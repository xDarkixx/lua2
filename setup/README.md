# BULDACITY Setup

Hier liegen die Einrichtungs-Assistenten. Sie sind bewusst vom eigentlichen Netzwerk getrennt.

## Dateien

- `BuldacityNetworkWizardUI.lua` — moderner grafischer Touch-Assistent.
- `BuldacityNetworkWizard.lua` — textbasierter Assistent als einfache Alternative.

## Wichtig

Der eigentliche Netzwerk-Kern bleibt `Network.lua`. Der Assistent ist nur die Bedienoberflaeche fuer Einrichtung und Diagnose.

Die bisherige `BuldacityNetworkSetup.lua` im Projektstamm bleibt erhalten und wird bei einem Fehler des grafischen Assistenten als Fallback verwendet.

## Start

Normalerweise startet `BuldacityOS_Tier3.lua` den grafischen Assistenten automatisch.

Manuell:

```text
dofile("/home/setup/BuldacityNetworkWizardUI.lua")
```

Der Assistent sucht Modems automatisch, oeffnet Port `4242`, setzt verfuegbare Wireless-Modems auf Staerke `400`, prueft die BULDACITY/2-Grundkonfiguration und speichert die Rolle unter `/home/buldacity-network.cfg`.

## Rollen

1. **SERVER / ZENTRALE** — Tier-3-Zentrale.
2. **CLIENT / ANLAGE** — Big Reactors, SGCraft oder allgemeiner Client.
3. **NETZWERK TESTEN** — reine Diagnose.

Es werden keine manuellen UUIDs oder Adressen verlangt.
