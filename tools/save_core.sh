#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/utils.sh
source "${SCRIPT_DIR}/utils.sh"

save_pair() {
  local source_path="$1"
  local destination_path="$2"
  copy_into_repo "${source_path}" "${destination_path}" || true
}

save_optional_pair() {
  local source_path="$1"
  local destination_path="$2"

  if [[ -e "${source_path}" ]]; then
    copy_into_repo "${source_path}" "${destination_path}" || true
  fi
}

save_globbed_configs() {
  local pattern="$1"
  local target_dir="$2"
  local matched=0

  mkdir -p "${target_dir}"
  shopt -s nullglob
  for source_path in ${pattern}; do
    matched=1
    local name
    name="$(basename "${source_path}")"
    copy_into_repo "${source_path}" "${target_dir}/${name}" || true
  done
  shopt -u nullglob

  if [[ "${matched}" -eq 0 ]]; then
    warn "No matches found for ${pattern}"
  fi
}

main() {
  save_pair "${HOME}/.config/fastfetch" "${CTHULHU_ROOT}/Fastfetch/fastfetch"
  save_pair "${HOME}/.config/rofi" "${CTHULHU_ROOT}/Rofi/rofi"
  save_pair "${HOME}/.config/picom" "${CTHULHU_ROOT}/Picom/picom"
  save_pair "${HOME}/.config/dunst" "${CTHULHU_ROOT}/Dunst/dunst"
  save_optional_pair "${HOME}/.wallpaper" "${CTHULHU_ROOT}/.wallpaper"

  save_pair "${HOME}/.config/dwm" "${CTHULHU_ROOT}/WM/dwm/dwm"
  save_pair "${HOME}/.xmonad" "${CTHULHU_ROOT}/WM/xmonad/xmonad"
  save_pair "${HOME}/.config/hypr" "${CTHULHU_ROOT}/WM/hyprland/hypr"

  save_pair "${HOME}/.config/xfce4" "${CTHULHU_ROOT}/DE/xfce/xfce4"
  save_pair "${HOME}/.config/cinnamon" "${CTHULHU_ROOT}/DE/cinnamon/cinnamon"
  save_globbed_configs "${HOME}/.config/plasma*" "${CTHULHU_ROOT}/DE/plasma"
  save_globbed_configs "${HOME}/.config/gnome*" "${CTHULHU_ROOT}/DE/gnome"

  info "Core configuration snapshot complete"
  printf 'Core configuration saved.\n'
}

main "$@"
