@echo off
:: Run Mysql
docker run ^
--name container_mysql ^
-v //c/workspace/purr/store/mysql:/var/lib/mysql ^
-p 127.0.0.1:3306:3306 ^
-e MYSQL_ROOT_PASSWORD=123456 ^
-e MYSQL_DATABASE=purr ^
-d mysql:latest

echo "container_mysql run in 127.0.0.1:3306:3306"
echo "container_mysql Environment:: MYSQL_ROOT_PASSWORD=123456 MYSQL_DATABASE=purr"

:: Run Redis
docker run ^
--name container_redis ^
-p 127.0.0.1:6379:6379 ^
-v //c/workspace/purr/store/redis ^
-d redis:latest

echo "container_redis run in 127.0.0.1:6379:6379"

:: Run Purr
docker run ^
--name container_purr -td ^
--link container_mysql:container_mysql ^
--link container_redis:container_redis ^
-p 127.0.0.1:8000:8000 ^
-v //c/workspace/purr:/opt/purr ^
nodejs:2.1

echo container_purr run in 127.0.0.1:8000:8000
echo docker for purr running...
