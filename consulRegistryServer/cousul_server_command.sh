#!/bin/bash

# Check if the Docker image hashicorp/consul:latest exists
if docker images hashicorp/consul:latest --format "{{.Repository}}:{{.Tag}}" | grep -q "hashicorp/consul:latest"; then
    echo "Docker image hashicorp/consul:latest already exists. Skipping docker pull."
else
    echo "Docker image hashicorp/consul:latest does not exist. Starting docker pull."
    docker pull hashicorp/consul
fi

# Run the Consul server container
docker run --name consul-server \
-d \
-p 8500:8500 \
-p 8600:8600/udp \
-p 8301:8301 \
-p 8301:8301/udp \
-e "CONSUL_LOCAL_CONFIG={\"skip_leave_on_interrupt\": true}" \
hashicorp/consul agent -server -bootstrap-expect=1 \
-ui \
-bind=0.0.0.0 \
-client=0.0.0.0 \
-data-dir=/tmp/consul
