---
title: Spring Boot学习之测试篇
date: 2018-08-28 10:16:40
categories: [Programming, Java, Spring Boot]
tags: [Java, Spring Boot, AssertJ, JMH, Gatling, ContPerf]
---

![](https://cdn.yangbingdong.com/img/spring-boot-testing/java-testing.png)

# Preface

> 测试已经是贯穿我们程序员的日常开发流程了，无论写个main方法，还是使用测试框架Junit、AssertJ，或者压测，都是我们日常开发的一部分。也有很多互联网公司推崇TDD（测试驱动开发）的。
>
> 下面主要介绍`AssertJ`、`JMH`、`Gatling`以及`ContPerf`。

<!--more-->

# 使用AssertJ

`AseertJ`: JAVA 流式断言器，什么是流式，常见的断言器一条断言语句只能对实际值断言一个校验点，而流式断言器，支持一条断言语句对实际值同时断言多个校验点。

> [AssertJ Core features highlight](http://joel-costigliola.github.io/assertj/assertj-core-features-highlight.html)

如果是Spring Boot 1.x版本，在`spring-boot-starter-test`模块中，AssertJ的版本依然停留在`2.x`，为了可以使用新功能，我们可以引入新版本的AssertJ（**Spring Boot 2已经是最新版的AssertJ**）:

```xml
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

## 字符串断言

```java
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
```

## 数字断言

```java
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
```

## 时间断言

```java
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
```

## 集合断言

```java
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
```

## Map断言

```java
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
```

## 类断言

```java
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
```

## 异常断言

```java
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
```

## 文件断言

```java
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
```

## 对象列表断言

```java
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
```

## 断言添加描述

```java
@Test
public void addDesc() {
	Person person = new Person("ybd", 18);
	assertThat(person.getAge()).as("check %s's age", person.getName()).isEqualTo(18);
}
```

## 官方例子

***[https://github.com/joel-costigliola/assertj-examples](https://github.com/joel-costigliola/assertj-examples)***

# JMH基准测试

> JMH 是一个由 OpenJDK/Oracle 里面那群开发了 Java 编译器的大牛们所开发的 Micro Benchmark Framework 。何谓 Micro Benchmark 呢？简单地说就是在 **method** 层面上的 benchmark，精度可以精确到微秒级。可以看出 JMH 主要使用在当你已经找出了热点函数，而需要对热点函数进行进一步的优化时，就可以使用 JMH 对优化的效果进行定量的分析。
>
> 比较典型的使用场景还有：
>
> - 想定量地知道某个函数需要执行多长时间，以及执行时间和输入 n 的相关性
> - 一个函数有两种不同实现（例如实现 A 使用了 `FixedThreadPool`，实现 B 使用了 `ForkJoinPool`），不知道哪种实现性能更好
>
> 尽管 JMH 是一个相当不错的 Micro Benchmark Framework，但很无奈的是网上能够找到的文档比较少，而官方也没有提供比较详细的文档，对使用造成了一定的障碍。但是有个好消息是官方的 ***[Code Sample](http://hg.openjdk.java.net/code-tools/jmh/file/tip/jmh-samples/src/main/java/org/openjdk/jmh/samples/)*** 写得非常浅显易懂，

## 导入Jar包

```xml
<dependency>
    <groupId>org.openjdk.jmh</groupId>
    <artifactId>jmh-core</artifactId>
    <version>1.21</version>
</dependency>
<dependency>
    <groupId>org.openjdk.jmh</groupId>
    <artifactId>jmh-generator-annprocess</artifactId>
    <version>1.21</version>
    <scope>provided</scope>
</dependency>
```

## 例子

我们来测试一下Snowflake的性能：

```java
@BenchmarkMode(Mode.Throughput)
@Warmup(iterations = 3, time = 1)
@Measurement(iterations = 4, time = 2)
@Threads(10)
@Fork(1)
@OutputTimeUnit(TimeUnit.SECONDS)
public class SnowflakeTest {
	private static final Snowflake[] SNOWFLAKES = IntStream.rangeClosed(1, 8)
														   .mapToObj(Snowflake::create)
														   .toArray(Snowflake[]::new);

	private static final AtomicLong ATOMIC_LONG = new AtomicLong(0);

	@Benchmark
	public long getId() {
		return SNOWFLAKES[(int) (ATOMIC_LONG.incrementAndGet() & (1 << 3) - 1)].nextId();
	}


	public static void main(String[] args) throws RunnerException {
		Options options = new OptionsBuilder().include(SnowflakeTest.class.getSimpleName())
											  .build();
		new Runner(options).run();
	}
}
```

输出结果：

```
Benchmark             Mode  Cnt         Score       Error  Units
SnowflakeTest.getId  thrpt    4  32751461.735 ± 88155.402  ops/s
```

注解都可以换成方法的方式在main方法中指定，比如这样：

```java
Options opt = new OptionsBuilder().include(SnowflakeTest.class.getSimpleName())
								  .forks(1)
								  .measurementIterations(3)
								  .measurementTime(TimeValue.seconds(1))
								  .warmupIterations(3)
								  .warmupTime(TimeValue.seconds(1))
								  .build();
```

## 注解分析

下面我把一些常用的注解全部分析一遍，看完之后你就可以得心应手的使用了。

### @BenchmarkMode

基准测试类型，对应Mode选项，可用于**类或者方法**上。 需要注意的是，这个注解的`value`是一个**数组**，可以把几种Mode集合在一起执行，如：`@BenchmarkMode({Mode.SampleTime, Mode.AverageTime})`

- `Throughput`：整体吞吐量，每秒执行了多少次调用。
- `AverageTime`：用的平均时间，每次操作的平均时间。
- `SampleTime`：随机取样，最后输出取样结果的分布，例如“99%的调用在xxx毫秒以内，99.99%的调用在xxx毫秒以内”。
- `SingleShotTime`：上模式都是默认一次 `iteration` 是 1s，唯有 `SingleShotTime` 是只运行一次。往往同时把 `warmup` 次数设为0，用于测试冷启动时的性能。
- `All`：上面的所有模式都执行一次，适用于内部JMH测试。

### @Warmup

预热所需要配置的一些基本测试参数。可用于**类或者方法**上。一般我们前几次进行程序测试的时候都会比较慢，所以要让程序进行几轮预热，保证测试的准确性。为什么需要预热？因为 JVM 的 JIT 机制的存在，**如果某个函数被调用多次之后**，**JVM 会尝试将其编译成为机器码从而提高执行速度**。所以为了让 benchmark 的结果更加接近真实情况就需要进行预热。

- `iterations`：预热的次数。
- `time`：每次预热的时间。
- `timeUnit`：时间的单位，默认秒。
- `batchSize`：批处理大小，每次操作调用几次方法。

### @Measurement

实际调用方法所需要配置的一些基本测试参数。可用于**类或者方法**上。参数和**@Warmup**一样。

### @Threads

每个进程中的测试线程，可用于**类或者方法**上。一般选择为cpu乘以2。如果配置了 `Threads.MAX` ，代表使用 `Runtime.getRuntime().availableProcessors()` 个线程。

### @Fork

进行 fork 的次数。可用于**类或者方法**上。如果 fork 数是2的话，则 JMH 会 fork 出两个进程来进行测试。

### @Benchmark

方法级注解，表示该方法是需要进行 benchmark 的对象，用法和 JUnit 的 @Test 类似。

### @Param

`@Param` 可以用来指定某项参数的多种情况。只能作用在**字段**上。特别适合用来测试一个函数在不同的参数输入的情况下的性能。使用该注解必须定义 `@State` 注解。

```java
@Param(value = {"a", "b", "c"})
private String param;
```

最后的结果可能是这个样子的：

```
Benchmark                    (param)  Mode  Cnt    Score   Error  Units
FirstBenchMark.stringConcat        a    ss       330.752          us/op
FirstBenchMark.stringConcat        b    ss       186.050          us/op
FirstBenchMark.stringConcat        c    ss       222.559          us/op
```

### @Setup&@TearDown

`@Setup`主要实现测试前的初始化工作，只能作用在**方法**上。用法和Junit一样。使用该注解必须定义 `@State` 注解。

`@TearDown`主要实现测试完成后的垃圾回收等工作，只能作用在**方法**上。用法和Junit一样。使用该注解必须定义 `@State` 注解。

这两个注解都有一个 `Level` 的枚举value，它有三个值（默认的是Trial）：

- `Trial`：在每次Benchmark的之前/之后执行。
- `Iteration`：在每次Benchmark的`iteration`的之前/之后执行。
- `Invocation`：每次调用Benchmark标记的方法之前/之后都会执行。

可见，Level的粒度从`Trial`到`Invocation`越来越细。

```
@TearDown(Level.Iteration)
public void check() {
    assert x > Math.PI : "Nothing changed?";
}

@Benchmark
public void measureRight() {
    x++;
}

@Benchmark
public void measureWrong() {
    double x = 0;
    x++;
}
```

### @State

该注解定义了给定类实例的可用范围。JMH可以在多线程同时运行的环境测试，因此需要选择正确的状态。只能作用在**类**上。被该注解定义的类通常作为 `@Benchmark` 标记的方法的入参，JMH根据scope来进行实例化和共享操作，当然`@State`可以被继承使用，如果父类定义了该注解，子类则无需定义。

Scope有如下3种值：

- `Benchmark`：同一个benchmark在多个线程之间共享实例。
- `Group`：同一个线程在同一个group里共享实例。group定义参考注解 `@Group` 。
- `Thread`：不同线程之间的实例不共享。

首先说一下`Benchmark`，对于同一个`@Benchmark`，所有线程共享实例，也就是只会new Person 1次

```java
@State(Scope.Benchmark)
public static class BenchmarkState {
    Person person = new Person(21, "ben", "benchmark");
    volatile double x = Math.PI;
}

@Benchmark
public void measureShared(BenchmarkState state) {
    state.x++;
}

public static void main(String[] args) throws RunnerException {
    Options opt = new OptionsBuilder()
            .include(JMHSample_03_States.class.getSimpleName())
            .threads(8)
            .warmupTime(TimeValue.seconds(1))
            .measurementTime(TimeValue.seconds(1))
            .forks(1)
            .build();

    new Runner(opt).run();
}
```

再说一下`Thread`，这个比较好理解，不同线程之间的实例不共享。对于上面我们设定的线程数为8个，也就是会new Person 8次。

```java
@State(Scope.Thread)
public static class ThreadState {
    Person person = new Person(21, "ben", "thread");
    volatile double x = Math.PI;
}

@Benchmark
public void measureUnshared(ThreadState state) {
    state.x++;
}
```

而对于Group来说，同一个group的作为一个执行单元，所以 `measureGroup` 和 `measureGroup2` 共享8个线程，所以一个方法也就会执行new Person 4次。

```java
@State(Scope.Group)
public static class GroupState {
    Person person = new Person(21, "ben", "group");
    volatile double x = Math.PI;
}

@Benchmark
@Group("ben")
public void measureGroup(GroupState state) {
    state.x++;
}

@Benchmark
@Group("ben")
public void measureGroup2(GroupState state) {
    state.x++;
}
```

### @Group

结合`@Benchmark`一起使用，把多个基准方法归为一类，只能作用在**方法**上。同一个组中的所有测试设置相同的名称(否则这些测试将独立运行——没有任何警告提示！)

### @GroupThreads

定义了多少个线程参与在组中运行基准方法。只能作用在**方法**上。

### @OutputTimeUnit

这个比较简单了，基准测试结果的时间类型。可用于**类或者方法**上。一般选择秒、毫秒、微秒。

### @CompilerControl

该注解可以控制方法编译的行为，可用于**类或者方法或者构造函数**上。它内部有6种模式，这里我们只关心三种重要的模式：

- `CompilerControl.Mode.INLINE`：强制使用内联。
- `CompilerControl.Mode.DONT_INLINE`：禁止使用内联。
- `CompilerControl.Mode.EXCLUDE`：禁止编译方法。

```java
public void target_blank() {
}

@CompilerControl(CompilerControl.Mode.DONT_INLINE)
public void target_dontInline() {
}

@CompilerControl(CompilerControl.Mode.INLINE)
public void target_inline() {
}

@CompilerControl(CompilerControl.Mode.EXCLUDE)
public void target_exclude() {
}

@Benchmark
public void baseline() {
}

@Benchmark
public void blank() {
    target_blank();
}

@Benchmark
public void dontinline() {
    target_dontInline();
}

@Benchmark
public void inline() {
    target_inline();
}

@Benchmark
public void exclude() {
    target_exclude();
}
```

最后得出的结果也表名，使用内联优化会影响实际的结果：

```
Benchmark                                Mode  Cnt   Score   Error  Units
JMHSample_16_CompilerControl.baseline    avgt    3   0.338 ± 0.475  ns/op
JMHSample_16_CompilerControl.blank       avgt    3   0.343 ± 0.213  ns/op
JMHSample_16_CompilerControl.dontinline  avgt    3   2.247 ± 0.421  ns/op
JMHSample_16_CompilerControl.exclude     avgt    3  82.814 ± 7.333  ns/op
JMHSample_16_CompilerControl.inline      avgt    3   0.322 ± 0.023  ns/op
```

## 避免JIT优化

我们在测试的时候，一定要避免JIT优化。对于有一些代码，编译器可以推导出一些计算是多余的，并且完全消除它们。 如果我们的基准测试里有部分代码被清除了，那测试的结果就不准确了。比如下面这一段代码：

```java
private double x = Math.PI;

@Benchmark
public void baseline() {
    // do nothing, this is a baseline
}

@Benchmark
public void measureWrong() {
    // This is wrong: result is not used and the entire computation is optimized away.
    Math.log(x);
}

@Benchmark
public double measureRight() {
    // This is correct: the result is being used.
    return Math.log(x);
}
```

由于 `measureWrong` 方法被编译器优化了，导致效果和 `baseline` 方法一样变成了空方法，结果也证实了这一点：

```
Benchmark                           Mode  Cnt   Score   Error  Units
JMHSample_08_DeadCode.baseline      avgt    5   0.311 ± 0.018  ns/op
JMHSample_08_DeadCode.measureRight  avgt    5  23.702 ± 0.320  ns/op
JMHSample_08_DeadCode.measureWrong  avgt    5   0.306 ± 0.003  ns/op
```

如果我们想方法返回值还是`void`，但是需要让`Math.log(x)`的耗时加入到基准运算中，我们可以使用JMH提供给我们的类 `Blackhole` ，使用它的 `consume`来避免JIT的优化消除。

```java
@Benchmark
public void measureRight_2(Blackhole bh) {
    bh.consume(Math.log(x));
}
```

但是有返回值的方法就不会被优化了吗？你想的太多了。。。重新改改刚才的代码，让字段 `x` 变成final的。

```java
private final double x = Math.PI;
```

运行后的结果发现 `measureRight` 被JIT进行了优化，从 `23.7ns/op` 降到了 `2.5ns/op`

```
JMHSample_08_DeadCode.measureRight    avgt    5  2.587 ± 0.081  ns/op
```

当然 `Math.log(Math.PI );` 这种返回写法和字段定义成final一样，都会被进行优化。

优化的原因是因为JVM认为每次计算的结果都是相同的，于是就会把相同代码移到了JMH的循环之外。

**结论：**

1. 基准测试方法一定不要返回`void`。
2. 如果要使用`void`返回，可以使用 `Blackhole` 的 `consume` 来避免JIT的优化消除。
3. 计算**不要引用常量**，否则会被优化到JMH的循环之外。

## IDEA插件

在插件中直接搜JMH，该插件可以右键生成JMH方法，不用写main方法也能执行`@Benchmark`的方法

## 参考

> ***[http://benjaminwhx.com/2018/06/15/%E4%BD%BF%E7%94%A8JMH%E5%81%9A%E5%9F%BA%E5%87%86%E6%B5%8B%E8%AF%95/](http://benjaminwhx.com/2018/06/15/%E4%BD%BF%E7%94%A8JMH%E5%81%9A%E5%9F%BA%E5%87%86%E6%B5%8B%E8%AF%95/)***

# Gatling性能测试

> 性能测试的两种类型，负载测试和压力测试：
> - **负载测试（Load Testing）：**负载测试是一种主要为了测试软件系统是否达到需求文档设计的目标，譬如软件在一定时期内，最大支持多少并发用户数，软件请求出错率等，测试的主要是软件系统的性能。
> - **压力测试（Stress Testing）：**压力测试主要是为了测试硬件系统是否达到需求文档设计的性能目标，譬如在一定时期内，系统的cpu利用率，内存使用率，磁盘I/O吞吐率，网络吞吐量等，压力测试和负载测试最大的差别在于测试目的不同。

## Gatling 简介

![](https://cdn.yangbingdong.com/img/spring-boot-learning/gatling-logo.png)

Gatling 是一个功能强大的负载测试工具。它是为易用性、可维护性和高性能而设计的。

开箱即用，Gatling 带有对 HTTP 协议的出色支持，使其成为负载测试任何 HTTP 服务器的首选工具。由于核心引擎实际上是协议不可知的，所以完全可以实现对其他协议的支持，例如，Gatling 目前也提供JMS 支持。

只要底层协议（如 HTTP）能够以非阻塞的方式实现，Gatling 的架构就是异步的。这种架构可以将虚拟用户作为消息而不是专用线程来实现。因此，运行数千个并发的虚拟用户不是问题。

## 使用Recorder快速开始

官方提供了GUI界面的录制器，可以监听对应端口记录请求操作并转化为Scala脚本

1、进入 *[下载页面](https://gatling.io/download/)* 下载最新版本
2、解压并进入 `$GATLING_HOME/bin` (`$GATLING_HOME`为解压目录)，运行`recorder.sh`
![](https://cdn.yangbingdong.com/img/spring-boot-learning/recorder1.png)

* 上图监听8000端口（若被占用请更换端口），需要在浏览器设置代理，以FireFox为例：
  ![](https://cdn.yangbingdong.com/img/spring-boot-learning/firefox-proxy.jpg)

* `Output folder`为Scala脚本输出路径，例如设置为 `/home/ybd/data/application/gatling-charts-highcharts-bundle-2.3.0/user-files/simulations`，会在该路经下面生成一个`RecordedSimulation.scala`的文件（上面指定的Class Name）：
  ![](https://cdn.yangbingdong.com/img/spring-boot-learning/scala-script-location.jpg)


3、点击`record`并在Firefox进行相应操作，然后点击`Stop`，会生成类似下面的脚本：

```java
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

![](https://cdn.yangbingdong.com/img/spring-boot-learning/terminal-gatling-test1.jpg)

![](https://cdn.yangbingdong.com/img/spring-boot-learning/terminal-gatling-test2.jpg)

注意看上图最下面那一行，就是生成测试结果的入口。

具体请看官方文档：*[https://gatling.io/docs/current/quickstart](https://gatling.io/docs/current/quickstart)*

## 使用IDEA编写

1、首先安装Scala插件：

![](https://cdn.yangbingdong.com/img/spring-boot-learning/scala-plugin.jpg)

2、安装 scala SDK：

![](https://cdn.yangbingdong.com/img/spring-boot-learning/add-scala-sdk02.jpg)

![](https://cdn.yangbingdong.com/img/spring-boot-learning/add-scala-sdk01.jpg)

3、编写测试脚本

```java
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

```xml
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

```shell
mvn gatling:execute
```
![](https://cdn.yangbingdong.com/img/spring-boot-learning/idea-gatling-test.jpg)

我们打开结果中的`index.html`：

![](https://cdn.yangbingdong.com/img/spring-boot-learning/gatling-test-result1.jpg)

![](https://cdn.yangbingdong.com/img/spring-boot-learning/gatling-test-result2.jpg)

## 遇到问题

途中出现了以下错误

![](https://cdn.yangbingdong.com/img/spring-boot-learning/gatling-error1.jpg)

![](https://cdn.yangbingdong.com/img/spring-boot-learning/gatling-error2.jpg)

这是由于**使用了Log4J2**，把Gatling自带的Logback排除了（同一个项目），把`<exclusions>`这一段注释掉就没问题了：

```xml
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

# ContPerf

ContiPerf是一个轻量级的**测试**工具，基于**JUnit**4 开发，可用于**接口**级的**性能测试**，快速压测。

引入依赖:

```xml
<!-- 性能测试 -->
<dependency>
    <groupId>org.databene</groupId>
    <artifactId>contiperf</artifactId>
    <scope>test</scope>
    <version>2.1.0</version>
</dependency>
```

## ContiPerf介绍

可以指定在线程数量和执行次数，通过限制最大时间和平均执行时间来进行效率测试，一个简单的例子如下：

```java
public class ContiPerfTest { 
    @Rule 
    public ContiPerfRule i = new ContiPerfRule(); 
   
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

```java
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

## 主要参数介绍

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

## 测试结果

测试结果除了会在控制台显示之外，还会生成一个结果文件`target/contiperf-report/index.html`

![](https://cdn.yangbingdong.com/img/spring-boot-learning/contiperf-report.jpg)