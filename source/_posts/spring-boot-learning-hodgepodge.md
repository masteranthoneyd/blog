---
title: Spring Boot学习之杂记篇
date: 2018-02-25 15:25:35
categories: [Programming, Java, Spring Boot]
tags: [Java, Spring, Spring Boot]
---

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/spring-boot.png)

> Spring Boot作为当下最流行的微服务项目构建基础，有的时候我们根本不需要额外的配置就能够干很多的事情，这得益于它的一个核心理念：“习惯优于配置”。。。
>
> 说白的就是大部分的配置都已经按照~~最佳实践~~的编程规范配置好了
>
> 本文基于 Spring Boot 2的学习杂记，还是与1.X版本还是有一定区别的

<!--more-->

# 构建依赖版本管理工程

学习Demo：***[https://github.com/masteranthoneyd/spring-boot-learning](https://github.com/masteranthoneyd/spring-boot-learning)***

> 为什么要分开为两个工程？因为考虑到common工程也需要版本控制，但parent工程中依赖了common工程，所以common工程不能依赖parent工程（循环依赖），故例外抽离出一个dependencies的工程，专门用作依赖版本管理，而parent工程用作其他子工程的公共依赖。

## 依赖版本管理工程

跟下面父工程一样只有一个`pom.xml`

*[https://github.com/masteranthoneyd/spring-boot-learning/tree/master/spring-boot-parent-dependencies](https://github.com/masteranthoneyd/spring-boot-learning/tree/master/spring-boot-parent-dependencies)*

## 父工程

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/parent.png)

*[https://github.com/masteranthoneyd/spring-boot-learning/blob/master/spring-boot-parent/pom.xml](https://github.com/masteranthoneyd/spring-boot-learning/blob/master/spring-boot-parent/pom.xml)*

说明：

* `<packaging>` 为 `pom` 表示此会被打包成 pom 文件被其他子项目依赖。
* 由于 Spring Boot 以及集成了 `maven-surefire-plugin` 插件，跳过测试只需要在 properties中添加 `<maven.test.skip>true</maven.test.skip>`即可，等同 `mvn package -Dmaven.test.skip=true`，也可使用 `<skipTests>true</skipTests>`，两者的区别在于 `<maven.test.skip>` 标签连 `.class` 文件都不会生成，而 `<skipTests>` 会编译生成 `.class` 文件


* 子项目会继承父项目的 `properties`，若子项目重新定义属性，则会覆盖父项目的属性。
* `<dependencyManagement>` 管理依赖版本，不使用 `<parent>` 来依赖 Spring Boot，可以使用上面方式，添加 `<type>` 为 `pom` 以及 `<scope>` 为 `import`。
* `<pluginManagement>` 的功能类似于 `<dependencyManagement>`，在父项目中设置好插件属性，在子项目中直接依赖就可以，不需要每个子项目都配置一遍，当然了，子项目也可以覆盖插件属性。

# 打包

## 打包成可执行的Jar

默认情况下Spring Boot打包出来的jar包是不可执行的，需要这样配置：

```
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
            <version>${spring-boot.version}</version>
            <executions>
                <execution>
                    <goals>
                        <goal>repackage</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
```

打包之后会发现有**两个**jar，一个是本身的代码，一个是集成了Spring Boot的可运行jar：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/repackage.png)

## 打包依赖了Spring Boot的工具库

只需要在打包插件`spring-boot-maven-plugin`中这样配置：

```
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
            <executions>
                <execution>
                    <phase>none</phase>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

## 打包契约类

```
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-jar-plugin</artifactId>
            <configuration>
                <includes>
                    <include>com/yangbingdong/server/**/contract/**/*.class</include>
                </includes>
            </configuration>
        </plugin>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
            <executions>
                <execution>
                    <phase>none</phase>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

然后指定该pom文件构建：

```
mvn -f pom_own.xml package
```

# 配置文件：Properties 和 YAML

## 配置文件的生效顺序，会对值进行覆盖

1. `@TestPropertySource` 注解

2. 命令行参数
3. Java系统属性（`System.getProperties()`）
4. 操作系统环境变量
5. 只有在`random.*`里包含的属性会产生一个`RandomValuePropertySource`
6. 在打包的jar外的应用程序配置文件（`application.properties`，包含YAML和profile变量）
7. 在打包的jar内的应用程序配置文件（`application.properties`，包含YAML和profile变量）
8. 在`@Configuration`类上的`@PropertySource`注解
9. 默认属性（使用`SpringApplication.setDefaultProperties`指定）

## 配置随机值

```
roncoo.secret=${random.value}
roncoo.number=${random.int}
roncoo.bignumber=${random.long}
roncoo.number.less.than.ten=${random.int(10)}
roncoo.number.in.range=${random.int[1024,65536]}

读取使用注解：@Value(value = "${roncoo.secret}")
```

## 应用简单配置

```
#端口配置：
server.port=8090
#应用名
spring.application.name=test-demo
#时间格式化
spring.jackson.date-format=yyyy-MM-dd HH:mm:ss
#时区设置
spring.jackson.time-zone=Asia/Chongqing
```

## 配置文件-多环境配置

### 多环境配置的好处

> - 不同环境配置可以配置不同的参数
> - 便于部署，提高效率，减少出错

### Properties多环境配置

```
1. 配置激活选项
spring.profiles.active=dev

2.添加其他配置文件
application.properties
application-dev.properties
application-prod.properties
application-test.properties
```

### YAML多环境配置

```
1.配置激活选项
spring:
  profiles:
    active: dev
2.在配置文件添加三个英文状态下的短横线即可区分
---
spring:
  profiles: dev
```

### 两种配置方式的比较

- Properties配置多环境，需要添加多个配置文件，YAML只需要一个配件文件
- 书写格式的差异，yaml相对比较简洁，优雅
- YAML的缺点：不能通过`@PropertySource`注解加载。如果需要使用`@PropertySource`注解的方式加载值，那就要使用properties文件。

### 如何使用

```
java -Dspring.profiles.active=dev -jar myapp.jar
```

# 热部署

`pom.xml`添加依赖：

```
    <dependencies>
        <!--支持热启动jar包-->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-devtools</artifactId>
            <!-- optional=true,依赖不会传递，该项目依赖devtools；之后依赖该项目的项目如果想要使用devtools，需要重新引入 -->
            <optional>true</optional>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <fork>true</fork>
                </configuration>
            </plugin>
        </plugins>
    </build>
```

`application.yml`配置文件中添加：

```
spring:
  devtools:
    restart:
      #热部署生效 默认就是为true
      enabled: true
      #classpath目录下的WEB-INF文件夹内容修改不重启
      exclude: WEB-INF/**
```

关于DevTools的键值如下：
```
# DEVTOOLS (DevToolsProperties)
spring.devtools.livereload.enabled=true # Enable a livereload.com compatible server.
spring.devtools.livereload.port=35729 # Server port.
spring.devtools.restart.additional-exclude= # Additional patterns that should be excluded from triggering a full restart.
spring.devtools.restart.additional-paths= # Additional paths to watch for changes.
spring.devtools.restart.enabled=true # Enable automatic restart.
spring.devtools.restart.exclude=META-INF/maven/**,META-INF/resources/**,resources/**,static/**,public/**,templates/**,**/*Test.class,**/*Tests.class,git.properties # Patterns that should be excluded from triggering a full restart.
spring.devtools.restart.poll-interval=1000 # Amount of time (in milliseconds) to wait between polling for classpath changes.
spring.devtools.restart.quiet-period=400 # Amount of quiet time (in milliseconds) required without any classpath changes before a restart is triggered.
spring.devtools.restart.trigger-file= # Name of a specific file that when changed will trigger the restart check. If not specified any classpath file change will trigger the restart.

# REMOTE DEVTOOLS (RemoteDevToolsProperties)
spring.devtools.remote.context-path=/.~~spring-boot!~ # Context path used to handle the remote connection.
spring.devtools.remote.debug.enabled=true # Enable remote debug support.
spring.devtools.remote.debug.local-port=8000 # Local remote debug server port.
spring.devtools.remote.proxy.host= # The host of the proxy to use to connect to the remote application.
spring.devtools.remote.proxy.port= # The port of the proxy to use to connect to the remote application.
spring.devtools.remote.restart.enabled=true # Enable remote restart.
spring.devtools.remote.secret= # A shared secret required to establish a connection (required to enable remote support).
spring.devtools.remote.secret-header-name=X-AUTH-TOKEN # HTTP header used to transfer the shared secret.
```

当我们修改了java类后，IDEA默认是不自动编译的，而`spring-boot-devtools`又是监测`classpath`下的文件发生变化才会重启应用，所以需要设置IDEA的自动编译：

（1）**File-Settings-Compiler-Build Project automatically**

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/spring-boot-devtools01.png)

（2）**ctrl + shift + alt + /,选择Registry,勾上 Compiler autoMake allow when app running**

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/spring-boot-devtools02.png)

OK了，重启一下项目，然后改一下类里面的内容，IDEA就会自动去make了。

> **热部署可能会牺牲一定的系统性能，因为是动态的编译**

# 使用为Undertow作为Web容器

> Spring Boot内嵌容器支持Tomcat、Jetty、Undertow。
> 根据 [Tomcat vs. Jetty vs. Undertow: Comparison of Spring Boot Embedded Servlet Containers](https://link.jianshu.com/?t=https://examples.javacodegeeks.com/enterprise-java/spring/tomcat-vs-jetty-vs-undertow-comparison-of-spring-boot-embedded-servlet-containers/) 这篇文章统计，Undertow的综合性能更好。
>
> 在Spring Boot 2中，已经把netty作为webflux的默认容器

## 与Tomcat性能对比

以下是Undertow与Tomcat简单的性能测试（同样是默认配置）

Tomcat:

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/tomcat-gatling-test.jpg)

Undertow:

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/undertow-gatling-test.jpg)

显然Undertow的吞吐量要比Tomcat高

## Maven配置

```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <exclusions>
        <!-- 移除默认web容器，使用undertow -->
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-tomcat</artifactId>
        </exclusion>
    </exclusions>
</dependency>

如果是webflux，默认的容器的netty
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webflux</artifactId>
    <exclusions>
        <!-- 移除默认web容器，使用undertow -->
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-reactor-netty</artifactId>
        </exclusion>
    </exclusions>
</dependency>

<!-- 使用高性能 Web 容器 undertow -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-undertow</artifactId>
</dependency>
```

## 监听多个端口与HTTP2支持

