#!/usr/bin/env bash
# AnoSpot — LocalSend single-file send.
# Usage: localsend_send.sh <file> <target-ip>
#
# Ported from Devvvmn/ActivSpot (experimental branch). Changes from
# upstream:
#   - Alias parameterized via env ANOSPOT_ALIAS (default "AnoSpot").
#   - Fingerprint cache moved from ~/.cache/qs_localsend_fp to
#     ~/.cache/anospot/localsend_fp.
#   - Server response parsing reads JSON from stdin instead of argv to
#     avoid shell-quoting hazards on responses with unusual characters.
#   - Output goes through notify-send; non-zero exit on failure.
#
# Dependencies: bash, openssl, curl, python3, file, stat, notify-send.

set -u

FILE="${1:-}"
TARGET="${2:-}"
ALIAS="${ANOSPOT_ALIAS:-AnoSpot}"

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    notify-send "LocalSend" "File not found" -i dialog-error
    exit 1
fi
if [ -z "$TARGET" ]; then
    notify-send "LocalSend" "No target device specified" -i dialog-error
    exit 1
fi

PORT=53317
FILENAME=$(basename "$FILE")
FILESIZE=$(stat -c%s -- "$FILE")
FILETYPE=$(file -b --mime-type -- "$FILE")
FILE_ID="anospot_$(date +%s%N | md5sum | head -c8)"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/anospot"
mkdir -p "$CACHE_DIR"
FP_FILE="$CACHE_DIR/localsend_fp"
[ -f "$FP_FILE" ] || openssl rand -hex 16 > "$FP_FILE"
FINGERPRINT=$(cat "$FP_FILE")

BODY=$(ALIAS="$ALIAS" PORT="$PORT" FINGERPRINT="$FINGERPRINT" \
       FILE_ID="$FILE_ID" FILENAME="$FILENAME" FILESIZE="$FILESIZE" FILETYPE="$FILETYPE" \
       python3 -c '
import os, json, sys
print(json.dumps({
    "info": {
        "alias": os.environ["ALIAS"],
        "version": "2.1",
        "deviceModel": None,
        "deviceType": "headless",
        "fingerprint": os.environ["FINGERPRINT"],
        "port": int(os.environ["PORT"]),
        "protocol": "https",
        "download": False
    },
    "files": {
        os.environ["FILE_ID"]: {
            "id": os.environ["FILE_ID"],
            "fileName": os.environ["FILENAME"],
            "size": int(os.environ["FILESIZE"]),
            "fileType": os.environ["FILETYPE"],
            "sha256": None,
            "preview": None,
            "metadata": None
        }
    }
}))
')

RESP=$(curl -sk --max-time 30 \
    -X POST "https://$TARGET:$PORT/api/localsend/v2/prepare-upload" \
    -H "Content-Type: application/json" \
    -d "$BODY")

# Read JSON from stdin (no argv quoting). FILE_ID is a token name, not a value.
read -r SESSION TOKEN < <(printf '%s' "$RESP" | FILE_ID="$FILE_ID" python3 -c '
import os, sys, json
try:
    d = json.loads(sys.stdin.read() or "{}")
except Exception:
    print("", "")
    sys.exit(0)
sid = d.get("sessionId", "")
tok = d.get("files", {}).get(os.environ["FILE_ID"], "")
print(sid, tok)
')

if [ -z "$SESSION" ] || [ -z "$TOKEN" ]; then
    notify-send "LocalSend" "Rejected or timed out" -i dialog-error
    exit 1
fi

if curl -sk --max-time 600 \
    -X POST "https://$TARGET:$PORT/api/localsend/v2/upload?sessionId=$SESSION&fileId=$FILE_ID&token=$TOKEN" \
    -H "Content-Type: $FILETYPE" \
    --data-binary @"$FILE" >/dev/null
then
    notify-send "LocalSend" "Sent: $FILENAME" -i emblem-ok-symbolic
else
    notify-send "LocalSend" "Upload failed" -i dialog-error
    exit 1
fi
