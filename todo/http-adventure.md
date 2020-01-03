# Adventure

> 一个请求从发起到服务器背后经历了什么

# DNS 解析

* 什么是 DNS 解析? DNS 全称 Domain Name System, 翻译为域名系统, DNS 解析指的就是通过查询域名系统, 得到域名对应的 IP.

* 为什么会有 DNS 解析? 互联网上每一台计算机的唯一标识是它的 IP 地址, 但是 IP 地址并不方便记忆, 所以使用容易记忆的域名作为一个映射. 类比来说就是城市名与邮政的内部编码, 别人问你哪个城市, 说广州别人一下就记住了, 说编码谁懂. 再比如别人问你在那条街, 总不能跟别人说经纬度吧...

![](https://cdn.yangbingdong.com/img/http-adventure/dns-resolve.png)

## DNS 优化

**DNS 缓存**:

由于每次查询 DNS 经过以上步骤比较耗时, 那如何优化? 那就是缓存.

DNS存在着多级缓存, 从离浏览器的距离排序的话, 有以下几种: 

浏览器缓存 -> *[系统缓存](https://en.wikipedia.org/wiki/Hosts_%28file%29#Location_in_the_file_system)* -> 路由器缓存 -> IPS服务器缓存 -> 根域名服务器缓存 -> 顶级域名服务器缓存 -> 主域名服务器缓存

**DNS 负载均衡**:

真实的互联网世界背后存在成千上百台服务器, 大型的网站甚至更多. 但是在用户的眼中, 它需要的只是处理他的请求, 哪台机器处理请求并不重要. DNS 可以返回一个合适的机器的 IP 给用户, 例如可以根据每台机器的负载量, 该机器离用户地理位置的距离等等, 这种过程就是 DNS 负载均衡, 又叫做 DNS 重定向. 大家耳熟能详的 CDN(Content Delivery Network) 就是利用 DNS 的重定向技术, DNS 服务器会返回一个跟用户最接近的点的 IP 地址给用户.

# ARP

> *[wiki: 地址解析协议](https://zh.wikipedia.org/wiki/地址解析协议)*

在 *[以太网](https://zh.wikipedia.org/wiki/以太网)* 协议中规定, 同一局域网中的一台主机要和另一台主机进行直接通信, 必须要知道目标主机的MAC地址. 而在 *[TCP/IP](https://zh.wikipedia.org/wiki/TCP/IP协议族)* 协议中, 网络层和传输层只关心目标主机的IP地址. 这就导致在以太网中使用IP协议时, 数据链路层的以太网协议接到上层IP协议提供的数据中, 只包含目的主机的IP地址. 于是需要一种方法, 根据目的主机的IP地址, 获得其 *[MAC地址](https://zh.wikipedia.org/wiki/MAC地址)*. 这就是ARP协议要做的事情. 所谓**地址解析(address resolution)**就是主机在发送帧前将目标IP地址转换成目标MAC地址的过程. 

另外, 当发送主机和目的主机不在同一个 *[局域网](https://zh.wikipedia.org/wiki/局域网)* 中时, 即便知道对方的MAC地址, 两者也不能直接通信, 必须经过 *[路由](https://zh.wikipedia.org/wiki/路由)* 转发才可以. 所以此时, 发送主机通过ARP协议获得的将不是目的主机的真实MAC地址, 而是一台可以通往局域网外的路由器的MAC地址. 于是此后发送主机发往目的主机的所有帧, 都将发往该路由器, 通过它向外发送. 这种情况称为委托ARP或**ARP代理(ARP Proxy)**. 

在 *[点对点链路](https://zh.wikipedia.org/wiki/点对点协议)* 中不使用ARP, 实际上在点对点网络中也不使用MAC地址, 因为在此类网络中分别已经获取了对端的IP地址. 

# TCP连接

TCP 3次握手, 建立连接.

![](https://cdn.yangbingdong.com/img/http-adventure/tcp-sync.webp)

老阿姨: 在家吗? 想去拜访您.

对方: 在的, 欢迎啊.

老阿姨: 马上到.

# HTTP请求

> HyperText Transfer Protocol

浏览器构建 HTTP 请求报文并通过 TCP 协议中发送到服务器指定端口(HTTP协议80/8080, HTTPS协议443). HTTP请求报文是由三部分组成: **请求行**, **请求头部**和**请求数据**。

![](https://cdn.yangbingdong.com/img/http-adventure/request-message-structure.webp)

![](https://cdn.yangbingdong.com/img/http-adventure/request-message-example.webp)

![](https://cdn.yangbingdong.com/img/http-adventure/tcp-transport-stream.webp)

应用层: 客户端发送HTTP请求报文

传输层: 切分长数据, 并确保可靠性

网络层: 进行路由

数据链路层: 传输数据

物理层: 物理传输bit

![](https://cdn.yangbingdong.com/img/http-adventure/tcp-and-osi.webp)

# Wireshark 抓包演示

![](https://cdn.yangbingdong.com/img/http-adventure/wireshark.png)

# HTTPS

***[HTTPS 虐我千百遍，我却待她如初恋！](https://mp.weixin.qq.com/s/kGujnr76eawyVaWWjBs6PA)***

> 以上过程只是冰山一角, 每一个节点单独拿出来放大都是别有洞天.