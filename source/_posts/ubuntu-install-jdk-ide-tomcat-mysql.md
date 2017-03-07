---
title: Ubuntu的Java开发环境基本搭建(JDK+IDE+Tomcat+MySQL+Navicat+Redis)
date: 2017-01-20 11:31:22
categories: [OperatingSystem,Ubuntu]
tags: [Ubuntu,IDE,JDK,Tomcat]
---
# 前言
最近公司的电脑由于不明原因老是奔溃，重装过两次，在家里也比较喜欢折腾系统，为了不用每次都度娘谷歌，记录下来，一条龙走过。博主是搞爪哇开发的，那么以下搭建针对的是爪哇环境开发

<!--more-->
# 安装JDK以及配置环境变量
## 安装JDK
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

## 配置环境变量

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
MyEclipse安装请看：***[Ubuntu16.04下MyEclipse安装与破解](http://ookamiantd.top/20170111/ubuntu-myeclipse-crack/)***

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
问度娘，博主也是度娘要的激活码


# 部署Tomcat
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
default-character-set=utf8
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
# 安装Navicat For Mysql
到*[官网](https://www.navicat.com/download)*下载对应系统版本
解压到适应文件夹
解压后，进入解压后的目录运行命令：

```
./start_navicat
```
OK，这样就完啦
连接上数据库后里面的中文数据是乱码,把`Ubuntu`的字符集修改为`zh_CN.utf8`就行了,修改方法:
1.查看系统支持的字符集: `locale -a` 
2.到start_navicat修改字符集: `export LANG=zh_CN.utf8`

## <font color=red>破解方案</font> 
第一次执行`start_navicat`时，会在用户主目录下生成一个名为`.navicat`的隐藏文件夹。
```
cd /home/ybd/.navicat/  
```
此文件夹下有一个system.reg文件
```
rm system.reg
```
把此文件删除后，下次启动`navicat` 会重新生成此文件，30天试用期会按新的时间开始计算。
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

[^1]: IDEA 全称IntelliJ IDEA，是java语言开发的集成环境，IntelliJ在业界被公认为最好的java开发工具之一，尤其在智能代码助手、代码自动提示、重构、J2EE支持、Ant、JUnit、CVS整合、代码审查、 创新的GUI设计等方面的功能可以说是超常的。IDEA是JetBrains公司的产品，这家公司总部位于捷克共和国的首都布拉格，开发人员以严谨著称的东欧程序员为主





