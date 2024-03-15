# 如何提升移动端的开发效率

## 影响前端开发效率因素
+ 开发环境越来越复杂
+ UI/UE规范不统一
+ 重复实现
+ 联调接口极其耗时
+ 移动端开发时debug难度增加

## 搭建开发环境
一个完整的前端开发环境包括目录管理、种子文件、依赖库、测试环境、编译环境、接口服务、构建工具等。
其中较复杂的部包括编译环境、测试环境、打包工具。这三个部分的依赖库少则十来个，多则数十个。
配置代码少则数百行，多则数千行，在不同系统、版本下的兼容问题比比皆是。

一个较为完整的前端开发环境包含文件如下：
```
├── dist
│   ├── prod
│   └── test
├── public
│   ├── favicon.ico
│   └── index.html
├── src
│   ├── App.js
│   ├── assets
│   ├── common
│   ├── components
│   ├── models
│   ├── plugins
│   ├── store
│   └── views
├── test
├── .browserslistrc
├── .editorconfig
├── .env.development
├── .env.mock
├── .env.production
├── .env.testing
├── .gitignore
├── .prettierignore
├── .prettierrc
├── babel.config.js
├── package.json
├── postcss.config.js
├── README.md
└── vue.config.js
```
如果需要一步步搭建这样一样开发环境，少则半天，多则数天。即使之前已经搭建过很多次，依然会出现各种始料未及的问题。
如果全部手写配置及测试通过，耗时大约0.5~3天。

在生态日益完整的的今天，前端开发终于可以像其他社区一样，可以通过脚本工具来一键构建开发环境。
vue-cli与create-react-app等，都是较为成熟的工具。我们使用社区提供的cli工具来创建前端开发环境，脚本如下：

```bash
vue-cli create ${project_name}
```
基本上一两行shell命令可以完成，耗时在5分钟以内。

如果这些工具不能满足项目的需要，也可以将配置代码稍加改动以适应项目。
至此，前端开发环境基本不用耗费什么时间了，除非使用业内较少使用的技术方案，比如typescript、kotlin等。

## 代码管理
传统的前端开发在html页面中直接引入JavaScript代码：
```html
<!-- app.html -->
<!-- 引入css -->
<link type="text/css" href="//css/a.css" />
<link type="text/css" href="//css/b.css" />

<!-- 引入JavaScript -->
<script type="text/javascript" src="//js/a.js?v=0.0.1"></script>
<script type="text/javascript" src="//js/b.js?v=0.0.1"></script>
<script type="text/javascript" src="//js/c.js?v=0.0.1"></script>
<script type="text/javascript" src="//js/app.js?v=0.0.1"></script>

```
这样的使用方式在大型项目下是一个灾难，大型项目的JavaScript文件、CSS文件、图片、流𩨡媒体成百上千。
仅仅手动管理其依赖关系就一个极其耗时的工作，更不用说控制其版本，改动内容，修复bug等。

我们使用webpack一切皆资源的思想，来管理前端所有需要用到的资源，并使用es6规范定义的module来引用资源。

上面的项目在webpack+es6 module的编译环境下代码如下：
```js
// app.js
import 'css/a.css';
import 'css/b.css';

import { a } from 'js/a.js';
import { b } from 'js/b.js';
import { c } from 'js/c.js';

a();
b();
c();
```
使用webpack将app.js打包、压缩，并将文件内容__hash__作为文件名，以便即时刷新缓存：
```bash
webpack
```

在app.html中引入（这一行代码也是通过构建工具自动插入）
```html
<!-- app.html -->
<script type="text/javascript" src="//js/bundle/app.0f569e27.js"></script>
```

## 建立标准、规范UI/UE库
从开发方式上来说，前端大约经历了如下阶段：
1. 服务端渲染静态页
2. jQuery操作DOM实现动态网页
3. 组件化
4. 数据驱动UI(MVVM)

第1、2点属于刀耕火种的原始开发阶段，不做过多的解读。
当前端进入了组件化开发的阶段化，前端开发才算真正独立于其他编程工种，成为一个新的职能。
组件化开发至少表明了现代前端开发的两个特点：专业化、规范化。
因为复杂的页面才需要组件化开发，而前端的复杂则代表在用户侧，业务重心开始从后端往前端偏移。
又因为复杂，所以需要标准，需要规范。

