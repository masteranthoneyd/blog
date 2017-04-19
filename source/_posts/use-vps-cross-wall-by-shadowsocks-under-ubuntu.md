---
title: use-vps-cross-wall-by-shadowsocks-under-ubuntu
date: 2017-04-19 18:15:57
categories: [VPS]
tags: [VPS,Shadowsocks]
---
# 前言
> 最近在玩***[VPS](http://baike.baidu.com/link?url=ehKAXxj45AdvSmxPRwiao9anB3Tej-jwgKXWMkTuA43M2479GPT-FkH6zMhI59Eip_iY5abNL2jODlGC4WiLW_)***，作为没有Google就活不下去的开发人员，穿墙已是日常= =...使用别人的VPN或者Sock代理显然是不安全的，个人信息随时被截获，那么拥有一台自己VPS也是必需的，价格也可以很便宜（绝对不是在打广告）

<!--more-->
# VPS选择

# Shadowsocks服务端
> 这里博主选择的vps的操作系统是Ubuntu14.04,因为16.04不明原因安装失败。
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



只需要把 `my_server_ip`换成你VPS的IP，并且把 `mypassword` 换成你自己的密码，注意：这个密码不是你登录VPS的密码，是你一会从Shadowsocks客户端登录的时候用的密码.
`server_port`默认8388也行，你修改也行，这个端口是Shadowsocks客户端登录时用的端口号，如果你修改了，最好改成1024至65536之间的一个数字，并且自己一定要记住。其它的都默认就好。

## 启动服务
下面就可以开始启动Shadowsocks服务端了。Shadowsocks服务端自身就已经支持后台运行了，所以，通过下面的命令启动之后，只要你的VPS不关机不重启，Shadowsocks服务端就会一直在后台运行。
```shell
ssserver -c /etc/shadowsocks.json -d start
```
![](http://ojoba1c98.bkt.clouddn.com/img/vps/shadowsocks-startup.png)
看到`started`没有，这就表示你的Shadowsocks服务端就已经启动了。此时就可以关掉你的putty，然后打开你的Shadowsocks客户端进行连接了。

最后一步，将shadowsocks加入开机启动。很简单，只需在/etc/rc.local加一句话就成。通过如下命令打开rc.local文件
```shell
vi /etc/rc.local
```
在`exit 0`的上一行添加以下内容：
```shell
/usr/bin/python /usr/local/bin/ssserver -c /etc/shadowsocks.json -d start
```
粘贴完成后，和上面编辑配置文件一样，选按键盘左上角的“ESC”键，然后输入”:wq”，保存退出。这样，开机就会自动启动shadowsocks了。不信，你可以试一下。




# Shadowsocks客户端
## 安装与启动
Ubuntu使用Shadowsocks客户端有两种方式：
1、安装shadowsocks命令行程序，配置命令。
2、安装shadowsocks GUI图形界面程序，配置。

> 博主推荐第一种，配置好后基本不用管。但使用的前提是你的服务端已经搭建好或者你有别人提供的SS 服务，下面我们来看怎么在Ubuntu上使用shadowsocks

### 方法一
#### 安装
用PIP安装很简单：
```shell
sudo apt-get update
sudo apt-get install python-pip
sudo apt-get install python-setuptools m2crypto
```
接着安装Shadowsocks：
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
安装GUI 图形界面程序，然后按照提示配置相对应的参数。安装教程地址：***[shadowsocks-qt5 安装指南](https://github.com/shadowsocks/shadowsocks-qt5/wiki/%E5%AE%89%E8%A3%85%E6%8C%87%E5%8D%97)***

在ubuntu上可以这样，通过PPA源安装，**仅支持Ubuntu 14.04或更高版本**。
```shell
sudo add-apt-repository ppa:hzwhuang/ss-qt5
sudo apt-get update
sudo apt-get install shadowsocks-qt5
```
由于是图形界面，配置和windows基本没啥差别就不赘述了。经过上面的配置，你只是启动了sslocal 但是要上网你还需要配置下浏览器到指定到代理端口比如1080才可以正式上网。

# 配置浏览器代理
假如你上面任选一种方式已经开始运行`sslocal`了，火狐那个代理插件老是订阅不了gfwlist所以配置自动模式的话不好使。这里用的是chrome，你可以在Ubuntu软件中心下载得到。

## 安装插件
我们需要给chrome安装SwitchyOmega插件，但是没有代理之前是不能从谷歌商店安装这个插件的，但是我们可以从Github上直接下载最新版 ***[https://github.com/FelisCatus/SwitchyOmega/releases/](https://github.com/FelisCatus/SwitchyOmega/releases/) （这个是chrome的）然后浏览器地址打开chrome://extensions/，将下载的插件托进去安装。

## 设置代理地址
安装好插件会自动跳到设置选项，有提示你可以跳过。左边新建情景模式-选择代理服务器-比如命名为shadowProxy（叫什么无所谓）其他默认之后创建，之后在代理协议选择SOCKS5，地址为`127.0.0.1`,端口默认`1080` 。然后保存即应用选项。
![](http://ojoba1c98.bkt.clouddn.com/img/vps/proxy.png)
![](http://ojoba1c98.bkt.clouddn.com/img/vps/proxy01.png)

## 设置自动切换
接着点击自动切换 ( Auto switch）上面的不用管，在按照规则列表匹配请求后面选择刚才新建的SS，默认情景模式选择直接连接。点击应用选项保存。再往下规则列表设置选择AutoProxy 然后将***[这个地址](https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt)**填进去，点击下面的立即更新情景模式，会有提示更新成功！
![](http://ojoba1c98.bkt.clouddn.com/img/vps/proxy03.png)

点击浏览器右上角的SwitchyOmega图标，下面选择自动切换，然后打开google.com试试，其他的就不在这贴图了。
![](http://ojoba1c98.bkt.clouddn.com/img/vps/proxy04.png)

# GenPAC全局代理
如果不想每个浏览器都要设置代理，可以通过GenPAC实现全局代理。
## 安装
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

## 设置全局代理
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


# 开机后台自动运行ss
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






