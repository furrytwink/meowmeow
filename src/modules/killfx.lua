--!nonstrict
--[[
	killfx.lua — extracted feature module (require id "modules.killfx").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("killfx") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("killfx", function()
			return require("modules.killfx")({ ESP = ESP, INIT_GENERATION = INIT_GENERATION, LocalPlayer = LocalPlayer, NeverLose = NeverLose, Players = Players, Sections = Sections, TAG = TAG, onUnload = onUnload, scanDescendantsAsync = scanDescendantsAsync, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local INIT_GENERATION = ctx.INIT_GENERATION;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local Players = ctx.Players;
	local Sections = ctx.Sections;
	local TAG = ctx.TAG;
	local onUnload = ctx.onUnload;
	local scanDescendantsAsync = ctx.scanDescendantsAsync;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("killfx") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local TweenService = game:GetService("TweenService");

	local K = {
		Clone = false, CloneColor = Color3.fromRGB(255, 0, 0), CloneTime = 3,
		Emitter = false, EmitterColor = Color3.fromRGB(255, 100, 100), EmitterTime = 1.2,
		Target = "Other",
	};

	local clones = {};
	local active, activeCount = {}, 0;

	local function removeEffect(record)
		for i = 1, activeCount do
			if active[i] == record then
				active[i] = active[activeCount];
				active[activeCount] = nil;
				activeCount = activeCount - 1;
				break;
			end;
		end;

		if record.part and record.part.Parent then record.part:Destroy() end;
	end;

	local function spawnEmitter(character, tint, duration)
		if not (character and character.Parent) then return end;

		if activeCount >= 3 then
			removeEffect(active[1]);
		end;

		duration = math.max(duration, 0.2);

		local bodyParts = {};

		for _, source in ipairs(character:GetChildren()) do
			if source:IsA("BasePart") and source.Name ~= "HumanoidRootPart" and #bodyParts < 15 then
				bodyParts[#bodyParts + 1] = source;
			end;
		end;

		if #bodyParts == 0 then return end;

		local root = Instance.new("Folder");
		root.Name = NeverLose.RandomString();
		root:SetAttribute(TAG, INIT_GENERATION);
		root.Parent = workspace;

		local record = { part = root, balls = {} };
		activeCount = activeCount + 1;
		active[activeCount] = record;

		local random = math.random;
		local goldenAngle = math.pi * (3 - math.sqrt(5));

		local function surfacePosition(source, radius, index, count, headSeed)
			local size = source.Size;
			local padding = radius * 0.92;

			if source.Name == "Head" then
				local y = 1 - 2 * ((index - 0.5) / count);
				local angle = index * goldenAngle + headSeed;
				local radial = math.sqrt(math.max(0, 1 - y * y));
				local dir = Vector3.new(radial * math.cos(angle), y, radial * math.sin(angle));
				local half = size * 0.5;

				return source.CFrame:PointToWorldSpace(Vector3.new(
					dir.X * (half.X + padding),
					dir.Y * (half.Y + padding),
					dir.Z * (half.Z + padding)
				));
			end;

			local areaX = size.Y * size.Z;
			local areaY = size.X * size.Z;
			local areaZ = size.X * size.Y;
			local pick = random() * (areaX + areaY + areaZ);
			local pos;

			if pick < areaX then
				local side = random() < 0.5 and -1 or 1;
				pos = Vector3.new(side * (size.X * 0.5 + padding), (random() - 0.5) * size.Y, (random() - 0.5) * size.Z);
			elseif pick < areaX + areaY then
				local side = random() < 0.5 and -1 or 1;
				pos = Vector3.new((random() - 0.5) * size.X, side * (size.Y * 0.5 + padding), (random() - 0.5) * size.Z);
			else
				local side = random() < 0.5 and -1 or 1;
				pos = Vector3.new((random() - 0.5) * size.X, (random() - 0.5) * size.Y, side * (size.Z * 0.5 + padding));
			end;

			return source.CFrame:PointToWorldSpace(pos);
		end;

		local minY, maxY = math.huge, -math.huge;

		for _, source in ipairs(bodyParts) do
			local halfY = source.Size.Y * 0.5;
			minY = math.min(minY, source.Position.Y - halfY);
			maxY = math.max(maxY, source.Position.Y + halfY);
		end;

		local phaseCount = 8;
		local groups = {};

		for i = 1, phaseCount do groups[i] = {} end;

		local headSeed = random() * math.pi * 2;
		local height = math.max(maxY - minY, 0.01);
		local created = 0;

		for _, source in ipairs(bodyParts) do
			local size = source.Size;
			local surface = 2 * (size.X * size.Y + size.X * size.Z + size.Y * size.Z);
			local count = source.Name == "Head" and 24 or math.clamp(math.floor(surface * 0.65 + 0.5), 7, 12);
			count = math.min(count, 140 - created);

			for index = 1, count do
				local diameter = source.Name == "Head" and (0.115 + random() * 0.045) or (0.13 + random() * 0.06);
				local targetSize = Vector3.new(diameter, diameter, diameter);
				local position = surfacePosition(source, diameter * 0.5, index, count, headSeed);

				local ball = Instance.new("Part");
				ball.Name = NeverLose.RandomString();
				ball.Shape = Enum.PartType.Ball;
				ball.Material = Enum.Material.Neon;
				ball.Color = tint;
				ball.Size = Vector3.new(0.015, 0.015, 0.015);
				ball.Position = position;
				ball.Anchored = true;
				ball.CanCollide = false;
				ball.CanQuery = false;
				ball.CanTouch = false;
				ball.CastShadow = false;
				ball.Massless = true;
				ball.Transparency = 1;
				ball.Parent = root;

				record.balls[#record.balls + 1] = ball;
				created = created + 1;

				local vertical = math.clamp((position.Y - minY) / height, 0, 1);
				local phase = math.clamp(math.floor(vertical * (phaseCount - 1) + 1.5) + random(-1, 1), 1, phaseCount);

				groups[phase][#groups[phase] + 1] = { ball = ball, size = targetSize };
			end;

			if created >= 140 then break end;
		end;

		local revealWindow = math.min(0.34, duration * 0.26);
		local revealTime = math.min(0.2, duration * 0.18);
		local fadeBegin = math.max(revealWindow + revealTime + 0.06, duration * 0.42);
		local fadeWindow = math.min(0.28, duration * 0.18);
		local fadeTime = math.max(duration - fadeBegin - fadeWindow, 0.1);

		for phase = 1, phaseCount do
			local alpha = (phase - 1) / (phaseCount - 1);
			local group = groups[phase];

			task.delay(revealWindow * alpha, function()
				if not root.Parent then return end;

				for _, item in ipairs(group) do
					if item.ball.Parent then
						TweenService:Create(item.ball, TweenInfo.new(revealTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
							Size = item.size, Transparency = 0.05,
						}):Play();
					end;
				end;
			end);

			task.delay(fadeBegin + fadeWindow * alpha, function()
				if not root.Parent then return end;

				for _, item in ipairs(group) do
					if item.ball.Parent then
						TweenService:Create(item.ball, TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
							Size = item.size * 0.58, Transparency = 1,
						}):Play();
					end;
				end;
			end);
		end;

		task.delay(duration + 0.12, function()
			removeEffect(record);
		end);
	end;

	local function fadeClone(clone, wait)
		task.delay(wait, function()
			if not clone.Parent then return end;

			for _, d in ipairs(clone:GetDescendants()) do
				if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
					pcall(function()
						TweenService:Create(d, TweenInfo.new(1.5, Enum.EasingStyle.Linear), { Transparency = 1 }):Play();
					end);
				end;
			end;

			task.delay(1.6, function()
				for i = #clones, 1, -1 do
					if clones[i] == clone then table.remove(clones, i) end;
				end;

				if clone.Parent then clone:Destroy() end;
			end);
		end);
	end;

	local function makeClone(character)

		local archivable = character.Archivable;

		if not archivable then
			pcall(function() character.Archivable = true end);
		end;

		local ok, clone = pcall(character.Clone, character);

		if not archivable then
			pcall(function() character.Archivable = archivable end);
		end;

		if not ok or not clone then return end;

		for _, d in ipairs(clone:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true;
				d.CanCollide = false;
				d.CanQuery = false;
				d.CanTouch = false;

				if d.Name == "HumanoidRootPart" then
					d.Transparency = 1;
				else
					d.Material = Enum.Material.ForceField;
					d.Color = K.CloneColor;
				end;
			elseif d:IsA("Humanoid") or d:IsA("AnimationController") or d:IsA("BaseScript") or d:IsA("ModuleScript") or d:IsA("Sound")
				or d:IsA("SurfaceAppearance") or d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam")
				or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") or d:IsA("Light") or d:IsA("Highlight")
				or d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
				pcall(function() d:Destroy() end);
			end;
		end;

		local shell = Instance.new("Folder");
		shell.Name = NeverLose.RandomString();
		shell:SetAttribute(TAG, INIT_GENERATION);
		for _, child in ipairs(clone:GetChildren()) do child.Parent = shell end;
		clone:Destroy();
		clone = shell;
		clone.Parent = workspace;

		clones[#clones + 1] = clone;

		fadeClone(clone, K.CloneTime);
	end;

	local function wants(player)
		local isSelf = player == LocalPlayer;

		return K.Target == "All" or (isSelf and K.Target == "Self") or (not isSelf and K.Target == "Other");
	end;

	local function onDeath(character)
		if K.Clone then makeClone(character) end;
		if K.Emitter then spawnEmitter(character, K.EmitterColor, K.EmitterTime) end;
	end;

	local humanoidHooks = {};
	local watching, scanGeneration = false, 0;
	local function unhookHumanoid(human)
		local record = humanoidHooks[human];
		if not record then return end;
		humanoidHooks[human] = nil;
		for _, connection in ipairs(record) do connection:Disconnect() end;
	end;
	local function hookHumanoid(human)
		if not __ALIVE() or humanoidHooks[human] then return end;
		local character = human.Parent;
		if not character or not character:IsA("Model") then return end;
		local record = {};
		humanoidHooks[human] = record;
		local fired = false;
		local function died()
			if not __ALIVE() or fired or not (K.Clone or K.Emitter) then return end;
			fired = true;
			local player = Players:GetPlayerFromCharacter(character);
			if player and not wants(player) then return end;
			if not player and K.Target == "Self" then return end;
			onDeath(character);
		end;
		record[#record + 1] = human.Died:Connect(died);
		record[#record + 1] = human.HealthChanged:Connect(function(value)
			if value <= 0 then died() else fired = false end;
		end);
		record[#record + 1] = human.AncestryChanged:Connect(function(_, parent)
			if not parent then unhookHumanoid(human) end;
		end);
		record[#record + 1] = human.Destroying:Connect(function() unhookHumanoid(human) end);
	end;

	local function stopWatching()
		watching = false;
		scanGeneration += 1;
		for human in pairs(humanoidHooks) do unhookHumanoid(human) end;
	end;
	local function startWatching()
		if watching then return end;
		watching = true;
		scanGeneration += 1;
		local token = scanGeneration;
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character;
			local human = character and character:FindFirstChildOfClass("Humanoid");
			if human then hookHumanoid(human) end;
		end;
		scanDescendantsAsync("kill effects scan", workspace, function(inst)
			if inst:IsA("Humanoid") then hookHumanoid(inst) end;
		end, function()
			return watching and token == scanGeneration;
		end, 512);
	end;
	local function updateWatching()
		if K.Clone or K.Emitter then startWatching() else stopWatching() end;
	end;
	NeverLose:AddSignal(workspace.DescendantAdded:Connect(function(inst)
		if watching and inst:IsA("Humanoid") then hookHumanoid(inst) end;
	end));

	for _, leftover in ipairs(workspace:GetChildren()) do
		local owner = leftover:GetAttribute(TAG);
		if owner and owner ~= INIT_GENERATION and (leftover:IsA("Folder") or leftover:IsA("Model")) then
			leftover:Destroy();
		end;
	end;

	ESP.KillFx = K;

	ESP.ClearKillFx = onUnload("kill effects", function()
		K.Clone, K.Emitter = false, false;
		stopWatching();
		for i = activeCount, 1, -1 do
			if active[i] then pcall(function() active[i].part:Destroy() end) end;
			active[i] = nil;
		end;

		activeCount = 0;

		for _, clone in ipairs(clones) do pcall(function() clone:Destroy() end) end;

		clones = {};
	end);

	local cloneRow = Sections.KillFx:AddLabel("Ghost");
	cloneRow:AddToggle({ Default = false, Flag = "killfx_clone", Callback = function(v) K.Clone = v; updateWatching() end });
	cloneRow:AddColorPicker({ Default = K.CloneColor, Flag = "killfx_clone_color", Callback = function(v) K.CloneColor = v end });
	cloneRow:AddOption(1):AddLabel("Hold"):AddSlider({
		Min = 1, Max = 100, Default = 30, Rounding = 0, Size = 90,
		Flag = "killfx_clone_time",
		Callback = function(v) K.CloneTime = v / 10 end,
	});

	local emitterRow = Sections.KillFx:AddLabel("Neon Burst");
	emitterRow:AddToggle({ Default = false, Flag = "killfx_emitter", Callback = function(v) K.Emitter = v; updateWatching() end });
	emitterRow:AddColorPicker({ Default = K.EmitterColor, Flag = "killfx_emitter_color", Callback = function(v) K.EmitterColor = v end });
	emitterRow:AddOption(1):AddLabel("Length"):AddSlider({
		Min = 4, Max = 60, Default = 12, Rounding = 0, Size = 90,
		Flag = "killfx_emitter_time",
		Callback = function(v) K.EmitterTime = v / 10 end,
	});

	Sections.KillFx:AddLabel("Target"):AddDropdown({
		Default = "Other",
		Values = { "Other", "Self", "All" },
		Flag = "killfx_target",
		Callback = function(v) K.Target = v end,
	});
end;
