---
title: 关于微服务的一些调研零散笔记
date: 2018-01-02 16:59:14
categories: [Programming, Java]
tags: [Java]
---

![](https://cdn.yangbingdong.com/img/micro-service/microservice.png)

# Preface

> *[微服务架构](https://zh.wikipedia.org/zh-cn/%E5%BE%AE%E6%9C%8D%E5%8B%99)*： 
> **微服务** (Microservices) 是一种软件架构风格 (Software Architecture Style)，它是以专注于单一责任与功能的小型功能区块 (Small Building Blocks) 为基础，利用模组化的方式组合出复杂的大型应用程序，各功能区块使用与**语言无关** (Language-Independent/Language agnostic) 的 **API 集相互通讯**。

> **不拆分存储的微服务是伪服务**：在实践中，我们常常见到一种架构，后端存储是全部和在一个数据库中，仅仅把前端的业务逻辑拆分到不同的服务进程中，本质上和一个Monolithic一样，只是把模块之间的进程内调用改为进程间调用，这种切分不可取，违反了分布式第一原则，**模块耦合没有解决**，**性能却受到了影响**。

<!--more-->

# Concept

**DDD**: Domain-Driver Design 领域驱动设计

**CQRS**: Command Query Responsibility Segregation 命令查询职责分离

**[Event Sourcing](http://microservices.io/patterns/data/event-sourcing.html)**: 事件溯源

**Event-driven Architecture**: 事件驱动架构，使用事件来实现跨多个服务的业务逻辑

**Saga**: 长时间活动的事务(Long Lived Transaction，简称为LLT)
SEC(Saga Execution Coordinator): 一个基于事件驱动的状态机的协调器
*[Saga模式和事件驱动](http://newtech.club/2017/07/16/Design%20for%20Failure-Saga%E6%A8%A1%E5%BC%8F%E5%92%8C%E6%B6%88%E6%81%AF%E9%A9%B1%E5%8A%A8/)*

**贫血模型**: 对象只用于在各层之间传输数据用，**只有数据字段和Get/Set方法**，没有逻辑在对象中 
**充血模型**: **将数据和行为封装在一起**，并与现实世界的业务对象相映射。各类具备明确的职责划分，使得逻辑分散到合适对象中。(领域模型)

# Problem

**微服务架构必须解决这三个问题**
**拆分领域模型**、**事务**、**查询**

## 拆分领域模型

遵循Single Responsibility(单一职责)
**Aggregate**(聚合)：

- 聚合通过id（例如主键）来引用而不是通过对象引用
- 聚合必须遵循一个事务只能对一个聚合进行创建或更新
- 聚合应该尽量细

## 事务

由于采用了微服务拥有各自的私人数据库，只能通过API访问，不可避免出现了分布式跨数据库事务问题。

### ACID vs BASE

传统事务 **ACID**：

- Atomicity（原子性）：一个事务中的操作是原子的，其中任何一步失败，系统都能够完全回到事务前的状态
- Consistency（一致性）：数据库的状态始终保持一致
- Isolation（隔离性）：多个并发执行的事务不会互相影响
- Durability（持久性）：事务处理结束后，对数据的修改是永久的

微服务下依靠分布式事务（如2PC）保证实时一致性（强一致性），性能底下，牺牲了可用性，已不适用于现代的微服务架构。

**BASE**模型：

- Basically Available（基本可用）：系统在出现不可预知的故障的时候，允许损失部分可用性，但不等于系统不可用
- Soft State（软状态）：允许系统中的数据存在中间状态，并认为该中间状态的存在不会影响系统的整体可用性
- Eventually Consistent（最终一致性）：系统保证最终数据能够达到一致

微服务倡导每个微服务拥有私有的数据库，且其他服务不能直接与访问该数据库，只能通过该服务暴露的API进行交互。

### TCC

业务层面的2PC，需要实现`Try`、`Comfirm`、`Cancel`
*[GitHub中TCC实现框架](https://github.com/search?l=Java&o=desc&q=tcc&s=stars&type=Repositories&utf8=%E2%9C%93)*

### 基于可靠消息达到最终一致性

缺点是应用程序不能够立即读取到自己刚刚的写入（滞后性）。

#### 使用本地事务

对资源的操作与发布时间捆绑在同一事务中。
优点：使用了本地数据库的事务，如果Event没有插入或发布成功，那么订单也不会被创建。
缺点：需要单独处理Event发布在业务逻辑中，繁琐容易忘记；Event发送有些滞后。

#### 使用数据库特有的MySQL Binlog跟踪

订阅binlog发送event
优点：提高了性能
缺点：不同的数据库，日志格式不一样，而且同一数据库，不同版本格式也可能不一样，决策的时候请慎重。

### Event Sourcing

颠覆传统存储概念，不持久化对象数据，而是持久化对象变更的Event，通过溯源，遍历事件拿到对象的最新状态。在我看来，类似文件系统的概念，一个操作是一层，删除并不是减掉一层，而是添加一层删除操作（类似Git中的版本，可回滚，有记录追踪）。

### 阿里云GTS全局事务

***[GTS（Global Transaction Service）官方文档](https://help.aliyun.com/document_detail/48726.html)***（需要捆绑Ali全家桶。。。）

## 查询

实践微服务之后，除了事务之外，查询是又是另外一个挑战。在传统架构中，我们可以JOIN多个表进行查询，但在微服务当中，数据库已经分开，如果是通过Event Sourcing实现的架构就更加困难了（因为存储的是事件）。

解决之道：**CQRS**

# Extend

## Event-driven

`Sync`（请求/响应）: 串行架构

![](https://cdn.yangbingdong.com/img/micro-service/register-sync.jpg)
优点：个人认为，只有一个优点，可以偷懒
缺点：中心控制点承担了太多的职责，入侵式强耦合代码，如果此时多加一个业务例如创建用户团队，那就必须在原来代码基础上继续入侵代码，而且修改一行代码有可能影响到下文。

`Async`（基于事件）: 并行/异步架构

![](https://cdn.yangbingdong.com/img/micro-service/register-async.jpg)
优点：客户端发起的不是一个请求，而是**发布一个事件**，然后其他协作者接收到该事件，并知道该怎么做。我们从来不会告知任何人去做任何事，基于事件的系统天生就是**异步**的。整个系统都很聪明，业务逻辑并非存在某个核心大脑，而是分布在不同的协作者中。基于事件的协作方式耦合性很低，这意味着你可以在**不改变客户端代码**的情况下，对该事件**添加新的订阅者来完成新增的功能需求**。

## Spring Cloud Framework

### Spring Cloud Netflix

这可是个大boss，地位仅次于老大，老大各项服务依赖与它，与各种Netflix OSS组件集成，组成微服务的核心，它的小弟主要有Eureka, Hystrix, Zuul, Archaius… 太多了

**Netflix Eureka**

服务中心，云端服务发现，一个基于 REST 的服务，用于定位服务，以实现云端中间层服务发现和故障转移。这个可是springcloud最牛鼻的小弟，服务中心，任何小弟需要其它小弟支持什么都需要从这里来拿，同样的你有什么独门武功的都赶紧过报道，方便以后其它小弟来调用；它的好处是你不需要直接找各种什么小弟支持，只需要到服务中心来领取，也不需要知道提供支持的其它小弟在哪里，还是几个小弟来支持的，反正拿来用就行，服务中心来保证稳定性和质量。

**Netflix Hystrix**

熔断器，容错管理工具，旨在通过熔断机制控制服务和第三方库的节点,从而对延迟和故障提供更强大的容错能力。比如突然某个小弟生病了，但是你还需要它的支持，然后调用之后它半天没有响应，你却不知道，一直在等等这个响应；有可能别的小弟也正在调用你的武功绝技，那么当请求多之后，就会发生严重的阻塞影响老大的整体计划。这个时候Hystrix就派上用场了，当Hystrix发现某个小弟不在状态不稳定立马马上让它下线，让其它小弟来顶上来，或者给你说不用等了这个小弟今天肯定不行，该干嘛赶紧干嘛去别在这排队了。

**Netflix Zuul**

Zuul 是在云平台上提供动态路由,监控,弹性,安全等边缘服务的框架。Zuul 相当于是设备和 Netflix 流应用的 Web 网站后端所有请求的前门。当其它门派来找大哥办事的时候一定要先经过zuul,看下有没有带刀子什么的给拦截回去，或者是需要找那个小弟的直接给带过去。

**Netflix Archaius**

配置管理API，包含一系列配置管理API，提供动态类型化属性、线程安全配置操作、轮询框架、回调机制等功能。可以实现动态获取配置，原理是每隔60s（默认，可配置）从配置源读取一次内容，这样修改了配置文件后不需要重启服务就可以使修改后的内容生效，前提使用archaius的API来读取。

### Spring Cloud Config

俗称的配置中心，配置管理工具包，让你可以把配置放到远程服务器，集中化管理集群配置，目前支持本地存储、Git以及Subversion。就是以后大家武器、枪火什么的东西都集中放到一起，别随便自己带，方便以后统一管理、升级装备。

### Spring Cloud Bus

事件、消息总线，用于在集群（例如，配置变化事件）中传播状态变化，可与Spring Cloud Config联合实现热部署。相当于水浒传中日行八百里的神行太保戴宗，确保各个小弟之间消息保持畅通。

### Spring Cloud for Cloud Foundry

Cloud Foundry是VMware推出的业界第一个开源PaaS云平台，它支持多种框架、语言、运行时环境、云平台及应用服务，使开发人员能够在几秒钟内进行应用程序的部署和扩展，无需担心任何基础架构的问题

其实就是与CloudFoundry进行集成的一套解决方案，抱了Cloud Foundry的大腿。

### Spring Cloud Cluster

Spring Cloud Cluster将取代Spring Integration。提供在分布式系统中的集群所需要的基础功能支持，如：选举、集群的状态一致性、全局锁、tokens等常见状态模式的抽象和实现。

如果把不同的帮派组织成统一的整体，Spring Cloud Cluster已经帮你提供了很多方便组织成统一的工具。

### Spring Cloud Consul

Consul 是一个支持多数据中心分布式高可用的服务发现和配置共享的服务软件,由 HashiCorp 公司用 Go 语言开发, 基于 Mozilla Public License 2.0 的协议进行开源. Consul 支持健康检查,并允许 HTTP 和 DNS 协议调用 API 存储键值对.

Spring Cloud Consul 封装了Consul操作，consul是一个服务发现与配置工具，与Docker容器可以无缝集成。

### 其它小弟

**Spring Cloud Security**

基于spring security的安全工具包，为你的应用程序添加安全控制。这个小弟很牛鼻专门负责整个帮派的安全问题，设置不同的门派访问特定的资源，不能把秘籍葵花宝典泄漏了。

**Spring Cloud Sleuth**

日志收集工具包，封装了Dapper和log-based追踪以及Zipkin和HTrace操作，为SpringCloud应用实现了一种分布式追踪解决方案。

**Spring Cloud Data Flow**

- Data flow 是一个用于开发和执行大范围数据处理其模式包括ETL，批量运算和持续运算的统一编程模型和托管服务。
- 对于在现代运行环境中可组合的微服务程序来说，Spring Cloud data flow是一个原生云可编配的服务。使用Spring Cloud data flow，开发者可以为像数据抽取，实时分析，和数据导入/导出这种常见用例创建和编配数据通道 （data pipelines）。
- Spring Cloud data flow 是基于原生云对 spring XD的重新设计，该项目目标是简化大数据应用的开发。Spring XD 的流处理和批处理模块的重构分别是基于 Spring Boot的stream 和 task/batch 的微服务程序。这些程序现在都是自动部署单元而且他们原生的支持像 Cloud Foundry、Apache YARN、Apache Mesos和Kubernetes 等现代运行环境。
- Spring Cloud data flow 为基于微服务的分布式流处理和批处理数据通道提供了一系列模型和最佳实践。

**Spring Cloud Stream**

Spring Cloud Stream是创建消息驱动微服务应用的框架。Spring Cloud Stream是基于Spring Boot创建，用来建立单独的／工业级spring应用，使用spring integration提供与消息代理之间的连接。数据流操作开发包，封装了与Redis,Rabbit、Kafka等发送接收消息。

一个业务会牵扯到多个任务，任务之间是通过事件触发的，这就是Spring Cloud stream要干的事了

**Spring Cloud Task**

Spring Cloud Task 主要解决短命微服务的任务管理，任务调度的工作，比如说某些定时任务晚上就跑一次，或者某项数据分析临时就跑几次。

**Spring Cloud Zookeeper**

ZooKeeper是一个分布式的，开放源码的分布式应用程序协调服务，是Google的Chubby一个开源的实现，是Hadoop和Hbase的重要组件。它是一个为分布式应用提供一致性服务的软件，提供的功能包括：配置维护、域名服务、分布式同步、组服务等。ZooKeeper的目标就是封装好复杂易出错的关键服务，将简单易用的接口和性能高效、功能稳定的系统提供给用户。

操作Zookeeper的工具包，用于使用zookeeper方式的服务发现和配置管理，抱了Zookeeper的大腿。

**Spring Cloud Connectors**

Spring Cloud Connectors 简化了连接到服务的过程和从云平台获取操作的过程，有很强的扩展性，可以利用Spring Cloud Connectors来构建你自己的云平台。

便于云端应用程序在各种PaaS平台连接到后端，如：数据库和消息代理服务。

**Spring Cloud Starters**

Spring Boot式的启动项目，为Spring Cloud提供开箱即用的依赖管理。

**Spring Cloud CLI**

基于 Spring Boot CLI，可以让你以命令行方式快速建立云组件。

## Demo

*[基于事件驱动+事件溯源+Saga的微服务示例](https://github.com/JoeCao/OrderEventDrivenDemo)*

*[一个微服务架构的在线购物网站（CQRS+Event Sourcing）](https://github.com/chaokunyang/microservices-event-sourcing)*

*[spring-cloud-event-sourcing-example](https://github.com/kbastani/spring-cloud-event-sourcing-example)*

*[CQRS实现框架AxonFramework](https://github.com/AxonFramework/AxonFramework)*

*[溯源实现框架Eventuate Local](https://github.com/eventuate-local/eventuate-local)*