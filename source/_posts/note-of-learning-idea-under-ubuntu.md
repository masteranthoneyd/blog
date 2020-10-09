---
title: Ubuntu下使用IntelliJ IDEA的正确姿势
date: 2017-04-17 18:00:00
categories: IDE
tags: [Ubuntu, IDE]
---
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea2.png)
# Preface
> 公司里的大牛们用的IDE基本都是IDEA~~近墨者黑~~, 早就听闻IntelliJ IDEA这个大名, 只不过当初比较菜鸟还不会用(...虽然现在也还是个菜鸟=.=), 再不用就要被OUT了
> 此篇把在Ubuntu下使用IDEA的学习经验记录下来(网上还是比较少资料解决Ubuntu下IDEA的问题Orz), 以便老了记性不好可以看一看...

<!--more-->

# Install
博主采用***[Toolbox App](https://www.jetbrains.com/toolbox/app/)*** 方式安装. 
这样的好处是我们不用关心更新问题, 每次有新版本它都会提示, 我们是需要点一下`Install`就可以了, 不需要关心升级后的配置. 
还有一个好处是可以管理其他的IntelliJ软件（虽然博主只用他们的IDEA = =）...
安装的时候注意**配置安装路径**: 
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-setting-path.png)

# License

> 可参考 ***[http://idea.lanyus.com/](http://idea.lanyus.com/)***

## 2018.1.5以前版本

注册码可以自己读娘, 或者使用授权服务器 

博主用的是基于docker的授权服务器: 

```
docker pull ilanyu/golang-reverseproxy
docker run -d -p 6666:8888 ilanyu/golang-reverseproxy
```

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/license-server.png)

也可以自己搭建一个基于docker的服务 = =

[***https://github.com/masteranthoneyd/docker-jetlicense***](https://github.com/masteranthoneyd/docker-jetlicense)

部署到VPS上, nginx反向代理: 

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

重启nginx: 

```
nginx -s reload
```

# Personal Setting

博主的常用配置: 
一般会选择打开项目时最外层的窗口打开`setting`, 对全局生效. 
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-setting.png)

## 文件修改后, 设置左边目录出现颜色变化
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/version-control-change.png)

## 如果只有一行方法的代码默认要展开, 去掉这个勾
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/one-line-methods.png)

## 修改字体和字号
Ubuntu下默认的字体还是让人看了有点~~不爽~~, 而且使用Ubuntu默认的字体工具栏可能会出现乱码. 
下面三个地方, 分别是窗口字体, 代码字体和控制台字体: 
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-font.png)

## 修改VM参数

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-vm-setting.png)
通过`Toolbox`可以简单地设置VM参数, 博主16G内存的主机的VM参数设置为
```
-Xms512m
-Xmx1500m
-XX:ReservedCodeCacheSize=500m
```
## 设置代码不区分大小写
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/code-comlpetion.png)

## 禁止 import *
IDEA默认检测到有5个相同包就会自动`import *`, 其实没必要, 需要哪个就`import`哪个. 
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/import-optimizing.png)

## 设置不自动打开上一次最后关闭的项目
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/system-setting01.png)

## Postfix Completion
这个本来就是默认开启的
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/postfix-completion.png)

## 可生成SreializableID
在 `setting>Editor>Inspections>Java>Serializtion Issues>`:
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/ger-serializtion.png)
钩上之后在需要生成的类上`Alt+Enter`就会出现了. 

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
在Java8中特别是使用Stream API, ex: 
```java
list.stream().filter(func).distinct().skip(num).limit(num).map(func).peek(func).collect(func);
```
写成一行太长了！！
勾上这个选项idea将自动帮我们优化: 
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/code-style-method-chain.png)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/method-chain.png)

> 钩上 `Align when multiline` 可对其方法链

会变成这样

```
list = list.stream()
		   .filter(func)
		   .distinct()
		   .....
```

## 多线程自动编译

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/auto-compile.png)

## 设置统一编译JDK版本（关闭module JDK）

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-close-module-jdk.png)

## Tab 键改为4个空格

