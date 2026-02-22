#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/utils.sh
source "${SCRIPT_DIR}/utils.sh"

get_distro() {
  local distro="Unknown"

  if [[ -f /etc/os-release ]]; then
    local os_id
    os_id="$(. /etc/os-release && printf '%s' "${ID:-unknown}")"
    case "${os_id}" in
      debian|ubuntu|linuxmint|pop)
        distro="Debian"
        ;;
      nixos)
        distro="NixOS"
        ;;
      gentoo)
        distro="Gentoo"
        ;;
      arch|manjaro|endeavouros)
        distro="Arch"
        ;;
      *)
        distro="Unknown"
        ;;
    esac
  fi

  printf '%s\n' "${distro}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  get_distro
fi
