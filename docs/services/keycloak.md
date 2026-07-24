# Keycloak

Keycloak provides centralized identity and access management for the platform.

## Purpose

- Authenticate users to platform services through OpenID Connect and OAuth 2.0
- Provide a single admin console for managing realms, clients, and users
- Serve as the identity provider for Lakekeeper and other future services

## Access

Once the stack is running, Keycloak is exposed through Caddy at:

- https://keycloak.localhost

The default admin user can be configured with the following environment variables:

- `KEYCLOAK_ADMIN`
- `KEYCLOAK_ADMIN_PASSWORD`

The database password for the backing Postgres instance can be set with:

- `KEYCLOAK_DB_PASSWORD`

## Initial realm bootstrap

The stack automatically imports a realm definition from `infra/keycloak/realm-import.json` on first startup. It provisions the `foss-platform` realm, the `lakekeeper-developers` group, and a preconfigured Dockhand OIDC client.

### Dockhand OIDC bootstrap

The imported `dockhand-app` confidential OIDC client is configured for:

- Redirect URI: `https://dockhand.localhost/api/auth/oidc/callback`
- Web origin: `https://dockhand.localhost`
- Group claim: `groups` in ID tokens, access tokens, and userinfo responses

The following groups are imported for Dockhand role mapping:

- `dockhand-admins`
- `dockhand-operators`
- `dockhand-viewers`

`dockhand-admin` remains available for compatibility with the existing realm configuration.

The client secret defaults to `dockhand-local-dev-secret`. Override it before the first Keycloak startup with `DOCKHAND_OIDC_CLIENT_SECRET` and configure the same secret in Dockhand.

Use this issuer/discovery URL in Dockhand:

`https://keycloak.localhost/realms/foss-platform/.well-known/openid-configuration`

Dockhand uses this URL server-side during sign-in. The Compose configuration maps `keycloak.localhost` inside the Dockhand container to Caddy's internal address so the discovery request reaches the HTTPS endpoint and uses the same issuer URL as browser clients.

Keycloak imports realm files only when the realm does not already exist. To apply changes to an already initialized local Keycloak instance, either configure the client manually in the Keycloak Admin Console or recreate the `volume-keycloak` Docker volume (which removes all Keycloak data).

## Notes

This configuration uses Keycloak in development mode (`start-dev`) so it is suitable for local self-hosting and quick integration work.
