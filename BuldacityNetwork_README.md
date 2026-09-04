# Buldacity Network

## Shared protocol
- Protocol ID: `BULDACITY/1`
- Port: `4242`
- Tier-2 controllers announce themselves with `HELLO` and `HEARTBEAT` packets.
- The Tier-3 desktop server replies to discovery and maintains an online/offline list.
- Wireless Network Cards use OpenComputers modem messages; wired Network Cards work on the same protocol.

## Tier 3
Run `BuldacityServer_Tier3.lua` on the central Tier-3 computer. Give it a Network Card or Tier-2 wireless Network Card and a screen/GPU for the desktop UI.

## Controllers
The modern Buldacity controllers are launched through wrappers that start the shared network client and then execute the original controller core. The original controller logic is kept intact in the corresponding `_Core.lua` file.

## Hardware
A Tier-2 wireless network card can communicate wirelessly. OpenComputers requires the modem port to be open to receive `modem_message` events. Signal range and energy use depend on the network card/configuration. Wired cards can also participate in the same protocol.
