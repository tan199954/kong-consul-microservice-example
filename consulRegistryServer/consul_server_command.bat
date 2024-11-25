@echo off

REM Kiểm tra xem Docker image hashicorp/consul:latest có tồn tại không
docker images hashicorp/consul:latest --format "{{.Repository}}:{{.Tag}}" | findstr "hashicorp/consul:latest" > nul
if %errorlevel%==0 (
    echo "Docker image hashicorp/consul:latest đã tồn tại, bỏ qua bước docker pull."
) else (
    echo "Docker image hashicorp/consul:latest chưa tồn tại, thực hiện docker pull."
    docker pull hashicorp/consul
)

REM Tiếp tục chạy container

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