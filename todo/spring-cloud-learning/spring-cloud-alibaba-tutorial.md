# Nacos 配置中心

> Nacos 官网: ***[https://nacos.io/](https://nacos.io/)***
>
> Spring Cloud Nacos Config 文档: ***[https://github.com/alibaba/spring-cloud-alibaba/wiki/Nacos-config](https://github.com/alibaba/spring-cloud-alibaba/wiki/Nacos-config)***

## 配置加载解读

Nacos 主要通过这几个参数控制配置文件的加载:

- `spring.cloud.nacos.config.namespace`: 命名空间, 可实现环境隔离或多租户, 默认值为 `public`
- `spring.cloud.nacos.config.prefix`: Data Id 前缀, 默认取 `${spring.application.name}`
- `spring.cloud.nacos.config.file-extension`: Data Id 后缀, 默认值 `properties`
- `spring.cloud.nacos.config.group`: 对应 Group, 默认值 `DEFAULT_GROUP`

Nacos 会加载 `${spring.cloud.nacos.config.namespace}` 下 `Data ID=${spring.cloud.nacos.config.prefix}-${spring.profiles.active}.${spring.cloud.nacos.config.file-extension}`, `Group=${spring.cloud.nacos.config.group}`的配置.

即默认加载 `Data ID=${spring.application.name}.properties` (没有指定指定 profile), `Group=DEFAULT_GROUP` 的配置.

## 多环境隔离方案

三种方案:

1. 通过 `Namespace`(官方推荐)
2. 通过 `Group`
3. 通过 `Data Id` + `profile`

## 多配置加载与共享配置

通过 `spring.cloud.nacos.config.ext-config[n]` 进行多配置加载:

```
spring.cloud.nacos.config.ext-config[0].data-id=actuator.properties
spring.cloud.nacos.config.ext-config[0].group=DEFAULT_GROUP
spring.cloud.nacos.config.ext-config[0].refresh=true
spring.cloud.nacos.config.ext-config[1].data-id=log.properties
spring.cloud.nacos.config.ext-config[1].group=DEFAULT_GROUP
spring.cloud.nacos.config.ext-config[1].refresh=true
```

共享配置:

```
# 配置支持共享的 Data Id
spring.cloud.nacos.config.shared-configs[0].data-id=common.yaml

# 配置 Data Id 所在分组，缺省默认 DEFAULT_GROUP
spring.cloud.nacos.config.shared-configs[0].group=GROUP_APP1

# 配置Data Id 在配置变更时，是否动态刷新，缺省默认 false
spring.cloud.nacos.config.shared-configs[0].refresh=true
```

**配置优先级:**

Spring Cloud Alibaba Nacos Config 目前提供了三种配置能力从 Nacos 拉取相关的配置。

- A: 通过 `spring.cloud.nacos.config.shared-configs[n].data-id` 支持多个共享 Data Id 的配置
- B: 通过 `spring.cloud.nacos.config.extension-configs[n].data-id` 的方式支持多个扩展 Data Id 的配置
- C: 通过内部相关规则(应用名, 应用名+ Profile )自动生成相关的 Data Id 配置

当三种方式共同使用时, 他们的一个优先级关系是:A < B < C

## 配置自动更新

以下两种方式都可以实现自动更新:

* `@ConfigurationProperties`
* `@RefreshScope`

> 使用 `@RefreshScope` 刷新配置时会刷新 bean 是的生命周期.

