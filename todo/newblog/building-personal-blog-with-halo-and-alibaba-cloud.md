# 基于阿里云搭建 Halo 个人博客

![](https://image.cdn.yangbingdong.com/image/building-personal-blog-with-halo-and-alibaba-cloud/9071e42eab7b13178362c8d6a22abdc1-a72fe6.jpg)



# 前言

构建一个博客大概可以分成两个纬度:

* 构建工具, 或者说是生成工具, 需要考虑它的易操作性, 生态等因素
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

[***我的老博客***](https://yangbingdong.com/)用的就是 Hexo 来生成的,  这类框架对于简单生成一个博客还是挺方便的, 编写 Markdown 文档, 配置主体, 执行相应命令就能生成静态 html 文件, 然后可以通过直接放到服务器上通过反向代理访问.

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

# 安装 Halo

> 参考指南: 使[***用 Docker Compose 部署***](https://docs.halo.run/getting-started/install/docker-compose)

## 环境准备

> 我这里用的是 Ubuntu, 毕竟用习惯了操作比较顺手.
>
> 别忘了切换到 root 用户

首先确保系统软件是最新的:

```bash
apt update -y && apt upgrade -y
```

安装 Docker:

```shell
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
```

> 新的 Docker 已经包含了 Compose 插件, 不再需要额外安装 docker-compose.

设置镜像加速:

```shell
echo '{"registry-mirrors": ["https://3xhp3ile.mirror.aliyuncs.com"]}' > /etc/docker/daemon.json && \
systemctl daemon-reload && \
systemctl restart docker
```

## 通过 Docker Compose 部署生产级别 Halo

先创建 network, 用于后续打通 Nginx:

```
docker network create omininet
```

创建工作目录, 添加并运行 `docker-compose.yaml`:

```
mkdir -p ~/app/halo && \
cd ~/app/halo && \
tee docker-compose.yaml <<- EOF
version: "3"

services:
  halo:
    image: halohub/halo:2.10
    container_name: halo
    restart: on-failure:3
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
      - --spring.r2dbc.url=r2dbc:pool:mysql://host:3306/halo
      - --spring.r2dbc.username=root
      - --spring.r2dbc.password=root
      - --spring.sql.init.platform=mysql
      # 外部访问地址, 请根据实际需要修改
      - --halo.external-url=https://blog.yangbingdong.com

networks:
  default:
    external: true
    name: omininet
EOF
```

* **注意**:
  *  `--halo.external-url` 填写成自己的域名
  * MySQL 我这里用的是 RDS, 自建 MySQL 参考官方文档

启动:

```
docker compose up -d
```

不出意外访问 `ip:port` (**先打开 8090 端口, 后面配置反向代理后可关闭**)可以进入系统, 初次打开创建用户设置密码, 之后就可以正常登录了, 默认界面大概长酱紫:

![](https://image.cdn.yangbingdong.com/image/building-personal-blog-with-halo-and-alibaba-cloud/63e63023eeab86e55d6de087ce089770-f7b8ff.png)



# Nginx Proxy Manager: 配置反向代理

一般来说都是会通过域名来访问博客的吧, 所以需要配置一个反向代理, 比较著名以及常用的反向代理就是 Nginx 了, 而 ***[Nginx Proxy Manager](https://nginxproxymanager.com/)*** 是一个基于 Nginx 的代理管理器, 它最大的特点是**简单方便**. 即使是没有 Nginx 基础, 也能轻松地用它来完成反向代理的操作, 而且因为**自带面板**, 操作极其简单, 非常适合配合 Docker 搭建的应用使用. Nginx Proxy Manager 后台还可以一**键申请 SSL 证书**, 并且会**自动续期**, 方便省心.

> 这里假设你已经有了一个域名, 并且降域名解析到了服务器.
>
> **在 ECS 中默认情况下 80 跟 443 端口应该是关闭的**, **记得先打开!!!** 另外 81 端口也要先打开, 因为 NPM 后台用的就是这个端口.

## 部署

```
mkdir -p ~/app/npm && \
cd ~/app/npm && \
tee docker-compose.yaml <<- EOF
version: '3'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: npm
    restart: unless-stopped
    ports:
      # These ports are in format <host-port>:<container-port>
      - '80:80' # Public HTTP Port
      - '443:443' # Public HTTPS Port
      - '81:81' # Admin Web Port
      # Add any other Stream port you want to expose
      # - '21:21' # FTP
    environment:
      # Mysql/Maria connection parameters:
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "user"
      DB_MYSQL_PASSWORD: "pwd"
      DB_MYSQL_NAME: "npm"
      # Uncomment this if IPv6 is not enabled on your host
      # DISABLE_IPV6: 'true'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt

networks:
  default:
    external: true
    name: omininet
EOF
```

启动:

```
docker compose up -d
```

没有意外的话这时候访问服务器外网 `ip:81` 或者 `域名:81` 的域名即可打开 NPM 后台, 默认用户名: ` admin@example.com ` 密码: `changeme`

 第一次登陆会提示更改用户名和密码, 建议修改一个复杂一点的密码.

![](https://image.cdn.yangbingdong.com/image/building-personal-blog-with-halo-and-alibaba-cloud/1cca93f5e7b82cb70254443962f2930d-a43588.png)

## 配置

进入首页后, 点击  `Proxy Hosts` ->  `Add Proxy Host`, 配置大概如图所示

![](https://image.cdn.yangbingdong.com/image/building-personal-blog-with-halo-and-alibaba-cloud/6bfd60df2933f4ffabf935a2f19c5d3b-9348b5.png)

- `Domain Names` : 填我们 Halo 网站的域名, 首先记得做好 DNS 解析, 把域名绑定到我们的服务器的 IP 上
- `Scheme` : 默认 `http` 即可, 除非你有自签名证书
- `Forward Hostname/IP` : 填入服务器的 IP, 或者 Docker 服务名(如果使用同一个 Docker )
- `Forward Port`: 填入 Halo 映射出的端口, 这边默认是 `8090`
- `Cache Assets` : 缓存, 可以选择打开
- `Block Common Exploits`:  阻止常见的漏洞, 可以选择打开
- `Websockets Support` : WS 支持, 可以选择打开
- `Access List`:  这个是 NPM 自带的一个限制访问功能



一键申请 SSL 证书:

![](https://image.cdn.yangbingdong.com/image/building-personal-blog-with-halo-and-alibaba-cloud/4f5d12bed307f361a95592a7c4b46ff4-667c85.png)

* 证书三个月自动续费

配置完成之后就可以通过域名访问博客啦~届时也可以选择将 NPM 后台隐藏起来, 比如将 81 端口不开放, 毕竟这玩意配置完之后基本也不会怎么变.

也可以选择给 NPM 加个域名解析并配置 SSL, 比如我就是这么玩的:

![](https://image.cdn.yangbingdong.com/image/building-personal-blog-with-halo-and-alibaba-cloud/90d54cc8849a5b0f20397c0086a057e3-a34c8c.png)

# OSS + CND 存储博客图片

Halo 自带一个附件功能, 虽然可以上传图片, 但是其不建议把文章里面的图片也放上去, 建议存放到 OSS 中, 外加一个 CDN. 因为图片一般来说应该是不怎么会变的, 那么使用 CDN 去访问博客图片会比直接访问 OSS **实惠**, 并且通过 CDN 访问 OSS, 那么 OSS 的 Bucket 就不需要公开, 一定程度上起到保护作用.

详细操作可以参考官网的最佳实践: [***CDN加速图文和视频类网站***](https://help.aliyun.com/zh/cdn/use-cases/accelerate-content-delivery-for-infographic-and-video-websites), 大致流程如下图所示:

![](https://image.cdn.yangbingdong.com/image/building-personal-blog-with-halo-and-alibaba-cloud/f89be11c850e282f799a2e4d7c31352d-2dc09c.png)

如果需要证书(比如 CDN 开启 SSL), 可以直接到[***阿里云数字证书管理服务***](https://yundun.console.aliyun.com/?p=cas#/overview/cn-hangzhou)中**申请免费证书**, 每年可以申请**20**个:

![](https://image.cdn.yangbingdong.com/image/building-personal-blog-with-halo-and-alibaba-cloud/23cae7ac2ce4543d5aa8febfa379906f-c01ee8.png)

**推荐组合使用流量包**: 

* CDN静态HTTPS请求包
* CDN下行流量（中国内地）
* 对象存储OSS资源包（包月）-标准存储包（中国内地）

# 技巧篇

## PicGo 加速图片上传动作

文章中的图片存放在 OSS 中, 如果不借助额外工具, 那么整个过成大概是这样的:

1. 截图
2. 重命名图片文件, 最好带个**随机字符**, 以免更换图片但文件名还是一样导致 CDN 拿到的还是**缓存**
3. 图片压缩(可选), 如果图片几兆那么大, 压缩一下可以**节省** OSS 存储
4. 打开 OSS 对应文件夹路径, 我一般习惯以文章英文名字作为存储该文章相关图片的文件夹名字
5. 点击上传, 复制路径
6. 在 Markdown 中粘贴图片链接, 并且修改成 CDN 的域名

好家伙, 一顿操作猛如虎, 耗费两三分钟就为了上传一张图. 而 [***PicGo***](https://github.com/Molunerfinn/PicGo) 刚好就是一个用于快速上传图片并获取图片 URL 链接的工具, 不仅支持众多 OSS 平台, 还有丰富的插件提供.

![](https://image.cdn.yangbingdong.com/image/building-personal-blog-with-halo-and-alibaba-cloud/5bfa8030fb1a581339cdf8f4764f6583-3c8bae.png)

复制图片后快捷键 `Ctrl+Shift+P` 直接上传到 OSS 并且生成 Markdown 格式图片链接在粘贴板上, 直接 `Ctrl+V` 就能完成操作, 相比原始的操作, 时间直接**优化了 90%**!!
另外再推荐两款插件:

![](https://image.cdn.yangbingdong.com/image/building-personal-blog-with-halo-and-alibaba-cloud/166f21147cb1d7fe3cea830d85bc1984-2e0afa.png)

* [***picgo-plugin-rename-file***](https://github.com/liuwave/picgo-plugin-rename-file): 可修改上传路径, 比如基于当前图片所在的文件夹路径作为 OSS 存放该图片的路径; 添加时间戳; 添加 MD5 或者随机字符
  * 这是我的配置: `image/{localFolder:1}/{hash}-{rand:6}`
* [***picgo-plugin-squoosh***](https://github.com/JolyneAnasui/picgo-plugin-squoosh): 上传前压缩图片
  * 注意, 这个插件里还带了 MD5 重命名的功能, 如果用了其他重命名插件比如上面的 `picgo-plugin-rename-file` 就不要开启这个重命名的选项
* 其他插件请参考: [***Awesome-PicGo***](https://github.com/PicGo/Awesome-PicGo)

# 其他建议

* 为确保**可移植性**, 最好使用通用的 Markdown 格式编写文章, 方便以后想切换底层博客框架的时候文章不会那么难迁移.

# 总结

本文主要介绍了基于 Halo + Alibaba Cloud Stack 搭建个人博客, 但这套东西需要一些成本(对我来说还能接受), 比如 OSS, CDN, ECS, 域名等, 见仁见智吧, 有些东西也不是必要的, 比如 CDN. 

追求性价比可以用华为云或者腾讯云, 甚至直接使用 Hexo + Github Pages 直接都能省掉服务器跟域名成本, 不好的地方可能就是访问速度会相对慢一点.