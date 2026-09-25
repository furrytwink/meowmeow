--!nonstrict
--[[
	gunchams.lua — extracted feature module (require id "modules.gunchams").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("gunchams") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("gunchams", function()
			return require("modules.gunchams")({ ESP = ESP, INIT_GENERATION = INIT_GENERATION, NeverLose = NeverLose, Players = Players, Remote = Remote, Render = Render, RunService = RunService, Sections = Sections, TAG = TAG, destroyAny = destroyAny, onUnload = onUnload, scanDescendantsAsync = scanDescendantsAsync, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local INIT_GENERATION = ctx.INIT_GENERATION;
	local NeverLose = ctx.NeverLose;
	local Players = ctx.Players;
	local Remote = ctx.Remote;
	local Render = ctx.Render;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local TAG = ctx.TAG;
	local destroyAny = ctx.destroyAny;
	local onUnload = ctx.onUnload;
	local scanDescendantsAsync = ctx.scanDescendantsAsync;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("gunchams") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local G = {
		On = false,
		Outline = Color3.fromRGB(255, 190, 60),
		Fill = 0.75,
		Aura = true,
		AuraType = "ForceField",
		AuraColor = Color3.fromRGB(255, 150, 40),
		AuraSpread = 1, AuraSize = 1, AuraSpeed = 1, AuraRate = 1, AuraOpacity = 0.75, AuraGlow = 2,
		Circle = false, CircleStyle = "Soft Ring", CircleColor = Color3.fromRGB(255, 190, 60),
		CircleSize = 4, CircleOpacity = 1, CircleGlow = 2, CircleHeight = 0.06,
		CircleRotation = 0, CircleGround = true, CircleThroughWalls = false,
		Text = true,
		TextColor = Color3.fromRGB(255, 220, 140),
	};

	ESP.GunChams = G;

	local candidates, live = {}, {};
	G.Live = live;
	G.AuraTypes = { "ForceField", "Neon", "Glass", "Metal", "Sparkle", "Fire", "Smoke" };
	local auraTextures = {
		Glow = "p_glow", Bloom = "p_bloom", Stars = "p_star", Sparks = "p_sparkle",
		Hearts = "p_heart", Snow = "p_snowflake", Lightning = "p_lightning",
		Petals = "p_petal1", Flowers = "p_flower1", Leaves = "p_leaf1",
		Bubbles = "p_bubble", Crown = "p_crown", Fireflies = "p_firefly", Flames = "p_flame3",
	};
	for _, name in ipairs({ "Glow", "Bloom", "Stars", "Sparks", "Hearts", "Snow", "Lightning",
		"Petals", "Flowers", "Leaves", "Bubbles", "Crown", "Fireflies", "Flames" }) do
		G.AuraTypes[#G.AuraTypes + 1] = name;
	end;
	local host = Render.gui("gunchams", -6);
	local shells = Instance.new("Folder");

	shells.Name = NeverLose.RandomString();
	shells.Parent = workspace.CurrentCamera;
	NeverLose:AddSignal(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if __ALIVE() then shells.Parent = workspace.CurrentCamera end;
	end));

	local conns = {};
	local frameConnection;
	local scanGeneration = 0;
	local sweep = 0;

	local function anchorPart(object)
		if object:IsA("BasePart") then return object end;
		if object:IsA("Model") then return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true) end;

		return object:FindFirstChild("Handle") or object:FindFirstChildWhichIsA("BasePart", true);
	end;

	local function ours(object)
		if object:GetAttribute("VisualsGunAura") or object:IsDescendantOf(shells) then return true end;
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character and object:IsDescendantOf(player.Character) then return true end;
		end;

		return false;
	end;

	local function watch(object)
		if object.Name ~= "GunDrop" or ours(object) then return end;
		if object:IsA("BasePart") or object:IsA("Model") or object:IsA("Tool") then
			candidates[object] = true;
		end;
	end;

	local function forget(object)
		if object.Name == "GunDrop" then candidates[object] = nil end;
	end;

	local function seed(token)
		table.clear(candidates);
		scanDescendantsAsync("gun chams scan", workspace, watch, function()
			return token == scanGeneration and (G.On or G.Circle);
		end, 512);
	end;

	local function restoreNativeAura(record)
		record.NativeActive = false;
		if record.NativeAdded then record.NativeAdded:Disconnect(); record.NativeAdded = nil end;
		for object, saved in pairs(record.Native or {}) do
			if saved.Connection then saved.Connection:Disconnect() end;
			if object.Parent then pcall(function() object[saved.Property] = saved.Value end) end;
		end;
		record.Native = nil;
	end;

	local function nativeAuraProperty(effect, part)
		if effect:GetAttribute("VisualsGunAura") then return nil end;
		if effect:IsA("ParticleEmitter") or effect:IsA("Beam") or effect:IsA("Trail")
			or effect:IsA("Sparkles") or effect:IsA("Fire") or effect:IsA("Smoke")
			or effect:IsA("Light") or effect:IsA("Highlight")
			or effect:IsA("BillboardGui") or effect:IsA("SurfaceGui") then return "Enabled", false end;
		if effect:IsA("BasePart") and effect ~= part then
			local c, name = effect.Color, effect.Name:lower();
			local green = c.G > c.R * 1.15 and c.G > c.B * 1.15;
			local auraName = name:find("aura", 1, true) or name:find("glow", 1, true) or name:find("ring", 1, true) or name:find("effect", 1, true);
			if green and (auraName or effect.Material == Enum.Material.Neon or effect.Material == Enum.Material.ForceField) then
				return "Transparency", 1;
			end;
		end;
	end;

	local function hideNativeAura(record, object, part, effect)
		if record.Native and record.Native[effect] then return end;
		local property, hidden = nativeAuraProperty(effect, part);
		if not property then return end;
		record.Native = record.Native or {};
		local saved = { Property = property, Value = effect[property] };
		record.Native[effect] = saved;
		saved.Connection = effect:GetPropertyChangedSignal(property):Connect(function()
			if not (record.NativeActive and G.On and G.Aura and effect.Parent and effect:IsDescendantOf(object)) then return end;
			if effect[property] ~= hidden then
				saved.Value = effect[property];
				effect[property] = hidden;
			end;
		end);
		effect[property] = hidden;
	end;

	local function suppressNativeAura(record, object, part)
		record.NativeActive = true;
		if not record.NativeAdded then
			record.NativeAdded = object.DescendantAdded:Connect(function(effect)
				if record.NativeActive then hideNativeAura(record, object, record.AuraPart or part, effect) end;
			end);
			record.NativeSweep = 0;
		end;
		local clock = os.clock();
		if clock < record.NativeSweep then return end;
		record.NativeSweep = clock + 0.25;
		for effect, saved in pairs(record.Native or {}) do
			if not effect.Parent or not effect:IsDescendantOf(object) then
				saved.Connection:Disconnect();
				if effect.Parent then pcall(function() effect[saved.Property] = saved.Value end) end;
				record.Native[effect] = nil;
			end;
		end;
		for _, effect in ipairs(object:GetDescendants()) do hideNativeAura(record, object, part, effect) end;
	end;

	local function clearCustomAura(record)
		if record.shell then record.shell:Destroy(); record.shell = nil end;
		if record.AuraEffect then record.AuraEffect:Destroy(); record.AuraEffect = nil end;
		record.AuraPart, record.AuraType = nil, nil;
		record.AuraSettings = nil;
	end;
	local function clearAura(record)
		clearCustomAura(record);
		restoreNativeAura(record);
	end;

	local function drop(object)
		local entry = live[object];

		if not entry then return end;

		live[object] = nil;

		if entry.glow then pcall(function() entry.glow:Destroy() end) end;
		clearAura(entry);
		if entry.Circle then entry.Circle.Part:Destroy(); entry.Circle = nil end;

		destroyAny(entry.label);
	end;

	local function clearAll()
		for object in pairs(live) do drop(object) end;
	end;

	local function makeShell(part)
		local archivable = part.Archivable;

		if not archivable and not pcall(function() part.Archivable = true end) then return nil end;

		local ok, clone = pcall(part.Clone, part);

		if not archivable then pcall(function() part.Archivable = archivable end) end;
		if not ok or not clone then return nil end;

		for _, child in ipairs(clone:GetChildren()) do
			if not child:IsA("DataModelMesh") then child:Destroy() end;
		end;

		local mesh = clone:FindFirstChildWhichIsA("DataModelMesh");

		if mesh then
			pcall(function() mesh.TextureId = "" end);
		end;

		pcall(function() clone.TextureID = "" end);
		clone.Name = "VisualsGunAuraShell";
		clone:SetAttribute(TAG, INIT_GENERATION);
		clone.MaterialVariant = "";
		clone:SetAttribute("VisualsGunAura", true);
		clone.Anchored = true;
		clone.CanCollide = false;
		clone.CanQuery = false;
		clone.CanTouch = false;
		clone.CastShadow = false;
		clone.Massless = true;

		return clone;
	end;

	local function updateAura(record, object, part, visible)
		if not G.Aura then clearAura(record); return end;
		if visible == false then

			clearCustomAura(record);
			suppressNativeAura(record, object, part);
			return;
		end;
		local kind = table.find(G.AuraTypes, G.AuraType) and G.AuraType or "ForceField";
		local node = record.shell or record.AuraEffect;
		if record.AuraType ~= kind or record.AuraPart ~= part or not node or not node.Parent then
			clearCustomAura(record);
			local ok, effect = pcall(function()
				if auraTextures[kind] then
					local attach = Instance.new("Attachment");
					attach:SetAttribute("VisualsGunAura", true);
					local emitter = Instance.new("ParticleEmitter");
					emitter:SetAttribute("VisualsGunAura", true);
					emitter.Enabled = false;
					emitter.LightEmission, emitter.LightInfluence = 1, 0;
					emitter.Lifetime = NumberRange.new(0.6, 1.2);
					emitter.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.25),
						NumberSequenceKeypoint.new(0.7, 0.4), NumberSequenceKeypoint.new(1, 1),
					});
					emitter.Parent, attach.Parent = attach, part;
					task.defer(function()
						local url = Remote.id(Remote.file("particles/" .. auraTextures[kind] .. ".png"));
						if __ALIVE() and live[object] == record and record.AuraEffect == attach and attach.Parent and url then
							emitter.Texture, emitter.Enabled = url, G.On and G.Aura;
						end;
					end);
					return attach;
				end;
				if kind == "Sparkle" or kind == "Fire" or kind == "Smoke" then
					local effect = Instance.new(kind == "Sparkle" and "Sparkles" or kind);
					effect:SetAttribute("VisualsGunAura", true);
					if kind == "Fire" then effect.Size, effect.Heat = 1.2, 0.3 end;
					if kind == "Smoke" then effect.Size, effect.Opacity, effect.RiseVelocity = 0.75, 0.12, 0.4 end;
					effect.Parent = part;
					return effect;
				end;
				local shell = makeShell(part);
				if shell then shell.Parent = shells end;
				return shell;
			end);
			if not ok or not effect then restoreNativeAura(record); return end;
			if effect:IsA("BasePart") then record.shell = effect else record.AuraEffect = effect end;
			record.AuraType, record.AuraPart = kind, part;
		end;
		if record.shell then
			local shell = record.shell;
			local mesh = shell:FindFirstChildWhichIsA("DataModelMesh");
			local sourceMesh = part:FindFirstChildWhichIsA("DataModelMesh");
			local factor = (1 + 0.08 * G.AuraSpread) * G.AuraSize;
			if mesh and sourceMesh then mesh.Scale = sourceMesh.Scale * factor;
			else shell.Size = part.Size * factor end;
			shell.CFrame, shell.Color = part.CFrame, G.AuraColor;
			shell.Material = Enum.Material[kind];
			shell.Reflectance = kind == "Metal" and 0.3 or kind == "Glass" and 0.12 or 0;
			shell.Transparency = 1 - G.AuraOpacity;
			shell.LocalTransparencyModifier = 0;
		elseif auraTextures[kind] then
			local emitter = record.AuraEffect:FindFirstChildOfClass("ParticleEmitter");
			local settings = { G.AuraColor, G.AuraSpread, G.AuraSpeed, G.AuraSize, G.AuraRate, G.AuraGlow, G.AuraOpacity };
			local changed = not record.AuraSettings;
			for i, value in ipairs(settings) do if not record.AuraSettings or value ~= record.AuraSettings[i] then changed = true end end;
			if emitter and changed then
				record.AuraSettings = settings;
				emitter.Color = ColorSequence.new(G.AuraColor);
				emitter.Speed = NumberRange.new(0.15 * G.AuraSpread * G.AuraSpeed, 1.5 * G.AuraSpread * G.AuraSpeed);
				emitter.SpreadAngle = Vector2.new(180, 180);
				emitter.Size = NumberSequence.new(0.3 * G.AuraSize);
				emitter.Rate, emitter.Brightness = 24 * G.AuraRate, G.AuraGlow;
				emitter.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 1 - G.AuraOpacity),
					NumberSequenceKeypoint.new(0.7, 1 - G.AuraOpacity * 0.6), NumberSequenceKeypoint.new(1, 1),
				});
			end;
		elseif kind == "Sparkle" then record.AuraEffect.SparkleColor = G.AuraColor;
		elseif kind == "Fire" then
			record.AuraEffect.Size, record.AuraEffect.Heat = 1.2 * G.AuraSize * G.AuraSpread, 0.3 * G.AuraSpeed;
			record.AuraEffect.Color = G.AuraColor;
			record.AuraEffect.SecondaryColor = G.AuraColor:Lerp(Color3.new(1, 1, 1), 0.35);
		else
			record.AuraEffect.Color = G.AuraColor;
			record.AuraEffect.Size = 0.75 * G.AuraSize * G.AuraSpread;
			record.AuraEffect.Opacity, record.AuraEffect.RiseVelocity = 0.2 * G.AuraOpacity, 0.4 * G.AuraSpeed;
		end;
		suppressNativeAura(record, object, part);
	end;

	local function found()
		local list = {};

		for object in pairs(candidates) do
			if object.Name == "GunDrop" and object.Parent and not ours(object) then
				local part = anchorPart(object);

				if part then
					list[#list + 1] = {
						object = object,
						part = part,
						adorn = (object:IsA("BasePart") or object:IsA("Model")) and object or part,
					};
				end;
			end;
		end;

		return list;
	end;

	local guns = {};

	local function step(dt)
		if not (__ALIVE() and (G.On or G.Circle)) then
			if next(live) then clearAll() end;

			return;
		end;

		sweep = sweep + dt;

		if sweep >= 0.25 then
			sweep = 0;
			guns = found();

			local seen = {};

			for _, entry in ipairs(guns) do seen[entry.object] = true end;
			for object in pairs(live) do
				if not seen[object] then drop(object) end;
			end;
		end;

		local camera = Render.camera();

		if not camera then return end;

		for _, entry in ipairs(guns) do
			local object, part = entry.object, entry.part;

			if not (object.Parent and part and part.Parent) then
				drop(object);
			else
				local record = live[object];
				local visible = true;

				if not record then record = {}; live[object] = record end;

				if not record.glow then
					local glow = Instance.new("Highlight");

					glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop;
					glow.Parent = host;

					record.glow = glow;
				end;

				record.glow.Adornee = entry.adorn;
				record.glow.OutlineColor = G.Outline;
				record.glow.OutlineTransparency = 0;
				record.glow.FillColor = G.Outline;
				record.glow.FillTransparency = math.clamp(G.Fill, 0, 1);
				record.glow.Enabled = G.On and visible;

				if G.On then updateAura(record, object, part, visible) else clearAura(record) end;
				if G.Circle and ESP.StaticGunCircle then
					ESP.StaticGunCircle(record, object, part, dt);
				elseif record.Circle then record.Circle.Part:Destroy(); record.Circle = nil end;

				if G.On and G.Text then
					if not record.label then
						local text = Drawing.new("Text");

						text.Center = true;
						text.Outline = true;
						text.Size = 13;
						text.Font = 2;

						record.label = text;
					end;

					local at, onScreen = camera:WorldToViewportPoint(part.Position);

					if visible and onScreen and at.Z > 0 then
						record.label.Text = "Gun";
						record.label.Color = G.TextColor;
						record.label.Position = Vector2.new(at.X, at.Y);
						record.label.Visible = true;
					else
						record.label.Visible = false;
					end;
				elseif record.label then
					record.label.Visible = false;
				end;
			end;
		end;
	end;

	local function start()
		if conns[1] then return end;
		scanGeneration += 1;
		local token = scanGeneration;
		sweep = 0.25;
		conns[#conns + 1] = workspace.DescendantAdded:Connect(watch);
		conns[#conns + 1] = workspace.DescendantRemoving:Connect(forget);
		frameConnection = RunService.RenderStepped:Connect(step);
		seed(token);
	end;

	local function stop()
		scanGeneration += 1;
		for _, conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end;
		if frameConnection then pcall(function() frameConnection:Disconnect() end); frameConnection = nil end;
		table.clear(conns);
		table.clear(candidates);

		guns = {};

		clearAll();
	end;
	G.SetTracking = function() if G.On or G.Circle then start() else stop() end end;

	local row = Sections.Guns:AddLabel("Dropped Gun");

	row:AddToggle({
		Name = "Dropped Gun",
		Default = false,
		Flag = "gun_chams",
		Callback = function(v)
			G.On = v;

			G.SetTracking();
		end,
	});

	row:AddColorPicker({
		Default = G.Outline,
		Flag = "gun_chams_color",
		Callback = function(v) G.Outline = v end,
	});

	Sections.Guns:AddLabel("Fill"):AddSlider({
		Min = 0, Max = 100, Default = 75, Rounding = 0, Size = 100, Type = "%",
		Flag = "gun_chams_fill",
		Callback = function(v) G.Fill = v / 100 end,
	});

	local auraRow = Sections.Guns:AddLabel("Aura");

	auraRow:AddToggle({
		Name = "Aura",
		Default = true,
		Flag = "gun_chams_aura",
		Callback = function(v)
			G.Aura = v;
			if not v then for _, record in pairs(live) do clearAura(record) end end;
		end,
	});

	auraRow:AddColorPicker({
		Default = G.AuraColor,
		Flag = "gun_chams_aura_color",
		Callback = function(v) G.AuraColor = v end,
	});
	local auraOptions = auraRow:AddOption(1);
	auraOptions:AddLabel("Style"):AddDropdown({
		Default = "ForceField", Values = G.AuraTypes, Flag = "gun_chams_aura_type",
		Callback = function(v) G.AuraType = table.find(G.AuraTypes, v) and v or "ForceField" end,
	});
	for _, setting in ipairs({
		{ "Spread", "AuraSpread", "spread", 0, 800, 100 },
		{ "Size", "AuraSize", "size", 10, 500, 100 },
		{ "Speed", "AuraSpeed", "speed", 0, 500, 100 },
		{ "Rate", "AuraRate", "rate", 0, 400, 100 },
		{ "Opacity", "AuraOpacity", "opacity", 0, 100, 75 },
		{ "Glow", "AuraGlow", "glow", 0, 600, 200 },
	}) do
		local key = setting[2];
		auraOptions:AddLabel(setting[1]):AddSlider({
			Min = setting[4], Max = setting[5], Default = setting[6], Rounding = 0,
			Flag = "gun_chams_aura_" .. setting[3], Callback = function(v) G[key] = v / 100 end,
		});
	end;

	local textRow = Sections.Guns:AddLabel("Label");

	textRow:AddToggle({
		Name = "Label",
		Default = true,
		Flag = "gun_chams_text",
		Callback = function(v) G.Text = v end,
	});

	textRow:AddColorPicker({
		Default = G.TextColor,
		Flag = "gun_chams_text_color",
		Callback = function(v) G.TextColor = v end,
	});

	ESP.ClearGunChams = onUnload("gunchams", function()
		G.On = false;
		G.Circle = false;

		stop();

		pcall(function() shells:Destroy() end);
	end);
end;
