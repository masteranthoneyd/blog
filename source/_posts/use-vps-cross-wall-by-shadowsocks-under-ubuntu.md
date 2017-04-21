---
title: 使用VPS搭建ShadowSocks实现Access Blocked Sites(俗称翻墙)并使用黑科技加速
date: 2017-04-19 18:15:57
categories: [VPS]
tags: [VPS,ShadowSocks]
---
![](http://ojoba1c98.bkt.clouddn.com/img/vps/whats-shadowsocks-04.png)
# 前言
> 最近在玩***[VPS](http://baike.baidu.com/link?url=ehKAXxj45AdvSmxPRwiao9anB3Tej-jwgKXWMkTuA43M2479GPT-FkH6zMhI59Eip_iY5abNL2jODlGC4WiLW_)***，作为没有Google就活不下去的开发人员，穿墙已是日常= =...使用别人的VPN或者Sock5代理显然是不安全的，个人信息随时被截获，那么拥有一台自己VPS也是必需的，价格也可以很便宜（绝对不是在打广告）

<!--more-->
# ShadowSocks介绍
## 什么是ShadowSocks(影梭)
ShadowSocks 是由***[clowwindy](https://github.com/shadowsocks/shadowsocks)***所开发的一个开源 Socks5 代理。如其***[官网](http://shadowsocks.org/en/index.html)***所言 ，它是 “`A secure socks5 proxy, designed to protect your Internet traffic`” （一个安全的 `Socks5` 代理）。其作用，亦如该项目主页的 ***[wiki](https://github.com/shadowsocks/shadowsocks/wiki)***（***[中文版](https://github.com/shadowsocks/shadowsocks/wiki/Shadowsocks-%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E)***） 中所说，“`A fast tunnel proxy that helps you bypass firewalls`” （一个**可穿透防火墙**的快速代理）。
不过，在中国，由于***[GFW](https://zh.wikipedia.org/wiki/%E9%98%B2%E7%81%AB%E9%95%BF%E5%9F%8E)***[^1]的存在，更多的网友用它来进行**科学上网**。

## This is a story...
### long long ago…
我们的互联网通讯是这样的：
![](http://ojoba1c98.bkt.clouddn.com/img/vps/whats-shadowsocks-01.png)
### when evil comes
然后有一天，GFW[^1] 就出现了，他像一个收过路费的强盗一样夹在了在用户和服务之间，每当用户需要获取信息，都经过了 GFW，GFW将它不喜欢的内容统统过**滤掉**，于是客户当触发 GFW 的**过滤规则**的时候，就会收到 `Connection Reset` 这样的响应内容，而无法接收到正常的内容：
![](http://ojoba1c98.bkt.clouddn.com/img/vps/whats-shadowsocks-02.png)
### ssh tunnel
聪明的人们想到了**利用境外服务器代理**的方法来绕过 GFW 的过滤，其中包含了各种HTTP代理服务、Socks服务、VPN服务… 其中以 `ssh tunnel` 的方法比较有代表性：
1) 首先用户和境外服务器基于 ssh 建立起一条加密的通道
2-3) 用户通过建立起的隧道进行代理，通过 ssh server 向真实的服务发起请求
4-5) 服务通过 ssh server，再通过创建好的隧道返回给用户
![](http://ojoba1c98.bkt.clouddn.com/img/vps/whats-shadowsocks-03.png)
由于 ssh 本身就是基于 `RSA` 加密技术，所以 GFW 无法从数据传输的过程中的加密数据内容进行关键词分析，**避免了被重置链接的问题**，但由于创建隧道和数据传输的过程中，**ssh 本身的特征是明显的**，所以 GFW 一度通过分析连接的特征进行**干扰**，导致 ssh**存在被定向进行干扰的问题**。
### shadowsocks
于是 clowwindy 同学**分享并开源**了他的解决方案。
简单理解的话，shadowsocks 是将原来 ssh 创建的 Socks5 协议**拆开**成 server 端和 client 端，所以下面这个原理图基本上和利用 ssh tunnel 大致类似。
1、6) 客户端发出的请求基于 Socks5 协议跟 ss-local 端进行通讯，由于这个 ss-local 一般是本机或路由器或局域网的其他机器，不经过 GFW，所以解决了上面被 GFW 通过特征分析进行干扰的问题
2、5) ss-local 和 ss-server 两端通过多种可选的加密方法进行通讯，经过 GFW 的时候是常规的TCP包，没有明显的特征码而且 GFW 也无法对通讯数据进行解密
3、4) ss-server 将收到的加密数据进行解密，还原原来的请求，再发送到用户需要访问的服务，获取响应原路返回
![](http://ojoba1c98.bkt.clouddn.com/img/vps/whats-shadowsocks-04.png)

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



# ShadowSocks服务端
> 这里博主选择的VPS的操作系统是**Ubuntu14.04**,因为16.04不明原因安装失败。
> 另外，**搬瓦工**可以一键安装Shadowsocks和OpenVPN（只支持CentOS），但处于爱折腾，手动安装。

## 安装
```shell
apt-get update
apt-get install python-pip
pip install shadowsocks
```

## 修改配置文件
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

## 启动服务
下面就可以开始启动ShadowSocks服务端了。ShadowSocks服务端自身就已经支持后台运行了，所以，通过下面的命令启动之后，只要你的VPS不关机不重启，ShadowSocks服务端就会一直在后台运行。
```shell
ssserver -c /etc/shadowsocks.json -d start
```
![](http://ojoba1c98.bkt.clouddn.com/img/vps/shadowsocks-startup.png)
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




# ShadowSocks客户端
## 安装与启动
Ubuntu使用ShadowSocks客户端有两种方式：
1、安装ShadowSocks命令行程序，配置命令。
2、安装ShadowSocks GUI图形界面程序，配置。

> 博主推荐第一种，配置好后基本不用管。但使用的前提是你的服务端已经搭建好或者你有别人提供的SS 服务，下面我们来看怎么在Ubuntu上使用ShadowSocks

### 方法一
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
![](http://ojoba1c98.bkt.clouddn.com/img/vps/sslocal-help.png)
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
![](http://ojoba1c98.bkt.clouddn.com/img/vps/launch-sslocal.png)

如果你选择这一种请跳过第二种。你可以去系统的代理设置按照说明设置代理，但一般是全局的，然而我们访问baidu,taobao等着些网站如果用代理就有点绕了，而且还会浪费服务器流量。我们最好配置我们的浏览器让它可以自动切换，该用代理用代理该直接连接自动直接连接。所以请看配置浏览器。

### 方法二
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

## 番外篇一：搬瓦工一键安装
搬瓦工早就知道广大使用者的~~阴谋~~意图，所以特意提供了**一键无脑安装Shadowsocks**。
注意：**目前只支持CentOS**。
进入KiwiVM后，在左边的选项栏的最下面：
![](http://ojoba1c98.bkt.clouddn.com/img/vps/one-key-install-shadowsocks.png)
点击Install之后会出现如下界面代表安装成功：
![](http://ojoba1c98.bkt.clouddn.com/img/vps/one-key-install-shadowsocks01.png)
点GO Back可看到相关信息了

## 番外篇二：一键安装脚本
这个就不多说了，直接贴上网址：***[Shadowsocks 一键安装脚本（四合一）](https://shadowsocks.be/11.html)***


# 使用ShadowSocks代理实现穿墙
## 方式一：配置浏览器代理
假如你上面任选一种方式已经开始运行`sslocal`了，火狐那个代理插件老是订阅不了gfwlist所以配置自动模式的话不好使。这里用的是chrome，你可以在Ubuntu软件中心下载得到。

### 安装插件
我们需要给chrome安装SwitchyOmega插件，但是没有代理之前是不能从谷歌商店安装这个插件的，但是我们可以从Github上直接下载最新版 ***[https://github.com/FelisCatus/SwitchyOmega/releases/](https://github.com/FelisCatus/SwitchyOmega/releases/) （这个是chrome的）然后浏览器地址打开chrome://extensions/，将下载的插件托进去安装。

### 设置代理地址
安装好插件会自动跳到设置选项，有提示你可以跳过。左边新建情景模式-选择代理服务器-比如命名为shadowProxy（叫什么无所谓）其他默认之后创建，之后在代理协议选择SOCKS5，地址为`127.0.0.1`,端口默认`1080` 。然后保存即应用选项。
![](http://ojoba1c98.bkt.clouddn.com/img/vps/proxy.png)
![](http://ojoba1c98.bkt.clouddn.com/img/vps/proxy01.png)

### 设置自动切换
接着点击自动切换 ( Auto switch）上面的不用管，在按照规则列表匹配请求后面选择刚才新建的SS，默认情景模式选择直接连接。点击应用选项保存。再往下规则列表设置选择AutoProxy 然后将***[这个地址](https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt)**填进去，点击下面的立即更新情景模式，会有提示更新成功！
![](http://ojoba1c98.bkt.clouddn.com/img/vps/proxy03.png)

点击浏览器右上角的SwitchyOmega图标，下面选择自动切换，然后打开google.com试试，其他的就不在这贴图了。
![](http://ojoba1c98.bkt.clouddn.com/img/vps/proxy04.png)

## 方式二：GenPAC全局代理
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
3、全局代理
系统设置 –> 网络 –> 网络代理
“方法”选择“自动”
“配置URL”填写：
`file:///home/ybd/Data/application/shadowsocks/autoproxy.pac`
点击“应用到整个系统”，接下来可以愉悦的跨过墙了～

## 方式三：通过proxychains
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
使用`shadowsocks`+`proxychains`代理打开新的firefox实现浏览器翻墙。 
也可以通过输入`proxychains bash`建立一个新的`shell`，基于这个shell运行的所有命令都将使用代理。

# 黑科技系列
## FinalSpeed
***[91yun发布的finalspeed一键安装包](https://www.91yun.org/archives/2775)***
***[锐速替代品双边加速FinalSpeed客户端下载及教程 ，Openvz福音](https://www.91yun.org/archives/615)***
## 锐速
***(锐速破解版linux一键自动安装包)[https://www.91yun.org/archives/683]***

## Google BBR
***(Centos/Ubuntu/Debian BBR加速一键安装包)[https://www.91yun.org/archives/5174]***

## Kcptun
***(Kcptun 服务端一键安装脚本)[https://blog.kuoruan.com/110.html]***

[^1]: 防火长城（英语：Great Firewall( of China)，常用简称：GFW，中文也称中国国家防火墙，中国大陆民众俗称防火墙等），是对中华人民共和国政府在其互联网边界审查系统（包括相关行政审查系统）的统称。此系统起步于1998年，其英文名称得自于2002年5月17日Charles R. Smith所写的一篇关于中国网络审查的文章《The Great Firewall of China》，取與Great Wall（长城）相谐的效果，简写为Great Firewall，缩写GFW。隨着使用的拓广，中文「墙」和英文「GFW」有时也被用作动词，网友所說的「被墙」即指被防火长城所屏蔽，「翻墙」也被引申为浏览国外网站、香港等特区网站的行为。






