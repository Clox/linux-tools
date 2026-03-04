#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Tillgängliga verktyg:"
echo

for dir in "$BASE_DIR"/*/; do
	tool=$(basename "$dir")
	install_script="$dir/install.sh"
	desc_file="$dir/description.txt"

	if [ -f "$install_script" ]; then
		echo "=== $tool ==="

		if [ -f "$desc_file" ]; then
			cat "$desc_file"
		else
			echo "(Ingen beskrivning)"
		fi

		echo
		read -p "Installera $tool? (y/n) " answer
		if [[ "$answer" =~ ^[Yy]$ ]]; then
			echo
			echo "Installerar $tool..."
			bash "$install_script"
			echo
		fi
	fi
done

echo "Alla val genomförda."
echo
read -p "Tryck Enter för att avsluta..."

