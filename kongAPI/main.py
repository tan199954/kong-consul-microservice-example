import os
import requests
from dotenv import load_dotenv


load_dotenv(override=True)

CONSUL_SERVER_ADDRESS = os.getenv("CONSUL_SERVER_ADDRESS", "http://127.0.0.1:8500")
KONG_ADMIN_ADDRESS = os.getenv("KONG_ADMIN_ADDRESS", "http://127.0.0.1:8001")

def get_services_from_consul(consul_server_address: str = "http://127.0.0.1:8500"):
    try:
        url = f"{consul_server_address}/v1/catalog/services"
        response = requests.get(url)
        response.raise_for_status()
        services = response.json()
        # Loại bỏ service gốc "consul"
        filtered_services = {k: v for k, v in services.items() if k != "consul"}
        print("services_from_consul: " , list(filtered_services.keys()))
        return filtered_services
    except Exception as e:
        print(f"Error fetching services from Consul: {e}")
        return {}
    
def register_kong_service(service_name: str, kong_address: str = "http://127.0.0.1:8001") -> bool:
    """
    Register a service in Kong.
    Returns True if the service is successfully registered or already exists.
    """
    try:
        # Define service data
        service_data = {
            "name": service_name,
            "host": f"{service_name}.service.consul"
        }
        
        # Send POST request to Kong Admin API
        response = requests.post(f"{kong_address}/services/", data=service_data)

        # Handle response
        if response.status_code in [200, 201]:
            print(f"Service '{service_name}' registered successfully in Kong.")
            return True
        if response.status_code == 409:  # Conflict: Service already exists
            print(f"Service '{service_name}' already exists in Kong.")
            return True
        
        # Other errors
        print(f"Failed to register service '{service_name}': {response.text}")
        return False
    except requests.RequestException as e:
        print(f"Error connecting to Kong: {e}")
        return False
    except Exception as e:
        print(f"Unexpected error while registering service '{service_name}': {e}")
        return False
        
def register_kong_route(service_name: str, route_name: str, kong_address: str = "http://127.0.0.1:8001") -> bool:
    """
    Register a route in Kong for a specific service.
    Returns True if the route is successfully created or already exists.
    """
    try:
        # Define route data
        route_data = {
            "service.name": service_name,
            "paths[]": f"/{route_name}"
        }
        
        # Send POST request to Kong Admin API
        response = requests.post(f"{kong_address}/routes/", data=route_data)

        # Handle response
        if response.status_code in [200, 201]:
            print(f"Route '{route_name}' for service '{service_name}' created successfully in Kong.")
            return True
        if response.status_code == 409:  # Conflict: Route already exists
            print(f"Route '{route_name}' for service '{service_name}' already exists in Kong.")
            return True

        # Other errors
        print(f"Failed to create route '{route_name}' for service '{service_name}': {response.text}")
        return False
    except requests.RequestException as e:
        print(f"Error connecting to Kong: {e}")
        return False
    except Exception as e:
        print(f"Unexpected error while registering route '{route_name}' for service '{service_name}': {e}")
        return False
    
def register_service_and_route_in_kong(service_name: str, kong_address: str = "http://127.0.0.1:8001") -> bool:
    """
    Register both a service and its corresponding route in Kong.
    Returns True if both operations are successful.
    """
    # Step 1: Register the service
    if not register_kong_service(service_name, kong_address):
        return False
    # Step 2: Register the route for the service
    if not register_kong_route(service_name, service_name, kong_address):
        return False
    return True

def sync_services():
    """
    Sync services from Consul into Kong.
    """
    print("Fetching services from Consul...")
    services = get_services_from_consul(CONSUL_SERVER_ADDRESS)
    print(f"Found {len(services)} services in Consul. Starting synchronization...")
    for service_name in services.keys():
        register_service_and_route_in_kong(service_name, KONG_ADMIN_ADDRESS)

if __name__ == "__main__":
    sync_services()
