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

# Query & Filtering 与多字符串串多字段查询

一般高级的搜索功能都是多项的复合搜索, 即对多个字段的进行搜索. 在 Elasticsearch 中有 Query 和 Filter 两种不同的 Context:

* Query Context: 相关性算分
* Filter Context: 不需要算分, 可以利用 Cache, 性能更好

Elasticsearch 提供 **bool Query** 进行复合查询, 一个 bool 查询, 是一个或多个查询子句的组合.

## bool 查询

bool 查询包括4种子句, 2个会影响算分, 两个不会:

| must     | 必须匹配,  贡献算分                       |
| -------- | ----------------------------------------- |
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

























