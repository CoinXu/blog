
# Base on unbuntu
FROM ubuntu:16.04

# Description labels
LABEL description="nodejs linux platform environment" version=1.0 author=coinxu

# Envrionment variables
ENV WORKDIR /opt

ARG NPM_REGISTRY=http://dev.sugoio.com:4873/#/
ARG GITHUB_NAME
ARG GITHUB_PASSWORD
ARG GITHUB_EMAIL

USER root

# use ssh
COPY ./.ssh .ssh

RUN    sed -i 's/security.ubuntu.com/mirrors.163.com/g' /etc/apt/sources.list      \
    && sed -i 's/archive.ubuntu.com/mirrors.163.com/g' /etc/apt/sources.list       \
    && apt-get update                                                              \    
    && apt-get install -y apt-utils                                                \
    && apt-get install -y sudo                                                     \
    && apt-get install -y sed                                                      \
    && apt-get update                                                              \
    && apt-get upgrade -y                                                          \

    # git
    && apt-get install -y git                                                      \
    && git config --global user.email ${GITHUB_EMAIL}                              \
    && git config --global user.name ${GITHUB_NAME}                                \
    
    # curl
    && apt-get install -y curl                                                     \

    # vim
    && sudo apt-get install -y vim                                                 \

    # nodejs
    && sudo apt-get install -y build-essential                                     \
    && curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -              \
    && sudo apt-get install -y nodejs                                              \

    # npm registry
    && npm install -g npm@4.6.1                                                    \
    && npm config set registry=${NPM_REGISTRY}                                     \        

    # clone sugo-analytics
    # && cd /opt                                                                   \
    # && git clone https://${GITHUB_NAME}:${GITHUB_PASSWORD}@github.com/Datafruit/sugo-analytics.git  \
    # && cd /opt/sugo-analytics                                                    \
    # && npm install                                                               \

    # proxychains
    && apt-get install proxychains                                                 \                                                

    # clean
    && apt-get -y clean

VOLUME ${WORKDIR}

EXPOSE 8080

ENTRYPOINT ["/bin/bash"]

# build script
# docker build --build-arg NPM_REGISTRY=$register --build-arg GITHUB_PASSWORD=$password --build-arg GITHUB_NAME=name -t sugo-analitics .