```
// 在@Configuration的类中添加@bean
@Bean
UndertowEmbeddedServletContainerFactory embeddedServletContainerFactory() {
    
    UndertowEmbeddedServletContainerFactory factory = new UndertowEmbeddedServletContainerFactory();
    
    // 这里也可以做其他配置
	// 支持HTTP2
	factory.addBuilderCustomizers(builder -> {
		builder.setServerOption(UndertowOptions.ENABLE_HTTP2, true);
		// 监听多个端口
		builder.addHttpListener(8080, "0.0.0.0");
	});
    return factory;
}
```

## Undertow相关配置

```
# Undertow 日志存放目录
server.undertow.accesslog.dir
# 是否启动日志
server.undertow.accesslog.enabled=false 
# 日志格式
server.undertow.accesslog.pattern=common
# 日志文件名前缀
server.undertow.accesslog.prefix=access_log
# 日志文件名后缀
server.undertow.accesslog.suffix=log
# HTTP POST请求最大的大小
server.undertow.max-http-post-size=0 
# 设置IO线程数, 它主要执行非阻塞的任务,它们会负责多个连接, 默认设置每个CPU核心一个线程
server.undertow.io-threads=4
# 阻塞任务线程池, 当执行类似servlet请求阻塞操作, undertow会从这个线程池中取得线程,它的值设置取决于系统的负载，默认数量为 CPU核心*8
server.undertow.worker-threads=20
# 以下的配置会影响buffer,这些buffer会用于服务器连接的IO操作,有点类似netty的池化内存管理
# 每块buffer的空间大小,越小的空间被利用越充分
server.undertow.buffer-size=1024
# 每个区分配的buffer数量 , 所以pool的大小是buffer-size * buffers-per-region
server.undertow.buffers-per-region=1024
# 是否分配的直接内存
server.undertow.direct-buffers=true
```

# 日志相关

## 使用Log4j2

> 更多Log4j2配置请看：***[https://my.oschina.net/kkrgwbj/blog/734530](https://my.oschina.net/kkrgwbj/blog/734530)***

下面是 Log4j2  官方性能测试结果：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/log4j2-performance.png)

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

**注意**：需要单独把`spring-boot-starter`里面的`logging`去除再引入`spring-boot-starter-web`，否则后面引入的`starter`模块带有的`logging`不会自动去除

### application.yml简单配置

```
logging:
  config: classpath:log4j2.xml # 指定log4j2配置文件的路径，默认就是这个
  pattern:
    console: "%clr{%d{yyyy-MM-dd HH:mm:ss.SSS}}{faint} | %clr{%5p} | %clr{%15.15t}{faint} | %clr{%-50.50c{1.}}{cyan} | %5L | %clr{%M}{magenta} | %msg%n%xwEx" # 控制台日志输出格式
```

### log4j2.xml配置

```
<?xml version="1.0" encoding="UTF-8"?>
<!-- Configuration后面的status，这个用于设置log4j2自身内部的信息输出，可以不设置，当设置成trace时，
     你会看到log4j2内部各种详细输出。可以设置成OFF(关闭) 或 Error(只输出错误信息)。
     30s 刷新此配置
-->
<configuration status="OFF" monitorInterval="30">

    <!-- 日志文件目录、压缩文件目录、日志格式配置 -->
    <properties>
        <Property name="fileName">/home/ybd/logs</Property>
        <Property name="fileGz">/home/ybd/logs/7z</Property>
        <Property name="PID">????</Property>
        <!--<Property name="LOG_PATTERN">%clr{%d{yyyy-MM-dd HH:mm:ss.SSS z}}{faint} %clr{%5p} %clr{${sys:PID}}{magenta}
            %clr{-&#45;&#45;}{faint} %clr{[%t]}{faint} %clr{%-40.40c{1.}}{cyan} %clr{:}{faint} %m%n%xwEx
        </Property>-->
        <Property name="LOG_PATTERN">%clr{%d{yyyy-MM-dd HH:mm:ss.SSS}}{faint} | %clr{%5p} | %clr{${sys:PID}}{magenta} | %clr{%15.15t}{faint} | %clr{%-50.50c{1.}}{cyan} | %5L | %clr{%M}{magenta} | %msg%n%xwEx
        </Property>
    </properties>

    <Appenders>
        <!-- 输出控制台日志的配置 -->
        <Console name="console" target="SYSTEM_OUT">
            <!--控制台只输出level及以上级别的信息（onMatch），其他的直接拒绝（onMismatch）-->
            <ThresholdFilter level="info" onMatch="ACCEPT" onMismatch="DENY"/>
            <!-- 输出日志的格式 -->
            <PatternLayout pattern="${LOG_PATTERN}" charset="UTF-8"/>
        </Console>

        <!-- 打印出所有的信息，每次大小超过size，则这size大小的日志会自动存入按年份-月份建立的文件夹下面并进行压缩，作为存档 -->
        <RollingRandomAccessFile name="infoFile" fileName="${fileName}/web-info.log" immediateFlush="false"
                                 filePattern="${fileGz}/$${date:yyyy-MM}/%d{yyyy-MM-dd}-%i.web-info.gz">
            <PatternLayout pattern="${LOG_PATTERN}" charset="UTF-8"/>

            <Policies>
                <SizeBasedTriggeringPolicy size="20 MB"/>
            </Policies>

            <Filters>
                <!-- 只记录info和warn级别信息 -->
                <ThresholdFilter level="error" onMatch="DENY" onMismatch="NEUTRAL"/>
                <ThresholdFilter level="info" onMatch="ACCEPT" onMismatch="DENY"/>
            </Filters>

            <!-- 指定每天的最大压缩包个数，默认7个，超过了会覆盖之前的 -->
            <DefaultRolloverStrategy max="50"/>
        </RollingRandomAccessFile>

        <!-- 存储所有error信息 -->
        <RollingRandomAccessFile name="errorFile" fileName="${fileName}/web-error.log" immediateFlush="false"
                                 filePattern="${fileGz}/$${date:yyyy-MM}/%d{yyyy-MM-dd}-%i.web-error.gz">
            <PatternLayout pattern="${LOG_PATTERN}" charset="UTF-8"/>

            <Policies>
                <SizeBasedTriggeringPolicy size="50 MB"/>
            </Policies>

            <Filters>
                <!-- 只记录error级别信息 -->
                <ThresholdFilter level="error" onMatch="ACCEPT" onMismatch="DENY"/>
            </Filters>

            <!-- 指定每天的最大压缩包个数，默认7个，超过了会覆盖之前的 -->
            <DefaultRolloverStrategy max="50"/>
        </RollingRandomAccessFile>
    </Appenders>

    <!-- Mixed sync/async -->
    <Loggers>
    
        <!--<logger name="org.apache.http" level="warn"/>
        <logger name="org.springframework" level="WARN"/>
        <logger name="com.ibatis" level="DEBUG"/>
        <logger name="com.ibatis.common.jdbc.SimpleDataSource" level="DEBUG"/>
        <logger name="com.ibatis.common.jdbc.ScriptRunner" level="DEBUG"/>
        <logger name="com.ibatis.sqlmap.engine.impl.SqlMapClientDelegate" level="DEBUG"/>
        <logger name="java.sql.Connection" level="DEBUG" additivity="true"/>
        <logger name="java.sql.Statement" level="DEBUG" additivity="true"/>
        <logger name="java.sql.PreparedStatement" level="=debug,stdout" additivity="true"/>
        <logger name="java.sql.ResultSet" level="DEBUG" additivity="true"/>
        <logger name="org.apache" level="WARN"/>

        &lt;!&ndash; 对包进行更详细的配置 &ndash;&gt;
        &lt;!&ndash; additivity表示是否追加,防止重复,因为root已经接收过一次了 &ndash;&gt;
        <logger name="com.my.blog.website.dao" level="DEBUG" additivity="true">
            <appender-ref ref="db_log"/>
        </logger>
        <logger name="com.my.blog.website.controller" level="DEBUG" additivity="false">
            <appender-ref ref="service_log"/>
        </logger>
        <logger name="com.my.blog.website.service" level="DEBUG" additivity="false">
            <appender-ref ref="service_log"/>
        </logger>-->

        <AsyncRoot level="debug" includeLocation="true">
            <AppenderRef ref="console"/>
            <AppenderRef ref="infoFile"/>
            <AppenderRef ref="errorFile"/>
        </AsyncRoot>
    </Loggers>

</configuration>
```

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

## 日志配置文件中获取Application配置项

### Logback

方法1: 使用`logback-spring.xml`，因为`logback.xml`加载早于`application.properties`，所以如果你在`logback.xml`使用了变量时，而恰好这个变量是写在`application.properties`时，那么就会获取不到，只要改成`logback-spring.xml`就可以解决。

方法2: 使用`<springProperty>`标签，例如：

```
<springProperty scope="context" name="LOG_HOME" source="logback.file"/>
```

### Log4j2

只能写一个Lookup：

