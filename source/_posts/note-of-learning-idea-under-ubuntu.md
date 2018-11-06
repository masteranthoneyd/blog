---
title: Ubuntu下使用IntelliJ IDEA的正确姿势
date: 2017-04-17 18:00:00
categories: IDE
tags: [Ubuntu, IDE]
---
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea2.png)
# Preface
> 公司里的大牛们用的IDE基本都是IDEA~~近墨者黑~~，早就听闻IntelliJ IDEA这个大名，只不过当初比较菜鸟还不会用(...虽然现在也还是个菜鸟=.=)，再不用就要被OUT了
> 此篇把在Ubuntu下使用IDEA的学习经验记录下来(网上还是比较少资料解决Ubuntu下IDEA的问题Orz)，以便老了记性不好可以看一看...


<!--more-->
# Install
博主采用***[Toolbox App](https://www.jetbrains.com/toolbox/app/)*** 方式安装。
这样的好处是我们不用关心更新问题，每次有新版本它都会提示，我们是需要点一下`Install`就可以了，不需要关心升级后的配置。
还有一个好处是可以管理其他的IntelliJ软件（虽然博主只用他们的IDEA = =）...
安装的时候注意**配置安装路径**：
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-setting-path.png)

# License

## 2018.1.5以前版本

注册码可以自己读娘，或者使用授权服务器

博主用的是基于docker的授权服务器：

```
docker pull ilanyu/golang-reverseproxy
docker run -d -p 6666:8888 ilanyu/golang-reverseproxy
```

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/license-server.png)

也可以自己搭建一个基于docker的服务 = =

[***https://github.com/masteranthoneyd/docker-jetlicense***](https://github.com/masteranthoneyd/docker-jetlicense)

部署到VPS上，nginx反向代理：

```
server {  
    listen 80;  
    server_name 域名;  

    location / {  
        proxy_set_header X-Real-IP $remote_addr;  
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;  
        proxy_set_header Host $http_host;  
        proxy_set_header X-NginX-Proxy true;  
        proxy_pass http://127.0.0.1:端口/;  
        proxy_redirect off;  
    }
}
```

重启nginx：

```
nginx -s reload
```

## 2018.2版本

> ***[rover大神](https://rover12421.com/)***

# Personal Setting

博主的常用配置：
一般会选择打开项目时最外层的窗口打开`setting`，对全局生效。
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-setting.png)

## 文件修改后，设置左边目录出现颜色变化
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/version-control-change.png)

## 如果只有一行方法的代码默认要展开，去掉这个勾
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/one-line-methods.png)

## 修改字体和字号
Ubuntu下默认的字体还是让人看了有点~~不爽~~，而且使用Ubuntu默认的字体工具栏可能会出现乱码。
下面三个地方，分别是窗口字体，代码字体和控制台字体：
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-font.png)

## 修改VM参数
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-vm-setting.png)
通过`Toolbox`可以简单地设置VM参数，博主16G内存的主机的VM参数设置为
```
-Xms512m
-Xmx1500m
-XX:ReservedCodeCacheSize=500m
```
## 设置代码不区分大小写
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/code-comlpetion.png)

## 禁止 import *
IDEA默认检测到有5个相同包就会自动`import *`，其实没必要，需要哪个就`import`哪个。
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/import-optimizing.png)

## 设置不自动打开上一次最后关闭的项目
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/system-setting01.png)

## Postfix Completion
这个本来就是默认开启的
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/postfix-completion.png)

## 可生成SreializableID
在 `setting>Editor>Inspections>Java>Serializtion Issues>`:
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/ger-serializtion.png)
钩上之后在需要生成的类上`Alt+Enter`就会出现了。

## 关闭代码拖拽功能
一不小心手抖就改了代码...禁用！
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/dorp-function.png)

## 显示内存使用情况
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/show-memory.png)
点击内存信息展示的那个条可以进行部分的内存回收
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/menory.png)


## 优化 Java 注释
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/code-optimize.png)

## 优化方法链
在Java8中特别是使用Stream API，ex：
```java
list.stream().filter(func).distinct().skip(num).limit(num).map(func).peek(func).collect(func);
```
写成一行太长了！！
勾上这个选项idea将自动帮我们优化：
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/code-style-method-chain.png)

