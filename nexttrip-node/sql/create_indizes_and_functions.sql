-- Takes a string of kind 13:00:00 and calculates the corresponding amount of seconds
CREATE OR REPLACE FUNCTION to_seconds(timestring varchar)
RETURNS integer AS $$
BEGIN   
	RETURN cast(split_part(timestring, ':', 1) AS INT) * 60 * 60 + cast(split_part(timestring, ':', 2) AS INT) * 60 + cast(split_part(timestring, ':', 3) AS INT);
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- Need to have an index on geography(geom) to make ST_DWithin use the index
CREATE INDEX idx_stops_geom_geography ON stops USING GIST (geography(geom));
-- We'll be querying the departure time a lot, so we better make an index on it
CREATE INDEX idx_departure_time ON stop_times(to_seconds(departure_time));


CREATE OR REPLACE FUNCTION close_depature_points(lat float, lon float, dist_in_m integer, traveldate date, from_time text, to_time text)
RETURNS TABLE(stop_name varchar, stop_geom geometry, departure_time varchar, trip_headsign varchar, route_short_name varchar, dist float) AS $$
BEGIN
  RETURN QUERY SELECT DISTINCT ON (routes.route_id) 
-- together with ORDER BY solves the greatest-n-per-group Problem in PostGIS
-- In our case the closest station for a given route_id
-- http://stackoverflow.com/questions/3800551/select-first-row-in-each-group-by-group/7630564#7630564
 stops.stop_name,
 stops.geom,
 stop_times.departure_time, 
 trips.trip_headsign, 
 --routes.route_id, 
 --trips.service_id,
 routes.route_short_name, 
 ST_Distance(
  Geography(stops.geom),
  Geography(ST_SetSRID(ST_Point(lon, lat),4326))
 ) AS distance
FROM stops 
INNER JOIN stop_times ON stops.stop_id = stop_times.stop_id
INNER JOIN trips ON stop_times.trip_id = trips.trip_id
INNER JOIN routes ON trips.route_id = routes.route_id
INNER JOIN calendar_dates ON trips.service_id = calendar_dates.service_id --TODO: take into account calenar as well
WHERE 
ST_DWithin(                    
                    Geography(stops.geom),
                    Geography(ST_SetSRID(ST_Point(lon, lat),4326)),
                    dist_in_m, false
                ) 
AND to_seconds(stop_times.departure_time) >= to_seconds(from_time) 
AND to_seconds(stop_times.departure_time) <= to_seconds(to_time)
AND calendar_dates.date = traveldate
ORDER BY routes.route_id, distance ASC;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION close_depature_points_grouped(lat float, lon float, dist_in_m integer, traveldate date, from_time text, to_time text)
RETURNS TABLE(stop_name varchar, trips_and_departure_time json, stop_geom text) AS $$
BEGIN
RETURN QUERY SELECT cdp.stop_name,
	array_to_json(array_agg(hstore(ARRAY['departure_time', departure_time, 
							 'trip_headsign', trip_headsign,
							 'route_short_name', route_short_name]))) AS properties,
	ST_AsGeoJSON(cdp.stop_geom) AS geom
FROM (SELECT * FROM close_depature_points(lat, lon, dist_in_m, traveldate, from_time, to_time)) as cdp
GROUP BY cdp.stop_geom, cdp.stop_name;
END;
$$ LANGUAGE plpgsql;
