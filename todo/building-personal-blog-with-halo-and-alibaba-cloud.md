# 基于阿里云搭建 Halo 个人博客

# 前言

构建一个博客大概可以分成两个纬度:

* 构建工具, 或者说是生成工具
* 云平台, 用于部署以及运维博客

> 当然你也可以通过平台能力托管一个, 比如  WordPress.

## 构建工具

以下是两个静态网站生成工具排行参考的链接:

*  [***Static Site Generators - Top Open Source SSGs***](https://jamstack.org/generators/) 
*  [***Static Site Generator - Ranking - OSS Insight***](https://ossinsight.io/collections/static-site-generator/)

人气比较高的几个:

* [***Hugo***](https://gohugo.io/)
* [***Jekyll***](https://jekyllrb.com/)
* [***Hexo***](https://hexo.io/)

我之前博客用的就是 Hexo 来生成的,  这类框架对于简单生成一个博客还是挺方便的, 编写 Markdown 文档, 配置主体, 执行相应命令就能生成静态 html 文件, 然后可以通过直接放到服务器上通过反向代理访问.

虽然上手容易操作简单, 但是想要实现一些额外的功能可能往往需要第三方的**集成**, 比如评论, 搜索等, 毕竟框架生成的只是静态页面, 不具备**服务端功能**. 

很久之前(在我刚开始写博客的时候)我就考虑过需要的是一个比较整体, 功能比较完善的博客系统, 当时就有注意到 ***[Halo](https://docs.halo.run/)***, 只不过大概出于以下两点考虑并没有采取该框架:

* Halo 是前后端分离, 前端还好, 后端由于是用 Java 编写的, 并且依赖数据库, 也就意味着服务器需要起一个 Java 服务以及 MySQL 数据库, 所以对于服务器内存有一定要求. (当时2G2核的服务器还是挺贵的)
* 当时 Halo 刚刚起步, 生态方面还不算太完善. (当时还跟 Halo 的作者提过一个天真的想法, 在后台编写文章后直接生成静态博客页面, 而不是模板渲染, 后来一想其实加个 CDN 一样的效果)

但经过这么多年的框架迭代以及云平台服务器的降价, 上面两个问题得到了很好的缓和, 所以决定使用 Halo 重新搭建一个博客网站, 或者说是迁移~

## 云平台

这个没啥好说的, 因为我的域名很早就在阿里云备案了, 换平台需要重新备案, 索性直接用阿里云算了. 而且阿里云生态应该是最丰富的了, 各种产品的集成先对来说比较便捷, 比如 OSS 跟 CDN 的集成, 追求性价比可以考虑腾讯云或者华为云.

# 简介

***[Halo](https://docs.halo.run/)*** [ˈheɪloʊ], 强大易用的开源建站工具. 

Doc:  ***[https://docs.halo.run](https://docs.halo.run)***

# 初体验

Requirements:

* Docker

> Windows Docker Desktop 很方便~

本地运行: 

```
docker run -it -d --name halo -p 8090:8090 -v ~/.halo2:/root/.halo2 halohub/halo:2.10
```

访问 localhost:8080 即可访问后台.

工作目录: 

- `db`: 存放 H2 Database 的物理文件, 如果你使用其他数据库, 那么不会存在这个目录. 
- `themes`: 里面包含用户所安装的主题. 
- `plugins`: 里面包含用户所安装的插件. 
- `attachments`: 附件目录. 
- `logs`: 运行日志目录. 
- `application.yaml`: 配置文件. 

# 安装 Halo

## 环境准备

我是用的是阿里云 ECS, 镜像使用的是 Alibaba Cloud Image, 但下面使用的命令都是比较通用的, 比如包管理工具 dnf, 所以理论上适用于大部分 Linux 操作系统.

> 这里我是切换 root 用户运行

首先确保系统软件是最新的:

```
dnf update
```

安装 Docker, Docker Compose, 设置镜像加速: 

```
dnf config-manager --add-repo=https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo && \
dnf -y install dnf-plugin-releasever-adapter --repo alinux3-plus && \
dnf -y install docker-ce --nobest && \
systemctl start docker && \
systemctl enable docker && \
dnf install python3-pip && \
pip3 install -U pip setuptools && \
pip3 install docker-compose && \
echo '{"registry-mirrors": ["https://3xhp3ile.mirror.aliyuncs.com"]}' > /etc/docker/daemon.json && \
systemctl daemon-reload && \
systemctl restart docker
```

## 通过 Docker Compose 安装 Halo

创建工作目录 halo, cd 进去, 并添加 `docker-compose.yaml`:

```
cd ~ && \
mkdir halo && cd halo && \
tee /root/halo/docker-compose.yaml <<- EOF
version: "3"

services:
  halo:
    image: halohub/halo:2.10
    container_name: halo
    restart: on-failure:3
    depends_on:
      halodb:
        condition: service_healthy
    networks:
      halo_network:
    volumes:
      - ./halo2:/root/.halo2
    ports:
      - "8090:8090"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8090/actuator/health/readiness"]
      interval: 30s
      timeout: 5s
      retries: 5
      start_period: 30s
    command:
      - --spring.r2dbc.url=r2dbc:pool:mysql://halodb:3306/halo
      - --spring.r2dbc.username=root
      # MySQL 的密码，请保证与下方 MYSQL_ROOT_PASSWORD 的变量值一致。
      - --spring.r2dbc.password=123qwe
      - --spring.sql.init.platform=mysql
      # 外部访问地址，请根据实际需要修改
      - --halo.external-url=http://localhost:8090/

  halodb:
    image: mysql:8.1.0
    container_name: halodb
    restart: on-failure:3
    networks:
      halo_network:
    command: 
      - --default-authentication-plugin=caching_sha2_password
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_general_ci
      - --explicit_defaults_for_timestamp=true
    volumes:
      - ./mysql:/var/lib/mysql
      - ./mysqlBackup:/data/mysqlBackup
    ports:
      - "3306:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "--silent"]
      interval: 3s
      retries: 5
      start_period: 30s
    environment:
      # 请修改此密码，并对应修改上方 Halo 服务的 SPRING_R2DBC_PASSWORD 变量值
      - MYSQL_ROOT_PASSWORD=123qwe
      - MYSQL_DATABASE=halo

networks:
  halo_network:
EOF
```

启动:

```
docker-compose up -d
```

# Nginx Proxy Manager: 配置反向代理

上面已经启动了 Halo, 不出意外可以使用 `ip:port` 进行访问, 但一般来说都是会通过域名来访问博客的吧, 所以需要配置一个反向代理.

***[Nginx Proxy Manager](https://nginxproxymanager.com/)*** 就是一个 Nginx 的代理管理器, 它最大的特点是**简单方便**. 即使是没有 Nginx 基础, 也能轻松地用它来完成反向代理的操作, 而且因为**自带面板**, 操作极其简单, 非常适合配合 docker 搭建的应用使用. Nginx Proxy Manager 后台还可以一**键申请 SSL 证书**, 并且会**自动续期**, 方便省心.

> 这里假设你已经有了一个域名, 并且降域名解析到了服务器.
>
> 在 ECS 中默认情况下 80 跟 443 端口应该是关闭的, 记得先打开.

## 部署

```
mkdir -p ~/data/docker_data/nginxproxymanager && \
cd ~/data/docker_data/nginxproxymanager && \
tee docker-compose.yaml <<- EOF
version: '3'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'              # 不建议修改端口
      - '81:81'              # 可以把冒号左边的 81 端口修改成你服务器上没有被占用的端口
      - '443:443'            # 不建议修改端口
    volumes:
      - ./data:/data         # 点号表示当前文件夹，冒号左边的意思是在当前文件夹下创建一个 data 目录，用于存放数据，如果不存在的话，会自动创建
      - ./letsencrypt:/etc/letsencrypt  # 点号表示当前文件夹，冒号左边的意思是在当前文件夹下创建一个 letsencrypt 目录，用于存放证书，如果不存在的话，会自动创建
EOF
```

启动:

```
docker-compose up -d
```

## 配置

浏览器输入 服务器ip:81 即可访问,  默认登陆的用户名: `admin@example.com` 密码: `changeme`, 第一次访问会要求修改邮箱密码.

进入首页后, 点击  `Proxy Hosts` ->  `Add Proxy Host` 

# OSS + CND 存储博客图片

图片一般来说应该是不怎么会变得, 那么使用 CDN 去访问博客图片会比直接访问 OSS 实惠.

>  推荐组合使用流量包: CDN静态HTTPS请求包, CDN下行流量（中国内地）, 对象存储OSS资源包（包月）-标准存储包（中国内地）

https://help.aliyun.com/zh/cdn/use-cases/accelerate-content-delivery-for-infographic-and-video-websites

https://github.com/Molunerfinn/PicGo

https://github.com/liuwave/picgo-plugin-rename-file

https://github.com/JolyneAnasui/picgo-plugin-squoosh