# Spring Boot 拾遗

# Servlet加载

## Spring时代

### servlet3.0 以前

继承`HttpServlet`：

```java
public class HelloWorldServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        ...
    }

}
```

实现`Filter`

```java
public class HelloWorldFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {

    }

    @Override
    public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain) throws IOException, ServletException {
        System.out.println("触发 hello world 过滤器...");
        filterChain.doFilter(servletRequest,servletResponse);
    }

    @Override
    public void destroy() {

    }
}
```

再配置到`web.xml`中：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://java.sun.com/xml/ns/javaee"
           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
           xsi:schemaLocation="http://java.sun.com/xml/ns/javaee
        http://java.sun.com/xml/ns/javaee/web-app_4_0.xsd"
           version="4.0">

    <servlet>
        <servlet-name>HelloWorldServlet</servlet-name>
        <servlet-class>....HelloWorldServlet</servlet-class>
    </servlet>

    <servlet-mapping>
        <servlet-name>HelloWorldServlet</servlet-name>
        <url-pattern>/hello</url-pattern>
    </servlet-mapping>

    <filter>
        <filter-name>HelloWorldFilter</filter-name>
        <filter-class>....HelloWorldFilter</filter-class>
    </filter>
    <filter-mapping>
        <filter-name>HelloWorldFilter</filter-name>
        <url-pattern>/hello</url-pattern>
    </filter-mapping>

</web-app>
```

这样就完成了一个Hello World。

### servlet3.0 时代

servlet3.0最大的一个特征就是可以在运行时动态注册 `servlet` ，`filter`，`listener`。以 servlet 为例，过滤器与监听器与之类似。`ServletContext` 为动态配置 Servlet 增加了如下方法：

- `ServletRegistration.Dynamic addServlet(String servletName,Class<? extends Servlet> servletClass)`
- `ServletRegistration.Dynamic addServlet(String servletName, Servlet servlet)`
- `ServletRegistration.Dynamic addServlet(String servletName, String className)`
- `T createServlet(Class clazz)`
- `ServletRegistration getServletRegistration(String servletName)`
- `Map<String,? extends ServletRegistration> getServletRegistrations()`

其中前三个方法的作用是相同的，只是参数类型不同而已；通过 `createServlet()` 方法创建的 Servlet，通常需要做一些自定义的配置，然后使用 `addServlet()` 方法来将其动态注册为一个可以用于服务的 Servlet。两个 `getServletRegistration()` 方法主要用于动态为 Servlet 增加映射信息，这等价于在 `web.xml` 中使用 标签为存在的 Servlet 增加映射信息。

以上 `ServletContext` 新增的方法要么是在 `ServletContextListener` 的 `contexInitialized` 方法中调用，要么是在 `ServletContainerInitializer` 的 `onStartup()` 方法中调用。

`ServletContainerInitializer` 也是 Servlet 3.0 新增的一个接口，容器在启动时使用 JAR 服务 API(JAR Service API) 来发现 `ServletContainerInitializer` 的实现类，并且容器将 WEB-INF/lib 目录下 JAR 包中的类都交给该类的 `onStartup()` 方法处理，我们通常需要在该实现类上使用 `@HandlesTypes` 注解来指定希望被处理的类，过滤掉不希望给 `onStartup()` 处理的类。

示例：

```java
public class CustomServletContainerInitializer implements ServletContainerInitializer {

  private final static String JAR_HELLO_URL = "/hello";

