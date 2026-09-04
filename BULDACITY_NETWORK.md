# Buldacity Netzwerk – Tier 2 / Tier 3

## Aktueller Stand

Buldacity verwendet ein gemeinsames OpenComputers-Netzwerk. Ein Tier-3-Rechner ist die zentrale Leitstelle und stellt den **BuldacityOS-Tier-3-Desktop** bereit. Tier-2/3-Rechner laufen als Controller für die Maschinen- und Mod-Systeme.

Die Netzwerkbasis nutzt OpenComputers-Modem-Nachrichten und `modem_message`-Signale.

**Aktueller Standard:** `BULDACITY/2`, Modem-Port `4242`.

## Server-PC

Benötigt:

- OpenComputers Tier-3 Computer
- CPU / RAM / Festplatte passend zum Computer
- GPU
- Screen
- Keyboard
- Wireless Network Card oder kompatible Network Card
- OpenOS
- `BuldacityWireless.lua`
- `BuldacityOS_Tier3.lua`

Der alte `BuldacityDesktop_Tier3.lua` wird nicht mehr verwendet.

## Controller-PC

Pro Controller:

- OpenComputers Tier-2 oder Tier-3 Computer
- CPU / RAM / Festplatte passend zum Controller
- GPU + Screen für eine lokale Oberfläche
- Keyboard nach Bedarf
- Wireless Network Card oder Network Card
- OpenOS
- `BuldacityWireless.lua`
- `BuldacityNetworkClient.lua`
- `BuldacityControllerLauncher.lua`
- benötigtes Controller-Skript

## Netzwerk

```text
                     TIER-3 BULDACITY OS
                              │
                           WIRELESS
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
      CONTROLLER          CONTROLLER          CONTROLLER
        REACTOR             DIESEL                AE2
          │                   │                   │
       OC-Kabel            OC-Kabel            OC-Kabel
          │                   │                   │
       Maschine            Maschine              AE2
```

Die Funkverbindung transportiert BULDACITY-Pakete und Remote-Oberflächen. Die lokale Maschinenverbindung bleibt über OC-Komponenten/Kabel getrennt.

## BuldacityOS Desktop

Der zentrale Desktop enthält:

- HOME
- NETWORK
- DEVICES
- CONTROLLER APPS
- REMOTE INTERFACE
- TERMINAL
- SYSTEM MONITOR
- Online-/Offline-Erkennung
- Ping/Rescan
- Touch- und Tastaturbedienung

Unter `DEVICES` werden die aktiven Controller angezeigt. Mit `REMOTE` kann die Oberfläche des ausgewählten Controllers live auf dem Tier-3-Screen dargestellt werden.

## Live-Oberflächen

Der Controller kann seine GPU-Zeichenfläche übertragen.

```text
Controller GPU
     │
     │ SCREEN_BEGIN
     │ SCREEN_ROW
     │ SCREEN_END
     ▼
BULDACITY/2 : 4242
     │
     ▼
Tier-3 REMOTE INTERFACE
```

Die Darstellung wird aus Zeichen- und Farb-Zellen aufgebaut. Es handelt sich nicht um einen Pixel-Video-Stream.

Remote-Eingaben:

- `key_down`
- `key_up`
- `touch`
- `scroll`

Diese werden über `INPUT` an den ausgewählten Controller übertragen.

## Netzwerkdienst

`BuldacityNetworkClient.lua` übernimmt:

- HELLO
- HEARTBEAT
- Server-Erkennung
- PING/PONG
- INPUT
- SCREEN_REQUEST
- SCREEN_BEGIN
- SCREEN_ROW
- SCREEN_END

`BuldacityWireless.lua` ist die gemeinsame Transport-Schicht und verwendet die OpenComputers-Modem-API.

## Controller-Apps

Der Desktop kennt unter anderem:

1. AE2
2. Diesel / Immersive Engineering
3. Mekanism
4. Thermal
5. ProjectE
6. RFTools
7. SGCraft
8. Reactor / Big Reactors
9. RotaryCraft
10. Thermal Expansion
11. PneumaticCraft
12. LogisticsPipes
13. Immersive Engineering
14. Immersive Integration
15. Immersive Railroading
16. IndustrialCraft 2
17. Galacticraft
18. ExtraPlanets
19. Forestry
20. Gendustry

## Start

### Tier 3

```text
OpenOS
  ↓
BuldacityOS_Tier3.lua
  ↓
HOME
  ↓
DEVICES
  ↓
Controller auswählen
  ↓
REMOTE
```

### Controller

```text
OpenOS
  ↓
BuldacityControllerLauncher.lua
  ↓
Controller auswählen
  ↓
BuldacityNetworkClient
  ↓
HELLO / HEARTBEAT
```

## Bedienung

```text
1 = HOME
2 = NETWORK
3 = DEVICES
4 = CONTROLLER APPS
5 = REMOTE
6 = TERMINAL
7 = SYSTEM
Q = Desktop beenden
R = Rescan / Remote Refresh
Pfeil hoch/runter = Controller auswählen
ENTER = Controller öffnen
```

## Fehlerbehebung

### Controller nicht sichtbar

- Wireless/Network Card prüfen
- Port `4242` prüfen
- `BULDACITY/2` verwenden
- Client starten
- Tier-3 `R` drücken

### Remote-Oberfläche leer

- Controller braucht GPU + Screen
- aktuelles `BuldacityNetworkClient.lua` installieren
- REMOTE erneut öffnen
- `SCREEN_REQUEST` prüfen
- Funkreichweite prüfen

### Eingaben funktionieren nicht

- richtigen Controller auswählen
- REMOTE öffnen
- Client-Netzwerkdienst prüfen
- `INPUT`-Empfang prüfen

### Maschine funktioniert nicht

Netzwerk und lokale Maschinenverbindung getrennt prüfen:

```text
Funk OK + Maschine nicht OK
        ↓
OC-Kabel / Adapter / Controller prüfen
```

## Sicherheit

Das Netzwerk besitzt bewusst keine Whitelist. Es ist für eine private Minecraft-Umgebung gedacht.

Aktuell gibt es keine Verschlüsselung oder Benutzer-/Passwortauthentifizierung. Port `4242` sollte deshalb nicht ungeschützt ins öffentliche Internet weitergeleitet werden.

## Aktuelle Kernstruktur

```text
BuldacityOS_Tier3.lua
        │
        ├── BuldacityWireless.lua
        │
        ├── BuldacityNetworkClient.lua
        │
        ├── BuldacityControllerLauncher.lua
        │
        ├── BuldacityNetworkLauncher.lua
        │
        └── BuldacityNetworkStatus.lua
```

Diese Struktur verwendet eine zentrale Netzwerkbasis und vermeidet eine zweite konkurrierende Tier-3-Desktop-Implementierung.
