# BULDACITY / 2

## 🟢 Anfänger? START HIER

BULDACITY ist eine OpenComputers-Steuerung für Minecraft 1.7.10.

**Wichtig:** Die alte/originale Lua-Struktur bleibt erhalten. Die Programme sind zusätzlich sauber in Ordner einsortiert, damit bestehende Installationen kompatibel bleiben.

## 🖥️ Echter Main-PC-Installer

Neben dem OpenComputers-Installer gibt es jetzt einen Installer für den **Haupt-PC**: `mainpc/install.py` bzw. unter Windows `mainpc/install.bat`.

Der Main-PC-Installer lädt **den kompletten `main`-Branch von `xDarkixx/lua2`** direkt von GitHub. Er verwendet dafür das GitHub-Repository-Archiv und benötigt **kein Git**. Damit müssen keine einzelnen Dateien mehr im Installer gepflegt werden: Neue Dateien und neue Ordner werden beim nächsten Update automatisch übernommen.

Vorhandene Dateien werden vor dem Überschreiben in `backup/YYYYMMDD-HHMMSS/` gesichert. Nach der Installation gibt es einen kleinen Main-PC-Launcher (`mainpc`) sowie `BULDACITY.bat` für Windows.

### Windows

```text
mainpc\install.bat
```

oder:

```text
py mainpc\install.py
```

### Linux / macOS

```text
python3 mainpc/install.py
```

Danach kann die lokale BULDACITY-Verwaltung mit `./mainpc` gestartet werden.

### Aktualisieren

```text
python3 mainpc/install.py --update
```

Der Main-PC lädt dann wieder den aktuellen Stand des gesamten Repositories. Der Minecraft/OpenComputers-Installer bleibt davon getrennt.

## 🚀 OpenComputers-Installer

Es gibt weiterhin den echten Installer `install.lua`. Er lädt die benötigten Runtime-Dateien aus dem öffentlichen GitHub-Repository nach `/home`, sichert vorhandene Dateien unter `/home/buldacity-backup/`, prüft Lua-Syntax und richtet `autorun.lua` ein.

Voraussetzungen:

- OpenComputers
- Tier-3-Festplatte/Filesystem
- Internet Card für den Download
- Modem/Wireless Network Card für das BULDACITY-Netzwerk

## 📁 Struktur

```text
lua2/
├── install.lua              # OpenComputers-Installer
├── mainpc/                  # Main-PC-Installer + lokale Verwaltung
├── autorun.lua              # OpenComputers-Autostart
├── server/                  # Zentrale / Tier-3 Computer
├── network/                 # Netzwerk
├── clients/                 # Mod- und Anlagensteuerungen
├── ui/                      # BULDACITY-Oberfläche
├── setup/                   # Einrichtungsassistenten
├── boot/                    # Start / Autostart
├── tools/                   # Diagnose-Werkzeuge
└── docs/                    # Anleitungen
```

## 🔒 Kompatibilität

Die bisherigen Root-Lua-Dateien werden nicht gelöscht oder umbenannt. Neue Ordner und Installer ergänzen das bestehende System, statt es zu ersetzen.

## 🌐 Netzwerk

- Protokoll: `BULDACITY/2`
- Port: `4242`
- WLAN-Stärke: bis `400`

## Ziel

**Ein Installer für den Haupt-PC, ein Installer für OpenComputers und beide holen ihre benötigten Daten direkt aus demselben GitHub-Repository.**
