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

## 什么是简单工厂模式
简单工厂模式又被称为**静态工厂方法模式**，由**一个**工厂类根据传入的参数，动态决定应该创建哪一个产品类（这些产品类继承自一个父类或接口）的实例。

将“类实例化的操作”与“使用对象的操作”分开，让使用者不用知道具体参数就可以实例化出所需要的“产品”类，从而避免了在客户端代码中显式指定，实现了**解耦**；
即使用者可直接消费产品而不需要知道其生产的细节

## 上代码

定义人类接口：
```
public interface Human {
	/**
	 * 是个人都会讲话
	 */
	void talk();
}
```

实现类（男人和女人）：
```
public class Man implements Human {
	@Override
	public void talk() {
		System.out.println("I'm man! \n");
	}
}

public class Woman implements Human {
	@Override
	public void talk() {
		System.out.println("I'm woman! \n");
	}
}
```

工厂类：
```
package com.yangbingdong.simplefactory;

import static com.yangbingdong.simplefactory.HumanFactory.HumanEnum.MAN;
import static com.yangbingdong.simplefactory.HumanFactory.HumanEnum.WOMAN;

/**
 * @author ybd
 * @date 17-10-19.
 * If you have any questions please contact yangbingdong@1994.gmail
 */
public class HumanFactory {

	private HumanFactory() {}

	/**
	 * 工厂获取实例静态方法
	 * @param humanEnum 根据传进来的枚举获取对应的实例
	 * @return 返回的实例
	 */
	public static Human getInstance(HumanEnum humanEnum) {
		if (MAN.equals(humanEnum)) {
			System.out.println("生产了男人");
			return new Man();
		}else if (WOMAN.equals(humanEnum)) {
			System.out.println("生产了女人");
			return new Woman();
		}else {
			System.out.println("什么都没有生产");
			return null;
		}
	}

	public enum HumanEnum {
		MAN,WOMAN
	}

}
```

现在来测试一下：
```
package com.yangbingdong.simplefactory;

import java.util.Optional;

import static com.yangbingdong.simplefactory.HumanFactory.HumanEnum.*;

/**
 * @author ybd
 * @date 17-10-19.
 * If you have any questions please contact yangbingdong@1994.gmail
 */
public class SimpleFactoryTest {
	public static void main(String[] args) {
		invokeTalkIfNotNull(MAN);

		invokeTalkIfNotNull(WOMAN);

		invokeTalkIfNotNull(null);
	}

	private static void invokeTalkIfNotNull(HumanFactory.HumanEnum man) {
		Optional.ofNullable(HumanFactory.getInstance(man)).ifPresent(Human::talk);
	}
}

```

运行结果：
```
生产了男人
I'm man! 

生产了女人
I'm woman! 

什么都没有生产
```

## 特点

将创建实例的工作与使用实例的工作分开，使用者不必关心类对象如何创建，只需要传入工厂需要的参数即可，但也有**弊端**：工厂类集中了所有实例（产品）的创建逻辑，一旦这个工厂不能正常工作，整个系统都会受到影响，违背“开放 - 关闭原则”，一旦添加新产品就不得不修改工厂类的逻辑，这样就会造成工厂逻辑过于复杂，对于系统维护和扩展不够友好。

## Java标准库中的简单工厂模式

```
java.util.Calendar - getInstance()
java.util.Calendar - getInstance(TimeZone zone)
java.util.Calendar - getInstance(Locale aLocale)
java.util.Calendar - getInstance(TimeZone zone, Locale aLocale)
java.text.NumberFormat - getInstance()
java.text.NumberFormat - getInstance(Locale inLocale)
```

# Factory Method

## UML

