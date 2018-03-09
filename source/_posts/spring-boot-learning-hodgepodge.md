---
title: Spring Boot 学习杂记
date: 2018-02-25 15:25:35
categories: [Programming, Java, Spring Boot]
tags: [Java, Spring, Spring Boot]
---

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/spring-boot.png)

> Spring Boot作为当下最流行的微服务项目构建基础，有的时候我们根本不需要额外的配置就能够干很多的事情，这得益于它的一个核心理念：“习惯优于配置”。。。
>
> 说白的就是大部分的配置都已经按照最佳实践的编程规范配置好了
>
> 本文基于 Spring Boot 2的学习杂记，还是与1.X版本还是有一定区别的

<!--more-->

# 构建依赖版本管理工程以及父工程

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

# 打包成可执行的Jar

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

# 使用Log4j2

下面是 Log4j2  官方性能测试结果：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/log4j2-performance.png)

## Maven配置

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

## application.yml简单配置

```
logging:
  config: classpath:log4j2.xml # 指定log4j2配置文件的路径，默认就是这个
  pattern:
    console: "%clr{%d{yyyy-MM-dd HH:mm:ss.SSS}}{faint} | %clr{%5p} | %clr{%15.15t}{faint} | %clr{%-50.50c{1.}}{cyan} | %5L | %clr{%M}{magenta} | %msg%n%xwEx" # 控制台日志输出格式
```

## log4j2.xml配置

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

## 也可以使用log4j2.yml

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

# 查看依赖树

如果引入了某些jar包带有`logback`依赖，log4j2会失效，需要通过IDEA或Maven查找排除依赖：

```
mvn dependency:tree
```

# 常用连接池配置

