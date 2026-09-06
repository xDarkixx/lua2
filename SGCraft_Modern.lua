-- BULDACITY SGCraft compatibility entry point.
-- Bootstraps the controller and its protected SGCraft API library.

local component=require("component")
local filesystem=require("filesystem")

local files={
  {path="/home/SGCraft_Buldacity.lua",url="https://raw.githubusercontent.com/xDarkixx/lua2/main/SGCraft_Buldacity.lua"},
  {path="/home/SGCraftAPI.lua",url="https://raw.githubusercontent.com/xDarkixx/lua2/main/clients/sgcraft/SGCraftAPI.lua"}
}

local function download(file)
  if not component.isAvailable("internet") then return false,"Internet Card fehlt" end
  local h,err=component.internet.request(file.url)
  if not h then return false,tostring(err or "HTTP request failed") end
  local f,openErr=filesystem.open(file.path,"w")
  if not f then return false,tostring(openErr or "cannot open target") end
  local n=0
  while true do
    local chunk=h()
    if chunk==nil then break end
    if #chunk>0 then f:write(chunk);n=n+#chunk end
  end
  f:close()
  if n==0 then return false,"downloaded file is empty" end
  return true
end

for _,file in ipairs(files) do
  if not filesystem.exists(file.path) then
    local ok,err=download(file)
    if not ok then error("BULDACITY SGCraft bootstrap failed: "..tostring(err)) end
  end
end

return dofile("/home/SGCraft_Buldacity.lua")
