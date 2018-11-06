---
title: Java8 Noob Tutorial
date: 2017-05-03 18:23:06
categories: [Programming, Java]
tags: [Java]
---
![](https://cdn.yangbingdong.com/img/java/java8.jpg)
# Preface
> "Java is still not dead—and people are starting to figure that out."
> Java 8是自Java  5（2004年）发布以来Java语言最大的一次版本升级，Java 8带来了很多的新特性，包括Lambda 表达式、方法引用、流(Stream API)、默认方法、Optional、组合式异步编程、新的时间 API，等等各个方面。利用这些特征，我们可以写出如同清泉般的简洁代码= =...

<!--more-->

# Default Methods for Interfaces
Java 8 允许我们使用`default`关键字，为接口声明添加非抽象的方法实现。这个特性又被称为扩展方法。下面是我们的第一个例子：
```java
interface Formula {
    double calculate(int a);

    default double sqrt(int a) {
        return Math.sqrt(a);
    }
}
```
在接口Formula中，除了抽象方法`caculate`以外，还定义了一个默认方法`sqrt.Formula`的实现类只需要实现抽象方法`caculate`就可以了。默认方法`sqrt`可以直接使用。
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

button.addActionListener(new ActionListener()) {
  public void actionPerformed(ActionEvent e) {
    ui.dazzle(e.getModifiers());
  }
}
```

匿名类型**最大的问题**就在于其**冗余的语法**。有人戏称匿名类型导致了“高度问题”（**height problem**）：比如前面`ActionListener`的例子里的五行代码中仅有一行在做实际工作。
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
在IDEA里面，对于可以写成Lambda表达式的，按下`Alt`+`Enter` 它会智能地提示转换

## Lexiacal Scope
### 访问局部变量
1、可以直接在Lambda表达式中访问外层的局部变量，但是和匿名对象不同的是，Lambda表达式的局部变量可以**不用声明为`final`**，不过局部变量必须不可被后面的代码修改（**即隐性的具有final的语义**）。
eg：下面代码无法编译

```java
int num = 1; 
Converter<Integer, String> s =  (param) -> String.valueOf(param + num);  
num = 5; 
```
在Lambda表达式中试图修改局部变量是不允许的！

2、在 Lambda 表达式当中被引用的变量的值**不可以被更改**。

3、在 Lambda 表达式当中**不允许**声明一个与局部变量同名的参数或者局部变量。

### 访问对象字段与静态变量
和局部变量不同的是，Lambda内部对于实例的字段（即：成员变量）以及静态变量是**即可读又可写**。

### 不能访问接口的默认方法
Lambda表达式中是**无法访问到默认方法**的。

**补充**：Lambda表达式对**值**封闭，对**变量**开放的原文是：lambda expressions close over **values**, not **variables**，在这里增加一个例子以说明这个特性：

```java
int sum = 0;
list.forEach(e -> { sum += e.size(); }); // Illegal, close over values

List<Integer> aList = new List<>();
list.forEach(e -> { aList.add(e); }); // Legal, open over variables
```

## 匿名内部类的简写？

**Lambda表达式通过`invokedynamic`指令实现，书写Lambda表达式不会产生新的类**。如果有如下代码，编译之后只有一个`class`文件：

```
public class MainLambda {
	public static void main(String[] args) {
		new Thread(
				() -> System.out.println("Lambda Thread run()")
			).start();;
	}
}
```

编译之后的结果：

![](https://cdn.yangbingdong.com/img/java/2-Lambda.png)

通过javap反编译命名，我们更能看出Lambda表达式内部表示的不同：

```
// javap -c -p MainLambda.class
public class MainLambda {
  ...
  public static void main(java.lang.String[]);
    Code:
       0: new           #2                  // class java/lang/Thread
       3: dup
       4: invokedynamic #3,  0              // InvokeDynamic #0:run:()Ljava/lang/Runnable; /*使用invokedynamic指令调用*/
       9: invokespecial #4                  // Method java/lang/Thread."<init>":(Ljava/lang/Runnable;)V
      12: invokevirtual #5                  // Method java/lang/Thread.start:()V
      15: return

  private static void lambda$main$0();  /*Lambda表达式被封装成主类的私有方法*/
    Code:
       0: getstatic     #6                  // Field java/lang/System.out:Ljava/io/PrintStream;
       3: ldc           #7                  // String Lambda Thread run()
       5: invokevirtual #8                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
       8: return
}
```

反编译之后我们发现Lambda表达式被封装成了主类的一个私有方法，并通过*`invokedynamic`*指令进行调用。

## Lambda表达式中的this

既然Lambda表达式不是内部类的简写，那么Lambda内部的`this`引用也就跟内部类对象没什么关系了。在Lambda表达式中`this`的意义跟在表达式外部完全一样。

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

显示结果：`Lambda`

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
- `filter(Predicate<? super T> predicate)`: 过滤
- `map(Function<? super T, ? extends U> mapper)`: 转换
- `flatMap(Function<? super T, Optional<U>> mapper)`: 转换成Optional

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
`Optional` 类设计的初衷仅仅是要支持能返回 `Optional` 对象的方法，没有考虑将它作为类的字段使用...

**另外，在Java9中对Optional添加了三个新的方法：**

1. `public Optional<T> or(Supplier<? extends Optional<? extends T>> supplier)`
   `or` 方法的作用是，如果一个 `Optional` 包含值，则返回自己；否则返回由参数 *supplier* 获得的 `Optional`

2. `public void ifPresentOrElse(Consumer<? super T> action, Runnable emptyAction)`
   `ifPresentOrElse` 方法的用途是，如果一个 `Optional` 包含值，则对其包含的值调用函数 *action*，即 `action.accept(value)`，这与 `ifPresent` 一致；与 `ifPresent` 方法的区别在于，`ifPresentOrElse` 还有第二个参数 `emptyAction` —— 如果 `Optional` 不包含值，那么 `ifPresentOrElse` 便会调用 `emptyAction`，即 `emptyAction.run()`

3. `public Stream<T> stream()`
   `stream` 方法的作用就是将 `Optional` 转为一个 `Stream`，如果该 `Optional` 中包含值，那么就返回包含这个值的 `Stream`；否则返回一个空的 `Stream`（`Stream.empty()`）。

   举个例子，在 Java8，我们会写下面的代码：

   ```
   // 此处 getUserById 返回的是 Optional<User>
   public List<User> getUsers(Collection<Integer> userIds) {
          return userIds.stream()
               .map(this::getUserById)     // 获得 Stream<Optional<User>>
               .filter(Optional::isPresent)// 去掉不包含值的 Optional
               .map(Optional::get)
               .collect(Collectors.toList());
   }
   ```

   而有了 `Optional.stream()`，我们就可以将其简化为：

   ```
   public List<User> getUsers(Collection<Integer> userIds) {
       return userIds.stream()
               .map(this::getUserById)    // 获得 Stream<Optional<User>>
               .flatMap(Optional::stream) // Stream 的 flatMap 方法将多个流合成一个流
               .collect(Collectors.toList());
   }
   ```

# Streams

![](https://cdn.yangbingdong.com/img/java/Java_stream_Interfaces.png)

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

![](https://cdn.yangbingdong.com/img/java/stream.png)
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
  - 转为原始流：`mapToInt`、`mapToInt`、`mapToInt`
  - 从原始流转为普通流：`boxed`
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
  - `reduce` 方法旨在把两个值结合起来生成一个新值，是不可变的归约；
  - `collect` 方法设计就是要改变容器，从而累积要输出的结果
- 实际问题    
  - 以错误的语义使用 `reduce` 会导致归约过程不能并行工作

分组和分区
- 分组：`Collectors.groupingBy`
  - 多级分组
  - 按子数组收集数据: `maxBy`
    - 把收集器的结果转换为另一种结果 `collectingAndThen`
    - 与 `groupingBy` 联合使用的其他收集器例子：`summingInt`,`mapping`
- 分区：`Collectors.partitioningBy`是分组的特殊情况，由一个谓词作为分类函数(分区函数)，返回一个Map，只有两个Boolean类型的key。

#### Ex1:使用collect()生成Collection

前面已经提到通过`collect()`方法将*Stream*转换成容器的方法，这里再汇总一下。将*Stream*转换成*List*或*Set*是比较常见的操作，所以*Collectors*工具已经为我们提供了对应的收集器，通过如下代码即可完成：

```
// 将Stream转换成List或Set
Stream<String> stream = Stream.of("I", "love", "you", "too");
List<String> list = stream.collect(Collectors.toList()); // (1)
Set<String> set = stream.collect(Collectors.toSet()); // (2)
```

上述代码能够满足大部分需求，但由于返回结果是接口类型，我们并不知道类库实际选择的容器类型是什么，有时候我们可能会想要人为指定容器的实际类型，这个需求可通过`Collectors.toCollection(Supplier<C> collectionFactory)`方法完成。

```
// 使用toCollection()指定规约容器的类型
ArrayList<String> arrayList = stream.collect(Collectors.toCollection(ArrayList::new));// (3)
HashSet<String> hashSet = stream.collect(Collectors.toCollection(HashSet::new));// (4)
```

上述代码(3)处指定规约结果是*ArrayList*，而(4)处指定规约结果为*HashSet*。一切如你所愿。

#### Ex2:使用collect()生成Map

前面已经说过*Stream*背后依赖于某种数据源，数据源可以是数组、容器等，但不能是*Map*。反过来从*Stream*生成*Map*是可以的，但我们要想清楚*Map*的*key*和*value*分别代表什么，根本原因是我们要想清楚要干什么。通常在三种情况下`collect()`的结果会是*Map*：

1. 使用`Collectors.toMap()`生成的收集器，用户需要指定如何生成*Map*的*key*和*value*。
2. 使用`Collectors.partitioningBy()`生成的收集器，对元素进行二分区操作时用到。
3. 使用`Collectors.groupingBy()`生成的收集器，对元素做*group*操作时用到。

情况1：使用`toMap()`生成的收集器，这种情况是最直接的，前面例子中已提到，这是和`Collectors.toCollection()`并列的方法。如下代码展示将学生列表转换成由<学生，GPA>组成的*Map*。非常直观，无需多言。

```
// 使用toMap()统计学生GPA
Map<Student, Double> studentToGPA =
     students.stream().collect(Collectors.toMap(Functions.identity(),// 如何生成key
                                     student -> computeGPA(student)));// 如何生成value
```

情况2：使用`partitioningBy()`生成的收集器，这种情况适用于将`Stream`中的元素依据某个二值逻辑（满足条件，或不满足）分成互补相交的两部分，比如男女性别、成绩及格与否等。下列代码展示将学生分成成绩及格或不及格的两部分。

```
// Partition students into passing and failing
Map<Boolean, List<Student>> passingFailing = students.stream()
         .collect(Collectors.partitioningBy(s -> s.getGrade() >= PASS_THRESHOLD));
```

情况3：使用`groupingBy()`生成的收集器，这是比较灵活的一种情况。跟SQL中的*group by*语句类似，这里的*groupingBy()也是按照某个属性对数据进行分组，属性相同的元素会被对应到Map*的同一个*key*上。下列代码展示将员工按照部门进行分组：

```
// Group employees by department
Map<Department, List<Employee>> byDept = employees.stream()
            .collect(Collectors.groupingBy(Employee::getDepartment));
```

以上只是分组的最基本用法，有些时候仅仅分组是不够的。在SQL中使用*group by*是为了协助其他查询，比如*1. 先将员工按照部门分组，2. 然后统计每个部门员工的人数*。Java类库设计者也考虑到了这种情况，增强版的`groupingBy()`能够满足这种需求。增强版的`groupingBy()`允许我们对元素分组之后再执行某种运算，比如求和、计数、平均值、类型转换等。这种先将元素分组的收集器叫做**上游收集器**，之后执行其他运算的收集器叫做**下游收集器**(*downstream Collector*)。

```
// 使用下游收集器统计每个部门的人数
Map<Department, Integer> totalByDept = employees.stream()
                    .collect(Collectors.groupingBy(Employee::getDepartment,
                                                   Collectors.counting()));// 下游收集器
```

上面代码的逻辑是不是越看越像SQL？高度非结构化。还有更狠的，下游收集器还可以包含更下游的收集器，这绝不是为了炫技而增加的把戏，而是实际场景需要。考虑将员工按照部门分组的场景，如果*我们想得到每个员工的名字（字符串），而不是一个个*Employee*对象*，可通过如下方式做到：

```
// 按照部门对员工分布组，并只保留员工的名字
Map<Department, List<String>> byDept = employees.stream()
                .collect(Collectors.groupingBy(Employee::getDepartment,
                        Collectors.mapping(Employee::getName,// 下游收集器
                                Collectors.toList())));// 更下游的收集器
```

## Notice And Optimization

* 流不可被复用
* 一般先`filter`、`limit`、`skip`操作后再进行`sorted`、`peek`、`map`等操作以达到`short-circuiting` 目的


| Stream操作分类                    |                                          |                                          |
| ----------------------------- | ---------------------------------------- | ---------------------------------------- |
| 中间操作(Intermediate operations) | 无状态(Stateless)                           | unordered() filter() map() mapToInt() mapToLong() mapToDouble() flatMap() flatMapToInt() flatMapToLong() flatMapToDouble() peek() |
| 有状态(Stateful)                 | distinct() sorted() sorted() limit() skip() |                                          |
| 结束操作(Terminal operations)     | 非短路操作                                    | forEach() forEachOrdered() toArray() reduce() collect() max() min() count() |
| 短路操作(short-circuiting)        | anyMatch() allMatch() noneMatch() findFirst() findAny() |                                          |

Stream上的所有操作分为两类：中间操作和结束操作，中间操作只是一种标记，只有结束操作才会触发实际计算。中间操作又可以分为无状态的(*`Stateless`*)和有状态的(*`Stateful`*)，无状态中间操作是指元素的处理不受前面元素的影响，而有状态的中间操作必须等到所有元素处理之后才知道最终结果，比如排序是有状态操作，在读取所有元素之前并不能确定排序结果；结束操作又可以分为短路操作和非短路操作，短路操作是指不用处理全部元素就可以返回结果，比如*找到第一个满足条件的元素*。之所以要进行如此精细的划分，是因为底层对每一种情况的处理方式不同。

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

# Time API

## 现有API存在的问题

- 线程安全: `Date`和`Calendar`**不是线程安全的**，你需要编写额外的代码处理线程安全问题
- API设计和易用性: 由于`Date`和`Calendar`的设计不当你无法完成日常的日期操作
- `ZonedDate`和`Time`: 你必须编写额外的逻辑处理时区和那些旧的逻辑

好在[JSR 310](http://link.zhihu.com/?target=http%3A//jcp.org/en/jsr/detail%3Fid%3D310)规范中为Java8添加了新的API
在`java.time`包中，新的API纠正了过去的缺陷

## 新的日期API

- `ZoneId`: 时区ID，用来确定`Instant`和`LocalDateTime`互相转换的规则
- `Instant`: 用来表示时间线上的一个点
- `LocalDate`: 表示没有时区的日期, `LocalDate`是不可变并且**线程安全**的
- `LocalTime`: 表示没有时区的时间, `LocalTime`是不可变并且**线程安全**的
- `LocalDateTime`: 表示没有时区的日期时间, `LocalDateTime`是不可变并且线程安全的
- `Clock`: 用于访问当前时刻、日期、时间，用到时区
- `Duration`: 用秒和纳秒表示时间的数量

最常用的就是`LocalDate`、`LocalTime`、`LocalDateTime`

## Clock

`Clock`提供了对当前时间和日期的访问功能。`Clock`是对当前时区敏感的，并可用于替代`System.currentTimeMillis()`方法来获取当前的毫秒时间。当前时间线上的时刻可以用`Instance`类来表示。Instance也能够用于创建原先的`java.util.Date`对象。

```
Clock clock = Clock.systemDefaultZone();
long millis = clock.millis();

Instant instant = clock.instant();
Date legacyDate = Date.from(instant); // legacy java.util.Date
```

## Timezones

时区类可以用一个`ZoneId`来表示。时区类的对象可以通过静态工厂方法方便地获取。时区类还定义了一个偏移量，用来在当前时刻或某时间与目标时区时间之间进行转换。

```
System.out.println(ZoneId.getAvailableZoneIds());
// prints all available timezone ids

ZoneId zone1 = ZoneId.of("Europe/Berlin");
ZoneId zone2 = ZoneId.of("Brazil/East");
System.out.println(zone1.getRules());
System.out.println(zone2.getRules());

// ZoneRules[currentStandardOffset=+01:00]
// ZoneRules[currentStandardOffset=-03:00]
```

## LocalDate

`LocalDate`代表一个IOS格式(`yyyy-MM-dd`)的日期，它有多个构造方法：

```
LocalDate.now();
LocalDate.of(2018, 8, 15);
LocalDate.parse("2018-08-15");
LocalDate.parse("2018.08.15", DateTimeFormatter.ofPattern("yyyy.MM.dd"))
```

其他API：

```
// 获取明天
LocalDate tomorrow = LocalDate.now().plusDays(1);

// 上一个月的今天
LocalDate prevMonth = LocalDate.now().minus(1, ChronoUnit.MONTHS);

// 获取今天是星期几
DayOfWeek thursday = LocalDate.parse("2018-09-27").getDayOfWeek();

// 获取今天是几号
int dayOfMonth = LocalDate.parse("2018-09-27").getDayOfMonth();

// 今年是不是闰年
boolean leapYear = LocalDate.now().isLeapYear();
```

日期比较：

```
LocalDate now = LocalDate.now();
LocalDate tomorrow = now.plusDays(1);
System.out.println(now.isBefore(tomorrow));
System.out.println(tomorrow.isAfter(now));
```

获取这个月的第一天

```
LocalDate firstDayOfMonth = LocalDate.parse("2018-08-15").with(TemporalAdjusters.firstDayOfMonth());
System.out.println("这个月的第一天: " + firstDayOfMonth);
firstDayOfMonth = firstDayOfMonth.withDayOfMonth(1);
System.out.println("这个月的第一天: " + firstDayOfMonth);
```

判断否是生日

```
LocalDate birthday = LocalDate.of(1994, 04, 15);
MonthDay birthdayMd = MonthDay.of(birthday.getMonth(), birthday.getDayOfMonth());
MonthDay today = MonthDay.from(LocalDate.now());
System.out.println("否是生日: " + today.equals(birthdayMd));
```

固定的日期，比如信用卡过期时间

```
YearMonth currentYearMonth = YearMonth.now();
System.out.printf("Days in month year %s: %d%n", currentYearMonth,currentYearMonth.lengthOfMonth()); 
YearMonth creditCardExpiry = YearMonth.of(2018, Month.FEBRUARY); 
System.out.printf("Your credit card expires on %s %n", creditCardExpiry); 
```



## LocalTime

构造方法与LocalDate类似：

```
LocalTime.now();
LocalTime.parse("15:02");
LocalTime.of(15, 02);
```

时间加减：

```
LocalTime.parse("15:02").plus(1, ChronoUnit.HOURS);
LocalTime.now().plusHours(1);
```

获取时间的小时、分钟:

```
int hour = LocalTime.parse("15:02").getHour();
int minute = LocalTime.parse("15:02").getMinute();
```

时间比较：

```
LocalTime.parse("15:02").isBefore(LocalTime.parse("16:02"));
LocalTime.parse("15:02").isAfter(LocalTime.parse("16:02"));
```

一天的开始与结束：

```
System.out.println(LocalTime.MAX);
System.out.println(LocalTime.MIN);
```

输出:

```
23:59:59.999999999
00:00
```

## LocalDateTime

这个应该是最常用的了，构造方法与上面两个类似：

```
LocalDateTime.now();
LocalDateTime.of(2018, Month.AUGUST, 15, 15, 18);
LocalDateTime.parse("2018-08-15T15:18:00");
```

时间加减操作与上面差不多：

```
LocalDateTime tomorrow = now.plusDays(1);
LocalDateTime minusTowHour = now.minusHours(2);
```

时间比较:

```
tomorrow.isAfter(minusTowHour)
```

获取特定单位：

```
Month month = now.getMonth();
```

转换成`LocalDate`和`LocalTime`:

```
now.toLocalDate();
now.toLocalTime();
```

获取某天的开始：

```
LocalDateTime localDateTime = LocalDateTime.now();
LocalDateTime startOfDay = now.toLocalDate().atStartOfDay();
```

## 日期格式化

```
LocalDateTime now = LocalDateTime.now();
DateTimeFormatter dateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
System.out.println("默认格式化: " + now);
System.out.println("自定义格式化: " + now.format(dateTimeFormatter));
LocalDateTime localDateTime = LocalDateTime.parse("2018-08-15 15:27:44", dateTimeFormatter);
System.out.println("字符串转LocalDateTime: " + localDateTime);
```

也可以使用`DateTimeFormatter`的`format`方法将日期、时间格式化为字符串

```
DateTimeFormatter dateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
String dateString = dateTimeFormatter.format(LocalDate.now());
System.out.println("日期转字符串: " + dateString);
```

## 日期周期

`Period`类用于修改给定日期或获得的两个日期之间的区别。

给初始化的日期添加5天:

```
LocalDate initialDate = LocalDate.parse("2018-08-15");
LocalDate finalDate = initialDate.plus(Period.ofDays(5));
```

周期API中提供给我们可以比较两个日期的差别，像下面这样获取差距天数:

```
long between = ChronoUnit.DAYS.between(initialDate, finalDate);
```

上面的代码会返回5，当然你想获取两个日期相差多少小时也是简单的。

## 与Date转换

`Date`和`Instant`互相转换

```
Date date = Date.from(Instant.now());
Instant instant = date.toInstant();
```

`Date`转换为`LocalDateTime`

```
LocalDateTime now = LocalDateTime.ofInstant(new Date().toInstant(), ZoneId.systemDefault());
```

`LocalDateTime`转`Date`

```
Date date = Date.from(LocalDateTime.now().atZone(ZoneId.systemDefault()).toInstant());
```

`LocalDate`转`Date`

```
Date date = Date.from(LocalDate.now().atStartOfDay().atZone(ZoneId.systemDefault()).toInstant());
```

# Other Extend

## Lambda表达式遇上检测型异常

先来看一段代码：

```
long count = Files.walk(Paths.get("/home/test"))                      // 获得项目目录下的所有目录及文件
                .filter(file -> !Files.isDirectory(file))          // 筛选出文件
                .filter(file -> file.toString().endsWith(".java")) // 筛选出 java 文件
                .flatMap(file -> Files.lines(file))                // 按行获得文件中的文本
                .filter(line -> !line.trim().isEmpty())            // 过滤掉空行
                .count();

System.out.println("代码行数：" + count);
```

> - `Files.walk(Path)` 在 JDK1.8 时添加，深度优先遍历一个 `Path` （目录），返回这个目录下所有的 `Path`（目录和文件），通过 `Stream<Path>` 返回；
> - `Files.lines(Path)` 也是在 JDK1.8 时添加，功能是返回指定 `Path` （文件）中所有的行，通过 `Stream<String>` 返回。

然后，编译不过 —— 因为 `Files.lines(Path)` 会抛出 `IOException`，如果要编译通过，得这样写：

```
long count = Files.walk(Paths.get("/home/test"))                      // 获得项目目录下的所有文件
                .filter(file -> !Files.isDirectory(file))          // 筛选出文件
                .filter(file -> file.toString().endsWith(".java")) // 筛选出 java 文件
                .flatMap(file -> {
                    try {
                        return Files.lines(file);
                    } catch (IOException ex) {
                        ex.printStackTrace(System.err);
                        return Stream.empty();                     // 抛出异常时返回一个空的 Stream
                    }
                })                                                 // 按行获得文件中的文本
                .filter(line -> !line.trim().isEmpty())            // 过滤掉空行
                .count();

System.out.println("代码行数：" + count);
```

对于有强迫症的程序员来说这简直是噩梦，*`one-liner expression`* 的 Lambda需要绝对的简介明了。

这里有两种做法，比较偷懒的就是每个会抛出异常的地方我们独自捕获处理，这样带来的问题就是不够通用，每个异常方法都要捕获一次：

```
public static void main(String[] args) throws Exception {
    long count = Files.walk(Paths.get("/home/test"))                       // 获得项目目录下的所有文件
                    .filter(file -> !Files.isDirectory(file))           // 筛选出文件
                    .filter(file -> file.toString().endsWith(".java"))  // 筛选出 java 文件
                    .flatMap(file -> getLines(file))                    // 按行获得文件中的文本
                    .filter(line -> !line.trim().isEmpty())             // 过滤掉空行
                    .count();

    System.out.println("代码行数：" + count);
}

private static Stream<String> getLines(Path file) {
    try {
        return Files.lines(file);
    } catch (IOException ex) {
        ex.printStackTrace(System.err);
        return Stream.empty();
    }
}
```

这种解决方法下，我们需要处理受检异常 —— 即在程序抛出异常的时候，我们需要告诉程序怎么去做（`getLines` 方法中抛出异常时我们输出了异常，并返回一个空的 `Stream`）

上面方式当然是不可取的啦，我们选择更偷懒的方式，**将会抛出异常的函数进行包装，使其不抛出受检异常**。

如果一个 *`FunctionInterface`* 的方法会抛出受检异常（比如 `Exception`），那么该 *`FunctionInterface`* 便可以作为会抛出受检异常的 Lambda 的目标类型。
我们定义如下一个 *`FunctionInterface`*：

```
@FunctionalInterface
public interface UncheckedFunction<T, R> {
	R apply(T t) throws Exception;
}
```

那么该 *`FunctionInterface`* 便可以作为类似于 `file -> File.lines(file)` 这类会抛出受检异常的 Lambda 的目标类型，此时 Lambda 中并不需要捕获异常（因为目标类型的 `apply` 方法已经将异常抛出了）—— 之所以原来的 Lambda 需要捕获异常，就是因为在流式操作 `flatMap` 中使用的 `java.util.function` 包下的 `Function<T, R>` 没有抛出异常：

![](https://cdn.yangbingdong.com/img/java-8-tutorial-extend/java-8-function.png)

那我们如何使用 `UncheckedFunction` 到流式操作的 Lambda 中呢？
首先我们定义一个 `Trier` 类，它的 `tryFunction` 方法提供将 `UncheckedFunction` 包装为 `Function` 的功能：

```
public class Trier {
   private static final Logger LOGGER = LoggerFactory.getLogger(Trier.class);

   public static <T, R> Function<T, R> tryFunction(UncheckedFunction<T, R> function) {
      requireNonNull(function);
      return t -> {
         try {
            return function.apply(t);
         } catch (Exception e) {
            throw logAndThrow(e);
         }
      };
   }
   
    @FunctionalInterface
    public static interface UncheckedFunction<T, R> {

        R apply(T t) throws Exception;
    }
}
```

然后在原先的代码中，我们使用 `Trier.tryFunction` 方法来对会抛出受检异常的 Lambda 进行包装：

```
long count = Files.walk(Paths.get("/home/test"))              // 获得项目目录下的所有文件
                .filter(file -> !Files.isDirectory(file))          // 筛选出文件
                .filter(file -> file.toString().endsWith(".java")) // 筛选出 java 文件
        
                .flatMap(Trier.tryFunction(file -> Files.lines(file)))        // 将 会抛出受检异常的 Lambda 包装为 抛出非受检异常的 Lambda
        
                .filter(line -> !line.trim().isEmpty())            // 过滤掉空行
                .count();

System.out.println("代码行数：" + count);
```

指定默认值的包装方法，即如果抛出异常，那么就返回默认值：

```
public static <T, R> Function<T, R> tryFunction(UncheckedFunction<T, R> function, R defaultValue) {
		requireNonNull(function);
		return t -> {
			try {
				return function.apply(t);
			} catch (Exception e) {
				return logAndReturn(e, defaultValue);
			}
		};
	}
	
private static <R> R logAndReturn(Exception e, R defaultValue) {
		LOGGER.error("Trier catch an exception: " + getFullStackTrace(e) + "\n And return default value: " + defaultValue);
		return defaultValue;
	}
```

比如我们前面的例子，如果 `file -> Files.lines(file)` 抛出异常了，说明在访问 *file* 类的时候出了问题，我们可以就假设这个文件的行数为 0 ，那么默认值就是个空的 `Stream<String>`：

```
long count = Files.walk(Paths.get("/home/test"))              // 获得项目目录下的所有文件
                .filter(file -> !Files.isDirectory(file))          // 筛选出文件
                .filter(file -> file.toString().endsWith(".java")) // 筛选出 java 文件
        
                .flatMap(Trier.tryFunction(file -> Files.lines(file), Stream.empty()))
        
                .filter(line -> !line.trim().isEmpty())            // 过滤掉空行
                .count();

System.out.println("代码行数：" + count);
```

如此类推，我们可以创建`UncheckedConsumer`、`UncheckedSupplier`等：

```
public class Trier {
	private static final Logger LOGGER = LoggerFactory.getLogger(Trier.class);

	public static <T, R> Function<T, R> tryFunction(UncheckedFunction<T, R> function) {
		requireNonNull(function);
		return t -> {
			try {
				return function.apply(t);
			} catch (Exception e) {
				throw logAndThrow(e);
			}
		};
	}

	public static <T, R> Function<T, R> tryFunction(UncheckedFunction<T, R> function, R defaultValue) {
		requireNonNull(function);
		return t -> {
			try {
				return function.apply(t);
			} catch (Exception e) {
				return logAndReturn(e, defaultValue);
			}
		};
	}

	public static <T> Supplier<T> trySupplier(UncheckedSupplier<T> supplier) {
		requireNonNull(supplier);
		return () -> {
			try {
				return supplier.get();
			} catch (Exception e) {
				throw logAndThrow(e);
			}
		};
	}

	public static <T> Supplier<T> trySupplier(UncheckedSupplier<T> supplier, T defaultValue) {
		requireNonNull(supplier);
		return () -> {
			try {
				return supplier.get();
			} catch (Exception e) {
				return logAndReturn(e, defaultValue);
			}
		};
	}

	public static <T> Consumer<T> tryConsumer(UncheckedConsumer<T> consumer) {
		requireNonNull(consumer);
		return t -> {
			try {
				consumer.accept(t);
			} catch (Exception e) {
				throw logAndThrow(e);
			}
		};
	}

	public static <T> Predicate<T> tryPredicate(UncheckedPredicate<T> predicate) {
		requireNonNull(predicate);
		return t -> {
			try {
				return predicate.test(t);
			} catch (Exception e) {
				throw logAndThrow(e);
			}
		};
	}

	public static <T> Predicate<T> tryPredicate(UncheckedPredicate<T> predicate, boolean defaultValue) {
		requireNonNull(predicate);
		return t -> {
			try {
				return predicate.test(t);
			} catch (Exception e) {
				return logAndReturn(e, defaultValue);
			}
		};
	}

	private static void log(Exception e) {
		LOGGER.error("Trier catch an exception: " + getFullStackTrace(e));
	}

	private static <R> R logAndReturn(Exception e, R defaultValue) {
		LOGGER.error("Trier catch an exception: " + getFullStackTrace(e) + "\n And return default value: " + defaultValue);
		return defaultValue;
	}

	private static RuntimeException logAndThrow(Exception e) {
		log(e);
		throw new RuntimeException(e);
	}

	@FunctionalInterface
	public interface UncheckedFunction<T, R> {
		R apply(T t) throws Exception;
	}

	@FunctionalInterface
	public interface UncheckedSupplier<T> {
		T get() throws Exception;
	}

	@FunctionalInterface
	public interface UncheckedConsumer<T> {
		void accept(T t) throws Exception;
	}

	@FunctionalInterface
	public interface UncheckedPredicate<T> {
		boolean test(T t) throws Exception;
	}

}
```

## Java8 对字符串连接的改进

有时候，我们会有一种需求就是将若干个字符串用某个**链接符**衔接起来，例如有一个 List<String>，将其格式化为 元素1, 元素2, 元素3, ... 元素N 的字符串形式。

以前我们的一般做法就是使用`StringBuilder`：

```
public static String formatList(List<String> list, String delimiter) {
    StringBuilder result = new StringBuilder();
    for (String str : list) {
        result.append(str).append(delimiter);
    }
    // 删除末尾多余的 delimiter
    result.delete(result.length() - delimiter.length(), result.length()); 
    
    return result.toString();
}

public static void main(String[] args) throws Exception {
    List<String> list = Arrays.asList("a", "b", "c", "d", "e", "f", "g");

    System.out.println("使用 StringBuilder：");
    String format = formatList(list, ",");
    System.out.println(format);
}
```

运行结果：

```
使用 StringBuilder：
a,b,c,d,e,f,g
```

JDK1.8 时，添加了一个新的用于字符串连接的类，专门用于这种需要 **分隔符** 的场合，它就是 `StringJoiner`。`StringJoiner` 在构造时可以指定一个分隔符（*`delimiter`*），然后每连接一个元素它便会加上一个 *`delimiter`*，使用 `StringJoiner` 改写 `formatList`：

```
public static String formatList(List<String> list, String delimiter) {
    StringJoiner result = new StringJoiner(delimiter);
    for (String str : list) {
        result.add(str);
    }
    return result.toString();
}

public static void main(String[] args) throws Exception {
    List<String> list = Arrays.asList("a", "b", "c", "d", "e", "f", "g");

    System.out.println("使用 StringJoiner：");
    String format = formatList(list, ",");
    System.out.println(format);
}
```

结果与上面一样。

或者使用`String.join`:

```
public static String formatList(List<String> list, String delimiter) {
    return String.join(delimiter, list);
}
```

它的底层也是调用`StringJoiner`：

![](https://cdn.yangbingdong.com/img/java-8-tutorial-extend/string-join.png)

但是我们看到了 `String.join` 方法的不足 —— 它不能指定前缀和后缀 —— 比如我们如果想要直接将 `List<String>` 格式化为 **{ 元素1, 元素2, 元素3, ... 元素N }** 呢？（此时前缀为 `"{ "`，后缀为 `" }"`）

查看 `StringJoiner` 的构造方法，发现 `StringJoiner` 除了指定 分隔符 的构造方法，还有一个可以指定 分隔符、前缀和后缀 的构造方法：

![](https://cdn.yangbingdong.com/img/java-8-tutorial-extend/stringjoiner.png)

修改 `formatList`：

```
public static String formatList(
        List<String> list, String delimiter, String prefix, String suffix) {

    StringJoiner result = new StringJoiner(delimiter, prefix, suffix);
    for (String str : list) {
        result.add(str);
    }
    return result.toString();
}

public static void main(String[] args) throws Exception {
    List<String> list = Arrays.asList("a", "b", "c", "d", "e", "f", "g");

    System.out.println("使用 StringJoiner，带前缀和后缀：");
    String format = formatList(list, ", ", "{ ", " }");
    System.out.println(format);
}
```

运行结果：

```
使用 StringJoiner，带前缀和后缀：
{ a, b, c, d, e, f, g }
```

事实上，Java8 对于字符串集合的连接操作提供了一个专门的流式 API，即 `Collectors.joining` 函数：
![img](https://cdn.yangbingdong.com/img/java-8-tutorial-extend/collectors-joining.png)

- 无参的 `joining()` 方法，即不存在连接符（底层实现为 `StringBuilder`）；
- `joining(CharSequence delimiter)` 方法，即分隔符为 *delimiter*（底层实现为 `StringJoiner`）；
- `joining(CharSequence delimiter, CharSequence prefix, CharSequence suffix)`方法，即分隔符为 *delimiter*，前缀为 *prefix*，后缀为 *suffix*（底层实现为 `StringJoiner`）。

那怎么使用呢？ 我们直接使用三个参数的 `Collectors.joining` 方法改写 `formatList`：

```
public static String formatList(
        List<String> list, String delimiter, String prefix, String suffix) {

    return list.stream().collect(Collectors.joining(delimiter, prefix, suffix));
}

public static void main(String[] args) throws Exception {
    List<String> list = Arrays.asList("a", "b", "c", "d", "e", "f", "g");

    System.out.println("使用 Collectors.joining：");
    String format = formatList(list, ", ", "{ ", " }");
    System.out.println(format);
}
```

运行结果同上。

## Java8 中 Map 接口的新方法

假如现在我们存在这样的需求：给定一个 `List<String>`，统计每个元素出现的所有位置。

比如，给定 *list*：`["a", "b", "b", "c", "c", "c", "d", "d", "d", "f", "f", "g"]` ，那么应该返回：

```
a : [0]
b : [1, 2]
c : [3, 4, 5]
d : [6, 7, 8]
f : [9, 10]
g : [11]
```

很明显，我们很适合使用 Map 来完成这件事情：

```
public static Map<String, List<Integer>> getElementPositions(List<String> list) {
    Map<String, List<Integer>> positionsMap = new HashMap<>();

    for (int i = 0; i < list.size(); i++) {
        String str = list.get(i);
        List<Integer> positions = positionsMap.get(str);

        if (positions == null) { // 如果 positionsMap 还不存在 str 这个键及其对应的 List<Integer>
            positions = new ArrayList<>(1);
            positionsMap.put(str, positions); // 将 str 及其对应的 positions 放入 positionsMap
        }

        positions.add(i); // 将索引加入 str 相关联的 List<Integer> 中
    }

    return positionsMap;
}

public static void main(String[] args) throws Exception {
    List<String> list = Arrays.asList("a", "b", "b", "c", "c", "c", "d", "d", "d", "f", "f", "g");

    System.out.println("使用 Java8 之前的 API：");
    Map<String, List<Integer>> elementPositions = getElementPositions(list);
    System.out.println(elementPositions);
}
```

运行结果：

```
使用 Java8 之前的 API：
{a=[0], b=[1, 2], c=[3, 4, 5], d=[6, 7, 8], f=[9, 10], g=[11]}
```

在Java8之后，`Map`添加了一下新的方法签名：

![](https://cdn.yangbingdong.com/img/java-8-tutorial-extend/map-java-8-new-method.png)

查看源码发现`computeIfAbsent`很符合上面需求：

![](https://cdn.yangbingdong.com/img/java-8-tutorial-extend/map-compute-if-absent.png)

我们可以改造成这样子：

```
public static Map<String, List<Integer>> getElementPositions(List<String> list) {
    Map<String, List<Integer>> positionsMap = new HashMap<>();

    for (int i = 0; i < list.size(); i++) {
        positionsMap.computeIfAbsent(list.get(i), k -> new ArrayList<>(1)).add(i);
    }

    return positionsMap;
}

public static void main(String[] args) throws Exception {
    List<String> list = Arrays.asList("a", "b", "b", "c", "c", "c", "d", "d", "d", "f", "f", "g");

    System.out.println("使用 computeIfAbsent：");
    Map<String, List<Integer>> elementPositions = getElementPositions(list);
    System.out.println(elementPositions);
}
```

效果一样，但是代码优雅整洁了很多。

## 当 forEach 需要索引

上面的例子通过Java8新增的`Map`方法可以很**优雅**地实现一些需求：

```
public static Map<String, List<Integer>> getElementPositions(List<String> list) {
    Map<String, List<Integer>> positionsMap = new HashMap<>();
    for (int i = 0; i < list.size(); i++) {
        positionsMap.computeIfAbsent(list.get(i), k -> new ArrayList<>(1)).add(i);
    }
    return positionsMap;
}
```

但是方法里面的`for`循环似乎让这个方法不太优雅了，Java8中`Iterable`提供的`foreach`并不带索引的：

![](https://cdn.yangbingdong.com/img/java-8-tutorial-extend/java-8-iterable-foreach.png)

我们可以自己写一个：

```
    public static <E> void forEach(
            Iterable<? extends E> elements, BiConsumer<Integer, ? super E> action) {
        Objects.requireNonNull(elements);
        Objects.requireNonNull(action);

        int index = 0;
        for (E element : elements) {
            action.accept(index++, element);
        }
    }
}
```

然后改造`getElementPositions`方法：

```
public static Map<String, List<Integer>> getElementPositions(List<String> list) {
    Map<String, List<Integer>> positionsMap = new HashMap<>();

    Iterables.forEach(list, (index, str) -> {
        positionsMap.computeIfAbsent(str, k -> new ArrayList<>(1)).add(index);
    });

    return positionsMap;
}
```

# Summary

关于java8的介绍与使用网上有太多太多了，如***[java8最佳技巧](https://zhuanlan.zhihu.com/p/27424997)***等等...

更加深入理解函数式编程请参考***[Java Functional Programming Internals](https://github.com/CarpenterLee/JavaLambdaInternals)***

> 参考
> ***[Java8简明教程](http://blog.didispace.com/books/java8-tutorial/)***
> ***[知乎专栏](https://zhuanlan.zhihu.com/java8)***
> ***[CarpenterLee](http://www.cnblogs.com/CarpenterLee/)***
> ***[http://winterbe.com/posts/2014/03/16/java-8-tutorial/](http://winterbe.com/posts/2014/03/16/java-8-tutorial/)***
> ***[http://brianway.github.io/2017/03/29/javase-java8/#%E6%B5%81stream-api](http://brianway.github.io/2017/03/29/javase-java8/#%E6%B5%81stream-api)***
> ***[https://segmentfault.com/a/1190000007832130](https://segmentfault.com/a/1190000007832130)***
