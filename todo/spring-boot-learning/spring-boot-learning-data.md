# JPA

## 配置数据源

> 更多请查看官方指导：***[https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#howto-configure-a-datasource](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#howto-configure-a-datasource)***

### MySQL

pom.xml:

```
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
</dependency>
```

application.yml:

```
spring:
  datasource:
    url: jdbc:mysql://192.168.6.113:3306/sync?useUnicode=true&characterEncoding=utf8&useSSL=false # 注意加上 useSSL=false
    username: root
    password: root
    driver-class-name: com.mysql.jdbc.Driver # 这个可以不加，会智能感知
```

### H2

**注意：使用H2控制台不能使用WebFlux，否则控制台出不来**

pom.xml:

```
<!-- h2 数据源连接驱动 -->
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>runtime</scope>
</dependency>
```

application.yml:

```
spring:
  datasource:
    url: jdbc:h2:mem:test # 使用内存存储
#    url: jdbc:h2:file:~/test # 使用物理盘存储
    username: sa
    password:
    driver-class-name: org.h2.Driver
```

#### 开启H2控制台

```
spring:
  h2:
    console:
      # 开启控制台，默认为 false
      enabled: true
      # 配置控制台路径，默认为 /h2-console
      path: /console
      settings:
        trace: true
        web-allow-others: true # 允许内网访问
```

## 常用连接池配置

> Spring Boot 2 默认使用 [*HikariCP*](https://github.com/brettwooldridge/HikariCP) 作为连接池

如果项目中已包含`spring-boot-starter-jdbc`或`spring-boot-starter-jpa`模块，那么连接池将**自动激活**！

在Spring Boot2中选择数据库链接池实现的判断逻辑：

1. 检查HikariCP是否可用，如可用，则启用。使用`spring.datasource.hikari.*`可以控制链接池的行为。
2. 检查Tomcat的数据库链接池实现是否可用，如可用，则启用。使用`spring.datasource.tomcat.*`可以控制链接池的行为。
3. 检查Commons DBCP2是否可用，如可用，则启用。使用`spring.datasource.dbcp2.*`可以控制链接池的行为。

Spring Boot 2中已经使用Hikari作为默认连接池，如果需要指定其他使用`spring.datasource.type`

```
spring:
    hikari:
      connection-timeout: 30000 #等待连接池分配连接的最大时长（毫秒），超过这个时长还没可用的连接则发生SQLException， 缺省:30秒
      idle-timeout: 600000 #一个连接idle状态的最大时长（毫秒），超时则被释放（retired），缺省:10分钟
      max-lifetime: 1800000 #一个连接的生命时长（毫秒），超时而且没被使用则被释放（retired），缺省:30分钟，建议设置比数据库超时时长少30秒以上，参考MySQL wait_timeout参数（show variables like '%timeout%';）
      maximum-pool-size: 9 #连接池中允许的最大连接数。缺省值：10；推荐的公式：((core_count * 2) + effective_spindle_count)
```

### HikariCP 连接池常用属性

| 属性                | 描述                                                         | 默认值                    |
| ------------------- | ------------------------------------------------------------ | ------------------------- |
| dataSourceClassName | JDBC 驱动程序提供的 DataSource 类的名称，如果使用了jdbcUrl则不需要此属性 | -                         |
| jdbcUrl             | 数据库连接地址                                               | -                         |
| username            | 数据库账户，如果使用了jdbcUrl则需要此属性                    | -                         |
| password            | 数据库密码，如果使用了jdbcUrl则需要此属性                    | -                         |
| autoCommit          | 是否自动提交事务                                             | true                      |
| connectionTimeout   | 连接超时时间（毫秒），如果在没有连接可用的情况下等待超过此时间，则抛出 SQLException | 30000（30秒）             |
| idleTimeout         | 空闲超时时间（毫秒），只有在minimumIdle<maximumPoolSize时生效，超时的连接可能被回收，数值 0 表示空闲连接永不从池中删除 | 600000（10分钟）          |
| maxLifetime         | 连接池中的连接的最长生命周期（毫秒）。数值 0 表示不限制      | 1800000（30分钟）         |
| connectionTestQuery | 连接池每分配一条连接前执行的查询语句（如：SELECT 1），以验证该连接是否是有效的。如果你的驱动程序支持 JDBC4，HikariCP 强烈建议我们不要设置此属性 | -                         |
| minimumIdle         | 最小空闲连接数，HikariCP 建议我们不要设置此值，而是充当固定大小的连接池 | 与maximumPoolSize数值相同 |
| maximumPoolSize     | 连接池中可同时连接的最大连接数，当池中没有空闲连接可用时，就会阻塞直到超出connectionTimeout设定的数值，推荐的公式：((core_count * 2) + effective_spindle_count) | 10                        |
| poolName            | 连接池名称，主要用于显示在日志记录和 JMX 管理控制台中        | auto-generated            |

`application.yml`

```
spring:
  datasource:
      url: jdbc:mysql://127.0.0.1/spring_boot_testing_storage
      username: root
      password: root
      driver-class-name: com.mysql.jdbc.Driver
#     type: com.zaxxer.hikari.HikariDataSource #Spring Boot2.0默认使用HikariDataSource
      hikari:
        auto-commit: false
        maximum-pool-size: 9 #连接池中允许的最大连接数。缺省值：10；推荐的公式：((core_count * 2) + effective_spindle_count)
```

### Tomcat连接池常用的属性

| 属性                          | 描述                                                         | 默认值                    |
| ----------------------------- | ------------------------------------------------------------ | ------------------------- |
| defaultAutoCommit             | 连接池中创建的连接默认是否自动提交事务                       | 驱动的缺省值              |
| defaultReadOnly               | 连接池中创建的连接默认是否为只读状态                         | -                         |
| defaultCatalog                | 连接池中创建的连接默认的 catalog                             | -                         |
| driverClassName               | 驱动类的名称                                                 | -                         |
| username                      | 数据库账户                                                   | -                         |
| password                      | 数据库密码                                                   | -                         |
| maxActive                     | 连接池同一时间可分配的最大活跃连接数                         | 100                       |
| maxIdle                       | 始终保留在池中的最大连接数，如果启用，将定期检查限制连接，超出此属性设定的值且空闲时间超过minEvictableIdleTimeMillis的连接则释放 | 与maxActive设定的值相同   |
| minIdle                       | 始终保留在池中的最小连接数，池中的连接数量若低于此值则创建新的连接，如果连接验证失败将缩小至此值 | 与initialSize设定的值相同 |
| initialSize                   | 连接池启动时创建的初始连接数量                               | 10                        |
| maxWait                       | 最大等待时间（毫秒），如果在没有连接可用的情况下等待超过此时间，则抛出异常 | 30000（30秒）             |
| testOnBorrow                  | 当从连接池中取出一个连接时是否进行验证，若验证失败则从池中删除该连接并尝试取出另一个连接 | false                     |
| testOnConnect                 | 当一个连接首次被创建时是否进行验证，若验证失败则抛出 SQLException 异常 | false                     |
| testOnReturn                  | 当一个连接使用完归还到连接池时是否进行验证                   | false                     |
| testWhileIdle                 | 对池中空闲的连接是否进行验证，验证失败则回收此连接           | false                     |
| validationQuery               | 在连接池返回连接给调用者前用来对连接进行验证的查询 SQL       | null                      |
| validationQueryTimeout        | SQL 查询验证超时时间（秒），小于或等于 0 的数值表示禁用      | -1                        |
| timeBetweenEvictionRunsMillis | 在空闲连接回收器线程运行期间休眠时间（毫秒）， 该值不应该小于 1 秒，它决定线程多久验证空闲连接或丢弃连接的频率 | 5000（5秒）               |
| minEvictableIdleTimeMillis    | 连接在池中保持空闲而不被回收的最小时间（毫秒）               | 60000（60秒）             |
| removeAbandoned               | 标记是否删除泄露的连接，如果连接超出removeAbandonedTimeout的限制，且该属性设置为 true，则连接被认为是被泄露并且可以被删除 | false                     |
| removeAbandonedTimeout        | 泄露的连接可以被删除的超时时间（秒），该值应设置为应用程序查询可能执行的最长时间 | 60                        |

`application.yml`:

```
spring:
  datasource:
    url: jdbc:mysql://127.0.0.1/spring_boot_testing_storage
    username: root
    password: root
    driver-class-name: com.mysql.jdbc.Driver
    tomcat:
      default-auto-commit: true
      initial-size: 30
      max-active: 120
      max-wait: 10000
      test-on-borrow: true
      test-while-idle: true
      validation-query: 'SELECT 1'
      validation-query-timeout: 3
      time-between-eviction-runs-millis: 10000
      min-evictable-idle-time-millis: 120000
      remove-abandoned: true
      remove-abandoned-timeout: 120
```

### DBCP 连接池常用配置

| 属性                          | 描述                                                         | 默认值            |
| ----------------------------- | ------------------------------------------------------------ | ----------------- |
| url                           | 数据库连接地址                                               | -                 |
| username                      | 数据库账户                                                   | -                 |
| password                      | 数据库密码                                                   | -                 |
| driverClassName               | 驱动类的名称                                                 | -                 |
| defaultAutoCommit             | 连接池中创建的连接默认是否自动提交事务                       | 驱动的缺省值      |
| defaultReadOnly               | 连接池中创建的连接默认是否为只读状态                         | 驱动的缺省值      |
| defaultCatalog                | 连接池中创建的连接默认的 catalog                             | -                 |
| initialSize                   | 连接池启动时创建的初始连接数量                               | 0                 |
| maxTotal                      | 连接池同一时间可分配的最大活跃连接数；负数表示不限制         | 8                 |
| maxIdle                       | 可以在池中保持空闲的最大连接数，超出此值的空闲连接被释放，负数表示不限制 | 8                 |
| minIdle                       | 可以在池中保持空闲的最小连接数，低于此值将创建空闲连接，若设置为 0，则不创建 | 0                 |
| maxWaitMillis                 | 最大等待时间（毫秒），如果在没有连接可用的情况下等待超过此时间，则抛出异常；-1 表示无限期等待，直到获取到连接为止 | -                 |
| validationQuery               | 在连接池返回连接给调用者前用来对连接进行验证的查询 SQL       | -                 |
| validationQueryTimeout        | SQL 查询验证超时时间（秒）                                   | -                 |
| testOnCreate                  | 连接在创建之后是否进行验证                                   | false             |
| testOnBorrow                  | 当从连接池中取出一个连接时是否进行验证，若验证失败则从池中删除该连接并尝试取出另一个连接 | true              |
| testOnReturn                  | 当一个连接使用完归还到连接池时是否进行验证                   | false             |
| testWhileIdle                 | 对池中空闲的连接是否进行验证，验证失败则释放此连接           | false             |
| timeBetweenEvictionRunsMillis | 在空闲连接回收器线程运行期间休眠时间（毫秒），如果设置为非正数，则不运行此线程 | -1                |
| numTestsPerEvictionRun        | 空闲连接回收器线程运行期间检查连接的个数                     | 3                 |
| minEvictableIdleTimeMillis    | 连接在池中保持空闲而不被回收的最小时间（毫秒）               | 1800000（30分钟） |
| removeAbandonedOnBorrow       | 标记是否删除泄露的连接，如果连接超出removeAbandonedTimeout的限制，且该属性设置为 true，则连接被认为是被泄露并且可以被删除 | false             |
| removeAbandonedTimeout        | 泄露的连接可以被删除的超时时间（秒），该值应设置为应用程序查询可能执行的最长时间 | 300（5分钟）      |
| poolPreparedStatements        | 设置该连接池的预处理语句池是否生效                           | false             |

`application.yml`

```
spring:
  jmx:
    enabled: false
  datasource:
    url: jdbc:mysql://127.0.0.1/spring_boot_testing_storage
    username: root
    password: root
    driver-class-name: com.mysql.jdbc.Driver
    dbcp2:
      default-auto-commit: true
      initial-size: 30
      max-total: 120
      max-idle: 120
      min-idle: 30
      max-wait-millis: 10000
      validation-query: 'SELECT 1'
      validation-query-timeout: 3
      test-on-borrow: true
      test-while-idle: true
      time-between-eviction-runs-millis: 10000
      num-tests-per-eviction-run: 10
      min-evictable-idle-time-millis: 120000
      remove-abandoned-on-borrow: true
      remove-abandoned-timeout: 120
      pool-prepared-statements: true
```

Spring Boot Data Jpa 依赖声明：

```
通过application.yml: spring.datasource.type=...配置

<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-dbcp2</artifactId>
    <version>2.2.0</version>
</dependency>
```

### Druid连接池配置

参考：***[https://github.com/alibaba/druid/tree/master/druid-spring-boot-starter](https://github.com/alibaba/druid/tree/master/druid-spring-boot-starter)***

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

## 默认驼峰模式

Spring Data Jpa 使用的默认策略是 `ImprovedNamingStrategy`

可以这样修改命名策略：

```
#PhysicalNamingStrategyStandardImpl
spring.jpa.hibernate.naming.physical-strategy=org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl
```

如果需要指定某个字段不使用驼峰模式可以直接使用`@Column(name = "aaa")`

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

## 常用注解

`@Entity(name = "t_user")`

`@Table(indexes = {...}`

`@Id`

`@GeneratedValue`

`@Column(length = 100, nullable = false)`

`@Enumerated(EnumType.STRING)`

`@Temporal(TemporalType.TIMESTAMP)`

## 生成JPQL语句方法名称中支持的关键字

| Keyword             | Sample                                                       | JPQL snippet                                                 |
| ------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `And`               | `findByLastnameAndFirstname`                                 | `… where x.lastname = ?1 and x.firstname = ?2`               |
| `Or`                | `findByLastnameOrFirstname`                                  | `… where x.lastname = ?1 or x.firstname = ?2`                |
| `Is,Equals`         | `findByFirstname`,`findByFirstnameIs`,`findByFirstnameEquals` | `… where x.firstname = ?1`                                   |
| `Between`           | `findByStartDateBetween`                                     | `… where x.startDate between ?1 and ?2`                      |
| `LessThan`          | `findByAgeLessThan`                                          | `… where x.age < ?1`                                         |
| `LessThanEqual`     | `findByAgeLessThanEqual`                                     | `… where x.age <= ?1`                                        |
| `GreaterThan`       | `findByAgeGreaterThan`                                       | `… where x.age > ?1`                                         |
| `GreaterThanEqual`  | `findByAgeGreaterThanEqual`                                  | `… where x.age >= ?1`                                        |
| `After`             | `findByStartDateAfter`                                       | `… where x.startDate > ?1`                                   |
| `Before`            | `findByStartDateBefore`                                      | `… where x.startDate < ?1`                                   |
| `IsNull`            | `findByAgeIsNull`                                            | `… where x.age is null`                                      |
| `IsNotNull,NotNull` | `findByAge(Is)NotNull`                                       | `… where x.age not null`                                     |
| `Like`              | `findByFirstnameLike`                                        | `… where x.firstname like ?1`                                |
| `NotLike`           | `findByFirstnameNotLike`                                     | `… where x.firstname not like ?1`                            |
| `StartingWith`      | `findByFirstnameStartingWith`                                | `… where x.firstname like ?1`(parameter bound with appended `%`) |
| `EndingWith`        | `findByFirstnameEndingWith`                                  | `… where x.firstname like ?1`(parameter bound with prepended `%`) |
| `Containing`        | `findByFirstnameContaining`                                  | `… where x.firstname like ?1`(parameter bound wrapped in `%`) |
| `OrderBy`           | `findByAgeOrderByLastnameDesc`                               | `… where x.age = ?1 order by x.lastname desc`                |
| `Not`               | `findByLastnameNot`                                          | `… where x.lastname <> ?1`                                   |
| `In`                | `findByAgeIn(Collection<Age> ages)`                          | `… where x.age in ?1`                                        |
| `NotIn`             | `findByAgeNotIn(Collection<Age> ages)`                       | `… where x.age not in ?1`                                    |
| `True`              | `findByActiveTrue()`                                         | `… where x.active = true`                                    |
| `False`             | `findByActiveFalse()`                                        | `… where x.active = false`                                   |
| `IgnoreCase`        | `findByFirstnameIgnoreCase`                                  | `… where UPPER(x.firstame) = UPPER(?1)`                      |


![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-data/jpa-query.png)

## 使用Tips

### 使用 @Convert 关联一对多的值对象

有时候在实体当中有某些字段是一个**值对象的集合**，我们又不想（也没必要）为其另起一张表，打个比方：订单里面的商品列表（只是打个比方，实际上应该是一张独立的表）。

例如设计一个访问日志对象，我们需要记录访问方法的行参与接收值：

```
@Data
@Accessors(chain = true)
@Slf4j
@Entity
@Table(name = "access_log")
public class AccessLog implements Serializable {

	private static final long serialVersionUID = -6911021075718017305L;

	@Id
	@GeneratedValue(generator = "snowflakeIdentifierGenerator")
	@GenericGenerator(name = "snowflakeIdentifierGenerator", strategy = "com.yangbingdong.docker.domain.core.vo.SnowflakeIdentifierGenerator")
	private long id;

	@Column(columnDefinition = "text")
	@Convert(converter = ReqReceiveDataConverter.class)
	private List<ReqReceiveData> reqReceiveDatas;
	
	...
}
```

属性转换器：
```
//@Converter(autoApply = true)
public class ReqReceiveDataConverter implements AttributeConverter<List<ReqReceiveData>, String> {
	@Override
	public String convertToDatabaseColumn(List<ReqReceiveData> attribute) {
		return JSONObject.toJSONString(attribute);
	}

	@Override
	public List<ReqReceiveData> convertToEntityAttribute(String dbData) {
		return JSONObject.parseArray(dbData, ReqReceiveData.class);
	}
}
```

* `@Convert`声明使用某个属性转换器（`ReqReceiveDataConverter`）
* `ReqReceiveDataConverter`需要实现`AttributeConverter<X,Y>`，`X`为实体的字段类型，`Y`对应需要持久化到DB的类型
* `@Converter(autoApply = true)`注解作用，如果有多个实体需要用到此属性转换器，不需要每个实体都的字段加上`@Convert`注解，自动对全部实体生效

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

## 踩坑

### 索引超长

```
com.mysql.jdbc.exceptions.jdbc4.MySQLSyntaxErrorException: Specified key was too long; max key length is 1000 bytes
	at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method) ~[?:1.8.0_162]
	at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62) ~[?:1.8.0_162]
	at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45) ~[?:1.8.0_162]
	at java.lang.reflect.Constructor.newInstance(Constructor.java:423) ~[?:1.8.0_162]
	at com.mysql.jdbc.Util.handleNewInstance(Util.java:425) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.Util.getInstance(Util.java:408) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.SQLError.createSQLException(SQLError.java:944) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.MysqlIO.checkErrorPacket(MysqlIO.java:3973) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.MysqlIO.checkErrorPacket(MysqlIO.java:3909) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.MysqlIO.sendCommand(MysqlIO.java:2527) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.MysqlIO.sqlQueryDirect(MysqlIO.java:2680) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.ConnectionImpl.execSQL(ConnectionImpl.java:2480) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.ConnectionImpl.execSQL(ConnectionImpl.java:2438) ~[mysql-connector-java-5.1.45.jar:5.1.45]
```

如果设置了索引：

```
@Table(indexes = {@Index(name = "idx_server_name", columnList = "serverName")})
```

上面注解指定了`serverName`这一列为普通索引，如果此列不做限制，默认的长度是为255，默认的字符编码为`utf8mb4`，最大字符长度为4字节，255 * 4 = 1020，所以超过了索引长度。

在`MyISAM`表中，创建索引时，创建的索引长度不能超过**1000**bytes，在`InnoDB`表中，创建索引时，索引的长度不成超过**767**byts 。

建立索引时，数据库计算key的长度是累加所有Index用到的字段的char长度后再按下面比例乘起来不能超过限定的key长度：

```
latin1 = 1 byte = 1 character 
uft8 = 3 byte = 1 character 
gbk = 2 byte = 1 character 
utf8mb4 = 4 byte = 1 character 
```

### 使用AttributeConverter转换JSON字符串时，Hibernate执行insert之后再执行update

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-data/jpa-dirty01.png)

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-data/jpa-dirty02.png)

如上图，这是利用AOP实现的操作日志记录，使用`AttributeConverter`与Fastjson实现`ReqReceiveData`转换成JSON字符串，可以看到在执行insert之后接着执行了一次update，那是因为JSON字符串字段顺序居然发生了变化！

不过后来折腾一下把顺序统一了，但还是会出现这种问题，百思不得其解，一样的字符串Hibernate也会认为这是Dirty的数据？

百般折腾得以解决（但还是搞不懂原因）：

value是Object类型，在set的时候调用`JSONObject.toJSON(value)`转成Object再set进去...

# Elasticsearch

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-elasticsearch/es-heart.svg)

