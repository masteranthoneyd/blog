---
title: 设计模式原则与UML类图
date: 2017-10-18 09:22:07
categories: [Programming, Java, Design Pattern]
tags: [Java, Design Pattern]
---

![](https://oldcdn.yangbingdong.com/img/design-pattern-uml-and-six-principle/designpatterns.png)

# Preface

> *[设计模式](https://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0ahUKEwjyks2QifnWAhVJKo8KHegiD20QFggnMAA&url=https%3A%2F%2Fzh.wikipedia.org%2Fzh-hans%2F%25E8%25AE%25BE%25E8%25AE%25A1%25E6%25A8%25A1%25E5%25BC%258F&usg=AOvVaw0z1ZKodwif8lD1sp_vC9C_)*, 总的来说, 就是前人踩过无数的坑总结出来的软件设计经验. 在学习设计模式之前, 有必要了解它的一些**规则**以及**建模**. 
> *[UML](https://zh.wikipedia.org/wiki/%E7%BB%9F%E4%B8%80%E5%BB%BA%E6%A8%A1%E8%AF%AD%E8%A8%80)*(Unified Modeling Language)又称**统一建模语言**或**标准建模语言**, 是始于1997年一个OMG(Object Management Group)标准, 它是一个支持模型化和软件系统开发的图形化语言, 为软件开发的所有阶段提供模型化和可视化支持, 包括由需求分析到规格, 到构造和配置. 

<!--more-->

# Design Pattern

在[软件工程](https://zh.wikipedia.org/wiki/%E8%BB%9F%E9%AB%94%E5%B7%A5%E7%A8%8B)中, **设计模式**(design pattern)是对[软件设计](https://zh.wikipedia.org/wiki/%E8%BB%9F%E4%BB%B6%E8%A8%AD%E8%A8%88)中普遍存在(反复出现)的各种问题, 所提出的解决方案. 这个术语是由[埃里希·伽玛](https://zh.wikipedia.org/wiki/%E5%9F%83%E9%87%8C%E5%B8%8C%C2%B7%E4%BC%BD%E7%91%AA)(Erich Gamma)等人在1990年代从[建筑设计](https://zh.wikipedia.org/wiki/%E5%BB%BA%E7%AD%91%E8%AE%BE%E8%AE%A1)领域引入到[计算机科学](https://zh.wikipedia.org/wiki/%E8%A8%88%E7%AE%97%E6%A9%9F%E7%A7%91%E5%AD%B8)的. 

设计模式并不直接用来完成[代码](https://zh.wikipedia.org/wiki/%E7%A8%8B%E5%BC%8F%E7%A2%BC)的编写, 而是描述在各种不同情况下, 要怎么解决问题的一种方案. [面向对象](https://zh.wikipedia.org/wiki/%E9%9D%A2%E5%90%91%E5%AF%B9%E8%B1%A1)设计模式通常以[类别](https://zh.wikipedia.org/wiki/%E9%A1%9E%E5%88%A5)或[对象](https://zh.wikipedia.org/wiki/%E7%89%A9%E4%BB%B6_(%E9%9B%BB%E8%85%A6%E7%A7%91%E5%AD%B8))来描述其中的关系和相互作用, 但不涉及用来完成应用程序的特定类别或对象. 设计模式能使不稳定依赖于相对稳定, 具体依赖于相对抽象, 避免会引起麻烦的紧耦合, 以增强软件设计面对并适应变化的能力.   ——来自维基百科

## 设计原则 

### 单一职责原则(SRP)

> A class or module should have a single responsibility.

单一职责原则(`Single Responsibility Principle`,SRP): 就一个类而言, 应该仅有一个引起它变化的原因. 即一个类应该**只负责一个功能领域中的相应职责**. 

**理解**:

一个类只负责完成一个职责或者功能. 不要设计大而全的类, 要设计粒度小, 功能单一的类. 单一职责原则是为了实现代码**高内聚**, **低耦合**, 提高代码的复用性, 可读性, 可维护性.

> 高内聚跟低耦合是从两个角度的不同描述:
>
> 高内聚从功能性来说, 将功能性高度相关的内容分开, 则降低了内聚性.
>
> 低耦合从功能无关性来说, 将不相关功能的内容聚合在一起, 就提高了耦合性.

**如何判断是否足够单一**?

不同的**应用场景**, 不同阶段的**需求背景**, 不同的**业务层面**, 对同一个类的职责是否单一, 可能会有不同的判定结果. 

实际上, 一些侧面的判断指标更具有指导意义和可执行性, 比如, 出现下面这些情况就有可能说明这类的设计不满足单一职责原则:

* 类中的代码行数, 函数或者属性过多.
* 类依赖的其他类过多, 或者依赖类的其他类过多.
* 私有方法过多.
* 比较难给类起一个合适的名字(说明类的职责定义得可能不够清晰).
* 类中大量的方法都是集中操作类中的某几个属性.

**类的职责是否设计得越单一越好**?

单一职责原则通过避免设计大而全的类, 避免将不相关的功能耦合在一起, 来提高类的内聚性. 同时, 类职责单一, 类依赖的和被依赖的其他类也会变少, 减少了代码的耦合性, 以此来实现代码的高内聚, 低耦合. 但是, 如果拆分得过细, 实际上会适得其反, 反倒会降低内聚性, 也会影响代码的可维护性. 

### 开闭原则(OCP)

> Software entities (modules, classes, functions, etc.) should be open for extension, but closed for modification.

开闭原则(`Open-Closed Principle`, OCP): 是指软件实体(类, 模块, 函数等等)应该**可以扩展**, **而非修改已有代码**.

**如何理解对扩展开放, 对修改关闭**?

添加一个新的功能, 应该是通过在已有代码基础上扩展代码(新增模块/类/方法/属性等), 而非修改已有代码(修改模块/类/方法/属性等)的方式来完成. 关于定义, 我们有两点要注意:

* 第一点是, 开闭原则并不是说完全杜绝修改, 而是以**最小的修改代码的代价**来完成新功能的开发. 
* 第二点是, 同样的代码改动, 在粗代码粒度下, 可能被认定为"修改"; 在细代码粒度下, 可能又被认定为"扩展". 

**如何做**?

我们要时刻具备扩展意识, 抽象意识, 封装意识. 在写代码的时候, 我们要多花点时间思考一下, 这段代码未来可能有哪些需求变更, 如何设计代码结构, 事先留好扩展点, 以便在未来需求变更的时候, 在不改动代码整体结构, 做到最小代码改动的情况下, 将新的代码灵活地插入到扩展点上. 

举个栗子, 有这么个需求, 要求处理两种消息类型A与B, 初期是这么写的:

```java
public class MessageHandlerV1 {

    public void handle(String message) {
        if ("A".equals(message)) {
            handleSceneA(message);
        }
        if ("B".equals(message)) {
            handleSceneB(message);
        }
    }

    protected void handleSceneA(String a) {
        System.out.println(a);
    }

    protected void handleSceneB(String b) {
        System.out.println(b);
    }
}
```

后期需要支持类型C的消息, 那么需要改动 `handle` 方法:

```java
public void handle(String message) {
    if ("A".equals(message)) {
        handleSceneA(message);
    }
    if ("B".equals(message)) {
        handleSceneB(message);
    }
    if ("C".equals(message)) {
        handleSceneC(message);
    }
}
```

这样就违背了 ocp 了, 而且 Test Case 也要修改, 比较麻烦.

可以稍微改造一下, 让扩展变得科学一点:

```java
public interface MessageHandler {

    String supportMessage();

    void handle(String s);
}

public class MessageHandlerA implements MessageHandler {
    @Override
    public String supportMessage() {
        return "A";
    }

    @Override
    public void handle(String s) {
        System.out.println(s);
    }
}

public class MessageHandlerManager {

    private final List<MessageHandler> messageHandlers = new ArrayList<>();

    public void addHandler(MessageHandler messageHandler) {
        messageHandlers.add(messageHandler);
    }

    public void handle(String type, String message) {
        for (MessageHandler messageHandler : messageHandlers) {
            if (messageHandler.supportMessage().equals(type)) {
                messageHandler.handle(message);
            }
        }
    }
}
```

将 `handle` 逻辑抽象成接口, 同时增加 `supportMessage` 方法, 实现方返回自己支持的消息类型. 那么这时候要扩展支持C类型的消息只需要新增一个 Handler 的实现即可:

```java
public class MessageHandlerC implements MessageHandler {
    @Override
    public String supportMessage() {
        return "C";
    }

    @Override
    public void handle(String s) {
        System.out.println(s);
    }
}
```

### 里氏替换原则(LSP)

> If S is a subtype of T, then objects of type T may be replaced with objects of type S, without breaking the program. 
>
> Functions that use pointers of references to base classes must be able to use objects of derived classes without knowing it. 
>
> PS: ***[Liskov](https://en.wikipedia.org/wiki/Barbara_Liskov)*** 是美国历史上第一个女计算机博士, 曾获得过**图灵奖**.

里氏替换原则(`Liskov Substitution Principle`,LSP): 子类对象(object of subtype/derived class)能够替换程序(program)中父类对象(object of base/parent class)出现的任何地方, 并且保证原来程序的逻辑行为(behavior)不变及正确性不被破坏. 

与多态的区别: 多态是面向对象的一大特性, 而里氏替换原则是设计原则. LSP 更关注的是对象行为, 用来指导继承关系中子类该如何设计, 子类的设计要保证在替换父类的时候, 不改变原有程序的逻辑及不破坏原有程序的正确性, 举个例子就是父类定义了一个方法, 不存在则返回 null, 子类重写(多态)了这个方法, 不存在则抛出异常, 这就违反了里氏替换原则.

举个例子, 有个 `Echo` 类, 打印输入的内容:

```java
public class Echo {
    public void echo(String s) {
        System.out.println(s);
    }
}
```

这时候对这个类做一个增强, 打印字符串后, 上报字符串到监控系统:

```java
public class PositiveEcho extends Echo {

    @Override
    public void echo(String s) {
        super.echo(s);
        metrics(s);
    }

    private void metrics(String s) {
        
    }

}
```

这个并没有改变原有的行为, 但是看一下下面这个实现, 如果输入的空对象, 那么抛出一个异常:

```java
public class NegativeEcho extends Echo {
    
    @Override
    public void echo(String s) {
        if (s == null) {
            throw new IllegalArgumentException("Input string must not be null");
        }
        System.out.println(s);
    }
}
```

原来的 `Echo` 类并没有这个限制, 如果替换成了 `NegativeEcho`, 那么输出空对象将会报错, 这改变了原有的行为, 所以不符合里氏替换原则.

### 接口隔离原则(ISP)

> Clients should not be forced to depend upon interfaces that they do not use.

接口隔离原则(`Interface Segregation Principle`,ISP): 使用专门的接口, 而不使用单一的总接口, 即客户端不应该依赖那些它不需要的接口. 

根据接口隔离原则, 当一个接口太大时, 我们需要将它分割成一些更细小的接口, 使用该接口的客户端仅需知道与之相关的方法即可. 每一个接口应该承担一种相对独立的角色, 不干不该干的事, 该干的事都要干. 

这获取跟 SRP 有点类似, 但 SRP 注重的是模块, 类, 接口的设计, 而 ISP **更加侧重于接口的设计**, 而且角度不一样, 判断的标准是调用者, 如果调用者只用到一部分的接口, 那么这个接口设计就不够单一.

比如有两个配置类:

```java
public class RabbitConfig {
    private String host;
    private String port;
}

public class RedisConfig {
    private String host;
    private String port;
}
```

这是需要加一个新功能, 在不重启系统的情况下热更配置, 那么可以定义一个 `Scheduler`, 以及 `Hofixer`, `Schedule` 周期性地调用 `Hotfixer`:

```java
public class RabbitConfig implements Hotfixer {
    private String host;
    private String port;

    @Override
    public void update() {
        System.out.println("Update RabbitConfig");
    }
}

public class RedisConfig implements Hotfixer {
    private String host;
    private String port;

    @Override
    public void update() {
        System.out.println("Update RedisConfig");
    }
}

public class HotfixerScheduler {

    public ScheduledExecutorService scheduledExecutorService;
    public Hotfixer hotfixer;
    public long initDelay;
    public long period;
    public volatile boolean destroyed = false;

    public HotfixerScheduler(Hotfixer hotfixer, long initDelay, long period) {
        this.hotfixer = hotfixer;
        this.initDelay = initDelay;
        this.period = period;
        init();
    }

    private void init() {
        scheduledExecutorService = Executors.newSingleThreadScheduledExecutor();
    }

    public void runHotfix() {
        scheduledExecutorService.scheduleAtFixedRate(() -> hotfixer.update(), initDelay, period, TimeUnit.MILLISECONDS);
    }

    public void shutdown() {
        if (destroyed) {
            return;
        }
        scheduledExecutorService.shutdown();
        destroyed = true;
    }
    
}
```

```java
public static void main(String[] args) {
    Hotfixer hotfixer = new RabbitConfig("127.0.0.1", "6379");
    HotfixerScheduler hotfixerScheduler = new HotfixerScheduler(hotfixer, 100L, 100L);
    hotfixerScheduler.runHotfix();
}
```

上面简单实现了热更的功能, 这时候又来了个新需求, 提供一个接口查看 Redis 的配置, 但是又不能暴露 Rabbit 的配置, 将上面代码稍加改造:

```java
public interface Viewer {
    String outputJson();
}

public class RedisConfig implements Hotfixer, Viewer {
    private String host;
    private String port;

    public RedisConfig(String host, String port) {
        this.host = host;
        this.port = port;
    }

    @Override
    public void update() {
        System.out.println("Update RedisConfig");
    }

    public String getHost() {
        return host;
    }

    public String getPort() {
        return port;
    }

    @Override
    public String outputJson() {
        return JSONObject.toJSONString(this);
    }
}

public class SimpleHttpServer extends AbstractVerticle {

    private final Map<String, Consumer<RoutingContext>> map = new HashMap<>(16);
    private int port;

    public SimpleHttpServer(int port) {
        this.port = port;
    }

    @Override
    public void start() {
        Router router = Router.router(vertx);
        router.route("/:path").handler(this::handlePath);

        HttpServer httpServer = vertx.createHttpServer();
        httpServer.requestHandler(router).listen(port, listenResult -> {
            if (listenResult.failed()) {
                System.out.println("Could not start HTTP server");
                listenResult.cause().printStackTrace();
            } else {
                System.out.println("Server started");
            }
        });
    }

    private void handlePath(RoutingContext ctx) {
        String path = ctx.pathParam("path");
        Consumer<RoutingContext> consumer = map.get(path);
        if (consumer == null) {
            ctx.response().setStatusCode(404).end("Not Found");
            return;
        }
        consumer.accept(ctx);
    }

    public void regist(String path, Viewer viewer) {
        map.put(path, ctx -> out(ctx, viewer.outputJson()));
    }


    private void out(RoutingContext ctx, String msg) {
        ctx.response()
           .putHeader("Content-Type", "text/plain; charset=utf-8")
           .end(msg);
    }

    public void close() {
        vertx.close();
    }
}
```

```java
public static void main(String[] args) {
    Viewer redisViewer = new RedisConfig("127.0.0.1", "6379");
    SimpleHttpServer httpServer = new SimpleHttpServer(8080);
    httpServer.regist("redis", redisViewer);
    Vertx.vertx().deployVerticle(httpServer);
}
```

这样就简单实现了配置查看的功能, `SimpleHttpServer` 只依赖了 `Viewer` 接口, 没有依赖 `Hotfixer`, 大家各司其职, 这符合接口隔离原则.

加入定义一个大而全的接口, 那么其他实现类就多了很多没必要的代码, 影响可读性.

### 依赖倒置原则(DIP)

> High-level modules shouldn’t depend on low-level modules. Both modules should depend on abstractions. In addition, abstractions shouldn’t depend on details. Details depend on abstractions.

依赖倒置原则(`Dependency Inversion Principle`,DIP): 抽象不应该依赖细节, 细节应该依赖于抽象. 即应该**针对接口编程**, 而不是针对实现编程. 

看起来这个原则跟多态类似, 但实际上, 多态是 JAVA 语言的特性, DIP 是指导思想. 而且 DIP 强调的是 **Design By Contract**, 即契约编程. 这个契约包括函数的功能定义, 入参出参以及异常输出等行为, 子类替换了父类不能改变这些行为.

先来捋清一些概念, **IOC**(Inversion Of Control, 控制反转), 这里先不要跟 Spring IoC 联想在一起.

```java
public class BeforeIoc {
    public void doTest() {
        if (test()) {
            System.out.println("doTest");
        } else {
            System.out.println("No doTest");
        }
    }

    private boolean test() {
        return false;
    }

    public static void main(String[] args) {
        BeforeIoc beforeIoc = new BeforeIoc();
        beforeIoc.doTest();
    }
}
```

上面的所有方法由程序员控制, 下面来修改一下:

```java
public abstract class AfterIoc {
    public void doTest() {
        if (test()) {
            System.out.println("doTest");
        } else {
            System.out.println("No doTest");
        }
    }

    protected abstract boolean test();

    static class MyAfterIoc extends AfterIoc {

        @Override
        protected boolean test() {
            return false;
        }
    }

    static class IocRunner {
        private List<AfterIoc> iocList = new ArrayList<>();

        public void registerIoc(AfterIoc afterIoc) {
            iocList.add(afterIoc);
        }

        public void run() {
            iocList.forEach(AfterIoc::doTest);
        }
    }

    public static void main(String[] args) {
        IocRunner iocRunner = new IocRunner();
        iocRunner.registerIoc(new MyAfterIoc());
        iocRunner.run();
    }
}
```

将主流程抽出来, 留下一个 `test` 扩展点, 调用者将自己的业务写在扩展点中, 剩下的交给框架, 这样就完成了流程的控制从程序员反转到了框架.

所以, 控制反转并不是一种具体的实现技巧, 而是一个比较笼统的设计思想, 一般用来指导框架层面的设计.

接下来是 **DI**(Dependency Injection, 依赖注入) 与 **DI Framewaork**.

```java
public class DiDemo {

    public final NameSupplier nameSupplier;

    public DiDemo(NameSupplier nameSupplier) {
        this.nameSupplier = nameSupplier;
    }

    public void printName() {
        System.out.println(nameSupplier.getName());
    }

    interface NameSupplier {
        String getName();
    }

    static class MyNameSupplier implements NameSupplier {

        @Override
        public String getName() {
            return "yangbingdong";
        }
    }

    public static void main(String[] args) {
        NameSupplier nameSupplier = new MyNameSupplier();
        DiDemo diDemo = new DiDemo(nameSupplier);
        diDemo.printName();
    }
}
```

通过构造器等方式将构建好的对象传递进来, 可以灵活地替换实现类, 提高了代码的灵活度, 这就是依赖注入.

而依赖注入框架则是像 Spring, Google Guice 等提供了依赖注入功能的框架.

DIP 其实与控制反转类似, 是指导框架层面的设计, 只不过 DIP 更为抽象一点.

### KISS原则与YAGNI原则

KISS原则: Keep It Simple and Stupid.

如何写出 KISS 原则的代码:

1. 不要使用一些同事看不懂的代码
2. 不要重复造轮子, 尽量复用工具类
3. 不要过度优化

还有一点, 如果在 code review 的时候, 大部分同时都看不懂, 那么也许写的代码不满足 KISS 原则.

YAGNI 原则: You Ain’t Gonna Need It. 你不会需要它. 总结来讲就是目前不要过度设计, 比如不要设计不需要的接口, 不要依赖不需要的依赖等.

### 迪米特法则(LOD)

迪米特法则(`Law of Demeter`,LOD): 一个软件实体应当尽可能少地与其它实体发生相互作用. 

迪米特法则又称为**最少知识原则**(`LeastKnowledge Principle`,LIP). 
如果一个系统符合迪米特法则, 那么当其中某一个模块发生修改时, 就会尽量少地影响其他模块, 扩展会相对容易, 这是对软件实体之间通信的限制, 迪米特法则要求限制软件实体之间通信的宽度和深度. 迪米特法则可降低系统的耦合度, 使类与类之间保持松散的耦合关系. 

## 三大类型
### [创建型(Creational)](/2018/design-pattern-creational)
- **单例模式**(`Singleton`): 保证一个类仅有一个实例, 并提供一个访问它的全局访问点. 

- **工厂方法**(`Factory Method`): 定义一个创建对象的接口, 让其子类自己决定实例化哪一个工厂类, 工厂模式使其创建过程延迟到子类进行. 

- **抽象工厂**(`Abstract Factory`): 提供一个创建一系列相关或相互依赖对象的接口, 而无需指定它们具体的类. 

- **建造者模式**(`Builder`): 将一个复杂对象的构建与它的表示分离, 使得同样的构建过程可以创建不同的表示. 

- **原型模式**(`Prototype`): 用原型实例指定创建对象的种类, 并且通过拷贝这些原型来创建新的对象. 


### 结构型(Structural)
- **适配器模式**(`Adapter`): 适配器模式把一个类的接口变换成客户端所期待的另一种接口, 从而使原本因接口不匹配而无法在一起工作的两个类能够在一起工作. 

- **装饰模式**(`Decrator`): 装饰模式是在不必改变原类文件和使用继承的情况下, 动态的扩展一个对象的功能. 它是通过创建一个包装对象, 也就是装饰来包裹真实的对象. 

- **代理模式(**`Proxy`): 为其他对象提供一种代理以控制对这个对象的访问 ；

- **外观模式**(`Facade`): 为子系统中的一组接口提供一个一致的界面, 外观模式定义了一个高层接口, 这个接口使得这一子系统更加容易使用. 

- **桥接模式**(`Bridge`): 将抽象部分与实现部分分离, 使它们都可以独立的变化. 

- **组合模式**(`Composite`): 允许你将对象组合成树形结构来表现"整体-部分"层次结构. 组合能让客户以一致的方法处理个别对象以及组合对象. 

- **享元模式**(`Flyweight`): 运用共享技术有效地支持大量细粒度的对象. 


### 行为型(Behavioral)
- **策略模式**(`Strategy`): 定义一组算法, 将每个算法都封装起来, 并且使他们之间可以互换. 

- **模板方法**(`Template Method`): 一个操作中算法的框架, 而将一些步骤延迟到子类中, 使得子类可以不改变算法的结构即可重定义该算法中的某些特定步骤. 

- **观察者模式**(`Observer`): 定义对象间的一种一对多的依赖关系, 当一个对象的状态发生改变时, 所有依赖于它的对象都得到通知并被自动更新. 

- **迭代器模式**(`Iterator`): 提供一种方法顺序访问一个聚合对象中各个元素, 而又无须暴露该对象的内部表示；

- **职责链模式**(`Chain of Responsibility`): 避免请求发送者与接收者耦合在一起, 让多个对象都有可能接收请求, 将这些对象连接成一条链, 并且沿着这条链传递请求, 直到有对象处理它为止. 

- **命令模式**(`Command`): 将一个请求封装为一个对象, 从而使你可以用不同的请求对客户进行参数化, 对请求排队和记录请求日志, 以及支持可撤销的操作；

- **备忘录模式**(`Memento`): 在不破坏封装性的前提下, 捕获一个对象的内部状态, 并在该对象之外保存这个状态. 这样就可以将该对象恢复到原先保存的状态. 

- **状态模式**(`State`): 允许对象在内部状态改变时改变它的行为, 对象看起来好像修改了它的类. 

- **访问者模式**(`Visitor`): 表示一个作用于其对象结构中的各元素的操作, 它使你可以在不改变各元素类的前提下定义作用于这些元素的新操作. 

- **中介者模式**(`Mediator`): 用一个中介对象来封装一系列的对象交互, 中介者使各对象不需要显示地相互引用. 从而使其耦合松散, 而且可以独立地改变它们之间的交互. 

- **解释器模式**(`Interpreter`): 给定一个语言, 定义它的文法表示, 并定义一个解释器, 这个解释器使用该标识来解释语言中的句子. 



## 四大阶段

　　1, 没学之前, 什么是设计模式, 老听别人说设计模式, 感觉好高大上, 那它到底是什么鬼. 这时我们设计的代码复用性很差, 难以维护. 

　　2, 学了几个模式后, 感觉很简单, 于是到处想着要用自己学过的模式, 这样就会造成滥用. 最后感觉还不如不用. 

　　3, 学完全部模式时, 感觉很多模式太相似了, 无法很清晰的知道各模式之间的区别, 联系, 这时一脸懵逼, 脑子一团乱麻. 在使用时, 分不清要使用那种模式. 

　　4, 模式已熟记于心, 已忘其形, 深知其意, 达到无剑胜有剑的境界, 恭喜你, 万剑归宗已练成！！！

## 设计模式参考

***[https://java-design-patterns.com/](https://java-design-patterns.com/)***

# UML

UML中有九种建模的图标, 即: 
**用例图**, **类图**, **对象图**, **顺序图**, **协作图**, **状态图**, **活动图**, **组件图**, **配置图**


## Class Diagram
在这主要学习一下**类图 Class diagram **. 
通过显示出系统的类以及这些类之间的关系来表示系统. 类图是静态的———它们显示出什么可以产生影响但不会告诉你什么时候产生影响. 

UML类的符号是一个被划分成三块的方框: 类名, 属性, 和操作. 抽象类的名字, 是斜体的. 类之间的关系是连接线. 


## 类与类的关系

- **泛化**: 可以简单的理解为继承关系；
- **实现**: 一般是接口和实现类之间的关系；
- **关联**: 一种拥有关系, 比如老师类中有学生列表, 那么老师类和学生类就是拥有关系；
- **聚合**: 整体与部分的关系, 但是整体和部分是可以分离而独立存在的, 如汽车类和轮胎类；
- **组合**: 整体与部分的关系, 但是二者不可分离, 分离了就没有意义了, 例如, 公司类和部门类, 没有公司就没有部门；
- **依赖**: 一种使用关系, 例如创建 A 类必须要有 B 类. 

![](https://oldcdn.yangbingdong.com/img/design-pattern-uml-and-six-principle/uml-relation.png)

这是一个类图的记忆方法: ***[https://mp.weixin.qq.com/s/yfp5ejzm4kHW44kU876SYQ](https://mp.weixin.qq.com/s/yfp5ejzm4kHW44kU876SYQ)***

## StarUML

*[StarUML](http://staruml.io/)*...就是一个画UML的很炫酷的工具=.=

### 显示interface
在staruml中, interface默认是以一个圆圈显示的(尴尬了)..., 但好在可以设置成想要的样子. 

1. 添加一个圆圈(interface)之后, 右键或选择菜单栏中的Format
2. 选择Stereotype Display -> Label, 这样矩形就显示出来了
3. 同样是Format, 然后把Suppress Operations取消掉, 这样操作就可以显示出来了

![](https://oldcdn.yangbingdong.com/img/learning-uml-and-using-staruml/interface-01.png)

![](https://oldcdn.yangbingdong.com/img/learning-uml-and-using-staruml/interface-02.png)

## Gliffy
*[Gliffy](https://www.gliffy.com/)*是一个*[在线](https://go.gliffy.com/go/html5/launch)*绘图工具, 支持Chrome插件, 非常强大. 

![](https://oldcdn.yangbingdong.com/img/design-pattern-uml-and-six-principle/gliffy.png)