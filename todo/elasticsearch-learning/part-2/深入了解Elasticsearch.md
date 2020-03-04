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

