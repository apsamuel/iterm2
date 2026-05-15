#!/usr/bin/env bash
set -euo pipefail

# dump-preferences.sh — Export iTerm2 preferences to a sorted JSON file
# Usage: dump-preferences.sh [-o <output-path>]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEFAULT_OUTPUT="${REPO_DIR}/config/preferences.json"
DOMAIN="com.googlecode.iterm2"

usage() {
    cat <<EOF
Usage: $(basename "$0") [-o <output-path>] [-h]

Export iTerm2 preferences (defaults domain: ${DOMAIN}) to a JSON file.

Options:
  -o <path>   Output file path (default: ${DEFAULT_OUTPUT})
  -h          Show this help message

The script uses 'defaults export' to extract the full preference plist,
converts it to JSON via 'plutil', and pretty-prints with sorted keys
for diff-friendly output.
EOF
}

output="${DEFAULT_OUTPUT}"

while getopts ":o:h" opt; do
    case "${opt}" in
        o) output="${OPTARG}" ;;
        h) usage; exit 0 ;;
        :) echo "Error: -${OPTARG} requires an argument" >&2; exit 1 ;;
        *) echo "Error: unknown option -${OPTARG}" >&2; usage >&2; exit 1 ;;
    esac
done

# --- Preflight checks ---

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Error: this script requires macOS (Darwin)" >&2
    exit 1
fi

if ! command -v defaults &>/dev/null; then
    echo "Error: 'defaults' command not found" >&2
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo "Error: 'python3' not found (needed for plist→JSON conversion)" >&2
    exit 1
fi

# Verify the domain exists in the defaults system
if ! defaults read "${DOMAIN}" &>/dev/null 2>&1; then
    echo "Error: defaults domain '${DOMAIN}' not found." >&2
    echo "Is iTerm2 installed and has it been launched at least once?" >&2
    exit 1
fi

# --- Ensure output directory exists ---

output_dir="$(dirname "${output}")"
if [[ ! -d "${output_dir}" ]]; then
    mkdir -p "${output_dir}"
fi

# --- Export preferences ---

# Pipeline:
#   1. defaults export → XML plist to stdout
#   2. python3 plistlib → parse plist, convert to JSON (handles binary data/dates)
#
# Note: plutil -convert json cannot handle <data> (binary) elements in plists,
# so we use Python's plistlib which base64-encodes binary blobs and formats
# datetime objects as ISO 8601 strings.
tmp_file="$(mktemp)"
trap 'rm -f "${tmp_file}"' EXIT

defaults export "${DOMAIN}" - \
    | python3 -c '
import sys, json, plistlib, base64
from datetime import datetime

def serialize(obj):
    """Custom serializer for plist types that are not JSON-native."""
    if isinstance(obj, bytes):
        return base64.b64encode(obj).decode("ascii")
    if isinstance(obj, datetime):
        return obj.isoformat() + "Z"
    raise TypeError(f"Object of type {type(obj).__name__} is not JSON serializable")

raw = sys.stdin.buffer.read()
data = plistlib.loads(raw)
json.dump(data, sys.stdout, indent=2, sort_keys=True, default=serialize, ensure_ascii=False)
sys.stdout.write("\n")
' > "${tmp_file}"

# Atomic write: move temp file to final destination
mv -f "${tmp_file}" "${output}"

# --- Summary ---

file_size=$(stat -f '%z' "${output}" 2>/dev/null || stat --printf='%s' "${output}" 2>/dev/null || echo "unknown")
timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

echo "iTerm2 preferences exported successfully."
echo "  Output: ${output}"
echo "  Size:   ${file_size} bytes"
echo "  Time:   ${timestamp}"
echo "  Domain: ${DOMAIN}"