会变成这样

```
list = list.stream()
		   .filter(func)
		   .distinct()
		   .....
```

## 多线程自动编译

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/auto-compile.png)

## 设置统一编译jdk版本（关闭module JDK）

![](http://yangbingdong.com/img/learning-idea-under-ubuntu/idea-close-module-jdk.png)

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

| Keyboard shortcut                    | Declaration                              |
| ------------------------------------ | ---------------------------------------- |
| **Ctrl+D/Ctrl+Y**                    | 重复代码,未选择代码时重复当前行/删除当前行                   |
| **Ctrl+Shift+Enter**                 | 补全语句                                     |
| **Ctrl+P**                           | 显示方法参数                                   |
| **Ctrl+Q**                           | 显示注释文档                                   |
| **Alt+Insert**                       | 生成代码,生成 Getter、Setter、构造器等               |
| **Ctrl+O/Ctrl+I**                    | 重写父类方法/实现接口方法                            |
| **Ctrl+W**                           | 选择代码块,连续按会增加选择外层的代码块                     |
| **Ctrl+Shift+W**                     | 与“Ctrl+W”相反,减少选择代码块                      |
| **Ctrl+Alt+L**                       | 格式化代码                                    |
| **Ctrl+Alt+O**                       | 优化 Imports                               |
| **Ctrl+Shift+J**                     | 合并多行为一行                                  |
| **Ctrl+Shift+U**                     | 对选中内容进行大小写切换                             |
| **Ctrl+Shift+]/[**                   | 选中到代码块的开始/结束                             |
| **Ctrl+Delete/Ctrl+Backspace**       | 删除从光标所在位置到单词结束/开头处                       |
| **Ctrl+F4**                          | 关闭当前编辑页                                  |
| **Alt+J/Ctrl+Alt+Shift+J**           | 匹配下一个/全部与当前选中相同的代码                       |
| **Alt+Shift+J**                      | “Alt+J”的反选                               |
| **Alt+Shift+Insert,然后Shift+Up/Down** | 同时编辑多行(退出此`Column`模式也是“Alt+Shift+Insert”) |

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
| **Ctrl+Alt+P**       | 提取为方法参数            |
| **Ctrl+Shift+Alt+P** | 提取为函数式参数           |
| **Ctrl+Alt+Shift+T** | 重构一切               |

# Plugin

## Lombok
1.首先在IDEA里面安装使用lombok编写简略风格代码的插件，
打开IDEA的Settings面板，并选择Plugins选项，然后点击 “Browse repositories..” 
![](https://cdn.yangbingdong.com/img/lombok/installLombok01.png)
在输入框输入”lombok”，得到搜索结果，选择第二个，点击安装，然后安装提示重启IDEA，安装成功; 
![](https://cdn.yangbingdong.com/img/lombok/installLombok02.png)

 还需要在IDEA中开启支持：

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/annotation-support.png)

2.在自己的项目里添加lombok的编译支持(maven项目),在pom文件里面添加如下
indenpence

```xml
<dependency>
  <groupId>org.projectlombok</groupId>
  <artifactId>lombok</artifactId>
  <version>1.16.18</version>
</dependency>
```

3.然后就可以尽情在自己项目里面编写简略风格的Java代码咯
```java
    package com.lombok;

    import lombok.Data;
    import lombok.EqualsAndHashCode;

    import java.util.List;

    @Data
    @EqualsAndHashCode(callSuper = false)
    public class Student {

        String name;
        int sex;
        Integer age;
        String address;

        List<String> books;

    }
    //使用Student类对象
    Student student = new Student();
    student.setName(name);
    student.setAge(age);
    student.setAddress(address);
    student.setBooks(Arrays.asList(books));
```

4.常用注解

- `@Getter` and `@Setter`：生成`getter` / `setter`方法，默认生成的方法是public的，如果要修改方法修饰符可以设置**AccessLevel**的值，例如：`@Getter(access = AccessLevel.PROTECTED)`

- `@ToString`：生成toString()方法，可以这样设置不包含哪些字段`@ToString(exclude = "id")` / `@ToString(exclude = {"id","name"})`，如果继承的有父类的话，可以设置**callSuper** 让其调用父类的toString()方法，例如：`@ToString(callSuper = true)`

- `@NoArgsConstructor`, `@RequiredArgsConstructor`, `@AllArgsConstructor`：`@NoArgsConstructor`生成一个无参构造方法。当类中有final字段没有被初始化时，编译器会报错，此时可用`@NoArgsConstructor(force = true)`，然后就会为没有初始化的`final`字段设置默认值 `0` / `false` / `null`。对于具有约束的字段（例如`@NonNul`l字段），不会生成检查或分配，因此请注意，正确初始化这些字段之前，这些约束无效。`@RequiredArgsConstructor`会生成构造方法（可能带参数也可能不带参数），如果带参数，这参数只能是以final修饰的未经初始化的字段，或者是以`@NonNull`注解的未经初始化的字段`@RequiredArgsConstructor(staticName = "of")`会生成一个`of()`的静态方法，并把构造方法设置为私有。`@AllArgsConstructor` 生成一个全参数的构造方法。

- `@Data`：`@Data` 包含了`@ToString`，`@EqualsAndHashCode`，`@Getter` / `@Setter`和`@RequiredArgsConstructor`的功能。

- `@Accessors`：主要用于控制生成的`getter`和`setter`，此注解有三个参数：`fluent boolean`值，默认为`false`。此字段主要为控制生成的`getter`和`setter`方法前面是否带`get/set`；`chain boolean`值，默认`false`。如果设置为`true`，`setter`返回的是此对象，方便链式调用方法`prefix` 设置前缀 例如：`@Accessors(prefix = "abc") private String abcAge`  当生成`get`/`set`方法时，会把此前缀去掉。

- `@Synchronized`：给方法加上同步锁。

- `@Builder`：`@Builder`注释为你的类生成复杂的构建器`API`：

  ```
  Person.builder().name("Adam Savage").city("San Francisco").job("Mythbusters").job("Unchained Reaction").build();
  ```

- `@NonNull`：如其名，不能为空，否则抛出`NullPointException`

- `Log`类：

  ```
  @CommonsLog
  Creates private static final org.apache.commons.logging.Log log = org.apache.commons.logging.LogFactory.getLog(LogExample.class);
  @JBossLog
  Creates private static final org.jboss.logging.Logger log = org.jboss.logging.Logger.getLogger(LogExample.class);
  @Log
  Creates private static final java.util.logging.Logger log = java.util.logging.Logger.getLogger(LogExample.class.getName());
  @Log4j
  Creates private static final org.apache.log4j.Logger log = org.apache.log4j.Logger.getLogger(LogExample.class);
  @Log4j2
  Creates private static final org.apache.logging.log4j.Logger log = org.apache.logging.log4j.LogManager.getLogger(LogExample.class);
  @Slf4j
  Creates private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(LogExample.class);
  @XSlf4j
  Creates private static final org.slf4j.ext.XLogger log = org.slf4j.ext.XLoggerFactory.getXLogger(LogExample.class);
  ```


`Lombok`的功能不仅如此，更详细请看***[features](https://projectlombok.org/features/all)***

## Docker Integration

可以通过IDEA链接Docker API，前提是开启了Docker API

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/docker-integration01.png)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/docker-integration02.png)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/docker-integration03.png)

