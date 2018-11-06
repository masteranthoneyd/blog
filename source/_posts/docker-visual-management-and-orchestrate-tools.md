---
title: Docker可视化与管理工具
date: 2018-01-02 12:57:52
categories: [Docker]
tags: [Docker, Swarm]
---

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/docker-managerment.png)

# Preface

> 在学习了Docker的基本操作之后，接下来就是Docker的管理部分了，这包括Docker的可视化管理以及集群管理。
>
> 此篇主要记录Docker私有库的搭建，Docker编排工具的介绍以及使用，可视化管理工具的介绍以及搭建...

<!--more-->

# Docker Registry & Mirror

## Harbor

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/harbor-arch.png)

Harbor是一个用于存储和分发Docker镜像的企业级Registry服务器，通过添加一些企业必需的功能特性，例如安全、标识和管理等，扩展了开源Docker Distribution。作为一个企业级私有Registry服务器，Harbor提供了更好的性能和安全。提升用户使用Registry构建和运行环境传输镜像的效率。Harbor支持安装在多个Registry节点的镜像资源复制，镜像全部保存在私有Registry中， 确保数据和知识产权在公司内部网络中管控。另外，Harbor也提供了高级的安全特性，诸如用户管理，访问控制和活动审计等。

- **基于角色的访问控制** - 用户与Docker镜像仓库通过“项目”进行组织管理，一个用户可以对多个镜像仓库在同一命名空间（project）里有不同的权限。
- **镜像复制** - 镜像可以在多个Registry实例中复制（同步）。尤其适合于负载均衡，高可用，混合云和多云的场景。
- **图形化用户界面** - 用户可以通过浏览器来浏览，检索当前Docker镜像仓库，管理项目和命名空间。
- **AD/LDAP 支持** - Harbor可以集成企业内部已有的AD/LDAP，用于鉴权认证管理。
- **审计管理** - 所有针对镜像仓库的操作都可以被记录追溯，用于审计管理。
- **国际化** - 已拥有英文、中文、德文、日文和俄文的本地化版本。更多的语言将会添加进来。
- **RESTful API** - RESTful API 提供给管理员对于Harbor更多的操控, 使得与其它管理软件集成变得更容易。
- **部署简单** - 提供在线和离线两种安装工具， 也可以安装到vSphere平台(OVA方式)虚拟设备。

- 集成clair进行镜像安全漏洞扫描

Harbor共由七个容器组成:

a.`harbor-adminserver`:harbor系统管理服务

b.`harbor-db`: 由官方mysql镜像构成的数据库容器

c.`harbor-jobservice`:harbor的任务管理服务

d.`harbor-log`:harbor的日志收集、管理服务

e.`harbor-ui`:harbor的web页面服务

f.`nginx`:负责流量转发和安全验证

g.`registry`:官方的Docker registry，负责保存镜像

### Condition

前置条件：

1.需要`Python2.7`或以上

2.Docker版本要在1.10或以上

3.Docker compose版本要在1.6.0或以上

### Download

[***Release页面***](https://github.com/vmware/harbor/releases)下载离线安装包（或在线也可以，不过安装的时候很慢）

### Config

解压缩之后，目录下会生成`harbor.conf`文件，该文件就是Harbor的配置文件。

```
# 1. hostname设置访问地址，可以使用ip、域名，不可以设置为127.0.0.1或localhost
# 2. 默认情况下，harbor使用的端口是80，若使用自定义的端口，除了要改docker-compose.yml文件中的配置外，
# 这里的hostname也要加上自定义的端口，在docker login、push时会报错
# hostname = ${IP_ADDR}:${PORT}
hostname = 192.168.1.102:8888

# 访问协议，默认是http，也可以设置https，如果设置https，则nginx ssl需要设置on
ui_url_protocol = http

# mysql数据库root用户默认密码root123，实际使用时修改下
db_password = root123

#Maximum number of job workers in job service  
max_job_workers = 3 

#The path of secretkey storage
secretkey_path = /data

# 启动Harbor后，管理员UI登录的密码，默认是Harbor12345
# 若修改了此处的admin登录密码。则登录后台时使用修改后的密码
harbor_admin_password = Harbor12345

# 认证方式，这里支持多种认证方式，如LADP、本次存储、数据库认证。默认是db_auth，mysql数据库认证
auth_mode = db_auth

# 是否开启自注册
self_registration = on

# Token有效时间，默认30分钟
token_expiration = 30

# 用户创建项目权限控制，默认是everyone（所有人），也可以设置为adminonly（只能管理员）
project_creation_restriction = everyone
```

harbor默认监听80端口，我们修改为8888端口，同时`docker-compose.yml`也需要修改`proxy`的端口

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/proxy-port.png)

还可以修改仓库的存储位置：

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/harbor-registry-data.png)

### Install

运行安装脚本：

```
./install.sh
```

集成clair漏洞扫描：

```
./install.sh --with-clair
```

脚本会自动解压镜像文件并运行docker-compose

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/harbor-install.png)

或者运行`prepare`文件再手动运行docker-compose

启动之后浏览器打开刚才修改的hostname

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/harbor-dashboard.png)

**帐号密码默认是** `admin/Harbor12345`，可在配置文件`harbor.conf`中修改

**修改配置文件之后**需要重新生成一些内置配置：

```
./prepare
docker-compose up -d
```

### 登录被refuse

多次docker login被refuse

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/refuse.png)

这是因为 Docker 默认**不允许非 `HTTPS` 方式推送镜像**。我们可以通过 Docker 配置来**取消这个限制**，或者配置能够通过 `HTTPS` 访问的私有仓库。

如果是`systemd` 的系统例如`Ubuntu16.04+`、`Debian 8+`、`centos 7`，可以在`/etc/docker/daemon.json` 中写入如下内容：

```
{
  "registry-mirrors": ["https://xxxxx.mirror.aliyuncs.com"],
  "insecure-registries": ["192.168.1.102:8888"]
}
```

然后重新加载Docker：

```
sudo systemctl reload docker
```

### Login and Push

```
docker login 192.168.1.102:8888 -u admin -p Harbor12345

docker tag ubuntu:latest 192.168.1.102/library/ubuntu:latest
docker push 192.168.1.102/library/ubuntu:latest
```

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/harbor-push.png)

**注意**：使用`docker stack deploy`时，如果是私有镜像，需要终端登录后加上`--with-registry-auth`选项。

### 删除Harbor

**删除harbor，但保留数据**

```
docker-compose down -v
```

**删除harbor数据**（对应`docker-compose.yml`里面的数据卷）

```
rm -r /data/database
rm -r /data/registry
```

**删除镜像**

UI界面操作删除镜像，只是删除元数据，并未删除真实数据，还需要调用registry的garbage-collect进行清理

```
docker-compose stop

docker run -it --name gc --rm --volumes-from registry vmware/registry:2.6.2-photon garbage-collect --dry-run /etc/registry/config.yml #只是打印过程，并不删除

docker run -it --name gc --rm --volumes-from registry vmware/registry:2.6.2-photon garbage-collect  /etc/registry/config.yml

docker-compose start
```

