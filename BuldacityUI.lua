-- BuldacityUI.lua
-- Shared graphical design system for OpenComputers Tier-3 dashboards.
local component=require("component")
local gpu=component.gpu
local UI={W=80,H=25,buttons={}}
UI.C={bg=0x070B12,panel=0x0D1520,panel2=0x121E2C,line=0x263D52,cyan=0x39E7FF,blue=0x5B8CFF,green=0x43F59B,red=0xFF5577,yellow=0xFFE36A,purple=0xC778FF,orange=0xFF9F4A,white=0xF3F8FF,muted=0x8298AA,off=0x273543}
local function safe(f,...)
 local ok,a,b=pcall(f,...);if ok then return a,b end
end
function UI.resize() local w,h=safe(gpu.getResolution);UI.W=w or 80;UI.H=h or 25;return UI.W,UI.H end
function UI.clear() UI.resize();gpu.setBackground(UI.C.bg);gpu.setForeground(UI.C.white);gpu.fill(1,1,UI.W,UI.H," ");UI.buttons={} end
function UI.text(x,y,s,fg,bg) if x<1 or y<1 or x>UI.W or y>UI.H then return end;gpu.setForeground(fg or UI.C.white);gpu.setBackground(bg or UI.C.bg);gpu.set(x,y,tostring(s or "")) end
function UI.fit(s,n) s=tostring(s or "");n=math.max(1,n or 1);if #s<=n then return s end;return n<=3 and s:sub(1,n) or s:sub(1,n-3).."..." end
function UI.header(title,subtitle,accent) accent=accent or UI.C.cyan;gpu.setBackground(UI.C.panel);gpu.fill(1,1,UI.W,4," ");UI.text(2,1,"BULDACITY",accent,UI.C.panel);UI.text(13,1,"//",UI.C.line,UI.C.panel);UI.text(16,1,UI.fit(title,UI.W-17),UI.C.white,UI.C.panel);if subtitle then UI.text(2,2,UI.fit(subtitle,UI.W-4),UI.C.muted,UI.C.panel) end;gpu.setBackground(accent);gpu.fill(1,4,UI.W,1," ") end
function UI.panel(x,y,w,h,title,accent) accent=accent or UI.C.cyan;gpu.setBackground(UI.C.panel);gpu.fill(x,y,w,h," ");gpu.setBackground(accent);gpu.fill(x,y,w,1," ");UI.text(x+2,y,"◆ "..UI.fit(title,w-5),UI.C.white,accent) end
function UI.button(id,x,y,w,label,accent,active) accent=accent or UI.C.cyan;w=math.max(6,w);UI.buttons[id]={x=x,y=y,w=w,h=2};gpu.setBackground(active and UI.C.white or accent);gpu.fill(x,y,w,2," ");local fg=active and accent or UI.C.white;UI.text(x+math.max(1,math.floor((w-#label)/2)),y,UI.fit(label,w-2),fg,active and UI.C.white or accent) end
function UI.hit(id,x,y) local b=UI.buttons[id];return b and x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h end
function UI.bar(x,y,w,p,accent) accent=accent or UI.C.cyan;p=math.max(0,math.min(100,tonumber(p) or 0));w=math.max(1,w);gpu.setBackground(UI.C.panel2);gpu.fill(x,y,w,1," ");local n=math.floor(w*p/100);if n>0 then gpu.setBackground(accent);gpu.fill(x,y,n,1," ") end end
function UI.badge(x,y,on,label,accent) accent=accent or UI.C.green;gpu.setBackground(on and accent or UI.C.off);gpu.fill(x,y,2,1," ");UI.text(x+3,y,UI.fit(label or (on and "ONLINE" or "OFFLINE"),UI.W-x-3),on and accent or UI.C.muted,UI.C.panel) end
function UI.footer(items) local y=UI.H-2;local x=2;local gap=1;local bw=math.max(8,math.floor((UI.W-4-(#items-1)*gap)/#items));for _,b in ipairs(items) do UI.button(b[1],x,y,bw,b[2],b[3] or UI.C.cyan,b[4]);x=x+bw+gap end end
return UI
