# BULDACITY Modern Network

Zentrale Netzwerkbasis für OpenComputers 1.7.10 mit **einem zentralen TIER-3-Hauptserver** und sicherem Fernzugriff.

## Zielarchitektur

```text
                         LAN / VPN / Internet
                                  |
                         +--------v--------+
                         | BULDACITY TIER-3 |
                         |    TIER3-CORE    |
                         | Registry         |
                         | Routing          |
                         | Security         |
                         | Jobs / Logging   |
                         | Monitoring       |
                         +--------+---------+
                                  |
                         TIER-3 BACKBONE
                                  |
             +--------------------+--------------------+
             |                    |                    |
           RELAY A              RELAY B              RELAY C
             |                    |                    |
        SGCraft / AE2       Reactor / Diesel       weitere Mods

Fernzugriff: VPN/SSH -> RemoteGateway -> RemoteBridge -> TIER3-CORE
```

**Wichtig:** Ein Modern-Gerät routet nicht direkt zu einem anderen Modern-Gerät. Der normale Weg ist:

`Modern-Gerät -> Relay -> TIER3-CORE -> Relay -> Zielgerät`

Der Tier-3 bleibt damit die zentrale Instanz für Registrierung, Routing, Überwachung und Remote-Befehle.

## Netzwerk

- Modern-Protokoll: `BULDACITY`
- Port: `31337`
- Legacy-Netzwerk bleibt getrennt auf Port `4242`
- TTL/Hop-Limit gegen Schleifen
- Message-ID-Deduplizierung
- Paketlimit 4096 Bytes
- ACK/NACK und begrenzte Retries
- Heartbeat und Offline-Erkennung
- Relay-Identität und Segment-Metadaten
- zentrale Access-Policy

## Tier-3 Lua-Dateien

- `Tier3Main.lua` – zentraler Startpunkt
- `Tier3Server.lua` – Routing-Core und Serverdienst
- `Tier3Config.lua` – zentrale Konfiguration
- `Tier3Security.lua` – Node-/Befehlsrichtlinien
- `Tier3Storage.lua` – persistenter Zustand
- `Tier3Logger.lua` – Ereignis-/Fehlerprotokoll
- `Tier3Jobs.lua` – Remote-/Command-Warteschlange
- `Tier3Monitor.lua` – lokale grafische Tier-3-Statusanzeige
- `Network.lua` – Client-API
- `Protocol.lua` – Paketformat/Validierung
- `Transport.lua` – OC-Modem-Transport
- `Registry.lua` – Node-/Heartbeat-Registry
- `Relay.lua` – Zwei-Segment-Relay
- `RemoteBridge.lua` – Verbindung vom OC-Tier-3 zum Remote-Gateway
- `Test.lua` – Protokoll-/TTL-Selbsttest

## Tier-3-Hardware

Mindestens:

- OpenComputers Tier-3-Computer
- Tier-3-CPU/RAM entsprechend der OC-Installation
- Festplatte/EEPROM
- Netzwerk Card oder Modem
- optional GPU + Screen für das lokale Dashboard
- für direkten Internetzugriff: Internet Card

Der Fernzugriff sollte trotzdem **nicht** durch Öffnen des OC-Ports 31337 ins Internet erfolgen.

## Start

Auf dem Tier-3-Rechner:

```text
/home/network-modern/Tier3Main.lua
```

Der Starter prüft das Modem, initialisiert Logging und persistenten Zustand und startet anschließend den zentralen Server.

## Relay

Jeder Relay-Rechner benötigt zwei Netzwerk-Interfaces/Modems:

1. Interface A an Segment A.
2. Interface B an Segment B.
3. `Relay.lua` starten.
4. Der Relay meldet sich am TIER3-CORE an.
5. Client-Traffic darf nicht direkt von Segment A nach B geroutet werden.

## Modern-Client

```lua
local Network=require("network-modern.Network")
Network.startClient("MEIN MODERN CONTROLLER",{mod="..."})
```

Die Node-ID identifiziert das Gerät. Zielgeräte werden über den zentralen Tier-3 geroutet.

## Fernzugriff

`RemoteGateway.py` läuft auf Linux/Ubuntu und stellt die Weboberfläche bereit. `RemoteBridge.lua` holt Remote-Aufträge ab und übergibt sie dem zentralen Tier-3-Netz.

Empfohlener Weg:

`Browser -> VPN/SSH -> RemoteGateway -> RemoteBridge -> TIER3-CORE`

Nicht empfohlen:

`Internet -> direkt Port 31337 -> OpenComputers`

Der Gateway verwendet einen zufälligen Token. Für den produktiven Internetbetrieb zusätzlich VPN/SSH und eine Firewall verwenden.

## Bestandsschutz

Die alte `Network.lua`-Implementierung und `sgcraft2/` bleiben getrennt. Die vorhandenen `*_Modern.lua` Controller behalten ihre lokale Steuerlogik; die neue zentrale Netzwerkebene liegt ausschließlich unter `network-modern/`.
