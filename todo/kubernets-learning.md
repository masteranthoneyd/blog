# 安装kubectl

## 通过curl（推荐）

1、下载最新release版本

```
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
```

需要下载特殊版本替换上面的`$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)`部分

例如：

```
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kubectl
```

2、使`kubectl`可执行

```
chmod +x ./kubectl
```

3、移动到相应目录

```
sudo mv ./kubectl /usr/local/bin/kubectl
```

## 在Ubuntu通过Snap下载安装

由于在国内，这种方式挺慢的...

1、确保已经安装了`snap`

```
sudo apt update && sudo apt install snapd
```

2、安装`kubectl`

```
sudo snap install kubectl --classic
```

3、检查是否已安装

```
# ybd @ ybd-PC in ~ [13:58:03] C:1
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"9", GitVersion:"v1.9.1", GitCommit:"3a1c9449a956b6026f075fa3134ff92f7d55f812", GitTreeState:"clean", BuildDate:"2018-01-04T11:52:23Z", GoVersion:"go1.9.2", Compiler:"gc", Platform:"linux/amd64"}
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

（由于并未安装k8s，所以会提示`The connection to the server localhost:8080 was refused - did you specify the right host or port?`）

## 命令补全

### Zsh

在`~/.zshrc`添加以下代码：

```
if [ $commands[kubectl] ]; then
  source <(kubectl completion zsh)
fi
```

### Oh-My-Zsh

如果是使用`Oh-My-Zsh`，在`~/.zshrc`中，找到`source $ZSH/oh-my-zsh.sh`这一行，在这行**下面**添加(否则不生效)：

```
source <(kubectl completion zsh)
```

# 安装minikube

## 安装

请确保安装了VirtualBox、xhyve、VMWARE、KVM、Hyper-V 等（只需要一种即可）。

```
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
chmod +x minikube && \
sudo mv minikube /usr/local/bin/
```

## 命令补全

### Oh-My-Zsh

如果是使用`Oh-My-Zsh`，在`~/.zshrc`中，找到`source $ZSH/oh-my-zsh.sh`这一行，在这行**下面**添加(否则不生效)：

```
source <(minikube completion zsh)
```

# 启动minikube

> 由于 Kubernetes 是 Google 公司员工开源维护的，所以其所依赖的一些镜像位于 Google 的公有仓库中。 由于一些众所周知的原因，在国内访问基本不可用，所以需要自备梯子（代理服务器）。

*如果你没有梯子以及类似东西的话，基本无法进一步使用下去，可以弃坑了。*

如果你使用了一个本地代理，其提供了HTTP代理服务，监听地址如：192.168.6.113:8118。你可以这样启动 minikube :

1、查看 VirtualBox 的网关IP地址

```
ifconfig -a
# 输出如下信息
vboxnet0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.99.1  netmask 255.255.255.0  broadcast 192.168.99.255
# 这里即表示 VirtualBox 的网关地址为：192.168.99.1
```

2、启动 minikube (使用代理[文档](https://github.com/kubernetes/minikube/blob/master/docs/http_proxy.md))

```
minikube start \
--docker-env HTTP_PROXY=192.168.6.113:8118 \
--docker-env HTTPS_PROXY=192.168.6.113:8118 \
--docker-env NO_PROXY=192.168.99.0/24 \
--registry-mirror=https://registry.docker-cn.com \
--insecure-registry=192.168.6.113:8888
```

这里还添加了一项`NO_PROXY`是因为 VirtualBox 网络中及你的Docker镜像仓库一般不需要代理。其它不需要代理的地址也可以添加在后面。

3、查看运行状态
如果一切顺利，应该就可以运行成功了。

```
minikube status           # 查看 minikube 当前运行状态
minikube docker-env       # 查看 Minikube 的 Docker 相关信息
```

# 使用 Minikube

当安装完成后，可以通过`kubectl`按正常使用 Kubernetes 的方式来使用 Minikube 管理运行容器。 这里列出一些简单的操作，具体详细的使用，请参看官网。

* 查看minikube是否正常启动

  ```
  kubectl get pod --all-namespaces

  NAMESPACE     NAME                          READY     STATUS    RESTARTS   AGE
  kube-system   kube-addon-manager-minikube   1/1       Running   0          3m
  kube-system   kube-dns-86f6f55dd5-bdfnn     3/3       Running   0          2m
  kube-system   kubernetes-dashboard-c7sc6    1/1       Running   0          2m
  kube-system   storage-provisioner           1/1       Running   0          2m
  ```

- 打开dashboard

  ```
  minikube dashboard
  ```

  ![](http://ojoba1c98.bkt.clouddn.com/img/kubernetes-learning/minikube-dashboard.png)


- 配置minikube的Docker环境变量

  如果不进行配置的话，直接使用`docker`命令无法访问到 Minikube 的Docker镜像等。配置方法如下：

  ```
  eval $(minikube docker-env)

  ```

- 查看节点数

  ```
  kubectl get nodes       # 显示本地节点

  ```

- 查看当前运行所有的资源

  ```
  kubectl get all               # 展示所有资源，包括 Pod, Service, Deployment, RS 等。

  kubectl get all -o wide       # 展示更多的信息，包括镜像地址等

  ```

- 运行Nginx

  ```
  # 运行一个nginx的pod，然后
  # 导出运行的nginx服务

  kubectl run hello --image=nginx --port=80
  kubectl expose deployment hello --type=NodePort
  ```

# 停用以及删除

- 删除已运行的 minikube 实例

  ```
  minikube delete
  ```

- 停止已运行的 minikube 实例

  ```
  minikube stop
  ```