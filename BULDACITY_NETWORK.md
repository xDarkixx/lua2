# Buldacity Netzwerk – Tier 2 / Tier 3

## Ziel

Buldacity verwendet ein gemeinsames OpenComputers-Funkprotokoll. Ein Tier-3-Rechner ist die zentrale Leitstelle. Tier-2-Rechner laufen als Controller für AE2, Reactor, Diesel Generator, RotaryCraft, Mekanism, Thermal, ProjectE, RFTools und SGCraft.

## Hardware

### Tier 3 Server

- OpenComputers Tier-3 Computer
- Bildschirm + GPU
- Keyboard oder Touchscreen
- **Network Card oder Wireless Network Card**
- `BuldacityServer_Tier3.lua`

### Tier 2 Controller

- OpenComputers Tier-2 Computer
- Bildschirm + GPU
- Keyboard/Touch optional
- **Network Card oder Wireless Network Card**
- Controller-Dateien aus diesem Repository
- empfohlen: `BuldacityControllerLauncher.lua`

## Netzwerkaufbau

```text
                    BULDACITY TIER 3
                 BuldacityServer_Tier3.lua
                         │
                  BULDACITY/1 : 4242
                         │
              ┌──────────┼──────────┐
              │          │          │
           Wireless   Wireless   Wired LAN
              │          │          │
            Tier 2     Tier 2      Tier 2
             AE2       Reactor     RFTools
              │          │          │
          Maschinen   Generator   Stargate
```

Die Rechner müssen sich im selben OpenComputers-Netz befinden bzw. die Network Cards müssen sich gegenseitig erreichen können. Bei Wireless Cards muss die Reichweite/Netzabdeckung ausreichen.

## Installation

### 1. Tier 3 Server

Kopiere `BuldacityServer_Tier3.lua` auf den Tier-3-Rechner und starte:

```text
BuldacityServer_Tier3.lua
```

Der Server öffnet Port **4242** und sendet regelmäßig eine Server-Ankündigung.

### 2. Tier 2 Controller

Kopiere die gewünschten Controller und `BuldacityNetworkClient.lua` auf den Tier-2-Rechner. Am einfachsten ist:

```text
BuldacityControllerLauncher.lua
```

Der Launcher startet zuerst den gemeinsamen Netzwerkdienst und danach den gewählten Controller.

### 3. Verbindung prüfen

Nach dem Start sollte der Tier-3-Desktop die Tier-2-Controller automatisch unter **DEVICES** anzeigen.

Ein Controller sendet:

- `HELLO` beim Start
- `HEARTBEAT` regelmäßig
- Controllername
- Rolle
- Anwendung
- Bildschirm-/Statusinformation, sofern vom Controller gemeldet

Der Server erkennt einen Client als offline, wenn länger als ungefähr 10 Sekunden kein gültiger Heartbeat empfangen wurde.

## Protokoll

Aktuell:

- Protokoll: `BULDACITY/1`
- Modem-Port: `4242`
- Pakettypen: `HELLO`, `HEARTBEAT`, `STATUS`, `SCREEN`, `SERVER`, `PING`, `PONG`

Pakete werden als Lua-Tabelle über das OpenComputers-Modem übertragen.

## Sicherheit

Das aktuelle Protokoll ist ein lokales Spiel-/LAN-Protokoll ohne Verschlüsselung oder Authentifizierung. Es sollte nicht als Internet-Sicherheitsprotokoll betrachtet werden.

## Tier-3-Desktop

Der Tier-3-Server besitzt eine PC-artige Buldacity-Oberfläche mit:

- Desktop
- System-/Netzwerkstatus
- Geräteverwaltung
- Online/Offline-Anzeige
- Remote-Statusseite
- Taskbar
- Uhr
- Tastatursteuerung
- Touch-Navigation

**Wichtig:** Die aktuelle REMOTE-Seite ist eine Status-/Metadatenansicht. Sie spiegelt noch nicht die einzelnen Pixel des Tier-2-Bildschirms. Ein echter Remote-Desktop mit Bildübertragung und Maus-/Tastaturweiterleitung wäre eine separate Erweiterung des Protokolls.

## Steuerung Server

- `1` = Desktop
- `2` = Geräteverwaltung
- `3` = Remote-Ansicht
- `Pfeil hoch/runter` = Gerät auswählen
- `R` = Server-Ankündigung / Rescan
- `Q` = Server beenden

## Controller direkt starten

Die vorhandenen Controller können weiterhin separat gestartet werden. Für die gemeinsame Netzwerkregistrierung ist der Launcher der empfohlene Einstiegspunkt.
