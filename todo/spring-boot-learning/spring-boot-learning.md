> Spring Boot作为当下最流行的微服务项目构建基础，有的时候我们根本不需要额外的配置就能够干很多的事情，这得益于它的一个核心理念：“习惯优于配置”。。。
>
> 说白的就是大部分的配置都已经按照比较便准的编程规范配置好了

# 构建父工程

父工程只是作为管理全局依赖版本管理以及插件管理的存在，子工程只需要引用依赖，并不需要关心版本号。

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/parent.png)

整个工程只需要一个`pom.xml`（下面那个是IDEA生成的，非必要）：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-learning/parent-pom.png)

说明：

* `<packaging>` 为 `pom` 表示此会被打包成 pom 文件被其他子项目依赖。
* 由于 Spring Boot 以及集成了 `maven-surefire-plugin` 插件，跳过测试只需要在 properties中添加 `<maven.test.skip>true</maven.test.skip>`即可
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
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-tomcat</artifactId>
        </exclusion>
    </exclusions>
</dependency>
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
    <version>3.3.7</version>
</dependency>
```

**注意**：需要单独把`spring-boot-starter`里面的`logging`去除再引入`spring-boot-starter-web`，否则后面引入的`starter`模块带有的`logging`不会自动去除

## application.yml简单配置

```
logging:
  pattern:
    console: "%clr{%d{yyyy-MM-dd HH:mm:ss.SSS}}{faint} | %clr{%5p} | %clr{%15.15t}{faint} | %clr{%-50.50c{1.}}{cyan} | %5L | %clr{%M}{magenta} | %msg%n%xwEx"
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
        
        <Root level="debug" includeLocation="true">
            <AppenderRef ref="console"/>
            <AppenderRef ref="infoFile"/>
            <AppenderRef ref="errorFile"/>
        </Root>

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

## 依赖冲突

如果引入了某些jar包带有`logback`依赖，log4j2会失效，需要通过IDEA或Maven查找排除依赖：

```
mvn dependency:tree
```

# 常用连接池配置

如果项目中已包含`spring-boot-starter-jdbc`或`spring-boot-starter-jpa`模块，那么连接池将**自动激活**！

Spring Boot选择数据库链接池实现的判断逻辑：

1. 检查Tomcat的数据库链接池实现是否可用，如可用，则启用。使用`spring.datasource.tomcat.*`可以控制链接池的行为。
2. 检查HikariCP是否可用，如可用，则启用。使用`spring.datasource.hikari.*`可以控制链接池的行为。
3. 检查Commons DBCP是否可用，如可用，则启用；但Spring Boot**不建议**在生产环境使用该链接池的实现。
4. 检查Commons DBCP2是否可用，如可用，则启用。使用`spring.datasource.dbcp2.*`可以控制链接池的行为。

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
| maximumPoolSize     | 连接池中可同时连接的最大连接数，当池中没有空闲连接可用时，就会阻塞直到超出connectionTimeout设定的数值 | 10                   |
| poolName            | 连接池名称，主要用于显示在日志记录和 JMX 管理控制台中            | auto-generated       |

`application.yml`

```
spring:
  datasource:
      url: jdbc:mysql://127.0.0.1/spring_boot_testing_storage
      username: root
      password: root
      driver-class-name: com.mysql.jdbc.Driver
      hikari:
        auto-commit: true
        connection-test-query: 'SELECT 1'
        maximum-pool-size: 150
```

Spring Boot Data Jpa 依赖声明：

```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
    <exclusions>
        <exclusion>
            <groupId>org.apache.tomcat</groupId>
            <artifactId>tomcat-jdbc</artifactId>
        </exclusion>
    </exclusions>
</dependency>
<!-- 移除 tomcat-jdbc, Spring Boot 将会自动使用 HikariCP -->
<dependency>
    <groupId>com.zaxxer</groupId>
    <artifactId>HikariCP</artifactId>
    <version>2.7.1</version>
</dependency>
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
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
    <exclusions>
        <exclusion>
            <groupId>org.apache.tomcat</groupId>
            <artifactId>tomcat-jdbc</artifactId>
        </exclusion>
    </exclusions>
</dependency>
<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-dbcp2</artifactId>
    <version>2.2.0</version>
</dependency>
```

## Druid连接池配置

参考：***[https://github.com/alibaba/druid/tree/master/druid-spring-boot-starter](https://github.com/alibaba/druid/tree/master/druid-spring-boot-starter)***

> 学习汇总：[http://www.ityouknow.com/springboot/2015/12/30/springboot-collect.html](http://www.ityouknow.com/springboot/2015/12/30/springboot-collect.html)

