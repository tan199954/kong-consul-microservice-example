#!/bin/bash

# Load .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo "The .env file does not exist!"
    exit 1
fi

# Check the CONSUL_DNS variable
if [ -z "$CONSUL_DNS" ]; then
    echo "CONSUL_DNS is not defined in the .env file!"
    exit 1
fi

# Check if the kong:latest image already exists
if ! docker images | grep -q "kong.*latest"; then
    echo "The kong:latest image does not exist. Pulling the image..."
    docker pull kong:latest
else
    echo "The kong:latest image already exists."
fi

# Check if a container named kong is currently running
if docker ps --filter "name=kong" --format "{{.Names}}" | grep -q "^kong$"; then
    echo "The kong container is running. Removing the container..."
    docker rm -f kong
else
    echo "No kong container is currently running."
fi

# Run a new container connected to the Consul server
echo "Running the kong container with Consul server $CONSUL_DNS..."
docker run --rm -it --name kong \
    -e "KONG_DNS_RESOLVER=$CONSUL_DNS" \
    -e "KONG_DATABASE=postgres" \
    -e "KONG_PG_HOST=kong-database.service.consul" \
    -e "KONG_PG_PORT=5432" \
    -e "KONG_PG_USER=your_postgres_user" \
    -e "KONG_PG_PASSWORD=your_postgres_password" \
    -e "KONG_PG_DATABASE=your_database_name" \
    kong:latest

if [ $? -eq 0 ]; then
    echo "The kong container has been started successfully!"
else
    echo "An error occurred while starting the kong container."
fi
