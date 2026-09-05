-- BuldacityUI.lua
-- BULDACITY GPU visual system for OpenComputers 1.7.10 / Tier-3.
-- Uses only APIs available on normal OC GPU/screen setups; no external libraries.
local component=require("component")
local gpu=component.gpu
local UI={W=80,H=25,buttons={}}
UI.C={bg=0x050811,panel=0x0B1320,panel2=0x111D2C,line=0x263F59,cyan=0x31E8FF,blue=0x5A8CFF,green=0x3BFF9A,red=0xFF5276,yellow=0xFFE16B,purple=0xC56CFF,orange=0xFF9E4A,pink=0xFF48C7,white=0xF2F8FF,muted=0x7890A8,off=0x253442,black=0x000000}
local function safe(f,...)
 local ok,a,b,c,d=pcall(f,...);if ok then return a,b,c,d end
end
function UI.resize()
 local w,h=safe(gpu.getResolution);UI.W=w or 80;UI.H=h or 25;return UI.W,UI.H
end
function UI.clear(bg)
 UI.resize();gpu.setBackground(bg or UI.C.bg);gpu.setForeground(UI.C.white);gpu.fill(1,1,UI.W,UI.H," ");UI.buttons={}
end
function UI.text(x,y,s,fg,bg)
 if x<1 or y<1 or x>UI.W or y>UI.H then return end
 gpu.setForeground(fg or UI.C.white);gpu.setBackground(bg or UI.C.bg);gpu.set(x,y,tostring(s or ""))
end
function UI.fit(s,n)
 s=tostring(s or "");n=math.max(1,n or 1);if #s<=n then return s end
 if n<=3 then return s:sub(1,n) end
 return s:sub(1,n-3).."..."
end
function UI.rect(x,y,w,h,bg,fg,ch)
 if w<1 or h<1 then return end
 gpu.setBackground(bg or UI.C.panel);gpu.setForeground(fg or UI.C.white);gpu.fill(x,y,w,h,ch or " ")
end
function UI.rule(x,y,w,c)
 if w>0 and y>=1 and y<=UI.H then UI.rect(x,y,math.min(w,UI.W-x+1),1,c or UI.C.line) end
end
function UI.header(title,subtitle,accent)
 accent=accent or UI.C.cyan;UI.rect(1,1,UI.W,4,UI.C.panel);UI.text(2,1,"◈ BULDACITY",accent,UI.C.panel);UI.text(15,1,"//",UI.C.muted,UI.C.panel);UI.text(19,1,UI.fit(title,UI.W-20),UI.C.white,UI.C.panel)
 if subtitle then UI.text(2,2,UI.fit(subtitle,UI.W-4),UI.C.muted,UI.C.panel) end
 UI.rect(1,4,UI.W,1,accent)
end
function UI.panel(x,y,w,h,title,accent)
 accent=accent or UI.C.cyan;UI.rect(x,y,w,h,UI.C.panel);UI.rect(x,y,w,1,accent);UI.text(x+2,y,"◆ "..UI.fit(title,w-5),UI.C.white,accent);if h>=3 then UI.rule(x+1,y+h-1,w-2,UI.C.line) end
