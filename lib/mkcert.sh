#!/usr/bin/env bash
# MKCert Bash API
# https://github.com/FiloSottile/mkcert

### MKCert

function mkcert_install {
    echo "[+] Installing mkcert (https://github.com/FiloSottile/mkcert)..."
    if brew --version > /dev/null; then
        brew install mkcert
    fi
}

function generate_cert {
    DOMAIN="$1"
    mkcert_install
    echo "[+] Generating self-signed cert for $DOMAIN using mkcert..."
    cd /tmp || exit 1
    mkcert "$DOMAIN"
    mv "$DOMAIN.pem" "$CERTS_DIR/$DOMAIN.crt"
    mv "$DOMAIN-key.pem" "$CERTS_DIR/$DOMAIN.key"
}
