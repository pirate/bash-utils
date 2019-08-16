#!/usr/bin/env bash
# Utils used by cloudflare and digitalocean

### Bash Environment Setup
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# set -o xtrace
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
IFS=$'\n'
trap 'log_quit SIGINT' SIGINT
trap 'log_quit SIGQUIT' SIGQUIT
trap 'log_quit SIGTSTP' SIGTSTP
trap 'log_quit TIMEOUT' SIGALRM
trap 'log_quit ERROR ${FUNCNAME} on line ${LINENO} in $SCRIPTNAME' ERR

 BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"


### General Helpers

# Return the assosciative array declaration without the `declare -A name=` part
function array_contents {
    echo "${1#*=}"
}

# Merge into [DEST_VAR_NAME] the contents from [ARRAY1] [ARRAY2] [ARRAY3] [...]
function merge_arrays {
    declare -g -A "$1"
    local -n DEST_VAR="$1"
    shift

    for ARRAY_NAME in "$@"; do
        local -n ARRAY="$ARRAY_NAME"

        for KEY in "${!ARRAY[@]}"; do
            DEST_VAR["$KEY"]="${ARRAY[$KEY]}"
        done
    done

    # Just to silence shellcheck warnings about unused var
    echo "${DEST_VAR[@]}" > /dev/null
}

# Run a command with a given TIMEOUT in seconds
function timed {
    local TIMEOUT="$1";
    shift;
    local -a CMD=("$@");
    local SPID CPID WPID START_TS END_TS TOOK STATUS

    SPID="$$"
    # Double-nested shell to avoid extra stderr on exit "./bin killed by ..."
    (
        # 1. Start command in background process, save child pid to CPID
        START_TS="$(date +"%s")"
        eval "${CMD[@]}" & CPID=$!
        
        # 2. Start timeout watcher in background process, save pid to WPID
        (       
            sleep "$TIMEOUT" || exit
            warn "Reached ${TIMEOUT}s timeout, aborting and retrying..."
            kill $CPID 2> /dev/null
        ) & WPID=$!

        debug "[timed][1/2] Timer started shell=$SPID watcher=$WPID pid=$CPID timeout=${TIMEOUT}s cmd=${CMD[0]}"
        
        # 3. Wait for either command process to finish, or watcher to fire and kill CPID
        wait $CPID && STATUS=$? || STATUS=$?
        kill $WPID
        
        # 4. Log total time spent and return original exit status of command subprocess
        END_TS="$(date +"%s")"
        TOOK=$((END_TS-START_TS))
        debug "[timed][2/2] Timer finished shell=$SPID watcher=$WPID pid=$CPID exit=${STATUS} took=${TOOK}s cmd=${CMD[0]}"
        return $STATUS
    ) && return $? || return $?
}

# Loop a command with the given TIMEOUT and the given INTERVAL between runs
function repeated {
    local INTERVAL="$1" STATUS
    shift 1
    local -a CMD=("$@")

    while :; do
        eval "${CMD[@]}" && STATUS=$? || STATUS=$?

        ((INTERVAL<1)) && return $STATUS
        sleep "$INTERVAL"
    done
}

function backtrace () {
    local depth=${#FUNCNAME[@]}

    for ((i=2; i<depth; i++)); do
        local func="${FUNCNAME[$i]}"
        local line="${BASH_LINENO[$((i))]}"
        local src="${BASH_SOURCE[$((i))]}"
        printf '%*s' $i '' # indent
        echo "at: $func(), $src, line $line"
    done
}

function trace_top_caller () {
    local func="${FUNCNAME[1]}"
    local line="${BASH_LINENO[0]}"
    local src="${BASH_SOURCE[0]}"
    echo "  called from: $func(), $src, line $line"
}

# Check to make sure the given functions are loaded
function REQUIRES_FUNCS {
    for FUNC in "$@"; do
        if [[ "$(type -t "$FUNC")" != "function" ]]; then
            echo "[X] Missing required function $FUNC (did you import all the required files in the right order?)" >&2
            exit 4
        fi
    done
}

function REQUIRES_CMDS {
    for CMD in "$@"; do
        if ! command -v "$CMD" > /dev/null; then
            echo "[X] Missing required command $CMD (is it installed on this system and available in \$PATH?)" >&2
            exit 4
        fi
    done
}

function REQUIRES_VARS {
    for VAR in "$@"; do
        VALUE=${VAR:-}

        if [[ -z "${VALUE}" ]]; then
            echo "[X] Missing required variable $VAR (did you import all the required files in the right order?)" >&2
            exit 4
        fi
    done
}

function REQUIRES_CONFIG {
    for VAR in "$@"; do
        VALUE=${CONFIG[VAR]:-}

        if [[ -z "${VALUE}" ]]; then
            echo "[X] Missing required config variable $VAR (did you import all the required files in the right order?)" >&2
            exit 4
        fi
    done
}


# function main {
#     local METHOD="$1"; shift; local ARGS=("$@")

#     if [[ "$METHOD" != "import" ]]; then
#         eval "$METHOD ${ARGS[*]}"
#         return "$?"
#     fi
# }

# main "$@"

