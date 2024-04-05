#!/usr/bin/env bash
# CloudFlare Bash API

REQUIRES_FUNCS warn json_api get_rootdomain
# REQUIRES_FUNCS and other global helpers are defined in base.sh:
# https://github.com/pirate/bash-utils/blob/master/util/base.sh#:~:text=REQUIRES_FUNCS

### Global Variables

CF_API_URL="https://api.cloudflare.com/client/v4"
CF_DEFAULT_TTL=1
CF_DEFAULT_PROXIED=false


function dns_record_url {
    local DOMAIN="$1" TYPE="${2:-A}"
    local ROOTDOMAIN URL JSON_PATH ZONE_ID RECORD_ID

    ROOTDOMAIN="$(get_rootdomain "$DOMAIN")"

    URL="$CF_API_URL/zones"
    JSON_PATH=".result[] | select(.name == \"$ROOTDOMAIN\") | .id"
    ZONE_ID="$(json_api GET "$URL" "$JSON_PATH" "${CONFIG[CF_API_KEY]}")" || return $?
    
    URL="$CF_API_URL/zones/$ZONE_ID/dns_records?name=$DOMAIN&type=$TYPE"
    JSON_PATH='.result[0].id'
    RECORD_ID="$(json_api GET "$URL" "$JSON_PATH" "${CONFIG[CF_API_KEY]}")" || return $?

    if [[ -z "$RECORD_ID" || "$RECORD_ID" == "null" || "$RECORD_ID" == "undefined" ]]; then
        debug "API response from CloudFlare indicates no record exists for the given domain."
        echo "null"
        return 8
    fi

    echo "$CF_API_URL/zones/$ZONE_ID/dns_records/$RECORD_ID"
    return 0
}

function dns_get_record {
    local DOMAIN="$1" TYPE="${2:-A}"

    local URL JSON_PATH

    URL="$(dns_record_url "$DOMAIN" "$TYPE")" || return $?
    JSON_PATH='.result.content'
    json_api GET "$URL" "$JSON_PATH" "${CONFIG[CF_API_KEY]}" || return $?
    return 0
}

function dns_create_record {
    local DOMAIN="$1" TYPE="$2" VALUE="$3" TTL="${4:-$CF_DEFAULT_TTL}" PROXIED="${5:-$CF_DEFAULT_PROXIED}"

    local ROOTDOMAIN URL JSON_PATH ZONE_ID DATA

    [[ "$TTL" == "default" ]] && TTL="$CF_DEFAULT_TTL"

    ROOTDOMAIN="$(get_rootdomain "$DOMAIN")"

    URL="$CF_API_URL/zones"
    JSON_PATH=".result[] | select(.name == \"$ROOTDOMAIN\") | .id"
    ZONE_ID="$(json_api GET "$URL" "$JSON_PATH" "${CONFIG[CF_API_KEY]}")" || return $?
    
    URL="$CF_API_URL/zones/$ZONE_ID/dns_records"
    JSON_PATH='.result.content'
    DATA='{
        "type": "'$TYPE'",
        "name": "'$DOMAIN'",
        "content": "'$VALUE'",
        "ttl": '$TTL',
        "proxied": '$PROXIED'
    }'

    json_api POST "$URL" "$JSON_PATH" "${CONFIG[CF_API_KEY]}" "$DATA" || return $?
    return 0
}

function dns_set_record {
    local DOMAIN="$1" TYPE="$2" VALUE="$3" TTL="${4:-$CF_DEFAULT_TTL}" PROXIED="${5:-$CF_DEFAULT_PROXIED}"

    local URL JSON_PATH DATA

    ROOTDOMAIN="$(get_rootdomain "$DOMAIN")"

    [[ "$TTL" == "default" ]] && TTL="$CF_DEFAULT_TTL"                # default ttl is 1
    [[ "$VALUE" == "$ROOTDOMAIN" ]] && VALUE="@"                      # replace root ref with @
    [[ "$TYPE" == "CNAME" && "$VALUE" != "@" ]] && VALUE="${VALUE}."  # append . to CNAME records

    URL="$(dns_record_url "$DOMAIN" "$TYPE")" || return $?
    JSON_PATH='.result.content'
    DATA='{
        "type": "'$TYPE'",
        "name": "'$DOMAIN'",
        "content": "'$VALUE'",
        "ttl": '$TTL',
        "proxied": '$PROXIED'
    }'

    json_api PUT "$URL" "$JSON_PATH" "${CONFIG[CF_API_KEY]}" "$DATA" || return $?
    return 0
}
