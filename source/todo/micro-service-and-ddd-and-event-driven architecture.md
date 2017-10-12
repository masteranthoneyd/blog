# Micro Service
> 微服务架构（[维基百科](https://zh.wikipedia.org/zh-cn/%E5%BE%AE%E6%9C%8D%E5%8B%99)）： 
> **微服务** (Microservices) 是一种软件架构风格 (Software Architecture Style)，它是以专注于单一责任与功能的小型功能区块 (Small Building Blocks) 为基础，利用模组化的方式组合出复杂的大型应用程序，各功能区块使用与语言无关 (Language-Independent/Language agnostic) 的 API 集相互通讯。

# Concept

**DDD**: Domain-Driver Design 领域驱动设计

**CQRS**: Command Query Responsibility Segregation 命令查询职责分离
AxonFramework: CQRS实现框架

**Event Sourcing**: 事件溯源
Eventuate Local: 溯源实现框架

**Event-driven Architecture**: 使用事件来实现跨多个服务的业务逻辑

# Problem

**微服务架构必须解决这三个问题**
**拆分领域模型**、**事务**、**查询**

## 拆分领域模型
Single Responsibility(单一职责)
Aggregate(聚合)

## 事务
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

### 最终一致性

#### 基于可靠消息

##### 使用本地事务
对资源的操作与发布时间捆绑在同一事务中。
优点：使用了本地数据库的事务，如果Event没有插入或发布成功，那么订单也不会被创建。
缺点：需要单独处理Event发布在业务逻辑中，繁琐容易忘记；Event发送有些滞后。

##### 使用数据库特有的MySQL Binlog跟踪
订阅binlog发送event
优点：提高了性能
缺点：不同的数据库，日志格式不一样，而且同一数据库，不同版本格式也可能不一样，决策的时候请慎重。

##### Event Sourcing
颠覆传统存储概念，不持久化对象数据，而是持久化对象变更的Event，通过溯源，遍历事件拿到对象的最新状态。在我看来，类似文件系统的概念，一个操作是一层。

## 查询

