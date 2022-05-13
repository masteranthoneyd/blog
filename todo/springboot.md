# SpringBoot 自动配置原理

# 什么是 SpringBoot 自动配置/Auto-Configuration

- 指的是基于你引入的 Jar 包(一般称之为 starter), 对 SpringBoot 应用进行自动配置
- 改特性为 Spring Boot 框架的**开箱即用**提供了基础支撑

与**自动装配**的区别:

* 自动配置: Auto-Configuration
* 自动装配: Autowire, 针对的是 Spring 中的依赖注入

# 为什么会有 SpringBoot

 SpringBoot 的出现是为了**简化** Spring 集成的项目(还有一些常用的第三方类库)的配置, 在原本的 Spring 集成的项目中(比如 spring-web, spring-data-jdbc 等), 无论是基于注解的配置还是基于 xml 的配置, 你都需要进行很多的配置才能正常使用.

比如 spring-web, 如果不使用 SpringBoot, 你需要:

1. 添加所需要的依赖, `spring-webmvc` 和 `javax.servlet-api` 共两个
2. 继承`AbstractAnnotationConfigDispatcherServletInitializer`类, 重写它的 `getRootConfigClasses`, `getServletConfigClasses` 和 `getServletMappings` 方法
3. 创建一个 `WebConfig` 类配置你需要的 Bean, 并在上面加上 `@Configuration`, `@EnableWebMvc`,
   还有 `@ComponentScan` 注解
4. 写 Controller 类, 上面加上 `@Controller` 和 `@RequestMapping` 注解
5. 把你的项目打包成 war（记得把依赖也打包到lib目录）, 配置 Servlet 容器(比如 Tomcat), 启动 Servlet 容器, 部署 war 到Servlet 容器
6. 如果你需要配置一些 SpringMVC 的东西, 比如视图解析器 , 消息转换器等, 你需要新建一个类实现 `WebMvcConfigurer` 接口, 然后根据重写接口里面的方法, 然后在类上面加上 `@Configuration` 和`@EnableWebMvc` 注解
7. 如果你需要改变 Servlet 容器的服务端口, **只能去改变外部**的 Servlet 容器的配置, 无法在项目的代码或者配置文件里面实现

而用 SpringBoot, 你只需要:

1. 添加所需要的依赖, spring-boot-starter-web, 就这一个就行
2.  写Controller类, 在上面加上`Controller`和`@RequestMapping`注解
3.  创建一个类(或者直接在 Controller 类上面)写一个启动(main)方法, 比如

```java
@SpringBootApplication
public class AppLauncher {
    public static void main(String[] args) {
        SpringApplication.run(AppLauncher.class, args);
    }
}
```

又如 spring-data-redis:

1. 引入依赖:

```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

2. 配置 redis 服务器:

```
spring:
  redis:
    host: 127.0.0.1
    port: 6379
    password: 123456
```

3. 代码中直接使用:

```
@Autowired
private StringRedisTemplate strRedisTmp;

...

String someVal = strRedisTmp.get(someKey);
```

SpringBoot 倡导的理念: **约定** > **配置** > **编码**

# 了解 SpringBoot 自动配置原理的好处

* 理解 SpringBoot 各种 starter 是如何**自动**被 Spring 加载的
  * 一般 starter 都是一个固定的套路/规范, 当自动配置失败时可以快速定位到问题.
  * 很容易对 starter 对一些拓展
* 吸收好的设计模式或者方法论
* 窥探大佬的优美代码
*  了解框架的拓展机制, 在框架基础上, 能进行自己的拓展, 实现自己的特殊的需求 

# Spring 配置 Bean 的方式

Spring Bean 的 metadata 都存放在一个叫做  `BeanDefinition` 的类里面, 包括 beanName, beanClass,  autowireMode,  constructorArgumentValues 等等.

所谓的配置 bean, 其实是对  `BeanDefinition`  的定义, Spring 拿到 `BeanDefinition` 之后, 根据里面的信息进行 bean 的实例化以及后续的操作(比如  `BeanFactoryPostProcessor`,  `BeanPostProcessor`).

## 基于 xml 配置

在 Spring 刚发布的时候, 那时候还是使用 xml 配置 bean 的.

 创建 `application-context.xml` 文件, 在里面加入： 

```
<!-- 通过属性注入 -->
<bean id="taxCalculator" class="util.TaxCalculator">
    <property name="rate" value="0.1"/>
</bean>

<!-- 通过构造器注入 -->
<bean id="taxCalculator" class="util.TaxCalculator">
    <constructor-arg index="0" type="java.lang.Float" value="0.1" />
</bean>
```

测试:

```
public class TaxCalculatorTest {
    @Test
    public void test(){
        ApplicationContext ctx = new ClassPathXmlApplicationContext("application-context.xml");
        TaxCalculator taxCalculator = ctx.getBean("taxCalculator", TaxCalculator.class);
        System.out.println(taxCalculator.calc(100));
    }
}
```

## 基于 JavaConfig 类配置

后来, 为了简化 xml 的配置, 出现了通过 JavaConfig 的方式进行配置.  想要成为 JavaConfig 类, 需要使用`@Configuration` 注解.

```
@Configuration
@ComponentScan
public class TaxCalculatorConfiguration {

    @Bean
    public TaxCalculator taxCalculator(){
        return new TaxCalculator(0.1);
    }
}
```

测试:

```
public class TaxCalculatorTest {
    @Test
    public void test(){
        ApplicationContext ctx = new AnnotationConfigApplicationContext(TaxCalculatorConfiguration.class);
        TaxCalculator taxCalculator = ctx.getBean("taxCalculator", TaxCalculator.class);
        System.out.println(taxCalculator.calc(100));
    }
}
```

## 三方组件的引入配置

假设上面的 `TaxCalculator` 需要提供给其他项目组的开发同学使用,他们至少要写一个配置文件, 无论是什么形式, 都**至少需要一个文件**把它全部写下来, 就算这个文件的内容是固定的, 但是为了装配这个对象, 不得不写. 更何况启动一个 Spring Web 应用可能需要其他的必要组件, 比如 MyBatis, SpringMvc 等, 那么可能为了初始化项目需要准备一些模板:

* `application-context.xml`
* `mybatis-config.xml`
* `spring-dao.xml`
* `spring-mvc.xml`
* `web.xml`

 有了这些模板, 我们只需要点点点, 再改一改, 就能用了.  这样做确实很好. 可是对于越来越成型的项目体系. 我们每次都搞一些重复动作, 是会厌烦的, 而且面对这么多xml配置文件, 我太难了. 

于是, 有人产生了这种想法:  我一个配置文件都不想写, 程序还能照样跑, 我只关心有我需要的组件就可以了, 我只需要关注我的目标就可以了, **我想打开一个工程之后可以1秒进入开发状态, 而不是花3小时写完配置文件(2.5小时找bug)** 希望有个东西帮我把开始之前的准备工作全做了, 即那些套路化的配置, 这样在我接完水之后回来就可以直接进行开发。.







# 进阶: AutoConfigurationImportSelector 是如何被加载的





