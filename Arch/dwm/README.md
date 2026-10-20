# Cthulhu: Arch Minimal + dwm (Stage 1)

Kleines, nachvollziehbares Bootstrap für den ersten dwm-Login auf Cthulhu.
**Keine automatische Partitionierung, Formatierung oder Neuinstallation.**

## Archinstall
- Profil **Minimal**; normalen Benutzer **mit sudo** anlegen; Netzwerk aktivieren.
- Laufwerke anhand der *Seriennummer*, nicht anhand von /dev/nvme0n1, identifizieren:
  - **System / Installationsziel:** Crucial P310 **25024D54E112** (Endung **112**, „Feuerwehr“).
  - **NICHT überschreiben:** Homelab P310 **25024D548A53**, Samsung Games.Vol1 / Games.Vol2.
- Vorher wichtige Daten sichern. Bei Unsicherheit die drei Datenlaufwerke ausgeschaltet abklemmen.

## Nach dem ersten Arch-Login

```bash
git clone --depth 1 https://github.com/dennishilk/cthulhu.git
cd cthulhu/Arch/dwm
bash ./install.sh
```

Das Skript **nicht mit sudo** starten! Es verwendet sudo ausschließlich für offizielle Pakete, kompiliert yay als normaler Benutzer und installiert Chrome anschließend über yay.
Anschließend auf einem TTY:

```bash
startx
```

## Was wird installiert?
- Offiziell: Xorg, Xinit, C-Build-Werkzeuge + X11-Bibliotheken, Mesa, RADV, Kitty, Rofi, JetBrainsMono Nerd Font.
- Eigener dwm-Build **Tag 6.8** von https://git.suckless.org/dwm, ohne Patches.
- yay aus AUR (PKGBUILD wird gezeigt, mit Freigabe); Chrome aus AUR.
- **Nicht in Stage 1:** Steam/Multilib, PipeWire, OBS, DaVinci, Wallpaper, Picom, Fastfetch, 144/60-Hz-Monitorkonfiguration. Nach dem ersten erfolgreichen Login einzeln ergänzen.

## Wo liegen die dwm-Dateien?
- `~/.config/dwm/config.h` (anpassen)
- `~/.config/dwm/src/` (eigene lokale Quellen)
- `~/.config/dwm/bin/dwm` (ausführbare Datei)
- `~/.config/dwm/start.sh`, `rebuild.sh`, `status.sh`
- **Nur** `~/.xinitrc` außerhalb dieses Verzeichnisses, weil Xinit sie erwartet. Eine bestehende wird **niemals überschrieben**.
- Nichts wird mit `sudo make install` nach /usr/local kopiert, kein Display Manager, keine TTY-Autostart-Hacks.

## Shortcuts
- **Super+Enter** Kitty
- **Super+B** Chrome (zweimal Super+Enter wäre unmöglich)
- **Super+D** Rofi
- **Super+Q** Fenster schließen
- **Super+Shift+Q** dwm beenden
- **Super+1–9** Tags, **Super+J/K** Fensterfokus
- **Super+Maus links/rechts** Fenster bewegen / Größe ändern

## Änderungen an dwm
```bash
nano ~/.config/dwm/config.h
~/.config/dwm/rebuild.sh
```
Danach dwm beenden und mit `startx` neu starten.

## Grenzen
- Dies ist **nur ein Einstieg**, keine Garantie für einen fertigen Gaming-Desktop.
- Die richtigen X11-Ausgangsnamen und **144 Hz** prüfen wir nach der Installation mit xrandr.
- Ein Distro-Wechsel ist **kein** garantierter Fix für die RX-9060-XT-Hardlocks.
- Der Installer bewahrt existierende Konfigurationsdateien unter ~/.config/dwm; seine Wiederholung ersetzt sie nicht.
- Shell-Syntax lokal geprüft; realer Arch-Build und die Display-Konfiguration müssen auf Cthulhu getestet werden.
