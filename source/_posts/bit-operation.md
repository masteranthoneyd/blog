---
title: 位运算以及常用场景
date: 2020-01-15 12:02:36
categories: [Programming, Algorithms]
tags: [Java, Algorithms]
---

![](https://cdn.yangbingdong.com/img/bit-operation/bit-operation-banner.jpg)

# Preface

> 位运算以及常用场景(装X)...

<!--more-->

# 符号解释

| 位运算符 | 描述       | 运算规则                                   |
| -------- | ---------- | ------------------------------------------ |
| `<<`     | 左移       | 各二进制全部左移, 高位丢弃, 低位补0        |
| `>>`     | 右移       | 各二进制全部右移, 正数高位补0, 附属高位补1 |
| `>>>`      | 无符号右移 | 各二进制全部右移, 高位补0                  |
|` & `       | 位与       | 两个为1, 结果才为1                         |
| `|`       | 位或       | 两个为0, 结果才为0                         |
| `~`        | 位非       | 1变0, 0变1                                 |
| `^`        | 位异或     | 两个相同为0, 相异为1                       |

# 基础运用

## 获取或修改a的第k位

获取第k位: `a >> k & 1`

将第k位清0: `a = a & ~(1 << k)`

将第k为设置为1: `a = a | (1 << k)`

## 判断第k位是否是1

```
int flag = 1 << k
return (a & flag) == flag
```

或

```
(a >> k & 1) == 1
```

## 乘除运算

`a * (2 ^ n)` 或 `a / (2 ^ n)` 可以使用左移或右移代替.

## 判断奇偶数

偶数的第一位是0, 可是使用 `(a & 1) == 0` 来代替 `a % 2 == 0` 判断是否为偶数.

## 判断a是否2的幂

```
(a != 0) && (a & (a - 1)) == 0
```

## 交换两个数

位异或有下面几个特性:

- `a ^ a = 0`
- `a ^ 0 = a`
- `(a ^ b) ^ c = a ^ (b ^ c)`

a 与 b 交换位置可以这样实现:

```
a ^= b;
b ^= a;
a ^= b;
```

上面三步可以这样理解:

```
a = a ^ b;
b = a ^ b = (a ^ b) ^ b = a ^ (b ^ b) = a ^ 0 = a;
a = a ^ b = (a ^ b) ^ b = (a ^ a) ^ b = b ^ 0 = b;
```

## 求余

`a % (2^n)` 等价于 `a & (2^n - 1)`

## 求相反数

`~a + 1`

## 求平均值

`(x & y) + ((x ^ y) >> 1)`

# 综合运用

## 多状态位

将多个开关合并到一个二进制中, 主要用到上面基础运用中的 **获取或修改a的第k位** 与 **判断第k位是否是1**.

```
int DISPLAY_H5 = 1 << 0;
int DISPLAY_MINI_PROGRAM = 1 << 1;
int DISPLAY_APP = 1 << 2;

int displayAllInOne;

// 生成所有开关二进制
displayAllInOne |= displayH5 ? DISPLAY_H5 : 0;
displayAllInOne |= displayMiniProgram ? DISPLAY_MINI_PROGRAM : 0;
displayAllInOne |= displayApp ? DISPLAY_APP : 0;

// 判断某个端是否展示(其他类似)
(displayAllInOne & DISPLAY_H5) == DISPLAY_H5
```

## 加密

主要运用到位异或的特性:

```
A ^ B = C => C ^ A = B => C ^ B = A 
```

```
String raw = "yangbingdong";
String key = "thisIsPasswo";

char[] xChars = raw.toCharArray();
char[] yChars = key.toCharArray();
char[] encodeChars = new char[yChars.length];
for (int i = 0; i < xChars.length; i++) {
	encodeChars[i] = (char)(xChars[i] ^ yChars[i]);
}

System.out.println(String.copyValueOf(encodeChars));
char[] decodeChars = new char[yChars.length];
for (int i = 0; i < encodeChars.length; i++) {
	decodeChars[i] = (char)(encodeChars[i] ^ yChars[i]);
}
System.out.println(String.copyValueOf(decodeChars));
```

## 高低位交换

34520的二进制表示: `10000110 11011000`.

将其高8位与低8位进行交换, 得到一个新的二进制数: `11011000 10000110`, 其十进制为55430.

假设下面a是16位二进制(实际上int是32位), `a >> 8` 将高8位移动到低8位, 高位补0. 将 `a << 8 & 0xff00` 将a左移8位地位补0并获取前16位: 

```
int a =  34520;
int exchange = (a << 8 & 0xff00) | (a >> 8);
```

## 生成第一个大于a的满足2^n的数

这个场景经典运用是在 `HashMap` 中, 因为 `HashMap` 通过 `key` 计算 `hash` 桶的位置就是用到上面的位移求余, 所以 hash 桶的数量**必须**是 `2^n`.

```java
public static final int tableSizeFor(int cap) {
    int n = cap - 1;
    n |= n >>> 1;
    n |= n >>> 2;
    n |= n >>> 4;
    n |= n >>> 8;
    n |= n >>> 16;
    return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
}
```