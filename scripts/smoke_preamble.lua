--!nonstrict
--[[
	smoke_preamble.lua — stubbed Roblox/executor environment for the lune smoke test.

	verify.py concatenates:  this file  +  pcall-wrapped dist/main.lua  +  smoke_assert.lua
	into scripts/.smoke/combined.lua and runs it with `lune run`.

	The stubs are permissive on purpose: the driver wraps every feature in
	guard()/pcall, so un-stubbable engine calls degrade into recorded warnings
	instead of aborting the run. What the smoke test PROVES:

	  1. dist/main.lua compiles and executes top-to-bottom under a Luau runtime
	  2. the require shim resolves every module (source + code modules)
	  3. the SOURCE payload really compiles (loadstring stub uses lune's luau.load)
	     and its content matches the extracted payload (newline-normalized)
	  4. BOOT_DATA is JSON-decoded byte-exactly by the driver's Remote bootstrap
]]

local fs = require("@lune/fs")
local serde = require("@lune/serde")
local luau = require("@lune/luau")

-- ===== observation tables (read by smoke_assert.lua) =====
SMOKE = {
	compiled = {},          -- every loadstring() attempt
	json_decoded = {},      -- every HttpService:JSONDecode(s) payload
	warns = {},             -- warn() messages
	writes = {},            -- writefile() calls
	spawns = 0,
	waits = 0,
	driver_ok = nil,
	driver_err = nil,
}

-- expected values, read from the extraction manifest
local extractManifest = serde.decode("json", fs.readFile("scripts/extract_manifest.json"))
SMOKE.expected = {}
for name, meta in pairs(extractManifest.payloads) do
	SMOKE.expected[name] = meta.chars
end
SMOKE.boot_data_file = fs.readFile("assets/boot_data.json")

-- Luau normalizes CRLF -> LF inside long-bracket strings at compile time;
-- the runtime SOURCE string therefore equals the normalized payload file.
SMOKE.expected_source_normalized = fs.readFile("src/neverlose/init.lua"):gsub("\r\n", "\n")



-- watchdog: the driver chunk must return within 60s of wall time
do
	local taskLibW = require("@lune/task")
	local processW = require("@lune/process")
	taskLibW.delay(60, function()
		print("SMOKE_TIMEOUT driver chunk did not return in 60s")
		print(("SMOKE_STATE spawns=%d waits=%d compiled=%d json=%d writes=%d warns=%d"):format(
			SMOKE.spawns, SMOKE.waits, #SMOKE.compiled, #SMOKE.json_decoded, #SMOKE.writes, #SMOKE.warns))
		processW.exit(2)
	end)
end

-- ===== permissive "anything" object =====
-- NOTE: Luau forbids setmetatable on functions, so the universal stub is a
-- callable TABLE: it survives calls, field reads, writes, # and concat.
local function make_anything(name)
	local t = {}
	setmetatable(t, {
		__call = function()
			return t
		end,
		__index = function(_, key)
			if key == "ClassName" then return name or "Instance" end
			return t
		end,
		__newindex = function() end,
		__tostring = function()
			return "<stub " .. tostring(name) .. ">"
		end,
		__len = function()
			return 0
		end,
		__concat = function()
			return t
		end,
		__add = function()
			return 0
		end,
		__sub = function()
			return 0
		end,
		__mul = function()
			return 0
		end,
		__div = function()
			return 0
		end,
		__mod = function()
			return 0
		end,
		__pow = function()
			return 0
		end,
		__idiv = function()
			return 0
		end,
		__unm = function()
			return 0
		end,
		__lt = function()
			return false
		end,
		__le = function()
			return false
		end,
	})
	return t
end

-- ===== executor globals =====
GENV = {}
getgenv = function()
	return GENV
end

-- in-memory executor filesystem (paths are exact strings, executor-style)
SMOKE_FS = {}
local function norm(path)
	return tostring(path):gsub("\\", "/")
end
readfile = function(path)
	local p = norm(path)
	local body = SMOKE_FS[p]
	if body == nil then error("readfile: no such file: " .. p, 2) end
	return body
end
isfile = function(path)
	return SMOKE_FS[norm(path)] ~= nil
end
writefile = function(path, body)
	local p = norm(path)
	SMOKE_FS[p] = tostring(body)
	SMOKE.writes[#SMOKE.writes + 1] = p
end
isfolder = function(path)
	local p = norm(path)
	local prefix = p .. "/"
	for key in pairs(SMOKE_FS) do
		if key:sub(1, #prefix) == prefix or key == p then
			return true
		end
	end
	return false
end
makefolder = function() end
delfile = function(path)
	SMOKE_FS[norm(path)] = nil
	return true
end
delete_file = delfile
listfiles = function(path)
	local p = norm(path)
	local out, seen = {}, {}
	local prefix = p .. "/"
	for key in pairs(SMOKE_FS) do
		if key:sub(1, #prefix) == prefix then
			local rest = key:sub(#prefix + 1)
			if rest:find("/", 1, true) == nil and not seen[key] then
				seen[key] = true
				out[#out + 1] = key
			end
		end
	end
	return out
end

gethui = function()
	return make_anything("gethui")
end
cloneref = function(ref)
	return ref
end
getcustomasset = function()
	return "rbxasset://smoke-stub"
end
getidentity = function()
	return 8
end
setthreadidentity = function() end
identifyexecutor = function()
	return "smoke-stub", "0.0.0"
end

-- loadstring: REALLY compiles the payload with luau.load, then hands back a
-- proxy chunk (the real payload is never executed in the smoke run).
loadstring = function(source, chunkname)
	local ok, result = pcall(luau.load, source)
	SMOKE.compiled[#SMOKE.compiled + 1] = {
		chunk = chunkname,
		length = #source,
		source = source,
		ok = ok,
		err = ok and nil or tostring(result),
	}
	if not ok then
		return nil, tostring(result)
	end
	local proxy = make_anything("chunk:" .. tostring(chunkname))
	return function()
		return proxy
	end, nil
end

-- warn capture
warn = function(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[i] = tostring(select(i, ...))
	end
	SMOKE.warns[#SMOKE.warns + 1] = table.concat(parts, " ")
end

-- task passthrough (real scheduler) with spawn/wait instrumentation
local taskLib = require("@lune/task")
local rawSpawn = taskLib.spawn
local rawWait = taskLib.wait
task = setmetatable({}, { __index = taskLib })
function task.spawn(fn, ...)
	SMOKE.spawns += 1
	return rawSpawn(fn, ...)
end
function task.wait(seconds, ...)
	SMOKE.waits += 1
	if SMOKE.waits % 500 == 0 then
		print("SMOKE_HEARTBEAT wait#" .. SMOKE.waits)
	end
	return rawWait(seconds, ...)
end

-- ===== Roblox services =====
local HttpServiceStub = {}
function HttpServiceStub:JSONDecode(...)
	-- colon call: ... holds the payload (self is bound by the colon syntax)
	local payload = select(select("#", ...), ...)
	SMOKE.json_decoded[#SMOKE.json_decoded + 1] = payload
	if payload == nil then return nil end
	return serde.decode("json", payload)
end
function HttpServiceStub:JSONEncode(_, value)
	return serde.encode("json", value)
end
function HttpServiceStub:UrlEncode(_, value)
	local s = tostring(value)
	s = s:gsub("([^%w_.%~%-])", function(c)
		return ("%%%02X"):format(c:byte())
	end)
	return s
end
function HttpServiceStub:GenerateGUID(_)
	return "00000000-0000-0000-0000-000000000000"
end
function HttpServiceStub:GetAsync(_, url)
	error("GetAsync stubbed (network disabled in smoke test): " .. tostring(url), 2)
end

local services = {
	HttpService = HttpServiceStub,
}
game = setmetatable({}, {
	__index = function(_, name)
		if name == "GetService" then
			return function(_, service)
				local cached = services[service]
				if cached == nil then
					cached = make_anything("service:" .. service)
					services[service] = cached
				end
				return cached
			end
		end
		return make_anything("game." .. tostring(name))
	end,
})
workspace = make_anything("workspace")
script = make_anything("script")
shared = {}
Instance = setmetatable({ new = function(className)
	return make_anything("Instance:" .. tostring(className))
end }, {
	__index = function()
		return make_anything("Instance.static")
	end,
})
Enum = setmetatable({}, {
	__index = function()
		return make_anything("Enum.item")
	end,
})

-- Roblox value/namespace stubs — assigned DIRECTLY as globals (in lune,
-- _G[k] = v does NOT create an environment-visible global).
UDim = make_anything("UDim")
UDim2 = make_anything("UDim2")
Vector2 = make_anything("Vector2")
Vector3 = make_anything("Vector3")
Color3 = make_anything("Color3")
CFrame = make_anything("CFrame")
Font = make_anything("Font")
Random = make_anything("Random")
TweenInfo = make_anything("TweenInfo")
NumberRange = make_anything("NumberRange")
NumberSequence = make_anything("NumberSequence")
NumberSequenceKeypoint = make_anything("NumberSequenceKeypoint")
ColorSequence = make_anything("ColorSequence")
ColorSequenceKeypoint = make_anything("ColorSequenceKeypoint")
BrickColor = make_anything("BrickColor")
Ray = make_anything("Ray")
Rect = make_anything("Rect")
Region3 = make_anything("Region3")
DateTime = make_anything("DateTime")
Drawing = make_anything("Drawing")
