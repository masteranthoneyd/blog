---
title: Ubuntu的Java开发环境基本搭建
date: 2017-01-20 11:31:22
categories: [OperatingSystem,Ubuntu]
tags: [Ubuntu,IDE,JDK,Tomcat]
---
![](https://cdn.yangbingdong.com/img/javaDevEnv/maxresdefault.jpg)

# 前言

最近公司的电脑由于不明原因老是奔溃, 重装过两次, 在家里也比较喜欢折腾系统, 为了不用每次都度娘谷歌, 记录下来, 一条龙走过. 博主是搞爪哇开发的, 那么以下搭建针对的是爪哇环境开发

<!--more-->
# JDK以及配置环境变量

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

**注意: 这个安装可能有点慢, 建议使用代理.**

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

安装之前当然是老规矩地下载`jdk`: *[Oracle JDK官方下载](http://www.oracle.com/technetwork/java/javase/downloads/index.html)*

```
# 把jdk的文件移动到 /usr/local/ 目录下
sudo mv ~/jdk*.tar.gz /usr/local/
# 解压文件
cd /usr/local/
# sudo tar -zxvf jdk-8u101-linux-x64.tar.gz
# 创建软链接
sudo ln -s jdk1.8.0_101 jdk
```

***如需更换`jdk`, 删除旧版本的软链接, 重新创建软链接指向新版即可***

```
sudo rm -rf jdk
sudo ln -s jdk* jdk
```

### 配置环境变量

- 放到 `/usr/local` 里面的程序, 建议使用系统变量. 
- 用户变量
    `~/.profile` 文件是用户的私有配置文件
    `~/.bashrc`  是在bash里面使用的私有配置文件, 优先级在 `.profile` 文件之后
- 系统变量
    `/etc/profile` 文件是系统的公用配置文件
    `/etc/bash.bashrc` 是`bash`专用的配置文件, 优先级在 `profile` 文件之后
- 系统变量的配置, 不建议修改前面说到的两个文件, 而是建议在 ***`/etc/profile.d/`*** 目录下, 创建一个 `.sh` 结尾 的文件. 

```
sudo vi /etc/profile.d/jdk.sh
```
**环境变量的配置内容如下: **

1. 设置一个名为`JAVA_HOME`的变量, 并且使用`export`命令导出为环境变量, 如果不使用 `export` , 仅在当前`shell`里面有效
```
export JAVA_HOME=/usr/local/jdk
```
2. `PATH`不需要`export`, 因为早在其他的地方, 已经`export`过了！, `\$JAVA_HOME` 表示引用前面配置的 `JAVA_HOME` 变量, 分隔符一定是冒号, **Windows**是分号,最后再引用原来的`PATH`的值
```
export PATH=$JAVA_HOME/bin:$PATH
```
3. 配置以后, 可以重新登录让配置生效, 也可以使用`source`临时加载配置文件. 使用`source`命令加载的配置, 仅在当前`shell`有效, 关闭以后失效. 
```
source /etc/profile.d/jdk.sh
```
4. 查看`jdk`是否安装成功, 一下两条命令成功则安装成功
```
java -version
javac -version
```
![](https://cdn.yangbingdong.com/img/javaDevEnv/javaVersion.png)

# Scala

* 下载 ***[官方 SDK](http://www.scala-lang.org/download/)***

![](https://cdn.yangbingdong.com/img/javaDevEnv/scala-download.jpg)

* 解压到 `/usr/local` 目录, 并创建软链接为 `scala` 

* 在 `/etc/profile.d` 目录下创建 `scala.sh` , 内容如下: 

```
export SCALA_HOME=/usr/local/scala
export PATH=$PATH:$SCALA_HOME/bin
```

* 查看是否安装成功

```
source /etc/profile.d/scala.sh
scala -version
```

![](https://cdn.yangbingdong.com/img/javaDevEnv/source-scala.jpg)

# Groovy

* 下载 ***[官方 SDK](http://www.groovy-lang.org/download.html)***
* 解压到 `/usr/local` 目录下, 并创建 `groovy` 软连接
* 在 `/etc/profile.d` 目录下创建 `groovy.sh`, 内容如下:

```bash
export GROOVY_HOME=/usr/local/groovy
export PATH=$PATH:$GROOVY_HOME/bin
```

* 验证:

```bash
source /etc/profile.d/groovy.sh
groovy -v
```

# Go

下载最新的 Go 的二进制 Release: ***[https://golang.org/dl/](https://golang.org/dl/)***

解压:

```
sudo tar -C /usr/local -xzf go1.15.6.linux-amd64.tar.gz
```

添加变量:

```
sudo tee /etc/profile.d/go.sh <<- EOF
export PATH=$PATH:/usr/local/go/bin
EOF
```

**智能补全**:

修改 `.zshrc`: 

```
plugins=(... golang)
```

**添加 pkg 代理**

单次生效:

```
export GO111MODULE="on"
go env -w GOPROXY="https://goproxy.io,direct"
```

永久生效, 在 `/etc/profile.d/go.sh` 追加:

```
export GOPROXY=https://goproxy.io
```

运行Hello world:

```
go get github.com/golang/example/hello
```

之后 `hello` 命令会下载到 `${HOME}/go/bin` 中.

解决 `unrecognized import path "golang.org/x/sys/unix`:

```
mkdir -p $GOPATH/src/golang.org/x/
cd !$
git clone https://github.com/golang/net.git
git clone https://github.com/golang/sys.git
git clone https://github.com/golang/tools.git
```

#  IDE

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
* 设置字体: general → appearance → color and font → basic → text font
* 编辑器背景颜色: general →  editors → text editors → background color → `RGB:85,123,208`,`#C7EDCC`
* 工作空间字符编码: general → workspace 
* 作者签名: java → code style → code templates → types  签名快捷键: `alt + shift + j`

## MyEclipse
MyEclipse安装请看: ***[Ubuntu16.04下MyEclipse安装与破解](/2017/ubuntu-myeclipse-crack/)***

## IntelliJ IDEA
之前听说过IDE[^1], 都是大公司用的, 并没有用过
日后再研究补上
官网: *[http://www.jetbrains.com/idea/](http://www.jetbrains.com/idea/)*

新公司好多大牛, 用的都是IDEA, 于是乎“近墨者黑”, 那么既然有机会跟大牛接触, 我也开始真正意义上的学习IDEA了

### 安装
通过官方提供的 ***[Toolbox App](http://www.jetbrains.com/toolbox/app)*** 进行安装, 可以很方便地进行版本管理:
![](https://cdn.yangbingdong.com/img/javaDevEnv/idea.png)

### 部署Tomcat

若是服务器版切换root用户解压到 `/opt/` 或者 `/usr/local/` 下
直接运行tomcat目录下`bin/start.sh`即可开启, 前提是配置好`JDK`

桌面版个人使用就解压到`/home/{user}`目录下就可以了

# MySQL以及GUI工具

## 基于Docker安装

### 拉取镜像

```
docker pull mysql:5.7
```

### 运行实例

```
MYSQL=/home/ybd/data/docker/mysql && \
docker run --name=mysql -p 3306:3306  \
-v $MYSQL/data:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=root -d mysql \
--character-set-server=utf8mb4 \
--collation-server=utf8mb4_unicode_ci \
--sql-mode=STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION \
--lower-case-table-names=1
```

### 终端链接

```
sudo apt-get install mysql-client

// 链接
mysql -h 127.0.0.1 -P 3306 -u root -p
```

![](https://cdn.yangbingdong.com/img/javaDevEnv/mysqlStartup.png)

## 手动折腾安装

***以`mysql5.7`以上版本为例 --> `mysql-5.7.10-linux-glibc2.5-x86_64.tar.gz`***

### 必须要先安装依赖的libaio才能正常按照mysql

```
sudo apt-get update
sudo apt-get install libaio-dev
```

### 创建用户组以及用户

```
sudo groupadd mysql
sudo useradd -r -g mysql -s /bin/false mysql
```

### 尽量把mysql安装到/usr/local目录下面

```
cd /usr/local
sudo cp /home/data/software/DataBase/mysql/mysql-5.7.10-linux-glibc2.5-x86_64.tar.gz ./
<-- 解压缩安装包 -->
sudo tar zxvf mysql-5.7.10-linux-glibc2.5-x86_64.tar.gz
<-- 创建软连接 -->
sudo ln -s mysql-5.7.10-linux-glibc2.5-x86_64 mysql
```

### 创建必须的目录和进行授权

```
cd mysql
sudo mkdir mysql-files
sudo chmod 770 mysql-files
sudo chown -R mysql .
sudo chgrp -R mysql .
```

### 执行安装脚本

```
sudo bin/mysqld --initialize --user=mysql   
sudo bin/mysql_ssl_rsa_setup
```

在初始化的时候, 一定要仔细看屏幕, 最后大概有一行:`[Note] A temporary password is generated for root@localhost: kklNBwkei1.t`
注意这是`root`的临时密码,记录下来以便后面修改密码！

### 重新对一些主要的目录进行授权, 确保安全性

```
sudo chown -R root .
sudo chown -R mysql data mysql-files
```

### 从默认的模板创建配置文件, 需要在文件中增加 skip-grant-tables , 以便启动mysql以后修改root用户的密码

```
sudo cp support-files/my-default.cnf ./my.cnf 
```

### 测试启动, 修改密码

```
# 后台启动mysql
sudo bin/mysqld_safe --user=mysql &  
# 启动
./bin/mysql -u root -p
```
#### 方式一

因为前面修改了`my.cnf`文件, 增加了 `skip-grant-tables` 参数, 所以不需要用户名即可登陆
进去后立即修改`root`用户的密码, 密码的字段是 `authentication_string`
```
update mysql.user set authentication_string=password('root') where user='root';
```
修改密码后, 再把`my.cnf`里面的 `skip-grant-tables` 去掉
#### 方式二

修改密码也可以使用安装到时候提示到**随机密码**进行登录, 然后使用下面到命令修改密码. 
建议用下面的方式设置数据库的密码
```
alter user user() identified by 'root';
```

### 复制启动脚本到合适的位置

```
sudo cp support-files/mysql.server /etc/init.d/mysql
```

### (Optional)增加自动启动

``` 
sudo update-rc.d -f mysql defaults
```

### 增加`mysql`命令的路径到`PATH`环境变量

```
sudo touch /etc/profile.d/mysql.sh
sudo chmod 777 /etc/profile.d/mysql.sh
sudo echo "PATH=/usr/local/mysql/bin:\$PATH" > /etc/profile.d/mysql.sh
sudo chmod 644 /etc/profile.d/mysql.sh
```
***<font color=red>到此, mysql的安装基本完成</font>***

### 修复乱码以及忽略大小写, 找到MySQL文件里的`my.cnf`在末尾添加

```
lower_case_table_names=1
character_set_server=utf8
```

### 查看以及修改MySQL字符编码

#### 查看

```
mysql> show variables like 'collation_%';

mysql> show variables like 'character_set_%';
```

#### 修改

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

### 如果登录mysql出现以下错误

![](https://cdn.yangbingdong.com/img/javaDevEnv/mysql-problom.png)
**则可能配置未加载或服务未启动, 请重启系统, 然后启动mysql服务**
```
sudo service mysql start
```

结束`mysql`服务
```
sudo service mysql stop
```

### 开启远程链接

链接mysql后: 
```
use mysql

// 下面两个root分别是帐号密码
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;
// 刷新特权
flush privileges;
// 查看修改是否成功
select host,user from user;
```

## Mysql GUI

### 传统终端客户端

```
sudo apt-get install mysql-client

// 链接
mysql -h 127.0.0.1 -P 3306 -u root -p
```

### 智能补全命令客户端

这个一个智能补全并且高亮语法的终端客户端 ***[mycli](https://github.com/dbcli/mycli)***

![](https://cdn.yangbingdong.com/img/mysql-related-learning/mycli.gif)

安装: 

```
sudo apt install mycli
```

使用: 

```
$ mycli --help
Usage: mycli [OPTIONS] [DATABASE]

  A MySQL terminal client with auto-completion and syntax highlighting.

  Examples:
    - mycli my_database
    - mycli -u my_user -h my_host.com my_database
    - mycli mysql://my_user@my_host.com:3306/my_database

Options:
  -h, --host TEXT               Host address of the database.
  -P, --port INTEGER            Port number to use for connection. Honors
                                $MYSQL_TCP_PORT.
  -u, --user TEXT               User name to connect to the database.
  -S, --socket TEXT             The socket file to use for connection.
  -p, --password TEXT           Password to connect to the database.
  --pass TEXT                   Password to connect to the database.
  --ssl-ca PATH                 CA file in PEM format.
  --ssl-capath TEXT             CA directory.
  --ssl-cert PATH               X509 cert in PEM format.
  --ssl-key PATH                X509 key in PEM format.
  --ssl-cipher TEXT             SSL cipher to use.
  --ssl-verify-server-cert      Verify server's "Common Name" in its cert
                                against hostname used when connecting. This
                                option is disabled by default.
  -v, --version                 Output mycli's version.
  -D, --database TEXT           Database to use.
  -R, --prompt TEXT             Prompt format (Default: "\t \u@\h:\d> ").
  -l, --logfile FILENAME        Log every query and its results to a file.
  --defaults-group-suffix TEXT  Read MySQL config groups with the specified
                                suffix.
  --defaults-file PATH          Only read MySQL options from the given file.
  --myclirc PATH                Location of myclirc file.
  --auto-vertical-output        Automatically switch to vertical output mode
                                if the result is wider than the terminal
                                width.
  -t, --table                   Display batch output in table format.
  --csv                         Display batch output in CSV format.
  --warn / --no-warn            Warn before running a destructive query.
  --local-infile BOOLEAN        Enable/disable LOAD DATA LOCAL INFILE.
  --login-path TEXT             Read this path from the login file.
  -e, --execute TEXT            Execute command and quit.
  --help                        Show this message and exit.
```

### Navicat Premium

#### 破解

1. 到*[官网](https://www.navicat.com/download)*下载对应系统版本, 这里选择linux版本, 并解压

2. 到*[Github](https://github.com/DoubleLabyrinth/navicat-keygen/releases)*下载注册机, 并解压

3.  安装wine

   ```
   sudo add-apt-repository ppa:ubuntu-wine/ppa
   sudo apt-get update
   sudo apt-get install wine1.8
   ```

4. 进入注册机解压目录, 在此目录下打开命令窗口输入

   ```
   wine navicat-patcher.exe <Navicat installation path> ./RegPrivateKey.pem
   ```

   `<Navicat installation path>`就是Navicat中存放`navicat.exe`的根目录. 

5. 接着再用`navicat-keygen.exe`生成注册码, 使用命令

   ```
   wine navicat-keygen.exe -text ./RegPrivateKey.pem
   ```

   你会被要求选择Navicat产品类别、语言以及输入主版本号. 之后会随机生成一个序列号. 

   产品选择Premium, 语言选择Simplified Chinese, 版本输入12（当然, 因为下载的是Navicat Premium12 简体中文版）

   然后会出现一个序列号: 

   ```
   Serial number:
   NAVA-DHCN-P2OI-DV46
   ```

   接下来填写`用户名`和`组织名`, 随便写. 

   **然后打开navicat, 然后断网**

6. 在注册界面填入序列号, 然后激活. 这时会提示要手动激活, ok就选这个. 

7. 一般来说在线激活肯定会失败, 这时候Navicat会询问你是否`手动激活`, 直接选吧. 

8. 在`手动激活`窗口你会得到一个请求码, 复制它并把它粘贴到keygen里. 最后别忘了连按至少两下回车结束输入. 

   ```
   Your name: DoubleLabyrinth
   Your organization: DoubleLabyrinth

   Input request code (in Base64), input empty line to end:
   q/cv0bkTrG1YDkS+fajFdi85bwNVBD/lc5jBYJPOSS5bfl4DdtnfXo+RRxdMjJtEcYQnvLPi2LF0
   OB464brX9dqU29/O+A3qstSyhBq5//iezxfu2Maqca4y0rVtZgQSpEnZ0lBNlqKXv7CuTUYCS1pm
   tEPgwJysQTMUZf7tu5MR0cQ+hY/AlyQ9iKrQAMhHklqZslaisi8VsnoIqH56vfTyyUwUQXrFNc41
   qG5zZNsXu/NI79JOo7qTvcFHQT/k5cTadbKTxY+9c5eh+nF3JR7zEa2BDDfdQRLNvy4DTSyxdYXd
   sAk/YPU+JdWI+8ELaa0SuAuNzr5fEkD6NDSG2A==

   Request Info:
   {"K":"NAVADHCNP2OIDV46", "DI":"Y2eJk9vrvfGudPG7Mbdn", "P":"WIN 8"}

   Response Info:
   {"K":"NAVADHCNP2OIDV46","DI":"Y2eJk9vrvfGudPG7Mbdn","N":"DoubleLabyrinth","O":"DoubleLabyrinth","T":1537630251}

   License:
   oyoMYr9cfVGXeT7F1dqBwHsB/vvWj6SUL6aR+Kzb0lm5IyEj1CgovuSq+qMzFfx+
   oHMFaGKFg6viOY2hfJcrO2Vdq0hXZS/B/Ie3jBS2Ov37v8e3ufVajaH+wLkmEpLd
   xppCVLkDQjIHYR2IPz5s/L/RuWqDpEY4TPmGFF6q+xQMnqQA3vXPyG+JYMARXLru
   Y1gCDLN30v3DpyOeqKmFjUqiHK5h8s0NYiH2OpMyaCpi12JsF23miP89ldQp3+SJ
   8moo0cNGy7sFp2gX9ol2zVoo7qxfYlLl03f7CALJ6im0sx4yBsmlzFDdvpQUbXk8
   YZ5rT4LML2Fx6Wgnnklb5g==
   ```

9. 如果不出意外, 你会得到一个看似用Base64编码的激活码. 直接复制它, 并把它粘贴到Navicat的`手动激活`窗口, 最后点`激活`按钮. 如果没什么意外的话应该能成功激活. 

![](https://cdn.yangbingdong.com/img/javaDevEnv/navicat12.png)

#### 创建快捷方式

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

> 参考: ***[https://www.52pojie.cn/thread-705020-1-1.html]( https://www.52pojie.cn/thread-705020-1-1.html)***

#### 后台运行

```
nohup /home/ybd/data/application/navicat/navicat120_premium_en_x64/start_navicat > /dev/null 2>&1 &
```
# Redis

***[请看这里](/2018/redis-relate-note.html)***


# Maven

## 下载
官网下载或者***[点击镜像获取](http://mirror.bit.edu.cn/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz)***

## 配置
1、下载解压到自己的指定的目录后, 将命令放到`/bin`下: 
```
sudo ln -s /自定义目录/apache-maven-3.3.9/bin/mvn /bin/mvn
```

2、添加环境变量
老规矩, 在`/etc/profile.d`下创建一个`maven.sh`的文件: 
```
sudo touch /etc/profile.d/maven.sh
sudo vi /etc/profile.d/maven.sh
```

输入以下内容: 
```
export M2_HOME=/自定义目录/apache-maven-3.3.9
export PATH=${M2_HOME}/bin:$PATH
```

然后`source`一下: 
```
source /etc/profile.d/maven.sh
```

查看是否配置成功: 
```
mvn -v
```

输入内容如下: 
```
Apache Maven 3.3.9 (bb52d8502b132ec0a5a3f4c09453c07478323dc5; 2015-11-11T00:41:47+08:00)
Maven home: /home/ybd/Data/application/maven/apache-maven-3.3.9
Java version: 1.8.0_65, vendor: Oracle Corporation
Java home: /usr/local/jdk1.8.0_65/jre
Default locale: zh_CN, platform encoding: UTF-8
OS name: "linux", version: "4.4.0-67-generic", arch: "amd64", family: "unix"
```

## 阿里镜像

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

#下面命令针对ubuntu16.04版本, 在其他ubuntu版本系统请查看MongoDB官网
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list

sudo apt-get update

sudo apt-get install -y mongodb-org
```

安装完成后查看版本: 
```
mongo -version
```
![](https://cdn.yangbingdong.com/img/mongodb/mongodb-version.png)

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
在 `mongod.log` 日志中若出现如下信息, 说明启动成功:
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
输入`mongo`进入shell命令模式, 默认连接的数据库是test数据库, 命令如下: 
```
➜  ~ mongo
```
常用操作命令: 

`show dbs`: 显示数据库列表 
`show collections`: 显示当前数据库中的集合（类似关系数据库中的表table） 
`show users`: 显示所有用户 
`use yourDB`: 切换当前数据库至yourDB 
`db.help()` : 显示数据库操作命令 
`db.yourCollection.help()` : 显示集合操作命令, yourCollection是集合名

官方文档: ***[https://docs.mongodb.com/master/tutorial/install-mongodb-on-ubuntu/](https://docs.mongodb.com/master/tutorial/install-mongodb-on-ubuntu/)***

## GUI客户端
***[Robomongo](https://www.mongodb.com/download-center#community)***

# RabbitMQ

选择Docker安装. . . 不折腾了. . 

```
docker pull rabbitmq:3-management
docker run -d --name rabbitmq -p 5673:5672 -p 15673:15672 --restart=always rabbitmq:3-management
```

(注意版本, 是`management`)

浏览器打开`localhost:15673`, 默认帐号密码都是`guest`

![](https://cdn.yangbingdong.com/img/javaDevEnv/rabbitmq.png)

集群: [https://www.jianshu.com/p/624871c646b9](https://www.jianshu.com/p/624871c646b9)

# Pip

```
sudo apt install python3-pip

// for Python 2
sudo apt install python-pip
```

# Kafka&Zookeeper集群

`docker-compose.yml`:

```yaml
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

启动: 
```
docker-compose up -d
```

测试: 

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

## Zookeeper UI

***[https://github.com/DeemOpen/zkui](https://github.com/DeemOpen/zkui)***

***[https://github.com/elkozmon/zoonavigator](https://github.com/elkozmon/zoonavigator)***

# Rinetd

Rinetd 是一个端口转发工具, 安装:

```
sudo apt install rinetd -y
```

配置文件 `/etc/rinetd.conf`:

```
#
# this is the configuration file for rinetd, the internet redirection server
#
# you may specify global allow and deny rules here
# only ip addresses are matched, hostnames cannot be specified here
# the wildcards you may use are * and ?
#
# allow 192.168.2.*
# deny 192.168.2.1?


#
# forwarding rules come here
#
# you may specify allow and deny rules after a specific forwarding rule
# to apply to only that forwarding rule
#
# bindadress    bindport  connectaddress  connectport


# logging information
logfile /var/log/rinetd.log

# uncomment the following line if you want web-server style logfile format
# logcommon
#绑定IP # 源端口号 # 目标地址 # 目标端口号
0.0.0.0 80 0.0.0.0 8080
```

操作:

```
sudo service rinetd [force-reload|reload|restart|start|stop]
```

应用场景之一: 手机APP调试

1. 将手机 wifi 代理设置为本地 rinetd 配置的端口, 比如上面的 80
2. 将服务起到 8080 端口即可
3. 修改 DNS 解析, 比如 APP 请求的地址是 api.xxx.com, 则将这个域名解析到本地, 并重启网络 `sudo /etc/init.d/networking restart`

# Ngrok

请看 ***[这里](/2017/self-hosted-build-ngrok-server/)***



[^1]: IDEA 全称IntelliJ IDEA, 是java语言开发的集成环境, IntelliJ在业界被公认为最好的java开发工具之一, 尤其在智能代码助手、代码自动提示、重构、J2EE支持、Ant、JUnit、CVS整合、代码审查、 创新的GUI设计等方面的功能可以说是超常的. IDEA是JetBrains公司的产品, 这家公司总部位于捷克共和国的首都布拉格, 开发人员以严谨著称的东欧程序员为主



