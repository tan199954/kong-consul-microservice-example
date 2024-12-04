from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
import requests
from contextlib import asynccontextmanager
import os


PUBLIC_SERVICE_IP = os.getenv("PUBLIC_SERVICE_IP")
PUBLIC_SERVICE_PORT = int(os.getenv("PUBLIC_SERVICE_PORT"))

fake_db = [
    {"id": 1, "name": "Alice", "email": "alice@example.com"},
    {"id": 2, "name": "Bob", "email": "bob@example.com"},
    {"id": 3, "name": "Charlie", "email": "charlie@example.com"},
]

class User(BaseModel):
    id: int
    name: str
    email: str
    
CONSUL_HOST = "127.0.0.1"
CONSUL_PORT = 8500
SERVICE_ID = f"user_service_{PUBLIC_SERVICE_IP}_{str(PUBLIC_SERVICE_PORT)}"
SERVICE_NAME = "user_service"


def register_service():
    url = f"http://{CONSUL_HOST}:{CONSUL_PORT}/v1/agent/service/register"
    payload = {
        "ID": SERVICE_ID,
        "Name": SERVICE_NAME,
        "Address": PUBLIC_SERVICE_IP,
        "Port": PUBLIC_SERVICE_PORT,
        "Check": {
            "HTTP": f"http://{PUBLIC_SERVICE_IP}:{PUBLIC_SERVICE_PORT}/health",
            "Interval": "10s",
            "Timeout": "5s",
            "DeregisterCriticalServiceAfter": "1m",
        }
    }
    response = requests.put(url, json=payload)
    if response.status_code == 200:
        print(f"Service {SERVICE_NAME} registered successfully.")
    else:
        print(f"Failed to register service: {response.text}")

def deregister_service():
    url = f"http://{CONSUL_HOST}:{CONSUL_PORT}/v1/agent/service/deregister/{SERVICE_ID}"
    response = requests.put(url)
    if response.status_code == 200:
        print(f"Service {SERVICE_NAME} deregistered successfully.")
    else:
        print(f"Failed to deregister service: {response.text}")

@asynccontextmanager
async def lifespan(app: FastAPI):
    register_service()
    yield
    deregister_service()
    
app = FastAPI(
    lifespan=lifespan, 
    openapi_prefix=f"/{SERVICE_NAME}"
    )

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/")
def read_root():
    return {"message": f"User Service is running in {PUBLIC_SERVICE_PORT}"}

@app.get("/users", response_model=List[User])
def get_users():

    return fake_db

@app.post("/users", response_model=User)
def create_user(user: User):

    for existing_user in fake_db:
        if existing_user["id"] == user.id:
            raise HTTPException(status_code=400, detail="User with this ID already exists")
    
    new_user = user.model_dump(mode="json")
    fake_db.append(new_user)
    return new_user

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=PUBLIC_SERVICE_PORT)