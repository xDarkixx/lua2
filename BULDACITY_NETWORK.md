# BULDACITY Netzwerk

Aktueller Netzwerkstandard für OpenComputers 1.7.10.

## 1. Architektur

```text
             TIER-3 HAUPTRECHNER
        BuldacityOS_Tier3.lua
             /        |        \
            /         |         \
       Wireless    Wireless    Wireless
          |            |           |
       CLIENT        CLIENT      CLIENT
          |            |           |
      Controller   Controller   Controller
```

Der Tier-3-Rechner ist die zentrale Desktop- und Netzwerkstation. Die eigentliche Maschinenlogik läuft weiterhin auf dem jeweiligen Controller.

## 2. Standard

- Minecraft `1.7.10`
- Forge `10.13.4.1614`
- OpenComputers für 1.7.10
- Protokoll `BULDACITY/2`
- Port `4242`
- Network Card oder Wireless Network Card
- keine Whitelist / keine UUID-Rollenverwaltung

## 3. Benötigte Dateien

### Tier 3

- `BuldacityOS_Tier3.lua`
- `BuldacityWireless.lua`
- `BuldacityNetworkClient.lua`
- `BuldacityNetworkLauncher.lua`
- `BuldacityControllerLauncher.lua`
- `BuldacityNetworkStatus.lua`
- `BuldacityNetworkInstall.lua`

### Controller

Die vorhandenen **Normal-Dateien** und **Modern-Dateien** bleiben erhalten. Für Big Reactors 0.4.3A ist
`ReactorBigReactors043A_Touch_Responsive.lua` der aktuelle Touch-Controller.

## 4. Tier-3 starten

Auf dem Tier-3-Computer:

```lua
component.list("modem")
```

Danach:

```lua
dofile("BuldacityOS_Tier3.lua")
```

Der Desktop verwendet automatisch die Buldacity/2-Netzwerkschicht auf Port `4242`.

## 5. Client starten

Auf dem Controller-Computer:

```lua
dofile("BuldacityNetworkClient.lua")
```

Oder den gewünschten Controller über
`BuldacityControllerLauncher.lua` auswählen.

Der Client meldet sich beim Tier 3 an und sendet regelmäßig seinen Status.

## 6. Remote Interface

Der Tier-3-Desktop kann den ausgewählten Client als Remote-Oberfläche anzeigen.

Unterstützt werden:

- Bildschirmübertragung
- Tastaturereignisse
- Touch-Ereignisse
- Scroll-Ereignisse

Die Remote-Oberfläche steuert nicht selbst die Maschine. Sie überträgt die Eingaben an den Controller-Computer.

## 7. Protokoll

Pakete verwenden mindestens:

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

`BuldacityWireless.valid(packet)` prüft das Protokoll, bevor ein Paket verarbeitet wird.

## 8. Verbindung testen

1. Tier 3 starten.
2. Modem/Wireless Card prüfen.
3. Port `4242` verwenden.
4. Einen einzigen Client starten.
5. Prüfen, ob der Client im Tier-3-Desktop erscheint.
6. Remote Interface öffnen.
7. Erst danach weitere Controller anschließen.

## 9. Big Reactors

Der Big-Reactors-Controller erkennt `br_reactor` und `br_turbine` direkt über OpenComputers.

Er bietet:

- Reaktorstatus
- Energie und Brennstoff
- Temperatur
- Control-Rods
- mehrere Reaktoreinheiten
- Touch-Steuerung
- AUTO-Regelung
- Sicherheitsabschaltung
- Turbinen-Telemetrie

AUTO startet unter `10 %` Energie und stoppt ab `90 %`. Bei Brennstoffmangel oder einer Temperatur ab `900 C` wird abgeschaltet.

## 10. Fehlerbehebung

### Kein Client sichtbar

- Wireless Network Card vorhanden?
- Modem erkannt?
- Port `4242` offen?
- `BuldacityNetworkClient.lua` gestartet?

### Kein Reactor sichtbar

- Big Reactors 0.4.3A installiert?
- OpenComputers-Komponente `br_reactor` vorhanden?
- Controller auf dem richtigen Computer gestartet?

### Remote-Bildschirm leer

- Client muss den Bildschirm mit OpenComputers-GPU/Screen besitzen.
- Client-Netzwerkdienst muss laufen.
- Remote Interface erst nach der Client-Anmeldung öffnen.

## 11. Nicht mehr Teil des Aufbaus

Die früheren Buldacity/1-Dateien, die alte Desktop-Datei, das alte Server-Script, die separate Access-Control-/Whitelist-Struktur und die alten Netzwerk-Testnotizen werden nicht mehr verwendet.
