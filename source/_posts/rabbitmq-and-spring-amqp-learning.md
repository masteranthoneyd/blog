---
title: Rabbit & Spring AMQP 入门
date: 2019-04-25 16:44:51
categories: [Programming, Java]
tags: [Java, Spring Boot, Spring Cloud, RabbitMQ]
---

![](https://oldcdn.yangbingdong.com/img/rabbitmq-learning/spring-rabbitmq-banner.png)

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

![](https://oldcdn.yangbingdong.com/img/rabbitmq-learning/basic-single-send-and-receive.png)

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

![](https://oldcdn.yangbingdong.com/img/rabbitmq-learning/queue-constructor01.png)

![](https://oldcdn.yangbingdong.com/img/rabbitmq-learning/queue-constructor02.png)

ExChange 指定持久化也一样:

![](https://oldcdn.yangbingdong.com/img/rabbitmq-learning/exchange-constructor.png)

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

# Spring Boot 中使用方式

## 创建队列交换机

### 通过@RabbitListener创建

```java
@RabbitListener(
        bindings = @QueueBinding(
                value = @Queue(value = "test-topic",durable = "true"),
                exchange = @Exchange(name = "test-topic"),
                key="test-topic"
        )
)
@RabbitHandler
public void onMessage(@Payload TestMessage testMessage, @Headers Map<String,Object> headers, Channel channel) throws Exception {
    try {
        log.info("收到消息, 当前线程: {}, 消息内容: {}", Thread.currentThread().getId(), testMessage);
    } catch (Exception e) {
        // 更新为消费失败
        log.error("消费异常");
    } finally {
        // multiple 为 true 代表批量确认
        channel.basicAck((Long) headers.get(AmqpHeaders.DELIVERY_TAG),false);
    }
}
```

### 通过声明Bean创建

```java
@Bean
public Queue delayQueue() {
    return new Queue(DELAY_QUEUE, true, false, false);
}
```

### 通过RabbitAdmin动态注册

```java
@Bean
public RabbitAdmin rabbitAdmin(ConnectionFactory connectionFactory) {
    return new RabbitAdmin(connectionFactory);
}
```

```java
@Configuration
@PropertySource(factory = YamlPropertySourceFactory.class, value = "classpath:MQ-CONF/topic.yml")
@EnableConfigurationProperties(MessagingProperty.class)
public class MessagingConfiguration implements InitializingBean {

    private final MessagingProperty messagingProperty;
    private final RabbitAdmin rabbitAdmin;

    public MessagingConfiguration(MessagingProperty messagingProperty, RabbitAdmin rabbitAdmin) {
        this.messagingProperty = messagingProperty;
        this.rabbitAdmin = rabbitAdmin;
    }

    @Override
    public void afterPropertiesSet() {
        if (MqType.RABBIT.equals(messagingProperty.getMqType())) {
            registryRabbit(messagingProperty);
        }
    }

    private void registryRabbit(MessagingProperty messagingProperty) {
        for (MessagingProperty.Topic topic : messagingProperty.getTopics()) {
            String topicName = topic.getName();
            Queue queue = new Queue(topicName, true, false, false);
            DirectExchange exchange = new DirectExchange(topicName, true, false);
            exchange.setDelayed(parseBoolean(topic.getProperties().getOrDefault("delayed", "false")));
            Binding binding = BindingBuilder.bind(queue).to(exchange).with(topicName);
            rabbitAdmin.declareQueue(queue);
            rabbitAdmin.declareExchange(exchange);
            rabbitAdmin.declareBinding(binding);
        }
    }
}
```

`topic.yml`:

```yml
messaging:
  mqType: rabbit
  topics:
    - name: test-topic
      properties:
        delayed: true
```

## 监听

```java
@Component
@Slf4j
public class RabbitMqConsumer {

    @RabbitListener(queues = "test-topic")
    public void onOrderMessage(@Payload TestMessage testMessage, @Headers Map<String,Object> headers, Channel channel) throws Exception {
        try {
            log.info("收到消息, 当前线程: {}, 消息内容: {}", Thread.currentThread().getId(), testMessage);
        } catch (Exception e) {
            // 更新为消费失败
            log.error("消费异常");
        } finally {
            // multiple 为 true 代表批量确认
            channel.basicAck((Long) headers.get(AmqpHeaders.DELIVERY_TAG),false);
        }
    }
}
```

`@RabbitListener`注解的消费者监听方法, 默认有几个可以自动注入的参数对象:

* `org.springframework.amqp.core.Message` 消息原始对象
* `com.rabbitmq.client.Channel` 接收消息所所在的`channel`
* `org.springframework.messaging.Message` amqp的原始消息对象转换为messaging后的消息对象, 该消息包含自定义消息头和标准的amqp消息头

此外, 非以上参数, 自定义参数对象可以通过`@Header`/`@Headers`/`@Payload`标注为消息头或消息体接受对象.

也可以通过 Bean 注册监听器:

```java

@Bean
public SimpleMessageListenerContainer messageListenerContainer(ConnectionFactory connectionFactory) {
    SimpleMessageListenerContainer container = new SimpleMessageListenerContainer();
    container.setConnectionFactory(connectionFactory);
    container.setQueueNames(QUEUE_NAME);
    container.setAcknowledgeMode(AcknowledgeMode.MANUAL);
    container.setMessageListener((ChannelAwareMessageListener) (message, channel) -> {
        log.info(ACK_QUEUE_A + "get msg:" +new String(message.getBody()));
        if(message.getMessageProperties().getHeaders().get("error") == null){
            // 消息手动ack
            channel.basicAck(message.getMessageProperties().getDeliveryTag(),false);
            log.info("消息确认");
        }else {
            // 消息重新回到队列
            //channel.basicNack(message.getMessageProperties().getDeliveryTag(),false,false);
            // 拒绝消息（删除）
            channel.basicReject(message.getMessageProperties().getDeliveryTag(),false);
            log.info("消息拒绝");
        }
 
    });
    return container;
```



# DLQ队列

通过下面参数开启DLQ转发:

```
spring.cloud.stream.rabbit.bindings.<channelName>.consumer.auto-bind-dlq=true
```

当消息消费失败后, 消息会原封不动地转发到 `error-topic.test.dlq` 这个死信队列中.

![](https://oldcdn.yangbingdong.com/img/rabbitmq-learning/rabbit-error-dlq01.png)

点击进入死信队列, 可以使用 `Get Message` 查看消息, `Move message` 可以将消息移动到原先的队列中继续消费.

![](https://oldcdn.yangbingdong.com/img/rabbitmq-learning/rabbit-error-dlq02.png)

**设置死信队列消息过期时间**:

如果某些消息存在时效性, 可通过一下参数配置过期时间, 超过时间后, 消息会自动移除掉:

```
spring.cloud.stream.rabbit.bindings.<channelName>.consumer.dlq-ttl=10000
```

将异常信息放到消息header中:

```
spring.cloud.stream.rabbit.bindings.<channelName>.consumer.republish-to-dlq=true
```

![](https://oldcdn.yangbingdong.com/img/rabbitmq-learning/rabbit-error-dlq03.png)

# 重新入队

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

![](https://oldcdn.yangbingdong.com/img/rabbitmq-learning/rabbitmq-x-delay-plugin.png)

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

![](https://oldcdn.yangbingdong.com/img/rabbitmq-learning/stream-rabbit-delay01.png)

![](https://oldcdn.yangbingdong.com/img/rabbitmq-learning/stream-rabbit-delay02.png)

### Spring AMQP

Configuration:

```java
@Configuration
public class RabbitMqConfiguration {

	@Bean
	public DirectExchange delayExchange() {
        DirectExchange exchange = new DirectExchange(topicName, true, false, false);
        exchange.setDelayed(true);
	}

	@Bean
	public Queue delayQueue() {
		return new Queue(DELAY_QUEUE, true, false, false);
	}

	@Bean
	public Binding delayBinging() {
		return BindingBuilder.bind(delayQueue()).to(delayExchange()).with(DELAY_ROUTING_KEY);
	}
}
```

常量类:

```java
public final class MqConstant {

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

## 查看延迟消息数量

这个可以通过RabbitMQ的管理页面查看:

![](https://oldcdn.yangbingdong.com/img/rabbitmq-learning/x-dalay-admin01.png)

![](https://oldcdn.yangbingdong.com/img/rabbitmq-learning/x-dalay-admin02.png)

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

![](https://oldcdn.yangbingdong.com/img/rabbitmq-learning/rabbitmq-exclusive.png)

# 附录

## 多Binder配置

`spring.cloud.stream.bindings.{channel-name}.binder`:设定指定通道binder名称，完全自定义；
`spring.cloud.stream.binders.{binder-name}.type`：对自定义的binder设定其类型，rabbit或者kafka；
`spring.cloud.stream.binders.{binder-name}.environment.{*}`：对自定义的binder设定其配置项，如host等；
`spring.cloud.stream.default-binder`：除了特殊的通道需要设定binder，其他的channel需要从所有自定义的binder选择一个作为默认binder，即所有非指定binder的通道均采用此`default-binder`

## 比较完整的配置说明

```json
spring:
  cloud:
    stream:
      binders:
        rabbit:
          type: rabbit
          environment:
            spring:
              rabbitmq:
                host: localhost
                port: 5672
                username: guest
                password: guest

      bindings:
        packetUplinkOutput:
          destination: packetUplinkTopic
          content-type: application/json
          binder: rabbit

        packetUplinkInput:
          destination: packetUplinkTopic
          content-type: application/json
          group: ${spring.application.name}
          binder: rabbit
          consumer:
            concurrency: 10 # 初始/最少/空闲时 消费者数量。默认1
            # 失败重试相关
            maxAttempts: 3 # 当消息消费失败时，尝试消费该消息的最大次数（消息消费失败后，发布者会重新投递）。默认3
            backOffInitialInterval: 1000 # 消息消费失败后重试消费消息的初始化间隔时间。默认1s，即第一次重试消费会在1s后进行
            backOffMultiplier: 2 # 相邻两次重试之间的间隔时间的倍数。默认2，即第二次是第一次间隔时间的2倍，第三次是第二次的2倍
            backOffMaxInterval: 10000 # 下一次尝试重试的最大时间间隔，默认为10000ms，即10s。
            # 分片相关
            partitioned: false # 消息 投递及消费 是否分片
            instanceIndex: -1 # 分片实例索引
            instanceCount: -1 # 分片实例数量

      rabbit:
        bindings:
          default:
            consumer:
              prefix: '' # 定义queue和exchange时名称的前缀
              # queue相关
              acknowledgeMode: AUTO # 消息的确认模式。有：NONE, MANUAL, AUTO。默认是AUTO。这里的AUTO区别于RabbitMQ的auto_ack，AUTO会根据消息正常消费或抛异常自动选择ack/nack。而NONE才对应auto_ack，MANUAL则为手动确认。
              bindQueue: true # 是否将queue绑定到目标exchange。默认true
              durableSubscription: true # queue中的消息是否序列化。只有当设置了group属性才起作用。默认true。
              exclusive: false # queue是否排外。当为true，有两个作用，一：当连接关闭时connection.close()该队列会自动删除；二：该队列是私有的private，即其它channel强制访问时会报错。
              expires: 10000000 # 当queue空闲多长时间后会被删除。
              bindingRoutingKey: '#' # 将queue绑定到exchange时使用的routing key。默认'#'
              queueNameGroupOnly: false # 默认为false。当为true时，从queue名称与属性group的值相等的队列消费消息，如果不是则为destination.group。该属性还可以用在从已存在的queue消费消息。
              prefetch: 1 # 限制consumer在消费消息时，一次能同时获取的消息数量，默认：1。
              ttl: 100000 # 默认不做限制，即无限。消息在队列中最大的存活时间。当消息滞留超过ttl时，会被当成消费失败消息，即会被转发到死信队列或丢弃
              txSize: 1 # 感觉像是批量确认的意思. 原文: The number of deliveries between acks.
              declareExchange: true # 是否声明目标exchange。默认true
              delayedExchange: false # 是否将目标exchange声明为一个延迟消息交换机，默认false。即消息productor发布消息到延迟exchange后，延迟n长时间后才将消息推送到指定的queue中。 -RabbitMQ需要安装/启用插件: rabbitmq-delayed-message-exchange
              failedDeclarationRetryInterval: 5000 # 当queue不存在时，间隔多长时间会尝试从queue消费消息，即检测queue是否恢复。
              headerPatterns: '*' # 默认：['*']。入站消息的hearders的匹配规则。是一个数组，
              lazy: false # 是否声明为lazy queue。RabbitMQ从3.6.0版本开始引入了惰性队列（Lazy Queue）的概念。惰性队列会尽可能的将消息存入磁盘中，而在消费者消费到相应的消息时才会被加载到内存中，它的一个重要的设计目标是能够支持更长的队列，即支持更多的消息存储。当消费者由于各种各样的原因（比如消费者下线、宕机亦或者是由于维护而关闭等）而致使长时间内不能消费消息造成堆积时，惰性队列就很有必要了。
              maxConcurrency: 3 # 默认：1。queue的消费者的最大数量。当前消费者数量不足以及时消费消息时, 会动态增加消费者数量, 直到到达最大数量, 即该配置的值.
              maxLength: 10000 # queue中能同时存在的最大消息条数。当超过时，会被丢到死信队列。默认没有限制
              maxLengthBytes: 100000000 # queue中能存放的消息的总占用空间，当超过时，会删除之前的消息。默认没有限制
              maxPriority: 255 # queue中消息的最大优先级。优先级高的优先被消费。消息的优先级在消息发布的时候设置。默认不做设置
              missingQueuesFatal: false # 暂时不知道用处，默认为false。官方文档介绍：If the queue cannot be found, treat the condition as fatal and stop the listener container. Defaults to false so that the container keeps trying to consume from the queue, for example when using a cluster and the node hosting a non HA queue is down.
              queueDeclarationRetries: 3 # 发现缺少对应queue时尝试重连的次数。默认3。 The number of times to retry consuming from a queue if it is missing. Only relevant if missingQueuesFatal is true; otherwise the container keeps retrying indefinitely.
              recoveryInterval: 5000 # 发现缺少对应queue时尝试重连的时间间隔，单位ms。默认5000
              requeueRejected: false # 当禁用重试（maxAttempts=1）或republishToDlq为false时，消息消费时候后是否重新加入队列，即是否丢弃该消息。

              # exchange相关
              exchangeAutoDelete: true # exchange是否自动删除（当最后一个队列移除后，exchange自动删除）。默认true。
              exchangeDurable: true # exchange是否序列化，broker重启后是否还存在。默认true。当declareExchange为true时有作用.
              exchangeType: topic # exchange的类型。默认为topic。exchange的类型。org.springframework.amqp.core.ExchangeTypes，包括：topic(默认)、direct、headers、fanout、system

              # DLQ相关
              autoBindDlq: true # 是否自动声明死信队列（DLQ）并将其绑定到死信交换机（DLX）。默认是false。
              deadLetterQueueName: 'packetUplinkTopic.scas-data-collection.dlq' # 默认prefix + destination + group + .dlq。DLQ的名称。
              deadLetterExchange: 'DLX' # 默认prefix + DLX。DLX的名称
              deadLetterRoutingKey: 'packetUplinkTopic.scas-data-collection' # 默认destination + group
              dlqExpires: 100000 # 默认不设置
              dlqLazy: false # 默认false
              dlqMaxLength: 100000 # 默认不限制
              dlqMaxLengthBytes: 100000000 # 默认不限制
              dlqMaxPriority: 255 # 默认不设置
              dlqTtl: 1000000 # 默认不限制
              republishToDlq: false # 默认false。如果定义了DLQ，当消费失败的消息重试次数耗尽后，会将消息路由到该DLQ。当为true时，死信队列接收到的消息的headers会更加丰富，多了异常信息和堆栈跟踪。
              republishDeliveryMode: DeliveryMode.PERSISTENT # 默认DeliveryMode.PERSISTENT（持久化）。当republishToDlq为true时，转发的消息的delivery mode

              # 死信队列的死信队列相关，死信队列也是一个普通队列，所以也有消费失败的消息，所以死信队列的死信队列有存在的意义。不过DLQ的DLQ不会自动生成，也只能定义DLQ的DLX。
              dlqDeadLetterExchange: 'DLX.DLX' # 默认none。DLQ的消息消费失败后转发到的exchange名称
              dlqDeadLetterRoutingKey: 'packetUplinkTopic.scas-data-collection.dlq' # 默认none。
```



# Finally

> 参考:
>
> ***[http://www.itmuch.com/tags/Spring-Cloud-Stream/](http://www.itmuch.com/tags/Spring-Cloud-Stream/)***
>
> ***[https://www.kancloud.cn/longxuan/rabbitmq-arron](https://www.kancloud.cn/longxuan/rabbitmq-arron)***
>
> ***[http://blog.didispace.com/spring-cloud-starter-finchley-7-7/](http://blog.didispace.com/spring-cloud-starter-finchley-7-7/)***
>
> ***[https://blog.csdn.net/eumenides_/article/details/86025773](https://blog.csdn.net/eumenides_/article/details/86025773)***
>
> ***[https://blog.csdn.net/songhaifengshuaige/article/details/79266444](https://blog.csdn.net/songhaifengshuaige/article/details/79266444)***