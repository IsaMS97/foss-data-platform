#!/bin/sh
set -eu

CERT_DIR=/certs

mkdir -p "$CERT_DIR"

if [ ! -f "$CERT_DIR/ca.crt" ] || [ ! -f "$CERT_DIR/wildcard.crt" ] || [ ! -f "$CERT_DIR/wildcard.key" ]; then
  apk add --no-cache openssl >/dev/null 2>&1

  rm -f \
    "$CERT_DIR/ca.key" \
    "$CERT_DIR/ca.crt" \
    "$CERT_DIR/ca.srl" \
    "$CERT_DIR/wildcard.key" \
    "$CERT_DIR/wildcard.csr" \
    "$CERT_DIR/wildcard.crt" \
    "$CERT_DIR/combined-ca.crt"

  openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout "$CERT_DIR/ca.key" \
    -out "$CERT_DIR/ca.crt" \
    -subj '/CN=Local Platform Root CA' \
    -addext 'basicConstraints=critical,CA:true,pathlen:1' \
    -addext 'keyUsage=critical,keyCertSign,cRLSign' \
    -addext 'subjectKeyIdentifier=hash'

  openssl req -new -newkey rsa:2048 -nodes \
    -keyout "$CERT_DIR/wildcard.key" \
    -out "$CERT_DIR/wildcard.csr" \
    -subj '/CN=localhost' \
    -addext 'subjectAltName=DNS:localhost,DNS:dockhand.localhost,DNS:s3.localhost,DNS:storage.localhost,DNS:catalog.localhost,DNS:keycloak.localhost' \
    -addext 'basicConstraints=critical,CA:FALSE' \
    -addext 'keyUsage=critical,digitalSignature,keyEncipherment' \
    -addext 'extendedKeyUsage=serverAuth'

  openssl x509 -req -in "$CERT_DIR/wildcard.csr" \
    -CA "$CERT_DIR/ca.crt" \
    -CAkey "$CERT_DIR/ca.key" \
    -CAcreateserial \
    -out "$CERT_DIR/wildcard.crt" \
    -days 365 \
    -sha256 \
    -copy_extensions copyall

  cp "$CERT_DIR/ca.crt" "$CERT_DIR/combined-ca.crt"

  echo "Generated local certificates in $CERT_DIR"
else
  echo "Certificates already present in $CERT_DIR; skipping generation"
fi