## 概念

**索引（index）** `->` 类似于关系型数据库中**Database**

**类型（type）** `->` 类似于关系型数据库中**Table**

**文档（document）** `->` 类似于关系型数据库中**Record**

## 自定义Dockerfile安装analysis-ik以及pinyin插件

基于官方的镜像安装***[analysis-ik](https://github.com/medcl/elasticsearch-analysis-ik)***和***[pinyin](https://github.com/medcl/elasticsearch-analysis-pinyin)***插件：

```
FROM docker.elastic.co/elasticsearch/elasticsearch:6.2.3
MAINTAINER yangbingdong <yangbingdong1994@gmail.com>
ARG TZ 
ARG HTTP_PROXY
ENV TZ=${TZ:-"Asia/Shanghai"} http_proxy=${HTTP_PROXY} https_proxy=${HTTP_PROXY}
RUN ./bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v6.2.3/elasticsearch-analysis-ik-6.2.3.zip \
  && ./bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-pinyin/releases/download/v6.2.3/elasticsearch-analysis-pinyin-6.2.3.zip \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo $TZ > /etc/timezone
ENV http_proxy=
ENV https_proxy=
```

构建镜像：

```
docker build --build-arg HTTP_PROXY=192.168.6.113:8118 -t yangbingdong/elasticsearch-ik-pinyin:6.2.3 .
```

## 安装启动

> 官方文档：***[https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html)***

使用docker compose:

```
version: '3.4'
services:
  elasticsearch-temp:
    image: yangbingdong/elasticsearch-ik-pinyin:6.2.3
    ports:
      - "9222:9200"
      - "9300:9300"
    restart: always
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    volumes:
      - ./data:/usr/share/elasticsearch/data
    networks:
      - backend

networks:
  backend:
    external:
      name: backend
```

## Head插件

直接使用Chrome插件：

***[https://chrome.google.com/webstore/detail/elasticsearch-head/ffmkiejjmecolpfloofpjologoblkegm](https://chrome.google.com/webstore/detail/elasticsearch-head/ffmkiejjmecolpfloofpjologoblkegm)***

![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot-elasticsearch/elasticsearch-head-plugin.png)