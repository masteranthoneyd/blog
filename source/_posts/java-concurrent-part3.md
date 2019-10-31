---
title: Java 并发拾遗-并发工具(中)
date: 2019-9-10 15:43:54
categories: [Programming, Java, Concurrent]
tags: [Java, Concurrent]
---


![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-part3-banner2.jpg)

# Preface

> 此篇聊聊 线程安全的容器 以及 JDK 原子类的简单使用.

<!--more-->

# 线程安全的容器

## 同步容器

Java 1.5 之前提供的**同步容器**虽然也能保证线程安全, 但是性能很差. Java 中的容器主要可以分为四个大类, 分别是 `List`、`Map`、`Set` 和 `Queue`, 但并不是所有的 Java 容器都是线程安全的. 例如, 我们常用的 `ArrayList`、`HashMap` 就不是线程安全的. 

那么如何将非线程安全的容器变成线程安全的容器? 之前说过, 只要把**非线程安全的容器封装在对象内部**, 然后控制好访问路径就可以了. 

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

JDK 的 `Collections` 这个类中还提供了一套完备的包装类, 比如下面的示例代码中, 分别把 `ArrayList`、`HashSet` 和 `HashMap` 包装成了线程安全的 `List`、`Set` 和 `Map`:

```java
List list = Collections.
  synchronizedList(new ArrayList());
Set set = Collections.
  synchronizedSet(new HashSet());
Map map = Collections.
  synchronizedMap(new HashMap());
```

组合操作需要注意**竞态条件问题**, 例如上面提到的 `addIfNotExist()` 方法就包含组合操作. 组合操作往往隐藏着**竞态条件**问题, 即便每个操作都能保证原子性, 也并不能保证组合操作的原子性, 这个一定要注意. 

在容器领域一个**容易被忽视的“坑”是用迭代器遍历容器**, 例如在下面的代码中, 通过迭代器遍历容器 list, 对每个元素调用 `foo()` 方法, 这就存在并发问题, 这些组合的操作不具备原子性:

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

上面提到的这些经过包装后线程安全容器, 都是**基于 `synchronized` 这个同步关键字实现**的, 所以也被称为**同步容器**. Java 提供的同步容器还有 `Vector`、`Stack` 和 `Hashtable`, 这三个容器不是基于包装类实现的, 但同样是基于 `synchronized` 实现的, 对这三个容器的遍历, 同样要加锁保证互斥. 

## 并发容器

上面提到的同步容器都是基于 `synchronized` 来实现的, 因此性能不高, 因此 Java 在 1.5 及之后版本提供了性能更高的容器, 我们一般称为并发容器. 

![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-container01.png)

### List

List 里面只有一个实现类就是 `CopyOnWriteArrayList`. CopyOnWrite, 顾名思义就是写的时候会将共享变量新复制一份出来, 这样做的好处是读操作完全无锁. 

如果在遍历 `CopyOnWriteArrayList` 的同时, 还有一个写操作, `CopyOnWriteArrayList` 会将 array 复制一份, 然后在新复制处理的数组上执行增加元素的操作, 执行完之后再将 array 指向这个新的数组. 读写是可以并行的, 遍历操作一直都是基于原 array 执行, 而写操作则是基于新 array 进行:

![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-copyonwritelist.png)

使用 `CopyOnWriteArrayList` 需要注意的“坑”主要有两个方面. 

* 一个是应用场景, `CopyOnWriteArrayList` 仅适用于写操作非常少的场景, 而且能够容忍读写的短暂不一致. 例如上面的例子中, 写入的新元素并不能立刻被遍历到;
* 另一个需要注意的是, `CopyOnWriteArrayList` 迭代器是只读的, 不支持增删改. 因为迭代器遍历的仅仅是一个快照, 而**对快照进行增删改是没有意义的**.

### Map

Map 接口的两个实现是 `ConcurrentHashMap` 和 `ConcurrentSkipListMap`, 它们从应用的角度来看, 主要区别在于 `ConcurrentHashMap` 的 key 是**无序**的, 而 `ConcurrentSkipListMap` 的 key 是**有序**的, 就像 `HashMap` 与 `TreeMap` 一样.

