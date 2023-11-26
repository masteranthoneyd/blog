# Kubernetes & Spring Cloud & DevOps

Kubernetes & Java 前后端分离项目的 CI/CD.

# 实战项目

实例项目是一个基于 Spring Boot + Spring Security + JWT + React + Ant Design 构建的开源投票系统: ***[spring-security-react-ant-design-polls-app](https://github.com/masteranthoneyd/spring-security-react-ant-design-polls-app)***

在这基础上新增了 Spring Cloud Alibaba 配置中心 Nacos.

# 集成 SCA Nacos

Nacos 搭建不是本章重点, 先使用 docker-compose quick start:

```yaml
version: "2"
services:
  nacos:
    image: nacos/nacos-server:latest
    container_name: nacos-standalone
    environment:
      - PREFER_HOST_MODE=hostname
      - MODE=standalone
      - JVM_XMX=1g
      - JVM_XMS=1g
      - JVM_XMN=500m
    ports:
      - "8848:8848"
```

`pom.xml` 加入 SCA Nacos 依赖:

> 原项目 Spring Boot 版本为 `2.2.1.RELEASE`, 这里升级到 `2.3.2.RELEASE`

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-alibaba-dependencies</artifactId>
            <version>2.2.3.RELEASE</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<dependencies>
    <dependency>
        <groupId>com.alibaba.cloud</groupId>
        <artifactId>spring-cloud-starter-alibaba-nacos-config</artifactId>
    </dependency>

    <dependency>
        <groupId>jakarta.validation</groupId>
        <artifactId>jakarta.validation-api</artifactId>
        <version>2.0.2</version>
    </dependency>
</dependencies>
```

项目新增 `bootstrap.yml`:

```yml
spring:
  application:
    name: polls
  cloud:
    nacos:
      server-addr: 127.0.0.1:8848 # 注意端口不能省略
      config:
        file-extension: yml
        namespace: test
        shared-configs:
          - data-id: common.yml
            group: SHARED_GROUP
            refresh: false
```

在 Nacos 新增 配置文件(注意命名空间), `common.yml`(注意 group 为 `SHARED_GROUP`):

```yaml
server:
  compression:
    enabled: true

spring:
  jackson:
    serialization:
      write-dates-as-timestamps: false
    time-zone: UTC

app:
  jwtSecret: JWTSuperSecretKey
  jwtExpirationInMs: 604800000
```

`polls.yml`:

```yaml
spring:
  datasource:
    url: jdbc:mysql://192.168.0.55:3306/polling_app?useSSL=false&serverTimezone=UTC&useLegacyDatetimeCode=true
    username: root
    password: root
    initialization-mode: always

  jpa:
    properties:
      hibernate:
        dialect: org.hibernate.dialect.MySQL5InnoDBDialect
    hibernate:
      ddl-auto: update
```

![](https://oldcdn.yangbingdong.com/img/k8s-spring-cloud-ci-cd/nacos.png)

# Spring Boot Actuator

加上 actuator 主要为了后面 Kubernetes 的 health check 以及优雅关机.

新增依赖:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

端点暴露配置, 先配置在 `bootstrap.yml` 中, 后续可通过 Kubernetes 启动参数配置:

```yml
management:
  server:
    port: 8081 # 安全考虑, K8S 只暴露 8080 端口, 8081 内部使用
  endpoints:
    web:
      exposure:
        include: '*' # http 默认只暴露了 health 跟 info
  endpoint:
    shutdown:
      enabled: true # 将 shutdown 断点开启, 默认除了 shutdown, 其他都是开启的
```

由于这个项目集成了 Spring Security, 需要修改一下 `SecurityConfig`, actuator 端点不需要验证:

```java
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
                .cors()
                    .and()
                    ......
                    .requestMatchers(EndpointRequest.toAnyEndpoint())
                        .permitAll()
                    .anyRequest()
                        .authenticated();
    }
```

# 构建 Docker 镜像

## 服务端

Java 中有构建 Docker 的 Maven 插件, 但是后续使用 Jenkins Pipeline 操作镜像的生成, 所以这里只做到打包阶段生成 Dockerfile 并复制 jar 包到同一个目录下即可.

### 基础镜像

`Dockerfile`:

```dockerfile
FROM frolvlad/alpine-oraclejre8:8.202.08-slim
MAINTAINER yangbingdong <yangbingdong1994@gmail.com>
ARG TZ
ENV TZ=${TZ:-"Asia/Shanghai"}
RUN apk update && \
    apk add --no-cache && \
    apk add curl bash tree tzdata busybox-extras && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

