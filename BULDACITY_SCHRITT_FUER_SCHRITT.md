# BULDACITY v9 – Schritt für Schritt

Diese Anleitung beschreibt die aktuelle grafische BULDACITY-Version für Minecraft 1.7.10 + Forge + OpenComputers.

## 1. Was v9 bietet

BULDACITY verwendet jetzt eine gemeinsame GPU-Oberfläche (`BuldacityUI.lua`) mit:

- echten GPU-Flächen statt reiner ASCII-Balken
- horizontalen und vertikalen Fortschrittsbalken
- großen Dashboard-Karten
- Status-LEDs und Badges
- Buttons und Touch-Flächen
- Messanzeigen/Gauges
- Live-Sparklines und Diagrammen
- Pixel-Icons für PC, Netzwerk, Energie, Reaktor, Maschine, Speicher, Drucker und Flüssigkeiten
- automatischer Anpassung an die vorhandene Screen-Auflösung
- Component-Explorer mit Component-Typ und OpenComputers-Adresse
- Remote-PC-Anzeige
- Netzwerk-/Relay-/Wireless-Dashboard
- Reactor-Dashboard

Die Oberfläche ist für Tier-3-Systeme und große Auflösungen bis zum vorhandenen GPU/Screen-Limit ausgelegt und fällt bei kleineren Screens automatisch kompakter aus.

## 2. Voraussetzungen

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für Minecraft 1.7.10
- Tier-3-CPU/GPU/RAM für die Zentrale
- Screen + GPU für grafische Oberflächen
- Network Card oder Wireless Network Card für Netzwerkbetrieb
- die Mod, deren Geräte gesteuert werden sollen

## 3. Grundregel: alles nach `/home`

Alle BULDACITY-Lua-Dateien werden auf dem OpenComputers-Rechner unter `/home` abgelegt.

```text
/home/Network.lua
/home/BuldacityUI.lua
/home/BuldacityOS_Tier3.lua
/home/BuldacityDesktop.lua
/home/BuldacityComponentServer.lua
/home/BuldacityComponentAgent.lua
/home/BuldacityComponentDashboard.lua
/home/BuldacityAutoStart.lua
/home/BuldacityNetworkTest.lua
/home/BuldacityWirelessCheck_Modern.lua
```

Die Mod-spezifischen Dateien kommen ebenfalls nach `/home`.

## 4. Zentrale aufbauen

Baue einen Tier-3-PC mit:

```text
CPU
RAM
EEPROM/Bootmedium
Festplatte/Filesystem
GPU
Screen
Keyboard
Network Card oder Wireless Network Card
```

Für maximale Darstellung:

```text
Tier-3 GPU
Tier-3 Screen
```

## 5. Zentrale Dateien installieren

Kopiere mindestens:

```text
/home/Network.lua
/home/BuldacityUI.lua
/home/BuldacityOS_Tier3.lua
/home/BuldacityDesktop.lua
/home/BuldacityComponentServer.lua
/home/BuldacityComponentDashboard.lua
/home/BuldacityAutoStart.lua
/home/BuldacityNetworkTest.lua
/home/BuldacityWirelessCheck_Modern.lua
```

## 6. Zentrale starten

Manuell:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

`BuldacityOS_Tier3.lua` startet den Desktop aus `/home`.

## 7. Grafische Oberfläche prüfen

Nach dem Start sollte die BULDACITY-Oberfläche erscheinen.

Die wichtigsten Seiten sind:

```text
DESKTOP
NETWORK
DEVICES
REMOTE
REACTOR
```

Die Darstellung verwendet GPU-Hintergründe, Panels, Balken, Icons und Statusanzeigen.

## 8. Component-System aktivieren

Die zentrale Component-Verwaltung läuft über:

```text
/home/BuldacityComponentServer.lua
```

Der Agent auf jedem Client läuft über:

```text
/home/BuldacityComponentAgent.lua
```

Der Agent liest die OpenComputers-Component-Liste und überträgt Typ + Adresse an den Server.

Beispiel einer lokalen Prüfung:

```lua
local component=require("component")
for address,typ in component.list() do
  print(address,typ)
end
```

## 9. Component Dashboard öffnen

```lua
dofile("/home/BuldacityComponentDashboard.lua")
```

Dort können die erkannten PCs und Componenten grafisch betrachtet werden.

Eine Component wird sinngemäß angezeigt als:

```text
ICON  COMPONENT TYPE
      ID: abcdef12-....
      STATUS: ONLINE
```

## 10. Netzwerk-Topologie

### Kabel

