-- BULDACITY Network compatibility loader for OpenOS require("Network").
-- The project keeps the canonical Network.lua at the repository root.
-- OpenOS require searches library paths such as /lib, so this loader bridges
-- both root and /home installations without duplicating the network library.

local filesystem=require("filesystem")

local candidates={
  "/Network.lua",
  "/home/Network.lua",
  "/usr/lib/Network.lua"
}

for i=1,#candidates do
  local path=candidates[i]
  if filesystem.exists(path) and not filesystem.isDirectory(path) then
    local ok,result=pcall(dofile,path)
    if ok then return result end
    error("BULDACITY Network load failed: "..tostring(result))
  end
end

error("BULDACITY Network.lua not found. Checked /Network.lua, /home/Network.lua and /usr/lib/Network.lua")
