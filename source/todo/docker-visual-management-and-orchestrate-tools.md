# Docker Visual Management

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

启动：

```
docker run -d -p 9000:9000 -v /path/on/host/data:/data  \
-v /var/run/docker.sock:/var/run/docker.sock \
portainer/portainer
```

## Rancher

[***官方网站***](http://rancher.com/)

如果是对集群管理并且管理员只限制Docker命令权限的话，建议用这个工具，商店用起来都比较方便，

**优点**：界面中文化，操作简单易懂,功能强大,容灾机制。

**缺点**: 不能团队分配权限，容器操作权限太大没法满足需求，部署时相应的Docker 服务也很多，需要逐一去了解容器作用。

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/rancher.png)

# Cluster and Orchestrate Tools

## Docker Compose

> 官方文档：[***https://docs.docker.com/compose/***](https://docs.docker.com/compose/)
>
> release：[***https://github.com/docker/compose/releases***](https://github.com/docker/compose/releases)

### Install

安装：

```
sudo curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
```

授权命令：

```
sudo chmod +x /usr/local/bin/docker-compose
```

检查成功：

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

进入解压包根目录

修改`harbor.cgf`文件：

````
# 修改hostname
hostname = 192.168.1.102:8888

# 修改登录密码（不修改默认为Harbor12345）
harbor_admin_password = 123456
````



harbor默认监听80端口，我们修改为8888端口，同时`docker-compose.yml`也需要修改`proxy`的端口

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/proxy-port.png)



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

### 踩坑

多次docker login被refuse，修改配置：

```
/etc/default/docker
添加：
DOCKER_OPTS='--insecure-registry 192.168.1.102'
# 注意：192.168.1.102为内网ip

/lib/systemd/system/docker.service
修改为：
EnvironmentFile=/etc/default/docker 
ExecStart=/usr/bin/dockerd -H fd:// --insecure-registry=192.168.1.102
# ExecStart=/usr/bin/dockerd -H fd:// $DOCKER_OPTS
```

重载docker：

```
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### Login and Push

```
docker login 192.168.1.102 -u admin -p Harbor12345

docker tag ubuntu:latest 192.168.1.102/library/ubuntu:latest
docker push 192.168.1.102/library/ubuntu:latest
```

![](http://ojoba1c98.bkt.clouddn.com/img/docker-visual-management-and-orchestrate-tools/harbor-push.png)

# Finally

> 参考：
>
> [***http://www.bleachlei.site/blog/2017/07/20/Docker%E4%B9%8B%E7%AE%A1%E7%90%86%E5%B7%A5%E5%85%B7/***](http://www.bleachlei.site/blog/2017/07/20/Docker%E4%B9%8B%E7%AE%A1%E7%90%86%E5%B7%A5%E5%85%B7/)