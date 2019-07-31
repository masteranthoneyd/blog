# Spring Boot + JWT 实现简单的登录鉴权

> ***[JWT](https://github.com/jwtk/jjwt#compression)*** 是什么就不说了, 下面利用JWT实现简单的无状态RestFul认证

工具类:

```java
public class JwtUtils {

	private static final String TOKEN_PREFIX = "Bearer ";
	private static final String PRIVATE_KEY = "scec6faa-ad93-45f7-ac8e-1feb148dce92";
	private static final int TOKEN_PREFIX_LENGTH = TOKEN_PREFIX.length();
	private static final SignatureAlgorithm SIGNATURE_ALGORITHM = SignatureAlgorithm.HS256;
	private static final Key SECRET_KEY = new SecretKeySpec(PRIVATE_KEY.getBytes(), SIGNATURE_ALGORITHM.getJcaName());
	private static final Serializer<Map<String, ?>> SERIALIZER = new FastJwtSerializer();
	private static final Deserializer<Map<String, ?>> DESERIALIZER = new FastJwtDeserializer();


	private static String genJwt(String sub, long ttlMillis) {
		JwtBuilder jwtBuilder = Jwts.builder()
									.setSubject(sub)
									.serializeToJsonWith(SERIALIZER)
									.signWith(SECRET_KEY, SIGNATURE_ALGORITHM);
		if (ttlMillis > 0) {
			jwtBuilder.setExpiration(new Date(System.currentTimeMillis() + ttlMillis));
		}
		return jwtBuilder.compact();
	}

	public static String genJwtTokenHeader(String sub, long ttlMillis) {
		return TOKEN_PREFIX + genJwt(sub, ttlMillis);
	}

	public static boolean validTokenPrefix(String token) {
		return token.startsWith(TOKEN_PREFIX);
	}

	public static Claims parseJwtBody(String token) {
		try {
			return Jwts.parser()
					   .deserializeJsonWith(DESERIALIZER)
					   .setSigningKey(SECRET_KEY)
					   .setAllowedClockSkewSeconds(10)
					   .parseClaimsJws(token.substring(TOKEN_PREFIX_LENGTH))
					   .getBody();
		} catch (ExpiredJwtException e) {
			throw new TokenException("Token已过期");
		} catch (UnsupportedJwtException e) {
			throw new TokenException("Token格式错误");
		} catch (MalformedJwtException e) {
			throw new TokenException("Token没有被正确构造");
		} catch (SignatureException e) {
			throw new TokenException("Token签名失败");
		} catch (IllegalArgumentException e) {
			throw new TokenException("非法参数");
		}
	}

}
```

```java
public class FastJwtSerializer implements Serializer<Map<String,?>> {
	@Override
	public byte[] serialize(Map<String, ?> stringMap) throws SerializationException {
		return JSONObject.toJSONBytes(stringMap);
	}
}
```

```java
public class FastJwtDeserializer implements Deserializer<Map<String,?>> {
	@SuppressWarnings("unchecked")
	@Override
	public Map<String, ?> deserialize(byte[] bytes) throws DeserializationException {
		return (Map<String, ?>) JSONObject.parse(bytes);
	}
}
```

使用Spring拦截器进行请求拦截:

```java
@Component
public class AuthorizationInterceptor extends HandlerInterceptorAdapter {

	@Autowired
	private UserService userService;

	@Override
	public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
		if (handler instanceof HandlerMethod) {
			HandlerMethod handlerMethod = (HandlerMethod) handler;
			if (handlerMethod.getMethod().isAnnotationPresent(PassTokenVerify.class)) {
				return true;
			}
		}
		String authorizationToken = request.getHeader(AUTHORIZATION_HEADER);
		assertTrue(authorizationToken != null, "Token不能为空");
		assertTrue(JwtUtils.validTokenPrefix(authorizationToken), "无效的Token前缀");
		return validatePre(request, response, authorizationToken);
	}

	private boolean validatePre(HttpServletRequest request, HttpServletResponse response, String authorizationToken) {
		Claims claims = JwtUtils.parseJwtBody(authorizationToken);
		UserJwtBody userJwtBody = UserJwtBody.fromJsonString(claims.getSubject());
		Long userId = userJwtBody.getUserId();
		User user = userService.getById(userId);
		assertTrue(user != null, userId + " 用户不存在");

		request.setAttribute(UserConstant.USER, user);
		MDC.put(USER_ACCOUNT, user.getAccount());
		refreshJwtIfProximityTimeout(response, claims);
		return true;
	}

	private void refreshJwtIfProximityTimeout(HttpServletResponse response, Claims claims) {
		long interval = claims.getExpiration().getTime() - System.currentTimeMillis();
		if (interval < REFRESH_INTERVAL) {
			response.setHeader(AUTHORIZATION_HEADER, genJwtTokenHeader(claims.getSubject(), JWT_EXPIRATION));
		}
	}

	private void assertTrue(boolean result, String message) {
		if (!result) {
			throw new TokenException(message);
		}
	}

	@Override
	public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
		MDC.clear();
	}
```

就这么简单!

# 权限设计

![](https://cdn.yangbingdong.com/img/spring-auth/auth-design.jpg)