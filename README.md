🇩🇪 **NixOS-Systemkonfiguration für meinen Main-PC (KDE Plasma)**  
🇬🇧 **NixOS system configuration for my main PC (KDE Plasma)**

---

## 🇩🇪 Beschreibung

**Cthulhu** ist meine **NixOS-Systemkonfiguration für meinen Desktop-PC**, mit Fokus auf **KDE Plasma**, Gaming, Benchmarks und Experimente.  
Das System dient als **Hauptarbeits- und Testumgebung**.

Dieses Repository fungiert gleichzeitig als **vollständiges System-Backup**.  
Die Konfiguration ist deklarativ, versioniert und jederzeit reproduzierbar.

---

## 🇬🇧 Description

**Cthulhu** is my **NixOS system configuration for my desktop PC**, focused on **KDE Plasma**, gaming, benchmarks and experimentation.  
The system acts as my **primary workstation and lab environment**.

This repository also serves as a **complete system backup**.  
The configuration is declarative, versioned, and fully reproducible.

---

## 🎯 Goals / Ziele

- Fully declarative NixOS configuration
- KDE Plasma desktop
- Optimized for high-end desktop hardware
- NVIDIA GPU support
- Gaming, benchmarking and experimentation
- Fast rollback and reproducibility
- Version-controlled system state

---

## 🧠 System Philosophy / System-Philosophie

🇩🇪  
Dieses Repository ist das **Single Source of Truth** für mein Main-System.  
Jede relevante Systemeigenschaft ist:

- dokumentiert
- versioniert
- reproduzierbar

Rollback ist jederzeit möglich, ohne Neuinstallation.

🇬🇧  
This repository acts as the **single source of truth** for my main system.  
Every relevant system aspect is:

- documented
- versioned
- reproducible

Rollbacks are always possible without reinstalling.

---
## 🖥️ Hardware Target / Zielhardware
AMD Ryzen 7 5800X3D

NVIDIA RTX 3060 Ti

32 GB DDR4 RAM

Multiple NVMe SSDs

High-refresh display setup

⚠️ Disclaimer
🇩🇪
Diese Konfiguration ist auf meine Hardware zugeschnitten.
Sie dient primär als Backup und Dokumentation meines Systems.

🇬🇧
This configuration is tailored to my hardware.
It primarily serves as a backup and documentation of my system.

## 🧱 Repository Structure / Struktur

```text
cthulhu/
├── nixos/
│   ├── configuration.nix
│   ├── hardware-configuration.nix
│   ├── plasma/
│   └── modules/
├── scripts/
├── benchmarks/
└── README.md
