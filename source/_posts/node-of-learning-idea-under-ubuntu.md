---
title: Ubuntu下IntelliJ IDEA使用笔记
date: 2017-04-17 18:00:00
categories: IDE
tags: [Ubuntu, IDE]
---
![](http://ojoba1c98.bkt.clouddn.com/img/java/idea.png)
# Preface
> 公司里的大牛们用的IDE基本都是IDEA，~~所为近墨者黑~~早就听闻IntelliJ IDEA这个大名，只不过当初比较菜鸟还不会用(...虽然现在也还是个菜鸟=.=)，再不用IDEA就要被OUT了，此篇把IDEA的学习经验记录下来，以便老了记性不好可以看一看...


<!--more-->
# Install
博主采用***[Toolbox App](https://www.jetbrains.com/toolbox/app/)*** 方式安装，方便管理更新。
安装的时候注意**配置安装路径**：
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/idea-setting-path.png)
至于*注册码*，嘿嘿，度娘你懂的。

# Setting
以下是博主个人的常用配置：
1、文件修改后，设置左边目录出现颜色变化
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/version-control-change.png)
2、如果只有一行方法的代码默认要展开，去掉这个勾
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/one-line-methods.png)
3、修改字体和字号
Ubuntu下默认的字体还是让人看了有点~~不爽~~，而且使用Ubuntu默认的字体工具栏可能会出现乱码。
下面三个地方，分别是窗口字体，代码字体和控制台字体：
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/idea-font.png)
4、修改VM参数
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/idea-vm-setting.png)
通过`Toolbox`可以简单地设置VM参数，博主16G内存的主机的VM参数设置为
```
-Xms512m
-Xmx1500m
-XX:ReservedCodeCacheSize=500m
```
5、设置代码不区分大小写
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/code-comlpetion.png)
6、自动导包
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/code-auto-import.png)
第一个钩：IntelliJ IDEA 将在我们书写代码的时候自动帮我们优化导入的包，比如自动去掉一些没有用到的包。
第二个钩：IntelliJ IDEA 将在我们书写代码的时候自动帮我们导入需要用到的包。但是对于那些同名的包，还是需要手动Alt + Enter 进行导入的，IntelliJ IDEA 目前还无法智能到替我们做判断。
7、设置不自动打开上一次最后关闭的项目
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/system-setting01.png)

8、Postfix Completion
这个本来就是默认开启的
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/postfix-completion.png)

9、可生成SreializableID
在 `setting>Editor>Inspections>Java>Serializtion Issues>`:
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/ger-serializtion.png)
钩上之后在需要生成的类上`Alt+Enter`就会出现了。

