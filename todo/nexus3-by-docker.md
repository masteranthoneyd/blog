# Nexus搭建与Maven配置

![](https://cdn.yangbingdong.com/img/docker-nexus3/nexus-logo.png)

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

# Enviroment

可通过 `INSTALL4J_ADD_VM_PARAMS` 环境变量配置 JVM 参数.

默认是:

```
-Xms1200m -Xmx1200m -XX:MaxDirectMemorySize=2g -Djava.util.prefs.userRoot=${NEXUS_DATA}/javaprefs
```

ex:

```
docker run -d -p 8081:8081 --name nexus -e INSTALL4J_ADD_VM_PARAMS="-Xms2g -Xmx2g -XX:MaxDirectMemorySize=3g  -Djava.util.prefs.userRoot=/some-other-dir" sonatype/nexus3
```

# Run

使用 `data volume`：
```
docker run --restart=always -d -p 8090:8081 --name nexus -v nexus-data:/nexus-data sonatype/nexus3
```

使用本地目录：
```
docker run --restart=always -d -p 8090:8081 --name nexus -v /some/dir/nexus-data:/nexus-data sonatype/nexus3
```


通过`docker logs nexus` 可以查看启动日志。

启动过程需要稍等几分钟，之后可以访问`localhost:8090`，默认的 用户名／密码是admin／admin123，需要自己修改密码。

# Password

最新版的默认密码是随机生成的, 在 `/nexus-data/admin.password` 中, **首次登录**需要输入里面的密码, 再重新设置密码.

# Repositories

![](https://cdn.yangbingdong.com/img/docker-nexus3/nexus-repo.png)

有几个默认仓库分别是：

1. `maven-central`：maven中央库，默认从[https://repo1.maven.org/maven2/](https://repo1.maven.org/maven2/)拉取jar
2. `maven-releases`：私库发行版jar，初次安装请将`Deployment policy`设置为`Allow redeploy`
3. `maven-snapshots`：私库快照（调试版本）`jar`
4. `maven-public`：仓库分组，把上面三个仓库组合在一起对外提供服务，在本地maven基础配置`settings.xml`中使用。

Nexus默认的仓库类型有以下四种：

1. `group`(仓库组类型)：又叫组仓库，用于方便开发人员自己设定的仓库
2. `hosted`(宿主类型)：内部项目的发布仓库（内部开发人员，发布上去存放的仓库
3. `proxy`(代理类型)：从远程中央仓库中寻找数据的仓库（可以点击对应的仓库的`Configuration`页签下`Remote Storage`属性的值即被代理的远程仓库的路径
4. `virtual`(虚拟类型)：虚拟仓库（这个基本用不到，重点关注上面三个仓库的使用）

# Proxy

由于访问中央仓库有时候会比较慢，我们可以配置代理加快速度。

## 方式一

默认的`maven-central` 使用的是 *[https://repo1.maven.org/maven2/](https://repo1.maven.org/maven2/)* 地址，速度上没有UK 的快，所以修改为 *[http://uk.maven.org/maven2/](http://uk.maven.org/maven2/)* 或者阿里的镜像 *[http://maven.aliyun.com/nexus/content/groups/public/](http://maven.aliyun.com/nexus/content/groups/public/)* 或 *[https://maven.aliyun.com/repository/public](https://maven.aliyun.com/repository/public)*

![](https://cdn.yangbingdong.com/img/docker-nexus3/proxy-url.png)

## 方式二

添加一个阿里云的代理仓库，然后优先级放到默认中央库之前：

![](https://cdn.yangbingdong.com/img/docker-nexus3/nexus-proxy1.png)

然后再public组里面讲这个`aliyun-proxy`仓库加入，排在`maven-central`之前即可。

![](https://cdn.yangbingdong.com/img/docker-nexus3/nexus-proxy2.png)

**Nexus仓库分类的概念**

1）Maven可直接从宿主仓库下载构件,也可以从代理仓库下载构件,而代理仓库间接的从远程仓库下载并缓存构件

2）为了方便,Maven可以从仓库组下载构件,而仓库组并没有时间的内容(下图中用虚线表示,它会转向包含的宿主仓库或者代理仓库获得实际构件的内容)

![](https://cdn.yangbingdong.com/img/docker-nexus3/nexus-proxy3.png)

# 允许多次push

![](https://cdn.yangbingdong.com/img/docker-nexus3/nexus-repush.png)

# Backup & Recovery

## 备份

```
docker run --rm -v nexus-data:/backup-data -v $(pwd):/backup ubuntu:latest tar cvf /backup/nexus-data.tar /backup-data

# or
docker run --rm -v nexus-data:/backup-data -v $(pwd):/backup ubuntu:latest tar zcvf /backup/nexus-data.tar.gz /backup-data 
```
## 还原
```
docker volume create --name nexus-data1
```

```
docker run --rm -v nexus-data1:/vdata -v $(pwd):/backup ubuntu:latest tar xvf /backup/nexus-data.tar -C /vdata --strip-components=1

# or
docker run --rm -v nexus-data1:/vdata -v $(pwd):/backup ubuntu:latest tar zxvf /backup/nexus-data.tar.gz -C /vdata --strip-components=1
```

`--strip-components=1`是为了不要解压出来的最外层文件夹

# Maven 配置

## 配置文件

`setting.xml`:

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
    <!-- 设置自己的maven本地仓库 -->
    <localRepository>/home/ybd/data/application/maven/maven-repo-local</localRepository>

    <servers>
        <server>
            <id>nexus-releases</id>
            <username>admin</username>
            <password>admin123</password>
        </server>
        <server>
            <id>nexus-snapshots</id>
            <username>admin</username>
            <password>admin123</password>
        </server>
    </servers>

    <mirrors>
        <mirror>
            <id>nexus-public</id>
            <mirrorOf>*</mirrorOf>
            <name>central repository</name>
            <url>http://127.0.0.1:9091/repository/maven-public/</url>
        </mirror>
    </mirrors>

    <profiles>
        <profile>
            <id>nexus</id>
            <repositories>
                <repository>
                    <id>nexus-releases</id>
                    <name>Nexus Release Snapshot Repository</name>
                    <url>http://127.0.0.1:9091/repository/maven-public/</url>
                    <releases>
                        <enabled>true</enabled>
                    </releases>
                    <snapshots>
                        <enabled>true</enabled>
                    </snapshots>
                </repository>
                <repository>
                    <id>nexus-snapshots</id>
                    <url>http://127.0.0.1:9091/repository/maven-public/</url>
                    <releases>
                        <enabled>true</enabled>
                    </releases>
                    <snapshots>
                        <enabled>true</enabled>
                    </snapshots>
                </repository>
            </repositories>
            <pluginRepositories>
                <pluginRepository>
                    <id>nexus-releases</id>
                    <name>Nexus Release Snapshot Repository</name>
                    <url>http://127.0.0.1:9091/repository/maven-public/</url>
                    <releases>
                        <enabled>true</enabled>
                    </releases>
                    <snapshots>
                        <enabled>true</enabled>
                    </snapshots>
                </pluginRepository>
                <pluginRepository>
                    <id>nexus-snapshots</id>
                    <url>http://127.0.0.1:9091/repository/maven-public/</url>
                    <releases>
                        <enabled>true</enabled>
                    </releases>
                    <snapshots>
                        <enabled>true</enabled>
                    </snapshots>
                </pluginRepository>
            </pluginRepositories>
        </profile>
    </profiles>

    <activeProfiles>
        <activeProfile>nexus</activeProfile>
    </activeProfiles>
</settings>
```

## 下载源码

下载`jar`包源码可以在配置文件或IDEA中配置

### 通过配置文件添加

在maven的`settings.xml`配置：

```xml
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

### IDEA配置

![](https://cdn.yangbingdong.com/img/docker-nexus3/download-source.png)

然后重新`import`就ok了

## 发布项目

在 `pom.xml` 中配置:

```xml
<distributionManagement>
    <!-- 两个ID必须与 setting.xml中的<server><id>nexus-releases</id></server>保持一致-->
    <repository>
        <id>nexus-releases</id>
        <name>Nexus Release Repository</name>
        <url>http://127.0.0.1:9091/repository/maven-public/</url>
    </repository>
    <snapshotRepository>
        <id>nexus-snapshots</id>
        <name>Nexus Snapshot Repository</name>
        <url>http://127.0.0.1:9091/repository/maven-public/</url>
    </snapshotRepository>
</distributionManagement>
```

# 仓库优先级

本地仓库 > 私服 （profile）> 远程仓库（repository）和 镜像 （mirror） > 中央仓库 （central）

# 附录: 阿里代理的仓库列表

| 仓库名称         | 代理源地址                               | 使用地址                                                     |
| :--------------- | :--------------------------------------- | :----------------------------------------------------------- |
| central          | https://repo1.maven.org/maven2/          | https://maven.aliyun.com/repository/central 或 https://maven.aliyun.com/nexus/content/repositories/central |
| jcenter          | http://jcenter.bintray.com/              | https://maven.aliyun.com/repository/jcenter 或 https://maven.aliyun.com/nexus/content/repositories/jcenter |
| public           | central仓和jcenter仓的聚合仓             | https://maven.aliyun.com/repository/public 或https://maven.aliyun.com/nexus/content/groups/public |
| google           | https://maven.google.com/                | https://maven.aliyun.com/repository/google 或 https://maven.aliyun.com/nexus/content/repositories/google |
| gradle-plugin    | https://plugins.gradle.org/m2/           | https://maven.aliyun.com/repository/gradle-plugin 或 https://maven.aliyun.com/nexus/content/repositories/gradle-plugin |
| spring           | http://repo.spring.io/libs-milestone/    | https://maven.aliyun.com/repository/spring 或 https://maven.aliyun.com/nexus/content/repositories/spring |
| spring-plugin    | http://repo.spring.io/plugins-release/   | https://maven.aliyun.com/repository/spring-plugin 或 https://maven.aliyun.com/nexus/content/repositories/spring-plugin |
| grails-core      | https://repo.grails.org/grails/core      | https://maven.aliyun.com/repository/grails-core 或 https://maven.aliyun.com/nexus/content/repositories/grails-core |
| apache snapshots | https://repository.apache.org/snapshots/ | https://maven.aliyun.com/repository/apache-snapshots 或 https://maven.aliyun.com/nexus/content/repositories/apache-snapshots |

使用:

```xml
<mirror>
    <id>aliyunmaven</id>
    <mirrorOf>*</mirrorOf>
    <name>阿里云公共仓库</name>
    <url>https://maven.aliyun.com/repository/public</url>
</mirror>	
```

如果想使用其它代理仓库,可在`<repositories></repositories>`节点中加入对应的仓库使用地址。以使用spring代理仓为例：

```xml
<repository>
    <id>spring</id>
    <url>https://maven.aliyun.com/repository/spring</url>
    <releases>
        <enabled>true</enabled>
    </releases>
    <snapshots>
        <enabled>true</enabled>
    </snapshots>
</repository>
```

# End

> 参考： ***[https://hub.docker.com/r/sonatype/nexus3/](https://hub.docker.com/r/sonatype/nexus3/)***



