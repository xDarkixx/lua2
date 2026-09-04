# Buldacity – Schritt-für-Schritt Setup für OpenComputers

Diese Anleitung erklärt für jeden Buldacity-Controller, welche OpenComputers-Hardware und welche Verbindung zum jeweiligen Mod benötigt wird.

## 1. Grundaufbau für alle Controller

1. Minecraft 1.7.10 mit Forge starten.
2. OpenComputers installieren.
3. Einen Computer (Tier 1–3) bauen.
4. Eine CPU, RAM, Festplatte/EEPROM, Grafikkarte und Bildschirm einbauen.
5. Eine Tastatur anschließen.
6. Den Computer mit OpenComputers-Kabeln mit den benötigten Adaptern/Komponenten verbinden.
7. OpenOS installieren bzw. bootfähiges Medium einlegen.
8. Die Buldacity-Dateien in den Computer kopieren.
9. `BuldacityControllerLauncher.lua` starten.
10. Der Desktop zeigt die passenden Apps an. Hardware-Apps wie der 3D-Drucker werden nur angezeigt, wenn die Komponente vorhanden ist.

## 2. Adapter – wann braucht man ihn?

Der OpenComputers Adapter stellt Blöcke von Minecraft oder anderen Mods als Komponenten bereit, wenn der jeweilige Block vom Adapter/Integration unterstützt wird. Der Adapter muss normalerweise direkt neben dem Zielblock stehen. OpenComputers beschreibt den Adapter ausdrücklich als Schnittstelle für Nicht-Komponenten-Blöcke; Erweiterungen/Driver können zusätzliche Mods unterstützen.

### Standard-Aufbau

`Computer/Server -> OC-Kabel -> Adapter -> Mod-Block`

Bei mehreren Geräten können mehrere Adapter verwendet werden. Jeden Adapter einzeln anschließen und anschließend im Controller einen Rescan durchführen.

## 3. Applied Energistics 2

Controller: `AE2Network_Modern.lua`

Benötigt:
- AE2-Netzwerk mit einem ME Controller bzw. einer vom Controller erkannten ME-Komponente.
- OpenComputers-Adapter, falls der AE2-Block nicht selbst als OC-Komponente verfügbar ist.
- OC-Kabel zwischen Computer und Adapter.
- Für Netzwerk-/P2P-Funktionen die entsprechende AE2-P2P-Konfiguration und Memory Card.

Aufbau:
`Computer -> OC-Kabel -> Adapter -> ME Controller/unterstützte AE2-Komponente`

Danach Controller starten und die Komponenten-/AE2-Seite prüfen. Die App scannt das Netzwerk und zeigt verfügbare Geräte und Funktionen.

## 4. Big Reactors

Controller: `ReactorBigReactors043A_Touch_Responsive.lua`

Benötigt:
- Big-Reactor-Reaktor bzw. unterstützte Reaktor-/Turbinen-Komponenten.
- OC-Adapter neben dem zu überwachenden Block, sofern keine direkte OC-Komponente vorhanden ist.
- OC-Kabel zum Computer.

Aufbau:
`Computer -> OC-Kabel -> Adapter -> Reactor/Turbine`

Für AUTO-Betrieb zuerst manuell testen. Danach Energie-/Temperaturgrenzen kontrollieren.

## 5. Immersive Engineering

Controller: `ImmersiveEngineering_Modern.lua`

Benötigt:
- Immersive-Engineering-Geräte, die vom verwendeten OC-Treiber erkannt werden.
- Bei normalen Mod-Blöcken: OC-Adapter.
- Bei mehreren Geräten: je nach Aufbau mehrere Adapter.

Der Diesel Generator hat einen eigenen Controller: `DieselGenerator_Modern.lua`.

## 6. Immersive Integration

Controller: `ImmersiveIntegration_Modern.lua`

Benötigt:
- Immersive-Integration-Gerät.
- OC-Adapter, wenn der Block nicht direkt als OC-Komponente erscheint.
- OC-Kabel.

Nach dem Aufbau `Scan`/Rescan ausführen und prüfen, welche Komponenten erkannt wurden.

## 7. Immersive Railroading

