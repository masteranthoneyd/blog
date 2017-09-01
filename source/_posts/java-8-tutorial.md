---
title: Java8 Noob Tutorial
date: 2017-05-03 18:23:06
categories: [Programming, Java]
tags: [Java]
---
![](http://ojoba1c98.bkt.clouddn.com/img/java/java8.jpg)
# Preface
> "Java is still not dead—and people are starting to figure that out."
> Java 8是自Java  5（2004年）发布以来Java语言最大的一次版本升级，Java 8带来了很多的新特性，包括Lambda 表达式、方法引用、流(Stream API)、默认方法、Optional、组合式异步编程、新的时间 API，等等各个方面。利用这些特征，我们可以写出如同清泉般的简洁代码= =...

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
在接口Formula中，除了抽象方法caculate以外，还定义了一个默认方法sqrt.Formula的实现类只需要实现抽象方法caculate就可以了。默认方法sqrt可以直接使用。
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

## Conflict

因为一个类可以**实现多个接口**，所以当一个类实现了多个接口，而这些接口中**存在两个或两个以上方法签名相同的默认方法时**就会产生冲突，java8定义如下三条原则来解决冲突：

1. **类或父类中显式声明的方法，其优先级高于所有的默认方法**；
2. **如果1规则失效，则选择与当前类距离最近的具有具体实现的默认方法**；
3. **如果2规则也失效，则需要显式指定接口**。

# Lambda Expressions
先来看一段代码：

```java
public interface ActionListener {
  void actionPerformed(ActionEvent e);
}

button.addActionListener(new ActionListener) {
  public void actionPerformed(ActionEvent e) {
    ui.dazzle(e.getModifiers());
  }
}
```

匿名类型最大的问题就在于其冗余的语法。有人戏称匿名类型导致了“高度问题”（**height problem**）：比如前面ActionListener的例子里的五行代码中仅有一行在做实际工作。
Lambda表达式（又被成为“闭包”或“匿名方法”）是简洁地表示可传递的匿名函数的一种方式，它提供了轻量级的语法，从而解决了匿名内部类带来的“高度问题”。

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
List<String> names = Arrays.asList("D", "B", "C", "A");
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
在IDEA里面，对于可以写成Lambda表达式的，按下Alt+Enter 它会智能地提示转换

## Lexiacal Scope
### 访问局部变量
1. 可以直接在Lambda表达式中访问外层的局部变量，但是和匿名对象不同的是，Lambda表达式的局部变量可以**不用声明为`final`**，不过局部变量必须不可被后面的代码修改（**即隐性的具有final的语义**）。
  eg：下面代码无法编译
```java
int num = 1; 
Converter<Integer, String> s =  
	(param) -> String.valueOf(param + num);  
num = 5; 
```
在Lambda表达式中试图修改局部变量是不允许的！
2. 在 Lambda 表达式当中被引用的变量的值**不可以被更改**。
3. 在 Lambda 表达式当中**不允许**声明一个与局部变量同名的参数或者局部变量。
4. ​
### 访问对象字段与静态变量
和局部变量不同的是，Lambda内部对于实例的字段（即：成员变量）以及静态变量是**即可读又可写**。

### 不能访问接口的默认方法
Lambda表达式中是**无法访问到默认方法**的。

### Lambda表达式中的this
Lambda 表达式中使用 `this` 会引用创建该 Lambda 表达式的方法的 `this` 参数。
eg：
```java
public class Test2 {  
    public static void main(String[] args) {  
        Test2 test = new Test2();  
        test.method();  
    }  
    @Override  
    public String toString() {  
        return "Lambda";  
    }  
    public void method() {  
        Runnable runnable = () -> {  
            System.out.println(this.toString());  
        };  
        new Thread(runnable).start();  
    }  
}  
```
显示结果：Lambda

**补充**：Lambda表达式对**值**封闭，对**变量**开放的原文是：lambda expressions close over **values**, not **variables**，在这里增加一个例子以说明这个特性：

```java
int sum = 0;
list.forEach(e -> { sum += e.size(); }); // Illegal, close over values

List<Integer> aList = new List<>();
list.forEach(e -> { aList.add(e); }); // Legal, open over variables
```



# Functional Interfaces

任意只包含一个抽象方法的接口，我们都可以用来做成Lambda表达式。为了让你定义的接口满足要求，你应当在接口前加上`@FunctionalInterface` 标注。编译器会注意到这个标注，如果你的接口中定义了第二个抽象方法的话，编译器会抛出异常。
eg:
```java
@FunctionalInterface
interface Converter<F, T> {
    T convert(F from);
}
 
Converter<String, Integer> converter = (from) -> Integer.valueOf(from);
Integer converted = converter.convert("123");
System.out.println(converted);    // 123
```
**注意**，如果你不写@FunctionalInterface 标注，程序也是正确的。
下面是Java SE 7中已经存在的函数式接口：
· [java.lang.Runnable](http://download.oracle.com/javase/7/docs/api/java/lang/Runnable.html)
· [java.util.concurrent.Callable](http://download.oracle.com/javase/7/docs/api/java/util/concurrent/Callable.html)
· [java.security.PrivilegedAction](http://download.oracle.com/javase/7/docs/api/java/security/PrivilegedAction.html)
· [java.util.Comparator](http://download.oracle.com/javase/7/docs/api/java/util/Comparator.html)
· [java.io.FileFilter](http://download.oracle.com/javase/7/docs/api/java/io/FileFilter.html)
· [java.beans.PropertyChangeListener](http://www.fxfrog.com/docs_www/api/java/beans/PropertyChangeListener.html)

除此之外，Java SE 8中增加了一个新的包：`java.util.function`，它里面包含了常用的函数式接口，例如：
· `Predicate<T>`——接收`T`对象并返回`boolean`
· `Consumer<T>`——接收`T`对象，不返回值
· `Function<T, R>`——接收`T`对象，返回`R`对象
· `Supplier<T>`——提供`T`对象（例如工厂），不接收值
· `UnaryOperator<T>`——接收`T`对象，返回`T`对象
· `BinaryOperator<T>`——接收两个`T`对象，返回`T`对象

除了上面的这些基本的函数式接口，我们还提供了一些针对原始类型（Primitive type）的特化（Specialization）函数式接口，例如`IntSupplier`和`LongBinaryOperator`。（我们只为`int`、`long`和`double`提供了特化函数式接口，如果需要使用其它原始类型则需要进行类型转换）同样的我们也提供了一些针对多个参数的函数式接口，例如`BiFunction<T, U, R>`，它接收`T`对象和`U`对象，返回`R`对象。

# Method and Constructor References

Lambda表达式允许我们定义一个匿名方法，并允许我们以函数式接口的方式使用它。我们也希望能够在**已有的**方法上实现同样的特性。
方法引用和Lambda表达式拥有相同的特性（例如，它们都需要一个目标类型，并需要被转化为函数式接口的实例），不过我们并不需要为方法引用提供方法体，我们可以直接通过方法名称引用已有方法。

方法引用就是替代那些转发参数的 Lambda 表达式的语法糖。
方法引用有很多种，它们的语法如下：
· 静态方法引用：`ClassName::methodName`
· 实际上的实例方法引用：`instanceReference::methodName`
· 超类上的实例方法引用：`super::methodName`
· 类型上的实例方法引用：`ClassName::methodName`
· 构造方法引用：`Class::new`
· 数组构造方法引用：`TypeName[]::new`

对于静态方法引用，我们需要在类名和方法名之间加入::分隔符，例如`Integer::sum`。
结合Lambda可以使我们的代码更加简洁：
```java
List<String> strings = Arrays.asList("a", "b");
strings.stream().map(String::toUpperCase).forEach(System.out::println);

List<Character> chars = Arrays.asList('a', 'b');	System.out.println(chars.stream().map(String::valueOf).collect(Collectors.joining(",")));
```

# Optional

`NullPointException`可以说是所有Java程序员都遇到过的一个异常，虽然Java从设计之初就力图让程序员脱离指针的苦海，但是指针确实是实际存在的，而java设计者也只能是让指针在Java语言中变得更加简单、易用，而不能完全的将其剔除，所以才有了我们日常所见到的关键字`null`。

空指针异常是一个运行时异常，对于这一类异常，如果没有明确的处理策略，那么最佳实践在于让程序早点挂掉，但是很多场景下，**不是开发人员没有具体的处理策略**，**而是根本没有意识到空指针异常的存在**。当异常真的发生的时候，处理策略也很简单，在存在异常的地方添加一个`if`语句判定即可，但是这样的应对策略会让我们的程序出现越来越多的`null`判定，我们知道一个良好的程序设计，应该让代码中尽量少出现`null`关键字，而Java8所提供的`Optional`类则在减少`NullPointException`的同时，也提升了代码的美观度。但首先我们需要明确的是，它并 **不是对`null`关键字的一种替代，而是对于`null`判定提供了一种更加优雅的实现，从而避免`NullPointException`**。

`java.util.Optional<T>` 对可能缺失的值建模,引入的目的并非是要消除每一个 `null` 引用，而是帮助你更好地设计出普适的 API。

创建 `Optional` 对象,三个静态工厂方法：
- `Optional.empty`：创建空的 `Optional` 对象
- `Optional.of`：依据非空值创建 `Optional` 对象，若传空值会抛 `NPE`
- `Optianal.ofNullable`：创建 `Optional` 对象，允许传空值

`Optional` API：
- `isPresent()`: 变量存在返回`true`
- `get()`: 返回封装的变量值，或者抛出 `NoSuchElementException`
- `orElse(T other)`: 提供默认值
- `orElseGet(Supplier<? extends T> other)`: `orElse` 方法的延迟调用版
- `orElseThrow(Supplier<> extends X> exceptionSupplier)`: 类似 `get`，但可以定制希望抛出的异常类型
- `ifPresent(Consumer<? super T>)`: 变量存在时可以执行一个方法

值得注意的是：`Optional`是一个**`final`类**，未实现任何接口，所以当我们在利用该类包装定义类的属性的时候，如果我们定义的类有序列化的需求，那么因为`Optional`**没有实现`Serializable`接口**，这个时候执行序列化操作就会有问题：
```java
public class User implements Serializable{

    /** 用户编号 */
    private long id;
    private String name;
    private int age;
    private Optional<Long> phone;  // 不能序列化
    private Optional<String> email;  // 不能序列化
```

不过我们可以采用如下替换策略：
```java
private long phone;

public Optional<Long> getPhone() {
    return Optional.ofNullable(this.phone);
}
```
Optional 类设计的初衷仅仅是要支持能返回 Optional 对象的方法，没有考虑将它作为类的字段使用...

# Streams

## 流是什么

先来一段代码：

```java
Arrays.asList("a1", "a2", "b1", "c2", "c1").stream()
                                           .filter(s -> s.startsWith("c"))
                                           .map(String::toUpperCase)
                                           .sorted()
                                           .forEach(System.out::println);
```
流是Java SE 8类库中新增的关键抽象，它被定义于`java.util.stream`（这个包里有若干流类型：`Stream<T>`代表对象引用流，此外还有一系列特化（specialization）流，比如`IntStream`代表整形数字流）。每个流代表一个值序列，流提供一系列常用的聚集操作，使得我们可以便捷的在它上面进行各种运算。集合类库也提供了便捷的方式使我们可以以操作流的方式使用集合、数组以及其它数据结构。流的操作可以被组合成流水线（Pipeline）。

引入的原因：
- 声明性方式处理数据集合
- 透明地并行处理，提高性能

**流** 的定义：从支持数据处理操作的源生成的元素序列
两个重要特点：
- 流水线
- 内部迭代

流与集合：
- 集合与流的差异就在于什么时候进行计算    
  - 集合是内存中的数据结构，包含数据结构中目前所有的值
  - 流的元素则是按需计算/生成
- 另一个关键区别在于遍历数据的方式    
  - 集合使用 Collection 接口，需要用户去做迭代，称为外部迭代
  - 流的 Streams 库使用内部迭代

流的使用：
- 一个数据源（如集合）来执行一个查询；
- 一个中间操作链，形成一条流的流水线；
- 一个终端操作，执行流水线，并能生成结果。

流的流水线背后的理念类似于构建器模式。常见的中间操作有`filter`,`map`,`limit`,`sorted`,`distinct`；常见的终端操作有 `forEach`,`count`,`collect`。

![](http://ojoba1c98.bkt.clouddn.com/img/java/stream.png)
流的操作类型分为两种：
* `Intermediate`：一个流可以后面跟随零个或多个 `intermediate` 操作。其目的主要是**打开流**，做出某种程度的数据映射/过滤，然后返回一个新的流，交给下一个操作使用。这类操作都是**惰性化的**（**lazy**），就是说，仅仅调用到这类方法，**并没有真正开始流的遍历**。
* `Terminal`：一个流只能有一个 `terminal` 操作，当这个操作执行后，流就被使用“光”了，无法再被操作。所以这必定是流的**最后一个操作**。`Terminal` 操作的执行，**才会真正开始流的遍历**，并且会生成一个结果，或者一个 **side effect**。

## 流的使用
### 构建流
- 由值创建流：`Stream.of`、`Stream.empty`、`IntStream.range`
- 由集合创建流：`Collection.stream`、`Collection.parallelStream`
- 由数组创建流：`Arrays.stream(数组变量)`
- 由文件生成流：`Files.lines`、`Files.walk`
- 由BufferedReader创建流：`java.io.BufferedReader.lines`
- 由函数生成流：创建无限流，    
  - 迭代： `Stream.iterate`（接受一个种子值，和一个`UnaryOperator`）
  - 生成：`Stream.generate`（接收一个`Supplier`接口）

### 使用流

#### Intermediate（中间操作）：

- 筛选:    
  - 谓词筛选：`filter`
  - 筛选互异的元素：`distinct`
  - 忽略头几个元素：`skip`
  - 截短至指定长度：`limit`
  - 排序：`sorted`
  - 偷瞄（输出）：`peek`
  - 平行化：`parallel`
  - 串行化：`sequential`
- 映射:
  - 对流中每个元素应用函数：`map`
  - 流的扁平化：`flatMap`
- 数值范围：
  - `range`:`[起始值，结束值)`
  - `rangeClosed`:`[起始值，结束值]`

#### Terminal（终结操作）
- 查找和匹配:
  - 检查谓词是否至少匹配一个元素：`anyMatch`
  - 检查谓词是否匹配所有元素：`allMatch`/`noneMatch`
  - 查找元素：`findAny`
  - 查找第一个元素：`findFirst`
- 归约（折叠）：`reduce`(初值，结合操作)
  - 元素求和：`count`、`sum`
  - 最大值和最小值：`min`、 `max`
- 遍历：`forEach`、 `forEachOrdered`

`anyMatch`,`allMatch`,`noneMatch` 都用到了短路；`distinct`,`sorted`是有状态且无界的，`skip`,`limit`,`reduce`是有状态且有界的。
原始类型流特化：`IntStream`,`DoubleStream`,`LongStream`，避免暗含的装箱成本。
- 映射到数值流：`mapToInt`,`mapToDouble`,`mapToLong`
- 转换回流对象：`boxed`
- 默认值：`OptionalInt`,`OptionalDouble`,`OptionalLong`



### 用流收集数据
对流调用 `collect` 方法将对流中的元素触发归约操作（由 `Collector` 来参数化）。
Collectors 实用类提供了许多静态工厂方法，用来创建常见收集器的实例，主要提供三大功能：
- 将流元素归约和汇总为一个值
- 元素分组
- 元素分区


归约和汇总(`Collectors` 类中的工厂方法)：
- 统计个数：`Collectors.counting`
- 查找流中最大值和最小值：`Collectors.maxBy`,`Collectors.minBy`
- 汇总：`Collectors.summingInt`,`Collectors.averagingInt`,`summarizingInt`/`IntSummaryStatistics`。还有对应的 long 和 double 类型的函数
- 连接字符串：`joining`
- 广义的归约汇总：`Collectors.reducing(起始值，映射方法，二元结合)`/`Collectors.reducing(二元结合)`。`Collectors.reducing` 工厂方法是所有上述特殊情况的一般化。

`collect vs. reduce`，两者都是 `Stream` 接口的方法，区别在于：
- 语意问题    
  - reduce 方法旨在把两个值结合起来生成一个新值，是不可变的归约；
  - collect 方法设计就是要改变容器，从而累积要输出的结果
- 实际问题    
  - 以错误的语义使用 reduce 会导致归约过程不能并行工作

分组和分区
- 分组：`Collectors.groupingBy`
  - 多级分组
  - 按子数组收集数据: `maxBy`
    - 把收集器的结果转换为另一种结果 `collectingAndThen`
    - 与 groupingBy 联合使用的其他收集器例子：`summingInt`,`mapping`

- 分区：是分组的特殊情况，由一个谓词作为分类函数(分区函数)

## Notice And Optimization

* 流不可被复用
* 一般先`filter`、`limit`、`skip`操作后再进行`map`、`sorted`、`peek`等操作以达到`short-circuiting` 目的


# Annotations

Java 8中的注解是可重复的。
首先，我们定义一个包装注解，它包括了一个实际注解的数组:
```java
@interface Hints {
    Hint[] value();
}

@Repeatable(Hints.class)
@interface Hint {
    String value();
}
```

只要在前面加上注解名：`@Repeatable`，Java 8 允许我们对同一类型使用多重注解
变体1：使用注解容器（老方法）
```
@Hints({@Hint("hint1"), @Hint("hint2")})
class Person {}

```

变体2：使用可重复注解（新方法）
```
@Hint("hint1")
@Hint("hint2")
class Person {}
```

使用变体2，Java编译器能够在内部自动对@Hint进行设置。这对于通过反射来读取注解信息来说，是非常重要的。
```
Hint hint = Person.class.getAnnotation(Hint.class);
System.out.println(hint);                   // null

Hints hints1 = Person.class.getAnnotation(Hints.class);
System.out.println(hints1.value().length);  // 2

Hint[] hints2 = Person.class.getAnnotationsByType(Hint.class);
System.out.println(hints2.length);          // 2
```

尽管我们绝对不会在`Person`类上声明`@Hints`注解，但是它的信息仍然可以通过`getAnnotation(Hints.class)`来读取。并且，`getAnnotationsByType`方法会更方便，因为它赋予了所有`@Hints`注解标注的方法直接的访问权限。
```
@Target({ElementType.TYPE_PARAMETER, ElementType.TYPE_USE})
@interface MyAnnotation {}
```

# Summary
关于java8的介绍与使用网上有太多太多了，如***[java8最佳技巧](https://zhuanlan.zhihu.com/p/27424997)***等等...
> 参考
> ***[http://winterbe.com/posts/2014/03/16/java-8-tutorial/](http://winterbe.com/posts/2014/03/16/java-8-tutorial/)***
> ***[http://brianway.github.io/2017/03/29/javase-java8/#%E6%B5%81stream-api](http://brianway.github.io/2017/03/29/javase-java8/#%E6%B5%81stream-api)***
> ***[http://ifeve.com/java-8-features-tutorial/](http://ifeve.com/java-8-features-tutorial/)***
