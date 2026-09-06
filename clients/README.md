# BULDACITY Modern Clients

Gemeinsame Client-Basis für alle modernen OpenComputers-Geräte. Die vorhandenen mod-spezifischen Client-Ordner bleiben erhalten.

## Gemeinsame Lua-Basis

- `Client.lua` – Registrierung am TIER3, Heartbeat, Status, Commands und Emergency-Stop.
- `Config.lua` – Protokoll, Port und Client-Defaults.
- `Device.lua` – sichere OpenComputers-Hardware-Helfer.
- `Startup.lua` – optionaler Start-Wrapper für Controller.

## Architektur

```text
*_Modern.lua
    |
    +-- clients/Client.lua
    +-- clients/Config.lua
    +-- clients/Device.lua
    |
    v
network-modern/Network.lua
    |
    v
RELAY -> TIER3-CORE
```

## Was jeder Client braucht

1. OpenComputers mit Modem.
2. `clients/` mit der gemeinsamen Client-Basis.
3. `network-modern/` mit `Network.lua`, `Protocol.lua`, `Transport.lua` und `Registry.lua`.
4. Das jeweilige `*_Modern.lua` Controller-Skript.
5. Verbindung zu Relay/TIER3.

Die Hardwarelogik bleibt im jeweiligen Controller. Die gemeinsame Client-Basis übernimmt die Netzwerkkommunikation.

## Vorhandene Client-Bereiche

`ae2/`, `bigreactors/`, `sgcraft/`, `diesel/`, `3dprinter/`, `forestry/`, `galacticraft/`, `gendustry/`, `immersiveengineering/`, `immersiveintegration/`, `immersiverailroading/`, `industrialcraft2/`, `logisticspipes/`, `mekanism/`, `pneumaticcraft/`, `projecte/`, `rftools/`, `rotarycraft/`, `thermalexpansion/`, `thermal/`.

## Netzwerkregeln

- Client-zu-Client-Verkehr wird zentral über `TIER3-CORE` geroutet.
- Modernes Netzwerk: Port `31337`, Protokoll `BULDACITY`.
- Das alte Netzwerk auf Port `4242` bleibt getrennt.
- Port `31337` niemals direkt ins Internet öffnen; Remote-Zugriff geht über Gateway/Bridge zum TIER3.

## Beispiel

```lua
local Client=require("clients.Client")
local ok,err=Client.start(
  "Mein Gerät",
  "MeinController_Modern.lua",
  {"STATUS","CONTROL"},
  {mod="MyMod"},
  function(command)
    -- Vorhandene Hardware-Steuerung aufrufen.
    return true,"OK"
  end
)
if not ok then error(err) end
```
