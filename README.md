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
- `BuldacityWireless.lua` – OpenComputers-Modem/Wireless-Netzwerkschicht
- `BuldacityDesktop_Tier3.lua` – Tier-3-Desktop für Netzwerk, Geräte und Remote-Steuerung
- `BULDACITY_NETWORK.md` – Netzwerkbeschreibung
- `BULDACITY_WIRELESS_SETUP.md` – technische Wireless-Netzwerkbeschreibung

## Schritt-für-Schritt Dokumentation

**Kompletter Grundaufbau:**

[BULDACITY_SETUP_GUIDE.md](BULDACITY_SETUP_GUIDE.md)

**Neue Mod-Familien – Galacticraft / ExtraPlanets / Forestry / Gendustry:**

[BULDACITY_MOD_SETUP_ADDONS.md](BULDACITY_MOD_SETUP_ADDONS.md)

**Kompletter Wireless-Netzwerkaufbau:**

[BULDACITY_WIRELESS_SETUP.md](BULDACITY_WIRELESS_SETUP.md)

Die Zusatzanleitung erklärt Installationsreihenfolge, Adapter, OC-Kabel, direkte OC-Komponenten, lokale Controller und Netzwerk-Controller. OpenComputers dokumentiert den Adapter als Schnittstelle für unterstützte Nicht-Komponenten-Blöcke; ein passender Driver muss vorhanden sein.

## Netzwerkstandard

- **Minecraft:** `1.7.10`
- **Forge:** `10.13.4.1614`
- **Protokoll:** `BULDACITY/2` für die aktuelle Wireless-Netzwerkschicht
- **Port:** `4242`
- **Hardware:** Network Card oder Wireless Network Card auf Tier 2 und Tier 3
- **Hauptserver:** Tier-3-OpenComputers
- **Clients:** Tier-2/Tier-3-OpenComputers
- **Remote:** Tastatur, Touch und Scroll können vom Tier 3 zum ausgewählten Client weitergeleitet werden

> **Hinweis:** Die Netzwerkarchitektur enthält bewusst keine Whitelist-, UUID- oder Rollenverwaltung. Diese README beschreibt ausschließlich den technischen Netzwerkaufbau und die Kommunikation.

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

---

# Buldacity / OpenComputers Netzwerk – Schritt-für-Schritt-Aufbau

## 1. Ziel

Diese Anleitung beschreibt den vollständigen technischen Aufbau eines OpenComputers-Netzwerks für Minecraft 1.7.10 mit einem Tier-3-Hauptserver, drahtlosen OpenComputers-Clients und einer Desktop-Oberfläche.

**Diese Anleitung enthält bewusst keine Whitelist-, UUID- oder Rollenverwaltung.**

## 2. Netzwerkarchitektur

```text
                 ┌─────────────────────────────┐
                 │       TIER-3 HAUPTSERVER    │
                 │     OpenComputers Computer  │
                 │                             │
                 │  GPU + Screen + Modem/Card │
                 │  Buldacity Desktop          │
                 └──────────────┬──────────────┘
                                │
                         Wireless / Modem
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
              ▼                 ▼                 ▼
       ┌────────────┐   ┌────────────┐   ┌────────────┐
       │ OC Client  │   │ OC Client  │   │ OC Client  │
       │ Tier 1/2/3 │   │ Tier 1/2/3 │   │ Tier 1/2/3 │
       └─────┬──────┘   └─────┬──────┘   └─────┬──────┘
             │                │                │
             ▼                ▼                ▼
          Maschinen       Maschinen         Maschinen
```

Der Tier-3-Rechner ist die zentrale Netzwerkstation. Die Clients kommunizieren über die OpenComputers-Modem-Schnittstelle.

## 3. Benötigte Software

- Minecraft 1.7.10
- Forge `10.13.4.1614`
- OpenComputers für Minecraft 1.7.10
- die benötigten Mods für die jeweiligen Controller
- die Lua-Dateien aus diesem Repository

