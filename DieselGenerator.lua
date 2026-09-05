-- DieselGenerator.lua
-- BULDACITY entry point for the Immersive Engineering Diesel Generator.
-- Minecraft 1.7.10 / OpenComputers 1.8.10
--
-- The old version accessed component.ie_diesel_generator directly and failed
-- with "component not found" when the adapter/component was not primary.
-- Use the robust modern controller instead.

local shell=require("shell")
local HOME="/home/"
pcall(function()shell.setWorkingDirectory(HOME)end)
package.path=HOME.."?.lua;"..HOME.."?/init.lua;"..(package.path or "")

dofile(HOME.."DieselGenerator_Modern.lua")
