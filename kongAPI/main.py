import os
import requests
from dotenv import load_dotenv

# Load biến môi trường từ file .env
load_dotenv()

# Địa chỉ Consul và Kong từ biến môi trường
CONSUL_ADDRESS = os.getenv("CONSUL_ADDRESS", "http://127.0.0.1:8500")
KONG_ADDRESS = os.getenv("KONG_ADDRESS", "http://127.0.0.1:8001")

def get_services_from_consul():
    """
    Lấy danh sách dịch vụ từ Consul.
    """
    try:
        url = f"{CONSUL_ADDRESS}/v1/agent/services"
        response = requests.get(url)
        response.raise_for_status()
        services = response.json()
        print(services)
        return services
    except Exception as e:
        print(f"Error fetching services from Consul: {e}")
        return {}

def register_service_in_kong(service_name, service_address, service_port):
    """
    Đăng ký một dịch vụ vào Kong.
    """
    try:
        # Đăng ký service vào Kong
        service_url = f"{KONG_ADDRESS}/services"
        payload_service = {
            "name": service_name,
            "url": f"http://{service_address}:{service_port}"
        }
        response_service = requests.post(service_url, json=payload_service)
        if response_service.status_code in [200, 201]:
            print(f"Service '{service_name}' registered successfully in Kong.")
        elif response_service.status_code == 409:  # Service already exists
            print(f"Service '{service_name}' already exists in Kong.")
        else:
            print(f"Failed to register service '{service_name}': {response_service.text}")

        # Đăng ký route cho service
        route_url = f"{KONG_ADDRESS}/services/{service_name}/routes"
        payload_route = {
            "paths": [f"/{service_name}"]
        }
        response_route = requests.post(route_url, json=payload_route)
        if response_route.status_code in [200, 201]:
            print(f"Route for service '{service_name}' created successfully in Kong.")
        elif response_route.status_code == 409:  # Route already exists
            print(f"Route for service '{service_name}' already exists in Kong.")
        else:
            print(f"Failed to create route for service '{service_name}': {response_route.text}")
    except Exception as e:
        print(f"Error registering service '{service_name}' in Kong: {e}")

def sync_services():
    """
    Đồng bộ các dịch vụ từ Consul vào Kong.
    """
    print("Fetching services from Consul...")
    services = get_services_from_consul()
    for service_id, service in services.items():
        service_name = service.get("Service")
        service_address = service.get("Address")
        service_port = service.get("Port")

        if service_name and service_address and service_port:
            print(f"Registering service '{service_name}' in Kong...")
            register_service_in_kong(service_name, service_address, service_port)
        else:
            print(f"Skipping invalid service: {service}")

if __name__ == "__main__":
    sync_services()