  @Override
  public void onStartup(Set<Class<?>> c, ServletContext servletContext) {

    ServletRegistration.Dynamic servlet = servletContext.addServlet(
            HelloWorldServlet.class.getSimpleName(),
            HelloWorldServlet.class);
    servlet.addMapping(JAR_HELLO_URL);

    FilterRegistration.Dynamic filter = servletContext.addFilter(
            HelloWorldFilter.class.getSimpleName(), HelloWorldFilter.class);

    EnumSet<DispatcherType> dispatcherTypes = EnumSet.allOf(DispatcherType.class);
    dispatcherTypes.add(DispatcherType.REQUEST); 
    dispatcherTypes.add(DispatcherType.FORWARD); 

    filter.addMappingForUrlPatterns(dispatcherTypes, true, JAR_HELLO_URL);

  }
}
```

这么声明一个 ServletContainerInitializer 的实现类，web 容器并不会识别它，所以，需要借助 SPI 机制来指定该初始化类，这一步骤是通过在项目路径下创建`META-INF/services/javax.servlet.ServletContainerInitializer`，它只包含一行内容：

```
com.example.CustomServletContainerInitializer
```

使用 `ServletContainerInitializer` 和 **SPI** 机制，我们的 web 应用便可以彻底摆脱 `web.xml` 了。

### Spring 支持

Spring 是也是通过 SPI 机制去加载 Servlet 的，寻找 `ServletContainerInitializer` 的实现类会发现有一个 `SpringServletContainerInitializer` 的类，查看使用处就会发现 SPI 支持：

![](https://cdn.yangbingdong.com/img/spring-boot-loading/spring-servlet-spi.png)

`SpringServletContainerInitializer` 中委托 `WebApplicationInitializer` 这个类初始化 web 环境，看一下实现类：

![](https://cdn.yangbingdong.com/img/spring-boot-loading/web-application-initializer-implement.png)

`AbstractDispatcherServletInitializer#registerDispatcherServlet` 便是无 `web.xml` 前提下创建 `dispatcherServlet` 的关键代码。

## Spring Boot

Spring Boot 并没有遵循 Servlet 3.0 规范，而是自己走了另外一条路线。

先来看一下 Spring Boot 中如何注册 Servlet.

### 添加Servlet

**方式一**：servlet3.0注解+`@ServletComponentScan`。springboot 依旧兼容 servlet3.0 一系列以 @Web* 开头的注解：`@WebServlet`，`@WebFilter`，`@WebListener`

```java
@WebServlet("/hello")
public class HelloWorldServlet extends HttpServlet{}
```

```java
@WebFilter("/hello/*")
public class HelloWorldFilter implements Filter {}
```

扫描：

```java
@SpringBootApplication
@ServletComponentScan
public class SpringBootServletApplication {

   public static void main(String[] args) {
      SpringApplication.run(SpringBootServletApplication.class, args);
   }
}
```

注册方式二：`RegistrationBean`。

```java
@Bean
public ServletRegistrationBean helloWorldServlet() {
    ServletRegistrationBean helloWorldServlet = new ServletRegistrationBean();
    myServlet.addUrlMappings("/hello");
    myServlet.setServlet(new HelloWorldServlet());
    return helloWorldServlet;
}

@Bean
public FilterRegistrationBean helloWorldFilter() {
    FilterRegistrationBean helloWorldFilter = new FilterRegistrationBean();
    myFilter.addUrlPatterns("/hello/*");
    myFilter.setFilter(new HelloWorldFilter());
    return helloWorldFilter;
}
```

`RegistrationBean` 是 Spring Boot 中广泛应用的一个注册类，负责把 `servlet`，`filter`，`listener` 给容器化，使他们被 Spring 托管，并且完成自身对 Web 容器的注册。这种注册方式也值得推崇。

