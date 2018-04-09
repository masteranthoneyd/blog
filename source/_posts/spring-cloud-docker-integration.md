---
title: 基于Docker构建高可用Eureka并提交到私有仓库
date: 2018-01-02 13:00:19
categories: [Programming, Java, Spring Cloud]
tags: [Docker, Spring Cloud, Java, Spring]
---

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-docker-integration/dev-ops)

> 微服务架构下，微服务在带来良好的设计和架构理念的同时，也带来了运维上的额外复杂性，尤其是在服务部署和服务监控上。单体应用是集中式的，就一个单体跑在一起，部署和管理的时候非常简单，而微服务是一个网状分布的，有很多服务需要维护和管理，对它进行部署和维护的时候则比较复杂。

<!--more-->

# 准备工作

- 安装Docker
- IDE（使用IDEA）
- Maven环境
- Docker私有仓库

集成Docker需要的插件`docker-maven-plugin`：*[https://github.com/spotify/docker-maven-plugin](https://github.com/spotify/docker-maven-plugin)*

**注意**，此篇使用`Spring Cloud Eureka`作为例子，并实现高可用

# Maven setting.xml配置

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
      <password>{D9YIyWYvtYsHayLjIenj***********=}</password>
      <configuration>
        <email>yangbingdong1994@gmail.com</email>
      </configuration>
    </server>
```

# 构建基础镜像

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
docker build --build-arg HTTP_PROXY=192.168.6.113:8118 -t yangbingdong/oraclejdk8 .
```

其中`HTTP_PROXY`是sock5代理转过来的http代理，通过`--build-arg`参数传入，注意**不能**是`127.0.0.1`或`localhost`。

# Step1、利用IDEA的Spring Initializr构建高可用Eureka工程

项目结构：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-docker-integration/structure.png)

```
@SpringBootApplication
@EnableEurekaServer
public class EurekaserverApplication {

	public static void main(String[] args) {
		SpringApplication.run(EurekaserverApplication.class, args);
	}
}
```

`application-peer1.properties`:

```
server.port=5001
spring.application.name=eureka-center-server
eureka.instance.hostname=peer1
#eureka.instance.prefer-ip-address=true
#eureka.instance.instance-id=${spring.cloud.client.ipAddress}:${server.port}
#eureka.client.register-with-eureka=false
eureka.client.fetch-registry=true
eureka.server.enable-self-preservation=false
#eureka.instance.ip-address=true
spring.output.ansi.enabled=ALWAYS
eureka.client.serviceUrl.defaultZone=http://peer2:5002/eureka/
```

`application-peer2.properties`:
```
server.port=5002
spring.application.name=eureka-center-server
eureka.instance.hostname=peer2
#eureka.instance.prefer-ip-address=true
#eureka.instance.instance-id=${spring.cloud.client.ipAddress}:${server.port}
#eureka.client.register-with-eureka=false
eureka.client.fetch-registry=true
eureka.server.enable-self-preservation=false
#eureka.instance.ip-address=true
spring.output.ansi.enabled=ALWAYS
eureka.client.serviceUrl.defaultZone=http://peer1:5001/eureka/
```

# Step2、创建Dockerfile

在`src/main`下面新建`docker`文件夹，并创建`Dockerfile`：

```
FROM yangbingdong/docker-oraclejdk8
MAINTAINER ybd <yangbingdong1994@gmail.com>
VOLUME /tmp
ENV PROJECT_NAME="@project.build.finalName@.@project.packaging@" JAVA_OPTS=""
ADD $PROJECT_NAME app.jar

RUN sh -c 'touch /app.jar'

CMD ["sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -Dspring.profiles.active=${ACTIVE:-docker1} -jar /app.jar"]
# ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app.jar" ]
```

# Step3、添加插件

在完整的`pom.xml`

