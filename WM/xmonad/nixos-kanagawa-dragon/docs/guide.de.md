# NixOS mit XMonad: Mein kompletter Kanagawa-Dragon-Desktop zum Nachbauen

Cthulhu ist mein Linux-Arbeitsrechner: Ryzen 7 5800X3D, Radeon RX 9060 XT und zwei ziemlich unterschiedliche Monitore. Bei diesem Neuaufbau bin ich zu XMonad zurückgekehrt. Ich wollte einen Desktop, bei dem ich Fensteranordnung, Launcher, Benachrichtigungen und Startvorgang anhand weniger Dateien nachvollziehen kann. Kanagawa Dragon verbindet diese Teile: fast schwarze Flächen, warme Schriftfarben und zurückhaltende grüne Akzente.

Ein Tiling Window Manager ordnet Fenster an, statt mich jede neue Anwendung von Hand platzieren zu lassen. Auf die Maus verzichte ich deshalb nicht. Diese Konfiguration aktiviert den Monitor unter dem Zeiger, erlaubt das Verändern von Kachelgrenzen mit der Maus und lässt Fenster nach dem Ziehen auf einen anderen Monitor wieder einrasten. Diese Anleitung dokumentiert den daraus entstandenen Desktop anhand meiner funktionierenden Dateien vom 19. Oktober 2026.

Mit Plasma verschwindet dessen vollständige Desktop-Sitzung aus diesem Startweg; XMonad, Xmobar, Dunst und Picom übernehmen konkrete Aufgaben. Das ist eine Entscheidung für einen nachvollziehbaren Arbeitsablauf. RAM-Ersparnis oder bessere Spieleleistung habe ich nicht gemessen. Grundlage bleibt X11, auch für OBS und Steam. Eine Kompatibilitätszusage für jedes Spiel, jede GPU oder jede Aufnahmemethode lässt sich daraus nicht ableiten.

## Den Installationsweg wählen

Beide Wege beginnen mit einem bereits installierten, startfähigen NixOS und führen zum selben Desktop-Modul und denselben Benutzerdateien. Das ist keine Partitionierungsanleitung. Bootloader, Netzwerk, vorhandenes Benutzerkonto, Hostname, Sprache, Laufwerkseinbindungen, hardware-configuration.nix und system.stateVersion bleiben diejenigen der eigenen Installation. Das Desktop-Modul enthält bewusst weder meine Laufwerksbezeichnungen noch meine Kernel-Auswahl.

| Weg | Ausgangspunkt | Erster grafischer Test | Endzustand |
| --- | --- | --- | --- |
| A — Empfehlung für Einsteiger | Grafische NixOS-Installation mit Plasma und funktionierendem Browser | XMonad in SDDM wählen, anschließend startx gesondert aus einer TTY prüfen | TTY-Anmeldung → startx → XMonad |
| B — für Erfahrene | Erfolgreich installiertes NixOS Minimal mit Netzwerk und TTY-Anmeldung | startx direkt an der lokalen TTY | TTY-Anmeldung → startx → XMonad |

Die Beispiele verwenden die Optionsstruktur von NixOS 26.05. CI wertet eine festgehaltene nixpkgs-Revision aus; das prüft diese Beispiele und pinnt nicht die eigene Installation. Der vorhandene Channel beziehungsweise die eigenen Flake-Inputs bleiben erhalten. Neuere Revisionen können Anpassungen erfordern. Bei Flakes müssen neu importierte Dateien im getrackten Konfigurationsverzeichnis liegen, bevor mit dem bisherigen --flake-Ziel gebaut wird.

## Weg A: in Plasma vorbereiten

NixOS mit dem grafischen Installer installieren und Plasma auswählen. In die installierte Umgebung neu starten, Netzwerk prüfen und diese Anleitung in Firefox öffnen. Daneben Konsole starten. Die folgenden Befehle funktionieren in Bash und Fish; die Blöcke der Reihe nach einzeln ausführen. Vorhandene Verzeichnisse werden nicht als entbehrlich vorausgesetzt.

Git vorübergehend bereitstellen und das echte Repository klonen. Falls ~/cthulhu schon existiert, den vorhandenen Checkout prüfen, statt darüber zu klonen.

```sh
nix-shell -p git
```

```sh
git clone --single-branch --branch main https://github.com/dennishilk/cthulhu.git "$HOME/cthulhu"
```

```sh
cd "$HOME/cthulhu/WM/xmonad/nixos-kanagawa-dragon"
```

Plasma und SDDM während der Vorbereitung aktiviert lassen. standalone noch nicht auf true setzen. Mit der gemeinsamen Installation fortfahren und nach dem ersten Rebuild zum Abschnitt über den Wechsel zurückkehren.

## Weg B: aus NixOS Minimal vorbereiten

