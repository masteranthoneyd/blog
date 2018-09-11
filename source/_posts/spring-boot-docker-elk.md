---
title: Spring Boot应用集成Docker并结合Kafka、ELK管理Docker日志
date: 2018-04-02 13:00:19
categories: [Programming, Java, Spring Boot]
tags: [Docker, Spring Boot, Java, Spring, Elasticsearch]
---

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-docker-integration/java-docker.png)

# Preface

> 微服务架构下，微服务在带来良好的设计和架构理念的同时，也带来了运维上的额外复杂性，尤其是在服务部署和服务监控上。单体应用是集中式的，就一个单体跑在一起，部署和管理的时候非常简单，而微服务是一个网状分布的，有很多服务需要维护和管理，对它进行部署和维护的时候则比较复杂。集成Docker之后，我们可以很方便地部署以及编排服务，ELK的集中式日志管理可以让我们很方便地聚合Docker日志。

<!--more-->

# Spring Boot Docker Integration

## 准备工作

- Docker
- IDE（使用IDEA）
- Maven环境
- Docker私有仓库，可以使用Harbor(***[Ubuntu中安装Harbor](/2018/docker-visual-management-and-orchestrate-tools/#Harbor)***)

集成Docker需要的插件`docker-maven-plugin`：*[https://github.com/spotify/docker-maven-plugin](https://github.com/spotify/docker-maven-plugin)*

## 安全认证配置

> 当我们 push 镜像到 Docker 仓库中时，不管是共有还是私有，经常会需要安全认证，登录完成之后才可以进行操作。当然，我们可以通过命令行 `docker login -u user_name -p password docker_registry_host` 登录，但是对于自动化流程来说，就不是很方便了。使用 docker-maven-plugin 插件我们可以很容易实现安全认证。

### 普通配置

`settings.xml`：

```
<server>
    <id>docker-registry</id>
    <username>admin</username>
    <password>12345678</password>
    <configuration>
        <email>yangbingdong1994@gmail.com</email>
    </configuration>
</server>
```

### Maven 密码加密配置

`settings.xml`配置私有库的访问：

首先使用你的私有仓库访问密码生成主密码：

```
mvn --encrypt-master-password <password>
```

其次在`settings.xml`文件的同级目录创建`settings-security.xml`文件，将主密码写入：

```
<?xml version="1.0" encoding="UTF-8"?>
<settingsSecurity>
  <master>{Ns0JM49fW9gHMTZ44n*****************=}</master>
</settingsSecurity>

```

最后使用你的私有仓库访问密码生成服务密码，将生成的密码写入到`settings.xml`的`<services>`中（可能会提示目录不存在，解决方法是创建一个`.m2`目录并把`settings-security.xml`复制进去）

```
mvn --encrypt-password <password>
{D9YIyWYvtYsHayLjIenj***********=}
```
```
<server>
    <id>docker-registry</id>
    <username>admin</username>
    <password>{gKLNhblk/SQHBMooM******************=}</password>
    <configuration>
        <email>yangbingdong1994@gmail.com</email>
    </configuration>
</server>
```

## 构建基础镜像

Dockerfile：

```
FROM frolvlad/alpine-oraclejdk8:slim
MAINTAINER ybd <yangbingdong1994@gmail.com>
ARG TZ 
ARG HTTP_PROXY
ENV TZ=${TZ:-"Asia/Shanghai"} http_proxy=${HTTP_PROXY} https_proxy=${HTTP_PROXY}
RUN apk update && \
    apk add --no-cache && \
    apk add curl bash tree tzdata && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone 
ENV http_proxy=
ENV https_proxy=
```

构建：

```
docker build --build-arg HTTP_PROXY=192.168.6.113:8118 -t yangbingdong/docker-oraclejdk8 .
```

其中`HTTP_PROXY`是http代理，通过`--build-arg`参数传入，注意**不能**是`127.0.0.1`或`localhost`。

## 开始集成

### 编写Dockerfile

在`src/main`下面新建`docker`文件夹，并创建`Dockerfile`：

```
FROM yangbingdong/docker-oraclejdk8:latest
MAINTAINER yangbingdong <yangbingdong1994@gmail.com>
ENV PROJECT_NAME="@project.build.finalName@.@project.packaging@" JAVA_OPTS=""
ADD $PROJECT_NAME app.jar
RUN sh -c 'touch /app.jar'
ENTRYPOINT exec java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -DLog4jContextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector -Dspring.profiles.active=${ACTIVE:-docker} -jar /app.jar
```

* 通过`@@`动态获取打包后的项目名（需要插件，下面会介绍）
* `Dspring.profiles.active=${ACTIVE:-docker}`可以通过docker启动命令`-e ACTIVE=docker`参数修改配置

#### 注意PID

如果需要Java程序监听到`sigterm`信号，那么Java程序的`PID`必须是1，可以使用`ENTRYPOINT exec java -jar ...`这种方式实现。 

### pom文件添加构建Docker镜像的相关插件

> 继承`spring-boot-starter-parent`，除了`docker-maven-plugin`，下面的3个插件都不用填写版本号，因为parent中已经定义版本号

#### spring-boot-maven-plugin

这个不用多介绍了，打包Spring Boot Jar包的

```
    <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <executions>
            <execution>
                <goals>
                    <goal>repackage</goal>
                </goals>
            </execution>
        </executions>
    </plugin>
```

#### maven-resources-plugin

resources插件，使用`@变量@`形式获取Maven变量到Dockerfile中（同时拷贝构建的Jar包到Dockerfile同一目录中，这种方式是方便手动构建镜像）

```
    <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-resources-plugin</artifactId>
        <executions>
            <execution>
                <id>prepare-dockerfile</id>
                <phase>validate</phase>
                <goals>
                    <goal>copy-resources</goal>
                </goals>
                <configuration>
                <!-- 编译后Dockerfile的输出位置 -->
                    <outputDirectory>${dockerfile.compiled.position}</outputDirectory>
                    <resources>
                    	<!-- Dockerfile位置 -->
                        <resource>
                            <directory>${project.basedir}/src/main/docker</directory>
                            <filtering>true</filtering>
                        </resource>
                    </resources>
                </configuration>
            </execution>
            <!-- 将Jar复制到target的docker目录中，因为真正的Dockerfile也是在里面，方便使用docker build命令构建Docker镜像 -->
            <execution>
                <id>copy-jar</id>
                <phase>package</phase>
                <goals>
                    <goal>copy-resources</goal>
                </goals>
                <configuration>
                    <outputDirectory>${dockerfile.compiled.position}</outputDirectory>
                    <resources>
                        <resource>
                            <directory>${project.build.directory}</directory>
                            <includes>
                                <include>*.jar</include>
                            </includes>
                        </resource>
                    </resources>
                </configuration>
            </execution>
        </executions>
    </plugin>
```

#### build-helper-maven-plugin

这个是为了给镜像添加基于时间戳的版本号，maven也有自带的获取时间戳的变量`maven.build.timestamp.format` + `maven.build.timestamp`:

```
<maven.build.timestamp.format>yyyy-MM-dd_HH-mm-ss<maven.build.timestamp.format>

# 获取时间戳
${maven.build.timestamp}
```

但是这个时区是`UTC`，接近于格林尼治标准时间，所以出来的时间会比但前的时间慢8个小时。

如果要使用`GMT+8`，就需要`build-helper-maven-plugin`插件，当然也有其他的实现方式，这里不做展开。

```
<build>
    <plugins>
        <plugin>
            <groupId>org.codehaus.mojo</groupId>
            <artifactId>build-helper-maven-plugin</artifactId>
            <executions>
                <execution>
                    <id>timestamp-property</id>
                    <goals>
                        <goal>timestamp-property</goal>
                    </goals>
                    <configuration>
                    	<!-- 其他地方可通过${timestamp}获取时间戳 -->
                        <name>timestamp</name>
                        <pattern>yyyyMMddHHmm</pattern>
                        <timeZone>GMT+8</timeZone>
                    </configuration>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

然后可以在pom中使用`${timestamp}`获取时间戳。

当然，也可以使用**另外一种方式实现**，打包前`export`一个格式化日期的环境变量，`pom.xml`中获取这个变量：

* `export DOCKER_IMAGE_TAGE_DATE=yyyy-MM-dd_HH-mm`
* `mvn help:system`可查看所有环境变量
* 所有的环境变量都可以用以`env.`开头的Maven属性引用: `${env.DOCKER_IMAGE_TAGE_DATE}`

#### docker-maven-plugin

这也是集成并构建Docker镜像的关键

```
    <plugin>
        <groupId>com.spotify</groupId>
        <artifactId>docker-maven-plugin</artifactId>
        <version>${docker-maven-plugin.version}</version>
        <!--  -->
        <!-- 绑定打包阶段执行Docker镜像操作 -->
        <executions>
            <execution>
                <!-- 打包阶段构建镜像 -->
                <phase>package</phase>
                <goals>
                    <goal>build</goal>
                </goals>
            </execution>
            <execution>
                <!-- 部署阶段Push镜像 -->
                <id>push-image</id>
                <phase>deploy</phase>
                <goals>
                    <goal>push</goal>
                </goals>
                <!-- Push指定镜像 -->
                <configuration>
                    <!--<imageName>${docker.registry.url}/${docker.registry.name}/${project.artifactId}:${docker-latest-tag}</imageName>-->
                    <!--suppress UnresolvedMavenProperty -->
                    <imageName>${docker.registry.url}/${docker.registry.name}/${project.artifactId}:${timestamp}</imageName>
                </configuration>
            </execution>
        </executions>
        <configuration>
            <!-- 是否跳过所有构建Docker镜像阶段 -->
            <skipDocker>${docker.skip.build}</skipDocker>
            <!-- 是否跳过Push阶段 -->
            <skipDockerPush>${docker.skip.push}</skipDockerPush>
            <forceTags>true</forceTags>
            <!-- 最大重试次数 -->
            <retryPushCount>2</retryPushCount>
            <imageTags>
                <!-- 使用时间戳版本号 -->
                <!--suppress UnresolvedMavenProperty -->
                <imageTag>${timestamp}</imageTag>
            </imageTags>
            <!-- 配置镜像名称，遵循Docker的命名规范： springio/image --><imageName>${docker.registry.url}/${docker.registry.name}/${project.artifactId}</imageName>
            <!-- Dockerfile位置，由于配置了编译时动态获取Maven变量，真正的Dockerfile位于位于编译后位置 -->
            <dockerDirectory>${dockerfile.compiled.position}</dockerDirectory>
            <resources>
                <resource>
                    <targetPath>/</targetPath>
                    <directory>${project.build.directory}</directory>
                    <include>${project.build.finalName}.jar</include>
                </resource>
            </resources>
            <!-- 被推送服务器的配置ID，与setting中的一直 -->
            <serverId>docker-registry</serverId>
            <!--<registryUrl>${docker.registry.url}</registryUrl>-->
        </configuration>
    </plugin>
```

主要`properties`:

```
<properties>
    <!-- ########## Docker 相关变量 ########## -->
    <docker-maven-plugin.version>1.0.0</docker-maven-plugin.version>
    <!-- resource插件编译Dockerfile后的位置-->
    <dockerfile.compiled.position>${project.build.directory}/docker</dockerfile.compiled.position>
    <docker.skip.build>false</docker.skip.build>
    <docker.skip.push>false</docker.push.image>
    <docker.registry.url>192.168.0.202:8080</docker.registry.url>
    <docker.registry.name>dev-images</docker.registry.name>
    <docker-latest-tag>latest</docker-latest-tag>
</properties>
```

**说明**：

* 这里的`serverId`要与maven `setting.xml`里面的一样


* Dockerfile构建文件在`src/main/docker`中
* 如果Dockerfile文件需要maven构建参数（比如需要构建后的打包文件名等），则使用`@@`占位符（如`@project.build.finalName@`）原因是Sping Boot 的pom将resource插件的占位符由`${}`改为`@@`，非继承Spring Boot 的pom文件，则使用`${}`占位符
* 如果不需要动态生成Dockerfile文件，则可以将Dockerfile资源拷贝部分放入`docker-maven-plugin`插件的`<resources>`配置里
* **`spring-boot-maven-plugin`插件一定要在其他构建插件之上，否则打包文件会有问题。**



`docker-maven-plugin` 插件还提供了很多很实用的配置，稍微列举几个参数吧。

| 参数                                      | 说明                                                         | 默认值 |
| ----------------------------------------- | ------------------------------------------------------------ | ------ |
| `<forceTags>true</forceTags>`             | build 时强制覆盖 tag，配合 imageTags 使用                    | false  |
| `<noCache>true</noCache>`                 | build 时，指定 –no-cache 不使用缓存                          | false  |
| `<pullOnBuild>true</pullOnBuild>`         | build 时，指定 –pull=true 每次都重新拉取基础镜像             | false  |
| `<pushImage>true</pushImage>`             | build 完成后 push 镜像                                       | false  |
| `<pushImageTag>true</pushImageTag>`       | build 完成后，push 指定 tag 的镜像，配合 imageTags 使用      | false  |
| `<retryPushCount>5</retryPushCount>`      | push 镜像失败，重试次数                                      | 5      |
| `<retryPushTimeout>10</retryPushTimeout>` | push 镜像失败，重试时间                                      | 10s    |
| `<rm>true</rm>`                           | build 时，指定 –rm=true 即 build 完成后删除中间容器          | false  |
| `<useGitCommitId>true</useGitCommitId>`   | build 时，使用最近的 git commit id 前7位作为tag，例如：image:b50b604，前提是不配置 newName | false  |

更多参数可查看插件中的定义。

### 命令构建

如果`<skipDockerPush>false</skipDockerPush>`则install阶段将不提交Docker镜像，只有maven的`deploy`阶段才提交。

```
mvn clean install
```

```
[INFO] --- spring-boot-maven-plugin:1.5.9.RELEASE:repackage (default) @ eureka-center-server ---
[INFO] 
[INFO] --- docker-maven-plugin:1.0.0:build (default) @ eureka-center-server ---
[INFO] Using authentication suppliers: [ConfigFileRegistryAuthSupplier, NoOpRegistryAuthSupplier]
[WARNING] Ignoring run because dockerDirectory is set
[INFO] Copying /home/ybd/data/git-repo/bitbucket/ms-iba/eureka-center-server/target/eureka-center-server-0.0.1-SNAPSHOT.jar -> /home/ybd/data/git-repo/bitbucket/ms-iba/eureka-center-server/target/docker/eureka-center-server-0.0.1-SNAPSHOT.jar
[INFO] Copying /home/ybd/data/git-repo/bitbucket/ms-iba/eureka-center-server/target/docker/eureka-center-server-0.0.1-SNAPSHOT.jar -> /home/ybd/data/git-repo/bitbucket/ms-iba/eureka-center-server/target/docker/eureka-center-server-0.0.1-SNAPSHOT.jar
[INFO] Copying /home/ybd/data/git-repo/bitbucket/ms-iba/eureka-center-server/target/docker/Dockerfile -> /home/ybd/data/git-repo/bitbucket/ms-iba/eureka-center-server/target/docker/Dockerfile
[INFO] Building image 192.168.6.113:8888/discover-server/eureka-center-server
Step 1/7 : FROM frolvlad/alpine-oraclejdk8:slim

 ---> 491f45037124
Step 2/7 : MAINTAINER ybd <yangbingdong1994@gmail.com>

 ---> Using cache
 ---> 016c2033bd32
Step 3/7 : VOLUME /tmp

 ---> Using cache
 ---> d2a287b6ed52
Step 4/7 : ENV PROJECT_NAME="eureka-center-server-0.0.1-SNAPSHOT.jar" JAVA_OPTS=""

 ---> Using cache
 ---> 34565a7de714
Step 5/7 : ADD $PROJECT_NAME app.jar

 ---> 64d9055ce969
Step 6/7 : RUN sh -c 'touch /app.jar'

 ---> Running in 66f4eb550a57
Removing intermediate container 66f4eb550a57
 ---> 93486965cad9
Step 7/7 : CMD ["sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -Dspring.profiles.active=${ACTIVE:-docker}  -jar /app.jar"]

 ---> Running in 8b42c471791f
Removing intermediate container 8b42c471791f
 ---> 2eb3dbbab6c5
ProgressMessage{id=null, status=null, stream=null, error=null, progress=null, progressDetail=null}
Successfully built 2eb3dbbab6c5
Successfully tagged 192.168.6.113:8888/discover-server/eureka-center-server:latest
[INFO] Built 192.168.6.113:8888/discover-server/eureka-center-server
[INFO] Tagging 192.168.6.113:8888/discover-server/eureka-center-server with 0.0.1-SNAPSHOT
[INFO] Tagging 192.168.6.113:8888/discover-server/eureka-center-server with latest
[INFO] Pushing 192.168.6.113:8888/discover-server/eureka-center-server
The push refers to repository [192.168.6.113:8888/discover-server/eureka-center-server]
40566d372b69: Pushed 
40566d372b69: Layer already exists 
4fd38f0d6712: Layer already exists 
d7cd646c41bd: Layer already exists 
ced237d13962: Layer already exists 
2aebd096e0e2: Layer already exists 
null: null 
null: null 
[INFO] 
[INFO] --- maven-install-plugin:2.4:install (default-install) @ eureka-center-server ---
[INFO] Installing /home/ybd/data/git-repo/bitbucket/ms-iba/eureka-center-server/target/eureka-center-server-0.0.1-SNAPSHOT.jar to /home/ybd/data/application/maven/maven-repo/com/iba/server/eureka-center-server/0.0.1-SNAPSHOT/eureka-center-server-0.0.1-SNAPSHOT.jar
[INFO] Installing /home/ybd/data/git-repo/bitbucket/ms-iba/eureka-center-server/pom.xml to /home/ybd/data/application/maven/maven-repo/com/iba/server/eureka-center-server/0.0.1-SNAPSHOT/eureka-center-server-0.0.1-SNAPSHOT.pom
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 15.962 s
[INFO] Finished at: 2017-12-25T13:33:39+08:00
[INFO] Final Memory: 55M/591M
[INFO] ------------------------------------------------------------------------
```

可以看到本地以及私有仓库都多了一个镜像：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-docker-integration/portainer.png)

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-docker-integration/harbor.png)

**此处有个疑问**，很明显看得出来这里上传了两个一样大小的包，不知道是不是同一个jar包，但id又不一样：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-docker-integration/duplicate01.png)

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-docker-integration/duplicate02.png)

### 运行Docker

运行程序

```
docker run --name some-server -e ACTIVE=docker -p 8080:8080 -d [IMAGE]
```

### 添加运行时JVM参数

只需要在Docker启动命令中加上`-e "JAVA_OPTS=-Xmx128m"`即可

## Demo地址

***[https://github.com/masteranthoneyd/spring-boot-learning/tree/master/spring-boot-docker](https://github.com/masteranthoneyd/spring-boot-learning/tree/master/spring-boot-docker)***

#  Kafka、ELK collect logs

![](http://ojoba1c98.bkt.clouddn.com/img/docker-logs-collect/elk-arch1.png)

传统的应用可以将日志存到日志中，但集成Docker之后，日志怎么处理？放到容器的某个目录然后挂在出来？这样也可以，但这样就相当于给容器与外界绑定了一个状态，弹性伸缩怎么办？个人还是觉得通过队列与ELK管理Docker日志比较合理，而且Log4j2**原生支持Kafka的Appender**。

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

## 启动Kafka与Zookeeper

这里直接使用docker-compose（需要先创建外部网络）:

```
version: '3'
services:
  zoo:
    image: zookeeper:latest
    ports:
    - "2181:2181"
    restart: always
    networks:
      backend:
        aliases:
        - zoo

  kafka:
    image: wurstmeister/kafka:1.1.0
    ports:
    - "9092:9092"
    environment:
    - KAFKA_PORT=9092
    - KAFKA_ADVERTISED_HOST_NAME=192.168.6.113
    - KAFKA_ZOOKEEPER_CONNECT=zoo:2181
    - KAFKA_ADVERTISED_PORT=9092
    volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    depends_on:
    - zoo
    restart: always
    networks:
      backend:
        aliases:
        - kafka

networks:
  backend:
    external:
      name: backend
```

* `KAFKA_ADVERTISED_HOST_NAME`是内网IP，本地调试用，Docker环境下换成`kafka`（与别名`aliases的值保持一致`），其他Docker应用可通过`kafka:9092`这个域名访问到Kafka。

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

## 程序Log4j2配置

**SpringBoot版本：2.0**

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
            <Property name="request.timeout.ms">5000</Property>
            <Property name="transaction.timeout.ms">5000</Property>
            <Property name="max.block.ms">3000</Property>
        </Kafka>
        
        <Async name="async" includeLocation="true">
            <AppenderRef ref="kafka"/>
        </Async>
    </Appenders>

    <Loggers>
        <AsyncRoot level="info" includeLocation="true">
            <AppenderRef ref="console"/>
            <AppenderRef ref="async"/>
        </AsyncRoot>
    </Loggers>
</configuration>
```

* `bootstrap.servers`是kafka的地址，接入Docker network之后可以配置成`kafka:9092`
* `topic`要与下面Logstash的一致
* KafkaAppender默认是同步阻塞模式，使用`Async`包装成异步
* `max.block.ms`默认为60s，在kafka异常时可能导致日志很久才出来
* 更多配置请看 ***[官方说明](https://logging.apache.org/log4j/2.x/manual/appenders.html#KafkaAppender)***

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

# log-pilot

Github: ***[https://github.com/AliyunContainerService/log-pilot](https://github.com/AliyunContainerService/log-pilot)***

更多说明: ***[https://yq.aliyun.com/articles/69382](https://yq.aliyun.com/articles/69382)***

这个是Ali开源的日志收集组件，通过中间件的方式部署，自动监听其他容器的日志，非常方便：

```
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v /etc/localtime:/etc/localtime -v /:/host -e PILOT_TYPE=fluentd -e FLUENTD_OUTPUT=elasticsearch -e ELASTICSEARCH_HOST=192.168.6.113 -e ELASTICSEARCH_PORT=9200 -e TZ=Asia/Chongqing --privileged registry.cn-hangzhou.aliyuncs.com/acs-sample/log-pilot:latest
```

需要手机日志的容器：

```
docker run --rm --label aliyun.logs.demo=stdout -p 8080:8080 192.168.0.202:8080/dev-images/demo:latest
```

* 通过`--label aliyun.logs.demo=stdout`告诉`log-pilot`需要收集日志，索引为`demo`

然后打开Kibana就可以看到日志了。

问题：

* 日志稍微延迟
* 日志顺序混乱
* 异常堆栈不集中