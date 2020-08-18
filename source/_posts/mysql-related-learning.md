---
title: MySQL 杂谈
date: 2018-02-16 15:16:18
categories: [MySQL]
tags: [MySQL]
---

![](https://cdn.yangbingdong.com/img/mysql-related-learning/MySQL.png)

# Preface

> MySQL 是一款开源的关系型数据库, 也是使用最广泛的数据库之一, 作为开发人员, 很有必要理解以及学习 MySQL 的一些相关知识.

<!--more-->

# 安装

## 传统安装

请见[*之前写的的一篇开发环境配置*](/2017/ubuntu-dev-environment-to-build/#%E5%AE%89%E8%A3%85MySQL%E4%BB%A5%E5%8F%8AGUI%E5%B7%A5%E5%85%B7)

## Docker版安装

直接贴出`docker-compose.yml`:

```yaml
version: '3.5'

services:
  mysql:
    image: mysql:latest
    container_name: mysql
    ports:
      - "3306:3306"
    volumes:
      - ../data:/var/lib/mysql
      - ../conf:/etc/mysql/conf.d
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - TZ=Asia/Shanghai
    restart: always
    networks:
      - backend

networks:
  backend:
    external: true
```

配置文件（`config-file.cnf`, 放在上面`volumes`中提到的`../conf`里）: 

```
[mysqld]

sql_mode = STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION
lower_case_table_names = 1
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```

## 遇到问题

### 配置文件权限

虽然启动成功, 但发现MySQL实例是关闭的, 在启动日志中发现这一条信息

![](https://cdn.yangbingdong.com/img/mysql-related-learning/mysql-warning.png)

大概意思是**权限全局可写**, 任何一个用户都可以写. MySQL担心这种文件**被其他用户恶意修改**, 所以**忽略**掉这个配置文件. 

结论: **配置文件权限过大, 会影响实例不能启动, 或者不能关闭, 需要修改为 644**

问题得以解决~！

### Docker时区

通过Docker启动的MySql, 默认读取的是Docker中的时区UTC, 只要在docker compose文件中指定时区就行了:

```diff
    environment:
      - MYSQL_ROOT_PASSWORD=root
+     - TZ=Asia/Shanghai
```

或者在MySql配置文件中加入:

```
[mysqld]
...
default-time-zone='+8:00'
```

### 连接不上

若抛出酱紫的错误:

```
ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/run/mysqld/mysqld.sock' (2)
```

那么你可能使用了 `localhost` 链接, 改为 `127.0.0.1` 或内网地址则OK.

# 客户端以及GUI

## 传统终端客户端

```
sudo apt-get install mysql-client

// 链接
mysql -h 127.0.0.1 -P 3306 -u root -p
```

##  智能补全命令客户端

这个一个智能补全并且高亮语法的终端客户端 ***[mycli](https://github.com/dbcli/mycli)***

![](https://cdn.yangbingdong.com/img/mysql-related-learning/mycli.gif)

安装: 

```
sudo apt install mycli
```

`mycli --help` 查看使用方法.

## Navicat Premium

安装以及破解在***[另一篇博文](/2017/ubuntu-dev-environment-to-build/#Navicat-Premium)***里面. 

![](https://cdn.yangbingdong.com/img/javaDevEnv/navicat12.png)

## Workbench

MySQL官方开源GUI

下载地址: ***[https://dev.mysql.com/downloads/workbench/](https://dev.mysql.com/downloads/workbench/)***

![](https://cdn.yangbingdong.com/img/mysql-related-learning/MySQL%20Workbench_001.png)

# 基础篇

## SQL 执行过程

![](https://cdn.yangbingdong.com/img/mysql-related-learning/mysql-sql-execute-arch.png)

**MySQL 8.0 以后已经缓存模块删除了**.

## 日志系统

日志作用:

* 降低 IO 成本(WAL, 也就是 Write-Ahead Logging)
* crash-safe, 崩溃恢复
* 数据恢复

两种日志:

* redo log(range 结构), **物理日志**, 属于 **InnoDb 特有**
* binlog, **逻辑日志**, MySQL Server 层实现  

redo log 与 binlog 的一致性通过**二阶段提交**来保证(比如 redo log 写 prepare 成功, binlog 写入失败, 则会滚)

update 执行图:

> `update T set c=c+1 where ID=2;`

![](https://cdn.yangbingdong.com/img/mysql-related-learning/mysql-update-processing.png)

## 事务隔离

多事务并行会有以下问题:

* 脏读(dirty read)
* 不可重复读(non-repeatable read)
* 幻读(phantom read)

SQL 标准的事务隔离级别包括:

* 读未提交(read uncommitted)
* 读提交(read committed)
* 可重复读(repeatable read)
* 串行化(serializable)

事务隔离通过 MVCC 实现(undoLog + read-view), 使用到的三个字段: **isDelete**(是否删除字段) / **DB_TRX_ID**(事务字段) / **DB_ROLL_PTR**(回滚指针字段). 

应该尽量避免长事务, 因为 undoLog 会占用大量空间.

MVCC 两种读形式:

- 快照读: 读取的只是当前事务的可见版本, 不用加锁.
- 当前读: 读取的是当前版本, 比如 **特殊的读操作, 更新/插入/删除操作**.

# 索引相关

## 科普

### B+ Tree

Innodb 采用 B+ Tree 结构, 索引也是.

B+ Tree 的几个特征:

* 最底层的节点叫作叶子节点, 用来存放数据
* 其他上层节点叫作非叶子节点, 仅用来存放目录项, 作为索引
* 非叶子节点分为不同层次, 通过分层来降低每一层的搜索量
* 所有节点**按照索引键大小排序**, 构成一个双向链表, 加速范围查找

![](https://cdn.yangbingdong.com/img/mysql-related-learning/mysql-b-plus-tree.png)

B+ 树, 既可以保存实际数据, 也可以加速数据搜索, 这就是聚簇索引.由于数据在物理上只会保存一份, **所以包含实际数据的聚簇索引只能有一个**.

### 回表

为了实现非主键字段的快速搜索, 就引出了二级索引, 也叫作**非聚簇索引**或者辅助索引. 二级索引的叶子节点中保存的不是实际数据, 而是主键, 获得主键值后去聚簇索引中获得数据行, 这个过程就叫作**回表**。

### 索引覆盖

如果我们需要查询的是索引列索引或联合索引能覆盖的数据, 那么查询索引本身已经  "覆盖" 了需要的数据不再需要回表查询.

### 索引下推

索引下推优化(index condition pushdown)是在 MySQL 5.6 引入的: 可以在索引遍历过程中, 对索引中包含的字段先做判断, 直接过滤掉不满足条件的记录, 减少回表次数.

## 如何判断数据库索引是否生效

使用`explain ... \G`分析语句 (使用`\G`可格式化结果)

表结构: 

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain01.png)

不使用索引: 

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain02.png)

使用索引: 

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain03.png)

可以看到, 使用`explain`显示了很多列, 各个关键字的含义如下: 

- `table`: 顾名思义, 显示这一行的数据是关于哪张表的；

- `type`: 这是重要的列, 显示连接使用了何种类型. 从**最好到最差**的连接类型为: `const`、`eq_reg`、`ref`、`range`、`indexhe`和`ALL`（详情: [*https://dev.mysql.com/doc/refman/5.7/en/explain-output.html#explain-join-types*](https://dev.mysql.com/doc/refman/5.7/en/explain-output.html#explain-join-types)）；

- `possible_keys`: 显示可能应用在这张表中的索引. 如果为空, 没有可能的索引. 可以为相关的域从`where`语句中选择一个合适的语句；

- `key`: 实际使用的索引. 如果为`NULL`, 则没有使用索引. 很少的情况下, MySQL会选择优化不足的索引. 这种情况下, 可以在`Select`语句中使用`USE INDEX（indexname）`来强制使用一个索引或者用`IGNORE INDEX（indexname）`来强制MySQL忽略索引；

- `key_len`: 使用的索引的长度. 在不损失精确性的情况下, 长度越短越好；

- `ref`: 显示索引的哪一列被使用了, 如果可能的话, 是一个常数；

- `rows`: MySQL认为必须检查的用来返回请求数据的行数；

- `Extra`: 关于MySQL如何解析查询的额外信息. 

    以下是`Extra`返回含义: 

    `Distinct`:一旦MYSQL找到了与行相联合匹配的行, 就不再搜索了

    `Not exists`: MYSQL优化了`LEFT JOIN`, 一旦它找到了匹配`LEFT JOIN`标准的行, 就不再搜索了

    `Range checked for each Record（index map:#）`:没有找到理想的索引, 因此对于从前面表中来的每一个行组合, MYSQL检查使用哪个索引, 并用它来从表中返回行. 这是使用索引的最慢的连接之一

    `Using filesort`: 看到这个的时候, 查询就需要优化了. MYSQL需要进行额外的步骤来发现如何对返回的行排序. 它根据连接类型以及存储排序键值和匹配条件的全部行的行指针来排序全部行

    `Using index`: 列数据是从仅仅使用了索引中的信息而没有读取实际的行动的表返回的, 这发生在对表的全部的请求列都是同一个索引的部分的时候

    `Using temporary` 看到这个的时候, 查询需要优化了. 这里, MYSQL需要创建一个临时表来存储结果, 这通常发生在对不同的列集进行`ORDER BY`上, 而不是`GROUP BY`上

    `Where used` 使用了`WHERE`从句来限制哪些行将与下一张表匹配或者是返回给用户. 如果不想返回表中的全部行, 并且连接类型`ALL`或`index`, 这就会发生, 或者是查询有问题不同连接类型的解释（按照效率高低的顺序排序）

    `system` 表只有一行: `system`表. 这是`const`连接类型的特殊情况

    `const`:表中的一个记录的最大值能够匹配这个查询（索引可以是主键或惟一索引）. 因为只有一行, 这个值实际就是常数, 因为MYSQL先读这个值然后把它当做常数来对待

    `eq_ref`:在连接中, MYSQL在查询时, 从前面的表中, 对每一个记录的联合都从表中读取一个记录, 它在查询使用了索引为主键或惟一键的全部时使用

    `ref`:这个连接类型只有在查询使用了不是惟一或主键的键或者是这些类型的部分（比如, 利用最左边前缀）时发生. 对于之前的表的每一个行联合, 全部记录都将从表中读出. 这个类型严重依赖于根据索引匹配的记录多少—越少越好

    `range`:这个连接类型使用索引返回一个范围中的行, 比如使用>或<查找东西时发生的情况

    `index`: 这个连接类型对前面的表中的每一个记录联合进行完全扫描（比ALL更好, 因为索引一般小于表数据）

    `ALL`:这个连接类型对于前面的每一个记录联合进行完全扫描, 这一般比较糟糕, 应该尽量避免

具体的各个列所能表示的值以及含义可以参考MySQL官方文档介绍, 地址: [*https://dev.mysql.com/doc/refman/5.7/en/explain-output.html*](https://dev.mysql.com/doc/refman/5.7/en/explain-output.html)

## 哪些场景会造成索引失效

1. 应尽量避免在 `where` 子句中使用 `!=` 或 `<>` 操作符, 否则引擎将放弃使用索引而进行全表扫描

2. 尽量避免在 `where` 子句中使用 `or` 来连接条件, 否则将**导致引擎放弃使用索引而进行全表扫描**, 即使其中有条件带索引也不会使用, 这也是为什么尽量少用 `or` 的原因

3. 对于**多列索引**, **不是使用的第一部分**, 则不会使用索引

4. 隐式转换, 比如列类型是**字符串**, 那一定要在条件中将数据使用**引号**引用起来, 否则不会使用索引

   ![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain04.png)

5. 可能由于字符集导致的索引失败, 连表查询中, 两个关联字段的字符集不一样会导致索引失效, 因为字符集不一样 MySQL 或使用函数将字符集改成一样的

6. `like`的模糊查询以 `%` 开头, 索引失效, 索引 B+ 树中行数据**按照索引值排序**, 只能根据前缀进行比较.

7. 应尽量**避免**在 `where` 子句中对字段进行**表达式操作**, 这将导致引擎放弃使用索引而进行全表扫描

   如: 

   ```
   select id from t where num/2 = 100 1
   ```

   应改为:

   ```
   select id from t where num = 100*2；1
   ```

8. 应尽量**避免**在 where 子句中对字段进行**函数操作**, 这将导致引擎放弃使用索引而进行全表扫描, 同样的原因, 索引保存的是索引列的原始值, 而不是经过函数计算后的值

   例如: 

   ```
   select id from t where substring(name,1,3) = 'abc' – name;1
   ```

   以abc开头的, 应改成: 

   ```
   select id from t where name like ‘abc%’ 1
   ```

   例如: 

   ```
   select id from t where datediff(day, createdate, '2005-11-30') = 0 – '2005-11-30';1
   ```

   应改为:

   ```
   select id from t where createdate >= '2005-11-30' and createdate < '2005-12-1';
   ```

9. 不要在 `where` 子句中的 `=` 左边进行函数、算术运算或其他表达式运算, 否则系统将可能无法正确使用索引

10. 如果MySQL估计使用全表扫描要比使用索引快, 则不使用索引

11. 不适合键值较少的列（重复数据较多的列）

    > 假如索引列TYPE有5个键值, 如果有1万条数据, 那么 WHERE TYPE = 1将访问表中的2000个数据块. 再加上访问索引块, 一共要访问大于2000个的数据块. 如果全表扫描, 假设10条数据一个数据块, 那么只需访问1000个数据块, 既然全表扫描访问的数据块少一些, 肯定就不会利用索引了. 


> 参考: *[http://blog.csdn.net/xlgen157387/article/details/79572598](http://blog.csdn.net/xlgen157387/article/details/79572598)*

# 其他

## JSON相关

### JSON支持

* 在MySQL 5.7.8中, MySQL支持由RFC 7159定义的本地JSON数据类型, 它支持对JSON(JavaScript对象标记)文档中的数据进行有效访问.
* MySQL会对DML JSON数据自动验证. 无效的DML JSON数据操作会产生错误.
* 优化的存储格式. 存储在JSON列中的JSON文档转换为一种内部格式, 允许对Json元素进行快速读取访问.
* MySQL Json类型支持通过虚拟列方式建立索引, 从而增加查询性能提升.

#### 函数语法

mysql在json类型中增加了一些json相关的函数 可以参考如下

| Name                                                         | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [`JSON_APPEND()`](https://dev.mysql.com/doc/refman/5.7/en/json-modification-functions.html#function_json-append) (deprecated 5.7.9) | Append data to JSON document                                 |
| [`JSON_ARRAY()`](https://dev.mysql.com/doc/refman/5.7/en/json-creation-functions.html#function_json-array) | Create JSON array                                            |
| [`JSON_ARRAY_APPEND()`](https://dev.mysql.com/doc/refman/5.7/en/json-modification-functions.html#function_json-array-append) | Append data to JSON document                                 |
| [`JSON_ARRAY_INSERT()`](https://dev.mysql.com/doc/refman/5.7/en/json-modification-functions.html#function_json-array-insert) | Insert into JSON array                                       |
| [`->`](https://dev.mysql.com/doc/refman/5.7/en/json-search-functions.html#operator_json-column-path) | Return value from JSON column after evaluating path; equivalent to JSON_EXTRACT(). |
| [`JSON_CONTAINS()`](https://dev.mysql.com/doc/refman/5.7/en/json-search-functions.html#function_json-contains) | Whether JSON document contains specific object at path       |
| [`JSON_CONTAINS_PATH()`](https://dev.mysql.com/doc/refman/5.7/en/json-search-functions.html#function_json-contains-path) | Whether JSON document contains any data at path              |
| [`JSON_DEPTH()`](https://dev.mysql.com/doc/refman/5.7/en/json-attribute-functions.html#function_json-depth) | Maximum depth of JSON document                               |
| [`JSON_EXTRACT()`](https://dev.mysql.com/doc/refman/5.7/en/json-search-functions.html#function_json-extract) | Return data from JSON document                               |
| [`->>`](https://dev.mysql.com/doc/refman/5.7/en/json-search-functions.html#operator_json-inline-path) | Return value from JSON column after evaluating path and unquoting the result; equivalent to JSON_UNQUOTE(JSON_EXTRACT()). |
| [`JSON_INSERT()`](https://dev.mysql.com/doc/refman/5.7/en/json-modification-functions.html#function_json-insert) | Insert data into JSON document                               |
| [`JSON_KEYS()`](https://dev.mysql.com/doc/refman/5.7/en/json-search-functions.html#function_json-keys) | Array of keys from JSON document                             |
| [`JSON_LENGTH()`](https://dev.mysql.com/doc/refman/5.7/en/json-attribute-functions.html#function_json-length) | Number of elements in JSON document                          |
| [`JSON_MERGE()`](https://dev.mysql.com/doc/refman/5.7/en/json-modification-functions.html#function_json-merge) (deprecated 5.7.22) | Merge JSON documents, preserving duplicate keys. Deprecated synonym for JSON_MERGE_PRESERVE() |
| [`JSON_MERGE_PATCH()`](https://dev.mysql.com/doc/refman/5.7/en/json-modification-functions.html#function_json-merge-patch) | Merge JSON documents, replacing values of duplicate keys     |
| [`JSON_MERGE_PRESERVE()`](https://dev.mysql.com/doc/refman/5.7/en/json-modification-functions.html#function_json-merge-preserve) | Merge JSON documents, preserving duplicate keys              |
| [`JSON_OBJECT()`](https://dev.mysql.com/doc/refman/5.7/en/json-creation-functions.html#function_json-object) | Create JSON object                                           |
| [`JSON_PRETTY()`](https://dev.mysql.com/doc/refman/5.7/en/json-utility-functions.html#function_json-pretty) | Prints a JSON document in human-readable format, with each array element or object member printed on a new line, indented two spaces with respect to its parent. |
| [`JSON_QUOTE()`](https://dev.mysql.com/doc/refman/5.7/en/json-creation-functions.html#function_json-quote) | Quote JSON document                                          |
| [`JSON_REMOVE()`](https://dev.mysql.com/doc/refman/5.7/en/json-modification-functions.html#function_json-remove) | Remove data from JSON document                               |
| [`JSON_REPLACE()`](https://dev.mysql.com/doc/refman/5.7/en/json-modification-functions.html#function_json-replace) | Replace values in JSON document                              |
| [`JSON_SEARCH()`](https://dev.mysql.com/doc/refman/5.7/en/json-search-functions.html#function_json-search) | Path to value within JSON document                           |
| [`JSON_SET()`](https://dev.mysql.com/doc/refman/5.7/en/json-modification-functions.html#function_json-set) | Insert data into JSON document                               |
| [`JSON_STORAGE_SIZE()`](https://dev.mysql.com/doc/refman/5.7/en/json-utility-functions.html#function_json-storage-size) | Space used for storage of binary representation of a JSON document; for a JSON column, the space used when the document was inserted, prior to any partial updates |
| [`JSON_TYPE()`](https://dev.mysql.com/doc/refman/5.7/en/json-attribute-functions.html#function_json-type) | Type of JSON value                                           |
| [`JSON_UNQUOTE()`](https://dev.mysql.com/doc/refman/5.7/en/json-modification-functions.html#function_json-unquote) | Unquote JSON value                                           |
| [`JSON_VALID()`](https://dev.mysql.com/doc/refman/5.7/en/json-attribute-functions.html#function_json-valid) | Whether JSON value is valid                                  |

常见的就是`JSON_EXTRACT()等`

#### 表结构

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain05.png)

#### 插入数据

```
INSERT INTO `user_json` VALUES (1, '{\"name\": \"yang\", \"address\": \"shenyang\"}');
...
```



![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain07.png)

**JSON校验**: 

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain06.png)

#### 查询

```
select * from user_json where json_extract(data,'$.name')='yang';
select json_extract(data,'$.name') from user_json where json_extract(data,'$.name')='yang';
select data->'$.name' from user_json where data->'$.name'='yang';
```

发现结果集是带有双引号的: 

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain08.png)

如果想要去除双引号一般来说我们这样:

```
select JSON_UNQUOTE(json_extract(data,'$.name'))from user_json where json_extract(data,'$.name')='yang';
select  data->>'$.name' from user_json where data->'$.name'='yang';
```

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain09.png)

### JSON如何建立索引

json类型并不能建立索引, 但我们可以通过**虚拟列**来建立索引

```
ALTER TABLE user_json ADD COLUMN `virtual_name` varchar(20) GENERATED ALWAYS AS (data->>'$.name') VIRTUAL NULL AFTER `data`;

ALTER TABLE user_json ADD KEY (virtual_name);
```

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain10.png)

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain11.png)

可以看到索引起作用了~

像时间这些要把周一到周日建索引也是可以的: 

```
`dayofweek` tinyint(4) GENERATED ALWAYS AS (dayofweek(SomeDate)) VIRTUAL,
```

或者某些很麻烦的条件: 

```
alter table ApiLog add verb_url_hash varbinary(16) GENERATED ALWAYS AS (unhex(md5(CONCAT(verb, ' - ', replace(url,'.xml',''))))) VIRTUAL;
alter table ApiLog add key (verb_url_hash);
```

### 其他区别

1、对于AUTO_INCREMENT类型的字段, InnoDB中必须包含只有该字段的索引, 但是在MyISAM表中, 可以和其他字段一起建立联合索引. 

2、DELETE FROM table时, InnoDB不会重新建立表, 而是一行一行的删除. 

3、LOAD TABLE FROMMASTER操作对InnoDB是不起作用的, 解决方法是首先把InnoDB表改成MyISAM表, 导入数据后再改成InnoDB表, 但是对于使用的额外的InnoDB特性(例如外键)的表不适用. 

4、 InnoDB存储引擎被完全与MySQL服务器整合, InnoDB存储引擎为在主内存中缓存数据和索引而维持它自己的缓冲池. 

5、对于自增长的字段, InnoDB中必须包含只有该字段的索引, 但是在MyISAM表中可以和其他字段一起建立联合索引. 

6、清空整个表时, InnoDB是一行一行的删除, 效率非常慢. MyISAM则会重建表. 

## SQL 查看表信息

**查看创建表**

```sql
SHOW CREATE TABLE test_table;
```

**查看表信息**

```sql
SHOW TABLE STATUS WHERE NAME IN('test_table', 'person');
```

更详细信息:

```sql
SELECT * FROM information_schema.tables WHERE table_schema='test_db' AND table_name='test_table';
```

**查看字段信息**

```sql
SHOW FULL FIELDS FROM `test_table`;
```

更详细信息:

```sql
SELECT * FROM information_schema.COLUMNS WHERE table_schema='test_db' AND table_name='test_table';
```

**查看表索引**

```sql
SHOW INDEX FROM test_table;
-- 或者
SHOW KEYS from test_table;
```

## 实用语句

**查看事务隔离级别:**

```sql
show variables like 'transaction_isolation'
```

**查看长事务:**

```sql
select * from information_schema.innodb_trx where TIME_TO_SEC(timediff(now(),trx_started))>60
```



## 备份数据与恢复

从Navicat中导入导出数据是比较慢的, 我们可以通过 `mysqldump` (安装 `mysql-client` 后自带)备份.

### mysqldump 备份

备份一个数据库:

```
mysqldump -u [uname] -p[pass] db_name > db_backup.sql
```

备份所有数据库:

```
mysqldump -u [uname] -p[pass] --all-databases > all_db_backup.sql
```

备份特定的表:

```
mysqldump -u [uname] -p[pass] db_name table1 table2 > table_backup.sql
```

导出压缩一步到位:

```
mysqldump -u [uname] -p[pass] db_name | gzip > db_backup.sql.gz
```

远程数据库:

```
mysqldump -P 3306 -h [ip_address] -u [uname] -p[pass] db_name > db_backup.sql
```

遇到 `mysqldump: Got error: 1044: Access denied for user` 解决办法:

加上 `--single-transaction` 即可, 网上有人说使用 `--skip-lock-tables`, 这个会影响数据的一致性(可能比丢数据还要遭糕)，故不推荐使用这个方法:

```
mysqldump --single-transaction -P 3306 -h [ip_address] -u [uname] -p[pass] db_name > db_backup.sql
```

### 恢复

恢复一个数据库:

```
mysql -h [host] -P [port] -u [uname] -p[pass] db_name < db_backup.sql
```

恢复全部数据库:

```
mysql -h [host] -P [port] -u [uname] -p[pass] < db_backup_all.sql
```

## 死锁排查

***[解决死锁之路（终结篇）- 再见死锁](https://mp.weixin.qq.com/s/HT1tWfEPnigBO9fhML6y0w)***