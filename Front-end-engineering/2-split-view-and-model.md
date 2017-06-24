在[上一篇](./1-intro.md)中对实现视图层进行了一些思考和实践，总结出应该将View与Model拆分开来。

上篇中将拆分View与Model的目的简单的总结为 **解藕** 与 **组合**,
本篇将分别深入讨论View与Model的拆分目的与实现思路。

# View
View要做到解藕，首先要与Model隔离开来。因为Model可能是会变化的，
一旦Model发生变化，View相关代码就需要跟着变动，此为影响解藕成功与否原因之一。
其二，View如果与Model绑定，那么一个View就只能展示与该Model相关的视图。

假设现有一个需求，渲染用户列表、渲染订单列表。
```TypeScript
// 用户数据结构
interface UserDesc {
    id: String,
    name: String
}
// 订单数据结构
interface OrderDesc {
    id: String,
    title: String
}
```
代码大致如下:
```TypeScript
const userList = Array<UserDesc>
const orderList = Array<OrderDesc>
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

解决这个问题也很简单，既然渲染结构相同，只是数据不同，那么将两份数据映射成
相同的结构即可，只需要加一个中间数据层，我们可以考虑一下，如何设计一下新的View。

此时需要我们跳出View与Model关联的思维方式，View有其自己的固定格式数据。
无需理会外面的数据是什么样子，如果要使用该View，就需要提供这样的数据格式。

人们将渲染View需要的数据称之为ViewModel，也就是上文中的中间数据层，View则可以如下设计：

```TypeScript
interface ViewListDesc = {
    text: string
}
type ViewModel = Array<ViewListDesc>
function renderListView(vm: ViewModel){
    return (
        <ul>
        {
            vm.map(v => (<li>{v.text}</li>)))
        }
        </ul>
    )
}
```
此时渲染过程为`Model -> ViewModel -> View`，View与Model完全独立，
如果要使用该View，必须将数据转为ViewModel。
```TypeScript
const user_vm = userList.map(m => ({text: m.name}))
const order_vm = orderList.map(m => ({text: m.title}))
renderListView(user_vm)
renderListView(order_vm)
```

# Model

