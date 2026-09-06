-- ModernRemote.lua
-- Companion service for existing *_Modern.lua controllers.
-- It does not modify or replace their local graphical interfaces. Instead it
-- publishes a compact remote UI scene + telemetry through the Modern network.
local component=require("component")
local computer=require("computer")
local event=require("event")
local filesystem=require("filesystem")
local serialization=require("serialization")
local Network=require("network-modern.Network")

local INTERVAL=2
local running=true
local function safe(fn,...)
  local ok,a,b=pcall(fn,...)
  if ok then return a,b end
end

local function modernApps()
  local out={}
  local ok,it=pcall(filesystem.list,"/home")
  if ok and it then
    for name in it do
      name=tostring(name)
      if name:match("_Modern%.lua$") then out[#out+1]=name:gsub("%.lua$","") end
    end
  end
  table.sort(out)
  return out
end

local function components()
  local out={}
  for address,ctype in component.list() do
    local s=tostring(ctype):lower()
    if s~="gpu" and s~="screen" and s~="modem" then
      out[#out+1]={id=address,type=ctype}
      if #out>=24 then break end
    end
  end
  return out
end

local function frame()
  local gpu=component.isAvailable("gpu") and component.gpu or nil
  local w,h=80,25
  if gpu then w,h=safe(gpu.getResolution) or 80,safe(gpu.getResolution) or 25 end
  return {
    kind="MODERN_REMOTE_UI",
    title="MODERN CONTROL CENTER",
    mode="REMOTE_SCENE",
    note="UI scene/telemetry channel; local GPU framebuffer is not read.",
    resolution={w=w,h=h},
    uptime=computer.uptime(),
    apps=modernApps(),
    components=components(),
    network=Network.status(),
    actions={
      {id="refresh",label="REFRESH",action="refresh"},
      {id="ping",label="PING NODE",action="ping"},
    }
  }
end

local function publish()
  local ok,err=Network.publishUI(frame())
  if not ok then io.stderr:write("ModernRemote: "..tostring(err).."\n") end
end

local ok,err=Network.startClient("MODERN REMOTE UI",{service="ModernRemote",ui=true})
if not ok then error("ModernRemote network unavailable: "..tostring(err)) end
publish()
event.timer(INTERVAL,publish,math.huge)
while running do
  local e=event.pull(30)
  if e and e[1]=="key_down" and e[3]==113 then running=false end
end
