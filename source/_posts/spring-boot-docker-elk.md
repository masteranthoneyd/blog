---
title: Spring Boot应用集成Docker并结合Log4j2、Kafka、ELK管理Docker日志
date: 2018-04-02 13:00:19
categories: [Programming, Java, Spring Boot]
tags: [Docker, Spring Boot, Java, Spring, Elasticsearch]
---

![](https://cdn.yangbingdong.com/img/spring-cloud-docker-integration/java-docker.png)

# Preface

> 微服务架构下，微服务在带来良好的设计和架构理念的同时，也带来了运维上的额外复杂性，尤其是在服务部署和服务监控上。单体应用是集中式的，就一个单体跑在一起，部署和管理的时候非常简单，而微服务是一个网状分布的，有很多服务需要维护和管理，对它进行部署和维护的时候则比较复杂。集成Docker之后，我们可以很方便地部署以及编排服务，ELK的集中式日志管理可以让我们很方便地聚合Docker日志。

<!--more-->

# Log4j2 Related

## 使用Log4j2

下面是 Log4j2  官方性能测试结果：

![](https://cdn.yangbingdong.com/img/spring-boot-learning/log4j2-performance.png)

### Maven配置

```
<!-- Spring Boot 依赖-->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter</artifactId>
    <!-- 去除 logback 依赖 -->
    <exclusions>
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-logging</artifactId>
        </exclusion>
    </exclusions>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>

<!-- 日志 Log4j2 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-log4j2</artifactId>
</dependency>

<!-- Log4j2 异步支持 -->
<dependency>
    <groupId>com.lmax</groupId>
    <artifactId>disruptor</artifactId>
    <version>3.3.8</version>
</dependency>
```

**注意**：

* 需要单独把`spring-boot-starter`里面的`logging`去除再引入`spring-boot-starter-web`，否则后面引入的`starter`模块带有的`logging`不会自动去除
* `Disruptor`需要**3.3.8**以及以上版本

### 开启全局异步以及Disruptor参数设置

> 官方说明： ***[https://logging.apache.org/log4j/2.x/manual/async.html#AllAsync](https://logging.apache.org/log4j/2.x/manual/async.html#AllAsync)***

添加`Disruptor`依赖后只需要添加启动参数：

```
-Dlog4j2.contextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector
```

也可以在程序启动时添加系统参数。

> 若想知道Disruptor是否生效，可以在`AsyncLogger#logMessage`中断点

加大队列参数：

```
-DAsyncLogger.RingBufferSize=262144
-DAsyncLoggerConfig.RingBufferSize=262144 
```

设置队列满了时的处理策略：丢弃，否则默认blocking，异步就与同步无异了：

```
-Dlog4j2.AsyncQueueFullPolicy=Discard
```

### application.yml简单配置

```
logging:
  config: classpath:log4j2.xml # 指定log4j2配置文件的路径，默认就是这个
  pattern:
    console: "%clr{%d{yyyy-MM-dd HH:mm:ss.SSS}}{faint} | %clr{%5p} | %clr{%15.15t}{faint} | %clr{%-50.50c{1.}}{cyan} | %5L | %clr{%M}{magenta} | %msg%n%xwEx" # 控制台日志输出格式
```

### log4j2.xml完整配置

上面是简单的打印，生产环境需要采用以下xml的配置：

```
<?xml version="1.0" encoding="UTF-8"?>
<configuration status="OFF" monitorInterval="30">
    <properties>
        <Property name="UNKNOWN" value="????"/>
        <Property name="KAFKA_SERVERS" value="${spring:ybd.kafka.bootstrap}"/>
        <Property name="SERVER_NAME" value="${spring:spring.application.name}"/>
        <Property name="LOG_PATTERN" value="%d{yyyy-MM-dd HH:mm:ss.SSS} | ${SERVER_NAME} | %5p | %X{IP} | %X{UA} | %t -> %c{1}#%M:%L | %msg%n%xwEx"/>
    </properties>

    <Appenders>
        <Console name="console" target="SYSTEM_OUT">
            <ThresholdFilter level="info" onMatch="ACCEPT" onMismatch="DENY"/>
            <PatternLayout pattern="${LOG_PATTERN}" charset="UTF-8"/>
        </Console>

        <Kafka name="kafka" topic="log-collect" ignoreExceptions="false">
            <ThresholdFilter level="INFO" onMatch="ACCEPT" onMismatch="DENY"/>
            <PatternLayout pattern="${LOG_PATTERN}" charset="UTF-8"/>
            <Property name="bootstrap.servers">${KAFKA_SERVERS}</Property>
            <Property name="request.timeout.ms">5000</Property>
            <Property name="transaction.timeout.ms">5000</Property>
            <Property name="max.block.ms">3000</Property>
        </Kafka>

        <RollingFile name="failoverKafkaLog" fileName="./failoverKafka/${SERVER_NAME}.log"
                     filePattern="./failoverKafka/${SERVER_NAME}.%d{yyyy-MM-dd}.log">
            <ThresholdFilter level="INFO" onMatch="ACCEPT" onMismatch="DENY"/>
            <PatternLayout>
                <Pattern>${LOG_PATTERN}</Pattern>
            </PatternLayout>
            <Policies>
                <TimeBasedTriggeringPolicy />
            </Policies>
        </RollingFile>

        <Failover name="failover" primary="kafka" retryIntervalSeconds="300">
            <Failovers>
                <AppenderRef ref="failoverKafkaLog"/>
            </Failovers>
        </Failover>
    </Appenders>

    <Loggers>
        <Root level="INFO" includeLocation="true">
            <AppenderRef ref="failover"/>
            <AppenderRef ref="console"/>
        </Root>
    </Loggers>

</configuration>
```
- `bootstrap.servers`是kafka的地址，接入Docker network之后可以配置成`kafka:9092`
- `topic`要与Logstash中配置的一致
- 启用了全局异步需要将`includeLocation`设为`true`才能打印路径之类的信息
- Kafka地址通过`${spring:ybd.kafka.bootstrap}`读取配置文件获取，这个需要自己拓展Log4j，具体请看下面的获取Application配置
- `LOG_PATTERN`中的`%X{IP}`、`%X{UA}`，通过`MDC.put(key, value)`放进去，同时在`<Root>`中设置`includeLocation="true"`才能获取`%t`、` %c`等信息
- `KafkaAppender`结合`FailoverAppender`确保当Kafka Crash时，日志触发Failover，写到文件中，不阻塞程序，进而保证了吞吐。`retryIntervalSeconds`的默认值是1分钟，是通过异常来切换的，所以可以适量加大间隔。
- `KafkaAppender` `ignoreExceptions` 必须设置为`false`，否则无法触发Failover
- `KafkaAppender` `max.block.ms`默认是1分钟，当Kafka宕机时，尝试写Kafka需要1分钟才能返回Exception，之后才会触发Failover，当请求量大时，log4j2 队列很快就会打满，之后写日志就Blocking，严重影响到主服务响应
- 日志的格式采用`" | "`作为分割符方便后面Logstash进行切分字段

### 也可以使用log4j2.yml

需要引入依赖以识别：

```
<!-- 加上这个才能辨认到log4j2.yml文件 -->
<dependency>
    <groupId>com.fasterxml.jackson.dataformat</groupId>
    <artifactId>jackson-dataformat-yaml</artifactId>
</dependency>
```

`log4j2.yml`:

```
Configuration:
  status: "OFF"
  monitorInterval: 10

  Properties:
    Property:
      - name: log.level.console
        value: debug
      - name: PID
        value: ????
      - name: LOG_PATTERN
        value: "%clr{%d{yyyy-MM-dd HH:mm:ss.SSS}}{faint} | %clr{%5p} | %clr{${sys:PID}}{magenta} | %clr{%15.15t}{faint} | %clr{%-50.50c{1.}}{cyan} | %5L | %clr{%M}{magenta} | %msg%n%xwEx"

  Appenders:
    Console:  #输出到控制台
      name: CONSOLE
      target: SYSTEM_OUT
      ThresholdFilter:
        level: ${sys:log.level.console} # “sys:”表示：如果VM参数中没指定这个变量值，则使用本文件中定义的缺省全局变量值
        onMatch: ACCEPT
        onMismatch: DENY
      PatternLayout:
        pattern: ${LOG_PATTERN}
        charset: UTF-8
  Loggers:
    Root:
      level: info
      includeLocation: true
      AppenderRef:
        - ref: CONSOLE
    AsyncRoot:
      level: info
      includeLocation: true
      AppenderRef:
        - ref: CONSOLE
```

更多配置请参照：*[http://logging.apache.org/log4j/2.x/manual/layouts.html](http://logging.apache.org/log4j/2.x/manual/layouts.html)*

## 日志配置文件中获取Application配置

### Logback

方法1: 使用`logback-spring.xml`，因为`logback.xml`加载早于`application.properties`，所以如果你在`logback.xml`使用了变量时，而恰好这个变量是写在`application.properties`时，那么就会获取不到，只要改成`logback-spring.xml`就可以解决。

方法2: 使用`<springProperty>`标签，例如：

```
<springProperty scope="context" name="LOG_HOME" source="logback.file"/>
```

### Log4j2

只能写一个Lookup：

```
/**
 * @author ybd
 * @date 18-5-11
 * @contact yangbingdong1994@gmail.com
 */
@Plugin(name = LOOK_UP_PREFIX, category = StrLookup.CATEGORY)
public class SpringEnvironmentLookup extends AbstractLookup {
	public static final String LOOK_UP_PREFIX = "spring";
	private static LinkedHashMap profileYmlData;
	private static LinkedHashMap metaYmlData;
	private static boolean profileExist;
	private static Map<String, String> map = new HashMap<>(16);
	private static final String PROFILE_PREFIX = "application";
	private static final String PROFILE_SUFFIX = ".yml";
	private static final String META_PROFILE = PROFILE_PREFIX + PROFILE_SUFFIX;
	private static final String SPRING_PROFILES_ACTIVE = "spring.profiles.active";

	static {
		try {
			metaYmlData = new Yaml().loadAs(new ClassPathResource(META_PROFILE).getInputStream(), LinkedHashMap.class);
			Properties properties = System.getProperties();
			String active = properties.getProperty(SPRING_PROFILES_ACTIVE);
			if (isBlank(active)) {
				active = getValueFromData(SPRING_PROFILES_ACTIVE, metaYmlData);
			}
			if (isNotBlank(active)) {
				String configName = PROFILE_PREFIX + "-" + active + PROFILE_SUFFIX;
				ClassPathResource classPathResource = new ClassPathResource(configName);
				profileExist = classPathResource.exists();
				if (profileExist) {
					profileYmlData = new Yaml().loadAs(classPathResource.getInputStream(), LinkedHashMap.class);
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
			throw new RuntimeException("SpringEnvironmentLookup initialize fail");
		}
	}

	@Override
	public String lookup(LogEvent event, String key) {
		return map.computeIfAbsent(key, SpringEnvironmentLookup::resolveYmlMapByKey);
	}

	private static String resolveYmlMapByKey(String key) {
		Assert.isTrue(isNotBlank(key), "key can not be blank!");
		String[] keyChain = key.split("\\.");
		String value = null;
		if (profileExist) {
			value = getValueFromData(key, profileYmlData);
		}
		if (isBlank(value)) {
			value = getValueFromData(key, metaYmlData);
		}
		return value;
	}

	private static String getValueFromData(String key, LinkedHashMap dataMap) {
		String[] keyChain = key.split("\\.");
		int length = keyChain.length;
		if (length == 1) {
			return getFinalValue(key, dataMap);
		}
		String k;
		LinkedHashMap[] mapChain = new LinkedHashMap[length];
		mapChain[0] = dataMap;
		for (int i = 0; i < length; i++) {
			if (i == length - 1) {
				return getFinalValue(keyChain[i], mapChain[i]);
			}
			k = keyChain[i];
			Object o = mapChain[i].get(k);
			if (Objects.isNull(o)) {
				return "";
			}
			if (o instanceof LinkedHashMap) {
				mapChain[i + 1] = (LinkedHashMap) o;
			} else {
				throw new IllegalArgumentException();
			}
		}
		return "";
	}

	private static String getFinalValue(String k, LinkedHashMap ymlData) {
		return defaultIfNull((String) ymlData.get(k), "");
	}
}
```

然后在`log4j2.xml`中这样使用 `${spring:spring.application.name}`

## 自定义字段

可以利用`MDC`实现当前线程自定义字段

```
MDC.put("IP", IpUtil.getIpAddr(request));
```

`log4j2.xml`中这样获取`%X{IP}`

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

![](https://cdn.yangbingdong.com/img/spring-cloud-docker-integration/portainer.png)

![](https://cdn.yangbingdong.com/img/spring-cloud-docker-integration/harbor.png)

**此处有个疑问**，很明显看得出来这里上传了两个一样大小的包，不知道是不是同一个jar包，但id又不一样：

![](https://cdn.yangbingdong.com/img/spring-cloud-docker-integration/duplicate01.png)

![](https://cdn.yangbingdong.com/img/spring-cloud-docker-integration/duplicate02.png)

### 运行Docker

运行程序

```
docker run --name some-server -e ACTIVE=docker -p 8080:8080 -d [IMAGE]
```

### 添加运行时JVM参数

只需要在Docker启动命令中加上`-e "JAVA_OPTS=-Xmx128m"`即可

## Docker Swarm环境下获取ClientIp

在Docker Swarm环境中，服务中获取到的ClientIp永远是`10.255.0.X`这样的Ip，搜索了一大圈，最终的解决方安是通过Nginx转发中添加参数，后端再获取。

在`location`中添加

```
proxy_set_header    X-Forwarded-For  $proxy_add_x_forwarded_for;
```

后端获取第一个Ip。

## Demo地址

***[https://github.com/masteranthoneyd/spring-boot-learning/tree/master/spring-boot-docker](https://github.com/masteranthoneyd/spring-boot-learning/tree/master/spring-boot-docker)***

#  Kafka、ELK collect logs

![](https://cdn.yangbingdong.com/img/docker-logs-collect/elk-arch1.png)

传统的应用可以将日志存到日志中，但集成Docker之后，日志怎么处理？放到容器的某个目录然后挂在出来？这样也可以，但这样就相当于给容器与外界绑定了一个状态，弹性伸缩怎么办？个人还是觉得通过队列与ELK管理Docker日志比较合理，而且Log4j2**原生支持Kafka的Appender**。

## 镜像准备

Docker Hub中的ELK镜像并不是最新版本的，我们需要到官方的网站获取最新的镜像：***[https://www.docker.elastic.co](https://www.docker.elastic.co)***

```
docker pull zookeeper
docker pull wurstmeister/kafka:1.1.0
docker pull docker.elastic.co/elasticsearch/elasticsearch:6.3.0
docker pull docker.elastic.co/kibana/kibana:6.3.0
docker pull docker.elastic.co/logstash/logstash:6.3.0
```

注意ELK版本最好保持一致

## 启动Kafka与Zookeeper

这里直接使用docker-compose（需要先创建外部网络）:

```
version: '3.4'
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

## ELK配置以及启动

### X-Pack 破解

#### 复制Jar包

先启动一个Elasticsearch的容器，将Jar包copy出来：

```
export CONTAINER_NAME=elk_elk-elasticsearch_1
docker cp ${CONTAINER_NAME}:/usr/share/elasticsearch/modules/x-pack-core/x-pack-core-6.4.0.jar ./
docker cp ${CONTAINER_NAME}:/usr/share/elasticsearch/lib ./lib
```

#### 反编译并修改源码

找到下面两个类：
```
org.elasticsearch.license.LicenseVerifier.class org.elasticsearch.xpack.core.XPackBuild.class
```
使用 ***[Luyten](https://github.com/deathmarine/Luyten)*** 进行反编译

![](https://cdn.yangbingdong.com/img/docker-logs-collect/luyten.png)

将两个类复制IDEA（**需要引入上面copy出来的lib以及`x-pack-core-6.4.0.jar`本身**），修改为如下样子：

```
package org.elasticsearch.license;

public class LicenseVerifier
{
	public static boolean verifyLicense(final License license, final byte[] publicKeyData) {
		return true;
	}

	public static boolean verifyLicense(final License license) {
		return true;
	}
}

```

```
package org.elasticsearch.xpack.core;

import org.elasticsearch.common.SuppressForbidden;
import org.elasticsearch.common.io.PathUtils;

import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.Path;

public class XPackBuild
{
	public static final XPackBuild CURRENT;
	private String shortHash;
	private String date;

	@SuppressForbidden(reason = "looks up path of xpack.jar directly")
	static Path getElasticsearchCodebase() {
		final URL url = XPackBuild.class.getProtectionDomain().getCodeSource().getLocation();
		try {
			return PathUtils.get(url.toURI());
		}
		catch (URISyntaxException bogus) {
			throw new RuntimeException(bogus);
		}
	}

	XPackBuild(final String shortHash, final String date) {
		this.shortHash = shortHash;
		this.date = date;
	}

	public String shortHash() {
		return this.shortHash;
	}

	public String date() {
		return this.date;
	}

	static {
		final Path path = getElasticsearchCodebase();
		String shortHash = null;
		String date = null;
		Label_0157: {  // 将try-catch去掉
			shortHash = "Unknown";
			date = "Unknown";
		}
		CURRENT = new XPackBuild(shortHash, date);
	}
}
```

再编译放回jar包中:

![](https://cdn.yangbingdong.com/img/docker-logs-collect/jar-archive.png)

### 配置文件

#### Elasticsearch

`elasticsearch.yml`:

```
cluster.name: "docker-cluster"
network.host: 0.0.0.0
discovery.zen.minimum_master_nodes: 1
xpack.security.enabled: false # 不启用密码登陆
xpack.monitoring.collection.enabled: true
```

#### Logstash

`logstash.conf`配置文件(**注意下面的topics要与上面log4j2.xml中的一样**):

```
input {
    kafka {
        bootstrap_servers => ["kafka:9092"]
        auto_offset_reset => "latest"
        consumer_threads => 3 # 3个消费线程，默认是1个
        topics => ["log-collect"]
    }
}
filter {
  mutate{  # 切分日志信息并添加相应字段
    split => [ "message"," | " ]

    add_field => {
      "timestamp" => "%{[message][0]}"
    }

    add_field => {
      "level" => "%{[message][2]}"
    }

    add_field => {
      "server_name" => "%{[message][1]}"
    }

    add_field => {
      "ip" => "%{[message][3]}"

    }

    add_field => {
      "device" => "%{[message][4]}"
    }

    add_field => {
      "thread_class_method" => "%{[message][5]}"
    }

    add_field => {
      "content" => "%{[message][6]}"
    }

    remove_field => [ "message" ]
  }

  date {  # 将上面得到的日期信息，也就是日志打印的时间作为时间戳
    match => [ "timestamp", "yyyy-MM-dd HH:mm:ss.SSS" ]
    locale => "en"
    target => [ "@timestamp" ]
    timezone => "Asia/Shanghai" # 这里如果不设置时区，在Kibana中展示的时候会多了8个小时
  }

  geoip { # 分析ip
    source => "ip"
  }

  useragent { # 分析User-Agent
    source => "device"
    target => "userDevice"
    remove_field => [ "device" ]
  }

}
output {
    stdout{ codec => rubydebug } # 输出到控制台
    elasticsearch { # 输出到 Elasticsearch
        action => "index"
        hosts  => ["elk-elasticsearch:9200"]
        index  => "logstash-%{server_name}-%{+yyyy.MM.dd}"
        document_type => "%{server_name}"
        # user => "elastic" # 如果选择开启xpack security需要输入帐号密码
        # password => "changeme"
    }
}


```

`logstash.yml`:

```
http.host: "0.0.0.0"
xpack.monitoring.elasticsearch.url: http://elk-elasticsearch:9200 # Docker版的Logstash此配置的默认地址是http://elasticsearch:9200

# xpack.monitoring.elasticsearch.username: "elastic" # 如果选择开启xpack security需要输入帐号密码
# xpack.monitoring.elasticsearch.password: "changeme"
```

#### Kibana

`kibana.yml`:

```
server.name: kibana
server.host: "0"
elasticsearch.url: http://elk-elasticsearch:9200
xpack.monitoring.ui.container.elasticsearch.enabled: true
#elasticsearch.username: "elastic"
#elasticsearch.password: "changeme"
```

### 申请License

转到 ***[License申请地址](https://license.elastic.co/registration)*** ，下载之后然后修改license中的`type`、`max_nodes`、`expiry_date_in_millis`：

```
{
  "license": {
    "uid": "fe8c9a81-6651-4327-89a3-c9a33bfd8e3f",
    "type": "platinum",  // 这个类型是白金会员
    "issue_date_in_millis": 1536883200000,
    "expiry_date_in_millis": 2855980923000, // 过期时间
    "max_nodes": 100,  // 集群节点数量
    "issued_to": "xxxx",
    "issuer": "Web Form",
    "signature": "AAAAAwAAAA0imCa5T/HVBQyiUbSBAAABmC9ZN0hjZDBGYnVyRXpCOW5Bb3FjZDAxOWpSbTVoMVZwUzRxVk1PSmkxaktJRVl5MUYvUWh3bHZVUTllbXNPbzBUemtnbWpBbmlWRmRZb25KNFlBR2x0TXc2K2p1Y1VtMG1UQU9TRGZVSGRwaEJGUjE3bXd3LzRqZ05iLzRteWFNekdxRGpIYlFwYkJiNUs0U1hTVlJKNVlXekMrSlVUdFIvV0FNeWdOYnlESDc3MWhlY3hSQmdKSjJ2ZTcvYlBFOHhPQlV3ZHdDQ0tHcG5uOElCaDJ4K1hob29xSG85N0kvTWV3THhlQk9NL01VMFRjNDZpZEVXeUtUMXIyMlIveFpJUkk2WUdveEZaME9XWitGUi9WNTZVQW1FMG1DenhZU0ZmeXlZakVEMjZFT2NvOWxpZGlqVmlHNC8rWVVUYzMwRGVySHpIdURzKzFiRDl4TmM1TUp2VTBOUlJZUlAyV0ZVL2kvVk10L0NsbXNFYVZwT3NSU082dFNNa2prQ0ZsclZ4NTltbU1CVE5lR09Bck93V2J1Y3c9PQAAAQAWq5AoReLA+uTiRhQ8M0qYERXNidAAsVw0LeN5H7qRXFBAvB+rId4vZNj2DN5W5GuaxuiUhiytvV6maf4ArTsROCMUKGyO9RH24bYgnRbbf6MwB8EBHjSZ6+D8ysCVgfyqAAEKURGSMWszi2mR9R+DINtaeFJnb4B1GeAppbwl7qGGetAQm0vbF7ncyojIfjFthmMUomwo3vs0his5e3UPumItGc57LEk2s5gx95NNP8aFsJXSSFHgWDWwJs18XSl3NZItnEWNfy9lEJeAkR+LWISfizZIfViOTlcDBVGKR7w8u8D5QXFUVdsTi2XU5qfIWFb78BOtpCHIlU+AjB6m",
    "start_date_in_millis": 1536883200000
  }
}
```

### 启动ELK

`docker-compose.yml`:

```
version: '3'
services:
  elk-elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:6.4.0
#    ports:
#      - "9200:9200"
    restart: always
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    volumes:
    - ./crack/x-pack-core-6.4.0.jar:/usr/share/elasticsearch/modules/x-pack-core/x-pack-core-6.4.0.jar
    - ./config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
    - ./config/license.json:/usr/share/elasticsearch/license.json
    deploy:
      placement:
        constraints:
        - node.role == manager
    networks:
      backend:
        aliases:
          - elk-elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:6.4.0
    ports:
      - "5601:5601"
    restart: always
    deploy:
      placement:
        constraints:
        - node.role == manager
    networks:
      backend:
        aliases:
          - kibana
    volumes:
    - ./config/kibana.yml:/usr/share/kibana/config/kibana.yml
    depends_on:
      - elk-elasticsearch

  logstash:
    image: docker.elastic.co/logstash/logstash:6.4.0
#    ports:
#      - "4560:4560"
    restart: always
    environment:
      - LS_JAVA_OPTS=-Xmx512m -Xms512m
    volumes:
      - ./config/logstash.conf:/etc/logstash.conf
      - ./config/logstash.yml:/usr/share/logstash/config/logstash.yml
    deploy:
      placement:
        constraints:
        - node.role == manager
    networks:
      backend:
        aliases:
          - logstash
    depends_on:
      - elk-elasticsearch
    entrypoint:
      - logstash
      - -f
      - /etc/logstash.conf

# docker network create -d=overlay --attachable backend
# docker network create --opt encrypted -d=overlay --attachable --subnet 10.10.0.0/16 backend
networks:
  backend:
    external:
      name: backend

```

启动后需要手动请求更新License：

```
docker-compose up -d
docker exec ${CONTAINER_NAME} curl -XPUT 'http://0.0.0.0:9200/_xpack/license' -H "Content-Type: application/json" -d @license.json
```

大概是下面这个样子：

```
# ybd @ ybd-PC in ~/data/git-repo/bitbucket/ms-base/docker-compose/elk on git:master x [20:52:51] 
$ docker-compose up -d                                                   

Creating elk_elk-elasticsearch_1 ... done

Creating elk_elk-elasticsearch_1 ... 
Creating elk_logstash_1          ... done
Creating elk_kibana_1            ... done

# ybd @ ybd-PC in ~/data/git-repo/bitbucket/ms-base/docker-compose/elk on git:master x [20:53:58] 
$ docker exec elk_elk-elasticsearch_1 curl -XPUT 'http://0.0.0.0:9200/_xpack/license' -H "Content-Type: application/json" -d @license.json
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1278  100    46  100  1232    328   8786 --:--:-- --:--:-- --:--:--  8800
{"acknowledged":true,"license_status":"valid"}
```


![](https://cdn.yangbingdong.com/kibana-license.png)

![](https://cdn.yangbingdong.com/img/docker-logs-collect/kibana02.png)

## Kibana相关设置

### 显示所有插件

在Kibana首页最下面找到：

![](https://cdn.yangbingdong.com/img/docker-logs-collect/kibana-full-plugin-button.png)

### Discover每页显示行数

找到Advanced Setting![](https://cdn.yangbingdong.com/img/docker-logs-collect/kibana-admin-setting.png)

点进去找到 `discover:sampleSize`再点击Edit修改:

![](https://cdn.yangbingdong.com/img/docker-logs-collect/kibana-page-size.png)

### 时区

Kibana默认读取浏览器时区，可通过`dateFormat:tz`进行修改：

![](https://cdn.yangbingdong.com/img/docker-logs-collect/kibana-timezone.png)

## ElasticSearch UI

* ***[ElasticHD](https://github.com/360EntSecGroup-Skylar/ElasticHD)***
* ***[Dejavu](https://github.com/appbaseio/dejavu/)***

# Spring Boot 集成 Elastic APM

## 运行APM Server

`docker-compose`:

```
version: '3'
services:
  apm-server:
    image: docker.elastic.co/apm/apm-server:6.4.0
    ports:
      - "8200:8200"
    volumes:
    - ./config/apm-server.yml:/usr/share/apm-server/apm-server.yml
    deploy:
      placement:
        constraints:
        - node.role == manager
    networks:
      backend-swarm:
        aliases:
          - apm-server

# docker network create -d=overlay --attachable backend-swarm
# docker network create --opt encrypted -d=overlay --attachable --subnet 10.10.0.0/16 backend-swarm
networks:
  backend-swarm:
    external:
      name: backend-swarm
```

`apm-server.yml`:

```
apm-server:
  host: "0.0.0.0:8200"

setup.template.settings:

  index:
    number_of_shards: 1
    codec: best_compression
    
output.elasticsearch:
  hosts: ["elk-elasticsearch:9200"]

  indices:
  - index: "apm-%{[beat.version]}-sourcemap"
    when.contains:
      processor.event: "sourcemap"

  - index: "apm-%{[beat.version]}-error-%{+yyyy.MM.dd}"
    when.contains:
      processor.event: "error"

  - index: "apm-%{[beat.version]}-transaction-%{+yyyy.MM.dd}"
    when.contains:
      processor.event: "transaction"

  - index: "apm-%{[beat.version]}-span-%{+yyyy.MM.dd}"
    when.contains:
      processor.event: "span"

  - index: "apm-%{[beat.version]}-metric-%{+yyyy.MM.dd}"
    when.contains:
      processor.event: "metric"

  - index: "apm-%{[beat.version]}-onboarding-%{+yyyy.MM.dd}"
    when.contains:
      processor.event: "onboarding"

logging.level: warning

logging.metrics.enabled: false
```

这个配置文件从容器中`/usr/share/apm-server/apm-server.yml`复制出来稍微改了一下Elasticsearch的Url。

若开启了X-Pack，则需要在yml中配置帐号密码：

```
output.elasticsearch:
    hosts: ["<es_url>"]
    username: <username>
    password: <password>
```

## 集成到Spring Boot

下载 ***[APM代理依赖](http://search.maven.org/#search%7Cga%7C1%7Ca%3Aelastic-apm-agent)***

在启动参数中添加:

```
java -javaagent:/path/to/elastic-apm-agent-<version>.jar \
     -Delastic.apm.service_name=my-application \
     -Delastic.apm.server_url=http://localhost:8200 \ 
     -Delastic.apm.application_packages=org.example \ 
     -jar my-application.jar
```

启动后在Kibana的APM模块中更新一下索引，效果图大概是这样的：

![](https://cdn.yangbingdong.com/img/docker-logs-collect/apm.png)

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

# Finally

> 参考:
>
> ***[https://www.yinchengli.com/2016/09/16/logstash/](https://www.yinchengli.com/2016/09/16/logstash/)***
>
> ***[https://www.jianshu.com/p/ba1aa0c52942](https://www.jianshu.com/p/ba1aa0c52942)***
>
> ***[https://www.jianshu.com/p/eb10c414a93f](https://www.jianshu.com/p/eb10c414a93f)***
>
> ***[https://my.oschina.net/kkrgwbj/blog/734530](https://my.oschina.net/kkrgwbj/blog/734530)***