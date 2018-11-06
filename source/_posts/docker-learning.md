---
title: Docker入坑笔记
date: 2017-09-07 15:55:07
categories: [Docker]
tags: [Docker]
---
![](https://cdn.yangbingdong.com/img/docker/docker.png)
# Preface
> Docker是什么？下面是官方的一段说明：
> ***[Docker is the world’s leading software containerization platform.](https://www.docker.com/what-docker)***
> 恩，很`niubility`，引领世界软件容器化的平台...
> 本篇主要记录Docker的基础学习（安装、简单使用）

<!--more-->
# Containerization VS Virtualization
了解Docker之前，我们有必要了解一下容器化
![](https://cdn.yangbingdong.com/img/docker/compare-container-and-docker2.jpg)

![](https://cdn.yangbingdong.com/img/docker/compare-container-and-docker.jpg)

**容器相当于轻量级的虚拟机，但隔离性不如虚拟机**。

# Story

![](https://cdn.yangbingdong.com/img/docker/old-dev-ops.jpg)

Long long ago...

Dev: "帮我构建几台跟生产环境一样的测试服务器"

Ops: "给我一个星期时间"

Dev: "明天用..."



Ops: "开发的这群傻叉新给的发布包又把系统CPU搞到100%了，应用又夯住了，都是些什么水平的人啊..."

Dev: "运维的这帮傻鸟技术太差，维护的是些什么稀烂的系统，在我这跑得好好的，上他们那应用就挂..."

Ops: "这是开发的锅..."

Dev: "这是运维的盘..."

Q：

- 线上线下环境不一致，线上JDK1.8.01,线下JDK1.8.02，数据库版本不统一等环境问题
- 单机安装和配置MySQL、Memcatched、MongoDB、Hadoop、GlusterFS、RabbitMQ、Node.js、Nginx已经够复杂，集群更不用说



最终引发的问题就是，我们的服务方是用户，受害方也是用户...

各司其职的同时也在两者之间形成了一面无形的墙，阻碍了开发和运维之间的沟通和协作，而**Docker**、**DevOps**的出现就是为了击碎这堵无形之墙。

# Docker

**核心理念**：Build，Ship，and Run Any App，Anywhere

(Java的核心理念：Write once, run anywhere)

![](https://cdn.yangbingdong.com/img/docker/container-history.jpg)

**Docker是`GO`语言编写的容器化的一种实现**，是一个**分布式**应用**构建**、**迁移**和**运行**的开放平台，它允许开发或运维人员将应用和运行应用所**依赖的文件打包到一个标准化的单元**（容器）中运行。其他的容器实现有**OpenVZ**，**Pouch**(`Ali`出品)等。

**服务器**好比运输码头：拥有场地和各种设备（服务器硬件资源）

**服务器容器化**好比作码头上的仓库：拥有独立的空间堆放各种货物或集装箱

(仓库之间完全独立，独立的应用系统和操作系统）

**实现的核心技术**: lcx、cgroup、namespaces...（Linux内核级别隔离技术）

**注意点**: 不能乱玩...遵循**单一职责**，**无状态**。

# Docker实现DevOps的优势

**优势一**:

开发、测试和生产环境的**统一化**和**标准化**。镜像作为标准的交付件，可在开发、测试和生产环境上以容器来运行，最终实现三套环境上的应用以及运行所**依赖内容的完全一致**。

**优势二**:

**解决底层基础环境的异构问题**。基础环境的多元化造成了从Dev到Ops过程中的阻力，而使用Docker Engine可无视基础环境的类型。不同的物理设备，不同的虚拟化类型，不同云计算平台，只要是运行了Docker Engine的环境，最终的应用都会以容器为基础来提供服务。

**优势三**:

易于**构建**、**迁移**和**部署**。Dockerfile实现镜像构建的标准化和可复用，镜像本身的分层机制也提高了镜像构建的效率。使用Registry可以将构建好的镜像迁移到任意环境，而且环境的部署仅需要将静态只读的镜像转换为动态可运行的容器即可。

**优势四**:

**轻量**和**高效**。和需要封装操作系统的虚拟机相比，容器仅需要封装应用和应用需要的依赖文件，实现轻量的应用运行环境，且拥有比虚拟机更高的硬件资源利用率。

**优势五**:

工具链的标准化和快速部署。将实现DevOps所需的多种工具或软件进行Docker化后，可在任意环境实现一条或多条工具链的快速部署。

适合**敏捷开发**、**持续交付**

# 核心概念

以下是Docker的三个基本概念。

## Image(镜像)
官方而言，Docker 镜像是一个**特殊的文件系统**，除了提供容器运行时所需的程序、库、资源、配置等文件外，还包含了一些为运行时准备的一些配置参数（如匿名卷、环境变量、用户等）。镜像不包含任何动态数据，其内容在构建之后也不会被改变。
对博主而言，它相当于就是个`Java Class`(类)=.=

但它的存储结构类似`Git`，一层一层地网上盖，**删除一个文件并不会真的删除**，只是在那个文件上面做了一个标记为已删除。在最终容器运行的时候，虽然不会看到这个文件，但是实际上该文件会**一直跟随镜像**。因此，在构建镜像的时候，需要额外小心，**每一层尽量只包含该层需要添加的东西**，任何额外的东西应该在该层构建结束前清理掉。

## Container(容器)

![](https://cdn.yangbingdong.com/img/docker/docker-component.jpg)

通俗来说，如果镜像是类，那么容器就是这个类的实例了，镜像是静态的定义，容器是镜像运行时的实体。容器可以被创建、启动、停止、删除、暂停等。

容器也有其特性，例如存储，不指定数据卷(`Volume`)的话，容器消亡数据也就跟着没了...
跟多特性请自行百度~

## Repository(仓库)
仓库没啥好说的了，以 `Ubuntu` 镜像 为例，`ubuntu` 是仓库的名字，其内包含有不同的版本标签，如，`14.04`, `16.04`。我们可以通过 `ubuntu:14.04`，或者 `ubuntu:16.04` 来具体指定所需哪个版本的镜像。如果忽略了标签，比如 `ubuntu`，那将视为 `ubuntu:latest`

# 安装
这里以Ubuntu为例（当然是因为博主用的是Ubuntu= =），版本的话Docker目前支持的Ubuntu版本最低为12.04LTS,但从稳定性上考虑,推荐使用14.04LTS或更高的版本。

## 使用脚本自动安装
在测试或开发环境中 Docker 官方为了简化安装流程，提供了一套便捷的安装脚本，Ubuntu 系统上可以使用这套脚本安装：
```
curl -fsSL get.docker.com -o get-docker.sh
sudo sh get-docker.sh --mirror Aliyun
```
执行这个命令后，脚本就会自动的将一切准备工作做好，并且把 Docker 安装在系统中

## 使用 APT 镜像源 安装
```
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
```
鉴于国内网络问题，强烈建议使用国内源

### 国内源
```
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
    "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
```
以上命令会添加 稳定 版本的 Docker CE APT 镜像源，如果需要最新版本的 Docker CE 请将 `stable` 改为 `edge` 或者 `test` 。从 Docker 17.06 开始，`edge` `test` 版本的 APT 镜像源也会包含稳定版本的 Docker

### 官方源
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
```

### 安装 Docker CE
```
sudo apt-get update
sudo apt-get install docker-ce
```

## 启动 Docker CE
```
sudo systemctl enable docker
sudo systemctl start docker
```

## 建立 docker 用户组
默认情况下，`docker` 命令会使用 [Unix socket](https://en.wikipedia.org/wiki/Unix_domain_socket) 与 Docker 引擎通讯。而只有 `root` 用户和 `docker` 组的用户才可以访问 Docker 引擎的 Unix socket。出于安全考虑，一般 Linux 系统上不会直接使用 `root` 用户。因此，更好地做法是将需要使用 `docker` 的用户加入 `docker` 用户组。
建立 `docker` 组(貌似执行了自动安装脚本会自动建一个docker的用户组)：
```
sudo groupadd docker
```

将当前用户加入 `docker` 组：
```
sudo usermod -aG docker $USER
```
加入`docker` 组之后要**重启才能生效**哦...


## Mirror Acceleration

没有代理的话国内访问[Docker Hub](https://hub.docker.com/)的速度实在感人，但Docker官方和国内很多云服务商都提供了加速器服务：
- [Docker 官方提供的中国registry mirror](https://docs.docker.com/registry/recipes/mirror/#use-case-the-china-registry-mirror)
- [阿里云加速器](https://cr.console.aliyun.com/#/accelerator)
- [DaoCloud 加速器](https://www.daocloud.io/mirror#accelerator-doc)
- [灵雀云加速器](http://docs.alauda.cn/feature/accelerator.html)

如阿里，注册并申请后会得到加速域名如`https://vioqnt8w.mirror.aliyuncs.com`，然后正如官方说的一样，通过修改`daemon`配置文件`/etc/docker/daemon.json`来使用加速器：
```
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://vioqnt8w.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

查看生效：

```
sudo docker info|grep "Registry Mirrors" -A 1
```

输出如下：

```
Registry Mirrors:
 https://vioqnt8w.mirror.aliyuncs.com/
```

# 镜像的相关操作
## 获取
[**Docker Hub**](https://hub.docker.com/explore/) 上有大量的高质量的镜像可以用，我们可以通过以下的方式获取镜像：
```
docker pull [选项] [Docker Registry地址]<仓库名>:<标签>
```
选项可以通过`docker pull --help`查看。
eg，从Docker Hub下载`REPOSITORY`为`java`的所有镜像：
```
docker pull -a java
```

## 列出
使用`docker images [OPTIONS] [REPOSITORY[:TAG]]`列出已下载的镜像
![](https://cdn.yangbingdong.com/img/docker/docker-images.png)
列表包含了仓库名、标签、镜像 ID、创建时间以及所占用的空间

OPTIONS说明：
```
-a :列出本地所有的镜像（含中间映像层，默认情况下，过滤掉中间映像层）；
--digests :显示镜像的摘要信息；
-f :显示满足条件的镜像；
--format :指定返回值的模板文件；
--no-trunc :显示完整的镜像信息；
-q :只显示镜像ID。
```
eg:
```
# 看到在 mongo:3.2 之后建立的镜像,想查看某个位置之前的镜像也可以，只需要把 since 换成 before 即可
docker images -f since=mongo:3.2
```

### 虚悬镜像(dangling image)
举个例子：原来为 `mongo:3.2`，随着官方镜像维护，发布了新版本后，重新 `docker pull mongo:3.2` 时，`mongo:3.2` 这个镜像名被转移到了新下载的镜像身上，而旧的镜像上的这个名称则被取消，从而成为了 `<none>`。除了 `docker pull` 可能导致这种情况，`docker build` 也同样可以导致这种现象。由于新旧镜像同名，旧镜像名称被取消，从而出现仓库名、标签均为 `<none>` 的镜像。这类无标签镜像也被称为 **虚悬镜像(dangling image)** ，可以用下面的命令专门显示这类镜像：
```shell
docker images -f dangling=true
```

一般来说，虚悬镜像已经失去了存在的价值，是可以随意删除的，可以用下面的命令删除：
```bash
docker rmi $(docker images -q -f dangling=true)
```

## Commit
从容器创建一个新的镜像:
```shell
docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]
```

OPTIONS说明：
```
-a :提交的镜像作者；
-c :使用Dockerfile指令来创建镜像；
-m :提交时的说明文字；
-p :在commit时，将容器暂停。
```
eg:
```
docker commit -a "ybd" -m "my apache" a404c6c174a2  mymysql:v1 
```

当我们修改了镜像文件提交时候，可以使用`docker diff [OPTIONS] CONTAINER`查看修改了什么东西。
一般地，不推荐使用`commit`来构建镜像，之前也提过，镜像是特殊的文件系统，改了东西之后原来的基础之上叠加，使之变得**越来越臃肿**。此外，使用 `docker commit` 意味着所有对镜像的操作都是黑箱操作，生成的镜像也被称为**黑箱镜像**，换句话说，就是除了制作镜像的人知道执行过什么命令、怎么生成的镜像，别人根本无从得知。一般我们会使用`Dockerfile`定制镜像。

## 删除
删除镜像可以使用：
```
docker rmi [OPTIONS] IMAGE [IMAGE...]
```

OPTIONS说明：
```
-f :强制删除；
--no-prune :不移除该镜像的过程镜像，默认移除；
```

一般会组合使用：

```shell
docker rmi $(docker images -q -f dangling=true)

docker rmi $(docker images -q redis)

docker rmi $(docker images -q -f before=mongo:3.2)
```

## 查看元数据

docker inspect : 获取容器/镜像的元数据。

```
docker inspect [OPTIONS] CONTAINER|IMAGE [CONTAINER|IMAGE...]
```

OPTIONS说明：

```
-f :指定返回值的模板文件。
-s :显示总的文件大小。
--type :为指定类型返回JSON。
```

**实例**

获取镜像mysql:5.6的元信息。

```
~: docker inspect mysql:5.6
[
    {
        "Id": "sha256:2c0964ec182ae9a045f866bbc2553087f6e42bfc16074a74fb820af235f070ec",
        "RepoTags": [
            "mysql:5.6"
        ],
        "RepoDigests": [],
        "Parent": "",
        "Comment": "",
        "Created": "2016-05-24T04:01:41.168371815Z",
        "Container": "e0924bc460ff97787f34610115e9363e6363b30b8efa406e28eb495ab199ca54",
        "ContainerConfig": {
            "Hostname": "b0cf605c7757",
            "Domainname": "",
            "User": "",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "ExposedPorts": {
                "3306/tcp": {}
            },
...
```

获取正在运行的容器mymysql的 IP。

```
~: docker inspect -f '' mymysql
172.17.0.3
```

查看容器内部IP：

```
docker inspect --format='{\{.NetworkSettings.IPAddress}}' CONTAINER
（注：由于代码块解析的问题，上面NetworkSettings前面的 \ 去掉）
```

## 标签

docker tag：

```
docker tag IMAGE/CONTAINER TAG
```

ex：

```
将同一IMAGE_ID的所有tag，合并为一个新的
# docker tag 195eb2565349 ybd/ubuntu:rm_test
新建一个tag，保留旧的那条记录
# docker tag Registry/Repos:Tag New_Registry/New_Repos:New_Tag
```

## 保存镜像到归档文件

docker save : 将指定镜像保存成 tar 归档文件。

```
docker save [OPTIONS] IMAGE [IMAGE...]

```

OPTIONS说明：

```
-o :输出到的文件。
```

**实例**

将镜像runoob/ubuntu:v3 生成my_ubuntu_v3.tar文档

runoob@runoob:~$ docker save -o my_ubuntu_v3.tar runoob/ubuntu:v3

## 导入镜像

### Import

docker import : 从归档文件中创建镜像。

```
docker import [OPTIONS] file|URL|- [REPOSITORY[:TAG]]
```

OPTIONS说明：

```
-c :应用docker 指令创建镜像；

-m :提交时的说明文字；
```

例如：

```
docker import  ubuntu.tar ybd/ubuntu:v1
```

### Load

Usage:	docker load [OPTIONS]

Load an image from a tar archive or STDIN

Options:

```
  -i, --input string   Read from tar archive file, instead of STDIN

  -q, --quiet          Suppress the load output
```

### 区别

1. 首先，docker import可以重新指定镜像的名字，docker load不可以
2. 其次，我们发现导出后的版本会比原来的版本稍微小一些。那是因为导出后，会丢失历史和元数据。执行下面的命令就知道了： 
   显示镜像的所有层(layer) 
   `docker images --tree` 
   执行命令，显示下面的内容。正你看到的，导出后再导入(exported-imported)的镜像会丢失所有的历史，而保存后再加载（saveed-loaded）的镜像没有丢失**历史和层(layer)**。这意味着使用导出后再导入的方式，你将无法回滚到之前的层(layer)，同时，使用保存后再加载的方式持久化整个镜像，就可以做到**层回滚**（可以执行docker tag 来回滚之前的层）。

# 容器的相关操作

## 开启
docker run ：创建一个新的容器并运行一个命令 docker create ：创建一个新的容器但不启动它
```
docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
docker create [OPTIONS] IMAGE [COMMAND] [ARG...]
```

docker run OPTIONS说明：
```
-a stdin: 指定标准输入输出内容类型，可选 STDIN/STDOUT/STDERR 三项；

-d: 后台运行容器，并返回容器ID；

-i: 以交互模式运行容器，通常与 -t 同时使用；

-t: 为容器重新分配一个伪输入终端，通常与 -i 同时使用；

-v: 挂载数据卷

--name="nginx-lb": 为容器指定一个名称；

--restart=always: docker启动容器也跟着启动

--dns 8.8.8.8: 指定容器使用的DNS服务器，默认和宿主一致；

--dns-search example.com: 指定容器DNS搜索域名，默认和宿主一致；

-h "mars": 指定容器的hostname；

-e username="ritchie": 设置环境变量；

--env-file=[]: 从指定文件读入环境变量；

--cpuset="0-2" or --cpuset="0,1,2": 绑定容器到指定CPU运行；

-m :设置容器使用内存最大值；

--net="bridge": 指定容器的网络连接类型，支持 bridge/host/none/container: 四种类型；

--link=[]: 添加链接到另一个容器；

--expose=[]: 开放一个端口或一组端口；  <b>实例</b>
```
例如，启动一个 bash 终端，允许用户进行交互：
```
docker run -t -i ubuntu:14.04 /bin/bash
```

当利用 `docker run` 来创建容器时，Docker 在后台运行的标准操作包括：
- 检查本地是否存在指定的镜像，不存在就从公有仓库下载
- 利用镜像创建并启动一个容器
- 分配一个文件系统，并在只读的镜像层外面挂载一层可读写层
- 从宿主主机配置的网桥接口中桥接一个虚拟接口到容器中去
- 从地址池配置一个 ip 地址给容器
- 执行用户指定的应用程序
- 执行完毕后容器被终止

启动一个es并指明healthcheck相关策略：

```
docker run --rm -d \
    --name=elasticsearch \
    --health-cmd="curl --silent --fail localhost:9200/_cluster/health || exit 1" \
    --health-interval=5s \
    --health-retries=12 \
    --health-timeout=2s \
    elasticsearch:5.5
```

## 暂停

docker pause :暂停容器中所有的进程。

docker unpause :恢复容器中所有的进程。

```
docker pause [OPTIONS] CONTAINER [CONTAINER...]

docker unpause [OPTIONS] CONTAINER [CONTAINER...]
```

**实例**

暂停数据库容器db01提供服务。

```
docker pause db01

```

恢复数据库容器db01提供服务。

```
docker unpause db01
```

## 停止

docker stop :停止一个运行中的容器：
```
docker stop [OPTIONS] CONTAINER [CONTAINER...]
```

## 杀掉容器

docker kill :杀掉一个运行中的容器。

```
docker kill [OPTIONS] CONTAINER [CONTAINER...]

```

OPTIONS说明：

```
-s :向容器发送一个信号

```

**实例**

杀掉运行中的容器mynginx

```
docker kill -s KILL mynginx
```

## 进入容器

使用docker exec ：
```
docker exec [OPTIONS] CONTAINER COMMAND [ARG...]
```

OPTIONS说明：
```
-d :分离模式: 在后台运行

-i :即使没有附加也保持STDIN 打开

-t :分配一个伪终端
```
例如进入ubuntu容器交互式模式：
```
docker exec -it ubuntu /bin/sh
```

或者使用docker attach：

```
docker attach --sig-proxy=false CONTAINER
```

`attach`是可以带上`--sig-proxy=false`来确保`CTRL-D`或`CTRL-C`不会关闭容器。

## 导出容器

**导出容器快照**
```
docker export [OPTIONS] CONTAINER
```
例如：
```
docker export 7691a814370e > ubuntu.tar
```

## 删除
```
docker rm [OPTIONS] CONTAINER [CONTAINER...]
```

OPTIONS说明：
```
-f :通过SIGKILL信号强制删除一个运行中的容器

-l :移除容器间的网络连接，而非容器本身

-v :-v 删除与容器关联的卷
```

删除所有容器：
```
docker rm $(docker ps -a -q)
```
但这并不会删除运行中的容器

## 列出容器

```
docker ps [OPTIONS]

```

OPTIONS说明：
```
-a :显示所有的容器，包括未运行的。

-f, --filter :根据条件过滤显示的内容。

--format :指定返回值的模板文件。

-l :显示最近创建的容器。

-n :列出最近创建的n个容器。

--no-trunc :不截断输出。

-q :静默模式，只显示容器编号。

-s :显示总的文件大小。
```
例如列出最近创建的5个容器信息：
```
docker ps -n 5
```
列出所有创建的容器ID：
```
docker ps -a -q
```

下面是docker官方的filter参数：

|        Filter         | Description                              |
| :-------------------: | :--------------------------------------- |
|         `id`          | Container’s ID                           |
|        `name`         | Container’s name                         |
|        `label`        | An arbitrary string representing either a key or a key-value pair. Expressed as `<key>` or `<key>=<value>` |
|       `exited`        | An integer representing the container’s exit code. Only useful with `--all`. |
|       `status`        | One of `created`, `restarting`, `running`, `removing`, `paused`, `exited`, or `dead` |
|      `ancestor`       | Filters containers which share a given image as an ancestor. Expressed as `<image-name>[:<tag>]`, `<image id>`, or `<image@digest>` |
|  `before` or `since`  | Filters containers created before or after a given container ID or name |
|       `volume`        | Filters running containers which have mounted a given volume or bind mount. |
|       `network`       | Filters running containers connected to a given network. |
| `publish` or `expose` | Filters containers which publish or expose a given port. Expressed as `<port>[/<proto>]` or `<startport-endport>/[<proto>]` |
|       `health`        | Filters containers based on their healthcheck status. One of `starting`, `healthy`, `unhealthy` or `none`. |
|      `isolation`      | Windows daemon only. One of `default`, `process`, or `hyperv`. |
|       `is-task`       | Filters containers that are a “task” for a service. Boolean option (`true` or `false`) |

ex 列出所有状态为退出的容器：

```
docker ps -q --filter status=exited
```

## 查看日志

```
docker logs [OPTIONS] CONTAINER
```

OPTIONS说明：

```
-f : 跟踪日志输出

--since :显示某个开始时间的所有日志

-t : 显示时间戳

--tail :仅列出最新N条容器日志

```

## 数据拷贝

docker cp :用于容器与主机之间的数据拷贝。

```
docker cp [OPTIONS] CONTAINER:SRC_PATH DEST_PATH|-

docker cp [OPTIONS] SRC_PATH|- CONTAINER:DEST_PATH

```

OPTIONS说明：

```
-L :保持源目标中的链接

```

**实例**

将主机/www/runoob目录拷贝到容器96f7f14e99ab的/www目录下。

```
docker cp /www/runoob 96f7f14e99ab:/www/

```

将主机/www/runoob目录拷贝到容器96f7f14e99ab中，目录重命名为www。

```
docker cp /www/runoob 96f7f14e99ab:/www

```

将容器96f7f14e99ab的/www目录拷贝到主机的/tmp目录中。

```
docker cp  96f7f14e99ab:/www /tmp/
```

# Volume的相关操作

Usage:	docker volume COMMAND

| Command                                  | Description                              |
| ---------------------------------------- | ---------------------------------------- |
| [docker volume create](https://docs.docker.com/engine/reference/commandline/volume_create/) | Create a volume                          |
| [docker volume inspect](https://docs.docker.com/engine/reference/commandline/volume_inspect/) | Display detailed information on one or more volumes |
| [docker volume ls](https://docs.docker.com/engine/reference/commandline/volume_ls/) | List volumes                             |
| [docker volume prune](https://docs.docker.com/engine/reference/commandline/volume_prune/) | Remove all unused volumes                |
| [docker volume rm](https://docs.docker.com/engine/reference/commandline/volume_rm/) | Remove one or more volumes               |

ex 删除所有悬浮的volume：

```
docker volume rm $(docker volume ls -q -f dangling=true)
```

## 选择 -v 还是 -–mount 参数

Docker 新用户应该选择 `--mount` 参数，经验丰富的 Docker 使用者对 `-v` 或者 `--volume` 已经很熟悉了，但是推荐使用 `--mount` 参数。

使用 `--mount` 标记可以指定挂载一个本地主机的目录到容器中去。

```
$ docker run -d -P \
--name web \
--mount type=bind,source=/src/webapp,target=/opt/webapp \
training/webapp \
python app.py
```

上面的命令加载主机的 `/src/webapp` 目录到容器的 `/opt/webapp`目录。这个功能在进行测试的时候十分方便，比如用户可以放置一些程序到本地目录中，来查看容器是否正常工作。本地目录的路径必须是**绝对路径**，以前使用 `-v` 参数时**如果本地目录不存在** Docker 会**自动为你创建**一个文件夹，现在使用 `--mount` 参数时如果本地目录不存在，Docker 会**报错**。

Docker 挂载主机目录的默认权限是 `读写`，用户也可以通过增加 `readonly` 指定为 `只读`。

```
docker run -d -P \
--name web \
--mount type=bind,source=/src/webapp,target=/opt/webapp,readonly \
training/webapp \
python app.py
```

# Network的相关操作

基本命令：

```
docker network create
docker network connect
docker network ls
docker network rm
docker network disconnect
docker network inspect
```

下面先创建一个新的 Docker 网络。

```
docker network create -d bridge my-net
```

`-d` 参数指定 Docker 网络类型，有 `bridge` `overlay`。其中 `overlay` 网络类型用于 Swarm mode

容器链接网络：

```
docker run -it --rm --name busybox1 --network my-net busybox sh
```

创建一个Swarm mode网络：

```
docker network create \
--driver overlay \
--opt encrypted \
--attachable \
--subnet 10.0.9.0/24 \
--gateway 10.0.9.99 \
my-network
```

# Dockerfile 详解

![](https://cdn.yangbingdong.com/img/note-of-dockerfile/dockerfile.jpg)

> 制作一个镜像可以使用`docker commit`和定制Dockerfile，但推荐的是写Dockerfile。
>
> 因为`docker commit`是一个**暗箱操作**，除了制作镜像的人知道执行过什么命令、怎么生成的镜像，别人根本无从得知，而且会加入一些没用的操作导致镜像**臃肿**。

## Build Images
首先在当前空目录创建一个Dockerfile：
```
FROM ubuntu:latest

ENV BLOG_PATH /root/blog
ENV NODE_VERSION 6

MAINTAINER yangbingdong <yangbingdong1994@gmail.com>

RUN \
    apt-get update -y && \
    apt-get install -y git curl libpng-dev && \
    curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    npm install -g hexo-cli

WORKDIR $BLOG_PATH

VOLUME ["$BLOG_PATH", "/root/.ssh"]

EXPOSE 4000

CMD ['/bin/bash']
```

然后在当前目录打开终端：
```
docker build -t <repo-name>/<image-name>:<tag> .
```

其中`<repo-name>`表示仓库名，与远程仓库（如docker hub）名字要一致，`<tag>`表示标签，不给默认`latest`，都是**可选项**，例如可以写成这样：
```
docker build -t <image-name> .
```
![](https://cdn.yangbingdong.com/img/note-of-dockerfile/docker-build.png)

看到`Successfully built`就表示构建成功了

注意`docker build` 命令最后有一个 `.`表示构建的**上下文**，镜像构建需要把上下文的东西上传到Docker引擎去构建。

## Dockerfile 指令

### From 指定基础镜像

所谓定制镜像，那一定是以一个镜像为基础，在其上进行定制。而 `FROM` 就是指定**基础镜像**，因此一个 `Dockerfile` 中 `FROM` 是必备的指令，并且必须是第一条指令。

在 [Docker Hub](https://hub.docker.com/explore/)上有非常多的高质量的官方镜像， 有可以直接拿来使用的服务类的镜像，如 [`nginx`](https://hub.docker.com/_/nginx/)、[`redis`](https://hub.docker.com/_/redis/)、[`mongo`](https://hub.docker.com/_/mongo/)、[`mysql`](https://hub.docker.com/_/mysql/)、[`httpd`](https://hub.docker.com/_/httpd/)、[`php`](https://hub.docker.com/_/php/)、[`tomcat`](https://hub.docker.com/_/tomcat/) 等； 也有一些方便开发、构建、运行各种语言应用的镜像，如 [`node`](https://hub.docker.com/_/node/)、[`openjdk`](https://hub.docker.com/_/openjdk/)、[`python`](https://hub.docker.com/_/python/)、[`ruby`](https://hub.docker.com/_/ruby/)、[`golang`](https://hub.docker.com/_/golang/) 等。 可以在其中寻找一个最符合我们最终目标的镜像为基础镜像进行定制。 如果没有找到对应服务的镜像，官方镜像中还提供了一些更为基础的操作系统镜像，如 [`ubuntu`](https://hub.docker.com/_/ubuntu/)、[`debian`](https://hub.docker.com/_/debian/)、[`centos`](https://hub.docker.com/_/centos/)、[`fedora`](https://hub.docker.com/_/fedora/)、[`alpine`](https://hub.docker.com/_/alpine/) 等，这些操作系统的软件库为我们提供了更广阔的扩展空间。

除了选择现有镜像为基础镜像外，Docker 还存在一个特殊的镜像，名为 `scratch`。这个镜像是虚拟的概念，并不实际存在，它表示一个空白的镜像。

### RUN 执行命令

`RUN` 指令是用来执行命令行命令的。由于命令行的强大能力，`RUN` 指令在定制镜像时是最常用的指令之一。其格式有两种：

- *shell* 格式：`RUN <命令>`，就像直接在命令行中输入的命令一样。刚才写的 Dockrfile 中的 `RUN` 指令就是这种格式。
```
RUN echo '<h1>Hello, Docker!</h1>' > /usr/share/nginx/html/index.html
```

- *exec* 格式：`RUN ["可执行文件", "参数1", "参数2"]`，这更像是函数调用中的格式。

**注意**：
* RUN命令尽量精简，也就是像上面一样一个RUN（使用`$$ \`），如果分开写很多个RUN会导致镜像铺了很多层从而臃肿。
* RUN最后记住清理掉没用的垃圾，很多人初学 Docker 制作出了很臃肿的镜像的原因之一，就是忘记了每一层构建的最后一定要清理掉无关文件。

### COPY 复制文件

格式：

- `COPY <源路径>... <目标路径>`
- `COPY ["<源路径1>",... "<目标路径>"]`

和 `RUN` 指令一样，也有两种格式，一种类似于命令行，一种类似于函数调用。

`COPY` 指令将从构建上下文目录中 `<源路径>` 的文件/目录复制到新的一层的镜像内的 `<目标路径>` 位置。比如：
```
COPY package.json /usr/src/app/
```

### ADD 更高级的复制文件

`ADD` 指令和 `COPY` 的格式和性质基本一致。但是在 `COPY` 基础上增加了一些功能。

比如 `<源路径>` 可以是一个 `URL`，这种情况下，Docker 引擎会试图去下载这个链接的文件放到 `<目标路径>` 去。下载后的文件权限自动设置为 `600`，如果这并不是想要的权限，那么还需要增加额外的一层 `RUN`进行权限调整，另外，如果下载的是个压缩包，需要解压缩，也一样还需要额外的一层 `RUN` 指令进行解压缩。所以不如直接使用 `RUN` 指令，然后使用 `wget` 或者 `curl` 工具下载，处理权限、解压缩、然后清理无用文件更合理。因此，这个功能其实并不实用，而且不推荐使用。

如果 `<源路径>` 为一个 `tar` 压缩文件的话，压缩格式为 `gzip`, `bzip2` 以及 `xz` 的情况下，`ADD` 指令将会自动解压缩这个压缩文件到 `<目标路径>` 去。

在某些情况下，这个自动解压缩的功能非常有用，比如官方镜像 `ubuntu` 中：

```
FROM scratch
ADD ubuntu-xenial-core-cloudimg-amd64-root.tar.gz /
...
```

但在某些情况下，如果我们真的是希望复制个压缩文件进去，而不解压缩，这时就不可以使用 `ADD` 命令了。

在 Docker 官方的最佳实践文档中要求，尽可能的使用 `COPY`，因为 `COPY` 的语义很明确，就是复制文件而已，而 `ADD` 则包含了更复杂的功能，其行为也不一定很清晰。最适合使用 `ADD` 的场合，就是所提及的需要自动解压缩的场合。

另外需要注意的是，`ADD` 指令会令镜像构建缓存失效，从而可能会令镜像构建变得比较缓慢。

因此在 `COPY` 和 `ADD` 指令中选择的时候，可以遵循这样的原则，所有的文件复制均使用 `COPY` 指令，仅在需要自动解压缩的场合使用 `ADD`。

### CMD 容器启动命令

`CMD` 指令就是用于指定默认的容器主进程的启动命令的。

`CMD` 指令的格式和 `RUN` 相似，也是两种格式：

- `shell` 格式：`CMD <命令>`
- `exec` 格式：`CMD ["可执行文件", "参数1", "参数2"...]`
- 参数列表格式：`CMD ["参数1", "参数2"...]`。在指定了 `ENTRYPOINT` 指令后，用 `CMD` 指定具体的参数。

在运行时可以指定新的命令来替代镜像设置中的这个默认命令，比如，`ubuntu` 镜像默认的 `CMD` 是 `/bin/bash`，如果我们直接 `docker run -it ubuntu` 的话，会直接进入 `bash`。我们也可以在运行时指定运行别的命令，如 `docker run -it ubuntu cat /etc/os-release`。这就是用 `cat /etc/os-release` 命令替换了默认的 `/bin/bash` 命令了，输出了系统版本信息。

在指令格式上，一般推荐使用 `exec` 格式，这类格式在解析时会被解析为 JSON 数组，因此一定要使用双引号 `"`，而不要使用单引号。

如果使用 `shell` 格式的话，实际的命令会被包装为 `sh -c` 的参数的形式进行执行。比如：
```
CMD echo $HOME
```

在实际执行中，会将其变更为：
```
CMD [ "sh", "-c", "echo $HOME" ]
```

所以如果使用`shell`格式会导致容器**莫名退出**，因为实际上执行的事`sh`命令，而`sh`命令执行完时候容器也就没有存在的意义。

### ENTRYPOINT 入口点

`ENTRYPOINT` 的格式和 `RUN` 指令格式一样，分为 `exec` 格式和 `shell` 格式。

`ENTRYPOINT` 的目的和 `CMD` 一样，都是在指定容器启动程序及参数。`ENTRYPOINT` 在运行时也可以替代，不过比 `CMD` 要略显繁琐，需要通过 `docker run` 的参数 `--entrypoint` 来指定。

当指定了 `ENTRYPOINT` 后，`CMD` 的含义就发生了改变，不再是直接的运行其命令，而是将 `CMD` 的内容作为参数传给 `ENTRYPOINT` 指令，换句话说实际执行时，将变为：

```
<ENTRYPOINT> "<CMD>"
```

这个指令非常有用，例如可以把命令后面的参数传进来或启动容器前准备一些环境然后执行启动命令（通过脚本`exec "$@"`）。

### ENV 设置环境变量

格式有两种：

- `ENV <key> <value>`
- `ENV <key1>=<value1> <key2>=<value2>...`

这个指令很简单，就是设置环境变量而已，无论是后面的其它指令，如 `RUN`，还是运行时的应用，都可以直接使用这里定义的环境变量。

ex：

```
ENV NODE_VERSION 6
...
RUN curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - && \
...
```

### ARG 构建参数

格式：`ARG <参数名>[=<默认值>]`

构建参数和 `ENV` 的效果一样，都是设置环境变量。所不同的是，`ARG` 所设置的构建环境的环境变量，在将来容器运行时是不会存在这些环境变量的。但是不要因此就使用 `ARG` 保存密码之类的信息，因为 `docker history` 还是可以看到所有值的。

`Dockerfile` 中的 `ARG` 指令是定义参数名称，以及定义其默认值。该默认值可以在构建命令 `docker build` 中用 `--build-arg <参数名>=<值>` 来覆盖。

在 1.13 之前的版本，要求 `--build-arg` 中的参数名，必须在 `Dockerfile` 中用 `ARG` 定义过了，换句话说，就是 `--build-arg` 指定的参数，必须在 `Dockerfile` 中使用了。如果对应参数没有被使用，则会报错退出构建。从 1.13 开始，这种严格的限制被放开，不再报错退出，而是显示警告信息，并继续构建。这对于使用 CI 系统，用同样的构建流程构建不同的 `Dockerfile` 的时候比较有帮助，避免构建命令必须根据每个 Dockerfile 的内容修改。

### VOLUME 定义匿名卷
格式为：
- `VOLUME ["<路径1>", "<路径2>"...]`
- `VOLUME <路径>`

之前我们说过，容器运行时应该尽量保持容器存储层不发生写操作，对于数据库类需要保存动态数据的应用，其数据库文件应该保存于卷(volume)中，后面的章节我们会进一步介绍 Docker 卷的概念。为了防止运行时用户忘记将动态文件所保存目录挂载为卷，在 `Dockerfile` 中，我们可以事先指定某些目录挂载为匿名卷，这样在运行时如果用户不指定挂载，其应用也可以正常运行，不会向容器存储层写入大量数据。
```
VOLUME /data

```

这里的 `/data` 目录就会在运行时自动挂载为匿名卷，任何向 `/data` 中写入的信息都不会记录进容器存储层，从而保证了容器存储层的无状态化。当然，运行时可以覆盖这个挂载设置。比如：
```
docker run -d -v mydata:/data xxxx

```

在这行命令中，就使用了 `mydata` 这个命名卷挂载到了 `/data` 这个位置，替代了 `Dockerfile` 中定义的匿名卷的挂载配置。

### EXPOSE 声明端口

格式为 `EXPOSE <端口1> [<端口2>...]`。
`EXPOSE` 指令是声明运行时容器提供服务端口，这只是一个声明，在运行时并不会因为这个声明应用就会开启这个端口的服务。在 Dockerfile 中写入这样的声明有两个好处，一个是帮助镜像使用者理解这个镜像服务的守护端口，以方便配置映射；另一个用处则是在运行时使用随机端口映射时，也就是 `docker run -P`时，会自动随机映射 `EXPOSE` 的端口。

此外，在早期 Docker 版本中还有一个特殊的用处。以前所有容器都运行于默认桥接网络中，因此所有容器互相之间都可以直接访问，这样存在一定的安全性问题。于是有了一个 Docker 引擎参数 `--icc=false`，当指定该参数后，容器间将默认无法互访，除非互相间使用了 `--links` 参数的容器才可以互通，并且只有镜像中 `EXPOSE` 所声明的端口才可以被访问。这个 `--icc=false` 的用法，在引入了 `docker network`后已经基本不用了，通过自定义网络可以很轻松的实现容器间的互联与隔离。

要将 `EXPOSE` 和在运行时使用 `-p <宿主端口>:<容器端口>` 区分开来。`-p`，是映射宿主端口和容器端口，换句话说，就是将容器的对应端口服务公开给外界访问，而 `EXPOSE` 仅仅是声明容器打算使用什么端口而已，并不会自动在宿主进行端口映射。

### WORKDIR 指定工作目录
格式为 `WORKDIR <工作目录路径>`。
使用 `WORKDIR` 指令可以来指定工作目录（或者称为当前目录），以后各层的当前目录就被改为指定的目录，如该目录不存在，`WORKDIR` 会帮你建立目录。

之前提到一些初学者常犯的错误是把 `Dockerfile` 等同于 Shell 脚本来书写，这种错误的理解还可能会导致出现下面这样的错误：
```
RUN cd /app
RUN echo "hello" > world.txt

```

如果将这个 Dockerfile 进行构建镜像运行后，会发现找不到 `/app/world.txt` 文件，或者其内容不是 `hello`。原因其实很简单，在 Shell 中，连续两行是同一个进程执行环境，因此前一个命令修改的内存状态，会直接影响后一个命令；而在 Dockerfile 中，这两行 `RUN` 命令的执行环境根本不同，是两个完全不同的容器。这就是对 Dokerfile 构建分层存储的概念不了解所导致的错误。

之前说过每一个 `RUN` 都是启动一个容器、执行命令、然后提交存储层文件变更。第一层 `RUN cd /app` 的执行仅仅是当前进程的工作目录变更，一个内存上的变化而已，其结果不会造成任何文件变更。而到第二层的时候，启动的是一个全新的容器，跟第一层的容器更完全没关系，自然不可能继承前一层构建过程中的内存变化。

因此如果需要改变以后各层的工作目录的位置，那么应该使用 `WORKDIR` 指令。

### USER 指定当前用户

格式：`USER <用户名>`

`USER` 指令和 `WORKDIR` 相似，都是改变环境状态并影响以后的层。`WORKDIR` 是改变工作目录，`USER`则是改变之后层的执行 `RUN`, `CMD` 以及 `ENTRYPOINT` 这类命令的身份。

当然，和 `WORKDIR` 一样，`USER` 只是帮助你切换到指定用户而已，这个用户必须是事先建立好的，否则无法切换。

```
RUN groupadd -r redis && useradd -r -g redis redis
USER redis
RUN [ "redis-server" ]
```
### HEALTHCHECK 健康检查

格式：

- `HEALTHCHECK [选项] CMD <命令>`：设置检查容器健康状况的命令
- `HEALTHCHECK NONE`：如果基础镜像有健康检查指令，使用这行可以屏蔽掉其健康检查指令

`HEALTHCHECK` 支持下列选项：

- `--interval=<间隔>`：两次健康检查的间隔，默认为 30 秒；
- `--timeout=<间隔>`：健康检查命令运行超时时间，如果超过这个时间，本次健康检查就被视为失败，默认 30 秒；
- `--retries=<次数>`：当连续失败指定次数后，则将容器状态视为 `unhealthy`，默认 3 次。
- `--start-period=<间隔>`: 应用的启动的初始化时间，在启动过程中的健康检查失效不会计入，默认 0 秒； (从17.05)引入

在 `HEALTHCHECK [选项] CMD` 后面的命令，格式和 `ENTRYPOINT` 一样，分为 `shell` 格式，和 `exec` 格式。命令的返回值决定了该次健康检查的成功与否：

- `0`：成功；
- `1`：失败；
- `2`：保留值，不要使用

容器启动之后，初始状态会为 `starting` (启动中)。Docker Engine会等待 `interval` 时间，开始执行健康检查命令，并周期性执行。如果单次检查返回值非0或者运行需要比指定 `timeout` 时间还长，则本次检查被认为失败。如果健康检查连续失败超过了 `retries` 重试次数，状态就会变为 `unhealthy` (不健康)。

注：

- 一旦有一次健康检查成功，Docker会将容器置回 `healthy` (健康)状态
- 当容器的健康状态发生变化时，Docker Engine会发出一个 `health_status` 事件。

假设我们有个镜像是个最简单的 Web 服务，我们希望增加健康检查来判断其 Web 服务是否在正常工作，我们可以用 `curl`来帮助判断，其 `Dockerfile` 的 `HEALTHCHECK` 可以这么写：

```
FROM elasticsearch:5.5

HEALTHCHECK --interval=5s --timeout=2s --retries=12 \
  CMD curl --silent --fail localhost:9200/_cluster/health || exit 1
```

## ENTRYPOINT与CMD使用区别

|                     | No ENTRYPOINT       | ENTRYPOINT entry arg0 | ENTRYPOINT [“entry”, “arg0”]   |
| ------------------- | ------------------- | --------------------- | ------------------------------ |
| No CMD              | error, not allowed  | /bin/sh -c entry arg0 | entry arg0                     |
| CMD [“cmd”, “arg1”] | cmd arg1            | /bin/sh -c entry arg0 | entry arg0 cmd arg1            |
| CMD cmd arg1        | /bin/sh -c cmd arg1 | /bin/sh -c entry arg0 | entry arg0 /bin/sh -c cmd arg1 |

上表源于官方文档中的[Understand how CMD and ENTRYPOINT interact](https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact)，有所简化。

1. ENTRYPOINT和CMD至少要有一个。
2. 使用`ENTRYPOINT entry arg0`形式，与CMD将没有任何配合。因此，除非特定需求，否则不推荐这种使用方式。
3. 右下角`entry arg0 /bin/sh -c cmd arg1`这种形式，几乎没有什么使用场景，反而是常见错误，应该尽量避免。

本质上，其实可以理解为ENTRYPOINT是真正的Docker可执行入口，而CMD则是可选参数。 之所以在很多情况下直接写CMD也能生效，是因为ENTRYPOINT就相当于是指定Shell，而CMD则是指定Shell中执行的命令。 注意，只是『相当于』。

### 注意PID

原则上，一个Docker容器里应该只有一个进程，其PID为1。 Docker外部的操作，比如`docker stop`，就是向这个进程**发送信号**。 **如果那个唯一的前台进程PID不为1，那么就会收不到信号，只能在超时（默认约10秒）后被kill**。

在Dockerfile中使用`ENTRYPOINT entry arg0`这种形式时，`entry`的位置总是应该使用`exec`，后面再接其它内容。 比如，`ENTRYPOINT exec top`，这可以确保`top`命令是PID为1的进程。 否则，`ENTRYPOINT top`的形式，PID为1的进程就是`/bin/sh -c top`，而`top`则被挤到了另外一个进程。

## 踩坑

- Dockerfile里也需要注意**权限问题**（nodejs7版本以上不能正常安装hexo，需要创建用户并制定权限去安装）
- 在docker容器里如果是root用户对挂载的文件进行了操作，那么实际上挂载文件的**权限也变成了root的**
- 使用attach进入容器，退出的时候容器也跟着退出了。。。囧
- 每一个RUN是一个**新的shell**
- `su -`之前在启动脚本加了`-`，导致**环境变量以及工作目录都变了**

## Hexo Dockerfile

```
FROM ubuntu:16.04

MAINTAINER yangbingdong <yangbingdong1994@gmail.com>

USER root

ENV NODE_VERSION 8.9.4
ENV NODE_DIR /opt/nodejs
ENV HOXO_DIR /root/hexo

RUN apt-get update && \
	apt-get install -y git curl && \
	mkdir ${NODE_DIR} && \
	curl -L https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz | tar xvzf - -C ${NODE_DIR} --strip-components=1 
     
ENV PATH $PATH:${NODE_DIR}/bin

RUN npm install -g hexo-cli

ENV PATH $PATH:${NODE_DIR}/bin

RUN cd /root && \
	hexo init hexo && \
	cd hexo && \
	git clone https://github.com/iissnan/hexo-theme-next themes/next && \
	npm install && \
	apt-get clean && \
	apt-get autoremove -y && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME ["/root/hexo/source/_posts"] 

WORKDIR /root/hexo

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
```

`docker-entrypoint.sh`:

```
#!/bin/sh
set -e
hexo clean && hexo server
exec "$@"
```

# 修改Docker默认镜像，容器存放位置

## 方法一、软链接

默认情况下Docker的存放位置为：`/var/lib/docker`
可以通过下面命令查看具体位置：

```
sudo docker info | grep "Docker Root Dir"
```

解决这个问题，最直接的方法当然是挂载分区到这个目录，但是我的数据盘还有其他东西，这肯定不好管理，所以采用修改镜像和容器的存放路径的方式达到目的。

这个方法里将通过软连接来实现。

首先停掉Docker服务：

```
systemctl restart docker
或者
service docker stop
```

然后移动整个`/var/lib/docker`目录到目的路径：

```
mv /var/lib/docker /root/data/docker
ln -s /root/data/docker /var/lib/docker
```

这时候启动Docker时发现存储目录依旧是`/var/lib/docker`，但是实际上是存储在数据盘的，你可以在数据盘上看到容量变化。

## 方法二、修改镜像和容器的存放路径

指定镜像和容器存放路径的参数是`--graph=/var/lib/docker`，我们只需要修改配置文件指定启动参数即可。

Docker 的配置文件可以设置大部分的后台进程参数，在各个操作系统中的存放位置不一致，在 Ubuntu 中的位置是：`/etc/default/docker`，在 CentOS 中的位置是：`/etc/sysconfig/docker`。

如果是 CentOS 则添加下面这行：

```
OPTIONS=--graph="/root/data/docker" --selinux-enabled -H fd://
```

如果是 Ubuntu 则添加下面这行（因为 Ubuntu 默认没开启 selinux）：

```
OPTIONS=--graph="/root/data/docker" -H fd://
# 或者
DOCKER_OPTS="-g /root/data/docker"
```

最后重新启动，Docker 的路径就改成 `/root/data/docker` 了。

# 定期清理容器日志
> 参考：[*https://zhuanlan.zhihu.com/p/29051214*](https://zhuanlan.zhihu.com/p/29051214)

## 通过logrotate服务实现日志定期清理和回卷

logrotate是个十分有用的工具，它可以自动对日志进行截断（或轮循）、压缩以及删除旧的日志文件。例如，你可以设置logrotate，让/var/log/foo日志文件每30天轮循，并删除超过6个月的日志。配置完后，logrotate的运作完全自动化，不必进行任何进一步的人为干预。

**[https://github.com/blacklabelops/logrotate](https://github.com/blacklabelops/logrotate)**

```
docker run -d \
  --restart=always \
  --name=logrotate \
  -v /var/lib/docker/containers:/var/lib/docker/containers \
  -v /var/log/docker:/var/log/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
  -e "LOGROTATE_INTERVAL=daily" \
  blacklabelops/logrotate
```

## 通过修改dockerd参数进行回卷和清理

在`/etc/docker/daemon.json`中添加`log-driver`以及`log-opts`参数：

```
{
  "registry-mirrors": ["https://vioqnt8w.mirror.aliyuncs.com"],
  "insecure-registries": ["192.168.6.113:8888"],
  "log-driver":"json-file",
  "log-opts":{
    "max-size" :"10m","max-file":"3"
    }
}
```

参数说明： 设置单个容器日志超过10M则进行回卷，回卷的副本数超过3个就进行清理。

重启docker

```
sudo systemctl daemon-reload && sudo systemctl restart docker
```

# 数据卷备份与恢复

## 数据卷备份

```
docker run --rm \
  --volumes-from <ContainerName> \
  -v $(pwd):/backup \
  busybox \
  tar cvf /backup/backup.tar /data
```

- `--rm`: 执行完命令之后移除容器
- `--volumes-from <Container>`: 连接要备份数据的容器
- `-v $(pwd):/backup`: 挂载当前路径到容器 busybox 容器，数据将会备份到此路径
- `busybox`: 非常小的镜像
- `tar cvf /backup/backup.tar /data`: 将 /data 路径下的文件打包到 backup.tar

## 数据卷恢复

**1、新建容器**

```
docker run -v /data --name <ContainerName> <Image>
```

**2、恢复数据**

```
docker run --rm \
  --volumes-from <ContainerName> \
  -v $(pwd):/backup \
  busybox \
  tar xvf /backup/backup.tar
```

> 注意：其中的路径 /data 仅为示例，具体需要备份的文件路径请结合自身需求。

# 使用Github自动构建Docker

![](https://cdn.yangbingdong.com/ima/docker-automated-built/github-docker.jpg)

> 一开始玩Docker总是用别人的镜像确实很爽~~歪歪~~...
> But，如果要定制个性化的Image那就必须要自己写Dockerfile了，但是每一次修改完Dockerfile，都要经过几个步骤：
> Built -> Push -> Delete invalid images
> 对于程序猿而言做重复的事情是很恐怖的，所以博主选择Github自动构建Docker Image~

## 创建用于自动构建的仓库
在Github上面创建一个项目并把Dockerfile以及上下文需要用到的文件放到里面。

## 链接仓库服务
首先需要绑定一个仓库服务（Github）：

1、登录`Docker Hub`；
2、选择 `Profile` > `Settings` > `Linked Accounts & Services`；
3、选择需要连接的仓库服务（目前只支持`Github`和`BitBucket`）；
4、这时候需要授权，点击授权就可以了。
![](https://cdn.yangbingdong.com/ima/docker-automated-built/add-repo-service.png)

## 创建一个自动构建
自动构建需要创建对应的仓库类型
自动构建仓库也可以使用`docker push`把已有的镜像上传上去
1、选择`Create` > `Create Automated Build`；
2、选择`Github`；
3、接下来会列出`User/Organizations`的所有项目，从中选择你需要的构建的项目（包含Dockerfile）；
4、可以选择`Click here to customize`自定义路径；
5、最后点击创建就可以了。
![](https://cdn.yangbingdong.com/ima/docker-automated-built/create-automated.png)
![](https://cdn.yangbingdong.com/ima/docker-automated-built/creating.png)

## 集成到Github
用过`Github`自动构建当然需要`Github`的支持啦，这里只需要在Github里面点两下就配置完成，很方便：
![](https://cdn.yangbingdong.com/ima/docker-automated-built/add-integrations.png)
在`Add Service`里面找到`Docker`并添加

![](https://cdn.yangbingdong.com/ima/docker-automated-built/github-docker-server.png)

## 构建设置
### 勾选自动构建
系统会默认帮我们勾上自动构建选项：
![](https://cdn.yangbingdong.com/ima/docker-automated-built/aotumated-setting.png)
这时候，当我们的Dockerfile有变动会自动触发构建：
![](https://cdn.yangbingdong.com/ima/docker-automated-built/building.png)
还在构建过程中我们可以点击Cancel取消构建过程。

### 添加新的构建
Docker hub默认选择master分支作为latest版本，我们可以根据自己的标签或分支构建不同的版本：
![](https://cdn.yangbingdong.com/ima/docker-automated-built/add-build.png)

（点击箭头位置会出现例子）
这样，当我们创建一个标签如1.0.2并push上去的时候会自动触发构建～

`Git`标签相关请看：***[Git标签管理](/2017/note-of-learning-git/#标签管理)***

### 远程触发构建
当然我们也可以远程触发构建，同样在Build Setting页面:
![](https://cdn.yangbingdong.com/ima/docker-automated-built/remote-trigger.png)
然后例子已经说的很清楚了

参考：***[https://docs.docker.com/docker-hub/builds/](https://docs.docker.com/docker-hub/builds/)***

# 使用代理构建镜像

有时候，我们构建镜像需要在镜像内安装一些软件，因为构建时采用的是`bridge`模式，对于一些资源比较稀缺或需要**科学上网**才能安装的软件慢得简直无法忍受。对此，我们可以在构建时设置**构建参数**（`--build-arg`）从而达到代理安装的目的。或者也可以用官方的Docker Hub自动构建，或者将Dockerfile上传到VPS进行构建=.=...但感觉没必要。

例如像下面`Dockerfile`：

```
FROM XXXXXX
MAINTAINER ybd <yangbingdong1994@gmail.com> 
ARG HTTP_PROXY
ENV http_proxy=${HTTP_PROXY} https_proxy=${HTTP_PROXY}
RUN apk update && \
    apk add --no-cache && \
    apk add curl bash tree tzdata .....
ENV http_proxy=
ENV https_proxy=
```

然后构建：

```
docker build --build-arg HTTP_PROXY=192.168.6.113:8118 -t yangbingdong/oraclejdk8 .
```

`192.168.6.113:8118`是从Sock5转换过来的http代理

**注意：镜像内软件安装完成时候需要将代理置空，所以上面示例最后两行后面的值是空的，否则接下来容器内发生的网络访问都会走代理...**

# 开启远程API

**注意：这是一个危险动作，仅测试使用，生产慎用！**

某些应用可能需要使用Docker的远程API调用，例如Portainer。

## 方式一，修改配置文件

打开`/lib/systemd/system/docker.service`，将`ExecStart=/usr/bin/docker daemon -H fd://`修改为`ExecStart=/usr/bin/docker daemon -H fd:// -H tcp://0.0.0.0:2375`。

其中`2375`是就是远程调用端口。

然后重启Dcoker：

```
sudo systemctl daemon-reload && sudo service docker restart
```

## 方式二，添加代理

这种方式比较优雅点，不需要重启Docker或更改配置文件：

```
docker run -ti -d -p 2375:2375 \
--restart=always \
--hostname=$HOSTNAME \
--name shipyard-proxy \
-v /var/run/docker.sock:/var/run/docker.sock \
-e PORT=2375 \
shipyard/docker-proxy
```

# Self Usage Docker Or Compose

以下是个人使用的一些容器运行命令或者`docker-compose.yml`，不定时更新

## *[Mysql](https://hub.docker.com/_/mysql/)*

**运行实例**：

```
MYSQL_DATA=${HOME}/data/docker/mysql/data && \
MYSQL_PORT=3306 && \
MYSQL_VERSION=latest && \
docker run --name=mysql \
--restart=always \
-p ${MYSQL_PORT}:3306  \
-v ${MYSQL_DATA}:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=root \
-d \
mysql:${MYSQL_VERSION:-latest} \
--character-set-server=utf8mb4 \
--collation-server=utf8mb4_unicode_ci \
--sql-mode=STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION \
--lower-case-table-names=1
```

链接Mysql服务端需要安装终端客户端：

```
sudo apt install mysql-client
```

链接：

```
mysql -h 127.0.0.1 -P 3306 -u root -p
// 然后需要输入密码
```

## *[Redis](https://hub.docker.com/_/redis/)*

**运行实例**：

```
REDIS_DATA=${HOME}/data/docker/redis/data && \
REDIS_CONF=${HOME}/data/docker/redis/redis.conf && \
REDIS_PORT=6379 && \
REDIS_VERSION=latest && \
docker run -p ${REDIS_PORT}:6379 \
--restart=always \
-v ${REDIS_DATA}:/usr/local/etc/redis/redis.conf \
-v ${REDIS_DATA}:/data \
--name redis \
-d \
redis:${REDIS_VERSION:-latest} \
redis-server /usr/local/etc/redis/redis.conf --appendonly yes
```

链接Redis服务端需要安装终端客户端：

```
sudo apt install redis-tools
```

链接：

```
redis-cli
```

## *[Portainer](https://hub.docker.com/r/portainer/portainer/)*

功能：管理容器与swarm集群

单机版：

```
docker run -d -p 9000:9000 \
--name portainer \
--restart=always \
-v /var/run/docker.sock:/var/run/docker.sock \
portainer/portainer:{PORTAINER_VERSION:-latest}
```

集群版：

```
PORTAINER_DATA=${HOME}/data/docker/portainer/data
docker service create \
--name portainer \
--publish 9000:9000 \
--constraint 'node.role == manager' \
--mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
--mount type=bind,src=${PORTAINER_DATA},dst=/data \
portainer/portainer:{PORTAINER_VERSION:-latest} \
-H unix:///var/run/docker.sock
```

## [*Visualizer*](https://hub.docker.com/r/dockersamples/visualizer/)

```
docker service create \
--name=viz \
--publish=8088:8080/tcp \
--constraint=node.role==manager \
--mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
dockersamples/visualizer
```

## *[Nexus3](https://hub.docker.com/r/sonatype/nexus3/)*

**创建Volume** ：

```
docker volume create --name nexus-data
```

**运行实例**：

```
NEXUS_PORT=8090 && \
NEXUS_VERSION=3.6.2 && \
docker run --restart=always \
-d \
-p ${NEXUS_PORT}:8081 \
--name nexus \
-v nexus-data:/nexus-data \
sonatype/nexus3:${NEXUS_VERSION}
```

查看启动日志：

```
docker logs nexus
```

**备份**：

```
BAK_CONTAINER=ubuntu:latest && \
VOLUME=nexus-data && \
BAK_PATH=${PWD} && \
BAK_ARCHIVE_NAME=nexus-data && \
docker run --rm \
-v ${BAK_PATH}:/backup \
-v ${VOLUME}:/backup-data \
${BAK_CONTAINER} \
tar zcvf /backup/${BAK_ARCHIVE_NAME}.tar.gz /backup-data 
```

**还原**：

先要创建还原的Volume：

```
docker volume create --name nexus-data1
```

然后：

```
BAK_CONTAINER=ubuntu:latest && \
RESTORE_VOLUME=nexus-data1 && \
BAK_PATH=${PWD} && \
BAK_ARCHIVE_NAME=nexus-data && \
docker volume create --name ${RESTORE_VOLUME} && \
docker run --rm \
-v ${RESTORE_VOLUME}:/restore \
-v ${BAK_PATH}:/backup \
ubuntu:latest \
tar zxvf /backup/${BAK_ARCHIVE_NAME}.tar.gz -C /restore --strip-components=1
```

## *[Shadowsocks](https://hub.docker.com/r/mritd/shadowsocks/)*

**服务端**：

```
SS_PASSWORD=123456 && \
SS_PORT=22 && \
docker run -dt \
--name ssserver \
--restart=always \
-p ${SS_PORT}:6443 \
mritd/shadowsocks:latest \
-m "ss-server" -s "-s 0.0.0.0 -p 6443 -m aes-256-cfb -k ${PASSWORD} --fast-open"
```

**客户端**：

```
SS_IP=127.0.0.1 && \
SS_PORT=22 && \
SS_PASSWORD=123456 && \
docker run -d \
--name ssclient \
--restart=always \
-p 1080:1080 \
mritd/shadowsocks:latest \
-m "ss-local" -s "-s ${SS_IP} -p ${SS_PORT} -b 0.0.0.0 -l 1080 -m aes-256-cfb -k ${SS_PASSWORD} --fast-open"
```

加速需要开启[***BBR***](https://teddysun.com/489.html)

## *[Ngrok（服务端）](https://hub.docker.com/r/hteen/ngrok/)*

**运行实例**：

```
NGROK_DATA=/root/docker/ngrok/data && \
NGROK_PORT=9000 && \
docker run -idt --name ngrok-server \
-p ${NGROK_PORT}:80 -p 4432:443 -p 4443:4443 \
-v ${NGROK_DATA}:/myfiles \
-e DOMAIN='ngrok.yangbingdong.com' hteen/ngrok /bin/sh /server.sh
```

> 详情：[***Docker搭建Ngrok***](http://yangbingdong.com/2017/self-hosted-build-ngrok-server/#Docker搭建Ngrok)

## [*Zookeeper*](https://hub.docker.com/_/zookeeper/)集群

docker-compose.yml:

```
version: '3.4'
services:
  zoo1:
    image: zookeeper:latest
    hostname: zoo1
    environment:
      ZOO_MY_ID: 1
      ZOO_SERVERS: server.1=0.0.0.0:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888
    ports:
      - "2181:2181"
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      placement:
        constraints:
          - node.hostname == ybd-PC
    networks:
      zoo-net:
        aliases:
          - zookeeper1

  zoo2:
    image: zookeeper:latest
    hostname: zoo2
    environment:
      ZOO_MY_ID: 2
      ZOO_SERVERS: server.1=zoo1:2888:3888 server.2=0.0.0.0:2888:3888 server.3=zoo3:2888:3888
    ports:
      - "2182:2181"
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      placement:
        constraints:
          - node.hostname == qww-PC
    networks:
      zoo-net:
        aliases:
          - zookeeper2

  zoo3:
    image: zookeeper:latest
    hostname: zoo3
    environment:
      ZOO_MY_ID: 3
      ZOO_SERVERS: server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=0.0.0.0:2888:3888
    ports:
      - "2183:2181"
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      placement:
        constraints:
          - node.hostname == qww-PC
    networks:
      zoo-net:
        aliases:
          - zookeeper3

# docker network create -d=overlay --attachable zoo-net
networks:
  zoo-net:
    external:
      name: zoo-net
```

## [*Kafka*](https://hub.docker.com/r/wurstmeister/kafka/tags/)集群

docker-compose.yml

```
version: '3.4'
services:
  kafka1:
    image: wurstmeister/kafka:1.0.0
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ADVERTISED_PORT: 9092
      KAFKA_ZOOKEEPER_CONNECT: zookeeper1:2181,zookeeper2:2181,zookeeper3:2181
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      placement:
        constraints:
          - node.hostname == ybd-PC
    networks:
      zoo-net:
        aliases:
          - kafka1

  kafka2:
    image: wurstmeister/kafka:1.0.0
    ports:
      - "9093:9092"
    environment:
      KAFKA_BROKER_ID: 2
      KAFKA_ADVERTISED_PORT: 9093
      KAFKA_ZOOKEEPER_CONNECT: zookeeper1:2181,zookeeper2:2181,zookeeper3:2181
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      placement:
        constraints:
          - node.hostname == qww-PC
    networks:
      zoo-net:
        aliases:
          - kafka2


  kafka3:
    image: wurstmeister/kafka:1.0.0
    ports:
      - "9094:9092"
    environment:
      KAFKA_BROKER_ID: 3
      KAFKA_ADVERTISED_PORT: 9094
      KAFKA_ZOOKEEPER_CONNECT: zookeeper1:2181,zookeeper2:2181,zookeeper3:2181
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      placement:
        constraints:
          - node.hostname == qww-PC
    networks:
      zoo-net:
        aliases:
          - kafka3

# docker network create -d=overlay --attachable zoo-net
networks:
  zoo-net:
    external:
      name: zoo-net
```

参考：[http://www.blockchain4u.info/docker/2017/07/28/kafka-cluster-with-docker](http://www.blockchain4u.info/docker/2017/07/28/kafka-cluster-with-docker)

## *[Kafka Manager](https://hub.docker.com/r/sheepkiller/kafka-manager/)*

docker-compose.yml:

```
version: '3.4'
services:
  kafka-manager:
    image: sheepkiller/kafka-manager
    environment: 
      ZK_HOSTS: zookeeper1:2181,zookeeper2:2181,zookeeper3:2181
      APPLICATION_SECRET: letmein
    ports:
      - "9100:9000"
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      placement:
        constraints:
          - node.hostname == ybd-PC
    networks:
      zoo-net:
        aliases:
          - kafka-manager

# docker network create -d=overlay --attachable zoo-net
networks:
  zoo-net:
    external:
      name: zoo-net
```

## [*Logrotate*](https://hub.docker.com/r/blacklabelops/logrotate/)

功能：日志清理

单机运行：

```
docker run -d \
--name logrotate \
--restart always \
-v /var/lib/docker/containers:/var/lib/docker/containers \
-v /var/log/docker:/var/log/docker \
-e "LOGS_DIRECTORIES=/var/lib/docker/containers /var/log/docker" \
-e "LOGROTATE_SIZE=10M" \
-e "LOGROTATE_INTERVAL=weekly" \
blacklabelops/logrotate:1.2
```

docker-compose.yml:

```
version: '3.4'
services:
  kafka-manager:
    image: blacklabelops/logrotate:1.2
    volumes:
      - /var/lib/docker/containers:/var/lib/docker/containers
    environment: 
      LOGS_DIRECTORIES: /var/lib/docker/containers
      LOGROTATE_INTERVAL: weekly
      LOGROTATE_SIZE: 20M
      TZ: Asia/Shanghai
    deploy:
      mode: global
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

```

## *[ShowDoc](https://github.com/star7th/showdoc)*

功能：API与数据字典管理

docker-compose.yml:

```
version: '3.4'

services:
  showdoc:
    image: yangbingdong/showdoc:1.0
    volumes:
      - /home/ybd/data/docker/showdoc/data:/var/www/html
    ports:
      - "4999:80"
    restart: always
```

其中要把 *[ShowDoc](https://github.com/star7th/showdoc)* 整个项目根目录所有文件拷贝到 data 里面，确保里面文件可执行 `chmod -R 777 data`

访问 `localhost:4999/install` 进行设置后把data里面的 `install` 目录删除防止再次安装。

# Last

![](https://cdn.yangbingdong.com/img/docker/cmd_logic.png)

> 参考：
> ***[Docker — 从入门到实践](https://yeasy.gitbooks.io/docker_practice/content/)***
> ***[Docker命令大全](https://kamisec.github.io/2017/06/docker%E5%91%BD%E4%BB%A4%E5%A4%A7%E5%85%A8/)***
> ***[Docker命令官方文档](https://docs.docker.com/engine/reference/commandline/cli/)***
