---
title: Access Blocked Sites(科学上网):VPS自搭建ShadowSocks与加速
date: 2017-04-19 18:15:57
categories: [VPS]
tags: [VPS,ShadowSocks]
---
![](https://cdn.yangbingdong.com/img/vps/whats-shadowsocks-04.png)
# Preface
> 最近在玩***[VPS](http://baike.baidu.com/link?url=ehKAXxj45AdvSmxPRwiao9anB3Tej-jwgKXWMkTuA43M2479GPT-FkH6zMhI59Eip_iY5abNL2jODlGC4WiLW_)***，作为没有Google就活不下去的开发人员，翻山越岭已是日常= =...使用别人的VPN或者Sock5代理显然是不安全的，个人信息随时被截获，那么拥有一台自己VPS也是必需的，价格也可以很便宜（绝对不是在打广告）
>
> 如果是要使用Linode作为VPS的并且还没注册的朋友，可以填上我的邀请码: `79e24952d46644605b071a55c4fda3b23e1d1a5a` 

<!--more-->
# ShadowSocks介绍

![](https://cdn.yangbingdong.com/img/docker-shadowsocks/shadowsocks.png)

## What is ShadowSocks
ShadowSocks(影梭) 是由***[clowwindy](https://github.com/shadowsocks/shadowsocks)***所开发的一个开源 Socks5 代理。如其***[官网](http://shadowsocks.org/en/index.html)***所言 ，它是 “`A secure socks5 proxy, designed to protect your Internet traffic`” （一个安全的 `Socks5` 代理）。其作用，亦如该项目主页的 ***[wiki](https://github.com/shadowsocks/shadowsocks/wiki)***（***[中文版](https://github.com/shadowsocks/shadowsocks/wiki/Shadowsocks-%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E)***） 中所说，“`A fast tunnel proxy that helps you bypass firewalls`” （一个**可穿透防火墙**的快速代理）。
不过，在中国，由于***[GFW](https://zh.wikipedia.org/wiki/%E9%98%B2%E7%81%AB%E9%95%BF%E5%9F%8E)***[^1]的存在，更多的网友用它来进行**科学上网**。

## This is a story...
### long long ago…
我们的互联网通讯是这样的：
![](https://cdn.yangbingdong.com/img/vps/whats-shadowsocks-01.png)
### when evil comes
然后有一天，GFW[^1] 就出现了，他像一个收过路费的强盗一样夹在了在用户和服务之间，每当用户需要获取信息，都经过了 GFW，GFW将它不喜欢的内容统统过**滤掉**，于是客户当触发 GFW 的**过滤规则**的时候，就会收到 `Connection Reset` 这样的响应内容，而无法接收到正常的内容：
![](https://cdn.yangbingdong.com/img/vps/whats-shadowsocks-02.png)
### ssh tunnel
聪明的人们想到了**利用境外服务器代理**的方法来绕过 GFW 的过滤，其中包含了各种HTTP代理服务、Socks服务、VPN服务… 其中以 `ssh tunnel` 的方法比较有代表性：
1) 首先用户和境外服务器基于 ssh 建立起一条加密的通道
2-3) 用户通过建立起的隧道进行代理，通过 ssh server 向真实的服务发起请求
4-5) 服务通过 ssh server，再通过创建好的隧道返回给用户
![](https://cdn.yangbingdong.com/img/vps/whats-shadowsocks-03.png)
由于 ssh 本身就是基于 `RSA` 加密技术，所以 GFW 无法从数据传输的过程中的加密数据内容进行关键词分析，**避免了被重置链接的问题**，但由于创建隧道和数据传输的过程中，**ssh 本身的特征是明显的**，所以 GFW 一度通过分析连接的特征进行**干扰**，导致 ssh**存在被定向进行干扰的问题**。
### shadowsocks
于是 clowwindy 同学**分享并开源**了他的解决方案。
简单理解的话，shadowsocks 是将原来 ssh 创建的 Socks5 协议**拆开**成 server 端和 client 端，所以下面这个原理图基本上和利用 ssh tunnel 大致类似。
1、6) 客户端发出的请求基于 Socks5 协议跟 ss-local 端进行通讯，由于这个 ss-local 一般是本机或路由器或局域网的其他机器，不经过 GFW，所以解决了上面被 GFW 通过特征分析进行干扰的问题
2、5) ss-local 和 ss-server 两端通过多种可选的加密方法进行通讯，经过 GFW 的时候是常规的TCP包，没有明显的特征码而且 GFW 也无法对通讯数据进行解密
3、4) ss-server 将收到的加密数据进行解密，还原原来的请求，再发送到用户需要访问的服务，获取响应原路返回
![](https://cdn.yangbingdong.com/img/vps/whats-shadowsocks-04.png)

# VPS选择
## BandwagonHOST
***[BandwagonHOST](https://bandwagonhost.com/)***俗称搬瓦工，隶属于美国IT7旗下的VPS服务品牌，VPS采用OpenVZ架构，主要针对低端VPS市场。
具体节点的选择，可以在浏览器中输入以下IP进行实际测试（测试地址由***[www.banwagong.com](http://www.banwagong.com/)***提供）：
美国洛杉矶 US West Coast-Los Angeles：[104.224.162.217](http://104.224.162.217/)
美国佛罗里达 US West Coast-Florida：[104.224.141.127](http://104.224.141.127)
欧洲 荷兰 EU-Netherlands：[104.224.145.203](http://104.224.145.203)
美国 凤凰城 US, Arizona ：[45.62.112.117](http://45.62.112.117)
一般而言，中国用户使用**洛杉矶**和**凤凰城**的机房会有较好的网络体验。
**注**：搬瓦工已被墙，需要翻墙访问。搬瓦工从15年6月26日起**支持支付宝**付款。

## Digital Ocean
***[DigitalOcean](https://www.digitalocean.com/)***是一家位于美国的云主机服务商，总部位于纽约，成立于2012年，VPS 核心架构采用KVM架构。由于价格低廉，高性能配置、灵活布置的优势，近些年来发展迅猛。
该公司拥有多个数据中心，分布在：New York( Equinix 和 Telx 机房), San Francisco ( Telx ), Singapore ( Equinix ), Amsterdam ( TelecityGroup ), Germany ( Frankfurt ). 其私有数据网络供应商是Level3, NTT, nLayer, Tinet, Cogent, 和Telia。
一般而言，建议**非电信用户**可以采用新加坡节点，速度非常给力。**电信用户不建议采用此VPS**，速度比较一般，更推荐 Vultr 和 Linode 的日本机房。

## Vultr
***[Vultr](https://www.vultr.com)*** 是一家成立于2014年的VPS提供商。根据域名所有者资料，母公司是2005年成立于新泽西州的 ClanServers Hosting LLC 公司，他们家的游戏服务器托管在全球6个国家的14个数据中心，选择非常多。 Vultr 家的服务器采用的 E3 的 CPU ，清一色的 Intel 的 SSD 硬盘，VPS**采用KVM架构**。 Vultr 的计费按照使用计费（自行选择配置、可以按月或按小时计费），用多少算多少，可以随时取消，另外**可以自己上传镜像**安装需要的操作系统也是一大亮点。现在已经成为 Digital Ocean 的有力竞争对手。
Vultr的服务器托管在全球14个数据中心，即时开通使用。大陆访问日本机房速度不错，延迟低、带宽足。

## Linode
***[Linode](https://www.linode.com)*** 是VPS 服务商中的大哥，高富帅般的存在。价格相对较高，但是性能，稳定性等各方面也非常给力。 VPS 采用 Xen 架构，不过最近的周年庆开始升级到 KVM 架构，VPS 性能进一步提升。推荐给对连接速度和网络延迟有极致追求的用户。
Linode只能使用**信用卡支付**，官方会随机手工抽查，被抽查到的话需要上传信用卡正反面照片以及可能还需要身份证正反面照片，只要材料真实齐全，审核速度很快，一般一个小时之内就可以全部搞定。账户成功激活以后，就可以安心使用了。

博主的邀请码: `79e24952d46644605b071a55c4fda3b23e1d1a5a`

# 准备工作

## 准备一台VPS

博主选择***[Linode](https://www.linode.com)***

博主的邀请码: `79e24952d46644605b071a55c4fda3b23e1d1a5a`

## SSH无密码登录VPS

参考 ***[免密码登录远程服务器](/2017/node-of-linux-command/#免密码登录远程服务器)***

# ShadowSocks服务端安装
> 安装方式各种各样。。。推荐Docker安装

## 基于Docker安装

详细教程不在本篇范围内，请看***[Docker入门笔记](/2017/docker-learning)***
以下是最简单快捷高效的安装方式：

```
curl -fsSL get.docker.com -o get-docker.sh
sh get-docker.sh
```

就是这么粗暴的两条命令=.=
这里可能会有个小问题，如果VPS使用的`IPv6`可能会导致`apt update`失败，解决办法是把上面下载的`get-docker.sh`里面所有的`apt-get update`改为`apt-get Acquire::ForceIPv4=true update`。

### 拉取镜像

`Showdowsocks`镜像：***[https://hub.docker.com/r/mritd/shadowsocks/](https://hub.docker.com/r/mritd/shadowsocks/)***

```
docker pull mritd/shadowsocks:latest
```

### 运行

**With Kcptun**

```
docker run -dt --name ssserver --restart=always -p 6443:6443 -p 6500:6500/udp mritd/shadowsocks:latest -m "ss-server" -s "-s 0.0.0.0 -p 6443 -m aes-256-cfb -k 123456 --fast-open" -x -e "kcpserver" -k "-t 127.0.0.1:6443 -l :6500 -mode fast2"
```

**说明：**

- `-m` : 参数后指定一个 `shadowsocks` 命令，如 `ss-local`，不写默认为 `ss-server`；该参数用于 shadowsocks 在客户端和服务端工作模式间切换，可选项如下: `ss-local`、`ss-manager`、`ss-nat`、`ss-redir`、`ss-server`、`ss-tunnel`
- `-s` : 参数后指定一个 `shadowsocks-libev` 的参数字符串，所有参数将被拼接到 `ss-server` 后
- `-x` : 指定该参数后才会开启 `kcptun` 支持，否则将默认禁用 `kcptun`
- `-e` : 参数后指定一个 `kcptun` 命令，如 `kcpclient`，不写默认为 `kcpserver`；该参数用于 kcptun 在客户端和服务端工作模式间切换，可选项如下: `kcpserver`、`kcpclient`
- `-k` : 参数后指定一个 `kcptun` 的参数字符串，所有参数将被拼接到 `kcptun` 后

**Without Kcptun**

```
docker run -dt --name ssserver --restart=always -p 6443:6443 mritd/shadowsocks:latest -m "ss-server" -s "-s 0.0.0.0 -p 6443 -m aes-256-cfb -k 123456 --fast-open"
```

ss命令说明：

- `-s` : 监听服务ip，为服务器本地
- `-p` : 端口
- `-m` : 加密算法
- `-k` : 密码
- `--fast-open` : 开启TCP `fast-open`

kcptun命令自行度娘=.=

## 脚本一键安装

> 更多精彩被容请移步到 ***[https://teddysun.com/](https://teddysun.com/)***

root用户执行：

```
wget --no-check-certificate -O shadowsocks-all.sh https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-all.sh
chmod +x shadowsocks-all.sh
./shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log
```

### 安装完成后，脚本提示如下

```
Congratulations, your_shadowsocks_version install completed!
Your Server IP        :your_server_ip
Your Server Port      :your_server_port
Your Password         :your_password
Your Encryption Method:your_encryption_method

Your QR Code: (For Shadowsocks Windows, OSX, Android and iOS clients)
 ss://your_encryption_method:your_password@your_server_ip:your_server_port
Your QR Code has been saved as a PNG file path:
 your_path.png

Welcome to visit:https://teddysun.com/486.html
Enjoy it!
```

### 卸载方法

若已安装多个版本，则卸载时也需多次运行（每次卸载一种）

使用root用户登录，运行以下命令：

```
./shadowsocks-all.sh uninstall
```

### 启动脚本

启动脚本后面的参数含义，从左至右依次为：启动，停止，重启，查看状态。

**Shadowsocks-Python** 版：
`/etc/init.d/shadowsocks-python start | stop | restart | status`

**ShadowsocksR** 版：
`/etc/init.d/shadowsocks-r start | stop | restart | status`

**Shadowsocks-Go** 版：
`/etc/init.d/shadowsocks-go start | stop | restart | status`

**Shadowsocks-libev** 版：
`/etc/init.d/shadowsocks-libev start | stop | restart | status`

### 各版本默认配置文件

**Shadowsocks-Python** 版：
`/etc/shadowsocks-python/config.json`

**ShadowsocksR** 版：
`/etc/shadowsocks-r/config.json`

**Shadowsocks-Go** 版：
`/etc/shadowsocks-go/config.json`

**Shadowsocks-libev** 版：
`/etc/shadowsocks-libev/config.json`

## 手动安装

### 安装

```shell
apt-get update
apt-get install python-pip
pip install shadowsocks
```

### 修改配置文件

```shell
vi /etc/shadowsocks.json
```
添加以下内容：
```json
{
    "server":"my_server_ip",
    "server_port":8388,
    "local_address": "127.0.0.1",
    "local_port":1080,
    "password":"mypassword",
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open": false
}
```
| name        | info                                     |
| ----------- | ---------------------------------------- |
| server      | 服务器 IP (IPv4/IPv6)，注意这也将是服务端监听的 IP 地址    |
| server_port | 服务器端口                                    |
| local_port  | 本地端端口                                    |
| password    | 用来加密的密码                                  |
| timeout     | 超时时间（秒）                                  |
| method      | 加密方法，可选择 “bf-cfb”, “aes-256-cfb”, “des-cfb”, “rc4″, 等等。默认是一种不安全的加密，推荐用 “aes-256-cfb” |

只需要把 `my_server_ip`换成你VPS的IP，并且把 `mypassword` 换成你自己的密码，注意：这个密码不是你登录VPS的密码，是你一会从ShadowSocks客户端登录的时候用的密码.
`server_port`默认8388也行，你修改也行，这个端口是ShadowSocks客户端登录时用的端口号，如果你修改了，最好改成1024至65536之间的一个数字，并且自己一定要记住。其它的都默认就好。

### 启动服务

下面就可以开始启动ShadowSocks服务端了。ShadowSocks服务端自身就已经支持后台运行了，所以，通过下面的命令启动之后，只要你的VPS不关机不重启，ShadowSocks服务端就会一直在后台运行。
```shell
ssserver -c /etc/shadowsocks.json -d start
```
![](https://cdn.yangbingdong.com/img/vps/shadowsocks-startup.png)
看到`started`没有，这就表示你的ShadowSocks服务端就已经启动了。此时就可以关掉你的终端，然后打开你的ShadowSocks客户端进行连接了。

最后一步，将ShadowSocks加入开机启动。很简单，只需在/etc/rc.local加一句话就成。通过如下命令打开rc.local文件
```shell
vi /etc/rc.local
```
在`exit 0`的上一行添加以下内容：
```shell
/usr/bin/python /usr/local/bin/ssserver -c /etc/shadowsocks.json -d start
```
粘贴完成后，和上面编辑配置文件一样，选按键盘左上角的“ESC”键，然后输入”:wq”，保存退出。这样，开机就会自动启动ShadowSocks了。不信，你可以试一下。

# ShadowSocks客户端安装
## 安装与启动

### Docker

**With Kcptun**

```
docker run -dt --name ssclient --restart=always -p 1080:1080 -p 6500:6500/udp mritd/shadowsocks:latest -m "ss-local" -s "-s 127.0.0.1 -p 6500 -b 0.0.0.0 -l 1080 -m aes-256-cfb -k 123456 --fast-open" -x -e "kcpclient" -k "-r server-ip:6500 -l :6500 -mode fast2"
```

**Without Kcptun**

```
docker run -dt --name ssclient --restart=always -p 1080:1080 mritd/shadowsocks:latest -m "ss-local" -s "-s server-ip -p 6443 -b 0.0.0.0 -l 1080 -m aes-256-cfb -k 123456 --fast-open"
```

**注意：**
如果使用了**With Kcptun**，ss的监听ip填本地 `127.0.0.1`，`server-ip`填服务器`ip`。

测试了一下，在开启了BBR情况下，**without kcptun**更快。
对于一般情况（没有开启BBR或其他加速），**with kcptun**速度有所提升。

### pip 安装
#### 安装
用PIP安装很简单：
```shell
sudo apt-get update
sudo apt-get install python-pip
sudo apt-get install python-setuptools m2crypto
```
接着安装ShadowSocks：
```shell
pip install shadowsocks
```

> 如果是ubuntu16.04 直接 (16.04 里可以直接用apt 而不用 apt-get 这是一项改进。
> `sudo apt install shadowsocks`
> 当然你在安装时候肯定有提示需要安装一些依赖比如python-setuptools m2crypto ，依照提示安装然后再安装就好。也可以网上搜索有很多教程的。

#### 启动
安装好后，在本地我们要用到sslocal ，终端输入sslocal --help 可以查看帮助，像这样
![](https://cdn.yangbingdong.com/img/vps/sslocal-help.png)
通过帮助提示我们知道各个参数怎么配置，比如 sslocal -c 后面加上我们的json配置文件，或者像下面这样直接命令参数写上运行。
比如 
```
sslocal -s 11.22.33.44 -p 50003 -k "123456" -l 1080 -t 600 -m aes-256-cfb
```
> -s表示服务IP, -p指的是服务端的端口，-l是本地端口默认是1080, -k 是密码（要加""）, -t超时默认300,-m是加密方法默认aes-256-cfb。

为了方便我推荐直接用`sslcoal -c` 配置文件路径 这样的方式，简单好用。
我们可以在/home/ybd/ 下新建个文件shadowsocks.json  (ybd是我在我电脑上的用户名，这里路径你自己看你的)。内容是这样：
```json
{
"server":"11.22.33.44",
"server_port":8388,
"local_port":1080,
"password":"123456",
"timeout":600,
"method":"aes-256-cfb"
}
```
`server`：  你服务端的IP
`servier_port`：  你服务端的端口
`local_port`：  本地端口，一般默认1080
`passwd`：  ss服务端设置的密码
`timeout`：  超时设置 和服务端一样
`method`：  加密方法 和服务端一样
确定上面的配置文件没有问题，然后我们就可以在终端输入 `sslocal -c /home/ybd/shadowsocks.json` 回车运行。如果没有问题的话，下面会是这样...
![](https://cdn.yangbingdong.com/img/vps/launch-sslocal.png)

如果你选择这一种请跳过第二种。你可以去系统的代理设置按照说明设置代理，但一般是全局的，然而我们访问baidu,taobao等着些网站如果用代理就有点绕了，而且还会浪费服务器流量。我们最好配置我们的浏览器让它可以自动切换，该用代理用代理该直接连接自动直接连接。所以请看配置浏览器。

### Shadowsocks Qt5
安装GUI 图形界面程序，然后按照提示配置相对应的参数。安装教程地址：***[ShadowSocks-qt5 安装指南](https://github.com/shadowsocks/shadowsocks-qt5/wiki/%E5%AE%89%E8%A3%85%E6%8C%87%E5%8D%97)***

在ubuntu上可以这样，通过PPA源安装，**仅支持Ubuntu 14.04或更高版本**。
```shell
sudo add-apt-repository ppa:hzwhuang/ss-qt5
sudo apt-get update
sudo apt-get install shadowsocks-qt5
```
由于是图形界面，配置和windows基本没啥差别就不赘述了。经过上面的配置，你只是启动了sslocal 但是要上网你还需要配置下浏览器到指定到代理端口比如1080才可以正式上网。

## 开机后台自动运行ss客户端
**如果你选择了第二种可以不管这个**
如果你上面可以代理上网了可以进行这一步，之前让你不要关掉终端，因为关掉终端的时候代理就随着关闭了，之后你每次开机或者关掉终端之后，下次你再想用代理就要重新在终端输入这样的命令 `sslocal  -c /home/ybd/shadowsocks.json` ，挺麻烦是不？

我们现在可以在你的Ubuntu上安装一个叫做`supervisor`的程序来管理你的`sslocal`启动。
```shell
sudo apt-get install supervisor
```
安装好后我们直接在`/etc/supervisor/conf.d/`下新建个文件比如`ss.conf`然后加入下面内容：
```shell
[program:shadowsocks]
command=sslocal -c /home/ybd/shadowsocks.json
autostart=true
autorestart=true
user=root
log_stderr=true
logfile=/var/log/shadowsocks.log
```
`command = `这里json文件的路径根据你的文件路径来填写。确认无误后记得保存。`sslocal` 和`ssserver`这两个命令是被存在 `/usr/bin/`下面的，我们要拷贝一份命令文件到`/bin`
```shell
sudo cp /usr/bin/sslocal /bin 
sudo cp /usr/bin/ssserver /bin 
```
现在关掉你之前运行`sslocal`命令的终端，再打开终端输入`sudo service supervisor restart` 然后去打开浏览器看看可不可以继续代理上网。你也可以用`ps -ef|grep sslocal`命令查看`sslocal`是否在运行。

这个时候我们需要在`/etc`下编辑一个叫`rc.local`的文件 ，让`supervisor`开机启动。
```shell
sudo gedit /etc/rc.local
```
在这个配置文件的`exit 0`**前面**一行加上 `service supervisor start` 保存。看你是否配置成功你可以在现在关机重启之后直接打开浏览器看是否代理成功。

还有一种方法就是：
```bash
sudo systemctl enable supervisor
```
然后重启即可

# 番外篇：服务端一键安装
## 搬瓦工一键安装
搬瓦工早就知道广大使用者的~~阴谋~~意图，所以特意提供了**一键无脑安装Shadowsocks**。
注意：**目前只支持CentOS**。
进入KiwiVM后，在左边的选项栏的最下面：
![](https://cdn.yangbingdong.com/img/vps/one-key-install-shadowsocks.png)
点击Install之后会出现如下界面代表安装成功：
![](https://cdn.yangbingdong.com/img/vps/one-key-install-shadowsocks01.png)
点GO Back可看到相关信息了

# 使用ShadowSocks代理实现科学上网

**毕竟Shadowsocks是sock5代理，不能接受http协议，所以我们需要把sock5转化成http流量。**

## 配置浏览器代理
假如你上面任选一种方式已经开始运行`sslocal`了，火狐那个代理插件老是订阅不了`gfwlist`所以配置自动模式的话不好使。这里用的是chrome，你可以在Ubuntu软件中心下载得到。

### 安装插件
我们需要给chrome安装`SwitchyOmega`插件，但是没有代理之前是不能从谷歌商店安装这个插件的，但是我们可以从Github上直接下载最新版***[https://github.com/FelisCatus/SwitchyOmega/releases/](https://github.com/FelisCatus/SwitchyOmega/releases/)***（这个是chrome的）然后浏览器地址打开`chrome://extensions/`，将下载的插件托进去安装。

### 设置代理地址
安装好插件会自动跳到设置选项，有提示你可以跳过。左边新建情景模式-选择代理服务器-比如命名为shadowProxy（叫什么无所谓）其他默认之后创建，之后在代理协议选择SOCKS5，地址为`127.0.0.1`,端口默认`1080` 。然后保存即应用选项。
![](https://cdn.yangbingdong.com/img/vps/proxy.png)
![](https://cdn.yangbingdong.com/img/vps/proxy01.png)

### 设置自动切换
接着点击自动切换 ( Auto switch）上面的不用管，在按照规则列表匹配请求后面选择刚才新建的SS，默认情景模式选择直接连接。点击应用选项保存。再往下规则列表设置选择`AutoProxy` 然后将**[这个地址](https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt)**填进去，点击下面的立即更新情景模式，会有提示更新成功！
![](https://cdn.yangbingdong.com/img/vps/proxy03.png)

点击浏览器右上角的SwitchyOmega图标，下面选择自动切换，然后打开google.com试试，其他的就不在这贴图了。
![](https://cdn.yangbingdong.com/img/vps/proxy04.png)

## GenPAC全局代理
如果不想每个浏览器都要设置代理，可以通过GenPAC实现全局代理。
### 安装
pip：
```shell
sudo apt-get install python-pip python-dev build-essential 
sudo pip install --upgrade pip 
sudo pip install --upgrade virtualenv 
```
GenPAC：
```shell
sudo pip install genpac
sudo pip install --upgrade genpac
```

### 设置全局代理
1、进入终端，Ctrl+Alt+T，cd到你希望生成文件存放的位置。
例如：
```shell
cd /home/ybd/Data/application/shadowsocks
```
2、执行下面的语句：
```shell
sudo genpac --proxy="SOCKS5 127.0.0.1:1080" --gfwlist-proxy="SOCKS5 127.0.0.1:1080" -o autoproxy.pac --gfwlist-url="https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
```
**注意**：
上面语句中`127.0.0.1:1080`应按照自己的情况填写。
如果出现下面这种报错：
```shell
fetch gfwlist fail. online: https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt local: None
```
那么换成执行下面的语句：
```shell
sudo genpac --proxy="SOCKS5 127.0.0.1:1080" -o autoproxy.pac --gfwlist-url="https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
```

如果出现`base64 decoding fail .`，安装其他版本：
```
sudo pip install https://github.com/JinnLynn/genpac/archive/master.zip
sudo pip install --upgrade https://github.com/JinnLynn/genpac/archive/master.zip
sudo pip uninstall genpac
```

3、全局代理
系统设置 –> 网络 –> 网络代理
“方法”选择“自动”
“配置URL”填写：
`file:///home/ybd/Data/application/shadowsocks/autoproxy.pac`
点击“应用到整个系统”，接下来可以愉悦的跨过墙了～

## Proxychains 代理
安装proxychains：
```shell
sudo apt install proxychains
```
配置proxychains：
编辑`/etc/proxychains.conf`，最下面有一行`socks4 127.0.0.1 9050`，把这一行注释掉，添加一行`socks5 127.0.0.1 1080`
测试：
```shell
proxychains curl www.google.com
```
使用：
用命令行启动软件，在前面加上proxychains，如：
```shell
proxychains firefox
```
使用`shadowsocks`+`proxychains`代理打开新的Firefox实现浏览器翻墙。 
也可以通过输入`proxychains bash`建立一个新的`shell`，基于这个`shell`运行的所有命令都将使用代理。

## Privoxy

Privoxy是一款带过滤功能的代理服务器，针对HTTP、HTTPS协议。通过Privoxy的过滤功能，用户可以保护隐私、对网页内容进行过滤、管理cookies，以及拦阻各种广告等。Privoxy可以用作单机，也可以应用到多用户的网络。

```
sudo apt install privoxy
```

安装好后进行配置，Privoxy的配置文件在`/etc/privoxy/config`，这个配置文件中注释很多。

找到`4.1. listen-address`这一节，确认监听的端口号。

![](https://cdn.yangbingdong.com/img/vps/privoxy-config01.png)

找到`5.2. forward-socks4, forward-socks4a, forward-socks5 and forward-socks5t`这一节，加上如下配置，注意最后的点号。

![](https://cdn.yangbingdong.com/img/vps/privoxy-config02.png)

重启一下Privoxy

```
sudo /etc/init.d/privoxy restart
```

终端体验：

```
export http_proxy="127.0.0.1:8118" && export https_proxy="127.0.0.1:8118"
wget http://www.google.com
```

在`/etc/profile`的末尾添加如下两句。

```
export http_proxy="127.0.0.1:8118"
export https_proxy="127.0.0.1:8118"
```

# ShadowSocks优化

> 更多详情请见：***[https://github.com/iMeiji/shadowsocks_install/wiki/shadowsocks-optimize](https://github.com/iMeiji/shadowsocks_install/wiki/shadowsocks-optimize)***

## 开启TCP Fast Open
**这个需要服务器和客户端都是Linux 3.7+的内核**
在服务端和客户端的`/etc/sysctl.conf`都加上：
```
# turn on TCP Fast Open on both client and server side
net.ipv4.tcp_fastopen = 3
```
然后把`vi /etc/shadowsocks.json`配置文件中`"fast_open": false`改为`"fast_open": true`

## 使用特殊端口
GFW会通过某些手段来减轻数据过滤的负荷，例如特殊的端口如ssh，ssh默认端口给ss用了那么久必须修改我们登录服务器的端口。
修改SSH配置文件：
```shell
vi /etc/ssh/sshd_config
```
找到`#port 22`，将前面的`#`去掉，然后修改端口 `port 2333`（自己设定）。
然后重启SSH：
```shell
service ssh restart
```

# 多用户管理

***[https://github.com/mmmwhy/ss-panel-and-ss-py-mu](https://github.com/mmmwhy/ss-panel-and-ss-py-mu)*** :

**ss-panel mod魔改版一键脚本**

```
yum install screen wget -y &&screen -S ss 
wget -N --no-check-certificate https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/ss-panel-v3-mod.sh && chmod +x ss-panel-v3-mod.sh && bash ss-panel-v3-mod.sh
```

**ss-panel v3一键脚本**

```
yum install screen wget -y &&screen -S ss
wget -N --no-check-certificate https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/ss-panel_node.sh && chmod +x ss-panel_node.sh && bash ss-panel_node.sh
```

选项都差不多,直接输入`1`安装即可

装完之后可以直接访问ip

默认账号：`91vps`

默认密码：`91vps`

phymyadmin 访问 `ip:888`

安装时间可能稍长，耐心等候。。。

下面是其他的开源多用户管理平台

***[https://github.com/Ehco1996/django-sspanel](https://github.com/Ehco1996/django-sspanel)***

***[搭建-sspanel-v3-魔改版记录](https://github.com/iMeiji/shadowsocks_install/wiki/%E6%90%AD%E5%BB%BA-sspanel-v3-%E9%AD%94%E6%94%B9%E7%89%88%E8%AE%B0%E5%BD%95)***

***[https://91vps.win/](https://91vps.win/)***

# Shadowsocks Optimize

## Google BBR
***[一键安装最新内核并开启 BBR 脚本](https://teddysun.com/489.html)***

### 更换Linode内核

谷歌开发的TCP加速“外挂”，目前已集成到最新的Linux内核。
博主用的**[Linode](https://www.linode.com/)**不能直接命令更换内核，需要到管理后台设置：
![](https://cdn.yangbingdong.com/img/docker-shadowsocks/change-kernel.png)

### 安装

```
wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && \
chmod +x bbr.sh && \
./bbr.sh

```

安装完后，会提示要重启 VPS，选择 **`Y`** 回车重启即可。

重启后输入

```
lsmod | grep bbr
```

出现 `tcp_bbr` 即说明 BBR 已经启动。

## 开启TCP Fast Open

这个需要服务器和客户端都是Linux 3.7+的内核，一般Linux的服务器发行版只有debian jessie有3.7+的，客户端用Linux更是珍稀动物，所以这个不多说，如果你的服务器端和客户端都是Linux 3.7+的内核，那就在服务端和客户端的`vi /etc/sysctl.conf`文件中再加上一行。

```
# turn on TCP Fast Open on both client and server side
net.ipv4.tcp_fastopen = 3
```

然后把`vi /etc/shadowsocks.json`配置文件中`"fast_open": false`改为`"fast_open": true`。这样速度也将会有非常显著的提升。

## TCP优化

1.修改文件句柄数限制
如果是ubuntu/centos均可修改`/etc/sysctl.conf`
找到`fs.file-max`这一行，修改其值为`1024000`，并保存退出。然后执行`sysctl -p`使其生效
修改`vi /etc/security/limits.conf`文件，加入

```
*               soft    nofile           512000
*               hard    nofile          1024000
```

针对centos,还需要修改`vi /etc/pam.d/common-session`文件，加入
`session required pam_limits.so`

2.修改`vi /etc/profile`文件，加入
`ulimit -SHn 1024000`
然后重启服务器执行`ulimit -n`，查询返回1024000即可。

```
sysctl.conf报错解决方法
修复modprobe的：
rm -f /sbin/modprobe 
ln -s /bin/true /sbin/modprobe
修复sysctl的：
rm -f /sbin/sysctl 
ln -s /bin/true /sbin/sysctl
```

## Kcptun

***[Kcptun 服务端一键安装脚本](https://blog.kuoruan.com/110.html)***

# VPS Security

> 公司刚买了一个Linode VPS 2TB流量的，不到几天就被DDOS攻击，直到余额被扣完停机。。。
>
> 吓得我马上谷歌了一些防御措施

## 修改SSH登录端口

### Ubuntu

1、用下面命令进入配置文件`vi /etc/ssh/sshd_config`
2、找到`#port 22`，将前面的`#`去掉，然后修改端口 `port 12345`（自己设定）。
3、然后重启ssh服务

```
#Debian/ubuntu  /etc/init.d/ssh restart   or    service ssh restart
#CentOS         service sshd restart
```

### CentOS

1、临时关闭SELinux：

```
setenforce 0
```

2、修改SSH端口

```
vi /etc/ssh/sshd_config

#在Port 22下面加一行，以端口2333为例，Port 2333

#重启ssh服务：
systemctl restart sshd.service
```

3、防火墙中放行新加入端口

```
firewall-cmd --permanent --add-port=2333/tcp
```

4、用该命令查询

```
firewall-cmd --permanent --query-port=2333/tcp
```

如果是`yes`就是添加成功，如果是no就是没成功

5、成功后重载防火墙

```
firewall-cmd --reload
```

6、关闭SELinux

查看SELinux状态`SELINUX`，如果是`enabled`就是开启状态

`vi /etc/selinux/config`

修改`SELINUX=disabled`

最后重启vps试试用新的`2333`端口登录，如果登录成功再`vi /etc/ssh/sshd_config`把`Port 22`端口删除，再重启ssh服务就好了。

## 使用密钥登录SSH

1、服务端生成密钥

```
#生成SSH密钥对
ssh-keygen -t rsa

Generating public/private rsa key pair.
#建议直接回车使用默认路径
Enter file in which to save the key (/root/.ssh/id_rsa): 
#输入密码短语（留空则直接回车）
Enter passphrase (empty for no passphrase): 
#重复密码短语
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
aa:8b:61:13:38:ad:b5:49:ca:51:45:b9:77:e1:97:e1 root@localhost.localdomain
The key's randomart image is:
+--[ RSA 2048]----+
|    .o.          |
|    ..   . .     |
|   .  . . o o    |
| o.  . . o E     |
|o.=   . S .      |
|.*.+   .         |
|o.*   .          |
| . + .           |
|  . o.           |
+-----------------+
```

2、复制密钥对

> 也可以手动在客户端建立目录和authorized_keys，注意修改权限

```
#复制公钥到无密码登录的服务器上,22端口改变可以使用下面的命令
#ssh-copy-id -i ~/.ssh/id_rsa.pub "-p 10022 user@server"
ssh-copy-id -i ~/.ssh/id_rsa.pub root@192.168.15.241
```

3、关闭密码登陆(编辑`/etc/ssh/sshd_config`)

```
#禁用密码验证
PasswordAuthentication no

#启用密钥验证
RSAAuthentication yes
PubkeyAuthentication yes

#指定公钥数据库文件
AuthorizedKeysFile .ssh/authorized_keys

#root 用户能否通过 SSH 登录
PermitRootLogin yes
```

4、重启SSH

```
#RHEL/CentOS系统
service sshd restart
#ubuntu系统
service ssh restart
#debian系统
/etc/init.d/ssh restart
```

## 防火墙

### Ubuntu防火墙UFW

```
ufw enable
ufw allow ssh
ufw allow [shadowsocks_port]
ufw allow from [remote_ip]
```

### CentOS

```
# 显示状态
firewall-cmd --state

# 启用
systemctl start firewalld.service

# Postgresql端口设置。允许192.168.142.166访问5432端口
firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.142.166" port protocol="tcp" port="5432" accept"

# redis端口设置。允许192.168.142.166访问6379端口
firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.142.166" port protocol="tcp" port="6379" accept"

# 查看配置结果，验证配置
firewall-cmd --list-all

# 删除规则
firewall-cmd --permanent --remove-rich-rule="rule family="ipv4" source address="192.168.142.166" port protocol="tcp" port="11300" accept"

# 更新防火墙规则
firewall-cmd --reload

# 重启防火墙
systemctl restart firewalld.service
```

## DDOS deflate

`DDOS deflate`是一款免费的用来防御和减轻DDOS攻击的脚本。它通过netstat监测跟踪创建大量网络连接的IP地址，在检测到某个结点超过预设的限制时，该程序会通过APF或IPTABLES禁止或阻挡这些IP。

**安装**：

```
wget http://www.moerats.com/usr/down/DDOS/deflate.sh && \
chmod +x deflate.sh && \
./deflate.sh
```

配置文件`/usr/local/ddos/ddos.conf`

```
##### Paths of the script and other files
PROGDIR="/usr/local/ddos"
PROG="/usr/local/ddos/ddos.sh"
IGNORE_IP_LIST="/usr/local/ddos/ignore.ip.list"
# 白名单.如有反向代理,注意添加本机地址和本机外网IP地址,防止提供反向代理的主机被判定为攻击.
CRON="/etc/cron.d/ddos.cron"
APF="/etc/apf/apf"
IPT="/sbin/iptables"##### frequency in minutes for running the script

##### Caution: Every time this setting is changed, run the script with cron
##### option so that the new frequency takes effect
FREQ=1

##### How many connections define a bad IP? Indicate that below. 
# 单IP发起连接数阀值,不建议设置太低.
NO_OF_CONNECTIONS=150

##### APF_BAN=1 (Make sure your APF version is atleast 0.96)
##### APF_BAN=0 (Uses iptables for banning ips instead of APF) 
#一般情况下你是使用iptables来做防火墙,所以这里你需要将 APF_BAN的值改为0.
APF_BAN=1

##### KILL=0 (Bad IPs are’nt banned, good for interactive execution of script)
##### KILL=1 (Recommended setting)
KILL=1 
#是否屏蔽IP，默认即可

##### An email is sent to the following address when an IP is banned. 
# 当单IP发起的连接数超过阀值后,将发邮件给指定的收件人.
##### Blank would suppress sending of mails
EMAIL_TO="root" 
# 这里是邮箱，可以把root替换成你的邮箱

##### Number of seconds the banned ip should remain in blacklist. 
# 设置被挡IP多少秒后移出黑名单.
BAN_PERIOD=600
```

将上述配置文件修改完成后，使用命令启动即可

```
ddos -d
```

Ubuntu中可能会报错：

```shell
root@localhost:~# ddos -d
/usr/local/sbin/ddos: 13: [: /usr/local/ddos/ddos.conf: unexpected operator
DDoS-Deflate version 0.6
Copyright (C) 2005, Zaf <zaf@vsnl.com>
```

因为启动大多数为 bash 脚本，而 Ubuntu 的默认环境为 dash，所以需要使用 dpkg-reconfigure dash，选择 NO，切换为 bash 运行脚本：

```
dpkg-reconfigure dash
```

## Denyhosts防暴力攻击

这个方法比较省时省力。denyhosts 是 Python 语言写的一个程序，它会分析 sshd 的日志文件，当发现重复的失败登录时就会记录 IP 到 /etc/hosts.deny 文件，从而达到自动屏 IP 的功能：
```shell
# Debian/Ubuntu：
sudo apt install denyhosts
 
# RedHat/CentOS
yum install denyhosts
```

默认配置就能很好的工作，如要个性化设置可以修改 `/etc/denyhosts.conf`

```
SECURE_LOG = /var/log/auth.log #ssh 日志文件，它是根据这个文件来判断的。
HOSTS_DENY = /etc/hosts.deny #控制用户登陆的文件
PURGE_DENY = #过多久后清除已经禁止的，空表示永远不解禁
BLOCK_SERVICE = sshd #禁止的服务名，如还要添加其他服务，只需添加逗号跟上相应的服务即可
DENY_THRESHOLD_INVALID = 5 #允许无效用户失败的次数
DENY_THRESHOLD_VALID = 10 #允许普通用户登陆失败的次数
DENY_THRESHOLD_ROOT = 1 #允许root登陆失败的次数
DENY_THRESHOLD_RESTRICTED = 1
WORK_DIR = /var/lib/denyhosts #运行目录
SUSPICIOUS_LOGIN_REPORT_ALLOWED_HOSTS=YES
HOSTNAME_LOOKUP=YES #是否进行域名反解析
LOCK_FILE = /var/run/denyhosts.pid #程序的进程ID
ADMIN_EMAIL = root@localhost #管理员邮件地址,它会给管理员发邮件
SMTP_HOST = localhost
SMTP_PORT = 25
SMTP_FROM = DenyHosts <nobody@localhost>
SMTP_SUBJECT = DenyHosts Report
AGE_RESET_VALID=5d #用户的登录失败计数会在多久以后重置为0，(h表示小时，d表示天，m表示月，w表示周，y表示年)
AGE_RESET_ROOT=25d
AGE_RESET_RESTRICTED=25d
AGE_RESET_INVALID=10d
RESET_ON_SUCCESS = yes #如果一个ip登陆成功后，失败的登陆计数是否重置为0
DAEMON_LOG = /var/log/denyhosts #自己的日志文件
DAEMON_SLEEP = 30s #当以后台方式运行时，每读一次日志文件的时间间隔。
DAEMON_PURGE = 1h #当以后台方式运行时，清除机制在 HOSTS_DENY 中终止旧条目的时间间隔,这个会影响PURGE_DENY的间隔。
```

查看已拦截的IP`cat /etc/hosts.deny`
查看拦截记录`cat /etc/hosts.deny | wc -l`
重启服务`service denyhosts restart`
写入自启`echo "service denyhosts restart" >> /etc/rc.local`

## vDDoS（只支持CentOS和CloudLinux）

Github: ***[https://github.com/duy13/vDDoS-Protection](https://github.com/duy13/vDDoS-Protection)***

# VPS Speed Test

## speedtest

下载：

```
wget https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py && \
chmod +x speedtest.py
```

运行：

```
./speedtest.py

#或者
python speedtest.py
```

结果：

```
[root@li1890-191 ~]# ./speedtest.py
Retrieving speedtest.net configuration...
Testing from Linode (123.456.789.123)...
Retrieving speedtest.net server list...
Selecting best server based on ping...
Hosted by IPA CyberLab (Bunkyo) [5.97 km]: 2.998 ms
Testing download speed................................................................................
Download: 2036.69 Mbit/s
Testing upload speed................................................................................................
Upload: 208.17 Mbit/s

```

## speedtest-cli

> 地址：***[https://github.com/sivel/speedtest-cli](https://github.com/sivel/speedtest-cli)***

pip方式安装

```
pip install speedtest-cli
```

或github安装

```
git clone https://github.com/sivel/speedtest-cli.git
python speedtest-cli/setup.py install
```
用法：

1、list

根据距离显示所有的节点服务器列表。

2、列出所有北京节点服务器

```
[root@li1890-191 ~]# speedtest-cli --list | grep Beijing
 4713) China Mobile Group Beijing Co.Ltd (Beijing, China) [2093.67 km]
 5505) Beijing Broadband Network (Beijing, China) [2093.67 km]
 5145) Beijing Unicom (Beijing, China) [2093.67 km]
18462) Beijing Broadband Network (Beijing, China) [2093.67 km]
```

3、选择节点测试下载速度

```
speedtest-cli --server=6611
```

# Finally

低调使用。。。


[^1]: 防火长城（英语：Great Firewall( of China)，常用简称：GFW，中文也称中国国家防火墙，中国大陆民众俗称防火墙等），是对中华人民共和国政府在其互联网边界审查系统（包括相关行政审查系统）的统称。此系统起步于1998年，其英文名称得自于2002年5月17日Charles R. Smith所写的一篇关于中国网络审查的文章《The Great Firewall of China》，取與Great Wall（长城）相谐的效果，简写为Great Firewall，缩写GFW。隨着使用的拓广，中文「墙」和英文「GFW」有时也被用作动词，网友所說的「被墙」即指被防火长城所屏蔽，「翻墙」也被引申为浏览国外网站、香港等特区网站的行为。


