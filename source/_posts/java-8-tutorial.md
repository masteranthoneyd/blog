---
title: java-8-tutorial
date: 2017-05-03 18:23:06
categories:
tags:
---
# Preface
> "Java is still not dead—and people are starting to figure that out."
> Java 8是自Java  5（2004年）发布以来Java语言最大的一次版本升级，Java 8带来了很多的新特性，包括Lambda 表达式、方法引用、流(Stream API)、默认方法、Optional、组合式异步编程、新的时间 API，等等各个方面。利用这些特征，我们可以写出如同清泉般的简洁代码= =,虽然现在才开始认真去阅读这些新特征，希望也不会太晚，本文主要记录博主的学习笔记吧...

<!--more-->

# Default Methods for Interfaces
Java 8 允许我们使用default关键字，为接口声明添加非抽象的方法实现。这个特性又被称为扩展方法。下面是我们的第一个例子：
```java
interface Formula {
    double calculate(int a);

    default double sqrt(int a) {
        return Math.sqrt(a);
    }
}
```
在接口Formula中，除了抽象方法caculate以外，还定义了一个默认方法sqrt。Formula的实现类只需要实现抽象方法caculate就可以了。默认方法sqrt可以直接使用。
```java
Formula formula = new Formula() {
    @Override
    public double calculate(int a) {
        return sqrt(a * 100);
    }
};

formula.calculate(100);     // 100.0
formula.sqrt(16);           // 4.0
```
那么这个新特征**有啥用**呢？
我们往往会碰到这样一个情况我们定义的接口根据不同的场景定义了几个不同的实现类，那么如果需要这几个实现类调用的方法都得到同一个结果或者只有一个实现类需要这个接口方法，那么我们需要去**重写每个实现了这个接口的类**，而这大大**增加**了我们的实现需求的**负担**。

正是为了解决Java接口中**只能定义抽象方法**的问题。Java8新增加了**默认方法**的特性。默认方法可以被**继承接口**重写成抽象方法或者重新定义成默认方法。除了默认方法，接口里还可以声明静态方法，并且可以实现。例子如下：

```java
private interface DefaulableFactory {
    // Interfaces now allow static methods
    static Defaulable create( Supplier< Defaulable > supplier ) {
        return supplier.get();
    }
}
```



# Lambda expressions

Lambda 表达式：简洁地表示可传递的匿名函数的一种方式

重点留意这四个关键词：**匿名**、**函数**、**传递**、**简洁**

Lambda的三个部分：

* 参数列表
* 箭头
* Lambda 主体

Lambda的基本语法大概就是下面这样子的了：

* `(parameters) -> expression`
* `(parameters) -> { statements; }`

来看个例子：

```java
List<String> names = Arrays.asList("peter", "anna", "mike", "xenia");
Collections.sort(names, new Comparator<String>() {
    @Override
    public int compare(String a, String b) {
        return b.compareTo(a);
    }
});
```

使用Lambda来表示：

```java
Collections.sort(names, (String a, String b) -> {
    return b.compareTo(a);
});
或者是
Collections.sort(names, (String a, String b) -> b.compareTo(a));
亦或是
Collections.sort(names, (a, b) -> b.compareTo(a));
```




# Functional Interfaces


# Method and Constructor References


# Streams

# Finally
> 参考
> ***[http://winterbe.com/posts/2014/03/16/java-8-tutorial/](http://winterbe.com/posts/2014/03/16/java-8-tutorial/)***
>
> ***[http://brianway.github.io/2017/03/29/javase-java8/#%E6%B5%81stream-api](http://brianway.github.io/2017/03/29/javase-java8/#%E6%B5%81stream-api)***
>
> ***[http://ifeve.com/java-8-features-tutorial/](http://ifeve.com/java-8-features-tutorial/)***
