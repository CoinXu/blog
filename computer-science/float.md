# 浮点数

## 存储格式
根据[IEEE 754](https://web.archive.org/web/20070505021348/http://babbage.cs.qc.edu/courses/cs341/IEEE-754references.html)标准中
__Storage Layout and Ranges of Floating-Point Numbers__ 章节的定义，浮点数由
`符号位(Sign)`、`指数(Exponent)`与`尾数(Mantissa)`三个部份组成。

从精度上可分为单精度(Single Precision)与双精度(Double Precision)，分别占用32bit、64bit存储空间。

Single Precision
```
Sign  Exponent  Mantissa
 -    --------  ----------------------
 31   30~23     22~0
 1bit 8bit      23bit
```
Double Precision
```
Sign  Exponent     Mantissa
 -    -----------  ---------------------------------------------------
 63   62-52        51~0
 1bit 11bit        52bit
```
