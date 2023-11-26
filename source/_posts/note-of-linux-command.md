---
title: Ubuntu 常用命令
date: 2017-09-20 18:05:10
categories: [OperatingSystem,Ubuntu]
tags: [Ubuntu]
---

![](https://oldcdn.yangbingdong.com/img/node-of-ubuntu-command/ubuntu-logo.png)

# Preface

> =.= 这里只记录一些个人比较常用到的[*Ubuntu*](https://www.ubuntu.com)命令


<!--more-->
# SSH相关

## 安装SSH

```
sudo apt install ssh
sudo apt install openssh-server
```

查看启动成功: `ps -e|grep ssh`, 如果看到`sshd`那代表成功了, 如果没有, 执行: 

```
sudo/etc/init.d/ssh start
```

ssh的配置文件位于`/etc/ssh/sshd_config`, 修改后需要重启ssh: 

```
sudo /etc/init.d/sshresart  
```

## 保持长连接
只需要在`ssh`命令后加上发送心跳即可: 
```
ssh -o ServerAliveInterval=30 root@123.456.88 -p 2333
```

## 生成SSH密钥和公钥

打开终端, 使用下面的`ssh-keygen`来生成`RSA`密钥和公钥. `-t`表示type, 就是说要生成`RSA`加密的钥匙: 
```shell
ssh-keygen -t rsa -C "your_email@youremail.com"
```
`RSA`也是默认的加密类型, 所以你也可以只输入`ssh-keygen`, 默认的`RSA`长度是2048位, 如果你非常注重安全, 那么可以指定4096位的长度: 
```shell
ssh-keygen -b 4096 -t rsa -C "your_email@youremail.com"
```
生成SSH Key的过程中会要求你指定一个文件来保存密钥, 按`Enter`键使用默认的文件就行了, 然后需要输入一个密码来加密你的SSH Key, 密码至少要20位长度, SSH密钥会保存在`home`目录下的`.ssh/id_rsa`文件中, SSH公钥保存在`.ssh/id_rsa.pub`文件中. 
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
姿势: 
```
# 传输单个文件
scp -P <端口> <源文件> <目标文件>

# 传输文件夹
scp -P <端口> -r <源文件夹> <目标文件夹>
```
**注意**`-P`要在前面
例如把本地的file复制到远程服务器: 
```
scp -P 2333 /home/ybd/file root@123.456.78:/root/file
```

## SSH 与 SCP 使用代理

```
ssh -o ProxyCommand="nc -X 5 -x proxy.net:1080 %h %p" user@server.net
```

常用参数：

- -X 指定代理协议

  - `4` SOCKS v.4
  - `5` SOCKS v.5**（默认）**
  - `connect` HTTPS proxy

- -x 代理地址[:端口]

  如果没有指定端口，采用协议常用端口，如：

  - SOCKETS 使用 1080
  - HTTPS 使用 3128

## 免密码登录远程服务器

### 姿势一
使用上述`scp`把公钥**上传**到服务器, 然后: 
```
cat id_rsa.pub >> ~/.ssh/authorized_keys
```

### 姿势二
可以使用`ssh-copy-id`命令来完成: 
```shell
ssh-copy-id <用户名>@<服务器ip> -p <端口>
```
输入远程用户的密码后, SSH公钥就会自动上传了, SSH公钥保存在远程Linux服务器的`.ssh/authorized_keys`文件中. 

# 别名alias简化命令
只需要在当前用户目录加上别名命令, 但博主用的是`zsh`, 所有配置在`.zshrc`而不是`.bashrc`
```shell
echo "alias vps='ssh -o ServerAliveInterval=30 root@172.104.65.190 -p 2333'" >> ~/.zshrc
source ~/.zshrc
```
然后直接输入`vps`就可以登陆远程服务器了. 

# 切换用户

使用`su`命令切换用户, ex: 
```
su - ybd
```
这样就切换到了ybd用户
`su -`就是`su -l`(l为login的意思), `l`可以省略, 所以一般写成`su -`.....(~~坑爹~~)
如果不加用户名, 默认是 `su root`切换`root`用户. 
**注意**: `su` 和 `su -`的区别

- 前者是直接切换, 还**保留了当前位置以及变量**
- 而后者不单单切换了用户, 而且还**切换到了用户目录**, 并且之前用户的**环境变量没有了**！

> 因为这个原因, 写`Dockerfile`困扰了好一段时间...囧

还有`su`也可以使用某个用户的身份执行一些命令, ex: 
```
# 执行单个命令
su - ${USER_NAME} -c "npm install -g hexo-cli"
# 执行shell脚本
su - ${USER_NAME} -s /bin/bash shell.sh
```

执行完之后还是保持当前用户. 
可以通过`exit`退出当前用户. 

# ufw防火墙

## 安装

Ubuntu自带ufw, 没有可以直接安装: 

```
sudo get install ufw
```

## 查看端口是否开启
```
telnet 192.168.1.103 80
```

## 设置默认规则

大多数系统只需要打开少量的端口接受传入连接, 并且关闭所有剩余的端口. 从一个简单的规则基础开始, `ufw default`命令可以用于设置对传入和传出连接的默认响应动作. 要拒绝所有传入并允许所有传出连接, 那么运行: 

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

## 防火墙重启: 

```
sudo ufw reload
```

# 用户与用户组相关

## 添加用户useradd
![](https://oldcdn.yangbingdong.com/img/node-of-ubuntu-command/command-useradd.png)

ex: 
创建`ybd`用户并且加入`ybd`用户组并且创建用户目录: 

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

![](https://oldcdn.yangbingdong.com/img/node-of-ubuntu-command/command-usermod.png)

## 添加用户组groupadd
![](https://oldcdn.yangbingdong.com/img/node-of-ubuntu-command/command-groupadd.png)


## 修改用户组
![](https://oldcdn.yangbingdong.com/img/node-of-ubuntu-command/command-groupmod.png)

ex:将test组的名子改成test2
```
groupmod -n test2 test
```

删除组test2
```
groupdel test2
```

## 查看组
查看当前登录用户所在的组: 
```
groups
```
查看用户test所在组: 
```
groups test
```
查看所有组: 
```
cat /etc/group
```

## 修改用户名

> `usermod`不允许你改变正在线上的使用者帐号名称. 当`usermod`用来改变`userID`, 必须确认这名`user`没在电脑上执行任何程序, 否则会报“`usermod: user xxx is currently logged in`”错误. **因此必须`root`用户登录或者其他用户登录然后切换到`root`身份, 而不能在当前用户下切换至`root`进行修改. **

1、**以root身份登录**

2、**usermod -l hadoop seed**
该命令相当于做了两件事: 
- 将`/etc/passwd`下的用户名栏从`seed`修改为`hadoop`, 其他部分不变
- 将`/etc/shadow`下的用户名栏从`seed`修改为`hadoop`, 其他部分不变

3、**usermod -c hadoop hadoop**
- 相当于将`/etc/passwd`下的注解栏修改为`hadoop`, 其他部分不变

4、**groupmod -n hadoop seed**
- 将原来的用户组`seed`修改为`hadoop`, 只修改组名, 组标识号不变, 相当于修改了文件`/etc/group`和`/etc/gshadow`

5、**usermod -md /home/hadoop hadoop**
相当于做了两件事: 
- 将~下的登入目录栏修改为`/home/hadoop`, 其他部分不变
- 将原来的用户目录`/home/seed`修改为新的用户目录`/home/hadoop`

# 网络相关

## curl

> 来自: ***[https://itbilu.com/linux/man/4yZ9qH_7X.html](https://itbilu.com/linux/man/4yZ9qH_7X.html)***
>
> `curl`是一个开源的用于数据传输的命令行工具与库，它使用`URL`语法格式，支持众多传输协议，包括：HTTP、HTTPS、FTP、FTPS、GOPHER、TFTP、SCP、SFTP、SMB、TELNET、DICT、LDAP、LDAPS、FILE、IMAP、SMTP、POP3、RTSP和RTMP。`curl`库提供了很多强大的功能，你可以利用它来进行HTTP/HTTPS请求、上传/下载文件等，且支持Cookie、认证、代理、限速等。

**直接访问**:

```
curlyangbingdong.com
```

**重定向跟踪**

页面使用了重定向，这时我们可以添加`-L`参数来跟踪URL重定向：

```
curl -L https://git.io/vokNn
```

**页面保存**

```
curl -o [文件名] https://git.io/vokNn
```

**查看头信息**

如果需要查看访问页面的可以添加`-i`或`--include`参数：

```
curl -i yangbingdong.com
```

添加`-i`参数后，页面响应头会和页面源码（响应体）一块返回。如果只想查看响应头，可以使用`-I`或`--head`参数.

**POST数据提交**

`curl`使用`POST`提交表单数据时，除了`-X`参数指定请求方法外，还要使用`--data`参数添加提交数据：

```
curl -X POST --data 'keyword=linux' itbilu.com
```

**添加请求头**

有时在进行HTTP请求时，需要自定义请求头。在`curl`中，可以通过`-H`或`--header`参数来指定请求头。多次使用`-H`或`--header`参数可指定多个请求头。

如，指定`Content-Type`及`Authorization`请求头：

```
curl -H 'Content-Type:application/json' -H 'Authorization: bearer eyJhbGciOiJIUzI1NiJ9' itbilu.com
```

**Cookie支持**

`Cookie`是一种常用的保持服务端会话信息的方法，`crul`也支持使用`Cookie`。

可以通过`--cookie`参数指定发送请求时的`Cookie`值，也可以通过`-b [文件名]`来指定一个存储了`Cookie`值的本地文件：

```
curl -b stored_cookies_in_file itbilu.com
```

`Cookie`值可能会被服务器所返回的值所修改，并应用于下次HTTP请求。这时，可以能过`-c`参数指定存储服务器返回`Cookie`值的存储文件：

```
curl -b cookies.txt -c newcookies.txt itbilu.com
```

## 递归下载抓取整个网站内容

```
wget -r -p -k -np <URL>
```
参数说明: 
`-r`:  递归下载
`-p`:  下载所有用于显示 HTML 页面的图片之类的元素
`-k`:   在转换文件 X 前先将它备份为 `X.orig`
`-np`:   不追溯至父目录

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
上面命令可以统计文件夹中所有的文件夹和文件的大小, 并且包括隐藏目录. 缺点是连上级目录也会统计. 

如果不需要列出上级目录, 则把ls命令的-a换成-A, 就不会列出点文件了. 
```
du -hs `ls -Al |awk '{print $9}'`
```
如果不需要列出文件, 只需文件夹, 则在ls中增加-d参数即可
```
du -hs `ls -Adl |awk '{print $9}'`
或
du -hs `ls -Al |grep ^d|awk '{print $9}'`
```

# 压缩和解压缩
打包但是不压缩(`tar`): `tar -cf <压缩包文件名> <要打包的目录>`
打包并压缩(`tar.gz`): `tar -zcf <压缩包文件名> <要打包的目录>`

解压缩`tar`文件: `tar -xvf <压缩包文件>`
解压缩`tar.gz`文件: `tar -zxvf <压缩包文件>`

# 目录与文件

> 以下转载于***[http://blog.csdn.net/wzzfeitian/article/details/40985549](http://blog.csdn.net/wzzfeitian/article/details/40985549)***

## **find命令**

find < path > < expression > < cmd >

- path: 所要搜索的目录及其所有子目录. 默认为当前目录. 
- expression: 所要搜索的文件的特征. 
- cmd: 对搜索结果进行特定的处理. 

如果什么参数也不加, find默认搜索当前目录及其子目录, 并且不过滤任何结果（也就是返回所有文件）, 将它们全都显示在屏幕上. 

### **find命令常用选项及实例**

`-name` 按照文件名查找文件. 
```
find /dir -name filename  在/dir目录及其子目录下面查找名字为filename的文件
find . -name "*.c" 在当前目录及其子目录（用“.”表示）中查找任何扩展名为“c”的文件
```

`-perm` 按照文件权限来查找文件. 
```
find . -perm 755 –print 在当前目录下查找文件权限位为755的文件, 即文件属主可以读、写、执行, 其他用户可以读、执行的文件
```

`-prune` 使用这一选项可以使`find`命令不在当前指定的目录中查找, 如果同时使用`-depth`选项, 那么`-prune`将被`find`命令忽略. 

```
find /apps -path "/apps/bin" -prune -o –print 在/apps目录下查找文件, 但不希望在/apps/bin目录下查找
find /usr/sam -path "/usr/sam/dir1" -prune -o –print 在/usr/sam目录下查找不在dir1子目录之内的所有文件
```

`-depth`: 在查找文件时, 首先查找当前目录中的文件, 然后再在其子目录中查找. 

```
find / -name "CON.FILE" -depth –print 它将首先匹配所有的文件然后再进入子目录中查找
```

`-user` 按照文件属主来查找文件. 

```
find ~ -user sam –print 在$HOME目录中查找文件属主为sam的文件
```

`-group` 按照文件所属的组来查找文件. 

```
find /apps -group gem –print 在/apps目录下查找属于gem用户组的文件

```

`-mtime -n +n` 按照文件的更改时间来查找文件, -n表示文件更改时间距现在n天以内, +n表示文件更改时间距现在n天以前. 

```
find / -mtime -5 –print 在系统根目录下查找更改时间在5日以内的文件
find /var/adm -mtime +3 –print 在/var/adm目录下查找更改时间在3日以前的文件
```

`-nogroup` 查找无有效所属组的文件, 即该文件所属的组在`/etc/groups`中不存在. 

```
find / –nogroup -print
```

`-nouser` 查找无有效属主的文件, 即该文件的属主在`/etc/passwd`中不存在. 

```
find /home -nouser –print
```

`-newer file1 ! file2` 查找更改时间比文件file1新但比文件file2旧的文件. 

`-type` 查找某一类型的文件, 


诸如: 
- b - 块设备文件. 
- d - 目录. 
- c - 字符设备文件. 
- p - 管道文件. 
- l - 符号链接文件. 
- f - 普通文件. 
```
find /etc -type d –print 在/etc目录下查找所有的目录
find . ! -type d –print 在当前目录下查找除目录以外的所有类型的文件
find /etc -type l –print 在/etc目录下查找所有的符号链接文件
```

`-size n[c]` 查找文件长度为n块的文件, 带有c时表示文件长度以字节计. 
```
find . -size +1000000c –print 在当前目录下查找文件长度大于1 M字节的文件
find /home/apache -size 100c –print 在/home/apache目录下查找文件长度恰好为100字节的文件
find . -size +10 –print 在当前目录下查找长度超过10块的文件（一块等于512字节）
```

`-mount` 在查找文件时不跨越文件系统mount点. 
  `find . -name “*.XC” -mount –print` 从当前目录开始查找位于本文件系统中文件名以XC结尾的文件（不进入其他文件系统）

`-follow` 如果find命令遇到符号链接文件, 就跟踪至链接所指向的文件

`-exec` find命令对匹配的文件执行该参数所给出的shell命令. 相应命令的形式为`command {} \`, 注意`{}`和`\`;之间的空格

```
$ find ./ -size 0 -exec rm {} \; 删除文件大小为零的文件
$ rm -i `find ./ -size 0`  
$ find ./ -size 0 | xargs rm -f &

为了用ls -l命令列出所匹配到的文件, 可以把ls -l命令放在find命令的-exec选项中: 
$ find . -type f -exec ls -l {} \;
在/logs目录中查找更改时间在5日以前的文件并删除它们: 
find /logs -type f -mtime +5 -exec rm {} \;
```

`-ok`, 和`-exec`的作用相同, 只不过以一种更为安全的模式来执行该参数所给出的shell命令, 在执行每一个命令之前, 都会给出提示, 让用户来确定是否执行. 

```
find . -name "*.conf"  -mtime +5 -ok rm {} \; 在当前目录中查找所有文件名以.LOG结尾、更改时间在5日以上的文件, 并删除它们, 只不过在删除之前先给出提示
```

**说明**: 如果你要寻找一个档案的话, 那么使用 find 会是一个不错的主意. 不过, 由于 find 在寻找数据的时候相当的耗硬盘, 所以没事情不要使用 find 啦！有更棒的指令可以取代呦, 那就是 `whereis` 与 `locate` 咯~

### **一些常用命令**
```
1. find . -type f -exec ls -l {} \;
查找当前路径下的所有普通文件, 并把它们列出来. 

2. find logs -type f -mtime +5 -exec rm {} \;
删除logs目录下更新时间为5日以上的文件. 

3.find . -name "*.log" -mtime +5 -ok rm {} \;
删除当前路径下以. log结尾的五日以上的文件, 删除之前要确认. 

4. find ~ -type f -perm 4755 -print
查找$HOME目录下suid位被设置, 文件属性为755的文件打印出来. 
说明: find在有点系统中会一次性得到将匹配到的文件都传给exec, 但是有的系统对exec的命令长度做限制, 就会报: ”参数列太长“, 这就需要使用xargs. xargs是部分取传来的文件. 

5. find / -type f -print |xargs file
xargs测试文件分类

6. find . -name "core*" -print|xargs echo " ">/tmp/core.log
将core文件信息查询结果报存到core. log日志. 

7. find / -type f -print | xargs chmod o -w

8. find . -name * -print |xargs grep "DBO"
```

## **grep命令**
```
grep [选项] pattern [文件名]
```
命令中的选项为: 

- -? 同时显示匹配行上下的？行, 如: `grep -2 pattern filename` 同时显示匹配行的上下2行. 
- -b, —byte-offset 打印匹配行前面打印该行所在的块号码. 
- -c,—count 只打印匹配的行数, 不显示匹配的内容. 
- -f File, —file=File 从文件中提取模板. 空文件中包含0个模板, 所以什么都不匹配. 
- -h, —no-filename 当搜索多个文件时, 不显示匹配文件名前缀. 
- -i, —ignore-case 忽略大小写差别. 
- -q, —quiet 取消显示, 只返回退出状态. 0则表示找到了匹配的行. 
- -l, —files-with-matches 打印匹配模板的文件清单. 
- -L, —files-without-match 打印不匹配模板的文件清单. 
- -n, —line-number 在匹配的行前面打印行号. 
- -s, —silent 不显示关于不存在或者无法读取文件的错误信息. 
- -v, —revert-match 反检索, 只显示不匹配的行. 
- -w, —word-regexp 如果被\<和>引用, 就把表达式做为一个单词搜索. 
- -V, —version 显示软件版本信息. 

```
ls -l | grep '^a' 通过管道过滤ls -l输出的内容, 只显示以a开头的行. 
grep 'test' d* 显示所有以d开头的文件中包含test的行. 
grep 'test' aa bb cc 显示在aa, bb, cc文件中匹配test的行. 
grep '[a-z]' aa 显示所有包含每个字符串至少有5个连续小写字符的字符串的行. 
grep 'w(es)t.*' aa 如果west被匹配, 则es就被存储到内存中, 并标记为1, 然后搜索任意个字符(.*), 这些字符后面紧跟着另外一个es(), 找到就显示该行. 如果用egrep或grep -E, 就不用""号进行转义, 直接写成'w(es)t.*'就可以了. 
grep -i pattern files : 不区分大小写地搜索. 默认情况区分大小写
grep -l pattern files : 只列出匹配的文件名, 
grep -L pattern files : 列出不匹配的文件名, 
grep -w pattern files : 只匹配整个单词, 而不是字符串的一部分(如匹配‘magic’, 而不是‘magical’), 
grep -C number pattern files : 匹配的上下文分别显示[number]行, 
grep pattern1 | pattern2 files : 显示匹配 pattern1 或 pattern2 的行, 
grep pattern1 files | grep pattern2 : 显示既匹配 pattern1 又匹配 pattern2 的行. 
```

pattern为所要匹配的字符串, 可使用下列模式
```
. 匹配任意一个字符
* 匹配0 个或多个*前的字符
^ 匹配行开头
$ 匹配行结尾
[] 匹配[ ]中的任意一个字符, []中可用 - 表示范围, 
例如[a-z]表示字母a 至z 中的任意一个
\ 转意字符
```

## **xargs命令**
【xargs定位参数位置 | xargs控制参数位置 | 如何定位控制xargs参数位置】
**背景**: 
管道 + xargs用于把上游输出转换为下游参数输入. 
例如 `ls *.bak | xargs rm -f`

**问题**: 
xargs默认把输入作为参数放到命令的最后, 但是很多命令需要自己定位参数的位置, 比如拷贝命令`cp {上游结果} destFolder`

**解决方法**: 
xargs 使用大写字母i 定义参数指示符 **-I <指示符>**, 然后用这个参数指示符定位参数插入的位置, 例如: 

```
ls *.bak | xargs -I % cp % /tmp/test
```

> 注释: 这里使用%作为指示符, 第一个%可以理解为声明, 第二个%可以理解为调用. 你也**可以用其他字符**, 比如 `ls *.bak | xargs -I {} cp {} /tmp/test`

**简介**
之所以能用到xargs这个命令, 关键是由于很多命令不支持|管道来传递参数, 而日常工作中有有这个必要, 所以就有了xargs命令, 例如: 

```
find /sbin -perm +700 | ls -l       这个命令是错误的
find /sbin -perm +700 | xargs ls -l   这样才是正确的

```

xargs 可以读入 stdin 的资料, 并且以**空白字元或断行字元**作为分辨, 将 stdin 的资料分隔成为 arguments . 因为是以空白字元作为分隔, 所以, 如果有一些档名或者是其他意义的名词内含有空白字元的时候, xargs 可能就会误判了～
**选项解释**
-0 当sdtin含有特殊字元时候, 将其当成一般字符, 像/ ‘ 空格等

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

- -e flag , 注意有的时候可能会是-E, flag必须是一个以空格分隔的标志, 当xargs分析到含有flag这个标志的时候就停止. 

```
root@localhost:~/test#cat txt
/bin tao shou kun
root@localhost:~/test#cat txt|xargs -E 'shou' echo
/bin tao
```

- -p 当每次执行一个argument的时候询问一次用户. 

```
root@localhost:~/test#cat txt|xargs -p echoecho /bin tao shou kun ff ?...y
/bin tao shou kun ff
```

- -n num 后面加次数, 表示命令在执行的时候一次用的argument的个数, 默认是用所有的

```
root@localhost:~/test#cat txt|xargs -n1 echo
/bin
tao
shou
kun
root@localhost:~/test3#cat txt|xargs  echo
/bin tao shou ku
```

- -t 表示先打印命令, 然后再执行. 

```
root@localhost:~/test#cat txt|xargs -t echoecho /bin tao shou kun
/bin tao shou kun
```

- -i 或者是-I, 这得看linux支持了, 将xargs的每项名称, 一般是一行一行赋值给{}, 可以用{}代替. 

```
$ ls | xargs -t -i mv {} {}.bak
```

- -r no-run-if-empty 当xargs的输入为空的时候则停止xargs, 不用再去执行了. 

```
root@localhost:~/test#echo ""|xargs -t -r  mv
root@localhost:~/test#
```

- -s num 命令行的最大字符数, 指的是xargs后面那个命令的最大命令行字符数

```
root@localhost:~/test#cat test |xargs -i -x  -s 14 echo "{}"
exp1
exp5
file
xargs: argument line too long
linux-2
root@localhost:~/test#
```

- -L num Use at most max-lines nonblank input lines per command line.-s是含有空格的. 

- -l 同-L

- -d delim 分隔符, **默认的xargs分隔符是回车**, **argument的分隔符是空格**, 这里修改的是xargs的分隔符

```
root@localhost:~/test#cat txt |xargs -i -p echo {}echo /bin tao shou kun ?...y
root@localhost:~/test#cat txt |xargs -i -p -d " " echo {}echo /bin ?...y
echo tao ?.../bin
y
echo shou ?...tao
再如: 
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

- -x exit的意思, 主要是配合-s使用. 

- -P 修改最大的进程数, 默认是1, 为0时候为as many as it can

## **其他查找命令**

### **1. locate命令**

locate命令其实是“find -name”的另一种写法, 但是要比后者快得多, 原因在于它不搜索具体目录, 而是搜索一个数据库（/var/lib/locatedb）, 这个数据库中含有本地所有文件信息. Linux系统自动创建这个数据库, 并且每天自动更新一次, 所以使用locate命令查不到最新变动过的文件. 为了避免这种情况, 可以在使用locate之前, 先使用updatedb命令, 手动更新数据库. 

**locate命令的使用实例: **

```
$ locate /etc/sh
搜索etc目录下所有以sh开头的文件. 
$ locate -i ~/m
搜索用户主目录下, 所有以m开头的文件, 并且忽略大小写. 
```

### **2. whereis命令**

whereis命令只能用于程序名的搜索, 而且只搜索二进制文件（参数-b）、man说明文件（参数-m）和源代码文件（参数-s）. 如果省略参数, 则返回所有信息. 

**whereis命令的使用实例: **

```
$ whereis grep
grep: /bin/grep /usr/share/man/man1p/grep.1p.gz /usr/share/man/man1/grep.1.gz
```

### **3. which命令**

which命令的作用是, 在PATH变量指定的路径中, 搜索某个系统命令的位置, 并且返回第一个搜索结果. 也就是说, 使用which命令, 就可以看到某个系统命令是否存在, 以及执行的到底是哪一个位置的命令. 

**which命令的使用实例: **

```
$ which grep
/bin/grep
```

## sed命令

> sed是stream editor的简称，也就是流编辑器。它一次处理一行内容，处理时，把当前处理的行存储在临时缓冲区中，称为“模式空间”（pattern space），接着用sed命令处理缓冲区中的内容，处理完成后，把缓冲区的内容送往屏幕。接着处理下一行，这样不断重复，直到文件末尾。文件内容并没有 改变，除非你使用重定向存储输出。

sed命令常用的使用方法为：

```
sed [option] 'command' input_file
```

常见的option选项：

`-n` 使用安静(silent)模式（想不通为什么不是-s）。在一般sed的用法中，所有来自stdin的内容一般都会被列出到屏幕上。但如果加上-n参数后，则只有经过sed特殊处理的那一行(或者动作)才会被列出来；
`-e` 直接在指令列模式上进行 sed 的动作编辑；
`-f` 直接将 sed 的动作写在一个文件内， `-f filename` 则可以执行filename内的sed命令；
`-r` 让sed命令支持扩展的正则表达式(默认是基础正则表达式)；
`-i` 直接修改读取的文件内容，而不是由屏幕输出。

常用的命令：

`a\`： append即追加字符串， a \的后面跟上字符串s(多行字符串可以用\n分隔)，则会在当前选择的行的后面都加上字符串s；

`c\`： 取代/替换字符串，c \后面跟上字符串s(多行字符串可以用\n分隔)，则会将当前选中的行替换成字符串s；

`d`： delete即删除，该命令会将当前选中的行删除；

`i\`： insert即插入字符串，i \后面跟上字符串s(多行字符串可以用\n分隔)，则会在当前选中的行的前面都插入字符串s；

`p`： print即打印，该命令会打印当前选择的行到屏幕上；

`s`： 替换，通常s命令的用法是这样的：`1，2s/old/new/g`，将old字符串替换成new字符串；其中的g 表示global全局替换，如果没有global的话，只会替换每一行中的第一个匹配的内容；

`=`： 显示文件行号 

在sed 命令中的定位问题：

定址用于决定对哪些行进行编辑。地址的形式可以是数字、正则表达式、或二者的结合。如果没有指定地址，sed将处理输入文件的所有行。

如： 3，表示第3行， 1,5 表示第1-5行， $ 表示最后一行；

/sb/ 表示包含sb的行， /sb/, /2b/ 表示包含 sb至包含 2b的行；

/^ha.*day$/  表示以ha开头，以day结尾的行

`s/\(.*\)line$/\1/g`  表示：`\(\)`包裹的内容表示正则表达式的第n部分，序号从1开始计算。本例中只有一个`\(\)`所以`\(.*\)`表示正则表达式的第一部分，这部分匹配任意字符串，所以`\(.*\)line$`匹配的就是以line结尾的任何行。用`\1`表示匹配到的第一部分，同样`\2`表示第二部分，`\3`表示第三部分，可以依次这样引用。 所以，它的意思是把每一行的line删除掉。

# 系统监控

## 查看磁盘空间

```
df -hl
```

显示格式为: 

```
文件系统              容量 已用 可用 已用% 挂载点　

Filesystem            Size Used Avail Use% Mounted on
```

`df -hl` 查看磁盘剩余空间

`df -h` 查看每个根路径的分区大小

`du -sh` [目录名] 返回该目录的大小

`du -sm` [文件夹] 返回该文件夹总M数

## 查看内存使用情况

`free`: 

```
root@localhost:~# free -h
              total        used        free      shared  buff/cache   available
Mem:           989M        121M         87M        7.0M        781M        662M
Swap:          255M         14M        241M
```

## 查看CPU信息

```
cat /proc/cpuinfo
```

## 查看内核所能打开的线程数

```
cat /proc/sys/kernel/threads-max
```

## 查看当前进程打开的文件

```
# 这里显示的数字需要减一, 因为第一行为头部标题信息
lsof -p ${PID} | wc -l
```

## 查看文件描述符

```
ls /proc/${PID}/fd |wc -l
```

# 挂载新硬盘并格式化硬盘

## 查看硬盘

```
ll -h /dev/sd*
```

输出:

```
brw-rw---- 1 root disk 8,  0 10月 11 09:20 /dev/sda
brw-rw---- 1 root disk 8,  1 10月 11 09:20 /dev/sda1
brw-rw---- 1 root disk 8,  2 10月 11 09:20 /dev/sda2
brw-rw---- 1 root disk 8,  5 10月 11 09:20 /dev/sda5
brw-rw---- 1 root disk 8, 16 10月 11 09:20 /dev/sdb
```

通过`sudo fdisk -l`也可以查看

## 新建分区

```
sudo fdisk /dev/sdb
```

之后进入command状态，大概是这么操作的：

- 输入 m 查看帮助
- 输入 p 查看 /dev/sdb 分区的状态
- 输入 n 创建sdb这块硬盘的分区
- 选 p primary =>输入　p
- Partition number =>分一个区所以输入　1
- 其他的默认回车即可
- 最后输入 w 保存并退出 Command 状态。

操作示例

```
Command (m for help): n
# n创建分区
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p
# p(primary主分区） e(extended拓展分区)
Partition number (1-4, default 1): 1
# 分区号
First sector (2048-83886079, default 2048): 
# 默认
Last sector, +sectors or +size{K,M,G,T,P} (2048-83886079, default 83886079): 
# 大小，可自定义，保持默认
Created a new partition 1 of type 'Linux' and of size 40 GiB.

Command (m for help): p
# 查看分区情况
Disk /dev/sdb: 40 GiB, 42949672960 bytes, 83886080 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xbb6c1792

Device     Boot Start      End  Sectors Size Id Type
/dev/sdb1        2048 83886079 83884032  40G 83 Linux

Command (m for help): w
# 保存
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

在通过查看命令即可查看，新增的硬盘.

## 格式化

ext4为分区格式:

```
sudo mkfs.ext4 /dev/sdb1
```

## 挂载

```
sudo mkdir /home/ybd/data
sudo mount /dev/sdb1 /home/ybd/data
```

### 开机自动挂载

查看sdb1的UUID:

```
$ sudo blkid
```

添加UUID到`/etc/fstab` 添加`UUID=63295b70-daec-4253-b659-821f51200be9 /home/data ext4 defaults,errors=remount-ro 0 1`到`/etc/fstab` 其中UUID后面跟sdb1的UUID 重启.

## 其他

如果涉及新硬盘的权限问题，可以通过chown，chmod命令调整权限.

# letsencrypt 自动脚本

***[https://github.com/Neilpang/acme.sh](https://github.com/Neilpang/acme.sh)***

#  Extend

## 使用systemd设置开机启动

> [ubuntu](https://www.centos.bz/category/other-system/ubuntu/)从16.04开始不再使用initd管理系统, 改用[systemd](https://www.centos.bz/tag/systemd/)

**为了像以前一样, 在`/etc/rc.local`中设置开机启动程序, 需要以下几步: **

**1、systemd默认读取`/etc/systemd/system`下的配置文件, 该目录下的文件会链接`/lib/systemd/system/`下的文件. 一般系统安装完`/lib/systemd/system/`下会有`rc-local.service`文件, 即我们需要的配置文件. **

链接过来: 

```
ln -fs /lib/systemd/system/rc-local.service /etc/systemd/system/rc-local.service
```

```
cd /etc/systemd/system/
vim rc-local.service
```

`rc-local.service`内容: 

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

**4、编辑rc.local, 添加需要开机启动的任务**

```
#!/bin/bash

echo "test test " > /var/test_boot_up.log
```

**5、执行reboot重启系统验证OK. **

最后, 说一下`/etc/systemd/system/`下的配置文件（`XXXX.service`）,
其中有三个配置项, `[Unit]` / `[Service]` / `[Install]`

- `[Unit]` 区块: 启动顺序与依赖关系. 
- `[Service]` 区块: 启动行为,如何启动, 启动类型. 
- `[Install]` 区块, 定义如何安装这个配置文件, 即怎样做到开机启动. 

## apt-get update无法下载

![](https://oldcdn.yangbingdong.com/img/node-of-ubuntu-command/apt-get-update-fail.png)

出现类似情况, 可以找到`/etc/apt/sources.list.d`目录, 删除对应的`.list`文件即可.

## printf进制转换

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

输出的是`29a`, 一般16进制前面会加个`0x`表示, 所以可以这样: 

```
printf "0x%x\n" 666
```

16进制转十进制:

```
printf "%d\n" 0x29a
```

## Shell自动交互

### 输入重定向Here Document

```
#!/bin/bash

ftp -i -n 192.168.167.187 << EOF
user hzc 123456
pwd
cd test
pwd
close
bye
EOF
```

### 管道，echo + sleep + |

```
#!/bin/bash

(echo "curpassword"
sleep 1
echo "newpassword"
sleep 1
echo "newpassword")|passwd
```

### expect

```
sudo apt-get install expect 
```

## Shell脚本加密

```
sudo apt install -y shc
```

```
shc -e "01/12/2019" -m "Script expired, pleace contact yangbingdong1994@gmail.com" -v -r -T -f shell.sh
```

* `-e`: 过期时间
* `-m`: 过期消息
* `-f`: 需要加密的脚本

## 写入文件或追加

有时候简单的东西不想通过 vi 编辑文件, 或者在脚本中需要写入或追加文字到文件中, 我们可以通过以下方式实现.

1. 单行通过 `echo` 实现:

   ```
   # 覆盖写入
   echo "hello" > test.txt
   
   # 追加
   echo "hello" >> test.txt
   ```

2. 多行可以通过 `cat` 实现:

   ```
   # 覆盖写入
   cat <<- EOF > test.txt
   hello1
   hello2
   EOF
   
   # 追加
   cat <<- EOF >> test.txt
   hello1
   hello2
   EOF
   ```

3. 当文件需要权限时, 可使用 `tee` 命令实现:

   ```
   # 覆盖写入
   echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/sudoers
   
   # 追加
   echo "forward-socks5 / 127.0.0.1:1080 ." | sudo tee -a /etc/privoxy/config
   ```

   当然也可以多行输入:

   ```
   sudo tee /etc/docker/daemon.json <<- EOF
   {
     "registry-mirrors": ["${DOCKER_MIRRORS}"]
   }
   EOF
   ```

   

# Finally

附上 Linux 命令行的艺术: ***[https://github.com/jlevy/the-art-of-command-line](https://github.com/jlevy/the-art-of-command-line)***