#!/usr/bin/env bash

SCRIPTNAME="$0"
VERSION="0.0.1"

. ./util/base.sh
. ./util/logging.sh
. ./util/config.sh
. ./util/dns.sh

REQUIRES_FUNCS dns_lookup get_public_ip config_load_all config_validate repeated timed


# shellcheck disable=SC2034
HELP_TEXT="
    $SCRIPTNAME v$VERSION
    
    Helper script to generate SSL certificates.

Usage:
    $SCRIPTNAME --domain=example.com --method=[mkcert|openssl|letsencryt] [--letsencrypt-method=standalone|webroot|cloudflare|digitalocean|manual]

Examples:
    $SCRIPTNAME example.l
    $SCRIPTNAME example.l mkcert
    $SCRIPTNAME example.com openssl
    $SCRIPTNAME example.com letsencrypt
    $SCRIPTNAME example.com letsencrypt digitalocean
"

### Config

# shellcheck disable=SC2034
declare -A SSL_CLI_ARGS=(
    # Flag Arguments
    [GET]='-g|--get'
    [PROXIED]='-p|--proxied'
    
    # Named Arguments
    [DOMAIN]='-d|--domain|-d=*|--domain=*'
    [TYPE]='-t|--type|-t=*|--type=*'
    [SET]='-s|--set|-s=*|--set=*'
    [TTL]='-l|-l=*|--ttl|--ttl=*'
    [API]='-a|-a=*|--api|--api=*'

    # Positional Arguments
    # [DOMAIN]='*'
    # [TYPE]='*'
    # [SET]='*'
)
merge_arrays CLI_ARGS BASE_CLI_ARGS SSL_CLI_ARGS

# shellcheck disable=SC2034
declare -A SSL_CONFIG_DEFAULTS=(
    [DOMAIN]=''
    [TYPE]='A'
    [GET]=''
    [SET]=''

    [API]='all'
    [TTL]='default'
    [PROXIED]='false'

    [CF_API_KEY]="$API_KEY_PLACEHOLDER"
    [CF_DEFAULT_TTL]=1

    [DO_API_KEY]="$API_KEY_PLACEHOLDER"
    [DO_DEFAULT_TTL]=300
)
merge_arrays CONFIG_DEFAULTS BASE_CONFIG_DEFAULTS SSL_CONFIG_DEFAULTS
declare -A CONFIG

# shellcheck disable=SC2016 disable=SC2034
declare -A CONFIG_VALIDATORS=(
    [DOMAIN]='[[ "${CONFIG[DOMAIN]}" ]]'
    [METHOD]='[[ "${CONFIG[METHOD]}" ]]'
)
merge_arrays CONFIG_VALIDATORS BASE_CONFIG_VALIDATORS SSL_CONFIG_VALIDATORS



function generate_cert {
    local METHOD="$1" DOMAIN="$2"

    DOMAIN_IP="$(dns_lookup "$DOMAIN")"
    PUBLIC_IP="$(get_public_ip)"

    if [[ "$DOMAIN_IP" == "$PUBLIC_IP" ]]; then
        echo "[√] Domain $DOMAIN DNS A record resolves to my IP $DOMAIN_IP."
    else
        if [[ "$DOMAIN_IP" ]]; then
            echo "[!] Warning: Domain $DOMAIN DNS A record resolves to $DOMAIN_IP (this server's IP is $PUBLIC_IP)!"
        else
            if [[ "$METHOD" != "openssl" ]] && [[ "$METHOD" != "mkcert" ]]; then
                echo "[!] Warning: Domain $DOMAIN DNS A record is not set up yet!"
            fi
        fi
    fi

    if [[ "$METHOD" == "mkcert" ]]; then
        mkcert_cert "$DOMAIN"
    elif [[ "$METHOD" == "openssl" ]]; then
        openssl_cert "$DOMAIN"
    else
        letsencrypt_cert "$DOMAIN" "$LETSENCRYPT_PROVIDER"
    fi

    if [[ ! "$(cat "$CERTS_DIR/$DOMAIN.dh")" ]]; then
        openssl_dhparam
    fi

    echo
    echo "[√] Done. Your new certificates can be found here:"
    echo "    $CERTS_DIR"
    echo

    ls -l "$CERTS_DIR"
}


function runloop {
    local METHODS="${CONFIG[METHOD]}"

    mkdir -p "${CONFIG[OUT_DIR]}"


    for METHOD in ${METHODS//,/ }; do
        timed "${CONFIG[TIMEOUT]}" \
            generate_cert \
                "$METHOD" \
                "${CONFIG[DOMAIN]}"
    done
}


function main {
    # Load config from file, env variables, and kwargs
    config_load_all CONFIG_DEFAULTS CLI_ARGS "$@"
    config_validate CONFIG_VALIDATORS
    log_start

    repeated "${CONFIG[INTERVAL]}" runloop || return $?
}

main "$@"
