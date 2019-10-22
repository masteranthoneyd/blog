# 各种好用的工具类库

# Hutool

文档: ***[https://hutool.cn/docs/#/](https://hutool.cn/docs/#/)***

`StrUtil`, `CollUtil` 等各种日常工具.

# Mapstruct

这是一个实体转换工具.

官网: ***[https://mapstruct.org](https://mapstruct.org/)***

# Guava-Retry

重试通用组件.

Github: ***[https://github.com/rholder/guava-retrying](https://github.com/rholder/guava-retrying)***

使用: ***[Guava-Retry实践](https://blog.csdn.net/songhaifengshuaige/article/details/79440285)***

# EasyExcel

***[https://github.com/alibaba/easyexcel](https://github.com/alibaba/easyexcel)***

## 注解

* `@ExcelProperty`: 指定当前字段对应excel中的那一列, 也可以不写, 默认第一个字段就是index=0，以此类推.
  * `value`: 指定的 header 名称.
  * `index`: 指定列下标.
  * `converter`: 自定义转换器
* `@ExcelIgnore`: 默认所有字段都会和excel去匹配，加了这个注解会忽略该字段.
* `@DateTimeFormat`: 指定日期格式.
* `@NumberFormat`: 指定数字格式.
* `@ColumnWidth`: 列宽.
* `@ContentRowHeight`: 行高.
* `@HeadRowHeight`: 头部高.

## 参数

### 读取

#### 通用参数

`ReadWorkbook`,`ReadSheet` 都会有的参数，如果为空，默认使用上级。

- `converter` 转换器，默认加载了很多转换器。也可以自定义。
- `readListener` 监听器，在读取数据的过程中会不断的调用监听器。
- `headRowNumber` 需要读的表格有几行头数据。默认为1，也就是认为第二行开始起为数据。
- `head` 与`clazz`二选一。读取文件头对应的列表，会根据列表匹配数据，建议使用class。如果两个都不指定，则会读取全部数据。
- `autoTrim` 字符串、表头等数据自动trim

#### ReadWorkbook（理解成excel对象）参数

- `excelType` 当前excel的类型 默认会自动判断
- `inputStream` 与`file`二选一。如果接收到的是流就只用，不用流建议使用`file`参数。因为使用了`inputStream` easyexcel会帮忙创建临时文件，最终还是`file`
- `autoCloseStream` 自动关闭流。
- `readCache` 默认小于5M用 内存，超过5M会使用 `EhCache`,这里不建议使用这个参数。

#### ReadSheet（就是excel的一个Sheet）参数

- `sheetNo` 需要读取Sheet的编码，建议使用这个来指定读取哪个Sheet
- `sheetName` 根据名字去匹配Sheet,excel 2003不支持根据名字去匹配

### 写出

#### 通用参数

`WriteWorkbook`,`WriteSheet` ,`WriteTable`都会有的参数，如果为空，默认使用上级。

- `converter` 转换器，默认加载了很多转换器。也可以自定义。
- `writeHandler` 写的处理器。可以实现`WorkbookWriteHandler`,`SheetWriteHandler`,`RowWriteHandler`,`CellWriteHandler`，在写入excel的不同阶段会调用
- `relativeHeadRowIndex` 距离多少行后开始。也就是开头空几行
- `needHead` 是否导出头
- `head` 与`clazz`二选一。写入文件的头列表，建议使用class。
- `autoTrim` 字符串、表头等数据自动trim

#### WriteWorkbook（理解成excel对象）参数

- `excelType` 当前excel的类型 默认`xlsx`
- `outputStream` 与`file`二选一。
- `templateInputStream` 模板的文件流
- `templateFile` 模板文件
- `autoCloseStream` 自动关闭流。

#### WriteSheet（就是excel的一个Sheet）参数

- `sheetNo` 需要写入的编码。默认0
- `sheetName` 需要些的Sheet名称，默认同`sheetNo`

#### WriteTable（就把excel的一个Sheet,一块区域看一个table）参数

- `tableNo` 需要写入的编码。默认0

## 用法

更多用法请查看官方demo: ***[https://github.com/alibaba/easyexcel/tree/master/src/test/java/com/alibaba/easyexcel/test/demo](https://github.com/alibaba/easyexcel/tree/master/src/test/java/com/alibaba/easyexcel/test/demo)***

### 读取

只有一个 sheet:

```java
String fileName = TestFileUtil.getPath() + "demo" + File.separator + "demo.xlsx";
// 这里 需要指定读用哪个class去读，然后读取第一个sheet 文件流会自动关闭
EasyExcel.read(fileName, DemoData.class, new DemoDataListener()).sheet().doRead();

// 或者
EasyExcel.read()
         .file(fileName).head(DemoData.class).registerReadListener(new DemoDataListener())
         .sheet()
         .doRead();
```

> 这种写法会**自动关闭流**

**读取多个** sheet 或者指定的 sheet:

```java
ExcelReader excelReader = EasyExcel.read(fileName, DemoData.class, new DemoDataListener()).build();
ReadSheet readSheet = EasyExcel.readSheet(0).build();
excelReader.read(readSheet);
// 这里千万别忘记关闭，读的时候会创建临时文件，到时磁盘会崩的
excelReader.finish();

// 如果不知道有几个sheet,可以这样写
ExcelReader excelReader = EasyExcel.read(file, MultipleSheetsData.class, multipleSheetsListener).build();
List<ReadSheet> sheets = excelReader.excelExecutor().sheetList();
int count = 1;
for (ReadSheet readSheet : sheets) {
    excelReader.read(readSheet);
    Assert.assertEquals((long)multipleSheetsListener.getList().size(), (long)count);
    count++;
}
excelReader.finish();

// 如果多个sheet的数据结构不一样, 需要给sheet分别配置ReadListener
excelReader = EasyExcel.read(fileName).build();
readSheet1 = EasyExcel.readSheet(0).head(DemoData.class).registerReadListener(new DemoDataListener()).build();
readSheet2 = EasyExcel.readSheet(1).head(DemoData.class).registerReadListener(new DemoDataListener()).build();
excelReader.read(readSheet1);
excelReader.read(readSheet2);
excelReader.finish();
```

**注意**: 

* 读多个sheet,这里注意一个sheet不能读取多次，多次读取需要重新读取文件.
* 直接调用 `ExcelReader.read` 后需要显式调用 `ExcelReader.finish` 关闭流.

读取header:

```java
EasyExcel.read(fileName, DemoData.class, new DemoDataListener()).sheet()
    // 这里可以设置1，因为头就是一行。如果多行头，可以设置其他值。不传入也可以，因为默认会根据DemoData 来解析，他没有指定头，也就是默认1行
    .headRowNumber(1).doRead();
```

获取header, 只需要重写 `AnalysisEventListener.invokeHeadMap` 方法:

```java
@Override
public void invokeHeadMap(Map<Integer, String> headMap, AnalysisContext context) {
    LOGGER.info("解析到一条头数据:{}", JSON.toJSONString(headMap));
}
```

异常处理, 重写 `AnalysisEventListener.onException`:

```java
@Override
public void onException(Exception exception, AnalysisContext context) {
    LOGGER.error("解析失败，但是继续解析下一行", exception);
}
```

### 写出

实体:

```java
@Data
public class DemoData {

    @ExcelProperty("字符串标题")
    private String string;

    @ColumnWidth(50)
    @DateTimeFormat("yyyy年MM月dd日HH时mm分ss秒")
    @ExcelProperty("日期标题")
    private Date date;

    @NumberFormat("#.##%")
    @ExcelProperty("数字标题")
    private Double doubleData;

}
```

```java
// 写法1
String fileName = TestFileUtil.getPath() + "simpleWrite" + System.currentTimeMillis() + ".xlsx";
EasyExcel.write(fileName, DemoData.class).sheet("模板").doWrite(data());

// 写法2
fileName = TestFileUtil.getPath() + "simpleWrite" + System.currentTimeMillis() + ".xlsx";
ExcelWriter excelWriter = EasyExcel.write(fileName, DemoData.class).build();
WriteSheet writeSheet = EasyExcel.writerSheet("模板").build();
excelWriter.write(data(), writeSheet);
excelWriter.finish();

// 写法3, 分批写入同一个sheet
String fileName = TestFileUtil.getPath() + "repeatedWrite" + System.currentTimeMillis() + ".xlsx";
ExcelWriter excelWriter = EasyExcel.write(fileName, DemoData.class).build();
WriteSheet writeSheet = EasyExcel.writerSheet("模板").build();
for (int i = 0; i < 5; i++) {
    List<DemoData> data = data();
    excelWriter.write(data, writeSheet);
}
excelWriter.finish();
```

设置样式, 全部居中:

```java
String fileName = TestFileUtil.getPath() + "styleWrite" + System.currentTimeMillis() + ".xlsx";
// 头的策略
WriteCellStyle headWriteCellStyle = new WriteCellStyle();
headWriteCellStyle.setFillForegroundColor(IndexedColors.RED.getIndex());
WriteFont headWriteFont = new WriteFont();
headWriteFont.setFontHeightInPoints((short)20);
headWriteCellStyle.setWriteFont(headWriteFont);

// 内容的策略
WriteCellStyle contentWriteCellStyle = new WriteCellStyle();
// 这里需要指定 FillPatternType 为FillPatternType.SOLID_FOREGROUND 不然无法显示背景颜色.头默认了 FillPatternType所以可以不指定
contentWriteCellStyle.setFillPatternType(FillPatternType.SOLID_FOREGROUND);
contentWriteCellStyle.setFillForegroundColor(IndexedColors.GREEN.getIndex());
WriteFont contentWriteFont = new WriteFont();
contentWriteFont.setFontHeightInPoints((short)20);
contentWriteCellStyle.setWriteFont(contentWriteFont);
contentWriteCellStyle.setHorizontalAlignment(HorizontalAlignment.CENTER); // 居中
// 这个策略是 头是头的样式 内容是内容的样式 其他的策略可以自己实现
HorizontalCellStyleStrategy horizontalCellStyleStrategy =
    new HorizontalCellStyleStrategy(headWriteCellStyle, contentWriteCellStyle);

EasyExcel.write(fileName, DemoData.class)
         .registerWriteHandler(horizontalCellStyleStrategy)
         .sheet("模板")
         .doWrite(data());
```

合并单元格:

```java
String fileName = TestFileUtil.getPath() + "mergeWrite" + System.currentTimeMillis() + ".xlsx";
// 每隔2行会合并 把eachColumn 设置成 3 也就是我们数据的长度，所以就第一列会合并。当然其他合并策略也可以自己写
LoopMergeStrategy loopMergeStrategy = new LoopMergeStrategy(2, 0);
// 这里 需要指定写用哪个class去读，然后写到第一个sheet，名字为模板 然后文件流会自动关闭
EasyExcel.write(fileName, DemoData.class).registerWriteHandler(loopMergeStrategy).sheet("模板").doWrite(data());
```

