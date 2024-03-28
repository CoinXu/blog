# 内网部署https
在部署`guacamole`的时候，发现不能复制粘贴浏览器之外的内容，查资料说是浏览器需要在https的环境中才能共享剪贴板。

## guacamole部署 (debian 12 bookworm)
最简单的方式，使用docker部署。
1. 新建一个空白目录
```bash
mkdir -p ~/docker/guacamole
cd ~/docker/guacamole
```
2. 在目录下新建`docker-compose.yml`文件，填入以下内容：
```yml
version: "3.8"

services:
guacamole:
    image: flcontainers/guacamole:latest
    container_name: guacamole
    restart: always
    ports:
       - 8080:8080
    environment:
       - TZ=Asia/Shanghai
    volumes:
       - /etc/localtime:/etc/localtime:ro
```
3. 启动guacamole容器
```bash
sudo docker compose up -d
sudo docker ps
...
CONTAINER ID   IMAGE                           PORTS                                      NAMES
7a83dc12c591   flcontainers/guacamole:latest   0.0.0.0:8080->8080/tcp, :::8080->8080/tcp  guacamole
```

## 通过nginx部署ssl证书
1. 安装[mkcert](https://github.com/FiloSottile/mkcert)
```bash
sudo apt install libnss3-tools
# 去发布地址下载对应的二进制文件，注意cpu架构
# https://github.com/FiloSottile/mkcert/releases
wget https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-arm64
chmod +x mkcert-v1.4.4-linux-arm64
sudo cp mkcert-v1.4.4-linux-arm64 /usr/local/bin/mkcert
# 验证安装是否成功
mkcert --version
...
v1.4.4
```

2. 创建泛域名证书
```bash
mkdir -p /etc/nginx/certs
cd /etc/nginx/certs
mkcert "*.example.com"
ls -l
...
 _wildcard.example.com-key.pem
 _wildcard.example.com.pem
```

3. 创建nginx ssl通用配置文件`/etc/nginx/conf.d/example.com.ssl_params`
```
ssl_certificate /etc/nginx/certs/_wildcard.example.com.pem;
ssl_certificate_key /etc/nginx/certs/_wildcard.example.com-key.pem;
ssl_session_cache shared:SSL:1m;
ssl_session_timeout 30m;
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_ciphers HIGH:!aNULL:!MD5:!EXPORT56:!EXP;
ssl_prefer_server_ciphers on;
```

4. 配置某个域名的nginx
```
server {
  listen       80;
  server_name mm.example.com;
  return 301 https://$server_name$request_uri;
}

server {
  listen 443 ssl;
  server_name mm.example.com;
  include /etc/nginx/conf.d/example.com.ssl_params;

  location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_buffering off;
    proxy_http_version 1.1;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
    access_log off;
  }
}
```

5. 检测nginx配置文件、重新加载nginx配置
```bash
nginx -t
nginx -s reload
```

## 客户端主机安装根证书
1. 在服务器安装根证书
```bash
mkcert --install
# 查看根证书安装目录
mkcert -CAROOT
...
/home/${user}/.local/share/mkcert
# 查看根证书文件
ls $(mkcert -CAROOT)
...
rootCA-key.pem  rootCA.pem
```

2. 将根证书下载到客户端（macOS为例）
```bash
scp root@{server ip or hostname}:/home/${user}/.local/share/mkcert .
```

3. 安装根证书
自己查资料，略