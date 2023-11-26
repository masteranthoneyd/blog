---
title: Java 并发拾遗-并发工具(下)
date: 2019-9-15 17:04:25
categories: [Programming, Java, Concurrent]
tags: [Java, Concurrent]
---




![](https://oldcdn.yangbingdong.com/img/concurrent/java-concurrent-part4-banner-min.png)

# Preface

> 这一篇关于线程池与Future相关.

<!--more-->

# Executor与线程池

多线程应用中, 创建线程是必然的, 但是在 Java 中创建一个线程，却需要调用操作系统内核的 API，然后操作系统要为线程分配一系列的资源，这个成本就很高了，所以**线程是一个重量级的对象，应该避免频繁创建和销毁**.

一般采用线程池, 线程池是一种**生产者 - 消费者模式**, 下面是一个简单的线程池模型:

```java
//简化的线程池，仅用来说明工作原理
class MyThreadPool{
  //利用阻塞队列实现生产者-消费者模式
  BlockingQueue<Runnable> workQueue;
  //保存内部工作线程
  List<WorkerThread> threads 
    = new ArrayList<>();
  // 构造方法
  MyThreadPool(int poolSize, 
    BlockingQueue<Runnable> workQueue){
    this.workQueue = workQueue;
    // 创建工作线程
    for(int idx=0; idx<poolSize; idx++){
      WorkerThread work = new WorkerThread();
      work.start();
      threads.add(work);
    }
  }
  // 提交任务
  void execute(Runnable command){
    workQueue.put(command);
  }
  // 工作线程负责消费任务，并执行任务
  class WorkerThread extends Thread{
    public void run() {
      //循环取任务并执行
      while(true){ ①
        Runnable task = workQueue.take();
        task.run();
      } 
    }
  }  
}

/** 下面是使用示例 **/
// 创建有界阻塞队列
BlockingQueue<Runnable> workQueue = 
  new LinkedBlockingQueue<>(2);
// 创建线程池  
MyThreadPool pool = new MyThreadPool(
  10, workQueue);
// 提交任务  
pool.execute(()->{
    System.out.println("hello");
});
```

Java 中线程池实现的核心原理也是这样, 当然, 功能更强大也更复杂, Java 提供的线程池相关的工具类中，最核心的是 `ThreadPoolExecutor`. 来看一下它的构造函数:

```java
ThreadPoolExecutor(
  int corePoolSize,
  int maximumPoolSize,
  long keepAliveTime,
  TimeUnit unit,
  BlockingQueue<Runnable> workQueue,
  ThreadFactory threadFactory,
  RejectedExecutionHandler handler) 
```

* `corePoolSize`：表示线程池保有的最小线程数。有些项目很闲，但是也不能把人都撤了，至少要留 `corePoolSize` 个人坚守阵地。
* `maximumPoolSize`：表示线程池创建的最大线程数。当项目很忙时，就需要加人，但是也不能无限制地加，最多就加到 `maximumPoolSize` 个人。当项目闲下来时，就要撤人了，最多能撤到 `corePoolSize` 个人。
* `keepAliveTime` & `unit`：上面提到项目根据忙闲来增减人员，那在编程世界里，如何定义忙和闲呢？很简单，一个线程如果在一段时间内，都没有执行任务，说明很闲，`keepAliveTime` 和 `unit` 就是用来定义这个“一段时间”的参数。也就是说，如果一个线程空闲了`keepAliveTime` & `unit` 这么久，而且线程池的线程数大于 `corePoolSize` ，那么这个空闲的线程就要被回收了。
* `workQueue`：工作队列，和上面示例代码的工作队列同义。
* `threadFactory`：通过这个参数你可以自定义如何创建线程，例如你可以给线程指定一个有意义的名字。
* `handler`：通过这个参数你可以自定义任务的拒绝策略。如果线程池中所有的线程都在忙碌，并且工作队列也满了（前提是工作队列是有界队列），那么此时提交任务，线程池就会拒绝接收。至于拒绝的策略，你可以通过 `handler` 这个参数来指定。`ThreadPoolExecutor` 已经提供了以下 4 种策略。`CallerRunsPolicy`：提交任务的线程自己去执行该任务。`AbortPolicy`：默认的拒绝策略，会 throws `RejectedExecutionException`。`DiscardPolicy`：直接丢弃任务，没有任何异常抛出。`DiscardOldestPolicy`：丢弃最老的任务，其实就是把最早进入工作队列的任务丢弃，然后把新任务加入到工作队列。

Java 在 1.6 版本还增加了 `allowCoreThreadTimeOut(boolean value)` 方法，它可以让所有线程都支持超时，这意味着如果项目很闲，就会将项目组的成员都撤走。

考虑到 `ThreadPoolExecutor` 的构造函数实在是有些复杂，所以 Java 并发包里提供了一个线程池的静态工厂类 `Executors`，利用 `Executors` 你可以快速创建线程池。不过目前大厂的编码规范中基本上都**不建议使用 `Executors`** 了.

使用 `ThreadPoolExecutor` 要注意几个问题:

第一, `Executors` 提供的很多方法默认使用的都是无界的 `LinkedBlockingQueue`，高负载情境下，**无界队列很容易导致 OOM**，而 OOM 会导致所有请求都无法处理，这是致命问题。所以**强烈建议使用有界队列**。

第二, 使用有界队列，当任务过多时，线程池会触发执行拒绝策略，线程池默认的拒绝策略会 throw `RejectedExecutionException` 这是个运行时异常，对于运行时异常编译器并不强制 catch 它，所以开发人员很容易忽略。因此**默认拒绝策略要慎重使用**。如果线程池处理的任务非常重要，建议自定义自己的拒绝策略；并且在实际工作中，自定义的拒绝策略往往和降级策略配合使用。

第三, 使用线程池，还要注意**异常处理的问题**，例如通过 `ThreadPoolExecutor` 对象的 `execute()` 方法提交任务时，如果任务在执行的过程中出现运行时异常，会导致执行任务的线程终止；不过，最致命的是任务虽然异常了，但是你却获取不到任何通知，这会让你误以为任务都执行得很正常。虽然线程池提供了很多用于异常处理的方法，但是最稳妥和简单的方案还是捕获所有异常并按需处理:

```java
try {
  //业务逻辑
} catch (RuntimeException x) {
  //按需处理
} catch (Throwable x) {
  //按需处理
} 
```

# Future与FutureTask

`ThreadPoolExecutor` 除了 `execute()` 方法执行任务, 还提供的 3 个 `submit()` 方法和 1 个 `FutureTask` 工具类来支持获得任务执行结果的需求:

```java
// 提交Runnable任务
Future<?> 
  submit(Runnable task);
// 提交Callable任务
<T> Future<T> 
  submit(Callable<T> task);
// 提交Runnable任务及结果引用  
<T> Future<T> 
  submit(Runnable task, T result);
```

* 第一个 `submit` 由于传进去的是 `Runnable`, 所以返回的 `Future` 仅可以用来断言任务已经结束了，类似于 Thread.join()。

* 第二个 `submit` 返回的 `Future` 对象可以通过调用其 `get()` 方法来获取任务的执行结果。

* 第三个 `submit`, 这个方法很有意思，假设这个方法返回的 `Future` 对象是 `f`，`f.get()` 的返回值就是传给 `submit()` 方法的参数 `result`:

  ```java
  ExecutorService executor 
    = Executors.newFixedThreadPool(1);
  // 创建Result对象r
  Result r = new Result();
  r.setAAA(a);
  // 提交任务
  Future<Result> future = 
    executor.submit(new Task(r), r);  
  Result fr = future.get();
  // 下面等式成立
  fr === r;
  fr.getAAA() === a;
  fr.getXXX() === x
  
  class Task implements Runnable{
    Result r;
    //通过构造函数传入result
    Task(Result r){
      this.r = r;
    }
    void run() {
      //可以操作result
      a = r.getAAA();
      r.setXXX(x);
    }
  }
  ```

  

上面三个方法返回的都是 `Future` 接口, `Future` 有5个方法:

```java
// 取消任务
boolean cancel(
  boolean mayInterruptIfRunning);
// 判断任务是否已取消  
boolean isCancelled();
// 判断任务是否已结束
boolean isDone();
// 获得任务执行结果
get();
// 获得任务执行结果，支持超时
get(long timeout, TimeUnit unit);
```

其中这两个 `get()` 方法都是**阻塞**式的.

下面来介绍 `FutureTask` 工具类。前面我们提到的 `Future` 是一个接口，而 `FutureTask` 是一个实实在在的工具类:

```java
FutureTask(Callable<V> callable);
FutureTask(Runnable runnable, V result);
```

`FutureTask` 实现了 `Runnable` 和 `Future` 接口，由于实现了 `Runnable` 接口，所以可以将 `FutureTask` 对象作为任务提交给 `ThreadPoolExecutor` 去执行，也可以直接被 `Thread` 执行；又因为实现了 `Future` 接口，所以也能用来获得任务的执行结果。下面的示例代码是将 `FutureTask` 对象提交给 `ThreadPoolExecutor` 去执行。

```java
// 创建FutureTask
FutureTask<Integer> futureTask
  = new FutureTask<>(()-> 1+2);
// 创建线程池
ExecutorService es = 
  Executors.newCachedThreadPool();
// 提交FutureTask 
es.submit(futureTask);
// 获取计算结果
Integer result = futureTask.get();


// 创建FutureTask
FutureTask<Integer> futureTask
  = new FutureTask<>(()-> 1+2);
// 创建并启动线程
Thread T1 = new Thread(futureTask);
T1.start();
// 获取计算结果
Integer result = futureTask.get();
```

# CompletableFuture

`CompletableFuture` 是 JDK 1.8 推出的异步编程工具类, 方法比较多也比较复杂, 但是灵活性很高.

先来举个烧茶的例子, 首先需要先完成分工方案，在下面的程序中，我们分了 3 个任务：任务 1 负责洗水壶、烧开水，任务 2 负责洗茶壶、洗茶杯和拿茶叶，任务 3 负责泡茶。其中任务 3 要等待任务 1 和任务 2 都完成后才能开始。

![](https://oldcdn.yangbingdong.com/img/concurrent/java-concurrent-part4-tea-process.png)

使用 `CompletableFuture` 完成:

```java
//任务1：洗水壶->烧开水
CompletableFuture<Void> f1 = 
  CompletableFuture.runAsync(()->{
  System.out.println("T1:洗水壶...");
  sleep(1, TimeUnit.SECONDS);

  System.out.println("T1:烧开水...");
  sleep(15, TimeUnit.SECONDS);
});
//任务2：洗茶壶->洗茶杯->拿茶叶
CompletableFuture<String> f2 = 
  CompletableFuture.supplyAsync(()->{
  System.out.println("T2:洗茶壶...");
  sleep(1, TimeUnit.SECONDS);

  System.out.println("T2:洗茶杯...");
  sleep(2, TimeUnit.SECONDS);

  System.out.println("T2:拿茶叶...");
  sleep(1, TimeUnit.SECONDS);
  return "龙井";
});
//任务3：任务1和任务2完成后执行：泡茶
CompletableFuture<String> f3 = 
  f1.thenCombine(f2, (__, tf)->{
    System.out.println("T1:拿到茶叶:" + tf);
    System.out.println("T1:泡茶...");
    return "上茶:" + tf;
  });
//等待任务3执行结果
System.out.println(f3.join());

void sleep(int t, TimeUnit u) {
  try {
    u.sleep(t);
  }catch(InterruptedException e){}
}
// 一次执行结果：
T1:洗水壶...
T2:洗茶壶...
T1:烧开水...
T2:洗茶杯...
T2:拿茶叶...
T1:拿到茶叶:龙井
T1:泡茶...
上茶:龙井
```

## 创建 CompletableFuture 对象

先来看一下4个构造器:

```java
//使用默认线程池
static CompletableFuture<Void> 
  runAsync(Runnable runnable)
static <U> CompletableFuture<U> 
  supplyAsync(Supplier<U> supplier)
//可以指定线程池  
static CompletableFuture<Void> 
  runAsync(Runnable runnable, Executor executor)
static <U> CompletableFuture<U> 
  supplyAsync(Supplier<U> supplier, Executor executor)  
```

`runAsync(Runnable)` 与 `supplyAsync(Supplier)` 的区别是前者没有返回值, 后者**有返回值**. 而前两个方法和后两个方法的区别在于：后两个方法可以**指定线程池参数**。

默认情况下 `CompletableFuture` 会使用公共的 `ForkJoinPool` 线程池，这个线程池默认创建的线程数是 CPU 的核数（也可以通过 JVM 参数: `-Djava.util.concurrent.ForkJoinPool.common.parallelism` 来设置 `ForkJoinPool` 线程池的线程数）。如果所有 `CompletableFuture` 共享一个线程池，那么一旦有任务执行一些很慢的 I/O 操作，就会导致线程池中所有线程都阻塞在 I/O 操作上，从而造成**线程饥饿**，进而影响整个系统的性能。所以，强烈建议**要根据不同的业务类型创建不同的线程池，以避免互相干扰**。

创建完 `CompletableFuture` 对象之后，会自动地异步执行 `runnable.run()` 方法或者 `supplier.get()` 方法，对于一个异步操作，需要关注两个问题：一个是异步操作什么时候结束，另一个是如何获取异步操作的执行结果。因为 `CompletableFuture` 类实现了 `Future` 接口，所以这两个问题你都可以通过 `Future` 接口来解决。另外，`CompletableFuture` 类还实现了 `CompletionStage` 接口，这个接口内容实在是太丰富了，在 1.8 版本里有 40 个方法

## 如何理解 CompletionStage 接口

可分为: **串行关系**, **AND 汇聚关系**, **OR 汇聚关系**(依赖的任务只要有一个完成就可以执行当前任务)以及**异常处理**.

一下提到的方法一般有三个"重载", 比如 `thenAccept(fn)`, 另外还有两个是 `thenAcceptAsync(fn)` 和 `thenAcceptAsync(fn, executor)`. 第一个使用前一个函数所在的同一个线程, 后两个则是异步执行, 没有指定线程池, 则使用的是 `ForkJoinPool`, 后者使用指定的线程池.

### 描述串行关系

`CompletionStage` 接口里面描述串行关系，主要是 `thenApply`、`thenAccept`、`thenRun` 和 `thenCompose` 这四个系列的接口:

```java
CompletionStage<R> thenApply(fn);
CompletionStage<Void> thenAccept(consumer);
CompletionStage<Void> thenRun(action);
CompletionStage<R> thenCompose(fn);
```

* `thenApply` 接收的是 `Function<T, R>`, 所以这个方法既**能接收参数也支持返回值**;
* `thenAccept` 接收的是 `Consumer<T>`, **只能接收参数没有返回值**, 所以返回的是 `CompletionStage<Void>`;
* `thenRun` 接收的是 `Runnable`, **不接受参数也不返回**;
* `thenCompose` 与 `thenApply` 类似, 不同的在于它接收的是 `Function<T, ? extends CompletionStage<U>>`, 返回值需要是 `CompletionStage<U>` 或其子类.

示例:

```java
CompletableFuture<String> f0 = 
  CompletableFuture.supplyAsync(
    () -> "Hello World")      //①
  .thenApply(s -> s + " QQ")  //②
  .thenApply(String::toUpperCase);//③

System.out.println(f0.join());
//输出结果
HELLO WORLD QQ
```

虽然这是一个异步流程，但任务①②③却是串行执行的，②依赖①的执行结果，③依赖②的执行结果。

### 描述 AND 汇聚关系

方法签名:

```java
CompletionStage<R> thenCombine(other, fn);
CompletionStage<Void> thenAcceptBoth(other, consumer);
CompletionStage<Void> runAfterBoth(other, action);
```

这些接口的区别也是源自 `fn`、`consumer`、`action` 这三个核心参数不同。它们的使用你可以参考上面烧水泡茶的实现程序，这里就不赘述了。

### 描述 OR 汇聚关系

OR 汇聚关系指的是依赖的任务只要有一个完成就可以执行当前任务.

```java
CompletionStage<R> thenCombine(other, fn);
CompletionStage<Void> thenAcceptBoth(other, consumer);
CompletionStage<Void> runAfterBoth(other, action);
```

这些接口的区别也是源自 fn、consumer、action 这三个核心参数不同。

### 异常处理

虽然上面我们提到的 `fn`、`consumer`、`action` 它们的核心方法都不允许抛出可检查异常，**但是却无法限制它们抛出运行时异常**，例如下面的代码，执行 7/0 就会出现除零错误这个运行时异常。非异步编程里面，我们可以使用 `try{}catch{}` 来捕获并处理异常，那在异步编程里面，异常该如何处理呢？

```java
CompletableFuture<Integer> 
  f0 = CompletableFuture.
    .supplyAsync(()->(7/0))
    .thenApply(r->r*10);
System.out.println(f0.join());
```

`CompletionStage` 接口给我们提供的方案非常简单，比 `try{}catch{}` 还要简单，下面是相关的方法，使用这些方法进行异常处理和串行操作是一样的，都支持链式编程方式:

```java
CompletionStage exceptionally(fn);
CompletionStage<R> whenComplete(consumer);
CompletionStage<R> whenCompleteAsync(consumer);
CompletionStage<R> handle(fn);
CompletionStage<R> handleAsync(fn);
```

下面的示例代码展示了如何使用 `exceptionally()` 方法来处理异常，`exceptionally()` 的使用非常类似于 `try{}catch{}` 中的 `catch{}`，但是由于支持链式编程方式，所以相对更简单:

```java
CompletableFuture<Integer> 
  f0 = CompletableFuture
    .supplyAsync(()->7/0))
    .thenApply(r->r*10)
    .exceptionally(e->0);
System.out.println(f0.join());
```

既然有 `try{}catch{}`，那就一定还有 `try{}finally{}`，`whenComplete()` 和 `handle()` 系列方法就类似于 `try{}finally{}`中的 `finally{}`，无论是否发生异常都会执行 `whenComplete()` 中的回调函数 `consumer` 和 `handle()` 中的回调函数 `fn`。`whenComplete()` 和 `handle()` 的区别在于 `whenComplete()` 不支持返回结果，而 `handle()` 是支持返回结果的。

## CompletionService

如何批量执行异步任务? 举个例子, 应用需要从三个电商询价，然后保存在自己的数据库里。核心示例代码如下所示，由于是串行的，所以性能很慢:

```java
// 向电商S1询价，并保存
r1 = getPriceByS1();
save(r1);
// 向电商S2询价，并保存
r2 = getPriceByS2();
save(r2);
// 向电商S3询价，并保存
r3 = getPriceByS3();
save(r3);
```

使用 `ThreadPoolExecutor` + `Future` 完成是这样的:

```java
// 创建线程池
ExecutorService executor =
  Executors.newFixedThreadPool(3);
// 异步向电商S1询价
Future<Integer> f1 = 
  executor.submit(
    ()->getPriceByS1());
// 异步向电商S2询价
Future<Integer> f2 = 
  executor.submit(
    ()->getPriceByS2());
// 异步向电商S3询价
Future<Integer> f3 = 
  executor.submit(
    ()->getPriceByS3());
    
// 获取电商S1报价并保存
r=f1.get();
executor.execute(()->save(r));
  
// 获取电商S2报价并保存
r=f2.get();
executor.execute(()->save(r));
  
// 获取电商S3报价并保存  
r=f3.get();
executor.execute(()->save(r));

```

上面的这个方案本身没有太大问题，但是有个地方的处理需要你注意，那就是如果获取电商 S1 报价的耗时很长，那么即便获取电商 S2 报价的耗时很短，也无法让保存 S2 报价的操作先执行，因为这个主线程都阻塞在了 `f1.get()` 操作上。

那么如何优化? 可以增加一个阻塞队列，获取到 S1、S2、S3 的报价都进入阻塞队列，然后在主线程中消费阻塞队列，这样就能保证先获取到的报价先保存到数据库了。

```java
// 创建阻塞队列
BlockingQueue<Integer> bq =
  new LinkedBlockingQueue<>();
//电商S1报价异步进入阻塞队列  
executor.execute(()->
  bq.put(f1.get()));
//电商S2报价异步进入阻塞队列  
executor.execute(()->
  bq.put(f2.get()));
//电商S3报价异步进入阻塞队列  
executor.execute(()->
  bq.put(f3.get()));
//异步保存所有报价  
for (int i=0; i<3; i++) {
  Integer r = bq.take();
  executor.execute(()->save(r));
}  
```

但在实际项目中, 我们可以使用 JDK 为我们提供的 `CompletionService` 去执行批量任务.

`CompletionService` 的实现原理也是内部维护了一个阻塞队列，当任务执行结束就把任务的执行结果加入到阻塞队列中，不同的是 `CompletionService` 是把任务执行结果的 `Future` 对象加入到阻塞队列中，而上面的示例代码是把任务最终的执行结果放入了阻塞队列中。

`CompletionService` 接口的实现类是 `ExecutorCompletionService`，这个实现类的构造方法有两个，分别是：

```java
ExecutorCompletionService(Executor executor)
ExecutorCompletionService(Executor executor, BlockingQueue> completionQueue)
```

下面使用 `CompletionService` 来优化一下:

```java
// 创建线程池
ExecutorService executor = 
  Executors.newFixedThreadPool(3);
// 创建CompletionService
CompletionService<Integer> cs = new 
  ExecutorCompletionService<>(executor);
// 异步向电商S1询价
cs.submit(()->getPriceByS1());
// 异步向电商S2询价
cs.submit(()->getPriceByS2());
// 异步向电商S3询价
cs.submit(()->getPriceByS3());
// 将询价结果异步保存到数据库
for (int i=0; i<3; i++) {
  Integer r = cs.take().get();
  executor.execute(()->save(r));
}
```

来看一下 `CompletionService` 的方法:

```java
Future<V> submit(Callable<V> task);
Future<V> submit(Runnable task, V result);
Future<V> take() 
  throws InterruptedException;
Future<V> poll();
Future<V> poll(long timeout, TimeUnit unit) 
  throws InterruptedException;
```

前面两个 `submit()` 是提交任务的, `take()`、`poll()` 都是从阻塞队列中获取并移除一个元素；它们的区别在于如果阻塞队列是空的，那么调用 `take()` 方法的线程会被**阻塞**，而 `poll()` 方法会**返回 null 值**。 `poll(long timeout, TimeUnit unit)` 方法支持以超时的方式获取并移除阻塞队列头部的一个元素，如果等待了 timeout unit 时间，阻塞队列还是空的，那么该方法会返回 null 值。

对于简单的并行任务，可以通过"线程池 + `Future`"的方案来解决；如果任务之间有聚合关系，无论是 AND 聚合还是 OR 聚合，都可以通过 `CompletableFuture` 来解决；而批量的并行任务，则可以通过 `CompletionService` 来解决。

# Fork/Join

Fork/Join 是一个并行计算的框架，主要就是用来支持**分治任务**模型的，**这个计算框架里的 Fork 对应的是分治任务模型里的任务分解，Join 对应的是结果合并**。Fork/Join 计算框架主要包含两部分，一部分是**分治任务的线程池 `ForkJoinPool`**，另一部分是**分治任务 `ForkJoinTask`**。这两部分的关系类似于 `ThreadPoolExecutor` 和 Runnable 的关系，都可以理解为提交任务到线程池，只不过分治任务有自己独特类型 `ForkJoinTask`。

`ForkJoinTask` 是一个抽象类，它的方法有很多，最核心的是 `fork()` 方法和 `join()` 方法，其中 `fork()` 方法会异步地执行一个子任务，而 `join()` 方法则会阻塞当前线程来等待子任务的执行结果。`ForkJoinTask` 有两个子类——`RecursiveAction` 和 `RecursiveTask`，通过名字你就应该能知道，它们都是用递归的方式来处理分治任务的。这两个子类都定义了抽象方法 `compute()`，不过区别是 `RecursiveAction` 定义的 `compute()` 没有返回值，而 `RecursiveTask` 定义的 `compute()` 方法是有返回值的。这两个子类也是抽象类，在使用的时候，需要自定义子类去扩展。

先来看一个简单的例子, 累加数组:

```java
public class ForkJoinTest {

    private static final int length = 3000;
    private static long[] numbers;

    static {
        numbers = new long[length];
        for (int i = 0; i < length; i++) {
            numbers[i] = i;
        }
    }


    public static void main(String[] args) {
        ForkJoinPool forkJoinPool = ForkJoinPool.commonPool();
        ForkCalculator forkCalculator = new ForkCalculator(numbers, 0, length - 1);
        long start = System.currentTimeMillis();
        Long invoke = forkJoinPool.invoke(forkCalculator);
        long end = System.currentTimeMillis();
        System.out.println("并行耗时: " + (end - start) + " 毫秒");
        System.out.println("结果: " + invoke);
    }

    private static long calc(long[] numbers, int start, int end) {
        long r = 0;
        try {
            for (int i = start; i <= end; i++) {
                Thread.sleep(1);
                r += numbers[i];
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return r;
    }

    static class ForkCalculator extends RecursiveTask<Long> {
        private static final int THRESHOLD = 100;
        private long[] numbers;
        private int start;
        private int end;

        public ForkCalculator(long[] numbers, int start, int end) {
            this.numbers = numbers;
            this.start = start;
            this.end = end;
        }

        @Override
        protected Long compute() {
            if (end - start <= THRESHOLD) {
                return calc(numbers, start, end);
            }
            int middle = (end + start) / 2;
            ForkCalculator left = new ForkCalculator(numbers, start, middle);
            ForkCalculator right = new ForkCalculator(numbers, middle + 1, end);
            invokeAll(left, right);
            return left.join() + right.join();
        }
    }

}
```

`ForkJoinPool` 本质上也是一个生产者 - 消费者的实现, 但它是每个线程对应一个**双端队列**, 因为它还采取了一种叫做**任务窃取**的机制, 以便有空闲线程出现的时候可以窃取其他线程的任务.

不过需要注意的是，默认情况下所有的并行流计算都**共享一个** `ForkJoinPool`，这个共享的 `ForkJoinPool` 默认的线程数是 CPU 的核数；如果所有的并行流计算都是 CPU 密集型计算的话，完全没有问题，但是如果存在 I/O 密集型的并行流计算，那么很可能会因为一个很慢的 I/O 计算而拖慢整个系统的性能。所以建议**用不同的 `ForkJoinPool` 执行不同类型的计算任务**。