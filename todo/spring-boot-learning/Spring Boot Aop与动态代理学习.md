# Spring Boot Aop与动态代理学习

# Spring Boot Aop

 **注意**：使用Spring Aop必须**满足以下两个条件**

* 需要是spring管理的`bean`对象
* 方法非`static`,`private`

**其他**：

* `@EnableAspectJAutoProxy`默认自动开启的，无需添加额外操作，如果类实现了接口会默认使用JDK动态代理
* 使用cglib：`spring.aop.proxy-target-class=true`(在2.0以上版本这个默认就是`true`)
* 拦截对象内部调用的方法需要添加在`Aspect`类添加`@EnableAspectJAutoProxy(exposeProxy = true)`

### 示例1,简单应用

1、添加依赖

```
	<dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-aop</artifactId>
    </dependency>
```

2、编写拦截规则的注解

```
@Target({ ElementType.PARAMETER, ElementType.METHOD })
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Action {

    String value() default "";
}
```

3、在控制器的方法上使用注解@Action

```
@RestController
public class HelloController {

    @RequestMapping("/")
    @Action("hello")
    public String hello() {
        return "Hello Spring Boot";
    }
}
```

4、编写切面

```
@Aspect
@Component
public class LogAspect {

    // pointCut
    @Pointcut("@annotation(org.light4j.springboot.aop.annotation.Action)")
    public void log() {

    }

    /**
     * 前置通知
     */
    @Before("log()")
    public void doBeforeController(JoinPoint joinPoint) {
        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        Method method = signature.getMethod();
        Action action = method.getAnnotation(Action.class);
        System.out.println("action名称 " + action.value()); // ⑤
    }

    /**
     * 后置通知
     */
    @AfterReturning(pointcut = "log()", returning = "retValue")
    public void doAfterController(JoinPoint joinPoint, Object retValue) {
        System.out.println("retValue is:" + retValue);
    }
}
```

> ①通过`@Aspect`注解声明该类是一个切面。
> ②通过`@Component`让此切面成为`Spring`容器管理的`Bean`。
> ③通过`@Pointcut`注解声明切面。
> ④通过`@After`注解声明一个建言，并使用`@Pointcut`定义的切点。
> ⑤通过反射可以获得注解上面的属性，然后做日志记录相关的操作，下面的相同。
> ⑥通过`@Before`注解声明一个建言，此建言直接使用拦截规则作为参数。

然后运行项目可以看到控制台打出的日志

### 实例2,注入自定义log

1、定义注解

```
@Retention(RUNTIME)
@Target(FIELD)
@Documented
@Inherited
public @interface Log {

}
```

2、编写切面

```
@Component
@Aspect
public class LogInjector implements BeanPostProcessor {

    public Object postProcessAfterInitialization(Object bean, String beanName)
            throws BeansException {
        return bean;
    }

    public Object postProcessBeforeInitialization(final Object bean,String beanName) throws BeansException {
        ReflectionUtils.doWithFields(bean.getClass(), new FieldCallback() {
            public void doWith(Field field) throws IllegalArgumentException,
                    IllegalAccessException {
                // System.out.println("Logger Inject into :" + bean.getClass());
                // make the field accessible if defined private
                ReflectionUtils.makeAccessible(field);
                if (field.getAnnotation(Log.class) != null) {
                    Logger log = Logger.getLogger(bean.getClass());
                    field.set(bean, log);
                }
            }
        });
        return bean;
    }
}
```

3、启动测试类

```
@SpringBootApplication
public class AnnotationApplication implements CommandLineRunner{
    @Log
    private Logger log;

    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(AnnotationApplication.class);
        app.setAdditionalProfiles("log");
        app.run(args);
    }

    @Override
    public void run(String... args) throws Exception {
        System.out.println("log : " + log);
        log.info("log 注解注入成功. log：" + log);
    }
}
```

输出结果

```
log : org.apache.log4j.Logger@24d31b86
2017-03-19 19:44:34.576  INFO 7688 --- [  restartedMain] ication$$EnhancerBySpringCGLIB$$52ae5e8e : log 注解注入成功. log：org.apache.log4j.Logger@24d31b86
```

# 动态代理

## Cglib