Die Forge-Universal-JAR wird nicht verändert. Forge wird auf dem Minecraft-Server installiert; die Buldacity-Lua-Dateien laufen innerhalb von OpenComputers.

## 4. Benötigte Hardware

### Tier-3-Hauptserver

- Tier-3 Computer
- Tier-3 GPU
- Screen
- Keyboard
- Speicher
- Wireless Network Card für drahtlose Kommunikation

### Clients

Jeder Client benötigt mindestens:

- OpenComputers Computer
- Speicher
- Network Card oder Wireless Network Card

Für eine drahtlose Verbindung muss der Client eine Wireless Network Card besitzen.

## 5. Hauptserver aufbauen

Setze den Tier-3-Computer möglichst zentral in der Anlage auf.

Installiere:

```text
Computer
 ├── GPU
 ├── Screen
 ├── Keyboard
 └── Wireless Network Card
```

Starte den Computer und prüfe die Komponenten:

```lua
component.list()
```

Speziell nach einem Modem suchen:

```lua
component.list("modem")
```

Wird eine Adresse ausgegeben, wurde eine Modem-Komponente erkannt.

## 6. Wireless-Modem initialisieren

Die Datei `BuldacityWireless.lua` verwendet die echte OpenComputers-Modem-API.

Beispiel:

```lua
local wireless = require("BuldacityWireless")
local ok, mode = wireless.init(4242)
print(ok, mode)
```

Bei einer Wireless Network Card wird normalerweise `WIRELESS` gemeldet. Bei einer normalen Network Card kann `WIRED` gemeldet werden.

## 7. Port 4242

Das Buldacity-Netzwerk verwendet:

```text
Port: 4242
```

Der Port muss auf den beteiligten Modems geöffnet werden. Alle Buldacity-Geräte müssen für dieses Netzwerk denselben Port verwenden.

```lua
modem.open(4242)
```

## 8. Protokoll BULDACITY/2

Die aktuelle Wireless-Schicht verwendet:

```text
BULDACITY/2
```

Ein Paket besitzt grundsätzlich:

```lua
{
    protocol = "BULDACITY/2",
    kind = "...",
    sender = "...",
    time = ...,
    session = ...,
    data = {}
}
```

Vor der Verarbeitung sollte ein Empfänger das Paket mit `wireless.valid(packet)` prüfen.

## 9. Broadcast

Broadcast sendet eine Nachricht an alle erreichbaren Geräte:

```lua
wireless.broadcast(
    "PING",
    {
        message = "Hello"
    }
)
```

Das eignet sich besonders für Discovery und Gerätesuche.

## 10. Direkte Kommunikation

Ist die Adresse eines Clients bekannt, kann der Server direkt senden:

```lua
wireless.send(
    computerAddress,
    "PING",
    {
        message = "Hello"
    }
)
```

## 11. Server und Client

Der Tier-3-Server übernimmt die zentrale Rolle:

```text
SERVER
  │
  ├── Discovery
  ├── Ping
  ├── Geräteübersicht
  ├── Remote-Kommunikation
  └── Desktop-Oberfläche
```

Die Clients melden sich mit Netzwerkstatus beim Server:

```text
CLIENT
  │
  ├── HELLO
  ├── HEARTBEAT
  └── STATUS / INPUT
```

## 12. Client starten

Der vorhandene `BuldacityNetworkClient.lua` stellt den gemeinsamen Netzwerkdienst für Controller bereit.

Ein Client kann beispielsweise mit folgendem Muster gestartet werden:

```lua
local client = require("BuldacityNetworkClient")
client.start("Reactor-01", "operator")
```

Danach kann der eigentliche Controller geladen werden.

## 13. Heartbeat

Clients sollten regelmäßig ihren Zustand melden:

```text
CLIENT
   │
   ├── HELLO
   │
   ├── HEARTBEAT
   │
   ├── HEARTBEAT
   │
   └── HEARTBEAT
```

