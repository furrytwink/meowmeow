local ASSETS = ...;

if not LPH_OBFUSCATED then
	local a = function() end
	local g = getgenv and getgenv() or _G
	g.LPH_ATTRIBUTES = a
	g.ENCRYPT, g.VM, g.PRESET, g.OPTIMIZE, g.TRANSFORM, g.ERROR_HANDLING = a, a, a, a, a, a
	g.UNROLL, g.INLINE, g.NO_UPVALUES = a, a, a
	g.NONE, g.OPAL, g.ONYX, g.FAST, g.BALANCED, g.SECURE = a, a, a, a, a, a
	g.EXTRACT, g.CONTROL_FLOW, g.REWRITE_NAMECALLS, g.GLOBALS, g.CONSTANTS = a, a, a, a, a
end

LPH_ATTRIBUTES(VM(NONE), TRANSFORM(EXTRACT))

cloneref = cloneref or function(o) return o end
gethui = gethui or get_hidden_gui
getcustomasset = getcustomasset or getsynasset
getgenv = getgenv or getfenv

do
	local rawHui = gethui or get_hidden_gui
	local function safeHui()
		if type(rawHui) == "function" then
			local ok, result = pcall(rawHui)
			if ok and typeof(result) == "Instance" then return result end
		end
	end

	gethui = safeHui
	get_hidden_gui = safeHui
end

local tws = cloneref(game:GetService("TweenService"))
local txs = cloneref(game:GetService("TextService"))
local uis = cloneref(game:GetService("UserInputService"))
local rs = cloneref(game:GetService("RunService"))
local plrs = cloneref(game:GetService("Players"))
local gus = cloneref(game:GetService("GuiService"))
local lp = plrs.LocalPlayer
local mouse = lp:GetMouse()
local clipput = setclipboard or toclipboard or (clipboard and clipboard.set)
local clipget = getclipboard or readclipboard or (clipboard and clipboard.get)
local hui = gethui and gethui()

if not hui then
	local ok, core = pcall(function() return cloneref(game:GetService("CoreGui")) end)
	hui = ok and core or nil
end

hui = hui or lp:WaitForChild("PlayerGui")
local prot = protect_gui or protectgui or (syn and syn.protect_gui) or function(g) return g end

local visualsui = {}

visualsui.ver = "67"
visualsui.wins = {}
visualsui.conns = {}

local drawmask = getgenv().visuals_drawmask

if type(drawmask) ~= "table" then
	drawmask = {}
	getgenv().visuals_drawmask = drawmask
end

visualsui.drawmask = drawmask

local function maskdel(f)
	for i = #drawmask, 1, -1 do
		if drawmask[i] == f then
			table.remove(drawmask, i)
		end
	end
end

local function maskadd(f)
	for i = #drawmask, 1, -1 do
		local e = drawmask[i]

		if e == f or typeof(e) ~= "Instance" or not e.Parent then
			table.remove(drawmask, i)
		end
	end

	drawmask[#drawmask + 1] = f
end

visualsui.layout = "auto"

local touch = uis.TouchEnabled
local keyboard = uis.KeyboardEnabled
local mouseEnabled = uis.MouseEnabled

local camera = workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
local preferredTouch = false
pcall(function() preferredTouch = uis.PreferredInput == Enum.PreferredInput.Touch end)

local forced = false
pcall(function() forced = getgenv().VISUALS_FORCE_MOBILE == true end)
visualsui.mobile = forced or (touch and (preferredTouch or not mouseEnabled or math.min(viewport.X, viewport.Y) < 700))
visualsui.scale = visualsui.mobile and 0.85 or 1

local sc = visualsui.scale

visualsui.theme = {
	bg = Color3.fromRGB(6, 6, 8),
	side = Color3.fromRGB(12, 12, 15),
	panel = Color3.fromRGB(11, 11, 14),
	head = Color3.fromRGB(15, 15, 18),
	line = Color3.fromRGB(52, 52, 64),
	glow = Color3.fromRGB(150, 152, 175),
	text = Color3.fromRGB(240, 240, 245),
	dim = Color3.fromRGB(122, 122, 134),
	accent = Color3.fromRGB(255, 255, 255),
}

visualsui.icons = {
	activity = 137527339160230,
	banknote = 113703117675594,
	bell = 84691420588185,
	book = 74111869099427,
	bot = 70979486241131,
	box = 117371753006597,
	boxes = 95055252135506,
	brain = 116902501990569,
	bug = 75649814233484,
	car = 91451724283877,
	["car-front"] = 79993076477613,
	check = 86817768619372,
	["chevron-down"] = 71457658246709,
	["chevron-right"] = 101007429951147,
	["chevron-up"] = 98648581502859,
	["circle-dot"] = 122878673716704,
	["clipboard-paste"] = 79192963603923,
	clock = 136533241128438,
	code = 75851496262862,
	copy = 116378866141355,
	pipette = 104047428948587,
	cog = 123222732420633,
	coins = 117341212186115,
	compass = 73836660434977,
	crosshair = 83752373575368,
	crown = 92253403464658,
	database = 99154172590159,
	dices = 116678154854810,
	ellipsis = 101330725759187,
	eye = 127234874352422,
	["eye-off"] = 85207295981701,
	["file-text"] = 92774566080911,
	fish = 114555142566431,
	flame = 125012650497883,
	folder = 77937190465422,
	footprints = 80792036653047,
	["gamepad-2"] = 99293705721130,
	gauge = 128279962545721,
	ghost = 132705178126217,
	globe = 125685532120024,
	hand = 83088528355903,
	heart = 88525382655929,
	home = 109841253338329,
	image = 114022611279795,
	info = 120620848266512,
	key = 83474888140571,
	keyboard = 121978468376124,
	layers = 114499998778667,
	link = 86131768436965,
	list = 101699539545687,
	lock = 119765975153029,
	["log-out"] = 140299936053191,
	map = 131325044235094,
	["map-pin"] = 137091405832737,
	minus = 95070996149109,
	monitor = 70520152532392,
	move = 77028714324861,
	["mouse-pointer"] = 113428527051320,
	package = 106101842173393,
	palette = 127369887384101,
	["person-standing"] = 101118444346965,
	pickaxe = 111300940329486,
	plus = 101123124881873,
	power = 89331085993646,
	radar = 132868138496209,
	["refresh-cw"] = 106497040962250,
	rocket = 109537053598807,
	save = 122894934359450,
	["scan-eye"] = 109514269737059,
	search = 72296609649861,
	send = 94849431195865,
	settings = 106205298246017,
	["settings-2"] = 109485777305919,
	shield = 106509993556171,
	["shield-check"] = 71867984579031,
	shirt = 128162112866809,
	["shopping-cart"] = 79435149356304,
	skull = 101060850237115,
	["sliders-horizontal"] = 125396339381135,
	sparkles = 105634041692696,
	star = 72669221096319,
	["swatch-book"] = 70990631477660,
	sword = 121406454377051,
	swords = 99199363807265,
	target = 121091323240554,
	terminal = 102379915564176,
	["toggle-right"] = 129483325318573,
	["trash-2"] = 126010725826757,
	user = 114567720540659,
	users = 85332511060401,
	["users-round"] = 103880524805720,
	video = 99411215690870,
	["volume-2"] = 129861259578431,
	["wand-sparkles"] = 115623066336607,
	wifi = 104941258142372,
	wrench = 85345725497834,
	x = 116396312853810,
	zap = 109718589733073,
}

local function icon(v)
	if type(v) == "number" then
		return "rbxassetid://" .. v
	end

	if type(v) ~= "string" or v == "" then
		return ""
	end

	if string.find(v, "://", 1, true) then
		return v
	end

	if string.match(v, "^%d+$") then
		return "rbxassetid://" .. v
	end

	local id = visualsui.icons[string.lower(v)]

	return id and ("rbxassetid://" .. id) or ""
end

local shots = {
	asset = "rbxthumb://type=Asset&id=%d&w=150&h=150",
	bundlethumbnail = "rbxthumb://type=BundleThumbnail&id=%d&w=150&h=150",
	avatarheadshot = "rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150",
	avatar = "rbxthumb://type=Avatar&id=%d&w=352&h=352",
	avatarbust = "rbxthumb://type=AvatarBust&id=%d&w=150&h=150",
	gameicon = "rbxthumb://type=GameIcon&id=%d&w=150&h=150",
	gamepass = "rbxthumb://type=GamePass&id=%d&w=150&h=150",
	badgeicon = "rbxthumb://type=BadgeIcon&id=%d&w=150&h=150",
	outfit = "rbxthumb://type=Outfit&id=%d&w=150&h=150",
	group = "rbxthumb://type=GroupIcon&id=%d&w=150&h=150",
}

local terse = {
	LeftAlt = "LAlt",
	RightAlt = "RAlt",
	LeftShift = "LShift",
	RightShift = "RShift",
	LeftControl = "LCtrl",
	RightControl = "RCtrl",
	LeftSuper = "LWin",
	RightSuper = "RWin",
	LeftMeta = "LMeta",
	RightMeta = "RMeta",
	Backspace = "Bksp",
	CapsLock = "Caps",
	Insert = "Ins",
	Delete = "Del",
	PageUp = "PgUp",
	PageDown = "PgDn",
	Escape = "Esc",
	Return = "Enter",
	PrintScreen = "PrtSc",
	ScrollLock = "ScrLk",
	NumLock = "NumLk",
	Semicolon = ";",
	Comma = ",",
	Period = ".",
	Slash = "/",
	BackSlash = "\\",
	Quote = "'",
	LeftBracket = "[",
	RightBracket = "]",
	Minus = "-",
	Equals = "=",
	Backquote = "`",
	Unknown = "None",
}

local function keyname(k)
	if typeof(k) ~= "EnumItem" then
		return "None"
	end

	local n = k.Name

	if terse[n] then
		return terse[n]
	end

	local pad = string.match(n, "^Keypad(.+)$")

	if pad then
		return "Num" .. pad
	end

	return n
end

local med = TweenInfo.new(0.18)
local quick = TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local glide = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local soft = TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function rnd()
	local t = table.create(12)
	for i = 1, 12 do
		t[i] = string.char(math.random(97, 122))
	end
	return table.concat(t)
end

local function new(cls, props, parent)
	local o = Instance.new(cls)
	if cls == "Sound" then o:SetAttribute("VisualsOwned", true) end
	if cls == "ImageButton" or cls == "TextButton" then
		o.AutoButtonColor = false
		o.Selectable = false
	end
	for k, v in next, props do
		o[k] = v
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function conn(sig, fn)
	if #visualsui.conns > 128 then
		for i = #visualsui.conns, 1, -1 do
			if not visualsui.conns[i].Connected then table.remove(visualsui.conns, i) end
		end
	end
	local c = sig:Connect(fn)
	table.insert(visualsui.conns, c)
	return c
end

local function anim(o, info, props)
	local t = tws:Create(o, info, props)
	t:Play()
	return t
end

local function shrink(o)
	if sc ~= 1 then
		new("UIScale", { Scale = sc }, o)
	end

	return o
end

local mirrored = { "AnchorPoint", "Position", "Size", "LayoutOrder" }

local function crisp(group)
	local twin = Instance.new("Frame")
	twin.Name = rnd()
	twin.BorderSizePixel = 0
	twin.ClipsDescendants = group.ClipsDescendants
	twin.ZIndex = group.ZIndex
	twin.Visible = false

	for _, key in next, mirrored do
		twin[key] = group[key]
	end

	for _, d in next, group:GetChildren() do
		if d:IsA("UICorner") then
			d:Clone().Parent = twin
		end
	end

	twin.Parent = group.Parent

	local resting, keep = false, nil

	local function shown(child)
		return child:IsA("GuiObject") and child.Visible
	end

	local function rest()
		if resting or group.GroupTransparency > 0.001 or not group.Parent then
			return
		end

		resting = true
		keep = { bg = group.BackgroundTransparency, active = group.Active, z = group.ZIndex }
		twin.BackgroundColor3 = group.BackgroundColor3
		twin.BackgroundTransparency = keep.bg
		twin.Active = keep.active
		twin.ZIndex = keep.z

		for _, child in next, group:GetChildren() do
			if shown(child) then
				child.Parent = twin
			end
		end

		group.BackgroundTransparency = 1
		group.Active = false
		group.ZIndex = keep.z + 1
		twin.Visible = group.Visible
	end

	local function wake()
		if not resting then
			return
		end

		resting = false

		for _, child in next, twin:GetChildren() do
			if not child:IsA("UICorner") then
				child.Parent = group
			end
		end

		group.BackgroundTransparency = keep.bg
		group.Active = keep.active
		group.ZIndex = keep.z
		twin.Visible = false
	end

	conn(group:GetPropertyChangedSignal("GroupTransparency"), function()
		if group.GroupTransparency > 0.001 then
			wake()
		else
			rest()
		end
	end)

	conn(group:GetPropertyChangedSignal("Visible"), function()
		twin.Visible = resting and group.Visible
	end)

	for _, key in next, mirrored do
		conn(group:GetPropertyChangedSignal(key), function()
			twin[key] = group[key]
		end)
	end

	conn(group.ChildAdded, function(child)
		if resting then
			task.defer(function()
				if resting and child.Parent == group and shown(child) then
					child.Parent = twin
				end
			end)
		end
	end)

	conn(group.Destroying, function()
		twin:Destroy()
	end)

	rest()

	return twin
end

local function apos(o)
	return o.AbsolutePosition / sc
end

local function asz(o)
	return o.AbsoluteSize / sc
end

local function acs(o)
	return o.AbsoluteContentSize / sc
end

local rides = setmetatable({}, { __mode = "k" })
local skip = setmetatable({}, { __mode = "k" })

local function outq(t)
	return 1 - (1 - t) ^ 5
end

local function inq(t)
	return t * t
end

local function flow(o, dur, curve, step, lag)
	local prev = rides[o]

	if prev then
		prev:Disconnect()
		rides[o] = nil
	end

	local t = -(lag or 0)
	local c

	c = rs.RenderStepped:Connect(function(dt)
		if not o.Parent then
			c:Disconnect()

			if rides[o] == c then
				rides[o] = nil
			end

			return
		end

		t = math.min(t + dt, dur)

		if t < 0 then
			step(0)

			return
		end

		step(curve(t / dur))

		if t >= dur then
			c:Disconnect()

			if rides[o] == c then
				rides[o] = nil
			end
		end
	end)

	rides[o] = c

	return c
end

local function round(o, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r) }, o)
end

local function hexof(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function fromhex(s)
	if type(s) ~= "string" then
		return nil
	end

	local raw = string.gsub(s, "[^%x]", "")

	if #raw == 3 then
		raw = string.gsub(raw, "%x", "%1%1")
	end

	if #raw ~= 6 then
		return nil
	end

	local n = tonumber(raw, 16)

	if not n then
		return nil
	end

	return Color3.fromRGB(math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
end

local function fade(o, rot, keys)
	return new("UIGradient", {
		Rotation = rot,
		Transparency = NumberSequence.new(keys),
	}, o)
end

local nooks = {
	Vector3.new(1, 1, 1),
	Vector3.new(1, 1, -1),
	Vector3.new(1, -1, 1),
	Vector3.new(1, -1, -1),
	Vector3.new(-1, 1, 1),
	Vector3.new(-1, 1, -1),
	Vector3.new(-1, -1, 1),
	Vector3.new(-1, -1, -1),
}

local optionalAssetsBlocked = false
local function optionalAsset(fn)
	if optionalAssetsBlocked then return nil end
	local done, abandoned, result = false, false, nil
	task.spawn(function()
		local ok, value = pcall(fn)
		if not abandoned then result = ok and value or nil; done = true end
	end)
	local deadline = os.clock() + 1.5
	while not done and visualsui.alive ~= false and os.clock() < deadline do task.wait(0.03) end
	if not done or visualsui.alive == false then
		abandoned = true
		if not done and visualsui.alive ~= false then
			optionalAssetsBlocked = true
			visualsui.assetIssue = "optional UI asset timed out"
		end
		return nil
	end
	return result
end

local function pullasset(name)
	local grab = type(ASSETS) == "table" and ASSETS.asset or getgenv().visuals_asset

	if type(grab) ~= "function" or type(name) ~= "string" or name == "" then
		return nil
	end

	local res = optionalAsset(function() return grab(name) end)

	if type(res) == "string" and res ~= "" then
		return res
	end
end

local function pulllist(prefix)
	local names = type(ASSETS) == "table" and ASSETS.under or getgenv().visuals_assetlist

	if type(names) ~= "function" then
		return {}
	end

	local ok, res = pcall(names, prefix)

	if ok and type(res) == "table" then
		return res
	end

	return {}
end

local function asset(paths)
	if type(ASSETS) == "table" then
		return pullasset(paths[1]) or ""
	end
	if getcustomasset and isfile then
		for _, p in next, paths do
			local res = optionalAsset(function()
				return isfile(p) and getcustomasset(p) or nil
			end)
			if type(res) == "string" and res ~= "" then
				return res
			end
		end
	end
	local got = pullasset(string.match(tostring(paths[1] or ""), "([^/\\]+)$"))
	if got then
		return got
	end
	return ""
end

local locks = 0

local function latch(d)
	locks = math.max(locks + d, 0)
end

do
	local held, idle = 0, 0

	local function pointer(i)
		return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
	end

	conn(uis.InputBegan, function(i)
		if pointer(i) then held += 1 end
	end)

	conn(uis.InputEnded, function(i)
		if pointer(i) then held = math.max(held - 1, 0) end
	end)

	conn(rs.Heartbeat, function(dt)
		if locks > 0 and held == 0 and not uis:GetFocusedTextBox() then
			idle += dt

			if idle > 0.4 then
				locks = 0
				idle = 0
			end
		else
			idle = 0
		end
	end)
end

local sky = nil
local skyzone = nil
local overkeys = nil

local function inset()
	local ok, v = pcall(function()
		return gus:GetGuiInset()
	end)

	if ok and typeof(v) == "Vector2" then
		return v
	end

	return Vector2.zero
end

local function inside(frame, slack)
	if not frame or not frame.Parent or not frame.Visible then
		return false
	end

	local s = frame.AbsoluteSize

	if s.X <= 0 or s.Y <= 0 then
		return false
	end

	local p = frame.AbsolutePosition + inset()

	slack = slack or 0

	local m = uis:GetMouseLocation()

	return m.X >= p.X - slack and m.X <= p.X + s.X + slack and m.Y >= p.Y - slack and m.Y <= p.Y + s.Y + slack
end

local function sink()
	local s = sky

	if not s then
		return
	end

	sky = nil
	skyzone = nil

	s()
end

conn(uis.InputBegan, function(i, typing)
	if not sky or typing then
		return
	end

	if locks > 0 then
		return
	end

	if overkeys and overkeys() then
		return
	end

	if skyzone and inside(skyzone, 2) then
		return
	end

	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		sink()
	end
end)

local function drag(handle, target, speed)
	local info = TweenInfo.new(speed or 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local held, origin, base, finger = false, nil, nil, nil

	conn(handle.InputBegan, function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local spot, seat = i.Position, target.Position

		task.wait()

		if locks > 0 or i.UserInputState == Enum.UserInputState.End then
			return
		end

		held, origin, base = true, spot, seat
		finger = i.UserInputType == Enum.UserInputType.Touch and i or nil

		local stop
		stop = i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then
				held = false
				stop:Disconnect()
			end
		end)
	end)

	conn(uis.InputEnded, function(i)
		if finger then
			if i == finger then
				held = false
			end
		elseif i.UserInputType == Enum.UserInputType.MouseButton1 then
			held = false
		end
	end)

	conn(uis.InputChanged, function(i)
		if not held or locks > 0 then
			return
		end

		if finger then
			if i ~= finger then
				return
			end
		elseif i.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		local d = i.Position - origin
		local goal = UDim2.new(
			base.X.Scale,
			math.floor(base.X.Offset + d.X),
			base.Y.Scale,
			math.floor(base.Y.Offset + d.Y)
		)

		if finger then
			target.Position = goal
		else
			anim(target, info, { Position = goal })
		end
	end)
end

local function net(parent, count, reach, speed, zi)
	local th = visualsui.theme

	local layer = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = zi,
	}, parent)

	local api = { layer = layer, on = true, veil = 0, marks = {} }
	local dots, link, hook = {}, {}, {}

	skip[layer] = true

	local function strand(alpha)
		local o = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = th.glow,
			BackgroundTransparency = alpha,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(0, 1),
			Visible = false,
			ZIndex = zi,
		}, layer)

		skip[o] = true

		return o
	end

	for i = 1, count do
		local s = math.random(2, 4)
		local base = 0.2 + math.random() * 0.3

		local o = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = th.glow,
			BackgroundTransparency = base,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(s, s),
			ZIndex = zi + 1,
		}, layer)

		new("UICorner", { CornerRadius = UDim.new(1, 0) }, o)

		skip[o] = true

		dots[i] = {
			o = o,
			base = base,
			x = math.random(),
			y = math.random(),
			vx = (math.random() - 0.5) * speed,
			vy = (math.random() - 0.5) * speed,
			px = 0,
			py = 0,
			jam = 0,
		}
	end

	for i = 1, count do
		link[i] = {}

		for j = i + 1, count do
			link[i][j] = strand(1)
		end

		hook[i] = strand(1)
	end

	local function put(l, ax, ay, bx, by, span)
		local dx, dy = bx - ax, by - ay
		local dist = math.sqrt(dx * dx + dy * dy)

		if dist >= span or dist < 2 then
			if l.Visible then
				l.Visible = false
			end

			return
		end

		local t = dist / span
		local base = 0.35 + 0.6 * t * t

		l.Size = UDim2.fromOffset(dist, 1)
		l.Position = UDim2.fromOffset((ax + bx) * 0.5, (ay + by) * 0.5)
		l.Rotation = math.deg(math.atan2(dy, dx))
		l.BackgroundTransparency = base + (1 - base) * api.veil
		l.Visible = true
	end

	local rects, pts = {}, {}
	local carry = 0

	api.conn = conn(rs.RenderStepped, function(dt)
		if not api.on then
			carry = 0

			return
		end

		carry = math.min(carry + dt, 0.1)

		if carry < 1 / 60 then
			return
		end

		dt = carry
		carry %= 1 / 60

		local size = asz(layer)
		local w, h = size.X, size.Y

		if w < 1 or h < 1 then
			return
		end

		local step = math.min(dt, 0.05)
		local span = reach * math.min(w, h)
		local origin = apos(layer)

		table.clear(rects)
		table.clear(pts)

		for _, m in next, api.marks do
			if m.Parent and m.Visible then
				local p = apos(m) - origin
				local s = asz(m)
				local x1, y1, x2, y2 = p.X, p.Y, p.X + s.X, p.Y + s.Y

				table.insert(rects, { x1 - 3, y1 - 3, x2 + 3, y2 + 3 })

				for _, c in next, { { x1, y1 }, { x2, y1 }, { x1, y2 }, { x2, y2 } } do
					if c[1] > 3 and c[1] < w - 3 and c[2] > 3 and c[2] < h - 3 then
						table.insert(pts, c)
					end
				end
			end
		end

		for _, d in next, dots do
			d.x += d.vx * step
			d.y += d.vy * step

			if d.x < 0.015 or d.x > 0.985 then
				d.vx = -d.vx
				d.x = math.clamp(d.x, 0.015, 0.985)
			end

			if d.y < 0.015 or d.y > 0.985 then
				d.vy = -d.vy
				d.y = math.clamp(d.y, 0.015, 0.985)
			end

			d.px, d.py = d.x * w, d.y * h
			d.hit = false

			for _, rc in next, rects do
				if d.px > rc[1] and d.px < rc[3] and d.py > rc[2] and d.py < rc[4] then
					local l, r = d.px - rc[1], rc[3] - d.px
					local t, b = d.py - rc[2], rc[4] - d.py
					local m = math.min(l, r, t, b)
					local sp = math.max(math.abs(d.vx), math.abs(d.vy), speed * 0.75)

					if m == l and rc[1] > 4 then
						d.vx = -sp
					elseif m == r and rc[3] < w - 4 then
						d.vx = sp
					elseif m == t and rc[2] > 4 then
						d.vy = -sp
					elseif m == b and rc[4] < h - 4 then
						d.vy = sp
					else
						d.vx = (d.x < 0.5) and sp or -sp
						d.vy = (d.y < 0.5) and sp or -sp
					end

					d.hit = true
				end
			end

			if d.hit then
				d.jam += step

				if d.jam > 2.5 then
					d.jam = 0
					d.x, d.y = 0.2 + math.random() * 0.6, 0.2 + math.random() * 0.6
					d.vx = (math.random() - 0.5) * speed
					d.vy = (math.random() - 0.5) * speed
					d.px, d.py = d.x * w, d.y * h
					d.hit = false
				end
			else
				d.jam = 0
			end

			d.o.Position = UDim2.fromOffset(d.px, d.py)
			d.o.BackgroundTransparency = d.base + (1 - d.base) * api.veil
		end

		for i = 1, count do
			local a = dots[i]
			local row = link[i]

			for j = i + 1, count do
				local b = dots[j]

				put(row[j], a.px, a.py, b.px, b.py, span)
			end

			local best, bx, by = math.huge, 0, 0

			if not a.hit then
				for _, p in next, pts do
					local dx, dy = p[1] - a.px, p[2] - a.py
					local d2 = dx * dx + dy * dy

					if d2 < best then
						best, bx, by = d2, p[1], p[2]
					end
				end
			end

			if best < math.huge then
				put(hook[i], a.px, a.py, bx, by, span * 0.8)
			elseif hook[i].Visible then
				hook[i].Visible = false
			end
		end
	end)

	function api:mark(o)
		table.insert(api.marks, o)
	end

	return api
end

local function params(cfg, def)
	cfg = cfg or {}
	for k, v in next, def do
		if cfg[k] == nil then
			cfg[k] = v
		end
	end
	return cfg
end

visualsui.logo = ""

local scr = new("ScreenGui", {
	Name = rnd(),
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 1000,
})

pcall(prot, scr)

local attached = pcall(function() scr.Parent = hui end)

if not attached or not scr.Parent then
	pcall(function() scr.Parent = lp:WaitForChild("PlayerGui") end)
end

local function supports(class)
	local ok, object = pcall(Instance.new, class)
	if ok then object:Destroy() end
	return ok
end

local function pointer(input)

	if input and input.UserInputType == Enum.UserInputType.Touch then
		return Vector2.new(input.Position.X, input.Position.Y)
	end
	return uis:GetMouseLocation() - gus:GetGuiInset()
end

local function callback(fn, ...)
	if not visualsui.alive or type(fn) ~= "function" then return end
	if visualsui.configApplying then return fn(...) end
	local args, epoch = table.pack(...), visualsui.applyEpoch
	task.spawn(function()
		if visualsui.alive and epoch == visualsui.applyEpoch then
			local ok, err = pcall(fn, table.unpack(args, 1, args.n))
			if not ok then warn("[visuals] UI callback: " .. tostring(err)) end
		end
	end)
end

visualsui.scr = scr

