#!/bin/bash

# Read .env file and get the value of PUBLIC_SERVICE_ADDRESS variable
PUBLIC_SERVICE_ADDRESS=$(grep "PUBLIC_SERVICE_ADDRESS" .env | cut -d '=' -f2)

# Check if PUBLIC_SERVICE_ADDRESS exists in the .env file
if [[ -z "$PUBLIC_SERVICE_ADDRESS" ]]; then
    echo "Could not find the PUBLIC_SERVICE_ADDRESS variable in the .env file."
    exit 1
fi

# Extract USED_PORTS from PUBLIC_SERVICE_ADDRESS
USED_PORTS=$(echo "$PUBLIC_SERVICE_ADDRESS" | cut -d ':' -f2)

# Generate a random port between 1024 and 65535
generate_random_port() {
    while :; do
        PUBLIC_SERVICE_PORT=$((RANDOM % 64512 + 1024))
        
        # Check if the port is already in use
        if ss -tuln | grep -q ":$PUBLIC_SERVICE_PORT"; then
            echo "Port $PUBLIC_SERVICE_PORT is in use. Generating a new random port."
            continue
        fi
        
        # Check if the port is in USED_PORTS
        if [[ "$USED_PORTS" == *"$PUBLIC_SERVICE_PORT"* ]]; then
            echo "Port $PUBLIC_SERVICE_PORT is in USED_PORTS. Generating a new random port."
            continue
        fi

        break
    done
}

generate_random_port

echo "Selected random port: $PUBLIC_SERVICE_PORT"

# Read .env file and get the value of CONSUL_SERVER variable
CONSUL_SERVER=$(grep "CONSUL_SERVER" .env | cut -d '=' -f2)

# Check if CONSUL_SERVER exists in the .env file
if [[ -z "$CONSUL_SERVER" ]]; then
    echo "Could not find the CONSUL_SERVER variable in the .env file."
    exit 1
fi

echo "Using Consul Server IP address: $CONSUL_SERVER"

# Check if the Docker image user_service_image:latest exists
if docker images user_service_image:latest --format "{{.Repository}}:{{.Tag}}" | grep -q "user_service_image:latest"; then
    echo "Docker image user_service_image:latest already exists. Skipping docker build."
else
    echo "Docker image user_service_image:latest does not exist. Starting docker build."
    docker build -t user_service_image .
fi

# Check if a container named user_service exists
if docker ps -a --format "{{.Names}}" | grep -q "^user_service$"; then
    echo "Docker container user_service already exists. Removing the container."
    docker rm -f user_service
fi

# Run a new container
echo "Running a new container user_service."
docker run -d \
--name user_service \
-p $PUBLIC_SERVICE_PORT:$PUBLIC_SERVICE_PORT \
-e "CONSUL_LOCAL_CONFIG={\"leave_on_terminate\": true, \"ui_config\": {\"enabled\": true}}" \
-e CONSUL_SERVER=$CONSUL_SERVER \
-e PUBLIC_SERVICE_ADDRESS=$PUBLIC_SERVICE_ADDRESS \
-e PUBLIC_SERVICE_PORT=$PUBLIC_SERVICE_PORT \
user_service_image \
sh -c "consul agent -node=user_service_node -bind=0.0.0.0 -client=0.0.0.0 -retry-join=$CONSUL_SERVER -data-dir=/tmp/consul & python3 main.py"