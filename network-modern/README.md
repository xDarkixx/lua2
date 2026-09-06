# BULDACITY Modern Network

Zentrale Netzwerkbasis für OpenComputers 1.7.10 mit **einem zentralen TIER-3-Hauptserver** und optionalem Fernzugriff.

## Zielarchitektur

```text
                         LAN / VPN / Internet
                                  |
                         +--------v--------+
                         | BULDACITY TIER-3 |
                         |    TIER3-CORE    |
                         | Registry         |
                         | Routing          |
                         | ACK / Retry      |
                         | Monitoring       |
                         +--------+---------+
                                  |
                         TIER-3 BACKBONE
                                  |
             +--------------------+--------------------+
             |                    |                    |
          +--v--+              +--v--+              +--v--+
          |Relay |              |Relay |              |Relay |
          +--+--+              +--+--+              +--+--+
             |                    |                    |
        SGCraft/AE2          Reactor/Diesel       weitere Mods
        Segment A            Segment B            Segment C
```

**Wichtig:** Ein Modern-Gerät routet nicht direkt zu einem anderen Modern-Gerät. Der normale Weg ist:

`Modern-Gerät -> Relay -> TIER3-CORE -> Relay -> Zielgerät`

Damit bleibt der Tier-3-Server die zentrale Instanz für Registrierung, Routing und Überwachung.

## Netzwerk

- Modern-Protokoll: `BULDACITY`
- Port: `31337`
- Legacy-Netzwerk: weiterhin getrennt auf Port `4242`
- TTL/Hop-Limit gegen Schleifen
- Message-ID-Deduplizierung
- Paketlimit 4096 Bytes
- ACK/NACK und begrenzte Retries
- Heartbeat und Offline-Erkennung
- Relay leitet Client-Traffic nicht mehr direkt auf das Nachbarsegment weiter

## Dateien

- `Network.lua` – zentrale Client-API und Tier-3-kompatibles Routing
- `Protocol.lua` – Paketformat, Validierung und TTL
- `Registry.lua` – Node-/Heartbeat-Registry
- `Transport.lua` – OpenComputers-Modem-Transport
- `Tier3Server.lua` – zentraler TIER-3-Hauptserver
- `Relay.lua` – Zwei-Segment-Relay zum Tier-3-Backbone
- `RemoteGateway.py` – token-geschützte Weboberfläche für einen Linux/Ubuntu-Tier-3-Host
- `Test.lua` – statischer Protokoll-/TTL-Test

## TIER-3 starten

Auf dem zentralen OpenComputers-Rechner:

```text
network-modern/Tier3Server.lua
```

Der Server verwendet die feste Node-ID `TIER3-CORE` und Port `31337`.

## Relay

Jeder Relay-Rechner benötigt zwei Netzwerk-Interfaces/Modems:

1. Interface A an Segment A.
2. Interface B an Segment B.
3. `network-modern/Relay.lua` starten.
4. Der Relay meldet sich am Tier-3 an und hält die beiden Segmente getrennt.

## Modern-Client

Die Modern-Network-Wrapper verwenden:

```lua
local Network=require("network-modern.Network")
Network.startClient("MEIN MODERN CONTROLLER",{mod="..."})
```

Für ein Zielgerät wird die Node-ID verwendet. Die API sendet solche Pakete standardmäßig an den bekannten Tier-3-Server und nicht direkt an das Ziel.

## Fernzugriff

`RemoteGateway.py` ist ein kleines Python-3-Webgateway ohne externe Python-Pakete. Es ist standardmäßig nur an `127.0.0.1:8080` gebunden. Dadurch wird kein OpenComputers-Modem-Port ins Internet geöffnet.

Start auf Ubuntu/Linux:

```bash
python3 network-modern/RemoteGateway.py
```

Der Gateway erzeugt beim ersten Start automatisch eine zufällige Token-Datei `tier3.token` mit restriktiven Dateirechten.

Für echten Zugriff von außen sollte der Gateway **über ein VPN oder einen SSH-Tunnel** erreichbar gemacht werden, statt Port 31337 direkt ins Internet zu öffnen.

Die Weboberfläche bietet aktuell:

- Tier-3-Status
- Node-/Relay-Anzahl
- token-geschützte Remote-Commands
- Command-Queue für eine spätere/angeschlossene Tier-3-Bridge

### Sicherheitsregel

Keinen OC-Port und keinen ungeschützten HTTP-Dienst direkt aus dem Internet erreichbar machen. Der Fernzugriff gehört vor den Tier-3-Gateway und wird über Authentifizierung plus VPN/SSH abgesichert.

## Bestandsschutz

Die alte `Network.lua`-Implementierung und `sgcraft2/` bleiben getrennt. Die vorhandenen `*_Modern.lua` Controller sollen ihre lokale Steuerlogik behalten; die Netzwerkebene sitzt separat unter `network-modern/`.
