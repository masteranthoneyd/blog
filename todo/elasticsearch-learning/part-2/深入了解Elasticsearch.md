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

