`curl https://getcaddy.com | bash -s personal http.cache,http.git,http.minify,tls.dns.linode,hook.service,http.forwardproxy`

**配置caddy**

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

* 配置 systemd

```
curl -s  https://raw.githubusercontent.com/mholt/caddy/master/dist/init/linux-systemd/caddy.service  -o /etc/systemd/system/caddy.service
systemctl daemon-reload
systemctl enable caddy.service
systemctl status caddy.service
```

- 配置Caddfile配置文件

修改Caddfile文件

```
vi /etc/caddy/Caddyfile
```

```
blog.yangbingdong.com {
    root /var/www/blog.yangbingdong.com
    gzip
    tls yangbingdong1994@gmail.com
    log / /var/log/caddy/blog.yangbingdong.com_access.log "{combined}" {
        rotate_size 10
        rotate_age  14
        rotate_keep 5
        rotate_compress
    }
    errors /var/log/caddy/blog.yangbingdong.com_error.log {
        rotate_size 10
        rotate_age  14
        rotate_keep 5
        rotate_compress
    }
    git {
        repo git@github.com:JefferyWang/blog.git
        branch master
        path /var/www/blog.wangjunfeng.com
        hook /webhook NtaZj251UH8xqB9WrRYo3Xbpvwnm6Jhs
        hook_type github
    }
}
```

给log路径赋权

```
sudo chown www-data:www-data /var/log/caddy
```

上例是一个简单的websocket加静态网站配置。第一行为自己的域名，tls后面加上邮箱会自动申请let’sencrypt ssl证书。Caddfile更多配置详见官网。

**通过systemd管理caddy**

```
systemctl daemon-reload
systemctl enable caddy.service
systemctl start caddy.service
systemctl stop caddy.service
systemctl restart caddy.service
systemctl reload caddy.service
systemctl status caddy.service
```



docker

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
        repo https://github.com/masteranthoneyd/masteranthoneyd.github.io.git
        branch master
        clone_args --recursive
        pull_args --allow-unrelated-histories
        hook /webhook NtaZj251UH8xqB9WrRYo3Xbpvwnm6Jhs
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
- `path`是指我们的拉取代码的目标地址
- `then`用来配置拉取代码后，我们重新编译hugo的静态文件
- `hook`是我们对github开放的webhook地址和密钥
- `hook_type`是我们的webhook类型

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



Caddy 指令介绍

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