Controller: `ImmersiveRailroading_Modern.lua`

Benötigt:
- Immersive-Railroading-Zielgeräte/Train-/Rail-Komponenten.
- OC-Adapter bei Mod-Blöcken ohne direkte OC-Schnittstelle.
- OC-Kabel.

Die App arbeitet über die tatsächlich gefundenen OC-Komponenten. Nicht automatisch unterstützte Blöcke erscheinen erst, wenn ein passender OC-Treiber/Adapter verfügbar ist.

## 8. IndustrialCraft 2

Controller: `IndustrialCraft2_Modern.lua`

Benötigt:
- IC2-Maschinen/EU-Geräte.
- OC-Adapter für unterstützte IC2-Blöcke, wenn sie nicht direkt als Komponente verfügbar sind.
- OC-Kabel.

Aufbau:
`Computer -> OC-Kabel -> Adapter -> IC2-Gerät`

Für Energieüberwachung zuerst einen einzelnen Adapter anschließen und den Scan prüfen.

## 9. Mekanism

Controller: `Mekanism_Modern.lua`

Versionen im Projekt:
- Mekanism 1.7.10-9.1.1.1031
- MekanismGenerators 1.7.10-9.1.1.1031
- MekanismTools 1.7.10-9.1.1.1031

Benötigt:
- Mekanism-Gerät/Netzwerk.
- Je nach Block OC-Adapter bzw. unterstützte OC-Komponente.
- OC-Kabel.

## 10. Thermal Expansion / Thermal Foundation / Thermal Dynamics

Controller:
- `Thermal_Modern.lua`
- `ThermalExpansion_Modern.lua`

Versionen im Projekt:
- Thermal Expansion 4.1.5-248
- Thermal Dynamics 1.2.1-172
- Thermal Foundation 1.2.6-118

Benötigt:
- Thermal-Geräte.
- Bei Adapter-basierten Blöcken: OC-Adapter.
- OC-Kabel.

Thermal-Integration kann je nach verwendeter OpenComputers/OpenComponents-Version unterschiedliche Komponenten bereitstellen. Deshalb nach dem Anschließen immer einen Rescan durchführen.

## 11. ProjectE

Controller: `ProjectE_Modern.lua`

Benötigt:
- ProjectE-Gerät, das über eine OC-Komponente/Integration erreichbar ist.
- Bei normalen Mod-Blöcken: Adapter, sofern ein passender Driver vorhanden ist.
- OC-Kabel.

Der Controller verwendet bewusst sichere generische Komponentenerkennung, wenn keine direkte ProjectE-API verfügbar ist.

## 12. RFTools

Controller: `RFTools_Modern.lua`

Benötigt:
- RFTools-Geräte.
- OC-Adapter für unterstützte Mod-Blöcke, wenn erforderlich.
- OC-Kabel.

## 13. SGCraft / Stargate

Controller: `SGCraft_Modern.lua`

Benötigt:
- SGCraft-Stargate bzw. die vom OC-Treiber bereitgestellte Stargate-Komponente.
- OC-Adapter, falls das Gate über einen Mod-Block angebunden wird.
- OC-Kabel.

Der Controller nutzt reale Stargate-Funktionen wie Status, Energie, lokale/entfernte Adresse, Dial/Disconnect und Iris-Steuerung, sofern die Komponente diese API anbietet.

## 14. PneumaticCraft

Controller:
- `PneumaticCraft_Modern.lua`
- `PneumaticCraftNetwork_Modern.lua`

Benötigt:
- PneumaticCraft-Geräte bzw. Drone-/Netzwerk-Komponenten.
- OC-Adapter für Mod-Blöcke, sofern nötig.
- OC-Kabel.

Bei Drohnen muss zusätzlich die jeweilige OpenComputers-Drohnenhardware vorhanden sein, wenn die Steuerung über eine OC-Drohne erfolgt.

## 15. LogisticsPipes

Controller:
- `LogisticsPipes_Modern.lua`
- `LogisticsPipesNetwork_Modern.lua`

Benötigt:
- LogisticsPipes-Netzwerk.
- OpenComputers-Integration/Proxy des verwendeten LP-Builds.
- OC-Kabel und ggf. Adapter für den konkreten Zielblock.

