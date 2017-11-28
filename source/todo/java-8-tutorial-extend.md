# Java8扩展
# Lambda表达式遇上检测型异常

先来看一段代码：

```
long count = Files.walk(Paths.get("/home/test"))                      // 获得项目目录下的所有目录及文件
                .filter(file -> !Files.isDirectory(file))          // 筛选出文件
                .filter(file -> file.toString().endsWith(".java")) // 筛选出 java 文件
                .flatMap(file -> Files.lines(file))                // 按行获得文件中的文本
                .filter(line -> !line.trim().isEmpty())            // 过滤掉空行
                .count();

System.out.println("代码行数：" + count);
```

> - `Files.walk(Path)` 在 JDK1.8 时添加，深度优先遍历一个 `Path` （目录），返回这个目录下所有的 `Path`（目录和文件），通过 `Stream<Path>` 返回；
> - `Files.lines(Path)` 也是在 JDK1.8 时添加，功能是返回指定 `Path` （文件）中所有的行，通过 `Stream<String>` 返回。

然后，编译不过 —— 因为 `Files.lines(Path)` 会抛出 `IOException`，如果要编译通过，得这样写：

```
long count = Files.walk(Paths.get("D:/Test"))                      // 获得项目目录下的所有文件
                .filter(file -> !Files.isDirectory(file))          // 筛选出文件
                .filter(file -> file.toString().endsWith(".java")) // 筛选出 java 文件
                .flatMap(file -> {
                    try {
                        return Files.lines(file);
                    } catch (IOException ex) {
                        ex.printStackTrace(System.err);
                        return Stream.empty();                     // 抛出异常时返回一个空的 Stream
                    }
                })                                                 // 按行获得文件中的文本
                .filter(line -> !line.trim().isEmpty())            // 过滤掉空行
                .count();

System.out.println("代码行数：" + count);
```

对于有强迫症的程序员来说这简直是噩梦，*`one-liner expression`* 的 Lambda需要绝对的简介明了。

这里有两种做法，比较偷懒的就是每个会抛出异常的地方我们独自捕获处理，这样带来的问题就是不够通用，每个异常方法都要捕获一次：

```
public static void main(String[] args) throws Exception {
    long count = Files.walk(Paths.get("D:/Test"))                       // 获得项目目录下的所有文件
                    .filter(file -> !Files.isDirectory(file))           // 筛选出文件
                    .filter(file -> file.toString().endsWith(".java"))  // 筛选出 java 文件
                    .flatMap(file -> getLines(file))                    // 按行获得文件中的文本
                    .filter(line -> !line.trim().isEmpty())             // 过滤掉空行
                    .count();

    System.out.println("代码行数：" + count);
}

private static Stream<String> getLines(Path file) {
    try {
        return Files.lines(file);
    } catch (IOException ex) {
        ex.printStackTrace(System.err);
        return Stream.empty();
    }
}
```

这种解决方法下，我们需要处理受检异常 —— 即在程序抛出异常的时候，我们需要告诉程序怎么去做（`getLines` 方法中抛出异常时我们输出了异常，并返回一个空的 `Stream`）

上面方式当然是不可取的啦，我们选择更偷懒的方式，**将会抛出异常的函数进行包装，使其不抛出受检异常**。

如果一个 *`FunctionInterface`* 的方法会抛出受检异常（比如 `Exception`），那么该 *`FunctionInterface`* 便可以作为会抛出受检异常的 Lambda 的目标类型。
我们定义如下一个 *`FunctionInterface`*：

```
@FunctionalInterface
	public interface UncheckedFunction<T, R> {
		R apply(T t) throws Exception;
	}
```

那么该 *`FunctionInterface`* 便可以作为类似于 `file -> File.lines(file)` 这类会抛出受检异常的 Lambda 的目标类型，此时 Lambda 中并不需要捕获异常（因为目标类型的 `apply` 方法已经将异常抛出了）—— 之所以原来的 Lambda 需要捕获异常，就是因为在流式操作 `flatMap` 中使用的 `java.util.function` 包下的 `Function<T, R>` 没有抛出异常：

