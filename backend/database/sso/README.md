# 单点登录（SSO）开源方案
经过一番折腾，总结：如果你不需要开源方案提供的二次验证、Time-based One-Time password、OAuth 2.0 、OpenID Connect 1.0.等功能，还是自己写代码吧。

# 需求
准确的说我想找一个开源的用户账户管理系统，但没找到合适的，退而用SSO方案搭建了一个。核心功能如下：
- 用户注册
- 修改密码、邮箱、昵称等属性
- 用户分组
- SSO验证
- 二次验证

我找到的开源方案要么功能太多，不方便成为独立服务，比如用户管理系统。要么功能太少，比如SSO，只有登录校验，没有用户信息管理。经过一天的资料查找，最终决定采用SSO+LDAP方案。

LDAP管理用户账户信息，SSO管理登录授权。

# 最终方案
- LDAP: https://github.com/lldap/lldap
- SSO: https://github.com/authelia/authelia

# 配置
请注意，采用Docker运行，为避免各种网络问题，粗暴的采用了`network_mode: host`方案。

## LDAP
- 注意：LDAP需要占用 `3890`，`17170`两个端口
- 特别注意：LDAP服务不建议使用`opendj`，这玩意儿太原始了，头痛。

### 添加`docker-compose.yml`文件
```yml
version: "3"

services:
  lldap:
    image: lldap/lldap:stable
    network_mode: host
    volumes:
      # 挂载一个本地目录，用户存放config、db等文件
      - "./lldap_data:/data"
    environment:
      - UID=1000
      - GID=1000
      - TZ=Asia/Shanghai
      - LLDAP_JWT_SECRET='2xYV:6RCZs?~YEn|VAQQr'
      - LLDAP_KEY_SEED='TAdV,6jl?@cEDFm1h18vL('
      # DN是LDAP中的概念，如有兴趣，自己去查资料
      # BASE_DN根据实际情况填写，比如你的网站是foo.com，此处可设置为
      # dc=foo,dc=com
      - LLDAP_LDAP_BASE_DN=dc=example,dc=com
      # 网页管理员密码
      - LLDAP_LDAP_USER_PASS=Admin***LDAP
```
### 添加`lldap`配置文件
文件路径：`./lldap_data/lldap_config.toml`

```toml
# 打印详细日志，方便debug
verbose=true
ldap_host = "0.0.0.0"
ldap_port = 3890
http_host = "0.0.0.0"
http_port = 17170
# 网页管理员用户名
ldap_user_dn = "admin"
database_url = "sqlite:///data/users.db?mode=rwc"
key_seed = "RanD0m STR1ng"
```

### 启动容器
```bash
sudo docker compose up -d
```

# SSO
选用Authelia的原因很简单：它在github上面star最多。这里配置麻烦一点，请按步骤来。

### 添加`docker-compose.yml`文件
在运行`authelia`之前，先准备一个redis服务，这里就不介绍了。

```yml
version: "3"

services:
  authelia:
    container_name: 'authelia_test'
    image: 'authelia/authelia'
    restart: 'unless-stopped'
    network_mode: "host"
    volumes:
      - './data/authelia/config:/config'
    environment:
      TZ: 'Asia/Shanghai'
```
在进行下一步之前，先访问`http://127.0.0.1:17170`网址，使用amdin账户登录，创建一个新用户`authelia`，并将其添加`lldap_strict_readonly`与`lldap_password_manager`权限。

