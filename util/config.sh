#!/usr/bin/env bash


# shellcheck disable=SC2034
declare -A BASE_CLI_ARGS=(
    # Flag Arguments
    [QUIET]='-q|--quiet'
    [VERBOSE]='-v|--verbose'
    [COLOR]='--color'
    [TIMESTAMPS]='--timestamps'
    [LOGLEVELS]='--loglevels'

    # Named Arguments
    [CONFIG_FILE]='-c|--config|-c=*|--config=*'
    [CONFIG_PREFIX]='-e|--config-prefix|-e=*|--config-prefix=*'
    [INTERVAL]='-r|-r=*|--interval|--interval=*'
    [TIMEOUT]='-w|-w=*|--timeout|--timeout=*'

    # Positional Arguments
    # [EXAMPLE]='*'
)

# shellcheck disable=SC2034
declare -A BASE_CONFIG_DEFAULTS=(
    [INTERVAL]=0
    [TIMEOUT]=15
    [VERBOSE]=0
    [QUIET]=0
    [COLOR]=1
    [TIMESTAMPS]=1
    [LOGLEVELS]=1

)
# shellcheck disable=SC2016,SC2034
declare -A BASE_CONFIG_VALIDATORS=(
    [INTERVAL]='[[ "${CONFIG[INTERVAL]}" ]] && ((CONFIG[INTERVAL]>-1))'
    [TIMEOUT]='[[ "${CONFIG[TIMEOUT]}" ]] && ((CONFIG[TIMEOUT]>-2))'
)

declare -A CONFIG_FROM_FILE
declare -A CONFIG_FROM_ENV
declare -A CONFIG_FROM_ARGS


### Config Loading Helpers

# load config vars from defaults
function config_load_defaults {
    local CONFIG_SCHEMA_NAME="$1";

    merge_arrays CONFIG "$CONFIG_SCHEMA_NAME"
}

# load config vars from cli named args, flag args, and positional args
function config_load_args {
    local CONFIG_SCHEMA_NAME="$1"
    local CLI_SCHEMA_NAME="$2"
    shift 2

    local ARG_ARRAY_STR

    while (( "$#" )); do
        case "$1" in
            -h|--help|help) echo "$HELP_TEXT"; exit 0;;
            --version|version) echo "$VERSION"; exit 0;;
            *)
                ARG_ARRAY_STR="$(config_parse_arg "$CONFIG_SCHEMA_NAME" "$CLI_SCHEMA_NAME" "$@")" && SHIFT=$? || SHIFT=$?
                unset ARG_CONFIG
                local -A ARG_CONFIG="$ARG_ARRAY_STR"

                if ((SHIFT>0)); then
                    shift "$SHIFT"
                    merge_arrays CONFIG_FROM_ARGS ARG_CONFIG
                else
                    fatal "Got unrecognized argument '$1'"
                fi
                ;;
        esac
    done

    merge_arrays CONFIG CONFIG_FROM_ARGS
}

# load config vars from environment into assosciative array
function config_load_env {
    local -n CONFIG_SCHEMA="$1"

    set +o nounset
    local CONFIG_PREFIX="${CONFIG[CONFIG_PREFIX]}"
    set -o nounset


    # Load config from environment
    for KEY in "${!CONFIG_SCHEMA[@]}"; do
        ENV_VALUE="$(eval echo "\${$KEY-}")"
        [[ "$ENV_VALUE" ]] && CONFIG_FROM_ENV["$KEY"]="$ENV_VALUE"
        
        if [[ "$CONFIG_PREFIX" ]]; then
            ENV_KEY="${CONFIG_PREFIX}_$KEY"
            ENV_VALUE="$(eval echo "\${$ENV_KEY-}")"
            [[ "$ENV_VALUE" ]] && CONFIG_FROM_ENV["$KEY"]="$ENV_VALUE"
        fi
    done

    merge_arrays CONFIG CONFIG_FROM_ENV
}

# load config vars from config file into assosciative array
function config_load_file {
    local -n CONFIG_SCHEMA="$1"

    set +o nounset
    local CONFIG_FILE="${CONFIG[CONFIG_FILE]}"
    local CONFIG_PREFIX="${CONFIG[CONFIG_PREFIX]}"
    set -o nounset

    # If config file is not defined, return empty
    if [[ ! "$CONFIG_FILE" ]]; then
        return 0
    fi

    # If config file is not a valid file, raise error
    if [[ ! -f "$CONFIG_FILE" ]]; then
        fatal "No config file found at $CONFIG_FILE."
    fi

    local ENV_FILE_CONTENT="$(cat "$CONFIG_FILE")" || {
        fatal "Unable to read config file $CONFIG_FILE"
    }

    # Load config from sourced file in subshell environment
    for KEY in "${!CONFIG_SCHEMA[@]}"; do
        FILE_VALUE="$(eval "$ENV_FILE_CONTENT; echo \${$KEY-}")"
        if [[ "$FILE_VALUE" ]]; then
            CONFIG_FROM_FILE["$KEY"]="$FILE_VALUE"
        fi
        unset FILE_VALUE
        
        if [[ "$CONFIG_PREFIX" ]]; then
            PREFIXED_KEY="${CONFIG_PREFIX}_$KEY"
            FILE_VALUE="$(eval "$ENV_FILE_CONTENT; echo \${$PREFIXED_KEY-}")"
            if [[ "$FILE_VALUE" ]]; then
                CONFIG_FROM_FILE["$KEY"]="$FILE_VALUE"
            fi
        fi
    done

    merge_arrays CONFIG CONFIG_FROM_FILE

}