# Keyboard shortcuts
> JetBrains官方快捷键手册：***[https://resources.jetbrains.com/storage/products/intellij-idea/docs/IntelliJIDEA_ReferenceCard.pdf](https://resources.jetbrains.com/storage/products/intellij-idea/docs/IntelliJIDEA_ReferenceCard.pdf)***

个人感觉Ubuntu下使用IDEA最大的一个不爽就是**快捷键**了，~~想屎的感觉有木有~~，各种没反应，原来是快捷键冲突，本来想改成Eclipse的风格，但想了想好像不太合适。
快捷键风格可以在`setting` -> `Keymap` 里面这是，博主使用安装时候idea默认配置的`Default for XWin`。
先来大致分各类（纯属个人看法= =）：

## 导航（一般都可以在Navigate里面找到）

| Keyboard shortcut           | Declaration    |
| :-------------------------- | :------------- |
| **Ctrl+N**                  | 查找Java类        |
| **Ctrl+Shift+N**            | 查找非Java文件      |
| **Ctrl+Shift+Alt+N**        | 查找类中的方法或变量     |
| **Double Shift**            | 查找所有           |
| **Ctrl+Alt+Left/Right**     | 跳到光标的上/下一个位置   |
| **F2/Shift+F2**             | 光标移动到下/上一个错误   |
| **Ctrl+Shift+Backspace**    | 跳到上一个编辑处       |
| **Ctrl+Alt+B**              | 跳到实现类/方法       |
| **Ctrl+U**                  | 跳到父类/方法        |
| **Alt+Up/Down**             | 光标移动到上/下一个方法   |
| **Ctrl+F12**                | 搜索当前文件方法       |
| **Ctrl+Shift+H/Ctrl+Alt+H** | 显示类/方法调用层级     |
| **F11/Shift+F11**           | 当前行设置书签/显示所有书签 |
| **Ctrl+Shift+Backspace**    | 跳到上一个编辑处       |

## 查找/替换（一般在Edit的find里面）

| Keyboard shortcut | Declaration |
| :---------------- | :---------- |
| **Ctrl+F**        | 文件内查找       |
| **Ctrl+R**        | 文件内替换       |
| **F3/Shift+F3**   | 查找下/上一个     |
| **Ctrl+Shift+F**  | 目录内查找       |
| **Ctrl+Shift+R**  | 目录内替换       |
| **Ctrl+F7**       | 查找当前文件中的使用处 |
| **Alt+F7**        | 查找被使用处      |
| **Ctrl+Alt+F7**   | 显示被使用处      |


## 编辑

1、基本代码补全：`Ctrl+Space`
2、复制当前行：`Ctrl+D`
3、删除当前行：`Ctrl+Y`
4、显示注释文档

## 重构：

其他：
1、后退（上次编辑或停留的地方）：`Ctrl+Alt+左箭头`
2、前进（跟上面相反）：`Ctrl+Alt++右箭头`

# Plugin
## 热部署插件JRebel安装与激活
> 每次修改java文件都需要重启tomcat，很痛苦有木有？ 推荐给大家一个很好用的热部署插件，JRebel，目前是最好的，在使用过程中应该90%的编辑操作都是可以reload的，爽歪歪，节约我们大量的开发时间，提高开发效率。

### 安装
两种方式安装：
#### 方式一
下载安装，前往***[JRebe官网下载地址](https://zeroturnaround.com/software/jrebel/download/nightly-build/#!/intellij)***，选择对应IDE的版本下载，然后安装（下面照搬官网说的...）：
1、Open File > Settings (Preferences on macOS). Select Plugins.
2、Press Install plugin from disk…
3、Browse to the downloaded archive and press OK. Complete the installation.

#### 方式二
直接安装：
1、Open File > Settings. Select Plugins.
2、Press Browse Repositories.
3、Find JRebel. Press Install plugin.
4、Next → ***[Activation](https://zeroturnaround.com/software/jrebel/quickstart/intellij/#!/activation)***

### 激活
先戳进***[官网](https://my.jrebel.com/)***，使用Facebook或Twitter注册登录，之后就可以免费申请激活码了：
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/myrebel-activation-code.png)

打开 `Help` > `JRebel` > `Activation`，将申请的激活码复制进去，稍等片刻完成激活。

### 工程配置
打开  `view` > `tool window` > `Jrebel`，在弹出框中勾选你要热部署的项目：
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/jrebel-project-setting.png)
在tomcat配置中勾选图示选项：
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/jrebel-tomcat-setting.png)
**deployment 要选择后缀为explored的工程**。

### 启动
点击 ![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/jrebel-startup.png) JRebel图标，启动项目


# Conflict of keyboard shortcuts
快捷键有冲突，创建脚本并执行：
```bash
#!/bin/bash  
gsettings set org.gnome.desktop.wm.keybindings toggle-shaded "[]" 
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "[]" 
gsettings set org.gnome.desktop.wm.keybindings begin-move "[]" 
```

**目前发现的快捷键冲突：**
1、`Ctrl+Alt+方向`，直接到系统设置里面改：
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/idea-setting-keyboard.png)

2、安装了搜狗之后，按`Ctrl+Alt+B`会启动虚拟键盘，所以在输入法里面打开Fcitx设置，在附加组件里面，点击高级，再把虚拟键盘的选项去掉：
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/idea-sougou-conflict.png)
然后注销或重启电脑。

3、`Ctrl+Alt+S`，这个在键盘设置里面找了很久，原来这玩意在输入法设置里面，点开输入法全局配置，把**显示高级选项**钩上，就会看到很多快捷键，我都把它们干掉了。
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/shurufa.png)










