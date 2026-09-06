-- BULDACITY Modern Client startup helper
-- Usage: dofile("/home/clients/Startup.lua") from a client installation.
local shell=require("shell")
local computer=require("computer")
local args={...}
local target=args[1]
if not target or target=="" then
  io.stderr:write("Usage: Startup.lua <controller.lua>\n")
  return false
end
local path=shell.resolve(target)
local f=io.open(path,"r")
if not f then io.stderr:write("Controller not found: "..path.."\n");return false end
f:close()
return dofile(path)