```
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>

	<groupId>com.ybd.server</groupId>
	<artifactId>eureka-center-server</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<packaging>jar</packaging>
	<name>eureka-center-server</name>
	<description>统一服务注册中心</description>

    <properties>
        <resources.plugin.version>3.0.2</resources.plugin.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
        <java.version>1.8</java.version>
        <spring-boot.version>1.5.9.RELEASE</spring-boot.version>
        <spring-boot-maven-plugin.version>1.5.9.RELEASE</spring-boot-maven-plugin.version>
        <spring-cloud.version>Edgware.RELEASE</spring-cloud.version>
        <maven.test.skip>true</maven.test.skip>

        <docker.plugin.version>1.0.0</docker.plugin.version>
        <dockerfile.compiled.position>${project.build.directory}/docker</dockerfile.compiled.position>
        <docker.registry.name>discover-server</docker.registry.name>
        <docker.registry.url>192.168.6.113:8888</docker.registry.url>
        <docker.skip.build>false</docker.skip.build>
        <docker.push.image>false</docker.push.image>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-dependencies</artifactId>
                <version>${spring-boot.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>${spring-cloud.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

	<dependencies>
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-eureka-server</artifactId>
		</dependency>
        <!--配置需要认证的eureka所需要引用的包-->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
	</dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <version>${spring-boot-maven-plugin.version}</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>repackage</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>

            <!-- resources插件，使用@变量@形式获取Maven变量到Dockerfile中 -->
            <plugin>
                <artifactId>maven-resources-plugin</artifactId>
                <version>${resources.plugin.version}</version>
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
                </executions>
            </plugin>
            <!-- 集成Docker maven 插件 -->
            <plugin>
                <groupId>com.spotify</groupId>
                <artifactId>docker-maven-plugin</artifactId>
                <version>${docker.plugin.version}</version>
                <executions>
                    <execution>
                        <phase>package</phase>
                        <goals>
                            <goal>build</goal>
                        </goals>
                    </execution>
                    <execution>
                        <id>push-image</id>
                        <phase>deploy</phase>
                        <goals>
                            <goal>push</goal>
                        </goals>
                        <configuration>
                            <imageName>${docker.registry.url}/${docker.registry.name}/${project.artifactId}:latest</imageName>
                        </configuration>
                    </execution>
                </executions>
                <configuration>
                    <!--配置变量，包括是否build、imageName、imageTag，非常灵活-->
                    <skipDocker>${docker.skip.build}</skipDocker>
                    <!--最后镜像产生了两个tag，版本和和最新的-->
                    <forceTags>true</forceTags>
                    <imageTags>
                        <imageTag>${project.version}</imageTag>
                        <imageTag>latest</imageTag>
                    </imageTags>
                    <!--install阶段也上传，否则只有deploy阶段上传-->
                    <pushImage>${docker.push.image}</pushImage>
                    <!-- 配置镜像名称，遵循Docker的命名规范： springio/image -->
                    <imageName>${docker.registry.url}/${docker.registry.name}/${project.artifactId}</imageName>
                    <!-- Dockerfile位置，由于配置了编译时动态获取Maven变量，真正的Dockerfile位于位于编译后位置 -->
                    <dockerDirectory>${dockerfile.compiled.position}</dockerDirectory>
                    <resources>
                        <!-- 构建时需要的资源文件，这些文件和Dockerfile放在一起，这里只需要Spring Boot生成的jar文件即可 -->
                        <resource>
                            <targetPath>/</targetPath>
                            <directory>${project.build.directory}</directory>
                            <include>${project.build.finalName}.jar</include>
                        </resource>
                    </resources>
                    <!--push到私有的hub-->
                    <serverId>docker-registry</serverId>
                    <registryUrl>192.168.6.113:8888</registryUrl>
                </configuration>
            </plugin>
        </plugins>
    </build>

    <distributionManagement>
        <repository>
            <id>nexus-releases</id>
            <name>Nexus Release Repository</name>
            <url>http://192.168.0.200:8081/repository/maven-releases/</url>
        </repository>
        <snapshotRepository>
            <id>nexus-snapshots</id>
            <name>Nexus Snapshot Repository</name>
            <url>http://192.168.0.200:8081/repository/maven-snapshots/</url>
        </snapshotRepository>
    </distributionManagement>
</project>
```

**说明**：

* 这里的`serverId`要与maven `setting.xml`里面的一样


* Dockerfile构建文件在`src/main/docker`中
* 如果Dockerfile文件需要maven构建参数（比如需要构建后的打包文件名等），则使用`@@`占位符（如`@project.build.finalName@`）原因是Sping Boot 的pom将resource插件的占位符由`${}`改为`@@`，非继承Spring Boot 的pom文件，则使用`${}`占位符
* 如果不需要动态生成Dockerfile文件，则可以将Dockerfile资源拷贝部分放入`docker-maven-plugin`插件的`<resources>`配置里
* `spring-boot-maven-plugin`插件一定要在其他构建插件之上，否则打包文件会有问题。

# Step4、构建

如果`<pushImage>false</pushImage>`则install阶段将不提交Docker镜像，只有maven的`deploy`阶段才提交。

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

# Step5、运行

运行程序