创建`./data/authelia/config/configuration.yml`文件，内容如下：
```yml
server:
  address: 'tcp://0.0.0.0:9091'

log:
  level: 'debug'

totp:
  issuer: 'dev.example.com'

identity_validation:
  reset_password:
    jwt_secret: 'a_very_important_secret'

authentication_backend:
  password_reset:
    disable: false
  refresh_interval: 1m
  ldap:
    implementation: custom
    address: ldap://0.0.0.0:3890
    timeout: 5s
    start_tls: false
    base_dn: dc=example,dc=com
    additional_users_dn: ou=people
    # To allow sign in both with username and email, one can use a filter like
    # (&(|({username_attribute}={input})({mail_attribute}={input}))(objectClass=person))
    users_filter: "(&({username_attribute}={input})(objectClass=person))"
    additional_groups_dn: ou=groups
    groups_filter: "(member={dn})"
    attributes:
      display_name: displayName
      username: uid
      group_name: cn
      mail: mail

    # The username and password of the bind user.
    # "bind_user" should be the username you created for authentication with the "lldap_strict_readonly" permission. It is not recommended to use an actual admin account here.
    # If you are configuring Authelia to change user passwords, then the account used here needs the "lldap_password_manager" permission instead.
    user: uid=authelia,ou=people,dc=example,dc=com
    # Password can also be set using a secret: https://www.authelia.com/docs/configuration/secrets.html
    password: 'Authelia****Manager'

access_control:
  default_policy: 'deny'
  rules:
    - domain: '*.dev.example.com'
      #policy: one_factor
      policy: two_factor

session:
  # This secret can also be set using the env variables AUTHELIA_SESSION_SECRET_FILE
  secret: 'insecure_session_secret'

  cookies:
    - name: 'authelia_session'
      domain: 'dev.example.com'  # Should match whatever your root protected domain is
      authelia_url: 'https://auth.dev.example.com'
      expiration: '1 hour'
      inactivity: '5 minutes'

  # 之前准备好的redis
  redis:
    host: 'localhost'
    port: 8060
    password: '****'

regulation:
  max_retries: 3
  find_time: '2 minutes'
  ban_time: '5 minutes'

storage:
  encryption_key: 'you_must_generate_a_random_string_of_more_than_twenty_chars_and_configure_this'
  local:
    path: '/config/db.sqlite3'

# 配置消息通知邮件服务，必填
notifier:
  smtp:
    address: 'smtp://smtp.gmail.com:587'
    timeout: '60s'
    username: "example@gmail.com"
    password: 'j**************d'
    sender: "example <lujunmin7@gmail.com>"
    identifier: 'dev.example.com'
    subject: "{title}"
    disable_require_tls: false
    disable_starttls: false
    disable_html_emails: false
```

### 启动Authelia
```bash
sudo docker compose up -d
```

