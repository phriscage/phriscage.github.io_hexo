title: Flask NoSQL Authentication Tutorial - Part II
tags:
  - authentication
  - elasticsearch
  - flask
  - python
  - nosql
  - session management
categories: []
date: 2015-01-11 02:29:00
---
## Overview

This is the second part of a tutorial that provides instructions for how to create an authentication mechanism for a web application utilizing [Flask](http://flask.pocoo.org/) as the [Python](https://www.python.org/) web framework and [Elasticsearch](http://www.elasticsearch.com/) (ES) as the NoSQL data store. 

The first part of the tutorial covered the prerequisites, the [Main API](https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/api/main.py), the [User model](https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/lib/user.py), and the [Users API](https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/api/users/views.py) end point. In this second part of the tutorial, I will be covering the [Flask-Login](https://flask-login.readthedocs.org/en/latest/) and session management modifications required for the [main API](https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/api/main.py), the [User model](https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/lib/user.py), and the [Auth API](https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/api/auth/views.py). 

Once again, feel free to ask any questions below and I’ll be happy to respond!


## Flask-Login

Flask-Login provides user session management for basic authentication tasks; logging a user in and logging out a user, in your application. You can restrict specific views for non-authenticated users by adding a decorator to your view routes. For this tutorial example, I have followed the [basic configuration](https://flask-login.readthedocs.org/en/latest/#configuring-your-application) and created a custom [user_loader](https://flask-login.readthedocs.org/en/latest/#flask.ext.login.LoginManager.user_loader) for ES. 

## Main API
In the Main API, we define the 'login_manager' and the 'load_user' function for the Flask-Login 'user_loader' decorator which sets the callback for reloading a user from the session. The 'load_user' funcation creates a User object, checks if the user exists in ES, then returns the User object:

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

Then we define the APP_SECRET_KEY as a global variable, then assign it to the main app and instantiate the 'login_manager':

```
    app.secret_key = APP_SECRET_KEY
    login_manager.init_app(app)
```

That's all the changes required for the 'main.py'. We need to modify the User model but those changes are minor too.

## User model

For the User model, we need to add a few functions that are required for [Flask-Login](https://flask-login.readthedocs.org/en/latest/#your-user-class). The function doc strings should be self explanatory. 

``` Python User.py https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/lib/user.py
    def is_authenticated(self):
        """ should just return True unless the object represents a user
            that should not be allowed to authenticate for some reason.
        """
        if self.is_anonymous():
            return False
        return True

    def is_active(self):
        """ method should return True for users unless they are inactive, for
            example because they have been banned.
        """
        if not self.values.get('is_active', False):
            return False
        return True

    def is_anonymous(self):
        """ method should return True only for fake users that are not supposed
            to log in to the system.
        """
        if not self.values.get('is_anonymous', False):
            return False
        return True

    def get_id(self):
        """ return the self.key """
        return self.values[KEY_NAME]
```

## Auth API

Now for the Auth API, we create a 'login' route for authenticating a user and a 'logout' for unauthenticating a user. For the 'login' route, first, we verify the user submitting the request is valid by checking if the user key exists in ES. Next, we check if the request payload includes the correct password by comparing the password value with the hashed password from the database. Finally, we add the valid user into session via 'login_user'. The 'login' route is almost identical to the 'new' user route from the User API, but we add the password check and add the authenticated user via 'login_user':

``` Python Auth https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/api/auth/views.py
...
    logger.debug("'%s' successfully found!", request.json['email_address'])
    user.set_values(values=data['_source'])
    if not user.check_password(request.json['password']):
        logger.warn("'%s' incorrect password", request.json['email_address'])
        message = "Unknown email_address or bad password"
        return jsonify(message=message, success=False), 400
    login_user(user)
    message = "'%s' successfully logged in!" % request.json['email_address']
    logger.info(message)
...
```  

Once a use is authenticated, the active user is now stored in the session. For the 'logout' route, we simply call the 'logout_user()' method to remove the user id from the current session. Now let's create a test route that is only accessible from authorized users.

## Test API

The [Test API](https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/api/test/views.py) includes the 'login_required' decorator which restricts access to only users that are authenticated:

``` Python Test https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/api/test/views.py
...
@test.route('')
@login_required
def index():
...
```

Import the new auth and test Blueprints and register it with the URL route to the app in main.py:

``` Python main.py https://github.com/phriscage/flask_elasticsearch_auth_example/blob/master/lib/example/v1/api/main.py
    from example.v1.api.auth.views import auth
    app.register_blueprint(auth, url_prefix="/v1/auth")
    from example.v1.api.users.views import users
    app.register_blueprint(users, url_prefix="/v1/users")
    from example.v1.api.test.views import test
    app.register_blueprint(test, url_prefix="/v1/test")
```

Start the application again with the 'main.py' and run `curl -X GET -D - http://127.0.0.1:8000/v1/test`. You should recieve an 401 unauthorized response:

```
$ curl -X GET -D - http://127.0.0.1:8000/v1/test
HTTP/1.0 401 UNAUTHORIZED
Content-Type: application/json
Content-Length: 294
Set-Cookie: session=eyJfaWQiOnsiIGIiOiJOalk0TldVMU1XWXdaamsyT0Roa1pqVmxOamN3TnpRNU5tSmpNamsxTVRJPSJ9fQ.B6pYAg.q2HbuYgeleBAGU1kKfDCCnGEugg; HttpOnly; Path=/
Server: Werkzeug/0.9.6 Python/2.6.6
Date: Tue, 20 Jan 2015 01:18:19 GMT

{
  "error": "401: Unauthorized",
  "message": "The server could not verify that you are authorized to access the URL requested.  You either supplied the wrong credentials (e.g. a bad password), or your browser doesn't understand how to supply the credentials required.",
  "success": false
}
```

We need to first authenticate our test user, store the cookie, then send the request again. Let's authenticate the user we created in [Part I](http://phriscage.github.io/2014/12/06/Flask-NoSQL-Authentication-Tutorial-Part-I/), 'test@abc.com' and store the cookies into a file, 'cookies.txt' 

```
$ curl -X POST -s -D - -c ~/cookies.txt -H 'Content-Type: application/json' -d '{"email_address": "test@abc.com", "password": "test"}' http://127.0.0.1:8000/v1/auth/login
HTTP/1.0 200 OK
Content-Type: application/json
Content-Length: 360
Set-Cookie: session=eyJfZnJlc2giOnRydWUsIl9pZCI6eyIgYiI6Ik5qWTROV1UxTVdZd1pqazJPRGhrWmpWbE5qY3dOelE1Tm1Kak1qazFNVEk9In0sInVzZXJfaWQiOiJ0ZXN0QGFiYy5jb20ifQ.B58_Qg.Ez4andKJ01l51Ltd5nDg9EyXzTQ; HttpOnly; Path=/
Server: Werkzeug/0.9.6 Python/2.6.6
Date: Tue, 20 Jan 2015 01:22:10 GMT

{
  "data": {
    "_id": "test@abc.com",
    "_index": "example",
    "_source": {
      "_type": "user",
      "created_at": 1417912435.2168,
      "email_address": "test@abc.com",
      "is_active": true
    },
    "_type": "user",
    "_version": 1,
    "found": true
  },
  "message": "'test@abc.com' successfully logged in!",
  "success": true
}
```

Boom! We've successfully authenitcated our test user! You can view the 'cookies.txt' to see the current session cookie. Now we can use that session variable to send a request to 'test' again: `curl -X GET -s -D - -b ~/cookies.txt http://127.0.0.1:8000/v1/test`

```
$ curl -X GET -s -D - -b ~/cookies.txt http://127.0.0.1:8000/v1/test
HTTP/1.0 200 OK
Content-Type: application/json
Content-Length: 273
Set-Cookie: session=eyJfZnJlc2giOnRydWUsIl9pZCI6eyIgYiI6Ik5qWTROV1UxTVdZd1pqazJPRGhrWmpWbE5qY3dOelE1Tm1Kak1qazFNVEk9In0sInVzZXJfaWQiOiJ0ZXN0QGFiYy5jb20ifQ.B58_6Q.JoOanNrX80o0hiBnrwGllvUg1G8; HttpOnly; Path=/
Server: Werkzeug/0.9.6 Python/2.6.6
Date: Tue, 20 Jan 2015 01:24:57 GMT

{
  "data": {
    "cookies": {
      "session": "eyJfZnJlc2giOnRydWUsIl9pZCI6eyIgYiI6Ik5qWTROV1UxTVdZd1pqazJPRGhrWmpWbE5qY3dOelE1Tm1Kak1qazFNVEk9In0sInVzZXJfaWQiOiJ0ZXN0QGFiYy5jb20ifQ.B58_Qg.Ez4andKJ01l51Ltd5nDg9EyXzTQ"
    }
  },
  "message": "Test",
  "success": true
}
```

That's it! There's not alot too it. You can use the 'login_required' decorator on any view that requires authentication. There are some session expiration configuration options and custom authentication params that are confgiurable in Flask-Login. 

I hope you have found this tutorial helpful and maybe even learned a thing or two about Python, Flask, authentication, etc. Let me know if you have any questions.

Best,

Chris







