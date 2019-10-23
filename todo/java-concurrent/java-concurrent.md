# Java 并发编程

> ***[https://time.geekbang.org/column/intro/159](https://time.geekbang.org/column/intro/159)***

# 并发理论基础

并发编程可以总结为三个核心问题：分工、同步、互斥。

所谓分工指的是如何高效地拆解任务并分配给线程，而同步指的是线程之间如何协作，互斥则是保证同一时刻只允许一个线程访问共享资源。

* 分工 -> Executor、Fork/Join、Future等

* 同步(核心技术是**管程**) -> CountDownLatch、CyclicBarrier、Phaser、Exchanger等

* 互斥(线程安全) -> synchronized、ReadWriteLock、StampedLock、ThreadLocal等

![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-generalization.png)

## 并发编程Bug的源头

现代CPU, 内存以及硬盘之间的速度差了个天跟地, 为了弥补短板, 计算机体系以及操作系统作出了重大贡献:

* CPU 增加了缓存，以均衡与内存的速度差异；
* 操作系统增加了进程、线程，以分时复用 CPU，进而均衡 CPU 与 I/O 设备的速度差异；
* 编译程序优化指令执行次序，使得缓存能够得到更加合理地利用。

**源头之一：缓存导致的可见性问题**.

两核两个线程同时对变量i进行10000次+1操作, 但结果并不是20000, 而是小于20000. 因为CPU-A加完后的结果对CPU-B并不是马上可见的.

**源头之二：线程切换带来的原子性问题.**

执行count += 1，至少需要三条 CPU 指令:

* 指令 1：首先，需要把变量 count 从内存加载到 CPU 的寄存器；
* 指令 2：之后，在寄存器中执行 +1 操作；
* 指令 3：最后，将结果写入内存（缓存机制导致可能写入的是 CPU 缓存而不是内存）。

有可能执行到指令1就发生了线程切换, 导致执行结果不符合预期.

操作系统做任务切换，可以发生在**任何一条CPU 指令**执行完，是的，是 CPU 指令，而不是高级语言里的一条语句CPU ，能保证的原子操作是 CPU 指令级别的。

**源头之三：编译优化带来的有序性问题**.

编译器为了优化性能，有时候会改变程序中语句的先后顺序，例如程序中：“a=6；b=7；”编译器优化后可能变成“b=7；a=6；”，在这个例子中，编译器调整了语句的顺序，但是不影响程序的最终结果。

在 Java 领域一个经典的案例就是利用双重检查创建单例对象:

```java
public class Singleton {
    static Singleton instance;

    static Singleton getInstance() {
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) instance = new Singleton();
            }
        }
        return instance;
    }
}
```

关键点在 new 上面:

1. 分配一块内存 M；
2. 在内存 M 上初始化 Singleton 对象；
3. 然后 M 的地址赋值给 instance 变量。

但是实际上优化后的执行路径却是这样的：

1. 分配一块内存 M；
2. 将 M 的地址赋值给 instance 变量；
3. 最后在内存 M 上初始化 Singleton 对象。

## Java 内存模型

上面说到了并发编程 Bug 源头的其中两个就是可见性与有序性, 那么解决这两个问题最直接的办法就是**禁用缓存和编译优化**.

Java 内存模型通过定义多项规则对编译器和处理器进行限制，主要是针对可见性和有序性。这是个很复杂的规范，可以从不同的视角来解读，站在我们这些程序员的视角，本质上可以理解为，Java 内存模型规范了 JVM 如何提供按需禁用缓存和编译优化的方法。具体来说，这些方法包括 `volatile`、`synchronized` 和 `final` 三个关键字，以及 **Happens-Before** 规则。

先来看一段代码(假设线程A调用writer, 线程B调用reader方法):

```java
class VolatileExample {
  int x = 0;
  volatile boolean v = false;
  public void writer() {
    x = 42;
    v = true;
  }
  public void reader() {
    if (v == true) {
      // 这里x会是多少呢？
    }
  }
}
```

Happens-Before 的几条规则:

* 程序的顺序性规则: 在一个线程内，按照程序代码顺序，书写在前面的操作先行发生于书写在后面的操作。准确地说，应该是控制流顺序而不是程序代码顺序，因为要考虑分支、循环等结构。
* volatile 变量规则: 如果 A Happens-Before B，且 B Happens-Before C，那么 A Happens-Before C。
* 管程中锁的规则(**管程**是一种通用的同步原语，在 Java 中指的就是 synchronized，synchronized 是 Java 里对管程的实现): 对一个锁的解锁 Happens-Before 于后续对这个锁的加锁。
* 线程 start() 规则: 主线程 A 启动子线程 B 后，子线程 B 能够看到主线程在启动子线程 B 前的操作。
* 线程 join() 规则: 主线程 A 等待子线程 B 完成（主线程 A 通过调用子线程 B 的 join() 方法实现），当子线程 B 完成后（主线程 A 中 join() 方法返回），主线程能够看到子线程的操作。当然所谓的“看到”，指的是对共享变量的操作。
* 线程中断规则: 对线程interrupt()方法的调用先行发生于被中断线程的代码检测到中断事件的发生，可以通过Thread.interrupted()方法检测到是否有中断发生。
* 对象终结规则: 一个对象的初始化完成(构造函数执行结束)先行发生于它的finalize()方法的开始。

## 互斥锁

原子性问题的源头是**线程切换**, 在单核时代, 可以通过禁用线程切换做到, 但并不适合多核 CPU.

32 位 CPU 上执行 long 型变量的写操作，long 型变量是 64 位，在 32 位 CPU 上执行写操作会被拆分成两次写操作, 单核 CPU 可以通过禁止 CPU 中断保证原子性. 但在多核 CPU 上, 此时禁止 CPU 中断，只能保证 CPU 上的线程连续执行, 并不能保证同一时刻只有一个线程执行.

互斥是为了**同一时刻只有一个线程执行**，保证原子性。如果我们能够保证对共享变量的修改是互斥的，那么，无论是单核 CPU 还是多核 CPU，就都能保证原子性了。

Java 中通过 `synchronized` 关键字提供锁技术.

```java
class X {
  // 修饰非静态方法
  synchronized void foo() {
    // 临界区
  }
  // 修饰静态方法
  synchronized static void bar() {
    // 临界区
  }
  // 修饰代码块
  Object obj = new Object()；
  void baz() {
    synchronized(obj) {
      // 临界区
    }
  }
}  
```



![](https://cdn.yangbingdong.com/img/concurrent/java-sync-lock-module.png)

```java
class Account {
  private int balance;
  // 转账
  synchronized void transfer(
      Account target, int amt){
    if (this.balance > amt) {
      this.balance -= amt;
      target.balance += amt;
    }
  } 
}
```

以上代码只能对 `this.balance` 进行临界保护, 但 `target.balance` 可能会出现并发问题. 可采取使用同一个锁(在构造函数中传入)或者直接将 `Account.class` 作为锁对象(性能慢).

### 死锁

上面提到的同步方案中将 `Account.class` 作为所对象, 相当于串行化了, 性能大打折扣, 为了取得更高的性能, 可以采用细粒度锁, 使用细粒度锁可以提高并行度, 是性能优化的一个重要手段.

```java
class Account {
  private int balance;
  // 转账
  void transfer(Account target, int amt){
    // 锁定转出账户
    synchronized(this) {              
      // 锁定转入账户
      synchronized(target) {           
        if (this.balance > amt) {
          this.balance -= amt;
          target.balance += amt;
        }
      }
    }
  } 
}
```

以上代码会出现死锁, 如果两个线程分别调用 Account-A 以及 Account-B 转账操作, 会出现相互等待的情况.

![](https://cdn.yangbingdong.com/img/concurrent/java-sync-dead-lock.png)

只有以下这四个条件都发生时才会出现死锁：

1. 互斥，共享资源 X 和 Y 只能被一个线程占用；
2. 占有且等待，线程 T1 已经取得共享资源 X，在等待共享资源 Y 的时候，不释放共享资源 X；
3. 不可抢占，其他线程不能强行抢占线程 T1 占有的资源；
4. 循环等待，线程 T1 等待线程 T2 占有的资源，线程 T2 等待线程 T1 占有的资源，就是循环等待。

**只要破坏其中一个，就可以成功避免死锁的发生。**

其中互斥不能破坏, 其他三个都是可破坏的.

1. 对于“占用且等待”，我们可以一次性申请所有的资源. 

2. 对于“不可抢占”这个条件，占用部分资源的线程进一步申请其他资源时，如果申请不到，可以主动释放它占有的资源.

3. 对于“循环等待”这个条件，可以靠按序申请资源来预防(加锁顺序一直)。



对于破坏占用且等待条件(增加一个管理员, 只有同时拿到两个资源才能执行转账操作):

![](https://cdn.yangbingdong.com/img/concurrent/java-break-dead-lock.png)

```java
class Allocator {
  private List<Object> als =
    new ArrayList<>();
  // 一次性申请所有资源
  synchronized boolean apply(
    Object from, Object to){
    if(als.contains(from) ||
         als.contains(to)){
      return false;  
    } else {
      als.add(from);
      als.add(to);  
    }
    return true;
  }
  // 归还资源
  synchronized void free(
    Object from, Object to){
    als.remove(from);
    als.remove(to);
  }
}

class Account {
  // actr应该为单例
  private Allocator actr;
  private int balance;
  // 转账
  void transfer(Account target, int amt){
    // 一次性申请转出账户和转入账户，直到成功
    while(!actr.apply(this, target))
      ；
    try{
      // 锁定转出账户
      synchronized(this){              
        // 锁定转入账户
        synchronized(target){           
          if (this.balance > amt){
            this.balance -= amt;
            target.balance += amt;
          }
        }
      }
    } finally {
      actr.free(this, target)
    }
  } 
}
```

## 等待-通知

在上面**破坏占用且等待条件**的时候, 使用了死循环的方式来循环等待，核心代码如下：

```java
// 一次性申请转出账户和转入账户，直到成功
while(!actr.apply(this, target))
  ；
```

这种写法太消耗性能, 比较好的做法就是不满足条件, 则等待, 满足后, 同时等待的线程重新执行.

类比(就医流程)：

1. 患者先去挂号，然后到就诊门口分诊，等待叫号；
2. 当叫到自己的号时，患者就可以找大夫就诊了；
3. 就诊过程中，大夫可能会让患者去做检查，同时叫下一位患者；
4. 当患者做完检查后，拿检测报告重新分诊，等待叫号；
5. 当大夫再次叫到自己的号时，患者再去找大夫就诊。

在 Java 语言里，等待 - 通知机制可以有多种实现方式，比如 Java 语言内置的 `synchronized` 配合 `wait()`、`notify()`、`notifyAll()` 这三个方法就能轻松实现。

![](https://cdn.yangbingdong.com/img/concurrent/java-break-dead-lock02.png)

这个等待队列和互斥锁是一对一的关系，每个互斥锁都有自己独立的等待队列。

`wait()`、`notify()`、`notifyAll()` 都是在 `synchronized{}`内部被调用的。如果在 `synchronized{}`外部调用，或者锁定的 `this`，而用 `target.wait()` 调用的话，JVM 会抛出一个运行时异常: `java.lang.IllegalMonitorStateException`。

将之前的 `Allocator` 改造一下:

```java
class Allocator {
  private List<Object> als;
  // 一次性申请所有资源
  synchronized void apply(
    Object from, Object to){
    // 经典写法
    while(als.contains(from) ||
         als.contains(to)){
      try{
        wait();
      }catch(Exception e){
      }   
    } 
    als.add(from);
    als.add(to);  
  }
  // 归还资源
  synchronized void free(
    Object from, Object to){
    als.remove(from);
    als.remove(to);
    notifyAll();
  }
}
```

wait与sleep区别在于：
1. wait会释放所有锁而sleep不会释放锁资源.
2. wait只能在同步方法和同步块中使用，而sleep任何地方都可以.
3. wait无需捕捉异常，而sleep需要.
4. sleep是Thread的方法，而wait是Object类的方法.

两者相同点：都会让渡CPU执行时间，等待再次调度！

## 安全性、活跃性以及性能问题

**安全性**：

* 数据竞争： 多个线程同时访问一个数据，并且至少有一个线程会写这个数据。
* 竞态条件： 程序的执行结果依赖程序执行的顺序。

**活跃性**：

* 死锁：破坏造成死锁的条件，
  1. 使用等待-通知机制的Allocator; 
  2. 主动释放占有的资源；
  3. 按顺序获取资源。
* 活锁：虽然没有发生阻塞，但仍会存在执行不下去的情况(两个线程相互谦让)。解决办法，等待随机的时间，例如Raft算法中重新选举leader。
* 饥饿：我想到了没有引入时间片概念时，cpu处理作业。如果遇到长作业，会导致短作业饥饿。如果优先处理短作业，则会饿死长作业。长作业就可以类比持有锁的时间过长，而时间片可以让cpu资源公平地分配给各个作业。当然，如果有无穷多的cpu，就可以让每个作业得以执行，就不存在饥饿了。

**性能**：

核心就是在保证安全性和活跃性的前提下，根据实际情况，尽量降低锁的粒度。即尽量减少持有锁的时间。JDK的并发包里，有很多特定场景针对并发性能的设计。还有很多无锁化的设计，例如MVCC，TLS，COW等，可以根据不同的场景选用不同的数据结构或设计。

**并发编程是一个复杂的技术领域，微观上涉及到原子性问题、可见性问题和有序性问题，宏观则表现为安全性、活跃性以及性能问题。**

## 管程

管程是一种**概念**，任何语言都可以通用, 对应的英文是 Monitor，很多 Javaer 都喜欢将其翻译成“监视器”，这是直译。

所谓管程，指的是**管理共享变量以及对共享变量的操作过程**，让他们支持并发。

在管程的发展史上，先后出现过三种不同的管程模型，分别是：Hasen 模型、Hoare 模型和 MESA 模型。其中，现在广泛应用的是 MESA 模型，并且 Java 管程的实现参考的也是 MESA 模型。

![](https://cdn.yangbingdong.com/img/concurrent/monitor-module01.png)

```java
public class BlockedQueue<T>{
  final Lock lock =
    new ReentrantLock();
  // 条件变量：队列不满  
  final Condition notFull =
    lock.newCondition();
  // 条件变量：队列不空  
  final Condition notEmpty =
    lock.newCondition();

  // 入队
  void enq(T x) {
    lock.lock();
    try {
      while (队列已满){
        // 等待队列不满 
        notFull.await();
      }  
      // 省略入队操作...
      //入队后,通知可出队
      notEmpty.signal();
    }finally {
      lock.unlock();
    }
  }
  // 出队
  void deq(){
    lock.lock();
    try {
      while (队列已空){
        // 等待队列不空
        notEmpty.await();
      }
      // 省略出队操作...
      //出队后，通知可入队
      notFull.signal();
    }finally {
      lock.unlock();
    }  
  }
}
```

