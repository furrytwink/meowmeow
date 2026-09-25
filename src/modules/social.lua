--!nonstrict
--[[
	social.lua — extracted feature module (require id "modules.social").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("social") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("social", function()
			return require("modules.social")({ ESP = ESP, LocalPlayer = LocalPlayer, NeverLose = NeverLose, Players = Players, Remote = Remote, RunService = RunService, Tabs = Tabs, Window = Window, gethwid = gethwid, http = http, onUnload = onUnload, userFile = userFile, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local Players = ctx.Players;
	local Remote = ctx.Remote;
	local RunService = ctx.RunService;
	local Tabs = ctx.Tabs;
	local Window = ctx.Window;
	local gethwid = ctx.gethwid;
	local http = ctx.http;
	local onUnload = ctx.onUnload;
	local userFile = ctx.userFile;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("social") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local HttpService = game:GetService("HttpService");
	local MarketplaceService = game:GetService("MarketplaceService");
	local UserInputService = game:GetService("UserInputService");
	local TweenService = game:GetService("TweenService");
	local CoreGui = game:GetService("CoreGui");
	local lib = NeverLose.Lib;
	local th = lib.theme;

	local origin = (Remote.base ~= "" and string.match(Remote.base, "^(%a+://[^/]+)")) or "https://inertiahub.xyz";
	local API = origin .. "/api/visuals";
	local me = tostring(LocalPlayer.UserId);
	local grab = (syn and syn.request) or (http and http.request)
		or (getgenv and (rawget(getgenv(), "http_request") or rawget(getgenv(), "request")))
		or http_request or request;

	local placeName = "Roblox";
	task.spawn(function()
		local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end);
		if ok and type(info) == "table" and type(info.Name) == "string" then placeName = info.Name:sub(1, 60) end;
	end);

	local function call(method, path, body)
		if type(grab) ~= "function" then
			if method ~= "GET" then return nil end;
			local ok, text = pcall(function() return game:HttpGet(API .. path, true) end);
			if not ok then return nil end;
			local fine, data = pcall(function() return HttpService:JSONDecode(text) end);
			return (fine and type(data) == "table" and data.ok) and data.data or nil;
		end;

		local ok, res = pcall(grab, {
			Url = API .. path,
			Method = method,
			Headers = { ["Content-Type"] = "application/json", Accept = "application/json" },
			Body = body and HttpService:JSONEncode(body) or nil,
		});

		if not (ok and type(res) == "table") then return nil end;

		local fine, data = pcall(function() return HttpService:JSONDecode(res.Body) end);

		if fine and type(data) == "table" and data.ok then return data.data end;

		return nil, tonumber(res.StatusCode) or 0, (fine and type(data) == "table") and data.error or nil;
	end;

	local function make(class, props, parent)
		local object = Instance.new(class);
		for key, value in pairs(props) do object[key] = value end;
		object.Parent = parent;
		return object;
	end;

	local function tween(object, time, props, style)
		local t = TweenService:Create(object, TweenInfo.new(time, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props);
		t:Play();
		return t;
	end;

	local function icon(name)
		local id = lib.icons and lib.icons[name];
		return id and ("rbxassetid://" .. id) or "";
	end;

	local function onColor(c)
		return (0.299 * c.R + 0.587 * c.G + 0.114 * c.B) > 0.6 and Color3.fromRGB(18, 18, 22) or Color3.new(1, 1, 1);
	end;

	local S = { On = true };
	ESP.Share = S;

	local KORBLOX = {
		RightUpperLeg = { MeshId = "rbxassetid://902942096", TextureID = "rbxassetid://902843398" },
		RightLowerLeg = { MeshId = "rbxassetid://902942093", Transparency = 1 },
		RightFoot = { MeshId = "rbxassetid://902942089", Transparency = 1 },
	};

	local marks = {};

	local function restoreSaved(mark)
		for part, saved in pairs(mark.saved) do
			if part.Parent then
				for key, value in pairs(saved) do pcall(function() part[key] = value end) end;
			end;
		end;

		table.clear(mark.saved);
	end;

	local function clearMark(player)
		local mark = marks[player];
		if not mark then return end;

		restoreSaved(mark);

		for part in pairs(mark.hidden) do
			if part.Parent then pcall(function() part.LocalTransparencyModifier = 0 end) end;
		end;

		marks[player] = nil;
	end;

	local function wearFlags(player, flags)
		local set = {};
		for _, flag in ipairs(flags or {}) do set[tostring(flag)] = true end;

		if not next(set) then clearMark(player); return end;

		marks[player] = marks[player] or { saved = {}, hidden = {} };
		marks[player].set = set;
	end;

	local function paintMark(player, mark)
		local char = player.Character;
		if not char then return end;

		local now = {};
		local head = char:FindFirstChild("Head");

		if mark.set.headless and head then now[head] = true end;

		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Accessory") then
				local handle = item:FindFirstChild("Handle");
				local hair = item.AccessoryType == Enum.AccessoryType.Hair
					or string.find(string.lower(item.Name), "hair", 1, true) ~= nil;

				if handle and (mark.set.noacc or (mark.set.hairless and hair)) then now[handle] = true end;
			end;
		end;

		for part in pairs(mark.hidden) do
			if not now[part] and part.Parent then pcall(function() part.LocalTransparencyModifier = 0 end) end;
		end;

		for part in pairs(now) do part.LocalTransparencyModifier = 1 end;
		mark.hidden = now;

		if mark.set.korblox then
			for name, look in pairs(KORBLOX) do
				local part = char:FindFirstChild(name);

				if part and part:IsA("MeshPart") then
					if not mark.saved[part] then
						mark.saved[part] = { MeshId = part.MeshId, TextureID = part.TextureID, Transparency = part.Transparency };
					end;

					for key, value in pairs(look) do pcall(function() part[key] = value end) end;
				end;
			end;
		elseif next(mark.saved) then
			restoreSaved(mark);
		end;
	end;

	local tagHome = Instance.new("Folder");
	tagHome.Name = NeverLose.RandomString();
	tagHome.Parent = CoreGui;
	onUnload("salad tags", function() pcall(function() tagHome:Destroy() end) end);

	local tags = {};
	local okFont, listFont = pcall(function() return Enum.Font.BuilderSansBold end);
	if not okFont then listFont = Enum.Font.GothamBold end;

	local function tagOn(player)
		if player == LocalPlayer then return end;

		local tag = tags[player];

		if not tag then
			local board = make("BillboardGui", {
				Name = NeverLose.RandomString(), Size = UDim2.fromScale(3, 0.62), AlwaysOnTop = false,
				StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0), MaxDistance = 90, LightInfluence = 0,
			}, tagHome);
			make("TextLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "<> Salad",
				TextColor3 = Color3.new(1, 1, 1), TextScaled = true, TextStrokeColor3 = Color3.new(0, 0, 0),
				TextStrokeTransparency = 0.65,
			}, board);

			tag = { board = board };
			tags[player] = tag;
		end;

		local char = player.Character;
		local head = char and char:FindFirstChild("Head");

		if tag.board.Adornee ~= head then tag.board.Adornee = head end;
	end;

	local function tagOff(player)
		local tag = tags[player];
		if not tag then return end;

		pcall(function() tag.board:Destroy() end);
		if tag.listPill then pcall(function() tag.listPill:Destroy() end) end;
		if tag.cap then pcall(function() tag.cap:Destroy() end) end;
		tags[player] = nil;
	end;

	local function markEntry(coreList, player, tag)
		if not (tag.entry and tag.entry.Parent) then
			tag.entry = coreList:FindFirstChild("PlayerEntry_" .. player.UserId, true);
			tag.label = nil;
		end;

		local entry = tag.entry;
		if not entry then return end;

		if not (tag.label and tag.label.Parent) then
			tag.label = nil;

			for _, d in ipairs(entry:GetDescendants()) do
				if d:IsA("TextLabel") and d.Name == "PlayerName" then tag.label = d; break end;
			end;
		end;

		local label = tag.label;
		if not label then return end;

		if not (tag.listPill and tag.listPill.Parent == label.Parent) then
			if tag.listPill then pcall(function() tag.listPill:Destroy() end) end;
			tag.listPill = make("TextLabel", {
				Name = NeverLose.RandomString(), AnchorPoint = Vector2.new(0, 0.5), AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, 16), BackgroundTransparency = 1, Font = listFont, Text = "<> Salad",
				TextColor3 = label.TextColor3, TextTransparency = 0.45, TextSize = math.max(label.TextSize - 3, 11),
				ZIndex = label.ZIndex,
			}, label.Parent);
		end;

		if not (tag.cap and tag.cap.Parent == label) then
			if tag.cap then pcall(function() tag.cap:Destroy() end) end;
			tag.cap = make("UISizeConstraint", {}, label);
			label.TextTruncate = Enum.TextTruncate.AtEnd;
		end;

		local left = label.Position.X.Offset;
		local room = label.Parent.AbsoluteSize.X - tag.listPill.AbsoluteSize.X - 8 - left;
		tag.cap.MaxSize = Vector2.new(math.max(room, 24), math.huge);
		tag.listPill.Position = UDim2.new(0, left + math.min(label.TextBounds.X, label.AbsoluteSize.X) + 6, 0.5, 0);
	end;

	task.spawn(function()
		while __ALIVE() do
			task.wait(0.5);

			if next(tags) then
				local coreList = CoreGui:FindFirstChild("PlayerList");

				if coreList then
					for player, tag in pairs(tags) do pcall(markEntry, coreList, player, tag) end;
				end;
			end;
		end;
	end);

	local function stateNow()
		local auras, cosmetics, trail = {}, {}, nil;

		for _, entry in ipairs(ESP.GameFX and ESP.GameFX.WornList() or {}) do
			if entry.group == "cosmetic" then cosmetics[#cosmetics + 1] = entry.id
			elseif entry.group == "trail" then trail = entry.id
			else auras[#auras + 1] = entry.id end;
		end;

		local flags = {};
		for flag, name in pairs({ korblox_leg = "korblox", headless = "headless", hairless = "hairless", no_accessories = "noacc" }) do
			local item = lib.pool[flag];
			if item and item.get() == true then flags[#flags + 1] = name end;
		end;

		local builtin, colour = {}, nil;
		local AU = ESP.Aura;

		if AU and AU.On then
			for name in pairs(AU.Types or {}) do builtin[#builtin + 1] = name end;
			table.sort(builtin);
			colour = AU.Color and AU.Color:ToHex() or nil;
		end;

		local btrail = ESP.Trail and ESP.Trail.Worn and ESP.Trail.Worn() or nil;

		return { auras = auras, trail = trail, cosmetics = cosmetics, flags = flags,
			builtin = builtin, color = colour, btrail = btrail };
	end;

	local function forgetEveryone()
		for player in pairs(marks) do clearMark(player) end;
		for player in pairs(tags) do tagOff(player) end;
		for player in pairs(ESP.GameFX and ESP.GameFX.Guests() or {}) do pcall(ESP.GameFX.Undress, player) end;
		for player in pairs(ESP.Aura and ESP.Aura.Guests and ESP.Aura.Guests() or {}) do pcall(ESP.Aura.Undress, player) end;
		for player in pairs(ESP.Trail and ESP.Trail.Guests and ESP.Trail.Guests() or {}) do pcall(ESP.Trail.Undress, player) end;
	end;

	task.spawn(function()
		while __ALIVE() do
			task.wait(3);

			if S.On then

				call("POST", "/share", {
					userId = me, name = LocalPlayer.DisplayName, place = placeName,
					placeId = tostring(game.PlaceId), gameId = tostring(game.GameId), jobId = game.JobId, state = stateNow(),
				});

				local data = call("GET", "/share?job=" .. HttpService:UrlEncode(game.JobId) .. "&me=" .. me);
				local seen = {};

				if S.On and data and type(data.users) == "table" then
					for _, entry in ipairs(data.users) do
						local player = Players:GetPlayerByUserId(tonumber(entry.userId) or 0);
						local state = type(entry.state) == "table" and entry.state or nil;

						if player and player ~= LocalPlayer and state then
							seen[player] = true;
							tagOn(player);

							local list = {};

							for _, id in ipairs(state.auras or {}) do list[#list + 1] = { id = id, group = "aura" } end;
							for _, id in ipairs(state.cosmetics or {}) do list[#list + 1] = { id = id, group = "cosmetic" } end;
							if type(state.trail) == "string" then list[#list + 1] = { id = state.trail, group = "trail" } end;

							if ESP.GameFX then ESP.GameFX.Dress(player, list) end;
							wearFlags(player, state.flags);

							if ESP.Aura and ESP.Aura.Dress then
								local ok, colour = pcall(Color3.fromHex, tostring(state.color or ""));
								ESP.Aura.Dress(player, type(state.builtin) == "table" and state.builtin or {}, ok and colour or nil);
							end;

							if ESP.Trail and ESP.Trail.Dress then
								if type(state.btrail) == "table" then
									pcall(ESP.Trail.Dress, player, state.btrail);
								else
									pcall(ESP.Trail.Undress, player);
								end;
							end;
						end;
					end;

					for player in pairs(marks) do if not seen[player] then clearMark(player) end end;
					for player in pairs(tags) do if not seen[player] then tagOff(player) end end;

					for player in pairs(ESP.GameFX and ESP.GameFX.Guests() or {}) do
						if not seen[player] then pcall(ESP.GameFX.Undress, player) end;
					end;

					for player in pairs(ESP.Aura and ESP.Aura.Guests and ESP.Aura.Guests() or {}) do
						if not seen[player] then pcall(ESP.Aura.Undress, player) end;
					end;

					for player in pairs(ESP.Trail and ESP.Trail.Guests and ESP.Trail.Guests() or {}) do
						if not seen[player] then pcall(ESP.Trail.Undress, player) end;
					end;
				end;
			end;
		end;
	end);

	NeverLose:AddSignal(RunService.Heartbeat:Connect(function()
		if not S.On then return end;

		for player, mark in pairs(marks) do
			if player.Parent then pcall(paintMark, player, mark) else clearMark(player) end;
		end;
	end));

	NeverLose:AddSignal(Players.PlayerRemoving:Connect(function(player)
		clearMark(player);
		tagOff(player);
	end));

	local function stopSharing()
		forgetEveryone();
		task.spawn(function() call("POST", "/share", { userId = me, name = LocalPlayer.DisplayName, jobId = game.JobId, state = nil }) end);
	end;

	Window.UserSettings:AddLabel("Share Function"):AddToggle({
		Default = true, Flag = "share",
		Callback = function(v)
			local was = S.On;
			S.On = v == true;
			if was and not S.On then stopSharing() end;
		end,
	});

	onUnload("social share", function()
		if S.On then stopSharing() else forgetEveryone() end;
	end);

	local chatTab = Tabs.Chat;
	local page = chatTab and chatTab.__tab and chatTab.__tab.page;
	if not page then return end;

	local EMOJI = { "\240\159\145\141", "\226\157\164\239\184\143", "\240\159\152\130", "\240\159\148\165", "\240\159\146\128", "\240\159\145\128" };
	local LIMIT = 300;
	local AVATAR = 28;
	local MOBILE = NeverLose.Mobile == true;

	local adminKey;
	pcall(function()
		local path = userFile("admin.key");
		if isfile and readfile and isfile(path) then adminKey = readfile(path):gsub("%s", "") end;
	end);
	if adminKey == "" then adminKey = nil end;
	local ADMIN = adminKey ~= nil;

	local hardware;
	pcall(function()
		if type(gethwid) == "function" then hardware = tostring(gethwid()):sub(1, 200) end;
	end);

	local function escape(text)
		return (tostring(text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;"));
	end;

	local function theirs() return th.head:Lerp(th.line, 0.22) end;
	local function ours() return th.accent:Lerp(th.head, 0.84) end;

	local root = make("Frame", {
		Name = NeverLose.RandomString(), Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 1, -34),
		BackgroundColor3 = th.panel, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 20,
	}, page);
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, root);
	make("UIStroke", { Color = th.line, Transparency = 0.7 }, root);

	local list = make("ScrollingFrame", {
		Name = NeverLose.RandomString(), BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -56), CanvasSize = UDim2.new(), ScrollBarThickness = 2,
		ScrollBarImageColor3 = th.dim, ScrollBarImageTransparency = 0.6,
		ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 21,
	}, root);
	local layout = make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom,
	}, list);
	make("UIPadding", {
		PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12),
	}, list);

	local empty = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -28), Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = "No messages yet", TextColor3 = th.dim,
		TextSize = 12, TextTransparency = 0.35, ZIndex = 22,
	}, root);

	local bar = make("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 40),
		BackgroundColor3 = th.head, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 25,
	}, root);
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, bar);
	local barEdge = make("UIStroke", { Color = th.line, Transparency = 0.55 }, bar);

	local replyBar = make("Frame", {
		Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Visible = false, ZIndex = 26,
	}, bar);
	make("Frame", {
		Position = UDim2.fromOffset(12, 8), Size = UDim2.fromOffset(2, 22), BackgroundColor3 = th.dim,
		BorderSizePixel = 0, ZIndex = 27,
	}, replyBar);
	local replyWho = make("TextLabel", {
		Position = UDim2.fromOffset(21, 7), Size = UDim2.new(1, -60, 0, 12), BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, Text = "", TextColor3 = th.text, TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 27,
	}, replyBar);
	local replySnip = make("TextLabel", {
		Position = UDim2.fromOffset(21, 19), Size = UDim2.new(1, -60, 0, 12), BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium, Text = "", TextColor3 = th.dim, TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 27,
	}, replyBar);
	local replyClose = make("ImageButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1, Image = icon("x"), ImageColor3 = th.dim, ZIndex = 27,
	}, replyBar);
	make("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, 0), Size = UDim2.new(1, -24, 0, 1),
		BackgroundColor3 = th.line, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 27,
	}, replyBar);

	local field = make("TextBox", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12), Size = UDim2.new(1, -56, 0, 16),
		BackgroundTransparency = 1, ClearTextOnFocus = false, MultiLine = false, TextWrapped = true,
		Font = Enum.Font.GothamMedium, PlaceholderText = ADMIN and "Message or /command" or "Message",
		PlaceholderColor3 = th.dim, Text = "", TextColor3 = th.text, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 26,
	}, bar);

	local send = make("ImageButton", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -6, 1, -6), Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = th.accent, BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false,
		Image = "", ZIndex = 26,
	}, bar);
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, send);
	local sendGlyph = make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, -1, 0.5, 1), Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1, Image = icon("send"), ImageColor3 = th.dim, ZIndex = 27,
	}, send);

	local suggest = make("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -56), Size = UDim2.new(1, -16, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = th.head, BorderSizePixel = 0, Visible = false, ZIndex = 35,
	}, root);
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, suggest);
	make("UIStroke", { Color = th.line, Transparency = 0.5 }, suggest);
	make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, suggest);
	make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1) }, suggest);

	local jump = make("ImageButton", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -66), Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = th.head, BorderSizePixel = 0, AutoButtonColor = false, Image = "", Visible = false, ZIndex = 30,
	}, root);
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, jump);
	make("UIStroke", { Color = th.line, Transparency = 0.5 }, jump);
	make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1, Image = icon("chevron-down"), ImageColor3 = th.text, ZIndex = 31,
	}, jump);
	local jumpCount = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(0, 15),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = th.accent, BorderSizePixel = 0, Font = Enum.Font.GothamBold,
		Text = "", TextColor3 = onColor(th.accent), TextSize = 10, Visible = false, ZIndex = 32,
	}, jump);
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, jumpCount);
	make("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, jumpCount);

	local tabBadge = make("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(0, 15),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = th.accent, BorderSizePixel = 0, Font = Enum.Font.GothamBold,
		Text = "", TextColor3 = onColor(th.accent), TextSize = 10, Visible = false, ZIndex = 9,
	}, chatTab.__tab.head);
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, tabBadge);
	make("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, tabBadge);

	local shade = make("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 40,
	}, root);
	local menu = make("Frame", {
		Size = UDim2.fromOffset(196, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = th.head,
		BorderSizePixel = 0, Visible = false, ZIndex = 41,
	}, root);
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, menu);
	make("UIStroke", { Color = th.line, Transparency = 0.45 }, menu);
	make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, menu);
	make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, menu);

	local emojiRow = make("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 1, ZIndex = 42 }, menu);
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
	}, emojiRow);
	make("Frame", {
		Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = th.line, BackgroundTransparency = 0.6, BorderSizePixel = 0,
		LayoutOrder = 2, ZIndex = 42,
	}, menu);

	local menuTarget;
	local emojiButtons = {};
	for index, emoji in ipairs(EMOJI) do
		local button = make("TextButton", {
			Size = UDim2.fromOffset(30, 30), BackgroundColor3 = th.line, BackgroundTransparency = 1, AutoButtonColor = false,
			Font = Enum.Font.GothamMedium, Text = emoji, TextSize = 16, TextColor3 = th.text, LayoutOrder = index, ZIndex = 43,
		}, emojiRow);
		make("UICorner", { CornerRadius = UDim.new(0, 6) }, button);
		NeverLose:AddSignal(button.MouseEnter:Connect(function() button.BackgroundTransparency = 0.6 end));
		NeverLose:AddSignal(button.MouseLeave:Connect(function() button.BackgroundTransparency = 1 end));
		emojiButtons[#emojiButtons + 1] = { button = button, emoji = emoji };
	end;

	local function menuItem(text, order)
		local item = make("TextButton", {
			Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = th.line, BackgroundTransparency = 1, AutoButtonColor = false,
			Font = Enum.Font.GothamMedium, Text = text, TextColor3 = th.text, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order, ZIndex = 43,
		}, menu);
		make("UICorner", { CornerRadius = UDim.new(0, 6) }, item);
		make("UIPadding", { PaddingLeft = UDim.new(0, 8) }, item);
		NeverLose:AddSignal(item.MouseEnter:Connect(function() item.BackgroundTransparency = 0.6 end));
		NeverLose:AddSignal(item.MouseLeave:Connect(function() item.BackgroundTransparency = 1 end));
		return item;
	end;

	local replyItem = menuItem("Reply", 3);
	local copyItem = menuItem("Copy Text", 4);
	local deleteItem = menuItem("Delete", 5);
	deleteItem.TextColor3 = Color3.fromRGB(255, 120, 120);

	local rows, byId, order = {}, {}, {};
	local seq, lastAt, unread, tabUnread, notes = 0, 0, 0, 0, 0;
	local atBottom, filled, replying = true, false, nil;
	local parked, wasActive = false, false;

	local function active()
		return page.Visible and lib.shown == true;
	end;

	local function bodyWidth(mine)
		return math.max(math.floor(list.AbsoluteSize.X * 0.72) - 20 - (mine and 0 or AVATAR + 8), 120);
	end;

	local function range()
		return math.max(list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y, 0);
	end;

	local function paintJump()
		jump.Visible = not atBottom;
		jumpCount.Visible = unread > 0;
		jumpCount.Text = tostring(unread);
	end;

	local function paintBadge()
		tabBadge.Visible = tabUnread > 0;
		tabBadge.Text = tabUnread > 99 and "99+" or tostring(tabUnread);
	end;

	local function fitCanvas()
		list.CanvasSize = UDim2.fromOffset(0, math.max(layout.AbsoluteContentSize.Y + 16, list.AbsoluteWindowSize.Y));
	end;

	NeverLose:AddSignal(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local stay = atBottom;
		fitCanvas();

		if stay then list.CanvasPosition = Vector2.new(0, range()) end;
	end));

	NeverLose:AddSignal(list:GetPropertyChangedSignal("CanvasPosition"):Connect(function()

		if not active() then return end;

		atBottom = range() - list.CanvasPosition.Y < 40;
		if atBottom and unread > 0 then unread = 0 end;
		paintJump();
	end));

	local function toBottom()
		atBottom, unread = true, 0;
		list.CanvasPosition = Vector2.new(0, range());
		paintJump();
	end;

	NeverLose:AddSignal(jump.MouseButton1Click:Connect(toBottom));

	local function appear(object)
		local jobs = {};

		local function note(o)
			if o:IsA("GuiObject") and o.BackgroundTransparency < 1 then jobs[#jobs + 1] = { o, "BackgroundTransparency", o.BackgroundTransparency } end;
			if o:IsA("TextLabel") or o:IsA("TextButton") then jobs[#jobs + 1] = { o, "TextTransparency", o.TextTransparency } end;
			if o:IsA("ImageLabel") or o:IsA("ImageButton") then jobs[#jobs + 1] = { o, "ImageTransparency", o.ImageTransparency } end;
			if o:IsA("UIStroke") then jobs[#jobs + 1] = { o, "Transparency", o.Transparency } end;
		end;

		note(object);
		for _, d in ipairs(object:GetDescendants()) do note(d) end;

		for _, job in ipairs(jobs) do
			job[1][job[2]] = 1;
			tween(job[1], 0.16, { [job[2]] = job[3] });
		end;
	end;

	local function layoutComposer()
		local text = math.clamp(field.TextBounds.Y, 16, 64);
		local height = text + 24 + (replying and 36 or 0);

		field.Size = UDim2.new(1, -56, 0, text);
		bar.Size = UDim2.new(1, -16, 0, height);
		list.Size = UDim2.new(1, 0, 1, -(height + 16));
		jump.Position = UDim2.new(1, -16, 1, -(height + 26));
		suggest.Position = UDim2.new(0, 8, 1, -(height + 14));
	end;

	local function paintSend()
		local ready = field.Text:match("%S") ~= nil;
		send.BackgroundTransparency = ready and 0 or 1;
		sendGlyph.ImageColor3 = ready and onColor(th.accent) or th.dim;
	end;

	local function focus()

		if MOBILE then return end;
		if active() and not menu.Visible and not field:IsFocused() then
			pcall(function() field:CaptureFocus() end);
		end;
	end;

	local function setReply(message)
		replying = message;

		if message then
			replyWho.Text = message.name;
			replySnip.Text = message.body;
			replyBar.Visible = true;
		else
			replyBar.Visible = false;
		end;

		layoutComposer();
	end;

	NeverLose:AddSignal(replyClose.MouseButton1Click:Connect(function() setReply(nil); focus() end));

	local paintRow;

	local function relayout()
		for index, message in ipairs(order) do
			local prev, nxt = order[index - 1], order[index + 1];
			local row = rows[message.id];

			if row then
				local joins = function(a, b)
					return a and b and not a.system and not b.system and a.userId == b.userId and math.abs((b.at or 0) - (a.at or 0)) < 300;
				end;
				row.first = not joins(prev, message);
				row.last = not joins(message, nxt);
				row.frame.LayoutOrder = index;
				paintRow(row, message);
			end;
		end;

		empty.Visible = #order == 0;
	end;

	local function scrollTo(id)
		local row = rows[id];
		if not row or not row.bubble then return end;

		local y = row.frame.AbsolutePosition.Y - list.AbsolutePosition.Y + list.CanvasPosition.Y - list.AbsoluteWindowSize.Y * 0.35;
		list.CanvasPosition = Vector2.new(0, math.clamp(y, 0, range()));

		local base = row.bubble.BackgroundColor3;
		row.bubble.BackgroundColor3 = base:Lerp(th.accent, 0.18);
		tween(row.bubble, 0.8, { BackgroundColor3 = base });
	end;

	local openMenu;

	local function sizeRow(row)
		local inner = row.bubble or row.note;
		row.frame.Size = UDim2.new(1, 0, 0, row.gap + inner.AbsoluteSize.Y);
	end;

	local function noteRow(message)
		local row = { system = true, gap = 8, first = true, last = true };

		row.frame = make("Frame", {
			Name = NeverLose.RandomString(), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), ZIndex = 22,
		}, list);
		row.note = make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromOffset(0, 0), BackgroundColor3 = th.head, BorderSizePixel = 0, Font = Enum.Font.GothamMedium,
			Text = message.body, TextColor3 = th.dim, TextSize = 11, ZIndex = 23,
		}, row.frame);
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, row.note);
		make("UIPadding", {
			PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
		}, row.note);
		row.note:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() sizeRow(row) end);

		return row;
	end;

	local function newRow(message)
		if message.system then return noteRow(message) end;

		local mine = message.userId == me;
		local row = { mine = mine, gap = 2, first = true, last = true };

		row.frame = make("Frame", {
			Name = NeverLose.RandomString(), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), ZIndex = 22,
		}, list);

		if not mine then
			row.avatar = make("ImageLabel", {
				AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(AVATAR, AVATAR),
				BackgroundColor3 = th.head, BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop, ZIndex = 23,
				Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48"):format(tonumber(message.userId) or 1),
			}, row.frame);
			make("UICorner", { CornerRadius = UDim.new(1, 0) }, row.avatar);
		end;

		row.bubble = make("TextButton", {
			Name = NeverLose.RandomString(), AutoButtonColor = false, Text = "", AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromOffset(0, 0), AnchorPoint = Vector2.new(mine and 1 or 0, 0),
			Position = mine and UDim2.new(1, 0, 0, 2) or UDim2.fromOffset(AVATAR + 8, 2),
			BackgroundColor3 = mine and ours() or theirs(), BorderSizePixel = 0, ZIndex = 23,
		}, row.frame);
		make("UICorner", { CornerRadius = UDim.new(0, 8) }, row.bubble);
		make("UIPadding", {
			PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		}, row.bubble);

		row.col = make("Frame", {
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), ZIndex = 24,
		}, row.bubble);
		make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }, row.col);

		row.head = make("Frame", {
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
			LayoutOrder = 1, Visible = false, ZIndex = 24,
		}, row.col);
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5),
		}, row.head);
		row.tag = make("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 14), BackgroundColor3 = th.accent,
			BorderSizePixel = 0, Font = Enum.Font.GothamBold, Text = "</> Dev", TextColor3 = onColor(th.accent),
			TextSize = 9, LayoutOrder = 1, Visible = false, ZIndex = 25,
		}, row.head);
		make("UICorner", { CornerRadius = UDim.new(0, 4) }, row.tag);
		make("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, row.tag);
		row.who = make("TextLabel", {
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), RichText = true,
			Font = Enum.Font.GothamMedium, Text = "", TextColor3 = th.text, TextSize = 12, LayoutOrder = 2,
			TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 24,
		}, row.head);
		row.headCap = make("UISizeConstraint", { MaxSize = Vector2.new(bodyWidth(mine) - 50, math.huge) }, row.who);

		row.body = make("TextLabel", {
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), RichText = true,
			Font = Enum.Font.GothamMedium, Text = "", TextColor3 = th.text, TextSize = 13, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 3, ZIndex = 24,
		}, row.col);
		row.bodyCap = make("UISizeConstraint", { MaxSize = Vector2.new(bodyWidth(mine), math.huge) }, row.body);

		row.bubble:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() sizeRow(row) end);
		row.bubble.MouseButton1Click:Connect(function()
			local current = byId[row.id];
			if current then openMenu(row, current) end;
		end);
		row.bubble.MouseButton2Click:Connect(function()
			local current = byId[row.id];
			if current then openMenu(row, current) end;
		end);

		return row;
	end;

	local function reactionKey(message)
		local parts = {};

		for _, emoji in ipairs(EMOJI) do
			local who = message.reactions and message.reactions[emoji];
			if type(who) == "table" and #who > 0 then
				parts[#parts + 1] = emoji .. #who .. (table.find(who, me) and "*" or "");
			end;
		end;

		return table.concat(parts, ",");
	end;

	local function react(message, emoji)
		if message.pending or message.failed or message.system then return end;

		message.reactions = message.reactions or {};
		local who = message.reactions[emoji] or {};
		local at = table.find(who, me);

		if at then table.remove(who, at) else who[#who + 1] = me end;

		message.reactions[emoji] = #who > 0 and who or nil;

		local row = rows[message.id];
		if row then paintRow(row, message) end;

		task.spawn(function() call("POST", "/chat/react", { userId = me, messageId = message.id, emoji = emoji }) end);
	end;

	function paintRow(row, message)
		row.id = message.id;

		if row.system then
			task.defer(sizeRow, row);
			return;
		end;

		local mine = row.mine;
		local admin = message.role == "admin";
		local key = table.concat({
			message.body, tostring(message.replyTo), reactionKey(message), tostring(row.first), tostring(row.last),
			tostring(message.pending), tostring(message.failed), tostring(admin),
		}, "|");

		if key == row.key then return end;
		row.key = key;

		row.gap = row.first and 10 or 2;
		row.bubble.Position = mine and UDim2.new(1, 0, 0, row.gap) or UDim2.fromOffset(AVATAR + 8, row.gap);

		if row.avatar then row.avatar.Visible = row.last end;

		row.head.Visible = row.first and (not mine or admin);
		row.tag.Visible = admin;
		if row.head.Visible then
			row.who.Text = ('<b>%s</b>%s'):format(
				escape(message.name),
				message.place ~= "" and ('  <font color="#%s" size="11">%s</font>'):format(th.dim:ToHex(), escape(message.place)) or ""
			);
		end;

		local parent = message.replyTo and byId[message.replyTo];

		if row.quote then row.quote:Destroy(); row.quote = nil end;

		if parent and not parent.system then
			local quote = make("TextButton", {
				AutoButtonColor = false, Text = "", AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
				BackgroundColor3 = th.bg, BackgroundTransparency = 0.55, BorderSizePixel = 0, LayoutOrder = 2, ZIndex = 24,
			}, row.col);
			make("UICorner", { CornerRadius = UDim.new(0, 5) }, quote);
			make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4) }, quote);
			make("Frame", { Size = UDim2.new(0, 2, 1, 4), BackgroundColor3 = th.dim, BorderSizePixel = 0, ZIndex = 25 }, quote);

			local inner = make("Frame", {
				Position = UDim2.fromOffset(8, 4), AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1, ZIndex = 25,
			}, quote);
			make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1) }, inner);

			for index, spec in ipairs({
				{ parent.name, Enum.Font.GothamBold, th.text },
				{ parent.body, Enum.Font.GothamMedium, th.dim },
			}) do
				local line = make("TextLabel", {
					AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1,
					Font = spec[2], Text = spec[1], TextColor3 = spec[3], TextSize = 11,
					TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = index, ZIndex = 25,
				}, inner);
				make("UISizeConstraint", { MaxSize = Vector2.new(bodyWidth(mine) - 18, math.huge) }, line);
			end;

			quote.MouseButton1Click:Connect(function() scrollTo(parent.id) end);
			row.quote = quote;
		end;

		local tail;

		if message.failed then
			tail = '<font color="#ff7878">not sent</font>';
		elseif message.pending then
			tail = "...";
		else
			tail = os.date("%H:%M", math.floor(tonumber(message.at) or os.time()));
		end;

		row.body.Text = ('%s   <font size="10" color="#%s">%s</font>'):format(escape(message.body), th.dim:ToHex(), tail);

		if row.chips then row.chips:Destroy(); row.chips = nil end;

		local any = false;
		for _, emoji in ipairs(EMOJI) do
			local who = message.reactions and message.reactions[emoji];
			if type(who) == "table" and #who > 0 then any = true; break end;
		end;

		if any then
			row.chips = make("Frame", {
				BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), LayoutOrder = 4, ZIndex = 24,
			}, row.col);
			make("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4),
			}, row.chips);

			for index, emoji in ipairs(EMOJI) do
				local who = message.reactions[emoji];

				if type(who) == "table" and #who > 0 then
					local lit = table.find(who, me) ~= nil;
					local chip = make("TextButton", {
						AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), AutoButtonColor = false,
						BackgroundColor3 = th.bg, BackgroundTransparency = 0.45, BorderSizePixel = 0, Font = Enum.Font.GothamBold,
						Text = emoji .. " " .. #who, TextColor3 = th.text, TextSize = 11, LayoutOrder = index, ZIndex = 25,
					}, row.chips);
					make("UICorner", { CornerRadius = UDim.new(1, 0) }, chip);
					make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 7) }, chip);
					if lit then make("UIStroke", { Color = th.text, Transparency = 0.55 }, chip) end;

					chip.MouseButton1Click:Connect(function()
						local current = byId[row.id];
						if current then react(current, emoji) end;
					end);
				end;
			end;
		end;

		task.defer(sizeRow, row);
	end;

	local function drop(message)
		local row = rows[message.id];
		if row then row.frame:Destroy(); rows[message.id] = nil end;
		byId[message.id] = nil;
	end;

	local function sortOrder()
		table.sort(order, function(a, b)
			local x, y = a.pending and math.huge or (a.at or 0), b.pending and math.huge or (b.at or 0);
			if x ~= y then return x < y end;
			return (a.seq or 0) < (b.seq or 0);
		end);
	end;

	local function settle(temp, real)
		real.seq = temp.seq;
		byId[temp.id] = nil;
		byId[real.id] = real;
		rows[real.id] = rows[temp.id];
		rows[temp.id] = nil;

		for index, message in ipairs(order) do
			if message == temp then order[index] = real; break end;
		end;
	end;

	local function pendingFor(message)
		for _, known in ipairs(order) do
			if known.pending and known.userId == message.userId and known.body == message.body then return known end;
		end;

		return nil;
	end;

	local function absorb(messages, full)
		if type(messages) ~= "table" then return end;

		local fresh, fromOthers = {}, 0;
		local present = {};

		for _, message in ipairs(messages) do
			if type(message) == "table" and type(message.id) == "string" and type(message.body) == "string" then
				message.userId = tostring(message.userId);
				message.name = tostring(message.name or "player");
				message.place = tostring(message.place or "");
				present[message.id] = true;

				local known = byId[message.id];

				if known then
					known.reactions = message.reactions or {};
				else
					local temp = message.userId == me and not message.pending and not message.system and pendingFor(message);

					if temp then
						settle(temp, message);
					else
						seq += 1;
						message.seq = seq;
						byId[message.id] = message;
						order[#order + 1] = message;
						rows[message.id] = newRow(message);
						fresh[#fresh + 1] = message;
						if message.userId ~= me and not message.system then fromOthers += 1 end;
					end;
				end;

				if not message.pending and not message.system and (tonumber(message.at) or 0) > lastAt then lastAt = tonumber(message.at) end;
			end;
		end;

		if full then
			for index = #order, 1, -1 do
				local message = order[index];
				if not message.pending and not message.failed and not message.system and not present[message.id] then
					drop(message);
					table.remove(order, index);
				end;
			end;
		end;

		sortOrder();

		while #order > 80 do drop(table.remove(order, 1)) end;

		relayout();

		if filled and #fresh > 0 then
			for _, message in ipairs(fresh) do
				local row = rows[message.id];
				if row then appear(row.bubble or row.note) end;
			end;

			if fromOthers > 0 then
				if not atBottom then unread += fromOthers end;
				if not active() then tabUnread += fromOthers; paintBadge() end;
			end;

			paintJump();
		end;

		filled = true;
	end;

	local function note(text)
		notes += 1;
		absorb({ { id = "note:" .. notes, system = true, userId = "", name = "", place = "", body = text, at = os.time(), reactions = {} } });
	end;

	local function poll(full)

		local since = (not full and lastAt > 0) and ("?since=" .. math.max(lastAt - 1, 0)) or "";
		local data = call("GET", "/chat" .. since);

		if data and type(data.messages) == "table" then absorb(data.messages, since == "") end;
	end;

	local function span(seconds)
		seconds = tonumber(seconds) or 0;
		if seconds >= 86400 * 2 then return math.floor(seconds / 86400) .. "d" end;
		if seconds >= 3600 then return math.floor(seconds / 3600) .. "h" end;
		return math.max(math.ceil(seconds / 60), 1) .. "m";
	end;

	local function deliver(message)
		task.spawn(function()
			local data, _, problem = call("POST", "/chat", {
				userId = me, name = LocalPlayer.DisplayName, place = placeName, body = message.body,
				replyTo = message.replyTo, key = adminKey, hw = hardware,
				placeId = tostring(game.PlaceId), gameId = tostring(game.GameId), jobId = game.JobId,
			});

			if byId[message.id] ~= message then return end;

			if data and type(data.message) == "table" then
				local real = data.message;
				real.userId, real.name, real.place = tostring(real.userId), tostring(real.name), tostring(real.place or "");
				real.reactions = real.reactions or {};
				settle(message, real);
				if (tonumber(real.at) or 0) > lastAt then lastAt = tonumber(real.at) end;
				sortOrder();
				relayout();
			elseif type(problem) == "table" and problem.code == "muted" then

				for index, known in ipairs(order) do
					if known == message then table.remove(order, index); break end;
				end;
				drop(message);
				relayout();
				note(problem.message == "perm" and "You are muted" or ("You are muted for " .. span(problem.message)));
			else
				message.pending, message.failed = false, true;
				relayout();
			end;
		end);
	end;

	local DURATIONS = { "30m", "1h", "1d", "1y", "perm" };
	local COMMANDS = {
		{ name = "mute", usage = "/mute player time", hint = "30m 1h 1d 1y perm", more = true },
		{ name = "unmute", usage = "/unmute player", hint = "lift a mute", more = true },
		{ name = "join", usage = "/join player", hint = "go to their server", more = true },
		{ name = "clear", usage = "/clear", hint = "wipe the chat for everyone" },
	};

	local function duration(text)
		text = string.lower(text or "");
		if text == "perm" then return nil, true end;

		local count, unit = text:match("^(%d+)([mhdwy])$");
		local per = { m = 60, h = 3600, d = 86400, w = 604800, y = 31536000 };

		if count and per[unit] and tonumber(count) > 0 then return tonumber(count) * per[unit], true end;

		return nil, false;
	end;

	local function handle(name)
		return (tostring(name):gsub("%s", "_"));
	end;

	local function people()
		local out, seen = {}, { [me] = true };

		for index = #order, 1, -1 do
			local message = order[index];
			if not message.system and not seen[message.userId] then
				seen[message.userId] = true;
				out[#out + 1] = { userId = message.userId, name = message.name, place = message.place };
			end;
		end;

		for _, player in ipairs(Players:GetPlayers()) do
			local id = tostring(player.UserId);
			if not seen[id] then
				seen[id] = true;
				out[#out + 1] = { userId = id, name = player.DisplayName, place = placeName };
			end;
		end;

		return out;
	end;

	local function person(text)
		text = string.lower(tostring(text or "")):gsub("^@", "");
		for _, entry in ipairs(people()) do
			if string.lower(handle(entry.name)) == text or entry.userId == text then return entry end;
		end;
		return nil;
	end;

	local function adminCall(body, done)
		body.key = adminKey;
		task.spawn(function()
			local data = call("POST", "/chat/admin", body);
			done(data ~= nil and data.done ~= false, data);
		end);
	end;

	local online, onlineAt, onlineBusy = {}, -1e9, false;
	local refreshSuggest;

	local function fetchOnline()
		if onlineBusy or os.clock() - onlineAt < 5 then return end;
		onlineBusy = true;

		adminCall({ action = "online" }, function(ok, data)
			onlineBusy, onlineAt = false, os.clock();
			online = {};

			for _, entry in ipairs((ok and type(data) == "table" and type(data.users) == "table") and data.users or {}) do
				if type(entry) == "table" and tostring(entry.userId) ~= me then
					online[#online + 1] = {
						userId = tostring(entry.userId), name = tostring(entry.name or "player"), place = tostring(entry.place or ""),
						placeId = tostring(entry.placeId or ""), jobId = tostring(entry.jobId or ""), gameId = tostring(entry.gameId or ""),
					};
				end;
			end;

			if refreshSuggest and field.Text:lower():sub(1, 5) == "/join" then refreshSuggest() end;
		end);
	end;

	local function onlinePerson(text)
		text = string.lower(tostring(text or "")):gsub("^@", "");
		for _, entry in ipairs(online) do
			if string.lower(handle(entry.name)) == text or entry.userId == text then return entry end;
		end;
		return nil;
	end;

	local function offerLink(data, why)
		local link = origin .. "/join?p=" .. tostring(data.placeId) .. "&j=" .. HttpService:UrlEncode(tostring(data.jobId));
		local copied = type(setclipboard) == "function" and pcall(setclipboard, link);
		note(why .. (copied and " - link copied, open it in a browser" or (": " .. link)));
	end;

	local function joinServer(who, data)
		if data.jobId == game.JobId then note(who.name .. " is in this server"); return end;

		if data.gameId ~= "" and data.gameId ~= tostring(game.GameId) then
			offerLink(data, who.name .. " is in another game");
			return;
		end;

		note("Joining " .. who.name .. (data.place ~= "" and (" in " .. data.place) or ""));

		local TeleportService = game:GetService("TeleportService");
		local failed;
		failed = TeleportService.TeleportInitFailed:Connect(function(player, result)
			if player ~= LocalPlayer then return end;
			failed:Disconnect();
			offerLink(data, "Teleport failed (" .. tostring(result and result.Name or "?") .. ")");
		end);
		task.delay(20, function() if failed.Connected then failed:Disconnect() end end);

		local fine = pcall(function()
			TeleportService:TeleportToPlaceInstance(tonumber(data.placeId), data.jobId, LocalPlayer);
		end);

		if not fine then
			if failed.Connected then failed:Disconnect() end;
			offerLink(data, "Teleport failed");
		end;
	end;

	local function runCommand(text)
		local words = {};
		for word in text:gmatch("%S+") do words[#words + 1] = word end;

		local command = string.lower((words[1] or ""):sub(2));

		if command == "clear" then
			adminCall({ action = "clear" }, function(ok)
				if not ok then note("Could not clear the chat"); return end;
				for index = #order, 1, -1 do
					if not order[index].system then drop(order[index]); table.remove(order, index) end;
				end;
				relayout();
				note("Chat cleared");
			end);
		elseif command == "mute" then
			local who = person(words[2]);
			if not who then note("Who? /mute player time"); return end;

			local seconds, fine = duration(words[3]);
			if not fine then note("Time is 30m, 1h, 1d, 1y or perm"); return end;

			adminCall({ action = "mute", userId = who.userId, seconds = seconds }, function(ok)
				note(ok and ("Muted " .. who.name .. (seconds and (" for " .. words[3]) or " for good")) or "Mute failed");
			end);
		elseif command == "unmute" then
			local who = person(words[2]);
			if not who then note("Who? /unmute player"); return end;

			adminCall({ action = "unmute", userId = who.userId }, function(ok)
				note(ok and (who.name .. " can talk again") or (who.name .. " was not muted"));
			end);
		elseif command == "join" then
			local who = onlinePerson(words[2]);
			if who then joinServer(who, who); return end;

			local known = person(words[2]);
			if not known then note("Who? /join player (online only)"); return end;

			adminCall({ action = "locate", userId = known.userId }, function(ok, data)
				if not (ok and type(data) == "table" and data.jobId and (tonumber(data.age) or 1e9) < 120) then
					note(known.name .. " is not online");
					return;
				end;

				joinServer(known, {
					placeId = tostring(data.placeId), jobId = tostring(data.jobId),
					gameId = tostring(data.gameId or ""), place = tostring(data.place or ""),
				});
			end);
		else
			note("No such command");
		end;
	end;

	local picks, pick = {}, 1;

	local function applyPick(option)
		if not option then return end;
		field.Text = option.fill;
		task.defer(function()
			field.CursorPosition = #field.Text + 1;
			focus();
		end);
	end;

	local function paintSuggest()
		for _, child in ipairs(suggest:GetChildren()) do
			if child:IsA("GuiObject") then child:Destroy() end;
		end;

		suggest.Visible = #picks > 0;

		for index, option in ipairs(picks) do
			local lit = index == pick;
			local item = make("TextButton", {
				Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = th.line, BackgroundTransparency = lit and 0.55 or 1,
				AutoButtonColor = false, Text = "", LayoutOrder = index, ZIndex = 36,
			}, suggest);
			make("UICorner", { CornerRadius = UDim.new(0, 6) }, item);

			local x = 8;
			if option.userId then
				local face = make("ImageLabel", {
					AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(18, 18),
					BackgroundColor3 = th.panel, BorderSizePixel = 0, ZIndex = 37,
					Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48"):format(tonumber(option.userId) or 1),
				}, item);
				make("UICorner", { CornerRadius = UDim.new(1, 0) }, face);
				x = 30;
			end;

			make("TextLabel", {
				Position = UDim2.fromOffset(x, 0), Size = UDim2.new(0.55, -x, 1, 0), BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold, Text = option.label, TextColor3 = th.text, TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 37,
			}, item);
			make("TextLabel", {
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0.45, -8, 1, 0),
				BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = option.hint or "", TextColor3 = th.dim,
				TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 37,
			}, item);

			item.MouseButton1Click:Connect(function() applyPick(option) end);
		end;
	end;

	function refreshSuggest()
		table.clear(picks);
		pick = 1;

		local text = field.Text;

		if ADMIN and text:sub(1, 1) == "/" then
			local words = {};
			for word in text:gmatch("%S+") do words[#words + 1] = word end;

			local trailing = text:sub(-1) == " ";
			local at = #words + (trailing and 1 or 0);
			local current = trailing and "" or string.lower(words[#words] or "");
			local command = string.lower((words[1] or "/"):sub(2));

			if at <= 1 then
				for _, entry in ipairs(COMMANDS) do
					if entry.name:sub(1, #command) == command then
						picks[#picks + 1] = { label = entry.usage, hint = entry.hint, fill = "/" .. entry.name .. (entry.more and " " or "") };
					end;
				end;
			elseif command == "join" and at == 2 then

				fetchOnline();
				local typed = current:gsub("^@", "");
				for _, entry in ipairs(online) do
					if typed == "" or string.lower(handle(entry.name)):find(typed, 1, true) then
						picks[#picks + 1] = {
							label = entry.name, hint = entry.place, userId = entry.userId,
							fill = "/join " .. handle(entry.name),
						};
					end;
					if #picks >= 6 then break end;
				end;
				if #picks == 0 then
					picks[1] = { label = onlineBusy and "Looking..." or "Nobody online", hint = "", fill = "/join " };
				end;
			elseif (command == "mute" or command == "unmute") and at == 2 then
				local typed = current:gsub("^@", "");
				for _, entry in ipairs(people()) do
					if typed == "" or string.lower(handle(entry.name)):find(typed, 1, true) then
						picks[#picks + 1] = {
							label = entry.name, hint = entry.place, userId = entry.userId,
							fill = "/" .. command .. " " .. handle(entry.name) .. (command == "mute" and " " or ""),
						};
					end;
					if #picks >= 6 then break end;
				end;
			elseif command == "mute" and at == 3 then
				for _, span in ipairs(DURATIONS) do
					if span:sub(1, #current) == current then
						picks[#picks + 1] = { label = span, hint = span == "perm" and "for good" or "", fill = "/mute " .. words[2] .. " " .. span };
					end;
				end;
			end;
		end;

		paintSuggest();
	end;

	local sent = 0;

	local function submit()
		local text = field.Text:gsub("^%s+", ""):gsub("%s+$", "");
		if text == "" then return end;

		field.Text = "";

		if text:sub(1, 1) == "/" then
			if ADMIN then runCommand(text) else note("Commands are for the owner") end;
			return;
		end;

		sent += 1;

		local message = {
			id = "local:" .. sent, userId = me, name = LocalPlayer.DisplayName, place = placeName, body = text,
			replyTo = replying and replying.id or nil, at = os.time(), reactions = {}, pending = true,
			role = ADMIN and "admin" or nil,
		};

		setReply(nil);

		atBottom, unread = true, 0;
		absorb({ message });
		paintJump();
		deliver(message);
	end;

	NeverLose:AddSignal(field:GetPropertyChangedSignal("Text"):Connect(function()
		local text = field.Text;

		if text:find("\t", 1, true) then
			field.Text = text:gsub("\t", "");
			if picks[pick] then applyPick(picks[pick]) end;
			return;
		end;

		local length = utf8.len(text);

		if length and length > LIMIT then
			field.Text = text:sub(1, utf8.offset(text, LIMIT + 1) - 1);
			return;
		end;

		paintSend();
		refreshSuggest();
	end));
	NeverLose:AddSignal(field:GetPropertyChangedSignal("TextBounds"):Connect(layoutComposer));
	NeverLose:AddSignal(field.Focused:Connect(function() barEdge.Transparency = 0.25 end));

	local function closeMenu()
		if not menu.Visible then return end;
		menu.Visible, shade.Visible = false, false;
		menuTarget = nil;
		task.defer(focus);
	end;

	function openMenu(row, message)
		if message.system then return end;

		if message.failed then

			message.failed, message.pending = false, true;
			relayout();
			deliver(message);
			return;
		end;

		if message.pending then return end;

		menuTarget = message;
		copyItem.Visible = type(setclipboard) == "function";
		deleteItem.Visible = ADMIN;

		local bubble = row.bubble;
		local width = 196;
		local height = 40 + 28 * ((copyItem.Visible and 1 or 0) + (deleteItem.Visible and 1 or 0) + 1);
		local left = bubble.AbsolutePosition.X - root.AbsolutePosition.X + (row.mine and bubble.AbsoluteSize.X - width or 0);
		local top = bubble.AbsolutePosition.Y - root.AbsolutePosition.Y + bubble.AbsoluteSize.Y + 4;
		local room = root.AbsoluteSize.Y - bar.AbsoluteSize.Y - 8;

		if top + height > room then top = bubble.AbsolutePosition.Y - root.AbsolutePosition.Y - height - 4 end;

		menu.Position = UDim2.fromOffset(
			math.clamp(left, 4, math.max(root.AbsoluteSize.X - width - 4, 4)),
			math.clamp(top, 4, math.max(room - height, 4))
		);

		shade.Visible, menu.Visible = true, true;
		appear(menu);
	end;

	NeverLose:AddSignal(shade.MouseButton1Click:Connect(closeMenu));
	NeverLose:AddSignal(shade.MouseButton2Click:Connect(closeMenu));

	for _, entry in ipairs(emojiButtons) do
		NeverLose:AddSignal(entry.button.MouseButton1Click:Connect(function()
			local target = menuTarget;
			closeMenu();
			if target then react(target, entry.emoji) end;
		end));
	end;

	NeverLose:AddSignal(replyItem.MouseButton1Click:Connect(function()
		local target = menuTarget;
		closeMenu();
		if target then setReply(target) end;
		task.defer(focus);
	end));

	NeverLose:AddSignal(copyItem.MouseButton1Click:Connect(function()
		local target = menuTarget;
		closeMenu();
		if target and type(setclipboard) == "function" then
			pcall(setclipboard, target.body);
			note("Copied");
		end;
	end));

	NeverLose:AddSignal(deleteItem.MouseButton1Click:Connect(function()
		local target = menuTarget;
		closeMenu();
		if not (target and ADMIN) then return end;

		adminCall({ action = "delete", messageId = target.id }, function(ok)
			if not ok then note("Could not delete that"); return end;
			for index, known in ipairs(order) do
				if known == target then table.remove(order, index); break end;
			end;
			drop(target);
			relayout();
		end);
	end));

	NeverLose:AddSignal(send.MouseButton1Click:Connect(function() submit(); task.defer(focus) end));

	NeverLose:AddSignal(field.FocusLost:Connect(function(enter, input)
		barEdge.Transparency = 0.55;

		if enter then submit() end;

		if input and input.KeyCode == Enum.KeyCode.Escape then parked = true; return end;

		task.delay(enter and 0.03 or 0.08, function()
			if __ALIVE() and not parked and UserInputService:GetFocusedTextBox() == nil then focus() end;
		end);
	end));

	NeverLose:AddSignal(root.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then parked = false end;
	end));

	NeverLose:AddSignal(UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end;

		if input.KeyCode == Enum.KeyCode.Escape and menu.Visible then closeMenu(); return end;

		if not field:IsFocused() then return end;

		if #picks > 0 then
			if input.KeyCode == Enum.KeyCode.Down then pick = pick % #picks + 1; paintSuggest(); return end;
			if input.KeyCode == Enum.KeyCode.Up then pick = (pick - 2) % #picks + 1; paintSuggest(); return end;
			if input.KeyCode == Enum.KeyCode.Tab then applyPick(picks[pick]); return end;
		end;

		local ok, bind = pcall(function()
			local value = Window.Keybind;
			return typeof(value) == "EnumItem" and value or Enum.KeyCode[tostring(value)];
		end);

		if ok and bind and input.KeyCode == bind and UserInputService:GetStringForKeyCode(bind) == "" then
			parked = true;
			field:ReleaseFocus();
			Window:ToggleInterface();
		end;
	end));

	NeverLose:AddSignal(list:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		for _, row in pairs(rows) do
			if row.bodyCap then
				row.bodyCap.MaxSize = Vector2.new(bodyWidth(row.mine), math.huge);
				row.headCap.MaxSize = Vector2.new(bodyWidth(row.mine) - 50, math.huge);
			end;
		end;

		fitCanvas();
		if atBottom then list.CanvasPosition = Vector2.new(0, range()) end;
	end));

	task.spawn(function()
		while __ALIVE() do
			local now = active();

			if now and not wasActive then
				parked = false;
				tabUnread = 0;
				paintBadge();

				task.defer(function()
					task.wait();
					fitCanvas();
					toBottom();
					focus();
				end);
			elseif wasActive and not now then
				closeMenu();
				if field:IsFocused() then parked = true; field:ReleaseFocus() end;
			end;

			wasActive = now;
			task.wait(0.12);
		end;
	end);

	task.spawn(function()
		task.wait(1.5);
		pcall(poll, true);

		local rounds = 0;

		while __ALIVE() do
			task.wait(active() and 1.5 or 8);
			rounds += 1;

			if __ALIVE() then pcall(poll, rounds % 4 == 0) end;
		end;
	end);

	layoutComposer();
	paintSend();

	onUnload("social chat", function()
		pcall(function() root:Destroy() end);
		pcall(function() tabBadge:Destroy() end);
	end);
end;
