#!/bin/bash

# Check if the postgres:13 image already exists
if ! docker images | grep -q "postgres.*13"; then
    echo "The postgres:13 image does not exist. Pulling the image..."
    docker pull postgres:13
else
    echo "The postgres:13 image already exists."
fi

# Check if a container named kong-database is currently running
if docker ps --filter "name=kong-database" --format "{{.Names}}" | grep -q "kong-database"; then
    # Container exists, check if it's running
    isRunning=$(docker inspect -f "{{.State.Running}}" kong-database)
    if [ "$isRunning" == "true" ]; then
        echo "Docker container kong-database is already running."
    else
        echo "Docker container kong-database exists but is not running. Starting the container."
        docker start kong-database
    fi
else
    echo "Docker container kong-database does not exist. Running a new container."
    docker run -d \
      --name kong-database \
      --restart always \
      -e POSTGRES_USER=kong \
      -e POSTGRES_DB=kong \
      -e POSTGRES_PASSWORD=kong \
      -p 5432:5432 \
      postgres:13
fi
