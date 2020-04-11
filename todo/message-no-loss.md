> 处理消息丢失问题

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

设置 ConfirmCallback 与 ReturnCallback

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
        factory.setTaskExecutor(createRabbitThreadTaskExecutor());
        configurer.configure(factory, connectionFactory);
        factory.setMessageConverter(jackson2JsonMessageConverter());
        return factory;
    }

    private ThreadPoolTaskExecutor createRabbitThreadTaskExecutor() {
        ThreadPoolTaskExecutor taskExecutor = new ThreadPoolTaskExecutor();
        taskExecutor.setCorePoolSize(16);
        taskExecutor.setMaxPoolSize(16);
        taskExecutor.setQueueCapacity(500);
        taskExecutor.setWaitForTasksToCompleteOnShutdown(true);
        taskExecutor.setThreadNamePrefix("rabbitExecutor-");
        taskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        taskExecutor.initialize();
        return taskExecutor;
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



## MQ端

Exchange, Queue 开启持久化, MQ集群处理

## 消费者端

 