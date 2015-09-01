FROM python:2.7.10

#Install buildout
RUN pip install zc.buildout

#Install easy_install
RUN wget https://bootstrap.pypa.io/ez_setup.py -O - | python

RUN git clone https://github.com/OpenTransitTools/gtfsdb.git
WORKDIR gtfsdb
RUN buildout install prod postgresql

# Sleep 5 seconds to make sure database is ready to accept connections
ENTRYPOINT ["sh", "-c", "sleep 5 && ./bin/gtfsdb-load --is_geospatial --database_url postgresql://docker:docker@$POSTGIS_PORT_5432_TCP_ADDR:$POSTGIS_PORT_5432_TCP_PORT/gis $0"]
