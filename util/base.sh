#!/usr/bin/env bash
# Basic utils and setup used by all the other scripts

### Bash Environment Setup
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# set -o xtrace                 # print every command before executing (for debugging)
set -o nounset                  # make using undefined variables throw an error
set -o errexit                  # exit immediately if any command returns non-0
set -o pipefail                 # exit from pipe if any command within fails
set -o errtrace                 # subshells should inherit error handlers/traps
shopt -s dotglob                # make * globs also match .hidden files
shopt -s inherit_errexit        # make subshells inherit errexit behavior
IFS=$'\n'                       # set array separator to newline to avoid word splitting bugs
trap 'log_quit SIGINT' SIGINT
trap 'log_quit SIGPIPE' SIGPIPE
trap 'log_quit SIGQUIT' SIGQUIT
trap 'log_quit SIGTSTP' SIGTSTP
trap 'log_quit TIMEOUT' SIGALRM
# trap 'log_quit SIGABRT' SIGABRT
trap 'log_quit $? "${BASH_SOURCE//$PWD/.}:${LINENO} ${FUNCNAME:-}($(IFS=" "; echo "$*"))"' ERR

SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
ROOT_PID=$$
PARENT_PID=$PPID

# get input/output redirection state
[[ ! -t 0 ]]; IS_STDIN_TTY="${?}"
[[ ! -t 1 ]]; IS_STDOUT_TTY="${?}"
[[ ! -t 2 ]]; IS_STDERR_TTY="${?}"
[[ ! "$IS_STDIN_TTY$IS_STDOUT_TTY$IS_STDERR_TTY" == "111" ]]; IS_TTY="${?}"

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
            sleep "$TIMEOUT" || exit 0
            warn "Reached ${TIMEOUT}s timeout, aborting and retrying..."
            kill $CPID 2> /dev/null || true
        ) & WPID=$!

        debug "[timed][1/2] Timer started shell=$SPID watcher=$WPID pid=$CPID timeout=${TIMEOUT}s cmd=${CMD[0]}"
        
        # 3. Wait for either command process to finish, or watcher to fire and kill CPID
        wait $CPID && STATUS=$? || STATUS=$?
        kill -PIPE $WPID 2>/dev/null || true
        
        # 4. Log total time spent and return original exit status of command subprocess
        END_TS="$(date +"%s")"
        TOOK=$((END_TS-START_TS))
        debug "[timed][2/2] Timer finished shell=$SPID watcher=$WPID pid=$CPID exit=${STATUS} took=${TOOK}s cmd=${CMD[0]}"
        return $STATUS
    ) &
    wait "$!" && STATUS=$? || STATUS=$?
    return $STATUS
}

# Loop a command with the given TIMEOUT and the given INTERVAL between runs
function repeated {
    local INTERVAL="$1" STATUS
    shift 1
    local -a CMD=("$@")

    while :; do
        eval "${CMD[@]}" &
        wait "$!" && STATUS=$? || STATUS=$?

        if ((INTERVAL<1)); then
            return $STATUS
        else
            sleep "$INTERVAL"
        fi
    done
}

function try {
    local -a CMD
    local -a PROPAGATE
    local -a SILENCE

    while (( "$#" )); do
        case "$1" in
            --propagate|--propagate=*)
                if [[ "$1" == *'='* ]]; then
                    PROPAGATE+=("${1#*=}")
                else
                    shift
                    PROPAGATE+=("$1")
                fi
                shift
            ;;
            --ignore|--ignore=*)
                if [[ "$1" == *'='* ]]; then
                    IGNORE+=("${1#*=}")
                else
                    shift
                    IGNORE+=("$1")
                fi
                shift
            ;;
            *)
                CMD+=("$1")
                shift
            ;;
        esac
    done

    eval "${CMD[@]}" & wait "$!" && return 0 || STATUS=$?


    if printf '%s\n' ${SILENCE[@]} | grep -q -E "^$STATUS\$"; then
        return 0
    fi

    if printf '%s\n' ${PROPAGATE[@]} | grep -q -E "^$STATUS\$"; then
        return "$STATUS"
    fi

    fatal --status=$STATUS "Got unexpected exit status $STATUS: ${CMD[@]}"
}

function backtrace {
    local depth=${1:-#FUNCNAME[@]}

    for ((i=2; i<depth; i++)); do
        local func="${FUNCNAME[$i]}"
        local line="${BASH_LINENO[$((i))]}"
        local src="${BASH_SOURCE[$((i))]}"
        printf '%*s' $i '' # indent
        echo "at: $func(), $src, line $line"
    done
}

function trace_top_caller {
    local func="${FUNCNAME[1]}"
    local line="${BASH_LINENO[0]}"
    local src="${BASH_SOURCE[0]}"
    echo "  called from: $func(), $src, line $line"
}

# Check to make sure the given functions are loaded
function IMPORT {
    local -a IMPORTS=("$@")
    local FUNC
    local PATH


    for PATH in ${IMPORTS[*]}; do
        IFS='.'
        for step in $PATH; do
            if [[ -d "$step" ]]; then
                cd "$step"
            elif [[ -f "$step" ]]; then
                source "$step"
                break
            fi
        done
        FUNC="${PATH[-1]}"
        IFS=$'\n'

        if [[ "$(type -t "$FUNC")" != "function" ]]; then
            echo "[X] Missing required function $FUNC (is the import path $PATH correct?)" >&2
            exit 4
        fi
    done
}

function REQUIRES_FUNCS {
    for FUNC in "$@"; do
        if [[ "$(type -t "$FUNC")" != "function" ]]; then
            echo "[X] Missing required function $FUNC (is the import path $PATH correct?)" >&2
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

