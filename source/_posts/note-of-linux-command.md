---
title: Ubuntu 常用命令
date: 2017-09-20 18:05:10
categories: [OperatingSystem,Ubuntu]
tags: [Ubuntu]
---

![](https://cdn.yangbingdong.com/img/node-of-ubuntu-command/ubuntu-logo.png)

# Preface

> =.= 这里只记录一些个人比较常用到的[*Ubuntu*](https://www.ubuntu.com)命令


<!--more-->
# SSH相关

## 安装SSH

```
sudo apt install ssh
sudo apt install openssh-server
```

查看启动成功：`ps -e|grep ssh`，如果看到`sshd`那代表成功了，如果没有，执行：

```
sudo/etc/init.d/ssh start
```

ssh的配置文件位于`/etc/ssh/sshd_config`，修改后需要重启ssh：

```
sudo /etc/init.d/sshresart  
```

## 保持长连接
只需要在`ssh`命令后加上发送心跳即可：
```
ssh -o ServerAliveInterval=30 root@123.456.88 -p 2333
```

## 生成SSH密钥和公钥
打开终端，使用下面的`ssh-keygen`来生成`RSA`密钥和公钥。`-t`表示type，就是说要生成`RSA`加密的钥匙：
```shell
ssh-keygen -t rsa -C "your_email@youremail.com"
```
`RSA`也是默认的加密类型，所以你也可以只输入`ssh-keygen`，默认的`RSA`长度是2048位，如果你非常注重安全，那么可以指定4096位的长度：
```shell
ssh-keygen -b 4096 -t rsa -C "your_email@youremail.com"
```
生成SSH Key的过程中会要求你指定一个文件来保存密钥，按`Enter`键使用默认的文件就行了，然后需要输入一个密码来加密你的SSH Key，密码至少要20位长度，SSH密钥会保存在`home`目录下的`.ssh/id_rsa`文件中，SSH公钥保存在`.ssh/id_rsa.pub`文件中。
```
Generating public/private rsa key pair.
Enter file in which to save the key (/home/matrix/.ssh/id_rsa): 　#按Enter键
Enter passphrase (empty for no passphrase): 　　#输入一个密码
Enter same passphrase again: 　　#再次输入密码
Your identification has been saved in /home/matrix/.ssh/id_rsa.
Your public key has been saved in /home/matrix/.ssh/id_rsa.pub.
The key fingerprint is:
e1:dc:ab:ae:b6:19:b0:19:74:d5:fe:57:3f:32:b4:d0 matrix@vivid
The key's randomart image is:
+---[RSA 4096]----+
| .. |
| . . |
| . . .. . |
| . . o o.. E .|
| o S ..o ...|
| = ..+...|
| o . . .o .|
| .o . |
| .++o |
+-----------------+
```

## 文件传输
姿势：
```
# 传输单个文件
scp -P <端口> <源文件> <目标文件>

# 传输文件夹
scp -P <端口> -r <源文件夹> <目标文件夹>
```
**注意**`-P`要在前面
例如把本地的file复制到远程服务器：
```
scp -P 2333 /home/ybd/file root@123.456.78:/root/file
```

## 免密码登录远程服务器
### 姿势一
使用上述`scp`把公钥**上传**到服务器，然后：
```
cat id_rsa.pub >> ~/.ssh/authorized_keys
```

### 姿势二
可以使用`ssh-copy-id`命令来完成：
```shell
ssh-copy-id <用户名>@<服务器ip> -p <端口>
```
输入远程用户的密码后，SSH公钥就会自动上传了，SSH公钥保存在远程Linux服务器的`.ssh/authorized_keys`文件中。

# 别名alias简化命令
只需要在当前用户目录加上别名命令，但博主用的是`zsh`，所有配置在`.zshrc`而不是`.bashrc`
```shell
echo "alias vps='ssh -o ServerAliveInterval=30 root@172.104.65.190 -p 2333'" >> ~/.zshrc
source ~/.zshrc
```
然后直接输入`vps`就可以登陆远程服务器了。

# 切换用户

使用`su`命令切换用户，ex：
```
su - ybd
```
这样就切换到了ybd用户
`su -`就是`su -l`(l为login的意思)，`l`可以省略，所以一般写成`su -`.....(~~坑爹~~)
如果不加用户名，默认是 `su root`切换`root`用户。
**注意**：`su` 和 `su -`的区别

- 前者是直接切换，还**保留了当前位置以及变量**
- 而后者不单单切换了用户，而且还**切换到了用户目录**，并且之前用户的**环境变量没有了**！

> 因为这个原因，写`Dockerfile`困扰了好一段时间...囧

还有`su`也可以使用某个用户的身份执行一些命令，ex：
```
# 执行单个命令
su - ${USER_NAME} -c "npm install -g hexo-cli"
# 执行shell脚本
su - ${USER_NAME} -s /bin/bash shell.sh
```

执行完之后还是保持当前用户。
可以通过`exit`退出当前用户。

# ufw防火墙

## 安装

Ubuntu自带ufw，没有可以直接安装：

```
sudo get install ufw
```

## 查看端口是否开启
```
telnet 192.168.1.103 80
```

## 设置默认规则

大多数系统只需要打开少量的端口接受传入连接，并且关闭所有剩余的端口。 从一个简单的规则基础开始，`ufw default`命令可以用于设置对传入和传出连接的默认响应动作。 要拒绝所有传入并允许所有传出连接，那么运行：

```
sudo ufw default allow outgoing
sudo ufw default deny incoming
```

## 查看本地的端口开启情况

```
sudo ufw status
```

## 打开80端口

```
sudo ufw allow 80
```

## 允许从一个 IP 地址连接

```
sudo ufw allow from 123.45.67.89
```

## 允许特定子网的连接

```
sudo ufw allow from 123.45.67.89/24
```

## 允许特定 IP/ 端口的组合

```
sudo ufw allow from 123.45.67.89 to any port 22 proto tcp
```

## 防火墙开启/禁用

```
# 开启
sudo ufw enable
# 禁用
sudo ufw disable
```

## 防火墙重启：

```
sudo ufw reload
```

# 用户与用户组相关

## 添加用户useradd
![](https://cdn.yangbingdong.com/img/node-of-ubuntu-command/command-useradd.png)

ex：
创建`ybd`用户并且加入`ybd`用户组并且创建用户目录：

```
useradd -g ybd -m ybd
# 或者
user add -m -U ybd
```

## 修改密码

```
passwd ybd
```



## 修改用户usermod

![](https://cdn.yangbingdong.com/img/node-of-ubuntu-command/command-usermod.png)

## 添加用户组groupadd
![](https://cdn.yangbingdong.com/img/node-of-ubuntu-command/command-groupadd.png)


## 修改用户组
![](https://cdn.yangbingdong.com/img/node-of-ubuntu-command/command-groupmod.png)

ex:将test组的名子改成test2
```
groupmod -n test2 test
```

删除组test2
```
groupdel test2
```

## 查看组
查看当前登录用户所在的组：
```
groups
```
查看用户test所在组：
```
groups test
```
查看所有组：
```
cat /etc/group
```

## 修改用户名

> `usermod`不允许你改变正在线上的使用者帐号名称。当`usermod`用来改变`userID`，必须确认这名`user`没在电脑上执行任何程序，否则会报“`usermod: user xxx is currently logged in`”错误。**因此必须`root`用户登录或者其他用户登录然后切换到`root`身份，而不能在当前用户下切换至`root`进行修改。**

1、**以root身份登录**

2、**usermod -l hadoop seed**
该命令相当于做了两件事：
- 将`/etc/passwd`下的用户名栏从`seed`修改为`hadoop`，其他部分不变
- 将`/etc/shadow`下的用户名栏从`seed`修改为`hadoop`，其他部分不变

3、**usermod -c hadoop hadoop**
- 相当于将`/etc/passwd`下的注解栏修改为`hadoop`，其他部分不变

4、**groupmod -n hadoop seed**
- 将原来的用户组`seed`修改为`hadoop`，只修改组名，组标识号不变，相当于修改了文件`/etc/group`和`/etc/gshadow`

5、**usermod -md /home/hadoop hadoop**
相当于做了两件事：
- 将~下的登入目录栏修改为`/home/hadoop`，其他部分不变
- 将原来的用户目录`/home/seed`修改为新的用户目录`/home/hadoop`

# 递归下载抓取整个网站内容

```
wget -r -p -k -np <URL>
```
参数说明：
`-r`：  递归下载
`-p`：  下载所有用于显示 HTML 页面的图片之类的元素
`-k`：   在转换文件 X 前先将它备份为 `X.orig`
`-np`：   不追溯至父目录

# 跟踪日志输出
```
tail -f <log>

# 输出最后1000行
tail -1000 <log>
```

# 统计文件夹大小
```
du -hs `ls -al |awk '{print $9}'`
```
上面命令可以统计文件夹中所有的文件夹和文件的大小，并且包括隐藏目录。缺点是连上级目录也会统计。

如果不需要列出上级目录，则把ls命令的-a换成-A，就不会列出点文件了。
```
du -hs `ls -Al |awk '{print $9}'`
```
如果不需要列出文件，只需文件夹，则在ls中增加-d参数即可
```
du -hs `ls -Adl |awk '{print $9}'`
或
du -hs `ls -Al |grep ^d|awk '{print $9}'`
```

# 压缩和解压缩
打包但是不压缩(`tar`)：`tar -cf <压缩包文件名> <要打包的目录>`
打包并压缩(`tar.gz`)：`tar -zcf <压缩包文件名> <要打包的目录>`

解压缩`tar`文件：`tar -xvf <压缩包文件>`
解压缩`tar.gz`文件：`tar -zxvf <压缩包文件>`

# 目录操作命令
在**Windows系统**中，有`C`、`D`、`E`等众多的盘符，每个盘符就是一个根目录。在`Linux`、`Unix`、`MacOS`等系统的**文件系统**中，**只有一个根目录**，那就是`root`，以一个斜杠代表（`/`）。
## 切换目录：`cd`
该命令和Windows中没有太大的区别，都表示改变当前的工作目录。
```
cd <目标目录>
```
## 显示当前目录：`pwd`
显示当前目录的路径，返回字符串。在Windows使用cd不带参数的方式代替。该命令同样也没有参数。
## 遍历目录：`ls`
显示当前目录中的内容，常用的命令有：
```
以列表显示当前目录所有的目录和文件
ls -l
```
在`Linux`、`Unix`、`MacOS`等系统中，隐藏文件均是点（.）开头的，下面命令以列表显示当前目录所有的目录和文件，包括隐藏的目录和文件。
```
ls -al
```
显示所有的目录，包括隐藏的目录，但是不包括文件
```
ls -adl
```
## 复制：`cp`
`cp`是`copy`的简称，用于复制文件和目录。复制的时候，源路径和目录路径可以是一个文件，也可以是一个目录。
```
cp <源路径> <目标路径>
```
## 移动：`mv`
`mv`是移动(`move`)的简称，用于移动文件和目录。
```
mv  <源路径> <目标路径>
```
## 删除：`rm`
`rm`命令可以用于删除目录和文件，但是通过`rm`删除目录的话，必须加上`rm -rf <目录名称>`。
删除文件直接就是`rm <文件名>`

注意：
在`Linux`或者`Unix`系统中，通过`rm`或者文件管理器删除文件将会从文件系统的目录结构上解除链接(`unlink`).
然而如果文件是被打开的（有一个进程正在使用），那么进程将仍然可以读取该文件，磁盘空间也一直被占用。
可以通过`lsof`命令查看文件是否被打开。详见 列出打开的文件。
## 删除目录：rmdir
删除目录的时候，必须确保目录是空的，否则无法删除。命令格式：`rm <目录>`。

## 管理员权限打开文件夹

```
sudo nautilus
```

# 查找相关

> 以下转载于***[http://blog.csdn.net/wzzfeitian/article/details/40985549](http://blog.csdn.net/wzzfeitian/article/details/40985549)***

## **find命令**

find < path > < expression > < cmd >

- path： 所要搜索的目录及其所有子目录。默认为当前目录。
- expression： 所要搜索的文件的特征。
- cmd： 对搜索结果进行特定的处理。

如果什么参数也不加，find默认搜索当前目录及其子目录，并且不过滤任何结果（也就是返回所有文件），将它们全都显示在屏幕上。

### **find命令常用选项及实例**

`-name` 按照文件名查找文件。
```
find /dir -name filename  在/dir目录及其子目录下面查找名字为filename的文件
find . -name "*.c" 在当前目录及其子目录（用“.”表示）中查找任何扩展名为“c”的文件
```

`-perm` 按照文件权限来查找文件。
```
find . -perm 755 –print 在当前目录下查找文件权限位为755的文件，即文件属主可以读、写、执行，其他用户可以读、执行的文件
```

`-prune` 使用这一选项可以使`find`命令不在当前指定的目录中查找，如果同时使用`-depth`选项，那么`-prune`将被`find`命令忽略。

```
find /apps -path "/apps/bin" -prune -o –print 在/apps目录下查找文件，但不希望在/apps/bin目录下查找
find /usr/sam -path "/usr/sam/dir1" -prune -o –print 在/usr/sam目录下查找不在dir1子目录之内的所有文件
```

`-depth`：在查找文件时，首先查找当前目录中的文件，然后再在其子目录中查找。

```
find / -name "CON.FILE" -depth –print 它将首先匹配所有的文件然后再进入子目录中查找
```

`-user` 按照文件属主来查找文件。

```
find ~ -user sam –print 在$HOME目录中查找文件属主为sam的文件
```

`-group` 按照文件所属的组来查找文件。

```
find /apps -group gem –print 在/apps目录下查找属于gem用户组的文件

```

`-mtime -n +n` 按照文件的更改时间来查找文件， -n表示文件更改时间距现在n天以内，+n表示文件更改时间距现在n天以前。

```
find / -mtime -5 –print 在系统根目录下查找更改时间在5日以内的文件
find /var/adm -mtime +3 –print 在/var/adm目录下查找更改时间在3日以前的文件
```

`-nogroup` 查找无有效所属组的文件，即该文件所属的组在`/etc/groups`中不存在。

```
find / –nogroup -print
```

`-nouser` 查找无有效属主的文件，即该文件的属主在`/etc/passwd`中不存在。

```
find /home -nouser –print
```

`-newer file1 ! file2` 查找更改时间比文件file1新但比文件file2旧的文件。

`-type` 查找某一类型的文件，


诸如：
- b - 块设备文件。
- d - 目录。
- c - 字符设备文件。
- p - 管道文件。
- l - 符号链接文件。
- f - 普通文件。
```
find /etc -type d –print 在/etc目录下查找所有的目录
find . ! -type d –print 在当前目录下查找除目录以外的所有类型的文件
find /etc -type l –print 在/etc目录下查找所有的符号链接文件
```

`-size n[c]` 查找文件长度为n块的文件，带有c时表示文件长度以字节计。
```
find . -size +1000000c –print 在当前目录下查找文件长度大于1 M字节的文件
find /home/apache -size 100c –print 在/home/apache目录下查找文件长度恰好为100字节的文件
find . -size +10 –print 在当前目录下查找长度超过10块的文件（一块等于512字节）
```

`-mount` 在查找文件时不跨越文件系统mount点。
  `find . -name “*.XC” -mount –print` 从当前目录开始查找位于本文件系统中文件名以XC结尾的文件（不进入其他文件系统）

`-follow` 如果find命令遇到符号链接文件，就跟踪至链接所指向的文件

`-exec` find命令对匹配的文件执行该参数所给出的shell命令。相应命令的形式为`command {} \`，注意`{}`和`\`;之间的空格

```
$ find ./ -size 0 -exec rm {} \; 删除文件大小为零的文件
$ rm -i `find ./ -size 0`  
$ find ./ -size 0 | xargs rm -f &

为了用ls -l命令列出所匹配到的文件，可以把ls -l命令放在find命令的-exec选项中：
$ find . -type f -exec ls -l {} \;
在/logs目录中查找更改时间在5日以前的文件并删除它们：
find /logs -type f -mtime +5 -exec rm {} \;
```

`-ok`，和`-exec`的作用相同，只不过以一种更为安全的模式来执行该参数所给出的shell命令，在执行每一个命令之前，都会给出提示，让用户来确定是否执行。

```
find . -name "*.conf"  -mtime +5 -ok rm {} \; 在当前目录中查找所有文件名以.LOG结尾、更改时间在5日以上的文件，并删除它们，只不过在删除之前先给出提示
```

**说明**： 如果你要寻找一个档案的话，那么使用 find 会是一个不错的主意。不过，由于 find 在寻找数据的时候相当的耗硬盘，所以没事情不要使用 find 啦！有更棒的指令可以取代呦，那就是 `whereis` 与 `locate` 咯~

### **一些常用命令**
```
1. find . -type f -exec ls -l {} \;
查找当前路径下的所有普通文件，并把它们列出来。

2. find logs -type f -mtime +5 -exec rm {} \;
删除logs目录下更新时间为5日以上的文件。

3.find . -name "*.log" -mtime +5 -ok rm {} \;
删除当前路径下以。log结尾的五日以上的文件，删除之前要确认。

4. find ~ -type f -perm 4755 -print
查找$HOME目录下suid位被设置，文件属性为755的文件打印出来。
说明： find在有点系统中会一次性得到将匹配到的文件都传给exec，但是有的系统对exec的命令长度做限制，就会报：”参数列太长“，这就需要使用xargs。xargs是部分取传来的文件。

5. find / -type f -print |xargs file
xargs测试文件分类

6. find . -name "core*" -print|xargs echo " ">/tmp/core.log
将core文件信息查询结果报存到core。log日志。

7. find / -type f -print | xargs chmod o -w

8. find . -name * -print |xargs grep "DBO"
```

## **grep命令**
```
grep [选项] pattern [文件名]
```
命令中的选项为：

- -? 同时显示匹配行上下的？行，如：`grep -2 pattern filename` 同时显示匹配行的上下2行。
- -b，—byte-offset 打印匹配行前面打印该行所在的块号码。
- -c,—count 只打印匹配的行数，不显示匹配的内容。
- -f File，—file=File 从文件中提取模板。空文件中包含0个模板，所以什么都不匹配。
- -h，—no-filename 当搜索多个文件时，不显示匹配文件名前缀。
- -i，—ignore-case 忽略大小写差别。
- -q，—quiet 取消显示，只返回退出状态。0则表示找到了匹配的行。
- -l，—files-with-matches 打印匹配模板的文件清单。
- -L，—files-without-match 打印不匹配模板的文件清单。
- -n，—line-number 在匹配的行前面打印行号。
- -s，—silent 不显示关于不存在或者无法读取文件的错误信息。
- -v，—revert-match 反检索，只显示不匹配的行。
- -w，—word-regexp 如果被\<和>引用，就把表达式做为一个单词搜索。
- -V，—version 显示软件版本信息。

```
ls -l | grep '^a' 通过管道过滤ls -l输出的内容，只显示以a开头的行。
grep 'test' d* 显示所有以d开头的文件中包含test的行。
grep 'test' aa bb cc 显示在aa，bb，cc文件中匹配test的行。
grep '[a-z]' aa 显示所有包含每个字符串至少有5个连续小写字符的字符串的行。
grep 'w(es)t.*' aa 如果west被匹配，则es就被存储到内存中，并标记为1，然后搜索任意个字符(.*)，这些字符后面紧跟着另外一个es()，找到就显示该行。如果用egrep或grep -E，就不用""号进行转义，直接写成'w(es)t.*'就可以了。
grep -i pattern files ：不区分大小写地搜索。默认情况区分大小写
grep -l pattern files ：只列出匹配的文件名，
grep -L pattern files ：列出不匹配的文件名，
grep -w pattern files ：只匹配整个单词，而不是字符串的一部分(如匹配‘magic’，而不是‘magical’)，
grep -C number pattern files ：匹配的上下文分别显示[number]行，
grep pattern1 | pattern2 files ：显示匹配 pattern1 或 pattern2 的行，
grep pattern1 files | grep pattern2 ：显示既匹配 pattern1 又匹配 pattern2 的行。
```

pattern为所要匹配的字符串，可使用下列模式
```
. 匹配任意一个字符
* 匹配0 个或多个*前的字符
^ 匹配行开头
$ 匹配行结尾
[] 匹配[ ]中的任意一个字符，[]中可用 - 表示范围，
例如[a-z]表示字母a 至z 中的任意一个
\ 转意字符
```

## **xargs命令**
【xargs定位参数位置 | xargs控制参数位置 | 如何定位控制xargs参数位置】
**背景**：
管道 + xargs用于把上游输出转换为下游参数输入。
例如 `ls *.bak | xargs rm -f`

**问题**：
xargs默认把输入作为参数放到命令的最后，但是很多命令需要自己定位参数的位置，比如拷贝命令`cp {上游结果} destFolder`

**解决方法**：
xargs 使用大写字母i 定义参数指示符 **-I <指示符>**，然后用这个参数指示符定位参数插入的位置, 例如：

```
ls *.bak | xargs -I % cp % /tmp/test
```

> 注释：这里使用%作为指示符，第一个%可以理解为声明，第二个%可以理解为调用。你也**可以用其他字符**，比如 `ls *.bak | xargs -I {} cp {} /tmp/test`

**简介**
之所以能用到xargs这个命令，关键是由于很多命令不支持|管道来传递参数，而日常工作中有有这个必要，所以就有了xargs命令，例如：

```
find /sbin -perm +700 | ls -l       这个命令是错误的
find /sbin -perm +700 | xargs ls -l   这样才是正确的

```

xargs 可以读入 stdin 的资料，并且以**空白字元或断行字元**作为分辨，将 stdin 的资料分隔成为 arguments 。 因为是以空白字元作为分隔，所以，如果有一些档名或者是其他意义的名词内含有空白字元的时候， xargs 可能就会误判了～
**选项解释**
-0 当sdtin含有特殊字元时候，将其当成一般字符，像/ ‘ 空格等

```
root@localhost:~/test#echo "//"|xargs  echo
root@localhost:~/test#echo "//"|xargs -0 echo
/
```

-a file 从文件中读入作为sdtin

```
root@localhost:~/test#cat test#!/bin/shecho "hello world/n"
root@localhost:~/test#xargs -a test echo#!/bin/sh echo hello world/n
root@localhost:~/test#
```

- -e flag ，注意有的时候可能会是-E，flag必须是一个以空格分隔的标志，当xargs分析到含有flag这个标志的时候就停止。

```
root@localhost:~/test#cat txt
/bin tao shou kun
root@localhost:~/test#cat txt|xargs -E 'shou' echo
/bin tao
```

- -p 当每次执行一个argument的时候询问一次用户。

```
root@localhost:~/test#cat txt|xargs -p echoecho /bin tao shou kun ff ?...y
/bin tao shou kun ff
```

- -n num 后面加次数，表示命令在执行的时候一次用的argument的个数，默认是用所有的

```
root@localhost:~/test#cat txt|xargs -n1 echo
/bin
tao
shou
kun
root@localhost:~/test3#cat txt|xargs  echo
/bin tao shou ku
```

- -t 表示先打印命令，然后再执行。

```
root@localhost:~/test#cat txt|xargs -t echoecho /bin tao shou kun
/bin tao shou kun
```

- -i 或者是-I，这得看linux支持了，将xargs的每项名称，一般是一行一行赋值给{}，可以用{}代替。

```
$ ls | xargs -t -i mv {} {}.bak
```

- -r no-run-if-empty 当xargs的输入为空的时候则停止xargs，不用再去执行了。

```
root@localhost:~/test#echo ""|xargs -t -r  mv
root@localhost:~/test#
```

- -s num 命令行的最大字符数，指的是xargs后面那个命令的最大命令行字符数

```
root@localhost:~/test#cat test |xargs -i -x  -s 14 echo "{}"
exp1
exp5
file
xargs: argument line too long
linux-2
root@localhost:~/test#
```

- -L num Use at most max-lines nonblank input lines per command line.-s是含有空格的。

- -l 同-L

- -d delim 分隔符，**默认的xargs分隔符是回车**，**argument的分隔符是空格**，这里修改的是xargs的分隔符

```
root@localhost:~/test#cat txt |xargs -i -p echo {}echo /bin tao shou kun ?...y
root@localhost:~/test#cat txt |xargs -i -p -d " " echo {}echo /bin ?...y
echo tao ?.../bin
y
echo shou ?...tao
再如：
root@localhost:~/test#cat test |xargs -i -p -d " " echo {}echo exp1
exp5
file
linux-2
ngis_post
tao
test
txt
xen-3
?...y
root@localhost:~/test#cat test |xargs -i -p echo {}echo exp1 ?...y
echo exp5 ?...exp1
y
echo file ?...exp5
y
```

- -x exit的意思，主要是配合-s使用。

- -P 修改最大的进程数，默认是1，为0时候为as many as it can

## **其他查找命令**

### **1. locate命令**

locate命令其实是“find -name”的另一种写法，但是要比后者快得多，原因在于它不搜索具体目录，而是搜索一个数据库（/var/lib/locatedb），这个数据库中含有本地所有文件信息。Linux系统自动创建这个数据库，并且每天自动更新一次，所以使用locate命令查不到最新变动过的文件。为了避免这种情况，可以在使用locate之前，先使用updatedb命令，手动更新数据库。

**locate命令的使用实例：**

```
$ locate /etc/sh
搜索etc目录下所有以sh开头的文件。
$ locate -i ~/m
搜索用户主目录下，所有以m开头的文件，并且忽略大小写。
```

### **2. whereis命令**

whereis命令只能用于程序名的搜索，而且只搜索二进制文件（参数-b）、man说明文件（参数-m）和源代码文件（参数-s）。如果省略参数，则返回所有信息。

**whereis命令的使用实例：**

```
$ whereis grep
grep: /bin/grep /usr/share/man/man1p/grep.1p.gz /usr/share/man/man1/grep.1.gz
```

### **3. which命令**

which命令的作用是，在PATH变量指定的路径中，搜索某个系统命令的位置，并且返回第一个搜索结果。也就是说，使用which命令，就可以看到某个系统命令是否存在，以及执行的到底是哪一个位置的命令。

**which命令的使用实例：**

```
$ which grep
/bin/grep

```

# 查看磁盘空间

```
df -hl
```

显示格式为：

```
文件系统              容量 已用 可用 已用% 挂载点　

Filesystem            Size Used Avail Use% Mounted on
```

`df -hl` 查看磁盘剩余空间

`df -h` 查看每个根路径的分区大小

`du -sh` [目录名] 返回该目录的大小

`du -sm` [文件夹] 返回该文件夹总M数

# 查看内存使用情况

`free`：

```
root@localhost:~# free -h
              total        used        free      shared  buff/cache   available
Mem:           989M        121M         87M        7.0M        781M        662M
Swap:          255M         14M        241M
```

# printf进制转换

> 二进制:binanry number
>
> 八进制:otcal number
>
> 十进制:decimal number
>
> 十六进制: hexadecimal number
>
> 一般使用jstack查找线程时候用到

十进制转16进制:

```
printf "%x\n" 666
```

输出的是`29a`，一般16进制前面会加个`0x`表示，所以可以这样：

```
printf "0x%x\n" 666
```

16进制转十进制:

```
printf "%d\n" 0x29a
```

#  Extend

## 使用systemd设置开机启动

> [ubuntu](https://www.centos.bz/category/other-system/ubuntu/)从16.04开始不再使用initd管理系统，改用[systemd](https://www.centos.bz/tag/systemd/)

**为了像以前一样，在`/etc/rc.local`中设置开机启动程序，需要以下几步：**

**1、systemd默认读取`/etc/systemd/system`下的配置文件，该目录下的文件会链接`/lib/systemd/system/`下的文件。一般系统安装完`/lib/systemd/system/`下会有`rc-local.service`文件，即我们需要的配置文件。**

链接过来：

```
ln -fs /lib/systemd/system/rc-local.service /etc/systemd/system/rc-local.service
```

```
cd /etc/systemd/system/
vim rc-local.service
```

`rc-local.service`内容：

```
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.

# This unit gets pulled automatically into multi-user.target by
# systemd-rc-local-generator if /etc/rc.local is executable.
[Unit]
Description=/etc/rc.local Compatibility
ConditionFileIsExecutable=/etc/rc.local
After=network.target

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
RemainAfterExit=yes
GuessMainPID=no

[Install]
WantedBy=multi-user.target
Alias=rc-local.service
```

**2、创建/etc/rc.local文件**

```
touch /etc/rc.local
```

**3、赋可执行权限**

```
chmod 755 /etc/rc.local
```

**4、编辑rc.local，添加需要开机启动的任务**

```
#!/bin/bash

echo "test test " > /var/test_boot_up.log
```

**5、执行reboot重启系统验证OK。**

最后，说一下`/etc/systemd/system/`下的配置文件（`XXXX.service`）,
其中有三个配置项，`[Unit]` / `[Service]` / `[Install]`

- `[Unit]` 区块：启动顺序与依赖关系。
- `[Service]` 区块：启动行为,如何启动，启动类型。
- `[Install]` 区块，定义如何安装这个配置文件，即怎样做到开机启动。

## apt-get update无法下载

![](https://cdn.yangbingdong.com/img/node-of-ubuntu-command/apt-get-update-fail.png)

出现类似情况，可以找到`/etc/apt/sources.list.d`目录，删除对应的`.list`文件即可