function config_load_all {
    local CONFIG_SCHEMA_NAME="$1"
    local CLI_SCHEMA_NAME="$2"
    shift 2
    local -a CLI_ARGS_VALUES=("$@")

    # Bootstrap CONFIG_FILE and CONFIG_PREFIX from args and env
    config_load_defaults "$CONFIG_SCHEMA_NAME" || return $?
    config_load_args "$CONFIG_SCHEMA_NAME" "$CLI_SCHEMA_NAME" "${CLI_ARGS_VALUES[@]}" || return $?
    config_load_env "$CONFIG_SCHEMA_NAME" || return $?

    # Load config in correct precedence order
    config_load_file "$CONFIG_SCHEMA_NAME" || return $?
    config_load_env "$CONFIG_SCHEMA_NAME" || return $?
    config_load_args "$CONFIG_SCHEMA_NAME" "$CLI_SCHEMA_NAME" "${CLI_ARGS_VALUES[@]}" || return $?

    config_print CONFIG_FROM_FILE "CONFIG FILE"
    config_print CONFIG_FROM_ENV "ENVIRONMENT VARIABLES"
    config_print CONFIG_FROM_ARGS "CLI ARGUMENTS"
}


function config_validate {
    local -n CONFIG_VALIDATORS_VAR="$1"

    local KEY VALIDATOR_FUNC

    for KEY in "${!CONFIG_VALIDATORS_VAR[@]}"; do
        VALIDATOR_FUNC="${CONFIG_VALIDATORS_VAR[$KEY]}"
        VAL="${CONFIG[$KEY]}"

        [[ ! "$VALIDATOR_FUNC" ]] && continue

        if ! eval "$VALIDATOR_FUNC"; then
            fatal "Invalid config $KEY=\"$VAL\" (pass --help for usage and examples)"
        fi
    done
    return 0
}

function config_assert {
    local -a KEYS=("$@")
    local KEY

    for KEY in "${KEYS[@]}"; do
        set +o nounset
        CONFIG_VAL="${CONFIG[$KEY]}"
        set -o nounset
        if [[ ! "$CONFIG_VAL" ]]; then
            fatal "Missing config value $KEY (pass --help for usage and examples)."
        fi
    done
    return 0
}

function config_print {
    local -n CONFIG_VAR="$1"
    local SOURCE="$2"

    local RUN_STR="Loaded config from $SOURCE:"

    for KEY in "${!CONFIG_VAR[@]}"; do
        RUN_STR="${RUN_STR}\n$KEY=${CONFIG_VAR[$KEY]} "
    done

    debug "$RUN_STR"
}



### Argument Parsing Helpers

function pattern_matches_arg {
    local PATTERN="$1" ARG="$2"
    eval "case '$ARG' in
        $PATTERN) return 0;;
        *)      return 1;;
    esac"
}

function config_parse_arg {
    local CONFIG_SCHEMA_NAME="$1"
    local -n CLI_ARGS_VAR="$2"
    shift 2

    local KEY PATTERN

    local -A ARG_CONFIG


    for KEY in "${!CLI_ARGS_VAR[@]}"; do
        PATTERN="${CLI_ARGS_VAR[$KEY]}"

        if pattern_matches_arg "$PATTERN" "$1"; then
            if [[ "$PATTERN" = *"=*"* ]]; then
                if [[ "$1" == *'='* ]]; then
                    ARG_CONFIG["$KEY"]="${1#*=}"
                    array_contents "$(declare -p ARG_CONFIG)"
                    return 1
                else
                    ARG_CONFIG["$KEY"]="$2"
                    array_contents "$(declare -p ARG_CONFIG)"
                    return 2
                fi

            # Flag argument
            else
                ARG_CONFIG["$KEY"]=1
                array_contents "$(declare -p ARG_CONFIG)"
                return 1
            fi
        fi
    done
    # # Positional argument
    # for KEY in "${CLI_POSITIONAL_ARGS[@]}"; do
    #     if [[ ! "${TARGET_CONFIG_VAR[$KEY]}" ]]; then
    #         TARGET_CONFIG_VAR[DOMAIN]="$1"
    #         return 1
    #     fi
    # done
    return 0
}
