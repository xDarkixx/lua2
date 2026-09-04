# BULDACITY – Schritt für Schritt

Diese Anleitung beschreibt die aktuelle Installation für Minecraft 1.7.10 + Forge + OpenComputers.

**Wichtig:** Alle BULDACITY-Lua-Dateien werden auf dem OpenComputers-Rechner ausschließlich unter `/home` installiert und von dort geladen. Es gibt keine `/lib`-Loader mehr.

## 1. Voraussetzungen

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für Minecraft 1.7.10
- die jeweils benötigten Mod- und Adapter-Versionen

## 2. Zentrale BULDACITY-Maschine

Baue einen Tier-3-OpenComputers-PC mit CPU, RAM, Speicher, GPU, Screen, Keyboard und Network Card oder Wireless Network Card.

## 3. Exakte Dateiablage – Zentrale

**Alle diese Dateien gehören nach `/home`:**

```text
/home/Network.lua
/home/BuldacityOS_Tier3.lua
/home/BuldacityDesktop.lua
/home/BuldacityUI.lua
/home/BuldacityComponentDashboard.lua
/home/BuldacityAutoStart.lua
/home/BuldacityNetworkTest.lua
/home/BuldacityWirelessCheck_Modern.lua
```

Keine dieser BULDACITY-Dateien muss nach `/lib`, `/usr/lib` oder `/` kopiert werden.

## 4. Zentrale starten

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

`BuldacityOS_Tier3.lua` startet fest:

```text
/home/BuldacityDesktop.lua
```

Die zentrale Desktop-Oberfläche enthält Netzwerkzentrale, Geräteverwaltung, Remote-PC, Systemmonitor, Apps, Laufwerke und Wireless-Diagnose.

## 5. Wireless-Hardware prüfen

```lua
dofile("/home/BuldacityWirelessCheck_Modern.lua")
```

Die Diagnose prüft Modems, Wireless-Hardware, Signalstärke, Relay, Access Point und Wireless-Pfade.

```text
WIRELESS READY
WIRELESS NOT READY
WIRELESS MISSING
```

- `WIRELESS MISSING`: Wireless Network Card einsetzen.
- `WIRELESS NOT READY`: Wireless-Hardware vorhanden, aber Signalstärke nicht korrekt gesetzt.
- `WIRELESS READY`: Hardware und Signal sind bereit. Danach zusätzlich PING/PONG prüfen.

## 6. Client-PC installieren

Für jeden Mod wird ein eigener OpenComputers-PC verwendet.

Minimal:

```text
CPU + RAM + Speicher + Network Card
```

Für grafische Controller zusätzlich:

```text
GPU + Screen + Keyboard
```

**Auf jeden Netzwerk-Client kommt `/home/Network.lua`.**

Danach kommen der passende Network-Wrapper und der dazugehörige Controller ebenfalls nach `/home`.

### Beispiel 3D Printer

```text
/home/Network.lua
/home/3DPrinterNetwork_Modern.lua
/home/3DPrinter_Modern.lua
```

### Beispiel Big Reactors

```text
/home/Network.lua
/home/ReactorBigReactors043A_Network.lua
/home/ReactorBigReactors043A_Touch_Responsive.lua
```

## 7. Allgemeines Schema

```text
/home/
├── Network.lua
├── BuldacityUI.lua
├── <Mod>Network_Modern.lua
└── <Mod>_Modern.lua
```

Die Network-Wrapper verwenden `Network.startClient(...)` und laden anschließend den lokalen Controller aus `/home` bzw. aus dem aktuellen `/home`-Arbeitsverzeichnis.

## 8. Mod-Komponente anschließen

Komponenten prüfen:

```lua
local component=require("component")
for address,typ in component.list() do
  print(address,typ)
end
```

Bei einem Adapter:

```text
OpenComputers-PC → OC-Kabel → Adapter → Mod-Block
```

## 9. Lokale GUI testen

1. passenden `<Mod>_Modern.lua` Controller nach `/home` kopieren
2. GUI starten
3. `SCAN` ausführen
4. Komponenten prüfen
5. lokale Funktionen testen
6. erst danach den Network-Wrapper starten

Gemeinsame GUI-Bibliothek:

```text
/home/BuldacityUI.lua
```

## 10. Netzwerk testen

Zentrale zuerst:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

Client danach:

```lua
dofile("/home/<Mod>Network_Modern.lua")
```

Netzwerk:

```text
Protokoll: BULDACITY/2
Port:     4242
```

Der Client sollte unter `DEVICES` erscheinen.

## 11. Automatische Netzwerkdiagnose

`Network.lua` prüft HELLO, Heartbeat, Wireless-Hardware, Signalstärke, Relay/Access Point, Entfernung und PING/PONG.