Der Server kann anhand des letzten Heartbeats erkennen, ob ein Gerät aktuell erreichbar ist.

## 14. Geräteerkennung

Der Server sendet eine Discovery-/Ping-Nachricht. Clients antworten mit Informationen wie:

```text
Name
Adresse
Rolle
Status
Capabilities
```

Die Tier-3-Oberfläche kann daraus eine Geräteübersicht aufbauen.

## 15. Tier-3-Desktop

`BuldacityDesktop_Tier3.lua` stellt die zentrale Oberfläche bereit.

Die Oberfläche ist in Bereiche wie folgt gegliedert:

```text
┌─────────────────────────────────────────────┐
│ BULDACITY TIER-3 NETWORK                    │
├─────────────────────────────────────────────┤
│                                             │
│  HOME     DEVICES     REMOTE                │
│                                             │
│  LINK       WIRELESS                        │
│  PORT       4242                            │
│  PROTOCOL   BULDACITY/2                    │
│                                             │
│  SERVER     ONLINE                          │
│  CLIENTS    4                               │
│                                             │
└─────────────────────────────────────────────┘
```

Die Geräteansicht zeigt erkannte Clients und ihren aktuellen Online-Zustand.

## 16. Remote-Kommunikation

Die Remote-Seite dient zur Kommunikation mit einem ausgewählten Client. Je nach angeschlossenem Controller können Tastatur-, Touch- und Scroll-Ereignisse weitergegeben werden.

Die Netzwerkebene transportiert dabei die OpenComputers-Signale; die eigentliche Maschinenlogik bleibt im jeweiligen Controller.

## 17. Erster Netzwerktest

Nicht sofort alle Maschinen anschließen. Zuerst nur zwei Computer verwenden.

```text
SERVER
  ↓
PING
  ↓
CLIENT
  ↓
PONG
  ↓
SERVER
```

### Testreihenfolge

1. Tier-3-Server starten.
2. Wireless Network Card prüfen.
3. Port `4242` öffnen.
4. Buldacity-Desktop starten.
5. Einen Client einschalten.
6. Client-Netzwerkdienst starten.
7. HELLO prüfen.
8. HEARTBEAT prüfen.
9. PING/PONG prüfen.
10. Client im Desktop kontrollieren.

Erst wenn diese Schritte funktionieren, weitere Geräte anschließen.

## 18. Reichweite

Wireless-Verbindungen haben eine begrenzte Reichweite. Der Hauptserver sollte deshalb möglichst zentral stehen.

```text
                     CLIENT
                       ●
                       |
                       |
        CLIENT ● ------●------ ● CLIENT
                       |
                       |
                  TIER-3 SERVER
                       |
                       |
                     CLIENT
```

Für große Anlagen sollte die tatsächliche Reichweite mit den verwendeten OpenComputers-Komponenten getestet werden.

## 19. Große Anlage

Ein mögliches Layout:

```text
                         ┌───────────────┐
                         │ TIER-3 SERVER │
                         └───────┬───────┘
                                 │
             ┌───────────────────┼───────────────────┐
             │                   │                   │
             ▼                   ▼                   ▼
        Maschinenhalle      Energiehalle        Lager/AE2
             │                   │                   │
        ┌────┴────┐         ┌────┴────┐        ┌────┴────┐
        ▼         ▼         ▼         ▼        ▼         ▼
     Reactor   Diesel    Mekanism   Thermal   AE2       Storage
```

Der Tier-3-Rechner bleibt die zentrale Leitstelle, während die einzelnen Maschinen von ihren jeweiligen OpenComputers-Controllern bedient werden.

## 20. Controller anbinden

Wenn das Grundnetzwerk funktioniert, können die vorhandenen Controller angeschlossen werden:

```text
BULDACITY SERVER
       │
       ├── Reactor Controller
       ├── Diesel Generator
       ├── AE2 Controller
       ├── Mekanism Controller
       ├── Thermal Controller
       ├── RotaryCraft Controller
       └── weitere Controller
```