Die Minimal-Installation muss bereits von der Festplatte starten, Netzwerkzugriff haben und eine Anmeldung mit dem normalen Benutzer an einer lokalen TTY erlauben. Das Konto benötigt sudo-Rechte. Eine SSH-Verbindung kann beim Bearbeiten helfen; startx gehört an die lokale virtuelle Konsole. Für diesen Weg muss Plasma zu keinem Zeitpunkt installiert werden.

Die temporäre Shell stellt Git und Nano auch auf einer kleinen Installation bereit. Wer bereits Fish verwendet, landet mit nix-shell normalerweise in einer Bash-Untershell; exit führt zurück zu Fish.

```sh
nix-shell -p git nano
```

```sh
git clone --single-branch --branch main https://github.com/dennishilk/cthulhu.git "$HOME/cthulhu"
```

```sh
cd "$HOME/cthulhu/WM/xmonad/nixos-kanagawa-dragon"
```

Danach dieselben Dateien und Befehle verwenden. In cthulhu-local.nix standalone sofort auf true setzen: Auf diesem Weg ist keine Plasma-Installation zu erhalten. Nach dem ersten erfolgreichen Rebuild neu starten, damit Fish, Gruppen und Sitzungsvariablen aus einer frischen Anmeldung stammen. Anschließend startx als normaler Benutzer ausführen.

## Gemeinsame Installation: System- und Benutzerdateien

Vor dem Bearbeiten /etc/nixos sichern. Das datierte Ziel darf noch nicht existieren; bei einer Wiederholung einen anderen Zusatz wählen. Es entstehen Kopien, keine Ersatzdateien für die generierte Hardwarekonfiguration.

```sh
sudo cp -a /etc/nixos "/etc/nixos.before-cthulhu-$(date +%Y%m%d-%H%M%S)"
```

Zunächst prüfen, ob die beiden Zieldateien bereits existieren. Falls ja, vergleichen und einen neuen Namen wählen oder die Inhalte bewusst zusammenführen. GNU cp -n überspringt vorhandene Ziele, statt sie zu überschreiben; anschließend prüfen, welche Dateien tatsächlich installiert wurden.

```sh
ls -l /etc/nixos/desktop.nix /etc/nixos/cthulhu-local.nix
```

Auf einer frischen Installation sind Fehlermeldungen über fehlende Dateien an dieser Stelle erwartbar. Module kopieren und die lokalen Optionen öffnen:

```sh
sudo cp -n nixos/desktop.nix nixos/cthulhu-local.nix /etc/nixos/
```

```sh
sudo nano /etc/nixos/cthulhu-local.nix
```

YOUR_LOGIN durch den vorhandenen Benutzernamen ersetzen; whoami zeigt ihn an. Das eigene X11-Tastaturlayout wählen. Weg A behält standalone=false, Weg B verwendet true. personalApps=true installiert Chrome, VS Code, OBS und Kdenlive für die entsprechenden Tastenkürzel. Bei false bleiben Firefox und die wesentlichen Desktop-Werkzeuge verfügbar; M-b/M-o/M-v benötigen dann entweder die optionalen Pakete oder eigene Ersatzbefehle. gaming=true ergänzt Steam, Lutris und 32-Bit-Grafik-/Audiounterstützung. Beide optionalen Schalter erlauben unfreie Pakete. Virtualisierung, Ledger-Unterstützung, Druckdienste und meine persönlichen Laufwerke sind keine Voraussetzung.

```sh
whoami
```

```sh
sudo nano /etc/nixos/configuration.nix
```

./cthulhu-local.nix zur VORHANDENEN imports-Liste hinzufügen. Wenn bisher ausschließlich die generierte Hardwaredatei importiert wird, sieht die Liste anschließend so aus. Weitere Imports und alle sonstigen Einstellungen der eigenen Datei erhalten:

```nix
imports = [ ./hardware-configuration.nix ./cthulhu-local.nix ];
```

Keine neue system.stateVersion aus diesem Artikel übernehmen. Der für die eigene Installation erzeugte Wert bleibt stehen. Auch die eigene Treiberkonfiguration bleibt erhalten: Das Modul aktiviert den Grafikunterbau, ersetzt aber keine NVIDIA-Einrichtung und wählt keinen neuen Kernel. Bei kollidierenden Optionen die in der Fehlermeldung genannten Dateien lesen und genau diese Einstellung zusammenführen. Nicht die vollständige Konfiguration eines fremden Rechners darüberkopieren.

Das Benutzer-Installationsskript vor dem Ausführen lesen und ohne sudo starten:

```sh
less scripts/install-user.sh
```

```sh
bash scripts/install-user.sh
```

Es kopiert ausschließlich die veröffentlichten home/-Dateien, macht die Helfer ausführbar und erstellt einmalig die eigene Fastfetch-Altersmarkierung. Vorher prüft es den gesamten Satz und verweigert abweichende vorhandene Dateien, Symlinks an Zielpfaden und ein vorhandenes ~/.config/xmonad, das Vorrang vor ~/.xmonad hätte. Es entfernt weder Plasma noch bearbeitet es /etc/nixos. Bei einem Konflikt die genannte Datei sichern, vergleichen und bewusst beiseitelegen. Ein identischer erneuter Lauf verändert weder Inhalte noch den Zeitstempel der Markierung. Nach eigenen Anpassungen meldet ein erneuter Lauf den Unterschied, statt die Änderungen zurückzusetzen.

