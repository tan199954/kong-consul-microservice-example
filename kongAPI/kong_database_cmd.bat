@echo off

REM Check if the postgres:13 image already exists
docker images | findstr "postgres.*13" >nul
if errorlevel 1 (
    echo The postgres:13 image does not exist. Pulling the image...
    docker pull postgres:13
) else (
    echo The postgres:13 image already exists.
)

REM Check if a container named kong is currently running
docker ps --filter "name=kong-database" --format "{{.Names}}" | findstr "kong-database" >nul
if not errorlevel 1 (
    REM Container exists, check if it's running
    for /f "tokens=*" %%i in ('docker inspect -f "{{.State.Running}}" kong-database') do set isRunning=%%i
    if "%isRunning%"=="true" (
        echo Docker container kong-database is already running.
    ) else (
        echo Docker container kong-database exists but is not running. Starting the container.
        docker start kong-database
    )
) else (
    echo Docker container kong-database does not exist. Running a new container.
    docker run -d ^
      --name kong-database ^
      --restart always ^
      -e POSTGRES_USER=kong ^
      -e POSTGRES_DB=kong ^
      -e POSTGRES_PASSWORD=kong ^
      -p 5432:5432 ^
      postgres:13
)
