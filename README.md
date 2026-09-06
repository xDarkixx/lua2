# BULDACITY / 2

## 🟢 Anfänger? START HIER

BULDACITY ist eine OpenComputers-Steuerung für Minecraft 1.7.10.

**Der wichtigste Punkt:** Die alte/originale Lua-Struktur bleibt im Repository erhalten. Die Programme sind zusätzlich sauber in Ordner einsortiert, damit man sie leichter findet und die bestehende Installation nicht kaputtgeht.

## 📁 Neue übersichtliche Struktur

```text
lua2/
├── server/                  # Zentrale / Tier-3 Computer
├── network/                 # Netzwerk, Discovery und Netzwerk-Clients
├── clients/                 # Mod- und Anlagensteuerungen
│   ├── ae2/
│   ├── bigreactors/
│   ├── sgcraft/
│   ├── diesel/
│   ├── 3dprinter/
│   ├── forestry/
│   ├── galacticraft/
│   ├── gendustry/
│   ├── immersiveengineering/
│   ├── immersiveintegration/
│   ├── immersiverailroading/
│   ├── industrialcraft2/
│   ├── logisticspipes/
│   ├── mekanism/
│   ├── pneumaticcraft/
│   ├── projecte/
│   ├── rftools/
│   ├── rotarycraft/
│   ├── thermalexpansion/
│   └── thermal/
├── ui/                      # BULDACITY-Oberfläche
├── setup/                   # Einrichtungsassistenten
├── boot/                    # Start / Autostart
├── tools/                   # Diagnose-Werkzeuge
└── docs/                    # Anleitungen
```

## 🔒 Original bleibt erhalten

Die bisherigen Lua-Dateien im Repository-Root wurden **nicht gelöscht und nicht umbenannt**. Sie bleiben als kompatible Original-/Legacy-Versionen vorhanden.

Die neuen Ordner enthalten die gleichen Programme als sauber einsortierte Kopien. Dadurch kann die Struktur verbessert werden, ohne eine bestehende OpenComputers-Installation durch geänderte Pfade zu beschädigen.

### Wichtig für Minecraft

Für eine bestehende Installation zunächst weiterhin die bekannten Root-Dateien verwenden. Die Ordnerstruktur ist die neue übersichtliche Organisation und kann später kontrolliert auf die tatsächlichen `/home`-Pfade übernommen werden.

## 🌐 Netzwerk

Das Netzwerk ist vollständig vom UI getrennt.

- `network/Network.lua` → Netzwerk-Kern
- `network/BuldacityNetworkSetup.lua` → klassischer Setup-Assistent
- `network/BuldacityNetworkTest.lua` → Netzwerkdiagnose
- `setup/BuldacityNetworkWizard.lua` → einfacher Assistent
- `setup/BuldacityNetworkWizardUI.lua` → grafischer Touch-Assistent

Standard:

- Protokoll: `BULDACITY/2`
- Port: `4242`
- WLAN-Stärke: automatisch bis `400`

## 🖥️ Oberfläche

Die Oberfläche liegt getrennt in `ui/`. Netzwerklogik und grafische Oberfläche werden dadurch nicht miteinander vermischt.

## 🔧 Server

Die Zentrale liegt zusätzlich unter `server/`:

- Tier-3 OS
- Desktop
- Component Server
- Component Dashboard
- Component Agent

## ⚙️ Autostart

Der Autostart liegt zusätzlich unter `boot/`. Für vorhandene Installationen bleibt `BuldacityAutoStart.lua` im Root erhalten.

## 📚 Anleitung

Für Einsteiger zuerst:

1. `docs/01_START_HIER.md`
2. `docs/02_HARDWARE.md`
3. `docs/03_NETZWERK.md`
4. `docs/04_AUTOSTART.md`

Danach die jeweiligen Ordner unter `clients/` verwenden.

## Ziel

**Einfach für Anfänger, sauber für Fortgeschrittene und kompatibel mit dem bestehenden BULDACITY-System.**