do
	local lists = {}
	local STEP = 120

	local function range(sf)
		return math.max(sf.AbsoluteCanvasSize.Y - sf.AbsoluteWindowSize.Y, 0)
	end

	local function inside(o, p)
		local a, z = o.AbsolutePosition, o.AbsoluteSize

		return p.X >= a.X and p.Y >= a.Y and p.X <= a.X + z.X and p.Y <= a.Y + z.Y
	end

	local function reach(sf, p)
		local o, depth = sf, 0

		while o and o ~= scr do
			if o:IsA("GuiObject") then
				if not o.Visible then
					return nil
				end

				if (o == sf or o.ClipsDescendants) and not inside(o, p) then
					return nil
				end
			end

			depth += 1
			o = o.Parent
		end

		return o == scr and depth or nil
	end

	local function watch(sf)
		if lists[sf] or visualsui.mobile or not sf.Parent then
			return
		end

		local st = { y = sf.CanvasPosition.Y, goal = sf.CanvasPosition.Y, allowed = sf.ScrollingEnabled }

		lists[sf] = st

		st.guard = true
		sf.ScrollingEnabled = false
		st.guard = false

		st.links = {
			sf:GetPropertyChangedSignal("ScrollingEnabled"):Connect(function()
				if st.guard then
					return
				end

				st.allowed = sf.ScrollingEnabled

				if sf.ScrollingEnabled then
					st.guard = true
					sf.ScrollingEnabled = false
					st.guard = false
				end
			end),
		}

		st.links[3] = sf.AncestryChanged:Connect(function()
			if not sf:IsDescendantOf(game) then
				for _, c in next, st.links do
					c:Disconnect()
				end

				lists[sf] = nil
			end
		end)
	end

	visualsui.glide = watch

	conn(uis.InputChanged, function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseWheel or not visualsui.shown then
			return
		end

		local p = pointer()
		local notch = -i.Position.Z
		local hits = {}

		for sf, st in next, lists do
			if st.allowed then
				local depth = reach(sf, p)

				if depth then
					hits[#hits + 1] = { sf = sf, depth = depth }
				end
			end
		end

		table.sort(hits, function(a, b)
			return a.depth > b.depth
		end)

		for _, hit in next, hits do
			local st = lists[hit.sf]
			local goal = math.clamp(st.goal + notch * STEP, 0, range(hit.sf))

			if goal ~= st.goal then
				st.goal = goal
				st.moving = true

				return
			end
		end
	end)

	conn(rs.RenderStepped, function(dt)
		local k = 1 - math.exp(-dt * 24)

		for sf, st in next, lists do
			local now = sf.CanvasPosition.Y

			if not st.moving then
				st.y, st.goal = now, now
			else

				if math.abs(now - st.y) > 1.5 then st.y = now end

				st.goal = math.clamp(st.goal, 0, range(sf))

				local y = st.y + (st.goal - st.y) * k

				if math.abs(st.goal - y) < 0.5 then
					y = st.goal
					st.moving = false
				end

				st.y = y
				sf.CanvasPosition = Vector2.new(sf.CanvasPosition.X, y)
			end
		end
	end)

	conn(scr.DescendantAdded, function(d)
		if d:IsA("ScrollingFrame") then
			task.defer(watch, d)
		end
	end)
end

local flock = {}
local flocked = 0

conn(scr.DescendantAdded, function(o)
	if o:IsA("GuiObject") or o:IsA("UIStroke") or o:IsA("UIShadow") then
		table.insert(flock, o)
		flocked += 1

		if flocked >= 4096 then
			flocked = 0

			local keep = 0

			for i = 1, #flock do
				local v = flock[i]

				if v.Parent then
					keep += 1
					flock[keep] = v
				end
			end

			for i = #flock, keep + 1, -1 do
				flock[i] = nil
			end
		end
	end
end)

function visualsui:recolor(key, c)
	local old = visualsui.theme[key]

	if typeof(c) ~= "Color3" or typeof(old) ~= "Color3" or c == old then
		return
	end

	visualsui.theme[key] = c

	for i = #flock, 1, -1 do
		local o = flock[i]

		if not o.Parent then
			table.remove(flock, i)
		elseif o:IsA("UIStroke") or o:IsA("UIShadow") then
			if o.Color == old then
				o.Color = c
			end
		else
			if o.BackgroundColor3 == old then
				o.BackgroundColor3 = c
			end

			if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
				if o.TextColor3 == old then
					o.TextColor3 = c
				end
			elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then
				if o.ImageColor3 == old then
					o.ImageColor3 = c
				end
			end
		end
	end
end

visualsui.dir = "visualscfgs"
visualsui.pool = {}
visualsui.order = {}
visualsui.alive = true

local abc = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local rev = {}

for i = 1, 64 do
	rev[string.sub(abc, i, i)] = i - 1
end

local salt = "sh1t4r0::cfg::v1"

local function mask(raw)
	local out = table.create(#raw)

	for i = 1, #raw do
		local k = (string.byte(salt, (i - 1) % #salt + 1) + i * 31 + 91) % 256

		out[i] = string.char(bit32.bxor(string.byte(raw, i), k))
	end

	return table.concat(out)
end

local function pack(raw)
	local out = {}
	local i = 1

	while i <= #raw do
		local a = string.byte(raw, i)
		local b = string.byte(raw, i + 1)
		local c = string.byte(raw, i + 2)
		local v = a * 65536 + (b or 0) * 256 + (c or 0)
		local q = { math.floor(v / 262144) % 64, math.floor(v / 4096) % 64, math.floor(v / 64) % 64, v % 64 }

		out[#out + 1] = string.sub(abc, q[1] + 1, q[1] + 1)
		out[#out + 1] = string.sub(abc, q[2] + 1, q[2] + 1)
		out[#out + 1] = b and string.sub(abc, q[3] + 1, q[3] + 1) or "="
		out[#out + 1] = c and string.sub(abc, q[4] + 1, q[4] + 1) or "="

		i = i + 3
	end

	return table.concat(out)
end

local function peel(txt)
	txt = string.gsub(txt, "[^%w%+/=]", "")

	local out = {}
	local i = 1

	while i < #txt do
		local v, gap = 0, 0

		for j = 0, 3 do
			local ch = string.sub(txt, i + j, i + j)

			if ch == "=" or ch == "" then
				v = v * 64
				gap = gap + 1
			else
				v = v * 64 + (rev[ch] or 0)
			end
		end

		out[#out + 1] = string.char(math.floor(v / 65536) % 256)

		if gap < 2 then
			out[#out + 1] = string.char(math.floor(v / 256) % 256)
		end

		if gap < 1 then
			out[#out + 1] = string.char(v % 256)
		end

		i = i + 4
	end

	return table.concat(out)
end

local function esc(s)
	return (string.gsub(tostring(s), "[%%\1\2\r\n]", function(ch)
		return string.format("%%%02X", string.byte(ch))
	end))
end

local function unesc(s)
	return (string.gsub(s, "%%(%x%x)", function(h)
		return string.char(tonumber(h, 16))
	end))
end

local function slap(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end

	local ok, res = pcall(fn, ...)

	if ok then
		return res
	end
	if visualsui.configApplying then error(res, 0) end
	warn("[visuals] UI: " .. tostring(res))
end

local function vault()
	if type(isfolder) ~= "function" or type(makefolder) ~= "function" then
		return false
	end

	local path = ""
	for piece in string.gmatch(string.gsub(visualsui.dir, "\\", "/"), "[^/]+") do
		path = path == "" and piece or (path .. "/" .. piece)
		if not slap(isfolder, path) then slap(makefolder, path) end
		if not slap(isfolder, path) then return false end
	end
	return path ~= ""
end

local function tidy(name)
	if type(name) ~= "string" then
		return nil
	end

	name = string.match(name, "^%s*(.-)%s*$") or ""
	name = string.gsub(name, "%.[yY][aA][nN]$", "")

	if #name == 0 or #name > 128 or name == "." or name == ".." or name:find('[%c<>:"/\\|?*]')
		or name:match("[%.%s]$") then
		return nil
	end

	return name
end

local function slot(name)
	return visualsui.dir .. "/" .. name .. ".yan"
end

function visualsui:hook(id, kind, get, set, schema)
	if type(id) ~= "string" or id == "" then
		return
	end

	if not visualsui.pool[id] then
		table.insert(visualsui.order, id)
	end

	visualsui.pool[id] = { kind = kind, get = get, set = set, schema = schema }
end

function visualsui:unhook(id)
	if type(id) ~= "string" or not visualsui.pool[id] then
		return
	end

	visualsui.pool[id] = nil

	local at = table.find(visualsui.order, id)

	if at then
		table.remove(visualsui.order, at)
	end
end

function visualsui:freeze()
	local rows = {}

	for _, id in next, visualsui.order do
		local e = visualsui.pool[id]

		if e and not (self.secrets and self.secrets[id]) then
			local v = slap(e.get)
			local t = nil

			if typeof(v) == "Color3" then
				t, v = "c", hexof(v)
			elseif type(v) == "boolean" then
				t, v = "b", v and "1" or "0"
			elseif type(v) == "number" and v == v and math.abs(v) < math.huge then
				t, v = "n", tostring(v)
			elseif type(v) == "string" then
				t = "s"
			elseif v == nil and e.kind == "key" then
				t, v = "s", "Unknown"
			end

			if t then
				rows[#rows + 1] = "f\1" .. esc(id) .. "\1" .. t .. "\1" .. esc(v)
			end
		end
	end

	for k, v in next, visualsui.theme do
		if typeof(v) == "Color3" then
			rows[#rows + 1] = "t\1" .. esc(k) .. "\1c\1" .. hexof(v)
		end
	end

	return "SHC1" .. pack(mask(table.concat(rows, "\2")))
end

function visualsui:thaw(blob)
	if type(blob) ~= "string" or #blob > 4 * 1024 * 1024 then return nil end
	blob = string.gsub(blob, "^\239\187\191", "")
	blob = string.match(blob, "^%s*(.-)%s*$") or ""
	if string.sub(blob, 1, 4) ~= "SHC1" then
		return nil
	end

	local encoded = string.gsub(string.sub(blob, 5), "%s", "")
	if encoded:find("[^%w+/=]") or #encoded % 4 ~= 0 or not encoded:match("^[%w+/]*=?=?$") then return nil end
	local raw = mask(peel(encoded))
	local flags, tint = {}, {}

	for chunk in string.gmatch(raw, "[^\2]+") do
		local kind, id, t, v = string.match(chunk, "^(%a)\1([^\1]*)\1(%a)\1(.*)$")

		if (kind == "f" or kind == "t") and (t == "b" or t == "n" or t == "s" or t == "c") then
			id = unesc(id)
			v = unesc(v)

			if t == "b" then
				if v ~= "1" and v ~= "0" then return nil end
				v = v == "1"
			elseif t == "n" then
				v = tonumber(v)
				if not v or v ~= v or math.abs(v) == math.huge then return nil end
			elseif t == "c" and not fromhex(v) then
				return nil
			end

			if v ~= nil then
				if kind == "f" then
					flags[id] = v
				elseif kind == "t" then
					tint[id] = v
				end
			end
		else return nil end
	end

	return { flags = flags, theme = tint }
end

function visualsui:clipboardExport()
	if type(clipput) ~= "function" then
		return false, "Clipboard write is unavailable"
	end

	local ok, blob = pcall(self.freeze, self)
	if not ok or type(blob) ~= "string" or blob == "" then
		return false, "Could not serialize current settings"
	end

	local copied, reason = pcall(clipput, blob)
	if not copied then
		return false, tostring(reason)
	end

	return true, #blob
end

function visualsui:clipboardImport()
	if type(clipget) ~= "function" then
		return false, "Clipboard read is unavailable"
	end

	local ok, blob = pcall(clipget)
	if not ok or type(blob) ~= "string" or blob == "" then
		return false, "Clipboard is empty or unavailable"
	end

	local fine, data = pcall(self.thaw, self, blob)
	if not fine or type(data) ~= "table" then
		return false, "Clipboard does not contain a valid config"
	end

	self.clipboardBlob = blob
	self.clipboardData = data
	return true
end

function visualsui:clipboardLoad()
	local data = self.clipboardData
	if type(data) ~= "table" then
		local imported, reason = self:clipboardImport()
		if not imported then return false, reason end
		data = self.clipboardData
	end

	local ok, result = pcall(self.apply, self, data)
	self.clipboardBlob, self.clipboardData = nil, nil
	if not ok then
		self.configResult = { ok = false, errors = { tostring(result) } }
		return false, tostring(result)
	end

	if result ~= true then
		local errors = self.configResult and self.configResult.errors
		return false, errors and errors[1] or "Could not apply clipboard config"
	end

	return true
end

function visualsui:apply(data)
	if type(data) ~= "table" or not self.alive then
		return false
	end
	local errors, warnings, prepared = {}, {}, {}
	local flags = data.flags or {}
	if type(flags) ~= "table" or (data.theme ~= nil and type(data.theme) ~= "table") then return false end
	for id, v in pairs(flags) do
		local e = self.pool[id]
		if e and not (self.secrets and self.secrets[id]) then
			local valid = true
			if e.kind == "number" then
				local n = tonumber(v)
				valid = n ~= nil and n == n and math.abs(n) < math.huge
				if valid then
					if e.schema and e.schema.min ~= nil then n = math.max(n, e.schema.min) end
					if e.schema and e.schema.max ~= nil then n = math.min(n, e.schema.max) end
					v = n
				end
			elseif e.kind == "toggle" then valid = type(v) == "boolean"
			elseif e.kind == "color" then valid = typeof(v) == "Color3" or (type(v) == "string" and fromhex(v) ~= nil)
			elseif e.kind == "key" then
				valid = type(v) == "string" and pcall(function() assert(Enum.KeyCode[v]) end)
			else valid = type(v) == "string" and #v <= 65536 end
			if not valid then errors[#errors + 1] = id .. ": invalid value" end
			if valid then prepared[id] = v end
		end
	end
	for key, value in pairs(data.theme or {}) do
		if type(key) ~= "string" or type(value) ~= "string" or not fromhex(value) then errors[#errors + 1] = "theme: invalid color" end
	end
	if #errors > 0 then self.configResult = { ok = false, errors = errors }; warn("[visuals] config: " .. table.concat(errors, "; ")); return false end

	if type(self.beforeConfigApply) == "function" then

		local ok, reason = pcall(self.beforeConfigApply, { flags = prepared, theme = data.theme })
		if not ok then self.configResult = { ok = false, errors = { tostring(reason) } }; return false end
	end
	if not self.alive then return false end
	for id, v in pairs(prepared) do
		local e = self.pool[id]
		if e.schema and e.schema.validate then
			local ok, accepted = pcall(e.schema.validate, v)
			if ok and accepted ~= true and (e.kind == "list" or e.kind == "string") then
				warnings[#warnings + 1] = id .. ": selection unavailable on this device"
				prepared[id] = nil
			elseif not ok or accepted ~= true then errors[#errors + 1] = id .. ": invalid value" end
		end
	end
	if #errors > 0 then self.configResult = { ok = false, errors = errors }; return false end
	self.applyEpoch = (self.applyEpoch or 0) + 1
	local epoch = self.applyEpoch
	self.configApplying = true
	self.quiet = true
	self.configResult = { ok = false, pending = true, errors = errors, warnings = warnings }
	local function active() return self.alive and self.applyEpoch == epoch end
		local ok, err = pcall(function()
			local work = 0

			if type(data.theme) == "table" then
				for k, v in next, data.theme do
					if not active() then return end
					local c = fromhex(v)

					if c and not self.pool["theme|" .. k] then
						self:recolor(k, c)
					end

					work += 1

					if work % 6 == 0 then task.wait() end
				end
			end

			if type(data.flags) == "table" then
				for _, id in next, self.order do
					if not active() then return end
					local e = self.pool[id]
					local v = prepared[id]

					if e and v ~= nil then
						if not (self.secrets and self.secrets[id]) then
							local fine, reason = pcall(e.set, v)
							if not fine then errors[#errors + 1] = id .. ": " .. tostring(reason) end
						end
					end

					work += 1

					if work % 6 == 0 then task.wait() end
				end
			end
		end)

		if self.applyEpoch == epoch then
			self.quiet = false
			self.configApplying = false
			if not ok then errors[#errors + 1] = tostring(err) end
			self.configResult = { ok = ok and self.alive and #errors == 0, errors = errors, warnings = warnings }
		end

		if not ok then
			warn("[visuals] config apply: " .. tostring(err))
		end
	if #errors > 0 then warn("[visuals] config setters: " .. table.concat(errors, "; ")) end
	return ok and active() and #errors == 0
end

function visualsui:roster()
	local out = {}

	if type(listfiles) ~= "function" or not vault() then
		return out
	end

	for _, f in next, slap(listfiles, visualsui.dir) or {} do
		local nm = string.match(string.gsub(tostring(f), "\\", "/"), "([^/]+)%.yan$")

		if nm then
			table.insert(out, nm)
		end
	end

	table.sort(out, function(a, b)
		return string.lower(a) < string.lower(b)
	end)

	return out
end

function visualsui:store(name)
	name = tidy(name)

	if not name or type(writefile) ~= "function" or not vault() then
		return nil
	end

	local ok, blob = pcall(visualsui.freeze, visualsui)

	if not ok or type(blob) ~= "string" then
		return nil
	end

	if not pcall(writefile, slot(name), blob) then
		return nil
	end
	if type(readfile) == "function" then
		local verified, saved = pcall(readfile, slot(name))
		if not verified or saved ~= blob then return nil end
	end

	return name
end

function visualsui:fetch(name)
	name = tidy(name)
	self.configResult = nil

	if not name or type(readfile) ~= "function" then
		self.configResult = { ok = false, errors = { "Config name or file API unavailable" } }
		return nil
	end

	local ok, blob = pcall(readfile, slot(name))

	if not ok or type(blob) ~= "string" then
		self.configResult = { ok = false, errors = { "Config file not found" } }
		return nil
	end

	local fine, data = pcall(visualsui.thaw, visualsui, blob)

	if not fine or not data then
		self.configResult = { ok = false, errors = { "Invalid or damaged config" } }
		return nil
	end

	local applied, result = pcall(self.apply, self, data)
	if not applied then
		self.quiet, self.configApplying = false, false
		self.configResult = { ok = false, errors = { tostring(result) } }
	end
	return applied and result and name or nil
end

function visualsui:erase(name)
	name = tidy(name)

	local kill = delfile or delete_file

	if not name or type(kill) ~= "function" then
		return nil
	end

	if not pcall(kill, slot(name)) then
		return nil
	end

	return name
end

function visualsui:retitle(from, to)
	from, to = tidy(from), tidy(to)

	if not from or not to or type(readfile) ~= "function" or type(writefile) ~= "function" then
		return nil
	end

	if from == to then
		return to
	end
	if type(isfile) ~= "function" or isfile(slot(to)) then return nil end

	local ok, blob = pcall(readfile, slot(from))

	if not ok or type(blob) ~= "string" then
		return nil
	end

	if not pcall(writefile, slot(to), blob) then
		return nil
	end

	local verified, saved = pcall(readfile, slot(to))
	if not verified or saved ~= blob or not visualsui:erase(from) then return nil end

	return to
end

local eyes = {}
local stamp = nil

local function sweep()
	local ls = visualsui:roster()
	local sig = table.concat(ls, "\1")

	if sig == stamp then
		return
	end

	stamp = sig

	for _, fn in next, eyes do
		task.spawn(fn, ls)
	end
end

function visualsui:watch(fn)
	local ls = visualsui:roster()

	stamp = table.concat(ls, "\1")

	table.insert(eyes, fn)

	task.spawn(fn, ls)
end

task.spawn(function()
	while visualsui.alive do
		task.wait(1.25)

		if #eyes > 0 then
			sweep()
		end
	end
end)

visualsui.shown = false

local reel = {
	Click = "click",
	Bubble = "bubble",
	Hentai = "hentai1",
}

visualsui.tonelist = { "Click", "Bubble", "Hentai" }
visualsui.tones = {}
visualsui.tone = "Click"
visualsui.sound = false

local spare = "rbxasset://sounds/electronicpingshort.wav"
local barns = { "visualsui/", "visualssnd/", "assets/", "" }
local looked = {}

local function lift(file)
	if type(isfile) == "function" and type(getcustomasset) == "function" then
		for _, dir in next, barns do
			for _, ext in next, { ".mp3", ".wav", ".ogg" } do
				local p = dir .. file .. ext

				if slap(isfile, p) then
					local asset = slap(getcustomasset, p)

					if type(asset) == "string" and asset ~= "" then
						return asset
					end
				end
			end
		end
	end

	for _, entry in next, pulllist("") do
		local stem, ext = string.match(entry, "^([^/]+)(%.[^%.]+)$")

		if stem == file and (ext == ".mp3" or ext == ".wav" or ext == ".ogg") then
			local got = pullasset(entry)

			if got then
				return got
			end
		end
	end
end

local function seek(name)
	if looked[name] ~= nil then
		return looked[name] or nil
	end

	local file = reel[name]
	local got = file and lift(file) or nil

	looked[name] = got or false

	return got
end

local bells = {}
local turnbell = 0

for i = 1, 4 do
	bells[i] = new("Sound", {
		Name = rnd(),
		SoundId = spare,
		Volume = 0.34,
	}, scr)
end

local grades = {
	on = { 1.08, 0.4 },
	off = { 0.86, 0.34 },
	tab = { 1, 0.32 },
	flip = { 1.18, 0.22 },
	open = { 0.8, 0.42 },
	close = { 1.32, 0.3 },
	tap = { 1.22, 0.26 },
}

function visualsui:chime(kind)
	if not visualsui.sound or visualsui.quiet then
		return
	end

	local g = grades[kind] or grades.tap

	turnbell = turnbell % #bells + 1

	local s = bells[turnbell]

	s.PlaybackSpeed = g[1]
	s.Volume = g[2]
	s.TimePosition = 0

	pcall(s.Play, s)
end

local function stock(id)
	for _, s in next, bells do
		if s.SoundId ~= id then
			s.SoundId = id
		end
	end
end

function visualsui:settone(name)
	if not reel[name] then
		return
	end

	visualsui.tone = name

	local set = visualsui.tones[name]

	if set then
		stock(set)

		return
	end

	task.spawn(function()
		local got = seek(name)

		if visualsui.tone ~= name then
			return
		end

		visualsui.tones[name] = got or spare

		stock(visualsui.tones[name])
	end)
end

function visualsui:setsound(v)
	visualsui.sound = v and true or false
end

visualsui.cursors = {}
visualsui.cursorlist = {}
visualsui.style = nil
visualsui.cursor = false

for _, entry in next, type(ASSETS) == "table" and {} or pulllist("cursors/") do
	local nm = string.match(entry, "([^/]+)%.png$")

	if nm and not visualsui.cursors[nm] then
		local got = pullasset(entry)

		if got then
			visualsui.cursors[nm] = got

			table.insert(visualsui.cursorlist, nm)
		end
	end
end

for _, dir in next, { "visualsui/cursors", "cursors" } do
	if slap(isfolder, dir) and type(listfiles) == "function" and type(getcustomasset) == "function" then
		for _, f in next, slap(listfiles, dir) or {} do
			local nm = string.match(string.gsub(tostring(f), "\\", "/"), "([^/]+)%.png$")

			if nm and not visualsui.cursors[nm] then
				local asset = slap(getcustomasset, dir .. "/" .. nm .. ".png")

				if type(asset) == "string" and asset ~= "" then
					visualsui.cursors[nm] = asset

					table.insert(visualsui.cursorlist, nm)
				end
			end
		end
	end
end

table.sort(visualsui.cursorlist, function(a, b)
	return string.lower(a) < string.lower(b)
end)

visualsui.style = visualsui.cursorlist[1]

local claw = new("ImageLabel", {
	Name = rnd(),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(64, 64),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Image = "",
	ScaleType = Enum.ScaleType.Stretch,
	Visible = false,
	ZIndex = 2147483647,
}, scr)

pcall(function()
	claw.ResampleMode = Enum.ResamplerMode.Pixelated
end)

local leash = nil
local kept = nil

local function trace()
	local p = uis:GetMouseLocation()

	claw.Position = UDim2.fromOffset(p.X, p.Y)

	if uis.MouseIconEnabled then
		uis.MouseIconEnabled = false
	end
end

local function rouse()
	local art = visualsui.cursors[visualsui.style]
	local go = visualsui.cursor and visualsui.shown and not visualsui.mobile and art ~= nil

	if go == (leash ~= nil) then
		if go then
			claw.Image = art
		end

		return
	end

	if go then
		kept = uis.MouseIconEnabled
		claw.Image = art

		trace()

		claw.Visible = true
		leash = rs.RenderStepped:Connect(trace)

		return
	end

	leash:Disconnect()
	leash = nil

	claw.Visible = false

	if kept ~= nil then
		uis.MouseIconEnabled = kept
		kept = nil
	end
end

function visualsui:setstyle(name)
	if not visualsui.cursors[name] then
		return
	end

	visualsui.style = name

	rouse()
end

function visualsui:setcursor(v)
	visualsui.cursor = v and true or false

	rouse()
end

function visualsui:wake()
	rouse()
end

local th = visualsui.theme

local ear, quit = nil, nil

local function capture(fn, off)
	if quit then
		local prev = quit

		quit = nil

		prev()
	end

	if ear then
		ear:Disconnect()
		ear = nil
	end

	if not fn then
		visualsui.capturing = false

		return
	end

	quit = off
	visualsui.capturing = true

	ear = uis.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.Keyboard or i.KeyCode == Enum.KeyCode.Unknown then
			return
		end

		local k = i.KeyCode

		quit = nil

		capture(nil)

		fn(k ~= Enum.KeyCode.Escape and k or nil)
	end)
end

visualsui.hotkeys = true

local hive = {}

local function hush(skip)
	for i = #hive, 1, -1 do
		local bd = hive[i]

		if bd ~= skip then
			bd:setopen(false)
		end
	end
end

local function gauge(txt, size)
	local ok, sz = pcall(function()
		return txs:GetTextSize(txt, size, Enum.Font.GothamBold, Vector2.new(9e9, 9e9))
	end)

	if ok and sz then
		return math.ceil(sz.X)
	end

	return math.ceil(#tostring(txt) * size * 0.6)
end

local deep = supports("UIShadow")

local hutch = new("CanvasGroup", {
	Name = rnd(),
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 8, 0.5, 0),
	Size = UDim2.fromOffset(0, 0),
	AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 900,
}, scr)

new("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 3),
}, hutch)

new("UIPadding", {
	PaddingTop = UDim.new(0, 10),
	PaddingBottom = UDim.new(0, 10),
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
}, hutch)

hutch.Visible = false
hutch.GroupTransparency = 1

shrink(hutch)

local function plate(parent, order, pad, gap, lift)
	local card = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = th.panel,
		BackgroundTransparency = 0.16,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = order,
		ZIndex = 2,
	}, parent)

	round(card, 8)

	local edge = new("UIStroke", {
		Color = th.line,
		Thickness = 1,
		Transparency = 0.45,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, card)

	if lift and deep then
		new("UIShadow", {
			Color = th.bg,
			BlurRadius = UDim.new(0, lift),
			Offset = UDim2.fromOffset(0, 2),
			Spread = UDim2.fromOffset(-2, -2),
			Transparency = 0.6,
			ZIndex = -1,
		}, card)
	end

	local skin = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = th.glow,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, card)

	round(skin, 8)

	fade(skin, 90, {
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.6, 0.82),
		NumberSequenceKeypoint.new(1, 0.9),
	})

	local gloss = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 1),
		Size = UDim2.new(1, -14, 0, 1),
		BackgroundColor3 = th.glow,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, card)

	fade(gloss, 0, {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})

	local hold = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, card)

	if pad then
		new("UIPadding", {
			PaddingLeft = UDim.new(0, pad),
			PaddingRight = UDim.new(0, pad),
		}, hold)
	end

	if gap then
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, gap),
		}, hold)
	end

	return card, edge, skin, hold
end

local crown, crownedge, crownskin, crownhold = plate(hutch, 0, 14, 8, 10)

crown.Active = true

local crownart = new("ImageLabel", {
	Name = rnd(),
	Size = UDim2.fromOffset(17, 17),
	BackgroundTransparency = 1,
	Image = icon("keyboard"),
	ImageColor3 = th.dim,
	ImageTransparency = 0,
	LayoutOrder = 1,
	ScaleType = Enum.ScaleType.Fit,
	ZIndex = 4,
}, crownhold)

local crowntag = new("TextLabel", {
	Name = rnd(),
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 20),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamMedium,
	Text = "hotkeys",
	TextColor3 = th.text,
	TextSize = 14,
	LayoutOrder = 2,
	ZIndex = 4,
}, crownhold)

local brief = 53 + gauge("hotkeys", 14)

drag(crown, hutch, 0.12)

local roost, ranks = {}, {}
local aired, span = false, nil

local function crest()
	local wide = brief

	for i = 1, #ranks do
		local p = roost[ranks[i]]

		if p and p.span and p.span > wide then
			wide = p.span
		end
	end

	if wide == span then
		return
	end

	if span == nil then
		span = wide
		crown.Size = UDim2.fromOffset(wide, 36)

		return
	end

	span = wide

	anim(crown, soft, { Size = UDim2.fromOffset(wide, 36) })
end

local function sort()
	table.sort(ranks, function(a, b)
		local pa, pb = roost[a], roost[b]

		if not pa or not pb then
			return false
		end

		if pa.tw ~= pb.tw then
			return pa.tw < pb.tw
		end

		return pa.name < pb.name
	end)

	for i = 1, #ranks do
		local p = roost[ranks[i]]

		if p then
			p.row.LayoutOrder = i
		end
	end
end

local function air()
	local want = visualsui.hotkeys and #ranks > 0

	if want == aired then
		return
	end

	aired = want

	crest()

	if want then
		hutch.Visible = true
	end

	local from = hutch.GroupTransparency
	local to = want and 0 or 1

	flow(hutch, want and 0.3 or 0.22, want and outq or inq, function(k)
		hutch.GroupTransparency = from + (to - from) * k

		if k >= 1 and not aired then
			hutch.Visible = false
		end
	end)
end

local function knob(p, on)
	on = on and true or false

	if not p.rail or p.on == on then
		return
	end

	p.on = on

	anim(p.rail, soft, { BackgroundColor3 = on and th.accent or th.bg })
	anim(p.bead, soft, {
		Position = UDim2.new(on and 0.68 or 0.32, 0, 0.5, 0),
		BackgroundColor3 = on and th.bg or Color3.new(1, 1, 1),
		BackgroundTransparency = on and 0 or 0.45,
	})
end

local function tally(p)
	local wide = 28 + p.tw

	if p.worth then
		wide = wide + p.vw + 10
	end

	local slim = math.max(24 + p.kw, 32)

	if wide == p.iw and slim == p.kwide then
		return
	end

	p.iw = wide
	p.kwide = slim
	p.span = wide + 5 + slim + (p.tumb and 37 or 0) + 4

	if p.born then
		anim(p.info, soft, { Size = UDim2.fromOffset(wide, 32) })
		anim(p.cue, soft, { Size = UDim2.fromOffset(slim, 32) })
		anim(p.row, soft, { Size = UDim2.fromOffset(p.span, 36) })
	else
		p.info.Size = UDim2.fromOffset(wide, 32)
		p.cue.Size = UDim2.fromOffset(slim, 32)
		p.row.Size = UDim2.fromOffset(p.span, 36)
	end
end

local function dawn(p)
	if p.gone or p.open then
		return
	end

	p.open = true

	p.row.Visible = true

	local from = p.row.GroupTransparency

	flow(p.row, 0.28, outq, function(k)
		p.row.GroupTransparency = from * (1 - k)
	end)
end

local function dusk(p, kill)
	if p.gone or (not p.open and not kill) then
		return
	end

	p.gone = kill and true or false
	p.open = false

	local from = p.row.GroupTransparency

	flow(p.row, 0.22, inq, function(k)
		p.row.GroupTransparency = from + (1 - from) * k

		if k < 1 then
			return
		end

		if p.gone then
			if p.row and p.row.Parent then
				p.row:Destroy()
			end

			return
		end

		p.row.Visible = false
	end)
end

local function perch(id, spec)
	local p = roost[id]

	if p then
		p.name = spec.name
		p.tw = gauge(spec.name, 14)
		p.kw = gauge(spec.key, 14)

		p.tag.Text = spec.name
		p.keyl.Text = spec.key

		if p.worth then
			p.worth.Text = spec.worth or ""
			p.vw = gauge(p.worth.Text, 14)
		end

		tally(p)
		knob(p, spec.lit)
		sort()
		crest()
		dawn(p)

		return
	end

	p = { name = spec.name, tw = gauge(spec.name, 14), kw = gauge(spec.key, 14), vw = 0 }

	p.row = new("CanvasGroup", {
		Name = rnd(),
		Size = UDim2.fromOffset(0, 36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 2,
	}, hutch)

	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5),
	}, p.row)

	new("UIPadding", {
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 2),
		PaddingLeft = UDim.new(0, 2),
		PaddingRight = UDim.new(0, 2),
	}, p.row)

	if spec.art then
		p.tumb, p.tumbedge, p.tumbskin = plate(p.row, 1)

		p.tumb.Size = UDim2.fromOffset(32, 32)

		p.rail = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(24, 13),
			BackgroundColor3 = th.bg,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, p.tumb)

		new("UICorner", { CornerRadius = UDim.new(1, 0) }, p.rail)

		p.bead = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.3, 0, 0.5, 0),
			Size = UDim2.fromOffset(9, 9),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			ZIndex = 5,
		}, p.rail)

		new("UICorner", { CornerRadius = UDim.new(1, 0) }, p.bead)

		if spec.press then
			p.hit = new("ImageButton", {
				Name = rnd(),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ImageTransparency = 1,
				ZIndex = 6,
			}, p.tumb)

			conn(p.hit.MouseButton1Click, function()
				spec.press()
			end)
		end
	end

	local hold

	p.info, p.infoedge, p.infoskin, hold = plate(p.row, 2, 14, 10)

	p.tag = new("TextLabel", {
		Name = rnd(),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = spec.name,
		TextColor3 = th.text,
		TextSize = 14,
		TextTransparency = 0.05,
		LayoutOrder = 1,
		ZIndex = 4,
	}, hold)

	if spec.worth then
		p.worth = new("TextLabel", {
			Name = rnd(),
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = spec.worth,
			TextColor3 = th.dim,
			TextSize = 14,
			TextTransparency = 0.25,
			LayoutOrder = 2,
			ZIndex = 4,
		}, hold)

		p.vw = gauge(spec.worth, 14)
	end

	local perchhold

	p.cue, p.cueedge, p.cueskin, perchhold = plate(p.row, 3, 12, 0)

	p.keyl = new("TextLabel", {
		Name = rnd(),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = spec.key,
		TextColor3 = th.accent,
		TextSize = 14,
		TextTransparency = 0.1,
		LayoutOrder = 1,
		ZIndex = 4,
	}, perchhold)

	roost[id] = p

	table.insert(ranks, id)

	tally(p)
	knob(p, spec.lit)
	sort()
	air()
	crest()

	p.born = true

	task.spawn(function()
		rs.Heartbeat:Wait()

		if p.row.Parent then
			dawn(p)
		end
	end)
end

local function unperch(id)
	local p = roost[id]

	if not p then
		return
	end

	roost[id] = nil

	local at = table.find(ranks, id)

	if at then
		table.remove(ranks, at)
	end

	sort()
	air()
	crest()
	dusk(p, true)
end

local function relight(id, lit)
	local p = roost[id]

	if p then
		knob(p, lit)
	end
end

function overkeys()
	return inside(hutch, 6)
end

function visualsui:sethotkeys(v)
	visualsui.hotkeys = v and true or false

	air()
end

function visualsui:hotkeyspot(v)
	if typeof(v) == "UDim2" then
		hutch.Position = v
	end
end

crest()

visualsui.watermark = true

local function spotof(v)
	return string.format(
		"%.4f,%d,%.4f,%d",
		v.X.Scale,
		math.floor(v.X.Offset + 0.5),
		v.Y.Scale,
		math.floor(v.Y.Offset + 0.5)
	)
end

local function readspot(v)
	if type(v) ~= "string" then
		return nil
	end

	local xs, xo, ys, yo = string.match(v, "^(-?[%d%.]+),(-?%d+),(-?[%d%.]+),(-?%d+)$")

	if not xs then
		return nil
	end

	return UDim2.new(tonumber(xs), tonumber(xo), tonumber(ys), tonumber(yo))
end

local nest = new("CanvasGroup", {
	Name = rnd(),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 8),
	Size = UDim2.fromOffset(0, 0),
	AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 900,
}, scr)

new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 8),
}, nest)

new("UIPadding", {
	PaddingTop = UDim.new(0, 10),
	PaddingBottom = UDim.new(0, 10),
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
}, nest)

nest.Visible = false
nest.GroupTransparency = 1

shrink(nest)

local function pod(order, pad, gap)
	local card = new("Frame", {
		Name = rnd(),
		Active = true,
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = th.panel,
		BackgroundTransparency = 0.16,
		BorderSizePixel = 0,
		LayoutOrder = order,
		ZIndex = 2,
	}, nest)

	round(card, 8)

	new("UIStroke", {
		Color = th.line,
		Thickness = 1,
		Transparency = 0.45,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, card)

	if deep then
		new("UIShadow", {
			Color = th.bg,
			BlurRadius = UDim.new(0, 10),
			Offset = UDim2.fromOffset(0, 2),
			Spread = UDim2.fromOffset(-2, -2),
			Transparency = 0.6,
			ZIndex = -1,
		}, card)
	end

	local skin = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = th.glow,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, card)

	round(skin, 8)

	fade(skin, 90, {
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.6, 0.82),
		NumberSequenceKeypoint.new(1, 0.9),
	})

	local gloss = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 1),
		Size = UDim2.new(1, -14, 0, 1),
		BackgroundColor3 = th.glow,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, card)

	fade(gloss, 0, {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})

	local hold = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, card)

	new("UIPadding", {
		PaddingLeft = UDim.new(0, pad),
		PaddingRight = UDim.new(0, pad),
	}, hold)

	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, gap),
	}, hold)

	drag(card, nest, 0.12)

	return card, hold
end

local badge, badgehold = pod(1, 13, 8)

new("ImageLabel", {
	Name = rnd(),
	Size = UDim2.fromOffset(16, 16),
	BackgroundTransparency = 1,
	Image = icon("code"),
	ImageColor3 = th.dim,
	ImageTransparency = 0,
	LayoutOrder = 1,
	ScaleType = Enum.ScaleType.Fit,
	ZIndex = 4,
}, badgehold)

new("TextLabel", {
	Name = rnd(),
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 20),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamMedium,
	Text = "inertiahub.xyz",
	TextColor3 = th.text,
	TextSize = 14,
	TextTransparency = 0.05,
	LayoutOrder = 2,
	ZIndex = 4,
}, badgehold)

local stat, stathold = pod(2, 13, 8)

local face = new("ImageLabel", {
	Name = rnd(),
	Size = UDim2.fromOffset(22, 22),
	BackgroundColor3 = th.bg,
	BackgroundTransparency = 0.3,
	BorderSizePixel = 0,
	Image = visualsui.logo ~= "" and visualsui.logo
		or string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", lp.UserId),
	ImageTransparency = 0.02,
	LayoutOrder = 10,
	ScaleType = Enum.ScaleType.Crop,
	ZIndex = 4,
}, stathold)

new("UICorner", { CornerRadius = UDim.new(1, 0) }, face)

new("UIStroke", {
	Color = th.line,
	Thickness = 1,
	Transparency = 0.35,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, face)

local function chip(order, art, txt, lead)
	if not lead then
		local rail = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromOffset(14, 16),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = order,
			ZIndex = 4,
		}, stathold)

		local line = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(1, 16),
			BackgroundColor3 = th.glow,
			BackgroundTransparency = 0.62,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, rail)

		fade(line, 90, {
			NumberSequenceKeypoint.new(0, 0.85),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 0.85),
		})
	end

	if art then
		new("ImageLabel", {
			Name = rnd(),
			Size = UDim2.fromOffset(15, 15),
			BackgroundTransparency = 1,
			Image = icon(art),
			ImageColor3 = th.text,
			ImageTransparency = 0.25,
			LayoutOrder = order + 1,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 4,
		}, stathold)
	end

	return new("TextLabel", {
		Name = rnd(),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = txt,
		TextColor3 = th.text,
		TextSize = 14,
		TextTransparency = 0.05,
		LayoutOrder = order + 2,
		ZIndex = 4,
	}, stathold)
end

local whotag = chip(20, nil, lp.Name, true)
local ratetag = chip(30, "layers", "0")
local lagtag = chip(40, "wifi", "0ms")
local timetag = chip(50, "clock", "00:00")

for tag, wide in next, {
	[ratetag] = gauge("999", 14),
	[lagtag] = gauge("999ms", 14),
	[timetag] = gauge("00:00", 14),
} do
	tag.AutomaticSize = Enum.AutomaticSize.None
	tag.Size = UDim2.fromOffset(wide, 20)
	tag.TextXAlignment = Enum.TextXAlignment.Left
end

local keyszone = overkeys

function overkeys()
	return (keyszone and keyszone()) or inside(nest, 6)
end

local marked = false

local function flare()
	local want = visualsui.watermark and true or false

	if want == marked then
		return
	end

	marked = want

	if want then
		nest.Visible = true
	end

	local from = nest.GroupTransparency
	local to = want and 0 or 1

	flow(nest, want and 0.3 or 0.22, want and outq or inq, function(k)
		nest.GroupTransparency = from + (to - from) * k

		if k >= 1 and not marked then
			nest.Visible = false
		end
	end)
end

local meter = nil

pcall(function()
	meter = cloneref(game:GetService("Stats"))
end)

local function lagof()
	if not meter then
		return 0
	end

	local ok, v = pcall(function()
		return meter.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)

	if not ok or type(v) ~= "number" then
		return 0
	end

	return math.floor(v + 0.5)
end

local beats, drift = 0, 0

conn(rs.RenderStepped, function(dt)
	beats += 1
	drift += dt

	if drift < 0.5 then
		return
	end

	local rate = math.floor(beats / drift + 0.5)

	beats, drift = 0, 0

	if not nest.Visible then
		return
	end

	if whotag.Text ~= lp.Name then
		whotag.Text = lp.Name
	end

	ratetag.Text = tostring(rate)
	lagtag.Text = tostring(lagof()) .. "ms"
	timetag.Text = os.date("%H:%M")
end)

visualsui:hook("menu|hotkeyspot", "string", function()
	return spotof(hutch.Position)
end, function(v)
	local p = readspot(v)

	if p then
		hutch.Position = p
	end
end)

visualsui:hook("menu|markspot2", "string", function()
	return spotof(nest.Position)
end, function(v)
	local p = readspot(v)

	if p then
		nest.Position = p
	end
end)

function visualsui:setwatermark(v)
	visualsui.watermark = v and true or false

	flare()
end

function visualsui:watermarkspot(v)
	if typeof(v) == "UDim2" then
		nest.Position = v
	end
end

timetag.Text = os.date("%H:%M")

flare()

visualsui.opener = visualsui.mobile

local knock = new("ImageButton", {
	Name = rnd(),
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -10, 0.5, 0),
	Size = UDim2.fromOffset(54, 54),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", lp.UserId),
	ImageColor3 = Color3.new(1, 1, 1),
	ScaleType = Enum.ScaleType.Fit,
	Visible = visualsui.opener,
	Active = true,
	ZIndex = 950,
}, scr)

drag(knock, knock, 0.1)

local rap, rapt = nil, 0

conn(knock.InputBegan, function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		rap, rapt = i.Position, os.clock()
	end
end)

conn(knock.InputEnded, function(i)
	if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local from = rap

	rap = nil

	if not from or locks > 0 then
		return
	end

	if (i.Position - from).Magnitude > 8 or os.clock() - rapt > 0.7 then
		return
	end

	for _, w in next, visualsui.wins do
		pcall(function()
			w:toggle()
		end)
	end
end)

visualsui:hook("menu|openerspot", "string", function()
	return spotof(knock.Position)
end, function(v)
	local p = readspot(v)

	if p then
		knock.Position = p
	end
end)

function visualsui:setopener(v)
	visualsui.opener = v and true or false

	knock.Visible = visualsui.opener
end

function visualsui:openerspot(v)
	if typeof(v) == "UDim2" then
		knock.Position = v
	end
end

function visualsui:openericon(v)
	knock.Image = tostring(v)
end

local shelf = new("Frame", {
	Name = rnd(),
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.new(0, 18, 0, 18),
	Size = UDim2.fromOffset(268, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	ZIndex = 400,
}, scr)

shrink(shelf)

local puffs = {}
local puffn = 0

local function stack(fresh)
	local y = 0

	for i = 1, #puffs do
		local p = puffs[i]
		local card = p.husk

		if card and card.Parent then
			local at = UDim2.fromOffset(0, y)

			if p == fresh or p.spot == nil then
				card.Position = at
			elseif p.spot ~= y then
				anim(card, soft, { Position = at })
			end

			p.spot = y

			y += (p.tall or card.Size.Y.Offset) + 8
		end
	end
end

visualsui.notices = true
visualsui.noticecap = 5

function visualsui:setnotices(v)
	visualsui.notices = v and true or false
end

function visualsui:notify(cfg)
	if not visualsui.alive or not visualsui.notices then
		return
	end

	cfg = params(cfg, {
		title = "visuals",
		text = "",
		icon = "info",
		life = 5,
		tone = nil,
	})

	local th = visualsui.theme
	local wide = 268
	local head = tostring(cfg.title or "")
	local body = tostring(cfg.text or "")
	local tint = (typeof(cfg.tone) == "Color3") and cfg.tone or th.accent
	local rows = 0

	if body ~= "" then
		rows = math.clamp(math.ceil(gauge(body, 11) / (wide - 52)), 1, 4)
	end

	local tall = 27 + (rows > 0 and (rows * 12 + 3) or 0)

	puffn += 1

	local husk = new("CanvasGroup", {
		Name = rnd(),
		Size = UDim2.fromOffset(wide, tall),
		BackgroundColor3 = th.panel,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		LayoutOrder = puffn,
		ZIndex = 400,
	}, shelf)

	round(husk, 7)

	new("UIStroke", {
		Color = th.line,
		Thickness = 1,
		Transparency = 0.45,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, husk)

	if deep then
		new("UIShadow", {
			Color = th.bg,
			BlurRadius = UDim.new(0, 14),
			Offset = UDim2.fromOffset(0, 3),
			Spread = UDim2.fromOffset(-2, -2),
			Transparency = 0.3,
			ZIndex = -1,
		}, husk)
	end

	local sheen = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = th.glow,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		ZIndex = 400,
	}, husk)

	round(sheen, 7)

	fade(sheen, 90, {
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.6, 0.82),
		NumberSequenceKeypoint.new(1, 0.9),
	})

	local gloss = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 1),
		Size = UDim2.new(1, -14, 0, 1),
		BackgroundColor3 = th.glow,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = 402,
	}, husk)

	fade(gloss, 0, {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})

	local bar = new("Frame", {
		Name = rnd(),
		Size = UDim2.new(0, 2, 1, 0),
		BackgroundColor3 = tint,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 402,
	}, husk)

	fade(bar, 90, {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.12, 0.2),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.88, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})

	new("ImageLabel", {
		Name = rnd(),
		Position = UDim2.fromOffset(11, 7),
		Size = UDim2.fromOffset(13, 13),
		BackgroundTransparency = 1,
		Image = icon(cfg.icon),
		ImageColor3 = tint,
		ImageTransparency = 0.05,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 402,
	}, husk)

	new("TextLabel", {
		Name = rnd(),
		Position = UDim2.fromOffset(31, 5),
		Size = UDim2.new(1, -46, 0, 17),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = head,
		TextColor3 = th.text,
		TextSize = 13,
		TextTransparency = 0.05,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 402,
	}, husk)

	if rows > 0 then
		new("TextLabel", {
			Name = rnd(),
			Position = UDim2.fromOffset(31, 21),
			Size = UDim2.new(1, -42, 0, rows * 12),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = body,
			TextColor3 = th.dim,
			TextSize = 11,
			TextTransparency = 0.15,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 402,
		}, husk)
	end

	local fuse = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = tint,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 403,
	}, husk)

	fade(fuse, 0, {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.12, 0.2),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.88, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})

	local shut = new("ImageButton", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ImageTransparency = 1,
		ZIndex = 404,
	}, husk)

	local function drift(inn, done)
		local a0 = husk.GroupTransparency
		local a1 = inn and 0 or 1

		flow(husk, inn and 0.3 or 0.22, inn and outq or inq, function(k)
			husk.GroupTransparency = a0 + (a1 - a0) * k

			if k >= 1 and done then
				done()
			end
		end)
	end

	local puff = { husk = husk, tall = tall, dead = false }

	function puff:close()
		if puff.dead then
			return
		end

		puff.dead = true

		drift(false, function()
			local at = table.find(puffs, puff)

			if at then
				table.remove(puffs, at)
			end

			husk:Destroy()

			stack()
		end)
	end

	table.insert(puffs, puff)

	stack(puff)

	local seen = 0
	local cap = math.max(visualsui.noticecap, 1)

	for i = #puffs, 1, -1 do
		local p = puffs[i]

		if not p.dead then
			seen += 1

			if seen > cap then
				p:close()
			end
		end
	end

	conn(shut.MouseButton1Click, function()
		visualsui:chime("tap")

		puff:close()
	end)

	conn(shut.MouseEnter, function()
		anim(sheen, soft, { BackgroundTransparency = 0.65 })
	end)

	conn(shut.MouseLeave, function()
		anim(sheen, soft, { BackgroundTransparency = 0.82 })
	end)

	drift(true)

	local life = math.max(tonumber(cfg.life) or 5, 0.4)

	anim(fuse, TweenInfo.new(life, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })

	task.delay(life, function()
		puff:close()
	end)

	return puff
