# 使用多阶段构建
多阶段构建从Docker 17.05及更高版本的守护进程与客户端的新功能，
对于那些努力优化Dockerfile同时保持可阅读性和可维护性的人来说，多阶段构建是非常有用的。

# 多阶段构建之前
构建镜像最有挑战性之一的就是使用镜像尽可能小。Dockerfile中的每一个指令都会向镜像添加一个新的层，
在移动到下一个图层之前，你需要记得清理所有不再需要的历史遗留。要编写一个非常高效的Dockerfile，
传统思维是采用shell技巧或其他方法使层尽可能小，并确保每个层都能从上一层拿到需要的数据，并且不会多拿。

一个Dockerfile用于开发环境，其中包含构建应用程序所需的一切，
另一个精简版的Dockerfile，只包含你的应用程序及运行所需的内容，用于生产环境，
这种情况实际上非常普遍，这被称为"构建器模式"。维护两个Dockerfile并不理想。

下面是一个Dockerfile.build与Dockerfile的示例，采用上面的构建器模式：

### Dockerfile.build
```dockerfile
FROM golang:1.7.3
WORKDIR /go/src/github.com/alexellis/href-counter/
RUN go get -d -v golang.org/x/net/html
COPY app.go .
RUN go get -d -v golang.org/x/net/html \
  && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .
```

注意：此例还使用Bash的`&&`操作符人为的将两个`RUN`命令合在一起，以避免在镜像中多出一个层。
这种方式容易出错而且难以维护，比如你很可能插入一个命令，但是忘记写`\`字符。

### Dockerfile
```dockerfile
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY app .
CMD ["./app"]
```

### Build.sh
```bash
#!/bin/sh
echo Building alexellis2/href-counter:build

docker build --build-arg https_proxy=$https_proxy --build-arg http_proxy=$http_proxy \
    -t alexellis2/href-counter:build . -f Dockerfile.build

docker create --name extract alexellis2/href-counter:build
docker cp extract:/go/src/github.com/alexellis/href-counter/app ./app
docker rm -f extract

echo Building alexellis2/href-counter:latest

docker build --no-cache -t alexellis2/href-counter:latest .
rm ./app
```

运行`build.sh`时，你需要先构建第一个镜像，创建一个容器以便将结果复制出来，然后构建第二个镜像。
两个镜像都会占用你的系统空间，并且在你的本地磁盘上依然有应用程序工件(artifact，译注：这词真难翻译)。

多阶段构建极大的简化了这种情况！

# 使用多阶段构建
在多阶段构建下，你可以在Dockerfile中使用多个`FROM`声明，每个`FROM`声明可以使用不同的基础镜像，
并且每个`FROM`都使用一个新的构建阶段。你可以选择性的将工单(artifacts)从一个阶段复制到另一个阶段，
删除你不想保留在最终镜像中的一切。为了说明它是如何工作的，我们来调整上一节的Dockerfile以使用多阶段构建。

### Dockerfile
```dockerfile
FROM golang:1.7.3
WORKDIR /go/src/github.com/alexellis/href-counter/
RUN go get -d -v golang.org/x/net/html
COPY app.go .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=0 /go/src/github.com/alexellis/href-counter/app .
CMD ["./app"]
```
你只需要一个Dockerfile文件即可，也不需要单独的构建脚本，只需要运行`docker build`。

```bash
$ docker build -t alexellis2/href-counter:latest .
```
最终的结果是与前面一样的极小的结果，但是复杂性大大降低，你不需要创建任何中间镜像，
也根本不需要将任何工件(artifacts)提取到本地系统。

它是如何工作的？第二个`FROM`指令使用`alpine:latest`镜像作为基础开始一个新的构建阶段，
`COPY --from=0`的行将前一个阶段的结果复制到新的阶段，`GO SDK`及所有中间产物被抛弃，并没有保存在最终镜像中。

# 命名构建阶段
默认情况下，构建阶段没有命名，使用它们的整数编号引用它们，从第一个`FORM`以0开始计数。
但是你可以使用给`FORM`指令添加一个`as <NAME>`为其构建阶段命名。以下示例通过命名构建阶段并在`COPY`指令中使用名称来改进上一个示例。
这意味着即使Dockerfile中的指令稍后发生顺序变化，`COPY`指令也不会出问题。

```dockerfile
FROM golang:1.7.3 as builder
WORKDIR /go/src/github.com/alexellis/href-counter/
RUN go get -d -v golang.org/x/net/html
COPY app.go    .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /go/src/github.com/alexellis/href-counter/app .
CMD ["./app"]
```