## Zookeeper

Zookeeper UI，支持删除操作

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/zookeeper-plugin1.png)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/zookeeper-plugin2.png)

## GsonFormat

复制一段JSON格式字符串

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/gson-format01.png)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/gson-format02.png)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/gson-format03.png)

## Mybatis 插件

可以直接从Mapper文件跳转到xml：

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/free-mybatis.png)

## Ali规约插件 P3C

插件地址：***[https://github.com/alibaba/p3c](https://github.com/alibaba/p3c)***
文档：***[https://github.com/alibaba/p3c/blob/master/idea-plugin/README_cn.md](https://github.com/alibaba/p3c/blob/master/idea-plugin/README_cn.md)***

## FindBugs
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/find-bug.png)
装完之后右键最下面会多出一个`FindBugs`的选项

## Maven Helper

这个主要可以分析maven依赖冲突。

安装之后，打开`pom.xml`文件，会看到多了一个Dependency Analyzer的面板，点击可以进入分析面板：

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/maven-helper01.png)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/maven-helper02.png)

另外，右键项目也会多两个Maven的bar：

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/maven-helper03.png)

## Statistic

这个插件可以统计代码数量：

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/maven-helper04.png)

## Stackoverflow

看名字就知道这个是干嘛的啦，在plugin repostories直接搜索stackoverflow就找得到

