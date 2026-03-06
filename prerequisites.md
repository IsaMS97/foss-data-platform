# Prerequisites

## Serve side

Server must have docker and docker compose installed


### Certificate

After cloning the repo, make sure to put the wildcart cert in infra/certificates/wildcard.crt using

```bash
mkdir -p infra/certificates
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout infra/certificates/wildcard.key \
  -out infra/certificates/wildcard.crt \
  -subj "/CN=*.platform.smith-data.de" \
  -addext "subjectAltName=DNS:*.platform.smith-data.de" \
  -addext "basicConstraints=critical,CA:FALSE" \
  -addext "keyUsage=critical,digitalSignature,keyEncipherment" \
  -addext "extendedKeyUsage=serverAuth"
```

### RustFS

This sets the permissions for ownership to match the container user (UID 10001)

```
sudo chown -R 10001:10001 rustfs_data rustfs_logs
```

Creates the enviroment file

```
nano .env
```

Afterwards, this adds your configuration.

```
# RustFS Access Key (username)
RUSTFS_ACCESS_KEY=rustfsadmin

# RustFS Secret Key (password - CHANGE THIS!)
RUSTFS_SECRET_KEY=your-super-secure-secret-key-minimum-8-chars 
```


## Client side

If you want to deploy with a single command, you can use the deploy.ps1 in the deployment folder. To do so, duplicate the config.example.json as config.json and update its properties.
