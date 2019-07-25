# Spring Data JPA 拾遗

![](https://cdn.yangbingdong.com/img/spring-boot-orm/jpa-logo.png)

# 结构图

![](https://cdn.yangbingdong.com/img/spring-boot-orm/jpa-struct.png)

# 配置

```yaml
spring:
  jpa:
    generate-ddl: false
    show-sql: true # 打印SQL
    hibernate:
      ddl-auto: create # create、create-drop、update、validate、none
      naming:
#        physical-strategy: com.example.MyPhysicalNamingStrategy
#    properties:
#      hibernate:
#        dialect: org.hibernate.dialect.MySQL5Dialect  # 方言设置，默认就为MySQL5Dialect，或者MySQL5InnoDBDialect使用InnoDB引擎
```

## 默认驼峰模式

Spring Data Jpa 使用的默认策略是 `SpringPhysicalNamingStrategy` 与 `SpringImplicitNamingStrategy`, 就是驼峰模式的实现.

可以这样修改命名策略：

```properties
#PhysicalNamingStrategyStandardImpl
spring.jpa.hibernate.naming.physical-strategy=org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl
```

如果需要指定某个字段不使用驼峰模式可以直接使用`@Column(name = "aaa")`

# 基础CRUD操作

集成 `JpaRepository<T, ID>` , T为实体, ID为实体id:

```java
public interface UserRepository extends JpaRepository<User, Long> {
	Page<User> findByName(String name, Pageable pageable);
}
```

Controller:

```java
@Autowired
private UserRepository userRepository;

@GetMapping
public Iterable<User> getAllUsers() {
	return userRepository.findAll();
}

@PostMapping
public void addNewUser(@Valid @RequestBody User user) {
	userRepository.save(user);
}

/**
 * 验证排序和分页查询方法，Pageable的默认实现类：PageRequest
 * @return
 */
@GetMapping(path = "/page")
@ResponseBody
public Page<User> getAllUserByPage() {
	return userRepository.findAll(PageRequest.of(0, 2, Sort.by(new Sort.Order(Sort.Direction.ASC,"name"))));
}
/**
 * 排序查询方法，使用Sort对象
 * @return
 */
@GetMapping(path = "/sort")
@ResponseBody
public Iterable<User> getAllUsersWithSort() {
	return userRepository.findAll(Sort.by(new Sort.Order(Sort.Direction.ASC,"name")));
}
```

![](https://cdn.yangbingdong.com/img/spring-boot-orm/simple-jpa-repository-method.png)

`JpaRepository` 的默认实现类是 `SimpleJpaRepository`, 可以看到提供了大部分通用的方法.

# 定义查询方法

## 方法的查询策略设置

通过下面的命令来配置方法的查询策略(在`JpaRepositoriesAutoConfigureRegistrar`中已经自动配置, 实际Spring Boot项目中我们只需要引入JPA依赖即可, 不需要手动显示配置)：

```java
@EnableJpaRepositories(queryLookupStrategy= QueryLookupStrategy.Key.CREATE_IF_NOT_FOUND)
```

`QueryLookupStrategy.Key` 的值一共就三个：

- `Create`：直接根据方法名进行创建，规则是根据方法名称的构造进行尝试，一般的方法是从方法名中删除给定的一组已知前缀，并解析该方法的其余部分。如果方法名不符合规则，启动的时候会报异常。
- `USE_DECLARED_QUERY`：声明方式创建，即本书说的注解的方式。启动的时候会尝试找到一个声明的查询，如果没有找到将抛出一个异常，查询可以由某处注释或其他方法声明。
- `CREATE_IF_NOT_FOUND`：这个是默认的，以上两种方式的结合版。先用声明方式进行查找，如果没有找到与方法相匹配的查询，那用 Create 的方法名创建规则创建一个查询。

## 查询方法的创建

Spring Data 中有一套自己的方法命名查询规范, 一般是前缀 find…By、read…By、query…By、count…By 和 get…By等, `org.springframework.data.repository.query.parser.PartTree`:

![](https://cdn.yangbingdong.com/img/spring-boot-orm/part-tree-class.png)

![](https://cdn.yangbingdong.com/img/spring-boot-orm/subject-class.png)

Ex:

```java
interface PersonRepository extends Repository<User, Long> {
   // and的查询关系
   List<User> findByEmailAddressAndLastname(EmailAddress emailAddress, String lastname);
   // 包含distinct去重，or的sql语法
   List<User> findDistinctPeopleByLastnameOrFirstname(String lastname, String firstname);
   List<User> findPeopleDistinctByLastnameOrFirstname(String lastname, String firstname);
   // 根据lastname字段查询忽略大小写
   List<User> findByLastnameIgnoreCase(String lastname);
   // 根据lastname和firstname查询equal并且忽略大小写
   List<User> findByLastnameAndFirstnameAllIgnoreCase(String lastname, String firstname); 
  // 对查询结果根据lastname排序
   List<User> findByLastnameOrderByFirstnameAsc(String lastname);
   List<User> findByLastnameOrderByFirstnameDesc(String lastname);
}
```

使用的时候要配合不同的返回结果进行使用:

```java
interface UserRepository extends CrudRepository<User, Long> {
     long countByLastname(String lastname);//查询总数
     long deleteByLastname(String lastname);//根据一个字段进行删除操作
     List<User> removeByLastname(String lastname);
}
```

##方法命名查询关键字列表

| Keyword             | Sample                                                       | JPQL snippet                                                 |
| ------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `And`               | `findByLastnameAndFirstname`                                 | `… where x.lastname = ?1 and x.firstname = ?2`               |
| `Or`                | `findByLastnameOrFirstname`                                  | `… where x.lastname = ?1 or x.firstname = ?2`                |
| `Is,Equals`         | `findByFirstname`,`findByFirstnameIs`,`findByFirstnameEquals` | `… where x.firstname = ?1`                                   |
| `Between`           | `findByStartDateBetween`                                     | `… where x.startDate between ?1 and ?2`                      |
| `LessThan`          | `findByAgeLessThan`                                          | `… where x.age < ?1`                                         |
| `LessThanEqual`     | `findByAgeLessThanEqual`                                     | `… where x.age <= ?1`                                        |
| `GreaterThan`       | `findByAgeGreaterThan`                                       | `… where x.age > ?1`                                         |
| `GreaterThanEqual`  | `findByAgeGreaterThanEqual`                                  | `… where x.age >= ?1`                                        |
| `After`             | `findByStartDateAfter`                                       | `… where x.startDate > ?1`                                   |
| `Before`            | `findByStartDateBefore`                                      | `… where x.startDate < ?1`                                   |
| `IsNull`            | `findByAgeIsNull`                                            | `… where x.age is null`                                      |
| `IsNotNull,NotNull` | `findByAge(Is)NotNull`                                       | `… where x.age not null`                                     |
| `Like`              | `findByFirstnameLike`                                        | `… where x.firstname like ?1`                                |
| `NotLike`           | `findByFirstnameNotLike`                                     | `… where x.firstname not like ?1`                            |
| `StartingWith`      | `findByFirstnameStartingWith`                                | `… where x.firstname like ?1`(parameter bound with appended `%`) |
| `EndingWith`        | `findByFirstnameEndingWith`                                  | `… where x.firstname like ?1`(parameter bound with prepended `%`) |
| `Containing`        | `findByFirstnameContaining`                                  | `… where x.firstname like ?1`(parameter bound wrapped in `%`) |
| `OrderBy`           | `findByAgeOrderByLastnameDesc`                               | `… where x.age = ?1 order by x.lastname desc`                |
| `Not`               | `findByLastnameNot`                                          | `… where x.lastname <> ?1`                                   |
| `In`                | `findByAgeIn(Collection<Age> ages)`                          | `… where x.age in ?1`                                        |
| `NotIn`             | `findByAgeNotIn(Collection<Age> ages)`                       | `… where x.age not in ?1`                                    |
| `True`              | `findByActiveTrue()`                                         | `… where x.active = true`                                    |
| `False`             | `findByActiveFalse()`                                        | `… where x.active = false`                                   |
| `IgnoreCase`        | `findByFirstnameIgnoreCase`                                  | `… where UPPER(x.firstame) = UPPER(?1)`                      |

最全支持关键字可查看: `org.springframework.data.repository.query.parser.Type`

## 查询结果的处理

### 参数选择（Sort/Pageable）分页和排序

```java
Page<User> findByLastname(String lastname, Pageable pageable);
Slice<User> findByLastname(String lastname, Pageable pageable);
List<User> findByLastname(String lastname, Sort sort);
List<User> findByLastname(String lastname, Pageable pageable);		
```

### 限制查询结果

在查询方法上加限制查询结果的关键字 First 和 Top:

```java
User findFirstByOrderByLastnameAsc();
User findTopByOrderByAgeDesc();
Page<User> queryFirst10ByLastname(String lastname, Pageable pageable);
Slice<User> findTop3ByLastname(String lastname, Pageable pageable);
List<User> findFirst10ByLastname(String lastname, Sort sort);
List<User> findTop10ByLastname(String lastname, Pageable pageable);
```

### 查询结果的不同形式（List/Stream/Page/Future）

```java
@Query("select u from User u")
Stream<User> findAllByCustomQueryAndStream();
Stream<User> readAllByFirstnameNotNull();
@Query("select u from User u")
Stream<User> streamAllPaged(Pageable pageable);
```

关闭流:

```java
Stream<User> stream;
try {
   stream = repository.findAllByCustomQueryAndStream()
   stream.forEach(…);
} catch (Exception e) {
   e.printStackTrace();
} finally {
   if (stream!=null){
      stream.close();
   }
}
```

异步结果:

```java
@Async
Future<User> findByFirstname(String firstname); 
@Async
CompletableFuture<User> findOneByFirstname(String firstname); 
@Async
ListenableFuture<User> findOneByLastname(String lastname);
```
支持的返回结果:

| 返回值类型          | 描述                                                         |
| ------------------- | ------------------------------------------------------------ |
| `void`              | 不返回结果，一般是更新操作                                   |
| `Primitives`        | Java 的基本类型，一般常见的是统计操作（如 `long`、`boolean` 等）Wrapper types Java 的包装类 |
| `T`                 | 最多只返回一个实体，没有查询结果时返回 null。如果超过了一个结果会抛出 `IncorrectResultSizeDataAccessException` 的异常。 |
| `Iterator`          | 一个迭代器                                                   |
| `Collection`        | 集合                                                         |
| `List`              | `List` 及其任何子类                                          |
| `Optional`          | 返回 Java 8 或 Guava 中的 `Optional` 类。查询方法的返回结果最多只能有一个，如果超过了一个结果会抛出 `IncorrectResultSizeDataAccessException` 的异常 |
| `Option`            | Scala 或者 javaslang 选项类型                                |
| `Stream`            | Java 8 Stream                                                |
| `Future`            | Future，查询方法需要带有 `@Async` 注解，并**开启 Spring 异步执行方法的功能**。一般配合多线程使用。关系数据库，实际工作很少有用到. |
| `CompletableFuture` | 返回 Java8 中新引入的 `CompletableFuture` 类，查询方法需要带有 `@Async` 注解，并开启 Spring 异步执行方法的功能 |
| `ListenableFuture`  | 返回 `org.springframework.util.concurrent.ListenableFuture` 类，查询方法需要带有 `@Async` 注解，并开启 Spring 异步执行方法的功能 |
| `Slice`             | 返回指定大小的数据和是否还有可用数据的信息。需要方法带有 `Pageable` 类型的参数 |
| `Page`              | 在 `Slice` 的基础上附加返回分页总数等信息。需要方法带有 `Pageable` 类型的参数 |
| `GeoResult`         | 返回结果会附带诸如到相关地点距离等信息                       |
| `GeoResults`        | 返回 `GeoResult` 的列表，并附带到相关地点平均距离等信息      |
| `GeoPage`           | 分页返回 `GeoResult`，并附带到相关地点平均距离等信息         |

### 实现机制

通过 `QueryExecutorMethodInterceptor` 这个类的源代码，我们发现，该类实现了 MethodInterceptor 接口，也就是说它是一个方法调用的拦截器， 当一个 Repository 上的查询方法，譬如说 findByEmailAndLastname 方法被调用，Advice 拦截器会在方法真正的实现调用前，先执行这个 MethodInterceptor 的 invoke 方法。这样我们就有机会在真正方法实现执行前执行其他的代码了。

然而对于 `QueryExecutorMethodInterceptor` 来说，最重要的代码并不在 invoke 方法中，而是在它的构造器 `QueryExecutorMethodInterceptor(RepositoryInformationr、Object customImplementation、Object target)` 中。

最重要的一段代码是这段：

```java
for (Method method : queryMethods) { 
     // 使用lookupStrategy，针对Repository接口上的方法查询Query
     RepositoryQuery query = lookupStrategy.resolveQuery(method, repositoryInformation, factory, namedQueries); invokeListeners(query);
     queries.put(method, query);
}
```

![](https://cdn.yangbingdong.com/img/spring-boot-orm/jpa-defining-query-method-processing.png)

# 注解查询

## @Query

```java
public @interface Query {
   /**
    * 指定JPQL的查询语句。（nativeQuery=true的时候，是原生的Sql语句）
    */
   String value() default "";
   /**
    * 指定count的JPQL语句，如果不指定将根据query自动生成。
    * （如果当nativeQuery=true的时候，指的是原生的Sql语句）
    */
   String countQuery() default "";
   /**
    * 根据哪个字段来count，一般默认即可。
    */
   String countProjection() default "";
   /**
    * 默认是false，表示value里面是不是原生的sql语句
    */
   boolean nativeQuery() default false;
   /**
    * 可以指定一个query的名字，必须唯一的。
    * 如果不指定，默认的生成规则是：
    * {$domainClass}.${queryMethodName}
    */
   String name() default "";
   /*
    * 可以指定一个count的query的名字，必须唯一的。
    * 如果不指定，默认的生成规则是：
    * {$domainClass}.${queryMethodName}.count
    */
   String countName() default "";
}
```

### 用法

```java
public interface UserRepository extends JpaRepository<User, Long>{
  @Query("select u from User u where u.emailAddress = ?1")
  User findByEmailAddress(String emailAddress);
    
  @Query("select u from User u where u.firstname like %?1")
  List<User> findByFirstnameEndsWith(String firstname);
}	
```

原生SQL:

```java
public interface UserRepository extends JpaRepository<User, Long> {
  @Query(value = "SELECT * FROM USERS WHERE EMAIL_ADDRESS = ?1", nativeQuery = true)
  User findByEmailAddress(String emailAddress);
    
  @Query(value = "select * from user_info where first_name=?1 order by ?2",nativeQuery = true)
}
```

**注意:** `nativeQuery` 不支持直接 `Sort` 的参数查询, 需要类似上面一样使用原生的`order by`。

### 排序

`@Query` 的 JPQL 情况下，想实现排序，方法上面直接用 `PageRequest` 或者直接用 `Sort` 参数都可以做到。

在排序实例中实际使用的属性需要与**实体模型里面的字段相匹配**，这意味着它们需要解析为查询中使用的属性或别名。这是一个`state_field_path_expression JPQL`定义，并且 Sort 的对象支持一些特定的函数。

```java
public interface UserRepository extends JpaRepository<User, Long> {
  @Query("select u from User u where u.lastname like ?1%")
  List<User> findByAndSort(String lastname, Sort sort);
  @Query("select u.id, LENGTH(u.firstname) as fn_len from User u where u.lastname like ?1%")
  List<Object[]> findByAsArrayAndSort(String lastname, Sort sort);
}
//调用方的写法，如下：
repo.findByAndSort("lannister", new Sort("firstname"));               
repo.findByAndSort("stark", new Sort("LENGTH(firstname)"));          
repo.findByAndSort("targaryen", JpaSort.unsafe("LENGTH(firstname)"));
repo.findByAsArrayAndSort("bolton", new Sort("fn_len"));  
```

### 分页

直接用 Page 对象接受接口，参数直接用 `Pageable` 的实现类即可。

```java
public interface UserRepository extends JpaRepository<User, Long> {
  @Query(value = "select u from User u where u.lastname = ?1")
  Page<User> findByLastname(String lastname, Pageable pageable);
}
//调用者的写法
repository.findByFirstName("jackzhang",new PageRequest(1,10));
```

对原生 SQL 的分页支持，案例如下，但是支持的不是特别友好，以 MySQL 为例。

```java
 public interface UserRepository extends JpaRepository<UserInfoEntity, Integer>, JpaSpecificationExecutor<UserInfoEntity> {
   @Query(value = "select * from user_info where first_name=?1 /* #pageable# */",
         countQuery = "select count(*) from user_info where first_name=?1",
         nativeQuery = true)
   Page<UserInfoEntity> findByFirstName(String firstName, Pageable pageable);
}
//调用者的写法
return userRepository.findByFirstName("jackzhang",new PageRequest(1,10, Sort.Direction.DESC,"last_name"));
//打印出来的sql
select  *   from  user_info  where  first_name=? /* #pageable# */  order by  last_name desc limit ?, ?
```

## @Param

默认情况下，参数是**通过顺序**绑定在查询语句上的，这使得查询方法**对参数位置的重构**容易出错。为了解决这个问题，可以使用 `@Param` 注解指定方法参数的具体名称，通过绑定的参数名字做查询条件，这样不需要关心参数的顺序，推荐这种做法，比较利于代码重构。

```java
public interface UserRepository extends JpaRepository<User, Long> {
  @Query("select u from User u where u.firstname = :firstname or u.lastname = :lastname")
  User findByLastnameOrFirstname(@Param("lastname") String lastname,
                                 @Param("firstname") String firstname);
}
```

根据参数进行查询，top 10 前面说的 query method 关键字照样有用，如下：

```java
public interface UserRepository extends JpaRepository<User, Long> {
  @Query("select u from User u where u.firstname = :firstname or u.lastname = :lastname")
  User findTop10ByLastnameOrFirstname(@Param("lastname") String lastname,
                                 @Param("firstname") String firstname);
}
```

> 提醒：大家通过 @Query 定义自己的查询方法时，建议也用 Spring Data JPA 的 name query 的命名方法，这样下来风格就比较统一了。

## Spel 表达式的支持

在 Spring Data JPA 1.4 以后，支持在 `@Query` 中使用 SpEL 表达式（简介）来接收变量。

SpEL 支持的变量

| 变量名       | 使用方式                         | 描述                                              |
| ------------ | -------------------------------- | ------------------------------------------------- |
| `entityName` | `select x from #{#entityName} x` | 根据指定的 Repository 自动插入相关的 `entityName` |

> 有两种方式能被解析出来：
>
> - 如果定了 `@Entity` 注解，直接用其属性名。
> - 如果没定义，直接用实体的类的名称。

在以下的例子中，我们在查询语句中插入表达式：

```java
@Entity("User")
public class User {
   @Id
   @GeneratedValue
   Long id;
   String lastname;
}
//Repository写法
public interface UserRepository extends JpaRepository<User, Long> {
   @Query("select u from #{#entityName} u where u.lastname = ?1")
   List<User> findByLastname(String lastname);
}
```

这个 SPEL 的支持，比较适合自定义的 Repository，如果想写一个通用的 Repository 接口，那么可以用这个表达式来处理：

```java
@MappedSuperclass
public abstract class AbstractMappedType {
   …
   String attribute;
}
@Entity
public class ConcreteType extends AbstractMappedType { …
}
@NoRepositoryBean
public interface MappedTypeRepository<T extends AbstractMappedType> extends Repository<T, Long> {
   @Query("select t from #{#entityName} t where t.attribute = ?1")
   List<T> findAllByAttribute(String attribute);
}
public interface ConcreteRepository extends MappedTypeRepository<ConcreteType> { …
}
```

`MappedTypeRepository` 作为一个公用的父类，自己的 Repository 可以继承它，当调用 `ConcreteRepository` 执行 `findAllByAttribute` 方法的时候执行结果如下：

```sql
select t from ConcreteType t where t.attribute = ?1
```

## @Modifying 修改查询

可以通过在 `@Modifying` 注解实现只需要参数绑定的 update 查询的执行，我们来看个例子根据 lastName 更新 firstname 并且返回更新条数如下：

```java
@Modifying
@Query("update User u set u.firstname = ?1 where u.lastname = ?2")
int setFixedFirstnameFor(String firstname, String lastname);
```

简单的针对某些特定属性的更新，也可以直接用基类里面提供的通用 save 来做更新（即继承 `CrudRepository` 接口）。

**还有第三种方法就是自定义 Repository 使用 EntityManager 来进行更新操作。**

对删除操作的支持如下：

```java
interface UserRepository extends Repository<User, Long> {
  void deleteByRoleId(long roleId);
  @Modifying
  @Query("delete from User u where user.role.id = ?1")
  void deleteInBulkByRoleId(long roleId);
}
```

所以现在我们一共有四种方式来做更新操作：

- 通过方法表达式；
- 还有一种就是 `@Modifying` 注解；
- `@Query` 注解也可以做到；
- 继承 `CrudRepository` 接口。

## @Query 的优缺点与实践

| 分类     | 描述                                                         |
| -------- | ------------------------------------------------------------ |
| 优点     | （1）可以灵活快速的使用 JPQL 和 SQL                          |
|          | （2）对返回的结果和字段记性自定义                            |
|          | （3）支持连表查询和对象关联查询，可以组合出来复杂的 SQL 或者 JPQL |
|          | （4）可以很好的表达你的查询思路                              |
|          | （5）灵活性非常强，快捷方便                                  |
| 缺点     | （1）不支持动态查询条件，参数个数如果是不固定的不支持        |
|          | （2）有些读者会将返回结果用 Map 或者 Object[] 数组接收结果，会导致调用此方法的开发人员不知道返回结果里面到底有些什么数据 |
| 最佳实践 | （1）当出现很复杂的 SQL 或者 JPQL 的时候建议用视图           |
|          | （2）返回结果一定要用对象接收，最好每个对象里面的字段和你返回的结果一一对应 |
|          | （3）动态的 Query Param 会在后面的章节中讲到                 |
|          | （4）能用 JPQL 的就不要用 SQL                                |

# 实例中的常用注解

> 更多注解请查看 `javax.persist` 包.

## @Entity

`@Entity` 用于定义对象将会成为被 JPA 管理的实体，将字段映射到指定的数据库表中

## @Table

`@Table` 用于指定数据库的表名：

```java
public @interface Table {
   //表的名字，可选。如果不填写，系统认为好实体的名字一样为表名。
   String name() default "";
   //此表的catalog，可选
   String catalog() default "";
   //此表所在schema，可选
   String schema() default "";
   //唯一性约束，只有创建表的时候有用，默认不需要。
   UniqueConstraint[] uniqueConstraints() default { };
   //索引，只有创建表的时候使用，默认不需要。
   Index[] indexes() default {};
}
```

## @Id

`@Id` 定义属性为数据库的主键，一个实体里面必须有一个，并且必须和 `@GeneratedValue` 配合使用和成对出现.

## @IdClass

`@IdClass` 利用外部类的联合主键。

## @Basic & @Transient

`@Basic` 表示属性是到数据库表的字段的映射。如果实体的字段上没有任何注解，默认即为 `@Basic`。`@Transient` 表示该属性并非一个到数据库表的字段的映射，表示非持久化属性。JPA 映射数据库的时候忽略它，与 `@Basic` 相反的作用。

## @Column

`@Column` 定义该属性对应数据库中的列名。

```java
public @interface Column {
    //数据库中的表的列名；可选，如果不填写认为字段名和实体属性名一样。
    String name() default "";
    //是否唯一。默认flase，可选。
    boolean unique() default false;
    //数据字段是否允许空。可选，默认true。
    boolean nullable() default true;
    //执行insert操作的时候是否包含此字段，默认，true，可选。
    boolean insertable() default true;
    //执行update的时候是否包含此字段，默认，true，可选。
    boolean updatable() default true;
    //表示该字段在数据库中的实际类型。
    String columnDefinition() default "";
   //数据库字段的长度，可选，默认255
    int length() default 255;
}
```

## @Temporal

`@Temporal` 用来设置 `Date` 类型的属性映射到对应精度的字段。

- `@Temporal(TemporalType.DATE)`映射为日期 // date （只有日期）
- `@Temporal(TemporalType.TIME)`映射为日期 // time （是有时间）
- `@Temporal(TemporalType.TIMESTAMP)`映射为日期 // date time （日期+时间）

## @Enumerated

`@Enumerated` 这个注解很好用，直接映射 `enum` 枚举类型的字段。

```java
public @interface Enumerated {
//枚举映射的类型，默认是ORDINAL（即枚举字段的下标）。
    EnumType value() default ORDINAL;
}
public enum EnumType {
    //映射枚举字段的下标
    ORDINAL,
    //映射枚举的Name
    STRING
}
```

## @MappedSuperclass

`@MappedSuperclass`注解使用在父类上面, 是用来标识父类的, `@MappedSuperclass`标识的类表示其不能映射到数据库表，因为其不是一个完整的实体类，但是它所拥有的属性能够隐射在其子类对用的数据库表中.

## @PrePersist... & @PostPersist...

`@PrePersist`, `@PreUpdate`, `@PreRemove`, `@PostLoad`, `@PostPersist`, `@PostRemove`, `PostUpdate`: 如字面理解的都是更新前, 更新后等回调的方法.

```java
@MappedSuperclass
@Data
@Accessors(chain = true)
public abstract class BaseEntity {

	@Id
	@GenericGenerator(name = SnowflakeIdentifierGenerator.NAME, strategy = SnowflakeIdentifierGenerator.CLASS_NAME)
	@GeneratedValue(generator = SnowflakeIdentifierGenerator.NAME)
	protected Long id;

	private LocalDateTime createTime;

	private LocalDateTime updateTime;

	@PrePersist
	protected void prePersist() {
		if (this.createTime == null) {
			createTime = LocalDateTime.now();
		}
	}
}
```

这里可以配合Auditing实现一些审计功能, 参考`AuditingEntityListener`:

```java
@Entity
@Table(name = "user_customer", schema = "test", catalog = "")
@EntityListeners(CustomAuditingEntityListener.class)
public class UserCustomerEntity {

}
```

```java
@Configurable
public class CustomAuditingEntityListener {
   
   @PrePersist
   public void touchForCreate(Object target) {
      // if(target.getCreateTime == null){ set createTime hear }
   }
   
   @PreUpdate
   public void touchForUpdate(Object target) {
      // inject update time
   }
}
```



## @JoinColumn

`@JoinColumn` 主要配合 `@OneToOne`、`@ManyToOne`、`@OneToMany` 一起使用，单独使用没有意义, 用来定义多个字段的关联关系。

```java
public @interface JoinColumn {
    //目标表的字段名,必填
    String name() default "";
    //本实体的字段名，非必填，默认是本表ID
    String referencedColumnName() default "";
    //外键字段是否唯一
    boolean unique() default false;
    //外键字段是否允许为空
    boolean nullable() default true;
    //是否跟随一起新增
    boolean insertable() default true;
    //是否跟随一起更新
    boolean updatable() default true;
}
```

## @OneToOne

```java
public @interface OneToOne {
    //关系目标实体，非必填，默认该字段的类型。
    Class targetEntity() default void.class;
    //cascade 级联操作策略
  1. CascadeType.PERSIST 级联新建
  2. CascadeType.REMOVE 级联删除
  3. CascadeType.REFRESH 级联刷新
  4. CascadeType.MERGE 级联更新
  5. CascadeType.ALL 四项全选
  6. 默认，关系表不会产生任何影响
    CascadeType[] cascade() default {};
    //数据获取方式EAGER(立即加载)/LAZY(延迟加载)
    FetchType fetch() default EAGER;
    //是否允许为空
    boolean optional() default true;
    //关联关系被谁维护的。 非必填，一般不需要特别指定。   
//注意：只有关系维护方才能操作两者的关系。被维护方即使设置了维护方属性进行存储也不会更新外键关联。1）mappedBy不能与@JoinColumn或者@JoinTable同时使用。2）mappedBy的值是指另一方的实体里面属性的字段，而不是数据库字段，也不是实体的对象的名字。既是另一方配置了@JoinColumn或者@JoinTable注解的属性的字段名称。
    String mappedBy() default "";
    //是否级联删除。和CascadeType.REMOVE的效果一样。两种配置了一个就会自动级联删除
    boolean orphanRemoval() default false;
}
```

`@OneToOne` 需要配合 `@JoinColumn` 一起使用。注意：可以双向关联，也可以只配置一方，看实际需求。

案例：假设一个部门只有一个员工，Department 的内容如下：

```java
@OneToOne
@JoinColumn(name="employee_id",referencedColumnName="id")
private Employee employeeAttribute = new Employee();
```

> 注意：`employee_id`指的是 Department 里面的字段，而 referencedColumnName="id" 指的是 Employee 表里面的字段。

如果需要双向关联，Employee 的内容如下：

```java
@OneToOne(mappedBy="employeeAttribute")
private Department department;
```

当然了也可以不选用 mappedBy 和下面效果是一样的：

```java
@OneToOne
@JoinColumn(name="id",referencedColumnName="employee_id")
private Department department;
```

## @OneToMany & @ManyToOne

```java
public @interface OneToMany {
    Class targetEntity() default void.class;
 //cascade 级联操作策略：(CascadeType.PERSIST、CascadeType.REMOVE、CascadeType.REFRESH、CascadeType.MERGE、CascadeType.ALL)
如果不填，默认关系表不会产生任何影响。
    CascadeType[] cascade() default {};
//数据获取方式EAGER(立即加载)/LAZY(延迟加载)
    FetchType fetch() default LAZY;
    //关系被谁维护，单项的。注意：只有关系维护方才能操作两者的关系。
    String mappedBy() default "";
//是否级联删除。和CascadeType.REMOVE的效果一样。两种配置了一个就会自动级联删除
    boolean orphanRemoval() default false;
}
public @interface ManyToOne {
    Class targetEntity() default void.class;
    CascadeType[] cascade() default {};
    FetchType fetch() default EAGER;
    boolean optional() default true;
}
```

```java
@Entity
@Table(name="user")
public class User implements Serializable{
@OneToMany(cascade=CascadeType.ALL,fetch=FetchType.LAZY,mappedBy="user")
    private Set<role> setRole; 
......}
@Entity
@Table(name="role")
public class Role {
@ManyToOne(cascade=CascadeType.ALL,fetch=FetchType.EAGER)
    @JoinColumn(name="user_id")//user_id字段作为外键
    private User user;
......}
```

## @ManyToMany & @JoinTable

```java
public @interface ManyToMany {
    Class targetEntity() default void.class;
    CascadeType[] cascade() default {};
    FetchType fetch() default LAZY;
    String mappedBy() default "";
}

public @interface JoinTable {
    //中间关联关系表明
    String name() default "";
    //表的catalog
    String catalog() default "";
    //表的schema
    String schema() default "";
    //主链接表的字段
    JoinColumn[] joinColumns() default {};
    //被联机的表外键字段
    JoinColumn[] inverseJoinColumns() default {};
......
}
```

```java
@Entity
public class User extends BaseEntity {

	@NotBlank(message = "姓名不能为空")
	private String name;
	private String email;

	@ManyToMany
	@JoinTable(
			name = "userRole",
			joinColumns = @JoinColumn(name = "userId", referencedColumnName="id"),
			inverseJoinColumns=@JoinColumn(name="roleId",referencedColumnName="id")
	)
	private List<Role> roles;
}

@Entity
public class Role {

	@Id
	private Long id;

	private String name;
}

@Entity
public class UserRole {

	@Id
	protected Long id;

	private Long userId;

	private Long roleId;
}
```

# QueryByExampleExecutor基本用法

> 这个使用比较少

多种条件组合:

```java
//创建查询条件数据对象
Customer customer = new Customer();
customer.setName("zhang");
customer.setAddress("河南省");
customer.setRemark("BB");
//虽然有值，但是不参与过滤条件
customer.setFocus(true);
//创建匹配器，即如何使用查询条件
ExampleMatcher matcher = ExampleMatcher.matching() //构建对象
        .withStringMatcher(StringMatcher.CONTAINING) //改变默认字符串匹配方式：模糊查询
        .withIgnoreCase(true) //改变默认大小写忽略方式：忽略大小写
        .withMatcher("address", GenericPropertyMatchers.startsWith()) //地址采用“开始匹配”的方式查询
        .withIgnorePaths("focus");  //忽略属性：是否关注。因为是基本类型，需要忽略掉
//创建实例
Example<Customer> ex = Example.of(customer, matcher); 
//查询
List<Customer> ls = dao.findAll(ex);
```

查询 Null 值:

```java
//创建查询条件数据对象
Customer customer = new Customer();
//创建匹配器，即如何使用查询条件
ExampleMatcher matcher = ExampleMatcher.matching() //构建对象
        //改变“Null值处理方式”：包括。
      .withIncludeNullValues() 
       //忽略其他属性
      .withIgnorePaths("id", "name", "sex", "age", "focus", "addTime", "remark", "customerType"); 
//创建实例
Example<Customer> ex = Example.of(customer, matcher);
//查询
List<Customer> ls = dao.findAll(ex); 
```

# JpaSpecificationExecutor使用

`JpaSpecificationExecutor` 是 `Repository` 要继承的接口，而 `SimpleJpaRepository` 是其默认实现:

```java
public interface JpaSpecificationExecutor<T> {
   //根据 Specification 条件查询单个对象，注意的是，如果条件能查出来多个会报错
   T findOne(@Nullable Specification<T> spec);
   //根据 Specification 条件查询 List 结果
   List<T> findAll(@Nullable Specification<T> spec);
   //根据 Specification 条件，分页查询
   Page<T> findAll(@Nullable Specification<T> spec, Pageable pageable);
   //根据 Specification 条件，带排序的查询结果
   List<T> findAll(@Nullable Specification<T> spec, Sort sort);
   //根据 Specification 条件，查询数量
   long count(@Nullable Specification<T> spec);
}
```

这个接口基本是围绕着 `Specification` 接口来定义的:

```java
public interface Specification<T> {
   Predicate toPredicate(Root<T> root, CriteriaQuery<?> query, CriteriaBuilder cb);
}
```

Criteria 的概念简单介绍:

**（1）Root root**

代表了可以查询和操作的实体对象的根，如果将实体对象比喻成表名，那 root 里面就是这张表里面的字段，这不过是 JPQL 的实体字段而已。通过里面的 Path get(String attributeName)，来获得我们想操作的字段。

**（2）CriteriaQuery query**

代表一个 specific 的顶层查询对象，它包含着查询的各个部分，比如 select 、from、where、group by、order by 等。CriteriaQuery 对象只对实体类型或嵌入式类型的 Criteria 查询起作用，简单理解，它提供了查询 ROOT 的方法。常用的方法有：

```
CriteriaQuery<T> where(Predicate... restrictions);
CriteriaQuery<T> select(Selection<? extends T> selection);
CriteriaQuery<T> having(Predicate... restrictions);
```

**（3）CriteriaBuilder cb**

用来构建 CritiaQuery 的构建器对象，其实就相当于条件或者是条件组合，并以 Predicate 的形式返回。下面是构建简单的 Predicate 示例：

```
Predicate p1=cb.like(root.get(“name”).as(String.class), “%”+uqm.getName()+“%”);
Predicate p2=cb.equal(root.get("uuid").as(Integer.class), uqm.getUuid());
Predicate p3=cb.gt(root.get("age").as(Integer.class), uqm.getAge());
```

构建组合的 Predicate 示例：

`Predicate p = cb.and(p3,cb.or(p1,p2));`

**用法**:

```java
@Component
public class UserInfoManager {
   @Autowired
   private UserRepository userRepository;
   public Page<UserInfoEntity> findByCondition(UserInfoRequest userParam,Pageable pageable){
      return userRepository.findAll((root, query, cb) -> {
         List<Predicate> predicates = new ArrayList<Predicate>();
         if (StringUtils.isNoneBlank(userParam.getFirstName())){
            //liked的查询条件
            predicates.add(cb.like(root.get("firstName"),"%"+userParam.getFirstName()+"%"));
         }
         if (StringUtils.isNoneBlank(userParam.getTelephone())){
            //equal查询条件
            predicates.add(cb.equal(root.get("telephone"),userParam.getTelephone()));
         }
         if (StringUtils.isNoneBlank(userParam.getVersion())){
            //greaterThan大于等于查询条件
            predicates.add(cb.greaterThan(root.get("version"),userParam.getVersion()));
         }
         if (userParam.getBeginCreateTime()!=null&&userParam.getEndCreateTime()!=null){
            //根据时间区间去查询   predicates.add(cb.between(root.get("createTime"),userParam.getBeginCreateTime(),userParam.getEndCreateTime()));
         }
         if (StringUtils.isNotBlank(userParam.getAddressCity())) {
            //联表查询，利用root的join方法，根据关联关系表里面的字段进行查询。
            predicates.add(cb.equal(root.join("addressEntityList").get("addressCity"), userParam.getAddressCity()));
         }
         return query.where(predicates.toArray(new Predicate[predicates.size()])).getRestriction();
      }, pageable);
   }
}
//可以仔细体会上面这个案例，实际工作中应该大部分都是这种写法，就算扩展也是百变不离其中。
```

# JPA Spec封装

```java
public final class SpecificationFactory {
   /**
    * 模糊查询，匹配对应字段
    */
   public static Specification containsLike(String attribute, String value) {
      return (root, query, cb)-> cb.like(root.get(attribute), "%" + value + "%");
   }
   /**
    * 某字段的值等于 value 的查询条件
    */
   public static Specification equal(String attribute, Object value) {
      return (root, query, cb) -> cb.equal(root.get(attribute),value);
   }
   /**
    * 获取对应属性的值所在区间
    */
   public static Specification isBetween(String attribute, int min, int max) {
      return (root, query, cb) -> cb.between(root.get(attribute), min, max);
   }
   public static Specification isBetween(String attribute, double min, double max) {
      return (root, query, cb) -> cb.between(root.get(attribute), min, max);
   }
   public static Specification isBetween(String attribute, Date min, Date max) {
      return (root, query, cb) -> cb.between(root.get(attribute), min, max);
   }
   /**
    * 通过属性名和集合实现 in 查询
    */
   public static Specification in(String attribute, Collection c) {
      return (root, query, cb) ->root.get(attribute).in(c);
   }
   /**
    * 通过属性名构建大于等于 Value 的查询条件
    */
   public static Specification greaterThan(String attribute, BigDecimal value) {
      return (root, query, cb) ->cb.greaterThan(root.get(attribute),value);
   }
   public static Specification greaterThan(String attribute, Long value) {
      return (root, query, cb) ->cb.greaterThan(root.get(attribute),value);
   }
......
}
```

调用:

```java
userRepository.findAll(
      SpecificationFactory.containsLike("firstName", userParam.getLastName()),
      pageable);
      
userRepository.findAll(Specifications.where(
      SpecificationFactory.containsLike("firstName", userParam.getLastName()))
            .and(SpecificationFactory.greaterThan("version",userParam.getVersion())),
      pageable);
```

这样一来可读性以及代码优雅度都提高了.

推荐一个对Specification的封装库: ***[https://github.com/wenhao/jpa-spec](https://github.com/wenhao/jpa-spec)***

# EntityManager与自定义Repository

## EntityManager的两种获取方式

获取`EntityManager`有两种方式.

方式一: `@PersistenceContext`

```java
@Repository
@Transactional(readOnly = true)
public class UserRepositoryImpl implements UserRepositoryCustom {
    @PersistenceContext  //获得entityManager的实例
    EntityManager entityManager;
}
```

方式二:  继承 `SimpleJpaRepository`

```java
public class BaseRepositoryCustom<T, ID> extends SimpleJpaRepository<T, ID> {
    public BaseRepositoryCustom(JpaEntityInformation<T, ?> entityInformation, EntityManager entityManager) {
        super(entityInformation, entityManager);
    }
    public BaseRepositoryCustom(Class<T> domainClass, EntityManager em) {
        super(domainClass, em);
    }
}
```

## 自定义 Repository

### 自定义个别的特殊场景私有的 Repository

定义接口:

```java
public interface UserRepositoryCustom {
    List<User> customerMethodNamesLike(String firstName);
}
```

实现接口:

```java
/**
 * 用@Repository 将此实现交个Spring bean加载
 * 咱们模仿SimpleJpaRepository 默认将所有方法都开启一个事务
 */
@Repository
@Transactional(readOnly = true)
public class UserRepositoryCustomImpl implements UserRepositoryCustom {
    @PersistenceContext
    EntityManager entityManager;
    
    @Override
    public List<User> customerMethodNamesLike(String firstName) {
        Query query = entityManager.createNativeQuery("SELECT u.* FROM user as u " +
                "WHERE u.name LIKE ?", User.class);
        query.setParameter(1, firstName + "%");
        return query.getResultList();
    }
}
```

> 上面除了entityManager, 也可以使用JdbcTemplate来自己实现逻辑

继承接口:

```java
public interface UserRepository extends Repository<User, Long>,UserRepositoryCustom {
}
```

然后直接调用就行了:

```java
userRepository.customerMethodNamesLike("jack");
```

我们还可以覆盖 JPA 里面的默认实现方法:

```java
//假设我们要覆盖默认的save方法的逻辑
interface CustomizedSave<T> {
  <S extends T> S save(S entity);
}
class CustomizedSaveImpl<T> implements CustomizedSave<T> {
  public <S extends T> S save(S entity) {
    // Your custom implementation
  }
}
//用法保持不变，如下：
interface UserRepository extends CrudRepository<User, Long>, CustomizedSave<User> {
}
//CustomizedSave通过泛化可以被多个Repository使用
interface PersonRepository extends CrudRepository<Person, Long>, CustomizedSave<Person> {
}
```

**实际工作中应用于逻辑删除场景：**

> 在实际工作的生产环境中，我们可能经常会用到逻辑删除，所以做法是一般自定义覆盖 Data JPA 帮我们提供 remove 方法，然后实现逻辑删除的逻辑即可。

### 公用的通用的场景替代默认的 SimpleJpaRepository

声明定制共享行为的接口，用 `@NoRepositoryBean`:

```java
@NoRepositoryBean
public interface MyRepository<T, ID extends Serializable> extends PagingAndSortingRepository<T, ID> {
  void sharedCustomMethod(ID id);
}
```

继承 SimpleJpaRepository 扩展自己的方法实现逻辑:

```java
public class MyRepositoryImpl<T, ID extends Serializable>
  extends SimpleJpaRepository<T, ID> implements MyRepository<T, ID> {
  private final EntityManager entityManager;
  public MyRepositoryImpl(JpaEntityInformation entityInformation, EntityManager entityManager) {
    super(entityInformation, entityManager);
    // Keep the EntityManager around to used from the newly introduced methods.
    this.entityManager = entityManager;
  }
  public void sharedCustomMethod(ID id) {
    // 通过entityManager实现自己的额外方法的实现逻辑。这里不多说了
  }
}
```

使用 JavaConfig 配置自定义 MyRepositoryImpl 作为其他接口的动态代理的实现基类:

```java
@Configuration
@EnableJpaRepositories(repositoryBaseClass = MyRepositoryImpl.class)
class ApplicationConfiguration { … }
```

> 具有全局的性质，即使没有继承它所有的动态代理类也会变成它.

# 使用Tips

## 使用 @Convert 关联一对多的值对象

有时候在实体当中有某些字段是一个**值对象的集合**，我们又不想(也没必要)为其另起一张表，打个比方：订单里面的商品列表(只是打个比方，实际上应该是一张独立的表)。

例如设计一个访问日志对象，我们需要记录访问方法的行参与接收值：

```java
@Data
@Accessors(chain = true)
@Slf4j
@Entity
@Table(name = "access_log")
public class AccessLog implements Serializable {

	private static final long serialVersionUID = -6911021075718017305L;

	@Id
	@GeneratedValue(generator = "snowflakeIdentifierGenerator")
	@GenericGenerator(name = "snowflakeIdentifierGenerator", strategy = "com.yangbingdong.docker.domain.core.vo.SnowflakeIdentifierGenerator")
	private long id;

	@Column(columnDefinition = "text")
	@Convert(converter = ReqReceiveDataConverter.class)
	private List<ReqReceiveData> reqReceiveDatas;
	
	...
}
```

属性转换器：
```java
//@Converter(autoApply = true)
public class ReqReceiveDataConverter implements AttributeConverter<List<ReqReceiveData>, String> {
	@Override
	public String convertToDatabaseColumn(List<ReqReceiveData> attribute) {
		return JSONObject.toJSONString(attribute);
	}

	@Override
	public List<ReqReceiveData> convertToEntityAttribute(String dbData) {
		return JSONObject.parseArray(dbData, ReqReceiveData.class);
	}
}
```

* `@Convert`声明使用某个属性转换器(`ReqReceiveDataConverter`)
* `ReqReceiveDataConverter`需要实现`AttributeConverter<X,Y>`，`X`为实体的字段类型，`Y`对应需要持久化到DB的类型
* `@Converter(autoApply = true)`注解作用，如果有多个实体需要用到此属性转换器，不需要每个实体都的字段加上`@Convert`注解，自动对全部实体生效

## 发布领域事件

一般基于DDD的设计，在实体状态改变时(保存或更新实体)，为了保证其他边缘服务与之状态的统一，我们需要通过发布实体保存或更新事件，其他服务监听后做出相应的处理，大概像这样：

```java
@RequiredArgsConstructor

class MyComponent {
  private final @NonNull MyRepository repository;
  private final @NonNull ApplicationEventPublisher publisher;

  public void doSomething(MyAggregateRoot entity) {
    MyDomainEvent event = entity.someBusinessFunctionality();
    publisher.publishEvent(event);
    repository.save(entity);
  }
}
```

通过JPA我们可以优雅地发布领域事件，有以下两种实现方式：

* 继承`AbstractAggregateRoot`，并使用其`registerEvent()`方法注册发布事件

  ```java
  public class BankTransfer extends AbstractAggregateRoot {
     ...

      public BankTransfer complete() {
          id = UUID.randomUUID().toString();
          registerEvent(new BankTransferCompletedEvent(id));
          return this;
      }
      
      ...
  }

  ```

  ```java
  @Service
  public class BankTransferService {

      ...
      
      @Transactional
      public String completeTransfer(BankTransfer bankTransfer) {
          return repository.save(bankTransfer.complete()).getId();
      }

      ...
  }

  ```

  **但此方式拿不到实体id，因为是在生成id之前生成的event**

* 使用`@DomainEvents`注解方法发布事件

  ```java
  public class MessageEvent implements Serializable {
  	private static final long serialVersionUID = -3843381578126175380L;
      ....
      
  	@Transient
  	private transient List<Object> domainEvents = new ArrayList<>(16);

  	@DomainEvents
  	Collection<Object> domainEvents() {
  		log.info("publish domainEvents......");
  		domainEvents.add(new SaveMsgEvent().setId(this.id));
  		return Collections.unmodifiableList(domainEvents);
  	}

  	@AfterDomainEventPublication
  	void callbackMethod() {
  		log.info("AfterDomainEventPublication..........");
  		domainEvents.clear();
  	}
  }
  ```

  这种方式可以拿到实体id

  监听：

  ```java
  @Component
  @Slf4j
  public class DomainEventListener {

  	@Async
  	@TransactionalEventListener(SaveMsgEvent.class)
  	public void processSaveMsgEvent(SaveMsgEvent saveMsgEvent) throws InterruptedException {
  		TimeUnit.MILLISECONDS.sleep(100);
  		log.info("Listening SaveMsgEvent..................saveMsgEvent id: {}", saveMsgEvent);
  	}
  }
  ```

  用`@EventListener`也可以，但是`@TransactionalEventListener`可以在**事务之后**执行。使用前者的话，程序异常事务会滚监听器照样会执行，而后者必须等事务正确提交之后才会执行。

# 踩坑

## 索引超长

```
com.mysql.jdbc.exceptions.jdbc4.MySQLSyntaxErrorException: Specified key was too long; max key length is 1000 bytes
	at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method) ~[?:1.8.0_162]
	at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62) ~[?:1.8.0_162]
	at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45) ~[?:1.8.0_162]
	at java.lang.reflect.Constructor.newInstance(Constructor.java:423) ~[?:1.8.0_162]
	at com.mysql.jdbc.Util.handleNewInstance(Util.java:425) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.Util.getInstance(Util.java:408) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.SQLError.createSQLException(SQLError.java:944) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.MysqlIO.checkErrorPacket(MysqlIO.java:3973) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.MysqlIO.checkErrorPacket(MysqlIO.java:3909) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.MysqlIO.sendCommand(MysqlIO.java:2527) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.MysqlIO.sqlQueryDirect(MysqlIO.java:2680) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.ConnectionImpl.execSQL(ConnectionImpl.java:2480) ~[mysql-connector-java-5.1.45.jar:5.1.45]
	at com.mysql.jdbc.ConnectionImpl.execSQL(ConnectionImpl.java:2438) ~[mysql-connector-java-5.1.45.jar:5.1.45]
```

如果设置了索引：

```
@Table(indexes = {@Index(name = "idx_server_name", columnList = "serverName")})
```

上面注解指定了`serverName`这一列为普通索引，如果此列不做限制，默认的长度是为255，默认的字符编码为`utf8mb4`，最大字符长度为4字节，255 * 4 = 1020，所以超过了索引长度。

在`MyISAM`表中，创建索引时，创建的索引长度不能超过**1000**bytes，在`InnoDB`表中，创建索引时，索引的长度不成超过**767**byts 。

建立索引时，数据库计算key的长度是累加所有Index用到的字段的char长度后再按下面比例乘起来不能超过限定的key长度：

```
latin1 = 1 byte = 1 character 
uft8 = 3 byte = 1 character 
gbk = 2 byte = 1 character 
utf8mb4 = 4 byte = 1 character 
```

## 使用AttributeConverter转换JSON字符串时，Hibernate执行insert之后再执行update

![](https://cdn.yangbingdong.com/img/spring-boot-data/jpa-dirty01.png)

![](https://cdn.yangbingdong.com/img/spring-boot-data/jpa-dirty02.png)

如上图，这是利用AOP实现的操作日志记录，使用`AttributeConverter`与Fastjson实现`ReqReceiveData`转换成JSON字符串，可以看到在执行insert之后接着执行了一次update，那是因为JSON字符串字段顺序居然发生了变化！

不过后来折腾一下把顺序统一了，但还是会出现这种问题，百思不得其解，一样的字符串Hibernate也会认为这是Dirty的数据？

百般折腾得以解决(但还是搞不懂原因)：

value是Object类型，在set的时候调用`JSONObject.toJSON(value)`转成Object再set进去...