在现代web应用中，一个界面往往承担数个或十数个操作步骤，如果没有一套规范的UI/UE标准，
无论在开发效率还是在质量保障上，都无法得到有效的控制。

一个极简现代web应用代码大致如下：
```xml
<!-- 伪代码 -->
<header name="example" />
<main>
  <input type="text" label="username" />
  <input type="password" label="password" />
  <button type="submit" on-click={login} />
</main>
<copyright />
```
其中的`header`、`main`、`input`、`button`、`copyright`都可以由UI/UE库或业务组件库提供，一次书写，多处使用，
并且表现与形为均一致。

在现代web应用中，除了操作步骤增加之外，还格外注重用户体验。
除了正常的业务逻辑，更多还需要考虑异常情况，比如提醒、代码或服务出现异常、网络传输缓慢等。
因而界面上会维护很多状态，在这些状态下尽可能提醒用户进行恰当的处理。

仅仅是组件化是难以维护这样复杂的代码，MVVM应运而生，前端由此进入数据驱动UI的时代。
```xml
<main>
  <v-table :data="models" v-loading="loading.table" />
  <v-button disabled="models.length < 1" />
</main>
```

因此，我们基于开源社区代码并结合实际业务，抽离了两个UI库，分别为PC与Mobile前端项目提供完备的UI/UE组件，
界面由一个个封装好的组件拼装起来，开发人员不必关注其内部实现。

其中，移动端UI库包含了布局、常用组件、提醒、选择器、状态、图标等：
```
actionsheet
checklist
index-list
icon
loadmore
popup
search
swipe-item
tab-item
badge
datetime-picker
index-section
message-box
progress
slider
switch
toast
button
datetime-selector
indicator
navbar
radio
slider-item
tabbar
cell
field
infinite-scroll
palette-button
range
spinner
tab-container
cell-swipe
header
lazyload
picker
swipe
tab-container-item
```

一个复杂的日期选择器，只需要下面一行代码即可实现：
```xml
<v-main>
  <v-datetime-picker :active="now()" @change="onTimeChange"/>
</v-main>
```

详见： 
+ Mobile: https://git.yy.com/webs/edu100FE/medu-ui

## 数据类型与结构验证
在前端现有的生态中，各类工具函数库已经较为完善，使用这些工具函数库可以解决大部份重复的代码逻辑。
但不同项目毕竟有不同的需求，不能总是在社区上找到解决方案，就需要根据项目的实际情况与各个前端团队自身的技术储备量身打造。

我们在开发内部系统的时候发现，这类管理系统，总需要用户输入大量的数据。对这类数据的合法性验证，是非常必要的。
但这又是一个非常没有技术含量事情，并且需要占用大量代码。

比如用户登录场景：用户至少需要输入用户名与密码，验证代码就得这样写。
```js
// 验证用户名
function userNameValidator(username) {
  if (!username) {
    return 'username required';
  }
  if (username.length > 32) {
    return 'username length must less than 32';
  }
  if (!/\w/.test(username)) {
    return 'username may be a-z, A-Z, 0-9, or _';
  }
  return null;
}
// 验证密码函数...
```

就前端而言，用户输入数据至少要在两个地方进行验证。
其一是用户输入时，提示用户输入是否正确与错误的原因。
其二是数据上报到服务端时，需要验证。

由于验证的逻辑是可以枚举的，不外乎那几十种，比如字符、数字、长度、范围、布而、非空等。所以我们开发了一个工具库来做这件事情。

还是以用户登录场景而言，使用该工具库代码如下：
```js
import { Reviser, TypeString, Required, MaxLength, Pattern } from 'data-reviser';
// 定义一个model
class SignIn extends Reviser {
  @Pattern(/\w/)
  @MaxLength(32)
  @TypeString()
  @Require('用户名为必填项')  // 自定义异常消息
  username = '';

  password = '';
}
// 使用
const sign = new SignIn();
const message = sign.map({ username: '', password: '' });
// 如果验证失败，message将是一个包含错误信息的map结构
```

验证的字段越多（比如接口返回的model字段），越代码量缩减效果越明显。

详见： https://github.com/CoinXu/data-reviser

