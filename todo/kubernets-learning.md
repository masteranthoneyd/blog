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

# MiniKube

> ***[官方文档](https://kubernetes.io/zh/docs/setup/learning-environment/minikube/)***

## 安装minikube

### 安装

请确保安装了VirtualBox、xhyve、VMWARE、KVM、Hyper-V 等（只需要一种即可）。

```
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
chmod +x minikube && \
sudo mv minikube /usr/local/bin/
```

### 命令补全

#### Oh-My-Zsh

如果是使用`Oh-My-Zsh`，在`~/.zshrc`中，找到`source $ZSH/oh-my-zsh.sh`这一行，在这行**下面**添加(否则不生效)：

```
source <(minikube completion zsh)
```

## 启动minikube

> 由于 Kubernetes 是 Google 公司员工开源维护的，所以其所依赖的一些镜像位于 Google 的公有仓库中。 由于一些众所周知的原因，在国内访问基本不可用，所以需要自备梯子（代理服务器）。

拉取基础镜像:

```
docker pull anjone/kicbase

minikube start --vm-driver=docker --base-image="anjone/kicbase" --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers
```

* `--base-image="anjone/kicbase"` 使用我们pull回来的网友缓存的kicbase镜像，这个很关键

* `--image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers` 使用阿里云的镜像，这个也很关键

启动:

```
minikube start \
--docker-env HTTP_PROXY=192.168.0.55:8118 \
--docker-env HTTPS_PROXY=192.168.0.55:8118 \
--docker-env http_proxy=192.168.0.55:8118 \
--docker-env https_proxy=192.168.0.55:8118 \
--base-image="anjone/kicbase" \
--image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers \
--registry-mirror=https://registry.docker-cn.com
```

如果一切顺利，应该就可以运行成功了。

```
minikube status           # 查看 minikube 当前运行状态
minikube docker-env       # 查看 Minikube 的 Docker 相关信息
```

## 使用 Minikube

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

  ![](https://cdn.yangbingdong.com/img/kubernetes-learning/minikube-dashboard.png)


- 配置minikube的Docker环境变量

  如果不进行配置的话，直接使用`docker`命令无法访问到 Minikube 的Docker镜像等。配置方法如下：

  ```
  eval $(minikube docker-env)

  ```

- 查看节点数

  ```
  kubectl get nodes       # 显示本地节点
  ```


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

## 停用以及删除

- 删除已运行的 minikube 实例

  ```
  minikube delete
  ```

- 停止已运行的 minikube 实例

  ```
  minikube stop
  ```

## 无法拉去基础镜像问题

问题:

  ```
Unable to find image 'gcr.io/k8s-minikube/kicbase...
  ```

解决方案:

```
docker pull anjone/kicbase

minikube start --vm-driver=docker --base-image="anjone/kicbase" --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers
```

* `--base-image="anjone/kicbase"` 使用我们pull回来的网友缓存的kicbase镜像，这个很关键

* `--image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers` 使用阿里云的镜像，这个也很关键

# 阿里云 K8S

## 创建集群

### 准备工作

购买一台2核4G的最低配置的CentOS(可选偏远地区有优惠, 比如华北3), 安装 **docker**, 安装 **kubectl**:

  ```
  cat <<EOF > /etc/yum.repos.d/kubernetes.repo
  [kubernetes]
  name=Kubernetes
  baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
  enabled=1
  gpgcheck=1
  repo_gpgcheck=1
  gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
  EOF
  
  yum install -y kubectl
  ```

### 创建集群

在容器服务K8S版中创建集群, 选择**托管版**, **按量付费**, 工作节点可选 ecs.t6-c1m2.large, 最低要求两台. 创建大概需要10分钟.

配置 KubeConfig: 创建完成之后在集群信息中找到**连接信息**, 里面有教程.

配置安全组: 在 ECS 中将两个 Worker 的安全组配置成与准备工作中买的那台一样.

## 镜像服务配置

在**容器镜像服务**中开通, 注意创建的仓库所在**地区**要与K8S配置的一致(华北3), 并且在**访问凭证**中创建密码.

在仓库详情中会有两个地址, 一个公网, 一个内网, **内网需要在同一个地区才能访问**.

## 停止设置

### 停止实例

在 ECS 服务中停止实例时选**停机不收费**的那项即可.

### 停止负载均衡

负载均衡在负载均衡控制台中停止.

### 完全释放资源

实例释放设置前要先取消**实例释放保护**.

## NAS

购买, 按量付费, 注意地区.

挂载前先安装依赖:

```
yum install nfs-utils
```

挂载后查看:

```
df -h | grep aliyun
```

取消挂载:

```
umount /mnt
```

# k8s 常用命令

**查看资源以及资源简写**:

```
kubectl api-resources
```

**应用资源**:

```
kubectl apply -f <RESOURCE_YAML>
```

**删除资源**:

```
kubectl delete -f <RESOURCE_YAML>
```

**资源列表**:

```
kubectl -n <NANESPACE> get <API_RESOURCES>
```

* 需要查看全部命名空间的资源, 将 `-n <NANESPACE>` 换成 `--all-namespaces`.

* 输出更多信息(ip/节点名等)追加参数 `-o wide`
* 输出标签信息追加 参数 `--show-labels`

**输出资源 yaml**:

```
kubectl -n <NANESPACE> get <API_RESOURCES> <RESOURCE_NAME> -o yaml

例如:
kubectl -n kube-system get deploy nginx-ingress-controller -o yaml
```

> 输出 json 格式只需要将 yaml 改成 json 即可

**查看资源详情**:

```
kubectl -n <NANESPACE> describe <API_RESOURCE> <RESOURCE_NAME>
```

**滚动更新相关**:

```
# 查看滚动更新状态
kubectl -n <NANESPACE> rollout status deployment <DEPLOYMENT_NAME>

# 查看历史
kubectl -n <NANESPACE> rollout history deployment <DEPLOYMENT_NAME>

# 回退
kubectl -n <NANESPACE> rollout undo deployment <DEPLOYMENT_NAME>

# 回退到指定版本
kubectl -n <NANESPACE> rollout undo deployment <DEPLOYMENT_NAME> --to-revision=2
```

**弹性伸缩**:

```
kubectl autoscale deployment <DEPLOYMENT_NAME> --cpu-percent=50 --min=1 --max=10
```



# YAML 资源文件

Deloyment:

```
apiVersion: apps/v1  #指定api版本，此值必须在kubectl apiversion中
kind: Deployment  # 资源类型, Deployment/Job/Ingress/Service等
metadata:  # 资源元数据/属性
  name: <DEPLOYMENT_VERSION>  #资源的名字，在同一个namespace中必须唯一   
  labels:  #设定资源的标签
    app: <APP_NAME>
    version: v1.0
  annotations:  #注解列表
    pod.alpha.kubernetes.io/initialized: "true"
spec:  #specification of the resource content 指定该资源的内容
  replicas: 1  # 容器数量
  revisionHistoryLimit: 10  # ReplicaSet 保留数量, 默认为 10, 如果设置为0将导致清空所有历史记录, 将无法回滚
  selector:  # 选择器, 选择哪些容器进行管理
    matchLabels:
      app: <APP_NAME>
      version: v1.0
  minReadySeconds: 3  # 指定新创建的 Pod 在没有任意容器崩溃情况下的最小就绪时间, 默认值为 0(Pod 在准备就绪后立即将被视为可用)
  strategy:  新 Pods 替换旧 Pods 的策略
    type: RollingUpdate  # 可选的还有 Recreate, 默认值是 RollingUpdate 
    rollingUpdate:  # 下面两个配置可填数字或者百分比, 例如1或者25%, 默认值都是25%
      maxSurge: 1  # 升级过程中最多可以比原先设置多出的POD数量, 例如: maxSurage=1, replicas=5, 则表示Kubernetes会先启动1一个新的Pod后才删掉一个旧的POD, 整个升级过程中最多会有5+1个POD
      maxUnavailable: 1  # 升级过程中最多有多少个POD处于无法提供服务的状态
  template:
    metadata:
      labels:
        app: user-center
        version: v1.0
        release: RELEASE-NAME
    spec:
      affinity:  # 亲和性调度
        podAntiAffinity:  # 反亲和性, 一个节点上运行了某个 pod, 那么我们的 pod 则希望被调度到其他节点上去
          requiredDuringSchedulingIgnoredDuringExecution:   # 硬策略, 必须满足, 与之对应是preferredDuringSchedulingIgnoredDuringExecution 
          - labelSelector:  #  标签选择, 下面的意思是如果 pod 中有标签为 app=busybox-pod 的实例, 就不在本节点创建了
              matchExpressions:
              - key: "app"
                operator: In
                values:
                - busybox-pod
            topologyKey: kubernetes.io/hostname
      restartPolicy: Always  #表明该容器一直运行，默认k8s的策略，在此容器退出后，会立即创建一个相同的容器
      nodeSelector:  #节点选择，先给主机打标签kubectl label nodes kube-node1 zone=node1
        zone: node1
      containers:
        - name: <CONTAINER_NAME>  # 容器名称
          image: <IMAGE>  # 镜像
          ports:  # 端口配置
            - name: http
              containerPort: 8080  #容器开发对外的端口
              protocol: TCP  #端口协议，支持TCP和UDP，默认TCP
          imagePullPolicy: Always  # 每次启动时检查和更新（从registery）images的策略, 三个选择Always()/Never/IfNotPresent
          lifecycle:  # 生命周期管理  
            postStart:  # 容器创建后立即执行
              exec:
                command: ["/bin/sh", "-c", "echo Hello from the postStart handler > /usr/share/message"]
            preStop:  # 容器终止之前立即被调用
              exec:
                command: ["/usr/bin/curl","-X","POST", "http://localhost:8081/actuator/shutdown"]
          terminationGracePeriodSeconds: 30  # 优雅终止宽限期, 默认30秒
          livenessProbe:  # pod存活检查, 失败的pod将从k8s中终止并启动新的pod 
            httpGet:  # 通过httpget检查健康, 返回200-399之间, 则认为容器正常
              path: /actuator/health
              port: 8081
              scheme: HTTP
            initialDelaySeconds: 60  #表明第一次检测在容器启动后多长时间后开始, 默认0秒
            timeoutSeconds: 10  #检测的超时时间, 默认1秒
            periodSeconds: 15  #检查间隔时间, 默认10秒
          readinessProbe:  # pod就绪探测, 当pod中所有容器就绪后, 流量才会进来, 否则将从 service 中移除
            httpGet:
              path: /actuator/health
              port: 8081
              scheme: HTTP
            initialDelaySeconds: 60
            timeoutSeconds: 10
            periodSeconds: 15
          resources:  # 资源管理 
            requests:  # 容器运行时, 最低资源需求, 也就是说最少需要多少资源容器才能正常运行
              cpu: 100m  # CPU资源(核数), 两种方式, 浮点数或者是整数+m, 0.1=100m, 最少值为0.001核(1m) 
              memory: 1536Mi  # 内存使用量
            limits: #资源限制   
              cpu: 0.5
              memory: 2000Mi
          env:  #指定容器中的环境变量
          - name: JAVA_OPTS
            value: "-Xmx1g -Xms1g"
          - name: SPRING_PROFILES_ACTIVE
            value: "test"
          - name: SERVER_PORT
            value: "8080"
          - name: MANAGEMENT_SERVER_PORT
            value:  "8081"
          - name: DB_HOST
            valueFrom:  # 从 configMap 中读取变量
              configMapKeyRef:
                name: cm-demo3
                key: db.host
          command: ['sh']  #启动容器的运行命令 将覆盖容器中的Entrypoint, 对应Dockefile中的ENTRYPOINT 
          args:  #启动容器的命令参数，对应Dockerfile中CMD参数
          - --spring.devtools.add-properties=false
          - --management.endpoints.web.exposure.include=*
          - --management.endpoint.shutdown.enabled=true
          - --management.endpoint.configprops.enabled=true
          - --management.endpoint.health.enabled=true
          - --management.endpoint.info.enabled=true
          - --management.endpoint.metrics.enabled=true
          - --spring.cloud.nacos.config.enabled=true
          - --spring.cloud.nacos.server-addr=nacos-headless.infra.svc.cluster.local:8848
          - --spring.cloud.nacos.config.file-extension=yaml
          - --spring.cloud.nacos.config.namespace=test
          volumeMounts:  #挂载持久存储卷
          - name: volume  #挂载设备的名字，与volumes[*].name 需要对应
            mountPath: /etc/config  #挂载到容器的某个路径下
            subPath: special.html  # 指定所引用的卷内的子路径, 而不是其根路径
            readOnly: false  # 是否只读, 默认为 false 
        volumes:  # 定义一组挂载设备
        - name: nginx-pvc
          persistentVolumeClaim:
            claimName: nginx-pvc
        - name: host-volume
          hostPath:
            path: /opt  # 挂载设备类型为hostPath，路径为宿主机下的/opt,这里设备类型支持很多种
            type: DirectoryOrCreate
        - name: configMap-volume
          configMap:  # 类型为configMap的存储卷，挂载预定义的configMap对象到容器内部
            name: nginx-cm
            items:
              - key: a.conf
                path: a.conf
```

Service:

```
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  labels:
    app: nginx
spec:
  ports:
  - port: 88  # 服务暴露的端口
    targetPort: 80  # 容器暴露的端口
  selector:  # 标签选择器 
    app: nginx
```

