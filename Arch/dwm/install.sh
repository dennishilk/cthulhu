#!/usr/bin/env bash
# Cthulhu Arch / dwm 6.8 one-shot desktop setup. Run as nebu, never as root.
set -Eeuo pipefail
trap 'printf "ERROR: bootstrap failed at line %s (exit %s).\n" "$LINENO" "$?" >&2' ERR
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
info() { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }

[[ $EUID -ne 0 ]] || fail 'Run this script as the normal user, WITHOUT sudo.'
[[ -f /etc/arch-release ]] || fail 'This bootstrap requires Arch Linux.'
[[ -d "$HOME" && -w "$HOME" ]] || fail 'HOME is not writable.'
command -v sudo >/dev/null || fail 'sudo is required; configure it during Arch installation.'
command -v pacman >/dev/null || fail 'pacman is missing.'
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DWM_REPO="$REPO_DIR/Arch/dwm"
DWM_DIR="$HOME/.config/dwm"
SRC_DIR="$DWM_DIR/src"
export PATH="$HOME/.local/bin:$PATH"
for f in config.h start.sh rebuild.sh patch_dwm.py picom.conf kitty.conf \
         cthulhu-fastfetch.fish cthulhu-dwm.fish gtk3.ini xfce4-panel.xml \
         pacman-style.py flameshot.ini; do
  [[ -f "$DWM_REPO/$f" ]] || fail "Missing GitHub source: Arch/dwm/$f"
done
for f in "$REPO_DIR/Arch/fastfetch/config.jsonc" "$REPO_DIR/Arch/fastfetch/1.png" \
         "$REPO_DIR/Arch/wallpapers/1.png" "$REPO_DIR/Arch/wallpapers/2.png"; do
  [[ -f "$f" ]] || fail "Missing GitHub asset: $f"
done
# 32-bit libraries are mandatory, but changing pacman.conf belongs to the user.
if ! pacman -Sl multilib >/dev/null 2>&1; then
  fail 'multilib is not enabled. Enable [multilib] in /etc/pacman.conf, sync, then rerun.'
fi

info 'Installing official Arch packages (pacman handles its normal prompts)'
sudo -v
sudo pacman -Syu --needed \
  git base-devel pkgconf python libx11 libxft libxinerama \
  xorg-server xorg-xinit xorg-xrandr xorg-xset xorg-setxkbmap xorg-xauth \
  dmenu kitty fish fastfetch feh picom thunar tumbler gvfs udisks2 polkit-gnome \
  xfce4-clipman-plugin xfconf xarchiver unzip 7zip unrar \
  mousepad nano vlc flameshot dunst numlockx btop ttf-jetbrains-mono-nerd \
  networkmanager pipewire pipewire-alsa pipewire-pulse wireplumber alsa-utils \
  mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon \
  vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools libva-mesa-driver \
  xdg-utils openssh ufw pacman-contrib

info 'Applying only Color and ILoveCandy in pacman [options] (backing up original if changed)'
sudo python "$DWM_REPO/pacman-style.py"

info 'Official upstream dwm 6.8, sources confined to ~/.config/dwm/src'
mkdir -p -- "$DWM_DIR" "$HOME/.local/bin"
if [[ ! -e "$SRC_DIR" ]]; then
  git clone --depth 1 --branch 6.8 https://git.suckless.org/dwm "$SRC_DIR"
else
  [[ -d "$SRC_DIR/.git" ]] || fail "Existing $SRC_DIR is not a git checkout; will not replace it."
  origin="$(git -C "$SRC_DIR" remote get-url origin)"
  [[ "$origin" == 'https://git.suckless.org/dwm' ]] || fail "Unexpected dwm origin: $origin"
  [[ "$(git -C "$SRC_DIR" rev-parse HEAD)" == "$(git -C "$SRC_DIR" rev-parse 'refs/tags/6.8^{commit}')" ]] ||
    fail 'Existing dwm source is not checked out at official stable tag 6.8; refusing to overwrite.'
fi

info 'Installing repo-managed desktop configs (existing managed files replaced)'
install -m644 "$DWM_REPO/config.h" "$DWM_DIR/config.h"
install -m644 "$DWM_REPO/patch_dwm.py" "$DWM_DIR/patch_dwm.py"
for file in start.sh rebuild.sh; do
  install -m755 "$DWM_REPO/$file" "$DWM_DIR/$file"
done
install -Dm644 "$DWM_REPO/picom.conf" "$HOME/.config/picom/picom.conf"
install -Dm644 "$DWM_REPO/kitty.conf" "$HOME/.config/kitty/kitty.conf"
# For minimal X11 WMs, Flameshot >=14 needs its documented legacy X11 screenshot method.
# Leave existing user-customized Flameshot settings intact.
if [[ ! -e "$HOME/.config/flameshot/flameshot.ini" ]]; then
  install -Dm644 "$DWM_REPO/flameshot.ini" "$HOME/.config/flameshot/flameshot.ini"
