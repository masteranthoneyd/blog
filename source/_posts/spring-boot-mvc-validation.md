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

![](https://cdn.yangbingdong.com/img/spring-boot-learning/spring-mvc-process.jpg)

1、  用户发送请求至前端控制器`DispatcherServlet`。

2、  `DispatcherServlet`收到请求调用`HandlerMapping`处理器映射器。

3、  处理器映射器找到具体的处理器(可以根据xml配置、注解进行查找)，生成处理器对象及处理器拦截器(如果有则生成)一并返回给`DispatcherServlet`。

4、  `DispatcherServlet`调用`HandlerAdapter`处理器适配器。

5、  `HandlerAdapter`经过适配调用具体的处理器(`Controller`，也叫后端控制器)。

6、  `Controller`执行完成返回`ModelAndView`。

7、  `HandlerAdapter`将`controller`执行结果`ModelAndView`返回给`DispatcherServlet`。

8、  `DispatcherServlet`将`ModelAndView`传给`ViewReslover`视图解析器。

9、  `ViewReslover`解析后返回具体`View`。

10、`DispatcherServlet`根据`View`进行渲染视图（即将模型数据填充至视图中）。

11、 `DispatcherServlet`响应用户。

## Spring MVC集成fastjson

> ***[https://github.com/alibaba/fastjson/wiki/%E5%9C%A8-Spring-%E4%B8%AD%E9%9B%86%E6%88%90-Fastjson](https://github.com/alibaba/fastjson/wiki/%E5%9C%A8-Spring-%E4%B8%AD%E9%9B%86%E6%88%90-Fastjson)***

```
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>fastjson</artifactId>
    <version>1.2.46</version>
</dependency>
```

两种方式：

### 方式一、实现`WebMvcConfigurer`

```
@Configuration
public class WebMvcMessageConvertConfig implements WebMvcConfigurer {
	@Override
	public void configureMessageConverters(List<HttpMessageConverter<?>> converters) {
		FastJsonHttpMessageConverter fastConverter = new FastJsonHttpMessageConverter();

		SerializeConfig serializeConfig = SerializeConfig.globalInstance;
		serializeConfig.put(BigInteger.class, ToStringSerializer.instance);
		serializeConfig.put(Long.class, ToStringSerializer.instance);
		serializeConfig.put(Long.TYPE, ToStringSerializer.instance);

		FastJsonConfig fastJsonConfig = new FastJsonConfig();
		fastJsonConfig.setCharset(Charset.forName("UTF-8"));
		fastJsonConfig.setSerializeConfig(serializeConfig);
		fastJsonConfig.setSerializerFeatures(SerializerFeature.PrettyFormat);
		fastJsonConfig.setDateFormat("yyyy-MM-dd HH:mm:ss");

		fastConverter.setFastJsonConfig(fastJsonConfig);

		converters.add(fastConverter);
	}
}
```

### 方式二、通过`@Bean`方式

```
@Configuration
public class WebMvcMessageConvertConfig {
	@Bean
	public HttpMessageConverters fastJsonHttpMessageConverter() {
		FastJsonHttpMessageConverter fastConverter = new FastJsonHttpMessageConverter();

		SerializeConfig serializeConfig = SerializeConfig.globalInstance;
		serializeConfig.put(BigInteger.class, ToStringSerializer.instance);
		serializeConfig.put(Long.class, ToStringSerializer.instance);
		serializeConfig.put(Long.TYPE, ToStringSerializer.instance);

		FastJsonConfig fastJsonConfig = new FastJsonConfig();
		fastJsonConfig.setCharset(Charset.forName(Constant.CHARSET));
		fastJsonConfig.setSerializeConfig(serializeConfig);
		fastJsonConfig.setSerializerFeatures(SerializerFeature.PrettyFormat);
		fastJsonConfig.setDateFormat(Constant.DATE_FORMAT);

		fastConverter.setFastJsonConfig(fastJsonConfig);
		return new HttpMessageConverters((HttpMessageConverter<?>) fastConverter);
	}
}
```

### WebFlux

上面针对的是Web MVC，**对于Webflux目前不支持这种方式**.

## Spring Boot JSON （Date类型入参、格式化，以及如何处理null）

```
spring:
  jackson:
    default-property-inclusion: non_null # 忽略 json 中值为null的属性
    date-format: "yyyy-MM-dd HH:mm:ss" # 设置 pattern
    time-zone: GMT+8 # 修正时区
```

* 时间格式可以在实体上使用该注解：`@JsonFormat(timezone = "GMT+8",pattern = "yyyy-MM-dd")`
* 忽略null属性可以在实体上使用：`@JsonInclude(JsonInclude.Include.NON_NULL)`

## Spring Boot MVC特性

Spring boot 在spring默认基础上，自动配置添加了以下特性

- 包含了`ContentNegotiatingViewResolver`和`BeanNameViewResolver` beans。
- 对静态资源的支持，包括对WebJars的支持。
- 自动注册`Converter`，`GenericConverter`，`Formatter` beans。
- 对`HttpMessageConverters`的支持。
- 自动注册`MessageCodeResolver`。
- 对静态`index.html`的支持。
- 对自定义`Favicon`的支持。
- 主动使用`ConfigurableWebBindingInitializer` bean

## @RequestBody与@ModelAttribute

`@RequestBody`：用于接收http请求中body的字符串信息，可在直接接收转换到Pojo。

`@ModelAttribute`：用于直接接受`url?`后面的参数 如`url?id=123&name=456`，可在直接接收转换到Pojo。

## 模板引擎的选择

- `FreeMarker`
- `Thymeleaf`
- `Velocity` (1.4版本之后弃用，Spring Framework 4.3版本之后弃用)
- `Groovy`
- `Mustache`

注：**jsp应该尽量避免使用**，原因如下：

- jsp只能打包为：war格式，**不支持jar格式**，只能在标准的容器里面跑（tomcat，jetty都可以）
- 内嵌的Jetty目前不支持JSP
- Undertow不支持jsp
- jsp自定义错误页面不能覆盖spring boot 默认的错误页面

## 开启GZIP算法压缩响应流

```
server:
  compression:
    enabled: true # 启用压缩
    min-response-size: 2048 # 对应Content-Length，超过这个值才会压缩
```

## 全局异常处理

### 方式一：添加自定义的错误页面

- `html`静态页面：在`resources/public/error/` 下定义. 如添加404页面： `resources/public/error/404.html`页面，中文注意页面编码
- 模板引擎页面：在`templates/error/`下定义. 如添加5xx页面： `templates/error/5xx.ftl`

> 注：`templates/error/` 这个的优先级比较`resources/public/error/`高

### 方式二：通过@ControllerAdvice

```
@Slf4j
@ControllerAdvice
//@RestControllerAdvice
public class ErrorExceptionHandler {

	@ExceptionHandler({ RuntimeException.class })
	@ResponseStatus(HttpStatus.OK)
	public ModelAndView processException(RuntimeException exception) {
		log.info("自定义异常处理-RuntimeException");
		ModelAndView m = new ModelAndView();
		m.addObject("roncooException", exception.getMessage());
		m.setViewName("error/500");
		return m;
	}

	@ExceptionHandler({ Exception.class })
	@ResponseStatus(HttpStatus.OK)
	public ModelAndView processException(Exception exception) {
		log.info("自定义异常处理-Exception");
		ModelAndView m = new ModelAndView();
		m.addObject("roncooException", exception.getMessage());
		m.setViewName("error/500");
		return m;
	}
}
```

或者继承`ResponseEntityExceptionHandler`更灵活地控制状态码、`Header`等信息：

```
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

更多方式请看：***[http://www.baeldung.com/exception-handling-for-rest-with-spring](http://www.baeldung.com/exception-handling-for-rest-with-spring)***

## 静态资源

设置静态资源放到指定路径下

```
spring.resources.static-locations=classpath:/META-INF/resources/,classpath:/static/

```

## 自定义消息转化器

```
	@Bean
    public StringHttpMessageConverter stringHttpMessageConverter() {
        StringHttpMessageConverter converter = new StringHttpMessageConverter(Charset.forName("UTF-8"));
        return converter;
    }

```

## 自定义SpringMVC的拦截器

有些时候我们需要自己配置SpringMVC而不是采用默认，比如增加一个拦截器

```
public class MyInterceptor implements HandlerInterceptor {

    @Override
    public void afterCompletion(HttpServletRequest arg0, HttpServletResponse arg1, Object arg2, Exception arg3)
            throws Exception {
        System.out.println("拦截器MyInterceptor------->3、请求结束之后被调用，主要用于清理工作。");

    }

    @Override
    public void postHandle(HttpServletRequest arg0, HttpServletResponse arg1, Object arg2, ModelAndView arg3)
            throws Exception {
        System.out.println("拦截器MyInterceptor------->2、请求之后调用，在视图渲染之前，也就是Controller方法调用之后");

    }

    @Override
    public boolean preHandle(HttpServletRequest arg0, HttpServletResponse arg1, Object arg2) throws Exception {
        System.out.println("拦截器MyInterceptor------->1、请求之前调用，也就是Controller方法调用之前。");
        return true;//返回true则继续向下执行，返回false则取消当前请求
    }

}

```

```
@Configuration
public class InterceptorConfigurerAdapter extends WebMvcConfigurer {
    /**
     * 该方法用于注册拦截器
     * 可注册多个拦截器，多个拦截器组成一个拦截器链
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

或者可以使用继承`HandlerInterceptorAdapter`的方式，这种方式可以**按需覆盖父类方法**。

## 创建 Servlet、 Filter、Listener

### 注解方式

> 直接通过`@WebServlet`、`@WebFilter`、`@WebListener` 注解自动注册

```
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

然后需要在`**Application.java` 加上`@ServletComponentScan`注解，否则不会生效。

**注意：如果同时添加了`@WebFilter`以及`@Component`，那么会初始化两次Filter，并且会过滤所有路径+自己指定的路径 ，便会出现对没有指定的URL也会进行过滤**

### 通过编码注册

```
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
        urlMappings.add("/myServlet");////访问，可以添加多个
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

- `Filter`是基于函数回调的，而`Interceptor`则是基于Java反射的。
- `Filter`依赖于Servlet容器，而`Interceptor`不依赖于Servlet容器。
- `Filter`对几乎所有的请求起作用，而`Interceptor`只能对`action`请求起作用。
- `Interceptor`可以访问`Action`的上下文，值栈里的对象，而`Filter`不能。
- 在`action`的生命周期里，`Interceptor`可以被多次调用，而Filter只能在容器初始化时调用一次。

![](https://cdn.yangbingdong.com/img/spring-boot-learning/mvc-process.png)

## RequestBodyAdvice和ResponseBodyAdvice

### 应用场景

* 对Request请求参数解密，对Response返回参数进行加密
* 自定义返回信息（业务无关性的）

### 使用

先看一下`ResponseBodyAdvice`

```
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

其中`supports`方法指定是否需要执行`beforeBodyWrite`，其中参数`returnType`可以拿到Controller对应方法中的方法注解以及参数注解：`returnType.getMethodAnnotation(XXXAnnotation.class)`、`returnType.getParameterAnnotation(XXXAnnotation.class)`。

`beforeBodyWrite`可以对返回的body进行包装或加密：

```
@RestControllerAdvice(annotations = Rest.class)
public class GlobalControllerAdvisor implements ResponseBodyAdvice {
	private static final String VOID = "void";
	private static final String RESOURCE_NOT_FOUND = "Resource not found!";
	private static final String SUCCESS = "SUCCESS";
	
	@Override
	public boolean supports(MethodParameter returnType, Class converterType) {
		return Boolean.TRUE;
	}

	@Override
	public Object beforeBodyWrite(Object body, MethodParameter returnType, MediaType selectedContentType, Class selectedConverterType, ServerHttpRequest request, ServerHttpResponse response) {
		Object result;
		if (isVoidMethod(returnType)) {
			result = genSuccessResult(null, SUCCESS);
		} else if (body instanceof Result) {
			result = body;
		} else if (nonNull(body)) {
			result = genSuccessResult(body);
		} else {
			result = genBadReqResult(NOT_FOUND, RESOURCE_NOT_FOUND);
		}
		return result;
	}

	private boolean isVoidMethod(MethodParameter returnType) {
		return VOID.equals(returnType.getMethod().getReturnType().getName());
	}
}
```

* 需要在类上面添加`@ControllerAdvice`或`@RestControllerAdvice`才能生效

>  `RequestBodyAdvice`的`beforeBodyRead`在拦截器之后执行，所以可以在拦截器做签名检验，然后在`RequestBodyAdvice`中解密请求参数

## Spring Boot和Feign中使用Java 8时间日期API（LocalDate等）的序列化问题

***[http://blog.didispace.com/Spring-Boot-And-Feign-Use-localdate/](http://blog.didispace.com/Spring-Boot-And-Feign-Use-localdate/)***

# Validation

## 常用注解（大部分**JSR**中已有）

| 注解                                           | 类型                                                         | 说明                                                         |
| ---------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `@AssertFalse`                                 | Boolean,boolean                                              | 验证注解的元素值是false                                      |
| `@AssertTrue`                                  | Boolean,boolean                                              | 验证注解的元素值是true                                       |
| `@NotNull`                                     | 任意类型                                                     | 验证注解的元素值不是null                                     |
| `@Null`                                        | 任意类型                                                     | 验证注解的元素值是null                                       |
| `@Min(value=值)`                               | BigDecimal，BigInteger, byte,short, int, long，等任何Number或CharSequence（存储的是数字）子类型 | 验证注解的元素值大于等于@Min指定的value值                    |
| `@Max（value=值）`                             | 和@Min要求一样                                               | 验证注解的元素值小于等于@Max指定的value值                    |
| `@DecimalMin(value=值)`                        | 和@Min要求一样                                               | 验证注解的元素值大于等于@ DecimalMin指定的value值            |
| `@DecimalMax(value=值)`                        | 和@Min要求一样                                               | 验证注解的元素值小于等于@ DecimalMax指定的value值            |
| `@Digits(integer=整数位数, fraction=小数位数)` | 和@Min要求一样                                               | 验证注解的元素值的整数位数和小数位数上限                     |
| `@Size(min=下限, max=上限)`                    | 字符串、Collection、Map、数组等                              | 验证注解的元素值的在min和max（包含）指定区间之内，如字符长度、集合大小 |
| `@Past`                                        | java.util.Date,java.util.Calendar;Joda Time类库的日期类型    | 验证注解的元素值（日期类型）比当前时间早                     |
| `@Future`                                      | 与@Past要求一样                                              | 验证注解的元素值（日期类型）比当前时间晚                     |
| `@NotBlank`                                    | CharSequence子类型                                           | 验证注解的元素值不为空（不为null、去除首位空格后长度为0），不同于@NotEmpty，@NotBlank只应用于字符串且在比较时会去除字符串的首位空格 |
| `@Length(min=下限, max=上限)`                  | CharSequence子类型                                           | 验证注解的元素值长度在min和max区间内                         |
| `@NotEmpty`                                    | CharSequence子类型、Collection、Map、数组                    | 验证注解的元素值不为null且不为空（字符串长度不为0、集合大小不为0） |
| `@Range(min=最小值, max=最大值)`               | BigDecimal,BigInteger,CharSequence, byte, short, int, long等原子类型和包装类型 | 验证注解的元素值在最小值和最大值之间                         |
| `@Email(regexp=正则表达式,flag=标志的模式)`    | CharSequence子类型（如String）                               | 验证注解的元素值是Email，也可以通过regexp和flag指定自定义的email格式 |
| `@Pattern(regexp=正则表达式,flag=标志的模式)`  | String，任何CharSequence的子类型                             | 验证注解的元素值与指定的正则表达式匹配                       |
| `@Valid`                                       | 任何非原子类型                                               | 指定递归验证关联的对象；如用户对象中有个地址对象属性，如果想在验证用户对象时一起验证地址对象的话，在地址对象上加@Valid注解即可级联验证 |

## 简单使用

实体：

```
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

```
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

一般情况下，Validator并不会应为第一个校验失败为停止，而是一直校验完所有参数。我们可以通过设置快速失效：

```
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

这样在遇到第一个校验失败的时候就会停止对之后的参数校验。

## 分组校验

> 如果同一个类，在不同的使用场景下有不同的校验规则，那么可以使用分组校验。未成年人是不能喝酒的，而在其他场景下我们不做特殊的限制，这个需求如何体现同一个实体，不同的校验规则呢？

添加分组：

```
Class Foo{
	@Min(value = 18,groups = {Adult.class})
	private Integer age;
	
	public interface Adult{}
	
	public interface Minor{}
}


```

`Controller`：

```
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

业务需求总是比框架提供的这些简单校验要复杂的多，我们可以自定义校验来满足我们的需求。自定义spring validation非常简单，主要分为两步。

1 自定义校验注解
我们尝试添加一个“字符串不能包含空格”的限制。

```
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

我们不需要关注太多东西，使用spring validation的原则便是便捷我们的开发，例如payload，List ，groups，都可以忽略。

`<1>` 自定义注解中指定了这个注解真正的验证者类。

2 编写真正的校验者类

```
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

`<1>` 所有的验证者都需要实现`ConstraintValidator`接口，它的接口也很形象，包含一个初始化事件方法，和一个判断是否合法的方法

```
public interface ConstraintValidator<A extends Annotation, T> {
	void initialize(A constraintAnnotation);
		boolean isValid(T value, ConstraintValidatorContext context);
}


```

`<2> ` `ConstraintValidatorContext` 这个上下文包含了认证中所有的信息，我们可以利用这个上下文实现获取默认错误提示信息，禁用错误提示信息，改写错误提示信息等操作。

`<3>` 一些典型校验操作，或许可以对你产生启示作用。

值得注意的一点是，自定义注解可以用在`METHOD, FIELD, ANNOTATION_TYPE, CONSTRUCTOR, PARAMETER`之上，`ConstraintValidator`的第二个泛型参数T，是需要被校验的类型。

## 手动校验

可能在某些场景下需要我们手动校验，即使用校验器对需要被校验的实体发起validate，同步获得校验结果。理论上我们既可以使用Hibernate Validation提供Validator，也可以使用Spring对其的封装。在spring构建的项目中，提倡使用经过spring封装过后的方法，这里两种方法都介绍下：

**Hibernate Validation**：

```
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

由于依赖了Hibernate Validation框架，我们需要调用Hibernate相关的工厂方法来获取validator实例，从而校验。

在spring framework文档的Validation相关章节，可以看到如下的描述：

> Spring provides full support for the Bean Validation API. This includes convenient support for bootstrapping a JSR-303/JSR-349 Bean Validation provider as a Spring bean. This allows for a javax.validation.ValidatorFactory or javax.validation.Validator to be injected wherever validation is needed in your application. Use the LocalValidatorFactoryBean to configure a default Validator as a Spring bean:

> bean id=”validator” class=”org.springframework.validation.beanvalidation.LocalValidatorFactoryBean”

> The basic configuration above will trigger Bean Validation to initialize using its default bootstrap mechanism. A JSR-303/JSR-349 provider, such as Hibernate Validator, is expected to be present in the classpath and will be detected automatically.

上面这段话主要描述了spring对validation全面支持JSR-303、JSR-349的标准，并且封装了`LocalValidatorFactoryBean`作为validator的实现。值得一提的是，这个类的责任其实是非常重大的，他兼容了spring的validation体系和hibernate的validation体系，也可以被开发者直接调用，代替上述的从工厂方法中获取的hibernate validator。由于我们使用了springboot，会触发web模块的自动配置，`LocalValidatorFactoryBean`已经成为了Validator的默认实现，使用时只需要自动注入即可。

```
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

`<1>` 真正使用过`Validator`接口的读者会发现有两个接口，一个是位于`javax.validation`包下，另一个位于`org.springframework.validation`包下，**注意我们这里使用的是前者**`javax.validation`，后者是spring自己内置的校验接口，`LocalValidatorFactoryBean`同时实现了这两个接口。

`<2>` 此处校验接口最终的实现类便是`LocalValidatorFactoryBean`。

## 基于方法校验

```
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

`<4>` 添加一个异常处理器，可以获得没有通过校验的属性相关信息

基于方法的校验，个人不推荐使用，感觉和项目结合的不是很好。

## 统一处理验证异常

```
@ControllerAdvice
@Component
public class GlobalExceptionHandler {

    @ExceptionHandler
    @ResponseBody
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public String handle(ValidationException exception) {
        if(exception instanceof ConstraintViolationException){
            ConstraintViolationException exs = (ConstraintViolationException) exception;

            Set<ConstraintViolation<?>> violations = exs.getConstraintViolations();
            for (ConstraintViolation<?> item : violations) {
　　　　　　　　　　/**打印验证不通过的信息*/
                System.out.println(item.getMessage());
            }
        }
        return "bad request, " ;
    }
}

```

> 参考：
> *[https://www.cnkirito.moe/2017/08/16/%E4%BD%BF%E7%94%A8spring%20validation%E5%AE%8C%E6%88%90%E6%95%B0%E6%8D%AE%E5%90%8E%E7%AB%AF%E6%A0%A1%E9%AA%8C/](https://www.cnkirito.moe/2017/08/16/%E4%BD%BF%E7%94%A8spring%20validation%E5%AE%8C%E6%88%90%E6%95%B0%E6%8D%AE%E5%90%8E%E7%AB%AF%E6%A0%A1%E9%AA%8C/)*
