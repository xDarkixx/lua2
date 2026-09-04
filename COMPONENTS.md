# OpenComputers Komponenten & Anschlussübersicht

Diese Übersicht erklärt für die Lua-Programme in diesem Repository, welche OpenComputers-Komponenten benötigt werden und wie sie aufgebaut werden.

> **Wichtig:** Die Nummern `1`, `2`, `3` usw. sind hier Anschluss-/Komponenten-Positionen in der Anleitung. OpenComputers verwendet für die eigentliche Kommunikation Adressen. Eine Komponente muss nicht zwingend an einem bestimmten physikalischen Seitenslot sitzen, solange sie vom Computer/Netzwerk erreichbar ist.

## 1. Grundaufbau

Für alle Touchscreen-Dashboards ist der Grundaufbau:

```text
[Touchscreen]
      │
      │ OC-Netzwerk
      ▼
[Computer] ─── [GPU]
      │
      ├── [Ziel-Komponente / Adapter]
      │
      └── optional [Redstone / weitere OC-Komponente]
```

### Komponenten

| Nr. | Komponente | Zweck |
|---|---|---|
| 1 | OpenComputers Computer | Führt das Lua-Programm aus |
| 2 | GPU | Zeichnet die Benutzeroberfläche |
| 3 | Screen / Touchscreen | Anzeige und Touch-Eingaben |
| 4 | Mod-Komponente bzw. Adapter | Verbindung zur Maschine |
| 5 | optional Redstone | Ein/Aus-Steuerung, wenn die Maschine nicht direkt steuerbar ist |

Die genaue OC-Komponenten-Adresse ist nicht fest vorgegeben. Die Programme suchen bzw. verwenden die jeweilige Komponente über ihren Typ bzw. ihre Adresse.

---

## 2. Big Reactors / Reactor

### Benötigt

1. OpenComputers Computer
2. GPU
3. Screen / Touchscreen
4. `br_reactor`-Komponente
5. optional `br_turbine`-Komponente

### Anschluss

```text
1. Computer
   │
2. GPU ─── 3. Screen
   │
4. br_reactor
   │
5. optional br_turbine
```

Der Reaktor muss über eine OpenComputers-kompatible Verbindung erreichbar sein. Die Reactor-Skripte suchen nach `br_reactor`.

### Funktionen

- Reaktorstatus EIN/AUS
- Energie
- Brennstoff
- Abfall
- Brennstofftemperatur
- Gehäusetemperatur
- Control-Rods
- Control-Rod Auswahl
- Control-Rod +/- Steuerung
- alle Rods auf 0/100 %
- mehrere Reaktoren auswählen
- optional Turbine
- automatische Regelung in der Responsive-Version

### Wichtiger Punkt

Die Control-Rod-Indizes bei Big Reactors 0.4.3A beginnen bei **0**. Also:

```text
Rod 0 = erste Control Rod
Rod 1 = zweite Control Rod
Rod 2 = dritte Control Rod
...
```

---

## 3. Applied Energistics 2

### Benötigt

1. OpenComputers Computer
2. GPU
3. Screen / Touchscreen
4. `me_controller`

### Anschluss

```text
1. Computer
   │
2. GPU ─── 3. Screen
   │
4. me_controller
   │
   └── AE2 ME Netzwerk
```

Der `me_controller` muss Teil des AE2-ME-Netzwerks sein und für OpenComputers erreichbar sein.

### Funktionen

- ME-Netzwerkstatus
- gespeicherte Item-Typen
- Craftable-Typen
- Item-Übersicht
- Crafting-Übersicht
- Netzwerk-Refresh
- Touch-Navigation
- automatische Aktualisierung

### Dateien

- `AE2Network.lua` – ursprüngliches Dashboard
- `AE2Network_Modern.lua` – modernes LED-/Sci-Fi-Dashboard

---

## 4. Immersive Engineering Diesel Generator

### Benötigt

1. OpenComputers Computer
2. GPU
3. Screen / Touchscreen
4. `ie_diesel_generator`

### Anschluss

```text
1. Computer
   │
2. GPU ─── 3. Screen
   │
4. ie_diesel_generator
```

Der Dieselgenerator benötigt seine normale Immersive-Engineering-Versorgung. Das Lua-Programm steuert die OpenComputers-Komponente und nicht den Aufbau des IE-Stromnetzes.

### Funktionen

