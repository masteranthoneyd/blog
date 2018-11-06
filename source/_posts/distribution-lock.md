---
title: 分布式锁的几种实现方式
date: 2018-09-15 17:19:33
categories: [Programming, Java]
tags: [Java, Redis, Zookeeper, Spring Boot, Spring]
---

![](https://cdn.yangbingdong.com/img/distribute-lock/distribute-lock-banner.png)

# Preface

> 在现代互联网，通常都是伴随着分布式、高并发等，在某些业务中例如下订单扣减库存，如果不对库存资源做临界处理，在并发量大的时候会出现库存不准确的情况。在单个服务的情况下可以通过Java自带的一些锁对临界资源进行处理，例如`synchronized`、`Reentrantlock`，甚至是通过无锁技术（比如`RangeBuffer`）都可以实现同一个JVM内的锁。But，在**能够弹性伸缩的分布式环境**下，Java内置的锁显然不能够满足需求，需要借助外部进程实现分布式锁。

<!--more-->

# 几种实现方式

分布式环境下，数据一致性问题一直是一个比较重要的话题，而又不同于单进程的情况。分布式与单机情况下最大的不同在于其不是多线程而是多进程。多线程由于可以共享堆内存，因此可以简单的采取内存作为标记存储位置。而进程之间甚至可能都不在同一台物理机上，因此需要将标记存储在一个所有进程都能看到的地方。

常见的是秒杀场景，订单服务部署了多个实例。如秒杀商品有4个，第一个用户购买3个，第二个用户购买2个，理想状态下第一个用户能购买成功，第二个用户提示购买失败，反之亦可。而实际可能出现的情况是，两个用户都得到库存为4，第一个用户买到了3个，更新库存之前，第二个用户下了2个商品的订单，更新库存为2，导致出错。

在上面的场景中，商品的库存是共享变量，面对高并发情形，需要保证对资源的访问互斥。在单机环境中，Java中其实提供了很多并发处理相关的API，但是这些API在分布式场景中就无能为力了。也就是说单纯的Java API并不能提供分布式锁的能力。分布式系统中，由于分布式系统的分布性，即多线程和多进程并且分布在不同机器中，`synchronized`和`lock`这两种锁将**失去原有锁的效果**，需要我们自己实现分布式锁。

常见的锁方案如下：

- 基于数据库实现分布式锁（基本用来玩的）
- 基于缓存，实现分布式锁，如`Redis`（业界常用方式）
- 基于`Zookeeper`实现分布式锁（性能低）

下面我们简单介绍下这几种锁的实现。

## 基于数据库

> 虽然这种方式基本上**不会被用于生产环境**

基于数据库的锁实现也有两种方式，一是基于数据库表，另一种是基于数据库排他锁。

### 基于数据库表的增删

基于数据库表增删是最简单的方式，首先创建一张锁的表主要包含下列字段：方法名，时间戳等字段。

具体使用的方法，当需要锁住某个方法时，往该表中插入一条相关的记录。这边需要注意，方法名是有唯一性约束的，如果有多个请求同时提交到数据库的话，数据库会保证只有一个操作可以成功，那么我们就可以认为操作成功的那个线程获得了该方法的锁，可以执行方法体内容。

执行完毕，需要`delete`该记录。

当然，这边只是简单介绍一下。对于上述方案可以进行优化，如应用主从数据库，数据之间双向同步。一旦挂掉快速切换到备库上；做一个定时任务，每隔一定时间把数据库中的超时数据清理一遍；使用`while`循环，直到`insert`成功再返回成功，虽然并不推荐这样做；还可以记录当前获得锁的机器的主机信息和线程信息，那么下次再获取锁的时候先查询数据库，如果当前机器的主机信息和线程信息在数据库可以查到的话，直接把锁分配给他就可以了，实现**可重入锁**。

> - **可重入锁**：可以再次进入方法A，就是说在释放锁前此线程可以再次进入方法A（方法A递归）。
> - **不可重入锁（自旋锁）**：不可以再次进入方法A，也就是说获得锁进入方法A是此线程在释放锁钱唯一的一次进入方法A。

### 基于数据库排他锁

我们还可以通过数据库的排他锁来实现分布式锁。基于MySql的InnoDB引擎，可以使用以下方法来实现加锁操作：

```
public void lock(){
    connection.setAutoCommit(false)
    int count = 0;
    while(count < 4){
        try{
            select * from lock where lock_name=xxx for update;
            if(结果不为空){
                //代表获取到锁
                return;
            }
        }catch(Exception e){

        }
        //为空或者抛异常的话都表示没有获取到锁
        sleep(1000);
        count++;
    }
    throw new LockException();
}

```

在查询语句后面增加`for update`，数据库会在查询过程中给数据库表增加排他锁。当某条记录被加上排他锁之后，其他线程无法再在该行记录上增加排他锁。其他没有获取到锁的就会阻塞在上述`select`语句上，可能的结果有2种，在超时之前获取到了锁，在超时之前仍未获取到锁。

获得排它锁的线程即可获得分布式锁，当获取到锁之后，可以执行方法的业务逻辑，执行完方法之后，释放锁`connection.commit()`。

存在的问题主要是性能不高和sql超时的异常。

### 基于数据库锁的优缺点

上面两种方式都是依赖数据库的一张表，一种是通过表中的记录的存在情况确定当前是否有锁存在，另外一种是通过数据库的排他锁来实现分布式锁。

- 优点是直接借助数据库，简单容易理解。
- 缺点是操作数据库需要一定的开销，性能问题需要考虑。

## 基于Zookeeper

基于Zookeeper**临时有序节点**可以实现的分布式锁。每个客户端对某个方法加锁时，在Zookeeper上的与该方法对应的指定节点的目录下，生成一个唯一的瞬时有序节点。 判断是否获取锁的方式很简单，只需要判断有序节点中序号最小的一个。 当释放锁的时候，只需将这个瞬时节点删除即可。同时，其可以避免服务宕机导致的锁无法释放，而产生的死锁问题。

提供的第三方库有[curator](https://curator.apache.org/)，具体使用读者可以自行去看一下。Curator提供的`InterProcessMutex`是分布式锁的实现。`acquire`方法获取锁，release方法释放锁。另外，锁释放、阻塞锁、可重入锁等问题都可以有有效解决。讲下阻塞锁的实现，客户端可以通过在ZK中创建顺序节点，并且在节点上绑定监听器，一旦节点有变化，Zookeeper会通知客户端，客户端可以检查自己创建的节点是不是当前所有节点中序号最小的，如果是就获取到锁，便可以执行业务逻辑。

根据Zookeeper的这些特性，我们来看看如何利用这些特性来实现分布式锁：

- 创建一个锁目录`lock`
- 线程A获取锁会在`lock`目录下，创建临时顺序节点
- 获取锁目录下所有的子节点，然后获取比自己小的兄弟节点，如果不存在，则说明当前线程顺序号最小，获得锁
- 线程B创建临时节点并获取所有兄弟节点，判断自己不是最小节点，**设置监听(`watcher`)比自己次小的节点**
- 线程A处理完，删除自己的节点，线程B监听到变更事件，判断自己是最小的节点，获得锁

最后，Zookeeper实现的分布式锁其实存在一个缺点，那就是**性能上可能并没有缓存服务那么高**。因为每次在创建锁和释放锁的过程中，都要动态创建、销毁瞬时节点来实现锁功能。ZK中创建和删除节点只能通过Leader服务器来执行，然后将数据同不到所有的Follower机器上。并发问题，可能存在网络抖动，客户端和ZK集群的session连接断了，zk集群以为客户端挂了，就会删除临时节点，这时候其他客户端就可以获取到分布式锁了。

下面是简单例子：

```
public class CuratorTest {
	private static String address = "127.0.0.1:2181";


	public static void main(String[] args) {
		RetryPolicy retryPolicy = new ExponentialBackoffRetry(1000, 3);
		CuratorFramework client = CuratorFrameworkFactory.newClient(address, retryPolicy);
		client.start();
		//创建分布式锁, 锁空间的根节点路径为/curator/lock
		InterProcessMutex mutex = new InterProcessMutex(client, "/curator/lock");
		ExecutorService fixedThreadPool = Executors.newFixedThreadPool(5);
		CompletionService<Object> completionService = new ExecutorCompletionService<>(fixedThreadPool);
		for (int i = 0; i < 5; i++) {
			completionService.submit(() -> {
				boolean flag = false;
				try {
					//尝试获取锁，最多等待5秒
					flag = mutex.acquire(5, TimeUnit.SECONDS);
					Thread currentThread = Thread.currentThread();
					if (flag) {
						System.out.println("线程" + currentThread.getId() + "获取锁成功");
					} else {
						System.out.println("线程" + currentThread.getId() + "获取锁失败");
					}
					//模拟业务逻辑，延时4秒
					Thread.sleep(4000);
				} catch (Exception e) {
					e.printStackTrace();
				} finally {
					if (flag) {
						try {
							mutex.release();
						} catch (Exception e) {
							e.printStackTrace();
						}
					}
				}
				return null;
			});
		}
		// 等待线程跑完
		int count = 0;
		while (count < 5) {
			if (completionService.poll() != null) {
				count++;
			}
		}
		System.out.println("=========  Complete!");
		client.close();
		fixedThreadPool.shutdown();
	}
}
```

## 基于缓存

相对于基于数据库实现分布式锁的方案来说，基于缓存来实现在性能方面会表现的更好一点，存取速度快很多。而且很多缓存是可以集群部署的，可以解决单点问题。基于缓存的锁有好几种，如Memcached、Redis，下面主要讲解基于Redis的分布式实现。

# 基于Redis的分布式锁实现

> 首先，为了确保分布式锁可用，我们至少要确保锁的实现同时满足以下四个条件：
>
> 1. **互斥性。**在任意时刻，只有一个客户端能持有锁。
> 2. **不会发生死锁。**即使有一个客户端在持有锁的期间崩溃而没有主动解锁，也能保证后续其他客户端能加锁。
> 3. **具有容错性。**只要大部分的Redis节点正常运行，客户端就可以加锁和解锁。
> 4. **解铃还须系铃人。**加锁和解锁必须是同一个客户端，客户端自己不能把别人加的锁给解了。

## 基于Spring Data Redis

下面是正确的实现姿势。（使用Spring Data Redis）

### 依赖

```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>

<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-pool2</artifactId>
</dependency>
```

### 加锁姿势

```
@Autowired
private StringRedisTemplate stringRedisTemplate;

private Boolean setNxEx(String key, String value) {
	return stringRedisTemplate.execute((RedisCallback<Boolean>) connection -> {
		StringRedisConnection stringRedisConn = (StringRedisConnection) connection;
		return stringRedisConn.set(key, value, Expiration.from(1L, TimeUnit.MINUTES), SET_IF_ABSENT);
	});
}
```

执行上面的`setNxEx()`方法就只会导致两种结果：

1. 当前没有锁（key不存在），那么就进行加锁操作，并对锁设置个有效期，同时value表示加锁的客户端。
2. 已有锁存在，不做任何操作。

网上有许多教程在加锁的步骤都**不是原子性**的，有些是先加锁，成功后再设置过期时间；有些将过期时间设置为value，获取锁失败会判断value是否小于当前时间，是则删除在设置新的值。这些方法由于不是原子性，在极端情况（比如多线程，或者代码执行到某一行就宕机了等等）必然会导致锁失效或死锁等情况...

在上面`stringRedisConn.set(...)`方法中，确保了上锁与设置过期时间的原子性。

### 解锁姿势

配置类：

```
@Bean
public RedisScript<Boolean> releaseLockScript(DLockConfigProperty dLockConfigProperty) {
	DefaultRedisScript<Boolean> redisScript = new DefaultRedisScript<>();
	String scriptLocation = "scripts/release_lock.lua";
	redisScript.setScriptSource(new ResourceScriptSource(new ClassPathResource(scriptLocation)));
	redisScript.setResultType(Boolean.class);
	return redisScript;
}
```

Lua脚本：

```
if redis.call('GET', KEYS[1]) == ARGV[1] then
    return 1 == redis.call('DEL', KEYS[1])
else
    return false
end
```

核心代码：

```
@Resource
private StringRedisTemplate stringRedisTemplate;

@Resource
private RedisScript<Boolean> script;

public void release(String key, String value) {
    stringRedisTemplate.execute(script, singletonList(key), value)
}
```

除了配置，解锁就一行代码搞定，虽然简洁，里面也是有很多学问滴。。。

为什么要用Lua脚本？确保原子性，如何保证，请看官网对`eval`命令的相关解释。上面脚本表达的意思很简单，对比传进来的value是否相等，是则删除锁。value可使用UUID作为当前线程的标识符，**只有但前线程才能解锁**。

网上的错误姿势一般都是执行完业务代码直接删除锁，这样会导致删除了其他线程获的锁。

上面实现的分布式锁是不支持可重入的，需要额外的编码，业界当然早就开源了类似的框架，比如下面介绍的Redisson。

## 基于Redisson

> ***[Redisson](https://github.com/redisson/redisson)*** 是一个在Redis的基础上实现的Java驻内存数据网格（In-Memory Data Grid）。它不仅提供了一系列的分布式的Java常用对象，还提供了许多分布式服务。其中包括(`BitSet`, `Set`, `Multimap`, `SortedSet`, `Map`, `List`, `Queue`, `BlockingQueue`, `Deque`, `BlockingDeque`, `Semaphore`, `Lock`, `AtomicLong`, `CountDownLatch`, `Publish / Subscribe`, `Bloom filter`, `Remote service`, `Spring cache`, `Executor service`, `Live Object service`, `Scheduler service`) Redisson提供了使用Redis的最简单和最便捷的方法。Redisson的宗旨是促进使用者对Redis的关注分离（Separation of Concern），从而让使用者能够将精力更集中地放在处理业务逻辑上。

Redisson提供的众多功能中有一项就是可重入锁（Reentrant Lock），具体用法可参考 ***[文档](https://github.com/redisson/redisson/wiki/8.-%E5%88%86%E5%B8%83%E5%BC%8F%E9%94%81%E5%92%8C%E5%90%8C%E6%AD%A5%E5%99%A8)*** 

### 依赖

```
<dependency>
    <groupId>io.netty</groupId>
    <artifactId>netty-transport-native-epoll</artifactId>
    <classifier>linux-x86_64</classifier>
</dependency>

<dependency>
    <groupId>org.redisson</groupId>
    <artifactId>redisson</artifactId>
    <version>3.7.5</version>
</dependency>
```

### 核心代码

```
@Data
@Slf4j
public class RedissonDLock implements DLock {

	private final Long waitTime;
	private final Long leaseTime;
	private final TimeUnit timeUnit;
	private final RedissonClient redisson;

	public RedissonDLock(DLockConfigProperty property) {
		// 设置一些基本属性
		this.waitTime = property.getWaitTime();
		this.leaseTime = property.getLeaseTime();
		this.timeUnit = property.getTimeUnit();

		Config config = new Config();
		SingleServerConfig singleServerConfig = config.useSingleServer();
		singleServerConfig.setAddress("redis://" + property.getHost() + ":" + property.getPort());
		if (property.getPassword() != null && property.getPassword().trim().length() > 0) {
			singleServerConfig.setPassword(property.getPassword());
		}
		try {
			Class.forName("io.netty.channel.epoll.Epoll");
			// 如果是Linux系统可采用Epoll算法，需要引入 netty-transport-native-epoll
			if (Epoll.isAvailable()) {
				config.setTransportMode(TransportMode.EPOLL);
				log.info("Starting with optional epoll library");
			} else {
				log.info("Starting without optional epoll library");
			}
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		}
		redisson = Redisson.create(config);
	}

	@Override
	public void tryLockAndAction(LockKeyGenerator lockKeyGenerator, AfterAcquireAction acquireAction) {
		tryLockAndAction(lockKeyGenerator, acquireAction, waitTime, leaseTime, timeUnit);
	}

	@Override
	public void tryLockAndAction(LockKeyGenerator lockKeyGenerator, AfterAcquireAction acquireAction, Long waitTime, Long leaseTime, TimeUnit timeUnit) {
		tryLockAndAction(lockKeyGenerator, acquireAction, DEFAULT_FAIL_ACQUIRE_ACTION, waitTime, leaseTime, timeUnit);
	}

	@Override
	public void tryLockAndAction(LockKeyGenerator lockKeyGenerator, AfterAcquireAction acquireAction, FailAcquireAction failAcquireAction, Long waitTime, Long leaseTime, TimeUnit timeUnit) {
		try (LockHolder holder = new LockHolder(redisson.getLock(lockKeyGenerator.getLockKey()))) {
			boolean acquire = holder.getLock().tryLock(waitTime, leaseTime, timeUnit);
			if (acquire) {
				acquireAction.doAction();
			} else {
				failAcquireAction.doOnFail();
			}
		} catch (InterruptedException e) {
			throw new RuntimeException(e);
		}
	}

	@Override
	public <T> T tryLockAndExecuteCommand(LockKeyGenerator lockKeyGenerator, AfterAcquireCommand<T> command, FailAcquireAction failAcquireAction, Long waitTime, Long leaseTime, TimeUnit timeUnit) throws Throwable {
		try (LockHolder holder = new LockHolder(redisson.getLock(lockKeyGenerator.getLockKey()))) {
			boolean acquire = holder.getLock().tryLock(waitTime, leaseTime, timeUnit);
			if (acquire) {
				return command.executeCommand();
			}
			failAcquireAction.doOnFail();
		}
		return null;
	}

	@Data
	@Accessors(chain = true)
	@AllArgsConstructor
	private static class LockHolder implements AutoCloseable {
		private RLock lock;

		@Override
		public void close() {
			lock.unlockAsync();
		}
	}
}
```

* 一般服务器都是Linux系统，引入`io.netty.channel.epoll.Epoll`采用Epoll方式有助于提升性能
* 使用`try-with-resource`方式提高代码优雅性...

### 注解驱动

Lock注解：

```
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
public @interface Lock {

	String namespace() default "default";

	String key();

	Class<?> prefixClass();

	String separator() default ":";

	long waitTime() default 2L;

	long leaseTime() default 5L;

	TimeUnit timeUnit() default TimeUnit.SECONDS;
}
```

切面类：

```
@Slf4j
@Component
@Aspect
@Order(1)
public class DLockAspect {
	@Resource
	private DLock dLock;

	@Value("${spring.application.name}")
	private String namespace;

	@Around(value = "@annotation(lock)")
	public Object doAround(ProceedingJoinPoint pjp, Lock lock) throws Throwable {
		Method method = ((MethodSignature) pjp.getSignature()).getMethod();

		Object[] args = pjp.getArgs();
		String keySpEL = lock.key();
		String resourceKey = parseSpel(method, args, keySpEL, String.class);

		String finalKey = buildFinalKey(lock, resourceKey);
		return dLock.tryLockAndExecuteCommand(() -> finalKey, () -> pjp.proceed(pjp.getArgs()), DEFAULT_FAIL_ACQUIRE_ACTION,
				lock.waitTime(), lock.leaseTime(), lock.timeUnit());
	}

	private String buildFinalKey(Lock lock, String key) {
		return namespace == null || namespace.length() == 0 ? lock.namespace() : namespace +
				lock.separator() +
				lock.prefixClass().getSimpleName() +
				lock.separator() +
				key;
	}
}
```

使用了 ***[SpEL](https://docs.spring.io/spring/docs/current/spring-framework-reference/core.html#expressions)*** 解析锁的Key：

```
public final class SpelHelper {
	private static final ExpressionParser PARSER = new SpelExpressionParser();
	private static final LocalVariableTableParameterNameDiscoverer DISCOVERER = new LocalVariableTableParameterNameDiscoverer();

	public static <T> T parseSpel(Method method, Object[] args, String spel, Class<T> clazz) {
		String[] parameterNames = DISCOVERER.getParameterNames(method);
		requireNonNull(parameterNames);
		EvaluationContext context = buildSpelContext(parameterNames, args);
		Expression expression = PARSER.parseExpression(spel);
		return expression.getValue(context, clazz);
	}

	private static EvaluationContext buildSpelContext(String[] parameterNames, Object[] args) {
		EvaluationContext context = new StandardEvaluationContext();
		for (int len = 0; len < parameterNames.length; len++) {
			context.setVariable(parameterNames[len], args[len]);
		}
		context.setVariable("args", args);
		return context;
	}
}
```

使用：

```
// @Lock(prefixClass = TestService.class, key = "#id")
@Lock(prefixClass = TestService.class, key = "#args[0]")
public void lockTest(Long id) {
	doSomething();
}
```

> 如果锁被早被别的线程使用，一般我们使用线程Sleep的方式等待锁释放，但Redisson的底层采用了更优雅的等待策略，通过发布订阅通知其他线程，所以性能也会有所提高。

# Finally

> Redisson官方文档： ***[https://github.com/redisson/redisson/wiki/%E7%9B%AE%E5%BD%95](https://github.com/redisson/redisson/wiki/%E7%9B%AE%E5%BD%95)***
>
> 示例代码：***[https://github.com/masteranthoneyd/starter/tree/master/dlock](https://github.com/masteranthoneyd/starter/tree/master/dlock)***
