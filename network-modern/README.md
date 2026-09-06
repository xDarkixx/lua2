# BULDACITY Modern Network

Zentrale, getrennte Netzwerkbasis für OpenComputers 1.7.10.

## Architektur

```text
Modern Controller A ── LAN ── [Relay A | RELAY | Relay B] ── LAN ── Modern Controller B
                                  │
                                  └── nur BULDACITY/1 auf Port 31337
```

Der Relay ist optional, aber für getrennte Kabelsegmente empfohlen. Ein Relay-Computer braucht zwei Netzwerk-Interfaces. Es leitet ausschließlich Pakete dieses Protokolls weiter und spiegelt Traffic nicht auf das Eingangssegment zurück.

## Schutz gegen Netzwerk-Chaos

- eigener Port `31337`
- eigenes Protokoll `BULDACITY`
- eindeutige Node-IDs und Message-IDs
- TTL/Hop-Limit gegen Endlosschleifen
- Duplikatschutz mit begrenztem Cache
- Paketgrößenlimit 4096 Bytes
- ACK und begrenzte Retries für wichtige Nachrichten
- Broadcast wird nur zwischen getrennten Segmenten weitergeleitet
- direkte Routen werden anhand der Node-ID gelernt
- alte `Network.lua`-Implementierung bleibt unangetastet
- `sgcraft2/` bleibt unangetastet

## Modern-Dateien

Die vorhandenen `*_Modern.lua` Programme bleiben in ihrer Oberfläche und lokalen Steuerlogik unverändert. Die jeweiligen `*_Network_Modern.lua` Startprogramme können diese API verwenden:

```lua
local Network = require("network-modern.Network")
Network.startClient("MEIN MODERN CONTROLLER", {mod="..."})
```

## Dateien

- `Network.lua` – öffentliche API, Client/Server, ACK/Retry
- `Protocol.lua` – Paketformat, Validierung, TTL
- `Registry.lua` – Nodes und Heartbeats
- `Transport.lua` – OpenComputers-Modem-Transport
- `Relay.lua` – Zwei-Segment-Relay/Gateway

## Relay-Aufbau

1. Relay-Computer mit zwei Netzwerk-Karten/Modems ausstatten.
2. Interface 1 nur an Segment A anschließen.
3. Interface 2 nur an Segment B anschließen.
4. `Relay.lua` auf dem Relay-Computer starten.
5. Modern-Clients auf den neuen `network-modern`-Dienst umstellen.

Nicht mehrere alte und neue Netzwerkdienste auf demselben Port mischen. Das neue System benutzt bewusst `31337`, während die ältere BULDACITY/2-Schicht `4242` verwendet.
