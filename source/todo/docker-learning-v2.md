
![](http://ojoba1c98.bkt.clouddn.com/img/docker/docker.png)
# Preface
> 作为一种新兴的虚拟化方式,Docker跟传统的虚拟化方式相比具有众多的优势

# 容器化 VS 虚拟化

![](http://ojoba1c98.bkt.clouddn.com/img/docker/docker-diff-virtual.jpg)

![](http://ojoba1c98.bkt.clouddn.com/img/docker/container-and-virtual.png)

**服务器**好比运输码头：拥有场地和各种设备（服务器硬件资源）

**服务器虚拟化**好比作码头上的仓库：拥有独立的空间堆放各种货物或集装箱

(仓库之间完全独立，独立的应用系统和操作系统）

# What is Docker

Docker是容器化的一种实现，

安装和配置MySQL、Memcatched、MongoDB、Hadoop、GlusterFS、RabbitMQ、Node.js、Nginx

Pouch

# Concept

以下是Docker的三个基本概念。

## Image(镜像)
官方而言，Docker 镜像是一个**特殊的文件系统**，除了提供容器运行时所需的程序、库、资源、配置等文件外，还包含了一些为运行时准备的一些配置参数（如匿名卷、环境变量、用户等）。镜像不包含任何动态数据，其内容在构建之后也不会被改变。
对博主而言，它相当于就是个`Java Class`(类)=.=

但它的存储结构类似`Git`，一层一层地网上盖，**删除一个文件并不会真的删除**，只是在那个文件上面做了一个标记为已删除。在最终容器运行的时候，虽然不会看到这个文件，但是实际上该文件会**一直跟随镜像**。因此，在构建镜像的时候，需要额外小心，**每一层尽量只包含该层需要添加的东西**，任何额外的东西应该在该层构建结束前清理掉。

## Container(容器)

通俗来说，如果镜像是类，那么容器就是这个类的实例了，镜像是静态的定义，容器是镜像运行时的实体。容器可以被创建、启动、停止、删除、暂停等。

容器也有其特性，例如存储，不指定数据卷(`Volume`)的话，容器消亡数据也就跟着没了...
跟多特性请自行百度~

## Repository(仓库)
仓库没啥好说的了，以 `Ubuntu` 镜像 为例，`ubuntu` 是仓库的名字，其内包含有不同的版本标签，如，`14.04`, `16.04`。我们可以通过 `ubuntu:14.04`，或者 `ubuntu:16.04` 来具体指定所需哪个版本的镜像。如果忽略了标签，比如 `ubuntu`，那将视为 `ubuntu:latest`

# Install
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

# Use Image
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
![](http://ojoba1c98.bkt.clouddn.com/img/docker/docker-images.png)
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

# Operating Container
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

## 停止
docker stop :停止一个运行中的容器：
```
docker stop [OPTIONS] CONTAINER [CONTAINER...]
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

## 导出和导入容器
**导出容器快照**
```
docker export [OPTIONS] CONTAINER
```
例如：
```
docker export 7691a814370e > ubuntu.tar
```

**导入容器快照**
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

-f :根据条件过滤显示的内容。

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

# Dev Env In Docker
## MySql

[**mysql**](https://hub.docker.com/_/mysql/):

```
MYSQL=/home/ybd/data/docker/mysql && docker run --name=mysql -p 3306:3306  -v $MYSQL/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root -d mysql --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --sql-mode=STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION --lower-case-table-names=1
```

## Redis

[**redis**](https://hub.docker.com/_/redis/):

```
REDIS=/home/ybd/data/docker/redis && docker run -p 6379:6379 --restart=always -v $REDIS/redis.conf:/usr/local/etc/redis/redis.conf -v $REDIS/data:/data --name redis -d redis redis-server /usr/local/etc/redis/redis.conf --appendonly yes
```
安装终端链接工具：
```
sudo apt-get install redis-tool
```

# Last

> 参考：
> ***[Docker — 从入门到实践](https://www.gitbook.com/book/yeasy/docker_practice/details)***
> ***[Docker命令大全](https://kamisec.github.io/2017/06/docker%E5%91%BD%E4%BB%A4%E5%A4%A7%E5%85%A8/)***
