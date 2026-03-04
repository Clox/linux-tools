#!/bin/bash

set -e

SCRIPT_NAME="övervaka"
TARGET="$HOME/.local/bin"
SOURCE="$(cd "$(dirname "$0")" && pwd)/övervaka.sh"

# Kommando -> paket
DEPENDENCIES=(
	maim:maim
	slop:slop
	compare:imagemagick
	paplay:pulseaudio-utils
	notify-send:libnotify-bin
	xset:x11-xserver-utils
)

echo "Installerar $SCRIPT_NAME..."
echo

missing_packages=()

for dep in "${DEPENDENCIES[@]}"; do
	cmd="${dep%%:*}"
	pkg="${dep##*:}"

	if ! command -v "$cmd" >/dev/null 2>&1; then
		missing_packages+=("$pkg")
	fi
done

if [ "${#missing_packages[@]}" -gt 0 ]; then
	echo "Följande beroenden saknas:"
	for pkg in "${missing_packages[@]}"; do
		echo "• $pkg"
	done
	echo

	read -p "Installera dessa via apt? (kräver sudo) (y/n) " answer
	if [[ ! "$answer" =~ ^[Yy]$ ]]; then
		echo "Avbryter installation."
		exit 1
	fi

	sudo apt update
	sudo apt install -y "${missing_packages[@]}"
else
	echo "Alla beroenden finns redan."
fi

echo
echo "Installerar programmet..."

mkdir -p "$TARGET"
cp "$SOURCE" "$TARGET/$SCRIPT_NAME"
chmod +x "$TARGET/$SCRIPT_NAME"

echo
echo "Klart!"
echo "Kör kommando '$SCRIPT_NAME' för att övervaka en del av skärmen"
echo "och larma när något ändras."