```
@SuppressWarnings("unused")
@Plugin(name = "spring", category = StrLookup.CATEGORY)
public class SpringEnvironmentLookup extends AbstractLookup {
	private static LinkedHashMap profileYmlData;
	private static LinkedHashMap metaYmlData;
	private static boolean profileExist;
	private static Map<String, String> map = new HashMap<>(16);
	private static final String META_PROFILE = "application.yml";
	private static final String PROFILE_PREFIX = "application";
	private static final String PROFILE_SUFFIX = ".yml";
	private static final String DEFAULT_PROFILE = "application-dev.yml";
	private static final String SPRING_PROFILES_ACTIVE = "spring.profiles.active";

	static {
		try {
			metaYmlData = new Yaml().loadAs(new ClassPathResource(META_PROFILE).getInputStream(), LinkedHashMap.class);
			Properties properties = System.getProperties();
			String active = properties.getProperty(SPRING_PROFILES_ACTIVE);
			if (isBlank(active)) {
				active = getValueFromData(SPRING_PROFILES_ACTIVE, metaYmlData);
			}
			String configName = isNotBlank(active) ? PROFILE_PREFIX + "-" + active + PROFILE_SUFFIX : DEFAULT_PROFILE;
			ClassPathResource classPathResource = new ClassPathResource(configName);
			profileExist = classPathResource.exists();
			if (profileExist) {
				profileYmlData = new Yaml().loadAs(classPathResource.getInputStream(), LinkedHashMap.class);
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

# 查看依赖树

如果引入了某些jar包带有`logback`依赖，log4j2会失效，需要通过IDEA或Maven查找排除依赖：

```
mvn dependency:tree
```

# Spring MVC 相关

## Spring MVC 流程

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/spring-mvc-process.jpg)

1、  用户发送请求至前端控制器`DispatcherServlet`。

2、  `DispatcherServlet`收到请求调用`HandlerMapping`处理器映射器。

3、  处理器映射器找到具体的处理器(可以根据xml配置、注解进行查找)，生成处理器对象及处理器拦截器(如果有则生成)一并返回给`DispatcherServlet`。

4、  `DispatcherServlet`调用`HandlerAdapter`处理器适配器。

5、  `HandlerAdapter`经过适配调用具体的处理器(`Controller`，也叫后端控制器)。

6、  `Controller`执行完成返回`ModelAndView`。

7、  `HandlerAdapter`将`controller`执行结果`ModelAndView`返回给`DispatcherServlet`。

8、  `DispatcherServlet`将`ModelAndView`传给`ViewReslover`视图解析器。

9、  `ViewReslover`解析后返回具体`View`。

10、`DispatcherServlet`根据`View`进行渲染视图（即将模型数据填充至视图中）。

11、 `DispatcherServlet`响应用户。

## Spring MVC集成fastjson

> ***[https://github.com/alibaba/fastjson/wiki/%E5%9C%A8-Spring-%E4%B8%AD%E9%9B%86%E6%88%90-Fastjson](https://github.com/alibaba/fastjson/wiki/%E5%9C%A8-Spring-%E4%B8%AD%E9%9B%86%E6%88%90-Fastjson)***

```
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>fastjson</artifactId>
    <version>1.2.46</version>
</dependency>
```

两种方式：

### 方式一、实现`WebMvcConfigurer`

```
@Configuration
public class WebMvcMessageConvertConfig implements WebMvcConfigurer {
	@Override
	public void configureMessageConverters(List<HttpMessageConverter<?>> converters) {
		FastJsonHttpMessageConverter fastConverter = new FastJsonHttpMessageConverter();

		SerializeConfig serializeConfig = SerializeConfig.globalInstance;
		serializeConfig.put(BigInteger.class, ToStringSerializer.instance);
		serializeConfig.put(Long.class, ToStringSerializer.instance);
		serializeConfig.put(Long.TYPE, ToStringSerializer.instance);

		FastJsonConfig fastJsonConfig = new FastJsonConfig();
		fastJsonConfig.setCharset(Charset.forName("UTF-8"));
		fastJsonConfig.setSerializeConfig(serializeConfig);
		fastJsonConfig.setSerializerFeatures(SerializerFeature.PrettyFormat);
		fastJsonConfig.setDateFormat("yyyy-MM-dd HH:mm:ss");

		fastConverter.setFastJsonConfig(fastJsonConfig);

		converters.add(fastConverter);
	}
}
```

### 方式二、通过`@Bean`方式

```
@Configuration
public class WebMvcMessageConvertConfig {
	@Bean
	public HttpMessageConverters fastJsonHttpMessageConverter() {
		FastJsonHttpMessageConverter fastConverter = new FastJsonHttpMessageConverter();

		SerializeConfig serializeConfig = SerializeConfig.globalInstance;
		serializeConfig.put(BigInteger.class, ToStringSerializer.instance);
		serializeConfig.put(Long.class, ToStringSerializer.instance);
		serializeConfig.put(Long.TYPE, ToStringSerializer.instance);

		FastJsonConfig fastJsonConfig = new FastJsonConfig();
		fastJsonConfig.setCharset(Charset.forName(Constant.CHARSET));
		fastJsonConfig.setSerializeConfig(serializeConfig);
		fastJsonConfig.setSerializerFeatures(SerializerFeature.PrettyFormat);
		fastJsonConfig.setDateFormat(Constant.DATE_FORMAT);

		fastConverter.setFastJsonConfig(fastJsonConfig);
		return new HttpMessageConverters((HttpMessageConverter<?>) fastConverter);
	}
}
```

### WebFlux

上面针对的是Web MVC，**对于Webflux目前不支持这种方式**，只能先这么设置

```
spring:
  jackson:
    default-property-inclusion: non_null # 过滤值为null的字段
    date-format: "yyyy-MM-dd HH:mm:ss"
```

## Spring Boot MVC特性

Spring boot 在spring默认基础上，自动配置添加了以下特性

- 包含了`ContentNegotiatingViewResolver`和`BeanNameViewResolver` beans。
- 对静态资源的支持，包括对WebJars的支持。
- 自动注册`Converter`，`GenericConverter`，`Formatter` beans。
- 对`HttpMessageConverters`的支持。
- 自动注册`MessageCodeResolver`。
- 对静态`index.html`的支持。
- 对自定义`Favicon`的支持。
- 主动使用`ConfigurableWebBindingInitializer` bean

## 模板引擎的选择

- FreeMarker
- Thymeleaf
- Velocity (1.4版本之后弃用，Spring Framework 4.3版本之后弃用)
- Groovy
- Mustache

注：**jsp应该尽量避免使用**，原因如下：

- jsp只能打包为：war格式，不支持jar格式，只能在标准的容器里面跑（tomcat，jetty都可以）
- 内嵌的Jetty目前不支持JSPs
- Undertow不支持jsps
- jsp自定义错误页面不能覆盖spring boot 默认的错误页面

## 开启GZIP算法压缩响应流

```
server:
  compression:
    enabled: true # 启用压缩
    min-response-size: 2048 # 对应Content-Length，超过这个值才会压缩
```

## 全局异常处理

### 方式一：添加自定义的错误页面

- html静态页面：在`resources/public/error/` 下定义. 如添加404页面： `resources/public/error/404.html`页面，中文注意页面编码
- 模板引擎页面：在`templates/error/`下定义. 如添加5xx页面： `templates/error/5xx.ftl`

> 注：`templates/error/` 这个的优先级比较`resources/public/error/`高

### 方式二：通过@ControllerAdvice

```
@Slf4j
@ControllerAdvice
//@RestControllerAdvice
public class ErrorExceptionHandler {

	@ExceptionHandler({ RuntimeException.class })
	@ResponseStatus(HttpStatus.OK)
	public ModelAndView processException(RuntimeException exception) {
		log.info("自定义异常处理-RuntimeException");
		ModelAndView m = new ModelAndView();
		m.addObject("roncooException", exception.getMessage());
		m.setViewName("error/500");
		return m;
	}

	@ExceptionHandler({ Exception.class })
	@ResponseStatus(HttpStatus.OK)
	public ModelAndView processException(Exception exception) {
		log.info("自定义异常处理-Exception");
		ModelAndView m = new ModelAndView();
		m.addObject("roncooException", exception.getMessage());
		m.setViewName("error/500");
		return m;
	}
}
```

## 静态资源

设置静态资源放到指定路径下

```
spring.resources.static-locations=classpath:/META-INF/resources/,classpath:/static/
```

## 自定义消息转化器

```
	@Bean
    public StringHttpMessageConverter stringHttpMessageConverter() {
        StringHttpMessageConverter converter = new StringHttpMessageConverter(Charset.forName("UTF-8"));
        return converter;
    }
```

## 自定义SpringMVC的拦截器

有些时候我们需要自己配置SpringMVC而不是采用默认，比如增加一个拦截器

```
public class MyInterceptor implements HandlerInterceptor {

    @Override
    public void afterCompletion(HttpServletRequest arg0, HttpServletResponse arg1, Object arg2, Exception arg3)
            throws Exception {
        System.out.println("拦截器MyInterceptor------->3、请求结束之后被调用，主要用于清理工作。");

    }

    @Override
    public void postHandle(HttpServletRequest arg0, HttpServletResponse arg1, Object arg2, ModelAndView arg3)
            throws Exception {
        System.out.println("拦截器MyInterceptor------->2、请求之后调用，在视图渲染之前，也就是Controller方法调用之后");

    }

    @Override
    public boolean preHandle(HttpServletRequest arg0, HttpServletResponse arg1, Object arg2) throws Exception {
        System.out.println("拦截器MyInterceptor------->1、请求之前调用，也就是Controller方法调用之前。");
        return true;//返回true则继续向下执行，返回false则取消当前请求
    }

}
```

```
@Configuration
public class InterceptorConfigurerAdapter extends WebMvcConfigurer {
    /**
     * 该方法用于注册拦截器
     * 可注册多个拦截器，多个拦截器组成一个拦截器链
     */
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // addPathPatterns 添加路径
        // excludePathPatterns 排除路径
        registry.addInterceptor(new MyInterceptor()).addPathPatterns("/*.*");
        super.addInterceptors(registry);
    }
}
```

## 创建 Servlet、 Filter、Listener

### 注解方式

> 直接通过`@WebServlet`、`@WebFilter`、`@WebListener` 注解自动注册

```
@WebFilter(filterName = "customFilter", urlPatterns = "/*")
public class CustomFilter implements Filter {
    ...
}

@WebListener
public class CustomListener implements ServletContextListener {
    ...
}

@WebServlet(name = "customServlet", urlPatterns = "/roncoo")
public class CustomServlet extends HttpServlet {
    ...
}

```

然后需要在`**Application.java` 加上`@ServletComponentScan`注解，否则不会生效。

**注意：如果同时添加了`@WebFilter`以及`@Component`，那么会初始化两次Filter，并且会过滤所有路径+自己指定的路径 ，便会出现对没有指定的URL也会进行过滤**

### 通过编码注册

```
@Configuration
public class WebConfig {

    @Bean
    public FilterRegistrationBean myFilter(){
        FilterRegistrationBean registrationBean = new FilterRegistrationBean();
        MyFilter filter = new MyFilter();
        registrationBean.setFilter(filter);

        List<String> urlPatterns = new ArrayList<>();
        urlPatterns.add("/*");
        registrationBean.setUrlPatterns(urlPatterns);
        registrationBean.setOrder(1);

        return registrationBean;
    }

    @Bean
    public ServletRegistrationBean myServlet() {
        MyServlet demoServlet = new MyServlet();
        ServletRegistrationBean registrationBean = new ServletRegistrationBean();
        registrationBean.setServlet(demoServlet);
        List<String> urlMappings = new ArrayList<String>();
        urlMappings.add("/myServlet");////访问，可以添加多个
        registrationBean.setUrlMappings(urlMappings);
        registrationBean.setLoadOnStartup(1);
        return registrationBean;
    }

