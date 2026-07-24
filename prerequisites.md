# Prerequisites

## Serve side

Server must have docker and docker compose installed

### RustFS

Set permissions for ownership to match the container user (UID 10001)  
You can find these two folders under /infra  

```bash
sudo chown -R 10001:10001 rustfs_data rustfs_logs
```

Create and edit the enviroment file

```bash
nano .env
```

Add this to your configuration to specify your username and password. Please change the password from default to a personal choice.

```bash
# RustFS Access Key (username)
RUSTFS_ACCESS_KEY=rustfsadmin

# RustFS Secret Key (password - CHANGE THIS!)
RUSTFS_SECRET_KEY=your-super-secure-secret-key-minimum-8-chars 
```

## Client side

If you want to deploy with a single command, you can use the deploy.ps1 in the deployment folder. To do so, duplicate the config.example.json as config.json and update its properties.

On first launch, certificates are being generated under /infra/certificates. Check out [how to install them](docs/certificate-trust.md) to avoid ssl issues.