注意：配置文件`config.yml`挂载在`/etc/registry/`下.

### 踩坑

#### python版本

在Ubuntu18.04中的python是3+版本的，需要装回2.7版本，不然会有不明异常。。。：

```
sudo apt install python2.7 python-minimal -y
```

#### Fail to generate key file

这个貌似是openssl的问题，解决方案是将`prepare`中的`empty_subj = "/C=/ST=/L=/O=/CN=/"`改为`empty_subj = "/"`

## Registry Mirror

**registry mirror原理**

Docker Hub的镜像数据分为两部分：index数据和registry数据。前者保存了镜像的一些元数据信息，数据量很小；后者保存了镜像的实际数据，数据量比较大。平时我们使用docker pull命令拉取一个镜像时的过程是：先去index获取镜像的一些元数据，然后再去registry获取镜像数据。

所谓registry mirror就是搭建一个registry，然后将docker hub的registry数据缓存到自己本地的registry。整个过程是：当我们使用docker pull去拉镜像的时候，会先从我们本地的registry mirror去获取镜像数据，如果不存在，registry mirror会先从docker hub的registry拉取数据进行缓存，再传给我们。而且整个过程是流式的，registry mirror并不会等全部缓存完再给我们传，而且边缓存边给客户端传。

对于缓存，我们都知道一致性非常重要。registry mirror与docker官方保持一致的方法是：registry mirror只是缓存了docker hub的registry数据，并不缓存index数据。所以我们pull镜像的时候会先连docker hub的index获取镜像的元数据，如果我们registry mirror里面有该镜像的缓存，且数据与从index处获取到的元数据一致，则从registry mirror拉取；如果我们的registry mirror有该镜像的缓存，但数据与index处获取的元数据不一致，或者根本就没有该镜像的缓存，则先从docker hub的registry缓存或者更新数据。

1、拉取镜像

```
docker pull registry:latest
```

2、获取registry的默认配置

```
docker run -it --rm --entrypoint cat registry:latest  /etc/docker/registry/config.yml > config.yml
```

内容可能如下：

```
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
```

我们在最后面加上如下配置：

```
proxy:
  remoteurl: https://registry-1.docker.io
  username: [username]
  password: [password]
```

`username`和`password`是可选的，如果配置了的话，那registry mirror除了可以缓存所有的公共镜像外，也可以访问这个用户所有的私有镜像。

启动registry容器：

Bash

```
docker run  --restart=always -p 5000:5000 --name v2-mirror -v /data:/var/lib/registry -v  $PWD/config.yml:/etc/registry/config.yml registry:latest /etc/registry/config.yml
```

当然我们也可以使用docker-compose启动：

```
version: '3'
services:
  registry:
    image: library/registry:latest
    container_name: registry-mirror
    restart: always
    volumes:
      - /data:/var/lib/registry
      - ./config.yml:/etc/registry/config.yml
    ports:
      - 5000:5000
    command:
      ["serve", "/etc/registry/config.yml"]
```

curl验证一下服务是否启动OK：

```
# ybd @ ybd-PC in ~ [17:30:14] 
$ curl -I http://192.168.6.113:5000
HTTP/1.1 200 OK
Cache-Control: no-cache
Date: Fri, 05 Jan 2018 09:30:27 GMT
Content-Type: text/plain; charset=utf-8
```

最后修改`/etc/docker/daemon.json`或`/etc/default/docker`中的`registry-mirrors`即可

# Cluster and Orchestrate Tools

## Docker Compose

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/docker-compose-logo.png)

