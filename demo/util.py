import os
from pyiceberg.catalog.rest import RestCatalog


def get_catalog() -> RestCatalog:
    catalog = RestCatalog(
        name="lakekeeper-smoke-test",
        **{
            "uri": os.getenv("LAKEKEEPER_URI", "https://catalog.localhost/catalog"),
            "credential": os.getenv("LAKEKEEPER_CREDENTIAL", "spark:spark-local-dev-secret"),
            "scope": os.getenv("LAKEKEEPER_OAUTH_SCOPE", "openid profile"),
            "oauth2-server-uri": os.getenv(
                "LAKEKEEPER_TOKEN_ENDPOINT",
                "https://keycloak.localhost/realms/foss-platform/protocol/openid-connect/token",
            ),
            "warehouse": os.getenv("LAKEKEEPER_WAREHOUSE", "lakehouse"),
        },
    )
    return catalog