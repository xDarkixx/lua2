-- BULDACITY TIER-3 MONITOR
local component=require("component")
local computer=require("computer")
local event=require("event")
local M={gpu=nil,screen=nil,started=false}
local function setup()
  if not component.isAvailable("gpu") then return false end
  M.gpu=component.gpu
  for a,_ in component.list("screen",true) do M.screen=a;break end
  if M.screen then pcall(function()M.gpu.bind(M.screen)end) end
  return true
end
local function line(y,text,w)
  M.gpu.fill(1,y,w or 80,1," ");M.gpu.set(2,y,tostring(text):sub(1,(w or 80)-2))
end
function M.render(state)
  if not M.gpu and not setup() then return false end
  local w,h=M.gpu.getResolution();M.gpu.setBackground(0x0A0F18);M.gpu.setForeground(0xE8EEF7);M.gpu.fill(1,1,w,h," ")
  line(1,"BULDACITY  |  TIER-3 CENTRAL SERVER",w)
  line(2,string.rep("-",math.min(w,80)),w)
  local nodes=state.nodes or {};local relays=state.relays or {};local stats=state.stats or {}
  line(4,"SERVER      TIER3-CORE",w);line(5,"PROTOCOL    BULDACITY / PORT 31337",w)
  line(7,"NODES       "..tostring(state.nodeCount or 0),w);line(8,"RELAYS      "..tostring(state.relayCount or 0),w)
  line(10,"RECEIVED    "..tostring(stats.received or 0),w);line(11,"ROUTED      "..tostring(stats.routed or 0),w);line(12,"NO ROUTE    "..tostring(stats.noRoute or 0),w);line(13,"INVALID     "..tostring(stats.invalid or 0),w)
  line(15,"ACTIVE NODES",w);local y=16
  for id,n in pairs(nodes) do if y>h-2 then break end local age=n.last and (computer.uptime()-n.last) or 999;local status=age<20 and "ONLINE" or "OFFLINE";line(y,string.format("%-24s %-9s %-10s",id,status,tostring(n.role or "NODE")),w);y=y+1 end
  line(h,"ESC/CTRL-C stops server",w);return true
end
function M.start(stateProvider,interval)
  if M.started then return end;M.started=true
  event.timer(interval or 2,function()local ok,s=pcall(stateProvider);if ok and s then pcall(M.render,s)end end,math.huge)
end
return M