> 代码规范会要求编程时使用4个空格缩进而不是tab, 因为不同编辑器下4个空格的宽度看起来是一致的, 而tab则长短可能会不一致。

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/tab-setting.png)

## Maven 自动下载源码

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/maven-auto-download-source.png)

## 自定义代码颜色

### 方法参数

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-change-prameter-color.png)

### 选择变量显示使用地方

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-change-select-color.png)

### 选中代码块的背景颜色

Selection background:

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/selection-background-color.png)

## 修改快捷键

### Fix doc comment

打开 Setting, Keymap -> Other -> Fix doc comment

## 统一代码风格

### 导入 Google Code Style

查看并下载: *[https://github.com/ningg/styleguide/blob/gh-pages/intellij-java-google-style.xml](https://github.com/ningg/styleguide/blob/gh-pages/intellij-java-google-style.xml)*

导入:

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/set-code-style.png)

### 使用 editorconfig 与 gitattributes

在项目根目录中加入 `.editorconfig` :

```
# http://editorconfig.org
root = true

# 空格替代Tab缩进在各种编辑工具下效果一致
[*]
indent_style = space
indent_size = 4
charset = utf-8
end_of_line = lf
trim_trailing_whitespace = true
insert_final_newline = true

[*.java]
indent_style = tab

[*.{json,yml}]
indent_size = 2

[*.md]
insert_final_newline = false
trim_trailing_whitespace = false
```

在项目根目录中加入 `.gitattributes` :

```
# All text files should have the "lf" (Unix) line endings
* text eol=lf
# windows cmd shoud have the "crlf" (Win32) line endings
*.cmd eol=crlf

# Explicitly declare text files you want to always be normalized and converted
# to native line endings on checkout.
*.java text
*.js text
*.css text
*.html text
*.properties text
*.xml text
*.yml text

# Denote all files that are truly binary and should not be modified.
*.png binary
*.jpg binary
*.jar binary
*.ttf binary
```

# Keyboard shortcuts

> JetBrains官方快捷键手册: *[https://resources.jetbrains.com/storage/products/intellij-idea/docs/IntelliJIDEA_ReferenceCard.pdf](https://resources.jetbrains.com/storage/products/intellij-idea/docs/IntelliJIDEA_ReferenceCard.pdf)*

个人感觉Ubuntu下使用IDEA最大的一个不爽就是**快捷键**了, ~~想屎的感觉有木有~~, 各种没反应, 原来是快捷键冲突, 本来想改成Eclipse的风格, 但想了想好像不太合适. 
快捷键风格可以在`setting` -> `Keymap` 里面这是, 博主使用安装时候idea默认配置的`Default for XWin`. 
先来大致分各类（纯属个人看法= =）: 

## 导航（一般都可以在Navigate里面找到）

| Keyboard shortcut        | Declaration                       |
| :----------------------- | :-------------------------------- |
| **Ctrl+N**               | 查找Java类                        |
| **Ctrl+Shift+N**         | 查找非Java文件                    |
| **Ctrl+Shift+Alt+N**     | 查找**mvc接口**、类中的方法或变量 |
| **Double Shift**         | 查找所有                          |
| **Ctrl+Alt+Left/Right**  | 跳到光标的上/下一个位置           |
| **F2/Shift+F2**          | 光标移动到下/上一个错误           |
| **Ctrl+Shift+Backspace** | 跳到上一个编辑处                  |
| **Ctrl+Alt+B**           | 跳到实现类/方法                   |
| **Ctrl+U**               | 跳到父类/方法                     |
| **Alt+Up/Down**          | 光标移动到上/下一个方法           |
| **Ctrl+F12**             | 搜索当前文件方法                  |
| **Ctrl+H/Ctrl+Shift+H**  | 显示类/方法层级                   |
| **F11/Shift+F11**        | 当前行设置书签/显示所有书签       |
| **Ctrl+G**               | 跳到指定行                        |

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

| Keyboard shortcut                      | Declaration                                            |
| -------------------------------------- | ------------------------------------------------------ |
| **Ctrl+D**                             | 重复代码,未选择代码时重复当前行                        |
| **Ctrl+Y**                             | 删除当前行                                             |
| **Ctrl+Shift+Enter**                   | 补全语句                                               |
| **Ctrl+P**                             | 显示方法参数                                           |
| **Ctrl+Q**                             | 显示注释文档                                           |
| **Alt+Insert**                         | 生成代码,生成 Getter、Setter、构造器等                 |
| **Ctrl+O/Ctrl+I**                      | 重写父类方法/实现接口方法                              |
| **Ctrl+W**                             | 选择代码块,连续按会增加选择外层的代码块                |
| **Ctrl+Shift+W**                       | 与“Ctrl+W”相反,减少选择代码块                          |
| **Ctrl+Alt+L**                         | 格式化代码                                             |
| **Ctrl+Alt+O**                         | 优化 Imports                                           |
| **Ctrl+Shift+J**                       | 合并多行为一行                                         |
| **Ctrl+Shift+U**                       | 对选中内容进行大小写切换                               |
| **Ctrl+Shift+]/[**                     | 选中到代码块的开始/结束                                |
| **Ctrl+Delete/Ctrl+Backspace**         | 删除从光标所在位置到单词结束/开头处                    |
| **Ctrl+F4**                            | 关闭当前编辑页                                         |
| **Alt+J/Ctrl+Alt+Shift+J**             | 匹配下一个/全部与当前选中相同的代码                    |
| **Alt+Shift+J**                        | “Alt+J”的反选                                          |
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

## IDE Features Trainer

IDEA 使用教程, 安装后在左上角会出现 Learn 的栏目, 可在其中进行学习.

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/plugin-learn.png)