end

visualsui.linklist = {}

function visualsui.linkhead(head)
	for _, b in next, head.links do
		b:Destroy()
	end

	table.clear(head.links)

	local th = visualsui.theme

	for n, l in next, visualsui.linklist do
		local b = new("ImageButton", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 16 + (n - 1) * 28, 0.5, 2),
			Size = UDim2.fromOffset(22, 22),
			BackgroundColor3 = th.head,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = l.image or "",
			ImageColor3 = th.dim,
			ImageTransparency = 0.15,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 8,
		}, head.quest)

		round(b, 6)

		conn(b.MouseEnter, function()
			anim(b, soft, { ImageTransparency = 0, ImageColor3 = th.text, BackgroundTransparency = 0.45 })
		end)

		conn(b.MouseLeave, function()
			anim(b, soft, { ImageTransparency = 0.15, ImageColor3 = th.dim, BackgroundTransparency = 1 })
		end)

		conn(b.MouseButton1Click, function()
			visualsui:chime("tap")

			if type(l.callback) == "function" then
				task.spawn(l.callback)
			end
		end)

		head.links[n] = b
	end
end

function visualsui:setlinks(list)
	visualsui.linklist = type(list) == "table" and list or {}

	for _, head in next, visualsui.heads or {} do
		visualsui.linkhead(head)
	end
end