# 使用代理软件实现拦截和转发请求
此处使用nginx作为代理软件，因为SSO需要一些nginx插件，所以使用[Authelia推荐](https://www.authelia.com/integration/proxies/nginx/)的nginx镜像：`lscr.io/linuxserver/nginx`

### 添加`docker-compose.yml`文件
该容器需要占用`80`，`443`两个端口

```yml
version: "3"

services:
  nginx:
    container_name: 'nginx'
    image: 'lscr.io/linuxserver/nginx'
    restart: 'unless-stopped'
    network_mode: "host"
   volumes:
      - './data/nginx/snippets:/config/nginx/snippets'
      - './data/nginx/site-confs:/config/nginx/site-confs'
      - './data/nginx/logs:/config/nginx/logs'
      - './data/nginx/data:/config/nginx/data'
    environment:
      TZ: 'Asia/Shanghai'
      DOCKER_MODS: 'linuxserver/mods:nginx-proxy-confs'
```
### 准备域名如下
- dev.example.com
- auth.dev.example.com
- test.dev.example.com

### 准备https证书
证书需要支持上面所有的域名

1. `snippets/cert/fullchain.pem`
2. `snippets/cert/privkey.pem`

### 为nginx分别添加如下配置文件
1. `snippets/authelia-authrequest.conf`
```nginx
## Send a subrequest to Authelia to verify if the user is authenticated and has permission to access the resource.
auth_request /internal/authelia/authz;

## Save the upstream metadata response headers from Authelia to variables.
auth_request_set $user $upstream_http_remote_user;
auth_request_set $groups $upstream_http_remote_groups;
auth_request_set $name $upstream_http_remote_name;
auth_request_set $email $upstream_http_remote_email;

## Inject the metadata response headers from the variables into the request made to the backend.
proxy_set_header Remote-User $user;
proxy_set_header Remote-Groups $groups;
proxy_set_header Remote-Email $email;
proxy_set_header Remote-Name $name;

## Configure the redirection when the authz failure occurs. Lines starting with 'Modern Method' and 'Legacy Method'
## should be commented / uncommented as pairs. The modern method uses the session cookies configuration's authelia_url
## value to determine the redirection URL here. It's much simpler and compatible with the mutli-cookie domain easily.

## Modern Method: Set the $redirection_url to the Location header of the response to the Authz endpoint.
auth_request_set $redirection_url $upstream_http_location;

## Modern Method: When there is a 401 response code from the authz endpoint redirect to the $redirection_url.
error_page 401 =302 $redirection_url;

## Legacy Method: Set $target_url to the original requested URL.
## This requires http_set_misc module, replace 'set_escape_uri' with 'set' if you don't have this module.
# set_escape_uri $target_url $scheme://$http_host$request_uri;

## Legacy Method: When there is a 401 response code from the authz endpoint redirect to the portal with the 'rd'
## URL parameter set to $target_url. This requires users update 'auth.example.com/' with their external authelia URL.
# error_page 401 =302 https://auth.dev.example.com/?rd=$target_url;
```
2. `snippets/authelia-location.conf`
```nginx
set $upstream_authelia http://127.0.0.1:9091/api/authz/auth-request;

## Virtual endpoint created by nginx to forward auth requests.
location /internal/authelia/authz {
    ## Essential Proxy Configuration
    internal;
    proxy_pass $upstream_authelia;

    ## Headers
    ## The headers starting with X-* are required.
    proxy_set_header X-Original-Method $request_method;
    proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header Content-Length "";
    proxy_set_header Connection "";

    ## Basic Proxy Configuration
    proxy_pass_request_body off;
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503; # Timeout if the real server is dead
    proxy_redirect http:// $scheme://;
    proxy_http_version 1.1;
    proxy_cache_bypass $cookie_session;
    proxy_no_cache $cookie_session;
    proxy_buffers 4 32k;
    client_body_buffer_size 128k;

    ## Advanced Proxy Configuration
    send_timeout 5m;
    proxy_read_timeout 240;
    proxy_send_timeout 240;
    proxy_connect_timeout 240;
}
```
3. `snippets/proxy.conf`
```nginx
## Headers
proxy_set_header Host $host;
proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $http_host;
proxy_set_header X-Forwarded-URI $request_uri;
proxy_set_header X-Forwarded-Ssl on;
proxy_set_header X-Forwarded-For $remote_addr;
proxy_set_header X-Real-IP $remote_addr;

## Basic Proxy Configuration
client_body_buffer_size 128k;
proxy_next_upstream error timeout invalid_header http_500 http_502 http_503; ## Timeout if the real server is dead.
proxy_redirect  http://  $scheme://;
proxy_http_version 1.1;
proxy_cache_bypass $cookie_session;
proxy_no_cache $cookie_session;
proxy_buffers 64 256k;

# 配置你信任的真实IP
## Please read the following documentation before configuring this:
##     https://www.authelia.com/integration/proxies/nginx/#trusted-proxies
# set_real_ip_from 10.0.0.0/8;
# set_real_ip_from 172.16.0.0/12;
# set_real_ip_from 192.168.0.0/16;
# set_real_ip_from fc00::/7;
set_real_ip_from 127.0.0.1;
real_ip_header X-Forwarded-For;
real_ip_recursive on;

## Advanced Proxy Configuration
send_timeout 5m;
proxy_read_timeout 360;
proxy_send_timeout 360;
proxy_connect_timeout 360;
```
4. `snippets/ssl.conf`
```nginx
# 注意修改为正确的路径
ssl_certificate /config/nginx/snippets/cert/fullchain.pem;
ssl_certificate_key /config/nginx/snippets/cert/privkey.pem;
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_ciphers HIGH:!aNULL:!MD5:!EXPORT56:!EXP;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
```

### 配置aut.dev.example.com的nginx
```nginx
server {
    listen 80;
    server_name auth.dev.example.com;

    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name auth.dev.example.com;

    include /config/nginx/snippets/ssl.conf;

    set $upstream http://127.0.0.1:9091;

    location / {
        include /config/nginx/snippets/proxy.conf;
        proxy_pass $upstream;
    }

    location = /api/verify {
        proxy_pass $upstream;
    }

    location /api/authz/ {
        proxy_pass $upstream;
    }
}
```

### 配置一个测试域名，用来验证SSO授权
```nginx
server {
    listen 80;
    server_name test.dev.example.com;

    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name test.dev.example.com;

    include /config/nginx/snippets/ssl.conf;
    include /config/nginx/snippets/authelia-location.conf;

    # 在这个目录下放一些html文件
    root /config/nginx/data/html;
    index index.html;

    location / {
        include /config/nginx/snippets/proxy.conf;
        include /config/nginx/snippets/authelia-authrequest.conf;
        try_files $uri $uri/ /index.html =404;
    }
}
```

### 请检查一遍ngix相关配置是否正确，特别是各个文件的路径
运行nginx容器
```bash
sudo docker compose up -d
```

# 验证
用浏览器访问`https://test.dev.example.com`，应该会跳转到登录界面