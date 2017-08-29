---
title: Ubuntu安装后的主题美化与个性化设置
date: 2017-01-12 23:04:36
categories: [OperatingSystem,Ubuntu]
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

## 安装 Wechat for Ubuntu
下载地址：
***[https://github.com/geeeeeeeeek/electronic-wechat/releases](https://github.com/geeeeeeeeek/electronic-wechat/releases)***
***[博主的百度盘](https://pan.baidu.com/s/1c2uyTEw)*** (密码: 9bpi) (提取路径：`UbuntuTools>wechat4Ubuntu`)


下载最新版本，解压后打开目录里面的`electronic-wechat`，然后创建个软连接换个图标拉倒桌面就可以了

## 安装QQ轻聊版
虽然不太想安装QQ，但工作时候团队交流需要，QQ国际版又太难看，所以装个Deepin的轻聊版。
工具包下载：***[博主的百度盘](https://pan.baidu.com/s/1c2uyTEw)*** (密码: 9bpi) (提取路径：`UbuntuTools>qq4Ubuntu`)

内含文件： `crossover_16.0.0-1.deb` 、 `crossover16crack.tar.gz` 和 `apps.com.qq.im.light_7.9.14308deepin0_i386.deb`

### crossover安装与破解
这个轻聊版是Deepin的作品，要在Ubuntu上使用，就要安装**crossover**，很不幸这玩意是收费的，很幸运的是这玩意是可以破解的。
1、安装的工具包下载下来解压后会有三个文件，首先先安装`crossover_16.0.0-1.deb`，缺少依赖就执行一下`sudo apt-get -f install`，安装完后**先不要打开**crossover。
2、在命令行输入`sudo nautilus`打开一个root权限的文件管理器
3、把破解文件 (`crossover16crack`->`winewrapper.exe.so`) 替换路径: `/opt/cxoffice/lib/wine`下的`winewrapper.exe.so`文件。提示已有文件，点“替换”破解完成。

### 安装Deepin QQ轻聊版
1、用归档管理器打开`apps.com.qq.im.light_7.9.14308deepin0_i386.deb`
2、点开 `data.tar.xz` 找到 `./opt/cxoffice/support`
3、把 `apps.com.qq.im.light` 这个文件夹提取出来
4、在命令行输入`sudo nautilus`打开一个root权限的文件管理器
5、然后将这个文件夹复制到系统的 `/opt/cxoffice/support` 下 
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/crossover-file.png)
6、然后打开 `crossover` ，发现多了一个容器 ，点击图标即可运行QQ轻聊版 
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/crossover.png)
7、如果运行后出现乱码，把 Windows 系统下的 `%systemroot%\fonts\simsun.ttf (simsun.ttc)` 复制到容器的对应文件夹就可以

## 搜狗输入法安装与崩溃处理
### 安装
点击下载 Sogou For Linux -> <a id="download" href="http://pinyin.sogou.com/linux/"><i class="fa fa-download"></i><span> Download Now</span>
</a>
然后`dpkg -i` 就可以安装了，中间如有冲突就`sudo apt-get -f install`进行修复。

### 搜狗输入法不能输入中文解决（linux下常见软件崩溃问题解决方案） 
先关闭`fcitx`：
```bash
killall fcitx
killall sogou-qinpanel
```
然后**删除搜狗配置文件**，ubuntu下搜狗的配置文件在 ~/.config下的3个文件夹里：
`SogouPY`、`SogouPY.users`、`sogou-qimpanel`
删除这3个文件夹，然后重启搜狗：
```bash
fcitx
```
解决！

## 安装Git
上面也提到过安装`git`
```
sudo apt-get install git
```

## 安装版本控制系统GUI-SmartGit
```
sudo add-apt-repository ppa:eugenesan/ppa
sudo apt-get update
sudo apt-get install smartgithg
```
卸载：
```
sudo apt-get remove smartgithg
```

## 安装Typora(Markdown编辑器)
```
# optional, but recommended

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BA300B7755AFCFAE

# add Typora's repository

sudo add-apt-repository 'deb https://typora.io ./linux/'

sudo apt-get update

# install typora

sudo apt-get install typora
```

## 安装chm阅读器-kchmViewer
```
sudo apt-get install kchmviewer
```

## 安装虚拟机
```
sudo apt-get install virtualbox
```

## 安装wiznote(为知笔记)

一款`linux`下强大的笔记软件

```
sudo add-apt-repository ppa:wiznote-team 
sudo apt-get update 
sudo apt-get install wiznote
```

## 安装Vim
系统并没有集成`vim`，可以执行以下代码安装：
```
sudo apt-get install vim
```
## 安装Wps
去*[wps官网](http://linux.wps.cn/)* 下载wps for Linux。
先不要执行dpkg -i 去执行安装。这个地方有个问题，就是ubuntu 16 版本不支持32位的支持库，所以需要安装一下支持库。
32位的支持库名为：ia32-libs
安装的时候会提示有替代包，需要安装替代包。
```bash
sudo apt install lib32ncurses5 lib32z1
```
还是不要执行dpkg -i ，因为即使现在安装还是会缺少一个依赖。这个依赖是libpng-12.0。不过这个在默认的apt 仓库里没有。所以需要手动下载一下。
下载地址：***[https://packages.debian.org/zh-cn/wheezy/amd64/libpng12-0/download](https://packages.debian.org/zh-cn/wheezy/amd64/libpng12-0/download)***
```bash
sudo dpkg -i libpng12-0_1.2.49-1+deb7u2_amd64.deb
```
最后：
```bash
sudo dpkg -i wps-office_10.1.0.5672~a21_amd64.deb
```

## 安装Chrome
到*[chrome官网](https://www.google.com/chrome/browser/desktop/index.html)* 下载linux版的chrome。
不能翻墙的小朋友可以到***[博主的百度盘](https://pan.baidu.com/s/1c2uyTEw)*** (密码: 9bpi)
```
sudo dpkg -i google-chrome-stable_current_amd64.deb
```

## 安装Xmind
一款思维导图软件，再*[xmind官网](http://www.xmindchina.net/xiazai.html)下载deb安装包*
```
sudo dpkg -i xmind-7.5-linux_amd64.deb
```

## 安装Shutter
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

## 安装Stardict火星译王
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

## 安装Filezilla
```
sudo apt-get install filezilla
sudo apt-get install filezilla-locales
```
## proxychains的安装与使用
安装：
```
sudo apt install proxychains
```
配置：
```
编辑/etc/proxychains.conf，最下面有一行socks4 127.0.0.1 9050，把这一行注释掉，添加一行socks5 127.0.0.1 1080
```
测试：
```
proxychains curl www.google.com
```
如果能看到一堆输出，说明设置成功，如果一直等待或者无法访问则代表设置失败。
使用：
用命令行启动软件，在前面加上proxychains，如：
```
proxychains firefox
```
使用shadowsocks+proxychains代理打开新的firefox实现浏览器翻墙。
也可以通过输入proxychains bash建立一个新的shell，基于这个shell运行的所有命令都将使用代理。





## rar安装与使用

### 安装
```
sudo apt-get install rar
```
### 使用
解压到当前目录：
```
unrar e update.rar
```

解压到指定目录：
```
unrar x update.rar update/
```

压缩：
```
rar a pg_healthcheck.rar1 pg_healthcheck/
```

## 备份工具
```
sudo add-apt-repository ppa:nemh/systemback
sudo apt-get update
sudo apt-get install systemback
```

## 键盘输入声音特效（Tickys）
***[官网](http://www.yingdev.com/projects/tickeys)*** 或者 ***[博主的百度盘](https://pan.baidu.com/s/1c2uyTEw)*** (密码: 9bpi)
下载`tickys`之后执行:
```
sudo apt-get install tickys
```
然后通过`sudo tickeys`来打开 (sudo tickeys -c 打开CLI版本)
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/tickeys_v0.2.5.png)



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

## 好玩的Docky
```
sudo apt-get install docky
```

## 提高逼格
```
sudo apt-get install cmatrix
cmatrix -b
```

![](http://ojoba1c98.bkt.clouddn.com/img/individuation/cmatrix.png)

# 参考
> 参考来源 请查看***[ubuntu16.04主题美化和软件推荐](http://blog.csdn.net/terence1212/article/details/52270210)***










