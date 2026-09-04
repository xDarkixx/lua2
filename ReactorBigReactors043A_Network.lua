-- ReactorBigReactors043A_Network.lua
-- Normal controller PC network wrapper for the Big Reactors 0.4.3A app.
local ok,net=pcall(require,"Network")
if ok and net and net.startClient then
  pcall(net.startClient,"Big Reactors",{controller="ReactorBigReactors043A_Touch_Responsive.lua",mod="Big Reactors",version="0.4.3A"})
end
dofile("/ReactorBigReactors043A_Touch_Responsive.lua")
