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
> 那么问题来了，怎么做一个公共的梯子实现人人翻墙呢？
> 在Gayhub全球最大同性交友网中发现，早就有大神做了这样一个服务，并选择了[ciqulover](https://ycwalker.com/)(在此感谢大神的鼎力帮助)的***[Disque-Proxy](https://github.com/ciqulover/disqus-proxy)***项目作为梯子。
> 当然也还有其他的Disqus-Proxy -> ***[fooleap](https://github.com/fooleap/disqus-php-api)***、 ***[jiananshi](https://github.com/jiananshi/disqus-proxy)***

<!--more-->
# Flow
流程就没什么好说的了，如上图，在前端页面上测试 disqus 加载是否成功，如果成功则显示 disqus 的评论框，反之加载独立的评论框...
具体请看***[https://ycwalker.com/2017/06/01/about-diqus-proxy/](https://ycwalker.com/2017/06/01/about-diqus-proxy/)***

# Deploy Disqus-Proxy
首先你得有一台**可以访问[disqus](https://disqus.com/)**的vps...博主用的是[linode](www.linode.com)





