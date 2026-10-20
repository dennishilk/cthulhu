#!/bin/sh
# Xorg session started from TTY1 with startx; no display manager or bar.
set -u
export XDG_CURRENT_DESKTOP=dwm
export XDG_SESSION_DESKTOP=dwm
DWM_DIR="$HOME/.config/dwm"
DWM_BIN="$HOME/.local/bin/dwm"
[ -x "$DWM_BIN" ] || { echo "dwm binary missing: $DWM_BIN" >&2; exit 1; }

# GUI helpers need access to the session DBus activation environment.
command -v dbus-update-activation-environment >/dev/null 2>&1 &&
  dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP >/dev/null 2>&1 || :

setxkbmap -layout de || echo 'Warning: could not set German X11 keyboard' >&2
numlockx on || echo 'Warning: could not activate NumLock' >&2
xset s off
xset -dpms
xset s noblank

# Require both real outputs and a 144 Hz native X11 mode before applying.
# xrandr under Xwayland is not authoritative; verify after initial native Xorg boot.
if xrandr --query | grep -q '^DP-2 connected' && xrandr --query | grep -q '^HDMI-1 connected'; then
  if xrandr --query | awk '
    /^DP-2 connected/ { dp=1; next }
    /^[^[:space:]]/ { dp=0 }
    dp && /3440x1440/ && /14[34][.]/ { found=1 }
    END { exit !found }
  '; then
    xrandr --output DP-2 --primary --mode 3440x1440 --rate 144 --pos 0x0 \
           --output HDMI-1 --mode 1920x1080 --rate 60 --pos 3440x180 ||
      echo 'Warning: could not apply 144/60 Hz XRandR layout; verify modes manually.' >&2
  else
    echo 'Warning: DP-2 has no visible 144 Hz native mode; keeping active resolution.' >&2
  fi
else
  echo 'Warning: expected DP-2 and HDMI-1 not both detected; keeping Xorg layout.' >&2
fi

if [ -r "$DWM_DIR/wallpapers/1.png" ] && [ -r "$DWM_DIR/wallpapers/2.png" ]; then
  feh --no-fehbg --bg-fill "$DWM_DIR/wallpapers/1.png" "$DWM_DIR/wallpapers/2.png" || :
fi

# Clipman standalone: clipboard retained after source closes; no history save on quit.
xfce4-clipman >/dev/null 2>&1 &
# No bar, panels, tray, or visible launch applications.
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 >/dev/null 2>&1 &
picom --config "$HOME/.config/picom/picom.conf" >/dev/null 2>&1 &
exec "$DWM_BIN"
