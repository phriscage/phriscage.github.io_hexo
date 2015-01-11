title: Nginx SSL Configuration
tags:
  - nginx
  - ssl
  - nodejs
categories: []
date: 2014-10-18 11:06:00
---
## Overview
[Nginx](http://nginx.org/) is becoming one of the more popular event driven web servers. As of October 2014, it is currently used amongst the top 20% of the most busiest websites today [Netcraft](http://news.netcraft.com/archives/2014/10/10/october-2014-web-server-survey.html). Setting up SSL should not be a daunting task, so I created a default SSL configuration (from [Raymii.org](https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html)) and Nodejs config [here](https://github.com/phriscage/nginx_ssl_configuration).

You can setup multiple sub domains in the same server config:

``` Python server_name https://github.com/phriscage/nginx_ssl_configuration/blob/master/etc/nodejs_sample.conf#L8
server_name    abc-dev.sample.com abc.sample.com;
```

Redirect all HTTP to HTTP requests permanently (301):

``` Python HTTP redirect https://github.com/phriscage/nginx_ssl_configuration/blob/master/etc/nodejs_sample.conf#L12-L14
if ($scheme != "https") {
    rewrite ^   https://$server_name$request_uri? permanent;
}
```

Also, redirect any unsupported client browsers:

``` Python browser redirect https://github.com/phriscage/nginx_ssl_configuration/blob/master/etc/nodejs_sample.conf#L21-L24
        ## redirect ie8 and lower
        if ($http_user_agent ~ "MSIE\s([1-8])\.") {
            rewrite ^ /unsupported break;
        }
```

[Source](https://github.com/phriscage/nginx_ssl_configuration).

Best,
Chris