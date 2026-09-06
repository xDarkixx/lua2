-- BULDACITY TIER-3 LOGGER
local filesystem=require("filesystem")
local computer=require("computer")
local M={file="/home/buldacity-tier3/tier3.log",maxBytes=262144}
local function ensure()
  local dir=M.file:match("^(.+)/[^/]+$")
  if dir then pcall(filesystem.makeDirectory,dir) end
end
function M.init(path) if path then M.file=path end;ensure() end
function M.write(level,message,data)
  ensure()
  local f=io.open(M.file,"a")
  if not f then return false end
  local extra=""
  if type(data)=="table" then extra=" | "..tostring(data.event or data.reason or data.id or "") end
  f:write(string.format("[%10.2f] %-7s %s%s\n",computer.uptime(),tostring(level),tostring(message),extra));f:close()
  local size=filesystem.size(M.file)
  if size and size>M.maxBytes then
    local src=io.open(M.file,"r");local content=src and src:read("*a") or "";if src then src:close() end
    content=content:sub(math.floor(#content/2));local dst=io.open(M.file,"w");if dst then dst:write(content);dst:close() end
  end
  return true
end
function M.info(m,d)return M.write("INFO",m,d)end
function M.warn(m,d)return M.write("WARN",m,d)end
function M.error(m,d)return M.write("ERROR",m,d)end
return M
