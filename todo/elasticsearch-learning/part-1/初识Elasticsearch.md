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
sudo tee -a /etc/sysctl.conf << EOF
vm.max_map_count=262144
EOF
```

 刷新配置:

```
sudo sysctl -p
```

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
      - -Dhosts.0.host=http://es01:9200
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
      - ELASTICSEARCH_HOSTS=http://es01:9200
    ports:
      - "5601:5601"
    networks:
      - es7net
  es01:
    image: elasticsearch:7.6.0
    environment:
      - cluster.name=geektime
      - node.name=es01
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms1024m -Xmx1024m"
      - discovery.seed_hosts=es02,es03
      - cluster.initial_master_nodes=es01,es02,es03
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
  es02:
    image: elasticsearch:7.6.0
    environment:
      - cluster.name=geektime
      - node.name=es02
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms1024m -Xmx1024m"
      - discovery.seed_hosts=es01,es03
      - cluster.initial_master_nodes=es01,es02,es03
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es7data2:/usr/share/elasticsearch/data
    networks:
      - es7net
  es03:
    image: elasticsearch:7.6.0
    environment:
      - cluster.name=geektime
      - node.name=es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms1024m -Xmx1024m"
      - discovery.seed_hosts=es01,es02
      - cluster.initial_master_nodes=es01,es02,es03
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es7data3:/usr/share/elasticsearch/data
    networks:
      - es7net

volumes:
  es7data1:
    driver: local
  es7data2:
    driver: local
  es7data3:
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

## 插件

```
#查看插件
bin/elasticsearch-plugin list
#查看安装的插件
GET http://localhost:9200/_cat/plugins?v
```

直接安装在自定义镜像中:

```
FROM elasticsearch:7.6.0
MAINTAINER yangbingdong <yangbingdong1994@gmail.com>
ARG TZ 
ARG HTTP_PROXY
ENV TZ=${TZ:-"Asia/Shanghai"} http_proxy=${HTTP_PROXY} https_proxy=${HTTP_PROXY}
RUN bin/elasticsearch-plugin install --batch https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v7.6.0/elasticsearch-analysis-ik-7.6.0.zip \
  && bin/elasticsearch-plugin install --batch https://github.com/medcl/elasticsearch-analysis-pinyin/releases/download/v7.6.0/elasticsearch-analysis-pinyin-7.6.0.zip \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo $TZ > /etc/timezone
