#!/usr/bin/env bash
set -Eeuo pipefail
cfg="$HOME/.config/dwm"
src="$cfg/src"
[[ $EUID -ne 0 ]] || { echo 'Never build dwm as root.' >&2; exit 1; }
[[ -f "$cfg/config.h" && -f "$src/Makefile" && -f "$cfg/patch_dwm.py" ]] || {
  echo 'Missing dwm 6.8 checkout, config or patch helper.' >&2; exit 1;
}
python3 "$cfg/patch_dwm.py"
cp -- "$cfg/config.h" "$src/config.h"
make -C "$src" clean
make -C "$src" -j2
install -Dm755 -- "$src/dwm" "$HOME/.local/bin/dwm"
printf 'Installed: %s/.local/bin/dwm\n' "$HOME"
