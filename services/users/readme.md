# Windows:
- Create .env file:
```console
echo CONSUL_SERVER_ADDRESS=Your_CONSUL_SERVER_ADDRESS > .env
echo PUBLIC_SERVICE_ADDRESS=Your_Public_Service_Addres >> .env
```
- Run service on docker
```console
user_service_command.bat
```

# Linux:
- Create .env file:
```console
echo "CONSUL_SERVER_ADDRESS=Your_CONSUL_SERVER_ADDRESS" >> .env
echo "PUBLIC_SERVICE_ADDRESS=Your_Public_Service_Addres" >> .env
```
- Run service on docker
```console
chmod +x user_service_command.sh
./user_service_command.sh
```