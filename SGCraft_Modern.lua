-- BULDACITY SGCraft compatibility entry point.
-- Bootstraps the realistic v3 Stargate controller and its libraries.
local component=require("component")
local filesystem=require("filesystem")
local files={
 {path="/home/SGCraft_Buldacity_v3.lua",url="https://raw.githubusercontent.com/xDarkixx/lua2/main/SGCraft_Buldacity_v3.lua"},
 {path="/home/SGCraftAPI.lua",url="https://raw.githubusercontent.com/xDarkixx/lua2/main/clients/sgcraft/SGCraftAPI.lua"},
 {path="/home/SGCraftVisual.lua",url="https://raw.githubusercontent.com/xDarkixx/lua2/main/clients/sgcraft/SGCraftVisual.lua"}
}
local function download(f)
 if not component.isAvailable("internet") then return false,"Internet Card fehlt" end
 local h,e=component.internet.request(f.url);if not h then return false,tostring(e or "HTTP request failed") end
 local out,oe=filesystem.open(f.path,"w");if not out then return false,tostring(oe or "cannot open target") end
 local n=0;while true do local s=h();if s==nil then break end;if #s>0 then out:write(s);n=n+#s end end;out:close();if n==0 then return false,"downloaded file is empty" end;return true
end
for _,f in ipairs(files) do if not filesystem.exists(f.path) then local ok,e=download(f);if not ok then error("BULDACITY SGCraft bootstrap failed: "..e) end end end
return dofile("/home/SGCraft_Buldacity_v3.lua")
