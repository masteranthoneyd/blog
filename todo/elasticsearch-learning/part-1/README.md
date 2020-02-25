![](https://cdn.yangbingdong.com/img%2Felasticsearch%2Fillustration-elasticsearch-heart.png)

> ***[Elasticsearch核心技术与实战](https://time.geekbang.org/course/intro/197)*** 笔记
>
> 全部课件: ***[https://github.com/geektime-geekbang/geektime-ELK](https://github.com/geektime-geekbang/geektime-ELK)***

# 安装上手

拉取镜像:

```
docker pull elasticsearch:7.6.0
docker pull kibana:7.6.0
docker pull lmenezes/cerebro:0.8.5
docker pull logstash:7.6.0 
```

## 启动(ES+Kibana+Cerebro)

> ***[Cerebro](https://github.com/lmenezes/cerebro)*** 是一款Elasticsearch监控平台.

系统配置:

`/etc/sysctl.conf` 追加:

```
vm.max_map_count=262144
```

`sudo sysctl -p` 刷新.

`docker-compose.yml`:

```yml
version: '2.2'
services:
  cerebro:
    image: lmenezes/cerebro:0.8.5
    container_name: cerebro
    ports:
      - "9001:9000"
    command:
      - -Dhosts.0.host=http://elasticsearch:9200
    networks:
      - es7net
  kibana:
    image: kibana:7.6.0
    container_name: kibana7
    environment:
      - I18N_LOCALE=zh-CN
      - XPACK_GRAPH_ENABLED=true
      - TIMELION_ENABLED=true
      - XPACK_MONITORING_COLLECTION_ENABLED="true"
    ports:
      - "5601:5601"
    networks:
      - es7net
  elasticsearch:
    image: elasticsearch:7.6.0
    container_name: es7_01
    environment:
      - cluster.name=geektime
      - node.name=es7_01
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms1024m -Xmx1024m"
      - discovery.seed_hosts=es7_01
      - cluster.initial_master_nodes=es7_01,es7_02
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es7data1:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
    networks:
      - es7net
  elasticsearch2:
    image: elasticsearch:7.6.0
    container_name: es7_02
    environment:
      - cluster.name=geektime
      - node.name=es7_02
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms1024m -Xmx1024m"
      - discovery.seed_hosts=es7_01
      - cluster.initial_master_nodes=es7_01,es7_02
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es7data2:/usr/share/elasticsearch/data
    networks:
      - es7net

volumes:
  es7data1:
    driver: local
  es7data2:
    driver: local

networks:
  es7net:
    driver: bridge
```

> Docker 中配置 Kibana: ***[https://www.elastic.co/guide/en/kibana/current/docker.html](https://www.elastic.co/guide/en/kibana/current/docker.html)***
>
> Docker 版 Kibana 中 `elasticsearch.hosts` 默认值为 `http://elasticsearch:9200`, 可通过修改 `kibana.yml` 或者直接指定环境变量 `ELASTICSEARCH_HOSTS` 进行配置.

## Logstash 导入数据

下载数据:

```
curl https://raw.githubusercontent.com/geektime-geekbang/geektime-ELK/master/part-1/2.4-Logstash%E5%AE%89%E8%A3%85%E4%B8%8E%E5%AF%BC%E5%85%A5%E6%95%B0%E6%8D%AE/movielens/ml-latest-small/movies.csv > movie.cvs
```

`logstash.conf`:

```
input {
  file {
    path => "/initialize/movie.cvs"
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
}
filter {
  csv {
    separator => ","
    columns => ["id","content","genre"]
  }

  mutate {
    split => { "genre" => "|" }
    remove_field => ["path", "host","@timestamp","message"]
  }

  mutate {

    split => ["content", "("]
    add_field => { "title" => "%{[content][0]}"}
    add_field => { "year" => "%{[content][1]}"}
  }

  mutate {
    convert => {
      "year" => "integer"
    }
    strip => ["title"]
    remove_field => ["path", "host","@timestamp","message","content"]
  }

}
output {
   elasticsearch {
     hosts => "http://elasticsearch:9200"
     index => "movies"
     document_id => "%{id}"
   }
  stdout {}
}
```

`docker-compose-logstash.yml`:

```yml
version: '3'
services:
  logstash:
    image: logstash:7.6.0
    #    ports:
    #      - "4560:4560"
    restart: always
    environment:
      - LS_JAVA_OPTS=-Xmx512m -Xms512m
    volumes:
      - ./logstash.conf:/etc/logstash.conf
      - ./movie.cvs:/initialize/movie.cvs
    networks:
      - es7net
    entrypoint:
      - logstash
      - -f
      - /etc/logstash.conf

networks:
  es7net:
    driver: bridge
```

# 基础入门

## 基本概念

### 文档(Document)

![](https://cdn.yangbingdong.com/img/elasticsearch/elastcsearch-perspective.png)

* Elasticsearch 是**面向文档**的, 可理解为关系型数据库中的一行数据.
* **JSON** 格式, 由字段组成, 每个字段都有对应**类型**(字符串/数值/布尔/日期/二进制/范围类型), 字段类型可以自己指定或者通过 Elasticsearch 自动推算.
* 每个文档都有**唯一 ID**, 可以自己指定, 也可以是自动生成的.

### 元数据

![](https://cdn.yangbingdong.com/img/elasticsearch/meta-data.png)

元数据是用于标注文档的相关信息

* `_index`: 文档所属的索引名
* `_type`: 文档所属的类型名
* `_id`: 文档唯一 ID
* `_score`: 相应性打分
* `_source`: 文档的原始 JSON 数据
* `_version`: 文档的版本信息

### 索引

![](https://cdn.yangbingdong.com/img/elasticsearch/concept-of-index.png)

索引(Index)是文档的容器, 是一类文档的结合.

文档有 Mapping 以及 Setting, 分别体现了逻辑空间以及物理空间上的设置.

Mapping 用于定义文档的字段名和字段类型, Setting 用于定义数据分布.

### 类比

| RDBMS  | Elasticsearch |
| ------ | ------------- |
| Table  | Index(Type)   |
| Row    | Document      |
| Column | Field         |
| Schema | Mapping       |
| SQL    | DSL           |

### REST API

Elasticsearch 在早起就已经提供了 REST API, 方便跨语言调用. 比如:

```
#查看状态为绿的索引
GET /_cat/indices?v&health=green

#按照文档个数排序
GET /_cat/indices?v&s=docs.count:desc
```

## 分布式概念

* Elasticsearch 同时也是一个分布式系统, 所以它具备了分布式的特征: **高可用**以及**可扩展**.

* 在 Elasticsearch 中, 不同的集群通过**名字来区分**, 默认名字为 `elasticsearch`, 可通过配置中的 `cluster.name=newClusterName` 来设置.
* 一个集群可以包含多个**节点**, 每个节点相当于一个 JAVA 进程, 每个节点都有名字, 通过 `node.name=node1` 进行指定, 节点启动后会分配一个 UID, 保存在 `data` 目录下.

### Master-eligible nodes 和 Master node

* 每个节点启动后默认就是 Master-eligible 节点, 可以通过 `node.master: false` 禁止.
* Master-eligible 节点可以参加选举成为 Master 节点.
* 第一个节点启动时会将自己选举为 Master 节点.
* 每个节点都保存了集群的状态, 只有 Master 可以修改, 集群状态信息包括:
  * 所有节点信息
  * 所有的索引以及相关的 Mapping 以及 Setting 信息
  * 分片的路由信息

### Data Node 和 Coordinating Node

* Data Node: 保存数据的节点, 在数据扩展上起到重要作用.
* Coordinating Node: 负责接受 Client 的请求, 将请求分发到合适的节点, 并将结果汇集在一起, 每个节点都起到 Coordinating Node 的作用.

### 其他类型节点

* Hot & Warm Node: 不同硬件配置的 Data Node, 用来实现 Hot & Warm 架构, 降低集群部署的成本.
* Machine Learning Node: 负责跑机器学习的 Job, 用来做异常检测.

### 分片

![](https://cdn.yangbingdong.com/img/elasticsearch/concept-of-shard.png)

分片又分为**主分片**(Primary Shard)以及**副本分片**(Replica Shard).

* 主分片: 解决数据水平扩展的问题, 通过主分片, 可以将数据分不到集群内的所有节点之上
  * 一个分片是一个运行的 Lucene 的实力
  * 主分片在**索引创建时指定**, 后续不允许修改, 除非 Reindex
* 副本分片: 解决数据的高可用问题, 是主分片的拷贝.
  * 副本分片数可以动态调整
  * 增加副本数, 可以一定程度提高服务的可用性(读取的吞吐)