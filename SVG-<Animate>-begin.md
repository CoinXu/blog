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

# Clock-value
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
+ 语法: ("+"|"-")? Clock-value
```XML
<rect id="a" x="0" y="10" width="0" height="20">
    <animate attributeType="XML" attributeName="width"
             from="0" to="100" dur="4s"
             begin="2s"/>
</rect>
<rect id="b" x="10" y="40" width="0" height="20">
    <animate attributeType="XML" attributeName="width"
             from="0" to="100" dur="4s" fill="freeze"
             begin="-2s"/>
</rect>
```
规范中没有说明 `document begin` 是个什么点,我暂时理解为 `DOMContentLoaded`。
`a` 中在 `DOMContentLoaded` 1s后开始,执行1s,也就是说在 `DOMContentLoaded` 后2s执行完成。
`b` 的 `begin="-2s"`, 表示偏移 `DOMContentLoaded` 时间前2s,那么,总共执行4s,同样是在
`DOMContentLoaded` 后2s执行完成。
