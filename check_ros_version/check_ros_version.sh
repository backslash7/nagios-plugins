#!/usr/bin/env bash

trap cleanup SIGINT SIGTERM

usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [options]

Checks the RouterOS version running on the device.

Options:
  -h, --help                            Print this help and exit.
  -d, --debug                           Print debugging information.
  -H HOST, --host HOST                  IP address or hostname of the device
  -c COMMUNITY, --community COMMUNITY   SNMPv2 read community.
  -l VERSION, --latest VERSION          Latest RouterOS version.

EOF
    exit
}

msg() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-3} # default exit status 3
    msg "$msg"
    exit "$code"
}

cleanup() {
    die "UNKNOWN: Unknwon script state. Rerun with -d to see what happened" 3
}

check_for() {
    command -v "$1" >/dev/null 2>&1 || {
        die "Error: \`$1\` not found. Please, install suitable package."
    }
}

parse_params() {
    while :; do
        case "${1-}" in
        -h | --help) usage ;;
        -d | --debug) set -x ;;
        -H | --host)
            HOST="${2-}"
            shift
            ;;
        -c | --community)
            COMMUNITY="${2-}"
            shift
            ;;
        -l | --latest)
            LATEST_VERSION="${2-}"
            shift
            ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    [[ -z "${HOST-}" ]] && die "Error: Hostname is required"
    [[ -z "${COMMUNITY-}" ]] && die "Error: SNMPv2 community is required"
    [[ -z "${LATEST_VERSION-}" ]] && die "Error: Latest RouterOS version is required"

    return 0
}

# Credits to https://stackoverflow.com/a/4025065
vercomp() {
    if [[ "$1" == "$2" ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i = ${#ver1[@]}; i < ${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i = 0; i < ${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 0
}

parse_params "$@"
check_for "snmpget"

RETURNED_VERSION=$(snmpget -v2c -t 1 -r 0 -c "${COMMUNITY}" "${HOST}" -Oqv iso.3.6.1.4.1.14988.1.1.4.4.0 2>/dev/null)
if [[ $? != 0 ]]; then
    die "UNKNOWN: Host unreachable or misconfigured" 3
else
    RUNNING_VERSION=${RETURNED_VERSION//\"/}
    vercomp "${RUNNING_VERSION}" "${LATEST_VERSION}"
    case "$?" in
    "0")
        die "OK: Running latest version ${LATEST_VERSION}" 0
        ;;
    "1")
        die "WARNING: Running version ${RUNNING_VERSION}, newer than latest ${LATEST_VERSION}" 1
        ;;
    "2")
        die "CRITICAL: Running version ${RUNNING_VERSION}, older than latest ${LATEST_VERSION}" 2
        ;;
    esac

fi

die "UNKNOWN: Unknown script state" 3
