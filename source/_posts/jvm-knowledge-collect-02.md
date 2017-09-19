---
title: JVM知识汇总——类加载以及JVM优化
date: 2017-03-20 09:17:51
categories: [Programming,Java]
tags: [Java,JVM]
---
![](http://ojoba1c98.bkt.clouddn.com/img/jvm/class.png)
# 前言

> [上一篇](/2017/jvm-knowledge-collect-01/)记录了JVM内存管理相关知识，这一篇来写一下类加载相关以及一些优化

<!--more-->
# Java类加载机制总结

## 类加载器的组织结构
类加载器 `ClassLoader`是具有层次结构的，也就是父子关系。其中，**`Bootstrap`是所有类加载器的父亲**。
（1）`Bootstrapclass loader`： **启动类加载器**
当运行Java虚拟机时，这个类加载器被创建，它负责加载虚拟机的**核心类库**，如`java.lang.*`等。
（2）`Extensionclass loader`：**标准扩展类加载器**
用于加载除了基本 API之外的一些拓展类。
（3）`AppClassLoader`：加载应用程序和程序员**自定义的类**。
运行下面的程序，结果也显示出来了：
![](http://ojoba1c98.bkt.clouddn.com/img/jvm/classlodertest.png)
从运行结果可以看出加载器之间的**父子关系**，`ExtClassLoader`的父`Loader`返回了null
原因是`BootstrapLoader`（启动类加载器）是用**`C`语言实现**的，找不到一个确定的返回父`Loader`的方式。

## 类的加载机制
类被加载到虚拟机内存包括**加载**、**链接**、**初始化**几个阶段。其中**链接又细化分为验证**、**准备**、**解析**。
这里需要注意的是，解析阶段在某些情况下可以在初始化阶段之后再开始，这是为了支持Java的运行时绑定。各个阶段的作用整理如下：

### 加载阶段
**加载阶段**可以使用系统提供的**类加载器**(ClassLoader)来完成，也可以由用户**自定义的类加载器**完成，开发人员可以通过定义类加载器去**控制字节流的获取方式**。
（1）通过类的**全名**产生对应类的**二进制数据流**（注意，若未找到该类文件，只有在类**实际使用时**才**抛出**错误）。
（2）分析并将这些二进制数据流转换为**方法区的运行时数据结构**。
（3）创建代表这个类的`java.lang.Class`对象。作为方法区这些数据的访问入口。

### 链接阶段（实现 Java 的动态性的重要一步）
（1）**验证**：主要的目的是确保class文件的字节流中包含的信息符合当前虚拟机的要求，并且**不会危害虚拟机自身安全**。验证点可能包括：class文件格式规范、这个类是否继承了不允许被继承的类(被final修饰的)、如果这个类的父类是抽象类，是否实现了起父类或接口中要求实现的所有方法、不能把一个父类对象赋值给子类数据类型、方法的访问性(private、protected、public、default)是否可被当前类访问等等。
（2）**准备**：准备阶段为**类的成员变量分配内存空间**并设置类变量**初始值**的阶段，这些变量所使用的内存都在**方法区**中分配。**所有原始类型的值都为0**。如`float`为0f、 `int`为0、`boolean`为0、引用类型为`null`。
（3）**解析**：解析阶段是把虚拟机中**常量池的符号引用**替换为**直接引用**的过程。

### 初始化
类初始化时类加载的最后一步，前面除了**加载阶段用户可以通过自定义类加载器参与**以外，其余都是**虚拟机**主导和控制。到了初始化阶段，才是**真正执行类中定义Java程序代码**。初始化阶段，**根据程序中的定制**，**初始化类变量**。
**初始化过程其实是执行类构造器方法的过程**。
（**类构造器方法是由编译器自动搜集类中所有类变量的赋值动作和静态语句块中的语句合并产生的**。）
```
//静态语句块中只能访问定义在静态语句块之前的变量，定义在它之后的变量可以赋值，但不能访问  
public class Test{  
    static{  
        i=0;//給变量赋值，可以通过编译  
        System.out.print(i);//这句编译器会提示非法向前引用  
    }  
    static int i=1;  
}  
```
**初始化过程会被触发执行的条件汇总**：
（1）使用`new`关键字**实例化对象**、读取或设置一个类的**静态字段**（被final修饰、已在编译器把结果放入常量池的静态字段除外）的时候，以及调用类的**静态方法*的时候。
（2）**对类进行反射调用**的时候。
（3）当初始化一个类的时候，如果发现其**父类还没有进行过初始化**，则进行**父类的初始化**。
（4）JVM启动时，用**户指定执行的主类**（包含main方法所在类），虚拟机会先初始化这个类。

【**关于构造器方法拓展知识**】（可以不看）
（1）类构造器`<clinit>()`方法与**类的构造函数不同**，它不需要**显式**调用父类构造，虚拟机会保证在子类`<clinit>()`方法执行之前，父类的`<clinit>()`方法已经执行完毕。因此在虚拟机中的**第一个执行的`<clinit>()`方法的类肯定是`java.lang.Object`**。
（2）由于父类的`<clinit>()`方法先执行，也就意味着父类中定义的**静态语句块要优先于子类的变量赋值**操作。
（3）`<clinit>()`方法对于类或接口来说**并不是必须的**，如果一个类中**没有静态语句**，**也没有变量赋值的操作**，那么编译器可以不为这个类生成`<clinit>()`方法。
（4）**接口中不能使用静态语句块**，和类不同的是，执行接口的`<clinit>()`方法**不需要先执行父接口**的`<clinit>()`方法。只有当父接口中定义的变量**被使用**时，父接口才会被初始化。另外，接口的**实现类在初始化**时也一样不会执行接口的`<clinit>()`方法。
（5）虚拟机会保证一个类的`<clinit>()`方法**在多线程环境中被正确加锁和同步**，可能会导致阻塞。

## 类的整个加载过程触发的的三种方式
（1）由 `new` 关键字创建一个类的实例。
（2）调用 `Class.forName()` 方法，通过反射加载类。
（3）调用某个`ClassLoader`实例的`loadClass()`方法。

三者的区别汇总如下：
（1）方法1和2都是使用的**当前类加载器**（`this.getClass.getClassLoader`）。方法3由**用户指定类加载器**并且加载的类与当前类**分属不同的命名空间**。
（2）方法1是**静态加载**，2、3是**动态加载**。
（3）对于两种动态加载，区别如下。
```java
Class.forName(className);  
//实际上是调用的是：  
Class.forName(className, true, this.getClass().getClassLoader());//第二个参数设置Class被loading后是不是必须被初始化，默认初始化
```
```java
ClassLoader.loadClass(className);  
//实际上调用的是:  
ClassLoader.loadClass(name, false);//第二个参数指Class是否被链接，默认为false 
```
**通过上面的描述，如果程序依赖于`Class`是否被初始化，就必须用`Class.forName(name)`了**

# 自定义类加载器
![](http://ojoba1c98.bkt.clouddn.com/img/jvm/calssloader.png)
## 为什么需要自定义类加载器
网上的大部分自定义类加载器文章，几乎都是贴一段实现代码，然后分析一两句自定义ClassLoader的原理。但是个人觉得首先得把为什么需要自定义加载器这个问题搞清楚，因为如果不明白它的作用的情况下，还要去学习它显然是很让人困惑的。
首先介绍自定义类的**应用场景**：
（1）**加密**：Java代码可以轻易的被**反编译**，如果你需要把自己的代码进行**加密以防止反编译**，可以先将**编译后的代码**用某种**加密算法加密**，类加密后就不能再用Java的`ClassLoader`去加载类了，这时就需要**自定义`ClassLoader`**在加载类的时候**先解密类**，然后再加载。
（2）**从非标准的来源加载代码**：如果你的字节码是放在数据库、甚至是在云端，就可以自定义类加载器，从指定的来源加载类。
（3）**以上两种情况在实际中的综合运用**：比如你的应用需要**通过网络来传输 Java 类的字节码**，为了安全性，这些字节码经过了加密处理。这个时候你就需要自定义类加载器来从某个网络地址上读取加密后的字节代码，接着进行解密和验证，最后定义出在Java虚拟机中运行的类。

## 双亲委派模型
在实现自己的`ClassLoade`r之前，我们先了解一下系统是如何加载类的，那么就不得不介绍**双亲委派模型的特点和实现过程**。
双亲委派模型**特点**：
该模型要求除了顶层的`Bootstrapclassloader`启动类加载器外，其余的类加载器都应当**有自己的父类加载器**。子类加载器和父类加载器**不是**以继承（Inheritance）的关系来实现，而是**通过组合（Composition）关系**来**复用**父加载器的代码。
```java
//双亲委派模型的工作过程源码  
protected synchronized Class<?> loadClass(String name, boolean resolve)  
throws ClassNotFoundException  
{  
// First, check if the class has already been loaded  
Class c = findLoadedClass(name);  
if (c == null) {  
try {  
if (parent != null) {  
c = parent.loadClass(name, false);  
} else {  
c = findBootstrapClassOrNull(name);  
}  
} catch (ClassNotFoundException e) {  
// ClassNotFoundException thrown if class not found  
// from the non-null parent class loader  
//父类加载器无法完成类加载请求  
}  
if (c == null) {  
// If still not found, then invoke findClass in order to find the class  
//子加载器进行类加载   
c = findClass(name);  
}  
}  
if (resolve) {//判断是否需要链接过程，参数传入  
resolveClass(c);  
}  
return c;  
}  
```
双亲委派模型的工作过程如下：
（1）代码中一开始的**判空**操作是当前 `ClassLoader`从自己已经加载的类中**查询是否此类已经加载**，如果已经加载则直接返回原来已经加载的类。（每个类加载器都有自己的加载缓存，当一个类被加载了以后就会放入缓存，等下次加载的时候就可以直接返回）
（2）当前 `ClassLoader`的缓存中**没有找到被加载的类的时候**，它自己不会尝试去加载该类，而是**委托父类加载器去加载**，如代码`c` `=` `parent.loadClass(name, false)`所示（父类加载器采用**同样的策略**，递归了`loadClass`函数），首先查看自己的缓存，没有就**委托父类的父类去加载**，一直到 `BootStrap ClassLoader`。如代码所示，如果父加载器为空则默认使用启动类加载器（`BootStrap ClassLoader`）作为父加载器去加载，如代码`findBootstrapClassOrNull(name)`所示（为何父类为`BootStrap ClassLoader`会返回空，原因在***[Java类加载机制总结](#Java%E7%B1%BB%E5%8A%A0%E8%BD%BD%E6%9C%BA%E5%88%B6%E6%80%BB%E7%BB%93)***中介绍过了）。
（3）如果**`BootStrapClassLoader`加载失败**（例如在`$JAVA_HOME/jre/lib`里未查找到该`class`），会使用`ExtClassLoader`来尝试加载； 若`ExtClassLoader`也加载失败，则会使用`AppClassLoader`来加载，如果`AppClassLoader`也加载失败，则会抛出`ClassNotFoundException`。**最后再调用当前加载器的`findClass()`方法进行加载**。

双亲委派模型的**好处**：
（1）主要是为了**安全性**，**避免用户自己编写的类动态替换Java的一些核心类**，比如 `String`。
（2）同时也**避免重复加载**，因为 JVM中区分不同类，不仅仅是根据类名，相同的`class`文件被**不同的 `ClassLoader`加载就是不同的两个类**。

## 自定义类加载器
（1）从上面源码可以看出，在调用`loadClass`方法时，会先根据委派模型在父加载器中加载，如果加载失败，则会**调用自己的`findClass`方法来完成加载**。
（2）因此我们自定义的类加载器只需要**继承ClassLoader，并覆盖findClass方法**。
（3）下面是一个实际例子，在该例中我们用自定义的类加载器去加载我们事先准备好的class文件。

### 自定义一个People.java类做例子
```java
public class People {  
//该类写在记事本里，在用javac命令行编译成class文件，放在d盘根目录下  
    private String name;  
    public People() {}  
  
    public People(String name) {  
        this.name = name;  
    }  
  
    public String getName() {  
        return name;  
    }  
  
    public void setName(String name) {  
        this.name = name;  
    }  
  
    public String toString() {  
        return "I am a people, my name is " + name;  
    }  
  
}  
```

### 自定义类加载器
自定义一个类加载器，需要继承**`ClassLoader`类，并实现`findClass`方法**。其中`defineClass`方法可以把二进制流字节组成的文件转换为一个`java.lang.Class`（只要二进制字节流的内容符合Class文件规范）。
```java
public class MyClassLoader extends ClassLoader  
{  
    public MyClassLoader()  
    {  
          
    }  
      
    public MyClassLoader(ClassLoader parent)  
    {  
        super(parent);  
    }  
      
    protected Class<?> findClass(String name) throws ClassNotFoundException  
    {  
        File file = new File("D:/People.class");  
        try{  
            byte[] bytes = getClassBytes(file);  
            //defineClass方法可以把二进制流字节组成的文件转换为一个java.lang.Class  
            Class<?> c = this.defineClass(name, bytes, 0, bytes.length);  
            return c;  
        }   
        catch (Exception e)  
        {  
            e.printStackTrace();  
        }  
          
        return super.findClass(name);  
    }  
      
    private byte[] getClassBytes(File file) throws Exception  
    {  
        // 这里要读入.class的字节，因此要使用字节流  
        FileInputStream fis = new FileInputStream(file);  
        FileChannel fc = fis.getChannel();  
        ByteArrayOutputStream baos = new ByteArrayOutputStream();  
        WritableByteChannel wbc = Channels.newChannel(baos);  
        ByteBuffer by = ByteBuffer.allocate(1024);  
          
        while (true){  
            int i = fc.read(by);  
            if (i == 0 || i == -1)  
            break;  
            by.flip();  
            wbc.write(by);  
            by.clear();  
        }  
        fis.close();  
        return baos.toByteArray();  
    }  
} 
```

### 在主函数里使用
```java
MyClassLoader mcl = new MyClassLoader();   
Class<?> clazz = Class.forName("People", true, mcl);   
Object obj = clazz.newInstance();  
         
System.out.println(obj);  
System.out.println(obj.getClass().getClassLoader());//打印出我们的自定义类加载器 
```

### 运行结果
![](http://ojoba1c98.bkt.clouddn.com/img/jvm/result.png)

至此关于自定义`ClassLoader`的内容总结完毕。

# Tomcat与Eclipse性能调优
## Tomcat服务器优化
### JDK内存优化
根据服务器物理内容情况配置相关参数优化tomcat性能。当应用程序需要的内存超出堆的最大值时虚拟机就会提示内存溢出，并且导致应用服务崩溃。因此一般建议堆的最大值设置为可用内存的最大值的80%。 Tomcat默认可以使用的内存为128MB，在较大型的应用项目中，这点内存是不够的，需要调大。
Tomcat默认可以使用的内存为128MB,Windows下,在文件/bin/catalina.bat，Unix下，在文件/bin/catalina.sh的前面，增加如下设置： JAVA_OPTS=’-Xms【初始化内存大小】 -Xmx【可以使用的最大内存】 -XX:PermSize=64M -XX:MaxPermSize=128m’ 需要把几个参数值调大。例如： JAVA_OPTS=’-Xms256m -Xmx512m’ 表示初始化内存为256MB，可以使用的最大内存为512MB。
 参数详解：
```
-server  启用jdk 的 server 版；
-Xms    java虚拟机初始化时的最小内存；
-Xmx    java虚拟机可使用的最大内存；
-XX:PermSize    内存永久保留区域
-XX:MaxPermSize   内存最大永久保留区域 
-Xmn    jvm最小内存
```
32G 内存配置示例：
```
JAVA_OPTS="$JAVA_OPTS  -Xms10g -Xmx10g -XX:PermSize=1g -XX:MaxPermSize=2g -Xshare:off -Xmn1024m
```

### Tomcat线程优化
在Tomcat配置文件`server.xml`中的配置中，和连接数相关的参数有：
`maxThreads`： Tomcat使用线程来处理接收的每个请求。这个值表示Tomcat可创建的最大的线程数。默认值150。
`acceptCount`： 指定当所有可以使用的处理请求的线程数都被使用时，可以放到处理队列中的请求数，超过这个数的请求将不予处理。默认值10。
`minSpareThreads`： Tomcat初始化时创建的线程数。默认值25。
`maxSpareThreads`： 一旦创建的线程超过这个值，Tomcat就会关闭不再需要的socket线程。默认值75。
`enableLookups`： 是否反查域名，默认值为true。为了提高处理能力，应设置为false
`connnectionTimeout`： 网络连接超时，默认值60000，单位：毫秒。设置为0表示永不超时，这样设置有隐患的。通常可设置为30000毫秒。
`maxKeepAliveRequests`： 保持请求数量，默认值100。 bufferSize： 输入流缓冲大小，默认值2048 bytes。
`compression`： 压缩传输，取值on/off/force，默认值off。 其中和最大连接数相关的参数为maxThreads和`acceptCount`。如果要加大并发连接数，应同时加大这两个参数。
32G 内存配置示例：
```
<Connector port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000" maxThreads="1000" minSpareThreads="60" maxSpareThreads="600"  acceptCount="120" 
               redirectPort="8443" URIEncoding="utf-8"/>
```

## Eclipse调优
eclipse.ini配置：
```
-startup
plugins/org.eclipse.equinox.launcher_1.3.100.v20150511-1540.jar
--launcher.library
plugins/org.eclipse.equinox.launcher.win32.win32.x86_64_1.1.300.v20150602-1417
-product
org.eclipse.epp.package.jee.product
--launcher.defaultAction
openFile
--launcher.XXMaxPermSize
512M
-showsplash
org.eclipse.platform
--launcher.XXMaxPermSize
512m
--launcher.defaultAction
openFile
--launcher.appendVmargs
-vmargs
-Dosgi.requiredJavaVersion=1.7
-Xms2048m
-Xmx2048m
-Xverify:none
-XX:+PrintGCDetails                 
-XX:+PrintGCDateStamps
-Xloggc:gc.log
```

# 最后
> **参考并转载于：**
> ***[http://blog.csdn.net/seu_calvin/article/details/51404589](http://blog.csdn.net/seu_calvin/article/details/51404589)***
> ***[http://blog.csdn.net/seu_calvin/article/details/51892567](http://blog.csdn.net/seu_calvin/article/details/51892567)***
> ***[http://blog.csdn.net/seu_calvin/article/details/52301541](http://blog.csdn.net/seu_calvin/article/details/52301541)***
> ***[http://www.importnew.com/23774.html](http://www.importnew.com/23774.html)***
> ***[http://www.importnew.com/23774.html](http://www.importnew.com/23780.html)***

