# Validation scope — 19 October 2026

- Local: 12 Python behavior tests for fresh installation, idempotence/marker retention,
  full-set conflict detection, symlink refusal, XDG precedence, audio status/actions,
  single/dual/no-wallpaper startup and portable Fastfetch configuration.
- Generated English/German documentation checked byte-for-byte against the source
  inventory. All home files are complete; original third-party PNGs are excluded.
- CI definition: four NixOS evaluations (Plasma preparation, explicit removal, Minimal,
  optional applications), ShellCheck, Haskell typechecking of XMonad and Xmobar.
  Pinned nixpkgs revision: `8ce73368d1efd4d657e9064d29b144a52046b4e8` (26.05 branch).
  Consult the workflow result for the actual execution status; the definition itself
  is not a claim that checks have passed.
- Existing backup/restore code and old snapshots are unchanged; CLI read-only listing
  and shell syntax checks are appropriate regression checks. No restore operation is
  executed against real files.

The editing environment is not NixOS and has no full graphical XMonad session. Neither
evaluation nor compilation proves physical monitor switching, drag/retiling, GTK 4
application compatibility, Polkit dialogs, USB mounting, image protocol rendering,
audio hardware, OBS capture or Steam compatibility. The owner's source setup was
reported working and the final screenshot is real; a fresh-install hardware test was
not performed by the publishing worker.
