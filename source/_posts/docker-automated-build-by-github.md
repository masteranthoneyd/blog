---
title: 使用Github自动构建Docker
date: 2017-09-18 18:07:18
categories: [Docker]
tags: [Docker,Automated]
---

![](http://ojoba1c98.bkt.clouddn.com/ima/docker-automated-built/github-docker.jpg)

> 一开始玩Docker总是用别人的镜像确实很爽~~歪歪~~...
> But，如果要定制个性化的Image那就必须要自己写Dockerfile了，但是每一次修改完Dockerfile，都要经过几个步骤：
> Built -> Push -> Delete invalid images
> 对于程序猿而言做重复的事情是很恐怖的，所以博主选择Github自动构建Docker Image~

<!--more-->

# Create automated repo
在Github上面创建一个项目并把Dockerfile以及上下文需要用到的文件放到里面。
Dockerfile的讲解不在本篇范围内～

# Integrations

找到项目Settings，添加Docker集成

![](http://ojoba1c98.bkt.clouddn.com/ima/docker-automated-built/github-docker-server.png)

# Link repository service
首先需要绑定一个仓库服务（Github）：

1、登录`Docker Hub`；
2、选择 `Profile` > `Settings` > `Linked Accounts & Services`；
3、选择需要连接的仓库服务（目前只支持`Github`和`BitBucket`）；
4、这时候需要授权，点击授权就可以了。
![](http://ojoba1c98.bkt.clouddn.com/ima/docker-automated-built/add-repo-service.png)

# Create an automated build
自动构建需要创建对应的仓库类型
自动构建仓库也可以使用`docker push`把已有的镜像上传上去
1、选择`Create` > `Create Automated Build`；
2、选择`Github`；
3、接下来会列出`User/Organizations`的所有项目，从中选择你需要的构建的项目（包含Dockerfile）；
4、可以选择`Click here to customize`自定义路径；
5、最后点击创建就可以了。
![](http://ojoba1c98.bkt.clouddn.com/ima/docker-automated-built/create-automated.png)
![](http://ojoba1c98.bkt.clouddn.com/ima/docker-automated-built/creating.png)

# Add integration service
用过`Github`自动构建当然需要`Github`的支持啦，这里只需要在Github里面点两下就配置完成，很方便：
![](http://ojoba1c98.bkt.clouddn.com/ima/docker-automated-built/add-integrations.png)
在`Add Service`里面找到`Docker`并添加。

# Use the Build Settings page
## Automated
系统会默认帮我们勾上自动构建选项：
![](http://ojoba1c98.bkt.clouddn.com/ima/docker-automated-built/aotumated-setting.png)
这时候，当我们的Dockerfile有变动会自动触发构建：
![](http://ojoba1c98.bkt.clouddn.com/ima/docker-automated-built/building.png)
还在构建过程中我们可以点击Cancel取消构建过程。

## Add new build
Docker hub默认选择master分支作为latest版本，我们可以根据自己的标签或分支构建不同的版本：
![](http://ojoba1c98.bkt.clouddn.com/ima/docker-automated-built/add-build.png)

（点击箭头位置会出现例子）
这样，当我们创建一个标签如1.0.2并push上去的时候会自动触发构建～

`Git`标签相关请看：***[Git标签管理](/2017/note-of-learning-git/#标签管理)***

## Remote Build triggers
当然我们也可以远程触发构建，同样在Build Setting页面:
![](http://ojoba1c98.bkt.clouddn.com/ima/docker-automated-built/remote-trigger.png)
然后例子已经说的很清楚了

# Finally
> 参考：***[https://docs.docker.com/docker-hub/builds/](https://docs.docker.com/docker-hub/builds/)***