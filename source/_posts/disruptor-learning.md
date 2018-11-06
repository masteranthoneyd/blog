---
title: 极致的追求：高性能并发框架 Disruptor
date: 2018-02-05 15:52:51
categories: [Programming, Java]
tags: [Java, Disruptor]
---

![](https://cdn.yangbingdong.com/img/disruptor-learning/Models.png)

# Preface

> [Disruptor](https://lmax-exchange.github.io/disruptor/)是英国外汇交易公司LMAX开发的一个高性能队列，研发的初衷是**解决内存队列的延迟问题**（在性能测试中发现竟然与I/O操作处于同样的数量级）。基于Disruptor开发的系统单线程能支撑**每秒600万订单**，2010年在QCon演讲后，获得了业界关注。2011年，企业应用软件专家Martin Fowler专门撰写长文介绍。同年它还获得了Oracle官方的Duke大奖。目前，包括**Apache Storm**、**Camel**、**Log4j2**、**Reactor**在内的很多知名项目都应用或参考了Disruptor以获取高性能。
>
> 其实Disruptor与其说是一个框架，不如说是一种设计思路，这个设计思路对于存在“并发、缓冲区、生产者—消费者模型、事务处理”这些元素的程序来说，Disruptor提出了一种大幅提升性能（TPS）的方案。
>
> 听说小米也是用这个东东把亚马逊搞挂了：[http://bbs.xiaomi.cn/t-13417592](http://bbs.xiaomi.cn/t-13417592)

<!--more-->

# 核心概念

在理解[Disruptor](https://github.com/LMAX-Exchange/disruptor)之前，我们需要看一下它的核心概念

- [**Ring Buffer**](https://github.com/LMAX-Exchange/disruptor/blob/master/src/main/java/com/lmax/disruptor/RingBuffer.java): Ring Buffer通常被认为是Disruptor的主要方面，然而从3.0开始，Ring Buffer只负责存储和更新通过Disruptor的数据（Events）。 而且对于一些高级用例可以完全由用户替换。
- [**Sequence**](https://github.com/LMAX-Exchange/disruptor/blob/master/src/main/java/com/lmax/disruptor/Sequence.java): Disruptor使用序列作为一种手段来确定特定组件的位置。 每个消费者（EventProcessor）都像Disruptor本身一样维护一个Sequence。 大部分并发代码依赖于这些Sequence值的移动，因此Sequence支持AtomicLong的许多当前特性。 事实上，与2版本之间唯一真正的区别是序列包含额外的功能，以防止序列和其他值之间的错误共享。
- [**Sequencer**](https://github.com/LMAX-Exchange/disruptor/blob/master/src/main/java/com/lmax/disruptor/Sequencer.java): Sequencer是Disruptor的真正核心。 这个接口的2个实现（单生产者，多生产者）实现了所有的并发算法，用于在生产者和消费者之间快速正确地传递数据。
- [**Sequence Barrier**](https://github.com/LMAX-Exchange/disruptor/blob/master/src/main/java/com/lmax/disruptor/SequenceBarrier.java): 序列屏障由序列发生器产生，并包含对序列发生器的主要发布序列和任何相关消费者的序列的引用。 它包含确定消费者是否有任何事件可供处理的逻辑。
- [**Wait Strategy**](https://github.com/LMAX-Exchange/disruptor/blob/master/src/main/java/com/lmax/disruptor/WaitStrategy.java): 等待策略决定了消费者如何等待事件被生产者置于Disruptor中。
- **Event**: 从生产者到消费者的数据单位。 事件没有特定的代码表示，因为它完全由用户定义。
- [**EventProcessor**](https://github.com/LMAX-Exchange/disruptor/blob/master/src/main/java/com/lmax/disruptor/EventProcessor.java): 用于处理来自Disruptor的事件的主事件循环，并拥有消费者序列的所有权。 有一个称为BatchEventProcessor的表示，它包含一个有效的事件循环实现，并将回调到EventHandler接口的已用提供的实现上。
- [**EventHandler**](https://github.com/LMAX-Exchange/disruptor/blob/master/src/main/java/com/lmax/disruptor/EventHandler.java): 由用户实现的界面，代表Disruptor的使用者。
- **Producer**: 这是调用Disruptor排入事件的用户代码。 这个概念在代码中也没有表示。

# Java内置队列

> 以下内容来自美团点评技术团队博文

Java的内置队列如下表所示。

| 队列                    | 有界性                | 锁    | 数据结构       |
| --------------------- | ------------------ | ---- | ---------- |
| ArrayBlockingQueue    | bounded            | 加锁   | arraylist  |
| LinkedBlockingQueue   | optionally-bounded | 加锁   | linkedlist |
| ConcurrentLinkedQueue | unbounded          | 无锁   | linkedlist |
| LinkedTransferQueue   | unbounded          | 无锁   | linkedlist |
| PriorityBlockingQueue | unbounded          | 加锁   | heap       |
| DelayQueue            | unbounded          | 加锁   | heap       |

队列的底层一般分成三种：数组、链表和堆。其中，堆一般情况下是为了实现带有优先级特性的队列，暂且不考虑。

我们就从数组和链表两种数据结构来看，基于数组线程安全的队列，比较典型的是`ArrayBlockingQueue`，它主要通过加锁的方式来保证线程安全；基于链表的线程安全队列分成`LinkedBlockingQueue`和`ConcurrentLinkedQueue`两大类，前者也通过锁的方式来实现线程安全，而后者以及上面表格中的`LinkedTransferQueue`都是通过原子变量`compare and swap`（以下简称“**CAS**”）这种不加锁的方式来实现的。

通过不加锁的方式实现的队列都是**无界**的（无法保证队列的长度在确定的范围内）；而加锁的方式，可以实现有界队列。在稳定性要求特别高的系统中，为了防止生产者速度过快，导致内存溢出，只能选择有界队列；同时，为了减少Java的垃圾回收对系统性能的影响，会尽量选择`array/heap`格式的数据结构。这样筛选下来，符合条件的队列就只有`ArrayBlockingQueue`。

# ArrayBlockingQueue的问题

`ArrayBlockingQueue`在实际使用过程中，会因为加锁和伪共享等出现严重的性能问题，我们下面来分析一下。

## 加锁

现实编程过程中，加锁通常会严重地影响性能。线程会因为竞争不到锁而被挂起，等锁被释放的时候，线程又会被恢复，这个过程中存在着很大的开销，并且通常会有较长时间的中断，因为当一个线程正在等待锁时，它不能做任何其他事情。如果一个线程在持有锁的情况下被延迟执行，例如发生了缺页错误、调度延迟或者其它类似情况，那么所有需要这个锁的线程都无法执行下去。如果被阻塞线程的优先级较高，而持有锁的线程优先级较低，就会发生优先级反转。

Disruptor论文中讲述了一个实验：

- 这个测试程序调用了一个函数，该函数会对一个64位的计数器循环自增5亿次。
- 机器环境：2.4G 6核
- 运算： 64位的计数器累加5亿次

| Method                            | Time (ms) |
| --------------------------------- | --------- |
| Single thread                     | 300       |
| Single thread with CAS            | 5,700     |
| Single thread with lock           | 10,000    |
| Single thread with volatile write | 4,700     |
| Two threads with CAS              | 30,000    |
| Two threads with lock             | 224,000   |

CAS操作比单线程无锁慢了1个数量级；有锁且多线程并发的情况下，速度比单线程无锁慢3个数量级。可见无锁速度最快。

单线程情况下，不加锁的性能 > CAS操作的性能 > 加锁的性能。

在多线程情况下，为了保证线程安全，必须使用CAS或锁，这种情况下，CAS的性能超过锁的性能，前者大约是后者的8倍。

**综上可知，加锁的性能是最差的。**

### 关于锁和CAS

保证线程安全一般分成两种方式：锁和原子变量。

#### 锁

![img](https://cdn.yangbingdong.com/img/disruptor-learning/lock.png)

采取加锁的方式，默认线程会冲突，访问数据时，先加上锁再访问，访问之后再解锁。通过锁界定一个临界区，同时只有一个线程进入。如上图所示，`Thread2`访问`Entry`的时候，加了锁，`Thread1`就不能再执行访问`Entry`的代码，从而保证线程安全。

下面是`ArrayBlockingQueue`通过加锁的方式实现的`offer`方法，保证线程安全。

```
public boolean offer(E e) {
    checkNotNull(e);
    final ReentrantLock lock = this.lock;
    lock.lock();
    try {
        if (count == items.length)
            return false;
        else {
            insert(e);
            return true;
        }
    } finally {
        lock.unlock();
    }
}
```

#### 原子变量

原子变量能够保证原子性的操作，意思是某个任务在执行过程中，要么全部成功，要么全部失败回滚，恢复到执行之前的初态，不存在初态和成功之间的中间状态。例如CAS操作，**要么比较并交换成功**，**要么比较并交换失败**。由CPU保证原子性。

通过原子变量可以实现线程安全。执行某个任务的时候，先假定不会有冲突，若不发生冲突，则直接执行成功；当发生冲突的时候，则执行失败，回滚再重新操作，直到不发生冲突。

![img](https://cdn.yangbingdong.com/img/disruptor-learning/cas.png)

如图所示，`Thread1`和`Thread2`都要把`Entry`加1。若不加锁，也不使用CAS，有可能`Thread1`取到了`myValue=1`，`Thread2`也取到了`myValue=1`，然后相加，`Entry`中的`value`值为2。这与预期不相符，我们预期的是`Entry`的值经过两次相加后等于3。

CAS会先把`Entry`现在的`value`跟线程当初读出的值相比较，若相同，则赋值；若不相同，则赋值执行失败。一般会通过`while/for`循环来重新执行，**直到赋值成功**。

代码示例是`AtomicInteger`的`getAndAdd`方法。CAS是CPU的一个指令，由CPU保证原子性。

```
/**
 * Atomically adds the given value to the current value.
 *
 * @param delta the value to add
 * @return the previous value
 */
public final int getAndAdd(int delta) {
    for (;;) {
        int current = get();
        int next = current + delta;
        if (compareAndSet(current, next))
            return current;
    }
}

/**
 * Atomically sets the value to the given updated value
 * if the current value {@code ==} the expected value.
 *
 * @param expect the expected value
 * @param update the new value
 * @return true if successful. False return indicates that
 * the actual value was not equal to the expected value.
 */
public final boolean compareAndSet(int expect, int update) {
    return unsafe.compareAndSwapInt(this, valueOffset, expect, update);
}
```

在高度竞争的情况下，锁的性能将超过原子变量的性能，但是更真实的竞争情况下，原子变量的性能将超过锁的性能。同时原子变量不会有死锁等活跃性问题。

## 伪共享

### 什么是共享

下图是计算的基本结构。L1、L2、L3分别表示一级缓存、二级缓存、三级缓存，越靠近CPU的缓存，速度越快，容量也越小。所以L1缓存很小但很快，并且紧靠着在使用它的CPU内核；L2大一些，也慢一些，并且仍然只能被一个单独的CPU核使用；L3更大、更慢，并且被单个插槽上的所有CPU核共享；最后是主存，由全部插槽上的所有CPU核共享。

![img](https://cdn.yangbingdong.com/img/disruptor-learning/computer.png)

当CPU执行运算的时候，它先去L1查找所需的数据、再去L2、然后是L3，如果最后这些缓存中都没有，所需的数据就要去主内存拿。走得越远，运算耗费的时间就越长。所以如果你在做一些很频繁的事，你要尽量确保数据在L1缓存中。

另外，线程之间共享一份数据的时候，需要一个线程把数据写回主存，而另一个线程访问主存中相应的数据。

下面是从CPU访问不同层级数据的时间概念:

| 从CPU到                                | 大约需要的CPU周期    | 大约需要的时间  |
| ------------------------------------ | ------------- | -------- |
| 主存                                   |               | 约60-80ns |
| QPI 总线传输(between sockets, not drawn) |               | 约20ns    |
| L3 cache                             | 约40-45 cycles | 约15ns    |
| L2 cache                             | 约10 cycles    | 约3ns     |
| L1 cache                             | 约3-4 cycles   | 约1ns     |
| 寄存器                                  | 1 cycle       |          |

可见CPU读取主存中的数据会比从L1中读取慢了近2个数量级。

### 缓存行

Cache是由很多个cache line组成的。每个cache line通常是64字节，并且它有效地引用主内存中的一块儿地址。一个Java的`long`类型变量是8字节，因此在一个缓存行中可以存8个`long`类型的变量。

CPU每次从主存中拉取数据时，会把相邻的数据也存入同一个cache line。

在访问一个long数组的时候，如果数组中的一个值被加载到缓存中，它会自动加载另外7个。因此你能非常快的遍历这个数组。事实上，你可以非常快速的遍历在连续内存块中分配的任意数据结构。

下面的例子是测试利用cache line的特性和不利用cache line的特性的效果对比。

```
public class CacheLineEffect {
    //考虑一般缓存行大小是64字节，一个 long 类型占8字节
    static  long[][] arr;

    public static void main(String[] args) {
        arr = new long[1024 * 1024][];
        for (int i = 0; i < 1024 * 1024; i++) {
            arr[i] = new long[8];
            for (int j = 0; j < 8; j++) {
                arr[i][j] = 0L;
            }
        }
        long sum = 0L;
        long marked = System.currentTimeMillis();
        for (int i = 0; i < 1024 * 1024; i+=1) {
            for(int j =0; j< 8;j++){
                sum = arr[i][j];
            }
        }
        System.out.println("Loop times:" + (System.currentTimeMillis() - marked) + "ms");

        marked = System.currentTimeMillis();
        for (int i = 0; i < 8; i+=1) {
            for(int j =0; j< 1024 * 1024;j++){
                sum = arr[j][i];
            }
        }
        System.out.println("Loop times:" + (System.currentTimeMillis() - marked) + "ms");
    }
}
```

在2G Hz、2核、8G内存的运行环境中测试，速度差一倍。

结果：
Loop times:30ms
Loop times:65ms

### 什么是伪共享

`ArrayBlockingQueue`有三个成员变量：

- `takeIndex`：需要被取走的元素下标
- `putIndex`：可被元素插入的位置的下标
- `count`：队列中元素的数量

这三个变量很容易放到一个缓存行中，但是之间修改没有太多的关联。所以每次修改，都会使之前缓存的数据失效，从而不能完全达到共享的效果。

![img](https://cdn.yangbingdong.com/img/disruptor-learning/falseSharing.png)

如上图所示，当生产者线程`put`一个元素到`ArrayBlockingQueue`时，`putIndex`会修改，从而导致消费者线程的缓存中的缓存行无效，需要从主存中重新读取。

这种无法充分使用缓存行特性的现象，称为伪共享。

对于伪共享，一般的解决方案是，增大数组元素的间隔使得由不同线程存取的元素位于不同的缓存行上，以空间换时间。

```
public class FalseSharing implements Runnable{
        public final static long ITERATIONS = 500L * 1000L * 100L;
        private int arrayIndex = 0;

        private static ValuePadding[] longs;
        public FalseSharing(final int arrayIndex) {
            this.arrayIndex = arrayIndex;
        }

        public static void main(final String[] args) throws Exception {
            for(int i=1;i<10;i++){
                System.gc();
                final long start = System.currentTimeMillis();
                runTest(i);
                System.out.println("Thread num "+i+" duration = " + (System.currentTimeMillis() - start));
            }

        }

        private static void runTest(int NUM_THREADS) throws InterruptedException {
            Thread[] threads = new Thread[NUM_THREADS];
            longs = new ValuePadding[NUM_THREADS];
            for (int i = 0; i < longs.length; i++) {
                longs[i] = new ValuePadding();
            }
            for (int i = 0; i < threads.length; i++) {
                threads[i] = new Thread(new FalseSharing(i));
            }

            for (Thread t : threads) {
                t.start();
            }

            for (Thread t : threads) {
                t.join();
            }
        }

        public void run() {
            long i = ITERATIONS + 1;
            while (0 != --i) {
                longs[arrayIndex].value = 0L;
            }
        }

        public final static class ValuePadding {
            protected long p1, p2, p3, p4, p5, p6, p7;
            protected volatile long value = 0L;
            protected long p9, p10, p11, p12, p13, p14;
            protected long p15;
        }
        public final static class ValueNoPadding {
            // protected long p1, p2, p3, p4, p5, p6, p7;
            protected volatile long value = 0L;
            // protected long p9, p10, p11, p12, p13, p14, p15;
        }
}
```

在2G Hz，2核，8G内存, jdk 1.7.0_45 的运行环境下，使用了共享机制比没有使用共享机制，速度快了4倍左右。

结果：
Thread num 1 duration = 447
Thread num 2 duration = 463
Thread num 3 duration = 454
Thread num 4 duration = 464
Thread num 5 duration = 561
Thread num 6 duration = 606
Thread num 7 duration = 684
Thread num 8 duration = 870
Thread num 9 duration = 823

把代码中ValuePadding都替换为ValueNoPadding后的结果：
Thread num 1 duration = 446
Thread num 2 duration = 2549
Thread num 3 duration = 2898
Thread num 4 duration = 3931
Thread num 5 duration = 4716
Thread num 6 duration = 5424
Thread num 7 duration = 4868
Thread num 8 duration = 4595
Thread num 9 duration = 4540

备注：在jdk1.8中，有专门的注解`@Contended`来避免伪共享，更优雅地解决问题。

# Disruptor的设计方案

Disruptor通过以下设计来解决队列速度慢的问题：

- 环形数组结构

为了避免垃圾回收，采用数组而非链表。同时，数组对处理器的缓存机制更加友好。

- 元素位置定位

数组长度`2^n`，通过位运算，加快定位的速度。下标采取递增的形式。不用担心`index`溢出的问题。`index`是`long`类型，即使100万QPS的处理速度，也需要30万年才能用完。

- 无锁设计

每个生产者或者消费者线程，会先**申请**可以操作的元素在数组中的位置，申请到之后，直接在该位置写入或者读取数据。

下面忽略数组的环形结构，介绍一下如何实现无锁设计。整个过程通过原子变量CAS，保证操作的线程安全。

## 一个生产者

### 写数据

生产者单线程写数据的流程比较简单：

1. 申请写入m个元素；
2. 若是有m个元素可以写入，则返回**最大的序列号**。这儿主要判断是否会覆盖未读的元素；
3. 若是返回的正确，则生产者开始写入元素。

![img](https://cdn.yangbingdong.com/img/disruptor-learning/singleWriter.png)
图5 单个生产者生产过程示意图

## 多个生产者

多个生产者的情况下，会遇到“如何防止多个线程重复写同一个元素”的问题。Disruptor的解决方法是，**每个线程获取不同的一段数组空间进行操作**。这个通过CAS很容易达到。只需要在分配元素的时候，通过CAS判断一下这段空间是否已经分配出去即可。

但是会遇到一个**新问题**：如何防止读取的时候，读到还未写的元素。Disruptor在多个生产者的情况下，引入了一个与`Ring Buffer`大小相同的`buffer`：`available Buffer`。当某个位置写入成功的时候，便把`availble Buffer`相应的位置置位，标记为写入成功。读取的时候，会遍历`available Buffer`，来判断元素是否已经就绪。

下面分读数据和写数据两种情况介绍。

### 读数据

生产者多线程写入的情况会复杂很多：

1. 申请读取到序号n；
2. 若`writer cursor` >= n，这时仍然无法确定连续可读的最大下标。从`reader cursor`开始读取`available Buffer`，一直查到第一个不可用的元素，然后返回最大连续可读元素的位置；
3. 消费者读取元素。

如下图所示，读线程读到下标为2的元素，三个线程`Writer1`/`Writer2`/`Writer3`正在向`RingBuffer`相应位置写数据，写线程被分配到的最大元素下标是11。

读线程申请读取到下标从3到11的元素，判断`writer cursor>=11`。然后开始读取`availableBuffer`，从3开始，往后读取，发现下标为7的元素没有生产成功，于是`WaitFor(11)`返回6。

然后，消费者读取下标从3到6共计4个元素。

![img](https://cdn.yangbingdong.com/img/disruptor-learning/multWriterReader.png)

### 写数据

多个生产者写入的时候：

1. 申请写入m个元素；
2. 若是有m个元素可以写入，则返回最大的序列号。每个生产者会被分配一段独享的空间；
3. 生产者写入元素，写入元素的同时设置`available Buffer`里面相应的位置，以标记自己哪些位置是已经写入成功的。

如下图所示，`Writer1`和`Writer2`两个线程写入数组，都申请可写的数组空间。`Writer1`被分配了下标3到下表5的空间，`Writer2`被分配了下标6到下标9的空间。

`Writer1`写入下标3位置的元素，同时把`available Buffer`相应位置置位，标记已经写入成功，往后移一位，开始写下标4位置的元素。`Writer2`同样的方式。最终都写入完成。

![img](https://cdn.yangbingdong.com/img/disruptor-learning/multWriterWrite.png)

防止不同生产者对同一段空间写入的代码，如下所示：

```
public long tryNext(int n) throws InsufficientCapacityException
{
    if (n < 1)
    {
        throw new IllegalArgumentException("n must be > 0");
    }

    long current;
    long next;

    do
    {
        current = cursor.get();
        next = current + n;

        if (!hasAvailableCapacity(gatingSequences, n, current))
        {
            throw InsufficientCapacityException.INSTANCE;
        }
    }
    while (!cursor.compareAndSet(current, next));

    return next;
}
```

通过`do`/`while`循环的条件`cursor.compareAndSet(current, next)`，来判断每次申请的空间是否已经被其他生产者占据。假如已经被占据，该函数会返回失败，While循环重新执行，申请写入空间。

消费者的流程与生产者非常类似，这儿就不多描述了。Disruptor通过精巧的无锁设计实现了在高并发情形下的高性能。

# 等待策略

## 生产者的等待策略

暂时只有休眠1ns。

```
LockSupport.parkNanos(1);
```

## 消费者的等待策略

| 名称                            | 说明                                       | 适用场景                                     |
| ----------------------------- | ---------------------------------------- | ---------------------------------------- |
| `BlockingWaitStrategy`        | 默认等待策略。和`BlockingQueue`的实现很类似，通过使用锁和条件（`Condition`）进行线程阻塞的方式，等待生产者唤醒(线程同步和唤醒)。此策略对于线程切换来说，最节约CPU资源，但在高并发场景下性能有限 | CPU资源紧缺，吞吐量和延迟并不重要的场景                    |
| `BusySpinWaitStrategy`        | 死循环策略。消费者线程会尽最大可能监控缓冲区的变化，会占用所有CPU资源,线程一直自旋等待，比较耗CPU | 通过不断重试，减少切换线程导致的系统调用，而降低延迟。推荐在线程绑定到固定的CPU的场景下使用 |
| `LiteBlockingWaitStrategy`    | 通过线程阻塞的方式，等待生产者唤醒，比`BlockingWaitStrategy`要轻，某些情况下可以减少阻塞的次数 |                                          |
| `PhasedBackoffWaitStrategy`   | 根据指定的时间段参数和指定的等待策略决定采用哪种等待策略             | CPU资源紧缺，吞吐量和延迟并不重要的场景                    |
| `SleepingWaitStrategy`        | CPU友好型策略。会在循环中不断等待数据。可通过参数设置,首先进行自旋等待，若不成功，则使用`Thread.yield()`让出CPU，并使用`LockSupport.parkNanos(1)`进行线程睡眠，通过线程调度器重新调度；或一直自旋等待，所以，此策略数据处理数据可能会有较高的延迟，适合用于对延迟不敏感的场景，优点是对生产者线程影响小， 典型应用场景是异步日志 | 性能和CPU资源之间有很好的折中。延迟不均匀                   |
| `TimeoutBlockingWaitStrategy` | 通过参数设置阻塞时间，如果超时则抛出异常                     | CPU资源紧缺，吞吐量和延迟并不重要的场景                    |
| `YieldingWaitStrategy`        | 低延时策略。消费者线程会不断循环监控`RingBuffer`的变化，在循环内部使用`Thread.yield()`让出CPU给其他线程，通过线程调度器重新调度 | 性能和CPU资源之间有很好的折中。延迟比较均匀                  |

# 核心对象

1. `RingBuffer`：环形的一个数据结构，对象初始化时，会使用事件`Event`进行填充。`Buffer`的大小**必须是2的幂次方**，方便移位操作。
2. `Event`：无指定具体接口，用户自己实现，可以携带任何业务数据。
3. `EventFactory`：产生事件`Event`的工厂，由用户自己实现。
4. `EventTranslator`：事件发布的回调接口，由用户实现，负责将业务参数设置到事件中。
5. `Sequencer`：序列产生器，也是协调生产者和消费者及实现高并发的核心。有`MultiProducerSequencer` 和 `SingleProducerSequencer`两个实现类。
6. `SequenceBarrier`：拥有`RingBuffer`的发布事件`Sequence`引用和消费者依赖的`Sequence`引用。决定消费者消费可消费的`Sequence`。
7. `EventHandler`：事件的处理者，由用户自己实现。
8. `EventProcessor`：事件的处理器，单独在一个线程中运行。
9. `WorkHandler`：事件的处理者，由用户自己实现。
10. `WorkProcessor`：事件的处理器，单独在一个线程中运行。
11. `WorkerPool`：一组`WorkProcessor`的处理。
12. `WaitStrategy`：在消费者比生产者快时，消费者处理器的等待策略。

# 用例

按照官方的指南，一般套路如下：

1. 自定义事件类：例如 `LongEvent` 
2. 实现`EventFactory<T>`： 例如`LongEventFactory implements EventFactory<LongEvent>`
3. 实现`EventHandler<T>`（消费者）：例如`LongEventHandler implements EventHandler<LongEvent>`
4. 实现`EventTranslatorOneArg<T, E>`作为生产者，将业务转换为事件：例如`LongEventTranslatorOneArg implements EventTranslatorOneArg<LongEvent, ByteBuffer>`
5. 提供线程池或线程工厂
6. 定义buffer大小，它**必须是2的幂**，否则会在初始化时抛出异常。因为重点在于使用逻辑二进制运算符有着更好的性能；(例如:mod运算)
7. 构建`Disruptor<T>`
8. 启动`disruptor`，`disruptor.start()`
9. 发布事件，驱动自行流转

## 基础事件生产与消费

## 自定义事件

```
package com.yangbingdong.springbootdisruptor.basic;

import lombok.Data;

/**
 * @author ybd
 * @date 18-1-31
 * @contact yangbingdong@1994.gmail
 */
@Data
public class LongEvent {
	private long value;
}

```

## 定义事件工厂

```
package com.yangbingdong.springbootdisruptor.basic;


import com.lmax.disruptor.EventFactory;
import lombok.extern.slf4j.Slf4j;

/**
 * @author ybd
 * @date 18-1-31
 * @contact yangbingdong@1994.gmail
 */
@Slf4j
public class LongEventFactory implements EventFactory<LongEvent> {
	@Override
	public LongEvent newInstance() {
		log.info("logEventFactory create LongEvent...");
		return new LongEvent();
	}
}

```

## 定义消费者

```
package com.yangbingdong.springbootdisruptor.basic;


import com.lmax.disruptor.EventHandler;
import lombok.extern.slf4j.Slf4j;

/**
 * @author ybd
 * @date 18-1-31
 * @contact yangbingdong@1994.gmail
 */
@Slf4j
public class LongEventHandler implements EventHandler<LongEvent> {
	@Override
	public void onEvent(LongEvent event, long sequence, boolean endOfBatch) {
		log.info("handle event: " + event);
	}
}

```

## 定义生产者

### 3.0版本之前

```
package com.yangbingdong.springbootdisruptor.basic;


import com.lmax.disruptor.RingBuffer;

import java.nio.ByteBuffer;

/**
 * @author ybd
 * @date 18-1-31
 * @contact yangbingdong@1994.gmail
 */
public class LongEventProducer {
	private final RingBuffer<LongEvent> ringBuffer;

	public LongEventProducer(RingBuffer<LongEvent> ringBuffer) {
		this.ringBuffer = ringBuffer;
	}

	public void onData(ByteBuffer bb) {
		// Grab the next sequence
		long sequence = ringBuffer.next();
		try {
			// Get the entry in the Disruptor
			LongEvent event = ringBuffer.get(sequence);
			// for the sequence
			// Fill with data
			event.setValue(bb.getLong(0));
		} finally {
			ringBuffer.publish(sequence);
		}
	}
}

```

### 3.0版本之后使用Translators

```
package com.yangbingdong.springbootdisruptor.basic;


import com.lmax.disruptor.EventTranslatorOneArg;

import java.nio.ByteBuffer;

/**
 * @author ybd
 * @date 18-1-31
 * @contact yangbingdong@1994.gmail
 */
public class LongEventProducerWithTranslator implements EventTranslatorOneArg<LongEvent, ByteBuffer>{
	@Override
	public void translateTo(LongEvent event, long sequence, ByteBuffer bb) {
		event.setValue(bb.getLong(0));
	}
}

```

## 测试实例

### 单生产者，单消费者

```
@Test
public void singleProducerLongEventDefaultTest() throws InterruptedException {
	// Executor that will be used to construct new threads for consumers
	Executor executor = Executors.newCachedThreadPool();

	// The factory for the event
	LongEventFactory factory = new LongEventFactory();

	// Specify the size of the ring buffer, must be power of 2.
	int bufferSize = 1 << 3;

	// Construct the Disruptor
	Disruptor<LongEvent> disruptor = new Disruptor<>(factory, bufferSize, executor, ProducerType.SINGLE, new BlockingWaitStrategy());

	// Connect the handler
	disruptor.handleEventsWith(new LongEventHandler());

	// Start the Disruptor, starts all threads running
	disruptor.start();

	// Get the ring buffer from the Disruptor to be used for publishing.
	RingBuffer<LongEvent> ringBuffer = disruptor.getRingBuffer();

	LongEventProducer producer = new LongEventProducer(ringBuffer);

	ByteBuffer bb = ByteBuffer.allocate(8);
	for (long l = 0; l < 100; l++) {
		bb.putLong(0, l);
		producer.onData(bb);
		Thread.sleep(10);
	}
}
```

新版的Disruptor不建议我们使用`Executor`，而使用`ThreadFactory`代替：

```
@Test
public void singleProducerLongEventUseThreadFactoryTest() throws InterruptedException {
	ThreadFactory threadFactory = new ThreadFactory() {
		private final AtomicInteger index = new AtomicInteger(1);
		@Override
		public Thread newThread(Runnable r) {
			return new Thread(null, r, "disruptor-thread-" + index.getAndIncrement());
		}
	};

	LongEventFactory factory = new LongEventFactory();

	int bufferSize = 1 << 3;

	Disruptor<LongEvent> disruptor = new Disruptor<>(factory, bufferSize, threadFactory, ProducerType.SINGLE, new BlockingWaitStrategy());

	disruptor.handleEventsWith(new LongEventHandler());

	disruptor.start();

	RingBuffer<LongEvent> ringBuffer = disruptor.getRingBuffer();

	LongEventProducer producer = new LongEventProducer(ringBuffer);

	ByteBuffer bb = ByteBuffer.allocate(8);
	for (long l = 0; l < 100; l++) {
		bb.putLong(0, l);
		producer.onData(bb);
		Thread.sleep(10);
	}
}
```

新版Disruptor使用Translators：

```
@Test
public void singleProducerLongEventUseTranslatorsTest() throws InterruptedException {
	ThreadFactory threadFactory = new ThreadFactory() {
		private final AtomicInteger index = new AtomicInteger(1);
		@Override
		public Thread newThread(Runnable r) {
			return new Thread(null, r, "disruptor-thread-" + index.getAndIncrement());
		}
	};

	LongEventFactory factory = new LongEventFactory();

	int bufferSize = 1 << 3;

	Disruptor<LongEvent> disruptor = new Disruptor<>(factory, bufferSize, threadFactory, ProducerType.SINGLE, new BlockingWaitStrategy());

	disruptor.handleEventsWith(new LongEventHandler());

	disruptor.start();

	RingBuffer<LongEvent> ringBuffer = disruptor.getRingBuffer();

	LongEventProducerWithTranslator longEventProducerWithTranslator = new LongEventProducerWithTranslator();

	ByteBuffer bb = ByteBuffer.allocate(8);
	for (long l = 0; l < 100; l++) {
		bb.putLong(0, l);
		ringBuffer.publishEvent(longEventProducerWithTranslator, bb);
		Thread.sleep(10);
	}
}
```

![](https://cdn.yangbingdong.com/img/disruptor-learning/simple-test01.jpg)

java8版：

```
@SuppressWarnings("unchecked")
@Test
public void singleProducerLongEventJava8Test() {
	int bufferSize = 1 << 3;

	Disruptor<LongEvent> disruptor = new Disruptor<>(LongEvent::new, bufferSize, (ThreadFactory) Thread::new, ProducerType.SINGLE, new BlockingWaitStrategy());

	disruptor.handleEventsWith((event, sequence, endOfBatch) -> log.info("handle event: " + event));

	disruptor.start();

	RingBuffer<LongEvent> ringBuffer = disruptor.getRingBuffer();

	ByteBuffer bb = ByteBuffer.allocate(8);
	LongStream.range(0, 100)
			  .forEach(tryLongConsumer(l -> {
				  bb.putLong(0, l);
				  ringBuffer.publishEvent((event, sequence, buffer) -> event.setValue(buffer.getLong(0)), bb);
				  Thread.sleep(10);
			  }));
}
```

![](https://cdn.yangbingdong.com/img/disruptor-learning/simple-test02.jpg)

### 多生产者，单消费者

```
@SuppressWarnings("unchecked")
@Test
public void multiProducerOneCustomerTest() throws InterruptedException {
	CountDownLatch countDownLatch = new CountDownLatch(30);

	int bufferSize = 1 << 6;

	Disruptor<LongEvent> disruptor = new Disruptor<>(LongEvent::new, bufferSize, Executors.defaultThreadFactory(), ProducerType.MULTI, new SleepingWaitStrategy());

	disruptor.handleEventsWith((event, sequence, endOfBatch) -> {
		log.info("handle event: {}, sequence: {}, endOfBatch: {}", event, sequence, endOfBatch);
		countDownLatch.countDown();
	});

	LongEventProducerWithTranslator longEventProducerWithTranslator = new LongEventProducerWithTranslator();

	disruptor.start();

	new Thread(() -> produce(disruptor, longEventProducerWithTranslator, 0, 10)).start();
	new Thread(() -> produce(disruptor, longEventProducerWithTranslator, 10, 20)).start();
	new Thread(() -> produce(disruptor, longEventProducerWithTranslator, 20, 30)).start();

	countDownLatch.await();
}

private void produce(Disruptor<LongEvent> disruptor, LongEventProducerWithTranslator longEventProducerWithTranslator, int i, int i2) {
	try {
		RingBuffer<LongEvent> ringBuffer = disruptor.getRingBuffer();

		ByteBuffer bb = ByteBuffer.allocate(8);
		for (long l = i; l < i2; l++) {
			bb.putLong(0, l);
			ringBuffer.publishEvent(longEventProducerWithTranslator, bb);
			TimeUnit.MILLISECONDS.sleep(20);
		}
	} catch (Exception e) {
		e.printStackTrace();
	}
}
```

### 一个及以上生产者，多个消费者

![](https://cdn.yangbingdong.com/img/disruptor-learning/dsl1.png)

先处理完c1和c2才处理c3：

```
@Test
public void multiCustomerOneProducerTest() throws InterruptedException {
	int bufferSize = 1 << 8;

	Disruptor<LongEvent> disruptor = new Disruptor<>(LongEvent::new, bufferSize, Executors.defaultThreadFactory(), ProducerType.MULTI, new YieldingWaitStrategy());

	LongEventHandler c1 = new LongEventHandler();
	LongEventHandler2 c2 = new LongEventHandler2();
	LongEventHandler3 c3 = new LongEventHandler3();

	disruptor.handleEventsWith(c1, c2).then(c3);

	LongEventProducerWithTranslator longEventProducerWithTranslator = new LongEventProducerWithTranslator();

	disruptor.start();

	new Thread(() -> produce(disruptor, longEventProducerWithTranslator, 0, 100)).start();

	TimeUnit.SECONDS.sleep(1);
}
```

![](https://cdn.yangbingdong.com/img/disruptor-learning/multi-test1.jpg)

从上图结果可以看出来c1和c2的顺序是不确定的，c3总是在最后。



![](https://cdn.yangbingdong.com/img/disruptor-learning/dsl2.png)

如图，消费者1b消费时，必须保证消费者1a已经完成对该消息的消费；消费者2b消费时，必须保证消费者2a已经完成对该消息的消费；消费者c3消费时，必须保证消费者1b和2b已经完成对该消息的消费。

```
@SuppressWarnings("unchecked")
@Test
public void multiCustomerOneProducerTest2() throws InterruptedException {
	int bufferSize = 1 << 8;

	Disruptor<LongEvent> disruptor = new Disruptor<>(LongEvent::new, bufferSize, Executors.defaultThreadFactory(), ProducerType.SINGLE, new LiteBlockingWaitStrategy());

	LongEventHandler c1a = new LongEventHandler();
	LongEventHandler2 c2a = new LongEventHandler2();
	LongEventHandler3 c1b = new LongEventHandler3();
	LongEventHandler4 c2b = new LongEventHandler4();

	disruptor.handleEventsWith(c1a, c2a);
	disruptor.after(c1a).then(c1b);
	disruptor.after(c2a).then(c2b);
	disruptor.after(c1b, c2b).then((EventHandler<LongEvent>) (event, sequence, endOfBatch) -> System.out.println("last costumer \n"));

	LongEventProducerWithTranslator longEventProducerWithTranslator = new LongEventProducerWithTranslator();

	disruptor.start();

	new Thread(() -> produce(disruptor, longEventProducerWithTranslator, 0, 30)).start();

	TimeUnit.SECONDS.sleep(1);
}
```

![](https://cdn.yangbingdong.com/img/disruptor-learning/multi-test2.jpg)

再来一个复杂点的：

```
@SuppressWarnings("unchecked")
@Test
public void multiCustomerOneProducerTest3() throws InterruptedException {
	int bufferSize = 1 << 8;

	Disruptor<LongEvent> disruptor = new Disruptor<>(LongEvent::new, bufferSize, Executors.defaultThreadFactory(), ProducerType.SINGLE, new LiteBlockingWaitStrategy());

	EventHandler a = (EventHandler<LongEvent>) (event, sequence, endOfBatch) -> System.out.println("process a... event: " + event);
	EventHandler b = (EventHandler<LongEvent>) (event, sequence, endOfBatch) -> System.out.println("process b... event: " + event);
	EventHandler c = (EventHandler<LongEvent>) (event, sequence, endOfBatch) -> System.out.println("process c... event: " + event);
	EventHandler d = (EventHandler<LongEvent>) (event, sequence, endOfBatch) -> System.out.println("process d... event: " + event);
	EventHandler e = (EventHandler<LongEvent>) (event, sequence, endOfBatch) -> System.out.println("process e... a,b,c has completed, event: " + event + "\n");
	EventHandler f = (EventHandler<LongEvent>) (event, sequence, endOfBatch) -> System.out.println("process f... d has completed, event: " + event + "\n");
	EventHandler g = (EventHandler<LongEvent>) (event, sequence, endOfBatch) -> System.out.println("process g... e,f has completed, event: " + event + "\n\n");

	disruptor.handleEventsWith(a, b, c, d);
	disruptor.after(a, b, c).then(e);
	disruptor.after(d).then(f);
	disruptor.after(e, f).then(g);

	LongEventProducerWithTranslator longEventProducerWithTranslator = new LongEventProducerWithTranslator();

	disruptor.start();

	new Thread(() -> produce(disruptor, longEventProducerWithTranslator, 0, 2)).start();

	TimeUnit.SECONDS.sleep(1);
}
```

![](https://cdn.yangbingdong.com/img/disruptor-learning/multi-test3.jpg)

## 异常处理

Disruptor默认会把异常包装成`RuntimeException`并抛出去，导致线程挂掉或阻塞，我们需要自定义异常处理器：

```
disruptor.setDefaultExceptionHandler(new ExceptionHandler<LongEvent>() {
			@Override
			public void handleEventException(Throwable ex, long sequence, LongEvent event) {
				System.out.println("捕捉异常：" + ex.getMessage());
				System.out.println("处理异常逻辑...");
			}

			@Override
			public void handleOnStartException(Throwable ex) {
				System.out.println("handleOnStartException");
			}

			@Override
			public void handleOnShutdownException(Throwable ex) {
				System.out.println("handleOnShutdownException");
			}
		});
```

# 从RingBuffer中移除对象

> 来自官方翻译：当通过Disruptor传递数据时，对象可能比预期寿命更长。 为避免发生这种情况，可能需要在处理事件后清除事件。 如果你有一个单一的事件处理程序清除在同一个处理程序中的值是足够的。 如果你有一连串的事件处理程序，那么你可能需要一个特定的处理程序放置在链的末尾来处理对象。

```
class ObjectEvent<T>
{
    T val;

    void clear()
    {
        val = null;
    }
}

public class ClearingEventHandler<T> implements EventHandler<ObjectEvent<T>>
{
    public void onEvent(ObjectEvent<T> event, long sequence, boolean endOfBatch)
    {
        // Failing to call clear here will result in the 
        // object associated with the event to live until
        // it is overwritten once the ring buffer has wrapped
        // around to the beginning.
        event.clear(); 
    }
}

public static void main(String[] args)
{
    Disruptor<ObjectEvent<String>> disruptor = new Disruptor<>(
        () -> ObjectEvent<String>(), bufferSize, executor);

    disruptor
        .handleEventsWith(new ProcessingEventHandler())
        .then(new ClearingObjectHandler());
}
```

# 消费者分片

```
public final class MyHandler implements EventHandler<ValueEvent>
{
    private final long ordinal;
    private final long numberOfConsumers;

    public MyHandler(final long ordinal, final long numberOfConsumers)
    {
        this.ordinal = ordinal;
        this.numberOfConsumers = numberOfConsumers;
    }

    public void onEvent(final ValueEvent entry, final long sequence, final boolean onEndOfBatch)
    {
        if ((sequence % numberOfConsumers) == ordinal)
        {
            // Process the event
        }
    }
}
```

使用`disruptor.handleEventsWithWorkerPool(...)`也可以实现这种类似消费者组的功能。

# 总结

> 代码：[https://github.com/masteranthoneyd/spring-boot-learning/tree/master/spring-boot-disruptor](https://github.com/masteranthoneyd/spring-boot-learning/tree/master/spring-boot-disruptor)
>
> 来自某大神的点评：
> “当对性能的追求达到这样的程度，以致对现代硬件构成的理解变得越来越重要。”这句话恰当地形容了Disruptor/LMAX在对性能方面的追求和失败。咦，失败？为什么会这么说呢？Disruptor当然是一个优秀的框架，我说的失败指的是在开发它的过程中，LMAX曽试图提高并发程序效率，优化、使用锁或借助其他模型，但是这些尝试最终失败了——然后他们构建了Disruptor。再提问：一个Java程序员在尝试提高他的程序性能的时候，需要了解很多硬件知识吗？我想很多人都会回答“不需要”，构建Disruptor的过程中，最初开发人员对这个问题的回答可能也是“不需要”，但是尝试失败后他们决定另辟蹊径。总的看下Disruptor的设计：锁到CAS、缓冲行填充、避免GC等，我感觉这些设计都在刻意“迁就”或者“依赖”硬件设计，这些设计更像是一种“(ugly)hack”（毫无疑问，Disruptor还是目前最优秀的方案之一）。

Disruptor可以说是工程级别的项目，通过各种高级的优化达到了性能的极致：

- 可选锁无关`lock-free`, 没有竞争所以非常快
- 所有访问者都记录自己的序号的实现方式，允许多个生产者与多个消费者共享相同的数据结构
- 在每个对象中都能跟踪序列号， 没有为伪共享和非预期的竞争
- 增加缓存行补齐， 提升`cache`缓存命中率
- 环形数组中的元素不会被删除