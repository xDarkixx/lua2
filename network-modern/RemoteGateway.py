#!/usr/bin/env python3
"""BULDACITY Tier-3 remote gateway (Python 3, stdlib only).
Keep this service on localhost and expose it through a VPN/SSH tunnel."""
from http.server import BaseHTTPRequestHandler,ThreadingHTTPServer
from urllib.parse import urlparse,parse_qs
import json,os,secrets,time
HOST=os.environ.get("BULDACITY_BIND","127.0.0.1");PORT=int(os.environ.get("BULDACITY_HTTP_PORT","8080"));TOKEN_FILE=os.environ.get("BULDACITY_TOKEN_FILE","./tier3.token")
TOKEN=os.environ.get("BULDACITY_TOKEN")
if not TOKEN:
    if os.path.exists(TOKEN_FILE): TOKEN=open(TOKEN_FILE,"r",encoding="utf-8").read().strip()
    else:
        TOKEN=secrets.token_urlsafe(32);open(TOKEN_FILE,"w",encoding="utf-8").write(TOKEN+"\n")
        try: os.chmod(TOKEN_FILE,0o600)
        except OSError: pass
state={"server":"TIER3-CORE","updated":0,"nodes":{},"relays":{},"stats":{}};commands=[]
def auth(q): return q.get("token",[""])[0]==TOKEN
class Handler(BaseHTTPRequestHandler):
    server_version="BULDACITY-Tier3/1.0"
    def log_message(self,*a): pass
    def reply(self,obj,status=200,ctype="application/json"):
        data=obj if isinstance(obj,bytes) else json.dumps(obj,separators=(",",":")).encode();self.send_response(status);self.send_header("Content-Type",ctype+"; charset=utf-8");self.send_header("Content-Length",str(len(data)));self.end_headers();self.wfile.write(data)
    def do_GET(self):
        u=urlparse(self.path);q=parse_qs(u.query)
        if u.path=="/health": self.reply({"ok":True,"server":state["server"],"time":time.time()});return
        if not auth(q): self.reply({"ok":False,"error":"UNAUTHORIZED"},401);return
        if u.path=="/api/status": self.reply({"ok":True,**state});return
        if u.path=="/api/poll": self.reply({"ok":True,"command":commands.pop(0) if commands else None});return
        if u.path=="/bridge/poll":
            c=commands.pop(0) if commands else None
            if not c: self.reply(b"NOOP\n",200,"text/plain");return
            value="" if c.get("value") is None else str(c.get("value")).replace("|","/").replace("\n"," ")
            self.reply(("COMMAND|%s|%s|%s|%s\n"%(c["id"],c["destination"],c["action"],value)).encode(),200,"text/plain");return
        if u.path=="/":
            page="""<!doctype html><meta charset=utf-8><title>BULDACITY TIER-3</title><style>body{font-family:system-ui;background:#090d14;color:#e9eef5;margin:0}main{max-width:1100px;margin:auto;padding:28px}.card{background:#111827;border:1px solid #263244;border-radius:14px;padding:18px;margin:12px 0}input,button{padding:10px;border-radius:8px;border:1px solid #334155;background:#0b1220;color:#fff;margin:3px}button{cursor:pointer}pre{white-space:pre-wrap}</style><main><div class=card><h1>BULDACITY TIER-3</h1><div id=s>Loading...</div></div><div class=card><h2>Remote Command</h2><input id=d placeholder=Destination><input id=a placeholder=Action><input id=v placeholder=Value><button onclick=send()>Send</button><pre id=o></pre></div></main><script>const token=new URLSearchParams(location.search).get('token')||prompt('Tier-3 Token');async function load(){let r=await fetch('/api/status?token='+encodeURIComponent(token));let j=await r.json();s.innerHTML='<b>Server:</b> '+j.server+'<br><b>Nodes:</b> '+Object.keys(j.nodes||{}).length+'<br><b>Relays:</b> '+Object.keys(j.relays||{}).length+'<br><b>Updated:</b> '+j.updated}async function send(){let r=await fetch('/api/command?token='+encodeURIComponent(token),{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({destination:d.value,action:a.value,value:v.value})});o.textContent=await r.text()}load();setInterval(load,3000)</script>"""
            self.reply(page.encode(),200,"text/html");return
        if u.path=="/api/command": self.reply({"ok":False,"error":"POST_REQUIRED"},405);return
        self.reply({"ok":False,"error":"NOT_FOUND"},404)
    def do_POST(self):
        u=urlparse(self.path);q=parse_qs(u.query)
        if not auth(q): self.reply({"ok":False,"error":"UNAUTHORIZED"},401);return
        n=min(int(self.headers.get("Content-Length","0")),65536);raw=self.rfile.read(n)
        try:data=json.loads(raw.decode())
        except Exception:self.reply({"ok":False,"error":"INVALID_JSON"},400);return
        if u.path=="/api/status":
            if isinstance(data,dict): state.update(data);state["updated"]=time.time()
            self.reply({"ok":True});return
        if u.path=="/api/command":
            if not isinstance(data,dict) or not data.get("destination") or not data.get("action"):
                self.reply({"ok":False,"error":"DESTINATION_AND_ACTION_REQUIRED"},400);return
            cmd={"id":secrets.token_hex(12),"destination":str(data["destination"]),"action":str(data["action"]),"value":data.get("value"),"created":time.time()};commands.append(cmd);del commands[:-100];self.reply({"ok":True,"queued":cmd});return
        self.reply({"ok":False,"error":"NOT_FOUND"},404)
if __name__=="__main__":
    print("BULDACITY Tier-3 Remote Gateway on http://%s:%d"%(HOST,PORT));print("Token file:",TOKEN_FILE);ThreadingHTTPServer((HOST,PORT),Handler).serve_forever()
