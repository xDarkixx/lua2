# BULDACITY Tier-3 / OpenComputers Wireless

## Hardware

### Tier 3 server
- Tier-3 Computer
- Tier-3 screen + GPU
- Network Card or Wireless Network Card

### Tier 2 controller
- Tier-2 Computer
- Screen + GPU as needed
- Network Card or Wireless Network Card
- The required machine adapters/components

## Software

Copy these files to the OpenComputers filesystem:

- `BuldacityWireless.lua`
- `BuldacityNetworkClient.lua`
- `BuldacityDesktop_Tier3.lua`
- the desired controller Lua files

Start on the Tier-3 computer:

```text
BuldacityDesktop_Tier3.lua
```

Start on each Tier-2 computer through:

```text
BuldacityControllerLauncher.lua
```

## Real OpenComputers wireless networking

The network layer uses the real OpenComputers `modem` component and the normal `modem_message` event. A Wireless Network Card is detected through the same modem component API. No fake TCP/IP layer is required.

The default protocol is `BULDACITY/2` on modem port `4242`.

The Tier-3 desktop provides:

- automatic controller discovery
- online/offline heartbeat status
- device selection
- wireless/wired detection
- modem signal-strength display when available
- remote keyboard forwarding
- remote touch forwarding
- remote scroll forwarding
- ping/rescan
- a full Tier-3 desktop UI

## Security

Network connectivity is not authentication. Use `AccessControl.lua` and `WhitelistConfig.lua` for Lua-side permissions. For tamper-resistant Minecraft UUID authentication, the server-side security bridge must remain authoritative.

Do not expose control permissions to untrusted computers. Restrict the whitelist and, where appropriate, bind permissions to known OpenComputers computer addresses.
