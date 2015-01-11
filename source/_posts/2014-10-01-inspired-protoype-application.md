title: Inspired Protoype Application
tags:
  - python
  - flask
  - sqlalchemy
date: 2014-10-01 05:04:53
---
## Overview
When I was invloved with the [Invid.io](http://invid.io) team from 2012-2014, one of the initial proof of concept projects I created was an application that provides video product metadata and merchant retailers directly to consumers. The [Inspired](http://inspiredapp.tv/) app ([source](https://github.com/phriscage/inspired)), enabled the content creators the ability to organize and sell their products to an audience. In this post, I'm going to provide an overview of the technologies utilized for the application at a high-level and a few specific examples. 

Most of the Python web applications I had built previously were using the [Django](https://www.djangoproject.com/) web framework. Since Inspired did not require all of the compents and functionality that Django provided out of the box, I decided to try [Flask](http://flask.pocoo.org/) for the project. I had created a few stand-alone APIs using Flask in my full-time position, but not a full-blown application. 

## Data model
Inspired was designed with a high-level relational data model of **Artists -> Videos -> Products -> Retailers**. The complete Inspired ERD is below: 

{% img /2014/10/01/inspired-protoype-application/invidio_videos_erd.png 600 400 %}

I was initially tempted to use a NoSQL data store like [Cassandra](http://cassandra.apache.org/) to handle the horizontal scaling in the future, but at the time, I had minimal experience with denormalizing and duplicating the data to fit the specific queries for the user interface. I decided to go with the de facto standard relational data store, MySQL. Instead of creating standard raw SQL queries, I used an ORM plugin [SQLAlchemy](http://www.sqlalchemy.org/) to build the queries and model relationships. [SQLAlchemy](http://docs.sqlalchemy.org/en/rel_0_9/orm/relationships.html) provides some create documentation on how to build the model classes and their respectable releationships. Here's an example of how the Video model uses both One-to-Many and Many-to-Many relationships in it's class:

``` Python Video model https://github.com/phriscage/inspired/blob/master/lib/inspired/v1/lib/videos/models.py#L15-L54
class Video(Base):
""" video_products join_table used to defined the bi-directional
    relationship between Video and Product. Creating a separate class is
    overkill unless additional atributes are required.
"""
video_products = Table('video_products', Base.metadata,
    Column('video_id', Integer(unsigned=True),
        ForeignKey('videos.video_id',
        name='fk_video_products_video_id', ondelete="CASCADE"),
        index=True, nullable=False),
    Column('product_id', Integer(unsigned=True),
        ForeignKey('products.product_id',
        name='fk_video_products_product_id', ondelete="CASCADE"),
        index=True, nullable=False),
    mysql_engine='InnoDB',
    mysql_charset='utf8'
)

class Video(Base):
    """ Attributes for the Video model. Custom MapperExtension declarative for 
        before insert and update methods. The migrate.versioning api does not
        handle sqlalchemy.dialects.mysql for custom column attributes. I.E.
        INTEGER(unsigned=True), so they need to be modified manually.
     """
    __tablename__ = 'videos'
    __table_args__ = {
        'mysql_engine': 'InnoDB',
        'mysql_charset': 'utf8'
    }
    ## mapper extension declarative for before insert and before update
    __mapper_args__ = { 'extension': BaseExtension() }

    id = Column('video_id', Integer(unsigned=True), primary_key=True)
    name = Column(String(120), unique=True, index=True, nullable=False)
    image_url = Column(String(2083))
    video_sources = relationship("VideoSource", backref="video")
    scenes = relationship("Scene", backref="video")
    products = relationship("Product", secondary="video_products",
        backref="videos")
    created_at = Column(DateTime(), nullable=False)
    updated_at = Column(DateTime(), nullable=False)
```

When I was building the data models, I wanted to use a similar DJango function for auto updating the DateTime fields whenever the row was created/updated [auto_now](https://docs.djangoproject.com/en/1.4/ref/models/fields/#django.db.models.DateField). SQLAlchemy 0.7.8 did not have this ability, but you could create custom *extensions* for the SQLAlchemy model through the *__mapper_args__*. I was able to implement the auto_now by extending the MapperExtension:

``` Python BaseExtension https://github.com/phriscage/inspired/blob/master/lib/inspired/v1/lib/helpers.py#L6-L18
class BaseExtension(MapperExtension):
    """Base entension class for all entity """

    def before_insert(self, mapper, connection, instance):
        """ set the created_at  """
        datetime_now = datetime.datetime.now()
        instance.created_at = datetime_now
        if not instance.updated_at:
            instance.updated_at = datetime_now

    def before_update(self, mapper, connection, instance):
        """ set the updated_at  """
        instance.updated_at = datetime.datetime.now()
```

## Schema Migrations
I was familiar with Ruby on Rails schema migrations and used a snippet of the Rails migration functionality extensively for Django ([South](http://south.aeracode.org/) was not mature yet). I decided to give [Alembic](https://bitbucket.org/zzzeek/alembic) a try since it has the ability to auto-generate the migrations based off the SQLAlchemy models. There were some *gotchas* with the 0.6.0 release, but overall, I think it is comparable to Rails migrations. I.E.
- explicitly importing sqlalchemy.dialects.mysql.INTEGER for unsigned values
- version filename length had fixed limit

I was also able to seed some initial test data (outside unit testing) in a few migrations. 

## Unit testing
I used Python's unittest library to test both the SQLAlchemy models and Flask API end points. For each model and API test case class, I duplicated the MySQL schema and ran the migrations to ensure a clean environment. The [nosetest](https://nose.readthedocs.org/en/latest/) performance was not great, but utilizing MySQL over SQLlite provided a more *production like* environment for test simulation. 

``` Python unittest
$ nosetests -s -x
...........................................................................
----------------------------------------------------------------------
Ran 75 tests in 5.823s

OK
```

Feel free to check out the [source](https://github.com/phriscage/inspired) and let me know if you have any questions.

Best,
Chris