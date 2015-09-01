var pg = require('pg');

//If we're running inside a Docker container with environement variables set, use them
//Userwise use developement default values
var pgAddr = process.env.POSTGIS_PORT_5432_TCP_ADDR || '192.168.99.100';
var pgPort = process.env.POSTGIS_PORT_5432_TCP_PORT || '5432';
var pgConnectionString = process.env.DATABASE_URL || 'postgres://docker:docker@' + pgAddr + ':' + pgPort+ '/gis';

var express = require('express');
var app = express();

app.use(express.static(__dirname + '/public/'));
app.use(express.static(__dirname + '/node_modules/'));

function validateRegexpParam(app, regExp, paramName) {
	app.param(paramName, function(req, res, next, param) {
		var re = new RegExp(regExp)
		if(!re.test(param)) {
			res.status(400).send('Invalid parameter ' + paramName);
		} else {
			next();
		}
	});	
}

function validateFloatParam(app, paramName) {
	validateRegexpParam(app, '^[-+]?[0-9]*(?:\.[0-9]*)?$', paramName);
}

validateFloatParam(app, 'lat');
validateFloatParam(app, 'lon');
validateFloatParam(app, 'distance');

app.get('/close_departure_points/:lat/:lon/:distance', function (req, res) {
	//either connects a new client or gets us one from the connection pool
	pg.connect(pgConnectionString, function(err, client, done) {
		//Query the stored function with the parameters
		var sql = 'SELECT * FROM close_depature_points_grouped($1, $2, $3, $4, $5, $6)';
		
		//use the current date
		var date = new Date();
		var dateString = (date.getMonth() + 1) + '-' + date.getDate() + '-' + date.getFullYear();
		
		var time_from = date.getHours() + ':' + date.getMinutes() + ':00';
		var time_to = date.getHours() + ':' + (date.getMinutes() + 5) + ':00';
 		
		//make sure that distance is an integer
		req.params.distance = req.params.distance | 0;
		var query = client.query(sql, [req.params.lat, req.params.lon, req.params.distance, dateString, time_from, time_to]);
		
		//Construct a GeoJSON FeatureCollection
		var featureCollection = {
			type: "FeatureCollection",
			features: []
		};
		
		query.on('row', function(row) {
			//map row columns to feature properties
			var properties = {
				stop_name: row.stop_name,
				trips: row.trips_and_departure_time
			};
			
			//create GeoJSON feature
			var feature = {
				type: "Feature",
				properties: properties,
				geometry: JSON.parse(row.stop_geom)
			};

			//add feature to collection
			featureCollection.features.push(feature);	
		});

		query.on('end', function() {
			client.end();
			done();

			//return the feature collection as json
			res.json(featureCollection);
		});
	});
});

var server = app.listen(3000, function () {
	var host = server.address().address;
	var port = server.address().port;

	console.log('Example app listening at http://%s:%s', host, port);
});