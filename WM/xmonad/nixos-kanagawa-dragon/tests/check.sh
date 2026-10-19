#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
python3 tests/test_setup.py
shellcheck scripts/install-user.sh home/.local/bin/cthulhu-audio home/.config/cthulhu/monitors.sh
temporary="$(mktemp -d)"
trap 'rm -rf -- "$temporary"' EXIT
ghc -fno-code -fforce-recomp -outputdir "$temporary" home/.xmonad/xmonad.hs
{ printf 'import Xmobar\nmain :: IO ()\nmain = xmobar $ '; cat home/.xmobarrc; } > "$temporary/Bar.hs"
ghc -fno-code -fforce-recomp -outputdir "$temporary" "$temporary/Bar.hs"
