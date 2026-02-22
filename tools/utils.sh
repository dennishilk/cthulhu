#!/usr/bin/env bash
set -euo pipefail

CTHULHU_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="${CTHULHU_ROOT}/logs/cthulhu.log"
DATE_STAMP="$(date +%F)"

ensure_runtime_dirs() {
  mkdir -p "${CTHULHU_ROOT}/logs"
}

log() {
  ensure_runtime_dirs
  local level="$1"
  shift
  local message="$*"
  printf '%s [%s] %s\n' "$(date '+%F %T')" "${level}" "${message}" | tee -a "${LOG_FILE}" >/dev/null
}

warn() {
  log "WARN" "$*"
}

info() {
  log "INFO" "$*"
}

error() {
  log "ERROR" "$*"
}

safe_run() {
  local output_file="$1"
  shift

  if command -v "$1" >/dev/null 2>&1; then
    if "$@" >"${output_file}" 2>&1; then
      info "Command succeeded: $*"
      return 0
    fi
    warn "Command failed: $*"
    return 1
  fi

  warn "Command unavailable: $1"
  return 1
}

prompt_overwrite() {
  local target="$1"
  if [[ ! -e "${target}" ]]; then
    return 0
  fi

  read -r -p "Target exists (${target}). Overwrite? [y/N]: " answer
  [[ "${answer}" =~ ^[Yy]$ ]]
}

backup_target() {
  local target="$1"
  if [[ -e "${target}" ]]; then
    local backup="${target}.bak-${DATE_STAMP}-$(date +%H%M%S)"
    mv "${target}" "${backup}"
    info "Backed up ${target} -> ${backup}"
  fi
}

copy_into_repo() {
  local source_path="$1"
  local destination_path="$2"

  if [[ ! -e "${source_path}" ]]; then
    warn "Missing source path: ${source_path}"
    return 1
  fi

  if ! prompt_overwrite "${destination_path}"; then
    info "Skipped copy (user declined overwrite): ${destination_path}"
    return 1
  fi

  backup_target "${destination_path}"
  mkdir -p "$(dirname "${destination_path}")"
  cp -a "${source_path}" "${destination_path}"
  info "Copied ${source_path} -> ${destination_path}"
}

backup_user_config_root() {
  local backup_dir="${HOME}/.config/cthulhu-backup-${DATE_STAMP}"
  mkdir -p "${backup_dir}"
  printf '%s\n' "${backup_dir}"
}

copy_to_user_config() {
  local source_path="$1"
  local destination_path="$2"
  local backup_root="$3"

  if [[ ! -e "${source_path}" ]]; then
    warn "Missing restore source path: ${source_path}"
    return 1
  fi

  if ! prompt_overwrite "${destination_path}"; then
    info "Skipped restore (user declined overwrite): ${destination_path}"
    return 1
  fi

  mkdir -p "$(dirname "${destination_path}")"

  if [[ -e "${destination_path}" ]]; then
    local backup_path="${backup_root}/${destination_path#${HOME}/}"
    mkdir -p "$(dirname "${backup_path}")"
    cp -a "${destination_path}" "${backup_path}"
    info "Backed up current config ${destination_path} -> ${backup_path}"
    rm -rf "${destination_path}"
  fi

  cp -a "${source_path}" "${destination_path}"
  info "Restored ${source_path} -> ${destination_path}"
}
