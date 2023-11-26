---
title: 并发设计模式
date: 2019-10-29 11:45:41
categories: [Programming, Java, Concurrent]
tags: [Java, Concurrent]
---

![](https://oldcdn.yangbingdong.com/img/concurrent/java-concurrent-part5-banner.jpg)

# Preface

> 并发领域中也有诸多的设计模式.

<!--more-->

# Immutability模式

解决并发问题，其实最简单的办法就是让共享变量**只有读操作**，而**没有写操作**。这个办法如此重要，以至于被上升到了一种解决并发问题的设计模式：**不变性（Immutability）模式**。所谓不变性，简单来讲，就是**对象一旦被创建之后，状态就不再发生变化**。换句话说，就是变量一旦被赋值，就不允许修改了（没有写操作）；没有修改操作，也就是保持了不变性。

实现一个具备不可变性的类，还是挺简单的。**将一个类所有的属性都设置成 final 的，并且只允许存在只读方法，那么这个类基本上就具备不可变性了**。更严格的做法是**这个类本身也是 final 的**，也就是不允许继承。因为子类可以覆盖父类的方法，有可能改变不可变性，所以推荐你在实际工作中，使用这种更严格的做法。

Java 中非常经典的例子就是 `String`、`Integer`、`Long` 以及 `Double` 等基础类型的包装类. 它们都严格遵守不可变类的三点要求：类和属性都是 final 的，所有方法均是只读的。

但是 `String` 中有一些方法类似 `replace()` 这种操作这种操作是怎么实现的? 很简单, **对象不可变那就返回一个新的对象**. 那是不是有点浪费内存呢? 确实会的, 但是可以通过一种**享元模式(Flyweight Pattern)**来使这个消耗减小. Java 语言里面 `Long`、`Integer`、`Short`、`Byte` 等这些基本数据类型的包装类都用到了享元模式, **享元模式本质上其实就是一个对象池**:

![](https://oldcdn.yangbingdong.com/img/concurrent/java-concurrent-part5-long-cache.png)

之前有提过, 基本上所有的基础类型的包装类都不适合做锁, 因为这些类基本都使用了享元模式, 看上去是私有, 但实际上可能是公共的, 以下就是错误示范:

```java
class A {
  Long al=Long.valueOf(1);
  public void setAX(){
    synchronized (al) {
      //省略代码无数
    }
  }
}
class B {
  Long bl=Long.valueOf(1);
  public void setBY(){
    synchronized (bl) {
      //省略代码无数
    }
  }
}
```

在使用 `Immutability` 模式的时候，需要注意以下两点：

* 对象的所有属性都是 final 的，并不能保证不可变性(对象属性也可能是一个对象)；
* 不可变对象也需要正确发布。

# Copy-on-Write模式

上面说到 String 这个类在实现 `replace()` 方法的时候，并没有更改原字符串里面 `value[]` 数组的内容，而是**创建了一个新字符串**，这种方法在解决不可变对象的修改问题时经常用到, 这本质上是 **Copy-on-Write** 方法, 也就是**写时复制**. 

Java 并发包中比较经典的实现就是 `CopyOnWriteArrayList` 和 `CopyOnWriteArraySet` 这两个类. 当然, 这并不是 Java 独有的模式, 这个模式也普遍存在与其他的领域, 比如类 Unix 操作系统中的 fork 子进程, 文件系统中的Btrfs (B-Tree File System), Docker 容器镜像, 甚至分布式源码管理系统 Git 背后的设计思想都有 Copy-on-Write...

不过，**Copy-on-Write 最大的应用领域还是在函数式编程领域**。函数式编程的基础是不可变性（Immutability），所以函数式编程里面所有的修改操作都需要 Copy-on-Write 来解决。你或许会有疑问，“所有数据的修改都需要复制一份，性能是不是会成为瓶颈呢?”你的担忧是有道理的，之所以函数式编程早年间没有兴起，性能绝对拖了后腿。但是随着硬件性能的提升，性能问题已经慢慢变得可以接受了。而且，Copy-on-Write 也远不像 Java 里的 `CopyOnWriteArrayList` 那样笨：整个数组都复制一遍。

`CopyOnWriteArrayList` 和 `CopyOnWriteArraySet` 这两个 Copy-on-Write 容器在修改的时候会复制整个数组，所以如果容器经常被修改或者这个数组本身就非常大的时候，是不建议使用的。反之，如果是修改非常少、数组数量也不大，并且对读性能要求苛刻的场景，使用 Copy-on-Write 容器效果就非常好了。一个比较经典的场景就是 RPC 框架的注册路由表, 对读的要求很高, 写比较少, 对一致性要求不高:

```java

//路由信息
public final class Router{
  private final String  ip;
  private final Integer port;
  private final String  iface;
  //构造函数
  public Router(String ip, 
      Integer port, String iface){
    this.ip = ip;
    this.port = port;
    this.iface = iface;
  }
  //重写equals方法
  public boolean equals(Object obj){
    if (obj instanceof Router) {
      Router r = (Router)obj;
      return iface.equals(r.iface) &&
             ip.equals(r.ip) &&
             port.equals(r.port);
    }
    return false;
  }
  public int hashCode() {
    //省略hashCode相关代码
  }
}
//路由表信息
public class RouterTable {
  //Key:接口名
  //Value:路由集合
  ConcurrentHashMap<String, CopyOnWriteArraySet<Router>> 
    rt = new ConcurrentHashMap<>();
  //根据接口名获取路由表
  public Set<Router> get(String iface){
    return rt.get(iface);
  }
  //删除路由
  public void remove(Router router) {
    Set<Router> set=rt.get(router.iface);
    if (set != null) {
      set.remove(router);
    }
  }
  //增加路由
  public void add(Router router) {
    Set<Router> set = rt.computeIfAbsent(
      route.iface, r -> 
        new CopyOnWriteArraySet<>());
    set.add(router);
  }
}
```

Copy-on-Write 是一项非常通用的技术方案，在很多领域都有着广泛的应用。不过，它也有缺点的，那就是**消耗内存，每次修改都需要复制一个新的对象出来**，好在随着自动垃圾回收（GC）算法的成熟以及硬件的发展，这种内存消耗已经渐渐可以接受了。

# 线程本地存储模式

之前提到过**线程封闭**这个概念, 其本质上就是避免共享, Java 中提供了 `ThreadLocal` 类来实现这个东西.

`ThreadLocal` 基本原理如下:

![](https://oldcdn.yangbingdong.com/img/concurrent/java-concurrent-threadlocal.png)

```java
class Thread {
  //内部持有ThreadLocalMap
  ThreadLocal.ThreadLocalMap 
    threadLocals;
}
class ThreadLocal<T>{
  public T get() {
    //首先获取线程持有的
    //ThreadLocalMap
    ThreadLocalMap map =
      Thread.currentThread()
        .threadLocals;
    //在ThreadLocalMap中
    //查找变量
    Entry e = 
      map.getEntry(this);
    return e.value;  
  }
  static class ThreadLocalMap{
    //内部是数组而不是Map
    Entry[] table;
    //根据ThreadLocal查找Entry
    Entry getEntry(ThreadLocal key){
      //省略查找逻辑
    }
    //Entry定义
    static class Entry extends
    WeakReference<ThreadLocal>{
      Object value;
    }
  }
}
```

这里要注意一点, 最好采用 `try{}finally{}` 手动释放资源**避免内存泄露**.

线程本地存储模式本质上是一种**避免共享**的方案，由于没有共享，所以自然也就没有并发问题。如果你需要在并发场景中使用一个线程不安全的工具类，最简单的方案就是避免共享。避免共享有两种方案，一种方案是将这个工具类作为局部变量使用，另外一种方案就是线程本地存储模式。这两种方案，局部变量方案的缺点是在高并发场景下会频繁创建对象，而线程本地存储方案，每个线程只需要创建一个工具类的实例，所以不存在频繁创建对象的问题。

# Guarded Suspension模式

假设有这么一个场景, 服务调用是通过MQ来调用的, 比如需要Web端请求一个文件, 服务A发送MessageA, 服务B消费MessageA并发送MessageB, 但是A消费MessageB是异步的,   但是对于Web端来说这个请求是同步的.

![](https://oldcdn.yangbingdong.com/img/concurrent/java-concurrent-guarded-suspension.png)

伪代码如下:

```java
class Message{
  String id;
  String content;
}
//该方法可以发送消息
void send(Message msg){
  //省略相关代码
}
//MQ消息返回后会调用该方法
//该方法的执行线程不同于
//发送消息的线程
void onMessage(Message msg){
  //省略相关代码
}
//处理浏览器发来的请求
Respond handleWebReq(){
  //创建一消息
  Message msg1 = new 
    Message("1","{...}");
  //发送消息
  send(msg1);
  //如何等待MQ返回的消息呢？
  String result = ...;
}
```

对于MQ返回消息需要等待服务提供方消费完成, 本质上是**等待一个条件满足**. 这类需求可以通过 Lock 与 Condition 来实现. 前人将其总结成一个模式: **Guarded Suspension**, 直译过来就是"保护性地暂停".

下图就是 Guarded Suspension 模式的结构图，非常简单，一个对象 `GuardedObject`，内部有一个成员变量——受保护的对象，以及两个成员方法——`get(Predicate p)`和`onChanged(T obj)`方法。

![](https://oldcdn.yangbingdong.com/img/concurrent/java-concurrent-guarded-suspension-struct.png)

```java
class GuardedObject<T>{
  //受保护的对象
  T obj;
  final Lock lock = 
    new ReentrantLock();
  final Condition done =
    lock.newCondition();
  final int timeout=1;
  //获取受保护对象  
  T get(Predicate<T> p) {
    lock.lock();
    try {
      //MESA管程推荐写法
      while(!p.test(obj)){
        done.await(timeout, 
          TimeUnit.SECONDS);
      }
    }catch(InterruptedException e){
      throw new RuntimeException(e);
    }finally{
      lock.unlock();
    }
    //返回非空的受保护对象
    return obj;
  }
  //事件通知方法
  void onChanged(T obj) {
    lock.lock();
    try {
      this.obj = obj;
      done.signalAll();
    } finally {
      lock.unlock();
    }
  }
}
```

对于上面场景, 我们可以这样实现:

```java
//处理浏览器发来的请求
Respond handleWebReq(){
  //创建一消息
  Message msg1 = new 
    Message("1","{...}");
  //发送消息
  send(msg1);
  //利用GuardedObject实现等待
  GuardedObject<Message> go
    =new GuardObjec<>();
  Message r = go.get(
    t->t != null);
}
void onMessage(Message msg){
  //如何找到匹配的go？
  GuardedObject<Message> go=???
  go.onChanged(msg);
}
```

但是这里的问题就是, `GuardedObject` 是在 `handleWebReq()` 方法中new出来的, 如何传递到 `onMessage()` 方法?

很简单, 做一个消息的映射就行了, `Dubbo` 中 `DefaultFuture` 这个类也是采用的这种方式的.

# Balking模式

我们经常会遇到**防御性 return** 的场景, 比如只加载一次或者只执行一次, 伪代码如下:

```java
if(condition) {
  return;
}
```

但往往会有多个线程去执行这段逻辑, 这又变成了另外一种"多线程版本的 if", 叫做 **Balking 模式**.

Balking 模式和 Guarded Suspension 模式从实现上看似乎没有多大的关系，Balking 模式只需要用互斥锁就能解决，而 Guarded Suspension 模式则要用到管程这种高级的并发原语；但是从应用的角度来看，它们解决的都是"线程安全的 if"语义，不同之处在于，Guarded Suspension 模式会等待 if 条件为真，而 Balking 模式不会等待。

# Thread-Per-Message模式

这个模式说白了就是就是每个请求都委托给一个新的线程, Thread-Per-Message 模式的一个最经典的应用场景是**网络编程里服务端的实现**，服务端为每个客户端请求创建一个独立的线程，当线程处理完请求后，自动销毁，这是一种最简单的并发处理网络请求的方法。

```java
final ServerSocketChannel ssc = 
  ServerSocketChannel.open().bind(
    new InetSocketAddress(8080));
//处理请求    
try {
  while (true) {
    // 接收请求
    SocketChannel sc = ssc.accept();
    // 每个请求都创建一个线程
    new Thread(()->{
      try {
        // 读Socket
        ByteBuffer rb = ByteBuffer
          .allocateDirect(1024);
        sc.read(rb);
        //模拟处理请求
        Thread.sleep(2000);
        // 写Socket
        ByteBuffer wb = 
          (ByteBuffer)rb.flip();
        sc.write(wb);
        // 关闭Socket
        sc.close();
      }catch(Exception e){
        throw new UncheckedIOException(e);
      }
    }).start();
  }
} finally {
  ssc.close();
}   
```

上面方案显然不适用于生产环境, 毕竟 Java 中的线程是一个重量级的对象，创建成本很高，一方面创建线程比较耗时，另一方面线程占用的内存也比较大. 

Thread-Per-Message 在 Java 中的知名度不大, 是因为线程的成本很高, 但是在别的语言当中却很响亮, 业界中有一种方案叫**轻量级线程**, 也叫**协程**, Go 语言、Lua 语言当中都有实现. 幸运的是, ava 语言目前也已经意识到轻量级线程的重要性了，OpenJDK 有个 Loom 项目，就是要解决 Java 语言的轻量级线程问题，在这个项目中，轻量级线程被叫做 Fiber。

> 有一个java库叫Quasar Fiber ，通过javaagent技术可以实现轻量级线程
> 官网: ***[http://www.paralleluniverse.co/quasar/](http://www.paralleluniverse.co/quasar/)***
>
> 阿里也有一个 wisp2, 不过目前没开源.

# Worker Thread模式

这个模式的经典实现就是 JDK 中的线程池了, 关于线程池的东西这里也不多说了, 主要还是重复一下注意事项吧:

* **使用有界队列**
* **拒绝策略要慎重使用**
* **异常处理的问题**
* **有意义的线程名称**

还有一个问题需要注意, **死锁**. 如果提交到相同线程池的任务不是相互独立的，而是有依赖关系的，那么就有可能导致线程死锁。实际工作中，我就亲历过这种线程死锁的场景。具体现象是应用每运行一段时间偶尔就会处于无响应的状态，监控数据看上去一切都正常，但是实际上已经不能正常工作了。

以下是一段死锁代码:

```java
//L1、L2阶段共用的线程池
ExecutorService es = Executors.
  newFixedThreadPool(2);
//L1阶段的闭锁    
CountDownLatch l1=new CountDownLatch(2);
for (int i=0; i<2; i++){
  System.out.println("L1");
  //执行L1阶段任务
  es.execute(()->{
    //L2阶段的闭锁 
    CountDownLatch l2=new CountDownLatch(2);
    //执行L2阶段子任务
    for (int j=0; j<2; j++){
      es.execute(()->{
        System.out.println("L2");
        l2.countDown();
      });
    }
    //等待L2阶段任务执行完
    l2.await();
    l1.countDown();
  });
}
//等着L1阶段任务执行完
l1.await();
System.out.println("end");
```

当应用出现类似问题时，首选的诊断方法是查看线程栈。下图是上面示例代码停止响应后的线程栈，你会发现线程池中的两个线程全部都阻塞在 `l2.await();` 这行代码上了，也就是说，线程池里所有的线程都在等待 L2 阶段的任务执行完，那 L2 阶段的子任务什么时候能够执行完呢？永远都没那一天了，为什么呢？因为线程池里的线程都阻塞了，没有空闲的线程执行 L2 阶段的任务了。其实这种问题通用的解决方案是**为不同的任务创建不同的线程池**。

最后再次强调一下：**提交到相同线程池中的任务一定是相互独立的，否则就一定要慎重**。

# 两阶段终止模式

Java 语言的 Thread 类中曾经提供了一个 `stop()` 方法，用来终止线程，可是早已不建议使用了，原因是这个方法用的就是一剑封喉的做法，**被终止的线程没有机会料理后事**。

前辈们经过认真对比分析，已经总结出了一套成熟的方案，叫做**两阶段终止模式**。顾名思义，就是将终止过程分成两个阶段，其中第一个阶段主要是线程 T1 向线程 T2**发送终止指令**，而第二阶段则是线程 T2**响应终止指令**。

![](https://oldcdn.yangbingdong.com/img/concurrent/java-concurrent-two-phase-terminal.png)

在 Java 中我们可以使用 Thread 提供的 interrupt() 以及自定义标志位来实现, 举个例子: 实际工作中，有些监控系统需要动态地采集一些数据，一般都是监控系统发送采集指令给被监控系统的监控代理，监控代理接收到指令之后，从监控目标收集数据，然后回传给监控系统，详细过程如下图所示。出于对性能的考虑（有些监控项对系统性能影响很大，所以不能一直持续监控），动态采集功能一般都会有终止操作。

![](https://oldcdn.yangbingdong.com/img/concurrent/java-concurrent-two-phase-terminal2.png)

```java
class Proxy {
  //线程终止标志位
  volatile boolean terminated = false;
  boolean started = false;
  //采集线程
  Thread rptThread;
  //启动采集功能
  synchronized void start(){
    //不允许同时启动多个采集线程
    if (started) {
      return;
    }
    started = true;
    terminated = false;
    rptThread = new Thread(()->{
      while (!terminated){
        //省略采集、回传实现
        report();
        //每隔两秒钟采集、回传一次数据
        try {
          Thread.sleep(2000);
        } catch (InterruptedException e){
          //重新设置线程中断状态
          Thread.currentThread().interrupt();
        }
      }
      //执行到此处说明线程马上终止
      started = false;
    });
    rptThread.start();
  }
  //终止采集功能
  synchronized void stop(){
    //设置中断标志位
    terminated = true;
    //中断线程rptThread
    rptThread.interrupt();
  }
}
```

这里要注意两点, 第一是没有使用 `Thread.currentThread().isInterrupted()` 来判断是因为代码中有可能会使用到第三方类库, 而我们没有办法保证第三方类库正确处理了线程的中断异常，例如第三方类库在捕获到 `Thread.sleep()` 方法抛出的中断异常后，没有重新设置线程的中断状态，那么就会导致线程不能够正常终止。还有一点是 `terminated` 标志位使用了 `volatile` 修饰来保证可见性.

# 生产者-消费者模式

这个的经典实现就是线程池了, 这里不在多说.

# STM&MVCC

STM: Software Transactional Memory(**软件事务内存**), 也是解决并发方面问题的一种模式, 在数据库中见的比较多. 其中一种实现是 MVCC(Multi-Version Concurrency Control), 也就是**多版本并发控制**.

MVCC 可以简单地理解为数据库事务在开启的时候，会给数据库打一个快照，以后所有的读写都是基于这个快照的。当提交事务的时候，如果所有读写过的数据在该事务执行期间没有发生过变化，那么就可以提交；如果发生了变化，说明该事务和有其他事务读写的数据冲突了，这个时候是不可以提交的。

为了记录数据是否发生了变化，可以给每条数据增加一个版本号，这样每次成功修改数据都会增加版本号的值。有不少 STM 的实现方案都是基于 MVCC 的，例如知名的 Clojure STM。

代码示例:

```java
//带版本号的对象引用
public final class VersionedRef<T> {
    final T value;
    final long version;

    //构造方法
    public VersionedRef(T value, long version) {
        this.value = value;
        this.version = version;
    }
}

//支持事务的引用
public class TxnRef<T> {
    //当前数据，带版本号
    volatile VersionedRef curRef;

    //构造方法
    public TxnRef(T value) {
        this.curRef = new VersionedRef(value, 0L);
    }

    //获取当前事务中的数据
    public T getValue(Txn txn) {
        return txn.get(this);
    }

    //在当前事务中设置数据
    public void setValue(T value, Txn txn) {
        txn.set(this, value);
    }
}

//事务接口
public interface Txn {
    <T> T get(TxnRef<T> ref);
    <T> void set(TxnRef<T> ref, T value);
}

//STM事务实现类
public final class STMTxn implements Txn {
    //事务ID生成器
    private static AtomicLong txnSeq = new AtomicLong(0);

    //当前事务所有的相关数据
    private Map<TxnRef, VersionedRef> inTxnMap = new HashMap<>();
    //当前事务所有需要修改的数据
    private Map<TxnRef, Object> writeMap = new HashMap<>();
    //当前事务ID
    private long txnId;

    //构造函数，自动生成当前事务ID
    STMTxn() {
        txnId = txnSeq.incrementAndGet();
    }

    //获取当前事务中的数据
    @Override
    public <T> T get(TxnRef<T> ref) {
        //将需要读取的数据，加入inTxnMap
        if (!inTxnMap.containsKey(ref)) {
            inTxnMap.put(ref, ref.curRef);
        }
        return (T) inTxnMap.get(ref).value;
    }

    //在当前事务中修改数据
    @Override
    public <T> void set(TxnRef<T> ref, T value) {
        //将需要修改的数据，加入inTxnMap
        if (!inTxnMap.containsKey(ref)) {
            inTxnMap.put(ref, ref.curRef);
        }
        writeMap.put(ref, value);
    }

    //提交事务
    boolean commit() {
        synchronized (STM.commitLock) {
            //是否校验通过
            boolean isValid = true;
            //校验所有读过的数据是否发生过变化
            for (Map.Entry<TxnRef, VersionedRef> entry : inTxnMap.entrySet()) {
                VersionedRef curRef = entry.getKey().curRef;
                VersionedRef readRef = entry.getValue();
                //通过版本号来验证数据是否发生过变化
                if (curRef.version != readRef.version) {
                    isValid = false;
                    break;
                }
            }
            //如果校验通过，则所有更改生效
            if (isValid) {
                writeMap.forEach((k, v) -> {
                    k.curRef = new VersionedRef(v, txnId);
                });
            }
            return isValid;
        }
    }
}

public interface TxnRunnable {
    void run(Txn txn);
}

//STM
public final class STM {
    //私有化构造方法
    private STM() {
    }

    //提交数据需要用到的全局锁
    static final Object commitLock = new Object();

    //原子化提交方法
    public static void atomic(TxnRunnable action) {
        boolean committed = false;
        //如果没有提交成功，则一直重试
        while (!committed) {
            //创建新的事务
            STMTxn txn = new STMTxn();
            //执行业务逻辑
            action.run(txn);
            //提交事务
            committed = txn.commit();
        }
    }
}
```

```java
public class Account {
    //余额
    private TxnRef<Integer> balance;

    //构造方法
    public Account(int balance) {
        this.balance = new TxnRef<>(balance);
    }

    //转账操作
    public void transfer(Account target, int amt) {
        STM.atomic((txn) -> {
            Integer from = balance.getValue(txn);
            balance.setValue(from - amt, txn);
            Integer to = target.balance.getValue(txn);
            target.balance.setValue(to + amt, txn);
        });
    }
}
```

总的来说其实就是通过版本号来控制并发, 只不过这里面还多了个**副本**的概念.

STM 借鉴的是数据库的经验，数据库虽然复杂，但仅仅存储数据，而编程语言除了有共享变量之外，还会执行各种 I/O 操作，**很显然 I/O 操作是很难支持回滚的**。所以，STM 也不是万能的。目前支持 STM 的编程语言主要是函数式语言，函数式语言里的数据天生具备不可变性，利用这种不可变性实现 STM 相对来说更简单。

# 总结

**Immutability 模式**、**Copy-on-Write 模式**和**线程本地存储模式**本质上都是为了**避免共享**，只是实现手段不同而已。这 3 种设计模式的实现都很简单，但是实现过程中有些细节还是需要格外注意的。例如，**使用 Immutability 模式需要注意对象属性的不可变性**，**使用 Copy-on-Write 模式需要注意性能问题**，**使用线程本地存储模式需要注意异步执行问题**。

**Guarded Suspension 模式**和 **Balking 模式**都可以简单地理解为"多线程版本的 if"，但它们的区别在于前者会等待 if 条件变为真，而后者则不需要等待。

**Thread-Per-Message 模式**、**Worker Thread 模式**和**生产者 - 消费者模式**是三种**最简单实用的多线程分工方法**。Thread-Per-Message 模式在实现的时候需要注意是否存在线程的频繁创建、销毁以及是否可能导致 **OOM**。Worker Thread 模式的实现，需要注意潜在的线程**死锁问题**, 以及**任务之间没有依赖关系**这个因素要慎重考虑。