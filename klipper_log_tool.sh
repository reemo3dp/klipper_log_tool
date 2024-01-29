#!/bin/env bash

set -eo pipefail

HASTEBIN_URL=${HASTEBIN_URL:-https://paste.armbian.com/documents}

usage() {
    cat >&2 <<EOF
Usage: $0 [ -u | --upload ] [ -y | --yes ] [ -r | --raw ] [ -a | --all-starts ] [KLIPPER_LOG_FILE]
EOF
    exit 1
}

UPLOAD=0
YES=0
RAW=0
ALL_STARTS=0

args=$(getopt -a -o hyura --long help,yes,upload,raw,all-starts -- "$@")
# shellcheck disable=SC2181
if [[ $? -gt 0 ]]; then
    usage
fi
eval set -- "${args}"
while :; do
    case $1 in
    -u | --upload)
        UPLOAD=1
        shift
        ;;
    -y | --yes)
        YES=1
        shift
        ;;
    -raw | --raw)
        RAW=1
        shift
        ;;
    -a | --all-starts)
        ALL_STARTS=1
        shift
        ;;
        # -- means the end of the arguments; drop this, and break out of the while loop
    --)
        shift
        break
        ;;
    *)
        echo >&2 Unsupported option: "$1"
        usage
        ;;
    esac
done

if [[ $# -eq 0 ]]; then
    FILE="$HOME/printer_data/logs/klippy.log"
    if [[ ! -f $FILE ]]; then
        echo >&2 "No file specified and default file $FILE does not exist."
        usage
    fi
else
    FILE="$1"
fi

set -u

remove_noise() {
    grep -vE '^(Stats |Sent |Receive:|Dumping receive queue)'
}

only_last() {
    FILE="$1"
    sed -n 'H; /^Start printer at/h; ${g;p;}' "$FILE"
}

process_klipper_log() {
    FILE="$1"
    if [[ $RAW -eq 1 ]]; then
        cat "$FILE"
        return
    fi
    if [[ $ALL_STARTS -eq 1 ]]; then
        remove_noise <"$FILE"
        return
    fi
    only_last "$FILE" |
        remove_noise
}

OUTPUT=$(process_klipper_log "$FILE")
echo "$OUTPUT"

if [[ $UPLOAD -eq 1 ]]; then
    echo ""
    echo "----------------------------------------"
    echo ""
    if [[ $YES -ne 1 ]]; then
        # shellcheck disable=SC2140
        echo "This data will be uploaded to $HASTEBIN_URL for easier sharing. It will be unprotected and publicly available. Press ENTER to continue, Ctrl+C to abort."
        read -r
    fi
    RESPONSE=$(echo "$OUTPUT" | curl -sfXPOST -T- "$HASTEBIN_URL")
    KEY=$(echo "$RESPONSE" | awk -F '"' '{print $4}')
    echo ""
    echo "Share the following url: ${HASTEBIN_URL%documents}$KEY"
fi

