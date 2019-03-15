docker



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