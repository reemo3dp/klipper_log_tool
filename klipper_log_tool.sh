#!/bin/env bash

set -eo pipefail

HASTEBIN_URL=${HASTEBIN_URL:-https://paste.armbian.com/documents}

remove_noise() {
    grep -vE '^(Stats |Sent |Receive:|Dumping receive queue)'
}

only_last() {
    FILE="$1"
    # shellcheck disable=SC2016
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

usage() {
    cat >&2 <<EOF
Usage: $0 [ -f | --find ] [ -u | --upload ] [ -y | --yes ] [ -r | --raw ] [ -a | --all-starts ] [KLIPPER_LOG_FILE]...
EOF
    exit 1
}

FIND=0
UPLOAD=0
YES=0
RAW=0
ALL_STARTS=0

args=$(getopt -a -o fhyura --long find,help,yes,upload,raw,all-starts -- "$@")
# shellcheck disable=SC2181
if [[ $? -gt 0 ]]; then
    usage
fi
eval set -- "${args}"
while :; do
    case $1 in
    -f | --find)
        FIND=1
        shift
        ;;
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

# shellcheck disable=SC2206
FILES=($@)

# If empty, check if default exists and replace that with FILES
if [[ ${#FILES[@]} -eq 0 ]]; then
    if [[ $FIND -eq 1 ]]; then
        set +e
        FILES=($(find /home -type f -name klippy.log 2>/dev/null))
        set -e
        if [[ ${#FILES[@]} -eq 0 ]]; then
            echo >&2 "No klippy.log files found."
            exit 1
        fi
    else
        FILE="$HOME/printer_data/logs/klippy.log"
        if [[ ! -f $FILE ]]; then
            echo >&2 "No file specified and default file $FILE does not exist."
            usage
        fi
        FILES=("$FILE")
    fi
fi

set -u

# Collect output from processing each file into OUTPUT
TARGET_OUTPUT_FILE=$(mktemp)
touch "$TARGET_OUTPUT_FILE"
trap 'rm "$TARGET_OUTPUT_FILE"' EXIT

for FILE in "${FILES[@]}"; do
    set +e
    echo "Logfile: $FILE
--------------------------------------------" >>"$TARGET_OUTPUT_FILE"
    process_klipper_log "$FILE" >>"$TARGET_OUTPUT_FILE"
    echo "" >>"$TARGET_OUTPUT_FILE"
    set -e
done

cat "$TARGET_OUTPUT_FILE"

if [[ $UPLOAD -eq 1 ]]; then
    echo ""
    echo "----------------------------------------"
    echo ""
    if [[ $YES -ne 1 ]]; then
        # shellcheck disable=SC2140
        echo "This data will be uploaded to $HASTEBIN_URL for easier sharing. It will be unprotected and publicly available. Press ENTER to continue, Ctrl+C to abort."
        read -r
    fi
    RESPONSE=$(cat "$TARGET_OUTPUT_FILE" | curl -sfXPOST -T- "$HASTEBIN_URL")
    KEY=$(echo "$RESPONSE" | awk -F '"' '{print $4}')
    echo ""
    echo "Share the following url: ${HASTEBIN_URL%documents}$KEY"
fi
