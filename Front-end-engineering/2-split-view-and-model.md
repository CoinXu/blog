在[上一篇](./1-intro.md)中对实现视图层进行了一些思考和实践，总结出应该将View与Model拆分开来。

上篇中将拆分View与Model的目的简单的总结为 先 **解藕** 后 **组合**，本篇将分别深入讨论View与Model的拆分目的与实现思路。

# View
View要做到解藕，首先要与Model隔离开来。
Model可能是会变化的，一旦Model发生变化，View相关代码就需要跟着变动，此为影响解藕成功与否原因之一。
其二，View如果与Model绑定，那么一个View就只能展示与该Model相关的视图。

假设现有一个需求，渲染用户列表、渲染订单列表。
```TypeScript
// 用户数据结构
interface User {
    id: string,
    name: string
}
// 订单数据结构
interface Order {
    id: string,
    title: string
}
```

代码大致如下:
```TSX
type userList = Array<User>
type orderList = Array<Order>
// 渲染用户列表
<ul>
{
    userList.map(mod => (<li>{mod.name}</li>))
}
</ul>
// 渲染订单列表
<ul>
{
    userList.map(mod => (<li>{mod.title}</li>))
}
</ul>
```

因为两个Model定义不同，则不得不书写重复的代码。
此时的渲染过程为`Model -> View`

解决这个问题也很简单，既然渲染结构相同，只是数据不同，那么将两份数据映射成相同的结构即可，只需要加一个中间数据层。
我们可以考虑一下，如何设计一下新的View。此时需要我们跳出View与Model关联的思维方式。
View有其自己的固定格式数据，无需理会外面的数据是什么样子，如果要使用该View，就需要提供这样的数据格式。
人们将渲染View需要的数据称之为ViewModel，也就是上文中的中间数据层，View则可以如下设计：

```TSX
interface ViewList = {
    text: string
}
type ViewModel = Array<ViewList>
function renderListView(vm: ViewModel):string{
    return (
        <ul>
        {
            vm.map(v => (<li>{v.text}</li>)))
        }
        </ul>
    )
}
```

渲染如下：
```TypeScript
const UserViewModel:ViewModel = UserList.map(m => ({text: m.name}))
const OrderViewModel:ViewModel = OrderList.map(m => ({text: m.title}))
renderListView(UserViewModel)
renderListView(OrderViewModel)
```

此时渲染过程为`Model -> ViewModel -> View`，View与Model完全独立。

# Model
Model功能主要包含数据获取与存储，以及一些简单的处理。
实现Model分离之前，需要考虑接口的统一管理。个人认为这是一个前端工程规划是否合理的重要考核指标之一。
此处需要做两件事情：
+ 统一接口返回内容的结构
+ 统一接口定义

这两点很好理解：
+ 如果每个接口返回的结构不一致，调用者基本上要为每个接口写一个处理函数。
+ 如果接口没有统一定义，那么接口的url、参数、响应处理的逻辑都会重复定义，增加维护成本与出错机率。

## 返回值结构定义
接口返回内容需要包含如下信息：
```TypeScript
interface ResponseStruct<T> {
  success: boolean
  code: number
  message: string
  result: T
  type: string | number
}
```
`code`字段一般要求与`http`状态保持一致，这有助于后期日志处理。
`type`字段标识`result`数据类型，根据业务需要，可以扩展其他字段。
前端可以依据该接口做统一的预处理，比如检测`success`或`code`值显示`message`。

## 统一接口定义
接口包含一个url，以及一些调用方式，诸如`post`,`get`,`put`。
由于服务器选型方案不同，可能需要解析url(Restfull或graphQ)，还可能需要对返回值进行简单的处理，比如返回`json`。
如果每次调用都去处理，未免太傻了些。

可以定义如下资源管理类，部份方法如下
```TypeScript
interface Resource<T> {
  new(url:string)
  get(params:any):Resource<T>
  post(params:any, body:any):Resource<T>
  json():Promise<ResponseStruct<T>>
  text():Promise<ResponseStruct<T>>
}
```

使用时，先统一定义
```TypeScript
// 定义
const UserResource = {
  create: new Resource<UserModel>('/app/user/create'),
  query: new Resource<UserModel>('/app/user/query/:id'),
  destroy: new Resource<UserModel>('/app/user/destroy/:id'),
  update: new Resource<UserModel>('/app/user/update')
}
```

然后调用
```TypeScript
const user:UserModel = await UserResource.create.post({name:'user_name', age:1}).json()
const destory = await UserResource.destroy.get({id: 'user_id'}).json()
```
从而达到：一次定义，多次使用，统一管理的设计目的。

接口还有一个比较重要的情况需要考虑：输入验证。
每个接口都需要对输入进行验证，包括数据类型、结构、有效性等方面，数据库字段有还包含长度、取值范围或enum值验证。
验证的位置包括用户输入、客户端验证、服务端验证等，而这些验证逻辑必须保持一致。
所以验证代码最好使用单独的模块实现。

基本的验证类型包含type、enum、required、in、oneof、bound等。
React使用的PropTypes接口设计得比较好，可以定义如下结构以适应最小粒度的参数验证代码。

```TypeScript
interface CheckResult {
  message: string | null
  success: boolean
}
interface Checker {
  (props: any, name: string): CheckResult
  isRequired(props: any, name: string): CheckResult
}
interface DefineTypes {
  [key:string]: Checker
}
declare function defineTypes(types: DefineTypes):(props:any) => CheckResult
interface PropTypes {
  string: Checker
  number: Checker
  array: Checker
}
```

使用如下
```TypeScript
const checker = defineTypes({
  str: PropTypes.string,
  num: PropTypes.number.isRequired
})
const result: CheckResult = checker({
  str:'s',
  num: 1
})
```
`checker`定义后，可在不同的场景下多次使用。

下一篇谈谈 Model -> ViewModel -> View -> UI 数据流控制
