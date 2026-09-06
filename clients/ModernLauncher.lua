-- BULDACITY Modern launcher.
-- Runs an existing *_Modern.lua without modifying or replacing it.
-- The legacy module name "Network" is redirected to the modern central API.
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

package.preload["Network"]=function()
  return require("clients.network.ModernNetworkCompat")
end

return dofile(path)
