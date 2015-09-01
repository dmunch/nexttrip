FROM node:0.12.7

RUN apt-get update
RUN apt-get -y install postgresql-client

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY package.json /usr/src/app/
RUN npm install
COPY ./index.js /usr/src/app/index.js
COPY ./public/ /usr/src/app/public/
ADD ./sql/create_indizes_and_functions.sql /usr/src/app/create_indizes_and_functions.sql
EXPOSE 3000

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD [ "npm", "start" ]