    @Bean
    public ServletListenerRegistrationBean myListener() {
        ServletListenerRegistrationBean registrationBean
                = new ServletListenerRegistrationBean<>();
        registrationBean.setListener(new MyListener());
        registrationBean.setOrder(1);
        return registrationBean;
    }
}

```

## Spring Interceptor与Servlet Filter的区别

- Filter是基于函数回调的，而Interceptor则是基于Java反射的。
- Filter依赖于Servlet容器，而Interceptor不依赖于Servlet容器。
- Filter对几乎所有的请求起作用，而Interceptor只能对action请求起作用。
- Interceptor可以访问Action的上下文，值栈里的对象，而Filter不能。
- 在action的生命周期里，Interceptor可以被多次调用，而Filter只能在容器初始化时调用一次。

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/mvc-process.png)

# Validation

## 常用注解（大部分**JSR**中已有）

| 注解                                           | 类型                                                         | 说明                                                         |
| ---------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `@AssertFalse`                                 | Boolean,boolean                                              | 验证注解的元素值是false                                      |
| `@AssertTrue`                                  | Boolean,boolean                                              | 验证注解的元素值是true                                       |
| `@NotNull`                                     | 任意类型                                                     | 验证注解的元素值不是null                                     |
| `@Null`                                        | 任意类型                                                     | 验证注解的元素值是null                                       |
| `@Min(value=值)`                               | BigDecimal，BigInteger, byte,short, int, long，等任何Number或CharSequence（存储的是数字）子类型 | 验证注解的元素值大于等于@Min指定的value值                    |
| `@Max（value=值）`                             | 和@Min要求一样                                               | 验证注解的元素值小于等于@Max指定的value值                    |
| `@DecimalMin(value=值)`                        | 和@Min要求一样                                               | 验证注解的元素值大于等于@ DecimalMin指定的value值            |
| `@DecimalMax(value=值)`                        | 和@Min要求一样                                               | 验证注解的元素值小于等于@ DecimalMax指定的value值            |
| `@Digits(integer=整数位数, fraction=小数位数)` | 和@Min要求一样                                               | 验证注解的元素值的整数位数和小数位数上限                     |
| `@Size(min=下限, max=上限)`                    | 字符串、Collection、Map、数组等                              | 验证注解的元素值的在min和max（包含）指定区间之内，如字符长度、集合大小 |
| `@Past`                                        | java.util.Date,java.util.Calendar;Joda Time类库的日期类型    | 验证注解的元素值（日期类型）比当前时间早                     |
| `@Future`                                      | 与@Past要求一样                                              | 验证注解的元素值（日期类型）比当前时间晚                     |
| `@NotBlank`                                    | CharSequence子类型                                           | 验证注解的元素值不为空（不为null、去除首位空格后长度为0），不同于@NotEmpty，@NotBlank只应用于字符串且在比较时会去除字符串的首位空格 |
| `@Length(min=下限, max=上限)`                  | CharSequence子类型                                           | 验证注解的元素值长度在min和max区间内                         |
| `@NotEmpty`                                    | CharSequence子类型、Collection、Map、数组                    | 验证注解的元素值不为null且不为空（字符串长度不为0、集合大小不为0） |
| `@Range(min=最小值, max=最大值)`               | BigDecimal,BigInteger,CharSequence, byte, short, int, long等原子类型和包装类型 | 验证注解的元素值在最小值和最大值之间                         |
| `@Email(regexp=正则表达式,flag=标志的模式)`    | CharSequence子类型（如String）                               | 验证注解的元素值是Email，也可以通过regexp和flag指定自定义的email格式 |
| `@Pattern(regexp=正则表达式,flag=标志的模式)`  | String，任何CharSequence的子类型                             | 验证注解的元素值与指定的正则表达式匹配                       |
| `@Valid`                                       | 任何非原子类型                                               | 指定递归验证关联的对象；如用户对象中有个地址对象属性，如果想在验证用户对象时一起验证地址对象的话，在地址对象上加@Valid注解即可级联验证 |

## 简单使用

实体：

```
@Data
public class Foo {
	@NotBlank
	private String name;

	@Min(18)
	private Integer age;

	@Pattern(regexp = "^1([34578])\\d{9}$",message = "手机号码格式错误")
	@NotBlank(message = "手机号码不能为空")
	private String phone;

	@Email(message = "邮箱格式错误")
	private String email;
}

```

`Controller`:

```
@RestController
@Slf4j
public class FooController {

   @PostMapping("/foo")
   public String foo(@Validated Foo foo, BindingResult bindingResult) {
      log.info("foo: {}", foo);
      if (bindingResult.hasErrors()) {
         for (FieldError fieldError : bindingResult.getFieldErrors()) {
            log.error("valid fail: field = {}, message = {}", fieldError.getField(), fieldError.getDefaultMessage());
         }
         return "fail";
      }
      return "success";
   }
}

```

## 快速失效

一般情况下，Validator并不会应为第一个校验失败为停止，而是一直校验完所有参数。我们可以通过设置快速失效：

```
@Configuration
public class ValidatorConfiguration {
	@Bean
	public Validator validator(){
		ValidatorFactory validatorFactory = Validation.byProvider( HibernateValidator.class )
													  .configure()
													  .failFast( true )
//													  .addProperty( "hibernate.validator.fail_fast", "true" )
													  .buildValidatorFactory();
		return validatorFactory.getValidator();
	}
}

```

这样在遇到第一个校验失败的时候就会停止对之后的参数校验。

## 分组校验

> 如果同一个类，在不同的使用场景下有不同的校验规则，那么可以使用分组校验。未成年人是不能喝酒的，而在其他场景下我们不做特殊的限制，这个需求如何体现同一个实体，不同的校验规则呢？

添加分组：

```
Class Foo{
	@Min(value = 18,groups = {Adult.class})
	private Integer age;
	
	public interface Adult{}
	
	public interface Minor{}
}

```

`Controller`：

```
@RequestMapping("/drink")
public String drink(@Validated({Foo.Adult.class}) Foo foo, BindingResult bindingResult) {
    if(bindingResult.hasErrors()){
        for (FieldError fieldError : bindingResult.getFieldErrors()) {
            //...
        }
        return "fail";
    }
    return "success";
}

```

## 自定义校验

业务需求总是比框架提供的这些简单校验要复杂的多，我们可以自定义校验来满足我们的需求。自定义spring validation非常简单，主要分为两步。

1 自定义校验注解
我们尝试添加一个“字符串不能包含空格”的限制。

```
@Target({METHOD, FIELD, ANNOTATION_TYPE, CONSTRUCTOR, PARAMETER})
@Retention(RUNTIME)
@Documented
@Constraint(validatedBy = {CannotHaveBlankValidator.class})<1>
public @interface CannotHaveBlank {

    //默认错误消息
    String message() default "不能包含空格";

    //分组
    Class<?>[] groups() default {};

    //负载
    Class<? extends Payload>[] payload() default {};

    //指定多个时使用
    @Target({FIELD, METHOD, PARAMETER, ANNOTATION_TYPE})
    @Retention(RUNTIME)
    @Documented
    @interface List {
        CannotHaveBlank[] value();
    }

}

```

我们不需要关注太多东西，使用spring validation的原则便是便捷我们的开发，例如payload，List ，groups，都可以忽略。

`<1>` 自定义注解中指定了这个注解真正的验证者类。

2 编写真正的校验者类

```
public class CannotHaveBlankValidator implements <1> ConstraintValidator<CannotHaveBlank, String> {

	@Override
    public void initialize(CannotHaveBlank constraintAnnotation) {
    }
    
    @Override
    public boolean isValid(String value, ConstraintValidatorContext context <2>) {
        //null时不进行校验
        if (value != null && value.contains(" ")) {
	        <3>
            //获取默认提示信息
            String defaultConstraintMessageTemplate = context.getDefaultConstraintMessageTemplate();
            System.out.println("default message :" + defaultConstraintMessageTemplate);
            //禁用默认提示信息
            context.disableDefaultConstraintViolation();
            //设置提示语
            context.buildConstraintViolationWithTemplate("can not contains blank").addConstraintViolation();
            return false;
        }
        return true;
    }
}

```

`<1>` 所有的验证者都需要实现`ConstraintValidator`接口，它的接口也很形象，包含一个初始化事件方法，和一个判断是否合法的方法

```
public interface ConstraintValidator<A extends Annotation, T> {
	void initialize(A constraintAnnotation);
		boolean isValid(T value, ConstraintValidatorContext context);
}

```

`<2> ` `ConstraintValidatorContext` 这个上下文包含了认证中所有的信息，我们可以利用这个上下文实现获取默认错误提示信息，禁用错误提示信息，改写错误提示信息等操作。

`<3>` 一些典型校验操作，或许可以对你产生启示作用。

值得注意的一点是，自定义注解可以用在`METHOD, FIELD, ANNOTATION_TYPE, CONSTRUCTOR, PARAMETER`之上，`ConstraintValidator`的第二个泛型参数T，是需要被校验的类型。

## 手动校验

可能在某些场景下需要我们手动校验，即使用校验器对需要被校验的实体发起validate，同步获得校验结果。理论上我们既可以使用Hibernate Validation提供Validator，也可以使用Spring对其的封装。在spring构建的项目中，提倡使用经过spring封装过后的方法，这里两种方法都介绍下：

**Hibernate Validation**：

```
Foo foo = new Foo();
foo.setAge(22);
foo.setEmail("000");
ValidatorFactory vf = Validation.buildDefaultValidatorFactory();
Validator validator = vf.getValidator();
Set<ConstraintViolation<Foo>> set = validator.validate(foo);
for (ConstraintViolation<Foo> constraintViolation : set) {
    System.out.println(constraintViolation.getMessage());
}

```

由于依赖了Hibernate Validation框架，我们需要调用Hibernate相关的工厂方法来获取validator实例，从而校验。

在spring framework文档的Validation相关章节，可以看到如下的描述：

> Spring provides full support for the Bean Validation API. This includes convenient support for bootstrapping a JSR-303/JSR-349 Bean Validation provider as a Spring bean. This allows for a javax.validation.ValidatorFactory or javax.validation.Validator to be injected wherever validation is needed in your application. Use the LocalValidatorFactoryBean to configure a default Validator as a Spring bean:

> bean id=”validator” class=”org.springframework.validation.beanvalidation.LocalValidatorFactoryBean”

> The basic configuration above will trigger Bean Validation to initialize using its default bootstrap mechanism. A JSR-303/JSR-349 provider, such as Hibernate Validator, is expected to be present in the classpath and will be detected automatically.

上面这段话主要描述了spring对validation全面支持JSR-303、JSR-349的标准，并且封装了`LocalValidatorFactoryBean`作为validator的实现。值得一提的是，这个类的责任其实是非常重大的，他兼容了spring的validation体系和hibernate的validation体系，也可以被开发者直接调用，代替上述的从工厂方法中获取的hibernate validator。由于我们使用了springboot，会触发web模块的自动配置，`LocalValidatorFactoryBean`已经成为了Validator的默认实现，使用时只需要自动注入即可。

```
@Autowired
Validator globalValidator; <1>