Das System zunächst bauen und erst danach aktivieren. Für eine Channel-basierte Installation:

```sh
sudo nixos-rebuild build
```

```sh
sudo nixos-rebuild switch
```

Bei einer Flake-Konfiguration den eigenen bisherigen --flake-Parameter verwenden. Änderungen an NixOS-Diensten und Paketen benötigen einen Rebuild. Das Bearbeiten einer Benutzerdatei benötigt keinen NixOS-Rebuild.

## Kanagawa Dragon: GTK-Theme installieren

Die GTK-Quelle ist [Fausto-Korpsvart/Kanagawa-GKT-Theme](https://github.com/Fausto-Korpsvart/Kanagawa-GKT-Theme). Das Projekt wurde am 3. Oktober 2026 archiviert und steht unter GPL-3.0. Der Installer benötigt sassc; Upstream nennt zusätzlich Murrine und gnome-themes-extra für ältere GTK-Darstellung. Das Desktop-Modul stellt diese Pakete bereit. Die Theme-Dateien werden aus der Upstream-Quelle bezogen und nicht in dieses Repository eingebettet.

```sh
mkdir -p "$HOME/.local/share"
```

```sh
git clone https://github.com/Fausto-Korpsvart/Kanagawa-GKT-Theme.git "$HOME/.local/share/kanagawa-gtk-source"
```

Für diesen Nachbau die geprüfte Upstream-Revision verwenden. Einen vorhandenen Quell-Checkout vor dem Wechsel der Revision prüfen.

```sh
git -C "$HOME/.local/share/kanagawa-gtk-source" checkout --detach 55ca4ba249eba21f861b9866b71ab41bb8930318
```

Als normaler Benutzer ausführen. Der Upstream-Installer ersetzt vorhandene Theme-Verzeichnisse gleichen Namens; ein selbst angepasstes Kanagawa-Theme vorher sichern. Diesen Befehl habe ich für meinen Desktop verwendet:

```sh
nix-shell -p sassc --run 'bash ~/.local/share/kanagawa-gtk-source/themes/install.sh -n Kanagawa -t green -c dark --tweaks dragon'
```

Das ausdrückliche -n Kanagawa legt den Theme-Namen fest. Beim Einrichten entstand ohne diesen Parameter durch die Nix-Shell-Umgebung ein unerwünschter Name. Prüfen, dass ~/.themes/Kanagawa-Green-Dark-Dragon existiert. GTK-3-Anwendungen wie Thunar und Mousepad lesen settings.ini beim Start; nach Theme-Änderungen schließen und neu öffnen. Ein Einstellungsdialog aus Plasma oder GNOME ist nicht erforderlich.

Die GTK-4-Datei verwendet jetzt ebenfalls Bibata-Modern-Classic; im privaten Snapshot stand noch breeze_cursors. Das ist eine bewusste Korrektur für die Veröffentlichung. Ein Theme-Name allein garantiert keine GTK-4- oder libadwaita-Darstellung. Upstream bietet gtk-4.0-CSS/Assets und den Schalter -l an; dieser ersetzt allerdings vorhandene GTK-4-CSS-Verknüpfungen. Wir aktivieren ihn nicht automatisch. Anwendungen mit libadwaita oder eigenen Sandbox-Laufzeitumgebungen können ihre eigene Darstellung behalten. GTK-3-Thunar und Mousepad bilden den verlässlichen Kern dieses Nachbaus; globale GTK_THEME-Overrides sind dafür unnötig.

Die Palette verteilt konkrete Aufgaben: #181616 ist die dunkle Basis, #c5c9c5 die Schrift, #87a987 der Fokus-/Auswahlakzent, #393836 der inaktive Rahmen und #c4746e die kritische Benachrichtigung. Kitty verwendet eine echte, mit Herkunft versehene Kanagawa-Dragon-Palettendatei. GTK, Rofi, Dunst, Xmobar und XMonad erhalten passende Einstellungen; keine einzelne Anwendung färbt automatisch die anderen mit ein.

## Monitore, Wallpaper und Mauszeiger

In der ersten grafischen XMonad-Sitzung die eigenen Ausgänge prüfen:

```sh
xrandr
```

Mein erster Monitor hängt an DP-2, mit 3440×1440 bei 144 Hz. Rechts daneben steht HDMI-1 mit 1920×1080 bei 60 Hz. Anschlussnamen und Modi hängen von der Hardware ab. Die veröffentlichte monitors.sh startet mit configure_layout=false und erhält die vorhandene Anordnung. Namen, unterstützte Modi und Positionen anpassen, bevor der Schalter auf true gesetzt wird. Mit nur einem Monitor kann false erhalten bleiben, um Xorgs funktionierende Anordnung zu verwenden; alternativ den Zwei-Ausgänge-Befehl durch einen Befehl für den eigenen einzelnen Ausgang ersetzen.

```sh
nano "$HOME/.config/cthulhu/monitors.sh"
```

Eigene Bilder verwenden. 1.png ist das Wallpaper meines ersten Monitors, 2.png das meines zweiten. Bei einem einzigen Monitor reicht 1.png. Der Helfer übergibt nur vorhandene Dateien; ohne Bilder setzt er einen einfarbigen Dragon-Hintergrund. feh verwendet die Xinerama-Monitorreihenfolge. Falls die Bilder vertauscht erscheinen, diese mit feh --list-xinerama prüfen und die Dateireihenfolge tauschen. --primary definiert fehs Reihenfolge nicht auf jeder Konfiguration neu.

```sh
mkdir -p "$HOME/Bilder/wallpaper"
```

Die gewählten PNGs mit Thunar oder cp dorthin kopieren und diese Dateinamen verwenden. Beispiel für ein zuvor unter ~/Pictures/my-wallpaper.png abgelegtes Bild:

```sh
cp -n "$HOME/Pictures/my-wallpaper.png" "$HOME/Bilder/wallpaper/1.png"
```

Direkt aus einem X11-Terminal anwenden:

```sh
bash "$HOME/.config/cthulhu/monitors.sh"
```

feh --bg-max skaliert das Bild vollständig hinein, ohne es zuzuschneiden; dabei können Ränder entstehen. --bg-fill füllt den Bildschirm und schneidet überstehende Bereiche bei abweichendem Seitenverhältnis ab. Mein Start verwendet --bg-max. Der Verzeichnisname Bilder ist lediglich die Konvention dieser Konfiguration und setzt keine deutsche Locale voraus. Wer einen anderen Pfad bevorzugt, passt den Helfer an.

Bibata-Modern-Classic ist der schwarze Mauszeiger. NixOS exportiert XCURSOR_THEME und XCURSOR_SIZE=24 bei der Anmeldung. Beide GTK-Einstellungsdateien stimmen damit überein; xsetroot -cursor_name left_ptr initialisiert den Zeiger auf dem Root-Fenster. Das Paket stellt das Cursor-Theme bereit. Geänderte Sitzungsvariablen benötigen eine frische Anmeldung mit neuer startx-Sitzung; ein XMonad-Neustart allein ersetzt dessen geerbte Umgebung nicht.

## Weg A: testen, dann Plasma entfernen

Nach der Vorbereitung aus Plasma abmelden und in SDDM die XMonad-Sitzung wählen. Kitty (Super+Return), Rofi, Thunar, Dialogfenster, Vollbild und Monitoranordnung testen. Damit wird der Window Manager geprüft, während die grafische Anmeldung weiter einen Rückweg anbietet.

Anschließend aus XMonad abmelden. Mit Strg+Alt+F3 zu einer TTY wechseln und als normaler Benutzer anmelden. Von dort SDDM vorübergehend stoppen, nachdem alle Arbeiten in der grafischen Sitzung gespeichert wurden:

```sh
sudo systemctl stop display-manager
```

Die generierte systemweite xinitrc wird nur verwendet, wenn ~/.xinitrc fehlt und XINITRC nicht gesetzt ist. Eine vorhandene Datei prüfen und bei gewünschter Nutzung des generierten Skripts in eine eigene Sicherung verschieben. Keine zusätzliche minimale Datei mit exec xmonad anlegen: Sie umgeht die verwaltete Sitzungsinitialisierung.

Bash, falls XINITRC gesetzt war:

```bash
unset XINITRC
```

Fish, falls XINITRC gesetzt war:

```fish
set -e XINITRC
```

```sh
startx
```

Weder sudo startx verwenden noch innerhalb eines bereits laufenden Desktop-Terminals starten. Polkit-Agent, USB-Einbindung, Benachrichtigungen, Audio und das Öffnen von Dateien prüfen. In einem XMonad-Terminal:

```sh
systemctl --user status nixos-fake-graphical-session.target cthulhu-polkit.service
```

Falls dieser Test scheitert, XMonad mit Super+Shift+Q verlassen und den Loginmanager von der TTY aus wieder starten:

```sh
sudo systemctl start display-manager
```

Erst nach dem erfolgreichen Standalone-Test /etc/nixos/cthulhu-local.nix bearbeiten und standalone=true setzen. Arbeit speichern, XMonad verlassen, von der TTY neu bauen und neu starten. Dieser ausdrückliche Schalter überschreibt die Aktivierung von Plasma/SDDM und wählt multi-user.target. Er löscht keine Plasma-Dateien oder Benutzerdaten.

```sh
sudo nano /etc/nixos/cthulhu-local.nix
```

```sh
sudo nixos-rebuild build
```

```sh
sudo nixos-rebuild switch
```

```sh
sudo reboot
```

An der Konsole anmelden und startx ausführen. Weg B kommt nach seinem ersten Rebuild und Neustart genau hier an; die SDDM-Test- und Entfernungsschritte entfallen dort vollständig.

## Was startx verwaltet

NixOS erzeugt /etc/X11/xinit/xinitrc aus der aktivierten XMonad-Sitzung. Unsere extraCommands kennzeichnen die Sitzung als XMonad und importieren Display-/Desktop-Variablen in D-Bus und systemd. Das erzeugte Skript importiert DISPLAY und XDG_SESSION_ID, startet nixos-fake-graphical-session.target, führt die XMonad-Sitzung aus, wartet auf deren Ende und stoppt anschließend das Target. Der Polkit-Agent folgt diesem Target. UDisks2, GVfs und das GTK-Portal stellen die ergänzenden Desktop-Dienste bereit.

Der Target-Name ist ein Implementierungsdetail von NixOS, kein zusätzlich zu installierender Desktop. Keine unabhängige weitere D-Bus-Sitzung und keinen zweiten Picom-/Polkit-Prozess darüber starten. Das vollständige Modul weiter unten enthält unsere Anpassung; die erzeugte xinitrc bleibt unter NixOS-Verwaltung. Das tatsächliche Ergebnis der eigenen Installation lässt sich so ansehen:

```sh
cat /etc/X11/xinit/xinitrc
```

Das GTK-Portal übernimmt unterstützte Desktop-Anfragen wie Dateidialoge. Es liefert keinen Wayland-Screencast-Backend. OBS-Aufnahmen müssen in diesem X11-Setup mit den verfügbaren X11-Quellen, etwa XSHM, und den tatsächlichen Anwendungsberechtigungen geprüft werden.

## XMonad: Maus, Tiling und Vollbild

Die vollständige Haskell-Konfiguration steht in der Dateisammlung weiter unten. Super/Windows ist Mod4. focusFollowsMouse behandelt Fenster; focusOnMouseMove aus xmonad-contrib aktualisiert den Fokus beim Bewegen des Zeigers. Der eigene MotionEvent-Hook für das Root-Fenster prüft außerdem Bildschirmrechtecke, wenn der Zeiger über leerer Desktop-Fläche liegt. Er aktiviert den Workspace, der auf diesem Monitor gerade sichtbar ist. Deshalb hängt der Monitorfokus nicht von einem Klick auf ein Fenster ab.

Mit Super und linkem Ziehen lässt mouseMoveWindow das Fenster vorübergehend schweben. afterDrag plant die abschließende Aktion nach dem Loslassen ein. queryPointer und pointScreen ermitteln den Zielmonitor; W.shiftWin verschiebt das Fenster auf dessen sichtbaren Workspace und W.sink fügt es wieder ins Tiling ein. Diese Logik bleibt aus meiner funktionierenden Konfiguration erhalten. Auch ein vorher bewusst schwebendes Fenster wird mit dieser Geste beim Ablegen eingekachelt. Super mit rechtem Ziehen verwendet dagegen das gewöhnliche freie Größenändern; Super+F bringt das Fenster wieder ins Tiling zurück.

MouseResizableTile und seine gespiegelte Variante stellen verschiebbare Kacheltrenner bereit. An den Griffen zwischen den gekachelten Fenstern ziehen, um deren Proportionen zu verändern. Ein frei schwebendes Rechteck zu skalieren ist ein anderer Vorgang. spacingRaw ergänzt außen 8 Pixel und um Fenster 6 Pixel Abstand; avoidStruts reserviert Xmobar Platz. Navigation2D liefert den richtungsbezogenen Fenstertausch. Dialoge schweben durch isDialog. ewmh und ewmhFullscreen unterstützen Vollbildanforderungen von Anwendungen. Das mit Super+Space erreichbare Full-Layout behält dagegen Abstände und Bar-Reservierung dieser Konfiguration; es ist nicht dasselbe wie Anwendungs-Vollbild.

Die Workspaces 1–9 bilden einen gemeinsamen Satz. Jeder Monitor zeigt einen anderen Workspace; es sind keine zwei unabhängigen Neunergruppen. Super+Ziffer verwendet das geerbte Greedy-View-Verhalten. Wird ein schon auf dem anderen Monitor sichtbarer Workspace gewählt, können die angezeigten Workspaces die Monitore tauschen. Super+Shift+Ziffer verschiebt das aktive Fenster dorthin. Die Bildschirmkürzel beziehen sich auf XMonad-Indizes, nicht zwingend auf die Anschlussnummerierung.

| Tastenkürzel | Aktion |
| --- | --- |
| Super+Return / Super+Shift+Return | Kitty (ausdrücklich gesetzt / geerbter Standard) |
| Super+T / Super+M | Thunar / Mousepad |
| Super+B / Super+O / Super+V | Chrome / OBS / VS Code (personalApps) |
| Super+D | Rofi-Anwendungsstarter |
| Super+Q | Aktives Fenster schließen; ersetzt das ursprüngliche Neustartkürzel |
| Super+F | Zentriertes schwebendes Fenster mit 70% Größe / zurück ins Tiling |
| Super+Links / Super+Rechts | Fokus unter den Zeiger setzen, Fenster nach links/rechts tauschen |
| Super+linke Maustaste | Ziehen; auf dem Zielmonitor loslassen und einkacheln |
| Super+mittlere Maustaste | Aktives Fenster zum Master machen |
| Super+rechte Maustaste | Als schwebendes Fenster skalieren |
| Super+Space | MouseResizableTile, gespiegelte Variante und Full durchschalten |
| Super+J / Super+K | Geerbter nächster/vorheriger Fokus |
| Super+1…9 / Super+Shift+1…9 | Workspace anzeigen / Fenster verschieben |
| Super+W / Super+E / Super+R | Bildschirm 0 / 1 / 2 aktivieren, sofern vorhanden |
| Super+Shift+W / E / R | Fenster auf den Workspace von Bildschirm 0 / 1 / 2 senden |
| Druck | Screenshot-Bereich wählen; unter ~/Bilder/Screenshots speichern |
| Lauter/leiser, stumm, Mikrofon stumm | PipeWire-Helfer mit Dunst-Rückmeldung |
| Super+Strg+R | Neu kompilieren, nur bei Erfolg neu starten |
| Super+Shift+Q | XMonad-Sitzung beenden (geerbter Standard) |

Nach Änderungen an xmonad.hs Super+Strg+R oder den folgenden Befehl innerhalb von XMonad verwenden. Bei Compilerfehlern wird die laufende Konfiguration nicht absichtlich ersetzt. Beim Testen ein Terminal geöffnet lassen.

```sh
xmonad --recompile && xmonad --restart
```

spawnOnce merkt sich Befehle über normale XMonad-Neustarts hinweg. Der Monitoraufbau wird dadurch nicht erneut ausgeführt; auch bereits gestartete Xmobar-, Dunst- und Picom-Prozesse werden nicht ausgetauscht. Für Wallpaper-Änderungen den Monitorhelfer direkt ausführen. Nach Konfigurationsänderungen an einem Hintergrundprozess diesen bewusst beenden und neu starten oder die X-Sitzung verlassen und startx erneut ausführen. Änderungen der Sitzungsumgebung benötigen eine neue Anmeldung.

## Kitty, Xmobar, Benachrichtigungen und Audio

Kitty bindet current-theme.conf ein und verwendet background_opacity 0.8. Unter X11 benötigt Transparenz einen Compositor. Dieser Desktop startet picom --backend xrender --daemon aus XMonad. In der Quellübergabe existiert keine separate funktionierende picom.conf. XRender ist die dokumentierte Wahl und keine Aussage über den besten Backend für jede GPU. Vorhandene ~/.config/picom.conf oder ~/.config/picom/picom.conf kann Picom trotzdem einlesen. Bei abweichendem Verhalten eine alte Konfiguration prüfen und nicht parallel einen zweiten Compositor starten.

Xmobar liegt auf Bildschirmindex 0, mit 28 Pixel Höhe, Hack-Schrift, Uhr und Lautstärke. Ein Linksklick auf die Uhr öffnet gsimplecal; ein Rechtsklick auf die Lautstärke pavucontrol. Der kleine Shell-Formatierer aus der Quelle zeigte 0.05 als 05% und ignorierte Stummschaltung. Die veröffentlichte Fassung fragt den gemeinsamen Audiohelfer lesend ab und zeigt korrekt 5% beziehungsweise MUTE. Das Intervall von 10 Ticks aktualisiert ungefähr einmal pro Sekunde. Dunst verwendet denselben Dragon-Hintergrund, grüne Rahmen und rote kritische Meldungen.

cthulhu-audio steuert über wpctl den aktuellen WirePlumber-Standardausgang beziehungsweise -eingang. Die Lautstärke ändert sich in Fünf-Prozent-Schritten; Erhöhungen sind auf 1.0, also 100%, begrenzt. Ausgangs- und Mikrofon-Stummschaltung nutzen verschiedene Ersetzungs-IDs für Benachrichtigungen, damit keine lange Warteschlange von Lautstärkehinweisen entsteht. LC_ALL=C stabilisiert die Dezimalauswertung. Die sichtbaren Meldungen bleiben wie in meinen Dateien deutsch; bei Bedarf die Texte ändern. wpctl status und pavucontrol helfen bei der Gerätewahl, wenn plötzlich HDMI-Audio Standard wird.

```sh
wpctl status
```

Hack wird ausdrücklich für Xmobar, Dunst, Rofi und VS Code installiert. Nerd-Font-Pakete liefern die Fastfetch-Symbole. Fehlende Zeichen deuten auf Schrift oder Fallback hin und nicht automatisch auf ein fehlerhaftes Systeminformationsmodul.

## Fastfetch: Bild, Module und eigenes Systemalter

Die vollständige JSONC erhält das eingerahmte Layout mit Benutzer/Hostname, Laufzeit, System, Kernel, WM, Terminal, Shell, CPU, Root-Laufwerk, RAM/Swap, Rechner, GPU, Displays, Alter und Farben. Die persönlichen Zeilen Games.Vol1/Games.Vol2/Homelab fehlen im portablen Standard. Bei Bedarf Disk-Module mit den eigenen eingehängten Pfaden ergänzen; das Root-Modul benötigt meine Laufwerke nicht. Nummerierte Platzhalter im GPU-Format stammen aus der Quelle und können leere Felder liefern, wenn ein Treiber die Information nicht meldet.

Ein eigenes beziehungsweise zur Nutzung erlaubtes Bild unter ~/.config/fastfetch/1.png ablegen. Dieser Dateiname ist unabhängig vom Wallpaper-Verzeichnis. kitty-icat überträgt es über Kittys Bildprotokoll, mit 30 Zeichenbreite und 15 Zeichenhöhe, oben 1, links 2 und rechts 4 Zeichen Abstand. Dafür sind ein geeignetes grafisches Kitty-Terminal und dessen kitten-Helfer nötig. Die reine Linux-Konsole, ungeeignete Terminals oder manche Multiplexer-Sitzungen stellen das nicht identisch dar. Ohne Bild zunächst die Informationen mit fastfetch --logo none prüfen.

```sh
fastfetch --logo none
```

Nach dem Einfügen des Bildes fastfetch in Kitty starten. Der Installer erzeugt ~/.config/fastfetch/cthulhu-born nur, wenn die Datei fehlt. Das Command-Modul zieht ihre Änderungszeit von der aktuellen Zeit ab und zeigt ganze Tage. Das ist eine selbst verwaltete Installationsmarkierung, nicht automatisch das Alter von Mainboard oder Nix Store. Die private Markierung reichte bis Juli 2022 zurück; neue Benutzer übernehmen dieses Datum nicht. Bei manueller Anlage einmalig zur Installation touch verwenden und später nur dann erneut berühren, wenn der Zähler bewusst zurückgesetzt werden soll.

## VS Code und optionale Anwendungen

settings.json wählt Kanagawa Dragon, Material Icon Theme und Hack. Nach dem Aktivieren von personalApps die Erweiterungen der tatsächlichen Herausgeber installieren. Die Quellübergabe enthielt keine Erweiterungsliste; das folgende überprüfte Theme-Paket liefert den benötigten Theme-Namen:

```sh
code --install-extension metaphore.kanagawa-vscode-color-theme
```

```sh
code --install-extension PKief.material-icon-theme
```

Falls die Darstellung nicht sofort übernommen wird, VS Code neu starten. Seine Einstellungen sind keine NixOS-Module. Steam und Lutris bleiben optional. Vorhandene Proton-Präfixe, Bibliothekslaufwerke, Spielekompatibilität und meine laufende Radeon-Fehlersuche sind getrennte Themen. OBS und Kdenlive werden über den Schalter für persönliche Anwendungen installiert, ohne erfundene Leistungsversprechen.

## Vollständige Konfigurationssammlung

Hier stehen die vollständigen veröffentlichten Dateien, keine Ausschnitte. GitHub- und Raw-Links verweisen auf den zugehörigen Setup-Baum. Dieses wiederverwendbare Desktop-Modul ist die sichere Alternative dazu, meine vollständige rechnerspezifische configuration.nix als Installer zu veröffentlichen. Die eigene ursprüngliche configuration.nix importiert das Modul und behält alle installationsbezogenen Entscheidungen.

<!-- FILE_LIBRARY -->

## Fehlersuche und Rückweg

| Symptom | Prüfung und Rückweg |
| --- | --- |
| Nix-Auswertung scheitert | Genannte Option und Datei lesen. YOUR_LOGIN ersetzen, vorhandenes Konto bestätigen, neue Imports bei Flakes tracken und Optionsunterstützung der eigenen Revision prüfen. Fehlgeschlagenen Build nicht aktivieren. |
| startx nutzt eine alte Sitzung | ~/.xinitrc und XINITRC prüfen; beide haben Vorrang vor dem erzeugten Skript. Auch ~/.config/xmonad neben ~/.xmonad prüfen. |
| Schwarzer Bildschirm oder X-Fehler | Mit Strg+Alt+F3 zur TTY wechseln. ~/.local/share/xorg/Xorg.0.log und journalctl -b ansehen. Lokale Anmeldung, eigene Treiber und unterstützte xrandr-Modi prüfen. |
| Kein Authentifizierungsdialog oder Portal | systemctl --user status cthulhu-polkit.service und journalctl --user -b prüfen. Über die generierte startx-Sitzung starten und doppelte Agenten vermeiden. |
| Wallpaper oder Bar nach Neustart unverändert | spawnOnce wiederholt Befehle beim normalen XMonad-Neustart nicht. monitors.sh direkt ausführen oder eine neue X-Sitzung starten. |
| Cursor bleibt Breeze oder ist winzig | Beide GTK-Dateien und XCURSOR_THEME/XCURSOR_SIZE nach einer frischen Anmeldung prüfen. Anwendungen können eigenes Cursorverhalten haben. |
| Kitty bleibt undurchsichtig | Picom einmalig starten, dessen Terminalfehler und alte Konfigurationsdateien prüfen; anschließend ein neues Kitty-Fenster öffnen. |
| Fastfetch-Bild fehlt | Eigenes PNG im richtigen Verzeichnis ablegen und Kitty verwenden. Text mit --logo none unabhängig prüfen. |
| Lautstärke steuert das falsche Gerät | wpctl status und pavucontrol verwenden; der Helfer verwendet bewusst den aktuellen Standardausgang/-eingang. |

Von einer TTY zur vorherigen Systemgeneration zurückkehren:

```sh
sudo nixos-rebuild switch --rollback
```

Falls das aktuelle System nicht bedienbar ist, im Bootmenü eine frühere NixOS-Generation auswählen. Diese Generationen während des Umbaus behalten; den Rückweg nicht mitten in der Installation durch Garbage Collection beseitigen. Für eine dauerhafte Rückkehr zu Plasma standalone wieder auf false setzen, die ursprünglichen Plasma-/SDDM-Deklarationen erhalten oder wiederherstellen und neu bauen. Der Schalter erzwingt deren Abschaltung nur bei true. Er installiert auf dem Minimal-Weg nicht automatisch Plasma. Benutzerdateien gesondert aus ihren Sicherungen zurückholen: NixOS-Rollback setzt manuell kopierte Dotfiles nicht zurück.

## Nachweise, Bildnachweise und Quellen

Die Konfiguration stammt aus meinen tatsächlich verwendeten Dateien. Funktionierendes Ziehen, Größenändern und die Sitzung nach dem Neustart habe ich selbst bestätigt. Automatisierte Quell- und Konfigurationsprüfungen stehen im Validierungsprotokoll des Repositorys. Sie testen weder meine Radeon und die zwei physischen Displays noch eine vollständige grafische Sitzung auf einem frisch installierten Rechner. Diese Eigenschaften müssen Leser weiterhin auf ihrer eigenen Hardware prüfen.

Den aktuellen Screenshot mit Waldhintergrund hat Dennis Hilk am 19. Oktober 2026 ausdrücklich für diese Dokumentation bereitgestellt. Er zeigt den echten Desktop mit Kitty und Fastfetch. Frühere Fuji-Screenshots gehören zu einem früheren Stand und werden nicht als Beleg für diese Version verwendet. Die Aufnahme dokumentiert den Desktop und ist kein separat lizenziertes Wallpaper- oder Fastfetch-Bildpaket. Sichtbare fremde Kunst behält ihre ursprünglichen Rechte. Das herunterladbare Setup enthält keine herausgelösten Bilder. Für 1.png und 2.png eigene Bilder verwenden. ATTRIBUTION.md erläutert die getrennten Theme-Lizenzen und Veröffentlichungskorrekturen.

Technische Primärquellen:

- [NixOS-startx-Modul und erzeugte Sitzung](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/services/x11/display-managers/startx.nix)
- [NixOS-XMonad-Modul und Contrib-Pakete](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/services/x11/window-managers/xmonad.nix)
- [XMonad AfterDrag](https://xmonad.github.io/xmonad-docs/xmonad-contrib/XMonad-Actions-AfterDrag.html)
- [XMonad UpdateFocus](https://xmonad.github.io/xmonad-docs/xmonad-contrib/XMonad-Actions-UpdateFocus.html)
- [XMonad MouseResizableTile](https://xmonad.github.io/xmonad-docs/xmonad-contrib/XMonad-Layout-MouseResizableTile.html)
- [Kitty-Konfiguration](https://sw.kovidgoyal.net/kitty/conf/)
- [feh-Handbuch, Wallpaper-Modi und Xinerama](https://man.finalrewind.org/1/feh/)
- [Fastfetch-JSON-Schema](https://github.com/fastfetch-cli/fastfetch/wiki/Json-Schema)
- [Kanagawa-GTK-Quelle und Lizenz](https://github.com/Fausto-Korpsvart/Kanagawa-GKT-Theme)
- [Ursprüngliche Kanagawa-Palette](https://github.com/rebelot/kanagawa.nvim)
- [Kanagawa-Theme für VS Code](https://github.com/paccodes/kanagawa-vscode-theme)
- [Material Icon Theme](https://github.com/material-extensions/vscode-material-icon-theme)
- [GTK 4 Settings](https://docs.gtk.org/gtk4/class.Settings.html)