else
  info 'Existing Flameshot settings kept (enable legacy X11 screenshot in Flameshot General settings if needed).'
fi
install -Dm644 "$DWM_REPO/gtk3.ini" "$HOME/.config/gtk-3.0/settings.ini"
install -Dm644 "$DWM_REPO/gtk3.ini" "$HOME/.config/gtk-4.0/settings.ini"
install -Dm644 "$DWM_REPO/cthulhu-fastfetch.fish" "$HOME/.config/fish/conf.d/cthulhu-fastfetch.fish"
install -Dm644 "$DWM_REPO/cthulhu-dwm.fish" "$HOME/.config/fish/conf.d/cthulhu-dwm.fish"
install -Dm644 "$DWM_REPO/xfce4-panel.xml" \
  "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
install -Dm644 "$REPO_DIR/Arch/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
install -Dm644 "$REPO_DIR/Arch/fastfetch/1.png" "$HOME/.config/fastfetch/1.png"
[[ -e "$HOME/.config/fastfetch/cthulhu-born" ]] || : > "$HOME/.config/fastfetch/cthulhu-born"
install -Dm644 "$REPO_DIR/Arch/wallpapers/1.png" "$DWM_DIR/wallpapers/1.png"
install -Dm644 "$REPO_DIR/Arch/wallpapers/2.png" "$DWM_DIR/wallpapers/2.png"
# Xinit requires this one managed file outside ~/.config/dwm.
printf '#!/bin/sh\nexec "$HOME/.config/dwm/start.sh"\n' > "$HOME/.xinitrc"
chmod 755 "$HOME/.xinitrc"
"$DWM_DIR/rebuild.sh"

info 'Installing yay from AUR only if missing, never as root'
if ! command -v yay >/dev/null 2>&1; then
  tmp_yay="$(mktemp -d /tmp/cthulhu-yay.XXXXXXXX)"
  trap 'rm -rf -- "$tmp_yay"' EXIT
  git clone --depth 1 https://aur.archlinux.org/yay.git "$tmp_yay/yay"
  (cd "$tmp_yay/yay" && makepkg -si)
  rm -rf -- "$tmp_yay"
  trap - EXIT
fi
info 'Installing Google Chrome from AUR'
yay -S --needed google-chrome

info 'Default applications (Chrome, PDFs, images, video)'
if [[ -f /usr/share/applications/google-chrome.desktop ]]; then
  desktop='google-chrome.desktop'
elif [[ -f /usr/share/applications/google-chrome-stable.desktop ]]; then
  desktop='google-chrome-stable.desktop'
else
  desktop=''
  warn 'Chrome desktop entry not found; MIME defaults must be checked later.'
fi
if [[ -n "$desktop" ]]; then
  xdg-mime default "$desktop" x-scheme-handler/http x-scheme-handler/https text/html application/pdf
fi
if [[ -f /usr/share/applications/feh.desktop ]]; then
  xdg-mime default feh.desktop image/png image/jpeg image/gif image/webp
fi
if [[ -f /usr/share/applications/vlc.desktop ]]; then
  xdg-mime default vlc.desktop video/mp4 video/x-matroska video/x-msvideo audio/mpeg audio/flac
fi

info 'Enabling requested system services (no boot, storage or fstab modifications)'
# Never disrupt an existing networkd-managed link or an active SSH setup.
if systemctl is-active --quiet systemd-networkd || systemctl is-enabled --quiet systemd-networkd; then
  warn 'systemd-networkd manages networking; leaving it untouched. Switch to NetworkManager manually after checking links.'
else
  sudo systemctl enable --now NetworkManager.service
fi
sudo systemctl enable --now fstrim.timer
sudo systemctl enable --now paccache.timer
sudo systemctl enable --now systemd-timesyncd.service
if [[ -n ${SSH_CONNECTION:-} || -n ${SSH_TTY:-} ]]; then
  warn 'SSH session detected: not activating UFW remotely (avoid cutting access).'
else
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw --force enable
fi
if ! systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service; then
  warn 'Could not enable PipeWire user units on this TTY; check systemctl --user after login.'
fi

info 'Setting fish as login shell (last step: next TTY1 login starts dwm)'
fishbin="$(command -v fish)"
[[ -n "$fishbin" && -x "$fishbin" ]] || fail 'fish binary not found.'
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$fishbin" ]]; then
  sudo usermod --shell "$fishbin" "$USER"
fi
printf '\nDONE: Re-login locally on TTY1 -> Xorg + dwm (automatic).\n'
printf 'Super+Enter kitty | Super+B Chrome | Super+D dmenu | Super+T Thunar\n'
printf 'Super+Q close | Super+F fullscreen | Super+mouse drag/resize | Print Flameshot\n'
printf 'No bar, no virtual workspace keys, no power/hibernation/partition changes.\n'
printf 'Verify DP-2 144 Hz natively after login; do not rely on Xwayland mode list.\n'
