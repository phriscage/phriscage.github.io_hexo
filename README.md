phriscage.github.io_hexo
=====================

Hexo blog for phriscage.github.io.

Quickstart:
=====================
* Docker:
Change the environment variables and launch the hexo blog container!
```
BLOG_DIR=~/github.com/phriscage/phriscage.github.io_hexo HEXO_SERVER_CONTAINER_PORT=4000; HEXO_SERVER_HOST_PORT=4000; docker run -it --rm -p $HEXO_SERVER_HOST_PORT:$HEXO_SERVER_CONTAINER_PORT -e HEXO_SERVER_PORT=$HEXO_SERVER_CONTAINER_PORT -v $BLOG_DIR:/app --name hexo_blog phriscage/hexo-server
```
Deploy:
```
docker exec -it hexo_blog hexo deploy
```

* Python:
```
sudo yum install python-virtualenvwrapper -y
source /usr/bin/virtualenvwrapper.sh
mkvirtualenv phriscage.github.io -r requirements.txt
nodeenv -p
npm install -g
```


Development:
=====================
* Docker:
```
docker build -t phriscage/hexo-server . && BLOG_DIR=~/github.com/phriscage/phriscage.github.io_hexo HEXO_SERVER_CONTAINER_PORT=4000; HEXO_SERVER_HOST_PORT=4000; docker run -it --rm -p $HEXO_SERVER_HOST_PORT:$HEXO_SERVER_CONTAINER_PORT -e HEXO_SERVER_PORT=$HEXO_SERVER_CONTAINER_PORT -v $BLOG_DIR:/app --name hexo_blog phriscage/hexo-server
```
