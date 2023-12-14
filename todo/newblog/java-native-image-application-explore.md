![](https://image.cdn.yangbingdong.com/image/java-native-image-application-basic/5f1d2ca90862bab4fa5afe565f7dd070-f9ce43.png)

# 前言

Java Native Image 是利用 GraalVM 实现的 AOT 编译成特定平台的本地二进制执行文件的一种技术, 而 AOT 其实在很早的时候就已经出现, 只不过早起应用没那么广泛, 大部分是在安卓中使用到. 而随着云原生的崛起, 与其他云原生友好的编程语言对比,  Java JVM和JIT的性能问题越来越多地被诟病, 而 GraalVM 的出现打破了这一尴尬局面. 

# GraalVM

> 官方介绍: [***GraalVM Overview***](https://www.graalvm.org/latest/docs/introduction/)
> 维基百科: [***GraalVM - Wiki***](https://en.wikipedia.org/wiki/GraalVM)

GraalVM 最早关于 GraalVM 工作可以追溯到 2012 年, 然而，最初的版本并没有立即成为公共可用的产品, GraalVM 项目于2018年逐渐成熟，GraalVM 19.0 是首个包含 GraalVM Native Image 的公开版本，这是在2019年1月发布的, GraalVM Native Image 提供了一种将 Java 程序编译成本地机器代码的方法，以便在启动和运行时获得更好的性能和资源利用率, 这使得 Java 应用程序能够更好地适应云原生和容器化环境.

**AOT的优点**:

- 在程序运行前编译，可以**避免在运行时的编译性能消耗和内存消耗**
- 可以**在程序运行初期就达到最高性能，程序启动速度快**
- 运行产物只有机器码，**打包体积小**

**AOT的缺点**:

- 由于是静态提前编译，不能根据硬件情况或程序运行情况择优选择机器指令序列，**理论峰值性能不如JIT**
- **没有动态能力**
- 同一份产物**不能跨平台运行**



# Remark

* Windows 下建议使用 Docker 构建 Native Image, 避免出现奇奇怪怪的问题, Quarkus 以及 Spring Boot 都有支持.
* Windows 下是用 Docker Desktop 管理 Docker 的, 尽量多分配点资源, 否则容易出现编译慢甚至卡死的现象, 辛苦等半天结果编译失败了 T.T
        
     

