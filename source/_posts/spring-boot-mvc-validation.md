---
title: Spring Boot学习之MVC与Validation
date: 2018-02-26 16:30:58
categories: [Programming, Java, Spring Boot]
tags: [Java, Spring Boot, Spring]
---

![](https://cdn.yangbingdong.com/img/spring-boot-learning/spring-boot.png)

# Preface

> 此篇大部分是对Spring MVC的一个回顾以及JSR303中bean validation规范的学习

<!--more-->

# Spring MVC 相关

## Spring MVC 流程

![](https://cdn.yangbingdong.com/img/spring-boot-learning/spring-mvc-process-new.png)

![](https://cdn.yangbingdong.com/img/spring-boot-learning/spring-mvc-convert-processing.png)

1、  用户发送请求至前端控制器`DispatcherServlet`. 

2、  `DispatcherServlet`收到请求调用`HandlerMapping`处理器映射器. 

3、  处理器映射器找到具体的处理器(可以根据xml配置、注解进行查找), 生成处理器对象及处理器拦截器(如果有则生成)一并返回给`DispatcherServlet`. 

4、  `DispatcherServlet`调用`HandlerAdapter`处理器适配器. 

5、  `HandlerAdapter`经过适配调用具体的处理器(`Controller`, 也叫后端控制器). 

6、  `Controller`执行完成返回`ModelAndView`. 

7、  `HandlerAdapter`将`controller`执行结果`ModelAndView`返回给`DispatcherServlet`. 

8、  `DispatcherServlet`将`ModelAndView`传给`ViewReslover`视图解析器. 

9、  `ViewReslover`解析后返回具体`View`. 

10、`DispatcherServlet`根据`View`进行渲染视图（即将模型数据填充至视图中）. 

11、 `DispatcherServlet`响应用户. 

> 更多源码解析请参考: ***[【深入浅出spring】Spring MVC 流程解析](https://segmentfault.com/a/1190000013816079)***

## Spring MVC集成FastJson

![](https://cdn.yangbingdong.com/img/spring-boot-learning/web-mvc-configurer.png)

> ***[https://github.com/alibaba/fastjson/wiki/%E5%9C%A8-Spring-%E4%B8%AD%E9%9B%86%E6%88%90-Fastjson](https://github.com/alibaba/fastjson/wiki/%E5%9C%A8-Spring-%E4%B8%AD%E9%9B%86%E6%88%90-Fastjson)***

```
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>fastjson</artifactId>
    <version>1.2.54</version>
</dependency>
```

```java
@Configuration
public class WebMvcMessageConvertConfig implements WebMvcConfigurer {

	@Autowired
	StringHttpMessageConverter stringHttpMessageConverter;

	@Override
	public void configureMessageConverters(List<HttpMessageConverter<?>> converters) {
		FastJsonHttpMessageConverter fastConverter = new FastJsonHttpMessageConverter();

		SerializeConfig serializeConfig = SerializeConfig.globalInstance;
		serializeConfig.put(BigInteger.class, ToStringSerializer.instance);
		serializeConfig.put(Long.class, ToStringSerializer.instance);
		serializeConfig.put(Long.TYPE, ToStringSerializer.instance);

		FastJsonConfig fastJsonConfig = new FastJsonConfig();
		fastJsonConfig.setCharset(StandardCharsets.UTF_8);
		fastJsonConfig.setSerializeConfig(serializeConfig);
//		fastJsonConfig.setSerializerFeatures(SerializerFeature.PrettyFormat);
		fastJsonConfig.setDateFormat(Constant.DATE_FORMAT);

		fastConverter.setFastJsonConfig(fastJsonConfig);
		fastConverter.setSupportedMediaTypes(Collections.singletonList(MediaType.APPLICATION_JSON_UTF8));
		converters.add(0, stringHttpMessageConverter);
		converters.add(1, fastConverter);
	}
}
```

**注意**:

* SpringBoot 2.0.1版本中加载`WebMvcConfigurer`的顺序发生了变动, 故需使用`converters.add(0, converter);`指定`FastJsonHttpMessageConverter`在converters内的顺序, 否则在SpringBoot 2.0.1及之后的版本中将优先使用Jackson处理。详情：***[WebMvcConfigurer is overridden by WebMvcAutoConfiguration #12389](https://github.com/spring-projects/spring-boot/issues/12389)***
* 在`FastJsonHttpMessageConverter`之前插入一个`StringHttpMessageConverter`是为了在Controller层返回String类型不会再次被FastJson序列化.

### FastJson枚举映射

实现 `ObjectSerializer,` 以及 `ObjectDeserializer`:

```java
public class EnumCodec implements ObjectSerializer, ObjectDeserializer {

    private static ConcurrentHashMap<Class<?>, Method> methodCache = new ConcurrentHashMap<>(16);

    @SuppressWarnings("unchecked")
    @Override
    public <T> T deserialze(DefaultJSONParser parser, Type type, Object fieldName) {
        Object value = parser.parse();
        Class enumClass = (Class) type;
        Method getValueMethod = getMethod(enumClass);
        Enum enumeration = EnumUtils.valueOf(enumClass, value, getValueMethod);
        return (T) enumeration;
    }

    @Override
    public int getFastMatchToken() {
        return JSONToken.LITERAL_INT;
    }

    @Override
    public void write(JSONSerializer serializer, Object object, Object fieldName, Type fieldType, int features) {
        SerializeWriter out = serializer.getWriter();
        if (object == null) {
            serializer.getWriter().writeNull();
            return;
        }
        IEnum enumeration = (IEnum) object;
        out.write(enumeration.getValue().toString());
    }

    private static Method getMethod(Class<?> clazz) {
        Method method = methodCache.get(clazz);
        if (method != null) {
            return method;
        }
        try {
            method = clazz.getDeclaredMethod("getValue");
            methodCache.put(clazz, method);
            return method;
        } catch (NoSuchMethodException e) {
            throw new RuntimeException(e);
        }
    }
}
```

#### 方式一: 字段上加注解

在枚举字段上添加注解:

```java
@JSONField(serializeUsing = EnumCodec.class, deserializeUsing = EnumCodec.class)
private AgeEnum age;
```

#### 方式二: 类上加注解

```java
@JSONType(serializeEnumAsJavaBean = true, serializer = EnumCodec.class, deserializer = EnumCodec.class)
public enum AgeEnum implements EnumValueProvider {
  ONE(1, "一岁"),
  TWO(2, "二岁"),
  THREE(3, "三岁");

  private int value;
  private String desc;

  AgeEnum(final int value, final String desc) {
    this.value = value;
    this.desc = desc;
  }

  @Override
  public Integer getValue() {
    return value;
  }
}
```

### WebFlux

上面针对的是Web MVC, **对于Webflux目前不支持这种方式**.

## Spring Boot JSON （Date类型入参、格式化, 以及如何处理null）

```yaml
spring:
  jackson:
    default-property-inclusion: non_null # 忽略 json 中值为null的属性
    date-format: "yyyy-MM-dd HH:mm:ss" # 设置 pattern
    time-zone: GMT+8 # 修正时区
```

* 时间格式可以在实体上使用该注解: `@JsonFormat(timezone = "GMT+8",pattern = "yyyy-MM-dd")`
* 忽略null属性可以在实体上使用: `@JsonInclude(JsonInclude.Include.NON_NULL)`

## Spring Boot MVC特性

Spring boot 在spring默认基础上, 自动配置添加了以下特性

- 包含了`ContentNegotiatingViewResolver`和`BeanNameViewResolver` beans. 
- 对静态资源的支持, 包括对WebJars的支持. 
- 自动注册`Converter`, `GenericConverter`, `Formatter` beans. 
- 对`HttpMessageConverters`的支持. 
- 自动注册`MessageCodeResolver`. 
- 对静态`index.html`的支持. 
- 对自定义`Favicon`的支持. 
- 主动使用`ConfigurableWebBindingInitializer` bean

## @RequestBody与@ModelAttribute

`@RequestBody`: 用于接收http请求中body的字符串信息, 可在直接接收转换到Pojo. 

`@ModelAttribute`: 用于直接接受`url?`后面的参数 如`url?id=123&name=456`, 可在直接接收转换到Pojo. 

## 模板引擎的选择

- `FreeMarker`
- `Thymeleaf`
- `Velocity` (1.4版本之后弃用, Spring Framework 4.3版本之后弃用)
- `Groovy`
- `Mustache`

注: **jsp应该尽量避免使用**, 原因如下: 

- jsp只能打包为: war格式, **不支持jar格式**, 只能在标准的容器里面跑（tomcat, jetty都可以）
- 内嵌的Jetty目前不支持JSP
- Undertow不支持jsp
- jsp自定义错误页面不能覆盖spring boot 默认的错误页面

## 开启GZIP算法压缩响应流

```yaml
server:
  compression:
    enabled: true # 启用压缩
    min-response-size: 2048 # 对应Content-Length, 超过这个值才会压缩
```

## 全局异常处理

在Spring Boot 2.X 中, 对于MVC抛出的异常, 默认会映射到 `/error`:  

![](https://cdn.yangbingdong.com/img/spring-boot-learning/spring-boot-mvc-error.png)

> 参考: ***[https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#boot-features-error-handling](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#boot-features-error-handling)***

由于默认情况下, Spring MVC 将报错转发到 `/error` 接口, 所以对应的Spring中也会有默认的异常处理类 `BasicErrorController`:

![](https://cdn.yangbingdong.com/img/spring-boot-learning/spring-boot-mvc-defalue-error01.png)

![](https://cdn.yangbingdong.com/img/spring-boot-learning/spring-boot-mvc-defalue-error02.png)

### 添加自定义的错误页面

- `html`静态页面: 在`resources/public/error/` 下定义. 如添加404页面: `resources/public/error/404.html`页面, 中文注意页面编码
- 模板引擎页面: 在`templates/error/`下定义. 如添加5xx页面: `templates/error/5xx.ftl`

> 注: `templates/error/` 这个的优先级比较`resources/public/error/`高

### 通过@ControllerAdvice

```java
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

	@SuppressWarnings("ConstantConditions")
	@ExceptionHandler(value = {
			MethodArgumentNotValidException.class,
			BindException.class,
			ConstraintViolationException.class})
	@ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
	public Response<Void> validExceptionHandler(Exception ex) {
		String validateFailReason;
		if (ex instanceof MethodArgumentNotValidException) {
			validateFailReason = ((MethodArgumentNotValidException) ex).getBindingResult()
																	   .getFieldError()
																	   .getDefaultMessage();
		} else if (ex instanceof BindException) {
			validateFailReason = ((BindException) ex).getFieldError().getDefaultMessage();
		} else if (ex instanceof ConstraintViolationException) {
			validateFailReason = ((ConstraintViolationException) ex).getConstraintViolations().stream()
																	.findAny()
																	.map(ConstraintViolation::getMessage)
																	.orElse("Unknown error message");
		} else {
			validateFailReason = "Unknown error message";
		}
		return Response.error(validateFailReason);
	}

	@ExceptionHandler(value = BusiException.class)
	@ResponseStatus(INTERNAL_SERVER_ERROR)
	public Response<Void> busiExceptionHandler(BusiException ex) {
		log.error("业务异常捕获: " + ex.getMessage());
		return Response.error(ex);
	}

	@ExceptionHandler(value = NoHandlerFoundException.class)
	@ResponseStatus(NOT_FOUND)
	public Response<Void> notFoundExceptionHandler(NoHandlerFoundException ex) {
		return Response.error(ex, NOT_FOUND.value());
	}

	@ExceptionHandler(value = TokenException.class)
	@ResponseStatus(FORBIDDEN)
	public Response<Void> tokenExceptionHandler(TokenException ex) {
		log.error("Token校验异常捕获: " + ex.getMessage());
		return Response.error(ex.getMessage(), FORBIDDEN.value());
	}

	@ExceptionHandler(value = Exception.class)
	@ResponseStatus(INTERNAL_SERVER_ERROR)
	public Response<Void> defaultErrorHandler(Exception ex) {
		log.error("全局异常捕获: ", ex);
		return Response.error(ex);
	}
}
```

* `@RestControllerAdvice` 可用于返回JSON格式报文.

或者继承`ResponseEntityExceptionHandler`更灵活地控制状态码、`Header`等信息: 

```java
@ControllerAdvice
public class RestResponseEntityExceptionHandler extends ResponseEntityExceptionHandler {

//	@ResponseStatus(HttpStatus.OK)
	@ExceptionHandler(value = { Exception.class })
	@Nullable
	protected ResponseEntity<Object> handleConflict(Exception ex, WebRequest request) {
		String bodyOfResponse = ex.getMessage();
		HttpHeaders headers = new HttpHeaders();
		headers.set(CONTENT_TYPE, MediaType.APPLICATION_JSON_UTF8_VALUE);
		return handleExceptionInternal(ex, bodyOfResponse, headers, HttpStatus.INTERNAL_SERVER_ERROR, request);
	}
}
```

更多方式请看: ***[http://www.baeldung.com/exception-handling-for-rest-with-spring](http://www.baeldung.com/exception-handling-for-rest-with-spring)***

### 异常处理性能优化

Java 异常对象的构造是十分耗时的, 原因是创建异常对象时会调用父类 `Throwable` 的 `fillInStackTrace()` 方法生成栈追踪信息, 对于一般的**业务异常**, 我们可以适当优化, 先看一下 `RuntimeException` 的构造器:

```java
protected RuntimeException(String message, Throwable cause,
                               boolean enableSuppression,
                               boolean writableStackTrace) {
        super(message, cause, enableSuppression, writableStackTrace);
    }
```

这几个参数的意义如下：

* `message`
  异常的描述信息, 也就是在打印栈追踪信息时异常类名后面紧跟着的描述字符串
* `cause`
  导致此异常发生的父异常, 即追踪信息里的`caused by`
* `enableSuppress`
  关于异常挂起的参数, 这里我们永远设为 `false` 即可
* `writableStackTrace`
  表示是否生成栈追踪信息, 只要将此参数设为 `false`, 则在构造异常对象时就不会调用 f`illInStackTrace()`

业务异常可以这样定义:

```java
public class XXXException extends RuntimeException {
    /**
     * 仅包含message, 没有cause, 也不记录栈异常, 性能最高
     * @param msg
     */
    public XXXException(String msg) {
        this(msg, false);
    }

    /**
     * 包含message, 可指定是否记录异常
     * @param msg
     * @param recordStackTrace
     */
    public EngineException(String msg, boolean recordStackTrace) {
        super(msg, null, false, recordStackTrace);
    }

    /**
     * 包含message和cause, 会记录栈异常
     * @param msg
     * @param cause
     */
    public EngineException(String msg, Throwable cause) {
        super(msg, cause, false, true);
    }
}
```

一般情况用第一个构造参数, 比较轻量级, 想要精准跟踪异常可以使用第三个构造参数.

## 404处理

Spring Boot 2.X 中会有一个Resouce的Mapping来处理静态资源, 当输入一个不存在的请求时, 总会匹配到这个Mapping:

![](https://cdn.yangbingdong.com/img/spring-boot-learning/spring-mvc-resource-mapping.png)

此时的404错误是 `ResourceHttpRequestHandler#handleRequest` 中因为找不到resource从而调用`response#sendError` 发出的:

![](https://cdn.yangbingdong.com/img/spring-boot-learning/spring-mvc-resource-not-found.png)

一般地如果是前后分离的项目, 都不要将资源放在后端, 所以可以用过以下配置关闭这个万能的Mapping:

```yaml
spring:
  resources:
    add-mappings: false
```

通过以上配置后, 将加载不了静态资源, 如果需要加载, 需要自定义配置, 比如Swagger:

```java
@Override
public void addResourceHandlers(ResourceHandlerRegistry registry) {
	registry.addResourceHandler("/swagger-ui.html")
			.addResourceLocations("classpath:/META-INF/resources/", "/static", "/public");

	registry.addResourceHandler("/webjars/**")
			.addResourceLocations("classpath:/META-INF/resources/webjars/");


}
```

如果需要通过抛异常的方式捕获404这个异常, 需要通过以下配置:

```yaml
spring:
  mvc:
    throw-exception-if-no-handler-found: true
```

![](https://cdn.yangbingdong.com/img/spring-boot-learning/spring-mvc-throw-not-found.png)

之后可以通过 `@ExceptionHandler(value = NoHandlerFoundException.class)` 处理这个404了, 而不是转发到 `/error`.

## 静态资源

设置静态资源放到指定路径下

```
spring.resources.static-locations=classpath:/META-INF/resources/,classpath:/static/
```

> ***[https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#boot-features-spring-mvc-static-content](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#boot-features-spring-mvc-static-content)***

## 自定义消息转化器

```java
	@Bean
    public StringHttpMessageConverter stringHttpMessageConverter() {
        StringHttpMessageConverter converter = new StringHttpMessageConverter(Charset.forName("UTF-8"));
        return converter;
    }
```

## 自定义SpringMVC的拦截器

有些时候我们需要自己配置SpringMVC而不是采用默认, 比如增加一个拦截器

```java
public class MyInterceptor implements HandlerInterceptor {

    @Override
    public void afterCompletion(HttpServletRequest arg0, HttpServletResponse arg1, Object arg2, Exception arg3)
            throws Exception {
        System.out.println("拦截器MyInterceptor------->3、请求结束之后被调用, 主要用于清理工作. ");

    }

    @Override
    public void postHandle(HttpServletRequest arg0, HttpServletResponse arg1, Object arg2, ModelAndView arg3)
            throws Exception {
        System.out.println("拦截器MyInterceptor------->2、请求之后调用, 在视图渲染之前, 也就是Controller方法调用之后");

    }

    @Override
    public boolean preHandle(HttpServletRequest arg0, HttpServletResponse arg1, Object arg2) throws Exception {
        System.out.println("拦截器MyInterceptor------->1、请求之前调用, 也就是Controller方法调用之前. ");
        return true;//返回true则继续向下执行, 返回false则取消当前请求
    }

}
```

```java
@Configuration
public class InterceptorConfigurerAdapter extends WebMvcConfigurer {
    /**
     * 该方法用于注册拦截器
     * 可注册多个拦截器, 多个拦截器组成一个拦截器链
     */
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // addPathPatterns 添加路径
        // excludePathPatterns 排除路径
        registry.addInterceptor(new MyInterceptor()).addPathPatterns("/*.*");
        super.addInterceptors(registry);
    }
}
```

或者可以使用继承`HandlerInterceptorAdapter`的方式, 这种方式可以**按需覆盖父类方法**. 

## 创建 Servlet、 Filter、Listener

### 注解方式

> 直接通过`@WebServlet`、`@WebFilter`、`@WebListener` 注解自动注册

```java
@WebFilter(filterName = "customFilter", urlPatterns = "/*")
public class CustomFilter implements Filter {
    ...
}

@WebListener
public class CustomListener implements ServletContextListener {
    ...
}

@WebServlet(name = "customServlet", urlPatterns = "/roncoo")
public class CustomServlet extends HttpServlet {
    ...
}
```

然后需要在`**Application.java` 加上`@ServletComponentScan`注解, 否则不会生效. 

**注意: 如果同时添加了`@WebFilter`以及`@Component`, 那么会初始化两次Filter, 并且会过滤所有路径+自己指定的路径 , 便会出现对没有指定的URL也会进行过滤**

### 通过编码注册

```java
@Configuration
public class WebConfig {

    @Bean
    public FilterRegistrationBean myFilter(){
        FilterRegistrationBean registrationBean = new FilterRegistrationBean();
        MyFilter filter = new MyFilter();
        registrationBean.setFilter(filter);

        List<String> urlPatterns = new ArrayList<>();
        urlPatterns.add("/*");
        registrationBean.setUrlPatterns(urlPatterns);
        registrationBean.setOrder(1);

        return registrationBean;
    }

    @Bean
    public ServletRegistrationBean myServlet() {
        MyServlet demoServlet = new MyServlet();
        ServletRegistrationBean registrationBean = new ServletRegistrationBean();
        registrationBean.setServlet(demoServlet);
        List<String> urlMappings = new ArrayList<String>();
        urlMappings.add("/myServlet");////访问, 可以添加多个
        registrationBean.setUrlMappings(urlMappings);
        registrationBean.setLoadOnStartup(1);
        return registrationBean;
    }

    @Bean
    public ServletListenerRegistrationBean myListener() {
        ServletListenerRegistrationBean registrationBean
                = new ServletListenerRegistrationBean<>();
        registrationBean.setListener(new MyListener());
        registrationBean.setOrder(1);
        return registrationBean;
    }
}
```

## Spring Interceptor与Servlet Filter的区别

- `Filter`是基于函数回调的, 而`Interceptor`则是基于Java反射的. 
- `Filter`依赖于Servlet容器, 而`Interceptor`不依赖于Servlet容器. 
- `Filter`对几乎所有的请求起作用, 而`Interceptor`只能对`action`请求起作用. 
- `Interceptor`可以访问`Action`的上下文, 值栈里的对象, 而`Filter`不能. 
- 在`action`的生命周期里, `Interceptor`可以被多次调用, 而Filter只能在容器初始化时调用一次. 

![](https://cdn.yangbingdong.com/img/spring-boot-learning/mvc-process.png)

## RequestBodyAdvice和ResponseBodyAdvice

### 应用场景

* 对Request请求参数解密, 对Response返回参数进行加密
* 自定义返回信息（业务无关性的）

### 使用

先看一下`ResponseBodyAdvice`

```java
public interface ResponseBodyAdvice<T> {

	/**
	 * Whether this component supports the given controller method return type
	 * and the selected {@code HttpMessageConverter} type.
	 * @param returnType the return type
	 * @param converterType the selected converter type
	 * @return {@code true} if {@link #beforeBodyWrite} should be invoked;
	 * {@code false} otherwise
	 */
	boolean supports(MethodParameter returnType, Class<? extends HttpMessageConverter<?>> converterType);

	/**
	 * Invoked after an {@code HttpMessageConverter} is selected and just before
	 * its write method is invoked.
	 * @param body the body to be written
	 * @param returnType the return type of the controller method
	 * @param selectedContentType the content type selected through content negotiation
	 * @param selectedConverterType the converter type selected to write to the response
	 * @param request the current request
	 * @param response the current response
	 * @return the body that was passed in or a modified (possibly new) instance
	 */
	T beforeBodyWrite(T body, MethodParameter returnType, MediaType selectedContentType,
			Class<? extends HttpMessageConverter<?>> selectedConverterType,
			ServerHttpRequest request, ServerHttpResponse response);

}
```

其中`supports`方法指定是否需要执行`beforeBodyWrite`, 其中参数`returnType`可以拿到Controller对应方法中的方法注解以及参数注解: `returnType.getMethodAnnotation(XXXAnnotation.class)`、`returnType.getParameterAnnotation(XXXAnnotation.class)`. 

`beforeBodyWrite`可以对返回的body进行包装或加密: 

```java
/**
 * @author ybd
 * @date 18-5-15
 * @contact yangbingdong1994@gmail.com
 */
@RestControllerAdvice(annotations = Rest.class)
public class GlobalControllerAdvisor implements ResponseBodyAdvice {
	private static final String VOID = "void";

	/**
	 * String 类型不支持
	 */
	@Override
	public boolean supports(MethodParameter returnType, Class converterType) {
		return !(returnType.getGenericParameterType() instanceof Class) || !((Class<?>) returnType.getGenericParameterType()).isAssignableFrom(String.class);
	}

	@Override
	public Object beforeBodyWrite(Object body, MethodParameter returnType, MediaType selectedContentType, Class selectedConverterType, ServerHttpRequest request, ServerHttpResponse response) {
		return isVoidMethod(returnType) ? Response.ok() : Response.ok(body);
	}

	private boolean isVoidMethod(MethodParameter returnType) {
		return VOID.equals(returnType.getGenericParameterType().getTypeName());
	}
}
```

* 需要在类上面添加`@ControllerAdvice`或`@RestControllerAdvice`才能生效

>  `RequestBodyAdvice`的`beforeBodyRead`在拦截器之后执行, 所以可以在拦截器做签名检验, 然后在`RequestBodyAdvice`中解密请求参数

## Spring Boot和Feign中使用Java 8时间日期API（LocalDate等）的序列化问题

***[http://blog.didispace.com/Spring-Boot-And-Feign-Use-localdate/](http://blog.didispace.com/Spring-Boot-And-Feign-Use-localdate/)***

## RequestBody 多读

有时候, 我们想要在过滤器或者拦截器中记录一下请求信息, POST 请求的 body 部分需要在 Request 中读取 InputStream. 但默认情况下只能读取一次, 可以通过继承 `HttpServletRequestWrapper` 实现:

```java
@Slf4j
public class RequestBodyCachingWrapper extends HttpServletRequestWrapper {

    private byte[] body;

    private BufferedReader reader;

    private ServletInputStream inputStream;

    public RequestBodyCachingWrapper(HttpServletRequest request) throws IOException{
        super(request);
        loadBody(request);
    }

    private void loadBody(HttpServletRequest request) throws IOException{
        body = IoUtil.readBytes(request.getInputStream());
        inputStream = new RequestCachingInputStream(body);
    }

    public byte[] getBody() {
        return body;
    }

    @Override
    public ServletInputStream getInputStream() throws IOException {
        if (inputStream != null) {
            return inputStream;
        }
        return super.getInputStream();
    }

    @Override
    public BufferedReader getReader() throws IOException {
        if (reader == null) {
            reader = new BufferedReader(new InputStreamReader(inputStream, getCharacterEncoding()));
        }
        return reader;
    }

    private static class RequestCachingInputStream extends ServletInputStream {

        private final ByteArrayInputStream inputStream;

        public RequestCachingInputStream(byte[] bytes) {
            inputStream = new ByteArrayInputStream(bytes);
        }
        @Override
        public int read() throws IOException {
            return inputStream.read();
        }

        @Override
        public boolean isFinished() {
            return inputStream.available() == 0;
        }

        @Override
        public boolean isReady() {
            return true;
        }

        @Override
        public void setReadListener(ReadListener readlistener) {
        }

    }

}
```

Filter:

```java
public class RequestBodyCachingFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String method = request.getMethod();
        if (!"GET".equals(method) && !"OPTIONS".equals(method)) {
            filterChain.doFilter(new RequestBodyCachingWrapper(request), response);
        }
    }

}
```

configuration:

```java
@Conditional(RequestBodyCachingCondition.class)
@Bean
public FilterRegistrationBean<RequestBodyCachingFilter> requestBodyCachingFilterFilterRegistrationBean() {
    FilterRegistrationBean<RequestBodyCachingFilter> registrationBean = new FilterRegistrationBean<>();
    RequestBodyCachingFilter requestBodyCachingFilter = new RequestBodyCachingFilter();
    registrationBean.setFilter(requestBodyCachingFilter);
    registrationBean.setOrder(Ordered.LOWEST_PRECEDENCE - 8);
    return registrationBean;
}
```

获取 requestBody:

```java
public static String getRequestBody() {
    RequestBodyCachingWrapper wrapper = WebUtils.getNativeRequest(currentRequest(), RequestBodyCachingWrapper.class);
    if (wrapper != null) {
        byte[] buf = wrapper.getBody();
        if (buf.length > 0) {
            return new String(buf);
        }
    }
    return StrUtil.EMPTY;
}
```

## Restful 性能优化

在 Spring MVC 中, 通过 `@PathVariable` 注解可轻松实现 Restful 风格的请求. 但是对于这种请求, Spring MVC 不能通过 url 直接获取到对应的 `HandlerMethod`, 而是通过 for 循环一个个地匹配, 效率低下.

我们可以通过重写 `RequestMappingHandlerMapping#lookupHandlerMethod` 方法, 思路是, 如果是匹配类型的 restful 请求, 其真正映射到的是 `@RequestMapping#name`, 请求时将 `name` 放在 Header 中, 查找的时候直接拿到通过 Hash 定位即可, 性能与直接匹配的效果一样.

继承 `RequestMappingHandlerMapping`:

```java
public class EnhanceRequestMappingHandlerMapping extends RequestMappingHandlerMapping {

    public static final String X_INNER_ACTION = "X-Inner-Action";

    private Map<String, RequestMappingInfoHandlerMethodPair> urlPairLookup;

    @Override
    protected void handlerMethodsInitialized(Map<RequestMappingInfo, HandlerMethod> handlerMethods) {
        super.handlerMethodsInitialized(handlerMethods);
        urlPairLookup = new HashMap<>(handlerMethods.size());
        handlerMethods.forEach((k, v) -> {
            Set<String> pathPatterns = getMappingPathPatterns(k);
            if (pathPatterns.size() > 1) {
                throw new IllegalArgumentException("Not allow multi paths");
            }
            String path = new ArrayList<>(pathPatterns).get(0);
            if (getPathMatcher().isPattern(path)) {
                if (k.getName() == null) {
                    throw new IllegalArgumentException("Pattern path must have a name");
                }
                path = k.getName();
            }
            RequestMappingInfoHandlerMethodPair pair = buildPair(k, v);
            urlPairLookup.put(path, pair);
        });
    }

    @Override
    protected HandlerMethod lookupHandlerMethod(String lookupPath, HttpServletRequest request) {
        String lookupPathKey = defaultIfNull(request.getHeader(X_INNER_ACTION), lookupPath);
        RequestMappingInfoHandlerMethodPair pair = urlPairLookup.get(lookupPathKey);
        if (pair == null) {
            return null;
        }
        request.setAttribute(BEST_MATCHING_HANDLER_ATTRIBUTE, pair.handlerMethod);
        handleMatch(pair.requestMappingInfo, lookupPath, request);
        return pair.handlerMethod;
    }

    private RequestMappingInfoHandlerMethodPair buildPair(RequestMappingInfo requestMappingInfo, HandlerMethod handlerMethod) {
        return new RequestMappingInfoHandlerMethodPair(requestMappingInfo, handlerMethod);
    }

    @Data
    @AllArgsConstructor
    private static class RequestMappingInfoHandlerMethodPair {
        private RequestMappingInfo requestMappingInfo;
        private HandlerMethod handlerMethod;
    }
}
```

配置:

```java
@Configuration(proxyBeanMethods = false)
public class EnhanceWebMvcConfigurationSupport extends WebMvcConfigurationSupport {

    @Override
    protected RequestMappingHandlerMapping createRequestMappingHandlerMapping() {
        return new EnhanceRequestMappingHandlerMapping();
    }
}
```

## 跨域配置

### Spring Mvc

方式一: 在 Controller 的类或者方法上贴上 `@CrossOrigin`

方式二: 上面的方式一需要每个类或者方法都加上, 有点麻烦, 可以使用 Spring 的 `CorsFilter`:

```java
@Bean
public CorsFilter corsFilter() {
	UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
	CorsConfiguration corsConfiguration = new CorsConfiguration();
	corsConfiguration.addAllowedHeader("*");
	corsConfiguration.addAllowedOrigin("*");
	corsConfiguration.addAllowedMethod("*");
	corsConfiguration.setAllowCredentials(true);
	corsConfiguration.setMaxAge(Duration.ofHours(1));
	source.registerCorsConfiguration("/**", corsConfiguration);
	return new CorsFilter(source);
}
```

### Spring Security

```java
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
                .authorizeRequests()
                .anyRequest().authenticated()
                .and()
                .formLogin()
                .permitAll()
                .and()
                .httpBasic()
                .and()
                .cors()
                .configurationSource(corsConfigurationSource())
                .and()
                .csrf()
                .disable();
    }
    @Bean
    CorsConfigurationSource corsConfigurationSource() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowCredentials(true);
        configuration.setAllowedOrigins(Arrays.asList("*"));
        configuration.setAllowedMethods(Arrays.asList("*"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setMaxAge(Duration.ofHours(1));
        source.registerCorsConfiguration("/**",configuration);
        return source;
    }
}
```

### OAuth2

集成了 OAth2 后, `/oauth/token` 会先发送一次 option 请求.

```java
@Configuration
public class GlobalCorsConfiguration {
    @Bean
    public CorsFilter corsFilter() {
        CorsConfiguration corsConfiguration = new CorsConfiguration();
        corsConfiguration.setAllowCredentials(true);
        corsConfiguration.addAllowedOrigin("*");
        corsConfiguration.addAllowedHeader("*");
        corsConfiguration.addAllowedMethod("*");
        UrlBasedCorsConfigurationSource urlBasedCorsConfigurationSource = new UrlBasedCorsConfigurationSource();
        urlBasedCorsConfigurationSource.registerCorsConfiguration("/**", corsConfiguration);
        return new CorsFilter(urlBasedCorsConfigurationSource);
    }
}
```

然后在 SecurityConfig 中开启跨域支持

```java
@Configuration
@Order(Ordered.HIGHEST_PRECEDENCE)
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    ...
    ...
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
                .requestMatchers().antMatchers(HttpMethod.OPTIONS, "/oauth/**")
                .and()
                .csrf().disable().formLogin()
                .and()
                .cors();
    }
}
```

# Validation

## 常用注解（大部分**JSR**中已有）

| 注解                                           | 类型                                                         | 说明                                                         |
| ---------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `@AssertFalse`                                 | Boolean,boolean                                              | 验证注解的元素值是false                                      |
| `@AssertTrue`                                  | Boolean,boolean                                              | 验证注解的元素值是true                                       |
| `@NotNull`                                     | 任意类型                                                     | 验证注解的元素值不是null                                     |
| `@Null`                                        | 任意类型                                                     | 验证注解的元素值是null                                       |
| `@Min(value=值)`                               | BigDecimal, BigInteger, byte,short, int, long, 等任何Number或CharSequence（存储的是数字）子类型 | 验证注解的元素值大于等于@Min指定的value值                    |
| `@Max（value=值）`                             | 和@Min要求一样                                               | 验证注解的元素值小于等于@Max指定的value值                    |
| `@DecimalMin(value=值)`                        | 和@Min要求一样                                               | 验证注解的元素值大于等于@ DecimalMin指定的value值            |
| `@DecimalMax(value=值)`                        | 和@Min要求一样                                               | 验证注解的元素值小于等于@ DecimalMax指定的value值            |
| `@Digits(integer=整数位数, fraction=小数位数)` | 和@Min要求一样                                               | 验证注解的元素值的整数位数和小数位数上限                     |
| `@Size(min=下限, max=上限)`                    | 字符串、Collection、Map、数组等                              | 验证注解的元素值的在min和max（包含）指定区间之内, 如字符长度、集合大小 |
| `@Past`                                        | java.util.Date,java.util.Calendar;Joda Time类库的日期类型    | 验证注解的元素值（日期类型）比当前时间早                     |
| `@Future`                                      | 与@Past要求一样                                              | 验证注解的元素值（日期类型）比当前时间晚                     |
| `@NotBlank`                                    | CharSequence子类型                                           | 验证注解的元素值不为空（不为null、去除首位空格后长度为0）, 不同于@NotEmpty, @NotBlank只应用于字符串且在比较时会去除字符串的首位空格 |
| `@Length(min=下限, max=上限)`                  | CharSequence子类型                                           | 验证注解的元素值长度在min和max区间内                         |
| `@NotEmpty`                                    | CharSequence子类型、Collection、Map、数组                    | 验证注解的元素值不为null且不为空（字符串长度不为0、集合大小不为0） |
| `@Range(min=最小值, max=最大值)`               | BigDecimal,BigInteger,CharSequence, byte, short, int, long等原子类型和包装类型 | 验证注解的元素值在最小值和最大值之间                         |
| `@Email(regexp=正则表达式,flag=标志的模式)`    | CharSequence子类型（如String）                               | 验证注解的元素值是Email, 也可以通过regexp和flag指定自定义的email格式 |
| `@Pattern(regexp=正则表达式,flag=标志的模式)`  | String, 任何CharSequence的子类型                             | 验证注解的元素值与指定的正则表达式匹配                       |
| `@Valid`                                       | 任何非原子类型                                               | 指定递归验证关联的对象；如用户对象中有个地址对象属性, 如果想在验证用户对象时一起验证地址对象的话, 在地址对象上加@Valid注解即可级联验证 |

## 简单使用

实体: 

```java
@Data
public class Foo {
	@NotBlank
	private String name;

	@Min(18)
	private Integer age;

	@Pattern(regexp = "^1([34578])\\d{9}$",message = "手机号码格式错误")
	@NotBlank(message = "手机号码不能为空")
	private String phone;

	@Email(message = "邮箱格式错误")
	private String email;
}
```

`Controller`:

```java
@RestController
@Slf4j
public class FooController {

   @PostMapping("/foo")
   public String foo(@Validated Foo foo, BindingResult bindingResult) {
      log.info("foo: {}", foo);
      if (bindingResult.hasErrors()) {
         for (FieldError fieldError : bindingResult.getFieldErrors()) {
            log.error("valid fail: field = {}, message = {}", fieldError.getField(), fieldError.getDefaultMessage());
         }
         return "fail";
      }
      return "success";
   }
}
```

## 快速失效

一般情况下, Validator并不会应为第一个校验失败为停止, 而是一直校验完所有参数. 我们可以通过设置快速失效: 

```java
@Configuration
public class ValidatorConfiguration {
	@Bean
	public Validator validator(){
		ValidatorFactory validatorFactory = Validation.byProvider( HibernateValidator.class )
													  .configure()
													  .failFast( true )
//													  .addProperty( "hibernate.validator.fail_fast", "true" )
													  .buildValidatorFactory();
		return validatorFactory.getValidator();
	}
}
```

这样在遇到第一个校验失败的时候就会停止对之后的参数校验. 

## 分组校验

> 如果同一个类, 在不同的使用场景下有不同的校验规则, 那么可以使用分组校验. 未成年人是不能喝酒的, 而在其他场景下我们不做特殊的限制, 这个需求如何体现同一个实体, 不同的校验规则呢？

添加分组: 

```java
Class Foo{
	@Min(value = 18,groups = {Adult.class})
	private Integer age;
	
	public interface Adult{}
	
	public interface Minor{}
}
```

`Controller`: 

```java
@RequestMapping("/drink")
public String drink(@Validated({Foo.Adult.class}) Foo foo, BindingResult bindingResult) {
    if(bindingResult.hasErrors()){
        for (FieldError fieldError : bindingResult.getFieldErrors()) {
            //...
        }
        return "fail";
    }
    return "success";
}
```

## 自定义校验

业务需求总是比框架提供的这些简单校验要复杂的多, 我们可以自定义校验来满足我们的需求. 自定义spring validation非常简单, 主要分为两步. 

1 自定义校验注解
我们尝试添加一个“字符串不能包含空格”的限制. 

```java
@Target({METHOD, FIELD, ANNOTATION_TYPE, CONSTRUCTOR, PARAMETER})
@Retention(RUNTIME)
@Documented
@Constraint(validatedBy = {CannotHaveBlankValidator.class})<1>
public @interface CannotHaveBlank {

    //默认错误消息
    String message() default "不能包含空格";

    //分组
    Class<?>[] groups() default {};

    //负载
    Class<? extends Payload>[] payload() default {};

    //指定多个时使用
    @Target({FIELD, METHOD, PARAMETER, ANNOTATION_TYPE})
    @Retention(RUNTIME)
    @Documented
    @interface List {
        CannotHaveBlank[] value();
    }

}
```

我们不需要关注太多东西, 使用spring validation的原则便是便捷我们的开发, 例如payload, List , groups, 都可以忽略. 

`<1>` 自定义注解中指定了这个注解真正的验证者类. 

2 编写真正的校验者类

```java
public class CannotHaveBlankValidator implements <1> ConstraintValidator<CannotHaveBlank, String> {

	@Override
    public void initialize(CannotHaveBlank constraintAnnotation) {
    }
    
    @Override
    public boolean isValid(String value, ConstraintValidatorContext context <2>) {
        //null时不进行校验
        if (value != null && value.contains(" ")) {
	        <3>
            //获取默认提示信息
            String defaultConstraintMessageTemplate = context.getDefaultConstraintMessageTemplate();
            System.out.println("default message :" + defaultConstraintMessageTemplate);
            //禁用默认提示信息
            context.disableDefaultConstraintViolation();
            //设置提示语
            context.buildConstraintViolationWithTemplate("can not contains blank").addConstraintViolation();
            return false;
        }
        return true;
    }
}
```

`<1>` 所有的验证者都需要实现`ConstraintValidator`接口, 它的接口也很形象, 包含一个初始化事件方法, 和一个判断是否合法的方法

```java
public interface ConstraintValidator<A extends Annotation, T> {
	void initialize(A constraintAnnotation);
		boolean isValid(T value, ConstraintValidatorContext context);
}
```

`<2> ` `ConstraintValidatorContext` 这个上下文包含了认证中所有的信息, 我们可以利用这个上下文实现获取默认错误提示信息, 禁用错误提示信息, 改写错误提示信息等操作. 

`<3>` 一些典型校验操作, 或许可以对你产生启示作用. 

值得注意的一点是, 自定义注解可以用在`METHOD, FIELD, ANNOTATION_TYPE, CONSTRUCTOR, PARAMETER`之上, `ConstraintValidator`的第二个泛型参数T, 是需要被校验的类型. 

## 手动校验

可能在某些场景下需要我们手动校验, 即使用校验器对需要被校验的实体发起validate, 同步获得校验结果. 理论上我们既可以使用Hibernate Validation提供Validator, 也可以使用Spring对其的封装. 在spring构建的项目中, 提倡使用经过spring封装过后的方法, 这里两种方法都介绍下: 

**Hibernate Validation**: 

```java
Foo foo = new Foo();
foo.setAge(22);
foo.setEmail("000");
ValidatorFactory vf = Validation.buildDefaultValidatorFactory();
Validator validator = vf.getValidator();
Set<ConstraintViolation<Foo>> set = validator.validate(foo);
for (ConstraintViolation<Foo> constraintViolation : set) {
    System.out.println(constraintViolation.getMessage());
}
```

由于依赖了Hibernate Validation框架, 我们需要调用Hibernate相关的工厂方法来获取validator实例, 从而校验. 

在spring framework文档的Validation相关章节, 可以看到如下的描述: 

> Spring provides full support for the Bean Validation API. This includes convenient support for bootstrapping a JSR-303/JSR-349 Bean Validation provider as a Spring bean. This allows for a javax.validation.ValidatorFactory or javax.validation.Validator to be injected wherever validation is needed in your application. Use the LocalValidatorFactoryBean to configure a default Validator as a Spring bean:

> bean id=”validator” class=”org.springframework.validation.beanvalidation.LocalValidatorFactoryBean”

> The basic configuration above will trigger Bean Validation to initialize using its default bootstrap mechanism. A JSR-303/JSR-349 provider, such as Hibernate Validator, is expected to be present in the classpath and will be detected automatically.

上面这段话主要描述了spring对validation全面支持JSR-303、JSR-349的标准, 并且封装了`LocalValidatorFactoryBean`作为validator的实现. 值得一提的是, 这个类的责任其实是非常重大的, 他兼容了spring的validation体系和hibernate的validation体系, 也可以被开发者直接调用, 代替上述的从工厂方法中获取的hibernate validator. 由于我们使用了springboot, 会触发web模块的自动配置, `LocalValidatorFactoryBean`已经成为了Validator的默认实现, 使用时只需要自动注入即可. 

```java
@Autowired
Validator globalValidator; <1>

@RequestMapping("/validate")
public String validate() {
    Foo foo = new Foo();
    foo.setAge(22);
    foo.setEmail("000");

    Set<ConstraintViolation<Foo>> set = globalValidator.validate(foo);<2>
    for (ConstraintViolation<Foo> constraintViolation : set) {
        System.out.println(constraintViolation.getMessage());
    }

    return "success";
}
```

`<1>` 真正使用过`Validator`接口的读者会发现有两个接口, 一个是位于`javax.validation`包下, 另一个位于`org.springframework.validation`包下, **注意我们这里使用的是前者**`javax.validation`, 后者是spring自己内置的校验接口, `LocalValidatorFactoryBean`同时实现了这两个接口. 

`<2>` 此处校验接口最终的实现类便是`LocalValidatorFactoryBean`. 

## 基于方法校验

```java
@RestController
@Validated <1>
public class BarController {

    @RequestMapping("/bar")
    public @NotBlank <2> String bar(@Min(18) Integer age <3>) {
        System.out.println("age : " + age);
        return "";
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public Map handleConstraintViolationException(ConstraintViolationException cve){
        Set<ConstraintViolation<?>> cves = cve.getConstraintViolations();<4>
        for (ConstraintViolation<?> constraintViolation : cves) {
            System.out.println(constraintViolation.getMessage());
        }
        Map map = new HashMap();
        map.put("errorCode",500);
        return map;
    }

}
```

`<1>` 为类添加@Validated注解

`<2> <3>` 校验方法的返回值和入参

`<4>` 添加一个异常处理器, 可以获得没有通过校验的属性相关信息

基于方法的校验, 个人不推荐使用, 感觉和项目结合的不是很好. 

## 统一处理验证异常

| 异常类型                                  | 描述                             |
| ----------------------------------------- | -------------------------------- |
| `ConstraintViolationException`            | 违反约束, javax扩展定义          |
| `BindException`                           | 绑定失败, 如表单对象参数违反约束 |
| `MethodArgumentNotValidException`         | 参数无效, 如JSON请求参数违反约束 |
| `MissingServletRequestParameterException` | 参数缺失                         |
| `TypeMismatchException`                   | 参数类型不匹配                   |

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

	@ExceptionHandler(value = {
			MethodArgumentNotValidException.class,
			BindException.class,
			ConstraintViolationException.class})
	@ResponseStatus(HttpStatus.OK)
	public Response<Void> handleValidException(Exception ex) {
		String validateFailReason;
		if (ex instanceof MethodArgumentNotValidException) {
			validateFailReason = ((MethodArgumentNotValidException) ex).getBindingResult()
																	   .getFieldError()
																	   .getDefaultMessage();
		} else if (ex instanceof BindException) {
			validateFailReason = ((BindException) ex).getFieldError().getDefaultMessage();
		} else if (ex instanceof ConstraintViolationException) {
			validateFailReason = ((ConstraintViolationException) ex).getConstraintViolations().stream()
																	.findAny()
																	.map(ConstraintViolation::getMessage)
																	.orElse("Unknown error message");
		} else {
			validateFailReason = "Unknown error message";
		}
		return Response.error(validateFailReason);
	}

	@ExceptionHandler(value = {Exception.class})
	public Response<Void> handle(Exception exception) {
		return Response.error(exception.getMessage());
	}
}
```

> 参考: 
> ***[https://www.cnkirito.moe/2017/08/16/%E4%BD%BF%E7%94%A8spring%20validation%E5%AE%8C%E6%88%90%E6%95%B0%E6%8D%AE%E5%90%8E%E7%AB%AF%E6%A0%A1%E9%AA%8C/](https://www.cnkirito.moe/2017/08/16/%E4%BD%BF%E7%94%A8spring%20validation%E5%AE%8C%E6%88%90%E6%95%B0%E6%8D%AE%E5%90%8E%E7%AB%AF%E6%A0%A1%E9%AA%8C/)***
>
> 相关代码:
>
> ***[https://github.com/masteranthoneyd/spring-boot-learning](https://github.com/masteranthoneyd/spring-boot-learning)***

# Authentication

下面介绍两种关于登录认证的实现方案, 分别是基于 Spring Security, 以及基于 Spring Mvc 的 `HandlerInterceptor`.

## 基于 Spring Security

Spring Security 是基于嵌套 `Filter`(委派 Filter) 实现的, 在 `DispatcherServlet` 之前触发.

![](https://cdn.yangbingdong.com/img/spring-boot-security/security-filters.png)

默认有哪些 Filter 可以看 `FilterComparator` 中的源码:

![](https://cdn.yangbingdong.com/img/spring-boot-security/filter-comparator.png)

### 认证流程

![](https://cdn.yangbingdong.com/img/spring-boot-security/core-service-Sequence.png)

#### 登录拦截

在 `FilterComparator` 中有一个 `UsernamePasswordAuthenticationFilter`, 继承了 `AbstractAuthenticationProcessingFilter`, 它就是我们登录时用到的 Filter:

![](https://cdn.yangbingdong.com/img/spring-boot-security/username-password-authentication-filter.png)

* 可以看到, **默认情况下拦截 `/login` 端点的 POST 请求**, 当然, 可以通过配置改变这个 url.
* 这里还有一个关键, 在 `attempAuthentication` 中, 用户名以及密码的参数是 `username` 以及 `password`, 并且是从 http parameter 中获取的, 如果要**支持 Json 格式的登录, 那就要重写这里**.
* 将登录请求信息封装成 `Authentication` 的实现类, 这里是 `UsernamePasswordAuthenticationToken`, **然后交给 `AuthenticationManager` 进行下一步的认证**. 

> 这一步相当与登录信息的提取以及封装.

#### 认证

认证通过 `AuthenticationManager` 进行的, 这是一个接口, 默认的实现类为 `ProviderManager`:

![](https://cdn.yangbingdong.com/img/spring-boot-security/provider-manager.png)

可以看到实现类 `ProviderManager` 中维护了一个 `List<AuthenticationProvider>` 的列表, 存放多种认证方式, 实际上这是委托者模式的应用(Delegate)

> 核心的认证入口始终只有一个: `AuthenticationManager`, 不同的认证方式: 用户名 + 密码(`UsernamePasswordAuthenticationToken`), 邮箱 + 密码, 手机号码 + 密码登录则对应了三个 `AuthenticationProvider`. 在默认策略下, 只需要通过一个 `AuthenticationProvider` 的认证, 即可被认为是登录成功.

![](https://cdn.yangbingdong.com/img/spring-boot-security/spring%20security%20architecture.png)

一个最常用到的 `AuthenticationProvider` 实现类就是 `DaoAuthenticationProvider`, 里面比较重要的一个环节就是 `additionalAuthenticationChecks` (密码校验):

*  通过 `UserDetailsService`  的实现类(需要用户自己实现)拿到 `UserDetails`
* 将其中的 `password` 与 `UsernamePasswordAuthenticationToken` 中的 `credentials` 进行对比 

![](https://cdn.yangbingdong.com/img/spring-boot-security/dao-authentication-password-check.png)

登录成功后会执行 `AbstractAuthenticationProcessingFilter#successfulAuthentication` 将 `Authentication` 存到 `SecurityContextHolder` 中.

到此, 认证的核心就是这样了.

### 权限校验流程

`FilterSecurityInterceptor` 是整个Security filter链中的最后一个, 也是最重要的一个, 它的主要功能就是判断认证成功的用户是否有权限访问接口, 其最主要的处理方法就是 调用父类（`AbstractSecurityInterceptor`）的 `super.beforeInvocation(fi)`, 我们来梳理下这个方法的处理流程：

> - 通过 `obtainSecurityMetadataSource().getAttributes()` 获取 当前访问地址所需权限信息
> - 通过 `authenticateIfRequired()` 获取当前访问用户的权限信息
> - 通过 `accessDecisionManager.decide()` 使用 投票机制判权, 判权失败直接抛出 `AccessDeniedException` 异常

```java
protected InterceptorStatusToken beforeInvocation(Object object) {
	       
	    ......
	    
	    // 1 获取访问地址的权限信息 
		Collection<ConfigAttribute> attributes = this.obtainSecurityMetadataSource()
				.getAttributes(object);

		if (attributes == null || attributes.isEmpty()) {
		
		    ......
		    
			return null;
		}

        ......

        // 2 获取当前访问用户权限信息
		Authentication authenticated = authenticateIfRequired();

	
		try {
		    // 3  默认调用AffirmativeBased.decide() 方法, 其内部 使用 AccessDecisionVoter 对象 进行投票机制判权, 判权失败直接抛出 AccessDeniedException 异常 
			this.accessDecisionManager.decide(authenticated, object, attributes);
		}
		catch (AccessDeniedException accessDeniedException) {
			publishEvent(new AuthorizationFailureEvent(object, attributes, authenticated,
					accessDeniedException));

			throw accessDeniedException;
		}

        ......
        return new InterceptorStatusToken(SecurityContextHolder.getContext(), false,
					attributes, object);
	}
```

因此如果要动态鉴权, 可以从两方面入手:

- 自定义`SecurityMetadataSource`, 实现从数据库加载 `ConfigAttribute`
- 另外就是可以自定义 `accessDecisionManager`, 官方的 `UnanimousBased` 其实足够使用, 并且他是基于 `AccessDecisionVoter` 来实现权限认证的, 因此我们只需要自定义一个 `AccessDecisionVoter` 就可以了

```java
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.authorizeRequests()
                .withObjectPostProcessor(new ObjectPostProcessor<FilterSecurityInterceptor>() {
                    @Override
                    public <O extends FilterSecurityInterceptor> O postProcess(O object) {
                        object.setAccessDecisionManager(customUrlDecisionManager);
                        object.setSecurityMetadataSource(customFilterInvocationSecurityMetadataSource);
                        return object;
                    }
                })
                .and()
                ...
    }
}
```

### 核心配置

下面贴一个核心配置

```java
@Configuration
@RequiredArgsConstructor
@EnableGlobalMethodSecurity(prePostEnabled = true)
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    /**
     * 自定义登录逻辑验证器
     */
    private final UserAuthenticationProvider userAuthenticationProvider;
    /**
     * 自定义未登录的处理器
     */
    private final UserAuthenticationEntryPoint userAuthenticationEntryPoint;
    /**
     * 自定义登录成功处理器
     */
    private final UserLoginSuccessHandler userLoginSuccessHandler;
    /**
     * 自定义登录失败处理器
     */
    private final UserLoginFailHandler userLoginFailHandler;
    /**
     * 自定义注销成功处理器
     */
    private final UserLogoutSuccessHandler userLogoutSuccessHandler;
    /**
     * 自定义暂无权限处理器
     */
    private final UserAccessDeniedHandler userAccessDeniedHandler;
    /**
     * 自定义权限解析
     */
    private final UserPermissionEvaluator permissionEvaluator;

    /**
     * 配置登录验证逻辑
     */
    @Override
    protected void configure(AuthenticationManagerBuilder auth) {
        auth.authenticationProvider(userAuthenticationProvider);
    }
    
    /**
     * 静态资源不需要走过滤链
     */
    @Override
    public void configure(WebSecurity web) {
        web.ignoring()
           .requestMatchers(PathRequest.toStaticResources().atCommonLocations());
    }

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.authorizeRequests()
                // 不需要认证的 url
                .antMatchers("/hello/**").permitAll()
                // 其他的请求需要认证
                .anyRequest()
                .authenticated()
            .and()
                // 关闭默认的登录配置 (UsernamePasswordAuthenticationFilter), 在下面配置自定义的登录 Filter(支持 json 登录)
                .formLogin()
            .disable()
                .logout()
                // 配置注销地址
                .logoutUrl("/user/logout")
                // 配置注销成功处理器
                .logoutSuccessHandler(userLogoutSuccessHandler)
            .and()
                .exceptionHandling()
                // 配置没有权限自定义处理类
                .accessDeniedHandler(userAccessDeniedHandler)
                .authenticationEntryPoint(userAuthenticationEntryPoint)
            .and()
                // 开启跨域
                .cors()
                .configurationSource(corsConfigurationSource())
            .and()
                // 取消跨站请求伪造防护
                .csrf()
            .disable()
                // jwt 无状态不需要 session
                .sessionManagement()
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
                .headers()
                .cacheControl()
                .disable()
            .and()
                .rememberMe()
            .disable()
            // 自定义 Jwt 登录认证 Filter
            .addFilterAt(jsonUsernamePasswordAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class)
            // 自定义 Jwt 过滤器
            .addFilterBefore(new JwtAuthenticationFilter(authenticationManagerBean()), JsonUsernamePasswordAuthenticationFilter.class);
    }

    /**
     * 加密方式
     */
    @Bean
    public BCryptPasswordEncoder bCryptPasswordEncoder(){
        return new BCryptPasswordEncoder();
    }

    /**
     * 自定义登录拦截器, 接收 json 登录信息
     */
    @Bean
    public JsonUsernamePasswordAuthenticationFilter jsonUsernamePasswordAuthenticationFilter() throws Exception {
        JsonUsernamePasswordAuthenticationFilter filter = new JsonUsernamePasswordAuthenticationFilter();
        filter.setFilterProcessesUrl("/user/login");
        filter.setAuthenticationSuccessHandler(userLoginSuccessHandler);
        filter.setAuthenticationFailureHandler(userLoginFailHandler);
        filter.setAuthenticationManager(authenticationManagerBean());
        return filter;
    }

    /**
     * 注入自定义 PermissionEvaluator
     */
    @Bean
    public DefaultWebSecurityExpressionHandler userSecurityExpressionHandler(){
        DefaultWebSecurityExpressionHandler handler = new DefaultWebSecurityExpressionHandler();
        handler.setPermissionEvaluator(permissionEvaluator);
        return handler;
    }

    /**
     * 跨域配置
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowCredentials(true);
        configuration.setAllowedOrigins(singletonList("*"));
        configuration.setAllowedMethods(singletonList("*"));
        configuration.setAllowedHeaders(singletonList("*"));
        configuration.setMaxAge(Duration.ofHours(1));
        source.registerCorsConfiguration("/**",configuration);
        return source;
    }

    /**
     * 共享 AuthenticationManager
     */
    @Bean
    @Override
    public AuthenticationManager authenticationManagerBean() throws Exception {
        return super.authenticationManagerBean();
    }
}
```

更多源码查看: ***[https://github.com/masteranthoneyd/spring-boot-learning/tree/master/spring-boot-security](https://github.com/masteranthoneyd/spring-boot-learning/tree/master/spring-boot-security)***

### 其他配置说明

#### session

> 上面的配置是基于 jwt 无状态的, 所以不需要 session, 如果使用, 可以通过下面配置实现一些额外的功能

```java
   http.sessionManagement()
        // 登陆后使用新的 sessionId, 防止固定会话攻击
    .sessionFixation().changeSessionId()
     // 同时在线最大数量
    .maximumSessions(1)
     // 是否禁止新的登录
    .maxSessionsPreventsLogin(false)
```

> 如果是自定义的用户, **需要重写 `equals` 以及 `hashcode` 方法**, 因为底层是通过一个 Map 存放 session 相关信息, 而 key 则是 principal 对象.
>
> 如果是覆盖了 `UsernamePasswordAuthenticationFilter`, 这些 session 配置需要在自定义的 Filter 重新配置.

同时启用 session 提供一个 bean(因为 Spring security 的通过监听事件实现 session 销毁的):

```java
@Bean
HttpSessionEventPublisher httpSessionEventPublisher() {
    return new HttpSessionEventPublisher();
}
```

session 集群共享:

第一步, 引入 redis:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.session</groupId>
    <artifactId>spring-session-data-redis</artifactId>
</dependency>
```

第二部, 配置 SessionRegistry:

```java
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    @Autowired
    FindByIndexNameSessionRepository sessionRepository;
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.authorizeRequests().anyRequest()
                ...
                .sessionManagement()
                .maximumSessions(1)
                .maxSessionsPreventsLogin(true)
                .sessionRegistry(sessionRegistry());
    }
    @Bean
    SpringSessionBackedSessionRegistry sessionRegistry() {
        return new SpringSessionBackedSessionRegistry(sessionRepository);
    }
}
```

## 基于 Spring Mvc 拦截器

如果觉得 Spring Security 太重, 可以基于拦截器实现一个比较轻量级的校验, 核心思路就是在拦截器中校验 token:

```java
public class AuthorizationInterceptor extends HandlerInterceptorAdapter {

	private AuthorizationPreHandler authorizationPreHandler;

	public AuthorizationInterceptor(AuthorizationPreHandler authorizationPreHandler) {
		this.authorizationPreHandler = authorizationPreHandler;
	}

	@Override
	public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
		if (handler instanceof HandlerMethod) {
			Method method = ((HandlerMethod) handler).getMethod();
			if (method.isAnnotationPresent(IgnoreAuth.class)) {
				return true;
			}
			authorizationPreHandler.preHandleAuth(request, response, method);
		}
		return true;
	}

}
```

这种实现可以更加灵活定义自己的权限逻辑.

完整代码请看: ***[https://github.com/masteranthoneyd/alchemist/tree/master/auth](https://github.com/masteranthoneyd/alchemist/tree/master/auth)***

## 权限设计

主要核心逻辑还是 `用户-角色-权限`.

在这基础上拓展出 `用户-用户组-角色` 以及 `权限-类型-具体权限`.

![](https://cdn.yangbingdong.com/img/spring-auth/auth-design.jpg)