![](http://ojoba1c98.bkt.clouddn.com/img/design-pattern-creational/factory-method.png)

## 什么是工厂方法

工厂方法模式，又称工厂模式、多态工厂模式和虚拟构造器模式，通过定义工厂父类负责定义创建对象的公共接口，而子类则负责生成具体的对象。就是一个工厂生产一个专一产品。

## 代码

人类接口与实现类与上面的一样

主要是把工厂抽象成了接口，具体的人类由具体的工厂实现类创建。

工厂接口定义统一的创建人类的借口

```
public interface HumanFactory {
	/**
	 * 定义抽象工厂方法
	 * @return
	 */
	Human createHuman();
}
```

两个工厂实现类

```
public class ManFactory implements HumanFactory {
	@Override
	public Human createHuman() {
		System.out.println("生产了男人");
		return new Man();
	}
}

public class WomanFactory implements HumanFactory {
	@Override
	public Human createHuman() {
		System.out.println("生产了女人");
		return new Woman();
	}
}
```

测试类：

```
package com.yangbingdong.factorymethod;

/**
 * @author ybd
 * @date 17-10-25.
 * If you have any questions please contact yangbingdong@1994.gmail
 */
public class FactoryMethodTest {
   public static void main(String[] args) {
      HumanFactory humanFactory = new ManFactory();
      humanFactory.createHuman().talk();

      humanFactory = new WomanFactory();
      humanFactory.createHuman().talk();
   }
}
```

运行结果：

```
生产了男人
I'm man! 

生产了女人
I'm woman! 
```

## 特点

工厂方法模式把具体产品的创建推迟到工厂类的子类（具体工厂）中，此时工厂类不再负责所有产品的创建，而只是给出具体工厂必须实现的接口，这样工厂方法模式在添加新产品的时候就不修改工厂类逻辑而是添加新的工厂子类，符合**开放封闭原则**，克服了简单工厂模式中缺点。工厂模式可以说是简单工厂模式的进一步抽象和拓展，在保留了简单工厂的封装优点的同时，让扩展变得简单，让继承变得可行，增加了多态性的体现。

同时**缺点**也很明显，多一个产品就多一个工厂，开销变大了，不适用与创建多种产品。

## Java中的工厂方法

查找了一下，数据库链接驱动就是一个典型的工厂方法模式，Java定义链接数据库以及其他操作的接口，数据库厂商必须实现这些接口，比如Mysql、Oracle。

# Abstract Factory

## UML

![](http://ojoba1c98.bkt.clouddn.com/img/design-pattern-creational/abstract-factory.png)

## 什么是抽象工厂模式

抽象工厂模式为创建一组对象提供了一种解决方案。与工厂方法模式相比，抽象工厂模式中的具体工厂不只是创建一种产品，它负责创建一族产品。比如AMD工厂负责生产AMD全家桶，Intel工厂负责生产Intel全家桶。

## 代码

首先定义CPU接口以及实现类

```
public interface CPU {
}

public class AMDCPU implements CPU {
}

public class IntelCPU implements CPU {
}
```

主板接口以及实现类

```
public interface MainBoard {
}

public class AMDMainBoard implements MainBoard {
}

public class IntelMainBoard implements MainBoard {
}
```

定义抽象工厂与实现类

```
public interface AbstractFactory {
	CPU createCPU();

	MainBoard createMainBoard();
}

public class AMDFactory implements AbstractFactory {
	@Override
	public CPU createCPU() {
		System.out.println("生产了AMD的CPU");
		return new AMDCPU();
	}

	@Override
	public MainBoard createMainBoard() {
		System.out.println("生产了AMD的主板");
		return new AMDMainBoard();
	}
}

public class IntelFactory implements AbstractFactory {
	@Override
	public CPU createCPU() {
		System.out.println("生产了Intel的CPU");
		return new IntelCPU();
	}

	@Override
	public MainBoard createMainBoard() {
		System.out.println("生产了Intel的主板");
		return new IntelMainBoard();
	}
}
```

测试类

```
public class AbstractFactoryTest {
	public static void main(String[] args) {
		AbstractFactory abstractFactory = new AMDFactory();
		abstractFactory.createCPU();
		abstractFactory.createMainBoard();

		abstractFactory = new IntelFactory();
		abstractFactory.createCPU();
		abstractFactory.createMainBoard();
	}
}
```

运行结果

```
生产了AMD的CPU
生产了AMD的主板
生产了Intel的CPU
生产了Intel的主板
```

## 优缺点

**优点**：

**分离接口和实现**：客户端使用抽象工厂来创建需要的对象，而客户端根本就不知道具体的实现是谁，客户端只是面向产品的接口编程而已。也就是说，客户端从具体的产品实现中解耦。

**使切换产品族变得容易**：因为一个具体的工厂实现代表的是一个产品族，比如上面例子的从Intel系列到AMD系列只需要切换一下具体工厂。

缺点：

**不太容易扩展新的产品**：如果需要给整个产品族添加一个新的产品，那么就需要修改抽象工厂，这样就会导致修改所有的工厂实现类

## Java标准类库中的抽象工厂模式

```
package java.util;

public interface List<E> extends Collection<E> {
    
    Iterator<E> iterator();//一种产品

    Object[] toArray();

    <T> T[] toArray(T[] a);

    ListIterator<E> listIterator();//另外一种产品

    ListIterator<E> listIterator(int index);

}
```

# Builder

## UML

## 什么是建造者模式
将一个**复杂**对象的**构建**与它的表示**分离**，使得同样的构建过程可以创建不同的表示。

## 代码

## 优缺点
优点：

- 封装性很好：使用建造者模式可以有效的封装变化，在使用建造者模式的场景中，一般产品类和建造者类是比较稳定的，因此，将主要的业务逻辑封装在导演类中对整体而言可以取得比较好的稳定性。
- 扩展性很好：建造者模式很容易进行扩展。如果有新的需求，通过实现一个新的建造者类就可以完成，基本上不用修改之前已经测试通过的代码，因此也就不会对原有功能引入风险。
- 可以有效控制细节风险：由于具体的建造者是独立的，因此可以对建造者过程逐步细化，而不对其他的模块产生任何影响。

缺点：

- 建造者模式所创建的产品一般具有较多的共同点，其组成部分相似，如果产品之间的差异性很大，则不适合使用建造者模式，因此其使用范围受到一定的限制。
- 如果产品的内部变化复杂，可能会导致需要定义很多具体建造者类来实现这种变化，导致系统变得很庞大。

## Java类库中的建造者模式

```
StringBuilder strBuilder= new StringBuilder();
strBuilder.append("one");
strBuilder.append("two");
strBuilder.append("three");
String str= strBuilder.toString();
```

