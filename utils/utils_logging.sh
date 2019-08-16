#!/usr/bin/env/bash

REQUIRES_CMDS sed
REQUIRES_FUNCS trace_top_caller


### Global Variables

RESET='\033[0m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
GRAY='\033[2;37m'


### Logging Helpers

function log_start {
    local -n CONFIG_VAR="$1"
    local RUN_STR="${SCRIPTNAME} with config:"

    for KEY in "${!CONFIG_VAR[@]}"; do
        RUN_STR="${RUN_STR}\n$KEY=${CONFIG_VAR[$KEY]} "
    done

    debug "Running $RUN_STR"
}

function log_quit {
    local SIGNAL="$1" SOURCE="${2:-$SCRIPTNAME}"
    wait
    fatal "Stopped. ($SIGNAL in $SOURCE)"
    exit "$SIGNAL"
}

function log {
    local LEVEL="$1"; shift
    local STRING="$*"

    set +o nounset
    local TIMESTAMPS="${CONFIG[TIMESTAMPS]:-1}"
    local LOGLEVELS="${CONFIG[LOGLEVELS]:-1}"
    local COLOR="${CONFIG[COLOR]:-1}"
    set -o nounset

    case "$LEVEL" in
        DEBUG)   ANSI="$GRAY";;
        INFO)    ANSI="$CYAN";;
        WARN)    ANSI="$YELLOW";;
        ERROR)   ANSI="$RED";;
        FATAL)   ANSI="$RED";;
        *)       ANSI="";;
    esac

    # replace newlines and repeated whitespace with a single space
    STRING="$(echo -e "$STRING" | sed -e "s/[[:space:]]\+/ /g")"
    if [[ "$TIMESTAMPS" == "1" ]]; then
        TS="[$(date +"%Y-%m-%d %H:%M")] "
    else
        TS=""
    fi
    if [[ "$LOGLEVELS" == "1" ]]; then
        LEVEL="$(printf '%-7s' "[${LEVEL}] ")"
    else
        LEVEL=""
    fi

    # if COLOR=0 or stderr is not a tty, turn off log coloring
    if [[ "$COLOR" == "1" && -t 2 ]]; then
        echo -e "${GRAY}${TS}${ANSI}${LEVEL}$RESET${STRING}" >&2
    else
        echo -e "${TS}${LEVEL}${STRING}" >&2
    fi
}

function debug {
    set +o nounset
    local VERBOSE="${CONFIG[VERBOSE]:-1}"
    set -o nounset

    [[ ! "$VERBOSE" == "1" ]] && return 0
    log DEBUG "$*"
    # set -o xtrace
}
function info {
    set +o nounset
    local QUIET="${CONFIG[QUIET]:-0}"
    set -o nounset

    [[ "$QUIET" == "1" ]] && return 0
    log INFO "$*"
}
function warn {
    log WARN "$*"
}
function error {
    log ERROR "$*"
}
function fatal {
    log FATAL "$*\n$(backtrace)"
    # debug "TRACEBACK:\n "
    exit 3
}
