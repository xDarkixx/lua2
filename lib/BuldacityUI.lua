-- BULDACITY UI compatibility loader for OpenOS require("BuldacityUI").
-- The canonical UI library remains at the repository root.

local filesystem=require("filesystem")

local candidates={
  "/BuldacityUI.lua",
  "/home/BuldacityUI.lua",
  "/usr/lib/BuldacityUI.lua"
}

for i=1,#candidates do
  local path=candidates[i]
  if filesystem.exists(path) and not filesystem.isDirectory(path) then
    local ok,result=pcall(dofile,path)
    if ok then return result end
    error("BULDACITY UI load failed: "..tostring(result))
  end
end

error("BuldacityUI.lua not found. Checked /BuldacityUI.lua, /home/BuldacityUI.lua and /usr/lib/BuldacityUI.lua")
