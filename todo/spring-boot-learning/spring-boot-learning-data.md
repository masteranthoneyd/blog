# JPA

## 配置数据源

> 更多请查看官方指导：***[https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#howto-configure-a-datasource](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#howto-configure-a-datasource)***

### MySQL

```
spring:
  datasource:
    url: jdbc:mysql://192.168.6.113:3306/sync?useUnicode=true&characterEncoding=utf8&useSSL=false # 注意加上 useSSL=false
    username: root
    password: root
    driver-class-name: com.mysql.jdbc.Driver # 这个可以不加，会智能感知
```

### H2

```
spring:
  datasource:
    url: jdbc:h2:mem:test # 使用内存存储
#    url: jdbc:h2:file:~/test # 使用物理盘存储
    username: sa
    password:
    driver-class-name: org.h2.Driver
  # 开启控制台
  h2:
    console:
      # 开启控制台，默认为 /h2-console
      enabled: true
      # 配置控制台路径
#      path: /console
```

## 连接池配置

Spring Boot 2中已经使用Hikari作为默认连接池，如果需要指定其他使用`spring.datasource.type`

```
spring:
    hikari:
      connection-timeout: 30000 #等待连接池分配连接的最大时长（毫秒），超过这个时长还没可用的连接则发生SQLException， 缺省:30秒
      idle-timeout: 600000 #一个连接idle状态的最大时长（毫秒），超时则被释放（retired），缺省:10分钟
      max-lifetime: 1800000 #一个连接的生命时长（毫秒），超时而且没被使用则被释放（retired），缺省:30分钟，建议设置比数据库超时时长少30秒以上，参考MySQL wait_timeout参数（show variables like '%timeout%';）
      maximum-pool-size: 9 #连接池中允许的最大连接数。缺省值：10；推荐的公式：((core_count * 2) + effective_spindle_count)
```

## JPA配置

```
spring:
  jpa:
    generate-ddl: false
    show-sql: true # 打印SQL
    hibernate:
      ddl-auto: create # create、create-drop、update、validate、none
      naming:
#        physical-strategy: com.example.MyPhysicalNamingStrategy
#    properties:
#      hibernate:
#        dialect: org.hibernate.dialect.MySQL5Dialect  # 方言设置，默认就为MySQL5Dialect，或者MySQL5InnoDBDialect使用InnoDB引擎
```



## MySQL抓取SQL运行时参数

添加依赖：

```
<dependency>
    <groupId>com.googlecode.log4jdbc</groupId>
    <artifactId>log4jdbc</artifactId>
    <version>1.2</version>
</dependency>
```

MySQL数据源配置换成：

```
spring:
  datasource:
    url: jdbc:log4jdbc:mysql://127.0.0.1:3306/test?useUnicode=true&characterEncoding=utf8&useSSL=false
    username: root
    password: root
    driver-class-name: net.sf.log4jdbc.DriverSpy
```

## 发布领域事件

一般基于DDD的设计，在实体状态改变时（保存或更新实体），为了保证其他边缘服务与之状态的统一，我们需要通过发布实体保存或更新事件，其他服务监听后做出相应的处理，大概像这样：

```
@RequiredArgsConstructor

class MyComponent {
  private final @NonNull MyRepository repository;
  private final @NonNull ApplicationEventPublisher publisher;

  public void doSomething(MyAggregateRoot entity) {
    MyDomainEvent event = entity.someBusinessFunctionality();
    publisher.publishEvent(event);
    repository.save(entity);
  }
}
```

通过JPA我们可以优雅地发布领域事件，有以下两种实现方式：

* 继承`AbstractAggregateRoot`，并使用其`registerEvent()`方法注册发布事件

  ```
  public class BankTransfer extends AbstractAggregateRoot {
     ...

      public BankTransfer complete() {
          id = UUID.randomUUID().toString();
          registerEvent(new BankTransferCompletedEvent(id));
          return this;
      }
      
      ...
  }

  ```

  ```
  @Service
  public class BankTransferService {

      ...
      
      @Transactional
      public String completeTransfer(BankTransfer bankTransfer) {
          return repository.save(bankTransfer.complete()).getId();
      }

      ...
  }

  ```

  **但此方式拿不到实体id，因为是在生成id之前生成的event**

* 使用`@DomainEvents`注解方法发布事件

  ```
  public class MessageEvent implements Serializable {
  	private static final long serialVersionUID = -3843381578126175380L;
      ....
      
  	@Transient
  	private transient List<Object> domainEvents = new ArrayList<>(16);

  	@DomainEvents
  	Collection<Object> domainEvents() {
  		log.info("publish domainEvents......");
  		domainEvents.add(new SaveMsgEvent().setId(this.id));
  		return Collections.unmodifiableList(domainEvents);
  	}

  	@AfterDomainEventPublication
  	void callbackMethod() {
  		log.info("AfterDomainEventPublication..........");
  		domainEvents.clear();
  	}
  }
  ```

  这种方式可以拿到实体id

  监听：

  ```
  @Component
  @Slf4j
  public class DomainEventListener {

  	@Async
  	@TransactionalEventListener(SaveMsgEvent.class)
  	public void processSaveMsgEvent(SaveMsgEvent saveMsgEvent) throws InterruptedException {
  		TimeUnit.MILLISECONDS.sleep(100);
  		log.info("Listening SaveMsgEvent..................saveMsgEvent id: {}", saveMsgEvent);
  	}
  }
  ```

  用`@EventListener`也可以，但是`@TransactionalEventListener`可以在事务之后执行。使用前者的话，程序异常事务会滚监听器照样会执行，而后者必须等事务正确提交之后才会执行。

220401005