> Spring Boot 2 默认使用 [*HikariCP*](https://github.com/brettwooldridge/HikariCP) 作为连接池

如果项目中已包含`spring-boot-starter-jdbc`或`spring-boot-starter-jpa`模块，那么连接池将**自动激活**！

在Spring Boot2中选择数据库链接池实现的判断逻辑：

1. 检查HikariCP是否可用，如可用，则启用。使用`spring.datasource.hikari.*`可以控制链接池的行为。
2. 检查Tomcat的数据库链接池实现是否可用，如可用，则启用。使用`spring.datasource.tomcat.*`可以控制链接池的行为。
3. 检查Commons DBCP2是否可用，如可用，则启用。使用`spring.datasource.dbcp2.*`可以控制链接池的行为。

## HikariCP 连接池常用属性

| 属性                  | 描述                                       | 默认值                  |
| ------------------- | ---------------------------------------- | -------------------- |
| dataSourceClassName | JDBC 驱动程序提供的 DataSource 类的名称，如果使用了jdbcUrl则不需要此属性 | -                    |
| jdbcUrl             | 数据库连接地址                                  | -                    |
| username            | 数据库账户，如果使用了jdbcUrl则需要此属性                 | -                    |
| password            | 数据库密码，如果使用了jdbcUrl则需要此属性                 | -                    |
| autoCommit          | 是否自动提交事务                                 | true                 |
| connectionTimeout   | 连接超时时间（毫秒），如果在没有连接可用的情况下等待超过此时间，则抛出 SQLException | 30000（30秒）           |
| idleTimeout         | 空闲超时时间（毫秒），只有在minimumIdle<maximumPoolSize时生效，超时的连接可能被回收，数值 0 表示空闲连接永不从池中删除 | 600000（10分钟）         |
| maxLifetime         | 连接池中的连接的最长生命周期（毫秒）。数值 0 表示不限制            | 1800000（30分钟）        |
| connectionTestQuery | 连接池每分配一条连接前执行的查询语句（如：SELECT 1），以验证该连接是否是有效的。如果你的驱动程序支持 JDBC4，HikariCP 强烈建议我们不要设置此属性 | -                    |
| minimumIdle         | 最小空闲连接数，HikariCP 建议我们不要设置此值，而是充当固定大小的连接池 | 与maximumPoolSize数值相同 |
| maximumPoolSize     | 连接池中可同时连接的最大连接数，当池中没有空闲连接可用时，就会阻塞直到超出connectionTimeout设定的数值，推荐的公式：((core_count * 2) + effective_spindle_count) | 10                   |
| poolName            | 连接池名称，主要用于显示在日志记录和 JMX 管理控制台中            | auto-generated       |

`application.yml`

```
spring:
  datasource:
      url: jdbc:mysql://127.0.0.1/spring_boot_testing_storage
      username: root
      password: root
      driver-class-name: com.mysql.jdbc.Driver
#     type: com.zaxxer.hikari.HikariDataSource #Spring Boot2.0默认使用HikariDataSource
      hikari:
        auto-commit: false
        maximum-pool-size: 9 #连接池中允许的最大连接数。缺省值：10；推荐的公式：((core_count * 2) + effective_spindle_count)
```

## Tomcat连接池常用的属性

| 属性                            | 描述                                       | 默认值                |
| ----------------------------- | ---------------------------------------- | ------------------ |
| defaultAutoCommit             | 连接池中创建的连接默认是否自动提交事务                      | 驱动的缺省值             |
| defaultReadOnly               | 连接池中创建的连接默认是否为只读状态                       | -                  |
| defaultCatalog                | 连接池中创建的连接默认的 catalog                     | -                  |
| driverClassName               | 驱动类的名称                                   | -                  |
| username                      | 数据库账户                                    | -                  |
| password                      | 数据库密码                                    | -                  |
| maxActive                     | 连接池同一时间可分配的最大活跃连接数                       | 100                |
| maxIdle                       | 始终保留在池中的最大连接数，如果启用，将定期检查限制连接，超出此属性设定的值且空闲时间超过minEvictableIdleTimeMillis的连接则释放 | 与maxActive设定的值相同   |
| minIdle                       | 始终保留在池中的最小连接数，池中的连接数量若低于此值则创建新的连接，如果连接验证失败将缩小至此值 | 与initialSize设定的值相同 |
| initialSize                   | 连接池启动时创建的初始连接数量                          | 10                 |
| maxWait                       | 最大等待时间（毫秒），如果在没有连接可用的情况下等待超过此时间，则抛出异常    | 30000（30秒）         |
| testOnBorrow                  | 当从连接池中取出一个连接时是否进行验证，若验证失败则从池中删除该连接并尝试取出另一个连接 | false              |
| testOnConnect                 | 当一个连接首次被创建时是否进行验证，若验证失败则抛出 SQLException 异常 | false              |
| testOnReturn                  | 当一个连接使用完归还到连接池时是否进行验证                    | false              |
| testWhileIdle                 | 对池中空闲的连接是否进行验证，验证失败则回收此连接                | false              |
| validationQuery               | 在连接池返回连接给调用者前用来对连接进行验证的查询 SQL            | null               |
| validationQueryTimeout        | SQL 查询验证超时时间（秒），小于或等于 0 的数值表示禁用          | -1                 |
| timeBetweenEvictionRunsMillis | 在空闲连接回收器线程运行期间休眠时间（毫秒）， 该值不应该小于 1 秒，它决定线程多久验证空闲连接或丢弃连接的频率 | 5000（5秒）           |
| minEvictableIdleTimeMillis    | 连接在池中保持空闲而不被回收的最小时间（毫秒）                  | 60000（60秒）         |
| removeAbandoned               | 标记是否删除泄露的连接，如果连接超出removeAbandonedTimeout的限制，且该属性设置为 true，则连接被认为是被泄露并且可以被删除 | false              |
| removeAbandonedTimeout        | 泄露的连接可以被删除的超时时间（秒），该值应设置为应用程序查询可能执行的最长时间 | 60                 |

`application.yml`:

```
spring:
  datasource:
    url: jdbc:mysql://127.0.0.1/spring_boot_testing_storage
    username: root
    password: root
    driver-class-name: com.mysql.jdbc.Driver
    tomcat:
      default-auto-commit: true
      initial-size: 30
      max-active: 120
      max-wait: 10000
      test-on-borrow: true
      test-while-idle: true
      validation-query: 'SELECT 1'
      validation-query-timeout: 3
      time-between-eviction-runs-millis: 10000
      min-evictable-idle-time-millis: 120000
      remove-abandoned: true
      remove-abandoned-timeout: 120
```

## DBCP 连接池常用配置

| 属性                            | 描述                                       | 默认值           |
| ----------------------------- | ---------------------------------------- | ------------- |
| url                           | 数据库连接地址                                  | -             |
| username                      | 数据库账户                                    | -             |
| password                      | 数据库密码                                    | -             |
| driverClassName               | 驱动类的名称                                   | -             |
| defaultAutoCommit             | 连接池中创建的连接默认是否自动提交事务                      | 驱动的缺省值        |
| defaultReadOnly               | 连接池中创建的连接默认是否为只读状态                       | 驱动的缺省值        |
| defaultCatalog                | 连接池中创建的连接默认的 catalog                     | -             |
| initialSize                   | 连接池启动时创建的初始连接数量                          | 0             |
| maxTotal                      | 连接池同一时间可分配的最大活跃连接数；负数表示不限制               | 8             |
| maxIdle                       | 可以在池中保持空闲的最大连接数，超出此值的空闲连接被释放，负数表示不限制     | 8             |
| minIdle                       | 可以在池中保持空闲的最小连接数，低于此值将创建空闲连接，若设置为 0，则不创建  | 0             |
| maxWaitMillis                 | 最大等待时间（毫秒），如果在没有连接可用的情况下等待超过此时间，则抛出异常；-1 表示无限期等待，直到获取到连接为止 | -             |
| validationQuery               | 在连接池返回连接给调用者前用来对连接进行验证的查询 SQL            | -             |
| validationQueryTimeout        | SQL 查询验证超时时间（秒）                          | -             |
| testOnCreate                  | 连接在创建之后是否进行验证                            | false         |
| testOnBorrow                  | 当从连接池中取出一个连接时是否进行验证，若验证失败则从池中删除该连接并尝试取出另一个连接 | true          |
| testOnReturn                  | 当一个连接使用完归还到连接池时是否进行验证                    | false         |
| testWhileIdle                 | 对池中空闲的连接是否进行验证，验证失败则释放此连接                | false         |
| timeBetweenEvictionRunsMillis | 在空闲连接回收器线程运行期间休眠时间（毫秒），如果设置为非正数，则不运行此线程  | -1            |
| numTestsPerEvictionRun        | 空闲连接回收器线程运行期间检查连接的个数                     | 3             |
| minEvictableIdleTimeMillis    | 连接在池中保持空闲而不被回收的最小时间（毫秒）                  | 1800000（30分钟） |
| removeAbandonedOnBorrow       | 标记是否删除泄露的连接，如果连接超出removeAbandonedTimeout的限制，且该属性设置为 true，则连接被认为是被泄露并且可以被删除 | false         |
| removeAbandonedTimeout        | 泄露的连接可以被删除的超时时间（秒），该值应设置为应用程序查询可能执行的最长时间 | 300（5分钟）      |
| poolPreparedStatements        | 设置该连接池的预处理语句池是否生效                        | false         |

`application.yml`

```
spring:
  jmx:
    enabled: false
  datasource:
    url: jdbc:mysql://127.0.0.1/spring_boot_testing_storage
    username: root
    password: root
    driver-class-name: com.mysql.jdbc.Driver
    dbcp2:
      default-auto-commit: true
      initial-size: 30
      max-total: 120
      max-idle: 120
      min-idle: 30
      max-wait-millis: 10000
      validation-query: 'SELECT 1'
      validation-query-timeout: 3
      test-on-borrow: true
      test-while-idle: true
      time-between-eviction-runs-millis: 10000
      num-tests-per-eviction-run: 10
      min-evictable-idle-time-millis: 120000
      remove-abandoned-on-borrow: true
      remove-abandoned-timeout: 120
      pool-prepared-statements: true
```

Spring Boot Data Jpa 依赖声明：

```
通过application.yml: spring.datasource.type=...配置

<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-dbcp2</artifactId>
    <version>2.2.0</version>
</dependency>
```

## Druid连接池配置

参考：***[https://github.com/alibaba/druid/tree/master/druid-spring-boot-starter](https://github.com/alibaba/druid/tree/master/druid-spring-boot-starter)***

# Spring MVC集成fastjson

```
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>fastjson</artifactId>
    <version>1.2.46</version>
</dependency>
```

两种方式：

## 方式一、实现`WebMvcConfigurer`

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

## 方式二、通过`@Bean`方式

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

## WebFlux

上面针对的是Web MVC，**对于Webflux目前不支持这种方式**，只能先这么设置

```
spring:
  jackson:
    default-property-inclusion: non_null # 过滤值为null的字段
    date-format: "yyyy-MM-dd HH:mm:ss"
```

# 开启GZIP算法压缩响应流

```
server:
  compression:
    enabled: true # 启用压缩
    min-response-size: 2048 # 对应Content-Length，超过这个值才会压缩
```

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

在不配置线程池的情况下，Spring默认使用`SimpleAsyncTaskExecutor`，每一次的执行任务都会使用新的线程，性能不太好，所以我们可以自定义线程池

### 直接定义线程池

```
@Configuration
@EnableAsync
public class SpringAsyncConfig {
	@Bean
	public Executor threadPoolTaskExecutor() {
		ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
		executor.setCorePoolSize(8);
		executor.setMaxPoolSize(42);
		executor.setQueueCapacity(500);
		executor.setThreadNamePrefix("asyncExecutor-");
		executor.initialize();
		return executor;
	}
}
```

### 实现AsyncConfigurer

`AsyncConfigurer`接口有两个方法：

* `getAsyncExecutor()`: 提供线程池
* `getAsyncUncaughtExceptionHandler()`: 异步任务异常处理

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

## Async使用指定线程池

如果同时实现了`AsyncConfigurer`以及配置线程池，那么`@Async`默认使用`AsyncConfigurer.getAsyncExecutor`的线程池。

如果需要指定线程池可以这样

```
@Bean("threadPoolTaskExecutor")
public Executor threadPoolTaskExecutor() {
	ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
	executor.setCorePoolSize(8);
	executor.setMaxPoolSize(42);
	executor.setQueueCapacity(500);
	executor.setThreadNamePrefix("asyncExecutor-");
	executor.initialize();
	return executor;
}


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

1. 通过`@PostConstruct`或实现`InitializingBean`实现初始化`bean`的时候干一些事情，两者区别在于`InitializingBean`是在属性设置完之后执行的，所以执行顺序是在`@PostConstruct`之前

   > 由于此接口的方法afterPropertiesSet是在对象的所有属性被初始化后才会调用。当Spring的配置文件中设置类初始默认为”延迟初始”（`default-lazy-init="true"`，此值默认为false）时，
   >
   > 类对象如果不被使用，则不会实例化该类对象。所以 InitializingBean子类不能用于在容器启动时进行初始化的工作，则应使用Spring提供的`ApplicationListener`接口来进行程序的初始化工作。
   >
   > 另外，如果需要InitializingBean子类对象在Spring容器启动时就初始化并则容器调用afterPropertiesSet方法则需要在类上增加`org.springframework.context.annotation.Lazy`注解并设置为false即可（也可通过spring配置bean时添加`lazy-init="false"`)。

2. 通过监听`ContextRefreshedEvent`事件：

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

   以下是Spring的内置事件

   | Spring 内置事件               | 描述                                       |
   | ------------------------- | ---------------------------------------- |
   | **ContextRefreshedEvent** | `ApplicationContext`被初始化或刷新时，该事件被发布。这也可以在`ConfigurableApplicationContext`接口中使用`refresh()`方法来发生。 |
   | **ContextStartedEvent**   | 当使用`ConfigurableApplicationContext`接口中的`start()`方法启动`ApplicationContext`时，该事件被触发。你可以查询你的数据库，或者你可以在接受到这个事件后重启任何停止的应用程序。 |
   | **ContextStoppedEvent**   | 当使用`ConfigurableApplicationContext`接口中的`stop()`方法停止`ApplicationContext`时，该事件被触发。你可以在接受到这个事件后做必要的清理的工作。 |
   | **ContextClosedEvent**    | 当使用`ConfigurableApplicationContext`接口中的`close()`方法关闭`ApplicationContext`时，该事件被触发。一个已关闭的上下文到达生命周期末端；它不能被刷新或重启。 |
   | **RequestHandledEvent**   | 这是一个`web-specific`事件，告诉所有`bean` HTTP请求已经被服务。 |

   Spring的事件处理是单线程的，所以如果一个事件被触发，除非所有的接收者得到消息，否则这些进程被阻止，流程将不会继续。因此，如果要使用事件处理，在设计应用程序时应小心。

   **注意！**发现在Spring Boot 2中通过监听内置事件，都会发布两次，不知道这是BUG还是啥，所以需要确保方法**幂等性**或者做**只消费一次处理**

3. 实现`ApplicationRunner`或`CommandLineRunner`

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

   ​


# Spring Boot 事件

在Spring Boot 2.0中对事件模型做了一些增强，主要就是增加了`ApplicationStartedEvent`事件，所以在2.0版本中所有的事件按执行的先后顺序如下：

- `ApplicationStartingEvent`
- `ApplicationEnvironmentPreparedEvent`
- `ApplicationPreparedEvent`
- `ApplicationStartedEvent` <= 新增的事件
- `ApplicationReadyEvent`
- `ApplicationFailedEvent`

# 测试篇

## 使用AssertJ

> [AssertJ Core features highlight](http://joel-costigliola.github.io/assertj/assertj-core-features-highlight.html)

如果是Spring Boot 1.x版本，在`spring-boot-starter-test`模块中，AssertJ的版本依然停留在`2.x`，为了可以使用新功能，我们可以引入新版本的AssertJ（**Spring Boot 2已经是最新版的AssertJ**）:

```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
    <exclusions>
        <exclusion>
            <groupId>org.assertj</groupId>
            <artifactId>assertj-core</artifactId>
        </exclusion>
    </exclusions>
</dependency>

<dependency>
    <groupId>org.assertj</groupId>
    <artifactId>assertj-core</artifactId>
    <version>3.9.0</version>
</dependency>
```

AsserJ的API很多，功能非常强大，直接贴上代码：

```
package com.yangbingdong.springboottestassertj.assertj;

import com.yangbingdong.springboottestassertj.domain.Person;
import org.assertj.core.util.Maps;
import org.junit.Test;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import java.nio.charset.Charset;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatExceptionOfType;
import static org.assertj.core.api.Assertions.assertThatIOException;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.atIndex;
import static org.assertj.core.api.Assertions.contentOf;
import static org.assertj.core.api.Assertions.entry;
import static org.assertj.core.util.DateUtil.parse;
import static org.assertj.core.util.DateUtil.parseDatetimeWithMs;
import static org.assertj.core.util.Lists.newArrayList;

/**
 * @author ybd
 * @date 18-2-8
 * @contact yangbingdong@1994.gmail
 */
public class AssertJTestDemo {

	/**
	 * 字符串断言
	 */
	@Test
	public void testString() {
		String str = null;
		// 断言null或为空字符串
		assertThat(str).isNullOrEmpty();
		// 断言空字符串
		assertThat("").isEmpty();
		// 断言字符串相等 断言忽略大小写判断字符串相等
		assertThat("Frodo").isEqualTo("Frodo").isEqualToIgnoringCase("frodo");
		// 断言开始字符串 结束字符穿 字符串长度
		assertThat("Frodo").startsWith("Fro").endsWith("do").hasSize(5);
		// 断言包含字符串 不包含字符串
		assertThat("Frodo").contains("rod").doesNotContain("fro");
		// 断言字符串只出现过一次
		assertThat("Frodo").containsOnlyOnce("do");
		// 判断正则匹配
		assertThat("Frodo").matches("..o.o").doesNotMatch(".*d");
	}

	/**
	 * 数字断言
	 */
	@Test
	public void testNumber() {
		Integer num = null;
		// 断言空
		assertThat(num).isNull();
		// 断言相等
		assertThat(42).isEqualTo(42);
		// 断言大于 大于等于
		assertThat(42).isGreaterThan(38).isGreaterThanOrEqualTo(38);
		// 断言小于 小于等于
		assertThat(42).isLessThan(58).isLessThanOrEqualTo(58);
		// 断言0
		assertThat(0).isZero();
		// 断言正数 非负数
		assertThat(1).isPositive().isNotNegative();
		// 断言负数 非正数
		assertThat(-1).isNegative().isNotPositive();
	}

	/**
	 * 时间断言
	 */
	@Test
	public void testDate() {
		// 断言与指定日期相同 不相同 在指定日期之后 在指定日期之钱
		assertThat(parse("2014-02-01")).isEqualTo("2014-02-01").isNotEqualTo("2014-01-01")
									   .isAfter("2014-01-01").isBefore(parse("2014-03-01"));
		// 断言 2014 在指定年份之前 在指定年份之后
		assertThat(new Date()).isBeforeYear(2020).isAfterYear(2013);
		// 断言时间再指定范围内 不在指定范围内
		assertThat(parse("2014-02-01")).isBetween("2014-01-01", "2014-03-01").isNotBetween(
				parse("2014-02-02"), parse("2014-02-28"));

		// 断言两时间相差100毫秒
		Date d1 = new Date();
		Date d2 = new Date(d1.getTime() + 100);
		assertThat(d1).isCloseTo(d2, 100);

		// sets dates differing more and more from date1
		Date date1 = parseDatetimeWithMs("2003-01-01T01:00:00.000");
		Date date2 = parseDatetimeWithMs("2003-01-01T01:00:00.555");
		Date date3 = parseDatetimeWithMs("2003-01-01T01:00:55.555");
		Date date4 = parseDatetimeWithMs("2003-01-01T01:55:55.555");
		Date date5 = parseDatetimeWithMs("2003-01-01T05:55:55.555");

		// 断言 日期忽略毫秒，与给定的日期相等
		assertThat(date1).isEqualToIgnoringMillis(date2);
		// 断言 日期与给定的日期具有相同的年月日时分秒
		assertThat(date1).isInSameSecondAs(date2);
		// 断言 日期忽略秒，与给定的日期时间相等
		assertThat(date1).isEqualToIgnoringSeconds(date3);
		// 断言 日期与给定的日期具有相同的年月日时分
		assertThat(date1).isInSameMinuteAs(date3);
		// 断言 日期忽略分，与给定的日期时间相等
		assertThat(date1).isEqualToIgnoringMinutes(date4);
		// 断言 日期与给定的日期具有相同的年月日时
		assertThat(date1).isInSameHourAs(date4);
		// 断言 日期忽略小时，与给定的日期时间相等
		assertThat(date1).isEqualToIgnoringHours(date5);
		// 断言 日期与给定的日期具有相同的年月日
		assertThat(date1).isInSameDayAs(date5);
	}

	/**
	 * 集合断要
	 */
	@Test
	public void testList() {
		// 断言 列表是空的
		assertThat(newArrayList()).isEmpty();
		// 断言 列表的开始 结束元素
		assertThat(newArrayList(1, 2, 3)).startsWith(1).endsWith(3);
		// 断言 列表包含元素 并且是排序的
		assertThat(newArrayList(1, 2, 3)).contains(1, atIndex(0)).contains(2, atIndex(1)).contains(3)
										 .isSorted();
		// 断言 被包含与给定列表
		assertThat(newArrayList(3, 1, 2)).isSubsetOf(newArrayList(1, 2, 3, 4));
		// 断言 存在唯一元素
		assertThat(newArrayList("a", "b", "c")).containsOnlyOnce("a");
	}

	/**
	 * Map断言
	 */
	@Test
	public void testMap() {
		Map<String, Object> foo = Maps.newHashMap("A", 1);
		foo.put("B", 2);
		foo.put("C", 3);

		// 断言 map 不为空 size
		assertThat(foo).isNotEmpty().hasSize(3);
		// 断言 map 包含元素
		assertThat(foo).contains(entry("A", 1), entry("B", 2));
		// 断言 map 包含key
		assertThat(foo).containsKeys("A", "B", "C");
		// 断言 map 包含value
		assertThat(foo).containsValue(3);
	}

	/**
	 * 类断言
	 */
	@Test
	public void testClass() {
		// 断言 是注解
		assertThat(Magical.class).isAnnotation();
		// 断言 不是注解
		assertThat(Ring.class).isNotAnnotation();
		// 断言 存在注解
		assertThat(Ring.class).hasAnnotation(Magical.class);
		// 断言 不是借口
		assertThat(Ring.class).isNotInterface();
		// 断言 是否为指定Class实例
		assertThat("string").isInstanceOf(String.class);
		// 断言 类是给定类的父类
		assertThat(Person1.class).isAssignableFrom(Employee.class);
	}

	/**
	 * 异常断言
	 */
	@Test
	public void testException() {
		assertThatThrownBy(() -> { throw new Exception("boom!"); }).isInstanceOf(Exception.class)
		  .hasMessageContaining("boom");

		assertThatExceptionOfType(IOException.class).isThrownBy(() -> { throw new IOException("boom!"); })
													.withMessage("%s!", "boom")
													.withMessageContaining("boom")
													.withNoCause();

		/*
		 * assertThatNullPointerException
		 * assertThatIllegalArgumentException
		 * assertThatIllegalStateException
		 * assertThatIOException
		 */
		assertThatIOException().isThrownBy(() -> { throw new IOException("boom!"); })
							   .withMessage("%s!", "boom")
							   .withMessageContaining("boom")
							   .withNoCause();
	}

	/**
	 * 断言添加描述
	 */
	@Test
	public void addDesc() {
		Person person = new Person("ybd", 18);
		assertThat(person.getAge()).as("check %s's age", person.getName()).isEqualTo(18);
	}

	/**
	 * 断言对象列表
	 */
	@Test
	public void personListTest() {
		List<Person> personList = Arrays.asList(new Person("A", 1), new Person("B", 2), new Person("C", 3));
		assertThat(personList).extracting(Person::getName).contains("A", "B").doesNotContain("D");
	}

	@Test
	public void personListTest1() {
		List<Person> personList = Arrays.asList(new Person("A", 1), new Person("B", 2), new Person("C", 3));
		assertThat(personList).flatExtracting(Person::getName).contains("A", "B").doesNotContain("D");
	}

	/**
	 * 断言文件
	 * @throws Exception
	 */
	@Test
	public void testFile() throws Exception {
		File xFile = writeFile("xFile", "The Truth Is Out There");

		assertThat(xFile).exists().isFile().isRelative();

		assertThat(xFile).canRead().canWrite();

		assertThat(contentOf(xFile)).startsWith("The Truth").contains("Is Out").endsWith("There");
	}

	private File writeFile(String fileName, String fileContent) throws Exception {
		return writeFile(fileName, fileContent, Charset.defaultCharset());
	}

	private File writeFile(String fileName, String fileContent, Charset charset) throws Exception {
		File file = new File("target/" + fileName);
		BufferedWriter out = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(file), charset));
		out.write(fileContent);
		out.close();
		return file;
	}

	@Magical
	public enum Ring {
		oneRing, vilya, nenya, narya, dwarfRing, manRing;
	}

	@Target(ElementType.TYPE)
	@Retention(RetentionPolicy.RUNTIME)
	public @interface Magical {
	}

	public class Person1 {
	}

	public class Employee extends Person1 {
	}
}
```

更多请看官方例子：***[https://github.com/joel-costigliola/assertj-examples](https://github.com/joel-costigliola/assertj-examples)***

## Gatling性能测试

> 性能测试的两种类型，负载测试和压力测试：
> - **负载测试（Load Testing）：**负载测试是一种主要为了测试软件系统是否达到需求文档设计的目标，譬如软件在一定时期内，最大支持多少并发用户数，软件请求出错率等，测试的主要是软件系统的性能。
> - **压力测试（Stress Testing）：**压力测试主要是为了测试硬件系统是否达到需求文档设计的性能目标，譬如在一定时期内，系统的cpu利用率，内存使用率，磁盘I/O吞吐率，网络吞吐量等，压力测试和负载测试最大的差别在于测试目的不同。

### Gatling 简介

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/gatling-logo.png)

Gatling 是一个功能强大的负载测试工具。它是为易用性、可维护性和高性能而设计的。

开箱即用，Gatling 带有对 HTTP 协议的出色支持，使其成为负载测试任何 HTTP 服务器的首选工具。由于核心引擎实际上是协议不可知的，所以完全可以实现对其他协议的支持，例如，Gatling 目前也提供JMS 支持。

只要底层协议（如 HTTP）能够以非阻塞的方式实现，Gatling 的架构就是异步的。这种架构可以将虚拟用户作为消息而不是专用线程来实现。因此，运行数千个并发的虚拟用户不是问题。

### 使用Recorder快速开始

官方提供了GUI界面的录制器，可以监听对应端口记录请求操作并转化为Scala脚本

1、进入 *[下载页面](https://gatling.io/download/)* 下载最新版本
2、解压并进入 `$GATLING_HOME/bin` (`$GATLING_HOME`为解压目录)，运行`recorder.sh`
![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/recorder1.png)

* 上图监听8000端口（若被占用请更换端口），需要在浏览器设置代理，以FireFox为例：
  ![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/firefox-proxy.jpg)

* `Output folder`为Scala脚本输出路径，例如设置为 `/home/ybd/data/application/gatling-charts-highcharts-bundle-2.3.0/user-files/simulations`，会在该路经下面生成一个`RecordedSimulation.scala`的文件（上面指定的Class Name）：
  ![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/scala-script-location.jpg)


3、点击`record`并在Firefox进行相应操作，然后点击`Stop`，会生成类似下面的脚本：

```
package computerdatabase 

