#!/usr/bin/env bash
set -euo pipefail

if (( $# != 0 )); then
    echo "Användning: install.sh" >&2
    exit 2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bin_dir="$HOME/.local/bin"
libexec_dir="$HOME/.local/libexec"
unit_dir="$HOME/.config/systemd/user"

for program in xrandr xssstate lpstat systemd-run; do
    if ! command -v "$program" >/dev/null 2>&1; then
        echo "Kräver $program." >&2
        exit 1
    fi
done
if ! /usr/bin/python3 -c 'import gi; from gi.repository import Gio, GLib' >/dev/null 2>&1; then
    echo "Kräver Python-modulen gi (python3-gi)." >&2
    exit 1
fi

systemctl --user disable --now cinnamon-refresh.timer 2>/dev/null || true
systemctl --user stop cinnamon-refresh.service 2>/dev/null || true

install -d "$bin_dir" "$libexec_dir" "$unit_dir"
install -m 0755 "$script_dir/cinnamon-refresh" "$bin_dir/cinnamon-refresh"
install -m 0755 "$script_dir/cinnamon-refresh-watch" "$libexec_dir/cinnamon-refresh-watch"
install -m 0644 "$script_dir/cinnamon-refresh.timer" "$unit_dir/cinnamon-refresh.timer"
sed "s|@HOME@|$HOME|g" "$script_dir/cinnamon-refresh.service.in" > "$unit_dir/cinnamon-refresh.service"
systemctl --user daemon-reload
systemctl --user enable --now cinnamon-refresh.timer

echo "Nattlig kontroll aktiverad. Vid avstängd skärm väntar den på återanslutning."
echo "Kontrollera: $bin_dir/cinnamon-refresh status"
echo "Starta om:  $bin_dir/cinnamon-refresh restart"
echo "Timer:      systemctl --user status cinnamon-refresh.timer"
