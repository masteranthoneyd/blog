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
<properties>
    <gatling-plugin.version>2.2.4</gatling-plugin.version>
    <gatling-charts-highcharts.version>2.3.0</gatling-charts-highcharts.version>
</properties>

<dependencies>
    <!-- 性能测试 Gatling -->
    <dependency>
        <groupId>io.gatling.highcharts</groupId>
        <artifactId>gatling-charts-highcharts</artifactId>
        <version>${gatling-charts-highcharts.version}</version>
        <!-- 由于配置了log4j2，运行Gatling时需要**注释**以下的 exclusions，否则会抛异常，但貌似不影响测试结果 -->
        <!--<exclusions>
            <exclusion>
                <groupId>ch.qos.logback</groupId>
                <artifactId>logback-classic</artifactId>
            </exclusion>
        </exclusions>-->
    </dependency>
</dependencies>

<build>
    <plugins>
        <!-- Gatling Maven 插件， 使用： mvn gatling:execute 命令运行 -->
        <plugin>
            <groupId>io.gatling</groupId>
            <artifactId>gatling-maven-plugin</artifactId>
            <version>${gatling-plugin.version}</version>
            <configuration>
                <!-- 测试脚本 -->
                <simulationClass>com.yangbingdong.springbootgatling.gatling.DockerTest</simulationClass>
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
