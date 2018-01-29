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
    factory.addBuilderCustomizers(builder -> builder.setServerOption(UndertowOptions.ENABLE_HTTP2, true));
    // 监听多个端口
    builder.addHttpListener(8080, "0.0.0.0");
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
# 阻塞任务线程池, 当执行类似servlet请求阻塞操作, undertow会从这个线程池中取得线程,它的值设置取决于系统的负载
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
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <exclusions>
        <!-- 抛弃自带的log，使用外置log框架 -->
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-logging</artifactId>
        </exclusion>
    </exclusions>
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

## log4j2.xml 配置

```
<?xml version="1.0" encoding="UTF-8"?>
<!-- Configuration后面的status，这个用于设置log4j2自身内部的信息输出，可以不设置，当设置成trace时，
     你会看到log4j2内部各种详细输出。可以设置成OFF(关闭) 或 Error(只输出错误信息)。
     30s 刷新此配置
-->
<configuration status="WARN" monitorInterval="30">

    <!-- 日志文件目录、压缩文件目录、日志格式配置 -->
    <properties>
        <Property name="fileName">/home/ybd/logs/log</Property>
        <Property name="fileGz">/home/ybd/logs/7z</Property>
        <Property name="PID">????</Property>
        <Property name="LOG_PATTERN">%clr{%d{yyyy-MM-dd HH:mm:ss.SSS}}{faint} %clr{%5p} %clr{${sys:PID}}{magenta} %clr{---}{faint} %clr{[%15.15t]}{faint} %clr{%-40.40c{1.}}{cyan} %clr{:}{faint} %m%n%xwEx</Property>
        <!--<Property name="LOG_PATTERN">%d{yyyy-MM-dd 'at' HH:mm:ss z} [%t] %-5level %logger{36} %L %M - %msg%xEx%n</Property>-->
    </properties>

    <Appenders>
        <!-- 输出控制台日志的配置 -->
        <Console name="console" target="SYSTEM_OUT">
            <!--控制台只输出level及以上级别的信息（onMatch），其他的直接拒绝（onMismatch）-->
            <ThresholdFilter level="debug" onMatch="ACCEPT" onMismatch="DENY"/>
            <!-- 输出日志的格式 -->
            <PatternLayout pattern="${LOG_PATTERN}"/>
        </Console>

        <!-- 打印出所有的信息，每次大小超过size，则这size大小的日志会自动存入按年份-月份建立的文件夹下面并进行压缩，作为存档 -->
        <RollingRandomAccessFile name="infoFile" fileName="${fileName}/web-info.log" immediateFlush="false"
                                    filePattern="${fileGz}/$${date:yyyy-MM}/%d{yyyy-MM-dd}-%i.web-info.gz">
            <PatternLayout pattern="${LOG_PATTERN}"/>

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
            <PatternLayout pattern="${LOG_PATTERN}"/>

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



# 配置连接池





> 学习汇总：[http://www.ityouknow.com/springboot/2015/12/30/springboot-collect.html](http://www.ityouknow.com/springboot/2015/12/30/springboot-collect.html)

