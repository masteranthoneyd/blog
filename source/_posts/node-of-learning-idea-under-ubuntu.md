---
title: Ubuntu下使用IntelliJ IDEA的正确姿势
date: 2017-04-17 18:00:00
categories: IDE
tags: [Ubuntu, IDE]
---
![](http://ojoba1c98.bkt.clouddn.com/img/java/idea.png)
# Preface
> 公司里的大牛们用的IDE基本都是IDEA~~近墨者黑~~，早就听闻IntelliJ IDEA这个大名，只不过当初比较菜鸟还不会用(...虽然现在也还是个菜鸟=.=)，再不用就要被OUT了
> 此篇把在Ubuntu下使用IDEA的学习经验记录下来(网上还是比较少资料解决Ubuntu下IDEA的问题Orz)，以便老了记性不好可以看一看...


<!--more-->
# Install
博主采用***[Toolbox App](https://www.jetbrains.com/toolbox/app/)*** 方式安装。
这样的好处是我们不用关心更新问题，每次有新版本它都会提示，我们是需要点一下`Install`就可以了，不需要关心升级后的配置。
还有一个好处是可以管理其他的IntelliJ软件（虽然博主只用他们的IDEA = =）...
安装的时候注意**配置安装路径**：
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/idea-setting-path.png)
至于*注册码*，嘿嘿嘿，度娘你懂的。

# Personal Setting
以下是博主个人的常用配置：
一般会选择打开项目时最外层的窗口打开`setting`，对全局生效。
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/idea-setting.png)
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

