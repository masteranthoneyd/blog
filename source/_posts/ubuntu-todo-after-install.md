---
title: Ubuntu主题美化与常用软件记录
date: 2017-01-12 23:04:36
categories: [OperatingSystem,Ubuntu]
tags: [Ubuntu]
---
![](https://cdn.yangbingdong.com/img/individuation/ubuntu-desktop.png)
# 前言
>  时间已经来到了9102年, 当初的***[Ubuntu 18.04 LTS](https://www.ubuntu.com/download/desktop)*** 版本已经回归GNOME环境, 各种主题优化教程也层出不穷了, 说明 Ubuntu 的使用人群也渐渐增加...
>
>  一键安装主题软件脚本: ***[ubuntu-desktop-initializer](https://github.com/masteranthoneyd/ubuntu-desktop-initializer)***

<!--more-->

# 启动盘制作篇

## Windows中利用UltraISO制作

在Windows环境下一般是通过 ***[UltraISO](https://www.ultraiso.com/)*** 制作U盘启动盘（最好是**FAT32**格式）, 步骤通常如下（安装UltraISO前提下）: 

* 选择并打开系统镜像（iso）
* 选择 `启动` -> `写入硬盘映像` , 会弹出一个写入硬盘映像的对话框
* 选择对应U盘
* 点击 `便捷启动` -> `写入新的驱动器引导扇区` -> `Syslinux`
* 最后再点击 `写入` 等待完成即可

图就不贴了, 搜索引擎上一大堆. 

接下来要介绍的是在Linux环境中制作启动盘

## Linux中利用DD命令制作

### Step 1

U盘插入电脑后, 用`lsblk`命令查看一下

```
$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0 111.8G  0 disk 
├─sda1   8:1    0   512M  0 part /boot/efi
├─sda2   8:2    0    14G  0 part /usr
├─sda3   8:3    0    14G  0 part /opt
├─sda4   8:4    0   4.7G  0 part /boot
└─sda5   8:5    0  78.7G  0 part /home
sdb      8:16   0 931.5G  0 disk 
├─sdb1   8:17   0 745.1G  0 part /
└─sdb2   8:18   0   8.4G  0 part [SWAP]
sdc      8:32   1  14.5G  0 disk 
└─sdc4   8:36   1  14.5G  0 part /media/ybd/SSS_X64FRE_
```

很明显, `/media/ybd/SSS_X64FRE_`这个挂载的就是U盘, U盘对应的路径是`/dev/sdc`如果不确定, 可以进去看一下文件目录. 

> 找到对应的挂载目录很重要, 少有不慎, 可能会导致整个系统瘫痪 23333...........

### Step 2

需要卸载掉挂载的目录: 

```
umount /media/ybd/SSS_X64FRE_
```

再用`lsblk`确认一下

```
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0 111.8G  0 disk 
├─sda1   8:1    0   512M  0 part /boot/efi
├─sda2   8:2    0    14G  0 part /usr
├─sda3   8:3    0    14G  0 part /opt
├─sda4   8:4    0   4.7G  0 part /boot
└─sda5   8:5    0  78.7G  0 part /home
sdb      8:16   0 931.5G  0 disk 
├─sdb1   8:17   0 745.1G  0 part /
└─sdb2   8:18   0   8.4G  0 part [SWAP]
sdc      8:32   1  14.5G  0 disk 
└─sdc4   8:36   1  14.5G  0 part 
```

可以看到已经没有挂载了

### Step 3

用`dd`命令将iso映像写入U盘（一般Linux的镜像是直接将整个安装系统包括引导直接压缩进iso当中）

```
sudo dd if=ubuntu-16.04-desktop-amd64.iso of=/dev/sdc bs=1M
```

过程中不会有任何输入, 并且时间可能稍久, 完成后会输出这样的信息: 

```
/dev/sdc bs=1M
1520+0 records in
1520+0 records out
1593835520 bytes (1.6 GB) copied, 493.732 s, 3.2 MB/s
```

到此制作完成. 

## 安装建议

* 硬盘格式: GPT ; 引导类型: UEFI.
* 单系统用户, 务必准备一个 **EFI (ESP)** 分区, 否则无法写入 GRUB 引导.
* 最小安装

# 系统篇

## 换源

更换最佳源服务器, 打开 **软件和更新**（这里可以选择阿里的, 或者点击右边的 选择最佳服务器）: 

![](https://cdn.yangbingdong.com/img/individuation/source-server.png)

## 更新

之前的16.04是会安装很多用不上的软件, 好在18.04版本优化掉了, 最小安装保持干净系统

安装完系统之后, 需要更新一些补丁. `Ctrl+Alt+T`调出终端, 执行一下代码: 
```
sudo apt update && sudo apt upgrade -y && sudo apt autoremove
```
## 关掉sudo的密码

先修改默认编辑器为vim（默认为nano）: 

```
sudo update-alternatives --config editor
```

输入vim对应的序号回车即可

打开 `visudo`:

```
sudo visudo
```

找到

```
%sudo   ALL=(ALL:ALL) ALL
```

修改为

```
%sudo   ALL=(ALL:ALL) NOPASSWD:ALL
```

这样所有sudo组内的用户使用sudo时就不需要密码了. 

## exfat驱动

```
sudo apt install exfat-fuse exfat-utils
```

## 统一Win10和Ubuntu18.04双系统的时间

> 双系统导致的时间不统一.

```
timedatectl set-local-rtc 1 --adjust-system-clock
```

## Apt Fast

> ***[https://github.com/ilikenwf/apt-fast](https://github.com/ilikenwf/apt-fast)***
>
> apt-fast 是一个为 `apt-get` 和 `aptitude` 做的 **shell 脚本封装**，通过对每个包进行并发下载的方式可以大大减少 APT 的下载时间。apt-fast 使用 **aria2c** 下载管理器来减少 APT 下载时间。就像传统的 apt-get 包管理器一样，apt-fast 支持几乎所有的 apt-get 功能，如， `install` , `remove` , `update` , `upgrade` , `dist-upgrade` 等等，并且更重要的是它也支持 proxy。

```
sudo add-apt-repository -y ppa:apt-fast/stable && \
sudo apt install -y apt-fast
```

之后就可以用 `apt-fast`  代替 `apt` 或 `apt-get` 命令了.

## Gdebi

有时候安装deb包不满足依赖还需要手动执行`sudo apt install -f`, 我们可以使用`gdebi`解决这个问题:

```
sudo apt install gdebi
```

之后使用`sudo gdebi xxx.deb`安装即可

## Snap

```
sudo apt install -y snapd
```

### 配置代理

```
sudo systemctl edit snapd.service
```

```
[Service]
Environment=http_proxy=http://proxy:port
Environment=https_proxy=http://proxy:port
```

```
sudo systemctl daemon-reload
sudo systemctl restart snapd.service
```

### 常用命令

```
# 列出已经安装的snap包
sudo snap list

# 搜索要安装的snap包
sudo snap find <text to search>

# 安装一个snap包
sudo snap install <snap name>

# 更新一个snap包，如果你后面不加包的名字的话那就是更新所有的snap包
sudo snap refresh <snap name>

# 把一个包还原到以前安装的版本
sudo snap revert <snap name>

# 删除一个snap包
sudo snap remove <snap name>
```

## 关闭 avahi-daemon 服务

`avahi-daemon` 造成过网络异常，用处也不大，停止服务并关闭开机启动：

```shell
sudo systemctl stop avahi-daemon.socket
sudo systemctl stop avahi-daemon.service
sudo /lib/systemd/systemd-sysv-install disable avahi-daemon

sudo systemctl disable avahi-daemon.socket
sudo systemctl disable avahi-daemon.service
```

## 显卡驱动

查看可安装显卡:

```
ubuntu-drivers devices
```

安装:

```
# 安装系统推荐驱动
sudo ubuntu-drivers autoinstall

# 安装指定驱动
sudo apt install nvidia-340
```

安装Beta版本驱动:

```
sudo add-apt-repository ppa:graphics-drivers/ppa -y

# 再次查看可安装的显卡驱动
ubuntu-drivers devices
```

输出如下:

```
$ ubuntu-drivers devices
== /sys/devices/pci0000:00/0000:00:01.0/0000:01:00.0 ==
modalias : pci:v000010DEd00001380sv00001458sd0000362Dbc03sc00i00
vendor   : NVIDIA Corporation
model    : GM107 [GeForce GTX 750 Ti]
driver   : nvidia-driver-396 - third-party free
driver   : nvidia-340 - distro non-free
driver   : nvidia-driver-390 - distro non-free
driver   : nvidia-driver-410 - third-party free
driver   : nvidia-driver-418 - third-party free recommended
driver   : nvidia-driver-415 - third-party free
driver   : xserver-xorg-video-nouveau - distro free builtin
```

安装:

```
sudo ubuntu-drivers autoinstall  # sudo apt install nvidia-418
```

重启后生效.

# 主题美化篇

推荐一个网站 ***[Gnome Look](https://www.gnome-look.org/)***, 这里面有大量的主题, 并且都是以压缩包形式的.

- 主题存放目录：`/usr/share/themes` 或 `~/.themes`
- 图标存放目录：`/usr/share/icons` 或 `~/.icons`
- 字体存放目录：`/usr/share/fonts` 或 `~/.fonts`

其中 `/usr/share` 目录需要 root 权限才能修改，可以对文件管理提权后打开：

```text
sudo nautilus
```

 并且注意一下解压后shell的主题文件夹的二级目录应该是`/gnome-shell`, 然后分别放到对应的目录, 就能在**gnome-tweak**工具里面识别了

## GNOME美化

### 依赖安装

```
sudo apt install -y \
gnome-tweak-tool \
gnome-shell-extensions \
chrome-gnome-shell \
gtk2-engines-pixbuf \
libxml2-utils
```

### 主题

#### Sierra-gtk-theme

> ***[https://github.com/vinceliuice/Sierra-gtk-theme](https://github.com/vinceliuice/Sierra-gtk-theme)***

这是一款类苹果的主题...

```
sudo add-apt-repository -y ppa:dyatlov-igor/sierra-theme
sudo apt install sierra-gtk-theme
```

#### Flatabulous

`Flatabulous`主题是一款`Ubuntu`下扁平化主题.

执行以下命令安装`Flatabulous`主题: 

```
sudo add-apt-repository ppa:noobslab/themes 
sudo apt update 
sudo apt install flatabulous-theme
```

该主题有配套的图标, 安装方式如下: 
```
sudo add-apt-repository ppa:noobslab/icons 
sudo apt update 
sudo apt install ultra-flat-icons
```

#### Arc-Theme

> ***[https://github.com/horst3180/arc-theme](https://github.com/horst3180/arc-theme)***

这也是一款很漂亮的主题

```
sudo apt install arc-theme
```

#### Sweet

***[https://www.gnome-look.org/p/1253385/](https://www.gnome-look.org/p/1253385/)***

### 图标

#### Suru Plus

> ***[https://www.opendesktop.org/p/1210408/](https://www.opendesktop.org/p/1210408/)***

```
wget -qO- https://raw.githubusercontent.com/gusbemacbe/suru-plus/master/install.sh | sh
```

更换文件夹颜色(***[https://github.com/gusbemacbe/suru-plus-folders/blob/master/languages/en.md](https://github.com/gusbemacbe/suru-plus-folders/blob/master/languages/en.md)***):

```
# 安装
curl -fsSL https://raw.githubusercontent.com/gusbemacbe/suru-plus-folders/master/install.sh | sh
# 查看颜色
suru-plus-folders -l --theme Suru++
# 更换
suru-plus-folders -C cyan --theme Suru++
```

#### Papirus

```
sudo add-apt-repository -y ppa:papirus/papirus
sudo apt install papirus-icon-theme
```

或者下载最新的 [**deb 安装包**](https://launchpad.net/~papirus/+archive/ubuntu/papirus/+packages?field.name_filter=papirus-icon-theme)
***[项目地址](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme)***

#### Paper

```
sudo add-apt-repository -y ppa:snwh/pulp
sudo apt install paper-icon-theme
# 同时也可以安装 GTK 和 Cursor 主题
sudo apt install paper-gtk-theme
sudo apt install paper-cursor-theme
```

**[项目地址](https://github.com/snwh/paper-icon-theme)**

### 光标

#### Capitaine Cursors

> ***[https://www.gnome-look.org/p/1148692/](https://www.gnome-look.org/p/1148692/)***

```
sudo add-apt-repository -y ppa:dyatlov-igor/la-capitaine
sudo apt install -y la-capitaine-cursor-theme
```

#### Oxy Blue

***[https://www.opendesktop.org/p/1274872/](https://www.opendesktop.org/p/1274872/)***

下载后解压到 `/usr/share/themes` 目录下

## GNOME Extensions

> Ubuntu 18.04 抛弃了 Unity 桌面转而使用 Gnome ，所以 Gnome 桌面下的一些 Shell 扩展在 Ubuntu 18.04 中就可以使用了。

先上图...

![](https://cdn.yangbingdong.com/img/gnome/desktop1.png)

![](https://cdn.yangbingdong.com/img/gnome/desktop2.png)

### Chrome Gnome Shell

首先安装 Chrome Gnome Shell ：

```
sudo apt install chrome-gnome-shell
```

然后安装浏览器插件（**谷歌浏览器**）：[Chrome 网上应用商店](https://chrome.google.com/webstore/detail/gnome-shell-integration/gphhapmejobijbbhgpjhcjognlahblep)

浏览器插件安装完成后点击 *插件图标* 就能进入：**[Shell 扩展商店](https://extensions.gnome.org/)**

### Dash To Dock

**[Dash To Dock](https://extensions.gnome.org/extension/307/dash-to-dock/)**: 虽然Ubuntu18已经有了一个Dock, 但定制性不强. 这个Dock插件提供了很多选项定制, 个人比较喜欢的一个选项就是隔离工作区. 

![](https://cdn.yangbingdong.com/img/gnome/dock02.png)

![](https://cdn.yangbingdong.com/img/gnome/dock01.png)

### Topicons Plus

[**Topicons Plus**](https://extensions.gnome.org/extension/1031/topicons/) 任务图标栏

任务图标栏使用默认的图标, 如何让他使用自定义的图标主题呢？
比如使用 **Papirus** , 它支持 `hardcode-tray` 脚本来实现

1. 安装 `hardcode-tray`

```
sudo add-apt-repository ppa:andreas-angerer89/sni-qt-patched
sudo apt update
sudo apt install sni-qt sni-qt:i386 hardcode-tray inkscape
```

2. 转换图标

```
hardcode-tray --conversion-tool Inkscape
```

### Nvidia GPU Temperature Indicator

[**Nvidia GPU Temperature Indicator**](https://extensions.gnome.org/extension/541/nvidia-gpu-temperature-indicator/) 显卡温度指示器

### User Themes

**[User Themes](https://extensions.gnome.org/extension/19/user-themes/)** 可以使用shell-theme: 

![](https://cdn.yangbingdong.com/img/individuation/user-themes.png)

### Other

**以下是其他的Gnome 扩展推荐** :

| 扩展                                                         | 简要功能描述                       |
| ------------------------------------------------------------ | ---------------------------------- |
| ***[Applications Menu](https://extensions.gnome.org/extension/6/applications-menu/)*** | 在顶部添加一个应用程序入口         |
| ***[Coverflow Alt-Tab](https://extensions.gnome.org/extension/97/coverflow-alt-tab/)*** | Alt Tab 切换应用（更酷炫的界面）   |
| ***[Dash to Dock](https://extensions.gnome.org/extension/307/dash-to-dock/)*** | Dock （大名鼎鼎）                  |
| ***[Dash to Panel](https://extensions.gnome.org/extension/1160/dash-to-panel/)*** | 对顶栏的操作处理（诸如自动隐藏等） |
| ***[EasyScreenCast](https://extensions.gnome.org/extension/690/easyscreencast/)*** | 录屏工具（录制质量优秀）           |
| ***[Extension update notifier](https://extensions.gnome.org/extension/1166/extension-update-notifier/)*** | 自动推送所有扩展的更新信息         |
| ***[Internet speed meter](https://extensions.gnome.org/extension/1461/internet-speed-meter/) / [NetSpeed](https://extensions.gnome.org/extension/104/netspeed/)*** | 顶栏显示当前网络速度               |
| ***[OpenWeather](https://extensions.gnome.org/extension/750/openweather/)*** | 顶栏显示天气情况（支持中文）       |
| ***[Dynamic Top Bar](https://extensions.gnome.org/extension/885/dynamic-top-bar/)*** | 动态调整状态栏透明度               |
| ***[Places Status Indicator](https://extensions.gnome.org/extension/8/places-status-indicator/)*** | 提供快捷目录入口（同文件管理器）   |
| ***[Popup dict Switcher](https://extensions.gnome.org/extension/1349/popup-dict-switcher/)*** | 一键开关划词翻译                   |
| ***[Removable Drive Menu](https://extensions.gnome.org/extension/7/removable-drive-menu/)*** | 移除可移动设备                     |
| ***[Screenshot Tool](https://extensions.gnome.org/extension/1112/screenshot-tool/)*** | 截图工具（挺方便）                 |
| ***[Sound Input & Output Device Chooser](https://extensions.gnome.org/extension/906/sound-output-device-chooser/)*** | 更方便的调整声音、亮度             |
| ***[System-monitor](https://extensions.gnome.org/extension/120/system-monitor/) / [System-monitor](https://extensions.gnome.org/extension/1064/system-monitor/)*** | 在状态栏中显示系统信息（很多类型） |

> 若出现安装失败，请检查 **是否满足相关依赖** 。

## Oh-My-Zsh

### 安装


终端采用`zsh`和`oh-my-zsh`, 既美观又简单易用, 主要是能提高你的逼格！！！

首先, 安装`zsh`: 

```
sudo apt-get install zsh
```

接下来我们需要下载 `oh-my-zsh` 项目来帮我们配置 `zsh`, 采用`wget`安装(需要先安装`git`)
```bash
sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
```

重启后生效.

### 语法高亮

安装插件`highlight`, **高亮语法**: 

```
cd ~/.oh-my-zsh/custom/plugins &&\
git clone git://github.com/zsh-users/zsh-syntax-highlighting.git
```

在`Oh-my-zsh`的配置文件中`~/.zshrc`中添加插件

```
plugins=( [plugins...] zsh-syntax-highlighting)
```

重新打开终端即可生效！

### 调色

最后, 修改以下配色, 会让你的终端样式看起来更舒服, 在终端任意地方右键, 进入配置文件(`profile`)->外观配置(`profile Preferences`), 弹出如下界面, 进入`colors`一栏:
![](https://cdn.yangbingdong.com/img/individuation/zsh02.png)


其中, 文字和背景采用系统主题, 透明度设为10%, 下面的`palette`样式采用`Tango`, 这样一通设置后, 效果如下: 
![](https://cdn.yangbingdong.com/img/individuation/screenfetch.png)

**推荐配色**: 

- 文本颜色: `#00FF00`
- 粗体字颜色: 与文本颜色相同
- 背景颜色: `#002B36`

### 主题

在`~/.oh-my-zsh/themes`中查看主题. 

然后编辑`~/.zshrc`, 找到`ZSH_THEME`修改为你想要的主题即可（感觉`ys`这个主题不错）. 

`agnoster`, *[bullet-train](https://github.com/caiogondim/bullet-train.zsh)* 这两款主题也不错, 但需要先安装一些 *[字体样式](https://github.com/powerline/fonts)*: 

```
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts
```

**装完后需要在终端配置Powerline字体**.

其他主题:

***[https://github.com/bhilburn/powerlevel9k](https://github.com/bhilburn/powerlevel9k)***

## 字体

`Ubuntu`自带的字体不太好看, 所以采用**文泉译微米黑/正黑**替代, 效果会比较好, 毕竟是国产字体！

```
sudo apt install fonts-wqy-microhei fonts-wqy-zenhei
```

然后通过`gnome-tweak-tool`来替换字体

## GRUB 2 主题

> 由于安装了多系统, 恰好Ubuntu的GRUB2提供了切换系统的选择, 但是界面不咋样

前往 ***[https://www.gnome-look.org/browse/cat/109/](https://www.gnome-look.org/browse/cat/109/)*** 选择一款合适自己的主题安装

博主推荐 ***[Grub-theme-vimix](https://www.gnome-look.org/p/1009236/)***  ***[Blur grub](https://www.gnome-look.org/p/1220920/)*** 或者 [***fallout-grub-theme***](https://github.com/shvchk/fallout-grub-theme)

![](https://cdn.yangbingdong.com/img/gnome/stylish.png)

根据提示下载源码执行安装脚本即可. 



但某些主题只提供主题包并没有安装脚本, 则我们需要**手动安装**:

首先下载主题包，多为压缩包，解压出文件。使用 `sudo nautilus` 打开文件管理器。

定位到目录：`/boot/grub`，在该目录下 **新建文件夹** ：`themes`，把解压出的文件拷贝到文件夹中。

- **方案一：手写配置文件**

接着（终端下）使用 gedit 修改 *grub* 文件：

```
sudo gedit /etc/default/grub
```

在该文件末尾添加：

```
# GRUB_THEME="/boot/grub/themes/主题包文件夹名称/theme.txt"
GRUB_THEME="/boot/grub/themes/fallout-grub-theme-master/theme.txt"
```

- **方案二：利用软件 Grub Customizer**

添加 PPA ：

```
sudo add-apt-repository ppa:danielrichter2007/grub-customizer
```

安装软件：

```
sudo apt install grub-customizer
```

- **最后** 更新配置文件：

```
sudo update-grub
```

> 谈到 grub 就不得不谈到 `/boot/grub/grub.cfg` ，这个文件才是事实上的配置文件，所谓更新就是重新生成 *grub.cfg* 。

## GDM 登录背景图

> 更多GDM主题请看 ***[https://www.pling.com/s/Gnome/browse/cat/131/order/latest/](https://www.pling.com/s/Gnome/browse/cat/131/order/latest/)***
>
> 修改之前可以备份一下`ubuntu.css`文件, 避免错了改不会来...

更换登录界面的背景图需要修改文件 `ubuntu.css`，它位于 `/usr/share/gnome-shell/theme` 。

```
sudo gedit /usr/share/gnome-shell/theme/ubuntu.css
```

在文件中找到关键字 `lockDialogGroup`，如下行：

```
#lockDialogGroup {
   background: #2c001e url(resource:///org/gnome/shell/theme/noise-texture.png);
   background-repeat: repeat; }
```

修改图片路径即可，样例如下：

```
#lockDialogGroup {
  background: #2c001e url(file:///home/ybd/data/pic/spain.jpg);
  background-repeat: no-repeat;
  background-size: cover;
  background-position: center; }
```

其中`file:///home/ybd/data/pic/spain.jpg`为图片路径.

## 开机动画

> 查找喜欢的开机动画: ***[https://www.gnome-look.org/browse/cat/108/order/latest](https://www.gnome-look.org/browse/cat/108/order/latest)***

几个不错的动画:

- *[UbuntuStudio - Suade](https://www.gnome-look.org/p/1176419/)*
- *[Mint Floral](https://www.gnome-look.org/p/1156215/)*
- *[ArcOS-X-Flatabulous](https://www.gnome-look.org/p/1215618/)*

下面说安装流程:

1. 首先下载并解压自己喜欢的开机动画;

2. 把解压后的文件夹复制到 `/usr/share/plymouth/themes/` 文件夹下;

   ```
   sudo cp ${caton-path} /usr/share/plymouth/themes/ -r
   ```

3. 编辑配置文件:

   ```
   sudo gedit /etc/alternatives/default.plymouth
   ```

   把后两行修改为:

   ```
   [script]
   ImageDir=/usr/share/plymouth/themes/${theme-directory}
   ScriptFile=/usr/share/plymouth/themes/${theme-directory}/${script-file-name}
   ```

   其中:

   - `${theme-directory}` 是你的主题文件夹名;
   - `${script-file-name}` 是主题文件夹下后缀为 `.script` 文件的文件名.

4. 重启即可.

## 动态桌面

在 Windows 中有 **Wallpaper Engine**, 收费的. 但在 Linux 中有一款开源的动态桌面软件 ***[komorebi](https://github.com/cheesecakeufo/komorebi)*** .

在 ***[releases](https://github.com/cheesecakeufo/komorebi/releases)*** 页面中下载 deb 包安装即可.

依赖:

```
sudo apt install -y libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-doc gstreamer1.0-tools
```

安装完后在启动器中搜索 `komorebi`, 除了看到 `komorebi` 之外还有一个 `Wallpaper Creator`, 这个是用来制作动态桌面壁纸的.

之后直接打开 `komorebi` 即可, 在桌面上右键即可打开菜单进行配置.

效果:

![](https://cdn.yangbingdong.com/img/gnome/dynamic-desktop.gif)

附动画: ***[https://cdn.yangbingdong.com/resource/desktop/%E5%96%84%E9%80%B8.zip](https://cdn.yangbingdong.com/resource/desktop/%E5%96%84%E9%80%B8.zip)***

## 壁纸推荐

推荐几个不错的壁纸下载网站: 

* ***[https://wallpapershome.com](https://wallpapershome.com)***

* ***[https://pixabay.com](https://pixabay.com)***

* ***[https://alpha.wallhaven.cc/](https://alpha.wallhaven.cc/)***

  

# 软件篇

> Java开发者的环境搭建请看: ***[Ubuntu的Java开发环境基本搭建](/2017/ubuntu-dev-environment-to-build/)***

## 搜狗输入法

卸载ibus. 

```
sudo apt-get remove ibus
```

清除ibus配置. 

```
sudo apt-get purge ibus
```

卸载顶部面板任务栏上的键盘指示. 

```
sudo  apt-get remove indicator-keyboard
```

安装fcitx输入法框架

```
sudo apt install fcitx-table-wbpy fcitx-config-gtk
```

切换为 Fcitx输入法

```
im-config -n fcitx
```

im-config 配置需要重启系统才能生效

```
sudo shutdown -r now
```

点击下载 Sogou For Linux -> <a id="download" href="http://pinyin.sogou.com/linux/"><i class="fa fa-download"></i><span> Download Now</span>
</a>

```
wget http://cdn2.ime.sogou.com/dl/index/1524572264/sogoupinyin_2.2.0.0108_amd64.deb?st=ryCwKkvb-0zXvtBlhw5q4Q&e=1529739124&fn=sogoupinyin_2.2.0.0108_amd64.deb
```

安装搜狗输入法

```
sudo dpkg -i sogoupinyin_2.2.0.0108_amd64.deb
```

修复损坏缺少的包

```
sudo apt-get install -f
```

打开 Fcitx 输入法配置

```
fcitx-config-gtk3
```

问题: 输入法皮肤透明

```
fcitx设置 >> 附加组件 >> 勾选高级 >> 取消经典界面

Configure>>  Addon  >>Advanced>>Classic
```

再次重启. 

## 跨平台终端工具 Tabby

***[https://tabby.sh/](https://tabby.sh/)***

## Deepin Wine For Ubuntu

这个项目是 Deepin-wine 环境的 Ubuntu 移植版, 可以在 Ubuntu 上运行 Tim, 微信, 网易云音乐, 百度云网盘, 迅雷等 Windows 软件: ***[https://github.com/wszqkzqk/deepin-wine-ubuntu](https://github.com/wszqkzqk/deepin-wine-ubuntu)***

```bash
git clone https://gitee.com/wszqkzqk/deepin-wine-for-ubuntu.git
cd deepin-wine-for-ubuntu
./install.sh
```

>  **关于托盘**：安装 *TopIconPlus* 的 gnome-shell 扩展。
>
>  然后在所有软件中找到 **优化 (Gnome-tweak-tool)** ，在扩展中打开 *Topicons plus* 。

在 ***[https://mirrors.aliyun.com/deepin/pool/non-free/d/](https://mirrors.aliyun.com/deepin/pool/non-free/d/)*** 中寻找需要的软件, 使用 `dpkg` 安装即可.

### 企业微信

***[https://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.weixin.work/](https://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.weixin.work/)***

安装完需要安装一下这个依赖, 不要会出现cpu彪高以及图片不能正常展示的问题:

```
sudo apt install libjpeg62:i386
```

### Wechat

***[https://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.wechat/](https://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.wechat/)***

### 微信开发者工具

***[https://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.wechat.devtools/](https://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.wechat.devtools/)***

确保安装了依赖:

```
sudo apt-get install libxtst6:i386
```

### QQ

***[https://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.qq.im/](https://mirrors.aliyun.com/deepin/pool/non-free/d/deepin.com.qq.im/)***

## GUI-SmartGit

git的一个GUI:

```
sudo add-apt-repository ppa:eugenesan/ppa
sudo apt update
sudo apt install smartgithg
```
## SVN GUI-SmartSVN

下载地址: ***[https://www.smartsvn.com/download/](https://www.smartsvn.com/download/)***

`smartsvn.license`:

```
Name=csdn  
Address=1337 iNViSiBLE Str.  
Email=admin@csdn.net  
FreeUpdatesUntil=2099-09-26  
LicenseCount=1337  
Addon-xMerge=true  
Addon-API=true  
Enterprise=true  
Key=4kl-<Zqcm-iUF7I-IVmYG-XAyvv-KYRoC-xlgsv-sSBds-VAnP6
```

注册时, 选中上面文件就OK了.

## Typora(Markdown编辑器)

*[官方](https://typora.io/#linux)* 安装方法如下: 

```
wget -qO - https://typora.io/linux/public-key.asc | sudo apt-key add -
sudo add-apt-repository -y 'deb https://typora.io/linux ./'
sudo apt install typora
```

如果加粗或斜体没有正确显示, 需要编辑 `github.css`(默认主题是Github), 将 `body` 标签中 `Open Sans` 改为 `Open Sans Regular`

## GIF制作软件 Peek

```
sudo add-apt-repository ppa:peek-developers/stable
sudo apt update
sudo apt install peek
```

终端执行`peek`即可运行

## KVM

KVM要求我们的CPU支持硬件虚拟化(hardware virtualization)．在终端里输入下面的命令来查看CPU是否支持硬件虚拟化: 

```
egrep -c '(svm|vmx)' /proc/cpuinfo
```

如果上面的命令返回数字０, 就表示CPU不支持硬件虚拟化, 那么我们就只能使用[Virtualbox](http://www.linuxdashen.com/category/virtualbox)或VMware来创建虚拟机了．如果返回的数字大于０, 那么表示CPU支持硬件虚拟化, 我们就能使用KVM来创建虚拟机．

安装: 

```
sudo apt install qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils virt-manager virtinst virt-viewer
```

Dash里打开virt-manager:

![](https://cdn.yangbingdong.com/img/individuation/kvm-manager.png)



## SecureCRT

### Install

官方下载地址（选择Linux版deb包）: ***[https://www.vandyke.com/download/securecrt/download.html](https://www.vandyke.com/download/securecrt/download.html)***

```
sudo dpkg -i scrt-8.3.2-1584.ubuntu16-64.x86_64.deb
```

### Crack

准备: 

```
wget http://download.boll.me/securecrt_linux_crack.pl && \
sudo apt install perl
```

查看一下SecureCRT的安装路径: 

```
whereis SecureCRT

# 不出意外应该是在 /usr/bin/SecureCRT
```

运行perl脚本: 

```
sudo perl securecrt_linux_crack.pl /usr/bin/SecureCRT
```

![](https://cdn.yangbingdong.com/img/individuation/securecrt-crack.png)

然后按照提示手动输入License即可

## WPS
去 *[wps官网](http://linux.wps.cn/)* 下载wps for Linux. 
先不要执行dpkg -i 去执行安装. 这个地方有个问题, 就是ubuntu 16 版本不支持32位的支持库, 所以需要安装一下支持库. 
32位的支持库名为: ia32-libs
安装的时候会提示有替代包, 需要安装替代包. 

```bash
sudo apt install lib32ncurses5 lib32z1
```
还是不要执行dpkg -i , 因为即使现在安装还是会缺少一个依赖. 这个依赖是libpng-12.0. 不过这个在默认的apt 仓库里没有. 所以需要手动下载一下. 
下载地址: ***[https://packages.debian.org/zh-cn/wheezy/amd64/libpng12-0/download](https://packages.debian.org/zh-cn/wheezy/amd64/libpng12-0/download)***

```bash
sudo dpkg -i libpng12-0_1.2.49-1+deb7u2_amd64.deb
```
最后: 
```bash
sudo dpkg -i wps-office_10.1.0.5672~a21_amd64.deb
```

## 数据库建模工具

### PDMan

***[http://www.pdman.cn/#/downLoad](http://www.pdman.cn/#/downLoad)***

在线打开 pmd 文件:

***[http://www.dmanywhere.cn/](http://www.dmanywhere.cn/)***

## 有道云笔记客户端

官方并没有停 Linux 的客户端, 但 Github 有非官方的开源版:

***[https://github.com/jamasBian/youdao-note-electron](https://github.com/jamasBian/youdao-note-electron)***

## 坚果云同步

***[官网下载](https://www.jianguoyun.com/s/downloads/linux)***

```
sudo gdebi  nautilus_nutstore_amd64.deb
```

## Chrome

到*[chrome官网](https://www.google.com/chrome/browser/desktop/index.html)* 下载linux版的chrome. 
不能翻墙的小朋友可以到***[博主的百度盘](https://pan.baidu.com/s/1c2uyTEw)*** (密码: 9bpi)
```
sudo dpkg -i google-chrome-stable_current_amd64.deb
```

或者通过apt安装:

```
sudo wget https://repo.fdzh.org/chrome/google-chrome.list -P /etc/apt/sources.list.d/ && \
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub  | sudo apt-key add - && \
sudo apt update && \
sudo apt install google-chrome-stable
```

### Extensions

推荐几个不错的Chrome扩展:

| 插件                                                         | 说明                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| ***[Proxy SwitchyOmega](https://chrome.google.com/webstore/detail/proxy-switchyomega/padekgcemlokbadohgkifijomclgjgif)*** | 谁用谁知道...                                                |
| ***[Axure RP Extension for Chrome](https://chrome.google.com/webstore/detail/axure-rp-extension-for-ch/dogkpdfcklifaemcdfbildhcofnopogp)*** | 可以打开Axure原型文件                                        |
| ***[GNOME Shell integration](https://chrome.google.com/webstore/detail/gnome-shell-integration/gphhapmejobijbbhgpjhcjognlahblep)*** | 可用过Chrome扩展Gnome插件                                    |
| ***[Adblock Plus](https://chrome.google.com/webstore/detail/adblock-plus-free-ad-bloc/cfhdojbkjhnklbpkdaibdccddilifddb)*** | 广告拦截                                                     |
| ***[Google translate](https://chrome.google.com/webstore/detail/google-translate/aapbdbdomjkkjkaonfhkkikfgjllcleb)*** | 谷歌翻译                                                     |
| ***[ElasticSearch Head](https://chrome.google.com/webstore/detail/elasticsearch-head/ffmkiejjmecolpfloofpjologoblkegm)*** | ElasticSearch Head Chome插件                                 |
| ***[BaiduExporter](https://github.com/acgotaku/BaiduExporter)*** | 导出百度盘链接                                               |
| ***[Octotree](https://chrome.google.com/webstore/detail/octotree/bkhaagjahfmjljalopjnoealnfndnagc)*** | Github左侧展示树状结构                                       |
| ***[Enhanced Github](https://chrome.google.com/webstore/detail/enhanced-github/anlikcnbgdeidpacdbdljnabclhahhmd)*** | 可下载Github中单个文件                                       |
| ***[Tampermonkey](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo)*** | 油猴, 脚本网站: *[https://greasyfork.org/zh-CN](https://greasyfork.org/zh-CN)*, *[https://openuserjs.org/](https://openuserjs.org/)* |
| ***[CrxMouse Chrome™ Gestures](https://chrome.google.com/webstore/detail/crxmouse-chrome-gestures/jlgkpaicikihijadgifklkbpdajbkhjo)*** | 高度可自定义的鼠标手势, 超级拖拽, 鼠标滚轮手势, 遥感手势, 提升工作效率 |
| ***[掘金](https://chrome.google.com/webstore/detail/%E6%8E%98%E9%87%91/lecdifefmmfjnjjinhaennhdlmcaeeeb)*** | 为程序员、设计师、产品经理每日发现优质内容                   |
| ***[Atom File Icons Web](https://chrome.google.com/webstore/detail/atom-file-icons-web/pljfkbaipkidhmaljaaakibigbcmmpnc)*** | 修改 Github 或者 Bitbucket 上面的图标                        |

## 截图

### Shutter

`Ubuntu`下很强大的一款截图软件

```
sudo apt install shutter
```

**设置快捷键: **
打开系统设置 -> `键盘` -> `快捷键` -> `自定义快捷键` -> `点击" + " `
名字随便起, 命令: `shutter -s`
点击确定, 再点禁用, 键盘按下`ctrl+alt+a`, 完成设置

#### 编辑按钮变成程灰色解决方法

需要3个deb包: 

*[libgoocanvas-common](https://launchpad.net/ubuntu/+archive/primary/+files/libgoocanvas-common_1.0.0-1_all.deb)*

*[libgoocanvas3](https://launchpad.net/ubuntu/+archive/primary/+files/libgoocanvas3_1.0.0-1_amd64.deb)*

*[libgoo-canvas-perl](https://launchpad.net/ubuntu/+archive/primary/+files/libgoo-canvas-perl_0.06-2ubuntu3_amd64.deb)*

或者: ***[博主的百度盘](https://pan.baidu.com/s/1c2uyTEw)*** (密码: 9bpi) (提取路径: `UbuntuTools -> shutter-1804-editor.zip`)

依次使用`dpkg`命令安装, 报错使用`sudo apt-get -f install`修复

最后重启Shutter进程就好了

### Deepin Screenshot

这个是Deepin开发的截图工具, 目前已经可以在软件商店中找到:

```
sudo apt install deepin-screenshot
```

然后跟上面的Shutter一样设置快捷键就可以了, 命令是`deepin-screenshot`

## 系统清理软件 BleachBit

```
sudo apt install -y bleachbit
```

## 下载相关

### 多协议下载器 Aria2

> aria2: ***[https://github.com/aria2/aria2](https://github.com/aria2/aria2)***
>
> 部分使用说明: ***[https://aria2c.com/usage.html](https://aria2c.com/usage.html)***

一般在Linux环境中下载东西都是比较不友好的, 不支持多种协议, 方式单一, 但这款Aria2就是为了解决多协议问题而诞生的, 配合UI界面可以很方便地~~随心所欲~~地下载. 

#### 直接安装

```
sudo apt install aria2
```

添加配置文件:

```
sudo mkdir /etc/aria2
sudo touch /etc/aria2/aria2.session
sudo chmod 777 /etc/aria2/aria2.session
sudo gedit /etc/aria2/aria2.conf
```

配置文件可参考: ***[https://github.com/fsaimon/aria2.conf](https://github.com/fsaimon/aria2.conf)***

后台运行:

```
sudo aria2c --conf-path=/etc/aria2/aria2.conf -D
```

#### GUI

1. ***[Uget](https://ugetdm.com/)***
2. chrome 扩展 ***[YAAW for Chrome](https://chrome.google.com/webstore/detail/yaaw-for-chrome/dennnbdlpgjgbcjfgaohdahloollfgoc)***

#### 通过 Docker 搭建 Aria2 以及 AriaNg Web UI

![](https://cdn.yangbingdong.com/img/individuation/aria2-ariaNg.jpg)

> 博主选择使用Docker

参考 *[aria2-ariang-docker](https://github.com/wahyd4/aria2-ariang-docker)* 以及 *[aria2-ariang-x-docker-compose](https://github.com/wahyd4/aria2-ariang-x-docker-compose)*

##### 配置`aria2.conf`

这个文件是从作者地 Github下载下来的, 主要加了代理, 而这个代理是 `sock5` 通过 `privoxy`

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
min-split-size=2M
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
enable-mmap=true
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
bt-tracker=udp://tracker.leechers-paradise.org:6969/announce, udp://tracker.internetwarriors.net:1337/announce, udp://tracker.opentrackr.org:1337/announce, udp://9.rarbg.to:2710/announce, udp://tracker.coppersurfer.tk:6969/announce, udp://exodus.desync.com:6969/announce, udp://explodie.org:6969/announce, http://tracker3.itzmx.com:6961/announce, udp://tracker1.itzmx.com:8080/announce, udp://tracker.tiny-vps.com:6969/announce, udp://thetracker.org:80/announce, udp://open.demonii.si:1337/announce, udp://denis.stalker.upeer.me:6969/announce, udp://bt.xxx-tracker.com:2710/announce, http://tracker4.itzmx.com:2710/announce, udp://tracker2.itzmx.com:6961/announce, udp://tracker.torrent.eu.org:451/announce, udp://tracker.port443.xyz:6969/announce, udp://tracker.cyberia.is:6969/announce, udp://open.stealth.si:80/announce
```

##### 使用h5ai作为文件管理器

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

![](https://cdn.yangbingdong.com/img/individuation/h5ai.jpg)

1. 查看文件h5ai： *[http://localhost:8000](http://localhost:8000/)*
2. AriaNg： *[http://localhost:8000/aria2/](http://localhost:8000/aria2/)* 注意地址后面一定要带`/` 

### Motrix

***[https://github.com/agalwood/Motrix](https://github.com/agalwood/Motrix)***

### 其他下载器

一款跨平台的快速，简单，干净的视频下载器：Annie，支持Bilibili/Youtube等多个网站: ***[https://github.com/iawia002/annie](https://github.com/iawia002/annie)***

一款开源、免费带Web面板的多功能下载神器: ***[https://github.com/pyload/pyload](https://github.com/pyload/pyload)***

### 磁力搜

磁力链接聚合搜索: ***[https://github.com/xiandanin/magnetW](https://github.com/xiandanin/magnetW)***

**注意**: 这个默认需要9000端口, 所以打开前确保9000端口没有被占用.

### bugstag

***[https://github.com/gxtrobot/bustag](https://github.com/gxtrobot/bustag)***

## 百度网盘相关

### BaiduExporter

> 官方是这么说明的
>
> * Chrome : Click Settings -> Extensions, drag BaiduExporter.crx file to the page, install it, or check Developer mode -> Load unpacked extension, navigate to the chrome/release folder.
> * Firefox : Open about:debugging in Firefox, click "Load Temporary Add-on" and navigate to the chrome/release folder, select manifest.json, click OK.

1、到 *[Github](https://github.com/acgotaku/BaiduExporter)* 下载源码

2、打开Chrome -> 扩展程序 -> 勾选开发者模式 -> 加载已解压的扩展程序 , 然后会弹出文件框, 找到刚才下载的源码, 找到chrome -> release, 添加成功！

3、打开百度云盘网页版, 勾选需要下载的文件, 在上方会出现导出下载地选项, 通过设置可以修改RCP地址

![](https://cdn.yangbingdong.com/img/individuation/baiduexporter1.jpg)
![](https://cdn.yangbingdong.com/img/individuation/baiduexporter2.jpg)

### BaiduPCS-Go

这里还有一个很有意思的通过终端与百度盘交互的项目: ***[https://github.com/iikira/BaiduPCS-Go](https://github.com/iikira/BaiduPCS-Go)***

### 百度网盘直接下载助手

1、安装 *[Tampermonkey](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo?hl=zh-CN)* Chrome插件, 这个主要是管理脚本的, 下面安装百度云盘脚本需要用到

2、进入 *[百度网盘直接下载助手(显示直接下载入口)](https://greasyfork.org/zh-CN/scripts/36549-%E7%99%BE%E5%BA%A6%E7%BD%91%E7%9B%98%E7%9B%B4%E6%8E%A5%E4%B8%8B%E8%BD%BD%E5%8A%A9%E6%89%8B-%E6%98%BE%E7%A4%BA%E7%9B%B4%E6%8E%A5%E4%B8%8B%E8%BD%BD%E5%85%A5%E5%8F%A3)* , 点击`安装`或者`install`,完了直接刷新界面, 进入到自己的百度云盘选择所需的下载文件即可. 

### pan-light

百度网盘不限速客户端, golang + qt5, 跨平台图形界面: ***[https://github.com/peterq/pan-light](https://github.com/peterq/pan-light)***

## 翻译

### Stardict火星译王

```
sudo apt install stardict
```
**安装词库: **
进入*[http://download.huzheng.org/](http://download.huzheng.org/)*
选择所需词库并下载, `a`为下载的词库名, 然后重启`stardict`

```
tar -xjvf a.tar.bz2
mv a /usr/share/stardict/dic
```

### golddict翻译

```
sudo apt install goldendict
```

在 编辑 -> 词典 中添加有道翻译 `http://dict.youdao.com/search?q=%GDWORD%&ue=utf8`, 再禁用其他翻译源.

选中英文, 按 `Ctrl` + `C` + `C` 即可弹出翻译界面.

## 备份工具 Timeshift

```
sudo add-apt-repository -y ppa:teejee2008/ppa
sudo apt install -y timeshift
```

![](https://cdn.yangbingdong.com/img/individuation/time-shift.png)

## Albert

```bash
sudo apt install curl
curl https://build.opensuse.org/projects/home:manuelschneid3r/public_key | sudo apt-key add -
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_18.04/ /' > /etc/apt/sources.list.d/home:manuelschneid3r.list"
sudo apt-get update
sudo apt-get install albert
```

第一次打开的时候需要设置快捷键, 推荐 `Ctrl` + `~`.

隐藏 Albert 图标只需要在设置中将 `showTray` 的勾选去除即可.

> 去除图标之后设置就不知道怎么按出来了, 这时候可以在 `/home/{USER}/.config/albert/albert.conf` 中配置.
>
> 或者通过快捷键按出 Albert 输入栏, 设置一般在输入栏的右上角.

## PostMan

下载: ***[https://www.getpostman.com/downloads/](https://www.getpostman.com/downloads/)***

Json Body 字体问题:

在Linux中, postman 的 body 和 response 使用的默认字体如果没有安装的话, 会导致字体和光标的位置不一致, 例如字体显示长度只有30, 而光标在70的位置, 导致编辑困难.

解决:

```bash
sudo wget -P /usr/share/fonts/custom https://github.com/fangwentong/dotfiles/raw/master/ubuntu-gui/fonts/Monaco.ttf
sudo chmod 744 /usr/share/fonts/custom/Monaco.ttf
sudo mkfontscale  && sudo mkfontdir && sudo fc-cache -fv
```

## 抓包

### Charles

> 官网下载地址: ***[https://www.charlesproxy.com/download/](https://www.charlesproxy.com/download/)***

apt 安装:

```bash
wget -q -O - https://www.charlesproxy.com/packages/apt/PublicKey | sudo apt-key add 
sudo sh -c 'echo deb https://www.charlesproxy.com/packages/apt/ charles-proxy main > /etc/apt/sources.list.d/charles.list'
sudo apt update
sudo apt install -y charles-proxy
```

## 硬件信息

### I-Nex

这是一个类似CPU-Z的工具

下载链接: ***[https://launchpad.net/i-nex/+download](https://launchpad.net/i-nex/+download)***

![](https://cdn.yangbingdong.com/img/individuation/I-Nex%20-%20CPU_001.png)

### Hardinfo

```
sudo apt install hardinfo -y
```

![](https://cdn.yangbingdong.com/img/individuation/System%20Information_002.png)

# 其他设置篇

## Grub2

### 设置引导等待时间

`Ubuntu`系统的`Grub2`菜单的相关信息在读取`/boot/grub/grub.cfg`文件, 不过`Ubuntu`官方不建议直接修改这个文件, 想要修改`Grub2`的等待时间还可以修改`/etc/deafalt/grub`来实现. 具体的修改方法如下: 

```
sudo gedit /etc/default/grub
```
将`GRUB_TIMEOUT=10`中的`10`改为你想要修改的等待时间, 比如`3`, 网上很多的教程都是到这一步, 其实是不行的, 估计都是乱转一气. 到这里还有最重要的一步, 就是使用`#`号将`GRUB_HIDDEN_TIMEOUT=0`标注,然后再次回到终端, 输入下面的命令刷新`/boot/grub/grub.cfg`文件: 
```
sudo update-grub2
```

### Grub Customizer

```
sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
sudo apt install grub-customizer
```

修改保存后更新配置文件:

```
sudo update-grub
```

## 启动项管理

```
gnome-session-properties
```

## 提高逼格

### screenfetch

```
sudo apt install screenfetch
```

![](https://cdn.yangbingdong.com/img/individuation/screenfetch.png)

### edex-ui

> ***[https://github.com/GitSquared/edex-ui](https://github.com/GitSquared/edex-ui)***

在Release页面中下载AppImage运行即可:

![](https://cdn.yangbingdong.com/img/individuation/eDEX-UI.png)

### 终端高逼格屏保

```
sudo apt install cmatrix
cmatrix -b
```

![](https://cdn.yangbingdong.com/img/individuation/cmatrix.png)

够骚气. . . 

## 键盘输入声音特效（Tickys）

***[官网](http://www.yingdev.com/projects/tickeys)*** 或者 ***[博主的百度盘](https://pan.baidu.com/s/1c2uyTEw)*** (密码: 9bpi)

Tickeys依赖 `gksu`, 然而 `gksu` 在Ubuntu18之后被移除了, 所以想要安装还需要装回 `gksu`:

```
cat <<EOF | sudo tee /etc/apt/sources.list.d/artful.list
deb http://archive.ubuntu.com/ubuntu/ artful universe
EOF
sudo apt update
sudo apt install -i gksu
sudo dpkg -i tickeys_0.2.5_amd64.deb

# 如有依赖未安装
sudo apt install -f
```

然后通过`sudo tickeys`来打开 (sudo tickeys -c 打开CLI版本)
![](https://cdn.yangbingdong.com/img/individuation/tickeys_v0.2.5.png)

# 附录

## 软件图标（.desktop）文件位置

- `/usr/share/applications` # 大部分启动图标都在此
- `~/.local/share/applications` # 一部分本地图标
- `/var/lib/snapd/desktop/applications` # snap 类软件在此

## 生成软件图标工具

工具安装:

```
sudo apt install gnome-panel
```

创建:

```
sudo gnome-desktop-item-edit /usr/share/applications/ --create-new
```

然后会弹出一个框, 在里面选择命令以及图标生成即可.

## gsetting 与 dconf

gsetting 与 dconf 是 Linux Gnome下实现对应用程序的配置及管理功能的工具.

gsetting命令:

```
#gsettings list-schemas             显示系统已安装的不可重定位的schema
#gsettings list-relocatable-schemas 显示已安装的可重定位的schema
#gsettings list-children SCHEMA     显示指定schema的children，其中SCHEMA指xml文件中schema的id属性值，例如实例中的"org.lili.test.app.testgsettings"
#gsettings list-keys SCHEMA         显示指定schema的所有项(key)
#gsettings range SCHEMA KEY         查询指定schema的指定项KEY的有效取值范围
#gsettings get SCHEMA KEY           显示指定schema的指定项KEY的值
#gsettings set SCHEMA KEY VALUE     设置指定schema的指定项KEY的值为VALUE
#gsettings reset SCHEMA KEY         恢复指定schema的指定项KEY的值为默认值
#gsettings reset-recursively SCHEMA 恢复指定schema的所有key的值为默认值
#gsettings list-recursively [SCHEMA]如果有SCHEMA参数，则递归显示指定schema的所有项(key)和值(value)，如果没有SCHEMA参数，则递归显示所有schema的所有项(key)和值(value)
```

dconf 可以实现配置的导入与导出:

```
dconf dump /org/gnome/shell/extensions/dynamic-top-bar/ > ~/backup.txt

dconf load /org/gnome/shell/extensions/topicons/ <<- EOF
[/]
icon-size=24
icon-spacing=12
tray-pos='right'
tray-order=1
EOF
```

也可以使用 `dconf-editor` 对其进行管理

```
sudo apt install -y dconf-editor
```

## 强制清空回收站

```
sudo rm -rf $HOME/.local/share/Trash/files/*
```

## 终端写出图形文字

***[Text to ASCII Art Generator](http://patorjk.com/software/taag/#p=display&f=Slant&t=Composer)***

## 其他 Ubuntu 衍生版

* ***[Elementary OS](https://elementary.io/zh_CN/)***
* ***[Linux Mint](https://www.linuxmint.com/)***
* ***[Zorin OS](https://zorinos.com/)***

# Finally

> 参考: 
>
> * ***[https://inkss.cn/2018/09/12/ubuntu-1804-installation-record/](https://inkss.cn/2018/09/12/ubuntu-1804-installation-record/)***
> * ***[https://blog.diqigan.cn/posts/ubuntu-18-10-beautify.html](https://blog.diqigan.cn/posts/ubuntu-18-10-beautify.html)***

使用Ubuntu的这一路过来跌跌撞撞, 摸爬滚打不断解决各种奇怪的系统问题, 磨合了也有好长一段日子, 重装系统的次数也数不过来了. . . 给我最大的收获并不是觉得自己用Ubuntu用得多牛X, 而是修身养性. . . 

本文将定期更新, 与时俱进~