> 官方文档：[***https://docs.docker.com/compose/***](https://docs.docker.com/compose/)
>
> release：[***https://github.com/docker/compose/releases***](https://github.com/docker/compose/releases)

Compose是定义和运行多容器Docker应用程序的工具，使用Compose，您可以使用YAML文件来配置应用程序的服务，然后，使用单个命令创建并启动配置中的所有服务。

Dockerfile 可以让用户管理一个单独的应用容器。使用Docker Compose，不再需要使用shell脚本来启动容器。在配置文件中，所有的容器通过services来定义，然后使用`docker-compose`脚本来启动，停止和重启应用，和应用中的服务以及所有依赖服务的容器

### Install

最新安装请看官方文档：***[https://docs.docker.com/compose/install/#install-compose](https://docs.docker.com/compose/install/#install-compose)***

```
sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
```

变为可执行命令：

```
sudo chmod +x /usr/local/bin/docker-compose
```

检查安装成功：

```
docker-compose --version
```

卸载：

```
sudo rm /usr/local/bin/docker-compose
```

### Command

基本命令：

`-p` 指定项目名称

`build` 构建项目中的服务容器 --force-rm 删除构建过程中的临时容器

`--no-cache` 构建过程中不使用 cache

`--pull` 始终通过 pull 来获取更新版本的镜像

`docker-compose kill` 强制停止服务容器

`docker-compose logs` 查看容器的输出 调试必备

`docker-compose pause` 暂停一个服务容器

`docker-compose unpause` 恢复暂停

`docker-compose port` 打印某个容器端口所映射的公共端口

`docker-compose ps` 列出项目中目前的所有容器 -q 只打印容器 id

`docker-compose pull` 拉取服务依赖的镜像

`docker-compose restart -t` 指定重启前停止容器的超时默认10秒

`docker-compose rm` 删除所有停止状态的容器先执行 stop

`docker-compose run` 指定服务上执行一个命令

`docker-compose start` 启动已经存在的服务容器

`docker-compose stop` 停止已经存在的服务容器

`docker-compose up` 自动构建、创建服务、启动服务，关联一系列，运行在前台，ctrl c 就都停止运行。如果容器已经存在，将会尝试停止容器，重新创建。如果不希望重新创建，可以 `--no-recreate` 就只启动处于停止状态的容器，如果只想重新部署某个服务，可以使用

`docker-compose up --no-deps -d` ，不影响其所依赖的服务

`docker-compose up -d` 后台启动运行，生产环境必备

`docker-compose down` 停止并删除容器

### Zsh命令补全

```
mkdir -p ~/.zsh/completion
curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/zsh/_docker-compose > ~/.zsh/completion/_docker-compose
```

在`.zshrc`添加：

**注意**：(如果是`oh-my-zsh`，在`$ZSH/oh-my-zsh.sh`中添加)

```
fpath=(~/.zsh/completion $fpath)
```

执行：

```
autoload -Uz compinit && compinit -i
```

重载：

```
exec $SHELL -l
```

### Compose 文件指令

> 最新参看文档： ***[https://docs.docker.com/compose/compose-file/](https://docs.docker.com/compose/compose-file/)***

默认的模板文件名称为 `docker-compose.yml`，格式为 YAML 格式。

```
version: "3"
services:
  webapp:
    image: examples/web
    ports:
      - "80:80"
    volumes:
      - "/data"
```

注意每个服务都必须通过 `image` 指令指定镜像或 `build` 指令（需要 Dockerfile）等来自动构建生成镜像。

如果使用 `build` 指令，在 `Dockerfile` 中设置的选项(例如：`CMD`, `EXPOSE`, `VOLUME`, `ENV` 等) 将会自动被获取，无需在 `docker-compose.yml` 中再次设置。下面分别介绍各个指令的用法。

#### `build`

指定 `Dockerfile` 所在文件夹的路径（可以是绝对路径，或者相对 docker-compose.yml 文件的路径）。 `Compose` 将会利用它自动构建这个镜像，然后使用这个镜像。

```
version: '3'
services:

  webapp:
    build: ./dir

```

你也可以使用 `context` 指令指定 `Dockerfile` 所在文件夹的路径。

使用 `dockerfile` 指令指定 `Dockerfile` 文件名。

使用 `arg` 指令指定构建镜像时的变量。

```
version: '3'
services:

  webapp:
    build:
      context: ./dir
      dockerfile: Dockerfile-alternate
      args:
        buildno: 1

```

使用 `cache_from` 指定构建镜像的缓存

```
build:
  context: .
  cache_from:
    - alpine:latest
    - corp/web_app:3.14
```

#### `cap_add, cap_drop`

指定容器的内核能力（capacity）分配。

例如，让容器拥有所有能力可以指定为：

```
cap_add:
  - ALL

```

去掉 NET_ADMIN 能力可以指定为：

```
cap_drop:
  - NET_ADMIN

```

#### `command`

覆盖容器启动后默认执行的命令。

```
command: echo "hello world"
```

#### `configs`

仅用于 `Swarm mode`，详细内容请查看下面Swarm模式介绍

#### `cgroup_parent`

指定父 `cgroup` 组，意味着将继承该组的资源限制。

例如，创建了一个 cgroup 组名称为 `cgroups_1`。

```
cgroup_parent: cgroups_1

```

#### `container_name`

指定容器名称。默认将会使用 `项目名称_服务名称_序号` 这样的格式。

```
container_name: docker-web-container

```

> 注意: 指定容器名称后，该服务将**无法进行扩展**（**scale**），因为 Docker 不允许多个容器具有相同的名称。

#### `deploy`

仅用于 `Swarm mode`，这是 V3 才能使用的语法，通过`docker-compose up`方式启动会忽略这部分。

语法规则：

```
deploy:
  replicas: 6
  update_config:
    parallelism: 2
    delay: 10s
  restart_policy:
    condition: on-failure
```

##### `mode`

首先 deploy 提供了一个模式选项，它的值有 `global` 和 `replicated` 两个，默认是 `replicated` 模式。

这两个模式的区别是：

- `global`：每个集群每个服务实例启动一个容器，就像以前启动 Service 时一样。
- `replicated`：用户可以指定集群中实例的副本数量。

以前这个功能是无法在 Compose 中直接实现的，以前需要用户先使用 `docker-compose bundle` 命令将 docker-compose.yml 转换为 .dab 文件，然后才能拿到集群部署，而且很多功能用不了。

但是随着这次更新把 stack 加进来了，deploy 也就水到渠成加进了 Compose 功能中。

##### `replicas`

上面说到可以指定副本数量，其中 replicas 就是用于指定副本数量的选项。

```
deploy:
  replicas: 6
```

部署服务栈：

```
docker stack deploy --compose-file docker-compose.yml
```

##### `placement`

这是 Docker 1.12 版本时就引入的概念，允许用户限制服务容器，下面是官方的说明：

| node attribute  | matches                  | example                                  |
| --------------- | ------------------------ | ---------------------------------------- |
| `node.id`       | Node ID                  | `node.id==2ivku8v2gvtg4`                 |
| `node.hostname` | Node hostname            | `node.hostname!=node-2`                  |
| `node.role`     | Node role                | `node.role==manager`                     |
| `node.labels`   | user defined node labels | `node.labels.security==high`             |
| `engine.labels` | Docker Engine's labels   | `engine.labels.operatingsystem==ubuntu 14.04` |

```
version: '3'
services:
  db:
    image: postgres
    deploy:
      placement:
        constraints:
          - node.role == manager
          - engine.labels.operatingsystem == ubuntu 14.04
        preferences:
          - spread: node.labels.zone
```

##### `update_config`

早在上一个版本中，Swarm 就提供了一个升级回滚的功能。当服务升级出现故障时，超过重试次数则停止升级的功能，这也很方便，避免让错误的应用替代现有正常服务。

这个选项用于告诉 Compose 使用怎样的方式升级，以及升级失败后怎样回滚原来的服务。

- `parallelism`: 服务中多个容器同时更新。
- `delay`: 设置每组容器更新之间的延迟时间。
- `failure_action`: 设置更新失败时的动作，可选值有 continue 与 pause (默认是：pause)。
- `monitor`: 每次任务更新失败后监视故障的持续时间 (ns|us|ms|s|m|h) (默认：0s)。
- `max_failure_ratio`: 更新期间容忍的故障率。

##### `resources`

看例子：

```
resources:
  limits:
    cpus: '0.001'
    memory: 50M
  reservations:
    cpus: '0.0001'
    memory: 20M
```

知道干啥用了吧，这是一个新的语法选项，替代了之前的类似 `cpu_shares`, `cpu_quota`, `cpuset`, `mem_limit`, `memswap_limit` 这种选项。统一起来好看点。

##### `restart_policy`

设置如何重启容器，毕竟有时候容器会意外退出。

- `condition`：设置重启策略的条件，可选值有 none, on-failure 和 any (默认：any)。
- `delay`：在重新启动尝试之间等待多长时间，指定为持续时间（默认值：0）。
- `max_attempts`：设置最大的重启尝试次数，默认是永不放弃，哈哈，感受到一股运维的绝望。
- `window`：在决定重新启动是否成功之前要等待多长时间，默认是立刻判断，有些容器启动时间比较长，指定一个“窗口期”非常重要。

#### `devices`

指定设备映射关系。

```
devices:
  - "/dev/ttyUSB1:/dev/ttyUSB0"
```

#### `depends_on`

解决容器的依赖、**启动先后的问题**。以下例子中会先启动 `redis` `db` 再启动 `web`

```
version: '3'

services:
  web:
    build: .
    depends_on:
      - db
      - redis

  redis:
    image: redis

  db:
    image: postgres

```

> 注意：`web` 服务不会等待 `redis` `db` 「完全启动」之后才启动。

#### `dns`

自定义 `DNS` 服务器。可以是一个值，也可以是一个列表。

```
dns: 8.8.8.8

dns:
  - 8.8.8.8
  - 114.114.114.114

```

#### `dns_search`

配置 `DNS` 搜索域。可以是一个值，也可以是一个列表。

```
dns_search: example.com

dns_search:
  - domain1.example.com
  - domain2.example.com

```

#### `tmpfs`

挂载一个 tmpfs 文件系统到容器。

```
tmpfs: /run
tmpfs:
  - /run
  - /tmp

```

#### `env_file`

从文件中获取环境变量，可以为单独的文件路径或列表，默认读当前目录`.env`。

如果通过 `docker-compose -f FILE` 方式来指定 Compose 模板文件，则 `env_file` 中变量的路径会**基于模板文件路径**。

如果有变量名称与 `environment` 指令冲突，则按照惯例，**以后者为准**。

```
env_file: .env

env_file:
  - ./common.env
  - ./apps/web.env
  - /opt/secrets.env
```

环境变量文件中每一行必须符合格式，支持 `#` 开头的注释行。

```
# common.env: Set development environment
PROG_ENV=development
```

#### `environment`

设置环境变量。你可以使用数组或字典两种格式。

**只给定名称的变量会自动获取运行 Compose 主机上对应变量的值**，**可以用来防止泄露不必要的数据**。

```
environment:
  RACK_ENV: development
  SESSION_SECRET:

environment:
  - RACK_ENV=development
  - SESSION_SECRET
```

如果变量名称或者值中用到 `true|false，yes|no` 等表达 [布尔](http://yaml.org/type/bool.html) 含义的词汇，**最好放到引号里**，避免 YAML 自动解析某些内容为对应的布尔语义。这些特定词汇，包括

```
y|Y|yes|Yes|YES|n|N|no|No|NO|true|True|TRUE|false|False|FALSE|on|On|ON|off|Off|OFF

```

#### `expose`

暴露端口，但不映射到宿主机，只被连接的服务访问。

仅可以指定内部端口为参数

```
expose:
 - "3000"
 - "8000"

```

#### `external_links`

> 注意：不建议使用该指令。

链接到 `docker-compose.yml` 外部的容器，甚至并非 `Compose` 管理的外部容器。

```
external_links:
 - redis_1
 - project_db_1:mysql
 - project_db_1:postgresql

```

#### `extra_hosts`

类似 Docker 中的 `--add-host` 参数，指定额外的 host 名称映射信息。

```
extra_hosts:
 - "googledns:8.8.8.8"
 - "dockerhub:52.1.157.61"
```

会在启动后的服务容器中 `/etc/hosts` 文件中添加如下两条条目。

```
8.8.8.8 googledns
52.1.157.61 dockerhub
```

#### `healthcheck`

通过命令检查容器是否健康运行。

```
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost"]
  interval: 1m30s
  timeout: 10s
  retries: 3
```

#### `image`

指定为镜像名称或镜像 ID。如果镜像在本地不存在，`Compose` 将会尝试拉去这个镜像。

```
image: ubuntu
image: orchardup/postgresql
image: a4bc65fd

```

#### `labels`

为容器添加 Docker 元数据（metadata）信息。例如可以为容器添加辅助说明信息。

```
labels:
  com.startupteam.description: "webapp for a startup team"
  com.startupteam.department: "devops department"
  com.startupteam.release: "rc3 for v1.0"
```

#### `links`

> 注意：不推荐使用该指令。

#### `logging`

配置日志选项。

```
logging:
  driver: syslog
  options:
    syslog-address: "tcp://192.168.0.42:123"
```

目前支持三种日志驱动类型。

```
driver: "json-file"
driver: "syslog"
driver: "none"

```

`options` 配置日志驱动的相关参数。

```
options:
  max-size: "200k"
  max-file: "10"
```

更多详情：[https://docs.docker.com/engine/admin/logging/overview/](https://docs.docker.com/engine/admin/logging/overview/)

#### `network_mode`

设置网络模式。使用和 `docker run` 的 `--network` 参数一样的值。

```
network_mode: "bridge"
network_mode: "host"
network_mode: "none"
network_mode: "service:[service name]"
network_mode: "container:[container name/id]"
```

#### `networks`

配置容器连接的网络。

```
version: "3"
services:

  some-service:
    networks:
     - some-network
     - other-network

networks:
  some-network:
  other-network:
```

Docker 网络类型，有 `bridge` `overlay`，默认为`bridge`。其中 `overlay` 网络类型用于 `Swarm mode`

#### `pid`

跟主机系统共享进程命名空间。打开该选项的容器之间，以及容器和宿主机系统之间可以通过进程 ID 来相互访问和操作。

```
pid: "host"
```

#### `ports`

暴露端口信息。

使用宿主端口：容器端口 `(HOST:CONTAINER)` 格式，或者仅仅指定容器的端口（宿主将会随机选择端口）都可以。

```
ports:
 - "3000"
 - "8000:8000"
 - "49100:22"
 - "127.0.0.1:8001:8001"
```

*注意：当使用 HOST:CONTAINER 格式来映射端口时，如果你使用的容器端口小于 60 并且没放到引号里，可能会得到错误结果，因为 YAML 会自动解析 xx:yy 这种数字格式为 60 进制。为避免出现这种问题，建议数字串都采用引号包括起来的字符串格式。*

#### `secrets`

存储敏感数据，例如 `mysql` 服务密码。

```
version: "3"
services:

mysql:
  image: mysql
  environment:
    MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
  secrets:
    - db_root_password
    - my_other_secret

secrets:
  my_secret:
    file: ./my_secret.txt
  my_other_secret:
    external: true
```

#### `security_opt`

指定容器模板标签（label）机制的默认属性（用户、角色、类型、级别等）。例如配置标签的用户名和角色名。

```
security_opt:
    - label:user:USER
    - label:role:ROLE
```

#### `stop_signal`

设置另一个信号来停止容器。在默认情况下使用的是 SIGTERM 停止容器。

```
stop_signal: SIGUSR1
```

#### `sysctls`

配置容器内核参数。

```
sysctls:
  net.core.somaxconn: 1024
  net.ipv4.tcp_syncookies: 0

sysctls:
  - net.core.somaxconn=1024
  - net.ipv4.tcp_syncookies=0
```

#### `ulimits`

指定容器的 ulimits 限制值。

例如，指定最大进程数为 65535，指定文件句柄数为 20000（软限制，应用可以随时修改，不能超过硬限制） 和 40000（系统硬限制，只能 root 用户提高）。

```
  ulimits:
    nproc: 65535
    nofile:
      soft: 20000
      hard: 40000
```

#### `volumes`

数据卷所挂载路径设置。可以设置宿主机路径 （`HOST:CONTAINER`） 或加上访问模式 （`HOST:CONTAINER:ro`）。

该指令中路径支持相对路径。

```
volumes:
 - /var/lib/mysql
 - cache/:/tmp/cache
 - ~/configs:/etc/configs/:ro
```

#### 其它指令

此外，还有包括 `domainname, entrypoint, hostname, ipc, mac_address, privileged, read_only, shm_size, restart, stdin_open, tty, user, working_dir` 等指令，基本跟 `docker run` 中对应参数的功能一致。

指定服务容器启动后执行的入口文件。

```
entrypoint: /code/entrypoint.sh
```

指定容器中运行应用的用户名。

```
user: nginx
```

指定容器中工作目录。

```
working_dir: /code
```

指定容器中搜索域名、主机名、mac 地址等。

```
domainname: your_website.com
hostname: test
mac_address: 08-00-27-00-0C-0A
```

允许容器中运行一些特权命令。

```
privileged: true
```

指定容器退出后的重启策略为始终重启。该命令对保持服务始终运行十分有效，在生产环境中推荐配置为 `always` 或者 `unless-stopped`。

```
restart: always
```

以只读模式挂载容器的 root 文件系统，意味着不能对容器内容进行修改。

```
read_only: true
```

打开标准输入，可以接受外部输入。

```
stdin_open: true
```

模拟一个伪终端。

```
tty: true
```

#### 读取变量

Compose 模板文件支持动态读取主机的系统环境变量和当前目录下的 `.env` 文件中的变量。

例如，下面的 Compose 文件将从运行它的环境中读取变量 `${MONGO_VERSION}` 的值，并写入执行的指令中。

```
version: "3"
services:

db:
  image: "mongo:${MONGO_VERSION}"

```

如果执行 `MONGO_VERSION=3.2 docker-compose up` 则会启动一个 `mongo:3.2` 镜像的容器；如果执行 `MONGO_VERSION=2.8 docker-compose up` 则会启动一个 `mongo:2.8` 镜像的容器。

若当前目录存在 `.env` 文件，执行 `docker-compose` 命令时将从该文件中读取变量。

在当前目录新建 `.env` 文件并写入以下内容。

```
# 支持 # 号注释
MONGO_VERSION=3.6
```

执行 `docker-compose up` 则会启动一个 `mongo:3.6` 镜像的容器。

**官方例子**：

```
version: "3"
services:

  redis:
    image: redis:alpine
    ports:
      - "6379"
    networks:
      - frontend
    deploy:
      replicas: 2
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure
  db:
    image: postgres:9.4
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend
    deploy:
      placement:
        constraints: [node.role == manager]
  vote:
    image: dockersamples/examplevotingapp_vote:before
    ports:
      - 5000:80
    networks:
      - frontend
    depends_on:
      - redis
    deploy:
      replicas: 2
      update_config:
        parallelism: 2
      restart_policy:
        condition: on-failure
  result:
    image: dockersamples/examplevotingapp_result:before
    ports:
      - 5001:80
    networks:
      - backend
    depends_on:
      - db
    deploy:
      replicas: 1
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure

  worker:
    image: dockersamples/examplevotingapp_worker
    networks:
      - frontend
      - backend
    deploy:
      mode: replicated
      replicas: 1
      labels: [APP=VOTING]
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 3
        window: 120s
      placement:
        constraints: [node.role == manager]

  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    stop_grace_period: 1m30s
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints: [node.role == manager]

networks:
  frontend:
  backend:

volumes:
  db-data:
```



### 理解多compose文件组合

默认，`compose`会读取两个文件，一个`docker-compose.yml`和一个可选的`docker-compose.override.yml`文件。通常，`docker-compose.yml`文件包含你的基本配置，而`docker-compose.override.yml`，顾名思义，就是包含的现有服务配置的覆盖内容，或完全新的配置。

如果一个服务在这两个文件中都有定义，那么`compose`将使用[添加和覆盖配置](https://docs.docker.com/compose/extends/#adding-and-overriding-configuration)中所描述的规则来合并服务

要使用多个`override`文件或不同名称的`override`文件，可以使用`-f`选项来指定文件列表。`compose`**根据在命令行指定的顺序来合并它们**。

当使用多个配置文件时，必须确保文件中所有的路径都是**相对于**`base compose`文件的(`-f` 指定的第一个`compose`文件)。这样要求是因为`override`文件不需要一个有效的`compose`文件。`override`文件可以只包含配置中的一小片段。跟踪一个服务的片段是相对于那个路径的，这是很困难的事，所以一定要保持路径容易理解，所以路径必须定义为相对于base文件的路径。

**例如**，定义两个配置文件：

**docker-compose.yml**

```
web:
  image: example/my_web_app:latest
  links:
    - db
    - cache

db:
  image: postgres:latest

cache:
  image: redis:latest
```

**docker-compose.prod.yml**

```
web:
  ports:
    - 80:80
  environment:
    PRODUCTION: 'true'

cache:
  environment:
    TTL: '500'
```

要使用这个生产compose文件部署，运行如下命令：

```
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

这将会使用`docker-compose.yml`和`docker-compose.prod.yml`来部署这三个服务

## Docker Machine

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/docker-machine-logo.png)

> Docker Machine 是供给和管理 docker 化主机的工具。有自己的命令行客户端 `docker-machine`。提供多种环境的 docker 主机，可以用 Docker Machine 在一个或者多个虚拟系统（本地或者远程）上安装 Docker Engine。

### Install

最新安装请看官方文档：***[https://docs.docker.com/machine/install-machine/](https://docs.docker.com/machine/install-machine/)***

```
base=https://github.com/docker/machine/releases/download/v0.14.0 && \
curl -L $base/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine && \
sudo install /tmp/docker-machine /usr/local/bin/docker-machine
```

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/docker-machine-version.png)

**uninstall**：

```
sudo rm $(which docker-machine)
```

### Zsh命令补全

```
mkdir -p ~/.zsh/completion
curl -L https://raw.githubusercontent.com/docker/machine/master/contrib/completion/zsh/_docker-machine > ~/.zsh/completion/_docker-machine
```

在`~/.zshrc`添加：

**注意**：(如果是`oh-my-zsh`，在`$ZSH/oh-my-zsh.sh`中添加)

```
fpath=(~/.zsh/completion $fpath)
```

执行：

```
autoload -Uz compinit && \
compinit -i && \
exec $SHELL -l
```

### Usage

确保已经安装了`virtualbox`：

```
sudo apt install virtualbox
```

创建本地实例：

使用 `virtualbox` 类型的驱动，创建一台 Docker 主机，命名为 test。

```
docker-machine create -d virtualbox test
```

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/docker-machine-create.png)

你也可以在创建时加上如下参数，来配置主机或者主机上的 Docker。

`--engine-opt dns=114.114.114.114` 配置 Docker 的默认 DNS

`--engine-registry-mirror https://registry.docker-cn.com` 配置 Docker 的仓库镜像

`--engine-insecure-registry` 可以使用http的仓库

`--virtualbox-memory 2048` 配置主机内存

`--virtualbox-cpu-count 2` 配置主机 CPU

更多参数请使用 `docker-machine create --driver virtualbox --help` 命令查看。

```
$ docker-machine create --driver virtualbox --help
Usage: docker-machine create [OPTIONS] [arg...]

Create a machine.

Run 'docker-machine create --driver name' to include the create flags for that driver in the help text.

Options:

   --driver, -d "none"                                                                                  Driver to create machine with.
   --engine-env [--engine-env option --engine-env option]                                               Specify environment variables to set in the engine
   --engine-insecure-registry [--engine-insecure-registry option --engine-insecure-registry option]     Specify insecure registries to allow with the created engine
   --engine-install-url "https://get.docker.com"                                                        Custom URL to use for engine installation [$MACHINE_DOCKER_INSTALL_URL]
   --engine-label [--engine-label option --engine-label option]                                         Specify labels for the created engine
   --engine-opt [--engine-opt option --engine-opt option]                                               Specify arbitrary flags to include with the created engine in the form flag=value
   --engine-registry-mirror [--engine-registry-mirror option --engine-registry-mirror option]           Specify registry mirrors to use [$ENGINE_REGISTRY_MIRROR]
   --engine-storage-driver                                                                              Specify a storage driver to use with the engine
   --swarm                                                                                              Configure Machine with Swarm
   --swarm-addr                                                                                         addr to advertise for Swarm (default: detect and use the machine IP)
   --swarm-discovery                                                                                    Discovery service to use with Swarm
   --swarm-experimental                                                                                 Enable Swarm experimental features
   --swarm-host "tcp://0.0.0.0:3376"                                                                    ip/socket to listen on for Swarm master
   --swarm-image "swarm:latest"                                                                         Specify Docker image to use for Swarm [$MACHINE_SWARM_IMAGE]
   --swarm-master                                                                                       Configure Machine to be a Swarm master
   --swarm-opt [--swarm-opt option --swarm-opt option]                                                  Define arbitrary flags for swarm
   --swarm-strategy "spread"                                                                            Define a default scheduling strategy for Swarm
   --virtualbox-boot2docker-url                                                                         The URL of the boot2docker image. Defaults to the latest available version [$VIRTUALBOX_BOOT2DOCKER_URL]
   --virtualbox-cpu-count "1"                                                                           number of CPUs for the machine (-1 to use the number of CPUs available) [$VIRTUALBOX_CPU_COUNT]
   --virtualbox-disk-size "20000"                                                                       Size of disk for host in MB [$VIRTUALBOX_DISK_SIZE]
   --virtualbox-host-dns-resolver                                                                       Use the host DNS resolver [$VIRTUALBOX_HOST_DNS_RESOLVER]
   --virtualbox-dns-proxy                                                                               Proxy all DNS requests to the host [$VIRTUALBOX_DNS_PROXY]
   --virtualbox-hostonly-cidr "192.168.99.1/24"                                                         Specify the Host Only CIDR [$VIRTUALBOX_HOSTONLY_CIDR]
   --virtualbox-hostonly-nicpromisc "deny"                                                              Specify the Host Only Network Adapter Promiscuous Mode [$VIRTUALBOX_HOSTONLY_NIC_PROMISC]
   --virtualbox-hostonly-nictype "82540EM"                                                              Specify the Host Only Network Adapter Type [$VIRTUALBOX_HOSTONLY_NIC_TYPE]
   --virtualbox-import-boot2docker-vm                                                                   The name of a Boot2Docker VM to import
   --virtualbox-memory "1024"                                                                           Size of memory for host in MB [$VIRTUALBOX_MEMORY_SIZE]
   --virtualbox-no-share                                                                                Disable the mount of your home directory
```

创建好主机之后，查看主机

```
docker-machine ls

NAME      ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER       ERRORS
test      -        virtualbox   Running   tcp://192.168.99.187:2376           v17.10.0-ce
```

创建主机成功后，可以通过 `env` 命令来让后续操作对象都是目标主机。

```
docker-machine env test
```

后续根据提示在命令行输入命令之后就可以操作 test 主机。

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/docker-machine-env.png)

通过以下命令恢复当前环境：

```
docker-machine env -u
```

也可以通过 `SSH` 登录到主机。

```
docker-machine ssh test
```

连接到主机之后你就可以在其上使用 Docker 了。

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/docker-machine-ssh.png)

**操作命令**

- `active` 查看活跃的 Docker 主机
- `config` 输出连接的配置信息
- `create` 创建一个 Docker 主机
- `env` 显示连接到某个主机需要的环境变量
- `inspect` 输出主机更多信息
- `ip` 获取主机地址
- `kill` 停止某个主机
- `ls` 列出所有管理的主机
- `provision` 重新设置一个已存在的主机
- `regenerate-certs` 为某个主机重新生成 TLS 认证信息
- `restart` 重启主机
- `rm` 删除某台主机
- `ssh` SSH 到主机上执行命令
- `scp` 在主机之间复制文件
- `mount` 挂载主机目录到本地
- `start` 启动一个主机
- `status` 查看主机状态
- `stop` 停止一个主机
- `upgrade` 更新主机 Docker 版本为最新
- `url` 获取主机的 URL
- `version` 输出 docker-machine 版本信息
- `help` 输出帮助信息

每个命令，又带有不同的参数，可以通过

```
$ docker-machine COMMAND --help
```

来查看具体的用法。

**注意：**docker-machine 安装的 Docker 在 `/etc/systemd/system` 目录下多出了一个 Docker 相关的目录：`docker.service.d`。这个目录中只有一个文件 `10-machine.conf`，这个配置文件至关重要，因为它会覆盖 Docker 默认安装时的配置文件，从而以 Docker Machine 指定的方式启动 Docker daemon。至此我们有了一个可以被远程访问的 Docker daemon。

### 使用KVM引擎启动

***[https://github.com/dhiltgen/docker-machine-kvm](https://github.com/dhiltgen/docker-machine-kvm)***

首先确保安装了KVM：

```
sudo apt install libvirt-bin qemu-kvm
```

到 ***[Release](https://github.com/dhiltgen/docker-machine-kvm/releases)*** 页面下载相关驱动。

Ubuntu 16.04:

```
sudo curl -L https://github.com/dhiltgen/docker-machine-kvm/releases/download/v0.10.0/docker-machine-driver-kvm-ubuntu16.04 > /usr/local/bin/docker-machine-driver-kvm && sudo chmod +x /usr/local/bin/docker-machine-driver-kvm
```

最后启动：

```
docker-machine create -d kvm --engine-registry-mirror=https://vioqnt8w.mirror.aliyuncs.com  --engine-insecure-registry=192.168.122.213 test01
```

## Swarm Mode

>  Docker 1.12 [Swarm mode](https://docs.docker.com/engine/swarm/) 已经内嵌入 Docker 引擎，成为了 docker 子命令 `docker swarm`。请注意与旧的 `Docker Swarm` 区分开来。
>
>  `Swarm mode` 内置 kv 存储功能，提供了众多的新特性，比如：具有容错能力的去中心化设计、内置服务发现、负载均衡、路由网格、动态伸缩、滚动更新、安全传输等。使得 Docker 原生的 `Swarm` 集群具备与 Mesos、Kubernetes 竞争的实力。

### 功能特点

#### 与Docker Engine集成的集群管理

使用Docker Engine CLI创建一组Docker引擎，您可以在其中部署应用程序服务。您不需要其他编排软件来创建或管理群集。

#### 节点分散式设计

Docker Engine不是在部署时处理节点角色之间的差异，而是在运行时处理角色变化。您可以使用Docker Engine部署两种类型的节点，管理节点和工作节点。这意味着您可以从单个服务器构建整个群集。

#### 声明性服务模型

Docker Engine使用声明性方法来定义应用程序堆栈中各种服务的所需状态。例如，您可以描述由具有消息队列服务和数据库后端的Web前端服务组成的应用程序。

####  可扩容与缩放容器

对于每个服务，您可以声明要运行的任务数。当您向上或向下缩放时，swarm管理器通过添加或删除任务来自动适应，以保持所需的任务数量来保证集群的可靠状态。

#### 容器容错状态协调

群集管理器节点不断监视群集状态，并协调您表示的期望状态的实际状态之间的任何差异。例如，如果设置一个服务以运行容器的10个副本，并且托管其中两个副本的工作程序计算机崩溃，则管理器将创建两个新副本以替换崩溃的副本。 swarm管理器将新副本分配给正在运行和可用的worker节点上。

#### 多主机网络

您可以为服务指定覆盖网络。当swarm管理器初始化或更新应用程序时，它会自动为覆盖网络上的容器分配地址。

#### 服务发现

Swarm管理器节点为swarm中的每个服务分配唯一的DNS名称，并负载平衡运行的容器。您可以通过嵌入在swarm中的DNS服务器查询在群中运行的每个容器。

#### 负载平衡

您可以将服务的端口公开给外部负载平衡器。在内部，swarm允许您指定如何在节点之间分发服务容器。

#### 缺省安全

群中的每个节点强制执行TLS相互验证和加密，以保护其自身与所有其他节点之间的通信。您可以选择使用自签名根证书或来自自定义根CA的证书。

#### 滚动更新

在已经运行期间，您可以增量地应用服务更新到节点。 swarm管理器允许您控制将服务部署到不同节点集之间的延迟。如果出现任何问题，您可以将任务回滚到服务的先前版本。

### 概念

#### 节点

运行 Docker 的主机可以主动初始化一个 `Swarm` 集群或者加入一个已存在的 `Swarm` 集群，这样这个运行 Docker 的主机就成为一个 `Swarm` 集群的节点 (`node`) 。

节点分为管理 (`manager`) 节点和工作 (`worker`) 节点。

管理节点用于 `Swarm` 集群的管理，`docker swarm` 命令基本只能在管理节点执行（节点退出集群命令 `docker swarm leave` 可以在工作节点执行）。一个 `Swarm` 集群可以有多个管理节点，但只有一个管理节点可以成为 `leader`，`leader` 通过 `raft` 协议实现。

工作节点是任务执行节点，管理节点将服务 (`service`) 下发至工作节点执行。管理节点默认也作为工作节点。你也可以通过配置让服务只运行在管理节点。

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/swarm-diagram.png)

#### 服务和任务

任务 （`Task`）是 `Swarm` 中的最小的调度单位，目前来说就是一个单一的容器。

服务 （`Services`） 是指一组任务的集合，服务定义了任务的属性。服务有两种模式：

- `replicated services` 按照一定规则在各个工作节点上运行指定个数的任务。
- `global services` 每个工作节点上运行一个任务

两种模式通过 `docker service create` 的 `--mode` 参数指定。

**下图解释服务、任务、容器：**

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/services-diagram.png)

**服务的任务及调试说明：**

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/docker-swarm-task.png)

**服务部署的复制模式和全局模式说明：**

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/docker-swarm-net.png)

### 创建集群

在创建集群前，如果开启了防火墙，请确认三台主机的防火墙能让swarm需求的端口开放，需要打开主机之间的端口，以下端口必须可用。在某些系统上，这些端口默认为打开。
**2377**：TCP端口2377用于集群管理通信
**7946**：TCP和UDP端口7946用于节点之间的通信
**4789**：TCP和UDP端口4789用于覆盖网络流量
如果您计划使用加密（–opt加密）创建覆盖网络，则还需要确保协议50（ESP）已打开。

docker swarm命令：

```
docker swarm init --advertise-addr 172.18.60.133

#恢复
docker swarm init --advertise-addr 172.18.60.133 --force-new-cluster

#其它节点加入
docker swarm join --token \
     SWMTKN-1-44gjumnutrh4k9lls54f5hp43kiioxf16iuh7qarjfqjsu7jio-2326b8ikb1xiysm3i7neh9nho 172.18.60.133:2377
     
#输出可以用来以worker角色加入的token
docker swarm join-token worker

#输出可以用来以manager角色加入的token
docker swarm join-token manager

#manager节点强制脱离
docker swarm leave --force

#worker节点脱离
docker swarm leave

#节点从swarm中移除
docker node rm XXXXX

#worker节点提升为manager
docker node promote ilog2

#恢复为worker
docker node demote <NODE>

#创建服务
docker service create --replicas 3 --name helloworld alpine ping docker.com
```

### 节点管理

#### 查看集群中的docker信息

```
docker -H 10.0.11.150:2376 info
```

#### 列出节点

```
docker node ls
```

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/docker-node-ls.png)

说明：
**AVAILABILITY列**：
显示调度程序是否可以将任务分配给节点：

- `Active` 意味着调度程序可以将任务分配给节点。
- `Pause` 意味着调度程序不会将新任务分配给节点，但现有任务仍在运行。
- `Drain` 意味着调度程序不会向节点分配新任务。调度程序关闭所有现有任务并在可用节点上调度它们。

**MANAGER STATUS列**
显示节点是属于manager或者worker

- **没有值** 表示不参与群管理的工作节点。
- `Leader` 意味着该节点是使得群的所有群管理和编排决策的主要管理器节点。
- `Reachable` 意味着节点是管理者节点正在参与Raft共识。如果领导节点不可用，则该节点有资格被选为新领导者。
- `Unavailable` 意味着节点是不能与其他管理器通信的管理器。如果管理器节点不可用，您应该将新的管理器节点加入群集，或者将工作器节点升级为管理器。

#### 查看节点的详细信息

您可以在管理器节点上运行`docker node inspect`来查看单个节点的详细信息。 输出默认为JSON格式，但您可以传递`–pretty`标志以以可读的yml格式打印结果

```
# ybd @ ybd-PC in ~ [9:37:23] 
$ docker node inspect --pretty ybd-machine1 
ID:			f917bibevklfp3xjsjoyx2g2t
Hostname:              	ybd-machine1
Joined at:             	2018-01-03 10:00:28.499769713 +0000 utc
Status:
 State:			Ready
 Availability:         	Active
 Address:		192.168.6.113
Platform:
 Operating System:	linux
 Architecture:		x86_64
Resources:
 CPUs:			1
 Memory:		995.9MiB
Plugins:
 Log:		awslogs, fluentd, gcplogs, gelf, journald, json-file, logentries, splunk, syslog
 Network:		bridge, host, macvlan, null, overlay
 Volume:		local
Engine Version:		17.12.0-ce
Engine Labels:
 - provider=virtualbox
TLS Info:
 TrustRoot:
-----BEGIN CERTIFICATE-----
MIIBajCCARCgAwIBAgIUTdhfszkLcL0IC92X4TaOWbQlbZAwCgYIKoZIzj0EAwIw
EzERMA8GA1UEAxMIc3dhcm0tY2EwHhcNMTcxMjIyMDg0NzAwWhcNMzcxMjE3MDg0
NzAwWjATMREwDwYDVQQDEwhzd2FybS1jYTBZMBMGByqGSM49AgEGCCqGSM49AwEH
A0IABEWabJlpAGjNi6x8QWGXnMUFwPe27anM5nHwLX8y05TbgamYvV7Is4CZ1BbU
ypJ/a9FpSp4FbV/6iYveIwwaHLSjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMB
Af8EBTADAQH/MB0GA1UdDgQWBBR1K7f/HuhGDD2gzDeejaH2r8ZxIzAKBggqhkjO
PQQDAgNIADBFAiEApL0o/FwwzLrhalYddR+buFHg0Hg3jKh37t00TmMU7SICIAOz
YZNcngOkQiY2K2poQqRw+dFU9xOk543G+zDHqX4h
-----END CERTIFICATE-----

 Issuer Subject:	MBMxETAPBgNVBAMTCHN3YXJtLWNh
 Issuer Public Key:	MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAERZpsmWkAaM2LrHxBYZecxQXA97btqczmcfAtfzLTlNuBqZi9XsizgJnUFtTKkn9r0WlKngVtX/qJi94jDBoctA==

```

#### 更新节点

Usage:	docker node update [OPTIONS] NODE

Options:
      --availability string   Availability of the node ("active"|"pause"|"drain")
      --label-add list        Add or update a node label (key=value)
      --label-rm list         Remove a node label if exists
      --role string           Role of the node ("worker"|"manager")
#### 升级或降级节点

您可以将工作程序节点提升为manager角色。这在管理器节点不可用或者您希望使管理器脱机以进行维护时很有用。 类似地，您可以将管理器节点降级为worker角色。
无论您升级或降级节点，您应该始终在群中维护**奇数个**管理器节点。
要升级一个节点或一组节点，请从管理器节点运行：

```
docker node promote [NODE]
docker node domote [NODE]
```

#### 退出docker swarm集群

work节点：

```
docker swarm leave
```

manager节点：

```
docker swarm leave -f
```

### 可视化visualizer服务

```
docker service create \
--name=viz \
--publish=8088:8080/tcp \
--constraint=node.role==manager \
--mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
dockersamples/visualizer
```

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/visualizer.png)

### Service用法

```
创建服务
docker service create \
--image nginx \
--replicas 2 \
nginx
 
更新服务
docker service update \
--image nginx:alpine \
nginx
 
删除服务
docker service rm nginx
 
减少服务实例(这比直接删除服务要好)
docker service scale nginx=0
 
增加服务实例
docker service scale nginx=5
 
查看所有服务
docker service ls
 
查看服务的容器状态
docker service ps nginx
 
查看服务的详细信息。
docker service inspect nginx
```

**实现零宕机部署也非常简单。**这样也可以方便地实现持续部署:

```
构建新镜像
docker build -t hub.docker.com/image .
 
将新镜像上传到Docker仓库
docker push hub.docker.com/image
 
更新服务的镜像
docker service update --image hub.docker.com/image service
```

**更新服务要慎重**。 你的容器同时运行在多个主机上。更新服务时，只需要更新Docker镜像。合理的测试和部署流程是保证成功的关键。**Swarm非常容易入门**。分布式系统通常是非常复杂的。与其他容器集群系统(Mesos, Kubernetes)相比，Swarm的学习曲线**最低**。

# Docker Visual Management

## Rancher

[***官方网站***](http://rancher.com/)

如果是对集群管理并且管理员只限制Docker命令权限的话，建议用这个工具，商店用起来都比较方便，

**优点**：界面中文化，操作简单易懂,功能强大,容灾机制。

**缺点**: 不能团队分配权限，容器操作权限太大没法满足需求，部署时相应的Docker 服务也很多，需要逐一去了解容器作用。

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/rancher.png)

## Shipyard

[***官方网站***](https://shipyard-project.com/)

Shipyard是在Docker Swarm的基础上，管理Docker资源，包括容器，镜像，注册表等。

**优点**：

1. 支持镜像管理、容器管理。
2. 支持控制台命令
3. 容器资源消耗监控
4. 支持集群swarm，可以随意增加节点
5. 支持控制用户管理权限，可以设置某个容器对某个用户只读、管理权限。
6. 有汉化版

**缺点** ：

1. 启动容器较多，占用每个节点的一部分资源

部署：

```
curl -sSL https://shipyard-project.com/deploy | bash -s
```

注意：这将在端口2375上暴露Docker Engine。如果此节点可以在安全网络之外访问，建议使用TLS。

支持集群，所以可以添加节点：

```
curl -sSL https://shipyard-project.com/deploy | ACTION=node DISCOVERY=etcd://10.0.0.10:4001 bash -s
```

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/shipyard-download.png)

它会下载并启动7个镜像：

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/shipyard-need-containers.png)

界面：

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/shipyard-containers.png)

