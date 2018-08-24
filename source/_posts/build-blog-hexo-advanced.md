---
title: 基于Hexo搭建个人博客——进阶篇(从入门到入土)
date: 2017-02-21 23:07:34
categories: Hexo
tags: [Hexo, Node.js, Github, Coding, Git]
---
![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/next.png)
# 前言
好久没更新了，因为懒- -
前面介绍了Hexo的一些基本搭建→***[基于Hexo+github+coding搭建个人博客——基础篇(从菜鸟到放弃)](/2017/build-blog-hexo-base/)***
对于追求装X的博主来说，基本的搭建是满足不了的，接下来整理了一下各方面的细节优化，包括页面字体大小、配色、背景、SEO(搜索引擎优化)、域名绑定、DNS域名解析实现负载均衡等。
关于`NexT`主题的很多配置、插件都可以在***[官方文档](theme-next.iissnan.com/getting-started.html)***找到答案，那么博主只是整理了一些官方没怎么提及的细节优化。

<!--more-->

# 解决Hexo命令fs.SyncWriteStream问题

请看***[解决Hexo命令fs.SyncWriteStream问题](/2017/build-blog-hexo-base/#解决Hexo命令fs-SyncWriteStream问题)***

# 高度定制优化篇
## 集成Mod分享组件
![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/share-mod.png)

Step1、获取 AppKey
在 *[Mob](http://www.mob.com/)* 注册账号后，点击头像进入后台，选择 `shareSDK` 添加一个 `Web应用`：

![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/mod-share.png)

Step2、在**主题配置文件**中添加配置：
```
mob_share:
  enable: true
  appkey: ********
```

Step3、在`next/layout/_partials/share/`里面添加`mob_share.swig`：
```
<!--MOB SHARE BEGIN-->
<div class="-hoofoo-share-title">分享到：</div>
<div class="-hoofoo-share-buttons">
    <div class="-mob-share-weibo -hoofoo-share-weibo -hoofoo-share-ui-button"><i class="fa fa-weibo" aria-hidden="true"></i></div>
    <div class="-mob-share-weixin -hoofoo-share-weixin -hoofoo-share-ui-button"><i class="fa fa-weixin" aria-hidden="true"></i></div>
    <div class="-mob-share-qq -hoofoo-share-qq -hoofoo-share-ui-button"><i class="fa fa-qq" aria-hidden="true"></i></div>
    <div class="-mob-share-twitter -hoofoo-share-twitter -hoofoo-share-ui-button"><i class="fa fa-twitter" aria-hidden="true"></i></div>
    <div class="-hoofoo-share-more -hoofoo-share-ui-button -mob-share-open"><i class="fa fa-ellipsis-h" aria-hidden="true"></i></div>
</div>
<div class="-mob-share-ui" style="display: none">
    <ul class="-mob-share-list">
        <li class="-mob-share-weibo"><p>新浪微博</p></li>
        <li class="-mob-share-weixin"><p>微信</p></li>
        <li class="-mob-share-qzone"><p>QQ空间</p></li>
        <li class="-mob-share-qq"><p>QQ好友</p></li>
        <li class="-mob-share-tencentweibo"><p>腾讯微博</p></li>
        <li class="-mob-share-renren"><p>人人网</p></li>
        <li class="-mob-share-kaixin"><p>开心网</p></li>
        <li class="-mob-share-douban"><p>豆瓣</p></li>
        <li class="-mob-share-youdao"><p>有道云笔记</p></li>
        <li class="-mob-share-mingdao"><p>明道</p></li>
        <li class="-mob-share-pengyou"><p>朋友网</p></li>
        <li class="-mob-share-facebook"><p>Facebook</p></li>
        <li class="-mob-share-twitter"><p>Twitter</p></li>
        <li class="-mob-share-pocket"><p>Pocket</p></li>
        <li class="-mob-share-google"><p>Google+</p></li>
        <li class="-mob-share-tumblr"><p>Tumblr</p></li>
        <li class="-mob-share-instapaper"><p>Instapaper</p></li>
        <li class="-mob-share-linkedin"><p>Linkedin</p></li>
    </ul>
    <div class="-mob-share-close">取消</div>
</div>
<div class="-mob-share-ui-bg"></div>
<script id="-mob-share" src="http://f1.webshare.mob.com/code/mob-share.js?appkey={{theme.mob_share.appkey}}"></script>
<!--MOB SHARE END-->
```

Step4、在`next/layout/post.swig`中添加条件分支：
```
{% if theme.jiathis %}
      {% include '_partials/share/jiathis.swig' %}
    {% elseif theme.baidushare %}
      {% include '_partials/share/baidushare.swig' %}
    {% elseif theme.add_this_id %}
      {% include '_partials/share/add-this.swig' %}
    {% elseif theme.duoshuo_shortname and theme.duoshuo_share %}
      {% include '_partials/share/duoshuo_share.swig' %}
    {% elseif theme.mob_share.enable %}
      {% include '_partials/share/mob_share.swig' %}
{% endif %}
```

Step5、在`next/source/css/_common/components/third-party/`里添加样式文件`mob_share.styl`：
```
.-hoofoo-share-buttons{
    display: inline-block;
}
.-hoofoo-share-title{
    font-size: 1.1em;
    font-weight: 200;
}
.-hoofoo-share-ui-button{
    cursor: pointer;
    background-color: #555;
    color: #fff;
    font-size: 24px;
    line-height: 40px;
    width: 40px;
    height: 40px;
    margin: 10px;
    border-radius: 25px;
    float: left;
    transition: background 0.4s;
    -moz-transition: background 0.4s;    /* Firefox 4 */
    -webkit-transition: background 0.4s;    /* Safari 和 Chrome */
    -o-transition: background 0.4s;
}
.-hoofoo-share-weibo:hover{
    background-color: #cf3f41;
}
.-hoofoo-share-weixin:hover{
    background-color: #18a01a;
}
.-hoofoo-share-qq:hover{
    background-color: #950c0c;
}
.-hoofoo-share-twitter:hover{
    background-color: #2ab3e6;
}
.-hoofoo-share-more:hover{
    background-color: #777;
}
.-mob-share-weixin-qrcode-content{
    border-radius: 4px;
    -webkit-box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
    -moz-box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
    -o-box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
}
.-mob-share-weixin-qrcode{
    margin: 5% !important;
    width: 90% !important;
    height: auto !important;
}
.-mob-share-weixin-qrcode-close {
    background-image: url('/lib/fancybox/source/fancybox_sprite.png') !important;//因为兼容问题把vendor改成了lib，根据自己的路径修改
}
.-mob-share-weixin-qrcode-close {
    overflow: hidden;
    line-height: 100px !important;
    position: absolute !important;
    top: -18px !important;
    right: -18px !important;
    width: 36px !important;
    height: 36px !important;
    cursor: pointer !important;
    z-index: 8040 !important;
}
/*Retina graphics!*/
@media only screen and (-webkit-min-device-pixel-ratio: 1.5),
       only screen and (min--moz-device-pixel-ratio: 1.5),
       only screen and (min-device-pixel-ratio: 1.5){
    .-mob-share-weixin-qrcode-close {
        background-image: url('/lib/fancybox/source/fancybox_sprite@2x.png') !important;//因为兼容问题把vendor改成了lib，根据自己的路径修改
        background-size: 44px 152px !important; /*The size of the normal image, half the size of the hi-res image*/
    }
}
.-mob-share-close{
    height: 4em !important;
    font-size: 0.8em !important;
    line-height: 4em !important;
    background: #555 !important;
    color: #fff !important;
}
```

Step6、同一目录下的 `third-party.styl` 中添加：
```
@import "mob_share";
```

Step7、在`next/layout/_scripts/third-party/`里添加脚本文件`mob_share.swig`：

```
{% if theme.mob_share.enable %}
<script type="text/javascript">
    //微信二维码点击背景关闭
    $('body').delegate('.-mob-share-weixin-qrcode-bg','click', function(){
         $(".-mob-share-weixin-qrcode-close").trigger("click");
    }); 
</script>
{% endif %}
```

Step8、在`next/layout/_layout.swig`的`body`标签结束前添加：
```
{% include '_scripts/third-party/mob_share.swig' %}
```

## 添加顶部加载条
打开`/themes/next/layout/_partials/head.swig`文件，添加如下代码：
```
<script src="//cdn.bootcss.com/pace/1.0.2/pace.min.js"></script>
<link href="//cdn.bootcss.com/pace/1.0.2/themes/pink/pace-theme-flash.css" rel="stylesheet">
```
但是，默认的是粉色的，要改变颜色可以在`/themes/next/layout/_partials/head.swig`文件中添加如下代码（接在刚才link的后面）
```
<style>
    .pace .pace-progress {
        background: #ff009e; /*进度条颜色*/
        height: 3px;
    }
    .pace .pace-progress-inner {
         box-shadow: 0 0 10px #ff009e, 0 0 5px #ff009e; /*阴影颜色*/
    }
    .pace .pace-activity {
        border-top-color: #ff009e;    /*上边框颜色*/
        border-left-color: #ff009e;    /*左边框颜色*/
    }
</style>
```

## 文章加密访问
打开`themes->next->layout->_partials->head.swig`文件,插入这样一段代码：
```
<script>
    (function(){
        if('{{ page.password }}'){
            if (prompt('请输入文章密码') !== '{{ page.password }}'){
                alert('密码错误！');
                history.back();
            }
        }
    })();
</script>

```
然后在文章上写成类似这样：
```
---
title: Hello World
date: 2016/7/13 20:46:25
categories:
- Diary
tags:
  - Testing
  - Another Tag
password: 123456
---
```

## 博客更换Disqus评论
由于多说即将关闭，本站启用Disqus。
既然Disqus已被墙，那么为了对没有梯子的同学标示友好，我们可以选择点击加载Disqus评论的方式，这个问题貌似也得到了主题作者的关注-> ***(NexT5.2.0)[https://github.com/iissnan/hexo-theme-next/milestone/7]***
具体做法如下：
打开`themes/next/layout/_partials/comments.swig`，在文件内容 `<div id="disqus_thread">`前面加入下面内容：
```
<div style="text-align:center;">
  <button class="btn" id="load-disqus" onclick="disqus.load();">加载 Disqus 评论</button>
</div>
```
再打开`themes/next/layout/_scripts/third-party/comments/disqus.swig`，需要替换原本的 Disqus 的加载的内容，如果希望显示评论数量，就保留 run_disqus_script('count.js') 这一行，这样页面载入时还会加载 disqus 的资源：
```
run_disqus_script('count.js');
{% if page.comments %}
  run_disqus_script('embed.js');
{% endif %}
```
替换为下面的内容：
```javascript
var disqus = {
  load : function disqus(){
      if(typeof DISQUS !== 'object') {
        (function () {
        var s = document.createElement('script'); s.async = true;
        s.type = 'text/javascript';
        s.src = '//' + disqus_shortname + '.disqus.com/embed.js';
        (document.getElementsByTagName('HEAD')[0] || document.getElementsByTagName('BODY')[0]).appendChild(s);
        }());
        $('#load-disqus').html("评论加载中，请确保你有梯子，若评论长时间未加载则你可能翻墙失败...").fadeOut(9000); //加载后移除按钮
      }
  }
}
```
前面的 `function run_disqus_script(disqus_script){} `这一段，不打算显示评论数量的话，可以一起删掉，不显示评论数量的话，那么点击加载按钮之前，网页是不会加载来自 Disqus 的资源的。

## NexT启用Disqus-Proxy 不翻墙也能使用Disqus

![](http://ojoba1c98.bkt.clouddn.com/img/disqus-proxy/disqus-proxy.png)

> 多说于2017.06.01停止了服务，不得不选择其他的第三方评论服务，试了一下国内的服务发现不是麻烦（例如需要备案）就是不靠谱或者界面不炫酷（装X嫌疑...）
>
> 还是使用***[Disqus](https://disqus.com/)***吧...But，这个早就被***[GWF](https://baike.baidu.com/item/great%20firewall/4843556?fr=aladdin&fromid=18582731&fromtitle=GFW)***隔离了，虽然自己可以闪现过墙=.=，但游客不一定都会这个技能...
> 那么问题来了，怎么做一个公共的梯子实现人人翻墙？
> 在Gayhub全球最大同性交友网中发现，早就有大神做了这样一个服务，并选择了*[ciqulover](https://ycwalker.com/)*(在此感谢大神的鼎力相助)的***[Disque-Proxy](https://github.com/ciqulover/disqus-proxy)***项目作为梯子。
> 当然也还有其他的Disqus-Proxy -> ***[fooleap](https://github.com/fooleap/disqus-php-api)***、 ***[jiananshi](https://github.com/jiananshi/disqus-proxy)***

### Flow
流程就没什么好说的了，如上图，在前端页面上测试 disqus 加载是否成功，如果成功则显示 disqus 的评论框，反之加载独立的评论框...
具体请看***[https://ycwalker.com/2017/06/01/about-diqus-proxy/](https://ycwalker.com/2017/06/01/about-diqus-proxy/)***

### Get Api-secret 
`api-secret` 需要你在 ***[Disqus Api](https://disqus.com/api/applications/)*** 的官方网站上开启 **API** 权限，申请成功后会得到这个秘钥。
![](http://ojoba1c98.bkt.clouddn.com/img/disqus-proxy/disqus-api-applcation.png)

并且需要在后台的 `Settings` => `Community` 里开启访客评论：
![](http://ojoba1c98.bkt.clouddn.com/img/disqus-proxy/disqus-admin-setting.png)

### Deploy Disqus-Proxy

首先你得有一台**可以访问[Disqus](https://disqus.com/)**的VPS[^1]... 博主用的是***[Linode](www.linode.com)***

Docker方式启动：

```
docker run -d --name disqus-proxy --restart=always -p 5509:5509 \
-e API_SECRECT=your_serect \
-e SHORT_NAME=your_short_name \
ycwalker/disqus-proxy-server 
```

更多方式请移步到 ***[https://github.com/ciqulover/disqus-proxy-server](https://github.com/ciqulover/disqus-proxy-server)***

### NexT Configuration

#### Copy Static File
将`disqus-proxy`项目中`/build/static`文件复制到博客`../next/source/`下。
`static`文件中应该包含`main.0d0338ae.js`和`main.0603c539.css`。

#### _config.yml
在**主题配置文件**中添加：
```yaml
disqus_proxy:
  enable: true
  # 如果 disqus 账号名没设置 那么 disqus_proxy 也不会生效
  username: ookamiantd
  # 下面两项你需要更改为自己服务器的域名和端口
  server: disqus-proxy.yangbingdong.com 
  port: 5509  # 端口号需要与后端设置一致
  # 头像路径设置
  defaultAvatar: /images/avatar/avatar-default.jpg
  adminAvatar: /images/avatar/avatar-admin.jpg
  # 脚本和 css 路径
  js: /static/js/main.0d0338ae.js
  css: /static/css/main.0603c539.css
```

#### comment.swig

修改`/next/layout/_partial/comment.swig`，在最后一个`</div>`钱加上：

```javascript
<div id="disqus_proxy_thread"></div>
      <div id="disqus_thread"></div>
      {% if theme.disqus_proxy.enable %}
          <script type="text/javascript">
              window.disqusProxy = {
                username: '{{ theme.disqus_proxy.username }}',
                server: '{{ theme.disqus_proxy.server }}',
                port: '{{ theme.disqus_proxy.port }}',
                defaultAvatar: '{{ theme.disqus_proxy.defaultAvatar }}',
                adminAvatar: '{{ theme.disqus_proxy.adminAvatar }}',
                identifier: '{{ page.path }}'
              };
              window.disqus_config = function () {
                this.page.url = '{{ page.permalink }}';
                this.page.identifier = '{{ page.path }}';
              };
              window.onload=function(){
                var s = document.createElement('script');
                s.src = "{{ theme.disqus_proxy.js }}";
                s.async = true;
                document.body.appendChild(s);
              }
          </script>
          <link rel="stylesheet" href="{{ theme.disqus_proxy.css }}">
      {% endif %}
```


渲染效果：
```html
<div id="disqus_proxy_thread"></div>
<div id="disqus_thread"></div>
<script type="text/javascript">
  window.disqusProxy = {
    username: 'ookamiantd',
    server: 'disqus-proxy.yangbingdong.com',
    port: '5509',
    defaultAvatar: '/images/avatar/avatar-default.jpg',
    adminAvatar: '/images/avatar/avatar-admin.jpg',
    identifier: '2017/disqus-proxy/'
  };
  window.disqus_config = function () {
    this.page.url = 'http://ookamiantd.top/2017/disqus-proxy/';
    this.page.identifier = '2017/disqus-proxy/';
  };
  window.onload = function () {
    var s = document.createElement('script');
    s.src = "/static/js/main.0d0338ae.js";
    s.async = true;
    document.body.appendChild(s);
  }
</script>
<link rel="stylesheet" href="/static/css/main.0603c539.css">
```

#### custom.styl

可能由于改过样式还是本来就不兼容，评论框一开始显示不出来，*[ciqulover](https://ycwalker.com/)*大神帮我加了个样式之后就好了。

在`/next/source/css/_custom/custom.styl`中添加：
```css
#disqus_proxy_thread .post{
  opacity: 1 !important;
  box-shadow: none !important;
  -webkit-box-shadow: none !important;
}
```
博主也对评论框乱入了一些样式例如头像旋转...具体请看***[main.0603c539.css](/static/css/main.0603c539.css)***

### Problem
博主使用了`hexo-all-minifier`进行静态文件压缩，不明原因导致那两个评论框的js和css压缩之后会报错，所以对压缩选项作设置，在**站点配置文件**中添加：
```yaml
html_minifier:
  enable: true
  exclude: 

css_minifier:
  enable: true
  exclude: 
    - '/home/ybd/GitRepo/blog/themes/next/source/static/css/main.0603c539.css'

js_minifier:
  enable: true
  mangle: true
  output:
  compress:
  exclude: 
    - '/home/ybd/GitRepo/blog/themes/next/source/static/js/*.*.js'

image_minifier:
  enable: true
  interlaced: false
  multipass: false
  optimizationLevel: 2
  pngquant: false
  progressive: false
```

### Show

这是翻墙状态：
![](http://ojoba1c98.bkt.clouddn.com/img/disqus-proxy/comment02.png)
这是`disqus_proxy`：
![](http://ojoba1c98.bkt.clouddn.com/img/disqus-proxy/comment01.png)

## 修改文章页宽

打开`themes/next/source/css/_variables/base.styl`，找到以下字段并修改为合适的宽度：
```
$content-desktop-large = 1000px
```
## 修改小型代码块颜色
修改`\themes\next\source\css\ _variables\base.styl`文件，加入自定义颜色：
```
$black-deep   = #222
$red          = #ff2a2a
$blue-bright  = #87daff
$blue         = #0684bd
$blue-deep    = #262a30
$orange       = #fc6423
// 下面是我自定义的颜色
$my-code-foreground = #dd0055  // 用``围出的代码块字体颜色
$my-code-background = #eee  // 用``围出的代码块背景颜色
```

修改`$code-background`和`$code-foreground`的值：
```
// Code & Code Blocks // 用``围出的代码块 // -------------------------------------------------- 
$code-font-family               = $font-family-monospace 
$code-font-size                 = 15px 
$code-background                = $my-code-background 
$code-foreground                = $my-code-foreground 
$code-border-radius             = 4px
```
## 文章末尾追加版权信息
找到`themes/next/layout/_macro/post.swig`，在`footer`之前添加如下代码(添加之前确保已添加***[样式](#%E5%A5%BD%E7%8E%A9%E7%9A%84%E6%A0%B7%E5%BC%8F)***)：
```
<div>
	    <p id="div-border-left-red">
	   <b>本文基于<a target="_blank" title="Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)" href="http://creativecommons.org/licenses/by-sa/4.0/"> 知识共享署名-相同方式共享 4.0 </a>国际许可协议发布</b><br/>
	    <span>
	    <b>本文地址：</b><a href="{{ url_for(page.path) }}" title="{{ page.title }}">{{ page.permalink }}</a><br/><b>转载请注明出处，谢谢！</b>
	    </span>
	    </p>
</div>
```

## 添加文章结束标记
同样在`themes/next/layout/_macro/post.swig`中，在`wechat-subscriber.swig`之前添加如下代码：
```
<div style="text-align:center;color: #ccc;font-size:14px;">---------------- The End ----------------</div>
```

## 添加热度
在`/themes/hexo-theme-next/layout/_macro/post.swig`里面的下面的位置加上如下代码：
```
{% if post.categories and post.categories.length %}
        <span class="post-category" >
        </span>
      {% endif %}

 <!-- 在下面的位置加上如下代码 -->
      <span id="busuanzi_container_page_pv">
      &nbsp; | &nbsp; 热度&nbsp; <span id="busuanzi_value_page_pv"></span>°C
      </span>
  <!-- 在上面的位置加上如上代码 -->    
  
      {% if post.comments %}
        {% if (theme.duoshuo and theme.duoshuo.shortname) or theme.duoshuo_shortname %}
          <span class="post-comments-count">
            &nbsp; | &nbsp;
            <a href="{{ url_for(post.path) }}#comments" itemprop="discussionUrl">
              <span class="post-comments-count ds-thread-count" data-thread-key="{{ post.path }}" itemprop="commentsCount"></span>
            </a>
          </span>    
```

但是这有一个**缺陷**。就是我们会发现在主页时显示的热度和进入博客后的热度不一样，那是因为在主页时他显示的是主页这个页面的阅读量，而不是博客的阅读量，所以我们需要改变一些：

我们在`/themes/hexo-theme-next/layout/_macro/`目录下新建`post-article.swig`,把这些`post.swig`中的内容复制过去，而且加上上面的统计代码，然后在`/themes/hexo-theme-next/layout/post.swig`上面`% import '_macro/post.swig' as post_template %`中的`post.swig`改成`post-article.swig`，这样子就解决啦。就是在主页上的博客名字下面不会有阅读人数，进入博客才能看见

## 添加Fork me on GitHub
去网址*[https://github.com/blog/273-github-ribbons](https://github.com/blog/273-github-ribbons)*挑选自己喜欢的样式，并复制代码，添加到`themes\next\layout\_layout.swig`的`body`标签之内即可
**记得把里面的url换成自己的!**

## 把侧边栏头像变成圆形，并且鼠标停留在上面发生旋转效果
﻿修改`themes\next\source\css\_common\components\sidebar\sidebar-author.styl`：
```
.site-author-image {

  display: block;
  margin: 0 auto;
  padding: $site-author-image-padding;
  max-width: $site-author-image-width;
  height: $site-author-image-height;
  border: site-author-image-border-color;

  /* start*/
  border-radius: 50%
  webkit-transition: 1.4s all;
  moz-transition: 1.4s all;
  ms-transition: 1.4s all;
  transition: 1.4s all;
  /* end */

}

/* start */
.site-author-image:hover {

  background-color: #55DAE1;
  webkit-transform: rotate(360deg) scale(1.1);
  moz-transform: rotate(360deg) scale(1.1);
  ms-transform: rotate(360deg) scale(1.1);
  transform: rotate(360deg) scale(1.1);
}
/* end */
```

## 修改链接文字样式
打开`themes\next\source\css\_common\components\post\post.styl`添加以下代码：
```
.post-body p a{

 color: #0593d3;
 border-bottom: none;
 &:hover {
   color: #ff106c;
   text-decoration: underline;
 }

}

```

`themes/next/source/css/_common/components/post/post-title.styl`修改为：
```
.posts-expand .post-title-link {

  display: inline-block;
  border-bottom: none;
  line-height: 1.2;
  vertical-align: top;

  &::before {
  ......

```

## 为next主题的主页文章添加阴影效果
打开`themes/next/source/css/_custom/custom.styl`文件添加：
```
 .post {
   margin-top: 60px;
   margin-bottom: 60px;
   padding: 25px;
   -webkit-box-shadow: 0 0 5px rgba(202, 203, 203, .5);
   -moz-box-shadow: 0 0 5px rgba(202, 203, 204, .5);
  }
```
## 为next主题添加nest背景特效
背景的几何线条是采用的`nest`效果，一个基于`html5 canvas`绘制的网页背景效果，非常赞！来自github的开源项目`canvas-nest`

### 特性

* 不依赖任何框架或者内库，比如不依赖jQuery，使用原生的javascript。
* 非常小，只有1.66kb，如果开启gzip，可以更小。
* 非常容易实现，配置简单，即使你不是web开发者，也能简单搞定。

使用非常简单

* `color`: 线条颜色, 默认: '0,0,0' ；三个数字分别为(R,G,B)，注意用,分割
* `opacity`: 线条透明度（0~1）, 默认: 0.5
* `count`: 线条的总数量, 默认: 150
* `zIndex`: 背景的z-index属性，css属性用于控制所在层的位置, 默认: -1

eg :

```
<script type="text/javascript" color="255,132,0" opacity='0.6' zIndex="-2" count="99" src="//cdn.bootcss.com/canvas-nest.js/1.0.1/canvas-nest.min.js"></script>
```

不足: CPU占用过高

### 如何添加?
#### 修改代码
打开`next/layout/_layout.swig`，在`</body>`之前添加如下代码：
```
{% if theme.canvas_nest %}

<script type="text/javascript" src="//cdn.bootcss.com/canvas-nest.js/1.0.0/canvas-nest.min.js"></script>

{% endif %}
```
#### 修改主题配置文件
打开`/next/_config.yml`，添加以下代码：
```
# --------------------------------------------------------------
# background settings
# --------------------------------------------------------------
# add canvas-nest effect
# see detail from https://github.com/hustcc/canvas-nest.js
canvas_nest: true
```
至此，大功告成，运行hexo clean 和 hexo g hexo s之后就可以看到效果了

## 添加音乐
去往*[网易云音乐](http://music.163.com/)*搜索喜欢的音乐，点击生成外链播放器，复制代码直接放到博文末尾即可，`height`设为0可隐藏播放器，但仍然可以播放音乐，`auto`设成0可手动播放，默认是1自动播放，可把代码放到`themes/next/layout/_custom/sidebar.swig`文件里，播放器会显示在站点预览中

## 添加注脚
安装插件：
```
npm install hexo-reference --save
```
用法如下：
```
this is a basic footnote[/^1] ##用的时候把/去掉
```
在文章末尾添加：
```
[/^1]: basic footnote content ##用的时候把/去掉
```

eg:this is a basic footnote[^1]

## 自定义页面
执行`hexo new page "guestbook"`之后，那怎么在博客中加进去呢？
找到`\next\_config.yml`下的`memu`，把`guestbook`加进去：
```
menu:
 home: /
 categories: /categories
 #about: /about
 archives: /archives
 tags: /tags
 guestbook: /guestbook
```
图标网站：*[http://fontawesome.io/icons/](http://fontawesome.io/icons/)*

在`/themes/hexo-theme-next/languages/zh-Hans.yml`的目录下（这里默认你使用的是简体中文，若是其他语言更改相应的`yml`就行），在`memu`下加一句即可：
```
guestbook: 留言
```

## 添加字数统计和阅读时间
### 安装插件
```
npm install hexo-wordcount --save
```

> 通过以上安装后，你可以在你的模板文件后者.md文件加入以下相关的标签实现本插件的功能
> 字数统计:WordCount
> 阅读时长预计:Min2Read
> 总字数统计: TotalCount

### 修改post.swig模板
找到`themes\next\layout\_macro\post.swig`并打开插入以下代码：
```
{# LeanCould PageView #}
         {% if theme.leancloud_visitors.enable %}
            <span id="{{ url_for(post.path) }}" class="leancloud_visitors" data-flag-title="{{ post.title }}">
		 &nbsp; | &nbsp;
              <span class="post-meta-item-icon">
                <i class="fa fa-eye"></i>
              </span>
              <span class="post-meta-item-text">{{__('post.visitors')}} </span>
              <span class="leancloud-visitors-count"></span>
             </span>
         {% endif %}

	  
#以下部分为：字数统计、阅读时长插入代码
         <span class="post-time">
	   &nbsp; | &nbsp;
           <span class="post-meta-item-icon">
             <i class="fa fa-calendar-o"></i>
           </span>
           <span class="post-meta-item-text">字数统计:</span>
           <span class="post-count">{{ wordcount(post.content) }}(字)</span>
           
         </span>
	  
      <span class="post-time">
	   &nbsp; | &nbsp;
           <span class="post-meta-item-icon">
             <i class="fa fa-calendar-o"></i>
           </span>
           <span class="post-meta-item-text">阅读时长:</span>
           <span class="post-count">{{ min2read(post.content) }}(分)</span>
           
         </span>
#以上部分为：字数统计、阅读时长插入代码
```

## 修改footer

修改之后的样子大概是这样的：
![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/result.png)

1、找到 `\themes\next\layout\partials\`下面的`footer.swig`文件，打开会发现，如下图的语句：
![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/footer.png)

- 第一个框 是下面侧栏的“日期❤ XXX”
  如果想像我一样加东西，一定要在双大括号外面写。如：`xxx{{config.author}}`,当然你要是想改彻底可以变量都删掉，看个人意愿。

- 第二个，是图一当中 “由Hexo驱动” 的Hexo链接，先给删掉防止跳转，如果想跳转当然也可以自己写地址，至于中文一会处理。注意删除的时候格式不能错，只把`<a>...</a>`标签这部分删除即可，留着两个单引号'',否则会出错哦。

- 第三个框也是最后一个了，这个就是更改图一后半部分“主题-Next.XX”,这个比较爽直接将<a>..</a>都删掉，同样中文“主题”一会处理，删掉之后在上一行 ‘-’后面可以随意加上你想显示的东西，不要显示敏感信息哟，请自重。

2、接下来，处理剩余的中文信息。找到这个地方`\themes\next\languages\` 下面的语言文件zh-Hans.yml（这里以中文为例，有的习惯用英文的配置文件，道理一样，找对应位置即可）
打开之后，如图：
![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/languages.png)

## 给博客添加吉祥物

> 详细信息： ***[https://github.com/EYHN/hexo-helper-live2d/blob/master/README.zh-CN.md](https://github.com/EYHN/hexo-helper-live2d/blob/master/README.zh-CN.md)***

效果图：

![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/hexo-helper-live2d.png)

安装依赖：

```
npm install --save hexo-helper-live2d
npm install --save live2d-widget-model-wanko
```

**站点配置**添加：

```
# hexo-helper-live2d配置，参考https://github.com/EYHN/hexo-helper-live2d/blob/master/README.zh-CN.md
live2d:
  enable: true
  scriptFrom: local
  pluginRootPath: live2dw/
  pluginJsPath: lib/
  pluginModelPath: assets/
  tagMode: false
  debug: false
  model:
    scale: 1
    use: live2d-widget-model-wanko
  display:
    superSample: 2 # 超采样等级
    width: 100 
    height: 100
    position: left # 位置
  mobile:
    show: false
  react:
    opacityDefault: 0.9 # 默认透明度
    opacityOnHover: 0.5 # 鼠标移上透明度
```

## 侧栏加入已运行的时间

`themes/next/layout/_custom`中添加`sidebar.swig`文件：

```html themes/next/layout/_custom https://reuixiy.github.io/technology/computer/computer-aided-art/2017/06/09/hexo-next-optimization.html 链接
<div id="days"></div>
    <script>
    function show_date_time(){
        window.setTimeout("show_date_time()", 1000);
        BirthDay=new Date("01/10/2017 12:34:56");
        today=new Date();
        timeold=(today.getTime()-BirthDay.getTime());
        sectimeold=timeold/1000
        secondsold=Math.floor(sectimeold);
        msPerDay=24*60*60*1000
        e_daysold=timeold/msPerDay
        daysold=Math.floor(e_daysold);
        e_hrsold=(e_daysold-daysold)*24;
        hrsold=setzero(Math.floor(e_hrsold));
        e_minsold=(e_hrsold-hrsold)*60;
        minsold=setzero(Math.floor((e_hrsold-hrsold)*60));
        seconds=setzero(Math.floor((e_minsold-minsold)*60));
        document.getElementById('days').innerHTML="已运行"+daysold+"天"+hrsold+"小时"+minsold+"分"+seconds+"秒";
    }
function setzero(i){
    if (i<10)
    {i="0" + i};
    return i;
}
show_date_time();
</script>
```

在`themes/next/layout/_macro/sidebar.swig`中的`</section>`之前添加

```
{% include '../_custom/sidebar.swig' %}
```

样式：

```diff themes/next/source/css/_custom/custom.styl
// 自定义的侧栏时间样式
#days {
    display: block;
    color: #fffa74;
    font-size: 14px;
    margin-top: 15px;
}
```

## 更改标签云（tagcloud）的颜色

`themes/next/layout/page.swig`找到`tagcloud并替换`:

```
{{ tagcloud({min_font: 13, max_font: 31, amount: 1000, color: true, start_color: '#9733EE', end_color: '#FF512F'}) }}
```

## 设置动态title

`themes/next/source/js/src`下创建`dytitle.js`：

```
var OriginTitile = document.title;
var titleTime;
document.addEventListener('visibilitychange', function () {
    if (document.hidden) {
        $('[rel="shortcut icon"]').attr('href', "/TEP.png");
        document.title = 'w(ﾟДﾟ)w 出BUG啦！！！！';
        clearTimeout(titleTime);
    }
    else {
        $('[rel="shortcut icon"]').attr('href', "/favicon.png");
        document.title = '♪(^∇^*)又好了。。。 ' + OriginTitile;
        titleTime = setTimeout(function () {
            document.title = OriginTitile;
        }, 2000);
    }
});
```

修改`themes/next/layout/layout.swing`,在 `</body>` 之前添加：:

```
<script type="text/javascript" src="/js/src/dytitle.js"></script>
```
## 修改文章底部的那个带#号的标签

修改模板`/themes/next/layout/_macro/post.swig`，搜索 `rel="tag">#`，将 # 换成`<i class="fa fa-tag"></i>`

# 元素微调自定义篇

那么如何把字体、页宽、按钮大小等等一些细节的东西调到自己喜欢的样式呢？
那就是通过浏览器元素定位，调到自己喜欢的样式，然后加到`themes/next/source/css/_custom/custom.styl`文件下面。
## 定位元素
用谷歌或者火狐浏览器打开博客页面，按下F12进入调试
先点击定位按钮，然后选择元素，然后在定位出来的样式进行修改，调到自己喜欢的样子，就像这样↓
![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/yemiantiaoshi.png)

## 添加到样式文件
打开`themes/next/source/css/_custom/custom.styl`，把调试好的样式加进去，保存后`Ctrl+F5`就能看到效果了，前提是在本地运行的，下面列出博主的一些自定义样式：
```
// Custom styles.
// 页面头部背景
.header {  background:url(http://ojoba1c98.bkt.clouddn.com/img/header/header_background.jpg);}

// 子标题
.site-subtitle{ font-size: 15px; color: white; }

// 标题
.site-title {
    font-size: 40px;
    font-weight: bold;
}

// 标题背景
.brand{
    background: transparent;
}

// 菜单栏
.menu {
	margin-top: 20px;
	padding-left: 0;
	text-align: center;
	background: rgba(240, 240, 240, 0.5);
	margin-left: auto;
	margin-right: auto;
	width: 530px;
	border-radius: initial;
}

// 菜单图表链接 以及 超链接样式
a {
    color: rgba(0,0,0,0.8);
}
a:hover {
    color: #ff106c;
    border-bottom-color: #ff106c;
}

// 菜单字体大小
.menu .menu-item a {
    font-size: 14px;
}
.menu .menu-item a:hover {
    border-bottom-color: #ff106c;
}

// 文章背景框框
.post {
    margin-top: 10px;
    margin-bottom: 40px;
    padding: 18px;
    -webkit-box-shadow: 0 0 5px rgba(202, 203, 203, 0.8);
   }

// 站点描述
.site-description {
    font-size: 16px;

}

// 头部inner
.header-inner {
    padding: 45px 0 25px;
    width: 700px;
}

// 作者名
.site-author-name {
    font-family: 'Comic Sans MS', sans-serif;
    font-size: 20px;
}

// 文章之间的分割线
.posts-expand .post-eof {
    margin: 40px auto 40px;
    background: white;
}

// 按钮样式
.btn {
    margin-top: 20px;
}

// ``代码块样式
code {
    color: #E6006B;
    background: white;
    border-radius: 3px;
}

// 文章```代码块顶部样式
.highlight figcaption {
    margin: 0em;
    padding: 0.5em;
    background: #eee;
    border-bottom: 1px solid #e9e9e9;
}
.highlight figcaption a {
    color: rgb(80, 115, 184);
}

// 文章标题动态效果 next/source/css/_common/components/post/post-title.styl中.posts-expand .post-title-link确保`position: relative;`属性存在，如果需要标题呈现链接效果颜色，将`color`元素去除即可
.posts-expand .post-title-link::before {
    background-image: linear-gradient(90deg, #a166ab 0%, #ef4e7b 25%, #f37055 50%, #ef4e7b 75%, #a166ab 100%);
}

// 文章内标题样式（左边的竖线）
.post-body h2, h3, h4, h5, h6 {
    border-left: 4px solid #657b83;
    padding-left: 10px;
}

.post-body h1 {
    border-left: 5px solid #657b83;
    padding-left: 10px;
}

body {
    color: #444;
    font-size: 16px;
}
```
但并不是所有的样式都能调，像页宽，多说评论的样式在`custom.styl`文件是无效的。

## 好玩的样式
先在`themes/next/source/css/_custom/custom.styl`中添加以下样式：
```
// 下载样式
a#download {
display: inline-block;
padding: 0 10px;
color: #000;
background: transparent;
border: 2px solid #000;
border-radius: 2px;
transition: all .5s ease;
font-weight: bold;
&:hover {
background: #000;
color: #fff;
}
}
/ /颜色块-黄
span#inline-yellow {
display:inline;
padding:.2em .6em .3em;
font-size:80%;
font-weight:bold;
line-height:1;
color:#fff;
text-align:center;
white-space:nowrap;
vertical-align:baseline;
border-radius:0;
background-color: #f0ad4e;
}
// 颜色块-绿
span#inline-green {
display:inline;
padding:.2em .6em .3em;
font-size:80%;
font-weight:bold;
line-height:1;
color:#fff;
text-align:center;
white-space:nowrap;
vertical-align:baseline;
border-radius:0;
background-color: #5cb85c;
}
// 颜色块-蓝
span#inline-blue {
display:inline;
padding:.2em .6em .3em;
font-size:80%;
font-weight:bold;
line-height:1;
color:#fff;
text-align:center;
white-space:nowrap;
vertical-align:baseline;
border-radius:0;
background-color: #2780e3;
}
// 颜色块-紫
span#inline-purple {
display:inline;
padding:.2em .6em .3em;
font-size:80%;
font-weight:bold;
line-height:1;
color:#fff;
text-align:center;
white-space:nowrap;
vertical-align:baseline;
border-radius:0;
background-color: #9954bb;
}
// 左侧边框红色块级
p#div-border-left-red {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-left-width: 5px;
border-radius: 3px;
border-left-color: #df3e3e;
}
// 左侧边框黄色块级
p#div-border-left-yellow {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-left-width: 5px;
border-radius: 3px;
border-left-color: #f0ad4e;
}
// 左侧边框绿色块级
p#div-border-left-green {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-left-width: 5px;
border-radius: 3px;
border-left-color: #5cb85c;
}
// 左侧边框蓝色块级
p#div-border-left-blue {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-left-width: 5px;
border-radius: 3px;
border-left-color: #2780e3;
}
// 左侧边框紫色块级
p#div-border-left-purple {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-left-width: 5px;
border-radius: 3px;
border-left-color: #9954bb;
}
// 右侧边框红色块级
p#div-border-right-red {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-right-width: 5px;
border-radius: 3px;
border-right-color: #df3e3e;
}
// 右侧边框黄色块级
p#div-border-right-yellow {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-right-width: 5px;
border-radius: 3px;
border-right-color: #f0ad4e;
}
// 右侧边框绿色块级
p#div-border-right-green {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-right-width: 5px;
border-radius: 3px;
border-right-color: #5cb85c;
}
// 右侧边框蓝色块级
p#div-border-right-blue {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-right-width: 5px;
border-radius: 3px;
border-right-color: #2780e3;
}
// 右侧边框紫色块级
p#div-border-right-purple {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-right-width: 5px;
border-radius: 3px;
border-right-color: #9954bb;
}
// 上侧边框红色
p#div-border-top-red {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-top-width: 5px;
border-radius: 3px;
border-top-color: #df3e3e;
}
// 上侧边框黄色
p#div-border-top-yellow {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-top-width: 5px;
border-radius: 3px;
border-top-color: #f0ad4e;
}
// 上侧边框绿色
p#div-border-top-green {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-top-width: 5px;
border-radius: 3px;
border-top-color: #5cb85c;
}
// 上侧边框蓝色
p#div-border-top-blue {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-top-width: 5px;
border-radius: 3px;
border-top-color: #2780e3;
}
// 上侧边框紫色
p#div-border-top-purple {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-top-width: 5px;
border-radius: 3px;
border-top-color: #9954bb;
}
```

**用法如下**：
### 文字增加背景色块
<span id="inline-blue">站点配置文件</span> ，<span id="inline-purple">主题配置文件</span>
```
<span id="inline-blue">站点配置文件</span>， 
<span id="inline-purple">主题配置文件</span>
```
### 引用边框变色
<p id="div-border-left-red">如果没有安装成功，那可能就是墙的原因。建议下载 `Node.js` 直接安装。</p>
<p id="div-border-top-blue">关于更多基本操作和基础知识，请查阅 [Hexo](https://hexo.io/zh-cn/) 与 [NexT](http://theme-next.iissnan.com/) 官方文档.</p>
```
<p id="div-border-left-red">如果没有安装成功，那可能就是墙的原因。建议下载 `Node.js` 直接安装。</p>
<p id="div-border-top-blue">关于更多基本操作和基础知识，请查阅 [Hexo](https://hexo.io/zh-cn/) 与 [NexT](http://theme-next.iissnan.com/) 官方文档.</p>
```

### 在文档中增加图标

- <i class="fa fa-pencil"></i>支持Markdown
  <i>Hexo 支持 GitHub Flavored Markdown 的所有功能，甚至可以整合 Octopress 的大多数插件。</i>
- <i class="fa fa-cloud-upload"></i>一件部署
  <i>只需一条指令即可部署到Github Pages，或其他网站</i>
- <i class="fa fa-cog"></i>丰富的插件
  <i>Hexo 拥有强大的插件系统，安装插件可以让 Hexo 支持 Jade, CoffeeScript。</i>

```
- <i class="fa fa-pencil"></i>支持Markdown
<i>Hexo 支持 GitHub Flavored Markdown 的所有功能，甚至可以整合 Octopress 的大多数插件。</i>
- <i class="fa fa-cloud-upload"></i>一件部署
<i>只需一条指令即可部署到Github Pages，或其他网站</i>
- <i class="fa fa-cog"></i>丰富的插件
<i>Hexo 拥有强大的插件系统，安装插件可以让 Hexo 支持 Jade, CoffeeScript。</i>
```

<i class="fa fa-github"></i>`<i class="fa fa-github"></i>`
<i class="fa fa-github fa-lg"></i>`<i class="fa fa-github fa-lg"></i>`
<i class="fa fa-github fa-2x"></i>`<i class="fa fa-github fa-2x"></i>`

采用的是***[Font Awesome](http://fontawesome.io/examples/)***的图标。

### 图形边框效果
<a id="download" href="https://git-scm.com/download/win"><i class="fa fa-download"></i><span> Download Now</span>
</a>
```
<a id="download" href="https://git-scm.com/download/win"><i class="fa fa-download"></i><span> Download Now</span>
</a>
```
这也是调用了***[Font Awesome](http://fontawesome.io/examples/)***的方法。

## 代码高亮相关

先看一则代码

```diff Hello World示例 http://yangbingdong.com 这是链接
	public static void main(String[] args) {
+		System.out.println("Hello World!");
-		System.out.println("Hello World!");
	}
```

正确姿势，代码片段开头：

```
[language] [title] [url] [link-text]
```

- `[language]` 是代码语言的名称，用来设置代码块颜色高亮，非必须；
- `[title]` 是顶部左边的说明，非必须；
- `[url]` 是顶部右边的超链接地址，非必须；
- `[link text]` 如它的字面意思，超链接的名称，非必须。

这 4 项应该是根据空格来分隔，而不是`[]`，故请不要加`[]`。除非如果你想写后面两个，但不想写前面两个，那么就必须加`[]`了，要这样写：`[] [] [url] [link text]`。

首先关于代码块颜色高亮，高亮的模式可以在**主题配置文件**中设置：

```
# Code Highlight theme
# Available value:
#    normal | night | night eighties | night blue | night bright
# https://github.com/chriskempson/tomorrow-theme

highlight_theme: normal
```

要颜色正确高亮，代码语言的名称肯定要写对，各种支持语言的名称可以查看[这篇文章](https://almostover.ru/2016-07/hexo-highlight-code-styles/)。也可以在站点配置文件`_config.yml`中设置自动高亮：

```diff blog/_config.yml
highlight:
  enable: true
  line_number: true
# 代码自动高亮
-  auto_detect: false
+  auto_detect: true
```

上边的diff是通过在`[language]`填写diff，然后在相应代码前面加上`-`和`+`

顶部的文字样式：

```
// 文章```代码块顶部样式
.highlight figcaption {
    margin: 0em;
    padding: 0.5em;
    background: #eee;
    border-bottom: 1px solid #e9e9e9;
}
.highlight figcaption a {
    color: rgb(80, 115, 184);
}
```


# 域名绑定篇

博客托管在Github和Coding，所以个人博客地址是Github或Coding的二级域名，不容易让人记住，也很难让百度收录，所以很多人都自己注册域名，和博客地址绑定，这样只要输入自己申请的域名，就能跳转到博客首页，也算是真正拥有了个人网站了
## 购买域名
博主选择***[万网](https://wanwang.aliyun.com/)***购买的域名，可以淘宝账号登陆，之后支付宝付款
至于怎么**实名认证**博主就略过了～
搜索自己想好的域名，没被注册的话，点击购买，top顶级域名第一年只要四元，选其他更高逼格的也可以，看个人喜好
## 域名解析
购买玩以后进入工作台，点击域名，然后解析
![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/yumingjiexi.png)
第一次可能需要填写个人信息，填完了，点击上面的域名解析->解析设置->添加解析，记录类型选`A`或`CNAME`，`A`记录的记录值就是ip地址，Github提供了两个IP地址，`192.30.252.153`和`192.30.252.154`，随便填一个就行，解析记录设置两个www和不填，线路就默认就行了，`CNAME`记录值填你的`Coding`的博客网址。
如果选择`A`（下图的Github地址）记录，就要在**网站根目录**新建`CNAME`文件，里面填写注册的域名`ookamiantd.top`，之后修改`站点配置文件`，把站点地址更新成新的绑定的域名即可
```
# URL
## If your site is put in a subdirectory, set url as 'http://yoursite.com/child' and root as '/child/'
url: http://www.ookamiantd.top
```

博主的是这样的↓
![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/DNSyumingjiexi.png)

一般解析配置好并不能马上访问，得看人品= =，博主的是第二天才访问到的，祝你好运



# 站点加速篇
## 更改默认Google字体库
访问系统总是会耗费一大部分的时间在加载`google`字体库上，而且经常加载不成功。

方法一：用国内的CDN库来替代主题中的`google`字体库，到`主题配置文件`中设置默认字体库：
```
host: fonts.useso.com
```

方法二：关掉字体库的引用，默认加载本地字体库，到`主题配置文件`设置：
``` 
font:
  enable: false
```
## 使用云盘存放图片资源
由于Github的服务器在海外，那么如果把图片也放到Github显然是不科学的，而且Github的存储空间也有局限，那么在这里博主推荐使用*[七牛云储存](http://www.qiniu.com/)*
具体怎么做在之前的基础篇已经介绍过了，详情请看→*[传送门](/2017/build-blog-hexo-base/#%E6%96%B9%E5%BC%8F%E4%B8%89)*

## 压缩代码
安装插件：
```
npm install hexo-all-minifier --save
```
之后执行`hexo g`就会自动压缩
但这有一个**缺点**，就是本地运行也就是执行`hexo s`之后浏览器打开本地项目会很慢，原因是每次点击一个链接它就会重新压缩一次，所以建议本地调试的时候把项目根目录下的`package.json`中的`"hexo-all-minifier": "0.0.14"`先删掉再调试,或者改成注释：
```
"dependencies": {
    .
	.
	.
    "hexo-server": "^0.2.0",
    "hexo-wordcount": "^2.0.1",
    "this-is-compress-plugin": {
      "hexo-all-minifier": "0.0.14"
    }
```
其实也没必要压缩代码，牺牲了性能，每次生成静态文件都太慢了，得不偿失的感觉

# SEO(搜索引擎优化)篇
## 网站验证
以下是几个搜索引擎的提交入口：
* ***[百度提交入口](http://zhanzhang.baidu.com/linksubmit/url)***
* ***[Google提交入口](https://www.google.com/webmasters/tools/home?hl=zh-CN)***
* ***[360提交入口](http://info.so.360.cn/site_submit.html)***

以百度为例，谷歌的太简单就不说了：
打开*[百度站长](http://zhanzhang.baidu.com/linksubmit/url)*验证网站
**方式一：文件验证**
* 登录百度站长选择添加网站，使用方式为文件验证
* 将下载的文件放到`source`文件下
* 由于hexo自动会对html文件进行渲染，所以在`站点配置文件`中找到`skip_render:`
* 在后面添加文件名字，如有多个用`[a.html,b.html]`，eg:`skip_render:[baidu_verify_tdOGHi8IQG.html, baidu_verify_vcJkI72f1e.html]`
* 重新渲染文件
```
hexo clean
hexo d -g
```
* 然后可以点击百度站长的验证按钮了


**方式二：CNAME验证**

1. 去站长添加网站选择CNAME验证
2. 把地址解析到zz.baidu.com
3. 完成验证

就像这样↓
![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/DNSjiexi.png)

![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/baiduyanzheng.png)

## 添加并提交sitemap
安装hexo的`sitemap`网站地图生成插件:
```
npm install hexo-generator-sitemap --save
npm install hexo-generator-baidu-sitemap --save
```

在`站点配置文件`中添加如下代码。
```
# hexo sitemap
sitemap:
  path: sitemap.xml

baidusitemap:
  path: baidusitemap.xml
```
配置成功后，会生成`sitemap.xml`和`baidusitemap.xml`，前者适合提交给**谷歌搜素引擎**，后者适合提交**百度搜索引擎**。
百度sitemap提交如下↓
![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/sitemap.png)

验证成功之后就可以开始推送了，这里说一下，Google的收录真的快的不要不要的，第二天就能搜得到，百度就不想说了，不知道要等到猴年马月
![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/GoogleSearch.png)

## 主动推送
安装主动推送插件：
```
﻿npm install hexo-baidu-url-submit --save
```
在根目录下，把以下内容配置到`站点配置文件`中:
```
baidu_url_submit:
  count: 3 ## 比如3，代表提交最新的三个链接
  host: www.henvyluk.com ## 在百度站长平台中注册的域名
  token: your_token ## 请注意这是您的秘钥，请不要发布在公众仓库里!
  path: baidu_urls.txt ## 文本文档的地址，新链接会保存在此文本文档里
```
至于上面提到的`your_token`可在百度站长如下位置找到↓
![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/baidutoken.png)
其次，记得查看`站点配置文件`中url的值， 必须包含是百度站长平台注册的域名（一般有www）， 比如:
```
url: http://www.ookamiantd.top
root: /
permalink: :year/:month/:day/:title/
```
接下来添加一个新的`deploy`的类型：
```
# Deployment
## Docs: https://hexo.io/docs/deployment.html
deploy:
- type: baidu_url_submitter
- type: git
  repo:
    github: git@github.com:masteranthoneyd/masteranthoneyd.github.io.git,master
    coding: git@git.coding.net:ookamiantd/ookamiantd.git,master
```

执行`hexo deploy`的时候，新的连接就会被推送了。这里讲一下原理：
* 新链接的产生，`hexo generate`会产生一个文本文件，里面包含最新的链接
* 新链接的提交，`hexo deploy`会从上述文件中读取链接，提交至百度搜索引擎

## 自动推送
把next`主题配置文件`中的`baidu_push`设置为`true`，就可以了。

## 添加蜘蛛协议
在`/source/`目录下新建一个`robots.txt`文件，添加下面的一段代码：
```
#hexo robots.txt
User-agent: *

Allow: /
Allow: /archives/

Disallow: /vendors/
Disallow: /js/
Disallow: /css/
Disallow: /fonts/
Disallow: /vendors/
Disallow: /fancybox/

Sitemap: http://blog.tangxiaozhu.com/search.xml
Sitemap: http://blog.tangxiaozhu.com/sitemap.xml
Sitemap: http://blog.tangxiaozhu.com/baidusitemap.xml
```
然后到百度站长更新一下，就像这样↓
![](http://ojoba1c98.bkt.clouddn.com/img/build-hexo/robots.png)

## 修改文章链接
hexo默认的文章链接形式为`domain/year/month/day/postname`，默认就是一个四级`url`，并且可能造成`url`过长，对搜索引擎是十分不友好的，我们可以改成`domain/postname`的形式。编辑`站点配置文件`文件，修改其中的`permalink`字段为`permalink: :title.html`即可。


## 更改首页标题格式为「关键词-网站名称 - 网站描述」
打开`\themes\next\layout\index.swig`文件，找到这行代码：
```
{% block title %} {{ config.title }} {% endblock %}    
```
把它改成：
```
{% block title %}
 {{ theme.keywords }} - {{ config.title }} - {{ theme.description }}
{% endblock %}
```

## 自动给所有外部链接添加nofollow
安装`hexo-autonofollow`，在站点的根目录下执行以下命令：
```
npm install hexo-autonofollow --save
```
编辑**站点配置文件**，新增以下内容到任意位置：
```
nofollow:
  enable: true
  exclude:
  - exclude1.com
  - exclude2.com
```

# 多PC同步源码篇
1.准备工作：公司电脑和家里电脑配置git ssh密钥连接

2.上传blog到git：此项建议先在blog进度最新的PC上进行，否则会有版本冲突，解决也比较麻烦。在PC上建立git ssh密钥连接和建立新库respo在此略过：    
* 编辑`.gitignore`文件：`.gitignore`文件作用是声明不被git记录的文件，blog根目录下的`.gitignore`是hexo初始化是创建的，可以直接编辑，建议`.gitignore`文件包括以下内容：      

```
.DS_Store      
Thumbs.db      
db.json      
*.log      
node_modules/      
public/      
.deploy*/
```
`public`内的文件可以根据`source`文件夹内容自动生成的，不需要备份。其他日志、压缩、数据库等文件也都是调试等使用，也不需要备份。

初始化仓库：
```
git init    
git remote add origin <server>
```
`server`是仓库的在线目录地址，可以从git上直接复制过来，`origin`是本地分支，`remote add`会将本地仓库映射到托管服务器的仓库上。

添加本地文件到仓库并同步到git上：
```
git add . #添加blog目录下所有文件，注意有个'.'(.gitignore里面声明的文件不在此内)    
git commit -m "hexo source first add" #添加更新说明    
git push -u origin master  #推送更新到git上
```

至此，git库上备份已完成。

3.将git的内容同步到另一台电脑：假设之前将公司电脑中的blog源码内容备份到了git上，现在家里电脑准备同步源码内容。**注意**，在同步前也要事先建好hexo的环境，不然同步后本地服务器运行时会出现无法运行错误。在建好的环境的主目录运行以下命令：
```
git init  #将目录添加到版本控制系统中    
git remote add origin <server>  #同上    
git fetch --all  #将git上所有文件拉取到本地    
git reset --hard origin/master  #强制将本地内容指向刚刚同步git云端内容
```
`reset`对所拉取的文件不做任何处理，此处不用`pull`是因为本地尚有许多文件，使用`pull`会有一些**版本冲突**，解决起来也麻烦，而本地的文件都是初始化生成的文件，较拉取的库里面的文件而言基本无用，所以直接丢弃。

4.家里电脑生成完文章并部署到服务器上后，此时需要将新的blog源码文件更新到git托管库上，不然公司电脑上无法获取最新的文章。在本地文件中运行以下命令：

```
git add . #将所有更新的本地文件添加到版本控制系统中
```
此时可以使用`git status`查看本地文件的状态。然后对更改添加说明更推送到git托管库上：

```
git commit -m '更新信息说明'  
git push
```
至此，家里电脑更新的备份完成。在公司电脑上使用时，只需先运行:
```
git pull
```
获取的源码即为最新文件

# 插件总结篇
## 部署插件
```
npm install hexo-deployer-git --save
```

## rss
```
npm install hexo-generator-feed --save
```

## Algolia

此处有两个版本

**第一**（以`0.2.0`为例）：

在站点找到`package.json`， 把添加一行` "hexo-algolia": "^0.2.0"`，然后：

```
npm install hexo-algolia --save 
```
这个为旧版的algolia，优点是全文索引，缺点是字数太多会索引失败

**第二**：直接安装

```
npm install hexo-algolia --save hexo algolia    
```

此处安装的应该是`1.0.0`之后的版本了，优点是没有字数限制了（因为没有了全文索引），只会索引文章开头的部分字段。但是需要在官网注册新key并且设置环境变量，方法：***[https://github.com/iissnan/theme-next-docs/issues/162](https://github.com/iissnan/theme-next-docs/issues/162)***

## sitemap

```
npm install hexo-generator-sitemap --save
npm install hexo-generator-baidu-sitemap --save
```

## 百度主动推送
```
npm install hexo-baidu-url-submit --save
```

## 分页插件
```
npm install hexo-generator-index --save
npm install hexo-generator-archive --save
npm install hexo-generator-category --save
npm install hexo-generator-tag --save
```
站点配置文件：
```
index_generator:
  per_page: 6

archive_generator:
  per_page: 10 ##归档页面默认20篇文章标题
  yearly: true  ##生成年视图
  monthly: true ##生成月视图

tag_generator:
  per_page: 10
```


## 压缩插件
```
npm install hexo-all-minifier --save
```

## 七牛admin插件
```
npm install --save hexo-admin-qiniu
hexo server -d
open http://localhost:4000/admin/
```
站点配置文件：
```
admin:
  qiniuCfg:
      imageslim: true  # 启动图片瘦身，仅华东区bucket可以使用
      AccessKey: 'your qiniu AK'
      SecretKey: 'your qiniu SK'
      BucketName: 'your BK Name'
      bucketHost: 'you BK Host'
```

## 注脚插件

```
npm install hexo-reference --save
```

## 字数与阅读时间插件
```
npm install hexo-wordcount --save
```

# 主题升级备份

对于升级主题，我们需要重新配置主题配置文件，那么每次升级都要这么干吗？超麻烦！

NexT作者给我们的建议就是使用***[Data Files](https://hexo.io/docs/data-files.html)***，具体详情请戳进 ***[Theme configurations using Hexo data files            #328](https://github.com/iissnan/hexo-theme-next/issues/328)***


# 最后

一路摸爬滚打下来也挺折腾的，不过确实满满的成就感，学到了很多
同时还要感谢很多很多的大神们的文章，有一些都忘了收藏记录下来，由衷地感谢
> **参考**
> ***[http://codepub.cn/2015/04/06/Github-Pages-personal-blog-from-Octopress-to-Hexo/](http://codepub.cn/2015/04/06/Github-Pages-personal-blog-from-Octopress-to-Hexo/)***
> ***[http://codepub.cn/2016/03/20/Hexo-blog-theme-switching-from-Jacman-to-NexT-Mist/](http://codepub.cn/2016/03/20/Hexo-blog-theme-switching-from-Jacman-to-NexT-Mist/)*** 
> ***[http://www.shellsec.com/news/34054.html](http://www.shellsec.com/news/34054.html)***
> ***[https://www.0101tx.com/pages/hexonextsanf.html](https://www.0101tx.com/pages/hexonextsanf.html)***
> ***[https://reuixiy.github.io/technology/computer/computer-aided-art/2017/06/09/hexo-next-optimization.html](https://reuixiy.github.io/technology/computer/computer-aided-art/2017/06/09/hexo-next-optimization.html)***


[^1]: basic footnote content

