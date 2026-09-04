# BULDACITY automatic startup

`BuldacityAutoStart.lua` is the common boot launcher for BULDACITY/2.
It is intended to be installed as `/home/autorun.lua` on each OpenComputers PC.

## Central server PC

Create `/home/buldacity-role.cfg`:

```text
ROLE=SERVER
```

After a reboot, the PC automatically starts:

```text
BuldacityOS_Tier3.lua
```

## Normal controller client PC

Create `/home/buldacity-role.cfg` with the client to start, for example:

```text
ROLE=CLIENT
CLIENT=BigReactors
```

The launcher then starts:

```text
ReactorBigReactors043A_Network.lua
```

Other supported client names are:

- 3DPrinter
- AE2
- DieselGenerator
- ExtraPlanets
- Forestry
- Galacticraft
- Gendustry
- ImmersiveEngineering
- ImmersiveIntegration
- ImmersiveRailroading
- IndustrialCraft2
- LogisticsPipes
- Mekanism
- PneumaticCraft
- ProjectE
- RFTools
- RotaryCraft
- SGCraft
- ThermalExpansion
- BigReactors

## Result

After a Minecraft/OpenComputers computer reboot, the configured BULDACITY program starts automatically. The launcher waits one second before starting so the OpenComputers environment and network components have time to initialize.

The default role is `CLIENT`, which prevents a copied setup from accidentally starting additional central servers.

The original `*_Modern.lua` controllers are not modified by the autostart system.
