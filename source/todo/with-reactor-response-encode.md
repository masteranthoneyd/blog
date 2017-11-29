# 使用 Reactor 进行反应式编程

> 反应式编程（`Reactive Programming`）这种新的编程范式越来越受到开发人员的欢迎。在 Java 社区中比较流行的是 `RxJava` 和 `RxJava 2`。本篇要介绍的是另外一个新的反应式编程库 Reactor。

# 反应式编程介绍

反应式编程来源于数据流和变化的传播，意味着由底层的执行模型负责通过数据流来自动传播变化。比如求值一个简单的表达式 c=a+b，当 a 或者 b 的值**发生变化**时，**传统的编程范式**需要对 a+b 进行**重新计算**来得到 c 的值。如果使用**反应式编程**，当 a 或者 b 的值**发生变化**时，c 的值会**自动更新**。反应式编程最早由 .NET 平台上的 `Reactive Extensions` (`Rx`) 库来实现。后来迁移到 Java 平台之后就产生了著名的 `RxJava` 库，并产生了很多其他编程语言上的对应实现。在这些实现的基础上产生了后来的反应式流（`Reactive Streams`）规范。该规范定义了反应式流的相关接口，并将集成到 **Java 9** 中。

在传统的编程范式中，我们一般通过迭代器（`Iterator`）模式来遍历一个序列。这种遍历方式是由**调用者来控制节奏**的，采用的是**拉**的方式。每次由调用者通过 next()方法来获取序列中的下一个值。使用**反应式流**时采用的则是**推**的方式，即常见的**发布者-订阅者模式**。当发布者有新的数据产生时，这些数据会被**推送**到**订阅者**来进行处理。在反应式流上可以添加各种不同的操作来对数据进行处理，形成数据处理链。这个以声明式的方式添加的处理链只在订阅者进行订阅操作时才会真正执行。

反应式流中第一个重要概念是**负压**（`backpressure`）。在基本的消息推送模式中，当消息发布者产生数据的**速度过快**时，会使得消息订阅者的处理速度**无法跟上产生的速度**，从而给订阅者造成很大的**压力**。当压力过大时，有可能造成订阅者本身的**奔溃**，所产生的级联效应甚至可能造成整个系统的**瘫痪**。**负压**的作用在于**提供一种从订阅者到生产者的反馈渠道**。订阅者可以通过 `request()`方法来**声明其一次所能处理的消息数量**，**而生产者就只会产生相应数量的消息**，直到下一次 `request()`方法调用。这实际上变成了**推拉结合的模式**。

# Reactor 简介

前面提到的 `RxJava` 库是 JVM 上反应式编程的先驱，也是反应式流规范的基础。`RxJava 2` 在 `RxJava` 的基础上做了很多的更新。不过 `RxJava` 库也有其不足的地方。`RxJava` 产生于反应式流规范之前，虽然可以和反应式流的接口进行转换，但是由于底层实现的原因，使用起来并不是很直观。`RxJava 2` 在设计和实现时考虑到了与规范的整合，不过为了保持与 `RxJava` 的兼容性，很多地方在使用时也并不直观。`Reactor` 则是**完全基于反应式流规范设计和实现的库**，没有 `RxJava` 那样的历史包袱，在使用上更加的直观易懂。`Reactor` 也是 Spring 5 中反应式编程的基础。学习和掌握 `Reactor` 可以更好地理解 Spring 5 中的相关概念。

在 Java 程序中使用 `Reactor` 库非常的简单，只需要通过 Maven 或 Gradle 来添加对 `io.projectreactor:reactor-core` 的依赖即可，目前的版本是 `3.1.2.RELEASE`：

```
<dependencies>
        <dependency>
            <groupId>io.projectreactor</groupId>
            <artifactId>reactor-core</artifactId>
            <version>3.1.2.RELEASE</version>
        </dependency>
    </dependencies>
```

# Flux 和 Mono

