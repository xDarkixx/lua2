# BULDACITY / 2

## 🟢 Anfänger? START HIER

BULDACITY ist eine OpenComputers-Steuerung für Minecraft 1.7.10.

**Der wichtigste Punkt:** Die alte/originale Lua-Struktur bleibt im Repository erhalten. Die Programme sind zusätzlich sauber in Ordner einsortiert, damit man sie leichter findet und die bestehende Installation nicht kaputtgeht.

## 🚀 Echter OpenComputers-Installer

Es gibt jetzt einen echten Installer: `install.lua`.

Der Installer lädt die benötigten BULDACITY-Dateien direkt aus dem öffentlichen GitHub-Repository und installiert sie kompatibel nach `/home`. Vorhandene Dateien werden vor dem Überschreiben unter `/home/buldacity-backup/` gesichert. Danach werden die geladenen Lua-Dateien auf Syntaxfehler geprüft und `autorun.lua` eingerichtet.

Voraussetzungen:

- OpenComputers
- Tier-3-Festplatte/Filesystem
- Internet Card für den Download
- Modem/Wireless Network Card für das BULDACITY-Netzwerk

Start:

```text
install.lua
```

Dann:

```text
1) Kern installieren/reparieren
2) Alles installieren (Kern + Mod-Clients)
3) Installation prüfen
4) Netzwerk/Hardware prüfen
```

Details: `docs/06_INSTALLER.md`

## 📁 Neue übersichtliche Struktur

```text
lua2/
├── install.lua              # echter OpenComputers-Installer
├── autorun.lua              # OpenComputers-Autostart-Einstieg
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

Für eine bestehende Installation können weiterhin die bekannten Root-Dateien verwendet werden. Der neue Installer übernimmt diese Runtime-Dateien automatisch nach `/home`.

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

Der Autostart liegt zusätzlich unter `boot/`. Für vorhandene Installationen bleibt `BuldacityAutoStart.lua` im Root erhalten. Der Installer erzeugt außerdem `/home/autorun.lua`, das den kompatiblen Autostart aufruft.

## 📚 Anleitung

Für Einsteiger zuerst:

1. `docs/01_START_HIER.md`
2. `docs/02_HARDWARE.md`
3. `docs/03_NETZWERK.md`
4. `docs/04_AUTOSTART.md`
5. `docs/06_INSTALLER.md`

Danach die jeweiligen Ordner unter `clients/` verwenden.

## Ziel

**Einfach für Anfänger, sauber für Fortgeschrittene und kompatibel mit dem bestehenden BULDACITY-System.**
