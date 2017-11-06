# Docker搭建Nexus3私服

# Preface

> 一般每个企业里面都有属于自己的Nexus服务器作为自己的私服（代理），私服好处众多，例如加速构建、稳定，节省带宽、节省中央`maven`仓库的带宽，控制和审计，可以建立本地内部仓库、可以建立公共仓库等等。`Docker` 可以大大简化服务器的部署，并且Nexus3已经支持`Docker Image`啦～爽歪歪

# Get Image

## 直接拉取镜像

```
docker pull sonatype/nexus3
```

如果没有代理导致下载很慢可以尝试下面方式二

## 通过Dockerfile构建

通过官方的`Dockerfile`构建：

```
git clone https://github.com/sonatype/docker-nexus3.git
cd docker-nexus3
docker build --rm=true --tag=sonatype/nexus3 .
```

`--rm=true` 表示成功编译后删除中间的容器，至于`tag`随便起

# Volume

官方有两种方式：

* 使用 docker 的 `data volume` （推荐）
* 使用本地目录作为 container 的 `volume`

使用`data volume`可以获取更高的灵活性。

使用 `data volume`：
```
docker volume create --name nexus-data
```

使用本地目录：
```
mkdir /some/dir/nexus-data && chown -R 200 /some/dir/nexus-data
```

其中 `chown -R 200` 表示更改该文件夹的拥有者为 UID 为 200 的用户，这里应该是为了尽量不要在本机被当前用户或其他用户修改该文件夹，该文件夹只允许我们后面运行的 docker container 来使用。（个人认为，首先通过命令`id 200` 检查一下该 `id` 是否有用户，如果没有就用该 `id`，如果有则换一个新的 `id`。）

# Run

使用 `data volume`：
```
docker run -d -p 8090:8081 --name nexus -v nexus-data:/nexus-data sonatype/nexus3
```

使用本地目录：
```
docker run -d -p 8090:8081 --name nexus -v /some/dir/nexus-data:/nexus-data sonatype/nexus3
```


通过`docker logs nexus` 可以查看启动日志。

启动过程需要稍等几分钟，之后可以访问`localhost:8090`，默认的 用户名／密码是admin／admin123，需要自己修改密码。

# Proxy

默认的`maven-central` 使用的是*[https://repo1.maven.org/maven2/](https://repo1.maven.org/maven2/)* 地址，速度上没有UK 的快，所以修改为*[http://uk.maven.org/maven2/](http://uk.maven.org/maven2/)* 或者阿里的镜像*[http://maven.aliyun.com/nexus/content/groups/public/](http://maven.aliyun.com/nexus/content/groups/public/)*

![](http://ojoba1c98.bkt.clouddn.com/img/docker-nexus3/proxy-url.png)

# Backup & Recovery

## 备份

```
docker run --rm -v nexus-data:/vdata -v $(pwd):/backup ubuntu:latest tar cvf /backup/vdata-bak.tar /vdata

# or
docker run --rm -v nexus-data:/vdata -v $(pwd):/backup ubuntu:latest tar zcvf /backup/vdata-bak.tar.gz /vdata 
```
## 还原
```
docker volume create --name nexus-data1
```

```
docker run --rm -v nexus-data1:/vdata -v $(pwd):/backup ubuntu:latest tar xvf /backup/vdata-bak.tar -C /vdata --strip-components=1

# or
docker run --rm -v nexus-data1:/vdata -v $(pwd):/backup ubuntu:latest tar zxvf /backup/vdata-bak.tar.gz -C /vdata --strip-components=1
```

`--strip-components=1`是为了不要解压出来的最外层文件夹

# Maven Source

下载`jar`包源码可以在配置文件或IDEA中配置

## 通过配置文件添加

在maven的`settings.xml`配置：

```
<profiles>  
<profile>  
    <id>downloadSources</id>  
    <properties>  
        <downloadSources>true</downloadSources>  
        <downloadJavadocs>true</downloadJavadocs>             
    </properties>  
</profile>  
</profiles>  
  
<activeProfiles>  
  <activeProfile>downloadSources</activeProfile>  
</activeProfiles>  
```

## IDEA配置

![](http://ojoba1c98.bkt.clouddn.com/img/docker-nexus3/download-source.png)

然后重新`import`就ok了

# End

> 参考： ***[https://hub.docker.com/r/sonatype/nexus3/](https://hub.docker.com/r/sonatype/nexus3/)***

