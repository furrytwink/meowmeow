--!nonstrict
--[[
	assets/init.lua — BOOT_DATA provider (dev mode).

	The original monolithic script inlined BOOT_DATA as a JSON string inside a
	long-bracket literal. The bootstrap driver expects require("assets") to
	return that exact JSON string (the driver runs
	HttpService:JSONDecode(BOOT_DATA) and then drops the reference).

	In the bundled dist/main.lua, scripts/bundle.py embeds the JSON from
	assets/boot_data.json verbatim as a source-string module, so this loader is
	bypassed and runtime behavior is byte-identical to the original.

	For un-bundled (dev) execution this loader reads assets/boot_data.json
	relative to getgenv().VISUALS_ROOT (the folder containing assets/).
	If VISUALS_ROOT is unset, the executor workspace root is assumed.
]]
local REL = "assets/boot_data.json"
local ROOT = (getgenv and getgenv().VISUALS_ROOT) or ""

local function fail(message)
	error("[assets] " .. message, 0)
end

if type(readfile) ~= "function" then
	fail("readfile is unavailable; run the bundled dist/main.lua or provide an executor environment.")
end

local path = ROOT .. REL

if type(isfile) == "function" and not isfile(path) then
	fail(
		"missing "
			.. path
			.. " — set getgenv().VISUALS_ROOT to the folder containing assets/, or use the bundled dist/main.lua."
	)
end

local ok, body = pcall(readfile, path)
if not ok or type(body) ~= "string" or body:sub(1, 1) ~= "{" then
	fail("could not read BOOT_DATA JSON from " .. path)
end

return body
