# blog

## 前端工程
+ [概述](./Front-end-engineering/1-intro.md)
+ [view与model分离思考](./Front-end-engineering/2-split-view-and-model.md)

## SVG
+ [Animate](./svg/SVG-<Animate>-begin.md)
+ [Animate calculation](./svg/SVG-<animate>-calculation.md)

## Docker
+ [概述](./docker/1-intro.md)
+ [安装](./docker/2-install.md)
+ [Docker 概览](./docker/3-docker-overview.md)
+ [使用镜像](./docker/4-work-in-images.md)
  + [创建基础镜像](./docker/4-2-create-a-base-image.md)
  + [Dockerfile参考](./docker/4-1-dockerfile-reference.md)
  + [使用多阶段构建](./docker/4-3-use-multi-stage-builds.md)
+ [容器数据存储](./docker/5-storage-data-within-containers.md)
  + [镜像、容器与存储驱动](./docker/5-1-about-images-containers-and-storage-drivers.md)
  
## 计算机图形学
+ [http://netclass.csu.edu.cn/NCourse/hep089/](http://netclass.csu.edu.cn/NCourse/hep089/)
+ [https://www.bilibili.com/video/av15445516/](https://www.bilibili.com/video/av15445516/)



「 @张博 ：# Base on unbuntu
FROM ubuntu:16.04

# Description labels
LABEL description="sugo-analytics runtime environment" version=0.0.0 author=sugo.io

# Envrionment variables
ENV WORKDIR /opt

# User args
ARG GITHUB_ACCOUNT
ARG GITHUB_PASSWORD
ARG GITHUB_HTTPS_PROXY

USER root

RUN apt-get update                                                                 \    
    && apt-get install -y apt-utils                                                \
    && apt-get install -y sudo                                                     \
    && apt-get install -y sed                                                      \
    && sed -i 's/security.ubuntu.com/mirrors.163.com/g' /etc/apt/sources.list      \   
    && apt-get update                                                              \
    && apt-get upgrade -y                                                          \

    # git
    && apt-get install -y git                                                      \
	&& git config --global https.proxy ${GITHUB_HTTPS_PROXY}                   \
    
    # curl
    && apt-get install -y curl                                                     \

    # vim
    && sudo apt-get install -y vim                                                 \

    # nodejs
    && sudo apt-get install -y build-essential                                     \
    && curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -              \
    && sudo apt-get install -y nodejs                                              \
	&& sudo apt-get install openssl                                                \

    # Clone source code from git
    && npm config set registry=http://192.168.0.202:4873/                          \
    # && cd ${WORKDIR}                                                             \
    # && git clone https://${GITHUB_ACCOUNT}:${GITHUB_PASSWORD}@github.com/Datafruit/sugo-analytics.git  \
    # && cd ./sugo-analytics                                                       \
    # && npm install                                                               \

    # && echo current pwd $(pwd)
    # && echo "[credential]" >> .git/config                                        \
    # && echo "    helper = store" >> .git/config                                  \
    && apt-get -y clean

VOLUME ${WORKDIR}

EXPOSE 8080

ENTRYPOINT ["/bin/bash"]

# CMD ["npm run dev:server && npm run dev:client"]
# CMD cd ${WORKDIR}/sugo-analytics && npm run dev:server & npm run dev:client


# Build script
# docker build --build-arg GITHUB_ACCOUNT={GITHUB_ACCOUNT} --build-arg GITHUB_PASSWORD={GITHUB_PASSWORD} --build-arg GITHUB_HTTPS_PROXY=http://192.168.0.202:3000 -t analytics .
# docker build -t nodejs:1.0 .

# Start container
# docker run --name analytics-tsa -i -t -v /docker:/opt -p 8080:8080

# Entry container
# docker exec -it {container_name} bash
 」
--------