`Flux` 和 `Mono` 是 `Reactor` 中的两个基本概念。`Flux` 表示的是**包含 0 到 N 个元素**的**异步**序列。在该序列中可以包含**三种不同类型**的消息通知：正常的包含元素的消息、序列结束的消息和序列出错的消息。当消息通知产生时，**订阅者**中对应的方法 `onNext()`, `onComplete()`和 `onError()`会被调用。`Mono` 表示的是**包含 0 或者 1 个元素**的**异步**序列。该序列中同样可以包含与 Flux 相同的三种类型的消息通知。`Flux` 和 `Mono` 之间可以进行**转换**。对一个 `Flux` 序列进行计数操作，得到的结果是一个 `Mono<Long>`对象。把两个 `Mono` 序列合并在一起，得到的是一个 `Flux` 对象。

## 创建 Flux

有多种不同的方式可以创建 Flux 序列。

### Flux 类的静态方法

第一种方式是通过 Flux 类中的静态方法。

- `just()`：可以指定序列中包含的全部元素。创建出来的 Flux 序列在发布这些元素之后会自动结束。
- `fromArray()`，`fromIterable()`和 `fromStream()`：可以从一个**数组**、`Iterable` 对象或 `Stream` 对象中创建 `Flux` 对象。
- `empty()`：创建一个不包含任何元素，只发布结束消息的序列。
- `error(Throwable error)`：创建一个只包含错误消息的序列。
- `never()`：创建一个不包含任何消息通知的序列。
- `range(int start, int count)`：创建包含从 start 起始的 count 个数量的 Integer 对象的序列。
- `interval(Duration period)`和 `interval(Duration delay, Duration period)`：创建一个包含了从 0 开始递增的 Long 对象的序列。其中包含的元素按照指定的间隔来发布。除了间隔时间之外，还可以指定起始元素发布之前的延迟时间。

代码清单 1 中给出了上述这些方法的使用示例。

**清单 1. 通过 Flux 类的静态方法创建 Flux 序列**

```
	public static void main(String[] args) throws InterruptedException {
		generateSimpleFlux();
	}

	private static void generateSimpleFlux() throws InterruptedException {
		Flux.just("Hello", "World").subscribe(System.out::println);
		Integer[] array = {1, 2, 3};
		Flux.fromArray(array).subscribe(System.out::println);
		Flux.fromStream(Stream.of(array)).subscribe(System.out::println);
		Flux.fromIterable(Arrays.asList(array)).subscribe(System.out::println);
		Flux.empty().subscribe(System.out::println);
		Flux.range(1, 10).subscribe(System.out::println);
		Flux.interval(Duration.ofSeconds(1)).subscribe(System.out::println);
		// Flux.interval(Duration.of(1, ChronoUnit.SECONDS)).subscribe(System.out::println);
		TimeUnit.SECONDS.sleep(5);
	}
```

上面的这些静态方法适合于**简单**的序列生成，当序列的生成**需要复杂的逻辑**时，则应该使用 `generate()` 或 `create()` 方法。

### generate()方法

`generate()`方法通过**同步**和**逐一**的方式来产生 `Flux` 序列。序列的产生是通过调用所提供的 `SynchronousSink` 对象的 `next()`，`complete()`和 `error(Throwable)`方法来完成的。逐一生成的含义是在具体的生成逻辑中，next()方法只能最多被调用一次。在有些情况下，序列的生成可能是有状态的，需要用到某些状态对象。此时可以使用 generate()方法的另外一种形式 generate(Callable<S> stateSupplier, BiFunction<S,SynchronousSink<T>,S> generator)，其中 stateSupplier 用来提供初始的状态对象。在进行序列生成时，状态对象会作为 generator 使用的第一个参数传入，可以在对应的逻辑中对该状态对象进行修改以供下一次生成时使用。

在代码清单 2中，第一个序列的生成逻辑中通过 next()方法产生一个简单的值，然后通过 complete()方法来结束该序列。如果不调用 complete()方法，所产生的是一个无限序列。第二个序列的生成逻辑中的状态对象是一个 ArrayList 对象。实际产生的值是一个随机数。产生的随机数被添加到 ArrayList 中。当产生了 10 个数时，通过 complete()方法来结束序列。

**清单 2. 使用 generate()方法生成 Flux 序列**