--!nonstrict
--[[
	weather.lua — extracted feature module (require id "modules.weather").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("weather") in the driver — byte-frozen original
	code below the marker (re-derived on every `make extract`; do not hand-edit).

	The block originally closed over driver locals; the driver now passes them
	in via the ctx table:

		guard("weather", function()
			return require("modules.weather")({ ESP = ESP, INIT_GENERATION = INIT_GENERATION, NeverLose = NeverLose, Render = Render, RunService = RunService, Sections = Sections, TAG = TAG });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local INIT_GENERATION = ctx.INIT_GENERATION;
	local NeverLose = ctx.NeverLose;
	local Render = ctx.Render;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local TAG = ctx.TAG;

-- [ guard("weather") callback body — byte-exact from input/message(47).txt ]
	local SOFT = "rbxasset://textures/particles/smoke_main.dds";
	local DOT = "rbxassetid://241876428";

	for _, leftover in ipairs(workspace:GetChildren()) do
		local owner = leftover:GetAttribute(TAG);
		if owner and owner ~= INIT_GENERATION and leftover:FindFirstChildWhichIsA("ParticleEmitter") then
			leftover:Destroy();
		end;
	end;

	local TYPES = {
		Snow = {

			texture = DOT,
			color = Color3.fromRGB(226, 240, 255),
			lifetime = NumberRange.new(4, 6),
			speed = NumberRange.new(6, 12),
			acceleration = Vector3.new(2, -6, 1),
			spread = Vector2.new(35, 35),
			spin = NumberRange.new(-40, 40),
			size = 0.16,
			squash = 0,
			emission = 0.15,
			transparency = { 0.1, 0.2 },
			fade = 0.8,
		},
		["Snow Soft"] = {

			color = Color3.fromRGB(150, 200, 255),
			lifetime = NumberRange.new(4, 6),
			speed = NumberRange.new(6, 12),
			acceleration = Vector3.new(2, -6, 1),
			spread = Vector2.new(35, 35),
			spin = NumberRange.new(-40, 40),
			size = 0.55,
			squash = 0,
			emission = 0.4,
			transparency = { 0.2, 0.3 },
			fade = 0.8,
		},
		Sakura = {
			color = Color3.fromRGB(255, 170, 210),
			lifetime = NumberRange.new(5, 7),
			speed = NumberRange.new(5, 10),
			acceleration = Vector3.new(4, -5, 2),
			spread = Vector2.new(40, 40),
			spin = NumberRange.new(-80, 80),
			size = 0.5,
			squash = 1.4,
			emission = 0.4,
			transparency = { 0.15, 0.25 },
			fade = 0.85,
		},
		Rain = {
			color = Color3.fromRGB(170, 200, 255),
			lifetime = NumberRange.new(1.1, 1.6),
			speed = NumberRange.new(70, 95),
			acceleration = Vector3.new(0, -40, 0),

			spread = Vector2.new(2, 2),
			spin = NumberRange.new(0, 0),
			size = 0.28,
			squash = 9,
			emission = 0.2,
			transparency = { 0.35, 0.45 },
			fade = 0.9,

			orientation = Enum.ParticleOrientation.VelocityParallel,
			rotation = NumberRange.new(0, 0),
			lean = Vector3.new(6, 0, 4),
		},
		Ash = {
			color = Color3.fromRGB(90, 90, 95),
			lifetime = NumberRange.new(6, 9),
			speed = NumberRange.new(3, 7),
			acceleration = Vector3.new(3, -3, 2),
			spread = Vector2.new(45, 45),
			spin = NumberRange.new(-25, 25),
			size = 0.32,
			squash = 0,
			emission = 0.1,
			transparency = { 0.25, 0.4 },
			fade = 0.85,
		},
		Fireflies = {
			color = Color3.fromRGB(255, 220, 120),
			lifetime = NumberRange.new(3, 5),
			speed = NumberRange.new(1, 3),
			acceleration = Vector3.new(0, 0.5, 0),
			spread = Vector2.new(180, 180),
			spin = NumberRange.new(-10, 10),
			size = 0.22,
			squash = 0,
			emission = 1,
			transparency = { 0.1, 0.1 },
			fade = 0.75,
		},
	};

	local W = {
		Kind = "Off",
		Rate = 250,
		Speed = 100,
		Size = 100,
		Fade = 100,
		Distance = 260,
		Height = 140,
		Color = TYPES.Snow.color,
		ThroughWalls = false,
	};

	local part, emitter, conn, lastPos, lastLook;

	local colorNow, colorTarget = W.Color, W.Color;

	local function easeColour(target)
		colorTarget = target;
	end;

	local function stepColour()
		if not emitter then return end;

		local dr, dg, db = colorNow.R - colorTarget.R, colorNow.G - colorTarget.G, colorNow.B - colorTarget.B;

		if dr * dr + dg * dg + db * db < 0.00002 then
			if colorNow ~= colorTarget then
				colorNow = colorTarget;
				emitter.Color = ColorSequence.new(colorNow);
			end;

			return;
		end;

		colorNow = colorNow:Lerp(colorTarget, 0.09);
		emitter.Color = ColorSequence.new(colorNow);
	end;

	local function style()
		local preset = TYPES[W.Kind];
		if not (emitter and preset) then return end;

		local scale = W.Speed / 100;

		emitter.Texture = preset.texture or SOFT;
		emitter.LightInfluence = 0;
		emitter.LightEmission = preset.emission;
		Render.FxDepth(emitter, W.ThroughWalls);
		emitter.Drag = 0;
		emitter.EmissionDirection = Enum.NormalId.Bottom;
		emitter.Rate = W.Rate;
		emitter.Color = ColorSequence.new(colorNow);

		emitter.Rotation = preset.rotation or NumberRange.new(0, 360);
		emitter.RotSpeed = preset.spin;
		emitter.SpreadAngle = preset.spread;

		pcall(function()
			emitter.Orientation = preset.orientation or Enum.ParticleOrientation.FacingCamera;
		end);

		emitter.Speed = NumberRange.new(preset.speed.Min * scale, preset.speed.Max * scale);
		emitter.Acceleration = (preset.acceleration + (preset.lean or Vector3.zero)) * scale;

		emitter.Lifetime = NumberRange.new(preset.lifetime.Min / scale, preset.lifetime.Max / scale);
		emitter.Size = NumberSequence.new(preset.size * (W.Size / 100));

		pcall(function() emitter.Squash = NumberSequence.new(preset.squash) end);

		local ghost = W.Fade / 100;
		local head = math.clamp(1 - (1 - preset.transparency[1]) / ghost, 0, 1);
		local tail = math.clamp(1 - (1 - preset.transparency[2]) / ghost, 0, 1);

		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, head),
			NumberSequenceKeypoint.new(preset.fade, tail),
			NumberSequenceKeypoint.new(1, 1),
		});
	end;

	local function resize()
		if not part then return end;

		part.Size = Vector3.new(W.Distance, W.Height, W.Distance);
		lastPos, lastLook = nil, nil;
	end;

	local function stop()
		if conn then pcall(function() conn:Disconnect() end) conn = nil end;
		if part then pcall(function() part:Destroy() end) part = nil end;

		emitter, lastPos, lastLook = nil, nil, nil;
	end;

	local function ensurePart()
		if part and part.Parent then return end;

		part = Instance.new("Part");
		part.Name = NeverLose.RandomString();
		part.Anchored = true;
		part.CanCollide = false;
		part.CanQuery = false;
		part.CanTouch = false;
		part.CastShadow = false;
		part.Transparency = 1;
		part.Size = Vector3.new(W.Distance, W.Height, W.Distance);
		part:SetAttribute(TAG, INIT_GENERATION);
		part.Parent = workspace;

		emitter = Instance.new("ParticleEmitter");

		pcall(function()
			emitter.Shape = Enum.ParticleEmitterShape.Box;
			emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume;
		end);

		emitter.Parent = part;

		style();
	end;

	local function burst()
		if not emitter then return end;

		emitter:Emit(math.clamp(math.floor(W.Rate * 0.16), 30, 140));
	end;

	local function start()
		ensurePart();

		if conn then return end;

		lastPos, lastLook = nil, nil;

		conn = NeverLose:AddSignal(RunService.RenderStepped:Connect(function()
			if not (part and part.Parent) then return end;

			stepColour();

			local camera = workspace.CurrentCamera;
			if not camera then return end;

			local cf = camera.CFrame;
			local at = cf.Position;
			local look = cf.LookVector;
			local flat = Vector3.new(look.X, 0, look.Z);

			if flat.Magnitude < 0.05 then
				flat = Vector3.new(0, 0, -1);
			else
				flat = flat.Unit;
			end;

			if lastPos and lastLook and (at - lastPos).Magnitude < 10 and flat:Dot(lastLook) > 0.95 then return end;

			lastPos, lastLook = at, flat;
			part.CFrame = CFrame.new(at + flat * (W.Distance * 0.22) + Vector3.new(0, W.Height * 0.5 - 26, 0));
		end));

		burst();
	end;

	ESP.Weather = W;
	ESP.ClearWeather = stop;

	local colorPicker;

	Sections.Weather:AddLabel("Type"):AddDropdown({
		Default = "Off",
		Values = { "Off", "Snow", "Snow Soft", "Sakura", "Rain", "Ash", "Fireflies" },
		Flag = "weather_kind",
		Callback = function(v)
			W.Kind = v;

			if v == "Off" then
				stop();
				return;
			end;

			W.Color = TYPES[v].color;
			easeColour(W.Custom and W.Pick or W.Color);

			start();
			style();
			burst();
		end,
	});

	Sections.Weather:AddLabel("Amount"):AddSlider({
		Min = 20, Max = 800, Default = 250, Rounding = 0, Size = 100,
		Flag = "weather_rate",
		Callback = function(v)
			W.Rate = v;

			if emitter then emitter.Rate = v end;
		end,
	});

	Sections.Weather:AddLabel("Fall Speed"):AddSlider({
		Min = 10, Max = 400, Default = 100, Type = "%", Size = 100,
		Flag = "weather_speed",
		Callback = function(v) W.Speed = v; style() end,
	});

	Sections.Weather:AddLabel("Particle Size"):AddSlider({
		Min = 10, Max = 500, Default = 100, Type = "%", Size = 100,
		Flag = "weather_size",
		Callback = function(v) W.Size = v; style() end,
	});

	Sections.Weather:AddLabel("Transparency"):AddSlider({
		Min = 20, Max = 400, Default = 100, Type = "%", Size = 100,
		Flag = "weather_fade",
		Callback = function(v) W.Fade = v; style() end,
	});

	Sections.Weather:AddLabel("Distance"):AddSlider({
		Min = 60, Max = 600, Default = 260, Rounding = 0, Size = 100,
		Flag = "weather_distance",
		Callback = function(v) W.Distance = v; resize() end,
	});

	Sections.Weather:AddLabel("Height"):AddSlider({
		Min = 40, Max = 400, Default = 140, Rounding = 0, Size = 100,
		Flag = "weather_height",
		Callback = function(v) W.Height = v; resize() end,
	});

	local custom = Sections.Weather:AddLabel("Custom Color");
	custom:AddToggle({
		Default = false, Flag = "weather_custom",
		Callback = function(v)
			W.Custom = v;
			easeColour(v and W.Pick or W.Color);
		end,
	});
	colorPicker = custom:AddColorPicker({
		Default = W.Color,
		Flag = "weather_color",
		Callback = function(v)
			W.Pick = v;
			if W.Custom then easeColour(v) end;
		end,
	});

	Sections.Weather:AddButton({
		Icon = "arrow-rotate-right",
		Name = "Burst",
		Callback = burst,
	});
end;
