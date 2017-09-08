---
title: 基于Docker搭建Shadowsocks Server与Client
date: 2017-09-08 15:55:07
categories: [Docker,Shadowsocks]
tags: [Docker,Shadowsocks]
---
![](http://ojoba1c98.bkt.clouddn.com/img/docker-shadowsocks/shadowsocks.png)
# Preface
> 人们为什么要翻墙什么的就不多说了~
> 普通安装请参照***[Access Blocked Sites(翻墙):VPS自搭建ShadowSocks与加速](/2017/use-vps-cross-wall-by-shadowsocks-under-ubuntu/)***

<!--more-->
# Open TCP-BBR(可选项)
谷歌开发的TCP加速“外挂”，目前已集成到最新的Linux内核。
博主用的**[Linode](https://www.linode.com/)**不能直接命令更换内核，需要到管理后台设置：
![](http://ojoba1c98.bkt.clouddn.com/img/docker-shadowsocks/change-kernel.png)
然后执行：
```
wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
chmod +x bbr.sh
./bbr.sh
```

# Install Docker
详细教程不在本篇范围内，以下是最简单快捷高效的安装方式：
```
curl -fsSL get.docker.com -o get-docker.sh
sh get-docker.sh
```
就是这么粗暴的两条命令=.=
这里可能会有个小问题，如果VPS使用的`IPv6`可能会导致`apt update`失败，解决办法是把上面下载的`get-docker.sh`里面所有的`apt-get update`改为`apt-get Acquire::ForceIPv4=true update`。

# Pull Showdowsocks Image
`Showdowsocks`镜像：***[https://hub.docker.com/r/mritd/shadowsocks/](https://hub.docker.com/r/mritd/shadowsocks/)***
根据需要选择自己喜欢的Tag
```
docker pull mritd/shadowsocks:latest
```

# Command Example
```
docker run -dt --name ss -p 6443:6443 mritd/shadowsocks -s "-s 0.0.0.0 -p 6443 -m aes-256-cfb -k test123 --fast-open"
```
**说明：**
- `-m` : 参数后指定一个 `shadowsocks` 命令，如 `ss-local`，不写默认为 `ss-server`；该参数用于 shadowsocks 在客户端和服务端工作模式间切换，可选项如下: `ss-local`、`ss-manager`、`ss-nat`、`ss-redir`、`ss-server`、`ss-tunnel`
- `-s` : 参数后指定一个 `shadowsocks-libev` 的参数字符串，所有参数将被拼接到 `ss-server` 后
- `-x` : 指定该参数后才会开启 `kcptun` 支持，否则将默认禁用 `kcptun`
- `-e` : 参数后指定一个 `kcptun` 命令，如 `kcpclient`，不写默认为 `kcpserver`；该参数用于 kcptun 在客户端和服务端工作模式间切换，可选项如下: `kcpserver`、`kcpclient`
- `-k` : 参数后指定一个 `kcptun` 的参数字符串，所有参数将被拼接到 `kcptun` 后



# Shadowsocks Server
**With Kcptun**
```
docker run -dt --name ssserver --restart=always -p 6443:6443 -p 6500:6500/udp mritd/shadowsocks:latest -m "ss-server" -s "-s 0.0.0.0 -p 6443 -m aes-256-cfb -k 123456 --fast-open" -x -e "kcpserver" -k "-t 127.0.0.1:6443 -l :6500 -mode fast2"
```

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

# Shadowsocks Client
**With Kcptun**
```
docker run -dt --name ssclient --restart=always -p 1080:1080 -p 6500:6500/udp mritd/shadowsocks:latest -m "ss-local" -s "-s 127.0.0.1 -p 6500 -b 0.0.0.0 -l 1080 -m aes-256-cfb -k 123456 --fast-open" -x -e "kcpclient" -k "-r {{server-ip}}:6500 -l :6500 -mode fast2"
```

**Without Kcptun**
```
docker run -dt --name ssclient --restart=always -p 1080:1080 mritd/shadowsocks:latest -m "ss-local" -s "-s {{server-ip}} -p 6443 -b 0.0.0.0 -l 1080 -m aes-256-cfb -k 123456 --fast-open"
```

**注意：**
如果使用了**With Kcptun**，ss的监听ip填本地 `127.0.0.1`，`server-ip`填服务器`ip`。

# Last
测试了一下，在开启了BBR情况下，**without kcptun**更快。
对于一般情况（没有开启BBR或其他加速），**with kcptun**速度有所提升。