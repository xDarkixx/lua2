-- BULDACITY TIER-3 PERSISTENT STATE
local filesystem=require("filesystem")
local serialization=require("serialization")
local M={file="/home/buldacity-tier3/state.dat"}
function M.init(path)
  if path then M.file=path end
  local dir=M.file:match("^(.+)/[^/]+$")
  if dir then pcall(filesystem.makeDirectory,dir) end
end
function M.load(default)
  if not filesystem.exists(M.file) then return default end
  local f=io.open(M.file,"r");if not f then return default end
  local raw=f:read("*a");f:close()
  local ok,data=pcall(serialization.unserialize,raw)
  if ok and type(data)=="table" then return data end
  return default
end
function M.save(data)
  local tmp=M.file..".tmp"
  local f=io.open(tmp,"w");if not f then return false,"OPEN" end
  local ok,raw=pcall(serialization.serialize,data)
  if not ok then f:close();filesystem.remove(tmp);return false,"SERIALIZE" end
  f:write(raw);f:close()
  if filesystem.exists(M.file) then filesystem.remove(M.file) end
  local moved=filesystem.rename(tmp,M.file)
  return moved and true or false,"RENAME"
end
return M
