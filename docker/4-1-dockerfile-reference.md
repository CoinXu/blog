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
|     Rule       | Behavior   |
| -------------- | ------     |
| # comment      | 注释、忽略  |
| */temp*        | 排除根目录中的`直接`子目录中任何以`temp`开头的文件或目录，比如文件`/somedir/temporary.txt`、目录`/somedir/temp` |
| */*/temp*      | 排除根目录中的`二级`子目录内的以`temp`开头的文件或目录，比如 `/somedir/subdir/temporary.txt` |
| temp?          | 排除根目录中名称为`temp`后跟一个字符的文件或目录，比如`/tempa`或`/tempb` |

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
+ `CMD ["param1","param2"]` 作为入口点(`ENTRYPOINT`)的默认参数
+ `CMD command param1 param2` shell命令形式

一个Dockerfile中只能出现一次`CMD`指令，如果出现多次，只有最后一次出现的起作用。

`CMD`一个主要目的是为一个执行容器提供默认值，该值可以包含可执程序，也可以省略，如果省略了，你需要指一个`ENTRYPOINT`指令。

> __注：__ 如果`CMD`用来为`ENTRYPOINT`指令提供默认参数，`CMD`与`ENTRYPOINT`指令都要符合JSON数组格式。
> __注：__ 执行形式将会解析为JSON格式数组，所以你必须使双引号来包裹语句，而非单引号。
> __注：__ 与shell形式不同，执行形式不会调用shell程序，不会发生正常的shell程序处理。
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
如果你希望容器每次执行同样的程序，那么你应该考虑`ENTRYPOINT`与`CMD`结合使用，详见[ENTRYPOINT](https://docs.docker.com/engine/reference/builder/#entrypoint)

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
