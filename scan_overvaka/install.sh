#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"

HOME_DIR="$HOME"
BIN_DIR="$HOME_DIR/.local/bin"
SYSTEMD_DIR="$HOME_DIR/.config/systemd/user"

WATCH_DIR_DEFAULT="$HOME_DIR/scan"
WATCH_DIR="${WATCH_DIR:-$WATCH_DIR_DEFAULT}"

need_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "ERROR: Missing command: $1" >&2
		exit 1
	fi
}

need_cmd install
need_cmd mkdir
need_cmd sed

# Install deps (Mint/Ubuntu/Debian)
if command -v apt-get >/dev/null 2>&1; then
	if command -v sudo >/dev/null 2>&1; then
		echo "Installing dependencies..."
		sudo apt-get update -y
		sudo apt-get install -y \
			inotify-tools \
			ghostscript \
			qpdf \
			ocrmypdf \
			tesseract-ocr \
			tesseract-ocr-swe \
			tesseract-ocr-eng \
			libnotify-bin \
			xdg-utils
	else
		echo "ERROR: sudo not found. Install deps manually." >&2
		exit 1
	fi
else
	echo "ERROR: apt-get not found. This installer currently supports Mint/Ubuntu/Debian." >&2
	exit 1
fi

# Warn about old install
OLD_SCRIPT="$HOME_DIR/monitor_and_compress.sh"
if [ -f "$OLD_SCRIPT" ]; then
	echo "WARNING: Found old script: $OLD_SCRIPT"
	echo "If it was previously started via Startup Applications, make sure that entry is disabled (to avoid double-processing)."
fi

# Install executable
mkdir -p "$BIN_DIR"
install -m 0755 "$ASSETS_DIR/scan_overvaka" "$BIN_DIR/scan_overvaka"

# Install systemd user service
mkdir -p "$SYSTEMD_DIR"
SERVICE_TARGET="$SYSTEMD_DIR/scan_overvaka.service"
sed \
	-e "s|@HOME@|$HOME_DIR|g" \
	-e "s|@WATCH_DIR@|$WATCH_DIR|g" \
	"$ASSETS_DIR/scan_overvaka.service.in" > "$SERVICE_TARGET"

# Create watch dir
mkdir -p "$WATCH_DIR" "$WATCH_DIR/compressed"

# Enable + restart service
need_cmd systemctl
systemctl --user daemon-reload
systemctl --user enable --now scan_overvaka.service
systemctl --user restart scan_overvaka.service

echo "Installed scan_overvaka"
echo "• Watching: $WATCH_DIR"
echo "• Output:   $WATCH_DIR/compressed/"
echo
echo "Status:"
echo "  systemctl --user status scan_overvaka.service"
echo
echo "Live logs:"
echo "  journalctl --user -u scan_overvaka.service -f"
