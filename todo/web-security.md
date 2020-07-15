# Web 安全

![](https://cdn.yangbingdong.com/img/web-security/web-security.png)

## 业务逻辑漏洞

### 过度信赖客户端

比如一个场景, 删除自己小店里面的商品.

这时候客户端传来商品id, 然后服务端删除. 如果不做合法性校验, 比如这个商品是不是自己的, 就会导致可以任意删除别人的商品了.