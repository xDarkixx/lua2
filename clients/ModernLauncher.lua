-- Modern launcher.
-- Runs an existing *_Modern.lua without modifying or replacing it.
-- Modern controllers resolve Network through the centralized root Network.lua.
local shell=require("shell")
local target=...
if not target or target=="" then
  io.stderr:write("Usage: ModernLauncher.lua <file_Modern.lua>\n")
  return
end

local path=shell.resolve(target)
local file=io.open(path,"r")
if not file then
  io.stderr:write("Modern file not found: "..tostring(path).."\n")
  return
end
file:close()

return dofile(path)