```
docker run --name discover-server1 -e ACTIVE=peer1 -p 5001:5001 -d --network=host [IMAGE]

docker run --name discover-server2 -e ACTIVE=peer2 -p 5002:5002 -d --network=host [IMAGE]
# 限制内存加上：-e "JAVA_OPTS=-Xmx128m"
```

这样一个简单的基于Docker的高可用Eureka就运行起来了。

# 高可用Eureka Server

**基于Compose运行高可用的Eureka**

## `application.yml`

```
spring:
  application:
    name: eureka-center-server
  cloud:
    inetutils:
      preferred-networks: ${PREFERRED_NETWORKS}
  output:
    ansi:
      enabled: always
security:
  basic:
    enabled: true     # 开启基于HTTP basic的认证
  user:
    name: ${SECURITY_NAME}
    password: ${SECURITY_PASSWORD}
---
spring:
  profiles: docker1
server:
  port: ${PORT}
eureka:
  instance:
    hostname: docker-eureka1
    prefer-ip-address: true
    ip-address: ${eureka.instance.hostname}
    instance-id: ${eureka.instance.hostname}:${spring.cloud.client.ipAddress}:${server.port}
    lease-renewal-interval-in-seconds: ${LEASE_RENEWAL_INTERVAL_INSECONDS}
  client:
    serviceUrl:
      defaultZone: ${ADDITIONAL_EUREKA_SERVER_LIST}
  server:
    enable-self-preservation: false
---
spring:
  profiles: docker2
server:
  port: ${PORT}
eureka:
  instance:
    hostname: docker-eureka2
    prefer-ip-address: true
    ip-address: ${eureka.instance.hostname}
    instance-id: ${eureka.instance.hostname}:${spring.cloud.client.ipAddress}:${server.port}
    lease-renewal-interval-in-seconds: ${LEASE_RENEWAL_INTERVAL_INSECONDS}
  client:
    serviceUrl:
      defaultZone: ${ADDITIONAL_EUREKA_SERVER_LIST}
  server:
    enable-self-preservation: false
---
spring:
  profiles: docker3
server:
  port: ${PORT}
eureka:
  instance:
    hostname: docker-eureka3
    prefer-ip-address: true
    ip-address: ${eureka.instance.hostname}
    instance-id: ${eureka.instance.hostname}:${spring.cloud.client.ipAddress}:${server.port}
    lease-renewal-interval-in-seconds: ${LEASE_RENEWAL_INTERVAL_INSECONDS}
  client:
    serviceUrl:
      defaultZone: ${ADDITIONAL_EUREKA_SERVER_LIST}
  server:
    enable-self-preservation: false
```

开启`basic`的认证需要添加依赖：

```
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

## `docker-compose.yml`

```
version: "3.4"
services:
  docker-eureka1:
    image: ${IMAGE}
    env_file:
      - .env
    environment:
      - ACTIVE=docker1
      - PORT=${EUREKA1_PORT}
      - ADDITIONAL_EUREKA_SERVER_LIST=http://${SECURITY_NAME}:${SECURITY_PASSWORD}@docker-eureka2:${EUREKA2_PORT}/eureka/,http://${SECURITY_NAME}:${SECURITY_PASSWORD}@docker-eureka3:${EUREKA3_PORT}/eureka/
    ports:
      - ${EUREKA1_PORT}:${EUREKA1_PORT}
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 3s
        max_attempts: 3
        window: 20s
      update_config:
        parallelism: 1
        delay: 20s
    networks:
      eureka-net:
        aliases:
          - eureka
    healthcheck:
      test: ["CMD", "curl", "-fs", "http://localhost:${EUREKA1_PORT}/health/"]
      interval: 1m30s
      timeout: 15s
      retries: 3

  docker-eureka2:
    image: ${IMAGE}
    env_file:
      - .env
    environment:
      - ACTIVE=docker2
      - PORT=${EUREKA2_PORT}
      - ADDITIONAL_EUREKA_SERVER_LIST=http://${SECURITY_NAME}:${SECURITY_PASSWORD}@docker-eureka1:${EUREKA1_PORT}/eureka/,http://${SECURITY_NAME}:${SECURITY_PASSWORD}@docker-eureka3:${EUREKA3_PORT}/eureka/
    ports:
      - ${EUREKA2_PORT}:${EUREKA2_PORT}
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 3s
        max_attempts: 3
        window: 20s
      update_config:
        parallelism: 1
        delay: 20s
    networks:
      eureka-net:
        aliases:
          - eureka
    healthcheck:
      test: ["CMD", "curl", "-fs", "http://localhost:${EUREKA2_PORT}/health/"]
      interval: 1m30s
      timeout: 15s
      retries: 3

  docker-eureka3:
    image: ${IMAGE}
    env_file:
      - .env
    environment:
      - ACTIVE=docker3
      - PORT=${EUREKA3_PORT}
      - ADDITIONAL_EUREKA_SERVER_LIST=http://${SECURITY_NAME}:${SECURITY_PASSWORD}@docker-eureka2:${EUREKA2_PORT}/eureka/,http://${SECURITY_NAME}:${SECURITY_PASSWORD}@docker-eureka1:${EUREKA1_PORT}/eureka/
    ports:
      - ${EUREKA3_PORT}:${EUREKA3_PORT}
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 3s
        max_attempts: 3
        window: 20s
      update_config:
        parallelism: 1
        delay: 20s
    networks:
      eureka-net:
        aliases:
          - eureka
    healthcheck:
      test: ["CMD", "curl", "-fs", "http://localhost:${EUREKA3_PORT}/health/"]
      interval: 1m30s
      timeout: 15s
      retries: 3

