---
title: 解决Hexo命令出现fs.SyncWriteStream问题
date: 2017-09-19 11:56:18
categories: [Hexo]
tags: [Hexo]
---

![](http://ojoba1c98.bkt.clouddn.com/img/solve-sync-write-stream/alasijiaquan.jpg)

# Preface

> （↑ 图文无关 ↑）
> `nodejs`版本更新到`8.0`之后，运行`hexo`相关命令总会出现这么一行鬼东西：
>
> ```shell
> (node:538) [DEP0061] DeprecationWarning: fs.SyncWriteStream is deprecated.
> ```
> 虽然不怎么影响大局，当对于强迫症来说是一个**噩梦**，于是决定把它干掉！

<!--more-->

# Solve
`nodejs`从`8.0`开始已经弃用了`fs.SyncWriteStream`方法，但是某些插件里面还是用到这个方法。查看Hexo项目也有这个一条[issue](https://github.com/hexojs/hexo/issues/2598)，在`hexo`项目中其中有一个`hexo-fs`的插件调用了这个方法，所以需要更新`hexo-fs`插件，更新方法如下：
```shell
npm install hexo-fs --save
```

当然还有一些插件：

```
npm install hexo-deployer-git@0.3.1 --save
npm install hexo-renderer-ejs@0.3.1 --save
npm install hexo-server@0.2.2 --save
```

**But**，问题木有得到解决啊！
`hexo`命令有个`-debug`参数，运行命令的时候加上这个参数，可以定位问题：

```shell
ybd@15ffab36a16c:~/blog$ hexo clean --debug
03:01:16.464 DEBUG Hexo version: 3.3.9
03:01:16.467 DEBUG Working directory: ~/blog/
03:01:16.539 DEBUG Config loaded: ~/blog/_config.yml
03:01:16.613 DEBUG Plugin loaded: hexo-admin-qiniu
(node:538) [DEP0061] DeprecationWarning: fs.SyncWriteStream is deprecated.
03:01:16.655 DEBUG Plugin loaded: hexo-algolia
03:01:16.657 DEBUG Plugin loaded: hexo-baidu-url-submit
03:01:16.668 DEBUG Plugin loaded: hexo-deployer-git
03:01:16.672 DEBUG Plugin loaded: hexo-fs
03:01:16.674 DEBUG Plugin loaded: hexo-generator-archive
03:01:16.677 DEBUG Plugin loaded: hexo-generator-baidu-sitemap
03:01:16.678 DEBUG Plugin loaded: hexo-generator-category
03:01:16.680 DEBUG Plugin loaded: hexo-generator-feed
03:01:16.681 DEBUG Plugin loaded: hexo-generator-index
03:01:16.682 DEBUG Plugin loaded: hexo-generator-tag
03:01:16.826 DEBUG Plugin loaded: hexo-inject
03:01:16.828 DEBUG Plugin loaded: hexo-renderer-ejs
03:01:16.829 DEBUG Plugin loaded: hexo-generator-sitemap
03:01:16.834 DEBUG Plugin loaded: hexo-renderer-marked
03:01:16.836 DEBUG Plugin loaded: hexo-renderer-stylus
03:01:16.881 DEBUG Plugin loaded: hexo-server
03:01:16.912 DEBUG Plugin loaded: hexo-wordcount
03:01:16.943 DEBUG Plugin loaded: hexo-reference
03:01:16.946 DEBUG Script loaded: themes/next/scripts/merge-configs.js
03:01:16.947 DEBUG Script loaded: themes/next/scripts/tags/button.js
03:01:16.947 DEBUG Script loaded: themes/next/scripts/tags/center-quote.js
03:01:16.947 DEBUG Script loaded: themes/next/scripts/tags/full-image.js
03:01:16.947 DEBUG Script loaded: themes/next/scripts/tags/note.js
03:01:16.948 DEBUG Script loaded: themes/next/scripts/tags/group-pictures.js
03:01:16.949 DEBUG [hexo-inject] firing inject_ready
03:01:16.951 INFO  Deleted database.
03:01:16.956 DEBUG Database saved
```

发现问题在`hexo-admin-qiniu`这个插件=.=

貌似也没怎么用这个插件，那么就删掉吧：
```shell
nmp uninstall hexo-admin-qiniu --save	
```

那个报错终于消失啦～～～

# Finally

> 休想逼死强迫症