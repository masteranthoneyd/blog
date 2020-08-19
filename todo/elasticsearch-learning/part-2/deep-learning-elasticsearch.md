# 词项(Term)与全文(Match)查询

## 基于词项的查询

* Term 是表达语意的最小单位
* 特点:
  * Term Level Query: Term Query / Range Query / Exists Query / Prefix Query / Wildcard Query
  * Term 查询**不会将输入进行分词**, 而是将它作为一个整体到倒排索引中精确查找, 并使用相关度算分公式为每个包含该词项的文档进行**相关度算分**
  * 可以通过 **Constant Score** 将查询转换成一个 Filtering, **避免算分**, **并利用缓存**, 从而**提高性能**

例子:

```
DELETE products
PUT products
{
  "settings": {
    "number_of_shards": 1
  }
}


POST /products/_bulk
{ "index": { "_id": 1 }}
{ "productID" : "XHDK-A-1293-#fJ3","desc":"iPhone" }
{ "index": { "_id": 2 }}
{ "productID" : "KDKE-B-9947-#kL5","desc":"iPad" }
{ "index": { "_id": 3 }}
{ "productID" : "JODL-X-1937-#pV7","desc":"MBP" }

GET /products

POST /products/_search
{
  "query": {
    "term": {
      "desc": {
        //"value": "iPhone"
        "value":"iphone"
      }
    }
  }
}

POST /products/_search
{
  "query": {
    "term": {
      "desc.keyword": {
        //"value": "iPhone"
        "value":"iphone"
      }
    }
  }
}


POST /products/_search
{
  "query": {
    "term": {
      "productID": {
        "value": "XHDK-A-1293-#fJ3"
      }
    }
  }
}

POST /products/_search
{
  //"explain": true,
  "query": {
    "term": {
      "productID.keyword": {
        "value": "XHDK-A-1293-#fJ3"
      }
    }
  }
}




POST /products/_search
{
  "explain": true,
  "query": {
    "constant_score": {
      "filter": {
        "term": {
          "productID.keyword": "XHDK-A-1293-#fJ3"
        }
      }

    }
  }
}
```

## 基于全文的查询

* 基于全文的查询
  * Match Query / Match Phrase Query / Query String Query
* 特点
  * 会将输入进行分词, 然后每个词项进行底层的查询, 最终合并结果, 并为每个文档生成一个算分.

