# BULDACITY Modern Clients

Gemeinsame Client-Basis für alle modernen OpenComputers-Geräte.

## Struktur

- `Client.lua` – zentrale Client-Runtime.
- `Config.lua` – Client-Defaults.
- `Device.lua` – sichere Hardware-Helfer.
- `Startup.lua` – optionaler Starter.
- `network/ClientProtocol.lua` – Protokoll-Fassade; Quelle bleibt `network-modern/Protocol.lua`.
- `network/ClientTransport.lua` – Transport-Fassade; Quelle bleibt `network-modern/Transport.lua`.
- `network/ClientDiscovery.lua` – HELLO/PING/Discovery.
- `network/ClientHeartbeat.lua` – Heartbeat und Retry-Timer.
- `network/ClientCommands.lua` – zentrale Commands und Ergebnisse.
- `network/ClientStatus.lua` – Statusmeldungen und Snapshots.

## Keine doppelte Netzwerklogik

Die Dateien unter `clients/network/` sind bewusst dünne Client-Fassaden. Es gibt **keine zweite Protokoll- oder Transport-Implementierung**. Dadurch bleiben Port, Protokoll, Paketformat, TTL und Modem-Transport zentral in `network-modern/`.

```text
*_Modern.lua
    |
    +-- clients/Client.lua
    |      |
    |      +-- clients/network/ClientDiscovery.lua
    |      +-- clients/network/ClientHeartbeat.lua
    |      +-- clients/network/ClientCommands.lua
    |      +-- clients/network/ClientStatus.lua
    |      |
    |      +-- clients/network/ClientProtocol.lua
    |      +-- clients/network/ClientTransport.lua
    |
    v
network-modern/Network.lua
    |
    v
RELAY -> TIER3-CORE
```

## Was jeder Client benötigt

1. OpenComputers mit Modem.
2. `clients/`.
3. `network-modern/`.
4. Sein jeweiliges `*_Modern.lua` Controller-Skript.
5. Netzwerkweg zu Relay/TIER3.

Die Hardwarelogik bleibt im Controller. Die Client-Basis übernimmt Registrierung, Heartbeat, Status, Commands, ACK/Retry und Emergency-Stop.

## Netzwerk

- Modernes Protokoll: `BULDACITY`.
- Port: `31337`.
- Route: Client → Relay → TIER3-CORE.
- Client-zu-Client wird nicht direkt geroutet.
- Das alte Netzwerk auf Port `4242` bleibt getrennt.
- Port `31337` nicht direkt ins Internet öffnen.

## Beispiel

```lua
local Client=require("clients.Client")
local ok,err=Client.start(
  "Mein Gerät",
  "MeinController_Modern.lua",
  {"STATUS","CONTROL"},
  {mod="MyMod"},
  function(command)
    return true,"OK"
  end
)
if not ok then error(err) end
```

## Vorhandene Client-Bereiche

`ae2/`, `bigreactors/`, `sgcraft/`, `diesel/`, `3dprinter/`, `forestry/`, `galacticraft/`, `gendustry/`, `immersiveengineering/`, `immersiveintegration/`, `immersiverailroading/`, `industrialcraft2/`, `logisticspipes/`, `mekanism/`, `pneumaticcraft/`, `projecte/`, `rftools/`, `rotarycraft/`, `thermalexpansion/`, `thermal/`.
