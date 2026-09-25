--!nonstrict
--[[
	aura.lua — extracted feature module (require id "modules.aura").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("aura") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("aura", function()
			return require("modules.aura")({ ESP = ESP, LocalPlayer = LocalPlayer, NeverLose = NeverLose, Preview = Preview, Remote = Remote, Render = Render, RunService = RunService, Sections = Sections, Visuals = Visuals, onUnload = onUnload, recordError = recordError, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local Preview = ctx.Preview;
	local Remote = ctx.Remote;
	local Render = ctx.Render;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local Visuals = ctx.Visuals;
	local onUnload = ctx.onUnload;
	local recordError = ctx.recordError;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("aura") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]

	local ORDER = {
		"Angelic", "Ambient", "Nimb", "Tornado", "Comet",
		"Angel", "Starlight", "Heavenly", "Ribbon", "Sakura", "Wind", "Flow", "Star",
	};

	local CATALOGUE = {
		Angel = "97658130917593",
		Starlight = "134645216613107",
		Heavenly = "139300897520961",
		Ribbon = "132069507632161",
		Sakura = "81755778619404",
		Wind = "80694081850877",
		Flow = "119913533725648",
		Star = "73754563740680",
	};

	local GROUPS = {
		{ "Head" },
		{ "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart" },
		{ "Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand" },
		{ "Right Arm", "RightUpperArm", "RightLowerArm", "RightHand" },
		{ "Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" },
		{ "Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot" },
	};

	local GROUP_OF = {};

	for _, names in ipairs(GROUPS) do
		for _, name in ipairs(names) do GROUP_OF[name] = names end;
	end;

	local A = {
		On = false,
		Color = Color3.fromRGB(133, 220, 255),
		Types = {},
		Type = "Angelic",
		Target = "Self",
		Glow = 2,
		Rate = 1,
		Size = 1,
		Tint = true,
		Speed = 1, Radius = 0.55, TrailLength = 100, TrailStep = 1.5, BloomSize = 150,
		LoadErrors = {}, ReadyTypes = {},
	};

	ESP.Aura = A;

	local function newBank(color)
		return { attachments = {}, borrowed = {}, particles = {}, accents = {}, color = color or A.Color };
	end;

	local mine = newBank();
	local sink = mine;
	local charConnection = nil;
	local auraGeneration = 0;

	local function clearBank(bank)
		for i = 1, #bank.attachments do
			if bank.attachments[i] and bank.attachments[i].Parent then
				bank.attachments[i]:Destroy();
			end;
		end;

		for i = 1, #bank.borrowed do
			if bank.borrowed[i] and bank.borrowed[i].Parent then
				pcall(function() bank.borrowed[i]:Destroy() end);
			end;
		end;

		bank.attachments, bank.borrowed, bank.particles, bank.accents = {}, {}, {}, {};
	end;

	local function clearAll()
		clearBank(mine);
		table.clear(A.ReadyTypes);
	end;

	local function keep(emitter, attachment)
		emitter.Parent = attachment;
		Render.FxDepth(emitter, false);

		sink.particles[#sink.particles + 1] = {
			emitter = emitter,
			rate = emitter.Rate,
			bright = emitter.Brightness,
			size = emitter.Size,
			color = emitter.Color, speed = emitter.Speed, rotation = emitter.RotSpeed,
			life = emitter.Lifetime, emission = emitter.LightEmission,
		};

		return emitter;
	end;

	local function scaleSequence(sequence, factor)
		if factor == 1 then return sequence end;

		local points = {};

		for index, key in ipairs(sequence.Keypoints) do
			points[index] = NumberSequenceKeypoint.new(key.Time, key.Value * factor, key.Envelope * factor);
		end;

		return NumberSequence.new(points);
	end;

	local guests = {};

	local function tuneBank(bank)
		local colour = bank.color;

		for _, record in ipairs(bank.particles) do
			local emitter = record.emitter;

			if emitter.Parent then
				Render.FxDepth(emitter, false);
				emitter.Color = A.Tint and ColorSequence.new(colour) or record.color;
				emitter.Rate = record.rate * A.Rate;
				emitter.Brightness = record.bright * A.Glow * 0.5;
				emitter.Size = scaleSequence(record.size, A.Size);
				local speed = math.clamp(A.Speed, 0.05, 5);
				emitter.Speed = NumberRange.new(record.speed.Min * speed, record.speed.Max * speed);
				emitter.RotSpeed = NumberRange.new(record.rotation.Min * speed, record.rotation.Max * speed);
				emitter.Lifetime = NumberRange.new(math.max(0.05, record.life.Min / speed), math.max(0.06, record.life.Max / speed));
				emitter.LightEmission = math.clamp(record.emission + (A.Glow * 0.5 - 1) * 0.5, 0, 1);
			end;
		end;

		for _, record in ipairs(bank.accents) do
			local item = record.item;
			if item.Parent then
				Render.FxDepth(item, false);
				pcall(function()
					if item:IsA("PointLight") or item:IsA("SpotLight") or item:IsA("SurfaceLight") then
						item.Color = A.Tint and colour or record.color;
						item.Brightness = record.brightness * A.Glow * 0.5;
					elseif item:IsA("Beam") or item:IsA("Trail") then
						item.Color = A.Tint and ColorSequence.new(colour) or record.color;
					end;
				end);
			end;
		end;
	end;

	local function tune()
		mine.color = A.Color;
		tuneBank(mine);

		for _, bank in pairs(guests) do tuneBank(bank) end;

		if ESP.GameFX then
			ESP.GameFX.Tune("aura", {
				glow = A.Glow * 0.5, rate = A.Rate, size = A.Size, speed = A.Speed,
			});
		end;
	end;

	local function part(character, ...)
		for _, name in ipairs({ ... }) do
			local found = character:FindFirstChild(name);

			if found then return found end;
		end;

		return nil;
	end;

	local function anchor(host, cframe)
		local attachment = Instance.new("Attachment");

		attachment.CFrame = cframe;
		attachment.Parent = host;

		sink.attachments[#sink.attachments + 1] = attachment;

		return attachment;
	end;

	local function createAngelic(character)
		local torso = part(character, "Torso", "UpperTorso");

		if not torso then return end;

		local left = anchor(torso, CFrame.new(-1.012, 0.5, 0.852, 0.966, 0, 0.259, 0, 1, 0, -0.259, 0, 0.966));
		local wingL = Instance.new("ParticleEmitter");
		wingL.Lifetime = NumberRange.new(1, 1);
		wingL.LockedToPart = true;
		wingL.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.944),
			NumberSequenceKeypoint.new(0.2, 0),
			NumberSequenceKeypoint.new(0.8, 0),
			NumberSequenceKeypoint.new(1, 1),
		});
		wingL.LightEmission = 1;
		wingL.Color = ColorSequence.new(A.Color);
		wingL.Speed = NumberRange.new(0.05, 0.05);
		wingL.Size = NumberSequence.new(2.75, 3.5);
		wingL.Rate = 4;
		wingL.Texture = "rbxassetid://13267054240";
		wingL.EmissionDirection = Enum.NormalId.Back;
		wingL.Orientation = Enum.ParticleOrientation.VelocityPerpendicular;
		wingL.Rotation = NumberRange.new(-15, -15);
		keep(wingL, left);

		local right = anchor(torso, CFrame.new(1.167, 0.5, 0.852, 0.966, 0, -0.259, 0, 1, 0, 0.259, 0, 0.966));
		local wingR = wingL:Clone();
		wingR.EmissionDirection = Enum.NormalId.Front;
		keep(wingR, right);

		local core = anchor(torso, CFrame.new(0, 0.3, 0));
		local burst = Instance.new("ParticleEmitter");
		burst.Lifetime = NumberRange.new(2, 2);
		burst.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4;
		burst.SpreadAngle = Vector2.new(180, 180);
		burst.LockedToPart = true;
		burst.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		});
		burst.LightEmission = 1;
		burst.Color = ColorSequence.new(A.Color);
		burst.Speed = NumberRange.new(0.5, 0.5);
		burst.Brightness = 2;
		burst.Size = NumberSequence.new(3, 4);
		burst.Rate = 5;
		burst.Texture = "rbxassetid://11402221943";
		burst.FlipbookMode = Enum.ParticleFlipbookMode.OneShot;
		burst.Rotation = NumberRange.new(0, 360);
		keep(burst, core);
	end;

	local function createAmbient(character)
		local hrp = part(character, "HumanoidRootPart");

		if not hrp then return end;

		local base = anchor(hrp, CFrame.new(0, -2.75, 0));

		local grow = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 1),
			NumberSequenceKeypoint.new(0.6, 2.5),
			NumberSequenceKeypoint.new(0.8, 4),
			NumberSequenceKeypoint.new(1, 6),
		});

		local crescent = Instance.new("ParticleEmitter");
		crescent.Lifetime = NumberRange.new(2, 2);
		crescent.SpreadAngle = Vector2.new(0.001, 0.001);
		crescent.LockedToPart = true;
		crescent.Transparency = NumberSequence.new(0, 1);
		crescent.LightEmission = 1;
		crescent.Color = ColorSequence.new(A.Color);
		crescent.Squash = NumberSequence.new(0);
		crescent.Speed = NumberRange.new(0.001, 0.001);
		crescent.Brightness = 2;
		crescent.Size = grow;
		crescent.RotSpeed = NumberRange.new(-600, 600);
		crescent.Texture = "rbxassetid://12713358087";
		crescent.Orientation = Enum.ParticleOrientation.VelocityPerpendicular;
		crescent.Rotation = NumberRange.new(0, 360);
		keep(crescent, base);

		local ring = Instance.new("ParticleEmitter");
		ring.Lifetime = NumberRange.new(2, 2);
		ring.SpreadAngle = Vector2.new(0.001, 0.001);
		ring.LockedToPart = true;
		ring.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.6, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		});
		ring.LightEmission = 1;
		ring.Color = ColorSequence.new(A.Color);
		ring.Squash = NumberSequence.new(0, 2);
		ring.Speed = NumberRange.new(0.001, 0.001);
		ring.Brightness = 2;
		ring.Size = grow;
		ring.RotSpeed = NumberRange.new(-30, 30);
		ring.Texture = "rbxassetid://7216849325";
		ring.Orientation = Enum.ParticleOrientation.VelocityPerpendicular;
		ring.Rotation = NumberRange.new(0, 360);
		keep(ring, base);

		local wide = Instance.new("ParticleEmitter");
		wide.Lifetime = NumberRange.new(2, 2);
		wide.SpreadAngle = Vector2.new(0.001, 0.001);
		wide.LockedToPart = true;
		wide.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		});
		wide.LightEmission = 1;
		wide.Color = ColorSequence.new(A.Color);
		wide.Squash = NumberSequence.new(0);
		wide.Speed = NumberRange.new(0.001, 0.001);
		wide.Brightness = 2;
		wide.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 2),
			NumberSequenceKeypoint.new(0.6, 5),
			NumberSequenceKeypoint.new(0.8, 8),
			NumberSequenceKeypoint.new(1, 12),
		});
		wide.RotSpeed = NumberRange.new(-40, 40);
		wide.Texture = "rbxassetid://7216855136";
		wide.Orientation = Enum.ParticleOrientation.VelocityPerpendicular;
		wide.Rotation = NumberRange.new(0, 360);
		keep(wide, base);
	end;

	local function createNimb(character)
		local head = part(character, "Head");

		if not head then return end;

		local halo = anchor(head, CFrame.new(-0.25, 0.933, 0.259, 0.469, -0.25, -0.847, -0.117, 0.933, -0.34, 0.875, 0.259, 0.408));

		for index = 1, 2 do
			local emitter = Instance.new("ParticleEmitter");
			emitter.Lifetime = NumberRange.new(1, 1);
			emitter.SpreadAngle = Vector2.new(5, 5);
			emitter.LockedToPart = true;
			emitter.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, 0),
				NumberSequenceKeypoint.new(0.8, 0),
				NumberSequenceKeypoint.new(1, 1),
			});
			emitter.LightEmission = 1;
			emitter.Color = ColorSequence.new(A.Color);
			emitter.Speed = NumberRange.new(0.001, 0.001);
			emitter.Brightness = 2;
			emitter.Size = (index == 1) and NumberSequence.new(2.5, 3) or NumberSequence.new(2, 3);
			emitter.RotSpeed = NumberRange.new(-400, 400);
			emitter.Rate = 7;
			emitter.Texture = "rbxassetid://8819682608";
			emitter.Orientation = Enum.ParticleOrientation.VelocityPerpendicular;
			emitter.Rotation = NumberRange.new(0, 360);
			keep(emitter, halo);
		end;
	end;

	local function createTornado(character)
		local hrp = part(character, "HumanoidRootPart");

		if not hrp then return end;

		local base = anchor(hrp, CFrame.new(0, -3, 0));

		local funnel = Instance.new("ParticleEmitter");
		funnel.LightInfluence = 1;
		funnel.LockedToPart = true;
		funnel.LightEmission = 1;
		funnel.Color = ColorSequence.new(A.Color);
		funnel.Speed = NumberRange.new(0.01, 0.01);
		funnel.Size = NumberSequence.new(6, 10);
		funnel.RotSpeed = NumberRange.new(360, 360);
		funnel.Rate = 1;
		funnel.Texture = "rbxassetid://8553497052";
		funnel.Orientation = Enum.ParticleOrientation.VelocityPerpendicular;
		keep(funnel, base);
	end;

	local loaded = {};
	local loading = {};

	local function fetchAura(name)
		if loaded[name] ~= nil then return loaded[name] or nil end;
		if loading[name] then
			local deadline = os.clock() + 13;
			repeat task.wait(0.03) until not loading[name] or not __ALIVE() or os.clock() >= deadline;
			return loaded[name];
		end;

		local id = CATALOGUE[name];

		if not id then return nil end;

		loading[name] = true;
		local ok, objects = Remote.objects(function() return game:GetObjects("rbxassetid://" .. id) end);
		loading[name] = nil;
		local source = (ok and type(objects) == "table") and objects[1] or nil;

		if type(objects) == "table" then for index = 2, #objects do pcall(function() objects[index]:Destroy() end) end end;
		if not __ALIVE() then if source then source:Destroy() end; return nil end;
		loaded[name] = source;
		if source then A.LoadErrors[name] = nil else A.LoadErrors[name] = "Asset unavailable: " .. id end;

		return source;
	end;

	local function slotFor(character, name)
		local direct = character:FindFirstChild(name, true);

		if direct and direct:IsA("BasePart") then return direct end;

		for _, alias in ipairs(GROUP_OF[name] or {}) do
			local found = character:FindFirstChild(alias, true);

			if found and found:IsA("BasePart") then return found end;
		end;

		return nil;
	end;

	local function createCatalogue(name)
		return function(character, generation, bank)

			bank = bank or sink;
			sink = mine;

			local source = fetchAura(name);
			local ours = bank == mine;

			if not source or not __ALIVE() or not character.Parent then return end;
			if ours and (not A.On or generation ~= auraGeneration or LocalPlayer.Character ~= character) then return end;

			local held = sink;
			sink = bank;

			local clone = source:Clone();
			for _, item in ipairs(clone:GetDescendants()) do
				if item:IsA("LuaSourceContainer") then item:Destroy() end;
			end;

			for _, group in ipairs(clone:GetChildren()) do
				local target = slotFor(character, group.Name) or part(character, "UpperTorso", "Torso", "HumanoidRootPart");

				if target then
					for _, child in ipairs(group:GetChildren()) do
						child.Parent = target;

						sink.borrowed[#sink.borrowed + 1] = child;

						local nodes = child:GetDescendants(); nodes[#nodes + 1] = child;
						for _, item in ipairs(nodes) do
							if item:IsA("ParticleEmitter") then keep(item, item.Parent);
							elseif item:IsA("Light") or item:IsA("Beam") or item:IsA("Trail") then
								sink.accents[#sink.accents + 1] = { item = item, color = item.Color,
									brightness = item:IsA("Light") and item.Brightness or 1 };
							end;
						end;
					end;
				end;
			end;

			clone:Destroy();
			sink = held;
		end;
	end;

	local cometHost = Render.gui("comet aura", -7);
	local cometSprites, cometTexture = {}, nil;
	local cometClock, cometFade = 0, 0;
	A.CometSprites = cometSprites;
	local function hideComet()
		for _, sprite in ipairs(cometSprites) do sprite.Visible = false end;
	end;
	NeverLose:AddSignal(RunService.RenderStepped:Connect(function(dt)
		if not __ALIVE() then return end;
		if not (A.On and A.Types.Comet) and cometFade <= 0 then return end;
		local character = LocalPlayer.Character;
		local root = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart"));
		local camera = Render.camera();
		local active = A.On and A.Types.Comet and root and root:IsA("BasePart") and camera;
		cometFade = math.clamp(cometFade + (active and dt or -dt) / 0.35, 0, 1);
		if not root or not camera or cometFade <= 0 then hideComet(); return end;
		cometClock += dt;
		if cometClock < 1 / 30 then return end;
		cometClock %= 1 / 30;
		if not ESP.Visibility.Part(camera, root, character) then hideComet(); return end;
		if not cometTexture then
			cometTexture = Remote.id(Remote.file("particles/comet_bloom.png"));
			if not cometTexture then hideComet(); return end;
		end;
		local count = math.clamp(math.floor(A.TrailLength), 20, 300);
		local distance = math.max(1.5, (camera.CFrame.Position - root.Position).Magnitude);
		local time = DateTime.now().UnixTimestampMillis;
		local baseSize = math.clamp(A.BloomSize * A.Size * camera.ViewportSize.Y / 720 / distance, 1, 160);
		local index = 0;
		for i = 0, count - 1 do
			local angle = 0.1 * (time - i * 1.5 * 300 / count * A.TrailStep) / (30 / A.Speed);
			local s, c = math.sin(angle) * A.Radius, math.cos(angle) * A.Radius;
			local progress = i / count;
			local diameter = math.max(1, baseSize * (1 - progress) ^ 1.1);
			local alpha = math.clamp(cometFade * (1 - progress * progress) * 0.4 * A.Glow * 0.5, 0, 0.95);
			for _, offset in ipairs({ Vector3.new(s, c, -c), Vector3.new(-s, s, -c), Vector3.new(-s, -s, c) }) do
				index += 1;
				local sprite = cometSprites[index];
				if not sprite then
					sprite = Instance.new("ImageLabel");
					sprite.Name = "VisualsCometBloom";
					sprite.BackgroundTransparency, sprite.BorderSizePixel = 1, 0;
					sprite.AnchorPoint, sprite.Image = Vector2.new(0.5, 0.5), cometTexture;
					sprite.Parent = cometHost;
					cometSprites[index] = sprite;
				end;
				local at, visible = camera:WorldToViewportPoint(root.Position + offset);
				sprite.Visible = visible and at.Z > 0 and alpha > 0.005;
				if sprite.Visible then
					sprite.Position, sprite.Size = UDim2.fromOffset(at.X, at.Y), UDim2.fromOffset(diameter, diameter);
					sprite.ImageColor3, sprite.ImageTransparency = A.Color, 1 - alpha;
					sprite.Rotation = (time / 5 + i * 5) % 180;
				end;
			end;
		end;
		for i = #cometSprites, index + 1, -1 do cometSprites[i]:Destroy(); cometSprites[i] = nil end;
	end));
	local BUILDERS = {
		Angelic = createAngelic,
		Ambient = createAmbient,
		Nimb = createNimb,
		Tornado = createTornado,

		Comet = function() end,
	};

	for name in pairs(CATALOGUE) do BUILDERS[name] = createCatalogue(name) end;

	local function refreshAuras()
		auraGeneration += 1;
		local generation = auraGeneration;
		clearAll();

		if not (__ALIVE() and A.On) then return end;

		local character = LocalPlayer.Character;

		if not character then return end;

		task.defer(function()
		for _, name in ipairs(ORDER) do
			if A.Types[name] then
				local build = BUILDERS[name];

				if generation ~= auraGeneration or not __ALIVE() or not A.On or LocalPlayer.Character ~= character then return end;
				if build then
					local ok, err = pcall(build, character, generation);
					if not ok and generation == auraGeneration then A.LoadErrors[name] = tostring(err); recordError("aura " .. name .. ": " .. tostring(err)) end;
					if ok and generation == auraGeneration then A.ReadyTypes[name] = true; tune() end;
				end;
			end;
		end;

		tune();
		if Preview and Preview.ReadAura and __ALIVE() and generation == auraGeneration then pcall(Preview.ReadAura) end;
		end);
	end;

	local function onCharacterAdded()
		if not A.On then return end;

		task.wait(0.5);

		if __ALIVE() and A.On then refreshAuras() end;
	end;

	local function setEnabled(value)
		auraGeneration += 1;
		A.On = value and true or false;

		if A.On then
			if not charConnection then
				charConnection = NeverLose:AddSignal(LocalPlayer.CharacterAdded:Connect(onCharacterAdded));
			end;

			if LocalPlayer.Character then
				task.spawn(function()
					task.wait(0.2);

					if __ALIVE() and A.On then refreshAuras() end;
				end);
			end;
		else
			if charConnection then
				pcall(function() charConnection:Disconnect() end);

				charConnection = nil;
			end;

			clearAll();
		end;
	end;

	function A.Dress(player, names, colour)
		if not player or player == LocalPlayer then return end;

		local bank = guests[player];

		if not bank then bank = newBank(colour); guests[player] = bank end;

		bank.color = colour or bank.color;
		bank.want = names or {};
	end;

	function A.Undress(player)
		local bank = guests[player];

		if not bank then return end;

		clearBank(bank);
		guests[player] = nil;
	end;

	function A.Guests() return guests end;

	local function serveGuest(player, bank)
		local character = player.Character;

		if not character or not character.Parent then
			if bank.char then clearBank(bank); bank.char = nil end;
			return;
		end;

		local key = table.concat(bank.want, ",");

		if bank.char == character and bank.key == key then return end;

		clearBank(bank);
		bank.char, bank.key = character, key;

		for _, name in ipairs(bank.want) do
			local build = BUILDERS[name];

			if build and name ~= "Comet" then
				sink = bank;
				pcall(build, character, auraGeneration, bank);
				sink = mine;
			end;
		end;

		tuneBank(bank);
	end;

	task.spawn(function()
		while __ALIVE() do
			task.wait(0.5);

			for player, bank in pairs(guests) do
				if not player.Parent then A.Undress(player) else pcall(serveGuest, player, bank) end;
			end;
		end;
	end);

	onUnload("aura guests", function()
		for player in pairs(guests) do pcall(A.Undress, player) end;
	end);

	ESP.AuraSource = function()
		return LocalPlayer.Character;
	end;

	local function refreshPreview()
		if Preview and Preview.ReadAura then pcall(Preview.ReadAura) end;
	end;

	local row = Sections.Aura:AddLabel("Aura");

	row:AddToggle({
		Name = "Aura",
		Default = false,
		Flag = "aura",
		Callback = function(v) setEnabled(v); if A.WearGame then A.WearGame() end; refreshPreview() end,
	});

	row:AddColorPicker({
		Default = A.Color,
		Flag = "aura_color",
		Callback = function(v)
			A.Color = v;

			tune();
			refreshPreview();
		end,
	});

	local FX = ESP.GameFX;
	local gameIds = {};
	local ART = {
		Angelic = "rbxassetid://13267054240", Ambient = "rbxassetid://12713358087",
		Nimb = "rbxassetid://8819682608", Tornado = "rbxassetid://8553497052",
		Comet = "rbxassetid://11402221943",
	};

	local function auraRows()
		local out = {};

		for _, name in ipairs(ORDER) do
			local image, rect, size = ART[name], nil, nil;
			if FX then image, rect, size = FX.Art("builtin/aura/" .. name, ART[name]) end;
			out[#out + 1] = { name = name, label = name, image = image, rect = rect, rectsize = size,
				id = not rect and tonumber(CATALOGUE[name]) or nil };
		end;

		for _, entry in ipairs(FX and FX.Catalog or {}) do
			if entry.kind ~= "Trail" and entry.kind ~= "Cosmetic" then
				out[#out + 1] = FX.Row(entry);
			end;
		end;

		return out;
	end;

	function A.WearGame()
		if FX then FX.SetGroup("aura", A.On and gameIds or {}) end;
	end;

	local auraGrid = Visuals.Auras:AddGallery({
		Name = "Auras", Icon = "sparkles", Position = "left", Height = 440, Cell = 74, Reset = true, Smooth = true,
		Thumb = "Asset", Blank = "sparkles", Empty = "No auras", Values = auraRows(),
		Default = { "Angelic" }, Multi = true, Flag = "aura_types",
		Callback = function(v)
			local picked, game = {}, {};

			if type(v) == "table" then
				for key, value in pairs(v) do

					local name = (type(key) == "string" and value) and key or value;

					if type(name) == "string" then
						if BUILDERS[name] then picked[name] = true
						elseif FX and FX.ById[name] then game[#game + 1] = name end;
					end;
				end;
			elseif type(v) == "string" then
				picked[v] = true;
			end;

			gameIds = game;
			A.WearGame();
			A.Types = picked;
			A.Type = nil;

			for _, name in ipairs(ORDER) do
				if picked[name] then A.Type = name; break end;
			end;

			if not A.Type and next(picked) then A.Type = "Angelic" end;

			refreshAuras();
			refreshPreview();
		end,
	});
	Sections.Aura:AddButton({ Name = "Unequip All", Icon = "x", Callback = function()
		pcall(function() auraGrid:set({}) end);
	end });

	if FX then
		FX.OnThumbs(function() auraGrid:setdata(auraRows()) end);
		Visuals.Auras.Signal:Connect(function(open) if open then FX.LoadThumbs() end end);
	end;

	Sections.Aura:AddLabel("Custom Colors"):AddToggle({ Default = true, Flag = "aura_tint",
		Callback = function(v) A.Tint = v; tune(); refreshPreview() end });

	for _, setting in ipairs({
		{ "Glow", "Glow", "aura_glow", 0, 600, 200, 100 },
		{ "Rate", "Rate", "aura_rate", 10, 400, 100, 100 },
		{ "Size", "Size", "aura_size", 25, 300, 100, 100 },
		{ "Speed", "Speed", "aura_speed", 5, 500, 100, 100 },
	}) do
		local key, divisor = setting[2], setting[7];

		Sections.Aura:AddLabel(setting[1]):AddSlider({
			Min = setting[4], Max = setting[5], Default = setting[6],
			Rounding = 0, Size = 90, Flag = setting[3],
			Callback = function(v)
				A[key] = v / divisor;

				tune();
				refreshPreview();
			end,
		});
	end;

	ESP.ClearAura = onUnload("aura", function()
		A.On = false;
		if FX then pcall(FX.SetGroup, "aura", {}) end;
		auraGeneration += 1;

		if charConnection then
			pcall(function() charConnection:Disconnect() end);

			charConnection = nil;
		end;

		clearAll();
		hideComet();
		table.clear(cometSprites);
		for _, source in pairs(loaded) do if source then pcall(function() source:Destroy() end) end end;
		table.clear(loaded);
	end);
end;
