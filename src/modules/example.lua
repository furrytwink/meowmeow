--!nonstrict
--[[
	modules/example.lua — template for new modules.

	Pattern:
	  1. drop a .lua/.luau file into src/modules/
	  2. run `make bundle` — the bundler auto-discovers it and regenerates
	     the modules index (src/modules/init.lua)
	  3. require it as require("modules.<name>") from anywhere in the project

	Module factories run once and are cached; return your public table.
]]
local Example = {}

Example.name = "example"

function Example.hello()
	return "hello from " .. Example.name
end

return Example
