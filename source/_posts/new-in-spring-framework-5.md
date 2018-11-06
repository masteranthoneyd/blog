---
title: Spring5新特征与WebFlux反应式编程
date: 2017-11-22 07:35:38
categories: [Programming, Java]
tags: [Java, Spring5]
---

![](https://cdn.yangbingdong.com/img/spring-framework-5/spring-framework-5.png)

# Preface

> Spring 5 于 2017 年 9 月发布了通用版本 (`GA`)，它标志着自 2013 年 12 月以来第一个主要 Spring Framework 版本。它提供了一些人们期待已久的改进，还采用了一种全新的编程范例，以***[反应式宣言](http://www.reactivemanifesto.org/)***中陈述的反应式原则为基础。
>
> 这个版本是很长时间以来最令人兴奋的 Spring Framework 版本。Spring 5 兼容 `Java™8` 和 `JDK 9`，它集成了**反应式流**，以便提供一种颠覆性方法来实现端点和 Web 应用程序开发。
>
> 诚然，反应式编程不仅是此版本的主题，还是令许多开发人员激动不已的重大特性。人们对能够针对负载波动进行无缝扩展的灾备和响应式服务的需求在不断增加，Spring 5 很好地满足了这一需求。
>
> 本文将全面介绍 Spring 5。我将介绍 Java SE 8 和 Java EE 7 API 的基准升级、Spring 5 的新反应式编程模型、[HTTP/2](https://www.ibm.com/developerworks/library/wa-http2-under-the-hood/index.html) 支持，以及 Spring 通过 `Kotlin` 对函数式编程的全面支持。我还会简要介绍测试和性能增强，最后介绍对 Spring 核心和容器的一般性修订。

<!--more-->

# Spring Framework 5 中的新特性

## 升级到 Java SE 8 和 Java EE 7

直到现在，Spring Framework 仍支持一些弃用的 Java 版本，但 Spring 5 已从旧包袱中解放出来。为了充分利用 Java 8 特性，它的代码库已进行了改进，而且该框架要求将 Java 8 作为**最低的 JDK 版本**。

Spring 5 在类路径（和模块路径）上完全兼容 Java 9，而且它通过了 JDK 9 测试套件的测试。对 Java 9 爱好者而言，这是一条好消息，因为在 Java 9 发布后，Spring 能立即使用它。

在 `API` 级别上，Spring 5 兼容 Java EE 8 技术，满足对 `Servlet 4.0`、`Bean Validation 2.0` 和全新的 `JSON Binding API` 的需求。对 Java EE API 的最低要求为 `V7`，该版本引入了针对 `Servlet`、`JPA` 和 `Bean Validation API` 的次要版本。

## 反应式编程模型

Spring 5 最令人兴奋的新特性是它的**反应式编程模型**。Spring 5 Framework 基于一种反应式基础而构建，而且是**完全异步和非阻塞的**。只需少量的线程，新的事件循环执行模型就可以垂直扩展。

该框架采用反应式流来提供在反应式组件中传播负压的机制。**负压**是一个**确保来自多个生产者的数据不会让使用者不堪重负的概念**。

`Spring WebFlux` 是 Spring 5 的反应式核心，它为开发人员提供了两种为 Spring Web 编程而设计的编程模型：一种基于**注解的模型**和 **Functional Web Framework** (`WebFlux.fn`)。

基于注解的模型是 Spring WebMVC 的现代替代方案，该模型基于反应式基础而构建，而 Functional Web Framework 是基于`@Controller` 注解的编程模型的替代方案。这些模型都通过同一种反应式基础来运行，后者调整非阻塞 HTTP 来适应反应式流 API。

## 使用注解进行编程

WebMVC 程序员应该对 Spring 5 的基于注解的编程模型非常熟悉。Spring 5 调整了 WebMVC 的 `@Controller` 编程模型，采用了相同的注解。

在清单 1 中，`BookController` 类提供了两个方法，分别响应针对某个图书列表的 HTTP 请求，以及针对具有给定 `id` 的图书的 HTTP 请求。请注意 resource 方法返回的对象（`Mono` 和 `Flux`）。这些对象是实现***[反应式流](http://www.reactive-streams.org/)***规范中的 `Publisher` 接口的反应式类型。它们的职责是处理数据流。`Mono` 对象处理一个**仅含 1 个元素的流**，而 `Flux` 表示一个**包含 N 个元素的流**。

**清单 1. 反应式控制器**
```
@RestController
public class BookController {
 
    @GetMapping("/book")
    Flux<Book> list() {
        return this.repository.findAll();
    }
 
    @GetMapping("/book/{id}")
    Mono<Book> findById(@PathVariable String id) {
        return this.repository.findOne(id);
    }
 
    // Plumbing code omitted for brevity
}
```

这是针对 Spring Web 编程的注解。现在我们使用函数式 Web 框架来解决同一个问题。

## 函数式编程

Spring 5 的新函数式方法将请求委托给处理函数，这些函数接受一个服务器请求实例并返回一种反应式类型。清单 2 演示了这一过程，其中 `listBook` 和 `getBook` 方法类似于清单 1 中的功能。

**清单 2. 清单 2.BookHandler 函数类**
```
public class BookHandler {
 
    public Mono<ServerResponse> listBooks(ServerRequest request) {
        return ServerResponse.ok()
            .contentType(APPLICATION_JSON)
            .body(repository.allPeople(), Book.class);
    }
     
    public Mono<ServerResponse> getBook(ServerRequest request) {
        return repository.getBook(request.pathVariable("id"))
            .then(book -> ServerResponse.ok()
            .contentType(APPLICATION_JSON)
            .body(fromObject(book)))
            .otherwiseIfEmpty(ServerResponse.notFound().build());
    }
    // Plumbing code omitted for brevity
}
```

通过路由函数来匹配 HTTP 请求谓词与媒体类型，将客户端请求路由到处理函数。清单 3 展示了图书资源端点 URI 将调用委托给合适的处理函数：

**清单 3. Router 函数**
```
BookHandler handler = new BookHandler();
 
RouterFunction<ServerResponse> personRoute =
    route(
        GET("/books/{id}")
        .and(accept(APPLICATION_JSON)), handler::getBook)
        .andRoute(
    GET("/books")
        .and(accept(APPLICATION_JSON)), handler::listBooks);
```

这些示例背后的数据存储库也支持完整的反应式体验，该体验是通过 Spring Data 对反应式 `Couchbase`、`Reactive MongoDB` 和 `Cassandra` 的支持来实现的。

## 使用 REST 端点执行反应式编程

新的编程模型脱离了传统的 Spring WebMVC 模型，引入了一些很不错的新特性。

举例来说，WebFlux 模块为 `RestTemplate` 提供了一种完全非阻塞、反应式的替代方案，名为 `WebClient`。清单 4 创建了一个 `WebClient`，并调用 `books` 端点来请求一本给定 `id` 为 `1234` 的图书。

**清单 4. 通过 WebClient 调用 REST 端点**
```
Mono<Book> book = WebClient.create("http://localhost:8080")
      .get()
      .url("/books/{id}", 1234)
      .accept(APPLICATION_JSON)
      .exchange(request)
      .then(response -> response.bodyToMono(Book.class));
```

## HTTP/2 支持

**HTTP/2 幕后原理：**要了解 HTTP/2 如何提高传输性能，减少延迟，并帮助提高应用程序吞吐量，从而提供经过改进的丰富 Web 体验，请查阅*[https://www.ibm.com/developerworks/cn/web/wa-http2-under-the-hood/index.html](https://www.ibm.com/developerworks/cn/web/wa-http2-under-the-hood/index.html)*。

Spring Framework 5.0 将提供专门的 *[HTTP/2 特性](https://www.ibm.com/developerworks/cn/web/wa-http2-under-the-hood/index.html)* 支持，还支持人们期望出现在 JDK 9 中的新 HTTP 客户端。尽管 HTTP/2 的服务器推送功能已通过 Jetty servlet 引擎的 `ServerPushFilter` 类向 Spring 开发人员公开了很长一段时间，但如果发现 Spring 5 中开箱即用地提供了 *[HTTP/2](https://www.ibm.com/developerworks/cn/web/wa-http2-under-the-hood/index.html)* 性能增强，Web 优化者们一定会为此欢呼雀跃。

Java EE Servlet 规范预计将于 2017 年第 4 季度发布，Servlet 4.0 支持将在 Spring 5.1 中提供。到那时，*[HTTP/2 特性](https://www.ibm.com/developerworks/cn/web/wa-http2-under-the-hood/index.html)* 将由 Tomcat 9.0、Jetty 9.3 和 Undertow 1.4 原生提供。

Kotlin 和 Spring WebFlux

`Kotlin` 是一种来自 *[JetBrains](https://blog.jetbrains.com/kotlin/)* 的面向对象的语言，它支持函数式编程。它的主要优势之一是与 Java 有非常高的互操作性。通过引入对 `Kotlin` 的专门支持，Spring 在 V5 中全面吸纳了这一优势。它的函数式编程风格与 Spring WebFlux 模块完美匹配，它的新路由 DSL 利用了函数式 Web 框架以及干净且符合语言习惯的代码。可以像清单 5 中这样简单地表达端点路由：

**清单 5. Kotlin 的用于定义端点的路由 DSL**

```
@Bean
fun apiRouter() = router {
    (accept(APPLICATION_JSON) and "/api").nest {
        "/book".nest {
            GET("/", bookHandler::findAll)
            GET("/{id}", bookHandler::findOne)
        }
        "/video".nest {
            GET("/", videoHandler::findAll)
            GET("/{genre}", videoHandler::findByGenre)
        }
    }
}
```

使用 `Kotlin 1.1.4+` 时，还添加了对 Kotlin 的不可变类的支持（通过带默认值的可选参数），以及对完全支持 `null` 的 API 的支持。

## 使用 Lambda 表达式注册 bean

作为传统 XML 和 JavaConfig 的替代方案，现在可以使用 lambda 表达式注册 Spring bean，使 bean 可以实际注册为提供者。清单 6 使用 lambda 表达式注册了一个 `Book` bean。

**清单 6. 将 Bean 注册为提供者**
```
GenericApplicationContext context = new GenericApplicationContext();
context.registerBean(Book.class, () -> new 
              Book(context.getBean(Author.class))
        );
```

## Spring WebMVC 支持最新的 API

全新的 WebFlux 模块提供了许多新的、令人兴奋的功能，但 Spring 5 也迎合了愿意继续使用 Spring MVC 的开发人员的需求。Spring 5 中更新了模型-视图-控制器框架，以兼容 WebFlux 和最新版的 *[Jackson 2.9](https://github.com/FasterXML/jackson/wiki/Jackson-Release-2.9)* 和 *[Protobuf 3.0](https://github.com/google/protobuf/releases?after=v3.0.0-alpha-3)*，甚至包括对新的 *[Java EE 8 JSON-Binding API](http://json-b.net/)* 的支持。

除了 *[HTTP/2 特性](https://www.ibm.com/developerworks/cn/web/wa-http2-under-the-hood/index.html)* 的基础服务器实现之外，Spring WebMVC 还通过 MVC 控制器方法的一个参数来支持 Servlet 4.0 的 `PushBuilder`。最后，WebMVC 全面支持 Reactor 3.1 的 `Flux` 和 `Mono` 对象，以及 [RxJava](https://github.com/ReactiveX/RxJava/wiki) 1.3 和 2.1，它们被视为来自 MVC 控制器方法的返回值。这项支持的最终目的是支持 Spring Data 中的新的反应式 `WebClient` 和反应式存储库。

## 使用 JUnit 5 执行条件和并发测试

**JUnit 和 Spring 5**：Spring 5 全面接纳了函数式范例，并支持 JUnit 5 及其新的函数式测试风格。还提供了对 JUnit 4 的向后兼容性，以确保不会破坏旧代码。

Spring 5 的测试套件通过多种方式得到了增强，但最明显的是它对 *[JUnit 5](http://junit.org/junit5/)* 的支持。现在可以在您的单元测试中利用 Java 8 中提供的函数式编程特性。清单 7 演示了这一支持：

**清单 7.JUnit 5 全面接纳了 Java 8 流和 lambda 表达式**
```
@Test
void givenStreamOfInts_SumShouldBeMoreThanFive() {
    assertTrue(Stream.of(20, 40, 50)
      .stream()
      .mapToInt(i -> i)
      .sum() > 110, () -> "Total should be more than 100");
}
```

**迁移到 JUnit 5：**如果您对升级到 JUnit 5 持观望态度，Steve Perry 的*[分两部分的深入剖析教程](https://www.ibm.com/developerworks/cn/views/global/libraryview.jsp?sort_by=&show_abstract=true&show_all=&search_flag=&contentarea_by=%E6%89%80%E6%9C%89%E4%B8%93%E5%8C%BA&search_by=JUnit+5+%E7%AE%80%E4%BB%8B&product_by=-1&topic_by=-1&type_by=%E6%89%80%E6%9C%89%E7%B1%BB%E5%88%AB&ibm-search=%E6%90%9C%E7%B4%A2)* 将说服您冒险尝试。

Spring 5 继承了 *[JUnit 5](https://www.ibm.com/developerworks/cn/java/j-introducing-junit5-part1-jupiter-api/index.html)* 在 Spring TestContext Framework 内实现多个扩展 API 的灵活性。举例而言，开发人员可以使用 JUnit 5 的条件测试执行注解 `@EnabledIf` 和 `@DisabledIf` 来自动计算一个 *[SpEL](https://docs.spring.io/spring/docs/current/spring-framework-reference/html/expressions.html)* (Spring Expression Language) 表达式，并适当地启用或禁用测试。借助这些注解，Spring 5 支持以前很难实现的复杂的条件测试方案。Spring TextContext Framework 现在能够并发执行测试。

## 使用 Spring WebFlux 执行集成测试

Spring Test 现在包含一个 `WebTestClient`，后者支持对 Spring WebFlux 服务器端点执行集成测试。`WebTestClient` 使用模拟请求和响应来避免耗尽服务器资源，并能直接绑定到 WebFlux 服务器基础架构。

`WebTestClient` 可绑定到真实的服务器，或者使用控制器或函数。在清单 8 中，`WebTestClient` 被绑定到 localhost：

**清单 8. 绑定到 localhost 的 `WebTestClient`**

```
WebTestClient testClient = WebTestClient
  .bindToServer()
  .baseUrl("http://localhost:8080")
  .build();
```

**清单 9. 将 `WebTestClient` 绑定到 `RouterFunction`**

```
RouterFunction bookRouter = RouterFunctions.route(
  RequestPredicates.GET("/books"),
  request -> ServerResponse.ok().build()
);
  
WebTestClient
  .bindToRouterFunction(bookRouter)
  .build().get().uri("/books")
  .exchange()
  .expectStatus().isOk()
  .expectBody().isEmpty();
```

## 包清理和弃用

Spring 5 中止了对一些过时 API 的支持。遭此厄运的还有 Hibernate 3 和 4，为了支持 Hibernate 5，它们遭到了弃用。另外，对 Portlet、Velocity、JasperReports、XMLBeans、JDO 和 Guava 的支持也已中止。

包级别上的清理工作仍在继续：Spring 5 不再支持 `beans.factory.access`、`jdbc.support.nativejdbc`、`mock.staticmock`（来自 spring-aspects 模块）或 `web.view.tiles2M`。Tiles 3 现在是 Spring 的最低要求。

## 对 Spring 核心和容器的一般更新

Spring Framework 5 改进了扫描和识别组件的方法，使大型项目的性能得到提升。目前，扫描是在编译时执行的，而且向 *[META-INF/spring.components](https://jira.spring.io/browse/SPR-11890)* 文件中的索引文件添加了组件坐标。该索引是通过一个为项目定义的特定于平台的应用程序构建任务来生成的。

标有来自 *[javax 包](https://docs.oracle.com/javase/8/docs/api/overview-summary.html)* 的注解的组件会添加到索引中，任何带 `@Index` 注解的类或接口都会添加到索引中。Spring 的传统类路径扫描方式没有删除，而是保留为一种后备选择。有许多针对大型代码库的明显性能优势，而托管许多 Spring 项目的服务器也会缩短启动时间。

Spring 5 还添加了对 `@Nullable` 的支持，后者可用于指示可选的注入点。使用者现在必须准备接受 null 值。此外，还可以使用此注解来标记可以为 null 的参数、字段和返回值。`@Nullable` 主要用于 IntelliJ IDEA 等 IDE，但也可用于 Eclipse 和 FindBugs，它使得在编译时处理 null 值变得更方便，而无需在运行时发送 `NullPointerExceptions`。

Spring Logging 还提升了性能，自带开箱即用的 Commons Logging 桥接器。现在已通过`资源抽象`支持防御性编程，为 `getFile`访问提供了 `isFile` 指示器。

## 小结
Spring 5 的首要特性是新的反应式编程模型，这代表着对提供可无缝扩展、基于 Spring 的响应式服务的重大保障。随着人们对 Spring 5 的采用，开发人员有望看到反应式编程将会成为使用 Java 语言的 Web 和企业应用程序开发的未来发展道路。

未来的 Spring Framework 版本将继续反映这一承诺，因为 Spring Security、Spring Data 和 Spring Integration 有望采用反应式编程的特征和优势。

总之，Spring 5 代表着一次大受 Spring 开发人员欢迎的范例转变，同时也为其他框架指出了一条发展之路。

# 使用 Spring 5 的 WebFlux 开发反应式 Web 应用

![](https://cdn.yangbingdong.com/img/spring-framework-5/spring-webflux-reactive-mongodb-rest-api-example.png)

## WebFlux 简介

WebFlux 模块的名称是 `spring-webflux`，名称中的 `Flux` 来源于 `Reactor` 中的类 `Flux`。该模块中包含了对**反应式 HTTP**、**服务器推送事件**和 **`WebSocket` 的客户端和服务器端的支持**。对于开发人员来说，比较重要的是服务器端的开发，这也是本文的重点。在服务器端，WebFlux 支持**两种**不同的编程模型：第一种是 Spring MVC 中使用的**基于 Java 注解的方式**；第二种是基于 Java 8 的 lambda 表达式的**函数式编程模型**。这两种编程模型**只是在代码编写方式上存在不同**。它们运行在同样的反应式底层架构之上，因此在**运行时是相同的**。WebFlux 需要底层提供运行时的支持，WebFlux 可以运行在支持 Servlet 3.1 非阻塞 IO API 的 Servlet 容器上，或是其他异步运行时环境，如 `Netty` 和 `Undertow`。

最方便的创建 WebFlux 应用的方式是使用 Spring Boot 提供的**应用模板**。直接访问 Spring Initializ 网站（*[http://start.spring.io/](http://start.spring.io/)* ），选择创建一个 Maven 或 Gradle 项目。Spring Boot 的版本选择 `2.0.0 M2`（或更高）。在添加的依赖中，选择 `Reactive Web`。最后输入应用所在的分组和名称，点击进行下载即可。需要注意的是，只有在选择了 `Spring Boot 2.0.0 M2` 之后，依赖中才可以选择 `Reactive Web`。下载完成之后可以导入到 IDE 中进行编辑。

本文从三个方面对 WebFlux 进行介绍。首先是使用经典的基于 Java 注解的编程模型来进行开发，其次是使用 WebFlux 新增的函数式编程模型来进行开发，最后介绍 WebFlux 应用的测试。通过这样循序渐进的方式让读者了解 WebFlux 应用开发的细节。

## Java 注解编程模型

基于 Java 注解的编程模型，对于使用过 Spring MVC 的开发人员来说是再熟悉不过的。在 WebFlux 应用中使用同样的模式，容易理解和上手。我们先从最经典的 Hello World 的示例开始说明。代码清单 1 中的 `BasicController` 是 REST API 的控制器，通过`@RestController` 注解来声明。在 `BasicController` 中声明了一个 URI 为`/hello_world` 的映射。其对应的方法 `sayHelloWorld()`的返回值是 `Mono<String>`类型，其中包含的字符串`"Hello World"`会作为 HTTP 的响应内容。

**清单 1. Hello World 示例**
```
@RestController
public class BasicController {
    @GetMapping("/hello_world")
    public Mono<String> sayHelloWorld() {
        return Mono.just("Hello World");
    }
}
```

从代码清单 1 中可以看到，使用 WebFlux 与 Spring MVC 的**不同在于**，WebFlux 所使用的类型是与反应式编程相关的 `Flux` 和 `Mono` 等，而**不是简单的对象**。对于简单的 Hello World 示例来说，这两者之间并没有什么太大的差别。**对于复杂的应用来说，反应式编程和负压的优势会体现出来，可以带来整体的性能的提升**。

### REST API

简单的 Hello World 示例并不足以说明 WebFlux 的用法。在下面的小节中，本文将介绍其他具体的实例。先从 REST API 开始说起。REST API 在 Web 服务器端应用中占据了很大的一部分。我们通过一个具体的实例来说明如何使用 WebFlux 来开发 REST API。

该 REST API 用来对用户数据进行基本的 `CRUD` 操作。作为**领域对象**的 User 类中包含了 id、name 和 email 等三个基本的属性。为了对 User 类进行操作，我们需要提供服务类 `UserService`，如代码清单 2 所示。类 `UserService` 使用一个 `Map` 来**保存**所有用户的信息，并不是一个持久化的实现。这对于示例应用来说已经足够了。类 `UserService` 中的方法都以 `Flux` 或 `Mono` 对象作为返回值，这也是 **WebFlux 应用的特征**。在方法 `getById()`中，如果找不到 ID 对应的 User 对象，会返回一个包含了 `ResourceNotFoundException` 异常通知的 `Mono` 对象。方法 `getById()`和 `createOrUpdate()`都可以接受 `String` 或 `Flux` 类型的参数。`Flux` 类型的参数表示的是有多个对象需要处理。这里使用 `doOnNext()`来对其中的每个对象进行处理。

**清单 2. UserService**

```
@Service
class UserService {
    private final Map<String, User> data = new ConcurrentHashMap<>();
 
    Flux<User> list() {
        return Flux.fromIterable(this.data.values());
    }
 
    Flux<User> getById(final Flux<String> ids) {
        return ids.flatMap(id -> Mono.justOrEmpty(this.data.get(id)));
    }
 
    Mono<User> getById(final String id) {
        return Mono.justOrEmpty(this.data.get(id))
                .switchIfEmpty(Mono.error(new ResourceNotFoundException()));
    }
 
    Flux<User> createOrUpdate(final Flux<User> users) {
        return users.doOnNext(user -> this.data.put(user.getId(), user));
    }
 
    Mono<User> createOrUpdate(final User user) {
        this.data.put(user.getId(), user);
        return Mono.just(user);
    }
 
    Mono<User> delete(final String id) {
        return Mono.justOrEmpty(this.data.remove(id));
    }
}
```

代码清单 3 中的类 `UserController` 是具体的 Spring MVC 控制器类。它使用类 `UserService` 来完成具体的功能。类 `UserController` 中使用了注解`@ExceptionHandler` 来添加了 `ResourceNotFoundException` 异常的处理方法，并返回 `404` 错误。类 `UserController` 中的方法都很简单，只是简单地代理给 `UserService` 中的对应方法。

**清单 3. UserController**

```
@RestController
@RequestMapping("/user")
public class UserController {
    private final UserService userService;
 
    @Autowired
    public UserController(final UserService userService) {
        this.userService = userService;
    }
 
    @ResponseStatus(value = HttpStatus.NOT_FOUND, reason = "Resource not found")
    @ExceptionHandler(ResourceNotFoundException.class)
    public void notFound() {
    }
 
    @GetMapping("")
    public Flux<User> list() {
        return this.userService.list();
    }
 
    @GetMapping("/{id}")
    public Mono<User>getById(@PathVariable("id") final String id) {
        return this.userService.getById(id);
    }
 
    @PostMapping("")
    public Flux<User> create(@RequestBody final Flux<User>  users) {
        return this.userService.createOrUpdate(users);
    }
 
    @PutMapping("/{id}")
    public Mono<User>  update(@PathVariable("id") final String id, @RequestBody final User user) {
        Objects.requireNonNull(user);
        user.setId(id);
        return this.userService.createOrUpdate(user);
    }
 
    @DeleteMapping("/{id}")
    public Mono<User>  delete(@PathVariable("id") final String id) {
        return this.userService.delete(id);
    }
}
```



### 服务器推送事件

服务器推送事件（Server-Sent Events，SSE）允许服务器端不断地推送数据到客户端。相对于 WebSocket 而言，服务器推送事件**只支持服务器端到客户端的单向数据传递**。虽然功能较弱，但优势在于 SSE 在已有的 HTTP 协议上使用简单易懂的文本格式来表示传输的数据。作为 W3C 的推荐规范，SSE 在浏览器端的支持也比较广泛，除了 IE 之外的其他浏览器都提供了支持。在 IE 上也可以使用 polyfill 库来提供支持。在服务器端来说，SSE 是一个不断产生新数据的流，非常适合于用反应式流来表示。在 WebFlux 中创建 SSE 的服务器端是非常简单的。只需要返回的对象的类型是 `Flux<ServerSentEvent>`，就会被自动按照 SSE 规范要求的格式来发送响应。

代码清单 4 中的 `SseController` 是一个使用 SSE 的控制器的示例。其中的方法 `randomNumbers()`表示的是每隔一秒产生一个随机数的 SSE 端点。我们可以使用类 `ServerSentEvent.Builder` 来创建 `ServerSentEvent` 对象。这里我们指定了事件名称 `random`，以及每个事件的标识符和数据。事件的标识符是一个递增的整数，而数据则是产生的随机数。

**清单 4. 服务器推送事件示例**

```
@RestController
@RequestMapping("/sse")
public class SseController {
    @GetMapping("/randomNumbers")
    public Flux<ServerSentEvent<Integer>> randomNumbers() {
        return Flux.interval(Duration.ofSeconds(1))
                .map(seq -> Tuples.of(seq, ThreadLocalRandom.current().nextInt()))
                .map(data -> ServerSentEvent.<Integer>builder()
                        .event("random")
                        .id(Long.toString(data.getT1()))
                        .data(data.getT2())
                        .build());
    }
}
```



在测试 SSE 时，我们只需要使用 curl 来访问即可。代码清单 5 给出了调用 curl http://localhost:8080/sse/randomNumbers 的结果。

**清单 5. SSE 服务器端发送的响应**

```
id:0
event:random
data:751025203
 
id:1
event:random
data:-1591883873
 
id:2
event:random
data:-1899224227
```



### WebSocket

WebSocket 支持客户端与服务器端的双向通讯。当客户端与服务器端之间的交互方式比较复杂时，可以使用 WebSocket。WebSocket 在主流的浏览器上都得到了支持。WebFlux 也对创建 WebSocket 服务器端提供了支持。在服务器端，我们需要实现接口 `org.springframework.web.reactive.socket.WebSocketHandler` 来处理 WebSocket 通讯。接口 `WebSocketHandler` 的方法 `handle` 的参数是接口 `WebSocketSession` 的对象，可以用来获取客户端信息、接送消息和发送消息。代码清单 6 中的 `EchoHandler` 对于每个接收的消息，会发送一个添加了"`ECHO ->` "前缀的响应消息。`WebSocketSession` 的 `receive` 方法的返回值是一个 `Flux<WebSocketMessage>`对象，表示的是接收到的消息流。而 `send` 方法的参数是一个 `Publisher<WebSocketMessage>`对象，表示要发送的消息流。在 `handle` 方法，使用 `map` 操作对 `receive` 方法得到的 `Flux<WebSocketMessage>`中包含的消息继续处理，然后直接由 `send` 方法来发送。

**清单 6. WebSocket 的 EchoHandler 示例**
```
@Component
public class EchoHandler implements WebSocketHandler {
    @Override
    public Mono<Void> handle(final WebSocketSession session) {
        return session.send(
                session.receive()
                        .map(msg -> session.textMessage("ECHO -> " + msg.getPayloadAsText())));
    }
}
```

在创建了 WebSocket 的处理器 `EchoHandler` 之后，下一步需要把它注册到 WebFlux 中。我们首先需要创建一个类 `WebSocketHandlerAdapter` 的对象，该对象负责把 `WebSocketHandler` 关联到 WebFlux 中。代码清单 7 中给出了相应的 Spring 配置。其中的 `HandlerMapping` 类型的 bean 把 `EchoHandler` 映射到路径 `/echo`。

**清单 7. 注册 EchoHandler**

```
@Configuration
public class WebSocketConfiguration {
 
    @Autowired
    @Bean
    public HandlerMapping webSocketMapping(final EchoHandler echoHandler) {
        final Map<String, WebSocketHandler> map = new HashMap<>(1);
        map.put("/echo", echoHandler);
 
        final SimpleUrlHandlerMapping mapping = new SimpleUrlHandlerMapping();
        mapping.setOrder(Ordered.HIGHEST_PRECEDENCE);
        mapping.setUrlMap(map);
        return mapping;
    }
 
    @Bean
    public WebSocketHandlerAdapter handlerAdapter() {
        return new WebSocketHandlerAdapter();
    }
}
```

运行应用之后，可以使用工具来测试该 WebSocket 服务。打开工具页面 *[https://www.websocket.org/echo.html](https://www.websocket.org/echo.html)*，然后连接到 *ws://localhost:8080/echo*，可以发送消息并查看服务器端返回的结果。

## 函数式编程模型

在上节中介绍了基于 Java 注解的编程模型，WebFlux 还支持基于 lambda 表达式的函数式编程模型。与基于 Java 注解的编程模型相比，函数式编程模型的抽象层次更低，代码编写更灵活，可以满足一些对动态性要求更高的场景。不过在编写时的代码复杂度也较高，学习曲线也较陡。开发人员可以根据实际的需要来选择合适的编程模型。目前 Spring Boot 不支持在一个应用中同时使用两种不同的编程模式。

为了说明函数式编程模型的用法，我们使用 `Spring Initializ` 来创建一个新的 WebFlux 项目。在函数式编程模型中，每个请求是由一个函数来处理的， 通过接口 `org.springframework.web.reactive.function.server.HandlerFunction` 来表示。`HandlerFunction` 是一个函数式接口，其中只有一个方法 `Mono<T extends ServerResponse> handle(ServerRequest request)`，因此可以用 labmda 表达式来实现该接口。接口 `ServerRequest` 表示的是一个 HTTP 请求。通过该接口可以获取到请求的相关信息，如请求路径、HTTP 头、查询参数和请求内容等。方法 `handle` 的返回值是一个 `Mono<T extends ServerResponse>`对象。接口 `ServerResponse` 用来表示 HTTP 响应。`ServerResponse` 中包含了很多静态方法来创建不同 HTTP 状态码的响应对象。本节中通过一个简单的计算器来展示函数式编程模型的用法。代码清单 8 中给出了处理不同请求的类 `CalculatorHandler`，其中包含的方法 `add`、`subtract`、`multiply` 和 `divide` 都是接口 `HandlerFunction` 的实现。这些方法分别对应加、减、乘、除四种运算。每种运算都是从 HTTP 请求中获取到两个作为操作数的整数，再把运算的结果返回。

**清单 8. 处理请求的类 CalculatorHandler**

```
@Component
public class CalculatorHandler {
 
    public Mono<ServerResponse> add(final ServerRequest request) {
        return calculate(request, (v1, v2) -> v1 + v2);
    }
 
    public Mono<ServerResponse> subtract(final ServerRequest request) {
        return calculate(request, (v1, v2) -> v1 - v2);
    }
 
    public Mono<ServerResponse>  multiply(final ServerRequest request) {
        return calculate(request, (v1, v2) -> v1 * v2);
    }
 
    public Mono<ServerResponse> divide(final ServerRequest request) {
        return calculate(request, (v1, v2) -> v1 / v2);
    }
 
    private Mono<ServerResponse> calculate(final ServerRequest request,
                                           final BiFunction<Integer, Integer, Integer> calculateFunc) {
        final Tuple2<Integer, Integer> operands = extractOperands(request);
        return ServerResponse
                .ok()
                .body(Mono.just(calculateFunc.apply(operands.getT1(), operands.getT2())), Integer.class);
    }
 
    private Tuple2<Integer, Integer> extractOperands(final ServerRequest request) {
        return Tuples.of(parseOperand(request, "v1"), parseOperand(request, "v2"));
    }
 
    private int parseOperand(final ServerRequest request, final String param) {
        try {
            return Integer.parseInt(request.queryParam(param).orElse("0"));
        } catch (final NumberFormatException e) {
            return 0;
        }
    }
}
```



在创建了处理请求的 `HandlerFunction` 之后，下一步是为这些 `HandlerFunction` 提供路由信息，也就是这些 `HandlerFunction` 被调用的条件。这是通过函数式接口 `org.springframework.web.reactive.function.server.RouterFunction` 来完成的。接口 `RouterFunction` 的方法 `Mono<HandlerFunction<T extends ServerResponse>> route(ServerRequest request)`对每个 `ServerRequest`，都返回对应的 0 个或 1 个 `HandlerFunction` 对象，以 `Mono<HandlerFunction>`来表示。当找到对应的 `HandlerFunction` 时，该 `HandlerFunction` 被调用来处理该 `ServerRequest`，并把得到的 `ServerResponse` 返回。在使用 WebFlux 的 Spring Boot 应用中，只需要创建 `RouterFunction` 类型的 `bean`，就会被自动注册来处理请求并调用相应的 `HandlerFunction`。

代码清单 9 给了示例相关的配置类 `Config`。方法 `RouterFunctions.route` 用来根据 `Predicate` 是否匹配来确定 `HandlerFunction` 是否被应用。`RequestPredicates` 中包含了很多静态方法来创建常用的基于不同匹配规则的 `Predicate`。如 `RequestPredicates.path` 用来根据 HTTP 请求的路径来进行匹配。此处我们检查请求的路径是`/calculator`。在清单 9 中，我们首先使用 `ServerRequest` 的 `queryParam` 方法来获取到查询参数 `operator` 的值，然后通过反射 API 在类 `CalculatorHandler` 中找到与查询参数 `operator` 的值名称相同的方法来确定要调用的 `HandlerFunction` 的实现，最后调用查找到的方法来处理该请求。如果找不到查询参数 `operator` 或是 `operator` 的值不在识别的列表中，服务器端返回 `400` 错误；如果反射 API 的方法调用中出现错误，服务器端返回 `500` 错误。

**清单 9. 注册 RouterFunction**

```
@Configuration
public class Config {
 
    @Bean
    @Autowired
    public RouterFunction<ServerResponse>routerFunction(final CalculatorHandler calculatorHandler) {
        return RouterFunctions.route(RequestPredicates.path("/calculator"), request ->
                request.queryParam("operator").map(operator ->
                        Mono.justOrEmpty(ReflectionUtils.findMethod(CalculatorHandler.class, operator, ServerRequest.class))
                                .flatMap(method -> (Mono<ServerResponse>) ReflectionUtils.invokeMethod(method, calculatorHandler, request))
                                .switchIfEmpty(ServerResponse.badRequest().build())
                                .onErrorResume(ex -> ServerResponse.status(HttpStatus.INTERNAL_SERVER_ERROR).build()))
                        .orElse(ServerResponse.badRequest().build()));
    }
}
```



## 客户端

除了服务器端实现之外，WebFlux 也提供了反应式客户端，可以访问 HTTP、SSE 和 WebSocket 服务器端。

### HTTP

对于 HTTP 和 SSE，可以使用 WebFlux 模块中的类 o`rg.springframework.web.reactive.function.client.WebClient`。代码清单 10 中的 `RESTClient` 用来访问前面小节中创建的 REST API。首先使用 `WebClient.create` 方法来创建一个新的 `WebClient` 对象，然后使用方法 `post` 来创建一个 `POST` 请求，并使用方法 `body` 来设置 `POST` 请求的内容。方法 `exchange` 的作用是发送请求并得到以 `Mono<ServerResponse>`表示的 HTTP 响应。最后对得到的响应进行处理并输出结果。`ServerResponse` 的 `bodyToMono` 方法把响应内容转换成类 `User` 的对象，最终得到的结果是 `Mono<User>`对象。调用 `createdUser.block` 方法的作用是等待请求完成并得到所产生的类 User 的对象。

**清单 10. 使用 WebClient 访问 REST API**

```
public class RESTClient {
    public static void main(final String[] args) {
        final User user = new User();
        user.setName("Test");
        user.setEmail("test@example.org");
        final WebClient client = WebClient.create("http://localhost:8080/user");
        final Monol<User> createdUser = client.post()
                .uri("")
                .accept(MediaType.APPLICATION_JSON)
                .body(Mono.just(user), User.class)
                .exchange()
                .flatMap(response -> response.bodyToMono(User.class));
        System.out.println(createdUser.block());
    }
}
```

### SSE

`WebClient` 还可以用同样的方式来访问 SSE 服务，如代码清单 11 所示。这里我们访问的是在之前的小节中创建的生成随机数的 SSE 服务。使用 `WebClient` 访问 SSE 在发送请求部分与访问 REST API 是相同的，所不同的地方在于对 HTTP 响应的处理。由于 SSE 服务的响应是一个消息流，我们需要使用 `flatMapMany` 把 `Mono<ServerResponse>`转换成一个 `Flux<ServerSentEvent>`对象，这是通过方法 `BodyExtractors.toFlux` 来完成的，其中的参数 `new ParameterizedTypeReference<ServerSentEvent<String>>() {}`表明了响应消息流中的内容是 `ServerSentEvent` 对象。由于 SSE 服务器会不断地发送消息，这里我们只是通过 `buffer` 方法来获取前 10 条消息并输出。

**清单 11. 使用 WebClient 访问 SSE 服务**

```
public class SSEClient {
    public static void main(final String[] args) {
        final WebClient client = WebClient.create();
        client.get()
                .uri("http://localhost:8080/sse/randomNumbers")
                .accept(MediaType.TEXT_EVENT_STREAM)
                .exchange()
                .flatMapMany(response -> response.body(BodyExtractors.toFlux(new ParameterizedTypeReference<ServerSentEvent<String>>() {
                })))
                .filter(sse -> Objects.nonNull(sse.data()))
                .map(ServerSentEvent::data)
                .buffer(10)
                .doOnNext(System.out::println)
                .blockFirst();
    }
}
```



### WebSocket

访问 WebSocket 不能使用 `WebClient`，而应该使用**专门**的 `WebSocketClient` 客户端。Spring Boot 的 WebFlux 模板中默认使用的是 `Reactor Netty` 库。`Reactor Netty` 库提供了 `WebSocketClient` 的实现。在代码清单 12 中，我们访问的是上面小节中创建的 WebSocket 服务。`WebSocketClient` 的 `execute` 方法与 WebSocket 服务器建立连接，并执行给定的 `WebSocketHandler` 对象。该 `WebSocketHandler` 对象与代码清单 6 中的作用是一样的，只不过它是工**作于客户端**，而不是服务器端。在 `WebSocketHandler` 的实现中，首先通过 `WebSocketSession` 的 `send` 方法来发送字符串 `Hello` 到服务器端，然后通过 `receive` 方法来等待服务器端的响应并输出。方法 `take(1)`的作用是表明客户端只获取服务器端发送的第一条消息。

**清单 12. 使用 WebSocketClient 访问 WebSocket**

```
public class WSClient {
    public static void main(final String[] args) {
        final WebSocketClient client = new ReactorNettyWebSocketClient();
        client.execute(URI.create("ws://localhost:8080/echo"), session ->
                session.send(Flux.just(session.textMessage("Hello")))
                        .thenMany(session.receive().take(1).map(WebSocketMessage::getPayloadAsText))
                        .doOnNext(System.out::println)
                        .then())
                .block(Duration.ofMillis(5000));
    }
}
```

## 测试

在 `spring-test` 模块中也添加了对 WebFlux 的支持。通过类 `org.springframework.test.web.reactive.server.WebTestClient` 可以测试 WebFlux 服务器。进行测试时既可以通过 `mock` 的方式来进行，也可以对实际运行的服务器进行集成测试。代码清单 13 通过一个集成测试来测试 `UserController` 中的创建用户的功能。方法 `WebTestClient.bindToServer` 绑定到一个运行的服务器并设置了基础 URL。发送 HTTP 请求的方式与代码清单 10 相同，不同的是 `exchange` 方法的返回值是 `ResponseSpec` 对象，其中包含了 `expectStatus` 和 `expectBody` 等方法来**验证** `HTTP` 响应的状态码和内容。方法 `jsonPath` 可以根据 JSON 对象中的路径来进行验证。

**清单 13. 测试 UserController**

```
public class UserControllerTest {
    private final WebTestClient client = WebTestClient.bindToServer().baseUrl("http://localhost:8080").build();
 
    @Test
    public void testCreateUser() throws Exception {
        final User user = new User();
        user.setName("Test");
        user.setEmail("test@example.org");
        client.post().uri("/user")
                .contentType(MediaType.APPLICATION_JSON)
                .body(Mono.just(user), User.class)
                .exchange()
                .expectStatus().isOk()
                .expectBody().jsonPath("name").isEqualTo("Test");
    }
}
```



## 小结

反应式编程范式为开发高性能 Web 应用带来了新的机会和挑战。Spring 5 中的 WebFlux 模块可以作为开发反应式 Web 应用的基础。由于 Spring 框架的流行，WebFlux 会成为开发 Web 应用的重要趋势之一。本文对 Spring 5 中的 WebFlux 模块进行了详细的介绍，包括如何用 WebFlux 开发 HTTP、SSE 和 WebSocket 服务器端应用，以及作为客户端来访问 HTTP、SSE 和 WebSocket 服务。对于 WebFlux 的基于 Java 注解和函数式编程等两种模型都进行了介绍。最后介绍了如何测试 WebFlux 应用。

# End

> 原文链接: 
>
> ***[https://www.ibm.com/developerworks/cn/java/spring5-webflux-reactive/index.html](https://www.ibm.com/developerworks/cn/java/spring5-webflux-reactive/index.html)***
>
> ***[https://www.ibm.com/developerworks/cn/java/j-whats-new-in-spring-framework-5-theedom/index.html](https://www.ibm.com/developerworks/cn/java/j-whats-new-in-spring-framework-5-theedom/index.html)***