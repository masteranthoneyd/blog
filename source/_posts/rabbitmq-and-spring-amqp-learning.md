---
title: Rabbit & Spring AMQP 入门
date: 2019-04-25 16:44:51
categories: [Programming, Java]
tags: [Java, Spring Boot, Spring Cloud, RabbitMQ]
---

![](https://cdn.yangbingdong.com/img/rabbitmq-learning/spring-rabbitmq-banner.png)

# Preface

> MQ(Message Queue, 消息队列)是一种应用系统之间的通信方法. 是通过读写出入队列的消息来通信(RPC则是通过直接调用彼此来通信的). 
>
> AMQP, 即Advanced Message Queuing Protocol, 高级消息队列协议, 是应用层协议的一个开放标准, 为面向消息的中间件设计. 消息中间件主要用于组件之间的解耦, 消息的发送者无需知道消息使用者的存在, 反之亦然. 
> AMQP的主要特征是面向消息, 队列, 路由(包括点对点和发布/订阅), 可靠性, 安全. 
>
> RabbitMQ是一个开源的AMQP**实现**, 服务器端用Erlang语言编写. 

<!--more-->

# 启动

这里使用Docker启动.

docker-compose:

```yaml
version: '3.7'

services:
  rabbitmq:
    image: my-rabbitmq:latest
    restart: always
    ports:
      - "5672:5672"
      - "15672:15672"
    volumes:
      - ./data:/var/lib/rabbitmq
    environment:
      RABBITMQ_DEFAULT_USER: rabbitmq
      RABBITMQ_DEFAULT_PASS: rabbitmq
    networks:
      backend:
        aliases:
          - rabbitmq

networks:
  backend:
    external: true
```

# 基本概念

## Hello World

先来利用原生的 RabbitMQ Java Client 来运行一个 Hello World 程序:

```java
package com.yangbingdong.rabbitmq.basic;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.Consumer;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;
import org.junit.Test;

import java.io.IOException;

import static com.yangbingdong.rabbitmq.basic.ConnectionUtil.getConnection;

public class BasicSingleSendAndReceive {

	private final static String QUEUE_NAME = "hello0";

	@Test
	public void basicSingleSendAndReceive() throws Exception {
		send();
		receive();
	}

	private void send() throws Exception {
		Connection connection = getConnection();
		Channel channel = connection.createChannel();
		channel.queueDeclare(QUEUE_NAME, false, false, false, null);
		String message = "Hello World!";
		channel.basicPublish("", QUEUE_NAME, null, message.getBytes());
		System.out.println("Sent '" + message + "'");
		channel.close();
		connection.close();
		System.out.println();
	}

	private void receive() throws Exception {
		Connection connection = getConnection();
		Channel channel = connection.createChannel();

		// 声明队列, 主要为了防止消息接收者先运行此程序, 队列还不存在时创建队列.
		channel.queueDeclare(QUEUE_NAME, false, false, false, null);
		Consumer consumer = new DefaultConsumer(channel) {
			@Override
			public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
				System.out.println("consumerTag: " + consumerTag);
				System.out.println("envelope: " + envelope);
				System.out.println("properties: " + properties);
				System.out.println("body: " + new String(body));
			}
		};
		System.out.println("Waiting for messages.");
		// 指定消费队列
		channel.basicConsume(QUEUE_NAME, true, consumer);
		Thread.sleep(100L);
	}
}
```

工具类:

```java
package com.yangbingdong.rabbitmq.basic;

import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;

import java.io.IOException;
import java.util.concurrent.TimeoutException;

public class ConnectionUtil {
	private static final String HOST = "127.0.0.1";
	private static final String NAME_PASS = "rabbitmq";

	public static Connection getConnection() throws IOException, TimeoutException {
		ConnectionFactory factory = new ConnectionFactory();
		factory.setHost(HOST);
		factory.setUsername(NAME_PASS);
		factory.setPassword(NAME_PASS);
		return factory.newConnection();
	}
}
```

运行结果:

![](https://cdn.yangbingdong.com/img/rabbitmq-learning/basic-single-send-and-receive.png)

## Connection

`ConnectionFactory`, `Connection`, `Channel` 这三个都是RabbitMQ对外提供的API中最基本的对象, 不管是服务器端还是客户端都会首先创建这三类对象.
`ConnectionFactory`为`Connection`的制造工厂.
`Connection`是与RabbitMQ服务器的socket链接, 它封装了socket协议及身份验证相关部分逻辑.
`Channel`是我们与RabbitMQ打交道的最重要的一个接口, 大部分的业务操作是在Channel这个接口中完成的, 包括定义Queue, 定义Exchange, 绑定Queue与Exchange, 发布消息等.

## Queue

Queue是RabbitMQ的内部对象, 用于存储消息, RabbitMQ中的消息都只能存储在Queue中, 生产者生产消息并最终投递到Queue中, 消费者可以从Queue中获取消息并消费. 队列是有Channel声明的, 而且这个操作是幂等的, 同名的队列多次声明也只会创建一次.

## Exchange

> RabbitMQ消息模式的核心理念是: 生产者没有直接发送任何消费到队列. 实际上, 生产者都不知道这个消费是发送给哪个队列的.
>
> 相反, 生产者只能发送消息给转发器, 转发器是非常简单的. 一方面它接受生产者的消息, 另一方面向队列推送消息. 转发器必须清楚的知道如何处理接收到的消息. 附加一个特定的队列吗? 附加多个队列? 或者是否丢弃? 这些规则通过转发器的类型进行定义.
>
> 类型有: `Direct`, `Topic`, `Headers`和`Fanout`

### fanout exchange

发送到该交换器的所有消息, 会被路由到其绑定的所有队列. 该交换器不需要指定routingKey.

### direct exchange

发送到该交换器的消息, 会通过路由键完全匹配, 匹配成功就会路由到指定队列.

发送到 `direct exchange` 的消息, 会通过消息的 `routing key` 路由:

- 如果 `routing key` 值为 `queue.direct.key1`, 会路由到 `QUEUE-1`
- 如果 `routing key` 值为 `queue.direct.key2`, 会路由到 `QUEUE-2`
- 如果 `routing key` 值为其他, 不会路由到任何队列

### topic exchange

发送到该交换器的消息, 会通过路由键模糊匹配, 匹配成功就会路由到指定队列, 路由键通过 `.` 来划分为多个单词,  `*` 匹配一个单词,  `#` 匹配零个或多个单词.

发送到 `topic exchange` 的消息, 会通过消息的 `routing key` 模糊匹配再路由:

- 如果 `routing key` 值为 `queue.topic.key1`, 会路由到 `QUEUE-1` 和 `QUEUE-2`
- 如果 `routing key` 值为 `test.topic.key2`, 会路由到 `QUEUE-1`
- 如果 `routing key` 值为 `queue`, 会路由到 `QUEUE-2`
- 如果 `routing key` 值为 `queue.hello`, 会路由到 `QUEUE-2`
- 如果 `routing key` 值为 `test.test.test`, 不会路由到任何队列

### header exchange

发送到该交换器的消息, 会通过消息的 `header` 信息匹配, 匹配成功就会路由到指定队列.

消息的 `header` 信息是 `key-value` 的形式, 每条消息可以包含多条 `header` 信息, 路由规则是通过 `header` 信息的 `key` 来匹配的, Spring Boot 封装的匹配规则有三种:

- `where(key).exists()` :匹配单个 `key`
- `whereAll(keys).exist()` :同时匹配多个 `key`
- `whereAny(keys).exist()` :匹配多个 `key` 中的一个或多个

发送到 `headers exchange` 的消息, 会通过消息的 `header` 匹配:

```java
@Bean
Binding bindingHeadersQueue1(Queue headersQueue1, HeadersExchange headersExchange) {
	return BindingBuilder.bind(headersQueue1).to(headersExchange).where("one").exists();
}

@Bean
Binding bindingHeadersQueue2(Queue headersQueue1, HeadersExchange headersExchange) {
	return BindingBuilder.bind(headersQueue1).to(headersExchange).whereAll("all1", "all2").exist();
}

@Bean
Binding bindingHeadersQueue3(Queue headersQueue3, HeadersExchange headersExchange) {
	return BindingBuilder.bind(headersQueue3).to(headersExchange).whereAny("any1", "any2").exist();
}
```

- 如果 `header` 信息存在 `one=XXXX`, 会路由到 `QUEUE-1`
- 如果 `header` 信息存在 `all1=XXXX` 和 `all2=XXXX`, 会路由到 `QUEUE-2`
- 如果 `header` 信息存在 `any1=XXXX` 或 `any2=XXXX`, 会路由到 `QUEUE-3`

> `header` 不能以 `x-` 开头, 参考官方文档:https://www.rabbitmq.com/tutorials/amqp-concepts.html#exchange-headers

# Spring AMQP的几个参数说明

```
spring:
  rabbitmq:
    addresses: 127.0.0.1:5672
    username: rabbitmq
    password: rabbitmq
    virtual-host: /
    connection-timeout: 15000

    ## 生产者配置
    # 消息到达 exchange ack
    publisher-confirm-type: correlated
    # 消息被路由到队列 ack
    publisher-returns: true
    template:
      # 必须开启这个才会触发 return callback
      mandatory: true

    ## 消费端配置
    listener:
      simple:
        #消费并发消费数量, 默认为1
        concurrency: 1
        #最大消费端数
        max-concurrency: 1
        #自动签收auto  手动 manual
        acknowledge-mode: manual
        #限流（海量数据，同时只能过来一条）
        prefetch: 1
```

# ListenerContainer线程池配置

默认一个消费者对应一个新的线程, 可配置共享线程池节约线程.

## Spring AMQP

Spring Boot 的相关配置在 `RabbitAutoConfiguration` -> `RabbitAnnotationDrivenConfiguration`.

ListernContainer的线程池可以配置在 `SimpleRabbitListenerContainerFactory` 中:

```java
@Bean(name = "rabbitListenerContainerFactory")
public SimpleRabbitListenerContainerFactory simpleRabbitListenerContainerFactory(
        SimpleRabbitListenerContainerFactoryConfigurer configurer,
        ConnectionFactory connectionFactory) {
    SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
    ThreadPoolTaskExecutor taskExecutor = new ThreadPoolTaskExecutor();
    taskExecutor.setCorePoolSize(16);
    taskExecutor.setMaxPoolSize(16);
    taskExecutor.setQueueCapacity(500);
    taskExecutor.setKeepAliveSeconds(60);
    taskExecutor.setWaitForTasksToCompleteOnShutdown(true);
    taskExecutor.setThreadNamePrefix("rabbitExecutor-");
    taskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
    taskExecutor.initialize();
    factory.setTaskExecutor(taskExecutor);
    configurer.configure(factory, connectionFactory);
    return factory;
}
```

## Spring Cloud Stream

对于 Spring Cloud Stream, 可以实现 `ListenerContainerCustomizer` 接口定制化配置:

```java
public class CustomListenerContainerCustomizer implements ListenerContainerCustomizer {

	@Override
	public void configure(Object container, String destinationName, String group) {
		if (container instanceof SimpleMessageListenerContainer) {
			if (destinationName.equals(MEIYA_QUEUE_ANALIFEBANK_QUEUE)) {
				SimpleMessageListenerContainer simpleMessageListenerContainer = (SimpleMessageListenerContainer) container;
                ThreadPoolTaskExecutor taskExecutor = new ThreadPoolTaskExecutor();
                taskExecutor.setCorePoolSize(16);
                taskExecutor.setMaxPoolSize(16);
                taskExecutor.setQueueCapacity(500);
                taskExecutor.setKeepAliveSeconds(60);
                taskExecutor.setWaitForTasksToCompleteOnShutdown(true);
                taskExecutor.setThreadNamePrefix("rabbitExecutor-");
                taskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
                taskExecutor.initialize();
                simpleMessageListenerContainer.setTaskExecutor(taskExecutor);
			}
		}
	}
}
```

# 持久化

开启消息持久化可在RabbitMQ重启后不丢失消息.

> 在Docker中, 数据存放在 `/var/lib/rabbitmq` .

## Spring AMQP

在Spring AMQP中, 通过Queue构造器可指定持久化是否开启:

```java
@Bean
public Queue delayQueue() {
	return new Queue(DELAY_QUEUE, true);
}
```

第二个参数指的是是否开启持久化:

![](https://cdn.yangbingdong.com/img/rabbitmq-learning/queue-constructor01.png)

![](https://cdn.yangbingdong.com/img/rabbitmq-learning/queue-constructor02.png)

ExChange 指定持久化也一样:

![](https://cdn.yangbingdong.com/img/rabbitmq-learning/exchange-constructor.png)

## Spring Cloud Stream

在Spring Cloud Stream中指定Queue与Exchange持久化只需要通过以下两个参数配置, 默认值都为 `true`:

```
spring.cloud.stream.rabbit.bindings.<channelName>.consumer.durableSubscription=
spring.cloud.stream.rabbit.bindings.<channelName>.consumer.exchangeDurable=
```

# 手动ACK

在Spring AMQP中ACK是自动完成的, 如果报错了, 消息不会丢失, 但是会无限循环消费, 一直报错, 如果开启了错误日志很容易就把磁盘空间耗完.

在Spring Cloud Stream中默认情况下会自动重试3次, 再自动ACK. 可通过 `maxAttempts` 参数指定重试次数. 

## 配置

### Spring Cloud Stream

```
spring.cloud.stream.rabbit.bindings.<channelName>.consumer.acknowledgeMode=MANUAL
```

### Spring AMQP

```
spring.rabbitmq.listener.simple.acknowledge-mode=MANUAL
```

## 代码示例

### Spring Cloud Stream

```java
@EnableBinding(AckTopic.class)
@Component
@Slf4j
public class AckTopicListener {

	@StreamListener(AckTopic.INPUT)
	public void receive(Message<String> message, @Header(AmqpHeaders.CHANNEL) Channel channel,
						@Header(AmqpHeaders.DELIVERY_TAG) Long deliveryTag) throws Exception {
		log.info("Received: " + message.getPayload());
		channel.basicAck(deliveryTag, false);
	}
}
```

* 使用 `channel.basicAck(deliveryTag, false)` 进行ACK.
* `Channel` 也可以通过 `message.getHeaders().get(AmqpHeaders.CHANNEL, Channel.class)` 获取, `deliveryTag` 也一样.

### Spring AMQP

```java
@Component
@Slf4j
public class RabbitConsumer {

    @RabbitListener(queues = "ack_queue")
    public void handler(List<Integer> list, Message message, Channel channel) throws IOException {
        try {
            dosomething.....
            channel.basicAck(message.getMessageProperties().getDeliveryTag(), false);
        } catch (Exception e) {
            log.error("============消费失败,尝试消息补发再次消费!==============");
            log.error(e.getMessage());
            /**
             * basicRecover方法是进行补发操作, 
             * 其中的参数如果为true是把消息退回到queue但是有可能被其它的consumer(集群)接收到, 
             * 设置为false是只补发给当前的consumer
             */
            channel.basicRecover(false);
        }
    }
}

```

# Spring Cloud Stream消费失败处理

## 重试

Spring Cloud Stream 中, 如果消息处理失败, 默认会自动重试三次, 可以通过一下参数配置:

```
spring.cloud.stream.bindings.<channelName>.consumer.max-attempts=1
```

>  一般地, 如果这个消息因为代码缺陷而失败, 那么无论重试多少次都是失败的. 所以个人觉得这个还是设置为1比较合适.

## 自定义错误处理

```yaml
spring:
  cloud:
    stream:
      default:
        contentType: application/json
        consumer:
          maxAttempts: 1
      bindings:
        error-topic-output:
          destination: error-topic
        error-topic-input:
          destination: error-topic
          group: test
```

```java
public interface ErrorTopic {
	String OUTPUT = "error-topic-output";
	String INPUT = "error-topic-input";

	@Output(OUTPUT)
	MessageChannel output();

	@Input(INPUT)
	SubscribableChannel input();
}
```

```java
@EnableBinding(ErrorTopic.class)
@Component
@Slf4j
public class ErrorTopicListener {

	@StreamListener(ErrorTopic.INPUT)
	public void receive(String payload) {
		log.info("Received: " + payload);
		throw new IllegalArgumentException("模拟一个异常");
	}

	@ServiceActivator(inputChannel = "error-topic.test.errors")
	public void error(Message<?> message) throws InterruptedException {
		log.info("Message consumer failed, call fallback! Message: {}", message);
	}

}
```

通过使用`@ServiceActivator(inputChannel = "error-topic.test.errors")`指定了某个通道的错误处理映射。其中，`inputChannel`的配置中对应关系如下：

- `error-topic`：对应 `destination`
- `test`：对应 `group`

运行结果:

![](https://cdn.yangbingdong.com/img/rabbitmq-learning/rabbit-error-custom-hendle.png)

> 这种方式一般比较适合有明确的错误处理, 应用场景比较少.

## DLQ队列

通过下面参数开启DLQ转发:

```
spring.cloud.stream.rabbit.bindings.<channelName>.consumer.auto-bind-dlq=true
```

当消息消费失败后, 消息会原封不动地转发到 `error-topic.test.dlq` 这个死信队列中.

![](https://cdn.yangbingdong.com/img/rabbitmq-learning/rabbit-error-dlq01.png)

点击进入死信队列, 可以使用 `Get Message` 查看消息, `Move message` 可以将消息移动到原先的队列中继续消费.

![](https://cdn.yangbingdong.com/img/rabbitmq-learning/rabbit-error-dlq02.png)

**设置死信队列消息过期时间**:

如果某些消息存在时效性, 可通过一下参数配置过期时间, 超过时间后, 消息会自动移除掉:

```
spring.cloud.stream.rabbit.bindings.<channelName>.consumer.dlq-ttl=10000
```

将异常信息放到消息header中:

```
spring.cloud.stream.rabbit.bindings.<channelName>.consumer.republish-to-dlq=true
```

![](https://cdn.yangbingdong.com/img/rabbitmq-learning/rabbit-error-dlq03.png)

## 重新入队

重新入队是指消息消费失败了之后, 消息将不会被抛弃, 而是重新放入队列中. 

可以通过以下参数开启:

```
spring.cloud.stream.rabbit.bindings.<channelName>.consumer.requeue-rejected=true
```

这样会导致一个问题就是, 业务代码的缺陷导致的异常, 无论消费多少次, 这个消息总是失败的. 那么会导致消息堆积越来越大, 那么可以通过配合DLQ来避免这个情况:

```
spring.cloud.stream.rabbit.bindings.<channelName>.consumer.auto-bind-dlq=true
```

然后到达一定重试次数之后抛出 `AmqpRejectAndDontRequeueException` 这个指定的异常, 消息就会被推到死信队列中了:

```java
@StreamListener(TestTopic.INPUT)
public void receive(String payload) {
    log.info("Received payload : " + payload + ", " + count);
    if (count == 3) {
        count = 1;
        throw new AmqpRejectAndDontRequeueException("tried 3 times failed, send to dlq!");
    } else {
        count ++;
        throw new RuntimeException("Message consumer failed!");
    }
}
```

**总结**:

上面介绍了几种Spring Cloud Stream RabbitMQ中的重试策略, 个人认为比较适合实际业务场景的做法是, 失败后, 将消息持久化到数据库中, 后续再通过邮件或钉钉等方式通知开发人员进行处理. 因为一般场景下 , 绝大部分的异常消息都是由于业务代码的缺陷导致的, 所以怎么重试都会失败, 并且消费逻辑中一定要做好**幂等**校验.

# Spring Cloud Stream 消息路由到不同的处理逻辑

通过设置header可以实现逻辑路由:

```java
testTopic.output().send(MessageBuilder.withPayload(message).setHeader("version", "1.0").build());
            testTopic.output().send(MessageBuilder.withPayload(message).setHeader("version", "2.0").build());
```

处理: 

```java
@StreamListener(value = TestTopic.INPUT, condition = "headers['version']=='1.0'")
public void receiveV1(String payload, @Header("version") String version) {
	log.info("Received v1 : " + payload + ", " + version);
}

@StreamListener(value = TestTopic.INPUT, condition = "headers['version']=='2.0'")
public void receiveV2(String payload, @Header("version") String version) {
	log.info("Received v2 : " + payload + ", " + version);
}
```

# 延迟队列

## 实现方式

RabbitMQ的延迟队列可以通过**死信队列**来实现, 但这种方式显得比较臃肿并且有致命的缺陷(设置了不同的过期时间, 队列并不会按照这些过期时间来顺序消费), 具体请参考:  ***[springboot整合rabbitmq实现延时队列之TTL方式](https://blog.csdn.net/eumenides_/article/details/86025773)*** 

比较优雅的方式是通过 `rabbitmq_delayed_message_exchange` 插件来实现延迟队列. 插件介绍可查看官网: ***[https://www.rabbitmq.com/blog/2015/04/16/scheduling-messages-with-rabbitmq/](https://www.rabbitmq.com/blog/2015/04/16/scheduling-messages-with-rabbitmq/)***

流程大概是这样的:

1: 生产者将消息(msg)和路由键(routekey)发送指定的延时交换机(exchange)上

2: 延时交换机(exchange)存储消息等待消息到期根据路由键(routekey)找到绑定自己的队列(queue)并把消息给它

3: 队列(queue)再把消息发送给监听它的消费者(customer）

## 插件安装

> 只有RabbitMQ 3.6.x以上才支持

这里使用Docker部署, `rabbitmq_delayed_message_exchange`插件需要到 ***[官网下载](https://www.rabbitmq.com/community-plugins.html)***.

![](https://cdn.yangbingdong.com/img/rabbitmq-learning/rabbitmq-x-delay-plugin.png)

Dockerfile:

```
FROM rabbitmq:3.7-management
COPY --chown=rabbitmq:rabbitmq rabbitmq_delayed_message_exchange-20171201-3.7.x.ez /opt/rabbitmq/plugins/
COPY --chown=rabbitmq:rabbitmq enabled_plugins /etc/rabbitmq/enabled_plugins
```

enable_plugins:

```
[rabbitmq_delayed_message_exchange,rabbitmq_management].
```

> **注意**: 插件需要解压放到Dockerfile根目录.

或者这个Dockerfile也可以:

```
FROM rabbitmq:3.7-management
COPY --chown=rabbitmq:rabbitmq rabbitmq_delayed_message_exchange-20171201-3.7.x.ez /opt/rabbitmq/plugins/
RUN rabbitmq-plugins enable rabbitmq_delayed_message_exchange
```

构建:

```
docker build -t my-rabbitmq .
```

## 代码示例

### Spring Cloud Stream

`application.yml`:

```yaml
spring:
  application:
    name: rabbitmq-learning
  rabbitmq:
    host: 192.168.6.113
    port: 5672
    username: rabbitmq
    password: rabbitmq
  profiles:
    include: stream-rabbitmq-delay
```

`application-stream-rabbitmq-delay.yml`:

```yaml
spring:
  cloud:
    stream:
      default:
        contentType: application/json
        consumer:
          maxAttempts: 1
      bindings:
        delay-topic-output:
          destination: delay-topic
        delay-topic-input:
          destination: delay-topic
          group: test
      rabbit:
        bindings:
          delay-topic-output:
            producer:
              delayedExchange: true
          delay-topic-input:
            consumer:
              delayedExchange: true
```

* `delayedExchange` 设置为`true`表示将 `exchange` 声明为 `Delayed Message Exchange`. **生产者以及消费者都需要配置**这个, 否则会报以下错误:

```
Channel shutdown: channel error; protocol method: #method<channel.close>(reply-code=406, reply-text=PRECONDITION_FAILED - inequivalent arg 'type' for exchange 'delay-topic' in vhost '/': received 'topic' but current is ''x-delayed-message'', class-id=40, method-id=10)
```

代码:

```java
public interface DelayTopic {
	String OUTPUT = "delay-topic-output";
	String INPUT = "delay-topic-input";

	@Output(OUTPUT)
	MessageChannel output();

	@Input(INPUT)
	SubscribableChannel input();
}
```

```java
@EnableBinding(DelayTopic.class)
@Component
@Slf4j
public class DelayTopicListener {

	@StreamListener(DelayTopic.INPUT)
	public void receive(String payload) {
		log.info("Received: " + payload);
	}
}
```

发送延迟消息:

```java
public class XDelaySender extends SpringBootRabbitmqApplicationTests {

	@Autowired
	private DelayTopic delayTopic;


	@Test
	public void sendDelay() {
		delayTopic.output().send(MessageBuilder.withPayload("Hello World ").setHeader("x-delay", 5000).build());
	}
}
```

运行结果, 可以看到发送与接受之间差了5秒:

![](https://cdn.yangbingdong.com/img/rabbitmq-learning/stream-rabbit-delay01.png)

![](https://cdn.yangbingdong.com/img/rabbitmq-learning/stream-rabbit-delay02.png)

### Spring AMQP

Configuration:

```java
@Configuration
public class RabbitMqConfiguration {

	@Bean
	public CustomExchange delayExchange() {
		Map<String, Object> args = new HashMap<>();
		args.put(X_DELAYED_TYPE_KEY, X_DELAYED_TYPE_VALUE);
		return new CustomExchange(DELAY_EXCHANGE, DELAY_EXCHANGE_TYPE, true, false, args);
	}

	@Bean
	public Queue delayQueue() {
		return new Queue(DELAY_QUEUE, true);
	}

	@Bean
	public Binding delayBinging() {
		return BindingBuilder.bind(delayQueue()).to(delayExchange()).with(DELAY_ROUTING_KEY).noargs();
	}
}
```

常量类:

```java
public final class MqConstant {

	public static final String X_DELAYED_TYPE_KEY = "x-delayed-type";

	public static final String X_DELAYED_TYPE_VALUE = "direct";

	public static final String DELAY_EXCHANGE_TYPE = "x-delayed-message";

	public static final String DELAY_EXCHANGE = "delay_exchange";

	public static final String DELAY_QUEUE = "delay_queue.ybd";

	public static final String DELAY_ROUTING_KEY = "delay_routing_key";

}
```

生产者:

```java
@Component
@Slf4j
public class RabbitProduct {

	@Autowired
	private RabbitTemplate rabbitTemplate;

	public void sendDelayMessage(User user, Integer delay) {
		log.info("发送时间:{},发送内容:{}", LocalDateTime.now(), user);
		rabbitTemplate.convertAndSend(
				DELAY_EXCHANGE,
				DELAY_ROUTING_KEY,
				user,
				message -> {
					message.getMessageProperties().setDelay(delay);
					return message;
				}
		);
	}
}
```

消费者:

```java
@Component
@Slf4j
public class RabbitConsumer {

	@RabbitListener(queues = MqConstant.DELAY_QUEUE)
	public void delayQueueListener(User user, Message message, Channel channel) throws IOException {
		log.info("接收时间:{},接受内容:{}", LocalDateTime.now(), user);
		try {
			System.out.println("处理业务逻辑中");
		} catch (Exception e) {
		}
	}
}
```

## 查看延迟消息数量:

这个可以通过RabbitMQ的管理页面查看:

![](https://cdn.yangbingdong.com/img/rabbitmq-learning/x-dalay-admin01.png)

![](https://cdn.yangbingdong.com/img/rabbitmq-learning/x-dalay-admin02.png)

# 独占队列

某些场景下, 我们对消息的处理具有**严格的顺序**依赖性, 比如下一个消息的处理需要基于上一个消息的处理结果.

这时候, 一般比较暴力的做法就是只部署一台消费者. 还有另外一种做法便是独占队列.

以RabbitMQ为例, 使用注解的话只需要多加一个 `exclusive = true` 的参数:

```java
@RabbitListener(queues = "${items.updated.queue}", exclusive = true)
```

Spring Cloud Stream 配置:

```yaml
spring:  
  cloud:
    stream:
      default:
        contentType: application/json
        consumer:
          max-attempts: 1
      bindings:
        input:
          binder: rabbit
          destination: test_queue
          group: test_group
        output :
          binder: rabbit
          destination: test_queue
      rabbit:
        bindings:
          input:
            consumer:
              # 消费者启用独占模式
              exclusive: true
              # 如果多个消费者则只有一个成功, 其他的消费者会不断地进行重试, 默认间隔为 5000ms
              recoveryInterval: 600000
```

* `recoveryInterval`: 由于RabbitMq的独占队列只有一个消费者能成功订阅, 后面的消费者都会失败并不断地重试, 我们可以将重试时间调大一点(默认为5000ms).

并且会有一个 WARN 级别的日志打印出来, 我们可以自己实现 `ConditionalExceptionLogger` 接口将日志改为 INFO 级别:

```java
public class CustomConditionalExceptionLogger implements ConditionalExceptionLogger {

	@Override
	public void log(Log logger, String message, Throwable t) {
		logger.info("Exclusive fail");
	}
}
```

注入到 `SimpleMessageListenerContainer`:

```java
public class CustomListenerContainerCustomizer implements ListenerContainerCustomizer {

	@Override
	public void configure(Object container, String destinationName, String group) {
		if (container instanceof SimpleMessageListenerContainer) {
			if (destinationName.equals(TEST_QUEUE)) {
				SimpleMessageListenerContainer simpleMessageListenerContainer = (SimpleMessageListenerContainer) container;
				simpleMessageListenerContainer.setExclusiveConsumerExceptionLogger(new CustomConditionalExceptionLogger());
			}
		}
	}
}
```

注册到Spring容器:

```java
@Bean
public ListenerContainerCustomizer customListenerContainerCustomizer() {
	return new CustomListenerContainerCustomizer();
}
```

启用了独占模式的队列中, 可以看到这个:

![](https://cdn.yangbingdong.com/img/rabbitmq-learning/rabbitmq-exclusive.png)

# 附录

## 多Binder配置

`spring.cloud.stream.bindings.{channel-name}.binder`:设定指定通道binder名称，完全自定义；
`spring.cloud.stream.binders.{binder-name}.type`：对自定义的binder设定其类型，rabbit或者kafka；
`spring.cloud.stream.binders.{binder-name}.environment.{*}`：对自定义的binder设定其配置项，如host等；
`spring.cloud.stream.default-binder`：除了特殊的通道需要设定binder，其他的channel需要从所有自定义的binder选择一个作为默认binder，即所有非指定binder的通道均采用此`default-binder`

# Finally

> 参考:
>
> ***[https://www.kancloud.cn/longxuan/rabbitmq-arron](https://www.kancloud.cn/longxuan/rabbitmq-arron)***
>
> ***[http://blog.didispace.com/spring-cloud-starter-finchley-7-7/](http://blog.didispace.com/spring-cloud-starter-finchley-7-7/)***
>
> ***[https://blog.csdn.net/eumenides_/article/details/86025773](https://blog.csdn.net/eumenides_/article/details/86025773)***
>
> ***[https://blog.csdn.net/songhaifengshuaige/article/details/79266444](https://blog.csdn.net/songhaifengshuaige/article/details/79266444)***