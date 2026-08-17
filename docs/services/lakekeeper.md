# Lakekeeper

Lakekeeper provides the Iceberg REST catalog API and UI for metadata, governance, and access control.

## Access

Once the stack is running, Lakekeeper is exposed through Caddy at:

- https://catalog.localhost

## Out-of-box authentication

Lakekeeper is preconfigured to use Keycloak as its OpenID Connect provider in local development.

Configured values in `infra/docker-compose.yml`:


 Lakekeeper resolves `keycloak.localhost` through `host-gateway`, so the container can fetch OIDC metadata and JWKS from the same HTTPS URL the browser uses.

The matching Keycloak realm import is defined in `infra/keycloak/realm-import.json` and includes the `lakekeeper` client plus the `lakekeeper` client scope with an audience mapper.

Lakekeeper also boots with a default warehouse named `lakehouse` that points at the `lakehouse` bucket in RustFS.

## Demo login

After startup, sign in to Lakekeeper UI with the imported demo user:

- Username: `demo-developer`
- Password: `demo-developer`

## Machine auth

The Keycloak import also provisions a machine client for query engines:

- Client ID: `spark`
- Client secret: `spark-local-dev-secret`

Use the client-credentials flow against `https://keycloak.localhost/realms/foss-platform/protocol/openid-connect/token` with the `lakekeeper` audience already mapped into the token.

## Notes

- This setup is intended for local development.
- If Keycloak data already exists, realm-import changes are not re-applied automatically. Use the `reset_keycloak` script to recreate Keycloak state and re-import the realm.
