# BULDACITY – Schritt für Schritt

## Phase 1 – Minecraft

1. Minecraft `1.7.10` installieren.
2. Forge `10.13.4.1614` installieren.
3. OpenComputers für 1.7.10 installieren.
4. Die benötigten Mods und die im Projekt vorgesehenen Versionen installieren.
5. Minecraft einmal starten und prüfen, dass Forge/OpenComputers ohne Fehler laden.

## Phase 2 – Zentrale bauen

1. Tier-3-OpenComputers-Computer bauen.
2. CPU einsetzen.
3. ausreichend RAM einsetzen.
4. Speicher einsetzen.
5. GPU einsetzen.
6. Screen anschließen.
7. Keyboard anschließen.
8. Network Card oder Wireless Network Card einsetzen.
9. OpenOS starten.

## Phase 3 – BULDACITY-Dateien installieren

Nach `/home` kopieren:

```text
Network.lua
BuldacityOS_Tier3.lua
BuldacityUI.lua
BuldacityComponentDashboard.lua
BuldacityAutoStart.lua
```

Zentrale manuell starten:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

## Phase 4 – Ersten Mod-Controller bauen

1. Einen normalen OpenComputers-PC bauen.
2. CPU, RAM und Speicher einsetzen.
3. Für eine grafische Oberfläche GPU + Screen anschließen.
4. Network Card/Wireless Network Card einsetzen.
5. `Network.lua` nach `/home` kopieren.
6. Den passenden Network-Controller nach `/home` kopieren.
7. Den passenden Mod-Controller nach `/home` kopieren.

## Phase 5 – Mod anschließen

Wenn der Mod eine direkte OC-Komponente liefert, diese direkt verwenden.

Wenn ein Adapter benötigt wird:

```text
Computer ── OC-Kabel ── Adapter ── Mod-Block
```

Danach:

```lua
component.list()
```

Nur Komponenten verwenden, die wirklich angezeigt werden.

## Phase 6 – Lokale GUI testen

1. passenden `*_Modern.lua` Controller starten.
2. GUI prüfen.
3. `SCAN`/Rescan ausführen.
4. erkannte Komponenten prüfen.
5. Steuerung zunächst manuell testen.
6. erst bei korrekter Hardwareerkennung Netzwerk aktivieren.

Die gemeinsame GUI-Basis ist `BuldacityUI.lua`. Sie stellt Panels, Statusanzeigen, Buttons, Balken und Touch-Hitboxen bereit.

## Phase 7 – Netzwerk testen

1. Tier-3-Zentrale starten.
2. Client starten.
3. Der Client meldet sich über `BULDACITY/2` auf Port `4242` an.
4. In `DEVICES` prüfen.
5. Heartbeat abwarten.
6. Client auswählen.
7. `REMOTE` öffnen.
8. Bildschirm testen.
9. Touch/Tastatur testen.

## Phase 8 – Big Reactors

Dateien:

```text
ReactorBigReactors043A_Touch_Responsive.lua
ReactorBigReactors043A_Network.lua
```

Komponenten:

```text
br_reactor
br_turbine
```

Lokale Tabs:

```text
CORE | RODS | TURBINE
```

Vor AUTO-Betrieb zuerst manuell testen und die Sicherheitsgrenzen kontrollieren.

## Phase 9 – Autostart

`BuldacityAutoStart.lua` als `/home/autorun.lua` installieren.

### Zentrale

`/home/buldacity-role.cfg`:

```text
ROLE=SERVER
```

### Client

Beispiel:

```text
ROLE=CLIENT
CLIENT=BigReactors
```

Der Launcher sucht Programme robust in `/home`, `/` und über die OpenOS-Pfadauflösung.

## Phase 10 – Weitere Controller

Diesen Ablauf für jeden weiteren Mod wiederholen:

```text
Mod installieren
      ↓
OC-Komponente / Adapter
      ↓
component.list()
      ↓
lokale Modern-GUI
      ↓
Network-Controller
      ↓
BULDACITY/2
      ↓
Tier-3 DEVICES
      ↓
REMOTE
      ↓
Steuerung
      ↓
Autostart
```

Unterstützte Controller-Familien umfassen aktuell unter anderem AE2, Big Reactors, Diesel Generator/Immersive Engineering, ExtraPlanets, Forestry, Galacticraft, Gendustry, Immersive Integration, Immersive Railroading, IC2, LogisticsPipes, Mekanism, PneumaticCraft, ProjectE, RFTools, RotaryCraft, SGCraft, Thermal Expansion und den OpenComputers 3D Printer.

## Phase 11 – Wenn etwas nicht funktioniert

### Datei nicht gefunden

Dateien bevorzugt nach `/home` kopieren. Keine alten festen Root-Pfade verwenden.

### Komponente nicht gefunden

```lua
component.list()
```

Danach Adapter, Kabel und vorhandene Driver/Integration prüfen.

### Netzwerk nicht gefunden

- Network Card prüfen.
- `Network.lua` prüfen.
- Port `4242` prüfen.
- Zentrale zuerst starten.
- Client danach starten.

### Remote-Bildschirm leer

- Client-GPU prüfen.
- Client-Screen prüfen.
- Network-Controller prüfen.
- Client unter `DEVICES` registriert?

## Phase 12 – Abschlussprüfung

Am Ende müssen folgende Punkte funktionieren:

- Minecraft/Forge startet.
- OpenComputers startet.
- lokale Mod-GUI startet.
- Komponenten werden erkannt.
- Network-Controller startet ohne `file not found`.
- Client erscheint unter `DEVICES`.
- Heartbeat bleibt aktiv.
- Remote-Bildschirm funktioniert.
- Eingaben werden weitergeleitet.
- Autostart funktioniert nach Neustart.

## Aktueller BULDACITY-Stand

- zentraler Tier-3-Desktop: `BuldacityOS_Tier3.lua`
- Netzwerk: `Network.lua`
- Protokoll: `BULDACITY/2`
- Port: `4242`
- gemeinsames Design: `BuldacityUI.lua`
- generisches Dashboard: `BuldacityComponentDashboard.lua`
- Autostart: `BuldacityAutoStart.lua`
- Big Reactors: `ReactorBigReactors043A_Touch_Responsive.lua` + Network-Bridge
