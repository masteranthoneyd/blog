# ORM(Object Relational Mapping) 对比

- MyBatis：MyBatis 本是 Apache 的一个开源项目 iBatis，2010 年这个项目由 Apache Software Foundation 迁移到了 Google Code，并且改名为 MyBatis，其**着力于 POJO 与 SQL 之间的映射关系**，可以进行更为细致的 SQL，使用起来十分灵活、上手简单、容易掌握，所以深受开发者的喜欢，目前市场占有率最高，比较适合互联应用公司的 API 场景; 缺点就是工作量比较大，需要各种配置文件的配置和 SQL 语句。
- Hibernate：Hibernate 是一个开放源代码的对象关系映射框架，它对 JDBC 进行了非常轻量级的对象封装，使得 Java 程序员可以随心所欲的使用对象编程思维来操纵数据库，并且对象有自己的生命周期，**着力点对象与对象之间关系**，有自己的 HQL 查询语言，所以数据库移植性很好。Hibernate 是完备的 ORM 框架，是符合 JPA 规范的，有自己的缓存机制，上手来说比较难，比较适合企业级的应用系统开发。
- Spring Data JPA：可以理解为 JPA 规范的再次封装抽象，底层还是使用了 Hibernate 的 JPA 技术实现，引用 JPQL(Java Persistence Query Language)查询语言，属于 Spring 的整个生态体系的一部分。由于 Spring Boot 和 Spring Cloud 在市场上的流行，Spring Data JPA 也逐渐进入大家的视野，他们有机的整体，使用起来比较方便，加快了开发的效率，使开发者不需要关系和配置更多的东西，完全可以沉浸在 Spring 的完整生态标准的实现下，上手简单、开发效率高，又对对象的支持比较好，又有很大的灵活性，市场的认可度越来越高。

# 数据源

## 配置数据源

