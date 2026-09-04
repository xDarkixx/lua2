# OpenComputers Komponenten & Anschlussübersicht

## 1. Grundaufbau

```text
                 ┌── GPU ── Screen ── Keyboard
[OpenComputers PC]
        │
        ├── direkte OC-Komponente
        │
        ├── OC-Kabel ── Adapter ── Mod-Block
        │
        └── Network Card / Wireless Network Card
```

## 2. Zentrale

Die zentrale Maschine ist ein Tier-3-PC mit:
- GPU
- Screen
- Keyboard
- Network/Wireless Network Card
- `Network.lua`
- `BuldacityOS_Tier3.lua`
- optional `BuldacityUI.lua`

## 3. Lokale Controller

Jeder Mod kann auf einem eigenen normalen OpenComputers-PC laufen. Die Mod-Logik bleibt dort lokal.

## 4. Netzwerk

```text
Tier-3 BULDACITY
       │
       │ BULDACITY/2 :4242
       ├── AE2 Client
       ├── Big Reactors Client
       ├── Mekanism Client
       ├── Thermal Client
       └── weitere Clients
```

## 5. Relevante Komponenten

### Big Reactors
```text
br_reactor
br_turbine
```

### Diesel Generator / Immersive Engineering
```text
ie_diesel_generator
```

### AE2
Je nach Installation werden die tatsächlich exponierten AE2-Komponenten verwendet. Keine feste Komponente annehmen, sondern Scan durchführen.

### 3D Printer
```text
printer3d
```

### Netzwerk
```text
modem
```

## 6. Adapter

Ein Adapter macht einen unterstützten Nicht-OC-Mod-Block als Komponente verfügbar. Ein Adapter allein garantiert keine vollständige Mod-API; der installierte Driver entscheidet, welche Methoden tatsächlich verfügbar sind.

Deshalb immer:

**Adapter anschließen → `component.list()` → Controller-Scan → API prüfen.**

## 7. Grafik

Die gemeinsame Oberfläche befindet sich in `BuldacityUI.lua`.

Sie stellt bereit:
- BULDACITY Header
- Panels
- Status-Badges
- Buttons
- Fortschrittsbalken
- responsive Auflösung
- Touch-Hitboxen
- einheitliche Farben

`BuldacityComponentDashboard.lua` verwendet diese Basis für generische Komponenten-Dashboards.

## 8. Big Reactors Grafik

`ReactorBigReactors043A_Touch_Responsive.lua` besitzt eine eigene spezialisierte Oberfläche mit:
- CORE
- RODS
- TURBINE
- Live-Telemetrie
- Steuerbuttons

## 9. Mod-Familien

Für die Projekt-Controller sind unter anderem vorgesehen:

- AE2
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
- 3D Printer

## 10. Diagnose

Auf einem OpenComputers-PC:

```lua
component.list()
component.list("modem")
component.list("br_reactor")
component.list("br_turbine")
```

Danach den jeweiligen Controller starten und nur die tatsächlich gefundenen Methoden verwenden.