@RequestMapping("/validate")
public String validate() {
    Foo foo = new Foo();
    foo.setAge(22);
    foo.setEmail("000");

    Set<ConstraintViolation<Foo>> set = globalValidator.validate(foo);<2>
    for (ConstraintViolation<Foo> constraintViolation : set) {
        System.out.println(constraintViolation.getMessage());
    }

    return "success";
}

```

`<1>` 真正使用过`Validator`接口的读者会发现有两个接口，一个是位于`javax.validation`包下，另一个位于`org.springframework.validation`包下，**注意我们这里使用的是前者**`javax.validation`，后者是spring自己内置的校验接口，`LocalValidatorFactoryBean`同时实现了这两个接口。

`<2>` 此处校验接口最终的实现类便是`LocalValidatorFactoryBean`。

## 基于方法校验

```
@RestController
@Validated <1>
public class BarController {

    @RequestMapping("/bar")
    public @NotBlank <2> String bar(@Min(18) Integer age <3>) {
        System.out.println("age : " + age);
        return "";
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public Map handleConstraintViolationException(ConstraintViolationException cve){
        Set<ConstraintViolation<?>> cves = cve.getConstraintViolations();<4>
        for (ConstraintViolation<?> constraintViolation : cves) {
            System.out.println(constraintViolation.getMessage());
        }
        Map map = new HashMap();
        map.put("errorCode",500);
        return map;
    }

}

```

`<1>` 为类添加@Validated注解

`<2> <3>` 校验方法的返回值和入参

`<4>` 添加一个异常处理器，可以获得没有通过校验的属性相关信息

基于方法的校验，个人不推荐使用，感觉和项目结合的不是很好。

## 统一处理验证异常

```
@ControllerAdvice
@Component
public class GlobalExceptionHandler {

    @ExceptionHandler
    @ResponseBody
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public String handle(ValidationException exception) {
        if(exception instanceof ConstraintViolationException){
            ConstraintViolationException exs = (ConstraintViolationException) exception;

            Set<ConstraintViolation<?>> violations = exs.getConstraintViolations();
            for (ConstraintViolation<?> item : violations) {
　　　　　　　　　　/**打印验证不通过的信息*/
                System.out.println(item.getMessage());
            }
        }
        return "bad request, " ;
    }
}
```

> 参考：
> *[https://www.cnkirito.moe/2017/08/16/%E4%BD%BF%E7%94%A8spring%20validation%E5%AE%8C%E6%88%90%E6%95%B0%E6%8D%AE%E5%90%8E%E7%AB%AF%E6%A0%A1%E9%AA%8C/](https://www.cnkirito.moe/2017/08/16/%E4%BD%BF%E7%94%A8spring%20validation%E5%AE%8C%E6%88%90%E6%95%B0%E6%8D%AE%E5%90%8E%E7%AB%AF%E6%A0%A1%E9%AA%8C/)*

# 创建异步方法

## 启动异步

```
@Configuration
@EnableAsync
public class SpringAsyncConfig {
  
}

```

配置完这个就已经具备异步方法功能了，只需要在方法上面添加`@Async`即可

如果被`@Async`注解的方法所在类是基于接口实现的，想要直接注入实现类，需要添加：`@EnableAsync(proxyTargetClass = true)` 以使用CGLIB代理

## 编写异步方法

```
@Async
public void asyncMethodWithVoidReturnType() throws InterruptedException {
	System.out.println("Execute method asynchronously. " + Thread.currentThread().getName());
}

```

## 配置线程池

在不配置线程池的情况下，Spring**默认使用**`SimpleAsyncTaskExecutor`，每一次的执行任务都会使用新的线程，性能不太好，所以我们可以自定义线程池

### 直接声明线程池

```
@Configuration
@EnableAsync
public class SpringAsyncConfig {
	@Bean
	public Executor threadPoolTaskExecutor() {
		ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
		executor.setCorePoolSize(10);
		executor.setMaxPoolSize(20);
		executor.setQueueCapacity(500);
		executor.setKeepAliveSeconds(60);
		executor.setThreadNamePrefix("asyncExecutor-");
		executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
		executor.initialize();
		return executor;
	}
}

```

通过使用`ThreadPoolTaskExecutor`创建了一个线程池，同时设置了以下这些参数：

- 核心线程数10：线程池创建时候初始化的线程数
- 最大线程数20：线程池最大的线程数，只有在缓冲队列满了之后才会申请超过核心线程数的线程
- 缓冲队列500：用来缓冲执行任务的队列
- 允许线程的空闲时间60秒：当超过了核心线程出之外的线程在空闲时间到达之后会被销毁
- 线程池名的前缀：设置好了之后可以方便我们定位处理任务所在的线程池
- 线程池对拒绝任务的处理策略：这里采用了`CallerRunsPolicy`策略，当线程池没有处理能力的时候，该策略会直接在 execute 方法的调用线程中运行被拒绝的任务；如果执行程序已关闭，则会丢弃该任务

### 实现AsyncConfigurer

> 通过这种方式，可以**对异常进行处理**

`AsyncConfigurer`接口有两个方法：

- `getAsyncExecutor()`: 提供线程池
- `getAsyncUncaughtExceptionHandler()`: 异步任务异常处理

```
@Configuration
@EnableAsync
public class SpringAsyncConfig implements AsyncConfigurer {
	@Override
	public Executor getAsyncExecutor() {
		ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
		executor.setCorePoolSize(8);
		executor.setMaxPoolSize(42);
		executor.setQueueCapacity(500);
		executor.setThreadNamePrefix("MyExecutor-");
		executor.initialize();
		return executor;
	}
	
	@Override
	public AsyncUncaughtExceptionHandler getAsyncUncaughtExceptionHandler(){
		return (ex, method, params) -> {
			ExceptionUtils.printRootCauseStackTrace(ex);
			System.out.println("Exception message - " + ex.getMessage());
			System.out.println("Method name - " + method.getName());
			for (Object param : params) {
				System.out.println("Parameter value - " + param);
			}
		};
	}
}

```

### 优雅关闭线程池

有时候，存在关闭程序但还有异步任务在执行的情况，这时候，我们需要优雅地关闭线程池，只需要两个参数：

```
executor.setWaitForTasksToCompleteOnShutdown(true);
executor.setAwaitTerminationSeconds(60);
```

## Async使用指定线程池

如果同时实现了`AsyncConfigurer`以及配置线程池，那么`@Async`默认使用`AsyncConfigurer.getAsyncExecutor`的线程池。

如果需要指定线程池可以这样

```
@Async("threadPoolTaskExecutor")
public void someMethod(){...}

```

## 获取异步执行结果

Service：

```
@Async("threadPoolTaskExecutor")
@Override
public Future<String> asyncMethodWithVoidReturnType() throws InterruptedException {
	Thread.sleep(2000L);
	return AsyncResult.forValue("Execute method asynchronously. " + Thread.currentThread().getName());
}

```

Controller：

```
@GetMapping("/hello")
public Mono<String> syaHello() throws InterruptedException, ExecutionException {
	Future<String> stringFuture = someService.asyncMethodWithVoidReturnType();
	while (!stringFuture.isDone()){
		System.out.println("wait...");
		Thread.sleep(500L);
	}
	System.out.println(stringFuture.get());
	return Mono.just("Hello World");
}

```

执行结果：

```
wait...
wait...
wait...
wait...
wait...
Execute method asynchronously. asyncExecutor-1

```

# Spring定时任务

启用：

```
@Configuration
@EnableScheduling
public class SpringScheduleConfig implements SchedulingConfigurer {

	@Override
	public void configureTasks(ScheduledTaskRegistrar taskRegistrar) {
		taskRegistrar.setScheduler(taskExecutor());
	}
	
	@Bean
	public Executor taskExecutor() {
		return new ScheduledThreadPoolExecutor(4,
				new BasicThreadFactory
						.Builder()
						.namingPattern("schedule-pool-thread-%d")
						.daemon(true)
						.build());
	}
}

```

定时任务：

```
	private int i = 0;

