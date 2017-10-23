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
$docker build -t shykes/myapp:1.0.2 -t shykes/myapp:laest .
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
如果该文件存丰，docker CLI将会修改context，使其排除该文件中匹配的文件目录。
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
| # comment      | 注释、忽略 |
| */temp*        | 排除根目录中的`直接`子目录中任何以`temp`开头的文件或目录，比如文件`/somedir/temporary.txt`、目录`/somedir/temp` |
| */*/temp*      | 排除根目录中的`二级`子目录内的以`temp`开头的文件或目录，比如 `/somedir/subdir/temporary.txt` |
| temp?          | 排除根目录中名称为`temp`后跟一个字符的文件或目录，比如`/tempa`或`/tempb` |


Matching is done using Go’s filepath.Match rules. A preprocessing step removes leading and trailing whitespace and eliminates
 . and .. elements using Go’s filepath.Clean. Lines that are blank after preprocessing are ignored.
 
匹配使用Go的[filepath.Match](http://golang.org/pkg/path/filepath#Match)规则，预处理步骤中将会删除开头与结尾的空白符，
使用[filepath.Clean](http://golang.org/pkg/path/filepath/#Clean)清除`.`与`..`元素元素。预处理后的空白行将会被忽略。

除了Go的filepath.Match规则之外，Docker还支持一个特殊的通配符`**`，用来匹配任意数量的目录，包括没有目录(including zero)。
比如`**/*.go`将会排除context根目录下所以有`.go`结尾的文件。

Lines starting with ! (exclamation mark) can be used to make exceptions to exclusions. 
The following is an example .dockerignore file that uses this mechanism:

一行以!（感叹号）开头可以用来标识例外的情况，下面是一个使用该机制的例子：
```
*.md
!README.md
```
排除除了`README.md`之外的所有`md`文件。

The placement of ! exception rules influences the behavior: the last line of the 
.dockerignore that matches a particular file determines whether it is included or excluded. Consider the following example:

!符号不同位置的影响：