EXPOSE 8080

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

`entrypoint.sh`:

```bash
#!/bin/bash

export JAVA_OPTS="$JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -Duser.timezone=GMT+8 -Dfile.encoding=utf-8"

echo run: java $JAVA_OPTS -jar app.jar "$@"
exec java $JAVA_OPTS -jar app.jar "$@"
```

* `$@` 是用于接收 Kubernetes 中的 args
* 使用 `exec` 是为了让 java 进程的 pid 为 1

构建:

```
docker build -t docker-oraclejdk8:v3 .
```

### 打包生成 Dockerfile

在 `src/main/docker` 目录下新增 `Dockerfile`:

```dockerfile
FROM yangbingdong/docker-oraclejdk8:v3
ENV PROJECT_NAME="@project.build.finalName@.@project.packaging@"
ADD $PROJECT_NAME /app.jar
```

 修改 `pom.xml`, 在 `spring-boot-maven-plugin` 后面新增插件:

```xml
<properties>
    <dockerfile.compiled.position>${project.build.directory}/docker</dockerfile.compiled.position>
</properties>

<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>

        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-resources-plugin</artifactId>
            <executions>
                <execution>
                    <id>prepare-dockerfile</id>
                    <phase>validate</phase>
                    <goals>
                        <goal>copy-resources</goal>
                    </goals>
                    <configuration>
                        <!-- 编译后Dockerfile的输出位置 -->
                        <outputDirectory>${dockerfile.compiled.position}</outputDirectory>
                        <resources>
                            <!-- Dockerfile位置 -->
                            <resource>
                                <directory>${project.basedir}/src/main/docker</directory>
                                <filtering>true</filtering>
                            </resource>
                        </resources>
                    </configuration>
                </execution>
                <!-- 将Jar复制到target的docker目录中, 因为真正的Dockerfile也是在里面, 方便使用docker build命令构建Docker镜像 -->
                <execution>
                    <id>copy-jar</id>
                    <phase>package</phase>
                    <goals>
                        <goal>copy-resources</goal>
                    </goals>
                    <configuration>
                        <outputDirectory>${dockerfile.compiled.position}</outputDirectory>
                        <resources>
                            <resource>
                                <directory>${project.build.directory}</directory>
                                <includes>
                                    <include>*.jar</include>
                                </includes>
                            </resource>
                        </resources>
                    </configuration>
                </execution>
            </executions>
        </plugin>

    </plugins>
</build>
```

执行 `mvn package` 后:

![](https://oldcdn.yangbingdong.com/img/k8s-spring-cloud-ci-cd/mvn-package-render-dockerfile.png)

### 构建并推送

先手动构建 Docker 镜像(后续通过 Jenkins Pipeline 自动构建):

```
docker build -t polls:0.0.1
```

打标签推送到镜像仓库, 这里使用阿里云镜像服务:

```
# 先登录
docker login --username=${用户名} registry.cn-zhangjiakou.aliyuncs.com

docker tag polls:0.0.1 registry.cn-zhangjiakou.aliyuncs.com/yangbingdong/polls:0.0.1
docker push registry.cn-zhangjiakou.aliyuncs.com/yangbingdong/polls:0.0.1
```

## 客户端

由于是前后端分离项目, 原本的项目中需要知道后端的地址, 配置在 `src/constants/index.js` 的 `API_BASE_URL` 参数中.

这样对于不用环境打包出来的镜像就不一样了, 变成了有状态镜像. 这里需要修改成无状态的镜像, 所有环境共用一个镜像, niginx 通过读取环境变量获取转发的后端地址, 所以这里的做法是:

1. 将 `index.js` 中的 `API_BASE_URL` 改为 `/backend`, 比如后端 url 为 `/api/version`, 则接口请求地址为 `localhost/backend/api/version`, 再由 nginx 转发到后端.
2. 修改 nginx 中的配置文件, 将 `/backend` 的请求转发到后端, 后端地址通过环境变量读取

### 镜像制作

使用 docker 多阶段构建, Dockerfile:

```dockerfile
#### Stage 1: Build the react application
FROM node:12.4.0-alpine as build

WORKDIR /app

# Copy the package.json as well as the package-lock.json and install 
# the dependencies. This is a separate step so the dependencies 
# will be cached unless changes to one of those two files 
# are made.
COPY package.json package-lock.json ./
RUN npm install

COPY . ./

RUN npm run build

#### Stage 2
FROM nginx:1.19

COPY --from=build /app/build /var/www
RUN chown -R nginx:nginx /var/www/;

COPY default.conf.template /default.conf.template

EXPOSE 80

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

`default.conf.template`:

```
server {
        # listen on port 80
        listen 80;
        server_name  _;

        # 转发后端接口
        location /backend/ {
            proxy_set_header   Host             $host:80;
            proxy_set_header   x-forwarded-for  $remote_addr;
            proxy_set_header   X-Real-IP        $remote_addr;
            proxy_pass ${API_ENDPOINT}/;
        }

        # nginx root directory
        root /var/www/;

        # what file to server as index
        index index.html index.htm;

        location / {
            # First attempt to serve request as file, then
            # as directory, then fall back to redirecting to index.html
            try_files $uri $uri/ /index.html;
        }

        # Media: images, icons, video, audio, HTC
        location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm|htc)$ {
          expires 1M;
          access_log off;
          add_header Cache-Control "public";
        }

        # Javascript and CSS files
        location ~* \.(?:css|js)$ {
            try_files $uri =404;
            expires 1y;
            access_log off;
            add_header Cache-Control "public";
        }

        # Any route containing a file extension (e.g. /devicesfile.js)
        location ~ ^.+\..+$ {
            try_files $uri =404;
        }
}
```

`entrypoint.sh`:

```sh
#!/bin/bash

