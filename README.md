phriscage.github.io_hexo
=====================

Hexo blog for phriscage.github.io.

Quickstart:
=====================
* Docker:
```
docker build -t phriscage.github.io . && docker run -it --rm -p 4000:4000 -v ~/github.com/phriscage/phriscage.github.io_hexo/app:/app phriscage.github.io_hexo
```

* Python:
```
sudo yum install python-virtualenvwrapper -y
source /usr/bin/virtualenvwrapper.sh
mkvirtualenv phriscage.github.io -r requirements.txt
nodeenv -p
npm install -g
```