![](http://ojoba1c98.bkt.clouddn.com/img/java-8-tutorial-extend/java-8-function.png)

那我们如何使用 `UncheckedFunction` 到流式操作的 Lambda 中呢？
首先我们定义一个 `Trier` 类，它的 `tryFunction` 方法提供将 `UncheckedFunction` 包装为 `Function` 的功能：

```
public class Trier {
   private static final Logger LOGGER = LoggerFactory.getLogger(Trier.class);

   public static <T, R> Function<T, R> tryFunction(UncheckedFunction<T, R> function) {
      requireNonNull(function);
      return t -> {
         try {
            return function.apply(t);
         } catch (Exception e) {
            throw logAndThrow(e);
         }
      };
   }
   
    @FunctionalInterface
    public static interface UncheckedFunction<T, R> {

        R apply(T t) throws Exception;
    }
}
```

然后在原先的代码中，我们使用 `Trier.tryFunction` 方法来对会抛出受检异常的 Lambda 进行包装：

```
long count = Files.walk(Paths.get("D:/Test"))              // 获得项目目录下的所有文件
                .filter(file -> !Files.isDirectory(file))          // 筛选出文件
                .filter(file -> file.toString().endsWith(".java")) // 筛选出 java 文件
        
                .flatMap(Trier.tryFunction(file -> Files.lines(file)))        // 将 会抛出受检异常的 Lambda 包装为 抛出非受检异常的 Lambda
        
                .filter(line -> !line.trim().isEmpty())            // 过滤掉空行
                .count();

System.out.println("代码行数：" + count);
```

指定默认值的包装方法，即如果抛出异常，那么就返回默认值：

```
public static <T, R> Function<T, R> tryFunction(UncheckedFunction<T, R> function, R defaultValue) {
		requireNonNull(function);
		return t -> {
			try {
				return function.apply(t);
			} catch (Exception e) {
				return logAndReturn(e, defaultValue);
			}
		};
	}
	
private static <R> R logAndReturn(Exception e, R defaultValue) {
		LOGGER.error("Trier catch an exception: " + getFullStackTrace(e) + "\n And return default value: " + defaultValue);
		return defaultValue;
	}
```

比如我们前面的例子，如果 `file -> Files.lines(file)` 抛出异常了，说明在访问 *file* 类的时候出了问题，我们可以就假设这个文件的行数为 0 ，那么默认值就是个空的 `Stream<String>`：

```
long count = Files.walk(Paths.get("D:/Test"))              // 获得项目目录下的所有文件
                .filter(file -> !Files.isDirectory(file))          // 筛选出文件
                .filter(file -> file.toString().endsWith(".java")) // 筛选出 java 文件
        
                .flatMap(Trier.tryFunction(file -> Files.lines(file), Stream.empty()))
        
                .filter(line -> !line.trim().isEmpty())            // 过滤掉空行
                .count();

System.out.println("代码行数：" + count);

```

如此类推，我们可以创建`UncheckedConsumer`、`UncheckedSupplier`等：

```
public class Trier {
	private static final Logger LOGGER = LoggerFactory.getLogger(Trier.class);

	public static <T, R> Function<T, R> tryFunction(UncheckedFunction<T, R> function) {
		requireNonNull(function);
		return t -> {
			try {
				return function.apply(t);
			} catch (Exception e) {
				throw logAndThrow(e);
			}
		};
	}

	public static <T, R> Function<T, R> tryFunction(UncheckedFunction<T, R> function, R defaultValue) {
		requireNonNull(function);
		return t -> {
			try {
				return function.apply(t);
			} catch (Exception e) {
				return logAndReturn(e, defaultValue);
			}
		};
	}

	public static <T> Supplier<T> trySupplier(UncheckedSupplier<T> supplier) {
		requireNonNull(supplier);
		return () -> {
			try {
				return supplier.get();
			} catch (Exception e) {
				throw logAndThrow(e);
			}
		};
	}

	public static <T> Supplier<T> trySupplier(UncheckedSupplier<T> supplier, T defaultValue) {
		requireNonNull(supplier);
		return () -> {
			try {
				return supplier.get();
			} catch (Exception e) {
				return logAndReturn(e, defaultValue);
			}
		};
	}

	public static <T> Consumer<T> tryConsumer(UncheckedConsumer<T> consumer) {
		requireNonNull(consumer);
		return t -> {
			try {
				consumer.accept(t);
			} catch (Exception e) {
				throw logAndThrow(e);
			}
		};
	}

	public static <T> Predicate<T> tryPredicate(UncheckedPredicate<T> predicate) {
		requireNonNull(predicate);
		return t -> {
			try {
				return predicate.test(t);
			} catch (Exception e) {
				throw logAndThrow(e);
			}
		};
	}

	public static <T> Predicate<T> tryPredicate(UncheckedPredicate<T> predicate, boolean defaultValue) {
		requireNonNull(predicate);
		return t -> {
			try {
				return predicate.test(t);
			} catch (Exception e) {
				return logAndReturn(e, defaultValue);
			}
		};
	}

	private static void log(Exception e) {
		LOGGER.error("Trier catch an exception: " + getFullStackTrace(e));
	}

	private static <R> R logAndReturn(Exception e, R defaultValue) {
		LOGGER.error("Trier catch an exception: " + getFullStackTrace(e) + "\n And return default value: " + defaultValue);
		return defaultValue;
	}

	private static RuntimeException logAndThrow(Exception e) {
		log(e);
		throw new RuntimeException(e);
	}

	@FunctionalInterface
	public interface UncheckedFunction<T, R> {
		R apply(T t) throws Exception;
	}

	@FunctionalInterface
	public interface UncheckedSupplier<T> {
		T get() throws Exception;
	}

	@FunctionalInterface
	public interface UncheckedConsumer<T> {
		void accept(T t) throws Exception;
	}

	@FunctionalInterface
	public interface UncheckedPredicate<T> {
		boolean test(T t) throws Exception;
	}

}
```

# Java8 对字符串连接的改进

有时候，我们会有一种需求就是将若干个字符串用某个**链接符**衔接起来，例如有一个 List<String>，将其格式化为 元素1, 元素2, 元素3, ... 元素N 的字符串形式。

以前我们的一般做法就是使用`StringBuilder`：

```
public static String formatList(List<String> list, String delimiter) {
    StringBuilder result = new StringBuilder();
    for (String str : list) {
        result.append(str).append(delimiter);
    }
    // 删除末尾多余的 delimiter
    result.delete(result.length() - delimiter.length(), result.length()); 
    
    return result.toString();
}

public static void main(String[] args) throws Exception {
    List<String> list = Arrays.asList("a", "b", "c", "d", "e", "f", "g");

    System.out.println("使用 StringBuilder：");
    String format = formatList(list, ",");
    System.out.println(format);
}
```

运行结果：

```
使用 StringBuilder：
a,b,c,d,e,f,g
```

JDK1.8 时，添加了一个新的用于字符串连接的类，专门用于这种需要 **分隔符** 的场合，它就是 `StringJoiner`。`StringJoiner` 在构造时可以指定一个分隔符（*`delimiter`*），然后每连接一个元素它便会加上一个 *`delimiter`*，使用 `StringJoiner` 改写 `formatList`：

```
public static String formatList(List<String> list, String delimiter) {
    StringJoiner result = new StringJoiner(delimiter);
    for (String str : list) {
        result.add(str);
    }
    return result.toString();
}

public static void main(String[] args) throws Exception {
    List<String> list = Arrays.asList("a", "b", "c", "d", "e", "f", "g");

    System.out.println("使用 StringJoiner：");
    String format = formatList(list, ",");
    System.out.println(format);
}
```

结果与上面一样。

或者使用`String.join`:

```
public static String formatList(List<String> list, String delimiter) {
    return String.join(delimiter, list);
}
```

它的底层也是调用`StringJoiner`：

![](http://ojoba1c98.bkt.clouddn.com/img/java-8-tutorial-extend/string-join.png)

但是我们看到了 `String.join` 方法的不足 —— 它不能指定前缀和后缀 —— 比如我们如果想要直接将 `List<String>` 格式化为 **{ 元素1, 元素2, 元素3, ... 元素N }** 呢？（此时前缀为 `"{ "`，后缀为 `" }"`）

查看 `StringJoiner` 的构造方法，发现 `StringJoiner` 除了指定 分隔符 的构造方法，还有一个可以指定 分隔符、前缀和后缀 的构造方法：

![](http://ojoba1c98.bkt.clouddn.com/img/java-8-tutorial-extend/stringjoiner.png)

修改 `formatList`：

```
public static String formatList(
        List<String> list, String delimiter, String prefix, String suffix) {

    StringJoiner result = new StringJoiner(delimiter, prefix, suffix);
    for (String str : list) {
        result.add(str);
    }
    return result.toString();
}

public static void main(String[] args) throws Exception {
    List<String> list = Arrays.asList("a", "b", "c", "d", "e", "f", "g");

    System.out.println("使用 StringJoiner，带前缀和后缀：");
    String format = formatList(list, ", ", "{ ", " }");
    System.out.println(format);
}
```

运行结果：

```
使用 StringJoiner，带前缀和后缀：
{ a, b, c, d, e, f, g }
```

事实上，Java8 对于字符串集合的连接操作提供了一个专门的流式 API，即 `Collectors.joining` 函数：
![img](http://ojoba1c98.bkt.clouddn.com/img/java-8-tutorial-extend/collectors-joining.png)

- 无参的 `joining()` 方法，即不存在连接符（底层实现为 `StringBuilder`）；
- `joining(CharSequence delimiter)` 方法，即分隔符为 *delimiter*（底层实现为 `StringJoiner`）；
- `joining(CharSequence delimiter, CharSequence prefix, CharSequence suffix)`方法，即分隔符为 *delimiter*，前缀为 *prefix*，后缀为 *suffix*（底层实现为 `StringJoiner`）。

那怎么使用呢？ 我们直接使用三个参数的 `Collectors.joining` 方法改写 `formatList`：

```
public static String formatList(
        List<String> list, String delimiter, String prefix, String suffix) {

    return list.stream().collect(Collectors.joining(delimiter, prefix, suffix));
}

public static void main(String[] args) throws Exception {
    List<String> list = Arrays.asList("a", "b", "c", "d", "e", "f", "g");

    System.out.println("使用 Collectors.joining：");
    String format = formatList(list, ", ", "{ ", " }");
    System.out.println(format);
}
```

运行结果同上。

# Java8 中 Map 接口的新方法

假如现在我们存在这样的需求：给定一个 `List<String>`，统计每个元素出现的所有位置。

比如，给定 *list*：`["a", "b", "b", "c", "c", "c", "d", "d", "d", "f", "f", "g"]` ，那么应该返回：

```
a : [0]
b : [1, 2]
c : [3, 4, 5]
d : [6, 7, 8]
f : [9, 10]
g : [11]
```

很明显，我们很适合使用 Map 来完成这件事情：

```
public static Map<String, List<Integer>> getElementPositions(List<String> list) {
    Map<String, List<Integer>> positionsMap = new HashMap<>();

    for (int i = 0; i < list.size(); i++) {
        String str = list.get(i);
        List<Integer> positions = positionsMap.get(str);

        if (positions == null) { // 如果 positionsMap 还不存在 str 这个键及其对应的 List<Integer>
            positions = new ArrayList<>(1);
            positionsMap.put(str, positions); // 将 str 及其对应的 positions 放入 positionsMap
        }

        positions.add(i); // 将索引加入 str 相关联的 List<Integer> 中
    }

    return positionsMap;
}

public static void main(String[] args) throws Exception {
    List<String> list = Arrays.asList("a", "b", "b", "c", "c", "c", "d", "d", "d", "f", "f", "g");

    System.out.println("使用 Java8 之前的 API：");
    Map<String, List<Integer>> elementPositions = getElementPositions(list);
    System.out.println(elementPositions);
}
```

运行结果：

```
使用 Java8 之前的 API：
{a=[0], b=[1, 2], c=[3, 4, 5], d=[6, 7, 8], f=[9, 10], g=[11]}
```

























