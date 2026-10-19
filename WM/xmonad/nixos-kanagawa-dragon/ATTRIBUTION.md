# Provenance, publication corrections and media

Source: Dennis Hilk's private Cthulhu handoff, 19 October 2026. All supplied text
configurations, the empty age marker and media were inspected. The host-specific NixOS
file was reviewed, not republished as an installer. It contained a personal account,
host, mounted drive labels, kernel/boot choices, virtualization, Ledger support and a
stateVersion tied to the author's installation. No secrets or credentials were needed
for this portable setup. Existing repository history and assets are outside this new tree.

## Intentional changes from the supplied files

- XMonad's drag/focus/resize/float logic and keys are retained. Only the hard-coded
  monitor/wallpaper startup command moves into an editable helper with a safe default.
- NixOS desktop dependencies are separated from personal apps/gaming; no host mounts,
  bootloader, hostname, account creation, kernel or stateVersion is copied.
- Hack and Noto Sans are explicitly installed alongside the Nerd Fonts.
- GTK 4's `breeze_cursors` becomes `Bibata-Modern-Classic`, matching GTK 3 and XCURSOR.
- Fastfetch uses `~` instead of `/home/nebu`; three personal disk rows are omitted.
  Its original frame, image dimensions, system modules and formats remain. Each user
  creates a new marker; the original July 2022 timestamp is not distributed.
- The audio helper adds a read-only `status` command and stable decimal parsing.
  Xmobar consumes it to fix zero-padded percentages and show mute state.
- No invented Picom configuration: startup retains `picom --backend xrender --daemon`.
- The optional VS Code theme extension was verified against upstream `package.json`;
  an exact extension inventory was not present in the handoff.

## Theme licenses

- Kitty `current-theme.conf`: supplied attribution identifies Tommaso Laurenzi and
  MIT, upstream https://github.com/rebelot/kanagawa.nvim/. The full copyright/license
  is retained in `LICENSES/kanagawa-kitty-MIT.txt`; it is not replaced by Dennis's
  repository license.
- GTK theme: https://github.com/Fausto-Korpsvart/Kanagawa-GKT-Theme, audited commit
  `55ca4ba249eba21f861b9866b71ab41bb8930318`, archived 3 October 2026, GPL-3.0.
  No GTK theme assets are redistributed here. The guide fetches upstream source.
- Bibata, Breeze icons, fonts, programs and VS Code extensions retain their own
  package licenses. Installing them does not relicense them under this repository's MIT.

## Images and screenshot

Original wallpaper and Fastfetch PNG redistribution rights were not established.
None is included, resized, recolored or extracted into this setup. The historical
Fuji screenshots are not used as evidence of the final forest desktop.

Dennis supplied `2026-10-19_17-07-41.png` specifically for the article after the handoff.
It shows the actual current forest desktop with Kitty, Fastfetch and Xmobar. Privacy
review found the deliberately public handle/host and hardware information, no visible
credentials, personal messages or private documents. A compressed documentation copy
appears on the website. Screenshot credit: Dennis Hilk, 19 October 2026. The visible
wallpaper and Fastfetch artwork have separate, unverified original rights: this is not
a standalone download or an MIT license grant for those works. Readers supply their
own permitted artwork. Do not infer an artist identity from appearance.