ENV http_proxy=
ENV https_proxy=
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
  * 需要集群具备故障转移的能力, 必须将索引的副本分片数设置为 1![](https://cdn.yangbingdong.com/img/elasticsearch/get-cluster-health.png)

#### 生命周期

* 在 Lucene 中, Lucene Index 包含了若干个 Segment
* 在 Elasticsearch 中, Index 包含了若干主从 Shard, Shard 包干了若干 Segment
* Segment 是 Elasticsearch 中存储的最小文件单元, 也就是分段存储, Segment被设计为**不可变**(Immutable Design)的

不可变性带来的好处就是:

* 避免了锁带来的性能问题
* 可以利用内存, 由于 Segment 不可变, 所以 Segment 被加载到内存后无需改变, 只要内存足够, Segment就可以长期驻村, 大大提升查询性能
* 更新, 新增的增量的方式很轻, 性能好

缺点也很明显:

* 删除操作不会马上删除有一定的空间浪费
* 频繁更新涉及到大量的删除动作, 会有大量的空间浪费

![](https://cdn.yangbingdong.com/img/elasticsearch/index-lifecycle-refresh.png)

![](https://cdn.yangbingdong.com/img/elasticsearch/index-lifecycle.png)

![](https://cdn.yangbingdong.com/img/elasticsearch/index-lifecycle-transaction-log.png)



这个流程的目的是: 提升写入性能(异步落盘)

### 文档的存储

![](https://cdn.yangbingdong.com/img/elasticsearch/index-document-process.png)

* 文档会存储在具体的某个主分片和副本分片上: 例如文档1, 会存储在 P0 和 R0 分片上
* 文档路由算法: `shard = hash(_routing) % number_of_primary_shards`
  * Hash 算法确保文档均匀分散到分片中
  * 默认的 `_routing` 值是文档 id
  * 可以自行制定 routing 数值, 例如用相同国家的商品, 都分配到指定的 shard
  * 设置 Index Settings 后, **Primary 数不能随意修改的根本原因**

### 脑裂问题

Split-Brain, 分布式系统的经典网络问题, 当出现网络问题, 一个节点和其他节点无法连接:

![](https://cdn.yangbingdong.com/img/elasticsearch/splite-brain.png)

如何避免: 7.0 之前通过设置quorum(仲裁),只有在 Master eligible 节点数大于 quorum 时,才能
进行选举

* Quorum = (master 节点总数 /2)+ 1
* 当 3 个 master eligible 时,设置 `discovery.zen.minimum_master_nodes` 为 2,即可避免脑裂

从 7.0 开始,无需这个配置, 移除 `minimum_master_nodes` 参数,让 Elasticsearch 自己选择可以形成仲裁的节点.

## 基本CRUD与批量操作

### CRUD

主要有5个操作(Type名都用`_doc`):

* Index: 如果 ID 不存在则创建新的文档, 否则, 删除现有的文档再创建信息的文档, 版本号增加

  * ```
    PUT my_index/_doc/1
    {"user" : "Mike"}
    ```

* Create: 如果 ID 已存在, 则创建失败

  * ```
    PUT my_index/_create/1
    {"user" : "Mike"}
    POST my_index/_doc (不指定ID,  自动生成)
    {"user" : "Mike"}
    ```

* Read: 读取文档

  * ```
    GET my_index/_doc/1
    ```

* Update: 文档必须已经存在, 更新时只会对相应字段做增量修改

  * ```
    POST my_index/_update/1
    {
        "doc":{
            "post_date" : "2019-05-15T14:12:12",
            "message" : "trying out Elasticsearch"
        }
    }
    ```

* Delete: 删除文档

  * ```
    DELETE my_index/_doc/1
    ```

Index 与 Create 不一样的地方在于: 文档不存在, 则索引新的文档, 否则删除后再索引, 版本号加1.

Update 方法则不会删除文档, 只是更新数据, Post 方法的 Payload 需要包含在 `doc` 中.

### 批量操作

> 批量操作可以减少网络开销, 但是单次的批量操作数据量不宜过大, 以免引发性能问题.

批量操作(Bulk API) 只支持四种类型: Index/Create/Update/Delete:

```
POST _bulk
{ "index" : { "_index" : "test", "_id" : "1" } }
{ "delete" : { "_index" : "test", "_id" : "2" } }
{ "create" : { "_index" : "test2", "_id" : "3" } }
{ "update" : {"_id" : "1", "_index" : "test"} }
```

mget 批量获取:

```
GET /_mget
{"docs":[{"_index":"test","_id":"1"},{"_index":"test","_id":"2"}]}

#URI中指定index
GET /test/_mget
{"docs":[{"_id":"1"},{"_id":"2"}]}
```

批量查询:

```
POST kibana_sample_data_ecommerce/_msearch
{}
{"query" : {"match_all" : {}},"size":1}
{"index" : "kibana_sample_data_flights"}
{"query" : {"match_all" : {}},"size":2}
```

## 倒排索引入门

![](https://cdn.yangbingdong.com/img/elasticsearch/concept-inverted-index.png)

正排索引与倒排索引:

![](https://cdn.yangbingdong.com/img/elasticsearch/concept-inverted-index02.png)

倒排索引分为两个部分:

* 单词词典(Term Dictionary), 记录了所有文档的单词, 记录单词到**倒排列表**的关联关系
  * 单词词典一般比较大, 可以通过 B+ 树或者哈希拉链法实现, 以满足高性能的插入与查询
* 倒排列表(Posting List), 记录了单词对应的文档结合, 有倒排索引项组成:
  * 文档 ID
  * 词频 TF, 改单词在文档中出现的次数, 用于相关性评分
  * 位置(Position), 单词在文档中分词的位置, 用于语句搜索(phrase query)
  * 偏移(Offset), 记录单词的开始结束位置, 实现高亮显示

一个例子- Elasticsearch:

![](https://cdn.yangbingdong.com/img/elasticsearch/concept-inverted-index03.png)

> 每个 JSON 文档中的每个字段, 又有自己的倒排索引
>
> 可以指定对某些字段不做索引, 以节省存储空间

## 通过 Analyzer 进行分词

分词(Analysis)是把文本转换一系列单词的过程, 通过 Analyzer 实现, 可使用 Elasticsearch 内置的 Analyzer 或者自定义 Analyzer.

除了在数据写入时转换词条, 匹配  Query 语句时也需要用相同的分析器对查询语句进行分析.

分词器(Analyzer)是专门处理分词的组件, 由三个部分组成:

* Character Filters: 针对原始文本处理, 例如去除 HTML 标签
* Tokenizer: 按照规则切分单词
* Token Filter: 将切分的单词进行加工, 小写, 删除 stopwords, 增加同义词等)

![](https://cdn.yangbingdong.com/img/elasticsearch/analyzer-component.png)

*[Elasticsearch 内置分词器](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-analyzers.html)*:

* Standard Analyzer – 默认分词器, 按词切分, 小写处理
* Simple Analyzer – 按照非字母切分(符号被过滤), 小写处理
* Stop Analyzer – 小写处理, 停用词过滤(the, a, is)
* Whitespace Analyzer – 按照空格切分, 不转小写
* Keyword Analyzer – 不分词, 直接将输入当作输出
* Patter Analyzer – 正则表达式, 默认 \W+ (非字符分隔)
* Language – 提供了30多种常见语言的分词器

```
GET _analyze
{
  "analyzer": "standard",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}

GET _analyze
{
  "analyzer": "simple",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}

GET _analyze
{
  "analyzer": "stop",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}

GET _analyze
{
  "analyzer": "whitespace",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}

GET _analyze
{
  "analyzer": "keyword",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}

GET _analyze
{
  "analyzer": "pattern",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}

GET _analyze
{
  "analyzer": "english",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}
```

其他分词器:

***[IK](https://github.com/medcl/elasticsearch-analysis-ik)***

***[HanPL](https://github.com/KennFalcon/elasticsearch-analysis-hanlp)***

***[jieba](https://github.com/sing1ee/elasticsearch-jieba-plugin)***

## Search API 简介

Elasticsearch Search API 提供了 URI Search 以及 Request Body Search. 两者都要遵循以下基本语法:

| 语法                   | 范围              |
| ---------------------- | ----------------- |
| /_search               | 集群上所有的索引  |
| /index1/_search        | index1            |
| /index1,index2/_search | index1, index2    |
| /index*/_search        | 以index开头的索引 |

URI Search:

![](https://cdn.yangbingdong.com/img/elasticsearch/uri-search-demo.png)

Request Body Search:

![](https://cdn.yangbingdong.com/img/elasticsearch/request-body-search-demo.png)

Response:

![](https://cdn.yangbingdong.com/img/elasticsearch/search-response-demo.png)

## QueryDSL介绍

DEMO:

```
POST /kibana_sample_data_ecommerce/_search
{
  "profile": true,  # 这个参数可以输出Elasticsearch是怎么查询的
  "sort":[{"order_date":"desc"}],  # 排序
  "from":10,  # 分页开始
  "size":20,  # 分页结束
  "_source":["order_date"], # 指定返回字段
  "query":{
    "match_all": {}
  }
}
```

* 分页不宜过深, 越往后成本越大
* 排序最好在数字类型或者日期类型上面排序

`match` 查询, 支持全文搜索和精确查询, 取决于字段是否支持全文检索:

```
POST movies/_search
{
  "query": {
    "match": {
      "title": "last christmas"
    }
  }
}
```

全文检索会将查询的字符串先进行分词, `last christmas`会分成为`last`和`christmas`, 然后在倒排索引中进行匹配, 默认是 OR 逻辑, 如果要实现 AND 逻辑, 可以这样处理:

```
POST movies/_search
{
  "query": {
    "match": {
      "title": {
        "query": "last christmas",
        "operator": "and" 
      }
    }
  }
}
```

`match_phrase` 查询, 短语查询，精确匹配，查询`one love`会匹配`title`字段包含`one love`短语的，而不会进行分词查询:

```
POST movies/_search
{
  "query": {
    "match_phrase": {
      "title":{
        "query": "one love",
        "slop": 1
      }
    }
  }
}
```

## Query & Simple Query String

插入数据:

```
PUT /users/_doc/1
{
  "name":"Ruan Yiming",
  "about":"java, golang, node, swift, elasticsearch"
}

PUT /users/_doc/2
{
  "name":"Li Yiming",
  "about":"Hadoop"
}
```

Query String, 类似 URI Query:

```
POST users/_search
{
  "query": {
    "query_string": {
      "default_field": "name",
      "query": "Ruan AND Yiming"
    }
  }
}

POST users/_search
{
  "query": {
    "query_string": {
      "fields":["name","about"],
      "query": "(Ruan AND Yiming) OR (Java AND Elasticsearch)"
    }
  }
}

# 多fields
GET /movies/_search
{
	"profile": true,
	"query":{
		"query_string":{
			"fields":[
				"title",
				"year"
			],
			"query": "2012"
		}
	}
}
```

Simple Query String: 

* 类似 Query String, 但会忽略错误语法, 只支持部分查询语法
* 不支持 AND OR NOT, 会当做字符串处理
* Term 之间的默认关系是 OR, 可以通过 Operator 指定
* 支持部分逻辑
  * `+` 代表 AND
  * `|` 代表 OR
  * `-` 代表 NOT

```
POST users/_search
{
  "query": {
    "simple_query_string": {
      "query": "Ruan Yiming",
      "fields": ["name"],
      "default_operator": "AND"
    }
  }
}

GET /movies/_search
{
	"profile":true,
	"query":{
		"simple_query_string":{
			"query":"Beautiful +mind",
			"fields":["title"]
		}
	}
}
```

## Dynamic Mapping 和常见字段类型

什么是 Mapping:

* Mapping 类似数据库中的 schema
  * 定义索引中的字段名称
  * 定义字段类型
  * 字段倒排索引的相关配置, 比如 Analyzed, Not Analyzed, Analyzer

字段类型:

* 简单类型
  * Text / Keyword
  * Data
  * Integer / Floating
  * Boolean
  * IPv4 / IPv6
* 复杂类型
  * 对象类型 / 嵌套类型
* 特殊类型
  * geo_point & geo_shape / percolator

Dynamic Mapping: 

* 写入文档时候, 索引不存在则自动创建
* 类型自动推断, 但可以通过设置修改这种行为, 比如字符串会推断成 text 类型, 并新增一个 keyword 类型的 keyword 子字段
* 但是会产生不良影响, 比如类型推断错误

通过索引创建事可以指定 Dynamic 的行为:

```
PUT movies
{
  "mapping": {
    "_doc": {
      "dynamic": "false"
    }
  }
}
```

对应的是可以设置成:

* true: 默认值, 可以自动推断
* false: 新增的字段不被索引, 可以存进 ES
* strict: 不能新增字段, 直接报错

## 显式Mapping设置

API:

```
PUT your_index
{
  "mappings": {
    // 自定义
  }
}
```

例如:

```
PUT users
{
    "mappings" : {
      "properties" : {
        "firstName" : {
          "type" : "text"
        },
        "lastName" : {
          "type" : "keyword"
          "null_value": "NULL"
        },
        "mobile" : {
          "type" : "text",
          "index": false
        }
      }
    }
}
```

参数说明:

* `index`: 默认为 true, 设置 false 后字段不能被索引, 同时可以节省存储空间

* `null_value`: 实现 NULL 值的搜索, 只有 Keyword 支持

* `copy_to`: 将字段拷贝到目标字段, 且目标字段不出现在 `_source` 中

  ```
  PUT users
  {
    "mappings": {
      "properties": {
        "firstName":{
          "type": "text",
          "copy_to": "fullName"
        },
        "lastName":{
          "type": "text",
          "copy_to": "fullName"
        }
      }
    }
  }
  
  GET users/_search?q=fullName:(Ruan Yiming)
  ```

  

创建 Mapping 建议: 创建临时索引, 写入样本数据, 获取动态创建的 Mapping 定义, 在这基础上修改.

## 多字段特性及Mapping中配置自定义Analyzer

字段还可以为其创建子字段, 可以实现一些精确匹配(增加 keyword 类型的字段), 或者使用不同的 analyzer(pinyin搜索)

```
PUT my_index
{
  "mappings": {
    "properties": {
      "city": {
        "type": "text",
        "fields": {
          "raw": { 
            "type":  "keyword",
            "ignore_above": 256
          }
        }
      }
    }
  }
}
```

### Exact Values vs Full Text

* Exact Value(精确值, 不会被分词): 包括数字/日期/具体的一个字符串(比如 Apple Store), 对应 ES 中的 keyword
* Full Text(全文本, 默认会分词): 对应 ES 中的 text

![](https://cdn.yangbingdong.com/img/elasticsearch/exact-value-vs-full-value.png)

### 自定义分词器

如果 ES 自带的分词器不满足, 我们可以自定义分词器, 通过组合 *[Character Filter](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-charfilters.html)*, *[Tokenizer](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-tokenizers.html)*, *[Token Filter](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-tokenfilters.html)* 实现:

```
PUT my_index
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_custom_analyzer": { 
          "type": "custom",
          "char_filter": [
            "emoticons"
          ],
          "tokenizer": "punctuation",
          "filter": [
            "lowercase",
            "english_stop"
          ]
        }
      },
      "tokenizer": {
        "punctuation": { 
          "type": "pattern",
          "pattern": "[ .,!?]"
        }
      },
      "char_filter": {
        "emoticons": { 
          "type": "mapping",
          "mappings": [
            ":) => _happy_",
            ":( => _sad_"
          ]
        }
      },
      "filter": {
        "english_stop": { 
          "type": "stop",
          "stopwords": "_english_"
        }
      }
    }
  }
}

# 测试
POST my_index/_analyze
{
  "analyzer": "my_custom_analyzer",
  "text": "I'm a :) person, and you?"
}
```

## Index Template 和 Dynamic Template

### Index Template

创建索引模板(Index Template)可以更好地管理某些索引, 比如日志索引: logs-1, logs-2 这类有规律的索引.

Index Template 可以帮助我们设定 Mapping 和 Settings, 并按照一定规则匹配到新创建的索引之上

* 模板仅在一个索引被新创建时, 才会起作用, 修改模板不会影响已经创建的索引
* 可以设定多个模板, 这些设置会被 merger 在一起, 可以通过 order 的数值, 空值 merging 的过程

Index Template 的工作方式(当一个索引被创建时):

* 应用 ES 默认的 settings 和 mappings
* 应用 order 数值低的 Index Template 设定
* 应用 order 数值高的 Index Template 设定, 之前的设定会被覆盖
* 应用创建索引时, 用户所指定的 settings 和 mappings, 并覆盖之前模板中的设定

```
#数字字符串被映射成text，日期字符串被映射成日期
PUT ttemplate/_doc/1
{
	"someNumber":"1",
	"someDate":"2019/01/01"
}
GET ttemplate/_mapping


#Create a default template
PUT _template/template_default
{
  "index_patterns": ["*"],
  "order" : 0,
  "version": 1,
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas":1
  }
}


PUT /_template/template_test
{
    "index_patterns" : ["test*"],
    "order" : 1,
    "settings" : {
    	"number_of_shards": 1,
        "number_of_replicas" : 2
    },
    "mappings" : {
    	"date_detection": false,
    	"numeric_detection": true
    }
}

#查看template信息
GET /_template/template_default
GET /_template/temp*


#写入新的数据，index以test开头
PUT testtemplate/_doc/1
{
	"someNumber":"1",
	"someDate":"2019/01/01"
}
GET testtemplate/_mapping
get testtemplate/_settings

PUT testmy
{
	"settings":{
		"number_of_replicas":5
	}
}

put testmy/_doc/1
{
  "key":"value"
}

get testmy/_settings
DELETE testmy
DELETE /_template/template_default
DELETE /_template/template_test
```

### Dynamic Template

什么是 Dynamic Template:

* 根据 Elasticsearch 识别的数据类型, 结合字段名称, 来动态设定字段类型, 比如:
  * 所有字符串设定成Keyword, 或者关闭 keyword 字段
  * is 开头的字段都设置成 boolean
  * long_ 开头的都设置成 long 类型
* Dynamic Template 是定义在某个索引的 Mapping 中
* Template 有个一名字
* 匹配规则是一个数组
* 为匹配到的字段设置 Mapping

例子:

```
#Dynaminc Mapping 根据类型和字段名
DELETE my_index

PUT my_index/_doc/1
{
  "firstName":"Ruan",
  "isVIP":"true"
}

GET my_index/_mapping
DELETE my_index
PUT my_index
{
  "mappings": {
    "dynamic_templates": [
            {
        "strings_as_boolean": {
          "match_mapping_type":   "string",
          "match":"is*",
          "mapping": {
            "type": "boolean"
          }
        }
      },
      {
        "strings_as_keywords": {
          "match_mapping_type":   "string",
          "mapping": {
            "type": "keyword"
          }
        }
      }
    ]
  }
}


DELETE my_index
#结合路径
PUT my_index
{
  "mappings": {
    "dynamic_templates": [
      {
        "full_name": {
          "path_match":   "name.*",
          "path_unmatch": "*.middle",
          "mapping": {
            "type":       "text",
            "copy_to":    "full_name"
          }
        }
      }
    ]
  }
}


PUT my_index/_doc/1
{
  "name": {
    "first":  "John",
    "middle": "Winston",
    "last":   "Lennon"
  }
}

GET my_index/_search?q=full_name:John
```

* match_mapping_type: 匹配自动识别的字段类型, 比如 string, boolean等
* match, unmatch: 匹配字段名称
* path_match, path_unmatch: 字段路径

## 聚合分析简介

什么是***[聚合](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html)***? 那就是对数据进行一个分析统计.

![](https://cdn.yangbingdong.com/img/elasticsearch/aggs-demo.png)

聚合主要分为四类:

* Bucket Aggregation: 一些列满足特定条件的文档集合
* Metric Aggregation: 一些数学运算, 可以对文档字段进行统计分析
* Pipeline Aggregation: 对其他的聚合结果进行二次聚合
* Matrix Aggregation: 支持对多个字段的操作并提供一个结果矩阵

![](https://cdn.yangbingdong.com/img/elasticsearch/bucket-and-matrix.png)

一个 Bucket 的例子:

![](https://cdn.yangbingdong.com/img/elasticsearch/bucket-demo.png)

支持嵌套:

![](https://cdn.yangbingdong.com/img/elasticsearch/bucket-nest-demo.png)

```
#按照目的地进行分桶统计
GET kibana_sample_data_flights/_search
{
	"size": 0,
	"aggs":{
		"flight_dest":{
			"terms":{
				"field":"DestCountry"
			}
		}
	}
}



#查看航班目的地的统计信息，增加平均，最高最低价格
GET kibana_sample_data_flights/_search
{
	"size": 0,
	"aggs":{
		"flight_dest":{
			"terms":{
				"field":"DestCountry"
			},
			"aggs":{
				"avg_price":{
					"avg":{
						"field":"AvgTicketPrice"
					}
				},
				"max_price":{
					"max":{
						"field":"AvgTicketPrice"
					}
				},
				"min_price":{
					"min":{
						"field":"AvgTicketPrice"
					}
				}
			}
		}
	}
}



#价格统计信息+天气信息
GET kibana_sample_data_flights/_search
{
	"size": 0,
	"aggs":{
		"flight_dest":{
			"terms":{
				"field":"DestCountry"
			},
			"aggs":{
				"stats_price":{
					"stats":{
						"field":"AvgTicketPrice"
					}
				},
				"wather":{
				  "terms": {
				    "field": "DestWeather",
				    "size": 5
				  }
				}

			}
		}
	}
}

```

