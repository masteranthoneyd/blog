# Elasticsearch

![](https://cdn.yangbingdong.com/img/spring-boot-elasticsearch/es-heart.svg)

## 概念

**索引(index)** `->` 类似于关系型数据库中**Database**

**类型(type)** `->` 类似于关系型数据库中**Table**

**文档(document)** `->` 类似于关系型数据库中**Record**

## 自定义Dockerfile安装analysis-ik以及pinyin插件

基于官方的镜像安装***[analysis-ik](https://github.com/medcl/elasticsearch-analysis-ik)***和***[pinyin](https://github.com/medcl/elasticsearch-analysis-pinyin)***插件：

```
FROM docker.elastic.co/elasticsearch/elasticsearch:6.2.3
MAINTAINER yangbingdong <yangbingdong1994@gmail.com>
ARG TZ 
ARG HTTP_PROXY
ENV TZ=${TZ:-"Asia/Shanghai"} http_proxy=${HTTP_PROXY} https_proxy=${HTTP_PROXY}
RUN ./bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v6.2.3/elasticsearch-analysis-ik-6.2.3.zip \
  && ./bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-pinyin/releases/download/v6.2.3/elasticsearch-analysis-pinyin-6.2.3.zip \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo $TZ > /etc/timezone
ENV http_proxy=
ENV https_proxy=
```

构建镜像：

```
docker build --build-arg HTTP_PROXY=192.168.6.113:8118 -t yangbingdong/elasticsearch-ik-pinyin:6.2.3 .
```

## 安装启动

> 官方文档：***[https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html)***

使用docker compose:

```yaml
version: '3.4'
services:
  elasticsearch-temp:
    image: yangbingdong/elasticsearch-ik-pinyin:6.2.3
    ports:
      - "9222:9200"
      - "9300:9300"
    restart: always
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    volumes:
      - ./data:/usr/share/elasticsearch/data
    networks:
      - backend

networks:
  backend:
    external:
      name: backend
```

## Head插件

直接使用Chrome插件：

***[https://chrome.google.com/webstore/detail/elasticsearch-head/ffmkiejjmecolpfloofpjologoblkegm](https://chrome.google.com/webstore/detail/elasticsearch-head/ffmkiejjmecolpfloofpjologoblkegm)***

![](https://cdn.yangbingdong.com/img/spring-boot-elasticsearch/elasticsearch-head-plugin.png)
