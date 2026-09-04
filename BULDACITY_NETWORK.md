# Buldacity Netzwerk – Tier 2 / Tier 3

## Ziel

Buldacity verwendet ein gemeinsames OpenComputers-Netzwerk. Ein Tier-3-Rechner ist die zentrale Leitstelle und stellt den PC-artigen Buldacity-Server-Desktop bereit. Tier-2-Rechner laufen als Controller für die vorhandenen Maschinen-/Mod-Systeme.

Die Netzwerkbasis nutzt OpenComputers-Modem-Nachrichten und `modem_message`-Signale.

## Was wird benötigt?

### Minecraft / Mods

- Minecraft **1.7.10**
- OpenComputers passend zu Minecraft 1.7.10
- Die jeweilige Mod für den gewünschten Controller
- Für die konkrete Mod müssen die im jeweiligen Script genannten Komponenten vorhanden sein

### Tier 3 Server-PC

Pflicht:

- OpenComputers **Tier-3 Computer**
- Tier-3 CPU / RAM / Festplatte nach OpenComputers-Bauplan
- Screen
- GPU
- Keyboard oder Touchscreen
- **Network Card oder Wireless Network Card**
- OpenOS
- `BuldacityServer_Tier3.lua`

Empfohlen:

- Internet Card ist für den lokalen Buldacity-Betrieb nicht erforderlich
- Chunkloader, wenn der Server auch bei großer Entfernung dauerhaft laufen soll

### Tier 2 Controller-PC

Pro Controller wird benötigt:

- OpenComputers **Tier-2 Computer**
- CPU / RAM / Festplatte passend zum Controller
- Screen
- GPU
- Keyboard und/oder Touchscreen nach Bedarf
- **Network Card oder Wireless Network Card**
- OpenOS
- `BuldacityNetworkClient.lua`
- `BuldacityControllerLauncher.lua`
- gewünschte Controller-Lua-Datei

## Netzwerk-Hardware

Es gibt zwei Varianten:

### Variante A – Wireless

Jeder Tier-2-PC und der Tier-3-Server bekommen eine Wireless Network Card. Die Rechner müssen sich gegenseitig im Funkbereich erreichen können.

```text
                 ┌─────────────────────────┐
                 │   BULDACITY TIER 3       │
                 │   Server / Desktop       │
                 │   Wireless Network Card  │
                 └────────────┬────────────┘
                              ))
                 BULDACITY/1 : 4242
                    )))       )))       )))
                    │         │         │
             ┌──────┴───┐ ┌───┴─────┐ ┌─┴────────┐
             │ Tier 2   │ │ Tier 2  │ │ Tier 2   │
             │ AE2      │ │ Reactor │ │ SGCraft  │
             └──────────┘ └─────────┘ └──────────┘
```

### Variante B – Kabel / Wired

Wenn Wireless nicht benötigt wird, kann das OpenComputers-Netz auch über kompatible Wired-Network-Komponenten aufgebaut werden. Wichtig ist, dass die Modem-Komponenten die jeweiligen Rechner erreichen können.

## Software im Repository

### Server

`BuldacityServer_Tier3.lua`

Der Tier-3-Rechner startet damit den Buldacity-Server-Desktop. Der Desktop besitzt:

- Buldacity-OS-Startleiste
- Desktop-Ansicht
- Systemstatus
- Netzwerkstatus
- Device Manager
- Online-/Offline-Erkennung
- Remote-Control-Ansicht
- Uhr
- Touch-Bedienung
- Tastaturbedienung
- Server-Ankündigung / Rescan

### Gemeinsamer Client-Dienst

`BuldacityNetworkClient.lua`

Der Dienst erledigt:

- Anmeldung am Buldacity-Netz
- `HELLO`
- regelmäßige `HEARTBEAT`-Pakete
- Server-Erkennung
- `PING` / `PONG`
- Empfang von `INPUT`
- Weitergabe von Remote-Tastatur-, Touch- und Scroll-Signalen an den Tier-2-Computer

### Launcher

`BuldacityControllerLauncher.lua`

Der Launcher startet den Netzwerkdienst und danach den gewünschten Controller. Dadurch muss nicht jeder Controller separat umgebaut werden, um am gemeinsamen Netzwerk teilzunehmen.

## Unterstützte Controller

Der Launcher enthält aktuell Einträge für:

1. AE2 Network
2. Diesel Generator / Immersive Engineering
3. Mekanism
4. Thermal
5. ProjectE
6. RFTools
7. SGCraft
8. Big Reactors / Reactor
9. RotaryCraft
10. Thermal Expansion

Die jeweiligen Mod-Versionen und Zusatzanforderungen stehen in den einzelnen Controller-Dateien bzw. in der Komponenten-Dokumentation.

