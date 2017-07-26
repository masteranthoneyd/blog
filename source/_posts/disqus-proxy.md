---
title: NexT主题启用Disqus-Proxy 妈妈再也不用担心需要翻墙了
date: 2017-07-4 20:44:05
categories: Hexo
tags: [Hexo, Disqus-Proxy]
---
![](http://ojoba1c98.bkt.clouddn.com/img/disqus-proxy/disqus-proxy.png)

# Preface
> 多说于2017.06.01停止了服务，不得不选择其他的第三方评论服务，试了一下国内的服务发现不是麻烦（例如需要备案）就是不靠谱或者界面不炫酷（装X嫌疑...）
> 还是使用***[Disqus](https://disqus.com/)***吧...But，这个早就被***[GWF](https://baike.baidu.com/item/great%20firewall/4843556?fr=aladdin&fromid=18582731&fromtitle=GFW)***隔离了，虽然自己可以闪现过墙=.=，但游客不一定都会这个技能...
> 那么问题来了，怎么做一个公共的梯子实现人人翻墙？
> 在Gayhub全球最大同性交友网中发现，早就有大神做了这样一个服务，并选择了*[ciqulover](https://ycwalker.com/)*(在此感谢大神的鼎力相助)的***[Disque-Proxy](https://github.com/ciqulover/disqus-proxy)***项目作为梯子。
> 当然也还有其他的Disqus-Proxy -> ***[fooleap](https://github.com/fooleap/disqus-php-api)***、 ***[jiananshi](https://github.com/jiananshi/disqus-proxy)***

<!--more-->
# Flow
流程就没什么好说的了，如上图，在前端页面上测试 disqus 加载是否成功，如果成功则显示 disqus 的评论框，反之加载独立的评论框...
具体请看***[https://ycwalker.com/2017/06/01/about-diqus-proxy/](https://ycwalker.com/2017/06/01/about-diqus-proxy/)***

# Deploy Disqus-Proxy
首先你得有一台**可以访问[Disqus](https://disqus.com/)**的VPS[^1]... 博主用的是***[Linode](www.linode.com)***

## Node.js
后端采用了`Koa` 框架和 `async/await` 语法，`Node.js` 版本 `7.6` 以上。

![](http://ojoba1c98.bkt.clouddn.com/img/disqus-proxy/node-js-version.png)

## Clone Project
`cd`到想要安装的目录下，然后：
```bash
git clone https://github.com/ciqulover/disqus-proxy
```

## Dependency
要运行起来首先要安装依赖，`cd`到项目里面执行：
```bash
npm i --production
// 或者
yarn install --production
```

## Configuration
配置 `server` 目录下的`config.js`：
```json
module.exports = {
  // 服务端端口，需要与 disqus-proxy 前端设置一致
  port: 5509,
  // 你的 diqus secret key
  api_secret: 'your secret key',
  // 你的 disqus 名称
  username:'ciqu',
  // 服务端 socks5 代理转发，便于在本地测试，生产环境通常为 null
  socks5Proxy: null,
  // 日志输出位置, 输出到文件或控制台 'file' | 'console'
  log: 'console'
}
```

## Get Api-secret 
`api-secret` 需要你在 ***[Disqus Api](https://disqus.com/api/applications/)*** 的官方网站上开启 **API** 权限，申请成功后会得到这个秘钥。
![](http://ojoba1c98.bkt.clouddn.com/img/disqus-proxy/disqus-api-applcation.png)

并且需要在后台的 `Settings` => `Community` 里开启访客评论：
![](http://ojoba1c98.bkt.clouddn.com/img/disqus-proxy/disqus-admin-setting.png)

## Start Up
使用 `pm2` 启动：
```bash
cd server
npm i pm2 -g
pm2 start index.js
```
如果你在配置文件中选择 `log` 类型为`file`, 那么输出的日志文件将在默认为 server 目录下的`disqus-proxy.log`

使用`netstat`查看项目监听情况：

```bash
netstat -nutpl
```

![](http://ojoba1c98.bkt.clouddn.com/img/disqus-proxy/disqus-proxy-startup.png)

那么后端的工作就完成了～

# Summary






[^1]: 虚拟专用服务器(Virtual private server)