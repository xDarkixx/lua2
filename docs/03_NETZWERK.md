# 🌐 BULDACITY – Netzwerk einfach erklärt

BULDACITY verwendet das Protokoll **BULDACITY/2** auf Port **4242**.

## Für Anfänger

Du musst normalerweise keine Client-Adresse und keine UUID eintippen.

### Server

1. Tier-3-Computer einschalten.
2. Modem anschließen.
3. `Network.lua` und `BuldacityNetworkSetup.lua` nach `/home` kopieren.
4. `BuldacityOS_Tier3.lua` starten.
5. Warten, bis der Netzwerkcheck fertig ist.

### Client

1. Client-PC bauen.
2. Modem anschließen.
3. `Network.lua` und den passenden Network-Controller nach `/home` kopieren.
4. Controller starten.
5. Auf der Zentrale `DEVICES` öffnen.

## Was passiert automatisch?

```text
Modem finden
   ↓
Port 4242 öffnen
   ↓
Wireless/Wired erkennen
   ↓
Server HELLO
   ↓
Client antwortet
   ↓
LINK_ACK
   ↓
PING / PONG
   ↓
Komponenten abfragen
   ↓
Gerät erscheint in DEVICES
```

## Netzwerk-Test

Der Assistent zeigt unter anderem:

- Modem gefunden / nicht gefunden
- Wireless verfügbar
- Signalstärke
- Relay / Access Point
- Client-Adresse
- Verbindung ONLINE/LINKED
- Entfernung, wenn vom Modem geliefert
- Ping-Latenz
- erkannte Komponenten

## Wenn ein Client nicht erscheint

Prüfe in dieser Reihenfolge:

1. Ist ein Modem eingebaut?
2. Läuft `Network.lua`?
3. Ist Port 4242 geöffnet?
4. Läuft der Network-Controller?
5. Ist das Mod-Gerät wirklich verbunden?
6. Danach Client und Server einmal neu starten.

## Für Fortgeschrittene

Der Netzwerkcode befindet sich in `Network.lua`. Die zentrale Konfiguration ist:

```lua
PROTOCOL = "BULDACITY/2"
PORT = 4242
```

Ändere den Port nur, wenn **alle** beteiligten Geräte denselben Port verwenden.
