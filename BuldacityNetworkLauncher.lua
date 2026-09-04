-- BuldacityNetworkLauncher.lua
-- Common helper used by Buldacity controller wrappers.
local M={}
function M.run(app,core)
  local ok,net=pcall(require,"BuldacityNetworkClient")
  if ok and net then pcall(net.start,app,"CLIENT",{screen="ACTIVE",version="BULDACITY/1"}) end
  local shellOk,shell=pcall(require,"shell")
  if shellOk and shell then
    local path=shell.resolve(core)
    if path then return dofile(path) end
  end
  return dofile(core)
end
return M
