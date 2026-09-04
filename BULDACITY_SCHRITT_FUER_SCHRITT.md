# BULDACITY – Schritt für Schritt

Diese Anleitung beschreibt die aktuelle Installation für Minecraft 1.7.10 + Forge + OpenComputers und die genaue Ablage der Lua-Dateien. Die Pfade sind so gewählt, dass `file not found` möglichst vermieden wird.

## 1. Voraussetzungen

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für Minecraft 1.7.10
- die jeweils benötigten Mod- und Adapter-Versionen

## 2. Zentrale BULDACITY-Maschine

Baue einen Tier-3-OpenComputers-PC mit CPU, RAM, Speicher, GPU, Screen, Keyboard und Network Card oder Wireless Network Card.

## 3. Exakte Dateiablage

### Zentrale: `/home`

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

### Kompatibilitäts-Loader: `/lib`

```text
/lib/Network.lua
/lib/BuldacityUI.lua
```

Die Loader laden die eigentlichen Dateien aus `/home`, `/` oder `/usr/lib`. Die eigentliche gemeinsame `Network.lua` bleibt `/home/Network.lua`.

## 4. Zentrale starten

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

Das Desktop-System enthält unter anderem Netzwerkzentrale, Geräteverwaltung, Remote-PC, Systemmonitor und Wireless-Diagnose.

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

Bei `WIRELESS MISSING`: Wireless Network Card einsetzen.
Bei `WIRELESS NOT READY`: Wireless-Hardware ist vorhanden, aber nicht korrekt konfiguriert.
Bei `WIRELESS READY`: Hardware und Signal sind bereit. Danach muss zusätzlich PING/PONG erfolgreich sein.

## 6. Client-PC installieren

Für jeden Mod wird ein eigener OpenComputers-PC verwendet. Minimal: CPU, RAM, Speicher und Network Card/Wireless Network Card. Für grafische Controller zusätzlich GPU + Screen.

Auf **jeden Netzwerk-Client**:

```text
/home/Network.lua
```

Danach den passenden Network-Wrapper und den dazugehörigen Controller.

Beispiel 3D Printer:

```text
/home/3DPrinterNetwork_Modern.lua
/home/3DPrinter_Modern.lua
```

Beispiel Big Reactors:

```text
/home/ReactorBigReactors043A_Network.lua
/home/ReactorBigReactors043A_Touch_Responsive.lua
```

## 7. Allgemeines Schema

```text
/home/
├── Network.lua                         ← Netzwerkbibliothek
├── BuldacityUI.lua                     ← bei GUI-Controllern
├── <Mod>Network_Modern.lua             ← Netzwerk-Wrapper
└── <Mod>_Modern.lua                    ← lokale Mod-GUI
```

Der Wrapper startet `Network.startClient(...)` und lädt anschließend den lokalen Controller.

## 8. Mod-Komponente anschließen

```lua
component.list()
```

Nur tatsächlich angezeigte Komponenten verwenden.

Bei einem Adapter:

```text
OpenComputers-PC → OC-Kabel → Adapter → Mod-Block
```

## 9. Lokale GUI zuerst testen

1. passenden `<Mod>_Modern.lua` Controller starten
2. GUI prüfen
3. `SCAN` ausführen
4. Komponenten prüfen
5. lokale Funktionen testen
6. erst danach den Network-Wrapper verwenden

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

`Network.lua` prüft HELLO, Heartbeat, Wireless-Hardware, Signalstärke, Relay/Access Point, Entfernung, PING/PONG und das End-to-End-Ergebnis.

`WIRELESS READY` allein bedeutet nicht, dass die komplette Verbindung funktioniert. Erst `PING PASS` bestätigt die Verbindung.

## 12. Big Reactors

```text
/home/Network.lua
/home/ReactorBigReactors043A_Network.lua
/home/ReactorBigReactors043A_Touch_Responsive.lua
```

Komponenten können `br_reactor` und `br_turbine` sein.

## 13. Autostart

```text
/home/BuldacityAutoStart.lua
/home/autorun.lua
```

Zentrale:

```text
/home/buldacity-role.cfg
ROLE=SERVER
```

Client-Beispiel:

```text
ROLE=CLIENT
CLIENT=BigReactors
```

## 14. `file not found` beheben

### `module 'Network' not found`

Prüfen:

```text
/home/Network.lua
/lib/Network.lua
```

Der Loader `/lib/Network.lua` sucht:

```text
/Network.lua
/home/Network.lua
/usr/lib/Network.lua
```

### `module 'BuldacityUI' not found`

Prüfen:

```text
/home/BuldacityUI.lua
/lib/BuldacityUI.lua
```

### `BuldacityDesktop.lua not found`

Prüfen:

```text
/home/BuldacityDesktop.lua
```

Danach:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

### Controller nicht gefunden

Es müssen beide passenden Dateien vorhanden sein:

```text
<Mod>Network_Modern.lua
<Mod>_Modern.lua
```

## 15. Schneller Datei-Check

```lua
local fs=require("filesystem")
for _,p in ipairs({
 "/home/Network.lua",
 "/home/BuldacityOS_Tier3.lua",
 "/home/BuldacityDesktop.lua",
 "/home/BuldacityUI.lua",
 "/lib/Network.lua",
 "/lib/BuldacityUI.lua"
}) do
 print(p, fs.exists(p) and "OK" or "MISSING")
end
```

Komponenten:

```lua
local component=require("component")
for address,typ in component.list() do
 print(address,typ)
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
/home/Network.lua + Desktop + UI
 ↓
/lib/Network.lua + /lib/BuldacityUI.lua
 ↓
Wireless-Hardware prüfen
 ↓
Mod-Komponente prüfen
 ↓
Lokale GUI testen
 ↓
Network-Wrapper
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

- Minecraft/Forge/OpenComputers starten
- `Network.lua` wird gefunden
- `BuldacityUI.lua` wird gefunden
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
/lib/Network.lua
/lib/BuldacityUI.lua
```

### Jeder Netzwerk-Client

```text
/home/Network.lua
/home/BuldacityUI.lua       ← falls der Controller die GUI benötigt
/home/<Mod>Network_Modern.lua
/home/<Mod>_Modern.lua
```

### Big Reactors

```text
/home/Network.lua
/home/ReactorBigReactors043A_Network.lua
/home/ReactorBigReactors043A_Touch_Responsive.lua
```

**Grundregel:** `Network.lua` muss auf Zentrale und jedem Netzwerk-Client vorhanden sein. `BuldacityUI.lua` muss auf jedem Rechner vorhanden sein, dessen Controller sie verwendet. Network-Wrapper und lokaler Controller gehören auf denselben Rechner.