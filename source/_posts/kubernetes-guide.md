---
title: Kuberbetes 常用概念及操作
date: 2020-07-29 14:54:13
categories: [Docker]
tags: [Docker, Kubernetes, K8S]
---



![](https://cdn.yangbingdong.com/img/k8s-learning/kubernetes-learning-banner.png)

# Preface

> K8S(Kubernetes) 现在来说也不是什么新鲜的词了, 或许小公司玩得比较少, 自己也一直没有实操的机会. 幸会近来公司也开始使用 K8S, 有机会将学习过的东西在生产上实践一遍.

<!--more-->

# Kubernetes 常用资源

通过 `kubectl api-resources` 命令可以列举出所有的资源并且可以看到它们的简写.

常用的资源有:

* `Pod`(po): 最小的调度单位, 一般一个 `Pod` 对应一个或两个(**Sidecar 模式**) Container. 一般不直接管理, 而是通过下面的 `Deployment` 管理.
* `ReplicationController`(rc) / `ReplicationSet`(rs): 用来部署, 升级 Pod.
* `Deployment`(deploy): 可以看做升级版的 RC, 在 RC 级基础上增加了事件和状态查看, 回滚, 版本记录, 暂停和启动等功能.
* `DaemonSet`(ds): `DaemonSet` 会在每个 Kubernetes 节点都启动一个 `Pod`, 可以理解为节点的守护进程, 适用于日志收集, 监控 Agent 等. 
* `StatefulSet`(sts): `StatefulSet` 表示有状态的服务, Pod 的名称的形式为`<statefulset name>-<ordinal index>`, 可参考 Nacos 的部署.
* `Service`(svc): 提供一组 `Pod` 的访问, 服务间的访问一般就是通过 `Service` 来实现的, 类型有4种
  * `ClusterIP`(默认): 仅仅使用一个集群内部的地址, 这也是默认值, 使用该类型, 意味着, Service 只能在集群内部被访问. `clusterIP` 参数设置为 `None` 就是一个 Headless Service 了.
  * `NodePort`: 在集群内部的每个节点上, 都开放这个服务. 可以在任意的 NodePort 地址上访问到这个服务
  * `LoadBalancer`: 这是当 Kubernetes 部署到公有云上时才会使用到的选项, 是向云提供商申请一个负载均衡器, 将流量转发到已经以 NodePort 形式开放的 Service 上. 
  * `ExternalName`: `ExternalName`实际上是将 Service 导向一个外部的服务, 这个外部的服务有自己的域名, 只是在 Kubernetes 内部为其创建一个内部域名, 并 cname 至这个外部的域名. 
* `Ingress`(ing): 对集群中服务的外部访问进行管理, 典型的访问方式是 HTTP, 可以提供负载均衡, SSL 终结和基于名称的虚拟托管.
* `ConfigMap`(cm) / `Secret`: 配置存储, 后者提供加密功能.
* `Job` / `CronJob`(cj): 任务, 前者为执行一次, 后者加上了时间调度.
* `PersistentVolume`(pv) / `PersistentVolumeClaim`(pvc): pv 是对共享存储的一种抽象, pvc 则是对 pv 的一种消耗.
* `StrorgeClass`(sc): 动态创建 pv.
* `HorizontalPodAutoscaler`(hpa): 自动横向扩容.
* `Endpoints`: 配合 `Service -> NodePort` 可用于映射外部服务.
* `ServiceAccount`(sa) / `ClusterRole` / `ClusterRoleBinding`: RBAC 权限相关资源

# 服务发现

Service 默认生成 ClusterIP(VIP) 来访问 Pod, 实际应用中通过写死 ClusterIP 显然不科学, 所以 Kubernetes 提供了 DNS 服务插件, 使得我们可以通过 Service Name 来发现 ClusterIP.

域名格式:

- 普通的 Service: 会生成 `serviceName.namespace.svc.cluster.local` 的域名, 会解析到 Service 对应的 ClusterIP 上, 在 Pod 之间的调用可以简写成 `serviceName.namespace`, 如果处于同一个命名空间下面, 甚至可以只写成 `serviceName` 即可访问.
- **Headless Service**: 无头服务, 就是把 ClusterIP 设置为 None 的, 会被解析为指定 Pod 的 IP 列表, 同样还可以通过 `podname.servicename.namespace.svc.cluster.local` 访问到具体的某一个 Pod.

# 服务映射

## 外部服务映射到内部

如果外部服务是个域名, 可以直接通过 `Service -> ExternalName` 实现:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  externalName: mysql.example.com
  type: ExternalName
```

如果是 IP, 推荐使用 EndPoint:

```yaml
apiVersion: v1
kind: Service
metadata:
 name: mysql
spec:
 type: ClusterIP
 ports:
 - port: 3306
   targetPort: 3307
---
apiVersion: v1
kind: Endpoints
metadata:
 name: mysql
subsets:
 - addresses:
     - ip: 192.168.1.10
   ports:
     - port: 3307
```

> **Service 不需要指定 selector**

## 暴露服务

暴露服务有多种方式: `NodePort`, `Ingress`, `LoadBalance`, `port-forward` 等, 这里介绍前两种

### NodePort 方式

NodePort 顾名思义, 就是占用了节点端口暴露内部服务, 优点就是少量服务时配置简单. 缺点也很明显, 大量服务时端口不好管理, 而且节点可能也没有那么多端口使用.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
  namespace: test
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 32180 
  selector:
    app: nginx-pod
```

> `port` 指服务端口, `targetPort` 指 Pod 端口, `nodePort` 节点端口.

### Ingress

推荐使用这种方式暴露服务, Ingress 其实就是从 kuberenets 集群外部访问集群的一个入口, 将外部的请求转发到集群内不同的 Service 上, 跟 Nginx 反向代理类似.

使用 Ingress 前需要部署 Ingress Controller, 实现有 *[Ingress NGINX](https://github.com/kubernetes/ingress-nginx)* / *[F5 BIG-IP Controller](https://clouddocs.f5.com/products/connectors/k8s-bigip-ctlr/v1.5/)* / *[Ingress Kong](https://konghq.com/blog/kubernetes-ingress-controller-for-kong/)* / *[Traefik](https://github.com/containous/traefik)* / *[Voyager](https://github.com/appscode/voyager)* 等, 部署过程省略... 部署了 Ingress Controller 后, 就可以开始使用 Ingress 了:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
  name: nginx-ingress
  namespace: test
spec:
  rules:
    - host: a.yangbingdong.com
      http:
        paths:
          - backend:
              serviceName: nginx
              servicePort: 80
            path: /
    - host: b.yangbingdong.com
      http:
        paths:
          - backend:
              serviceName: nginx
              servicePort: 80
            path: /
```

# 调度选择

> 更多参考官方文档: ***[https://kubernetes.io/zh/docs/concepts/scheduling-eviction/](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/)***

## nodeSelector

将 Pod 部署到 label 中包含 `{KEY}={VALUE}` 的 node, 如果不满足, 则 Pod 会一直处于 Pending 状态.

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: busybox-pod
  name: test
spec:
  containers:
  - command:
    - sleep
    - "3600"
    image: busybox
    imagePullPolicy: Always
    name: test-busybox
  nodeSelector:
    kubernetes.io/hostname: node-a
```

## 亲和性和反亲和性调度

亲和性和反亲和性调度都有硬策略以及软策略.

> 软策略和硬策略的区分是有用处的, 硬策略适用于 pod 必须运行在某种节点, 否则会出现问题的情况, 比如集群中节点的架构不同, 而运行的服务必须依赖某种架构提供的功能; 软策略不同, 它适用于满不满足条件都能工作, 但是满足条件更好的情况, 比如服务最好运行在某个区域, 减少网络传输等. 这种区分是用户的具体需求决定的, 并没有绝对的技术依赖. 

### Node Affinity

硬策略:

* `requiredDuringSchedulingIgnoredDuringExecution`
* `requiredDuringSchedulingRequiredDuringExecution`

软策略:

* `preferredDuringSchedulingIgnoredDuringExecution`
* `preferredDuringSchedulingRequiredDuringExecution`

其中 `IgnoredDuringExecution` 表示如果节点标签发生了变化, 不再满足pod指定的条件, pod也会继续运行, 而 `RequiredDuringExecution` 表示如果节点标签发生了变化, 不再满足pod指定的条件, 则重新选择符合要求的节点.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: with-node-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/e2e-az-name
            operator: In
            values:
            - e2e-az1
            - e2e-az2
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: another-node-label-key
            operator: In
            values:
            - another-node-label-value
  containers:
  - name: with-node-affinity
    image: k8s.gcr.io/pause:2.0
```

### Pod Affinity

与上面的 Node Affinity 类似, 只不过选择 pod 的纬度是 pod 之间的关系. 比如需要将3个 Nacos 实例部署到3个不同的节点, 也就是节点中有一个 Nacos pod, 就不分配到这个节点了.

和 node affinity 相似, pod affinity 也有 `requiredDuringSchedulingIgnoredDuringExecution` 和 `preferredDuringSchedulingIgnoredDuringExecution`.

亲和性调度:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-affinity
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: security
            operator: In
            values:
            - S1
        topologyKey: kubernetes.io/hostname
  containers:
  - name: with-pod-affinity
    image: gcr.io/google_containers/pause:2.0
```

反亲和性调度:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: with-pod-affinity
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: security
            operator: In
            values:
            - S1
        topologyKey: "failure-domain.beta.kubernetes.io/zone"
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: security
              operator: In
              values:
              - S2
          topologyKey: kubernetes.io/hostname
  containers:
  - name: with-pod-affinity
    image: gcr.io/google_containers/pause:2.0
```

## 污点和容忍(Taints和Tolerations)

与 NodeAffinity 相反, Taint 让 Node 拒绝 Pod 的运行. Taint 需要与 Toleration 配合使用, 让 Pod 避开那些不合适的 Node.

想设置标签一样, 需要先设置 taint:

```
kubectl taint node [node] key=value[effect]
其中[effect] 可取值:  [ NoSchedule | PreferNoSchedule | NoExecute ]
NoSchedule : 一定不能被调度
PreferNoSchedule: 尽量不要调度
NoExecute: 不仅不会调度, 还会驱逐Node上已有的Pod

ex:
kubectl taint node 10.3.1.16 test=16:NoSchedule
```

在 Node上设置一个或多个 Taint 后, 除非 Pod 明确声明能够容忍这些"污点", 否则无法在这些 Node 上运行.

Toleration 设置为可以容忍具有该 Taint 的 Node, 使得 Pod 能够被调度到 node1 上: 

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-taints
spec:
  tolerations:
  - key: "key"
    operator: "Equal"
    value: "value"
    effect: "NoSchedule"
  containers:
    - name: pod-taints
      image: busybox:latest
```

> 更多参考这里: ***[https://www.cnblogs.com/breezey/p/9101677.html](https://www.cnblogs.com/breezey/p/9101677.html)***

# ConfigMap & Secret

通常一个应用多多少少都会有一些配置, 而对于不同环境的配置是不一样的, 这时候就需要将配置与应用隔离.

Kubernetes 提供了 ConfigMap 以及 Secret 这样的方案提供给我们. Secret 相当于加密版的 ConfigMap, 存储的是 Base64 编码后的值.

## 创建

推荐使用 yaml 文件创建 ConfigMap:

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: cm-demo
  namespace: default
data:
  data.1: hello
  data.2: world
  config: |
    property.1=value-1
    property.2=value-2
    property.3=value-3
```

Secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  username: YWRtaW4=
  password: YWRtaW4zMjE=
```

> username 与 password 是经过 Base64 处理后的字符串

## 使用

通过环境变量方式:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: testcm1-pod
spec:
  containers:
    - name: testcm1
      image: busybox
      command: [ "/bin/sh", "-c", "echo $(DB_HOST) $(DB_PORT)" ]
      env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: cm-demo3
              key: db.host
        - name: DB_PORT
          valueFrom:
            configMapKeyRef:
              name: cm-demo3
              key: db.port
      envFrom:
        - configMapRef:
            name: cm-demo1
```

通过挂载方式(ConfigMap 中的 key 为文件名, value 为文件内容):

```yaml
apiVersion: v1
data:
  redis.conf: |
    host=127.0.0.1
    port=6379
kind: ConfigMap
metadata:
  name: cm-demo2
  namespace: default
---
apiVersion: v1
kind: Pod
metadata:
  name: testcm3-pod
spec:
  containers:
    - name: testcm3
      image: busybox
      command: [ "/bin/sh", "-c", "cat /etc/config/redis.conf" ]
      volumeMounts:
      - name: config-volume
        mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: cm-demo2
```

也可以指定挂载某一个 key:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: testcm3-pod
spec:
  containers:
    - name: testcm3
      image: busybox
      command: [ "/bin/sh", "-c", "cat /etc/config/path/to/redis.conf" ]
      volumeMounts:
      - name: config-volume
        mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: cm-demo2
        items:
        - key: redis.conf
          path: path/to/redis.conf
```

Secret 用法类似, 只需要将 `configMapKeyRef` 替换成 `secretKeyRef`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret1-pod
spec:
  containers:
  - name: secret1
    image: busybox
    command: [ "/bin/sh", "-c", "env" ]
    env:
    - name: USERNAME
      valueFrom:
        secretKeyRef:
          name: mysecret
          key: username
    - name: PASSWORD
      valueFrom:
        secretKeyRef:
          name: mysecret
          key: password
```

## 差异与注意点

相同点: 

- key/value 的形式
- 属于某个特定的 namespace
- 可以导出到环境变量
- 可以通过目录/文件形式挂载
- 通过 volume 挂载的配置信息均可热更新

不同点: 

- Secret 可以被 ServerAccount 关联
- Secret 可以存储 docker register 的鉴权信息, 用在 ImagePullSecret 参数中, 用于拉取私有仓库的镜像
- Secret 支持 Base64 加密
- Secret 分为 `kubernetes.io/service-account-token`, `kubernetes.io/dockerconfigjson`, `Opaque` 三种类型而 Configmap 不区分类型

ConfigMap需要注意:

* ConfigMap 必须在 Pod 之前创建
* 只有与当前 ConfigMap 在同一个 namespace 内的 pod 才能使用这个 ConfigMap, 换句话说, ConfigMap 不能跨命名空间调用

# 数据挂载

Kubernetes 提供了众多 Volume 类型, 包括 `emptyDir` / `hostPath` / `nfs` / `glusterfs` / `cephfs` / `ceph rbd` 等。具体可以参考[***官方文档***](https://kubernetes.io/docs/concepts/storage/volumes/), 这里列举常用的几种.

## emptyDir

这是一个临时文件夹, Pod 销毁就删除:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - image: test-webserver
    name: test-container
    volumeMounts:
    - name: cache-volume
      mountPath: /cache
  volumes:
  - name: cache-volume
    emptyDir: {}
```

## hostPath

在 Pod 运行节点创建的文件夹, 缺点是, Pod 是动态的, 而 `hostPath` 是静态的(跟着 node 走):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - image: test-webserver
    name: test-container
    volumeMounts:
    - name: test-volume
      mountPath: /www
  volumes:
  - name: test-volume
    hostPath:
      path: /data
```

## PV & PVC

PV: 是对共享存储资源的一种抽象, 实现方式常见的有 `Ceph`, `GlusterFS`, `NFS` 等.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name:  pv1
  labels:
    app: nfs
spec:
  capacity: 
    storage: 1Gi # 存储空间设置
  accessModes: # 访问模式, 其他还有 ReadOnlyMany(只读权限, 可以被多个节点挂载), ReadWriteMany(读写权限, 可以被多个节点挂载)
  - ReadWriteOnce # 读写权限, 但是只能被单个节点挂载
  persistentVolumeReclaimPolicy: Recycle # 回收策略, Retain(保留, 需要人工删除), Recycle(回收), Delete
  nfs:
    path: /data/k8s
    server: 10.151.30.57
```

PVC: 则是用户存储的一种消耗 PV 的声明, 用户不需要关心具体的存储实现, 只需要直接使用 PVC 就行.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc1
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  selector:
    matchLabels:
      app: nfs
```

## StorageClass

`StorageClass` 可以自动帮我们创建 PV, 我们只需要声明 PVC. 创建的 PV 以 `${namespace}-${pvcName}-${pvName}` 的形式存在 NFS 的共享目录中.

要使用 `StorageClass`, 我们需要先创建自动配置程序, 又叫 `Provisioner`, 怎么创建可以参考 ***[https://github.com/kubernetes-retired/external-storage/tree/master/nfs-client](https://github.com/kubernetes-retired/external-storage/tree/master/nfs-client)***.

创建 `StorageClass`:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  namespace: test
  name: course-nfs-storage
provisioner: fuseim.pri/ifs  # 对应 Provisioner 中的 PROVISIONER_NAME 参数
```

使用 `StorageClass`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  annotations:
    volume.beta.kubernetes.io/storage-class: "course-nfs-storage" # 对应上面声明的 name
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
```

或者通过 Pod PVC 模板自动创建 PVC:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nfs-web
spec:
  serviceName: "nginx"
  replicas: 3
  selector:
    matchLabels:
      app: nfs-web
  template:
    metadata:
      labels:
        app: nfs-web
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
      annotations:
        volume.beta.kubernetes.io/storage-class: course-nfs-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

# Kubernetes 常用命令

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

* 需要查看全部命名空间的资源, 将 `-n <NANESPACE>` 换成最后追加 `--all-namespaces`.

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

# YAML 声明示例

## Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: <APP_NAME>
  labels: # 标签
    app: <APP_NAME>
  annotations: # 注解
    armsPilotAutoEnable: "on"
    armsPilotCreateAppName: <APP_NAME>
spec:
  affinity: # 亲和性调度
    podAntiAffinity: # 反亲和性, 一个节点上运行了某个 pod, 那么我们的 pod 则希望被调度到其他节点上去
      requiredDuringSchedulingIgnoredDuringExecution: # 硬策略, 必须满足, 与之对应是preferredDuringSchedulingIgnoredDuringExecution
        - labelSelector: #  标签选择, 下面的意思是如果 pod 中有标签为 app=busybox-pod 的实例, 就不在本节点创建了
            matchExpressions:
              - key: "app"
                operator: In
                values:
                  - busybox-pod
          topologyKey: kubernetes.io/hostname
  tolerations: # 容忍度
    - key: "key"
      operator: "Equal"
      value: "value"
      effect: "NoSchedule"
  restartPolicy: Always  #表明该容器一直运行, 默认k8s的策略, 在此容器退出后, 会立即创建一个相同的容器
  nodeSelector: #节点选择, 先给主机打标签kubectl label nodes kube-node1 zone=node1
    zone: node1
    kubernetes.io/hostname: dev-a
  terminationGracePeriodSeconds: 30  # 优雅终止宽限期, 默认30秒
  initContainers: # 初始化容器, 执行完初始化容器才会启动下面的 containers
    - name: init-myservice
      image: busybox
      command: [ 'sh', '-c', 'until nslookup myservice; do echo waiting for myservice; sleep 2; done;' ]
  containers:
    - name: <APP_NAME>  # 容器名称
      image: <IMAGE>  # 镜像
      imagePullPolicy: Always  # 每次启动时检查和更新（从registery）images的策略, 三个选择Always()/Never/IfNotPresent
      ports: # 端口配置
        - name: http # 端口配置名称, 在 Service -> target port 可以指定端口或者使用该名称
          containerPort: 8080  #容器开发对外的端口
          protocol: TCP  #端口协议, 支持TCP和UDP, 默认TCP
      lifecycle: # 生命周期管理
        postStart: # 容器创建后立即执行
          exec:
            command: [ "/bin/sh", "-c", "echo Hello from the postStart handler > /usr/share/message" ]
        preStop: # 容器终止之前立即被调用
          exec:
            command: [ "/usr/bin/curl","-X","POST", "http://localhost:8081/actuator/shutdown" ]
      livenessProbe: # pod存活检查, 失败的pod将从k8s中终止并启动新的pod
        httpGet: # 通过httpget检查健康, 返回200-399之间, 则认为容器正常
          path: /actuator/health
          port: 8081
          scheme: HTTP
        initialDelaySeconds: 60  #表明第一次检测在容器启动后多长时间后开始, 默认0秒
        timeoutSeconds: 10  #检测的超时时间, 默认1秒
        periodSeconds: 15  #检查间隔时间, 默认10秒
      readinessProbe: # pod就绪探测, 当pod中所有容器就绪后, 流量才会进来, 否则将从 service 中移除
        httpGet:
          path: /actuator/health
          port: 8081
          scheme: HTTP
        initialDelaySeconds: 60
        timeoutSeconds: 10
        periodSeconds: 15
      resources: # 资源限制管理
        requests: # 容器运行时, 最低资源需求, 也就是说最少需要多少资源容器才能正常运行
          cpu: 100m  # CPU资源(核数), 两种方式, 浮点数或者是整数+m, 0.1=100m, 最少值为0.001核(1m)
          memory: 1536Mi  # 内存使用量
        limits: #资源限制
          cpu: 100m
          memory: 2000Mi
      env: #指定容器中的环境变量
        - name: JAVA_OPTS
          value: "-Xmx1g -Xms1g"
        - name: SPRING_PROFILES_ACTIVE
          value: "test"
        - name: SERVER_PORT
          value: "8080"
        - name: MANAGEMENT_SERVER_PORT
          value: "8081"
        - name: DB_HOST
          valueFrom: # 从 configMap 中读取变量
            configMapKeyRef:
              name: cm-demo3
              key: db.host
      command: [ 'sh' ]  #启动容器的运行命令 将覆盖容器中的Entrypoint, 对应Dockefile中的ENTRYPOINT
      args: #启动容器的命令参数, 对应Dockerfile中CMD参数
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
      volumeMounts: #挂载持久存储卷
        - name: volume  #挂载设备的名字, 与volumes[*].name 需要对应
          mountPath: /etc/config  #挂载到容器的某个路径下
          subPath: special.html  # 指定所引用的卷内的子路径, 而不是其根路径
          readOnly: false  # 是否只读, 默认为 false
  volumes: # 定义一组挂载设备
    - name: nginx-pvc
      persistentVolumeClaim:
        claimName: nginx-pvc
    - name: host-volume
      hostPath:
        path: /opt  # 挂载设备类型为hostPath, 路径为宿主机下的/opt,这里设备类型支持很多种
        type: DirectoryOrCreate
    - name: configMap-volume
      configMap: # 类型为configMap的存储卷, 挂载预定义的configMap对象到容器内部
        name: nginx-cm
        items:
          - key: a.conf
            path: a.conf
```

## Deloyment

```yaml
apiVersion: apps/v1  #指定api版本, 此值必须在kubectl apiversion中
kind: Deployment  # 资源类型, Deployment/Job/Ingress/Service等
metadata:  # 资源元数据/属性
  name: <DEPLOYMENT_VERSION>  #资源的名字, 在同一个namespace中必须唯一   
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
        app: <APP_NAME>
    spec: # 下面配置参考 Pod
      ...
      containers:
      ...
```

## Service

```yaml
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

## HPA

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache
  namespace: default
spec:
  maxReplicas: 10  # 最大扩容数
  minReplicas: 4  # 最小扩容数
  scaleTargetRef:
    kind: Deployment
    name: nginx-demo
  targetCPUUtilizationPercentage: 90  # 目标 Pod 所有副本自身的 CPU 利用率的平均值超过90%后触发扩容
```

## Daemonset

`template` 语法与 `Deployment` 类似, 不同在于滚动升级策略, `.spec.updateStrategy.type` 指定:

* `OnDelete`: 更新配置后, 只有手动删除 DaemonSet Pod 才会创建新的.
* `RollingUpdate`: 更新后自动删除并创建 Pod.

其他设置:

* `.spec.updateStrategy.rollingUpdate.maxUnavailable`: 默认值为1.
* `.spec.minReadySeconds`: 默认为0, 用于指定认为 DaemoSet Pod 启动可用所需的最小的秒数.

```yaml
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: test-ds
  namespace: kube-system
  labels:
    tier: node
    app: test
spec:
  updateStrategy:
    type: RollingUpdate
  selector:
    matchLabels:
      ...
  template:
    ...
```

# 阿里云 K8S

## 创建集群

### 准备工作

购买一台2核4G的最低配置的CentOS(可选偏远地区有优惠, 比如华北3), 安装 **docker**

#### 安装 kubectl

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

其他系统安装(Ubuntu):

```
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

##### 命令补全

**Zsh**:

在`~/.zshrc`添加以下代码: 

```
if [ $commands[kubectl] ]; then
  source <(kubectl completion zsh)
fi
```

**Oh-My-Zsh**:

如果是使用`Oh-My-Zsh`, 在`~/.zshrc`中, 找到`source $ZSH/oh-my-zsh.sh`这一行, 在这行**下面**添加(否则不生效): 

```
source <(kubectl completion zsh)
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

# Kubernetes 学习环境

* Minikube
* k3s
* Kind
* Docker Desktop Kubernetes

# 其他

## 别名

***[https://github.com/ahmetb/kubectl-aliases](https://github.com/ahmetb/kubectl-aliases)***

## Context 以及 Namespaces 切换工具

***[https://github.com/ahmetb/kubectx](https://github.com/ahmetb/kubectx)***

# 参考

***[https://www.qikqiak.com/k8s-book/](https://www.qikqiak.com/k8s-book/)***

***[https://www.cnblogs.com/breezey/p/9101666.html](https://www.cnblogs.com/breezey/p/9101666.html)***