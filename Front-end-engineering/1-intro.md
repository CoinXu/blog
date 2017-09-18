# 从视图层说起
任何前端应用都绕不过视图层，前端工程师大多数时间都在与视图层做斗争。
前端最流行的框架也一直是与视图相关的，视图层处理主要包括两个方面
+ 使用数据渲染
+ 与用户行为交互

# 使用数据渲染
视图数据的来源一般包含常量与从服务器请求得来的Model。
常量数据指一个视图下固定的值，比如按钮名称，图片地址等。
这些数据不用处理，拿到之后直接使用即可，复杂的是Model数据的处理。

Model数据大多为服务端数据库表字段。或为原始表结构数据，或为稍做加工后的数据。
无论是从节省服务器性能，还是保持接口数据的纯粹性来说，Model都不应该被过度加工。
所以，我们基本可以认为Model是一个表结构原始数据。
使用原始的Model来渲染View，必然会进行一系列的数据加工（比如转换、计算、过滤等）。

思考一下这样的场景：按订单状态查看订单表列，设订单状态包含：
+ 待支付
+ 已支付
+ 已取消

设数据库中`order`表的字段如下：
```TypeScript
interface OrderStatus {
    NORMAL: number
    PAID: number
    CANCELED: number
}
interface Order {
    id: string
    user_id: string
    goods_id: string
    status: number,
    pay_type: number
    create_at: number
}
```

客户端从服务端拿到的数据为一个`Array<Order>`，渲染伪代码大致如下。
```TSX
const list:Order[] = await fetch('http://api.example.com/order/list')
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
```TypeScript
interface Goods {
    id: string
    title: string
    price: number
}
```

这样也简单，加代码：
```TSX
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
这是一个比较常见的视图层开发程式。
如果只是做渲染，这样是完全没有问题的，看起来还很清晰。
事实上这也是服务端渲染模版的方式：查询数据 -> 传入模版引擎 -> 得到结果字符 -> 传递到客户端

# 与用户行为交互
与服务端不同，客户端除了内容展现之外，还要提供用户交互界面(UI)。交互结果结果会造成View和Model更新。
比如用户点击了`加入购物车`按钮，在View上需要出现提示信息（成功或失败或其他异常），同时服务端数据也可能需要更新。

```TSX
<button onClick={async () => {
    const res = await fetch(`http://api/example.com/cart/add/${product_id and number}`)
    message.success(res.success ? '加入成功' : '加入失败')
}}>
  加入购物车
</button>
```
需求解决了，看起来也不难。


# 深入一点的思考
以上的需求只存在于教程中，实际需求的复杂程度远超于此。
任何简单的事物变得超来越多的时候，就会多出无数的问题。
这样的差别和带一群小朋友与带一支军队一样大。

比如，一个视图上的数据可能来自于数十个接口，并且请求数据的参数随着用户的操作产生的。
再如，一个视图的交互极其复杂（游戏）。或者还有需要从第三方服务获取数据。如此种种，都不好弄。

如果还以上面提供的方式去组织代码，可以预见的是代码必然乱成一团（数据、视图、行为代码混杂一处）。
+ 到处都在发请求
+ 同一个请求的`url`写了一次又一次，返回结果处理了一次又一次
+ 到处都在处理Model
+ 到处都在进行逻辑判断
+ 团队开发下，每个人可能都要去实现重复的功能

开发成本与维护成本自然高居不下。
于是前贤们在实际工作中结合经验与血淋淋的教训（想笑...），产生了各种设计模式。
如`MCV`，`MVP`，`MVVM`等，这些可以统一表示为`MV*`。
无论何种模式，`M`与`V`都是单独提出来处理的，由此可见Model与View的重要性。
这些模式的设计思想表现不一，但有一点是统一的：分离。书面化点说：解耦。
甚至产生了一条不成文的规则：
### 组合大于复用

所以写代码的时候需要拆分，拆模块、拆功能、拆接口、拆结构，拆一切能拆的，只有拆开了，才能组合，才能复用。
至于拆的粒度，那又是一个不是那么容易说明白的事情。

[下一篇:拆分view与model](./2-split-view-and-model.md)