```text
ZENTRALE
   │
 OC-Kabel
   │
 CLIENT
```

### Wireless

```text
ZENTRALE
   │
 Wireless Network Card
   )))
       (((
          CLIENT
```

### Relay

```text
ZENTRALE ── Kabel ── RELAY ))) ((( CLIENT
```

Ein Relay benötigt für einen Wireless-Pfad die passende Wireless-Hardware.

## 11. Wireless prüfen

```lua
dofile("/home/BuldacityWirelessCheck_Modern.lua")
```

Erwartete Zustände:

```text
WIRELESS READY
WIRELESS NOT READY
WIRELESS MISSING
```

`READY` bedeutet lokale Wireless-Hardware + konfigurierte Signalstärke.

Für eine echte Ende-zu-Ende-Prüfung anschließend den Netzwerk-Test ausführen.

## 12. Client-PC installieren

Jeder Mod kann einen eigenen OpenComputers-Client erhalten.

Grundausstattung:

```text
CPU + RAM + Filesystem + Network Card
```

Für lokale grafische Mod-Oberflächen:

```text
GPU + Screen + Keyboard
```

Auf jeden Netzwerk-Client kommt:

```text
/home/Network.lua
/home/BuldacityUI.lua
/home/BuldacityComponentAgent.lua
```

Danach die passende Mod-Network-Datei und den Mod-Controller.

## 13. Mod-Dateien

Die aktuelle Repo enthält unter anderem grafische Controller für:

```text
3D Printer
Applied Energistics 2
Diesel Generator
Extra Planets
Forestry
Galacticraft
Gendustry
Immersive Engineering
Immersive Integration
Immersive Railroading
IndustrialCraft 2
Logistics Pipes
Mekanism
PneumaticCraft
ProjectE
RFTools
RotaryCraft
SGCraft
Thermal Expansion
Big Reactors / Extreme Reactors
```

Je nach Mod werden die tatsächlich verfügbaren Werte automatisch über die vorhandene Component-/Adapter-API verwendet.

## 14. Beispiel: 3D Printer

```text
/home/Network.lua
/home/BuldacityUI.lua
/home/BuldacityComponentAgent.lua
/home/3DPrinterNetwork_Modern.lua
/home/3DPrinter_Modern.lua
```

Start:

```lua
dofile("/home/3DPrinterNetwork_Modern.lua")
```

## 15. Beispiel: Big Reactors

```text
/home/Network.lua
/home/BuldacityUI.lua
/home/BuldacityComponentAgent.lua
/home/ReactorBigReactors043A_Network.lua
/home/ReactorBigReactors043A_Touch_Responsive.lua
```

Die Zentrale kann gemeldete Reactor-Telemetrie als grafische Karten und Verlauf darstellen.

## 16. Beispiel: Diesel Generator

```text
/home/Network.lua
/home/BuldacityUI.lua
/home/BuldacityComponentAgent.lua
/home/DieselGeneratorNetwork_Modern.lua
/home/DieselGenerator_Modern.lua
```

Die Diesel-GUI verwendet grafische Füllstandsbalken, Statusanzeigen, Automation und Component-Erkennung.

## 17. Netzwerk starten

Zuerst Zentrale:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

Dann Client:

```lua
dofile("/home/<Mod>Network_Modern.lua")
```

BULDACITY-Netzwerk:

```text
Protokoll: BULDACITY/2
Port:      4242
```

## 18. Client entdecken

Auf der Zentrale:

```text
DESKTOP → SCAN
```

oder Netzwerk-Test:

```lua
dofile("/home/BuldacityNetworkTest.lua")
```

Der Client muss anschließend unter `DEVICES` erscheinen.

## 19. Remote-PC öffnen

1. `DESKTOP` öffnen
2. Client markieren
3. `ENTER` oder `REMOTE` verwenden
4. `REQUEST SCREEN` ausführen, falls noch kein Bild vorhanden ist

Der Client überträgt sein OpenComputers-Screen zeilenweise zur Zentrale.

## 20. Eingaben an Remote-PC senden

Die Remote-Oberfläche unterstützt die Weitergabe von Eingaben, sofern der Client die entsprechenden Signale empfängt.

Damit kann die Zentrale als Remote-Control-Station verwendet werden.

## 21. Autostart

Auf jedem Rechner:

