@echo off

:: Load variables from .env file
if not exist .env (
    echo The .env file does not exist!
    exit /b 1
)

for /f "tokens=*" %%i in (.env) do set %%i

:: Check the CONSUL_DNS variable
if "%CONSUL_DNS%"=="" (
    echo CONSUL_DNS is not defined in the .env file!
    exit /b 1
)

:: Check if the kong/kong-gateway:3.8.1.0 image already exists
docker images | findstr "kong/kong-gateway.*3.8.1.0" >nul
if errorlevel 1 (
    echo The kong/kong-gateway:3.8.1.0 image does not exist. Pulling the image...
    docker pull kong/kong-gateway:3.8.1.0
) else (
    echo The kong/kong-gateway:3.8.1.0 image already exists.
)

:: Check if a container named kong is currently running
docker ps --filter "name=kong-gateway" --format "{{.Names}}" | findstr "kong-gateway" >nul
if not errorlevel 1 (
    echo The kong-gateway container is running. Removing the container...
    docker rm -f kong-gateway
) else (
    echo No kong-gateway container is currently running.
)

echo Running the kong container with Consul server %CONSUL_DNS%...

:: Initializes or updates Kong's database schema using migrations.
docker run --rm ^
--name kong-migrations ^
--link kong-database:kong-database ^
-e "KONG_DATABASE=postgres" ^
-e "KONG_PG_HOST=kong-database" ^
-e "KONG_PG_PASSWORD=kong" ^
-e "KONG_PASSWORD=test" ^
kong/kong-gateway:3.8.1.0 kong migrations bootstrap

:: Run a new container connected to the Consul server
docker run -d ^
--name kong-gateway ^
--link kong-database:kong-database ^
-e "KONG_DATABASE=postgres" ^
-e "KONG_PG_HOST=kong-database" ^
-e "KONG_PG_USER=kong" ^
-e "KONG_PG_PASSWORD=kong" ^
-e "KONG_PROXY_ACCESS_LOG=/dev/stdout" ^
-e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" ^
-e "KONG_PROXY_ERROR_LOG=/dev/stderr" ^
-e "KONG_ADMIN_ERROR_LOG=/dev/stderr" ^
-e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" ^
-e "KONG_PROXY_LISTEN=0.0.0.0:8000, 0.0.0.0:8443 ssl" ^
-e "KONG_ADMIN_GUI_URL=http://localhost:8002" ^
-e "KONG_DNS_RESOLVER=%CONSUL_DNS%" ^
-p 8000:8000 ^
-p 8443:8443 ^
-p 8001:8001 ^
-p 8444:8444 ^
-p 8002:8002 ^
-p 8445:8445 ^
-p 8003:8003 ^
-p 8004:8004 ^
kong/kong-gateway:3.8.1.0

if errorlevel 1 (
    echo An error occurred while starting the kong container.
    exit /b 1
) else (
    echo The kong container has been started successfully!
)
