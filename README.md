# RedstoneServer

This is the server of a self-hosted CLI backup tool for my final graduation project.

[Click here](https://github.com/hammsvietro/redstone) if you’re looking for the client.

## Deployment using docker compose:

```bash
mkdir ~/redstone-data -m 777
mkdir ~/redstone-db

export main_app_secret=YOUR_SECRET
export db_name=DB_NAME
export db_user=DB_USER
export db_password=DB_PASSWORD

docker-compose up -d
```

The server will be listening for http connections in the port 4000.
