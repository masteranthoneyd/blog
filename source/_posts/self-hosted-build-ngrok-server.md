---
title: self-hosted-build-ngrok-server
date: 2017-04-24 18:44:20
categories:
tags:
---


<!--more-->
# 一、安装GO环境
```shell
wget https://storage.googleapis.com/golang/go1.8.1.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.4.1.linux-amd64.tar.gz
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
cd /usr/local/src/ngrok
bin/ngrokd -domain="ngrok.yangbingdong.com" -httpAddr=":80"
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


