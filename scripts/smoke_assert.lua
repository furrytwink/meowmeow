--!nonstrict
--[[
	smoke_assert.lua — trailing assertions for the lune smoke test.
	Runs AFTER the pcall-wrapped dist/main.lua body in scripts/.smoke/combined.lua.
	Prints SMOKE markers consumed by scripts/verify.py; exits non-zero on failure.
]]

local serde = require("@lune/serde")

local failures = {}

-- 1. driver survived to the end without a hard (unguarded) error
if SMOKE.driver_ok ~= true then
	failures[#failures + 1] = "driver aborted: " .. tostring(SMOKE.driver_err)
end

-- 2. SOURCE payload was loadstring'd as "@adapter"; compare content against
--    the extracted payload (Luau normalizes CRLF -> LF at compile time, so
--    the expected string is normalized the same way).
local adapterSource
for _, entry in ipairs(SMOKE.compiled) do
	if entry.chunk == "@adapter" and entry.ok then
		adapterSource = entry.source
	end
end
if not adapterSource then
	failures[#failures + 1] = "SOURCE was never compiled via loadstring('@adapter')"
elseif adapterSource ~= SMOKE.expected_source_normalized then
	failures[#failures + 1] = "SOURCE content at runtime differs from normalized src/neverlose/init.lua"
end

-- 3. SKIN_SOURCE payload compiled as "@skins"
local skinsSeen = false
for _, entry in ipairs(SMOKE.compiled) do
	if entry.chunk == "@skins" and entry.ok then
		skinsSeen = true
	end
end
if not skinsSeen then
	-- skins only mount when IS_MM2 is true; record but do not fail on it
	print("SMOKE_NOTE skins chunk not compiled (game-gated path)")
end

-- 4. BOOT_DATA JSON-decoded byte-exactly by the driver
local bootSeen, bootExact = false, false
for _, payload in ipairs(SMOKE.json_decoded) do
	bootSeen = true
	if payload == SMOKE.boot_data_file then
		bootExact = true
		break
	end
end
if not bootSeen then
	failures[#failures + 1] = "HttpService:JSONDecode never received BOOT_DATA"
elseif not bootExact then
	failures[#failures + 1] = "BOOT_DATA decoded by driver does not match assets/boot_data.json byte-for-byte"
end

-- 5. every loadstring attempt must have compiled cleanly
for _, entry in ipairs(SMOKE.compiled) do
	if not entry.ok then
		failures[#failures + 1] = ("loadstring(%s) failed to compile: %s"):format(
			tostring(entry.chunk), tostring(entry.err))
	end
end

-- compile-failed payloads ALSO mean loadstring returned nil -> driver assert
-- would abort; covered by check 1, but the explicit loop above pinpoints it.

local results = {
	driver_ok = SMOKE.driver_ok,
	compiled = #SMOKE.compiled,
	json_decoded = #SMOKE.json_decoded,
	warns = #SMOKE.warns,
	spawns = SMOKE.spawns,
	writes = #SMOKE.writes,
	failures = failures,
}
print("SMOKE_RESULT " .. serde.encode("json", results))

local process = require("@lune/process")

if #failures > 0 then
	for _, message in ipairs(failures) do
		print("SMOKE_FAIL " .. message)
	end
	print("SMOKE_EXIT fail")
	process.exit(1)
end

-- The driver intentionally keeps running (UI render loop threads); the chunk
-- itself has returned and all observations are recorded, so exit now instead
-- of idling in the scheduler forever.
print("SMOKE_PASS")
print("SMOKE_EXIT pass")
process.exit(0)
