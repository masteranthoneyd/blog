---
title: Ubuntu 常用命令
date: 2017-09-20 18:05:10
categories: [OperatingSystem,Ubuntu]
tags: [Ubuntu]
---

![](http://ojoba1c98.bkt.clouddn.com/img/node-of-ubuntu-command/ubuntu-logo.png)

# Preface

> =.= 这里只记录一些个人比较常用到的[*Ubuntu*](https://www.ubuntu.com)命令
> 那些太基本以及太高深的就......


<!--more-->
# SSH相关
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
ex：
```
scp -P 2333 /home/ybd/file root@123.456.78:/root/file
```

## 免密码登录远程服务器
### 姿势一
使用上述`scp`把公钥上传到服务器，然后：
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
`su -`就是`su -l`(l为login的意思)，`l`可以省略，所以一般写成`su -`.....
如果不加用户名，默认是 `su root`切换`root`用户。
**注意**：`su` 和 `su -`的区别

- 前者是直接切换，还**保留了当前位置以及变量**
- 而后者不单单切换了用户，而且还**切换到了用户目录**，并且之前用户的**环境变量没有了**！

> 之前就因为这个原因，写`Dockerfile`困扰了好一段时间...囧

还有`su`也可以使用某个用户的身份执行一些命令，ex：
```
# 执行单个命令
su - ${USER_NAME} -c "npm install -g hexo-cli"
# 执行shell脚本
su - ${USER_NAME} -s /bin/bash shell.sh
```

执行完之后还是保持当前用户。
可以通过`exit`退出当前用户。

# 防火墙
1、查看端口是否开启：
```
telnet 192.168.1.103 80
```

2、查看本地的端口开启情况：
```
sudo ufw status
```

3、打开80端口：
```
sudo ufw allow 80
```

4、防火墙开启：
```
sudo ufw enable
```

5、防火墙重启：
```
sudo ufw reload
```

# 用户与用户组相关

## 添加用户useradd
![](http://ojoba1c98.bkt.clouddn.com/img/node-of-ubuntu-command/command-useradd.png)

ex：
创建ybd用户并且加入ybd用户组并且创建用户目录：

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

![](http://ojoba1c98.bkt.clouddn.com/img/node-of-ubuntu-command/command-usermod.png)

## 添加用户组groupadd
![](http://ojoba1c98.bkt.clouddn.com/img/node-of-ubuntu-command/command-groupadd.png)


## 修改用户组
![](http://ojoba1c98.bkt.clouddn.com/img/node-of-ubuntu-command/command-groupmod.png)

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
在Windows系统中，有C、D、E等众多的盘符，每个盘符就是一个根目录。在`Linux`、`Unix`、`MacOS`等系统的文件系统中，只有一个根目录，那就是`root`，以一个斜杠代表（`/`）。
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
在Linux、Unix、MacOS等系统中，隐藏文件均是点（.）开头的，下面命令以列表显示当前目录所有的目录和文件，包括隐藏的目录和文件。
```
ls -al
```
显示所有的目录，包括隐藏的目录，但是不包括文件
```
ls -adl
```
## 复制：`cp`
cp是copy的简称，用于复制文件和目录。复制的时候，源路径和目录路径可以是一个文件，也可以是一个目录。
```
cp <源路径> <目标路径>
```
## 移动：`mv`
mv是移动(move)的简称，用于移动文件和目录。
```
mv  <源路径> <目标路径>
```
## 删除：`rm`
`rm`命令可以用于删除目录和文件，但是通过`rm`删除目录的话，必须加上`rm -rf <目录名称>`。
删除文件直接就是`rm <文件名>`

注意：
在Linux或者Unix系统中，通过rm或者文件管理器删除文件将会从文件系统的目录结构上解除链接(unlink).
然而如果文件是被打开的（有一个进程正在使用），那么进程将仍然可以读取该文件，磁盘空间也一直被占用。
可以通过`lsof`命令查看文件是否被打开。详见 列出打开的文件。
## 删除目录：rmdir
删除目录的时候，必须确保目录是空的，否则无法删除。命令格式：`rm <目录>`。





















