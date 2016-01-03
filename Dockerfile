################################################################################
##  Name:   Dockerfile
##  Date:   2016-01-03
##  Developer:  Chris Page
##  Email:  christophertpage@gmail.com
##  Purpose:   This Dockerfile contains the Docker builder commands for a simple
##	the hexo blog development environment.
################################################################################
FROM node:5.3.0-slim

MAINTAINER Chris Page <christophertpage@gmail.com>

WORKDIR /app
COPY app /app
RUN npm install

EXPOSE 4000

CMD ["/app/node_modules/hexo/bin/hexo", "server", "-d"]
#ENTRYPOINT ["/nodejs/bin/npm", "start"]
