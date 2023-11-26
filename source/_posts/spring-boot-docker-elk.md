---
title: Spring Boot应用集成Docker并结合Log4j2、Kafka、ELK管理Docker日志
date: 2018-04-02 13:00:19
categories: [Programming, Java, Spring Boot]
tags: [Docker, Spring Boot, Java, Spring, Elasticsearch]
---

![](https://oldcdn.yangbingdong.com/img/spring-cloud-docker-integration/java-docker.png)

# Preface

> 微服务架构下, 微服务在带来良好的设计和架构理念的同时, 也带来了运维上的额外复杂性, 尤其是在服务部署和服务监控上. 单体应用是集中式的, 就一个单体跑在一起, 部署和管理的时候非常简单, 而微服务是一个网状分布的, 有很多服务需要维护和管理, 对它进行部署和维护的时候则比较复杂. 集成Docker之后, 我们可以很方便地部署以及编排服务, ELK的集中式日志管理可以让我们很方便地聚合Docker日志. 

<!--more-->

# Log4j2 Related

## 使用Log4j2

下面是 Log4j2  官方性能测试结果: 

![](https://oldcdn.yangbingdong.com/img/spring-boot-learning/log4j2-performance.png)

### Maven配置

```xml
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

**注意**: 

* 需要单独把`spring-boot-starter`里面的`logging`去除再引入`spring-boot-starter-web`, 否则后面引入的`starter`模块带有的`logging`不会自动去除
* `Disruptor`需要**3.3.8**以及以上版本

### 开启全局异步以及Disruptor参数设置

> 官方说明: ***[https://logging.apache.org/log4j/2.x/manual/async.html#AllAsync](https://logging.apache.org/log4j/2.x/manual/async.html#AllAsync)***

添加`Disruptor`依赖后只需要添加启动参数: 

```
-Dlog4j2.contextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector
```

也可以在程序启动时添加系统参数. 

> 若想知道Disruptor是否生效, 可以在`AsyncLogger#logMessage`中断点

加大队列参数: 

```
-DAsyncLogger.RingBufferSize=262144
-DAsyncLoggerConfig.RingBufferSize=262144 
```

设置队列满了时的处理策略: 丢弃, 否则默认blocking, 异步就与同步无异了: 

```
-Dlog4j2.AsyncQueueFullPolicy=Discard
```

### 系统时钟参数

通过 `log4j2.clock` 指定, 默认使用 `SystemClock`, 我们可以使用 `org.apache.logging.log4j.core.util.CachedClock`. 其他选项看接口实现类, 也可以自己实现 `Clock` 接口.

### Log4j 环境变量配置文件

上面的全局异步以及系统始终参数配置都是通过系统环境变量来设置的, 下面方式可以通过配置文件的方式来设置.

在 `resource` 下定义 `log4j2.component.properties`  配置文件:

```properties
Log4jContextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector
log4j2.clock=com.xxx.CustomLog4jClock
```

### application.yml简单配置

```
logging:
  config: classpath:log4j2.xml # 指定log4j2配置文件的路径, 默认就是这个
  pattern:
    console: "%clr{%d{yyyy-MM-dd HH:mm:ss.SSS}}{faint} | %clr{%5p} | %clr{%15.15t}{faint} | %clr{%-50.50c{1.}}{cyan} | %5L | %clr{%M}{magenta} | %msg%n%xwEx" # 控制台日志输出格式
```

### log4j2.xml 详细配置

先来看一下常用的输出格式:

* `%d{yyyy-MM-dd HH:mm:ss.SSS}`: 输出时间，精确度为毫秒.
* `%-5level` | `%-5p`: 输出日志级别, -5表示左对齐并且固定占5个字符宽度, 如果不足用空格补齐.
* `%t` | `%thread`: 线程名称
* `%c{precision}` | `logger{precision}`: 输出的Logger名字, `{precision}` 表示保留的名字长度, 比如 `%c{1}` 是这样的 `Foo`, `%c{3}` 是这样的 `apache.commons.Foo`
* `%C{precision}` | `%class{precision}`: 实际上输出log的类名, 如果一个类有子类(`Son extend Father`), 在 `Father` 中调用 `log.info`, 那么`%C{1}` 输出的是 `Father`. 
* `M` | `method`: 输出log所在的方法名.
* `L` | `line`: 输出log所在的行数.
* `%msg{nolookups}`: 输出的log日志, `{nolookups}` 表示忽略掉一些内置函数比如 `logger.info("Try ${date:YYYY-MM-dd}")`, 如果不加 `{nolookups}` 那么输出的日志会是这样的 `Try 2019-05-28`.
* `%n`: 换行, 一般跟在 `%msg` 后面.
* `%xEx` | `%xwEx`: 输出异常, 后者会在异常信息的开始与结束append空的一行, 与 `%ex` 的区别在于在每一行异常信息后面会追加jar包的信息.
* `%clr`: 配置颜色, 比如 `%clr{字段}{颜色}`
  * `blue`: 蓝色
  * `cyan`: 青色
  * `faint`: 不知道什么颜色, 输出来是黑色
  * `green`: 绿色
  * `magenta`: 粉色
  * `red`: 红色
  * `yellow`: 黄色

所以我们的pattern是这样的: `%d{yyyy-MM-dd HH:mm:ss.SSS}  | %-5level | ${server_name} | %X{IP} | %logger{1} | %thread -> %class{1}#%method:%line | %msg{nolookups}%n%xwEx`.

使用 ` | ` 作为分隔符是因为后面输出到Logstash时用于字段分割.

#### 输出到 Kafka

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration status="OFF" monitorInterval="30">
    <properties>
        <Property name="UNKNOWN" value="????"/>
        <Property name="KAFKA_SERVERS" value="${spring:ybd.kafka.bootstrap}"/>
        <Property name="server_name" value="${spring:spring.application.name}"/>
        <Property name="LOG_PATTERN" value="%d{yyyy-MM-dd HH:mm:ss.SSS} | %-5level | ${server_name} | %X{IP} | %logger{1} | %thread -> %class{1}#%method:%line | %msg{nolookups}%n%xwEx"/>
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
- `bootstrap.servers`是kafka的地址, 接入Docker network之后可以配置成`kafka:9092`
- `topic`要与Logstash中配置的一致
- 启用了全局异步需要将`includeLocation`设为`true`才能打印路径之类的信息
- Kafka地址通过`${spring:ybd.kafka.bootstrap}`读取配置文件获取, 这个需要自己拓展Log4j, 具体请看下面的获取Application配置
- `LOG_PATTERN`中的`%X{IP}`、`%X{UA}`, 通过`MDC.put(key, value)`放进去, 同时在`<Root>`中设置`includeLocation="true"`才能获取`%t`、` %c`等信息
- `KafkaAppender`结合`FailoverAppender`确保当Kafka Crash时, 日志触发Failover, 写到文件中, 不阻塞程序, 进而保证了吞吐. `retryIntervalSeconds`的默认值是1分钟, 是通过异常来切换的, 所以可以适量加大间隔. 
- `KafkaAppender` `ignoreExceptions` 必须设置为`false`, 否则无法触发Failover
- `KafkaAppender` `max.block.ms`默认是1分钟, 当Kafka宕机时, 尝试写Kafka需要1分钟才能返回Exception, 之后才会触发Failover, 当请求量大时, log4j2 队列很快就会打满, 之后写日志就Blocking, 严重影响到主服务响应
- 日志的格式采用`" | "`作为分割符方便后面Logstash进行切分字段

#### 输出到文件

> 这种方式可以用于存档, 同是使用 Filebeat 抓取文件日志输出到 Logstash.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!--日志级别以及优先级排序: OFF > FATAL > ERROR > WARN > INFO > DEBUG > TRACE > ALL -->
<!--Configuration后面的status,这个用于设置log4j2自身内部的信息输出,可以不设置,当设置成trace时,你会看到log4j2内部各种详细输出 -->
<!--monitorInterval：Log4j能够自动检测修改配置 文件和重新配置本身,设置间隔秒数 -->
<configuration status="WARN" monitorInterval="1800">
    <properties>
        <property name="UNKNOWN" value="????"/>
        
        <!-- 应用的名字, 需要自己写spring的拓展 -->
        <property name="server_name" value="${spring:spring.application.name}"/>
        
        <!-- 控制台输出的格式 -->
        <property name="log_pattern" value="%d{yyyy-MM-dd HH:mm:ss.SSS} | %-5level | ${server_name} | %X{IP} | %logger{1} | %thread -> %class{1}#%method:%line | %msg{nolookups}%n%xwEx"/>
		
        <!-- 日志默认存放的位置,这里设置为项目根路径下,也可指定绝对路径 -->
        <property name="basePath">./log4j2Logs/${server_name}</property>
        <!-- 日志默认切割的最小单位 -->
        <property name="every_file_size">20MB</property>
        <!-- 日志默认输出级别 -->
        <property name="output_log_level">INFO</property>

        <!-- 日志默认存放路径(所有级别日志) -->
        <property name="rolling_fileName">${basePath}/all.log</property>
        <!-- 日志默认压缩路径,将超过指定文件大小的日志,自动存入按"年月"建立的文件夹下面并进行压缩,作为存档 -->
        <property name="rolling_filePattern">${basePath}/%d{yyyy-MM}/all-%d{yyyy-MM-dd}-%i.log.gz</property>
        <!-- 日志默认同类型日志,同一文件夹下可以存放的数量,不设置此属性则默认为7个 -->
        <property name="rolling_max">20</property>

        <property name="info_fileName">${basePath}/info.log</property>
        <property name="info_filePattern">${basePath}/%d{yyyy-MM}/info-%d{yyyy-MM-dd}-%i.log.gz</property>
        <property name="info_max">10</property>

        <property name="warn_fileName">${basePath}/warn.log</property>
        <property name="warn_filePattern">${basePath}/%d{yyyy-MM}/warn-%d{yyyy-MM-dd}-%i.log.gz</property>
        <property name="warn_max">10</property>

        <property name="error_fileName">${basePath}/error.log</property>
        <property name="error_filePattern">${basePath}/%d{yyyy-MM}/error-%d{yyyy-MM-dd}-%i.log.gz</property>
        <property name="error_max">10</property>

        <!-- 控制台显示的日志最低级别 -->
        <property name="console_print_level">INFO</property>
    </properties>

    <!--定义appender -->
    <Appenders>
        <!-- 用来定义输出到控制台的配置 -->
        <Console name="Console" target="SYSTEM_OUT">
            <!-- 设置控制台只输出level及以上级别的信息(onMatch),其他的直接拒绝(onMismatch) -->
            <ThresholdFilter level="${console_print_level}" onMatch="ACCEPT" onMismatch="DENY"/>
            <PatternLayout pattern="${log_pattern}" charset="UTF-8"/>
        </Console>

        <!-- 打印root中指定的level级别以上的日志到文件 -->
        <RollingFile name="RollingFile" fileName="${rolling_fileName}" filePattern="${rolling_filePattern}">
            <PatternLayout pattern="${log_pattern}" charset="UTF-8"/>
            <!-- 设置同类型日志,同一文件夹下可以存放的数量,如果不设置此属性则默认存放7个文件 -->
            <SizeBasedTriggeringPolicy size="${every_file_size}"/>
            <DefaultRolloverStrategy max="${rolling_max}" />
            <!-- 匹配INFO以及以上级别 -->
            <Filters>
                <ThresholdFilter level="INFO" onMatch="ACCEPT" onMismatch="DENY"/>
            </Filters>
        </RollingFile>

        <RollingFile name="InfoFile" fileName="${info_fileName}" filePattern="${info_filePattern}">
            <PatternLayout pattern="${log_pattern}" charset="UTF-8"/>
            <SizeBasedTriggeringPolicy size="${every_file_size}" />
            <DefaultRolloverStrategy max="${info_max}" />
            <Filters>
                <ThresholdFilter level="WARN" onMatch="DENY" onMismatch="NEUTRAL"/>
                <ThresholdFilter level="INFO" onMatch="ACCEPT" onMismatch="DENY"/>
            </Filters>
        </RollingFile>

        <RollingFile name="WarnFile" fileName="${warn_fileName}" filePattern="${warn_filePattern}">
            <PatternLayout pattern="${log_pattern}" charset="UTF-8"/>
            <SizeBasedTriggeringPolicy size="${every_file_size}" />
            <DefaultRolloverStrategy max="${warn_max}" />
            <Filters>
                <ThresholdFilter level="ERROR" onMatch="DENY" onMismatch="NEUTRAL"/>
                <ThresholdFilter level="WARN" onMatch="ACCEPT" onMismatch="DENY"/>
            </Filters>
        </RollingFile>

        <RollingFile name="ErrorFile" fileName="${error_fileName}" filePattern="${error_filePattern}">
            <PatternLayout pattern="${log_pattern}" charset="UTF-8"/>
            <SizeBasedTriggeringPolicy size="${every_file_size}" />
            <DefaultRolloverStrategy max="${error_max}" />
            <Filters>
                <ThresholdFilter level="FATAL" onMatch="DENY" onMismatch="NEUTRAL"/>
                <ThresholdFilter level="ERROR" onMatch="ACCEPT" onMismatch="DENY"/>
            </Filters>
        </RollingFile>
    </Appenders>

    <!--然后定义logger,只有定义了logger并引入的appender,appender才会生效 -->
    <Loggers>
        <!--建立一个默认的root的logger -->
        <Root level="{output_log_level}" includeLocation="true">
            <AppenderRef ref="Console"/>
            <AppenderRef ref="RollingFile"/>
            <AppenderRef ref="InfoFile"/>
            <AppenderRef ref="WarnFile"/>
            <AppenderRef ref="ErrorFile"/>
        </Root>
    </Loggers>
</configuration>
```

### 也可以使用log4j2.yml

需要引入依赖以识别: 

```xml
<!-- 加上这个才能辨认到log4j2.yml文件 -->
<dependency>
    <groupId>com.fasterxml.jackson.dataformat</groupId>
    <artifactId>jackson-dataformat-yaml</artifactId>
</dependency>
```

`log4j2.yml`:

```yaml
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
        level: ${sys:log.level.console} # “sys:”表示: 如果VM参数中没指定这个变量值, 则使用本文件中定义的缺省全局变量值
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

更多配置请参照: *[http://logging.apache.org/log4j/2.x/manual/layouts.html](http://logging.apache.org/log4j/2.x/manual/layouts.html)*

## 日志配置文件中获取Application配置

### Logback

方法1: 使用`logback-spring.xml`, 因为`logback.xml`加载早于`application.properties`, 所以如果你在`logback.xml`使用了变量时, 而恰好这个变量是写在`application.properties`时, 那么就会获取不到, 只要改成`logback-spring.xml`就可以解决. 

方法2: 使用`<springProperty>`标签, 例如: 

```
<springProperty scope="context" name="LOG_HOME" source="logback.file"/>
```

### Log4j2

只能写一个Lookup: 

```java
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
- Docker私有仓库, 可以使用Harbor(***[Ubuntu中安装Harbor](/2018/docker-visual-management-and-orchestrate-tools/#Harbor)***)

集成Docker需要的插件`docker-maven-plugin`: *[https://github.com/spotify/docker-maven-plugin](https://github.com/spotify/docker-maven-plugin)*

## 安全认证配置

> 当我们 push 镜像到 Docker 仓库中时, 不管是共有还是私有, 经常会需要安全认证, 登录完成之后才可以进行操作. 当然, 我们可以通过命令行 `docker login -u user_name -p password docker_registry_host` 登录, 但是对于自动化流程来说, 就不是很方便了. 使用 docker-maven-plugin 插件我们可以很容易实现安全认证. 

### 普通配置

`settings.xml`: 

```xml
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

`settings.xml`配置私有库的访问: 

首先使用你的私有仓库访问密码生成主密码: 

```
mvn --encrypt-master-password <password>
```

其次在`settings.xml`文件的同级目录创建`settings-security.xml`文件, 将主密码写入: 

```
<?xml version="1.0" encoding="UTF-8"?>
<settingsSecurity>
  <master>{Ns0JM49fW9gHMTZ44n*****************=}</master>
</settingsSecurity>

```

最后使用你的私有仓库访问密码生成服务密码, 将生成的密码写入到`settings.xml`的`<services>`中（可能会提示目录不存在, 解决方法是创建一个`.m2`目录并把`settings-security.xml`复制进去）

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

Dockerfile: 

```dockerfile
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

构建: 

```
docker build --build-arg HTTP_PROXY=192.168.6.113:8118 -t yangbingdong/docker-oraclejdk8 .
```

其中`HTTP_PROXY`是http代理, 通过`--build-arg`参数传入, 注意**不能**是`127.0.0.1`或`localhost`. 

## 开始集成

### 编写Dockerfile

在`src/main`下面新建`docker`文件夹, 并创建`Dockerfile`: 

```
FROM yangbingdong/docker-oraclejdk8:latest
MAINTAINER yangbingdong <yangbingdong1994@gmail.com>
ENV PROJECT_NAME="@project.build.finalName@.@project.packaging@" JAVA_OPTS=""
ADD $PROJECT_NAME /app.jar
ENTRYPOINT exec java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -DLog4jContextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector -Dspring.profiles.active=${ACTIVE:-docker} -jar /app.jar
```

* 通过`@@`动态获取打包后的项目名（需要插件, 下面会介绍）
* `Dspring.profiles.active=${ACTIVE:-docker}`可以通过docker启动命令`-e ACTIVE=docker`参数修改配置

#### 注意PID

如果需要Java程序监听到`sigterm`信号, 那么Java程序的`PID`必须是1, 可以使用`ENTRYPOINT exec java -jar ...`这种方式实现. 

### pom文件添加构建Docker镜像的相关插件

> 继承`spring-boot-starter-parent`, 除了`docker-maven-plugin`, 下面的3个插件都不用填写版本号, 因为parent中已经定义版本号

#### spring-boot-maven-plugin

这个不用多介绍了, 打包Spring Boot Jar包的

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

resources插件, 使用`@变量@`形式获取Maven变量到Dockerfile中（同时拷贝构建的Jar包到Dockerfile同一目录中, 这种方式是方便手动构建镜像）

```xml
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
            <!-- 将Jar复制到target的docker目录中, 因为真正的Dockerfile也是在里面, 方便使用docker build命令构建Docker镜像 -->
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

这个是为了给镜像添加基于时间戳的版本号, maven也有自带的获取时间戳的变量`maven.build.timestamp.format` + `maven.build.timestamp`:

```
<maven.build.timestamp.format>yyyy-MM-dd_HH-mm-ss<maven.build.timestamp.format>

# 获取时间戳
${maven.build.timestamp}
```

但是这个时区是`UTC`, 接近于格林尼治标准时间, 所以出来的时间会比但前的时间慢8个小时. 

如果要使用`GMT+8`, 就需要`build-helper-maven-plugin`插件, 当然也有其他的实现方式, 这里不做展开. 

```xml
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

然后可以在pom中使用`${timestamp}`获取时间戳. 

当然, 也可以使用**另外一种方式实现**, 打包前`export`一个格式化日期的环境变量, `pom.xml`中获取这个变量: 

* `export DOCKER_IMAGE_TAGE_DATE=yyyy-MM-dd_HH-mm`
* `mvn help:system`可查看所有环境变量
* 所有的环境变量都可以用以`env.`开头的Maven属性引用: `${env.DOCKER_IMAGE_TAGE_DATE}`

#### docker-maven-plugin

这也是集成并构建Docker镜像的关键

```xml
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
            <!-- 配置镜像名称, 遵循Docker的命名规范: springio/image --><imageName>${docker.registry.url}/${docker.registry.name}/${project.artifactId}</imageName>
            <!-- Dockerfile位置, 由于配置了编译时动态获取Maven变量, 真正的Dockerfile位于位于编译后位置 -->
            <dockerDirectory>${dockerfile.compiled.position}</dockerDirectory>
            <resources>
                <resource>
                    <targetPath>/</targetPath>
                    <directory>${project.build.directory}</directory>
                    <include>${project.build.finalName}.jar</include>
                </resource>
            </resources>
            <!-- 被推送服务器的配置ID, 与setting中的一直 -->
            <serverId>docker-registry</serverId>
            <!--<registryUrl>${docker.registry.url}</registryUrl>-->
        </configuration>
    </plugin>
```

主要`properties`:

```xml
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

**说明**: 

* 这里的`serverId`要与maven `setting.xml`里面的一样


* Dockerfile构建文件在`src/main/docker`中
* 如果Dockerfile文件需要maven构建参数（比如需要构建后的打包文件名等）, 则使用`@@`占位符（如`@project.build.finalName@`）原因是Sping Boot 的pom将resource插件的占位符由`${}`改为`@@`, 非继承Spring Boot 的pom文件, 则使用`${}`占位符
* 如果不需要动态生成Dockerfile文件, 则可以将Dockerfile资源拷贝部分放入`docker-maven-plugin`插件的`<resources>`配置里
* **`spring-boot-maven-plugin`插件一定要在其他构建插件之上, 否则打包文件会有问题. **



`docker-maven-plugin` 插件还提供了很多很实用的配置, 稍微列举几个参数吧. 

| 参数                                      | 说明                                                         | 默认值 |
| ----------------------------------------- | ------------------------------------------------------------ | ------ |
| `<forceTags>true</forceTags>`             | build 时强制覆盖 tag, 配合 imageTags 使用                    | false  |
| `<noCache>true</noCache>`                 | build 时, 指定 –no-cache 不使用缓存                          | false  |
| `<pullOnBuild>true</pullOnBuild>`         | build 时, 指定 –pull=true 每次都重新拉取基础镜像             | false  |
| `<pushImage>true</pushImage>`             | build 完成后 push 镜像                                       | false  |
| `<pushImageTag>true</pushImageTag>`       | build 完成后, push 指定 tag 的镜像, 配合 imageTags 使用      | false  |
| `<retryPushCount>5</retryPushCount>`      | push 镜像失败, 重试次数                                      | 5      |
| `<retryPushTimeout>10</retryPushTimeout>` | push 镜像失败, 重试时间                                      | 10s    |
| `<rm>true</rm>`                           | build 时, 指定 –rm=true 即 build 完成后删除中间容器          | false  |
| `<useGitCommitId>true</useGitCommitId>`   | build 时, 使用最近的 git commit id 前7位作为tag, 例如: image:b50b604, 前提是不配置 newName | false  |

更多参数可查看插件中的定义. 

### 命令构建

如果`<skipDockerPush>false</skipDockerPush>`则install阶段将不提交Docker镜像, 只有maven的`deploy`阶段才提交. 

```
mvn clean install

# 如果由外部传入 TAG, pom.xml 中通过 ${env.DOCKER_TAG_DATE} 获取
export DOCKER_TAG_DATE=`date '+%Y-%m-%d_%H-%M'` && mvn clean install
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

可以看到本地以及私有仓库都多了一个镜像: 

![](https://oldcdn.yangbingdong.com/img/spring-cloud-docker-integration/portainer.png)

![](https://oldcdn.yangbingdong.com/img/spring-cloud-docker-integration/harbor.png)

**此处有个疑问**, 很明显看得出来这里上传了两个一样大小的包, 不知道是不是同一个jar包, 但id又不一样: 

![](https://oldcdn.yangbingdong.com/img/spring-cloud-docker-integration/duplicate01.png)

![](https://oldcdn.yangbingdong.com/img/spring-cloud-docker-integration/duplicate02.png)

### 运行Docker

#### 普通运行

运行程序

```
docker run --name some-server -e ACTIVE=docker -p 8080:8080 -d [IMAGE]
```

#### Docker Swarm 运行

`docker-compose.yml` 中的 `image` 通过 `.env` 配置, 但 通过 `docker stack` 启动并不会读取到 `.env` 的镜像变量, 但可以通过以下命令解决:

```
export $(cat .env) && docker stack deploy -c docker-compose.yml demo-stack
```

### 添加运行时JVM参数

只需要在Docker启动命令中加上`-e "JAVA_OPTS=-Xmx128m"`即可

### 其他的Docker构建工具

#### Jib

> Jib 是 Google 开源的另外一款Docker打包工具.
>
> jib-maven-plugin: ***[https://github.com/GoogleContainerTools/jib/tree/master/jib-maven-plugin](https://github.com/GoogleContainerTools/jib/tree/master/jib-maven-plugin)***

pom配置:

```xml
<plugin>
    <groupId>com.google.cloud.tools</groupId>
    <artifactId>jib-maven-plugin</artifactId>
    <version>1.6.1</version>
    <configuration>
        <!--from节点用来设置镜像的基础镜像，相当于Docerkfile中的FROM关键字-->
        <from>
            <!--使用openjdk官方镜像，tag是8-jdk-stretch，表示镜像的操作系统是debian9,装好了jdk8-->
            <!--<image>gcr.io/distroless/java:8</image>-->
            <image>yangbingdong/docker-oraclejdk8:latest</image>
        </from>
        <to>
            <!--镜像名称和tag，使用了mvn内置变量${project.version}，表示当前工程的version-->
            <!--suppress MavenModelInspection, MybatisMapperXmlInspection -->
            <image>${docker.registry.url}/${docker.registry.name}/${project.artifactId}:${env.DOCKER_TAG_DATE}</image>
            <auth>
                <username>admin</username>
                <password>Harbor12345</password>
            </auth>
        </to>
        <!--容器相关的属性-->
        <container>
            <!--jvm内存参数-->
            <jvmFlags>
                <jvmFlag>-Xmx1g</jvmFlag>
                <!--suppress MavenModelInspection, MybatisMapperXmlInspection -->
                <jvmFlag>-Dspring.profiles.active=${ACTIVE:-docker}</jvmFlag>
            </jvmFlags>
            <!--要暴露的端口-->
            <ports>
                <port>8080</port>
            </ports>
            <creationTime>USE_CURRENT_TIMESTAMP</creationTime>
            <format>OCI</format>
        </container>
        <allowInsecureRegistries>true</allowInsecureRegistries>
    </configuration>
    <executions>
        <execution>
            <phase>compile</phase>
            <goals>
                <!--suppress MybatisMapperXmlInspection -->
                <goal>dockerBuild</goal>
                <!--<goal>build</goal>-->
            </goals>
        </execution>
    </executions>
</plugin>
```

更多配置请看官方文档.

#### Dockerfile Maven

这是 spotify 在 开源 `docker-maven-plugin` 之后的又一款插件, 用法大概如下:

```xml
<plugin>
    <groupId>com.spotify</groupId>
    <artifactId>dockerfile-maven-plugin</artifactId>
    <version>1.4.12</version>
    <executions>
        <execution>
            <id>default</id>
            <phase>package</phase>
            <goals>
                <goal>build</goal>
            </goals>
        </execution>
    </executions>
    <configuration>
        <repository>${docker.registry.url}/${docker.registry.name}</repository>
        <!--suppress MavenModelInspection -->
        <tag>${env.DOCKER_TAG_DATE}</tag>
        <contextDirectory>${dockerfile.compiled.position}</contextDirectory>
        <dockerfile>${dockerfile.compiled.position}/Dockerfile</dockerfile>
    </configuration>
</plugin>
```

感觉灵活性没有 `docker-maven-plugin` 好.

## Docker Swarm环境下获取ClientIp

在Docker Swarm环境中, 服务中获取到的ClientIp永远是`10.255.0.X`这样的Ip, 搜索了一大圈, 最终的解决方安是通过Nginx转发中添加参数, 后端再获取. 

在`location`中添加

```
proxy_set_header    X-Forwarded-For  $proxy_add_x_forwarded_for;
```

后端获取第一个Ip. 

## 服务注册IP问题

一般安装了 Docker 会出现多网卡的情况, 在服务注册的时候会出现获取到的ip不准确的问题, 可以通过以下几种方式解决(可以混合使用)

方式一, 忽略指定名称的网卡

```yml
spring:
  cloud:
    inetutils:
      ignored-interfaces: 
        - docker0
        - veth.*
```

方式二, 使用正则表达式, 指定使用的网络地址

```yml
spring:
  cloud:
    inetutils:
      preferred-networks: 
        - 192.168
        - 10.0
```

方式三, 只使用站点本地地址

```yml

spring:
  cloud:
    inetutils:
      use-only-site-local-interfaces: true
```

## Demo地址

***[https://github.com/masteranthoneyd/spring-boot-learning/tree/master/spring-boot-docker](https://github.com/masteranthoneyd/spring-boot-learning/tree/master/spring-boot-docker)***

#  Kafka、ELK collect logs

![](https://oldcdn.yangbingdong.com/img/docker-logs-collect/elk-arch1.png)

传统的应用可以将日志存到日志中, 但集成Docker之后, 日志怎么处理？放到容器的某个目录然后挂在出来？这样也可以, 但这样就相当于给容器与外界绑定了一个状态, 弹性伸缩怎么办？个人还是觉得通过队列与ELK管理Docker日志比较合理, 而且Log4j2**原生支持Kafka的Appender**. 

## 镜像准备

Docker Hub中的ELK镜像并不是最新版本的, 我们需要到官方的网站获取最新的镜像: ***[https://www.docker.elastic.co](https://www.docker.elastic.co)***

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

```yaml
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

* `KAFKA_ADVERTISED_HOST_NAME`是内网IP, 本地调试用, Docker环境下换成`kafka`（与别名`aliases的值保持一致`）, 其他Docker应用可通过`kafka:9092`这个域名访问到Kafka. 

## ELK配置以及启动

### X-Pack 破解

#### 复制Jar包

先启动一个Elasticsearch的容器, 将Jar包copy出来: 

```
export CONTAINER_NAME=elk_elk-elasticsearch_1
docker cp ${CONTAINER_NAME}:/usr/share/elasticsearch/modules/x-pack-core/x-pack-core-6.4.0.jar ./
docker cp ${CONTAINER_NAME}:/usr/share/elasticsearch/lib ./lib
```

#### 反编译并修改源码

找到下面两个类: 
```
org.elasticsearch.license.LicenseVerifier.class org.elasticsearch.xpack.core.XPackBuild.class
```
使用 ***[Luyten](https://github.com/deathmarine/Luyten)*** 进行反编译

![](https://oldcdn.yangbingdong.com/img/docker-logs-collect/luyten.png)

将两个类复制IDEA（**需要引入上面copy出来的lib以及`x-pack-core-6.4.0.jar`本身**）, 修改为如下样子: 

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

```java
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

![](https://oldcdn.yangbingdong.com/img/docker-logs-collect/jar-archive.png)

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

##### Kafka Input

`logstash.conf` 配置文件(**注意下面的topics要与上面log4j2.xml中的一样**):

```
input {
    kafka {
        bootstrap_servers => ["kafka:9092"]
        auto_offset_reset => "latest"
        consumer_threads => 3 # 3个消费线程, 默认是1个
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

  date {  # 将上面得到的日期信息, 也就是日志打印的时间作为时间戳
    match => [ "timestamp", "yyyy-MM-dd HH:mm:ss.SSS" ]
    locale => "en"
    target => [ "@timestamp" ]
    timezone => "Asia/Shanghai" # 这里如果不设置时区, 在Kibana中展示的时候会多了8个小时
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

##### Filebeat Input

```
input {
  beats {
#    host => filebeat
    port => 5044
  }
}
filter {

  mutate{  # 切分日志信息并添加相应字段

    split => [ "message"," | " ]

    add_field => {
      "timestamp" => "%{[message][0]}"
    }

    add_field => {
      "level" => "%{[message][1]}"
    }

    add_field => {
      "server_name" => "%{[message][2]}"
    }

    add_field => {
      "ip" => "%{[message][3]}"

    }

    add_field => {
      "logger" => "%{[message][4]}"
    }

    add_field => {
      "thread_class_method" => "%{[message][5]}"
    }

    add_field => {
      "content" => "%{[message][6]}"
    }

  }

  date {  # 将上面得到的日期信息, 也就是日志打印的时间作为时间戳
    match => [ "timestamp", "yyyy-MM-dd HH:mm:ss.SSS" ]
    locale => "en"
    target => "@timestamp" 
    timezone => "Asia/Shanghai" # 这里如果不设置时区, 在Kibana中展示的时候会多了8个小时
  }

  geoip { # 分析ip
    source => "ip"
  }

  mutate{
    # 定义去除的字段
    remove_field => ["agent", "source", "input", "@version", "log", "ecs", "_score", "beat", "offset","prospector", "host.name", "message"]
  }

}
output {
    # 输出到控制台
    stdout{ codec => rubydebug }

    # 输出到 Elasticsearch
    elasticsearch {
        hosts  => ["elk-elasticsearch:9200"]
        index  => "logstash-%{server_name}-%{+YYYY.MM.dd}"

        # manage_template => false # 关闭logstash默认索引模板
        # template_name => "crawl" #映射模板的名字
        # template_overwrite => true
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

User-Agent 分析配置:

```
# 将 UA 输出到日志当中, 在 mutate 中添加:
    add_field => {
      "device" => "%{[message][4]}"
    }

# 在 filter 中添加
  useragent { # 分析User-Agent
    source => "device"
    target => "userDevice"
    remove_field => [ "device" ]
  }
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

#### Filebeat

这是另外一种基于文件的日志收集.

filebeat.yml:

```yaml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /log4j2Logs/example/all.log
  multiline:
    pattern: ^\d{4} # 多行处理，正则表示如果前面几个数字不是4个数字开头，那么就会合并到一行
    negate: true # 正则是否开启，默认false不开启
    match: after # 不匹配的正则的行是放在上面一行的前面还是后面
  fields:      # 在采集的信息中添加一个自定义字段 service
    service: example


output.logstash:
  hosts: ["logstash:5044"]
#output.console:
#  pretty: true
```

### 申请License

转到 ***[License申请地址](https://license.elastic.co/registration)*** , 下载之后然后修改license中的`type`、`max_nodes`、`expiry_date_in_millis`: 

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

在此之前, 官方提到了`vm.max_map_count`的值在生产环境最少要设置成262144, 设置的方式有两种:

1. 永久性的修改, 在`/etc/sysctl.conf`文件中添加一行:

   ```
   grep vm.max_map_count /etc/sysctl.conf # 查找当前的值。
   
   vm.max_map_count=262144 # 修改或者新增
   ```

2. 正在运行的机器:

   ```
   sysctl -w vm.max_map_count=262144
   ```



`docker-compose.yml`:

```yaml
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
      
#  filebeat:
#    image: docker.elastic.co/beats/filebeat:7.1.1
#    restart: always
#    volumes:
#      - ./filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
#      - /home/ybd/data/git-repo/bitbucket/central-city/cc-component/log4j2Logs:/log4j2Logs
#    deploy:
#      placement:
#        constraints:
#          - node.role == manager
#    networks:
#      backend:
#        aliases:
#          - filebeat

# docker network create -d=overlay --attachable backend
# docker network create --opt encrypted -d=overlay --attachable --subnet 10.10.0.0/16 backend
networks:
  backend:
    external:
      name: backend

```

启动后需要手动请求更新License: 

```
docker-compose up -d
docker exec ${CONTAINER_NAME} curl -XPUT 'http://0.0.0.0:9200/_xpack/license' -H "Content-Type: application/json" -d @license.json
```

大概是下面这个样子: 

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


![](https://oldcdn.yangbingdong.com/kibana-license.png)

![](https://oldcdn.yangbingdong.com/img/docker-logs-collect/kibana02.png)

### 动态模板

我们可以自定义Logstash输出到ElasticSearch的Mapping.

logstash.conf 的 output 配置:

```
output {
    # 输出到控制台
    stdout{ codec => rubydebug }

    # 输出到 Elasticsearch
    elasticsearch {
        hosts  => ["elk-elasticsearch:9200"]
        index  => "logstash-%{server_name}-%{+YYYY.MM.dd}"

        template => "/usr/share/logstash/config/logstash-template.json"
        template_name => "logstash" #映射模板的名字
        template_overwrite => true
    }
```

配置模板:

logstash-template.json:

```json
{
    "template":"logstash-*",
    "settings":{
        "index.number_of_shards":5,
        "number_of_replicas":0
    },
    "mappings":{
        "dynamic_templates":[
            {
                "message_field":{
                    "match":"content",
                    "match_mapping_type":"string",
                    "mapping":{
                        "type":"text"
                    }
                }
            },
            {
                "string_fields":{
                    "match":"*",
                    "match_mapping_type":"string",
                    "mapping":{
                        "type":"keyword"
                    }
                }
            }
        ],
        "properties":{
            "@timestamp":{
                "type":"date"
            },
            "@version":{
                "type":"keyword"
            },
            "geoip":{
                "dynamic":true,
                "properties":{
                    "ip":{
                        "type":"ip"
                    },
                    "location":{
                        "type":"geo_point"
                    },
                    "latitude":{
                        "type":"float"
                    },
                    "longitude":{
                        "type":"float"
                    }
                }
            }
        }
    }
}
```

docker-compose.yml 中添加配置文件的映射:

```
  logstash:
    image: docker.elastic.co/logstash/logstash:7.1.1
    #    ports:
    #      - "4560:4560"
    restart: always
    environment:
      - LS_JAVA_OPTS=-Xmx512m -Xms512m
    volumes:
      - ./logstash/logstash.conf:/etc/logstash.conf
      - ./logstash/logstash.yml:/usr/share/logstash/config/logstash.yml
      - ./elasticsearch/logstash-template.json:/usr/share/logstash/config/logstash-template.json
```



## Kibana相关设置

### 显示所有插件

在Kibana首页最下面找到: 

![](https://oldcdn.yangbingdong.com/img/docker-logs-collect/kibana-full-plugin-button.png)

### Discover每页显示行数

找到Advanced Setting![](https://oldcdn.yangbingdong.com/img/docker-logs-collect/kibana-admin-setting.png)

点进去找到 `discover:sampleSize`再点击Edit修改:

![](https://oldcdn.yangbingdong.com/img/docker-logs-collect/kibana-page-size.png)

### 时区

Kibana默认读取浏览器时区, 可通过`dateFormat:tz`进行修改: 

![](https://oldcdn.yangbingdong.com/img/docker-logs-collect/kibana-timezone.png)

## ElasticSearch UI

* ***[ElasticHD](https://github.com/360EntSecGroup-Skylar/ElasticHD)***
* ***[Dejavu](https://github.com/appbaseio/dejavu/)***

# Spring Boot 集成 Elastic APM

## 运行APM Server

`docker-compose`:

```yaml
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

这个配置文件从容器中`/usr/share/apm-server/apm-server.yml`复制出来稍微改了一下Elasticsearch的Url. 

若开启了X-Pack, 则需要在yml中配置帐号密码: 

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

启动后在Kibana的APM模块中更新一下索引, 效果图大概是这样的: 

![](https://oldcdn.yangbingdong.com/img/docker-logs-collect/apm.png)

# log-pilot

Github: ***[https://github.com/AliyunContainerService/log-pilot](https://github.com/AliyunContainerService/log-pilot)***

更多说明: ***[https://yq.aliyun.com/articles/69382](https://yq.aliyun.com/articles/69382)***

这个是Ali开源的日志收集组件, 通过中间件的方式部署, 自动监听其他容器的日志, 非常方便: 

```
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v /etc/localtime:/etc/localtime -v /:/host -e PILOT_TYPE=fluentd -e FLUENTD_OUTPUT=elasticsearch -e ELASTICSEARCH_HOST=192.168.6.113 -e ELASTICSEARCH_PORT=9200 -e TZ=Asia/Chongqing --privileged registry.cn-hangzhou.aliyuncs.com/acs-sample/log-pilot:latest
```

需要手机日志的容器: 

```
docker run --rm --label aliyun.logs.demo=stdout -p 8080:8080 192.168.0.202:8080/dev-images/demo:latest
```

* 通过`--label aliyun.logs.demo=stdout`告诉`log-pilot`需要收集日志, 索引为`demo`

然后打开Kibana就可以看到日志了. 

问题: 

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