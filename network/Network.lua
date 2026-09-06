-- BULDACITY/2 organized entry point.
-- Compatibility wrapper: keeps the original root Network.lua unchanged.
-- Run from any OpenComputers working directory.
local path = "/home/Network.lua"
if filesystem and filesystem.exists and filesystem.exists(path) then
  return dofile(path)
end
local ok, result = pcall(dofile, path)
if not ok then error("BULDACITY Network: /home/Network.lua not found: " .. tostring(result)) end
return result
