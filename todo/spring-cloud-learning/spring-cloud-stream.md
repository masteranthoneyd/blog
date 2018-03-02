## *[Spring Cloud Stream](https://cloud.spring.io/spring-cloud-stream/)*

binder:

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-learning/SCSt-with-binder.png)

group:

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-learning/SCSt-groups.png)

partitioning:

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-learning/SCSt-partitioning.png)

> 参考：***[https://docs.spring.io/spring-cloud-stream/docs/current/reference/htmlsingle/](https://docs.spring.io/spring-cloud-stream/docs/current/reference/htmlsingle/)***

### 配置消息中间件链接信息

#### RabbitMQ

```
spring:
  rabbitmq:
    host: 127.0.0.1
    port: 5673
    username: guest
    password: guest
```

> 以上是默认配置，可以不配

#### Kafka

```
spring:
  cloud:
    stream:
      kafka:
        binder:
          brokers: 127.0.0.1:9092
          zk-nodes: 127.0.0.1:2181
          auto-add-partitions: true
          auto-create-topics: true
          min-partition-count: 1
```

> 跟RabbitMQ不同，Kafka的链接配置前面多了`spring.cloud.stream`的前缀

### 定义消息通道

参考 `org.springframework.cloud.stream.messaging.Sink`、`org.springframework.cloud.stream.messaging.Source`

```
public interface ProdInput {
	String INPUT = "prodInput";

	@Input(ProdInput.INPUT)
	SubscribableChannel prodInput();
}
```

```
public interface ProdOutput {
	String OUTPUT = "prodOutput";

	@Output(ProdOutput.OUTPUT)
	MessageChannel prodOutput();
}
```

```
public interface AckInput {
	String INPUT = "ackInput";

	@Input(AckInput.INPUT)
	SubscribableChannel ackInput();
}
```

```
public interface AckOutput {
	String OUTPUT = "ackOutput";

	@Output(AckOutput.OUTPUT)
	MessageChannel ackOutput();
}
```

### 配置消息通道信息

```
prod-sync-destination: "prod-sync"
spring:
  profiles: multi
  cloud:
    stream:
      default: # 配置bindings.<channelName>默认属性
        contentType: application/json # 参考 https://docs.spring.io/spring-cloud-stream/docs/Chelsea.SR2/reference/htmlsingle/index.html#mime-types
        consumer:
          max-attempts: 1 # 消费失败重试次数，默认为3，设置为1则不重试
      bindings:
        prodInput: # 配置prodInput消息通道信息
          binder: rabbit
          destination: ${prod-sync-destination} # 定了输入通道对应的主题名
          group: service-a
        prodOutput : # 同上
          binder: rabbit
          destination: ${prod-sync-destination} # 定了输入通道对应的主题名
        ackInput:
          destination: ack
          binder: kafka
        ackOutput:
          destination: ack
          binder: kafka
```

> Spring Cloud Stream做的很灵活，可以不修改一行代码切换MQ类型，上面的配置是同时用了Kafka和RabbitMQ

### 定义生产者

```
@AllArgsConstructor
@Slf4j
@Component
@EnableBinding({ProdOutput.class, AckOutput.class})
public class MessageProducer {

	private final MessageChannel prodOutput;
	private final MessageChannel ackOutput;

	public void publishMessage(Prod prod) {
		prodOutput.send(MessageBuilder.withPayload(prod).build());
	}

	/**
	 * 间歇发射器，默认每秒一次
	 */
	@InboundChannelAdapter(channel = AckOutput.OUTPUT, poller = {@Poller(fixedDelay = "60000")})
	public String greet() {
		return "hello world " + System.currentTimeMillis();
	}
	
	@PostConstruct
	public void init() {
		log.info("injected output channel: {}, {}", prodOutput, ackOutput);
	}
}
```

### 定义消费者

```
@EnableBinding({ProdInput.class, AckOutput.class, AckInput.class})
@Log4j2
@Component
public class SinkReceiver {
	private AtomicInteger atomicInteger = new AtomicInteger(0);

	@StreamListener(ProdInput.INPUT)
	@SendTo(AckOutput.OUTPUT) //定义回执发送的消息通道
	public String receive(@Payload Prod payload, @Headers MessageHeaders headers) {
		atomicInteger.incrementAndGet();
		log.info("atomicInteger = {}, headers: {}, Received: {}", atomicInteger, headers, payload);
//		int i = 1 / 0;
		return "receive message success, and return an ack";
	}

	@StreamListener(AckInput.INPUT)
	public void receive2(Message<String> msg) {
		log.info("ACK!!!!!!! {} {}", msg);
	}
}
```

### Controller测试

```
@AllArgsConstructor
@RestController
@Slf4j
public class MessageController {

	private final MessageProducer producer;

	@GetMapping("/p/{name}")
	public String publish(@PathVariable("name") String name) {
		Prod prod = Prod.builder().id(1L).name(name).price(66.66F).desc("描述").build();
		log.info("produce a message: {}", prod);
		producer.publishMessage(prod);
		return "SUCCESS";
	}
}
```

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-learning/test01.png)

