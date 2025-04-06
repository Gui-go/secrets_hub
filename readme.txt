sudo docker run -d \
  --name vaultwarden \
  -v /vw-data:/data \
  -p 80:80 \
  guigo13/vaultwarden-custom:latest