> 更多请查看官方指导：***[https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#howto-configure-a-datasource](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#howto-configure-a-datasource)***

### MySQL

pom.xml:

```xml
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
</dependency>
```

application.yml:

```yaml
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

```xml
<!-- h2 数据源连接驱动 -->
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>runtime</scope>
</dependency>
```

application.yml:

```yaml
spring:
  datasource:
    url: jdbc:h2:mem:test # 使用内存存储
#    url: jdbc:h2:file:~/test # 使用物理盘存储
    username: sa
    password:
    driver-class-name: org.h2.Driver
```

**开启H2控制台**

```yaml
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
      connection-timeout: 30000 #等待连接池分配连接的最大时长(毫秒)，超过这个时长还没可用的连接则发生SQLException， 缺省:30秒
      idle-timeout: 600000 #一个连接idle状态的最大时长(毫秒)，超时则被释放(retired)，缺省:10分钟
      max-lifetime: 1800000 #一个连接的生命时长(毫秒)，超时而且没被使用则被释放(retired)，缺省:30分钟，建议设置比数据库超时时长少30秒以上，参考MySQL wait_timeout参数(show variables like '%timeout%';)
      maximum-pool-size: 9 #连接池中允许的最大连接数。缺省值：10; 推荐的公式：((core_count * 2) + effective_spindle_count)
```

### HikariCP 连接池常用属性

| 属性                | 描述                                                         | 默认值                    |
| ------------------- | ------------------------------------------------------------ | ------------------------- |
| dataSourceClassName | JDBC 驱动程序提供的 DataSource 类的名称，如果使用了jdbcUrl则不需要此属性 | -                         |
| jdbcUrl             | 数据库连接地址                                               | -                         |
| username            | 数据库账户，如果使用了jdbcUrl则需要此属性                    | -                         |
| password            | 数据库密码，如果使用了jdbcUrl则需要此属性                    | -                         |
| autoCommit          | 是否自动提交事务                                             | true                      |
| connectionTimeout   | 连接超时时间(毫秒)，如果在没有连接可用的情况下等待超过此时间，则抛出 SQLException | 30000(30秒)               |
| idleTimeout         | 空闲超时时间(毫秒)，只有在minimumIdle<maximumPoolSize时生效，超时的连接可能被回收，数值 0 表示空闲连接永不从池中删除 | 600000(10分钟)            |
| maxLifetime         | 连接池中的连接的最长生命周期(毫秒)。数值 0 表示不限制        | 1800000(30分钟)           |
| connectionTestQuery | 连接池每分配一条连接前执行的查询语句(如：SELECT 1)，以验证该连接是否是有效的。如果你的驱动程序支持 JDBC4，HikariCP 强烈建议我们不要设置此属性 | -                         |
| minimumIdle         | 最小空闲连接数，HikariCP 建议我们不要设置此值，而是充当固定大小的连接池 | 与maximumPoolSize数值相同 |
| maximumPoolSize     | 连接池中可同时连接的最大连接数，当池中没有空闲连接可用时，就会阻塞直到超出connectionTimeout设定的数值，推荐的公式：((core_count * 2) + effective_spindle_count) | 10                        |
| poolName            | 连接池名称，主要用于显示在日志记录和 JMX 管理控制台中        | auto-generated            |

`application.yml`

```yaml
spring:
  datasource:
      url: jdbc:mysql://127.0.0.1/spring_boot_testing_storage
      username: root
      password: root
      driver-class-name: com.mysql.jdbc.Driver
#     type: com.zaxxer.hikari.HikariDataSource #Spring Boot2.0默认使用HikariDataSource
      hikari:
        auto-commit: false
        maximum-pool-size: 9 #连接池中允许的最大连接数。缺省值：10; 推荐的公式：((core_count * 2) + effective_spindle_count)
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
| maxWait                       | 最大等待时间(毫秒)，如果在没有连接可用的情况下等待超过此时间，则抛出异常 | 30000(30秒)               |
| testOnBorrow                  | 当从连接池中取出一个连接时是否进行验证，若验证失败则从池中删除该连接并尝试取出另一个连接 | false                     |
| testOnConnect                 | 当一个连接首次被创建时是否进行验证，若验证失败则抛出 SQLException 异常 | false                     |
| testOnReturn                  | 当一个连接使用完归还到连接池时是否进行验证                   | false                     |
| testWhileIdle                 | 对池中空闲的连接是否进行验证，验证失败则回收此连接           | false                     |
| validationQuery               | 在连接池返回连接给调用者前用来对连接进行验证的查询 SQL       | null                      |
| validationQueryTimeout        | SQL 查询验证超时时间(秒)，小于或等于 0 的数值表示禁用        | -1                        |
| timeBetweenEvictionRunsMillis | 在空闲连接回收器线程运行期间休眠时间(毫秒)， 该值不应该小于 1 秒，它决定线程多久验证空闲连接或丢弃连接的频率 | 5000(5秒)                 |
| minEvictableIdleTimeMillis    | 连接在池中保持空闲而不被回收的最小时间(毫秒)                 | 60000(60秒)               |
| removeAbandoned               | 标记是否删除泄露的连接，如果连接超出removeAbandonedTimeout的限制，且该属性设置为 true，则连接被认为是被泄露并且可以被删除 | false                     |
| removeAbandonedTimeout        | 泄露的连接可以被删除的超时时间(秒)，该值应设置为应用程序查询可能执行的最长时间 | 60                        |

`application.yml`:

```yaml
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

| 属性                          | 描述                                                         | 默认值          |
| ----------------------------- | ------------------------------------------------------------ | --------------- |
| url                           | 数据库连接地址                                               | -               |
| username                      | 数据库账户                                                   | -               |
| password                      | 数据库密码                                                   | -               |
| driverClassName               | 驱动类的名称                                                 | -               |
| defaultAutoCommit             | 连接池中创建的连接默认是否自动提交事务                       | 驱动的缺省值    |
| defaultReadOnly               | 连接池中创建的连接默认是否为只读状态                         | 驱动的缺省值    |
| defaultCatalog                | 连接池中创建的连接默认的 catalog                             | -               |
| initialSize                   | 连接池启动时创建的初始连接数量                               | 0               |
| maxTotal                      | 连接池同一时间可分配的最大活跃连接数; 负数表示不限制         | 8               |
| maxIdle                       | 可以在池中保持空闲的最大连接数，超出此值的空闲连接被释放，负数表示不限制 | 8               |
| minIdle                       | 可以在池中保持空闲的最小连接数，低于此值将创建空闲连接，若设置为 0，则不创建 | 0               |
| maxWaitMillis                 | 最大等待时间(毫秒)，如果在没有连接可用的情况下等待超过此时间，则抛出异常; -1 表示无限期等待，直到获取到连接为止 | -               |
| validationQuery               | 在连接池返回连接给调用者前用来对连接进行验证的查询 SQL       | -               |
| validationQueryTimeout        | SQL 查询验证超时时间(秒)                                     | -               |
| testOnCreate                  | 连接在创建之后是否进行验证                                   | false           |
| testOnBorrow                  | 当从连接池中取出一个连接时是否进行验证，若验证失败则从池中删除该连接并尝试取出另一个连接 | true            |
| testOnReturn                  | 当一个连接使用完归还到连接池时是否进行验证                   | false           |
| testWhileIdle                 | 对池中空闲的连接是否进行验证，验证失败则释放此连接           | false           |
| timeBetweenEvictionRunsMillis | 在空闲连接回收器线程运行期间休眠时间(毫秒)，如果设置为非正数，则不运行此线程 | -1              |
| numTestsPerEvictionRun        | 空闲连接回收器线程运行期间检查连接的个数                     | 3               |
| minEvictableIdleTimeMillis    | 连接在池中保持空闲而不被回收的最小时间(毫秒)                 | 1800000(30分钟) |
| removeAbandonedOnBorrow       | 标记是否删除泄露的连接，如果连接超出removeAbandonedTimeout的限制，且该属性设置为 true，则连接被认为是被泄露并且可以被删除 | false           |
| removeAbandonedTimeout        | 泄露的连接可以被删除的超时时间(秒)，该值应设置为应用程序查询可能执行的最长时间 | 300(5分钟)      |
| poolPreparedStatements        | 设置该连接池的预处理语句池是否生效                           | false           |

`application.yml`

```yaml
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

```xml
通过application.yml: spring.datasource.type=...配置

<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-dbcp2</artifactId>
    <version>2.2.0</version>
</dependency>
```

### Druid连接池配置

参考：***[https://github.com/alibaba/druid/tree/master/druid-spring-boot-starter](https://github.com/alibaba/druid/tree/master/druid-spring-boot-starter)***

## JTA分布式事务数据源

Atomikos是一个非常流行的开源事务管理器，并且可以嵌入到Spring Boot应用中。可以使用 `spring-boot-starter-jta-atomikos` Starter去获取正确的Atomikos库。Spring Boot会自动配置Atomikos，并将合适的 `depends-on` 应用到Spring Beans上，确保它们以正确的顺序启动和关闭。

默认情况下，Atomikos事务日志将被记录在应用home目录(应用jar文件放置的目录)下的 `transaction-logs` 文件夹中。可以在 `application.properties` 文件中通过设置 `spring.jta.log-dir` 属性来定义该目录，以 `spring.jta.atomikos.properties` 开头的属性能用来定义Atomikos的 `UserTransactionServiceIml` 实现，具体参考[AtomikosProperties javadoc](http://docs.spring.io/spring-boot/docs/1.5.4.RELEASE/api/org/springframework/boot/jta/atomikos/AtomikosProperties.html)。

> 注 为了确保多个事务管理器能够安全地和相应的资源管理器配合，每个Atomikos实例必须设置一个唯一的ID。默认情况下，该ID是Atomikos实例运行的机器上的IP地址。为了确保生产环境中该ID的唯一性，需要为应用的每个实例设置不同的 `spring.jta.transaction-manager-id` 属性值。

依赖：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jta-atomikos</artifactId>
</dependency>
```

application.yml

```yaml
spring:
  application:
    name: test-23
  jpa:
    show-sql: true
  jta:
    enabled: true
    atomikos:
      datasource:
        jta-user:
          xa-properties.url: jdbc:mysql://localhost:3306/jta-user
          xa-properties.user: root
          xa-properties.password: root
          xa-data-source-class-name: com.mysql.jdbc.jdbc2.optional.MysqlXADataSource
          unique-resource-name: jta-user
          max-pool-size: 25
          min-pool-size: 3
          max-lifetime: 20000
          borrow-connection-timeout: 10000
        jta-income: 
          xa-properties.url: jdbc:mysql://localhost:3306/jta-income
          xa-properties.user: root
          xa-properties.password: root
          xa-data-source-class-name: com.mysql.jdbc.jdbc2.optional.MysqlXADataSource
          unique-resource-name: jta-income
          max-pool-size: 25
          min-pool-size: 3
          max-lifetime: 20000
          borrow-connection-timeout: 10000
```

DataSourceJTAIncomeConfig.java:

```java
@Configuration
@EnableConfigurationProperties
@EnableAutoConfiguration
@MapperScan(basePackages = "com.freud.test.springboot.mapper.income", sqlSessionTemplateRef = "jtaIncomeSqlSessionTemplate")
public class DataSourceJTAIncomeConfig {

    @Bean
    @ConfigurationProperties(prefix = "spring.jta.atomikos.datasource.jta-income")
    public DataSource dataSourceJTAIncome() {
        return new AtomikosDataSourceBean();
    }

    @Bean
    public SqlSessionFactory jtaIncomeSqlSessionFactory(@Qualifier("dataSourceJTAIncome") DataSource dataSource)
            throws Exception {
        SqlSessionFactoryBean bean = new SqlSessionFactoryBean();
        bean.setDataSource(dataSource);
        bean.setMapperLocations(new PathMatchingResourcePatternResolver().getResources("classpath:mapper/*.xml"));
        bean.setTypeAliasesPackage("com.freud.test.springboot.mapper.income");
        return bean.getObject();
    }

    @Bean
    public SqlSessionTemplate jtaIncomeSqlSessionTemplate(
            @Qualifier("jtaIncomeSqlSessionFactory") SqlSessionFactory sqlSessionFactory) throws Exception {
        return new SqlSessionTemplate(sqlSessionFactory);
    }
}
```

DataSourceJTAUserConfig.java

```java
@Configuration
@EnableConfigurationProperties
@EnableAutoConfiguration
@MapperScan(basePackages = "com.freud.test.springboot.mapper.user", sqlSessionTemplateRef = "jtaUserSqlSessionTemplate")
public class DataSourceJTAUserConfig {

    @Bean
    @ConfigurationProperties(prefix = "spring.jta.atomikos.datasource.jta-user")
    @Primary
    public DataSource dataSourceJTAUser() {
        return new AtomikosDataSourceBean();
    }

    @Bean
    @Primary
    public SqlSessionFactory jtaUserSqlSessionFactory(@Qualifier("dataSourceJTAUser") DataSource dataSource)
            throws Exception {
        SqlSessionFactoryBean bean = new SqlSessionFactoryBean();
        bean.setDataSource(dataSource);
        bean.setMapperLocations(new PathMatchingResourcePatternResolver().getResources("classpath:mapper/*.xml"));
        bean.setTypeAliasesPackage("com.freud.test.springboot.mapper.user");
        return bean.getObject();
    }

    @Bean
    @Primary
    public SqlSessionTemplate jtaUserSqlSessionTemplate(
            @Qualifier("jtaUserSqlSessionFactory") SqlSessionFactory sqlSessionFactory) throws Exception {
        return new SqlSessionTemplate(sqlSessionFactory);
    }
}
```

# 运行时SQL监控

> 虽然一些开源框架会自带SQL打印, 但都需要各自配置, 但我们可以通过第三方框架比如p6spy以及log4jdbc做到驱动级别拦截.

## p6spy

> ***[https://p6spy.readthedocs.io](https://p6spy.readthedocs.io)***

添加依赖:

```xml
<dependency>
    <groupId>p6spy</groupId>
    <artifactId>p6spy</artifactId>
    <version>3.7.0</version>
</dependency>
```

应用`P6Spy`只需要

- 1.替换你的`JDBC Driver`为`com.p6spy.engine.spy.P6SpyDriver`
- 2.修改`JDBC Url`为`jdbc:p6spy:xxxx`
- 3.配置`spy.properties`

修改`application.yml`文件,替换`jdbc driver`和`url`

```yaml
# 数据源
spring:
  datasource:
    url: jdbc:p6spy:mysql://127.0.0.1:3306/jpa_test?useSSL=false
    username: root
    password: root
    driver-class-name: com.p6spy.engine.spy.P6SpyDriver
```

配置`spy.properties`

```properties
module.log=com.p6spy.engine.logging.P6LogFactory,com.p6spy.engine.outage.P6OutageFactory
# 自定义日志打印
logMessageFormat=com.yangbingdong.springbootdatajpa.util.sqlformat.PrettySqlMultiLineFormat
# 使用日志系统记录sql
appender=com.p6spy.engine.spy.appender.Slf4JLogger
## 配置记录Log例外
excludecategories=info,debug,result,batc,resultset
# 设置使用p6spy driver来做代理
deregisterdrivers=true
# 日期格式
dateformat=yyyy-MM-dd HH:mm:ss
# 实际驱动
driverlist=com.mysql.jdbc.Driver
# 是否开启慢SQL记录
outagedetection=true
# 慢SQL记录标准 秒
outagedetectioninterval=2
```

自定义日志打印 , 这里有两种方式

一、实现`MessageFormattingStrategy`接口

```java
public class PrettySqlMultiLineFormat implements MessageFormattingStrategy {
	private static final Formatter FORMATTER = new BasicFormatterImpl();

	@Override
	public String formatMessage(int connectionId, String now, long elapsed, String category, String prepared, String sql) {
		return "#" + now + " | took " + elapsed + "ms | " + category + " | connection " + connectionId + " | " + FORMATTER.format(sql) +";";
	}
}
```

二、在 `spy.properties` 中指定

```
# 自定义日志打印
logMessageFormat=com.p6spy.engine.spy.appender.CustomLineFormat
customLogMessageFormat=%(currentTime) | SQL耗时： %(executionTime) ms | 连接信息： %(category)-%(connectionId) | 执行语句： %(sql)
```

附录: `spy.properties`详细说明

```properties
# 指定应用的日志拦截模块,默认为com.p6spy.engine.spy.P6SpyFactory 
#modulelist=com.p6spy.engine.spy.P6SpyFactory,com.p6spy.engine.logging.P6LogFactory,com.p6spy.engine.outage.P6OutageFactory

# 真实JDBC driver , 多个以 逗号 分割 默认为空
#driverlist=

# 是否自动刷新 默认 flase
#autoflush=false

# 配置SimpleDateFormat日期格式 默认为空
#dateformat=

# 打印堆栈跟踪信息 默认flase
#stacktrace=false

# 如果 stacktrace=true，则可以指定具体的类名来进行过滤。
#stacktraceclass=

# 监测属性配置文件是否进行重新加载
#reloadproperties=false

# 属性配置文件重新加载的时间间隔，单位:秒 默认60s
#reloadpropertiesinterval=60

# 指定 Log 的 appender，取值：
#appender=com.p6spy.engine.spy.appender.Slf4JLogger
#appender=com.p6spy.engine.spy.appender.StdoutLogger
#appender=com.p6spy.engine.spy.appender.FileLogger

# 指定 Log 的文件名 默认 spy.log
#logfile=spy.log

# 指定是否每次是增加 Log，设置为 false 则每次都会先进行清空 默认true
#append=true

# 指定日志输出样式  默认为com.p6spy.engine.spy.appender.SingleLineFormat , 单行输出 不格式化语句
#logMessageFormat=com.p6spy.engine.spy.appender.SingleLineFormat
# 也可以采用  com.p6spy.engine.spy.appender.CustomLineFormat 来自定义输出样式, 默认值是%(currentTime)|%(executionTime)|%(category)|connection%(connectionId)|%(sqlSingleLine)
# 可用的变量为:
#   %(connectionId)            connection id
#   %(currentTime)             当前时间
#   %(executionTime)           执行耗时
#   %(category)                执行分组
#   %(effectiveSql)            提交的SQL 换行
#   %(effectiveSqlSingleLine)  提交的SQL 不换行显示
#   %(sql)                     执行的真实SQL语句，已替换占位
#   %(sqlSingleLine)           执行的真实SQL语句，已替换占位 不换行显示
#customLogMessageFormat=%(currentTime)|%(executionTime)|%(category)|connection%(connectionId)|%(sqlSingleLine)

# date类型字段记录日志时使用的日期格式 默认dd-MMM-yy
#databaseDialectDateFormat=dd-MMM-yy

# boolean类型字段记录日志时使用的日期格式 默认boolean 可选值numeric
#databaseDialectBooleanFormat=boolean

# 是否通过jmx暴露属性 默认true
#jmx=true

# 如果jmx设置为true 指定通过jmx暴露属性时的前缀 默认为空
# com.p6spy(.<jmxPrefix>)?:name=<optionsClassName>
#jmxPrefix=

# 是否显示纳秒 默认false
#useNanoTime=false

# 实际数据源 JNDI
#realdatasource=/RealMySqlDS
# 实际数据源 datasource class
#realdatasourceclass=com.mysql.jdbc.jdbc2.optional.MysqlDataSource

# 实际数据源所携带的配置参数 以 k=v 方式指定 以 分号 分割
#realdatasourceproperties=port;3306,serverName;myhost,databaseName;jbossdb,foo;bar

# jndi数据源配置 
# 设置 JNDI 数据源的 NamingContextFactory。 
#jndicontextfactory=org.jnp.interfaces.NamingContextFactory
# 设置 JNDI 数据源的提供者的 URL。 
#jndicontextproviderurl=localhost:1099
# 设置 JNDI 数据源的一些定制信息，以分号分隔。 
#jndicontextcustom=java.naming.factory.url.pkgs;org.jboss.naming:org.jnp.interfaces

# 是否开启日志过滤 默认false， 这项配置是否生效前提是配置了 include/exclude/sqlexpression
#filter=false

# 过滤 Log 时所包含的表名列表，以逗号分隔 默认为空
#include=
# 过滤 Log 时所排除的表名列表，以逗号分隔 默认为空
#exclude=

# 过滤 Log 时的 SQL 正则表达式名称  默认为空
#sqlexpression=

#显示指定过滤 Log 时排队的分类列表，取值: error, info, batch, debug, statement,
#commit, rollback, result and resultset are valid values
# (默认 info,debug,result,resultset,batch)
#excludecategories=info,debug,result,resultset,batch

# 是否过滤二进制字段
# (default is false)
#excludebinary=false

# P6Log 模块执行时间设置，整数值 (以毫秒为单位)，只有当超过这个时间才进行记录 Log。 默认为0
#executionThreshold=

# P6Outage 模块是否记录较长时间运行的语句 默认false
# outagedetection=true|false
# P6Outage 模块执行时间设置，整数值 （以秒为单位)），只有当超过这个时间才进行记录 Log。 默认30s
# outagedetectioninterval=integer time (seconds)
```

## log4jdbc

添加依赖：

```xml
<dependency>
    <groupId>com.googlecode.log4jdbc</groupId>
    <artifactId>log4jdbc</artifactId>
    <version>1.2</version>
</dependency>
```

MySQL数据源配置换成：

```yaml
spring:
  datasource:
    url: jdbc:log4jdbc:mysql://127.0.0.1:3306/test?useUnicode=true&characterEncoding=utf8&useSSL=false
    username: root
    password: root
    driver-class-name: net.sf.log4jdbc.DriverSpy
```

# Spring Data JPA

## 结构图

![](https://cdn.yangbingdong.com/img/spring-boot-orm/jpa-struct.png)

## 配置

```yaml
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

### 默认驼峰模式

Spring Data Jpa 使用的默认策略是 `SpringPhysicalNamingStrategy` 与 `SpringImplicitNamingStrategy`, 就是驼峰模式的实现.

可以这样修改命名策略：

```properties
#PhysicalNamingStrategyStandardImpl
spring.jpa.hibernate.naming.physical-strategy=org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl
```

如果需要指定某个字段不使用驼峰模式可以直接使用`@Column(name = "aaa")`

## 基础CRUD操作

集成 `JpaRepository<T, ID>` , T为实体, ID为实体id:

```java
public interface UserRepository extends JpaRepository<User, Long> {
	Page<User> findByName(String name, Pageable pageable);
}
```

Controller:

```java
@Autowired
private UserRepository userRepository;

@GetMapping
public Iterable<User> getAllUsers() {
	return userRepository.findAll();
}

@PostMapping
public void addNewUser(@Valid @RequestBody User user) {
	userRepository.save(user);
}

/**
 * 验证排序和分页查询方法，Pageable的默认实现类：PageRequest
 * @return
 */
@GetMapping(path = "/page")
@ResponseBody
public Page<User> getAllUserByPage() {
	return userRepository.findAll(PageRequest.of(0, 2, Sort.by(new Sort.Order(Sort.Direction.ASC,"name"))));
}
/**
 * 排序查询方法，使用Sort对象
 * @return
 */
@GetMapping(path = "/sort")
@ResponseBody
public Iterable<User> getAllUsersWithSort() {
	return userRepository.findAll(Sort.by(new Sort.Order(Sort.Direction.ASC,"name")));
}
```

![](https://cdn.yangbingdong.com/img/spring-boot-orm/simple-jpa-repository-method.png)

`JpaRepository` 的默认实现类是 `SimpleJpaRepository`, 可以看到提供了大部分通用的方法.

## 定义查询方法

### 方法的查询策略设置

通过下面的命令来配置方法的查询策略(在`JpaRepositoriesAutoConfigureRegistrar`中已经自动配置, 实际Spring Boot项目中我们只需要引入JPA依赖即可, 不需要手动显示配置)：

```java
@EnableJpaRepositories(queryLookupStrategy= QueryLookupStrategy.Key.CREATE_IF_NOT_FOUND)
```

`QueryLookupStrategy.Key` 的值一共就三个：

- `Create`：直接根据方法名进行创建，规则是根据方法名称的构造进行尝试，一般的方法是从方法名中删除给定的一组已知前缀，并解析该方法的其余部分。如果方法名不符合规则，启动的时候会报异常。
- `USE_DECLARED_QUERY`：声明方式创建，即本书说的注解的方式。启动的时候会尝试找到一个声明的查询，如果没有找到将抛出一个异常，查询可以由某处注释或其他方法声明。
- `CREATE_IF_NOT_FOUND`：这个是默认的，以上两种方式的结合版。先用声明方式进行查找，如果没有找到与方法相匹配的查询，那用 Create 的方法名创建规则创建一个查询。

### 查询方法的创建

Spring Data 中有一套自己的方法命名查询规范, 一般是前缀 find…By、read…By、query…By、count…By 和 get…By等, `org.springframework.data.repository.query.parser.PartTree`:

![](https://cdn.yangbingdong.com/img/spring-boot-orm/part-tree-class.png)

![](https://cdn.yangbingdong.com/img/spring-boot-orm/subject-class.png)

Ex:

```java
interface PersonRepository extends Repository<User, Long> {
   // and的查询关系
   List<User> findByEmailAddressAndLastname(EmailAddress emailAddress, String lastname);
   // 包含distinct去重，or的sql语法
   List<User> findDistinctPeopleByLastnameOrFirstname(String lastname, String firstname);
   List<User> findPeopleDistinctByLastnameOrFirstname(String lastname, String firstname);
   // 根据lastname字段查询忽略大小写
   List<User> findByLastnameIgnoreCase(String lastname);
   // 根据lastname和firstname查询equal并且忽略大小写
   List<User> findByLastnameAndFirstnameAllIgnoreCase(String lastname, String firstname); 
  // 对查询结果根据lastname排序
   List<User> findByLastnameOrderByFirstnameAsc(String lastname);
   List<User> findByLastnameOrderByFirstnameDesc(String lastname);
}
```

使用的时候要配合不同的返回结果进行使用:

```java
interface UserRepository extends CrudRepository<User, Long> {
     long countByLastname(String lastname);//查询总数
     long deleteByLastname(String lastname);//根据一个字段进行删除操作
     List<User> removeByLastname(String lastname);
}
```

#### 方法命名查询关键字列表

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

最全支持关键字可查看: `org.springframework.data.repository.query.parser.Type`

### 查询结果的处理

#### 参数选择（Sort/Pageable）分页和排序

```java
Page<User> findByLastname(String lastname, Pageable pageable);
Slice<User> findByLastname(String lastname, Pageable pageable);
List<User> findByLastname(String lastname, Sort sort);
List<User> findByLastname(String lastname, Pageable pageable);		
```

#### 限制查询结果

在查询方法上加限制查询结果的关键字 First 和 Top:

```java
User findFirstByOrderByLastnameAsc();
User findTopByOrderByAgeDesc();
Page<User> queryFirst10ByLastname(String lastname, Pageable pageable);
Slice<User> findTop3ByLastname(String lastname, Pageable pageable);
List<User> findFirst10ByLastname(String lastname, Sort sort);
List<User> findTop10ByLastname(String lastname, Pageable pageable);
```

#### 查询结果的不同形式（List/Stream/Page/Future）

```java
@Query("select u from User u")
Stream<User> findAllByCustomQueryAndStream();
Stream<User> readAllByFirstnameNotNull();
@Query("select u from User u")
Stream<User> streamAllPaged(Pageable pageable);
```

关闭流:

```java
Stream<User> stream;
try {
   stream = repository.findAllByCustomQueryAndStream()
   stream.forEach(…);
} catch (Exception e) {
   e.printStackTrace();
} finally {
   if (stream!=null){
      stream.close();
   }
}
```

异步结果:

```java
@Async
Future<User> findByFirstname(String firstname); 
@Async
CompletableFuture<User> findOneByFirstname(String firstname); 
@Async
ListenableFuture<User> findOneByLastname(String lastname);
```
支持的返回结果:

| 返回值类型          | 描述                                                         |
| ------------------- | ------------------------------------------------------------ |
| `void`              | 不返回结果，一般是更新操作                                   |
| `Primitives`        | Java 的基本类型，一般常见的是统计操作（如 `long`、`boolean` 等）Wrapper types Java 的包装类 |
| `T`                 | 最多只返回一个实体，没有查询结果时返回 null。如果超过了一个结果会抛出 `IncorrectResultSizeDataAccessException` 的异常。 |
| `Iterator`          | 一个迭代器                                                   |
| `Collection`        | 集合                                                         |
| `List`              | `List` 及其任何子类                                          |
| `Optional`          | 返回 Java 8 或 Guava 中的 `Optional` 类。查询方法的返回结果最多只能有一个，如果超过了一个结果会抛出 `IncorrectResultSizeDataAccessException` 的异常 |
| `Option`            | Scala 或者 javaslang 选项类型                                |
| `Stream`            | Java 8 Stream                                                |
| `Future`            | Future，查询方法需要带有 `@Async` 注解，并**开启 Spring 异步执行方法的功能**。一般配合多线程使用。关系数据库，实际工作很少有用到. |
| `CompletableFuture` | 返回 Java8 中新引入的 `CompletableFuture` 类，查询方法需要带有 `@Async` 注解，并开启 Spring 异步执行方法的功能 |
| `ListenableFuture`  | 返回 `org.springframework.util.concurrent.ListenableFuture` 类，查询方法需要带有 `@Async` 注解，并开启 Spring 异步执行方法的功能 |
| `Slice`             | 返回指定大小的数据和是否还有可用数据的信息。需要方法带有 `Pageable` 类型的参数 |
| `Page`              | 在 `Slice` 的基础上附加返回分页总数等信息。需要方法带有 `Pageable` 类型的参数 |
| `GeoResult`         | 返回结果会附带诸如到相关地点距离等信息                       |
| `GeoResults`        | 返回 `GeoResult` 的列表，并附带到相关地点平均距离等信息      |
| `GeoPage`           | 分页返回 `GeoResult`，并附带到相关地点平均距离等信息         |

#### 实现机制

通过 `QueryExecutorMethodInterceptor` 这个类的源代码，我们发现，该类实现了 MethodInterceptor 接口，也就是说它是一个方法调用的拦截器， 当一个 Repository 上的查询方法，譬如说 findByEmailAndLastname 方法被调用，Advice 拦截器会在方法真正的实现调用前，先执行这个 MethodInterceptor 的 invoke 方法。这样我们就有机会在真正方法实现执行前执行其他的代码了。

然而对于 `QueryExecutorMethodInterceptor` 来说，最重要的代码并不在 invoke 方法中，而是在它的构造器 `QueryExecutorMethodInterceptor(RepositoryInformationr、Object customImplementation、Object target)` 中。

最重要的一段代码是这段：

```java
for (Method method : queryMethods) { 
     // 使用lookupStrategy，针对Repository接口上的方法查询Query
     RepositoryQuery query = lookupStrategy.resolveQuery(method, repositoryInformation, factory, namedQueries); invokeListeners(query);
     queries.put(method, query);
}
```

![](https://cdn.yangbingdong.com/img/spring-boot-orm/jpa-defining-query-method-processing.png)

## 注解查询

### @Query

```java
public @interface Query {
   /**
    * 指定JPQL的查询语句。（nativeQuery=true的时候，是原生的Sql语句）
    */
   String value() default "";
   /**
    * 指定count的JPQL语句，如果不指定将根据query自动生成。
    * （如果当nativeQuery=true的时候，指的是原生的Sql语句）
    */
   String countQuery() default "";
   /**
    * 根据哪个字段来count，一般默认即可。
    */
   String countProjection() default "";
   /**
    * 默认是false，表示value里面是不是原生的sql语句
    */
   boolean nativeQuery() default false;
   /**
    * 可以指定一个query的名字，必须唯一的。
    * 如果不指定，默认的生成规则是：
    * {$domainClass}.${queryMethodName}
    */
   String name() default "";
   /*
    * 可以指定一个count的query的名字，必须唯一的。
    * 如果不指定，默认的生成规则是：
    * {$domainClass}.${queryMethodName}.count
    */
   String countName() default "";
}
```

#### 用法

```java
public interface UserRepository extends JpaRepository<User, Long>{
  @Query("select u from User u where u.emailAddress = ?1")
  User findByEmailAddress(String emailAddress);
    
  @Query("select u from User u where u.firstname like %?1")
  List<User> findByFirstnameEndsWith(String firstname);
}	
```

原生SQL:

```java
public interface UserRepository extends JpaRepository<User, Long> {
  @Query(value = "SELECT * FROM USERS WHERE EMAIL_ADDRESS = ?1", nativeQuery = true)
  User findByEmailAddress(String emailAddress);
    
  @Query(value = "select * from user_info where first_name=?1 order by ?2",nativeQuery = true)
}
```

**注意:** `nativeQuery` 不支持直接 `Sort` 的参数查询, 需要类似上面一样使用原生的`order by`。

#### 排序

`@Query` 的 JPQL 情况下，想实现排序，方法上面直接用 `PageRequest` 或者直接用 `Sort` 参数都可以做到。

在排序实例中实际使用的属性需要与**实体模型里面的字段相匹配**，这意味着它们需要解析为查询中使用的属性或别名。这是一个`state_field_path_expression JPQL`定义，并且 Sort 的对象支持一些特定的函数。

```java
public interface UserRepository extends JpaRepository<User, Long> {
  @Query("select u from User u where u.lastname like ?1%")
  List<User> findByAndSort(String lastname, Sort sort);
  @Query("select u.id, LENGTH(u.firstname) as fn_len from User u where u.lastname like ?1%")
  List<Object[]> findByAsArrayAndSort(String lastname, Sort sort);
}
//调用方的写法，如下：
repo.findByAndSort("lannister", new Sort("firstname"));               
repo.findByAndSort("stark", new Sort("LENGTH(firstname)"));          
repo.findByAndSort("targaryen", JpaSort.unsafe("LENGTH(firstname)"));
repo.findByAsArrayAndSort("bolton", new Sort("fn_len"));  
```

#### 分页

直接用 Page 对象接受接口，参数直接用 `Pageable` 的实现类即可。

```java
public interface UserRepository extends JpaRepository<User, Long> {
  @Query(value = "select u from User u where u.lastname = ?1")
  Page<User> findByLastname(String lastname, Pageable pageable);
}
//调用者的写法
repository.findByFirstName("jackzhang",new PageRequest(1,10));
```

对原生 SQL 的分页支持，案例如下，但是支持的不是特别友好，以 MySQL 为例。

```java
 public interface UserRepository extends JpaRepository<UserInfoEntity, Integer>, JpaSpecificationExecutor<UserInfoEntity> {
   @Query(value = "select * from user_info where first_name=?1 /* #pageable# */",
         countQuery = "select count(*) from user_info where first_name=?1",
         nativeQuery = true)
   Page<UserInfoEntity> findByFirstName(String firstName, Pageable pageable);
}
//调用者的写法
return userRepository.findByFirstName("jackzhang",new PageRequest(1,10, Sort.Direction.DESC,"last_name"));
//打印出来的sql
select  *   from  user_info  where  first_name=? /* #pageable# */  order by  last_name desc limit ?, ?
```

### @Param

默认情况下，参数是**通过顺序**绑定在查询语句上的，这使得查询方法**对参数位置的重构**容易出错。为了解决这个问题，可以使用 `@Param` 注解指定方法参数的具体名称，通过绑定的参数名字做查询条件，这样不需要关心参数的顺序，推荐这种做法，比较利于代码重构。

```java
public interface UserRepository extends JpaRepository<User, Long> {
  @Query("select u from User u where u.firstname = :firstname or u.lastname = :lastname")
  User findByLastnameOrFirstname(@Param("lastname") String lastname,
                                 @Param("firstname") String firstname);
}
```

根据参数进行查询，top 10 前面说的 query method 关键字照样有用，如下：

```java
public interface UserRepository extends JpaRepository<User, Long> {
  @Query("select u from User u where u.firstname = :firstname or u.lastname = :lastname")
  User findTop10ByLastnameOrFirstname(@Param("lastname") String lastname,
                                 @Param("firstname") String firstname);
}
```

> 提醒：大家通过 @Query 定义自己的查询方法时，建议也用 Spring Data JPA 的 name query 的命名方法，这样下来风格就比较统一了。

### Spel 表达式的支持

在 Spring Data JPA 1.4 以后，支持在 `@Query` 中使用 SpEL 表达式（简介）来接收变量。

SpEL 支持的变量

| 变量名       | 使用方式                         | 描述                                              |
| ------------ | -------------------------------- | ------------------------------------------------- |
| `entityName` | `select x from #{#entityName} x` | 根据指定的 Repository 自动插入相关的 `entityName` |

> 有两种方式能被解析出来：
>
> - 如果定了 `@Entity` 注解，直接用其属性名。
> - 如果没定义，直接用实体的类的名称。

在以下的例子中，我们在查询语句中插入表达式：

```java
@Entity("User")
public class User {
   @Id
   @GeneratedValue
   Long id;
   String lastname;
}
//Repository写法
public interface UserRepository extends JpaRepository<User, Long> {
   @Query("select u from #{#entityName} u where u.lastname = ?1")
   List<User> findByLastname(String lastname);
}
```

这个 SPEL 的支持，比较适合自定义的 Repository，如果想写一个通用的 Repository 接口，那么可以用这个表达式来处理：

```java
@MappedSuperclass
public abstract class AbstractMappedType {
   …
   String attribute;
}
@Entity
public class ConcreteType extends AbstractMappedType { …
}
@NoRepositoryBean
public interface MappedTypeRepository<T extends AbstractMappedType> extends Repository<T, Long> {
   @Query("select t from #{#entityName} t where t.attribute = ?1")
   List<T> findAllByAttribute(String attribute);
}
public interface ConcreteRepository extends MappedTypeRepository<ConcreteType> { …
}
```

`MappedTypeRepository` 作为一个公用的父类，自己的 Repository 可以继承它，当调用 `ConcreteRepository` 执行 `findAllByAttribute` 方法的时候执行结果如下：

```sql
select t from ConcreteType t where t.attribute = ?1
```

### @Modifying 修改查询

可以通过在 `@Modifying` 注解实现只需要参数绑定的 update 查询的执行，我们来看个例子根据 lastName 更新 firstname 并且返回更新条数如下：

```java
@Modifying
@Query("update User u set u.firstname = ?1 where u.lastname = ?2")
int setFixedFirstnameFor(String firstname, String lastname);
```

简单的针对某些特定属性的更新，也可以直接用基类里面提供的通用 save 来做更新（即继承 `CrudRepository` 接口）。

**还有第三种方法就是自定义 Repository 使用 EntityManager 来进行更新操作。**

对删除操作的支持如下：

```java
interface UserRepository extends Repository<User, Long> {
  void deleteByRoleId(long roleId);
  @Modifying
  @Query("delete from User u where user.role.id = ?1")
  void deleteInBulkByRoleId(long roleId);
}
```

所以现在我们一共有四种方式来做更新操作：

- 通过方法表达式；
- 还有一种就是 `@Modifying` 注解；
- `@Query` 注解也可以做到；
- 继承 `CrudRepository` 接口。

### @Query 的优缺点与实践

| 分类     | 描述                                                         |
| -------- | ------------------------------------------------------------ |
| 优点     | （1）可以灵活快速的使用 JPQL 和 SQL                          |
|          | （2）对返回的结果和字段记性自定义                            |
|          | （3）支持连表查询和对象关联查询，可以组合出来复杂的 SQL 或者 JPQL |
|          | （4）可以很好的表达你的查询思路                              |
|          | （5）灵活性非常强，快捷方便                                  |
| 缺点     | （1）不支持动态查询条件，参数个数如果是不固定的不支持        |
|          | （2）有些读者会将返回结果用 Map 或者 Object[] 数组接收结果，会导致调用此方法的开发人员不知道返回结果里面到底有些什么数据 |
| 最佳实践 | （1）当出现很复杂的 SQL 或者 JPQL 的时候建议用视图           |
|          | （2）返回结果一定要用对象接收，最好每个对象里面的字段和你返回的结果一一对应 |
|          | （3）动态的 Query Param 会在后面的章节中讲到                 |
|          | （4）能用 JPQL 的就不要用 SQL                                |

## 常用注解

`@Entity(name = "t_user")`

`@Table(indexes = {...}`

`@Id`

`@GeneratedValue`

`@Column(length = 100, nullable = false)`

`@Enumerated(EnumType.STRING)`

`@Temporal(TemporalType.TIMESTAMP)`

`@PrePersist`

`@PreUpdate`

`@PreRemove`

`@CreationTimestamp`

`@UpdateTimestamp`


## 使用Tips

### 使用 @Convert 关联一对多的值对象

有时候在实体当中有某些字段是一个**值对象的集合**，我们又不想(也没必要)为其另起一张表，打个比方：订单里面的商品列表(只是打个比方，实际上应该是一张独立的表)。

例如设计一个访问日志对象，我们需要记录访问方法的行参与接收值：

```java
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
```java
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

* `@Convert`声明使用某个属性转换器(`ReqReceiveDataConverter`)
* `ReqReceiveDataConverter`需要实现`AttributeConverter<X,Y>`，`X`为实体的字段类型，`Y`对应需要持久化到DB的类型
* `@Converter(autoApply = true)`注解作用，如果有多个实体需要用到此属性转换器，不需要每个实体都的字段加上`@Convert`注解，自动对全部实体生效

### 发布领域事件

一般基于DDD的设计，在实体状态改变时(保存或更新实体)，为了保证其他边缘服务与之状态的统一，我们需要通过发布实体保存或更新事件，其他服务监听后做出相应的处理，大概像这样：

```java
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

  ```java
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

  ```java
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

  ```java
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

  ```java
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

![](https://cdn.yangbingdong.com/img/spring-boot-data/jpa-dirty01.png)

![](https://cdn.yangbingdong.com/img/spring-boot-data/jpa-dirty02.png)

如上图，这是利用AOP实现的操作日志记录，使用`AttributeConverter`与Fastjson实现`ReqReceiveData`转换成JSON字符串，可以看到在执行insert之后接着执行了一次update，那是因为JSON字符串字段顺序居然发生了变化！

不过后来折腾一下把顺序统一了，但还是会出现这种问题，百思不得其解，一样的字符串Hibernate也会认为这是Dirty的数据？

百般折腾得以解决(但还是搞不懂原因)：

value是Object类型，在set的时候调用`JSONObject.toJSON(value)`转成Object再set进去...

# 对象映射

> ***[https://www.baeldung.com/java-performance-mapping-frameworks](https://www.baeldung.com/java-performance-mapping-frameworks)***

# Elasticsearch

![](https://cdn.yangbingdong.com/img/spring-boot-elasticsearch/es-heart.svg)

## 概念

**索引(index)** `->` 类似于关系型数据库中**Database**

**类型(type)** `->` 类似于关系型数据库中**Table**

**文档(document)** `->` 类似于关系型数据库中**Record**

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

```yaml
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

![](https://cdn.yangbingdong.com/img/spring-boot-elasticsearch/elasticsearch-head-plugin.png)