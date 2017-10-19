# Singleton Pattern
## UML
![](http://ojoba1c98.bkt.clouddn.com/img/design-pattern-creational/singleton.png)

## 什么是单例模式
这么说吧，一个城市只能有一个市长，每当需要他的时候他总会出现，并且每次都是同一个人。总不能一个城市有两个市长吧？
那么单例模式就是保证一个类只有一个实例化对象，并提供一个全局访问入口。
本质就是控制实例的数量。

## 小学生式单例模式
现在来看一个最原始的单例：
```
package com.yangbingdong.singleton;

/**
 * @author ybd
 * @date 17-10-16
 * If you have any questions please contact yangbingdong@1994.gmail
 *
 * 小学生式单例模式
 */
public class SimpleSingleton {

	private static SimpleSingleton instance;

	private SimpleSingleton() {}

	public static SimpleSingleton getInstance() {
		if (instance == null) {
			instance = new SimpleSingleton();
		}
		return instance;
	}

}
```
如果是刚入门的程序猿这可以得到101分（多一份骄傲）
但若是已出来工作的写出这样的代码。。。那是找群殴。。。

单例模式中注重的是**单**字，上面代码有可能造成多个实例，来一段多线程测试代码：
```
package com.yangbingdong.singleton;

import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.ExecutorService;

import static java.util.Collections.synchronizedSet;
import static java.util.concurrent.Executors.newCachedThreadPool;

/**
 * @author ybd
 * @date 17-10-18
 * If you have any questions please contact yangbingdong@1994.gmail
 */
public class SingletonTest {
	private static final int NUM = 1000;

	public static void main(String[] args) throws Exception {
		ExecutorService executorService = newCachedThreadPool();
		try {
			CyclicBarrier cyclicBarrier = new CyclicBarrier(NUM);
			CountDownLatch countDownLatch = new CountDownLatch(NUM);
			Set<String> set = synchronizedSet(new HashSet<String>());
			for (int i = 0; i < NUM; i++) {
				executorService.execute(() -> {
					try {
						/* 阻塞并等待所有线程加载完毕再同时run */
						cyclicBarrier.await();
						SimpleSingleton singleton = SimpleSingleton.getInstance();
						set.add(singleton.toString());
					} catch (Exception e) {
						e.printStackTrace();
					} finally {
						/* 计数器用于阻塞主线程 */
						countDownLatch.countDown();
					}
				});
			}
			/* 阻塞主线程，等待所有线程跑完再执行下面 */
			countDownLatch.await();
			System.out.println("------并发情况下我们取到的实例------");
			set.forEach(System.out::println);
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			executorService.shutdown();
		}
	}
}
```

执行结果：

```
------并发情况下我们取到的实例------
com.yangbingdong.singleton.SimpleSingleton@3bf59e6d
com.yangbingdong.singleton.SimpleSingleton@4e593af6
com.yangbingdong.singleton.SimpleSingleton@7eac491e
```

很明显的产生了**多个实例**，三个线程同时通过了`instance == null`条件。

## 饿汉式

```
package com.yangbingdong.singleton;

/**
 * @author ybd
 * @date 17-10-19
 * If you have any questions please contact yangbingdong@1994.gmail
 *
 * 饿汉式
 */
public class EagerSingleton {
	private static EagerSingleton instance = new EagerSingleton();

	private EagerSingleton() {}

	public static EagerSingleton getInstance() {
		return instance;
	}
}
```

通过**类加载**保证了线程安全，**空间换时间**。

## 懒汉式

```
package com.yangbingdong.singleton;

import java.util.concurrent.locks.ReentrantLock;

/**
 * @author ybd
 * @date 17-10-19
 * If you have any questions please contact yangbingdong@1994.gmail
 * 
 * 懒汉式
 */
public class LazySingleton {
	private static ReentrantLock reentrantLock = new ReentrantLock();
	private static LazySingleton instance = null;

	private LazySingleton() {}

	public static LazySingleton getInstance() {
		try {
			/* 可重入所保证线程安全 */
			reentrantLock.lock();
			if (instance == null) {
				instance = new LazySingleton();
			}
			return instance;
		} finally {
			reentrantLock.unlock();
		}
	}
}
```

每一次获取实例都需要同步，性能极差，不可取。

## 双重检查加锁

```
package com.yangbingdong.singleton;

import java.util.concurrent.locks.ReentrantLock;

/**
 * @author ybd
 * @date 17-10-19.
 * If you have any questions please contact yangbingdong@1994.gmail
 *
 * 双重检查加锁
 */
public class DoubleCheckSingleton {
	private static ReentrantLock reentrantLock = new ReentrantLock();
	
	/**
	 * 1.5后加上 volatile 关键字使得double check变得有意义
	 */
	private static volatile DoubleCheckSingleton instance = null;

	private DoubleCheckSingleton() {}

	public static DoubleCheckSingleton getInstance() {
		try {
			if (instance == null) {
				reentrantLock.lock();
				if (instance == null) {
					instance = new DoubleCheckSingleton();
				}
			}
			return instance;
		}finally {
			if(reentrantLock.isHeldByCurrentThread()){
				reentrantLock.unlock();
			}
		}
	}
}

```

double check模式需要在给`instance`加上`volatile`关键字，作用是当线程中的变量**发生变化**时，会**强制写回主存**，**其他线程**发现主存的变量地址发生改变，也会**强制读取主存**的变量。

如果不加`volatile`关键字，则有可能出现这样的情况：

线程A、B同时进入并通过了第一个`if (instance == null)`，然后A获取了锁，A把`instance`实例化并释放锁，B获取锁，但此时B自己的内存里的`instance`还是空（因为没有强制读取主存并不知道`instance`已经被实例化了），所以又实例化了一个对象。。。

## Lazy initialization holder class模式
```
package com.yangbingdong.singleton;

/**
 * @author ybd
 * @date 17-10-19.
 * If you have any questions please contact yangbingdong@1994.gmail
 *
 * Lazy initialization holder class模式
 */
public class InnerClassSingleton {
	private InnerClassSingleton() {}

	private static class SingletonHolder {
		private static InnerClassSingleton singleton = new InnerClassSingleton();
	}

	public static InnerClassSingleton getInstance() {
		return SingletonHolder.singleton;
	}
}
```
在JVM进行类加载的时候会保证数据是同步的，我们采用内部类实现：在内部类里面去创建对象实例。
只要应用中不使用内部类 JVM 就不会去加载这个单例类，也就不会创建单例对象，从而实现**延迟加载**和**线程安全**。

## 枚举

```
package com.yangbingdong.singleton;

import java.util.function.Supplier;

/**
 * @author ybd
 * @date 17-10-19.
 * If you have any questions please contact yangbingdong@1994.gmail
 *
 * 枚举就是一个单例
 */
public enum  SingletonEnum implements Supplier<String> {
	SINGLETON {
		@Override
		public String get() {
			return "I'm singleton";
		}
	}
}

```

枚举天生就是一个单例，并且是**线程安全**的，**自由序列化**的，这意味着反序列化之后它还是原来的那个单例。

而其他的单例模式需要定义`readResolve()`方法，反序列化的时候会调用此方法：

```
private Object readResolve() {
        return instance;
 }
```

## Java标准库中的单例模式

`java.lang.Runtime#getRuntime()`就是一个典型的代表。
```
class Runtime {
	private static Runtime currentRuntime = new Runtime();
 
	public static Runtime getRuntime() {
		return currentRuntime;
	}
 
	private Runtime() {}
 
	//... 
}
```
这个`currentRuntime`就是在初始化就已经加载了的。

# Simple Factory Pattern

## UML
![](http://ojoba1c98.bkt.clouddn.com/img/design-pattern-creational/simple-factory.png)

## Java标准库中的简单工厂模式

```
java.util.Calendar - getInstance()
java.util.Calendar - getInstance(TimeZone zone)
java.util.Calendar - getInstance(Locale aLocale)
java.util.Calendar - getInstance(TimeZone zone, Locale aLocale)
java.text.NumberFormat - getInstance()
java.text.NumberFormat - getInstance(Locale inLocale)
```

