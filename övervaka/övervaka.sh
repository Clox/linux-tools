#!/bin/bash

# ===== Inställningar =====

REF="$HOME/tele2_queue_ref.png"
NOW="$HOME/tele2_queue_now.png"

ALARM="/usr/share/sounds/freedesktop/stereo/phone-incoming-call.oga"

CHECK_INTERVAL=5
DIFF_THRESHOLD=120
ALARM_PAUSE=0.2
START_DELAY=5


# ===== Spara och stäng av skärmsläckare =====

# spara nuvarande inställningar
SCREENSAVER_STATE=$(xset q | awk '/timeout:/ {print $2}')
DPMS_STATE=$(xset q | awk '/Standby:/ {print $2}')

# stäng av
xset s off
xset -dpms

notify-send "Tele2-övervakning" "Skärmsläckare tillfälligt avaktiverad"


# ===== Välj område =====

notify-send "Tele2-övervakning" "Markera området som ska övervakas"
AREA=$(slop)

if [ -z "$AREA" ]; then
	echo "Inget område valt. Avslutar."
	exit 1
fi


# ===== Vänta tills allt är lugnt =====

notify-send "Tele2-övervakning" "Väntar $START_DELAY sek innan start..."
sleep "$START_DELAY"


# ===== Ta referensbild =====

maim -g "$AREA" "$REF"
notify-send "Tele2-övervakning startad" "Du kan göra annat nu"


# ===== Signalhantering =====

alarm_pid=""

restore_screensaver() {
	# återställ skärmsläckare
	xset s "$SCREENSAVER_STATE"
	xset +dpms
}

cleanup() {
	if [ -n "$alarm_pid" ]; then
		kill "$alarm_pid" 2>/dev/null
	fi
	restore_screensaver
	exit 0
}

trap cleanup INT TERM EXIT


# ===== Övervakningsloop =====

while true; do
	sleep "$CHECK_INTERVAL"

	maim -g "$AREA" "$NOW"

	rawDiff=$(compare -metric AE "$REF" "$NOW" null: 2>&1)
	diff=$(echo "$rawDiff" | awk '{print $1}')

	if ! [[ "$diff" =~ ^[0-9]+$ ]]; then
		continue
	fi

	if [ "$diff" -gt "$DIFF_THRESHOLD" ]; then
		notify-send "Tele2-chatten är redo!" "Tryck Ctrl+C för att stoppa larmet"

		while true; do
			paplay "$ALARM" &
			alarm_pid=$!
			wait "$alarm_pid"
			sleep "$ALARM_PAUSE"
		done
	fi
done

