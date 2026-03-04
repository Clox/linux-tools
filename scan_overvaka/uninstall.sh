#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="$HOME"
BIN="$HOME_DIR/.local/bin/scan_overvaka"
SERVICE="$HOME_DIR/.config/systemd/user/scan_overvaka.service"

if command -v systemctl >/dev/null 2>&1; then
	systemctl --user disable --now scan_overvaka.service >/dev/null 2>&1 || true
	systemctl --user daemon-reload >/dev/null 2>&1 || true
fi

rm -f "$SERVICE"
rm -f "$BIN"

echo "Uninstalled scan_overvaka"
echo "Note: It does not delete your ~/scan or ~/scan/compressed files."
