title: Ubuntu16.04下MyEclipse安装与破解
categories:
  - IDE
tags:
  - Ubuntu
  - IDE
date: 2017-01-11 11:52:00
---
![](https://cdn.yangbingdong.com/img/ubuntu-myclipse-crack/myeclipseInfo.png)

# 前言
> 之前一直用的是Eclipse Luna，没有用MyEclipse是因为它**收钱**的- -，去新公司工作需要用到MyEclipse，下载安装happy地**试用**了将近一个月，不幸，试用期已过。身为一个开源爱好者，不想去用破解的（虚伪 - -），也不想出钱，博主秉着屌丝的意志，一番折腾过后，搞定。以下是经过参考与总结得到的操作步骤，博主用的是Linux的发行版Ubuntu，所以以下步骤针对Ubuntu系统，win与mac的步骤也大同小异。
<!--more-->

------

# 下载与安装

首先，请前往***[MyEclipse的官网](http://www.MyEclipsecn.com/download/)*** 下载相应系统的版本，我选择的是*MyEclipse-2015-stable-3.0-offline-installer-linux.run*，进入放置安装文件的目录，右键在终端打开安装文件

```bash
./MyEclipse-2015-stable-3.0-offline-installer-linux.run 
```

![](https://cdn.yangbingdong.com/img/ubuntu-myclipse-crack/meInstall.png)
按`Nest`设置一下安装路径完成安装，安装完之后不要选择运行MyEclipse

**破解之前请不要开启你的MyEclipse，要保持刚安装完的状态，如果你已经开过了，卸载重装吧——否则你就会遭遇打开编译器，然后校验失败，报错关闭**

# 破解与运行

首先请前往***[博主的百度盘](https://pan.baidu.com/s/1geKxeoz)***（密码：kv25）下载对应的破解工具，我的MyEclipse版本是2015-stable-3.0，所以在这以此版本作为示范。

下载到本地解压后并进入目录会有以下文件

![](https://cdn.yangbingdong.com/img/ubuntu-myclipse-crack/meFile.png)


## 打开注册机

进入`MyEclipse2015_keygen`，双击打开注册机`cracker2015.jar`，失败的话，用java命令打开`cracker2015.jar`，**前提都是你要安装了JDK并且配置好环境**，JDK版本最好不要太旧，我的是1.8

当前目录终端执行：

```
java -jar cracker2015.jar

```

运行之后出现如下界面 ↓

![](https://cdn.yangbingdong.com/img/ubuntu-myclipse-crack/crack.png)

## 开始生成注册信息 

1. 在算号器填好`Usercode`,`UserCode`可以随意输入

2. 选择版本：由于`Bling`版功能最全，所以我选择了这个版本（其他版本也可以）

3. 然后点击”SystemId”按钮，就会出现一行ID值，如果提示 `Cannot find JNIWrapper native library (jniwrap.dll) in java.library.path:`这样的错误，不要紧，再点一下应该就出来了，还是没有的话请注意**权限**问题

4. 点击`Active`

5. 保存破解信息：点`Tools`下的`SaveProperites`把破解信息（注册码）保存到文件 （<font color=red>注意不要手残去点RebuildKey- - !</font>）

{% asset_img crack01.png %}

## copy文件

把plugins文件中的文件复制到MyEclipse的plugins文件夹中，覆盖原文件

![](https://cdn.yangbingdong.com/img/ubuntu-myclipse-crack/plugins.png)

# 运行MyEclipse

打开了MyEclipse，点击菜单栏中的`MyEclipse`->`Subscription information`，激活成功，激动ing=.=

![](https://cdn.yangbingdong.com/img/ubuntu-myclipse-crack/myeclipseInfo.png)

------

# 最后

以上是博主在Ubuntu中安装破解MyEclipse的总结过程，对于不同的环境，不同的版本，不同的操作，有可能会导致一些不一样的小问题，那么可以在一下参考中找到一些答案

> **参考：**
> ***[Myeclipse 2015 stable 1.0 完美破解方法](http://yangl.net/2015/07/14/myeclipse_2015stable_1/)***
> ***[Myeclipse 2016 CI 6 破解](http://http://yangl.net/2016/10/11/myeclipse-2016-ci-6_crack/)***