	@Scheduled(fixedDelay=1000)
	public void doScheduled() {
		System.out.println(Thread.currentThread().getName() + "  " + ++i);
	}

```

结果：

```
schedule-pool-thread-1  2
schedule-pool-thread-2  3
schedule-pool-thread-1  4
schedule-pool-thread-3  5
schedule-pool-thread-2  6

```

# Spring启动后执行程序的几种方式

## @PostConstruct 或 InitializingBean

通过`@PostConstruct`或实现`InitializingBean`实现初始化`bean`的时候干一些事情，两者区别在于`InitializingBean`是在属性设置完之后执行的，所以执行顺序是在`@PostConstruct`之前

> 由于此接口的方法`afterPropertiesSet`是在对象的所有属性被初始化后才会调用。当Spring的配置文件中设置类初始默认为”延迟初始”（`default-lazy-init="true"`，此值默认为`false`）时，
>
> 类对象如果不被使用，则不会实例化该类对象。所以 `InitializingBean`子类不能用于在容器启动时进行初始化的工作，则应使用Spring提供的`ApplicationListener`接口来进行程序的初始化工作。
>
> 另外，如果需要`InitializingBean`子类对象在Spring容器启动时就初始化并则容器调用`afterPropertiesSet`方法则需要在类上增加`org.springframework.context.annotation.Lazy`注解并设置为false即可（也可通过spring配置bean时添加`lazy-init="false"`)。

## 监听ContextRefreshedEvent

通过监听`ContextRefreshedEvent`事件：

```
public class ApplicationContextRefreshedEventListener implements ApplicationListener<ContextRefreshedEvent> {
	@Override
	public void onApplicationEvent(ContextRefreshedEvent event) {
		System.out.println("ContextRefreshedEvent process...");
	}
}

或者
@EventListener
public void processContextRefreshedEvent(ContextRefreshedEvent event) throws InterruptedException {
	log.info("ContextRefreshedEvent process...");
}

```

Spring的事件处理是单线程的，所以如果一个事件被触发，除非所有的接收者得到消息，否则这些进程被阻止，流程将不会继续。因此，如果要使用事件处理，在设计应用程序时应小心。

### Spring内置事件

以下是Spring的内置事件

| Spring 内置事件           | 描述                                                         |
| ------------------------- | ------------------------------------------------------------ |
| **ContextRefreshedEvent** | `ApplicationContext`被初始化或刷新时，该事件被发布。这也可以在`ConfigurableApplicationContext`接口中使用`refresh()`方法来发生。 |
| **ContextStartedEvent**   | 当使用`ConfigurableApplicationContext`接口中的`start()`方法启动`ApplicationContext`时，该事件被触发。你可以查询你的数据库，或者你可以在接受到这个事件后重启任何停止的应用程序。 |
| **ContextStoppedEvent**   | 当使用`ConfigurableApplicationContext`接口中的`stop()`方法停止`ApplicationContext`时，该事件被触发。你可以在接受到这个事件后做必要的清理的工作。 |
| **ContextClosedEvent**    | 当使用`ConfigurableApplicationContext`接口中的`close()`方法关闭`ApplicationContext`时，该事件被触发。一个已关闭的上下文到达生命周期末端；它不能被刷新或重启。 |
| **RequestHandledEvent**   | 这是一个`web-specific`事件，告诉所有`bean` HTTP请求已经被服务。 |

### Spring Boot 2.0新增事件

在Spring Boot 2.0中对事件模型做了一些增强，主要就是增加了`ApplicationStartedEvent`事件，所以在2.0版本中所有的事件按执行的先后顺序如下：

- `ApplicationStartingEvent`
- `ApplicationEnvironmentPreparedEvent`
- `ApplicationPreparedEvent`
- `ApplicationStartedEvent` <= 新增的事件
- `ApplicationReadyEvent`
- `ApplicationFailedEvent`

## ApplicationRunner 或 CommandLineRunner

实现`ApplicationRunner`或`CommandLineRunner`

```
@SpringBootApplication
public class ProdSyncLayerApplication implements ApplicationRunner,CommandLineRunner{

	public static void main(String[] args) {
		SpringApplication.run(ProdSyncLayerApplication.class, args);
	}

	@Override
	public void run(ApplicationArguments args) throws Exception {
		System.out.println("ApplicationRunner...");
	}

	@Override
	public void run(String... args) throws Exception {
		System.out.println("CommandLineRunner...");
	}
}

```

`ApplicationRunner`比`CommandLineRunner`先执行

**总结**：以上三种方式的顺序跟其序号一样

## onApplicationEvent执行两次问题

`applicationontext`和使用MVC之后的`webApplicationontext`会两次调用上面的方法，如何区分这个两种容器呢？

但是这个时候，会存在一个问题，在web 项目中（spring mvc），系统会存在两个容器，一个是`root application context` ,另一个就是我们自己的 `projectName-servlet context`（作为root application context的子容器）。

这种情况下，就会造成`onApplicationEvent`方法被执行两次。为了避免上面提到的问题，我们可以只在`root application context`初始化完成后调用逻辑代码，其他的容器的初始化完成，则不做任何处理，修改后代码 

```
      @Override  
      public void onApplicationEvent(ContextRefreshedEvent event) {  
        if(event.getApplicationContext().getParent() == null){//root application context 没有parent，他就是老大.  
             //需要执行的逻辑代码，当spring容器初始化完成后就会执行该方法。  
        }  
      }  

```

> 后续发现加上以上判断还是能执行两次，不加的话三次，最终研究结果使用以下判断更加准确：`event.getApplicationContext().getDisplayName().equals("Root WebApplicationContext")`

# Spring应用停止前执行程序的几种方式

1. 监听`ContextClosedEvent`

2. 实现`DisposableBean`或使用`@PostConstruct`，执行顺序：`@PostConstruct` > `DisposableBean`

3. 使用ShutdownHook:

   ```
   public class ShutdownHook {

       public static void main(String[] args) throws InterruptedException {
           Runtime.getRuntime().addShutdownHook(new Thread(() -> {
               try (FileWriter fw = new FileWriter("hook.log")) {
                   // 假设记录日志/或者发送消息
                   fw.write("完成销毁操作,回收内存! " + (new Date()).toString());
                   System.out.println("退出程序...");
               } catch (IOException e) {
                   e.printStackTrace();
               }
           }));
           IntStream.range(0, 10).forEach(i -> {
               try {
                   System.out.println("正在工作...");
                   Thread.sleep(2000L);
               } catch (InterruptedException e) {
                   e.printStackTrace();
               }
           });
       }
   }

   ```

# 元注解与组合注解

## 元注解

Spring4.0的许多注解都可以用作meta annotation（元注解）。元注解是一种使用在别的注解上的注解。这意味着我们可以使用Spring的注解组合成一个我们自己的注解。

类似于：`@Documented`, `@Component`, `@RequestMapping`, `@Controller`, `@ResponseBody`等等

对于元注解，是Spring框架中定义的部分，都有特定的含义。我们并不能修改，但是对于组合注解，我们完全可以基于自己的定义进行实现。

## 组合注解

自定义注解或组合注解是从其他的Spring元注解创建的，我们先看一下`@SpringBootApplication`这个神奇的注解（去除注释）：

```
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan(excludeFilters = {
		@Filter(type = FilterType.CUSTOM, classes = TypeExcludeFilter.class),
		@Filter(type = FilterType.CUSTOM, classes = AutoConfigurationExcludeFilter.class) })
public @interface SpringBootApplication {

	@AliasFor(annotation = EnableAutoConfiguration.class)
	Class<?>[] exclude() default {};

	@AliasFor(annotation = EnableAutoConfiguration.class)
	String[] excludeName() default {};

	@AliasFor(annotation = ComponentScan.class, attribute = "basePackages")
	String[] scanBasePackages() default {};

	@AliasFor(annotation = ComponentScan.class, attribute = "basePackageClasses")
	Class<?>[] scanBasePackageClasses() default {};

}
```

发现这个注解中有含有大量其他注解，并使用了`@AliasFor`这个注解传递注解属性值。

## 自定义组合注解

```
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@RestController
@RequestMapping(produces = MediaType.APPLICATION_JSON_UTF8_VALUE)
public @interface Rest {
	@AliasFor(annotation = RequestMapping.class, attribute = "value")
	String[] value() default {};
}
```

使用：

```
@Rest("/ex")
public class ExampleController {

}
```

# Spring AOP

> AOP为**Aspect Oriented Programming**的缩写，意为：面向切面编程，通过预编译方式和运行期动态代理实现程序功能的统一维护的一种技术。AOP是Spring框架中的一个重要内容，它通过对既有程序定义一个切入点，然后在其前后切入不同的执行内容，比如常见的有：打开数据库连接/关闭数据库连接、打开事务/关闭事务、记录日志等。基于AOP不会破坏原来程序逻辑，因此它可以很好的对业务逻辑的各个部分进行**隔离**，从而使得业务逻辑各部分之间的**耦合度降低**，提高程序的可重用性，同时提高了开发的效率。

## 注解说明

实现AOP的切面主要有以下几个要素：

- 使用`@Aspect`注解将一个java类定义为切面类
- 使用`@Pointcut`定义一个切入点，可以是一个规则表达式，比如下例中某个package下的所有函数，也可以是一个注解等。
- 根据需要在切入点不同位置的切入内容
  - 使用`@Before`在切入点开始处切入内容
  - 使用`@After`在切入点结尾处切入内容
  - 使用`@AfterReturning`在切入点return内容之后切入内容（可以用来对处理返回值做一些加工处理）
  - 使用`@Around`在切入点前后切入内容，并自己控制何时执行切入点自身的内容
  - 使用`@AfterThrowing`用来处理当切入内容部分抛出异常之后的处理逻辑

## 引入依赖

与其他模块一样，使用需要引入pom依赖：

```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
</dependency>
```

**引入依赖程序将自动启用AOP**，只要引入了AOP依赖后，默认已经增加了`@EnableAspectJAutoProxy`，并且默认启用**Cglib**代理：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/spring-boot-cglib-default.png)

## AOP顺序

由于通过AOP实现，程序得到了很好的解耦，但是也会带来一些问题，比如：我们可能会对Web层做多个切面，校验用户，校验头信息等等，这个时候经常会碰到切面的处理**顺序问题**。

所以，我们需要定义每个切面的优先级，我们需要`@Order(i)`注解来标识切面的优先级。**i的值越小，优先级越高**。

## AOP记录Web访问日志用例

### 日志注解

```
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
public @interface ReqLog {
	String value() default "";
}
```

别忘了加上`@Retention(RetentionPolicy.RUNTIME)`

### 声明Pointcut

```
@Pointcut("execution(public * com.yangbingdong.docker.controller..*.*(..))")
public void path() {}

@Pointcut("@annotation(ReqLog)")
public void annotation() {}

@Pointcut("path() && annotation()")
public void logHttp() {}
```

然后这样使用：

```
@Before("path() && @annotation(reqLog)")
public void before(JoinPoint joinPoint) {
    ...
}
```

如果要很方便地获取`@ReqLog`的`value`，我们可以将其**绑定**为参数：

```
@Pointcut("execution(public * com.yangbingdong.docker.controller..*.*(..))")
public void path(){}

@Before("path() && @annotation(reqLog)")
public void doBefore(JoinPoint joinPoint, ReqLog reqLog) {
    ...
}
```

Pointcut匹配表达式详解可以参考：***[https://blog.csdn.net/elim168/article/details/78150438](https://blog.csdn.net/elim168/article/details/78150438)***

如果是使用`@Around`，则方法参数应该使用`ProceedingJoinPoint，`因为`ProceedingJoinPoint.proceed()`可获取方法返回值，且必须返回`Object`：

```
@Around("logHttp()")
public Object around(final ProceedingJoinPoint joinPoint) throws Throwable {
    ...
}
```



# 自动配置的原理与自定义starter

在自定义starter之前，先看一下Spring Boot的一些原理

## Spring Boot实现自动配置的原理

### 入口注解类@EnableAutoConfiguration

`@SpringBootApplication`注解中包含了自动配置的入口注解：

```
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan(excludeFilters = {
        @Filter(type = FilterType.CUSTOM, classes = TypeExcludeFilter.class),
        @Filter(type = FilterType.CUSTOM, classes = AutoConfigurationExcludeFilter.class) })
public @interface SpringBootApplication {
  // ...
}
```

```
@SuppressWarnings("deprecation")
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@AutoConfigurationPackage
@Import(EnableAutoConfigurationImportSelector.class)
public @interface EnableAutoConfiguration {
  // ...
}
```

这个注解的Javadoc内容还是不少，所有就不贴在文章里面了，概括一下：

1. 自动配置基于应用的类路径以及你定义了什么Beans
2. 如果使用了`@SpringBootApplication`注解，那么自动就启用了自动配置
3. 可以通过设置注解的`excludeName`属性或者通过`spring.autoconfigure.exclude`配置项来指定不需要自动配置的项目
4. 自动配置的发生时机在用户定义的Beans被注册之后
5. 如果没有和`@SpringBootApplication`一同使用，最好将`@EnableAutoConfiguration`注解放在root package的类上，这样就能够搜索到所有子packages中的类了
6. 自动配置类就是普通的Spring `@Configuration`类，通过`SpringFactoriesLoader`机制完成加载，实现上通常使用`@Conditional`(比如`@ConditionalOnClass`或者`@ConditionalOnMissingBean`)

### @AutoConfigurationPackage

```
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@Import(AutoConfigurationPackages.Registrar.class)
public @interface AutoConfigurationPackage {

}
```

这个注解的职责就是**引入**了另外一个配置类：`AutoConfigurationPackages.Registrar`。

```
/**
 * ImportBeanDefinitionRegistrar用来从导入的Config中保存base package
 */
@Order(Ordered.HIGHEST_PRECEDENCE)
static class Registrar implements ImportBeanDefinitionRegistrar, DeterminableImports {

