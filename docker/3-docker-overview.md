# 概述
[https://docs.docker.com/engine/docker-overview/](https://docs.docker.com/engine/docker-overview/)

Docker 是一个为开发、传递和运行应用的开放平台。Docker 可以使你的应用与基础设施分离，
所以你可以快速的交付软件而不必折腾各种环境。利用Docker你可以像管理你的应用一样管理基础设施。
使用Docker快速传递、测试和部署代码，可以大大减少编写代码到运行代码之间的时间延迟。

# Docker 平台
Docker 提供打包、运行应用在一个松散隔离环境中的能力，这个环境称之为容器(container)。
容器的隔离性与安全性允许你在同一主机中同时运行多个容器。容器是非常轻量的，因为它们不需要管理额外的负载，
而是直接运行主机内核中。这意味着在特定的环境中，相比虚拟机，你可以运行更多的容器。你甚至可以在虚拟机中运行容器。

Docker 提供工具和平台用于管理容器的生命周期：

1. 使用容器开发应用程序及其支持组件
2. 容器成为部署和测试应用的基本单元
3. 准备就绪后，部署应用到生产环境中作为，作为容器或协调服务。
   无论你的生产环境是本地数据中心、云服务提供商或二者混合，都无差别。

# Docker 引擎

Docker 引擎是一个客户端-服务端应用，提供以下主要部件：

+ 一个称之为守护进程的长时间运行程序 (`dockerd`命令)
+ 一个指定的RSET API接口用于与守护进程通信并指示守护进程做什么
+ 一个命令行客户端(CLI)

<img src="./engine-components-flow.png">

CLI使用REST API通过脚本或直接使用CLI命令控制Docker或与Docker通信。
许多其他Docker应用程序都使用这个底层的API和命令。

> __注__: Docker 使用Apache 2.0开源协议

# 能用Docker做什么？
[https://docs.docker.com/engine/docker-overview/#what-can-i-use-docker-for](https://docs.docker.com/engine/docker-overview/#what-can-i-use-docker-for)

+ 快速、一致地交付你的应用
+ 响应式部署与扩展
+ 在同样的硬件环境中运行更多的工作负载

# Docker 架构
Docker使用客户端-服务端架构。Docker客户端与守护进程通信。Docker客户端与守护进程可以运行在同一系统上。
你也可以连接一个远程Docker守护进程。Docker客户端使用UNIX sockets或者网络接口通过REST API与守护进程通信。

<img src="./architecture.svg">

### Docker 守护进程
Docker 守护进程监听Docker API请求，管理Docker对象，如：镜像、容器、网络和数组卷。
也可以与其他守护进程通信管理Docker服务。

### Docker 客户端
Docker客户端是许多Docker用户与Docker交互的主要方式。当你使用Docker命令，比如`docker run`时，
客户端发送命令到`dockerd`。`docker`命令使用Docker API。Docker客户端可以与多个守护进程通信。

### Docker 仓库
Docker 仓库存储Docker镜像。任何人都可以在公共的仓库Docker Hub与Docker Cloud上注册。
Docker默认在Docker Hub上查找镜像，你甚至可以运行自己私有的服务。
如果你使用Docker Datacenter(DDC)，它包含了Docker Trusted Registry(DTR)。

当你使用`docker pull`或`docker run`命令时，将会从你配置的仓库上拉取所需的镜像。
当你使用`docker push`命令时，镜像将会推送到你所配置的仓库。

你可以在[Docker store](https://store.docker.com/)上购买、发售或者免费发布Docker镜像。
例如：你可以从软件供应商处购买包含应用或服务镜像，部署应用到你的测试、staging(不知道如何翻译)与生产环境中。
你可以通过拉取镜像新版本更新镜像并重新部署以更新应用。

# Docker 对象
使用Docker时，你将会创建并使用镜像、容器、网络、数据卷、插件与其他对象，该节简要介绍这些对象。

### 镜像(IMAGES)
镜像是一个创建容器说明只读模版。镜像一般都依赖于其他镜像，并在上面附加一些定制的内容。
比如，你可能需要创建一个基于`ubuntu`的镜像，并安装`Apache` web服务和你的应用，
以及运行应用程序所需要的详细配置。

你可以使用私有镜像，也可以只使用其他人创建并发布在Docker仓库上的公共镜像。
创建私有镜像需要创建一个具有简单语法的`Dockerfile`，用于定义创建并运行镜像所需的步骤。
`Dockerfile`中的每一步将会在镜像中创建一个层级(layer)。当`Dockerfile`发生变化并重新生成镜像时，
只有发生变化的层级将会重新构建。这是镜像与其他虚拟化技术相比更轻量、小巧、快速的原因之一。

### 容器(CONTAINERS)
容器是一个可以运行的镜像实例。你可以通过Docker API或CLI创建、运行、停止、移除或删除一个容器。
你可以将容器联结到一个或多个网络、为其添加存储层，甚至可以基于容器当前状态创建一个新的镜像。

默认情况下，容器与其他容器、所在的主机相对较好的隔离。
你可以控制容器的网络、存储或其他低层子系统如何与其他容器或主机之间的隔离。

容器通过其镜像以及在启动或创建时提供的配置参数来定义。当一个容器被移除时，所有未存储在持久层的数据都会消失不见。

### `docker run` 命令示例
以下命令运行一个`ubuntu`容器，在本地命令行窗口增加提供交互会话，并运行`/bin/bash`
```bash
docker run -t -t ubuntu /bin/bash
```
运行该命令时，将发生以下情况(确保你使用的是默认的Docker仓库配置)：

1. 如果你本地没有`ubuntu`镜像，Docker会从仓库中将其下载至本地，相当于手动运行`docker pull ubuntu`命令。
2. Docker创建一个新的容器，相当于手动运行`docker create`命令
3. Docker为该容器分配读-写文件系统作为其最后一层(layer)，这允许容器在其本地文件系统(local filesystem)中创建或修改文件和目录。
4. 由于该命令没有指明网络配置，所以Docker创建一个网络接口联结容器到默认网络。
   其中就包含了为容器分配一个IP地址的行为。默认情况下，容器可以使用主机的网络联结到外部网络。
5. Docker启动容器并执行`/bin/bash`。由于容器是在终端上以交互方式运行(因为命令中指定了`-i`与`-t`)，
   所以你可以在终端上输入内容并显示结果。
6. 当你输入`exit`命令时，容器会停止运行，但不会移除。你可以再次启动或移除容器。

### SERVICES
Services 允许你跨过(across)多过Docker守护进程扩展容器，这些守护进程在多个管理与工作人员控制下以一个集群的方式运行。
集群中的每一个成员都是一个守护进程(哎，这样翻译不对吧，好扯淡...)，并且这些守护进程可以使用Docker API互相通信。
Services 允许你定义所需的状态，比如在指定的时间内可用服务的副本数。默认情况下，service 所有的节点中是负载均衡的。
对消息者来说，Docker服务为一个单一的应用。Docker引擎在1.12及更高版本中提供集群模式。

# 底层技术
Docker由[Go](https://golang.org/)编写，并利用一些Linux内核功能为其提供功能。

### 命名空间
Docker使用一种称之为`namespace`的技术为容器提供隔离工作空间。运行容器时，Docker为其创建一系列的命名空间。

这些命名空间提供一个隔离层。容器的每一个方面都运行在一个单独的命名空间中，其访问仅限于命名空间内。

在Linux中，Docker引擎使用如下的命名空间:
+ `pid` 进程隔离(PID:Process ID)
+ `net` 管理网络接口(NET:Networking)
+ `ipc` 管理访问ICP资源(PIC:InterProcess Communication)
+ `mnt` 管理文件系统挂载点(MNT:Mount)
+ `uts` 隔离内核与版本标识(UTS:Unix Timesharing System)

### 控制组
Docker 引擎在Linux上也依赖于另一个称之为控制组的技术(cgroups)。cgroups将一个应用限制为一个特殊的资源集合。
cgroups 允许Docker引擎将可用的硬件资源分配到容器，并进行选择性的限制和约束。比如你可以限制一个容器的可用内存。

### 联合文件系统 (Union file systems)
联合文件系统，也称`UnionFS`，是文件系统的操作层，使用起来非常的轻量、快速。Docker引擎使用`UnionFS`为容器构建块。
Docker引擎可以使用多种`UnionFS`，包括`AUFS`,`btrfs`,`vfs`以及`DeviceMapper`。

### 容器格式
Docker引擎将命名空间、控制组和联合文件系统组合到一个称之为容器格式包装中。默认容器格式为`libcontainer`。
未来Docker可能通过与BSD、Jails或Solaris Zones等技术的集成来支持其他容器格式。