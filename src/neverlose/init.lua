local UI_SOURCE, ASSETS = ...;

if type(UI_SOURCE) ~= "string" and readfile and isfile and isfile("UI-lib/visualsui.luau") then
	UI_SOURCE = readfile("UI-lib/visualsui.luau");
end;

assert(type(UI_SOURCE) == "string" and UI_SOURCE ~= "", "visualsui source missing");

local chunk = assert(loadstring(UI_SOURCE, "@visualsui"))
local lib = chunk(ASSETS);

UI_SOURCE = nil;

assert(type(lib) == "table" and type(lib.window) == "function", "visualsui did not load");

local NeverLose = {};

NeverLose.Lib = lib;
NeverLose.ScreenGui = lib.scr;
NeverLose.AccentColor = lib.theme.accent;
NeverLose.MainColor = lib.theme.bg;
local defaultTheme = table.clone(lib.theme);

local recolor = lib.recolor;
function lib:recolor(key, color)
	recolor(self, key, color);
	NeverLose.AccentColor = self.theme.accent;
	NeverLose.MainColor = self.theme.bg;
end;

local applyConfig = lib.apply;
function lib:apply(data)

	if type(data) == "table" and type(data.flags) == "table" and data.flags.esp_arrow_skin == "Arrows 2" then
		data = table.clone(data);
		data.flags = table.clone(data.flags);
		data.flags.esp_arrow_skin = "Triangle";
	end;
	if type(data) ~= "table" or type(data.flags) ~= "table" or type(data.theme) ~= "table" then
		return applyConfig(self, data);
	end;
	local patched;
	for key, color in pairs(data.theme) do
		local flag = "theme|" .. key;
		if self.pool[flag] and data.flags[flag] == nil then
			if not patched then
				patched = table.clone(data);
				patched.flags = table.clone(data.flags);
			end;
			patched.flags[flag] = color;
		end;
	end;
	return applyConfig(self, patched or data);
end;
NeverLose.GlobalLogo = lib.logo;
NeverLose.EnabledBlur = false;
NeverLose.UnloadEnabled = false;
NeverLose.GlobalSignals = {};
NeverLose.Flags = {};
NeverLose.OnToggleChanged = function() end;
NeverLose.BuiltInRegular = Font.fromEnum(Enum.Font.GothamMedium);
NeverLose.BuiltInBold = Font.fromEnum(Enum.Font.GothamBold);

NeverLose.Mobile = lib.mobile and true or false;
NeverLose.IsMobile = NeverLose.Mobile;

local function laneFor(position)
	if position == "full" then return "full" end;

	return (position == "right") and "right" or "left";
end;