function visualsui:window(cfg)
	cfg = params(cfg, {
		logo = visualsui.logo,
		size = UDim2.fromOffset(528, 540),
		side = 153,
		radius = 9,
		bind = "RightShift",
	})

	local th = visualsui.theme
	local r = cfg.radius
	local sw = cfg.side

	local win = {
		size = cfg.size,
		open = true,
		list = {},
		bind = typeof(cfg.bind) == "EnumItem" and cfg.bind or Enum.KeyCode[cfg.bind],
	}

	local ContextActionService = game:GetService("ContextActionService")
	local bindActionName = "Visuals_MenuBind"
	local function bindMenuAction()
		pcall(function() ContextActionService:UnbindAction(bindActionName) end)
		if not win.bind then return end
		pcall(function()
			ContextActionService:BindActionAtPriority(bindActionName, function(_, state)
				if state == Enum.UserInputState.Begin then win:toggle() end
				return Enum.ContextActionResult.Sink
			end, false, Enum.ContextActionPriority.High.Value, win.bind)
		end)
	end

	local shell = new("Frame", {
		Name = rnd(),
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = cfg.size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, scr)

	shrink(shell)

	local aura, halo = {}, {}
	local native = supports("UIShadow")

	if native then
		local lamp = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 1,
		}, shell)

		round(lamp, r)

		for i, spec in next, {
			{ UDim.new(0, 16), UDim2.fromOffset(2, 2), 0.2 },
			{ UDim.new(0, 38), UDim2.fromOffset(12, 12), 0.45 },
		} do
			aura[i] = new("UIShadow", {
				Color = th.bg,
				BlurRadius = spec[1],
				Spread = spec[2],
				Offset = UDim2.new(),
				Transparency = 1,
				ZIndex = -i,
			}, lamp)

			halo[i] = spec[3]
		end
	else
		for i, alpha in next, { 0.35, 0.55, 0.72 } do
			local ring = new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, i * 5, 1, i * 5),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 1,
			}, shell)

			round(ring, r + i * 3)

			aura[i] = new("UIStroke", {
				Color = th.bg,
				Thickness = 3,
				Transparency = 1,
			}, ring)

			halo[i] = alpha
		end
	end

	local root = new("CanvasGroup", {
		Name = rnd(),
		Active = true,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = th.bg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		GroupTransparency = 1,
		ZIndex = 2,
	}, shell)

	round(root, r)

	win.plate = crisp(root)

	local rim = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, root)

	round(rim, r)
	new("UIStroke", { Color = th.line, Transparency = 0.6 }, rim)

	function win:setfury()
	end

	local grip = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 0,
		Active = true,
	}, root)

	local body = new("Frame", {
		Name = rnd(),
		Position = UDim2.fromOffset(sw, 0),
		Size = UDim2.new(1, -sw, 1, 0),
		BackgroundColor3 = th.bg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
	}, root)

	round(body, r)

	new("Frame", {
		Name = rnd(),
		Size = UDim2.new(0, r, 1, 0),
		BackgroundColor3 = th.bg,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, body)

	local bgnet = net(body, 13, 0.44, 0.11, 2)

	local pages = new("Frame", {
		Name = rnd(),
		Position = UDim2.fromOffset(16, 16),
		Size = UDim2.new(1, -32, 1, -32),
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, body)

	local side = new("Frame", {
		Name = rnd(),
		Size = UDim2.new(0, sw, 1, 0),
		BackgroundColor3 = th.side,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 5,
	}, root)

	round(side, r)

	new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, r, 1, 0),
		BackgroundColor3 = th.side,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, side)

	local split = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, sw, 0.5, 0),
		Size = UDim2.new(0, 16, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 8,
	}, root)

	local splitGlow = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = th.glow,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		ZIndex = 8,
	}, split)

	fade(splitGlow, 0, {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})

	local splitLine = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = th.line,
		BorderSizePixel = 0,
		ZIndex = 9,
	}, split)

	fade(splitLine, 90, {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.12, 0.25),
		NumberSequenceKeypoint.new(0.88, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})

	local logo = new("ImageLabel", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.fromOffset(117, 117),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = cfg.logo,
		ImageColor3 = th.accent,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 7,
	}, side)
	win.Logo = logo

	local under = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 140),
		Size = UDim2.new(1, -28, 0, 1),
		BackgroundColor3 = th.line,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 7,
	}, side)

	fade(under, 0, {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})

	local tabs = new("ScrollingFrame", {
		Name = rnd(),
		Active = true,
		Position = UDim2.fromOffset(6, 154),
		Size = UDim2.new(1, -12, 1, -222),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		ZIndex = 7,
	}, side)

	local list = new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 3),
	}, tabs)

	conn(list:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		tabs.CanvasSize = UDim2.fromOffset(0, acs(list).Y + 2)
	end)

	visualsui.glide(tabs)

	local seam = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -60),
		Size = UDim2.new(1, -28, 0, 1),
		BackgroundColor3 = th.line,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 7,
	}, side)

	fade(seam, 0, {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})

	local badge = new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -12, 0, 44),
		BackgroundColor3 = th.head,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		ZIndex = 7,
	}, side)

	round(badge, 8)

	new("UIStroke", { Color = th.line, Transparency = 0.72 }, badge)

	local face = new("ImageLabel", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 6, 0.5, 0),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = th.panel,
		BorderSizePixel = 0,
		Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", lp.UserId),
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 8,
	}, badge)

	new("UICorner", { CornerRadius = UDim.new(1, 0) }, face)

	new("UIStroke", { Color = th.line, Transparency = 0.45 }, face)

	local nick = new("TextLabel", {
		Name = rnd(),
		Position = UDim2.fromOffset(45, 6),
		Size = UDim2.new(1, -51, 0, 15),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = lp.DisplayName,
		TextColor3 = th.text,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 8,
	}, badge)

	local handle = new("TextLabel", {
		Name = rnd(),
		Position = UDim2.fromOffset(45, 22),
		Size = UDim2.new(1, -51, 0, 13),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "@" .. lp.Name,
		TextColor3 = th.dim,
		TextSize = 11,
		TextTransparency = 0.3,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 8,
	}, badge)

	conn(lp:GetPropertyChangedSignal("DisplayName"), function()
		nick.Text = lp.DisplayName
	end)

	if visualsui.mobile then
		logo.Visible = false
		under.Visible = false
		badge.Visible = false
		seam.Visible = false
		tabs.Position = UDim2.fromOffset(6, 10)
		tabs.Size = UDim2.new(1, -12, 1, -18)
	end

	local order, live = 0, nil

	local function inlay(card, item, tail)
		local sv = new("Frame", {
			Name = rnd(),
			Active = true,
			Position = UDim2.fromOffset(10, 40),
			Size = UDim2.new(1, -20, 0, 98),
			BackgroundColor3 = Color3.fromHSV(0, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 6,
		}, card)

		round(sv, 6)

		local tintw = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 30,
		}, sv)

		round(tintw, 6)

		new("UIGradient", {
			Color = ColorSequence.new(Color3.new(1, 1, 1)),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, tintw)

		local tintb = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(),
			BorderSizePixel = 0,
			ZIndex = 30,
		}, sv)

		round(tintb, 6)

		new("UIGradient", {
			Color = ColorSequence.new(Color3.new()),
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
		}, tintb)

		new("UIStroke", { Color = th.panel, Thickness = 1.5 }, sv)

		local dot = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(9, 9),
			BackgroundColor3 = th.accent,
			BorderSizePixel = 0,
			ZIndex = 31,
		}, sv)

		new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
		new("UIStroke", { Color = th.bg, Transparency = 0.25 }, dot)

		local bar = new("Frame", {
			Name = rnd(),
			Active = true,
			Position = UDim2.fromOffset(10, 146),
			Size = UDim2.new(1, -20, 0, 10),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 6,
		}, card)

		round(bar, 5)
		new("UIStroke", { Color = th.panel, Thickness = 1.5 }, bar)

		local keys = {}

		for i = 0, 6 do
			table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
		end

		new("UIGradient", { Color = ColorSequence.new(keys) }, bar)

		local pin = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(4, 16),
			BackgroundColor3 = th.accent,
			BorderSizePixel = 0,
			ZIndex = 31,
		}, bar)

		new("UICorner", { CornerRadius = UDim.new(1, 0) }, pin)
		new("UIStroke", { Color = th.bg, Transparency = 0.25 }, pin)

		local field = new("TextBox", {
			Name = rnd(),
			Position = UDim2.fromOffset(10, 164),
			Size = UDim2.new(1, -66, 0, 22),
			BackgroundColor3 = th.head,
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Font = Enum.Font.GothamBold,
			Text = hexof(item.color),
			TextColor3 = th.text,
			TextSize = 13,
			ZIndex = 6,
		}, card)

		round(field, 5)

		local st = { h = 0, s = 1, v = 1, hold = false, drag = nil }

		st.h, st.s, st.v = Color3.toHSV(item.color)

		local function paint(fire, snap)
			local c = Color3.fromHSV(st.h, st.s, st.v)
			local spot = UDim2.fromScale(st.s, 1 - st.v)
			local slide = UDim2.new(st.h, 0, 0.5, 0)

			if snap then
				dot.Position = spot
				pin.Position = slide
				dot.BackgroundColor3 = c
				sv.BackgroundColor3 = Color3.fromHSV(st.h, 1, 1)

				if item.chip then
					item.chip.BackgroundColor3 = c
				end
			else
				anim(dot, quick, { Position = spot, BackgroundColor3 = c })
				anim(pin, quick, { Position = slide })
				anim(sv, quick, { BackgroundColor3 = Color3.fromHSV(st.h, 1, 1) })

				if item.chip then
					anim(item.chip, quick, { BackgroundColor3 = c })
				end
			end

			if not field:IsFocused() then
				field.Text = hexof(c)
			end

			item.apply(c, fire)
		end

		local function reel()
			local o = card.Parent

			while o and o ~= scr do
				if o:IsA("ScrollingFrame") then
					return o
				end

				o = o.Parent
			end
		end

		local roll = reel()

		local function releaseDrag()
			if not st.hold then
				return
			end

			st.hold = false
			st.drag = nil

			if roll then
				roll.ScrollingEnabled = true
			end

			latch(-1)
		end

		local function updateDrag()
			if st.hold and st.drag then
				local ok, err = pcall(function() st.drag(); paint(true, true) end)
				if not ok then releaseDrag(); warn("[visuals] color drag: " .. tostring(err)) end
			end
		end

		local function graze(frame, apply)
			conn(frame.Destroying, releaseDrag)
			conn(frame.InputBegan, function(i)
				if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
					return
				end

				if st.hold then
					return
				end

				st.hold = true
				st.drag = apply
				st.input = i

				latch(1)

				if roll then
					roll.ScrollingEnabled = false
				end

				updateDrag()
			end)

			conn(frame.InputEnded, function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or (i.UserInputType == Enum.UserInputType.Touch and i == st.input) then
					releaseDrag()
				end
			end)
		end

		graze(sv, function()
			local p, s = sv.AbsolutePosition, sv.AbsoluteSize

			local at = pointer(st.input)
			st.s = math.clamp((at.X - p.X) / math.max(s.X, 1), 0, 1)
			st.v = 1 - math.clamp((at.Y - p.Y) / math.max(s.Y, 1), 0, 1)
		end)

		graze(bar, function()
			local p, s = bar.AbsolutePosition, bar.AbsoluteSize

			st.h = math.clamp((pointer(st.input).X - p.X) / math.max(s.X, 1), 0, 1)
		end)

		conn(uis.InputEnded, function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or (i.UserInputType == Enum.UserInputType.Touch and i == st.input) then
				releaseDrag()
			end
		end)

		conn(uis.InputChanged, function(i)
			if not st.hold then
				return
			end

			if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
				if i.UserInputType == Enum.UserInputType.Touch and i ~= st.input then return end
				updateDrag()
			end
		end)

		conn(field.FocusLost, function()
			local c = fromhex(field.Text)

			if c then
				st.h, st.s, st.v = Color3.toHSV(c)
			end

			paint(true)
		end)

		function tail.pull(c)
			st.h, st.s, st.v = Color3.toHSV(c)

			paint(true)
		end

		paint(false, true)
	end

	local function attach(pg, trail)
		if not visualsui.heads then
			visualsui.heads = {}
		end

		local cols = {}
		local cards = {}
		local lip = 34

		trail = trail or "root"

		for i = 1, 2 do
			local col = new("ScrollingFrame", {
				Name = rnd(),
				Position = UDim2.new(0.5 * (i - 1), (i == 1) and 0 or 4, 0, lip),
				Size = UDim2.new(0.5, -4, 1, -lip),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.new(),
				ScrollBarThickness = 0,
				ZIndex = 5,
			}, pg)

			local cl = new("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 9),
			}, col)

			conn(cl:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				col.CanvasSize = UDim2.fromOffset(0, acs(cl).Y + 4)
			end)

			cols[i] = { frame = col, slots = {}, n = 0 }
		end

		local function lane(side)
			if side == "full" or side == 3 then
				if not cols[3] then
					local col = new("ScrollingFrame", {
						Name = rnd(),
						Position = UDim2.fromOffset(0, lip),
						Size = UDim2.new(1, 0, 1, -lip),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						CanvasSize = UDim2.new(),
						ScrollBarThickness = 0,
						ZIndex = 5,
					}, pg)

					local cl = new("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 9),
					}, col)

					conn(cl:GetPropertyChangedSignal("AbsoluteContentSize"), function()
						col.CanvasSize = UDim2.fromOffset(0, acs(cl).Y + 4)
					end)

					cols[3] = { frame = col, slots = {}, n = 0 }

					cols[1].frame.Visible = false
					cols[2].frame.Visible = false
				end

				return cols[3]
			end

			return cols[(side == "right" or side == 2) and 2 or 1]
		end

		local quest = new("Frame", {
			Name = rnd(),
			Position = UDim2.fromOffset(-16, -16),
			Size = UDim2.new(1, 32, 0, 42),
			BackgroundColor3 = th.bg,
			BorderSizePixel = 0,
			ZIndex = 6,
		}, pg)

		local seam = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			ZIndex = 6,
		}, quest)

		local seamGlow = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = th.glow,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			ZIndex = 6,
		}, seam)

		fade(seamGlow, 90, {
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.35),
			NumberSequenceKeypoint.new(1, 1),
		})

		local seamLine = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = th.line,
			BorderSizePixel = 0,
			ZIndex = 7,
		}, seam)

		fade(seamLine, 0, {
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.12, 0.25),
			NumberSequenceKeypoint.new(0.88, 0.25),
			NumberSequenceKeypoint.new(1, 1),
		})

		local tally = new("TextLabel", {
			Name = rnd(),
			Position = UDim2.fromOffset(17, 3),
			Size = UDim2.new(1, -110, 1, -8),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = "",
			TextColor3 = th.dim,
			TextSize = 14,
			TextTransparency = 1,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 7,
		}, quest)

		local probe = new("TextBox", {
			Name = rnd(),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -44, 0.5, -1),
			Size = UDim2.new(0, 0, 0, 27),
			BackgroundColor3 = th.head,
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			ClipsDescendants = true,
			Font = Enum.Font.GothamBold,
			PlaceholderColor3 = th.dim,
			PlaceholderText = "search",
			Text = "",
			TextColor3 = th.text,
			TextSize = 14,
			TextTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Visible = false,
			ZIndex = 7,
		}, quest)

		round(probe, 8)

		new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, probe)

		local hem = new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = th.line,
			Transparency = 0.55,
		}, probe)

		local glint = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.new(1, 6, 0, 1),
			BackgroundColor3 = th.accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 8,
		}, probe)

		fade(glint, 0, {
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1),
		})

		local lens = new("ImageButton", {
			Name = rnd(),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -17, 0.5, 2),
			Size = UDim2.fromOffset(22, 22),
			BackgroundColor3 = th.head,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = icon("search"),
			ImageColor3 = th.dim,
			ImageTransparency = 0.2,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 8,
		}, quest)

		round(lens, 6)

		if visualsui.mobile then
			local shut = new("ImageButton", {
				Name = rnd(),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 2),
				Size = UDim2.fromOffset(24, 24),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = icon("x"),
				ImageColor3 = th.dim,
				ImageTransparency = 0.1,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 8,
			}, quest)

			lens.Position = UDim2.new(1, -48, 0.5, 2)
			probe.Position = UDim2.new(1, -76, 0.5, -1)

			conn(shut.MouseButton1Click, function()
				win:toggle()
			end)
		end

		local head = { quest = quest, links = {} }

		table.insert(visualsui.heads, head)
		visualsui.linkhead(head)

		local function sift(raw)
			local q = string.match(string.lower(raw or ""), "^%s*(.-)%s*$") or ""
			local hits = 0

			for _, cd in next, cards do
				local own = q == "" or string.find(string.lower(cd.name), q, 1, true) ~= nil
				local any, moved = false, false

				for _, rw in next, cd.rows do
					local direct = q ~= "" and string.find(string.lower(rw.name), q, 1, true) ~= nil
					local ok = own or direct

					if rw.row.Visible ~= ok then
						rw.row.Visible = ok
						moved = true
					end

					any = any or ok

					if direct then
						hits += 1
					end
				end

				if cd.gate then
					cd.gate(q ~= "" and any or nil)
				end

				if moved and cd.fit then
					cd.fit()
				end

				if own and q ~= "" then
					hits += 1
				end

				cd.slot.show(own or any)
			end

			return hits
		end

		local lit, shut = false, 0

		local function flick(v)
			if lit == v then
				return
			end

			lit = v

			for _, b in next, head.links do
				b.Visible = not v
			end

			if v then
				probe.Visible = true
				lens.Image = icon("x")

				anim(probe, soft, { Size = UDim2.new(0.66, -44, 0, 27), TextTransparency = 0 })
				anim(hem, soft, { Transparency = 0.35 })
				anim(glint, soft, { BackgroundTransparency = 0.35 })
				anim(lens, soft, { ImageTransparency = 0, ImageColor3 = th.text, BackgroundTransparency = 0.45 })

				task.delay(0.12, function()
					if lit then
						probe:CaptureFocus()
					end
				end)
			else
				shut = os.clock()

				lens.Image = icon("search")

				probe:ReleaseFocus()

				if probe.Text ~= "" then
					probe.Text = ""
				end

				anim(probe, soft, { Size = UDim2.new(0, 0, 0, 27), TextTransparency = 1 })
				anim(hem, soft, { Transparency = 0.55 })
				anim(glint, soft, { BackgroundTransparency = 1 })
				anim(lens, soft, { ImageTransparency = 0.2, ImageColor3 = th.dim, BackgroundTransparency = 1 })

				task.delay(0.28, function()
					if not lit then
						probe.Visible = false
					end
				end)
			end
		end

		conn(lens.MouseButton1Click, function()
			if not lit and os.clock() - shut < 0.25 then
				return
			end

			flick(not lit)
		end)

		conn(lens.MouseEnter, function()
			anim(lens, soft, { ImageTransparency = 0, ImageColor3 = th.text, BackgroundTransparency = 0.45 })
		end)

		conn(lens.MouseLeave, function()
			if not lit then
				anim(lens, soft, { ImageTransparency = 0.2, ImageColor3 = th.dim, BackgroundTransparency = 1 })
			end
		end)

		conn(probe:GetPropertyChangedSignal("Text"), function()
			local hits = sift(probe.Text)
			local busy = string.match(probe.Text, "%S") ~= nil

			tally.Text = busy and (hits .. (hits == 1 and " result" or " results")) or ""

			anim(tally, soft, { TextTransparency = busy and 0.2 or 1 })
		end)

		conn(probe.FocusLost, function()
			if not string.match(probe.Text, "%S") then
				flick(false)
			end
		end)

		local api = {}

		local function crate(col, fixed)
			col.n += 1

			local slot = new("Frame", {
				Name = rnd(),
				Size = UDim2.new(1, 0, 0, fixed or 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = col.n,
				ZIndex = 5,
			}, col.frame)

			local curtain = new("Frame", {
				Name = rnd(),
				Size = UDim2.new(1, 0, 0, fixed or 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				ZIndex = 5,
			}, slot)

			curtain:SetAttribute("VisualsCardCurtain", true)

			local skin = new("Frame", {
				Name = rnd(),
				Size = fixed and UDim2.new(1, 0, 0, fixed) or UDim2.new(1, 0, 0, 0),
				AutomaticSize = (not fixed) and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
				BackgroundColor3 = th.panel,
				BorderSizePixel = 0,
				ZIndex = 5,
			}, curtain)

			round(skin, 7)

			new("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(178, 178, 190)),
				}),
			}, skin)

			if native then
				new("UIShadow", {
					Color = th.bg,
					BlurRadius = UDim.new(0, 12),
					Offset = UDim2.fromOffset(0, 3),
					Spread = UDim2.fromOffset(-2, -2),
					Transparency = 0.45,
					ZIndex = -1,
				}, skin)
			end

			local rec = { frame = slot, curtain = curtain, panel = skin, live = true }

			function rec.show(v)
				v = v and true or false

				if rec.live == v then
					return
				end

				rec.live = v

				if v then
					slot.Visible = true
				end

				flow(curtain, 0.26, v and outq or inq, function(k)
					local h = asz(skin).Y
					local p = v and k or (1 - k)
					local a = math.floor(h * p + 0.5)

					slot.Size = UDim2.new(1, 0, 0, a)
					curtain.Size = UDim2.new(1, 0, 0, a)
					skin.Position = UDim2.fromOffset(0, -math.floor(math.min(18, h) * (1 - p) + 0.5))

					if k >= 1 then
						skin.Position = UDim2.new()
						slot.Visible = v

						if v then
							slot.Size = UDim2.new(1, 0, 0, h)
							curtain.Size = UDim2.new(1, 0, 0, h)
						end
					end
				end)
			end

			table.insert(col.slots, rec)

			conn(skin:GetPropertyChangedSignal("AbsoluteSize"), function()
				local h = asz(skin).Y

				if not rec.live then
					return
				end

				slot.Size = UDim2.new(1, 0, 0, h)

				if not rides[curtain] then
					curtain.Size = UDim2.new(1, 0, 0, h)
				end
			end)

			return skin, rec
		end

		function api.reveal()
			api.settle()
		end

		function api.settle()
			for _, c in next, cols do
				for _, s in next, c.slots do
					if s.live then
						local prev = rides[s.curtain]

						if prev then
							prev:Disconnect()
							rides[s.curtain] = nil
						end

						s.panel.Position = UDim2.new()
						s.curtain.Size = UDim2.new(1, 0, 0, asz(s.panel).Y)
					end
				end
			end
		end

		local function bindpod(anchor, title, vue, keep, opt)
			local bd = { on = false, live = false, key = nil, mode = "toggle", value = 0, w = 198, h = 0 }
			local slot = opt.value

			if slot then
				bd.value = tonumber(slot.default) or slot.min or 0
			end

			local veil = new("ImageButton", {
				Name = rnd(),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ImageTransparency = 1,
				Visible = false,
				ZIndex = 33,
			}, root)

			local pit = native and new("Frame", {
				Name = rnd(),
				Size = UDim2.fromOffset(0, 0),
				BackgroundColor3 = th.panel,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Visible = false,
				ZIndex = 34,
			}, root) or nil

			local cast = pit and new("UIShadow", {
				Color = th.bg,
				BlurRadius = UDim.new(0, 16),
				Offset = UDim2.fromOffset(0, 5),
				Spread = UDim2.fromOffset(-3, -3),
				Transparency = 1,
				ZIndex = -1,
			}, pit) or nil

			if pit then
				round(pit, 8)
			end

			local hull = new("CanvasGroup", {
				Name = rnd(),
				Size = UDim2.fromOffset(0, 0),
				BackgroundColor3 = th.panel,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				GroupTransparency = 1,
				Visible = false,
				ZIndex = 35,
			}, root)

			round(hull, 8)

			new("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(178, 178, 190)),
				}),
			}, hull)

			new("ImageButton", {
				Name = rnd(),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ImageTransparency = 1,
				ZIndex = 1,
			}, hull)

			local brim = new("Frame", {
				Name = rnd(),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 44,
			}, hull)

			round(brim, 8)

			new("UIStroke", { Color = th.line, Transparency = 0.6 }, brim)

			local cap = new("Frame", {
				Name = rnd(),
				Size = UDim2.new(1, 0, 0, 31),
				BackgroundColor3 = th.head,
				BorderSizePixel = 0,
				ZIndex = 36,
			}, hull)

			round(cap, 8)

			new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 8),
				BackgroundColor3 = th.head,
				BorderSizePixel = 0,
				ZIndex = 36,
			}, cap)

			local mast = new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -20, 1, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 37,
			}, cap)

			new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 7),
			}, mast)

			new("ImageLabel", {
				Name = rnd(),
				Size = UDim2.fromOffset(13, 13),
				BackgroundTransparency = 1,
				Image = icon("keyboard"),
				ImageColor3 = th.accent,
				ImageTransparency = 0.12,
				LayoutOrder = 1,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 38,
			}, mast)

			new("TextLabel", {
				Name = rnd(),
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, 16),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = title,
				TextColor3 = th.text,
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = 2,
				ZIndex = 38,
			}, mast)

			local rule = new("Frame", {
				Name = rnd(),
				Position = UDim2.fromOffset(0, 31),
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = th.line,
				BackgroundTransparency = 0.25,
				BorderSizePixel = 0,
				ZIndex = 37,
			}, hull)

			fade(rule, 0, {
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.18, 0.15),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(0.82, 0.15),
				NumberSequenceKeypoint.new(1, 1),
			})

			local slab = new("Frame", {
				Name = rnd(),
				Position = UDim2.fromOffset(0, 34),
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 36,
			}, hull)

			new("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}, slab)

			new("UIPadding", {
				PaddingTop = UDim.new(0, 7),
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 7),
				PaddingRight = UDim.new(0, 7),
			}, slab)

			local tier = 0

			local function bunk(h)
				tier += 1

				return new("Frame", {
					Name = rnd(),
					Size = UDim2.new(1, 0, 0, h),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = tier,
					ZIndex = 36,
				}, slab)
			end

			local function stub(host, text, y, w)
				return new("TextLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(5, y),
					Size = UDim2.new(w or 0.4, -8, 0, 15),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = text,
					TextColor3 = th.dim,
					TextSize = 11,
					TextTransparency = 0.4,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 37,
				}, host)
			end

			local keybunk = bunk(22)

			stub(keybunk, "bind", 4)

			local wipe = new("ImageButton", {
				Name = rnd(),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -5, 0.5, 0),
				Size = UDim2.fromOffset(20, 20),
				BackgroundColor3 = th.head,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = "",
				ZIndex = 38,
			}, keybunk)

			round(wipe, 5)

			local wipepip = new("ImageLabel", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(11, 11),
				BackgroundTransparency = 1,
				Image = icon("trash-2"),
				ImageColor3 = th.dim,
				ImageTransparency = 0.65,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 39,
			}, wipe)

			local pill = new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -28, 0.5, 0),
				Size = UDim2.new(0.6, -33, 0, 21),
				BackgroundColor3 = th.head,
				BackgroundTransparency = 0.12,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				ZIndex = 37,
			}, keybunk)

			round(pill, 6)

			local ring = new("UIStroke", { Color = th.line, Transparency = 0.62 }, pill)

			local shown = new("TextLabel", {
				Name = rnd(),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = "None",
				TextColor3 = th.text,
				TextSize = 12,
				TextTransparency = 0.1,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 38,
			}, pill)

			local beam = new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = th.accent,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 39,
			}, pill)

			fade(beam, 0, {
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1),
			})

			local hit = new("ImageButton", {
				Name = rnd(),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ImageTransparency = 1,
				ZIndex = 40,
			}, pill)

			local dial, fill, worth, grab = nil, nil, nil, nil

			if slot then
				local valbunk = bunk(34)

				stub(valbunk, "value", 1)

				worth = new("TextLabel", {
					Name = rnd(),
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -5, 0, 1),
					Size = UDim2.fromOffset(70, 15),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = "",
					TextColor3 = th.text,
					TextSize = 12,
					TextTransparency = 0.15,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Right,
					ZIndex = 37,
				}, valbunk)

				dial = new("Frame", {
					Name = rnd(),
					Position = UDim2.fromOffset(5, 23),
					Size = UDim2.new(1, -10, 0, 6),
					BackgroundColor3 = th.head,
					BackgroundTransparency = 0.12,
					BorderSizePixel = 0,
					ZIndex = 37,
				}, valbunk)

				new("UICorner", { CornerRadius = UDim.new(1, 0) }, dial)

				fill = new("Frame", {
					Name = rnd(),
					Size = UDim2.new(0, 6, 1, 0),
					BackgroundColor3 = th.accent,
					BackgroundTransparency = 0.1,
					BorderSizePixel = 0,
					ZIndex = 38,
				}, dial)

				new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

				grab = new("Frame", {
					Name = rnd(),
					Active = true,
					Position = UDim2.fromOffset(0, 18),
					Size = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 39,
				}, valbunk)
			end

			local picks, glider = {}, nil

			if opt.mode then
				local segbunk = bunk(24)

				local seg = new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(1, -10, 0, 22),
					BackgroundColor3 = th.head,
					BackgroundTransparency = 0.12,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					ZIndex = 37,
				}, segbunk)

				round(seg, 6)

				new("UIStroke", { Color = th.line, Transparency = 0.62 }, seg)

				glider = new("Frame", {
					Name = rnd(),
					Position = UDim2.new(0, 2, 0, 2),
					Size = UDim2.new(0.5, -3, 1, -4),
					BackgroundColor3 = th.accent,
					BackgroundTransparency = 0.82,
					BorderSizePixel = 0,
					ZIndex = 38,
				}, seg)

				round(glider, 5)

				fade(glider, 90, {
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 0.55),
				})

				new("UIStroke", { Color = th.accent, Transparency = 0.72 }, glider)

				for i, name in next, { "toggle", "hold" } do
					local o = { name = name, warm = false, slot = i }

					o.btn = new("ImageButton", {
						Name = rnd(),
						Position = UDim2.new(0.5 * (i - 1), 0, 0, 0),
						Size = UDim2.new(0.5, 0, 1, 0),
						BackgroundTransparency = 1,
						ImageTransparency = 1,
						ZIndex = 40,
					}, seg)

					o.lbl = new("TextLabel", {
						Name = rnd(),
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Font = Enum.Font.GothamBold,
						Text = name,
						TextColor3 = th.dim,
						TextSize = 12,
						TextTransparency = 0.45,
						ZIndex = 39,
					}, o.btn)

					picks[i] = o
				end
			end

			local step = slot and math.max(tonumber(slot.step) or 1, 0) or 0
			local dec = slot and slot.dec or 0
			local live = false

			local function tag(v)
				if dec > 0 then
					return string.format("%." .. dec .. "f", v) .. (slot.suffix or "")
				end

				return string.format("%d", math.floor(v + 0.5)) .. (slot.suffix or "")
			end

			local function snap(v)
				v = math.clamp(v, slot.min, slot.max)

				if step > 0 then
					v = slot.min + math.floor((v - slot.min) / step + 0.5) * step
				end

				if dec > 0 then
					v = tonumber(string.format("%." .. dec .. "f", v)) or v
				end

				return math.clamp(v, slot.min, slot.max)
			end

			local function meter()
				if not slot then
					return
				end

				local range = slot.max - slot.min
				local k = (range > 0) and (bd.value - slot.min) / range or 0

				worth.Text = tag(bd.value)

				anim(fill, live and glide or quick, {
					Size = UDim2.new(k, math.floor(6 * (1 - k) + 0.5), 1, 0),
				})
			end

			local function shade()
				for i = 1, #picks do
					local o = picks[i]
					local sel = bd.mode == o.name

					anim(o.lbl, quick, {
						TextTransparency = sel and 0 or (o.warm and 0.2 or 0.45),
						TextColor3 = sel and th.text or th.dim,
					})

					if sel and glider then
						anim(glider, soft, { Position = UDim2.new(0.5 * (o.slot - 1), 2, 0, 2) })
					end
				end
			end

			local function tint()
				shown.Text = bd.hunting and "..." or keyname(bd.key)

				anim(pill, soft, { BackgroundTransparency = bd.hunting and 0 or 0.12 })
				anim(ring, soft, { Transparency = bd.hunting and 0.22 or 0.62 })
				anim(beam, soft, { BackgroundTransparency = bd.hunting and 0.25 or 1 })
				anim(shown, soft, {
					TextTransparency = bd.key and 0.05 or 0.35,
					TextColor3 = bd.hunting and th.accent or (bd.key and th.text or th.dim),
				})
				anim(wipepip, soft, { ImageTransparency = bd.key and 0.25 or 0.7 })
			end

			local function post()
				if not bd.key then
					unperch(opt.id)

					return
				end

				perch(opt.id, {
					name = title,
					key = keyname(bd.key),
					art = opt.art,
					press = opt.press,
					worth = opt.show and opt.show() or nil,
					lit = opt.state and opt.state() or false,
				})
			end

			local function tall()
				return 34 + math.max(math.floor(asz(slab).Y + 0.5), 24)
			end

			local function place()
				local rp, rz = apos(root), asz(root)
				local pp, ps = apos(vue), asz(vue)
				local ap, as = apos(anchor), asz(anchor)
				local rightx = pp.X - rp.X + ps.X + 8
				local leftx = pp.X - rp.X - bd.w - 8
				local x = rightx

				if rightx + bd.w > rz.X - 8 then
					x = (leftx >= 8) and leftx or math.max(8, rz.X - 8 - bd.w)
				end

				local y = math.clamp(
					ap.Y - rp.Y + as.Y * 0.5 - bd.h * 0.5,
					8,
					math.max(8, rz.Y - bd.h - 8)
				)

				hull.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))

				if pit then
					pit.Position = hull.Position
				end
			end

			local function fit()
				bd.h = tall()

				hull.Size = UDim2.fromOffset(bd.w, bd.h)

				if pit then
					pit.Size = hull.Size
				end
			end

			local function slide()
				local from = hull.GroupTransparency
				local to = bd.on and 0 or 1

				flow(hull, bd.on and 0.34 or 0.26, bd.on and outq or inq, function(k)
					local a = from + (to - from) * k

					hull.GroupTransparency = a

					if pit then
						pit.BackgroundTransparency = a
						cast.Transparency = 0.35 + 0.65 * a
					end

					if k >= 1 then
						hull.Visible = bd.on

						if pit then
							pit.Visible = bd.on
						end
					end
				end)
			end

			local track = nil

			local function untrack()
				if track then
					track:Disconnect()
					track = nil
				end
			end

			local function shut()
				bd:setopen(false)
			end

			local function follow()
				if locks > 0 then
					place()

					return
				end

				if not win.open or not pg.Visible or not anchor.Visible then
					bd:setopen(false)

					return
				end

				local vp, vs = vue.AbsolutePosition, vue.AbsoluteSize
				local hp, hs = keep.AbsolutePosition, keep.AbsoluteSize
				local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
				local mid = ap.Y + as.Y * 0.5

				if mid < vp.Y or mid > vp.Y + vs.Y or mid < hp.Y or mid > hp.Y + hs.Y then
					bd:setopen(false)

					return
				end

				place()
			end

			function bd:setopen(v)
				v = v and true or false

				if bd.on == v then
					return
				end

				bd.on = v

				if v then
					sink()
					hush(bd)
					fit()

					veil.Visible = true
					hull.Visible = true

					if pit then
						pit.Visible = true
					end

					place()

					sky = shut
					skyzone = hull

					untrack()

					track = rs.RenderStepped:Connect(follow)
				else
					untrack()

					veil.Visible = false

					if bd.hunting then
						bd.hunting = false

						capture(nil)
						tint()
					end

					if sky == shut then
						sky = nil
						skyzone = nil
					end
				end

				slide()
			end

			local flick = 0

			function bd:flip()
				local now = os.clock()

				if now - flick < 0.2 then
					return false
				end

				flick = now

				if bd.on and (inside(hull, 2) or (pit and inside(pit, 2))) then
					return false
				end

				bd:setopen(not bd.on)

				return true
			end

			local function shed()
				if overkeys() then
					return
				end

				flick = os.clock()

				bd:setopen(false)
			end

			conn(veil.MouseButton1Click, shed)
			conn(veil.MouseButton2Click, shed)

			function bd:setkey(v)
				local k = v

				if type(k) == "string" then
					k = select(2, pcall(function()
						return Enum.KeyCode[v]
					end))
				end

				if typeof(k) ~= "EnumItem" or k == Enum.KeyCode.Unknown then
					k = nil
				end

				if bd.key == k then
					return
				end

				if bd.live then
					bd.live = false

					opt.fire(false)
				end

				bd.key = k

				tint()
				post()
			end

			function bd:setmode(m)
				if m ~= "toggle" and m ~= "hold" then
					return
				end

				if bd.mode == m then
					return
				end

				if bd.live then
					bd.live = false

					opt.fire(false)
				end

				bd.mode = m

				shade()
			end

			function bd:setvalue(v)
				if not slot then
					return
				end

				v = snap(tonumber(v) or slot.min)

				if bd.value == v then
					return
				end

				bd.value = v

				meter()

				if bd.key then
					post()
				end
			end

			function bd:sync(v)
				bd.live = v and true or false
			end

			function bd:lit(v)
				relight(opt.id, v)
			end

			bd.fire = opt.fire

			local function halt()
				bd.hunting = false

				tint()
			end

			conn(hit.MouseButton1Click, function()
				if bd.hunting then
					capture(nil)
					halt()

					return
				end

				bd.hunting = true

				tint()

				visualsui:chime("flip")

				capture(function(k)
					halt()

					if k then
						bd:setkey(k)

						visualsui:chime("tap")
					end
				end, halt)
			end)

			conn(wipe.MouseButton1Click, function()
				if bd.hunting then
					capture(nil)
					halt()
				end

				if not bd.key then
					return
				end

				bd:setkey(nil)

				wipepip.ImageColor3 = th.accent

				anim(wipepip, soft, { ImageColor3 = th.dim })

				visualsui:chime("off")
			end)

			conn(wipe.MouseEnter, function()
				anim(wipe, soft, { BackgroundTransparency = 0.4 })
				anim(wipepip, soft, { ImageTransparency = 0, ImageColor3 = th.text })
			end)

			conn(wipe.MouseLeave, function()
				anim(wipe, soft, { BackgroundTransparency = 1 })
				anim(wipepip, soft, {
					ImageTransparency = bd.key and 0.25 or 0.7,
					ImageColor3 = th.dim,
				})
			end)

			for i = 1, #picks do
				local o = picks[i]

				conn(o.btn.MouseEnter, function()
					o.warm = true

					shade()
				end)

				conn(o.btn.MouseLeave, function()
					o.warm = false

					shade()
				end)

				conn(o.btn.MouseButton1Click, function()
					bd:setmode(o.name)

					visualsui:chime("tap")
				end)
			end

			shade()

			if slot then
				local dragLocked = false
				local function finishDrag()
					live = false
					if dragLocked then dragLocked = false; latch(-1) end
				end
				conn(grab.Destroying, finishDrag)
				conn(grab.InputBegan, function(i)
					if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
						return
					end

					if live then
						return
					end

					live = true
					dragLocked = true

					latch(1)

					local ok, err = pcall(function()
					visualsui:chime("tap")
					while live and visualsui.alive and grab.Parent and i.UserInputState ~= Enum.UserInputState.End and i.UserInputState ~= Enum.UserInputState.Cancel do
						local p, s = dial.AbsolutePosition, dial.AbsoluteSize

						if s.X > 0 then
							bd:setvalue(slot.min + (slot.max - slot.min) * math.clamp((pointer(i).X - p.X) / s.X, 0, 1))
						end

						task.wait()
					end

					end)
					finishDrag()
					if not ok then warn("[visuals] slider drag: " .. tostring(err)) end
					meter()
				end)

				conn(grab.InputEnded, function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
						finishDrag()
					end
				end)

				conn(uis.InputEnded, function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
						finishDrag()
					end
				end)

				bd.value = snap(bd.value)

				meter()
			end

			conn(slab:GetPropertyChangedSignal("AbsoluteSize"), function()
				if bd.on then
					fit()
					place()
				end
			end)

			conn(uis.InputBegan, function(i)
				if not bd.on or locks > 0 or overkeys() then
					return
				end

				if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
					return
				end

				if inside(hull, 2) or (pit and inside(pit, 2)) then
					return
				end

				task.defer(function()
					if bd.on then
						bd:setopen(false)
					end
				end)
			end)

			conn(uis.InputBegan, function(i, typing)
				if typing or visualsui.capturing or not bd.key or not visualsui.alive then
					return
				end

				if i.UserInputType ~= Enum.UserInputType.Keyboard or i.KeyCode ~= bd.key then
					return
				end

				if not opt.mode then
					opt.fire(true)

					return
				end

				if bd.mode == "hold" then
					if bd.live then
						return
					end

					bd.live = true

					opt.fire(true)
				else
					bd.live = not bd.live

					opt.fire(bd.live)
				end
			end)

			conn(uis.InputEnded, function(i)
				if bd.mode ~= "hold" or not bd.key or not bd.live then
					return
				end

				if i.UserInputType ~= Enum.UserInputType.Keyboard or i.KeyCode ~= bd.key then
					return
				end

				bd.live = false

				opt.fire(false)
			end)

			tint()

			table.insert(hive, bd)

			visualsui:hook(opt.id .. "|bind", "key", function()
				return bd.key and bd.key.Name or nil
			end, function(v)
				bd:setkey(v)
			end)

			if opt.mode then
				visualsui:hook(opt.id .. "|bindmode", "list", function()
					return bd.mode
				end, function(v)
					bd:setmode(v)
				end, {validate=function(v) return v == "toggle" or v == "hold" end})
			end

			if slot then
				visualsui:hook(opt.id .. "|bindvalue", "number", function()
					return bd.value
				end, function(v)
					bd:setvalue(v)
				end, {min=slot.min, max=slot.max})
			end

			return bd
		end

		function api:section(cfg)
			cfg = params(cfg, {
				name = "section",
				side = "left",
			})

			local col = lane(cfg.side)
			local panel, rec = crate(col)
			local seek = { slot = rec, name = cfg.name, rows = {} }
			local base = trail .. "|" .. cfg.name

			table.insert(cards, seek)

			new("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 0),
			}, panel)

			local top = new("Frame", {
				Name = rnd(),
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = th.head,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				LayoutOrder = 1,
				ZIndex = 5,
			}, panel)

			round(top, 7)

			new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 8),
				BackgroundColor3 = th.head,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				ZIndex = 5,
			}, top)

			new("TextLabel", {
				Name = rnd(),
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, -38, 1, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = cfg.name,
				TextColor3 = th.text,
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 6,
			}, top)

			local caret = new("ImageLabel", {
				Name = rnd(),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -9, 0.5, 0),
				Size = UDim2.fromOffset(13, 13),
				BackgroundTransparency = 1,
				Image = icon("chevron-down"),
				ImageColor3 = th.dim,
				ImageTransparency = 0.35,
				Rotation = 180,
				ZIndex = 6,
			}, top)

			local grab = new("ImageButton", {
				Name = rnd(),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ImageTransparency = 1,
				ZIndex = 7,
			}, top)

			local rule = new("Frame", {
				Name = rnd(),
				Size = UDim2.new(1, 0, 0, 2),
				BackgroundColor3 = th.accent,
				BackgroundTransparency = 0.45,
				BorderSizePixel = 0,
				LayoutOrder = 2,
				ZIndex = 6,
			}, panel)

			fade(rule, 0, {
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.12, 0.2),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(0.88, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			})

			local hold = new("Frame", {
				Name = rnd(),
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				LayoutOrder = 3,
				ZIndex = 5,
			}, panel)

			local items = new("Frame", {
				Name = rnd(),
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				ZIndex = 5,
			}, hold)

			new("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 1),
			}, items)

			new("UIPadding", {
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 5),
				PaddingRight = UDim.new(0, 5),
			}, items)

			local sec = { panel = panel, items = items, n = 0, open = true }

			conn(items:GetPropertyChangedSignal("AbsoluteSize"), function()
				if sec.open and not sec.glide then
					hold.Size = UDim2.new(1, 0, 0, asz(items).Y)
				end
			end)

			function sec.refit()
				local h0 = hold.Size.Y.Offset

				sec.glide = true

				task.defer(function()
					local h1 = sec.open and asz(items).Y or 0

					flow(hold, 0.32, (h1 >= h0) and outq or inq, function(k)
						hold.Size = UDim2.new(1, 0, 0, math.floor(h0 + (h1 - h0) * k + 0.5))

						if k >= 1 then
							sec.glide = false
							hold.Size = UDim2.new(1, 0, 0, sec.open and asz(items).Y or 0)
						end
					end)
				end)
			end

			function sec:setopen(v)
				sec.open = v and true or false

				local r0, r1 = caret.Rotation, sec.open and 180 or 0

				flow(caret, 0.34, outq, function(k)
					caret.Rotation = r0 + (r1 - r0) * k
				end)

				sec.refit()
			end

			seek.fit = sec.refit

			seek.gate = function(v)
				if v == nil then
					if seek.kept ~= nil then
						local back = seek.kept

						seek.kept = nil

						if sec.open ~= back then
							sec:setopen(back)
						end
					end

					return
				end

				if v and not sec.open then
					if seek.kept == nil then
						seek.kept = false
					end

					sec:setopen(true)
				end
			end

			conn(grab.MouseButton1Click, function()
				sec:setopen(not sec.open)

				visualsui:chime("flip")
			end)

			conn(grab.MouseEnter, function()
				anim(caret, soft, { ImageTransparency = 0.1 })
			end)

			conn(grab.MouseLeave, function()
				anim(caret, soft, { ImageTransparency = 0.35 })
			end)

			local host = { frame = items, va = col.frame, vb = hold }
			local kits = { "toggle", "slider", "keybind", "dropdown", "combo", "color", "button", "label" }

			local function branch(nest, va, vb)
				local sub = {}

				for _, k in next, kits do
					sub[k] = function(_, cfg)
						local pf, pa, pb = host.frame, host.va, host.vb

						host.frame, host.va, host.vb = nest, va, vb

						local ok, res = pcall(sec[k], sec, cfg)

						host.frame, host.va, host.vb = pf, pa, pb

						if not ok then
							error(res, 2)
						end

						table.remove(seek.rows)

						return res
					end
				end

				return sub
			end

			local function bloom(anchor, title, vue, keep)
				local pod = { on = false, w = 0, h = 0 }

				local veil = new("ImageButton", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					Visible = false,
					ZIndex = 22,
				}, root)

				local pit = native and new("Frame", {
					Name = rnd(),
					Size = UDim2.fromOffset(0, 0),
					BackgroundColor3 = th.panel,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 23,
				}, root) or nil

				local cast = pit and new("UIShadow", {
					Color = th.bg,
					BlurRadius = UDim.new(0, 14),
					Offset = UDim2.fromOffset(0, 4),
					Spread = UDim2.fromOffset(-2, -2),
					Transparency = 1,
					ZIndex = -1,
				}, pit) or nil

				if pit then
					round(pit, 7)
				end

				local husk = new("CanvasGroup", {
					Name = rnd(),
					Size = UDim2.fromOffset(0, 0),
					BackgroundColor3 = th.panel,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					GroupTransparency = 1,
					Visible = false,
					ZIndex = 24,
				}, root)

				round(husk, 7)

				new("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(178, 178, 190)),
					}),
				}, husk)

				local brim = new("Frame", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 26,
				}, husk)

				round(brim, 7)

				new("UIStroke", { Color = th.line, Transparency = 0.6 }, brim)

				local pane = new("Frame", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 24,
				}, husk)

				local cap = new("Frame", {
					Name = rnd(),
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundColor3 = th.head,
					BorderSizePixel = 0,
					ZIndex = 24,
				}, pane)

				round(cap, 7)

				new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.fromScale(0, 1),
					Size = UDim2.new(1, 0, 0, 8),
					BackgroundColor3 = th.head,
					BorderSizePixel = 0,
					ZIndex = 24,
				}, cap)

				new("ImageLabel", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 10, 0.5, 0),
					Size = UDim2.fromOffset(12, 12),
					BackgroundTransparency = 1,
					Image = icon("sliders-horizontal"),
					ImageColor3 = th.dim,
					ImageTransparency = 0.3,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 25,
				}, cap)

				new("TextLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(28, 0),
					Size = UDim2.new(1, -36, 1, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = title,
					TextColor3 = th.text,
					TextSize = 13,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 25,
				}, cap)

				local rule = new("Frame", {
					Name = rnd(),
					Position = UDim2.fromOffset(0, 30),
					Size = UDim2.new(1, 0, 0, 2),
					BackgroundColor3 = th.accent,
					BackgroundTransparency = 0.45,
					BorderSizePixel = 0,
					ZIndex = 25,
				}, pane)

				fade(rule, 0, {
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.12, 0.2),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(0.88, 0.2),
					NumberSequenceKeypoint.new(1, 1),
				})

				local roll = new("ScrollingFrame", {
					Name = rnd(),
					Active = false,
					Position = UDim2.fromOffset(0, 32),
					Size = UDim2.new(1, 0, 1, -32),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					CanvasSize = UDim2.new(),
					ScrollBarThickness = 0,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ZIndex = 24,
				}, pane)

				local slab = new("Frame", {
					Name = rnd(),
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 24,
				}, roll)

				new("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 1),
				}, slab)

				new("UIPadding", {
					PaddingTop = UDim.new(0, 6),
					PaddingBottom = UDim.new(0, 8),
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5),
				}, slab)

				local function gauge()
					local rz = asz(root)
					local wide = math.floor(asz(vue).X + 0.5)

					return math.clamp(wide, 160, math.max(math.floor(rz.X) - 24, 160))
				end

				local function tall()
					local rz = asz(root)
					local body = math.max(math.floor(asz(slab).Y + 0.5), 26)

					return math.clamp(32 + body, 64, math.max(math.floor(rz.Y) - 24, 64))
				end

				local function place()
					local rp, rz = apos(root), asz(root)
					local pp, ps = apos(vue), asz(vue)
					local ap, as = apos(anchor), asz(anchor)
					local rightx = pp.X - rp.X + ps.X + 8
					local leftx = pp.X - rp.X - pod.w - 8
					local x = rightx

					if rightx + pod.w > rz.X - 8 then
						x = (leftx >= 8) and leftx or math.max(8, rz.X - 8 - pod.w)
					end

					local y = math.clamp(
						ap.Y - rp.Y + as.Y * 0.5 - pod.h * 0.5,
						8,
						math.max(8, rz.Y - pod.h - 8)
					)

					husk.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))

					if pit then
						pit.Position = husk.Position
					end
				end

				local function slide()
					local from = husk.GroupTransparency
					local to = pod.on and 0 or 1

					flow(husk, pod.on and 0.34 or 0.26, pod.on and outq or inq, function(k)
						local a = from + (to - from) * k

						husk.GroupTransparency = a

						if pit then
							pit.BackgroundTransparency = a
							cast.Transparency = 0.4 + 0.6 * a
						end

						if k >= 1 then
							husk.Visible = pod.on

							if pit then
								pit.Visible = pod.on
							end
						end
					end)
				end

				local function fit()
					pod.w = gauge()
					pod.h = tall()

					husk.Size = UDim2.fromOffset(pod.w, pod.h)

					if pit then
						pit.Size = husk.Size
					end
				end

				local track = nil

				local function untrack()
					if track then
						track:Disconnect()
						track = nil
					end
				end

				local function follow()
					if locks > 0 then
						place()

						return
					end

					if not win.open or not pg.Visible or not anchor.Visible then
						pod:setopen(false)

						return
					end

					local vp, vs = vue.AbsolutePosition, vue.AbsoluteSize
					local hp, hs = keep.AbsolutePosition, keep.AbsoluteSize
					local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
					local mid = ap.Y + as.Y * 0.5

					if mid < vp.Y or mid > vp.Y + vs.Y or mid < hp.Y or mid > hp.Y + hs.Y then
						pod:setopen(false)

						return
					end

					place()
				end

				function pod:setopen(v)
					v = v and true or false

					if pod.on == v then
						return
					end

					pod.on = v

					if v then
						fit()

						husk.Visible = true
						veil.Visible = true
						roll.CanvasPosition = Vector2.new()

						if pit then
							pit.Visible = true
						end

						place()
						untrack()
						maskadd(husk)

						track = rs.RenderStepped:Connect(follow)
					else
						untrack()
						sink()
						maskdel(husk)

						veil.Visible = false
					end

					slide()
				end

				conn(slab:GetPropertyChangedSignal("AbsoluteSize"), function()
					roll.CanvasSize = UDim2.fromOffset(0, math.floor(asz(slab).Y + 0.5))

					if pod.on then
						fit()
						place()
					end
				end)

				conn(veil.MouseButton1Click, function()
					if locks > 0 then
						return
					end

					pod:setopen(false)
				end)

				pod.frame = husk
				pod.body = slab
				pod.api = branch(slab, roll, roll)

				return pod
			end

			function sec:toggle(t)
				t = params(t, {
					name = "toggle",
					default = false,
					options = false,
					flag = nil,
					callback = nil,
				})

				sec.n += 1

				local nest, vue, keep = host.frame, host.va, host.vb

				local row = new("Frame", {
					Name = rnd(),
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = sec.n,
					ZIndex = 5,
				}, nest)

				local box = new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 5, 0.5, 0),
					Size = UDim2.fromOffset(16, 16),
					BackgroundColor3 = th.accent,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 6,
				}, row)

				round(box, 4)

				local edge = new("UIStroke", { Color = th.line, Transparency = 0.2 }, box)

				local tick = new("ImageLabel", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(6, 6),
					BackgroundTransparency = 1,
					Image = icon("check"),
					ImageColor3 = th.bg,
					ImageTransparency = 1,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 7,
				}, box)

				local lbl = new("TextLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(29, 0),
					Size = UDim2.new(1, t.options and -60 or -35, 1, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = t.name,
					TextColor3 = th.dim,
					TextSize = 13,
					TextTransparency = 0.35,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 6,
				}, row)

				local btn = new("ImageButton", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					ZIndex = 8,
				}, row)

				local grip = new("ImageButton", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 2, 0.5, 0),
					Size = UDim2.fromOffset(22, 22),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					ZIndex = 9,
				}, row)

				local dots = t.options and new("ImageButton", {
					Name = rnd(),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -5, 0.5, 0),
					Size = UDim2.fromOffset(21, 21),
					BackgroundColor3 = th.head,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Image = icon("ellipsis"),
					ImageColor3 = th.dim,
					ImageTransparency = 0.35,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 10,
				}, row) or nil

				if dots then
					round(dots, 6)
				end

				table.insert(seek.rows, { row = row, name = t.name })

				local item = { row = row, on = false }
				local warm = false

				if dots then
					local pod = bloom(row, t.name, vue, keep)

					item.pod = pod
					item.options = pod.api

					function item:setoptions(v)
						pod:setopen(v)
					end

					conn(dots.MouseButton1Click, function()
						pod:setopen(not pod.on)

						visualsui:chime("flip")
					end)

					conn(dots.MouseEnter, function()
						anim(dots, soft, { ImageTransparency = 0, ImageColor3 = th.text, BackgroundTransparency = 0.45 })
					end)

					conn(dots.MouseLeave, function()
						anim(dots, soft, { ImageTransparency = 0.35, ImageColor3 = th.dim, BackgroundTransparency = 1 })
					end)
				end

				local function paint()
					anim(box, soft, { BackgroundTransparency = item.on and 0.05 or (warm and 0.88 or 1) })
					anim(edge, soft, { Transparency = item.on and 1 or (warm and 0.05 or 0.2) })
					anim(tick, soft, {
						ImageTransparency = item.on and 0 or 1,
						Size = UDim2.fromOffset(item.on and 12 or 6, item.on and 12 or 6),
					})
					anim(lbl, soft, {
						TextTransparency = item.on and 0 or 0.35,
						TextColor3 = item.on and th.text or th.dim,
					})
				end

				function item:set(v, quiet)
					v = v and true or false

					if item.on == v and not visualsui.configApplying then
						return
					end

					item.on = v
					paint()

					if item.bind then
						item.bind:sync(v)
						item.bind:lit(v)
					end

					if not quiet then
						visualsui:chime(v and "on" or "off")

						if t.callback then
							callback(t.callback, v)
						end
					end
				end

				function item:get()
					return item.on
				end

				conn(btn.MouseButton1Click, function()
					item:set(not item.on)
				end)

				conn(grip.MouseButton1Click, function()
					item:set(not item.on)
				end)

				conn(grip.MouseEnter, function()
					warm = true
					paint()
				end)

				conn(grip.MouseLeave, function()
					warm = false
					paint()
				end)

				if t.default then
					item.on = true
					paint()
				end

				local id = t.flag or (base .. "|" .. t.name)

				local bind = bindpod(row, t.name, vue, keep, {
					id = id,
					art = "toggle-right",
					mode = true,
					fire = function(v)
						item:set(v)
					end,
					press = function()
						item:set(not item.on)
					end,
					state = function()
						return item.on
					end,
				})

				item.bind = bind

				bind:lit(item.on)

				conn(btn.MouseButton2Click, function()
					if not bind:flip() then
						return
					end

					visualsui:chime("flip")
				end)

				conn(grip.MouseButton2Click, function()
					if not bind:flip() then
						return
					end

					visualsui:chime("flip")
				end)

				visualsui:hook(id, "toggle", function()
					return item.on
				end, function(v)
					item:set(v == true or v == "true" or v == 1)
				end)

				return item
			end

			function sec:slider(t)
				t = params(t, {
					name = "slider",
					min = 0,
					max = 100,
					default = nil,
					step = 1,
					suffix = "",
					flag = nil,
					callback = nil,
				})

				sec.n += 1

				local nest, vue, keep = host.frame, host.va, host.vb
				local step = math.max(tonumber(t.step) or 1, 0)
				local dec = (step > 0 and step < 1) and #(string.match(tostring(step), "%.(%d+)") or "") or 0

				local row = new("Frame", {
					Name = rnd(),
					Size = UDim2.new(1, 0, 0, 32),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = sec.n,
					ZIndex = 5,
				}, nest)

				local lbl = new("TextLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(5, 1),
					Size = UDim2.new(1, -74, 0, 16),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = t.name,
					TextColor3 = th.dim,
					TextSize = 13,
					TextTransparency = 0.35,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 6,
				}, row)

				local val = new("TextLabel", {
					Name = rnd(),
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -5, 0, 1),
					Size = UDim2.fromOffset(64, 16),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = "",
					TextColor3 = th.text,
					TextSize = 12,
					TextTransparency = 0.2,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Right,
					ZIndex = 6,
				}, row)

				local track = new("Frame", {
					Name = rnd(),
					Position = UDim2.fromOffset(5, 22),
					Size = UDim2.new(1, -10, 0, 6),
					BackgroundColor3 = th.head,
					BackgroundTransparency = 0.12,
					BorderSizePixel = 0,
					ZIndex = 6,
				}, row)

				new("UICorner", { CornerRadius = UDim.new(1, 0) }, track)

				local fill = new("Frame", {
					Name = rnd(),
					Size = UDim2.new(0, 6, 1, 0),
					BackgroundColor3 = th.accent,
					BackgroundTransparency = 0.1,
					BorderSizePixel = 0,
					ZIndex = 7,
				}, track)

				new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

				local grab = new("Frame", {
					Name = rnd(),
					Active = true,
					Position = UDim2.fromOffset(0, 15),
					Size = UDim2.new(1, 0, 0, 17),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 8,
				}, row)

				local item = { row = row, value = t.min }
				local warm, live, finger = false, false, nil

				table.insert(seek.rows, { row = row, name = t.name })

				local function tag(v)
					if dec > 0 then
						return string.format("%." .. dec .. "f", v) .. t.suffix
					end

					return string.format("%d", math.floor(v + 0.5)) .. t.suffix
				end

				local function snap(v)
					v = math.clamp(v, t.min, t.max)

					if step > 0 then
						v = t.min + math.floor((v - t.min) / step + 0.5) * step
					end

					if dec > 0 then
						v = tonumber(string.format("%." .. dec .. "f", v)) or v
					end

					return math.clamp(v, t.min, t.max)
				end

				local function span(k)
					return UDim2.new(k, math.floor(6 * (1 - k) + 0.5), 1, 0)
				end

				local function paint()
					local range = t.max - t.min
					local k = (range > 0) and (item.value - t.min) / range or 0

					val.Text = tag(item.value)

					anim(fill, live and glide or quick, { Size = span(k) })
				end

				local function glow()
					anim(track, soft, { BackgroundTransparency = (live or warm) and 0 or 0.12 })
					anim(fill, soft, { BackgroundTransparency = live and 0 or (warm and 0.04 or 0.1) })
					anim(lbl, soft, { TextTransparency = (live or warm) and 0.1 or 0.35 })
					anim(val, soft, { TextTransparency = (live or warm) and 0 or 0.2 })
				end

				function item:set(v, quiet)
					v = snap(tonumber(v) or t.min)

					if item.value == v and not visualsui.configApplying then
						return
					end

					item.value = v

					paint()

					if not quiet and t.callback then
						callback(t.callback, v)
					end
				end

				function item:get()
					return item.value
				end

				local function positionX(input)
					if input and input.Position then
						return input.Position.X
					end

					return uis:GetMouseLocation().X
				end

				local function reach(x)
					local p, s = track.AbsolutePosition, track.AbsoluteSize

					if s.X <= 0 then
						return item.value
					end

					return t.min + (t.max - t.min) * math.clamp((x - p.X) / s.X, 0, 1)
				end

				local function finishDrag()
					if not live then return end

					live = false
					vue.ScrollingEnabled = true
					latch(-1)
					paint()
					glow()
				end

				conn(grab.InputBegan, function(i)
					if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
						return
					end

					if live then
						return
					end

					live = true
					finger = i.UserInputType == Enum.UserInputType.Touch and i or nil

					latch(1)
					glow()

					vue.ScrollingEnabled = false

					visualsui:chime("tap")
					item:set(reach(positionX(i)))
				end)

				local function ours(i)
					if finger then
						return i == finger
					end

					return i.UserInputType == Enum.UserInputType.MouseButton1
				end

				conn(grab.InputEnded, function(i)
					if ours(i) then
						finishDrag()
					end
				end)

				conn(uis.InputChanged, function(i)
					if not live then return end

					if finger then
						if i ~= finger then return end
					elseif i.UserInputType ~= Enum.UserInputType.MouseMovement then
						return
					end

					item:set(reach(positionX(i)))
				end)

				conn(uis.InputEnded, function(i)
					if ours(i) then
						finishDrag()
					end
				end)

				conn(row.MouseEnter, function()
					warm = true

					glow()
				end)

				conn(row.MouseLeave, function()
					warm = false

					glow()
				end)

				item.value = snap(tonumber(t.default) or t.min)

				paint()

				local id = t.flag or (base .. "|" .. t.name)
				local kept = nil
				local bind

				bind = bindpod(row, t.name, vue, keep, {
					id = id,
					art = "sliders-horizontal",
					mode = true,
					value = {
						min = t.min,
						max = t.max,
						step = step,
						dec = dec,
						suffix = t.suffix,
						default = item.value,
					},
					show = function()
						return tag(bind.value)
					end,
					fire = function(v)
						if v then
							if kept == nil then
								kept = item.value
							end

							item:set(bind.value)
						elseif kept ~= nil then
							item:set(kept)

							kept = nil
						end

						bind:lit(kept ~= nil)
					end,
					press = function()
						bind.live = not bind.live

						bind.fire(bind.live)
					end,
					state = function()
						return kept ~= nil
					end,
				})

				item.bind = bind

				local snoop = new("ImageButton", {
					Name = rnd(),
					Size = UDim2.new(1, 0, 0, 15),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					ZIndex = 7,
				}, row)

				local function pop()
					if not bind:flip() then
						return
					end

					visualsui:chime("flip")
				end

				conn(snoop.MouseButton2Click, pop)

				conn(grab.InputBegan, function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton2 then
						pop()
					end
				end)

				visualsui:hook(id, "number", function()
					return item.value
				end, function(v)
					item:set(v)
				end, {min=t.min, max=t.max})

				return item
			end

			function sec:keybind(t)
				t = params(t, {
					name = "keybind",
					default = nil,
					flag = nil,
					callback = nil,
				})

				sec.n += 1

				local nest = host.frame

				local row = new("Frame", {
					Name = rnd(),
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = sec.n,
					ZIndex = 5,
				}, nest)

				local lbl = new("TextLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(5, 0),
					Size = UDim2.new(0.56, -8, 1, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = t.name,
					TextColor3 = th.dim,
					TextSize = 13,
					TextTransparency = 0.35,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 6,
				}, row)

				local pill = new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -5, 0.5, 0),
					Size = UDim2.new(0.42, -5, 0, 21),
					BackgroundColor3 = th.head,
					BackgroundTransparency = 0.12,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					ZIndex = 6,
				}, row)

				round(pill, 6)

				local ring = new("UIStroke", { Color = th.line, Transparency = 0.62 }, pill)

				local nib = new("ImageLabel", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 5, 0.5, 0),
					Size = UDim2.fromOffset(12, 12),
					BackgroundTransparency = 1,
					Image = icon("keyboard"),
					ImageColor3 = th.dim,
					ImageTransparency = 0.3,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 7,
				}, pill)

				local slit = new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0, 22, 0.5, 0),
					Size = UDim2.new(0, 1, 0, 13),
					BackgroundColor3 = th.line,
					BackgroundTransparency = 0.35,
					BorderSizePixel = 0,
					ZIndex = 7,
				}, pill)

				fade(slit, 90, {
					NumberSequenceKeypoint.new(0, 0.85),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(1, 0.85),
				})

				local val = new("TextLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(28, 0),
					Size = UDim2.new(1, -33, 1, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = "None",
					TextColor3 = th.text,
					TextSize = 12,
					TextTransparency = 0.1,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Center,
					ZIndex = 7,
				}, pill)

				local beam = new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.fromScale(0.5, 1),
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = th.accent,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 8,
				}, pill)

				fade(beam, 0, {
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(1, 1),
				})

				local tap = new("ImageButton", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					ZIndex = 9,
				}, row)

				local pin = { row = row, key = nil, live = false }
				local warm = false

				table.insert(seek.rows, { row = row, name = t.name })

				local function show()
					val.Text = pin.live and "..." or keyname(pin.key)
				end

				local function paint()
					anim(pill, soft, { BackgroundTransparency = pin.live and 0 or (warm and 0.04 or 0.12) })
					anim(ring, soft, { Transparency = pin.live and 0.22 or (warm and 0.45 or 0.62) })
					anim(beam, soft, { BackgroundTransparency = pin.live and 0.25 or 1 })
					anim(slit, soft, { BackgroundTransparency = pin.live and 0.1 or 0.35 })
					anim(val, soft, {
						TextTransparency = pin.live and 0 or 0.1,
						TextColor3 = pin.live and th.accent or th.text,
					})
					anim(nib, soft, {
						ImageTransparency = pin.live and 0 or (warm and 0.1 or 0.3),
						ImageColor3 = pin.live and th.accent or th.dim,
					})
					anim(lbl, soft, { TextTransparency = (pin.live or warm) and 0.1 or 0.35 })
				end

				function pin:set(v, quiet)
					local k = v

					if type(k) == "string" then
						k = select(2, pcall(function()
							return Enum.KeyCode[v]
						end))
					end

					if typeof(k) ~= "EnumItem" or k == pin.key then
						return
					end

					pin.key = k

					show()

					if not quiet and t.callback then
						callback(t.callback, k.Name)
					end
				end

				function pin:get()
					return pin.key and pin.key.Name or nil
				end

				local function halt()
					pin.live = false

					show()
					paint()
				end

				conn(tap.MouseButton1Click, function()
					if pin.live then
						capture(nil)

						halt()

						return
					end

					pin.live = true

					show()
					paint()

					visualsui:chime("flip")

					capture(function(k)
						halt()

						if k then
							pin:set(k)

							visualsui:chime("tap")
						end
					end, halt)
				end)

				conn(tap.MouseEnter, function()
					warm = true

					paint()
				end)

				conn(tap.MouseLeave, function()
					warm = false

					paint()
				end)

				pin:set(t.default)

				show()
				paint()

				visualsui:hook(t.flag or (base .. "|" .. t.name), "key", function()
					return pin:get()
				end, function(v)
					pin:set(v)
				end)

				return pin
			end

			function sec:dropdown(t)
				t = params(t, {
					name = "dropdown",
					list = {},
					default = nil,
					flag = nil,
					callback = nil,
				})

				sec.n += 1

				local nest = host.frame

				local wrap = new("Frame", {
					Name = rnd(),
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					LayoutOrder = sec.n,
					ZIndex = 5,
				}, nest)

				local hood = new("Frame", {
					Name = rnd(),
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 5,
				}, wrap)

				local lbl = new("TextLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(5, 0),
					Size = UDim2.new(0.44, -8, 1, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = t.name,
					TextColor3 = th.dim,
					TextSize = 13,
					TextTransparency = 0.35,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 6,
				}, hood)

				local pill = new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -5, 0.5, 0),
					Size = UDim2.new(0.56, -5, 0, 21),
					BackgroundColor3 = th.head,
					BackgroundTransparency = 0.12,
					BorderSizePixel = 0,
					ZIndex = 6,
				}, hood)

				round(pill, 6)

				local ring = new("UIStroke", { Color = th.line, Transparency = 0.62 }, pill)

				local val = new("TextLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(9, 0),
					Size = UDim2.new(1, -27, 1, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = "",
					TextColor3 = th.text,
					TextSize = 12,
					TextTransparency = 0.1,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 7,
				}, pill)

				local caret = new("ImageLabel", {
					Name = rnd(),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -6, 0.5, 0),
					Size = UDim2.fromOffset(11, 11),
					BackgroundTransparency = 1,
					Image = icon("chevron-down"),
					ImageColor3 = th.dim,
					ImageTransparency = 0.3,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 7,
				}, pill)

				local tap = new("ImageButton", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					ZIndex = 9,
				}, hood)

				local cage = new("Frame", {
					Name = rnd(),
					Position = UDim2.fromOffset(5, 28),
					Size = UDim2.new(1, -10, 0, 0),
					BackgroundColor3 = th.bg,
					BackgroundTransparency = 0.28,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					ZIndex = 6,
				}, wrap)

				round(cage, 6)

				new("UIStroke", { Color = th.line, Transparency = 0.74 }, cage)

				local crop = new("Frame", {
					Name = rnd(),
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 6,
				}, cage)

				new("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 1),
				}, crop)

				new("UIPadding", {
					PaddingTop = UDim.new(0, 4),
					PaddingBottom = UDim.new(0, 4),
					PaddingLeft = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 4),
				}, crop)

				local drop = { row = wrap, on = false, pick = nil, leaf = {} }

				table.insert(seek.rows, { row = wrap, name = t.name })

				local function shade(o)
					local sel = drop.pick == o.name

					anim(o.tint, quick, { BackgroundTransparency = sel and 0.12 or (o.warm and 0.5 or 1) })
					anim(o.dot, quick, {
						BackgroundTransparency = sel and 0.05 or 1,
						Size = UDim2.fromOffset(sel and 7 or 4, sel and 7 or 4),
					})
					anim(o.lbl, quick, {
						TextTransparency = sel and 0 or (o.warm and 0.18 or 0.45),
						TextColor3 = sel and th.text or th.dim,
					})
				end

				local function slide()
					local h0 = cage.Size.Y.Offset
					local h1 = drop.on and (asz(crop).Y) or 0
					local w0 = wrap.Size.Y.Offset
					local w1 = 26 + (drop.on and (h1 + 6) or 0)
					local r0 = caret.Rotation
					local r1 = drop.on and 180 or 0

					flow(cage, 0.3, drop.on and outq or inq, function(k)
						cage.Size = UDim2.new(1, -10, 0, math.floor(h0 + (h1 - h0) * k + 0.5))
						wrap.Size = UDim2.new(1, 0, 0, math.floor(w0 + (w1 - w0) * k + 0.5))
					end)

					flow(caret, 0.3, outq, function(k)
						caret.Rotation = r0 + (r1 - r0) * k
					end)

					anim(ring, soft, { Transparency = drop.on and 0.38 or 0.62 })
				end

				function drop:setopen(v)
					drop.on = v and true or false

					slide()
				end

				function drop:set(v, quiet)
					if type(v) ~= "string" or (v == drop.pick and not visualsui.configApplying) then
						return
					end

					if not table.find(t.list, v) then
						return
					end

					drop.pick = v
					val.Text = v

					for _, o in next, drop.leaf do
						shade(o)
					end

					if not quiet and t.callback then
						callback(t.callback, v)
					end
				end

				function drop:get()
					return drop.pick
				end

				for i, name in next, t.list do
					local o = { name = name, warm = false }

					o.head = new("Frame", {
						Name = rnd(),
						Size = UDim2.new(1, 0, 0, 21),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						LayoutOrder = i,
						ZIndex = 6,
					}, crop)

					o.tint = new("Frame", {
						Name = rnd(),
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = th.panel,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ZIndex = 6,
					}, o.head)

					round(o.tint, 5)

					fade(o.tint, 0, {
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(0.7, 0.25),
						NumberSequenceKeypoint.new(1, 0.55),
					})

					o.dot = new("Frame", {
						Name = rnd(),
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 8, 0.5, 0),
						Size = UDim2.fromOffset(4, 4),
						BackgroundColor3 = th.accent,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ZIndex = 7,
					}, o.head)

					new("UICorner", { CornerRadius = UDim.new(1, 0) }, o.dot)

					o.lbl = new("TextLabel", {
						Name = rnd(),
						Position = UDim2.fromOffset(22, 0),
						Size = UDim2.new(1, -30, 1, 0),
						BackgroundTransparency = 1,
						Font = Enum.Font.GothamBold,
						Text = name,
						TextColor3 = th.dim,
						TextSize = 12,
						TextTransparency = 0.45,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 7,
					}, o.head)

					o.btn = new("ImageButton", {
						Name = rnd(),
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						ImageTransparency = 1,
						ZIndex = 8,
					}, o.head)

					conn(o.btn.MouseEnter, function()
						o.warm = true

						shade(o)
					end)

					conn(o.btn.MouseLeave, function()
						o.warm = false

						shade(o)
					end)

					conn(o.btn.MouseButton1Click, function()
						drop:set(o.name)
						drop:setopen(false)

						visualsui:chime("tap")
					end)

					drop.leaf[i] = o
				end

				conn(tap.MouseButton1Click, function()
					drop:setopen(not drop.on)

					visualsui:chime("flip")
				end)

				conn(tap.MouseEnter, function()
					anim(lbl, soft, { TextTransparency = 0.1 })
					anim(caret, soft, { ImageTransparency = 0.05 })
					anim(pill, soft, { BackgroundTransparency = 0 })
				end)

				conn(tap.MouseLeave, function()
					anim(lbl, soft, { TextTransparency = 0.35 })
					anim(caret, soft, { ImageTransparency = 0.3 })
					anim(pill, soft, { BackgroundTransparency = 0.12 })
				end)

				drop:set(t.default or t.list[1])

				visualsui:hook(t.flag or (base .. "|" .. t.name), "list", function()
					return drop.pick
				end, function(v)
					drop:set(v)
				end, {validate=function(v) return table.find(t.list, v) ~= nil end})

				return drop
			end

			function sec:combo(t)
				t = params(t, {
					name = "combo",
					list = {},
					default = nil,
					max = 8,
					multi = false,
					flag = nil,
					callback = nil,
				})

				sec.n += 1

				local nest, vue, keep = host.frame, host.va, host.vb
				local pitch = 27
				local cap = math.max(math.floor(tonumber(t.max) or 8), 1)

				local row = new("Frame", {
					Name = rnd(),
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = sec.n,
					ZIndex = 5,
				}, nest)

				local lbl = new("TextLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(5, 0),
					Size = UDim2.new(0.42, -8, 1, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = t.name,
					TextColor3 = th.dim,
					TextSize = 13,
					TextTransparency = 0.35,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 6,
				}, row)

				local pill = new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -5, 0.5, 0),
					Size = UDim2.new(0.58, -5, 0, 22),
					BackgroundColor3 = th.head,
					BackgroundTransparency = 0.12,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					ZIndex = 6,
				}, row)

				round(pill, 6)

				local ring = new("UIStroke", { Color = th.line, Transparency = 0.62 }, pill)

				local val = new("TextLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(9, 0),
					Size = UDim2.new(1, -28, 1, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = "",
					TextColor3 = th.text,
					TextSize = 12,
					TextTransparency = 0.1,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 7,
				}, pill)

				local beam = new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.fromScale(0.5, 1),
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = th.accent,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 9,
				}, pill)

				fade(beam, 0, {
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(1, 1),
				})

				local caret = new("ImageLabel", {
					Name = rnd(),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -7, 0.5, 0),
					Size = UDim2.fromOffset(12, 12),
					BackgroundTransparency = 1,
					Image = icon("chevron-down"),
					ImageColor3 = th.dim,
					ImageTransparency = 0.3,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 7,
				}, pill)

				local tap = new("ImageButton", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					ZIndex = 10,
				}, pill)

				local veil = new("ImageButton", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					Visible = false,
					ZIndex = 29,
				}, root)

				local pit = native and new("Frame", {
					Name = rnd(),
					Size = UDim2.fromOffset(0, 0),
					BackgroundColor3 = th.panel,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 30,
				}, root) or nil

				local cast = pit and new("UIShadow", {
					Color = th.bg,
					BlurRadius = UDim.new(0, 16),
					Offset = UDim2.fromOffset(0, 5),
					Spread = UDim2.fromOffset(-3, -3),
					Transparency = 1,
					ZIndex = -1,
				}, pit) or nil

				if pit then
					round(pit, 8)
				end

				local hull = new("CanvasGroup", {
					Name = rnd(),
					Size = UDim2.fromOffset(0, 0),
					BackgroundColor3 = th.panel,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					GroupTransparency = 1,
					Visible = false,
					ZIndex = 31,
				}, root)

				round(hull, 8)

				new("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(178, 178, 190)),
					}),
				}, hull)

				new("ImageButton", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					ZIndex = 1,
				}, hull)

				local brim = new("Frame", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 40,
				}, hull)

				round(brim, 8)

				new("UIStroke", { Color = th.line, Transparency = 0.6 }, brim)

				local roll = new("ScrollingFrame", {
					Name = rnd(),
					Active = false,
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					CanvasSize = UDim2.new(),
					ScrollBarThickness = 0,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ZIndex = 32,
				}, hull)

				local lay = new("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 2),
				}, roll)

				new("UIPadding", {
					PaddingTop = UDim.new(0, 6),
					PaddingBottom = UDim.new(0, 6),
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
				}, roll)

				local drop = { row = row, on = false, pick = nil, tick = {}, leaf = {}, up = false, w = 0, h = 0 }
				local warm, cue = false, 0

				table.insert(seek.rows, { row = row, name = t.name })

				local function hot(name)
					if t.multi then
						return drop.tick[name] == true
					end

					return drop.pick == name
				end

				local function chosen()
					local out = {}

					for i = 1, #t.list do
						if drop.tick[t.list[i]] then
							table.insert(out, t.list[i])
						end
					end

					return out
				end

				local function shade(o, snap)
					local sel = hot(o.name)
					local aim = o.warm or drop.leaf[cue] == o
					local tw = snap and quick or soft

					anim(o.head, tw, { BackgroundTransparency = sel and 0.08 or (aim and 0.4 or 1) })
					anim(o.edge, tw, { Transparency = sel and 0.7 or 1 })
					anim(o.tint, tw, { BackgroundTransparency = sel and 0.86 or 1 })
					anim(o.bar, tw, {
						Size = UDim2.new(0, 3, 0, sel and 13 or 0),
						BackgroundTransparency = sel and 0.05 or 1,
					})
					anim(o.lbl, tw, {
						TextTransparency = sel and 0 or (aim and 0.15 or 0.45),
						TextColor3 = sel and th.text or th.dim,
					})

					if t.multi then
						anim(o.knob, tw, { BackgroundTransparency = sel and 0.05 or 1 })
						anim(o.pin, tw, { Transparency = sel and 1 or (aim and 0.05 or 0.3) })
						anim(o.nod, tw, {
							ImageTransparency = sel and 0 or 1,
							Size = UDim2.fromOffset(sel and 10 or 4, sel and 10 or 4),
						})
					else
						anim(o.mark, tw, {
							ImageTransparency = sel and 0 or 1,
							Size = UDim2.fromOffset(sel and 12 or 7, sel and 12 or 7),
						})
					end
				end

				local function show()
					if not t.multi then
						val.Text = drop.pick or "None"

						return
					end

					local out = chosen()

					val.Text = #out > 0 and table.concat(out, ", ") or "None"
				end

				local function paint()
					anim(pill, soft, { BackgroundTransparency = (drop.on or warm) and 0 or 0.12 })
					anim(ring, soft, { Transparency = drop.on and 0.3 or (warm and 0.45 or 0.62) })
					anim(beam, soft, { BackgroundTransparency = drop.on and 0.2 or 1 })
					anim(lbl, soft, { TextTransparency = (drop.on or warm) and 0.1 or 0.35 })
					anim(caret, soft, {
						ImageTransparency = (drop.on or warm) and 0.05 or 0.3,
						ImageColor3 = drop.on and th.text or th.dim,
					})
				end

				local function repaint()
					show()

					for i = 1, #drop.leaf do
						shade(drop.leaf[i], true)
					end
				end

				local function tallness()
					return math.clamp(#drop.leaf, 1, cap) * pitch + 10
				end

				local function wideness()
					local wide = 0

					for i = 1, #t.list do
						local ok, sz = pcall(function()
							return txs:GetTextSize(t.list[i], 12, Enum.Font.GothamBold, Vector2.new(4096, 24))
						end)

						if ok and sz then
							wide = math.max(wide, sz.X)
						end
					end

					return math.ceil(wide) + (t.multi and 56 or 52)
				end

				local function place()
					local rp, rz = apos(root), asz(root)
					local pp, ps = apos(pill), asz(pill)
					local x = pp.X - rp.X
					local y = drop.up and (pp.Y - rp.Y - 6) or (pp.Y - rp.Y + ps.Y + 6)

					if x + drop.w > rz.X - 8 then
						x = math.max(8, pp.X - rp.X + ps.X - drop.w)
					end

					hull.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))

					if pit then
						pit.Position = hull.Position
					end
				end

				local function refit()
					drop.h = tallness()

					hull.Size = UDim2.fromOffset(drop.w, drop.h)

					if pit then
						pit.Size = hull.Size
					end

					place()
				end

				local function slide()
					local from = hull.GroupTransparency
					local to = drop.on and 0 or 1
					local r0, r1 = caret.Rotation, drop.on and 180 or 0

					flow(hull, drop.on and 0.34 or 0.26, drop.on and outq or inq, function(k)
						local a = from + (to - from) * k

						hull.GroupTransparency = a

						if pit then
							pit.BackgroundTransparency = a
							cast.Transparency = 0.35 + 0.65 * a
						end

						if k >= 1 then
							hull.Visible = drop.on

							if pit then
								pit.Visible = drop.on
							end
						end
					end)

					flow(caret, 0.3, outq, function(k)
						caret.Rotation = r0 + (r1 - r0) * k
					end)
				end

				local function reveal(o)
					local view = roll.AbsoluteWindowSize.Y / sc
					local full = acs(lay).Y + 12
					local idx = table.find(drop.leaf, o)

					if not idx or view <= 0 or full <= view then
						return
					end

					local y = 6 + (idx - 1) * pitch
					local at = roll.CanvasPosition.Y

					if y < at then
						roll.CanvasPosition = Vector2.new(0, math.max(y - 6, 0))
					elseif y + 25 > at + view then
						roll.CanvasPosition = Vector2.new(0, y + 31 - view)
					end
				end

				local function mark(i)
					local was = drop.leaf[cue]

					cue = i

					if was then
						shade(was, true)
					end

					local now = drop.leaf[cue]

					if now then
						shade(now, true)
						reveal(now)
					end
				end

				local function nudge(d)
					if #drop.leaf == 0 then
						return
					end

					local i = cue + d

					if i < 1 then
						i = #drop.leaf
					elseif i > #drop.leaf then
						i = 1
					end

					mark(i)

					visualsui:chime("tap")
				end

				local function commit(o)
					if not o then
						return
					end

					if t.multi then
						drop.tick[o.name] = not drop.tick[o.name] or nil

						repaint()

						visualsui:chime(drop.tick[o.name] and "on" or "off")

						if t.callback then
							callback(t.callback, drop:get())
						end

						return
					end

					drop:set(o.name)
					drop:setopen(false)

					visualsui:chime("tap")
				end

				local function build()
					for i = 1, #drop.leaf do
						local o = drop.leaf[i]

						for _, c in next, o.cx do
							c:Disconnect()
						end

						o.head:Destroy()
					end

					table.clear(drop.leaf)

					local lead = t.multi and 30 or 11
					local trail = t.multi and 10 or 28

					for i = 1, #t.list do
						local name = t.list[i]
						local o = { name = name, warm = false, cx = {} }

						o.head = new("Frame", {
							Name = rnd(),
							Size = UDim2.new(1, 0, 0, 25),
							BackgroundColor3 = th.head,
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							LayoutOrder = i,
							ZIndex = 32,
						}, roll)

						round(o.head, 6)

						o.edge = new("UIStroke", { Color = th.line, Transparency = 1 }, o.head)

						o.tint = new("Frame", {
							Name = rnd(),
							Size = UDim2.fromScale(1, 1),
							BackgroundColor3 = th.accent,
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							ZIndex = 32,
						}, o.head)

						round(o.tint, 6)

						fade(o.tint, 0, {
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(0.55, 0.62),
							NumberSequenceKeypoint.new(1, 1),
						})

						o.bar = new("Frame", {
							Name = rnd(),
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(0, 1, 0.5, 0),
							Size = UDim2.new(0, 3, 0, 0),
							BackgroundColor3 = th.accent,
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							ZIndex = 33,
						}, o.head)

						new("UICorner", { CornerRadius = UDim.new(1, 0) }, o.bar)

						if t.multi then
							o.knob = new("Frame", {
								Name = rnd(),
								AnchorPoint = Vector2.new(0, 0.5),
								Position = UDim2.new(0, 9, 0.5, 0),
								Size = UDim2.fromOffset(14, 14),
								BackgroundColor3 = th.accent,
								BackgroundTransparency = 1,
								BorderSizePixel = 0,
								ZIndex = 33,
							}, o.head)

							round(o.knob, 4)

							o.pin = new("UIStroke", { Color = th.line, Transparency = 0.3 }, o.knob)

							o.nod = new("ImageLabel", {
								Name = rnd(),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.fromScale(0.5, 0.5),
								Size = UDim2.fromOffset(4, 4),
								BackgroundTransparency = 1,
								Image = icon("check"),
								ImageColor3 = th.bg,
								ImageTransparency = 1,
								ScaleType = Enum.ScaleType.Fit,
								ZIndex = 34,
							}, o.knob)
						else
							o.mark = new("ImageLabel", {
								Name = rnd(),
								AnchorPoint = Vector2.new(1, 0.5),
								Position = UDim2.new(1, -9, 0.5, 0),
								Size = UDim2.fromOffset(7, 7),
								BackgroundTransparency = 1,
								Image = icon("check"),
								ImageColor3 = th.accent,
								ImageTransparency = 1,
								ScaleType = Enum.ScaleType.Fit,
								ZIndex = 33,
							}, o.head)
						end

						o.lbl = new("TextLabel", {
							Name = rnd(),
							Position = UDim2.fromOffset(lead, 0),
							Size = UDim2.new(1, -lead - trail, 1, 0),
							BackgroundTransparency = 1,
							Font = Enum.Font.GothamBold,
							Text = name,
							TextColor3 = th.dim,
							TextSize = 12,
							TextTransparency = 0.45,
							TextTruncate = Enum.TextTruncate.AtEnd,
							TextXAlignment = Enum.TextXAlignment.Left,
							ZIndex = 33,
						}, o.head)

						o.btn = new("ImageButton", {
							Name = rnd(),
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							ImageTransparency = 1,
							ZIndex = 34,
						}, o.head)

						table.insert(o.cx, o.btn.MouseEnter:Connect(function()
							local was = drop.leaf[cue]

							o.warm = true
							cue = 0

							if was and was ~= o then
								shade(was, true)
							end

							shade(o, true)
						end))

						table.insert(o.cx, o.btn.MouseLeave:Connect(function()
							o.warm = false

							shade(o, true)
						end))

						table.insert(o.cx, o.btn.MouseButton1Click:Connect(function()
							commit(o)
						end))

						drop.leaf[i] = o

						shade(o, true)
					end
				end

				local track, ears = nil, nil

				local function untrack()
					if track then
						track:Disconnect()
						track = nil
					end
				end

				local function unears()
					if ears then
						ears:Disconnect()
						ears = nil
					end
				end

				local function shut()
					drop:setopen(false)
				end

				local function follow()
					if locks > 0 then
						place()

						return
					end

					if not win.open or not pg.Visible or not row.Visible then
						shut()

						return
					end

					local vp, vs = vue.AbsolutePosition, vue.AbsoluteSize
					local hp, hs = keep.AbsolutePosition, keep.AbsoluteSize
					local pp, ps = pill.AbsolutePosition, pill.AbsoluteSize
					local mid = pp.Y + ps.Y * 0.5

					if mid < vp.Y or mid > vp.Y + vs.Y or mid < hp.Y or mid > hp.Y + hs.Y then
						shut()

						return
					end

					place()
				end

				local function pilot(i)
					if visualsui.capturing or i.UserInputType ~= Enum.UserInputType.Keyboard then
						return
					end

					local k = i.KeyCode

					if k == Enum.KeyCode.Down then
						nudge(1)
					elseif k == Enum.KeyCode.Up then
						nudge(-1)
					elseif k == Enum.KeyCode.Return or k == Enum.KeyCode.KeypadEnter then
						commit(drop.leaf[cue])
					elseif k == Enum.KeyCode.Escape then
						shut()
					end
				end

				function drop:setopen(v)
					v = v and true or false

					if drop.on == v then
						return
					end

					drop.on = v

					if v then
						sink()

						local rp, rz = apos(root), asz(root)
						local pp, ps = apos(pill), asz(pill)

						drop.w = math.clamp(
							math.max(wideness(), math.floor(ps.X + 0.5)),
							130,
							math.max(math.floor(rz.X) - 16, 130)
						)
						drop.h = tallness()

						local under = rz.Y - (pp.Y - rp.Y + ps.Y + 6) - 6
						local over = pp.Y - rp.Y - 12

						drop.up = under < drop.h and over > under

						hull.AnchorPoint = Vector2.new(0, drop.up and 1 or 0)
						hull.Visible = true
						veil.Visible = true
						roll.CanvasPosition = Vector2.new()

						if pit then
							pit.AnchorPoint = hull.AnchorPoint
							pit.Visible = true
						end

						refit()
						repaint()

						if not t.multi then
							for i = 1, #drop.leaf do
								if drop.leaf[i].name == drop.pick then
									cue = i

									shade(drop.leaf[i], true)
									reveal(drop.leaf[i])

									break
								end
							end
						end

						sky = shut
						skyzone = hull

						untrack()
						unears()

						track = rs.RenderStepped:Connect(follow)
						ears = uis.InputBegan:Connect(pilot)
					else
						untrack()
						unears()

						veil.Visible = false
						cue = 0

						if sky == shut then
							sky = nil
							skyzone = nil
						end

						for i = 1, #drop.leaf do
							drop.leaf[i].warm = false

							shade(drop.leaf[i], true)
						end
					end

					paint()
					slide()
				end

				function drop:get()
					if not t.multi then
						return drop.pick
					end

					return chosen()
				end

				function drop:set(v, quiet)
					if t.multi then
						local want = {}

						if type(v) == "table" then
							for _, n in next, v do
								want[n] = true
							end
						elseif type(v) == "string" then
							for n in string.gmatch(v, "[^,]+") do
								want[string.match(n, "^%s*(.-)%s*$")] = true
							end
						else
							return
						end

						table.clear(drop.tick)

						for i = 1, #t.list do
							if want[t.list[i]] then
								drop.tick[t.list[i]] = true
							end
						end

						repaint()

						if not quiet and t.callback then
							callback(t.callback, drop:get())
						end

						return
					end

					if type(v) ~= "string" or (v == drop.pick and not visualsui.configApplying) or not table.find(t.list, v) then
						return
					end

					drop.pick = v

					repaint()

					if not quiet and t.callback then
						callback(t.callback, v)
					end
				end

				function drop:setlist(ls)
					if type(ls) ~= "table" then
						return
					end

					local held = t.multi and drop:get() or drop.pick

					t.list = ls
					drop.pick = nil

					table.clear(drop.tick)
					build()

					if t.multi then
						drop:set(held, true)
					elseif held and table.find(ls, held) then
						drop:set(held, true)
					else
						drop:set(ls[1], true)
					end

					show()

					if not drop.on then
						return
					end

					if #ls == 0 then
						shut()

						return
					end

					refit()
				end

				conn(lay:GetPropertyChangedSignal("AbsoluteContentSize"), function()
					roll.CanvasSize = UDim2.fromOffset(0, acs(lay).Y + 12)
				end)

				conn(veil.MouseButton1Click, shut)

				conn(tap.MouseButton1Click, function()
					if #t.list == 0 then
						return
					end

					drop:setopen(not drop.on)

					visualsui:chime("flip")
				end)

				conn(tap.MouseEnter, function()
					warm = true

					paint()
				end)

				conn(tap.MouseLeave, function()
					warm = false

					paint()
				end)

				build()

				if t.multi then
					if t.default ~= nil then
						drop:set(t.default)
					end
				else
					drop:set(t.default or t.list[1])
				end

				show()
				paint()

				visualsui:hook(t.flag or (base .. "|" .. t.name), "list", function()
					if t.multi then
						return table.concat(drop:get(), ", ")
					end

					return drop.pick
				end, function(v)
					drop:set(v)
				end, {validate=function(v)
					if not t.multi then return table.find(t.list, v) ~= nil end
					for name in string.gmatch(v, "[^,]+") do
						if not table.find(t.list, string.match(name, "^%s*(.-)%s*$")) then return false end
					end
					return true
				end})

				return drop
			end

			function sec:button(t)
				t = params(t, {
					name = "button",
					icon = nil,
					flag = nil,
					callback = nil,
				})

				sec.n += 1

				local nest, vue, keep = host.frame, host.va, host.vb

				local row = new("Frame", {
					Name = rnd(),
					Size = UDim2.new(1, 0, 0, 28),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = sec.n,
					ZIndex = 5,
				}, nest)

				local slab = new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(1, -10, 0, 24),
					BackgroundColor3 = th.head,
					BackgroundTransparency = 0.12,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					ZIndex = 6,
				}, row)

				round(slab, 6)

				local ring = new("UIStroke", { Color = th.line, Transparency = 0.62 }, slab)

				local wash = new("Frame", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = th.accent,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 6,
				}, slab)

				round(wash, 6)

				fade(wash, 0, {
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.55, 0.62),
					NumberSequenceKeypoint.new(1, 1),
				})

				local art = t.icon and new("ImageLabel", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 9, 0.5, 0),
					Size = UDim2.fromOffset(13, 13),
					BackgroundTransparency = 1,
					Image = icon(t.icon),
					ImageColor3 = th.dim,
					ImageTransparency = 0.25,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 7,
				}, slab) or nil

				local lbl = new("TextLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(t.icon and 27 or 9, 0),
					Size = UDim2.new(1, t.icon and -36 or -18, 1, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = t.name,
					TextColor3 = th.dim,
					TextSize = 13,
					TextTransparency = 0.25,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = t.icon and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
					ZIndex = 7,
				}, slab)

				local beam = new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.fromScale(0.5, 1),
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = th.accent,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 8,
				}, slab)

				fade(beam, 0, {
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(1, 1),
				})

				local tap = new("ImageButton", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					ZIndex = 9,
				}, slab)

				table.insert(seek.rows, { row = row, name = t.name })

				local item = { row = row }
				local warm = false

				local function glow()
					anim(slab, soft, { BackgroundTransparency = warm and 0 or 0.12 })
					anim(ring, soft, { Transparency = warm and 0.4 or 0.62 })
					anim(wash, soft, { BackgroundTransparency = warm and 0.88 or 1 })
					anim(lbl, soft, {
						TextTransparency = warm and 0 or 0.25,
						TextColor3 = warm and th.text or th.dim,
					})

					if art then
						anim(art, soft, {
							ImageTransparency = warm and 0 or 0.25,
							ImageColor3 = warm and th.text or th.dim,
						})
					end
				end

				function item:fire()
					wash.BackgroundTransparency = 0.72
					beam.BackgroundTransparency = 0.15

					anim(wash, soft, { BackgroundTransparency = warm and 0.88 or 1 })
					anim(beam, soft, { BackgroundTransparency = 1 })

					visualsui:chime("tap")

					if t.callback then
						callback(t.callback)
					end
				end

				conn(tap.MouseButton1Click, function()
					item:fire()
				end)

				conn(tap.MouseEnter, function()
					warm = true

					glow()
				end)

				conn(tap.MouseLeave, function()
					warm = false

					glow()
				end)

				local bind = bindpod(row, t.name, vue, keep, {
					id = t.flag or (base .. "|" .. t.name),
					art = nil,
					mode = false,
					fire = function(v)
						if v then
							item:fire()
						end
					end,
				})

				item.bind = bind

				conn(tap.MouseButton2Click, function()
					if not bind:flip() then
						return
					end

					visualsui:chime("flip")
				end)

				glow()

				return item
			end

			function sec:label(t)
				if type(t) == "string" then
					t = { name = t }
				end

				t = params(t, {
					name = "label",
					icon = nil,
					wrap = false,
					tone = nil,
				})

				sec.n += 1

				local nest = host.frame

				local row = new("Frame", {
					Name = rnd(),
					Size = t.wrap and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 0, 22),
					AutomaticSize = t.wrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = sec.n,
					ZIndex = 5,
				}, nest)

				table.insert(seek.rows, { row = row, name = t.name })

				local lead = 5

				if t.icon then
					lead = 24

					new("ImageLabel", {
						Name = rnd(),
						AnchorPoint = Vector2.new(0, 0),
						Position = UDim2.fromOffset(5, 5),
						Size = UDim2.fromOffset(12, 12),
						BackgroundTransparency = 1,
						Image = icon(t.icon),
						ImageColor3 = th.dim,
						ImageTransparency = 0.3,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 6,
					}, row)
				end

				local lbl = new("TextLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(lead, 0),
					Size = t.wrap and UDim2.new(1, -(lead + 8), 0, 0) or UDim2.new(1, -(lead + 8), 1, 0),
					AutomaticSize = t.wrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = tostring(t.name),
					TextColor3 = t.tone or th.dim,
					TextSize = 12,
					TextTransparency = 0.15,
					TextTruncate = (not t.wrap) and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None,
					TextWrapped = t.wrap and true or false,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = t.wrap and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
					ZIndex = 6,
				}, row)

				if t.wrap then
					new("UIPadding", {
						PaddingTop = UDim.new(0, 4),
						PaddingBottom = UDim.new(0, 4),
					}, row)
				end

				local item = { row = row, text = lbl }

				function item:set(v)
					lbl.Text = tostring(v)
				end

				function item:get()
					return lbl.Text
				end

				function item:settone(c)
					if typeof(c) == "Color3" then
						lbl.TextColor3 = c
					end
				end

				return item
			end

			function sec:color(t)
				t = params(t, {
					name = "color",
					default = th.accent,
					flag = nil,
					callback = nil,
				})

				if t.key and typeof(th[t.key]) == "Color3" then
					local hook = t.callback

					t.default = th[t.key]

					t.callback = function(c)
						visualsui:recolor(t.key, c)

						if hook then
							hook(c)
						end
					end
				end

				sec.n += 1

				local nest, vue, keep = host.frame, host.va, host.vb
				local wide, tall = 178, 178

				local row = new("Frame", {
					Name = rnd(),
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = sec.n,
					ZIndex = 5,
				}, nest)

				local lbl = new("TextLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(5, 0),
					Size = UDim2.new(1, -42, 1, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = t.name,
					TextColor3 = th.dim,
					TextSize = 13,
					TextTransparency = 0.35,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 6,
				}, row)

				local swatch = new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -5, 0.5, 0),
					Size = UDim2.fromOffset(26, 16),
					BackgroundColor3 = t.default,
					BorderSizePixel = 0,
					ZIndex = 6,
				}, row)

				round(swatch, 4)

				local ring = new("UIStroke", { Color = th.line, Transparency = 0.25 }, swatch)

				local sheen = new("Frame", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 7,
				}, swatch)

				round(sheen, 4)

				fade(sheen, 90, {
					NumberSequenceKeypoint.new(0, 0.72),
					NumberSequenceKeypoint.new(1, 1),
				})

				local tap = new("ImageButton", {
					Name = rnd(),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -3, 0.5, 0),
					Size = UDim2.fromOffset(32, 22),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					ZIndex = 9,
				}, row)

				local veil = new("ImageButton", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					Visible = false,
					ZIndex = 29,
				}, root)

				local pit = native and new("Frame", {
					Name = rnd(),
					Size = UDim2.fromOffset(0, 0),
					BackgroundColor3 = th.panel,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 30,
				}, root) or nil

				local cast = pit and new("UIShadow", {
					Color = th.bg,
					BlurRadius = UDim.new(0, 16),
					Offset = UDim2.fromOffset(0, 5),
					Spread = UDim2.fromOffset(-3, -3),
					Transparency = 1,
					ZIndex = -1,
				}, pit) or nil

				if pit then
					round(pit, 8)
				end

				local hull = new("CanvasGroup", {
					Name = rnd(),
					Size = UDim2.fromOffset(0, 0),
					BackgroundColor3 = th.panel,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					GroupTransparency = 1,
					Visible = false,
					ZIndex = 31,
				}, root)

				round(hull, 8)

				new("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(178, 178, 190)),
					}),
				}, hull)

				new("ImageButton", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					ZIndex = 1,
				}, hull)

				local brim = new("Frame", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 40,
				}, hull)

				round(brim, 8)

				new("UIStroke", { Color = th.line, Transparency = 0.6 }, brim)

				local sv = new("Frame", {
					Name = rnd(),
					Active = true,
					Position = UDim2.fromOffset(10, 10),
					Size = UDim2.new(1, -20, 0, 110),
					BackgroundColor3 = Color3.fromHSV(0, 1, 1),
					BorderSizePixel = 0,
					ZIndex = 32,
				}, hull)

				round(sv, 6)

				local tintw = new("Frame", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					ZIndex = 33,
				}, sv)

				round(tintw, 6)

				new("UIGradient", {
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}, tintw)

				local tintb = new("Frame", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.new(),
					BorderSizePixel = 0,
					ZIndex = 33,
				}, sv)

				round(tintb, 6)

				new("UIGradient", {
					Color = ColorSequence.new(Color3.new()),
					Rotation = 90,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(1, 0),
					}),
				}, tintb)

				new("UIStroke", { Color = th.panel, Thickness = 1.5 }, sv)

				local dot = new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(9, 9),
					BackgroundColor3 = th.accent,
					BorderSizePixel = 0,
					ZIndex = 34,
				}, sv)

				new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
				new("UIStroke", { Color = th.bg, Transparency = 0.25 }, dot)

				local bar = new("Frame", {
					Name = rnd(),
					Active = true,
					Position = UDim2.fromOffset(10, 128),
					Size = UDim2.new(1, -20, 0, 10),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					ZIndex = 32,
				}, hull)

				round(bar, 5)

				new("UIStroke", { Color = th.panel, Thickness = 1.5 }, bar)

				local keys = {}

				for i = 0, 6 do
					table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
				end

				new("UIGradient", { Color = ColorSequence.new(keys) }, bar)

				local pin = new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0, 0.5),
					Size = UDim2.fromOffset(4, 16),
					BackgroundColor3 = th.accent,
					BorderSizePixel = 0,
					ZIndex = 34,
				}, bar)

				new("UICorner", { CornerRadius = UDim.new(1, 0) }, pin)
				new("UIStroke", { Color = th.bg, Transparency = 0.25 }, pin)

				local field = new("TextBox", {
					Name = rnd(),
					Position = UDim2.fromOffset(10, 146),
					Size = UDim2.new(1, -78, 0, 22),
					BackgroundColor3 = th.head,
					BorderSizePixel = 0,
					ClearTextOnFocus = false,
					ClipsDescendants = true,
					Font = Enum.Font.GothamBold,
					Text = hexof(t.default),
					TextColor3 = th.text,
					TextSize = 13,
					ZIndex = 32,
				}, hull)

				round(field, 5)

				local hem = new("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = th.line,
					Transparency = 0.65,
				}, field)

				local function nib(x, art)
					local b = new("ImageButton", {
						Name = rnd(),
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.new(1, x, 0, 147),
						Size = UDim2.fromOffset(20, 20),
						BackgroundColor3 = th.head,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Image = icon(art),
						ImageColor3 = th.dim,
						ImageTransparency = 0.25,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 32,
					}, hull)

					round(b, 5)

					conn(b.MouseEnter, function()
						anim(b, soft, { ImageTransparency = 0, ImageColor3 = th.text, BackgroundTransparency = 0.4 })
					end)

					conn(b.MouseLeave, function()
						anim(b, soft, { ImageTransparency = 0.25, ImageColor3 = th.dim, BackgroundTransparency = 1 })
					end)

					return b
				end

				local copier = nib(-34, "copy")
				local paster = nib(-10, "clipboard-paste")

				local item = { row = row, on = false, color = t.default, up = false }
				local st = { h = 0, s = 1, v = 1, hold = false, drag = nil }
				local warm = false
				local pendingColor = nil
				local callbackQueued = false
				local colorSerial = 0

				local function queueCallback(c)
					if not t.callback then
						return
					end
					if visualsui.configApplying then
						colorSerial += 1
						pendingColor, callbackQueued = nil, false
						callback(t.callback, c)
						return
					end

					pendingColor = c

					if callbackQueued then
						return
					end

					callbackQueued = true
					colorSerial += 1
					local serial, epoch = colorSerial, visualsui.applyEpoch

					task.delay(0.05, function()
						if serial ~= colorSerial then return end
						local value = pendingColor

						pendingColor = nil
						callbackQueued = false

						if value and visualsui.alive and epoch == visualsui.applyEpoch then
							callback(t.callback, value)
						end
					end)
				end

				table.insert(seek.rows, { row = row, name = t.name })

				st.h, st.s, st.v = Color3.toHSV(t.default)

				local function glow()
					anim(ring, soft, { Transparency = (item.on or warm) and 0 or 0.25 })
					anim(lbl, soft, { TextTransparency = (item.on or warm) and 0.1 or 0.35 })
					anim(swatch, soft, {
						Size = UDim2.fromOffset((item.on or warm) and 28 or 26, (item.on or warm) and 17 or 16),
					})
				end

				local function paint(fire, snap)
					local c = Color3.fromHSV(st.h, st.s, st.v)
					local spot = UDim2.fromScale(st.s, 1 - st.v)
					local seat = UDim2.new(st.h, 0, 0.5, 0)

					if snap then
						dot.Position = spot
						pin.Position = seat
						dot.BackgroundColor3 = c
						sv.BackgroundColor3 = Color3.fromHSV(st.h, 1, 1)
						swatch.BackgroundColor3 = c
					else
						anim(dot, quick, { Position = spot, BackgroundColor3 = c })
						anim(pin, quick, { Position = seat })
						anim(sv, quick, { BackgroundColor3 = Color3.fromHSV(st.h, 1, 1) })
						anim(swatch, quick, { BackgroundColor3 = c })
					end

					if not field:IsFocused() then
						field.Text = hexof(c)
					end

					item.color = c

					if fire then
						queueCallback(c)
					end
				end

				local function place()
					local rp, rz = apos(root), asz(root)
					local sp, ss = apos(swatch), asz(swatch)
					local x = sp.X - rp.X + ss.X - wide
					local y = item.up and (sp.Y - rp.Y - 6) or (sp.Y - rp.Y + ss.Y + 6)

					if x + wide > rz.X - 8 then
						x = rz.X - 8 - wide
					end

					hull.Position = UDim2.fromOffset(math.floor(math.max(x, 8) + 0.5), math.floor(y + 0.5))

					if pit then
						pit.Position = hull.Position
					end
				end

				local function slide()
					local from = hull.GroupTransparency
					local to = item.on and 0 or 1

					flow(hull, item.on and 0.34 or 0.26, item.on and outq or inq, function(k)
						local a = from + (to - from) * k

						hull.GroupTransparency = a

						if pit then
							pit.BackgroundTransparency = a
							cast.Transparency = 0.35 + 0.65 * a
						end

						if k >= 1 then
							hull.Visible = item.on

							if pit then
								pit.Visible = item.on
							end
						end
					end)
				end

				local track = nil

				local function untrack()
					if track then
						track:Disconnect()
						track = nil
					end
				end

				local function shut()
					if locks > 0 then
						return
					end

					item:setopen(false)
				end

				local function follow()
					if locks > 0 then
						place()

						return
					end

					if not win.open or not pg.Visible or not row.Visible then
						item:setopen(false)

						return
					end

					local vp, vs = vue.AbsolutePosition, vue.AbsoluteSize
					local hp, hs = keep.AbsolutePosition, keep.AbsoluteSize
					local sp, ss = swatch.AbsolutePosition, swatch.AbsoluteSize
					local mid = sp.Y + ss.Y * 0.5

					if mid < vp.Y or mid > vp.Y + vs.Y or mid < hp.Y or mid > hp.Y + hs.Y then
						item:setopen(false)

						return
					end

					place()
				end

				function item:setopen(v)
					v = v and true or false

					if item.on == v then
						return
					end

					item.on = v

					if v then
						sink()

						local rp, rz = apos(root), asz(root)
						local sp, ss = apos(swatch), asz(swatch)
						local under = rz.Y - (sp.Y - rp.Y + ss.Y + 6) - 6
						local over = sp.Y - rp.Y - 12

						item.up = under < tall and over > under

						hull.AnchorPoint = Vector2.new(0, item.up and 1 or 0)
						hull.Size = UDim2.fromOffset(wide, tall)
						hull.Visible = true
						veil.Visible = true

						if pit then
							pit.AnchorPoint = hull.AnchorPoint
							pit.Size = hull.Size
							pit.Visible = true
						end

						place()

						sky = shut
						skyzone = hull

						untrack()

						track = rs.RenderStepped:Connect(follow)
					else
						untrack()

						veil.Visible = false

						if sky == shut then
							sky = nil
							skyzone = nil
						end

						if field:IsFocused() then
							field:ReleaseFocus()
						end
					end

					glow()
					slide()
				end

				function item:set(c)
					if typeof(c) == "string" then
						c = fromhex(c)
					end

					if typeof(c) ~= "Color3" then
						return
					end

					st.h, st.s, st.v = Color3.toHSV(c)

					paint(true)
				end

				function item:get()
					return item.color
				end

				local function releaseDrag()
					if not st.hold then
						return
					end

					st.hold = false
					st.drag = nil
					vue.ScrollingEnabled = true
					latch(-1)
				end

				local function updateDrag()
					if st.hold and st.drag then
						local ok, err = pcall(function() st.drag(); paint(true, true) end)
						if not ok then releaseDrag(); warn("[visuals] color drag: " .. tostring(err)) end
					end
				end

				local function graze(frame, apply)
					conn(frame.Destroying, releaseDrag)
					conn(frame.InputBegan, function(i)
						if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
							return
						end

						if st.hold then
							return
						end

						st.hold = true
						st.drag = apply
						st.input = i

						latch(1)

 						vue.ScrollingEnabled = false
						updateDrag()
					end)

					conn(frame.InputEnded, function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 or (i.UserInputType == Enum.UserInputType.Touch and i == st.input) then
							releaseDrag()
						end
					end)
				end

				graze(sv, function()
					local p, s = sv.AbsolutePosition, sv.AbsoluteSize

					local at = pointer(st.input)
					st.s = math.clamp((at.X - p.X) / math.max(s.X, 1), 0, 1)
					st.v = 1 - math.clamp((at.Y - p.Y) / math.max(s.Y, 1), 0, 1)
				end)

				graze(bar, function()
					local p, s = bar.AbsolutePosition, bar.AbsoluteSize

					st.h = math.clamp((pointer(st.input).X - p.X) / math.max(s.X, 1), 0, 1)
				end)

				conn(uis.InputEnded, function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or (i.UserInputType == Enum.UserInputType.Touch and i == st.input) then
						releaseDrag()
					end
				end)

				conn(uis.InputChanged, function(i)
					if not st.hold then
						return
					end

					if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
						if i.UserInputType == Enum.UserInputType.Touch and i ~= st.input then return end
						updateDrag()
					end
				end)

				conn(field.Focused, function()
					latch(1)

					anim(hem, soft, { Transparency = 0.35 })
				end)

				conn(field.FocusLost, function()
					latch(-1)

					anim(hem, soft, { Transparency = 0.65 })

					local c = fromhex(field.Text)

					if c then
						st.h, st.s, st.v = Color3.toHSV(c)
					end

					paint(true)
				end)

				local function blink(b)
					b.ImageColor3 = th.accent
					b.ImageTransparency = 0

					anim(b, soft, { ImageColor3 = th.dim, ImageTransparency = 0.25 })
				end

				conn(copier.MouseButton1Click, function()
					if clipput then
						pcall(clipput, hexof(item.color))
					end

					blink(copier)

					visualsui:chime("tap")
				end)

				conn(paster.MouseButton1Click, function()
					local grab = clipget and select(2, pcall(clipget))
					local c = fromhex(grab)

					if c then
						st.h, st.s, st.v = Color3.toHSV(c)

						paint(true)
						blink(paster)

						visualsui:chime("tap")
					end
				end)

				conn(veil.MouseButton1Click, shut)

				conn(tap.MouseButton1Click, function()
					item:setopen(not item.on)

					visualsui:chime("flip")
				end)

				conn(tap.MouseEnter, function()
					warm = true

					glow()
				end)

				conn(tap.MouseLeave, function()
					warm = false

					glow()
				end)

				paint(false, true)
				glow()

				visualsui:hook(t.flag or (t.key and ("theme|" .. t.key)) or (base .. "|" .. t.name), "color", function()
					return item.color
				end, function(v)
					item:set(v)
				end)

				return item
			end

			return sec
		end

		function api:color(cfg)
			cfg = params(cfg, {
				name = "color",
				default = th.accent,
				side = "left",
				flag = nil,
				callback = nil,
			})

			if cfg.key and typeof(th[cfg.key]) == "Color3" then
				local hook = cfg.callback

				cfg.default = th[cfg.key]

				cfg.callback = function(c)
					visualsui:recolor(cfg.key, c)

					if hook then
						hook(c)
					end
				end
			end

			local col = lane(cfg.side)
			local card, rec = crate(col, 196)

			table.insert(cards, { slot = rec, name = cfg.name, rows = {} })

			local strip = new("Frame", {
				Name = rnd(),
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = th.head,
				BorderSizePixel = 0,
				ZIndex = 6,
			}, card)

			round(strip, 7)

			new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 8),
				BackgroundColor3 = th.head,
				BorderSizePixel = 0,
				ZIndex = 6,
			}, strip)

			local rule = new("Frame", {
				Name = rnd(),
				Position = UDim2.fromOffset(0, 28),
				Size = UDim2.new(1, 0, 0, 2),
				BackgroundColor3 = th.accent,
				BackgroundTransparency = 0.45,
				BorderSizePixel = 0,
				ZIndex = 7,
			}, card)

			fade(rule, 0, {
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.12, 0.2),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(0.88, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			})

			new("TextLabel", {
				Name = rnd(),
				Position = UDim2.fromOffset(28, 0),
				Size = UDim2.new(1, -38, 1, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = cfg.name,
				TextColor3 = th.text,
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 7,
			}, strip)

			local chip = new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0),
				Size = UDim2.fromOffset(12, 12),
				BackgroundColor3 = cfg.default,
				BorderSizePixel = 0,
				ZIndex = 7,
			}, strip)

			new("UICorner", { CornerRadius = UDim.new(1, 0) }, chip)
			new("UIStroke", { Color = th.line, Transparency = 0.35 }, chip)

			local item = { card = card, color = cfg.default, chip = chip }
			local tail = {}
			local pendingColor = nil
			local callbackQueued = false
			local colorSerial = 0

			local function queueCallback(c)
				if not cfg.callback then
					return
				end
				if visualsui.configApplying then
					colorSerial += 1
					pendingColor, callbackQueued = nil, false
					callback(cfg.callback, c)
					return
				end

				pendingColor = c

				if callbackQueued then
					return
				end

				callbackQueued = true
				colorSerial += 1
				local serial, epoch = colorSerial, visualsui.applyEpoch

				task.delay(0.05, function()
					if serial ~= colorSerial then return end
					local value = pendingColor

					pendingColor = nil
					callbackQueued = false

					if value and visualsui.alive and epoch == visualsui.applyEpoch then
						callback(cfg.callback, value)
					end
				end)
			end

			function item.apply(c, fire)
				item.color = c

				if fire then
					queueCallback(c)
				end
			end

			function item:set(c)
				if typeof(c) == "string" then
					c = fromhex(c)
				end

				if typeof(c) == "Color3" then
					tail.pull(c)
				end
			end

			function item:get()
				return item.color
			end

			local function nib(x, art)
				local b = new("ImageButton", {
					Name = rnd(),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, x, 0, 175),
					Size = UDim2.fromOffset(20, 20),
					BackgroundColor3 = th.head,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Image = icon(art),
					ImageColor3 = th.dim,
					ImageTransparency = 0.25,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 7,
				}, card)

				round(b, 5)

				conn(b.MouseEnter, function()
					anim(b, soft, { ImageTransparency = 0, ImageColor3 = th.text, BackgroundTransparency = 0.4 })
				end)

				conn(b.MouseLeave, function()
					anim(b, soft, { ImageTransparency = 0.25, ImageColor3 = th.dim, BackgroundTransparency = 1 })
				end)

				return b
			end

			local copier = nib(-32, "copy")
			local paster = nib(-10, "clipboard-paste")

			local function blink(b)
				b.ImageColor3 = th.accent
				b.ImageTransparency = 0

				anim(b, soft, { ImageColor3 = th.dim, ImageTransparency = 0.25 })
			end

			conn(copier.MouseButton1Click, function()
				if clipput then
					pcall(clipput, hexof(item.color))
				end

				blink(copier)
			end)

			conn(paster.MouseButton1Click, function()
				local grab = clipget and select(2, pcall(clipget))
				local c = fromhex(grab)

				if c then
					tail.pull(c)
					blink(paster)
				end
			end)

			inlay(card, item, tail)

			visualsui:hook(cfg.flag or (cfg.key and ("theme|" .. cfg.key)) or (trail .. "|" .. cfg.name), "color", function()
				return item.color
			end, function(v)
				item:set(v)
			end)

			return item
		end

		function api:configs(cfg)
			cfg = params(cfg, {
				name = "Configs",
				side = "left",
			})

			local col = lane(cfg.side)
			local card, rec = crate(col, 266)

			table.insert(cards, { slot = rec, name = cfg.name, rows = {} })

			local strip = new("Frame", {
				Name = rnd(),
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = th.head,
				BorderSizePixel = 0,
				ZIndex = 6,
			}, card)

			round(strip, 7)

			new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 8),
				BackgroundColor3 = th.head,
				BorderSizePixel = 0,
				ZIndex = 6,
			}, strip)

			new("ImageLabel", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0),
				Size = UDim2.fromOffset(13, 13),
				BackgroundTransparency = 1,
				Image = icon("save"),
				ImageColor3 = th.dim,
				ImageTransparency = 0.25,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 7,
			}, strip)

			new("TextLabel", {
				Name = rnd(),
				Position = UDim2.fromOffset(30, 0),
				Size = UDim2.new(1, -40, 1, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = cfg.name,
				TextColor3 = th.text,
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 7,
			}, strip)

			local rule = new("Frame", {
				Name = rnd(),
				Position = UDim2.fromOffset(0, 28),
				Size = UDim2.new(1, 0, 0, 2),
				BackgroundColor3 = th.accent,
				BackgroundTransparency = 0.45,
				BorderSizePixel = 0,
				ZIndex = 7,
			}, card)

			fade(rule, 0, {
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.12, 0.2),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(0.88, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			})

			local list = new("ScrollingFrame", {
				Name = rnd(),
				Position = UDim2.fromOffset(10, 38),
				Size = UDim2.new(1, -20, 0, 128),
				BackgroundColor3 = th.bg,
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
				CanvasSize = UDim2.new(),
				ScrollBarThickness = 0,
				ZIndex = 6,
			}, card)

			round(list, 6)

			new("UIStroke", { Color = th.line, Transparency = 0.74 }, list)

			local lay = new("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}, list)

			new("UIPadding", {
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
			}, list)

			conn(lay:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				list.CanvasSize = UDim2.fromOffset(0, acs(lay).Y + 8)
			end)

			local void = new("TextLabel", {
				Name = rnd(),
				Position = UDim2.fromOffset(10, 38),
				Size = UDim2.new(1, -20, 0, 128),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = "no configs yet",
				TextColor3 = th.dim,
				TextSize = 12,
				TextTransparency = 0.5,
				Visible = false,
				ZIndex = 7,
			}, card)

			local field = new("TextBox", {
				Name = rnd(),
				Position = UDim2.fromOffset(10, 174),
				Size = UDim2.new(1, -20, 0, 26),
				BackgroundColor3 = th.head,
				BorderSizePixel = 0,
				ClearTextOnFocus = false,
				ClipsDescendants = true,
				Font = Enum.Font.GothamBold,
				PlaceholderColor3 = th.dim,
				PlaceholderText = "config name",
				Text = "",
				TextColor3 = th.text,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 6,
			}, card)

			round(field, 6)

			new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, field)

			local brim = new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = th.line,
				Transparency = 0.6,
			}, field)

			local deck = new("Frame", {
				Name = rnd(),
				Position = UDim2.fromOffset(10, 208),
				Size = UDim2.new(1, -20, 0, 28),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 6,
			}, card)

			new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
			}, deck)

			local note = new("TextLabel", {
				Name = rnd(),
				Position = UDim2.fromOffset(11, 242),
				Size = UDim2.new(1, -22, 0, 14),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = "",
				TextColor3 = th.dim,
				TextSize = 11,
				TextTransparency = 1,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 7,
			}, card)

			local turn, hint = 0, false

			local function say(txt, tone, stay)
				turn += 1
				hint = stay and true or false

				local mine = turn

				note.Text = txt
				note.TextColor3 = tone or th.dim

				anim(note, quick, { TextTransparency = 0.2 })

				if stay then
					return
				end

				task.delay(1.9, function()
					if turn == mine then
						anim(note, soft, { TextTransparency = 1 })
					end
				end)
			end

			local function hush()
				if not hint then
					return
				end

				turn += 1
				hint = false

				anim(note, soft, { TextTransparency = 1 })
			end

			local rows, mark, hail = {}, nil, nil

			local function polish(r)
				local sel = mark == r.name

				anim(r.head, soft, { BackgroundTransparency = sel and 0.02 or 0.06 })
				anim(r.tint, soft, { BackgroundTransparency = sel and 0.12 or (r.warm and 0.5 or 1) })
				anim(r.edge, soft, { Transparency = sel and 0.72 or 1 })
				anim(r.bar, soft, {
					Size = UDim2.new(0, 3, 0, sel and 13 or 0),
					BackgroundTransparency = sel and 0.05 or 1,
				})
				anim(r.img, soft, {
					ImageTransparency = sel and 0 or (r.warm and 0.15 or 0.4),
					ImageColor3 = sel and th.text or th.dim,
				})
				anim(r.lbl, soft, {
					TextTransparency = sel and 0 or (r.warm and 0.15 or 0.4),
					TextColor3 = sel and th.text or th.dim,
				})
			end

			local function repaint()
				for _, r in next, rows do
					polish(r)
				end
			end

			local function pin(name)
				mark = name
				field.Text = name or ""

				repaint()
			end

			local function keep()
				local nm = tidy(field.Text) or mark

				if not nm then
					say("type a name first")

					return
				end

				if visualsui:store(nm) then
					mark = nm

					say("saved " .. nm, th.text)
					sweep()
				else
					say("could not write the file")
				end
			end

			local function overwrite()
				if not mark then
					say("select a config first")

					return
				end

				if visualsui:store(mark) then
					field.Text = mark

					say("overwritten " .. mark, th.text)
					sweep()
				else
					say("could not overwrite the file")
				end
			end

			local function draw(name)
				local nm = tidy(name) or mark

				if not nm then
					say("select a config first")

					return
				end

				if visualsui:fetch(nm) then
					pin(nm)

					say("loaded " .. nm, th.text)
				else
					local result = visualsui.configResult
					say(result and result.errors and result.errors[1] or "could not read the file")
				end
			end

			local function toss()
				local nm = mark or tidy(field.Text)

				if not nm then
					say("select a config first")

					return
				end

				if visualsui:erase(nm) then
					mark = nil
					field.Text = ""

					say("deleted " .. nm, th.text)
					sweep()
				else
					say("could not delete the file")
				end
			end

			local function brand()
				local nm = tidy(field.Text)

				if not mark then
					say("select a config first")

					return
				end

				if not nm then
					say("type a new name")

					return
				end

				local res = visualsui:retitle(mark, nm)

				if res then
					pin(res)

					say("renamed to " .. res, th.text)
					sweep()
				else
					say("could not rename the file")
				end
			end

			local function fill(ls)
				for _, r in next, rows do
					for _, c in next, r.cx do
						c:Disconnect()
					end

					r.head:Destroy()
				end

				table.clear(rows)

				if mark and not table.find(ls, mark) then
					mark = nil
				end

				void.Visible = #ls == 0

				for i, name in next, ls do
					local r = { name = name, warm = false, cx = {} }

					r.head = new("Frame", {
						Name = rnd(),
						Size = UDim2.new(1, 0, 0, 25),
						BackgroundColor3 = th.side,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						LayoutOrder = i,
						ZIndex = 6,
					}, list)

					round(r.head, 6)

					r.edge = new("UIStroke", { Color = th.line, Transparency = 1 }, r.head)

					r.tint = new("Frame", {
						Name = rnd(),
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = th.panel,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ZIndex = 6,
					}, r.head)

					round(r.tint, 6)

					fade(r.tint, 0, {
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(0.7, 0.25),
						NumberSequenceKeypoint.new(1, 0.55),
					})

					r.bar = new("Frame", {
						Name = rnd(),
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 1, 0.5, 0),
						Size = UDim2.new(0, 3, 0, 0),
						BackgroundColor3 = th.accent,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ZIndex = 7,
					}, r.head)

					new("UICorner", { CornerRadius = UDim.new(1, 0) }, r.bar)

					r.img = new("ImageLabel", {
						Name = rnd(),
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 9, 0.5, 0),
						Size = UDim2.fromOffset(12, 12),
						BackgroundTransparency = 1,
						Image = icon("file-text"),
						ImageColor3 = th.dim,
						ImageTransparency = 1,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 7,
					}, r.head)

					r.lbl = new("TextLabel", {
						Name = rnd(),
						Position = UDim2.fromOffset(28, 0),
						Size = UDim2.new(1, -36, 1, 0),
						BackgroundTransparency = 1,
						Font = Enum.Font.GothamBold,
						Text = name,
						TextColor3 = th.dim,
						TextSize = 12,
						TextTransparency = 1,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 7,
					}, r.head)

					r.btn = new("ImageButton", {
						Name = rnd(),
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						ImageTransparency = 1,
						ZIndex = 8,
					}, r.head)

					table.insert(r.cx, r.btn.MouseEnter:Connect(function()
						r.warm = true

						polish(r)
					end))

					table.insert(r.cx, r.btn.MouseLeave:Connect(function()
						r.warm = false

						polish(r)
					end))

					table.insert(r.cx, r.btn.MouseButton1Click:Connect(function()
						local now = os.clock()

						if mark == r.name and now - (hail or 0) < 0.4 then
							hail = nil

							draw(r.name)

							return
						end

						hail = now

						pin(r.name)
					end))

					rows[i] = r

					task.delay((i - 1) * 0.03, function()
						if r.head.Parent then
							polish(r)
						end
					end)
				end
			end

			local ord = 0

			local function nub(art, label, fn)
				ord += 1

				local b = new("ImageButton", {
					Name = rnd(),
					Size = UDim2.new(0.2, -4.8, 1, 0),
					BackgroundColor3 = th.head,
					BackgroundTransparency = 0.12,
					BorderSizePixel = 0,
					Image = "",
					LayoutOrder = ord,
					ZIndex = 6,
				}, deck)

				round(b, 6)

				local ring = new("UIStroke", { Color = th.line, Transparency = 0.78 }, b)

				local pip = new("ImageLabel", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(15, 15),
					BackgroundTransparency = 1,
					Image = icon(art),
					ImageColor3 = th.dim,
					ImageTransparency = 0.25,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 7,
				}, b)

				conn(b.MouseEnter, function()
					anim(b, soft, { BackgroundTransparency = 0 })
					anim(ring, soft, { Transparency = 0.45 })
					anim(pip, soft, { ImageTransparency = 0, ImageColor3 = th.text })

					say(label, th.dim, true)
				end)

				conn(b.MouseLeave, function()
					anim(b, soft, { BackgroundTransparency = 0.12 })
					anim(ring, soft, { Transparency = 0.78 })
					anim(pip, soft, { ImageTransparency = 0.25, ImageColor3 = th.dim })

					hush()
				end)

				conn(b.MouseButton1Click, function()
					pip.ImageColor3 = th.accent

					anim(pip, soft, { ImageColor3 = th.text })

					visualsui:chime("tap")

					fn()
				end)

				return b
			end

			nub("save", "save current settings", keep)
			nub("folder", "load selected config", draw)
			nub("refresh-cw", "overwrite selected config", overwrite)
			nub("file-text", "rename selected config", brand)
			nub("trash-2", "delete selected config", toss)

			conn(field.Focused, function()
				anim(brim, soft, { Transparency = 0.35 })
			end)

			conn(field.FocusLost, function(enter)
				anim(brim, soft, { Transparency = 0.6 })

				if enter then
					keep()
				end
			end)

			visualsui:watch(fill)

			local box = {
				card = card,
				list = list,
				refresh = function()
					fill(visualsui:roster())
				end,
			}

			function box:get()
				return mark
			end

			function box:select(name)
				pin(tidy(name))
			end

			return box
		end

		function api:gallery(cfg)
			cfg = params(cfg, {
				name = "Gallery",
				icon = "image",
				side = "left",
				height = 250,
				list = {},
				default = nil,
				multi = false,
				thumb = "Asset",
				blank = "image",
				cell = 76,
				gap = 6,
				wrap = false,
				smooth = false,
				search = true,
				tools = true,
				reset = false,
				buttons = nil,
				action = nil,
				context = nil,
				empty = "nothing here",
				flag = nil,
				callback = nil,
			})

			local tall = math.clamp(math.floor(tonumber(cfg.height) or 250), 110, 560)
			local hunt = cfg.search and true or false
			local extra = type(cfg.buttons) == "table" and cfg.buttons or {}
			local deckon = (cfg.tools and true or false) or #extra > 0
			local shape = shots[string.lower(tostring(cfg.thumb))]
			local gy = 38 + (hunt and 32 or 0)
			local dy = gy + tall + 8
			local ny = dy + (deckon and 34 or 0)

			local col = lane(cfg.side)
			local card, rec = crate(col, ny + 20)

			table.insert(cards, { slot = rec, name = cfg.name, rows = {} })

			local strip = new("Frame", {
				Name = rnd(),
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = th.head,
				BorderSizePixel = 0,
				ZIndex = 6,
			}, card)

			round(strip, 7)

			new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 8),
				BackgroundColor3 = th.head,
				BorderSizePixel = 0,
				ZIndex = 6,
			}, strip)

			new("ImageLabel", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0),
				Size = UDim2.fromOffset(13, 13),
				BackgroundTransparency = 1,
				Image = icon(cfg.icon),
				ImageColor3 = th.dim,
				ImageTransparency = 0.25,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 7,
			}, strip)

			new("TextLabel", {
				Name = rnd(),
				Position = UDim2.fromOffset(30, 0),
				Size = UDim2.new(1, -96, 1, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = cfg.name,
				TextColor3 = th.text,
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 7,
			}, strip)

			local count = new("TextLabel", {
				Name = rnd(),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(60, 14),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = "0",
				TextColor3 = th.dim,
				TextSize = 11,
				TextTransparency = 0.3,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 7,
			}, strip)

			local rule = new("Frame", {
				Name = rnd(),
				Position = UDim2.fromOffset(0, 28),
				Size = UDim2.new(1, 0, 0, 2),
				BackgroundColor3 = th.accent,
				BackgroundTransparency = 0.45,
				BorderSizePixel = 0,
				ZIndex = 7,
			}, card)

			fade(rule, 0, {
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.12, 0.2),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(0.88, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			})

			local field, brim = nil, nil

			if hunt then
				field = new("TextBox", {
					Name = rnd(),
					Position = UDim2.fromOffset(10, 38),
					Size = UDim2.new(1, -20, 0, 26),
					BackgroundColor3 = th.head,
					BorderSizePixel = 0,
					ClearTextOnFocus = false,
					ClipsDescendants = true,
					Font = Enum.Font.GothamBold,
					PlaceholderColor3 = th.dim,
					PlaceholderText = "search",
					Text = "",
					TextColor3 = th.text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 6,
				}, card)

				round(field, 6)

				new("UIPadding", { PaddingLeft = UDim.new(0, 30), PaddingRight = UDim.new(0, 10) }, field)

				brim = new("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = th.line,
					Transparency = 0.6,
				}, field)

				new("ImageLabel", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 20, 0, 51),
					Size = UDim2.fromOffset(13, 13),
					BackgroundTransparency = 1,
					Image = icon("search"),
					ImageColor3 = th.dim,
					ImageTransparency = 0.3,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 8,
				}, card)
			end

			local list = new("ScrollingFrame", {
				Name = rnd(),
				Active = true,
				Position = UDim2.fromOffset(10, gy),
				Size = UDim2.new(1, -20, 0, tall),
				BackgroundColor3 = th.bg,
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
				CanvasSize = UDim2.new(),
				ClipsDescendants = true,
				ElasticBehavior = Enum.ElasticBehavior.Never,
				ScrollingEnabled = true,
				ScrollBarImageColor3 = th.accent,
				ScrollBarImageTransparency = cfg.smooth and 0.3 or 1,
				ScrollBarThickness = cfg.smooth and 3 or 0,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ZIndex = 6,
			}, card)

			round(list, 6)

			local ring = new("UIStroke", { Color = th.line, Transparency = 0.74 }, list)

			local void = new("TextLabel", {
				Name = rnd(),
				Position = UDim2.fromOffset(10, gy),
				Size = UDim2.new(1, -20, 0, tall),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = cfg.empty,
				TextColor3 = th.dim,
				TextSize = 12,
				TextTransparency = 0.5,
				Visible = false,
				ZIndex = 7,
			}, card)

			local deck, note = nil, nil

			if deckon then
				deck = new("Frame", {
					Name = rnd(),
					Position = UDim2.fromOffset(10, dy),
					Size = UDim2.new(1, -20, 0, 28),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 6,
				}, card)

				new("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
				}, deck)
			end

			note = new("TextLabel", {
				Name = rnd(),
				Position = UDim2.fromOffset(11, ny),
				Size = UDim2.new(1, -22, 0, 14),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = "",
				TextColor3 = th.dim,
				TextSize = 11,
				TextTransparency = 1,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 7,
			}, card)

			local turn, stick = 0, false

			local function say(txt, tone, stay)
				turn += 1
				stick = stay and true or false

				local mine = turn

				note.Text = txt
				note.TextColor3 = tone or th.dim

				anim(note, quick, { TextTransparency = 0.2 })

				if stay then
					return
				end

				task.delay(1.9, function()
					if turn == mine then
						anim(note, soft, { TextTransparency = 1 })
					end
				end)
			end

			local function mute()
				if not stick then
					return
				end

				turn += 1
				stick = false

				anim(note, soft, { TextTransparency = 1 })
			end

			local item
			local data, view = {}, {}
			local pick, bag = nil, {}
			local pool, live = {}, 0
			local span, held = 0, {}
			local want = math.clamp(math.floor(tonumber(cfg.cell) or 76), 44, 220)
			local gap = math.max(math.floor(tonumber(cfg.gap) or 6), 2)
			local pad = 5
			local labelh = cfg.wrap and 28 or 14
			local lane, cw, chh, rowh = 1, want, want + labelh, want + labelh + 6
			local query = ""
			local dirty, tick = true, false

			local function melt(v)
				if type(v) == "string" then
					if v == "" then
						return nil
					end

					return { name = v, label = v }
				end

				if type(v) ~= "table" then
					return nil
				end

				local nm = v.name or v.Name or v.label or v.Label or v.id or v.Id
				if nm == nil then
					return nil
				end

				nm = tostring(nm)

				local id = tonumber(v.id or v.Id or v.ID or v.asset or v.Asset or v.assetid or v.AssetId or v.userid or v.UserId)
				local art = v.image or v.Image or v.icon or v.Icon or v.art or v.thumb or v.Thumb

				return {
					name = nm,
					label = tostring(v.display or v.Display or v.label or v.Label or nm),
					id = id,
					art = (type(art) == "string" or type(art) == "number") and art or nil,
					rect = typeof(v.rect) == "Vector2" and v.rect or nil,
					rectsize = typeof(v.rectsize) == "Vector2" and v.rectsize or nil,
				}
			end

			local function pull(e)
				if e.art then
					return icon(e.art)
				end

				if shape and e.id and e.id > 0 then
					return string.format(shape, e.id)
				end

				return ""
			end

			visualsui.thumbnailState = visualsui.thumbnailState or { ready = {}, loading = {} }
			local thumbnailState = visualsui.thumbnailState
			local thumbnailQueue = {}
			local thumbnailWorker = false
			local function warm(e)
				local id = e and pull(e) or ""
				if id == "" or thumbnailState.ready[id] or thumbnailState.loading[id] then return end
				thumbnailState.loading[id] = true
				thumbnailQueue[#thumbnailQueue + 1] = id
				if thumbnailWorker then return end
				thumbnailWorker = true
				task.spawn(function()
					local provider = game:GetService("ContentProvider")
					while visualsui.alive and #thumbnailQueue > 0 do
						local batch = {}
						for _ = 1, math.min(12, #thumbnailQueue) do batch[#batch + 1] = table.remove(thumbnailQueue, 1) end
						local ok = pcall(provider.PreloadAsync, provider, batch)
						for _, content in ipairs(batch) do
							thumbnailState.loading[content] = nil
							if ok then thumbnailState.ready[content] = true end
						end
						task.wait()
					end
					for _, content in ipairs(thumbnailQueue) do thumbnailState.loading[content] = nil end
					table.clear(thumbnailQueue)
					thumbnailWorker = false
				end)
			end

			local function chosen(nm)
				if cfg.multi then
					return bag[nm] == true
				end

				return pick == nm
			end

			local function total()
				if not cfg.multi then
					return pick and 1 or 0
				end

				local n = 0

				for _ in next, bag do
					n += 1
				end

				return n
			end

			local function tag()
				local n = #view
				local all = #data

				if n == all then
					count.Text = (cfg.multi and (total() .. "/" .. all)) or tostring(all)
				else
					count.Text = n .. "/" .. all
				end
			end

			local function value()
				if not cfg.multi then
					return pick
				end

				local out = {}

				for i = 1, #data do
					local nm = data[i].name

					if bag[nm] then
						out[#out + 1] = nm
					end
				end

				return out
			end

			local function shout()
				if cfg.callback and not visualsui.quiet then
					callback(cfg.callback, value())
				end
			end

			local function dress(t, instant)
				if not t.head.Visible and not instant then
					return
				end

				local sel = t.name ~= nil and chosen(t.name)
				local hot = t.warm and not sel

				local bt = sel and 0.02 or 0.07
				local tt = sel and 0.1 or (hot and 0.45 or 1)
				local et = sel and 0.35 or (hot and 0.6 or 1)
				local ec = sel and th.accent or th.line
				local lt = sel and 0 or (hot and 0.12 or 0.4)
				local lc = sel and th.text or th.dim
				local it = sel and 0 or (hot and 0.06 or 0.22)

				t.mark.Visible = sel

				if instant then
					t.head.BackgroundTransparency = bt
					t.tint.BackgroundTransparency = tt
					t.edge.Transparency = et
					t.edge.Color = ec
					t.lbl.TextTransparency = lt
					t.lbl.TextColor3 = lc
					t.shot.ImageTransparency = it

					return
				end

				anim(t.head, soft, { BackgroundTransparency = bt })
				anim(t.tint, soft, { BackgroundTransparency = tt })
				anim(t.edge, soft, { Transparency = et, Color = ec })
				anim(t.lbl, soft, { TextTransparency = lt, TextColor3 = lc })
				anim(t.shot, soft, { ImageTransparency = it })
			end

			local function tap(t)
				if not t.name then
					return
				end

				visualsui:chime("tap")

				if cfg.multi then
					if bag[t.name] then
						bag[t.name] = nil
					else
						bag[t.name] = true
					end
				else
					if pick == t.name then
						pick = nil
					else
						pick = t.name
					end
				end

				for i = 1, live do
					dress(pool[i])
				end

				tag()
				shout()
			end

			local function forge()
				local t = { warm = false }

				t.head = new("Frame", {
					Name = rnd(),
					Size = UDim2.fromOffset(cw, chh),
					BackgroundColor3 = th.side,
					BackgroundTransparency = 0.07,
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 6,
				}, list)

				round(t.head, 6)

				t.edge = new("UIStroke", { Color = th.line, Transparency = 1 }, t.head)

				t.tint = new("Frame", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = th.panel,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 6,
				}, t.head)

				round(t.tint, 6)

				fade(t.tint, 90, {
					NumberSequenceKeypoint.new(0, 0.1),
					NumberSequenceKeypoint.new(0.7, 0.3),
					NumberSequenceKeypoint.new(1, 0.6),
				})

				t.shot = new("ImageLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(4, 4),
					Size = UDim2.fromOffset(cw - 8, cw - 8),
					BackgroundColor3 = th.bg,
					BackgroundTransparency = 0.45,
					BorderSizePixel = 0,
					Image = "",
					ImageColor3 = Color3.new(1, 1, 1),
					ImageTransparency = 0.22,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 7,
				}, t.head)

				round(t.shot, 5)

				t.mark = new("Frame", {
					Name = rnd(),
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -6, 0, 6),
					Size = UDim2.fromOffset(14, 14),
					BackgroundColor3 = th.accent,
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 8,
				}, t.head)

				new("UICorner", { CornerRadius = UDim.new(1, 0) }, t.mark)

				new("ImageLabel", {
					Name = rnd(),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(9, 9),
					BackgroundTransparency = 1,
					Image = icon("check"),
					ImageColor3 = th.bg,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 9,
				}, t.mark)

				t.lbl = new("TextLabel", {
					Name = rnd(),
					Position = UDim2.fromOffset(4, cw - 3),
					Size = UDim2.new(1, -8, 0, labelh),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					Text = "",
					TextColor3 = th.dim,
					TextSize = 11,
					TextTransparency = 0.4,
					TextTruncate = cfg.wrap and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
					TextWrapped = cfg.wrap,
					TextYAlignment = cfg.wrap and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
					ZIndex = 7,
				}, t.head)

				t.btn = new("ImageButton", {
					Name = rnd(),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ImageTransparency = 1,
					ZIndex = 9,
				}, t.head)

				conn(t.btn.MouseEnter, function()
					t.warm = true

					dress(t)

					if t.name then
						say(t.label or t.name, th.dim, true)
					end
				end)

				conn(t.btn.MouseLeave, function()
					t.warm = false

					dress(t)
					mute()
				end)

				conn(t.btn.MouseButton1Click, function()
					if t.skip then
						t.skip = nil

						return
					end

					tap(t)
				end)

				if type(cfg.context) == "function" then
					local function fire()
						if not t.name then
							return
						end

						visualsui:chime("tap")

						local at = t.head.AbsolutePosition

						task.spawn(cfg.context, t.name, item, at.X + t.head.AbsoluteSize.X * 0.5, at.Y + 12, t.head)
					end

					conn(t.btn.MouseButton2Click, fire)

					conn(t.btn.InputBegan, function(i)
						if i.UserInputType ~= Enum.UserInputType.Touch then
							return
						end

						local mine = os.clock()

						t.hold = mine

						task.delay(0.35, function()
							if t.hold == mine then
								t.hold = nil
								t.skip = true

								fire()
							end
						end)
					end)

					conn(t.btn.InputChanged, function(i)
						if i.UserInputType == Enum.UserInputType.Touch then
							t.hold = nil
						end
					end)

					conn(t.btn.InputEnded, function(i)
						if i.UserInputType == Enum.UserInputType.Touch then
							t.hold = nil
						end
					end)
				end

				if type(cfg.action) == "table" then
						t.act = new("ImageButton", {
							Name = rnd(),
							AnchorPoint = Vector2.new(1, 0),
							Position = UDim2.new(1, -5, 0, 5),
							Size = UDim2.fromOffset(19, 19),
							BackgroundColor3 = th.bg,
							BackgroundTransparency = 0.2,
							BorderSizePixel = 0,
							Active = true,
						Image = "",
						ZIndex = 10,
					}, t.head)

					round(t.act, 5)

					new("UIStroke", { Color = th.line, Transparency = 0.6 }, t.act)

					local pin = new("ImageLabel", {
						Name = rnd(),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromOffset(12, 12),
						BackgroundTransparency = 1,
						Image = icon(cfg.action.icon or "sliders-horizontal"),
						ImageColor3 = th.text,
						ImageTransparency = 0.15,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 11,
					}, t.act)

					conn(t.act.MouseEnter, function()
						anim(t.act, soft, { BackgroundTransparency = 0 })
						anim(pin, soft, { ImageTransparency = 0, ImageColor3 = th.accent })
					end)

					conn(t.act.MouseLeave, function()
						anim(t.act, soft, { BackgroundTransparency = 0.2 })
						anim(pin, soft, { ImageTransparency = 0.15, ImageColor3 = th.text })
					end)

					conn(t.act.MouseButton1Click, function()
						if not t.name then
							return
						end

						visualsui:chime("tap")

						local fn = cfg.action.callback

						if type(fn) == "function" then
							local at = t.head.AbsolutePosition

							task.spawn(fn, t.name, item, at.X + 22, at.Y + 20, t.head)
						end
					end)
				end

				return t
			end

			local function shell(t)
				t.head.Size = UDim2.fromOffset(cw, chh)
				t.shot.Size = UDim2.fromOffset(cw - 8, cw - 8)
				t.lbl.Position = UDim2.fromOffset(4, cw - 3)
			end

			local function metrics()
				local w = asz(list).X - pad * 2

				if w < 20 then
					return false
				end

				local n = math.max(math.floor((w + gap) / (want + gap)), 1)
				local c = math.max(math.floor((w - gap * (n - 1)) / n), 30)

				if n == lane and c == cw then
					return false
				end

				lane, cw = n, c
				chh = cw + 14
				rowh = chh + gap

				for i = 1, #pool do
					shell(pool[i])
				end

				return true
			end

			local function draw()
				local n = #view

				list.CanvasSize = UDim2.fromOffset(0, math.max(math.ceil(n / lane) * rowh - gap + pad * 2, 0))

				local top = list.CanvasPosition.Y
				local seen = asz(list).Y
				local first = math.max(math.floor((top - pad) / rowh), 0)
				local last = math.max(math.ceil((top + seen - pad) / rowh), first + 1)
				local a = first * lane + 1
				local b = math.min(last * lane, n)
				local cap = lane * math.max(last - first + 2, 3)

				if cap ~= span then
					span = cap

					for i = 1, #pool do
						pool[i].name = nil
						pool[i].head.Visible = false
					end
				end

				table.clear(held)

				for i = a, b do
					local e = view[i]

					if e then
						warm(e)
						local s = (i - 1) % cap + 1
						local t = pool[s]

						if not t then
							t = forge()
							pool[s] = t
						end

						held[s] = true

						local fresh = t.name ~= e.name or t.entry ~= e
						local r = math.floor((i - 1) / lane)
						local c = (i - 1) % lane

						t.name = e.name
						t.entry = e
						t.label = e.label

						t.head.Position = UDim2.fromOffset(pad + c * (cw + gap), pad + r * rowh)

						if fresh then
							t.lbl.Text = e.label
							t.shot.Image = pull(e)
							t.shot.ImageRectOffset = e.rect or Vector2.zero
							t.shot.ImageRectSize = e.rectsize or Vector2.zero

							if t.shot.Image == "" then
								t.shot.Image = icon(cfg.blank)
								t.shot.ImageColor3 = th.dim
							else
								t.shot.ImageColor3 = Color3.new(1, 1, 1)
							end
						end

						if not t.head.Visible then
							t.head.Visible = true
						end

						dress(t, fresh)
					end
				end
				for i = b + 1, math.min(b + cap, n) do warm(view[i]) end

				for i = 1, #pool do
					if not held[i] then
						local t = pool[i]

						t.name = nil
						t.head.Visible = false
					end
				end

				live = #pool
			end

			local function stir()
				if tick then
					return
				end

				tick = true

				task.defer(function()
					tick = false

					if not rec.live then
						dirty = true

						return
					end

					dirty = false

					metrics()
					draw()
				end)
			end

			local function sieve()
				table.clear(view)

				if query == "" then
					for i = 1, #data do
						view[i] = data[i]
					end
				else
					for i = 1, #data do
						local e = data[i]

						if string.find(string.lower(e.label), query, 1, true) or string.find(string.lower(e.name), query, 1, true) then
							view[#view + 1] = e
						end
					end
				end

				void.Visible = #view == 0
				list.CanvasPosition = Vector2.new(0, math.min(list.CanvasPosition.Y, math.max(math.ceil(#view / math.max(lane, 1)) * rowh - asz(list).Y, 0)))

				tag()
				stir()
			end

			local function soak(ls)
				table.clear(data)

				local seen = {}

				if type(ls) == "table" then
					for _, v in next, ls do
						local e = melt(v)

						if e and not seen[e.name] then
							seen[e.name] = true
							data[#data + 1] = e
						end
					end
				end

				if cfg.multi then
					for nm in next, bag do
						if not seen[nm] then
							bag[nm] = nil
						end
					end
				elseif pick and not seen[pick] then
					pick = nil
				end

				sieve()
			end

			conn(list:GetPropertyChangedSignal("CanvasPosition"), stir)
			conn(list:GetPropertyChangedSignal("AbsoluteSize"), stir)

			conn(list.MouseEnter, function()
				anim(ring, soft, { Transparency = 0.5 })
			end)

			conn(list.MouseLeave, function()
				anim(ring, soft, { Transparency = 0.74 })
			end)

			if field then
				conn(field.Focused, function()
					anim(brim, soft, { Transparency = 0.35 })
				end)

				conn(field.FocusLost, function()
					anim(brim, soft, { Transparency = 0.6 })
				end)

				conn(field:GetPropertyChangedSignal("Text"), function()
					local q = string.lower(string.match(field.Text, "^%s*(.-)%s*$") or "")

					if q == query then
						return
					end

					query = q

					sieve()
				end)
			end

			item = { card = card, list = list, data = data }

			function item:get()
				return value()
			end

			function item:set(v, quiet)
				if cfg.multi then
					table.clear(bag)

					if type(v) == "table" then
						for k, s in next, v do
							if s == true and type(k) == "string" then
								bag[k] = true
							elseif type(s) == "string" and s ~= "" then
								bag[s] = true
							end
						end
					elseif type(v) == "string" and v ~= "" then
						for s in string.gmatch(v, "[^,]+") do
							local nm = string.match(s, "^%s*(.-)%s*$")

							if nm ~= "" then
								bag[nm] = true
							end
						end
					end
				else
					if type(v) == "table" then
						v = v.name or v.Name
					end

					pick = (type(v) == "string" and v ~= "") and v or nil
				end

				for i = 1, live do
					dress(pool[i])
				end

				tag()

				if not quiet then
					shout()
				end
			end

			function item:setdata(ls)
				soak(ls)
			end

			function item:setdefault(v)
				item:set(v, true)
			end

			function item:clear()
				table.clear(bag)

				pick = nil

				for i = 1, live do
					dress(pool[i])
				end

				tag()
				shout()
			end

			function item:all()
				if not cfg.multi then
					return
				end

				for i = 1, #view do
					bag[view[i].name] = true
				end

				for i = 1, live do
					dress(pool[i])
				end

				tag()
				shout()
			end

			function item:refresh()
				sieve()
			end

			function item:values()
				local out = {}

				for i = 1, #data do
					out[i] = data[i].name
				end

				return out
			end

			function item:search(q)
				if field then
					field.Text = tostring(q or "")
				end
			end

			if deck then
				local ord = 0
				local slots = {}

				if cfg.multi then
					slots[#slots + 1] = { icon = "check", tip = "select everything shown", callback = function()
						item:all()
					end }
					slots[#slots + 1] = { icon = "x", tip = "clear selection", callback = function()
						item:clear()
					end }
				elseif cfg.tools then
					slots[#slots + 1] = { icon = "x", tip = "clear selection", callback = function()
						item:clear()
					end }
				end

				if cfg.tools then
					slots[#slots + 1] = { icon = "refresh-cw", tip = "reload the list", callback = function()
						sieve()
					end }
				end

				for _, b in next, extra do
					if type(b) == "table" then
						slots[#slots + 1] = b
					end
				end

				local span = math.max(#slots, 1)

				for _, b in next, slots do
					ord += 1

					local hit = new("ImageButton", {
						Name = rnd(),
						Size = UDim2.new(1 / span, -(gap * (span - 1)) / span, 1, 0),
						BackgroundColor3 = th.head,
						BackgroundTransparency = 0.12,
						BorderSizePixel = 0,
						Image = "",
						LayoutOrder = ord,
						ZIndex = 6,
					}, deck)

					round(hit, 6)

					local band = new("UIStroke", { Color = th.line, Transparency = 0.78 }, hit)

					local pip = new("ImageLabel", {
						Name = rnd(),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromOffset(15, 15),
						BackgroundTransparency = 1,
						Image = icon(b.icon or b.Icon or "circle-dot"),
						ImageColor3 = th.dim,
						ImageTransparency = 0.25,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 7,
					}, hit)

					local hint = b.tip or b.Tip or b.name or b.Name

					conn(hit.MouseEnter, function()
						anim(hit, soft, { BackgroundTransparency = 0 })
						anim(band, soft, { Transparency = 0.45 })
						anim(pip, soft, { ImageTransparency = 0, ImageColor3 = th.text })

						if hint then
							say(hint, th.dim, true)
						end
					end)

					conn(hit.MouseLeave, function()
						anim(hit, soft, { BackgroundTransparency = 0.12 })
						anim(band, soft, { Transparency = 0.78 })
						anim(pip, soft, { ImageTransparency = 0.25, ImageColor3 = th.dim })

						mute()
					end)

					conn(hit.MouseButton1Click, function()
						pip.ImageColor3 = th.accent

						anim(pip, soft, { ImageColor3 = th.text })

						visualsui:chime("tap")

						local fn = b.callback or b.Callback

						if type(fn) == "function" then
							task.spawn(fn, item)
						end
					end)
				end
			end

			conn(rec.frame:GetPropertyChangedSignal("Visible"), function()
				if rec.frame.Visible and dirty then
					stir()
				end
			end)

			soak(cfg.list)

			if cfg.default ~= nil then
				item:set(cfg.default, true)
			end

			visualsui:hook(cfg.flag or (trail .. "|" .. cfg.name), cfg.multi and "list" or "string", function()
				if cfg.multi then
					return table.concat(value(), ", ")
				end

				return pick or ""
			end, function(v)
				item:set(v, true)

				if cfg.callback then
					callback(cfg.callback, value())
				end
			end, {validate=function(v)
				local function known(name)
					for _, entry in ipairs(data) do if entry.name == name then return true end end
					return false
				end
				if not cfg.multi then return v == "" or known(v) end
				for name in string.gmatch(v, "[^,]+") do
					if not known(string.match(name, "^%s*(.-)%s*$")) then return false end
				end
				return true
			end})

			task.defer(stir)

			return item
		end

		function api:clone(cfg)
			cfg = params(cfg, {
				name = "Clone",
				icon = "person-standing",
				side = "left",
				height = 208,
				fov = 45,
				zoom = 1,
				yaw = 18,
				pitch = -6,
				spin = 24,
				delay = 0.45,
				warm = 1.1,
				sens = 0.5,
				rotate = true,
				reset = true,
				callback = nil,
			})

			local tall = math.clamp(math.floor(tonumber(cfg.height) or 208), 90, 560)
			local col = lane(cfg.side)
			local card, rec = crate(col, tall + 48)

			table.insert(cards, { slot = rec, name = cfg.name, rows = {} })

			local strip = new("Frame", {
				Name = rnd(),
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = th.head,
				BorderSizePixel = 0,
				ZIndex = 6,
			}, card)

			round(strip, 7)

			new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 8),
				BackgroundColor3 = th.head,
				BorderSizePixel = 0,
				ZIndex = 6,
			}, strip)

			new("ImageLabel", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0),
				Size = UDim2.fromOffset(13, 13),
				BackgroundTransparency = 1,
				Image = icon(cfg.icon),
				ImageColor3 = th.dim,
				ImageTransparency = 0.25,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 7,
			}, strip)

			new("TextLabel", {
				Name = rnd(),
				Position = UDim2.fromOffset(30, 0),
				Size = UDim2.new(1, -66, 1, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = cfg.name,
				TextColor3 = th.text,
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 7,
			}, strip)

			local rule = new("Frame", {
				Name = rnd(),
				Position = UDim2.fromOffset(0, 28),
				Size = UDim2.new(1, 0, 0, 2),
				BackgroundColor3 = th.accent,
				BackgroundTransparency = 0.45,
				BorderSizePixel = 0,
				ZIndex = 7,
			}, card)

			fade(rule, 0, {
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.12, 0.2),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(0.88, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			})

			local stage = new("Frame", {
				Name = rnd(),
				Position = UDim2.fromOffset(10, 38),
				Size = UDim2.new(1, -20, 0, tall),
				BackgroundColor3 = th.bg,
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				ZIndex = 6,
			}, card)

			round(stage, 6)

			local ring = new("UIStroke", { Color = th.line, Transparency = 0.74 }, stage)

			local haze = new("Frame", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0.6, 0),
				BackgroundColor3 = th.glow,
				BackgroundTransparency = 0.88,
				BorderSizePixel = 0,
				ZIndex = 6,
			}, stage)

			round(haze, 6)

			fade(haze, 90, {
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0.3),
			})

			local view = new("ViewportFrame", {
				Name = rnd(),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Ambient = Color3.fromRGB(148, 148, 160),
				LightColor = Color3.fromRGB(255, 255, 255),
				LightDirection = Vector3.new(-0.35, -1, -0.55),
				ZIndex = 7,
			}, stage)

			round(view, 6)

			local host = view

			if supports("WorldModel") then
				host = new("WorldModel", { Name = rnd() }, view)
			end

			local cam = new("Camera", {
				Name = rnd(),
				FieldOfView = math.clamp(tonumber(cfg.fov) or 45, 10, 100),
			}, view)

			view.CurrentCamera = cam

			local overlay = new("Frame", {
				Name = rnd(),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				ZIndex = 8,
			}, stage)

			local grab = new("ImageButton", {
				Name = rnd(),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ImageTransparency = 1,
				ZIndex = 9,
			}, stage)

			local item = {
				card = card,
				stage = stage,
				viewport = view,
				world = host,
				camera = cam,
				overlay = overlay,
				model = nil,
				root = nil,
				parts = {},
				active = false,
				yaw = tonumber(cfg.yaw) or 0,
				pitch = math.clamp(tonumber(cfg.pitch) or 0, -80, 80),
				zoom = math.clamp(tonumber(cfg.zoom) or 1, 0.35, 4),
			}

			local hooks = {}
			local bounds = Vector3.new(4, 5.5, 4)
			local center = Vector3.new(0, 2.75, 0)
			local pivot = Vector3.new(0, 2.75, 0)
			local reach, ready, held, wait0, watch = 12, false, false, 0, nil
			local drift, rest = 0, 0
			local dirty, dirty0 = false, 0

			local function fit()
				local tan = math.tan(math.rad(cam.FieldOfView * 0.5))
				local sz = view.AbsoluteSize
				local ratio = (sz.Y > 1) and (sz.X / sz.Y) or 1
				local drop = math.abs(center.Y - pivot.Y)
				local high = bounds.Y * 0.5 + drop
				local wide = math.sqrt(bounds.X * bounds.X + bounds.Z * bounds.Z) * 0.5

				reach = math.max(high / tan, wide / (tan * math.max(ratio, 0.05))) * 1.12
			end

			local function place()
				cam.CFrame = CFrame.new(pivot)
					* CFrame.fromEulerAnglesYXZ(math.rad(item.pitch), math.rad(item.yaw), 0)
					* CFrame.new(0, 0, reach * item.zoom)
			end

			local function nudge()
				local at = view.Parent

				if not at then
					return
				end

				view.Parent = nil
				view.Parent = at
			end

			local function bay()
				return view.AbsolutePosition + inset(), view.AbsoluteSize
			end

			local function cast(v3)
				local at, sz = bay()

				if sz.X < 1 or sz.Y < 1 then
					return 0, 0, false
				end

				local rel = cam.CFrame:PointToObjectSpace(v3)

				if rel.Z > -0.05 then
					return 0, 0, false
				end

				local tan = math.tan(math.rad(cam.FieldOfView * 0.5))
				local far = -rel.Z
				local nx = rel.X / (far * tan * (sz.X / sz.Y))
				local ny = rel.Y / (far * tan)

				return at.X + sz.X * (0.5 + nx * 0.5), at.Y + sz.Y * (0.5 - ny * 0.5), true
			end

			local function ping(dt)
				for i = #hooks, 1, -1 do
					local fn = hooks[i]

					if type(fn) ~= "function" then
						table.remove(hooks, i)
					elseif not pcall(fn, item, dt) then
						table.remove(hooks, i)
					end
				end
			end

			local function wipe()
				if watch then
					watch:Disconnect()
					watch = nil
				end

				if item.model then
					item.model:Destroy()
					item.model = nil
				end

				table.clear(item.parts)

				item.root = nil
				ready = false
			end

			local function twin(a, b, out)
				local ac, bc = a:GetChildren(), b:GetChildren()

				for i = 1, #ac do
					local x = ac[i]
					local y = bc[i]

					if not y or y.Name ~= x.Name or y.ClassName ~= x.ClassName then
						y = b:FindFirstChild(x.Name)
					end

					if y then
						if x:IsA("BasePart") and y:IsA("BasePart") then
							out[#out + 1] = { x, y }
						end

						twin(x, y, out)
					end
				end
			end

			local function scrub(m)
				for _, o in next, m:GetDescendants() do
					if o:IsA("BasePart") then
						o.Anchored = true
						o.CanCollide = false
						o.Massless = true
						o.CastShadow = false
						o.LocalTransparencyModifier = 0
					elseif o:IsA("Humanoid") then
						local motor = o:FindFirstChildOfClass("Animator")

						if motor then
							motor:Destroy()
						end

						pcall(function()
							o.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
							o.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
							o.NameDisplayDistance = 0
							o.HealthDisplayDistance = 0
							o.AutoRotate = false
							o.BreakJointsOnDeath = false
							o.RequiresNeck = false
							o.EvaluateStateMachine = false
							o.Health = o.MaxHealth
						end)
					elseif o:IsA("LuaSourceContainer") or o:IsA("Sound") or o:IsA("BodyMover") or o:IsA("Camera") or o:IsA("Fire") or o:IsA("Smoke") then
						o:Destroy()
					end
				end
			end
			local function stale()
				if not dirty then
					dirty = true
					dirty0 = os.clock()
				end

				wait0 = os.clock() + 0.35
			end

			local function raise()
				local char = lp.Character

				if not char or not char.Parent then
					return
				end

				local core = char.PrimaryPart
					or char:FindFirstChild("HumanoidRootPart")
					or char:FindFirstChild("UpperTorso")
					or char:FindFirstChild("Torso")
					or char:FindFirstChildWhichIsA("BasePart")

				if not core then
					return
				end

				local locked = {}
				local was = char.Archivable

				for _, o in next, char:GetDescendants() do
					if not o.Archivable then
						locked[#locked + 1] = o

						pcall(function()
							o.Archivable = true
						end)
					end
				end

				pcall(function()
					char.Archivable = true
				end)

				local ok, dup = pcall(function()
					return char:Clone()
				end)

				pcall(function()
					char.Archivable = was
				end)

				for _, o in next, locked do
					pcall(function()
						o.Archivable = false
					end)
				end

				if not ok or not dup then
					return
				end

				local map = {}

				twin(char, dup, map)
				scrub(dup)

				if #map == 0 then
					dup:Destroy()

					return
				end

				dup.Name = rnd()
				wipe()

				dup.Parent = host

				item.model = dup
				item.parts = map
				item.root = core

				local base = core.CFrame:Inverse()

				for i = 1, #map do
					local p = map[i]

					if p[1].Parent and p[2].Parent then
						p[2].CFrame = base * p[1].CFrame
					end
				end

				local okb, bcf, bsz = pcall(dup.GetBoundingBox, dup)

				if okb and typeof(bsz) == "Vector3" and bsz.Y > 0 then
					bounds = bsz
				end

				if okb and typeof(bcf) == "CFrame" then
					center = Vector3.new(0, bcf.Position.Y, 0)
					pivot = Vector3.new(0, center.Y - bounds.Y * 0.08, 0)
				end

				ready = true
				dirty = false

				fit()
				place()

				task.defer(nudge)

				watch = conn(char.DescendantAdded, function(o)
					if o:IsA("BasePart") or o:IsA("Accoutrement") or o:IsA("Clothing") or o:IsA("ShirtGraphic") or o:IsA("CharacterMesh") then
						stale()
					end
				end)

				if cfg.callback then
					callback(cfg.callback, dup, item)
				end
			end

			local function pose()
				local core = item.root

				if not core or not core.Parent then
					stale()

					return
				end

				local base = core.CFrame:Inverse()
				local map = item.parts

				for i = 1, #map do
					local p = map[i]
					local a, b = p[1], p[2]

					if a.Parent and b.Parent then
						b.CFrame = base * a.CFrame
					end
				end
			end

			conn(view:GetPropertyChangedSignal("AbsoluteSize"), function()
				fit()

				if ready then
					place()
				end
			end)

			conn(rs.RenderStepped, function(dt)
				local go = visualsui.alive and win.open and pg.Visible and rec.live and true or false

				if go ~= item.active then
					item.active = go

					if go then
						task.defer(nudge)
					else
						ping(0)
					end
				end

				if not go then
					return
				end

				if not ready or not item.model or not item.model.Parent then
					if os.clock() >= wait0 then
						wait0 = os.clock() + 0.4

						raise()
					end

					return
				end
				if dirty and (os.clock() >= wait0 or os.clock() - dirty0 >= 2) then
					wait0 = os.clock() + 0.4

					raise()
				end

				pose()

				if held then
					rest = 0
					drift = math.max(drift - dt * 7, 0)
				else
					rest += dt

					if rest > cfg.delay then
						drift = math.min(drift + dt / math.max(cfg.warm, 0.05), 1)
					end
				end

				if cfg.spin ~= 0 and drift > 0 then
					local k = drift * drift * (3 - 2 * drift)

					item.yaw = (item.yaw + cfg.spin * k * dt) % 360
				end

				place()
				ping(dt)
			end)

			conn(grab.InputBegan, function(i)
				if not cfg.rotate or held then
					return
				end

				if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
					return
				end

				held = true

				latch(1)

				col.frame.ScrollingEnabled = false

				visualsui:chime("tap")

				anim(ring, soft, { Transparency = 0.4 })

				local last = uis:GetMouseLocation()

				while held and (uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or i.UserInputState ~= Enum.UserInputState.End) do
					local now = uis:GetMouseLocation()
					local d = now - last

					last = now

					if d.X ~= 0 or d.Y ~= 0 then
						item.yaw = (item.yaw - d.X * cfg.sens) % 360
						item.pitch = math.clamp(item.pitch - d.Y * cfg.sens, -80, 80)

						if ready then
							place()
						end
					end

					task.wait()
				end

				held = false

				col.frame.ScrollingEnabled = true

				latch(-1)

				anim(ring, soft, { Transparency = 0.74 })
			end)

			conn(grab.InputEnded, function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					held = false
				end
			end)

			conn(uis.InputEnded, function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					held = false
				end
			end)

			conn(grab.MouseEnter, function()
				anim(ring, soft, { Transparency = 0.55 })
			end)

			conn(grab.MouseLeave, function()
				if not held then
					anim(ring, soft, { Transparency = 0.74 })
				end
			end)

			function item:set(y, p)
				if tonumber(y) then
					item.yaw = tonumber(y) % 360
				end

				if tonumber(p) then
					item.pitch = math.clamp(tonumber(p), -80, 80)
				end

				if ready then
					place()
				end
			end

			function item:get()
				return item.yaw, item.pitch, item.zoom
			end

			function item:setzoom(v)
				item.zoom = math.clamp(tonumber(v) or 1, 0.35, 4)

				if ready then
					place()
				end
			end

			function item:setspin(v)
				cfg.spin = tonumber(v) or 0
			end

			function item:setfov(v)
				cam.FieldOfView = math.clamp(tonumber(v) or 45, 10, 100)

				fit()

				if ready then
					place()
				end
			end

			function item:reset()
				item.yaw = tonumber(cfg.yaw) or 0
				item.pitch = math.clamp(tonumber(cfg.pitch) or 0, -80, 80)
				item.zoom = math.clamp(tonumber(cfg.zoom) or 1, 0.35, 4)

				fit()

				if ready then
					place()
				end
			end

			function item:refresh()
				wait0 = 0

				wipe()
			end

			function item:redraw()
				nudge()
			end

			function item:onrender(fn)
				if type(fn) ~= "function" then
					return function() end
				end

				table.insert(hooks, fn)

				return function()
					local at = table.find(hooks, fn)

					if at then
						table.remove(hooks, at)
					end
				end
			end

			function item:project(v3)
				if typeof(v3) ~= "Vector3" then
					return Vector2.new(), false
				end

				local x, y, front = cast(v3)

				if not front then
					return Vector2.new(), false
				end

				local at, sz = bay()

				return Vector2.new(x, y), x >= at.X and y >= at.Y and x <= at.X + sz.X and y <= at.Y + sz.Y
			end

			function item:rect(target, loose)
				local m = target or item.model

				if not item.active or not m or not m.Parent then
					return nil
				end

				local x1, y1, x2, y2 = math.huge, math.huge, -math.huge, -math.huge
				local hit = false

				local function chew(part)
					if part.Transparency >= 1 or part.Size.Magnitude <= 0 then
						return true
					end

					local half = part.Size * 0.5

					for i = 1, 8 do
						local x, y, front = cast(part.CFrame * (nooks[i] * half))

						if not front then
							return false
						end

						x1, y1 = math.min(x1, x), math.min(y1, y)
						x2, y2 = math.max(x2, x), math.max(y2, y)
					end

					hit = true

					return true
				end

				if m:IsA("BasePart") then
					if not chew(m) then
						return nil
					end
				elseif m == item.model then
					local map = item.parts

					for i = 1, #map do
						local part = map[i][2]

						if part.Parent and not chew(part) then
							return nil
						end
					end
				else
					for _, o in next, m:GetDescendants() do
						if o:IsA("BasePart") and not chew(o) then
							return nil
						end
					end
				end

				if not hit then
					return nil
				end

				if not loose then
					local at, sz = bay()

					x1, y1 = math.max(x1, at.X), math.max(y1, at.Y)
					x2, y2 = math.min(x2, at.X + sz.X), math.min(y2, at.Y + sz.Y)

					if x2 - x1 < 1 or y2 - y1 < 1 then
						return nil
					end
				end

				return x1, y1, x2 - x1, y2 - y1
			end

			function item:onscreen()
				local at, sz = bay()

				return at, sz, item.active
			end

			if cfg.reset then
				local nib = new("ImageButton", {
					Name = rnd(),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -8, 0.5, 0),
					Size = UDim2.fromOffset(20, 20),
					BackgroundColor3 = th.head,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Image = icon("refresh-cw"),
					ImageColor3 = th.dim,
					ImageTransparency = 0.25,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 8,
				}, strip)

				round(nib, 5)

				conn(nib.MouseEnter, function()
					anim(nib, soft, { ImageTransparency = 0, ImageColor3 = th.text, BackgroundTransparency = 0.4 })
				end)

				conn(nib.MouseLeave, function()
					anim(nib, soft, { ImageTransparency = 0.25, ImageColor3 = th.dim, BackgroundTransparency = 1 })
				end)

				conn(nib.MouseButton1Click, function()
					nib.ImageColor3 = th.accent

					anim(nib, soft, { ImageColor3 = th.dim })

					visualsui:chime("tap")

					item:reset()
					item:refresh()
				end)
			end

			conn(lp.CharacterAdded, stale)

			conn(lp.CharacterRemoving, stale)

			return item
		end

		return api
	end

	local function board(trail)
		local pg = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = 4,
		}, pages)

		return pg, attach(pg, trail)
	end

	local function pick(t)
		if live == t then
			return
		end

		if live then
			live.hit(false)

			visualsui:chime("tab")
		end

		live = t
		win.active = t
		t.hit(true)
	end

	local function row(parent, cfg, depth, ord)
		local deep = depth > 0
		local tall = (cfg.tip ~= "" and (deep and 32 or 40)) or (deep and 24 or 30)
		local pad = 8 + depth * 9
		local isz = deep and 13 or 16
		local tx = pad + isz + 7
		local r = { pad = 8 }

		r.head = new("Frame", {
			Name = rnd(),
			Size = UDim2.new(1, 0, 0, tall),
			BackgroundColor3 = th.side,
			BackgroundTransparency = 0.06,
			BorderSizePixel = 0,
			LayoutOrder = ord,
			ZIndex = 7,
		}, parent)

		round(r.head, 6)

		r.edge = new("UIStroke", { Color = th.line, Transparency = 1 }, r.head)

		r.tint = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = th.panel,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 7,
		}, r.head)

		round(r.tint, 6)

		fade(r.tint, 0, {
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.7, 0.25),
			NumberSequenceKeypoint.new(1, 0.55),
		})

		r.bar = new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 1, 0.5, 0),
			Size = UDim2.new(0, 3, 0, 0),
			BackgroundColor3 = th.accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 8,
		}, r.head)

		new("UICorner", { CornerRadius = UDim.new(1, 0) }, r.bar)

		r.img = new("ImageLabel", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, pad, 0.5, 0),
			Size = UDim2.fromOffset(isz, isz),
			BackgroundTransparency = 1,
			Image = icon(cfg.icon),
			ImageColor3 = th.dim,
			ImageTransparency = 0.35,
			ZIndex = 8,
		}, r.head)

		if cfg.tip ~= "" then
			r.nm = new("TextLabel", {
				Name = rnd(),
				Position = UDim2.new(0, tx, 0, deep and 3 or 5),
				Size = UDim2.new(1, -tx - r.pad, 0, deep and 14 or 16),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = cfg.name,
				TextColor3 = th.dim,
				TextSize = deep and 12 or 13,
				TextTransparency = 0.4,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 8,
			}, r.head)

			r.ds = new("TextLabel", {
				Name = rnd(),
				Position = UDim2.new(0, tx, 0, deep and 16 or 21),
				Size = UDim2.new(1, -tx - r.pad, 0, 11),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = cfg.tip,
				TextColor3 = th.dim,
				TextSize = 9,
				TextTransparency = 0.7,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 8,
			}, r.head)
		else
			r.nm = new("TextLabel", {
				Name = rnd(),
				Position = UDim2.new(0, tx, 0, 0),
				Size = UDim2.new(1, -tx - r.pad, 1, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = cfg.name,
				TextColor3 = th.dim,
				TextSize = deep and 12 or 13,
				TextTransparency = 0.4,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 8,
			}, r.head)
		end

		r.btn = new("ImageButton", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			ZIndex = 9,
		}, r.head)

		function r.reserve(px)
			r.pad = px
			r.nm.Size = UDim2.new(1, -tx - px, r.nm.Size.Y.Scale, r.nm.Size.Y.Offset)

			if r.ds then
				r.ds.Size = UDim2.new(1, -tx - px, 0, 11)
			end
		end

		function r.paint(sel)
			r.sel = sel

			anim(r.tint, soft, { BackgroundTransparency = sel and 0.12 or 1 })
			anim(r.edge, soft, { Transparency = sel and 0.72 or 1 })
			anim(r.bar, soft, { Size = UDim2.new(0, 3, 0, sel and math.floor(tall * 0.55) or 0), BackgroundTransparency = sel and 0.05 or 1 })
			anim(r.img, soft, { ImageTransparency = sel and 0 or 0.35, ImageColor3 = sel and th.text or th.dim })
			anim(r.nm, soft, { TextTransparency = sel and 0 or 0.4, TextColor3 = sel and th.text or th.dim })

			if r.ds then
				anim(r.ds, soft, { TextTransparency = sel and 0.4 or 0.7 })
			end
		end

		conn(r.head.MouseEnter, function()
			if not r.sel then
				anim(r.tint, soft, { BackgroundTransparency = 0.55 })
				anim(r.nm, soft, { TextTransparency = 0.15 })
				anim(r.img, soft, { ImageTransparency = 0.15 })
			end
		end)

		conn(r.head.MouseLeave, function()
			if not r.sel then
				anim(r.tint, soft, { BackgroundTransparency = 1 })
				anim(r.nm, soft, { TextTransparency = 0.4 })
				anim(r.img, soft, { ImageTransparency = 0.35 })
			end
		end)

		return r
	end

	function win:tab(cfg)
		cfg = params(cfg, {
			name = "tab",
			icon = "",
			tip = "",
			open = false,
		})

		order += 1

		local holder = new("Frame", {
			Name = rnd(),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = order,
			ZIndex = 7,
		}, tabs)

		new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		}, holder)

		local r = row(holder, cfg, 0, 1)

		local arrow = new("ImageLabel", {
			Name = rnd(),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -7, 0.5, 0),
			Size = UDim2.fromOffset(13, 13),
			BackgroundTransparency = 1,
			Image = icon("chevron-down"),
			ImageColor3 = th.dim,
			ImageTransparency = 1,
			Rotation = 0,
			Visible = false,
			ZIndex = 8,
		}, r.head)

		local kids = new("Frame", {
			Name = rnd(),
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			LayoutOrder = 2,
			ZIndex = 7,
		}, holder)

		local klist = new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		}, kids)

		local pg, px = board(cfg.name)

		local tab = {
			name = cfg.name,
			page = pg,
			subs = {},
			open = false,
			head = r.head,
		}

		function tab:section(c)
			return px:section(c)
		end

		function tab:color(c)
			return px:color(c)
		end

		function tab:configs(c)
			return px:configs(c)
		end

		function tab:clone(c)
			return px:clone(c)
		end

		function tab:gallery(c)
			return px:gallery(c)
		end

		tab.hit = function(sel)
			r.paint(sel)

			if sel then
				pg.Visible = true

				px.reveal()
			else
				pg.Visible = false

				px.settle()
			end
		end

		local function fit(instant)
			local h1 = tab.open and acs(klist).Y or 0

			if instant then
				kids.Size = UDim2.new(1, 0, 0, h1)

				return
			end

			local h0 = kids.Size.Y.Offset

			flow(kids, 0.34, tab.open and outq or inq, function(k)
				kids.Size = UDim2.new(1, 0, 0, h0 + (h1 - h0) * k)
			end)

		end

		conn(klist:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			if tab.open then
				fit(true)
			end
		end)

		function tab:setopen(v)
			tab.open = v and true or false

			fit(false)

			local r0, r1 = arrow.Rotation, tab.open and 180 or 0

			flow(arrow, 0.36, outq, function(k)
				arrow.Rotation = r0 + (r1 - r0) * k
			end)
		end

		function tab:select()
			pick(tab)
		end

		function tab:sub(scfg)
			scfg = params(scfg, {
				name = "sub",
				icon = "",
				tip = "",
			})

			local sr = row(kids, scfg, 1, #tab.subs + 1)

			local spg, spx = board(cfg.name .. "|" .. scfg.name)

			local sub = {
				name = scfg.name,
				page = spg,
				head = sr.head,
			}

			function sub:section(c)
				return spx:section(c)
			end

			function sub:color(c)
				return spx:color(c)
			end

			function sub:configs(c)
				return spx:configs(c)
			end

			function sub:clone(c)
				return spx:clone(c)
			end

			function sub:gallery(c)
				return spx:gallery(c)
			end

			sub.hit = function(sel)
				sr.paint(sel)

				if sel then
					spg.Visible = true

					spx.reveal()
				else
					spg.Visible = false

					spx.settle()
				end
			end

			function sub:select()
				pick(sub)
			end

			conn(sr.btn.MouseButton1Click, function()
				pick(sub)
			end)

			table.insert(tab.subs, sub)

			if not arrow.Visible then
				arrow.Visible = true
				r.reserve(26)
				anim(arrow, soft, { ImageTransparency = 0.35 })
			end

			if cfg.open and not tab.open then
				tab:setopen(true)
			end

			return sub
		end

		conn(r.btn.MouseButton1Click, function()
			if #tab.subs > 0 then
				local wasOpen = tab.open
				tab:setopen(not wasOpen)

				if wasOpen then
					return
				end
			end

			pick(tab)
		end)

		if not live then
			pick(tab)
		end

		table.insert(win.list, tab)

		return tab
	end

	bgnet:mark(split)

	drag(grip, shell, 0.14)

	win.shell = shell
	win.root = root
	win.side = side
	win.body = body
	win.pages = pages
	win.tabs = tabs
	win.net = bgnet

	function win:mark(o)
		bgnet:mark(o)
	end

	function win:render(v)
		win.open = v and true or false

		local from = root.GroupTransparency
		local to = win.open and 0 or 1

		visualsui.shown = win.open
		visualsui:chime(win.open and "open" or "close")
		visualsui:wake()

		if not win.open then

			local ride = rides[root]

			if ride then
				ride:Disconnect()
				rides[root] = nil
			end

			root.GroupTransparency = 1

			for i, s in next, aura do
				s.Transparency = 1
			end

			shell.Visible = false
			bgnet.on = false

			return
		end

		shell.Visible = true
		bgnet.on = true

		flow(root, 0.34, outq, function(k)
			local a = from + (to - from) * k

			root.GroupTransparency = a

			for i, s in next, aura do
				s.Transparency = halo[i] + (1 - halo[i]) * a
			end
		end)
	end

	function win:toggle()
		win:render(not win.open)
	end

	function win:setlogo(v)
		logo.Image = tostring(v)
	end

	function win:setsize(v)
		win.size = v

		if win.open then
			anim(shell, med, { Size = v })
		else
			shell.Size = v
		end
	end

	function win:setbind(v)
		if typeof(v) == "EnumItem" then
			win.bind = v
			bindMenuAction()

			return
		end

		if type(v) == "string" then
			local ok, k = pcall(function()
				return Enum.KeyCode[v]
			end)

			if ok and typeof(k) == "EnumItem" then
				win.bind = k
				bindMenuAction()
			end
		end
	end

	bindMenuAction()
	conn(shell.Destroying, function()
		pcall(function() ContextActionService:UnbindAction(bindActionName) end)
	end)

	conn(body.MouseEnter, function()
		visualsui.hover = true
	end)

	conn(body.MouseLeave, function()
		visualsui.hover = false
	end)

	table.insert(visualsui.wins, win)
	task.defer(win.render, win, true)

	return win
end

visualsui.browsers = {}

local shade = supports("UIShadow")

local decoder = nil

local function unb64(s)
	if decoder then
		local ok, res = pcall(decoder, s)

		return (ok and type(res) == "string") and res or nil
	end

	local env = getgenv()

	for _, fn in next, {
		crypt and crypt.base64decode,
		crypt and crypt.base64 and crypt.base64.decode,
		crypt and crypt.base64_decode,
		env.base64 and env.base64.decode,
		env.base64_decode,
		env.base64decode,
	} do
		if type(fn) == "function" then
			local ok, res = pcall(fn, s)

			if ok and type(res) == "string" then
				decoder = fn

				return res
			end
		end
	end

	return nil
end

local function socket(url)
	local env = getgenv()

	for _, fn in next, {
		env.WebSocket and env.WebSocket.connect,
		env.syn and env.syn.websocket and env.syn.websocket.connect,
		env.websocket and env.websocket.connect,
	} do
		if type(fn) == "function" then
			local ok, res = pcall(fn, url)

			if ok and res then
				return res
			end
		end
	end

	return nil
end

function visualsui:browser(cfg)
	local th = visualsui.theme

	cfg = params(cfg, {
		name = "browser",
		url = "https://inertiahub.xyz",
		size = Vector2.new(580, 430),
		min = Vector2.new(340, 260),
		host = "ws://127.0.0.1:8787",
		fps = 30,
		retry = 3,
		callback = nil,
	})

	local wide = math.max(math.floor(cfg.size.X), cfg.min.X)
	local high = math.max(math.floor(cfg.size.Y), cfg.min.Y)

	local shell = new("Frame", {
		Name = rnd(),
		Active = true,
		Position = UDim2.new(0.5, -math.floor(wide * 0.5), 0.5, -math.floor(high * 0.5)),
		Size = UDim2.fromOffset(wide, high),
		BackgroundColor3 = th.bg,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 60,
	}, scr)

	shrink(shell)

	round(shell, 9)

	new("UIStroke", { Color = th.line, Transparency = 0.55 }, shell)

	if shade then
		new("UIShadow", {
			Color = th.bg,
			BlurRadius = UDim.new(0, 26),
			Offset = UDim2.fromOffset(0, 6),
			Spread = UDim2.fromOffset(-4, -4),
			Transparency = 0.4,
			ZIndex = -1,
		}, shell)
	end

	local head = new("Frame", {
		Name = rnd(),
		Active = true,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = th.head,
		BorderSizePixel = 0,
		ZIndex = 61,
	}, shell)

	round(head, 9)

	new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 9),
		BackgroundColor3 = th.head,
		BorderSizePixel = 0,
		ZIndex = 61,
	}, head)

	local rule = new("Frame", {
		Name = rnd(),
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = th.accent,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ZIndex = 62,
	}, shell)

	fade(rule, 0, {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.12, 0.2),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.88, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})

	local function nib(x, art, side)
		local b = new("ImageButton", {
			Name = rnd(),
			AnchorPoint = Vector2.new(side and 1 or 0, 0.5),
			Position = UDim2.new(side and 1 or 0, x, 0.5, 0),
			Size = UDim2.fromOffset(22, 22),
			BackgroundColor3 = th.panel,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = icon(art),
			ImageColor3 = th.dim,
			ImageTransparency = 0.25,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 63,
		}, head)

		round(b, 6)

		conn(b.MouseEnter, function()
			anim(b, soft, { ImageTransparency = 0, ImageColor3 = th.text, BackgroundTransparency = 0.35 })
		end)

		conn(b.MouseLeave, function()
			anim(b, soft, { ImageTransparency = 0.25, ImageColor3 = th.dim, BackgroundTransparency = 1 })
		end)

		return b
	end

	local rear = nib(8, "chevron-right")
	local fore = nib(32, "chevron-right")
	local spin = nib(56, "refresh-cw")
	local shut = nib(-8, "x", true)

	rear.Rotation = 180

	local bar = new("TextBox", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 82, 0.5, 0),
		Size = UDim2.new(1, -118, 0, 24),
		BackgroundColor3 = th.bg,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Enum.Font.GothamMedium,
		PlaceholderText = "type a link",
		PlaceholderColor3 = th.dim,
		Text = cfg.url,
		TextColor3 = th.text,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 63,
	}, head)

	round(bar, 6)

	pcall(function()
		bar.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Medium)
	end)

	new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }, bar)

	local brim = new("UIStroke", { Color = th.line, Transparency = 0.6 }, bar)

	local stage = new("Frame", {
		Name = rnd(),
		Position = UDim2.fromOffset(8, 42),
		Size = UDim2.new(1, -16, 1, -68),
		BackgroundColor3 = th.bg,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 61,
	}, shell)

	round(stage, 7)

	new("UIStroke", { Color = th.line, Transparency = 0.72 }, stage)

	local sheet = new("ImageLabel", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "",
		ImageTransparency = 1,
		ResampleMode = Enum.ResamplerMode.Default,
		ScaleType = Enum.ScaleType.Stretch,
		ZIndex = 62,
	}, stage)

	round(sheet, 7)

	local note = new("TextLabel", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -40, 0, 40),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "host offline",
		TextColor3 = th.dim,
		TextSize = 12,
		TextTransparency = 0.25,
		TextWrapped = true,
		ZIndex = 63,
	}, stage)

	local veil = new("ImageButton", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ImageTransparency = 1,
		ZIndex = 64,
	}, stage)

	local keys = new("TextBox", {
		Name = rnd(),
		Position = UDim2.fromOffset(-40, -40),
		Size = UDim2.fromOffset(10, 10),
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Text = "",
		TextTransparency = 1,
		ZIndex = 61,
	}, shell)

	local foot = new("TextLabel", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -6),
		Size = UDim2.new(1, -46, 0, 14),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "idle",
		TextColor3 = th.dim,
		TextSize = 11,
		TextTransparency = 0.3,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 62,
	}, shell)

	local grip = new("ImageButton", {
		Name = rnd(),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -4, 1, -4),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Image = icon("move"),
		ImageColor3 = th.dim,
		ImageTransparency = 0.45,
		Rotation = 45,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 63,
	}, shell)

	local api = {
		shell = shell,
		stage = stage,
		image = sheet,
		url = cfg.url,
		open = false,
		live = false,
		host = cfg.host,
	}

	local sock, ed, want, hot, tick, moved = nil, nil, Vector2.zero, false, 0, 0
	local browserGeneration, killed, dialing = 0, false, false
	local socketConnections = {}
	local asvc = nil
	local mist, ghost = {}, nil

	local function tally(o)
		if o:IsA("UIStroke") or o:IsA("UIShadow") then
			table.insert(mist, { o = o, k = "Transparency", b = o.Transparency })
		elseif o:IsA("TextLabel") or o:IsA("TextBox") or o:IsA("TextButton") then
			table.insert(mist, { o = o, k = "BackgroundTransparency", b = o.BackgroundTransparency })
			table.insert(mist, { o = o, k = "TextTransparency", b = o.TextTransparency })
		elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then
			table.insert(mist, { o = o, k = "BackgroundTransparency", b = o.BackgroundTransparency })

			local rec = { o = o, k = "ImageTransparency", b = o.ImageTransparency }

			table.insert(mist, rec)

			if o == sheet then
				ghost = rec
			end
		elseif o:IsA("GuiObject") then
			table.insert(mist, { o = o, k = "BackgroundTransparency", b = o.BackgroundTransparency })
		end
	end

	local function mask(a)
		for i = 1, #mist do
			local r = mist[i]

			if r.o.Parent then
				r.o[r.k] = r.b + (1 - r.b) * a
			end
		end
	end

	pcall(function()
		asvc = cloneref(game:GetService("AssetService"))
	end)

	local function tell(txt)
		if foot.Text ~= txt then
			foot.Text = txt
		end
	end

	local function push(msg)
		if not sock then
			return false
		end

		local ok = pcall(function()
			sock:Send(msg)
		end)

		if not ok then
			api.live = false
		end

		return ok
	end

	local function canvas(w, h)
		if killed or not api.open or type(w) ~= "number" or type(h) ~= "number" or w < 1 or h < 1 or w > 1024 or h > 1024 or w % 1 ~= 0 or h % 1 ~= 0 then return false end
		if not asvc then
			return false
		end

		local ok, res = pcall(function()
			return asvc:CreateEditableImage({ Size = Vector2.new(w, h) })
		end)

		if not ok or not res then
			return false
		end

		local bound = pcall(function()
			sheet.ImageContent = Content.fromObject(res)
		end)

		if not bound then
			bound = pcall(function()
				res.Parent = sheet
			end)
		end

		if not bound then
			pcall(function()
				res:Destroy()
			end)

			return false
		end

		if ed then
			pcall(function()
				ed:Destroy()
			end)
		end

		ed = res
		want = Vector2.new(w, h)

		sheet.ImageTransparency = 0
		note.Visible = false

		return true
	end

	local function blit(x, y, w, h, blob)
		if killed or not api.open or not x or not y or not w or not h or x < 0 or y < 0 or w < 1 or h < 1
			or x % 1 ~= 0 or y % 1 ~= 0 or w % 1 ~= 0 or h % 1 ~= 0 or x+w > want.X or y+h > want.Y or type(blob) ~= "string" or #blob > 8*1024*1024 then return end
		if not ed then
			return
		end

		local raw = unb64(blob)
		local need = w * h * 4

		if not raw or #raw < need then
			return
		end

		if #raw > need then
			raw = string.sub(raw, 1, need)
		end

		pcall(function()
			ed:WritePixelsBuffer(Vector2.new(x, y), Vector2.new(w, h), buffer.fromstring(raw))
		end)
	end

	local function fitted()
		local s = stage.AbsoluteSize
		local w = math.clamp(math.floor(s.X / 8) * 8, 128, 1024)
		local h = math.clamp(math.floor(s.Y / 8) * 8, 128, 1024)

		return w, h
	end

	local function relay()
		local w, h = fitted()

		if want.X ~= w or want.Y ~= h then
			push("size\1" .. w .. "\1" .. h)
		end
	end

	local function eat(msg)
		if killed or not visualsui.alive or not api.open or type(msg) ~= "string" or #msg > 8*1024*1024 then return end
		local kind = string.match(msg, "^(%a+)")

		if kind == "f" then
			local x, y, w, h, blob = string.match(msg, "^f\1(%-?%d+)\1(%-?%d+)\1(%d+)\1(%d+)\1(.*)$")

			if blob then
				blit(tonumber(x), tonumber(y), tonumber(w), tonumber(h), blob)
			end
		elseif kind == "s" then
			local w, h = string.match(msg, "^s\1(%d+)\1(%d+)$")

			if w then
				canvas(tonumber(w), tonumber(h))
			end
		elseif kind == "u" then
			local u = string.sub(msg, 3)

			api.url = u

			if not bar:IsFocused() then
				bar.Text = u
			end
		elseif kind == "t" then
			tell(string.sub(msg, 3))
		elseif kind == "e" then
			tell(string.sub(msg, 3))
		end
	end

	local function drop()
		browserGeneration += 1
		dialing = false
		for _, connection in ipairs(socketConnections) do connection:Disconnect() end
		table.clear(socketConnections)
		if sock then
			local dead = sock

			sock = nil

			pcall(function()
				dead:Close()
			end)
		end

		api.live = false
		want = Vector2.zero

		if ed then
			pcall(function()
				ed:Destroy()
			end)

			ed = nil
		end

		sheet.ImageTransparency = 1
		note.Visible = true
	end

	local function dial()
		if sock or dialing or killed or not visualsui.alive or not api.open then
			return
		end

		note.Text = "connecting to " .. api.host
		note.Visible = true
		local generation = browserGeneration
		dialing = true

		local s = socket(api.host)
		if generation ~= browserGeneration or killed or not visualsui.alive or not api.open then if s then pcall(function() s:Close() end) end; return end
		dialing = false

		if not s then
			note.Text = "no host at " .. api.host .. "\nstart webhost.py and reopen"

			return
		end

		sock = s
		api.live = true

		pcall(function()
			socketConnections[#socketConnections+1] = s.OnMessage:Connect(function(msg) if sock == s then eat(msg) end end)
		end)

		pcall(function()
			socketConnections[#socketConnections+1] = s.OnClose:Connect(function()
				if sock == s then
					drop()

					note.Text = "host closed the link"
				end
			end)
		end)

		local w, h = fitted()

		push("fps\1" .. math.clamp(math.floor(cfg.fps), 1, 60))
		push("size\1" .. w .. "\1" .. h)
		push("nav\1" .. api.url)

		tell("linked")
	end

	local function place()
		local m = uis:GetMouseLocation()
		local at = sheet.AbsolutePosition + inset()
		local sz = sheet.AbsoluteSize

		if sz.X < 1 or sz.Y < 1 then
			return nil
		end

		return math.clamp((m.X - at.X) / sz.X, 0, 1), math.clamp((m.Y - at.Y) / sz.Y, 0, 1)
	end

	function api:go(u)
		u = tostring(u or "")

		if not string.match(u, "%S") then
			return
		end

		if not string.find(u, "://", 1, true) then
			u = (string.find(u, "%.") and not string.find(u, "%s")) and ("https://" .. u) or ("https://www.google.com/search?q=" .. (string.gsub(u, "%s+", "+")))
		end
		if not u:match("^https?://") or #u > 4096 then return false end

		api.url = u
		bar.Text = u

		tell("loading")
		push("nav\1" .. u)
	end

	function api:render(v)
		if killed or not visualsui.alive then return end
		v = v and true or false

		if api.open == v then
			return
		end

		api.open = v
		browserGeneration += 1
		local generation = browserGeneration

		visualsui:chime(v and "open" or "close")

		if ghost then
			ghost.b = sheet.ImageTransparency
		end

		if v then
			mask(1)

			shell.Visible = true

			task.defer(dial)

			flow(shell, 0.34, outq, function(k)
				mask(1 - k)
			end)
		else
			flow(shell, 0.26, inq, function(k)
				mask(k)

				if k >= 1 then
					shell.Visible = false

					mask(0)
				end
			end)

			task.delay(0.26, function() if generation == browserGeneration and not api.open and not killed then drop() end end)
		end

		if cfg.callback then
			callback(cfg.callback, v)
		end
	end

	function api:toggle()
		api:render(not api.open)
	end

	function api:sethost(v)
		api.host = tostring(v or api.host)

		if api.open then
			drop()
			task.defer(dial)
		end
	end

	function api:kill()
		if killed then return end
		killed, api.open = true, false
		drop()
		local index = table.find(visualsui.browsers, api)
		if index then table.remove(visualsui.browsers,index) end

		shell:Destroy()
	end

	conn(shut.MouseButton1Click, function()
		api:render(false)
	end)

	conn(rear.MouseButton1Click, function()
		visualsui:chime("flip")

		push("back")
	end)

	conn(fore.MouseButton1Click, function()
		visualsui:chime("flip")

		push("fwd")
	end)

	conn(spin.MouseButton1Click, function()
		visualsui:chime("tap")

		push("reload")
	end)

	conn(bar.FocusLost, function(enter)
		anim(brim, soft, { Transparency = 0.6 })

		if enter then
			api:go(bar.Text)
		end
	end)

	conn(bar.Focused, function()
		anim(brim, soft, { Transparency = 0.3 })
	end)

	conn(veil.MouseButton1Click, function()
		local x, y = place()

		if x then
			visualsui:chime("tap")

			push("click\1" .. string.format("%.5f\1%.5f", x, y) .. "\1l")

			pcall(function()
				keys:CaptureFocus()
			end)
		end
	end)

	conn(veil.MouseButton2Click, function()
		local x, y = place()

		if x then
			push("click\1" .. string.format("%.5f\1%.5f", x, y) .. "\1r")
		end
	end)

	conn(veil.InputChanged, function(i)
		if not api.live then
			return
		end

		if i.UserInputType == Enum.UserInputType.MouseWheel then
			local x, y = place()

			if x then
				push("wheel\1" .. string.format("%.5f\1%.5f", x, y) .. "\1" .. (i.Position.Z > 0 and -120 or 120))
			end

			return
		end

		if i.UserInputType == Enum.UserInputType.MouseMovement then
			local now = os.clock()

			if now - moved < 0.06 then
				return
			end

			moved = now

			local x, y = place()

			if x then
				push("move\1" .. string.format("%.5f\1%.5f", x, y))
			end
		end
	end)

	conn(veil.InputBegan, function(i)
		if i.UserInputType ~= Enum.UserInputType.Touch or not api.live then
			return
		end

		local last = uis:GetMouseLocation()
		local born = os.clock()
		local slid = 0

		while i.UserInputState ~= Enum.UserInputState.End do
			local now = uis:GetMouseLocation()
			local d = now - last

			if math.abs(d.Y) >= 2 then
				local x, y = place()

				if x then
					push("wheel\1" .. string.format("%.5f\1%.5f", x, y) .. "\1" .. math.floor(-d.Y * 3))
				end

				slid += math.abs(d.Y)
				last = now
			end

			task.wait()
		end

		if slid < 6 and os.clock() - born < 0.5 then
			local x, y = place()

			if x then
				push("click\1" .. string.format("%.5f\1%.5f", x, y) .. "\1l")
			end
		end
	end)

	conn(keys:GetPropertyChangedSignal("Text"), function()
		local txt = keys.Text

		if txt == "" or not api.live then
			return
		end

		keys.Text = ""

		push("text\1" .. txt)
	end)

	conn(uis.InputBegan, function(i, typing)
		if not api.open or not api.live or not keys:IsFocused() then
			return
		end

		local name = keyname(i.KeyCode)

		if name == "Enter" or name == "Bksp" or name == "Tab" or name == "Del" or name == "Up" or name == "Down" or name == "Left" or name == "Right" then
			push("key\1" .. name)
		end
	end)

	conn(grip.InputBegan, function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		if hot then
			return
		end

		hot = true

		latch(1)

		local start = uis:GetMouseLocation()
		local base = asz(shell)
		local w0, h0 = base.X, base.Y
		local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)) / sc

		anim(grip, soft, { ImageTransparency = 0, ImageColor3 = th.text })

		while hot and (uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or i.UserInputState ~= Enum.UserInputState.End) do
			local d = (uis:GetMouseLocation() - start) / sc

			shell.Size = UDim2.fromOffset(
				math.clamp(w0 + d.X, cfg.min.X, math.max(cfg.min.X, vp.X - 16)),
				math.clamp(h0 + d.Y, cfg.min.Y, math.max(cfg.min.Y, vp.Y - 16))
			)

			task.wait()
		end

		hot = false

		latch(-1)

		anim(grip, soft, { ImageTransparency = 0.45, ImageColor3 = th.dim })

		relay()
	end)

	conn(grip.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			hot = false
		end
	end)

	conn(rs.Heartbeat, function()
		if not api.open then
			return
		end

		local now = os.clock()

		if now - tick < cfg.retry then
			return
		end

		tick = now

		if not sock then
			dial()
		elseif not hot then
			relay()
		end
	end)

	tally(shell)

	for _, o in next, shell:GetDescendants() do
		tally(o)
	end

	mask(1)

	drag(head, shell, 0.1)

	table.insert(visualsui.browsers, api)

	return api
