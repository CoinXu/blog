# 概述
[https://docs.docker.com/engine/docker-overview/](https://docs.docker.com/engine/docker-overview/)

Docker 是一个为开发、传递和运行应用的开放平台。Docker 可以使你的应用与基础设施分离，
所以你可以快速的交付软件而不必折腾各种环境。利用Docker你可以像管理你的应用一样管理基础设施。
使用Docker快速传递、测试和部署代码，可以大大减少编写代码到运行代码之间的时间延迟。

# Docker 平台
Docker 提供打包、运行应用在一个松散隔离环境中的能力，这个环境称之为容器(container)。
隔离性与安全性允许你在同一主机中同时运行多个容器。容器是非常轻量的，因为它们不需要管理额外的负载，
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

#### Docker 守护进程
Docker 守护进程监听Docker API请求，管理Docker对象，如：镜像、容器、网络和数组卷。
也可以与其他守护进程通信管理Docker服务。

#### Docker 客户端
Docker客户端是许多Docker用户与Docker交互的主要方式。当你使用Docker命令，比如`docker run`时，
客户端发送命令到`dockerd`，`docker`命令使用Docker API，Docker客户端可以与多个守护进程通信。

#### Docker 注册服务
Docker 注册服务存储Docker镜像。任何人都可以在公共的注册服务Docker Hub与Docker Cloud上注册。
Docker默认在Docker Hub上查找镜像，你甚至可以运行自己私有的服务。
如果你使用Docker Datacenter(DDC)，它包含了Docker Trusted Registry(DTR)。

当你使用`docker pull`或`docker run`命令时，将会从你配置的服务上拉取所需的镜像。
当你使用`docker push`命令时，镜像将会推送到你所配置的服务。

你可以在[Docker store](https://store.docker.com/)上购买、发售或者免费发布Docker镜像。
例如：你可以从软件供应商处购买包含应用或服务镜像，部署应用到你的测试、staging(不知道如何翻译)与生产环境中。
你可以通过拉取镜像新版本更新镜像并重新部署以更新应用。

# Docker 对象
使用Docker时，你将会创建并使用镜像、容器、网络、数据卷、插件与其他对象，该节简要介绍这些对象。

#### 镜像(IMAGES)
#### 容器(CONTAINERS)
#### 服务(SERVICES)

# 底层技术
#### 命令空间
#### 控制组
#### 联合文件系统
#### 容器格式
