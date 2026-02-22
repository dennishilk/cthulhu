#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/utils.sh
source "$SCRIPT_DIR/utils.sh"
# shellcheck source=lib/detect.sh
source "$SCRIPT_DIR/detect.sh"

save_kernel_info() {
  local snapshot_dir="$1"
  uname -r > "$snapshot_dir/kernel-version.txt"
  log "INFO" "Saved kernel version"
}

save_gentoo() {
  local snapshot_dir="$1"
  run_capture "$snapshot_dir/qlist-installed.txt" qlist -I
  run_capture "$snapshot_dir/emerge-info.txt" emerge --info
  copy_if_exists "/var/lib/portage/world" "$snapshot_dir/world"
}

save_nixos() {
  local snapshot_dir="$1"
  copy_if_exists "/etc/nixos/configuration.nix" "$snapshot_dir/configuration.nix"
  copy_if_exists "$HOME/flake.nix" "$snapshot_dir/flake.nix"
  run_capture "$snapshot_dir/nixos-version.txt" nixos-version
  run_capture "$snapshot_dir/nix-channel-list.txt" nix-channel --list
}

save_debian() {
  local snapshot_dir="$1"
  run_capture "$snapshot_dir/dpkg-selections.txt" dpkg --get-selections
  copy_if_exists "/etc/apt/sources.list" "$snapshot_dir/sources.list"
  copy_if_exists "/etc/apt/sources.list.d" "$snapshot_dir/sources.list.d"
}

save_arch() {
  local snapshot_dir="$1"
  run_capture "$snapshot_dir/pacman-explicit.txt" pacman -Qe
  run_capture "$snapshot_dir/pacman-aur.txt" pacman -Qm
}

save_system() {
  detect_distro

  local date_tag snapshot_dir
  date_tag="$(date '+%Y-%m-%d')"
  snapshot_dir="$ROOT_DIR/systems/$DISTRO/$date_tag"

  ensure_dir "$snapshot_dir"
  log "INFO" "Saving system snapshot to $snapshot_dir"

  case "$DISTRO" in
    gentoo) save_gentoo "$snapshot_dir" ;;
    nixos) save_nixos "$snapshot_dir" ;;
    debian) save_debian "$snapshot_dir" ;;
    arch) save_arch "$snapshot_dir" ;;
    *) log "WARN" "Unsupported distro; saving kernel info only" ;;
  esac

  save_kernel_info "$snapshot_dir"
  log "INFO" "System snapshot complete"
}
