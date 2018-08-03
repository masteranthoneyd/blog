# Spring Cloud Stack

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-docker-integration/spring-cloud-stack.jpg)

> Spring Cloud 是一系列框架的有序集合。它利用 Spring Boot 的开发便利性巧妙地简化了分布式系统基础设施的开发，如服务发现注册、配置中心、消息总线、负载均衡、断路器、数据监控等，都可以用 Spring Boot 的开发风格做到一键启动和部署。Spring 并没有重复制造轮子，它只是将目前各家公司开发的比较成熟、经得起实际考验的服务框架组合起来，通过 Spring Boot 风格进行再封装屏蔽掉了复杂的配置和实现原理，最终给开发者留出了一套简单易懂、易部署和易维护的分布式系统开发工具包。
>
> 至于各种框架组件的相关概念以及入门教程网上一大把，此篇博文主要记录个人在使用Spring Cloud构建微服务的一些配置以及踩坑...

# 服务注册中心


## 单节点

> 集成Docker部分请看 ***[Spring Boot Docker Integration](/2018/spring-boot-docker-elk/)***

### 核心依赖

```
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

### `application.yml`

```
spring:
  application:
    name: discovery
  profiles:
    active: single
  security:  ## http base security 帐号密码
    user:
      name: ybd
      password: ybd
eureka:
  client: # 以下两项默认为true
    fetch-registry: true
    register-with-eureka: true
  instance:
    prefer-ip-address: true
    ip-address: ${eureka.instance.hostname}
    instance-id: ${spring.application.name}:${spring.application.instance_id:${server.port}}

management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    health:
      show-details: ALWAYS
```

### `application-single.yml`
```
server:
  port: 8761
eureka:
  environment: dev
  instance:
    hostname: localhost
    prefer-ip-address: false
    metadata-map:
      user.name: ibalife
      user.password: ibalife
  client: 
    fetch-registry: false
    register-with-eureka: true
    service-url:
      defaultZone: http://ibalife:ibalife@${eureka.instance.hostname}:${server.port}/eureka/
  server:
    enable-self-preservation: false
    eviction-interval-timer-in-ms: 15000
```

### Security配置

开启`basic`的认证需要添加依赖：

```
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

配置类：

```
@EnableWebSecurity
class WebSecurityConfig extends WebSecurityConfigurerAdapter {

	private static final String EUREKA = "/eureka/**";

	@Override
	protected void configure(HttpSecurity http) throws Exception {
		http.csrf().ignoringAntMatchers(EUREKA);
		super.configure(http);
	}
}
```

## Docker Compose构建HA Eureka Server

**基于Compose运行高可用的Eureka**

### `application.yml`

```
spring:
  application:
    name: discovery
  profiles:
    active: single
  security:  # 安全认证帐号密码
    user:
      name: ybd 
      password: ybd
eureka:
  environment: prod # 在Eureka控制面板中显示prod环境
  client:  # 以下两项默认为true
    fetch-registry: true
    register-with-eureka: true # 注册自己
  instance:
    prefer-ip-address: true
    ip-address: ${eureka.instance.hostname}
    instance-id: ${spring.application.name}:${spring.application.instance_id:${server.port}}

management:  # Spring Boot Admin 使用的端点
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    health:
      show-details: ALWAYS
```

### `application-cluster1.yml`

```
server:
  port: 8761
eureka:
  instance:
    hostname: eureka-cluster1
    metadata-map:  # Spring Boot Admin 使用
      user.name: ibalife
      user.password: ibalife
  client:
    service-url:
      defaultZone: http://ibalife:ibalife@eureka-cluster2:8762/eureka/,http://ibalife:ibalife@eureka-cluster3:8763/eureka/
  server:
    enable-self-preservation: false # 关闭自我保护模式
```

### `application-cluster2.yml`

```
server:
  port: 8762
eureka:
  instance:
    hostname: eureka-cluster2
    metadata-map:
      user.name: ibalife
      user.password: ibalife
  client:
    service-url:
      defaultZone: http://ibalife:ibalife@eureka-cluster1:8761/eureka/,http://ibalife:ibalife@eureka-cluster3:8763/eureka/
  server:
    enable-self-preservation: false
```

### `application-cluster3.yml`

```
server:
  port: 8763
eureka:
  instance:
    hostname: eureka-cluster3
    metadata-map:
      user.name: ibalife
      user.password: ibalife
  client:
    service-url:
      defaultZone: http://ibalife:ibalife@eureka-cluster1:8761/eureka/,http://ibalife:ibalife@eureka-cluster2:8762/eureka/
  server:
    enable-self-preservation: false
```

### `docker-compose.yml`