使用 `ConcurrentHashMap` 和 `ConcurrentSkipListMap` 需要注意的地方是, 它们的 key 和 value 都不能为空, 否则会抛出 `NullPointerException` 这个运行时异常, 因为在多线程环境下, 调用 `get(KEY)` 拿到的 null 值无法判断是设置进去的 null 还是被别的线程删除了.

![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-map.png)

`ConcurrentSkipListMap` 里面的 `SkipList` 本身就是一种数据结构, 中文一般都翻译为“跳表”, 以空间换时间. 跳表插入、删除、查询操作平均的时间复杂度是 `O(log n)`, 理论上和并发线程数没有关系, 所以在并发度非常高的情况下, 若对 `ConcurrentHashMap` 的性能还不满意, 可以尝试一下 `ConcurrentSkipListMap`. 

### Set

Set 接口的两个实现是 `CopyOnWriteArraySet` 和 `ConcurrentSkipListSet`, 使用场景可以参考前面讲述的 `CopyOnWriteArrayList` 和 `ConcurrentSkipListMap`, 它们的原理都是一样的, 这里就不再赘述了. 

### Queue

Java 并发包里面 Queue 这类并发容器是最复杂的, 你可以从以下两个维度来分类. 一个维度是**阻塞与非阻塞**, 所谓阻塞指的是当队列已满时, 入队操作阻塞; 当队列已空时, 出队操作阻塞. 另一个维度是**单端与双端**, 单端指的是只能队尾入队, 队首出队; 而双端指的是队首队尾皆可入队出队. Java 并发包里**阻塞队列都用 Blocking 关键字标识, 单端队列使用 Queue 标识, 双端队列使用 Deque 标识**. 

这两个维度组合后, 可以将 Queue 细分为四大类, 分别是: 

第一, **单端阻塞队列**: 其实现有 `ArrayBlockingQueue`、`LinkedBlockingQueue`、`SynchronousQueue`、`LinkedTransferQueue`、`PriorityBlockingQueue` 和 `DelayQueue`. 内部一般会持有一个队列, 这个队列可以是数组(其实现是 `ArrayBlockingQueue`)也可以是链表(其实现是 `LinkedBlockingQueue`); 甚至还可以不持有队列(其实现是 `SynchronousQueue`), 此时生产者线程的入队操作必须等待消费者线程的出队操作. 而 `LinkedTransferQueue` 融合 `LinkedBlockingQueue` 和 `SynchronousQueue` 的功能, 性能比 `LinkedBlockingQueue` 更好; `PriorityBlockingQueue` 支持按照优先级出队; `DelayQueue` 支持延时出队. 

![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-queue01.png)

第二, **双端阻塞队列**: 其实现是 `LinkedBlockingDeque`. 

![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-queue02.png)

第三, **单端非阻塞队列**: 其实现是 `ConcurrentLinkedQueue`. 

第四, **双端非阻塞队列**: 其实现是 `ConcurrentLinkedDeque`. 

另外, 使用队列时, 需要格外注意队列是否支持**有界**(所谓有界指的是内部的队列是否有容量限制). 实际工作中, 一般都不建议使用无界的队列, 因为数据量大了之后很容易**导致 OOM**. 上面我们提到的这些 Queue 中, 只有 ArrayBlockingQueue 和 LinkedBlockingQueue 是支持有界的, **所以在使用其他无界队列时, 一定要充分考虑是否存在导致 OOM 的隐患. **

# 原子类: 无锁工具类的典范

对于一些需要并发累加的操作, 现在我们也许第一时间想到的是 Atomic 相关的类比如 `AtomicLong` 等, 这些类使用 CAS指令(Compare And Swap, 即"比较并交换") 实现**无锁**的**高性能**操作, 并且作为一条 CPU 指令, CAS 指令本身是能够保证**原子性**的. 

CAS 指令包含 3 个参数: 共享变量的内存地址 A、用于比较的值 B 和共享变量的新值 C; 并且只有当内存中地址 A 处的值等于 B 时, 才能将内存中地址 A 处的值更新为新值 C. 

Java SDK 并发包里提供的原子类内容很丰富, 我们可以将它们分为五个类别: **原子化的基本数据类型**、**原子化的对象引用类型**、**原子化数组**、**原子化对象属性更新器**和**原子化的累加器**. 

