#!/bin/bash

# Read .env file and get the value of PUBLIC_SERVICE_IP variable
PUBLIC_SERVICE_IP=$(grep "PUBLIC_SERVICE_IP" .env | cut -d '=' -f2)

# Check if PUBLIC_SERVICE_IP exists in the .env file
if [[ -z "$PUBLIC_SERVICE_IP" ]]; then
    echo "Could not find the PUBLIC_SERVICE_IP variable in the .env file."
    exit 1
fi

# Extract USED_PORTS from PUBLIC_SERVICE_IP
USED_PORTS=$(echo "$PUBLIC_SERVICE_IP" | cut -d ':' -f2)

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

# Read .env file and get the value of CONSUL_SERVER_IP variable
CONSUL_SERVER_IP=$(grep "CONSUL_SERVER_IP" .env | cut -d '=' -f2)

# Check if CONSUL_SERVER_IP exists in the .env file
if [[ -z "$CONSUL_SERVER_IP" ]]; then
    echo "Could not find the CONSUL_SERVER_IP variable in the .env file."
    exit 1
fi

echo "Using Consul Server IP address: $CONSUL_SERVER_IP"

# Check if the Docker image user-service-image:latest exists
if docker images user-service-image:latest --format "{{.Repository}}:{{.Tag}}" | grep -q "user-service-image:latest"; then
    echo "Docker image user-service-image:latest already exists. Skipping docker build."
else
    echo "Docker image user-service-image:latest does not exist. Starting docker build."
    docker build -t user-service-image .
fi


# Run a new container
echo "Running a new container user-service."
docker run -d \
--name user-service-${PUBLIC_SERVICE_IP}-${PUBLIC_SERVICE_PORT} \
-p $PUBLIC_SERVICE_PORT:$PUBLIC_SERVICE_PORT \
-e "CONSUL_LOCAL_CONFIG={\"leave_on_terminate\": true, \"ui_config\": {\"enabled\": true}}" \
-e CONSUL_SERVER_IP=$CONSUL_SERVER_IP \
-e PUBLIC_SERVICE_IP=$PUBLIC_SERVICE_IP \
-e PUBLIC_SERVICE_PORT=$PUBLIC_SERVICE_PORT \
user-service-image \
sh -c "consul agent -node=user_service_${PUBLIC_SERVICE_IP}_${PUBLIC_SERVICE_PORT} -bind=0.0.0.0 -client=0.0.0.0 -retry-join=$CONSUL_SERVER_IP -data-dir=/tmp/consul & python3 main.py"