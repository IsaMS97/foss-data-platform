# Installing the local CA certificate on Fedora, Debian, and Windows (WSL)

This project uses a local root CA certificate in `infra/certificates/ca.crt`.

To trust the local HTTPS endpoints such as `dockhand.localhost`, `s3.localhost`, `storage.localhost`, and `catalog.localhost`, install the CA into the operating system trust store.

## Fedora

Copy the CA into the Fedora trust anchor directory and update the trust store:

```bash
sudo cp infra/certificates/ca.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```

Then restart the browser or open a fresh browser session.

## Debian / Ubuntu

Copy the CA into the Debian CA directory and refresh the certificate store:

```bash
sudo cp infra/certificates/ca.crt /usr/local/share/ca-certificates/local-platform-root-ca.crt
sudo update-ca-certificates
```

Then restart the browser.

## Windows (when Docker Compose is running in WSL)

If your browser is running on Windows, but Docker Compose is running inside WSL, the Windows browser must trust the CA from the Windows certificate store.

### Option 1: use the Windows certificate manager

1. From WSL, copy the file to a Windows-accessible path, for example:

```bash
cp infra/certificates/ca.crt /mnt/c/Users/<your-user>/Downloads/local-platform-root-ca.crt
```

2. Open the file in Windows File Explorer.
3. Install it as a trusted root certificate.
4. Restart the browser.

### Option 2: install it from PowerShell

In PowerShell as an Administrator:

```powershell
Import-Certificate -FilePath "C:\Users\<your-user>\Downloads\local-platform-root-ca.crt" -CertStoreLocation Cert:\CurrentUser\Root
```

Then reopen the browser.

## Notes

- The file you want to trust is `infra/certificates/ca.crt`.
- If a browser still warns after importing the CA, close and reopen the browser completely.
- If Docker Compose is run from WSL, browser trust still needs to be configured in the environment where the browser itself is running.

## Python tooling note

Some Python HTTP clients can use a packaged CA bundle (for example, certifi) instead of your OS trust store.

Make sure `pip-system-certs` is included so Python is patched to use system trust.