    @Override
    public void registerBeanDefinitions(AnnotationMetadata metadata,
            BeanDefinitionRegistry registry) {
        register(registry, new PackageImport(metadata).getPackageName());
    }

    @Override
    public Set<Object> determineImports(AnnotationMetadata metadata) {
        return Collections.<Object>singleton(new PackageImport(metadata));
    }

}
```

这个注解实现的功能已经比较底层了，调试看看上面的register方法什么会被调用：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/spring-boot-code.png)

调用参数中的`packageNames`数组中仅包含一个值：`com.example.demo`，也就是项目的root package名。

从调用栈来看的话，调用`register`方法的时间在容器刷新期间：

`refresh` -> `invokeBeanFactoryPostProcessors` -> `invokeBeanDefinitionRegistryPostProcessors` -> `postProcessBeanDefinitionRegistry` -> `processConfigBeanDefinitions`(开始处理配置Bean的定义) -> `loadBeanDefinitions` -> `loadBeanDefinitionsForConfigurationClass`(读取配置Class中的Bean定义) -> `loadBeanDefinitionsFromRegistrars`(这里开始准备进入上面的register方法) -> `registerBeanDefinitions`(即上述方法)

这个过程已经比较复杂了，目前暂且不深入研究了。它的功能简单说就是将应用的root package给注册到Spring容器中，供后续使用。

相比而言，下面要讨论的几个类型才是实现自动配置的关键。

### @Import(EnableAutoConfigurationImportSelector.class)

`@EnableAutoConfiguration`注解的另外一个作用就是引入了`EnableAutoConfigurationImportSelector`：

它的类图如下所示：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/spring-boot-code02.png)

可以发现它除了实现几个Aware类接口外，最关键的就是实现了`DeferredImportSelector`(继承自`ImportSelector`)接口。

所以我们先来看看`ImportSelector`以及`DeferredImportSelector`接口的定义：

```
public interface ImportSelector {

    /**
     * 基于被引入的Configuration类的AnnotationMetadata信息选择并返回需要引入的类名列表
     */
    String[] selectImports(AnnotationMetadata importingClassMetadata);

}
```

这个接口的Javadoc比较长，还是捡重点说明一下：

1. 主要功能通过`selectImports`方法实现，用于筛选需要引入的类名
2. 实现了`ImportSelector`的类也可以实现一系列Aware接口，这些Aware接口中的相应方法会在`selectImports`方法之前被调用(这一点通过上面的类图也可以佐证，`EnableAutoConfigurationImportSelector`确实实现了四个Aware类型的接口)
3. `ImportSelector`的实现和通常的`@Import`在处理方式上是一致的，然而还是可以在所有`@Configuration`类都被处理后再进行引入筛选(具体看下面即将介绍的`DeferredImportSelector`)

```
public interface DeferredImportSelector extends ImportSelector {

}
```

这个接口是一个**标记接口**，它本身没有定义任何方法。那么这个接口的含义是什么呢：

1. 它是`ImportSelector`接口的一个变体，在所有的`@Configuration`被处理之后才会执行。在需要筛选的引入类型具备`@Conditional`注解的时候非常有用
2. 实现类同样也可以实现`Ordered`接口，来定义多个`DeferredImportSelector`的优先级别(同样地，`EnableAutoConfigurationImportSelector`也实现了`Ordered`接口)

明确了这两个接口的意义，下面来看看是如何实现的：

```
@Override
public String[] selectImports(AnnotationMetadata annotationMetadata) {
    if (!isEnabled(annotationMetadata)) {
        return NO_IMPORTS;
    }
    try {
      // Step1: 得到注解信息
        AutoConfigurationMetadata autoConfigurationMetadata = AutoConfigurationMetadataLoader
                .loadMetadata(this.beanClassLoader);
        // Step2: 得到注解中的所有属性信息
        AnnotationAttributes attributes = getAttributes(annotationMetadata);
        // Step3: 得到候选配置列表
        List<String> configurations = getCandidateConfigurations(annotationMetadata,
                attributes);
        // Step4: 去重
        configurations = removeDuplicates(configurations);
        // Step5: 排序
        configurations = sort(configurations, autoConfigurationMetadata);
        // Step6: 根据注解中的exclude信息去除不需要的
        Set<String> exclusions = getExclusions(annotationMetadata, attributes);
        checkExcludedClasses(configurations, exclusions);
        configurations.removeAll(exclusions);
        configurations = filter(configurations, autoConfigurationMetadata);
        // Step7: 派发事件
        fireAutoConfigurationImportEvents(configurations, exclusions);
        return configurations.toArray(new String[configurations.size()]);
    }
    catch (IOException ex) {
        throw new IllegalStateException(ex);
    }
}
```

很明显，核心就在于上面的**步骤3**：

```
protected List<String> getCandidateConfigurations(AnnotationMetadata metadata,
        AnnotationAttributes attributes) {
    List<String> configurations = SpringFactoriesLoader.loadFactoryNames(
            getSpringFactoriesLoaderFactoryClass(), getBeanClassLoader());
    Assert.notEmpty(configurations,
            "No auto configuration classes found in META-INF/spring.factories. If you "
                    + "are using a custom packaging, make sure that file is correct.");
    return configurations;
}
```

它将实现委托给了`SpringFactoriesLoader`的`loadFactoryNames`方法：

```
// 传入的factoryClass：org.springframework.boot.autoconfigure.EnableAutoConfiguration
public static List<String> loadFactoryNames(Class<?> factoryClass, ClassLoader classLoader) {
    String factoryClassName = factoryClass.getName();
    try {
        Enumeration<URL> urls = (classLoader != null ? classLoader.getResources(FACTORIES_RESOURCE_LOCATION) :
                ClassLoader.getSystemResources(FACTORIES_RESOURCE_LOCATION));
        List<String> result = new ArrayList<String>();
        while (urls.hasMoreElements()) {
            URL url = urls.nextElement();
            Properties properties = PropertiesLoaderUtils.loadProperties(new UrlResource(url));
            String factoryClassNames = properties.getProperty(factoryClassName);
            result.addAll(Arrays.asList(StringUtils.commaDelimitedListToStringArray(factoryClassNames)));
        }
        return result;
    }
    catch (IOException ex) {
        throw new IllegalArgumentException("Unable to load [" + factoryClass.getName() +
                "] factories from location [" + FACTORIES_RESOURCE_LOCATION + "]", ex);
    }
}

// 相关常量
public static final String FACTORIES_RESOURCE_LOCATION = "META-INF/spring.factories";
```

这段代码的意图很明确，在第一篇文章讨论Spring Boot启动过程的时候就已经接触到了。它会从类路径中拿到所有名为**`META-INF/spring.factories`**的配置文件，然后按照`factoryClass`的名称取到对应的值。那么我们就来找一个**`META-INF/spring.factories`**配置文件看看。

#### META-INF/spring.factories

比如`spring-boot-autoconfigure`包：

```
# Auto Configure
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.springframework.boot.autoconfigure.admin.SpringApplicationAdminJmxAutoConfiguration,\
org.springframework.boot.autoconfigure.aop.AopAutoConfiguration,\
org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration,\
org.springframework.boot.autoconfigure.batch.BatchAutoConfiguration,\
org.springframework.boot.autoconfigure.cache.CacheAutoConfiguration,\
org.springframework.boot.autoconfigure.cassandra.CassandraAutoConfiguration,\
org.springframework.boot.autoconfigure.cloud.CloudAutoConfiguration,\
# ...
```

列举了非常多的自动配置候选项，挑一个AOP相关的`AopAutoConfiguration`看看究竟：

```
// 如果设置了spring.aop.auto=false，那么AOP不会被配置
// 需要检测到@EnableAspectJAutoProxy注解存在才会生效
// 默认使用JdkDynamicAutoProxyConfiguration，如果设置了spring.aop.proxy-target-class=true，那么使用CglibAutoProxyConfiguration
@Configuration
@ConditionalOnClass({ EnableAspectJAutoProxy.class, Aspect.class, Advice.class })
@ConditionalOnProperty(prefix = "spring.aop", name = "auto", havingValue = "true", matchIfMissing = true)
public class AopAutoConfiguration {

    @Configuration
    @EnableAspectJAutoProxy(proxyTargetClass = false)
    @ConditionalOnProperty(prefix = "spring.aop", name = "proxy-target-class", havingValue = "false", matchIfMissing = true)
    public static class JdkDynamicAutoProxyConfiguration {

    }

