# Bboss 客户端使用

> 完整文档: ***[https://esdoc.bbossgroups.com/#/](https://esdoc.bbossgroups.com/#/)***

# 配置加载

## 默认配置文件加载顺序

要获取 client, **必须先初始化配置文件(最终调用都是 `ElasticSearchConfigBoot#boot`)**, 核心代码在 `org.frameworkset.elasticsearch.ElasticSearchHelper#init` 中.

* 可通过手动调用 `ElasticSearchBoot` 或者 `ElasticSearchConfigBoot` 的 `boot` 方法初始化配置

* 如果**没有显式手动调用** `boot`, 则 `ElasticSearchHelper#init` 中会通过反射调用 `ElasticSearchConfigBoot#boot` 方法, 最终走到 `DefaultApplicationContext.getApplicationContext("conf/elasticsearch-boot-config.xml",forceBoot)` 这一行, 而 `elasticsearch-boot-config.xml` 是这样的定义的:

  ```xml
  <properties>
      <!--
          优先从bboss es属性配置文件加载扩展属性，其次从spring boot 配置文件application.properties加载属性
          必须配置elasticsearch.rest.hostNames这一个属性，其他属性可选
      -->
      <!-- <config file="conf/elasticsearch.properties,application.properties,config/application.properties"/>-->
      <config plugin="org.frameworkset.elasticsearch.boot.ElasticSearchPropertiesFilePlugin"/>
   </properties>
  ```

  所以最终的加载顺序在 `ElasticSearchPropertiesFilePlugin` 类中定义的:

  ```java
  public class ElasticSearchPropertiesFilePlugin implements PropertiesFilePlugin {
  	private static String elasticSearchConfigFiles = "conf/elasticsearch.properties,application.properties,config/application.properties";
  
      ......
  }
  ```

* 所以默认的加载顺序为(从上往下):

  * `conf/elasticsearch.properties`
  * `application.properties`
  * `config/application.properties`

## 自定义配置文件

eg: 读取 `resources` 文件下的 `elasticsearch.properties`:

```java
ElasticSearchBoot.boot("elasticsearch.properties");
ClientInterface restClient = ElasticSearchHelper.getRestClientUtil();
```

> `ElasticSearchBoot.boot("elasticsearch.properties")` 将 `ElasticSearchPropertiesFilePlugin.elasticSearchConfigFiles` 改成 `elasticsearch.properties` 并调用 `ElasticSearchConfigBoot#boot`.

## Spring Boot 中的配置加载

添加 starter(与 Spring Boot 有**日志依赖冲突**, 注意移除):

```xml
<dependency>
    <groupId>com.bbossgroups.plugins</groupId>
    <artifactId>bboss-elasticsearch-spring-boot-starter</artifactId>
    <version>{最新版本}</version>
    <exclusions>
        <exclusion>
            <artifactId>slf4j-log4j12</artifactId>
            <groupId>org.slf4j</groupId>
        </exclusion>
    </exclusions>
</dependency>
```

集成改 starter 后, 将读取 `spring.elasticsearch.bboss` 前缀的配置并加载 `BBossESStarter`, 具体请看: `BBossESAutoConfiguration`.

最终构建出一个 `Map` 的配置对象并调用 `ElasticSearchBoot.boot`.

## 配置文件示例

***[https://esdoc.bbossgroups.com/#/spring-booter-with-bboss?id=_311-applicationproperties](https://esdoc.bbossgroups.com/#/spring-booter-with-bboss?id=_311-applicationproperties)***

> 这些配置的含义, 可以参考文档:《*[高性能elasticsearch ORM开发库使用介绍](https://esdoc.bbossgroups.com/#/development)*》章节2进行了解

# 获取 Client

## 普通项目环境

```java
//创建加载配置文件的客户端工具，单实例多线程安全
//Get a ConfigRestClientUtil instance
ClientInterface clientUtil = ElasticSearchHelper.getConfigRestClientUtil("esmapper/demo.xml");
//Build a RestClientUtil instance, single instance multi-thread security
ClientInterface clientUtil = ElasticSearchHelper.getRestClientUtil() ;
```

## Spring Boot 项目环境

```java
@Autowired
private BBossESStarter bbossESStarter;
//Get a ConfigRestClientUtil instance to load configuration files, single instance multithreaded security
ClientInterface clientUtil = bbossESStarter.getConfigRestClient(mappath);
//Build a RestClientUtil instance, single instance multi-thread security
ClientInterface clientUtil = bbossESStarter.getRestClient(); 
```
