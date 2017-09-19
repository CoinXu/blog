# 安装
其他平台上安装Docker都异常的简单，特别是Linux系统，几条命令就解决问题，本文重点会放在windows上的安装上。
Linux平台以ubuntu举例说明。

本文所说的Docker都是以[CE(Community Edition)](https://www.docker.com/community-edition)版本。
> Docker Community Edition (CE) is ideal for developers and small teams looking
> to get started with Docker and experimenting with container-based apps.

对于个人开发者与小团队来说，CE版本足够用来体验基于容器开发APP的过程。
[EE(Enterprise Edition)](https://www.docker.com/enterprise-edition)版本我没用过，也没有去看有啥功能。

# Ubuntu
[官方文档](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/)很详细的说明了环境需求及安装过程，摘要如下。

### 系统要求
安装Docker，你需要使用以下发行版的64位版本
+ Zesty 17.04
+ Xenial 16.04 (LTS)
+ Trusty 14.04 (LTS) 

Docker 支持x86_64、armhf与s390架构，s390仅仅在Ubuntu`Xenial`与`Zesty`中可用。

### 安装准备
```bash
# 1. 卸载旧版本
sudo apt-get remove docker docker-engine docker.io
# 2. 在14.04版本中，推荐使用`linux-image-extra-*包，使得Docker可以使用aufs存取驱动
sudo apt-get update
sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual
```
### 指定Docker CE库
在一台新主机中需要指定Docker库地址，之后才能使用`apt-get`安装。
```bash
# 1. 更新apt包索引
sudo apt-get update

# 2. 安装https相关包
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common

# 3. 添加官方GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# 3.1 验证fingerprint
sudo apt-key fingerprint 0EBFCD88

# 4. 指定稳定版Docker仓库，需要区分不同的架构
# 4.1 amd64
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
# 4.2 armhf
sudo add-apt-repository \
   "deb [arch=armhf] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
# 4.3 s390x
sudo add-apt-repository \
   "deb [arch=s390x] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
```
### 安装Docker
```bash
# 1. 更新apt索引
sudo apt-get update

# 2. 安装最新版Docker
sudo apt-get install docker-ce
# 安装指定版本：
# 2.1 获取可用版本列表
# apt-cache madison docker-ce
# 2.2 安装指定版本
# sudo apt-get install docker-ce=<VERSION>

# 3. 运行一个hello-word的镜像检测是否安装成功
sudo docker run hello-world
```

Linux大致过程如下，当然你也可以通过各种安装包(*.deb)来安装，详细说明不再列出，
请查阅[官方文档](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/#install-from-a-package)

下面重点说下windows下安装(我喜欢windows环境~)

# Windows