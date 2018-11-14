---
title: Redis杂记
date: 2018-10-06 16:15:04
categories: [Programming, Java, Spring Boot]
tags: [Redis, Spring Boot]
---



![](https://cdn.yangbingdong.com/img/spring-boot-redis/redis-logo.png)

# Preface

> Redis是一个开源的使用ANSI C语言编写、支持网络、可基于内存亦可持久化的日志型、Key-Value数据库，并提供多种语言的API。相比`Memcached`它支持存储的类型相对更多**（字符、哈希、集合、有序集合、列表、GEO）**，**同时Redis是线程安全的**。2010年3月15日起，Redis的开发工作由VMware主持，2013年5月开始，Redis的开发由`Pivotal`赞助。 

<!--more-->

# 安装与配置

## 安装

### 基于Docker安装

拉取镜像：

```
docker pull redis:latest
```

运行实例：

```
REDIS=/home/ybd/data/docker/redis && \
docker run -p 6379:6379 --restart=always \
-v $REDIS/redis.conf:/usr/local/etc/redis/redis.conf \
-v $REDIS/data:/data \
--name redis -d redis \
redis-server /usr/local/etc/redis/redis.conf --appendonly yes
```

安装链接工具：

```
sudo apt install redis-tools

// 连接
redis-cli -h 127.0.0.1 -p 6379
```

或者docker-compose启动：

```
version: '3'
services:
  redis:
    image: redis:latest
#    command: ["redis-server", "--appendonly", "yes"]
    command: ["redis-server", "/usr/local/etc/redis/redis.conf"]
    restart: always
    ports:
      - "6379:6379"
    networks:
      backend-swarm:
        aliases:
         - redis
    volumes:
      - ./data:/data
      - ./config/redis.conf:/usr/local/etc/redis/redis.conf

# docker network create -d=overlay --attachable backend
networks:
  backend-swarm:
    external:
      name: backend-swarm
```

### Ubuntu Apt安装

终端执行：
```
sudo apt update && sudo apt install redis-server

# 启动
redis-server

# 连接
redis-cli -h 127.0.0.1 -p 6379
```

## 配置相关

> 稳定版本配置文件： ***[http://download.redis.io/redis-stable/redis.conf](http://download.redis.io/redis-stable/redis.conf)***

`/etc/redis`：存放redis配置文件
`/var/redis/端口号`：存放redis的持久化文件

通过下面的命令停止/启动/重启redis：
```
/etc/init.d/redis-server stop
/etc/init.d/redis-server start
/etc/init.d/redis-server restart
```

如果是通过源码安装的redis，则可以通过redis的客户端程序`redis-cli`的`shutdown`命令来重启redis
```
redis-cli -h 127.0.0.1 -p 6379 shutdown
```
如果上述方式都没有成功停止redis，则可以使用终极武器 `kill -9`

## 开启远程访问
找到`redis.conf`文件，一般在`/etc`下面：

找到`bind 127.0.0.1`注释掉
注释掉本机,局域网内的所有计算机都能访问。
`band localhost` 只能本机访问,局域网内计算机不能访问。
`bind 局域网IP` 只能局域网内IP的机器访问, 本地localhost都无法访问。

博主选择将`bind 127.0.0.1` 改成了`bind 0.0.0.0`

## 开启发布订阅监听

> Redis自2.8.0之后版本提供[Keyspace Notifications](https://redis.io/topics/notifications)功能，允许客户订阅Pub / Sub频道，以便以某种方式接收影响Redis数据集的事件。
>
> Redis默认关闭，键空间通知通常是不启用的，因为这个过程会产生额外消耗

还是修改`redis.conf`文件，找到`notify-keyspace-events ""`，修改为`notify-keyspace-events Ex`或者`notify-keyspace-events AKE`，然后重启。

| 字符  | 发送通知                                                     |
| ----- | ------------------------------------------------------------ |
| K     | 键空间通知，所有通知以 **keyspace@** 为前缀，针对Key         |
| E     | 键事件通知，所有通知以 **keyevent@** 为前缀，针对event       |
| *g*   | *DEL 、 EXPIRE 、 RENAME 等类型无关的通用命令的通知*         |
| **$** | **字符串命令的通知**                                         |
| **l** | **列表命令的通知**                                           |
| **s** | **集合命令的通知**                                           |
| **h** | **哈希命令的通知**                                           |
| **z** | **有序集合命令的通知**                                       |
| *x*   | *过期事件：每当有过期键被删除时发送*                         |
| *e*   | *驱逐(evict)事件：每当有键因为 maxmemory 政策而被删除时发送* |
| A     | 参数 g$lshzxe 的别名，相当于是All                            |

`SUBSCRIBE`与`PSUBSCRIBE`都可以订阅事件，后者可以通过正则表达匹配对应的Channel，比如`__keyevent*__:expired`订阅所有数据库的过期事件

打开一个终端订阅key过期事件：

```
192.168.6.113:6379> PSUBSCRIBE __keyevent*__:expired
Reading messages... (press Ctrl-C to quit)
1) "psubscribe"
2) "__keyevent*__:expired"
3) (integer) 1
```

再开一个终端设置一个会过期的kv：

```
192.168.6.113:6379> set test ybd EX 10
OK
```

10秒后在第一个终端将会受到如下信息：

```
1) "pmessage"
2) "__keyevent*__:expired"
3) "__keyevent@0__:expired"
4) "test"
```

# Redis常用命令

> 最新命令参考： ***[http://redisdoc.com](http://redisdoc.com)***

## 连接操作命令

- `quit`：关闭连接（connection）
- `auth`：简单密码认证
- `help cmd`： 查看cmd帮助，例如：help quit

## 持久化

- `save`：将数据同步保存到磁盘
- `bgsave`：将数据异步保存到磁盘
- `lastsave`：返回上次成功将数据保存到磁盘的Unix时戳
- `shutdown`：将数据同步保存到磁盘，然后关闭服务

## 远程服务控制

- `info`：提供服务器的信息和统计
- `monitor`：实时转储收到的请求
- `slaveof`：改变复制策略设置
- `config`：在运行时配置Redis服务器

## 对key操作的命令

- `exists(key)`：确认一个key是否存在
- `del(key)`：删除一个key
- `type(key)`：返回值的类型
- `keys(pattern)`：返回满足给定pattern的所有key
- `randomkey`：随机返回key空间的一个
- `keyrename(oldname, newname)`：重命名key
- `dbsize`：返回当前数据库中key的数目
- `expire`：设定一个key的活动时间（s）
- `ttl`：获得一个key的活动时间
- `select(index)`：按索引查询
- `move(key, dbindex)`：移动当前数据库中的key到dbindex数据库
- `flushdb`：删除当前选择数据库中的所有key
- `flushall`：删除所有数据库中的所有key

## String

- `set(key, value [EX seconds] [PX milliseconds] [NX|XX])`：给数据库中名称为key的string赋予值value，EX与PX都是过期时间，前者是秒为单位，后者是毫秒，NX表示当key不存在时赋值，XX表示当key存在时赋值
- `get(key)`：返回数据库中名称为key的string的value
- `getset(key, value)`：给名称为key的string赋予上一次的value
- `mget(key1, key2,…, key N)`：返回库中多个string的value
- `setnx(key, value)`：添加string，名称为key，值为value
- `setex(key, time, value)`：向库中添加string，设定过期时间time
- `mset(key N, value N)`：批量设置多个string的值
- `msetnx(key N, value N)`：如果所有名称为key i的string都不存在
- `incr(key)`：名称为key的string增1操作
- `incrby(key, integer)`：名称为key的string增加integer
- `decr(key)`：名称为key的string减1操作
- `decrby(key, integer)`：名称为key的string减少integer
- `append(key, value)`：名称为key的string的值附加value
- `substr(key, start, end)`：返回名称为key的string的value的子串

## List

- `rpush(key, value)`：在名称为key的list尾添加一个值为value的元素
- `lpush(key, value)`：在名称为key的list头添加一个值为value的 元素
- `llen(key)`：返回名称为key的list的长度
- `lrange(key, start, end)`：返回名称为key的list中start至end之间的元素
- `ltrim(key, start, end)`：截取名称为key的list
- `lindex(key, index)`：返回名称为key的list中index位置的元素
- `lset(key, index, value)`：给名称为key的list中index位置的元素赋值
- `lrem(key, count, value)`：删除count个key的list中值为value的元素
- `lpop(key)`：返回并删除名称为key的list中的首元素
- `rpop(key)`：返回并删除名称为key的list中的尾元素
- `blpop(key1, key2,… key N, timeout)`：lpop命令的block版本。
- `brpop(key1, key2,… key N, timeout)`：rpop的block版本。
- `rpoplpush(srckey, dstkey)`：返回并删除名称为srckey的list的尾元素，并将该元素添加到名称为dstkey的list的头部

## Set

- `sadd(key, member)`：向名称为key的set中添加元素member
- `srem(key, member)` ：删除名称为key的set中的元素member
- `spop(key)` ：随机返回并删除名称为key的set中一个元素
- `smove(srckey, dstkey, member)` ：移到集合元素
- `scard(key)` ：返回名称为key的set的基数
- `sismember(key, member)` ：member是否是名称为key的set的元素
- `sinter(key1, key2,…key N)` ：求交集
- `sinterstore(dstkey, (keys))` ：求交集并将交集保存到dstkey的集合
- `sunion(key1, (keys))` ：求并集
- `sunionstore(dstkey, (keys))` ：求并集并将并集保存到dstkey的集合
- `sdiff(key1, (keys))` ：求差集
- `sdiffstore(dstkey, (keys))` ：求差集并将差集保存到dstkey的集合
- `smembers(key)` ：返回名称为key的set的所有元素
- `srandmember(key)` ：随机返回名称为key的set的一个元素

## Hash

- `hset(key, field, value)`：向名称为key的hash中添加元素field
- `hget(key, field)`：返回名称为key的hash中field对应的value
- `hmget(key, (fields))`：返回名称为key的hash中field i对应的value
- `hmset(key, (fields))`：向名称为key的hash中添加元素field
- `hincrby(key, field, integer)`：将名称为key的hash中field的value增加integer
- `hexists(key, field)`：名称为key的hash中是否存在键为field的域
- `hdel(key, field)`：删除名称为key的hash中键为field的域
- `hlen(key)`：返回名称为key的hash中元素个数
- `hkeys(key)`：返回名称为key的hash中所有键
- `hvals(key)`：返回名称为key的hash中所有键对应的value
- `hgetall(key)`：返回名称为key的hash中所有的键（field）及其对应的value


# 不同数据类型的常见应用场景

> 为缓存而生的Redis，其所有数据都在内存中，固其最大的应用场景就是缓存了，但这只是个大的概念，其不同的数据类型都有对应的应用场景。

## String

### 对象存储

这应该是最最最常用的场景了，将对象序列化后再`set`进去，所以选择一个好的序列化方案很重要，需要从时间复杂度以及空间复杂度这两个维度综合考虑。个人觉得`Protostuff`选当不错，基于Google的Protobuff。详情请看下面的**序列化**一节。

### 计数

`INCRBY`可以原子性地递增，通常用作分布式计数器，也可以用作生成ID。

### 分布式锁

正由于Redis是单线程客户端，这不单单是一个特性，更是一个应用场景，最常用的就是分布式锁了。

```
SET key value [EX seconds] [PX milliseconds] [NX|XX]
```

利用上面命令，可以做到加锁与过期的原子性。

释放锁可以利用LUA脚本完成：

```
if redis.call("get",KEYS[1]) == ARGV[1]
then
    return redis.call("del",KEYS[1])
else
    return 0
end
```

### 超大数量的布尔统计

比如要统计几亿人的在线情况、数十亿的布尔存储（布尔标识符）都可以使用`GETBIT`、`SETBIT`、`BITCOUNT`来完成。

## List

### 显示最新的分页列表

一种很常见的需求，分页，比如列出最新的5页评论、列出最新的某活动5页商品，在QPS高的时候，采用传统的RDBS查询往往会有性能问题。BUT，结合Redis的`LPUSH`与`LTRIM`可以优雅地缓存最新的数据并做到分页，一般大部分用户只关注前几页数据，那么后面的数据可以用数据库补上。这时候前5页的数据是走缓存的，QPS可以提高几个数量级

### 消息队列

Redis 的 list 数据类型对于大部分使用者来说，是实现队列服务的最经济，最简单的方式。

## Set

### 共同好友列表（求交集系列）

社交类应用中，获取两个人或多个人的共同好友，两个人或多个人共同关注的微博这样类似的功能，用 MySQL 的话操作很复杂，可以把每个人的好友 id 存到集合中，获取共同好友的操作就可以简单到一个取交集的命令就搞定。

```
sadd user:wade james melo paul kobe
sadd user:james wade melo paul kobe
sadd user:paul wade james melo kobe
sadd user:melo wade james paul kobe

// 获取 wade 和 james 的共同好友
sinter user:wade user:james
/* 输出：
 *      1) "kobe"
 *      2) "paul"
 *      3) "melo"
 */
 
 // 获取香蕉四兄弟的共同好友
 sinter user:wade user:james user:paul user:melo
 /* 输出：
 *      1) "kobe"
 */
```

类似的需求还有很多 , 必须把每个标签下的文章 id 存到集合中，可以很容易的求出几个不同标签下的共同文章；
 把每个人的爱好存到集合中，可以很容易的求出几个人的共同爱好。

## SortedSet

### 排行榜

SortedSet 是在 Set 的基础上给集合中每个元素关联了一个分数，往有序集合中插入数据时会自动根据这个分数排序，很适合排行榜之类的需求：

– 列出前100名高分选手

– 列出某用户当前的全球排名

# 慢查询查看

> Redis 通过 `slowlog-log-slower-than` 和 `slowlog-max-len` 分别配置慢查询的阈值，以及慢查询记录的日志长度。 `slowlog-log-slower-than` 默认值 10*1000 **微秒**，当命令执行时间查过设定时，那么将会被记录在慢查询日志中。如果`slowlog-log-slower-than=0`会记录所有的命令，`slowlog-log-slower-than<0` 对于任何命令都不会进行记录。

参数设定：

```
config set slowlog-log-slower-than 20000
config set slowlog-max-len 1000
config rewrite
```

> 如果要 Redis 将配置**持久化**到本地配置文件，需要执行 `config rewrite` 命令.

**获取慢查询日志:**

```
slowlog get [n] // n 表示返回的日志记录条数
```

每个慢查询日志有 4 个属性组成，分别是慢查询日志的标识 id、发生时间戳、命令耗时、执行命令和参数，慢查询列表如下：

```
127.0.0.1:6378> slowlog get
1) 1) (integer) 0                       //标识 id
   2) (integer) 1501750261      //时间戳
   3) (integer) 19                      // 命令耗时
   4) 1) "config"                        // 执行命令
      2) "set"
      3) "slowlog-log-slower-than"
      4) "0"
127.0.0.1:6378> 
```

**获取慢查询日志列表当前的长度:**

```
127.0.0.1:6378> slowlog len
(integer) 2
127.0.0.1:6378> 
```

**慢查询最佳实践**

- `slowlog-max-len` 配置建议：线上建议调大慢查询列表，记录慢查询时 Redis 会对长命令做截断操作，并不会占用大量内存。增大慢查询列表可以减缓慢查询被剔除的可能，例如线上可设置为 1000 以上。
- `slowlog-log-slower-than` 配置建议：默认值超过 10 毫秒判定为慢查询，需要根据 Redis 并发量调整该值。由于 Redis 采用单线程响应命令，对于高流量的场景，如果命令执行时间在 1 毫秒以上，那么 Redis 最多可支撑 OPS 不到 1000。因此对于高 OPS （operation per second）场景的 Redis 建议设置为 1 毫秒。
- 慢查询只记录命令执行时间，并不包括命令排队和网络传输时间。因此客户端执行命
  令的时间会大于命令实际执行时间。因为命令执行排队机制，慢查询会导致其他命令级联阻塞，因此当客户端出现请求超时，需要检查该时间点是否有对应的慢查询，从
  而分析出是否为慢查询导致的命令级联阻塞。
- 由于慢查询日志是一个先进先出的队列，也就是说如果慢查询比较多的情况下，可能
  会丢失部分慢查询命令，为了防止这种情况发生，可以定期执行 slow get 命令将慢查询日志持久化到其他存储中（例如 MySQL），然后可以制作可视化界面进行查询。

# rdb文件分析

首先查看Redis的dump目录设置:

```
CONFIG GET dir
```

再使用`bgsave`命令导出`dump.rdb`，将`dump.rdb`复制出来，再使用 ***[rdr](https://github.com/xueqiu/rdr)*** 分析：

```
./rdr show -p 8080 *.rdb
```

效果图：

![](https://cdn.yangbingdong.com/img/javaDevEnv/rdr.png)

# 客户端序列化选择

> ***[https://github.com/masteranthoneyd/serializer](https://github.com/masteranthoneyd/serializer)***

以下是序列化框架性能对比（纳秒）

操作系统：Ubuntu 18.04 64位

CPU：I7-8700

内存：32G 

![](https://cdn.yangbingdong.com/img/spring-boot-redis/serialize-performance.png)

* `Protostuff`不能直接序列化集合，需要用包装类封装起来。
* `String`类型还是建议直接使用`StringRedisSerializer`，速度最快。

# Spring监听Redis Keyspace Event

在Spring Boot应用中，可使用方式一和二，集成非常快。

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-pool2</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

## 方式一、通过`RedisMessageListenerContainer`

这个类是使用线程池监听并执行后续动作的，可以添加多个监听者。

配置类：

```java
@Configuration
public class RedisConfig {

	@Resource
	private LettuceConnectionFactory lettuceConnectionFactory

	@Bean
	public RedisMessageListenerContainer redisMessageListenerContainer() {
		RedisMessageListenerContainer redisMessageListenerContainer = new RedisMessageListenerContainer();
		redisMessageListenerContainer.setConnectionFactory(lettuceConnectionFactory);
		redisMessageListenerContainer.addMessageListener(new KeyExpireListener(), new PatternTopic("__keyevent@*__:expired"));
		return redisMessageListenerContainer;
	}

}
```

监听类：

```java
public class KeyExpireListener implements MessageListener {
	private RedisSerializer<String> stringRedisSerializer = new StringRedisSerializer();

	@Override
	public void onMessage(Message message, byte[] pattern) {
		Thread thread = Thread.currentThread();
		System.out.println(thread.getId() + " " + thread.getName() + " -> " + stringRedisSerializer.deserialize(pattern) + ": " + message);
	}
}
```

如此简单的几行代码就可以监听Redis Key过期事件，但`RedisMessageListenerContainer`默认使用`SimpleAsyncTaskExecutor`作为线程池，这个线程池比较坑的地方在于每次都是用新的线程去执行任务，不重用线程，不是真正意义上的线程池。

## 方式二、监听RedisKeyspaceEvent

通过创建并注册`KeyExpirationEventMessageListener`，监听到过期事件后，会发布一个`RedisKeyExpiredEvent`。

`KeyExpirationEventMessageListener`继承`KeyspaceEventMessageListener`，`KeyspaceEventMessageListener`实现`MessageListener`，在`onMessage(...)`方法中提供了`doHandleMessage(message)`抽象方法，最终由`KeyExpirationEventMessageListener`实现。

配之类：

```java
@Configuration
public class RedisConfig {

	@Resource
	private LettuceConnectionFactory lettuceConnectionFactory;

	@Bean
	public KeyExpirationEventMessageListener keyExpirationEventMessageListener() {
		return new KeyExpirationEventMessageListener(redisMessageListenerContainer());
	}

	@Bean
	public RedisMessageListenerContainer redisMessageListenerContainer() {
		RedisMessageListenerContainer redisMessageListenerContainer = new RedisMessageListenerContainer();
		redisMessageListenerContainer.setConnectionFactory(lettuceConnectionFactory);
		return redisMessageListenerContainer;
	}

}
```

事件监听类：

```java
@Component
public class KeyExpireApplicationEventListener implements ApplicationListener<RedisKeyExpiredEvent> {
	@Override
	public void onApplicationEvent(RedisKeyExpiredEvent event) {
		System.out.println(event);
	}
}
```

实际上`KeyExpirationEventMessageListener`也是`MessageListener`的实现，最终还是由`RedisMessageListenerContainer`管理，没有设置线程池的话，还是使用`SimpleAsyncTaskExecutor`。。。

两种方式最终都是`RedisPubSubCommands.pSubscribe(MessageListener listener, byte[]... patterns);`

## 方式三、结合Disruptor

上面两种方式操作简单，但是如果每天有上千万的过期通知，在一个链接的情况下可能会影响吞吐量，某些业务处理比较慢，阻塞后面的通知，这种情况下我们可以结合高性能队列框架`Disruptor`异步处理。

先定义Event：

```java
import org.springframework.data.redis.connection.Message;

/**
 * @author ybd
 * @date 18-10-19
 * @contact yangbingdong1994@gmail.com
 */
public class RedisKeyExpireEvent implements CleanEvent {
    private Message message;
    private byte[] pattern;

    public Message getMessage() {
        return message;
    }

    public RedisKeyExpireEvent setMessage(Message message) {
        this.message = message;
        return this;
    }

    public byte[] getPattern() {
        return pattern;
    }

    public RedisKeyExpireEvent setPattern(byte[] pattern) {
        this.pattern = pattern;
        return this;
    }

    @Override
    public void clean() {
        this.message = null;
        this.pattern = null;
    }
}

public interface CleanEvent {
    void clean();
}
```

* 这个Event是由用户自己定义的。

定义Event处理类：

```java
import com.lmax.disruptor.WorkHandler;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.serializer.RedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;
import org.springframework.stereotype.Component;

/**
 * @author ybd
 * @date 18-10-19
 * @contact yangbingdong1994@gmail.com
 */
@Slf4j
@Component
public class RedisKeyExpireEventHandler implements WorkHandler<RedisKeyExpireEvent> {
	private RedisSerializer<String> stringRedisSerializer = new StringRedisSerializer();
    @Override
    public void onEvent(RedisKeyExpireEvent event) {
        try {
			Thread thread = Thread.currentThread();
			log.info(thread.getId() + " " + thread.getName() + " -> " + stringRedisSerializer.deserialize(event.getPattern()) + ": " + event.getMessage());
        } finally {
            event.clean();
        }
    }
}
```

* 实现的是`WorkHandler`而不是`EventHandler`，因为我们调用的是`disruptor.handleEventsWithWorkerPool`，区别是`WorkerPool`可以达到Sharding的效果。

异常处理类：

```java
import com.lmax.disruptor.ExceptionHandler;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.serializer.StringRedisSerializer;

/**
 * @author ybd
 * @date 18-10-19
 * @contact yangbingdong1994@gmail.com
 */
@Slf4j
public class RedisKeyExpireEventExceptionHandler implements ExceptionHandler<RedisKeyExpireEvent> {
    private StringRedisSerializer strSerial = new StringRedisSerializer();
    @Override
    public void handleEventException(Throwable ex, long sequence, RedisKeyExpireEvent event) {
        String msgBody = strSerial.deserialize(event.getMessage().getBody());
        log.error("处理Redis Key过期事件失败： " + msgBody, ex);
    }

    @Override
    public void handleOnStartException(Throwable ex) {
		log.error("Disruptor<RedisKeyExpireEvent> handleOnStartException:", ex);
    }

    @Override
    public void handleOnShutdownException(Throwable ex) {
		log.error("Disruptor<RedisKeyExpireEvent> handleOnShutdownException:", ex);
    }
}
```

用于发布事件的Disruptor：

```java
import com.lmax.disruptor.BlockingWaitStrategy;
import com.lmax.disruptor.EventTranslatorTwoArg;
import com.lmax.disruptor.RingBuffer;
import com.lmax.disruptor.dsl.Disruptor;
import com.lmax.disruptor.dsl.ProducerType;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextClosedEvent;
import org.springframework.data.redis.connection.Message;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.util.stream.IntStream;

/**
 * @author ybd
 * @date 18-10-19
 * @contact yangbingdong1994@gmail.com
 */
@Slf4j
@Component
public class RedisKeyExpireDisruptor implements InitializingBean, ApplicationListener<ContextClosedEvent> {
    private static final int TOTAL_SHARDING = 1 << 2;

    private Disruptor<RedisKeyExpireEvent> disruptor;

    private EventTranslatorTwoArg<RedisKeyExpireEvent, Message, byte[]> translatorTwoArg;

    private RingBuffer<RedisKeyExpireEvent> ringBuffer;

    @Resource
	private RedisKeyExpireEventHandler redisKeyExpireEventHandler;


    @Override
    public void afterPropertiesSet() {
        initDisruptor();
		RedisKeyExpireEventHandler[] handlers = buildHandler();
        disruptor.handleEventsWithWorkerPool(handlers);
        disruptor.start();
        ringBuffer = disruptor.getRingBuffer();
        translatorTwoArg = (event, sequence, message, pattern) -> event.setMessage(message).setPattern(pattern);
        log.info("RedisKeyExpireDisruptor initialized");
    }

    private RedisKeyExpireEventHandler[] buildHandler() {
        return IntStream.range(0, TOTAL_SHARDING)
                        .mapToObj(i -> redisKeyExpireEventHandler)
                        .toArray(RedisKeyExpireEventHandler[]::new);
    }

    private void initDisruptor() {
        disruptor = new Disruptor<>(RedisKeyExpireEvent::new, 1 << 10, DisruptorUtil.getThreadFactory("keyspace-disruptor-%d"), ProducerType.SINGLE, new BlockingWaitStrategy());
        disruptor.setDefaultExceptionHandler(new RedisKeyExpireEventExceptionHandler());
    }

    @Override
    public void onApplicationEvent(ContextClosedEvent event) {
        DisruptorUtil.shutDownDisruptor(disruptor);
    }

    public void publish(Message message, byte[] pattern) {
        ringBuffer.publishEvent(translatorTwoArg, message, pattern);
    }
}
```

工具类：

```java
import com.lmax.disruptor.TimeoutException;
import com.lmax.disruptor.dsl.Disruptor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.concurrent.BasicThreadFactory;

import java.util.concurrent.TimeUnit;

/**
 * @author ybd
 * @date 18-9-29
 * @contact yangbingdong1994@gmail.com
 */
@Slf4j
public final class DisruptorUtil {

    public static BasicThreadFactory getThreadFactory(String pattern) {
        return new BasicThreadFactory.Builder().namingPattern(pattern)
                                               .daemon(true)
                                               .build();
    }

    public static void shutDownDisruptor(Disruptor disruptor) {
        if (disruptor != null) {
            try {
                disruptor.shutdown(5, TimeUnit.SECONDS);
            } catch (TimeoutException e) {
                log.error("Disruptor shutdown error!", e);
            }
        }
    }
}
```

效果图：

![](https://cdn.yangbingdong.com/img/spring-boot-redis/redis-key-expire-disruptor.png)

## 缺点

> ## Timing of expired events
>
> Keys with a time to live associated are expired by Redis in two ways:
>
> - When the key is accessed by a command and is found to be expired.
> - Via a background system that looks for expired keys in background, incrementally, in order to be able to also collect keys that are never accessed.
>
> The `expired` events are generated when a key is accessed and is found to be expired by one of the above systems, as a result there are no guarantees that the Redis server will be able to generate the `expired` event at the time the key time to live reaches the value of zero.
>
> If no command targets the key constantly, and there are many keys with a TTL associated, there can be a significant delay between the time the key time to live drops to zero, and the time the `expired` event is generated.
>
> Basically `expired` events **are generated when the Redis server deletes the key** and not when the time to live theoretically reaches the value of zero.

上面是官方文档的原文，在删除key的时候发送事件，而删除key不是实时的，而是后台逐步删除的，所有可能会与TTL时间存在误差。在客户端链接丢失期间（比如项目迭代发布版本），也是会丢失消息的。