# Dockerfile参考

Docker可以从一个Dockerfile中读取指令自动创建镜像，
Dockerfile是一个包含了用户可以在命令行上所有用于组合镜像的命令。
用户可以使用`docker build`创建一个连续执行一些命令的自动构建。

本页介绍了能在Dockerfile中使用的命令集。在你阅读完本文之后，你可以参考[Dockerfile最佳实践](./4-work-in-images.md)
获得最好的指导。

# 用法
`docker build`命令从一个Dockerfile与一个上下文中构建一个镜像。
构建的上下文是一个指定的本地`PATH`或`URL`的文件集合。`PATH`为本机上的一个目录，`URL`为一个git仓库地址。

上下文是一个递归处理的过程，所以，一个`PATH`包含了其所有的子目录，一个`URL`包含了该仓库及其子模块。
以下示例展示了使用当前目录作为上下文运行`build`命令。
```bash
$ docker build .
Sending build context to Docker daemon  6.51 MB
...
```
该构建由Docker守护进程运行，而不是由CLI运行。构建时，最先时最做的就是将整个上下文发送到守护进程。
大多数情况下，最好的方式是使用一个空的目录作为上下文，将Dockerfile放在该目录中。
只添加构建所需的文件到该目录中。

> 警告: 不要使用根目录`/`作为上下文，使用`/`会将你硬盘上的所有内容发送到守护进程

