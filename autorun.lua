-- BULDACITY / 2 OpenComputers autorun
-- The installer places this file in /home automatically.
local ok, err = pcall(function()
  dofile("/home/BuldacityAutoStart.lua")
end)
if not ok then
  print("BULDACITY AUTOSTART FEHLER: " .. tostring(err))
end