if [ ! -n "$API_ENDPOINT" ]; then
   echo "you should set env 'API_ENDPOINT'!"
   exit 1
else
    echo api endpoint: $API_ENDPOINT
    # 读取指定环境变量注入到 default.conf.template
    envsubst '${API_ENDPOINT}' < /default.conf.template > /etc/nginx/conf.d/default.conf
fi

exec nginx -g "daemon off;"
```

* 如果不想在服务器中安装 nodejs, 可以使用 docker 多阶段构建, 第一阶段构建的镜像是为了编译生成静态页面, 第二阶段构建的才是真正用到的 nginx 镜像.
* nginx 配置文件中不支持读取环境变量, 所以通过 `envsubst` 读取环境变量生成配置文件
* `exec` 是为了 nginx 进程的 pid 为1

### 生成镜像并推送

> 注意先登录镜像仓库

```
docker build -t polls-client:0.0.1 .

docker tag polls-client:0.0.1 registry.cn-zhangjiakou.aliyuncs.com/yangbingdong/polls-client:0.0.1
docker push registry.cn-zhangjiakou.aliyuncs.com/yangbingdong/polls-client:0.0.1
```

## docker-compose 简单验证

现在试着用 docker compose 启动这两个项目验证是否正常:

```yaml
version: '3'

services:
  app-server:
    image: registry.cn-zhangjiakou.aliyuncs.com/yangbingdong/polls:0.0.1
    ports:
      - "8080:8080"
    command: ["--spring.cloud.nacos.server-addr=192.168.0.55:8848"]

  app-client:
    image: registry.cn-zhangjiakou.aliyuncs.com/yangbingdong/polls-client:0.0.1
    ports:
      - "8070:80"
    environment:
      API_ENDPOINT: 'http://192.168.0.55:8080'
