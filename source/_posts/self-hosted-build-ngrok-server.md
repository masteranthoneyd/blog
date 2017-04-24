---
title: self-hosted-build-ngrok-server
date: 2017-04-24 18:44:20
categories:
tags:
---
# 前言
> 我们经常会有「把本机开发中的 web 项目给朋友看一下」或「测试一下支付宝、微信的支付功能」这种临时需求，为此**专门**购买个域名然后在 VPS或云主机 上**部署一遍**就有点太**浪费**了。那么这时候，**ngrok**就是个很好的东西，它可以实现我们的这种需求。而且 ngrok 官网本身还提供了公共服务，只需要注册一个帐号，运行它的客户端，就可以快速把内网映射出去。不过这么好的服务，没多久就被**墙**了~幸好ngrok是**开源**的，那么我们可以自己搭建一个ngrok！

<!--more-->
# 一、安装GO环境
```shell
apt-get update
apt-get install build-essential mercurial git
wget https://storage.googleapis.com/golang/go1.8.1.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.8.1.linux-amd64.tar.gz
mkdir $HOME/go
echo 'export GOROOT=/usr/local/go' >> ~/.bashrc 
echo 'export GOPATH=$HOME/go' >> ~/.bashrc 
echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' >> ~/.bashrc 
source $HOME/.bashrc
```

# 二、安装Ngrok
```shell
cd /usr/local/src/
git clone https://github.com/tutumcloud/ngrok.git ngrok
export GOPATH=/usr/local/src/ngrok/
export NGROK_DOMAIN="ngrok.yangbingdong.com"
```
生成自签名SSL证书，ngrok为ssl加密连接：
```shell
cd ngrok
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$NGROK_DOMAIN" -days 5000 -out rootCA.pem
openssl genrsa -out device.key 2048
openssl req -new -key device.key -subj "/CN=$NGROK_DOMAIN" -out device.csr
openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 5000
cp rootCA.pem assets/client/tls/ngrokroot.crt
cp device.crt assets/server/tls/snakeoil.crt 
cp device.key assets/server/tls/snakeoil.key
GOOS=linux GOARCH=386
make clean
make release-server release-client
```

启动server
```shell
cd /usr/local/src/ngrok/bin && ./ngrokd -domain="ngrok.yangbingdong.com" -httpAddr=":8080" -httpsAddr=":8081" -tunnelAddr=":443"
```

后台运行：
```shell
apt-get install screen
screen -S 任意名字（例如：keepngork）
然后运行ngrok启动命令
最后按快捷键
ctrl+A+D
既可以保持ngrok后台运行
```

# 上传脚本
```shell
scp -P26850 ~/ngrokbuild.sh root@45.78.26.212:/root
```


# 下载客户端
```shell
scp -P33033 root@45.78.26.212:/usr/local/src/ngrok/bin/ngrok ~/
```

# 开机启动
```shell
vim /etc/init.d/ngrok_start:
cd /root/goproj/src/github.com/inconshreveable
./bin/ngrokd -tlsKey=server.key -tlsCrt=server.crt -domain="tunnel.imike.me" -httpAddr=":8081" -httpsAddr=":8082"
chmod 755 /etc/init.d/ngrok_start
```

# 启动客户端
写一个简单的配置文件，随意命名如 ngrok.cfg：
```
server_addr: ngrok.yangbingdong.com:443
trust_host_root_certs: false
```
```
./ngrok -subdomain ybd -proto=http -config=ngrok.cfg 80
```

# Nginx添加server
```
#ngrok.imike.me.conf
upstream ngrok {
    server 127.0.0.1:8000;
    keepalive 64;
}

server {
    listen 80;
    server_name *.tunnel.imike.me;
    access_log /var/log/nginx/ngrok_access.log;
    location / {
        proxy_set_essay-header X-Real-IP $remote_addr;
        proxy_set_essay-header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_essay-header Host  $http_host:8081;
        proxy_set_essay-header X-Nginx-Proxy true;
        proxy_set_essay-header Connection "";
        proxy_pass      http://ngrok;

    }

}
```

# 常见错误
在ngrok目录下执行如下命令，编译ngrokd
```
$ make release-server

出现如下错误：
GOOS="" GOARCH="" go get github.com/jteeuwen/go-bindata/go-bindata
bin/go-bindata -nomemcopy -pkg=assets -tags=release \
        -debug=false \
        -o=src/ngrok/client/assets/assets_release.go \
        assets/client/…
make: bin/go-bindata: Command not found
make: *** [client-assets] Error 127
go-bindata被安装到了$GOBIN下了，go编译器找不到了。修正方法是将$GOBIN/go-bindata拷贝到当前ngrok/bin下。

$cp /home/ubuntu/.bin/go14/bin/go-bindata ./bin
```





