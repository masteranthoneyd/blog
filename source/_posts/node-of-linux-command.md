---
title: Linux 常用命令
date: 2017-09-20 18:05:10
categories: [OperatingSystem,Ubuntu]
tags: [Ubuntu]
---

# preface
> =.= 这里只记录一些个人比较常用到的命令
> 那些太基本以及太高深的就。。。。。


<!--more-->
# SSH相关
## 保持长连接
只需要在ssh命令后加上发送心跳即可：
```
ssh -o ServerAliveInterval=30 root@123.456.88 -p 2333
```

## 生成SSH密钥和公钥
打开终端，使用下面的ssh-keygen来生成RSA密钥和公钥。`-t`表示type，就是说要生成`RSA`加密的钥匙：
```shell
ssh-keygen -t rsa -C "your_email@youremail.com"
```
`RSA`也是默认的加密类型，所以你也可以只输入`ssh-keygen`，默认的`RSA`长度是2048位，如果你非常注重安全，那么可以指定4096位的长度：
```shell
ssh-keygen -b 4096 -t rsa -C "your_email@youremail.com"
```
生成SSH Key的过程中会要求你指定一个文件来保存密钥，按Enter键使用默认的文件就行了，然后需要输入一个密码来加密你的SSH Key，密码至少要20位长度，SSH密钥会保存在home目录下的`.ssh/id_rsa`文件中，SSH公钥保存在`.ssh/id_rsa.pub`文件中。
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
su ybd
```

这样就切换到了`ybd`用户，如果不加用户名，默认是 `su root`切换`root`用户。
**注意**：`su` 和 `su -`的区别

- 前者是直接切换，还**保留了当前位置以及变量**
- 而后者不单单切换了用户，而且还**切换到了用户目录**，并且之前用户的**环境变量没有了**！


> 之前就因为这个原因，写Dockerfile困扰了好一段时间...囧

还有`su`也可以使用某个用户的身份执行一些命令，ex：

```
su - ${USER_NAME} -c "npm install -g hexo-cli"
su - ${USER_NAME} -c shell.sh
```

执行完之后还是保持当前用户。






