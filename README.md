# lua2

OpenComputers Lua-Programme für Minecraft 1.7.10 und die im jeweiligen Script angegebenen Mod-Versionen.

## Systeme

- **Big Reactors** – Reaktor-Dashboard, Control-Rods, Status, Energie, Brennstoff und automatische Regelung
- **Applied Energistics 2** – ME-Netzwerk, Items und Craftables
- **Immersive Engineering 0.7.7** – Buldacity-Dashboard für IE-Komponenten; Diesel Generator bleibt im bestehenden Spezialcontroller
- **Immersive Integration 0.6.8** – Live-Dashboard für tatsächlich exponierte IE-Integrationen
- **Immersive Railroading 1.7.10-forge-1.9.1** – Live-Dashboard für tatsächlich exponierte Rail-/Train-Komponenten
- **IndustrialCraft 2 2.2.827 Experimental** – Live-Dashboard für tatsächlich exponierte IC2/EU/Inventory/Fluid-Komponenten
- **RotaryCraft** – Dashboard und optionale Redstone-Steuerung
- **Mekanism** – gemeinsames Buldacity-Dashboard für Mekanism-Komponenten
- **Thermal** – gemeinsames Buldacity-Dashboard für Thermal-Systeme
- **ProjectE** – Buldacity-Komponenten-Dashboard
- **RFTools** – Buldacity-Komponenten-Dashboard
- **SGCraft** – Stargate-Dashboard mit OpenComputers-Anbindung
- **PneumaticCraft** – OpenComputers-Dashboard und Netzwerksteuerung
- **LogisticsPipes** – Live-Komponenten-/API-Dashboard und Netzwerksteuerung
- **Galacticraft** – Buldacity-Dashboard und Netzwerk-Controller
- **ExtraPlanets** – Galacticraft-Addon-Dashboard und Netzwerk-Controller
- **Forestry** – Buldacity-Dashboard und Netzwerk-Controller
- **Gendustry** – Forestry-Addon-Dashboard und Netzwerk-Controller
- **OpenComputers 3D Printer** – Buldacity-Dashboard für `printer3d`

## Neue Mod-Controller

### Galacticraft
- `Galacticraft_Modern.lua`
- `GalacticraftNetwork_Modern.lua`
- Zielversion: `GalacticraftCore-1.7-3.0.12.504` + `Galacticraft-Planets-1.7-3.0.12.504`

### ExtraPlanets
- `ExtraPlanets_Modern.lua`
- `ExtraPlanetsNetwork_Modern.lua`
- Zielversion: `ExtraPlanets-1.7.10-2.1.4`

### Forestry
- `Forestry_Modern.lua`
- `ForestryNetwork_Modern.lua`
- Zielversion: `forestry_1.7.10-4.2.16.64`

### Gendustry
- `Gendustry_Modern.lua`
- `GendustryNetwork_Modern.lua`
- Zielversion: `gendustry-1.6.4.135-mc1.7.10`

Die Controller arbeiten bewusst mit Live-OpenComputers-Komponentenerkennung. Sie behaupten keine Mod-API, die auf der konkreten Installation nicht tatsächlich vorhanden ist.

## Immersive / IC2 Controller

- `ImmersiveEngineering_Modern.lua`
- `ImmersiveEngineering_Network_Modern.lua`
- `ImmersiveIntegration_Modern.lua`
- `ImmersiveIntegration_Network_Modern.lua`
- `ImmersiveRailroading_Modern.lua`
- `ImmersiveRailroading_Network_Modern.lua`
- `IndustrialCraft2_Modern.lua`
- `IndustrialCraft2_Network_Modern.lua`

## Buldacity Netzwerk

Buldacity kann mehrere Tier-2-OpenComputers als Controller mit einem Tier-3-OpenComputers als zentralem Server verbinden.

- `BuldacityServer_Tier3.lua` – PC-artiger Tier-3-Server-Desktop
- `BuldacityNetworkClient.lua` – gemeinsamer Netzwerkdienst
- `BuldacityNetworkLauncher.lua` – gemeinsamer Netzwerk-Wrapper
- `BuldacityControllerLauncher.lua` – zentraler Desktop-Launcher
- `BULDACITY_NETWORK.md` – Netzwerkbeschreibung

## Schritt-für-Schritt Dokumentation

**Kompletter Grundaufbau:**

[BULDACITY_SETUP_GUIDE.md](BULDACITY_SETUP_GUIDE.md)

**Neue Mod-Familien – Galacticraft / ExtraPlanets / Forestry / Gendustry:**

[BULDACITY_MOD_SETUP_ADDONS.md](BULDACITY_MOD_SETUP_ADDONS.md)

Die Zusatzanleitung erklärt Installationsreihenfolge, Adapter, OC-Kabel, direkte OC-Komponenten, lokale Controller und Netzwerk-Controller. OpenComputers dokumentiert den Adapter als Schnittstelle für unterstützte Nicht-Komponenten-Blöcke; ein passender Driver muss vorhanden sein.

## Netzwerkstandard

- **Protokoll:** `BULDACITY/1`
- **Port:** `4242`
- **Hardware:** Network Card oder Wireless Network Card auf Tier 2 und Tier 3
- **Remote:** Tastatur, Touch und Scroll können vom Tier 3 zum ausgewählten Tier 2 weitergeleitet werden

## Moderne Dashboards

- `ReactorBigReactors043A_Touch_Responsive.lua`
- `AE2Network_Modern.lua`
- `DieselGenerator_Modern.lua`
- `RotaryCraftDashboard_Modern.lua`
- `Mekanism_Modern.lua`
- `Thermal_Modern.lua`
- `ProjectE_Modern.lua`
- `RFTools_Modern.lua`
- `SGCraft_Modern.lua`
- `ThermalExpansion_Modern.lua`
- `PneumaticCraft_Modern.lua`
- `LogisticsPipes_Modern.lua`
- `ImmersiveEngineering_Modern.lua`
- `ImmersiveIntegration_Modern.lua`
- `ImmersiveRailroading_Modern.lua`
- `IndustrialCraft2_Modern.lua`
- `Galacticraft_Modern.lua`
- `ExtraPlanets_Modern.lua`
- `Forestry_Modern.lua`
- `Gendustry_Modern.lua`
- `3DPrinter_Modern.lua`

Die ursprünglichen Lua-Dateien bleiben erhalten.
