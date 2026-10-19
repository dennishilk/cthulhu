# Cthulhu Dragon — NixOS + XMonad

Complete desktop reproduction from Dennis Hilk's working configuration, 19 October 2026.
Independent of the existing Cthulhu backup/restore CLI and historical snapshots.

**[English: complete installation and every configuration file](INSTALL.en.md)**

**[Deutsch: vollständige Installation und sämtliche Konfigurationen](INSTALL.de.md)**

Both documents cover the Plasma-first route and an installed NixOS Minimal system.
Both finish with TTY login → `startx` → XMonad. The installer does not partition disks,
replace hardware configuration, create accounts or silently overwrite user files.

| Location | Purpose |
| --- | --- |
| `nixos/desktop.nix` | Complete opt-in desktop module, no personal bootloader/disks/stateVersion |
| `nixos/cthulhu-local.nix` | Reader's account/layout and explicit standalone/app switches |
| `home/` | Complete XMonad, Xmobar, Kitty, GTK, Rofi, Dunst, audio, Fastfetch and Code files |
| `scripts/install-user.sh` | Conservative home-file installer with full conflict preflight |
| `docs/guide.en.md`, `docs/guide.de.md` | Equivalent authoring sources |
| `docs/files.json` | Configuration inventory; every file has GitHub and raw links in both guides |
| `tests/` | Installer/helper behavior, NixOS evaluation and Haskell compilation checks |
| `ATTRIBUTION.md`, `LICENSES/` | Source audit, image policy and separate third-party licenses |

Set `user` to your existing login before rebuilding. Keep `standalone=false` on the
Plasma route until the independent TTY/startx test succeeds. `personalApps` and `gaming`
are opt-in; see the guide for the shortcuts that need them.

Wallpapers: supply `~/Bilder/wallpaper/1.png` for the first monitor and `2.png` for the
second. One monitor needs only `1.png`. Supply your own Fastfetch image separately at
`~/.config/fastfetch/1.png`. No original artwork or old age marker is bundled.

The owner's current real screenshot is displayed with the bilingual website tutorial;
it is documentation, not an artwork asset pack. See attribution before reusing images.

## Maintain and verify

From this directory:

```sh
python3 scripts/render-docs.py
python3 scripts/render-docs.py --check
python3 tests/test_setup.py
nix-instantiate --eval --strict --json tests/eval.nix
nix-shell tests/shell.nix --run 'bash tests/check.sh'
```

CI records its nixpkgs revision in `.github/workflows/kanagawa-dragon.yml` at repository
root. The evaluation fixtures use fake disks and a test account; never import them on a
real machine. Compilation and evaluation do not establish a working physical desktop.
See [VALIDATION.md](VALIDATION.md) for the scope and remaining hardware checks.
