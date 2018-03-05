# JPA

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