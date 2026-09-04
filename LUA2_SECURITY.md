# lua2 Security / Whitelist

`lua2` now contains a central `AccessControl.lua` module and `WhitelistConfig.lua` configuration.

## Important limitation

OpenComputers Lua can read the player name included in interactive events such as keyboard/touch events, but a normal Lua program cannot independently establish a cryptographically trusted Minecraft UUID. Therefore the Lua whitelist is an access-control layer, not a server-authoritative authentication mechanism.

For strong protection, the Minecraft 1.7.10 server must provide the authoritative player UUID and permission result through a server-side Forge/OpenComputers integration. The client must never be allowed to choose its own UUID or permission.

## Configuration

Edit `WhitelistConfig.lua` on the trusted OC computer:

```lua
players = {
  ["MinecraftName"] = {
    uuid = "00000000-0000-0000-0000-000000000000",
    role = "admin"
  }
}
```

Available roles are `admin`, `operator`, `user`, and `guest`.

Permissions currently used by the central module include:

- `reactor`
- `ae2`
- `network`
- `buldacity`
- `status`
- `printer`

Set `requireComputer = true` if access must also be bound to specific OC computer addresses.

## Recommended server-side architecture

```text
Minecraft Server / Forge 1.7.10
        |
        | trusted player UUID
        v
Lua2 Security Bridge
        |
        | authenticated permission result
        v
OpenComputers
        |
        +-- Reactor.lua
        +-- AE2Network.lua
        +-- BuldacityNetwork*.lua
        +-- other controllers
```

Network controllers should validate authorization for every privileged command, not only when the program starts.

## Security defaults

- Unknown players are denied by default.
- UUID is preferred when a trusted server bridge supplies it.
- Name fallback is supported for OpenComputers-only installations.
- Computer-address binding is optional.
- Do not give normal players write access to `WhitelistConfig.lua`.
