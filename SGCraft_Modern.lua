-- BULDACITY SGCraft compatibility entry point.
-- Loads the BULDACITY SGCX-style controller and can bootstrap it from GitHub.

local component=require("component")
local filesystem=require("filesystem")

local target="/home/SGCraft_Buldacity.lua"
local url="https://raw.githubusercontent.com/xDarkixx/lua2/main/SGCraft_Buldacity.lua"

local function download()
  if not component.isAvailable("internet") then return false,"Internet Card fehlt" end
  local h,err=component.internet.request(url)
  if not h then return false,tostring(err or "HTTP request failed") end
  local f,openErr=filesystem.open(target,"w")
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

if not filesystem.exists(target) then
  local ok,err=download()
  if not ok then error("BULDACITY SGCraft controller missing: "..tostring(err)) end
end

return dofile(target)
