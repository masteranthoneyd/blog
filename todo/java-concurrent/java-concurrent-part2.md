# Lock和Condition

> 在并发编程领域，有两大核心问题：一个是**互斥**，即同一时刻只允许一个线程访问共享资源；另一个是**同步**，即线程之间如何通信、协作。这两大问题，管程都是能够解决的。**Java SDK 并发包通过 Lock 和 Condition 两个接口来实现管程，其中 Lock 用于解决互斥问题，Condition 用于解决同步问题。**

## 造轮子的理由

Java 已经提供了管程的相关实现 `synchronized`, 那么为什么还有一个 `Lock`, 需要了解一下 `synchronized` 的局限性. 在 *[上一篇的死锁问题](https://yangbingdong.com/2019/java-concurrent-part1/#%E6%AD%BB%E9%94%81)* 中, 提出了一个**破坏不可抢占条件**方案, 这个方案 `synchronized` 没有办法解决。原因是 `synchronized` 申请资源的时候，如果申请不到，线程直接进入阻塞状态了，而线程进入阻塞状态，啥都干不了，也释放不了线程已经占有的资源。

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

## 如何保证可见性

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

## 可重入锁

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

## 公平锁与非公平锁

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