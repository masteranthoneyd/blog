# Spring Boot 之数据篇

![](https://cdn.yangbingdong.com/img/spring-boot-orm/spring-data-learning.png)

# Preface

> 后端应用当中与DB交互也是必不可少的一部, 在Java中我们将交互部分抽象成了 **ORM**(Object Relational Mapping), 以下是数据源以及ORM相关...

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

# 表与数据初始化

## 使用 Hibernate 初始化

可以显式设置 `spring.jpa.hibernate.ddl-auto` ，标准的Hibernate属性值有 `none` ， `validate` ， `update` ， `create` ， `create-drop` 。Spring Boot根据数据库是否为内嵌数据库来选择相应的默认值，如果是内嵌型的则默认值为 `create-drop` ，否则为 `none` 。通过查看 `Connection` 类型可以检查是否为内嵌型数据库，`hsqldb`，`h2`和`derby`是内嵌的，其他都不是。当从内存数据库迁移到一个真正的数据库时，需要当心，在新的平台中不能对数据库表和数据是否存在进行臆断，也需要显式设置 `ddl-auto` ，或使用其他机制初始化数据库。

> 可以通过启用`org.hibernate.SQL` 来输出Schema的创建过程。当[DEBUG MODE](http://docs.spring.io/spring-boot/docs/1.5.4.RELEASE/reference/htmlsingle/#boot-features-logging-console-output)被开启的时候，这个功能就已经被自动开启了。

此外，启动时处于classpath根目录下的 `import.sql` 文件会被执行(前提是`ddl-auto`属性被设置为 `create` 或 `create-drop`)。这在demos或测试时很有用，但在生产环境中可能不期望这样。这是Hibernate的特性，和Spring没有一点关系。

## 使用 Spring JDBC 初始化

指定初始化脚本位置: 

```yaml
spring:
  datasource:
    driver-class-name: org.h2.Driver
    schema: classpath:db/schema-h2.sql
    data: classpath:db/data-h2.sql
    url: jdbc:h2:mem:test
    username: root
    password: test
    initialization-mode: always # 默认为 embedded
```

不能与Hibernate的创建表功能一起开启, 否则会报错.

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

# Spring 事务监控

某些特殊的场景下, 我们需要在事务开启时, 完成时做一些事情, 比如释放一些资源. 

## TransactionSynchronization

Spring事务的核心部分在 `TransactionInterceptor#invoke`, `TransactionInterceptor` 继承了 `TransactionAspectSupport`, `TransactionAspectSupport` 使用 `AbstractPlatformTransactionManager` 的实现类操作事务. `AbstractPlatformTransactionManager` 中的 `processCommit` 以及  `processRollback` 中的几个节点会调用到 `TransactionSynchronizationUtils` 中的一些方法: 

![](https://cdn.yangbingdong.com/img/spring-boot-orm/spring-tx01.png)

![](https://cdn.yangbingdong.com/img/spring-boot-orm/spring-tx02.png)

这些被trigger的类就是 `TransactionSynchronization` 的实现类.

`TransactionSynchronizationUtils` 通过 `TransactionSynchronizationManager#getSynchronizations` 来获取 `TransactionSynchronization` 列表, 而 `TransactionSynchronizationManager` 是通过 `ThreadLocal` 来管理这些类的:

![](https://cdn.yangbingdong.com/img/spring-boot-orm/spring-tx03.png)

![](https://cdn.yangbingdong.com/img/spring-boot-orm/spring-tx04.png)

![](https://cdn.yangbingdong.com/img/spring-boot-orm/spring-tx05.png)

示例:

```java
@Component
@Slf4j
public class TestTransactionSynchronization extends TransactionSynchronizationAdapter {

	@Override
	public int getOrder() {
		return 0;
	}

	@Override
	public void suspend() {
		log.info("#################### suspend");
	}

	@Override
	public void resume() {
		log.info("#################### resume");
	}

	@Override
	public void flush() {
		log.info("#################### flush");
	}

	@Override
	public void beforeCommit(boolean readOnly) {
		log.info("#################### beforeCommit");
	}

	@Override
	public void beforeCompletion() {
		log.info("#################### beforeCompletion");
	}

	@Override
	public void afterCommit() {
		log.info("#################### afterCommit");
	}

	@Override
	public void afterCompletion(int status) {
		log.info("#################### afterCompletion");
	}
}
```

那么这个类什么时候注册进 `TransactionSynchronizationManager` 呢? 答案是每次事务开启的时候, 因为这个是使用 `ThreadLocal` 保存的, 每次事务过后会被清空掉. 我们可以使用切面, 将打有 `@Transactional` 注解的方法增强一下:

```java
@Component
@Aspect
@Slf4j
public class TestTransactionAspect {

	@Autowired
	private TestTransactionSynchronization testTransactionSynchronization;


	@Before(value = "@annotation(tx)")
	public void doAfterReturning(Transactional tx) {
		TransactionSynchronizationManager.registerSynchronization(testTransactionSynchronization);
	}
}
```

这样就行了~

## 继承DataSourceTransactionManager

上面的方法有一个缺点, 不能在事务开启时做一些事情, 可以通过继承 `DataSourceTransactionManager` 来实现:

```java
@Slf4j
public class CustomTransactionManager extends DataSourceTransactionManager {

	private static final long serialVersionUID = -5831041749053502702L;

	public CustomTransactionManager(DataSource dataSource) {
		super(dataSource);
	}

	@Override
	protected void doCleanupAfterCompletion(Object transaction) {
		log.info("#################### doCleanupAfterCompletion");
		super.doCleanupAfterCompletion(transaction);
	}

	@Override
	protected void doBegin(Object transaction, TransactionDefinition definition) {
		log.info("#################### doBegin");
		super.doBegin(transaction, definition);
	}
}
```

配置类:

```java
@Configuration
@ConditionalOnClass({PlatformTransactionManager.class})
@EnableConfigurationProperties(DataSourceProperties.class)
public class CustomDataSourceTransactionManagerAutoConfiguration {

	@Bean
	public DataSourceTransactionManager transactionManager(DataSource dataSource,
														   ObjectProvider<TransactionManagerCustomizers> transactionManagerCustomizers) {
		DataSourceTransactionManager transactionManager = new CustomTransactionManager(dataSource);
		transactionManagerCustomizers.ifAvailable(
				(customizers) -> customizers.customize(transactionManager));
		return transactionManager;
	}
}
```

## 判断当前方法是否在事务环境中

通过上面的 `TransactionSynchronizationManager` 可以发现定义了很多 `ThreadLocal`:

![](https://cdn.yangbingdong.com/img/spring-boot-orm/spring-tx05.png)

可以看到变量中有一个 `actualTransactionActive` 以及 `currentTransactionReadOnly`, 通过这两个变量可以判断当前是否在事务当中, Spring很多代码中也是通过这个来判断的, 比如 `RedisConnectionUtils#isActualNonReadonlyTransactionActive` :

![](https://cdn.yangbingdong.com/img/spring-boot-orm/spring-tx06.png)

# 对象映射

> ***[https://www.baeldung.com/java-performance-mapping-frameworks](https://www.baeldung.com/java-performance-mapping-frameworks)***

# ORM 对比

- MyBatis：MyBatis 本是 Apache 的一个开源项目 iBatis，2010 年这个项目由 Apache Software Foundation 迁移到了 Google Code，并且改名为 MyBatis，其**着力于 POJO 与 SQL 之间的映射关系**，可以进行更为细致的 SQL，使用起来十分灵活、上手简单、容易掌握，所以深受开发者的喜欢，目前市场占有率最高，比较适合互联应用公司的 API 场景; 缺点就是工作量比较大，需要各种配置文件的配置和 SQL 语句。
- Hibernate：Hibernate 是一个开放源代码的对象关系映射框架，它对 JDBC 进行了非常轻量级的对象封装，使得 Java 程序员可以随心所欲的使用对象编程思维来操纵数据库，并且对象有自己的生命周期，**着力点对象与对象之间关系**，有自己的 HQL 查询语言，所以数据库移植性很好。Hibernate 是完备的 ORM 框架，是符合 JPA 规范的，有自己的缓存机制，上手来说比较难，比较适合企业级的应用系统开发。
- Spring Data JPA：可以理解为 JPA 规范的再次封装抽象，底层还是使用了 Hibernate 的 JPA 技术实现，引用 JPQL(Java Persistence Query Language)查询语言，属于 Spring 的整个生态体系的一部分。由于 Spring Boot 和 Spring Cloud 在市场上的流行，Spring Data JPA 也逐渐进入大家的视野，他们有机的整体，使用起来比较方便，加快了开发的效率，使开发者不需要关系和配置更多的东西，完全可以沉浸在 Spring 的完整生态标准的实现下，上手简单、开发效率高，又对对象的支持比较好，又有很大的灵活性，市场的认可度越来越高。

# MyBatis

对于MyBatis, 现已有很优秀的二次封装框架, 比如 ***[Mapper4](https://github.com/abel533/Mapper)***, ***[MtBatis-Plus](https://github.com/baomidou/mybatis-plus)*** 等.

# Spring Data JPA

> 请看 ***[Spring Data JPA 拾遗](/2018/spring-boot-data-jpa-learning)***