## Startreihenfolge

### Tier 3

```text
1. OpenOS starten
2. BuldacityServer_Tier3.lua starten
3. Server-Desktop erscheint
4. Server sendet regelmäßig SERVER-Ankündigungen
```

### Tier 2

```text
1. OpenOS starten
2. BuldacityControllerLauncher.lua starten
3. Controller auswählen
4. Netzwerkdienst meldet den Controller am Tier 3 an
5. Controller startet
```

## Verbindung

Alle Buldacity-Netzpakete verwenden:

- Protokoll: `BULDACITY/1`
- Modem-Port: **4242**

Beispiel:

```text
Tier 2 Controller
       │
       │ HELLO
       ▼
Tier 3 Server
       │
       │ SERVER
       ▼
Tier 2 Controller
       │
       │ HEARTBEAT alle ~3 s
       ▼
Tier 3 Server
```

Der Server betrachtet einen Controller nach ungefähr 10 Sekunden ohne gültigen Heartbeat als offline.

## Remote-Steuerung

Im Tier-3-Desktop kann ein Gerät unter **DEVICES** ausgewählt und anschließend **REMOTE** geöffnet werden.

Aktuell unterstützt die Remote-Verbindung:

- Tier-3-Tastatur → Tier-2 `key_down`
- Tier-3-Tastatur → Tier-2 `key_up`
- Tier-3-Touch → Tier-2 `touch`
- Tier-3-Scroll → Tier-2 `scroll`

Der Tier-2-Client empfängt diese Signale und stellt sie dem lokalen OpenComputers-Eventsystem zur Verfügung.

### Wichtig: Bildschirmübertragung

Ein echter Pixel-Stream des Tier-2-GPU-Bildschirms ist **noch nicht implementiert**. Die aktuelle Remote-Seite ist deshalb eine echte Remote-Steuerung plus Status-/Metadatenansicht, aber kein vollständiges VNC/RDP-artiges Bild.

Der Grund ist die OpenComputers-GPU-Schnittstelle: Das Script kann Zeichen auf den Bildschirm schreiben, bekommt aber nicht einfach einen vollständigen Pixel-/Text-Framebuffer zurück. Deshalb wird keine falsche „Bildschirmspiegelung“ vorgetäuscht.

## Bedienung Tier 3

- `1` = Desktop
- `2` = Device Manager
- `3` = Remote
- `Pfeil hoch` = vorheriges Gerät
- `Pfeil runter` = nächstes Gerät
- `R` = Server-Ankündigung / Rescan
- `Q` = Server beenden

Im Remote-Modus werden Tastatur- und Touch-Eingaben an das ausgewählte Tier-2-Gerät weitergeleitet.

## Sicherheit

Das aktuelle Protokoll ist für ein Minecraft-LAN gedacht.

Es besitzt derzeit:

- keine Verschlüsselung
- keine Benutzer-/Passwortauthentifizierung
- keine kryptografische Geräte-ID-Prüfung

Daher sollte Port **4242** nicht ungeschützt über das öffentliche Internet weitergeleitet werden.

## Fehlerbehebung

### Tier 2 wird nicht angezeigt

Prüfen:

1. Network/Wireless Network Card eingebaut?
2. Beide Rechner erreichen sich?
3. Server läuft?
4. Tier-2-Launcher läuft?
5. Beide verwenden Port **4242**?
6. Ist `BuldacityNetworkClient.lua` auf dem Tier-2-Rechner vorhanden?
7. Ist OpenOS korrekt installiert?

### Controller läuft, aber Remote-Eingaben kommen nicht an

- Controller über `BuldacityControllerLauncher.lua` starten
- prüfen, dass `BuldacityNetworkClient.lua` geladen werden kann
- prüfen, dass der Tier-2-Computer Netzwerkpakete empfängt
- prüfen, dass im Tier 3 das richtige Gerät unter REMOTE ausgewählt ist

## Zielaufbau

```text
                     ┌──────────────────────────────┐
                     │      BULDACITY TIER 3         │
                     │  PC-artiger Server Desktop   │
                     │  Device Manager / Remote     │
                     │  Port 4242 / BULDACITY/1    │
                     └──────────────┬───────────────┘
                                    │
             ┌──────────────────────┼─────────────────────┐
             │                      │                     │
        ┌────▼─────┐           ┌────▼─────┐         ┌────▼─────┐
        │ Tier 2   │           │ Tier 2   │         │ Tier 2   │
        │ AE2      │           │ Reactor  │         │ SGCraft  │
        └────┬─────┘           └────┬─────┘         └────┬─────┘
             │                      │                     │
          ME-Netz               Big Reactor            Stargate

             weitere Tier-2-Controller können parallel
             über denselben Buldacity-Netzwerkdienst laufen.
```
