---
title: NGINX初学指南(安装与简单配置)
date: 2017-04-24 16:56:15
categories: [Nginx]
tags: [VPS,Nginx]
---
![](https://cdn.yangbingdong.com/NGINX.png)
# 前言
> 走上了VPS这条~~不归路~~，就意味着需要会维护以及运营自己的服务器。那么这一章记录一下学习Nginx的一些东西...
> 本文绝大部分内容来自NGINX 网站的官方手册：
> ***[https://www.nginx.com/resources/admin-guide/installing-nginx-open-source/](https://www.nginx.com/resources/admin-guide/installing-nginx-open-source/)***
> ***[http://nginx.org/en/docs/beginners_guide.html](http://nginx.org/en/docs/beginners_guide.html)***

<!--more-->
# 安装NGINX部分
## 主干版本VS稳定版本
NGINX 有两个有效版本：
* 主干版本。这个版本中包含了最新的功能和 BUG 修复，并且总是最新的版本。这个版本很可靠，但是也包含了一些实验性质的模块和一定数量的新 BUG。
* 稳定版本。这个版本没有最新的功能，但是包含了关键 BUG 的修复。在生产服务器中推荐使用稳定版本。

## 预编译包VS源码编译
NGINX 的主干版本和稳定版本都可以以下两种方式安装：
* 预编译包安装。这是一种快捷的安装方式。预编译包中含有几乎所有 NGINX 官方模块并且适用于大多数主流的操作系统。
* 通过源码编译安装。这种方式更加灵活：你可以添加包括第三方模块在内的特殊模块以及最新的安全补丁。

## 通过源码编译和安装
> 通过源码编译 NGINX 带给你更多的灵活性：你可以添加包括第三方模块在内的特殊模块以及最新的安全补丁。

先安装一些编译依赖：
```shell
apt-get update && apt-get install -y build-essential libtool 
```
### 安装 NGINX 依赖
1、***[PCRC](http://pcre.org/)*** 库：被 NGINX ***[Core](https://nginx.org/en/docs/ngx_core_module.html?_ga=2.65941421.2064822644.1493181926-708921149.1492677721)*** 和 ***[Rewrite](https://nginx.org/en/docs/http/ngx_http_rewrite_module.html?_ga=2.65941421.2064822644.1493181926-708921149.1492677721)*** 模块需求，并且提供正则表达式支持：
```shell
cd /usr/local/src && wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.40.tar.gz && tar -zxf pcre-8.40.tar.gz && cd pcre-8.40 && ./configure && make && make install
```

2、***[zlib](http://www.zlib.net/)*** 库：为了头部压缩被 NGINX ***[Gzip](https://nginx.org/en/docs/http/ngx_http_gzip_module.html?_ga=2.65941421.2064822644.1493181926-708921149.1492677721)*** 模块需求：
```shell
cd /usr/local/src && wget http://zlib.net/zlib-1.2.11.tar.gz && tar -zxf zlib-1.2.11.tar.gz && cd zlib-1.2.11 && ./configure && make && make install
```

3、***[OpenSSL](https://www.openssl.org/)*** 库：被 NGINX SSL 模块需求用以支持 HTTPS 协议：
> 这里博主并不选择源码安装=.=，而是通过apt安装：

```shell
apt-get upgrade
apt-get install -y libssl-dev openssl
```
### 下载源码
NGINX 同时提供了稳定版本和主干版本的源码文件。源码文件可以从 NGINX Open Source 下载页面下载：
<a id="download" href="http://www.nginx.org/en/download.html"><i class="fa fa-download"></i><span>Redirect Download Page</span>
</a>
下载并解压最新的主干版本源码文件，在命令行中输入下面的命令：
```shell
cd /usr/local/src && wget http://nginx.org/download/nginx-1.12.0.tar.gz && tar -zxvf nginx-1.12.0.tar.gz && cd nginx-1.12.0
```

### 配置构建选项
配置选项要使用 `./configure` 脚本来设置各种 NGINX 的参数，其中包括源码和配置文件路径、编译器选项，连接处理方法以及模块列表。脚本最终创建了用于编译代码和安装 NGINX 的 Makefile 文件。
例如：
```shell
./configure --sbin-path=/usr/local/nginx/nginx --conf-path=/usr/local/nginx/nginx.conf --pid-path=/usr/local/nginx/nginx.pid --with-pcre=../pcre-8.40 --with-zlib=../zlib-1.2.11 --with-http_ssl_module --with-stream --with-http_stub_status_module
```

#### 配置 NGINX 路径
配置脚本允许你设置 NGINX 二进制文件和配置文件的路径以及依赖库 （PCRC 或 SSL）的路径，以便静态链接到 NGINX 二进制文件中。

`–prefix=path`：
定义保存 NGINX 文件的目录。目录也将被用于所有通过 `./configure` 设置的相对路径和 nginx.conf 配置文件的路径。默认这个路径被设置为 `/usr/local/nginx`。

`–sbin-path=path`：
设置 NGINX 可执行文件的名称。这个名称仅在安装期间使用。该文件默认的被命名为 `prefix/sbin/nginx`。

`–conf-path=path`：
设置 NGINX 配置文件名称。该文件默认的被命名为 `prefix/conf/nginx.conf`。

注意：无论这个选项是什么，你都可以在命令行中通过 -c 选项来指定使用不同的配置文件启动 NGINX。

`–pid-path=path`：
设置存储主进程的进程 id 的 `nginx.pid` 文件名。在安装以后，文件名的路径总是可以在 `nginx.conf` 文件中被修改，通过使用 pid 指令。默认该文件被命名为 `prefix/logs/nginx.pid`

`–error-log-path=path`：
设置主要的错误，警告和诊断文件的名字。安装之后，文件名总是可以在 `nginx.conf` 文件中使用 `error_log` 指令修改。该文件默认被命名为 `prefix/logs/access.log`。

`–user=name`：
设置凭据将被用于 NGINX worker 进程的非特权用户的名称。在安装后，这个名称可以通过使用 user 指令在 `nginx.conf` 文件中修改。默认的名字是 nobody。

`–group=name`：
设置凭据将被用于 NGINX worker 进程的用户组名。在安装以后，这个名称可以通过使用 user 指令在 `nginx.conf` 文件中修改。默认地，用户组名被设置为非特权用户的名字。

`–with-pcre=path`：
设置 PCRE 库的源码的路径。这个库在 ***[location](https://nginx.org/en/docs/http/ngx_http_core_module.html?&_ga=2.225233945.2064822644.1493181926-708921149.1492677721#location)*** 指令和 ***[ngx_http_rewrite_module](https://nginx.org/en/docs/http/ngx_http_rewrite_module.html?_ga=2.225233945.2064822644.1493181926-708921149.1492677721)*** 模块中被用于支持正则表达式。

`–with-pcre-jit`：
使用 “just-in-time compilation” 支持（***[pcre_jit](https://nginx.org/en/docs/ngx_core_module.html?&_ga=2.225233945.2064822644.1493181926-708921149.1492677721#pcre_jit)*** 指令）来构建 PCRE 库。

`–with-zlib=path`：
设置 zlib 库的源码的路径。这个库被用于 ***[ngx_http_gzip_module](https://nginx.org/en/docs/http/ngx_http_gzip_module.html?_ga=2.252710794.2064822644.1493181926-708921149.1492677721)*** 模块中。

#### 配置 NGINX GCC 选项
在配置脚本中你也可以指定编译器关联选项：
`–with-cc-opt=parameters`：
设置添加到 CFLAGS 变量中的附加参数。在 FreeBSD 系统下，当使用系统 PCRE 库的时候，`–with-cc-opt=-I/usr/local/include` 必须被指定。

如果被select支持的文件数量需要增加，那么也可以像这下面这样指定：`–with-cc-opt=-D/FD_SETSIZE=2048`。

`–with-ld-opt=parameters`：
设置将用于链接时的附加参数。当在 FreeBSD 下使用系统 PCRE 库时，`–with-cc-opt=-L/usr/local/lib` 必须被指定。

#### 指定 NGINX 连接处理方法
在配置脚本中，你可以重新定义基于事件的轮询方法。查看 ***[Connection Processing Methods](https://nginx.org/en/docs/events.html?_ga=2.221072283.2064822644.1493181926-708921149.1492677721)*** 了解更多内容。
`–with-select_module`,`–without-select_module`：
启用或禁用构建允许 NGINX 使用 select 方法工作的模块。如果平台没有明确支持想 kqueue,epoll,/dev/poll这样更加合适的方法，该模块将被自动构建。

`–with-poll_module`,`–without-poll-module`：
启用或禁用构建允许 NGINX 使用 poll() 方法工作的模块。如果该平台没有明确支持像 kqueue,epoll,/dev/poll 这样更加更是的方法，该模块将被自动构建。

#### NGINX 模块
模块的 NGINX 常量。模块的设置就如其他构建选项一样被配置在 `./configure` 脚本中。
有一些模块被自动构建——他们不需要在配置脚本中指定。然而，一些默认的模块可以被排除在 NGINX 二进制文件之外，通过在配置脚本中使用 `-without-` 配置选项。
模块默认不包含第三方模块，必须在配置脚本中使用其他的构建选项明确指定才行。这些模块可以被链接到 NGINX 二进制文件，以静态的方式在每次启动 NGINX 被加载，或者如果他们在配置文件中被指定则以动态的方式被加载。

#### 默认的模块构建

如果你不需要一个默认的构建模块，你可以通过使用 `–without-` 前缀的模块名来禁用它：
```shell
./configure --sbin-path=/usr/local/nginx/nginx --conf-path=/usr/local/nginx/nginx.conf --pid-path=/usr/local/nginx/nginx.pid --with-http_ssl_module --with-stream --with-pcre=../pcre-8.40 --with-zlib=../zlib-1.2.11 --without-http_empty_gif_module
```

| 模块名称                                     | 描述                                       |
| ---------------------------------------- | ---------------------------------------- |
| [***http_charset_module***](https://nginx.org/en/docs/http/ngx_http_charset_module.html?_ga=2.81192606.806275146.1493177927-708921149.1492677721) | 向 Content-Type 响应 header 域添加指定的字符集，能够覆盖数据从一种编码到另外一种。 |
| ***[http_gzip_module](https://nginx.org/en/docs/http/ngx_http_gzip_module.html?_ga=2.263596489.438601762.1493179575-708921149.1492677721)*** | 使用 gzip 方法压缩响应，有助于将传输的数据减少至少一半。          |
| ***[http_ssi_module](https://nginx.org/en/docs/http/ngx_http_ssi_module.html?_ga=2.258467593.2064822644.1493181926-708921149.1492677721)*** | 通过它在响应中处理 SSI (Server Side Includes) 命令。 |
| ***[http_userid_module](https://nginx.org/en/docs/http/ngx_http_userid_module.html?_ga=2.258467593.2064822644.1493181926-708921149.1492677721)*** | 为客户端鉴定设置 cookies 适配。                     |
| ***[http_access_module](https://nginx.org/en/docs/http/ngx_http_access_module.html?_ga=2.258467593.2064822644.1493181926-708921149.1492677721)*** | 限制对特定客户端地址的访问                            |
| ***[http_auth_basic_module](https://nginx.org/en/docs/http/ngx_http_auth_basic_module.html?_ga=2.258467593.2064822644.1493181926-708921149.1492677721)*** | 通过使用 HTTP Basic Authentication 协议验证用户名和密码来限制访问资源。 |
| ***[http_autoindex_module](https://nginx.org/en/docs/http/ngx_http_autoindex_module.html?_ga=2.195961647.2064822644.1493181926-708921149.1492677721)*** | 处理以斜线（/）结束的请求并产生一个目录列表。                  |
| ***[http_geo_module](https://nginx.org/en/docs/http/ngx_http_geo_module.html?_ga=2.195961647.2064822644.1493181926-708921149.1492677721)*** | 创建依赖客户端 IP 地址值的变量。                       |
| ***[http_map_module](https://nginx.org/en/docs/http/ngx_http_map_module.html?_ga=2.195961647.2064822644.1493181926-708921149.1492677721)*** | 创建依赖其他变量值的变量。                            |
| ***[http_split_clients_module](https://nginx.org/en/docs/http/ngx_http_split_clients_module.html?_ga=2.195961647.2064822644.1493181926-708921149.1492677721)*** | 创建适配 AB 测试的变量，也被称为分隔测试。                  |
| ***[http_referer_module](https://nginx.org/en/docs/http/ngx_http_referer_module.html?_ga=2.195961647.2064822644.1493181926-708921149.1492677721)*** | 如果请求的 header 域中的 Referer 使用了无效值，阻止其访问站点。 |
| ***[http_rewrite_module](https://nginx.org/en/docs/http/ngx_http_rewrite_module.html?_ga=2.65405741.2064822644.1493181926-708921149.1492677721)*** | 使用正则表达式改变请求的 URI 并重定向。有条件的选择。需要 PCRE 库支持。 |
| ***[http_proxy_module](https://nginx.org/en/docs/http/ngx_http_proxy_module.html?_ga=2.65405741.2064822644.1493181926-708921149.1492677721)*** | 传递请求到其他服务器。                              |
| ***[http_fastcgi_module](https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html?_ga=2.65405741.2064822644.1493181926-708921149.1492677721)*** | 传递请求到 FastCGI 服务器。                       |
| ***[http_uwsgi_module](https://nginx.org/en/docs/http/ngx_http_uwsgi_module.html?_ga=2.65405741.2064822644.1493181926-708921149.1492677721)*** | 传递请求到 uwsgi 服务器。                         |
| ***[http_scgi_module](https://nginx.org/en/docs/http/ngx_http_scgi_module.html?_ga=2.65405741.2064822644.1493181926-708921149.1492677721)*** | 传递请求到 SCGI 服务器。                          |
| ***[http_memcached_module](https://nginx.org/en/docs/http/ngx_http_memcached_module.html?_ga=2.65405741.2064822644.1493181926-708921149.1492677721)*** | 从 memcached 服务器中获取响应。                    |
| ***[http_limit_conn_module](https://nginx.org/en/docs/http/ngx_http_limit_conn_module.html?_ga=2.65405741.2064822644.1493181926-708921149.1492677721)*** | 限制每个定义的 key 的连接数量，特别是来自单一 IP 地址的连接数量。    |
| ***[http_limit_req_module](https://nginx.org/en/docs/http/ngx_http_limit_req_module.html?_ga=2.65405741.2064822644.1493181926-708921149.1492677721)*** | 限制每个定义的 key 的请求处理率，特别是来自单一 IP 地址的处理率。    |
| ***[http_empty_gif_module](https://nginx.org/en/docs/http/ngx_http_empty_gif_module.html?_ga=2.60746670.2064822644.1493181926-708921149.1492677721)*** | 发出单像素透明 GIF。                             |
| ***[http_browser_module](https://nginx.org/en/docs/http/ngx_http_browser_module.html?_ga=2.60746670.2064822644.1493181926-708921149.1492677721)*** | 创建依赖请求 header 域中的 “User-Agent” 值的变量。     |
| ***[http_upstream_hash_module](https://nginx.org/en/docs/http/ngx_http_upstream_module.html?&_ga=2.60746670.2064822644.1493181926-708921149.1492677721#hash)*** | 开启 hash 负载均衡方法。                          |
| ***[http_upstream_ip_hash_module](https://nginx.org/en/docs/http/ngx_http_upstream_module.html?&_ga=2.60746670.2064822644.1493181926-708921149.1492677721#ip_hash)*** | 开启 IP hash 负载均衡方法。                       |
| ***[http_upstream_least_conn_module](https://nginx.org/en/docs/http/ngx_http_upstream_module.html?&_ga=2.60746670.2064822644.1493181926-708921149.1492677721#least_conn)*** | 开启 least_conn 负载均衡方法。                    |
| ***[http_upstream_keepalive_module](https://nginx.org/en/docs/http/ngx_http_upstream_module.html?&_ga=2.60746670.2064822644.1493181926-708921149.1492677721#keepalive)*** | 开启持续连接。                                  |
| ***[http_upstream_zone_module](https://nginx.org/en/docs/http/ngx_http_upstream_module.html?&_ga=2.60746670.2064822644.1493181926-708921149.1492677721#zone)*** | 开启共享内存区。                                 |

#### 非默认构建的模块
一些 NGINX 模块**不是默认构建**的。你需要通过添加到 `./configure` 命令去手动启用他们。[mail](https://nginx.org/en/docs/mail/ngx_mail_core_module.html?_ga=2.225839129.2064822644.1493181926-708921149.1492677721),[stream](https://nginx.org/en/docs/stream/ngx_stream_core_module.html?_ga=2.225839129.2064822644.1493181926-708921149.1492677721),[geoip](https://nginx.org/en/docs/http/ngx_http_geoip_module.html?_ga=2.225839129.2064822644.1493181926-708921149.1492677721),[image_filter](https://nginx.org/en/docs/http/ngx_http_image_filter_module.html?_ga=2.225839129.2064822644.1493181926-708921149.1492677721),[perl](https://nginx.org/en/docs/http/ngx_http_perl_module.html?_ga=2.225839129.2064822644.1493181926-708921149.1492677721)和[xslt](https://nginx.org/en/docs/http/ngx_http_xslt_module.html?_ga=2.230180639.2064822644.1493181926-708921149.1492677721) 模块可以被动态编译。查看 ***[Dynamic Modules](https://www.nginx.com/resources/admin-guide/installing-nginx-open-source/#modules_dynamic)*** 来了解更多内容。

例如，`./configure` 命令包含了这些模块：
```shell
./configure --sbin-path=/usr/local/nginx/nginx --conf-path=/usr/local/nginx/nginx.conf --pid-path=/usr/local/nginx/nginx.pid --with-pcre=../pcre-8.40 --with-zlib=../zlib-1.2.11 --with-http_ssl_module --with-stream --with-mail
```


| 选项                                       | 说明                                       |
| ---------------------------------------- | ---------------------------------------- |
| --with-threads                           | 允许 NGINX 使用线程池。查看详情：*** [Thread Pools in NGINX Boost Performance 9x!](https://www.nginx.com/blog/thread-pools-boost-performance-9x/)*** |
| --with-file-aio                          | 启用异步 I/O。                                |
| --with-ipv6                              | 启用 IPv6 支持。                              |
| --with-http_ssl_module                   | 提供 HTTPS 支持。需要 SSL 库，如 ***[OpenSSL](https://www.openssl.org/)***。配置参考： ***[ngx_http_ssl_module](https://nginx.org/en/docs/http/ngx_http_ssl_module.html?_ga=2.115793734.1190757652.1493193149-708921149.1492677721)*** |
| --with-http_v2_module                    | 提供 HTTP/2 支持。配置参考：***[ngx_http_v2_module](https://nginx.org/en/docs/http/ngx_http_v2_module.html?_ga=2.69656016.1190757652.1493193149-708921149.1492677721)***，更多信息：***[HTTP/2 Module in NGINX](https://www.nginx.com/blog/http2-module-nginx/)*** |
| --with-http_realip_module                | 修改客户端地址为在指定 header 域中的发送地址。参考配置：***[ngx_http_realip_module](https://nginx.org/en/docs/http/ngx_http_realip_module.html?_ga=2.114613063.1190757652.1493193149-708921149.1492677721)*** |
| --with-http_addition_module              | 在响应的前后添加文本。配置参考：***[ngx_http_addition_module](https://nginx.org/en/docs/http/ngx_http_addition_module.html?_ga=2.114613063.1190757652.1493193149-708921149.1492677721)*** |
| --with-http_xslt_module 或 --with-http_xslt_module=dynamic | 使用一种或多种 XSLT 样式表来转换 XML 响应。该模块需要 [Libxml2](http://xmlsoft.org/) 和 [XSLT](http://xmlsoft.org/XSLT/) 库。配置参考：***[ngx_http_xslt_module](https://nginx.org/en/docs/http/ngx_http_xslt_module.html?_ga=2.107494082.1190757652.1493193149-708921149.1492677721)*** |
| --with-http_image_filter_module 或 --with-http_image_filter_module=dynamic | 将图片在 JPEG、GIF 和 PNG 中转换格式。该模块需要 LibGD 库。配置参考：***[ngx_http_image_filter_module](https://nginx.org/en/docs/http/ngx_http_image_filter_module.html?_ga=2.107494082.1190757652.1493193149-708921149.1492677721)*** |
| --with-http_geoip_module 或 --with-http_geoip_module=dynamic | 允许创建依赖客户端 IP 地址值的变量。该模块使用了 [MaxMind](http://www.maxmind.com/) GeoIP 数据库。配置参考：***[ngx_http_geoip_module](https://nginx.org/en/docs/http/ngx_http_geoip_module.html?_ga=2.114618951.1190757652.1493193149-708921149.1492677721)*** |
| --with-http_sub_module                   | 通过使用其他的字符串替换指定字符串修改响应。配置参考：***[ngx_http_sub_module](https://nginx.org/en/docs/http/ngx_http_sub_module.html?_ga=2.114618951.1190757652.1493193149-708921149.1492677721)*** |
| --with-http_dav_module                   | 用于通过 WebDAV 协议的文件管理自动化。配置参考：***[ngx_http_dav_module](https://nginx.org/en/docs/http/ngx_http_dav_module.html?_ga=2.114618951.1190757652.1493193149-708921149.1492677721)*** |
| --with-http_flv_module                   | 为 Flash Video (FLV) 文件提供伪流服务器端支持。配置参考：ngx ***[http_flv_module](https://nginx.org/en/docs/http/ngx_http_flv_module.html?_ga=2.114618951.1190757652.1493193149-708921149.1492677721)*** |
| --with-mp4_module                        | 为 MP4 文件提供伪流服务器端支持。配置参考：***[ngx_http_mp4_module](https://nginx.org/en/docs/http/ngx_http_mp4_module.html?_ga=2.114618951.1190757652.1493193149-708921149.1492677721)*** |
| --with-http_gunzip_module                | 使用 Content-Encoding 解压响应：gzip 用于不支持 zip 编码方法的客户端。配置参考：***[ngx_http_gunzip_module](https://nginx.org/en/docs/http/ngx_http_gunzip_module.html?_ga=2.177683941.1190757652.1493193149-708921149.1492677721)*** |
| --with-http_gzip_static_module           | 允许发送使用 `*.gz` 文件扩展名而不是常规的预压缩文件。配置参考：***[ngx_http_gzip_static_module](https://nginx.org/en/docs/http/ngx_http_gzip_static_module.html?_ga=2.177683941.1190757652.1493193149-708921149.1492677721)*** |
| --with-http_auth_request_module          | 基于子请求实施客户端授权。配置参考：***[http_auth_request_module](https://nginx.org/en/docs/http/ngx_http_auth_request_module.html?_ga=2.177683941.1190757652.1493193149-708921149.1492677721)*** |
| --with-http_random_index_module          | 处理使用斜杠 (/) 结尾的请求，并且从一个目录取出一个随机文件来作为首页。配置参考：***[ngx_http_random_index_module](https://nginx.org/en/docs/http/ngx_http_random_index_module.html?_ga=2.177683941.1190757652.1493193149-708921149.1492677721)*** |
| --with-http_secure_link_module           | 用于插件被请求链接的授权，保护资源不被未授权访问或者限制链接的生命周期。配置参考：***[ngx_http_secure_link_module](https://nginx.org/en/docs/http/ngx_http_secure_link_module.html?_ga=2.177683941.1190757652.1493193149-708921149.1492677721)*** |
| --with-http_slice_module                 | 允许将请求分隔为子请求，每个请求返回确定的响应范围。提供更多大型文件的有效缓存。查看 ngx_http_slice_module 相关的指令列表。配置参考：***[ngx_http_slice_module](https://nginx.org/en/docs/http/ngx_http_slice_module.html?_ga=2.177683941.1190757652.1493193149-708921149.1492677721)*** |
| --with-http_degradation_module           | 当内存超出默认值的时候，允许返回错误信息                     |
| --with-http_stub_status_module           | 提供访问基本状态信息。配置参考： ***[ngx_http_stub__status_module](https://nginx.org/en/docs/http/ngx_http_stub_status_module.html?_ga=2.207099347.1190757652.1493193149-708921149.1492677721)***。注意 NGINX Plus 用户不需要这个模块，因为已经为他们提供了扩展状态的面板。 |
| --with-http_perl_module 或 --with-http_perl_module=dynamic | 用于在 Perl 中实现位置和变量句柄，并且将 Perl 调用插入到 SSI 中。需要 [PERL](https://www.perl.org/get.html) 库。配置参考： ***[ngx_http_perl_module](https://nginx.org/en/docs/http/ngx_http_perl_module.html?_ga=2.207099347.1190757652.1493193149-708921149.1492677721)*** 。该模块也可以被动态编译。 |
| --with-mail 或 --with-mail=dynamic        | 启用邮件代理功能。配置参考：***[ngx_mail_core_module](https://nginx.org/en/docs/mail/ngx_mail_core_module.html?_ga=2.207099347.1190757652.1493193149-708921149.1492677721)*** 。该模块也可以被动态编译。 |
| --with-mail_ssl_module                   | 为使用 SSL/TLS 协议工作的邮件代理服务器提供支持。需要想 [OpenSSL](https://www.openssl.org/) 这样的 SSL 库。配置参考： ***[ngx_mail_ssl_module](https://nginx.org/en/docs/mail/ngx_mail_ssl_module.html?_ga=2.174071266.1190757652.1493193149-708921149.1492677721)*** |
| --with-stream 或 --with-stream=dynamic    | 开启 TCP 代理功能。配置参考： ***[ngx_stream_code_module](https://nginx.org/en/docs/stream/ngx_stream_core_module.html?_ga=2.174071266.1190757652.1493193149-708921149.1492677721) ***。该模块可以被动态编译。 |
| --with-google_perftools_module           | 允许使用 Google Performance 工具库。             |
| --with-cpp_test_module 或 --with-debug    | 开启***[调试日志](https://www.nginx.com/resources/admin-guide/debugging-nginx)***。 |

#### 第三方模块
你可以使用你自己的模块或者第三方模块扩展 NGINX 的功能通过编译 NGINX 源码。一些第三方模块被列举在 [https://nginx.com/resources/wiki/modules/](https://nginx.com/resources/wiki/modules/ ) 页面中。使用第三方模块的你将要承担稳定性无法保证的风险。

**静态链接模块**
被构建在 NGINX 源码中的大多数模块是被静态链接的：他们在编译的时候被构建在 NGINX 源码中，然后被静态的了链接到 NGINX 二进制文件中。这些模块只能在 NGINX 重新编译之后才能禁用。
要使用静态链接的第三方模块去编译 NGINX 源码，在配置脚本中要指定 `–add-module=option` 并且输入模块的路径：
```shell
$  ./configure ... --add-module=/usr/build/nginx-rtmp-module
```
**动态链接模块**
NGINX 模块也可以被编译为一个共享对象（*.so 文件），然后在运行时动态的加载到 NGINX 中。这样提供了更多的灵活性，作为模块可以在任何时候被加载或反加载通过在 NGINX 配置文件中使用 ***[load_module](https://nginx.org/en/docs/ngx_core_module.html?&_ga=2.111565380.1190757652.1493193149-708921149.1492677721#load_module)*** 指令指定。注意：这种模块必须支持动态链接。
要使用动态加载第三方模块编译 NGINX 源码，在配置脚本中要指定 `–add-dynamic-module=`配置选项和模块的路径。
```shell
$  ./configure ... --add-dynamic-module=/path/to/module
```
动态模块的结果文件 .so 在编译结束后在 `prefix/modules/` 目录中被找到，prefix 是保存服务器文件的目录，如：`/usr/local/nginx/modules`。要想加载动态模块，在 NGINX 安装完成后使用 ***[local_module](https://nginx.org/en/docs/ngx_core_module.html?&_ga=2.136254193.1190757652.1493193149-708921149.1492677721#load_module)*** 指令。
查看 ***[Introducing Dynamic Modules in NGINX 1.9.11](https://www.nginx.com/blog/dynamic-modules-nginx-1-9-11/)*** 和 ***[Extending NGINX](https://www.nginx.com/resources/wiki/extending/) ***来了解更多内容。

### 完成安装
```shell
./configure --prefix=/usr/local/nginx --with-pcre=../pcre-8.40 --with-zlib=../zlib-1.2.11 --with-http_stub_status_module --with-http_ssl_module
make && make install
```
到此NGINX已经安装完成，但是，此时直接敲`nginx`可能会显示没有找到命令，因为**还没有配置环境变量**：
```shell
touch /etc/profile.d/nginx.sh
echo "PATH=$PATH:/usr/local/nginx/sbin" >> /etc/profile.d/nginx.sh
echo "export PATH" >> /etc/profile.d/nginx.sh
source /etc/profile.d/nginx.sh
```
完成！查看NGINX:
```shell
nginx -v
```


## 预编译包安装
> 博主用的就是这种方式，**简单粗暴**！当然上面的方式也是过，但毕竟只是个业余的，手动一个个模块配置上去的话，小白表示搞不定。

### 添加源
```shell
echo "deb http://nginx.org/packages/ubuntu/ trusty nginx" >> /etc/apt/sources.list
echo "deb-src http://nginx.org/packages/ubuntu/ trusty nginx" >> /etc/apt/sources.list
```

### 更新并导入升级Key完成安装
```shell
wget http://nginx.org/keys/nginx_signing.key && apt-key add nginx_signing.key && apt-get update && apt-get upgrade && apt-get install openssl nginx
```

### 查看
```shell
nginx -V
```

# NGINX初学
## 校验，启动，停止和重新加载配置

```shell
# 校验
nginx -t 

# 停止、退出、重新加载配置、重启
nginx -s stop|quit|reload|reopen
```

也可以是这样：
```shell
kill -s QUIT 1888 #1888是nginx的PID
```
要获取全部正在运行中的 nginx 进程列表，可以使用 ps 工具，就像下面这样：
```shell
ps -ax | grep nginx
```
如果要了解更多的有关信号发送的信息，请查看***[控制nginx](http://nginx.org/en/docs/control.html)***。

## 配置文件的结构

nginx 由被配置文件指定的指令控制的模块组成。指令被分为简单指令和块指令。简单指令有名称和参数组成，通过空格来分隔开，以 `;` 号来结束。块指令拥有和简单指令一样的结构，但是不用 `;` 结束而是使用一组被 `{}` 环绕的额外指令。如果一个块指令在其内部包含了其他指令，则被称为上下文（context），比如：***[events](http://nginx.org/en/docs/ngx_core_module.html#events)***,***[http](http://nginx.org/en/docs/http/ngx_http_core_module.html#http)***,***[server](http://nginx.org/en/docs/http/ngx_http_core_module.html#server)*** 和***[location](http://nginx.org/en/docs/http/ngx_http_core_module.html#location)***。

被放置在配置文件中却不在任何上下文中的指令被认为是在主上下文之内的。`events` 和 `http` 指令就属于主上下文， `server` 在 `http` 之内，`location` 在 `server` 之内。

单行之中在 `#` 号之后的剩余内容被认为是注释。



## 静态内容服务

一个重要的 web 服务器任务就是提供文件（比如图片或者静态 HTML 页面）。你将会实现一个例子，依赖于 request 请求，文件将被从不同的本地目录（/data/www 和 /data/images）中提供。这需要编辑配置文件并在 `http` 块之内使用两个 `location` 块来设置一个 `server` 块。

首先，创建 `/data/www` 目录并且将一个名为 `index.html` 文件放进去，然后在创建一个 `/data/images` 目录并放置一些图片在里面。

接下来，打开配置文件。默认的配置文件已经包含了一些 `server` 块的例子，通常都被注释掉了。那么现在，注释掉全部块并且编写一个新的 `server`块吧：

```shell
http {
    server {
    }
}
```

通常地，配置文件可能包含了一些 `server` 块，通过***[监听](http://nginx.org/en/docs/http/ngx_http_core_module.html#listen)***端口和***[服务器名字](http://nginx.org/en/docs/http/server_names.html)***来***[区分](http://nginx.org/en/docs/http/request_processing.html)***。一旦 nginx 决定哪个服务处理请求，将会试着添加以下 `location` 块到 `server` 块中：

```shell
location / {
    root /data/www;
}
```

这个 `location` 块说明了 `/` 前缀和请求中的 URI 进行比较。对于匹配的请求，URI 将会被添加到被 [root](http://nginx.org/en/docs/http/ngx_http_core_module.html#root) 指令说明的路径中去，就是到 `/data/www` 中，形成一个在本地文件系统中的请求文件路径。如果有多个匹配了 `location` 的块，nginx 会**选择前缀最长的那个**。上面的那个 `location` 块是最短的前缀，长度只有 1，所以只有其他 `location` 块匹配都失败了，这个块才会被使用。

接下来，添加第二个 `location` 块：

```
location /images/ {
    root /data;
}
```

这将匹配以 `/images/` 开始的请求（location / 也会匹配这个请求，但他的前缀最短）。

最终 `server` 块的配置看起来是像下面这样的：

```
server {
    location / {
        root /data/www ;
    }

    location /iamges/ {
        root /data;
    }
}
```

配置一个监听标准 80 端口并且可在本机访问的服务器的工作就是这样了。在响应使用以 `/images/` 为开头的 URI 的请求中，服务器会从 `/data/images` 目录中中发送文件。例如，在响应 `http://localhost/images/example.png` 的请求中，nginx 会发送 `/data/images/exmaple.png` 文件。如果这个文件不存在，nginx 会发送一个  404 错误的响应。URI 不以 `/images/` 开头的请求将被映射到 `/data/www` 目录中。例如，在响应 `http://localhost/some/example.html` 的请求中，nginx 将发送 `/data/www/some/example.html` 文件。

要想应用新的配置，请启动 nginx（如果还没启动的话）或者发送 `reload` 信号到 nginx 主进程，通过执行如下命令：

```
nginx -s reload
```

> 本例中，有些不会像期望中的那样工作，你可以在 `access.log` 和 `error.log` 文件中尝试找到原因，这些文件的位置在 `/usr/local/nginx/logs` 或 `/var/log/nginx` 中。



## 设置一个简单的代理服务器

nginx 的一个频繁的用法是被设置作为代理服务器，这意味着接收请求的服务器，通过他们到被代理的服务器，再通过他们取回相应，并且通过他们发送给客户端。

下面我们来配置一个基本的代理服务器，来为本地图片请求提供服务并将其他请求转到被代理的服务器上。本例中，两个服务器将被定义在一个 nginx 实例中。

首先，通过增加一个 `server` 块到 nginx 配置文件的方式定义被代理的服务，配置内容如下：

```
server {
    listen 8080;
    root /data/up1;

    location / {
    }
}
```

这是一个监听 8080 端口并且映射全部请求到本地 `/data/up1` 目录的简单服务器。创建这个目录并放一个 `index.html` 在里面。注意， `root` 指令被放置在 `server` 上下文中，这样的 `root` 指令被用在当 `location` 块被选中提供服务的时候。

接下来，使用上一节的服务器配置并修改为一个代理服务器的配置。在第一 `location` 块中，放入使用由协议，名字以及被代理服务器的端口描述的参数的 `proxy_pass` 指令（在我们的例子中，就是 http://localhost:8080）：

```
server {
    localtion / {
        proxy_pass http://localhost:8080;
    }
    localtion /images/ {
        root /data;
    }
}
```

我们将修改第二个 `location` 块，它当前使用 `/images/` 前缀来映射请求到 `/data/images/` 下的文件，我们现在想要让他匹配一些典型的图片类型扩展名的请求。修改后的 `localtion` 块看起来像这样的：

```
localtion ~ \.(gif|jpg|png)$ {
    root /data/images;
}
```

参数是匹配了全部以 `.gif` `.jpg` `.png` 结尾的 URI 的正则表达式。一个正则表达式应被 `~` 开始。这样，相关的请求就会被映射到 `/data/images/` 目录中了。

当 nginx 选取一个 `localtion` 块来为请求提供服务的时候，首先要检查 `location` 指令说明的前缀，**记住最长前缀**的 `location`，**然后再检查正则表达式**。如果匹配了一个正则表达式，nginx 挑出这个 `localtion`，否则，它就会挑选之前被记录的。

代理服务器的配置结果看起来将会是下面这样：

```
server{
    location / {
        proxy_pass http://localhost:8080/;
    }
    localtion ~ \.(gif|jpg|png)$ {
        root /data/images;
    }
}
```

这个服务器将过滤以 `.gif` `.jpg` `.png` 结尾的请求，并映射他们到 `/data/images` 目录（通过添加 URI 到 `root` 指令的参数），还会传递其他请求到被之前配置的被代理服务器上。

要应用新配置，要像前面章节提到的发送 `reload` 信号给 nginx。

这里有***[更多](http://nginx.org/en/docs/http/ngx_http_proxy_module.html)***的可能更加有用的配置代理连接的指令。

## 快速查看配置文件的方法

nginx的配置放在nginx.conf文件中，一般我们可以使用以下命令查看服务器中存在的nginx.conf文件。

```
locate nginx.conf
/usr/local/etc/nginx/nginx.conf
/usr/local/etc/nginx/nginx.conf.default
...1234
```

如果服务器中存在多个nginx.conf文件，我们并不知道实际上调用的是哪个配置文件，因此我们**必须找到实际调用的配置文件**才能进行修改。 

## 查看NGINX实际调用的配置文件

### 1.查看NGINX路径

```
ps aux|grep nginx
root              352   0.0  0.0  2468624    924   ??  S    10:43上午   0:00.08 nginx: worker process  
root              232   0.0  0.0  2459408    532   ??  S    10:43上午   0:00.02 nginx: master process /usr/local/opt/nginx/bin/nginx -g daemon off;  
root             2345   0.0  0.0  2432772    640 s000  S+    1:01下午   0:00.00 grep nginx1234
```

NGINX的路径为：`/usr/local/opt/nginx/bin/nginx` 

### 2.查看NGINX配置文件路径

使用NGINX的 `-t` 参数进行配置检查，即可知道实际调用的配置文件路径及是否调用有效。

```
/usr/local/opt/nginx/bin/nginx -t
nginx: the configuration file /usr/local/etc/nginx/nginx.conf syntax is ok
nginx: configuration file /usr/local/etc/nginx/nginx.conf test is successful123
```

测试可知，NGINX的配置文件路径为：`/usr/local/etc/nginx/nginx.conf` 且调用有效。

## 拒绝或允许指定IP

NGINX拒绝或允许指定IP,是使用模块HTTP访问控制模块（HTTP Access）.
控制规则按照声明的顺序进行检查，首条匹配IP的访问规则将被启用。
如下例：

```
location / {
  deny    192.168.1.1;
  allow   192.168.1.0/24;
  allow   10.1.1.0/16;
  deny    all;
}
```

上面的例子中仅允许192.168.1.0/24和10.1.1.0/16网络段访问这个`location`字段，但192.168.1.1是个例外。
注意规则的匹配顺序，如果你使用过Apache你可能会认为你可以随意控制规则的顺序并且他们能够正常的工作，但实际上不行，下面的这个例子将拒绝掉所有的连接：

```
location / {
  #这里将永远输出403错误。
  deny all;
  #这些指令不会被启用，因为到达的连接在第一条已经被拒绝
  deny    192.168.1.1;
  allow   192.168.1.0/24;
  allow   10.1.1.0/1
}
```

# 最后

> 参考：
> ***[Installing NGINX Open Source](https://www.nginx.com/resources/admin-guide/installing-nginx-open-source/)***
> ***[Nginx 初学者指南](https://www.crazy-code.tech/index.php/2016/11/11/nginx-beginner-guide/)***

顺便写了个安装脚本：
***[源码版](https://github.com/masteranthoneyd/about-shell/blob/master/nginx-by-source.sh)***
***[预编译版](https://github.com/masteranthoneyd/about-shell/blob/master/nginx-by-pre-built-package.sh)***

人生在于折腾，这几天玩VPS有很大的收获，学会了一些以前不会的命令、写脚本、穿墙、Nginx等等，坚持折腾！
PS：链接换成加粗斜体，一个一个地找好累，于是又学会了正则表达式：`\[[\w\s]*\]\(https?://[a-z\.\?/_=0-9\s#&-]*\)`，一键替换～