![](https://cdn.yangbingdong.com/img/elasticsearch/match-query-processing.png)

例子:

```
#设置 position_increment_gap
DELETE groups
PUT groups
{
  "mappings": {
    "properties": {
      "names":{
        "type": "text",
        "position_increment_gap": 0
      }
    }
  }
}

GET groups/_mapping

POST groups/_doc
{
  "names": [ "John Water", "Water Smith"]
}

POST groups/_search
{
  "query": {
    "match_phrase": {
      "names": {
        "query": "Water Water",
        "slop": 100
      }
    }
  }
}


POST groups/_search
{
  "query": {
    "match_phrase": {
      "names": "Water Smith"
    }
  }
}
```

# 结构化搜索

结构化搜索(Structured search) 是指对结构化数据的搜索:

* 日期,布尔类型和数字都是结构化的
* 文本也可以是结构化的
  * 一个博客可能被标记了了标签, 例例如, 分布式(distributed)和搜索(search)
  * 电商网站上的商品都有 UPCs(通用产品码 Universal Product Codes)或其他的唯一标
    识, 它们都需要遵从严格规定的, 结构化的格式

ES 中的结构化搜索:

* 布尔, 时间, 日期和数字这类**有精准格式**的数据可以进行**逻辑操作**, 包括比较数字或时间的范围, 或判定两个值的大小.
* 结构化的文本可以做精确匹配(Term 查询)或者部分匹配(Prefix 前缀查询)
* 结构化结果只有是或否两个值, 根据场景需要, 可以**决定结构化搜索是否需要打分**(Constant Score)

下面是例子.

插入数据:

```
#结构化搜索，精确匹配
DELETE products
POST /products/_bulk
{ "index": { "_id": 1 }}
{ "price" : 10,"avaliable":true,"date":"2018-01-01", "productID" : "XHDK-A-1293-#fJ3" }
{ "index": { "_id": 2 }}
{ "price" : 20,"avaliable":true,"date":"2019-01-01", "productID" : "KDKE-B-9947-#kL5" }
{ "index": { "_id": 3 }}
{ "price" : 30,"avaliable":true, "productID" : "JODL-X-1937-#pV7" }
{ "index": { "_id": 4 }}
{ "price" : 30,"avaliable":false, "productID" : "QQPX-R-3956-#aD8" }

GET products/_mapping
```

布尔值:

```
#对布尔值 match 查询，有算分
POST products/_search
{
  "profile": "true",
  "explain": true,
  "query": {
    "term": {
      "avaliable": true
    }
  }
}

#对布尔值，通过constant score 转成 filtering，没有算分
POST products/_search
{
  "profile": "true",
  "explain": true,
  "query": {
    "constant_score": {
      "filter": {
        "term": {
          "avaliable": true
        }
      }
    }
  }
}

#数字类型 terms, 价格为20或者30
POST products/_search
{
  "query": {
    "constant_score": {
      "filter": {
        "terms": {
          "price": [
            "20",
            "30"
          ]
        }
      }
    }
  }
}
```

数字 Range:

```
#数字 Range 查询
GET products/_search
{
    "query" : {
        "constant_score" : {
            "filter" : {
                "range" : {
                    "price" : {
                        "gte" : 20,
                        "lte"  : 30
                    }
                }
            }
        }
    }
}


# 日期 range
POST products/_search
{
    "query" : {
        "constant_score" : {
            "filter" : {
                "range" : {
                    "date" : {
                      "gte" : "now-1y"
                    }
                }
            }
        }
    }
}
```

* gt / lt: 大于 / 小于
* gte / lte: 大于等于 / 小于等于

日期 Range:

```
# 日期 range
POST products/_search
{
    "query" : {
        "constant_score" : {
            "filter" : {
                "range" : {
                    "date" : {
                      "gte" : "now-1y"
                    }
                }
            }
        }
    }
}
```

日期表达式: 2014-01-01 00:00:00||+1M
y: 年, M: 月, w: 周, d: 天, H/h: 小时, m: 分钟, s: 秒

查找多个精准值:

```
POST products/_search
{
  "query": {
    "constant_score": {
      "filter": {
        "terms": {
          "price": [
            "20",
            "30"
          ]
        }
      }
    }
  }
}

POST products/_search
{
  "query": {
    "constant_score": {
      "filter": {
        "terms": {
          "productID.keyword": [
            "QQPX-R-3956-#aD8",
            "JODL-X-1937-#pV7"
          ]
        }
      }
    }
  }
}
```

处理多值字段(处理多值字段, **term 查询是包含**, **而不是等于**):

```
POST /movies/_bulk
{ "index": { "_id": 1 }}
{ "title" : "Father of the Bridge Part II","year":1995, "genre":"Comedy"}
{ "index": { "_id": 2 }}
{ "title" : "Dave","year":1993,"genre":["Comedy","Romance"] }

POST movies/_search
{
  "query": {
    "constant_score": {
      "filter": {
        "term": {
          "genre.keyword": "Comedy"
        }
      }
    }
  }
}
```

# 相关性算分

* 搜索的相关性算分, 描述了一个文档和查询语句**匹配的程度**, 算分结果体现在 `_score` 字段.
* 打分的本质是排序, 需要把最符合用户需求文档排在前面, ES 5 之前, 默认的相关性算分
  采用 **TF-IDF**(Term Frequency-Inverse Document Frequency), 现在采用 **BM 25**(Best Match, 貌似是经过 25 次迭代调整之后得出的算法, 它也是基于 TF-IDF 进化来的).

![](https://cdn.yangbingdong.com/img/elasticsearch/es-tf-idf.png)

![](https://cdn.yangbingdong.com/img/elasticsearch/es-bm-25.png)

## Boosting Query

看一个例子:

```
PUT testscore/_bulk
{ "index": { "_id": 1 }}
{ "content":"we use Elasticsearch to power the search" }
{ "index": { "_id": 2 }}
{ "content":"we like elasticsearch" }
{ "index": { "_id": 3 }}
{ "content":"The scoring of documents is caculated by the scoring formula" }
{ "index": { "_id": 4 }}
{ "content":"you know, for search" }

POST /testscore/_search
{
  "query": {
    "match": {
      "content": "elasticsearch"
    }
  }
}
```

这个搜索的结果有两条数据, 分别是id为1跟2的文档, 但是2文档的得分会更高, 因为根据 TF-IDF 公式, 2的文档长度更短, 所以它的得分更高, 如果要使1排在前面, 可以使用 Boosting Query:

```
POST testscore/_search
{
    "query": {
        "boosting" : {
            "positive" : {
                "term" : {
                    "content" : "elasticsearch"
                }
            },
            "negative" : {
                 "term" : {
                     "content" : "like"
                }
            },
            "negative_boost" : 0.2
        }
    }
}
```

参数 boost的含义:

* 当 boost > 1 时,打分的相关度相对性提升
* 当 0 < boost < 1 时,打分的权重相对性降低
* 当 boost < 0 时,贡献负分

# Query & Filtering 与多字符串串多字段查询

一般高级的搜索功能都是多项的复合搜索, 即对多个字段的进行搜索. 在 Elasticsearch 中有 Query 和 Filter 两种不同的 Context:

* Query Context: 相关性算分
* Filter Context: 不需要算分, 可以利用 Cache, 性能更好

Elasticsearch 提供 **bool Query** 进行复合查询, 一个 bool 查询, 是一个或多个查询子句的组合.

## bool 查询

bool 查询包括4种子句, 2个会影响算分, 两个不会:

| 子语句   | 说明                                      |
| -------- | ----------------------------------------- |
| must     | 必须匹配,  贡献算分                       |
| should   | 选择性匹配, 贡献算分                      |
| must_not | Filter Context 查询字句句, 必须不不能匹配 |
| filter   | Filter Context 必须匹配, 但是不不贡献算分 |

查询语法:

```
POST /products/_bulk
{ "index": { "_id": 1 }}
{ "price" : 10,"avaliable":true,"date":"2018-01-01", "productID" : "XHDK-A-1293-#fJ3" }
{ "index": { "_id": 2 }}
{ "price" : 20,"avaliable":true,"date":"2019-01-01", "productID" : "KDKE-B-9947-#kL5" }
{ "index": { "_id": 3 }}
{ "price" : 30,"avaliable":true, "productID" : "JODL-X-1937-#pV7" }
{ "index": { "_id": 4 }}
{ "price" : 30,"avaliable":false, "productID" : "QQPX-R-3956-#aD8" }

#基本语法
POST /products/_search
{
  "query": {
    "bool" : {
      "must" : {
        "term" : { "price" : "30" }
      },
      "filter": {
        "term" : { "avaliable" : "true" }
      },
      "must_not" : {
        "range" : {
          "price" : { "lte" : 10 }
        }
      },
      "should" : [
        { "term" : { "productID.keyword" : "JODL-X-1937-#pV7" } },
        { "term" : { "productID.keyword" : "XHDK-A-1293-#fJ3" } }
      ],
      "minimum_should_match" :1
    }
  }
}
```

* 子查询可以任意顺序出现
* 可以嵌套多个查询
* 如果你的 bool 查询中, 没有 must 条件, should 中必须至少满足一条查询

bool 嵌套:

```
#嵌套，实现了 should not 逻辑
POST /products/_search
{
  "query": {
    "bool": {
      "must": {
        "term": {
          "price": "30"
        }
      },
      "should": [
        {
          "bool": {
            "must_not": {
              "term": {
                "avaliable": "false"
              }
            }
          }
        }
      ],
      "minimum_should_match": 1
    }
  }
}
```

### 控制字段的 Boosting

下面例子中, 如果不设置 boost, 则两个文档的 `_score` 是一样的, 则按 `_id` 排序了, 如果需要分数更倾向于第二个文档, 可以通过控制 `boost` 来达到效果: 

```
DELETE blogs
POST /blogs/_bulk
{ "index": { "_id": 1 }}
{"title":"Apple iPad", "content":"Apple iPad,Apple iPad" }
{ "index": { "_id": 2 }}
{"title":"Apple iPad,Apple iPad", "content":"Apple iPad" }


POST blogs/_search
{
  "query": {
    "bool": {
      "should": [
        {"match": {
          "title": {
            "query": "apple,ipad",
            "boost": 2
          }
        }},

        {"match": {
          "content": {
            "query": "apple,ipad"
          }
        }}
      ]
    }
  }
}
```

### Boosting Query

再来看一个例子, 先插入数据:

```
DELETE news
POST /news/_bulk
{ "index": { "_id": 1 }}
{ "content":"Apple Mac" }
{ "index": { "_id": 2 }}
{ "content":"Apple iPad" }
{ "index": { "_id": 3 }}
{ "content":"Apple employee like Apple Pie and Apple Juice" }
```

如果要**优先**搜索苹果公司的产品, 采用以下查询都是不行的:

```
POST news/_search
{
  "query": {
    "bool": {
      "must": {
        "match":{"content":"apple"}
      }
    }
  }
}

POST news/_search
{
  "query": {
    "bool": {
      "must": {
        "match":{"content":"apple"}
      },
      "must_not": {
        "match":{"content":"pie"}
      }
    }
  }
}
```

可以通过 Boosting query 解决:

```
POST news/_search
{
  "query": {
    "boosting": {
      "positive": {
        "match": {
          "content": "apple"
        }
      },
      "negative": {
        "match": {
          "content": "pie"
        }
      },
      "negative_boost": 0.5
    }
  }
}
```

### or 功能实现注意点

看一下这个查询, 不仅返回A和B中的至少一个, 也返回了没有A也没有B的情况:

```
 {
   "query": {
     "bool": {
       "fileter":[
           {"range":{"date.keyword":{"gt":"20170101","lt":"20170201"}}}
       ]
       "should": [
           {"term": {"A.keyword": "0000000000"}},
           {"term": {"B.keyword": "0000000001"}}
      ]
    }
  }
}
```

因为上面查询"隐藏"了一个参数: `minimum_should_match`, 当存在 `should` 查询并且没有 `must` 与 `filter` 时, 这个值为1, 也就是至少匹配一个, 其他情况下, `minimum_should_match` 的值为 0.

所以有两种方式实现这个 or 的逻辑:

* 将 `minimum_should_match` 设置成1
* 使用 `must` 将 `should` 包起来

# 单字符串多字段查询

## Dis Max Query

![](https://cdn.yangbingdong.com/img/elasticsearch/dis-max-query-case.png)

先来看一个例子:

```
DELETE /blogs
PUT /blogs/_doc/1
{
    "title": "Quick brown rabbits",
    "body":  "Brown rabbits are commonly seen."
}

PUT /blogs/_doc/2
{
    "title": "Keeping pets healthy",
    "body":  "My quick brown fox eats rabbits on a regular basis."
}

POST /blogs/_search
{
    "query": {
        "bool": {
            "should": [
                { "match": { "title": "Brown fox" }},
                { "match": { "body":  "Brown fox" }}
            ]
        }
    }
}
```

我们期望是优先展示第二个文档, 因为目测文档二条件更为符合, 但结果却是:

![](https://cdn.yangbingdong.com/img/elasticsearch/dis-max-query-result.png)

这是因为 bool should 算分策略导致的:

* 查询 should 语句中的两个查询
* 加和两个查询的评分
* 乘以匹配语句句的总数
* 除以所有语句句的总数

这时候可以使用 **Disjunction max query**, 这个查询将任何与**任一查询**匹配的文档作为结果返回, 采用字段上最匹配的评分最终评分返回:

```
POST /blogs/_search
{
  "explain": true, 
    "query": {
        "dis_max": {
            "queries": [
                { "match": { "title": "Brown fox" }},
                { "match": { "body":  "Brown fox" }}
            ]
        }
    }
}
```

但是某些情况下(比如查询 `Quick pets`), 同时匹配 title 和 body 字段的文档比只与一个字段匹配的文档的相关度更高, 但 disjunction max query 查询只会简单地使用单个最佳匹配语句的评分 `_score` 作为整体评分, 怎么办?

这时候可以使用 **Tie Breaker** 参数调整

* 获得最佳匹配语句的评分 `_score`
* 将**其他匹配语句的评分**与 `tie_breaker` 相乘
* 对以上评分**求和**并规范化

```
POST blogs/_search
{
    "query": {
        "dis_max": {
            "queries": [
                { "match": { "title": "Quick pets" }},
                { "match": { "body":  "Quick pets" }}
            ],
            "tie_breaker": 0.2
        }
    }
}
```

>  Tier Breaker 是一个介于 0-1 之间的浮点数, 0代表使用最佳匹配, 1 代表所有语句同等重要.

## Multi Match

这个 API 也是单字符串多字段查询的. 主要有三种场景.

### Best Fields

当字段之间相互竞争, 又相互关联. 例如 title 和 body 这样的字段, 评分来自最匹配字段

```
POST blogs/_search
{
    "query": {
        "dis_max": {
            "queries": [
                { "match": { "title": "Quick pets" }},
                { "match": { "body":  "Quick pets" }}
            ],
            "tie_breaker": 0.2
        }
    }
}

// 这个等价于上面
POST blogs/_search
{
  "query": {
    "multi_match": {
      "type": "best_fields",
      "query": "Quick pets",
      "fields": ["title","body"],
      "tie_breaker": 0.2,
      "minimum_should_match": "20%"
    }
  }
}
```

* Best Fields 是默认类型, 可以不用指定
* Minimum should match 等参数可以传递到生成的 query 中

### Most Fields

处理英文内容时一种常见的手段是, 在主字段( English Analyzer)抽取词干, 加入同义词, 以匹配更更多的文档. 相同的文本,加入子字段(Standard Analyzer)以提供更加精确的匹配, 其他字段作为匹配文档提高高相关度的信号, 匹配字段越多则越好.

比如下面场景中, 文档1的分数比文档2的要高(受英文分词器的影响, 导致精确度降低):

```
DELETE /titles
PUT /titles
{
  "mappings": {
    "properties": {
      "title": {
        "type": "text",
        "analyzer": "english"
      }
    }
  }
}

POST titles/_bulk
{ "index": { "_id": 1 }}
{ "title": "My dog barks" }
{ "index": { "_id": 2 }}
{ "title": "I see a lot of barking dogs on the road " }


GET titles/_search
{
  "query": {
    "match": {
      "title": "barking dogs"
    }
  }
}
```

这时候可以使用多数字段匹配解决:

```
DELETE /titles
PUT /titles
{
  "mappings": {
    "properties": {
      "title": {
        "type": "text",
        "analyzer": "english",
        "fields": {"std": {"type": "text","analyzer": "standard"}}
      }
    }
  }
}

POST titles/_bulk
{ "index": { "_id": 1 }}
{ "title": "My dog barks" }
{ "index": { "_id": 2 }}
{ "title": "I see a lot of barking dogs on the road " }

GET /titles/_search
{
  "profile": "true", 
   "query": {
        "multi_match": {
            "query":  "barking dogs",
            "type":   "most_fields",
            "fields": [ "title", "title.std" ]
        }
    }
}

// 自定义 boost 值
GET /titles/_search
{
   "query": {
        "multi_match": {
            "query":  "barking dogs",
            "type":   "most_fields",
            "fields": [ "title^10", "title.std" ]
        }
    }
}
```

### Cross Field

 对于某些实体,例如人名, 地址, 图书信息. 需要在多个字段中确定信息, 单个字段只能作为整体
的一部分, 希望在任何这些列出的字段中找到尽可能多的词.

![](https://cdn.yangbingdong.com/img/elasticsearch/multi-match-cross-fields01.png)

* 无法使用用 Operator
* 可以用 copy_to 解决, 但是需要额外的存储空间

使用跨字段搜索:

![](https://cdn.yangbingdong.com/img/elasticsearch/multi-match-cross-fields02.png)

* 支持使用用 Operator
* 与 copy_to,  相比, 其中一个优势就是它可以在搜索时为单个字段提升权重

## 分词器实战

* IK 分词器: ***[https://github.com/medcl/elasticsearch-analysis-ik](https://github.com/medcl/elasticsearch-analysis-ik)***
* 拼音分词器: ***[https://github.com/medcl/elasticsearch-analysis-pinyin](https://github.com/medcl/elasticsearch-analysis-pinyin)***
* 繁体转换器: ***[https://github.com/medcl/elasticsearch-analysis-stconvert](https://github.com/medcl/elasticsearch-analysis-stconvert)***

```
DELETE prod
PUT prod
{
  "settings": {
    "refresh_interval": "5s",
    "number_of_replicas": 5,
    "number_of_shards": 1,
    "analysis": {
      "char_filter": {
        "ts_convert_char_filter": {
          "type": "stconvert",
          "convert_type": "t2s"
        },
        "char_convert_char_filter": {
          "type": "mapping",
          "mappings": [
            "six => 6"
          ]
        }
      },
      "tokenizer": {
        "pinyin_tokenizer": {
          "type": "pinyin",
          "keep_first_letter": true
        }
      },
      "filter": {
        "pinyin_full_filter": {
          "type": "pinyin",
          "keep_first_letter": false,
          "keep_joined_full_pinyin": true
        },
        "pinyin_simple_filter": {
          "type": "pinyin",
          "keep_full_pinyin": false
        }
      },
      "analyzer": {
        "ik_max_analyzer": {
          "type": "custom",
          "char_filter": [
            "ts_convert_char_filter",
            "char_convert_char_filter"
          ],
          "tokenizer": "ik_max_word"
        },
        "ik_smart_analyzer": {
          "type": "custom",
          "char_filter": [
            "ts_convert_char_filter",
            "char_convert_char_filter"
          ],
          "tokenizer": "ik_smart"
        },
        "ik_max_full_pinyin_analyzer": {
          "type": "custom",
          "char_filter": [
            "ts_convert_char_filter",
            "char_convert_char_filter"
          ],
          "tokenizer": "ik_max_word",
          "filter": "pinyin_full_filter"
        },
        "ik_smart_full_pinyin_analyzer": {
          "type": "custom",
          "char_filter": [
            "ts_convert_char_filter",
            "char_convert_char_filter"
          ],
          "tokenizer": "ik_smart",
          "filter": "pinyin_full_filter"
        },
        "ik_max_simple_pinyin_analyzer": {
          "type": "custom",
          "char_filter": [
            "ts_convert_char_filter",
            "char_convert_char_filter"
          ],
          "tokenizer": "ik_max_word",
          "filter": "pinyin_simple_filter"
        },
        "ik_smart_simple_pinyin_analyzer": {
          "type": "custom",
          "char_filter": [
            "ts_convert_char_filter",
            "char_convert_char_filter"
          ],
          "tokenizer": "ik_smart",
          "filter": "pinyin_simple_filter"
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "prodName": {
        "type": "text",
        "analyzer": "ik_max_analyzer",
        "search_analyzer": "ik_smart_analyzer",
        "fields": {
          "fpy": {
            "type": "text",
            "analyzer": "ik_max_full_pinyin_analyzer",
            "search_analyzer": "ik_smart_full_pinyin_analyzer"
          },
          "spy": {
            "type": "text",
            "analyzer": "ik_max_simple_pinyin_analyzer",
            "search_analyzer": "ik_smart_simple_pinyin_analyzer"
          }
        }
      }
    }
  }
}

POST prod/_bulk
{"index":{"_id":1}}
{"prodName":"苹果手机2019"}
{"index":{"_id":2}}
{"prodName":"华为手机2020"}
{"index":{"_id":3}}
{"prodName":"sj手机2020"}


POST prod/_search
{
  "query": {
    "bool": {
      "should": [
        {
          "multi_match": {
            "type": "most_fields",
            "query": "手机",
            "fields": [
              "prodName^10",
              "prodName.fpy^7",
              "prodName.spy^5"
            ]
          }
        }
      ]
    }
  },
  "highlight": {
    "fields": {
      "prodName": {
        "pre_tags": ["<666>"],
        "post_tags": ["</666>"]
      }
    }
  }
}
```

# 使用用 Search Template 和 Index Alias

## Search Template

Search Template 是一种解耦的手段, 开发人员更专注于业务, ES 专家优化 DSL.

例子:

```
DELETE _scripts/prod_search_template
POST _scripts/prod_search_template
{
  "script": {
    "lang": "mustache",
    "source": {
      "_source": [
        "prodName"
      ],
      "size": 20,
      "query": {
        "bool": {
          "should": [
            {
              "multi_match": {
                "type": "most_fields",
                "query": "{{q}}",
                "fields": [
                  "prodName^10",
                  "prodName.fpy^7",
                  "prodName.spy^5"
                ]
              }
            }
          ]
        }
      }
    }
  }
}

POST prod/_search/template
{
  "id": "prod_search_template",
  "params": {
    "q": "手机"
  }
}
```

## Index Alias

```
POST _aliases
{
  "actions": [
    {
      "add": {
        "index": "movies-2019",
        "alias": "movies-latest"
      }
    }
  ]
}

POST movies-latest/_search
{
  "query": {
    "match_all": {}
  }
}
```

# 综合排序:Function Score Query 优化算分

Function Score Query 可以在查询结束后, 对每一个匹配的文档进行一系列的重新算分, 根据新生成的分数进行排序.

提供了几种默认的计算分值的函数:

* Weight: 为每一个文档设置一个简单而不被规范化的权重
* Field Value Factor: 使用该数值来修改 _score,例如将 "热度" 和 "点赞数" 作为算分的参考因素
* Random Score: 为每一个用户使用一个不同的, 随机算分结果. 比如让每个用户能看到不同的随机排名,但是也希望同一个用户访问时,结果的相对顺序,保持一致 (Consistently Random)
* 衰减函数: 以某个字段的值为标准, 距离某个值越近, 得分越高
* Script Score: 自定义脚本完全控制所需逻辑

例子:

```
DELETE blogs
PUT /blogs/_doc/1
{
  "title":   "About popularity",
  "content": "In this post we will talk about...",
  "votes":   0
}

PUT /blogs/_doc/2
{
  "title":   "About popularity",
  "content": "In this post we will talk about...",
  "votes":   100
}

PUT /blogs/_doc/3
{
  "title":   "About popularity",
  "content": "In this post we will talk about...",
  "votes":   1000000
}

POST /blogs/_search
{
  "query": {
    "function_score": {
      "query": {
        "multi_match": {
          "query":    "popularity",
          "fields": [ "title", "content" ]
        }
      },
      "field_value_factor": {
        "field": "votes",
        "modifier": "log1p" ,
        "factor": 0.1
      },
      "boost_mode": "sum",
      "max_boost": 3
    }
  }
}
```

![](https://cdn.yangbingdong.com/img/elasticsearch/function-score-factor.png)

`boost_mode` 可选:

* `multiply` (默认): 算分与函数值的乘积
* `sum`: 算分与函数的和
* `min` / `max`: 算分与函数取 最小/ 最大值
* `replace`: 使用函数值取代算分

`max_boost` 可以将算分控制在一个最大值.

>  参考: ***[https://www.elastic.co/guide/en/elasticsearch/reference/7.6/query-dsl-function-score-query.html](https://www.elastic.co/guide/en/elasticsearch/reference/7.6/query-dsl-function-score-query.html)***

# 搜索提示 Suggester

核心问题:

- 匹配: 能够通过用户的输入进行前缀匹配
- 排序: 根据建议词的优先级进行排序
- 聚合: 能够根据建议词关联的商品进行聚合，比如聚合分类、聚合标签等
- 纠错: 能够对用户的输入进行拼写纠错

## Term & Phrase Suggester

测试数据:

```
DELETE articles

POST articles/_bulk
{ "index" : { } }
{ "body": "lucene is very cool"}
{ "index" : { } }
{ "body": "Elasticsearch builds on top of lucene"}
{ "index" : { } }
{ "body": "Elasticsearch rocks"}
{ "index" : { } }
{ "body": "elastic is the company behind ELK stack"}
{ "index" : { } }
{ "body": "Elk stack rocks"}
{ "index" : {} }
{  "body": "elasticsearch is rock solid"}
```

例子:

```
POST /articles/_search
{
  "suggest": {
    "term-suggestion": {
      "text": "lucen hocks",
      "term": {
        "suggest_mode": "always",
        "field": "body",
        "prefix_length": 0,
        "sort": "frequency"
      }
    }
  }
}
```

* `term-suggestion` 为自定义字段, suggest 结果在此字段中
* `term` 为 term suggest 关键字
* `suggest_mode`:
  * `missing`: 如索引中已经存在, 就不提供建议
  * `popular`: 推荐出现频率更加高的词
  * `always`: 无论是否存在, 都提供建议
* `sort` 排序, 默认按照 `score` 排序, 也可以按照 `frequency`
* 默认首字母不一致就不会匹配推荐,但是如果将 `prefix_length` 设置为 0, 就会为 `hock` 建议 `rock`

Phrase Suggester 则是在 Term Suggester 上增加了一些额外的逻辑

```
POST /articles/_search
{
  "suggest": {
    "my-suggestion": {
      "text": "lucne and elasticsear rock hello world ",
      "phrase": {
        "field": "body",
        "max_errors":2,
        "confidence":0,
        "direct_generator":[{
          "field":"body",
          "suggest_mode":"always"
        }],
        "highlight": {
          "pre_tag": "<em>",
          "post_tag": "</em>"
        }
      }
    }
  }
}
```

* `max_errors`: 最多可以拼错的 Terms 数
* `confidence`: 限制返回结果数, 默认为 1

## 自动补全与基于上下文的提示

### Completion Suggester

* 自动完成功能, 用户每输入一个字符. 就需要即时发送一个查询请求到后端查找匹配项
* 它对性能要求比较苛刻
* Elasticsearch 将 Analyse 的数据编码成FST与索引放在一起, 它会被整个加载进内存里面, 速度非常快
* FST只能**支持前缀查找**

定义 mappings:

```
DELETE articles
PUT articles
{
  "mappings": {
    "properties": {
      "title_completion":{
        "type": "completion"
      }
    }
  }
}
```

* 字段 `type` 需要用 `completion`

查询:

```
POST articles/_bulk
{"index":{}}
{"title_completion":"lucene is very cool"}
{"index":{}}
{"title_completion":"Elasticsearch builds on top of lucene"}
{"index":{}}
{"title_completion":"Elasticsearch rocks"}
{"index":{}}
{"title_completion":"elastic is the company behind ELK stack"}
{"index":{}}
{"title_completion":"Elk stack rocks"}
{"index":{}}

POST articles/_search?pretty
{
  "size": 0,
  "suggest": {
    "article-suggester": {
      "prefix": "elk ",
      "completion": {
        "field": "title_completion"
      }
    }
  }
}
```

### Context Suggester

Completion Suggester 的扩展, 可以在搜索中加入更多的上下文信息,例如,输入 `star`

* 咖啡相关: 建议 Starbucks
* 电影相关:  star wars

实现 Context Suggester, 可以定义两种类型:

* Category: 任意的字符串
* Geo: 地理理位置信息

```
DELETE comments
PUT comments
PUT comments/_mapping
{
  "properties": {
    "comment_autocomplete":{
      "type": "completion",
      "contexts":[{
        "type":"category",
        "name":"comment_category"
      }]
    }
  }
}

POST comments/_doc
{
  "comment":"I love the star war movies",
  "comment_autocomplete":{
    "input":["star wars"],
    "contexts":{
      "comment_category":"movies"
    }
  }
}

POST comments/_doc
{
  "comment":"Where can I find a Starbucks",
  "comment_autocomplete":{
    "input":["starbucks"],
    "contexts":{
      "comment_category":"coffee"
    }
  }
}


POST comments/_search
{
  "suggest": {
    "MY_SUGGESTION": {
      "prefix": "sta",
      "completion":{
        "field":"comment_autocomplete",
        "contexts":{
          "comment_category":"coffee"
        }
      }
    }
  }
}
```

# 跨级群搜索

应用场景: 水平扩展出现瓶颈, 将数据分散到多个集群中

启动三个集群:

```
bin/elasticsearch -E node.name=cluster0node -E cluster.name=cluster0 -E path.data=cluster0_data -E discovery.type=single-node -E http.port=9200 -E transport.port=9300

bin/elasticsearch -E node.name=cluster1node -E cluster.name=cluster1 -E path.data=cluster1_data -E discovery.type=single-node -E http.port=9201 -E transport.port=9301

bin/elasticsearch -E node.name=cluster2node -E cluster.name=cluster2 -E path.data=cluster2_data -E discovery.type=single-node -E http.port=9202 -E transport.port=9302
```

在每个集群上执行:

```
PUT /_cluster/settings
{
  "persistent": {
    "cluster": {
      "remote": {
        "cluster0": {
          "seeds": [
            "127.0.0.1:9300"
          ],
          "transport.ping_schedule": "30s"
        },
        "cluster1": {
          "seeds": [
            "127.0.0.1:9301"
          ],
          "transport.compress": true,
          "skip_unavailable": true
        },
        "cluster2": {
          "seeds": [
            "127.0.0.1:9302"
          ]
        }
      }
    }
  }
}
```

创建测试数据:

```
POST /users/_doc
{"name":"user1","age":10}

POST /users/_doc
{"name":"user2","age":20}

POST /users/_doc
{"name":"user3","age":30}
```

查询:

```
GET /users,cluster1:users,cluster2:users/_search
{
  "query": {
    "range": {
      "age": {
        "gte": 20,
        "lte": 40
      }
    }
  }
}
```

# 文档的存储

![](https://cdn.yangbingdong.com/img/elasticsearch/index-document-process.png)

* 文档会存储在具体的某个主分片和副本分片上: 例如文档1, 会存储在 P0 和 R0 分片上
* 文档路由算法: `shard = hash(_routing) % number_of_primary_shards`
  * Hash 算法确保文档均匀分散到分片中
  * 默认的 `_routing` 值是文档 id
  * 可以自行制定 routing 数值, 例如用相同国家的商品, 都分配到指定的 shard
  * 设置 Index Settings 后, **Primary 数不能随意修改的根本原因**

# 索引生命周期

* 在 Lucene 中, Lucene Index 包含了若干个 Segment
* 在 Elasticsearch 中, Index 包含了若干主从 Shard, Shard 包干了若干 Segment
* Segment 是 Elasticsearch 中存储的最小文件单元, 也就是分段存储, Segment被设计为**不可变**(Immutable Design)的

不可变性带来的好处就是:

* 避免了锁带来的性能问题
* 可以利用内存, 由于 Segment 不可变, 所以 Segment 被加载到内存后无需改变, 只要内存足够, Segment就可以长期驻村, 大大提升查询性能
* 更新, 新增的增量的方式很轻, 性能好

缺点也很明显:

* 删除操作不会马上删除有一定的空间浪费
* 频繁更新涉及到大量的删除动作, 会有大量的空间浪费

## Lucene Index

![](https://cdn.yangbingdong.com/img/elasticsearch/index-lifecycle.png)

* 在 Lucene 中, 单个倒排索引文件被称为 Segment, 多个 Segment 汇总在一起, 称为 Lucene的 Index
* 当有新文档写入时,会生成新 Segment, 查询时会同时查询所有 Segments, 并且对结果汇总, Lucene 中有一个文件, 用来记录所有 Segments 信息, 叫做 Commit Point
* 删除的文档信息,保存在 `.del` 文件中

## Refresh

![](https://cdn.yangbingdong.com/img/elasticsearch/index-lifecycle-refresh.png)

* 将 Index buffer 写入 Segment 的过程叫 Refresh, Refresh 不执行 fsync 操作
* Refresh 频率: 默认 1 秒发生一次,可通过 `index.refresh_interval` 配置. Refresh 后, 数据就可以被搜索到了, 这也是为什么Elasticsearch 被称为近实时搜索
* 如果系统有大量的数据写入, 那就会产生很多的 Segment, Index Buffer 被占满时, 触发 Refresh, 默认值是 JVM 的 10%

## Transaction Log

![](https://cdn.yangbingdong.com/img/elasticsearch/index-lifecycle-transaction-log.png)

* Segment 写入磁盘的过程**相对耗时**, 借助文件系统缓存, Refresh 时, 先将Segment 写入缓存以**开放查询**
* 为了保证数据不会丢失, 所以在 Index 文档时, 同时写 Transaction Log, 高版本开始, Transaction Log 默认落盘, 每个分片有一个 Transaction Log
* 在 ES Refresh 时, Index Buffer 被清空, Transaction log 不会清空

## Flush

![](https://cdn.yangbingdong.com/img/elasticsearch/index-lifecycle-flush.png)

* 调用 Refresh, Index Buffer 清空
* 调用 fsync, 将缓存中的 Segments写入磁盘
* 清空(删除) Transaction Log
* 默认 30 分钟调用一次或者 Transaction Log 满 (默认 512 MB)

## Merge

* Segment 很多, 需要被定期被合并
  * 减少 Segments / 删除已经删除的文档
* ES 和 Lucene 会自动进行 Merge 操作
  * POST my_index/_forcemerge

这个流程的目的是: 提升写入性能(异步落盘)

# 剖析分布式查询

Elasticsearch 的搜索分为两个阶段: Query & Fetch

![](https://cdn.yangbingdong.com/img/elasticsearch/elasticsearch-query-and-fetch.png)

## Query 阶段

* 节点收到请求, 以 Coordinating 节点的身份在6个主副分片中随机选择3个, 发送查询请求
* 被选中的分片执行查询, **进行排序**, 然后每个分片都会返回 **From + Size** 个排序后的**文档 Id** 和排序值

## Fetch 阶段

* Coordinating 节点将每个分片返回的文档 Id 重新组合排序, 选取 From 到 From + Size 个文档 Id
* 以 multi get 的请求方式, 到相应的分片获取详细的文档数据

## 潜在问题

由于每个分片需要查询 From + Size 的数量, 所以总的查询数量为 number_of_shard * (from + size), 所以在**深度分页**的情况下会有性能问题

# 排序以及 Doc Value & Field Data

排序基本语法:

```
POST /kibana_sample_data_ecommerce/_search
{
  "size": 5,
  "query": {
    "match_all": {

    }
  },
  "sort": [
    {"order_date": {"order": "desc"}},
    {"_doc":{"order": "asc"}},
    {"_score":{ "order": "desc"}}
  ]
}
```

Elasticsearch 有两种实现方法:

* Fielddata (ES 1.X 以及之前版本)
* Doc Values (列列式存储,对 Text 类型无无效) (ES 2.X之后版本)

## 打开 Fielddata

```
PUT kibana_sample_data_ecommerce/_mapping
{
  "properties": {
    "customer_full_name" : {
          "type" : "text",
          "fielddata": true,
          "fields" : {
            "keyword" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        }
  }
}
```

* 默认关闭, 可以通过 Mapping 设置打开. 修改设置后, 即时生生效, 无需重建索引

* 其他字段类型不支持, 只支持对 Text 进行设定

## 关闭 Doc Value

```
PUT test_keyword/_mapping
{
  "properties": {
    "user_name":{
      "type": "keyword",
      "doc_values":false
    }
  }
}
```

* 什么时候关闭: 明确不需要做排序以及聚合分析
* 可以增加索引速度, 减少磁盘空间
* 需要重建索引

# 分页与遍历

插入数据:

```
DELETE users

POST users/_doc
{"name":"user1","age":10}

POST users/_doc
{"name":"user2","age":11}


POST users/_doc
{"name":"user2","age":12}

POST users/_doc
{"name":"user2","age":13}

POST users/_count
```

## From Size

语法:

```
POST users/_search
{
    "from": 1, 
    "size": 4,
    "query": {
        "match_all": {}
    }
}
```

缺点: 深度分页会有性能问题, 假设 From = 990, Size = 10, 那么每个 Coordinating Node 都会获取 1000 个文档再聚合结果, 页数越深, 占用内存越多, Elasticsearch 有一个设定, 默认**限定到 10000 个文档**.

## Search After

```
POST users/_search
{
    "size": 1,
    "query": {
        "match_all": {}
    },
    "sort": [
        {"age": "desc"} ,
        {"_id": "asc"}    
    ]
}

POST users/_search
{
    "size": 1,
    "query": {
        "match_all": {}
    },
    "search_after":
        [
          10,
          "dF-ExnEBHozATh0Ori4u"],
    "sort": [
        {"age": "desc"} ,
        {"_id": "asc"}    
    ]
}
```

* 能避免深度分页的问题
  * 不能指定页数 (From)
  * 只能往下翻
* 第一步搜索需要指定 sort, 并且保证值是唯一的(可以通过加入 _id 保证唯一性)
* 然后使用上一次,最后一个文档的 sort 值进行查询

原理是通过唯一排序值定位, 将每次要处理的文档数都控制在 固定的数值

## Scroll API

```
DELETE users
POST users/_doc
{"name":"user1","age":10}

POST users/_doc
{"name":"user2","age":20}

POST users/_doc
{"name":"user3","age":30}

POST users/_doc
{"name":"user4","age":40}

POST /users/_search?scroll=5m
{
    "size": 1,
    "query": {
        "match_all" : {
        }
    }
}


POST users/_doc
{"name":"user5","age":50}
POST /_search/scroll
{
    "scroll" : "1m",
    "scroll_id" : "DXF1ZXJ5QW5kRmV0Y2gBAAAAAAAAAWAWbWdoQXR2d3ZUd2kzSThwVTh4bVE0QQ=="
}
```

* 创建一个**快照**, 有新的数据写入以后,无法被查到
* 每次查询后,输入上一次的 Scroll Id

## 不同的搜索类型和使用场景

* Regular
  * 需要实时获取顶部的部分文档, 例如查询最新的订单
* Scroll
  * 需要全部文档, 例如导出全部数据
* Pagination
  * From 和 Size
  * 如果需要深度分页,则选用 Search After

# Bucket & Metric 聚合分析及嵌套聚合

* Metric Aggregation:  一些系列的统计方法(类比COUNT)
  * 单值分析: 只输出一个分析结果
    * min, max, avg, sum
    * Cardinality (类似 distinct count)
  * 多值分析: 输出多个分析结果
    * stats, extended stats
    * percentile, percentile rank
    * top hits
* Bucket Aggregation: 一组满足条件的文档 (类比GROUP BY), 支支持嵌套, 也就在桶里再做分桶
  * terms
  * 数字类型:
    * range, data range
    * histogram, date histogram

基本语法:

![](https://cdn.yangbingdong.com/img/elasticsearch/aggregation-syntax.png )

数据准备:

```
DELETE /employees
PUT /employees/
{
  "mappings" : {
      "properties" : {
        "age" : {
          "type" : "integer"
        },
        "gender" : {
          "type" : "keyword"
        },
        "job" : {
          "type" : "text",
          "fields" : {
            "keyword" : {
              "type" : "keyword",
              "ignore_above" : 50
            }
          }
        },
        "name" : {
          "type" : "keyword"
        },
        "salary" : {
          "type" : "integer"
        }
      }
    }
}

PUT /employees/_bulk
{ "index" : {  "_id" : "1" } }
{ "name" : "Emma","age":32,"job":"Product Manager","gender":"female","salary":35000 }
{ "index" : {  "_id" : "2" } }
{ "name" : "Underwood","age":41,"job":"Dev Manager","gender":"male","salary": 50000}
{ "index" : {  "_id" : "3" } }
{ "name" : "Tran","age":25,"job":"Web Designer","gender":"male","salary":18000 }
{ "index" : {  "_id" : "4" } }
{ "name" : "Rivera","age":26,"job":"Web Designer","gender":"female","salary": 22000}
{ "index" : {  "_id" : "5" } }
{ "name" : "Rose","age":25,"job":"QA","gender":"female","salary":18000 }
{ "index" : {  "_id" : "6" } }
{ "name" : "Lucy","age":31,"job":"QA","gender":"female","salary": 25000}
{ "index" : {  "_id" : "7" } }
{ "name" : "Byrd","age":27,"job":"QA","gender":"male","salary":20000 }
{ "index" : {  "_id" : "8" } }
{ "name" : "Foster","age":27,"job":"Java Programmer","gender":"male","salary": 20000}
{ "index" : {  "_id" : "9" } }
{ "name" : "Gregory","age":32,"job":"Java Programmer","gender":"male","salary":22000 }
{ "index" : {  "_id" : "10" } }
{ "name" : "Bryant","age":20,"job":"Java Programmer","gender":"male","salary": 9000}
{ "index" : {  "_id" : "11" } }
{ "name" : "Jenny","age":36,"job":"Java Programmer","gender":"female","salary":38000 }
{ "index" : {  "_id" : "12" } }
{ "name" : "Mcdonald","age":31,"job":"Java Programmer","gender":"male","salary": 32000}
{ "index" : {  "_id" : "13" } }
{ "name" : "Jonthna","age":30,"job":"Java Programmer","gender":"female","salary":30000 }
{ "index" : {  "_id" : "14" } }
{ "name" : "Marshall","age":32,"job":"Javascript Programmer","gender":"male","salary": 25000}
{ "index" : {  "_id" : "15" } }
{ "name" : "King","age":33,"job":"Java Programmer","gender":"male","salary":28000 }
{ "index" : {  "_id" : "16" } }
{ "name" : "Mccarthy","age":21,"job":"Javascript Programmer","gender":"male","salary": 16000}
{ "index" : {  "_id" : "17" } }
{ "name" : "Goodwin","age":25,"job":"Javascript Programmer","gender":"male","salary": 16000}
{ "index" : {  "_id" : "18" } }
{ "name" : "Catherine","age":29,"job":"Javascript Programmer","gender":"female","salary": 20000}
{ "index" : {  "_id" : "19" } }
{ "name" : "Boone","age":30,"job":"DBA","gender":"male","salary": 30000}
{ "index" : {  "_id" : "20" } }
{ "name" : "Kathy","age":29,"job":"DBA","gender":"female","salary": 20000}
```

## Metric Aggregation

```
# 多个 Metric 聚合，找到最低最高和平均工资
POST employees/_search
{
  "size": 0,
  "aggs": {
    "max_salary": {
      "max": {
        "field": "salary"
      }
    },
    "min_salary": {
      "min": {
        "field": "salary"
      }
    },
    "avg_salary": {
      "avg": {
        "field": "salary"
      }
    }
  }
}

# 一个聚合，输出多值
POST employees/_search
{
  "size": 0,
  "aggs": {
    "stats_salary": {
      "stats": {
        "field":"salary"
      }
    }
  }
}
```

## Term Aggregation

text 类型字段需要打开 fielddata, 才能进行 Terms Aggregation, 且是基于分词后的 term 做 aggregation.

```
# 对 Text 字段进行 terms 聚合查询，失败
POST employees/_search
{
  "size": 0,
  "aggs": {
    "jobs": {
      "terms": {
        "field":"job"
      }
    }
  }
}

# 对 Text 字段打开 fielddata，支持terms aggregation
PUT employees/_mapping
{
  "properties" : {
    "job":{
       "type":     "text",
       "fielddata": true
    }
  }
}

# 可以指定size, 限制放回的aggregation结果数量
POST employees/_search
{
  "size": 0,
  "aggs": {
    "jobs": {
      "terms": {
        "field":"job.keyword",
        "size": 5
      }
    }
  }
}
```

## Cardinality

```
# 对job.keyword 和 job 进行 terms 聚合，分桶的总数并不一样
POST employees/_search
{
  "size": 0,
  "aggs": {
    "cardinate": {
      "cardinality": {
        "field": "job"
      }
    }
  }
}
```

## Bucket Size & Top Hits

```
# 指定size，不同工种中，年纪最大的3个员工的具体信息
POST employees/_search
{
  "size": 0,
  "aggs": {
    "jobs": {
      "terms": {
        "field":"job.keyword"
      },
      "aggs":{
        "old_employee":{
          "top_hits":{
            "size":3,
            "sort":[
              {
                "age":{
                  "order":"desc"
                }
              }
            ]
          }
        }
      }
    }
  }
}
```

## Range & Histogram

```
#Salary Ranges 分桶，可以自己定义 key
POST employees/_search
{
  "size": 0,
  "aggs": {
    "salary_range": {
      "range": {
        "field":"salary",
        "ranges":[
          {
            "to":10000
          },
          {
            "from":10000,
            "to":20000
          },
          {
            "key":">20000",
            "from":20000
          }
        ]
      }
    }
  }
}

#Salary Histogram,工资0到10万，以 5000一个区间进行分桶
POST employees/_search
{
  "size": 0,
  "aggs": {
    "salary_histrogram": {
      "histogram": {
        "field":"salary",
        "interval":5000,
        "extended_bounds":{
          "min":0,
          "max":100000
        }
      }
    }
  }
}
```

## 多层嵌套

```
# 多次嵌套。根据工作类型分桶，然后按照性别分桶，计算工资的统计信息
POST employees/_search
{
  "size": 0,
  "aggs": {
    "Job_gender_stats": {
      "terms": {
        "field": "job.keyword"
      },
      "aggs": {
        "gender_stats": {
          "terms": {
            "field": "gender"
          },
          "aggs": {
            "salary_stats": {
              "stats": {
                "field": "salary"
              }
            }
          }
        }
      }
    }
  }
}
```

## 优化 Terms 聚合的性能

应用场景: 对字段需要频繁地调用 aggregation, 并且写入也比较频繁.

![](https://cdn.yangbingdong.com/img/elasticsearch/term-performer.png)

参考: ***[tune-for-search-speed](https://www.elastic.co/guide/en/elasticsearch/reference/current/tune-for-search-speed.html)***

## post_filter

> ***[filter-search-results](https://www.elastic.co/guide/en/elasticsearch/reference/current/filter-search-results.html)***

`post_filter` 作用: 聚合结果生成完毕后, 查询结果可以根据 post_filter 参数的设置而被再次过滤.

> `post_filter` 的作用和我们常用的filter是类似的, 但由于 `post_filter` 是在查询之后才会执行, 所以 `post_filter` 不具备 `filter` 对查询带来的好处(忽略评分, 缓存等), 因此, **在普通的查询中不要用 `post_filter` 来替代 `filter`**.

```
GET /shirts/_search
{
  "query": {
    "bool": {
      "filter": {
        "term": { "brand": "gucci" } 
      }
    }
  },
  "aggs": {
    "colors": {
      "terms": { "field": "color" } 
    },
    "color_red": {
      "filter": {
        "term": { "color": "red" } 
      },
      "aggs": {
        "models": {
          "terms": { "field": "model" } 
        }
      }
    }
  },
  "post_filter": { 
    "term": { "color": "red" }
  }
}
```



# Pipeline 聚合分析

概念: 支持对聚合分析的结果, 再次进行聚合分析.

Pipeline 的分析结果会输出到原结果中, 根据位置的不同, 分为两类:

* Sibling: 结果和现有分析结果同级
  * Max, Min, Avg & Sum Bucket
  * Stats, Extended Status Bucket
  * Percentiles Bucket
* Parent: 结果内嵌到现有的聚合分析结果之中
  * Derivative (求导)
  * Cumultive Sum (累计求和)
  * Moving Function (滑动窗口)

## Sibing Pipline 例子

数据沿用上一小结的.

对不同类型工作的, 平均工资, 求最大/平均/统计信息/百分位数的值:

```
POST employees/_search
{
  "size": 0,
  "aggs": {
    "jobs": {
      "terms": {
        "field": "job.keyword",
        "size": 10
      },
      "aggs": {
        "avg_salary": {
          "avg": {
            "field": "salary"
          }
        }
      }
    },
    "min_salary_by_job": {
      "min_bucket": {
        "buckets_path": "jobs>avg_salary"
      }
    },
    "max_salary_by_job": {
      "max_bucket": {
        "buckets_path": "jobs>avg_salary"
      }
    },
    "avg_salary_by_job":{
      "avg_bucket": {
        "buckets_path": "jobs>avg_salary"
      }
    },
    "stats_salary_by_job":{
      "stats_bucket": {
        "buckets_path": "jobs>avg_salary"
      }
    },
    "percentiles_salary_by_job":{
      "percentiles_bucket": {
        "buckets_path": "jobs>avg_salary"
      }
    }
  }
}
```

## Derivative 例子

按照年龄, 对工资进行求导(看工资发展的趋势)/累计求和/:

```
POST employees/_search
{
  "size": 0,
  "aggs": {
    "age": {
      "histogram": {
        "field": "age",
        "min_doc_count": 1,
        "interval": 1
      },
      "aggs": {
        "avg_salary": {
          "avg": {
            "field": "salary"
          }
        },
        "derivative_avg_salary":{
          "derivative": {
            "buckets_path": "avg_salary"
          }
        },
        "cumulative_salary":{
          "cumulative_sum": {
            "buckets_path": "avg_salary"
          }
        },
        "moving_avg_salary":{
          "moving_fn": {
            "buckets_path": "avg_salary",
            "window":10,
            "script": "MovingFunctions.min(values)"
          }
        }
      }
    }
  }
}
```

# 聚合的作用范围以及排序

聚合分析默认范围: query 的查询结果集

同时 ES 还支持以下方式改变聚合的作用范围:

* Filter
* Post_Filter
* Global

## Filter

下面的 older_person 的作用范围是 filter , 而 all_jobs 还是基于 query

```
#Filter
POST employees/_search
{
  "size": 0,
  "query": {
    "range": {
      "age": {
        "gte": 20
      }
    }
  },
  "aggs": {
    "older_person": {
      "filter": {
        "range": {
          "age": {
            "from": 35
          }
        }
      },
      "aggs": {
        "jobs": {
          "terms": {
            "field": "job.keyword"
          }
        }
      }
    },
    "all_jobs": {
      "terms": {
        "field": "job.keyword"
      }
    }
  }
}
```

## Post_Filter

一条语句, 找出所有的job类型. 还能找到聚合后符合条件的结果:

> post_filter的作用和我们常用的filter是类似的, 但由于post_filter是在查询之后才会执行, 所以post_filter不具备filter对查询带来的好处(忽略评分/缓存等), 因此, 在普通的查询中不要用post_filter来替代filter.

```
POST employees/_search
{
  "aggs": {
    "jobs": {
      "terms": {
        "field": "job.keyword"
      }
    }
  },
  "post_filter": {
    "match": {
      "job.keyword": "Dev Manager"
    }
  }
}
```

## Global

global 无视 query, 针对全文档进行统计:

```
POST employees/_search
{
  "size": 0,
  "query": {
    "range": {
      "age": {
        "gte": 40
      }
    }
  },
  "aggs": {
    "jobs": {
      "terms": {
        "field": "job.keyword"
      }
    },
    "all": {
      "global": {},
      "aggs": {
        "salary_avg": {
          "avg": {
            "field": "salary"
          }
        }
      }
    }
  }
}
```

## 排序

```
POST employees/_search
{
  "size": 0,
  "query": {
    "range": {
      "age": {
        "gte": 20
      }
    }
  },
  "aggs": {
    "jobs": {
      "terms": {
        "field": "job.keyword",
        "order": [
          {
            "_count": "asc"
          },
          {
            "_key": "desc"
          }
        ]
      }
    }
  }
}
```

根据子聚合排序:

```
POST employees/_search
{
  "size": 0,
  "aggs": {
    "jobs": {
      "terms": {
        "field": "job.keyword",
        "order": [
          {
            "avg_salary": "desc"
          }
        ]
      },
      "aggs": {
        "avg_salary": {
          "avg": {
            "field": "salary"
          }
        }
      }
    }
  }
}

POST employees/_search
{
  "size": 0,
  "aggs": {
    "jobs": {
      "terms": {
        "field": "job.keyword",
        "order": [
          {
            "stats_salary.min": "desc"
          }
        ]
      },
      "aggs": {
        "stats_salary": {
          "stats": {
            "field": "salary"
          }
        }
      }
    }
  }
}
```

# 聚合的精准度

在多分片环境下, 会导致聚合的精准度产生偏差, 解决方案有两个:

1. 当数据量不大时, 设置 PrimaryShard 为 1, 实现准确性

2. 调整 shard size, shard size 默认大小为 size * 1.5 +10

   ```
   GET my_flights/_search
   {
     "size": 0,
     "aggs": {
       "weather": {
         "terms": {
           "field": "OriginWeather",
           "size": 1,
           "shard_size": 10,
           "show_term_doc_count_error": true
         }
       }
     }
   }
   ```

   
# 处理关系型数据

> 参考地址: ***[Joining queries](https://www.elastic.co/guide/en/elasticsearch/reference/current/joining-queries.html)***

Elasticsearch 采用 **Denormalization**(反范式化设计), 与之对应的就是日常使用关系型数据库的 **Normalization**(范式化设计).

反范式化一般采用**扁平化处理**, 不使用关联关系, 而是在文档中保存冗余的数据拷贝, 缺点就是**不适合在数据频繁修改**的场景.

ES 处理处理关联关系主要有以下方式:

* 对象类型
* 嵌套对象(Nested Object)
* 父子关联关系(Parant/Child)
* 应用端关联

性能: 对象 > 嵌套 > 父子文档

## 对象类型

```
DELETE blog
# 设置blog的 Mapping
PUT /blog
{
  "mappings": {
    "properties": {
      "content": {
        "type": "text"
      },
      "time": {
        "type": "date"
      },
      "user": {
        "properties": {
          "city": {
            "type": "text"
          },
          "userid": {
            "type": "long"
          },
          "username": {
            "type": "keyword"
          }
        }
      }
    }
  }
}


# 插入一条 Blog 信息
PUT blog/_doc/1
{
  "content":"I like Elasticsearch",
  "time":"2019-01-01T00:00:00",
  "user":{
    "userid":1,
    "username":"Jack",
    "city":"Shanghai"
  }
}

# 搜索
POST blog/_search
{
  "query": {
    "bool": {
      "must": [
        {"match": {"content": "Elasticsearch"}},
        {"match": {"user.username": "Jack"}}
      ]
    }
  }
}
```

## 嵌套对象

再来看这个例子:

```
DELETE my_movies

# 电影的Mapping信息
PUT my_movies
{
      "mappings" : {
      "properties" : {
        "actors" : {
          "properties" : {
            "first_name" : {
              "type" : "keyword"
            },
            "last_name" : {
              "type" : "keyword"
            }
          }
        },
        "title" : {
          "type" : "text",
          "fields" : {
            "keyword" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        }
      }
    }
}


# 写入一条电影信息
POST my_movies/_doc/1
{
  "title":"Speed",
  "actors":[
    {
      "first_name":"Keanu",
      "last_name":"Reeves"
    },
    {
      "first_name":"Dennis",
      "last_name":"Hopper"
    }

  ]
}

# 查询电影信息
POST my_movies/_search
{
  "query": {
    "bool": {
      "must": [
        {"match": {"actors.first_name": "Keanu"}},
        {"match": {"actors.last_name": "Hopper"}}
      ]
    }
  }
}
```

上面搜索一个不存在的名字, 但却可以搜索出来, 这是因为扁平化存储的原因:

![](https://cdn.yangbingdong.com/img/elasticsearch/nested-object1.png)

可以使用 Nested Data Type 解决上述问题:

```
DELETE my_movies
# 创建 Nested 对象 Mapping
PUT my_movies
{
      "mappings" : {
      "properties" : {
        "actors" : {
          "type": "nested",
          "properties" : {
            "first_name" : {"type" : "keyword"},
            "last_name" : {"type" : "keyword"}
          }},
        "title" : {
          "type" : "text",
          "fields" : {"keyword":{"type":"keyword","ignore_above":256}}
        }
      }
    }
}


POST my_movies/_doc/1
{
  "title":"Speed",
  "actors":[
    {
      "first_name":"Keanu",
      "last_name":"Reeves"
    },

    {
      "first_name":"Dennis",
      "last_name":"Hopper"
    }

  ]
}

# Nested 查询
POST my_movies/_search
{
  "query": {
    "bool": {
      "must": [
        {"match": {"title": "Speed"}},
        {
          "nested": {
            "path": "actors",
            "query": {
              "bool": {
                "must": [
                  {"match": {
                    "actors.first_name": "Keanu"
                  }},
                  {"match": {
                    "actors.last_name": "Hopper"
                  }}
                ]
              }
            }
          }
        }
      ]
    }
  }
}
```

在内部, Nested 文档会被保存在两个 Lucene 文档中,在查询时做 Join 处理.

Nested 对象的聚合查询语句也要特殊处理, 普通的聚合查询是查不到的:

```
# Nested Aggregation
POST my_movies/_search
{
  "size": 0,
  "aggs": {
    "actors": {
      "nested": {
        "path": "actors"
      },
      "aggs": {
        "actor_name": {
          "terms": {
            "field": "actors.first_name",
            "size": 10
          }
        }
      }
    }
  }
}
```

## 父子文档

对象和 Nested 对象的局限性: 每次**更新需要重新索引**整个对象(包括根对象和嵌套对象).

而父子文档, 类似数据库中的 JOIN, 通过**维护 Parent/ Child 的关系**(在 mapping 中体现), 从而分离两个对象:

* 父文档和子文档是两个**独立**的文档
* 更新父文档无需重新索引子文档, 子文档被添加, 更新或者删除也不会影响到父文档和其他的子文档
* 父子文档字段定义在同一个 Mapping 中

定义父子关系的几个步骤:

* 设置 Mapping(关键是声明 `type` 为 `join` 的关联字段)
* 索引父文档(指定自己为父文档)
* 索引子文档(指定自己为子文档, 并指定父文档id, **指定 `routing`** 为父文档 id(更新时也要指定 `routing`), 为了是它们存储在同一分片从而提高查询性能)
* 按需查询, `parent_id`(返回子文档) / `has_child`(返回父文档) / `has_parent`(返回子文档) 查询

```
DELETE my_blogs

# 设定 Parent/Child Mapping
PUT my_blogs
{
  "settings": {
    "number_of_shards": 2
  },
  "mappings": {
    "properties": {
      "blog_comments_relation": {
        "type": "join",
        "relations": {
          "blog": "comment"
        }
      },
      "content": {
        "type": "text"
      },
      "title": {
        "type": "keyword"
      }
    }
  }
}


#索引父文档
PUT my_blogs/_doc/blog1
{
  "title":"Learning Elasticsearch",
  "content":"learning ELK @ geektime",
  "blog_comments_relation":{
    "name":"blog"
  }
}

#索引父文档
PUT my_blogs/_doc/blog2
{
  "title":"Learning Hadoop",
  "content":"learning Hadoop",
    "blog_comments_relation":{
    "name":"blog"
  }
}


#索引子文档
PUT my_blogs/_doc/comment1?routing=blog1
{
  "comment":"I am learning ELK",
  "username":"Jack",
  "blog_comments_relation":{
    "name":"comment",
    "parent":"blog1"
  }
}

#索引子文档
PUT my_blogs/_doc/comment2?routing=blog2
{
  "comment":"I like Hadoop!!!!!",
  "username":"Jack",
  "blog_comments_relation":{
    "name":"comment",
    "parent":"blog2"
  }
}

#索引子文档
PUT my_blogs/_doc/comment3?routing=blog2
{
  "comment":"Hello Hadoop",
  "username":"Bob",
  "blog_comments_relation":{
    "name":"comment",
    "parent":"blog2"
  }
}

# 查询所有文档
POST my_blogs/_search
{

}

#根据父文档ID查看
GET my_blogs/_doc/blog2

# Parent Id 查询
POST my_blogs/_search
{
  "query": {
    "parent_id": {
      "type": "comment",
      "id": "blog2"
    }
  }
}

# Has Child 查询,返回父文档
POST my_blogs/_search
{
  "query": {
    "has_child": {
      "type": "comment",
      "query" : {
                "match": {
                    "username" : "Jack"
                }
            }
    }
  }
}

# Has Parent 查询，返回相关的子文档
POST my_blogs/_search
{
  "query": {
    "has_parent": {
      "parent_type": "blog",
      "query" : {
                "match": {
                    "title" : "Learning Hadoop"
                }
            }
    }
  }
}

#通过ID ，访问子文档
GET my_blogs/_doc/comment3
#通过ID和routing ，访问子文档
GET my_blogs/_doc/comment3?routing=blog2

#更新子文档
PUT my_blogs/_doc/comment3?routing=blog2
{
    "comment": "Hello Hadoop??",
    "blog_comments_relation": {
      "name": "comment",
      "parent": "blog2"
    }
}
```

## inner_hits

> ***[Retrieve inner hits](https://www.elastic.co/guide/en/elasticsearch/reference/current/inner-hits.html)***

在 `nested`/ `has_child` / `has_parent` 查询中加上 inner_hits 可返回对应的命中文档:

```
"<query>" : {
  "inner_hits" : {
    <inner_hits_options>
  }
}
```

比如 `has_child` 在默认情况下只返回了父文档, 如果也要返回命中的子文档:

```
POST my_blogs/_search
{
  "query": {
    "has_child": {
      "type": "comment",
      "query": {
        "match": {
          "username": "Jack"
        }
      },
      "inner_hits": {}
    }
  }
}
```

# 索引重建

> ***[Reindex API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html)***
>
> ***[Update By Query API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-update-by-query.html)***

索引重建场景:

* 修改 mapping(字段类型更改, 分词器及字典更新) 以及 setting(分片数量修改)

ES 提供了两种重建索引的 API:

* Reindex: 将一个索引数据搬到另外一个索引上(mapping 以及 setting 不会搬过去)
  * 场景: 修改字段类型(需要先对新索引设置 mapping), 修改索引的主分片片数
* Update By Query:  在现有的索引上重建
  * 场景: 为字段新增子字段, 字段更换分词器, 或更新分词器词库.

```
DELETE blogs/

# 写入文档
PUT blogs/_doc/1
{
  "content":"Hadoop is cool",
  "keyword":"hadoop"
}

# 查看 Mapping
GET blogs/_mapping

# 修改 Mapping，增加子字段，使用英文分词器
PUT blogs/_mapping
{
      "properties" : {
        "content" : {
          "type" : "text",
          "fields" : {
            "english" : {
              "type" : "text",
              "analyzer":"english"
            }
          }
        }
      }
    }


# 写入文档
PUT blogs/_doc/2
{
  "content":"Elasticsearch rocks",
    "keyword":"elasticsearch"
}

# 查询新写入文档
POST blogs/_search
{
  "query": {
    "match": {
      "content.english": "Elasticsearch"
    }
  }

}

# 查询 Mapping 变更前写入的文档
POST blogs/_search
{
  "query": {
    "match": {
      "content.english": "Hadoop"
    }
  }
}


# Update所有文档
POST blogs/_update_by_query
{

}

# 查询之前写入的文档
POST blogs/_search
{
  "query": {
    "match": {
      "content.english": "Hadoop"
    }
  }
}


# 查询
GET blogs/_mapping

PUT blogs/_mapping
{
        "properties" : {
        "content" : {
          "type" : "text",
          "fields" : {
            "english" : {
              "type" : "text",
              "analyzer" : "english"
            }
          }
        },
        "keyword" : {
          "type" : "keyword"
        }
      }
}

DELETE blogs_fix

# 创建新的索引并且设定新的Mapping
PUT blogs_fix/
{
  "mappings": {
        "properties" : {
        "content" : {
          "type" : "text",
          "fields" : {
            "english" : {
              "type" : "text",
              "analyzer" : "english"
            }
          }
        },
        "keyword" : {
          "type" : "keyword"
        }
      }    
  }
}

# Reindx API
POST  _reindex
{
  "source": {
    "index": "blogs"
  },
  "dest": {
    "index": "blogs_fix"
  }
}

GET  blogs_fix/_doc/1

# 测试 Term Aggregation
POST blogs_fix/_search
{
  "size": 0,
  "aggs": {
    "blog_keyword": {
      "terms": {
        "field": "keyword",
        "size": 10
      }
    }
  }
}
```

# Ingest Pipeline 与 Painless Script

应用场景: 对写入的数据进行拦截并处理后, 再写入, 类似 Logstash, 但是又无需 Logstash.

参考文档:

***[Ingest APIs](https://www.elastic.co/guide/en/elasticsearch/reference/current/ingest-apis.html)***

***[Ingest Processors](https://www.elastic.co/guide/en/elasticsearch/reference/current/ingest-processors.html)***

***[How to use scripts](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-scripting-using.html)***

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
  * `completion`
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

# 搜索选择

![](https://cdn.yangbingdong.com/img/elasticsearch/search-method-choose.png)

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