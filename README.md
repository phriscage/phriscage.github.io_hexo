phriscage.github.io_hexo
=====================

Hexo blog for phriscage.github.io.

Quickstart:
=====================
* Docker:
```
docker build -t phriscage/hexo-server . && HEXO_SERVER_CONTAINER_PORT=4000; HEXO_SERVER_HOST_PORT=4000; docker run -it --rm -p $HEXO_SERVER_HOST_PORT:$HEXO_SERVER_CONTAINER_PORT -e HEXO_SERVER_PORT=$HEXO_SERVER_CONTAINER_PORT -v ~/github.com/phriscage/phriscage.github.io_hexo/app:/app phriscage/hexo-server
```

* Python:
```
sudo yum install python-virtualenvwrapper -y
source /usr/bin/virtualenvwrapper.sh
mkvirtualenv phriscage.github.io -r requirements.txt
nodeenv -p
npm install -g
```
