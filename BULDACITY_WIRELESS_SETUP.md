# BULDACITY Wireless Setup

Aktuelle Anleitung für das Buldacity/2-Netzwerk in OpenComputers 1.7.10.

## 1. Voraussetzungen

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für 1.7.10
- Tier-3-Computer als Zentrale
- Wireless Network Card oder Network Card im Client
- Port `4242`

Es gibt bewusst **keine Whitelist, keine UUID-Rollen und keine Access-Control-Datei**.

## 2. Zentrale

Der Tier-3-Rechner benötigt:

```text
Tier-3 Computer
├── GPU
├── Screen
├── Keyboard
└── Wireless Network Card
```

Start:

```lua
dofile("BuldacityOS_Tier3.lua")
```

## 3. Client

Der Controller-Computer benötigt mindestens:

```text
OpenComputers Computer
├── CPU
├── RAM
├── Speicher
└── Wireless Network Card
```

Netzwerkdienst:

```lua
dofile("BuldacityNetworkClient.lua")
```

Danach kann der gewünschte Normal-, Modern- oder Big-Reactors-Controller gestartet werden.

## 4. Funknetz

`BuldacityWireless.lua` verwendet die echte OpenComputers-Modem-Schnittstelle.

Der Standard ist:

```text
Protocol: BULDACITY/2
Port:     4242
```

Die Wireless Card muss Reichweite zum Tier-3-Rechner haben. Für große Anlagen den Tier-3-Rechner möglichst zentral platzieren.

## 5. Buldacity/2

Pakete verwenden:

```lua
{
  protocol = "BULDACITY/2",
  kind = "...",
  sender = "...",
  time = ...,
  session = ...,
  data = {}
}
```

Nur Pakete mit dem aktuellen Protokoll werden von `BuldacityWireless.valid()` akzeptiert.

## 6. Controller

Die vorhandenen Controller werden nicht durch eine zweite Netzwerk-Implementierung ersetzt.

Es bleiben:

- Normal-Dateien
- Modern-Dateien
- `ReactorBigReactors043A_Touch_Responsive.lua`

Der gemeinsame Netzwerkdienst übernimmt Anmeldung, Heartbeat und Remote-Kommunikation.

## 7. Remote-Bildschirm

Der Tier-3-Desktop kann einen ausgewählten Client als Remote Interface darstellen.

Der Client überträgt:

- Bildschirmzeilen
- Tastatureingaben
- Touch
- Scroll

Die Maschinenlogik bleibt lokal im jeweiligen Controller.

## 8. Big Reactors

Für Big Reactors 0.4.3A wird verwendet:

```text
ReactorBigReactors043A_Touch_Responsive.lua
```

Der Controller erkennt `br_reactor` und `br_turbine` direkt und bietet Touch-Steuerung, Control-Rods, Energie, Brennstoff, Temperatur, AUTO und Turbinen-Telemetrie.

## 9. Installation prüfen

Auf dem Tier-3-Rechner:

```lua
dofile("BuldacityNetworkInstall.lua")
```

Der Installer prüft die aktuelle Netzwerkbasis und den Big-Reactors-Controller.

## 10. Diagnose

```lua
dofile("BuldacityNetworkStatus.lua")
```

Prüfe anschließend:

1. Modem erkannt
2. Port `4242`
3. Protokoll `BULDACITY/2`
4. Client im Tier-3-Desktop sichtbar
5. Remote Interface erreichbar

## 11. Typische Fehler

**Client fehlt:** Wireless Card, Reichweite, Port oder Clientdienst prüfen.

**Reactor fehlt:** Big Reactors 0.4.3A und `br_reactor` prüfen.

**Remote leer:** Client muss einen OpenComputers Screen/GPU besitzen und den Netzwerkdienst ausführen.

**Alte Anleitung erwähnt BULDACITY/1:** Diese Information ist veraltet und gehört nicht mehr zum aktuellen Setup.
