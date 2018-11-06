---
title: 基于Hexo+Github+Coding搭建个人博客——基础篇(从菜鸟到放弃)
date: 2017-01-15 20:44:05
categories: Hexo
tags: [Hexo, Node.js, Github, Coding, Git]
---
![](https://cdn.yangbingdong.com/img/build-hexo/hexoGoverment.png)

# 前言
搭建此博客的动机以及好处在此就不多谈了，之前已经表达过，详情请看*[Start My Blog Trip — Power By Hexo](/2017/hello-world/)*
记录一下搭建的基本过程以及遇到的一些问题，仅供参考
= =废话不多说，进入主题
<!--more-->
* Hexo博客搭建的基础大致流程为：
   安装Node.js →安装Git → 安装Hexo → 安装主题 → 本地测试运行 → 注册给github与coding并创建pages仓库 → 部署

* 这是博主的系统环境与版本:
  OS: Ubuntu16.04
  Node.js: 6.2.0
  Npm: 3.8.9
  Hexo: 3.2.2
  主题NexT: 5.1.0
  Git: 2.7.4

* **对于使用windows的童鞋，可参考文章末尾处的参考链接，步骤大同小异**
* 以下提到的**<font color=red>站点配置文件</font>**指的是博客文件根目录下的 `_config.yml`，**<font color=red>主题配置文件</font>**是主题文件夹下的 `_config.yml`，童鞋们不要混淆了
------

# 安装Node.js

> Node.js的安装有很多种方式，*[Hexo的官方文档](https://hexo.io/zh-cn/docs/)* 建议是用*[nvm](https://github.com/creationix/nvm)* 安装，但好多人都说不行，所以找了另外两种方式安装
> **windows**的童鞋可参考*[安装Node.js](http://www.runoob.com/nodejs/nodejs-install-setup.html)*

## 方法一：二进制包直接解压配置
在node.js的*[官网](https://nodejs.org/en/)* 下载二进制包来安装的，下载过后，解压，设置软链接，要不然每次都执行命令都要加上路径，好麻烦
```shell
sudo ln -s /home/ybd/Data/soft/application/node-v6.2.0-linux-x64/bin/node /usr/local/bin/node

sudo ln -s /home/ybd/Data/soft/application/node-v6.2.0-linux-x64/bin/npm /usr/local/bin/npm
```
**注意**！源文件要写**<font color=red>绝对路径</font>**，否则会报错：**链接层数过多**。也可以直接将node可执行文件拷贝到 `/usr/local/bin` 目录下。

接下来就可以查看是否成功配置了
```
node -v
npm -v
```

## 方法二：换源下载
安装 6.x 版本：
```
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y nodejs
```

安装 8.x 版本：
```
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs
```

npm 更换淘宝镜像：
```
npm config set registry https://registry.npm.taobao.org/
```

## 方法三：源文件编译安装
在安装前，首先需要配置安g++编译器
```
sudo apt-get install build-essential
```
去*[官网](https://nodejs.org/en/download/)* 下载源代码，选择最后一项，Source Code
解压到某一目录，然后进入此目录,依次执行以下3条命令
```
./configure
make
sudo make install
```
执行以下命令，检测是否已经装好node.js
```
node -v
```
npm安装，一条命令即可解决
```
curl http://npmjs.org/install.sh | sudo sh
```
![](https://cdn.yangbingdong.com/img/build-hexo/version.png)

博主安装Node.js遇到的问题就是多次安装了不同版本的Node.js，有的是安装在用户变量上，有的是系统变量，所以每次用的时候都要切换到root用户，就算赋权 `sudo chmod 777 file` 都没有用，所以折腾了很久才把Node.js完全卸载，再重新安装

# 安装Git
**Ubuntu**系统下安装Git非常简单，只需一条命令：
```
sudo apt-get install git
```
**windows**下就直接到*[Git官网](https://git-scm.com/download/win)* 下载安装即可

然后终端执行 `git --version` 查看是否安装成功
![](https://cdn.yangbingdong.com/img/build-hexo/git-version.png)


# 安装Hexo
> 什么是 Hexo？Hexo 是一个快速、简洁且高效的博客框架。Hexo 使用 Markdown（或其他渲染引擎）解析文章，在几秒内，即可利用靓丽的主题生成静态网页。

* 所有以上必备的应用程序安装完成后，**无论是在哪个操作系统**，之后的操作都一样

安装Hexo的非常简单，只要一条命令，前提是安装好Node.js与Git
```
npm install -g hexo-cli
```
* 如果npm安装hexo失败，则很有可能是**<font color=red>权限</font>**问题，或者npm与node的版本不兼容（很少出现）

如果顺利安装完成，理论上Hexo已经安装完成，但在**Ubuntu**系统中，比较**坑**的地方就是 `hexo` 命令居然放在了Node.js安装目录的 `bin` 文件夹下，不能快捷地在终端把命令敲出来，所以还是老规矩，软链接走起
```
sudo ln -s /home/ybd/data/application/node-v7.4.0-linux-x64/bin/hexo /usr/local/bin/hexo
```
到此，Hexo的安装已基本完成，可以先试一下**Hello World**。

# 解决Hexo命令fs.SyncWriteStream问题
> `nodejs`版本更新到`8.0`之后，运行`hexo`相关命令总会出现这么一行鬼东西：
> `(node:538) [DEP0061] DeprecationWarning: fs.SyncWriteStream is deprecated.`
> 虽然不怎么影响大局，当对于强迫症来说是一个**噩梦**！

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

# 本地启动Hello World与Hexo简单使用
## 初始化
随便建一个文件夹，名字随便取，博主取其名为blog，`cd` 到文件夹里，先安装必要的文件，执行以下命令：
```
hexo init  # hexo会在目标文件夹建立网站所需要的所有文件
npm install  # 安装依赖包
```
## 本地启动
有了必要的各种配置文件之后就可以在本地预览效果了
```
hexo g # 等同于hexo generate，生成静态文件
hexo s # 等同于hexo server，在本地服务器运行
```
![](https://cdn.yangbingdong.com/img/build-hexo/buildCmd.png)
之后打开浏览器并输入IP地址 `http://localhost:4000/` 查看，效果如下
![](https://cdn.yangbingdong.com/img/build-hexo/helloWorld.png)

## 新建文章与页面
```
hexo new "title"  # 生成新文章：\source\_posts\title.md
hexo new page "title"  # 生成新的页面，后面可在主题配置文件中配置页面
```

* 生成文章或页面的模板放在博客文件夹根目录下的 `scaffolds/` 文件夹里面，文章对应的是 `post.md` ，页面对应的是`page.md`，草稿的是`draft.md`

## 编辑文章
打开新建的文章`\source\_posts\postName.md`，其中`postName`是`hexo new "title"`中的`title`
```
title: Start My Blog Trip — Power By Hexo  # 文章页面上的显示名称，可以任意修改，不会出现在URL中
date: 2017-01-10 23:49:28  # 文章生成时间，一般不改
categories: diary  # 文章分类目录，多个分类使用[a,b,c]这种格式
tags: [Hexo,diary]  # 文章标签
---

#这里开始使用markdown格式输入你的正文。

<!--more--> 
#more标签以下的内容要点击“阅读全文”才能看见

```

## 插入图片
**插入图片有三种方式**
### 方式一
在博客根目录的 `source` 文件夹下新建一个 `img` 文件夹专门存放图片，在博文中引用的**图片路径**为 `/img/图片名.后缀`

```
![](图片路径)
```
### 方式二
对于那些想要更有规律地提供图片和其他资源以及想要将他们的资源分布在各个文章上的人来说，Hexo也提供了更组织化的方式来管理资源，将**站点配置文件**中的 `post_asset_folder` 选项设为 `true` 来打开文章资源文件夹

```
post_asset_folder: true
```
然后再博文中通过相对路径引用
```
{% asset_img 图片文件名 %}
```

### 方式三
使用*[七牛云储存](http://www.qiniu.com/)*，因为Github跟Coding项目容量有限，而且Github的主机在国外，访问速度较慢，把图片放在国内的图床上是个更好的选择，免费用户实名审核之后，新建空间，专门用来放置博客上引用的资源，进入空间后点击「内容管理」，再点击「上传」
![](https://cdn.yangbingdong.com/uploadImg.png)

上传完成之后点击关闭回到管理页面，选中刚上传的图片，最右边的操作点击复制链接即可
![](https://cdn.yangbingdong.com/img/build-hexo/copyUrl.png)
然后在博文中通过地址引用
```
![](图片地址如：https://cdn.yangbingdong.com/img/build-hexo/copyUrl.png)
```

## 简单的命令
总结一下简单的使用命令
```
hexo init [folder] # 初始化一个网站。如果没有设置 folder ，Hexo 默认在目前的文件夹建立网站
hexo new [layout] <title> # 新建一篇文章。如果没有设置 layout 的话，默认使用 _config.yml 中的 default_layout 参数代替。如果标题包含空格的话，请使用引号括起来
hexo version # 查看版本
hexo clean # 清除缓存文件 (db.json) 和已生成的静态文件 (public)
hexo g # 等于hexo generate # 生成静态文件
hexo s # 等于hexo server # 本地预览
hexo d # 等于hexo deploy # 部署，可与hexo g合并为 hexo d -g
```

# 安装主题（以NexT为例）
更多主题请看***[知乎专栏](https://www.zhihu.com/question/24422335)***
![](https://cdn.yangbingdong.com/img/build-hexo/scheme.png)
## 复制主题
Hexo 安装主题的方式非常简单，只需要将主题文件拷贝至站点目录的 `themes` 目录下， 然后修改下配置文件即可
在这我们使用git克隆最新版
```
cd your-hexo-site
git clone https://github.com/iissnan/hexo-theme-next themes/next
```
## 启用主题
打开**站点配置文件**， 找到 theme 字段，并将其值更改为 next
```
theme: next
```
然后 `hexo s` 即可预览主题效果
## 更换主题外观
NexT有三个外观，博主用的是 `Muse`，直接更改**主题配置文件**的 `scheme` 参数即可，如果显示的是繁体中文，那么**站点配置文件**中的 `language: zh-CN`
```
scheme: Muse
#scheme: Mist
#scheme: Pisces
```
在次执行 `hexo clean` 和 `heox s` 可预览效果
**大部分的设定都能在*[NexT的官方文档](http://theme-next.iissnan.com/getting-started.html)* 里面找到，如侧栏、头像、打赏、评论等等，在此就不多讲了，照着文档走就行了，接下只是个性定制的问题**


# 注册Github和Coding并分别创建Pages
在本地运行没有问题的话，那么可以部署到外网去，在此之前，先得有服务器让你的项目可以托管，那么Github Page与Coding Page就是个很好的东西，它们可以让我们访问**静态文件**，而Hexo生成的恰恰是静态文件
具体请查看 *[Coding Page](https://coding.net/help/doc/pages/index.html)* 、 *[Github Page](https://pages.github.com/)*

那为什么要注册两个网站呢？因为Github是国外的服务器，访问速度比较慢，而Coding是国内的，速度相对来说比较快，在后面**DNS解析**的时候可以把国内的解析到Coding，国外的解析到Github，完美

## GitHub

### 注册Github帐号
进入*[Github](https://github.com/)* 首页进行注册，用户名、邮箱和密码之后都需要用到，自己记好，不知道怎么注册的童鞋去问问度娘

### 创建Repository(Github Pages)
Repository相当于一个仓库，用来放置你的代码文件。首先，登陆进入*[Github](https://github.com/)*，选择首页中的 `New repository` 按钮
![](https://cdn.yangbingdong.com/img/build-hexo/newRepo.png)
创建时，只需要填写Repository name即可，可以顺便创建README文件，就是红色那个钩，当然这个名字的格式必须为`{user_name}.github.io`，其中`{user_name}`**必须**与你的用户名一样，这是github pages的**特殊命名规范**，如下图请忽视红色警告，那是因为博主已经有了一个pages项目
![](https://cdn.yangbingdong.com/img/build-hexo/createRepo.png)

## Coding
### 注册Coding帐号
国内的网站，绝大部分都是中文的，注册什么的就不说了,进入*[Coding](https://coding.net)* 滚键盘就是了= =
### 创建项目(Coding Pages)
Coding Pages请看 *[Coding Pages](https://coding.net/help/doc/pages/index.html)*
注册之后进入主页，点击项目，点击**+**，项目名为你的用户名
![](https://cdn.yangbingdong.com/img/build-hexo/createCoding.png)
查看Pages 服务是否开启：点击项目 -> 代码 -> Pages 服务，若没有开启则点开启
![](https://cdn.yangbingdong.com/img/build-hexo/codingPage.png)


# 配置SSH与Git
那么我们有了两个免费的服务器之后，就要绑定个人电脑与它们联系，那就是**SSH**与**Git**
绑定之后我们每次部署项目就不用输入帐号和密码
## 生成SSH Key
```
ssh-keygen -t rsa -C your_email@youremail.com
```
后面的 `your_email@youremail.com` 改为你的邮箱，之后会要求确认路径和输入密码，我们这使用默认的一路回车就行。成功的话会在~/下生成 `.ssh` 文件夹，进去，打开 `id_rsa.pub`，复制里面的key，粗暴点就是 Ctrl+a 然后 Ctrl+c
## 添加SSH Key
首先是Github，登录Github，右上角 头像 -> `Settings` —> `SSH nd GPG keys` —> `New SSH key` 。把公钥粘贴到key中，填好title并点击 `Add SSH key`
![](https://cdn.yangbingdong.com/img/build-hexo/githubSSH.png)

至于Coding，登录进入主页，点击 `账户` —> `SSH公钥` —> 输入key再点击 `添加`
![](https://cdn.yangbingdong.com/img/build-hexo/codingSSH.png)

## 验证成功与否
验证github
```
ssh -T git@github.com
```
如果是第一次的会提示是否continue，输入**<font color=red>yes</font>**就会看到：You’ve successfully authenticated, but GitHub does not provide shell access 。这就表示已成功连上github!之前博主就是因为没有输入**yes**，导致几次失败，粗心地一路回车= =
验证coding
```
ssh -T git@git.coding.net
```
同上，按**yes**
接下来我们要做的就是把本地仓库传到github上去，在此之前还需要设置username和email，因为github每次commit都会记录他们
```
git config --global user.name your name
git config --global user.email your_email@youremail.com
```
关于git可参考：
*[史上最全github使用方法：github入门到精通](http://blog.csdn.net/v123411739/article/details/44071059/)*
*[Git学习笔记](/2017/note-of-learning-git/)*

# 部署到Github与Coding
在此之前，先安装**Git部署插件**
```
npm install hexo-deployer-git --save
```
打**开站点配置文件**，拉到底部，修改部署配置：
```
# Deployment
## Docs: https://hexo.io/docs/deployment.html
deploy:
  type: git
  repo:
    github: git@github.com:masteranthoneyd/masteranthoneyd.github.io.git,master
    coding: git@git.coding.net:ookamiantd/ookamiantd.git,master
```
注意冒号后面是网站对应的用户名，接着就是**/**，然后再是你的项目名加上 `.git,master`
保存后终端执行
```
hexo clean
hexo g
hexo d
```
稍等片刻，可能会由于环境、网络等原因，部署的时间会有偏差，有的人快有的慢
![](https://cdn.yangbingdong.com/img/build-hexo/deploy.png)
部署完成后可在浏览器输入 `yourName.github.io` 或者 `yourName.coding.me` 都可以浏览到一个属于自己的博客了 ～

# 绑定自定义域名开启Https

1. 首先你需要一个域名，这个就不说了，可以去万网
2. 分别对Coding以及Github解析

## Coding

在代码中找到Pages服务：

![](https://cdn.yangbingdong.com/img/build-hexo/coding-encrypt.png)

要注意的是需要**按照提示添加CHAME记录**，比如博主的是`ookamiantd.coding.me`，检验成功后才可绑定成功。

## Github

* 跟Coding一样，需要添加CHAME记录，记录值为对应的Pages域名，比如博主的是`masteranthoneyd.github.io`
* 除此之外还需要在网站根目录添加一个CHAME文件，内容为你的自定义域名

![](https://cdn.yangbingdong.com/img/build-hexo/github-encccrypt.png)

效果图：

![](https://cdn.yangbingdong.com/img/build-hexo/green-lock.png)

至此，境内外的小绿锁都开启了。

当然，如果站内有部分资源不是https方式（比如图片），锁就绿不起来了。

# 总结

最后用拙劣的语言总结一下博主搭建Hexo博客的体会，六个字：简洁但，不简单。
再六个字，正如NexT官方说的：精于心，简于形
= =貌似这个博客也不怎么简洁，有点花俏，装X嫌疑
但无论怎样，折腾这个博客让我受益匪浅，正如之前听到的一句名言，忘了谁说的：不努力试一把，又怎么会知道绝望...好像很有道理，绝望中寻找光芒，绝处逢生...嘿嘿嘿

# 参考
> ***[使用Hexo搭建个人博客(基于hexo3.0) ](http://opiece.me/2015/04/09/hexo-guide/)***
> ***[Github Pages个人博客，从Octopress转向Hexo](http://codepub.cn/2015/04/06/Github-Pages-personal-blog-from-Octopress-to-Hexo/#)***
> ***[Hexo 3.1.1 静态博客搭建指南](http://lovenight.github.io/2015/11/10/Hexo-3-1-1-%E9%9D%99%E6%80%81%E5%8D%9A%E5%AE%A2%E6%90%AD%E5%BB%BA%E6%8C%87%E5%8D%97/)***
> ***[Hexo官方文档](https://hexo.io/zh-cn/)***
> ***[NexT官方文档](http://theme-next.iissnan.com/getting-started.html)***






