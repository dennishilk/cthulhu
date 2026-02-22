#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/utils.sh
source "$SCRIPT_DIR/utils.sh"

DISTRO="unknown"
WM="unknown"

normalize_distro() {
  local raw="$1"
  case "$raw" in
    gentoo) echo "gentoo" ;;
    nixos) echo "nixos" ;;
    debian|ubuntu|linuxmint|pop) echo "debian" ;;
    arch|manjaro|endeavouros) echo "arch" ;;
    *) echo "unknown" ;;
  esac
}

detect_distro() {
  local id=""
  local id_like=""

  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    id="${ID:-unknown}"
    id_like="${ID_LIKE:-}"
  fi

  DISTRO="$(normalize_distro "$id")"
  if [ "$DISTRO" = "unknown" ] && [ -n "$id_like" ]; then
    for token in $id_like; do
      DISTRO="$(normalize_distro "$token")"
      [ "$DISTRO" != "unknown" ] && break
    done
  fi

  log "INFO" "Detected distro: $DISTRO"
}

detect_wm() {
  local session="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"
  local proc=""

  if [ -n "$session" ]; then
    case "$(printf '%s' "$session" | tr '[:upper:]' '[:lower:]')" in
      *dwm*) WM="dwm" ;;
      *xmonad*) WM="xmonad" ;;
      *plasma*|*kde*) WM="plasma" ;;
    esac
  fi

  if [ "$WM" = "unknown" ]; then
    proc="$(ps -e -o comm= | tr '[:upper:]' '[:lower:]' || true)"
    case "$proc" in
      *dwm*) WM="dwm" ;;
      *xmonad*) WM="xmonad" ;;
      *plasmashell*) WM="plasma" ;;
    esac
  fi

  log "INFO" "Detected WM: $WM"
}

export DISTRO WM