`WIRELESS READY` bedeutet nur, dass die lokale Wireless-Hardware einsatzbereit ist. Erst `PING PASS` bestätigt die End-to-End-Verbindung.

## 12. Big Reactors

```text
/home/Network.lua
/home/ReactorBigReactors043A_Network.lua
/home/ReactorBigReactors043A_Touch_Responsive.lua
```

Mögliche OpenComputers-Komponenten sind unter anderem `br_reactor` und `br_turbine`.

## 13. Autostart

Installiere:

```text
/home/BuldacityAutoStart.lua
/home/autorun.lua
```

Konfiguration:

```text
/home/buldacity-role.cfg
```

### Zentrale

```text
ROLE=SERVER
```

### Client

```text
ROLE=CLIENT
CLIENT=BigReactors
```

Der Autostart setzt `/home` als Arbeitsverzeichnis und startet alle BULDACITY-Programme direkt aus `/home`.

## 14. `file not found` beheben

### `module 'Network' not found`

Prüfen:

```text
/home/Network.lua
```

Danach sicherstellen, dass `/home` das Arbeitsverzeichnis ist:

```lua
local shell=require("shell")
shell.setWorkingDirectory("/home")
```

Dann testen:

```lua
local Network=require("Network")
print(Network.PROTOCOL)
```

Erwartet:

```text
BULDACITY/2
```

### `module 'BuldacityUI' not found`

Prüfen:

```text
/home/BuldacityUI.lua
```

und `/home` als Arbeitsverzeichnis verwenden.

### `BuldacityDesktop.lua not found`

Prüfen:

```text
/home/BuldacityDesktop.lua
```

Start:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

### Controller nicht gefunden

Beide passenden Dateien müssen in `/home` liegen:

```text
/home/<Mod>Network_Modern.lua
/home/<Mod>_Modern.lua
```

## 15. Schneller Datei-Check

```lua
local fs=require("filesystem")
for _,p in ipairs({
  "/home/Network.lua",
  "/home/BuldacityOS_Tier3.lua",
  "/home/BuldacityDesktop.lua",
  "/home/BuldacityUI.lua",
  "/home/BuldacityComponentDashboard.lua",
  "/home/BuldacityAutoStart.lua",
  "/home/BuldacityNetworkTest.lua",
  "/home/BuldacityWirelessCheck_Modern.lua"
}) do
  print(p,fs.exists(p) and "OK" or "MISSING")
end
```

## 16. Vollständiger Ablauf

```text
Minecraft 1.7.10
 ↓
Forge 10.13.4.1614
 ↓
OpenComputers
 ↓
Tier-3-Zentrale
 ↓
/home/Network.lua
 ↓
/home/BuldacityOS_Tier3.lua
 ↓
/home/BuldacityDesktop.lua
 ↓
Wireless-Hardware prüfen
 ↓
Mod-Komponente prüfen
 ↓
Lokale GUI testen
 ↓
/home/<Mod>Network_Modern.lua
 ↓
BULDACITY/2 : 4242
 ↓
DEVICES
 ↓
PING/PONG
 ↓
REMOTE
 ↓
Autostart
```

## 17. Abschlussprüfung

- `/home/Network.lua` vorhanden
- `/home/BuldacityUI.lua` vorhanden, wenn benötigt
- `/home/BuldacityOS_Tier3.lua` vorhanden
- `/home/BuldacityDesktop.lua` vorhanden
- Desktop startet
- lokale Mod-GUI startet
- Komponenten werden erkannt
- Wireless-Hardware wird erkannt, wenn Wireless verwendet wird
- Wireless-Signal ist konfiguriert
- Client erscheint unter `DEVICES`
- Heartbeat bleibt aktiv
- PING/PONG funktioniert
- Remote-Bildschirm funktioniert
- Eingaben funktionieren
- Autostart funktioniert

## 18. Kurzfassung der Ablage

### Zentrale

```text
/home/Network.lua
/home/BuldacityOS_Tier3.lua
/home/BuldacityDesktop.lua
/home/BuldacityUI.lua
/home/BuldacityComponentDashboard.lua
/home/BuldacityAutoStart.lua
/home/BuldacityNetworkTest.lua
/home/BuldacityWirelessCheck_Modern.lua
/home/autorun.lua
/home/buldacity-role.cfg
```

### Jeder Netzwerk-Client

```text
/home/Network.lua
/home/BuldacityUI.lua                 ← falls benötigt
/home/<Mod>Network_Modern.lua
/home/<Mod>_Modern.lua
```

### Big Reactors

```text
/home/Network.lua
/home/ReactorBigReactors043A_Network.lua
/home/ReactorBigReactors043A_Touch_Responsive.lua
```

**Grundregel: Alles von BULDACITY kommt nach `/home`. Keine `/lib`-Loader verwenden.**