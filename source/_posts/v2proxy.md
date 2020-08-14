---
title: V2Proxy 正确的代理模式
date: 2017-04-19 18:15:57
categories: [VPS]
tags: [VPS, ShadowSocks, V2Ray, Trojan]
password: admin123
---
![](https://cdn.yangbingdong.com/img/vps/whats-shadowsocks-04.png)
# Preface
> 作为一名开发人员, 日常离不开 Google, 那么在这之前, 必须要先学会如何代理.
>
> 本人 ***[Linode](https://www.linode.com/)*** 邀请码: `79e24952d46644605b071a55c4fda3b23e1d1a5a` 

<!--more-->

# 代理方式介绍

> 核心原理都一样, 如上方图所示. 推荐使用 ***[Trojan](https://github.com/trojan-gfw/trojan)***.

* ***[Shadowsocks](https://shadowsocks.org/)***: 过去比较常用, 据说如今 GFW 已经能够识别出, 所以经常掉链子.
* ***[V2ray](https://www.v2ray.com/)***: Go 语言开发的高性能网络工具集, 服务端客户端于一体, 功能比较多, 支持 Shadowsocks 协议, 属于目前比较流行的科学上网软件.
* ***[Trojan](https://github.com/trojan-gfw/trojan)***: 专门为绕过 GFW 而生的新一代科学上网软件, 由 C++ 编写, 需要域名以及证书伪装成 HTTPS.

难度 | 稳定: `Shadowsocks` < `V2ray` < `Trojan`

# VPS选择

> VPS 厂商众多, 其他的我不多说.

* ***[Linode](https://www.linode.com)*** VPS 大厂了, 价格不算便宜, 我用的5$每月, 稳定网速快, 推荐. 邀请码: `79e24952d46644605b071a55c4fda3b23e1d1a5a`
* ***[BandwagonHOST](https://bandwagonhost.com/)*** 搬瓦工(已被墙), 便宜, 性价比高
* 阿里云香港ECS, 优点不说了, 缺点就是太贵, 如果只是查查资料或者玩游戏的, 可以买按流量计费的

# 准备工作

## 准备一台VPS

博主选择***[Linode](https://www.linode.com)***

博主的邀请码: `79e24952d46644605b071a55c4fda3b23e1d1a5a`

## SSH无密码登录VPS (可选)

参考 ***[免密码登录远程服务器](/2017/note-of-linux-command/#免密码登录远程服务器)***

# 各大代理安装与使用

安装方式各种各样. . .同意 推荐使用 Docker 镜像安装.

## Shadowsocks

### 服务端

拉取镜像:

`Showdowsocks`镜像: ***[https://hub.docker.com/r/mritd/shadowsocks/](https://hub.docker.com/r/mritd/shadowsocks/)***

```
docker pull mritd/shadowsocks:latest
```

运行: 

```
docker run -dt --name ssserver --restart=always -p 6443:6443 mritd/shadowsocks:latest -m "ss-server" -s "-s 0.0.0.0 -p 6443 -m aes-256-cfb -k 123456 --fast-open"
```

ss命令说明: 

- `-s` : 监听服务ip, 为服务器本地
- `-p` : 端口
- `-m` : 加密算法
- `-k` : 密码
- `--fast-open` : 开启TCP `fast-open`

### 脚本一键安装

> 更多精彩被容请移步到 ***[https://teddysun.com/](https://teddysun.com/)***

root用户执行: 

```
wget --no-check-certificate -O shadowsocks-all.sh https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-all.sh
chmod +x shadowsocks-all.sh
./shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log
```

安装完成后, 脚本提示如下:

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

卸载方法:

若已安装多个版本, 则卸载时也需多次运行（每次卸载一种）

使用root用户登录, 运行以下命令: 

```
./shadowsocks-all.sh uninstall
```

启动脚本:

启动脚本后面的参数含义, 从左至右依次为: 启动, 停止, 重启, 查看状态. 

**Shadowsocks-Python** 版: 
`/etc/init.d/shadowsocks-python start | stop | restart | status`

**ShadowsocksR** 版: 
`/etc/init.d/shadowsocks-r start | stop | restart | status`

**Shadowsocks-Go** 版: 
`/etc/init.d/shadowsocks-go start | stop | restart | status`

**Shadowsocks-libev** 版: 
`/etc/init.d/shadowsocks-libev start | stop | restart | status`

各版本默认配置文件:

**Shadowsocks-Python** 版: 
`/etc/shadowsocks-python/config.json`

**ShadowsocksR** 版: 
`/etc/shadowsocks-r/config.json`

**Shadowsocks-Go** 版: 
`/etc/shadowsocks-go/config.json`

**Shadowsocks-libev** 版: 
`/etc/shadowsocks-libev/config.json`

### 客户端

官网各大客户端: ***[https://shadowsocks.org/en/download/clients.html](https://shadowsocks.org/en/download/clients.html)***

Docker 客户端:

```
docker run -dt --name ssclient --restart=always -p 1080:1080 mritd/shadowsocks:latest -m "ss-local" -s "-s server-ip -p 6443 -b 0.0.0.0 -l 1080 -m aes-256-cfb -k 123456 --fast-open"
```

### 多用户管理

***[https://github.com/mmmwhy/ss-panel-and-ss-py-mu](https://github.com/mmmwhy/ss-panel-and-ss-py-mu)*** :

***[https://github.com/Ehco1996/django-sspanel](https://github.com/Ehco1996/django-sspanel)***

***[搭建-sspanel-v3-魔改版记录](https://github.com/iMeiji/shadowsocks_install/wiki/%E6%90%AD%E5%BB%BA-sspanel-v3-%E9%AD%94%E6%94%B9%E7%89%88%E8%AE%B0%E5%BD%95)***

***[https://91vps.win/](https://91vps.win/)***

## V2Ray

> 项目地址: ***[https://github.com/v2ray/v2ray-core](https://github.com/v2ray/v2ray-core)***
>
> 参考文档: ***[https://toutyrater.github.io/](https://toutyrater.github.io/)*** (已被墙)
>
> 一键安装:
> ***[https://github.com/Jrohy/multi-v2ray](https://github.com/Jrohy/multi-v2ray)***
> ***[https://github.com/233boy/v2ray](https://github.com/233boy/v2ray)***

### 服务端

`docker-compose.yml`:

```yaml
version: '3.7'
services:
  v2ray:
    image: v2ray/official
    container_name: v2ray
    restart: always
    ports:
      - "443:443"

    volumes:
      - ./config.json:/etc/v2ray/config.json
    command: v2ray -config=/etc/v2ray/config.json
```

`config.json`:

```json
{
    "inbounds":[
        {
            "port":443,
            "protocol":"vmess",
            "settings":{
                "clients":[
                    {
                        "id":"b371a709-f63c-42d7-88bf-2a67cff72267",
                        "alterId":64
                    }
                ]
            }
        }
    ],
    "outbounds":[
        {
            "protocol":"freedom",
            "settings":{
            }
        }
    ]
}
```

### 客户端

`docker-compose.yml`:

```yaml
version: '3.7'
services:
  v2ray:
    image: v2ray/official
    container_name: v2ray
    restart: always
    ports:
      - "1080:1080"
      - "1080:1080/udp"
    volumes:
      - ./client-config.json:/etc/v2ray/config.json
    command: ["v2ray", "-config=/etc/v2ray/config.json"]
```

`client-config.json`:

```json
{
    "inbounds":[
        {
            "port":1080,
            "protocol":"socks",
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ]
            },
            "settings":{
                "auth":"noauth"
            }
        }
    ],
    "outbounds":[
        {
            "protocol":"vmess",
            "settings":{
                "vnext":[
                    {
                        "address":"123.456.678.0",
                        "port":443,
                        "users":[
                            {
                                "id":"b371a709-f63c-42d7-88bf-2a67cff72267",
                                "alterId":64
                            }
                        ]
                    }
                ],
                "mux":{
                    "enabled":true
                }
            }
        }
    ]
}
```

其他客户端:

* 跨平台 UI 客户端: ***[Qv2ray](https://github.com/Qv2ray/Qv2ray)***
* MAC 客户端: ***[V2rayU](https://github.com/yanue/V2rayU/tree/master)***

### 多用户管理UI

***[https://blog.sprov.xyz/2019/08/03/v2-ui/](https://blog.sprov.xyz/2019/08/03/v2-ui/)***

## Trajon

### 服务端

***[https://www.atrandys.com/category/kxsw/trojan](https://www.atrandys.com/category/kxsw/trojan)*** / ***[https://github.com/atrandys/trojan](https://github.com/atrandys/trojan)***

***[https://github.com/mark-logs-code-hub/trojan-wiz](https://github.com/mark-logs-code-hub/trojan-wiz)***

或者是一下我写的...:

```
wget -N --no-check-certificate 'https://raw.githubusercontent.com/masteranthoneyd/about-shell/master/trojan.sh' && chmod +x trojan.sh && ./trojan.sh $DOMAIN
```

将 `$DOMAIN` 换成自己的域名.

### 客户端

`docker-compose.yml`:

```yml
version: '3.7'
services:
  v2ray:
    image: trojangfw/trojan
    container_name: trojan
    restart: always
    ports:
      - "1081:1080"
    volumes:
      - ./config:/config
```

`config` 文件夹中应该包含Json配置文件以及证书.

`config.json`:

```json
{
    "run_type": "client",
    "local_addr": "0.0.0.0",
    "local_port": 1080,
    "remote_addr": "YOUR_DOMAIN",
    "remote_port": 443,
    "password": [
        "YOUR_PASSWORD"
    ],
    "log_level": 1,
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "fullchain.cer",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
"sni": "",
        "alpn": [
            "h2",
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "curves": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": true,
        "fast_open_qlen": 20
    }
}
```

## Just My Socks

搬瓦工官方机场: ***[https://justmysocks.net/](https://justmysocks.net/)***

使用: ***[https://blog.shuziyimin.org/840](https://blog.shuziyimin.org/840)***

# 将流量转发到代理

上面所介绍的代理软件基本上客户端都是**监听本地1080端口**, 并且是 **Sock5** 协议,  所以需要将 HTTP 流量**转发**到本地的1080端口. 好处是**解耦了代理的实现**, 可以**随时更换代理软件**, 比如将 V2ray 换成 Trojan, 只需要更换客户端.

## 浏览器转发

推荐使用 Chrome 或者使用 Chrome 内核的浏览器如360. 其他浏览器自行研究.

这种方式适合所有桌面版系统平台, 有些代理客户端可以设置全局流量转发比如 Windows 的 ***[shadowsocks-win](https://github.com/shadowsocks/shadowsocks-windows)***, 不建议将全局流量转发作为常用设置, 不好控制. 而使用浏览器插件可控度高, 有些网站没有被墙比如 Github, 但是加载速度比较慢, 可在浏览器中直接强制走代理.

### SwitchyOmega插件安装

***[SwitchyOmega](https://github.com/FelisCatus/SwitchyOmega)*** 可以将浏览器的流量转发到我们本地的 Socks5 端口.

安装方式:

* 从 ***[Chrome Web Store](https://chrome.google.com/webstore/detail/padekgcemlokbadohgkifijomclgjgif)*** 下载, 首先你得能访问 Google, 这是一个**悖论**
* 从 ***[Releases](https://github.com/FelisCatus/SwitchyOmega/releases/)*** 页面下载离线安装包, 浏览器地址打开`chrome://extensions/`,  启用**开发者模式**,将下载的安装包拖进去
* 无法安装的参考一下这里: ***[四种谷歌浏览器扩展插件安装方法，完美解决程序包无效问题！](https://zhuanlan.zhihu.com/p/78519194)***

### 设置代理地址
安装好插件会自动跳到设置选项, 有提示你可以跳过. 左边新建情景模式-选择代理服务器-比如命名为shadowProxy（叫什么无所谓）其他默认之后创建, 之后在代理协议选择 SOCKS5, 地址为`127.0.0.1`,端口默认`1080` . 然后保存即应用选项. 
![](https://cdn.yangbingdong.com/img/vps/proxy.png)
![](https://cdn.yangbingdong.com/img/vps/proxy01.png)

### 设置自动切换
接着点击自动切换 ( Auto switch）上面的不用管, 在按照规则列表匹配请求后面选择刚才新建的SS, 默认情景模式选择直接连接. 点击应用选项保存. 再往下规则列表设置选择`AutoProxy` 然后将 *https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt* 填进去, 点击下面的立即更新情景模式, 会有提示更新成功！
![](https://cdn.yangbingdong.com/img/vps/proxy03.png)

点击浏览器右上角的 SwitchyOmega 图标, 下面选择自动切换, 然后打开 ***[google.com](https://www.google.com/)*** 试试, 其他的就不在这贴图了. 
![](https://cdn.yangbingdong.com/img/vps/proxy04.png)

## GenPAC全局代理
如果不想每个浏览器都要设置代理, 可以通过GenPAC实现全局代理. 
### 安装
pip: 
```shell
sudo apt-get install python-pip python-dev build-essential 
sudo pip install --upgrade pip 
sudo pip install --upgrade virtualenv 
```
GenPAC: 
```shell
sudo pip install genpac
sudo pip install --upgrade genpac
```

### 设置全局代理
1、进入终端, Ctrl+Alt+T, cd到你希望生成文件存放的位置. 
例如: 
```shell
cd /home/ybd/Data/application/shadowsocks
```
2、执行下面的语句: 
```shell
sudo genpac --proxy="SOCKS5 127.0.0.1:1080" --gfwlist-proxy="SOCKS5 127.0.0.1:1080" -o autoproxy.pac --gfwlist-url="https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
```
**注意**: 
上面语句中`127.0.0.1:1080`应按照自己的情况填写. 
如果出现下面这种报错: 
```shell
fetch gfwlist fail. online: https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt local: None
```
那么换成执行下面的语句: 
```shell
sudo genpac --proxy="SOCKS5 127.0.0.1:1080" -o autoproxy.pac --gfwlist-url="https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
```

如果出现`base64 decoding fail .`, 安装其他版本: 
```
sudo pip install https://github.com/JinnLynn/genpac/archive/master.zip
sudo pip install --upgrade https://github.com/JinnLynn/genpac/archive/master.zip
sudo pip uninstall genpac
```

3、全局代理
系统设置 –> 网络 –> 网络代理
“方法”选择“自动”
“配置URL”填写: 
`file:///home/ybd/Data/application/shadowsocks/autoproxy.pac`
点击“应用到整个系统”, 接下来可以愉悦的跨过墙了～

## Proxychains 代理

> ***[https://github.com/rofl0r/proxychains-ng](https://github.com/rofl0r/proxychains-ng)***
>
> 这个是最新版的proxychains, 下面通过apt安装的是3.1版本的.

安装proxychains: 
```shell
sudo apt install proxychains

# 最新版为 sudo apt install proxychains4, 配置文件在/etc/proxychains4.conf, 命令为proxychains4
```
配置proxychains: 
编辑`/etc/proxychains.conf`, 最下面有一行`socks4 127.0.0.1 9050`, 把这一行注释掉, 添加一行`socks5 127.0.0.1 1080`
测试: 

```shell
proxychains curl www.google.com
```
使用: 
用命令行启动软件, 在前面加上proxychains, 如: 
```shell
proxychains firefox
```
使用`shadowsocks`+`proxychains`代理打开新的Firefox实现浏览器翻墙. 
也可以通过输入`proxychains bash`建立一个新的`shell`, 基于这个`shell`运行的所有命令都将使用代理. 

>  如果需要配置**不输出代理信息**, 编辑 `/etc/proxychains.conf` 将 `#quiet_mode` 改为 `quiet_mode`.

## Privoxy

Privoxy是一款带过滤功能的代理服务器, 针对HTTP、HTTPS协议. 通过Privoxy的过滤功能, 用户可以保护隐私、对网页内容进行过滤、管理cookies, 以及拦阻各种广告等. Privoxy可以用作单机, 也可以应用到多用户的网络. 

```
sudo apt install privoxy
```

安装好后进行配置, Privoxy的配置文件在`/etc/privoxy/config`, 这个配置文件中注释很多. 

找到`4.1. listen-address`这一节, 确认监听的端口号, 如果有内网地址可以监听 `0.0.0.0:8118`. 

![](https://cdn.yangbingdong.com/img/vps/privoxy-config01.png)

找到`5.2. forward-socks4, forward-socks4a, forward-socks5 and forward-socks5t`这一节, 加上如下配置, 注意最后的点号. 

![](https://cdn.yangbingdong.com/img/vps/privoxy-config02.png)

重启一下Privoxy

```
sudo /etc/init.d/privoxy restart
```

终端体验: 

```
export http_proxy="127.0.0.1:8118" && export https_proxy="127.0.0.1:8118"
wget http://www.google.com
```

在`/etc/profile`的末尾添加如下两句. 

```
export http_proxy="127.0.0.1:8118"
export https_proxy="127.0.0.1:8118"
```

# 网络优化

## Google BBR
***[一键安装最新内核并开启 BBR 脚本](https://teddysun.com/489.html)***:

```
wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && ./bbr.sh
```

或者使用下面这个开始 BBR+.

***[https://github.com/chiakge/Linux-NetSpeed](https://github.com/chiakge/Linux-NetSpeed)*** :

```
wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
```

### 更换Linode内核

谷歌开发的TCP加速外挂, 目前已集成到最新的Linux内核. 
**[Linode](https://www.linode.com/)** 不能直接命令更换内核, 需要到管理后台设置: 
![](https://cdn.yangbingdong.com/img/docker-shadowsocks/change-kernel.png)

安装完重启后输入

```
lsmod | grep bbr
```

出现 `tcp_bbr` 即说明 BBR 已经启动. 

### 手动安装

如果是最新内核:

```
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
```

## 开启TCP Fast Open

这个需要服务器和客户端都是Linux 3.7+的内核, 一般Linux的服务器发行版只有debian jessie有3.7+的, 客户端用Linux更是珍稀动物, 所以这个不多说, 如果你的服务器端和客户端都是Linux 3.7+的内核, 那就在**服务端**和**客户端**的`vi /etc/sysctl.conf`文件中再加上一行. 

```
echo "net.ipv4.tcp_fastopen = 3" | sudo tee -a /etc/sysctl.conf
echo "3" | sudo tee /proc/sys/net/ipv4/tcp_fastopen
sudo sysctl -p
```

然后把`vi /etc/shadowsocks.json`配置文件中`"fast_open": false`改为`"fast_open": true`. 这样速度也将会有非常显著的提升. 

## TCP优化

1.修改文件句柄数限制
如果是ubuntu/centos均可修改`/etc/sysctl.conf`
找到`fs.file-max`这一行, 修改其值为`1024000`, 并保存退出. 然后执行`sysctl -p`使其生效
修改`vi /etc/security/limits.conf`文件, 加入

```
*               soft    nofile           512000
*               hard    nofile          1024000
```

针对centos,还需要修改`vi /etc/pam.d/common-session`文件, 加入
`session required pam_limits.so`

2.修改`vi /etc/profile`文件, 加入
`ulimit -SHn 1024000`
然后重启服务器执行`ulimit -n`, 查询返回1024000即可. 

```
sysctl.conf报错解决方法
修复modprobe的: 
rm -f /sbin/modprobe 
ln -s /bin/true /sbin/modprobe
修复sysctl的: 
rm -f /sbin/sysctl 
ln -s /bin/true /sbin/sysctl
```

## 使用特殊端口

GFW会通过某些手段来减轻数据过滤的负荷, 例如特殊的端口如ssh, ssh默认端口给ss用了那么久必须修改我们登录服务器的端口. 
修改SSH配置文件: 

```shell
vi /etc/ssh/sshd_config
```

找到`#port 22`, 将前面的`#`去掉, 然后修改端口 `port 2333`（自己设定）. 
然后重启SSH: 

```shell
service ssh restart
```

# VPS Security

## 修改SSH登录端口

### Ubuntu

1、用下面命令进入配置文件`vi /etc/ssh/sshd_config`
2、找到`#port 22`, 将前面的`#`去掉, 然后修改端口 `port 12345`（自己设定）. 
3、然后重启ssh服务

```
#Debian/ubuntu  /etc/init.d/ssh restart   or    service ssh restart
#CentOS         service sshd restart
```

### CentOS

1、临时关闭SELinux: 

```
setenforce 0
```

2、修改SSH端口

```
vi /etc/ssh/sshd_config

#在Port 22下面加一行, 以端口2333为例, Port 2333

#重启ssh服务: 
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

如果是`yes`就是添加成功, 如果是no就是没成功

5、成功后重载防火墙

```
firewall-cmd --reload
```

6、关闭SELinux

查看SELinux状态`SELINUX`, 如果是`enabled`就是开启状态

`vi /etc/selinux/config`

修改`SELINUX=disabled`

最后重启vps试试用新的`2333`端口登录, 如果登录成功再`vi /etc/ssh/sshd_config`把`Port 22`端口删除, 再重启ssh服务就好了. 

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

> 也可以手动在客户端建立目录和authorized_keys, 注意修改权限

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

# Postgresql端口设置. 允许192.168.142.166访问5432端口
firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.142.166" port protocol="tcp" port="5432" accept"

# redis端口设置. 允许192.168.142.166访问6379端口
firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.142.166" port protocol="tcp" port="6379" accept"

# 查看配置结果, 验证配置
firewall-cmd --list-all

# 删除规则
firewall-cmd --permanent --remove-rich-rule="rule family="ipv4" source address="192.168.142.166" port protocol="tcp" port="11300" accept"

# 更新防火墙规则
firewall-cmd --reload

# 重启防火墙
systemctl restart firewalld.service
```

## DDOS deflate

`DDOS deflate`是一款免费的用来防御和减轻DDOS攻击的脚本. 它通过netstat监测跟踪创建大量网络连接的IP地址, 在检测到某个结点超过预设的限制时, 该程序会通过APF或IPTABLES禁止或阻挡这些IP. 

**安装**: 

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
#是否屏蔽IP, 默认即可

##### An email is sent to the following address when an IP is banned. 
# 当单IP发起的连接数超过阀值后,将发邮件给指定的收件人.
##### Blank would suppress sending of mails
EMAIL_TO="root" 
# 这里是邮箱, 可以把root替换成你的邮箱

##### Number of seconds the banned ip should remain in blacklist. 
# 设置被挡IP多少秒后移出黑名单.
BAN_PERIOD=600
```

将上述配置文件修改完成后, 使用命令启动即可

```
ddos -d
```

Ubuntu中可能会报错: 

```shell
root@localhost:~# ddos -d
/usr/local/sbin/ddos: 13: [: /usr/local/ddos/ddos.conf: unexpected operator
DDoS-Deflate version 0.6
Copyright (C) 2005, Zaf <zaf@vsnl.com>
```

因为启动大多数为 bash 脚本, 而 Ubuntu 的默认环境为 dash, 所以需要使用 dpkg-reconfigure dash, 选择 NO, 切换为 bash 运行脚本: 

```
dpkg-reconfigure dash
```

## fail2ban防暴力攻击

```
sudo apt install fail2ban
```

## vDDoS（只支持CentOS和CloudLinux）

***[https://github.com/duy13/vDDoS-Protection](https://github.com/duy13/vDDoS-Protection)***

## CCKiller

***[https://github.com/jagerzhang/CCKiller](https://github.com/jagerzhang/CCKiller)***

# VPS Speed Test

## speedtest

下载: 

```
wget https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py && \
chmod +x speedtest.py
```

运行: 

```
./speedtest.py

#或者
python speedtest.py
```

结果: 

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

> 地址: ***[https://github.com/sivel/speedtest-cli](https://github.com/sivel/speedtest-cli)***

pip方式安装

```
pip install speedtest-cli
```

或github安装

```
git clone https://github.com/sivel/speedtest-cli.git
python speedtest-cli/setup.py install
```
用法: 

1、list

根据距离显示所有的节点服务器列表. 

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

低调服用. . . 