![](https://cdn.yangbingdong.com/img/spring-boot-loading/registration-bean-implement.png)

它的几个实现类作用分别是：帮助容器注册 filter，servlet，listener，最后的 `DelegatingFilterProxyRegistrationBean` 使用的不多，但熟悉 SpringSecurity 的朋友不会感到陌生，`SpringSecurityFilterChain` 就是通过这个代理类来调用的。

### 加载流程

Spring Boot 由于使用了内嵌容器，可通过JAR包方式直接使用`java -jar`方式运行，也可打包成WAR包交给外部容器运行。由于JAR包的运行策略导致了程序不会照 servlet3.0 的策略去加载 `ServletContainerInitializer`。最后作者还提供了一个替代选项：`ServletContextInitializer`，它和 `ServletContextInitializer` **长得很像**，**但不是同一个东西**。

`ServletContextInitializer` 是 `org.springframework.boot.web.servlet.ServletContextInitializer`，后者 `ServletContainerInitializer` 是 `javax.servlet.ServletContainerInitializer`，上面提到 `RegistrationBean` 实现了 `ServletContextInitializer` 接口，最终通过 `TomcatStarter` 加载到Web容器。

![](https://cdn.yangbingdong.com/img/spring-boot-loading/tomcat-starter.png)

但上面并没有 `RegistrationBean`，只有这三个类，其中两个匿名的，`ServletWebServerApplicationContext`  这个类看起来比较核心，但不是这个类，是这个类的内部类。

实际上入口是在 `ServletWebServerApplicationContext#onRefresh()`方法中，onRefresh 是 ApplicationContext 的生命周期方法，`ServletWebServerApplicationContext` 的实现非常简单，只干了一件事： 

```java
@Override
protected void onRefresh() {
    super.onRefresh();
    try {
        createWebServer(); // 创建web容器
    }
    catch (Throwable ex) {
        throw new ApplicationContextException("Unable to start web server", ex);
    }
}
```

接着往下 `createWebServer()`：

```java
private void createWebServer() {
    WebServer webServer = this.webServer;
    ServletContext servletContext = getServletContext();
    if (webServer == null && servletContext == null) {
        ServletWebServerFactory factory = getWebServerFactory();
        this.webServer = factory.getWebServer(getSelfInitializer()); // 在这里获取
    }
    else if (servletContext != null) {
        try {
            getSelfInitializer().onStartup(servletContext);
        }
        catch (ServletException ex) {
            throw new ApplicationContextException("Cannot initialize servlet context",
                ex);
        }
    }
    initPropertySources();
}  
```

再往下 `getSelfInitializer()`：

```java
private org.springframework.boot.web.servlet.ServletContextInitializer getSelfInitializer() {
    return this::selfInitialize;
}

private void selfInitialize(ServletContext servletContext) throws ServletException {
    prepareWebApplicationContext(servletContext);
    registerApplicationScope(servletContext);
    WebApplicationContextUtils.registerEnvironmentBeans(getBeanFactory(),
        servletContext);
    for (ServletContextInitializer beans : getServletContextInitializerBeans()) { // 注意这里
        beans.onStartup(servletContext);
    }
}
```

`getServletContextInitializerBeans()`：

```java
/**
 * Returns {@link ServletContextInitializer}s that should be used with the embedded
 * web server. By default this method will first attempt to find
 * {@link ServletContextInitializer}, {@link Servlet}, {@link Filter} and certain
 * {@link EventListener} beans.
 * @return the servlet initializer beans
 */
protected Collection<ServletContextInitializer> getServletContextInitializerBeans() {
    return new ServletContextInitializerBeans(getBeanFactory());
}
```

注解告诉我们了，这是用来加载 Servlet、Filter 这些的。

`ServletContextInitializerBeans()`：

```java
	public ServletContextInitializerBeans(ListableBeanFactory beanFactory) {
		this.initializers = new LinkedMultiValueMap<>();
		addServletContextInitializerBeans(beanFactory); // 这里添加
		addAdaptableBeans(beanFactory);
		List<ServletContextInitializer> sortedInitializers = this.initializers.values()
				.stream()
				.flatMap((value) -> value.stream()
						.sorted(AnnotationAwareOrderComparator.INSTANCE))
				.collect(Collectors.toList());
		this.sortedList = Collections.unmodifiableList(sortedInitializers);
	}
```

`addServletContextInitializerBeans()`：

```java
private void addServletContextInitializerBeans(ListableBeanFactory beanFactory) {
    for (Map.Entry<String, ServletContextInitializer> initializerBean : getOrderedBeansOfType(
        beanFactory, ServletContextInitializer.class)) {
        addServletContextInitializerBean(initializerBean.getKey(), // 最后在这里
            initializerBean.getValue(), beanFactory);
    }
}
```

`addServletContextInitializerBean()`：

```java
private void addServletContextInitializerBean(String beanName,
                                              ServletContextInitializer initializer, ListableBeanFactory beanFactory) {
    if (initializer instanceof ServletRegistrationBean) {
        Servlet source = ((ServletRegistrationBean<?>) initializer).getServlet();
        addServletContextInitializerBean(Servlet.class, beanName, initializer,
            beanFactory, source);
    }
    else if (initializer instanceof FilterRegistrationBean) {
        Filter source = ((FilterRegistrationBean<?>) initializer).getFilter();
        addServletContextInitializerBean(Filter.class, beanName, initializer,
            beanFactory, source);
    }
    else if (initializer instanceof DelegatingFilterProxyRegistrationBean) {
        String source = ((DelegatingFilterProxyRegistrationBean) initializer)
            .getTargetBeanName();
        addServletContextInitializerBean(Filter.class, beanName, initializer,
            beanFactory, source);
    }
    else if (initializer instanceof ServletListenerRegistrationBean) {
        EventListener source = ((ServletListenerRegistrationBean<?>) initializer)
            .getListener();
        addServletContextInitializerBean(EventListener.class, beanName, initializer,
            beanFactory, source);
    }
    else {
        addServletContextInitializerBean(ServletContextInitializer.class, beanName,
            initializer, beanFactory, initializer);
    }
}
```

最终这些 `ServletContextInitializer` 在 `TomcatServletWebServerFactory#configureContext` 方法当中交给了 `TomcatStarter` ：

```java
protected void configureContext(Context context,
                                ServletContextInitializer[] initializers) {
    TomcatStarter starter = new TomcatStarter(initializers);
    if (context instanceof TomcatEmbeddedContext) {
        // Should be true
        ((TomcatEmbeddedContext) context).setStarter(starter);
    }
    context.addServletContainerInitializer(starter, NO_CLASSES);
    for (LifecycleListener lifecycleListener : this.contextLifecycleListeners) {
        context.addLifecycleListener(lifecycleListener);
    }
    for (Valve valve : this.contextValves) {
        context.getPipeline().addValve(valve);
    }
    for (ErrorPage errorPage : getErrorPages()) {
        new TomcatErrorPage(errorPage).addToContext(context);
    }
    for (MimeMappings.Mapping mapping : getMimeMappings()) {
        context.addMimeMapping(mapping.getExtension(), mapping.getMimeType());
    }
    configureSession(context);
    for (TomcatContextCustomizer customizer : this.tomcatContextCustomizers) {
        customizer.customize(context);
    }
}
```

`TomcatStarter` 再交给真正的Tomcat容器调用 `onStartup` 方法，最终完成装配！

那么 `TomcatServletWebServerFactory` 又是什么时候被加载的呢？

答案在 `ServletWebServerFactoryAutoConfiguration` ：

```java
@Configuration
@AutoConfigureOrder(Ordered.HIGHEST_PRECEDENCE)
@ConditionalOnClass(ServletRequest.class)
@ConditionalOnWebApplication(type = Type.SERVLET)
@EnableConfigurationProperties(ServerProperties.class)
@Import({ ServletWebServerFactoryAutoConfiguration.BeanPostProcessorsRegistrar.class,
		ServletWebServerFactoryConfiguration.EmbeddedTomcat.class,
		ServletWebServerFactoryConfiguration.EmbeddedJetty.class,
		ServletWebServerFactoryConfiguration.EmbeddedUndertow.class })
public class ServletWebServerFactoryAutoConfiguration {

	@Bean
	public ServletWebServerFactoryCustomizer servletWebServerFactoryCustomizer(
			ServerProperties serverProperties) {
		return new ServletWebServerFactoryCustomizer(serverProperties);
	}
    .....
}
```

`ServletWebServerFactoryConfiguration`：

```java
@Configuration
class ServletWebServerFactoryConfiguration {

	@Configuration
	@ConditionalOnClass({ Servlet.class, Tomcat.class, UpgradeProtocol.class })
	@ConditionalOnMissingBean(value = ServletWebServerFactory.class, search = SearchStrategy.CURRENT)
	public static class EmbeddedTomcat {

		@Bean
		public TomcatServletWebServerFactory tomcatServletWebServerFactory() {
			return new TomcatServletWebServerFactory();
		}

	}

	/**
	 * Nested configuration if Jetty is being used.
	 */
	@Configuration
	@ConditionalOnClass({ Servlet.class, Server.class, Loader.class,
			WebAppContext.class })
	@ConditionalOnMissingBean(value = ServletWebServerFactory.class, search = SearchStrategy.CURRENT)
	public static class EmbeddedJetty {

		@Bean
		public JettyServletWebServerFactory JettyServletWebServerFactory() {
			return new JettyServletWebServerFactory();
		}

	}

	/**
	 * Nested configuration if Undertow is being used.
	 */
	@Configuration
	@ConditionalOnClass({ Servlet.class, Undertow.class, SslClientAuthMode.class })
	@ConditionalOnMissingBean(value = ServletWebServerFactory.class, search = SearchStrategy.CURRENT)
	public static class EmbeddedUndertow {

		@Bean
		public UndertowServletWebServerFactory undertowServletWebServerFactory() {
			return new UndertowServletWebServerFactory();
		}

	}

}
```

