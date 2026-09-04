# OpenComputers Komponenten & Anschlussübersicht

Diese Übersicht erklärt die OpenComputers-Komponenten für die Lua-Programme in diesem Repository.

## Grundaufbau

```text
[Touchscreen]
      │
[Computer] ─── [GPU]
      │
      ├── [Mod-Komponente / Adapter]
      └── [Network Card / Wireless Network Card]
```

## Immersive Engineering 0.7.7

Ziel: `ImmersiveEngineering-0.7.7.jar`, Minecraft 1.7.10.

Der vorhandene Diesel-Generator-Controller bleibt getrennt. `ImmersiveEngineering_Modern.lua` übernimmt die übrigen zur Laufzeit erkennbaren IE-Komponenten und zeigt nur deren tatsächlich exponierte OpenComputers-Methoden.

- `ImmersiveEngineering_Modern.lua` – lokale Buldacity-Version
- `ImmersiveEngineering_Network_Modern.lua` – Tier-2-Netzwerkversion
- Live-Komponentenscan alle 2 Sekunden
- Energie-/Fluid-/Redstone-/Inventory-relevante APIs werden erkannt, wenn sie exponiert sind

## Immersive Integration 0.6.8

Ziel: `immersiveintegration-0.6.8.jar`, Minecraft 1.7.10. Immersive Integration erweitert Immersive Engineering und stellt zusätzliche Integrations-/Transport-/Energie-Inhalte bereit.

- `ImmersiveIntegration_Modern.lua` – lokale Version
- `ImmersiveIntegration_Network_Modern.lua` – Tier-2-Netzwerkversion
- dynamische OC-Komponentenerkennung
- API-Anzeige ausschließlich für tatsächlich vorhandene Methoden

## Immersive Railroading 1.7.10-forge-1.9.1

- `ImmersiveRailroading_Modern.lua` – lokale Version
- `ImmersiveRailroading_Network_Modern.lua` – Tier-2-Netzwerkversion
- Live-Erkennung von Rail-/Train-/Track-/Locomotive-relevanten OC-Endpunkten
- keine erfundenen Steuerfunktionen: nur installierte OC-API wird angezeigt

## IndustrialCraft 2 2.2.827 Experimental

Ziel: `industrialcraft-2-2.2.827-experimental.jar`, Minecraft 1.7.10.

- `IndustrialCraft2_Modern.lua` – lokale Buldacity-Version
- `IndustrialCraft2_Network_Modern.lua` – Tier-2-Netzwerkversion
- Live-Erkennung von IC2-/EU-/Energy-/Inventory-/Fluid-/Charge-APIs
- nur tatsächlich exponierte Methoden werden angezeigt

## Komponentenliste

Bei allen neuen Controllern wird `component.list()` regelmäßig neu ausgewertet. Neue oder entfernte OpenComputers-Komponenten werden dadurch während des laufenden Programms automatisch übernommen.

## Netzwerk

```text
Tier-3 Server
     │
 Wireless Network
     │
     ├──────── Tier-2 Immersive Engineering
     ├──────── Tier-2 Immersive Integration
     ├──────── Tier-2 Immersive Railroading
     └──────── Tier-2 IndustrialCraft 2
```

Die Netzwerkversionen starten den gemeinsamen `BuldacityNetworkClient` und registrieren den jeweiligen Controller am Tier-3-Server.

## LogisticsPipes 0.9.3.132

Ziel: `logisticspipes-0.9.3.132.jar`, Minecraft 1.7.10.

LogisticsPipes besitzt eine OpenComputers-Integrationsschicht. Der Controller verwendet deshalb dynamische Erkennung statt einer festen, möglicherweise falschen Komponentenadresse.

- `LogisticsPipes_Modern.lua`
- `LogisticsPipesNetwork_Modern.lua`
- Live-Komponentenbus
- automatischer Scan alle 2 Sekunden
- API-/Inventory-/Request-/Crafting-Erkennung
- Tier-2/Tier-3-Betrieb

## PneumaticCraft

```text
Computer + GPU + Screen + PneumaticCraft-OC-Anschluss
                         └─ Drone / Drone Interface
```

## Big Reactors

```text
Computer + GPU + Screen + br_reactor
                         └─ optional br_turbine
```

## AE2

```text
Computer + GPU + Screen + me_controller + AE2 ME Network
```

## Diesel Generator

```text
Computer + GPU + Screen + ie_diesel_generator
```

Der Diesel Generator wird nicht doppelt in den neuen IE-Controller integriert.

## RotaryCraft

```text
Computer + GPU + Screen + optional Redstone
                         └─ RotaryCraft-Maschine
```
