@echo off


REM Read .env file and get the value of the PUBLIC_SERVICE_IP variable
for /f "delims=" %%i in ('findstr "PUBLIC_SERVICE_IP" .env') do set %%i

REM Check if PUBLIC_SERVICE_IP exists in the .env file
if "%PUBLIC_SERVICE_IP%"=="" (
    echo "Could not find the PUBLIC_SERVICE_IP variable in the .env file."
    exit /b 1
)

REM Extract USED_PORTS from PUBLIC_SERVICE_IP
setlocal enabledelayedexpansion
set USED_PORTS=

for /f "tokens=2 delims=:" %%A in ("%PUBLIC_SERVICE_IP%") do (
    set USED_PORTS=%%A
)

REM Generate a random port between 1024 and 65535
:generate_random_port
set /a PUBLIC_SERVICE_PORT=%RANDOM% * 55312 / 32768 + 1024

REM Check if the random port is already in use
netstat -an | find ":%PUBLIC_SERVICE_PORT%" >nul
if not errorlevel 1 (
    echo "Port %PUBLIC_SERVICE_PORT% is in USED_PORTS. Generating a new random port."
    goto :generate_random_port
)

REM Check if the random port is in USED_PORTS
echo %USED_PORTS% | find "%PUBLIC_SERVICE_PORT%" >nul
if not errorlevel 1 (
    echo "Port %PUBLIC_SERVICE_PORT% is in USED_PORTS. Generating a new random port."
    goto :generate_random_port
)

REM Select the random port for PUBLIC_SERVICE_PORT
echo "Selected random port: %PUBLIC_SERVICE_PORT%"

REM Read the .env file and get the value of the CONSUL_SERVER_IP variable
for /f "delims=" %%i in ('findstr "CONSUL_SERVER_IP" .env') do set %%i

REM Check if CONSUL_SERVER_IP exists in the environment
if "%CONSUL_SERVER_IP%"=="" (
    echo "Could not find the CONSUL_SERVER_IP variable in the .env file."
    exit /b 1
)

echo "Using Consul Server IP address: %CONSUL_SERVER_IP%"

REM Check if the Docker image user-service_image:latest exists
docker images user-service-image:latest --format "{{.Repository}}:{{.Tag}}" | findstr "user-service-image:latest" > nul
if %errorlevel%==0 (
    echo "Docker image user-service-image:latest already exists. Skipping docker build."
) else (
    echo "Docker image user-service-image:latest does not exist. Starting docker build."
    docker build -t user-service-image .
)


REM Run a new container
echo "Running a new container user-service."
docker run -d ^
--name user-service-%PUBLIC_SERVICE_IP%-%PUBLIC_SERVICE_PORT% ^
-p %PUBLIC_SERVICE_PORT%:%PUBLIC_SERVICE_PORT% ^
-e "CONSUL_LOCAL_CONFIG={\"leave_on_terminate\": true, \"ui_config\": {\"enabled\": true}}" ^
-e CONSUL_SERVER_IP=%CONSUL_SERVER_IP% ^
-e PUBLIC_SERVICE_IP=%PUBLIC_SERVICE_IP% ^
-e PUBLIC_SERVICE_PORT=%PUBLIC_SERVICE_PORT% ^
user-service-image ^
sh -c "consul agent -node=user_service_${PUBLIC_SERVICE_IP}_${PUBLIC_SERVICE_PORT} -bind=0.0.0.0 -client=0.0.0.0 -retry-join=$CONSUL_SERVER_IP -data-dir=/tmp/consul & python3 main.py"
