# 快速搭建Spring Boot工程
# 前言
**理念“习惯优于配置”**
# 构建


# 项目结构
![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot/spring-boot-frame.png)
整个目录大概就这样子啦~
* `src/main/java`下的程序入口：`FastBootApplication`
* `src/main/resources`下的配置文件：`application.properties`
* `src/test`下的测试入口：`FastBootApplicationTests`

由于目前该项目未配合任何数据访问或Web模块，程序会在加载完Spring之后**结束运行**~

# 引入Web模块
引入Web模块，需添加`spring-boot-starter-web`模块：
```xml
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-web</artifactId>
</dependency>
```
如果是通过IDEA工具生成，可以在配置中直接勾选：
![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot/spring-boot-web.png)

# HelloWorld
在`com.yangbingdong`下创建一个`package`命名为`web`（可以随便）
然后创建`HelloWord`类：
```java
@RestController
public class HelloWorld {
	@GetMapping(value = "/hello")
	public String index() {
		return "Hello World";
	}
}
```
启动主程序，打开浏览器访问`http://localhost:8080/hello`，可以看到页面输出`Hello World`~
**注意：**这个`web`必须与`FastBootApplication`在**同一包下**，否则后面启动项目会扫描不到我们的`HelloWorld.java`...

# Junit Test Case
打开的`src/test/`下的测试入口`FastBootApplicationTests`类，编写一个简单的单元测试来模拟http请求：
```java
@RunWith(SpringRunner.class)
@SpringBootTest()
public class FastBootApplicationTests {

	private MockMvc mvc;

	@Before
	public void setUp() throws Exception {
		mvc = MockMvcBuilders.standaloneSetup(new HelloWorld()).build();
	}

	@Test
	public void getHello() throws Exception {
		mvc.perform(get("/hello").accept(APPLICATION_JSON))
		   .andExpect(status().isOk())
		   .andExpect(content().string(equalTo("Hello World")));
	}

}
```
**注意静态引用：**
```java
import static org.hamcrest.Matchers.equalTo;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
```

# 打包Jar运行
直接打开`Maven Project`，点击`jar`即可打包：
![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot/spring-boot-jar.png)

But!打包出来的`jar`包，在在终端执行`java -jar`时显示**没有主清单属性**...
![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot/spring-boot-jar-no-main.png)
解决方案：用package命令就能运行
![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot/spring-boot-package.png)

再次终端运行：
![](http://ojoba1c98.bkt.clouddn.com/img/spring-boot/spring-boot-package-run.png)

到此，我们已经成功搭建了一个简单的`Spring Boot`项目了~

# 属性配置文件
因为我们在`pom.xml`文件中引入了模块化的`Starter POMs`，其中各个模块都有自己的默认配置，所以如果不是特殊应用场景，就只需要在`application.properties`中完成一些属性配置就能开启各模块的应用，基于**理念“习惯优于配置”**，所以我们可以不需要配置什么就能跑气一个`HelloWold`。
`application.properties`除了配置数据库、redis等之外，还可以有其他的用途。
## 自定义属性
```properties
com.yangbingdong.blog=www.ookamiantd.top
```
然后通过`@Value("${属性名:默认值}")`注解来加载对应的配置属性，当然不给默认值也可以，给了默认值系统会在读取不到对应配置时拿默认值，不配置的话，当系统找不到配置时会抛异常...
```java
@Component("propertiesBean")
public class PropertiesBean {

	@Value("${com.yangbingdong.blog:defaultUrl}")
	private String blogUrl;

	public String getBlogUrl() {
		return blogUrl;
	}

	public void setBlogUrl(String blogUrl) {
		this.blogUrl = blogUrl;
	}
}
```

## 参数间的引用
在`application.properties`中的各个参数之间也可以直接引用来使用:
```properties
yangbingdong.log.level=info
logging.level.com.yangbingdong.FastBootApplicationTests=${yangbingdong.log.level}
```

## 使用随机数
在一些情况下，有些参数我们需要希望它不是一个固定的值，比如密钥、服务端口等。Spring Boot的属性配置文件中可以通过`${random}`来产生int值、long值或者string字符串，来支持属性的随机值。
```properties
# 随机字符串
com.yangbingdong.blog.value=${random.value}
# 随机int
com.yangbingdong.blog.number=${random.int}
# 随机long
com.yangbingdong.blog.bignumber=${random.long}
# 10以内的随机数
com.yangbingdong.blog.test1=${random.int(10)}
# 10-20的随机数
com.yangbingdong.blog.test2=${random.int[10,20]}
```

## 通过命令行设置属性值
我们在启动Spring Boot jar包时通常使用`java -jar xxx.jar --server.port=8888`，`–server.port`属性来设置`xxx.jar`应用的端口为`8888`。
在命令行运行时，连续的两个减号`--`就是对`application.properties`中的属性值进行赋值的标识。
`java -jar xxx.jar --server.port=8888`命令，等价于我们在`application.properties`中添加属性`server.port=8888`。
如果想屏蔽命令行访问属性的设置，只需要这句设置就能屏蔽：`SpringApplication.setAddCommandLineProperties(false)`。

## 多环境配置
在Spring Boot中多环境配置文件名需要满足`application-{profile}.properties`的格式，其中`{profile}`对应你的环境标识，比如：
* `application-dev.properties`：开发环境
* `application-test.properties`：测试环境
* `application-prod.properties`：生产环境

至于哪个具体的配置文件会被加载，需要在`application.properties`文件中通过`spring.profiles.active`属性来设置，其值对应`{profile}`值。
test：
在`application.properties`同级目录下创建`application-dev.properties`、`application-prod.properties`。
分别设置不同的`server.port`，如：`dev`环境设置为8080，`prod`环境设置为6666
`application.properties`中设置`spring.profiles.active=dev`，就是说默认以`dev`环境设置。
然后分别执行`java -jar xxx.jar`、`java -jar xxx.jar --spring.profiles.active=prod`，会发现他们的端口分别是8080和6666



