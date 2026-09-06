# lua2 – BULDACITY/2

OpenComputers-Lua-Programme für Minecraft 1.7.10.

> **🟢 Anfänger? Dann starte mit [`docs/01_START_HIER.md`](docs/01_START_HIER.md).**
>
> Du musst kein Lua können. Die Dateien bleiben bewusst zunächst im Hauptordner, damit bestehende Installationen nicht kaputtgehen. Die neuen Ordner dienen als übersichtliche Struktur und Anleitung.

## 🗂️ So ist das Projekt aufgebaut

```text
lua2/
├── docs/                 ← 🟢 HIER STARTEN
│   ├── 01_START_HIER.md
│   ├── 02_HARDWARE.md
│   ├── 03_NETZWERK.md
│   └── 04_AUTOSTART.md
├── server/               ← Zentrale
├── network/              ← Netzwerk
├── clients/              ← Geräte / Mods
│   ├── bigreactors/
│   └── sgcraft/
├── boot/                 ← Autostart
├── tools/                ← Diagnose
└── Root-Dateien          ← kompatibel mit bisherigen Installationen
```

## 🌐 Netzwerk – möglichst einfach

BULDACITY verwendet **BULDACITY/2** auf Port **4242**.

Die vorhandene `Network.lua` erkennt Modems automatisch, öffnet Port 4242, erkennt Wireless-Hardware und unterstützt Client-Discovery, Link/Ping-Tests und Komponentenabfragen.

Der zentrale Ablauf ist:

```text
SERVER STARTEN
      ↓
MODEM AUTOMATISCH FINDEN
      ↓
PORT 4242
      ↓
CLIENT STARTEN
      ↓
AUTOMATISCHE ERKENNUNG
      ↓
PING / LINK
      ↓
GERÄTE IN DEVICES
```

Du brauchst dafür normalerweise keine UUID-Whitelist und musst keine Adressen von Hand eintragen.

## 🖥️ Zentrale

- `BuldacityOS_Tier3.lua` – zentraler Desktop
- `BuldacityNetworkSetup.lua` – automatischer Netzwerkcheck
- `Network.lua` – BULDACITY/2 Netzwerkdienst
- `BuldacityUI.lua` – gemeinsames UI
- `BuldacityComponentDashboard.lua` – Geräte-/Komponenten-Dashboard
- `BuldacityAutoStart.lua` – Autostart

## ⚙️ Clients

Die grafischen Controller bleiben lokale Apps. Network-Controller verbinden die Geräte mit der Zentrale.

### Big Reactors

- `ReactorBigReactors043A_Touch_Responsive.lua`
- `ReactorBigReactors043A_Network.lua`

Siehe [`clients/bigreactors/README.md`](clients/bigreactors/README.md).

### SGCraft

- `SGCraft_Modern.lua`
- `SGCraftNetwork_Modern.lua`

Siehe [`clients/sgcraft/README.md`](clients/sgcraft/README.md).

## 📚 Dokumentation

- 🟢 [`START HIER`](docs/01_START_HIER.md)
- 🔧 [`Hardware`](docs/02_HARDWARE.md)
- 🌐 [`Netzwerk`](docs/03_NETZWERK.md)
- ▶️ [`Autostart`](docs/04_AUTOSTART.md)
- `BULDACITY_SCHRITT_FUER_SCHRITT.md`
- `BULDACITY_SETUP_GUIDE.md`
- `BULDACITY_NETWORK.md`
- `BULDACITY_WIRELESS_SETUP.md`
- `BULDACITY_MOD_SETUP_ADDONS.md`
- `COMPONENTS.md`

## 🔴 Wichtig bei Fehlern

Immer in dieser Reihenfolge prüfen:

**Hardware → Modem → Network.lua → lokale Mod-GUI → Network-Controller → Zentrale → Autostart.**

So lässt sich ein Fehler schnell eingrenzen, ohne zehn Dateien gleichzeitig zu ändern.
