---
title: Ubuntu安装后的主题美化与个性化设置
date: 2017-01-12 23:04:36
categories: OperatingSystemNote
tags: [Ubuntu]
---
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/desktop.png)
# 前言
既然是博主是喜欢折腾的人，那么重装这种事情也是必不可少的，每次重装之后，重新设置个性化总是觉得少了点什么。博主笨拙，那么把需要安装的、美化的记下来免得下次又少了点什么。

<!--more-->

# 系统清理篇

## 系统更新

安装完系统之后，需要更新一些补丁。`Ctrl+Alt+T`调出终端，执行一下代码：
```
sudo apt-get update
sudo apt-get upgrade
```
## 卸载libreOffice
```
sudo apt-get remove libreoffice-common
```
## 删除Amazon的链接
```
sudo apt-get remove unity-webapps-common

```
## 删除不常用的软件
```
sudo apt-get remove thunderbird totem rhythmbox empathy brasero simple-scan gnome-mahjongg aisleriot 
sudo apt-get remove gnome-mines cheese transmission-common gnome-orca webbrowser-app gnome-sudoku  landscape-client-ui-install   
sudo apt-get remove onboard deja-dup
```
**做完上面这些，系统应该干净了，下面我们来安装一些必要的软件**

***

# 翻墙篇
## 方式一：修改hosts

**为了便于后续软件能够快速下载，教程如下**

*[老D的博客](https://laod.cn/hosts/2016-google-hosts.html)* 讲的很清楚怎么修改hosts，下载地址：*[戳我](https://laod.cn/hosts/2016-google-hosts.html)*

下载完之后，解压会得到一个`hosts`文件。

```
cd ./Downloads 
sudo mv -f hosts /etc/hosts
```

## 方式二：下载Lantern
**如果为了更方便地科学上网，建议下载`Lantern`**
可在github（免翻墙）找到*[开源项目](https://github.com/getlantern/lantern/)*，拉到下面`README`下载对应版本

```
sudo dpkg -i lantern.deb
sudo chmod -R 777 /usr/bin/lantern
```

***


# 主题美化篇
## 安装unity-tweak-tool

调整 `Unity` 桌面环境，还是推荐使用`Unity Tweak Tool`，这是一个非常好用的 `Unity` 图形化管理工具，可以修改工作区数量、热区等。

```
sudo apt-get install unity-tweak-tool

```

## 安装Flatabulous主题

`Flatabulous`主题是一款`Ubuntu`下扁平化主题，也是我试过众多主题中最喜欢的一个！最终效果如上述图所示。

执行以下命令安装`Flatabulous`主题：

```
sudo add-apt-repository ppa:noobslab/themes 
sudo apt-get update 
sudo apt-get install flatabulous-theme
```

该主题有配套的图标，安装方式如下：
```
sudo add-apt-repository ppa:noobslab/icons 
sudo apt-get update 
sudo apt-get install ultra-flat-icons
```

**安装完成后，打开`unity-tweak-tool`软件，修改主题和图标**
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/unity-tweak-tool.png)


进入`Theme`，修改为`Flatabulous`：
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/theme.png)

在此界面下进入`Icons`栏，修改为`Ultra-flat`:
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/icons.png)


## 安装zsh


终端采用`zsh`和`oh-my-zsh`，既美观又简单易用，主要是能提高你的逼格！！！

首先，安装`zsh`：

```
sudo apt-get install zsh
```

接下来我们需要下载 `oh-my-zsh` 项目来帮我们配置 `zsh`，采用`wget`安装(需要先安装`git`)
```
sudo apt-get install git
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
```

查看`shells`
```
cat /etc/shells
```

所以这时的`zsh` 基本已经配置完成,你需要一行命令就可以切换到 `zsh` 模式，终端下输入以下命令
```
chsh -s /bin/zsh
```

最后，修改以下配色，会让你的终端样式看起来更舒服，在终端任意地方右键，进入配置文件(`profile`)->外观配置(`profile Preferences`)，弹出如下界面，进入`colors`一栏:
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/zsh.png)


其中，文字和背景采用系统主题，透明度设为10%，下面的`palette`样式采用`Tango`，这样一通设置后，效果如下：
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/zsh-show.png)


## 安装字体

`Ubuntu`自带的字体不太好看，所以采用**文泉译微米黑字体**替代，效果会比较好，毕竟是国产字体！
```
sudo apt-get install fonts-wqy-microhei
```

然后通过`unity-tweak-tool`来替换字体




> 到此，主题已经比较桑心悦目了，接下来推荐一些常用的软件，提高你的工作效率！

***

# 软件篇

## wiznote(为知笔记)

一款`linux`下强大的笔记软件

```
sudo add-apt-repository ppa:wiznote-team 
sudo apt-get update 
sudo apt-get install wiznote
```

