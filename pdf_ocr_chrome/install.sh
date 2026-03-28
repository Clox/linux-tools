#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"

HOME_DIR="${HOME}"
BIN_DIR="$HOME_DIR/.local/bin"
APP_DIR="$HOME_DIR/.local/share/applications"
CACHE_DIR="$HOME_DIR/.cache/ocrpdf"

mkdir -p "$BIN_DIR" "$APP_DIR" "$CACHE_DIR"

need_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "ERROR: Missing command: $1" >&2
		exit 1
	fi
}

resolve_src_file() {
	local rel="$1"
	if [ -f "$SCRIPT_DIR/$rel" ]; then
		echo "$SCRIPT_DIR/$rel"
		return 0
	fi
	if [ -f "$ASSETS_DIR/$rel" ]; then
		echo "$ASSETS_DIR/$rel"
		return 0
	fi
	echo "ERROR: Could not find required file: $rel (looked in $SCRIPT_DIR and $ASSETS_DIR)" >&2
	exit 1
}

# Preconditions
need_cmd sed
need_cmd install
need_cmd mkdir

# 1) Install system dependencies (Mint/Ubuntu/Debian)
if command -v apt-get >/dev/null 2>&1; then
	if command -v sudo >/dev/null 2>&1; then
		echo "Installing dependencies with apt..."
		sudo apt-get update -y
		sudo apt-get install -y \
			ocrmypdf \
			tesseract-ocr \
			tesseract-ocr-swe \
			tesseract-ocr-eng \
			ghostscript \
			qpdf \
			poppler-utils \
			xdg-utils \
			coreutils
	else
		echo "ERROR: sudo not found. Install dependencies manually:" >&2
		echo "sudo apt-get update -y" >&2
		echo "sudo apt-get install -y ocrmypdf tesseract-ocr tesseract-ocr-swe tesseract-ocr-eng ghostscript qpdf poppler-utils xdg-utils coreutils" >&2
		exit 1
	fi
else
	echo "ERROR: apt-get not found. This installer currently supports Mint/Ubuntu/Debian." >&2
	echo "Install manually: ocrmypdf + tesseract (swe+eng) + ghostscript + qpdf + poppler-utils + xdg-utils" >&2
	exit 1
fi

# 2) Verify key commands exist now
need_cmd ocrmypdf
need_cmd xdg-mime
need_cmd sha1sum
need_cmd stat

# 3) Install executable
SCRIPT_SRC="$(resolve_src_file ocr_chrome)"
DESKTOP_SRC="$(resolve_src_file pdf-ocr-chrome.desktop.in)"
install -m 0755 "$SCRIPT_SRC" "$BIN_DIR/ocr_chrome"

# 4) Install desktop entry (replace @HOME@)
DESKTOP_TARGET="$APP_DIR/pdf-ocr-chrome.desktop"
sed "s|@HOME@|$HOME_DIR|g" "$DESKTOP_SRC" > "$DESKTOP_TARGET"

# 5) Update desktop database if available (optional)
if command -v update-desktop-database >/dev/null 2>&1; then
	update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi

# 6) Set as default handler for PDFs
xdg-mime default pdf-ocr-chrome.desktop application/pdf

echo "Installed PDF OCR -> Chrome"
echo "• Binary: $BIN_DIR/ocr_chrome"
echo "• Desktop: $DESKTOP_TARGET"
echo "• Default handler set for: application/pdf"
echo "• Cache: $CACHE_DIR"
echo
echo "Tip: Test it with:"
echo "  $BIN_DIR/ocr_chrome /path/to/file.pdf"
