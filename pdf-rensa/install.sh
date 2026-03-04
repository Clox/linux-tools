#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin/pdf-rensa"
SERVICE_DIR="$HOME/.config/systemd/user"

echo "Ange sökväg till mapp som ska övervakas:"
read -r WATCH_DIR

if [ -z "$WATCH_DIR" ] || [ ! -d "$WATCH_DIR" ]; then
	echo "Ogiltig mapp."
	exit 1
fi

# Skapa stabilt ID baserat på sökvägen
ID=$(echo "$WATCH_DIR" | sha1sum | cut -c1-8)
SERVICE_NAME="pdf-rensa-$ID.service"
SERVICE_FILE="$SERVICE_DIR/$SERVICE_NAME"

echo
echo "Skapar övervakning för:"
echo "  $WATCH_DIR"
echo "Service:"
echo "  $SERVICE_NAME"
echo

# ===== Dependencies =====

missing=()

command -v inotifywait >/dev/null || missing+=(inotify-tools)
command -v gs >/dev/null || missing+=(ghostscript)
command -v notify-send >/dev/null || missing+=(libnotify-bin)

if [ "${#missing[@]}" -gt 0 ]; then
	echo "Följande beroenden saknas:"
	printf "• %s\n" "${missing[@]}"
	echo

	read -p "Installera dessa via apt? (kräver sudo) (y/n) " answer
	if [[ ! "$answer" =~ ^[Yy]$ ]]; then
		echo "Avbryter."
		exit 1
	fi

	sudo apt update
	sudo apt install -y "${missing[@]}"
fi

# ===== Installera programmet =====

mkdir -p "$HOME/.local/bin"
cp "$SCRIPT_DIR/pdf-rensa.sh" "$BIN"
chmod +x "$BIN"

# ===== Skapa service =====

mkdir -p "$SERVICE_DIR"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=PDF-rensning av $WATCH_DIR

[Service]
ExecStart=$BIN "$WATCH_DIR"
Restart=always

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE_NAME"

echo
echo "Klart!"
echo "PDF-filer i följande mapp rensas nu automatiskt:"
echo "  $WATCH_DIR"
echo
echo "Service:"
echo "  $SERVICE_NAME"

