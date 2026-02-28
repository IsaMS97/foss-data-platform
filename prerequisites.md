# Prerequisites

Server must have docker and docker compose installed

After cloning the repo, make sure to put the wildcart cert in infra/certificates/wildcard.crt using

```bash
mkdir -p infra/certificates
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout infra/certificates/wildcard.key \
  -out infra/certificates/wildcard.crt \
  -subj "/CN=*.platform.smith-data.de"
```