```
version: '3.4'
services:
  eureka-cluster1:
    image: eureka-cluster:latest
    environment:
      - ACTIVE=cluster1
      - JAVA_OPTS=-Xms512m -Xmx512m
    ports:
      - 8761:8761
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://ibalife:ibalife@localhost:8761/actuator/health"]
      interval: 1m30s
      timeout: 10s
      retries: 3
      start_period: 30s
    networks:
      backend:
        aliases:
          - eureka-cluster1
  eureka-cluster2:
    image: eureka-cluster:latest
    environment:
      - ACTIVE=cluster2
      - JAVA_OPTS=-Xms512m -Xmx512m
    ports:
      - 8762:8762
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://ibalife:ibalife@localhost:8762/actuator/health"]
      interval: 1m30s
      timeout: 10s
      retries: 3
      start_period: 30s
    networks:
      backend:
        aliases:
          - eureka-cluster2
  eureka-cluster3:
    image: eureka-cluster:latest
    environment:
      - ACTIVE=cluster3
      - JAVA_OPTS=-Xms512m -Xmx512m
    ports:
      - 8763:8763
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://ibalife:ibalife@localhost:8763/actuator/health"]
      interval: 1m30s
      timeout: 10s
      retries: 3
      start_period: 30s
    networks:
      backend:
        aliases:
          - eureka-cluster3

networks:
  backend:
    external:
      name: backend
```

### 启动

启动前确保创建好了网络：

```
docker network create --opt encrypted -d=overlay --attachable --subnet 10.10.0.0/16 backend
docker-compse up -d
```

此时在`Portainer`中可以看到三个容器已经启动：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-docker-integration/portainer-eureka.png)

随意一个eureka端口都能看到另外两个服务：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-docker-integration/compose-up03.png)

如果使用swarm mode：

```
export $(cat .env) && docker stack deploy --compose-file=docker-compose.yml eureka-stack
```

**注意**：目前使用stack方式启动是无法加载`env_file`的，所以需要预先加载一下。

我们的app通过合适的`network`交互应该是这样的：

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-docker-integration/cnm-demo.png)

### 踩坑(容器中服务下线无法向注册中心注销服务)

在Docker中程序，如果PID不是1，是接收不到`docker-compose down`发出的`sigterm`信号从而导致只能等待被Kill，不能向注册中心注销。

解决方法是在`Dockerfile`中的入口使用`ENTRYPOINT exec java -jar ... `这种方式 

![](http://ojoba1c98.bkt.clouddn.com/img/spring-cloud-docker-integration/docker-pid1.png)

### Eureka Edgware.RELEASE版本注册优化

在`Edgware.RELEASE`版本中相比之前的步骤，省略了在主函数上添加`@EnableDiscoveryClient`注解这一过程。Spring Cloud默认认为客户端是要完成向注册中心进行注册的。

- 添加对应的`pom`依赖.
- `properties`文件进行配置

**添加pom依赖**

```
<dependency>
   <groupId>org.springframework.cloud</groupId>
   <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

**properties文件进行配置**

```
spring.application.name=EUREKA-CLIENT
eureka.client.service-url.defaultZone=http://localhost:8761/eureka
```

启动Eureka Client客户端，访问<http://localhost:8761/eureka>
可以看到EUEREKA-CLIENT已经注册到Eureka Server服务上了。

**关闭自动注册功能**

spring cloud提供了一个参数，该参数的作用是控制是否要向Eureka Server发起注册。具体参数为：

```
//默认为true,如果控制不需要向Eureka Server发起注册将该值设置为false.
spring.cloud.service-registry.auto-registration.enabled = xxx
```

可以在**JUnit测试**中通过该变量关闭服务发现：

```
@BeforeClass
public static void beforeClass() {
	System.setProperty("spring.cloud.service-registry.auto-registration.enabled", "false");
}
```

### Eureka的自我保护模式

当Eureka提示下面一段话的时候，就表示它已经进入保护模式：

```
EMERGENCY! EUREKA MAY BE INCORRECTLY CLAIMING INSTANCES ARE UP WHEN THEY'RE NOT.
RENEWALS ARE LESSER THAN THRESHOLD AND HENCE THE INSTANCES ARE NOT BEING EXPIRED JUST TO BE SAFE.
```

保护模式主要用于一组客户端和Eureka Server之间存在网络分区场景下的保护。一旦进入保护模式，Eureka Server将会尝试保护其服务注册表中的信息，不再删除服务注册表中的数据（也就是不会注销任何微服务）。

解决方法如下：

服务器端配置：

```
eureka:
  server:
    enable-self-preservation: false
    eviction-interval-timer-in-ms: 15000
```

客户端配置：

```
eureka:
  instance:
    lease-expiration-duration-in-seconds: 30 
    lease-renewal-interval-in-seconds: 10
```

**注意：**
**更改Eureka更新频率将打破服务器的自我保护功能，生产环境下不建议自定义这些配置。**