## 提升联调效率
传统前后端开发流程：
1. 接到需求
2. 后端定义接口文档
3. 后端开发接口
4. 前端基于后端接口开发
5. 如果接口出错，反馈给后端，等待后端修复后继续开发
6. 前后端都开发完成后进行业务联调

可以看到传统模式下前端的进度严重受限于后端。
在后端接口开发完成之前，前端能做的只有静态页面。
一旦后端接口出问题（开发环境出问题是常事，比如服务挂掉，比如接口修改），前端唯一能做的事情就是等待。

mock服务可以很好的解决这个问题。

接入mock后开发流程如下：
1. 接到需求
2. 后端定义接口文档
3. 前端将接口文档导入mock服务器，生成mock接口
4. 前端基于mock开始开发，后端开始开发
5. 前后端都开发完成后进行业务联调

前端只管维护好自己的mock服务器就好，在接口文档定义完成后，即可与后端并行开发，开发过程中不受后端服务影响。

除此之外，我们将mock服务与后端swagger无缝衔接，后端通过swagger提供的注解快速生成swagger.json。
前端只需将swagger.json导入前端的mock服务器，即可生成mock项目。

详见: http://npm.100.com
hosts: 
```
172.27.192.4  mock.100.com
```

## 移动端debug方案
在pc上开发可以通过调式工具打断点、查错误堆栈、审查页面状态、页面元素变化，可以很快速的定位问题。

但是在移动端（包括h5、微信、app内嵌web页）上的项目则不能，移动端对一个开发人员更像是一个黑盒，只能看见异常，却不知道具体的异常原因。

在目前的条件（时间与技术储备）下，我们使用实时日志的方式解决这个问题。
在开发、测试环境下，通过对关键步骤输出日志、全局错误捕获并上报到实时日志服务器的方式定位问题。

代码如下：
```js
import { Logger } from 'data-logger';
Logger.create('ui').trace('hello world');
```

在pc上打开`http://logservertest.100.com/real-time?namespace={namespace}`可以立马看到如下日志：
```
[2018-09-29 14:23:35][2018-09-29 14:23:34]: hello world
```

其格式为：
```
[server time][client time][level]: {message}
```
详见： https://git.yy.com/webs/edu100FE/log-server

## 生产环境错误快速定位
对于直接面向用户的web应用，用户环境不受开发人员控制，受限于条件，不可能将每个用户可能的环境全部测试一遍。
此时，我们能做的是在用户出现问题的时候，即时定位到问题所在，快速发布新版本修复问题。

对于这一点，目前我们使用上报客户端日志到日志服务器的方式来定位问题。
当用户反应出错的时候（由于数据服务器还在建设中，主动告警的方案目前还不能实现），我们可以通过客户端日志快速定位bug，并即时修复。

目前只是将关键步骤的日志与JavaScript执行错误上报到服务器，计划中还有很多事情要做，比如通过sourcemap定位到原始文件中的具体某行、
收集到一些数据后针对特定的客户端主动引入补丁代码等。

## web应用监控
除此之外，不同用户的客户端性能不同，有的用户用的是当年最新旗舰机型，有的用户用的是数年前的老型号，
为了尽可能的为不同客户端提供访问能力、持续优化项目性能、兼容性、用户体验等，web应用需要对不同的客户端的运行情况进行监控。

我们通过收集页面性能指标、异常事件数据、全埋点等数据来分析代码质量与用户习惯。

## 性能指标
+ 首屏渲染耗时： 首屏内容渲染结束时间点 - 开始请求时间点。
+ 白屏时长： 页面开始展示的时间点 - 开始请求时间点 。
+ 可交互时间： 用户可以正常进行事件输入时间点 - 开始请求时间点。
+ 页面加载完成耗时。
+ DNS解析耗时。
+ 资源加载耗时。
+ 接口请求耗时。
+ 开页面加载时网速。
+ 渲染帧率。

## 异常事件
+ 卡顿事件。
+ JavaScript执行错误事件，收集错误现场（全埋点实现）。
+ 页面崩溃

该项目正在开发中，预计在2018年11月前实现部分功能，接入到生产环境。

详见： https://git.yy.com/webs/edu100FE/supervisor

## 版本控制



