---
title: JVM知识汇总
date: 2017-03-09 13:04:51
categories: [Programming,Java]
tags: [Java,JVM]
---
![](http://ojoba1c98.bkt.clouddn.com/img/comic/zuiewangguang1.jpeg)
(此图与文章无关，只是想看一下不一样的景色 =.=)
# 前言
> 想要深刻地理解Java，那么就要从深入地理解底层——JVM(Java Virtual Machine | Java虚拟机)。
> 博主经过一番查阅，找到了自认为写的好的一些文章，并记录下载，方便不定时的看。
> 希望每次看都会有新的领悟，不断提高自己。

<!--more-->

# Java虚拟机架构
Java虚拟机（Java Virtual Machine）实现了Java语言最重要的特征：即平台无关性。
**平台无关性原理**：编译后的 Java程序（`.class`文件）由**JVM执行**。JVM**屏蔽了与具体平台相关的信息**，使程序可以在多种平台上不加修改地运行。Java虚拟机在执行字节码时，把字节码解释成具体平台上的机器指令执行。因此实现**Java平台无关性**。
## JVM结构图
![](http://ojoba1c98.bkt.clouddn.com/img/jvm/jvm-frame-diagram.png)
**JVM = 类加载器 classloader+ 执行引擎 executionengine + 运行时数据区域 runtime data area**
首先Java源代码文件被Java编译器编译为字节码文件，然后JVM中的**类加载器**加载完毕之后，交由JVM**执行引擎**执行。在整个程序执行过程中，JVM中的**运行时数据区（内存）**会用来存储程序执行期间需要用到的数据和相关信息。
因此，**在Java中我们常常说到的内存管理就是针对这段空间进行管理**（如何分配和回收内存空间）。

## ClassLoader
ClassLoader把硬盘上的class文件**加载到JVM中的运行时数据区域**，但是它不负责这个类文件能否执行，而这个是执行引擎负责的。
限于篇幅，**类加载器的组织结构，加载类的机制原理**等会在***[JVM——类加载器总结](#Java%E7%B1%BB%E5%8A%A0%E8%BD%BD%E6%9C%BA%E5%88%B6%E6%80%BB%E7%BB%93)***一文中描述。
**双亲委派模型**以及**自定义类加载器**会在***[JVM——自定义类加载器](#%E8%87%AA%E5%AE%9A%E4%B9%89%E7%B1%BB%E5%8A%A0%E8%BD%BD%E5%99%A8)***一文中描述。

## 执行引擎
作用：**执行字节码，或者执行本地方法。**

## Runtime DataArea
JVM运行时数据区 (JVM RuntimeArea)其实就是指 JVM在**运行期间**，其**对JVM内存空间的划分和分配**。JVM在运行时将数据划分为了**以下几个区域来存储**。
程序员写的所有程序都被加载到运行时数据区域中。
![](http://ojoba1c98.bkt.clouddn.com/img/jvm/jvm-runtime-area.png)
（图注：**JDK1.7已经把常量池转移到堆里面了！**）
### PC寄存器（The pc Register）
（1）每一个Java线程**都有一个PC寄存器**，用以**记录当前执行到哪个指令**。
（2）用于存储每个线程下一步将执行的JVM指令，如该方法是Java方法，则记录的是**正在执行的虚拟机字节码地址**，如该方法为native的，则**计数器值为空**。
（3）此内存区域是**唯一一个在JVM中没有规定任何OutOfMemoryError情况**的区域。

### JVM栈（Java Virtual Machine Stacks）
（1）JVM栈是**线程私有的，并且生命周期与线程相同**。并且当线程运行完毕后，相应内存也就被**自动回收**。
（2）栈里面存放的元素叫**栈帧**，每个函数从调用到执行结束，其实是对应一个栈帧的**入栈和出栈**。
（栈帧好像很复杂的样子，其实它很简单！）它里面具体存放的是执行的函数的一些数据，如**局部变量、操作数**栈（执行引擎计算时需要），**方法出口**等等。
（3）这个区域可能有两种异常：如果线程请求的栈深度大于虚拟机所允许的深度，将抛出`StackOverflowError`异常（如：将一个函数反复递归自己，最终会出现这种异常）。如果JVM栈可以动态扩展（大部分JVM是可以的），当扩展时无法申请到足够内存则抛出`OutOfMemoryError`异常。

下面来实现一个栈溢出：
```java
package org.antd.test;

public class StackOverFlowMock {
	int num;
	public int getNum() {
		return num;
	}
	public void stackOver(){
		num++;
		stackOver();
	}
	public static void main(String[] args) {
		StackOverFlowMock stackOverFlowTest = new StackOverFlowMock();
		try {
			stackOverFlowTest.stackOver();
		} catch (Throwable t) {
			System.out.println("迭代深度："+stackOverFlowTest.getNum());
			t.printStackTrace();
		}
	}

}

```
输出为：
```java
迭代深度：17781
java.lang.StackOverflowError
	at org.antd.test.StackOverFlowMock.stackOver(StackOverFlowMock.java:10)
	at org.antd.test.StackOverFlowMock.stackOver(StackOverFlowMock.java:10)
	at org.antd.test.StackOverFlowMock.stackOver(StackOverFlowMock.java:10)
	at org.antd.test.StackOverFlowMock.stackOver(StackOverFlowMock.java:10)
	at org.antd.test.StackOverFlowMock.stackOver(StackOverFlowMock.java:10)
	at org.antd.test.StackOverFlowMock.stackOver(StackOverFlowMock.java:10)

```

### 本地方法栈（Native Method Stacks）

（1）本地方法栈与虚拟机栈所发挥的作用很相似，他们的区别在于**虚拟机栈为执行Java代码方法服务，而本地方法栈是为Native方法服务**。
（2）和JVM栈一样，这个区域也会抛出`StackOverflowError`和`OutOfMemoryError`异常。

### 方法区（Method Area）
（1）在方法区中，存储了每个**类的信息**、**静态变量**等。如，当程序中通过`getName`、`isInterface`等方法来获取信息时，这些数据来源于**方法区**。
（2）方法区域是**全局共享**的，比如**每个线程都可以访问同一个类的静态变量**。
（3）由于使用**反射机制**的原因，虚拟机**很难推测哪个类信息不再使用**，因此这块区域的**回收很难**！另外，对这块区域主要是针对**常量池**回收，**值得注意的是JDK1.7已经把常量池转移到堆里面了**。
（4）同样，当方法区**无法满足内存分配需求**时，会抛出`OutOfMemoryError`。下面演示一下造成方法区内的OOM场景。
执行之前，可以把虚拟机的参数`-XXpermSize`和`-XX：MaxPermSize`限制方法区大小。
那么实现一下OOM：
```java
public class HeapOomMock {
	public static void main(String[] args) {
		List<byte[]> list = new ArrayList<byte[]>();
		int i = 0;
		boolean flag = true;
		while (flag) {
			try {
				i++;
				list.add(new byte[1024 * 1024]);// 每次增加一个1M大小的数组对象
			} catch (Throwable e) {
				flag = false;
				System.out.println("count=" + i);// 记录运行的次数
				e.printStackTrace();
			}
		}
	}
}

```
控制台输出：
```
count=3422
java.lang.OutOfMemoryError: Java heap space
	at org.antd.test.HeapOomMock.main(HeapOomMock.java:14)
```

### 运行时常量池（Runtime Constant Pool）
（1）存放类中固定的常量信息、方法引用信息等，其空间从方法区域（JDK1.7后为堆空间）中分配。
（2）Class文件中除了有类的版本、字段、方法、接口等描述等信息外，还有就是**常量表**(constant_pool table)，用于存放**编译期已可知的常量**，这部分内容将在**类加载后进入方法区（永久代）存放**。但是Java语言并不要求常量一定只有编译期预置入Class的常量表的内容才能进入方法区常量池，运行期间也可将新内容放入常量池（最典型的`String.intern()`方法）。
（3）当常量池无法在申请到内存时会抛出`OutOfMemoryError`异常。
再来一段代码展示以下：
```
//不断将字符串添加到常量池，最终导致内存不足抛出方法区的OOM 
List<String> list =new ArrayList<String>(); 
int i =0; 
while(true){ 
    list.add(String.valueOf(i).intern()); 
} 
```
String的intern函数的作用就不多赘述了，在这篇博文***[了解String类的intern()方法](#%E9%80%9A%E8%BF%87String%E7%B1%BB%E7%9A%84intern-%E4%BA%86%E8%A7%A3%E5%86%85%E5%AD%98%E5%BB%BA%E6%A8%A1%E4%B8%8E%E5%B8%B8%E9%87%8F%E6%B1%A0)***有所介绍。关于JDK1.6和JDK1.7之后常量池位置的变化对该函数的影响，也在链接文中阐述了。

### Java堆
（1）Java堆是JVM所管理的**最大的一块内存**。它是被**所有线程共享的一块内存区域，在虚拟机启动时创建**。
（2）几乎所有的**实例对象都是在这块区域中存放**。（JIT编译器貌似不是这样的）。
（3）Java堆是**垃圾收集管理**的主要战场。所有Java堆可以细分为：**新生代**和**老年代**。再细致分就是把新生代分为：**Eden空间**、**FromSurvivor空间**、**To Survivor空间**。JVM具体的垃圾回收机制总结请查看***[JVM——内存管理和垃圾回收](#%E5%86%85%E5%AD%98%E7%AE%A1%E7%90%86%E5%92%8C%E5%9E%83%E5%9C%BE%E5%9B%9E%E6%94%B6)***。
（4）根据**Java虚拟机规范**的规定，Java堆可以处于物理上**不连续的内存空间**中，只要**逻辑上是连续**的即可，就像我们的磁盘空间一样。如果在**堆中没有内存完成实例分配**，并且**堆也无法再扩展时**，将会抛出`OutOfMemoryError`异常。


## 堆和栈的区别
这是一个非常常见的面试题，主要从以下几个方面来回答。
### 各司其职
最主要的区别就是**栈内存用来存储局部变量和方法调用**。
而堆内存用来存储**Java中的对象**。无论是成员变量、局部变量还是类变量，它们指向的对象都存储在堆内存中。
### 空间大小
**栈的内存要远远小于堆内存**，如果你使用**递归**的话，那么你的栈很快就会充满并产生``StackOverFlowError``。
关于如何设置堆栈内存的大小，可以查看***[JVM——内存管理和垃圾回收](#%E5%86%85%E5%AD%98%E7%AE%A1%E7%90%86%E5%92%8C%E5%9E%83%E5%9C%BE%E5%9B%9E%E6%94%B6)***中的相关介绍。
### 独有还是共享
栈内存归属于**线程的私有内存**，每个线程都会有一个栈内存，其存储的变量只能在其所属线程中可见。
而堆内存中的对象**对所有线程可见**，可以被所有线程访问。
### 异常错误
如果线程请求的**栈深度**大于虚拟机所允许的深度，将抛出`StackOverflowError`异常。
如果JVM栈可以动态扩展（大部分JVM是可以的），当扩展时**无法申请到足够内存**则抛出`OutOfMemoryError`异常。
而堆内存没有可用的空间存储生成的对象，JVM会抛出`java.lang.OutOfMemoryError`。

以上便是关于JVM架构的相关知识。

# 通过String类的intern()了解内存建模与常量池
## 引言
什么都先不说，先看下面这个引入的例子：
```java
String str1 = new String("SEU")+ new String("Calvin"); 
System.out.println(str1.intern() == str1);
System.out.println(str1 == "SEUCalvin"); 
```
JDK版本1.8，输出结果为：
```
true
true
```
再将上面的例子加上一行代码：
```java
String str2 = "SEUCalvin";//新加的一行代码，其余不变 
String str1 = new String("SEU")+ new String("Calvin"); 
System.out.println(str1.intern() == str1);
System.out.println(str1 == "SEUCalvin");
```
再运行，结果为：
```
false 
false 
```
是不是感觉莫名其妙，新定义的`str2`好像和`str1`没有半毛钱的关系，怎么会影响到有关`str1`的输出结果呢？其实这都是`intern()`方法搞的鬼！看完这篇文章，你就会明白。
在JVM架构一文中也有介绍，在JVM**运行时数据区中的方法区有一个常量池**，但是发现在**JDK1.6以后常量池被放置在了堆空间**，因此常量池位置的不同影响到了**String的intern()方法**的表现。深入了解后发现还是值得写下来记录一下的。为了确保文章的实时更新，实时修改可能出错的地方，请确保这篇是原文，而不是无脑转载来的“原创文”，原文链接为：***[http://blog.csdn.net/seu_calvin/article/details/52291082](http://blog.csdn.net/seu_calvin/article/details/52291082)***。

## 为什么要介绍intern()方法
`intern()`方法设计的初衷，就是**重用String对象**，以**节省内存消耗**。这么说可能有点抽象，那么就用例子来证明。
```java
    static final int MAX = 100000; 
    static final String[] arr = new String[MAX]; 
      
    public static void main(String[] args) throws Exception { 
        //为长度为10的Integer数组随机赋值  
        Integer[] sample = new Integer[10];  
        Random random = new Random(1000);  
        for (int i = 0; i < sample.length; i++) {  
            sample[i] = random.nextInt();  
        }  
        //记录程序开始时间  
        long t = System.currentTimeMillis();  
        //使用/不使用intern方法为10万个String赋值，值来自于Integer数组的10个数  
            for (int i = 0; i < MAX; i++) {  
                arr[i] = new String(String.valueOf(sample[i % sample.length]));  
                //arr[i] = new String(String.valueOf(sample[i % sample.length])).intern();  
            }  
            System.out.println((System.currentTimeMillis() - t) + "ms");  
            System.gc();  
    } 
```
这个例子也比较简单，**就是为了证明使用`intern()`比不使用`intern()`消耗的内存更少**。
先定义一个长度为10的Integer数组，并随机为其赋值，在通过for循环为长度为10万的String对象依次赋值，这些值都来自于Integer数组。两种情况分别运行，可通过`Window`>`Preferences`>`Java`>`InstalledJREs`设置JVM启动参数为`-agentlib:hprof=heap=dump,format=b`，将程序运行完后的hprof置于工程目录下。再通过**MAT插件**查看该`hprof`文件。
两次实验结果如下：
![](http://ojoba1c98.bkt.clouddn.com/img/jvm/hprof1.png)
![](http://ojoba1c98.bkt.clouddn.com/img/jvm/hrpof2.png)
从运行结果来看，不使用`intern()`的情况下，程序生成了101762个String对象，而使用了`intern()`方法时，程序仅生成了1772个String对象。自然也证明了**`intern()`节省内存的结论**。
细心的同学会发现使用了`intern()`方法后**程序运行时间有所增加**。这是因为程序中每次都是用了`new String`后又进行**`intern()`操作的耗时时间**，但是不使用`intern()`占用内存空间导致GC的时间是要远远大于这点时间的。 

## 深入认识intern()方法
**JDK1.7后**，**常量池被放入到堆空间中**，这导致`intern()`函数的功能不同，具体怎么个不同法，且看看下面代码，这个例子是网上流传较广的一个例子，分析图也是直接粘贴过来的，这里自己的理解去解释这个例子：
```java
String s = new String("1"); 
s.intern();
String s2 = "1"; 
System.out.println(s == s2); 
  
String s3 = new String("1") + new String("1"); 
s3.intern(); 
String s4 = "11"; 
System.out.println(s3 == s4); 
```
输出结果为：
```
JDK1.6以及以下：false false 
JDK1.7以及以上：false true
```
再分别调整上面代码2.3行、7.8行的顺序：
```java
String s = new String("1"); 
String s2 = "1"; 
s.intern(); 
System.out.println(s == s2); 
  
String s3 = new String("1") + new String("1"); 
String s4 = "11"; 
s3.intern(); 
System.out.println(s3 == s4); 
```
输出结果为：
```
JDK1.6以及以下：false false 
JDK1.7以及以上：false false 
```
下面依据上面代码对`intern()`方法进行分析
### JDK1.6
![](http://ojoba1c98.bkt.clouddn.com/img/jvm/jdk6-intern.png)
在JDK1.6中所有的输出结果都是 false，因为JDK1.6以及以前版本中，常量池是放在 Perm 区（属于方法区）中的，熟悉JVM的话应该知道这是和堆区完全分开的。
使用**引号声明的字符串都是会直接在字符串常量池**中生成的，而 **new 出来的 String 对象是放在堆空间中的**。所以两者的内存地址肯定是不相同的，即使调用了intern()方法也是不影响的。如果不清楚String类的“==”和equals()的区别可以查看这篇博文***[Java面试——从Java堆、栈角度比较equals和==的区别](http://blog.csdn.net/seu_calvin/article/details/52089040)***。
`intern()`方法在JDK1.6中的**作用**是：比如`String s = new String("SEU_Calvin")`，再调用`s.intern()`，此时返回值还是字符串`"SEU_Calvin"`，表面上看起来好像这个方法没什么用处。但实际上，在JDK1.6中它做了个小动作：检查字符串池里**是否存在"SEU_Calvin"这么一个字符串**，如果存在，就返回池里的字符串；如果不存在，该方法会把`"SEU_Calvin"`添加到字符串池中，然后再返回它的引用。然而在JDK1.7中却不是这样的，后面会讨论。

## JDK1.7
针对JDK1.7以及以上的版本，我们将上面两段代码分开讨论。先看第一段代码的情况：
![](http://ojoba1c98.bkt.clouddn.com/img/jvm/jdk7-intern1.png)
```java
String s = new String("1"); 
s.intern(); 
String s2 = "1"; 
System.out.println(s == s2); 
  
String s3 = new String("1") + new String("1"); 
s3.intern(); 
String s4 = "11"; 
System.out.println(s3 == s4); 
```
`String s = newString("1")`，生成了**常量池中的“1” 和堆空间中的字符串对象**。
`s.intern()`，这一行的作用是s对象去常量池中寻找后发现"1"**已经存在于常量池中了**。
`String s2 = "1"`，这行代码是生成一个s2的引用**指向常量池中的“1”对象**。
结果就是 s 和 s2 的**引用地址**明显不同。因此返回了`false`。

`String s3 = new String("1") + newString("1")`，这行代码在**字符串常量池中生成“1”** ，**并在堆空间中生成s3引用指向的对象（内容为"11"）**。注意此时常量池中是没有 “11”对象的。
`s3.intern()`，这一行代码，是将 s3中的**“11”字符串放入 String 常量池**中，此时常量池中不存在“11”字符串，JDK1.6的做法是直接在常量池中生成一个 "11" 的对象。
**但是在JDK1.7中，常量池中不需要再存储一份对象了，可以直接存储堆中的引用**。这份引用直接**指向 s3 引用的对象，也就是说`s3.intern() ==s3`会返回`true`**。
`String s4 = "11"`， 这一行代码会**直接去常量池中创建**，但是发现已经有这个对象了，此时也就是指向 **s3 引用对象的一个引用**。因此`s3 == s4`返回了`true`。

下面继续分析第二段代码：
![](http://ojoba1c98.bkt.clouddn.com/img/jvm/jdk7-intern2.png)
再把第二段代码贴一下便于查看：
```java
String s = new String("1"); 
String s2 = "1"; 
s.intern(); 
System.out.println(s == s2); 

String s3 = new String("1") + new String("1"); 
String s4 = "11"; 
s3.intern(); 
System.out.println(s3 == s4); 
```
`String s = newString("1")`，生成了**常量池中的“1” 和堆空间中的字符串对象**。
`String s2 = "1"`，这行代码是生成一个s2的引用**指向常量池中的“1”对象，但是发现已经存在了，那么就直接指向了它**。
`s.intern()`，这一行在这里就没什么实际作用了。因为"1"已经存在了。
结果就是 s 和 s2 的引用地址明显不同。因此返回了`false`。

`String s3 = new String("1") + newString("1")`，这行代码在**字符串常量池中生成“1” ，并在堆空间中生成s3引用指向的对象（内容为"11"）**。注意此时常量池中是没有 “11”对象的。
`String s4 = "11"`， 这一行代码会**直接去生成常量池中的"11"**。
`s3.intern()`，这一行在这里就没什么实际作用了。因为"11"已经存在了。
结果就是 s3 和 s4 的引用地址明显不同。因此返回了`false`。
为了确保文章的实时更新，实时修改可能出错的地方，请确保这篇是原文，而不是无脑转载来的“原创文”，原文链接为：***[http://blog.csdn.net/seu_calvin/article/details/52291082](http://blog.csdn.net/seu_calvin/article/details/52291082)***。

## 总结
终于要做Ending了。现在再来看一下开篇给的引入例子，是不是就很清晰了呢。
```java
String str1 = new String("SEU") + new String("Calvin"); 
System.out.println(str1.intern() == str1); 
System.out.println(str1 == "SEUCalvin");
```
`str1.intern()==str1`就是上面例子中的情况，`str1.intern()`发现常量池中不存在`“SEUCalvin”`，因此指向了str1。`"SEUCalvin"`在常量池中创建时，也就直接指向了str1了。两个都返回`true`就理所当然啦。
那么第二段代码呢：
```java
String str2 = "SEUCalvin";//新加的一行代码，其余不变 
String str1 = new String("SEU")+ new String("Calvin"); 
System.out.println(str1.intern() == str1); 
System.out.println(str1 == "SEUCalvin"); 
```
也很简单啦，str2先在常量池中创建了`“SEUCalvin”`，那么`str1.intern()`当然就直接指向了str2，你可以去验证它们两个是返回的true。后面的`"SEUCalvin"`也一样指向str2。所以谁都不搭理在堆空间中的str1了，所以都返回了`false`。
好了，本篇对intern的作用以及在JDK1.6和1.7中的实现原理的介绍就到此为止了。希望能给你带来帮助。
# 内存管理和垃圾回收
## 何为GC
Java与C语言相比的一个优势是，可以通过自己的JVM**自动分配和回收内存空间**。
垃圾回收机制是由垃圾收集器Garbage Collection来实现的，GC是后台一个**低优先级的守护进程**。在内存中低到一定限度时才会自动运行，因此垃圾**回收的时间是不确定的**。

**为何要这样设计**：因为GC也要消耗CPU等资源，如果GC执行过于频繁会对Java的程序的执行产生较大的影响，因此实行**不定期的GC**。

**与GC有关的是**：JVM运行时数据区中的堆（对象实例会存储在这里）和 gabagecollector方法。
垃圾回收GC**只能回收通过new关键字申请的内存**（在堆上），但是堆上的内存并不完全是通过new申请分配的。还有一些本地方法，这些内存如果不手动释放，就会导致内存泄露，所以需要在finalize中用本地方法(nativemethod)如**free操作等，再使用gc**方法。
```java
System.gc();
```

## 何为垃圾
Java中那些**不可达**的对象就会变成垃圾。对象之间的引用可以抽象成树形结构，通过树根（GC Roots）作为起点，从这些树根往下搜索，搜索走过的链称为引用链。
**当一个对象到GC Roots没有任何引用链相连时，则证明这个对象为可回收的对象**。
**可以作为GC Roots的主要有以下几种**：
（1）**栈帧中的本地变量表**所引用的对象。
（2）方法区中**类静态属性和常量**引用的对象。 
（3）本地方法栈中JNI（**Native方法**）引用的对象。
```java
//垃圾产生的情况举例： 
//1.改变对象的引用，如置为null或者指向其他对象 
Object obj1 = new Object(); 
Object obj2 = new Object(); 
obj1 = obj2; //obj1成为垃圾 
obj1 = obj2 = null ; //obj2成为垃圾
```
```java
//2.引用类型 
//第2句在内存不足的情况下会将String对象判定为可回收对象，第3句无论什么情况下String对象都会被判定为可回收对象 
String str = new String("hello"); 
SoftReference<String> sr = new SoftReference<String>(new String("java")); 
WeakReference<String> wr = new WeakReference<String>(new String("world"));
```
```java
//3.循环每执行完一次，生成的Object对象都会成为可回收的对象 
 for(int i=0;i<10;i++) { 
        Object obj = new Object();  
        System.out.println(obj.getClass());  
    } 
```
```java
//4.类嵌套 
class A{ 
   A a; 
} 
A x = new A();//分配了一个空间 
x.a = new A();//又分配了一个空间 
x = null;//产生两个垃圾
```
```java
    //5.线程中的垃圾 
    calss A implements Runnable{ 
        void run(){  
        //....  
    } 
    }
      
    //main 
    A x = new A(); 
    x.start(); 
    x=null; //线程执行完成后x对象才被认定为垃圾 
```

##  四种引用类型
### 强引用
```java
Object obj = new Object();
```
这里的obj引用便是一个强引用，强引用不会被GC回收。即使抛出`OutOfMemoryError`错误，使程序异常终止。

### 软引用
如果内存空间足够，垃圾回收器就不会回收它，如果内存空间不足了，就会回收这些对象的内存。软引用可用来实现内存敏感的高速缓存。
软引用可以和一个引用队列（ReferenceQueue）联合使用，如果软引用所引用的对象被垃圾回收，Java虚拟机就会把这个软引用加入到与之关联的引用队列中。
 
### 弱引用
弱引用与软引用的区别在于：垃圾回收器一旦发现了弱引用的对象，不管当前内存空间足够与否，都会回收它的内存。不过由于垃圾回收器是一个优先级很低的线程，因此不一定会很快发现那些弱引用的对象。
弱引用可以和一个引用队列（ReferenceQueue）联合使用，如果弱引用所引用的对象被垃圾回收，Java虚拟机就会把这个弱引用加入到与之关联的引用队列中。

### 虚引用
虚引用与软引用和弱引用的一个区别在于：虚引用必须和引用队列（ReferenceQueue）联合使用。当垃圾回收器发现一个对象有虚引用时，就会把这个虚引用对象加入到与之关联的引用队列中。此时该对象并没有被GC回收。而是要等到引用队列被真正的处理后才会被回收。
程序可以通过判断引用队列中是否已经加入了虚引用，来了解被引用的对象是否将要被垃圾回收。
（由于`Object.finalize()`方法的不安全性、低效性，常常使用虚引用完成对象回收前的资源释放工作。）
这里特别需要注意：当JVM将虚引用插入到引用队列的时候，虚引用执行的对象内存还是存在的。但是PhantomReference并没有暴露API返回对象。所以如果我想做清理工作，需要继承PhantomReference类，以便访问它指向的对象。如NIO直接内存的自动回收，就使用到了sun.misc.Cleaner。
# Java类加载机制总结
# 自定义类加载器















