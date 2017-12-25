# Docker Registry

## Harbor

Harbor是一个用于存储和分发Docker镜像的企业级Registry服务器，通过添加一些企业必需的功能特性，例如安全、标识和管理等，扩展了开源Docker Distribution。作为一个企业级私有Registry服务器，Harbor提供了更好的性能和安全。提升用户使用Registry构建和运行环境传输镜像的效率。Harbor支持安装在多个Registry节点的镜像资源复制，镜像全部保存在私有Registry中， 确保数据和知识产权在公司内部网络中管控。另外，Harbor也提供了高级的安全特性，诸如用户管理，访问控制和活动审计等。

- **基于角色的访问控制** - 用户与Docker镜像仓库通过“项目”进行组织管理，一个用户可以对多个镜像仓库在同一命名空间（project）里有不同的权限。
- **镜像复制** - 镜像可以在多个Registry实例中复制（同步）。尤其适合于负载均衡，高可用，混合云和多云的场景。
- **图形化用户界面** - 用户可以通过浏览器来浏览，检索当前Docker镜像仓库，管理项目和命名空间。
- **AD/LDAP 支持** - Harbor可以集成企业内部已有的AD/LDAP，用于鉴权认证管理。
- **审计管理** - 所有针对镜像仓库的操作都可以被记录追溯，用于审计管理。
- **国际化** - 已拥有英文、中文、德文、日文和俄文的本地化版本。更多的语言将会添加进来。
- **RESTful API** - RESTful API 提供给管理员对于Harbor更多的操控, 使得与其它管理软件集成变得更容易。
- **部署简单** - 提供在线和离线两种安装工具， 也可以安装到vSphere平台(OVA方式)虚拟设备。

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

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/proxy-port.png)

还可以修改仓库的存储位置：

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/harbor-registry-data.png)

### Install

运行安装脚本：

```
./install.sh
```

脚本会自动解压镜像文件并运行docker-compose

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/harbor-install.png)

或者运行`prepare`文件再手动运行docker-compose

启动之后浏览器打开刚才修改的hostname

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/harbor-dashboard.png)

**帐号密码默认是** `admin/Harbor12345`，可在配置文件`harbor.conf`中修改

### 踩坑

多次docker login被refuse

首先修改`/etc/default/docker`

```
DOCKER_OPTS="--insecure-registry 192.168.1.102:8888"
```

修改`/lib/systemd/system/docker.service`：

```
# 找到ExecStart=/usr/bin/dockerd -H fd:// 
# 前面添加EnvironmentFile=-/etc/default/docker，后面追加$DOCKER_OPTS8

EnvironmentFile=-/etc/default/docker
ExecStart=/usr/bin/dockerd -H fd:// $DOCKER_OPTS8
```

重启docker：

```
sudo systemctl daemon-reload && sudo systemctl restart docker
```

**centos下是这样的**：

修改`/etc/sysconfig/docker`：

```
# OPTIONS='--selinux-enabled --log-driver=journald --signature-verification=false  -H'后面追加 --insecure-registry 10.0.11.150:5000

OPTIONS='--selinux-enabled --log-driver=journald --signature-verification=false  -H --insecure-registry 10.0.11.150:5000'
```

重启：

```
sudo systemctl restart docker
```

### Login and Push

```
docker login 192.168.1.102:8888 -u admin -p Harbor12345

docker tag ubuntu:latest 192.168.1.102/library/ubuntu:latest
docker push 192.168.1.102/library/ubuntu:latest
```

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/harbor-push.png)



# Cluster and Orchestrate Tools

## Docker Compose

> 官方文档：[***https://docs.docker.com/compose/*
>
> release：[***https://github.com/docker/compose/releases*

### Install

在[release](https://github.com/docker/compose/releases)页面找到最新版安装，ex：

```
sudo curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
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

**Zsh命令补全**：

```
mkdir -p ~/.zsh/completion
curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/zsh/_docker-compose > ~/.zsh/completion/_docker-compose
```

在`.zshrc`添加：

```
fpath=(~/.zsh/completion $fpath)
```

执行：

```
autoload -Uz compinit && compinit -i
```

`.zshrc`添加：

```
plugins+=(docker-compose)
```

重载：

```
exec $SHELL -l
source ~/.zshrc
```

## Swarm

>  Swarm是一套较为简单的工具，用以管理Docker集群，使得Docker集群暴露给用户时相当于一个虚拟的整体。Swarm使用标准的Docker API接口作为其前端访问入口，换言之，各种形式的Docker Client(dockerclient in go, docker_py, docker等)均可以直接与Swarm通信。

下面是swarm的一个架构图：

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/swarmarchitecture.jpg)



### 端口监听

`Swarm`是通过监听`2375`端口进行通信的，所以在使用`Swarm`进行集群管理之前，需要设置一下`2375`端口的监听。这里有两种方法，一种是通过修改docker配置文件方式，另一种是通过一个轻量级的代理容器进行监听。

**方式一，修改配置文件**：

`/etc/default/docker`中的`DOCKER_OPTS`追加配置：

```
-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
```

**方式二，添加代理**：

```
docker run -ti -d -p 2375:2375 \
--restart=always \
--hostname=$HOSTNAME \
--name shipyard-proxy \
-v /var/run/docker.sock:/var/run/docker.sock \
-e PORT=2375 \
shipyard/docker-proxy
```

### 创建集群

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

### 查看节点信息

**查看集群中的docker信息**：

```
docker -H 10.0.11.150:2376 info
```

**列出节点**：

```
docker node ls
```

### 可视化visualizer服务

```
docker service create \
--name=visualizer \
--publish 8088:8080 \
--constraint=node.role==manager \
--mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
manomarks/visualizer
```

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/visualizer.png)

# Docker Visual Management

## Rancher

[***官方网站***](http://rancher.com/)

如果是对集群管理并且管理员只限制Docker命令权限的话，建议用这个工具，商店用起来都比较方便，

**优点**：界面中文化，操作简单易懂,功能强大,容灾机制。

**缺点**: 不能团队分配权限，容器操作权限太大没法满足需求，部署时相应的Docker 服务也很多，需要逐一去了解容器作用。

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/rancher.png)

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

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/shipyard-download.png)

它会下载并启动7个镜像：

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/shipyard-need-containers.png)

界面：

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/shipyard-containers.png)

容器信息：

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/shipyard-container-info.png)

初体验来说，感觉跟下面的Portainer功能差不多，但是Registry总是添加失败

## Portainer

[***官方网站***](https://portainer.io/)

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/portainer-demo.gif)

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
--restart=always
-v /path/on/host/data:/data  \
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

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/harbor-containers.png)

镜像管理：

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/harbor-images.png)

镜像仓库：

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/harbor-registry.png)

# Finally

> 参考：
>
> [***http://www.bleachlei.site/blog/2017/07/20/Docker%E4%B9%8B%E7%AE%A1%E7%90%86%E5%B7%A5%E5%85%B7/***](http://www.bleachlei.site/blog/2017/07/20/Docker%E4%B9%8B%E7%AE%A1%E7%90%86%E5%B7%A5%E5%85%B7/)