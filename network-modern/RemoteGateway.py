#!/usr/bin/env python3
"""BULDACITY remote gateway.

Small stdlib-only web gateway for a Linux/Ubuntu Tier-3 host. It intentionally
keeps the OpenComputers network behind the host: browsers never talk directly
to OC modems. The gateway exposes a token-protected dashboard and a command
queue that a Tier-3 bridge can poll.

Run locally first and put it behind HTTPS/VPN for Internet access.
"""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs
import html, json, os, secrets, time

HOST = os.environ.get("BULDACITY_BIND", "127.0.0.1")
PORT = int(os.environ.get("BULDACITY_HTTP_PORT", "8080"))
TOKEN_FILE = os.environ.get("BULDACITY_TOKEN_FILE", "./tier3.token")
TOKEN = os.environ.get("BULDACITY_TOKEN")
if not TOKEN:
    if os.path.exists(TOKEN_FILE):
        TOKEN = open(TOKEN_FILE, "r", encoding="utf-8").read().strip()
    else:
        TOKEN = secrets.token_urlsafe(32)
        with open(TOKEN_FILE, "w", encoding="utf-8") as f:
            f.write(TOKEN + "\n")
        try:
            os.chmod(TOKEN_FILE, 0o600)
        except OSError:
            pass

state = {"server": "TIER3-CORE", "updated": 0, "nodes": {}, "relays": {}, "stats": {}}
commands = []


def authorized(query):
    return query.get("token", [""])[0] == TOKEN


def json_bytes(obj):
    return json.dumps(obj, separators=(",", ":")).encode("utf-8")


class Handler(BaseHTTPRequestHandler):
    server_version = "BULDACITY-Tier3/1.0"

    def log_message(self, fmt, *args):
        return

    def send_json(self, obj, status=200):
        data = json_bytes(obj)
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        u = urlparse(self.path)
        q = parse_qs(u.query)
        if u.path == "/health":
            self.send_json({"ok": True, "server": state["server"], "time": time.time()})
            return
        if not authorized(q):
            self.send_json({"ok": False, "error": "UNAUTHORIZED"}, 401)
            return
        if u.path == "/api/status":
            self.send_json({"ok": True, **state})
            return
        if u.path == "/api/poll":
            if commands:
                self.send_json({"ok": True, "command": commands.pop(0)})
            else:
                self.send_json({"ok": True, "command": None})
            return
        if u.path == "/":
            page = """<!doctype html><html><head><meta charset='utf-8'><title>BULDACITY TIER-3</title>
<style>body{font-family:system-ui;background:#090d14;color:#e9eef5;margin:0}main{max-width:1100px;margin:auto;padding:28px}.card{background:#111827;border:1px solid #263244;border-radius:14px;padding:18px;margin:12px 0}h1{margin-top:0}button,input{padding:10px;border-radius:8px;border:1px solid #334155;background:#0b1220;color:#fff}button{cursor:pointer}pre{white-space:pre-wrap}</style></head>
<body><main><div class='card'><h1>BULDACITY TIER-3</h1><div id='state'>Lade...</div></div>
<div class='card'><h2>Remote Command</h2><input id='dst' placeholder='Ziel Node-ID'><input id='action' placeholder='Action'><input id='value' placeholder='Value'><button onclick='send()'>Senden</button><pre id='out'></pre></div>
<script>
const token=new URLSearchParams(location.search).get('token')||prompt('Tier-3 Token');
async function load(){let r=await fetch('/api/status?token='+encodeURIComponent(token));let j=await r.json();document.getElementById('state').innerHTML='<b>Server:</b> '+j.server+'<br><b>Nodes:</b> '+Object.keys(j.nodes||{}).length+'<br><b>Relays:</b> '+Object.keys(j.relays||{}).length+'<br><b>Updated:</b> '+j.updated;}
async function send(){let p=new URLSearchParams({token, destination:dst.value, action:action.value, value:value.value});let r=await fetch('/api/command?'+p);document.getElementById('out').textContent=await r.text();load();} load();setInterval(load,3000);
</script></main></body></html>"""
            data = page.encode("utf-8")
            self.send_response(200); self.send_header("Content-Type", "text/html; charset=utf-8"); self.send_header("Content-Length", str(len(data))); self.end_headers(); self.wfile.write(data)
            return
        if u.path == "/api/command":
            self.send_json({"ok": False, "error": "POST_REQUIRED"}, 405)
            return
        self.send_json({"ok": False, "error": "NOT_FOUND"}, 404)

    def do_POST(self):
        u = urlparse(self.path); q = parse_qs(u.query)
        if not authorized(q):
            self.send_json({"ok": False, "error": "UNAUTHORIZED"}, 401); return
        if u.path == "/api/status":
            n = int(self.headers.get("Content-Length", "0")); raw = self.rfile.read(min(n, 65536))
            try: data = json.loads(raw.decode("utf-8"))
            except Exception: self.send_json({"ok": False, "error": "INVALID_JSON"}, 400); return
            if isinstance(data, dict): state.update(data); state["updated"] = time.time()
            self.send_json({"ok": True}); return
        if u.path == "/api/command":
            n = int(self.headers.get("Content-Length", "0")); raw = self.rfile.read(min(n, 8192))
            try: data = json.loads(raw.decode("utf-8"))
            except Exception: self.send_json({"ok": False, "error": "INVALID_JSON"}, 400); return
            if not isinstance(data, dict) or not data.get("destination") or not data.get("action"):
                self.send_json({"ok": False, "error": "DESTINATION_AND_ACTION_REQUIRED"}, 400); return
            cmd = {"id": secrets.token_hex(12), "destination": str(data["destination"]), "action": str(data["action"]), "value": data.get("value"), "created": time.time()}
            commands.append(cmd); commands[:] = commands[-100:]
            self.send_json({"ok": True, "queued": cmd}); return
        self.send_json({"ok": False, "error": "NOT_FOUND"}, 404)


if __name__ == "__main__":
    print("BULDACITY Tier-3 Remote Gateway")
    print("Bind:", HOST, "Port:", PORT)
    print("Token file:", TOKEN_FILE)
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
