# Feign+OkHttp

1、添加依赖：

```
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>

<dependency>
    <groupId>io.github.openfeign</groupId>
    <artifactId>feign-okhttp</artifactId>
</dependency>
```

2、配置：

```
feign:
  httpclient:
    enabled: false
  okhttp:
    enabled: true
```

3、编写接口（参数命名什么的最好跟服务提供者一样，不然可能发生神秘错误）：

```
@FeignClient(value = "epms", path = "/epms/msg")
public interface EpmsFeignClient {
	@PostMapping("/list")
	Response<Void> postListMessage(@RequestBody List<Message> messageVos);
}
```

* `value`：提供服务的`spring.application.name`
* `path`：下面所有方法请求的前缀

4、启用扫描：

```
@SpringBootApplication
@EnableFeignClients
public class Application {

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}
}
```

5、注入服务并调用

```
@Resource
private EpmsFeignClient epmsFeignClient;

public void feignInvoke() {
    epmsFeignClient.postListMessage(.....)
}
```



# Hystrix

