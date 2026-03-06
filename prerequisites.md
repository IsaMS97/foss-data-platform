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



## Client side

If you want to deploy with a single command, you can use the deploy.ps1 in the deployment folder. To do so, duplicate the config.example.json as config.json and update its properties.
