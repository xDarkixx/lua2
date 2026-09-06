-- BULDACITY SGCraft2 installer
-- OpenComputers / Minecraft 1.7.10
-- Installs the complete application below /home/sgcraft2.

local component=require("component")
local computer=require("computer")

local ROOT="/home/sgcraft2"
local BASE="https://raw.githubusercontent.com/xDarkixx/lua2/main/sgcraft2/"

local files={
  {"SGCraft2.lua",ROOT.."/SGCraft2.lua"},
  {"lib/SGCraftAPI.lua",ROOT.."/lib/SGCraftAPI.lua"},
  {"lib/SGCraftVisual.lua",ROOT.."/lib/SGCraftVisual.lua"},
  {"stargate/SGCraft2.lua",ROOT.."/stargate/SGCraft2.lua"},
}

local function mkdir(path)
  local fs=require("filesystem")
  if not fs.exists(path) then
    assert(fs.makeDirectory(path),"cannot create "..path)
  end
end

local function parent(path)
  return path:match("^(.*)/[^/]+$") or "/"
end

local function writeFile(path,data)
  mkdir(parent(path))
  local f,err=io.open(path,"wb")
  if not f then return false,err end
  f:write(data)
  f:close()
  return true
end

local function download(url)
  local internet=component.internet
  if not internet then return nil,"Internet Card not found" end
  local ok,handle=pcall(internet.request,url)
  if not ok or not handle then return nil,tostring(handle or "request failed") end
  local chunks={}
  while true do
    local okRead,data=pcall(handle)
    if not okRead then return nil,tostring(data) end
    if data==nil then break end
    chunks[#chunks+1]=data
  end
  return table.concat(chunks)
end

local function verify(path)
  local f=io.open(path,"r")
  if not f then return false,"cannot open" end
  f:close()
  local ok,fn=pcall(loadfile,path)
  if not ok or not fn then return false,tostring(fn or "Lua syntax error") end
  return true
end

print("========================================")
print(" BULDACITY // SGCraft2 INSTALLER")
print(" Install root: "..ROOT)
print("========================================")

mkdir(ROOT);mkdir(ROOT.."/lib");mkdir(ROOT.."/stargate")

for _,item in ipairs(files) do
  local source,path=item[1],item[2]
  print("DOWNLOAD  "..source)
  local data,err=download(BASE..source)
  if not data then
    error("Download failed: "..source.." / "..tostring(err))
  end
  local ok,writeErr=writeFile(path,data)
  if not ok then error("Write failed: "..path.." / "..tostring(writeErr)) end
  local verified,verifyErr=verify(path)
  if not verified then error("Verification failed: "..path.." / "..tostring(verifyErr)) end
  print("OK        "..path)
end

local autorun="/home/autorun.lua"
local af=io.open(autorun,"w")
if af then
  af:write("return dofile(\"/home/sgcraft2/SGCraft2.lua\")\n")
  af:close()
  print("AUTORUN   "..autorun)
else
  print("WARNING   could not write "..autorun)
end

print("----------------------------------------")
print("INSTALL COMPLETE")
print("Start: dofile(\"/home/sgcraft2/SGCraft2.lua\")")
print("Reboot to use /home/autorun.lua")
print("----------------------------------------")
computer.beep(1000,0.1)
