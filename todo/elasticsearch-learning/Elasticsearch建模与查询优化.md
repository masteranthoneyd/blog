# 数据建模

![](https://cdn.yangbingdong.com/img/elasticsearch/mapping-design01.png)

> 文档: ***[mapping](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html)***

## Field data types

* 字符串:
  * `text`: 用于全文本字段, 文本会被 Analyzer 分词, **默认不支持聚合分析及排序**, 需要设置 `fielddata` 为 `true`.
  * `keyword`: 用于不需要分词的文本, 适用于 Filter(精确匹配), Sorting 和 Aggregations.
* 数值:
  * 整形:  `byte` / `short` / `integer` / `long`
  * 浮点型: `float` / `half_float` / `scaled_float` / `double`
* 日期: `date`
* 范围: `integer_range` / `long_range` /  `float_range` / `double_range` / `date_range`
* 布尔: `boolean`
* 复合类型:
  * `object`
  * `nested`: 嵌套文档
* 数组: 没有定义专门的数组类型, 插入的时候传数组就是数组了, 但是数组里面的元素类型要相同.
* 专有类型:
  * `ip`
  * `completion`: 搜索提示特殊结构
  * `token_count`: 使用自字段记录 token 数量
  * `join`: 父子文档

## Mapping parameters

* `enable`: 是否需要检索, 排序和聚合分析.
* `index`: 是否需要检索.
* `analyzer` / `search_analyzer`: 指定分词器, 后者用于指定搜索时的分词器
* `norms`: 是否归一化数据, 对于**不需要算分的数据建议关闭**, `keyword` 类型默认为 `false`, `text` 默认为 `true`.
* `index_options`: 针对 `text` 类型, 控制倒排索引中包括哪些信息(`docs` / `freqs` / `positions` / `offsets`, 对于不太注重 `_score` / `highlighting` 的使用场景, 可以设为 `docs` 来**降低内存/磁盘资源消耗**.
* `index_phrase`: 对于需要频繁使用 `phrase` 查询的 `text` 字段, 可以设置为 `true` 来提高搜索速度, 代价是消耗更大的空间.
* `index_prefixes`: 对于需要频繁使用 `prefix` 查询的 `text` 字段, 可以设置 `index_prefixes` 来提高搜索速度.
* `doc_value`: 建立正排索引, 排序和聚合需要用到正排索引, 不需要排序以及聚合的时候可以关闭(节省空间), 非 `text` 字段默认为 `true`.
* `fielddata`: 针对 `text` 类型, 也是用于建立正排索引,  但数据是存在内存中, 而 `doc_value` 是基于硬盘, 所以现在来说 `fielddata` 基本不怎么受欢迎, 因为容易导致 OOM. 对于 `text` 字段, `fielddata` 默认为 `false`.
* `eager_global_ordinals`: 更新频繁, 聚合查询频繁的 `keyword` 类型的字段建议设置为 `true`.
* `store`: 是否专门存储字段, 默认为 `false`. 因为文档所有数据都被存储到 `_source` 字段, 除非你不想将文档存到 `_source` 字段(比如文档中有一个大字段), 这个时候可以将 `store` 设置为 `true`, `_source` 设置为 `false` 来达到存储指定字段的需求.
* `coerce`: 是否强制装换类型, 默认为 `true`, 比如定义的类型为 `integer`, 但传过来的是字符转"5", 这时候 ES 会自动转换.
* `ignore-malformed`: 当转换失败时是否抛出异常, 默认为 true.
* `dynamic`: 是否动态判断字段类型, 默认为 `true`, `false` 表示忽略新字段, `strict`  检测到新字段则抛出异常.
* `fields`: 指定子字段
* `format`: 针对 `date` 类型, 指定自定义时间格式
* `ignore_above`: 超过指定长度则不被索引
* `null-value`: 对空数据指定默认值

## 数据建模最佳实践

* 如何构建索引: 将数据插入到一个新的 index, 拿到自动生成的 mapping, 再作调整
* 使用别名
* 精确的字段设计:

  * 不需要检索, 排序和聚合分析? `enable` 设置为 `false`.
  * 不需要排序与聚合? `doc_value` 设置为 `false`.
  * 不需要索引? `index` 设置为 `false`.
  * 不需要算分? `norms` 设置为 `false`(一般针对 `text` 类型而言, `keyword` 默认就为 `false`).

  * 能不用 `text` 字段的场景就不要用, `keyword` 字段无论从索引, 搜索的性能还是空间的节省都比 `text` 优秀.
* 优先考虑 Denormalization 设计: Object -> Nested -> Child/Parent
* 避免设计过多的字段:

  * 大量的字段会对集群的性能产生影响, 因为 mapping 信息保存在 Cluster State 中, 影响同步.
  * 字段过多不易维护.
  * 通过 `index.mapping.total_fields.limt` 设置字段最大上限, 默认为 1000.
  * 如果真实数据有很多字段, 比如 cookie, 可以通过 nested 关系, 设计 key / value 字段化解, 缺点就是查询语句变复杂了.
* 生产中尽量不要打开 `dynamic`, 建议使用 `strict`.
* 避免使用正则查询, 性能不好.
* 如果需要聚合的字段有空值, 可能会导致聚合查询的不准确, 通过 `null_value` 设计默认值.
* 可以通过 `_meta` 自定义字段, 比如版本, 对应类等

示例:

```json
PUT /blogs_index/
{
  "settings": {
    "index": {
      "number_of_shards": 1,
      "number_of_replicas": 1
    },
    "analysis": {
      "analyzer": {
        "pinyin_analyzer": {
          "tokenizer": "standard",
          "filter": [
            "my_pinyin"
          ]
        }
      },
      "filter": {
        "my_pinyin": {
          "type": "pinyin",
          "keep_first_letter": true,
          "keep_separate_first_letter": true,
          "keep_full_pinyin": true,
          "keep_original": true,
          "limit_first_letter_length": 16,
          "lowercase": true
        }
      }
    }
  },
  "mappings": {
    # 禁止新增字段
    "dynamic": "strict",
    "properties": {
      "id": {
        "type": "integer"
      },
      "author": {
        "type": "text",
        # 对作者使用拼音分词
        "analyzer": "pinyin_analyzer",
        "fields": {
          # 建立多字段，用于聚合
          "keyword": {
            "type": "keyword",
            "index":false
          }
        }
      },
      # 博客的分类，支持 term 查询
      "blog_sort": {
        "type": "keyword",
        # 需要聚合，且数据量较大，但唯一值较少
        "eager_global_ordinals": true,
        # 提升该字段的权重
        "boost": 3
      },
      "title": {
        "type": "text",
        "analyzer": "ik_max_word",
        # 检索的分词没必要细粒度，提升效率
        "search_analyzer": "ik_smart",
        # 对 标题 不需要聚合、排序
        "doc_values": false,
        # 提升该字段的权重
        "boost": 5
      },
      "content": {
        "type": "text",
        "analyzer": "ik_max_word",
        "search_analyzer": "ik_smart",
        # 博客内容为大字段，单独存储，用于查询返回
        "store": true,
        # 不需要聚合、排序
        "doc_values": false
      },
      "update_time":{
        "type": "date",
        # 规定格式，提高可读性
        "format": ["yyyy-MM-dd HH:mm:ss"],
        # 该字段仅用于显示，不用检索、聚合、排序【非object类型，不能使用 enabled 参数】
        "index":false,
        "doc_values": false
      },
      "create_time":{
        "type": "date",
        "format": ["yyyy-MM-dd HH:mm:ss"]
      }
    }
  }
}
```



# 搜索选择

![](https://cdn.yangbingdong.com/img/elasticsearch/search-method-choose01.png)

# 性能优化

## 优化搜索速度

> 官方原文: ***[tune-for-search-speed](https://www.elastic.co/guide/en/elasticsearch/reference/current/tune-for-search-speed.html)***

以下是总结:

* 将更多地内存交给 filesystem cache(至少一半)
* 使用更快的硬盘
* 优化建模, 避免使用 join 关系(内嵌以及父子文档)
* 尽量不要查询太多的字段, 对于 `query_string` 与 `multi_match` 而言, 越多的字段搜索速度越慢. 可以考虑使用 `copy_to` 汇总到一个字段
* 预索引数据, 如果 `range` 聚合总在一个固定的范围, 比如需要聚合 price 的值为10 到 100, 那么可以新增一个 `price_range` 的 `keyword`, 值为 `10-100`, 然后使用 term aggregations
* `keyword` 类型的 `term` 查询要比数字类型的快, 如果没有用到 `range`, 可以考虑设置成 `keyword`
* 避免使用脚本
* `date` 类型可以四舍五入查询, 从用户体验上可以接收, 并且可以更好地利用缓存
* 经常使用聚合查询并且更新频繁的 `keyword`, 建议将 `eager_global_ordinals` 设置为 `true`
* 对于固定排序的场景, 比如按更新时间排序, 或者经常用于 conjunctions(连词查询, a AND b AND ...)并且cardinality(基数) 比较低的字段, 可以使用 [*预排序*](https://www.elastic.co/guide/en/elasticsearch/reference/current/index-modules-index-sorting.html) 提高查询性能. 缺点是对于相关性分数排序的场景无法优化, 并且对写入性能有影响.
* 使用 *[`preference`](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-your-data.html#search-preference)* 参数将查询请求路由到同一个节点, 可以更好地利用缓存, 但却与负载均衡相侼论.
* 使用 Kibana 提供的 Search Profiler 分析查询语句.
* 对于 `text` 类型而言, 不关心 `_score` 以及 `highlighting`, 可以将 `index_options` 设置为 `docs`, 频繁使用 `phrase` 查询可以将 `index_phrase` 设置为`true`, 频繁使用 `prefix` 查询可以设置 `index_prefixes` 参数.

## Indexing 优化

***[tune-for-indexing-speed](https://www.elastic.co/guide/en/elasticsearch/reference/current/tune-for-indexing-speed.html)***

## 其他优化

* 对于 PB 级别数据, 建议使用模板+Rollover+Curator动态创建索引.
* 建议分片数 = 索引大小/分片大小经验值(30GB, 官方建议一个分片大小应该在20到40GB)
* 如果对实时性要求不高, 可适量增加 `refresh_interval`(默认是1s)

# IK 分词器使用

> ***[https://github.com/medcl/elasticsearch-analysis-ik](https://github.com/medcl/elasticsearch-analysis-ik)***

![](https://cdn.yangbingdong.com/img/elasticsearch/analyzer-component.png)

## 安装

直接安装:

```
{ES_HOME}/bin/elasticsearch-plugin install --batch https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v7.4.2/elasticsearch-analysis-ik-7.4.2.zip
```

或者直接集成到镜像中:

```dockerfile
FROM elasticsearch:7.4.2
MAINTAINER yangbingdong <yangbingdong1994@gmail.com>
ARG TZ
ENV TZ=${TZ:-"Asia/Shanghai"}
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v7.4.2/elasticsearch-analysis-ik-7.4.2.zip \
  && /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch https://github.com/medcl/elasticsearch-analysis-pinyin/releases/download/v7.4.2/elasticsearch-analysis-pinyin-7.4.2.zip \
  && /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch https://github.com/medcl/elasticsearch-analysis-stconvert/releases/download/v7.4.2/elasticsearch-analysis-stconvert-7.4.2.zip \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo $TZ > /etc/timezone
```

## 自定义词典

修改 `${ES_HOME}/config/analysis-ik/IKAnalyzer.cfg.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
    <comment>IK Analyzer 扩展配置</comment>
    <!--用户可以在这里配置自己的扩展字典 -->
    <entry key="ext_dict">custom/mydict.dic;extra_main.dic</entry>
    <!--用户可以在这里配置自己的扩展停止词字典-->
    <entry key="ext_stopwords">extra_stopword.dic</entry>
    <!--用户可以在这里配置远程扩展字典 -->
    <entry key="remote_ext_dict">words_location</entry>
    <!--用户可以在这里配置远程扩展停止词字典-->
    <entry key="remote_ext_stopwords">words_location</entry>
</properties>
```

如果用的是 Docker 方式, 可以直接挂载进去:

```yaml
version: '3'
services:
  elk-elasticsearch:
    image: yangbingdong/elasticsearch-ik-pinyin:7.4.2
    container_name: elasticsearch
    ports:
      - "9200:9200"
    restart: always
    environment:
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - ELASTIC_PASSWORD=elastic
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - ./config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
      - ./data:/usr/share/elasticsearch/data
      - ./config/IKAnalyzer.cfg.xml:/usr/share/elasticsearch/config/analysis-ik/IKAnalyzer.cfg.xml
      - ./config/mydict.dic:/usr/share/elasticsearch/config/analysis-ik/custom/mydict.dic
    networks:
      backend:
        aliases:
          - elasticsearch

# docker network create -d=overlay --attachable backend
# docker network create --opt encrypted -d=overlay --attachable --subnet 10.10.0.0/16 backend
networks:
  backend:
    external:
      name: backend
```

## 同义词

主要通过 token filter 实现: `synonym` 或者 `synonym_graph`.

在进行同义词搜索时, 有如下的几种方案:

- 在建立索引时 (indexing), 通过 analyzer 建立 synonyms 的反向索引
- 在 query 时，通过 search analyzer 对查询的词建立 synonyms
- 在 indexing 及 query 时，同时建立反向索引中的 synonym 及在 query 时为查询的词建立 synonyms (对精度有一定影响)

```
DELETE /s-test
PUT /s-test
{
  "settings": {
    "index": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "analysis": {
      "filter": {
        "graph_synonyms": {
          "type": "synonym_graph",
          "synonyms": [
            "土豆,洋芋,马铃薯"
          ]
        }
      },
      "analyzer": {
        "my_ik_max_word": {
          "type": "custom",
          "tokenizer": "ik_max_word",
          "filter": ["graph_synonyms"]
        }
      }
    }
  },
  "mappings": {
    "dynamic": false,
    "properties": {
      "id": {
        "type": "integer"
      },
      "title": {
        "type": "text",
        "analyzer": "my_ik_max_word"
      }
    }
  }
}

POST /s-test/_doc/1
{
  "title": "我要吃土豆"
}

POST /s-test/_search
{
  "query": {
    "match": {
      "author": "马铃薯和土豆"
    }
  }
}

GET /s-test/_termvectors/1?fields=title
```

另外, 同义词还可以通过 `synonyms_path` 指定(`synonyms_path` 的位置是以ES的 `config` 开始算的). 例如同义词文件在 `${ES_HOME}/config/analysis/synonyms.txt`, 则 `synonyms_path` 为 `analysis/synonyms.txt`.

同义词文件示例:

```
# 当expand=true时, 只要匹配到以下任意一个 token, 都会变成下面三个 token
# 当expand=false时, 则匹配到下面任意一个, 转换成第一个
土豆,洋芋,马铃薯

# 匹配到左边任意一个, 转换为右边
# 这样写会忽略expand参数
洋芋,马铃薯 => 土豆
```

## 拼音

> ***[https://github.com/medcl/elasticsearch-analysis-pinyin](https://github.com/medcl/elasticsearch-analysis-pinyin)***

```
DELETE /s-test
PUT /s-test
{
  "settings": {
    "index": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "analysis": {
      "filter": {
        "my_pinyin": {
          "type": "pinyin",
          "keep_first_letter": true,
          "keep_separate_first_letter": false,
          "limit_first_letter_length": 16,
          "keep_full_pinyin": true,
          "keep_joined_full_pinyin": false,
          "keep_none_chinese": true,
          "keep_none_chinese_together": true,
          "keep_none_chinese_in_first_letter": true,
          "keep_none_chinese_in_joined_full_pinyin": false,
          "none_chinese_pinyin_tokenize": false,
          "keep_original": false,
          "lowercase": true,
          "trim_whitespace": true,
          "remove_duplicated_term": false,
          "ignore_pinyin_offset": true
        }
      },
      "analyzer": {
        "my_pinyin": {
          "type": "custom",
          "tokenizer": "ik_smart",
          "filter": [
            "my_pinyin"
          ]
        }
      }
    }
  },
  "mappings": {
    "dynamic": false,
    "properties": {
      "id": {
        "type": "integer"
      },
      "name": {
        "type": "text",
        "analyzer": "ik_max_word",
        "fields": {
          "pinyin": {
            "type": "text",
            "analyzer": "my_pinyin",
            "search_analyzer": "pinyin"
          }
        }
      }
    }
  }
}

POST /s-test/_analyze
{
  "field": "name.pinyin",
  "text": "Iphone手机"
}

POST /s-test/_doc/1
{
  "name": "IPhone 苹果手机"
}

POST /s-test/_search
{
  "query": {
    "multi_match": {
      "fields": ["name", "name.pinyin"],
      "query": "shouji",
      "type": "most_fields"
    }
  }
}
```

拼音分词器这里有个小问题, 当字段有非中文的时候, 比如 IPhone 手机, 默认情况下, 是会将 IPhone 拆分成单个字母, 如果想要保留非中文, 可以将 `none_chinese_pinyin_tokenize` 设置成 `false`. 但是这样又会导致搜索的时候输入拼音时, 导致拼音不会被分词, 这种情况下可以将 `search_analyzer` 设置为 `pinyin`.

可以在程序中做这样的处理, 输入的字符串中有非中文时, 将非中文放到 `pinyin` 字段搜索(通过正则提取).

## 繁体转简体

>  ***[https://github.com/medcl/elasticsearch-analysis-stconvert](https://github.com/medcl/elasticsearch-analysis-stconvert)***

```
DELETE /s-test
PUT /s-test
{
  "settings": {
    "index": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "analysis": {
      "char_filter": {
        "tsconvert": {
          "type": "stconvert",
          "convert_type": "t2s"
        }
      },
      "analyzer": {
        "my_ik_smart": {
          "type": "custom",
          "char_filter": "tsconvert",
          "tokenizer": "ik_smart"
        }
      }
    }
  },
  "mappings": {
    "dynamic": false,
    "properties": {
      "id": {
        "type": "integer"
      },
      "ts": {
        "type": "text",
        "analyzer": "my_ik_smart"
      }
    }
  }
}

POST /s-test/_analyze
{
  "field": "ts",
  "text": "國際手机"
}
```
