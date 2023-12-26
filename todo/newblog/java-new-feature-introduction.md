# 现代 Java 新特新

![](https://image.cdn.yangbingdong.com/image/java-new-feature-introduction/4588529f5a4e87b6bd960b74d97c6f96-180272.png)

# 前言

Java 8 自  **2014 年 3 月18 日**发布至今(2023), 这么多年过去了依然是国内使用最广泛的 JDK 版本, 正所谓 "**他发任他发, 我用 Java 8**", 突出一个**稳**字啊! 先来康一康 [***Java SE RoadMap***](https://www.oracle.com/java/technologies/java-se-support-roadmap.html):

![](https://image.cdn.yangbingdong.com/image/java-new-feature-introduction/a73b4fe2afccf8f74622b7b628b99ae2-9489c1.png)

Java 8 之后的10年里 Oracle 先后发布了13个版本, 其中3个 LTS 版本, 从里面的 [***Release***](https://en.wikipedia.org/wiki/Java_version_history#Future_features) 的功能可以看出来 Java 一直紧跟时代, 变化非常大, 总的来说就是迈向更轻(体积), 更快(性能), 更小(内存占用). 作为一个有灵魂码农, 也不能落后, 可以不用, 但不能不了解.

> 关于 Java 8 的介绍可以看我的老文章: [***Java8 Noob Tutorial***](https://yangbingdong.com/2017/java-8-tutorial/)

# Java 9 - 11

## Java 9

**主要语言变化**

**新增**

- 模块化系统(Module System):  [***JSR 376***](http://openjdk.java.net/projects/jigsaw/spec/)
  - [***Project Jigsaw***](https://openjdk.org/projects/jigsaw/) 的一部分
  - 按需加载, 解决臃肿
  - ` module-info.java `
    - 通过 `exports`, `requires` 关键字声明作用域(感觉像 nodejs?)
- 新版本定义机制: `$MAJOR.$MINOR.$SECURITY.$PATCH`

**更新**

- `try-with-resources` 语法允许变量使用 final 修饰, 语法升级
- `diamond` 语法允许匿名类(如果类型推断的参数类型可表示的话)
- 接口允许定义 `private` 方法
- `@SafeVarargs` 允许声明在实例 private 方法上

**主要 API 变化**

**引入**

- 进程(Process): [***JEP 102***](https://openjdk.org/jeps/102), 全新 API `ProcessHandle` 提供更好的管控操作系统
- 内存(Memory): [***JEP 193***](https://openjdk.org/jeps/193), `VarHandle` 作为正式 API 替代 `Unsafe`, 对变量执行原子和内存屏障操作
- 日志(Logging): [***JEP 264***](https://openjdk.org/jeps/264), 全新日志 API 和服务
  - 现在基本都用 Slf4j 了吧...
- XML: [***JEP 268***](https://openjdk.org/jeps/268), 添加标准的 XML Catalog API
- 栈(Stack): [***JEP 259***](https://openjdk.org/jeps/259), 全新栈跟踪工具, `StackWalker` 替代老的 `StackTraceElement` 体系

**更新**

- 字符串(String): [***JEP 254***](https://openjdk.org/jeps/254), String **底层存储**从 `char[]` 替换为 `byte[]`
  - 内存优化, 时间换空间
- 集合(Collections): [***JEP 269***](https://openjdk.org/jeps/269), **集合接口提供便利的工厂方法**, 如, `Set.of(...)`
- 并发(Concurrency): [***JEP 266***](https://openjdk.org/jeps/266), `CompletableFuture` 以及其他并发组件提升
  - Reactive Streams:  `java.util.concurrent.Flow`
- 编译器(Compiler): [***JEP 274***](https://openjdk.org/jeps/274), 提升 `MethodHandle` 通用性以及更好地编译优化
  - `MethodHandle` 以及其他反射方式性能对比: [***Java Reflection, but Faster***](https://dzone.com/articles/java-reflection-but-faster)
- 注解(Annotation): [***JEP 277***](https://openjdk.org/jeps/277), `@Deprecated` 注解增加 `since` 和 `forRemoval` 属性, 丰富 API 淘汰策略
- 线程(Threading): [***JEP 285***](https://openjdk.org/jeps/285), 新增自选方法 `Thread.onSpinWait`
- 对象序列化(Serialization): [***JEP 290***](https://openjdk.org/jeps/290), 新增 API `ObjectInputFilter` 过滤 `ObjectInputStream`
- XML: [***JEP 255***](https://openjdk.org/jeps/255), 更新 Xerces 2.11.0 解析 XML
- Java Management Extensions (JMX): 支持远程诊断命令
- 脚本(Scripting): 
  - [***JEP 236***](https://openjdk.org/jeps/236), Nashorn 解析器 API 引入
  - [***JEP 292***](https://openjdk.org/jeps/292), 实现 ECMAScript 6 功能
- 国际化(Internationalization): 
  - [***JEP 267***](https://openjdk.org/jeps/267), 支持 Unicode 8.0
  - [***JEP 252***](https://openjdk.org/jeps/252), JDK 8 引入的 XML 形式的 Common Locale Data Repository (CLDR) 作为默认选项
  - [***JEP 226***](https://openjdk.org/jeps/226), 支持 UTF-8 Properties 文件
- Java Database Connectivity (JDBC): 
  - JDBC-ODBC 桥接移除
  - JDBC 4.2 升级

**主要 JVM 变化**

**新增**

- String **压缩**: [***JEP 254: Compact Strings***](https://openjdk.org/jeps/254)
- [***JEP 295: Ahead-of-Time Compilation***](https://openjdk.org/jeps/295)

**更新**

- 垃圾回收(Garbage Collection)
  - 移除组合: 
    - 并发标记和清扫(Concurrent Mark Sweep Collector) CMS: [***JEP 291***](https://openjdk.org/jeps/291)
    - DefNew + CMS
    - ParNew + SerialOld
    - Incremental CMS
  - Garbage-First(**G1**): [***JEP 248: Make G1 the Default Garbage Collector***](https://openjdk.org/jeps/248)
    - 提升可读性和性能优化
    - 标记为**默认 GC**
- 统一 JVM 日志: [***JEP 158***](https://openjdk.org/jeps/158)
- 输入/输出(I/O): 
  - **减少** `<JDK_HOME>/jre/lib/charsets.ja`r **文件大小**
- 性能提升(Performance)
  - `java.lang.String` **字节数组**性能优化
- 工具(Tools)
  - Java Plug-in 标记为不推荐使用, 未来版本移除
  - ***[jshell](https://en.wikipedia.org/wiki/JShell)***: [***JEP 222***](https://openjdk.org/jeps/222), 增加 Read-Eval-Print Loop
  - jcmd: [***JEP 228***](https://openjdk.org/jeps/228), 增加更多诊断命令
  - jlink: [***JEP 282***](https://openjdk.org/jeps/282), 组装和优化模块以及依赖
  - 多版本发布 JAR 文件: [***JEP 238***](https://openjdk.org/jeps/238)
  - 移除指定版本 JRE 启动
  - 移除 HProf Agent: [***JEP 240***](https://openjdk.org/jeps/240)

## Java 10

**主要语言变化**

**新增**

- 本地变量类型推断: [***JEP 286: Local-Variable Type Inference***](https://openjdk.org/jeps/286)
  - 用 var 来声明变量, 相关阅读:  [***Java 10 新特性之局部变量类型推断***](https://zhuanlan.zhihu.com/p/34911982)

**主要 API 变化**

**更新**

- 通用: Optional 新增方法
  -  `orElseThrow()`方法来在没有值时抛出指定的异常
- 集合增强
  -  `List`, `Set`, `Map` 提供了静态方法`copyOf()`返回入参集合的一个不可变拷贝
-  `java.util.stream.Collectors` 中新增了静态方法, 用于将流中的元素收集为不可变的集合
- `Collectors.toUnmodifiableList()`, `Collectors.toUnmodifiableSet()`
- 安全(Security): 
  - [***JEP 319***](https://openjdk.org/jeps/319), 默认根证书

**主要 JVM 变化**

**新增**

- **JIT Compiler**: [***JEP 317***](https://openjdk.org/jeps/317) 实验性的 Java 编写的 JIT Compiler,  Graal
  -  相关阅读: [***深入浅出 Java 10 的实验性 JIT 编译器 Graal***](https://www.infoq.cn/article/java-10-jit-compiler-graal)

**更新**

- 垃圾回收(Garbage Collection)
  - Garbage-First(**G1**): **并行 Full GC** 支持
  - [***JEP 304***](https://openjdk.org/jeps/304): Garbage Collector Interface
- 内存(Memory): 运行 JVM Heap 在用户可选的设备上分配, 如: NV-DIMM
- 应用层级的 CDS: [***JEP 310: Application Class-Data Sharing***](https://openjdk.org/jeps/310)
- 线程(Threading): [***JEP 312 Thread-Local Handshakes***](https://openjdk.org/jeps/304)
- 工具(Tools)
  - javah: [***JEP 313***](https://openjdk.org/jeps/313) 被移除
- 国际化(Internationalization): 增加 Unicode 语言 Tag 扩展
- 版本发布:  [***JEP 322***](https://openjdk.org/jeps/322), 基于时间发布版本信息

## Java 11(LTS)

**主要语言变化**

**新增**

- 字节码(Byte-code): 
  - 基于嵌套类型访问控制(***[JEP 181: Nest-Based Access Control](https://openjdk.org/jeps/181)***)
  - 新增常量池形式: CONSTANT_Dynamic(***[JEP 309: Dynamic Class-File Constants](https://openjdk.java.net/jeps/309)***)
- Lambda 参数局部变量语句: ***[JEP 323: Local-Variable Syntax for Lambda Parameters](https://openjdk.java.net/jeps/323)***
  - 可以在 Lambda 表达式中使用 var

**主要 API 变化**

**引入**

- HTTP: 新增 HTTP 客户端(***[JEP 321: HTTP Client (Standard)](https://openjdk.java.net/jeps/321)***)

**更新**

- Optional 增强
  -  新增了`isEmpty()`方法来判断指定的 `Optional` 对象是否为空
- String 增强
  - 新增了 `isBlank`, `strip`, `repeat`, `lines`等方法
- 国际化(Internationalization): 
  - Unicode 10 支持(***[JEP 327: Unicode 10](https://openjdk.java.net/jeps/327)***)
- 安全(Security): 
  - 与 Curve25519 和 Curve448 的关键协议(***[JEP 324: Key Agreement with Curve25519 and Curve448](https://openjdk.java.net/jeps/324)***)
  - Chacha20 和 Poly1305 加密算法(***[JEP 329: ChaCha20 and Poly1305 Cryptographic Algorithms](https://openjdk.java.net/jeps/329)***)
  - TLS 1.3 支持(***[JEP 332: Transport Layer Security (TLS) 1.3](https://openjdk.java.net/jeps/332)***)
- 移除 Java EE 和 CORBA 模块([***JEP 320: Remove the Java EE and CORBA Modules***](https://openjdk.org/jeps/320))
  - java.xml.ws (JAX-WS, SAAJ and Web Services Metadata)
  - java.xml.bind (JAXB)
  - java.activation (JAF)
  - java.xml.ws.annotation (Common Annotations)
  - java.corba (CORBA)
  - java.transaction (JTA)

**主要 JVM 变化**

**新增**

- **JIT Compiler**: [***JEP 317***](https://openjdk.java.net/jeps/317) 实验性的 Java 编写的 JIT Compiler
- 垃圾回收(Garbage Collection)
  - 无操作 GC([***JEP 318: Epsilon: A No-Op Garbage Collector***](https://openjdk.java.net/jeps/318))
    - 用途: 性能测试
  - 实验性地引入 **ZGC**([***JEP 333: ZGC: A Scalable Low-Latency Garbage Collector (Experimental***)](https://openjdk.java.net/jeps/333))
    - [***新一代垃圾回收器ZGC的探索与实践***](https://tech.meituan.com/2020/08/06/new-zgc-practice-in-meituan.html)
- 工具
  - Java Fight Recorder([***JEP 328: Flight Recorder***](https://openjdk.java.net/jeps/328))
  - java 命令直接启动单个 Java 源文件([***JEP 330: Launch Single-File Source-Code Programs***](https://openjdk.java.net/jeps/330))
    - `java helloword.java`
    - 类**脚本**, 无需预先编译, 直接运行, 比如写个简单的爬虫
  - 低消耗 JVM Heap Profiling([***JEP 331: Low-Overhead Heap Profiling***](https://openjdk.java.net/jeps/331))

**更新**

- 内存(Memory): 运行 JVM Heap 在用户可选的设备上分配, 如: NV-DIMM
- 应用层级的 CDS: JEP 310
  - **Class-Data Sharing**
- 工具(Tools)
  - 不推荐 JavaScript 引擎 Nashorn([***JEP 335: Deprecate the Nashorn JavaScript Engine***](https://openjdk.java.net/jeps/335))
  - 不推荐 Pack200 工具([***JEP 336: Deprecate the Pack200 Tools and API***](https://openjdk.java.net/jeps/336))
- GUI: 
  - 移除 Java Applet
  - 移除 Java Web Start
  - 移除 JavaFX
- 指令: 提升 Aarch64 内联函数([***JEP 315: Improve Aarch64 Intrinsics***](https://openjdk.java.net/jeps/315))

# Java 12 - 17

## Java 12

**主要语言变化**

**新增**

- **[预览] Switch 语句优化**([***JEP 325: Switch Expressions (Preview)***](https://openjdk.java.net/jeps/325))

**主要 API 变化**

* `String` 新增了 `indent` 方法处理缩进
* `Files` 新增了 `mismatch` 来对比两个文件
*  `NumberFormat` 新增了对复杂的数字进行格式化的支持: `getCompactNumberInstance`

**主要 JVM 变化**

**新增**

- 单一 AArch64 端口([***JEP 340: One AArch64 Port, Not Two***](https://openjdk.java.net/jeps/340))
- 默认 CDS 归档([***JEP 341: Default CDS Archives***](https://openjdk.java.net/jeps/341))
- 垃圾回收(Garbage Collection)
  - [实验性] Shenandoah GC([***JEP 189: Shenandoah: A Low-Pause-Time Garbage Collector (Experimental***)](https://openjdk.java.net/jeps/189))
- Microbenchmark 套件([***JEP 230: Microbenchmark Suite***](https://openjdk.java.net/jeps/230))

**更新**

- 垃圾回收(Garbage Collection)
  - Garbage First(G1)
    - 可中断混合收集([***JEP 344: Abortable Mixed Collections for G1***](https://openjdk.java.net/jeps/344))
    - **返回未提交内存**([***JEP 346: Promptly Return Unused Committed Memory from G1***](https://openjdk.java.net/jeps/346))

## Java 13

**主要语言变化**

**新增**

- [预览] Switch 语句优化更新([***JEP 354: Switch Expressions (Preview)***](https://openjdk.java.net/jeps/354))
  - 新增 `yield` 关键字
- [预览] **文件块**([***JEP 355: Text Blocks (Preview)***](https://openjdk.java.net/jeps/355))

**主要 API 变化**

**更新**

- 网络(Network): 重新实现 Socket API([***JEP 353: Reimplement the Legacy Socket API***](https://openjdk.java.net/jeps/353))
  - 虚拟线程铺垫

**主要 JVM 变化**

**更新**

- 垃圾回收(Garbage Collection)
  - ZGC
    - 返回未提交内存([***JEP 351: ZGC: Uncommit Unused Memory***](https://openjdk.java.net/jeps/351))

## Java 14

**主要语言变化**

**新增**

- [预览] **instanceof 语句优化**([***JEP 305: Pattern Matching for instanceof (Preview)***](https://openjdk.java.net/jeps/305))
  - 在 `instanceof` 块中转换变量
- [预览] 文件块更新,  引入了两个新的转义字符 ([***JEP 368: Text Blocks (Second Preview)***](https://openjdk.java.net/jeps/368))
  - `\` : 表示行尾, 不引入换行符
  - `\s`: 表示单个空格
- [预览] **Record 类型**([***JEP 359: Records (Preview)***](https://openjdk.java.net/jeps/359))
  -   Immutable data
  -   `record Person(String name, Long id){}`
- **Switch 语句优化(转正)**([***JEP 361: Switch Expressions (Standard)***](https://openjdk.java.net/jeps/361))

**主要 API 变化**

**引入**

- [孵化] 外部内存访问 API([***JEP 370: Foreign-Memory Access API (Incubator)***](https://openjdk.java.net/jeps/370))

**主要 JVM 变化**

**更新**

- 非 volatile 内存 ByteBuffer 映射([***JEP 352: Non-Volatile Mapped Byte Buffers***](https://openjdk.java.net/jeps/352))
- 空指针异常内容辅助([***JEP 358: Helpful NullPointerExceptions***](https://openjdk.java.net/jeps/358))
  - 补充异常信息, 比如: `Cannot read field 'c' because 'a.b' is null.`
- 垃圾回收(Garbage Collection)
  - ZGC
    - 支持 macOS([***JEP 364: ZGC on macOS***](https://openjdk.java.net/jeps/364))
    - 支持 Windows([***JEP 365: ZGC on Windows***](https://openjdk.java.net/jeps/365))
  - CMS
    - 移除([***JEP 363: Remove the Concurrent Mark Sweep (CMS) Garbage Collector***](https://openjdk.java.net/jeps/363))
  - Garbage First(G1)
    - NUMA 架构内存分配([***JEP 345: NUMA-Aware Memory Allocation for G1***](https://openjdk.java.net/jeps/345))
- 工具
  - JFR 流([***JEP 349: JFR Event Streaming***](https://openjdk.java.net/jeps/349))
  - [孵化] 打包工具([***JEP 343: Packaging Tool (Incubator)***](https://openjdk.java.net/jeps/343))
  - 移除 Pack200([***JEP 367: Remove the Pack200 Tools and API***](https://openjdk.java.net/jeps/367))

## Java 15

**主要语言变化**

**引入**

- **文本块**([***JEP 378: Text Blocks***](https://openjdk.java.net/jeps/378))
- 隐藏类([***JEP 371: Hidden Classes***](https://openjdk.java.net/jeps/371))
  -  为框架(frameworks)所设计的, 隐藏类不能直接被其他类的字节码使用, 只能在运行时生成类并通过反射间接使用它们

**更新**

- [预览] Sealed 类([***JEP 360: Sealed Classes (Preview)***](https://openjdk.java.net/jeps/360))
  - 解决被 `final` 修饰的类不能被继承的尴尬
- [预览] instanceof 语句优化([***JEP 375: Pattern Matching for instanceof (Second Preview)***](https://openjdk.java.net/jeps/375))
- [预览] Record 类型([***JEP 384: Records (Second Preview)***](https://openjdk.java.net/jeps/384))

**主要 API 变化**

**引入**

- [孵化] 外部内存访问 API([***JEP 383: Foreign-Memory Access API (Second Incubator)***](https://openjdk.java.net/jeps/383))

**更新**

- 网络(Network): 重新实现 Socket API([***JEP 353: Reimplement the Legacy Socket API***](https://openjdk.java.net/jeps/353))
- Remote Method Invocation(RMI): [***JEP 385: Deprecate RMI Activation for Removal***](https://openjdk.java.net/jeps/385)

**主要 JVM 变化**

**更新**

- 移除 Solaris 和 SPARC JVM 实现([***JEP 381: Remove the Solaris and SPARC Ports***](https://openjdk.java.net/jeps/381))
- 线程(Threading)
  - 失效和不推荐使用偏向锁([***JEP 374: Disable and Deprecate Biased Locking***](https://openjdk.java.net/jeps/374))
    -  偏向锁的引入增加了 JVM 的复杂性大于其带来的性能提升
- 垃圾回收(Garbage Collection)
  - ZGC
    - 正式发布([***JEP 377: ZGC: A Scalable Low-Latency Garbage Collector***](https://openjdk.java.net/jeps/377))
  - Shenandoah
    - 正式发布([***JEP 379: Shenandoah: A Low-Pause-Time Garbage Collector***](https://openjdk.java.net/jeps/379))
- 工具
  - 移除 Nashorn JavaScript 引擎([***JEP 372: Remove the Nashorn JavaScript Engine***](https://openjdk.java.net/jeps/372))
- 安全(Security): 
  - [***JEP 339: Edwards-Curve Digital Signature Algorithm (EdDSA)***](https://openjdk.java.net/jeps/339)

## Java 16

**主要语言变化**

**引入**

- Record 类型正式引入([***JEP 395: Records***](https://openjdk.java.net/jeps/395))
- instanceof 语句优化正式引入([***JEP 394: Pattern Matching for instanceof***](https://openjdk.java.net/jeps/394))
- 包装类警告([***JEP 390: Warnings for Value-Based Classes***](https://openjdk.java.net/jeps/390))

**更新**

- Stream 新增 `toList()` 方法, 直接可转换成不可变的 List 
  - `list.stream().toList()`
- 模块化(Modular): JDK 内部 API 默认强封装([***JEP 396: Strongly Encapsulate JDK Internals by Default***](https://openjdk.java.net/jeps/396))
- [孵化] 向量 API([***JEP 338: Vector API (Incubator)***](https://openjdk.java.net/jeps/338))
  -   API 将使开发人员能够轻松地用 Java 编写可移植的高性能向量算法
- [预览] Sealed 类([***JEP 397: Sealed Classes (Second Preview)***](https://openjdk.java.net/jeps/397))

**引入**

- 网络(Network): 
  - Unix-Domain Socket([***JEP 380: Unix-Domain Socket Channels***](https://openjdk.java.net/jeps/380))
- Native: 
  - [孵化] 替代 JNI Java API: [***JEP 389: Foreign Linker API (Incubator)***](https://openjdk.java.net/jeps/389)
- [孵化] 外部内存访问 API([***JEP 393: Foreign-Memory Access API (Third Incubator)***](https://openjdk.java.net/jeps/393))
  - 通用: 单个 API 应该能够对各种外部内存(如本机内存、持久内存、堆内存等)进行操作. 
  - 安全: 无论操作何种内存, API 都不应该破坏 JVM 的安全性. 
  - 控制: 可以自由的选择如何释放内存(显式、隐式等). 
  - 可用: 如果需要访问外部内存, API 应该是 `sun.misc.Unsafe`.

**主要 JVM 变化**

**引入**

- 源码(SourceCode): 
  - 激活 C++ 14 特性([***JEP 347: Enable C++14 Language Features***](https://openjdk.java.net/jeps/347))
  - 迁移到 Git 上([***JEP 357: Migrate from Mercurial to Git***](https://openjdk.java.net/jeps/357))
    -  在此之前, OpenJDK 源代码是使用版本管理工具 Mercurial 进行管理, 现在迁移到了 Git
  - Alpine Linux 实现([***JEP 386: Alpine Linux Port***](https://openjdk.java.net/jeps/386))
  - Windows/AArch64 实现([***JEP 388: Windows/AArch64 Port***](https://openjdk.java.net/jeps/388))

**更新**

- 垃圾回收(Garbage Collection)
  - ZGC
    - 并发线程栈处理([***JEP 376: ZGC: Concurrent Thread-Stack Processing***](https://openjdk.java.net/jeps/376))
- 工具(Tools)
  - jpackage 容器打包工具([***JEP 392: Packaging Tool***](https://openjdk.java.net/jeps/392))

## Java 17(LTS)

**主要语言变化**

**引入**

- Sealed 类正式引入([***JEP 409: Sealed Classes***](https://openjdk.java.net/jeps/409))
  - `sealed`: 修饰类/接口, 用来描述这个类/接口为密封类/接口
  - `non-sealed`: 修饰类/接口, 用来描述这个类/接口为非密封类/接口
  - `permits`: 用在`extends`和`implements`之后, 指定可以继承或实现的类
- 浮点数: 浮点数默认 `strictfp`([***JEP 306: Restore Always-Strict Floating-Point Semantics***](https://openjdk.java.net/jeps/306))

**更新**

- 模块化(Modular): JDK 内部 API 强封装([***JEP 403: Strongly Encapsulate JDK Internals***](https://openjdk.java.net/jeps/403))
- [预览] Switch 语句增强模式匹配([***JEP 406: Pattern Matching for switch (Preview)***](https://openjdk.java.net/jeps/406))
  - 类似 `instanceof` 的匹配+转换: `case Integer i -> String.format("int %d", i);`
- [孵化] 向量 API([***JEP 414: Vector API (Second Incubator)***](https://openjdk.java.net/jeps/414))

**主要 API 变化**

**引入**

- [孵化] 外部 Native 函数和内存 API([***JEP 412: Foreign Function & Memory API (Incubator)***](https://openjdk.java.net/jeps/412))
- 关联: 
  - [***JEP 424: Foreign Function & Memory API (Preview)***](https://openjdk.java.net/jeps/424)
  - [***JEP 389: Foreign Linker API (Incubator)***](https://openjdk.java.net/jeps/389)
    - [***JEP 393: Foreign-Memory Access API (Third Incubator)***](https://openjdk.java.net/jeps/393)

**更新**

- 工具(Utility): Random 增强([***JEP 356: Enhanced Pseudo-Random Number Generators***](https://openjdk.java.net/jeps/356))
- 安全(Security): 
  - 不推荐 SecurityManager, 未来将移除([***JEP 411: Deprecate the Security Manager for Removal***](https://openjdk.java.net/jeps/411))
- Remote Method Invocation(RMI): 移除 RMI Activation([***JEP 407: Remove RMI Activation***](https://openjdk.java.net/jeps/407))
- 对象序列化(Serialization): 上下文反序列化过滤器([***JEP 415: Context-Specific Deserialization Filters***](https://openjdk.java.net/jeps/415))
- 用户界面(UI): 
  - Applet: 不推荐使用, 未来移除([***JEP 398: Deprecate the Applet API for Removal***](https://openjdk.java.net/jeps/398))

**主要 JVM 变化**

**引入**

- 源码(SourceCode): 
  - macOS/AArch64 支持([***JEP 391: macOS/AArch64 Port***](https://openjdk.java.net/jeps/391))

**更新**

- 工具(Tools): 
  - 移除实验性 AOT 和 JIT 编译器([***JEP 410: Remove the Experimental AOT and JIT Compiler***](https://openjdk.java.net/jeps/410)), 由 **GraalVM** 替代
- 用户界面(UI): 
  - 新 macOS 渲染引擎([***JEP 382: New macOS Rendering Pipeline***](https://openjdk.java.net/jeps/382))

# Java 18 - 21

## Java 18

**主要语言变化**

**更新**

- [孵化] 向量 API [***JEP 417: Vector API (Third Incubator)***](https://openjdk.java.net/jeps/417)
- [预览] `switch`语句模式匹配 [***JEP 420: Pattern Matching for switch (Second Preview)***](https://openjdk.java.net/jeps/420)
- 默认字符集为 UTF-8 [***JEP 400:UTF-8 by Default***](https://openjdk.java.net/jeps/400)

**主要 API 变化**

**更新**

- [孵化] 外部 Native 函数和内存 API [***JEP 419: Foreign Function & Memory API (Second Incubator)***](https://openjdk.java.net/jeps/419)
- 输入/输出(I/O): 
  - UTF-8 作为默认字符 [***JEP 400: UTF-8 by Default***](https://openjdk.java.net/jeps/400)
- 反射(Reflection): 
  - 基于 `MethodHandlers` 重新实现核心反射API [***JEP 416: Reimplement Core Reflection with Method Handles***](https://openjdk.java.net/jeps/416)
- 网络(Network): 
  - 简单 Web Server [***JEP 408: Simple Web Server***](https://openjdk.java.net/jeps/408)
  - IP 地址解析 [***JEP 418: Internet-Address Resolution SPI***](https://openjdk.java.net/jeps/418)

**主要 JVM 变化**

**更新**

- 不推荐 Finalization, 未来删除 [***JEP 421: Deprecate Finalization for Removal***](https://openjdk.java.net/jeps/421)
- 工具(Tools)
  - javadoc: API 文档增加代码片段 [***JEP 413: Code Snippets in Java API Documentation***](https://openjdk.java.net/jeps/413)
    - 使用姿势: `{@snippet : System.out.print("a");}`

## Java 19

**主要语言变化**

**更新**

- [预览] Record 模式([***JEP 405: Record Patterns (Preview)***](https://openjdk.java.net/jeps/405))
- [预览] **虚拟线程**([***JEP 425: Virtual Threads (Preview)***](https://openjdk.java.net/jeps/425))
- [预览] `switch`语句模式匹配([***JEP 427: Pattern Matching for switch (Third Preview)***](https://openjdk.java.net/jeps/427))
- [孵化] 向量 API([***JEP 426: Vector API (Fourth Incubator)***](https://openjdk.java.net/jeps/426))

**主要 API 变化**

**更新**

- [预览] 外部 Native 函数和内存 API([***JEP 424: Foreign Function & Memory API (Preview)***](https://openjdk.java.net/jeps/424))
- [孵化] 结构化并发([***JEP 428: Structured Concurrency (Incubator)***](https://openjdk.java.net/jeps/428))
  -  [`StructuredTaskScope`](https://download.java.net/java/early_access/loom/docs/api/jdk.incubator.concurrent/jdk/incubator/concurrent/StructuredTaskScope.html)

**主要 JVM 变化**

**引入**

- 源码(SourceCode): 
  - Linux/RISC 支持([***JEP 422: Linux/RISC-V Port***](https://openjdk.java.net/jeps/422))

## Java 20

**主要语言变化**

**引入**

- [预览] 虚拟线程([***JEP 436: Virtual Threads (Second Preview)***](https://openjdk.java.net/jeps/436))
- [孵化] 作用域值([***JEP 429: Scoped Values (Incubator)***](https://openjdk.java.net/jeps/429))
- [预览] Record 模式([***JEP 432: Record Patterns (Second Preview)***](https://openjdk.java.net/jeps/432))
- [预览] `switch`语句模式匹配([***JEP 433: Pattern Matching for switch (Fourth Preview)***](https://openjdk.java.net/jeps/433))
- [孵化] 向量 API([***JEP 438: Vector API (Fifth Incubator)***](https://openjdk.java.net/jeps/438))

**主要 API 变化**

**更新**

- [预览] 外部 Native 函数和内存 API([***JEP 434: Foreign Function & Memory API (Second Preview)***](https://openjdk.java.net/jeps/434))
- [孵化] 结构化并发([***JEP 437: Structured Concurrency (Second Incubator)***](https://openjdk.java.net/jeps/437))

## Java 21(LTS)

**主要语言变化**

**引入**

- 虚拟线程([***JEP 444: Virtual Threads***](https://openjdk.java.net/jeps/444))
  - [***虚拟线程原理及性能分析｜得物技术***](https://mp.weixin.qq.com/s/vdLXhZdWyxc6K-D3Aj03LA)
- Record 模式([***JEP 440: Record Patterns***](https://openjdk.java.net/jeps/440))
- `switch`语句模式匹配([***JEP 441: Pattern Matching for switch***](https://openjdk.java.net/jeps/441))
- [预览] String 模板([***JEP 430: String Templates (Preview)***](https://openjdk.java.net/jeps/430))
- [预览] 未命名模式和变量([***JEP 443: Unnamed Patterns and Variables (Preview)***](https://openjdk.java.net/jeps/443))
- [预览] 未命名类和实例 main 方法([***JEP 445: Unnamed Classes and Instance Main Methods (Preview)***](https://openjdk.java.net/jeps/445))
- [预览] 作用域值([***JEP 446: Scoped Values (Preview)***](https://openjdk.java.net/jeps/446))

**更新**

- [孵化] 向量 API([***JEP 448: Vector API (Sixth Incubator)***](https://openjdk.java.net/jeps/448))

**主要 API 变化**

**引入**

- 集合(Collections): 有序集合([***JEP 431: Sequenced Collections***](https://openjdk.java.net/jeps/431))
- 安全(Security): Key 封装 API([***JEP 452: Key Encapsulation Mechanism API***](https://openjdk.org/jeps/452))

**更新**

- [预览] 外部 Native 函数和内存 API([***JEP 442: Foreign Function & Memory API (Third Preview)***](https://openjdk.java.net/jeps/442))
- [预览] 结构化并发([***JEP 453: Structured Concurrency (Preview)***](https://openjdk.java.net/jeps/453))

**主要 JVM 变化**

**更新**

- 垃圾回收(Garbage Collection)
  - 分代 ZGC([***JEP 439: Generational ZGC***](https://openjdk.java.net/jeps/439))
    - 目前默认关闭, 未来会设置成默认, 可以通过配置打开: `-XX:+UseZGC -XX:+ZGenerational`
- 源码(SourceCode): 
  - 移除 Windows 32 位 x86 实现([***JEP 449: Deprecate the Windows 32-bit x86 Port for Removal***](https://openjdk.java.net/jeps/449))
- 预备禁止动态 Agent 加载([***JEP 451: Prepare to Disallow the Dynamic Loading of Agents***](https://openjdk.java.net/jeps/451))

# 是否升级

> 个人觉得现代 Java 的使用越来越偏底层, 越来越难, 很多黑科技的出现, 比如指令优化等, 这些都不是给没有经验的小白玩的, 而是给资深有经验的人使用的, 所以了解这些高级特性是提升个人竞争力的有效途径.

从 Java 8 到 21, 无论是性能还是内存的优化, 还是更多的底层支持, 都得到了质的飞跃(String 压缩, ZGC, GraalVm等), 但升不升级还是需要慎重考虑.

如果应用依赖比较少, 升级难度还没那么大. 如果依赖比较多, 那么就要非常慎重了, 因为由于内部 Java 内部 API 的变动(比如 `@PostCostruct` 被移除了, StackTrace 有了新的 API), 如果第三框架没有适配, 那就寄了. 新的项目可以尝试使用最新的版本以享受新特性带来的性能提升, 但可能很多公共模块要重新适配, 对开发人员提出更高的要求.

# Ref

* ***[Wiki - Java版本历史](https://zh.wikipedia.org/wiki/Java%E7%89%88%E6%9C%AC%E6%AD%B7%E5%8F%B2)***
* [***Java 9 - 21: 新特性解读***](https://www.didispace.com/java-features/)
* [***【值得收藏】JDK10到21！新特性一网打尽！***](https://mp.weixin.qq.com/s/lE23o1p2QVcn3t2ffGDcqA)
* [***Java Version History***](https://en.wikipedia.org/wiki/Java_version_history)
* [***JDK 11 Release Notes***](https://www.oracle.com/java/technologies/javase/11-relnote-issues.html)
* [***JDK 17 Release Notes***](https://www.oracle.com/java/technologies/javase/17-relnote-issues.html)
* [***JDK 21 Release Notes***](https://www.oracle.com/java/technologies/javase/21-relnote-issues.html)