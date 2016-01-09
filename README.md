nexttrip
===================

Nexttrip shows you the next public transports available near you in the next 10 minutes. You can find an instance of it for the city of Berlin at [nexttrip.pause.coffee](https://nexttrip.pause.coffee). 

Nexttrip was born as a tiny pet project to exploit the [GTFS  format](https://developers.google.com/transit/gtfs/reference) and to showcase the power of Docker. If you want to set up an instance on your own, three steps are necessary:

- Install [Docker](https://docs.docker.com/installation/) and [Docker Compose](https://docs.docker.com/compose/install/). If you're on Windows or Mac OSX go directly for the [Docker Toolbox](https://www.docker.com/toolbox).
- Clone this repository.
- Initalize your database with the GTFS file of your choice. At the root of the cloned repository, run ``` docker-compose run gtfsdb http://www.vbb.de/de/download/GTFS_VBB_Dez2015_Dez2016.zip``` The last argument specifies the location of a GTFS file of your choice.
- Start the web-frontend with ``` docker-compose up -d nexttrip-node```

Pro-Tip: Run it in fullscreen and put it on your TV. As it refreshes timetables every minute you'll never miss that S-Bahn again!

