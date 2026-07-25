"""Bootstrap Lakekeeper and create the default warehouse."""

from __future__ import annotations

import json
import os
import ssl
import time
from pathlib import Path
from typing import Any
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


CA_BUNDLE = Path("/etc/ssl/certs/ca-certificates.crt")

MAX_ATTEMPTS = 30
RETRY_DELAY_SECONDS = 2.0


def build_context() -> ssl.SSLContext:
    if CA_BUNDLE.exists():
        return ssl.create_default_context(cafile=str(CA_BUNDLE))
    return ssl.create_default_context()


def request_json(
    method: str,
    url: str,
    *,
    context: ssl.SSLContext,
    headers: dict[str, str] | None = None,
    body: Any = None,
) -> Any:
    request_headers = {"Accept": "application/json"}
    if headers:
        request_headers.update(headers)

    data: bytes | None = None
    if body is not None:
        request_headers["Content-Type"] = "application/json"
        data = json.dumps(body).encode("utf-8")

    request = Request(url, data=data, headers=request_headers, method=method)
    last_error: Exception | None = None

    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            with urlopen(request, context=context, timeout=30) as response:
                response_body = response.read()
                if not response_body:
                    return None
                return json.loads(response_body)
        except OSError as error:
            last_error = error
            if attempt == MAX_ATTEMPTS:
                raise
            time.sleep(RETRY_DELAY_SECONDS)

    if last_error is not None:
        raise last_error
    return None


def request_token(context: ssl.SSLContext) -> str:
    token_endpoint = os.getenv(
        "LAKEKEEPER_BOOTSTRAP_TOKEN_ENDPOINT",
        "https://keycloak.localhost/realms/foss-platform/protocol/openid-connect/token",
    )
    form_fields = {
        "client_id": os.getenv("LAKEKEEPER_BOOTSTRAP_CLIENT_ID", "spark"),
        "scope": os.getenv("LAKEKEEPER_BOOTSTRAP_SCOPE", "openid profile"),
    }

    username = os.getenv("LAKEKEEPER_BOOTSTRAP_USERNAME")
    password = os.getenv("LAKEKEEPER_BOOTSTRAP_PASSWORD")
    if username and password:
        form_fields.update(
            {
                "grant_type": "password",
                "username": username,
                "password": password,
            }
        )
    else:
        form_fields.update(
            {
                "grant_type": "client_credentials",
                "client_secret": os.getenv("LAKEKEEPER_BOOTSTRAP_CLIENT_SECRET", ""),
            }
        )

    form_data = urlencode(form_fields).encode("utf-8")
    request = Request(
        token_endpoint,
        data=form_data,
        headers={"Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json"},
        method="POST",
    )

    last_error: Exception | None = None

    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            with urlopen(request, context=context, timeout=30) as response:
                payload = json.loads(response.read())
            return payload["access_token"]
        except HTTPError as error:
            body = error.read().decode("utf-8", errors="replace")
            raise RuntimeError(
                "Token request failed with "
                f"HTTP {error.code} from {token_endpoint}. Response body: {body}. "
                "If this is unauthorized_client or invalid_grant, ensure the realm import "
                "is reapplied and direct access grants are enabled for the lakekeeper client."
            ) from error
        except OSError as error:
            last_error = error
            if attempt == MAX_ATTEMPTS:
                raise
            time.sleep(RETRY_DELAY_SECONDS)

    if last_error is not None:
        raise last_error
    raise RuntimeError("Failed to acquire Lakekeeper bootstrap token")


def ensure_bootstrapped(base_url: str, context: ssl.SSLContext, token: str) -> None:
    headers = {"Authorization": f"Bearer {token}"}
    info = request_json("GET", f"{base_url}/info", context=context, headers=headers)
    if info and info.get("bootstrapped"):
        return

    request_json(
        "POST",
        f"{base_url}/bootstrap",
        context=context,
        headers=headers,
        body={
            "accept-terms-of-use": True,
            "is-operator": True,
            "user-name": os.getenv("LAKEKEEPER_BOOTSTRAP_USER_NAME", "Lakekeeper bootstrap"),
            "user-email": os.getenv(
                "LAKEKEEPER_BOOTSTRAP_USER_EMAIL", "lakekeeper-bootstrap@example.local"
            ),
        },
    )


def ensure_warehouse(base_url: str, context: ssl.SSLContext, token: str) -> None:
    warehouse_name = os.getenv("LAKEKEEPER_BOOTSTRAP_WAREHOUSE_NAME", "lakehouse")
    headers = {"Authorization": f"Bearer {token}"}

    response = request_json("GET", f"{base_url}/warehouse", context=context, headers=headers)
    warehouses = (response or {}).get("warehouses", [])
    if any(warehouse.get("name") == warehouse_name for warehouse in warehouses):
        return

    try:
        request_json(
            "POST",
            f"{base_url}/warehouse",
            context=context,
            headers=headers,
            body={
                "warehouse-name": warehouse_name,
                "delete-profile": {"type": "hard"},
                "storage-credential": {
                    "type": "s3",
                    "credential-type": "access-key",
                    "aws-access-key-id": os.getenv("RUSTFS_ACCESS_KEY", "rustfsadmin"),
                    "aws-secret-access-key": os.getenv("RUSTFS_SECRET_KEY", ""),
                },
                "storage-profile": {
                    "type": "s3",
                    "bucket": os.getenv("LAKEKEEPER_BOOTSTRAP_BUCKET", "lakehouse"),
                    "region": os.getenv("LAKEKEEPER_BOOTSTRAP_REGION", "local-01"),
                    "endpoint": os.getenv("LAKEKEEPER_BOOTSTRAP_ENDPOINT", "https://s3.localhost"),
                    "key-prefix": os.getenv("LAKEKEEPER_BOOTSTRAP_KEY_PREFIX", ""),
                    "flavor": "s3-compat",
                    "path-style-access": True,
                    "remote-signing-enabled": True,
                    "sts-enabled": True,
                },
            },
        )
    except HTTPError as error:
        if error.code != 409:
            raise


def main() -> int:
    context = build_context()
    base_url = os.getenv("LAKEKEEPER_BOOTSTRAP_MANAGEMENT_URL", "http://lakekeeper:8181/management/v1")
    token = request_token(context)

    ensure_bootstrapped(base_url, context, token)
    ensure_warehouse(base_url, context, token)

    print("Lakekeeper bootstrapped and default warehouse ensured.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())