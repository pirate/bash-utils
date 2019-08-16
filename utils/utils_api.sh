#!/usr/bin/env bash

REQUIRES_FUNCS debug fatal
REQUIRES_CMDS curl jq

### API Helpers

function json_api {
    local METHOD="$1" URL="$2" JSON_PATH="$3" API_KEY="$4" DATA="${5:-}"

    local CMD OUTPUT ERRORS PARSED_OUTPUT STATUS

    [[ ! "$API_KEY" ]] && fatal "API Key is empty!"

    CMD=(
        "curl"
        "--silent"
        "--request" "$METHOD"
        "--url" "'$URL'"
        "--header" "'Authorization: Bearer $API_KEY'"
        "--header" "'Content-Type: application/json'"
    )
    [[ -n "$DATA" ]] && {
        CMD+=("--data" "'$DATA'")
    }

    IFS=' '
    debug "[json_api][1/3] ${CMD[*]} | jq --raw-output '$JSON_PATH'"
    IFS=$'\n'

    OUTPUT="$(eval "${CMD[@]}")"; STATUS="$?"
    debug "[json_api][2/3] curl (exitstatus=$STATUS) => $OUTPUT"
    ERRORS="$(echo "$OUTPUT" | jq '.errors,.error_message,.message | select (.!=null and .!=[] and .!="")')" 2>/dev/null || true

    if ((STATUS>0)) || [[ "$ERRORS" ]]; then
        fatal "API request to $API failed: ERRORS='$ERRORS'"
    fi

    PARSED_OUTPUT="$(echo "$OUTPUT" | jq --raw-output "$JSON_PATH")"; STATUS="$?"
    debug "[json_api][3/3] jq (exitstatus=$STATUS) => $PARSED_OUTPUT"
    if ((STATUS>0)); then
        fatal "API response from $API could not be parsed. (status=$?)"
    fi

    echo "$PARSED_OUTPUT"
    return 0
}
