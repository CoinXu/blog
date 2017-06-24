任何前端应用都绕不过视图层，前端工程师大多数时间都在与视图层做斗争。
前端最流行的框架也一直是与视图相关的，视图层处理主要包括两个方面
+ 使用数据渲染
+ 与用户行为交互

# 使用数据渲染
视图数据的来源一般包含常量`Constant`与从服务器请求得来的`Model`。
常量数据指一个视图下固定的值，比如按钮名称，图片地址等。
这些数据不用处理，拿到之后直接使用即可，难点是`Model`数据的处理。

`Model`数据大多为服务端数据库表字段，或为原始表结构数据，或为稍做加工后的数据。
无论是从节省服务器性能，还是保持接口数据的纯粹性来说，`Model`都不应该被过度加工。

所以，对客户端来说，我们基本可以认为`Model`是一个原始数据。

使用原始的`Model`来渲染`View`，必然会进行一系列的数据加工（比如转换、计算、过滤等）。

思考一下这样的场景：按订单状态查看订单表列，设订单状态包含：
+ 待支付
+ 已支付
+ 已取消
设数据库中`order`表的字段如下：
```JavaScript
const ORDER_STATUS = {
    NORMAL: 0,
    PAID: 1,
    CANCELED: 2
}
const Order = {
    id: String,
    user_id: String,
    goods_id: String,
    status: Integer,
    pay_type: Integer,
    create_at: Date
}
```
客户端从服务端拿到的数据为一个`List<Order>`，渲染层代码大致如下。
```jsx
const list = await fetch('http://api.example.com/order/list')
<div className="wrapper">
    <p>待支付</p>
    <div className="content">
    {
        list
        .filter(mod => mod.status === ORDER_STATUS.NORMAL)
        .map(mod => (<h3>{mod.id} create at {mod.create_at}</h3>))
    }
    </div>
</div>
// ...渲染已支付
// ...渲染已取消
```
Ok，看起来解决了业务的需求，代码还比较清晰。

现在我们来增加需求，使其更贴合实际场景：查询和订单相关的商品，将商品的名称显示在列表上。
设商品表结构如下：
```JavaScript
const GoodsDesc = {
    id: String,
    title: String,
    price: Integer
}
```
这样也简单，加代码：
```jsx
const orders = await fetch('http://api.example.com/order/list')
const goods = await fetch(`http://api.example.com/goods/list/${base64(orders.map(m => m.goods_id))}`)
<div className="wrapper">
    <p>待支付</p>
    <div className="content">
    {
        list
        .filter(mod => mod.status === ORDER_STATUS.NORMAL)
        .map(mod => {
            const cur = goods.find(m => m.id === mod.goods_id)
            return (
                <div>
                    <h3>{mod.id} create at {mod.create_at}</h3>
                    <p>商品名称：{cur.title}</p>
                    <p>应付：{cur.price}</p>
                </div>
            )
        })
    }
    </div>
</div>
```
Ok，又解决了一个需求。

这是一个比较典型的__渲染__视图层开发程式。
如果只是做渲染，这样是完全没有问题的，看起来还很清晰。
事实上这也是服务端渲染模版的方式：查询数据 -> 传入模版引擎 -> 得到结果字符 -> 传递到客户端

# 与用户行为交互
与服务端不同，客户端最重要的功能除了内容展现之外，还要提供用户交互界面(UI)。
常见的用户行为造成的结果包括`View`和`Model`更新。

比如用户点击了`加入购物车`按钮，在`View`上需要出现提示信息（成功或失败或其他异常），
同时服务端数据也可能需要更新。
```jsx
<button onClick={async function() {
    await fetch(`http://api/example.com/cart/add/${product_id and number}`)
    message.success('加入成功')
}}>加入购物车</button>
```
需求解决了。

# 深入一点的思考？
看起来我们能比较容易的解决以上的需求。但这样需求只存在于教程中，实际需求的复杂程度远超于此。
任何简单的事物开始庞大之后，就会多出无数的问题。
这样的差别和带一群小朋友与带一支军队一样大。

比如，一个视图上的数据可能来自于数十个接口，并且请求数据的参数随着用户的操作产生的。

再如，一个视图的交互极其复杂（游戏）。

或者还有需要从第三方服务获取数据。

如此种种，都不好弄。

如果还以上面提供的方式去组织代码，可以预见的是代码必然乱成一团（数据、视图、行为混杂一处）。
产生巨大的维护成本。

于是前贤们在实际工作中，结合经验与血淋淋的教训（想笑...），产生了各种设计模式，
如`MCV`，`MVP`，`MVVM`等，这些可以统一表示为`MV*`。
无论何种模式，`M`与`V`都是单独提出来处理的，由此可见`Model`与`View`的重要性。

这些模式的设计思想表现不一，但有一点是统一的：分离。书面化点说：解耦。

由此甚至产生了一条不成文的规则：
#### 组合大于复用

如果要满足这条规则，则需要拆模块、拆功能、拆接口、拆结构，拆一切能拆的，
只有拆开了，才能组合，才能复用。

拆的粒度控制，则需要根据实际需要来决定。


下一篇思考如何拆。

