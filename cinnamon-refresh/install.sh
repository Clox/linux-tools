#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bin_dir="$HOME/.local/bin"
unit_dir="$HOME/.config/systemd/user"

if (( $# != 0 )); then
    echo "Användning: install.sh" >&2
    exit 2
fi

if ! command -v xssstate >/dev/null 2>&1; then
    echo "xssstate saknas. Installera paketet suckless-tools först." >&2
    exit 1
fi

install -d "$bin_dir" "$unit_dir"
install -m 0755 "$script_dir/cinnamon-refresh" "$bin_dir/cinnamon-refresh"
sed "s|@HOME@|$HOME|g" "$script_dir/cinnamon-refresh.service.in" > "$unit_dir/cinnamon-refresh.service"
install -m 0644 "$script_dir/cinnamon-refresh.timer" "$unit_dir/cinnamon-refresh.timer"
systemctl --user daemon-reload
systemctl --user enable --now cinnamon-refresh.timer
echo "Automatisk kontroll aktiverad och startar vid nästa inloggning."

echo "Kontrollera: $bin_dir/cinnamon-refresh status"
echo "Starta om:  $bin_dir/cinnamon-refresh restart"
echo "Timer:      systemctl --user status cinnamon-refresh.timer"
