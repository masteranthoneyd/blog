> 处理消息丢失问题

![](https://cdn.yangbingdong.com/img/messagenoloss/message-no-loss.png)

防止消息丢失的套路大体流程:

生产者:

* 生产者将消息**持久化**(可以是缓存或者罗盘到DB), 标志为**待发送**
* 生产者发送消息, 在回调函数中处理成功或失败的情况, 成功则将消息标志为**已发送**或者删除

MQ:

* 集群副本保证MQ自身的高可用性

消费者:

* 开启手动 ACK
* 消费完成将消息标志为已消费(如果消息没有删除)

# RabbitMQ

## 生产者端

* 开启 Confirm 模式
* 开启 Return 模式

```yml
spring:
  rabbitmq:
    # 消息到达 exchange ack
    publisher-confirm-type: true
    # 消息被路由到队列 ack
    publisher-returns: true
    template:
      # 必须开启这个才会触发 return callback
      mandatory: true
```

设置 `ConfirmCallback` 与 `ReturnCallback`, 可改为持久化策略(先存进数据库或者缓存, 收到 ack 后将消息标志为发送成功):

```java
@Configuration
@Slf4j
public class RabbitMqConfiguration {


    @Bean
    public Jackson2JsonMessageConverter jackson2JsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @Bean(name = "rabbitListenerContainerFactory")
    public SimpleRabbitListenerContainerFactory simpleRabbitListenerContainerFactory(
            SimpleRabbitListenerContainerFactoryConfigurer configurer,
            ConnectionFactory connectionFactory) {
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        configurer.configure(factory, connectionFactory);
        factory.setMessageConverter(jackson2JsonMessageConverter());
        return factory;
    }

    @Bean
    public RabbitTemplate rabbitTemplate(RabbitProperties properties,
                                         ObjectProvider<MessageConverter> messageConverter,
                                         ConnectionFactory connectionFactory) {
        PropertyMapper map = PropertyMapper.get();
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        messageConverter.ifUnique(template::setMessageConverter);
        template.setMandatory(determineMandatoryFlag(properties));
        RabbitProperties.Template templateProperties = properties.getTemplate();
        map.from(templateProperties::getReceiveTimeout).whenNonNull().as(Duration::toMillis).to(template::setReceiveTimeout);
        map.from(templateProperties::getReplyTimeout).whenNonNull().as(Duration::toMillis).to(template::setReplyTimeout);
        map.from(templateProperties::getExchange).to(template::setExchange);
        map.from(templateProperties::getRoutingKey).to(template::setRoutingKey);
        map.from(templateProperties::getDefaultReceiveQueue).whenNonNull().to(template::setDefaultReceiveQueue);

        template.setMessageConverter(jackson2JsonMessageConverter());
        template.setConfirmCallback(new RabbitTemplate.ConfirmCallback() {
            @Override
            public void confirm(CorrelationData correlationData, boolean ack, String cause) {
                if (ack) {
                    log.info("消息已发送 Exchange 成功, correlationDataId: {}, correlationData: {}", correlationData.getId(), correlationData);
                } else {
                    log.warn("消息发送到 Exchange 失败, correlationDataId: {}, correlationData: {}, cause: {}", correlationData.getId(), correlationData, cause);
                }
            }
        });
        template.setReturnCallback(new RabbitTemplate.ReturnCallback() {
            @Override
            public void returnedMessage(Message message, int replyCode, String replyText, String exchange, String routingKey) {
                log.warn("消息路由失败, message: {}, replyCode: {}, replyText: {}, exchange: {}, routingKey: {}",
                        message, replyCode, replyText, exchange, routingKey);
            }
        });
        return template;
    }

    private boolean determineMandatoryFlag(RabbitProperties properties) {
        Boolean mandatory = properties.getTemplate().getMandatory();
        return (mandatory != null) ? mandatory : properties.isPublisherReturns();
    }
}
```

```java
@Component
public class RabbitMqPublisher implements MqPublisher {

    @Autowired
    private RabbitTemplate rabbitTemplate;

    @Override
    public void produce(MessageSupporter messageSupporter, String topic) {
        rabbitTemplate.convertAndSend(topic, topic, messageSupporter.getPayload(), new CorrelationData(messageSupporter.getId()));
    }
}
```

## MQ端

MQ集群处理, Exchange, Queue 开启持久化:

```java
@Component
@Slf4j
public class RabbitMqConsumer {

    @RabbitListener(
            bindings = @QueueBinding(
                    value = @Queue(value = "test-topic",durable = "true"),
                    exchange = @Exchange(name = "test-topic"),
                    key="test-topic"
            )
    )
    @RabbitHandler
    public void onOrderMessage(@Payload TestMessage testMessage, @Headers Map<String,Object> headers, Channel channel) throws Exception {
        try {
            log.info("收到消息, 当前线程: {}, 消息内容: {}", Thread.currentThread().getId(), testMessage);
        } catch (Exception e) {
            // 更新为消费失败
            log.error("消费异常");
        } finally {
            channel.basicAck((Long) headers.get(AmqpHeaders.DELIVERY_TAG),false);
        }
    }
}
```

## 消费者端

需要做幂等处理.

开启手动确认:

```yaml
spring:
    listener:
      simple:
        #消费端
        concurrency: 1
        #最大消费端数
        max-concurrency: 1
        #自动签收auto  手动 manual
        acknowledge-mode: manual
        #限流（海量数据, 同时只能过来一条）
        prefetch: 1
```

 ```java
@Component
@Slf4j
public class RabbitMqConsumer {

    @RabbitListener(
            bindings = @QueueBinding(
                    value = @Queue(value = "test-topic",durable = "true"),
                    exchange = @Exchange(name = "test-topic"),
                    key="test-topic"
            )
    )
    @RabbitHandler
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

# Kafka

## 生产者端

* 设置 acks 为 -1(也就是 all)
* 重试次数可以设置大一点
* 设置发送的回调函数, 在成功或失败函数中做后续处理

```yaml
spring:
  kafka:
    producer:
      retries: 3  #  重试次数
      acks: all
      client-id: ${spring.application.name}
```

```java
@Slf4j
public class KafkaProducerListener<K, V> implements ProducerListener<K, V> {

    @Override
    public void onSuccess(String topic, Integer partition, K key, V value, RecordMetadata recordMetadata) {
        log.info("Kafka produce success, topic: {}, partition: {}, K: {}, V: {}, recordMetadata: {}", topic, partition, key, value, recordMetadata);
    }

    @Override
    public void onError(String topic, Integer partition, K key, V value, Exception exception) {
        log.error("Kafka produce fail, topic: " + topic + ", partition: " + partition + ", K: " + key + ", V: " + value, exception);
    }
}
```

```java
@PropertySource(factory = YamlPropertySourceFactory.class, value = "classpath:MQ-CONF/kafka.yml")
@Configuration
public class KafkaConfiguration {

    @Bean
    public ProducerListener<Object, Object> kafkaProducerListener() {
        return new KafkaProducerListener<>();
    }
}
```

## MQ端

* Kafka 做集群处理
* 设置`unclean.leader.election.enable = false`. 这是`Broker`端的参数, 在`kafka`版本迭代中社区也多次反复修改过他的默认值, 之前比较具有争议. 它控制哪些`Broker`有资格竞选分区的`Leader`. 如果一个`Broker`落后原先的`Leader`太多, 那么它一旦成为新的`Leader`, 将会导致消息丢失. 故一般都要将该参数设置成`false`
* 设置`replication.factor >= 3`
* 设置`min.insync.replicas > 1`
* 确保 `replication.factor` > `min.insync.replicas`



## 消费者端

关闭自动提交, 确保消息消费完成再提交.

```
spring:
  kafka:
    bootstrap-servers: 127.0.0.1:9094
    consumer:
      # latest, earliest
      auto-offset-reset: earliest
      # 关闭自动提交
      enable-auto-commit: false
      group-id: messagenoloss
    listener:
      # 手动提交
      ack-mode: manual
#      concurrency: 3
```

```java
public class KafkaConsumer {

    @KafkaListener(topics = "test-topic")
    public void consumeMessage(Acknowledgment acknowledgment, ConsumerRecord<String, String> consumerRecord) {
        try {
            TestMessage testMessage = JSONObject.parseObject(consumerRecord.value(), TestMessage.class);
            log.info("消费者消费1, 当前线程: {}, topic:{} partition:{} 的消息 -> {}, consumerRecord: {}", Thread.currentThread(), consumerRecord.topic(), consumerRecord.partition(), testMessage.toString(), consumerRecord);
        } catch (Exception e) {
            log.error("Kafka 消费异常", e);
        } finally {
            acknowledgment.acknowledge();
        }
    }
}
```

