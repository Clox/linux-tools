#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"

need_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "ERROR: Missing command: $1" >&2
		exit 1
	fi
}

need_cmd install
need_cmd mkdir

if ! command -v sudo >/dev/null 2>&1; then
	echo "ERROR: sudo not found. This tool must write Chrome policy under /etc." >&2
	exit 1
fi

# Policy path for Google Chrome on Linux
POLICY_DIR="/etc/opt/chrome/policies/managed"
TARGET="$POLICY_DIR/print_as_image.json"

sudo mkdir -p "$POLICY_DIR"
sudo install -m 0644 "$ASSETS_DIR/print_as_image.json" "$TARGET"

echo "Installed Chrome policy: PrintPdfAsImageDefault=true"
echo "• File: $TARGET"
echo
echo "Next:"
echo "• Restart Chrome completely"
echo "• Verify at: chrome://policy"
