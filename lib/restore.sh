#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/utils.sh
source "$SCRIPT_DIR/utils.sh"

restore_item() {
  local source_path="$1"
  local target_path="$2"

  if [ ! -e "$source_path" ]; then
    die "Restore source does not exist: $source_path"
  fi

  backup_target "$target_path"
  if confirm_overwrite "$target_path"; then
    ensure_dir "$(dirname "$target_path")"
    cp -a "$source_path" "$target_path"
    log "INFO" "Restored $source_path -> $target_path"
  fi
}

restore_system() {
  local distro="$1"
  local date_tag="$2"
  local snapshot_dir="$ROOT_DIR/systems/$distro/$date_tag"

  [ -d "$snapshot_dir" ] || die "System snapshot not found: $snapshot_dir"

  printf 'Restore system snapshot metadata from %s? [y/N]: ' "$snapshot_dir"
  read -r answer
  case "$answer" in
    y|Y|yes|YES)
      backup_target "$HOME/.config"
      ensure_dir "$HOME/.config/cthulhu-restored-system"
      cp -a "$snapshot_dir" "$HOME/.config/cthulhu-restored-system/"
      log "INFO" "System snapshot copied to ~/.config/cthulhu-restored-system"
      ;;
    *)
      log "INFO" "System restore cancelled by user"
      ;;
  esac
}

restore_core() {
  local component="$1"

  case "$component" in
    all)
      restore_core_component "fastfetch" "$HOME/.config/fastfetch"
      restore_core_component "rofi" "$HOME/.config/rofi"
      restore_core_component "picom" "$HOME/.config/picom"
      restore_core_component "dunst" "$HOME/.config/dunst"
      restore_core_component "kitty" "$HOME/.config/kitty"
      restore_core_component "zsh" "$HOME/.zshrc"
      restore_core_component "wm/dwm" "$HOME/.config/dwm"
      restore_core_component "wm/xmonad" "$HOME/.xmonad"
      restore_plasma_components
      ;;
    wm/plasma|plasma)
      restore_plasma_components
      ;;
    *)
      restore_core_component "$component" "$(core_target_for_component "$component")"
      ;;
  esac
}

core_target_for_component() {
  local component="$1"
  case "$component" in
    fastfetch|rofi|picom|dunst|kitty) printf '%s/.config/%s\n' "$HOME" "$component" ;;
    zsh) printf '%s/.zshrc\n' "$HOME" ;;
    wm/dwm|dwm) printf '%s/.config/dwm\n' "$HOME" ;;
    wm/xmonad|xmonad) printf '%s/.xmonad\n' "$HOME" ;;
    *) die "Unknown core component: $component" ;;
  esac
}

restore_core_component() {
  local component="$1"
  local target_path="$2"
  local source_base="$ROOT_DIR/core/$component"

  if [ ! -d "$source_base" ] && [ ! -f "$source_base" ]; then
    log "WARN" "Stored core component missing: $component"
    return 0
  fi

  if [ -d "$source_base" ]; then
    local found=0
    local item
    for item in "$source_base"/*; do
      [ -e "$item" ] || continue
      found=1
      restore_item "$item" "$target_path"
    done
    [ "$found" -eq 0 ] && log "WARN" "No files in component archive: $component"
  else
    restore_item "$source_base" "$target_path"
  fi
}

restore_plasma_components() {
  local source_dir="$ROOT_DIR/core/wm/plasma"
  [ -d "$source_dir" ] || { log "WARN" "No archived plasma configs"; return 0; }

  local item
  local found=0
  for item in "$source_dir"/*; do
    [ -e "$item" ] || continue
    found=1
    restore_item "$item" "$HOME/.config/$(basename "$item")"
  done

  [ "$found" -eq 0 ] && log "WARN" "No plasma entries to restore"
}
