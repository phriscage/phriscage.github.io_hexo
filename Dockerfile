################################################################################
##  Name:   Dockerfile
##  Date:   2016-01-03
##  Developer:  Chris Page
##  Email:  christophertpage@gmail.com
##  Purpose:   This Dockerfile contains the Docker builder commands for a simple
##	the hexo blog development environment.
##  Usage: docker run -it \
##	--rm \
##	-p 4000:4000 \
##	-v ~/github.com/phriscage/phriscage.github.io_hexo/app:/app \
##	phriscage.github.io_hexo
################################################################################
FROM node:5.3.0-slim

MAINTAINER Chris Page <christophertpage@gmail.com>

ENV HEXO_SERVER_PORT=4000

RUN npm install -g hexo-cli
WORKDIR /app
#RUN npm install

EXPOSE ${HEXO_SERVER_PORT}

#COPY docker-entrypoint.sh /app/.
#ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD npm install && hexo server -d
