--!nonstrict
--[[
	circles.lua — extracted feature module (require id "modules.circles").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("circles") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("circles", function()
			return require("modules.circles")({ ESP = ESP, INIT_GENERATION = INIT_GENERATION, LocalPlayer = LocalPlayer, NeverLose = NeverLose, Players = Players, Remote = Remote, Render = Render, RunService = RunService, Sections = Sections, TAG = TAG, onUnload = onUnload, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local INIT_GENERATION = ctx.INIT_GENERATION;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local Players = ctx.Players;
	local Remote = ctx.Remote;
	local Render = ctx.Render;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local TAG = ctx.TAG;
	local onUnload = ctx.onUnload;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("circles") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local Debris = game:GetService("Debris");
	local ContentProvider = game:GetService("ContentProvider");
	local DEFAULT_STYLE = "Soft Ring";

	local C = {
		Jump = false, Land = false,
		Style = DEFAULT_STYLE,
		Color = Color3.fromRGB(150, 200, 255),
		Size = 4,
		Life = 0.8,
		Target = "Self",
		Bright = 100,
		Grow = 160,
		Spin = 0,
	};

	local styles = {
		["Soft Ring"] = { file = Remote.file("circles/circle.png") },
		Inscription = { file = Remote.file("circles/konchal.png") },
		["Classic Ring"] = { asset = "rbxassetid://7185003058" },
		["Double Ripple"] = { file = Remote.file("circles/ripple.png") },
		["Neon Ring"] = { file = Remote.file("circles/neonring.png") },
		["Triple Swirl"] = { file = Remote.file("circles/swirl.png") },
		["Neon Star"] = { file = Remote.file("circles/neonstar.png") },
		["Halo Ring"] = { file = Remote.file("circles/haloring.png") },
		["Cracked Ground"] = { file = Remote.file("circles/shatter.png") },
		["Rune Crown"] = { file = Remote.file("circles/img.png") },
		["Glyph Ring"] = { file = Remote.file("circles/pentos.png") },
		["Magic Circle"] = { file = Remote.file("circles/imagephotoroom.png") },
		["Blast Ring"] = { file = Remote.file("circles/boom1.png") },
		["Vortex Ring"] = { file = Remote.file("circles/omut3.png") },
		["Radial Burst"] = { file = Remote.file("circles/85362844633530.png") },
		["Mist Ring"] = { file = Remote.file("circles/134160165648626.png") },
		["Star Flash"] = { file = Remote.file("circles/17068400400.png") },
		["Arcane Sigil"] = { file = Remote.file("circles/circle4.png") },
	};

	local order = {
		"Soft Ring", "Inscription", "Classic Ring", "Double Ripple", "Neon Ring", "Triple Swirl",
		"Neon Star", "Halo Ring", "Cracked Ground", "Rune Crown", "Glyph Ring", "Magic Circle",
		"Blast Ring", "Vortex Ring", "Radial Burst", "Mist Ring", "Star Flash", "Arcane Sigil",
	};
	local aliases = {
		Circle = "Soft Ring", Konchal = "Inscription", Ring = "Classic Ring", Ripple = "Double Ripple",
		Neon = "Neon Ring", Swirl = "Triple Swirl", Star = "Neon Star", Halo = "Halo Ring",
		Shatter = "Cracked Ground", Img = "Rune Crown", Pentos = "Glyph Ring",
		["Image Photoroom"] = "Magic Circle", ["Boom 1"] = "Blast Ring", ["Omut 3"] = "Vortex Ring",
		["85362844633530"] = "Radial Burst", ["134160165648626"] = "Mist Ring",
		["17068400400"] = "Star Flash", ["Circle 4"] = "Arcane Sigil",
		Animation1 = "Orbit Rings", Animation2 = "Firework Bloom", Puff = "Smoke Bloom",
	};
	local generatedNames = { animation1 = "Orbit Rings", animation2 = "Firework Bloom", puff = "Smoke Bloom" };

	do
		for _, rel in ipairs(Remote.under("circles/")) do
			local file = string.match(rel, "([^/]+)$");
			local name, cols, rows, frames = string.match(file or "", "^(.+)_(%d+)x(%d+)_(%d+)%.png$");

			if name then
				local pretty = generatedNames[string.lower(name)] or (string.gsub(name, "^%l", string.upper));

				styles[pretty] = {
					file = Remote.file(rel),
					cols = tonumber(cols), rows = tonumber(rows), frames = tonumber(frames),
				};

				order[#order + 1] = pretty;
			end;
		end;
	end;

	local function urlFor(style)
		if style.asset then return style.asset end;
		if style.url ~= nil then return style.url or nil end;
		style.url = Remote.id(style.file) or false;
		return style.url or nil;
	end;
	local function canonicalStyle(name)
		name = aliases[name] or name;
		return styles[name] and name or DEFAULT_STYLE;
	end;
	ESP.CircleStyles = { Order = order, Styles = styles, Aliases = aliases, Default = DEFAULT_STYLE };
	task.spawn(function()
		local urls = {};
		for _, name in ipairs(order) do
			if not __ALIVE() then return end;
			local url = urlFor(styles[name]);
			if url then urls[#urls + 1] = url end;
			task.wait();
		end;
		if __ALIVE() and #urls > 0 then Remote.invoke(function() ContentProvider:PreloadAsync(urls) end, 8) end;
	end);
	do
		local G = ESP.GunChams;
		if G then
			local function makeCircle(record, style)
				local part = Instance.new("Part");
				part.Name = "VisualsGunCircle";
				part:SetAttribute(TAG, INIT_GENERATION);
				part:SetAttribute("VisualsGunAura", true);
				part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false;
				part.CastShadow, part.Transparency = false, 1;
				part.Parent = workspace;
				local attach = Instance.new("Attachment"); attach.Parent = part;
				local emitter = Instance.new("ParticleEmitter");
				emitter:SetAttribute("VisualsGunAura", true);
				emitter.Rate, emitter.TimeScale = 0, 0;
				emitter.Lifetime, emitter.Speed = NumberRange.new(20), NumberRange.new(0.01);
				emitter.LightEmission, emitter.LightInfluence, emitter.LockedToPart = 1, 0, true;
				emitter.Orientation = Enum.ParticleOrientation.VelocityPerpendicular;
				emitter.EmissionDirection = Enum.NormalId.Top;
				emitter.Rotation, emitter.RotSpeed = NumberRange.new(0), NumberRange.new(0);
				emitter.Parent = attach;
				local circle = { Part = part, Emitter = emitter, Style = G.CircleStyle, Clock = 1 };
				record.Circle = circle;
				task.defer(function()
					local url = urlFor(style);
					if not __ALIVE() or record.Circle ~= circle or not part.Parent or not url then return end;
					emitter.Texture = url;
					local layouts = { [2] = Enum.ParticleFlipbookLayout.Grid2x2,
						[4] = Enum.ParticleFlipbookLayout.Grid4x4, [8] = Enum.ParticleFlipbookLayout.Grid8x8 };
					if style.frames and layouts[style.cols] then
						emitter.FlipbookLayout = layouts[style.cols];
						emitter.FlipbookMode = Enum.ParticleFlipbookMode.OneShot;
						emitter.FlipbookStartRandom = false;
						emitter.FlipbookFramerate = NumberRange.new(0);
					end;
					emitter:Emit(1);
					circle.Ready = true;
				end);
				return circle;
			end;
			ESP.StaticGunCircle = function(record, object, gun, dt)
				local style = styles[G.CircleStyle] or styles[DEFAULT_STYLE];
				local circle = record.Circle;
				if not circle or circle.Style ~= G.CircleStyle or not circle.Part.Parent then
					if circle then circle.Part:Destroy() end;
					circle = makeCircle(record, style);
				end;
				circle.Clock += dt;
				if circle.Clock >= 0.1 or circle.Ground ~= G.CircleGround then
					circle.Clock, circle.Ground = 0, G.CircleGround;
					local position, normal = gun.Position - Vector3.new(0, gun.Size.Y * 0.5, 0), Vector3.yAxis;
					if G.CircleGround then
						local params = RaycastParams.new();
						params.FilterType = Enum.RaycastFilterType.Exclude;
						local ignore = { object, circle.Part };
						for _, player in ipairs(Players:GetPlayers()) do if player.Character then ignore[#ignore + 1] = player.Character end end;
						params.FilterDescendantsInstances, params.IgnoreWater = ignore, true;
						local hit = workspace:Raycast(gun.Position, Vector3.new(0, -64, 0), params);
						if hit then position, normal = hit.Position, hit.Normal end;
					end;
					circle.Position, circle.Normal = position, normal;
				end;
				local up = circle.Normal or Vector3.yAxis;
				local reference = math.abs(up.Y) > 0.98 and Vector3.xAxis or Vector3.yAxis;
				local right = up:Cross(reference).Unit;
				circle.Part.CFrame = CFrame.fromMatrix(circle.Position + up * G.CircleHeight, right, up, right:Cross(up).Unit);
				local emitter = circle.Emitter;
				local settings = { G.CircleColor, G.CircleSize, G.CircleOpacity, G.CircleGlow, G.CircleRotation, G.CircleThroughWalls };
				local changed = not circle.Settings;
				for i, value in ipairs(settings) do if not circle.Settings or value ~= circle.Settings[i] then changed = true end end;
				if changed then
					circle.Settings = settings;
					emitter.Color, emitter.Size = ColorSequence.new(G.CircleColor), NumberSequence.new(G.CircleSize);
					emitter.Transparency, emitter.Brightness = NumberSequence.new(1 - G.CircleOpacity), G.CircleGlow;
					emitter.Rotation = NumberRange.new(G.CircleRotation);
					Render.FxDepth(emitter, G.CircleThroughWalls);
					if circle.Ready then emitter:Clear(); emitter:Emit(1) end;
				end;
			end;
			local row = Sections.Guns:AddLabel("Gun Circle");
			row:AddToggle({ Default = false, Flag = "gun_circle", Callback = function(v) G.Circle = v; G.SetTracking() end });
			row:AddColorPicker({ Default = G.CircleColor, Flag = "gun_circle_color", Callback = function(v) G.CircleColor = v end });
			local options = row:AddOption(1);
			options:AddLabel("Style"):AddDropdown({ Default = DEFAULT_STYLE, Values = order, Flag = "gun_circle_style",
				Callback = function(v) G.CircleStyle = canonicalStyle(v) end });
			for _, setting in ipairs({
				{ "Size", "CircleSize", "size", 5, 300, 40, 10 },
				{ "Opacity", "CircleOpacity", "opacity", 0, 100, 100, 100 },
				{ "Glow", "CircleGlow", "glow", 0, 600, 200, 100 },
				{ "Height", "CircleHeight", "height", 0, 200, 6, 100 },
				{ "Rotation", "CircleRotation", "rotation", 0, 360, 0, 1 },
			}) do
				local key, divisor = setting[2], setting[7];
				options:AddLabel(setting[1]):AddSlider({ Min = setting[4], Max = setting[5], Default = setting[6],
					Rounding = 0, Flag = "gun_circle_" .. setting[3], Callback = function(v) G[key] = v / divisor end });
			end;
			options:AddLabel("On Ground"):AddToggle({ Default = true, Flag = "gun_circle_ground", Callback = function(v) G.CircleGround = v end });
		end;
	end;

	local FLIPBOOK = {
		[2] = Enum.ParticleFlipbookLayout.Grid2x2,
		[4] = Enum.ParticleFlipbookLayout.Grid4x4,
		[8] = Enum.ParticleFlipbookLayout.Grid8x8,
	};

	local function groundAt(char, root)
		local params = RaycastParams.new();
		params.FilterType = Enum.RaycastFilterType.Exclude;
		params.FilterDescendantsInstances = { char };
		params.IgnoreWater = true;

		local sum, normal, hits = Vector3.zero, Vector3.zero, 0;

		for _, name in ipairs({ "LeftFoot", "RightFoot", "Left Leg", "Right Leg" }) do
			local foot = char:FindFirstChild(name);

			if foot and foot:IsA("BasePart") then
				local hit = workspace:Raycast(foot.Position + Vector3.new(0, 0.35, 0), Vector3.new(0, -7, 0), params);

				if hit then
					sum = sum + hit.Position;
					normal = normal + hit.Normal;
					hits = hits + 1;
				end;
			end;
		end;

		if hits > 0 then return sum / hits, normal.Unit end;

		local hit = workspace:Raycast(root.Position + Vector3.new(0, 1, 0), Vector3.new(0, -16, 0), params);

		if hit then return hit.Position, hit.Normal end;

		return root.Position - Vector3.new(0, 3, 0), Vector3.yAxis;
	end;

	local circleParts, circleVisuals = {}, {};
	local function clearActiveCircles()
		local stale = {};
		for part in pairs(circleParts) do stale[#stale + 1] = part end;
		for _, part in ipairs(stale) do if part.Parent then part:Destroy() end end;
		table.clear(circleParts);
		table.clear(circleVisuals);
	end;
	local function spawnCircle(position, normal)
		if not __ALIVE() then return end;
		local style = styles[C.Style] or styles[DEFAULT_STYLE];
		local url = urlFor(style);
		local count, oldest, oldestAt = 0, nil, math.huge;
		for part, visual in pairs(circleVisuals) do
			count += 1;
			if visual.born < oldestAt then oldest, oldestAt = part, visual.born end;
		end;
		if count >= 24 and oldest then oldest:Destroy() end;

		local up = normal or Vector3.yAxis;
		local reference = (math.abs(up.Y) > 0.98) and Vector3.xAxis or Vector3.yAxis;
		local right = up:Cross(reference).Unit;
		local front = right:Cross(up).Unit;

		local part = Instance.new("Part");
		part.Name = "VisualsJumpCircle";
		part:SetAttribute(TAG, INIT_GENERATION);
		part.Anchored = true;
		part.CanCollide = false;
		part.CanQuery = false;
		part.CanTouch = false;
		part.CastShadow = false;
		part.Transparency = 1;
		part.Size = Vector3.new(0.2, 0.2, 0.2);
		part.CFrame = CFrame.fromMatrix(position + up * 0.08, right, up, front);
		circleParts[part] = true;
		part.Destroying:Once(function() circleParts[part] = nil; circleVisuals[part] = nil end);
		part.Parent = workspace;

		local surface = Instance.new("SurfaceGui");
		surface.Face, surface.Adornee = Enum.NormalId.Top, part;
		surface.AlwaysOnTop, surface.LightInfluence = false, 0;
		surface.CanvasSize, surface.Parent = Vector2.new(512, 512), part;
		local ring = Instance.new("Frame");
		ring.BackgroundTransparency, ring.Size = 1, UDim2.fromScale(0.94, 0.94);
		ring.Position, ring.BorderSizePixel, ring.Parent = UDim2.fromScale(0.03, 0.03), 0, surface;
		local corner = Instance.new("UICorner"); corner.CornerRadius, corner.Parent = UDim.new(1, 0), ring;
		local stroke = Instance.new("UIStroke");
		stroke.ApplyStrokeMode, stroke.Thickness = Enum.ApplyStrokeMode.Border, 7;
		stroke.Color, stroke.Parent = C.Color, ring;
		circleVisuals[part] = {
			born = os.clock(), life = C.Life, size = C.Size, grow = C.Grow / 100,
			bright = math.clamp(C.Bright / 100, 0, 1), stroke = stroke,
			base = part.CFrame, spin = math.rad(C.Spin),
		};
		part.Size = Vector3.new(C.Size * 0.35, 0.025, C.Size * 0.35);
		Debris:AddItem(part, C.Life + 0.4);
		if not url then return part end;
		local ok = pcall(function()

		local attach = Instance.new("Attachment");
		attach.Parent = part;

		local opacity = math.clamp(C.Bright / 100, 0, 1);

		local emitter = Instance.new("ParticleEmitter");
		emitter.Texture = url;
		emitter.Color = ColorSequence.new(C.Color);
		emitter.LightEmission = 1;
		emitter.LightInfluence = 0;
		emitter.Rate = 0;
		emitter.Lifetime = NumberRange.new(C.Life);
		emitter.Speed = NumberRange.new(0.01);
		emitter.Drag = 0;
		emitter.Acceleration = Vector3.zero;
		emitter.VelocityInheritance = 0;
		emitter.EmissionDirection = Enum.NormalId.Top;
		emitter.Rotation = NumberRange.new(0);
		emitter.RotSpeed = NumberRange.new(C.Spin);
		emitter.ZOffset = 0;

		pcall(function() emitter.Orientation = Enum.ParticleOrientation.VelocityPerpendicular end);

		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, C.Size * 0.35),
			NumberSequenceKeypoint.new(0.4, C.Size),
			NumberSequenceKeypoint.new(1, C.Size * C.Grow / 100),
		});

		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1 - opacity),
			NumberSequenceKeypoint.new(0.6, 1 - opacity * 0.55),
			NumberSequenceKeypoint.new(1, 1),
		});

		if style.frames and FLIPBOOK[style.cols] then
			pcall(function()
				emitter.FlipbookLayout = FLIPBOOK[style.cols];
				emitter.FlipbookMode = Enum.ParticleFlipbookMode.OneShot;
			end);
		end;

		emitter.Parent = attach;
		emitter:Emit(1);

		surface.Enabled = false;

		end);
		if not ok then
			for _, child in ipairs(part:GetChildren()) do if child:IsA("Attachment") then child:Destroy() end end;
		end;
		return part;
	end;

	local function wants(player)
		local isSelf = player == LocalPlayer;

		return C.Target == "All" or (isSelf and C.Target == "Self") or (not isSelf and C.Target == "Other");
	end;

	local state = {};
	local function rootFor(character, human)
		local root = human.RootPart or character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart;
		return root and root:IsA("BasePart") and root or nil;
	end;
	local function emitFor(record, position, normal)
		local now = os.clock();
		if record.lastCircleAt and now - record.lastCircleAt <= 0.22 and record.lastCirclePosition
			and (position - record.lastCirclePosition).Magnitude <= 5 then return false end;
		record.lastCircleAt, record.lastCirclePosition = now, position;
		spawnCircle(position, normal);
		return true;
	end;
	local function unhook(player)
		local record = state[player];
		if not record then return end;
		state[player] = nil;
		for _, conn in ipairs(record.conns) do conn:Disconnect() end;
		for _, conn in ipairs(record.humanConns or {}) do conn:Disconnect() end;
	end;
	local function takeoff(record, fromFloor)
		local root = rootFor(record.character, record.human);
		if not root then return end;
		if fromFloor and record.jumpDetected then record.air = true; return end;
		record.jumpDetected = true;
		local now = os.clock();
		if C.Jump and wants(record.player) and now - record.lastJump > 0.18 then
			record.lastJump = now;
			local position, normal = groundAt(record.character, root);
			emitFor(record, position, normal);
		end;
		record.air = true;
	end;
	local function landed(record)
		if record.air and C.Land and wants(record.player) then
			local root = rootFor(record.character, record.human);
			if root then
				local position, normal = groundAt(record.character, root);
				emitFor(record, position, normal);
			end;
		end;
		record.air = false;
		record.jumpDetected = false;
	end;
	local function watch(player)
		local function hook(character)
			unhook(player);
			local record = { player = player, character = character, conns = {}, humanConns = {}, lastJump = -math.huge };
			state[player] = record;
			local function attach(human)
				if (record.human and record.human.Parent) or not __ALIVE() or state[player] ~= record or player.Character ~= character then return end;
				for _, conn in ipairs(record.humanConns) do conn:Disconnect() end;
				table.clear(record.humanConns);
				record.human = human;
				record.air = human.FloorMaterial == Enum.Material.Air;
				record.floorAir = record.air;
				record.humanConns[#record.humanConns + 1] = human.StateChanged:Connect(function(_, new)
					if not __ALIVE() or state[player] ~= record then return end;
					if new == Enum.HumanoidStateType.Jumping then takeoff(record)
					elseif new == Enum.HumanoidStateType.Freefall then record.air = true
					elseif new == Enum.HumanoidStateType.Landed then landed(record) end;
				end);
				record.humanConns[#record.humanConns + 1] = human.Jumping:Connect(function(active)
					if __ALIVE() and active and state[player] == record then takeoff(record) end;
				end);
			end;
			record.conns[#record.conns + 1] = character.DescendantAdded:Connect(function(obj)
				if obj:IsA("Humanoid") then attach(obj) end;
			end);
			record.conns[#record.conns + 1] = character.ChildRemoved:Connect(function(obj)
				if obj == record.human then
					for _, conn in ipairs(record.humanConns) do conn:Disconnect() end;
					table.clear(record.humanConns); record.human = nil;
					local human = character:FindFirstChildOfClass("Humanoid");
					if human then attach(human) end;
				end;
			end);
			task.spawn(function()
				local human = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10);
				if human and __ALIVE() and character.Parent and player.Parent and player.Character == character then attach(human) end;
			end);
		end;
		if player.Character then hook(player.Character) end;
		NeverLose:AddPlayerSignal(player, player.CharacterAdded:Connect(hook));
		NeverLose:AddPlayerSignal(player, player.CharacterRemoving:Connect(function() unhook(player) end));
	end;
	local poll = 0;
	NeverLose:AddSignal(RunService.RenderStepped:Connect(function(dt)
		if not __ALIVE() then return end;
		local now = os.clock();
		for part, visual in pairs(circleVisuals) do
			local t = (now - visual.born) / visual.life;
			if t >= 1 or not part.Parent then part:Destroy()
			else
				local diameter = visual.size * (t < 0.4 and (0.35 + t / 0.4 * 0.65) or (1 + (visual.grow - 1) * (t - 0.4) / 0.6));
				part.Size = Vector3.new(diameter, 0.025, diameter);
				part.CFrame = visual.base * CFrame.Angles(0, visual.spin * (now - visual.born), 0);
				visual.stroke.Transparency = 1 - visual.bright * (1 - t) ^ 1.4;
			end;
		end;
		if not (C.Jump or C.Land) then return end;
		poll += dt;
		if poll < 0.04 then return end;
		poll = 0;
		for player, record in pairs(state) do
			local human, character = record.human, record.character;
			if human and human.Parent and character.Parent and player.Character == character and wants(player) then
				local root = rootFor(character, human);
				if root then
					local air = human.FloorMaterial == Enum.Material.Air;
					if air and not record.floorAir and root.AssemblyLinearVelocity.Y > 1 then takeoff(record, true)
					elseif not air and record.floorAir then landed(record) end;
					record.floorAir = air;
				end;
			end;
		end;
	end));
	for _, player in ipairs(Players:GetPlayers()) do watch(player) end;
	NeverLose:AddSignal(Players.PlayerAdded:Connect(watch));
	NeverLose:AddSignal(Players.PlayerRemoving:Connect(unhook));

	ESP.Circles = C;
	ESP.SpawnCircle = spawnCircle;

	ESP.ClearCircles = onUnload("circles", function()
		C.Jump, C.Land = false, false;
		clearActiveCircles();
		for player in pairs(state) do unhook(player) end;

		table.clear(state);
	end);

	local jumpRow = Sections.Circles:AddLabel("Jump Circle");
	jumpRow:AddToggle({ Default = false, Flag = "jump_circle", Callback = function(v)
		C.Jump = v;
		if not (C.Jump or C.Land) then clearActiveCircles() end;
	end });
	jumpRow:AddColorPicker({ Default = C.Color, Flag = "circle_color", Callback = function(v) C.Color = v end });

	Sections.Circles:AddLabel("Land Circle"):AddToggle({
		Default = false, Flag = "land_circle",
		Callback = function(v)
			C.Land = v;
			if not (C.Jump or C.Land) then clearActiveCircles() end;
		end,
	});

	Sections.Circles:AddLabel("Style"):AddDropdown({
		Default = DEFAULT_STYLE,
		Values = order,
		Flag = "circle_style",
		Callback = function(v)
			local nextStyle = canonicalStyle(v);
			if C.Style ~= nextStyle then clearActiveCircles() end;
			C.Style = nextStyle;
		end,
	});

	Sections.Circles:AddLabel("Size"):AddSlider({
		Min = 1, Max = 30, Default = 4, Rounding = 1, Size = 100,
		Flag = "circle_size",
		Callback = function(v) C.Size = v end,
	});

	Sections.Circles:AddLabel("Life"):AddSlider({
		Min = 2, Max = 40, Default = 8, Rounding = 0, Size = 100,
		Flag = "circle_life",
		Callback = function(v) C.Life = v / 10 end,
	});

	Sections.Circles:AddLabel("Grow"):AddSlider({
		Min = 100, Max = 400, Default = 220, Type = "%", Size = 100,
		Flag = "circle_grow",
		Callback = function(v) C.Grow = v end,
	});

	Sections.Circles:AddLabel("Brightness"):AddSlider({
		Min = 10, Max = 100, Default = 100, Type = "%", Size = 100,
		Flag = "circle_bright",
		Callback = function(v) C.Bright = v end,
	});

	Sections.Circles:AddLabel("Spin"):AddSlider({
		Min = 0, Max = 180, Default = 0, Rounding = 0, Size = 100,
		Flag = "circle_spin",
		Callback = function(v) C.Spin = v end,
	});

	Sections.Circles:AddLabel("Target"):AddDropdown({
		Default = "Self",
		Values = { "Self", "Other", "All" },
		Flag = "circle_target",
		Callback = function(v) C.Target = v end,
	});

	Sections.Circles:AddButton({
		Icon = "play-large",
		Name = "Test Circle",
		Callback = function()
			local char = LocalPlayer.Character;
			local root = char and char:FindFirstChild("HumanoidRootPart");

			if root then spawnCircle(groundAt(char, root)) end;
		end,
	});
end;
