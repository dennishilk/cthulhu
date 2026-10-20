# Cthulhu — Arch Linux + dwm 6.8

A minimal, two-monitor daily-driver desktop built from the official **stable dwm 6.8** tag, with small local source adjustments. The public repository is the source of truth for these desktop files.

## Hard boundary: Arch base belongs to you

You install Arch, `linux`, firmware, GRUB, Btrfs, Snapper, snap-pac, grub-btrfs, `multilib`, zram and game-disk mounts yourself. The bootstrap **does not** partition, format, mount, or edit `/etc/fstab`, GRUB, EFI, Snapper or your SSH keys. The **only** pacman.conf changes made are `Color` and `ILoveCandy` within `[options]` (after inspecting the section and backing up the original); `[multilib]` remains as you configured it. Leave your existing game SSDs untouched. Confirm the installation NVMe by its serial number before installing Arch.

The bootstrap requires a working Arch installation, non-root user `nebu` with sudo, online pacman mirrors, the enabled and synced `multilib` repository, git and internet access. It performs a full normal pacman update; finish the base setup first. It uses official Arch repositories and installs `yay`/Google Chrome from AUR (AUR build scripts are third-party code; review them if you want). If anything fails, it stops rather than silently continuing.

## Start, from the installed Arch TTY

Run these *one at a time*, checking each result:

```sh
git clone https://github.com/dennishilk/cthulhu.git
```

```sh
cd cthulhu/Arch/dwm
```

```sh
bash ./install.sh
```

**Do not use sudo to launch install.sh.** Normal sudo/pacman/AUR prompts are expected. When finished, log out and log back in as `nebu` on **local TTY1**. Fish auto-runs `startx`, which starts dwm. SSH sessions never autostart dwm. No graphical login manager. A re-run updates the desktop files managed by this script; it does not touch unrelated configs. It does manage `~/.xinitrc` and your login shell.

## Sources and configuration locations

- `~/.config/dwm/src/` — unmodified upstream git HEAD pinned to tag 6.8 with local changes in working tree only; `patch_dwm.py` is idempotent.
- `~/.config/dwm/config.h`, `patch_dwm.py`, `start.sh`, `rebuild.sh` — repo-managed dwm files.
- `~/.local/bin/dwm` — locally compiled binary, never `/usr/local/bin/dwm`.
- `~/.config/dwm/wallpapers/{1,2}.png` — from `Arch/wallpapers/`, `feh --bg-fill`.
- `~/.config/kitty/kitty.conf` — JetBrains Mono Nerd Font 12pt, `background_opacity 0.85`.
- `~/.config/picom/picom.conf` — glx, subtle shadows, no blur, no fades, no VSync, fullscreen unredirect when possible.
- `~/.config/flameshot/flameshot.ini` — created only if absent; default enables the documented legacy X11 screenshot method for dwm. Existing user configuration is preserved.
- `/etc/pacman.conf` — safely enables `Color` and `ILoveCandy` only in `[options]`, keeping other sections untouched; creates a timestamped backup if changed.
- `~/.config/fastfetch/{config.jsonc,1.png,cthulhu-born}` — existing custom theme, `I use Arch btw`; on each interactive kitty fish start.
- `~/.config/fish/conf.d/cthulhu-*.fish` — TTY1 auto-start and kitty-only Fastfetch.
- `~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml` — Clipboard 'save on quit' off (no panel is launched).

## Key bindings

| Binding | Action |
|---|---|
| `Super+Enter` | kitty (fish + Fastfetch) |
| `Super+B` | Google Chrome |
| `Super+D` | original `dmenu_run` at the top of current monitor |
| `Super+T` | Thunar |
| `Super+Q` | Close focused window |
| `Super+F` | Real EWMH fullscreen toggle |
| `Super+left mouse` | Move a window; previously tiled windows return to tiling on other monitor |
| `Super+right mouse` | Resize in floating mode |
| `Print` | Flameshot interactive screenshot |
| Hardware volume keys | `wpctl` +5%, -5%, mute |

No tag switching, keyboard focus cycling, minimize shortcut, dwm quit shortcut, status bar, display manager, automatic screen lock, compositor blur or fading. Default layout: one tag per monitor; master left, stack right; 50/50 when two tiled clients; 12px outer and 8px inner gaps; border 0. New windows take focus, then mouse-over changes focus. Dialogs float as upstream dwm normally does.

To rebuild after changing config:

```sh
~/.config/dwm/rebuild.sh
```

Restart your Xorg session to load the new binary. There is deliberately no dwm quit shortcut; use a deliberate command/process exit instead.

## Monitors (verify after native Xorg login)

- `DP-2` left, 3440×1440 **target 144 Hz**, image `1.png`.
- `HDMI-A-1` right, 1920×1080 **target 60 Hz**, image `2.png`.
- Right monitor vertically centered → X position 3440, Y offset 180.

DRM status was verified while the old desktop ran Wayland: `DP-2` and `HDMI-A-1` connected, `DP-1` disconnected. The prior Xwayland `xrandr` report only listed about 60 Hz; **do not interpret that as native Xorg capability**. The startup script applies the expected layout only if it detects a 144 Hz mode on DP-2; otherwise it leaves the current mode and warns. Verify native modes and `feh` image ordering on the installed system. Picom behavior at mixed refresh rates and AMD/RDNA4 Vulkan stability also require real hardware tests.

## Other desktop components

- Xorg, Xinit, dmenu, Thunar + Tumbler + GVfs + udisks2 + Polkit, Mousepad, **nano**, Xarchiver, VLC, feh, Flameshot, numlockx, btop; **dunst** runs silently for system notifications.
- xfce4-clipman standalone retains copied text after the source window closes, with disk persistence disabled; it does not launch an XFCE panel.
- PipeWire, WirePlumber and `wpctl` volume keys. No pavucontrol.
- NetworkManager, UFW incoming deny / outgoing allow, weekly SSD TRIM, weekly pacman cache cleanup, automatic time sync. Existing systemd-networkd links are not changed and UFW is not activated in an SSH session.
- Mesa/RADV (64/32-bit), Vulkan loaders (64/32-bit), vulkan-tools. Kernel and firmware stay part of the base Arch install.
- No Bluetooth, CUPS, extra PDF viewer, extra image viewer, standalone GUI search or desktop locker.

Steam, Lutris and OBS intentionally come **after** native Xorg, audio and 64/32-bit Vulkan checks. This Linux reinstallation is not a proven fix for earlier RX 9060 XT hardlocks.

## Testing limitations

Scripts and configuration can be syntax-checked without Arch. Full pacman/AUR installation, actual upstream dwm compilation and behavior, Xorg and 144/60 Hz layout, clipboard lifetime, terminal logo rendering and gaming require testing on Cthulhu after install. Do not assume these are verified merely because the files are committed.
