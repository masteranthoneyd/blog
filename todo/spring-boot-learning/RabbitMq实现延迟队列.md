# RabbitMq实现延迟队列

使用`rabbitmq_delayed_message_exchange`插件实现延迟队列.

流程大概是这样的:

1: 生产者将消息(msg)和路由键(routekey)发送指定的延时交换机(exchange)上

2: 延时交换机(exchange)存储消息等待消息到期根据路由键(routekey)找到绑定自己的队列(queue)并把消息给它

3: 队列(queue)再把消息发送给监听它的消费者(customer）

## RabbitMq部署以及插件安装

这里使用Docker部署, `rabbitmq_delayed_message_exchange`插件需要到官网 ***[下载](https://www.rabbitmq.com/community-plugins.html)***.

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

构建:

```
docker build -t my-rabbitmq .
```

使用Docker Compose启动:

```yaml
version: '3.7'

services:
  rabbitmq:
    image: my-rabbitmq:latest
    restart: always
    ports:
      - "5672:5672"
      - "15672:15672"
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

## 项目配置

pom.xml:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```

application.yml:

```yaml
spring:  
  rabbitmq:
    host: 192.168.6.113
    port: 5672
    username: rabbitmq
    password: rabbitmq
```

## 示例代码

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

# 独占队列

某些场景下, 我们对消息的处理具有严格的顺序依赖性, 比如下一个消息的处理需要基于上一个消息的处理结果.

这时候, 一般比较暴力的做法就是只部署一台消费者. 还有另外一种做法便是独占队列.

以RabbitMq为例, 使用注解的话只需要多加一个 `exclusive = true` 的参数:

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

由于RabbitMq的独占队列只有一个消费者能成功订阅, 后面的消费者都会失败并不断地重试, 我们可以将重试时间调大一点(默认为5000ms).

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



>  参考: 
>
> ***[http://blog.didispace.com/spring-cloud-starter-finchley-7-7/](http://blog.didispace.com/spring-cloud-starter-finchley-7-7/)***
>
> ***[https://blog.csdn.net/eumenides_/article/details/86025773](https://blog.csdn.net/eumenides_/article/details/86025773)***