## RestfulToolkit

提供 Restful 开发工具箱, 可通过 `Ctrl + Alt + N` 搜索 url 方法

## Codota

*[Codota](https://www.codota.com/)* 这个插件用于智能代码补全, 它基于数百万Java程序, 能够根据程序上下文提示补全代码

## Lombok

1.首先在IDEA里面安装使用lombok编写简略风格代码的插件, 
打开IDEA的Settings面板, 并选择Plugins选项, 然后点击 “Browse repositories..” 
![](https://cdn.yangbingdong.com/img/lombok/installLombok01.png)
在输入框输入”lombok”, 得到搜索结果, 选择第二个, 点击安装, 然后安装提示重启IDEA, 安装成功; 
![](https://cdn.yangbingdong.com/img/lombok/installLombok02.png)

 还需要在IDEA中开启支持: 

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

- `@Getter` and `@Setter`: 生成`getter` / `setter`方法, 默认生成的方法是public的, 如果要修改方法修饰符可以设置**AccessLevel**的值, 例如: `@Getter(access = AccessLevel.PROTECTED)`

- `@ToString`: 生成toString()方法, 可以这样设置不包含哪些字段`@ToString(exclude = "id")` / `@ToString(exclude = {"id","name"})`, 如果继承的有父类的话, 可以设置**callSuper** 让其调用父类的toString()方法, 例如: `@ToString(callSuper = true)`

- `@NoArgsConstructor`, `@RequiredArgsConstructor`, `@AllArgsConstructor`: `@NoArgsConstructor`生成一个无参构造方法. 当类中有final字段没有被初始化时, 编译器会报错, 此时可用`@NoArgsConstructor(force = true)`, 然后就会为没有初始化的`final`字段设置默认值 `0` / `false` / `null`. 对于具有约束的字段（例如`@NonNul`l字段）, 不会生成检查或分配, 因此请注意, 正确初始化这些字段之前, 这些约束无效. `@RequiredArgsConstructor`会生成构造方法（可能带参数也可能不带参数）, 如果带参数, 这参数只能是以final修饰的未经初始化的字段, 或者是以`@NonNull`注解的未经初始化的字段`@RequiredArgsConstructor(staticName = "of")`会生成一个`of()`的静态方法, 并把构造方法设置为私有. `@AllArgsConstructor` 生成一个全参数的构造方法. 

- `@Data`: `@Data` 包含了`@ToString`, `@EqualsAndHashCode`, `@Getter` / `@Setter`和`@RequiredArgsConstructor`的功能. 

- `@Accessors`: 主要用于控制生成的`getter`和`setter`, 此注解有三个参数: `fluent boolean`值, 默认为`false`. 此字段主要为控制生成的`getter`和`setter`方法前面是否带`get/set`；`chain boolean`值, 默认`false`. 如果设置为`true`, `setter`返回的是此对象, 方便链式调用方法`prefix` 设置前缀 例如: `@Accessors(prefix = "abc") private String abcAge`  当生成`get`/`set`方法时, 会把此前缀去掉. 

- `@Synchronized`: 给方法加上同步锁. 

- `@Builder`: `@Builder`注释为你的类生成复杂的构建器`API`: 

  ```
  Person.builder().name("Adam Savage").city("San Francisco").job("Mythbusters").job("Unchained Reaction").build();
  ```

- `@NonNull`: 如其名, 不能为空, 否则抛出`NullPointException`

- `Log`类: 

  ```java
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
  
- `@SneakyThrows`: 将 Checked Exception 转换成 `RuntimeException`


`Lombok`的功能不仅如此, 更详细请看***[features](https://projectlombok.org/features/all)***

## Docker Integration

可以通过IDEA链接Docker API, 前提是开启了Docker API

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/docker-integration01.png)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/docker-integration02.png)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/docker-integration03.png)

## Zookeeper

Zookeeper UI, 支持删除操作

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/zookeeper-plugin1.png)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/zookeeper-plugin2.png)

## K8s工具：Kubernetes

参考 *[https://plugins.jetbrains.com/plugin/10485-kubernetes](https://plugins.jetbrains.com/plugin/10485-kubernetes)* 支持编辑 Kubernetes 资源文件, 如下： 可以比较方便的查看yaml中的各项 placeholder 的默认值, 且可以方便的链接到value位置。

## GsonFormat

复制一段JSON格式字符串

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/gson-format01.png)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/gson-format02.png)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/gson-format03.png)

## POJO to JSON

为了测试需要, 我们需要将简单 Java 领域对象转成 JSON 字符串方便用 postman 或者 curl 模拟数据。详细使用文档, 参考：*[https://plugins.jetbrains.com/plugin/9686-pojo-to-json](https://plugins.jetbrains.com/plugin/9686-pojo-to-json)*

## CamelCase

下划线转驼峰插件, 安装好之后可通过快捷键 `Shift+Alt+U` 更换驼峰.

## Grep Console

参考：*[https://plugins.jetbrains.com/plugin/7125-grep-console](https://plugins.jetbrains.com/plugin/7125-grep-console)*

## Free Mybatis Plugin

可以直接从Mapper文件跳转到xml: 

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/free-mybatis.png)

## MyBatisCodeHelper-Pro

插件地址: ***[https://github.com/gejun123456/MyBatisCodeHelper-Pro](https://github.com/gejun123456/MyBatisCodeHelper-Pro)***

Crack: ***[https://github.com/pengzhile/MyBatisCodeHelper-Pro-Crack](https://github.com/pengzhile/MyBatisCodeHelper-Pro-Crack)***

## Ali规约插件 P3C

插件地址: ***[https://github.com/alibaba/p3c](https://github.com/alibaba/p3c)***
文档: ***[https://github.com/alibaba/p3c/blob/master/idea-plugin/README_cn.md](https://github.com/alibaba/p3c/blob/master/idea-plugin/README_cn.md)***

## FindBugs
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/find-bug.png)
装完之后右键最下面会多出一个`FindBugs`的选项

## Maven Helper

这个主要可以分析maven依赖冲突. 

安装之后, 打开`pom.xml`文件, 会看到多了一个Dependency Analyzer的面板, 点击可以进入分析面板: 

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/maven-helper01.png)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/maven-helper02.png)

另外, 右键项目也会多两个Maven的bar: 

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/maven-helper03.png)

## Statistic

这个插件可以统计代码数量: 

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/maven-helper04.png)

## Stackoverflow

看名字就知道这个是干嘛的啦, 在plugin repostories直接搜索stackoverflow就找得到

重启后随便选中内容右键就可以看到

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-stackoverflow.png)

## Background Image Plus

这是一个设置背景图的插件

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/background-image-plus.png)

**在 2020+ 版本中已经自带设置背景功能**:

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/setting-background-image.png)

## Translation

详细使用文档, 参考：***[https://github.com/YiiGuxing/TranslationPlugin](https://github.com/YiiGuxing/TranslationPlugin)***

有道智云: ***[https://ai.youdao.com/](https://ai.youdao.com/)***

快捷键:

* 翻译: `Ctrl` + `Shift` + `Y`
* 翻译并替换: `Ctrl` + `Shift` + `X`

## Enso

它可以将测试名转化成一个句子, 一目了然地显示测试的内容. 这意味着当你在注视任何类的时候, Enso 都会展示其说明文档. 

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/plugin-enso.png)

## Rainbow Brackets

> ***[https://github.com/izhangzhihao/intellij-rainbow-brackets](https://github.com/izhangzhihao/intellij-rainbow-brackets)***

这个可以实现配对括号相同颜色, 并且实现选中区域代码高亮的功能, 对增强写代码的有趣性和排错等都有一些帮助。

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/with-material-theme-ui.png)

高亮效果:  Ctrl+鼠标右键单击

选中部分外暗淡效果: Alt+鼠标右键单击

## Checkstyle

`checks.xml`: *[https://github.com/ningg/checkstyle/blob/master/src/main/resources/google_checks.xml](https://github.com/ningg/checkstyle/blob/master/src/main/resources/google_checks.xml)*

安装完以后在 Other Settings 中配置 Checkstyle:

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/check-style-config-2-configure.png)

利用 Checkstyle 进行 check: (3 种, 可以使用一种)

- `Check Current file`
- `Check All Modified file`
- `Check Project`

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/check-style-config-3-usage.png)

## Jclasslib

> 这是一个查看Java字节码的插件

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-plugin-jclasslib.png)

## JOL

> Java Object Layout, 查看Java对象大小的插件

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-plugin-jol.png)

## VisualVM Launcher

启动 Java 应用时启动 VisualVM 查看堆占用等情况.

> 需要 *[下载 Visualvm](https://visualvm.github.io/download.html)* 并在 IDEA 中配置启动路径.

# Theme

## Cyan Light Theme

***[https://plugins.jetbrains.com/plugin/12102-cyan-light-theme](https://plugins.jetbrains.com/plugin/12102-cyan-light-theme)*** 

个人觉得比较舒适的主题, 清新, 没有多余的花里胡哨.

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/theme-cyan.png)

## Material Theme

漂亮的主题插件, 内置了多种主题, 主题浏览: ***[https://www.material-theme.com/](https://www.material-theme.com/)***

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/theme-material-oceanic.png)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/theme-material-github.png)

配置说明: ***[Material Theme UI详解](https://blog.csdn.net/zyx1260168395/article/details/102928172)***

# Icons

## Atom Material Icons

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/atom-material-icons.png)

# Skills

## 演出模式

此模式将`IDEA`弄到最大, 可以让你只关注一个类里面的代码, 进行毫无干扰的`coding`. 

可以使用`Alt+V`快捷键, 弹出`View`视图, 然后选择`Enter Presentation Mode`

若`Alt+V`没有设置快捷键, 可在`Keymap`中设置: 

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/keymap-view.png)

退出: 使用`ALT+V`弹出view视图, 然后选择`Exit Presentation Mode` 即可. 

## Inject language 编辑JSON

如果使用`IDEA`在编写`JSON`字符串的时候, 然后要一个一个`\`去转义双引号的话, 就实在太不应该了, 又烦又容易出错. 在`IDEA`可以使用`Inject language`帮我们自动转义双引号. 

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/inject-language.png)

然后搜索`json`: 

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/inject-language-json.png)

选择完后. 鼠标焦点自动会定位在双引号里面, 这个时候你再次使用`alt+enter`就可以看到 :

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/inject-language-json-edit-new.png)

选中`Edit JSON Fragment`并回车, 就可以看到编辑`JSON`文件的视图了:

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/inject-language-json-edit-result.png)

## 使用快捷键移动分割线

有时候想要拖拉项目视图的分割线: 

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/project-view-hide.png)

可以先`alt+1`把鼠标焦点定位到`project`视图里, 然后直接使用`ctrl+shift+左右箭头`来移动分割线. 

再按`esc`返回代码. 

## 把鼠标定位到project视图里

使用`alt+F1`, 弹出`Select in`视图, 然后选择`Project View`中的`Project`, 回车, 就可以立刻定位到类的位置了. 

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/locate-project.png)

使用`esc`或者`F4`跳回代码. 

## 自动生成not null判断语句

变量后输入`.not`或者`.nn`: 

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/edit-notnull.png)

更多模板可查看设置中的`Postfix Completion`. 

## 生成 Try Catch

使用`Ctrl + w`选中区域后按下`Ctrl + Shift + t`:

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/try-catch.png)

# VM Options

可以通过ToolBox或IDEA选项里面设置

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/vmoption1.jpg)

![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/vmoption2.jpg)

优化参数(32G内存): 

```
-server
-Xms2048m
-Xmx4096m
-Xmn1024m
-XX:MetaspaceSize=256m
-XX:MaxMetaspaceSize=2048m
-XX:ReservedCodeCacheSize=512m
-XX:+UseG1GC
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

**部分参数说明**: 

`-Xms2048m`: 初始时内存大小, 至少为`Xmx`的二分之一

`-Xmx2048m`: 最大内存大小, 若总内存小于2GB, 至少为总内存的四分之一；若总内存大于2GB, 设为1-4GB

`-XX:+UseG1GC -XX:-UseParNewGC -XX:-UseConcMarkSweepGC`: 设置使用G1垃圾收集器 

`-server`: JVM以server的方式运行, 启动速度慢, 运行速度快

`-Dsun.awt.keepWorkingSetOnMinimize=true`: 让IDEA最小化后阻止JVM对其进行修剪

# Conflict of keyboard shortcuts

快捷键有冲突, 创建脚本并执行: 
```bash
#!/bin/bash  
gsettings set org.gnome.desktop.wm.keybindings toggle-shaded "[]" 
gsettings set org.gnome.settings-daemon.plugins.media-keys screencast "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "[]" 
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "[]"
gsettings set org.gnome.desktop.wm.keybindings begin-move "[]" 
```

如果是习惯Windows下的快捷键, 那么可以**禁用TTY**（IDEA Ctrl+Alt+F1-6冲突）: 

```
FILE_NAME=/usr/share/X11/xorg.conf.d/50-novtswitch.conf &&\
sudo touch ${FILE_NAME} && \
sudo tee ${FILE_NAME} << EOF
 Section "ServerFlags"
Option "DontVTSwitch" "true"
EndSection
EOF
```

**目前发现的快捷键冲突: **
1、`Ctrl+Alt+方向`, 直接到系统设置里面改: 
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-setting-keyboard.png)

2、安装了搜狗之后, 按`Ctrl+Alt+B`会启动虚拟键盘, 所以在输入法里面打开Fcitx设置, 在附加组件里面, 点击高级, 再把虚拟键盘的选项去掉: 
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/idea-sougou-conflict.png)
然后注销或重启电脑. 

3、`Ctrl+Alt+S`, 这个在键盘设置里面找了很久, 原来这玩意在输入法设置里面, 点开输入法全局配置, 把**显示高级选项**钩上, 就会看到很多快捷键, 我都把它们干掉了. 
![](https://cdn.yangbingdong.com/img/learning-idea-under-ubuntu/shurufa.png)


# Finally
> IDEA真的智能到没朋友...
> 如果喜欢IDEA这款软件, 并且有经济能力的, 请付费购买~







