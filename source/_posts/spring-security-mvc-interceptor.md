---
title: Spring Security 与 HandlerInterceptor 的认证鉴权
date: 2020-05-26 16:30:58
categories: [Programming, Java, Spring Boot]
tags: [Java, Spring Boot, Spring, Spring Security]
---

![](https://oldcdn.yangbingdong.com/img/spring-boot-security/spring-authentication-banner.png)

# Preface

> 本篇总结分别基于 Spring Security 与 Spring MVC HandlerInterceptor 实现认证鉴权.

<!--more-->

# Spring Security

Spring Security 是基于嵌套 `Filter`(委派 Filter) 实现的, 在 `DispatcherServlet` 之前触发. 普通的 Filter 称之为 Web Filter, 而 Spring Security 的 Filter 称之为 Security Filter:

![](https://oldcdn.yangbingdong.com/img/spring-boot-security/security-filters.png)

默认有哪些 Filter 可以看 `FilterComparator` 中的源码:

![](https://oldcdn.yangbingdong.com/img/spring-boot-security/filter-comparator.png)

## 认证流程

![](https://oldcdn.yangbingdong.com/img/spring-boot-security/core-service-Sequence.png)

### 登录拦截

在 `FilterComparator` 中有一个 `UsernamePasswordAuthenticationFilter`, 继承了 `AbstractAuthenticationProcessingFilter`, 它就是我们登录时用到的 Filter:

![](https://oldcdn.yangbingdong.com/img/spring-boot-security/username-password-authentication-filter.png)

* 可以看到, **默认情况下拦截 `/login` 端点的 POST 请求**, 当然, 可以通过配置改变这个 url.
* 这里还有一个关键, 在 `attempAuthentication` 中, 用户名以及密码的参数是 `username` 以及 `password`, 并且是从 http parameter 中获取的, 如果要**支持 Json 格式的登录, 那就要重写这里**.
* 将登录请求信息封装成 `Authentication` 的实现类, 这里是 `UsernamePasswordAuthenticationToken`, **然后交给 `AuthenticationManager` 进行下一步的认证**. 

> **这一步相当与登录信息的提取以及封装**.

### 认证

认证通过 `AuthenticationManager` 进行的, 这是一个接口, 默认的实现类为 `ProviderManager`:

![](https://oldcdn.yangbingdong.com/img/spring-boot-security/provider-manager.png)

可以看到实现类 `ProviderManager` 中维护了一个 `List<AuthenticationProvider>` 的列表, 存放多种认证方式, 实际上这是委托者模式的应用(Delegate)

> 核心的认证入口始终只有一个: `AuthenticationManager`, 不同的认证方式: 用户名 + 密码(`UsernamePasswordAuthenticationToken`), 邮箱 + 密码, 手机号码 + 密码登录则对应了三个 `AuthenticationProvider`. 在默认策略下, 只需要通过一个 `AuthenticationProvider` 的认证, 即可被认为是登录成功.

![](https://oldcdn.yangbingdong.com/img/spring-boot-security/spring%20security%20architecture.png)

一个最常用到的 `AuthenticationProvider` 实现类就是 `DaoAuthenticationProvider`, 里面比较重要的一个环节就是 `additionalAuthenticationChecks` (密码校验):

*  通过 `UserDetailsService`  的实现类(需要用户自己实现)拿到 `UserDetails`
* 将其中的 `password` 与 `UsernamePasswordAuthenticationToken` 中的 `credentials` 进行对比 

![](https://oldcdn.yangbingdong.com/img/spring-boot-security/dao-authentication-password-check.png)

登录成功后会执行 `AbstractAuthenticationProcessingFilter#successfulAuthentication` 将 `Authentication` 存到 `SecurityContextHolder` 中.

到此, 认证的核心就是这样了.

## 权限校验流程

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

因此如果要**动态鉴权**, 可以从两方面入手:

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

## 核心配置

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

## 其他配置说明

### session

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

## 总结

上面提到的只是一个大致的核心流程, 但大概可以看出来, Spring Security 功能不仅齐全, 而且留了很多的扩展点, 可以很灵活的定制自己的权限业务.

但正是因为其极其丰富的扩展, 使得这框架变得"很重", 对新手来说可能不太友好, 需要一定的学习成本.

# Spring MVC HandlerInterceptor

对于一般简单的登录校验而言, 使用 Spring Security 可能稍显笨重, 这时候可以基于 Spring MVC 的 HandlerInterceptor 实现简单的校验逻辑:

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

将拦截器添加到 MVC 中:

```java
@ConditionalOnBean(AuthorizationPreHandler.class)
public class AuthorizationInterceptorConfiguration {

	@Bean
	public AuthorizationInterceptor authorizationInterceptor(
			ObjectProvider<AuthorizationPreHandler> authorizationHandlerObjectProvider) {
		return new AuthorizationInterceptor(authorizationHandlerObjectProvider.getIfAvailable());
	}

	@Order(1)
	@Bean
	public AuthorizationMvcConfigure authorizationMvcConfigure(
			ObjectProvider<AuthorizationInterceptor> authorizationInterceptorObjectProvider) {
		return new AuthorizationMvcConfigure(authorizationInterceptorObjectProvider.getIfAvailable());
	}
}

@RequiredArgsConstructor
public class AuthorizationMvcConfigure implements WebMvcConfigurer {

	private final AuthorizationInterceptor authorizationInterceptor;

	@Override
	public void addInterceptors(InterceptorRegistry registry) {
		if (Objects.nonNull(authorizationInterceptor)) {
			registry.addInterceptor(authorizationInterceptor);
		}
	}
}
```

`authorizationPreHandler` 中简单校验是否存在 token 即可.

完整代码请看: ***[https://github.com/masteranthoneyd/alchemist/tree/master/auth](https://github.com/masteranthoneyd/alchemist/tree/master/auth)***

# RBAC 权限设计

主要核心逻辑还是 `用户-角色-权限`.

在这基础上拓展出 `用户-用户组-角色` 以及 `权限-类型-具体权限`.

![](https://oldcdn.yangbingdong.com/img/spring-auth/auth-design.jpg)



