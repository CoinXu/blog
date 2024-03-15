# 创建一个基础镜像
大多数Dockerfile由一个父镜像开始，如果你需要完全控制镜像的内容，你可能需要创建基础镜像代替父镜像，
不同在于：

1. 父镜像是你的镜像基于的镜像，指的是Dockerfile中`FROM`指令的内容。Dockerfile中每个后续声明都会修改父对象。
   大多数Dockerfile以一个父镜像而非基础镜像开始，然而，这种说法有时候也会反过来。
2. 一个基础镜像没有`FROM`行，也许有`FROM scratch`。

本文主题是向你展示创建基础镜像的几种方式，具体过程在很大程度上取决于你要封装的Linux发行版。
下面有一些例子，我们鼓励你贡献新的例子。

# 使用tar创建一个完整的镜像
一般来说，你需要从你想要作为父镜像包的发行版的工作机器开始，尽管一些工具并不需要，
比如Debian的[Debootstrap](https://wiki.debian.org/Debootstrap)，但你也可以使用它们来构建Ubuntu镜像。

可以如此简单的创建Ubuntu父镜像：
```bash
$ sudo debootstrap xenial xenial > /dev/null
$ sudo tar -C xenial -c . | docker import - xenial

a29c15f1bf7a

$ docker run xenial cat /etc/lsb-release

DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=16.04
DISTRIB_CODENAME=xenial
DISTRIB_DESCRIPTION="Ubuntu 16.04 LTS"
```
在Docker Github Repo 中有更多创建父镜像的脚本：

+ [BusyBox](https://github.com/moby/moby/blob/master/contrib/mkimage/busybox-static)
+ CentOS / Scientific Linux CERN (SLC) [on Debian/Ubuntu](https://github.com/moby/moby/blob/master/contrib/mkimage/rinse)
  或 [on CentOS/RHEL/SLC/etc.](https://github.com/moby/moby/blob/master/contrib/mkimage-yum.sh)
+ [Debian / Ubuntu](https://github.com/moby/moby/blob/master/contrib/mkimage/debootstrap)

# 使用scratch创建一个镜像的父容器
可以使用Docker保留的最小镜像scratch作为构建容器的起点，使用scratch镜像告知构建进程，
你希望Dockerfile中的下一个命令成为镜像的第一个文件系统层。

scratch出现在hub上的Docker仓库时，你不能拉取、运行或给其他镜像打上scratch标签。
你可以在你的Dockerfile中引用它，下面是创建一个最小容器的例子：

```dockerfile
FROM scratch
ADD hello /
CMD ["/hello"]
```

假设你已经从[Docker Github示例C源码](https://github.com/docker-library/hello-world/blob/master/hello.c)创建了
可执行应用，并使用`-static`标记编译了，之后你可以使用`docker build --tag hello .`命令构建该容器。

> 注：
  因为Docker for Mac和Docker for Windows使用Linux VM，因此必须使用Linux工具链编译此代码，
  以获得Linux二进制文件。 不必担心，您可以快速获得Linux镜像和构建环境并在其中构建：
  ```dockerfile
  $ docker run --rm -it -v $PWD:/build ubuntu:16.04
  container# apt-get update && apt-get install build-essential
  container# cd /build
  container# gcc -o hello -static -nostartfiles hello.c
  ```

然后可以使用`docker run --rm hello`运行该镜像。

本示例创建教程中使用的hello-word镜像，如果你想测试它，可以[克隆](https://github.com/docker-library/hello-world)一份

# 更多资源
这里有更多的资源可以帮助你创建你自己的Dockerfile

+ 一份[所有指令完全指南](./4-1-dockerfile-reference.md)
+ 为了帮助你书写一个清爽的、可读性高的、可维护的Dockerfile，
  我们准备了一份[Dockerfile最佳实践指南](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/)
+ 如果你的目标是创建一个新的官方仓库，请务必阅读Docker的[官方仓库介绍](https://docs.docker.com/docker-hub/official_repos/)