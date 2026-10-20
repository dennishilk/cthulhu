#!/usr/bin/env bash
set -Eeuo pipefail
cfg="$HOME/.config/dwm"
[[ $EUID -ne 0 ]] || { echo 'Nicht als root bauen!' >&2; exit 1; }
[[ -f "$cfg/config.h" && -f "$cfg/src/Makefile" ]] || { echo 'dwm-Quellen/config.h fehlen.' >&2; exit 1; }
cp "$cfg/config.h" "$cfg/src/config.h"
make -C "$cfg/src" clean
make -C "$cfg/src" -j2
install -Dm755 "$cfg/src/dwm" "$cfg/bin/dwm"
echo "Eigener dwm-Build: $cfg/bin/dwm"
