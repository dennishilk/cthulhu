#!/bin/sh
set -eu
DIR="$HOME/.config/dwm"
[ -x "$DIR/bin/dwm" ] || { echo "dwm nicht gefunden: $DIR/bin/dwm" >&2; exit 1; }
xsetroot -solid '#11191b'
"$DIR/status.sh" &
exec "$DIR/bin/dwm"