容器信息：

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/shipyard-container-info.png)

初体验来说，感觉跟下面的Portainer功能差不多，但是Registry总是添加失败

## Portainer

[***官方网站***](https://portainer.io/)

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/portainer-demo.gif)

`Portainer`是`Docker`的图形化管理工具，提供状态显示面板、应用模板快速部署、容器镜像网络数据卷的基本操作（包括上传下载镜像，创建容器等操作）、事件日志显示、容器控制台操作、`Swarm`集群和服务等集中管理和操作、登录用户管理和控制等功能。功能十分全面，基本能满足中小型单位对容器管理的全部需求。

**优点**

1. 支持容器管理、镜像管理
2. 轻量级，消耗资源少
3. 基于docker api，安全性高，可指定docker api端口，支持TLS证书认证。
4. 支持权限分配
5. 支持集群

**缺点**

1. 功能不够强大。
2. 容器创建后，无法通过后台增加端口。
3. 没有容灾机制

单机启动：

```
docker run -d -p 9000:9000 \
--name portainer \
--restart=always \
-v /var/run/docker.sock:/var/run/docker.sock \
portainer/portainer
```

swarm模式启动：

```
docker service create \
--name portainer \
--publish 9000:9000 \
--constraint 'node.role == manager' \
--mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
--mount type=bind,src=/path/on/host/data,dst=/data \
portainer/portainer \
-H unix:///var/run/docker.sock
```

容器管理：

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/harbor-containers.png)

镜像管理：

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/harbor-images.png)

镜像仓库：

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/harbor-registry.png)

Endpoints：

![](https://cdn.yangbingdong.com/img/docker-visual-management-and-orchestrate-tools/end-point.png)

**注意**：添加Endpoints先要暴露节点的2375端口。

# Finally

> 参考：
>
> ***[Docker — 从入门到实践](https://yeasy.gitbooks.io/docker_practice/content/)***
>
> ***[在生产环境中使用Docker Swarm的一些建议](http://www.jiagoumi.com/virtualization/1464.html)***
>
> ***[使用Docker Harbor搭建私有镜像服务器和Mirror服务器](https://www.jianshu.com/p/8d4fcff97a35)***
>
> ***[远程连接docker daemon，Docker Remote API](https://deepzz.com/post/dockerd-and-docker-remote-api.html)***