重启后随便选中内容右键就可以看到

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-stackoverflow.png)

## Nyan progress bar

这个是彩虹版的进度条...

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/nyan-progress-bar.png)

## Background Image Plus

这是一个设置背景图的插件

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/background-image-plus.png)

## Enso

它可以将测试名转化成一个句子，一目了然地显示测试的内容。这意味着当你在注视任何类的时候， Enso 都会展示其说明文档。

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/plugin-enso.png)

## activate-power-mode 或 Power mode ||

这个抖动的窗口老年人实在受不了...

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/activate-power-mode.gif)

# VM Options

可以通过ToolBox或IDEA选项里面设置

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/vmoption1.jpg)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/vmoption2.jpg)

优化参数：

```
-server
-Xms2048m
-Xmx2048m
-Xmn1024m
-XX:MetaspaceSize=256m
-XX:MaxMetaspaceSize=2048m
-XX:ReservedCodeCacheSize=512m
-XX:+UseG1GC
-XX:-UseParNewGC
-XX:-UseConcMarkSweepGC
-XX:SoftRefLRUPolicyMSPerMB=200
-XX:+UseCompressedOops
-ea
-Dsun.io.useCanonCaches=false
-Djava.net.preferIPv4Stack=true
-XX:+HeapDumpOnOutOfMemoryError
-XX:-OmitStackTraceInFastThrow
-Dsun.awt.keepWorkingSetOnMinimize=true
-Dide.no.platform.update=true
-Djdk.http.auth.tunneling.disabledSchemes=""
-javaagent:/home/ybd/data/application/jetbrains/JetbrainsCrack.jar
-XX:MaxJavaStackTraceDepth=10000
```

**部分参数说明**：

`-Xms2048m`: 初始时内存大小，至少为`Xmx`的二分之一

`-Xmx2048m`: 最大内存大小，若总内存小于2GB，至少为总内存的四分之一；若总内存大于2GB，设为1-4GB

`-XX:+UseG1GC -XX:-UseParNewGC -XX:-UseConcMarkSweepGC`: 设置使用G1垃圾收集器 

`-server`: JVM以server的方式运行，启动速度慢，运行速度快

`-Dsun.awt.keepWorkingSetOnMinimize=true`: 让IDEA最小化后阻止JVM对其进行修剪

# Conflict of keyboard shortcuts

快捷键有冲突，创建脚本并执行：
```bash
#!/bin/bash  
gsettings set org.gnome.desktop.wm.keybindings toggle-shaded "[]" 
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "[]" 
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "[]"
gsettings set org.gnome.desktop.wm.keybindings begin-move "[]" 
```

如果是习惯Windows下的快捷键，那么可以**禁用TTY**（IDEA Ctrl+Alt+F1-6冲突）：

```
FILE_NAME=/usr/share/X11/xorg.conf.d/50-novtswitch.conf &&\
sudo touch ${FILE_NAME} && \
sudo tee ${FILE_NAME} << EOF
 Section "ServerFlags"
Option "DontVTSwitch" "true"
EndSection
EOF
```

**目前发现的快捷键冲突：**
1、`Ctrl+Alt+方向`，直接到系统设置里面改：
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-setting-keyboard.png)

2、安装了搜狗之后，按`Ctrl+Alt+B`会启动虚拟键盘，所以在输入法里面打开Fcitx设置，在附加组件里面，点击高级，再把虚拟键盘的选项去掉：
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-sougou-conflict.png)
然后注销或重启电脑。

3、`Ctrl+Alt+S`，这个在键盘设置里面找了很久，原来这玩意在输入法设置里面，点开输入法全局配置，把**显示高级选项**钩上，就会看到很多快捷键，我都把它们干掉了。
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/shurufa.png)


# Finally
> IDEA真的智能到没朋友...
> 如果喜欢IDEA这款软件，并且有经济能力的，请付费购买~







