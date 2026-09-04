# Buldacity – komplette Schritt-für-Schritt-Anleitung

Diese Anleitung beschreibt den **aktuellen** Stand von `xDarkixx/lua2` für Minecraft 1.7.10.

## 1. Voraussetzungen

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für 1.7.10
- die jeweils benötigten Mod-Versionen
- für Netzwerk: Network Card oder Wireless Network Card

## 2. Zuerst die Zentrale bauen

Tier-3-Computer:

```text
Tier-3 Computer
├── CPU
├── RAM
├── Speicher
├── GPU
├── Screen
├── Keyboard
└── Network/Wireless Network Card
```

Nach `/home` kopieren:

```text
Network.lua
BuldacityOS_Tier3.lua
BuldacityUI.lua
BuldacityComponentDashboard.lua
BuldacityAutoStart.lua
```

Start:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

## 3. Danach einen Controller-PC bauen

Für jeden Mod einen normalen OpenComputers-PC verwenden.

```text
Controller-PC
├── CPU
├── RAM
├── Speicher
├── GPU + Screen (für grafische Controller)
└── Network Card/Wireless Network Card
```

Nach `/home` kopieren:

```text
Network.lua
passender *Network*.lua Controller
passender *_Modern.lua Controller
```

## 4. Mod-Komponente anschließen

Wenn der Mod bereits eine direkte OC-Komponente bereitstellt, ist kein Adapter nötig.

Wenn es ein unterstützter Mod-Block ohne direkte OC-Komponente ist:

```text
Computer -> OC-Kabel -> Adapter -> Mod-Block
```

Danach immer einen Scan durchführen. Ein Adapter stellt nur die Schnittstelle bereit, wenn ein passender Driver vorhanden ist.

## 5. Controller starten

Zentrale:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

Beispiel Big Reactors Network:

```lua
dofile("/home/ReactorBigReactors043A_Network.lua")
```

Andere Network-Controller funktionieren nach demselben Prinzip.

## 6. Ersten Netzwerktest durchführen

1. Nur die Zentrale starten.
2. Einen einzigen Controller starten.
3. Prüfen, ob `NETWORK` eine Verbindung meldet.
4. `DEVICES` öffnen.
5. Warten, bis der Client per HELLO/Heartbeat erscheint.
6. Client auswählen.
7. `REMOTE` öffnen.
8. Bildschirm und Eingaben testen.
9. Erst danach weitere Controller starten.

## 7. Big Reactors 0.4.3A

Dateien:

```text
ReactorBigReactors043A_Touch_Responsive.lua
ReactorBigReactors043A_Network.lua
```

Lokale Oberfläche:
- CORE
- RODS
- TURBINE

Daten/Steuerung:
- Reaktorstatus
- Energie
- Brennstoff
- Temperatur
- Control Rods
- AUTO
- Sicherheitsabschaltung
- Turbinenstatus
- Rotor Speed
- Output
- Fluid Flow
- Inductor

## 8. Grafisches Design

Die neuen gemeinsamen UI-Bausteine liegen in:

```text
BuldacityUI.lua
BuldacityComponentDashboard.lua
```

Das Design verwendet:
- einheitliche BULDACITY-Kopfzeile
- farbige Statusanzeigen
- Panels
- Buttons
- Fortschrittsbalken
- Touch-Zonen
- responsive Anpassung an die verfügbare GPU-Auflösung
- API-/Komponentenansicht

Die aufwendigeren Spezial-Controller behalten ihre mod-spezifische Oberfläche.

## 9. Autostart einrichten

`BuldacityAutoStart.lua` als `/home/autorun.lua` installieren.

Zentrale:

```text
ROLE=SERVER
```

Client, Beispiel:

```text
ROLE=CLIENT
CLIENT=BigReactors
```

Die verfügbaren Client-Namen stehen in `BuldacityAutoStart.lua`.

## 10. Installation weiterer Mods

Für jeden Mod gilt dasselbe Grundprinzip:

**Mod installieren → OC-Komponente/Adapter anschließen → Scan → lokalen Controller prüfen → Network-Controller starten → Zentrale prüfen → Remote testen.**

Unterstützte Familien im aktuellen Projekt umfassen unter anderem:

- Applied Energistics 2
- Big Reactors
- Diesel Generator / Immersive Engineering
- ExtraPlanets
- Forestry
- Galacticraft
- Gendustry
- Immersive Integration
- Immersive Railroading
- IndustrialCraft 2
- LogisticsPipes
- Mekanism
- PneumaticCraft
- ProjectE
- RFTools
- RotaryCraft
- SGCraft
- Thermal Expansion
- OpenComputers 3D Printer

## 11. Fehler: Datei nicht gefunden

Programme bevorzugt nach `/home` kopieren.

Bei Network-Wrappern und Autostart wird die Datei robust gesucht. Keine festen Annahmen über einen einzigen Installationspfad treffen.

## 12. Fehler: Mod-Komponente fehlt

1. `component.list()` prüfen.
2. Adapter direkt neben den Mod-Block setzen.
3. OC-Kabel prüfen.
4. passenden Driver/Integration prüfen.
5. Controller-Scan erneut ausführen.

## 13. Fehler: Netzwerk fehlt

1. Network Card/Wireless Card prüfen.
2. `Network.lua` prüfen.
3. Port `4242` prüfen.
4. Zentrale zuerst starten.
5. Client danach starten.
6. `DEVICES` beobachten.

## 14. Fehler: Remote-Bildschirm leer

- Client braucht GPU/Screen.
- Network-Controller muss laufen.
- Client muss bereits registriert sein.
- Remote erst danach öffnen.

## 15. Automatischer Kompletttest

Nach der Installation in dieser Reihenfolge testen:

```text
[1] Minecraft/Forge
        ↓
[2] OpenComputers
        ↓
[3] Mod-Komponenten
        ↓
[4] Lokaler Controller
        ↓
[5] Network-Controller
        ↓
[6] BULDACITY Tier-3
        ↓
[7] DEVICES
        ↓
[8] REMOTE
        ↓
[9] Steuerung
        ↓
[10] Autostart
```

## 16. Aktuelle Architektur

Es gibt **einen** BULDACITY-Server und beliebig viele Controller-Clients.

```text
                 BULDACITY TIER-3
               BuldacityOS + Network
                       │
             BULDACITY/2 : 4242
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
      AE2 PC        Reactor PC     Mekanism PC
        │              │              │
     Mod-Gerät      Reactor/Turbine  Mod-Gerät
```

Die Maschine wird lokal gesteuert; BULDACITY stellt die zentrale Anzeige, Überwachung und Remote-Bedienung bereit.
