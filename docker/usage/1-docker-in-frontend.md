## Docker在前端开发环境中的应用
在一些前端团队中并没要求开发环境统一，有的前端工程师使用windows，有的使用osx，有的使用linux。
本人在这三个环境中都有一年以上的前端使用经验，可以就此简单的总结一下各自的缺点。

### Windows
就纯前端（仅客户端环境开发）而言，windows是不二的选择。所需要的开发环境不外乎客户端环境、开发环境。大致包含如下软件：chrome浏览器、编辑器（sublime text、atom、webstorm、vscode等）、代码管理git、图片处理软件ps、字体处理软件等，window都有足够多的精品软件的选择。如果这样的开发者没必要去折腾linux了，您切图的时候还要去开个windows虚拟机呢。

windows坑爹的地方在于需要node环境前端开发者，因为node及其相关社区对windows相当不友好，所以第三库或工具在windows下也有各自的坑，严重的甚至不能正常运行，而且windows不同的版本、相同版本的不同发行版、相同发行版的不同补丁版本都有各种各样的坑。在有的时候你甚至不得不为某一台windows写一些定制的脚本。

### Osx
Unix系统，什么都好，开发软件该有的也都有，就是不太普及，大多数公司也不会让osx成为公司的标配。

### Linux
前端开发如果选linux，要么是前端leader脑子进水，要么就是开发大多集中在node后端开发。我司现在前端就是Linux或Osx系统，Linux同学在写页面的时候那叫一个痛苦：先开个Windows虚拟机，在里面开个ps，切个图，量个大小位置，再把结果通过各种方式从虚拟机中拿出来......，窗口切来切去那叫一个“爽利”。

我司目前的前端需要写大量的页面、同时也要写大量的node（服务系统由node实现），假假也是个“全栈团队”了。在这种情况下，OSX似乎是唯一的解决方案了。

但是！我是个对键盘有极高要求的人！在一周高强度的（一周大约提了2w+行代码，大量的html与css）编码下，我的左手小指敲出了鞘膜炎，MacBook那破键盘彻底的激怒了我！由此造成了我对Mac的彻底鄙视，就让这破本本在家里吃灰吧......由此开始了我的Windows前端开发环境的折腾之路。

目前我的主力开发机是thinkpad x220，键盘虽然无法与我大cherry机械键盘比，但比MacBook要好太多了。

## “全栈前端开发工程师”开发主机要解决的问题
1. 足够的图形（切图、量尺寸等）、字体（font icon）处理软件
2. 提供node运行的环境，最好是与生产环境一样（centos、unbuntu等linux发行版）的环境

Windows优秀的生态自然满足第1点需求，很少有在Windows上找不到的软件，就算没有，也有类似的东西来满足需求。所以要解决的主要是第2点。`Docker`的出现完美（其实也有坑，但是小坑）的解决了这一问题。

## 如何使用Docker搭建一个前端开发环境
首先请您阅读本博客Docker相关的[资料](../../README.md)，对Docker有个大约的认知之后再来看这里，不然看了也是一头雾水。

前面已经说过，如果你是一个纯前端，Windows本身已经满足你的各种需求了，所以此处主要是针对node开发环境，需要解决的问题如下：

1. 文件本地编辑并同步到docker环境。因为进入docker环境后你能操作的只是一个命令行，总不能在里面用vim编辑您的代码吧？就算您愿意，我也不愿意啊......。推荐方式是在window中使用编辑器书写代码，在docker中运行代码。
2. debug，在docker命令行中对node代码debug是很扯淡的，虽然node提供了debug运行环境，但那种体验是很不友好。推荐的方式是本地使用debug工具连接docker进行debug。

### 创建容器
Docker本身提供本地数据卷挂载的功能，简单的说，如果将`c:/user/you/code`盘挂载到一个docker容器（假设这个容器是linux环境）的`/opt/code`目录，你在windows中编辑`c:/user/you/code`下的任意文件，都会立即同步到docker容器的`/opt/code`目录。所以您需要做的只是打开您的编辑器，打开`c:/user/you/code`目录，开始写代码吧。当然，前提是您得有一个docker容器。

下面贴一个简单的ubuntu（纯粹是个人原因，我个人经常用ubuntu，您也可以定制你的centos或redhat等）的容器是如何定义的。

