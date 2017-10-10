---
title: Dockerfile学习And构建Hexo镜像
date: 2017-10-09 09:14:57
categories: [Docker, Base]
tags: [Docker, Dockerfile]
---

![](http://ojoba1c98.bkt.clouddn.com/img/note-of-dockerfile/dockerfile.jpg)
# Preface

> 制作一个镜像可以使用`docker commit`和定制Dockerfile，但推荐的是写Dockerfile。
>
> 因为`docker commit`是一个**暗箱操作**，除了制作镜像的人知道执行过什么命令、怎么生成的镜像，别人根本无从得知，而且会加入一些没用的操作导致镜像**臃肿**。
>
> 此篇记录构建Hexo的镜像踩坑～

<!--more-->

# Build Images
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
![](http://ojoba1c98.bkt.clouddn.com/img/note-of-dockerfile/docker-build.png)

看到`Successfully built`就表示构建成功了

注意`docker build` 命令最后有一个 `.`表示构建的**上下文**，镜像构建需要把上下文的东西上传到Docker引擎去构建。

# Dockerfile 指令

## From 指定基础镜像

所谓定制镜像，那一定是以一个镜像为基础，在其上进行定制。而 `FROM` 就是指定**基础镜像**，因此一个 `Dockerfile` 中 `FROM` 是必备的指令，并且必须是第一条指令。

在 [Docker Hub](https://hub.docker.com/explore/)上有非常多的高质量的官方镜像， 有可以直接拿来使用的服务类的镜像，如 [`nginx`](https://hub.docker.com/_/nginx/)、[`redis`](https://hub.docker.com/_/redis/)、[`mongo`](https://hub.docker.com/_/mongo/)、[`mysql`](https://hub.docker.com/_/mysql/)、[`httpd`](https://hub.docker.com/_/httpd/)、[`php`](https://hub.docker.com/_/php/)、[`tomcat`](https://hub.docker.com/_/tomcat/) 等； 也有一些方便开发、构建、运行各种语言应用的镜像，如 [`node`](https://hub.docker.com/_/node/)、[`openjdk`](https://hub.docker.com/_/openjdk/)、[`python`](https://hub.docker.com/_/python/)、[`ruby`](https://hub.docker.com/_/ruby/)、[`golang`](https://hub.docker.com/_/golang/) 等。 可以在其中寻找一个最符合我们最终目标的镜像为基础镜像进行定制。 如果没有找到对应服务的镜像，官方镜像中还提供了一些更为基础的操作系统镜像，如 [`ubuntu`](https://hub.docker.com/_/ubuntu/)、[`debian`](https://hub.docker.com/_/debian/)、[`centos`](https://hub.docker.com/_/centos/)、[`fedora`](https://hub.docker.com/_/fedora/)、[`alpine`](https://hub.docker.com/_/alpine/) 等，这些操作系统的软件库为我们提供了更广阔的扩展空间。

除了选择现有镜像为基础镜像外，Docker 还存在一个特殊的镜像，名为 `scratch`。这个镜像是虚拟的概念，并不实际存在，它表示一个空白的镜像。

## RUN 执行命令

`RUN` 指令是用来执行命令行命令的。由于命令行的强大能力，`RUN` 指令在定制镜像时是最常用的指令之一。其格式有两种：

- *shell* 格式：`RUN <命令>`，就像直接在命令行中输入的命令一样。刚才写的 Dockrfile 中的 `RUN` 指令就是这种格式。
```
RUN echo '<h1>Hello, Docker!</h1>' > /usr/share/nginx/html/index.html

```

- *exec* 格式：`RUN ["可执行文件", "参数1", "参数2"]`，这更像是函数调用中的格式。

**注意**：
* RUN命令尽量精简，也就是像上面一样一个RUN（使用`$$ \`），如果分开写很多个RUN会导致镜像铺了很多层从而臃肿。
* RUN最后记住清理掉没用的垃圾，很多人初学 Docker 制作出了很臃肿的镜像的原因之一，就是忘记了每一层构建的最后一定要清理掉无关文件。

## COPY 复制文件

格式：

- `COPY <源路径>... <目标路径>`
- `COPY ["<源路径1>",... "<目标路径>"]`

和 `RUN` 指令一样，也有两种格式，一种类似于命令行，一种类似于函数调用。

`COPY` 指令将从构建上下文目录中 `<源路径>` 的文件/目录复制到新的一层的镜像内的 `<目标路径>` 位置。比如：
```
COPY package.json /usr/src/app/
```

## ADD 更高级的复制文件

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

## CMD 容器启动命令

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

## ENTRYPOINT 入口点

`ENTRYPOINT` 的格式和 `RUN` 指令格式一样，分为 `exec` 格式和 `shell` 格式。

`ENTRYPOINT` 的目的和 `CMD` 一样，都是在指定容器启动程序及参数。`ENTRYPOINT` 在运行时也可以替代，不过比 `CMD` 要略显繁琐，需要通过 `docker run` 的参数 `--entrypoint` 来指定。

当指定了 `ENTRYPOINT` 后，`CMD` 的含义就发生了改变，不再是直接的运行其命令，而是将 `CMD` 的内容作为参数传给 `ENTRYPOINT` 指令，换句话说实际执行时，将变为：

```
<ENTRYPOINT> "<CMD>"
```

这个指令非常有用，例如可以把命令后面的参数传进来或启动容器前准备一些环境然后执行启动命令（通过脚本`exec "$@"`）。

## ENV 设置环境变量

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

## ARG 构建参数

格式：`ARG <参数名>[=<默认值>]`

构建参数和 `ENV` 的效果一样，都是设置环境变量。所不同的是，`ARG` 所设置的构建环境的环境变量，在将来容器运行时是不会存在这些环境变量的。但是不要因此就使用 `ARG` 保存密码之类的信息，因为 `docker history` 还是可以看到所有值的。

`Dockerfile` 中的 `ARG` 指令是定义参数名称，以及定义其默认值。该默认值可以在构建命令 `docker build` 中用 `--build-arg <参数名>=<值>` 来覆盖。

在 1.13 之前的版本，要求 `--build-arg` 中的参数名，必须在 `Dockerfile` 中用 `ARG` 定义过了，换句话说，就是 `--build-arg` 指定的参数，必须在 `Dockerfile` 中使用了。如果对应参数没有被使用，则会报错退出构建。从 1.13 开始，这种严格的限制被放开，不再报错退出，而是显示警告信息，并继续构建。这对于使用 CI 系统，用同样的构建流程构建不同的 `Dockerfile` 的时候比较有帮助，避免构建命令必须根据每个 Dockerfile 的内容修改。

## VOLUME 定义匿名卷
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

## EXPOSE 声明端口

格式为 `EXPOSE <端口1> [<端口2>...]`。
`EXPOSE` 指令是声明运行时容器提供服务端口，这只是一个声明，在运行时并不会因为这个声明应用就会开启这个端口的服务。在 Dockerfile 中写入这样的声明有两个好处，一个是帮助镜像使用者理解这个镜像服务的守护端口，以方便配置映射；另一个用处则是在运行时使用随机端口映射时，也就是 `docker run -P`时，会自动随机映射 `EXPOSE` 的端口。

此外，在早期 Docker 版本中还有一个特殊的用处。以前所有容器都运行于默认桥接网络中，因此所有容器互相之间都可以直接访问，这样存在一定的安全性问题。于是有了一个 Docker 引擎参数 `--icc=false`，当指定该参数后，容器间将默认无法互访，除非互相间使用了 `--links` 参数的容器才可以互通，并且只有镜像中 `EXPOSE` 所声明的端口才可以被访问。这个 `--icc=false` 的用法，在引入了 `docker network`后已经基本不用了，通过自定义网络可以很轻松的实现容器间的互联与隔离。

要将 `EXPOSE` 和在运行时使用 `-p <宿主端口>:<容器端口>` 区分开来。`-p`，是映射宿主端口和容器端口，换句话说，就是将容器的对应端口服务公开给外界访问，而 `EXPOSE` 仅仅是声明容器打算使用什么端口而已，并不会自动在宿主进行端口映射。

## WORKDIR 指定工作目录
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

## USER 指定当前用户

格式：`USER <用户名>`

`USER` 指令和 `WORKDIR` 相似，都是改变环境状态并影响以后的层。`WORKDIR` 是改变工作目录，`USER`则是改变之后层的执行 `RUN`, `CMD` 以及 `ENTRYPOINT` 这类命令的身份。

当然，和 `WORKDIR` 一样，`USER` 只是帮助你切换到指定用户而已，这个用户必须是事先建立好的，否则无法切换。

```
RUN groupadd -r redis && useradd -r -g redis redis
USER redis
RUN [ "redis-server" ]
```
# 踩坑

- Dockerfile里也需要注意**权限问题**（nodejs7版本以上不能正常安装hexo，需要创建用户并制定权限去安装）
- 在docker容器里如果是root用户对挂载的文件进行了操作，那么实际上挂载文件的**权限也变成了root的**
- 使用attach进入容器，退出的时候容器也跟着退出了。。。囧
- 每一个RUN是一个**新的shell**
- `su -`之前在启动脚本加了`-`，导致**环境变量以及工作目录都变了**

# Hexo-Docker

最后献上踩坑写的Hexo Dockerfile:

```
# 使用Ubuntu官方镜像
FROM ubuntu:latest

# 作者信息
MAINTAINER yangbingdong <yangbingdong1994@gmail.com>

# 设置环境变量，使用${变量名}取值
ENV \
    USER_NAME=hexo \
    NODE_VERSION=8.5.0 \
    NODE_DIR=/home/${USER_NAME}/nodejs

# 需要执行的命令，使用 `$$ \` 分割多行多个命令
RUN \
    # 安装基本的依赖以及工具
    apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y git && \
    apt-get install -y curl && \
    apt-get install -y libpng-dev && \
    # 清理不必要的垃圾
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # 创建hexo用户去安装hexo
    useradd -m -U ${USER_NAME} && \
    # 创建nodejs目录
    mkdir ${NODE_DIR} && \
    # 将nodejs下载解压到对应目录
    curl -L https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz | tar xvzf - -C ${NODE_DIR} --strip-components=1 && \
    # 把nodejs文件赋权给hexo用户
    chown -R ${USER_NAME}.${USER_NAME} ${NODE_DIR} && \
    # 把node相关命令软连接到/usr/local/bin目录下以便我们使用
    ln -s ${NODE_DIR}/bin/node /usr/local/bin/node && \
    ln -s ${NODE_DIR}/bin/npm /usr/local/bin/npm && \
    # 以hexo用户身份安装hexo-cli
    su - ${USER_NAME} -c "npm install -g hexo-cli" && \
    # 同样把hexo命令放到/usr/local/bin下
    ln -s ${NODE_DIR}/bin/hexo /usr/local/bin/hexo && \
    # 使用淘宝镜像
    npm config set registry https://registry.npm.taobao.org/

# 切换到此目录
WORKDIR /home/${USER_NAME}/blog

# 可以挂载进来的卷（文件夹）
VOLUME ["/home/${USER_NAME}/blog", "/home/${USER_NAME}/.ssh"]

# 暴露端口
EXPOSE 4000

# 把上下文中的docker-entrypoint.sh复制进来
COPY docker-entrypoint.sh /docker-entrypoint.sh

# 执行脚本
ENTRYPOINT ["/docker-entrypoint.sh"]

# 这个...鸡肋操作
CMD ['/bin/bash']
```

docker-entrypoint.sh :
```
#!/bin/sh

# 发生异常回滚
set -e

# 设置git相关信息，不设置默认为博主的=.=
GIT_USER_NAME=${GIT_USER_NAME:-yangbingdong}

GIT_USER_MAIL=${GIT_USER_MAIL:-yangbingdong1994@gmail.com}

# 你想要的用户名
NEW_USER_NAME=${NEW_USER_NAME:-ybd}

# 由于每次启动容器都会执行这个脚本，但这个只需要执行一次，在此标志一下
if [ $(git config --system user.name)x = ${GIT_USER_NAME}x ]
then
	su ${NEW_USER_NAME}
else
    # 修改用户名
	/usr/sbin/usermod -l ${NEW_USER_NAME} ${USER_NAME}

	/usr/sbin/usermod -c ${NEW_USER_NAME} ${NEW_USER_NAME}

	/usr/sbin/groupmod -n ${NEW_USER_NAME} ${USER_NAME}

	chown -R ${NEW_USER_NAME}.${NEW_USER_NAME} /home/${USER_NAME}/blog

	chmod -R 766 /home/${USER_NAME}/blog
    
    # 设置git全局信息
	git config --system user.name $GIT_USER_NAME

	git config --system user.email $GIT_USER_MAIL

	su ${NEW_USER_NAME}
fi

# 执行脚本之后的命令
exec "$@"
```

源码：***[https://github.com/masteranthoneyd/docker-hexo](https://github.com/masteranthoneyd/docker-hexo)***

# Last

> 参考：***[Docker从入门到实践](https://www.gitbook.com/book/yeasy/docker_practice/details)***