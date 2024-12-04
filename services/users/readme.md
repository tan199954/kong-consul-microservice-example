# Windows:
- Create .env file:  
**Note:** Override your value in the **.env** file
```console
echo CONSUL_SERVER_IP=Your_CONSUL_SERVER_IP > .env
echo PUBLIC_SERVICE_IP=Your_Public_Service_Ip >> .env
```
- Run service on docker
```console
user_service_command.bat
```

# Linux:
- Create .env file:  
**Note:** Override your value in the **.env** file
```console
echo "CONSUL_SERVER_IP=Your_CONSUL_SERVER_IP" >> .env
echo "PUBLIC_SERVICE_IP=Your_Public_Service_Ip" >> .env
```
- Run service on docker
```console
chmod +x user_service_command.sh
./user_service_command.sh
```