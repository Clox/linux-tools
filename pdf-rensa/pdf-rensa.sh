#!/bin/bash

WATCH_DIR="$1"

if [ -z "$WATCH_DIR" ]; then
	echo "Ingen mapp angiven"
	exit 1
fi

inotifywait -m -e close_write --format "%f" "$WATCH_DIR" | while read file; do
	if [[ "$file" == *.pdf ]]; then
		full="$WATCH_DIR/$file"
		tmp="$full.tmp"

		gs \
			-dSAFER \
			-dBATCH \
			-dNOPAUSE \
			-sDEVICE=pdfwrite \
			-sOutputFile="$tmp" \
			"$full" && mv "$tmp" "$full"

		notify-send "PDF rensad" "$file har rensats från osynliga sidor"
	fi
done

