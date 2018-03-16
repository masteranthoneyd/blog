---
title: MySQL杂记
date: 2018-02-16 15:16:18
categories: [MySQL]
tags: [MySQL]
---

![](http://ojoba1c98.bkt.clouddn.com/img/mysql-related-learning/MySQL.png)

# Preface

> MySQL是什么就多说了。。。

<!--more-->

# 安装

## 传统安装



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

![](http://ojoba1c98.bkt.clouddn.com/img/mysql-related-learning/mysql-warning.png)

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

![](http://ojoba1c98.bkt.clouddn.com/img/mysql-related-learning/mycli.gif)

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

![](http://ojoba1c98.bkt.clouddn.com/img/javaDevEnv/navicat12.png)

## Workbench

MySQL官方开源GUI

下载地址：***[https://dev.mysql.com/downloads/workbench/](https://dev.mysql.com/downloads/workbench/)***

![](http://ojoba1c98.bkt.clouddn.com/img/mysql-related-learning/MySQL%20Workbench_001.png)

# 索引相关

## 如何判断数据库索引是否生效

使用`explain ... \G`分析语句 (使用`\G`可格式化结果)

表结构：

![](http://ojoba1c98.bkt.clouddn.com/img/mysql-related-learning/idx-explain01.png)

不使用索引：

![](http://ojoba1c98.bkt.clouddn.com/img/mysql-related-learning/idx-explain02.png)

使用索引：

![](http://ojoba1c98.bkt.clouddn.com/img/mysql-related-learning/idx-explain03.png)

可以看到，使用`explain`显示了很多列，各个关键字的含义如下：

- `table`：顾名思义，显示这一行的数据是关于哪张表的；

- `type`：这是重要的列，显示连接使用了何种类型。从**最好到最差**的连接类型为：`const`、`eq_reg`、`ref`、`range`、`indexhe`和`ALL`（详情：[*https://dev.mysql.com/doc/refman/5.7/en/explain-output.html#explain-join-types*](https://dev.mysql.com/doc/refman/5.7/en/explain-output.html#explain-join-types)）；

- `possible_keys`：显示可能应用在这张表中的索引。如果为空，没有可能的索引。可以为相关的域从`where`语句中选择一个合适的语句；

- `key`： 实际使用的索引。如果为`NULL`，则没有使用索引。很少的情况下，MySQL会选择优化不足的索引。这种情况下，可以在`Select`语句中使用`USE INDEX（indexname）`来强制使用一个索引或者用`IGNORE INDEX（indexname）`来强制MySQL忽略索引；

- `key_len`：使用的索引的长度。在不损失精确性的情况下，长度越短越好；

- `ref`：显示索引的哪一列被使用了，如果可能的话，是一个常数；

- `rows：MySQL`认为必须检查的用来返回请求数据的行数；

- `Extra`：关于MySQL如何解析查询的额外信息。

    以下是`Extra`返回含义：

    `Distinct`:一旦MYSQL找到了与行相联合匹配的行，就不再搜索了

    `Not exists`: MYSQL优化了LEFT JOIN，一旦它找到了匹配LEFT JOIN标准的行，就不再搜索了

    `Range checked for each Record（index map:#）`:没有找到理想的索引，因此对于从前面表中来的每一个行组合，MYSQL检查使用哪个索引，并用它来从表中返回行。这是使用索引的最慢的连接之一

    `Using filesort`: 看到这个的时候，查询就需要优化了。MYSQL需要进行额外的步骤来发现如何对返回的行排序。它根据连接类型以及存储排序键值和匹配条件的全部行的行指针来排序全部行

    `Using index`: 列数据是从仅仅使用了索引中的信息而没有读取实际的行动的表返回的，这发生在对表的全部的请求列都是同一个索引的部分的时候

    `Using temporary` 看到这个的时候，查询需要优化了。这里，MYSQL需要创建一个临时表来存储结果，这通常发生在对不同的列集进行ORDER BY上，而不是GROUP BY上

    `Where used` 使用了WHERE从句来限制哪些行将与下一张表匹配或者是返回给用户。如果不想返回表中的全部行，并且连接类型ALL或index，这就会发生，或者是查询有问题不同连接类型的解释（按照效率高低的顺序排序）

    `system` 表只有一行：system表。这是const连接类型的特殊情况

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

   ![](http://ojoba1c98.bkt.clouddn.com/img/mysql-related-learning/idx-explain04.png)

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

    > 假如索引列TYPE有5个键值，如果有1万条数据，那么 WHERE TYPE = 1将访问表中的2000个数据块。再加上访问索引块，一共要访问大于200个的数据块。如果全表扫描，假设10条数据一个数据块，那么只需访问1000个数据块，既然全表扫描访问的数据块少一些，肯定就不会利用索引了。


> 参考：[*http://blog.csdn.net/xlgen157387/article/details/79572598*](http://blog.csdn.net/xlgen157387/article/details/79572598)

# JSON支持以及建立JSON索引

* 在MySQL 5.7.8中，MySQL支持由RFC 7159定义的本地JSON数据类型，它支持对JSON(JavaScript对象标记)文档中的数据进行有效访问.
* MySQL会对DML JSON数据自动验证。无效的DML JSON数据操作会产生错误.
* 优化的存储格式。存储在JSON列中的JSON文档转换为一种内部格式，允许对Json元素进行快速读取访问.
* MySQL Json类型支持通过虚拟列方式建立索引，从而增加查询性能提升.

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

