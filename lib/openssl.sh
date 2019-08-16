#!/usr/bin/env bash
# OpenSSL Bash API

REQUIRES_FUNCS warn json_api get_rootdomain get_subdomain


### Global Variables

SSL_EMAIL='ssl@zalad.io'
SSL_COUNTRY='US'
SSL_STATE='NY'
SSL_CITY='New York'
SSL_ORG='Monadical'
SSL_DIV='Engineering'

DH_SIZE=2048

### OpenSSL

function generate_cert {
    DOMAIN="$1"
    echo "[+] Generating self-signed cert for $DOMAIN using openssl..."
    openssl req \
        -new \
        -newkey rsa:4096 \
        -x509 \
        -sha256 \
        -days 365 \
        -nodes \
        -out "$CERTS_DIR/$DOMAIN.crt" \
        -keyout "$CERTS_DIR/$DOMAIN.key" \
        -subj "/emailAddress=$SSL_EMAIL/C=$SSL_COUNTRY/ST=$SSL_STATE/L=$SSL_CITY/O=$SSL_ORG/OU=$SSL_DIV/CN=$DOMAIN"
}

function generate_dhparam {
    echo "[+] Generating $DH_SIZE bit Diffie-helman parameter file..."
    openssl dhparam -out "$CERTS_DIR/$DOMAIN.dh" "$DH_SIZE"
}