Wichtig: Alte LogisticsPipes/OpenComputers-Kombinationen können unterschiedliche Komponenten-Namen bereitstellen. Deshalb immer den Komponenten-Scan des Controllers prüfen.

## 16. RotaryCraft

Controller: `RotaryCraftDashboard_Modern.lua`

Benötigt:
- RotaryCraft-Maschine bzw. unterstützte OC-Schnittstelle.
- OC-Adapter, falls erforderlich.
- OC-Kabel.

Bei RotaryCraft ist insbesondere die mechanische Verbindung der Maschine weiterhin unabhängig von OpenComputers erforderlich. Der Computer ersetzt keine Wellen, Getriebe oder sonstige RotaryCraft-Antriebe.

## 17. 3D Printer

Controller: `3DPrinter_Modern.lua`

Benötigt:
- OpenComputers 3D Printer mit Komponententyp `printer3d`.
- Computer/Tablet/geeignetes OC-Gerät mit Bildschirmsteuerung.
- OC-Kabel nur für die normale kabelgebundene Verbindung; der Drucker muss als `printer3d`-Komponente sichtbar sein.

Der Desktop zeigt **3D Printer** nur an, wenn `component.isAvailable("printer3d")` true liefert.

Funktionstest:
1. Drucker anschließen.
2. Computer starten.
3. Desktop öffnen.
4. `3D Printer` auswählen.
5. Status prüfen.
6. Modell/Vorlage auswählen.
7. Druck starten.

## 18. Netzwerk-Controller

Folgende Dateien gehören zum Buldacity-Netzwerkbereich:
- `PneumaticCraftNetwork_Modern.lua`
- `LogisticsPipesNetwork_Modern.lua`
- `ImmersiveEngineering_Network_Modern.lua`
- `ImmersiveIntegration_Network_Modern.lua`
- `ImmersiveRailroading_Network_Modern.lua`
- `IndustrialCraft2_Network_Modern.lua`

Diese sind von `BuldacityNetworkLauncher.lua`/`BuldacityNetworkClient.lua` zu unterscheiden. `BuldacityNetworkLauncher.lua` ist der gemeinsame Netzwerk-Wrapper und nicht die Liste der Desktop-Apps.

## 19. Fehlersuche

### App wird nicht angezeigt
1. Prüfen, ob die Lua-Datei vorhanden ist.
2. Bei Hardware-Apps prüfen, ob die erforderliche OC-Komponente vorhanden ist.
3. Rescan durchführen.
4. Computer neu starten.

### Adapter findet den Mod-Block nicht
1. Adapter direkt neben den Block setzen.
2. OC-Kabel anschließen.
3. Prüfen, ob ein passender OC-Driver/OpenComponents-Treiber für diesen Mod vorhanden ist.
4. Komponentenliste prüfen.

Der Adapter kann nur Blöcke bereitstellen, für die ein passender Driver vorhanden ist. OpenComputers dokumentiert außerdem, dass zusätzliche Adapter-Unterstützung über Erweiterungen/Driver kommen kann.

### Energie/Fluids/Inventar fehlen
Je nach Mod und Driver werden unterschiedliche Komponentenfunktionen bereitgestellt. Einen einzelnen Adapter zuerst testen, danach weitere Geräte anschließen und erneut scannen.

## 20. Empfohlener Universal-Aufbau

Für eine zentrale Buldacity-Steuerung:

`Tier-2/3 Computer`
`  |`
`OC Cable / Network`
`  +-- Adapter -> AE2`
`  +-- Adapter -> Big Reactors`
`  +-- Adapter -> Mekanism`
`  +-- Adapter -> Thermal`
`  +-- Adapter -> IC2`
`  +-- Adapter -> Immersive Engineering`
`  +-- Adapter -> weitere Mod-Geräte`
`  +-- printer3d -> 3D Printer`

Nicht jeder Mod benötigt zwingend einen Adapter: direkte OC-Komponenten werden direkt erkannt. Der wichtigste Test ist deshalb immer der Komponenten-Scan des jeweiligen Buldacity-Controllers.
