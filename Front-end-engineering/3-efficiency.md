# 如何提升前端开发效率

## 影响前端开发效率因素
+ 开发环境搭建
+ 模块与工作流
+ 代码规范与错误检测
+ UI/UE规范不统一
+ 重复实现
+ 联调接口极其耗时
+ 移动端开发时debug难度增加
+ 多个环境下代码打包的问题

# 解决方案

## 使用cli搭建开发环境
一个完整的前端开发环境包括目录管理、种子文件、依赖库、测试环境、编译环境、接口服务、打包工具等。
其中较复杂的部包括编译环境、测试环境、打包工具。这三个部分的依赖库少则十来个，多则数十个。
配置代码少则数百行，多则近千行，在不同版本、系统下的兼容问题比比皆是。如果需要一步步搭建这样一样开发环境，少则半天，多则数天。
即使之前已经搭建过很多次，依然会出现各种始料未及的问题。

书写配置代码一般流程如下：
```
package.json
webpack.config.js
webpack.config.dev.js
webpack.config.production.js
webpack.config.test.js
kamar.config.js
.gitignore
.npmignore
.babelrc
.editorconfig
.eslint
```

在生态日益完整的的今天，前端开发终于可以像其他社区一样，可以通过脚本工具来一键构建开发环境。
vue-cli与create-react-app等，都是较为成熟的工具。
```
vue-cli create ${project_name}
```

如果这些工具不能满足项目的需要，也可以将配置代码稍加改动以适应项目。
至此，前端开发环境基本不用耗费什么时间了，除非使用业内较少使用的技术方案，比如typescript、kolin等。


## 与业务需求结合，建立标准、规范UI/UE库
从开发方式上来说，前端大约经历了如下阶段：
1. 服务端渲染静态页
2. jQuery操作DOM实现动态网页
3. 组件化
4. MVVM + 组件化

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

其中的`header`、`main`、`input`、`button`、`copyright`都可以由UI/UE库或业务组件库提供，一次书写，多处使用，并且表现与形为均一致。

在现代web应用中，除了操作步骤增加之外，还格外注重用户体验。除了正常的业务逻辑，更多还需要考虑异常情况，
比如提醒、代码或服务出现异常、网络传输缓慢等。因而界面上会维护很多状态，在这些状态下尽可能提醒用户进行恰当的处理。
仅仅是组件化是难以维护这样复杂的代码，MVVM应运而生，前端由此进入数据驱动UI的时代。


## 抽离常用的代码，形成辅助工具库
在前端现有的生态中，各类工具函数库已经较为完善，使用这些工具函数库可以解决大部份重复的代码逻辑。
但由于不同项目毕竟有不同的需求，不能总是在社区上找到解决方案，就需要根据项目的实际情况与各个前端团队自身的技术储备量身打造。

我们在开发内部系统的时候发现，这类管理系统，总需要用户输入大量的数据。
对这类数据的合法性验证，是非常必要的，但又是一个非常没有技术含量事情。并且需要占用大量代码。
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

验证的逻辑是可以枚举的，不外乎那几十种，比如字符、数字、长度、范围、布而、非空等。
所以我们开发了一个工具库来做这件事情。
还以用户登录场景而言，使用该工具库代码如下：
```js
import { Reviser, TypeString, Required, MaxLength, Pattern } from 'data-reviser';

// 定义一个model
class SignIn extends Reviser {
  @Pattern(/\w/)
  @MaxLength(32)
  @TypeString()
  @Require()
  username = '';

  password = '';
}

// 使用
const sign = new SignIn();
const message = sign.map({ username: '', password: '' });
// 如果验证失败，message将是一个包含错误信息的map结构
```

## 开发阶段使用mock服务，与后端基于接口定义并行开发
传统开发流程：
1. 接到需求
2. 后端定义接口文档
3. 后端开发接口
4. 前端基于后端接口开发
5. 如果接口出错，反馈给后端，等待后端修复后继续开发
6. 前后端都开发完成后进行业务联调

可以看到传统模式下前端的进度严重受限于后端，一旦后端出问题，前端唯一能做的事情就是等待。
mock服务可以很好的解决这个问题。

接入mock后开发流程如下：
1. 接到需求
2. 后端定义接口文档
3. 前端将接口文档导入mock服务器，生成mock接口
4. 前端基于mock开始开发，后端开始开发
5. 前后端都开发完成后进行业务联调

除此之外，我们将mock服务与后端swagger无缝衔接，后端通过swagger提供的注解快速生成swagger.json。
前端只需将swagger.json导入前端的mock服务器，即可生成mock项目。

## 移动端调式日志上传到服务器，可以在pc上实时查看
在pc上开发可以通过调式工具打断点、查错误堆栈、审查页面状态、页面元素变化，可以很快速的定位问题。
但是在移动端（包括h5、微信、app内嵌web页）上的项目则不能，移动端对一个开发人员更像是一个黑盒，只能看见异常，却不知道具体的异常原因。

在目前的条件（时间与技术储备）下，我们使用实时日志的方式解决这个问题。在开发、测试环境下，
通过对关键步骤输出日志、全局错误捕获并上报的方式定位问题。

代码如下：
```js
import { Logger } from 'data-logger';
Logger.create('ui').trace('hello world');
```

在pc上打开`http://logservertest.100.com/real-time?namespace={namespace}`可以立马看到如下日志
```
# [server time][client time][level]: {message}
[2018-09-29 14:23:35][2018-09-29 14:23:34]: hello world
```

## 尽量参数化不同环境下的代码配置
