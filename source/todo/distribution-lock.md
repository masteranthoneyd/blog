# 分布式锁

> Raft算法：*[http://thesecretlivesofdata.com/raft/](http://thesecretlivesofdata.com/raft/)*

## 实现

分布式环境下，数据一致性问题一直是一个比较重要的话题，而又不同于单进程的情况。分布式与单机情况下最大的不同在于其不是多线程而是多进程。多线程由于可以共享堆内存，因此可以简单的采取内存作为标记存储位置。而进程之间甚至可能都不在同一台物理机上，因此需要将标记存储在一个所有进程都能看到的地方。

常见的是秒杀场景，订单服务部署了多个实例。如秒杀商品有4个，第一个用户购买3个，第二个用户购买2个，理想状态下第一个用户能购买成功，第二个用户提示购买失败，反之亦可。而实际可能出现的情况是，两个用户都得到库存为4，第一个用户买到了3个，更新库存之前，第二个用户下了2个商品的订单，更新库存为2，导致出错。

在上面的场景中，商品的库存是共享变量，面对高并发情形，需要保证对资源的访问互斥。在单机环境中，Java中其实提供了很多并发处理相关的API，但是这些API在分布式场景中就无能为力了。也就是说单纯的Java Api并不能提供分布式锁的能力。分布式系统中，由于分布式系统的分布性，即多线程和多进程并且分布在不同机器中，synchronized和lock这两种锁将失去原有锁的效果，需要我们自己实现分布式锁。

常见的锁方案如下：

- 基于数据库实现分布式锁
- 基于缓存，实现分布式锁，如redis
- 基于Zookeeper实现分布式锁

下面我们简单介绍下这几种锁的实现。

### 基于数据库

基于数据库的锁实现也有两种方式，一是基于数据库表，另一种是基于数据库排他锁。

#### 基于数据库表的增删

基于数据库表增删是最简单的方式，首先创建一张锁的表主要包含下列字段：方法名，时间戳等字段。

具体使用的方法，当需要锁住某个方法时，往该表中插入一条相关的记录。这边需要注意，方法名是有唯一性约束的，如果有多个请求同时提交到数据库的话，数据库会保证只有一个操作可以成功，那么我们就可以认为操作成功的那个线程获得了该方法的锁，可以执行方法体内容。

执行完毕，需要delete该记录。

当然，笔者这边只是简单介绍一下。对于上述方案可以进行优化，如应用主从数据库，数据之间双向同步。一旦挂掉快速切换到备库上；做一个定时任务，每隔一定时间把数据库中的超时数据清理一遍；使用while循环，直到insert成功再返回成功，虽然并不推荐这样做；还可以记录当前获得锁的机器的主机信息和线程信息，那么下次再获取锁的时候先查询数据库，如果当前机器的主机信息和线程信息在数据库可以查到的话，直接把锁分配给他就可以了，实现可重入锁。

#### 基于数据库排他锁

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

在查询语句后面增加for update，数据库会在查询过程中给数据库表增加排他锁。当某条记录被加上排他锁之后，其他线程无法再在该行记录上增加排他锁。其他没有获取到锁的就会阻塞在上述select语句上，可能的结果有2种，在超时之前获取到了锁，在超时之前仍未获取到锁。

获得排它锁的线程即可获得分布式锁，当获取到锁之后，可以执行方法的业务逻辑，执行完方法之后，释放锁`connection.commit()`。

存在的问题主要是性能不高和sql超时的异常。

#### 基于数据库锁的优缺点

上面两种方式都是依赖数据库的一张表，一种是通过表中的记录的存在情况确定当前是否有锁存在，另外一种是通过数据库的排他锁来实现分布式锁。

- 优点是直接借助数据库，简单容易理解。
- 缺点是操作数据库需要一定的开销，性能问题需要考虑。

### 基于Zookeeper

基于zookeeper临时有序节点可以实现的分布式锁。每个客户端对某个方法加锁时，在zookeeper上的与该方法对应的指定节点的目录下，生成一个唯一的瞬时有序节点。 判断是否获取锁的方式很简单，只需要判断有序节点中序号最小的一个。 当释放锁的时候，只需将这个瞬时节点删除即可。同时，其可以避免服务宕机导致的锁无法释放，而产生的死锁问题。

提供的第三方库有[curator](https://curator.apache.org/)，具体使用读者可以自行去看一下。Curator提供的InterProcessMutex是分布式锁的实现。acquire方法获取锁，release方法释放锁。另外，锁释放、阻塞锁、可重入锁等问题都可以有有效解决。讲下阻塞锁的实现，客户端可以通过在ZK中创建顺序节点，并且在节点上绑定监听器，一旦节点有变化，Zookeeper会通知客户端，客户端可以检查自己创建的节点是不是当前所有节点中序号最小的，如果是就获取到锁，便可以执行业务逻辑。

最后，Zookeeper实现的分布式锁其实存在一个缺点，那就是性能上可能并没有缓存服务那么高。因为每次在创建锁和释放锁的过程中，都要动态创建、销毁瞬时节点来实现锁功能。ZK中创建和删除节点只能通过Leader服务器来执行，然后将数据同不到所有的Follower机器上。并发问题，可能存在网络抖动，客户端和ZK集群的session连接断了，zk集群以为客户端挂了，就会删除临时节点，这时候其他客户端就可以获取到分布式锁了。

### 基于缓存

相对于基于数据库实现分布式锁的方案来说，基于缓存来实现在性能方面会表现的更好一点，存取速度快很多。而且很多缓存是可以集群部署的，可以解决单点问题。基于缓存的锁有好几种，如memcached、redis、本文下面主要讲解基于redis的分布式实现。

## 基于redis的分布式锁实现

### SETNX

使用redis的SETNX实现分布式锁，多个进程执行以下Redis命令：

```
SETNX lock.id <current Unix time + lock timeout + 1>

```

SETNX是将 key 的值设为 value，当且仅当 key 不存在。若给定的 key 已经存在，则 SETNX 不做任何动作。

- 返回1，说明该进程获得锁，SETNX将键 lock.id 的值设置为锁的超时时间，当前时间 +加上锁的有效时间。
- 返回0，说明其他进程已经获得了锁，进程不能进入临界区。进程可以在一个循环中不断地尝试 SETNX 操作，以获得锁。

### 存在死锁的问题

SETNX实现分布式锁，可能会存在死锁的情况。与单机模式下的锁相比，分布式环境下不仅需要保证进程可见，还需要考虑进程与锁之间的网络问题。某个线程获取了锁之后，断开了与Redis 的连接，锁没有及时释放，竞争该锁的其他线程都会hung，产生死锁的情况。

在使用 SETNX 获得锁时，我们将键 lock.id 的值设置为锁的有效时间，线程获得锁后，其他线程还会不断的检测锁是否已超时，如果超时，等待的线程也将有机会获得锁。然而，锁超时，我们不能简单地使用 DEL 命令删除键 lock.id 以释放锁。

考虑以下情况:

> 1. A已经首先获得了锁 lock.id，然后线A断线。B,C都在等待竞争该锁；
> 2. B,C读取lock.id的值，比较当前时间和键 lock.id 的值来判断是否超时，发现超时；
> 3. B执行 DEL lock.id命令，并执行 SETNX lock.id 命令，并返回1，B获得锁；
> 4. C由于各刚刚检测到锁已超时，执行 DEL lock.id命令，将B刚刚设置的键 lock.id 删除，执行 SETNX lock.id命令，并返回1，即C获得锁。

上面的步骤很明显出现了问题，导致B,C同时获取了锁。在检测到锁超时后，线程不能直接简单地执行 DEL 删除键的操作以获得锁。

对于上面的步骤进行改进，问题是出在删除键的操作上面，那么获取锁之后应该怎么改进呢？
首先看一下redis的GETSET这个操作，`GETSET key value`，将给定 key 的值设为 value ，并返回 key 的旧值(old value)。利用这个操作指令，我们改进一下上述的步骤。

> 1. A已经首先获得了锁 lock.id，然后线A断线。B,C都在等待竞争该锁；
> 2. B,C读取lock.id的值，比较当前时间和键 lock.id 的值来判断是否超时，发现超时；
> 3. B检测到锁已超时，即当前的时间大于键 lock.id 的值，B会执行
>    `GETSET lock.id <current Unix timestamp + lock timeout + 1>`设置时间戳，通过比较键 lock.id 的旧值是否小于当前时间，判断进程是否已获得锁；
> 4. B发现GETSET返回的值小于当前时间，则执行 DEL lock.id命令，并执行 SETNX lock.id 命令，并返回1，B获得锁；
> 5. C执行GETSET得到的时间大于当前时间，则继续等待。

在线程释放锁，即执行 DEL lock.id 操作前，需要先判断锁是否已超时。如果锁已超时，那么锁可能已由其他线程获得，这时直接执行 DEL lock.id 操作会导致把其他线程已获得的锁释放掉。

### 一种实现方式

#### 获取锁

```
public boolean lock(long acquireTimeout, TimeUnit timeUnit) throws InterruptedException {
    acquireTimeout = timeUnit.toMillis(acquireTimeout);
    long acquireTime = acquireTimeout + System.currentTimeMillis();
    //使用J.U.C的ReentrantLock
    threadLock.tryLock(acquireTimeout, timeUnit);
    try {
        //循环尝试
        while (true) {
            //调用tryLock
            boolean hasLock = tryLock();
            if (hasLock) {
                //获取锁成功
                return true;
            } else if (acquireTime < System.currentTimeMillis()) {
                break;
            }
            Thread.sleep(sleepTime);
        }
    } finally {
        if (threadLock.isHeldByCurrentThread()) {
            threadLock.unlock();
        }
    }

    return false;
}

public boolean tryLock() {

    long currentTime = System.currentTimeMillis();
    String expires = String.valueOf(timeout + currentTime);
    //设置互斥量
    if (redisHelper.setNx(mutex, expires) > 0) {
        //获取锁，设置超时时间
        setLockStatus(expires);
        return true;
    } else {
        String currentLockTime = redisUtil.get(mutex);
        //检查锁是否超时
        if (Objects.nonNull(currentLockTime) && Long.parseLong(currentLockTime) < currentTime) {
            //获取旧的锁时间并设置互斥量
            String oldLockTime = redisHelper.getSet(mutex, expires);
            //旧值与当前时间比较
            if (Objects.nonNull(oldLockTime) && Objects.equals(oldLockTime, currentLockTime)) {
                //获取锁，设置超时时间
                setLockStatus(expires);
                return true;
            }
        }

        return false;
    }
}

```

lock调用tryLock方法，参数为获取的超时时间与单位，线程在超时时间内，获取锁操作将自旋在那里，直到该自旋锁的保持者释放了锁。

tryLock方法中，主要逻辑如下：

- setnx(lockkey, 当前时间+过期超时时间) ，如果返回1，则获取锁成功；如果返回0则没有获取到锁
- get(lockkey)获取值oldExpireTime ，并将这个value值与当前的系统时间进行比较，如果小于当前系统时间，则认为这个锁已经超时，可以允许别的请求重新获取
- 计算newExpireTime=当前时间+过期超时时间，然后getset(lockkey, newExpireTime) 会返回当前lockkey的值currentExpireTime
- 判断currentExpireTime与oldExpireTime 是否相等，如果相等，说明当前getset设置成功，获取到了锁。如果不相等，说明这个锁又被别的请求获取走了，那么当前请求可以直接返回失败，或者继续重试

#### 释放锁

```
    public boolean unlock() {
        //只有锁的持有线程才能解锁
        if (lockHolder == Thread.currentThread()) {
            //判断锁是否超时，没有超时才将互斥量删除
            if (lockExpiresTime > System.currentTimeMillis()) {
                redisHelper.del(mutex);
                logger.info("删除互斥量[{}]", mutex);
            }
            lockHolder = null;
            logger.info("释放[{}]锁成功", mutex);

            return true;
        } else {
            throw new IllegalMonitorStateException("没有获取到锁的线程无法执行解锁操作");
        }
    }

```

在上面获取锁的实现下，其实此处的释放锁函数可以不需要了，有兴趣的读者可以结合上面的代码看下为什么？有想法可以留言哦！



------

# 应用场景

当多个机器（多个进程）会对同一条数据进行修改时，并且要求这个修改是原子性的。这里有两个限定：（1）多个进程之间的竞争，意味着JDK自带的锁失效；（2）原子性修改，意味着数据是有状态的，修改前后有依赖。

# 实现方式

- 基于Redis实现，主要基于redis的setnx（set if not exist）命令；
- 基于Zookeeper实现；
- 基于version字段实现，乐观锁，两个线程可以同时读取到原有的version值，但是最终只有一个可以完成操作；

这三种方式中，我接触过第一和第三种。基于redis的分布式锁功能更加强大，可以实现阻塞和非阻塞锁。

# 基于Redis的实践

## 锁的实现

- 锁的key为目标数据的唯一键，value为锁的期望超时时间点；

- 首先进行一次setnx命令，尝试获取锁，如果获取成功，则设置锁的最终超时时间（以防在当前进程获取锁后奔溃导致锁无法释放）；如果获取锁失败，则检查当前的锁是否超时，如果发现没有超时，则获取锁失败；如果发现锁已经超时（即锁的超时时间小于等于当前时间），则再次尝试获取锁，取到后判断下当前的超时时间和之前的超时时间是否相等，如果相等则说明当前的客户端是排队等待的线程里的第一个尝试获取锁的，让它获取成功即可。
  ![基于redis实现分布式锁逻辑.png](http://upload-images.jianshu.io/upload_images/44770-f8c10db8066e44e6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

  ```
  public class RedisDistributionLock {

  private static final Logger logger = LoggerFactory.getLogger(RedisDistributionLock.class);

  //key的TTL,一天
  private static final int finalDefaultTTLwithKey = 24 * 3600;

  //锁默认超时时间,20秒
  private static final long defaultExpireTime = 20 * 1000;

  private static final boolean Success = true;

  @Resource( name = "redisTemplate")
  private RedisTemplate<String, String> redisTemplateForGeneralize;

  /**
   * 加锁,锁默认超时时间20秒
   * @param resource
   * @return
   */
  public boolean lock(String resource) {
      return this.lock(resource, defaultExpireTime);
  }

  /**
   * 加锁,同时设置锁超时时间
   * @param key 分布式锁的key
   * @param expireTime 单位是ms
   * @return
   */
  public boolean lock(String key, long expireTime) {

      logger.debug("redis lock debug, start. key:[{}], expireTime:[{}]",key,expireTime);
      long now = Instant.now().toEpochMilli();
      long lockExpireTime = now + expireTime;

      //setnx
      boolean executeResult = redisTemplateForGeneralize.opsForValue().setIfAbsent(key,String.valueOf(lockExpireTime));
      logger.debug("redis lock debug, setnx. key:[{}], expireTime:[{}], executeResult:[{}]", key, expireTime,executeResult);

      //取锁成功,为key设置expire
      if (executeResult == Success) {
          redisTemplateForGeneralize.expire(key,finalDefaultTTLwithKey, TimeUnit.SECONDS);
          return true;
      }
      //没有取到锁,继续流程
      else{
          Object valueFromRedis = this.getKeyWithRetry(key, 3);
          // 避免获取锁失败,同时对方释放锁后,造成NPE
          if (valueFromRedis != null) {
              //已存在的锁超时时间
              long oldExpireTime = Long.parseLong((String)valueFromRedis);
              logger.debug("redis lock debug, key already seted. key:[{}], oldExpireTime:[{}]",key,oldExpireTime);
              //锁过期时间小于当前时间,锁已经超时,重新取锁
              if (oldExpireTime <= now) {
                  logger.debug("redis lock debug, lock time expired. key:[{}], oldExpireTime:[{}], now:[{}]", key, oldExpireTime, now);
                  String valueFromRedis2 = redisTemplateForGeneralize.opsForValue().getAndSet(key, String.valueOf(lockExpireTime));
                  long currentExpireTime = Long.parseLong(valueFromRedis2);
                  //判断currentExpireTime与oldExpireTime是否相等
                  if(currentExpireTime == oldExpireTime){
                      //相等,则取锁成功
                      logger.debug("redis lock debug, getSet. key:[{}], currentExpireTime:[{}], oldExpireTime:[{}], lockExpireTime:[{}]", key, currentExpireTime, oldExpireTime, lockExpireTime);
                      redisTemplateForGeneralize.expire(key, finalDefaultTTLwithKey, TimeUnit.SECONDS);
                      return true;
                  }else{
                      //不相等,取锁失败
                      return false;
                  }
              }
          }
          else {
              logger.warn("redis lock,lock have been release. key:[{}]", key);
              return false;
          }
      }
      return false;
  }

  private Object getKeyWithRetry(String key, int retryTimes) {
      int failTime = 0;
      while (failTime < retryTimes) {
          try {
              return redisTemplateForGeneralize.opsForValue().get(key);
          } catch (Exception e) {
              failTime++;
              if (failTime >= retryTimes) {
                  throw e;
              }
          }
      }
      return null;
  }

  /**
   * 解锁
   * @param key
   * @return
   */
  public boolean unlock(String key) {
      logger.debug("redis unlock debug, start. resource:[{}].",key);
      redisTemplateForGeneralize.delete(key);
      return Success;
  }
  }

  ```

  ## 自定义注解使用分布式锁

  ```
  @Retention(RetentionPolicy.RUNTIME)
  @Target(ElementType.METHOD)
  public @interface RedisLockAnnoation {

  String keyPrefix() default "";

  /**
   * 要锁定的key中包含的属性
   */
  String[] keys() default {};

  /**
   * 是否阻塞锁；
   * 1. true：获取不到锁，阻塞一定时间；
   * 2. false：获取不到锁，立即返回
   */
  boolean isSpin() default true;

  /**
   * 超时时间
   */
  int expireTime() default 10000;

  /**
   * 等待时间
   */
  int waitTime() default 50;

  /**
   * 获取不到锁的等待时间
   */
  int retryTimes() default 20;
  }

  ```

  ## 实现分布式锁的逻辑

  ```
  @Component
  @Aspect
  public class RedisLockAdvice {

  private static final Logger logger = LoggerFactory.getLogger(RedisLockAdvice.class);

  @Resource
  private RedisDistributionLock redisDistributionLock;

  @Around("@annotation(RedisLockAnnoation)")
  public Object processAround(ProceedingJoinPoint pjp) throws Throwable {
      //获取方法上的注解对象
      String methodName = pjp.getSignature().getName();
      Class<?> classTarget = pjp.getTarget().getClass();
      Class<?>[] par = ((MethodSignature) pjp.getSignature()).getParameterTypes();
      Method objMethod = classTarget.getMethod(methodName, par);
      RedisLockAnnoation redisLockAnnoation = objMethod.getDeclaredAnnotation(RedisLockAnnoation.class);

      //拼装分布式锁的key
      String[] keys = redisLockAnnoation.keys();
      Object[] args = pjp.getArgs();
      Object arg = args[0];
      StringBuilder temp = new StringBuilder();
      temp.append(redisLockAnnoation.keyPrefix());
      for (String key : keys) {
          String getMethod = "get" + StringUtils.capitalize(key);
          temp.append(MethodUtils.invokeExactMethod(arg, getMethod)).append("_");
      }
      String redisKey = StringUtils.removeEnd(temp.toString(), "_");

      //执行分布式锁的逻辑
      if (redisLockAnnoation.isSpin()) {
          //阻塞锁
          int lockRetryTime = 0;
          try {
              while (!redisDistributionLock.lock(redisKey, redisLockAnnoation.expireTime())) {
                  if (lockRetryTime++ > redisLockAnnoation.retryTimes()) {
                      logger.error("lock exception. key:{}, lockRetryTime:{}", redisKey, lockRetryTime);
                      throw ExceptionUtil.geneException(CommonExceptionEnum.SYSTEM_ERROR);
                  }
                  ThreadUtil.holdXms(redisLockAnnoation.waitTime());
              }
              return pjp.proceed();
          } finally {
              redisDistributionLock.unlock(redisKey);
          }
      } else {
          //非阻塞锁
          try {
              if (!redisDistributionLock.lock(redisKey)) {
                  logger.error("lock exception. key:{}", redisKey);
                  throw ExceptionUtil.geneException(CommonExceptionEnum.SYSTEM_ERROR);
              }
              return pjp.proceed();
          } finally {
              redisDistributionLock.unlock(redisKey);
          }
      }
  }
  }

  ```

# 参考资料

1. [Java分布式锁三种实现方案](https://www.jianshu.com/p/535efcab356d)
2. [Java注解的基础与高级应用](http://linbinghe.com/2017/ac8515d0.html)
3. [基于 AOP 和 Redis 实现的分布式锁](http://blog.csdn.net/qq1013598664/article/details/71642140)
4. [如何高效排查系统故障？一分钱引发的系统设计“踩坑”案例](https://yq.aliyun.com/articles/272539)
5. [用redis实现分布式锁](http://www.jeffkit.info/2011/07/1000/?spm=5176.100239.blogcont60663.8.9f4d4a8ltDsSf)