import io.gatling.core.Predef._ 
import io.gatling.http.Predef._
import scala.concurrent.duration._

class BasicSimulation extends Simulation { 

  val httpConf = http 
    .baseURL("http://computer-database.gatling.io") 
    .acceptHeader("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8") 
    .doNotTrackHeader("1")
    .acceptLanguageHeader("en-US,en;q=0.5")
    .acceptEncodingHeader("gzip, deflate")
    .userAgentHeader("Mozilla/5.0 (Windows NT 5.1; rv:31.0) Gecko/20100101 Firefox/31.0")

  val scn = scenario("BasicSimulation")
    .exec(http("request_1")
    .get("/"))
    .pause(5) 

  setUp( 
    scn.inject(atOnceUsers(1))
  ).protocols(httpConf)
}
```

4、然后运行 `$GATLING_HOME/bin/gatling.sh`，选择 `[0] RecordedSimulation`，随后的几个选项直接回车即可生成测试结果：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/terminal-gatling-test1.jpg)

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/terminal-gatling-test2.jpg)

注意看上图最下面那一行，就是生成测试结果的入口。

具体请看官方文档：*[https://gatling.io/docs/current/quickstart](https://gatling.io/docs/current/quickstart)*

### 使用IDEA编写

1、首先安装Scala插件：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/scala-plugin.jpg)

2、安装 scala SDK：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/add-scala-sdk02.jpg)

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/add-scala-sdk01.jpg)

3、编写测试脚本

```
class ApiGatlingSimulationTest extends Simulation {

