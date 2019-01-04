---
title: Spring与任务调度集成相关
date: 2018-12-02 14:23:13
categories: [Programming, Java, Spring Boot]
tags: [Spring Boot, Java, Scheduler]
---

![](https://cdn.yangbingdong.com/img/scheduler/scheduler-banner.jpg)

# Preface

> 本篇主要记录**任务调度**相关框架知识. 
>
> 任务调度这个在日常开发中非常经典, 比如每天固定时刻同步用户信息、或者是动态的活动开始与结束时间, 亦或者每天早上8点发条短信鼓励一下自己今天努力填坑之类的. . . 

<!--more-->

# Quartz

![](https://cdn.yangbingdong.com/img/scheduler/quartz-logo.jpg)

> ***[官方文档](http://www.quartz-scheduler.org/documentation/)***
>
> Quartz是一个功能丰富的开源作业调度库, 几乎可以集成在任何Java应用程序中 - 从最小的独立应用程序到最大的电子商务系统. Quartz可用于创建简单或复杂的计划, 以执行数十, 数百甚至数万个作业;将任务定义为标准Java组件的作业, 这些组件可以执行几乎任何可以编程的程序. Quartz Scheduler包含许多企业级功能, 例如支持JTA事务和集群. 

## 主要成员

- `Scheduler` - 与调度器交互的主要API. 
- `Job` - 需要被调度器调度的任务必须实现的接口. 
- `JobDetail` - 用于定义任务的实例. 
- `Trigger` - 用于定义调度器何时调度任务执行的组件. 
- `JobBuilder` - 用于定义或创建`JobDetail`的实例 . 
- `TriggerBuilder` - 用于定义或创建触发器实例. 

## 构建流程

- 定义`ScheduleFactory`, `Schedule`实例对象通过该工厂接口的实现类获取. 

- 定义`JobDetail`实例对象, 该对象需要指定名称、组和`Job`接口的`Class`信息. 

- 定义`Trigger`实例对象, 通过该对象设置触发任务的相关信息, 如起始时间、重复次数等. 

- 向`Schedule`中注册`JobDetail`和`Trigger`, 有两种方式: 

- - 通过`Schedule`的schedule方法注册, 此时它自动让`Trigger`和`JobDetail`绑定. 
  - 通过`addJob`和`scheduleJob`方法注册, 此时需要手动设置 `Trigger`的关联的`Job`组名和`Job`名称, 让`Trigger`和`JobDetail`绑定. 

- 启动调度器（调用`Schedule`对象的`start`方法）. 

## 运行模式

![](http://www.javarticles.com/wp-content/uploads/2016/03/MainComponents.png)



内部运行图: 

![](http://www.javarticles.com/wp-content/uploads/2016/03/QuartzSchedulerModel.png)

## 与Spring集成

在`Spring`中使用`Quartz`有两种方式实现: `MethodInvokingJobDetailFactoryBean`和`QuartzJobBean`. 其中`MethodInvokingJobDetailFactoryBean`不支持存储到数据库, 会报`java.io.NotSerializableException`. 

### xml方式声明Job

#### MethodInvokingJobDetailFactoryBean

先来看一下`MethodInvokingJobDetailFactoryBean`的方式（指定`targetObject`与`targetMethod`再通过反射调用）: 

```xml
<!-- 使用MethodInvokingJobDetailFactoryBean, 任务类可以不实现Job接口, 通过targetMethod指定调用方法-->
<bean id="taskJob" class="com.xxx.DataConversionTask"/>
<bean id="jobDetail" class="org.springframework.scheduling.quartz.MethodInvokingJobDetailFactoryBean">
    <property name="group" value="job_work"/>
    <property name="name" value="job_work_name"/>
    <!--false表示等上一个任务执行完后再开启新的任务-->
    <property name="concurrent" value="false"/>
    <!-- 指定bean -->
    <property name="targetObject">
        <ref bean="taskJob"/>
    </property>
    <!-- 指定执行方法 -->
    <property name="targetMethod">
        <value>run</value>
    </property>
</bean>
```

#### QuartzJobBean

一般很少会使用上述方式, 一般是使用`QuartzJobBean`: 

```xml
<bean name="redisKeySpaceMetricReportJob" class="org.springframework.scheduling.quartz.JobDetailFactoryBean">
    <property name="jobClass" value="com.iba.boss.schedule.RedisKeySpaceMetricReportScheduleJob"/>
    <property name="durability" value="true" />
    <!-- 向jobDataMap中注入依赖, Spring会通过反射将这些属性注入到RedisKeySpaceMetricReportScheduleJob中 -->
    <property name="jobDataMap">
        <map>
            <entry key="contextUtil" value-ref="applicationContextUtil" />
            <!-- 定时任务执行开关 -->
            <entry key="isOpen" value="true"></entry>
        </map>
    </property>
</bean>
<bean id="redisMetricReportTrigger" class="org.springframework.scheduling.quartz.CronTriggerFactoryBean">
    <property name="jobDetail" ref="redisKeySpaceMetricReportJob" />
    <property name="cronExpression" value="0 30 9 * * ?" />
</bean>
<bean id="schedulerFactoryBean"
    class="org.springframework.scheduling.quartz.SchedulerFactoryBean">
    <property name="triggers">
        <list>
            <ref bean="redisMetricReportTrigger"/>
        </list>
    </property>
</bean> 
```

```java
public class RedisKeySpaceMetricReportScheduleJob extends QuartzJobBean {
    private Boolean isOpen;
    private ApplicationContext context;
    @Override
    protected void executeInternal(JobExecutionContext ctx) {
        if (!isOpen) {
            return;
        }
		// Do something
    }

    public void setIsOpen(Boolean isOpen) {
        this.isOpen = isOpen;
    }

    public void setContextUtil(ApplicationContextUtil contextUtil){
        this.context = contextUtil.getContext();
    }
}
```

### JobFactory

Quartz是通过`JobFactory#newJob()`接口返回`Job`实例的, 默认实现`SimpleJobFactory`是通过`jobClass.newInstance()`反射构建实例的. 

在Spring中, 也是类似地通过反射构建`Job`实例, 不同的是在此实例上做了扩展（注入Spring Bean）. 

`AdaptableJobFactory`只是简单地通过反射构建`Job`, `SpringBeanJobFactory`继承`AdaptableJobFactory`并重写`createJobInstance`方法, 把`jobDataMap`跟`triggerDataMap`中的`bean`注入到`Job`实例当中: 

```java
	@Override
	protected Object createJobInstance(TriggerFiredBundle bundle) throws Exception {
		Object job = super.createJobInstance(bundle);
		BeanWrapper bw = PropertyAccessorFactory.forBeanPropertyAccess(job);
		if (isEligibleForPropertyPopulation(bw.getWrappedInstance())) {
			MutablePropertyValues pvs = new MutablePropertyValues();
			if (this.schedulerContext != null) {
				pvs.addPropertyValues(this.schedulerContext);
			}
			pvs.addPropertyValues(getJobDetailDataMap(bundle));
			pvs.addPropertyValues(getTriggerDataMap(bundle));
			if (this.ignoredUnknownProperties != null) {
				for (String propName : this.ignoredUnknownProperties) {
					if (pvs.contains(propName) && !bw.isWritableProperty(propName)) {
						pvs.removePropertyValue(propName);
					}
				}
				bw.setPropertyValues(pvs);
			}
			else {
				bw.setPropertyValues(pvs, true);
			}
		}
		return job;
	}
```

其中`isEligibleForPropertyPopulation()`: 

```java
	protected boolean isEligibleForPropertyPopulation(Object jobObject) {
		return (!(jobObject instanceof QuartzJobBean));
	}
```

所以要获得注入`bean`的支持, 有两步, 第一继承`QuartzJobBean`, 在构建`JobDetail`时在`jobDataMap`中注入Spring Bean. 

不过这种方法也有缺点, 理论上我们是不应该关注`Job`中依赖了哪些Spring Bean, 这样耦合度太大. 所以在Spring Boot中已经优化掉了这一点. 

## Spring Boot自动配置

在Spring Boot 中通过`QuartzAutoConfiguration`自动配置Quartz相关类并对`SpringBeanJobFactory`进行了扩展: 

```java
class AutowireCapableBeanJobFactory extends SpringBeanJobFactory {

	private final AutowireCapableBeanFactory beanFactory;

	AutowireCapableBeanJobFactory(AutowireCapableBeanFactory beanFactory) {
		Assert.notNull(beanFactory, "Bean factory must not be null");
		this.beanFactory = beanFactory;
	}

	@Override
	protected Object createJobInstance(TriggerFiredBundle bundle) throws Exception {
		Object jobInstance = super.createJobInstance(bundle);
		this.beanFactory.autowireBean(jobInstance);
		this.beanFactory.initializeBean(jobInstance, null);
		return jobInstance;
	}

}
```

这样我们只需要在`Job`实现类中用`@Autowired`或`@Resource`注解声明需要注入的Spring Bean即可. 

Spring Boot提供`SchedulerFactoryBeanCustomizer`定制`SchedulerFactoryBean`, 比如换一个`JobFactory`（从Spring IoC容器中获取无状态`Job`）: 

```java
@Component
public class QuartzScheduleFactoryBeanCustomizer implements SchedulerFactoryBeanCustomizer {

	@Resource
	private CustomizedActivitySchedulerFactory customizedSchedulerFactory;

	@Override
	public void customize(SchedulerFactoryBean schedulerFactoryBean) {
		schedulerFactoryBean.setJobFactory(customizedSchedulerFactory);
	}
}
```

```java
@Component
public class CustomizedActivitySchedulerFactory implements JobFactory, ApplicationContextAware {

	private ApplicationContext applicationContext;


	@Override
	public Job newJob(TriggerFiredBundle bundle, Scheduler scheduler) {
		return applicationContext.getBean(bundle.getJobDetail().getJobClass());
	}

	@Override
	public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
		this.applicationContext = applicationContext;
	}
}
```

## Job的增删改

```java
/**
 * @author ybd
 * @date 18-11-22
 * @contact yangbingdong1994@gmail.com
 */
public class SpringQuartzJobTemplate implements ScheduleJobOperations, InitializingBean {

    private static final Logger log = LoggerFactory.getLogger(SpringQuartzJobTemplate.class);

	@Autowired(required = false)
    @Qualifier("customizedSchedulerFactoryBean")
	private SchedulerFactoryBean schedulerFactoryBean;

	private Scheduler scheduler;

    @Override
    public void addOrUpdateScheduleJob(BaseJobDetail baseJobDetail) {
        try {
            TriggerKey triggerKey = parseTriggerKey(baseJobDetail);
            JobKey jobKey = parseJobKey(baseJobDetail);
            boolean jobExists = scheduler.checkExists(jobKey);
            boolean triggerExists = scheduler.checkExists(triggerKey);
            CronScheduleBuilder cronScheduleBuilder = CronScheduleBuilder.cronSchedule(baseJobDetail.getCron());
            CronTrigger cronTrigger = TriggerBuilder.newTrigger()
                                                    .withIdentity(triggerKey)
                                                    .withSchedule(cronScheduleBuilder)
                                                    .build();
            if (!jobExists && !triggerExists) {
                JobDetail jobDetail = buildJobDetail(baseJobDetail, jobKey);
                scheduler.scheduleJob(jobDetail, cronTrigger);
            } else if (jobExists && triggerExists) {
                if (baseJobDetail.getJobDataMap() != null) {
                    JobDetail jobDetail = buildJobDetail(baseJobDetail, jobKey);
                    scheduler.addJob(jobDetail, true, true);
                }
                scheduler.rescheduleJob(triggerKey, cronTrigger);
            } else {
                throw new ScheduleJobException("Illegal state -> jobExists: " + jobExists + ", triggerExists: " + triggerExists);
            }
        } catch (Exception e) {
            throw new ScheduleJobException(e);
        }
    }

    private JobDetail buildJobDetail(BaseJobDetail baseJobDetail, JobKey jobKey) throws ClassNotFoundException {
        Class<? extends Job> jobClass = Class.forName(baseJobDetail.getJobClass()).asSubclass(Job.class);
        JobDetail jobDetail = JobBuilder.newJob(jobClass)
                                        .withIdentity(jobKey)
                                        .build();
        if (baseJobDetail.getId() != null) {
            jobDetail.getJobDataMap().put(JOB_DETAIL_ID_KEY, baseJobDetail.getId());
        }
        if (baseJobDetail.getJobDataMap() != null) {
            jobDetail.getJobDataMap().putAll(baseJobDetail.getJobDataMap());
        }
        return jobDetail;
    }

    @Override
    public void deleteScheduleJob(BaseJobDetail baseJobDetail) {
        try {
            TriggerKey triggerKey = parseTriggerKey(baseJobDetail);
            if (scheduler.checkExists(triggerKey)) {
                scheduler.pauseTrigger(triggerKey);
                scheduler.unscheduleJob(triggerKey);
                JobKey jobKey = parseJobKey(baseJobDetail);
                if (scheduler.checkExists(jobKey)) {
                    scheduler.deleteJob(parseJobKey(baseJobDetail));
                }
                log.info("Success [CREATE] quartz job: " + triggerKey.toString());
            } else {
                log.info("Fail to [DELETE] schedule job, job not exist: " + triggerKey);
            }
        } catch (SchedulerException e) {
            throw new ScheduleJobException(e);
        }
    }

	@Override
	public void trigger(BaseJobDetail baseJobDetail) {
		try {
            JobKey jobKey = parseJobKey(baseJobDetail);
            if (scheduler.checkExists(jobKey)) {
                scheduler.triggerJob(jobKey);
            } else {
                JobDetail jobDetail = buildJobDetail(baseJobDetail, jobKey);
                scheduler.addJob(jobDetail, false, true);
                scheduler.triggerJob(jobKey);
            }
		} catch (Exception e) {
			throw new ScheduleJobException(e);
		}
	}

	@Override
	public void afterPropertiesSet() {
		this.scheduler = schedulerFactoryBean.getScheduler();
	}

	private TriggerKey parseTriggerKey(BaseJobDetail baseJobDetail) {
        requireNameAndGroupNonNull(baseJobDetail);
        return TriggerKey.triggerKey(baseJobDetail.getJobName(), baseJobDetail.getJobGroup());
	}

    private JobKey parseJobKey(BaseJobDetail baseJobDetail) {
        requireNameAndGroupNonNull(baseJobDetail);
        return JobKey.jobKey(baseJobDetail.getJobName(), baseJobDetail.getJobGroup());
    }

    private void requireNameAndGroupNonNull(BaseJobDetail baseJobDetail) {
        requireNonNull(baseJobDetail.getJobName());
        requireNonNull(baseJobDetail.getJobGroup());
    }
}
```

信息类: 

```java
@Data
public class BaseJobDetail {
    /**
     * field comment: 主键
     */
    private Long id;

    /**
     * field comment: 任务组
     */
    private String jobGroup;

    /**
     * field comment: 任务名
     */
    private String jobName;

    /**
     * field comment: 任务类
     */
    private String jobClass;

    /**
     * field comment: cron表达式
     */
    private String cron;

    /**
     * field comment: 冗余, cron表达式对应执行时间
     */
    private Date cronTime;

    /**
     * field comment: 触发次数
     */
    private Integer fireTimes;

    /**
     * field comment: 最后一次触发时间
     */
    private Date lastFireTime;

    /**
     * field comment: 最后一次触发的任务耗时, 单位: 毫秒
     */
    private Long lastFireConsume;

    /**
     * field comment: 状态, 0:待执行 1:已执行 2:已取消 3:执行异常
     */
    private Byte status;

    /**
     * field comment: 作业数据
     */
    private String jobData;

    /**
     * field comment: 创建时间
     */
    private Date createTime;

    /**
     * field comment: 更新时间
     */
    private Date updateTime;

    private transient Map<String, ?> jobDataMap;

    public BaseJobDetail incrFireTimes() {
        fireTimes++;
        return this;
    }

    public BaseJobDetail withJobData(Object jobData) {
        return setJobData(BaseJobData.of(jobData).toJsonString());
    }

    public static BaseJobDetail of(String jobGroup, String jobName, Class<? extends Job> jobClass, Date cronTime) {
        return new BaseJobDetail().setCron(DateUtil.parseToCron(cronTime))
                                  .setCronTime(cronTime)
                                  .setJobGroup(jobGroup)
                                  .setJobName(jobName)
                                  .setJobClass(jobClass.getName());
    }

    @Data
    public static class BaseJobData {
        private Class dataClass;
        private JSON jsonData;

        public static BaseJobData resolve(String jsonData) {
            return parseObject(jsonData, BaseJobData.class);
        }

        public static BaseJobData of(Object data) {
            return new BaseJobData().setDataClass(data.getClass())
                                    .setJsonData((JSON) toJSON(data));
        }

        @SuppressWarnings("unchecked")
        public <T> T parseData() {
            return (T) parseObject(this.jsonData.toJSONString(), this.dataClass);
        }

        public String toJsonString() {
            return toJSONString(this);
        }
    }
}

```

## 其他问题

### Durability

当设置了`JobDetail.setDurability(true)`, 当`job`不再有`trigger`引用它的时候, `Quartz`也不要删除`job`. 

### Misfire

由于某些原因（比如Worker线程池满了）导致任务没有及时执行, 此时扫描Misfire的线程就会把它们找出来并按照Misfire指令处理这个任务. 比如`CronTrigger`的默认策略是`CronTrigger.MISFIRE_INSTRUCTION_FIRE_ONCE_NOW`,也可以自己指定: 

```java
CronScheduleBuilder cronScheduleBuilder = CronScheduleBuilder.cronSchedule(scheduleJobInfo.getCron()).withMisfireHandlingInstructionDoNothing();
TriggerKey oldTriggerKey = parseTriggerKey(scheduleJobInfo);
CronTrigger newTrigger = TriggerBuilder.newTrigger()
										.withIdentity(oldTriggerKey)
										.withSchedule(cronScheduleBuilder)
										.build();
scheduler.rescheduleJob(oldTriggerKey, newTrigger);
```

### maxBatchSize

一次拉取trigger的最大数量, 默认是1, 可通过`org.quartz.scheduler.batchTriggerAcquisitionMaxCount`改写. 但是在集群环境下, 不建议设置为很大值. 如果值 > 1, 并且使用了 JDBC JobStore的话, `org.quartz.jobStore.acquireTriggersWithinLock`属性必须设置为`true`, 以避免”弄脏”数据. 

> 更多参数配置: ***[https://blog.csdn.net/zixiao217/article/details/53091812](https://blog.csdn.net/zixiao217/article/details/53091812)***

### 性能问题

由于Quartz的集群是通过底层调度依赖数据库的悲观锁, 谁先抢到谁调度, 这样会导致节点负载不均衡, 并且影响性能. 

# Spring Scheduler

> Spring Scheduler相对Quartz来说比较轻量级, 通过简单的配置就可以使用了, 但灵活度不如Quartz

## 开启配置

### Xml方式

```xml
<task:scheduler id="scheduler" pool-size="50"/>
```

- 如果不设置`pool-size`, 默认是1, 会导致任务单线程执行. 

### Java配置方式

```java
@Configuration
@EnableScheduling
public class SpringScheduleConfig implements SchedulingConfigurer {

	@Override
	public void configureTasks(ScheduledTaskRegistrar taskRegistrar) {
		taskRegistrar.setScheduler(taskExecutor());
	}
	
	@Bean
	public Executor taskExecutor() {
		return new ScheduledThreadPoolExecutor(4,
				new BasicThreadFactory
						.Builder()
						.namingPattern("schedule-pool-thread-%d")
						.build());
	}
}

```

* `@EnableScheduling`表示告诉Spring开启Scheduler
* 实现`SchedulingConfigurer`是为了配置线程池

## 使用

### Xml方式

```xml
<task:scheduled-tasks scheduler="myScheduler">
    <task:scheduled ref="doSomethingTask" method="doSomething" cron="0 * * * * *"/>
</task:scheduled-tasks>
```

```java
@Component
public class DoSomethingTask {
    @Scheduled(cron="0 * * * * *")
    public void doSomething() {
        System.out.println("do something");
    }
}
```

### 注解声明方式

使用`@Scheduled`可以非常简单地就声明一个任务: 

```java
@Component
public class DoSomethingTask {
    @Scheduled(cron="0 * * * * *")
    public void doSomething() {
        System.out.println("do something");
    }
}
```

`@Scheduled`有几个参数: 

- `cron`: cron表达式, 指定任务在特定时间执行；

- `fixedDelay`: 表示上一次任务执行完成后多久再次执行, 参数类型为long, 单位ms；

- `fixedDelayString`: 与`fixedDelay`含义一样, 只是参数类型变为String；

- `fixedRate`: 表示按一定的频率执行任务, 参数类型为long, 单位ms；

- `fixedRateString`: 与`fixedRate`的含义一样, 只是将参数类型变为String；

- `initialDelay`: 表示延迟多久再第一次执行任务, 参数类型为long, 单位ms；

- `initialDelayString`: 与`initialDelay`的含义一样, 只是将参数类型变为String；

- `zone`: 时区, 默认为当前时区, 一般没有用到. 

# Cron表达式

想了解Cron最好的方法是看***[Quartz的官方文档](http://www.quartz-scheduler.org/documentation/quartz-2.2.x/tutorials/crontrigger)***. 本节也会大致介绍一下. 

Cron表达式由6~7项组成, 中间用空格分开. 从左到右依次是: 秒、分、时、日、月、周几、年（可省略）. 值可以是数字, 也可以是以下符号: 
`*`: 所有值都匹配
`?`: 无所谓, 不关心, 通常放在“周几”里
`,`: 或者
`/`: 增量值
`-`: 区间

下面举几个例子, 看了就知道了: 
`0 * * * * *`: 每分钟（当秒为0的时候）
`0 0 * * * *`: 每小时（当秒和分都为0的时候）
`*/10 * * * * *`: 每10秒
`0 5/15 * * * *`: 每小时的5分、20分、35分、50分
`0 0 9,13 * * *`: 每天的9点和13点
`0 0 8-10 * * *`: 每天的8点、9点、10点
`0 0/30 8-10 * * *`: 每天的8点、8点半、9点、9点半、10点
`0 0 9-17 * * MON-FRI`: 每周一到周五的9点、10点…直到17点（含）
`0 0 0 25 12 ?`: 每年12约25日圣诞节的0点0分0秒（午夜）
`0 30 10 * * ? 2016`: 2016年每天的10点半

其中的`?`在用法上其实和`*`是相同的. 但是`*`语义上表示全匹配, 而`?`并不代表全匹配, 而是不关心. 比如对于`0 0 0 5 8 ? 2016`来说, 2016年8月5日是周五, `?`表示我不关心它是周几. 而`0 0 0 5 8 * 2016`中的`*`表示周一也行, 周二也行……语义上和2016年8月5日冲突了, 你说谁优先生效呢. 

不记得也没关系, 记住***[Cron Maker](http://www.cronmaker.com/)***也可以, 它可以在线生成cron表达式. 

# 时间轮

> ***[https://github.com/ifesdjeen/hashed-wheel-timer](https://github.com/ifesdjeen/hashed-wheel-timer)***

# 分布式任务调度

> ***[Elastic Job](http://elasticjob.io/)***