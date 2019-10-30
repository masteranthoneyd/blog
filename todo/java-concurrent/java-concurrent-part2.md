![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-lock-condition-banner.png)

# Lock&Condition

> 在并发编程领域，有两大核心问题：一个是**互斥**，即同一时刻只允许一个线程访问共享资源；另一个是**同步**，即线程之间如何通信、协作。这两大问题，管程都是能够解决的。**Java SDK 并发包通过 Lock 和 Condition 两个接口来实现管程，其中 Lock 用于解决互斥问题，Condition 用于解决同步问题。**

## Lock

### 造轮子的理由

Java 已经提供了管程的相关实现 `synchronized`, 那么为什么还有一个 `Lock`, 需要了解一下 `synchronized` 的局限性. 在 *[上一篇的死锁问题](https://yangbingdong.com/2019/java-concurrent-part1/#%E6%AD%BB%E9%94%81)* 中, 提出了一个**破坏不可抢占条件**方案, 这个方案 `synchronized` 没有办法解决。原因是 `synchronized` 申请资源的时候，如果申请不到，线程直接进入阻塞状态了，而线程进入阻塞状态，啥都干不了，也释放不了线程已经占有的资源。

在 Lock 的API 中, 体现了实现这个方案的三个办法:

```java
// 支持中断的API
void lockInterruptibly() 
  throws InterruptedException;
// 支持超时的API
boolean tryLock(long time, TimeUnit unit) 
  throws InterruptedException;
// 支持非阻塞获取锁的API
boolean tryLock();
```

### 如何保证可见性

> Java 里多线程的可见性是**通过 Happens-Before 规则保证的**，而 `synchronized` 之所以能够保证可见性，也是因为有一条 `synchronized` 相关的规则：`synchronized` 的解锁 Happens-Before 于后续对这个锁的加锁。

先来看一段代码:

```java
class X {
  private final Lock rtl =
  new ReentrantLock();
  int value;
  public void addOne() {
    // 获取锁
    rtl.lock();  
    try {
      value+=1;
    } finally {
      // 保证锁能释放
      rtl.unlock();
    }
  }
}
```

> `try{}finally{}` 是 Lock 使用的经典范式.

Lock **利用了 `volatile` 相关的 Happens-Before 规则** 保证可见性. Java SDK 里面的 `ReentrantLock`，内部持有一个 `volatile` 的成员变量 `state`，获取锁的时候，会读写 `state` 的值；解锁的时候，也会读写 `state` 的值, 简化版代码如下:

```java
class SampleLock {
  volatile int state;
  // 加锁
  lock() {
    // 省略代码无数
    state = 1;
  }
  // 解锁
  unlock() {
    // 省略代码无数
    state = 0;
  }
}
```

根据相关的 Happens-Before 规则：

1. **顺序性规则**：对于线程 T1，`value+=1` Happens-Before 释放锁的操作 `unlock()`；
2. **`volatile` 变量规则**：由于 `state = 1` 会先读取 `state`，所以线程 T1 的 `unlock()` 操作 Happens-Before 线程 T2 的 `lock()` 操作；
3. **传递性规则**：线程 T1 的 `value+=1` Happens-Before 线程 T2 的 `lock()` 操作。

### 可重入锁

上面代码中创建的锁为 `ReentrantLock`, 翻译过来为可重入锁, 所谓可重入锁，顾名思义，指的是**线程可以重复获取同一把锁**。

例如下面代码中，当线程 T1 执行到 ① 处时，已经获取到了锁 rtl ，当在 ① 处调用 `get()` 方法时，会在 ② 再次对锁 rtl 执行加锁操作。此时，如果锁 rtl 是可重入的，那么线程 T1 可以再次加锁成功；如果锁 rtl 是不可重入的，那么线程 T1 此时会被阻塞。

```java
class X {
  private final Lock rtl =
  new ReentrantLock();
  int value;
  public int get() {
    // 获取锁
    rtl.lock();         ②
    try {
      return value;
    } finally {
      // 保证锁能释放
      rtl.unlock();
    }
  }
  public void addOne() {
    // 获取锁
    rtl.lock();  
    try {
      value = 1 + get(); ①
    } finally {
      // 保证锁能释放
      rtl.unlock();
    }
  }
}
```

### 公平锁与非公平锁

`ReentrantLock` 这个类有两个构造函数:

```java
//无参构造函数：默认非公平锁
public ReentrantLock() {
    sync = new NonfairSync();
}
//根据公平策略参数创建锁
public ReentrantLock(boolean fair){
    sync = fair ? new FairSync() 
                : new NonfairSync();
}
```

锁都对应着一个等待队列，如果一个线程没有获得锁，就会进入等待队列，当有线程释放锁的时候，就需要从等待队列中唤醒一个等待的线程。如果是公平锁，唤醒的策略就是谁等待的时间长，就唤醒谁，很公平；如果是非公平锁，则不提供这个公平保证，有可能等待时间短的线程反而先被唤醒。

并发大师 Doug Lea《Java 并发编程：设计原则与模式》一书中，推荐的三个用锁的最佳实践，它们分别是：

* 永远只在更新对象的成员变量时加锁;
* 永远只在访问可变的成员变量时加锁;
* 永远不在调用其他对象的方法时加锁.



## Condition

**Condition 实现了管程模型里面的条件变量**, Java 内置的管程实现只支持一个条件变量, 而 Lock&Condition 实现的管程是**支持多个条件变量**的，这是二者的一个重要区别.

在很多并发场景下，支持多个条件变量能够让我们的并发程序可读性更好，实现起来也更容易。例如，实现一个阻塞队列，就需要两个条件变量:

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

# Semaphore: 如何快速实现一个限流器

一般被翻译为**信号量**, 由大名鼎鼎的计算机科学家迪杰斯特拉（Dijkstra）于 1965 年提出，在这之后的 15 年，信号量一直都是并发编程领域的终结者，直到 1980 年管程被提出来.

信号量一般用于**控制资源访问的并发数量**, 比如数据库链接资源, 读取千万条数据, 但是数据库链接就只有20个, 需要控制连接池的并发使用数量. 

## 信号量模型

**一个计数器，一个等待队列，三个方法。**

![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-semaphore-module.png)

* `init()`：设置计数器的初始值。
* `down()`：计数器的值减 1；如果此时计数器的值小于 0，则当前线程将被阻塞，否则当前线程可以继续执行。
* `up()`：计数器的值加 1；如果此时计数器的值小于或者等于 0，则唤醒等待队列中的一个线程，并将其从等待队列中移除。

这里提到的三个方法都是原子性的，并且这个原子性是由信号量模型的实现方保证的。在 Java SDK 里面，信号量模型是由 `java.util.concurrent.Semaphore` 实现的，`Semaphore` 这个类能够保证这三个方法都是原子操作, 其中, `down()` 和 `up()` 对应的则是 `acquire()` 和 `release()`。

> 在信号量模型里面，`down()`、`up()` 这两个操作历史上最早称为 P 操作和 V 操作，所以信号量模型也被称为 **PV 原语**。

## 使用

实现一个停车场停车限制:

```java
public class ParkingSpotManager {

    private static final int MAX_SIZE = 10;
    private final BlockingQueue<ParkingSpot> parkingSpots = new LinkedBlockingQueue<>(MAX_SIZE);
    private final Semaphore sem = new Semaphore(MAX_SIZE);

    public ParkingSpotManager() {
        ParkingSpot parkingSpot;
        for (int i = 0; i < MAX_SIZE; i++) {
            parkingSpot = new ParkingSpot();
            parkingSpot.setId(i);
            parkingSpots.add(parkingSpot);
        }
    }

    public void park(Consumer<ParkingSpot> consumer) {
        ParkingSpot parkingSpot = null;
        try {
            sem.acquire(1);
            parkingSpot = parkingSpots.remove();
            consumer.accept(parkingSpot);
        } catch (InterruptedException e) {
            throw new RuntimeException(e);
        } finally {
            if (parkingSpot != null) {
                parkingSpots.add(parkingSpot);
            }
            sem.release(1);
        }
    }

    public static void main(String[] args) {
        ParkingSpotManager parkingSpotManager = new ParkingSpotManager();

        ExecutorService executorService = Executors.newFixedThreadPool(50);
        for (int i = 0; i < 50; i++) {
            executorService.execute(() -> parkingSpotManager.park(parkingSpot -> {
                System.out.println(Thread.currentThread().getName() + " 拿到车位, 车位号: " + parkingSpot.getId());
                try {
                    Thread.sleep(ThreadLocalRandom.current().nextLong(500, 1000));
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }));
        }
        executorService.shutdown();
    }
}
```

# ReadWriteLock: 如何快速实现一个完备的缓存

Java 已经实现了管程和信号量这两个同步原语, 那么为什么并发包下还有那么多工具? 答案是**分场景优化性能，提升易用性。**

有一个常见的应用场景: **读多写少**, 比如缓存. 针对读多写少这种并发场景，Java SDK 并发包提供了**读写锁**——`ReadWriteLock`.

读写锁，并不是 Java 语言特有的，而是一个广为使用的通用技术，所有的读写锁都遵守以下三条基本原则：

* 允许多个线程同时读共享变量；
* 只允许一个线程写共享变量；
* 如果一个写线程正在执行写操作，此时禁止读线程读共享变量。

读写锁与互斥锁的一个重要区别就是**读写锁允许多个线程同时读共享变量**，而互斥锁是不允许的，这是读写锁在读多写少场景下性能优于互斥锁的关键。但**读写锁的写操作是互斥的**，当一个线程在写共享变量的时候，是不允许其他线程执行写操作和读操作。

一个简单的缓存实现:

```java
class Cache<K,V> {
  final Map<K, V> m =
    new HashMap<>();
  final ReadWriteLock rwl =
    new ReentrantReadWriteLock();
  // 读锁
  final Lock r = rwl.readLock();
  // 写锁
  final Lock w = rwl.writeLock();
  // 读缓存
  V get(K key) {
    r.lock();
    try { return m.get(key); }
    finally { r.unlock(); }
  }
  // 写缓存
  V put(K key, V value) {
    w.lock();
    try { return m.put(key, v); }
    finally { w.unlock(); }
  }
}
```

按需加载, 即当缓存不存在, 再查询数据库:

```java
class Cache<K,V> {
  final Map<K, V> m =
    new HashMap<>();
  final ReadWriteLock rwl = 
    new ReentrantReadWriteLock();
  final Lock r = rwl.readLock();
  final Lock w = rwl.writeLock();
 
  V get(K key) {
    V v = null;
    //读缓存
    r.lock();         ①
    try {
      v = m.get(key); ②
    } finally{
      r.unlock();     ③
    }
    //缓存中存在，返回
    if(v != null) {   ④
      return v;
    }  
    //缓存中不存在，查询数据库
    w.lock();         ⑤
    try {
      //再次验证
      //其他线程可能已经查询过数据库
      v = m.get(key); ⑥
      if(v == null){  ⑦
        //查询数据库
        v=省略代码无数
        m.put(key, v);
      }
    } finally{
      w.unlock();
    }
    return v; 
  }
}
```

## 锁升级

先来看一段代码:

```java
//读缓存
r.lock();         ①
try {
  v = m.get(key); ②
  if (v == null) {
    w.lock();
    try {
      //再次验证并更新缓存
      //省略详细代码
    } finally{
      w.unlock();
    }
  }
} finally{
  r.unlock();     ③
}
```

在①处获取读锁，在③处释放读锁，那是否可以在②处的下面增加验证缓存并更新缓存, 这个叫**锁的升级**.

可惜 `ReadWriteLock` 并不支持这种升级。在上面的代码示例中，读锁还没有释放，此时获取写锁，会导致写锁永久等待，最终导致相关线程都被阻塞，永远也没有机会被唤醒。

不过，虽然锁的升级是不允许的，但是**锁的降级**却是允许的:

```java
class CachedData {
  Object data;
  volatile boolean cacheValid;
  final ReadWriteLock rwl =
    new ReentrantReadWriteLock();
  // 读锁  
  final Lock r = rwl.readLock();
  //写锁
  final Lock w = rwl.writeLock();
  
  void processCachedData() {
    // 获取读锁
    r.lock();
    if (!cacheValid) {
      // 释放读锁，因为不允许读锁的升级
      r.unlock();
      // 获取写锁
      w.lock();
      try {
        // 再次检查状态  
        if (!cacheValid) {
          data = ...
          cacheValid = true;
        }
        // 释放写锁前，降级为读锁
        // 降级是可以的
        r.lock(); ①
      } finally {
        // 释放写锁
        w.unlock(); 
      }
    }
    // 此处仍然持有读锁
    try {use(data);} 
    finally {r.unlock();}
  }
}
```

在代码①处，获取读锁的时候线程还是持有写锁的，这种锁的降级是支持的。

> 读写锁类似于 `ReentrantLock`，也支持公平模式和非公平模式。读锁和写锁都实现了 `java.util.concurrent.locks.Lock` 接口，所以除了支持 `lock()` 方法外，`tryLock()`、`lockInterruptibly()` 等方法也都是支持的。但是有一点需要注意，那就是只有写锁支持条件变量，读锁是不支持条件变量的，读锁调用 `newCondition()` 会抛出 `UnsupportedOperationException` 异常。

# StampedLock: 读写锁更快的锁

`StampedLock` 类，在 JDK1.8 时引入，是对读写锁 `ReentrantReadWriteLock` 的增强，该类提供了一些功能，优化了读锁、写锁的访问，同时使读写锁之间可以互相转换，更细粒度控制并发。该类的设计初衷是作为一个内部工具类，用于辅助开发其它线程安全组件，用得好，该类可以提升系统性能，用不好，容易产生死锁和其它莫名其妙的问题。

## 特点

StampedLock的主要特点概括一下，有以下几点：

1. 所有获取锁的方法，都返回一个邮戳（Stamp），Stamp为0表示获取失败，其余都表示成功；
2. 所有释放锁的方法，都需要一个邮戳（Stamp），这个Stamp必须是和成功获取锁时得到的Stamp一致；
3. `StampedLock` 是不可重入的；（如果一个线程已经持有了写锁，再去获取写锁的话就会造成死锁）
4. `StampedLock` 有三种访问模式：
   * Reading（读模式）：功能和 `ReentrantReadWriteLock` 的读锁类似;
   * Writing（写模式）：功能和 `ReentrantReadWriteLock` 的写锁类似;
   * Optimistic reading（**乐观读模式**）：这是一种优化的读模式;
5. `StampedLock` 支持读锁和写锁的相互转换
   我们知道 RRW 中，当线程获取到写锁后，可以降级为读锁，但是读锁是不能直接升级为写锁的。
   StampedLock 提供了读锁和写锁相互转换的功能，使得该类支持更多的应用场景;
6. 无论写锁还是读锁，都不支持 Conditon 等待条件.

在 `ReentrantReadWriteLock` 中，当读锁被使用时，如果有线程尝试获取写锁，**该写线程会阻塞**。
但是，在 Optimistic reading 中，即使读线程获取到了读锁，写线程尝试获取写锁也不会阻塞，这相当于对读模式的优化，但是**可能会导致数据不一致的问题**。所以，当使用 Optimistic reading 获取到读锁时，**必须对获取结果进行校验**。

## 乐观读

读写锁的用法与 `ReentrantReadWriteLock` 类似, `StampedLock` 的性能之所以比 `ReadWriteLock` 还要好，其关键是 `StampedLock` 支持乐观读的方式。注意这里，用的是“**乐观读**”这个词，而不是“乐观读锁”，乐观读这个操作是**无锁**的，所以相比较 `ReadWriteLock` 的读锁，乐观读的性能更好一些。

以下是来自官网乐观读的一段代码:

```java
    /**
     * 使用乐观读锁访问共享资源
     * 注意：乐观读锁在保证数据一致性上需要拷贝一份要操作的变量到方法栈，并且在操作数据时候可能其他写线程已经修改了数据，
     * 而我们操作的是方法栈里面的数据，也就是一个快照，所以最多返回的不是最新的数据，但是一致性还是得到保障的。
     *
     * @return
     */
    double distanceFromOrigin() {
        long stamp = sl.tryOptimisticRead();    // 使用乐观读锁
        double currentX = x, currentY = y;      // 拷贝共享资源到本地方法栈中
        if (!sl.validate(stamp)) {              // 如果有写锁被占用，可能造成数据不一致，所以要切换到普通读锁模式
            stamp = sl.readLock();             
            try {
                currentX = x;
                currentY = y;
            } finally {
                sl.unlockRead(stamp);
            }
        }
        return Math.sqrt(currentX * currentX + currentY * currentY);
    }
```

Optimistic reading 的使用必须遵循以下模式：

```java
long stamp = lock.tryOptimisticRead();  // 非阻塞获取版本信息
copyVaraibale2ThreadMemory();           // 拷贝变量到线程本地堆栈
if(!lock.validate(stamp)){              // 校验
    long stamp = lock.readLock();       // 获取读锁
    try {
        copyVaraibale2ThreadMemory();   // 拷贝变量到线程本地堆栈
     } finally {
       lock.unlock(stamp);              // 释放悲观锁
    }

}
useThreadMemoryVarables();              // 使用线程本地堆栈里面的数据进行操作
```

## 锁升级

`StampedLock` 支持锁的降级（通过 `tryConvertToReadLock()` 方法实现）和升级（通过 `tryConvertToWriteLock()` 方法实现），但是建议慎重使用。下面的代码也源自 Java 的官方示例:

```java
    void moveIfAtOrigin(double newX, double newY) { // upgrade
        // Could instead start with optimistic, not read mode
        long stamp = sl.readLock();
        try {
            while (x == 0.0 && y == 0.0) {
                long ws = sl.tryConvertToWriteLock(stamp);  //读锁转换为写锁
                if (ws != 0L) {
                    stamp = ws;
                    x = newX;
                    y = newY;
                    break;
                } else {
                    sl.unlockRead(stamp);
                    stamp = sl.writeLock();
                }
            }
        } finally {
            sl.unlock(stamp);
        }
    }
```

## 注意事项

* `StampedLock` 不支持重入,重入会导致死锁.
* 使用 `StampedLock` 一定不要调用中断操作, 一定使用可中断的悲观读锁 `readLockInterruptibly()` 和写锁 `writeLockInterruptibly()`.

# CountDownLatch和CyclicBarrier: 如何让多线程步调一致

`CountDownLatch` 和 `CyclicBarrier` 是 Java 并发包提供的两个非常易用的**线程同步工具类**，这两个工具类用法的区别在这里还是有必要再强调一下：

* `CountDownLatch` 主要用来**解决一个线程等待多个线程的场景**，可以类比旅游团团长要等待所有的游客到齐才能去下一个景点；
* 而 `CyclicBarrier` 是**一组线程之间互相等待**，更像是几个驴友之间不离不弃。

除此之外 `CountDownLatch` 的计数器是**不能循环利用**的，也就是说一旦计数器减到 0，再有线程调用 await()，该线程会直接通过。但 `CyclicBarrier` 的计数器是**可以循环利用**的，而且具备**自动重置**的功能，一旦计数器减到 0 会自动重置到你设置的初始值。除此之外，`CyclicBarrier` 还可以设置回调函数，可以说是功能丰富。

举个例子就是做一个对账功能, 首先查询订单，然后查询派送单，之后对比订单和派送单，将差异写入差异库:

![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-countdownlatch01.png)

抽象代码如下:

```java
while(存在未对账订单){
  // 查询未对账订单
  pos = getPOrders();
  // 查询派送单
  dos = getDOrders();
  // 执行对账操作
  diff = check(pos, dos);
  // 差异写入差异库
  save(diff);
} 
```

执行流程是这样的:

![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-countdownlatch02.png)

其实 `getPOrders()` 与 `getDOrders()` 是可以并行执行的:

![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-countdownlatch03.png)

这时候可以使用 `CountDownLatch` 来实现:

```java
// 创建2个线程的线程池
Executor executor = 
  Executors.newFixedThreadPool(2);
while(存在未对账订单){
  // 计数器初始化为2
  CountDownLatch latch = 
    new CountDownLatch(2);
  // 查询未对账订单
  executor.execute(()-> {
    pos = getPOrders();
    latch.countDown();
  });
  // 查询派送单
  executor.execute(()-> {
    dos = getDOrders();
    latch.countDown();
  });
  
  // 等待两个查询操作结束
  latch.await();
  
  // 执行对账操作
  diff = check(pos, dos);
  // 差异写入差异库
  save(diff);
}
```

当然, 我们也可以使用线程的 `join()` 来实现:

```java
while(存在未对账订单){
  // 查询未对账订单
  Thread T1 = new Thread(()->{
    pos = getPOrders();
  });
  T1.start();
  // 查询派送单
  Thread T2 = new Thread(()->{
    dos = getDOrders();
  });
  T2.start();
  // 等待T1、T2结束
  T1.join();
  T2.join();
  // 执行对账操作
  diff = check(pos, dos);
  // 差异写入差异库
  save(diff);
} 
```

缺点就是每次都需要创建以及销毁线程, 非常消耗资源.

想一想, 还能再优化吗? 我们将 `getPOrders()` 和 `getDOrders()` 这两个查询操作并行了，但这两个查询操作和对账操作 `check()`、`save()` 之间还是串行的。很显然，这两个查询操作和对账操作也是可以并行的，也就是说，在执行对账操作的时候，可以同时去执行下一轮的查询操作:

![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-countdownlatch04.png)

两次查询操作能够和对账操作并行，对账操作还依赖查询操作的结果，这明显有点生产者 - 消费者的意思. 那么需要两个队列, 并且两个队列的元素之间还有对应关系:

![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-countdownlatch05.png)

但线程 T1 和线程 T2 的工作要步调一致，不能一个跑得太快，一个跑得太慢，只有这样才能做到各自生产完 1 条数据的时候，通知线程 T3。

![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-countdownlatch06.png)

这时候 `CyclicBarrier` 就派上用场了:

```java
// 订单队列
Vector<P> pos;
// 派送单队列
Vector<D> dos;
// 执行回调的线程池 
Executor executor = 
  Executors.newFixedThreadPool(1);
final CyclicBarrier barrier =
  new CyclicBarrier(2, ()->{
    executor.execute(()->check());
  });
  
void check(){
  P p = pos.remove(0);
  D d = dos.remove(0);
  // 执行对账操作
  diff = check(p, d);
  // 差异写入差异库
  save(diff);
}
  
void checkAll(){
  // 循环查询订单库
  Thread T1 = new Thread(()->{
    while(存在未对账订单){
      // 查询订单库
      pos.add(getPOrders());
      // 等待
      barrier.await();
    }
  });
  T1.start();  
  // 循环查询运单库
  Thread T2 = new Thread(()->{
    while(存在未对账订单){
      // 查询运单库
      dos.add(getDOrders());
      // 等待
      barrier.await();
    }
  });
  T2.start();
}
```

这里有两个注意点:

1. 为啥要用线程池，而不是在回调函数中直接调用？使用线程池是为了异步操作，否则回掉函数是同步调用的，也就是本次对账操作执行完才能进行下一轮的检查。
2. 线程池为啥使用单线程的？线程数量固定为1，防止了多线程并发导致的数据不一致，因为订单和派送单是两个队列，只有单线程去两个队列中取消息才不会出现消息不匹配的问题。

# 线程安全的容器

## 同步容器

Java 1.5 之前提供的**同步容器**虽然也能保证线程安全，但是性能很差. Java 中的容器主要可以分为四个大类，分别是 `List`、`Map`、`Set` 和 `Queue`，但并不是所有的 Java 容器都是线程安全的。例如，我们常用的 `ArrayList`、`HashMap` 就不是线程安全的。

那么如何将非线程安全的容器变成线程安全的容器？之前说过, 只要把**非线程安全的容器封装在对象内部**，然后控制好访问路径就可以了。

```java
SafeArrayList<T>{
  //封装ArrayList
  List<T> c = new ArrayList<>();
  //控制访问路径
  synchronized
  T get(int idx){
    return c.get(idx);
  }

  synchronized
  void add(int idx, T t) {
    c.add(idx, t);
  }

  synchronized
  boolean addIfNotExist(T t){
    if(!c.contains(t)) {
      c.add(t);
      return true;
    }
    return false;
  }
}
```

JDK 的 `Collections` 这个类中还提供了一套完备的包装类，比如下面的示例代码中，分别把 `ArrayList`、`HashSet` 和 `HashMap` 包装成了线程安全的 `List`、`Set` 和 `Map`:

```java
List list = Collections.
  synchronizedList(new ArrayList());
Set set = Collections.
  synchronizedSet(new HashSet());
Map map = Collections.
  synchronizedMap(new HashMap());
```

组合操作需要注意**竞态条件问题**，例如上面提到的 `addIfNotExist()` 方法就包含组合操作。组合操作往往隐藏着**竞态条件**问题，即便每个操作都能保证原子性，也并不能保证组合操作的原子性，这个一定要注意。

在容器领域一个**容易被忽视的“坑”是用迭代器遍历容器**，例如在下面的代码中，通过迭代器遍历容器 list，对每个元素调用 `foo()` 方法，这就存在并发问题，这些组合的操作不具备原子性:

```java
List list = Collections.
  synchronizedList(new ArrayList());
Iterator i = list.iterator(); 
while (i.hasNext())
  foo(i.next());
```

正确的写法应该是这样:

```java
List list = Collections.
  synchronizedList(new ArrayList());
Iterator i = list.iterator(); 
while (i.hasNext())
  foo(i.next());
```

上面提到的这些经过包装后线程安全容器，都是**基于 `synchronized` 这个同步关键字实现**的，所以也被称为**同步容器**。Java 提供的同步容器还有 `Vector`、`Stack` 和 `Hashtable`，这三个容器不是基于包装类实现的，但同样是基于 `synchronized` 实现的，对这三个容器的遍历，同样要加锁保证互斥。

## 并发容器

上面提到的同步容器都是基于 `synchronized` 来实现的, 因此性能不高, 因此 Java 在 1.5 及之后版本提供了性能更高的容器，我们一般称为并发容器。

![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-container01.png)