#!/bin/bash

# Check if the Docker image hashicorp/consul:1.20.1 exists
if docker images hashicorp/consul:1.20.1 --format "{{.Repository}}:{{.Tag}}" | grep -q "hashicorp/consul:1.20.1"; then
    echo "Docker image hashicorp/consul:1.20.1 already exists. Skipping docker pull."
else
    echo "Docker image hashicorp/consul:1.20.1 does not exist. Starting docker pull."
    docker pull hashicorp/consul:1.20.1
fi

# Check if a container named consul-server exists
if docker ps -a --format "{{.Names}}" | grep -q "^consul-server$"; then
    # Container exists, check if it's running
    isRunning=$(docker inspect -f "{{.State.Running}}" consul-server)
    if [ "$isRunning" = "true" ]; then
        echo "Docker container consul-server is already running."
    else
        echo "Docker container consul-server exists but is not running. Starting the container."
        docker start consul-server
    fi
else
    echo "Docker container consul-server does not exist. Running a new container."
    docker run --name consul-server \
    -d \
    -p 8500:8500 \
    -p 8600:8600/udp \
    -p 8301:8301 \
    -e "CONSUL_LOCAL_CONFIG={\"skip_leave_on_interrupt\": true, \"ports\": {\"dns\": 8600}, \"recursors\": [\"8.8.8.8\"], \"autopilot\": {\"cleanup_dead_servers\": true, \"last_contact_threshold\": \"200ms\", \"server_stabilization_time\": \"10s\", \"max_trailing_logs\": 250}}" \
    hashicorp/consul:1.20.1 agent -server -bootstrap-expect=1 \
    -ui \
    -client=0.0.0.0 \
    -data-dir=/tmp/consul
fi