  val scn: ScenarioBuilder = scenario("AddAndFindPersons").repeat(100, "n") {
    exec(
      http("AddPerson-API")
        .post("http://localhost:8080/persons")
        .header("Content-Type", "application/json")
        .body(StringBody("""{"firstName":"John${n}","lastName":"Smith${n}","birthDate":"1980-01-01", "address": {"country":"pl","city":"Warsaw","street":"Test${n}","postalCode":"02-200","houseNo":${n}}}"""))
        .check(status.is(200))
    ).pause(Duration.apply(5, TimeUnit.MILLISECONDS))
  }.repeat(1000, "n") {
    exec(
      http("GetPerson-API")
        .get("http://localhost:8080/persons/${n}")
        .check(status.is(200))
    )
  }

  setUp(scn.inject(atOnceUsers(30))).maxDuration(FiniteDuration.apply(10, "minutes"))
```

4、配置pom

```
 <build>
        <plugins>
            <!-- Gatling Maven 插件， 使用： mvn gatling:execute 命令运行 -->
            <plugin>
                <groupId>io.gatling</groupId>
                <artifactId>gatling-maven-plugin</artifactId>
                <version>${gatling-plugin.version}</version>
                <configuration>
                    <!-- 测试脚本 -->
                    <simulationClass>com.yangbingdong.springbootgatling.gatling.ApiGatlingSimulationTest</simulationClass>
                    <!-- 结果输出地址 -->
                    <resultsFolder>/home/ybd/test/gatling</resultsFolder>
                </configuration>
            </plugin>
        </plugins>
    </build>
```

5、运行 Spring Boot 应用

6、运行测试

```
mvn gatling:execute
```
![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/idea-gatling-test.jpg)

我们打开结果中的`index.html`：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/gatling-test-result1.jpg)

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/gatling-test-result2.jpg)

### 遇到问题

途中出现了以下错误

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/gatling-error1.jpg)

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/gatling-error2.jpg)

这是由于**使用了Log4J2**，把Gatling自带的Logback排除了（同一个项目），把`<exclusions>`这一段注释掉就没问题了：

```
<dependency>
    <groupId>io.gatling.highcharts</groupId>
    <artifactId>gatling-charts-highcharts</artifactId>
    <version>${gatling-charts-highcharts.version}</version>
    <!-- 由于配置了log4j2，运行Gatling时需要**注释**以下的 exclusions，否则会抛异常，但貌似不影响测试结果 -->
    <exclusions>
        <exclusion>
            <groupId>ch.qos.logback</groupId>
            <artifactId>logback-classic</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

囧。。。。。。

> 参考：*[http://www.spring4all.com/article/584](http://www.spring4all.com/article/584)*
>
> 代码：*[https://github.com/masteranthoneyd/spring-boot-learning/tree/master/spring-boot-gatling](https://github.com/masteranthoneyd/spring-boot-learning/tree/master/spring-boot-gatling)*
>
> 官方教程：*[https://gatling.io/docs/current/advanced_tutorial/](https://gatling.io/docs/current/advanced_tutorial/)*

## ContPerf

ContiPerf

是一个轻量级的**测试**工具，基于**JUnit**4 开发，可用于**接口**级的**性能测试**，快速压测。

引入依赖:

```
        <!-- 性能测试 -->
        <dependency>
            <groupId>org.databene</groupId>
            <artifactId>contiperf</artifactId>
            <scope>test</scope>
            <version>2.1.0</version>
        </dependency>
```

### ContiPerf介绍

可以指定在线程数量和执行次数，通过限制最大时间和平均执行时间来进行效率测试，一个简单的例子如下：

```
public class ContiPerfTest { 
    @Rule 
    publicContiPerfRule i = newContiPerfRule(); 
   
    @Test 
    @PerfTest(invocations = 1000, threads = 40) 
    @Required(max = 1200, average = 250, totalTime = 60000) 
    publicvoidtest1() throwsException { 
        Thread.sleep(200); 
    } 
}
```

使用`@Rule`注释激活ContiPerf，通过`@Test`指定测试方法，`@PerfTest`指定调用次数和线程数量，`@Required`指定性能要求（每次执行的最长时间，平均时间，总时间等）。

也可以通过对类指定`@PerfTest`和`@Required`，表示类中方法的默认设置，如下：

```
@PerfTest(invocations = 1000, threads = 40) 
@Required(max = 1200, average = 250, totalTime = 60000) 
public class ContiPerfTest { 
    @Rule 
    public ContiPerfRule i = new ContiPerfRule(); 
   
    @Test 
    public void test1() throws Exception { 
        Thread.sleep(200); 
    } 
}
```

### 主要参数介绍

1）PerfTest参数

`@PerfTest(invocations = 300)`：执行300次，和线程数量无关，默认值为1，表示执行1次；

`@PerfTest(threads=30)`：并发执行30个线程，默认值为1个线程；

`@PerfTest(duration = 20000)`：重复地执行测试至少执行20s。

三个属性可以组合使用，其中`Threads`必须和其他两个属性组合才能生效。当`Invocations`和`Duration`都有指定时，以执行次数多的为准。

　　例，`@PerfTest(invocations = 300, threads = 2, duration = 100)`，如果执行方法300次的时候执行时间还没到100ms，则继续执行到满足执行时间等于100ms，如果执行到50次的时候已经100ms了，则会继续执行之100次。

　　如果你不想让测试连续不间断的跑完，可以通过注释设置等待时间，例，`@PerfTest(invocations = 1000, threads = 10, timer = RandomTimer.class, timerParams = { 30, 80 })` ，每执行完一次会等待30~80ms然后才会执行下一次调用。

　　在开多线程进行并发压测的时候，如果一下子达到最大进程数有些系统可能会受不了，ContiPerf还提供了“预热”功能，例，`@PerfTest(threads = 10, duration = 60000, rampUp = 1000)` ，启动时会先起一个线程，然后每个1000ms起一线程，到9000ms时10个线程同时执行，那么这个测试实际执行了69s，如果只想衡量全力压测的结果，那么可以在注释中加入warmUp，即`@PerfTest(threads = 10, duration = 60000, rampUp = 1000, warmUp = 9000)` ，那么统计结果的时候会去掉预热的9s。

2）Required参数

`@Required(throughput = 20)`：要求每秒至少执行20个测试；

`@Required(average = 50)`：要求平均执行时间不超过50ms；

`@Required(median = 45)`：要求所有执行的50%不超过45ms； 

`@Required(max = 2000)`：要求没有测试超过2s；

`@Required(totalTime = 5000)`：要求总的执行时间不超过5s；

`@Required(percentile90 = 3000)`：要求90%的测试不超过3s；

`@Required(percentile95 = 5000)`：要求95%的测试不超过5s； 

`@Required(percentile99 = 10000)`：要求99%的测试不超过10s; 

`@Required(percentiles = "66:200,96:500")`：要求66%的测试不超过200ms，96%的测试不超过500ms。

### 测试结果

测试结果除了会在控制台显示之外，还会生成一个结果文件`target/contiperf-report/index.html`

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/contiperf-report.jpg)

