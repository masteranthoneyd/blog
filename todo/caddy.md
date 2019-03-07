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

```
docker run \
--name caddy \
-v /var/www/blog.yangbingdong.com:/srv \
-v /etc/caddy/Caddyfile:/etc/Caddyfile \
-e ACME_AGREE=true \
-p 80:80 -p 443:443 \
abiosoft/caddy

/etc/caddy/Caddyfile:
http://blog.yangbingdong.com {
    redir https://blog.yangbingdong.me
}

https://blog.yangbingdong.com {
    #tls off
    tls yangbingdong1994@gmai.com
    root /srv 
}
```





```
http://axiong.me {
    redir https://axiong.me
}
https://axiong.me {
    #tls admin@example.com
    minify
    gzip
    log / /var/log/caddy/pub-axiong.me_access.log "{combined}" {
        rotate_size 100 # Rotate a log when it reaches 100 MB
        rotate_age  14  # Keep rotated log files for 14 days
        rotate_keep 10  # Keep at most 10 rotated log files
        rotate_compress # Compress rotated log files in gzip format
    }
    errors /var/log/caddy/pub-axiong.me_error.log {
        404 404.html # Not Found
        rotate_size 100 # Rotate a log when it reaches 100 MB
        rotate_age  14  # Keep rotated log files for 14 days
        rotate_keep 10  # Keep at most 10 rotated log files
        rotate_compress # Compress rotated log files in gzip format
    }
    root /var/www/axiong.me/public
    git {
        repo git@github.com:JefferyWang/blog.git
        branch master
        path /var/www/blog.wangjunfeng.com
        then hugo --destination=/var/www/blog.wangjunfeng.com/public
        hook /webhook NtaZj251UH8xqB9WrRYo3Xbpvwnm6Jhs
        hook_type github
    }
    hugo
}
```