```text
/home/BuldacityAutoStart.lua
/home/autorun.lua
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

Der Autostart verwendet `/home` als Arbeitsverzeichnis und lädt die Programme von dort.

## 22. Maximale Grafik herausholen

Für maximale Darstellung:

```text
Tier-3 GPU
Tier-3 Screen
hohe verfügbare Screen-Auflösung
Keyboard
```

Die UI verwendet:

```text
gpu.setBackground()
gpu.setForeground()
gpu.fill()
gpu.set()
```

Dadurch werden echte farbige Flächen, Balken und UI-Elemente gezeichnet.

Die gemeinsame Bibliothek ist:

```text
/home/BuldacityUI.lua
```

## 23. Was die Grafikbibliothek bereitstellt

```text
UI.panel()       Panels/Karten
UI.button()      Buttons
UI.bar()         Balken
UI.bar2()        große Balken
UI.vbar()        vertikale Balken
UI.gauge()       Messanzeige
UI.led()         Status-LED
UI.badge()       Status-Badge
UI.sparkline()   kleine Live-Kurve
UI.graph()       Live-Diagramm
UI.icon()        Pixel-Icon
UI.card()        Dashboard-Karte
```

## 24. Fehler: Network nicht gefunden

Prüfen:

```text
/home/Network.lua
```

Dann:

```lua
local shell=require("shell")
shell.setWorkingDirectory("/home")
local Network=require("Network")
print(Network.PROTOCOL)
```

Erwartet:

```text
BULDACITY/2
```

## 25. Fehler: BuldacityUI nicht gefunden

Prüfen:

```text
/home/BuldacityUI.lua
```

und:

```lua
local shell=require("shell")
shell.setWorkingDirectory("/home")
local UI=require("BuldacityUI")
print(UI.W,UI.H)
```

## 26. Fehler: kein Client

Prüfe in dieser Reihenfolge:

```text
1. Client-PC läuft
2. Network Card vorhanden
3. /home/Network.lua vorhanden
4. /home/BuldacityComponentAgent.lua vorhanden
5. passender Network-Wrapper vorhanden
6. Port 4242 geöffnet
7. Wireless-Signal > 0, falls Wireless
8. Relay/Access Point korrekt aufgebaut
9. Zentrale mit SCAN aktualisieren
10. BuldacityNetworkTest.lua ausführen
```

## 27. Fehler: Component fehlt

Lokale Komponenten anzeigen:

```lua
local component=require("component")
for address,typ in component.list() do
  print(address,typ)
end
```

Wenn der Adapter/Mod nicht auftaucht, ist zunächst die Mod-/OC-Verkabelung zu prüfen.

## 28. Vollständiger Startablauf

```text
Minecraft 1.7.10
 ↓
Forge
 ↓
OpenComputers
 ↓
Tier-3-Zentrale
 ↓
/home/Network.lua
 ↓
/home/BuldacityUI.lua
 ↓
/home/BuldacityComponentServer.lua
 ↓
/home/BuldacityOS_Tier3.lua
 ↓
BULDACITY v9 Desktop
 ↓
Wireless / Netzwerk prüfen
 ↓
Client-PC starten
 ↓
Component Agent
 ↓
Mod-Network-Wrapper
 ↓
BULDACITY/2 : 4242
 ↓
DESKTOP / DEVICES
 ↓
PING/PONG
 ↓
REMOTE
 ↓
Reactor / Mod Dashboard
 ↓
Autostart
```

## 29. Abschlussprüfung

- [ ] `/home/Network.lua`
- [ ] `/home/BuldacityUI.lua`
- [ ] `/home/BuldacityOS_Tier3.lua`
- [ ] `/home/BuldacityDesktop.lua`
- [ ] `/home/BuldacityComponentServer.lua`
- [ ] `/home/BuldacityComponentAgent.lua`
- [ ] `/home/BuldacityComponentDashboard.lua`
- [ ] GPU + Screen vorhanden
- [ ] lokale Mod-Komponente erkannt
- [ ] Wireless bereit, falls benötigt
- [ ] Client erscheint unter `DEVICES`
- [ ] Heartbeat läuft
- [ ] PING/PONG funktioniert
- [ ] Component IDs erscheinen
- [ ] Remote-Screen funktioniert
- [ ] Touch/Keyboard funktioniert
- [ ] Autostart funktioniert

## 30. Wichtig

BULDACITY v9 ist eine GPU-basierte Zeichenoberfläche für OpenComputers. Sie nutzt die tatsächlich verfügbaren GPU-/Screen-Funktionen und keine moderne Desktop-Grafik-Engine.

Das bedeutet: Die UI kann sehr weit grafisch gehen, bleibt aber an die OpenComputers-GPU- und Screen-Grenzen von Minecraft 1.7.10 gebunden.

**Grundregel: Alle BULDACITY-Dateien nach `/home`. Keine `/lib`-Loader verwenden.**