function NeverLose.RandomString()
	local out = {};

	for _ = 1, 12 do out[#out + 1] = string.char(math.random(1, 7)) end;

	return table.concat(out);
end;

function NeverLose:AddSignal(signal)
	if not lib.alive then signal:Disconnect(); return signal end;
	if #NeverLose.GlobalSignals > 128 then
		for i = #NeverLose.GlobalSignals, 1, -1 do
			if not NeverLose.GlobalSignals[i].Connected then table.remove(NeverLose.GlobalSignals, i) end
		end
	end
	table.insert(NeverLose.GlobalSignals, signal);

	return signal;
end;

local playerSignals = {};
function NeverLose:AddPlayerSignal(player, signal)
	playerSignals[player] = playerSignals[player] or {};
	table.insert(playerSignals[player], signal);
	return self:AddSignal(signal);
end;
NeverLose:AddSignal(game:GetService("Players").PlayerRemoving:Connect(function(player)
	for _, connection in ipairs(playerSignals[player] or {}) do connection:Disconnect() end;
	playerSignals[player] = nil;
end));

NeverLose.Brand = "Wsp boi";

function NeverLose:CreateNotification()
	return {
		new = function(c)
			c = c or {};

			lib:notify({
				title = c.Title or NeverLose.Brand,
				text = c.Content or "",
				icon = NeverLose.IconName(c.Icon or "info"),
				life = c.Duration or 5,
			});
		end,
	};
end;

function NeverLose:CreateLogger()
	return {
		new = function(ic, txt, dur, col)
			lib:notify({
				title = tostring(txt or ""),
				icon = NeverLose.IconName(ic or "file-text"),
				life = dur or 4,
				tone = (typeof(col) == "Color3") and col or nil,
			});
		end,
	};
end;

local ICON_ALIAS = {
	["arrow-down"] = "chevron-down",
	["arrow-left"] = "chevron-right",
	["arrow-right"] = "chevron-right",
	["arrow-right-from-portrait-rectangle"] = "log-out",
	["arrow-rotate-right"] = "refresh-cw",
	["arrow-spin-clockwise"] = "refresh-cw",
	["arrow-up"] = "chevron-up",
	["bookmark"] = "book",
	["chart-four-vertical-bars"] = "activity",
	["chart-line"] = "activity",
	["chevron-large-left"] = "chevron-right",
	["chevron-large-right"] = "chevron-right",
	["chevron-small-down"] = "chevron-down",
	["chevron-small-left"] = "chevron-right",
	["chevron-small-right"] = "chevron-right",
	["chevron-small-up"] = "chevron-up",
	["circle"] = "circle-dot",
	["circle-check"] = "check",
	["circle-play"] = "circle-dot",
	["circle-x"] = "x",
	["crosshairs"] = "crosshair",
	["cube-vertexes"] = "box",
	["eye-slash"] = "eye-off",
	["file-box"] = "file-text",
	["flag"] = "map-pin",
	["floppy-disk"] = "save",
	["frame-corners"] = "monitor",
	["gear"] = "settings",
	["globe-detailed"] = "globe",
	["globe-simplified"] = "globe",
	["hammer-code"] = "wrench",
	["list-bulleted"] = "list",
	["magnifying-glass"] = "search",
	["music"] = "volume-2",
	["music-note"] = "volume-2",
	["paint-brush"] = "palette",
	["pause-large"] = "x",
	["pause-small"] = "x",
	["person"] = "user",
	["person-play"] = "hand",
	["person-running"] = "person-standing",
	["play-large"] = "zap",
	["play-small"] = "zap",
	["plus-large"] = "plus",
	["signal-exclamation"] = "wifi",
	["square"] = "x",
	["square-check"] = "check",
	["stop-large"] = "x",
	["stop-small"] = "x",
	["three-dots-horizontal"] = "ellipsis",
	["three-sliders-horizontal"] = "sliders-horizontal",
	["trash-can"] = "trash-2",
};

function NeverLose.IconName(name)
	local key = string.lower(tostring(name or "")):gsub("%-bold$", "");

	if lib.icons[key] then return key end;

	local alias = ICON_ALIAS[key];

	if alias and lib.icons[alias] then return alias end;

	return key;
end;

function NeverLose.ApplyIcon(label, name)
	if typeof(label) ~= "Instance" then return end;

	local id = lib.icons[NeverLose.IconName(name)];

	if not id then
		label.Text = "";

		return;
	end;

	label.Text = "";

	local image = label:FindFirstChild("Icon");

	if not image then
		image = Instance.new("ImageLabel");
		image.Name = "Icon";
		image.BackgroundTransparency = 1;
		image.AnchorPoint = Vector2.new(0.5, 0.5);
		image.Position = UDim2.fromScale(0.5, 0.5);
		image.Size = UDim2.fromScale(0.85, 0.85);
		image.ScaleType = Enum.ScaleType.Fit;
		image.Parent = label;
	end;

	image.Image = "rbxassetid://" .. id;
	image.ImageColor3 = label.TextColor3;
	image.ZIndex = label.ZIndex;
end;

function NeverLose.SetWatermark(on)
	pcall(function() lib:setwatermark(on and true or false) end);
end;

function NeverLose.SetWatermarkText(text)
	for _, child in ipairs(lib.scr:GetDescendants()) do
		if child:IsA("TextLabel") and child.Text == "inertiahub.xyz" then
			child.Text = tostring(text or "");

			return true;
		end;
	end;

	return false;
end;

function NeverLose.SetKeybindList(on)
	pcall(function() lib:sethotkeys(on and true or false) end);
end;

local function panelFor(wantsRight)
	for _, child in ipairs(lib.scr:GetChildren()) do
		if child:IsA("CanvasGroup") and child.ZIndex == 900
			and child.AutomaticSize == Enum.AutomaticSize.XY then
			local onRight = child.AnchorPoint.X > 0.5;

			if onRight == wantsRight then return child end;
		end;
	end;

	return nil;
end;

function NeverLose:Unload()
	for _, connections in pairs(playerSignals) do for _, connection in ipairs(connections) do connection:Disconnect() end end;
	table.clear(playerSignals);
	for _, signal in ipairs(NeverLose.GlobalSignals) do
		pcall(function() signal:Disconnect() end);
	end;

	table.clear(NeverLose.GlobalSignals);

	pcall(function() lib:unload() end);
end;

NeverLose.Unload = NeverLose.Unload;

local function tolerant(object)
	return setmetatable(object, {
		__index = function(_, key)
			if type(key) ~= "string" then return nil end;

			return function() end;
		end,
	});
end;

local function register(flag, item)
	if type(flag) ~= "string" or flag == "" then return item end;

	NeverLose.Flags[flag] = item;

	return item;
end;

local ELLIPSIS = lib.icons.ellipsis and ("rbxassetid://" .. lib.icons.ellipsis) or nil;

local function findDots(element)
	local row = element and element.row;

	if not ELLIPSIS or typeof(row) ~= "Instance" then return nil end;

	for _, child in ipairs(row:GetChildren()) do
		if (child:IsA("ImageButton") or child:IsA("ImageLabel")) and child.Image == ELLIPSIS then
			return child;
		end;
	end;

	return nil;
end;

local function retune(element, fullWidth)
	local row = element and element.row;

	if typeof(row) ~= "Instance" then return element end;

	local caption, pill;

	for _, child in ipairs(row:GetChildren()) do
		if child:IsA("TextLabel") and not caption then
			caption = child;
		elseif child:IsA("Frame") and child.ClipsDescendants then
			pill = child;
		end;
	end;

	if fullWidth then
		if caption then caption.Visible = false end;
		if pill then pill.Size = UDim2.new(1, -10, 0, 22) end;
		return element;
	end;

	if caption then
		caption.TextColor3 = lib.theme.text;
		caption.TextTransparency = 0.12;

		local needed = caption.TextBounds.X;

		if needed <= 0 then needed = #caption.Text * 7 end;

		local share = math.clamp((needed + 14) / math.max(1, row.AbsoluteSize.X), 0.3, 0.6);

		caption.Size = UDim2.new(share, -8, 1, 0);

		if pill then pill.Size = UDim2.new(1 - share, -5, 0, 22) end;
	elseif pill then
		pill.Size = UDim2.new(0.58, -5, 0, 22);
	end;

	return element;
end;

local function typable(element, minimum, maximum)
	local row = element and element.row;

	if typeof(row) ~= "Instance" or type(element.set) ~= "function" then return element end;

	local readout;

	for _, child in ipairs(row:GetChildren()) do
		if child:IsA("TextLabel") and child.TextXAlignment == Enum.TextXAlignment.Right then
			readout = child;
		end;
	end;

	if not readout then return element end;

	local box = Instance.new("TextBox");
	box.Name = "Typed";
	box.BackgroundColor3 = lib.theme.head;
	box.BackgroundTransparency = 0.1;
	box.BorderSizePixel = 0;
	box.AnchorPoint = readout.AnchorPoint;
	box.Position = readout.Position;
	box.Size = UDim2.fromOffset(math.max(44, readout.AbsoluteSize.X + 14), 16);
	box.Font = Enum.Font.GothamBold;
	box.TextSize = 12;
	box.TextColor3 = lib.theme.text;
	box.ClearTextOnFocus = true;
	box.Visible = false;
	box.ZIndex = readout.ZIndex + 2;
	box.Parent = row;

	local corner = Instance.new("UICorner", box);
	corner.CornerRadius = UDim.new(0, 4);

	local hit = Instance.new("TextButton");
	hit.Name = "TypeHit";
	hit.BackgroundTransparency = 1;
	hit.Text = "";
	hit.AnchorPoint = readout.AnchorPoint;
	hit.Position = readout.Position;
	hit.Size = UDim2.fromOffset(math.max(44, readout.AbsoluteSize.X + 14), 18);
	hit.ZIndex = readout.ZIndex + 1;
	hit.Parent = row;

	hit.MouseButton1Click:Connect(function()
		box.Text = tostring(element:get());
		box.Visible = true;

		box:CaptureFocus();
	end);

	box.FocusLost:Connect(function()
		box.Visible = false;

		local typed = tonumber((box.Text or ""):match("-?%d+%.?%d*"));

		if not typed then return end;

		if minimum then typed = math.max(minimum, typed) end;
		if maximum then typed = math.min(maximum, typed) end;

		element:set(typed);
	end);

	return element;
end;

local function stepOf(cfg)
	local digits = tonumber(cfg.Rounding or cfg.Round) or 0;

	return (digits > 0) and (1 / (10 ^ digits)) or 1;
end;

local silent = false;

local function report(flag, hook)
	return function(value, ...)
		if hook then hook(value, ...) end;

		local notify = NeverLose.OnToggleChanged;

		if notify then
			local restoring = NeverLose.Lib and NeverLose.Lib.quiet;
			pcall(notify, value, flag, not silent and not restoring);
		end;
	end;
end;

local function quietly(fn, ...)
	local was = silent;

	silent = true;

	local ok, err = pcall(fn, ...);

	silent = was;

	if not ok then error(err, 3) end;
end;

local function wrapValue(element, flag, extra)
	local item = { __el = element };

	function item:GetValue() return element:get() end;
	function item:SetValue(v) quietly(element.set, element, v) end;
	function item:Set(v) quietly(element.set, element, v) end;

	if extra then extra(item, element) end;

	return register(flag, tolerant(item));
end;

local function makeRow(section, caption)
	local row = { Name = caption, __section = section };

	local first = true;

	local dots;

	local function revealDots()
		if dots and dots.Parent then dots.Visible = true end;
	end;

	row.RevealOptions = revealDots;

	local function placeFor(kind)
		if first then
			first = false;

			return section.__sec, caption;
		end;

		local toggle = rawget(row, "__toggle");
		local panel = toggle and toggle.options;

		if panel then
			revealDots();

			return panel, kind;
		end;

		return section.__sec, caption;
	end;

	function row:AddToggle(cfg)
		cfg = cfg or {};

		local target, name = placeFor("Enabled");

		local element = target:toggle({
			name = name,
			default = cfg.Default and true or false,
			options = true,
			flag = cfg.Flag,
			callback = report(cfg.Flag, cfg.Callback),
		});

		row.__toggle = element;
		dots = findDots(element);

		if dots then dots.Visible = false end;

		return wrapValue(element, cfg.Flag);
	end;

	function row:AddSlider(cfg)
		cfg = cfg or {};

		local target, name = placeFor("Amount");

		local element = target:slider({
			name = name,
			min = tonumber(cfg.Min) or 0,
			max = tonumber(cfg.Max) or 100,
			default = cfg.Default,
			step = stepOf(cfg),
			suffix = (type(cfg.Type) == "string") and cfg.Type or "",
			flag = cfg.Flag,
			callback = report(cfg.Flag, cfg.Callback),
		});

		typable(element, tonumber(cfg.Min) or 0, tonumber(cfg.Max) or 100);

		return wrapValue(element, cfg.Flag);
	end;

	function row:AddDropdown(cfg)
		cfg = cfg or {};

		local target, name = placeFor("Mode");

		local element = target:combo({
			name = name,
			list = cfg.Values or {},
			default = cfg.Default,
			multi = cfg.Multi and true or false,
			flag = cfg.Flag,
			callback = report(cfg.Flag, cfg.Callback),
		});

		retune(element, cfg.FullWidth);

		return wrapValue(element, cfg.Flag, function(item)
			function item:SetValues(list)
				if element.setlist then element:setlist(list) end;
			end;

			function item:Generate() end;
		end);
	end;

	function row:AddColorPicker(cfg)
		cfg = cfg or {};

		local hook = cfg.Callback;
		local target, name = placeFor("Color");

		local element = target:color({
			name = cfg.Name or name,
			default = cfg.Default,
			flag = cfg.Flag,
			callback = report(cfg.Flag, hook and function(colour) hook(colour, cfg.Transparency) end or nil),
		});

		return wrapValue(element, cfg.Flag);
	end;

	function row:AddKeybind(cfg)
		cfg = cfg or {};

		local target, name = placeFor("Key");

		local element = target:keybind({
			name = name,
			default = cfg.Default,
			flag = cfg.Flag,
			callback = report(cfg.Flag, cfg.Callback),
		});

		return wrapValue(element, cfg.Flag);
	end;

	function row:AddTextInput(cfg)
		cfg = cfg or {};

		local host = section.__sec.items;
		local frame = Instance.new("Frame");
		frame.Name = NeverLose.RandomString();
		frame.BackgroundTransparency = 1;
		frame.Size = UDim2.new(1, 0, 0, 26);
		frame.Parent = host;

		local box = Instance.new("TextBox");
		box.Name = "Input";
		box.BackgroundColor3 = lib.theme.head;
		box.BorderSizePixel = 0;
		box.Position = UDim2.new(0, 4, 0, 3);
		box.Size = UDim2.new(1, -8, 0, 20);
		box.Font = Enum.Font.GothamMedium;
		box.TextSize = 12;
		box.TextColor3 = lib.theme.text;
		box.PlaceholderText = cfg.Placeholder or caption;
		box.PlaceholderColor3 = lib.theme.dim;
		box.Text = cfg.Default or "";
		box.ClearTextOnFocus = false;
		box.Parent = frame;

		local corner = Instance.new("UICorner", box);
		corner.CornerRadius = UDim.new(0, 5);

		local item = { __box = box };

		local applying = false;

		function item:GetValue() return box.Text end;

		function item:SetValue(v)
			applying = true;

			box.Text = tostring(v or "");

			applying = false;
			if cfg.Callback and not (lib.secrets and lib.secrets[cfg.Flag]) then cfg.Callback(box.Text) end;
		end;

		NeverLose:AddSignal(box:GetPropertyChangedSignal("Text"):Connect(function()
			if applying or not cfg.Callback then return end;

			cfg.Callback(box.Text);
		end));

		if type(cfg.Flag) == "string" and cfg.Flag ~= "" then
			pcall(function()
				lib:hook(cfg.Flag, "string",
					function() return box.Text end,
					function(value) item:SetValue(value) end);
			end);
		end;

		return register(cfg.Flag, item);
	end;

	function row:AddOption()

		local toggle = rawget(row, "__toggle");
		local panel = toggle and toggle.options;

		if not panel then return section end;

		revealDots();

		local nested = {
			__sec = setmetatable({ items = section.__sec.items }, { __index = panel }),
			__parentSection = section,
		};

		function nested:AddLabel(name) return makeRow(nested, name) end;

		function nested:AddButton(cfg)
			cfg = cfg or {};

			panel:button({ name = cfg.Name or "Button", icon = cfg.Icon and NeverLose.IconName(cfg.Icon) or nil, callback = cfg.Callback });

			return {};
		end;

		nested.__sec = panel;
		nested.__sec.items = section.__sec.items;

		return nested;
	end;

	function row:SetText(value)
		if row.__label and row.__label.set then row.__label:set(value) end;
	end;

	return tolerant(row);
end;

local function wrapSection(sec)
	local section = { __sec = sec, Root = sec.items, Items = sec.items };

	function section:SetVisible(state)
		local panel = sec.panel;
		local curtain = typeof(panel) == "Instance" and panel.Parent or nil;
		local slot = typeof(curtain) == "Instance" and curtain.Parent or nil;

		if typeof(slot) ~= "Instance" then return end;

		slot.Visible = state and true or false;

		if state then
			local height = panel.AbsoluteSize.Y;

			if height > 2 then
				curtain.Size = UDim2.new(1, 0, 0, height);
				slot.Size = UDim2.new(1, 0, 0, height);
			end;
		end;
	end;

	function section:AddLabel(name, isStatus)
		local caption = tostring(name or "");

		if isStatus then
			local element = sec:label({ name = caption, wrap = true });
			local row = makeRow(section, caption);

			row.__label = element;

			function row:SetText(value)
				if element.set then element:set(value) end;
			end;

			return row;
		end;

		return makeRow(section, caption);
	end;

	function section:AddButton(cfg)
		cfg = cfg or {};

		local element = sec:button({
			name = cfg.Name or "Button",
			icon = cfg.Icon and NeverLose.IconName(cfg.Icon) or nil,
			callback = cfg.Callback,
		});

		return tolerant({ __el = element });
	end;

	return tolerant(section);
end;

local function pageSignal(node)
	local bindable = Instance.new("BindableEvent");
	bindable.Parent = NeverLose.ScreenGui;
	local value = false;
	local previous = node.hit;

	node.hit = function(selected)
		value = selected and true or false;

		if previous then previous(selected) end;

		bindable:Fire(value);
	end;

	return {
		GetValue = function() return value end,
		SetValue = function(_, v) value = v; bindable:Fire(v) end,
		Connect = function(_, fn) return NeverLose:AddSignal(bindable.Event:Connect(fn)) end,
	};
end;

local function windowSize(fallback)
	if not NeverLose.Mobile then return fallback end;

	local camera = workspace.CurrentCamera;
	local view = (camera and camera.ViewportSize) or Vector2.new(640, 480);

	pcall(function()
		local fake = getgenv().VISUALS_FAKE_VIEWPORT;
		if typeof(fake) == "Vector2" then view = fake end;
	end);
	local scale = lib.scale;

	if type(scale) ~= "number" or scale <= 0 then scale = 1 end;

	local inset = game:GetService("GuiService"):GetGuiInset().Y;
	local roomX, roomY = math.max(view.X - 16, 160), math.max(view.Y - inset - 30, 120);
	local wide = math.clamp(math.floor(view.X * 0.74), math.min(300, roomX), math.min(580, roomX));
	local tall = math.clamp(roomY, math.min(220, roomY), 560);

	return UDim2.fromOffset(math.floor(wide / scale), math.floor(tall / scale));
end;

function NeverLose:CreateWindow(cfg)
	cfg = cfg or {};

	local win = lib:window({
		size = windowSize(cfg.Size or UDim2.fromOffset(640, 520)),

		side = NeverLose.Mobile and 140 or nil,
		bind = cfg.Keybind or "RightShift",
	});

	NeverLose.WindowFrame = win.shell;

	if NeverLose.Mobile then
		local GuiService = game:GetService("GuiService");

		local function fit()
			local inset = GuiService:GetGuiInset().Y;
			pcall(function()
				win:setsize(windowSize(win.size or UDim2.fromOffset(640, 520)));
				win.shell.Position = UDim2.new(0.5, 0, 0.5, math.floor(inset / 2));
			end);
		end;

		fit();

		local camera = workspace.CurrentCamera;
		if camera then
			NeverLose:AddSignal(camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit));
		end;
	end;
	NeverLose.WindowRoot = win.root;

	local Window = {
		__win = win,
		Frame = win.shell,
		Tabs = {},
		CurrentTab = 1,
		Keybind = cfg.Keybind or "RightShift",
	};

	local function settleCards(page)
		if typeof(page) ~= "Instance" then return 0 end;

		local fixed = 0;

		for _, frame in ipairs(page:GetDescendants()) do

			if frame:IsA("Frame") and frame:GetAttribute("VisualsCardCurtain") then
				local inner = frame:FindFirstChildWhichIsA("Frame");

				if inner and inner.AutomaticSize == Enum.AutomaticSize.Y then
					local want = inner.AbsoluteSize.Y;

					if want > 2 and frame.AbsoluteSize.Y < want - 2 then
						frame.Size = UDim2.new(1, 0, 0, want);

						local slot = frame.Parent;

						if slot and slot:IsA("Frame") and slot.AbsoluteSize.Y < want - 2 then
							slot.Size = UDim2.new(1, 0, 0, want);
						end;

						fixed = fixed + 1;
					end;
				end;
			end;
		end;

		return fixed;
	end;

	local function settleSoon(page)
		task.defer(function() settleCards(page) end);
		task.delay(0.5, function() settleCards(page) end);
	end;

	local signalValue = true;
	local bindable = Instance.new("BindableEvent");

	Window.Signal = {
		GetValue = function() return signalValue end,
		SetValue = function(_, v) signalValue = v; bindable:Fire(v) end,
		Connect = function(_, fn) return NeverLose:AddSignal(bindable.Event:Connect(fn)) end,
	};

	function Window:ToggleInterface()
		win:render(not win.open);
		signalValue = win.open;

		bindable:Fire(signalValue);
	end;

	NeverLose:AddSignal(game:GetService("RunService").Heartbeat:Connect(function()
		local open = lib.shown and true or false;

		if open ~= signalValue then
			signalValue = open;

			bindable:Fire(open);

			if open and win.active then settleSoon(win.active.page) end;
		end;
	end));

	local groupTabs, headerClick = {}, false;
	local function foldOthers(tab)
		for _, other in ipairs(groupTabs) do
			local want = other == tab;

			if want and headerClick then continue end;
			if other.open ~= want and other.setopen then pcall(function() other:setopen(want) end) end;
		end;
	end;

	function Window:GetPage()
		local live = win.active;

		if type(live) ~= "table" then return nil end;

		for _, tab in ipairs(win.list) do
			if tab == live then return tostring(tab.name) end;

			for _, sub in ipairs(tab.subs or {}) do
				if sub == live then return tostring(tab.name) .. "/" .. tostring(sub.name) end;
			end;
		end;

		return nil;
	end;

	function Window:SetPage(path)
		if type(path) ~= "string" or path == "" then return false end;

		local parent, child = string.match(path, "^([^/]+)/(.+)$");

		parent = parent or path;

		for _, tab in ipairs(win.list) do
			if tostring(tab.name) == parent then
				if child then
					for _, sub in ipairs(tab.subs or {}) do
						if tostring(sub.name) == child then
							pcall(function() sub.select() end);

							foldOthers(tab);

							return true;
						end;
					end;
				end;

				pcall(function() tab.select() end);

				return true;
			end;
		end;

		return false;
	end;

	function Window:SetSize(size)
		if typeof(size) ~= "UDim2" or NeverLose.Mobile then return end;

		pcall(function() win:setsize(size) end);
	end;

	function Window:SetKeybind(value)
		if value == nil then return end;

		Window.Keybind = value;

		pcall(function() win:setbind(value) end);
	end;

	local settingsSection, settingsTab, settingsPages = nil, nil, {};
	local settingsLast;
	local function settings()
		if not settingsTab then
			settingsTab = win:tab({ name = "SETTINGS", icon = "settings-2" });

			local parentHit = settingsTab.hit;
			settingsTab.hit = function(selected)
				if parentHit then parentHit(selected) end;
				if not selected then return end;
				task.defer(function()
					local sub = settingsLast or settingsPages.Menu;
					headerClick = true;
					if sub then pcall(function() sub:select() end) end;
					headerClick = false;
				end);
			end;
		end;

		return settingsTab;
	end;
	local function settingsPage(name, icon)
		if not settingsPages[name] then
			local tab = settings();
			local sub = tab:sub({ name = name, icon = icon });
			local previous = sub.hit;

			if not table.find(groupTabs, tab) then table.insert(groupTabs, tab) end;

			sub.hit = function(selected)
				if previous then previous(selected) end;
				if selected then settingsLast = sub; foldOthers(tab) end;
			end;

			settingsPages[name] = sub;
		end;

		return settingsPages[name];
	end;

	local colorsTab;
	function Window:ResetMenuColors()
		for key, color in pairs(defaultTheme) do
			local entry = lib.pool["theme|" .. key];
			if entry and entry.set then entry.set(color) end;
			lib:recolor(key, color);
		end;
	end;
	function Window:AddColorsTab()
		if colorsTab then return colorsTab end;
		colorsTab = settingsPage("Colors", "palette");
		for _, color in ipairs({
			{ "Accent", "accent", "left" }, { "Text", "text", "right" },
			{ "Panel", "panel", "left" }, { "Header", "head", "right" },
			{ "Sidebar", "side", "left" }, { "Outline", "line", "right" },
			{ "Muted", "dim", "left" }, { "Network", "glow", "right" },
			{ "Background", "bg", "left" },
		}) do
			colorsTab:color({ name = color[1], key = color[2], side = laneFor(color[3]) });
		end;
		colorsTab:section({ name = "Default", side = laneFor("right") }):button({
			name = "Reset Colors", icon = "rotate-ccw",
			callback = function() Window:ResetMenuColors() end,
		});
		return colorsTab;
	end;

	local configCard;
	function Window:AddConfigCard()
		if configCard then return configCard end;

		local tab = settingsPage("Configs", "folder");

		tab:configs({ name = "Configs", side = laneFor("left") });

		local card = tab:section({ name = "Clipboard", side = laneFor("right") });
		local function toast(text, failed)
			lib:notify({ title = text, icon = failed and "x" or "check", life = 3 });
		end;

		card:button({
			name = "Copy Config", icon = "copy",
			callback = function()
				local ok, size = lib:clipboardExport();
				toast(ok and "Config copied" or tostring(size), not ok);
			end,
		});

		local field = wrapSection(card):AddLabel("Config"):AddTextInput({ Placeholder = "Ctrl+V a config here" });

		card:button({
			name = "Paste Config", icon = "clipboard-paste",
			callback = function()
				local text = field:GetValue();
				local ok, reason;

				if text ~= "" then
					local data = lib:thaw(text);

					if data then
						ok = lib:apply(data) == true;
						reason = lib.configResult and lib.configResult.errors and lib.configResult.errors[1];
					else
						ok, reason = false, "That is not a config";
					end;

					if ok then field:SetValue("") end;
				else
					ok, reason = lib:clipboardLoad();
				end;

				toast(ok and "Config loaded" or tostring(reason or "Paste a config into the box first"), not ok);
			end,
		});

		configCard = { refresh = function() end };
		return configCard;
	end;

	function Window:AddSettingsSection(name, side)
		return wrapSection(settingsPage("Menu", "sliders-horizontal"):section({
			name = name or "section",
			side = laneFor(side),
		}));
	end;

	Window.UserSettings = setmetatable({}, {
		__index = function(_, key)
			if not settingsSection then
				local tab = settingsPage("Menu", "sliders-horizontal");

				settingsSection = wrapSection(tab:section({ name = "Menu", side = "left" }));

			end;

			local value = settingsSection[key];

			if type(value) ~= "function" then return value end;

			return function(_, ...) return value(settingsSection, ...) end;
		end,
	});

	do

		local keybindPanel = panelFor(false);
		if keybindPanel then
			keybindPanel.AnchorPoint = Vector2.new(0, 1);
			keybindPanel.Position = UDim2.new(0, 10, 1, -10);
		end;
		local panel = panelFor(true);

		if panel then
			local shrink = panel:FindFirstChildOfClass("UIScale")
				or Instance.new("UIScale", panel);

			shrink.Scale = NeverLose.Mobile and 0.85 or 1;
		end;

		if panel and NeverLose.Mobile then

			panel.Active = true;
			local lastWatermarkTap = 0;

			local function toggleFromWatermark()
				local now = os.clock();

				if now - lastWatermarkTap < 0.18 then return end;

				lastWatermarkTap = now;
				pcall(function() win:toggle() end);
			end;

			local UserInputService = game:GetService("UserInputService");
			local GuiService = game:GetService("GuiService");
			local pressedIn, pressedAt, pressedInput;

			local function pointer(input)
				if input.UserInputType == Enum.UserInputType.Touch then
					return Vector2.new(input.Position.X, input.Position.Y);
				end;

				return UserInputService:GetMouseLocation() - GuiService:GetGuiInset();
			end;

			local function over(at)
				local origin = panel.AbsolutePosition;
				local size = panel.AbsoluteSize;

				return at.X >= origin.X and at.X <= origin.X + size.X
					and at.Y >= origin.Y and at.Y <= origin.Y + size.Y;
			end;

			local function pressable(input)
				return input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch;
			end;

			NeverLose:AddSignal(UserInputService.InputBegan:Connect(function(input)
				if not pressable(input) then return end;
				if not (panel.Parent and panel.Visible and lib.watermark) then return end;

				local at = pointer(input);

				pressedIn, pressedAt = over(at) and at or nil, os.clock();
				pressedInput = pressedIn and input or nil;
			end));

			NeverLose:AddSignal(UserInputService.InputEnded:Connect(function(input)
				if not pressable(input) then return end;
				if input ~= pressedInput then return end;

				local start = pressedIn;

				pressedIn = nil;
				pressedInput = nil;

				if not start then return end;

				if (pointer(input) - start).Magnitude > 8 then return end;
				if os.clock() - pressedAt > 0.7 then return end;

				toggleFromWatermark();
			end));

			for _, child in ipairs(panel:GetChildren()) do
				if child:IsA("GuiObject") then
					child.Active = true;

				end;
			end;
		end;

		pcall(function() lib:setopener(false) end);

		local watermarkOn = true;

		function NeverLose.SetWatermark(on)
			watermarkOn = on and true or false;

			pcall(function() lib:setwatermark(watermarkOn) end);

			pcall(function() lib:setopener(NeverLose.Mobile and not watermarkOn) end);
		end;
	end;

	function Window:AddTab(config)
		config = config or {};

		local tab = win:tab({ name = config.Name or "Tab", icon = NeverLose.IconName(config.Icon) });

		if config.Last and tab.head and tab.head.Parent then tab.head.Parent.LayoutOrder = 100000 end;

		local hit = tab.hit;
		tab.hit = function(selected)
			if hit then hit(selected) end;
			if selected then foldOthers(tab) end;
		end;

		local Tab = { __tab = tab, Name = config.Name, Signal = pageSignal(tab) };

		function Tab:AddSection(sectionConfig)
			sectionConfig = sectionConfig or {};

			return wrapSection(tab:section({
				name = sectionConfig.Name or "section",
				side = laneFor(sectionConfig.Position),
			}));
		end;

		function Tab.SetValue(value)
			if value and tab.select then tab:select() end;
		end;

		table.insert(Window.Tabs, Tab);

		return tolerant(Tab);
	end;

	function Window:AddGroup(name, icon, entries)
		local tab = win:tab({ name = name, icon = NeverLose.IconName(icon) });
		local group = { __tab = tab };

		for _, entry in ipairs(entries or {}) do
			local sub = tab:sub({ name = entry.Name, icon = NeverLose.IconName(entry.Icon) });
			local page = { __sub = sub, Name = entry.Name, Signal = pageSignal(sub) };

			function page:AddSection(sectionConfig)
				sectionConfig = sectionConfig or {};

				return wrapSection(sub:section({
					name = sectionConfig.Name or "section",
					side = laneFor(sectionConfig.Position),
				}));
			end;

			function page.SetValue(value)
				if value and sub.select then sub:select() end;
			end;

			function page:AddGallery(cfg)
				cfg = cfg or {};

				return sub:gallery({
					name = cfg.Name or "gallery",
					icon = cfg.Icon and NeverLose.IconName(cfg.Icon) or "image",
					side = laneFor(cfg.Position),
					height = cfg.Height or 260,
					list = cfg.Values or {},
					default = cfg.Default,
					multi = cfg.Multi and true or false,
					reset = cfg.Reset == true,
					thumb = cfg.Thumb or "Asset",
					blank = cfg.Blank and NeverLose.IconName(cfg.Blank) or "image",
					cell = cfg.Cell or 76,
					wrap = cfg.Wrap == true,
					smooth = cfg.Smooth == true,
					search = cfg.Search ~= false,
					tools = cfg.Tools == true,
					buttons = cfg.Buttons,
					action = type(cfg.Action) == "table" and {
						icon = NeverLose.IconName(cfg.Action.Icon or cfg.Action.icon or "sliders-horizontal"),
						callback = cfg.Action.Callback or cfg.Action.callback,
					} or nil,
					context = cfg.Context,
					empty = cfg.Empty or "nothing here",
					flag = cfg.Flag,
					callback = report(cfg.Flag, cfg.Callback),
				});
			end;

			group[entry.Name] = tolerant(page);

			table.insert(Window.Tabs, group[entry.Name]);
		end;

		local remembered = tab.subs and tab.subs[1] or nil;
		local bouncing = false;

		table.insert(groupTabs, tab);

		for _, sub in ipairs(tab.subs or {}) do
			local previous = sub.hit;

			sub.hit = function(selected)
				if selected then remembered = sub end;

				if previous then previous(selected) end;

				if selected then
					settleSoon(sub.page);
					foldOthers(tab);
				end;
			end;
		end;

		local parentHit = tab.hit;

		tab.hit = function(selected)
			if parentHit then parentHit(selected) end;

			if selected then settleSoon(tab.page) end;

			if not (selected and remembered and not bouncing) then return end;

			bouncing = true;

			task.defer(function()
				bouncing = false;
				headerClick = true;

				pcall(function() remembered:select() end);

				headerClick = false;
			end);
		end;

		function group.Select()
			if remembered then pcall(function() remembered:select() end) end;
		end;

		if remembered and win.active == tab then
			task.defer(function() pcall(function() remembered:select() end) end);
		end;

		function group.Toggle()
			if tab.setopen then tab:setopen(not tab.open) end;

			return tab.open;
		end;

		function group.IsOpen() return tab.open end;

		return group;
	end;

	return tolerant(Window);
end;

return NeverLose;
