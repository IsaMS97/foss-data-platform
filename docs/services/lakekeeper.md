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

## Demo login

After startup, sign in to Lakekeeper UI with the imported demo user:

- Username: `demo-developer`
- Password: `demo-developer`

## Notes

- This setup is intended for local development.
- If Keycloak data already exists, realm-import changes are not re-applied automatically. Use the `reset_keycloak` script to recreate Keycloak state and re-import the realm.
