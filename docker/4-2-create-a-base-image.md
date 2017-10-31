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
