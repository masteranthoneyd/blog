---
title: Spring Cloud Stack Learning
date: 2018-06-09 16:55:08
categories: [Programming, Java, Spring Cloud]
tags: [Java, Spring Cloud]
---

![](https://cdn.yangbingdong.com/img/spring-cloud-docker-integration/spring-cloud-stack.jpg)

# Preface

> Spring Cloud 是一系列框架的有序集合。它利用 Spring Boot 的开发便利性巧妙地简化了分布式系统基础设施的开发，如服务发现注册、配置中心、消息总线、负载均衡、断路器、数据监控等，都可以用 Spring Boot 的开发风格做到一键启动和部署。Spring 并没有重复制造轮子，它只是将目前各家公司开发的比较成熟、经得起实际考验的服务框架组合起来，通过 Spring Boot 风格进行再封装屏蔽掉了复杂的配置和实现原理，最终给开发者留出了一套简单易懂、易部署和易维护的分布式系统开发工具包。
>
> 至于各种框架组件的相关概念以及入门教程网上一大把，此篇博文主要记录个人在使用Spring Cloud构建微服务的一些配置以及踩坑...
>
> 集成Docker部分请看 ***[Spring Boot Docker Integration](/2018/spring-boot-docker-elk/)***

<!--more-->

# Eureka

> Eureka是Netflix开发的服务发现组件，本身是一个基于REST的服务。Spring Cloud将它集成在其子项目`spring-cloud-netflix`中，以实现Spring Cloud的服务发现功能。


## 单节点

### 核心依赖

```
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
</dependency>

<!-- Base认证需要，前端账户密码登陆 -->
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

management: # 暴露所有端点，Spring Boot Admin监控使用
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    health:
      show-details: ALWAYS
```

- `eureka.client.register-with-eureka`：表示是否将自己注册到 Eureka Server，默认为 true。
- `eureka.client.fetch-registry`：表示是否从 Eureka Server 获取注册信息，默认为 true。
- `eureka.client.service-url.defaultZone`：设置与 Eureka Server 交互的地址，查询服务和注册服务都需要依赖这个地址。默认是 <http://localhost:8761/eureka> ；多个地址可使用英文逗号（,）分隔。

### `application-single.yml`

```
server:
  port: 8761
eureka:
  environment: dev
  instance:
    hostname: localhost
    prefer-ip-address: false
    metadata-map:  # 由于配置了安全认证，Spring Boot Admin 通过拿到此信息获取Eureka的端点信息
      user.name: ybd
      user.password: ybd
  client: 
    fetch-registry: false
    register-with-eureka: true
    service-url:
      defaultZone: http://ybd:ybd@${eureka.instance.hostname}:${server.port}/eureka/
  server:
    enable-self-preservation: false  # 禁用保护模式
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

## Docker构建HA Eureka Server

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
  cloud:  # 忽略以下网卡
    inetutils:
      ignored-interfaces:
      - eth0
      - eth1
      - eth2
      - eth3
      - lo
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
    prefer-ip-address: true  # 优先使用ip
    ip-address: eureka-cluster1 # ip地址，这里对应的是docker compose文件中的网络别名aliases
    instance-id: ${spring.application.name}:${spring.application.instance_id:${server.port}}
    metadata-map:  # spring boot admin 会通过eureka读取该信息从而通过认证拿到相关服务发现信息
      user.name: ybd
      user.password: ybd
  client:
    service-url:
      defaultZone: http://ybd:ybd@eureka-cluster2:8762/eureka/,http://ybd:ybd@eureka-cluster3:8763/eureka/
  server:
    enable-self-preservation: false # 关闭自我保护模式
```

### `application-cluster2.yml`

```
server:
  port: 8762
eureka:
  instance:
    prefer-ip-address: true  # 优先使用ip
    ip-address: eureka-cluster2 # ip地址，这里对应的是docker compose文件中的网络alias
    metadata-map:
      user.name: ybd
      user.password: ybd
  client:
    service-url:
      defaultZone: http://ybd:ybd@eureka-cluster1:8761/eureka/,http://ybd:ybd@eureka-cluster3:8763/eureka/
  server:
    enable-self-preservation: false
```

### `application-cluster3.yml`

```
server:
  port: 8763
eureka:
  instance:
    prefer-ip-address: true  # 优先使用ip
    ip-address: eureka-cluster3 # ip地址，这里对应的是docker compose文件中的网络alias
    metadata-map:
      user.name: ybd
      user.password: ybd
  client:
    service-url:
      defaultZone: http://ybd:ybd@eureka-cluster1:8761/eureka/,http://ybd:ybd@eureka-cluster2:8762/eureka/
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
      test: ["CMD", "curl", "-f", "http://ybd:ybd@localhost:8761/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 15s
    deploy:
      placement:
        constraints:
        - node.hostname == node1
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
      test: ["CMD", "curl", "-f", "http://ybd:ybd@localhost:8762/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 15s
    deploy:
      placement:
        constraints:
        - node.hostname == node2
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
      test: ["CMD", "curl", "-f", "http://ybd:ybd@localhost:8763/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 15s
    deploy:
      placement:
        constraints:
        - node.hostname == node3
    networks:
      backend:
        aliases:
          - eureka-cluster3

networks:
  backend:
    external:
      name: backend
```

### Docker Compose启动

启动前确保创建好了网络：

```
docker network create -d=overlay --attachable --subnet 10.10.0.0/16 backend
docker-compse up -d
```

此时在`Portainer`中可以看到三个容器已经启动：

![](https://cdn.yangbingdong.com/img/spring-cloud-docker-integration/portainer-eureka.png)

随意一个eureka端口都能看到另外两个服务：

![](https://cdn.yangbingdong.com/img/spring-cloud-docker-integration/compose-up03.png)

### Docker Swarm启动

由于目前使用stack方式启动是无法加载`env_file`的，所以需要预先加载一下:

```
export $(cat .env) && docker stack deploy --compose-file=docker-compose.yml eureka-stack
```

我们的app通过合适的`network`交互应该是这样的：

![](https://cdn.yangbingdong.com/img/spring-cloud-docker-integration/cnm-demo.png)

#### 注意事项（ip与hostname混乱）

之前使用Docker Compose方式启动服务没什么问题，后来换成Docker Swarm方式启动，在Eureka的面板中发现有些服务是ip，有些是hostname，但都注册成功，不过某些服务相互之间又访问不了。Google一番后的解决方案：

Server端跟Client端都使用以下配置：

```
spring:
  cloud:  
    inetutils:
      ignored-interfaces:
      - eth0
      - eth1
      - eth2
      - eth3
      - lo
      
eureka:
  instance:
    prefer-ip-address: true
    ip-address: eureka-cluster1 # 这里对应上面compose文件中的aliases
    instance-id: ${spring.application.name}:${spring.application.instance_id:${server.port}}
```

### 踩坑(容器中服务下线无法向注册中心注销服务)

在Docker中程序，如果PID不是1，是接收不到`docker-compose down`发出的`sigterm`信号从而导致只能等待被Kill，不能向注册中心注销。

解决方法是在`Dockerfile`中的入口使用`ENTRYPOINT exec java -jar ... `这种方式 

![](https://cdn.yangbingdong.com/img/spring-cloud-docker-integration/docker-pid1.png)

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

### **关闭自动注册功能**

Spring Cloud提供了一个参数，该参数的作用是控制是否要向Eureka Server发起注册。具体参数为：

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

## 修改Eureka界面UI

覆盖对应源码中的界面文件即可：

![](https://cdn.yangbingdong.com/img/spring-cloud-docker-integration/eureka-ui.png)

效果图：
![](https://cdn.yangbingdong.com/img/spring-cloud-docker-integration/eureka-custom.png)

**注意事项**：

如果`pom.xml`中的`parent`不是`spring-boot-starter-parent`，这些样式文件需要新建一个项目另外打包成jar包再引入方可生效。

# RPC(Remote Procedure Call)

> 这里指针对Http协议调用

通过注册中心，服务间的基本调用如下：

![](https://cdn.yangbingdong.com/img/spring-cloud-docker-integration/micro-rpc.jpg)

调用方式主要有三种（基本上在实际应用中都使用Feign）

**前置条件：集成服务注册中心**

服务提供者（`service-a`）：

```
@RestController
@RequestMapping("/service-a")
public class HelloController {

	@GetMapping("/{name}")
	public String sayHello(@PathVariable String name) throws UnknownHostException {
		InetAddress localHost = InetAddress.getLocalHost();
		return localHost + ":  Hello 『" + name + "』  , Date: " + new Date();
	}
}
```

## LoadBalancerClient

初始化`RestTemplate`，用来发起 REST 请求。

```
@Bean
public RestTemplate restTemplate() {
	return new RestTemplate();
}
```

消费者（`service-b`）：

```
@RestController
@RequestMapping("/service-b")
public class HelloController {
	@Resource
	private LoadBalancerClient client;

	@Resource
	private RestTemplate restTemplate;

	@GetMapping("/{name}")
	public String hello(@PathVariable String name) {
		name += "!";
		ServiceInstance instance = client.choose("service-a");
		String url = "http://" + instance.getHost() + ":" + instance.getPort() + "/service-a/" + name;
		return restTemplate.getForObject(url, String.class);
	}
}
```

访问`http://127.0.0.1:8082/service-b/ybd`，返回：

```
ybd-PC/127.0.1.1: Hello 『ybd!』 , Date: Wed Aug 08 18:30:48 CST 2018
```

## Spring Cloud Ribbon

>  它是一个基于 HTTP 和 TCP 的客户端负载均衡器。它可以通过在客户端中配置 ribbonServerList 来设置服务端列表去轮询访问以达到均衡负载的作用。当 Ribbon 与 Eureka 联合使用时，ribbonServerList 会被 DiscoveryEnabledNIWSServerList 重写，扩展成从 Eureka 注册中心中获取服务实例列表。同时它也会用 NIWSDiscoveryPing 来取代 IPing，它将职责委托给 Eureka 来确定服务端是否已经启动。

为`RestTemplate`添加`@LoadBalanced`注解:

```
@LoadBalanced
@Bean
public RestTemplate restTemplate() {
	return new RestTemplate();
}
```

Controller:

修改 controller，去掉`LoadBalancerClient`，并修改相应的方法，直接用 `RestTemplate`发起请求

```
@RestController
@RequestMapping("/service-b")
public class HelloController {
	@Resource
	private RestTemplate restTemplate;

	@GetMapping("/{name}")
	public String hello(@PathVariable String name) {
		name += "!";
		String url = "http://service-a/service-a/" + name;
		return restTemplate.getForObject(url, String.class);
	}
}
```

## Spring Cloud Feign

依赖（使用OkHttp组件）：

```
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>

<dependency>
    <groupId>io.github.openfeign</groupId>
    <artifactId>feign-okhttp</artifactId>
</dependency>
```

配置：

```
feign:
  httpclient:
    enabled: false
  okhttp:
    enabled: true
```

在启动类上加上`@EnableFeignClients`

```
@EnableFeignClients
@SpringBootApplication
public class ServiceBApplication {

	public static void main(String[] args) {
		SpringApplication.run(ServiceBApplication.class, args);
	}
}
```

Feign:

```
@FeignClient(value = "service-a", path = "/service-a")
public interface HelloRemoteClient {

	@GetMapping("/{name}")
	String sayHello(@PathVariable("name") String name);
}
```

* `value`指被调用方的服务名
* `path`请求指定前缀，例如上面的`sayHello`会请求`/service-a/{name}`这个url

调用：

```
@RestController
@RequestMapping("/service-b")
public class HelloController {

	@Resource
	private HelloRemoteClient helloClient;

	@GetMapping("/{name}")
	public String hello(@PathVariable String name) {
		name += "!";
		return helloClient.sayHello(name);
	}
}
```

### 踩坑

```
Caused by: java.lang.IllegalStateException: PathVariable annotation was empty on param 0.
```

这个大概的意思就是`@PathVariable`的第一个参数为空。。。

因为之前的写法是这样的：

```
@GetMapping("/{name}")
String sayHello(@PathVariable String name);
```

**正确姿势**是这样的：

```
@GetMapping("/{name}")
String sayHello(@PathVariable("name") String name);
```

`@PathVariable`需要指定占位符的名字`("name")`

# Spring Cloud Gateway

Spring Cloud Gateway 是 Spring Cloud 的一个全新项目，该项目是基于 Spring 5.0，Spring Boot 2.0 和 Project Reactor 等技术开发的网关，它旨在为微服务架构提供一种简单有效的统一的 API 路由管理方式。

Spring Cloud Gateway 作为 Spring Cloud 生态系统中的网关，目标是替代 Netflix Zuul，其不仅提供统一的路由方式，并且基于 Filter 链的方式提供了网关基本的功能，例如：安全、监控、埋点和限流等。

Spring Cloud Gateway 的特征：

- 基于 Spring Framework 5，Project Reactor 和 Spring Boot 2.0
- 动态路由
- Predicates 和 Filters 作用于特定路由
- 集成 Hystrix 断路器
- 集成 Spring Cloud DiscoveryClient
- 易于编写的 Predicates 和 Filters
- 限流
- 路径重写

**流程图**：

![](https://cdn.yangbingdong.com/img/spring-cloud-docker-integration/spring-cloud-gateway-flow.jpg)



# Spring Boot Admin

![](https://cdn.yangbingdong.com/img/spring-cloud-docker-integration/spring-boot-admin.png)

## 依赖

```
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <dependency>
        <groupId>de.codecentric</groupId>
        <artifactId>spring-boot-admin-starter-server</artifactId>
        <version>2.0.2</version>
    </dependency>

    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
</dependencies>
```

## 主类添加注解

```
@EnableAdminServer
@SpringBootApplication
public class AdminApplication {

	public static void main(String[] args) {
		SpringApplication.run(AdminApplication.class, args);
	}
}
```

## 配置

`application.yml`:

```
server:
  port: 6010
spring:
  application:
    name: admin
  profiles:
    active: dev
  security:
    user:
      name: ybd
      password: ybd
management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    health:
      show-details: ALWAYS
```

`application-dev.yml`:

```
eureka:
  client:
    service-url:
      defaultZone: http://ybd:ybd@127.0.0.1:8761/eureka/
  instance:
    metadata-map:
      user.name: ybd
      user.password: ybd
```

`SecuritySecureConfig`:

```
@Configuration
public class SecuritySecureConfig extends WebSecurityConfigurerAdapter {

	private final String adminContextPath;

	public SecuritySecureConfig(AdminServerProperties adminServerProperties) {
		this.adminContextPath = adminServerProperties.getContextPath();
	}

	@Override
	protected void configure(HttpSecurity http) throws Exception {
		SavedRequestAwareAuthenticationSuccessHandler successHandler = new SavedRequestAwareAuthenticationSuccessHandler();
		successHandler.setTargetUrlParameter("redirectTo");
		http.authorizeRequests()
//			.antMatchers("/actuator", "/actuator/health", "/actuator/info").permitAll()
			.antMatchers(adminContextPath + "/assets/**").permitAll()
			.antMatchers(adminContextPath + "/login").permitAll()
			.anyRequest().authenticated()
			.and()
			.formLogin().loginPage(adminContextPath + "/login").successHandler(successHandler).and()
			.logout().logoutUrl(adminContextPath + "/logout").and()
			.httpBasic()
			.and()
			.csrf().disable();
	}

}
```

# Finally

> 代码：***[https://github.com/masteranthoneyd/spring-cloud-learning](https://github.com/masteranthoneyd/spring-cloud-learning)***