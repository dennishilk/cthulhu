#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC2034
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="$ROOT_DIR/logs/cthulhu.log"

mkdir -p "$ROOT_DIR/logs"

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  local level="$1"
  shift
  local message="$*"
  printf '[%s] [%s] %s\n' "$(timestamp)" "$level" "$message" | tee -a "$LOG_FILE"
}

die() {
  log "ERROR" "$*"
  exit 1
}

ensure_dir() {
  local dir="$1"
  mkdir -p "$dir"
}

run_capture() {
  local output_file="$1"
  shift
  if command -v "$1" >/dev/null 2>&1; then
    log "INFO" "Running command: $*"
    if "$@" >"$output_file" 2>&1; then
      log "INFO" "Saved output to $output_file"
    else
      log "WARN" "Command failed, captured output in $output_file"
    fi
  else
    log "WARN" "Command not available, skipping: $1"
  fi
}

copy_if_exists() {
  local source="$1"
  local destination="$2"

  if [ -e "$source" ]; then
    ensure_dir "$(dirname "$destination")"
    cp -a "$source" "$destination"
    log "INFO" "Copied $source -> $destination"
  else
    log "WARN" "Missing source, skipped: $source"
  fi
}

confirm_overwrite() {
  local target="$1"
  if [ -e "$target" ]; then
    printf 'Target exists: %s\nOverwrite? [y/N]: ' "$target"
    read -r answer
    case "$answer" in
      y|Y|yes|YES) return 0 ;;
      *) log "INFO" "User skipped overwrite for $target"; return 1 ;;
    esac
  fi
  return 0
}

backup_target() {
  local target="$1"
  if [ ! -e "$target" ]; then
    return 0
  fi

  local backup_root="$HOME/.config/cthulhu-backup-$(date '+%Y-%m-%d')"
  local target_name
  target_name="$(basename "$target")"
  ensure_dir "$backup_root"
  cp -a "$target" "$backup_root/$target_name"
  log "INFO" "Backed up $target -> $backup_root/$target_name"
}
