@echo off

:: container name
set postgres_name=postgres
set analytics_name=analytics
set redis_name=redis

:: container environment
set postgres_user_name=postgres
set postgres_user_password=123456
set postgres_db=sugo

:: postgres
docker volume create pgdata

docker run ^
--name postgres ^
--rm ^
-d ^
-e POSTGRES_USER=%postgres_user_name% ^
-e POSTGRES_PASSWORD=%postgres_user_password% ^
-e POSTGRES_DB=%postgres_db% ^
-v pgdata:/var/lib/postgresql/data ^
-p 127.0.0.1:5432:5432 ^
postgres:9.6

echo "postgres ready"

:: redis
docker run ^
--name %redis_name% ^
--rm ^
-d ^
-p 127.0.0.1:6379:6379 ^
-v //c/users/meicai/workspace/redis:/data ^
redis:3.2

echo "redis ready"

:: run sugo image
docker run ^
--name %analytics_name% -td ^
--rm ^
--link %postgres_name%:%postgres_name% ^
--link %redis_name%:%redis_name% ^
-p 127.0.0.1:8080:8080 ^
-p 9229:9229 ^
-v //c/users/meicai/workspace/sugo:/opt/sugo ^
sugo:1.0

echo "ubuntu container for sugo-analytics named %container_name%"

:: Entry purr container
docker exec -it %analytics_name% bash
