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
Docker encapsulates your application in virtual, containerized environments enabling you to deploy and run your applications in their own isolated or clustered domains. All of the application's run-time OS packages, libraries, and dependencies are included with the application binaries/executables when a Docker container is created. These containers can be deployed to single or multiple hosts for repeatable Continuous Integration/Continous Deployment environments, replicating or replacing physical with virtualized infrastructure, or isolated application environments for development.

> Docker is an open-source project that automates the deployment of applications inside software containers
>
> -- https://en.wikipedia.org/wiki/Docker_(software)



## Hexo


``` Python main.py https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/api/main.py
@login_manager.user_loader
def load_user(email_address):
    try:
        user = User(email_address=email_address)
    except ValueError as error:
        message = str(error)
        logger.warn(message)
        return None
    data = {}
    try:
        data = g.db_client.get('example', user.key)
    except (TransportError, Exception) as error:
        if not getattr(error, 'status_code', None) == 404:
            logger.critical(str(error))
            return None
    if not data.get('found', None):
        message = "'%s' does not exist." % email_address
        logger.warn(message)
        return None
    user.set_values(values=data['_source'])
    return user
```