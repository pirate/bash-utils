#!/usr/bin/env bash
# LetsEncyrpt Bash API

REQUIRES_FUNCS info json_api get_rootdomain get_subdomain
# REQUIRES_FUNCS and other global helpers are defined in base.sh:
# https://github.com/pirate/bash-utils/blob/master/util/base.sh#:~:text=REQUIRES_FUNCS

### Global Variables

SSL_EMAIL='ssl@zalad.io'

### LetsEncyrpt

function letsencrypt_install {
    info "Installing letsencrypt..."
    if brew --version > /dev/null; then
        python3 --version > /dev/null || brew install python3
        pip3 --quiet install certbot \
                     certbot-nginx \
                     certbot-dns-digitalocean \
                     certbot-dns-cloudflare
    else
        apt-get install software-properties-common
        add-apt-repository -y -n universe
        add-apt-repository -y -n ppa:certbot/certbot
        apt update -qq
        apt install -y \
            certbot \
            python3-certbot-nginx \
            python3-certbot-dns-digitalocean \
            python3-certbot-dns-cloudflare
    fi
}

function generate_cert {
    DOMAIN="$1"; PROVIDER="${2:-cloudflare}"
    letsencrypt_install

    info "Generating live SSL cert for $DOMAIN using letsencrypt + $PROVIDER..."

    CMD=(
        certbot
        certonly
        --agree-tos
        -m "$SSL_EMAIL"
        --non-interactive
        --config-dir "$TMP_DIR"
        --work-dir "$TMP_DIR"
        --logs-dir "$TMP_DIR"
        --domain "$DOMAIN"
    )

    CONTENT_BEFORE=$(cat "$TMP_DIR/live/$DOMAIN/privkey.pem")
    if [[ "$CONTENT_BEFORE" ]]; then
        CMD+=(--keep-until-expiring)
    else
        CMD+=(--force-renewal)
    fi

    if [[ "$PROVIDER" == "standalone" ]] || [[ "$PROVIDER" == "manual" ]]; then
        CMD+=("--$PROVIDER")
    elif [[ "$PROVIDER" == "webroot" ]]; then
        CMD+=("--webroot" "--webroot-path=$WEBROOT_DIR")
    else
        CMD+=("--dns-$PROVIDER" "--dns-$PROVIDER-credentials=$CREDENTIALS_FILE")
    fi

    if eval "${CMD[*]}"; then
        echo "[i] Certbot returned exit status=$?"
    fi

    CONTENT_AFTER=$(cat "$TMP_DIR/live/$DOMAIN/privkey.pem")

    if [[ ! "$CONTENT_AFTER" ]]; then
        echo "[X] Generated certificate was not found in $TMP_DIR/live/$DOMAIN"
        exit 1
    elif [[ "$CONTENT_BEFORE" != "$CONTENT_AFTER" ]]; then
        cp -L "$TMP_DIR/live/$DOMAIN/fullchain.pem" "$CERTS_DIR/$DOMAIN.crt"
        cp -L "$TMP_DIR/live/$DOMAIN/privkey.pem" "$CERTS_DIR/$DOMAIN.key"
        echo "[$(date +"%Y-%m-%d %H:%M")] Renewed SSL certificate succesfully."
    else
        echo "[$(date +"%Y-%m-%d %H:%M")] SSL certificate already up-to-date."
    fi
}