end

local popper = nil

function visualsui:closepopup()
	if popper then
		popper.kill()
		popper = nil
	end
end

function visualsui:popup(cfg)
	cfg = type(cfg) == "table" and cfg or {}

	local rows = type(cfg.items) == "table" and cfg.items or {}
	local sliders = {}
	for _, slider in ipairs(type(cfg.sliders) == "table" and cfg.sliders or {}) do
		if type(slider) == "table" and #sliders < 8 then sliders[#sliders + 1] = slider end
	end
	if #sliders == 0 and type(cfg.slider) == "table" then sliders[1] = cfg.slider end
	local popupConnections = {}
	local function conn(signal, fn)
		local connection = signal:Connect(fn)
		popupConnections[#popupConnections + 1] = connection
		return connection
	end

	visualsui:closepopup()

	if (#rows == 0 and #sliders == 0) or not visualsui.alive then
		return
	end

	local vs = scr.AbsoluteSize
	local room = vs / sc
	local wide = math.clamp(math.floor(tonumber(cfg.width) or 170), 140, math.max(math.floor(room.X) - 24, 140))
	local crown = 32
	local body = #rows * 27 + 14 + #sliders * 48
	local tall = math.clamp(crown + body, 64, math.max(math.floor(room.Y) - 24, 64))
	local m = uis:GetMouseLocation()
	local ax = math.floor(tonumber(cfg.x) or m.X)
	local ay = math.floor(tonumber(cfg.y) or m.Y)
	local px = math.clamp(ax, 8, math.max(vs.X - wide * sc - 8, 8))
	local py = math.clamp(ay, 8, math.max(vs.Y - tall * sc - 8, 8))

	local pit = deep and new("Frame", {
		Name = rnd(),
		Position = UDim2.fromOffset(px, py),
		Size = UDim2.fromOffset(wide, tall),
		BackgroundColor3 = th.panel,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 399,
	}, scr) or nil

	local cast = pit and new("UIShadow", {
		Color = th.bg,
		BlurRadius = UDim.new(0, 14),
		Offset = UDim2.fromOffset(0, 4),
		Spread = UDim2.fromOffset(-2, -2),
		Transparency = 1,
		ZIndex = -1,
	}, pit) or nil

	if pit then
		round(pit, 7)
		shrink(pit)
	end

	local husk = new("CanvasGroup", {
		Name = cfg.name or rnd(),
		Position = UDim2.fromOffset(px, py),
		Size = UDim2.fromOffset(wide, tall),
		BackgroundColor3 = th.panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		GroupTransparency = 1,
		ZIndex = 400,
	}, scr)

	round(husk, 7)
	shrink(husk)

	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(178, 178, 190)),
		}),
	}, husk)

	local brim = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 406,
	}, husk)

	round(brim, 7)

	new("UIStroke", { Color = th.line, Transparency = 0.6 }, brim)

	local pane = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 401,
	}, husk)

	local cap = new("Frame", {
		Name = rnd(),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = th.head,
		BorderSizePixel = 0,
		ZIndex = 401,
	}, pane)

	round(cap, 7)

	new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 8),
		BackgroundColor3 = th.head,
		BorderSizePixel = 0,
		ZIndex = 401,
	}, cap)

	new("ImageLabel", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		Image = icon(cfg.icon or "ellipsis"),
		ImageColor3 = th.dim,
		ImageTransparency = 0.3,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 402,
	}, cap)

	new("TextLabel", {
		Name = rnd(),
		Position = UDim2.fromOffset(28, 0),
		Size = UDim2.new(1, -36, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = tostring(cfg.title or ""),
		TextColor3 = th.text,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 402,
	}, cap)

	local rule = new("Frame", {
		Name = rnd(),
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = th.accent,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ZIndex = 402,
	}, pane)

	fade(rule, 0, {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.12, 0.2),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.88, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})

	local roll = new("ScrollingFrame", {
		Name = rnd(),
		Active = false,
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 1, -32),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 401,
	}, pane)

	local slab = new("Frame", {
		Name = rnd(),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 401,
	}, roll)

	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 1),
	}, slab)

	new("UIPadding", {
		PaddingTop = UDim.new(0, 5),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 5),
		PaddingRight = UDim.new(0, 5),
	}, slab)

	local rec = { alive = true, frame = husk, release = {}, sliders = {} }

	local function shut(done)
		local from = husk.GroupTransparency

		flow(husk, 0.26, inq, function(k)
			local a = from + (1 - from) * k

			husk.GroupTransparency = a
			husk.Position = UDim2.fromOffset(px, py + math.floor(7 * k + 0.5))

			if pit then
				pit.BackgroundTransparency = a
				pit.Position = husk.Position
				cast.Transparency = 0.4 + 0.6 * a
			end

			if k >= 1 then
				husk.Visible = false

				if pit then
					pit.Visible = false
				end

				if done then
					done()
				end
			end
		end)
	end

	function rec.kill()
		if not rec.alive then
			return
		end

		rec.alive = false
		for _, finish in ipairs(rec.release) do finish() end
		for _, connection in ipairs(popupConnections) do connection:Disconnect() end
		table.clear(popupConnections)

		if rec.watch then
			pcall(function()
				rec.watch:Disconnect()
			end)

			rec.watch = nil
		end

		if rec.spin then
			pcall(function()
				rec.spin:Disconnect()
			end)

			rec.spin = nil
		end

		if rec.trail then
			pcall(function()
				rec.trail:Disconnect()
			end)

			rec.trail = nil
		end

		if not visualsui.alive or not husk.Parent then
			husk:Destroy()
			if pit then pit:Destroy() end
			return
		end
		shut(function()
			pcall(function()
				husk:Destroy()
			end)

			if pit then
				pcall(function()
					pit:Destroy()
				end)
			end
		end)
	end

	conn(husk.Destroying, rec.kill)
	for i = 1, #rows do
		local r = rows[i]
		local flip = r.on ~= nil
		local live = r.on == true

		local row = new("Frame", {
			Name = rnd(),
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = i,
			ZIndex = 402,
		}, slab)

		local box = flip and new("Frame", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 5, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = th.accent,
			BackgroundTransparency = live and 0.05 or 1,
			BorderSizePixel = 0,
			ZIndex = 403,
		}, row) or nil

		local edge = nil
		local tick = nil

		if box then
			round(box, 4)

			edge = new("UIStroke", { Color = th.line, Transparency = live and 1 or 0.2 }, box)

			tick = new("ImageLabel", {
				Name = rnd(),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(live and 12 or 6, live and 12 or 6),
				BackgroundTransparency = 1,
				Image = icon("check"),
				ImageColor3 = th.bg,
				ImageTransparency = live and 0 or 1,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 404,
			}, box)
		end

		local art = (not flip) and new("ImageLabel", {
			Name = rnd(),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 7, 0.5, 0),
			Size = UDim2.fromOffset(13, 13),
			BackgroundTransparency = 1,
			Image = icon(r.icon or "circle-dot"),
			ImageColor3 = th.dim,
			ImageTransparency = 0.3,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 403,
		}, row) or nil

		local lbl = new("TextLabel", {
			Name = rnd(),
			Position = UDim2.fromOffset(29, 0),
			Size = UDim2.new(1, -35, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = tostring(r.name or ""),
			TextColor3 = live and th.text or th.dim,
			TextSize = 13,
			TextTransparency = live and 0 or 0.35,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 403,
		}, row)

		local btn = new("ImageButton", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			ZIndex = 405,
		}, row)

		local warm = false

		local function paint()
			if box then
				anim(box, soft, { BackgroundTransparency = live and 0.05 or (warm and 0.88 or 1) })
				anim(edge, soft, { Transparency = live and 1 or (warm and 0.05 or 0.2) })
				anim(tick, soft, {
					ImageTransparency = live and 0 or 1,
					Size = UDim2.fromOffset(live and 12 or 6, live and 12 or 6),
				})
			end

			if art then
				anim(art, soft, {
					ImageTransparency = warm and 0 or 0.3,
					ImageColor3 = warm and th.text or th.dim,
				})
			end

			anim(lbl, soft, {
				TextTransparency = (live or warm) and 0 or 0.35,
				TextColor3 = (live or warm) and th.text or th.dim,
			})
		end

		conn(btn.MouseEnter, function()
			warm = true

			paint()
		end)

		conn(btn.MouseLeave, function()
			warm = false

			paint()
		end)

		conn(btn.MouseButton1Click, function()
			local fn = r.callback

			if not flip then
				visualsui:chime("tap")

				if popper == rec then
					popper = nil
				end

				rec.kill()

				if type(fn) == "function" then
					task.spawn(fn, r)
				end

				return
			end

			visualsui:chime(live and "off" or "on")

			local res = nil

			if type(fn) == "function" then
				local ok, out = pcall(fn, r)

				if ok then
					res = out
				end
			end

			if type(res) == "boolean" then
				live = res
			else
				live = not live
			end

			r.on = live

			if not rec.alive then
				return
			end

			paint()
		end)
	end

	conn(slab:GetPropertyChangedSignal("AbsoluteSize"), function()
		roll.CanvasSize = UDim2.fromOffset(0, math.floor(asz(slab).Y + 0.5))
	end)

	for index, slider in ipairs(sliders) do
		local minimum = tonumber(slider.min) or 0
		local maximum = tonumber(slider.max) or 100
		local step = tonumber(slider.step) or 1
		if step ~= step or step <= 0 or step == math.huge then step = 1 end
		local precision = math.clamp(math.floor(tonumber(slider.precision) or 0), 0, 4)
		local value = math.clamp(tonumber(slider.value) or minimum, minimum, maximum)
		local srow = new("Frame", {
			Name = rnd(), Size = UDim2.new(1, 0, 0, 44),
			BackgroundTransparency = 1, BorderSizePixel = 0,
			LayoutOrder = #rows + index, ZIndex = 402,
		}, slab)

		new("TextLabel", {
			Name = rnd(), Position = UDim2.fromOffset(5, 1),
			Size = UDim2.new(1, -64, 0, 16), BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold, Text = tostring(slider.name or "size"),
			TextColor3 = th.dim, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 403,
		}, srow)

		local svalue = new("TextLabel", {
			Name = rnd(), AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -5, 0, 1), Size = UDim2.fromOffset(56, 16),
			BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
			TextColor3 = th.text, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 403,
		}, srow)

		local strack = new("Frame", {
			Name = rnd(), Position = UDim2.fromOffset(5, 25),
			Size = UDim2.new(1, -10, 0, 6), BackgroundColor3 = th.head,
			BorderSizePixel = 0, ZIndex = 403,
		}, srow)

		round(strack, 4)

		local sfill = new("Frame", {
			Name = rnd(), Size = UDim2.new(0, 6, 1, 0),
			BackgroundColor3 = th.accent, BorderSizePixel = 0, ZIndex = 404,
		}, strack)

		round(sfill, 4)

		local sgrab = new("ImageButton", {
			Name = rnd(), Position = UDim2.fromOffset(0, 18),
			Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
			ImageTransparency = 1, Active = true, ZIndex = 405,
		}, srow)

		local dragging, dragInput = false, nil
		local function finishDrag()
			if dragging then dragging = false; latch(-1) end
			dragInput = nil
		end
		rec.release[#rec.release + 1] = finishDrag
		local function paintSlider()
			local span = maximum - minimum
			local k = span > 0 and (value - minimum) / span or 0

			svalue.Text = (precision > 0 and string.format("%." .. precision .. "f", value) or tostring(math.floor(value + 0.5))) .. tostring(slider.suffix or "%")
			sfill.Size = UDim2.new(k, math.floor(6 * (1 - k) + 0.5), 1, 0)
		end

		local function setSlider(x)
			if not rec.alive then return end
			local p, size = strack.AbsolutePosition, strack.AbsoluteSize

			if size.X <= 0 then return end

			local raw = minimum + (maximum - minimum) * math.clamp((x - p.X) / size.X, 0, 1)
			local nextValue = math.clamp(minimum + math.floor((raw - minimum) / step + 0.5) * step, minimum, maximum)
			if precision > 0 then local factor = 10 ^ precision; nextValue = math.floor(nextValue * factor + 0.5) / factor end
			if nextValue == value then return end
			value = nextValue
			paintSlider()

			if type(slider.callback) == "function" then
				callback(function(v) if rec.alive then slider.callback(v) end end, value)
			end
		end

		local function inputX(input)
			return pointer(input).X
		end

		conn(sgrab.InputBegan, function(input)
			if not rec.alive or dragging then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then return end

			dragging = true
			dragInput = input
			latch(1)
			local ok, err = pcall(setSlider, inputX(input))
			if not ok then finishDrag(); warn("[visuals] popup slider: " .. tostring(err)) end
		end)

		conn(uis.InputChanged, function(input)
			if not rec.alive or not dragging then return end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement
				and input.UserInputType ~= Enum.UserInputType.Touch then return end

			if input.UserInputType == Enum.UserInputType.Touch and input ~= dragInput then return end
			local ok, err = pcall(setSlider, inputX(dragInput))
			if not ok then finishDrag(); warn("[visuals] popup slider: " .. tostring(err)) end
		end)

		conn(uis.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or (input.UserInputType == Enum.UserInputType.Touch and input == dragInput) then
				finishDrag()
			end
		end)

		conn(sgrab.Destroying, finishDrag)
		rec.sliders[index] = {name=slider.name, grab=sgrab, track=strack, row=srow}
		paintSlider()
	end

	roll.CanvasSize = UDim2.fromOffset(0, body)

	local function open()
		husk.Visible = true

		if pit then
			pit.Visible = true
		end

		flow(husk, 0.34, outq, function(k)
			local a = 1 - k

			husk.GroupTransparency = a
			husk.Position = UDim2.fromOffset(px, py + math.floor(7 * (1 - k) + 0.5))

			if pit then
				pit.BackgroundTransparency = a
				pit.Position = husk.Position
				cast.Transparency = 0.4 + 0.6 * a
			end
		end)
	end

	local born = os.clock()

	local function stray(input)
		local kind = input.UserInputType
		if not rec.alive or os.clock() - born < 0.2 then
			return false
		end

		if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.MouseButton2 and kind ~= Enum.UserInputType.Touch and kind ~= Enum.UserInputType.MouseWheel then
			return false
		end

		if kind == Enum.UserInputType.Touch then
			local at, position, size = pointer(input), husk.AbsolutePosition, husk.AbsoluteSize
			return at.X < position.X - 4 or at.Y < position.Y - 4 or at.X > position.X + size.X + 4 or at.Y > position.Y + size.Y + 4
		end
		return not inside(husk, 4)
	end

	rec.watch = conn(uis.InputBegan, function(i)
		if not stray(i) then
			return
		end

		if popper == rec then
			popper = nil
		end

		rec.kill()
	end)

	rec.spin = conn(uis.InputChanged, function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseWheel then
			return
		end

		if not stray(i) then
			return
		end

		if popper == rec then
			popper = nil
		end

		rec.kill()
	end)

	if typeof(cfg.follow) == "Instance" and cfg.follow:IsA("GuiObject") then
		local anchor = cfg.follow
		local base = anchor.AbsolutePosition

		rec.trail = conn(rs.RenderStepped, function()
			if not rec.alive then
				return
			end

			local gone = not anchor.Parent or not anchor.Visible

			if gone or (anchor.AbsolutePosition - base).Magnitude > 4 then
				if popper == rec then
					popper = nil
				end

				rec.kill()
			end
		end)
	end

	task.spawn(function()
		while rec.alive do
			if not visualsui.alive or not visualsui.shown then
				if popper == rec then
					popper = nil
				end

				rec.kill()

				break
			end

			task.wait(0.12)
		end
	end)

	popper = rec

	open()

	return rec
end

local asker = nil

function visualsui:closeask()
	if asker then
		asker.kill()
		asker = nil
	end
end

function visualsui:ask(cfg)
	cfg = params(cfg, {
		title = "input",
		icon = "keyboard",
		hint = "",
		text = "",
		accept = "ok",
		deny = "cancel",
		width = 268,
		callback = nil,
	})

	visualsui:closeask()
	visualsui:closepopup()

	if not visualsui.alive then
		return nil
	end

	local host = nil

	for _, w in next, visualsui.wins do
		if w.root and w.root.Parent and w.open then
			host = w
		end
	end

	if not host then
		return nil
	end

	local wide = math.clamp(math.floor(tonumber(cfg.width) or 268), 200, 420)
	local tall = 122

	local veil = new("ImageButton", {
		Name = rnd(),
		Active = true,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "",
		ImageTransparency = 1,
		ZIndex = 40,
	}, host.shell or host.root)

	local pit = deep and new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(wide, tall),
		BackgroundColor3 = th.panel,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 42,
	}, veil) or nil

	local cast = pit and new("UIShadow", {
		Color = th.bg,
		BlurRadius = UDim.new(0, 22),
		Offset = UDim2.fromOffset(0, 6),
		Spread = UDim2.fromOffset(-3, -3),
		Transparency = 1,
		ZIndex = -1,
	}, pit) or nil

	if pit then
		round(pit, 8)
	end

	local husk = new("CanvasGroup", {
		Name = rnd(),
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(wide, tall),
		BackgroundColor3 = th.panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		GroupTransparency = 1,
		ZIndex = 43,
	}, veil)

	round(husk, 8)

	local brim = new("Frame", {
		Name = rnd(),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 310,
	}, husk)

	round(brim, 8)

	new("UIStroke", { Color = th.line, Transparency = 0.55 }, brim)

	local cap = new("Frame", {
		Name = rnd(),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = th.head,
		BorderSizePixel = 0,
		ZIndex = 303,
	}, husk)

	round(cap, 8)

	new("Frame", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 8),
		BackgroundColor3 = th.head,
		BorderSizePixel = 0,
		ZIndex = 303,
	}, cap)

	new("ImageLabel", {
		Name = rnd(),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(13, 13),
		BackgroundTransparency = 1,
		Image = icon(cfg.icon),
		ImageColor3 = th.dim,
		ImageTransparency = 0.25,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 304,
	}, cap)

	new("TextLabel", {
		Name = rnd(),
		Position = UDim2.fromOffset(30, 0),
		Size = UDim2.new(1, -40, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = tostring(cfg.title),
		TextColor3 = th.text,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 304,
	}, cap)

	local rule = new("Frame", {
		Name = rnd(),
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = th.accent,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ZIndex = 304,
	}, husk)

	fade(rule, 0, {
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.12, 0.2),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.88, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})

	local field = new("TextBox", {
		Name = rnd(),
		Position = UDim2.fromOffset(10, 42),
		Size = UDim2.new(1, -20, 0, 28),
		BackgroundColor3 = th.head,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		Font = Enum.Font.GothamBold,
		PlaceholderColor3 = th.dim,
		PlaceholderText = tostring(cfg.hint),
		Text = tostring(cfg.text),
		TextColor3 = th.text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 303,
	}, husk)

	round(field, 6)

	new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, field)

	local edge = new("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = th.line,
		Transparency = 0.6,
	}, field)

	local rec = { alive = true, frame = husk, field = field }

	local function nib(x, w, text, lead)
		local slab = new("Frame", {
			Name = rnd(),
			Position = UDim2.fromOffset(x, 82),
			Size = UDim2.fromOffset(w, 28),
			BackgroundColor3 = th.head,
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 303,
		}, husk)

		round(slab, 6)

		local ring = new("UIStroke", { Color = th.line, Transparency = 0.62 }, slab)

		local wash = new("Frame", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = th.accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 304,
		}, slab)

		round(wash, 6)

		fade(wash, 0, {
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.55, 0.62),
			NumberSequenceKeypoint.new(1, 1),
		})

		local lbl = new("TextLabel", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = tostring(text),
			TextColor3 = lead and th.text or th.dim,
			TextSize = 13,
			TextTransparency = lead and 0.05 or 0.25,
			ZIndex = 305,
		}, slab)

		local tap = new("ImageButton", {
			Name = rnd(),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			ZIndex = 306,
		}, slab)

		local warm = false

		local function glow()
			anim(slab, soft, { BackgroundTransparency = warm and 0 or 0.12 })
			anim(ring, soft, { Transparency = warm and 0.4 or 0.62 })
			anim(wash, soft, { BackgroundTransparency = warm and 0.88 or 1 })
			anim(lbl, soft, {
				TextTransparency = warm and 0 or (lead and 0.05 or 0.25),
				TextColor3 = (warm or lead) and th.text or th.dim,
			})
		end

		conn(tap.MouseEnter, function()
			warm = true

			glow()
		end)

		conn(tap.MouseLeave, function()
			warm = false

			glow()
		end)

		return tap, wash
	end

	local gap = 6
	local half = math.floor((wide - 20 - gap) / 2)
	local deny, denywash = nib(10, half, cfg.deny, false)
	local okay, okaywash = nib(10 + half + gap, wide - 20 - half - gap, cfg.accept, true)

	local function paint(a)
		husk.GroupTransparency = a

		if pit then
			pit.BackgroundTransparency = a
			cast.Transparency = 0.35 + 0.65 * a
		end
	end

	local function shut(done)
		local from = husk.GroupTransparency

		flow(husk, 0.26, inq, function(k)
			paint(from + (1 - from) * k)

			if k >= 1 and done then
				done()
			end
		end)
	end

	function rec.kill()
		if not rec.alive then
			return
		end

		rec.alive = false

		latch(-1)

		if rec.watch then
			pcall(function()
				rec.watch:Disconnect()
			end)

			rec.watch = nil
		end

		if rec.guard then
			pcall(function()
				rec.guard:Disconnect()
			end)

			rec.guard = nil
		end

		pcall(function()
			field:ReleaseFocus(false)
		end)

		if asker == rec then
			asker = nil
		end

		shut(function()
			pcall(function()
				veil:Destroy()
			end)
		end)
	end

	local function refuse()
		edge.Color = th.accent
		edge.Transparency = 0.1

		anim(edge, soft, { Color = th.line, Transparency = 0.6 })

		flow(field, 0.26, outq, function(k)
			field.Position = UDim2.fromOffset(10 + math.floor(math.sin(k * math.pi * 3) * 4 * (1 - k) + 0.5), 42)
		end)

		task.defer(function()
			if rec.alive then
				field:CaptureFocus()
			end
		end)
	end

	local function submit()
		if not rec.alive then
			return
		end

		okaywash.BackgroundTransparency = 0.72

		anim(okaywash, soft, { BackgroundTransparency = 1 })

		visualsui:chime("tap")

		local text = string.match(field.Text, "^%s*(.-)%s*$") or ""

		if text == "" then
			refuse()

			return
		end

		if type(cfg.callback) == "function" then
			local ok, res = pcall(cfg.callback, text)

			if ok and res == false then
				refuse()

				return
			end
		end

		rec.kill()
	end

	local function drop()
		if not rec.alive then
			return
		end

		denywash.BackgroundTransparency = 0.72

		anim(denywash, soft, { BackgroundTransparency = 1 })

		visualsui:chime("tap")

		rec.kill()
	end

	conn(okay.MouseButton1Click, submit)
	conn(deny.MouseButton1Click, drop)

	conn(veil.MouseButton1Click, function()
		if inside(husk, 2) then
			return
		end

		drop()
	end)

	conn(field.Focused, function()
		anim(edge, soft, { Transparency = 0.3 })
	end)

	conn(field.FocusLost, function(enter)
		anim(edge, soft, { Transparency = 0.6 })

		if enter then
			submit()
		end
	end)

	rec.watch = conn(uis.InputBegan, function(i)
		if not rec.alive or i.KeyCode ~= Enum.KeyCode.Escape then
			return
		end

		drop()
	end)

	rec.guard = host.shell and conn(host.shell:GetPropertyChangedSignal("Visible"), function()
		if not host.shell.Visible then
			rec.kill()
		end
	end) or nil

	latch(1)

	paint(1)

	flow(husk, 0.34, outq, function(k)
		paint(1 - k)
	end)

	task.defer(function()
		if rec.alive then
			field:CaptureFocus()
		end
	end)

	asker = rec

	return rec
end

function visualsui:unload()
	visualsui:closeask()
	visualsui:closepopup()

	for _, b in next, table.clone(visualsui.browsers) do
		pcall(function()
			b:kill()
		end)
	end

	table.clear(visualsui.browsers)

	visualsui.alive = false
	visualsui.applyEpoch = (visualsui.applyEpoch or 0) + 1
	visualsui.quiet = false
	visualsui.configApplying = false
	locks = 0
	visualsui.cursor = false
	visualsui.shown = false

	pcall(rouse)
	pcall(capture, nil)
	pcall(hush)

	table.clear(eyes)
	table.clear(hive)
	table.clear(visualsui.pool)
	table.clear(visualsui.order)

	for _, c in next, visualsui.conns do
		pcall(function()
			c:Disconnect()
		end)
	end

	table.clear(visualsui.conns)
	table.clear(visualsui.wins)

	if scr then
		scr:Destroy()
	end
end

getgenv().visualsui = visualsui

return visualsui