```

![](https://oldcdn.yangbingdong.com/img/k8s-spring-cloud-ci-cd/simple-verify.png)

# 部署到 Kubernetes 中

## 集群准备

购买一台2核4G的最低配置的CentOS(可选偏远地区有优惠, 比如华北3), 并且安装 **docker**.

### 安装 kubectl

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

在容器服务K8S版中创建集群, 选择**托管版**, **按量付费**, 工作节点可选 `ecs.t6-c1m2.large`, 最低要求两台. 创建大概需要10分钟.

配置 KubeConfig: 创建完成之后在集群信息中找到**连接信息**, 里面有教程.

配置安全组: 在 ECS 中将两个 Worker 的安全组配置成与准备工作中买的那台一样.

### 镜像服务配置

在**容器镜像服务**中开通, 注意创建的仓库所在**地区**要与K8S配置的一致(华北3), 并且在**访问凭证**中创建密码.

在仓库详情中会有两个地址, 一个公网, 一个内网, **内网需要在同一个地区才能访问**.

### 停止设置

#### 停止实例

在 ECS 服务中停止实例时选**停机不收费**的那项即可.

#### 停止负载均衡

负载均衡在负载均衡控制台中停止.

#### 完全释放资源

实例释放设置前要先取消**实例释放保护**.

### NAS

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

## 部署文件

Kubernetes 使用阿里云容器服务, 可以选择最低消费版(偏远地区比如华北3, 两个2核4G的低配, 按量付费). 使用另外一台 ECS 安装

后端部署文件 `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: polls
  labels:
    app: polls
    version: v1.0
  namespace: prod
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: polls
      version: v1.0
  minReadySeconds: 3 # 指定新创建的 Pod 在没有任意容器崩溃情况下的最小就绪时间, 默认值为 0(Pod 在准备就绪后立即将被视为可用)
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  template:
    metadata:
      name: polls
      labels:
        app: polls
        version: v1.0
    spec:
      affinity: # 亲和性调度
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app
                      operator: In
                      values:
                        - polls
                topologyKey: kubernetes.io/hostname
      terminationGracePeriodSeconds: 30  # 优雅终止宽限期, 默认30秒
      containers:
        - name: polls
          image: registry-vpc.cn-zhangjiakou.aliyuncs.com/yangbingdong/polls:0.0.1
          imagePullPolicy: Always  # 每次启动时检查和更新（从registery）images的策略, 三个选择Always()/Never/IfNotPresent
          ports:
            - name: http # 端口配置名称, 在 Service -> target port 可以指定端口或者使用该名称
              containerPort: 8080
              protocol: TCP  #端口协议, 支持TCP和UDP, 默认TCP
          lifecycle: # 生命周期管理
            preStop: # 容器终止之前立即被调用
              exec:
                command: [ "/usr/bin/curl","-X","POST", "http://localhost:8081/actuator/shutdown" ]
          startupProbe: # 慢启动容器保护, 一旦成功后, 存活探测任务就会接管对容器的探测
            httpGet:
              path: /actuator/health
              port: 8081
              scheme: HTTP
            failureThreshold: 10
            periodSeconds: 15
          livenessProbe: # pod存活检查, 失败的pod将从k8s中终止并启动新的pod
            httpGet: # 通过httpget检查健康, 返回200-399之间, 则认为容器正常
              path: /actuator/health
              port: 8081
              scheme: HTTP
            initialDelaySeconds: 5  #表明第一次检测在容器启动后多长时间后开始, 默认0秒
            timeoutSeconds: 10  #检测的超时时间, 默认1秒
            periodSeconds: 15  #检查间隔时间, 默认10秒
          readinessProbe: # pod就绪探测, 当pod中所有容器就绪后, 流量才会进来, 否则将从 service 中移除
            httpGet:
              path: /actuator/health
              port: 8081
              scheme: HTTP
            initialDelaySeconds: 5
            timeoutSeconds: 10
            periodSeconds: 15
          resources: # 资源限制管理
            requests: # 容器运行时, 最低资源需求, 也就是说最少需要多少资源容器才能正常运行
              cpu: 100m  # CPU资源(核数), 两种方式, 浮点数或者是整数+m, 0.1=100m, 最少值为0.001核(1m)
              memory: 512Mi  # 内存使用量
            limits: #资源限制
              cpu: 1000m
              memory: 2048Mi
          env: #指定容器中的环境变量
            - name: JAVA_OPTS
              value: "-Xmx1g -Xms1g"
          args: #启动容器的命令参数, 对应 Dockerfile 中 CMD 参数
            - --spring.devtools.add-properties=false
            - --management.endpoints.web.exposure.include=*
            - --management.endpoint.shutdown.enabled=true
            - --management.server.port=8081
            - --spring.cloud.nacos.config.enabled=true
            - --spring.cloud.nacos.server-addr=192.168.0.241:8848
            - --spring.cloud.nacos.config.namespace=prod

---
apiVersion: v1
kind: Service
metadata:
  name: polls
  labels:
    app: polls
  namespace: prod
spec:
  ports:
    - port: 8080
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app: polls
```

客户端:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: polls-client
  labels:
    app: polls-client
  namespace: prod
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app: polls-client
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: polls-client
  labels:
    app: polls-client
    version: v1.0
  namespace: prod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: polls-client
      version: v1.0
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: polls-client
        version: v1.0
    spec:
      containers:
        - name: polls-client
          image: registry-vpc.cn-zhangjiakou.aliyuncs.com/yangbingdong/polls-client:0.0.1
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          resources:
            limits:
              cpu: 500m
              memory: 256Mi
            requests:
              cpu: 100m
              memory: 64Mi
          env:
            - name: API_ENDPOINT
              value: http://polls:8080
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: polls-client
  labels:
    app: polls-client
  namespace: prod
spec:
  rules:
    - host: polls.yangbingdong.com
      http:
        paths:
          - path: /
            backend:
              serviceName: polls-client
              servicePort: http
```

