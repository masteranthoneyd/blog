# 手把手实现一个 Lite SpringBoot

> 从 SQL Boy, 到 CRUD Boy, 再到 Spring Boy, 当今的 Java 项目基本都离不开 Spring,  这也可以看出 Spring 在 Java 世界里举足轻重的作用.

# Spring 的前世今生

早在  2002  年, J2EE 与 EJB 大行其道 , 很多知名公司都是采用此技术方案进行项目开发. 那么 J2EE 是什么? 

J2EE 其实是一套标准规范, 里面有一堆技术的集合体, 包括 EJB, JDBC 等:
![]( https://cdn.yangbingdong.com/img/spring-autoconfig-evolution/ejb-collection.png )

然而 EJB 的实现是一个**非常笨重**的 Java 组件:

* 它将 JavaBean 集中式的管理并且通过 RMI 进行调用, 性能不高, 如果调用方与 EJB 服务不在一个局域网, 后果很可怕
* 它只能只能运行在 JBoss, WebLogic 等大型收费的服务器上

在这时候有一位小伙子认为并不是所有的项目都需要 EJB 这种重量级框架,  应该会有一种更好的方案来解决这个问题, 并且 在2001年10月写了一本书《Expert One-on-One J2EE Development without EJB》 , 指出了 J2EE 和 EJB 框架的主要缺陷,  提出了一个**基于普通  Java 类和依赖注入**的更简单的解决方案.

书中展示了如何在不使用 EJB 的情况下构建高质量, 可扩展的在线座位预留系统. 根据这些内容, 他编写了一个叫  **interface21** 的框架, 为了寓意 J2EE 漫长的冬天(winter)的结束, 后来改名叫 Spring.

Spring 在 2004 年 3 月 发布 1.0 版本, 而这位 Spring 的作者叫  Rod Johnson.

![](https://cdn.yangbingdong.com/img/spring-autoconfig-evolution/spring-author-rod-johnson.png)

> 从上面 J2EE 的图中可以看出来, Spring 并不是要代替 J2EE, 而是在 J2EE 只上的框架, 为 J2EE 一些组件提供轻量级的集成能力, 与 J2EE 相辅相成.
>
> 关于 Spring 的版本变迁可参考: ***[当音乐学博士搞起编程, 用一本书改变了Java世界！](https://blog.didispace.com/hero-spring-rod-johnson/)***

# Spring 是什么?

早期, Spring 是一个**轻量级**, 非入侵式(无需实现Spring的特定接口)的**控制反转** (IoC) 和面向切面 (AOP) 的框架. 发展到如今, Spring 已经是一个非常强大, 整合了众多能力的平台了.

![](https://cdn.yangbingdong.com/img/spring-autoconfig-evolution/spring-timer-shaft.png)

 ![](https://cdn.yangbingdong.com/img/spring-autoconfig-evolution/spring-overview.png)

Spring 特性:

![](https://cdn.yangbingdong.com/img/spring-autoconfig-evolution/spring-feature.png)

到了现在, 企业级开发的标配基本就是 **Spring5** + **Spring Boot 2** + **JDK 8** 

## IoC 和 DI 是什么

Java 是面向对象的编程语言, 一个个实例对象相互合作组成了业务逻辑, 原来, 我们都是**在代码里所需要的地方创建对象**和对象的依赖.

所谓的**IoC**(Inversion of Control, 控制反转): 就是由容器来负责控制对象的生命周期和对象间的关系. 以前是我们想要什么, 就自己创建什么, 现在是我们需要什么, 容器就给我们送来什么.

![](https://cdn.yangbingdong.com/img/spring-autoconfig-evolution/before-ioc-and-after.png)

也就是说, 控制对象生命周期的不再是引用它的对象, 而是容器. 对具体对象, 以前是它控制其它对象, 现在所有对象都被容器控制, 所以这就叫**控制反转**.

![](https://cdn.yangbingdong.com/img/spring-autoconfig-evolution/ioc.png)

 **DI**(Dependency Injection, 依赖注入)：指的是容器在实例化对象的时候把它依赖的类注入给它, IoC 思想的实现.

IoC 的有点显而易见,  最主要的是两个字**解耦**, 硬编码会造成对象间的过度耦合, 使用 IoC 之后, 我们可以**不用关心对象间的依赖**, 专心开发应用就行.

# 为什么会有 SpringBoot

有了 Spring, 可以很轻松通过 IoC/DI 管理项目中的 Bean, 那为什么还会有 SpringBoot呢? 

其实 SpringBoot 的出现是为了**简化** Spring 集成的项目(还有一些常用的第三方类库)的配置, 在原本的 Spring 集成的项目中(比如 spring-web, spring-data-jdbc 等), 无论是基于注解的配置还是基于 xml 的配置, 你都需要进行很多的配置才能正常使用.

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
2. 写Controller类, 在上面加上`Controller`和`@RequestMapping`注解
3. 创建一个类(或者直接在 Controller 类上面)写一个启动(main)方法, 比如

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

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

2. 配置 redis 服务器:

```yaml
spring:
  redis:
    host: 127.0.0.1
    port: 6379
    password: 123456
```

3. 代码中直接使用:

```java
@Autowired
private StringRedisTemplate strRedisTmp;

...

String someVal = strRedisTmp.get(someKey);
```

SpringBoot 倡导的理念: **约定** > **配置** > **编码**

# 什么是 SpringBoot 自动配置/Auto-Configuration

- 指的是基于你引入的 Jar 包(一般称之为 starter), 对 SpringBoot 应用进行自动配置
- 改特性为 Spring Boot 框架的**开箱即用**提供了基础支撑

> 与**自动装配**的区别:
>
> * 自动配置: Auto-Configuration
> * 自动装配: Autowire, 针对的是 Spring 中的依赖注入

# Spring 配置 Bean 的方式

Spring Bean 的 metadata 都存放在一个叫做  `BeanDefinition` 的类里面, 包括 beanName, beanClass,  autowireMode,  constructorArgumentValues 等等.

所谓的配置 bean, 其实是对  `BeanDefinition`  的定义, Spring 拿到 `BeanDefinition` 之后, 根据里面的信息进行 bean 的实例化以及后续的操作(比如  `BeanFactoryPostProcessor`,  `BeanPostProcessor`).

## 基于 xml 配置

在 Spring 刚发布的时候, 那时候还是使用 xml 配置 bean 的.

 创建 `beans.xml` 文件, 在里面加入： 

```xml
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

```java
public class TaxCalculatorTest {
    @Test
    public void test(){
        ApplicationContext ctx = new ClassPathXmlApplicationContext("beans.xml");
        TaxCalculator taxCalculator = ctx.getBean("taxCalculator", TaxCalculator.class);
        System.out.println(taxCalculator.calc(100));
    }
}
```

## 基于 JavaConfig 类配置

后来, 为了简化 xml 的配置, 出现了通过 JavaConfig 的方式进行配置.  想要成为 JavaConfig 类, 需要使用`@Configuration` 注解.

```java
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

```java
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

假设上面的 `TaxCalculator` 需要提供给其他项目组的开发同学使用,他们至少要写一个配置文件, 无论是什么形式, 都**至少需要一个文件**把它全部写下来, 就算这个文件的内容是固定的, 但是为了装配这个对象, 不得不写. 更何况启动一个 Spring Web 应用可能需要其他的必要组件, 比如 MyBatis, SpringMVC 等, 那么可能为了初始化项目需要准备一些模板:

* `application-context.xml`
* `mybatis-config.xml`
* `spring-dao.xml`
* `spring-mvc.xml`
* `web.xml`

 有了这些模板, 我们只需要点点点, 再改一改, 就能用了.  这样做确实很好. 可是对于越来越成型的项目体系. 我们每次都搞一些**重复动作**, 是会厌烦的, 而且面对这么多xml配置文件, 我太难了. 

于是, 有人产生了这种想法:  我一个配置文件都不想写, 程序还能照样跑, 我只关心有我需要的组件就可以了, 我只需要关注我的目标就可以了, **我想打开一个工程之后可以1秒进入开发状态, 而不是花3小时写完配置文件(2.5小时找bug)** 希望有个东西帮我把开始之前的准备工作全做了, 即那些**套路化(有规律)的配置**, 这样在我接完水之后回来就可以直接进行开发.

## JavaConfig 拓展: @Import

`@Import` 也是 Spring 框架的一个注解, 它的作用是**提供了一种显式地从其他地方加载配置类的方式**, 这样可以避免使用**性能较差**的组件扫描(`@ComponentScan`).

`@Import` 支持通过下面三种方式导入:

* 普通的Bean或配置类, 可以理解为一个加了 `@Component` 或 `@Configuration` 注解的类
* 实现了  `ImportBeanDefinitionRegistrar` 接口的类
* 实现了  `ImportSelector` 接口的类 

```Java
@Import(ConfigA.class)
@Import(AImportBeanDefinitionRegister.class)
@Import(AImportSelector.class)
@Configuration
public XxxConfiguraion {
    ...
}

public class ConfigA {
  @Bean
  pubic A a() {
    return new A();
  }
}

public class AImportBeanDefinitionRegister implements ImportBeanDefinitionRegistrar {
    @Override
    public void registerBeanDefinitions(AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry) {
        RootBeanDefinition aDef = new RootBeanDefinition(A.class);
        registry.registerBeanDefinition("a", aDef);
    }
}

public class AImportSelector implements ImportSelector {
    @Override
    public String[] selectImports(AnnotationMetadata importingClassMetadata) {
        return new String[]{"config.ConfigA"};
    }
}
```

#  MyEnableAutoConfig

有了 `@Import` 的基础之后, 我们可以利用这个特性来实现我们自己的自动配置了~

```java
@MySpringBootApplication
public class ApplicationLauncher {
    public static void main(String[] args) {
        MySpringApplicationRunner.run(ApplicationLauncher.class);
    }
}

public class MySpringApplicationRunner {
    public static ApplicationContext run(Class<?> mainClass) {
        return new AnnotationConfigApplicationContext(mainClass);
    }
}
```

`@MySpringBootApplication`:

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Configuration
@MyEnableConfiguration
@ComponentScan
public @interface MySpringBootApplication {
}
```

让我们继续进入 `MyEnableAutoConfiguration` 一探究竟:

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Import(MyImportSelector.class)   
public @interface MyEnableAutoConfiguration {
}
```

原来是使用了 `@Import`, 进入`MyImportSelector`:

```java
public class MyImportSelector implements ImportSelector {
    @Override
    public String[] selectImports(AnnotationMetadata importingClassMetadata) {
        return new String[]{"com.xxx.ExpressionEvaluatorConfiguration"};
    }
}

@Configuration
public class ExpressionEvaluatorConfiguration {
    @Bean
    public ExpressionEvaluator ExpressionEvaluator(){
        return new InfixExpressionEvaluator();
    }
}
```

emmm... 饶了一大圈, 还是加载了一个配置文件.

总结一下流程:

![](https://cdn.yangbingdong.com/img/spring-autoconfig-evolution/myautoconfig-flow.png)

但这里, 已经基本得到了自动配置的能力, 但还不是特别的方便, 如果加一个配置或修改一个配置, 需要改动源码, 我们需要遵循**开闭原则**. 

将其改造一下, 继续偷懒, 在不改配置类的情况下, 能够动态增加配置类, 那么有什么优雅的方式可以做到呢? 我们可以参考 **Java SPI 机制**(比如 JDBC Driver, Dubbo), 定义一个 properties 文件, 所有的配置类信息以字符串形式放在里面, 启动时读取里面的配置信息并进行加载.

升级版 `MyImportSelector` -> `MyImportSelectorPlus` 会是这样的:

```java
public class MyImportSelectorPlus implements ImportSelector {

    @Override
    public String[] selectImports(AnnotationMetadata importingClassMetadata) {
        Properties properties = MyConfigLoader.loadConfig("/META-INF/load-config.properties");
        String strings = (String) properties.get(MyEnableConfiguration.class.getName());
        return new String[]{strings};
    }
}

public final class MyConfigLoader {
    public static Properties loadConfig(String path) {
        Properties properties = new Properties();
        try (InputStream sin = MyConfigLoader.class.getResourceAsStream(path)) {
            properties.load(sin);
        } catch (IOException e) {
            e.printStackTrace();
        }
        return properties;
    }
}
```

 至此, 无论是添加或者删除组件, 无非是在配置文件中加上或者删除一行的问题了.

# SpringBoot 自动配置源码分析

## SpringBoot 运行简化流程

一切的入口都在 `SpringApplication.run(...);`

> 看了上面的轻量级实现, ``SpringApplication.run(...)` 为什么要传入一个 mainClass 应该心里有数了吧.

![](https://cdn.yangbingdong.com/img/spring-autoconfig-evolution/springboot-autoconfiguration-simple-flow.png)

其中 processConfigurationClasses 简化逻辑如下:

![](https://cdn.yangbingdong.com/img/spring-autoconfig-evolution/process-configuration-classes.png)

这是一个递归的过程:

![](https://cdn.yangbingdong.com/img/spring-autoconfig-evolution/recursively-import-configuration-classes.png)

## @SpringBootApplication

SpringBoot 应用还需要在启动类上贴上 `@SpringBootApplication` 这个注解:

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan(excludeFilters = { @Filter(type = FilterType.CUSTOM, classes = TypeExcludeFilter.class),
		@Filter(type = FilterType.CUSTOM, classes = AutoConfigurationExcludeFilter.class) })
public @interface SpringBootApplication {
    ...
}


@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Configuration
@Indexed
public @interface SpringBootConfiguration {
    ...
}

@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@AutoConfigurationPackage
@Import(AutoConfigurationImportSelector.class)
public @interface EnableAutoConfiguration {
    ...
}
```

![](https://cdn.yangbingdong.com/img/spring-autoconfig-evolution/springboot-application-annnotation.png)

SpringBoot 配置自动加载的原理其实就是上面的 MyEnableAutoConfig 是一样的, 通过 import 注解导入 `ImportSelector` 接口的实现, 而 SpringBoot 这里用的是 `AutoConfigurationImportSelector`:

```java
public class AutoConfigurationImportSelector implements DeferredImportSelector {
	protected AutoConfigurationEntry getAutoConfigurationEntry(AnnotationMetadata annotationMetadata) {
		...
		List<String> configurations = getCandidateConfigurations(annotationMetadata, attributes);
		...
		return new AutoConfigurationEntry(configurations, exclusions);
	}
    
	protected List<String> getCandidateConfigurations(AnnotationMetadata metadata, AnnotationAttributes attributes) {
		List<String> configurations = SpringFactoriesLoader.loadFactoryNames(EnableAutoConfiguration.class,
				getBeanClassLoader());
		...
		return configurations;
	}
		
}
```

这里面用到了 `SpringFactoriesLoader.loadFactoryNames`, 在 `SpringFactoriesLoader` 里面就定义了配置自动加载的目录文件:

```java
public final class SpringFactoriesLoader {

	/**
	 * The location to look for factories.
	 * <p>Can be present in multiple JAR files.
	 */
	public static final String FACTORIES_RESOURCE_LOCATION = "META-INF/spring.factories";
    
}
```

那么还剩下一个 `@AutoConfigurationPackage` 是做什么的, 网上有一些文章说是它的作用是包扫描, 这个是错误的, 它的作用其实在源码中已经告诉了我们:

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@Import(AutoConfigurationPackages.Registrar.class)
public @interface AutoConfigurationPackage {
  ...
}


/**
 * Class for storing auto-configuration packages for reference later (e.g. by JPA entity
 * scanner).
 *
 * @author Phillip Webb
 * @author Dave Syer
 * @author Oliver Gierke
 * @since 1.0.0
 */
public abstract class AutoConfigurationPackages {
    ...
}
```

> 