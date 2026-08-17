#!/bin/sh
set -eu

BASE_URL="${KEYCLOAK_BASE_URL:-https://${KEYCLOAK_PUBLIC_HOST:-keycloak.${PLATFORM_BASE_DOMAIN:-localhost}}}"
REALM="${KEYCLOAK_REALM:-foss-platform}"
USER="${KEYCLOAK_USER:-demo-developer}"
PASS="${KEYCLOAK_PASS:-demo-developer}"
CLIENT_ID="${KEYCLOAK_CLIENT_ID:-admin-cli}"
SCOPE="${KEYCLOAK_SCOPE:-openid profile email roles}"

echo "Requesting token from ${BASE_URL}/realms/${REALM}/protocol/openid-connect/token"

TOKEN_JSON=$(curl -ksS -X POST "${BASE_URL}/realms/${REALM}/protocol/openid-connect/token" \
	-H 'content-type: application/x-www-form-urlencoded' \
	--data-urlencode "grant_type=password" \
	--data-urlencode "client_id=${CLIENT_ID}" \
	--data-urlencode "scope=${SCOPE}" \
	--data-urlencode "username=${USER}" \
	--data-urlencode "password=${PASS}")

ACCESS_TOKEN=$(printf '%s' "$TOKEN_JSON" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("access_token",""))')

if [ -z "$ACCESS_TOKEN" ]; then
	echo "No access_token returned. Full response:"
	echo "$TOKEN_JSON"
	exit 1
fi

python3 - "$ACCESS_TOKEN" <<'PY'
import base64
import json
import sys

jwt = sys.argv[1]
parts = jwt.split('.')
if len(parts) < 2:
		print('Invalid token')
		sys.exit(1)

payload = parts[1] + '=' * (-len(parts[1]) % 4)
claims = json.loads(base64.urlsafe_b64decode(payload.encode()))

print('iss:', claims.get('iss'))
print('aud:', claims.get('aud'))
print('azp:', claims.get('azp'))
print('scope:', claims.get('scope'))
print('preferred_username:', claims.get('preferred_username'))
print('realm_access:', claims.get('realm_access'))
ra = claims.get('resource_access') or {}
print('resource_access keys:', sorted(ra.keys()))
print('resource_access.account:', ra.get('account'))
print('resource_access.account-console:', ra.get('account-console'))
PY

echo "\nuserinfo response:"
curl -ksS "${BASE_URL}/realms/${REALM}/protocol/openid-connect/userinfo" \
	-H "Authorization: Bearer ${ACCESS_TOKEN}" | python3 -m json.tool
