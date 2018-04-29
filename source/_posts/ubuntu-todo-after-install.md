---
title: Ubuntu主题美化、个性化设置与常用软件
date: 2017-01-12 23:04:36
categories: [OperatingSystem,Ubuntu]
tags: [Ubuntu]
---
![](http://ojoba1c98.bkt.clouddn.com/img/gnome/activities-overview.jpg)
# 前言
> 鉴于 [Ubuntu 18.04 LTS](https://linux.cn/article-9183-1.html) 版本即将到来，本篇的16.04也将升级到18.04 GNOME 版本
>
> 可能会存在兼容问题，本篇将持续更新

<!--more-->

# 系统清理篇

## 系统更新

安装完系统之后，需要更新一些补丁。`Ctrl+Alt+T`调出终端，执行一下代码：
```
sudo apt update && sudo apt upgrade -y
```
## 卸载libreOffice
```
sudo apt remove --purge libreoffice-common
```
## 删除Amazon的链接
```
sudo apt remove --purge ubuntu-web-launchers
```
## 删除不常用的软件
```
sudo apt remove --purge thunderbird totem rhythmbox transmission gnome-mines gnome-mahjongg gnome-sudoku
sudo apt autoremove
```
# 科学上网篇
## 方式一：下载Lantern
**如果为了更方便地科学上网，建议下载`Lantern`** （免费版限流）
可在github（免翻墙）找到*[开源项目](https://github.com/getlantern/lantern/)*，拉到下面`README`下载对应版本

```
sudo dpkg -i lantern.deb
sudo chmod -R 777 /usr/bin/lantern
```

## 方式二：自搭建Shadowsocks
***[Access Blocked Sites(翻墙):VPS自搭建ShadowSocks与加速](/2017/use-vps-cross-wall-by-shadowsocks-under-ubuntu/)***

# 主题美化篇

## 16.04 Unity 桌面环境

### 安装unity-tweak-tool

调整 `Unity` 桌面环境，还是推荐使用`Unity Tweak Tool`，这是一个非常好用的 `Unity` 图形化管理工具，可以修改工作区数量、热区等。

```
sudo apt install unity-tweak-tool
```

### 安装Flatabulous主题

`Flatabulous`主题是一款`Ubuntu`下扁平化主题，也是我试过众多主题中最喜欢的一个！最终效果如上述图所示。

执行以下命令安装`Flatabulous`主题：

```
sudo add-apt-repository ppa:noobslab/themes 
sudo apt update 
sudo apt install flatabulous-theme
```

该主题有配套的图标，安装方式如下：
```
sudo add-apt-repository ppa:noobslab/icons 
sudo apt update 
sudo apt install ultra-flat-icons
```

**安装完成后，打开`unity-tweak-tool`软件，修改主题和图标**
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/unity-tweak-tool.png)


进入`Theme`，修改为`Flatabulous`：
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/theme.png)

在此界面下进入`Icons`栏，修改为`Ultra-flat`:
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/icons.png)

## 17.10以后的 GNOME 桌面环境

### 安装原生 GNOME 环境

```
sudo apt install -y gnome-session gnome-weather gnome-photos gnome-music gnome-backgrounds
```

恢复原生 gdm 登录界面：

```
sudo update-alternatives --config gdm3.css
```

然后选择第二个 `gnome-shell.css` ， 输入 `1`

### 主题

选择一款叫 Arc-Theme 的主题，包括了 GNOME Shell 主题和 GTK 主题。
安装前需要以下依赖包（直接使用 `sudo apt install` 安装即可）：

- `autoconf`
- `automake`
- `pkg-config`
- `libgtk-3-dev`
- `git`

#### 从 Github 上获取项目

```
git clone https://github.com/horst3180/arc-theme --depth 1 && cd arc-theme
```

#### 构建项目并安装

```
./autogen.sh --prefix=/usr
sudo make install
```

#### 其它选项

