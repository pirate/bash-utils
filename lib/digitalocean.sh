#!/usr/bin/env bash
# DigitalOcean Bash API

REQUIRES_FUNCS warn json_api get_rootdomain get_subdomain
# REQUIRES_FUNCS and other global helpers are defined in base.sh:
# https://github.com/pirate/bash-utils/blob/master/util/base.sh#:~:text=REQUIRES_FUNCS

### Global Variables

DO_API_URL="https://api.digitalocean.com/v2"
DO_DEFAULT_TTL=300


function dns_record_url {
    local DOMAIN="$1" TYPE="${2:-A}"

    local ROOTDOMAIN SUBDOMAIN URL JSON_PATH RECORD_ID

    ROOTDOMAIN="$(get_rootdomain "$DOMAIN")"
    SUBDOMAIN="$(get_subdomain "$DOMAIN")"

    URL="$DO_API_URL/domains/$ROOTDOMAIN/records"
    JSON_PATH=".domain_records[] | select(.name == \"$SUBDOMAIN\" and .type == \"$TYPE\") | .id"
    RECORD_ID="$(json_api GET "$URL" "$JSON_PATH" "${CONFIG[DO_API_KEY]}")" || return $?

    if [[ -z "$RECORD_ID" || "$RECORD_ID" == "null" || "$RECORD_ID" == "undefined" ]]; then
        warn "API response from DigitalOcean indicates no record exists for the given domain."
        return 8
    fi

    echo "$DO_API_URL/domains/$ROOTDOMAIN/records/$RECORD_ID"
    return 0
}

function dns_get_record {
    local DOMAIN="$1" TYPE="${2:-A}"

    local URL JSON_PATH

    URL="$(dns_record_url "$DOMAIN" "$TYPE")" || return $?
    JSON_PATH=".domain_record.data"

    json_api GET "$URL" "$JSON_PATH" "${CONFIG[DO_API_KEY]}" || return $?
    return 0
}

function dns_create_record {
    local DOMAIN="$1" TYPE="$2" VALUE="$3" TTL="${4:-$DO_DEFAULT_TTL}";

    local ROOTDOMAIN SUBDOMAIN URL JSON_PATH DATA

    [[ "$TTL" == "default" ]] && TTL="$DO_DEFAULT_TTL"

    ROOTDOMAIN="$(get_rootdomain "$DOMAIN")"
    SUBDOMAIN="$(get_subdomain "$DOMAIN")"

    URL="$DO_API_URL/domains/$ROOTDOMAIN/records"
    JSON_PATH=".domain_record.data"
    DATA='{
        "type": "'$TYPE'",
        "name": "'$SUBDOMAIN'",
        "data": "'$VALUE'",
        "ttl": '$TTL'
    }'

    json_api POST "$URL" "$JSON_PATH" "${CONFIG[DO_API_KEY]}" "$DATA" || return $?
    return 0
}

function dns_set_record {
    local DOMAIN="$1" TYPE="$2" VALUE="$3" TTL="${4:-$DO_DEFAULT_TTL}";

    local ROOTDOMAIN SUBDOMAIN URL JSON_PATH DATA

    [[ "$TTL" == "default" ]] && TTL="$DO_DEFAULT_TTL"
    [[ "$VALUE" == "$ROOTDOMAIN" ]] && VALUE="@"                      # replace root ref with @
    [[ "$TYPE" == "CNAME" && "$VALUE" != "@" ]] && VALUE="${VALUE}."  # append . to CNAME records

    SUBDOMAIN="$(get_subdomain "$DOMAIN")"

    URL="$(dns_record_url "$DOMAIN" "$TYPE")" || return $?
    JSON_PATH=".domain_record.data"
    DATA='{
        "type": "'$TYPE'",
        "name": "'$SUBDOMAIN'",
        "data": "'$VALUE'",
        "ttl": '$TTL'
    }'
    json_api PUT "$URL" "$JSON_PATH" "${CONFIG[DO_API_KEY]}" "$DATA" || return $?
    return 0
}
