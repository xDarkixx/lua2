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

## Immersive / IC2 Controller

Neue Dateien:

- `ImmersiveEngineering_Modern.lua`
- `ImmersiveEngineering_Network_Modern.lua`
- `ImmersiveIntegration_Modern.lua`
- `ImmersiveIntegration_Network_Modern.lua`
- `ImmersiveRailroading_Modern.lua`
- `ImmersiveRailroading_Network_Modern.lua`
- `IndustrialCraft2_Modern.lua`
- `IndustrialCraft2_Network_Modern.lua`

Die Controller scannen die OpenComputers-Komponenten live und zeigen nur APIs an, die zur Laufzeit tatsächlich exponiert werden. Der Diesel Generator wird nicht doppelt eingebaut; dafür bleibt `DieselGenerator_Modern.lua` zuständig.

## Buldacity Netzwerk

Buldacity kann mehrere Tier-2-OpenComputers als Controller mit einem Tier-3-OpenComputers als zentralem Server verbinden.

- `BuldacityServer_Tier3.lua` – PC-artiger Tier-3-Server-Desktop
- `BuldacityNetworkClient.lua` – gemeinsamer Netzwerkdienst
- `BuldacityControllerLauncher.lua` – startet alle verfügbaren Controller mit Netzwerkregistrierung
- `BULDACITY_NETWORK.md` – vollständige Hardware-, Software-, Aufbau-, Installations-, Protokoll- und Fehlerbehebungsbeschreibung

Netzwerkstandard:

- **Protokoll:** `BULDACITY/1`
- **Port:** `4242`
- **Hardware:** Network Card oder Wireless Network Card auf Tier 2 und Tier 3
- **Remote:** Tastatur, Touch und Scroll können vom Tier 3 zum ausgewählten Tier 2 weitergeleitet werden

## Dokumentation

**Komponenten, Anschluss und Aufbau:**

[COMPONENTS.md](COMPONENTS.md)

**Tier-2/Tier-3-Netzwerk:**

[BULDACITY_NETWORK.md](BULDACITY_NETWORK.md)

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

Die ursprünglichen Lua-Dateien bleiben erhalten.
