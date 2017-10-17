# Micro Service
> *[微服务架构](https://zh.wikipedia.org/zh-cn/%E5%BE%AE%E6%9C%8D%E5%8B%99)*： 
> **微服务** (Microservices) 是一种软件架构风格 (Software Architecture Style)，它是以专注于单一责任与功能的小型功能区块 (Small Building Blocks) 为基础，利用模组化的方式组合出复杂的大型应用程序，各功能区块使用与**语言无关** (Language-Independent/Language agnostic) 的 **API 集相互通讯**。

> **不拆分存储的微服务是伪服务**：在实践中，我们常常见到一种架构，后端存储是全部和在一个数据库中，仅仅把前端的业务逻辑拆分到不同的服务进程中，本质上和一个Monolithic一样，只是把模块之间的进程内调用改为进程间调用，这种切分不可取，违反了分布式第一原则，**模块耦合没有解决**，**性能却受到了影响**。

# Concept

**DDD**: Domain-Driver Design 领域驱动设计

**CQRS**: Command Query Responsibility Segregation 命令查询职责分离
*[AxonFramework](https://github.com/AxonFramework/AxonFramework)*: CQRS实现框架

**[Event Sourcing](http://microservices.io/patterns/data/event-sourcing.html)**: 事件溯源
*[Eventuate Local](https://github.com/eventuate-local/eventuate-local)*: 溯源实现框架

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
Aggregate(聚合)：
* 聚合通过id（例如主键）来引用而不是通过对象引用
* 聚合必须遵循一个事务只能对一个聚合进行创建或更新
* 聚合应该尽量细

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
***[GTS（Global Transaction Service）官方文档](https://help.aliyun.com/document_detail/48726.html)***

## 查询

实践微服务之后，除了事务之外，查询是又是另外一个挑战。在传统架构中，我们可以JOIN多个表进行查询，但在微服务当中，数据库已经分开，如果是通过Event Sourcing实现的架构就更加困难了（因为存储的是事件）。

解决之道：CQRS



# Extend
## Event-driven

`Sync`（请求/响应）: 串行架构

![](http://ojoba1c98.bkt.clouddn.com/img/micro-service/register-sync.jpg)
优点：个人认为，只有一个优点，可以偷懒
缺点：中心控制点承担了太多的职责，入侵式强耦合代码，如果此时多加一个业务例如创建用户团队，那就必须在原来代码基础上继续入侵代码，而且修改一行代码有可能影响到下文。


`Async`（基于事件）: 并行/异步架构

![](http://ojoba1c98.bkt.clouddn.com/img/micro-service/register-async.jpg)
优点：客户端发起的不是一个请求，而是**发布一个事件**，然后其他协作者接收到该事件，并知道该怎么做。我们从来不会告知任何人去做任何事，基于事件的系统天生就是**异步**的。整个系统都很聪明，业务逻辑并非存在某个核心大脑，而是分布在不同的协作者中。基于事件的协作方式耦合性很低，这意味着你可以在**不改变客户端代码**的情况下，对该事件**添加新的订阅者来完成新增的功能需求**。

## Framework

* ***Spring Cloud Stream***: Spring对消息中间件的封装，使开发人员更简单地使用消息来构建*事件驱动架构*
* ***Zipkin***: 分布式跟踪系统
* ***Dapper***: Google开发的大规模分布式系统的跟踪系统
* ***Spring Cloud Sleuth***: Spring对`Zipkin`以及`Dapper`的部分封装

## Demo

*[基于事件驱动+事件溯源+Saga的微服务示例](https://github.com/JoeCao/OrderEventDrivenDemo)*

*[一个微服务架构的在线购物网站（CQRS+Event Sourcing）](https://github.com/chaokunyang/microservices-event-sourcing)*

*[spring-cloud-event-sourcing-example](https://github.com/kbastani/spring-cloud-event-sourcing-example)*