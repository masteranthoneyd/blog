---
title: Spring Cloud Alibaba 介绍
date: 2020-09-09 11:06:32
categories: [Programming, Java, Spring Cloud]
tags: [Spring, Spring Cloud, Spring Cloud Alibaba]
---

![](https://cdn.yangbingdong.com/img/spring-cloud-alibaba/spring-cloud-alibaba-introduce.png)

# Preface

> 阿里作为国内最大的云厂家之一, 在微服务如火如荼的当下也紧跟时代, 推出了 Spring Cloud Alibaba 体系, 与自身的云产品有更好的融合. 本篇主要记录开源 Spring Cloud Alibaba 组件的简单实用.

<!--more-->

Spring Cloud Alibaba 包含组件:

开源部分

* Sentinel: 把流量作为切入点, 从流量控制, 熔断降级, 系统负载保护等多个维度保护服务的稳定性. 
* Nacos: 一个更易于构建云原生应用的动态服务发现, 配置管理和服务管理平台. 
* RocketMQ: 一款开源的分布式消息系统, 基于高可用分布式集群技术, 提供低延时的, 高可靠的消息发布与订阅服务. 
* Dubbo: Apache Dubbo 是一款高性能 Java RPC 框架. 
* Seata: 阿里巴巴开源产品, 一个易于使用的高性能微服务分布式事务解决方案

平台部分

* Alibaba Cloud OSS: 阿里云对象存储服务(Object Storage Service, 简称 OSS), 是阿里云提供的海量, 安全, 低成本, 高可靠的云存储服务. 您可以在任何应用, 任何时间, 任何地点存储和访问任意类型的数据. 
* Alibaba Cloud SchedulerX: 阿里中间件团队开发的一款分布式任务调度产品, 提供秒级, 精准, 高可靠, 高可用的定时(基于 Cron 表达式)任务调度服务. 
* Alibaba Cloud SMS: 覆盖全球的短信服务, 友好, 高效, 智能的互联化通讯能力, 帮助企业迅速搭建客户触达通道. 

***[Spring Cloud Alibaba 中文参考文档](https://spring-cloud-alibaba-group.github.io/github-pages/hoxton/zh-cn/)***

***[Spring Cloud Alibaba Github](https://github.com/alibaba/spring-cloud-alibaba)***

***[Aliyun Spring Boot Github](https://github.com/alibaba/aliyun-spring-boot)***

***[Aliyun Java Initializer](https://start.aliyun.com/bootstrap.html)***

# 版本说明

> 最新请看: ***[版本说明](https://github.com/alibaba/spring-cloud-alibaba/wiki/%E7%89%88%E6%9C%AC%E8%AF%B4%E6%98%8E)***

推荐使用 bom 管理:

```xml
    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>com.alibaba.cloud</groupId>
                <artifactId>spring-cloud-alibaba-dependencies</artifactId>
                <version>${spring-cloud-alibaba.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-dependencies</artifactId>
                <version>${spring-boot.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>	
```

```xml
    <properties>
        <java.version>1.8</java.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
        <spring-boot.version>2.3.0.RELEASE</spring-boot.version>
        <spring-cloud-alibaba.version>2.2.1.RELEASE</spring-cloud-alibaba.version>
    </properties>
```

# Nacos 分布式配置

> Nacos 获取以及启动方式: ***[Nacos 官网](https://nacos.io/zh-cn/docs/quick-start.html?spm=a2ck6.20206201.0.0.671e1fd6rGzuF0)***
>
> Spring Cloud Nacos Config 文档: ***[https://github.com/alibaba/spring-cloud-alibaba/wiki/Nacos-config](https://github.com/alibaba/spring-cloud-alibaba/wiki/Nacos-config)***

## 依赖与配置

```xml
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-nacos-config</artifactId>
</dependency>
```

在 bootstrap.yml 中增加如下配置:

```yaml
spring:
  application:
    name: test-server
  cloud:
    nacos:
      server-addr: nacos.test.com:80 # 注意端口不能省略
      config:
        username: admin
        password: admin123
        file-extension: properties
        namespace: test
```

不需要启用 Nacos 可以通过 `spring.cloud.nacos.config.enabled = false` 进行关闭.

## 配置加载解读

Nacos 主要通过这几个参数控制配置文件的加载:

- `spring.cloud.nacos.config.namespace`: 命名空间, 可实现环境隔离或多租户, 默认值为 `public`
- `spring.cloud.nacos.config.prefix`: Data Id 前缀, 默认取 `${spring.application.name}`
- `spring.cloud.nacos.config.file-extension`: Data Id 后缀, 默认值 `properties`
- `spring.cloud.nacos.config.group`: 对应 Group, 默认值 `DEFAULT_GROUP`

Nacos 会加载 `${spring.cloud.nacos.config.namespace}` 下 `Data ID=${spring.cloud.nacos.config.prefix}-${spring.profiles.active}.${spring.cloud.nacos.config.file-extension}`, `Group=${spring.cloud.nacos.config.group}`的配置.

即默认加载 `Data ID=${spring.application.name}.properties` (没有指定指定 profile), `Group=DEFAULT_GROUP` 的配置.

## 多环境隔离方案

三种方案:

1. 通过 `Namespace`(官方推荐)
2. 通过 `Group`
3. 通过 `Data Id` + `profile`

## 多配置加载与共享配置

通过 `spring.cloud.nacos.config.ext-config[n]` 进行多配置加载:

```
spring.cloud.nacos.config.ext-config[0].data-id=actuator.properties
spring.cloud.nacos.config.ext-config[0].group=DEFAULT_GROUP
spring.cloud.nacos.config.ext-config[0].refresh=true
spring.cloud.nacos.config.ext-config[1].data-id=log.properties
spring.cloud.nacos.config.ext-config[1].group=DEFAULT_GROUP
spring.cloud.nacos.config.ext-config[1].refresh=true
```

共享配置:

```
# 配置支持共享的 Data Id
spring.cloud.nacos.config.shared-configs[0].data-id=common.yaml

# 配置 Data Id 所在分组, 缺省默认 DEFAULT_GROUP
spring.cloud.nacos.config.shared-configs[0].group=GROUP_APP1

# 配置Data Id 在配置变更时, 是否动态刷新, 缺省默认 false
spring.cloud.nacos.config.shared-configs[0].refresh=true
```

**配置优先级:**

Spring Cloud Alibaba Nacos Config 目前提供了三种配置能力从 Nacos 拉取相关的配置. 

- A: 通过 `spring.cloud.nacos.config.shared-configs[n].data-id` 支持多个共享 Data Id 的配置
- B: 通过 `spring.cloud.nacos.config.extension-configs[n].data-id` 的方式支持多个扩展 Data Id 的配置
- C: 通过内部相关规则(应用名, 应用名+ Profile )自动生成相关的 Data Id 配置

当三种方式共同使用时, 他们的一个优先级关系是:A < B < C

## 配置自动更新

必须条件: Bean 的声明类必须标注 `@RefreshScope`

二选一条件: 

* 属性(非 static 字段)标注 `@Value`

* `@ConfigurationProperties`Bean

> 使用 `@RefreshScope` 刷新配置时会刷新 bean 是的生命周期.

# Nacos 服务注册与发现

> Nacos 获取以及启动方式: ***[Nacos 官网](https://nacos.io/zh-cn/docs/quick-start.html?spm=a2ck6.20206201.0.0.671e1fd6rGzuF0)***

依赖:

```xml
	  <dependency>
		  <groupId>com.alibaba.cloud</groupId>
		  <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
	  </dependency>
```

核心配置:

```properties
## Nacos 注册中心配置地址(无需配置 HTTP 协议部分)
spring.cloud.nacos.discovery.server-addr=127.0.0.1:8848
## Nacos 客户端认证信息(默认用户名和密码均为 nacos)
spring.cloud.nacos.discovery.user-name=nacos
spring.cloud.nacos.discovery.password=naocs		
```

在启动类加上 `@EnableDiscoveryClient` 即可. 服务名对应 `spring.application.name`.

接下来就可以使用 `@LoadBalanced RestTemplate` 或者 Open Feign 进行远程调用了.

# Dubbo Spring Cloud 远程调用

Dubbo Spring Cloud 基于 Spring Cloud Commons 抽象实现 Dubbo 服务注册与发现, 无需添加任何外部化配置, 就能轻松地桥接到所有原生 Spring Cloud 注册中心, 包括: 

- Nacos
- Eureka
- Zookeeper
- Consul

在 Spring Cloud 中默认通过 `@LoadBalanced RestTemplate` 或者 Open Feign 进行远程调用, 而 Dubbo Spring Cloud 通过 Apache Dubbo 注解 `@Service` 和 `@Reference` 暴露和引用 Dubbo 服务, 实现服务间多种协议的通讯.

Dubbo Spring Cloud 提供了 `@DubboTransported` 注解, 该注解能够帮助服务消费端的 Spring Cloud Open Feign 接口以及`@LoadBalanced RestTemplate` Bean 底层走 Dubbo 调用(可切换 Dubbo 支持的协议), 而服务提供方则只需在原有 `@RestController` 类上追加 Dubbo `@Servce` 注解(需要抽取接口)即可, 换言之, 在不调整 Feign 接口以及 `RestTemplate` URL 的前提下, 实现无缝迁移. 

使用 Dubbo Spring Cloud 主要三步, 当然前提是服务提供者与消费者都需要添加对应的依赖(需要依赖服务注册与发现):

```xml
        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
        </dependency>
        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-dubbo</artifactId>
        </dependency>
```

第一步, 定义契约接口, 服务提供者与消费者都需要依赖这个接口(可以单独打包, 也可以各自建接口, 但是接口包名要一样).

第二步:

* 服务提供者实现契约接口, 并打上 `@org.apache.dubbo.config.annotation.Service` 注解

* 在 `bootstrap.yaml` 中暴露服务:

  ```yaml
  dubbo:
    scan:
      # dubbo 服务扫描基准包
      base-packages: org.springframework.cloud.alibaba.dubbo.bootstrap
    protocol:
      # dubbo 协议
      name: dubbo
      # dubbo 协议端口( -1 表示自增端口, 从 20880 开始)
      port: -1
    
  spring:
    application:
      name: svc-provider # 该值在 Dubbo Spring Cloud 加持下被视作dubbo.application.name, 因此, 无需再显示地配置dubbo.application.name
    cloud:
      nacos:
        # Nacos 服务发现与注册配置
        discovery:
          server-addr: 127.0.0.1:8848
  ```

* 启动应用, 观察是否在 Nacos 中正常注册.

第三步:

* 服务消费者依赖契约接口, 并使用 `@Reference` 注解注入契约接口到使用类.

* `bootstrap.yaml` 配置:

  ```yaml
  dubbo:
    cloud:
      subscribed-services: svc-provider # 指定服务提供者, 多个使用","分割
      
  spring:
    cloud:
      nacos:
        # Nacos 服务发现与注册配置
        discovery:
          server-addr: 127.0.0.1:8848
  ```

* 直接使用契约接口像本地方法一样地调用.

# Sentinel 服务熔断与限流

> 沙箱体验: ***[https://start.aliyun.com/sandbox.html?id=5](https://start.aliyun.com/sandbox.html?id=5)***

熔断与限流可以避免服务因为瞬间的流量洪峰压垮, 从一定程度上保证了服务的稳定性.

***[Sentinel](https://github.com/alibaba/Sentinel)*** 是阿里巴巴开源的, 面向分布式服务架构的高可用防护组件, 主要以流量为切入点, 从流量控制, 流量整形, 熔断降级, 系统自适应保护, 热点防护等多个维度来帮助开发者保障微服务的稳定性. Sentinel 承接了阿里巴巴近 10 年的双十一大促流量的核心场景, 例如秒杀, 冷启动, 消息削峰填谷, 自适应流量控制, 实时熔断下游不可用服务等, 是保障微服务高可用的利器, 原生支持 Java/Go/C++ 等多种语言, 并且提供 Istio/Envoy 全局流控支持来为 Service Mesh 提供高可用防护的能力. 

Sentinel 的技术亮点: 

- 高度可扩展能力: 基础核心 + SPI 接口扩展能力, 用户可以方便地扩展流控, 通信, 监控等功能
- 多样化的流量控制策略(资源粒度, 调用关系, 流控指标, 流控效果等多个维度), 提供分布式集群流控的能力
- 热点流量探测和防护
- 对不稳定服务进行熔断降级和隔离
- 全局维度的系统负载自适应保护, 根据系统水位实时调节流量
- 覆盖 API Gateway 场景, 为 Spring Cloud Gateway, Zuul 提供网关流量控制的能力
- 实时监控和规则动态配置管理能力

![](https://cdn.yangbingdong.com/img/spring-cloud-alibaba/sentinel.png)

现假设有三个服务分别是 demo-gateway(业务网关), web-api-demo(web 应用, 负责接收用户请求并调用 dubbo-provider), dubbo-provider(服务提供者).

其中 web 暴露了三个端点:

- `/demo/hello`: 接受一个 name 参数, 会 RPC 调用后端的 `FooService:sayHello(name)` 方法. 
- `/demo/time`: 调用后端的 `FooService:getCurrentTime` 方法获取当前时间；里面可以通过 slow 请求参数模拟慢调用. 
- `/demo/bonjour/{name}`: 直接调用本地 DemoService 服务. 

api-gateway 配置如下:

```yaml
spring:
  cloud:
    gateway:
      enabled: true
      discovery:
        locator:
		  # route ID 转化小写
          lower-case-service-id: true
      routes:
        - id: foo-service-route
          uri: http://localhost:9669/
          predicates:
            - Path=/demo/**
        - id: httpbin-route
          uri: https://httpbin.org
          predicates:
            - Path=/httpbin/**
          filters:
            - RewritePath=/httpbin/(?<segment>.*), /$\{segment}
```

三个服务都引入:

```xml
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-sentinel</artifactId>
</dependency>
```

对于 Dubbo 服务, 需要引入 `sentinel-apache-dubbo-adapter` (provider 和 consumer):

```xml
<dependency>
    <groupId>com.alibaba.csp</groupId>
    <artifactId>sentinel-apache-dubbo-adapter</artifactId>
    <version>1.8.0</version>
</dependency>
```

而对于Spring Cloud Gateway, Zuul 1.x 等网关则需要引入:

```xml
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-alibaba-sentinel-gateway</artifactId>
</dependency>
```

接入 Sentinel 控制台, 修改 application.properties:

```properties
spring.application.name=foo-web
spring.cloud.sentinel.transport.dashboard=localhost:8080
```

依次启动 dubbo-provider, web-api-demo 和 demo-gateway 应用, 并通过网关入口访问 `localhost:8090/demo/time` 获取当前时间.

触发后可以在 Sentinel 的面板看到访问信息:

![](https://cdn.yangbingdong.com/img/spring-cloud-alibaba/sentinel02.png)

可以为每个链路设置限流:

![](https://cdn.yangbingdong.com/img/spring-cloud-alibaba/sentinel01.png)

更多限流规则请查看官方文档: ***[https://sentinelguard.io/zh-cn/docs/introduction.html](https://sentinelguard.io/zh-cn/docs/introduction.html)***

自定义流控逻辑:

```java
@Configuration
public class SentinelWebConfig {

    @Bean
    public BlockExceptionHandler sentinelBlockExceptionHandler() {
        return (request, response, e) -> {
            // 429 Too Many Requests
            response.setStatus(429);

            PrintWriter out = response.getWriter();
            out.print("Oops, blocked by Sentinel: " + e.getClass().getSimpleName());
            out.flush();
            out.close();
        };
    }
}
```

对于其他 RPC 组件比如 Feign 的支持请看 ***[Spring Cloud Alibaba Sentinel 接入文档](https://github.com/alibaba/spring-cloud-alibaba/wiki/Sentinel?spm=a2ck6.20206201.0.0.3c4a1fd6mFeVca#feign-%E6%94%AF%E6%8C%81)***

# Spring Cloud Stream RocketMQ

Spring 生态里有两个消息相关的模块和项目, 分别是 spring-messaging 模块和 Spring Integration 项目, 他们将消息模型进行了统一, 抽象成 `org.springframework.messaging.Message`:

![](https://cdn.yangbingdong.com/img/spring-cloud-alibaba/messaging01.png)

`Payload` 是一个泛型, 意味是消息体可以放任意数据类型. Header 是一个 `MessageHeaders` 类型的消息头. 

Spring Cloud Stream 是在 Spring Integration 基础上封装的, 他们的关系如下:

![](https://cdn.yangbingdong.com/img/spring-cloud-alibaba/messaging02.png)

Spring Cloud Stream RocketMQ 的用法与其他 Binder 的用法一致, 不同的是依赖以及配置:

```xml
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-stream-rocketmq</artifactId>
</dependency>
```

```properties
spring.cloud.stream.rocketmq.binder.name-server=http://1459088147016887.mqrest.cn-qingdao-public.aliyuncs.com

spring.cloud.stream.bindings.source1.destination=test-topic-1
spring.cloud.stream.bindings.source1.group=group-1-yangbingdong
spring.cloud.stream.bindings.source1.binder=rocketmq

spring.cloud.stream.bindings.source2.destination=test-topic-2
spring.cloud.stream.bindings.source2.group=group-2-yangbingdong
spring.cloud.stream.bindings.source2.binder=rocketmq
```

```java
@SpringBootApplication
@EnableBinding({SCSApplication.Source1.class, SCSApplication.Source2.class})
public class SCSApplication {

    public static void main(String[] args) {
        new SpringApplicationBuilder().sources(SCSApplication.class).run(args);
    }

    @Autowired
    private Source1 source1;

    @Bean
    public CommandLineRunner runner() {
        return (args) -> source1.output().send(MessageBuilder.withPayload("custom payload").setHeader("k1", "v1").build());
    }

    @StreamListener("source1")
    @SendTo("source2")
    public String receiveFromSource2(String msg) {
        System.out.println("receive msg from source1: " + msg);
        return msg.toUpperCase();
    }

    @StreamListener("source2")
    public void receiveFromRocketMQ(String msg) {
        System.out.println("receive msg from source2 : " + msg);
    }

    public interface Source1 {

        @Output("source1")
        MessageChannel output();

        @Input("source1")
        SubscribableChannel input();
    }

    public interface Source2 {

        @Output("source2")
        MessageChannel output();

        @Input("source2")
        SubscribableChannel input();
    }
}
```

# Seata 分布式事务

文档: ***[https://seata.io/zh-cn/docs/user/quickstart.html](https://seata.io/zh-cn/docs/user/quickstart.html)***
