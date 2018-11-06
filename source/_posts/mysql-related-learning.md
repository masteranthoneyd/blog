---
title: MySQL杂记
date: 2018-02-16 15:16:18
categories: [MySQL]
tags: [MySQL]
---

![](https://cdn.yangbingdong.com/img/mysql-related-learning/MySQL.png)

# Preface

> MySQL是什么就多说了。。。

<!--more-->

# 安装

## 传统安装

请见[*博主之前的一篇博文*](/2017/ubuntu-dev-environment-to-build/#%E5%AE%89%E8%A3%85MySQL%E4%BB%A5%E5%8F%8AGUI%E5%B7%A5%E5%85%B7)

## Docker版安装

直接贴出`docker-compose.yml`:

```
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
    restart: always
    networks:
      - backend

networks:
  backend:
    external: true
```

配置文件（`config-file.cnf`，放在上面`volumes`中提到的`../conf`里）：

```
[mysqld]

sql_mode = STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION
lower_case_table_names = 1
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```

## 遇到问题

虽然启动成功，但发现MySQL实例是关闭的，在启动日志中发现这一条信息

![](https://cdn.yangbingdong.com/img/mysql-related-learning/mysql-warning.png)

大概意思是**权限全局可写**，任何一个用户都可以写。MySQL担心这种文件**被其他用户恶意修改**，所以**忽略**掉这个配置文件。

结论：**配置文件权限过大，会影响实例不能启动，或者不能关闭，需要修改为 644**

问题得以解决~！



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

安装：

```
sudo apt install mycli
```

使用：

```
$ mycli --help
Usage: mycli [OPTIONS] [DATABASE]

  A MySQL terminal client with auto-completion and syntax highlighting.

  Examples:
    - mycli my_database
    - mycli -u my_user -h my_host.com my_database
    - mycli mysql://my_user@my_host.com:3306/my_database

Options:
  -h, --host TEXT               Host address of the database.
  -P, --port INTEGER            Port number to use for connection. Honors
                                $MYSQL_TCP_PORT.
  -u, --user TEXT               User name to connect to the database.
  -S, --socket TEXT             The socket file to use for connection.
  -p, --password TEXT           Password to connect to the database.
  --pass TEXT                   Password to connect to the database.
  --ssl-ca PATH                 CA file in PEM format.
  --ssl-capath TEXT             CA directory.
  --ssl-cert PATH               X509 cert in PEM format.
  --ssl-key PATH                X509 key in PEM format.
  --ssl-cipher TEXT             SSL cipher to use.
  --ssl-verify-server-cert      Verify server's "Common Name" in its cert
                                against hostname used when connecting. This
                                option is disabled by default.
  -v, --version                 Output mycli's version.
  -D, --database TEXT           Database to use.
  -R, --prompt TEXT             Prompt format (Default: "\t \u@\h:\d> ").
  -l, --logfile FILENAME        Log every query and its results to a file.
  --defaults-group-suffix TEXT  Read MySQL config groups with the specified
                                suffix.
  --defaults-file PATH          Only read MySQL options from the given file.
  --myclirc PATH                Location of myclirc file.
  --auto-vertical-output        Automatically switch to vertical output mode
                                if the result is wider than the terminal
                                width.
  -t, --table                   Display batch output in table format.
  --csv                         Display batch output in CSV format.
  --warn / --no-warn            Warn before running a destructive query.
  --local-infile BOOLEAN        Enable/disable LOAD DATA LOCAL INFILE.
  --login-path TEXT             Read this path from the login file.
  -e, --execute TEXT            Execute command and quit.
  --help                        Show this message and exit.
```

## Navicat Premium

安装以及破解在***[另一篇博文](/2017/ubuntu-dev-environment-to-build/#Navicat-Premium)***里面。

![](https://cdn.yangbingdong.com/img/javaDevEnv/navicat12.png)

## Workbench

MySQL官方开源GUI

下载地址：***[https://dev.mysql.com/downloads/workbench/](https://dev.mysql.com/downloads/workbench/)***

![](https://cdn.yangbingdong.com/img/mysql-related-learning/MySQL%20Workbench_001.png)

# 索引相关

## 如何判断数据库索引是否生效

使用`explain ... \G`分析语句 (使用`\G`可格式化结果)

表结构：

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain01.png)

不使用索引：

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain02.png)

使用索引：

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain03.png)

可以看到，使用`explain`显示了很多列，各个关键字的含义如下：

- `table`：顾名思义，显示这一行的数据是关于哪张表的；

- `type`：这是重要的列，显示连接使用了何种类型。从**最好到最差**的连接类型为：`const`、`eq_reg`、`ref`、`range`、`indexhe`和`ALL`（详情：[*https://dev.mysql.com/doc/refman/5.7/en/explain-output.html#explain-join-types*](https://dev.mysql.com/doc/refman/5.7/en/explain-output.html#explain-join-types)）；

- `possible_keys`：显示可能应用在这张表中的索引。如果为空，没有可能的索引。可以为相关的域从`where`语句中选择一个合适的语句；

- `key`： 实际使用的索引。如果为`NULL`，则没有使用索引。很少的情况下，MySQL会选择优化不足的索引。这种情况下，可以在`Select`语句中使用`USE INDEX（indexname）`来强制使用一个索引或者用`IGNORE INDEX（indexname）`来强制MySQL忽略索引；

- `key_len`：使用的索引的长度。在不损失精确性的情况下，长度越短越好；

- `ref`：显示索引的哪一列被使用了，如果可能的话，是一个常数；

- `rows`：MySQL认为必须检查的用来返回请求数据的行数；

- `Extra`：关于MySQL如何解析查询的额外信息。

    以下是`Extra`返回含义：

    `Distinct`:一旦MYSQL找到了与行相联合匹配的行，就不再搜索了

    `Not exists`: MYSQL优化了`LEFT JOIN`，一旦它找到了匹配`LEFT JOIN`标准的行，就不再搜索了

    `Range checked for each Record（index map:#）`:没有找到理想的索引，因此对于从前面表中来的每一个行组合，MYSQL检查使用哪个索引，并用它来从表中返回行。这是使用索引的最慢的连接之一

    `Using filesort`: 看到这个的时候，查询就需要优化了。MYSQL需要进行额外的步骤来发现如何对返回的行排序。它根据连接类型以及存储排序键值和匹配条件的全部行的行指针来排序全部行

    `Using index`: 列数据是从仅仅使用了索引中的信息而没有读取实际的行动的表返回的，这发生在对表的全部的请求列都是同一个索引的部分的时候

    `Using temporary` 看到这个的时候，查询需要优化了。这里，MYSQL需要创建一个临时表来存储结果，这通常发生在对不同的列集进行`ORDER BY`上，而不是`GROUP BY`上

    `Where used` 使用了`WHERE`从句来限制哪些行将与下一张表匹配或者是返回给用户。如果不想返回表中的全部行，并且连接类型`ALL`或`index`，这就会发生，或者是查询有问题不同连接类型的解释（按照效率高低的顺序排序）

    `system` 表只有一行：`system`表。这是`const`连接类型的特殊情况

    `const`:表中的一个记录的最大值能够匹配这个查询（索引可以是主键或惟一索引）。因为只有一行，这个值实际就是常数，因为MYSQL先读这个值然后把它当做常数来对待

    `eq_ref`:在连接中，MYSQL在查询时，从前面的表中，对每一个记录的联合都从表中读取一个记录，它在查询使用了索引为主键或惟一键的全部时使用

    `ref`:这个连接类型只有在查询使用了不是惟一或主键的键或者是这些类型的部分（比如，利用最左边前缀）时发生。对于之前的表的每一个行联合，全部记录都将从表中读出。这个类型严重依赖于根据索引匹配的记录多少—越少越好

    `range`:这个连接类型使用索引返回一个范围中的行，比如使用>或<查找东西时发生的情况

    `index`: 这个连接类型对前面的表中的每一个记录联合进行完全扫描（比ALL更好，因为索引一般小于表数据）

    `ALL`:这个连接类型对于前面的每一个记录联合进行完全扫描，这一般比较糟糕，应该尽量避免

具体的各个列所能表示的值以及含义可以参考MySQL官方文档介绍，地址：[*https://dev.mysql.com/doc/refman/5.7/en/explain-output.html*](https://dev.mysql.com/doc/refman/5.7/en/explain-output.html)

## 哪些场景会造成索引失效

1. 应尽量避免在 `where` 子句中使用 `!=` 或 `<>` 操作符，否则引擎将放弃使用索引而进行全表扫描

2. 尽量避免在 `where` 子句中使用 `or` 来连接条件，否则将**导致引擎放弃使用索引而进行全表扫描**，即使其中有条件带索引也不会使用，这也是为什么尽量少用 `or` 的原因

3. 对于**多列索引**，**不是使用的第一部分**，则不会使用索引

4. 如果列类型是**字符串**，那一定要在条件中将数据使用**引号**引用起来，否则不会使用索引

   ![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain04.png)

5. `like`的模糊查询以 `%` 开头，索引失效

6. 应尽量**避免**在 `where` 子句中对字段进行**表达式操作**，这将导致引擎放弃使用索引而进行全表扫描

   如：

   ```
   select id from t where num/2 = 100 1
   ```

   应改为:

   ```
   select id from t where num = 100*2；1
   ```

7. 应尽量**避免**在 where 子句中对字段进行**函数操作**，这将导致引擎放弃使用索引而进行全表扫描

   例如：

   ```
   select id from t where substring(name,1,3) = 'abc' – name;1
   ```

   以abc开头的，应改成：

   ```
   select id from t where name like ‘abc%’ 1
   ```

   例如：

   ```
   select id from t where datediff(day, createdate, '2005-11-30') = 0 – '2005-11-30';1
   ```

   应改为:

   ```
   select id from t where createdate >= '2005-11-30' and createdate < '2005-12-1';
   ```

8. 不要在 `where` 子句中的 `=` 左边进行函数、算术运算或其他表达式运算，否则系统将可能无法正确使用索引

9. 如果MySQL估计使用全表扫描要比使用索引快，则不使用索引

10. 不适合键值较少的列（重复数据较多的列）

    > 假如索引列TYPE有5个键值，如果有1万条数据，那么 WHERE TYPE = 1将访问表中的2000个数据块。再加上访问索引块，一共要访问大于2000个的数据块。如果全表扫描，假设10条数据一个数据块，那么只需访问1000个数据块，既然全表扫描访问的数据块少一些，肯定就不会利用索引了。


> 参考：*[http://blog.csdn.net/xlgen157387/article/details/79572598](http://blog.csdn.net/xlgen157387/article/details/79572598)*

# JSON相关

## JSON支持

* 在MySQL 5.7.8中，MySQL支持由RFC 7159定义的本地JSON数据类型，它支持对JSON(JavaScript对象标记)文档中的数据进行有效访问.
* MySQL会对DML JSON数据自动验证。无效的DML JSON数据操作会产生错误.
* 优化的存储格式。存储在JSON列中的JSON文档转换为一种内部格式，允许对Json元素进行快速读取访问.
* MySQL Json类型支持通过虚拟列方式建立索引，从而增加查询性能提升.

### 函数语法

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

### 表结构

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain05.png)

### 插入数据

```
INSERT INTO `user_json` VALUES (1, '{\"name\": \"yang\", \"address\": \"shenyang\"}');
...
```



![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain07.png)

**JSON校验**：

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain06.png)

### 查询

```
select * from user_json where json_extract(data,'$.name')='yang';
select json_extract(data,'$.name') from user_json where json_extract(data,'$.name')='yang';
select data->'$.name' from user_json where data->'$.name'='yang';
```

发现结果集是带有双引号的：

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain08.png)

如果想要去除双引号一般来说我们这样:

```
select JSON_UNQUOTE(json_extract(data,'$.name'))from user_json where json_extract(data,'$.name')='yang';
select  data->>'$.name' from user_json where data->'$.name'='yang';
```

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain09.png)

## JSON如何建立索引

json类型并不能建立索引，但我们可以通过**虚拟列**来建立索引

```
ALTER TABLE user_json ADD COLUMN `virtual_name` varchar(20) GENERATED ALWAYS AS (data->>'$.name') VIRTUAL NULL AFTER `data`;

ALTER TABLE user_json ADD KEY (virtual_name);
```

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain10.png)

![](https://cdn.yangbingdong.com/img/mysql-related-learning/idx-explain11.png)

可以看到索引起作用了~

像时间这些要把周一到周日建索引也是可以的：

```
`dayofweek` tinyint(4) GENERATED ALWAYS AS (dayofweek(SomeDate)) VIRTUAL,
```

或者某些很麻烦的条件：

```
alter table ApiLog add verb_url_hash varbinary(16) GENERATED ALWAYS AS (unhex(md5(CONCAT(verb, ' - ', replace(url,'.xml',''))))) VIRTUAL;
alter table ApiLog add key (verb_url_hash);
```

# MySQL存储引擎MyISAM与InnoDB区别

## MySQL默认存储引擎的变迁

在MySQL 5.1之前的版本中，默认的搜索引擎是MyISAM，从MySQL 5.5之后的版本中，默认的搜索引擎变更为InnoDB。

## MyISAM与InnoDB存储引擎的主要特点

MyISAM存储引擎的特点是：**表级锁**、**不支持事务和全文索引**，适合一些CMS内容管理系统作为后台数据库使用，但是使用大并发、重负荷生产系统上，**表锁结构的特性就显得力不从心**；

以下是MySQL 5.7 MyISAM存储引擎的版本特性：

![](https://cdn.yangbingdong.com/img/mysql-related-learning/mysql-engine01.png)

InnoDB存储引擎的特点是：**行级锁**、**事务安全（ACID兼容）**、**支持外键**、不支持FULLTEXT类型的索引(5.6.4以后版本开始支持FULLTEXT类型的索引)。InnoDB存储引擎提供了具有提交、回滚和崩溃恢复能力的事务安全存储引擎。InnoDB是**为处理巨大量时拥有最大性能而设计的**。它的CPU效率可能是任何其他基于磁盘的关系数据库引擎所不能匹敌的。

以下是MySQL 5.7 InnoDB存储引擎的版本特性：

![](https://cdn.yangbingdong.com/img/mysql-related-learning/mysql-engine02.png)

*注意：* 
InnoDB表的行锁也不是绝对的，假如在执行一个SQL语句时MySQL不能确定要扫描的范围，InnoDB表同样会锁全表，例如`update table set num=1 where name like “a%”`。

两种类型最主要的差别就是InnoDB支持事务处理与外键和行级锁。而MyISAM不支持。所以MyISAM往往就容易被人认为只适合在小项目中使用。

## MyISAM与InnoDB性能测试

下边两张图是官方提供的MyISAM与InnoDB的压力测试结果

![](https://cdn.yangbingdong.com/img/mysql-related-learning/mysql-engine03.png)

![](https://cdn.yangbingdong.com/img/mysql-related-learning/mysql-engine04.png)

可以看出，**随着CPU核数的增加**，**InnoDB的吞吐量反而越好**，而MyISAM，其吞吐量几乎没有什么变化，显然，MyISAM的表锁定机制降低了读和写的吞吐量。

## 事务支持与否

MyISAM是一种非事务性的引擎，使得MyISAM引擎的MySQL可以提供高速存储和检索，以及全文搜索能力，适合数据仓库等查询频繁的应用；

InnoDB是事务安全的；

事务是一种高级的处理方式，如在一些列增删改中只要哪个出错还可以回滚还原，而MyISAM就不可以了。

## MyISAM与InnoDB构成上的区别

（1）每个MyISAM在磁盘上存储成三个文件：

> 第一个文件的名字以表的名字开始，扩展名指出文件类型，.frm文件存储表定义。 
> 第二个文件是数据文件，其扩展名为.MYD (MYData)。 
> 第三个文件是索引文件，其扩展名是.MYI (MYIndex)。

（2）基于磁盘的资源是InnoDB表空间数据文件和它的日志文件，InnoDB 表的 大小只受限于操作系统文件的大小，一般为 2GB。

## MyISAM与InnoDB表锁和行锁的解释

MySQL表级锁有两种模式：表共享读锁（Table Read Lock）和表独占写锁（Table Write Lock）。什么意思呢，就是说对MyISAM表进行读操作时，它不会阻塞其他用户对同一表的读请求，但会阻塞对同一表的写操作；而对MyISAM表的写操作，则会阻塞其他用户对同一表的读和写操作。

InnoDB行锁是通过给索引项加锁来实现的，即**只有通过索引条件检索数据**，**InnoDB才使用行级锁**，**否则将使用表锁**！行级锁在每次获取锁和释放锁的操作需要消耗比表锁更多的资源。在InnoDB两个事务发生死锁的时候，会计算出每个事务影响的行数，然后回滚行数少的那个事务。当锁定的场景中不涉及Innodb的时候，InnoDB是检测不到的。只能依靠锁定超时来解决。

## 是否保存数据库表中表的具体行数

InnoDB 中不保存表的具体行数，也就是说，执行`select count(*) from table` 时，InnoDB要扫描一遍整个表来计算有多少行，但是MyISAM只要简单的读出保存好的行数即可。

注意的是，当`count(*)`语句包含`where`条件时，两种表的操作是一样的。也就是 上述“6”中介绍到的InnoDB使用表锁的一种情况。

## 如何选择

MyISAM适合： 
（1）做很多count 的计算； 
（2）插入不频繁，查询非常频繁，如果执行大量的SELECT，MyISAM是更好的选择； 
（3）没有事务。

InnoDB适合： 
（1）可靠性要求比较高，或者要求事务； 
（2）表更新和查询都相当的频繁，并且表锁定的机会比较大的情况指定数据引擎的创建； 
（3）如果你的数据执行大量的INSERT或UPDATE，出于性能方面的考虑，应该使用InnoDB表； 
（4）DELETE FROM table时，InnoDB不会重新建立表，而是一行一行的 删除； 
（5）LOAD TABLE FROM MASTER操作对InnoDB是不起作用的，解决方法是首先把InnoDB表改成MyISAM表，导入数据后再改成InnoDB表，但是对于使用的额外的InnoDB特性（例如外键）的表不适用。

要注意，创建每个表格的代码是相同的，除了最后的 TYPE参数，这一参数用来指定数据引擎。

## 其他区别

1、对于AUTO_INCREMENT类型的字段，InnoDB中必须包含只有该字段的索引，但是在MyISAM表中，可以和其他字段一起建立联合索引。

2、DELETE FROM table时，InnoDB不会重新建立表，而是一行一行的删除。

3、LOAD TABLE FROMMASTER操作对InnoDB是不起作用的，解决方法是首先把InnoDB表改成MyISAM表，导入数据后再改成InnoDB表，但是对于使用的额外的InnoDB特性(例如外键)的表不适用。

4、 InnoDB存储引擎被完全与MySQL服务器整合，InnoDB存储引擎为在主内存中缓存数据和索引而维持它自己的缓冲池。

5、对于自增长的字段，InnoDB中必须包含只有该字段的索引，但是在MyISAM表中可以和其他字段一起建立联合索引。

6、清空整个表时，InnoDB是一行一行的删除，效率非常慢。MyISAM则会重建表。

# Finally

看到一片美团技术团队的博文非常好：***[https://tech.meituan.com/mysql-index.html](https://tech.meituan.com/mysql-index.html)***