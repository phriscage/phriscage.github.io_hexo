################################################################################
##
##  Developer:  Chris Page
##  Email:  phriscage@gmail.com
##  Purpose:   This Dockerfile contains the Docker builder commands for a simple
##	the hexo blog development environment.
##  Usage:
##	HEXO_SERVER_CONTAINER_PORT=4000;
##	HEXO_SERVER_HOST_PORT=4000;
##	docker run -it \
##	--rm \
##	-p $HEXO_SERVER_HOST_PORT:$HEXO_SERVER_CONTAINER_PORT \
##	-e HEXO_SERVER_PORT=$HEXO_SERVER_CONTAINER_PORT
##	-v <local github.com hexo directory>/app:/app \
##	--name hexo_blog \
##	phriscage/hexo-server
##
################################################################################
FROM node:5.3.0-slim

MAINTAINER Chris Page <phriscage@gmail.com>

## set HEXO_SERVER_PORT environment default
ENV HEXO_SERVER_PORT=4000

## update the respositories
RUN apt-get update
## install git for deployment
RUN apt-get install git -y

## install hexo-cli globally
RUN npm install -g hexo-cli

## set the workdir
WORKDIR /app

## expose the HEXO_SERVER_PORT
EXPOSE ${HEXO_SERVER_PORT}

#COPY docker-entrypoint.sh /app/.
#ENTRYPOINT ["/app/docker-entrypoint.sh"]

## npm install the latest packages from package.json and run the hexo server
## TODO put this in an appropriate ENTRYPOINT script
#CMD npm install && hexo clean && hexo server -d -p ${HEXO_SERVER_PORT}
CMD npm install; hexo clean; hexo server -d -p ${HEXO_SERVER_PORT}
