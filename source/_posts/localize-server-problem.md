---
title: 线上问题定位常用技巧
date: 2019-05-05 17:09:02
categories:[Java, MAT]
tags:[Programming, Java]
---

![](https://cdn.yangbingdong.com/img/online-debug/locate.png)

# Preface

> 线上问题无可避免, 人为BUG, 系统资源限制等, 通过合理的手段可让问题现出原形, 这里记录一些常用的排查手段.

<!--more-->

# 线上问题定位常用方法

## 查找Java进程

### top

`top` 命令定位进程: 输入`top`命令后，可以按P(shift+p)根据cpu占用排序、按M根据内存占用排序、按T根据运行时间排序.

### jps

通过 `jps -mlvV` 可以查看当前运行中的Java进程.

> 原理：java程序启动后，默认会在`/tmp/hsperfdata_userName`目录下以该进程的id为文件名新建文件，并在该文件中存储jvm运行的相关信息，其中的userName为当前的用户名，`/tmp/hsperfdata_userName`目录会存放该用户所有已经启动的java进程信息.而jps、jconsole等工具的数据来源就是这个文件（`/tmp/hsperfdata_userName/pid`)。所以当该文件不存在或是无法读取时就会出现jps无法查看该进程号，jconsole无法监控等问题.

## CPU100%问题快速定位

### 步骤一: 找到最耗CPU的进程
1、执行top -c ，显示进程运行信息列表
2、键入P (大写p)，进程按照CPU使用率排序
3、第一个进程为最耗CPU，假设其PID为 2333

### 步骤二: 找到最耗CPU的线程
1、top -Hp 2333 ，显示一个进程的线程运行信息列表
2、键入P (大写p)，线程按照CPU使用率排序
3、第一个为最耗CPU线程，假设其PID为 666

### 步骤三: 将线程PID转化为16进制
输入: `printf "%x\n" 666` 得到 29a
666对应的16进制是0x29a
之所以要转化为16进制，是因为堆栈里，线程id是用16进制表示的

### 步骤四: 查看堆栈，找到线程在干嘛
`jstack 2333 | grep "0x29a" -C5 --color`
即可打印堆栈.

## 内存OOM问题定位

### 一、确认是不是内存本身就分配过小
命令: `jmap -heap ${PID}`
注意：Ubuntu系统需要修改一下配置 打开`/etc/sysctl.d/10-ptrace.conf` 修改为：`kernel.yama.ptrace_scope = 0` (即将1改成0)

### 二、找到最耗内存的对象
命令: `jmap -histo:live ${PID} | more`
### 三、确认是否是资源耗尽

* 查看进程的线程数量: `ll /proc/${PID}/task | wc -l`, 效果等同 `pstree -p | wc -l`

```
$ ll /proc/17608/task | wc -l
74
```

> 如果看到启用了大量线程，就需要审查代码涉及到线程池的使用部分，是否限定了最大线程数量。

* 查询进程占用的句柄数量: `ll /proc/${PID}/fd | wc -l`

```
$ ll /proc/17608/fd | wc -l
224
```

`jmap -heap`输出的非自定义类名说明：

| BaseType Character | Type      | Interpretation                        |
| ------------------ | --------- | ------------------------------------- |
| B                  | byte      | signed byte                           |
| C                  | char      | Unicode character                     |
| D                  | double    | double-precision floating-point value |
| F                  | float     | single-precision floating-point value |
| I                  | int       | integer                               |
| J                  | long      | long integer                          |
| L;                 | reference | an instance of class                  |
| S                  | short     | signed short                          |
| Z                  | boolean   | true or false                         |
| [                  | reference | one array dimension                   |

## JFR & JMC

```
Jcmd <pid> JFR.start duration=120s filename=myrecording.jfr
```

然后，使用 JMC 打开“.jfr 文件”就可以进行分析了，方法、异常、线程、IO 等应有尽有，其功能非常强大

# MAT(Memory Analyzer Tool)

> MAT是一款高性能, 具备丰富功能的Java堆内存分析工具, 可以用来排查内存泄漏和内存浪费的问题.
>
> 下载地址: ***[https://www.eclipse.org/mat/downloads.php](https://www.eclipse.org/mat/downloads.php)***

## 配置

下载解压后, 目录中有个 `MemoryAnalyzer.ini` 的文件, 该文件里面有个 `Xmx` 参数, 该参数表示最大内存占用量, 默认为 `1024m`, 根据堆转储文件大小修改该参数即可.

MAT默认的存储展示单位是 `Bytes`, 可在 `Window` -> `Preferences` 中设置:

![](https://cdn.yangbingdong.com/img/online-debug/mat-setting.png)

1. Keep unreachable objects：如果勾选这个，则在分析的时候会包含dump文件中的不可达对象；
2. Hide the getting started wizard：隐藏分析完成后的首页，控制是否要展示一个对话框，用来展示内存泄漏分析、消耗最多内存的对象排序。
3. Hide popup query help：隐藏弹出查询帮助，除非用户通过F1或Help按钮查询帮助。
4. Hide Welcome screen on launch：隐藏启动时候的欢迎界面
5. Bytes Display：设置分析结果中内存大小的展示单位

## 获取堆转储文件

* 主动获取:

  ```
  jmap -dump:format=b,file=<dumpfile.hprof> <pid>
  
  # 或者
  jmap -dump:live,format=b,file=<dumpfile.hprof> <pid>
  ```

  `live` 参数: 这个参数表示我们需要抓取目前在生命周期内的内存对象, 也就是说GC收不走的对象, 然后我们绝大部分情况下, 需要的看的就是这些内存.

* 内存溢出时自动dump, 在启动参数中添加:

  ```
  -XX:+HeapDumpOnOutOfMemoryError
  ```

  在Java进程运行过程中发生OOM的时候就会生成一个heapdump文件，并写入到指定目录，一般用`-XX:HeapDumpPath=${HOME}/dump/test`来设置.

## Shallow Retained 区别

当我们打开 `Histogram` (从类的视角出发) 或者 `Dominator Tree` (从对象的视角出发) 时, 开到 `Shallow Heap` 和 `Retained Heap` 这两列.

简单地说, `Shallow` 只是对象本身所占用的大小, 而 `Retained` 则包含了引用对象的大小.

![](https://cdn.yangbingdong.com/img/online-debug/dump-file-opened.png)

# 转载-如何应对在线故障

> 原创出处: ***[http://www.rowkey.me/blog/2018/11/22/online-debug/](http://www.rowkey.me/blog/2018/11/22/online-debug/)***

![](https://cdn.yangbingdong.com/img/online-debug/online-debug01.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug02.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug03.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug04.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug05.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug06.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug07.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug08.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug09.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug10.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug11.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug12.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug13.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug14.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug15.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug16.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug17.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug18.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug19.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug20.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug21.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug22.jpeg)

![](https://cdn.yangbingdong.com/img/online-debug/online-debug23.jpeg)

# Finally

> 参考：
>
> ***[https://mp.weixin.qq.com/s/-K56NWVFiFsL8JSIH42QMA](https://mp.weixin.qq.com/s/-K56NWVFiFsL8JSIH42QMA)***
>
> ***[https://zhuanlan.zhihu.com/p/43435903](https://zhuanlan.zhihu.com/p/43435903)***
