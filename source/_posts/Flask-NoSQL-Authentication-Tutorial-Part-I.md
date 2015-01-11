title: Flask NoSQL Authentication Tutorial - Part I
tags:
  - python
  - flask
  - elasticsearch
  - nosql
  - authentication
categories: []
date: 2014-12-06 22:55:00
---
## Overview

This tutorial provides instructions for how to create an authentication mechanism for a web application utilizing [Flask](http://flask.pocoo.org/) as the [Python](https://www.python.org/) web framework and [Elasticsearch](http://www.elasticsearch.com/) (ES) as the NoSQL data store. Many applications utilize ES as the index/search layer, but I choose ES as the primary database as a proof of concept for both persistant and search data layers. ES can be swapped out with almost any available [NoSQL document store](http://en.wikipedia.org/wiki/Document-oriented_database).

A basic understanding of the *NIX system, Python, and web applications is required otherwise you may struggle with some of the concepts and context. If you are new to Flask, I highly recommend checking out Miguel Grinberg’s [Flask Mega Tutorial](http://blog.miguelgrinberg.com/post/the-flask-mega-tutorial-part-i-hello-world) or his newley published [Flask Book](http://flaskbook.com) by O’Reilly for a complete Flask application how-to. The [User Login tutorial](http://blog.miguelgrinberg.com/post/the-flask-mega-tutorial-part-v-user-logins) actually inspired me to build this tutorial for a NoSQL data store.

In this first part of the tutorial, I will be covering the prerequisites, the [main API](https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/api/main.py), the [User model](https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/lib/user.py), and the [Users API](https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/api/users/views.py) end point. If you have any questions, feel free to write below and I’ll be happy to answer if you have any issues.

Let’s get started!

## Prerequisites

Below are the specific prerequisites that are required to setup the working environment and download the neccesary packages and files.

* **linux server**: This tutorial is based off the [Centos](http://www.centos.org/) 6.4 x86_64 base image, so package management (and command instructions below) are via [RPM](http://en.wikipedia.org/wiki/RPM_Package_Manager) and [Yum](http://en.wikipedia.org/wiki/Yellowdog_Updater,_Modified). sudo or root privileges are required to install the various system packages. *If you prefer [Debian](https://www.debian.org/), you’ll need to substitute the respectable DEB packages and apt-get commands.*

` ssh username@hostname `

* **Elasticsearch**: The ES server package is downloaded directly from the ES site. Installation and the default configuration is all that is required to get the service running. You can verify ES is running by executing `curl -X GET http://127.0.0.1:9200` or navigating to the URL.
*note that version 1.3.2 is used at the time of writing*

` wget wget     https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.2.noarch.rpm && yum install elasticsearch-1.3.2.noarch.rpm --nogpgcheck -y `
` service elasticsearch start `

```
$ curl -X GET http://127.0.0.1:9200
{
  "status" : 200,
  "name" : "Sludge",
  "version" : {
    "number" : "1.3.2",
    "build_hash" : "dee175dbe2f254f3f26992f5d7591939aaefd12f",
    "build_timestamp" : "2014-08-13T14:29:30Z",
    "build_snapshot" : false,
    "lucene_version" : "4.9"
  },
  "tagline" : "You Know, for Search"
}
```

* **Python**: Python 2.6.6 is already included in the base Centos 6.4, so that version will work. We’ll be using [Python virtual environments](http://virtualenv.readthedocs.org/en/latest/) and [Pip](https://pip.pypa.io/en/latest/) to handle the Python libraries and dependencies:

` yum install python-virtualenv python-pip -y `

* **Git**: We’ll need to install [Git](http://git-scm.com/) and clone the tutorial source code from my [Gihub](https://github.com/) [repository](https://github.com/phriscage/flask_elasticsearch_auth_example && cd flask_elasticsearch_auth_example).

` yum install git -y `
` git clone https://github.com/phriscage/flask_elasticsearch_auth_example && cd flask_elasticsearch_auth_example `

* **Python libraries**: Create a new virtual environment and activate it. Then pull the packages from [PyPi](https://pypi.python.org/pypi) using Pip and [requirements.txt](https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/requirements.txt):

` virtualenv venv && source venv/bin/activate `
` ./venv/bin/pip install -r requirements.txt `

Now we should have all the required dependencies. :)

## Main API

Before we create the primary User model, we need to create the basic Flask app API and verify we can connect to ES. I’m using Flask's global [g](http://flask.pocoo.org/docs/0.10/api/#flask.g) module to handle the ES client connection for each request. You can tweak the ES connection pool options for the cluster, but for now the default connection object works. I am using the default_error_handle method to return a standard [JSON](http://tools.ietf.org/html/rfc7159) formatted message for all of the relevant [HTTP error codes](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html).

``` Python main.py https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/api/main.py
def connect_db():
    """ connect to couchbase """
    try:
        db_client = Elasticsearch()
            #[{'host': ELASTICSEARCH_HOST, 'port': ELASTICSEARCH_PORT}],
            #use_ssl=True,)
            #sniff_on_connection_fail=True,)
    except Exception as error:
        logger.critical(error)
        raise
    return db_client
    
def create_app():
    """ dynamically create the app """
    app = Flask(__name__)
    app.config.from_object(__name__)
   
    @app.before_request
    def before_request():
        """ create the db_client global if it does not exist """
        if not hasattr(g, 'db_client'):
            g.db_client = connect_db()
    
    def default_error_handle(error=None):
        """ create a default json error handle """
        return jsonify(error=str(error), message=error.description,
            success=False), error.code
    
    ## handle all errors with json output
    for error in range(400, 420) + range(500, 506):
        app.error_handler_spec[None][error] = default_error_handle
```

The main.py arguments accept a specific hostname or IP and port number. When you start the application, the output should look like this:

```
$ ./main.py
2014-12-06 22:10:05,770 INFO werkzeug[8640] : _log :  * Running on http://0.0.0.0:8000/
2014-12-06 22:10:05,770 INFO werkzeug[8640] : _log :  * Restarting with reloader
```

We can verify it works, along with the default_error_handle, but pulling the base URL. `curl -X GET -D - http://127.0.0.1:8000/`

```
$ curl -X GET -D - http://127.0.0.1:8000/
HTTP/1.0 404 NOT FOUND
Content-Type: application/json
Content-Length: 191
Server: Werkzeug/0.9.6 Python/2.6.6
Date: Sun, 07 Dec 2014 00:35:23 GMT

{
  "error": "404: Not Found",
  "message": "The requested URL was not found on the server.  If you entered the URL manually please check your spelling and try again.",
  "success": false
}
```

Great! Now let’s define our User model and how-to store the user document data in ES.

## User model

The User model contains the data structure and validation methods for the user metadata that will be passed from the API.

First, we include the system level modules and two password hash functions from [werkzeug](http://werkzeug.pocoo.org/). We define what the key or ID attribute name will be for our user document and any additional required and/or valid attributes for the document.

``` Python user.py https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/lib/user.py
from __future__ import absolute_import
import time
import re
import logging
from werkzeug.security import generate_password_hash, check_password_hash

KEY_NAME = 'email_address'
REQUIRED_ARGS = (KEY_NAME, 'password',)
VALID_ARGS = REQUIRED_ARGS + ('first_name', 'last_name',)
```

Instatiation of class executes private class functions to validate the kwargs against the global VALID_AGRS and REQUIRED_ARGS. It also sets the default and required values for the user document:

``` Python user.py https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/lib/user.py
class User(object):
    """ encapsulate the user as an object """
    
    def __init__(self, **kwargs):
        """ instantiate the class """
        self.key = None
        self.values = {}
        self._validate_args(**kwargs)
        self._set_key(kwargs[KEY_NAME])
        self._set_values()
```

The set_password and check_password functions are how the model generates a password hash and verifies a plain text password against a hash. Instead of creating our own hashing algorithms, we use werkzeug’s utilies we imported above:

``` Python user.py https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/lib/user.py
def set_password(self, password):
    """ set the password using werkzeug generate_password_hash """
    self.values['password'] = generate_password_hash(password)
    
def check_password(self, password):
    """ check the password using werkzeug check_password_hash """
    if not self.values.get('password', None):
        return None
    return check_password_hash(self.values['password'], password)
```

There's not alot going on the User model for Part I, but we will expand the functionality in the next tutorial.

## Users API:

Now that we have our basic user model, let’s define the User API endpoint that enables us to create a new user in ES. I’m using Flask’s [Blueprint](http://flask.pocoo.org/docs/0.10/blueprints/), [jsonify](http://flask.pocoo.org/docs/0.10/api/#flask.json.jsonify), [request](http://flask.pocoo.org/docs/0.10/reqcontext/) and g modules. I created a 'users' Blueprint and added the root '/new' route to create new users via [HTTP POST](http://en.wikipedia.org/wiki/POST_(HTTP). [REST API Tutorial](http://www.restapitutorial.com) provides a greate "resource" for learning the appropriate synatx naming. *For a truely textbook [RESTful](http://en.wikipedia.org/wiki/Representational_state_transfer) interface, one can argue between how a new resource is created ( '/users/new', '/user/new', or '/users') and if resource pluralization matters, but I'll save that discussion for a later date...*

The overall logic is straightforward. First we verify the request [content type](http://www.w3.org/Protocols/rfc1341/4_Content-Type.html) is ['application/json']( (https://tools.ietf.org/html/rfc4627). Next we create the User model and check the payload. Then check if the User document exits in ES. Finally, create a new User document if the User key, email_address, does not exist in ES. 

``` Python users/views.py https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/api/users/views.py
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)) +
        '/../../../../../lib')
from example.v1.lib.user import User, KEY_NAME as USER_KEY_NAME
from flask import Blueprint, jsonify, request, g
from elasticsearch import TransportError
import logging

logger = logging.getLogger(__name__)

users = Blueprint('users', __name__)

@users.route('/new', methods=['POST'])
    """ create a user and hash their password

    **Example request:**

    .. sourcecode:: http

    GET /users/new HTTP/1.1
    Accept: application/json
    data: {
        'email_address': 'abc@abc.com',
        'password': 'abc123',
        'first_name': 'abc',
        'last_name': '123'
    }

    **Example response:**

    .. sourcecode:: http

    HTTP/1.1 200 OK
    Content-Type: application/json

    :statuscode 200: success
    :statuscode 400: bad data
    :statuscode 409: already exists
    :statuscode 500: server error
    """
    
    if not request.data:
        message = "Content-Type: 'application/json' required"
        logger.warn(message)
        return jsonify(message=message, success=False), 400
    try:
        user = User(**request.json)
    except ValueError as error:
        message = str(error)
        logger.warn(message)
        return jsonify(message=message, success=False), 400
    data = {}
    try:
        data = g.db_client.get('example', user.key)
    except (TransportError, Exception) as error:
        if not getattr(error, 'status_code', None) == 404:
            logger.critical(str(error))
            message = "Something broke... We are looking into it!"
            return jsonify(message=message, success=False), 500
    if data.get('found', None):
        message = "'%s' already exists." % user.values[USER_KEY_NAME]
        logger.warn(message)
        return jsonify(message=message, success=False), 409
    try:
        args = {
            'index': 'example',
            'id': user.key,
            'body': user.values,
            'doc_type': user.values['_type']
        }
        data = g.db_client.index(**args)
    except Exception as error:
        message = str(error)
        logger.warn(message)
        return jsonify(message=message, success=False), 500
    message = "'%s' added successfully!" % user.values[USER_KEY_NAME]
    logger.debug(message)
    return jsonify(message=message, success=True), 200
```

Next we need to import the users Blueprint and register it with the URL route to the app in main.py:

``` Python main.py https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/api/main.py
    from example.v1.api.users.views import users
    app.register_blueprint(users, url_prefix="/v1/users")
```

If your 'main.py' file is not running, restart it. Finally, let's test creating a new user 'test@abc.com' against the Users API with the ` curl -X POST -H 'Content-Type: application/json' -d '{"email_address": "test@abc.com", "password": "test"}' http://127.0.0.1:8000/v1/users/new `

```
$ curl -X POST  -D - -H 'Content-Type: application/json' -d '{"email_address": "test@abc.com", "password": "test"}' http://127.0.0.1:8000/v1/users/new
HTTP/1.0 200 OK
Content-Type: application/json
Content-Length: 73
Server: Werkzeug/0.9.6 Python/2.6.6
Date: Sun, 07 Dec 2014 00:33:55 GMT

{
  "message": "'test@abc.com' added successfully!",
  "success": true
}
```

Success! 

You'll notice that if we try to add the same user again, we recieve a 409 conflict error:

```
$ curl -X POST  -D - -H 'Content-Type: application/json' -d '{"email_address": "test@abc.com", "password": "test"}' http://127.0.0.1:8000/v1/users/new
HTTP/1.0 409 CONFLICT
Content-Type: application/json
Content-Length: 70
Server: Werkzeug/0.9.6 Python/2.6.6
Date: Sun, 07 Dec 2014 00:34:01 GMT

{
  "message": "'test@abc.com' already exists.",
  "success": false
}
```

That's it for Part I. I'll follow up in a couple weeks with Part II which will utilize [Flask-Login](https://flask-login.readthedocs.org/en/latest/) to handle the user session managment.

Best,
Chris