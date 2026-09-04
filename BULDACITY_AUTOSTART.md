# BULDACITY Autostart – Schritt für Schritt

`BuldacityAutoStart.lua` ist der gemeinsame Boot-Launcher für BULDACITY/2.

## 1. Datei installieren

`BuldacityAutoStart.lua` nach `/home/autorun.lua` kopieren.

Der Launcher wartet kurz nach dem Boot, damit OpenComputers und Netzwerk-Komponenten initialisiert sind.

## 2. Zentrale konfigurieren

Datei `/home/buldacity-role.cfg` anlegen:

```text
ROLE=SERVER
```

Nach dem Neustart wird gestartet:

```text
BuldacityOS_Tier3.lua
```

## 3. Client konfigurieren

Datei `/home/buldacity-role.cfg`:

```text
ROLE=CLIENT
CLIENT=BigReactors
```

Dadurch wird automatisch gestartet:

```text
ReactorBigReactors043A_Network.lua
```

## 4. Unterstützte Client-Namen

- `3DPrinter`
- `AE2`
- `DieselGenerator`
- `ExtraPlanets`
- `Forestry`
- `Galacticraft`
- `Gendustry`
- `ImmersiveEngineering`
- `ImmersiveIntegration`
- `ImmersiveRailroading`
- `IndustrialCraft2`
- `LogisticsPipes`
- `Mekanism`
- `PneumaticCraft`
- `ProjectE`
- `RFTools`
- `RotaryCraft`
- `SGCraft`
- `ThermalExpansion`
- `BigReactors`

## 5. Pfadauflösung

Der Launcher sucht Programme in dieser Reihenfolge:

1. `/home/<programm>`
2. `/<programm>`
3. über die OpenOS-Pfadauflösung

Damit wird der frühere Fehler mit fest verdrahteten Root-Pfaden vermieden.

## 6. Empfehlung

Alle BULDACITY-Programme bevorzugt unter `/home` installieren. `Network.lua` muss bei Network-Controllern ebenfalls erreichbar sein.

## 7. Kontrolle nach Neustart

### Server
- BULDACITY Desktop erscheint.
- `NETWORK` öffnen.
- `DEVICES` öffnen.

### Client
- Network-Controller startet.
- Client erscheint nach HELLO/Heartbeat auf der Zentrale.
- `REMOTE` kann danach getestet werden.

Der Autostart verändert die eigentlichen `_Modern.lua` Controller nicht.