注意点:

* 安全组端口开放(Nacos, MySQL)
* 域名解析(注意是解析到 ACK 的负载均衡 IP 上)

## 验证

访问域名

![](https://oldcdn.yangbingdong.com/img/k8s-spring-cloud-ci-cd/site-k8s-verify.png)

# 使用 Helm 部署应用

## 构建基础子 chart

对于大部分 Spring Boot 应用来说, 部署用的 `deployment.yaml` 其实都大同小异, 只是应用名跟一些细微的参数不一样, 所以我们可以将共性的东西抽取出来构建出子模块, 具体的应用再依赖这个子模块并通过参数配置可变的部分.

### 编写子 chart

子 chart 目录树:

```
.
├── Chart.yaml
├── templates
│   ├── deployment.yaml
│   ├── ingress.yaml
│   └── service.yaml
└── values.yaml
```

`Chart.yaml`:

```
apiVersion: v2
appVersion: v1.0
name: boot2
description: A Helm chart for Spring Cloud Kubernetes
version: 1.0.8
```

`values.yaml`:

```
app:
  name: <changeme>
  #  version: "v1.0"
  image:
    imagePullPolicy: "ALWAYS"
    name: ""
    repository: ""
    tag: <changeme>

replicas: 1
javaOpts: "-Xmx1g -Xms1g"


args: {}
env: {}
resources: {}
volumes: {}
volumeMounts: {}

nodeSelector: {}
tolerations: []
affinity: {}


service:
  enabled: true
  name: "" # left empty if use app.name
  type: ClusterIP
  port: 8080


ingress:
  enabled: false
  name: "" # left empty if use app.name
  annotations: {}
  path: /
  hosts:
    - <changeme>
```

`deployment.yaml`:

```
{{- $appName := .Values.app.name -}}
  {{- $appVersion := .Values.app.version | default .Chart.AppVersion -}}

apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $appName }}-{{ $appVersion }}
  labels:
    app: {{ $appName }}
    version: {{ $appVersion }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
spec:
  replicas: {{ .Values.replicas }}
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: {{ $appName }}
      version: {{ $appVersion }}
      release: {{ .Release.Name }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  template:
    metadata:
      name: {{ $appName }}
      labels:
        app: {{ $appName }}
        version: {{ $appVersion }}
        release: {{ .Release.Name }}
    spec:
      containers:
        - name: {{ $appName }}
          image: "{{ .Values.app.image.repository | default .Values.global.image.repository }}/{{ $appName }}:{{ .Values.app.image.tag }}"
          imagePullPolicy: {{ .Values.global.image.imagePullPolicy }}
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          lifecycle:
            preStop:
              exec:
                command: [ "/usr/bin/curl","-X","POST", "http://localhost:8081/actuator/shutdown" ]
          startupProbe:
            httpGet:
              path: /actuator/health
              port: 8081
              scheme: HTTP
            failureThreshold: 10
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /actuator/health
              port: 8081
              scheme: HTTP
            initialDelaySeconds: 5
            timeoutSeconds: 10
            periodSeconds: 15
          readinessProbe:
            httpGet:
              path: /actuator/health
              port: 8081
              scheme: HTTP
            initialDelaySeconds: 5
            timeoutSeconds: 10
            periodSeconds: 15
          {{- with .Values.resources }}
          resources:
          {{ toYaml . | nindent 12 }}
          {{- end }}
          {{- if not .Values.resources }}
          {{- with .Values.global.resources }}
          resources:
          {{ toYaml . | nindent 12 }}
          {{- end }}
          {{- end }}
          env:
            - name: JAVA_OPTS
              value: {{ .Values.javaOpts | default .Values.global.javaOpts | quote }}
          args:
            - --spring.devtools.add-properties=false
            - --management.endpoints.web.exposure.include=*
            - --management.endpoint.shutdown.enabled=true
            - --management.server.port=8081
            {{- with .Values.args }}
          {{ toYaml . | nindent 12 }}
      {{- end }}

      {{- with .Values.nodeSelector }}
      nodeSelector:
      {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- with .Values.affinity }}
      affinity:
      {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- with .Values.tolerations }}
      tolerations:
      {{- toYaml . | nindent 8 }}
  {{- end }}
```

`service.yaml`:

```
{{- if .Values.service.enabled -}}
  {{- $serviceName := .Values.app.name -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ $serviceName }}
  labels:
    app: {{ $serviceName }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app: {{ $serviceName }}
  {{- end }}
```

`ingress.yaml`:

```
{{- if .Values.ingress.enabled -}}
  {{- $serviceName := .Values.app.name -}}
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: {{ $serviceName }}
  labels:
    app: {{ $serviceName }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
  {{- with .Values.ingress.annotations }}
  annotations:
  {{ toYaml . | indent 4 }}
  {{- end }}
spec:
  rules:
    {{- $path := .Values.ingress.path }}
    {{- range .Values.ingress.hosts }}
    - host: {{ . }}
      http:
        paths:
          - path: {{ $path }}
            backend:
              serviceName: {{  $serviceName }}
              servicePort: http
  {{- end }}
{{- end }}
```

### 打包并上传到私有仓库

```
# 打包
helm package boots/

# 上传
curl --data-binary "@boot2-1.0.7.tgz" http://charts.yangbingdong.com/api/charts
```

上传脚本, `push_chart.sh`:

```sh
#!/bin/bash
ret=`helm package $1`

if [ $? -ne 0 ]; then
  echo failed to push chart: $ret
  exit 1
fi

file=`echo $ret |awk '{print $NF}'`

file_name=`echo $file | awk -F '/' '{print $NF}'`

echo pushing chart: $file_name
curl --data-binary "@$file" http://charts.test.yanpin.cn/api/charts

rm $file
```

```
# 打包并上传
./push_chart.sh boots
```

## 编写父 chart

以 server 端项目为例, 只需要在 `Chart.yaml` 中依赖子 chart, 并覆盖定义的kv.

共享变量:

```
子chart.${变量}
```

全局变量:

```
global.${变量}
```

polls 目录树

```
.
├── Chart.yaml
└── values.yaml
```

`Chart.yaml`:

```
apiVersion: v2
name: polls
description: A Helm chart for polls

type: application

version: 0.0.1

appVersion: 1.0.0

dependencies:
  - name: boot2
    version: 1.0.8
    repository: http://charts.yangbingdong.com
```

`values.yaml`:

```
boot2:
  app:
    name: polls
    #version: "v1.0"
    image:
      tag: 0.0.1

  args:
    - --spring.cloud.nacos.config.enabled=true
    - --spring.cloud.nacos.server-addr=192.168.0.241:8848
    - --spring.cloud.nacos.config.namespace=prod
  ingress:
    enabled: true
    hosts:
      - polls-server.yangbingdong.com
```

## 通过 helm 部署

初始化依赖:

```
cd polls
helm dependency update
```

部署:

```
helm install -f global.yaml -n prod polls/ --generate-name
```

# 使用 Argocd 实践 GitOps

![](https://oldcdn.yangbingdong.com/img/k8s-spring-cloud-ci-cd/argocd.png)

## Argocd 安装

```
wget https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 因为后续会使用 ingress 暴露外网，所以 argocd 不启用 tls
vi install.yaml
#在 2567 行出加入,argocd-server Deployment 中
- --insecure
```

![](https://oldcdn.yangbingdong.com/img/k8s-spring-cloud-ci-cd/argocd-install.png)

安装:

```
kubectl create namespace argocd
kubectl apply -n argocd -f install.yaml

# 查看状态
kubectl get pod -n argocd
kubectl get svc -n argocd
```

`ingress.yaml`:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: argocd.yangbingdong.com
    http:
      paths:
      - backend:
          serviceName: argocd-server
          servicePort: http
```

接下来就可以了通过域名访问 argocd web ui 了.

默认账号名: admin

查看密码: `kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2`

客户端安装: 

```
VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
```

客户端登录:

```
argocd login <ARGOCD_SERVER>

# 更新密码
argocd account update-password
```

## 部署

```
argocd app create polls \
  --project prod \
  --repo https://github.com/masteranthoneyd/spring-security-react-ant-design-polls-app \
  --path deployments/helm/polls \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace prod
  --revision-history-limit 5 \
  --values ../global.yaml
  
  argocd app sync polls
```

## 更新应用

```
argocd app set polls -p boot2.app.image.tag=0.0.2
argocd app sync polls
```


