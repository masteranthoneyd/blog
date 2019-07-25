> ***[Elasticsearch核心技术与实战](https://time.geekbang.org/course/intro/197)*** 笔记
>
> 全部课件: ***[https://github.com/geektime-geekbang/geektime-ELK](https://github.com/geektime-geekbang/geektime-ELK)***

# 基础篇

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
    image: lmenezes/cerebro:0.8.3
    container_name: cerebro
    ports:
      - "9001:9000"
    command:
      - -Dhosts.0.host=http://elasticsearch:9200
    networks:
      - es7net
  kibana:
    image: docker.elastic.co/kibana/kibana:7.1.0
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
    image: docker.elastic.co/elasticsearch/elasticsearch:7.1.0
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
    image: docker.elastic.co/elasticsearch/elasticsearch:7.1.0
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
    image: docker.elastic.co/logstash/logstash:7.1.0
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



