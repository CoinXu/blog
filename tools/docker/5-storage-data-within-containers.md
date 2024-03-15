# Docker 存储驱动

Docker 使用一系列不同存储驱动来管理镜像与运行中的容器文件系统。
这些存储驱动与[Docker volumes](https://docs.docker.com/engine/tutorials/dockervolumes/)不同。
Docker volumes管理可在多个容器之间共享的存储。

Docker依靠存储驱动技术来管理与镜像及其容器相关的存储与交互。本部份包含如下内容：
+ [镜像、容器与存储驱动相关知识](./5-1-about-images-containers-and-storage-drivers.md)，
+ 选择存储驱动
+ AUFS存储驱动实践
+ Btrfs存储驱动实践
+ Device Mapper存储驱动实践
+ OverlayFS实践
+ ZFS存储实践

如果你是Docker新手，请先阅读[镜像、容器与存储驱动相关知识](./5-1-about-images-containers-and-storage-drivers.md)，
这里解释了在使用存储驱动时的关键概念与知识。