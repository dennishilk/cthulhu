#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/utils.sh
source "${SCRIPT_DIR}/utils.sh"

restore_system() {
  local distro="$1"
  local date_dir="$2"
  local source_dir="${CTHULHU_ROOT}/${distro}/${date_dir}"

  if [[ ! -d "${source_dir}" ]]; then
    error "System snapshot not found: ${source_dir}"
    exit 1
  fi

  printf 'System restore source: %s\n' "${source_dir}"
  warn "System restore replays files only; package reinstallation is manual."
  info "System restore requested for ${source_dir}"
}

restore_component() {
  local component="$1"
  local backup_root
  backup_root="$(backup_user_config_root)"

  case "${component}" in
    fastfetch)
      copy_to_user_config "${CTHULHU_ROOT}/Fastfetch/fastfetch" "${HOME}/.config/fastfetch" "${backup_root}" || true
      ;;
    rofi)
      copy_to_user_config "${CTHULHU_ROOT}/Rofi/rofi" "${HOME}/.config/rofi" "${backup_root}" || true
      ;;
    picom)
      copy_to_user_config "${CTHULHU_ROOT}/Picom/picom" "${HOME}/.config/picom" "${backup_root}" || true
      ;;
    dunst)
      copy_to_user_config "${CTHULHU_ROOT}/Dunst/dunst" "${HOME}/.config/dunst" "${backup_root}" || true
      ;;
    dwm)
      copy_to_user_config "${CTHULHU_ROOT}/WM/dwm/dwm" "${HOME}/.config/dwm" "${backup_root}" || true
      ;;
    xmonad)
      copy_to_user_config "${CTHULHU_ROOT}/WM/xmonad/xmonad" "${HOME}/.xmonad" "${backup_root}" || true
      ;;
    hyprland)
      copy_to_user_config "${CTHULHU_ROOT}/WM/hyprland/hypr" "${HOME}/.config/hypr" "${backup_root}" || true
      ;;
    xfce)
      copy_to_user_config "${CTHULHU_ROOT}/DE/xfce/xfce4" "${HOME}/.config/xfce4" "${backup_root}" || true
      ;;
    cinnamon)
      copy_to_user_config "${CTHULHU_ROOT}/DE/cinnamon/cinnamon" "${HOME}/.config/cinnamon" "${backup_root}" || true
      ;;
    plasma)
      local p
      shopt -s nullglob
      for p in "${CTHULHU_ROOT}"/DE/plasma/*; do
        copy_to_user_config "${p}" "${HOME}/.config/$(basename "${p}")" "${backup_root}" || true
      done
      shopt -u nullglob
      ;;
    gnome)
      local g
      shopt -s nullglob
      for g in "${CTHULHU_ROOT}"/DE/gnome/*; do
        copy_to_user_config "${g}" "${HOME}/.config/$(basename "${g}")" "${backup_root}" || true
      done
      shopt -u nullglob
      ;;
    all)
      local item
      for item in fastfetch rofi picom dunst dwm xmonad hyprland xfce cinnamon plasma gnome; do
        restore_component "${item}"
      done
      return
      ;;
    *)
      error "Unsupported core component: ${component}"
      exit 2
      ;;
  esac

  info "Core restore completed for component: ${component}"
  printf 'Restored component: %s (backup: %s)\n' "${component}" "${backup_root}"
}

main() {
  local mode="${1:-}"
  case "${mode}" in
    system)
      [[ $# -eq 3 ]] || { error "Usage: restore.sh system <distro> <date>"; exit 2; }
      restore_system "$2" "$3"
      ;;
    core)
      [[ $# -eq 2 ]] || { error "Usage: restore.sh core <component|all>"; exit 2; }
      restore_component "$2"
      ;;
    *)
      error "Usage: restore.sh <system|core> ..."
      exit 2
      ;;
  esac
}

main "$@"
