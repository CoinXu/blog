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

## <span id="clock-value">Clock-value</span>
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

## offset-value
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

## syncbase-value
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
那么 `third` 会在 `first` 跑了 1s 后开始执行。`second` 在 `first` 跑完后执行。

## event-value
定义一个事件,用来判定动画元素的开始时间,动画元素在事件触发时开始执行动画。
动画可以是和[DOM2Events](http://www.w3.org/TR/DOM-Level-2-Events/events.html)
一致的事件,也可以是通过网络触发的用户接口事件(user-interface)。
[更多信息](http://www.w3.org/TR/2001/REC-smil-animation-20010904/#Unifying)

+ 语法: ( Id-value "." )? ( event-ref  ) ( ( "+" | "-" ) Clock-value )?
  ```XML
  <rect x="10" y="10" width="0" height="30" rx="2" ry="2">
      <animate id="first"
               attributeType="XML"
               attributeName="width"
               from="0" to="100" dur="2s"
               fill="freeze"
               begin="start_btn.click"/>
  </rect>
  <rect x="10" y="50" width="0" height="30" rx="2" ry="2">
      <animate id="second"
               attributeType="XML"
               attributeName="width"
               from="0" to="100" dur="1s"
               fill="freeze"
               begin="start_btn.click+1s"/>
  </rect>
  <rect id="start_btn" style="cursor:pointer;"
        x="10" y="90" width="100" height="30" rx="2"
        ry="2" fill="#ffffff" stroke="#000000" stroke-width=".5">
  </rect>
  <text text-anchor="middle"
        style="pointer-events:none;"
        x="60" y="105" width="100" heigth="30" dy="4">
      Click Me
  </text>
  ```
当 `start_btn` click事件触发时, first 会立即触发动画, second 在一秒后触发。

## repeat-value
动画元素指定开始时间为另一个动画元素的重复事件(repeat event)上。
当指定元素发生重复事件的迭代次数等于指定次数时触发。

+ 语法 : ( Id-value "." )? "repeat(" integer ")" ( ( "+" | "-" ) Clock-value )?
  ```XML
  <rect x="10" y="10" width="0" height="30" rx="2" ry="2">
      <animate id="loop" begin="0s;loop.end"
               attributeType="XML"
               attributeName="width"
               from="0" to="100" dur="4s"
               repeatCount="3"/>
      <set begin="loop.begin" attributeType="CSS"
           attributeName="fill" to="green"/>
      <set begin="loop.repeat(1)" attributeType="CSS"
           attributeName="fill" to="gold"/>
      <set begin="loop.repeat(2)" attributeType="CSS"
           attributeName="fill" to="red"/>
  </rect>
  ```
+ `loop` 开始时, `rect` 颜色变为 `green`。
+ `loop` 第一次重复时, `rect` 颜色变为 `gold`。
+ `loop` 第二次重复时, `rect` 颜色变为 `red`。

## accessKey-value
当用户某个健按下时,动画开始执行。
+ 语法 : "accessKey(" character ")"
  ```XML
  <rect x="10" y="10" width="0" height="30" rx="2" ry="2">
      <animate id="loop" begin="accessKey(s)"
               attributeType="XML"
               attributeName="width"
               from="0" to="100" dur="4s"
               repeatCount="3"/>
  </rect>
  ```
按下 `s` 键时,动画开始执行。

__注__:目前chrome(52.0.2743.116 (64-bit) mac os)还没有实现该功能。firefox(48.0.1 mac os)可以运行。

## wallclock-sync-value
+ 语法: "wallclock(" wallclock-value ")"

定义一个现实世界的时间,在这个时间后触发动画。
`wallclock-value` 基于 [ISO8601](http://www.w3.org/TR/2001/REC-smil-animation-20010904/#ref-iso8601)
https://en.wikipedia.org/wiki/ISO_8601
  ```XML
  <rect y="10" width="0" height="30" rx="2" ry="2">
      <animate attributeType="XML" attributeName="width"
               from="0" to="100" dur="3s"
               fill="freeze"
               begin="wallclock(2016-09-16)"/>
  </rect>
  ```
__注__:目前(2016-09-16)还没有浏览器实现

## indefinite
如果调用了 `beginElement()` 方法或者一个超链接指向该元素并且该链接被点击时触发动画。
  ```XML
  <rect x="10" y="10" width="10" height="10" rx="2" ry="1">
      <animate id="animate" begin="indefinite"
               attributeType="XML" attributeName="x" from="0" to="100"
               dur="1s" repeatCount="indefinite"/>
  </rect>
  <a href="#animate">
      <rect height="30" width="120" y="40" x="10" rx="15"/>
      <text fill="white" y="60" x="70" text-anchor="middle">Click</text>
  </a>
  ```
点击 `Click`,开始动画。
