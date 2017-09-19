# 诱因
在一次配置windows下的node开发环境，需要执行一些npm scripts的时候，不得不为windows单独写脚本。
所以package.json文件大约就写成了这样。
```json
{
  "scripts": {
     "build": "...",
     "build:win": "..."
  }
}
```

问题是在windows下的命令总是会出现各种问题，而我对bat又不熟悉（当然我对shell也不是很熟悉~）。
再加上一些第三方库的编译问题，折腾了大半天放弃了，于是想到了偶然间看到的docker。

我基本不会为某一软件或库写笔记，因为觉得没必要。
但在安装docker的过程中遇到太多坑了，特此记录一下，以供其他同学参考及备忘。

# 概述
[Docker](https://www.docker.com/) 官网介绍那是相当的嚣张：
> Docker is the world’s leading software container platform.

功能也是一句话概括了：
> Developers use Docker to eliminate “works on my machine” problems when collaborating on code with co-workers.
> Operators use Docker to run and manage apps side-by-side in isolated containers to get better compute density.
> Enterprises use Docker to build agile software delivery pipelines to ship new features faster, more securely and with confidence for both Linux, Windows Server, and Linux-on-mainframe apps.

[原文](https://www.docker.com/what-docker)把两件事说得很明白了：

1. Docker 也许是(广告法)最好的软件容器平台了。言外之意就是你别折腾其他了，我就是最好的。
   你如果有软件容器需求，选我，就选我。就算你现在不选我，将来还是要来选我。
2. Docker 解决的问题是:
   + 开发者：代码在我机子上跑得好好的，为啥到同事机子上就跪了？
   + 运营商：使用Docker将应用在隔离的容器中管理和运行，以获得更好的计算密度。
   + 企业：使用Docker构建敏捷的发布途径，可以在`Linux`，`windows`以及以`Linux`为基础的系统上更快更安全的发布新功能

如何证明docker确实可行呢？可以参考[Docker在京东的使用情况](http://www.dockerinfo.net/4165.html)。

#### 对于一个可怜的前端来说，Docker能作什么？
1. 解决组内开发环境统一问题
2. 解决测试环境问题
3. 解决生产环境问题
4. 解决公司与家里环境统一问题

最重要的是什么？__开发环境与生产环境一致的问题__，再也不会出现部署之后出问题的痛了。
如果公司能将所有的服务docker化，那么给客户部署也就不用关心什么鬼客户环境的问题了。

以前解决开发环境统一的问题主要是依靠统一硬件配置，这对前端来说其实有点扯淡，你说你一个写页面的，
天天开着虚拟机搞ps，不觉得痛吗？windows上这么多好的软件不用，非要去linux折腾各种命令行工具，
不觉得浪费时间吗？(请记住一点，折腾工具并不会带给你半点实用的收获，你只是学会了工具的几个可怜的命令行而已)。

如果某位看官觉得：爷就喜欢折腾，折腾使我快乐，使我成长，使我不能自己...
这后面的也不用看了，爷不希得和你说...

# 使用流程
前面废话了这么，我再不放干货的话看官可能要骂我灌水了，现在先来看看docker的使用流程是怎样的。
以前端node开发环境来说明如何将开发环境搬牵到docker中，纯干货！
具体的名词后面再解释，现在只关心步骤，只有四步。

1. 建立docker镜像(image)，此处搭建一个完整的Linux环境，使用Dockerfile描述一个image，一个简单的例子如下：
   ```
   FROM ubuntu:16.04
   ENV HOME /root
   ENV DEBIAN_FRONTEND noninteractive
   VOLUME /data/docker
   RUN apt-get update && apt-get clean                                          \
   	&& apt-get install -y sudo                                                  \
   	&& apt-get install -y build-essential                                       \
   	&& apt-get install -y wget                                                  \
   	&& apt-get install -y curl                                                  \
   	&& apt-get install -y apt-transport-https                                   \
   	&& apt-get install -y software-properties-common python-software-properties \
   	&& add-apt-repository ppa:fkrull/deadsnakes                                 \
   	&& apt-get update                                                           \
   	&& apt-get install -y python2.7                                             \
   	&& apt-get install -y git                                                   \
       && wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash \
   	&& curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -           \
   	&& sudo apt-get install -y nodejs                                           \
   	&& curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -   \
   	&& echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
   	&& apt-get update                                                           \
   	&& sudo apt-get -y install yarn                                             \
   	&& rm -rf /var/lib/apt/lists/*
   CMD ["/bin/bash"]
   ```
   我撒谎了，以上例子其实不算简单的...
   在其中安装了`sudo`, `wget`, `curl`, `nodejs`及其依赖的`python`、`build-essential`，
   还有开发常用的`git`,`yarn`...

   诸位也不用退缩，这是一个定制性比较强的image了，其实平常所需的开发软件官方都有提供Dockerfile，
   你可以直接使用，不必写Dockerfile，不过我强烈建议去看看Dockerfile相关[文档](https://docs.docker.com/engine/reference/builder/)，
   很简单的几个描述符。总会有遇到定制的时候。

2. 创建镜像：有了Dockerfile之后就可以创建镜像了，只需要执行一条命令
   ```bash
   docker build -f ./Dockerfile -t nodejs:1.0
   ```
   此时会创建一个`nodejs:1.0`的镜像，你可以通过`docker image ls`命令看到

3. 使用镜像启动一个容器(container)

   ```bash
   // shell命令
   // bat命令略有不同，放后面说
   docker run \
   --name container_node -td \     # 容器name，也可以不指定
   -p 127.0.0.1:8080:9090 \        # 端口绑定，将容器9090端口映射到本机的9090端口
   -v /opt/path:/opt/test/dir \    # volume映射，将本机的/opt/path映射到容器的/opt/test/dir
   nodejs:1.0
   ```

4. 外部访问容器
   ```bash
   docker exec -it container_node bash
   ```
   此时会进入容器，容器为一个基本的ubuntu系统，你可以在里面安装、执行任意的ubuntu软件。

你可以将该Dockerfile拷贝或则发布到[hub.docker.com](https://hub.docker.com/)，
供你的同事使用，他们只需要执行上面的`2，3，4`步即可拥有与你一致的环境。

__下一篇将讲[安装过程](./2-install.md)，这可以让诸位少走不少弯路，特别是windows用户__

