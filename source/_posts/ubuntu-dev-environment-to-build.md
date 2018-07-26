---
title: Ubuntu的Java开发环境基本搭建
date: 2017-01-20 11:31:22
categories: [OperatingSystem,Ubuntu]
tags: [Ubuntu,IDE,JDK,Tomcat]
---
# 前言
最近公司的电脑由于不明原因老是奔溃，重装过两次，在家里也比较喜欢折腾系统，为了不用每次都度娘谷歌，记录下来，一条龙走过。博主是搞爪哇开发的，那么以下搭建针对的是爪哇环境开发

<!--more-->
# 安装JDK以及配置环境变量

## 通过Apt安装

> ***[https://linuxconfig.org/how-to-install-java-on-ubuntu-18-04-bionic-beaver-linux](https://linuxconfig.org/how-to-install-java-on-ubuntu-18-04-bionic-beaver-linux)***

### OpenJDK

JDK8:

```
sudo apt install openjdk-8-jdk
```

JDK9:

```
sudo apt install openjdk-9-jdk
```

JDK11:

```
sudo apt install openjdk-11-jdk
```

### OracleJDK

```
sudo add-apt-repository ppa:webupd8team/java && sudo apt update
```

JDK8:

```
sudo apt install oracle-java8-set-default
```

JDK9:

```
sudo apt install oracle-java9-set-default
```

## 手动安装

### 安装JDK

安装之前当然是老规矩地下载`jdk`：*[Oracle JDK官方下载](http://www.oracle.com/technetwork/java/javase/downloads/index.html)*

```
# 把jdk的文件移动到 /usr/local/ 目录下
sudo mv ~/jdk*.tar.gz /usr/local/
# 解压文件
cd /usr/local/
# sudo tar -zxvf jdk-8u101-linux-x64.tar.gz
# 创建软链接
sudo ln -s jdk1.8.0_101 jdk
```

***如需更换`jdk`，删除旧版本的软链接，重新创建软链接指向新版即可***

```
sudo rm -rf jdk
sudo ln -s jdk* jdk
```

### 配置环境变量

- 放到 `/usr/local` 里面的程序，建议使用系统变量。
- 用户变量
    `~/.profile` 文件是用户的私有配置文件
    `~/.bashrc`  是在bash里面使用的私有配置文件，优先级在 `.profile` 文件之后
- 系统变量
    `/etc/profile` 文件是系统的公用配置文件
    `/etc/bash.bashrc` 是`bash`专用的配置文件，优先级在 `profile` 文件之后
- 系统变量的配置，不建议修改前面说到的两个文件，而是建议在 ***`/etc/profile.d/`*** 目录下，创建一个 `.sh` 结尾 的文件。

```
sudo vi /etc/profile.d/jdk.sh
```
***环境变量的配置内容如下：***

1. 设置一个名为`JAVA_HOME`的变量，并且使用`export`命令导出为环境变量, 如果不使用 `export` ，仅在当前`shell`里面有效
```
export JAVA_HOME=/usr/local/jdk
```
2. `PATH`不需要`export`，因为早在其他的地方，已经`export`过了！，`\$JAVA_HOME` 表示引用前面配置的 `JAVA_HOME` 变量，分隔符一定是冒号，**Windows**是分号,最后再引用原来的`PATH`的值
```
PATH=$JAVA_HOME/bin:$PATH
```
3. 配置以后，可以重新登录让配置生效，也可以使用`source`临时加载配置文件。使用`source`命令加载的配置，仅在当前`shell`有效，关闭以后失效。
```
source /etc/profile.d/jdk.sh
```
4. 查看`jdk`是否安装成功，一下两条命令成功则安装成功
```
java -version
javac -version
```
![](http://ojoba1c98.bkt.clouddn.com/img/javaDevEnv/javaVersion.png)

# 安装Scala环境

更上面安装JDK类似

1、去 *[官网](http://www.scala-lang.org/download/)* 下载最新地SDK

![](http://ojoba1c98.bkt.clouddn.com/img/javaDevEnv/scala-download.jpg)

2、解压到 `/usr/local` 目录，并创建软链接为 `scala` 

3、在 `/etc/profile.d` 目录下创建 `scala.sh` ，输入以下信息：

```
export SCALA_HOME=/usr/local/scala
PATH=$PATH:$SCALA_HOME/bin
```

4、查看是否安装成功
```
source /etc/profile.d/scala.sh
scala -version
```

![](http://ojoba1c98.bkt.clouddn.com/img/javaDevEnv/source-scala.jpg)

#  安装IDE

## Eclipse

直接在 *[Eclipse官方网站](https://www.eclipse.org/)* 下载相关版本Eclipse
解压
```
sudo tar zxvf eclipse-jee-mars-2-linux-gtk-x86_64.tar.gz -C ~/IDE
```
创建快捷方式
1\. 在终端中执行如下命令
```
sudo gedit /usr/share/applications/eclipse.desktop
```
2\. 粘贴并保存如下内容(注意更改相应的名字和目录)
```
[Desktop Entry] 
Name=Eclipse Mars.2 
Type=Application 
Exec=/home/ybd/IDE/eclipse 
Terminal=false 
Icon=/home/ybd/IDE/icon.xpm 
Comment=Integrated Development Environment 
NoDisplay=false 
Categories=Development;IDE; 
Name[en]=Eclipse Mars.2
```
**通用设置**
`window → preferences →`
* 设置字体：general → appearance → color and font → basic → text font
* 编辑器背景颜色：general →  editors → text editors → background color → `RGB:85,123,208`,`#C7EDCC`
* 工作空间字符编码：general → workspace 
* 作者签名：java → code style → code templates → types  签名快捷键：`alt + shift + j`

## MyEclipse
MyEclipse安装请看：***[Ubuntu16.04下MyEclipse安装与破解](/2017/ubuntu-myeclipse-crack/)***

## IntelliJ IDEA
之前听说过IDE[^1]，都是大公司用的，并没有用过
日后再研究补上
官网：*[http://www.jetbrains.com/idea/](http://www.jetbrains.com/idea/)*

新公司好多大牛，用的都是IDEA，于是乎“近墨者黑”，那么既然有机会跟大牛接触，我也开始真正意义上的学习IDEA了

### 安装
进过查阅，我选择官方的盒子下载：***[http://www.jetbrains.com/toolbox/app/?fromMenu](http://www.jetbrains.com/toolbox/app/?fromMenu)***
优点是可以自动更新
![](http://ojoba1c98.bkt.clouddn.com/img/javaDevEnv/idea.png)

### 激活

博主使用授权服务器，可以自己搭建，详情请看 ***[这里](/2017/note-of-learning-idea-under-ubuntu/#License)***

### 部署Tomcat

若是服务器版切换root用户解压到 `/opt/` 或者 `/usr/local/` 下
直接运行tomcat目录下`bin/start.sh`即可开启，前提是配置好`JDK`

桌面版个人使用就解压到`/home/{user}`目录下就可以了


# 安装MySQL以及GUI工具
![](http://ojoba1c98.bkt.clouddn.com/img/javaDevEnv/mysqlStartup.png)

***以`mysql5.7`以上版本为例 --> `mysql-5.7.10-linux-glibc2.5-x86_64.tar.gz`***

## 必须要先安装依赖的libaio才能正常按照mysql
```
sudo apt-get update
sudo apt-get install libaio-dev
```

## 创建用户组以及用户
```
sudo groupadd mysql
sudo useradd -r -g mysql -s /bin/false mysql
```

## 尽量把mysql安装到/usr/local目录下面
```
cd /usr/local
sudo cp /home/data/software/DataBase/mysql/mysql-5.7.10-linux-glibc2.5-x86_64.tar.gz ./
<-- 解压缩安装包 -->
sudo tar zxvf mysql-5.7.10-linux-glibc2.5-x86_64.tar.gz
<-- 创建软连接 -->
sudo ln -s mysql-5.7.10-linux-glibc2.5-x86_64 mysql
```

## 创建必须的目录和进行授权
```
cd mysql
sudo mkdir mysql-files
sudo chmod 770 mysql-files
sudo chown -R mysql .
sudo chgrp -R mysql .
```

## 执行安装脚本
```
sudo bin/mysqld --initialize --user=mysql   
sudo bin/mysql_ssl_rsa_setup
```

在初始化的时候，一定要仔细看屏幕，最后大概有一行:`[Note] A temporary password is generated for root@localhost: kklNBwkei1.t`
注意这是`root`的临时密码,记录下来以便后面修改密码！

## 重新对一些主要的目录进行授权，确保安全性

```
sudo chown -R root .
sudo chown -R mysql data mysql-files
```

## 从默认的模板创建配置文件，需要在文件中增加 skip-grant-tables ，以便启动mysql以后修改root用户的密码

```
sudo cp support-files/my-default.cnf ./my.cnf 
```

## 测试启动，修改密码

```
# 后台启动mysql
sudo bin/mysqld_safe --user=mysql &  
# 启动
./bin/mysql -u root -p
```
### 方式一
因为前面修改了`my.cnf`文件，增加了 `skip-grant-tables` 参数，所以不需要用户名即可登陆
进去后立即修改`root`用户的密码，密码的字段是 `authentication_string`
```
update mysql.user set authentication_string=password('root') where user='root';
```
修改密码后，再把`my.cnf`里面的 `skip-grant-tables` 去掉
### 方式二
修改密码也可以使用安装到时候提示到**随机密码**进行登录，然后使用下面到命令修改密码。
建议用下面的方式设置数据库的密码
```
alter user user() identified by 'root';
```

## 复制启动脚本到合适的位置
```
sudo cp support-files/mysql.server /etc/init.d/mysql
```

##  (Optional)增加自动启动

``` 
sudo update-rc.d -f mysql defaults
```

## 增加`mysql`命令的路径到`PATH`环境变量

```
sudo touch /etc/profile.d/mysql.sh
sudo chmod 777 /etc/profile.d/mysql.sh
sudo echo "PATH=/usr/local/mysql/bin:\$PATH" > /etc/profile.d/mysql.sh
sudo chmod 644 /etc/profile.d/mysql.sh
```
***<font color=red>到此，mysql的安装基本完成</font>***

## 修复乱码以及忽略大小写，找到MySQL文件里的`my.cnf`在末尾添加

```
lower_case_table_names=1
character_set_server=utf8
```

## 查看以及修改MySQL字符编码
### 查看
```
mysql> show variables like 'collation_%';

mysql> show variables like 'character_set_%';
```

### 修改
```
mysql> set character_set_client=utf8;
Query OK, 0 rows affected (0.00 sec)

mysql> set character_set_connection=utf8;
Query OK, 0 rows affected (0.00 sec)

mysql> set character_set_database=utf8;
Query OK, 0 rows affected (0.00 sec)

mysql> set character_set_results=utf8;
Query OK, 0 rows affected (0.00 sec)

mysql> set character_set_server=utf8;
Query OK, 0 rows affected (0.00 sec)

mysql> set character_set_system=utf8;
Query OK, 0 rows affected (0.01 sec)

mysql> set collation_connection=utf8_general_ci;
Query OK, 0 rows affected (0.01 sec)

mysql> set collation_database=utf8mb4_general_ci;
Query OK, 0 rows affected (0.01 sec)

mysql> set collation_server=utf8mb4_general_ci;
Query OK, 0 rows affected (0.01 sec)
```

## 如果登录mysql出现以下错误
![](http://ojoba1c98.bkt.clouddn.com/img/javaDevEnv/mysql-problom.png)
**则可能配置未加载或服务未启动，请重启系统，然后启动mysql服务**
```
sudo service mysql start
```

结束`mysql`服务
```
sudo service mysql stop
```

## 开启远程链接
链接mysql后：
```
use mysql

// 下面两个root分别是帐号密码
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;
// 刷新特权
flush privileges;
// 查看修改是否成功
select host,user from user;
```


## 附加：基于Docker
### 拉取镜像

```
docker pull mysql:5.7
```

### 运行实例

```
MYSQL=/home/ybd/data/docker/mysql && docker run --name=mysql -p 3306:3306  -v $MYSQL/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root -d mysql --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --sql-mode=STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION --lower-case-table-names=1
```

### 终端客户端

```
sudo apt-get install mysql-client

// 链接
mysql -h 127.0.0.1 -P 3306 -u root -p
```



# Navicat Premium

## 破解

1. 到*[官网](https://www.navicat.com/download)*下载对应系统版本，这里选择linux版本，并解压

2. 到*[Github](https://github.com/DoubleLabyrinth/navicat-keygen/releases)*下载注册机，并解压

   CHS - > Navicat简体中文版。
   CHT - > Navicat繁体中文版。
   ENG - > Navicat英文版

3.  安装wine

   ```
   sudo add-apt-repository ppa:ubuntu-wine/ppa
   sudo apt-get update
   sudo apt-get install wine1.8
   ```

4. 进入注册机解压目录，在此目录下打开命令窗口输入

   ```
   wine navicat-patcher.exe <navicat.exe path>
   ```

   `<navicat.exe path>`就是`navicat.exe`的路径，最好是完整的。

   可能会出现N个error日志信息不用鸟他 能正常success就行
   之后在当前目录下会生成对应的私钥文件`RegPrivateKey.pem`

5. 接着再用`navicat-keygen.exe`生成注册码，使用命令

   ```
   wine navicat-keygen.exe  RegPrivateKey.pem
   ```

   先填名字和组织名称，之后会生成一个序列号，并要求填入请求码。

   **打开navicat，然后断网**

6. 在注册界面填入序列号，然后激活。这时会提示要手动激活，ok就选这个
   接下来会有请求码，复制然后贴入控制台，就可以得到注册码了。

![](http://ojoba1c98.bkt.clouddn.com/img/javaDevEnv/navicat-patch.png)

![](http://ojoba1c98.bkt.clouddn.com/img/javaDevEnv/navicat12.png)


## 创建快捷方式

```
cd /usr/share/applications/
sudo touch navicat.desktop
sudo vi navicat.desktop
```

加入以下内容
```
[Desktop Entry]
Encoding=UTF-8
Name=Navicat
Comment=The Smarter Way to manage dadabase
Exec=/bin/sh "/home/ybd/Data/soft/application/navicat112_mysql_en_x64/start_navicat"
Icon=/home/ybd/Data/soft/application/navicat112_mysql_en_x64/Navicat/navicat.png
Categories=Application;Database;MySQL;navicat
Version=1.0
Type=Application
Terminal=0
```

> 参考：***[https://www.52pojie.cn/thread-705020-1-1.html]( https://www.52pojie.cn/thread-705020-1-1.html)***

## 后台运行

```
nohup /home/ybd/data/application/navicat/navicat120_premium_en_x64/start_navicat > /dev/null 2>&1 &
```

# 安装Redis

## 安装
终端执行：
```
sudo apt-get update
sudo apt-get install redis-server
```

## 启动
```
redis-server
```

## 查看是否启动成功
```
redis-cli
```

## HelloWorld
```
set k1 helloword
get k1
```

## 配置相关
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
```
➜  ~ sudo find /etc -name redis.conf
/etc/redis/redis.conf
➜  ~ sudo gedit /etc/redis/redis.conf
```
找到`bind 127.0.0.1`注释掉
注释掉本机,局域网内的所有计算机都能访问。
`band localhost` 只能本机访问,局域网内计算机不能访问。
`bind 局域网IP` 只能局域网内IP的机器访问, 本地localhost都无法访问。

博主选择将`bind 127.0.0.1` 改成了`bind 0.0.0.0`

## 开启发布订阅监听
还是修改`redis.conf`文件，找到`notify-keyspace-events ""`，修改为`notify-keyspace-events Ex`或者`notify-keyspace-events AKE`，然后重启。

## 附加1：基于Docker

拉取镜像：

```
docker pull redis:latest
```

运行实例：

```
REDIS=/home/ybd/data/docker/redis && docker run -p 6379:6379 --restart=always -v $REDIS/redis.conf:/usr/local/etc/redis/redis.conf -v $REDIS/data:/data --name redis -d redis redis-server /usr/local/etc/redis/redis.conf --appendonly yes
```

安装链接工具：

```
sudo apt-get install redis-tools

// 链接
redis-cli
```

## 附加2：Redis常用命令

### 连接操作命令

- `quit`：关闭连接（connection）
- `auth`：简单密码认证
- `help cmd`： 查看cmd帮助，例如：help quit

### 持久化

- `save`：将数据同步保存到磁盘
- `bgsave`：将数据异步保存到磁盘
- `lastsave`：返回上次成功将数据保存到磁盘的Unix时戳
- `shutdown`：将数据同步保存到磁盘，然后关闭服务

### 远程服务控制

- `info`：提供服务器的信息和统计
- `monitor`：实时转储收到的请求
- `slaveof`：改变复制策略设置
- `config`：在运行时配置Redis服务器

### 对key操作的命令

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

### String

- `set(key, value)`：给数据库中名称为key的string赋予值value
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

### List

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

### Set

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

### Hash

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


## 附加3：慢查询查看

> Redis 通过 `slowlog-log-slower-than` 和 `slowlog-max-len` 分别配置慢查询的阈值，以及慢查询记录的日志长度。 `slowlog-log-slower-than` 默认值 10*1000 **微秒**，当命令执行时间查过设定时，那么将会被记录在慢查询日志中。如果`slowlog-log-slower-than=0`会记录所有的命令，`slowlog-log-slower-than<0` 对于任何命令都不会进行记录。

参数设定：

```
config set slowlog-log-slower-than 20000
config set slowlog-max-len 1000
config rewrite
```

> 如果要 Redis 将配置**持久化**到本地配置文件，需要执行 `config rewrite` 命令.

# 安装Maven

## 下载
官网下载或者***[点击镜像获取](http://mirror.bit.edu.cn/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz)***

## 配置
1、下载解压到自己的指定的目录后，将命令放到`/bin`下：
```
sudo ln -s /自定义目录/apache-maven-3.3.9/bin/mvn /bin/mvn
```

2、添加环境变量
老规矩，在`/etc/profile.d`下创建一个`maven.sh`的文件：
```
sudo touch /etc/profile.d/maven.sh
sudo vi /etc/profile.d/maven.sh
```

输入以下内容：
```
export M2_HOME=/自定义目录/apache-maven-3.3.9
export PATH=${M2_HOME}/bin:$PATH
```

然后`source`一下：
```
source /etc/profile.d/maven.sh
```

查看是否配置成功：
```
mvn -v
```

输入内容如下：
```
Apache Maven 3.3.9 (bb52d8502b132ec0a5a3f4c09453c07478323dc5; 2015-11-11T00:41:47+08:00)
Maven home: /home/ybd/Data/application/maven/apache-maven-3.3.9
Java version: 1.8.0_65, vendor: Oracle Corporation
Java home: /usr/local/jdk1.8.0_65/jre
Default locale: zh_CN, platform encoding: UTF-8
OS name: "linux", version: "4.4.0-67-generic", arch: "amd64", family: "unix"
```

## 淘宝镜像

```
<mirrors>
	<mirror>
	  <id>alimaven</id>
	  <name>aliyun maven</name>
	  <url>http://maven.aliyun.com/nexus/content/groups/public/</url>
	  <mirrorOf>central</mirrorOf> 
	</mirror>
</mirrors>
```
# MongoDB
## 安装
```
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6

#下面命令针对ubuntu16.04版本，在其他ubuntu版本系统请查看MongoDB官网
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list

sudo apt-get update

sudo apt-get install -y mongodb-org
```

安装完成后查看版本：
```
mongo -version
```
![](http://ojoba1c98.bkt.clouddn.com/img/mongodb/mongodb-version.png)

启动、重新启动和关闭mongodb命令:
```
sudo service mongod start
sudo service mongod stop
sudo service mongod restart
```

查看是否启动成功:
```
sudo cat /var/log/mongodb/mongod.log
```
在 `mongod.log` 日志中若出现如下信息，说明启动成功:
```
[initandlisten] waiting for connections on port 27017
```

## MongoDB 卸载
删除 mongodb 包
```
sudo apt-get purge mongodb-org*
```
删除 MongoDB 数据库和日志文件
```
sudo rm -r /var/log/mongodb
sudo rm -r /var/lib/mongodb
```
## MongoDB 使用
shell命令模式 
输入`mongo`进入shell命令模式，默认连接的数据库是test数据库，命令如下：
```
➜  ~ mongo
```
常用操作命令：

`show dbs`：显示数据库列表 
`show collections`：显示当前数据库中的集合（类似关系数据库中的表table） 
`show users`：显示所有用户 
`use yourDB`：切换当前数据库至yourDB 
`db.help()` ：显示数据库操作命令 
`db.yourCollection.help()` ：显示集合操作命令，yourCollection是集合名

官方文档：***[https://docs.mongodb.com/master/tutorial/install-mongodb-on-ubuntu/](https://docs.mongodb.com/master/tutorial/install-mongodb-on-ubuntu/)***

## GUI客户端
***[Robomongo](https://www.mongodb.com/download-center#community)***

# RabbitMQ

选择Docker安装。。。不折腾了。。

```
docker pull rabbitmq:3-management
docker run -d --name rabbitmq -p 5673:5672 -p 15673:15672 --restart=always rabbitmq:3-management
```

(注意版本，是`management`)

浏览器打开`localhost:15673`，默认帐号密码都是`guest`

![](http://ojoba1c98.bkt.clouddn.com/img/javaDevEnv/rabbitmq.png)

集群：[https://www.jianshu.com/p/624871c646b9](https://www.jianshu.com/p/624871c646b9)

# Kafka&Zookeeper集群

`docker-compose.yml`:

```
version: '3'
services:
  kafka1:
    image: wurstmeister/kafka:1.0.0
    depends_on:
      - zoo1
      - zoo2
      - zoo3
    ports:
      - "9092:9092"
    environment:
      KAFKA_LOG_DIRS: /kafka
      KAFKA_BROKER_ID: 1
      KAFKA_CREATE_TOPICS: test:6:1
      KAFKA_ADVERTISED_HOST_NAME: 192.168.6.113
      KAFKA_ADVERTISED_PORT: 9092
      KAFKA_ZOOKEEPER_CONNECT: zoo1:2181,zoo2:2181,zoo3:2181

  kafka2:
    image: wurstmeister/kafka:1.0.0
    depends_on:
      - zoo1
      - zoo2
      - zoo3
    ports:
      - "9093:9092"
    environment:
      KAFKA_LOG_DIRS: /kafka
      KAFKA_BROKER_ID: 2
      KAFKA_ADVERTISED_HOST_NAME: 192.168.6.113
      KAFKA_ADVERTISED_PORT: 9093
      KAFKA_ZOOKEEPER_CONNECT: zoo1:2181,zoo2:2181,zoo3:2181

  kafka3:
    image: wurstmeister/kafka:1.0.0
    depends_on:
      - zoo1
      - zoo2
      - zoo3
    ports:
      - "9094:9092"
    environment:
      KAFKA_LOG_DIRS: /kafka
      KAFKA_BROKER_ID: 3
      KAFKA_ADVERTISED_HOST_NAME: 192.168.6.113
      KAFKA_ADVERTISED_PORT: 9094
      KAFKA_ZOOKEEPER_CONNECT: zoo1:2181,zoo2:2181,zoo3:2181

  zoo1:
    image: zookeeper:latest
    environment:
      ZOO_MY_ID: 1
      SERVERS: zoo1,zoo2,zoo3
    ports:
      - "2181:2181"
      - "2888"
      - "3888"

  zoo2:
    image: zookeeper:latest
    environment:
      ZOO_MY_ID: 2
      SERVERS: zoo1,zoo2,zoo3
    ports:
      - "2182:2181"
      - "2888"
      - "3888"

  zoo3:
    image: zookeeper:latest
    environment:
      ZOO_MY_ID: 3
      SERVERS: zoo1,zoo2,zoo3
    ports:
      - "2183:2181"
      - "2888"
      - "3888"
```

启动：
```
docker-compose up -d
```

测试：

```
#创建主题
docker exec -it ${CONTAINER_ID} /opt/kafka/bin/kafka-topics.sh --create --zookeeper zoo1:2181 --replication-factor 1 --partitions 1 --topic test

#查看topic列表
docker exec -it ${CONTAINER_ID} /opt/kafka/bin/kafka-topics.sh --list --zookeeper zoo1:2181

#生产者
docker exec -it ${CONTAINER_ID} /opt/kafka/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic test

#消费者
docker exec -it ${CONTAINER_ID} /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test --from-beginning
```



# 搭建ngrok配置

![](http://ojoba1c98.bkt.clouddn.com/img/javaDevEnv/ngrok_p1.jpg)
>ngrok 是一个反向代理，通过在公共的端点和本地运行的 Web 服务器之间建立一个安全的通道。ngrok 可捕获和分析所有通道上的流量，便于后期分析和重放。可以被使用来进行微信借口的本地调试。在ngrok被墙之后，我们需要通过ngrok开源的源码自行搭建ngrok服务。

参考地址：***[Ubuntu下配置安装ngrok](http://blog.csdn.net/cloume/article/details/51209493)***
搞了一上午，服务运行起来了，客户端也运行起来了，浏览器就是访问不到！！
不知道是不是因为个人电脑没有域名所以才访问不到，日后再深究。
无奈，还好互联网开源精神无处不在，某大神搭建的ngrok：
***[http://www.qydev.com/](http://www.qydev.com/)***
客户端和教程都在里面哦。

**Update:**Ngrok已搭建成功～ ，记录于***[self-hosted-build-ngrok-server](/2017/self-hosted-build-ngrok-server/)***


<p id="div-border-left-purple">**其他tunnel的代理服务器**：
***[natapp.cn](http://natapp.cn)***
***[www.ngrok.cc](http://www.ngrok.cc)***
</p>


[^1]: IDEA 全称IntelliJ IDEA，是java语言开发的集成环境，IntelliJ在业界被公认为最好的java开发工具之一，尤其在智能代码助手、代码自动提示、重构、J2EE支持、Ant、JUnit、CVS整合、代码审查、 创新的GUI设计等方面的功能可以说是超常的。IDEA是JetBrains公司的产品，这家公司总部位于捷克共和国的首都布拉格，开发人员以严谨著称的东欧程序员为主



