#!/usr/bin/env python3
"""Modern Tier-3 remote gateway. Python 3 stdlib only.
One Main PC exposes Modern Minecraft/OpenComputers nodes to a browser.
Keep this service behind a VPN/SSH tunnel or trusted LAN and always use the token.
"""
from http.server import BaseHTTPRequestHandler,ThreadingHTTPServer
from urllib.parse import urlparse,parse_qs
import json,os,secrets,time
HOST=os.environ.get("MODERN_BIND","127.0.0.1");PORT=int(os.environ.get("MODERN_HTTP_PORT","8080"));TOKEN_FILE=os.environ.get("MODERN_TOKEN_FILE","./modern-tier3.token")
TOKEN=os.environ.get("MODERN_TOKEN")
if not TOKEN:
    if os.path.exists(TOKEN_FILE): TOKEN=open(TOKEN_FILE,"r",encoding="utf-8").read().strip()
    else:
        TOKEN=secrets.token_urlsafe(32);open(TOKEN_FILE,"w",encoding="utf-8").write(TOKEN+"\n")
        try: os.chmod(TOKEN_FILE,0o600)
        except OSError: pass
state={"server":"TIER3-CORE","updated":0,"nodes":{},"relays":{},"stats":{}};ui={};commands=[]
def auth(q): return secrets.compare_digest(q.get("token",[""])[0],TOKEN)
class Handler(BaseHTTPRequestHandler):
    server_version="Modern-Tier3/1.1"
    def log_message(self,*a): pass
    def reply(self,obj,status=200,ctype="application/json"):
        data=obj if isinstance(obj,bytes) else json.dumps(obj,separators=(",",":")).encode();self.send_response(status);self.send_header("Content-Type",ctype+"; charset=utf-8");self.send_header("Content-Length",str(len(data)));self.end_headers();self.wfile.write(data)
    def do_GET(self):
        u=urlparse(self.path);q=parse_qs(u.query)
        if u.path=="/health": self.reply({"ok":True,"server":state["server"],"time":time.time()});return
        if not auth(q): self.reply({"ok":False,"error":"UNAUTHORIZED"},401);return
        if u.path=="/api/status": self.reply({"ok":True,**state});return
        if u.path=="/api/ui": self.reply({"ok":True,"ui":ui});return
        if u.path=="/api/poll": self.reply({"ok":True,"command":commands.pop(0) if commands else None});return
        if u.path=="/bridge/poll":
            c=commands.pop(0) if commands else None
            if not c: self.reply(b"NOOP\n",200,"text/plain");return
            value="" if c.get("value") is None else str(c.get("value")).replace("|","/").replace("\n"," ")
            kind="UIINPUT" if c.get("kind")=="UIINPUT" else "COMMAND"
            self.reply(("%s|%s|%s|%s\n"%(kind,c["destination"],c["action"],value)).encode(),200,"text/plain");return
        if u.path=="/":
            page=r'''<!doctype html><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1"><title>MODERN TIER-3</title><style>body{font-family:Inter,system-ui;background:#070b12;color:#e8f0ff;margin:0}main{max-width:1250px;margin:auto;padding:24px}.top{display:flex;justify-content:space-between;align-items:center}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:14px}.card{background:#0e1624;border:1px solid #26364d;border-radius:16px;padding:18px;box-shadow:0 10px 30px #0006}.muted{color:#7f91aa}.ok{color:#39ff9a}.pill{display:inline-block;padding:4px 8px;border-radius:999px;background:#15263a;margin:3px;font-size:12px}.app{padding:10px;border:1px solid #24344a;border-radius:10px;margin:6px 0}.toolbar{display:flex;gap:8px;flex-wrap:wrap}button,input{padding:9px;border-radius:9px;border:1px solid #30445e;background:#0a111d;color:#fff}button{cursor:pointer}.screen{font-family:monospace;line-height:1.1;background:#000;padding:10px;overflow:auto}.screenrow{height:1.1em;white-space:pre}</style><main><div class=top><div><h1>MODERN CONTROL CENTER</h1><div class=muted>Remote Modern UI • one Main PC • Tier-3 central network</div></div><button onclick=load()>Refresh</button></div><div id=cards class=grid><div class=card>Loading…</div></div><div class=card><h2>Remote command</h2><div class=toolbar><input id=d placeholder=Destination><input id=a placeholder=Action><input id=v placeholder=Value><button onclick=send()>Send</button></div><pre id=o></pre></div></main><script>const token=new URLSearchParams(location.search).get('token')||prompt('Modern Tier-3 Token');const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));function screen(x){let s=x.screen;if(!s||!s.rows)return '';let map={};s.rows.forEach(r=>map[r.y]=r.cells||[]);let out='';for(let y=1;y<=s.height;y++){let row=map[y]||[];let text='';row.forEach(c=>text+=String(c[0]??' '));out+=`<div class=screenrow>${esc(text)}</div>`}return `<h3>Remote screen</h3><div class=screen>${out}</div>`}async function load(){let r=await fetch('/api/ui?token='+encodeURIComponent(token));let j=await r.json();let all=Object.values(j.ui||{});cards.innerHTML=all.length?all.map(x=>`<div class=card><h2>${esc(x.title||x.nodeId||'MODERN NODE')}</h2><div class=ok>● ONLINE</div><p class=muted>${esc(x.note||'Remote UI scene')}</p><div class=toolbar><button onclick="requestScreen('${esc(x.nodeId)}')">Refresh screen</button><button onclick="uiAction('${esc(x.nodeId)}','ping')">Ping</button></div>${screen(x)}<h3>Modern applications</h3>${(x.apps||[]).map(a=>`<div class=app>${esc(a)}</div>`).join('')||'<span class=muted>none reported</span>'}<h3>Components</h3>${(x.components||[]).slice(0,12).map(c=>`<span class=pill>${esc(c.type)}</span>`).join('')||'<span class=muted>none reported</span>'}</div>`).join(''):'<div class=card>No Modern UI frames received yet.</div>'}async function requestScreen(node){await queue(node,'SCREEN_REQUEST');setTimeout(load,1200)}async function uiAction(node,action){await fetch('/api/command?token='+encodeURIComponent(token),{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({destination:node,action:action,kind:'UIINPUT'})});setTimeout(load,500)}async function queue(node,action,value){return fetch('/api/command?token='+encodeURIComponent(token),{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({destination:node,action:action,value:value})})}async function send(){let r=await queue(d.value,a.value,v.value);o.textContent=await r.text();load()}load();setInterval(load,3000)</script>'''
            self.reply(page.encode(),200,"text/html");return
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
        if u.path=="/api/ui":
            if not isinstance(data,dict) or not data.get("nodeId"):
                self.reply({"ok":False,"error":"NODE_ID_REQUIRED"},400);return
            node=str(data["nodeId"]);cur=ui.get(node,{})
            if data.get("kind")=="TEXT_SCREEN":
                screen=cur.get("screen",{"width":data.get("width"),"height":data.get("height"),"rows":[]})
                screen["width"]=data.get("width",screen.get("width"));screen["height"]=data.get("height",screen.get("height"));rows={r.get("y"):r for r in screen.get("rows",[]) if isinstance(r,dict)}
                for r in data.get("rows",[]): rows[r.get("y")]=r
                screen["rows"]=[rows[k] for k in sorted(rows)];cur["screen"]=screen;cur["nodeId"]=node;cur["updated"]=time.time();ui[node]=cur
            else:
                data["updated"]=time.time();data["screen"]=cur.get("screen");ui[node]=data
            self.reply({"ok":True});return
        if u.path=="/api/command":
            if not isinstance(data,dict) or not data.get("destination") or not data.get("action"):
                self.reply({"ok":False,"error":"DESTINATION_AND_ACTION_REQUIRED"},400);return
            cmd={"id":secrets.token_hex(12),"destination":str(data["destination"]),"action":str(data["action"]),"value":data.get("value"),"kind":str(data.get("kind","COMMAND")),"created":time.time()};commands.append(cmd);del commands[:-100];self.reply({"ok":True,"queued":cmd});return
        self.reply({"ok":False,"error":"NOT_FOUND"},404)
if __name__=="__main__":
    print("Modern Tier-3 Remote Gateway on http://%s:%d"%(HOST,PORT));print("Token file:",TOKEN_FILE);ThreadingHTTPServer((HOST,PORT),Handler).serve_forever()