6、优化导包
IDEA默认检测到有5个相同包就会自动`import *`，其实没必要，需要哪个就`import`哪个。
![](http://ojoba1c98.bkt.clouddn.com/img/learning-idea-under-ubuntu/import-optimizing.png)

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
> JetBrains官方快捷键手册： *[https://resources.jetbrains.com/storage/products/intellij-idea/docs/IntelliJIDEA_ReferenceCard.pdf](https://resources.jetbrains.com/storage/products/intellij-idea/docs/IntelliJIDEA_ReferenceCard.pdf)*

个人感觉Ubuntu下使用IDEA最大的一个不爽就是**快捷键**了，~~想屎的感觉有木有~~，各种没反应，原来是快捷键冲突，本来想改成Eclipse的风格，但想了想好像不太合适。
快捷键风格可以在`setting` -> `Keymap` 里面这是，博主使用安装时候idea默认配置的`Default for XWin`。
先来大致分各类（纯属个人看法= =）：

## 导航（一般都可以在Navigate里面找到）

| Keyboard shortcut        | Declaration    |
| :----------------------- | :------------- |
| **Ctrl+N**               | 查找Java类        |
| **Ctrl+Shift+N**         | 查找非Java文件      |
| **Ctrl+Shift+Alt+N**     | 查找类中的方法或变量     |
| **Double Shift**         | 查找所有           |
| **Ctrl+Alt+Left/Right**  | 跳到光标的上/下一个位置   |
| **F2/Shift+F2**          | 光标移动到下/上一个错误   |
| **Ctrl+Shift+Backspace** | 跳到上一个编辑处       |
| **Ctrl+Alt+B**           | 跳到实现类/方法       |
| **Ctrl+U**               | 跳到父类/方法        |
| **Alt+Up/Down**          | 光标移动到上/下一个方法   |
| **Ctrl+F12**             | 搜索当前文件方法       |
| **Ctrl+H/Ctrl+Shift+H**  | 显示类/方法层级       |
| **F11/Shift+F11**        | 当前行设置书签/显示所有书签 |
| **Ctrl+Shift+Backspace** | 跳到上一个编辑处       |
| **Ctrl+G**               | 跳到指定行          |

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

| Keyboard shortcut              | Declaration                |
| ------------------------------ | -------------------------- |
| **Ctrl+D/Ctrl+Y**              | 重复代码,未选择代码时重复当前行/删除当前行     |
| **Ctrl+Shift+Enter**           | 补全语句                       |
| **Ctrl+P**                     | 显示方法参数                     |
| **Ctrl+Q**                     | 显示注释文档                     |
| **Alt+Insert**                 | 生成代码,生成 Getter、Setter、构造器等 |
| **Ctrl+O/Ctrl+I**              | 重写父类方法/实现接口方法              |
| **Ctrl+W**                     | 选择代码块,连续按会增加选择外层的代码块       |
| **Ctrl+Shift+W**               | 与“Ctrl+W”相反,减少选择代码块        |
| **Ctrl+Alt+L**                 | 格式化代码                      |
| **Ctrl+Alt+O**                 | 优化 Imports                 |
| **Ctrl+Shift+J**               | 合并多行为一行                    |
| **Ctrl+Shift+U**               | 对选中内容进行大小写切换               |
| **Ctrl+Shift+]/[**             | 选中到代码块的开始/结束               |
| **Ctrl+Delete/Ctrl+Backspace** | 删除从光标所在位置到单词结束/开头处         |
| **Ctrl+F4**                    | 关闭当前编辑页                    |
| **Alt+J/Ctrl+Alt+Shift+J**     | 匹配下一个/全部与当前选中相同的代码         |

## 调试

| Keyboard shortcut | Declaration         |
| ----------------- | ------------------- |
| **F8/F7**         | 单步调试,不进入函数内部/进入函数内部 |
| **Shift+F8**      | 跳出函数                |
| **Alt+F9**        | 运行到断点               |
| **Alt+F8**        | 执行表达式查看结果           |
| **F9**            | 继续执行,进入下一个断点或执行完程序  |
| **Ctrl+Shift+F8** | 查看断点                |



## 重构

| Keyboard shortcut    | Declaration        |
| -------------------- | ------------------ |
| **F6**               | 移动类                |
| **Alt+Delete**       | 安全删除,删除前会提示调用处     |
| **Shift+F6**         | 重命名                |
| **Ctrl+F6**          | 重构方法参数、Exception 等 |
| **Ctrl+Alt+M**       | 提取为新方法             |
| **Ctrl+Alt+V**       | 提取为新变量             |
| **Ctrl+Alt+F**       | 提取为对象新属性           |
| **Ctrl+Alt+C**       | 提取为新静态常量           |
| **Ctrl+Alt+P**       | 提取为方法参数           |
| **Ctrl+Shift+Alt+P** | 提取为函数式参数           |
| **Ctrl+Alt+Shift+T** | 重构一切               |

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

## Markdown Navigator支持md编写
### 下载
Markdown Navigator下载地址： ***[https://plugins.jetbrains.com/plugin/7896-markdown-navigator](https://plugins.jetbrains.com/plugin/7896-markdown-navigator)***
下载下来的应该是一个`zip`文件

### 解压
解压后进入`lib`文件，找到`idea-multimarkdown.jar`：
![](http://ojoba1c98.bkt.clouddn.com/img/idea-markdown/decompression.png)

打开jar包找到 `com.vladsch.idea.multimarkdown.license.LicenseAgent.java`
![](http://ojoba1c98.bkt.clouddn.com/img/idea-markdown/crack-file.png)


### IDEA创建项目
在IDEA里创建一个Java项目，且目录**必须**为`com.vladsch.idea.multimarkdown.license`,要不然编译出来的package属性就变了哦
把上面找到的`LicenseAgent.java`扔进去
![](http://ojoba1c98.bkt.clouddn.com/img/idea-markdown/crack-java-file.png)

恩，接着一大波红色的波浪错误出现啦，先别紧张，咱们把依赖包加上去就OK了：
![](http://ojoba1c98.bkt.clouddn.com/img/idea-markdown/project-setting-step.png)

上图的两个依赖分别是**解压Markdown Navigator插件里边的`lib`包**和**IDEA文件夹里边的`lib`包**

### 修改
**铺垫**做完了，开始改源码了。
修改 `com.vladsch.idea.multimarkdown.license.LicenseAgent.java` 文件的内容如下：
* `getLicenseExpires()` 整个方法体干掉不要了(删除方法体)，只留返回值改为 `return "Never Expires"`;
* `getLicenseCode()` 最后一行返回值 `return false` 改为 `return true`，**对你没有看错**，**只改最后一行代码**;
* `isValidLicense()` 删除方法体，只留返回值，返回值改为 `return true`;
* `isValidActivation()` 删除方法体，只留返回值，返回值改为 `return true`;
* `getLicenseType()` 删除方法体，只留返回值，返回值改为 `return "License"` 或 `return "license"`;
* `getLicenseExpiringIn()` 删除方法体，只留返回值，返回值改为 `return 36000`;(单位是天)
* `isActivationExpired()` 删除方法体，只留返回值，返回值改为 `return false`;

改完后右键`java`文件compile编译一下得到`class`文件

### 替换
用上面得到的`LicenseAgent.class`文件替换掉`idea-multimarkdown.jar/com/vladsch/idea/multimarkdown/license`里面的文件`LicenseAgent.class`文件：
![](http://ojoba1c98.bkt.clouddn.com/img/idea-markdown/class1.png)
![](http://ojoba1c98.bkt.clouddn.com/img/idea-markdown/class2.png)

### 安装
替换完成后把解压的插件包重新打包成`zip`文件
![](http://ojoba1c98.bkt.clouddn.com/img/idea-markdown/zip.png)

打开`Setting`找到`Pligins`：
![](http://ojoba1c98.bkt.clouddn.com/img/idea-markdown/install.png)

之后重启IDEA，搞定~
虽然有很多功能齐全的md编辑器，但是用IDEA配置和编写Hexo，还要打开别的编辑器那就太不方便了，还是用浑然天成的插件吧。
改了源码后插件上面的工具栏貌似没有效果了...


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


# Finally
> IDEA真的智能到没朋友...
> 如果喜欢IDEA这款软件，并且有经济能力的，请付费购买~