end
function UI.button(id,x,y,w,label,accent,active)
 accent=accent or UI.C.cyan;w=math.max(6,w);UI.buttons[id]={x=x,y=y,w=w,h=2};UI.rect(x,y,w,2,active and UI.C.white or accent);UI.text(x+math.max(1,math.floor((w-#label)/2)),y,UI.fit(label,w-2),active and accent or UI.C.white,active and UI.C.white or accent)
end
function UI.hit(id,x,y)local b=UI.buttons[id];return b and x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h end
function UI.bar(x,y,w,p,accent,showValue)
 accent=accent or UI.C.cyan;p=math.max(0,math.min(100,tonumber(p) or 0));w=math.max(1,w);UI.rect(x,y,w,1,UI.C.panel2);local n=math.floor(w*p/100);if n>0 then UI.rect(x,y,n,1,accent) end;if showValue then UI.text(x+math.max(0,w-5),y,string.format("%3.0f%%",p),UI.C.white,accent) end
end
function UI.bar2(x,y,w,h,p,accent,showValue)
 accent=accent or UI.C.cyan;p=math.max(0,math.min(100,tonumber(p) or 0));w=math.max(1,w);h=math.max(1,h);UI.rect(x,y,w,h,UI.C.panel2);local n=math.floor(w*p/100);if n>0 then UI.rect(x,y,n,h,accent) end;if showValue and h>=2 then UI.text(x+math.max(1,w-6),y+math.floor(h/2),string.format("%3.0f%%",p),UI.C.white,accent) end
end
function UI.vbar(x,y,w,h,p,accent)
 accent=accent or UI.C.cyan;p=math.max(0,math.min(100,tonumber(p) or 0));UI.rect(x,y,w,h,UI.C.panel2);local n=math.floor(h*p/100);if n>0 then UI.rect(x,y+h-n,w,n,accent) end
end
function UI.badge(x,y,on,label,accent)
 accent=accent or UI.C.green;local c=on and accent or UI.C.off;UI.rect(x,y,2,1,c);UI.text(x+3,y,UI.fit(label or (on and "ONLINE" or "OFFLINE"),UI.W-x-3),on and accent or UI.C.muted,UI.C.panel)
end
function UI.led(x,y,on,accent,label)
 accent=accent or UI.C.green;UI.rect(x,y,3,1,on and accent or UI.C.off);UI.text(x+4,y,UI.fit(label or (on and "ONLINE" or "OFFLINE"),UI.W-x-4),on and accent or UI.C.muted,UI.C.panel)
end
-- Compatibility alias used by older BULDACITY pages.
-- UI.led is the canonical implementation; statusLed keeps existing pages working.
UI.statusLed=UI.led
function UI.gauge(x,y,w,label,value,min,max,accent,unit)
 accent=accent or UI.C.cyan;min=tonumber(min) or 0;max=tonumber(max) or 100;value=tonumber(value) or 0;local p=max>min and (value-min)/(max-min)*100 or 0;UI.text(x,y,label,UI.C.muted,UI.C.panel);UI.text(x+w-10,y,string.format("%.1f",value)..tostring(unit or ""),accent,UI.C.panel);UI.bar(x,y+1,w,p,accent,false)
end
function UI.ring(x,y,r,p,accent)
 accent=accent or UI.C.cyan;r=math.max(2,math.floor(r));p=math.max(0,math.min(100,p or 0));local seg=math.max(1,math.floor(12*p/100));local glyphs={"◴","◷","◶","◵"};local g=glyphs[(seg%4)+1];UI.text(x,y,g,accent,UI.C.panel);UI.text(x+2,y,string.format("%3.0f%%",p),accent,UI.C.panel)
end
function UI.sparkline(x,y,w,h,values,accent)
 accent=accent or UI.C.cyan;w=math.max(2,w);h=math.max(2,h);UI.rect(x,y,w,h,UI.C.panel2);if type(values)~="table" or #values<2 then return end
 local lo,hi=values[1],values[1];for i=2,#values do local v=tonumber(values[i]) or 0;if v<lo then lo=v end;if v>hi then hi=v end end
 local span=hi-lo;if span==0 then span=1 end
 local lastX=x;local lastY=y+h-1-math.floor(((values[1]-lo)/span)*(h-1));
 for i=2,#values do local xx=x+math.floor((i-1)*(w-1)/(#values-1));local yy=y+h-1-math.floor(((tonumber(values[i]) or lo)-lo)/span*(h-1));if xx>lastX then UI.text(lastX,lastY,"·",accent,UI.C.panel2) end;UI.text(xx,yy,"•",accent,UI.C.panel2);lastX,lastY=xx,yy end
end
function UI.graph(x,y,w,h,values,accent,min,max)
 accent=accent or UI.C.cyan;w=math.max(4,w);h=math.max(3,h);UI.rect(x,y,w,h,UI.C.panel2);for gy=1,h-1,2 do UI.rule(x,y+gy,w,UI.C.line) end;if type(values)~="table" or #values<2 then return end
 local lo=tonumber(min);local hi=tonumber(max);if not lo or not hi then lo,hi=values[1],values[1];for i=2,#values do local v=tonumber(values[i]) or 0;if v<lo then lo=v end;if v>hi then hi=v end end end;local span=hi-lo;if span==0 then span=1 end
 for i=1,#values do local v=tonumber(values[i]) or lo;local xx=x+math.floor((i-1)*(w-1)/(#values-1));local yy=y+h-1-math.floor((v-lo)/span*(h-1));UI.rect(xx,yy,1,1,accent) end
end
function UI.icon(x,y,name,accent,scale)
 accent=accent or UI.C.cyan;scale=math.max(1,math.floor(scale or 1));name=string.lower(tostring(name or ""));local p={}
 local function add(a,b) p[#p+1]={a,b} end
 if name:find("power") or name:find("energy") then add(2,1);add(1,2);add(3,2);add(2,3)
 elseif name:find("network") or name:find("modem") then add(1,2);add(2,1);add(3,2);add(2,3);add(1,3);add(3,3)
 elseif name:find("computer") or name:find("pc") then add(1,1);add(2,1);add(3,1);add(1,2);add(3,2);add(1,3);add(2,3);add(3,3)
 elseif name:find("reactor") then add(2,1);add(1,2);add(2,2);add(3,2);add(2,3)
 elseif name:find("gear") or name:find("machine") then add(2,1);add(1,2);add(2,2);add(3,2);add(2,3)
 elseif name:find("disk") or name:find("storage") then add(1,1);add(2,1);add(3,1);add(1,2);add(3,2);add(1,3);add(2,3);add(3,3)
 elseif name:find("printer") then add(1,1);add(2,1);add(3,1);add(2,2);add(1,3);add(2,3);add(3,3)
 elseif name:find("fluid") or name:find("tank") then add(2,1);add(1,2);add(3,2);add(1,3);add(3,3)
 else add(1,1);add(2,2);add(3,3) end
 for _,q in ipairs(p) do UI.rect(x+(q[1]-1)*scale,y+(q[2]-1)*scale,scale,scale,accent) end
end
function UI.card(x,y,w,h,iconName,title,value,percent,accent)
 accent=accent or UI.C.cyan;UI.panel(x,y,w,h,title,accent);UI.icon(x+2,y+2,iconName,accent,1);UI.text(x+8,y+2,UI.fit(value,w-10),UI.C.white,UI.C.panel);if percent~=nil then UI.bar(x+2,y+h-2,w-4,percent,accent,false) end
end
function UI.footer(items)
 local y=UI.H-2;local x=2;local gap=1;local bw=math.max(7,math.floor((UI.W-4-(#items-1)*gap)/#items));for _,b in ipairs(items) do UI.button(b[1],x,y,bw,b[2],b[3] or UI.C.cyan,b[4]);x=x+bw+gap end
end
function UI.statusLine(text,accent)
 UI.text(2,UI.H,UI.fit(text,UI.W-4),accent or UI.C.muted,UI.C.bg)
end
return UI
