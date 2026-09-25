--!nonstrict
--[[
	animations.lua — extracted feature module (require id "modules.animations").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("animations") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("animations", function()
			return require("modules.animations")({ ESP = ESP, LocalPlayer = LocalPlayer, MiscGroup = MiscGroup, NeverLose = NeverLose, Notification = Notification, Remote = Remote, RunService = RunService, Sections = Sections, USER_DATA = USER_DATA, Window = Window, onUnload = onUnload, userFile = userFile, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local LocalPlayer = ctx.LocalPlayer;
	local MiscGroup = ctx.MiscGroup;
	local NeverLose = ctx.NeverLose;
	local Notification = ctx.Notification;
	local Remote = ctx.Remote;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local USER_DATA = ctx.USER_DATA;
	local Window = ctx.Window;
	local onUnload = ctx.onUnload;
	local userFile = ctx.userFile;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("animations") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local A = { EmoteLoop = false, EmoteSpeed = 100, Alive = true, _request = 0, PackName = "Default" };
	onUnload("animations", function()
		if A.Destroy then A.Destroy() else A.Alive = false; A._request += 1 end;
	end);

	local function prettyName(value)
		local text = tostring(value or ""):gsub("[_]+", " ");

		text = text:gsub("%s+", " "):match("^%s*(.-)%s*$") or "";

		if text == "" or text:match("^%[%d+%]$") then return "Untitled" end;

		text = text:gsub("(%a[%w']*)", function(word)
			if word:match("^%l") and not word:match("%u") then
				return word:sub(1, 1):upper() .. word:sub(2);
			end;

			return word;
		end);

		return text;
	end

		local origAnims = {}

		local function toAid(v)
			local t = tostring(v or ""):match("^%s*(.-)%s*$")
			local d = t:match("(%d+)")
			if not d or tonumber(d) == 0 then return nil end
			return "rbxassetid://" .. d
		end

		local function kickReload(hum, animate)

			pcall(function()
				local animator = hum:FindFirstChildOfClass("Animator");
				for _, track in ipairs(animator and animator:GetPlayingAnimationTracks() or hum:GetPlayingAnimationTracks()) do
					if track.Priority.Value <= Enum.AnimationPriority.Movement.Value then track:Stop(0.12) end;
				end;
				if not animate.Disabled then animate.Disabled = true; animate.Disabled = false end;
			end);
		end;

		local function restoreAnims()
			local changed = false;
			for animation, id in pairs(origAnims) do
				if animation.Parent and animation.AnimationId ~= id then
					local ok = pcall(function()
						local parent = animation.Parent;
						animation.AnimationId = id;
						animation.Parent = nil;
						animation.Parent = parent;
					end);
					if ok then changed = true end;
				end;
			end;
			origAnims = {};
			return changed;
		end;

		local CAT_URLS = {
			"https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/AnimationSniper.json",
			"https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/AnimationSniperoffsale.json",
		}
		local PACK_CACHE = Remote.file("animpacks.json")

		local packByName = {}
		local mapCache   = {}

		A.PackCatalog   = {}
		A.PackSearch    = ""
		A.PackPage      = 1
		A.PacksPerPage  = 24
		A.PackFiltered  = {}

		local function resolveMappings(data)
			local key = tostring(data.id)
			if mapCache[key] then return mapCache[key] end
			local bundled = data.bundledItems
			if type(bundled) ~= "table" then return nil end
			local mappings = {}
			local deadline = os.clock() + 30;
			for _, ids in pairs(bundled) do
				if type(ids) == "table" then
					for _, assetId in pairs(ids) do
						if not A.Alive or not Remote.current() or os.clock() >= deadline then return nil end;
						local ok, objs = Remote.objects(function() return game:GetObjects("rbxassetid://" .. tostring(assetId)) end);
						if ok and objs then
							local function scan(parent, path)
								for _, child in ipairs(parent:GetChildren()) do
									if child:IsA("Animation") then
										local parts = (path .. "." .. child.Name):split(".")
										mappings[#mappings + 1] = {
											category = parts[#parts - 1],
											name = parts[#parts],
											id = child.AnimationId,
										}
									elseif #child:GetChildren() > 0 then
										scan(child, path .. "." .. child.Name)
									end
								end
							end
							for _, o in ipairs(objs) do
								scan(o, o.Name)
								pcall(function() o:Destroy() end)
							end
						end
					end
				end
			end
			mapCache[key] = next(mappings) and mappings or nil
			return mappings
		end

		local function applyCategory(animate, folderName, mappings)
			local items, changed = {}, 0
			for _, m in ipairs(mappings) do
				if m.category and m.category:lower() == folderName then
					items[m.name:lower()] = m.id
				end
			end
			if not next(items) then return 0 end
			local folder = animate:FindFirstChild(folderName)
			if not folder then return 0 end
			local _, first = next(items)
			for _, a in ipairs(folder:GetChildren()) do
				if a:IsA("Animation") then
					local id = items[a.Name:lower()] or first
					if id then
						if origAnims[a] == nil then origAnims[a] = a.AnimationId end
						changed = changed + 1
						a.AnimationId = id
						local p = a.Parent
						a.Parent = nil
						a.Parent = p
					end
				end
			end
			return changed;
		end

		A.ApplyPack = function(packName)
			if not A.Alive then return false end;
			A.ResetEmote();
			local token = A._request;
			local name = packName or A.PackName or "Default";
			local character = LocalPlayer.Character;
			A.PackName = "Default";
			A.PendingPack = name ~= "Default" and name or nil;
			if A.OnStateChange then A.OnStateChange() end;
			if name == "Default" then
				local changed = restoreAnims();
				A.LastError = nil;
				local c = LocalPlayer.Character;
				local hum = c and c:FindFirstChildOfClass("Humanoid");
				local animate = c and c:FindFirstChild("Animate");
				if changed and hum and animate then kickReload(hum, animate) end;
				return true;
			end;
			local data = packByName[name];
			if not data then A.PendingPack = nil; if A.OnStateChange then A.OnStateChange() end; return false end;
			task.spawn(function()
				local ok, mappings = pcall(resolveMappings, data);
				if not A.Alive or token ~= A._request or LocalPlayer.Character ~= character then return end;
				local c = LocalPlayer.Character;
				local hum = c and c:FindFirstChildOfClass("Humanoid");
				local animate = c and c:FindFirstChild("Animate");
				A.PendingPack = nil;
				if not (ok and mappings and #mappings > 0 and hum and animate) then
					local restored = restoreAnims();
					if restored and hum and animate then kickReload(hum, animate) end;
					A.LastError = "Animation pack could not load on this character";
					if A.OnStateChange then A.OnStateChange() end;
					return;
				end;
				local restored = restoreAnims();
				local changed = 0;
				for _, folderName in ipairs({ "idle", "walk", "run", "jump", "fall", "climb", "swim", "swimidle" }) do
					changed = changed + applyCategory(animate, folderName, mappings);
				end;
				if changed > 0 then
					A.PackName = name;
					A.LastError = nil;
					kickReload(hum, animate);
				else
					if restored then kickReload(hum, animate) end;
					A.LastError = "This pack has no matching animation slots";
				end;
				if A.OnStateChange then A.OnStateChange() end;
			end);
			return true;
		end;

		A._RefreshPackList = function()
			A.PackFavs = A.PackFavs or {}
			local q = tostring(A.PackSearch or ""):lower()
			local list = A.PackCatalog
			if q ~= "" then
				local filtered = {}
				for _, e in ipairs(list) do
					if e.name:lower():find(q, 1, true) then filtered[#filtered + 1] = e end
				end
				A.PackFiltered = filtered
			else
				A.PackFiltered = list
			end

			if next(A.PackFavs) ~= nil then
				local fav, rest = {}, {}
				for _, e in ipairs(A.PackFiltered) do
					if A.PackFavs[e.name] then fav[#fav+1] = e else rest[#rest+1] = e end
				end
				for _, e in ipairs(rest) do fav[#fav+1] = e end
				A.PackFiltered = fav
			end
			local total = #A.PackFiltered
			A.PackTotalPages = math.max(1, math.ceil(total / A.PacksPerPage))
			if A.PackPage > A.PackTotalPages then A.PackPage = A.PackTotalPages end
			if A.PackPage < 1 then A.PackPage = 1 end
		end

		local function ingest(list)
			local seen = {}
			for _, e in ipairs(A.PackCatalog) do seen[e.id] = true end
			for _, item in pairs(list) do
				local id = type(item) == "table" and tonumber(item.id)
				if id and id > 0 and id < 2 ^ 53 and id % 1 == 0 and type(item.bundledItems) == "table" and not seen[id] then
					seen[id] = true
					local nm = prettyName(item.name or ("Animation " .. id))
					if packByName[nm] then nm = nm .. " [" .. id .. "]" end
					packByName[nm] = { id = id, bundledItems = item.bundledItems }
					A.PackCatalog[#A.PackCatalog + 1] = { id = id, name = nm }
				end
			end
		end

		task.spawn(function()
			local cached
			pcall(function()
				if isfile and isfile(PACK_CACHE) then
					local d = game:GetService("HttpService"):JSONDecode(readfile(PACK_CACHE))
					if type(d) == "table" and #d > 0 then cached = d end
				end
			end)
			if cached then
				ingest(cached)
				table.sort(A.PackCatalog, function(a, b) return a.name < b.name end)
			end

			local fresh = {}
			for _, url in ipairs(CAT_URLS) do
				local ok, res = pcall(function()
					local body = Remote.download(url)
					return body ~= "" and game:GetService("HttpService"):JSONDecode(body) or nil
				end)
				if ok and type(res) == "table" then
					local list = type(res.data) == "table" and res.data or res
					for _, item in pairs(list) do
						if type(item) == "table" and item.id and type(item.bundledItems) == "table" then fresh[#fresh + 1] = item end
					end
				end
			end
			if not A.Alive or #fresh == 0 then return end

			A.PackCatalog = {}
			packByName = {}
			ingest(fresh)
			table.sort(A.PackCatalog, function(a, b) return a.name < b.name end)
			pcall(function()
								writefile(PACK_CACHE, game:GetService("HttpService"):JSONEncode(fresh))
			end)
		end)

		A.ResetEmote = function()
			A._request = A._request + 1;
			A.PendingEmoteId, A.PendingPack, A.SelectedEmoteId = nil, nil, nil;
			if A._emoteStopped then A._emoteStopped:Disconnect(); A._emoteStopped = nil end;
			if A._emoteMonitor then A._emoteMonitor:Disconnect(); A._emoteMonitor = nil end;
			local track = A._currentEmoteTrack;
			A._currentEmoteTrack = nil;
			if track then pcall(function() track:Stop(0.12); track:Destroy() end) end;
			if A._currentEmoteAnim then A._currentEmoteAnim:Destroy(); A._currentEmoteAnim = nil end;
			if A.OnStateChange then A.OnStateChange() end;
		end;

		local animIdCache = {};

		local function resolveAnimId(id)
			local key = tostring(id);
			if animIdCache[key] then return animIdCache[key] end;
			local direct = toAid(id);
			if not direct then return nil end;
			local found;
			local ok, objects = Remote.objects(function() return game:GetObjects(direct) end);
			if ok and type(objects) == "table" then
				for _, object in ipairs(objects) do
					if object:IsA("Animation") then found = toAid(object.AnimationId) end;
					if not found then
						for _, descendant in ipairs(object:GetDescendants()) do
							if descendant:IsA("Animation") then found = toAid(descendant.AnimationId); if found then break end end;
						end;
					end;
					object:Destroy();
				end;
			end;
			animIdCache[key] = found or direct;
			return animIdCache[key];
		end;

		A.PlayEmote = function(id)
			if not A.Alive then return false end;
			A.ResetEmote();
			restoreAnims();
			A.PackName = "Default";
			local token = A._request;
			local character = LocalPlayer.Character;
			local hum = character and character:FindFirstChildOfClass("Humanoid");
			local raw = toAid(id);
			if not (hum and raw) then return false end;
			A.PendingEmoteId = tostring(id);
			A.LastError = nil;
			if A.OnStateChange then A.OnStateChange() end;
			task.spawn(function()
				local ok, aid = pcall(resolveAnimId, id);
				if not A.Alive or token ~= A._request or LocalPlayer.Character ~= character then return end;
				local animation = Instance.new("Animation");
				animation.AnimationId = ok and aid or raw;
				local animator = hum:FindFirstChildOfClass("Animator");
				local loaded, track = pcall(function()
					return animator and animator:LoadAnimation(animation) or hum:LoadAnimation(animation);
				end);
				if loaded and track then
					local deadline = os.clock() + 5;
					while A.Alive and token == A._request and track.Length <= 0 and os.clock() < deadline do task.wait(0.05) end;
				end;
				if not A.Alive or token ~= A._request or LocalPlayer.Character ~= character then
					if loaded and track then pcall(function() track:Stop(0); track:Destroy() end) end;
					animation:Destroy();
					return;
				end;
				A.PendingEmoteId = nil;
				if not loaded or not track or track.Length <= 0 then
					if loaded and track then track:Destroy() end;
					animation:Destroy();
					A.LastError = "Emote unavailable for this character or experience";
					if A.OnStateChange then A.OnStateChange() end;
					return;
				end;

				track.Priority = Enum.AnimationPriority.Action4;
				track.Looped = A.EmoteLoop == true;
				A._currentEmoteTrack, A._currentEmoteAnim = track, animation;
				A.SelectedEmoteId = id;
				local lastPosition = 0;
				A._emoteMonitor = RunService.Heartbeat:Connect(function()
					if A._currentEmoteTrack ~= track then return end;
					if track.IsPlaying then lastPosition = track.TimePosition end;
				end);
				A._emoteStopped = track.Stopped:Connect(function()
					if A._currentEmoteTrack ~= track then return end;
					task.defer(function()
						if A._currentEmoteTrack ~= track or track.IsPlaying then return end;
						if A.EmoteLoop then
							pcall(function() track:Play(0.05, 1, A.EmoteSpeed / 100) end);
						elseif lastPosition > 0.05 and lastPosition < track.Length - 0.08 then
							pcall(function()
								track:Play(0.05, 1, A.EmoteSpeed / 100);
								track.TimePosition = math.min(lastPosition, math.max(track.Length - 0.05, 0));
							end);
						else
							A.ResetEmote();
						end;
					end);
				end);
				local played = pcall(function() track:Play(0.12, 1, A.EmoteSpeed / 100) end);
				if not played then A.ResetEmote(); A.LastError = "Unable to play this emote" end;
				if A.OnStateChange then A.OnStateChange() end;
			end);
			return true;
		end;

		A._SetEmoteLoop = function(value)
			A.EmoteLoop = value == true;
			local track = A._currentEmoteTrack;
			if track then track.Looped = A.EmoteLoop end;
		end;

		NeverLose:AddSignal(LocalPlayer.CharacterAdded:Connect(function(character)
			local emote = A.SelectedEmoteId or A.PendingEmoteId;
			local pack = A.PendingPack or A.PackName;
			A.ResetEmote();
			origAnims = {};
			local token = A._request;
			task.spawn(function()
				local human = character:WaitForChild("Humanoid", 10);
				local animate = character:WaitForChild("Animate", 10);
				if animate then animate:WaitForChild("idle", 5) end;
				if not A.Alive or token ~= A._request or LocalPlayer.Character ~= character or not human then return end;
				if emote then A.PlayEmote(emote) elseif pack and pack ~= "Default" then A.ApplyPack(pack) end;
			end);
		end));

		A.Destroy = function()
			if not A.Alive then return end;
			A.Alive = false;
			A.OnStateChange = nil;
			A.ResetEmote();
			local changed = restoreAnims();
			local character = LocalPlayer.Character;
			local hum = character and character:FindFirstChildOfClass("Humanoid");
			local animate = character and character:FindFirstChild("Animate");
			if changed and hum and animate then kickReload(hum, animate) end;
			A.PackName = "Default";
		end;
		NeverLose:AddSignal(NeverLose.ScreenGui.Destroying:Connect(A.Destroy));

		A.EmoteCatalog = {}
		A.EmoteSearch = ""
		A.EmoteFavorites = {}
		A.EmoteSpeed   = 100
		A.EmoteLoop    = false
		A.SelectedEmoteId = nil
		A._emotePage = 1
		A._emotesPerPage = 24
		A._emoteFilteredList = {}

		do
			A.EmoteCatalog = { { id = 129149402922241, name = "Griddy" } };
			local seeded = { [129149402922241] = true };

			pcall(function()
				if isfile and isfile("emotes.json") then
					local d = game:GetService("HttpService"):JSONDecode(readfile("emotes.json"));

					if type(d) == "table" then
						for k, v in pairs(d) do
							local name, id;

							if type(v) == "table" then
								name, id = tostring(v.name or v[1] or k), v.id or v[2]
							else
								name, id = tostring(k), v
							end;

							local raw = tonumber(tostring(id or ""):gsub("%D", "")) or 0;

							if name ~= "" and raw > 0 and not seeded[raw] then
								seeded[raw] = true;
								A.EmoteCatalog[#A.EmoteCatalog + 1] = { id = raw, name = prettyName(name) };
							end;
						end;
					end;
				end;
			end);
		end

		local function fetchEmotes()
			local ok, result = pcall(function()
				local json = Remote.download("https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/EmoteSniper.json")
				if json and json ~= "" then
					return game:GetService("HttpService"):JSONDecode(json).data or {}
				end
			end)
			if ok and type(result) == "table" then
				local list = {}
				for _, item in pairs(result) do
					local id = type(item) == "table" and tonumber(item.id)
					if id and id > 0 and id < 2 ^ 53 and id % 1 == 0 then
						list[#list+1] = { id = id, name = prettyName(item.name or ("Emote_"..id)) }
					end
				end
				return list
			end
			return {}
		end

		local function filterEmotes(search)
			search = search:lower()
			local list = A.EmoteCatalog
			if search ~= "" then
				local isId = search:match("^%d+$")
				local filtered = {}
				for _, e in ipairs(list) do
					if isId then
						if tostring(e.id) == search then filtered[#filtered+1] = e end
					else
						local name = prettyName(e.name):lower()
						local match = true
						for word in search:gmatch("%S+") do
							if not name:find(word, 1, true) then match = false; break end
						end
						if match then filtered[#filtered+1] = e end
					end
				end
				A._emoteFilteredList = filtered
			else
				A._emoteFilteredList = list
			end
		end

		A._refreshEmoteList = function()
			filterEmotes(A.EmoteSearch)
			if next(A.EmoteFavorites) ~= nil then
				local fav, rest = {}, {}
				for _, e in ipairs(A._emoteFilteredList) do
					if A.EmoteFavorites[e.id] then fav[#fav+1] = e else rest[#rest+1] = e end
				end
				for _, e in ipairs(rest) do fav[#fav+1] = e end
				A._emoteFilteredList = fav
			end
			local total = #A._emoteFilteredList
			local pp = A._emotesPerPage
			A._emoteTotalPages = math.max(1, math.ceil(total / pp))
			if A._emotePage > A._emoteTotalPages then A._emotePage = A._emoteTotalPages end
			if A._emotePage < 1 then A._emotePage = 1 end
		end

		local CACHE = Remote.file("emotes.json")

		local function loadCache()
			local ok, list = pcall(function()
				if not (isfile and isfile(CACHE)) then return nil end
				local d = game:GetService("HttpService"):JSONDecode(readfile(CACHE))
				return (type(d) == "table" and #d > 0) and d or nil
			end)
			return ok and list or nil
		end

		local function saveCache(list)
			pcall(function()
								writefile(CACHE, game:GetService("HttpService"):JSONEncode(list))
			end)
		end

		task.spawn(function()
			local cached = loadCache()
			if cached then
				local seen, merged = {}, {};
				for _, e in ipairs(A.EmoteCatalog) do
					if e and e.id and not seen[e.id] then
						e.name = prettyName(e.name or e.id)
						seen[e.id] = true;
						merged[#merged + 1] = e;
					end;
				end;
				for _, e in ipairs(cached) do
					if e and e.id and not seen[e.id] then
						e.name = prettyName(e.name or e.id)
						seen[e.id] = true;
						merged[#merged + 1] = e;
					end;
				end;
				A.EmoteCatalog = merged
				A._refreshEmoteList()
				if A._buildEmoteGrid then pcall(A._buildEmoteGrid) end
			end

			for attempt = 1, 5 do
				if not A.Alive then return end;
				local fresh = fetchEmotes()
				if not A.Alive then return end;
				if #fresh > 0 then

					local seen, merged = {}, {};

					for _, e in ipairs(A.EmoteCatalog) do
						if e and e.id and not seen[e.id] then
							e.name = prettyName(e.name or e.id)
							seen[e.id] = true;
							merged[#merged + 1] = e;
						end;
					end;

					for _, e in ipairs(fresh) do
						if e and e.id and not seen[e.id] then
							e.name = prettyName(e.name or e.id)
							seen[e.id] = true;
							merged[#merged + 1] = e;
						end;
					end;

					A.EmoteCatalog = merged
					saveCache(A.EmoteCatalog)
					A._refreshEmoteList()
					if A._buildEmoteGrid then pcall(A._buildEmoteGrid) end
					return
				end
				task.wait(3)
			end
		end)

	ESP.Anim = A;
	ESP.ClearAnimations = A.Destroy;

	local Accent = NeverLose.AccentColor;

	local function sectionHost(section)
		return section.Items or section.Root;
	end;

		local COLS, CELL_H, PAD = 2, 118, 8;
		local COL_IDLE = Color3.fromRGB(25, 27, 33);
		local COL_HOVER = Color3.fromRGB(35, 38, 48);
		local COL_ACTIVE = Color3.fromRGB(30, 34, 48);
		local COL_TEXT = Color3.fromRGB(236, 238, 244);
		local COL_EDGE = Color3.fromRGB(45, 48, 58);
		local grids = {};

		local function buildGrid(parent, height, order, cfg)
			local sf = Instance.new("ScrollingFrame");
			sf.Name = "AnimationCatalog";
			sf.Size = UDim2.new(1, -8, 0, height);
			sf.BackgroundColor3 = Color3.fromRGB(13, 14, 18);
			sf.ZIndex, sf.BorderSizePixel, sf.ScrollBarThickness = 20, 0, 4;
			sf.ScrollBarImageColor3 = Accent;
			sf.CanvasSize = UDim2.new();
			sf.ClipsDescendants = true;
			sf.Parent, sf.LayoutOrder = parent, order;
			Instance.new("UICorner", sf).CornerRadius = UDim.new(0, 6);
			local empty = Instance.new("TextLabel");
			empty.Name, empty.Text = "Empty", "No matching results";
			empty.Size, empty.Position = UDim2.new(1, -16, 0, 48), UDim2.fromOffset(8, 16);
			empty.BackgroundTransparency, empty.TextTransparency = 1, 0.35;
			empty.Font, empty.TextSize, empty.TextColor3 = Enum.Font.Gotham, 12, COL_TEXT;
			empty.ZIndex, empty.Parent = 21, sf;
			local pool, live, parked = {}, {}, {};
			local selectedKey, dirty, disposed = nil, true, false;
			local grid = { Frame = sf };

			local function restoreScroll()
				for ancestor, enabled in pairs(parked) do
					if ancestor.Parent then ancestor.ScrollingEnabled = enabled end;
					parked[ancestor] = nil;
				end;
			end;
			local function visible()
				if disposed or not A.Alive or not sf.Parent then return false end;
				local ancestor = sf;
				while ancestor do
					if ancestor:IsA("GuiObject") and not ancestor.Visible then return false end;
					if ancestor:IsA("ScreenGui") then return ancestor.Enabled end;
					ancestor = ancestor.Parent;
				end;
				return false;
			end;
			local function build()
				local card = Instance.new("TextButton");
				card.Name, card.ClipsDescendants = "CatalogCard", true;
				card.BackgroundColor3, card.BorderSizePixel, card.ZIndex = COL_IDLE, 0, 21;
				card.AutoButtonColor, card.Text = false, "";
				Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6);
				local stroke = Instance.new("UIStroke", card);
				stroke.Color, stroke.Thickness, stroke.Transparency = COL_EDGE, 1, 0.45;
				local scale = Instance.new("UIScale", card);
				local img = Instance.new("ImageLabel", card);
				img.Name, img.ZIndex, img.BackgroundTransparency = "Thumb", 22, 1;
				img.ScaleType = Enum.ScaleType.Fit;
				img.Size, img.Position = UDim2.new(1, -16, 0, CELL_H - 44), UDim2.fromOffset(8, 7);
				local label = Instance.new("TextLabel", card);
				label.Name, label.ZIndex, label.BackgroundTransparency = "Title", 23, 1;

				label.FontFace = NeverLose.BuiltInRegular;
				label.TextSize, label.TextColor3 = 12, COL_TEXT;
				label.TextWrapped, label.TextTruncate = false, Enum.TextTruncate.AtEnd;
				label.TextXAlignment = Enum.TextXAlignment.Center;
				label.Size, label.Position = UDim2.new(1, -10, 0, 16), UDim2.fromOffset(5, CELL_H - 26);
				local star = Instance.new("TextLabel", card);
				star.Name, star.Text, star.Font = "Favorite", "★", Enum.Font.GothamBold;
				star.ZIndex, star.TextSize, star.BackgroundTransparency = 24, 17, 1;
				star.TextColor3, star.TextTransparency = Color3.fromRGB(255, 211, 104), 1;
				star.Position, star.Size = UDim2.fromOffset(5, 3), UDim2.fromOffset(20, 20);
				local dot = Instance.new("Frame", card);
				dot.Name, dot.ZIndex, dot.BorderSizePixel = "ActiveDot", 24, 0;
				dot.AnchorPoint, dot.Position = Vector2.new(1, 0), UDim2.new(1, -7, 0, 8);
				dot.Size, dot.BackgroundColor3, dot.BackgroundTransparency = UDim2.fromOffset(7, 7), Accent, 1;
				Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0);
				local tile = { card = card, img = img, label = label, stroke = stroke, scale = scale, dot = dot, star = star, active = 0, hover = 0, favorite = 0, pulse = 0 };
				card.MouseEnter:Connect(function() tile.hovered = true end);
				card.MouseLeave:Connect(function() tile.hovered = false end);
				card.MouseButton1Click:Connect(function()
					if not tile.entry or not visible() then return end;
					local entry, key = tile.entry, tile.key;
					tile.pulse = 1;
					cfg.onClick(entry, key);
				end);
				card.MouseButton2Click:Connect(function()
					if tile.entry and visible() and cfg.onFav then cfg.onFav(tile.entry, tile.key) end;
				end);
				return tile;
			end;

			function grid.refresh()
				if disposed then return end;
				dirty = false;
				local list = cfg.getList() or {};
				local total, rowHeight = #list, CELL_H + PAD;
				local rows = math.ceil(total / COLS);
				local canvasHeight = math.max(0, rows * rowHeight + PAD);
				if sf.CanvasSize.Y.Offset ~= canvasHeight then sf.CanvasSize = UDim2.fromOffset(0, canvasHeight) end;
				empty.Visible = total == 0;
				local width = math.max(40, (sf.AbsoluteSize.X - sf.ScrollBarThickness - PAD * (COLS + 1)) / COLS);
				local first = math.max(0, math.floor((sf.CanvasPosition.Y - PAD) / rowHeight) - 1);
				local last = math.min(rows - 1, math.floor((sf.CanvasPosition.Y + math.max(sf.AbsoluteSize.Y, height)) / rowHeight) + 1);
				local want = {};
				for row = first, last do
					for col = 0, COLS - 1 do
						local index = row * COLS + col + 1;
						if index <= total then want[index] = { row, col } end;
					end;
				end;
				for index, tile in pairs(live) do
					if not want[index] then
						tile.card.Visible, tile.hovered = false, false;
						tile.entry, tile.key = nil, nil;
						pool[#pool + 1], live[index] = tile, nil;
					end;
				end;
				for index, coordinates in pairs(want) do
					local tile = live[index] or table.remove(pool) or build();
					live[index] = tile;
					local entry, key = list[index], cfg.keyOf(list[index]);
					if key ~= tile.key then
						tile.active, tile.hover, tile.favorite, tile.pulse = key == selectedKey and 1 or 0, 0, 0, 0;
						tile.hovered = false;
						tile.img.Image, tile.label.Text = cfg.imageOf(entry), cfg.nameOf(entry);
					end;
					tile.entry, tile.key = entry, key;
					tile.card.Parent, tile.card.Visible = sf, true;
					tile.card.Size = UDim2.fromOffset(width, CELL_H);
					tile.card.Position = UDim2.fromOffset(PAD + coordinates[2] * (width + PAD), PAD + coordinates[1] * rowHeight);
				end;
			end;
			function grid.select(key) selectedKey = key end;
			function grid.queue(resetScroll)
				if disposed then return end;
				dirty = true;
				if resetScroll then sf.CanvasPosition = Vector2.zero end;
			end;
			function grid.step(dt)
				if not visible() then restoreScroll(); return end;
				if dirty then grid.refresh() end;
				local blend = 1 - math.exp(-18 * math.min(dt, 0.1));
				for _, tile in pairs(live) do
					local on = tile.key == selectedKey;
					tile.active = tile.active + ((on and 1 or 0) - tile.active) * blend;
					tile.hover = tile.hover + ((tile.hovered and 1 or 0) - tile.hover) * blend;
					local favorite = cfg.isFav and cfg.isFav(tile.entry) and 1 or 0;
					tile.favorite = tile.favorite + (favorite - tile.favorite) * blend;
					tile.pulse = tile.pulse * (1 - blend);
					local accent = NeverLose.AccentColor;
					tile.card.BackgroundColor3 = COL_IDLE:Lerp(COL_HOVER, tile.hover * 0.7):Lerp(COL_ACTIVE, tile.active);
					tile.stroke.Color = COL_EDGE:Lerp(accent, tile.active);
					tile.stroke.Thickness = 1 + tile.active;
					tile.stroke.Transparency = 0.45 * (1 - tile.active);
					tile.label.TextColor3 = COL_TEXT:Lerp(accent, tile.active);
					tile.dot.BackgroundColor3, tile.dot.BackgroundTransparency = accent, 1 - tile.active;
					tile.star.TextTransparency = 1 - tile.favorite;
					tile.star.Rotation = -15 * (1 - tile.favorite);
					tile.scale.Scale = 1 - tile.pulse * 0.025;
				end;
			end;
			sf:GetPropertyChangedSignal("CanvasPosition"):Connect(function() grid.queue() end);
			sf:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() grid.queue() end);

			sf.MouseLeave:Connect(restoreScroll);
			sf.Destroying:Connect(function() disposed = true; restoreScroll() end);
			Window.Signal:Connect(function(value) if not value then restoreScroll() else grid.queue() end end);
			if cfg.tab then cfg.tab.Signal:Connect(function(value) if not value then restoreScroll() else grid.queue() end end) end;
			grids[#grids + 1] = grid;
			return grid;
		end;

		NeverLose:AddSignal(RunService.Heartbeat:Connect(function(dt)
			if not A.Alive then return end;
			for _, grid in ipairs(grids) do grid.step(dt) end;
		end));

	local FAVS_FILE = userFile("favourites.json");

	local favorites = { emotes = {}, packs = {} };

	pcall(function()
		if isfile and isfile(FAVS_FILE) then
			local decoded = game:GetService("HttpService"):JSONDecode(readfile(FAVS_FILE));

			if type(decoded) == "table" then
				favorites.emotes = type(decoded.emotes) == "table" and decoded.emotes or {};
				favorites.packs = type(decoded.packs) == "table" and decoded.packs or {};
				local function normalizeKeys(source)
					local normalized = {};
					if type(source) ~= "table" then return normalized end;
					for key, value in pairs(source) do
						if value then normalized[prettyName(key)] = true end
					end
					return normalized;
				end
				favorites.emotes = normalizeKeys(favorites.emotes);
				favorites.packs = normalizeKeys(favorites.packs);
			end;
		end;
	end);

	local function saveFavorites()
		pcall(function()
			if not (writefile and isfolder) then return end;
			if not isfolder(USER_DATA) then makefolder(USER_DATA) end;

			writefile(FAVS_FILE, game:GetService("HttpService"):JSONEncode(favorites));
		end);
	end;

	local function favoriteKey(entry) return tostring(entry.id) end;
	local function isFavorite(list, entry)
		local key = favoriteKey(entry);

		return list[key] == true or list[entry.name] == true or list[prettyName(entry.name)] == true;
	end;
	local function toggleFavorite(list, entry)
		local enabled = not isFavorite(list, entry);
		list[entry.name], list[prettyName(entry.name)] = nil, nil;
		list[favoriteKey(entry)] = enabled or nil;
		saveFavorites();
	end;
	local function filtered(source, search, favs, nameOf)
		local needle = tostring(search or ""):lower();
		local pinned, rest = {}, {};
		for _, entry in ipairs(source or {}) do
			local haystack = (nameOf(entry) .. " " .. tostring(entry.id)):lower();
			local matches = true;
			for word in needle:gmatch("%S+") do
				if not haystack:find(word, 1, true) then matches = false; break end;
			end;
			if matches then
				local list = isFavorite(favs, entry) and pinned or rest;
				list[#list + 1] = entry;
			end;
		end;
		for _, entry in ipairs(rest) do pinned[#pinned + 1] = entry end;
		return pinned;
	end;

	local emoteSearch, emoteList, emoteGrid = "", {};
	local packSearch, packList, packGrid;

	local function refreshEmotes()
		emoteList = filtered(A.EmoteCatalog, emoteSearch, favorites.emotes, function(e) return prettyName(e.name or tostring(e.id)) end);

		if emoteGrid then emoteGrid.queue() end;
	end;

	Sections.Emotes:AddLabel("Search"):AddTextInput({
		Default = "",
		Placeholder = "Search emotes...",
		Flag = "emote_search",
		Size = 130,
		Callback = function(v) emoteSearch = v or ""; refreshEmotes(); if emoteGrid then emoteGrid.queue(true) end end,
	});

		emoteGrid = buildGrid(sectionHost(Sections.Emotes), 480, 10, {
		tab = MiscGroup.Emotes,
		getList = function() return emoteList end,
		keyOf = function(e) return tostring(e.id) end,
		nameOf = function(e) return prettyName(e.name or tostring(e.id)) end,
		imageOf = function(e) return "rbxthumb://type=Asset&id=" .. tostring(e.id) .. "&w=420&h=420" end,
		onClick = function(entry, key)
			if tostring(A.SelectedEmoteId or A.PendingEmoteId or "") == key then A.ResetEmote() else A.PlayEmote(entry.id) end;
		end,
		isFav = function(entry) return isFavorite(favorites.emotes, entry) end,
		onFav = function(entry)
			toggleFavorite(favorites.emotes, entry);
			refreshEmotes();
			emoteGrid.queue(true);
		end,
	});

	Sections.EmoteOptions:AddLabel("Loop"):AddToggle({
		Default = false, Flag = "emote_loop",
		Callback = function(v)
			if A._SetEmoteLoop then A._SetEmoteLoop(v) else A.EmoteLoop = v end;
		end,
	});

	Sections.EmoteOptions:AddLabel("Speed"):AddSlider({
		Min = 10, Max = 300, Default = 100, Type = "%", Size = 100,
		Flag = "emote_speed",
		Callback = function(v)
			A.EmoteSpeed = v;

			local track = A._currentEmoteTrack;

			if track then pcall(track.AdjustSpeed, track, v / 100) end;
		end,
	});

	Sections.EmoteOptions:AddButton({
		Icon = "stop-large",
		Name = "Stop Emote",
		Callback = function()
			if A.ResetEmote then pcall(A.ResetEmote) end;
			emoteGrid.select(nil);
		end,
	});

	packSearch, packList, packGrid = "", {}, {};

	local function refreshPacks()
		packList = filtered(A.PackCatalog, packSearch, favorites.packs, function(e) return prettyName(e.name) end);

		if packGrid and packGrid.queue then packGrid.queue() end;
	end;

	Sections.Animations:AddLabel("Search"):AddTextInput({
		Default = "",
		Placeholder = "Search packs...",
		Flag = "pack_search",
		Size = 130,
		Callback = function(v) packSearch = v or ""; refreshPacks(); if packGrid and packGrid.queue then packGrid.queue(true) end end,
	});

		packGrid = buildGrid(sectionHost(Sections.Animations), 480, 10, {
		tab = MiscGroup.Animations,
		getList = function() return packList end,
		keyOf = function(e) return e.name end,
		nameOf = function(e) return prettyName(e.name) end,
		imageOf = function(e) return "rbxthumb://type=BundleThumbnail&id=" .. tostring(e.id) .. "&w=420&h=420" end,
		onClick = function(entry, key)
			A.ApplyPack((A.PackName == entry.name or A.PendingPack == entry.name) and "Default" or entry.name);
		end,
		isFav = function(entry) return isFavorite(favorites.packs, entry) end,
		onFav = function(entry)
			toggleFavorite(favorites.packs, entry);
			refreshPacks();
			packGrid.queue(true);
		end,
	});

	pcall(function()
		NeverLose.Lib:hook("anim_pack", "string",
			function() return tostring(A.PendingPack or A.PackName or "Default") end,
			function(value)
				value = tostring(value or "Default");
				if value == "" then value = "Default" end;
				if not __ALIVE() or not A.Alive then return end;
				assert(A.ApplyPack(value), "Animation pack is unavailable");
			end);

		NeverLose.Lib:hook("emote_pick", "string",
			function() return tostring(A.SelectedEmoteId or A.PendingEmoteId or "") end,
			function(value)
				local id = tonumber(value);
				if not __ALIVE() or not A.Alive then return end;
				if value == "" then
					if A.SelectedEmoteId or A.PendingEmoteId or A._currentEmoteTrack then A.ResetEmote() end;
					return;
				end;
				assert(id and id > 0 and id % 1 == 0, "Invalid emote id");
				assert(A.PlayEmote(id), "Emote could not start");
			end);
	end);

	Sections.AnimationOptions:AddButton({
		Icon = "arrow-rotate-right",
		Name = "Reapply",
		Callback = function()
			if A.ApplyPack then pcall(A.ApplyPack, A.PackName) end;
		end,
	});

	Sections.AnimationOptions:AddButton({
		Icon = "trash-can",
		Name = "Reset To Default",
		Callback = function()
			A.PackName = "Default";

			if A.ApplyPack then pcall(A.ApplyPack, "Default") end;
			packGrid.select(nil);
		end,
	});

	local emoteStatus = Sections.EmoteOptions:AddLabel("Idle", true);
	local packStatus = Sections.AnimationOptions:AddLabel("Default", true);
	A.OnStateChange = function()
		if not A.Alive then return end;
		emoteGrid.select(A.SelectedEmoteId and tostring(A.SelectedEmoteId) or nil);
		packGrid.select(A.PackName ~= "Default" and A.PackName or nil);
		emoteStatus:SetText(A.PendingEmoteId and "Loading..." or (A.SelectedEmoteId and "Playing" or A.LastError or "Idle"));
		packStatus:SetText(A.PendingPack and "Loading..." or (A.PackName ~= "Default" and prettyName(A.PackName) or A.LastError or "Default"));
	end;
	A.OnStateChange();

	ESP.RefreshAnimGrids = function()
		refreshEmotes();
		refreshPacks();
	end;

	task.spawn(function()
		local lastEmotes, lastPacks = -1, -1;

		while A.Alive and NeverLose.ScreenGui.Parent do
			local emotes = #(A.EmoteCatalog or {});
			local packs = #(A.PackCatalog or {});

			if emotes ~= lastEmotes or packs ~= lastPacks then
				lastEmotes, lastPacks = emotes, packs;

				pcall(refreshEmotes);
				pcall(refreshPacks);
			end;

			task.wait(2);
		end;
	end);

	local TeleportService = game:GetService("TeleportService");
	local HttpService = game:GetService("HttpService");

	local function say(ok, text)
		Notification.new({
			Title = ok and "Helpers" or "Helpers failed",
			Content = tostring(text),
			Duration = ok and 4 or 6,
		});
	end;

	local zoomLimit = { On = false, Max = nil, Min = nil };

	local function applyZoom()
		local ok = pcall(function()
			if zoomLimit.On then
				if zoomLimit.Max == nil then
					zoomLimit.Max = LocalPlayer.CameraMaxZoomDistance;
					zoomLimit.Min = LocalPlayer.CameraMinZoomDistance;
				end;

				LocalPlayer.CameraMaxZoomDistance = 2048;
			elseif zoomLimit.Max ~= nil then
				LocalPlayer.CameraMaxZoomDistance = zoomLimit.Max;
				LocalPlayer.CameraMinZoomDistance = zoomLimit.Min;
				zoomLimit.Max, zoomLimit.Min = nil, nil;
			end;
		end);

		return ok;
	end;

	Sections.Helpers:AddLabel("No Zoom Limit"):AddToggle({
		Name = "No Zoom Limit",
		Default = false,
		ToolTip = "Removes the zoom cap",
		Flag = "no_zoom_limit",
		Callback = function(v)
			zoomLimit.On = v;

			applyZoom();
		end,
	});

	NeverLose:AddSignal(LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.6);

		if __ALIVE() and zoomLimit.On then
			if LocalPlayer.CameraMaxZoomDistance ~= 2048 then
				zoomLimit.Max, zoomLimit.Min = LocalPlayer.CameraMaxZoomDistance, LocalPlayer.CameraMinZoomDistance;
			end;

			applyZoom();
		end;
	end));

	onUnload("zoom limit", function()
		zoomLimit.On = false;

		applyZoom();
	end);

	Sections.Helpers:AddButton({
		Icon = "refresh-cw",
		Name = "Rejoin",
		ToolTip = "Same server",
		Callback = function()
			say(true, "rejoining...");

			task.spawn(function()
				local ok, err = pcall(function()
					TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer);
				end);

				if not ok then say(false, tostring(err)) end;
			end);
		end,
	});

	Sections.Helpers:AddButton({
		Icon = "compass",
		Name = "Server Hop",
		ToolTip = "Random server",
		Callback = function()
			say(true, "looking for a server...");

			task.spawn(function()
				local cursor, tried = "", 0;

				while tried < 6 do
					tried = tried + 1;

					local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100")
						:format(game.PlaceId) .. (cursor ~= "" and ("&cursor=" .. cursor) or "");

					local body = Remote.download(url);
					local ok, page = pcall(function() return HttpService:JSONDecode(body) end);

					if not (ok and type(page) == "table" and type(page.data) == "table") then
						return say(false, "server list unavailable");
					end;

					for _, server in ipairs(page.data) do
						if server.id ~= game.JobId
							and (tonumber(server.playing) or 0) < (tonumber(server.maxPlayers) or 0) then
							local sent = pcall(function()
								TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer);
							end);

							if sent then return end;
						end;
					end;

					if type(page.nextPageCursor) ~= "string" then break end;

					cursor = page.nextPageCursor;
				end;

				say(false, "No open servers");
			end);
		end,
	});

	Sections.Helpers:AddButton({
		Icon = "copy",
		Name = "Copy Join Link",
		ToolTip = "Copies a join link",
		Callback = function()
			local link = ("roblox://experiences/start?placeId=%d&gameInstanceId=%s")
				:format(game.PlaceId, game.JobId);

			if setclipboard and pcall(setclipboard, link) then
				say(true, "join link copied");
			else
				say(false, "No clipboard support");
			end;
		end,
	});

end;
