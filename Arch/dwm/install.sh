#!/usr/bin/env bash
# Arch Minimal stage 1: personal dwm, yay, Chrome. RUN AS NORMAL USER.
set -Eeuo pipefail
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
info() { printf '\n==> %s\n' "$*"; }

[[ $EUID -ne 0 ]] || fail 'Nicht als root/sudo starten.'
[[ -f /etc/arch-release ]] || fail 'Nur Arch Linux.'
command -v sudo >/dev/null || fail 'Benutzer benoetigt sudo (in Archinstall konfigurieren).'
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd -P)"
DWM_DIR="$HOME/.config/dwm"
SRC_DIR="$DWM_DIR/src"
for f in config.h start.sh rebuild.sh status.sh; do
  [[ -f "$SCRIPT_DIR/$f" ]] || fail "Fehlende Datei im Repo: $f"
done

info 'Aktuelle offizielle Pakete (kein automatisches Ja zu Rueckfragen)'
sudo -v
sudo pacman -Syu --needed \
  git base-devel pkgconf libx11 libxft libxinerama \
  xorg-server xorg-xinit xorg-xrandr xorg-xsetroot \
  mesa vulkan-radeon kitty rofi ttf-jetbrains-mono-nerd

info 'dwm 6.8 nach ~/.config/dwm/src (nichts nach /usr/local)'
mkdir -p "$DWM_DIR/bin"
if [[ -e "$SRC_DIR" ]]; then
  [[ -d "$SRC_DIR/.git" ]] || fail "Vorhandenes $SRC_DIR ist kein Git-Checkout."
  [[ "$(git -C "$SRC_DIR" remote get-url origin)" == "https://git.suckless.org/dwm" ]] || fail 'Unbekannte dwm-Quelle: Stop.'
  git -C "$SRC_DIR" fetch --tags origin
else
  git clone https://git.suckless.org/dwm "$SRC_DIR"
fi
git -C "$SRC_DIR" checkout --detach 6.8
for f in config.h start.sh rebuild.sh status.sh; do
  if [[ ! -e "$DWM_DIR/$f" ]]; then
    cp "$SCRIPT_DIR/$f" "$DWM_DIR/$f"
  else
    info "$f besteht bereits: bleibt unveraendert."
  fi
done
chmod u+x "$DWM_DIR/start.sh" "$DWM_DIR/rebuild.sh" "$DWM_DIR/status.sh"
"$DWM_DIR/rebuild.sh"

if [[ -e "$HOME/.xinitrc" ]]; then
  if ! grep -Fqx 'exec "$HOME/.config/dwm/start.sh"' "$HOME/.xinitrc"; then
    info 'Bestehende ~/.xinitrc NICHT ueberschrieben. Zum Start von dwm bitte selbst anpassen.'
  fi
else
  printf '#!/bin/sh\nexec "$HOME/.config/dwm/start.sh"\n' > "$HOME/.xinitrc"
fi

info 'yay aus AUR, makepkg ausschliesslich als normaler Benutzer'
if ! command -v yay >/dev/null 2>&1; then
  TMP_BUILD="$(mktemp -d /tmp/cthulhu-yay.XXXXXXXX)"
  trap 'rm -rf -- "$TMP_BUILD"' EXIT
  git clone https://aur.archlinux.org/yay.git "$TMP_BUILD/yay"
  cat "$TMP_BUILD/yay/PKGBUILD"
  read -r -p 'PKGBUILD pruefen. Enter zum Fortfahren; Ctrl+C zum Abbrechen: ' _
  (cd "$TMP_BUILD/yay" && makepkg -si)
  rm -rf -- "$TMP_BUILD"
  trap - EXIT
fi
info 'Chrome aus dem AUR, mit Rueckfragen'
yay -S --needed google-chrome

printf '\nFertig. TTY-Login -> startx.\n'
printf 'Super+Enter Kitty | Super+B Chrome | Super+D Rofi | Super+Q schliessen.\n'
printf 'DWM-Dateien komplett in %s\n' "$DWM_DIR"
printf 'Steam, Multilib, Audio, Fastfetch, 144Hz und Zusatzprogramme erst nach dem ersten Test.\n'
