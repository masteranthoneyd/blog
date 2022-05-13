---
title: 使用Caddy部署Https静态博客站点
date: 2019-02-13 22:40:50
categories: [VPS]
tags: [Hexo, VPS, Caddy]
---

![](https://cdn.yangbingdong.com/img/caddy/caddy-banner.png)

# Preface

> Github Pages 在国内访问速度不理想, 其他国内的免费静态页面服务(Coding等)有时候也比较慢, 于是决定自己使用国内的云服务器部署静态博客. 一般是通过Nginx可以做到, 但是要开启Https以及Http2还需要手动配置一些东西, 面向普通用户不太友善, 这时候可以使用 ***[Caddy](https://caddyserver.com)*** 来做到简易部署Https的静态博客...

<!--more-->

简单来说, ***[Caddy](https://caddyserver.com)*** 是一个用GO语言编写的轻量级高性能Web服务器, 并自动启用 Https(***[Let's Encrypt](https://letsencrypt.org/)*** 自动续期) 以及 Http2, 只需要简单的配置, 对于这种静态页面网站或者简单的代理还算是比较友好的.

下面记录一下安装以及配置过程.

# 通过官方脚本安装

## 定制安装脚本

在 ***[https://caddyserver.com/download](https://caddyserver.com/download)*** 中定制自己的Caddy安装脚本:

![](https://cdn.yangbingdong.com/img/caddy/caddy-script.png)

Copy 一键安装脚本到服务器上安装即可, 比如:

```bash
curl https://getcaddy.com | bash -s personal http.cache,http.git,http.minify,tls.dns.linode,hook.service,http.forwardproxy
```

## 配置Systemd

安装完成之后配置Systemd:

```
curl -s  https://raw.githubusercontent.com/mholt/caddy/master/dist/init/linux-systemd/caddy.service  -o /etc/systemd/system/caddy.service
systemctl daemon-reload
systemctl enable caddy.service
```

通过systemd管理caddy:

```
# 添加或更新了daemon配置文件需要重新读取一下
systemctl daemon-reload

# 设置为开机启动
systemctl enable caddy.service

# 启动Caddy
systemctl start caddy.service

# 停止Caddy
systemctl stop caddy.service

# 重启Caddy
systemctl restart caddy.service

# 重新加载Caddy配置文件
systemctl reload caddy.service

# 查看Caddy状态
systemctl status caddy.service
```

## 配置Caddy

* 置文件放到 /etc/caddy 目录

```
mkdir /etc/caddy
touch /etc/caddy/Caddyfile
chown -R root:www-data /etc/caddy
```

- 配置ssl证书目录

```
mkdir /etc/ssl/caddy
chown -R www-data:root /etc/ssl/caddy
chmod 0770 /etc/ssl/caddy
```

* 配置网站目录

```
mkdir /var/www
chown www-data:www-data /var/www
```

- 配置Caddfile配置文件

修改Caddfile文件

```
vi /etc/caddy/Caddyfile
```

```
yangbingdong.com {
    root /var/www/yangbingdong.com
    gzip
    tls yangbingdong1994@gmail.com
    log / /var/log/caddy/yangbingdong.com_access.log "{combined}" {
        rotate_size 10
        rotate_age  14
        rotate_keep 5
        rotate_compress
    }
    errors /var/log/caddy/yangbingdong.com_error.log {
        rotate_size 10
        rotate_age  14
        rotate_keep 5
        rotate_compress
    }
    git {
        repo https://github.com/masteranthoneyd/masteranthoneyd.github.io.git
        branch master
        clone_args --recursive
        path /var/www/yangbingdong.com
        pull_args --allow-unrelated-histories
        hook /webhook ************************
        hook_type github
    }
}
```

- `tls`后面的邮箱是我们申请证书的邮箱，填写自己的邮箱即可
- `gzip`指开启gzip压缩
- `root`是我们站点的目录
- `log`用来记录我们博客的访问日志
- `repo`用来配置我们的git仓库
- `branch`用来配置我们要拉取的分支
- `path`是指我们的拉取代码的目标地址, 默认为`root`中指定的
- `then`用来配置拉取代码后，我们重新编译hugo的静态文件
- `hook`是我们对github开放的webhook地址和密钥
- `hook_type`是我们的webhook类型

给log路径赋权

```
chown www-data:www-data /var/log/caddy
```

上例是一个简单的websocket加静态网站配置。第一行为自己的域名，tls后面加上邮箱会自动申请let’sencrypt ssl证书。

之后重启Caddy访问域名即可.

# 通过Docker启动Caddy

> Docker仓库: ***[https://hub.docker.com/r/abiosoft/caddy](https://hub.docker.com/r/abiosoft/caddy)***

创建目录:

```
mkdir -p /var/www/yangbingdong.com && \
mkdir -p /var/log/caddy && \
mkdir -p /etc/caddy && \
mkdir -p /etc/ssl/caddy 
```

配置文件 `vi /etc/caddy/Caddyfile`:

```
www.yangbingdong.com {
    redir https://yangbingdong.com{url}
}

yangbingdong.com, :80 {
    root /srv/www/yangbingdong.com
    gzip
    tls yangbingdong1994@gmail.com
    log / /srv/log/caddy/yangbingdong.com_access.log "{combined}" {
        rotate_size 10
        rotate_age  14
        rotate_keep 5
        rotate_compress
    }
    errors /srv/log/caddy/yangbingdong.com_error.log {
        rotate_size 10
        rotate_age  14
        rotate_keep 5
        rotate_compress
    }
    git {
        repo https://ghproxy.com/https://github.com/masteranthoneyd/masteranthoneyd.github.io.git
        branch master
        clone_args --recursive
        pull_args --allow-unrelated-histories
        hook /webhook ************************
        hook_type github
    }
}
```

**注意**: repo 的地址前面加了 `https://ghproxy.com/` 是因为国内的 ECS 访问 Github 有时候会有问题, 所以采用了代理.

Docker启动:

```
docker run -d \
--name caddy \
--restart=always \
-v /var/www/yangbingdong.com:/srv/www/yangbingdong.com \
-v /var/log/caddy:/srv/log/caddy \
-v /etc/caddy/Caddyfile:/etc/Caddyfile \
-v /etc/ssl/caddy:/root/.caddy \
-e ACME_AGREE=true \
-p 80:80 -p 443:443 \
abiosoft/caddy:no-stats
```

# 配置 Github Web Hook

如下图:

![](https://cdn.yangbingdong.com/img/caddy/config-githun-webhook.png)

![](https://cdn.yangbingdong.com/img/caddy/add-github-webhook.png)

- Content Type 需要选择 `application/json`

Caddyfile 中配置:

```
...
    git {
        repo https://github.com/masteranthoneyd/masteranthoneyd.github.io.git
        branch master
        clone_args --recursive
        pull_args --allow-unrelated-histories
        hook /webhook ************************
        hook_type github
    }
...
```



# Caddy 指令介绍

> 更多指令请查看官方文档: ***[https://caddyserver.com/docs](https://caddyserver.com/docs)***

| 指令       | 说明                                                         | 默认情况的处理                                               |
| ---------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| basicauth  | HTTP基本认证                                                 |                                                              |
| bind       | 用于给TCP监听套接字绑定IP地址                                | 默认绑定在为通配符地址                                       |
| browse     | 目录浏览功能                                                 |                                                              |
| errors     | 配置HTTP错误页面以及错误日志                                 | 响应码>=400的返回一个纯文本错误消息,也不记录日志             |
| expvar     | 将运行时或者当前进程的一些信息(内存统计,启动命令,协程数等)以JSON格式暴露在某个路径下. |                                                              |
| ext        | 对于不存在的路径,自动追加后缀名后再次尝试                    |                                                              |
| fastcgi    | fastcgi配置                                                  |                                                              |
| gzip       | gzip压缩配置                                                 | 不压缩,但是如果网站目录下存在.gz或者.br压缩文件,Caddy就会使用. 如果客户端支持gzip格式的压缩压缩文件,Caddy确保不压缩图片,视频和已压缩文件 |
| header     | 设置响应头,可以增加,修改和删除.如果是代理的必须在proxy指令中设置 |                                                              |
| import     | 从其他文件或代码段导入配置,减少重复                          |                                                              |
| index      | 索引文件配置                                                 | index(default).html(htm/txt)                                 |
| internal   | X-Accel-Redirect 静态转发配置, 该路径外部不可访问,caddy配置的代理可以发出X-Accel-Redirect请求 |                                                              |
| limit      | 设置HTTP请求头( one limit applies to all sites on the same listener)和请求体的大小限制 | 默认无限制.设置了之后,如果超出了限制返回413响应              |
| log        | 请求日志配置                                                 |                                                              |
| markdown   | 将markdown文件渲染成HTML                                     |                                                              |
| mime       | 根据响应文件扩展名设置Content-Type字段                       |                                                              |
| on         | 在服务器启动/关闭/刷新证书的时候执行的外部命令               |                                                              |
| pprof      | 在某个路径下展示profiling信息                                |                                                              |
| proxy      | 反向代理和负载均衡配置                                       |                                                              |
| push       | 开启和配置HTTP/2服务器推                                     |                                                              |
| redir      | 根据请求返回重定向响应(可自己设置重定向状态码)               |                                                              |
| request_id | 生成一个UUID,之后可以通过{request_id}占位符使用              |                                                              |
| rewrite    | 服务器端的重定向                                             |                                                              |
| root       | 网站根目录配置                                               |                                                              |
| status     | 访问某些路径时,直接返回一个配置好的状态码                    |                                                              |
| templates  | 模板配置                                                     |                                                              |
| timeouts   | 设置超时时间:读请求的时间/读请求头的时间/写响应的时间/闲置时间(使用keep-alive时) | Keep-Alive超时时间默认为5分钟                                |
| tls        | HTTPS配置,摘自文档的一句话: **Since HTTPS is enabled automatically, this directive should only be used to deliberately override default settings. Use with care, if at all.** |                                                              |
| websocket  | 提供一个简单的Websocket服务器                                |                                                              |

占位符清单: ***[https://caddyserver.com/docs/placeholders](https://caddyserver.com/docs/placeholders)***