@echo off

REM Check if the Docker image hashicorp/consul:latest exists
docker images hashicorp/consul:latest --format "{{.Repository}}:{{.Tag}}" | findstr "hashicorp/consul:latest" > nul
if %errorlevel%==0 (
    echo "Docker image hashicorp/consul:latest already exists. Skipping docker pull."
) else (
    echo "Docker image hashicorp/consul:latest does not exist. Starting docker docker pull."
    docker pull hashicorp/consul
)

REM Check if a container named consul-server exists
docker ps -a --format "{{.Names}}" | findstr "^consul-server$" >nul
if %errorlevel%==0 (
    echo Docker container consul-server already exists. Starting the container.
    docker start consul-server
) else (
    echo Docker container consul-server does not exist. Running a new container.
    docker run --name consul-server ^
    -d ^
    -p 8500:8500 ^
    -p 8600:8600/udp ^
    -p 8301:8301 ^
    -p 8301:8301/udp ^
    -e "CONSUL_LOCAL_CONFIG={\"skip_leave_on_interrupt\": true}" ^
    hashicorp/consul agent -server -bootstrap-expect=1 ^
    -ui ^
    -bind=0.0.0.0 ^
    -client=0.0.0.0 ^
    -data-dir=/tmp/consul
)