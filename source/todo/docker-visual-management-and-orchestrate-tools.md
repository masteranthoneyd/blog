# Docker Visual Management

## Portainer

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



# Cluster and Orchestrate Tools

## Docker Compose

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