要使用构建上下文中的文件，Dockerfile引用指令指定中指定的文件，比如`COPY`指令。
为了提升构建性能，可以在上下上下文目录中添加一个`.dockerignore`文件用于排除文件和目录。
关于如何[创建一个.dockerignore文件](https://docs.docker.com/engine/reference/builder/#dockerignore-file)
的信息在该页面查看。

Dockerfile文件惯例上命名为Dockerfile并放在构建上下文根目录中。你也可以在使用`docker build`命令时添加上
`-f`标识指定位于你的文件系统上任意位置的Dockerfile文件。
```bash
$ docker build -f /path/to/a/Dockerfile .
```
你也可以指定一个存储库和标签，在构建成功作为镜像的标识。
```bash
$ docker build -t shykes/myapp .
```
要在构建成功后将镜像票房到多个存储库中，可以添加多个`-t`标识
```bash
$ docker build -t shykes/myapp:1.0.2 -t shykes/myapp:laest .
```

Docker守护进程在运行Dockerfile指令之前，会对指令作为一个初步检查，如果有语法不正确将会返回一个错误：
```bash
$ docker build -t test/myapp .
Sending build context to Docker daemon 2.048 kB
Error response from daemon: Unknown instruction: RUNCMD
```

Docker守护进程逐条运行Dockerfile中的命令，如果需要，将每条指令的结果提交到新的镜像，最后输出新镜像的ID。
Docker守护进程会自动清理你发送的构建上下文。

需要注意的是，每条指令都是独立运行的，并会创建一个新的镜像，所以诸如`RUN cd /tmp`不会对下一条指令造成任何影响。
Docker会尽可能的使用中间镜像(缓存)以显著加速构建过程。这由控制台输出的`Using cache`消息可标明。
([构建缓存章节](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#build-cache)可以看看更多详情)
```bash
$ docker build -t svendowideit/ambassador .
Sending build context to Docker daemon 15.36 kB
Step 1/4 : FROM alpine:3.2
 ---> 31f630c65071
Step 2/4 : MAINTAINER SvenDowideit@home.org.au
 ---> Using cache
 ---> 2a1c91448f5f
Step 3/4 : RUN apk update &&      apk add socat &&        rm -r /var/cache/
 ---> Using cache
 ---> 21ed6e7fbb73
Step 4/4 : CMD env | grep _TCP= | (sed 's/.*_PORT_\([0-9]*\)_TCP=tcp:\/\/\(.*\):\(.*\)/socat -t 100000000 TCP4-LISTEN:\1,fork,reuseaddr TCP4:\2:\3 \&/' && echo wait) | sh
 ---> Using cache
 ---> 7ea8aef582cc
Successfully built 7ea8aef582cc
```

# 格式
Dockerfile 格式如下：
```conf
# 注释
指令 参数
```

指令对大小写不敏感，然后将指令转换成大写可以更容易区分指令与参数。
Docker运行Dockerfile中的指令是按照顺序进行。一个Dockerfile必须是以`FROM`指令开始。
`FROM`指令指明了你创建的基础镜像。`FORM`指令只能在一个或多个`ARG`指令之前，
`ARG`指令声明在Dockerfile中`FROM`行使用的参数。

如果一行以`#`开始，Docker认为其是一个注释，除非该行是一个合法[解析指令](#解析指令)。
一行其他地方的`#`标志会当作参数对待。可以使用如下语句：
```conf
# Comment
RUN echo 'we are running some # of cool things'
```
续行标识不能用于注释中。


# 解析指令

[TODO](https://docs.docker.com/engine/reference/builder/#parser-directives)

# 环境变更
环境变量（用`ENV`语句声明）也可以在某些指令中使用，作为Dockerfile解释的变量。
将类似变量的语句包含在字符串在还可以用来处理转义。

环境变量在Dockerfile中使用`$variable_name`或`${variable_name}`标记。他们被等效对待，
并且大括号语法用于解决不带空格的亦是名称的问题，比如`${foo}_bar`。
`${variable_name}`语法还支持以下特定的标准bash修饰符：
+ `${variable:-word}` 标示如果没有设置变量值，那么该变量的值为`word`
+ `${variable:+word}` 标示如果设置了变量值，那么该量变为`word`，否则为空字符串。

`word`可以是任何字符串，也可以是其他环境变量。

可以在一个变量前加`\`来转义：`\$foo`或`\$bar`，以下示例将`$foo`和`${foo}`分别转为字符。
`#`表示解析后的结果。
```bash
FROM busybox
ENV foo /bar
WORKDIR ${foo}   # WORKDIR /bar
ADD . $foo       # ADD . /bar
COPY \$foo /quux # COPY $foo /quux
```

环境变量支持下表中的指令：
+ ADD
+ COPY
+ ENV
+ EXPOSE
+ FROM
+ LABEL
+ STOPSIGNAL
+ USER
+ VOLUME
+ WORKDIR

以及
+ ONBUILD（当与上面指令组合时支持）

> 1.4之前，ONBUILD指令不支持环境变量，即使与上述其他指令组合

环境变量将会在整个指令中为每个变量使用相同的值，换句话说，在以下的例子中，
def=hello，而不是bye。然而ghi=bye，因为他与abc=bye不在同一条指令中。

# .dockerignore file

在docker CLI发送context到docker守护进程之前，docker CLI将会寻找context根目录下一个名为`.dockerignore`的文件。
如果该文件存在，docker CLI将会修改context，使其排除该文件中匹配的文件目录。
这有助于避免将不必要的大的、敏感的文件或目录发送到守护进程，也能避免用户通过`ADD`或`COPY`命令将这些文件或目录添加到镜像。

CLI将.dockerignore文件解析为以换行符作为分割符的匹配模式列表，context的根目录将会作为.dockerignore中所有匹配的根目录。
比如，模式`/foo/bar`与`foo/bar`都会排除`PATH`或本地git仓库根目录下`foo`子目录中名为`bar`的文件或目录。

如果.dockerignore中的一行以`#`开始，那么该行被认为是注释，在CLI解析时将会被忽略。

下面是一个.dockerignore列子
```
# comment
*/temp*
*/*/temp*
temp?
```
|     Rule       | Behavior                                                                                                |
| -------------- | ------------------------------------------------------------------------------------------------------- |
| # comment      | 注释、忽略                                                                                                |
| */temp*        | 排除根目录中的`直接`子目录中任何以`temp`开头的文件或目录，比如文件`/somedir/temporary.txt`、目录`/somedir/temp`  |
| */*/temp*      | 排除根目录中的`二级`子目录内的以`temp`开头的文件或目录，比如 `/somedir/subdir/temporary.txt`                   |
| temp?          | 排除根目录中名称为`temp`后跟一个字符的文件或目录，比如`/tempa`或`/tempb`                                       |

匹配使用Go的[filepath.Match](http://golang.org/pkg/path/filepath#Match)规则，预处理步骤中将会删除开头与结尾的空白符，
使用[filepath.Clean](http://golang.org/pkg/path/filepath/#Clean)清除`.`与`..`元素元素。预处理后的空白行将会被忽略。

除了Go的filepath.Match规则之外，Docker还支持一个特殊的通配符`**`，用来匹配任意数量的目录，包括没有目录(including zero)。
比如`**/*.go`将会排除context根目录下所以有`.go`结尾的文件。

一行以!（感叹号）开头可以用来标识例外的情况，下面是一个使用该机制的例子：
```
*.md
!README.md
```
排除除了`README.md`之外的所有`md`文件。

!符号位置的影响行为：.dockerignore最后一行匹配决定一文件或目录是包含还是排除。考虑如下情况：
```
*.md
!README*.md
README-secret.md
```
不包含任何markdown文件，除了`README`之外，而且要排除`README-secret.md`。

现在考虑如下情况：
```
*.md
README-secret.md
!README*.md
```
所有的`README`文件将会被包含进来，中间这行没有起效，因为`!README*.md`也匹配了`README-secred.md`，并且还是在最后匹配的。

你甚至可以使用.dockerignore排除Dockerfile和.dockerignore文件。
但是这些文件依然会被发送到守护进程，因为需要它们来完成任务，但`ADD`与`COPY`指令将不会复制它们到镜像。

最后，你可能希望能够指定哪些文件可以包含进来，而不是排除哪些文件。
为了达到这个目的，你可以指定`*`作为第一个匹配模式，然后再使用一个或多个`!`感叹号模式。

__注:__ 历史原因，`.`匹配模式已被忽略。

# FROM
```dockerfile
FROM <image> [AS <name>]
```
或
```dockerfile
FROM <image>[:<tag>] [AS <name>]
```
或
```dockerfile
FROM <image>[@<digest>] [AS <name>]
```

`FROM`指令初始化一个新的构建阶段并且为接下来的指令设置一个基础镜像。
一个合法的Dockerfile必须以一个`FROM`指令开始。image参数可以是任意合法的镜像，
可以非常容易的从[公开仓库](https://docs.docker.com/engine/tutorials/dockerrepos/)中得到。

+ `ARG`是Dockerfile中唯一可能出现在`FROM`之前的指令，见[ARG与FROM的相互影响](#ARG与FROM的相互影响)

FROM可以在单个Docker文件中多次出现以创建多个图像，或者使用一个构建阶段作为另一个的依赖。
在每个新的FROM指令之前，简单地记录通过提交输出的最后一个图像ID。每个FROM指令清除由先前指令创建的任何状态。

+ `FROM`可以在一个Dockerfile中出现多次来创建多个镜像，或者使用一个构建阶段(build stage)作为其他构建的依赖。
  在每个新的`FROM`指令之前，简单地记录通过提交输出的最后一个镜像的ID。(译注：这句话不知道是什么意思，译者只是按原句语义翻译。
  Simply make a note of the last image ID output by the commit before each new FROM instruction.)
  每个`FROM`指令将会清除之前指令创建的所有状态。
+ 可选参数name，可以使用`AS name`给`FROM`指令一个新的构建阶段。该name可以用在接下来的`FROM`和`COPY --from=<name|index>`指令在该构建阶段中构建新的镜像。
+ `tag`或`digest`是可选的，如果你忽略二者之一，构建器默认分配`latest`，如果构建器找不到`tag`值，将会返回一个错误。

# ARG与FROM的相互影响
`FROM`指令支持在第一个`FROM`指令前使用`ARG`指令声明的变量。
```dockerfile
ARG  CODE_VERSION=latest
FROM base:${CODE_VERSION}
CMD  /code/run-app

FROM extras:${CODE_VERSION}
CMD  /code/run-extras
```
在`FROM`之前的`ARG`声明在构建阶段之外，所以不能在任何`FROM`之后的指令中使用。
若要使用第一个`FROM`指令前`ARG`指令声明的默认值，可以在构建阶段使用`ARG`指令声明变量，但不要赋值：
```dockerfile
ARG VERSION=latest
FROM busybox:$VERSION
ARG VERSION
RUN echo $VERSION > image_version
```

# RUN
`RUN`有两种形式：
+ `RUN <command>` ： shell形式，命令在shell中运行，在Linux中为`/bin/sh -c`，Window中为`cmd /S /C`
+ `RUN ["executable", "param1", "param2"]`：执行形式

`RUN`指令将在当前镜像最上层创建一个新的层来执行并提交执行结果，该接果将会用于Dockerfile后续的步骤。

分层执行`RUN`指令并提交结果，符合Docker的核概念，提交变更成本很低，容器可以从镜像的任意层创建。

执行形式可以避免shell脚本字符被修改，还可以在一个没有指定shell运行环境的基础镜像中执行命令。

shell形式的默认shell可以通过`SHELL`命令修改。
在shell形式下可以使用一个\(反斜线)来连接位位于多行的一条指令。如：
```dockerfile
RUN /bin/bash -c 'source $HOME/.bashrc; \
echo $HOME'
```
等同于
```dockerfile
RUN /bin/bash -c 'source $HOME/.bashrc; echo $HOME'
```

> __注:__
  如果不使用`/bin/sh`而想使用其他的shell来运行命令，可以使用执行形式指定一个shell。
  比如：`RUN ["/bin/bash", "-c", "echo hello"]

> __注:__
  执行形式将会被转成JSON数据，这意味着你必须使用双引号（"）来包裹一个词，而不是单引号（')。

> __注:__
  与shell形式不同，执行形式不会调用shell命令，不会执行正常的shell处理程序。
  比如执行`RUN ["echo", "$HOME"]`，$HOME并不会发生变量替换。
  如果你希望shell处理程序执行，可使用shell形式或直接执行一个shell，如`RUN [ "sh", "-c", "echo $HOME" ]`。
  当你使用执行形式或直接执行shell，与shell形式一样，是由正在执行环境变量扩展的shell在处理，而不是docker。

> __注:__
  在JSON形式下，必需转义反斜线，尤其是在将反斜线作为路径分隔符的windows上。
  如：`["c:\windows\system32\tasklist.exe"]`将会被视为shell形式，因为它不是合法的JSON。
  正确的语法应为：`["c:\\windows\\system32\\tasklist.exe"]


`RUN`指令的缓存不会自动清理，将会用于下一次构建。
如运行`RUN apt-get dist-upgrade -y`的缓存在一次的构建时将会被使用。
但可以通过`--no-cache`标识使`RUN`指令的缓存失效，如`docker build --no-cache`。

更多信息见Dockerfile [最佳实践指南](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#/build-cache)。

`RUN`指令的缓存可以通途`ADD`指令使其无效，[详见](https://docs.docker.com/engine/reference/builder/#add)

## 已知问题(RUN)
[Issue 783](https://github.com/docker/docker/issues/783)
是关于文件权限的问题，可能在AUFS文件系统上出现。在你尝试删除一个文件的时候可能会收到该提示。

如果系统为最近的aufs版本（可以设置`dirperm`挂载配置），Docker将会尝试通过使用`dirperm`选择挂载该层来自动修复这个问题。
`dirperm1`选择的详细信息可以在aufs[主页](https://github.com/sfjro/aufs3-linux/tree/aufs3.18/Documentation/filesystems/aufs)找到。

如果你的系统不支持`dirperm1`，该issue提供了一个解决方案。

# CMD
`CMD`指令有三种使用形式
+ `CMD ["executable","param1","param2"]` 执行形式，也是首选形式
+ `CMD ["param1","param2"]` 作为`ENTRYPOINT`的默认参数
+ `CMD command param1 param2` shell命令形式

一个Dockerfile中只能出现一次`CMD`指令，如果出现多次，只有最后一次出现的起作用。

`CMD`一个主要目的是为一个执行容器提供默认值，该值可以包含可执程序，也可以省略，如果省略了，你需要指一个`ENTRYPOINT`指令。

> __注:__ 如果`CMD`用来为`ENTRYPOINT`指令提供默认参数，`CMD`与`ENTRYPOINT`指令都要符合JSON数组格式。

> __注:__ 执行形式将会解析为JSON格式数组，所以你必须使双引号来包裹语句，而非单引号。

> __注:__
  与shell形式不同，执行形式不会调用shell程序，不会发生正常的shell程序处理。
  如`CMD ["echo", "$HOME"]`不会在`$HOME`上发生变量替换。如果你希望shell处理程序生效，你可以使用shell形式或直接执行shell程序。
  如`CMD ["sh", "-c", "echo $HOME"]`，当你使用执行形式或直接执行shell，与shell形式一样，是由正在执行环境变量扩展的shell在处理，而不是docker。

shell格式与可执行形式的`CMD`指令设置的命令将会在镜像运行是执行。

如果你使用了shell形式的`CMD`指令，其`<command>`部份将会运行在`/bin/sh -c`中：
```dockerfile
FROM ubuntu
CMD echo "This is a test." | wc -
```
如果你不想在shell中运行你的`<command>`，你必须使用JSON数组格式定义命令，并且为可执行程序给定完整的路径。
数组形式是`CMD`首选形式，所有的附加参数必须独立的以字符串形式置于数组中。
```dockerfile
FROM ubuntu
CMD ["/usr/bin/wc","--help"]
```
如果你希望容器每次执行同样的程序，那么你应该考虑`ENTRYPOINT`与`CMD`结合使用，详见[ENTRYPOINT](#entrypoint)

如果用户在运行`docker run`命令时指定了参数，将会覆盖默认的`CMD`指令。

> __注：__ 不要混淆`RUN`和`CMD`。`RUN`实际上是运行命令并提交结果，`CMD`在构建是不会执行任何指令，
  只是为镜像提供预备(intended)(译注：相当于默认的意思吧，就是如果在`docker run`中没有提供参数，就使用`CMD`提供的了)的命令。

# LABEL
```dockerfile
LABEL <key>=<value> <key>=<value> <key>=<value> ...
```
`LABEL`指令添加元数据到一个镜像中(metadata)，一个`LABEL`为一个key-value对，其值与`LABEL`用空格隔开。
可以像命令中一样使用引号和反斜杆。下面是一些使用例子：
```dockerfile
LABEL "com.example.vendor"="ACME Incorporated"
LABEL com.example.label-with-value="foo"
LABEL version="1.0"
LABEL description="This text illustrates \
that label-values can span multiple lines."
```
一个镜像可以有多个`LABEL`，Docker推荐尽可能使用单个`LABEL`指令组合所有的值。
每个`LABEL`会产生一个新的层，从而导致镜像效率低下。下面的例子的结果将会作为镜像的单个层：
```dockerfile
LABEL multi.label1="value1" multi.label2="value2" other="value3"
```
上面的例子也可以写成：
```dockerfile
LABEL multi.label1="value1" \
      multi.label2="value2" \
      other="value3"
```
标签附加在`FROM`提供的镜像里，如果Docker遇到标签的键与已存在的键相冲突的情况，新的值将会覆盖原来键所属的值。
使用`docker inspect`可以显示一个镜像的标签：
```dockerfile
"Labels": {
    "com.example.vendor": "ACME Incorporated"
    "com.example.label-with-value": "foo",
    "version": "1.0",
    "description": "This text illustrates that label-values can span multiple lines.",
    "multi.label1": "value1",
    "multi.label2": "value2",
    "other": "value3"
},
```

# MAINTAINER (已废弃)

# EXPOSE
```dockerfile
EXPOSE <port> [<port>/<protocol>...]
```
`EXPOSE`指令告诉Docker容器运行时监听的网络端口。你可以指定TCP或UDT的端口，如果没有指定通信协议，默认为TCP端口。

`EXPOSE`指令并非真正的开放端口。它的功能是为在构建镜像和使用镜像人的之间创建一个关于哪个端口作为预设的开放端口的描述。
真正开放端口是在运行容器的时候，在`docker run`时使用`-p`标记指定开放与映射一个或多个端口，
或者使用`-P`开放所有已设置的端口并将其映射到高级别(high-order)端口。

在主机系统上设置端口重定向，参考[使用-P标记](https://docs.docker.com/engine/reference/run/#expose-incoming-ports)。
`docker network`命令支持创建一个网络，容器可以不暴露或发布指定端口而使用该网络通信，因为容器联结到该网络可以与任意其他端口通信。
详细信息[该特性概览](https://docs.docker.com/engine/userguide/networking/)

# ENV
[Dockerfile`ENT`指令介绍](https://docs.docker.com/engine/reference/builder/#env)

为了使用新的软件更容易运行，可以使用`ENV`为容器中的软件更新`PATH`环境变量，
比如`ENV PATH /usr/local/nginx/bin:$PATH`可以确保`CMD ["nginx"]`正确运行。

`ENV`指令在为服务指供必要的环境变量时也非常有用，比如Postgres的`PGDATA`。

`ENV`也可以用来设置公共的版本号，使得维护版本号变得非常容易：
```dockerfile
ENV PG_MAJOR 9.3
ENV PG_VERSION 9.3.4
RUN curl -SL http://example.com/postgres-$PG_VERSION.tar.xz | tar -xJC /usr/src/postgress && …
ENV PATH /usr/local/postgres-$PG_MAJOR/bin:$PATH
```
类似于程序中的常量（不是硬编码），该方法可以让你通过变更一个`ENV`指令而达到自动变容器中的软件的目的。

# ADD or COPY
[ADD指令介绍](https://docs.docker.com/engine/reference/builder/#add)
[COPY指令介绍](https://docs.docker.com/engine/reference/builder/#copy)

虽然`ADD`与`COPY`功能类似，但通常而言，`COPY`是首选，因为它比`ADD`更透明(transparent)。
`COPY`只支持本地文件到容器的基本复制功能，而`ADD`有一些隐含的特性（如本地tar文件提取、远程URL支持）。
所以`ADD`的最佳使用方法是将本地文件自动提取到镜像，如：`ADD rootfs.tar.xz /.`。

如果Dockerfile中有多个步骤需要使用不同的文件，对每个文件使用`COPY`指令比次复制所有的方法要好。
如果特别的指明了需要依赖文件变化，这将确保每个步骤的构建缓存失效(is only invalidated. 译注：是指即时清除缓存吗？)
```dockerfile
COPY requirements.txt /tmp/
RUN pip install --requirement /tmp/requirements.txt
COPY . /tmp/
```
如果你将`COPY ./tmp/`放在`RUN`之前，会导致`RUN`步骤的缓存失效数减少。
(Results in fewer cache invalidations for the RUN step, than if you put the COPY . /tmp/ before it. 译注：说不太明白)

基于图形大小的考量，强烈建议不要使用`ADD`从远程`URL`上拉取安装包，而应使用`curl`或`wget`代替。
这样你可以删除在解压后不再需要的文件，而不必在镜像中再创建一层。比如，你应该避免如下的方式：
```dockerfile
ADD http://example.com/big.tar.xz /usr/src/things/
RUN tar -xJf /usr/src/things/big.tar.xz -C /usr/src/things
RUN make -C /usr/src/things all
```
而是如此：
```dockerfile
RUN mkdir -p /usr/src/things \
    && curl -SL http://example.com/big.tar.xz \
    | tar -xJC /usr/src/things \
    && make -C /usr/src/things all
```
对于其他不需要的自动提取功能的项（文件、目录），你应该始终使用`COPY`。

# ENTRYPOINT

ENTRYPOINT 有两种形式：
+ `ENTRYPOINT ["executable", "param1", "param2"]` (执行形式，首选)
+ `ENTRYPOINT command param1 param2 (shell form)` (shell 形式)

`ENTRYPOIN`允许你配置容器以何种方式运行，下面例子将使用使用nginx的默认内容启动，并监听80端口：
```dockerfile
docker run -i -t --rm -p 80:80 nginx
```
`docker run <image>`命令行参数将会全部追加到执行形式的`ENTRYPOINT`后，并会覆写`CMD`指令指定的所有元素。
这允许参数传递到入口点(entry point)，如`docker run <image> -d`将会把`-d`参数传递到入口点。
你可以通过`docker run --entrypoint`标记覆写`ENTRYPOINT`指令。

shell形式阻止任何`CMD`与`run`命令行参数，这种方式有一个缺点：`ENTRYPOINT`将会作为`/bin/sh -c`的子命令运行，因而不会传入信号。
这意味着执行程序不会成为容器的`PID 1`，不能收到Unix信号，因而你的执行程序不会收到`docker stop <container>`的终止信号`SIGTERM`。

在Dockerfile中，只有最后一个`ENTRYPOINT`指令才会生效。

### 执行形式 ENTRYPOINT 示例
你可以使用`ENTRYPOINT`的执行形式设置稳定的默认命令与参数，然后使用`CMD`两种形式之一设置可变参数的默认值。
```dockerfile
FROM ubuntu
ENTRYPOINT ["top", "-b"]
CMD ["-c"]
```
运行容器时将会看到`top`是唯一的进程：
```bash
$ docker run -it --rm --name test  top -H
top - 08:25:00 up  7:27,  0 users,  load average: 0.00, 0.01, 0.05
Threads:   1 total,   1 running,   0 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.1 us,  0.1 sy,  0.0 ni, 99.7 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem:   2056668 total,  1616832 used,   439836 free,    99352 buffers
KiB Swap:  1441840 total,        0 used,  1441840 free.  1324440 cached Mem

  PID USER      PR  NI    VIRT    RES    SHR S %CPU %MEM     TIME+ COMMAND
    1 root      20   0   19744   2336   2080 R  0.0  0.1   0:00.04 top
```
可以使用`docker exec`查看更多结果：
```bash
$ docker exec -it test ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  2.6  0.1  19752  2352 ?        Ss+  08:24   0:00 top -b -H
root         7  0.0  0.1  15572  2164 ?        R+   08:25   0:00 ps aux
```
你可以使用`docker stop test`优雅的停止`top`进程。

下面Dockerfile展示了使用`ENTRYPOINT`使用`FOREGROUND`运行Apache。
```dockerfile
FROM debian:stable
RUN apt-get update && apt-get install -y --force-yes apache2
EXPOSE 80 443
VOLUME ["/var/www", "/var/log/apache2", "/etc/apache2"]
ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
```

如果你需要为某个可执行程序书写一个启动器，你需要确保最终执行程序能接收从`exec`与`gosu`命令发出Unix信号：
```bash
#!/usr/bin/env bash
set -e

if [ "$1" = 'postgres' ]; then
    chown -R postgres "$PGDATA"

    if [ -z "$(ls -A "$PGDATA")" ]; then
        gosu postgres initdb
    fi

    exec gosu postgres "$@"
fi

exec "$@"
```

如果你需要在停止的时候做一些特别的清理（或与其他容器通信），或是协调多个执行程序，你可能需要确保`ENTRYPOINT`脚本能接收Unix信号，
通过他们做一些事情：
```bash
#!/bin/sh
# 注：该脚本使用sh书写，所以也可以运行在busybox容器中

# 如果服务停止后你还需要手动做一些清理工作，请使用trap命令。
# 或者需要在一个容器中启动多个服务
trap "echo TRAPed signal" HUP INT QUIT TERM

# 启动一个服务在后台运行
/usr/sbin/apachectl start

echo "[hit enter key to exit] or run 'docker stop <container>'"
read

# 停止服务并清理
echo "stopping apache"
/usr/sbin/apachectl stop

echo "exited $0"
```
如果使用`docker run -it --rm -p 80:80 --name test apache`运行该镜像，可以使用`docker exec`查看容器进程，
或使用`docker stop`后要求脚本停止Apache:
```bash
$ docker exec -it test ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.1  0.0   4448   692 ?        Ss+  00:42   0:00 /bin/sh /run.sh 123 cmd cmd2
root        19  0.0  0.2  71304  4440 ?        Ss   00:42   0:00 /usr/sbin/apache2 -k start
www-data    20  0.2  0.2 360468  6004 ?        Sl   00:42   0:00 /usr/sbin/apache2 -k start
www-data    21  0.2  0.2 360468  6000 ?        Sl   00:42   0:00 /usr/sbin/apache2 -k start
root        81  0.0  0.1  15572  2140 ?        R+   00:44   0:00 ps aux
$ docker top test
PID                 USER                COMMAND
10035               root                {run.sh} /bin/sh /run.sh 123 cmd cmd2
10054               root                /usr/sbin/apache2 -k start
10055               33                  /usr/sbin/apache2 -k start
10056               33                  /usr/sbin/apache2 -k start
$ /usr/bin/time docker stop test
test
real	0m 0.27s
user	0m 0.03s
sys	0m 0.03s
```

> 注：可以使用`--entrypoint`覆写`ENTRYPOINT`配置，但是只能设置执行的二态(binary，译注：不理解)。

> 注：执行形式将会解析为JSON数组，所以命令需要包在双引号内，单引号不行。

> 注：与shell形式不同，执行形式不会调用shell程序，不会发生正常的shell程序处理。
  如`ENTRYPOINT [ "echo", "$HOME" ]`不会在`$HOME`上发生变量替换。如果你希望shell处理程序生效，你可以使用shell形式或直接执行shell程序。
  如`ENTRYPOINT [ "sh", "-c", "echo $HOME" ]`，当你使用执行形式或直接执行shell，与shell形式一样，是由正在执行环境变量扩展的shell在处理，而不是docker。

### shell形式`ENTRYPOINT`例子
你可以为`ENTRYPOINT`指定一个纯字符串作为其值，这将会运行在`/bin/sh -c`中。shell形式使用shell程序替换shell环境变量，
并且会忽略所有`CMD`与`docker run`命令行参数。为了确保`docker stop`能正确的发送信号给长时间运行的程序，你需要使用`exec`启动程序：
```dockerfile
FROM ubuntu
ENTRYPOINT exec top -b
```
运行后你可以看到一个`PID1`进程：
```bash
$ docker run -it --rm --name test top
Mem: 1704520K used, 352148K free, 0K shrd, 0K buff, 140368121167873K cached
CPU:   5% usr   0% sys   0% nic  94% idle   0% io   0% irq   0% sirq
Load average: 0.08 0.03 0.05 2/98 6
  PID  PPID USER     STAT   VSZ %VSZ %CPU COMMAND
    1     0 root     R     3164   0%   0% top -b
```
运行`docker stop`时会干净利落的退出：
```bash
$ /usr/bin/time docker stop test
test
real	0m 0.20s
user	0m 0.02s
sys	0m 0.04s
```
如果你忘记了在`ENTRYPOINT`开始处使用`exec`
```dockerfile
FROM ubuntu
ENTRYPOINT top -b
CMD --ignored-param1
```
运行后(为了下面步骤，指定一个name)：
```bash
$ docker run -it --name test top --ignored-param2
Mem: 1704184K used, 352484K free, 0K shrd, 0K buff, 140621524238337K cached
CPU:   9% usr   2% sys   0% nic  88% idle   0% io   0% irq   0% sirq
Load average: 0.01 0.02 0.05 2/101 7
  PID  PPID USER     STAT   VSZ %VSZ %CPU COMMAND
    1     0 root     S     3168   0%   0% /bin/sh -c top -b cmd cmd2
    7     1 root     R     3164   0%   0% top -b
```
从输出内容可以看到并不是`PID 1`

当运行`docker stop test`时，该容器并没有直接退出，`stop`命令会在超时后强制发送`SIGKILL`。
```bash
$ docker exec -it test ps aux
PID   USER     COMMAND
    1 root     /bin/sh -c top -b cmd cmd2
    7 root     top -b
    8 root     ps aux
$ /usr/bin/time docker stop test
test
real	0m 10.19s
user	0m 0.04s
sys	0m 0.03s
```

### 理解CMD与ENTRYPOINT相互影响
`CMD`与`ENTRYPOINT`指令都是定义一个容器运行时执行的命令，下面有一些规则描述他们之间的协作。

1. Dockerfile应该在结尾定义一个`CMD`或`ENTRYPOINT`
2. 当容器作为一个可执行程序时，应该定义`ENTRYPOINT`
3. `CMD`应该用来作为定义`ENTRYPOINT`的默认参数，或者在容器中执行点对点(ad-hoc)的命令
4. 在容器启动时，`CMD`将会被其他替代参数覆写

下面表格展示了`ENTRYPOINT`与`CMD`组合时，什么命令会被执行：

|                            | No ENTRYPOINT              | ENTRYPOINT exec_entry p1_entry | ENTRYPOINT ["exec_entry", "p1_entry"]          |
| -------------------------- | -------------------------- | ------------------------------ | ---------------------------------------------- |
| No CMD                     | error, not allowed         | /bin/sh -c exec_entry p1_entry | exec_entry p1_entry                            |
| CMD [“exec_cmd”, “p1_cmd”] | exec_cmd p1_cmd            | /bin/sh -c exec_entry p1_entry | exec_entry p1_entry exec_cmd p1_cmd            |
| CMD [“p1_cmd”, “p2_cmd”]   | p1_cmd p2_cmd              | /bin/sh -c exec_entry p1_entry | exec_entry p1_entry p1_cmd p2_cmd              |
| CMD exec_cmd p1_cmd        | /bin/sh -c exec_cmd p1_cmd | /bin/sh -c exec_entry p1_entry | exec_entry p1_entry /bin/sh -c exec_cmd p1_cmd |

# VOLUME
```dockerfile
VOLUME ["/data"]
```

`VOLUME`指令创建一个具有指定全称的挂载点，将其标记为从本地主机或其他容器联结到容器挂载卷（译注：这句有点不通顺）。
其值可以是JSON数组：`VOLUME ["/var/log/"]`，或者包含多个参数的纯字符串，如：`VOLUME /var/log` 或 `VOLUME /var/log /var/db`。
Docker客户端的更多信息、示例及挂载相关指令，参考[使用Volumes共享目录](https://docs.docker.com/engine/tutorials/dockervolumes/#/mount-a-host-directory-as-a-data-volume)文档。

Docker `run`命令使用镜像中指定位置的所有数据初始化新创建的卷，考虑如下Dockerfile片段：
```dockerfile
FROM ubuntu
RUN mkdir /myvol
RUN echo "hello world" > /myvol/greeting
VOLUME /myvol
```
运行`docker run`，该镜像会在`/myvol`上创建一个新的挂载点，并且复制`greeting`文件到新创建的卷上。

### 指定卷应该注意：
+ 基于windows的容器的卷：容器卷的标的必须是如下情况之一：
  + 一个不存在或空目录
  + C盘之外的驱动器(drive，译注：是否是指C盘外的盘才能做为Volume？由于译者没有windows环境，所以没做测试)
+ 在Dockerfile中更改卷：如果在某些步骤在卷声明之后修改了卷，这些修改会被丢弃。
+ JSON格式：指令将会被解析为JSON数组，所以需要使用双引号将参数括起来
+ 主机目录在容器运行时声明：主机目录(mountpoint)本质上是与主机相关的，这是为了维持镜像的可移值性。
  因为给定的目录不能保证在所有的主机上可用，因此你无法从Dockerfile中挂载主机目录。
  `VOLUME`指令不支持指定`host-dir`参数。在创建或运行容器时必须指定挂载点。

# USER
```dockerfile
USER <user>[:<group>] or
USER <UID>[:<GID>]
```
`USER`指令设置用户名(或UID)和可选的运行镜像时、以及Dockerfile中随后的`RUN`,`CMD`和`ENTRYPOINT`指令使用的用户组(或GID)。

> __警告：__ 当用户没有所属组时(does doesn’t have a primary group)，镜像将会使用root组运行。

# WORKDIR
```dockerfile
WORKDIR /path/to/workdir
```
`WORKDIR`为Dockerfile中随后的`RUN`,`CMD`,`ENTRYPOINT`,`COPY`与`ADD`指令提供工作目录。
如果`WORKDIR`不存在，即使在随后的指令中并没有使用它，工作目录也会被创建。

`WORKDIR`指令可以在Dockerfile中出现多次，如果设置了一个相对路径，它会相对于上一个`WORKDIR`指令，如:
```dockerfile
WORKDIR /a
WORKDIR b
WORKDIR c
RUN pwd
```
该Dockerfile中最终的pwd的结果为`/a/b/c`

`WORKDIR`可以解析在此之前使用`ENV`设置的环境变量，你只能使用在Dockerfile中显示设置的环境变量，如：
```dockerfile
ENV DIRPATH /path
WORKDIR $DIRPATH/$DIRNAME
RUN pwd
```
该Dockerfile中最终pwd结果为`path/$DIRNAME`

# ARG
```dockerfile
ARG <name>[=<default value>]
```
`ARG`指令定义了一个变量，用户可以在使用`docker build`命令构建时添加`--build-arg <varname>=<value>`标志传递给构建器(builder)。
如果用户指定了在Dockerfile中未定义的构建参数，则构建会输出警告。
```docckerfile
[Warning] One or more build-args [foo] were not consumed.
```
一个Dockerfile中可以包含一个或多个`ARG`，以下的Dockerfile是合法的：
```dockerfile
FROM busybox
ARG user1
ARG buildno
...
```

> __警告：__ 不建议使用构建时变量来传递安全相关信息，比如github keys，用户凭证等。
  因为任何用户都可以使用`docker history`命令看到构建时的变量值。

### 默认值
`ARG`指令可以设置一个默认值：
```dockerfile
FROM busybox
ARG user1=someuser
ARG buildno=1
...
```
如果一个`ARG`指令有默认值，在构建时如果没有传入它的值时，构建器将会使用默认值。

### 作用域
`ARG`变量定义从它在Dockerfile中定义的行开始生效，而不是在命令行或其他地方使用参数。思考如下Dockerfile:
```dockerfile
1 FROM busybox
2 USER ${user:-some_user}
3 ARG user
4 USER $user
...
```
一个用户使用如下方式构建：
```bash
$ docker build --build-arg user=what_user .
```

第2行计算结果为`some_user`，因为`user`是在第3行定义的(译注：此时`ARG`参数还没生效呢)，
第4行`USER`计算结果为`what_user`，因为此时`user`已经定义(译注：在第3行)，并且从命令行传入了`what_user`值。
在`ARG`指令定义变量之前，任何使用变量的行为都会得到空字符串。

`ARG`指令在其定义的构建阶段结束时失效(out of scope)，要在多个阶段使用参数，需要在每个阶段包含`ARG`指令。

```dockerfile
FROM busybox
ARG SETTINGS
RUN ./run/setup $SETTINGS

FROM busybox
ARG SETTINGS
RUN ./run/other $SETTINGS
```

### 使用ARG变量
你可以使用`ARG`或`ENV`指令来指定可用于`RUN`指令的变量，使用`ENV`指令定义的环境变量总是覆盖相同名称的`ARG`指令定义的变量。
考虑下面这个包含一个`ARG`与`ENV`指令的Dockerfile:
```dockerfile
1 FROM ubuntu
2 ARG CONT_IMG_VER
3 ENV CONT_IMG_VER v1.0.0
4 RUN echo $CONT_IMG_VER
```
假设使用如下命令构建该镜像：
```bash
$ docker build --build-arg CONT_IMG_VER=v2.0.1 .
```
该情况下，`RUN`指令使用`v1.0.0`替代用户传入的`v2.0.1`。该行为类似于shell脚本中本地作用域变量将覆盖作为参数传入的变量或他处继承的变量。

在上面的例子使用不同的`ENV`指定值，你可以在`ARG`与`ENV`指令之间创建更有用的交互：
```dockerfile
1 FROM ubuntu
2 ARG CONT_IMG_VER
3 ENV CONT_IMG_VER ${CONT_IMG_VER:-v1.0.0}
4 RUN echo $CONT_IMG_VER
```
不同于`ARG`，`ENV`的始终存在于构建镜像中，思考不使用`--build-arg`标识:
```bash
$ docker build .
```
该例中`CONT_IMG_VER`仍然存在镜像中，但是其值为`-v1.0.0`，因为取的是第3行设置的默认值。

此示例中的变量扩展技术允许你从命令行传递参数，并通过使用`ENV`指令将它们一直保存在最终镜像中，变量扩展只支持部份Dockerfile指令。

### 预定义ARG
Docker有一组预定义`ARG`变量，你可以直接使用而不必使用相应的`ARG`指令声明：
+ HTTP_PROXY
+ http_proxy
+ HTTPS_PROXY
+ https_proxy
+ FTP_PROXY
+ ftp_proxy
+ NO_PROXY
+ no_proxy

可以在命令行中使用标识传入它们的值：
```bash
--build-arg <varname>=<value>
```
默认情况下，这些预定义变量排除在`docker history`输出之外，排队它们降低了在`HTTP_PROXY`变量中意外泄露敏感认证信息的风险。

考虑使用`--build-arg HTTP_PROXY=http://user:pass@proxy.lon.example.com`构建如下Dockerfile:
```dockerfile
FROM ubuntu
RUN echo "Hello World"
```
在这种情况下，`HTTP_PROXY`变量的值在`docker history`中不可用，也不会缓存。如果你想修改地址，
并且你的代理服务器改为`http://user:pass@proxy.sfo.example.com`，不会导致后续的构建发生缓存遗漏(cache miss)。

如果你想覆盖此行为，你可以通过添加`ARG`声明：
```dockerfile
FROM ubuntu
ARG HTTP_PROXY
RUN echo "Hello World"
```
构建该Dockerfile时，`HTTP_PROXY`将保留在`docker history`中，并且更该值会使构建缓存失效。

### 对构建缓存的影响
因为`ENV`的存在，`ARG`变量不会保留在构建镜像中。然而`ARG`变量会以类似方式影响构建缓存。
如果Dockerfile定义了一个`ARG`变量，其值与此前构建时的值不同，那么在第一次使用时将会出现`缓存遗漏(cache miss)`。
具体而言，`ARG`指令之后的所有`RUN`指令隐含的(作为环境变量)使用`ARG`变量，因而会可以引发缓存遗漏。
所有的预定义指令都不会缓存，除非在Dockerfile中有其声明。

考虑如下两个Dockerfile
```dockerfile
1 FROM ubuntu
2 ARG CONT_IMG_VER
3 RUN echo $CONT_IMG_VER
```
```dockerfile
1 FROM ubuntu
2 ARG CONT_IMG_VER
3 RUN echo hello
```
如果在命令行中指定`--build-arg CONT_IMG_VER=<value>`，两种情况下，第2行指令不会导致缓存遗漏，第3行将会发生缓存遗漏。
`ARG CONT_IMG_VER`导致`RUN`所在的行识别为与运行`CONT_IMG_VER=<value>` echo hello相同。所以，如果`<value>`发生了变化，将会出现缓存遗漏。

考虑如下示例在相同命令下运行：
```dockerfile
1 FROM ubuntu
2 ARG CONT_IMG_VER
3 ENV CONT_IMG_VER $CONT_IMG_VER
4 RUN echo $CONT_IMG_VER
```
该例中，缓存遗漏发生在第3行。因为`EVN`中的变量的值引用了`ARG`变量，并且使用命令行使该值发生了变化，所以发生了遗漏。
此例中`ENV`命令便镜像包含该值。

如果`ENV`指令覆写了同类`ARG`指令，如：
```dockerfile
1 FROM ubuntu
2 ARG CONT_IMG_VER
3 ENV CONT_IMG_VER hello
4 RUN echo $CONT_IMG_VER
```
第3行不会发生缓存遗漏，因为`CONT_IMG_VER`的值为常量(hello)，因此在`RUN`(第4行)上使用的环境变量和值在构建时不会改变。

# ONBUILD

`ONBUILD`指令向镜像添加一个`触发器(trigger)`指令，当该镜像作为其他构建的基础镜像时，
该触发器会在下游构建的context中执行，就像它直接插入到下游Dockerfile中`FROM`指令后面一样。

任何指令都可以注册一个触发器。

如果你的构建镜像将用作其他镜像的基础构建，这会非常有用。
比如可以通过用户指定的配置自定义的应用程序的构建环境或守护进程。

比如：如果你的镜像是一个可复用的Python应用程序构建器，那么需要将应用的源码添加到指定的目录。
并且在之后可能需要调用构建脚本。此时你无法调用`ADD`与`RUN`指令，因为此时你还不知道应用程序源码，
并且每个应用构建都会不同。你可以简单的为开发人员提供一个Dockerfile样板，复制到各自的应用程序中。
但由于它与特定的应用代码混合，因此效率低下，容易出错并且难以更新维护。

解决方案是使用`ONBUILD`注册高级指令到运行后、下一个构建阶段之前。

工作原理：
1. 当遇到`ONBUILD`指令时，构建器添加一个触发器到正在构建镜像的元数据上，该指令不会影响当前构建。
2. 构建结束时，所有的触发器列表存储在镜像的清单的`OnBuild`键下，可以使用`docker inspect`命令查看。
3. 稍后可能使用`FROM`指令将该镜像作为一个新构建的基础，作为`FROM`指令处理的一部，下游构建器将会查找`ONBUILD`的触发器，
   并按其注册顺序执行。如果某一触发器执行失败，`FROM`指令将会退出从而导致构建失败，
   如果所有的触发器都成功执行，`FROM`指令完成并继续构建过程。
4. 触发器会在最终镜像执行完成后清除。(译注：后面还有一句不知如何翻译: In other words they are not inherited by “grand-children” builds.)

例如，你可能添加如下内容：
```dockerfile
[...]
ONBUILD ADD . /app/src
ONBUILD RUN /usr/local/bin/python-build --dir /app/src
[...]
```
> __警告：__ 不能使用`ONBUILD ONBUILD`链接`ONBUILD`指令

> __警告：__ `ONBUILD`指令可能不触发`FROM`或`MAINTAINER`指令

# STOPSIGNAL
```dockerfile
STOPSIGNAL signal
```
`STOPSIGNAL`指令设置发送到容器使其退出的系统调用号，该信号可以是一个与系统调用表相匹配的无符号数字，比如9，
或者是一个`SIGNAME`格式的信号名称，如`SIGKILL`。

# HEALTHCHECK
`HEALTHCHECK`有两种形式：
+ `HEALTHCHECK [OPTIONS] CMD command` 通过在容器内运行命令来检查容器的健康状况
+ `HEALTHCHECK NONE` 禁用所有从基础镜像继承来的 healthcheck

`HEALTHCHECK`指令告诉容器如何检测一个容器能正常工作，比如可以检测一个web服务是否卡在一个无限循环中，
从而不能处理新的连接请求，即使该服务处理进程还在运行，也可以进行检测。

当一个容器指定了了`healthcheck`时，它除了正常状态外，还有一个健康状态，该状态最初是`staring`(译注：原文:This status is initially staring)。
每当一个健康检测通过时，无论之前的状态是什么，该状态都会变为`healthy`，经过一定次数的连续失败后，该状态变为`unhealthy`。

`CMD`之前的`OPTIONS`的值可以为：
+ `--interval=DURATION` (default: 30s)
+ `--timeout=DURATION` (default: 30s)
+ `--start-period=DURATION` (default: 0s)
+ `--retries=N` (default: 3)

健康检查在容器启动后`interval`秒开始首次运行，每次检测完之后，隔`interval`秒后再次检测。

如果单次健康检测耗时超过`timeout`，则认为检测失败。

如果容器健康检测连续`retries`次失败，则认为容器为`unhealthy`。

启动时间为容器初始化的时间，在此期间检测到的失败不计入最大重试次数。但是，如果健康检测在开始其间成功，
则认为容器已启动，并且所有连续的失败将计入最大重试数中。

一个Dockerfile中只能有一个`HEALTHCHECK`指令，如果你列出了多个，只有最后一个生效。

`CMD`之后的命令可以是shell命令(如：HEALTHCHECK CMD /bin/check-running)或执行形式数组(同Dockerfile其他命令一样，比如[ENTRYPOINT](#entrypoint))。

命令的退退出状态标明容器的运行状态，可能的值为：
+ `0: success` 容器健康，可以使用
+ `1: unhealthy` 容器运行不正常
+ `2: reserved` 保留退出码，不要使用该退出码

比如，每隔五分钟左右检测网站服务能够在3秒内提供其主页面：
```dockerfile
HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost/ || exit 1
```

为了debug失败原因，命令在stdout或stderr上输出的任何内容(utf-8编码)都会存在健康状态里，
并且可以通过`docker inspect`查询。此类输出应该保持短小(仅存储输出的前4096个字节)。

当容器的健康状态发生变化时，将会使用新的状态生成一个`health_status`事件。

`HEALTHCECK`在Docker 1.12版本中加入。

# SHELL
```dockerfile
SHELL ["executable", "parameters"]
```
`SHELL`指令使shell形式命令使用的的默认shell可以被覆盖，默认shell在Linux上为`["/bin/sh", "-c"]`，
Windows上为`["cmd", "/S", "/C"]`，Dockerfile中的`SHELL`指令必须使用JSON形式书写。

`SHELL`指令在Windows上特别有用，Windows中有两个常用的但差别非常大的原生shell：`cmd`与`powershell`，
以及包含`sh`的备用shell。

`SHELL`指令可以出现多闪，每个`SHELL`指令覆写之前所有的`SHELL`指令，并且影响其后的所有指令。如：
```dockerfile
FROM microsoft/windowsservercore

# 执行 cmd /S /C echo default
RUN echo default

# 执行 cmd /S /C powershell -command Write-Host default
RUN powershell -command Write-Host default

# 执行 powershell -command Write-Host hello
SHELL ["powershell", "-command"]
RUN Write-Host hello

# 执行 cmd /S /C echo hello
SHELL ["cmd", "/S"", "/C"]
RUN echo hello
```
`RUN`, `CMD`和`ENTRYPOINT`指令的shell形式会受`SHELL`指令影响。

下面的示例是在Windows查找可以使用`SHELL`流化(streamlined)的常见模式：
> 原文：
> The following example is a common pattern found on Windows which can be streamlined by using the SHELL instruction:

```dockerfile
...
RUN powershell -command Execute-MyCmdlet -param1 "c:\foo.txt"
...
```
docker调用该命令结果为：
```dockerfile
cmd /S /C powershell -command Execute-MyCmdlet -param1 "c:\foo.txt"
```

导致无效有两个原因，其一，有个不必要的`cmd.exe`命令处理器(又称shell)被调用。
其二，每个shell形式的`RUN`指令需要在命令前添加一个额外的`powershell -command`前缀。

要使期有效，有两种机制可用，其一是使用`RUN`命令的JSON形式：
```dockerfile
...
RUN ["powershell", "-command", "Execute-MyCmdlet", "-param1 \"c:\\foo.txt\""]
...
```
虽然使用JSON形式可以提供明确的指令，并且不会使用不必要的`cmd.exe`，但它需要使用双引号与转义，因而变得冗长。
替代机制是使用`SHELL`指令和shell形式，为Windows用户提供更接近原有的语法，在与`escape`解析指令结合使用是更为明显：
```dockerfile
# escape=`

FROM microsoft/nanoserver
SHELL ["powershell","-command"]
RUN New-Item -ItemType Directory C:\Example
ADD Execute-MyCmdlet.ps1 c:\example\
RUN c:\example\Execute-MyCmdlet -sample 'hello world'
```
结果为：
```dockerfile
PS E:\docker\build\shell> docker build -t shell .
Sending build context to Docker daemon 4.096 kB
Step 1/5 : FROM microsoft/nanoserver
 ---> 22738ff49c6d
Step 2/5 : SHELL powershell -command
 ---> Running in 6fcdb6855ae2
 ---> 6331462d4300
Removing intermediate container 6fcdb6855ae2
Step 3/5 : RUN New-Item -ItemType Directory C:\Example
 ---> Running in d0eef8386e97


    Directory: C:\


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d-----       10/28/2016  11:26 AM                Example


 ---> 3f2fbf1395d9
Removing intermediate container d0eef8386e97
Step 4/5 : ADD Execute-MyCmdlet.ps1 c:\example\
 ---> a955b2621c31
Removing intermediate container b825593d39fc
Step 5/5 : RUN c:\example\Execute-MyCmdlet 'hello world'
 ---> Running in be6d8e63fe75
hello world
 ---> 8e559e9bf424
Removing intermediate container be6d8e63fe75
Successfully built 8e559e9bf424
PS E:\docker\build\shell>
```

`SHELL`指令也可以用于修改shell操作方式，例如，在Windows上使用`HELL cmd /S /C /V:ON|OFF`，
可以修改延时的环境变量扩展语义(原文：delayed environment variable expansion semantics could be modified. 译者不明白这个命令做什么的)。

`SHELL`指也可以在Linux上使用替换shell，如`zsh`，`csh`,`tcsh`等。

`SHELL`在Docker 1.12版本中引入。

# Dockerfile 示例
下面你可以看到一些Dockerfile语法的例子，如果你对更真实的内容感兴趣，请查看[Docker化示例](https://docs.docker.com/engine/examples/)。
```dockerfile
# Nginx
#
# VERSION               0.0.1

FROM      ubuntu
LABEL Description="This image is used to start the foobar executable" Vendor="ACME Products" Version="1.0"
RUN apt-get update && apt-get install -y inotify-tools nginx apache2 openssh-server
```

```dockerfile
# Firefox over VNC
#
# VERSION               0.3

FROM ubuntu

# Install vnc, xvfb in order to create a 'fake' display and firefox
RUN apt-get update && apt-get install -y x11vnc xvfb firefox
RUN mkdir ~/.vnc
# Setup a password
RUN x11vnc -storepasswd 1234 ~/.vnc/passwd
# Autostart firefox (might not be the best way, but it does the trick)
RUN bash -c 'echo "firefox" >> /.bashrc'

EXPOSE 5900
CMD    ["x11vnc", "-forever", "-usepw", "-create"]
```

```dockerfile
# Multiple images example
#
# VERSION               0.1

FROM ubuntu
RUN echo foo > bar
# Will output something like ===> 907ad6c2736f

FROM ubuntu
RUN echo moo > oink
# Will output something like ===> 695d7793cbe4

# You'll now have two images, 907ad6c2736f with /bar, and 695d7793cbe4 with
# /oink.
```