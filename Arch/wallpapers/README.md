# Cthulhu — Arch/dwm wallpapers

The two supplied images belong to these monitors:

- `1.png` — left main monitor, **3440×1440 at target 144 Hz**, kernel DRM connector `DP-2` (`card1-DP-2`).
- `2.png` — right secondary monitor, **1920×1080 at target 60 Hz**, kernel DRM connector `HDMI-A-1` (`card1-HDMI-A-1`).

Verified on Cthulhu on 2026-10-20 from `/sys/class/drm/card*-*/status`: `DP-2` and `HDMI-A-1` connected; `DP-1` disconnected.

**Note:** The current `xrandr` output was from Xwayland and only listed ~59.94 Hz for the main display. Do not treat that as the native Xorg refresh rate. Confirm connector names, available 144 Hz mode and left/right ordering under native Xorg before locking in the final `xrandr` setup.

The dwm startup script should assign `1.png` and `2.png` to their respective monitors with `feh`, using the Xorg output order confirmed at setup time.
