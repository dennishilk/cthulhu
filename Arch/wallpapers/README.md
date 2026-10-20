# Cthulhu — Arch/dwm wallpapers

Place the two wallpaper images in this directory:

- `1.png` — primary display: `DP-1`, 3440×1440 @ 144 Hz, on the left.
- `2.png` — secondary display: 1920×1080 @ 60 Hz, on the right.

The dwm startup script should apply the corresponding image to each Xorg monitor using `feh`. Check the actual XRandR output ordering and secondary connector name on Cthulhu before writing the final startup command. The current images are supplied by the user; this folder does not contain them yet.
