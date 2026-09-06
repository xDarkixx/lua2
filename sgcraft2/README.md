# SGCraft2

Neue, eigenständige SGCraft-Steuerung für BULDACITY/2.

Dieses Verzeichnis ist bewusst getrennt von der bestehenden SGCraft-Version. Die vorhandenen Dateien im Root bleiben unverändert und kompatibel.

## Ziel

- eigene SGCraft2-Oberfläche
- BULDACITY-Control-Room-Design
- robuste OpenComputers-Schnittstelle
- Unterstützung mehrerer Stargate-Interfaces
- Touch- und Tastatursteuerung
- später erweiterbar um Adressbuch, Iris-Automatik, Auto-Disconnect und Diagnose

## Start

`SGCraft2.lua` ist der Einstiegspunkt. Die bestehende `SGCraftAPI.lua` und `SGCraftVisual.lua` werden wiederverwendet, sofern sie unter `/home` vorhanden sind.
