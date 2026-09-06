# BULDACITY Modern Network

Zentrale, getrennte Netzwerkbasis für OpenComputers 1.7.10.

## Grundregel

Dieser Ordner enthält ausschließlich die neuen Netzwerk-Luas. Bestehende Modern-Dateien und `sgcraft2/` werden nicht verändert.

## Ziel

- eindeutige Node-IDs
- HELLO / Registrierung
- Heartbeat und Offline-Erkennung
- ACK / NACK
- Retry mit Timeout
- Schutz vor doppelter Ausführung über Message-IDs
- kleine, validierte Pakete
- Transport getrennt von Protokoll und Registry
- lokale Steuerung bleibt unabhängig vom Netzwerk

## Struktur

- `Network.lua` – öffentliche Netzwerk-API
- `Protocol.lua` – Nachrichtenformat und Validierung
- `Registry.lua` – Geräte und Heartbeats
- `Transport.lua` – OpenComputers-Modem-Transport

Der Ordner ist absichtlich separat, damit alte und neue Netzwerk-Luas sich nicht gegenseitig überschreiben.
