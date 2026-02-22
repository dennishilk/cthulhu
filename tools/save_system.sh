#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/utils.sh
source "${SCRIPT_DIR}/utils.sh"
# shellcheck source=tools/detect.sh
source "${SCRIPT_DIR}/detect.sh"

save_gentoo() {
  local target_dir="$1"
  safe_run "${target_dir}/installed-packages.txt" qlist -I || true
  safe_run "${target_dir}/emerge-info.txt" emerge --info || true
  [[ -f /var/lib/portage/world ]] && cp -a /var/lib/portage/world "${target_dir}/world"
  safe_run "${target_dir}/kernel.txt" uname -r || true
}

save_nixos() {
  local target_dir="$1"
  [[ -f /etc/nixos/configuration.nix ]] && cp -a /etc/nixos/configuration.nix "${target_dir}/configuration.nix"
  [[ -f /etc/nixos/flake.nix ]] && cp -a /etc/nixos/flake.nix "${target_dir}/flake.nix"
  safe_run "${target_dir}/nixos-version.txt" nixos-version || true
  safe_run "${target_dir}/channels.txt" nix-channel --list || true
}

save_debian() {
  local target_dir="$1"
  safe_run "${target_dir}/dpkg-selections.txt" dpkg --get-selections || true
  if compgen -G '/etc/apt/sources.list*' >/dev/null; then
    mkdir -p "${target_dir}/apt"
    cp -a /etc/apt/sources.list* "${target_dir}/apt/"
  fi
  safe_run "${target_dir}/kernel.txt" uname -r || true
}

save_arch() {
  local target_dir="$1"
  safe_run "${target_dir}/pacman-explicit.txt" pacman -Qe || true
  safe_run "${target_dir}/pacman-foreign.txt" pacman -Qm || true
  safe_run "${target_dir}/kernel.txt" uname -r || true
}

main() {
  local distro
  distro="$(get_distro)"

  if [[ "${distro}" == "Unknown" ]]; then
    error "Unsupported distro detected. Save aborted."
    exit 2
  fi

  local dated_dir="${CTHULHU_ROOT}/${distro}/${DATE_STAMP}"
  mkdir -p "${dated_dir}"

  case "${distro}" in
    Gentoo) save_gentoo "${dated_dir}" ;;
    NixOS) save_nixos "${dated_dir}" ;;
    Debian) save_debian "${dated_dir}" ;;
    Arch) save_arch "${dated_dir}" ;;
  esac

  info "System snapshot saved to ${dated_dir}"
  printf 'Saved system snapshot: %s\n' "${dated_dir}"
}

main "$@"