```dockerfile
# 使用ubuntu 16.04作为基础镜像
FROM ubuntu:16.04
# 添加一些描述的label，可选
LABEL description="nodejs linux platform environment" version=1.0 author=coinxu
# 设置一些环境变量
ENV WORKDIR /opt

# 设置一些参数，可以在编译时传入
# 公司内网的npm registry
ARG NPM_REGISTRY=http://192.168.0.220:4873/#/
# github 相关资料
ARG GITHUB_NAME=coinxu
ARG GITHUB_EMAIL=duanxian0605@gmail.com

# 设置运行用户
USER root

# 执行内容脚本
RUN                                                                                \
    # 众所周知的原因，需要替换ubuntu镜像为163国内镜像，提升apt-get的安装速度与成功率    
    sed -i 's/security.ubuntu.com/mirrors.163.com/g' /etc/apt/sources.list         \
    && sed -i 's/archive.ubuntu.com/mirrors.163.com/g' /etc/apt/sources.list       \
    # apt-get 安装一些软件
    && apt-get update                                                              \    
    && apt-get install -y apt-utils                                                \
    && apt-get install -y sudo                                                     \
    && apt-get update                                                              \
    && apt-get upgrade -y                                                          \

    # 安装并配置git
    && apt-get install -y git                                                      \
    && git config --global user.email ${GITHUB_EMAIL}                              \
    && git config --global user.name ${GITHUB_NAME}                                \
    
    # curl
    && apt-get install -y curl                                                     \

    # vim
    && sudo apt-get install -y vim                                                 \

    # 安装nodejs 8.x
    && sudo apt-get install -y build-essential                                     \
    && curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -              \
    && sudo apt-get install -y nodejs                                              \

    # 注册npm registry为NPM_REGISTRY环境变量
    && npm install -g npm@4.6.1                                                    \
    && npm config set registry=${NPM_REGISTRY}                                     \        

    # proxychains命令行代理工具，可选
    && apt-get install -y proxychains                                              \                                                
    # clean
    && apt-get -y clean

# 声明数据卷
VOLUME ${WORKDIR}
# 对外开放端口
EXPOSE 8080
# 进入时执行的命令
ENTRYPOINT ["/bin/bash"]
```
有了上面这份Dockerfile，就可以使用docker构建我们需要的ubuntu环境了。
```bash
docker build --build-arg GITHUB_NAME=your_github_name --build-arg GITHUB_EMAIL=your_github_email -t your_image_name:1.0 .
```

此时你可以通过`docker images`命令查看镜像，下面是我的机子上的容器
```bat
PS C:\Users\coin> docker images
REPOSITORY                 TAG                 IMAGE ID            CREATED             SIZE
sugo                       1.0                 59bccbc703bc        12 days ago         576MB
ubuntu                     16.04               00fd29ccc6f1        6 weeks ago         111MB
redis                      3.2                 256639e384de        6 weeks ago         99.7MB
postgres                   9.6                 5579c7505b1b        6 weeks ago         268MB
docker4w/nsenter-dockerd   latest              cae870735e91        3 months ago        187kB
```
### Debug
可以针对上面创建镜像写一个启动脚本运行容器：
```bash
docker run ^
:: 给容器随便起个名字
--name demo -td ^
--rm ^
:: 对外开放两个端口，一个是你应用程序的本来端口，二是debug端口
-p 127.0.0.1:8080:8080 ^
-p 127.0.0.1:9229:9229 ^
:: 挂载本地目录到容器目录
-v //d/codes:/opt/codes ^
sugo:1.0
```
使用node提供的`--inspect`参数与`chrome://inspect`远程debug。

1. 启动node程序
```bash
root@ae1f7916205c:/opt/codes/works/sugo/sugo-analytics# node --inspect-brk=0.0.0.0:9229 app/app.js
Debugger listening on ws://0.0.0.0:9229/8c367cfb-1806-4d07-8cc7-b7211ae7b259
For help see https://nodejs.org/en/docs/inspector
```
2. 打开chrome，在地址栏输入`chrome://inspect`，并点击`inspect`
![docker-mac.png](https://raw.githubusercontent.com/CoinXu/blog/master/docker/usage/chrome-inspect.png)

3. 进入chrome-devtools界面进行debug
![docker-mac.png](https://raw.githubusercontent.com/CoinXu/blog/master/docker/usage/chrome-inspect-debug.png)

## 目前未解决的坑
1. windows下同步文件到docker后，不会触发node的fsevent相关事件，基于这类事件的程序（如webpack开启watch选项）将会失效。之前搜过一些issue，好像是有第三方的程序包可以解决这个问题。因为最近一直在写服务端相关的东西，没用到`webpack watch`，所以还没折腾这个坑。
2. 使用powershell做为终端，有的时候会报错`process.cwd()`相关错误，需要重开一个powsershell进入docker容器才可以。

正常的开发环境中还需要redis、mysql这样的持久化存储方案，如果也需要使用docker容器话（当然我也是建议您使用docker容器，而不必装一大堆软件），可以认真阅读docker相关资料并搭建自己的开发环境。