# docker network create --opt encrypted -d=overlay --attachable --subnet 10.10.0.0/16 name
networks:
  eureka-net:
    external:
      name: ${BACKEND_NETWORK:-backend}
```

`.env`

```
IMAGE=192.168.6.113:8888/discover-server/eureka-center-server
PREFERRED_NETWORKS=10.10
LEASE_RENEWAL_INTERVAL_INSECONDS=15
SECURITY_NAME=admin
SECURITY_PASSWORD=admin123
EUREKA1_PORT=5001
EUREKA2_PORT=5002
EUREKA3_PORT=5003
```

从部署模版中可以看出这三个Eureka实例在网络上的别名(alias)都是`eureka`，对于客户端可以在配置文件中指定这个别名即可，不必指定三个示例的名字。

`application.yml`

```
eureka.client.serviceUrl.defaultZone=http://${EUREKA_SERVER_ADDRESS}:5001/eureka/
```

Eureka Server的地址通过`${EUREKA_SERVER_ADDRESS}` 环境变量传入。

```
services:
  web:
    image: demo-web
    networks:
      - eureka-net
    environment:
      - EUREKA_SERVER_ADDRESS=eureka
```

另外要注意的是所有依赖于Eureka的应用服务都要挂到`eureka-net`网络上，否则无法和Eureka Server通信。

## 启动

启动前确保创建好了网络：

```
docker network create --opt encrypted -d=overlay --attachable --subnet 10.10.0.0/16 backend
docker-compse up -d
```

此时在`Portainer`中可以看到三个容器已经启动：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-docker-integration/portainer-eureka.png)

随意一个eureka端口都能看到另外两个服务：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-docker-integration/compose-up03.png)

如果使用swarm mode：

```
export $(cat .env) && docker stack deploy --compose-file=docker-compose.yml eureka-stack
```

**注意**：目前使用stack方式启动是无法加载`env_file`的，所以需要预先加载一下。

我们的app通过合适的`network`交互应该是这样的：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-docker-integration/cnm-demo.png)

# Eureka Edgware.RELEASE版本注册优化

在`Edgware.RELEASE`版本中相比之前的步骤，省略了在主函数上添加`@EnableDiscoveryClient`注解这一过程。Spring Cloud默认认为客户端是要完成向注册中心进行注册的。

- 添加对应的`pom`依赖.
- `properties`文件进行配置

**添加pom依赖**

```
<dependency>
   <groupId>org.springframework.cloud</groupId>
   <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

**properties文件进行配置**

```
spring.application.name=EUREKA-CLIENT
eureka.client.service-url.defaultZone=http://localhost:8761/eureka

```

启动Eureka Client客户端，访问<http://localhost:8761/eureka>
可以看到EUEREKA-CLIENT已经注册到Eureka Server服务上了。

**关闭自动注册功能**

spring cloud提供了一个参数，该参数的作用是控制是否要向Eureka Server发起注册。具体参数为：

```
//默认为true,如果控制不需要向Eureka Server发起注册将该值设置为false.
spring.cloud.service-registry.auto-registration.enabled = xxx
```

# Finally

> 参考
>
> ***[http://blueskykong.com/2017/11/02/dockermaven/](http://blueskykong.com/2017/11/02/dockermaven/)***
>
> ***[http://blog.csdn.net/timedifier2/article/details/78135970](http://blog.csdn.net/timedifier2/article/details/78135970)***
>
> 源码
>
> [***https://github.com/masteranthoneyd/spring-boot-docker-demo***](https://github.com/masteranthoneyd/spring-boot-docker-demo ) 