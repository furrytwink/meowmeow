--!nonstrict
--[[
	bullet_tracers.lua — extracted feature module (require id "modules.bullet_tracers").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("bullet tracers") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("bullet tracers", function()
			return require("modules.bullet_tracers")({ ESP = ESP, LocalPlayer = LocalPlayer, NeverLose = NeverLose, Remote = Remote, Sections = Sections, onUnload = onUnload, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local Remote = ctx.Remote;
	local Sections = ctx.Sections;
	local onUnload = ctx.onUnload;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("bullet tracers") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local ReplicatedStorage = game:GetService("ReplicatedStorage");
	local TweenService = game:GetService("TweenService");
	local Debris = game:GetService("Debris");

	local B = {
		On = false,
		Color = Color3.fromRGB(133, 220, 255),
		Duration = 1,
		Style = "Classic",
	};

	local TRACER_STYLES = {
		Classic = { fallback = "rbxassetid://12781800668", speed = 1.5, length = 2, width = 0.25, brightness = 2.5 },
		Bloom = { path = "trail/bloom.png", fallback = "rbxassetid://12781800668", speed = 1.2, length = 2.6, width = 0.3, brightness = 2.8 },
		Comet = { path = "particles/comet_bloom.png", fallback = "rbxassetid://12781800668", speed = 1.8, length = 2.4, width = 0.26, brightness = 3 },
		Lightning = { path = "particles/p_lightning.png", fallback = "rbxassetid://12781800668", speed = 2.6, length = 1.4, width = 0.18, brightness = 3.2 },
		Sparkle = { path = "particles/p_sparkle.png", fallback = "rbxassetid://12781800668", speed = 1.9, length = 1.8, width = 0.22, brightness = 2.7 },
		SoftGlow = { path = "particles/p_softglow.png", fallback = "rbxassetid://12781800668", speed = 1, length = 2.2, width = 0.34, brightness = 2.4 },
	};
	local tracerTextures = { Classic = TRACER_STYLES.Classic.fallback };

	local function warmTracerStyle(name)
		local style = TRACER_STYLES[name];
		if not style or not style.path or tracerTextures[name] then return end;
		task.spawn(function()
			local asset = Remote.asset(style.path);
			if __ALIVE() and type(asset) == "string" and asset ~= "" then tracerTextures[name] = asset end;
		end);
	end;

	local gunFiredConn, gunFiredRemote, roundClient;
	local live = {};

	local FADE = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out);

	local function getRoundClient()
		local ok, module = pcall(function()
			return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"));
		end);

		if ok then roundClient = module end;

		return roundClient;
	end;

	local function isLocalSheriff()
		local character = LocalPlayer.Character;

		if character and character:FindFirstChild("Gun") then return true end;

		local backpack = LocalPlayer:FindFirstChildOfClass("Backpack");

		if backpack and backpack:FindFirstChild("Gun") then return true end;

		local round = getRoundClient();

		if not round then return false end;

		local data = round.PlayerData;
		local mine = data and data[LocalPlayer.Name];

		return mine ~= nil and (mine.Role == "Sheriff" or mine.Role == "Hero");
	end;

	local function makePoint(position, lifetime)
		local part = Instance.new("Part");

		part.Name = NeverLose.RandomString();
		part.Transparency = 1;
		part.Anchored = true;
		part.CanCollide = false;
		part.CanQuery = false;
		part.Size = Vector3.new(1, 1, 1);
		part.CFrame = CFrame.new(position);

		local attachment = Instance.new("Attachment");

		attachment.Parent = part;

		Debris:AddItem(part, lifetime);

		part.Parent = workspace;
		live[part] = true;

		return part, attachment;
	end;

	local function toPosition(value)
		if typeof(value) == "Vector3" then
			return value;
		elseif typeof(value) == "CFrame" then
			return value.Position;
		elseif typeof(value) == "Instance" then
			if value:IsA("Attachment") then
				return value.WorldPosition;
			elseif value:IsA("BasePart") then
				return value.Position;
			end;
		end;
	end;

	local function createTracer(startValue, endValue)
		local startPosition = toPosition(startValue);
		local endPosition = toPosition(endValue);

		if not startPosition or not endPosition then return end;

		local duration = B.Duration or 1;
		local style = TRACER_STYLES[B.Style] or TRACER_STYLES.Classic;
		local startPart, startAttachment = makePoint(startPosition, duration + 0.5);
		local endPart, endAttachment = makePoint(endPosition, duration + 0.5);

		local beam = Instance.new("Beam");

		beam.Name = NeverLose.RandomString();
		beam.FaceCamera = true;
		beam.TextureSpeed = style.speed;
		beam.TextureLength = style.length;
		beam.Width0 = style.width;
		beam.Width1 = style.width;
		beam.LightEmission = 3;
		beam.LightInfluence = 0;
		beam.Brightness = style.brightness;
		beam.Texture = tracerTextures[B.Style] or style.fallback;
		beam.Color = ColorSequence.new(B.Color);
		beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.1) });
		beam.Attachment0 = startAttachment;
		beam.Attachment1 = endAttachment;
		beam.Parent = startPart;

		task.delay(duration, function()
			if beam.Parent then
				TweenService:Create(beam, FADE, { Width0 = 0, Width1 = 0 }):Play();
			end;
		end);

		task.delay(duration + 0.5, function()
			live[startPart], live[endPart] = nil, nil;
		end);
	end;

	local function onGunFired(gun, startValue, endValue)
		if not (__ALIVE() and B.On) then return end;

		local character = LocalPlayer.Character;

		if not character then return end;
		if not (typeof(gun) == "Instance" and gun:IsDescendantOf(character)) then return end;
		if not isLocalSheriff() then return end;

		createTracer(startValue, endValue);
	end;

	local function connectGunFired()
		local ok, remote = pcall(function()
			return ReplicatedStorage:WaitForChild("ClientServices"):WaitForChild("WeaponService"):WaitForChild("GunFired");
		end);

		if not ok or not remote or not __ALIVE() then return end;
		if gunFiredConn and gunFiredRemote == remote and gunFiredConn.Connected then return end;

		if gunFiredConn then
			pcall(function() gunFiredConn:Disconnect() end);

			gunFiredConn = nil;
		end;

		gunFiredRemote = remote;
		gunFiredConn = remote.OnClientEvent:Connect(function(gun, startValue, endValue)
			task.spawn(onGunFired, gun, startValue, endValue);
		end);
	end;

	task.spawn(function()
		while __ALIVE() do
			if B.On then pcall(connectGunFired) end;

			task.wait(1);
		end;
	end);

	local row = Sections.BulletTracer:AddLabel("Enabled");

	row:AddToggle({
		Default = false,
		Flag = "bullet_tracers",
		ToolTip = "Create a tracer line when you shoot",
		Callback = function(v)
			B.On = v == true;

			if B.On then task.spawn(connectGunFired) end;
		end,
	});

	row:AddColorPicker({
		Default = B.Color,
		Flag = "bullet_tracers_color",
		Callback = function(v) B.Color = v end,
	});

	Sections.BulletTracer:AddLabel("Style"):AddDropdown({
		Default = B.Style,
		Values = { "Classic", "Bloom", "Comet", "Lightning", "Sparkle", "SoftGlow" },
		Flag = "bullet_tracers_style",
		Callback = function(v)
			B.Style = TRACER_STYLES[v] and v or "Classic";
			warmTracerStyle(B.Style);
		end,
	});

	Sections.BulletTracer:AddLabel("Duration"):AddSlider({
		Min = 0.1, Max = 5, Default = 1, Rounding = 1, Size = 100,
		Flag = "bullet_tracers_lifetime",
		Callback = function(v) B.Duration = tonumber(v) or 1 end,
	});

	ESP.BulletTracers = B;
	ESP.ClearBulletTracers = onUnload("bullet tracers", function()
		B.On = false;

		if gunFiredConn then
			pcall(function() gunFiredConn:Disconnect() end);

			gunFiredConn = nil;
		end;

		for part in pairs(live) do
			pcall(function() part:Destroy() end);
		end;

		table.clear(live);
	end);
end;