> CGLIB (Code Generation Library) 底层基于 [ASM](http://baike.baidu.com/subview/98042/8756650.htm#viewPageContent) 字节码处理框架, 能够在运行时生成新的java字节码，因此在动态代理方面使用广泛。相对于 `JDK 原生动态代理`, 它无需依赖接口，能够对任意类生成代理对象。

他的原理是对指定的目标类生成一个子类，并覆盖其中方法实现增强，**但因为采用的是继承，所以不能对final修饰的类进行代理**。 

Cglib一般套路如下：

```
Enhancer enhancer = new Enhancer();                     // 创建增强器
enhancer.setSuperclass(businessObject.getClass());      // 设置被代理类
enhancer.setCallback(callBackLogic);                    // 设置代理逻辑
Business businessProxy = (Business)enhancer.create();   // 创建代理对象
          
businessProxy.doBusiness();                             // 业务调用
```

**CallBack** 子接口展示:

![](http://ojoba1c98.bkt.clouddn.com/img/spring-aop-and-dynamic-proxy/cglib-callback.png)

添加依赖：

```
<dependency>
  <groupId>cglib</groupId>
  <artifactId>cglib</artifactId>
  <version>3.2.5</version>
</dependency>
```



### MethodInterceptor

```
public class EmptyElementFilterCglibProxyFactory {
	public static <T> T createEmptyElementFilterCglibProxy(Class<T> clazz) {
		Enhancer enhancer = new Enhancer();
		enhancer.setSuperclass(clazz);
		enhancer.setCallback(new Callback());
		return clazz.cast(enhancer.create());
	}

	private static class Callback implements MethodInterceptor {
		@Override
		public Object intercept(Object obj, Method method, Object[] args, MethodProxy proxy) throws Throwable {
			if (method.isAnnotationPresent(EmptyElementFilter.class)) {
				args = Optional.ofNullable(args)
							   .filter(a -> a.length == 1)
							   .map(a -> a[0])
							   .filter(a -> a instanceof String && !"".equals(a))
							   .map(a -> new Object[]{filterSplitEmptyElement((String) a, method.getAnnotation(EmptyElementFilter.class).value())})
							   .orElse(args);
			}
			return proxy.invokeSuper(obj, args);
		}
	}

}
```

```
@EqualsAndHashCode(callSuper = false)
@Builder
@Data
@Accessors(chain = true)
@NoArgsConstructor
@AllArgsConstructor
public class SpuVo extends BaseVo {
	@Setter(onMethod = @__({@EmptyElementFilter}))
	private String keyWords;

	@Setter(onMethod = @__({@EmptyElementFilter}))
	private String album;

}
```

```
public class BaseVo {

	private Map<String, Object> paramMap = new HashMap<>();

	public void putParamBySimpleName(Object v) {
		this.paramMap.put(v.getClass().getSimpleName(), v);
	}

	public void putParamByKey(String k, Object v) {
		this.paramMap.put(k, v);
	}

	public <T> T getParamBySimpleName(Class<T> clazz) {
		return clazz.cast(paramMap.get(clazz.getSimpleName()));
	}

	public <T> T getParamByKey(String k, Class<T> clazz) {
		return clazz.cast(paramMap.get(k));
	}

	/**
	 * 通过Cglib创建代理，运行时过滤分隔符字符串的空元素
	 * @param clazz
	 * @param <T>
	 * @return
	 */
	public <T> T emptyElementFilterCglibProxy(Class<T> clazz) {
		T proxy = createEmptyElementFilterCglibProxy(clazz);
		copyPropertiesIgnoreNull(this, proxy);
		return proxy;
	}
}
```


```
@Target({ ElementType.FIELD, ElementType.METHOD })
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface EmptyElementFilter {
	/**
	 * 指定分隔符
	 * @return
	 */
	String value() default COMMA;
}
```

main方法：

```
public static void main(String[] args) {
		SpuVo spuVo = SpuVo.builder()
						   .keyWords(",,a,,b,,v,,,")
						   .build()
						   .emptyElementFilterCglibProxy(SpuVo.class);
		System.out.println(spuVo.getKeyWords());
	}
```

输出结果为：

```
a,b,v
```
