- Generatorstatus
- Diesel-/Tankfüllstand
- Fluidname
- EIN/AUS
- AUTO/MANUAL
- Füllstandsgrenzen
- Refresh
- Touch-Steuerung

### AUTO

Die moderne Version verwendet eine Hysterese:

```text
Tank <= 10 %  → Generator AUS
Tank >= 20 %  → Generator EIN
```

Dadurch wird verhindert, dass der Generator bei genau einem Grenzwert ständig zwischen EIN und AUS wechselt.

---

## 5. RotaryCraft

RotaryCraft stellt nicht für jede Maschine eine einheitliche OpenComputers-Komponente mit identischen Methoden bereit. Deshalb ist der Aufbau hier etwas anders.

### Grundaufbau

1. OpenComputers Computer
2. GPU
3. Screen / Touchscreen
4. optional Redstone-Komponente
5. RotaryCraft-Maschine bzw. RotaryCraft-Power-Netzwerk

```text
1. Computer
   │
2. GPU ─── 3. Screen
   │
4. optional Redstone
   │
5. RotaryCraft-Maschine
```

### Funktionen

- RotaryCraft-Version anzeigen
- OpenComputers-Komponentenstatus
- Redstone-Ausgang EIN/AUS
- manueller Modus
- AUTO-Modus für das vorhandene Steuersignal
- Status-/Informationsanzeige

**Nicht behaupten:** Es gibt keine universelle RotaryCraft-OC-Methode, mit der jedes RotaryCraft-Gerät direkt per `setActive()` gesteuert werden kann. Deshalb wird für generische RotaryCraft-Steuerung kein nicht vorhandener Maschinen-API-Aufruf erfunden.

---

## 6. Welche Datei für welches System?

| System | Basisprogramm | Moderne Oberfläche |
|---|---|---|
| Big Reactors | `Reactor.lua` / `ReactorBigReactors043A_Touch_v3.lua` | `ReactorBigReactors043A_Touch_Responsive.lua` |
| AE2 | `AE2Network.lua` | `AE2Network_Modern.lua` |
| Immersive Engineering | `DieselGenerator.lua` | `DieselGenerator_Modern.lua` |
| RotaryCraft | `RotaryCraft.lua` / `RotaryCraftDashboard.lua` | `RotaryCraftDashboard_Modern.lua` |

Die ursprünglichen Dateien bleiben als Referenz erhalten. Die modernen Varianten sind separat benannt.

---

## 7. OpenComputers Bildschirm-Aufbau

Für einen normalen Touchscreen:

```text
Computer
  │
  ├── GPU
  │    │
  │    └── Screen
  │
  └── Mod-Komponente
       ├── br_reactor
       ├── me_controller
       ├── ie_diesel_generator
       └── RotaryCraft/Redstone
```

Bei mehreren Maschinen können mehrere Komponenten am gleichen OC-Netzwerk hängen. Bei Big Reactors kann das Programm mehrere `br_reactor`-Komponenten erkennen und zwischen ihnen wechseln.

---

## 8. Erst anschließen, dann starten

### Schritt 1
Computer aufstellen.

### Schritt 2
GPU mit dem Computer verbinden.

### Schritt 3
Screen/Touchscreen mit der GPU verbinden.

### Schritt 4
Die passende Mod-Komponente anschließen bzw. über den OC-Netzwerkaufbau erreichbar machen.

### Schritt 5
Prüfen, dass die Lua-Datei auf dem OpenComputers-Computer vorhanden ist.

### Schritt 6
Das passende Programm starten.

### Schritt 7
Wenn **kein Gerät gefunden** wird, zuerst die Komponente bzw. den Adapter und die Netzwerkverbindung prüfen.

---

## 9. Schnellübersicht

```text
REACTOR:
Computer + GPU + Screen + br_reactor
                         └─ optional br_turbine

AE2:
Computer + GPU + Screen + me_controller + AE2 ME Network

DIESEL:
Computer + GPU + Screen + ie_diesel_generator

ROTARYCRAFT:
Computer + GPU + Screen + optional Redstone
                         └─ RotaryCraft-Maschine
```

## Kompatibilitätsziel

Die Skripte in diesem Repository zielen auf die im jeweiligen Programm angegebenen Minecraft-/Mod-Versionen, insbesondere Minecraft 1.7.10 und OpenComputers 1.8.10. Vor dem Einsatz sollte die tatsächlich installierte Mod-Version mit der Versionsangabe im jeweiligen Lua-Programm verglichen werden.