流程是这样的：

1. 请求链接
2. 处理业务并发送消息
3. 消费者接收到消息并消费
4. 消费完毕发送ACK消息
5. ACK消费者接受ACK信息并处理

### Kafka手动确认消息

首先关闭Kafka客户端自动提交：

```
spring:
  cloud:
    stream:
      kafka:
        binder:
          requiredAcks: 1 # 确认ack，默认为1
        bindings:
          prodInput:
            consumer:
              auto-commit-offset: false # 开启手动提交offset，据说可以防止生产过快
              configuration: # Map with a key/value pair containing generic Kafka producer properties.
                max.poll.records: 200 # 每次最大拉取消息数量，貌似默认为500
```

之后Kafka binder会自动把`ack mode`设置为`org.springframework.kafka.listener.AbstractMessageListenerContainer.AckMode.MANUAL`

消费者：

```
	@SuppressWarnings("ConstantConditions")
	@StreamListener(ProdInput.INPUT)
	public void receive(@Payload Prod prod, @Headers MessageHeaders headers) {
		atomicInteger.incrementAndGet();
		log.info("atomicInteger = {}, headers: {}, Received: {}", atomicInteger, headers, prod);
		Optional.ofNullable(headers.get(KafkaHeaders.ACKNOWLEDGMENT, Acknowledgment.class))
				.ifPresent(Acknowledgment::acknowledge);
	}
```

### 其他用法

#### @Transformer

```
@EnableBinding(Processor.class)
public class TransformProcessor {

  @Autowired
  VotingService votingService;

  @StreamListener(Processor.INPUT)
  @SendTo(Processor.OUTPUT)
  public VoteResult handle(Vote vote) {
    return votingService.record(vote);
  }
}
```

可以变成这样：

```
  @Transformer(inputChannel = Processor.INPUT, outputChannel = Processor.OUTPUT)
  public Object transform(Vote vote) {
    return votingService.record(vote);
  }
```

#### Dispatching消息到多个方法

```
@EnableBinding(Sink.class)
@EnableAutoConfiguration
public static class TestPojoWithAnnotatedArguments {

    @StreamListener(target = Sink.INPUT, condition = "headers['type']=='foo'")
    public void receiveFoo(@Payload FooPojo fooPojo) {
       // handle the message
    }

    @StreamListener(target = Sink.INPUT, condition = "headers['type']=='bar'")
    public void receiveBar(@Payload BarPojo barPojo) {
       // handle the message
    }
}
```

#### Reactor支持

```
@EnableBinding(Processor.class)
@EnableAutoConfiguration
public static class UppercaseTransformer {

  @StreamListener
  @Output(Processor.OUTPUT)
  public Flux<String> receive(@Input(Processor.INPUT) Flux<String> input) {
    return input.map(s -> s.toUpperCase());
  }
}
```

或者：

```
@EnableBinding(Processor.class)
@EnableAutoConfiguration
public static class UppercaseTransformer {

  @StreamListener
  public void receive(@Input(Processor.INPUT) Flux<String> input,
     @Output(Processor.OUTPUT) FluxSender output) {
     output.send(input.map(s -> s.toUpperCase()));
  }
}
```

#### 链接多个MQ

```
spring:
  cloud:
    stream:
      bindings:
        input:
          destination: foo
          binder: rabbit1
        output:
          destination: bar
          binder: rabbit2
      binders:
        rabbit1:
          type: rabbit
          environment:
            spring:
              rabbitmq:
                host: <host1>
        rabbit2:
          type: rabbit
          environment:
            spring:
              rabbitmq:
                host: <host2>
```