```
--disable-transparency     在 GTK3 主题中禁用透明度
--disable-light            禁用 Arc Light
--disable-darker           禁用 Arc Darker
--disable-dark             禁用 Arc Dark
--disable-cinnamon         禁用 Cinnamon
--disable-gnome-shell      禁用 GNOME Shell
--disable-gtk2             禁用 GTK2
--disable-gtk3             禁用 GTK3
--disable-metacity         禁用 Metacity
--disable-unity            禁用 Unity
--disable-xfwm             禁用 XFWM
--with-gnome=<version>     为特定的 GNOME 版本 (3.14, 3.16, 3.18, 3.20, 3.22) 构建主题
```

#### 选择主题

安装完成后打开自带的 `GNOME Tweak Tool` 工具选择对应的 `Arc` 主题即可。

如果没有这个工具那就：

```
sudo apt install gnome-tweak-tool gnome-shell-extensions
```

![](http://ojoba1c98.bkt.clouddn.com/img/gnome/gnome-tweak-tool.png)

**注意** :对于高分屏，可能使用 `Arc-Theme` 显示 GNOME Shell 的字体过小，可通过修改 `/usr/share/themes/[对应 Arc 主题]/gnome-shell/gnome-shell.css` 修改 **stage** 的 `font-size` 。

[**项目地址**](https://github.com/snwh/paper-icon-theme) ，其他热门主题 [**Numix**](https://github.com/snwh/paper-gtk-theme) 、 [**Paper**](https://github.com/numixproject/numix-gtk-theme)

### Icon

#### Numix

```
sudo add-apt-repository ppa:numix/ppa
sudo apt update
sudo apt install numix-icon-theme
```

**[项目地址](https://github.com/numixproject/numix-icon-theme)**

#### Paper

```
sudo add-apt-repository ppa:snwh/pulp
sudo apt update
sudo apt install paper-icon-theme
# 同时也可以安装 GTK 和 Cursor 主题
sudo apt install paper-gtk-theme
sudo apt install paper-cursor-theme
```

**[项目地址](https://github.com/snwh/paper-icon-theme)**

#### Papirus

```
sudo add-apt-repository ppa:papirus/papirus
sudo apt update
sudo apt install papirus-icon-theme
```

或者下载最新的 [**deb 安装包**](https://launchpad.net/~papirus/+archive/ubuntu/papirus/+packages?field.name_filter=papirus-icon-theme)
**[项目地址](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme)**

### GNOME Shell Extensions

先上图...

![](http://ojoba1c98.bkt.clouddn.com/img/gnome/desktop1.png)

![](http://ojoba1c98.bkt.clouddn.com/img/gnome/desktop2.png)

**下安装一下Chrome支持**：

```
sudo apt install chrome-gnome-shell
```

[**Weather**](https://extensions.gnome.org/extension/613/weather/) 天气插件

[**System Monitor**](https://extensions.gnome.org/extension/1064/system-monitor/) 系统监视器

这个先要安装依赖：

```
sudo apt install gir1.2-gtop-2.0 libgtop2-dev
```

[**Topicons Plus**](https://extensions.gnome.org/extension/1031/topicons/) 任务图标栏

任务图标栏使用默认的图标，如何让他使用自定义的图标主题呢？
比如使用 **Papirus** ，它支持 `hardcode-tray` 脚本来实现

1. 安装 `hardcode-tray`

```
sudo add-apt-repository ppa:andreas-angerer89/sni-qt-patched
sudo apt update
sudo apt install sni-qt sni-qt:i386 hardcode-tray inkscape
```

1. 转换图标

```
hardcode-tray --conversion-tool Inkscape
```

[**Nvidia GPU Temperature Indicator**](https://extensions.gnome.org/extension/541/nvidia-gpu-temperature-indicator/) 显卡温度指示器

[**Dash To Dock**](https://extensions.gnome.org/extension/307/dash-to-dock/) 可定制的 Dock

### 中文输入法

可更换成`ibus-pinyin`:

```
sudo apt remove --purge ibus-sunpinyin
sudo apt install ibus-pinyin
sudo ibus-daemon -d -x -r
现在可以在 Settings > Region & Language > Input sources 中添加 pinyin 输入法
```

### Fix Curl

装了GNOME后，发现没有`curl`...
对，下载源码安装：***[https://curl.haxx.se/download.html](https://curl.haxx.se/download.html)***
装好之后又尴尬了，不支持`https`！！！
一番查阅后，已解决：
step1，安装`openssl`：

```
sudo apt install openssl
sudo apt-get install libssl-dev
```

安装默认路径：
`/usr/lib/ssl`

step2，进入解压的`curl`源码包：

```
./configure --with-ssl=/usr/lib/ssl
make
sudo make install
```

![](http://ojoba1c98.bkt.clouddn.com/img/gnome/configure.png)

![](http://ojoba1c98.bkt.clouddn.com/img/gnome/have-https.png)

搞定～

## 安装Oh-My-Zsh


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

或者**一键安装**...
```
sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
```


最后，修改以下配色，会让你的终端样式看起来更舒服，在终端任意地方右键，进入配置文件(`profile`)->外观配置(`profile Preferences`)，弹出如下界面，进入`colors`一栏:
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/zsh.png)


其中，文字和背景采用系统主题，透明度设为10%，下面的`palette`样式采用`Tango`，这样一通设置后，效果如下：
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/zsh-show.png)

**配色**：

- 文本颜色：`#00FF00`
- 粗体字颜色：与文本颜色相同
- 背景颜色：`#002B36`

**主题**：

在`~/.oh-my-zsh/themes`中查看主题。

然后编辑`~/.zshrc`，找到`ZSH_THEME`修改为你想要的主题即可。

## 安装字体

`Ubuntu`自带的字体不太好看，所以采用**文泉译微米黑字体**替代，效果会比较好，毕竟是国产字体！
```
sudo apt-get install fonts-wqy-microhei
```

然后通过`unity-tweak-tool`来替换字体




> 到此，主题已经比较桑心悦目了，接下来推荐一些常用的软件，提高你的工作效率！

***

# 软件篇

## Wechat for Ubuntu
下载地址：
***[https://github.com/geeeeeeeeek/electronic-wechat/releases](https://github.com/geeeeeeeeek/electronic-wechat/releases)***
***[博主的百度盘](https://pan.baidu.com/s/1c2uyTEw)*** (密码: 9bpi) (提取路径：`UbuntuTools -> wechat4Ubuntu`)


下载最新版本，解压后打开目录里面的`electronic-wechat`，然后创建个软连接换个图标拉倒桌面就可以了

## QQ轻聊版
虽然不太想安装QQ，但工作时候团队交流需要，QQ国际版又太难看，所以装个Deepin的轻聊版。
工具包下载：***[博主的百度盘](https://pan.baidu.com/s/1c2uyTEw)*** (密码: 9bpi) (提取路径：`UbuntuTools>qq4Ubuntu`)

内含文件： `crossover_16.0.0-1.deb` 、 `crossover16crack.tar.gz` 和 `apps.com.qq.im.light_7.9.14308deepin0_i386.deb`

### crossover安装与破解
这个轻聊版是Deepin的作品，要在Ubuntu上使用，就要安装**crossover**，很不幸这玩意是收费的，很幸运的是这玩意是可以破解的。
1、安装的工具包下载下来解压后会有三个文件，首先先安装`crossover_16.0.0-1.deb`，缺少依赖就执行一下`sudo apt -f install`，安装完后**先不要打开**crossover。
2、在命令行输入`sudo nautilus`打开一个root权限的文件管理器
3、把破解文件 (`crossover16crack`->`winewrapper.exe.so`) 替换路径: `/opt/cxoffice/lib/wine`下的`winewrapper.exe.so`文件。提示已有文件，点“替换”破解完成。

### Deepin QQ轻聊版
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
然后`dpkg -i` 就可以安装了，中间如有冲突就`sudo apt -f install`进行修复。

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

## 版本控制系统GUI-SmartGit
```
sudo add-apt-repository ppa:eugenesan/ppa
sudo apt update
sudo apt install smartgithg
```
卸载：
```
sudo apt remove smartgithg

```

## Typora(Markdown编辑器)
*[官方](https://typora.io/#linux)*安装方法如下：
```
# optional, but recommended
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BA300B7755AFCFAE
# add Typora's repository
sudo add-apt-repository 'deb http://typora.io linux/'
sudo apt update
# install typora
sudo apt install typora
```

## GIF制作软件 Peek

```
sudo add-apt-repository ppa:peek-developers/stable
sudo apt update
sudo apt install peek
```

终端执行`peek`即可运行

![](http://ojoba1c98.bkt.clouddn.com/img/individuation/Peek%202018-01-22%2015-49.gif)

## StarUml

这个一款绘图工具
下载：***[http://staruml.io/download](http://staruml.io/download)***
安装依赖：***[https://launchpad.net/ubuntu/trusty/amd64/libgcrypt11/1.5.3-2ubuntu4.5](https://launchpad.net/ubuntu/trusty/amd64/libgcrypt11/1.5.3-2ubuntu4.5)***
然后`dpkg`安装就好了，如果还有依赖直接`apt install -f`修复一下就好。
安装好之后修改`LicenseManagerDomain.js`
查找：
```
dpkg -S staruml | grep LicenseManagerDomain.js
```
修改：
```
sudo gedit /opt/staruml/www/license/node/LicenseManagerDomain.js
```
如下：
```
(function () {
    "use strict";

    var NodeRSA = require('node-rsa');
    
    function validate(PK, name, product, licenseKey) {
        var pk, decrypted;
		return {  
            name: "yangbingdong",  
            product: "StarUML",  
            licenseType: "vip",  
            quantity: "yangbingdong.com",  
            licenseKey: "later equals never!"  
        };  
        try {
            pk = new NodeRSA(PK);
            decrypted = pk.decrypt(licenseKey, 'utf8');
        } catch (err) {
            return false;
        }
        var terms = decrypted.trim().split("\n");
        if (terms[0] === name && terms[1] === product) {
            return { 
                name: name, 
                product: product, 
                licenseType: terms[2],
                quantity: terms[3],
                licenseKey: licenseKey
            };
        } else {
            return false;
        }
    }
    ......
```
改完打开StarUml -> `Help` -> `Enter License`，不是输入任何东西直接确定

## 虚拟机
```
sudo apt-get install virtualbox
```

## SecureCRT Crack

### Install

官方下载地址（选择Linux版deb包）：***[https://www.vandyke.com/download/securecrt/download.html](https://www.vandyke.com/download/securecrt/download.html)***

```
sudo dpkg -i scrt-8.3.2-1584.ubuntu16-64.x86_64.deb
```

### Crack

准备：

```
wget http://download.boll.me/securecrt_linux_crack.pl

sudo apt install perl
```

查看一下SecureCRT的安装路径：

```
whereis SecureCRT

# 不出意外应该是在 /usr/bin/SecureCRT
```

运行perl脚本：

```
sudo perl securecrt_linux_crack.pl /usr/bin/SecureCRT
```

![](http://ojoba1c98.bkt.clouddn.com/img/individuation/securecrt-crack.png)

然后按照提示手动输入License即可

## wiznote(为知笔记)

一款`linux`下强大的笔记软件

```
sudo add-apt-repository ppa:wiznote-team 
sudo apt update 
sudo apt install wiznote
```

## Vim
系统并没有集成`vim`，可以执行以下代码安装：
```
sudo apt install vim
```
## Wps
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

## Chrome
到*[chrome官网](https://www.google.com/chrome/browser/desktop/index.html)* 下载linux版的chrome。
不能翻墙的小朋友可以到***[博主的百度盘](https://pan.baidu.com/s/1c2uyTEw)*** (密码: 9bpi)
```
sudo dpkg -i google-chrome-stable_current_amd64.deb
```

## XMind 8 Crack

### Setup

一款思维导图软件，再*[XMind官网](http://www.xmindchina.net/xiazai.html)*下载压缩包.

解压后先执行一下解压包根目录下的`setup.sh`：

```
sudo sh setup.sh
```

### Crack

* 将`XMindCrack.jar`复制到根目录的`plugins`文件中


* 以文本格式打开根目录中 `XMind.ini`
* 在最后一行添加`-javaagent:../plugins/XMindCrack.jar`
* 禁止XMind访问网络：在host文件中添加`127.0.0.1 www.xmind.net`，然后重启网络`sudo /etc/init.d/networking restart`
* 打开XMind输入序列号

**`XMindCrack.jar`**与**序列号**如果有需要可以私聊博主。

## Shutter
`Ubuntu`下很强大的一款截图软件
```
sudo apt install shutter
```

***设置快捷键：*** 
打开系统设置 -> `键盘` -> `快捷键` -> `自定义快捷键` -> `点击" + " `
名字随便起，命令：`shutter -s`
点击确定，再点禁用，键盘按下`ctrl+alt+a`，完成设置


## 系统清理软件 BleachBit
```
sudo add-apt-repository ppa:n-muench/programs-ppa
sudo apt update 
sudo apt install bleachbit 
```


## 多协议下载器 Aria2
一般在Linux环境中下载东西都是比较不友好的，不支持多种协议，方式单一，但这款Aria2就是为了解决多协议问题而诞生的，配合UI界面可以很方便地~~随心所欲~~地下载。

### 搭建 Aria2 以及 AriaNg Web UI

![](http://ojoba1c98.bkt.clouddn.com/img/individuation/aria2-ariaNg.jpg)

> 博主选择使用Docker

参考 *[aria2-ariang-docker](https://github.com/wahyd4/aria2-ariang-docker)* 以及 *[aria2-ariang-x-docker-compose](https://github.com/wahyd4/aria2-ariang-x-docker-compose)*

#### 配置`aria2.conf`

这个文件是从作者地 Github下载下来的，主要加了代理，而这个代理是 `sock5` 通过 `privoxy`

```
#所有协议代理
all-proxy=http://192.168.6.113:8118
#用户名
#rpc-user=user
#密码
#rpc-passwd=passwd
#上面的认证方式不建议使用,建议使用下面的token方式
#设置加密的密钥
#rpc-secret=token
#允许rpc
enable-rpc=true
#允许所有来源, web界面跨域权限需要
rpc-allow-origin-all=true
#允许外部访问，false的话只监听本地端口
rpc-listen-all=true
#RPC端口, 仅当默认端口被占用时修改
#rpc-listen-port=6800
#最大同时下载数(任务数), 路由建议值: 3
max-concurrent-downloads=5
#断点续传
continue=true
#同服务器连接数
max-connection-per-server=5
#最小文件分片大小, 下载线程数上限取决于能分出多少片, 对于小文件重要
min-split-size=10M
#单文件最大线程数, 路由建议值: 5
split=10
#下载速度限制
max-overall-download-limit=0
#单文件速度限制
max-download-limit=0
#上传速度限制
max-overall-upload-limit=0
#单文件速度限制
max-upload-limit=0
#断开速度过慢的连接
#lowest-speed-limit=0
#验证用，需要1.16.1之后的release版本
#referer=*
#文件保存路径, 默认为当前启动位置
# dir=/user-files/superuser/
dir=/data
#文件缓存, 使用内置的文件缓存, 如果你不相信Linux内核文件缓存和磁盘内置缓存时使用, 需要1.16及以上版本
#disk-cache=0
#另一种Linux文件缓存方式, 使用前确保您使用的内核支持此选项, 需要1.15及以上版本(?)
#enable-mmap=true
#文件预分配, 能有效降低文件碎片, 提高磁盘性能. 缺点是预分配时间较长
#所需时间 none < falloc ? trunc « prealloc, falloc和trunc需要文件系统和内核支持
file-allocation=prealloc

# General Options
log=/var/log/aria2.log
#You can set either debug, info, notice, warn or error.
log-level=error

## 进度保存相关 ##
# 从会话文件中读取下载任务
input-file=/root/conf/aria2.session
# 在Aria2退出时保存`错误/未完成`的下载任务到会话文件
save-session=/root/conf/aria2.session
# 定时保存会话, 0为退出时才保存, 需1.16.1以上版本, 默认:0
save-session-interval=10

# BT trackers from https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt
# echo `wget -qO- https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt|awk NF|sed ":a;N;s/\n/,/g;ta"`
bt-tracker=udp://tracker.coppersurfer.tk:6969/announce,udp://tracker.leechers-paradise.org:6969/announce,udp://9.rarbg.to:2710/announce,udp://p4p.arenabg.com:1337/announce,http://p4p.arenabg.com:1337/announce,udp://tracker.internetwarriors.net:1337/announce,http://tracker.internetwarriors.net:1337/announce,udp://tracker.skyts.net:6969/announce,udp://tracker.safe.moe:6969/announce,udp://tracker.piratepublic.com:1337/announce,udp://tracker.opentrackr.org:1337/announce,http://tracker.opentrackr.org:1337/announce,udp://wambo.club:1337/announce,udp://trackerxyz.tk:1337/announce,udp://tracker4.itzmx.com:2710/announce,udp://tracker2.christianbro.pw:6969/announce,udp://tracker1.wasabii.com.tw:6969/announce,udp://tracker.zer0day.to:1337/announce,udp://public.popcorn-tracker.org:6969/announce,udp://peerfect.org:6969/announce,udp://tracker.mg64.net:6969/announce,udp://mgtracker.org:6969/announce,http://tracker.mg64.net:6881/announce,http://mgtracker.org:6969/announce,http://t.nyaatracker.com:80/announce,http://retracker.telecom.by:80/announce,ws://tracker.btsync.cf:2710/announce,udp://zephir.monocul.us:6969/announce,udp://z.crazyhd.com:2710/announce,udp://tracker.xku.tv:6969/announce,udp://tracker.vanitycore.co:6969/announce,udp://tracker.tvunderground.org.ru:3218/announce,udp://tracker.torrent.eu.org:451/announce,udp://tracker.tiny-vps.com:6969/announce,udp://tracker.swateam.org.uk:2710/announce,udp://tracker.halfchub.club:6969/announce,udp://tracker.grepler.com:6969/announce,udp://tracker.files.fm:6969/announce,udp://tracker.dutchtracking.com:6969/announce,udp://tracker.dler.org:6969/announce,udp://tracker.desu.sh:6969/announce,udp://tracker.cypherpunks.ru:6969/announce,udp://tracker.cyberia.is:6969/announce,udp://tracker.christianbro.pw:6969/announce,udp://tracker.bluefrog.pw:2710/announce,udp://tracker.acg.gg:2710/announce,udp://thetracker.org:80/announce,udp://sd-95.allfon.net:2710/announce,udp://santost12.xyz:6969/announce,udp://sandrotracker.biz:1337/announce,udp://retracker.nts.su:2710/announce,udp://retracker.lanta-net.ru:2710/announce,udp://retracker.coltel.ru:2710/announce,udp://oscar.reyesleon.xyz:6969/announce,udp://open.stealth.si:80/announce,udp://ipv4.tracker.harry.lu:80/announce,udp://inferno.demonoid.pw:3418/announce,udp://allesanddro.de:1337/announce,http://tracker2.itzmx.com:6961/announce,http://tracker.vanitycore.co:6969/announce,http://tracker.torrentyorg.pl:80/announce,http://tracker.city9x.com:2710/announce,http://torrentsmd.me:8080/announce,http://sandrotracker.biz:1337/announce,http://retracker.mgts.by:80/announce,http://open.acgtracker.com:1096/announce,http://omg.wtftrackr.pw:1337/announce,wss://tracker.openwebtorrent.com:443/announce,wss://tracker.fastcast.nz:443/announce,wss://tracker.btorrent.xyz:443/announce,udp://tracker.uw0.xyz:6969/announce,udp://tracker.kamigami.org:2710/announce,udp://tracker.justseed.it:1337/announce,udp://tc.animereactor.ru:8082/announce,udp://packages.crunchbangplusplus.org:6969/announce,udp://explodie.org:6969/announce,udp://bt.xxx-tracker.com:2710/announce,udp://bt.aoeex.com:8000/announce,udp://104.238.198.186:8000/announce,https://open.acgnxtracker.com:443/announce,http://tracker.tfile.me:80/announce,http://share.camoe.cn:8080/announce,http://retracker.omsk.ru:2710/announce,http://open.acgnxtracker.com:80/announce,http://explodie.org:6969/announce,http://agusiq-torrents.pl:6969/announce,http://104.238.198.186:8000/announce
```

#### 使用h5ai作为文件管理器

```
version: '3.4'

services:
  h5ai:
    image: bixidock/h5ai
    volumes:
      - /home/ybd/data/docker/aria2/data:/var/www
    restart: always
  aria2:
    image: wahyd4/aria2-ui:h5ai
    ports:
      - "8000:80"
      - "6800:6800"
    volumes:
    #   - /some_folder:/root/conf/key
      - /home/ybd/data/docker/aria2/config/aria2.conf:/root/conf/aria2.conf
      - /home/ybd/data/docker/aria2/config/aria2.session:/root/conf/aria2.session
      - /home/ybd/data/docker/aria2/cache/dht.dat:/root/.cache/aria2/dht.dat
      - /home/ybd/data/docker/aria2/data:/data
    environment:
      - DOMAIN=:80
      # - SSL=true
      # - RPC_SECRET=Hello
      # - ARIA2_USER=admin
      # - ARIA2_PWD=password
      # - ENABLE_AUTH=true
    links:
      - h5ai:file-manager
    restart: always
```

![](http://ojoba1c98.bkt.clouddn.com/img/individuation/h5ai.jpg)

#### 使用nextcloud作为文件管理器

`docker-compose.yml` :

```
version: '3.4'

services:
  nextcloud:
    image: wonderfall/nextcloud
    volumes:
      - /home/ybd/data/docker/aria2/nextcloud:/data
      - /home/ybd/data/docker/aria2/data:/user-files
    restart: always
  aria2:
    image: wahyd4/aria2-ui:nextcloud
    ports:
      - "8000:80"
      - "6800:6800"
    volumes:
      - /home/ybd/data/docker/aria2/config/aria2.conf:/root/conf/aria2.conf
      - /home/ybd/data/docker/aria2/config/aria2.session:/root/conf/aria2.session
      - /home/ybd/data/docker/aria2/data:/data
    environment:
      - DOMAIN=:80
      # - SSL=true
      # - RPC_SECRET=Hello
      # - ARIA2_USER=admin
      # - ARIA2_PWD=password
      # - ENABLE_AUTH=true
    links:
      - nextcloud:file-manager
    restart: always
```

使用nettcloud作为文件管理还需要手动配置一下：

*[https://github.com/wahyd4/aria2-ariang-x-docker-compose/tree/master/nextcloud#nextcloud-%E9%85%8D%E7%BD%AE-external-storage](https://github.com/wahyd4/aria2-ariang-x-docker-compose/tree/master/nextcloud#nextcloud-%E9%85%8D%E7%BD%AE-external-storage)*

### 百度网盘直接下载助手

1、安装 *[Tampermonkey](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo?hl=zh-CN)* Chrome插件，这个主要是管理脚本的，下面安装百度云盘脚本需要用到

2、进入 *[百度网盘直接下载助手(显示直接下载入口)](https://greasyfork.org/zh-CN/scripts/36549-%E7%99%BE%E5%BA%A6%E7%BD%91%E7%9B%98%E7%9B%B4%E6%8E%A5%E4%B8%8B%E8%BD%BD%E5%8A%A9%E6%89%8B-%E6%98%BE%E7%A4%BA%E7%9B%B4%E6%8E%A5%E4%B8%8B%E8%BD%BD%E5%85%A5%E5%8F%A3)* ，点击`安装`或者`install`,完了直接刷新界面，进入到自己的百度云盘选择所需的下载文件即可。

![](http://ojoba1c98.bkt.clouddn.com/img/individuation/baidupan.jpg)

### BaiduExporter

> 博主使用的是BaiduExporter，上面那个下载助手导出来链接在我这边并不能下载成功。。囧
>
> 官方是这么说明的
>
> * Chrome : Click Settings -> Extensions, drag BaiduExporter.crx file to the page, install it, or check Developer mode -> Load unpacked extension, navigate to the chrome/release folder.
> * Firefox : Open about:debugging in Firefox, click "Load Temporary Add-on" and navigate to the chrome/release folder, select manifest.json, click OK.


1、到 *[Github](https://github.com/acgotaku/BaiduExporter)* 下载与源码

2、打开Chrome -> 扩展程序 -> 勾选开发者模式 -> 加载已解压的扩展程序 ，然后会弹出文件框，找到刚才下载的源码，找到chrome -> release，添加成功！

3、打开百度云盘网页版，勾选需要下载的文件，在上方会出现导出下载地选项，通过设置可以修改RCP地址

![](http://ojoba1c98.bkt.clouddn.com/img/individuation/baiduexporter1.jpg)
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/baiduexporter2.jpg)

## Stardict火星译王

```
sudo apt install stardict
```
***安装词库：***
进入*[http://download.huzheng.org/](http://download.huzheng.org/)*
选择所需词库并下载，`a`为下载的词库名，然后重启`stardict`
```
tar -xjvf a.tar.bz2
mv a /usr/share/stardict/dic
```

## Filezilla
```
sudo apt install filezilla
sudo apt install filezilla-locales
```

## rar安装与使用

### 安装
```
sudo apt install rar
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
sudo apt update
sudo apt install systemback
```

## 键盘输入声音特效（Tickys）
***[官网](http://www.yingdev.com/projects/tickeys)*** 或者 ***[博主的百度盘](https://pan.baidu.com/s/1c2uyTEw)*** (密码: 9bpi)
下载`tickys`之后执行:
```
sudo apt install tickys
```
然后通过`sudo tickeys`来打开 (sudo tickeys -c 打开CLI版本)
![](http://ojoba1c98.bkt.clouddn.com/img/individuation/tickeys_v0.2.5.png)

## 硬件信息

### I-Nex

这是一个类似CPU-Z的工具

下载链接：***[https://launchpad.net/i-nex/+download](https://launchpad.net/i-nex/+download)***

![](http://ojoba1c98.bkt.clouddn.com/img/individuation/I-Nex%20-%20CPU_001.png)

### Hardinfo

```
sudo apt-get install hardinfo -y
```

![](http://ojoba1c98.bkt.clouddn.com/img/individuation/System%20Information_002.png)

# 其他设置篇

## 点击图标最小化
`Ubuntu 16.04 LTS` 也支持了点击应用程序 `Launcher` 图标即可「最小化」的功能，不过还是需要用户进行手动启用。
方法有两种，你可以安装 `Unity Tweak Tool` 图形界面工具之后在 `「Unity」-「Launcher」-「Minimise」`中进行配置，或直接在终端中使用如下命令启用。

## exfat驱动
```
sudo apt install exfat-fuse
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
sudo apt install docky
```

## 提高逼格
```
sudo apt install cmatrix
cmatrix -b
```

![](http://ojoba1c98.bkt.clouddn.com/img/individuation/cmatrix.png)

