--!nonstrict
--[[
	starfall.lua — extracted feature module (require id "modules.starfall").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("starfall") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("starfall", function()
			return require("modules.starfall")({ ESP = ESP, INIT_GENERATION = INIT_GENERATION, Remote = Remote, Render = Render, RunService = RunService, Sections = Sections, TAG = TAG, onUnload = onUnload, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local INIT_GENERATION = ctx.INIT_GENERATION;
	local Remote = ctx.Remote;
	local Render = ctx.Render;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local TAG = ctx.TAG;
	local onUnload = ctx.onUnload;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("starfall") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local F = ESP.WorldFX;
	local S = {
		On = false, Count = 20, Rate = 150, Speed = 100, Length = 100, Size = 100,
		Life = 4, Distance = 260, Preset = "Perseids",
		Head = Color3.fromRGB(255, 249, 230), Tail = Color3.fromRGB(140, 185, 255),
		Fireballs = true, Stars = true, HeadSize = 14, Active = 0, Allocated = 0,
		ThroughWalls = false,
	};
	ESP.Starfall = S;
	local PRESETS = { "Perseids", "Leonids", "Gentle Shower" };
	local PROFILES = {
		Perseids = { direction = Vector3.new(0.92, -0.62, 0.28).Unit, speed = 76, spread = 0.12 },
		Leonids = { direction = Vector3.new(-0.75, -0.9, 0.45).Unit, speed = 108, spread = 0.1 },
		["Gentle Shower"] = { direction = Vector3.new(0.4, -0.85, -0.3).Unit, speed = 48, spread = 0.16 },
	};
	local MAX, LEVELS = 80, 96;
	local rng, slots, fades, hazeFades = Random.new(), {}, {}, {};
	local sky, connection, due, lastCamera;
	local generation, starting = 0, false;
	local lastHead, lastTail, colors;
	for level = 0, LEVELS do
		local alpha = level / LEVELS;
		fades[level] = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.35, 1 - alpha * 0.12),
			NumberSequenceKeypoint.new(0.75, 1 - alpha * 0.72),
			NumberSequenceKeypoint.new(0.96, 1 - alpha * 0.98),
			NumberSequenceKeypoint.new(1, 1 - alpha * 0.45),
		});
		hazeFades[level] = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.65, 1 - alpha * 0.1),
			NumberSequenceKeypoint.new(0.93, 1 - alpha * 0.28),
			NumberSequenceKeypoint.new(1, 1 - alpha * 0.08),
		});
	end;
	local hazeTexture, glowTexture, starTexture;
	local function ensure(token)
		if sky and sky.Parent then return true end;
		local haze = Remote.asset("trail/bloom.png") or "";
		local glow = Remote.asset("particles/p_glow.png") or "rbxasset://textures/particles/sparkles_main.dds";
		local star = Remote.asset("particles/star_user.png") or glow;
		if not __ALIVE() or not S.On or token ~= generation then return false end;
		hazeTexture, glowTexture = haze, glow;
		starTexture = star;
		sky = Instance.new("Part");
		sky.Name = "VisualsStarfall";
		sky.Anchored, sky.CanCollide, sky.CanTouch, sky.CanQuery = true, false, false, false;
		sky.Transparency, sky.CastShadow, sky.Size = 1, false, Vector3.one;
		sky:SetAttribute(TAG, INIT_GENERATION); sky.Parent = workspace;
		return true;
	end;
	local function make()
		local tail, nose = Instance.new("Attachment"), Instance.new("Attachment");
		tail.Parent, nose.Parent = sky, sky;
		local function beam(texture)
			local b = Instance.new("Beam");
			b.Attachment0, b.Attachment1 = tail, nose;
			b.FaceCamera, b.LightInfluence, b.LightEmission = true, 0, 1;
			b.Texture, b.TextureSpeed, b.Segments = texture, 0, 8;
			b.Width0, b.Enabled, b.Parent = 0, false, sky;
			return b;
		end;
		local card = Instance.new("BillboardGui");
		card.Adornee, card.AlwaysOnTop, card.LightInfluence = nose, S.ThroughWalls, 0;
		card.Size, card.Enabled, card.Parent = UDim2.fromScale(1, 1), false, sky;
		local blob = Instance.new("ImageLabel");
		blob.BackgroundTransparency, blob.Size = 1, UDim2.fromScale(1, 1);
		blob.Image, blob.Parent = glowTexture, card;
		local star = Instance.new("ImageLabel");
		star.BackgroundTransparency, star.Size = 1, UDim2.fromScale(0.85, 0.85);
		star.AnchorPoint, star.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5);
		star.Image, star.Rotation, star.Parent = starTexture, 15, card;
		return { tail = tail, nose = nose, line = beam(""), haze = beam(hazeTexture), card = card, blob = blob, star = star, busy = false };
	end;
	local function park(slot)
		slot.busy, slot.line.Enabled, slot.haze.Enabled, slot.card.Enabled = false, false, false, false;
	end;
	local function launch(camera)
		local want = math.floor(F.Number(S.Count, 20, 1, MAX));
		local slot, active = nil, 0;
		for _, entry in ipairs(slots) do if entry.busy then active += 1 elseif not slot then slot = entry end end;
		if not slot or active >= want then return false end;
		local profile = PROFILES[S.Preset] or PROFILES.Perseids;
		local look = camera.CFrame.LookVector;
		local yaw = math.atan2(look.Z, look.X) + rng:NextNumber(-1.45, 1.45);
		local distance = S.Distance * rng:NextNumber(0.7, 1.2);
		slot.origin = camera.CFrame.Position + Vector3.new(math.cos(yaw) * distance,
			distance * rng:NextNumber(0.5, 1.0), math.sin(yaw) * distance);
		local spread = Vector3.new(rng:NextNumber(-profile.spread, profile.spread),
			rng:NextNumber(-0.06, 0.06), rng:NextNumber(-profile.spread, profile.spread));
		slot.velocity = (profile.direction + spread).Unit * profile.speed * rng:NextNumber(0.85, 1.15);
		slot.fire = S.Fireballs and rng:NextNumber() < 0.07;
		slot.mass = slot.fire and rng:NextNumber(1.7, 2.2) or rng:NextNumber(0.45, 1.1);
		slot.life = S.Life * rng:NextNumber(0.85, 1.15) * (slot.fire and 1.2 or 1);
		slot.age, slot.travel, slot.busy = 0, 0, true;
		return true;
	end;
	local function step(dt)
		if not __ALIVE() or not S.On or not sky or not sky.Parent then return end;
		local camera = Render.camera(); if not camera then return end;
		dt = math.clamp(dt, 0, 0.1);
		local at = camera.CFrame.Position;
		if lastCamera and (at - lastCamera).Magnitude > S.Distance * 2 then
			for _, slot in ipairs(slots) do park(slot) end;
			due = 0;
		end;
		lastCamera = at;
		local want = math.floor(F.Number(S.Count, 20, 1, MAX));

		for _ = 1, math.min(3, want - #slots) do slots[#slots + 1] = make() end;
		S.Allocated = #slots;
		if lastHead ~= S.Head or lastTail ~= S.Tail then
			lastHead, lastTail, colors = S.Head, S.Tail, ColorSequence.new(S.Tail, S.Head);
		end;
		due -= dt;
		if due <= 0 then
			launch(camera);

			due = (60 / S.Rate) * rng:NextNumber(0.8, 1.2);
		end;
		local active = 0;
		for _, slot in ipairs(slots) do
			if slot.busy then
				active += 1;
				if active > want then
					park(slot); active -= 1;
				else
					slot.age += dt; slot.travel += dt * S.Speed / 100;
					local nose = F.MeteorPoint(slot.origin, slot.velocity, slot.travel);
					local horizon = F.Smooth((nose.Y - at.Y - 10) / 40);
					if slot.age >= slot.life or horizon <= 0 then
						park(slot); active -= 1;
					else
						local lit = F.Envelope(slot.age, slot.life, 0.1, 0.32) * horizon;
						local span = math.min(slot.travel * slot.velocity.Magnitude,
							(30 + slot.mass * 22) * S.Length / 100);
						local tailTime = slot.travel - span / slot.velocity.Magnitude;
						local tail = F.MeteorPoint(slot.origin, slot.velocity, tailTime);
						slot.nose.WorldCFrame = F.Frame(nose, slot.velocity + Vector3.new(0, -3.6 * slot.travel, 0));
						slot.tail.WorldCFrame = F.Frame(tail, slot.velocity + Vector3.new(0, -3.6 * tailTime, 0));
						local level = math.floor(math.clamp(lit, 0, 1) * LEVELS + 0.5);
						local width = 0.55 * slot.mass * S.Size / 100;
						local handle = (nose - tail).Magnitude / 3;
						if slot.colors ~= colors then
							slot.line.Color, slot.haze.Color, slot.blob.ImageColor3 = colors, colors, S.Head;
							slot.star.ImageColor3 = S.Head;
							slot.colors = colors;
						end;
						if slot.level ~= level then
							slot.line.Transparency, slot.haze.Transparency = fades[level], hazeFades[level];
							slot.level = level;
						end;
						slot.line.Width1, slot.haze.Width1 = width, width * 3.4;
						slot.line.CurveSize0, slot.line.CurveSize1 = handle, handle;
						slot.haze.CurveSize0, slot.haze.CurveSize1 = handle, handle;
						slot.line.Enabled, slot.haze.Enabled, slot.card.Enabled = lit > 0.005, lit > 0.005, lit > 0.005;
						Render.FxDepth(slot.line, S.ThroughWalls);
						Render.FxDepth(slot.haze, S.ThroughWalls);
						slot.card.AlwaysOnTop = S.ThroughWalls;
						local headPixels = S.HeadSize * (slot.fire and 1.35 or 1);
						slot.card.Size = UDim2.fromOffset(headPixels, headPixels);
						slot.blob.ImageTransparency = 1 - lit * (S.Stars and 0.35 or (slot.fire and 0.9 or 0.72));
						slot.star.ImageTransparency = S.Stars and (1 - lit * 0.95) or 1;
					end;
				end;
			end;
		end;
		S.Active = active;
	end;
	local function stop()
		generation += 1; starting, lastCamera, due = false, nil, 0;
		if connection then connection:Disconnect(); connection = nil end;
		for _, slot in ipairs(slots) do park(slot) end;
		S.Active = 0;
	end;
	local function start()
		if connection or starting or not __ALIVE() or not S.On then return end;
		starting = true;
		local token = generation;
		local ok, ready = pcall(ensure, token);
		if token ~= generation then return end;
		starting = false;
		if not ok then stop(); warn("[visuals] Starfall: " .. tostring(ready)); return end;
		if not ready or not __ALIVE() or not S.On then return end;
		due = 0;
		connection = RunService.RenderStepped:Connect(step);
	end;
	local row = Sections.Starfall:AddLabel("Starfall");
	row:AddToggle({ Default = false, Flag = "starfall", Callback = function(v) S.On = v == true; if S.On then start() else stop() end end });
	row:AddColorPicker({ Default = S.Head, Flag = "starfall_head", Callback = function(v) S.Head = v end });
	Sections.Starfall:AddLabel("Shower Preset"):AddDropdown({
		Default = "Perseids", Values = PRESETS, Flag = "starfall_preset",
		Callback = function(v) S.Preset = table.find(PRESETS, v) and v or "Perseids" end,
	});
	Sections.Starfall:AddLabel("Max Stars"):AddSlider({
		Min = 1, Max = MAX, Default = 20, Rounding = 0, Size = 100, Flag = "starfall_count",
		Callback = function(v) S.Count = F.Number(v, 20, 1, MAX) end,
	});
	Sections.Starfall:AddLabel("Spawn Rate"):AddSlider({
		Min = 2, Max = 600, Default = 150, Rounding = 0, Type = "/min", Size = 100, Flag = "starfall_rate",
		Callback = function(v) S.Rate = F.Number(v, 150, 2, 600); due = 0 end,
	});
	local more = row:AddOption(1);
	more:AddLabel("Tail Color"):AddColorPicker({ Default = S.Tail, Flag = "starfall_tail", Callback = function(v) S.Tail = v end });
	for _, setting in ipairs({
		{ "Travel Speed", "starfall_speed", 20, 250, 100, "%", function(v) S.Speed = F.Number(v, 100, 20, 250) end },
		{ "Tail Length", "starfall_length", 20, 260, 100, "%", function(v) S.Length = F.Number(v, 100, 20, 260) end },
		{ "Size", "starfall_size", 20, 250, 100, "%", function(v) S.Size = F.Number(v, 100, 20, 250) end },
		{ "Lifetime", "starfall_life", 1, 12, 4, "s", function(v) S.Life = F.Number(v, 4, 1, 12) end },
		{ "Sky Distance", "starfall_distance", 100, 500, 260, "", function(v) S.Distance = F.Number(v, 260, 100, 500) end },
	}) do
		more:AddLabel(setting[1]):AddSlider({ Min = setting[3], Max = setting[4], Default = setting[5], Type = setting[6],
			Rounding = 0, Size = 100, Flag = setting[2], Callback = setting[7] });
	end;
	more:AddLabel("Bright Meteors"):AddToggle({ Default = true, Flag = "starfall_fireballs", Callback = function(v) S.Fireballs = v end });
	more:AddLabel("Star Heads"):AddToggle({ Default = true, Flag = "starfall_stars", Callback = function(v) S.Stars = v end });
	more:AddLabel("Head Size"):AddSlider({ Min = 3, Max = 64, Default = 14, Rounding = 0, Type = "px", Size = 100,
		Flag = "starfall_head_size", Callback = function(v) S.HeadSize = F.Number(v, 14, 3, 64) end });
	ESP.ClearStarfall = onUnload("starfall", function()
		S.On = false; stop();
		if sky then sky:Destroy(); sky = nil end;
		table.clear(slots); S.Allocated = 0;
	end);
end;
