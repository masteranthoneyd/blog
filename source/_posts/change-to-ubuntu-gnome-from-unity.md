---
title: Ubuntu GNOME安装主题与美化
date: 2017-09-04 15:55:07
categories: [OperatingSystem,Ubuntu]
tags: [Ubuntu,GNOME]
---
![](http://ojoba1c98.bkt.clouddn.com/img/gnome/activities-overview.jpg)
# Preface

> 在今年四月份，Ubuntu以及Canonical的创始人Mark Shuttleworth，今天在Ubuntu官方网站发表了一篇重磅文章，原文标题是*[《Growing Ubuntu for Cloud and IoT, rather than Phone and convergence》](https://insights.ubuntu.com/2017/04/05/growing-ubuntu-for-cloud-and-iot-rather-than-phone-and-convergence/)*，里面有一项，那就是Ubuntu的默认桌面将回归 GNOME 桌面环境。
> 最为一名爱折腾的小白，一直用的是Unity，用了GNOME之后，个人感觉，GNOME比Unity更高逼格...
> 于是迫不及待地开始折腾了...

<!--more-->

# Install
一开始的做法是直接安装GNOME，然后注销登录就可以了：
```shell
sudo apt-get install gnome-session-flashback
```
但考虑到会不会有兼容性的问题，就直接下载Ubuntu GNOME重装了=.=
<a id="download" href="https://ubuntugnome.org/download"><i class="fa fa-download"></i><span> Download Now</span>
</a>
安装过程博主就省略了。

# Theme
博主选择一款叫 Arc-Theme 的主题，包括了 GNOME Shell 主题和 GTK 主题。
安装前需要以下依赖包（直接使用 `sudo apt install` 安装即可）：
* `autoconf`
* `automake`
* `pkg-config`
* `libgtk-3-dev`
* `git`

## 从 Github 上获取项目
```
git clone https://github.com/horst3180/arc-theme --depth 1 && cd arc-theme
```

## 构建项目并安装
```
./autogen.sh --prefix=/usr
sudo make install
```

## 其它选项
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

## 选择主题
安装完成后打开自带的 `GNOME Tweak Tool` 工具选择对应的 `Arc` 主题即可。

**注意** :对于高分屏，可能使用 `Arc-Theme` 显示 GNOME Shell 的字体过小，可通过修改 `/usr/share/themes/[对应 Arc 主题]/gnome-shell/gnome-shell.css` 修改 **stage** 的 `font-size` 。

[**项目地址**](https://github.com/snwh/paper-icon-theme) ，其他热门主题 [**Numix**](https://github.com/snwh/paper-gtk-theme) 、 [**Paper**](https://github.com/numixproject/numix-gtk-theme)

# Icon
## Numix
```
sudo add-apt-repository ppa:numix/ppa
sudo apt-get update
sudo apt-get install numix-icon-theme
```
**[项目地址](https://github.com/numixproject/numix-icon-theme)**

## Paper
```
sudo add-apt-repository ppa:snwh/pulp
sudo apt-get update
sudo apt-get install paper-icon-theme
# 同时也可以安装 GTK 和 Cursor 主题
sudo apt-get install paper-gtk-theme
sudo apt-get install paper-cursor-theme
```
**[项目地址](https://github.com/snwh/paper-icon-theme)**
## Papirus
```
sudo add-apt-repository ppa:papirus/papirus
sudo apt-get update
sudo apt-get install papirus-icon-theme
```
或者下载最新的 [**deb 安装包**](https://launchpad.net/~papirus/+archive/ubuntu/papirus/+packages?field.name_filter=papirus-icon-theme)
**[项目地址](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme)**

# GNOME Shell Extensions
[**Weather**](https://extensions.gnome.org/extension/613/weather/) 天气插件

[**System Monitor**](https://extensions.gnome.org/extension/1064/system-monitor/) 系统监视器

[**Topicons Plus**](https://extensions.gnome.org/extension/1031/topicons/) 任务图标栏

任务图标栏使用默认的图标，如何让他使用自定义的图标主题呢？
比如使用 **Papirus** ，它支持 `hardcode-tray` 脚本来实现
1. 安装 `hardcode-tray`
```
sudo add-apt-repository ppa:andreas-angerer89/sni-qt-patched
sudo apt update
sudo apt install sni-qt sni-qt:i386 hardcode-tray
```
2. 转换图标
```
hardcode-tray --conversion-tool Inkscape
```

[**Nvidia GPU Temperature Indicator**](https://extensions.gnome.org/extension/541/nvidia-gpu-temperature-indicator/) 显卡温度指示器

[**Dash To Dock**](https://extensions.gnome.org/extension/307/dash-to-dock/) 可定制的 Dock


