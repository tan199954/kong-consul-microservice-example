@echo off


REM Đọc file .env và lấy giá trị của PUBLIC_SERVICE_ADDRESS
for /f "delims=" %%i in ('findstr "PUBLIC_SERVICE_ADDRESS" .env') do set %%i

REM Kiểm tra nếu PUBLIC_SERVICE_ADDRESS không được đọc
if "%PUBLIC_SERVICE_ADDRESS%"=="" (
    echo "Không tìm thấy biến PUBLIC_SERVICE_ADDRESS trong file .env"
    exit /b 1
)

REM Lấy danh sách các cổng đã tồn tại từ PUBLIC_SERVICE_ADDRESS
setlocal enabledelayedexpansion
set USED_PORTS=

for /f "tokens=2 delims=:" %%A in ("%PUBLIC_SERVICE_ADDRESS%") do (
    set USED_PORTS=%%A
)

REM Tạo cổng ngẫu nhiên từ 1024 đến 65535
:generate_random_port
set /a PUBLIC_SERVICE_PORT=%RANDOM% * 55312 / 32768 + 1024

REM Kiểm tra xem cổng đã tồn tại hay chưa
netstat -an | find ":%PUBLIC_SERVICE_PORT%" >nul
if not errorlevel 1 (
    echo "Cổng %PUBLIC_SERVICE_PORT% đã được sử dụng. Tạo lại..."
    goto :generate_random_port
)

REM Kiểm tra xem cổng có nằm trong USED_PORTS không
echo %USED_PORTS% | find "%PUBLIC_SERVICE_PORT%" >nul
if not errorlevel 1 (
    echo "Cổng %PUBLIC_SERVICE_PORT% nằm trong danh sách cổng đã sử dụng. Tạo lại..."
    goto :generate_random_port
)

REM Gán cổng ngẫu nhiên đã tạo vào PUBLIC_SERVICE_PORT
echo "Cổng ngẫu nhiên đã chọn: %PUBLIC_SERVICE_PORT%"

REM Đọc file .env và lấy giá trị của CONSUL_SERVER
for /f "delims=" %%i in ('findstr "CONSUL_SERVER" .env') do set %%i

REM Kiểm tra nếu biến môi trường không được đọc
if "%CONSUL_SERVER%"=="" (
    echo "Không tìm thấy biến CONSUL_SERVER trong file .env"
    exit /b 1
)

echo "Sử dụng địa chỉ Consul Server: %CONSUL_SERVER%"

REM Kiểm tra xem Docker image user_service_image:latest có tồn tại không
docker images user_service_image:latest --format "{{.Repository}}:{{.Tag}}" | findstr "user_service_image:latest" > nul
if %errorlevel%==0 (
    echo "Docker image user_service_image:latest đã tồn tại, bỏ qua bước docker build."
) else (
    echo "Docker image user_service_image:latest chưa tồn tại, thực hiện docker build."
    docker build -t user_service_image .
)

REM Tiếp tục chạy container

docker run -d ^
--name user_service ^
-p %PUBLIC_SERVICE_PORT%:%PUBLIC_SERVICE_PORT% ^
-e "CONSUL_LOCAL_CONFIG={\"leave_on_terminate\": true, \"ui_config\": {\"enabled\": true}}" ^
-e CONSUL_SERVER=%CONSUL_SERVER% ^
-e PUBLIC_SERVICE_ADDRESS=%PUBLIC_SERVICE_ADDRESS% ^
-e PUBLIC_SERVICE_PORT=%PUBLIC_SERVICE_PORT% ^
user_service_image ^
sh -c "consul agent -node=user_service_node -bind=0.0.0.0 -client=0.0.0.0 -retry-join=$CONSUL_SERVER -data-dir=/tmp/consul & python3 main.py"

