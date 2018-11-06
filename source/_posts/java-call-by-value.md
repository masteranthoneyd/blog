---
title: Java基本数据类型传递与引用传递的那点事
date: 2017-04-18 15:36:30
categories: [Programming,Java]
tags: [Java,Java basics]
---
![](https://cdn.yangbingdong.com/img/java/201611161519205180.png)
# 前言
> 今天在逛博客的时候看到了有意思的东西，下面代码会输出什么？
```java
public static void change(String s) {     
    s = "123";    
}     
    
public static void main(String args[]) {     
    String s = "abc";     
    change(s);     
    System.out.println(s);  
} 
```
结果是`abc`。
为什么？经过一番查找与理解，又学习到了...
<!--more-->
# 捋一捋术语
Java的值传递和引用传递在面试中一般都会都被涉及到，今天我们就来聊聊这个问题，首先我们必须认识到这个问题一般是相对函数而言的，也就是java中的方法参数，那么我们先来回顾一下在程序设计语言中有关参数传递给方法（或函数）的两个专业术语：
* 按值调用（call by value）
* 按引用调用（call by reference）
  所谓的按值调用表示方法接收的是调用着提供的值，而按引用调用则表示方法接收的是调用者提供的变量地址(如果是C语言的话来说就是指针啦，当然java并没有指针的概念)。**这里我们需要注意的是一个方法可以修改传递引用所对应的变量值，而不能修改传递值调用所对应的变量值，这句话相当重要，这是按值调用与引用调用的根本区别**。

# 基本数据类型的传递
前面说过java中并不存在引用调用，这点是没错的，因为java程序设计语言确实是采用了按值调用，即call by value。也就是说方法得到的是所有参数值的一个拷贝，方法并不能修改传递给它的任何参数变量的内容。下面来看一个例子：
```java
public class CallByValue {  
      
    private static int x=10;  
      
    public static void updateValue(int value){  
        value = 3 * value;  
    }  
      
    public static void main(String[] args) {  
        System.out.println("调用前x的值："+x);  
        updateValue(x);  
        System.out.println("调用后x的值："+x);  
    }
```
运行程序，结果如下：
```
调用前x的值：10
调用后x的值：10
```
可以看到x的值并没有变化，接下来我们一起来看一下具体的执行过程：
![](https://cdn.yangbingdong.com/img/java-call-by-value/java-call-by-value01.png)
 分析：
1）value被初始化为x值的一个拷贝（也就是10）
2）value被乘以3后等于30，但注意此时x的值仍为10！
3）这个方法结束后，参数变量value不再使用，被回收。
结论：**当传递方法参数类型为基本数据类型（数字以及布尔值）时，一个方法是不可能修改一个基本数据类型的参数**。

# 引用数据类型的传递
当然java中除了基本数据类型还有引用数据类型，也就是对象引用，那么对于这种数据类型又是怎么样的情况呢？还是一样先来看一个例子：
声明一个User对象类型：
```java
public class User {  
    private String name;  
    private int age;  
    public User(String name, int age) {  
        this.name=name;  
        this.age=age;  
    }  
    public String getName() {  
        return name;  
    }  
    public void setName(String name) {  
        this.name = name;  
    }  
    public int getAge() {  
        return age;  
    }  
    public void setAge(int age) {  
        this.age = age;  
    }  
}
```
执行类如下：
```java
public class CallByValue {  
    private static User user=null;  
    public static void updateUser(User student){  
        student.setName("Lishen");  
        student.setAge(18);  
    }  
      
      
    public static void main(String[] args) {  
        user = new User("zhangsan",26);  
        System.out.println("调用前user的值："+user.toString());  
        updateUser(user);  
        System.out.println("调用后user的值："+user.toString());  
    }
```
运行结果如下：
```
调用前user的值：User [name=zhangsan, age=26]
调用后user的值：User [name=Lishen, age=18]	
```
很显然，User的值被改变了，也就是说方法参数类型如果是引用类型的话，引用类型对应的值将会被修改，下面我们来分析一下这个过程：
![](https://cdn.yangbingdong.com/img/java-call-by-value/java-call-by-value02.png)
 过程分析：
1）student变量被初始化为user值的拷贝，这里是一个对象的引用。
2）调用student变量的set方法作用在这个引用对象上，user和student同时引用的User对象内部值被修改。
3）方法结束后，student变量不再使用，被释放，而user还是没有变，依然指向User对象。
结论：**当传递方法参数类型为引用数据类型时，一个方法将修改一个引用数据类型的参数所指向对象的值**。

# 再来举个例子
虽然到这里两个数据类型的传递都分析完了，也明白的基本数据类型的传递和引用数据类型的传递区别，前者将不会修改原数据的值，而后者将会修改引用所指向对象的值。可通过上面的实例我们可能就会觉得java同时拥有按值调用和按引用调用啊，可惜的是这样的理解是有误导性的，虽然上面引用传递表面上体现了按引用调用现象，但是java中确实只有按值调用而没有按引用调用。到这里估计不少人都蒙逼了，下面我们通过一个反例来说明（回忆一下开头我们所说明的按值调用与按引用调用的根本区别）。
```java
public class CallByValue {  
    private static User user=null;  
    private static User stu=null;  
      
    /** 
     * 交换两个对象 
     * @param x 
     * @param y 
     */  
    public static void swap(User x,User y){  
        User temp =x;  
        x=y;  
        y=temp;  
    }  
      
      
    public static void main(String[] args) {  
        user = new User("user",26);  
        stu = new User("stu",18);  
        System.out.println("调用前user的值："+user.toString());  
        System.out.println("调用前stu的值："+stu.toString());  
        swap(user,stu);  
        System.out.println("调用后user的值："+user.toString());  
        System.out.println("调用后stu的值："+stu.toString());  
    }
```
我们通过一个swap函数来交换两个变量user和stu的值，在前面我们说过，如果是按引用调用那么一个方法可以修改传递引用所对应的变量值，也就是说如果java是按引用调用的话，那么swap方法将能够实现数据的交换，而实际运行结果是：
```
调用前user的值：User [name=user, age=26]
调用前stu的值：User [name=stu, age=18]
调用后user的值：User [name=user, age=26]
调用后stu的值：User [name=stu, age=18]
```
我们发现user和stu的值并没有发生变化，也就是方法并没有改变存储在变量user和stu中的对象引用。swap方法的参数x和y被初始化为**两个对象引用的拷贝**，这个方法交换的是这两个拷贝的值而已，最终，所做的事都是白费力气罢了。在方法结束后x，y将被丢弃，而原来的变量user和stu仍然引用这个方法调用之前所引用的对象。
![](https://cdn.yangbingdong.com/img/java-call-by-value/java-call-by-value03.png)
这个过程也充分说明了java程序设计语言对对象采用的不是引用调用，实际上是对象引用进行的是值传递，当然在这里我们可以简单理解为这就是按值调用和引用调用的区别，而且必须明白即使java函数在传递引用数据类型时，也只是拷贝了引用的值罢了，之所以能修改引用数据是因为它们同时指向了一个对象，但这仍然是按值调用而不是引用调用。
总结：
- **一个方法不能修改一个基本数据类型的参数（数值型和布尔型）**
- **一个方法可以修改一个引用所指向的对象状态，但这仍然是按值调用而非引用调用**
- **上面两种传递都进行了值拷贝的过程**

# 最后
> 参考
> ***[http://blog.csdn.net/javazejian/article/details/51192130](http://blog.csdn.net/javazejian/article/details/51192130)***
> ***[http://blog.csdn.net/seu_calvin/article/details/70089977](http://blog.csdn.net/seu_calvin/article/details/70089977)***





















