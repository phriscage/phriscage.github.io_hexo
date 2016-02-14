title: Hexo blog development on Docker
tags:
  - hexo
  - docker
categories: []
date: 2016-01-18 17:29:00
---
## Overview

It's been over a year since my last post and I wanted to share some of my experiences utilizing [Docker](http://docker.com) for my [Hexo](http://hexo.com) blog development. In my current consultant position, I have been working extensively with Docker's technology stack, streamlining various customers' integration efforts into the API Management realm. This post will focus on how to develop your own Hexo blog with Docker.


## Docker
Docker encapsulates your application in virtual, containerized environments enabling you to deploy and run your applications in their own isolated or clustered domains. All of the application's run-time OS packages, libraries, and dependencies are included with the application binaries/executables when a Docker container is created. These containers can be deployed to single or multiple hosts for repeatable Continuous Integration/Continous Deployment environments, replicating or replacing physical with virtualized infrastructure, or isolated application environments for development. There are many different use-cases for Docker containers and running a Hexo blog is one of them.


## Dockerfile
A Dockerfile is a script that defines all of the various commands for creating an image. The Dockerfile for the Hexo blog is pretty straight-forward. I am using the core node:5.3.0-slim image, set the HEXO_SERVER_PORT environment, install hexo-cli, expose the HEXO_SERVER_PORT, then intall the packages via [NPM](https://www.npmjs.com/) and run the server. I have already pre-defined the *hexo-server* and *hexo-admin* plugins in the app/package.json so NPM handles those dependencies. 

``` 
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

```


## Runtime
When running a Hexo blog Docker container, you need to specify the local Hexo blog volume directory via **-v** to mount to the container's /app directory:
* `-v ~/github.com/phriscage/phriscage.github.io_hexo/app:/app`

The port command **-p**, will map your exposed container port to the Docker host: 
* `-p $HEXO_SERVER_HOST_PORT:$HEXO_SERVER_CONTAINER_PORT`

You can also specify the **-e** HEXO_SERVER_PORT environment variable to change the exposed container portL
* `-e HEXO_SERVER_PORT=$HEXO_SERVER_CONTAINER_PORT`


```
$ BLOG_DIR=~/github.com/phriscage/phriscage.github.io_hexo HEXO_SERVER_CONTAINER_PORT=4000; HEXO_SERVER_HOST_PORT=4000; docker run -it --rm -p $HEXO_SERVER_HOST_PORT:$HEXO_SERVER_CONTAINER_PORT -e HEXO_SERVER_PORT=$HEXO_SERVER_CONTAINER_PORT -v $BLOG_DIR/app:/app --name hexo_blog phriscage/hexo-server
npm info it worked if it ends with ok
npm info using npm@3.3.12
npm info using node@v5.3.0
npm info attempt registry request try #1 at 2:54:43 AM
npm http request GET https://registry.npmjs.org/fsevents
npm http 304 https://registry.npmjs.org/fsevents
npm WARN install Couldn't install optional dependency: Unsupported
npm WARN install Couldn't install optional dependency: Unsupported
npm info lifecycle phriscage.github.io@0.1.0~preinstall: phriscage.github.io@0.1.0
npm info linkStuff phriscage.github.io@0.1.0
npm info lifecycle phriscage.github.io@0.1.0~install: phriscage.github.io@0.1.0
npm info lifecycle phriscage.github.io@0.1.0~postinstall: phriscage.github.io@0.1.0
npm info lifecycle phriscage.github.io@0.1.0~prepublish: phriscage.github.io@0.1.0
npm info ok
INFO  Deleted database.
INFO  Hexo is running at http://0.0.0.0:4000/. Press Ctrl+C to stop.
```

Now that your container is running, you can navigate to the *http://DOCKER_HOST_IP:PORT/admin* URL on your broswer and start blogging!

Let me know if you have any comments or questions.

Best,

Chris