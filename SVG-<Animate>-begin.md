## SVG `<animate/>` Begin
`begin`: 定义动画何时激活

### 语法: begin-value(";"begin-value-list)?
```
begin-value-list ::= begin-value (S ";" S begin-value-list )?
begin-value      ::= (offset-value | syncbase-value
                      | event-value
                      | repeat-value | accessKey-value
                      | wallclock-sync-value | "indefinite" )
```

# <span id="clock-value">Clock-value</span>
```
Clock-value         ::= ( Full-clock-value | Partial-clock-value
                       | Timecount-value )
Full-clock-value    ::= Hours ":" Minutes ":" Seconds ("." Fraction)?
Partial-clock-value ::= Minutes ":" Seconds ("." Fraction)?
Timecount-value     ::= Timecount ("." Fraction)? (Metric)?
Metric              ::= "h" | "min" | "s" | "ms"
Hours               ::= DIGIT+; any positive number
Minutes             ::= 2DIGIT; range from 00 to 59
Seconds             ::= 2DIGIT; range from 00 to 59
Fraction            ::= DIGIT+
Timecount           ::= DIGIT+
2DIGIT              ::= DIGIT DIGIT
DIGIT               ::= [0-9]
```

# offset-value
指定动画开始时间与 `document` 开始时(relative to the document begin)的偏移量。
+ 语法: ("+"|"-")? [Clock-value](#clock-value)
```XML
<rect x="0" y="10" width="0" height="20">
    <animate id="a" attributeType="XML" attributeName="width"
             from="0" to="100" dur="4s"
             begin="2s"/>
</rect>
<rect x="10" y="40" width="0" height="20">
    <animate id="b" attributeType="XML" attributeName="width"
             from="0" to="100" dur="4s" fill="freeze"
             begin="-2s"/>
</rect>
```
规范中没有说明 `document begin` 是个什么点,我暂时理解为 `DOMContentLoaded`。

`a` 中在 `DOMContentLoaded` 1s后开始,执行1s,
也就是说在 `DOMContentLoaded` 后2s执行完成。

`b` 的 `begin="-2s"`, 表示偏移 `DOMContentLoaded` 时间前2s,
那么,总共执行4s,同样是在 `DOMContentLoaded` 后2s执行完成。

# syncbase-value
指定动画元素在例一个动画元素的运行过程中某个阶段偏移某个时间后执行。
+ 语法: ( Id-value "." ( "begin" | "end" ) ) ( ( "+" | "-" ) Clock-value )?

```XML
<rect x="10" y="0" width="0" height="30" rx="2" ry="2">
    <animate id="first"
             attributeType="XML"
             attributeName="width"
             from="0" to="100" dur="2s"
             begin="0s;third.end"/>
</rect>
<rect x="10" y="40" width="0" height="30" rx="2" ry="2">
    <animate id="second"
             attributeType="XML"
             attributeName="width"
             from="0" to="100" dur="2s"
             begin="first.end"/>
</rect>
<rect x="10" y="80" width="0" height="30" rx="2" ry="2">
    <animate id="third"
             attributeType="XML"
             attributeName="width"
             from="0" to="100" dur="2s"
             begin="first.end-1s"/>
</rect>
```
由于 `third` 的 `begin` 为 `first.end-1s`, `first` 的 `dur` 为 `2s`。
那么 `third` 会在 `first` 跑了 1s 后开始执行。

`second` 在 `first` 跑完后执行。


