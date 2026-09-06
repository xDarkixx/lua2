# Remote Zugriff über einen einzigen Haupt-PC

Das Modern-Netz kann über einen einzigen Haupt-PC zentral erreicht werden. Die Minecraft/OpenComputers-PCs müssen dabei **nicht direkt aus dem Internet erreichbar** sein.

## Aufbau

```text
Browser / Laptop / anderer PC
          |
          | HTTP + Token
          v
      HAUPT-PC
  ModernRemoteGateway
          |
          | HTTP
          v
 OpenComputers Internet Card
          |
          v
      TIER3-CORE
          |
      Modem/WLAN
          |
    +-----+-----+-----+
    |           |     |
  OC-PC       OC-PC  OC-PC
  Modern      Modern Modern
```

## 1. Haupt-PC starten

Python 3 wird benötigt. Aus dem Repository-Verzeichnis:

```bash
python3 network-modern/RemoteGateway.py
```

Windows:

```bat
py network-modern\RemoteGateway.py
```

Beim ersten Start wird automatisch ein zufälliger Token in `modern-tier3.token` angelegt.

Standardmäßig hört der Gateway nur auf `127.0.0.1:8080`.

Für Zugriff aus dem eigenen LAN kann der Haupt-PC gezielt auf seine LAN-Schnittstelle bzw. `0.0.0.0` gebunden werden:

```bash
MODERN_BIND=0.0.0.0 MODERN_HTTP_PORT=8080 python3 network-modern/RemoteGateway.py
```

Der Port sollte **nicht ungeschützt ins Internet weitergeleitet** werden. Für Internetzugriff wird VPN oder ein SSH-Tunnel empfohlen.

## 2. TIER3-CORE verbinden

Auf dem zentralen OpenComputers-PC läuft `network-modern/Tier3Main.lua` bzw. der vorhandene Tier-3-Server. Zusätzlich wird auf dem Tier-3-PC `network-modern/RemoteBridge.lua` gestartet.

Der Bridge-PC braucht:

- OpenComputers Internet Card
- Modem/WLAN für das interne OC-Netz
- Zugriff auf den Haupt-PC über HTTP
- den gleichen Gateway-Token

Beispiel-Konfiguration:

```text
MODERN_GATEWAY=http://192.168.1.10:8080
MODERN_GATEWAY_TOKEN=<Token aus modern-tier3.token>
```

Danach startet die Bridge:

```text
/network-modern/RemoteBridge.lua
```

## 3. Minecraft-PCs

Die vorhandenen `*_Modern.lua`-Controller bleiben unverändert.

`network-modern/ModernRemote.lua` kann zusätzlich auf einem Minecraft/OpenComputers-PC gestartet werden. Es veröffentlicht:

- erkannte Modern-Programme
- Komponenten
- Auflösung/Uptime
- Netzwerkstatus
- Modern-UI-Aktionen
- optional den aktuellen GPU-Textbildschirm über die bestehende Remote-Screen-Funktion

Die Browser-Oberfläche ruft diese Daten über den Haupt-PC ab.

## 4. Remote öffnen

Im Browser des Haupt-PCs:

```text
http://127.0.0.1:8080/?token=<TOKEN>
```

Von einem anderen PC im LAN:

```text
http://<HAUPT-PC-IP>:8080/?token=<TOKEN>
```

Die Oberfläche zeigt die gemeldeten Modern-Knoten und bietet unter anderem:

- Remote-Screen aktualisieren
- Ping/UI-Aktion senden
- Remote-Command an einen Minecraft-PC senden
- Modern-Apps und Komponenten anzeigen
- Live-Aktualisierung alle 3 Sekunden

## 5. Sicherheitsmodell

Der Haupt-PC ist der einzige externe Zugangspunkt. Minecraft-PCs werden nicht direkt veröffentlicht.

Der Gateway verlangt für API-Zugriffe den Token. Remote-Zugriff über das Internet sollte zusätzlich über VPN/SSH abgesichert werden.

Der Token darf nicht in GitHub eingecheckt werden.

## 6. GitHub als Installationsquelle

Das Repository bleibt die zentrale Quelle für die Software. Die Minecraft- und Haupt-PC-Installer können daraus den aktuellen Stand laden.

GitHub ist dabei **nicht der Live-Datenkanal**: Live-Status, Bildschirme und Befehle laufen über den Haupt-PC-Gateway. Dadurch muss GitHub keine offenen Minecraft-Verbindungen annehmen.

## Status

Die Remote-Kette ist damit:

```text
*_Modern.lua
    -> network-modern.Network
    -> TIER3-CORE
    -> RemoteBridge
    -> Main-PC RemoteGateway
    -> Browser
```

Befehle laufen in Gegenrichtung über dieselbe Kette.
