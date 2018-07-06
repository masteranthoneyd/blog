# Elastic Job 与 Sping Cloud 集成解决依赖冲突问题

由于Elastic Job自身的 `curator-client`,`curator-framework`,`curator-recipes`与Spring Cloud组件中的`curator-client`,`curator-framework`,`curator-recipes`有版本冲突，在启动过程会报如下错误：

```
2018-07-06 18:19:34.403 | epms |  WARN | IP: |            main | AnnotationConfigServletWebServerApplicationContext |   558 | refresh | Exception encountered during context initialization - cancelling refresh attempt: org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'reqAspect' defined in file [/home/ybd/data/git-repo/bitbucket/epms/epms-core/target/classes/com/yanglaoban/epms/core/aop/ReqAspect.class]: Unsatisfied dependency expressed through constructor parameter 0; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'disruptorConfig': Injection of resource dependencies failed; nested exception is org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'delayHandler' defined in file [/home/ybd/data/git-repo/bitbucket/epms/epms-core/target/classes/com/yanglaoban/epms/core/pubsub/disruptor/handler/DelayHandler.class]: Unsatisfied dependency expressed through constructor parameter 0; nested exception is org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'delayService' defined in file [/home/ybd/data/git-repo/bitbucket/epms/epms-core/target/classes/com/yanglaoban/epms/core/domain/service/DelayService.class]: Unsatisfied dependency expressed through constructor parameter 0; nested exception is org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'elasticJobService' defined in file [/home/ybd/data/git-repo/bitbucket/epms/epms-core/target/classes/com/yanglaoban/epms/core/elasticjob/ElasticJobService.class]: Unsatisfied dependency expressed through constructor parameter 0; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'regCenter' defined in class path resource [com/yanglaoban/epms/core/elasticjob/config/ElasticJobConfig.class]: Invocation of init method failed; nested exception is java.lang.NoClassDefFoundError: org/apache/curator/connection/StandardConnectionHandlingPolicy
```

解决方式是排除Elastic Job中`curator`相关依赖，重新导入：

```
<properties>
   <elastic-job.version>2.1.5</elastic-job.version>
   <curator.version>2.10.0</curator.version>
</properties>

<dependencies>
     <dependency>
            <groupId>com.dangdang</groupId>
            <artifactId>elastic-job-lite-core</artifactId>
            <version>${elastic-job.version}</version>
            <exclusions>
                <exclusion>
                    <artifactId>curator-client</artifactId>
                    <groupId>org.apache.curator</groupId>
                </exclusion>
                <exclusion>
                    <artifactId>curator-framework</artifactId>
                    <groupId>org.apache.curator</groupId>
                </exclusion>
                <exclusion>
                    <artifactId>curator-recipes</artifactId>
                    <groupId>org.apache.curator</groupId>
                </exclusion>
            </exclusions>
        </dependency>
        <dependency>
            <groupId>org.apache.curator</groupId>
            <artifactId>curator-framework</artifactId>
            <version>${curator.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.curator</groupId>
            <artifactId>curator-client</artifactId>
            <version>${curator.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.curator</groupId>
            <artifactId>curator-recipes</artifactId>
            <version>${curator.version}</version>
        </dependency>
</dependencies>
```

