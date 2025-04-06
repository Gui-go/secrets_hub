FROM vaultwarden/server:latest

# Optional: copy config or secrets if needed
COPY env /data/.env

