#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/utils.sh
source "$SCRIPT_DIR/utils.sh"
# shellcheck source=lib/detect.sh
source "$SCRIPT_DIR/detect.sh"

save_component() {
  local name="$1"
  local source_path="$2"
  local target_dir="$ROOT_DIR/core/$name"

  if [ -e "$source_path" ]; then
    ensure_dir "$target_dir"
    if confirm_overwrite "$target_dir"; then
      cp -a "$source_path" "$target_dir/"
      log "INFO" "Saved core component: $name"
    fi
  else
    log "WARN" "Core component not found: $source_path"
  fi
}

save_plasma_configs() {
  local target_dir="$ROOT_DIR/core/wm/plasma"
  local found=0

  ensure_dir "$target_dir"
  for item in "$HOME/.config"/plasma*; do
    if [ -e "$item" ]; then
      found=1
      if confirm_overwrite "$target_dir/$(basename "$item")"; then
        cp -a "$item" "$target_dir/"
        log "INFO" "Saved Plasma config: $item"
      fi
    fi
  done

  if [ "$found" -eq 0 ]; then
    log "WARN" "No plasma* entries found in ~/.config"
  fi
}

save_core() {
  detect_wm

  save_component "fastfetch" "$HOME/.config/fastfetch"
  save_component "rofi" "$HOME/.config/rofi"
  save_component "picom" "$HOME/.config/picom"
  save_component "dunst" "$HOME/.config/dunst"
  save_component "kitty" "$HOME/.config/kitty"
  save_component "zsh" "$HOME/.zshrc"

  if [ -e "$HOME/.config/dwm" ]; then
    save_component "wm/dwm" "$HOME/.config/dwm"
  fi

  if [ -e "$HOME/.xmonad" ]; then
    save_component "wm/xmonad" "$HOME/.xmonad"
  fi

  save_plasma_configs
  log "INFO" "Core save complete"
}
