# Spring Boot 学习之测试篇

## 使用 Gatling 进行性能测试
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

这是由于使用了Log4J2，把Gatling自带的Logback排除了（同一个项目）：

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
> 官方教程：*[https://gatling.io/docs/current/advanced_tutorial/](https://gatling.io/docs/current/advanced_tutorial/)*

