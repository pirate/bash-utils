#!/usr/bin/env bash


REQUIRES_FUNCS debug error
REQUIRES_CMDS dig curl grep sed


### Global Variables

IPV4_BLOCK='(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'
IPV4_REGEX="$IPV4_BLOCK\.$IPV4_BLOCK\.$IPV4_BLOCK\.$IPV4_BLOCK"

NS1='1.1.1.1'
NS2='8.8.8.8'
NS3='208.67.222.222'


### DNS Helpers

function get_rootdomain {                   # www.sub.example.dev -> example.dev
    local DOMAIN="$1"

    echo "$DOMAIN" | rev | cut -d "." -f1-2 | rev
}
function get_subdomain {                    # www.sub.example.dev -> www.sub
    local DOMAIN="$1"
    local root=
    echo "$DOMAIN" | sed "s/\.$(get_rootdomain "$DOMAIN")//g"
}

function dns_lookup {                       # abc.example.com -> 123.123.123.123
    local DOMAIN="$1" TYPE="${2:-A}" NS="${3:-}"

    local OUTPUT STATUS PARSED_OUTPUT

    debug "[dns_lookup][1/3] dig $DOMAIN $TYPE @$NS | grep -Eo '\$IPV4_REGEX'"
    if [[ -n "$NS" ]]; then
        # Resolve domain to IP using NS
        OUTPUT="$(dig -4 +short +tries=5 +time=5 "$DOMAIN" "$TYPE" "@$NS" 2>&1)"
        STATUS="$?"
    else
        for NS in "$NS1" "$NS2" "$NS3"; do
            OUTPUT="$(dig -4 +short +tries=2 +time=3 "$DOMAIN" "$TYPE" "@$NS" 2>&1)" && break
            STATUS="$?"
        done
    fi
    debug "[dns_lookup][2/3] dig (exitstatus=$STATUS) => $OUTPUT"
    if ((STATUS>0)); then
        error "Resolving $DOMAIN $TYPE @$NS failed. (Is the internet down?)"
        return 1
    fi
    
    PARSED_OUTPUT="$(echo "$OUTPUT" | grep -Eo "$IPV4_REGEX" | head -1)"; STATUS="$?"
    debug "[dns_lookup][3/3] grep (exitstatus=$STATUS) => $PARSED_OUTPUT"
    if ((STATUS>0)); then
        error "Parsing $DOMAIN $TYPE @$NS failed. (got '$OUTPUT')"
        return 1
    fi
    
    echo "$PARSED_OUTPUT"
    return 0
}

function openhttp_get_public_ip {
    curl --fail --silent "https://diagnostic.opendns.com/myip" | grep -Eo "$IPV4_REGEX" \
    || return 1
}
function ifconfig_get_public_ip {
    curl --fail --silent 'https://ifconfig.me' | grep -Eo "$IPV4_REGEX" \
    || return 1
}
function akamai_get_public_ip {
    curl --fail --silent "http://whatismyip.akamai.com/" | grep -Eo "$IPV4_REGEX" \
    || return 1
}
function iptyknu_get_public_ip {
    curl --fail --silent 'http://ip.tyk.nu/' | grep -Eo "$IPV4_REGEX" \
    || return 1
}
function opendns_get_public_ip {
    dns_lookup "myip.opendns.com" "A" "resolver1.opendns.com" \
    || return 1
}
function google_get_public_ip {
    dns_lookup "o-o.myaddr.l.google.com" "TXT" "ns1.google.com" \
    || return 1
}
function dnscrypt_get_public_ip {
    dns_lookup "resolver.dnscrypt.info" "TXT" "$NS1" \
    || return 1
}

function get_public_ip {
    # Favor HTTPS public-ip providers, then HTTP providers, then pure-DNS last
    openhttp_get_public_ip || \
    ifconfig_get_public_ip || \
    akamai_get_public_ip || \
    iptyknu_get_public_ip || \
    dnscrypt_get_public_ip || \
    opendns_get_public_ip || \
    google_get_public_ip || \
    {
        error "Unable to get public IP from any source!"
        return 1
    }
}
