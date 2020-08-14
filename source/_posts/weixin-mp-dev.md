---
title: 微信公众号开发
date: 2020-08-01 10:32:59
categories: Java
tags: [Java, Weixin]
---

![](https://cdn.yangbingdong.com/img/weixin-dev/weixin-mp-dev-banner.png)

# Preface

> 使用微信提供的微信平台体系(微信开放平台/微信公众号平台/微信小程序/微信支付等)可以使我们的业务接入庞大的微信体系, 定义自己的个性化业务.
>
> 这里主要记录一下微信公众号开发相关的要点...

<!--more-->

# 前置

* 是已认证的服务号
* 后端采用 Java 开发

后端微信开发工具包采用官方推荐的 Java 工具包: ***[WxJava](https://github.com/Wechat-Group/WxJava)***, 假定你已经阅读过***[官方 Wiki](https://github.com/Wechat-Group/WxJava/wiki)***

下面集成用例均在本地完成, 微信对于**开发者服务器只能是80端口或者443**, 因此本地开发调试时, 需要借助**内网穿透**工具, 该类工具有很多, 比如 Ngrok, 如何使用请自行搜索.

## Maven 引用开发包

```xml
<dependency>
  <groupId>com.github.binarywang</groupId>
  <artifactId>（不同模块参考下文）</artifactId>
  <version>(参考 Github 最新版本)</version>
</dependency>
```

- 微信小程序：`weixin-java-miniapp`
- 微信支付：`weixin-java-pay`
- 微信开放平台：`weixin-java-open`
- 公众号（包括订阅号和服务号）：`weixin-java-mp`
- 企业号/企业微信：`weixin-java-cp`

# 开发者服务器配置

## 作用

* 接收微信各种事件推送(eg: 关注公众号事件/关键字回复/公众号菜单点击事件/扫码事件等)
* 扩展微信公众号功能(eg: 自动回复/自定义菜单等)

## 流程说明

服务器地址**只能配置一个 URL**, 此后所有检测(微信会定时发送 GET 请求到此 URL 确认服务器还正常运行)以及所有的事件回调(关注事件/文本接收等)都会发送到此 URL:

* 对于服务器检测, 发送的是 **GET** 请求
* 其他事件推送, 发送的是 **POST** 请求

## 服务器开发

在配置服务器前, 需要实现开发(只需要能够收到并处理检测的 GET 请求即可)并启动服务器

因为在提交配置的时候微信会检测服务器可用情况.

核心代码示例(WxJava配置请查看官网):

```java
@Slf4j
@RequiredArgsConstructor
@RestController
@RequestMapping("/wx/portal")
public class WxController {

	private final WxMpService wxService;

	@GetMapping(produces = "text/plain;charset=utf-8")
	public String authGet(@RequestParam(name = "signature", required = false) String signature,
						  @RequestParam(name = "timestamp", required = false) String timestamp,
						  @RequestParam(name = "nonce", required = false) String nonce,
						  @RequestParam(name = "echostr", required = false) String echostr) {
		log.info("\n接收到来自微信服务器的认证消息：[{}, {}, {}, {}]", signature, timestamp, nonce, echostr);
		if (StringUtils.isAnyBlank(signature, timestamp, nonce, echostr)) {
			return "请求参数非法，请核实!";
		}

		return wxService.checkSignature(timestamp, nonce, signature) ? echostr : "非法请求";
	}
}
```

此时我们处理微信请求的路径为 `/wx/portal`, 假定:

*  `serverContextPath` 为 `portal-user`
* 内网穿透地址为 `http://wx.ngrok.yangbingdong.com`

那么我们最终的服务器 URL 为 `http://wx.ngrok.yangbingdong.com/portal-user/wx/portal`.

## 配置服务器

进入微信公众号平台, 在左边最下面找到**开发** -> **基本配置**:

![](https://cdn.yangbingdong.com/img/weixin-dev/weixin-mp-dev-setting-bar.png)

![](https://cdn.yangbingdong.com/img/weixin-dev/weixin-mp-dev-setting.png)

点击修改配置, 并填入 URL:

![](https://cdn.yangbingdong.com/img/weixin-dev/weixin-mp-dev-setting-server.png)

点击提交, 此时微信会发送 GET 请求到服务器:

![](https://cdn.yangbingdong.com/img/weixin-dev/weixin-mp-server-verify.png)

至此, 自己的服务器已接入微信公众号平台.

## 启用服务器

接收微信的推送事件需要将服务器配置**启用**, 否则会无法收到事件推送.

![](https://cdn.yangbingdong.com/img/weixin-dev/weixin-mp-dev-enable-server.png)

## 配置白名单

获取微信公众号 access_token 前, 还需要配置 **IP 白名单**, 否则会报 **40164** 错误(`invalid ip x.x.x.x, not in whitelist hint...`)

# 接收并处理微信推送的消息

> 微信推送都是以 POST 请求发送的.
>
> **注意**: **公众号调用各接口时都需使用access_token**, 文档请看***[这里](https://developers.weixin.qq.com/doc/offiaccount/Basic_Information/Get_access_token.html)***, 在 WxJava 中通过 `WxMpConfigStorage` 管理 access_token, 我们只需要 Redis版 的 `WxMpConfigStorage`  即可(请看 WxJava 官方 Demo).

先看两段段明文的消息报文示例:

```xml
<xml>
  <ToUserName><![CDATA[gh_0544c55c0947]]></ToUserName>  
  <FromUserName><![CDATA[ouaAwuL0sOndEGFIvXULJlwj0jrk]]></FromUserName>  
  <CreateTime>1596276376</CreateTime>  
  <MsgType><![CDATA[text]]></MsgType>  
  <Content><![CDATA[你好]]></Content>  
  <MsgId>22853185785369939</MsgId> 
</xml>
```

```xml
<xml>
  <ToUserName><![CDATA[gh_0544c55c0947]]></ToUserName>  
  <FromUserName><![CDATA[ouaAwuL0sOndEGFIvXULJlwj0jrk]]></FromUserName>  
  <CreateTime>1596276457</CreateTime>  
  <MsgType><![CDATA[event]]></MsgType>  
  <Event><![CDATA[VIEW]]></Event>  
  <EventKey><![CDATA[https://open.weixin.qq.com/connect/oauth2/authorize?appid=wx123123123123&redirect_uri=http%3A%2F%2Fwx.ngrok.yangbingdong.com%2Fportal-user%2Fwx%2Fredirect%2Fgreet&response_type=code&scope=snsapi_userinfo&state=&connect_redirect=1#wechat_redirect]]></EventKey>  
  <MenuId>426548808</MenuId> 
</xml>

```

微信推送的消息基本都会带有 `MsgType` 字段, 比较常用的就是:

* `text`: 普通文本消息
* `event`: 事件, 如果 MsgType 为 `event`, 那么还会附带 `Event` 字段, 代表事件类型:
  * `subscribe`: 关注事件
  * `CLICK`: 菜单点击事件
  * `VIEW`: 菜单连接查看事件

更多的消息类型以及事件类型查看 `me.chanjar.weixin.common.api.WxConsts.XmlMsgType` 与 `me.chanjar.weixin.common.api.WxConsts.EventType`.

处理这类消息也很简单, 只需要配置 `WxMpMessageRouter` 即可:

```java
@Bean
public WxMpMessageRouter messageRouter(WxMpService wxMpService,
									   ObjectProvider<RedisUtils> redisUtilsObjectProvider) {
	final WxMpMessageRouter newRouter = new WxMpMessageRouter(wxMpService);
	newRouter.setMessageDuplicateChecker(new WxRedisMessageDuplicateChecker(redisUtilsObjectProvider.getIfAvailable()));

	// 记录所有事件的日志 （异步执行）
	newRouter.rule().handler(wxEventLogHandler).next();

	// 自定义菜单事件
	newRouter.rule().async(false).msgType(EVENT).event(WxConsts.EventType.CLICK).handler(menuHandler).end();

	// 点击菜单连接事件
	newRouter.rule().async(false).msgType(EVENT).event(WxConsts.EventType.VIEW).handler(nullHandler).end();

	// 关注事件
	newRouter.rule().async(false).msgType(EVENT).event(SUBSCRIBE).handler(subscribeHandler).end();

	// 取消关注事件
	newRouter.rule().msgType(EVENT).event(UNSUBSCRIBE).handler(unsubscribeHandler).end();

	// 扫码事件
	newRouter.rule().async(false).msgType(EVENT).event(WxConsts.EventType.SCAN).handler(scanHandler).end();

	// 文本输入
	newRouter.rule().async(false).msgType(TEXT).handler(msgHandler).end();

	// 默认
	newRouter.rule().async(false).handler(nullHandler).end();

	return newRouter;
}
```

然后在 POST 请求中处理:

```java
@PostMapping(produces = "application/xml; charset=UTF-8")
public String post(@RequestBody String requestBody,
				   @RequestParam("signature") String signature,
				   @RequestParam("timestamp") String timestamp,
				   @RequestParam("nonce") String nonce,
				   @RequestParam("openid") String openid,
				   @RequestParam(name = "encrypt_type", required = false) String encType,
				   @RequestParam(name = "msg_signature", required = false) String msgSignature) {
	log.info("接收微信请求：[openid=[{}], [signature=[{}], encType=[{}], msgSignature=[{}], timestamp=[{}], nonce=[{}], requestBody=[\n{}\n] ",
		openid, signature, encType, msgSignature, timestamp, nonce, requestBody);
	if (log.isDebugEnabled()) {
		log.debug("接收微信请求：[openid=[{}], [signature=[{}], encType=[{}], msgSignature=[{}], timestamp=[{}], nonce=[{}], requestBody=[\n{}\n] ",
			openid, signature, encType, msgSignature, timestamp, nonce, requestBody);
	}

	if (!wxService.checkSignature(timestamp, nonce, signature)) {
		log.warn("非法请求，可能属于伪造的请求！[openid=[{}], [signature=[{}], encType=[{}], msgSignature=[{}], timestamp=[{}], nonce=[{}], requestBody=[\n{}\n] ",
			openid, signature, encType, msgSignature, timestamp, nonce, requestBody);
		return null;
	}

	String out = encrypt(encType) ?
		handlerEncryptedMessage(requestBody, timestamp, nonce, msgSignature) :
		handlerPlainTextMessage(requestBody);
	if (log.isDebugEnabled()) {
		log.debug("组装回复信息：{}", out);
	}
	return out;
}

private boolean encrypt(String encType) {
	return "aes".equalsIgnoreCase(encType);
}

/**
 * 处理明文
 */
private String handlerPlainTextMessage(String requestBody) {
	WxMpXmlMessage inMessage = WxMpXmlMessage.fromXml(requestBody);
	return Optional.ofNullable(route(inMessage))
				   .map(WxMpXmlOutMessage::toXml)
				   .orElse(null);
}

/**
 * 处理密文
 */
private String handlerEncryptedMessage(String requestBody, String timestamp, String nonce, String msgSignature) {
	WxMpXmlMessage inMessage = WxMpXmlMessage.fromEncryptedXml(requestBody, wxService.getWxMpConfigStorage(), timestamp, nonce, msgSignature);
	if (log.isDebugEnabled()) {
		log.debug("消息解密后内容为：\n{} ", inMessage.toString());
	}
	return Optional.ofNullable(this.route(inMessage))
				   .map(m -> m.toEncryptedXml(wxService.getWxMpConfigStorage()))
				   .orElse(null);
}

private WxMpXmlOutMessage route(WxMpXmlMessage message) {
	try {
		return this.messageRouter.route(message);
	} catch (Exception e) {
		log.error("路由微信消息时出现异常！", e);
	}
	return null;
}
```

# 授权获取用户信息

> ***[微信网页授权文档](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/Wechat_webpage_authorization.html)***

在调用授权接口之前, 需要配置网页授权域名, 在 **公众号设置** -> **功能设置** -> **网页授权域名**

**切记**, **只需要配置域名**, **不要加协议**, **也不要加路径**, 否则 **10003** 错误, 也就是 **`redirect_uri`域名与后台配置不一致错误**. `redirect_uri` 上面配置的网页授权域名, `redirect_uri` 可以添加参数, 比如标记落地页等. 用户同意授权后微信会在 `redirect_uri` 后面加上 `code` 参数, 并重定向到该 URL.

流程走的是标准的 OAUTH2, 什么是 OAUTH2 自行搜索...

主要流程就是:

* 构建授权 URL(微信跳转到该 `redirectUri` 时会在参数后面拼接上 `code`):

  ```java
  String url = this.wxService.oauth2buildAuthorizationUrl(redirectUri, WxConsts.OAuth2Scope.SNSAPI_USERINFO, null);
  ```

* 用户点击 URL, 微信重定向到 `redirectUri`, 并附带上 `code` 参数

* 利用 `code` 获取 `access_token`:

  ```java
  WxMpOAuth2AccessToken accessToken = wxService.oauth2getAccessToken(code);
  ```

* 利用 `access_token` 获取用户信息:

  ```java
  WxMpUser user = wxService.oauth2getUserInfo(accessToken, null);
  ```

# 获取 JS-SDK 加密信息

>  ***[JS-SDK 说明文档](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/JS-SDK.html)***
>
>  ***[JS-SDK 使用权限签名算法](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/JS-SDK.html#62)***

**需要提前配置JS接口安全域名**, **公众号设置** -> **功能设置** -> **JS接口安全域名**

```java
WxJsapiSignature jsapiSignature = wxService.createJsapiSignature("当前页面 URL");
```

# 创建自定义公众号菜单

```java
@GetMapping("/create")
public String menuCreateSample(@PathVariable String appid) throws WxErrorException, MalformedURLException {
    WxMenu menu = new WxMenu();
    WxMenuButton button1 = new WxMenuButton();
    button1.setType(MenuButtonType.CLICK);
    button1.setName("今日歌曲");
    button1.setKey("V1001_TODAY_MUSIC");

   WxMenuButton button2 = new WxMenuButton();
   button2.setType(MenuButtonType.MINIPROGRAM);
   button2.setName("小程序");
   button2.setAppId("wx286b93c14bbf93aa");
   button2.setPagePath("pages/lunar/index.html");
   button2.setUrl("http://mp.weixin.qq.com");

    WxMenuButton button3 = new WxMenuButton();
    button3.setName("菜单");

    menu.getButtons().add(button1);
    menu.getButtons().add(button2);
    menu.getButtons().add(button3);

    WxMenuButton button31 = new WxMenuButton();
    button31.setType(MenuButtonType.VIEW);
    button31.setName("搜索");
    button31.setUrl("http://www.soso.com/");

    WxMenuButton button32 = new WxMenuButton();
    button32.setType(MenuButtonType.VIEW);
    button32.setName("视频");
    button32.setUrl("http://v.qq.com/");

    WxMenuButton button33 = new WxMenuButton();
    button33.setType(MenuButtonType.CLICK);
    button33.setName("赞一下我们");
    button33.setKey("V1001_GOOD");

    WxMenuButton button34 = new WxMenuButton();
    button34.setType(MenuButtonType.VIEW);
    button34.setName("获取用户信息");

    ServletRequestAttributes servletRequestAttributes =
        (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
    if (servletRequestAttributes != null) {
        HttpServletRequest request = servletRequestAttributes.getRequest();
        URL requestURL = new URL(request.getRequestURL().toString());
        String url = this.wxService.switchoverTo(appid).oauth2buildAuthorizationUrl(
            String.format("%s://%s/wx/redirect/%s/greet", requestURL.getProtocol(), requestURL.getHost(), appid),
            WxConsts.OAuth2Scope.SNSAPI_USERINFO, null);
        button34.setUrl(url);
    }

    button3.getSubButtons().add(button31);
    button3.getSubButtons().add(button32);
    button3.getSubButtons().add(button33);
    button3.getSubButtons().add(button34);

    this.wxService.switchover(appid);
    return this.wxService.getMenuService().menuCreate(menu);
}
```

# 微信支付

支付步骤:

* 调用微信统一下单接口, 拿到 prepay_id
* 根据不同端封装返回参数(小程序支付/JS-SDK支付/H5支付等)
* 前端拉起微信支付
* 用户支付
* 支付成功回调

相关文档:

* ***[微信JSAPI支付业务流程](https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=7_4)***
* ***[统一下单](https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=9_1)***
* ***[微信JS-SDK支付](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/JS-SDK.html#58)***
* ***[支付签名算法](https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=4_3)***

## 注意事项

**`timestamp` 驼峰命名问题**:

微信公众号中的微信支付采用 JS-SDK, 文档中的 `timestamp` 中的 `s` 是**小写**, 而签名中需要时 `timeStamp`(`S` **大写**), 这一点文档中有说明, 需要注意:

```
wx.chooseWXPay({
  timestamp: 0, // 支付签名时间戳，注意微信jssdk中的所有使用timestamp字段均为小写。但最新版的支付后台生成签名使用的timeStamp字段名需大写其中的S字符
  nonceStr: '', // 支付签名随机串，不长于 32 位
  package: '', // 统一支付接口返回的prepay_id参数值，提交格式如：prepay_id=\*\*\*）
  signType: '', // 签名方式，默认为'SHA1'，使用新版支付需传入'MD5'
  paySign: '', // 支付签名
  success: function (res) {
    // 支付成功后的回调函数
  }
});
```

# 关注公众号后网站自动登录功能实现

网页端的微信登录多数基于*[微信开放平台登录功能](https://developers.weixin.qq.com/doc/oplatform/Website_App/WeChat_Login/Wechat_Login.html)*, 这种方式需要申请开放平台, 比较麻烦.

另外一种扫码登录方式只需要一个微信**服务号**就行, 大概流程是：

* 点击微信登录, 网站自己弹出一个二维码
* 扫描二维码后弹出公众号的关注界面
* 只要一关注公众号网站自动登录, 第二次扫描登录的时候网站直接登录
* 体验一下 *[「随便找的一个网站」](http://90sheji.com/)*, 这种扫码登录的方式有利于公众号推广

主要的核心原理就是利用了 ***[带参数二维码](https://developers.weixin.qq.com/doc/offiaccount/Account_Management/Generating_a_Parametric_QR_Code.html)*** 以及 ***[接收事件推送](https://developers.weixin.qq.com/doc/offiaccount/Message_Management/Receiving_event_pushes.html)***.

所以实现方案大概如下:

* 生成自定义场景值参数, 比如UUID字符串, 设置进 Redis 中, key 生成的字符串, value 为空字符串
* 使用上面生成的随机字符串生成**临时带参数二维码**(`action_name=QR_STR_SCENE&scene_str={UUID}`)
* 将二维码与 UUID 一同返回前端, 前端通过 UUID **轮询**登录状态
* 用户扫描二维码, 会有以下两种情况:
  * 如果用户还未关注公众号, 则用户可以关注公众号, 关注后微信会将带场景值关注事件推送给开发者.
  * 如果用户已经关注公众号, 在用户扫描后会自动进入会话, 微信也会将带场景值扫描事件推送给开发者.
* 根据扫码结果(微信回调拿到自定义字符串与 OpenId), 创建用户(已创建则跳过这步), 修改 Redis 中对应的值改为用户Id或者登录 Token
* 前端轮训拿到了用户 Id 或者 Token, 完成登录.

# 注意事项

* 配置的服务器 URL 不要拦截(登录拦截等), 只支持 80 或 443 端口.
* 微信消息可能会重复发送, 需要开发者自己确保幂等, 虽然 WxJava 已经带有消息去重逻辑, 但模式实现是单机版的, 所以如果是集群的服务器, 需要自己实现 `WxMessageDuplicateChecker`, 并配置到 `WxMpMessageRouter` 中.