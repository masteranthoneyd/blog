# Install Elasticsearch
## Docker

### Pull

```
docker pull elasticsearch:5.5.2-alpine
```

### Dockerfile

```
FROM elasticsearch:5.5.2-alpine

RUN echo "http.cors.enabled: true" >> config/elasticsearch.yml && echo 'http.cors.allow-origin: "*"' >> config/elasticsearch.yml
```

### Build

```
docker build -t yangbingdong/es:v2 .
```

### Run

```
docker run -d -p 9200:9200 -p 9300:9300 -v /home/ybd/docker/es/data:/usr/share/elasticsearch/data --name=es yangbingdong/es:v3
```

### Access

访问`localhost:9200`
![](http://ojoba1c98.bkt.clouddn.com/ima/node-of-elasticsearch/es-docker-9200.png)


# Elasticsearch-head
```
docker pull mobz/elasticsearch-head:5-alpine
docker run -d -p 9100:9100 --name es-head mobz/elasticsearch-head:5-alpine
```
![](http://ojoba1c98.bkt.clouddn.com/ima/node-of-elasticsearch/es-head-docker-9100.png)

# Spring Boot Elasticsearch
```
<dependency>
    <groupId>org.springframework.data</groupId>
    <artifactId>spring-data-elasticsearch</artifactId>
    <version>3.0.0.RC2</version>
</dependency>
```

# 参考
> ***[https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html)***
> ***[http://blog.leanote.com/post/wei@wayneleo.com/%E8%BF%90%E8%A1%8CES-ElasticSearch](http://blog.leanote.com/post/wei@wayneleo.com/%E8%BF%90%E8%A1%8CES-ElasticSearch)***
> ***[https://devblog.dymel.pl/2017/05/23/elasticsearch-dev-environment-with-docker/](https://devblog.dymel.pl/2017/05/23/elasticsearch-dev-environment-with-docker/)***
