import os
from pyiceberg.catalog.rest import RestCatalog


def get_catalog(base_domain: str) -> RestCatalog:
    catalog_uri = f"https://catalog.{base_domain}/catalog"
    token_endpoint = f"https://keycloak.{base_domain}/realms/foss-platform/protocol/openid-connect/token"
    catalog = RestCatalog(
        name="lakekeeper-smoke-test",
        **{
            "uri": catalog_uri,
            "credential": os.getenv("LAKEKEEPER_CREDENTIAL", "spark:spark-local-dev-secret"),
            "scope": os.getenv("LAKEKEEPER_OAUTH_SCOPE", "openid profile"),
            "oauth2-server-uri": token_endpoint,
            "warehouse": os.getenv("LAKEKEEPER_WAREHOUSE", "lakehouse"),
        },
    )
    return catalog