    @Configuration
    @EnableAspectJAutoProxy(proxyTargetClass = true)
    @ConditionalOnProperty(prefix = "spring.aop", name = "proxy-target-class", havingValue = "true", matchIfMissing = false)
    public static class CglibAutoProxyConfiguration {

    }

}
```

这个自动配置类的作用是判断是否存在配置项：

```
spring.aop.proxy-target-class=true
```

如果存在并且值为`true`的话使用基于**CGLIB**字节码操作的动态代理方案，否则使用JDK自带的动态代理机制。

下面列举所有由Spring Boot提供的条件注解：

- `@ConditionalOnBean`
- `@ConditionalOnClass`
- `@ConditionalOnCloudPlatform`
- `@ConditionalOnExpression`
- `@ConditionalOnJava`
- `@ConditionalOnJndi`
- `@ConditionalOnMissingBean`
- `@ConditionalOnMissingClass`
- `@ConditionalOnNotWebApplication`
- `@ConditionalOnProperty`
- `@ConditionalOnResource`
- `@ConditionalOnSingleCandidate`
- `@ConditionalOnWebApplication`

一般的模式，就是一个条件注解对应一个继承自`SpringBootCondition`的具体实现类。

> 以上来自：***[https://blog.csdn.net/dm_vincent/article/details/77619752](https://blog.csdn.net/dm_vincent/article/details/77619752)***

## 自定义starter

看完上面描述之后，应该不难发现，自定义starter的关键就是**`META-INF/spring.factories`**了，Spring Boot会在启动时加载这个文件中声明的第三方类。

### 自定义properties

为了给可配置的bean属性生成元数据，我们需要引入如下jar包：

```
<!-- 将被@ConfigurationProperties注解的类的属性注入到元数据 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-configuration-processor</artifactId>
    <optional>true</optional>
</dependency>
```

`application.properties`:

```
ybd.datasource.driver-class-name=com.mysql.jdbc.Driver
ybd.datasource.url=jdbc:mysql://192.168.0.200:3306/transaction_message_test?useUnicode=true&characterEncoding=utf8&useSSL=false
ybd.datasource.username=ibalife
ybd.datasource.password=ibalife
ybd.datasource.dbcp2.validation-query=select 'x'
```

> 生成的元数据位于jar文件中的`META-INF/spring-configurationmetadata. json`。元数据本身并不会修改被`@ConfigurationProperties`修饰的类属性，在我的理解里元数据仅仅只是表示配置类的默认值以及java doc，供调用者便利的了解默认配置有哪些以及默认配置的含义，在idea里面如果有元数据则可以提供良好的代码提示功能以方便了解默认的配置。

### properties接收类

```
@Data
@ConfigurationProperties(DataSourceProperties.DATASOURCE_PREFIX)
public class DataSourceProperties {
	public static final String DATASOURCE_PREFIX = "ybd.datasource";
	private Boolean tcc;
	private String driverClassName = "com.mysql.jdbc.Driver";
	private String url;
	private String username = "root";
	private String password = "root";
	private Dbcp2 dbcp2;

	@Data
	public static class Dbcp2 {
		private Integer maxTotal = 50;
		private Integer initialSize = 20;
		private Long maxWaitMillis = 60000L;
		private Integer minIdle = 6;
		private Boolean logAbandoned = true;
		private Boolean removeAbandonedOnBorrow = true;
		private Boolean removeAbandonedOnMaintenance = true;
		private Integer removeAbandonedTimeout = 1800;
		private Boolean testWhileIdle = true;
		private Boolean testOnBorrow = false;
		private Boolean testOnReturn = false;
		private String validationQuery;
		private Integer validationQueryTimeout = 1;
		private Long timeBetweenEvictionRunsMillis = 30000L;
		private Integer numTestsPerEvictionRun = 20;
	}
}
```

`@ConfigurationProperties`会将`application.properties`中指定的前缀的属性注入到bean中

### Config类

```
@Configuration
@Import(SpringCloudConfiguration.class)
@ConditionalOnClass({LocalXADataSource.class})
@EnableConfigurationProperties({DataSourceProperties.class})
public class DataSourceConfiguration {
	private final DataSourceProperties dataSourceProperties;

	@Autowired
	public DataSourceConfiguration(DataSourceProperties dataSourceProperties) {
		this.dataSourceProperties = dataSourceProperties;
	}


	@Bean("dataSource")
	@ConditionalOnProperty(prefix = DATASOURCE_PREFIX, value = "tcc", havingValue = "true", matchIfMissing = true)
	public DataSource getTccDataSource() {
		LocalXADataSource dataSource = new LocalXADataSource();
		dataSource.setDataSource(this.resolveDbcp2DataSource());
		return dataSource;
	}

	private DataSource resolveDbcp2DataSource() {
		BasicDataSource dataSource = new BasicDataSource();
		dataSource.setDriverClassName(dataSourceProperties.getDriverClassName());
		dataSource.setUrl(dataSourceProperties.getUrl());
		dataSource.setUsername(dataSourceProperties.getUsername());
		dataSource.setPassword(dataSourceProperties.getPassword());
		dataSource.setMaxTotal(dataSourceProperties.getDbcp2().getMaxTotal());
		dataSource.setInitialSize(dataSourceProperties.getDbcp2().getInitialSize());
		dataSource.setMaxWaitMillis(dataSourceProperties.getDbcp2().getMaxWaitMillis());
		dataSource.setMinIdle(dataSourceProperties.getDbcp2().getMinIdle());
		dataSource.setLogAbandoned(dataSourceProperties.getDbcp2().getLogAbandoned());
		dataSource.setRemoveAbandonedOnBorrow(dataSourceProperties.getDbcp2().getRemoveAbandonedOnBorrow());
		dataSource.setRemoveAbandonedOnMaintenance(dataSourceProperties.getDbcp2().getRemoveAbandonedOnMaintenance());
		dataSource.setRemoveAbandonedTimeout(dataSourceProperties.getDbcp2().getRemoveAbandonedTimeout());
		dataSource.setTestWhileIdle(dataSourceProperties.getDbcp2().getTestWhileIdle());
		dataSource.setTestOnBorrow(dataSourceProperties.getDbcp2().getTestOnBorrow());
		dataSource.setTestOnReturn(dataSourceProperties.getDbcp2().getTestOnReturn());
		dataSource.setValidationQuery(dataSourceProperties.getDbcp2().getValidationQuery());
		dataSource.setValidationQueryTimeout(dataSourceProperties.getDbcp2().getValidationQueryTimeout());
		dataSource.setTimeBetweenEvictionRunsMillis(dataSourceProperties.getDbcp2().getTimeBetweenEvictionRunsMillis());
		dataSource.setNumTestsPerEvictionRun(dataSourceProperties.getDbcp2().getNumTestsPerEvictionRun());
		return dataSource;
	}
}
```

* `@Import`引入其他配置类
* `@ConditionalOnClass`在指定类存在时该配置类生效
* `@EnableConfigurationProperties`启用配置接受类，通过Spring字段注入或构造器注入properties配置Bean

### 使Spring Boot可以自动加载配置类

在`/resource`目录创建**`META-INF/spring.factories`**：

```
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
com.yangbingdong.configuration.WebMvcMessageConvertConfiguration
```

然后打包成Jar，第三方Spring Boot系统通过引入这个Jar包，会自动加载该类。

如果有需要，可以配合`@AutoConfigureAfter`，`@ConditionalOnBean`，`@ConditionalOnProperty`等注解控制配置是否需要加载以及加载顺序。

需要更灵活的配置可以实现`Condition`或`SpringBootCondition`通过`@Conditional(XXXCondition.class)`实现类加载判断。

# 优雅停机

可参考：***[http://www.spring4all.com/article/1022](http://www.spring4all.com/article/1022)***

```
package com.yangbingdong.docker.config.shutdown;

import io.undertow.server.HandlerWrapper;
import io.undertow.server.HttpHandler;
import io.undertow.server.handlers.GracefulShutdownHandler;

/**
 * @author ybd
 * @date 18-4-19
 * @contact yangbingdong1994@gmail.com
 */
public class GracefulShutdownWrapper implements HandlerWrapper {
	private GracefulShutdownHandler gracefulShutdownHandler;

	@Override
	public HttpHandler wrap(HttpHandler handler) {
		if(gracefulShutdownHandler == null) {
			this.gracefulShutdownHandler = new GracefulShutdownHandler(handler);
		}
		return gracefulShutdownHandler;
	}

	public GracefulShutdownHandler getGracefulShutdownHandler() {
		return gracefulShutdownHandler;
	}
}
```

```
package com.yangbingdong.docker.config.shutdown;

import io.undertow.server.handlers.GracefulShutdownHandler;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextClosedEvent;

/**
 * @author ybd
 * @date 18-4-19
 * @contact yangbingdong1994@gmail.com
 */
@RequiredArgsConstructor
@Slf4j
public class GracefulShutdownListener implements ApplicationListener<ContextClosedEvent> {

	private final GracefulShutdownWrapper gracefulShutdownWrapper;

	@Override
	public void onApplicationEvent(ContextClosedEvent event) {
		GracefulShutdownHandler gracefulShutdownHandler = gracefulShutdownWrapper.getGracefulShutdownHandler();
		try {
			gracefulShutdownHandler.shutdown();
			gracefulShutdownHandler.awaitShutdown(5000L);
		} catch (InterruptedException e) {
			log.error("Graceful shutdown container error:", e);
		}
	}
}

```

```
package com.yangbingdong.springboot.common.config.shutdown;

import io.undertow.server.HandlerWrapper;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.web.embedded.undertow.UndertowServletWebServerFactory;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.boot.web.servlet.server.ConfigurableServletWebServerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * @author ybd
 * @date 18-4-19
 * @contact yangbingdong1994@gmail.com
 */
@Configuration
@ConditionalOnClass(HandlerWrapper.class)
public class GracefulShutdownConfiguration {

	@Bean
	public GracefulShutdownWrapper gracefulShutdownWrapper() {
		return new GracefulShutdownWrapper();
	}

	@Bean
	public WebServerFactoryCustomizer<ConfigurableServletWebServerFactory> gracefulWebServerFactoryCustomizer() {
		return factory -> {
			if (factory instanceof UndertowServletWebServerFactory) {
				UndertowServletWebServerFactory undertowServletWebServerFactory = (UndertowServletWebServerFactory) factory;
				undertowServletWebServerFactory
						.addDeploymentInfoCustomizers(deploymentInfo ->
								deploymentInfo.addOuterHandlerChainWrapper(gracefulShutdownWrapper()));
//				undertowServletWebServerFactory.addBuilderCustomizers(builder -> builder.setServerOption(UndertowOptions.ENABLE_STATISTICS, true));
			}
		};
	}

	@Bean
	public GracefulShutdownListener gracefulShutdown() {
		return new GracefulShutdownListener(gracefulShutdownWrapper());
	}
}
```