![](https://cdn.yangbingdong.com/img/concurrent/java-concurrent-atomic-family.png)

## 原子化的基本数据类型

相关实现有 `AtomicBoolean`、`AtomicInteger` 和 `AtomicLong`, 提供的方法主要有以下这些:

```java
getAndIncrement() //原子化i++
getAndDecrement() //原子化的i--
incrementAndGet() //原子化的++i
decrementAndGet() //原子化的--i
//当前值+=delta, 返回+=前的值
getAndAdd(delta) 
//当前值+=delta, 返回+=后的值
addAndGet(delta)
//CAS操作, 返回是否成功
compareAndSet(expect, update)
//以下四个方法
//新值可以通过传入func函数来计算
getAndUpdate(func)
updateAndGet(func)
getAndAccumulate(x,func)
accumulateAndGet(x,func)
```

## 原子化的对象引用类型

相关实现有 `AtomicReference`、`AtomicStampedReference` 和 `AtomicMarkableReference`, 利用它们可以实现**对象引用的原子化更新**. `AtomicReference` 提供的方法和原子化的基本数据类型差不多, 这里不再赘述. 不过需要注意的是, 对象引用的更新需要重点关注 **ABA 问题**, `AtomicStampedReference` 和 `AtomicMarkableReference` 这两个原子类可以解决 ABA 问题. 

解决 ABA 问题的思路其实很简单, 增加一个版本号维度就可以了, 每次执行 CAS 操作, 附加再更新一个版本号, 只要保证版本号是递增的, 那么即便 A 变成 B 之后再变回 A, 版本号也不会变回来(版本号递增的). `AtomicStampedReference` 实现的 CAS 方法就增加了版本号参数, 方法签名如下: 

```java
boolean compareAndSet(
  V expectedReference,
  V newReference,
  int expectedStamp,
  int newStamp) 
```

`AtomicMarkableReference` 的实现机制则更简单, 将版本号简化成了一个 `Boolean` 值, 方法签名如下: 

```java
boolean compareAndSet(
  V expectedReference,
  V newReference,
  boolean expectedMark,
  boolean newMark)
```

## 原子化数组

相关实现有 `AtomicIntegerArray`、`AtomicLongArray` 和 `AtomicReferenceArray`, 利用这些原子类, 我们可以原子化地更新数组里面的每一个元素. 这些类提供的方法和原子化的基本数据类型的区别仅仅是: 每个方法多了一个数组的索引参数, 所以这里也不再赘述了. 

## 原子化对象属性更新器

相关实现有 `AtomicIntegerFieldUpdater`、`AtomicLongFieldUpdater` 和 `AtomicReferenceFieldUpdater`, 利用它们可以原子化地更新对象的属性, 这三个方法都是利用反射机制实现的, 创建更新器的方法如下: 

```java
public static <U>
AtomicXXXFieldUpdater<U> 
newUpdater(Class<U> tclass, 
  String fieldName)
```

需要注意的是, **对象属性必须是 `volatile` 类型的, 只有这样才能保证可见性**; 如果对象属性不是 `volatile` 类型的, `newUpdater()` 方法会抛出 `IllegalArgumentException` 这个运行时异常. 

你会发现 `newUpdater()` 的方法参数只有类的信息, 没有对象的引用, 而更新对象的属性, 一定需要对象的引用, 那这个参数是在哪里传入的呢? 是在原子操作的方法参数中传入的. 例如 `compareAndSet()` 这个原子操作, 相比原子化的基本数据类型多了一个对象引用 obj. 原子化对象属性更新器相关的方法, 相比原子化的基本数据类型仅仅是多了对象引用参数, 所以这里也不再赘述了. 

```java
boolean compareAndSet(
  T obj, 
  int expect, 
  int update)
```

## 原子化的累加器

`DoubleAccumulator`、`DoubleAdder`、`LongAccumulator` 和 `LongAdder`, 这四个类仅仅用来执行累加操作, 相比原子化的基本数据类型, 速度更快, 但是不支持 `compareAndSet()` 方法. 如果你仅仅需要累加操作, 使用原子化的累加器性能会更好. 