## vim
系统并没有集成`vim`，可以执行以下代码安装：
```
sudo apt-get install vim
```
## wps
去*[wps官网](http://linux.wps.cn/)* 下载wps for Linux。
下载后，打开终端，运行一下命令
```
sudo dpkg -i wps-office_10.1.0.5672~a21_amd64.deb
```
***如果缺少依赖包，可以先执行一下命令(后面的软件安装过程中如出现依赖包问题，一样可以采用这种方式解决)***
```
sudo apt-get install -f
```

## chrome
去*[chrome官网](https://www.google.com/chrome/browser/desktop/index.html)* 下载linux版的chrome。
```
sudo dpkg -i google-chrome-stable_current_amd64.deb
```

## xmind
一款思维导图软件，再*[xmind官网](http://www.xmindchina.net/xiazai.html)下载deb安装包*
```
sudo dpkg -i xmind-7.5-linux_amd64.deb
```

## shutter
`Ubuntu`下很强大的一款截图软件
```
sudo apt-get install shutter
```

***设置快捷键：*** 
打开系统设置 -> `键盘` -> `快捷键` -> `自定义快捷键` -> `点击" + " `
名字随便起，命令：`shutter -s`
点击确定，再点禁用，键盘按下`ctrl+alt+a`，完成设置


## 系统清理软件 BleachBit
```
sudo add-apt-repository ppa:n-muench/programs-ppa
sudo apt-get update 
sudo apt-get install bleachbit 
```


## 多线程下载器
`XTREME`下载管理器旨在为您提供一个快速和安全的工具，用于管理所有的下载。采用了先进的动态分割算法，应用程序可以加快下载过程。 下载管理器支持`HTTP`，`HTTPS`，`FTP`协议，代理服务器需要授权的网站。此外，它可以无缝地集成到`Xtreme`下载管理器安装的浏览器发送任何下载。由于它是用`Java`编写的，它是兼容所有主要平台。
 
最终版本 `Xtreme Download Manager` (`XDMAN`) 4.7 已经发布。
安装方法，因为有`PPA`可用，支持`Ubuntu 14.10`、`14.04`、`12.04`用户，打开终端，输入一下命令：
```
sudo add-apt-repository ppa:noobslab/apps
sudo apt-get update
sudo apt-get install xdman
```
卸载`xdman`命令：
```
sudo apt-get remove xdman
```
或者到*[官网](http://xdman.sourceforge.net/download.html)* 下载
下载到的是.tar.xz的格式
创建`tar.xz`文件：只要先 `tar cvf xxx.tar xxx/` 这样创建`xxx.tar`文件先，然后使用 `xz -z xxx.tar `来将 `xxx.tar`压缩成为 `xxx.tar.xz`
解压`tar.xz`文件：先 `xz -d xxx.tar.xz` 将 `xxx.tar.xz`解压成 `xxx.tar` 然后，再用 `tar xvf xxx.tar`来解包。


## SMPlayer播放器安装
```
sudo apt-add-repository ppa:rvm/smplayer
sudo apt-get update
sudo apt-get install smplayer smplayer-skins smplayer-themes
```

## stardict火星译王
```
sudo apt-get install stardict
```
***安装词库：***
进入*[http://download.huzheng.org/](http://download.huzheng.org/)*
选择所需词库并下载，`a`为下载的词库名，然后重启`stardict`
```
tar -xjvf a.tar.bz2
mv a /usr/share/stardict/dic
```

## filezilla
```
sudo apt-get install filezilla
sudo apt-get install filezilla-locales
```
# 其他设置篇
## 点击图标最小化
`Ubuntu 16.04 LTS` 也支持了点击应用程序 `Launcher` 图标即可「最小化」的功能，不过还是需要用户进行手动启用。
方法有两种，你可以安装 `Unity Tweak Tool` 图形界面工具之后在 `「Unity」-「Launcher」-「Minimise」`中进行配置，或直接在终端中使用如下命令启用。

## exfat驱动
```
sudo apt-get install exfat-fuse
```

## 设置grub2引导等待时间
`Ubuntu`系统的`Grub2`菜单的相关信息在读取`/boot/grub/grub.cfg`文件，不过`Ubuntu`官方不建议直接修改这个文件，想要修改`Grub2`的等待时间还可以修改`/etc/deafalt/grub`来实现。具体的修改方法如下：
```
sudo gedit /etc/default/grub
```
将`GRUB_TIMEOUT=10`中的`10`改为你想要修改的等待时间，比如`3`，网上很多的教程都是到这一步，其实是不行的，估计都是乱转一气。到这里还有最重要的一步，就是使用`#`号将`GRUB_HIDDEN_TIMEOUT=0`标注,然后再次回到终端，输入下面的命令刷新`/boot/grub/grub.cfg`文件：
```
sudo update-grub2
```

## 启动项管理
```
gnome-session-properties
```

## 提高逼格
```
sudo apt-get install cmatrix
cmatrix -b
```

![](http://ojoba1c98.bkt.clouddn.com/img/individuation/cmatrix.png)

# 参考
> 参考来源 请查看***[ubuntu16.04主题美化和软件推荐](http://blog.csdn.net/terence1212/article/details/52270210)***










