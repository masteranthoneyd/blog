---
title: VPS自搭建Ngrok内网穿透服务
date: 2017-04-26 18:44:20
categories: [VPS]
tags: [VPS,Ngrok]
---
![](https://cdn.yangbingdong.com/ngrok.png)
# 前言
> Ngrok可以干嘛？我们经常会有 "把本机开发中的 web 项目给朋友看一下" 或 "测试一下支付宝、微信的支付功能" 这种临时需求，为此**专门**购买个域名然后在 VPS或云主机 上**部署一遍**就有点太**浪费**了。那么这时候，**Ngrok**就是个很好的东西，它可以实现我们的这种需求。而且 Ngrok 官网本身还提供了公共服务，只需要注册一个帐号，运行它的客户端，就可以快速把内网映射出去。不过这么好的服务，没多久就被**墙**了~幸好Ngrok是**开源**的，那么我们可以自己搭建一个Ngrok！

<!--more-->
# 域名泛解析
因为内网穿透需要用到多级域名，这里，博主的这个域名是在***[Namesilo](https://www.namesilo.com/)***购买的，然后转到DNSPod解析：
![](https://cdn.yangbingdong.com/DNSPod.png)
如图所示，我搞买的域名是`yangbingdong.com`,将`ngrok.yangbingdong.com`通过`A`记录解析导VPS的ip地址，再将`*.ngrok.yangbingdong.com`通过`CNAME`解析导`ngrok.yangbingdong.com`，完成泛解析。

# 服务端安装
## 安装GO环境
> 这里博主选择通过下载最新版解压安装。

```shell
apt-get update
apt-get -y install build-essential mercurial git
wget https://storage.googleapis.com/golang/go1.8.1.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.8.1.linux-amd64.tar.gz
mkdir $HOME/go
echo 'export GOROOT=/usr/local/go' >> /etc/profile.d/go.sh
echo 'export GOPATH=$HOME/go' >> /etc/profile.d/go.sh
echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' >> /etc/profile.d/go.sh
source /etc/profile.d/go.sh
```

## 安装Ngrok
```shell
cd /usr/local/src/
git clone https://github.com/tutumcloud/ngrok.git ngrok
export GOPATH=/usr/local/src/ngrok/
```
生成自签名SSL证书，ngrok为ssl加密连接：
```shell
cd ngrok
NGROK_DOMAIN="ngrok.yangbingdong.com"
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$NGROK_DOMAIN" -days 5000 -out rootCA.pem
openssl genrsa -out device.key 2048
openssl req -new -key device.key -subj "/CN=$NGROK_DOMAIN" -out device.csr
openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 5000
cp rootCA.pem assets/client/tls/ngrokroot.crt
cp device.crt assets/server/tls/snakeoil.crt 
cp device.key assets/server/tls/snakeoil.key
GOOS=linux GOARCH=amd64
make clean
make release-server release-client
```
注意：**上面的`ngrok.yangbingdong.com`换成自己的域名**。
* 如果是32位系统,`GOARCH=386`; 如果是64为系统，`GOARCH=amd64`
* 如果要编译linux,`GOOS=linux`;如果要编译window,`GOOS=windows`

## 启动server
```shell
cd /usr/local/src/ngrok/bin && ./ngrokd -domain="ngrok.yangbingdong.com" -httpAddr=":8002" -httpsAddr=":8003" -tunnelAddr=":4000"
```
**`ngrok.yangbingdong.com`换成自己的域名**。其他端口可自己配置。
顺利的话，可以正常编译，在`bin`下面可以看到「ngrokd」和「ngrok」，其中「ngrokd」是服务端执行程序，「ngrok」是客户端执行程序
![](https://cdn.yangbingdong.com/ngrok-server-startup.png)

## 后台运行：
```shell
cd /usr/local/src/ngrok/bin && nohup ./ngrokd -domain="ngrok.yangbingdong.com" -httpAddr=":8002" -httpsAddr=":8003" -tunnelAddr=":4000"  > /dev/null 2>&1 &
```

```shell
apt-get install screen
screen -S 任意名字（例如：keepngork）
然后运行ngrok启动命令
最后按快捷键
ctrl+A+D
既可以保持ngrok后台运行
```

## 设置开机启动
```shell
vim /etc/init.d/ngrok_start:
cd /usr/local/src/ngrok/bin
./ngrokd -domain="ngrok.yangbingdong.com" -httpAddr=":8002" -httpsAddr=":8003" -tunnelAddr=":4000"

chmod 755 /etc/init.d/ngrok_start
```

# 客户端使用
## 下载客户端
```shell
scp -P 26850 root@12.34.56.78:/usr/local/src/ngrok/bin/ngrok ~/
```
**将`12.34.56.78`换成自己的VPS ip**。

## 启动客户端
写一个简单的配置文件，随意命名如 ngrok.cfg：
```
server_addr: ngrok.yangbingdong.com:4000
trust_host_root_certs: false
```
然后启动：
```
./ngrok -subdomain ybd -config=ngrok.cfg 8080
```
其中`ybd`是自定义的域名前缀，`ngrok.cfg`是上面创建的配置文件，`8080`是本地需要映射到外网的端口。
没有意外的话访问`ybd.ngrok.yangbingdong.com:8002`就会映射到本机的`8080`端口了。
![](https://cdn.yangbingdong.com/ngrok-client-startup01.png)

控制台：

就是上图的`Web Interface`，通过这个界面可以看到远端转发过来的 http 详情，包括完整的 request/response 信息，相当于附带了一个抓包工具。



另外，Ngrok支持多种协议，启动的时候可以指定通过`-proto`指定协议，例如：

**http协议**：

```shell
./ngrok -subdomain ybd -config=ngrok.cfg -proto=http 8080
```

**tcp协议**：

```shell
./ngrok -subdomain ybd -config=ngrok.cfg -proto=tcp 8080
```

应该会看到：

```shell
ngrok                                               (Ctrl+C to quit)

Tunnel Status                 online
Version                       1.7/1.7
Forwarding                    tcp://ybd.ngrok.yangbingdong.com:8002-> 127.0.0.1:8080
Web Interface                 127.0.0.1:4040
# Conn                        0
Avg Conn Time                 0.00ms

```



# Nginx添加server

虽然可以访问，但是带着端口就让人不舒服，80端口又被Nginx占用，那么可以用过Nginx反向代理Ngrok。
Nginx的配置一般在`/etc/nginx/conf.d`或者`/usr/local/nginx/conf.d`里面：
```
#ngrok.yangbingdong.com.conf
upstream ngrok {
    server 127.0.0.1:8002;
    keepalive 64;
}

server {
    listen 80;
    server_name *.ngrok.yangbingdong.com;
    access_log /var/log/nginx/ngrok_access.log;
    proxy_set_header "Host" $host:8002;
    location / {
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host:8002;
        proxy_pass_header Server;
        proxy_redirect off;
        proxy_pass  http://ngrok;

    }
    access_log off;
    log_not_found off;
}
```


重启Nginx：
```shell
nginx -s reload 
```
# 维护脚本
在网上看到的某大神写的维护脚本：

```shell
wget https://gist.githubusercontent.com/IvanChou/1be8b15b1b41bf0ce2e9d939866bbfec/raw/1a2445599fe7fd706505a6e103a9dc60b4d3a0ed/ngrokd -O ngrokd

##修改 脚本中的配置
vi ngrokd

chomd +x ngrokd
sudo mv ngrokd /etc/init.d/ngrokd
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

# 遇到的问题：source与./
写了一个Ngrok的***[安装脚本](https://github.com/masteranthoneyd/about-shell/blob/master/ngrok-installation.sh)***，然后`chmod +x ngrok-installation.sh`赋权，再`./ngrok-installation.sh`执行。
但是遇到了一个奇怪的问题：在脚本里面设置了环境变量并source让其生效，然而出现的结果是由于**没有加载**到环境变量导致找不到命令，百思不得解，Google了一把，发现了原因：
>`source`命令与`shell scripts`的区别是：
>我们在test.sh设置了AA环境变量，它只在fork出来的这个子shell中生效，子shell只能继承父shell的环境变量，而不能修改父shell的环境变量，所以test.sh结束后，父进程的环境就覆盖回去。
>source在当前bash环境下执行命令，而scripts是启动一个子shell来执行命令。这样如果把设置环境变量（或alias等等）的命令写进scripts中，就只会影响子shell,无法改变当前的BASH,所以通过文件（命令列）设置环境变量时，要用source 命令。

然后直接`source ngrok-installation.sh`，安装成功！

# Docker搭建Ngrok

> 安装Docker请看***[这里](/2017/docker-learning/)***

## 构建镜像

```
git clone https://github.com/hteen/docker-ngrok.git
cd docker-ngrok
docker build -t hteen/ngrok .
```

##  运行镜像

```
docker run -idt --name ngrok-server \
-p 8082:80 -p 4432:443 -p 4443:4443 \
-v /root/docker/ngrok/data:/myfiles \
-e DOMAIN='ngrok.yangbingdong.com' hteen/ngrok /bin/sh /server.sh
```

- `-p`: 80端口为http端口，433端口为https端口，4443端口为tunnel端口
- `-v`: 生成的各种配置文件和客户端都在里面
- `-e`: 泛化的域名


稍等片刻，会在挂在的目录（`/root/docker/ngrok/data`）下面生成对应的配置文件以及客户端

```
bin/ngrokd                  服务端
bin/ngrok                   linux客户端
bin/darwin_amd64/ngrok      osx客户端
bin/windows_amd64/ngrok.exe windows客户端
```

## Nginx Conf

```
server {
     listen       80;
     server_name  *.ngrok.yangbingdong.com;
     location / {
             proxy_redirect off;
             proxy_set_header Host $host;
             proxy_set_header X-Real-IP $remote_addr;
             proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
             proxy_pass http://172.17.0.1:8082;
     }
 }
 server {
     listen       443;
     server_name  *.ngrok.yangbingdong.com;
     location / {
             proxy_redirect off;
             proxy_set_header Host $host;
             proxy_set_header X-Real-IP $remote_addr;
             proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
             proxy_pass http://172.17.0.1:4432;
     }
 }
```

- `172.17.0.1`为内网ip

**注意**：大概每个星期会产生100M的日志文件。
查年docker日志文件位置`docker inspect <id> | grep LogPath`
查看大小`ls -lh /var/lib/docker/containers/<id>/<id>-json.log`



