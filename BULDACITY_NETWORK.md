# BULDACITY v9 – Netzwerk Schritt für Schritt

## 1. Architektur

```text
                    TIER-3 ZENTRALE
                 BuldacityOS + GPU UI
                         │
                  BULDACITY/2 :4242
                         │
             ┌───────────┴───────────┐
             │ Wired / Wireless / AP │
             └───────────┬───────────┘
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
        AE2 PC        Reactor PC       Mekanism PC
          │               │               │
        Mod-Gerät       Reactor         Mod-Gerät
```

Ein zentraler BULDACITY-Server verwaltet die Flotte. Die eigentliche Mod-Logik bleibt auf den jeweiligen Clients.

## 2. Zentrale installieren

Nach `/home`:

```text
Network.lua
BuldacityUI.lua
BuldacityOS_Tier3.lua
BuldacityDesktop.lua
BuldacityComponentServer.lua
BuldacityComponentDashboard.lua
```

Start:

```lua
dofile("/home/BuldacityOS_Tier3.lua")
```

## 3. Client installieren

Nach `/home`:

```text
Network.lua
BuldacityUI.lua
BuldacityComponentAgent.lua
<Mod>Network_Modern.lua
<Mod>_Modern.lua
```

## 4. Port und Protokoll

```text
Protocol: BULDACITY/2
Port:     4242
```

## 5. Verbindung testen

```text
1. Zentrale starten
2. einen Client starten
3. CLIENT HELLO abwarten
4. Zentrale → SCAN
5. DEVICES öffnen
6. Client auswählen
7. PING/PONG prüfen
8. REMOTE öffnen
9. erst danach weitere Clients starten
```

## 6. Wireless

```text
ZENTRALE ))) ((( CLIENT
```

oder:

```text
ZENTRALE ── Kabel ── RELAY/AP ))) ((( CLIENT
```

Die `Network.lua` konfiguriert erkannte Wireless-Hardware und berücksichtigt Relay/Access-Point-Komponenten.

## 7. Diagnose

```lua
dofile("/home/BuldacityWirelessCheck_Modern.lua")
dofile("/home/BuldacityNetworkTest.lua")
```

Prüfen:

```text
Modem
Wireless
Signalstärke
Relay/AP
Port 4242
HELLO
HEARTBEAT
PING
PONG
Latenz
Entfernung
```

## 8. Remote-PC

Die Zentrale kann Screen-Daten vom Client anfordern. Die Remote-Seite kann Tastatur-, Touch- und Scroll-Eingaben weitergeben.

## 9. Component IDs

Der Component Agent überträgt die erkannten OC-Componenten inklusive Adresse. In `DEVICES`/`COMPONENTS` werden diese Daten grafisch angezeigt.

## 10. Kein Client sichtbar

```text
Network Card
Network.lua
BuldacityComponentAgent.lua
passender Network-Wrapper
Port 4242
Wireless-Signal
Relay/AP
Zentrale SCAN
NetworkTest
```

## 11. Abschluss

```text
Zentrale ONLINE
      ↓
BULDACITY/2
      ↓
CLIENT HELLO
      ↓
LINK_ACK
      ↓
HEARTBEAT
      ↓
PING/PONG
      ↓
DEVICES
      ↓
COMPONENTS
      ↓
REMOTE
```

**Alle BULDACITY-Dateien werden aus `/home` geladen.**