Der `BuldacityControllerLauncher.lua` dient als zentraler Einstiegspunkt für die verfügbaren Controller.

## 21. Komponenten richtig verbinden

Je nach Maschine wird eine direkte OpenComputers-Komponente oder ein Adapter benötigt.

Typischer Aufbau:

```text
Minecraft Maschine
       │
       ▼
OC Adapter / unterstützte OC-Komponente
       │
       ▼
OpenComputers Controller
       │
       ▼
Wireless Network Card
       │
       ▼
Tier-3 Server
```

Vor dem Einsatz eines Controllers sollte geprüft werden, welche Komponenten tatsächlich mit `component.list()` vorhanden sind.

## 22. Fehlerdiagnose

### Kein Modem gefunden

```lua
component.list("modem")
```

Wenn nichts ausgegeben wird:

- Wireless Network Card prüfen
- Karte korrekt einsetzen
- Computer neu starten
- OpenComputers-Konfiguration prüfen

### Client wird nicht gefunden

Prüfen:

1. Beide Geräte verwenden Port `4242`.
2. Beide verwenden `BULDACITY/2`.
3. Wireless Network Card ist vorhanden.
4. Geräte sind innerhalb der Reichweite.
5. Client-Netzwerkdienst läuft.
6. Server empfängt `modem_message`.

### Verbindung ist instabil

Zuerst Server und Client direkt nebeneinander stellen. Danach die Entfernung schrittweise erhöhen. So lässt sich feststellen, ob die Reichweite die Ursache ist.

## 23. Schrittweise Erweiterung

```text
1. Minecraft 1.7.10
   ↓
2. Forge 10.13.4.1614
   ↓
3. OpenComputers installieren
   ↓
4. Tier-3 Server aufbauen
   ↓
5. Wireless Network Card einsetzen
   ↓
6. Port 4242 testen
   ↓
7. BuldacityWireless testen
   ↓
8. Einen Client aufbauen
   ↓
9. HELLO / HEARTBEAT
   ↓
10. PING / PONG
   ↓
11. Tier-3 Desktop
   ↓
12. Weitere Clients
   ↓
13. Maschinen-Controller
   ↓
14. Gesamtes Netzwerk testen
```

## 24. Test-Checkliste

- [ ] Minecraft 1.7.10 startet
- [ ] Forge `10.13.4.1614` startet
- [ ] OpenComputers funktioniert
- [ ] Tier-3 Computer funktioniert
- [ ] GPU erkannt
- [ ] Screen erkannt
- [ ] Keyboard erkannt
- [ ] Wireless Network Card erkannt
- [ ] Modem erkannt
- [ ] Port `4242` geöffnet
- [ ] `BULDACITY/2` aktiv
- [ ] Client startet
- [ ] HELLO funktioniert
- [ ] HEARTBEAT funktioniert
- [ ] PING funktioniert
- [ ] PONG funktioniert
- [ ] Client erscheint im Desktop
- [ ] Online-/Offline-Status funktioniert
- [ ] Remote-Kommunikation funktioniert
- [ ] mehrere Clients funktionieren
- [ ] Controller können angebunden werden

## 25. Wichtiger Hinweis zum Sicherheitsumfang

Dieses Netzwerksetup enthält absichtlich **keine Whitelist** und keine UUID-basierte Zugriffskontrolle.

Die Architektur ist damit:

```text
OpenComputers
     ↓
Wireless Network Card
     ↓
OpenComputers Modem
     ↓
BULDACITY/2
     ↓
Tier-3 Server
     ↓
Desktop
     ↓
Controller
     ↓
Minecraft-Mod / Maschine
```

Wenn später eine Zugriffskontrolle benötigt wird, kann sie als separate Schicht ergänzt werden, ohne den grundlegenden Netzwerkaufbau zu ändern.
