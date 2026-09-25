--!nonstrict
--[[
	trail.lua — extracted feature module (require id "modules.trail").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("trail") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("trail", function()
			return require("modules.trail")({ ESP = ESP, LocalPlayer = LocalPlayer, NeverLose = NeverLose, Players = Players, Remote = Remote, RunService = RunService, Sections = Sections, Visuals = Visuals, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local Players = ctx.Players;
	local Remote = ctx.Remote;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local Visuals = ctx.Visuals;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("trail") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local T = {
		On = false,
		Target = "Self",
		Color = Color3.fromRGB(120, 200, 255),
		Color2 = Color3.fromRGB(255, 120, 220),
		Rainbow = false,
		Style = "Bloom",
		Size = 10,
		Life = 0.9,
		Rate = 140,
		Bright = 85,
		Amount = 100,
		Spread = 100,
		Gravity = 100,
		Always = false,
		Speed = 18,
	};

	local PARTICLES = "particles/";

	local STYLES = {
		Bloom = { kind = "particle", sprite = { "p_bloom" }, size = 2.04, rate = 34, life = 1.0,
			speed = { 0.4, 1.4 }, spread = 16, rise = 1.6, drag = 3.5, spin = 20, light = 0.85 },
		Glow = { kind = "particle", sprite = { "p_glow", "p_softglow" }, size = 2.40, rate = 26, life = 1.2,
			speed = { 0.2, 1.0 }, spread = 22, rise = 2.2, drag = 4, spin = 12, light = 1 },
		Sparkle = { kind = "particle", sprite = { "p_sparkle" }, size = 1.20, rate = 46, life = 0.8,
			speed = { 1.0, 3.2 }, spread = 45, rise = -2, drag = 2.2, spin = 180, light = 0.9 },
		Stars = { kind = "particle", sprite = { "p_star", "p_starnew" }, size = 1.32, rate = 34, life = 1.1,
			speed = { 0.8, 2.4 }, spread = 38, rise = -1.5, drag = 2, spin = 140, light = 0.55 },
		Fireflies = { kind = "particle", sprite = { "p_firefly" }, size = 0.96, rate = 30, life = 1.8,
			speed = { 0.3, 1.2 }, spread = 60, rise = 1.2, drag = 5, spin = 30, light = 1 },
		Hearts = { kind = "particle", sprite = { "p_heart" }, size = 1.44, rate = 22, life = 1.3,
			speed = { 0.6, 1.8 }, spread = 30, rise = 2.4, drag = 3, spin = 60, light = 0.35 },
		Snow = { kind = "particle", sprite = { "p_snowflake" }, size = 1.20, rate = 30, life = 1.6,
			speed = { 0.3, 1.1 }, spread = 42, rise = -1.8, drag = 3.5, spin = 90, light = 0.4 },
		Lightning = { kind = "particle", sprite = { "p_lightning" }, size = 1.44, rate = 28, life = 0.6,
			speed = { 1.4, 3.6 }, spread = 30, rise = 0, drag = 1.5, spin = 220, light = 1 },
		Crowns = { kind = "particle", sprite = { "p_crown" }, size = 1.44, rate = 16, life = 1.4,
			speed = { 0.6, 1.6 }, spread = 28, rise = 2.0, drag = 3, spin = 70, light = 0.3 },

		Smolder = { kind = "particle", sprite = { "p_bloom", "p_softglow" }, size = 3.20,
			rate = 14, life = 2.6, speed = { 0.1, 0.5 }, spread = 70, rise = 1.0, drag = 6, spin = 8, light = 0.45 },
		Halo = { kind = "particle", sprite = { "p_glowboost" }, size = 2.80, rate = 12, life = 1.6,
			speed = { 0.05, 0.3 }, spread = 90, rise = 0.4, drag = 7, spin = 15, light = 1.3 },
		Starfall = { kind = "particle", sprite = { "p_star", "p_starnew", "p_sparkle" }, size = 0.84,
			rate = 60, life = 2.2, speed = { 0.2, 0.9 }, spread = 25, rise = -6, drag = 1.2, spin = 200, light = 0.8 },
		Swarm = { kind = "particle", sprite = { "p_firefly", "p_sparkle" }, size = 0.60, rate = 90,
			life = 1.1, speed = { 1.6, 4.2 }, spread = 120, rise = 0, drag = 2.5, spin = 260, light = 1 },
		Static = { kind = "particle", sprite = { "p_lightning", "p_sparkle" }, size = 0.90, rate = 75,
			life = 0.35, speed = { 2.4, 5.5 }, spread = 75, rise = 0, drag = 0.8, spin = 300, light = 1.2 },
		Frost = { kind = "particle", sprite = { "p_snowflake", "p_sparkle" }, size = 0.78, rate = 55,
			life = 2.4, speed = { 0.2, 0.8 }, spread = 80, rise = -1.0, drag = 5, spin = 60, light = 0.7 },
		Bloomburst = { kind = "particle", sprite = { "p_bloom", "p_glow", "p_glowboost" }, size = 1.10,
			rate = 100, life = 0.5, speed = { 3.0, 7.0 }, spread = 180, rise = 0, drag = 1, spin = 120, light = 1.4 },

		Ribbon = { kind = "ribbon", texture = "", light = 1 },
		Comet = { kind = "ribbon", texture = Remote.file(PARTICLES .. "p_glow.png"), local_file = true, light = 2 },
		Smoke = { kind = "ribbon", texture = "rbxasset://textures/particles/smoke_main.dds", light = 0.4 },
	};

	local order = {
		"Bloom", "Glow", "Sparkle", "Stars", "Fireflies", "Hearts", "Snow",
		"Lightning", "Crowns", "Smolder", "Halo", "Starfall", "Swarm", "Static", "Frost",
		"Bloomburst", "Ribbon", "Comet", "Smoke",
	};

	local function customAsset(path)
		return Remote.id(path) or "";
	end;

	local function textureFor(style)
		if style.sprite then
			return customAsset(Remote.file(PARTICLES .. style.sprite[math.random(1, #style.sprite)] .. ".png"));
		end;

		if not style.local_file then return style.texture end;

		return customAsset(style.texture);
	end;

	local live = {};
	local WHITE = Color3.new(1, 1, 1);

	local function clear(character)
		local entry = live[character];
		if not entry then return end;

		for _, key in ipairs({ "trail", "emitter", "a", "b" }) do
			local part = entry[key];

			if part then pcall(function() part:Destroy() end) end;
		end;

		live[character] = nil;
	end;

	local function clearAll()
		for character, entry in pairs(live) do
			if not entry.cfg or entry.cfg == T then clear(character) end;
		end;
	end;

	local function colors(cfg)
		cfg = cfg or T;

		if cfg.Rainbow then
			local hue = (os.clock() * 0.12) % 1;

			return Color3.fromHSV(hue, 0.85, 1), Color3.fromHSV((hue + 0.22) % 1, 0.85, 1);
		end;

		return cfg.Color, cfg.Color2;
	end;

	local function sequenceFor(style, cfg)
		if style.own then return ColorSequence.new(Color3.new(1, 1, 1)) end;

		local first, second = colors(cfg);

		return ColorSequence.new(first, second);
	end;

	local function sizeFor(style, cfg)
		cfg = cfg or T;
		local base = style.size * (cfg.Size / 10);

		return NumberSequence.new({
			NumberSequenceKeypoint.new(0, base * 0.35),
			NumberSequenceKeypoint.new(0.25, base),
			NumberSequenceKeypoint.new(1, base * 0.1),
		});
	end;

	local function fadeFor(cfg)
		cfg = cfg or T;
		local floor = 1 - math.clamp(cfg.Bright / 100, 0.05, 1);

		return NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.12, floor),
			NumberSequenceKeypoint.new(0.55, floor + (1 - floor) * 0.35),
			NumberSequenceKeypoint.new(1, 1),
		});
	end;

	local function buildParticles(character, root, style, cfg)
		cfg = cfg or T;
		local attach = Instance.new("Attachment");
		attach.Name = NeverLose.RandomString();
		attach.Position = Vector3.new(0, -0.9, 0);
		attach.Parent = root;

		local emitter = Instance.new("ParticleEmitter");
		emitter.Name = NeverLose.RandomString();
		emitter.Texture = textureFor(style);
		emitter.LightEmission = style.light;

	emitter.LightInfluence = 0;
		emitter.Enabled = false;
		emitter.Rate = style.rate * (cfg.Rate / 100) * (cfg.Amount / 100);
		emitter.Lifetime = NumberRange.new(cfg.Life * 0.65, cfg.Life);
		emitter.Speed = NumberRange.new(style.speed[1], style.speed[2]);
		emitter.SpreadAngle = Vector2.new(style.spread, style.spread) * (cfg.Spread / 100);
		emitter.Acceleration = Vector3.new(0, style.rise * (cfg.Gravity / 100), 0);
		emitter.Drag = style.drag;
		emitter.VelocityInheritance = 0.3;
		emitter.EmissionDirection = Enum.NormalId.Back;
		emitter.Rotation = NumberRange.new(0, 360);
		emitter.RotSpeed = NumberRange.new(-style.spin, style.spin);
		emitter.Color = sequenceFor(style, cfg);
		emitter.Size = sizeFor(style, cfg);
		emitter.Transparency = fadeFor(cfg);
		emitter.Parent = attach;

		live[character] = {
			emitter = emitter, a = attach, root = root, style = style,
			swap = 0, size = cfg.Size, rate = cfg.Rate, amount = cfg.Amount, bright = cfg.Bright,
			enabled = false, life = cfg.Life, cfg = cfg,
		};
	end;

	local function buildRibbon(character, root, style, cfg)
		cfg = cfg or T;
		local a = Instance.new("Attachment");
		a.Name = NeverLose.RandomString();
		a.Position = Vector3.new(0, cfg.Size * 0.09, 0);
		a.Parent = root;

		local b = Instance.new("Attachment");
		b.Name = NeverLose.RandomString();
		b.Position = Vector3.new(0, -cfg.Size * 0.09, 0);
		b.Parent = root;

		local first, second = colors(cfg);

		local trail = Instance.new("Trail");
		trail.Name = NeverLose.RandomString();
		trail.Attachment0, trail.Attachment1 = a, b;
		trail.Lifetime = cfg.Life;
		trail.MinLength = 0.08;
		trail.FaceCamera = true;
		trail.LightEmission = style.light;
		trail.LightInfluence = 0;
		trail.Texture = textureFor(style);
		trail.TextureMode = Enum.TextureMode.Static;
		trail.TextureLength = 4;
		trail.Color = ColorSequence.new(first, second);

		trail.WidthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.62),
			NumberSequenceKeypoint.new(1, 0),
		});

		local floor = 1 - math.clamp(cfg.Bright / 100, 0.05, 1);

		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, floor),
			NumberSequenceKeypoint.new(0.7, floor + (1 - floor) * 0.5),
			NumberSequenceKeypoint.new(1, 1),
		});

		trail.Parent = root;

		live[character] = {
			trail = trail, a = a, b = b, root = root, style = style, size = cfg.Size,
			life = cfg.Life, first = first, second = second, cfg = cfg,
		};
	end;

	local FX = ESP.GameFX;

	local guests = {};

	local function build(character)
		local root = character:FindFirstChild("HumanoidRootPart");
		if not root then return end;

		clear(character);

		local owner = Players:GetPlayerFromCharacter(character);
		local cfg = (owner and guests[owner]) or T;

		if cfg == T and T.Game and character == LocalPlayer.Character then return end;

		local style = STYLES[cfg.Style] or STYLES.Bloom;

		if style.kind == "ribbon" then
			buildRibbon(character, root, style, cfg);
		else
			buildParticles(character, root, style, cfg);
		end;
	end;

	local function wants(player)
		if not T.On then return false end;

		local isSelf = player == LocalPlayer;

		return T.Target == "All" or (isSelf and T.Target == "Self") or (not isSelf and T.Target == "Other");
	end;

	local function gameTune()
		if not FX then return end;
		local first, second = colors();
		FX.Tune("trail", {
			glow = T.Bright / 85, rate = T.Rate / 140, size = T.Size / 10, life = T.Life / 0.9,
			amount = T.Amount / 100,
		});
	end;

	local function trailAllowed(id, label)
		local text = (tostring(id) .. " " .. tostring(label or "")):lower();
		for _, blocked in ipairs({
			"pride", "minecraft", "cubic", "block", "cube", "dash",
			"petal", "leaves", "flower", "flame", "bubble", "ember", "bloomfall",
			"confetti", "reicle", "reticle", "relic", "soap", "beam", "chain",
		}) do
			if text:find(blocked, 1, true) then return false end;
		end;
		return true;
	end;

	local function refresh()
		clearAll();
		if T.Game and not trailAllowed(T.Game) then T.Game = nil end;

		if FX then FX.SetGroup("trail", (T.On and T.Game and trailAllowed(T.Game)) and { T.Game } or {}) end;
		gameTune();

		if not T.On then return end;
		if not T.Style and not T.Game then return end;

		for _, player in ipairs(Players:GetPlayers()) do
			if wants(player) and player.Character then build(player.Character) end;
		end;
	end;

	local tuneClock, tuned = 0, nil;
	NeverLose:AddSignal(RunService.RenderStepped:Connect(function(dt)
		if not NeverLose.ScreenGui.Parent then return end;

		if T.Game and T.On then
			tuneClock += dt;
			if tuneClock > 0.12 then
				tuneClock = 0;
				local first, second = colors();
				local key = table.concat({ tostring(first), tostring(second), T.Bright, T.Rate, T.Amount, T.Size, T.Life, tostring(T.Rainbow) }, "|");
				if key ~= tuned then tuned = key; gameTune() end;
			end;
		end;
		if not next(live) then return end;
		local frameFirst, frameSecond = colors();
		local frameSequence = T.Rainbow and ColorSequence.new(frameFirst, frameSecond) or nil;

		for character, entry in pairs(live) do
			local cfg = entry.cfg or T;
			local ownFirst, ownSecond, ownSequence = frameFirst, frameSecond, frameSequence;
			if cfg ~= T then
				ownFirst, ownSecond = colors(cfg);
				ownSequence = cfg.Rainbow and ColorSequence.new(ownFirst, ownSecond) or nil;
			end;
			if not entry.root or not entry.root.Parent then
				clear(character);
			elseif entry.emitter then
				if not entry.emitter.Parent then
					clear(character);
				else
					local velocity = entry.root.AssemblyLinearVelocity;
					local planarSpeed = (velocity * Vector3.new(1, 0, 1)).Magnitude;
					local humanoid = character:FindFirstChildOfClass("Humanoid");
					local intent = humanoid and humanoid.MoveDirection.Magnitude > 0.05;
					local airborne = humanoid and (humanoid:GetState() == Enum.HumanoidStateType.Jumping
						or humanoid:GetState() == Enum.HumanoidStateType.Freefall);
					local moving = cfg.Always or (planarSpeed > 7 and (intent or airborne));
					local style = entry.style;

					if entry.enabled ~= moving then
						entry.enabled = moving;
						entry.emitter.Enabled = moving;
					end;
					local first, second = ownFirst, ownSecond;
					if style.own then first, second = WHITE, WHITE end;
					if entry.first ~= first or entry.second ~= second then
						entry.first, entry.second = first, second;
						entry.emitter.Color = (not style.own and ownSequence) or ColorSequence.new(first, second);
					end;
					if entry.life ~= cfg.Life then
						entry.life = cfg.Life;
						entry.emitter.Lifetime = NumberRange.new(cfg.Life * 0.65, cfg.Life);
					end;

					if entry.size ~= cfg.Size then
						entry.size = cfg.Size;
						entry.emitter.Size = sizeFor(style, cfg);
					end;

					if entry.rate ~= cfg.Rate or entry.amount ~= cfg.Amount then
						entry.rate, entry.amount = cfg.Rate, cfg.Amount;
						entry.emitter.Rate = style.rate * (cfg.Rate / 100) * (cfg.Amount / 100);
					end;

					if entry.bright ~= cfg.Bright then
						entry.bright = cfg.Bright;
						entry.emitter.Transparency = fadeFor(cfg);
					end;

					if style.sprite and #style.sprite > 1 and moving then
						entry.swap = entry.swap + dt;

						if entry.swap > 0.22 then
							entry.swap = 0;
							entry.emitter.Texture = textureFor(style);
						end;
					end;
				end;
			elseif not entry.trail or not entry.trail.Parent then
				clear(character);
			else
				if entry.first ~= ownFirst or entry.second ~= ownSecond then
					entry.first, entry.second = ownFirst, ownSecond;
					entry.trail.Color = ownSequence or ColorSequence.new(ownFirst, ownSecond);
				end;
				if entry.life ~= cfg.Life then
					entry.life = cfg.Life;
					entry.trail.Lifetime = cfg.Life;
				end;

				if entry.size ~= cfg.Size then
					entry.size = cfg.Size;
					entry.a.Position = Vector3.new(0, cfg.Size * 0.09, 0);
					entry.b.Position = Vector3.new(0, -cfg.Size * 0.09, 0);
				end;
			end;
		end;
	end));

	local function watch(player)
		NeverLose:AddPlayerSignal(player, player.CharacterAdded:Connect(function(character)
			if not wants(player) then return end;

			task.delay(1, function()
				if __ALIVE() and T.On and wants(player) and player.Parent and player.Character == character and character.Parent then build(character) end;
			end);
		end));
	end;

	for _, player in ipairs(Players:GetPlayers()) do watch(player) end;
	NeverLose:AddSignal(Players.PlayerAdded:Connect(watch));

	ESP.Trail = T;

	function T.Worn()
		if not (T.On and T.Style and STYLES[T.Style] and (T.Target == "Self" or T.Target == "All")) then return nil end;
		return {
			s = T.Style, a = T.Color:ToHex(), b = T.Color2:ToHex(), r = T.Rainbow == true, z = T.Size, l = T.Life,
			n = T.Rate, g = T.Bright, m = T.Amount, w = T.Always == true,
		};
	end;

	function T.Dress(player, spec)
		if player == LocalPlayer then return end;
		if type(spec) ~= "table" or not STYLES[tostring(spec.s)] then T.Undress(player); return end;

		local okA, first = pcall(Color3.fromHex, tostring(spec.a));
		local okB, second = pcall(Color3.fromHex, tostring(spec.b));
		local cfg = {
			Style = tostring(spec.s), Color = okA and first or T.Color, Color2 = okB and second or T.Color2,
			Rainbow = spec.r == true, Size = math.clamp(tonumber(spec.z) or 10, 1, 40),
			Life = math.clamp(tonumber(spec.l) or 0.9, 0.1, 5), Rate = math.clamp(tonumber(spec.n) or 140, 1, 600),
			Bright = math.clamp(tonumber(spec.g) or 85, 1, 100), Amount = math.clamp(tonumber(spec.m) or 100, 1, 400),
			Spread = 100, Gravity = 100, Always = spec.w == true,
		};
		cfg.key = table.concat({ cfg.Style, tostring(spec.a), tostring(spec.b), tostring(cfg.Rainbow), cfg.Size, cfg.Life, cfg.Rate, cfg.Bright, cfg.Amount, tostring(cfg.Always) }, "|");

		if guests[player] and guests[player].key == cfg.key then return end;

		guests[player] = cfg;
		if player.Character then pcall(build, player.Character) end;
	end;

	function T.Undress(player)
		if not guests[player] then return end;
		guests[player] = nil;

		local character = player.Character;
		if character and live[character] and live[character].cfg ~= T then clear(character) end;

		if character and T.On and wants(player) then pcall(build, character) end;
	end;

	function T.Guests() return guests end;

	task.spawn(function()
		while __ALIVE() do
			task.wait(1);
			for player, cfg in pairs(guests) do
				if not player.Parent then
					guests[player] = nil;
				else
					local character = player.Character;
					local entry = character and live[character];
					if character and character:FindFirstChild("HumanoidRootPart") and not (entry and entry.cfg == cfg) then
						pcall(build, character);
					end;
				end;
			end;
		end;
	end);
	ESP.TrailStyles = order;
	ESP.ClearTrail = function()
		T.On = false;
		clearAll();
		if FX then pcall(FX.SetGroup, "trail", {}) end;
	end;

	local row = Sections.Trail:AddLabel("Enabled");
	row:AddToggle({ Default = false, Flag = "trail", Callback = function(v) T.On = v; refresh() end });
	row:AddColorPicker({ Default = T.Color, Flag = "trail_color", Callback = function(v) T.Color = v; refresh(); gameTune() end });

	local TRAIL_PREVIEW_FALLBACK = "rbxasset://textures/particles/sparkles_main.dds";
	local function trailRows(art)
		local out = {};
		for _, name in ipairs(order) do
			if trailAllowed(name) then
				local fallback = (art and art[name]) or TRAIL_PREVIEW_FALLBACK;
				local image, rect, size = fallback, nil, nil;
				if FX then image, rect, size = FX.Art("builtin/trail/" .. name, fallback) end;
				out[#out + 1] = { name = name, label = name, image = image, rect = rect, rectsize = size };
			end;
		end;
		for _, entry in ipairs(FX and FX.Catalog or {}) do
			if entry.kind == "Trail" and trailAllowed(entry.id, entry.label) then
				local row = FX.Row(entry);
				local image, rect, size = FX.Art(entry.id, nil);
				if image then row.image, row.rect, row.rectsize = image, rect, size end;
				row.image = row.image or TRAIL_PREVIEW_FALLBACK;
				out[#out + 1] = row;
			end;
		end;
		return out;
	end;

	local trailGrid = Visuals.Trails:AddGallery({
		Name = "Trails", Icon = "wand-sparkles", Position = "left", Height = 440, Cell = 74, Reset = true, Smooth = true,
		Thumb = "Asset", Blank = "wand-sparkles", Empty = "No trails", Values = trailRows(),
		Default = "Bloom", Flag = "trail_style",
		Callback = function(v)
			if type(v) ~= "string" or v == "" then
				T.Style, T.Game = nil, nil;
				refresh();
				return;
			end;
			if STYLES[v] and trailAllowed(v) then
				T.Style, T.Game = v, nil;
			elseif FX and FX.ById[v] and trailAllowed(v, FX.ById[v].label) then
				T.Game = v;
			else
				T.Game = nil;
			end;
			refresh();
		end,
	});

	if FX then
		FX.OnThumbs(function() trailGrid:setdata(trailRows()) end);
		Visuals.Trails.Signal:Connect(function(open) if open then FX.LoadThumbs() end end);
	end;

	task.delay(4, function()
		if not __ALIVE() then return end;
		local art = {};
		for _, name in ipairs(order) do
			local style = STYLES[name];
			local ok, texture = pcall(textureFor, style);
			if ok and type(texture) == "string" and texture ~= "" then art[name] = texture end;
			task.wait();
		end;
		if __ALIVE() then pcall(function() trailGrid:setdata(trailRows(art)) end) end;
	end);

	Sections.Trail:AddLabel("Target"):AddDropdown({
		Default = "Self",
		Values = { "Self", "Other", "All" },
		Flag = "trail_target",
		Callback = function(v) T.Target = v; refresh() end,
	});

	row:AddColorPicker({ Name = "Fade Color", Default = T.Color2, Flag = "trail_color2", Callback = function(v) T.Color2 = v; refresh(); gameTune() end });

	Sections.Trail:AddLabel("Rainbow"):AddToggle({
		Default = false, Flag = "trail_rainbow",
		Callback = function(v) T.Rainbow = v; refresh(); gameTune() end,
	});

	local options = Sections.Trail:AddLabel("Tuning"):AddOption(1);

	options:AddLabel("Size"):AddSlider({
		Min = 2, Max = 40, Default = 10, Rounding = 0, Size = 100,
		Flag = "trail_width",
		Callback = function(v) T.Size = v end,
	});

	options:AddLabel("Length"):AddSlider({
		Min = 2, Max = 40, Default = 9, Rounding = 0, Size = 100,
		Flag = "trail_life",
		Callback = function(v) T.Life = v / 10 end,
	});

	options:AddLabel("Density"):AddSlider({
		Min = 10, Max = 300, Default = 140, Type = "%", Size = 100,
		Flag = "trail_rate",
		Callback = function(v) T.Rate = v end,
	});

	options:AddLabel("Amount"):AddSlider({
		Min = 10, Max = 300, Default = 100, Type = "%", Size = 100,
		Flag = "trail_amount",
		Callback = function(v) T.Amount = v; refresh(); gameTune() end,
	});

	options:AddLabel("Brightness"):AddSlider({
		Min = 5, Max = 100, Default = 85, Type = "%", Size = 100,
		Flag = "trail_bright",
		Callback = function(v) T.Bright = v end,
	});

	options:AddLabel("Spread"):AddSlider({
		Min = 0, Max = 250, Default = 100, Type = "%", Size = 100,
		Flag = "trail_spread",
		Callback = function(v) T.Spread = v; refresh() end,
	});

	options:AddLabel("Drift"):AddSlider({
		Min = 0, Max = 250, Default = 100, Type = "%", Size = 100,
		Flag = "trail_gravity",
		Callback = function(v) T.Gravity = v; refresh() end,
	});

	options:AddLabel("Always On"):AddToggle({
		Default = false, Flag = "trail_always",
		Callback = function(v) T.Always = v; refresh() end,
	});
end;
