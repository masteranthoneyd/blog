# Bboss 客户端使用

> 完整文档: ***[https://esdoc.bbossgroups.com/#/](https://esdoc.bbossgroups.com/#/)***

# 配置加载

## 默认配置文件加载顺序

要获取 client, **必须先初始化配置文件(boot)**, 核心代码在 `org.frameworkset.elasticsearch.ElasticSearchHelper#init` 中.

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

# 获取 Client

```java
ClientInterface restClient = ElasticSearchHelper.getRestClientUtil();
String response = restClient.executeHttp("_cluster/state?pretty",ClientInterface.HTTP_GET);
```

