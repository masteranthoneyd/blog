![](http://ojoba1c98.bkt.clouddn.com/img/docker-logs-collect/elk-arch1.png)

#  ELK结合Log4j2、Kafka收集Docker日志

## 程序Log4j2配置

SpringBoot版本：2.0

`log4j2.xml`:

```
<?xml version="1.0" encoding="UTF-8"?>
<configuration status="OFF" monitorInterval="30">
    <properties>
        <Property name="fileName">logs</Property>
        <Property name="fileGz">logs/7z</Property>
        <Property name="PID">????</Property>
        <Property name="LOG_PATTERN">%d{yyyy-MM-dd HH:mm:ss.SSS} | %5p | ${sys:PID} | %15.15t | %-50.50c{1.} | %5L | %M | %msg%n%xwEx
        </Property>
    </properties>

    <Appenders>
        <Console name="console" target="SYSTEM_OUT">
            <ThresholdFilter level="info" onMatch="ACCEPT" onMismatch="DENY"/>
            <PatternLayout pattern="${LOG_PATTERN}" charset="UTF-8"/>
        </Console>

        <Kafka name="kafka" topic="log-collect">
            <ThresholdFilter level="info" onMatch="ACCEPT" onMismatch="DENY"/>
            <PatternLayout pattern="${LOG_PATTERN}" charset="UTF-8"/>
            <Property name="bootstrap.servers">192.168.6.113:9092</Property>
        </Kafka>
    </Appenders>

    <Loggers>
        <AsyncRoot level="info" includeLocation="true">
            <AppenderRef ref="console"/>
            <AppenderRef ref="kafka"/>
        </AsyncRoot>
    </Loggers>
</configuration>
```

打印日志：

```
@Slf4j
@Component
public class LogIntervalSender {
	private AtomicInteger atomicInteger = new AtomicInteger(0);

	@Scheduled(fixedDelay = 2000)
	public void doScheduled() {
		try {
			int i = atomicInteger.incrementAndGet();
			randomThrowException(i);
			log.info("{} send a message: the sequence is {} , random uuid is {}", currentThread().getName(), i, randomUUID());
		} catch (Exception e) {
			log.error("catch an exception:", e);
		}
	}

	private void randomThrowException(int i) {
		if (i % 10 == 0) {
			throw new RuntimeException("this is a random exception, sequence = " + i);
		}
	}
}
```

## 镜像准备

Docker Hub中的ELK镜像并不是最新版本的，我们需要到官方的网站获取最新的镜像：***[https://www.docker.elastic.co](https://www.docker.elastic.co)***

```
docker pull zookeeper
docker pull wurstmeister/kafka:1.0.0
docker pull docker.elastic.co/elasticsearch/elasticsearch:6.2.3
docker pull docker.elastic.co/kibana/kibana:6.2.3
docker pull docker.elastic.co/logstash/logstash:6.2.3
```

注意ELK版本最好保持一致

## Kafka Compose

使用docker-compose:

```
version: '3.4'
services:
  zoo:
    image: zookeeper:latest
    ports:
      - "2181:2181"
    restart: always
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 60s
        max_attempts: 5
      placement:
        constraints:
          - node.hostname == ybd-PC
    networks: 
      - backend

  kafka:
    image: wurstmeister/kafka:1.0.0
    ports:
      - "9092:9092"
    environment:
      KAFKA_ADVERTISED_HOST_NAME: 192.168.6.113
      KAFKA_ZOOKEEPER_CONNECT: zoo:2181
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    depends_on:
      - zoo
    restart: always
    networks: 
      - backend

networks:
  backend:
    external:
      name: backend
```

## ELK Compose

`logstash.conf`配置文件(**注意下面的topics要与上面log4j2.xml中的一样**):

```
input {
    kafka {
        bootstrap_servers => ["kafka:9092"]
        auto_offset_reset => "latest"
#        consumer_threads => 5
        topics => ["log-collect"]
    } 
}
filter {
  #Only matched data are send to output.
}
output {
    stdout {
      codec => rubydebug { }
    }
    elasticsearch {
        action => "index"                #The operation on ES
        codec  => rubydebug
        hosts  => ["elasticsearch:9200"]      #ElasticSearch host, can be array.
        index  => "logstash-%{+YYYY.MM.dd}"      #The index to write data to.
    }
}
```

`docker-compose.yml`:

```
version: '3.4'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:6.2.3
    ports:
      - "9200:9200"
    restart: always
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    networks:
      - backend

  kibana:
    image: docker.elastic.co/kibana/kibana:6.2.3
    ports:
      - "5601:5601"
    restart: always
    networks:
      - backend
    environment:
      - ELASTICSEARCH_URL=http://elasticsearch:9200
    depends_on:
      - elasticsearch

  logstash:
    image: docker.elastic.co/logstash/logstash:6.2.3
    ports:
      - "4560:4560"
    restart: always
    volumes:
      - /docker/elk/logstash/config/logstash.conf:/etc/logstash.conf
    networks:
      - backend
    depends_on:
      - elasticsearch
    entrypoint:
      - logstash
      - -f
      - /etc/logstash.conf

# docker network create -d=overlay --attachable backend
networks:
  backend:
    external:
      name: backend
```

![](http://ojoba1c98.bkt.clouddn.com/img/docker-logs-collect/kibana.png)



`          ``<``pattern``>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - traceId:[%X{mdc_trace_id}] - %msg%n</``pattern``>`