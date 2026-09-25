--!nonstrict
--[[
	preview.lua — extracted feature module (require id "modules.preview").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("preview") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("preview", function()
			return require("modules.preview")({ ESP = ESP, LocalPlayer = LocalPlayer, NeverLose = NeverLose, Preview = Preview, Remote = Remote, RunService = RunService, S = S, Window = Window, onUnload = onUnload, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local Preview = ctx.Preview;
	local Remote = ctx.Remote;
	local RunService = ctx.RunService;
	local S = ctx.S;
	local Window = ctx.Window;
	local onUnload = ctx.onUnload;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("preview") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local UserInputService = game:GetService("UserInputService");
	local lib = NeverLose.Lib;
	local th = lib.theme;

	local WindowFrame;
	local function windowFrame()
		if WindowFrame and WindowFrame.Parent then return WindowFrame end;
		if NeverLose.WindowFrame and NeverLose.WindowFrame.Parent then
			WindowFrame = NeverLose.WindowFrame;
			return WindowFrame;
		end;
		for _, child in ipairs(NeverLose.ScreenGui:GetChildren()) do
			if child:IsA("Frame") and child.Active and child.AnchorPoint == Vector2.new(0.5, 0.5) then WindowFrame = child end;
		end;
		return WindowFrame;
	end;
	ESP.WindowFrame = windowFrame;

	local function make(class, props, parent)
		local object = Instance.new(class);
		for key, value in pairs(props) do object[key] = value end;
		object.Parent = parent;
		return object;
	end;

	local panel = make("Frame", {
		Name = NeverLose.RandomString(), BackgroundColor3 = Color3.fromRGB(8, 8, 13), BackgroundTransparency = 0.0255,
		BorderSizePixel = 0, ClipsDescendants = true, Visible = not NeverLose.Mobile, ZIndex = 0,
	}, NeverLose.ScreenGui);
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, panel);

	local icon = make("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 20),
		Size = UDim2.fromOffset(16, 16), TextColor3 = NeverLose.AccentColor, TextSize = 14, ZIndex = 4,
	}, panel);
	NeverLose.ApplyIcon(icon, "person");
	make("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1, Position = UDim2.new(0, 34, 0, 20),
		Size = UDim2.new(1, -70, 0, 14), Font = Enum.Font.GothamBold, Text = LocalPlayer.DisplayName,
		TextColor3 = th.text, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
	}, panel);
	local refresh = make("ImageButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0, 20), Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1, AutoButtonColor = false, ImageColor3 = th.dim, ZIndex = 5,
		Image = lib.icons["refresh-cw"] and ("rbxassetid://" .. lib.icons["refresh-cw"]) or "",
	}, panel);

	local peek = make("TextButton", {
		Name = NeverLose.RandomString(), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(22, 52),
		BackgroundColor3 = Color3.fromRGB(8, 8, 13), BackgroundTransparency = 0.0255, BorderSizePixel = 0,
		AutoButtonColor = false, Text = "", Visible = false, ZIndex = 0,
	}, NeverLose.ScreenGui);
	make("UICorner", { CornerRadius = UDim.new(0, 7) }, peek);
	local peekArrow = make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 4, 0.5, 0), Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1, ImageColor3 = th.dim, ZIndex = 1,
		Image = lib.icons["chevron-right"] and ("rbxassetid://" .. lib.icons["chevron-right"]) or "",
	}, peek);
	NeverLose:AddSignal(peek.MouseEnter:Connect(function() peekArrow.ImageColor3 = th.text end));
	NeverLose:AddSignal(peek.MouseLeave:Connect(function() peekArrow.ImageColor3 = th.dim end));
	make("Frame", {
		BackgroundColor3 = th.line, BackgroundTransparency = 0.5, BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 0, 40), Size = UDim2.new(1, -24, 0, 1), ZIndex = 4,
	}, panel);

	local stage = make("Frame", {
		Position = UDim2.fromOffset(0, 41), Size = UDim2.new(1, 0, 1, -41), BackgroundColor3 = th.panel,
		BorderSizePixel = 0, ClipsDescendants = true, Active = true, ZIndex = 1,
	}, panel);
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, stage);
	make("UIGradient", {
		Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 165)),
	}, stage);

	local glow = make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(1.15, 0.85),
		BackgroundTransparency = 1, ImageTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 2,
	}, stage);
	task.spawn(function()
		local id = Remote.id(Remote.file("particles/p_glow.png"));
		if id and glow.Parent then glow.Image = id end;
	end);

	local floor = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.9), Size = UDim2.new(0.55, 0, 0, 10),
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 2,
	}, stage);
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, floor);
	make("UIGradient", { Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1),
	}) }, floor);

	local view = make("ViewportFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 208),
		LightColor = Color3.fromRGB(255, 250, 242), LightDirection = Vector3.new(-0.4, -0.9, -0.6), ZIndex = 3,
	}, stage);
	local world = make("WorldModel", {}, view);
	local camera = make("Camera", { FieldOfView = 30 }, view);
	view.CurrentCamera = camera;

	local overlay = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6 }, stage);

	local BODY = {
		Head = true, Torso = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true,
		UpperTorso = true, LowerTorso = true, LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
		RightUpperArm = true, RightLowerArm = true, RightHand = true, LeftUpperLeg = true, LeftLowerLeg = true,
		LeftFoot = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
	};
	local model, center, extents = nil, Vector3.zero, Vector3.new(4, 5, 2);
	local DROP = {
		LuaSourceContainer = true, Sound = true, ForceField = true, Highlight = true, BillboardGui = true,
		ParticleEmitter = true, Trail = true, Beam = true, Light = true, Fire = true, Smoke = true, Sparkles = true,
		SelectionBox = true, BoxHandleAdornment = true,
	};

	local function dropModel()
		if model then
			pcall(ESP.Restore, model);
			model:Destroy();
			model = nil;
		end;
	end;

	local refreshing, refreshId = false, 0;
	function Preview.Refresh()
		refreshId += 1;
		local coldStart = model == nil;
		if refreshing then return end;
		refreshing = true;

		task.spawn(function()

			task.wait(coldStart and 0.25 or 0);
			while __ALIVE() do
				local id, char = refreshId, LocalPlayer.Character;
				if not (char and char.Parent) then break end;

				local archivable = char.Archivable;
				char.Archivable = true;
				local ok, clone = pcall(function() return char:Clone() end);
				char.Archivable = archivable;
				if not (ok and clone) then
					if id == refreshId then break end;
					continue;
				end;

				for index, item in ipairs(clone:GetDescendants()) do
					pcall(function()
						local drop = false;
						for class in pairs(DROP) do
							if item:IsA(class) then drop = true; break end;
						end;
						if drop then
							item:Destroy();
						elseif item:IsA("BasePart") then
							item.Anchored, item.CanCollide, item.CanQuery, item.CanTouch = true, false, false, false;
							item.LocalTransparencyModifier = 0;
						end;
					end);
					if index % 48 == 0 then task.wait() end;
					if not __ALIVE() or id ~= refreshId then break end;
				end;
				if not __ALIVE() then clone:Destroy(); break end;
				if id ~= refreshId or LocalPlayer.Character ~= char then clone:Destroy(); continue end;

				local humanoid = clone:FindFirstChildOfClass("Humanoid");
				if humanoid then
					humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
					pcall(function() humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff end);
				end;

				local root = clone:FindFirstChild("HumanoidRootPart") or clone:FindFirstChild("UpperTorso") or clone:FindFirstChild("Torso");
				if not root then
					clone:Destroy();
					if id == refreshId then break end;
					continue;
				end;
				clone.PrimaryPart = root;
				clone:PivotTo(CFrame.Angles(0, math.pi, 0));

				local x0, y0, z0, x1, y1, z1 = math.huge, math.huge, math.huge, -math.huge, -math.huge, -math.huge;
				for _, part in ipairs(clone:GetChildren()) do
					if part:IsA("BasePart") and BODY[part.Name] then
						local half = part.Size / 2;
						for _, sx in ipairs({ -1, 1 }) do for _, sy in ipairs({ -1, 1 }) do for _, sz in ipairs({ -1, 1 }) do
							local p = part.CFrame * Vector3.new(half.X * sx, half.Y * sy, half.Z * sz);
							x0, y0, z0 = math.min(x0, p.X), math.min(y0, p.Y), math.min(z0, p.Z);
							x1, y1, z1 = math.max(x1, p.X), math.max(y1, p.Y), math.max(z1, p.Z);
						end end end;
					end;
				end;
				if id ~= refreshId or LocalPlayer.Character ~= char then clone:Destroy(); continue end;

				dropModel();
				clone.Parent, model = world, clone;
				if x1 > x0 then
					center, extents = Vector3.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), Vector3.new(x1 - x0, y1 - y0, z1 - z0);
				else
					local cf, size = clone:GetBoundingBox();
					center, extents = cf.Position, size;
				end;
				if Preview.Paint then pcall(Preview.Paint) end;
				if id == refreshId then break end;
			end;
			refreshing = false;
		end);
	end;

	NeverLose:AddSignal(refresh.MouseButton1Click:Connect(function()
		pcall(function() lib:chime("tap") end);
		Preview.Refresh();
	end));

	local yaw, zoom, dragging, lastX = 0, 1, false, nil;

	local function aim()
		local size = view.AbsoluteSize;
		if size.X < 2 or size.Y < 2 then return end;
		local half = math.tan(math.rad(camera.FieldOfView) / 2);
		local aspect = size.X / size.Y;
		local fit = math.max(extents.Y / 2 / half, math.max(extents.X, extents.Z) / 2 / (half * aspect));
		local distance = (fit * 1.25 + extents.Z / 2) * zoom;
		local target = center + Vector3.new(0, extents.Y * 0.02, 0);
		camera.CFrame = CFrame.lookAt(target + Vector3.new(math.sin(yaw), 0.1, math.cos(yaw)).Unit * distance, target);
	end;

	NeverLose:AddSignal(stage.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, lastX = true, input.Position.X;
		end;
	end));
	NeverLose:AddSignal(stage.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			zoom = math.clamp(zoom * (input.Position.Z > 0 and 0.86 or 1.16), 0.45, 2.5);
			aim();
		end;
	end));
	NeverLose:AddSignal(UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end;
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local dx = input.Position.X - (lastX or input.Position.X);
			lastX = input.Position.X;
			yaw -= dx * 0.012;
		end;
	end));
	NeverLose:AddSignal(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false;
		end;
	end));

	local function project(point)
		local rel = camera.CFrame:PointToObjectSpace(point);
		if rel.Z > -0.05 then return nil end;
		local size = view.AbsoluteSize;
		local f = size.Y / 2 / math.tan(math.rad(camera.FieldOfView) / 2);
		return Vector2.new(size.X / 2 + rel.X / -rel.Z * f, size.Y / 2 - rel.Y / -rel.Z * f);
	end;

	local pool, used = {}, 0;
	local function bar()
		used += 1;
		local frame = pool[used];
		if not frame then
			frame = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = 7 }, overlay);
			pool[used] = frame;
		end;
		frame.Visible = true;
		return frame;
	end;
	local function line(a, b, color, thick)
		local d = b - a;
		local frame = bar();
		frame.BackgroundColor3, frame.BackgroundTransparency = color, 0;
		frame.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2);
		frame.Size = UDim2.fromOffset(d.Magnitude + thick * 0.5, thick);
		frame.Rotation = math.deg(math.atan2(d.Y, d.X));
	end;

	local fill = make("Frame", { BorderSizePixel = 0, Visible = false, ZIndex = 6 }, overlay);
	local function label(size)
		return make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
			TextSize = size, TextStrokeTransparency = 0.5, Size = UDim2.fromOffset(160, 14), Visible = false, ZIndex = 8,
		}, overlay);
	end;
	local nameTag, distTag = label(12), label(11);

	local BONES = {
		{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
		{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
		{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
		{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
		{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
		{ "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" }, { "Torso", "Left Leg" }, { "Torso", "Right Leg" },
	};

	local function drawOverlay()
		used = 0;
		fill.Visible, nameTag.Visible, distTag.Visible = false, false, false;

		if model and S.Enabled then
			local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge;
			for _, part in ipairs(model:GetChildren()) do
				if part:IsA("BasePart") and BODY[part.Name] then
					local half = part.Size / 2;
					for _, sx in ipairs({ -1, 1 }) do for _, sy in ipairs({ -1, 1 }) do for _, sz in ipairs({ -1, 1 }) do
						local p = project(part.CFrame * Vector3.new(half.X * sx, half.Y * sy, half.Z * sz));
						if p then x0, y0, x1, y1 = math.min(x0, p.X), math.min(y0, p.Y), math.max(x1, p.X), math.max(y1, p.Y) end;
					end end end;
				end;
			end;

			if x1 > x0 then
				local a, b = Vector2.new(x0 - 3, y0 - 3), Vector2.new(x1 + 3, y1 + 3);
				local thick = math.clamp(tonumber(S.BoxThickness) or 1, 1, 4);

				if S.Box then
					local tl, tr, bl, br = a, Vector2.new(b.X, a.Y), Vector2.new(a.X, b.Y), b;
					if S.BoxStyle == "Corner" then
						local cx, cy = (b.X - a.X) * 0.25, (b.Y - a.Y) * 0.2;
						line(tl, tl + Vector2.new(cx, 0), S.BoxColor, thick); line(tl, tl + Vector2.new(0, cy), S.BoxColor, thick);
						line(tr, tr - Vector2.new(cx, 0), S.BoxColor, thick); line(tr, tr + Vector2.new(0, cy), S.BoxColor, thick);
						line(bl, bl + Vector2.new(cx, 0), S.BoxColor, thick); line(bl, bl - Vector2.new(0, cy), S.BoxColor, thick);
						line(br, br - Vector2.new(cx, 0), S.BoxColor, thick); line(br, br - Vector2.new(0, cy), S.BoxColor, thick);
					else
						line(tl, tr, S.BoxColor, thick); line(bl, br, S.BoxColor, thick);
						line(tl, bl, S.BoxColor, thick); line(tr, br, S.BoxColor, thick);
					end;
					if S.BoxFilled then
						fill.Visible = true;
						fill.BackgroundColor3, fill.BackgroundTransparency = S.BoxColor, 0.82;
						fill.Position, fill.Size = UDim2.fromOffset(a.X, a.Y), UDim2.fromOffset(b.X - a.X, b.Y - a.Y);
					end;
				end;

				if S.Name then
					nameTag.Visible = true;
					nameTag.Text, nameTag.TextColor3 = LocalPlayer.DisplayName, S.NameColor;
					nameTag.Position = UDim2.fromOffset((a.X + b.X) / 2, a.Y - 9);
				end;
				if S.Distance then
					distTag.Visible = true;
					distTag.Text, distTag.TextColor3 = ("%dm"):format(math.floor((camera.CFrame.Position - center).Magnitude + 0.5)), S.NameColor;
					distTag.Position = UDim2.fromOffset((a.X + b.X) / 2, b.Y + 9);
				end;
			end;

			if S.Skeleton then
				for _, bone in ipairs(BONES) do
					local p, q = model:FindFirstChild(bone[1]), model:FindFirstChild(bone[2]);
					if p and q and p:IsA("BasePart") and q:IsA("BasePart") then
						local pa, pb = project(p.Position), project(q.Position);
						if pa and pb then line(pa, pb, S.SkeletonColor, 1) end;
					end;
				end;
			end;
		end;

		for i = used + 1, #pool do pool[i].Visible = false end;
	end;

	local glowOn, glowColor = false, Color3.new(1, 1, 1);
	function Preview.ReadAura()
		local A = ESP.Aura;
		glowOn = A and A.On and true or false;
		glowColor = (A and A.Color) or glowColor;
	end;

	local TweenService = game:GetService("TweenService");
	local folded, moving = false, false;

	local function spots()
		local wf = windowFrame();
		local cam = workspace.CurrentCamera;
		local view = (cam and cam.ViewportSize) or Vector2.new(1280, 720);
		local size = (wf and wf.AbsoluteSize) or Vector2.new(640, 480);
		local at = (wf and wf.AbsolutePosition) or (view / 2 - size / 2);

		local o = NeverLose.ScreenGui.AbsolutePosition;
		local width = math.floor(size.Y * 0.46);
		local gap = 16;
		local right = at.X + size.X + gap + width <= view.X;
		local edge = right and at.X + size.X or at.X;

		return {
			right = right, width = width, height = size.Y, y = at.Y - o.Y,
			open = (right and edge + gap or edge - gap - width) - o.X,
			tucked = (right and edge - width - 16 or edge + 16) - o.X,
			edge = edge - o.X, mid = at.Y + size.Y / 2 - o.Y,
		};
	end;

	local function aim(s)
		local outward = folded;
		peekArrow.Rotation = (s.right == outward) and 0 or 180;
		peekArrow.Position = UDim2.new(0.5, s.right and 4 or -4, 0.5, 0);
	end;

	local function placePeek(hidden)
		local s = spots();

		local x = s.right and s.edge - 10 or s.edge + 10;
		if hidden then x = s.right and s.edge - 22 or s.edge + 22 end;
		peek.AnchorPoint = Vector2.new(s.right and 0 or 1, 0.5);
		return UDim2.fromOffset(x, s.mid), s;
	end;

	local function place()
		local position, s = placePeek(false);
		peek.Position = position;
		aim(s);
		if moving or folded then return end;
		panel.Size = UDim2.fromOffset(s.width, s.height);
		panel.Position = UDim2.fromOffset(s.open, s.y);
	end;

	local function glide(object, time, goal, direction)
		local t = TweenService:Create(object, TweenInfo.new(time, Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), goal);
		t:Play();
		return t;
	end;

	local function slide()
		local s = spots();
		moving = true;
		glide(peekArrow, 0.25, { Rotation = (s.right == folded) and 0 or 180 });

		if folded then
			glide(panel, 0.26, { Position = UDim2.fromOffset(s.tucked, s.y) }, Enum.EasingDirection.In);
			task.delay(0.26, function()
				moving = false;
				if folded then panel.Visible = false end;
			end);
		else
			panel.Size = UDim2.fromOffset(s.width, s.height);
			panel.Position = UDim2.fromOffset(s.tucked, s.y);
			panel.Visible = not NeverLose.Mobile;
			glide(panel, 0.3, { Position = UDim2.fromOffset(s.open, s.y) });
			task.delay(0.3, function() moving = false; place() end);
		end;
	end;

	function Preview.SetShown(value)
		local want = not value;
		if folded == want then return end;
		folded = want;
		pcall(function() lib:chime("tap") end);
		slide();
	end;
	function Preview.Shown() return not folded end;

	NeverLose:AddSignal(peek.MouseButton1Click:Connect(function() Preview.SetShown(folded) end));

	do
		local hooked;
		local function hook()
			local wf = windowFrame();
			if wf and wf ~= hooked then
				hooked = wf;
				NeverLose:AddSignal(wf:GetPropertyChangedSignal("AbsolutePosition"):Connect(place));
				NeverLose:AddSignal(wf:GetPropertyChangedSignal("AbsoluteSize"):Connect(place));
			end;
		end;
		hook();
		NeverLose:AddSignal(NeverLose.ScreenGui.ChildAdded:Connect(function() hook(); place() end));
	end;

	NeverLose:AddSignal(Window.Signal:Connect(function(open)
		panel.Visible = open and not NeverLose.Mobile and not folded;
		peek.Visible = open and not NeverLose.Mobile;
		place();
	end));

	peek.Visible = lib.shown == true and not NeverLose.Mobile;
	task.defer(place);

	local dirty, dirtyAt = false, 0;
	local function stale() dirty, dirtyAt = true, os.clock() end;

	NeverLose:AddSignal(LocalPlayer.CharacterAdded:Connect(function()
		dropModel();
		task.delay(1, function() if __ALIVE() then stale() end end);
	end));
	NeverLose:AddSignal(LocalPlayer.CharacterAppearanceLoaded:Connect(stale));
	NeverLose:AddSignal(LocalPlayer.CharacterRemoving:Connect(dropModel));
	if ESP.GameFX and ESP.GameFX.OnChange then ESP.GameFX.OnChange(stale) end;

	local LOOKS = { "model", "korblox", "headless", "hairless", "no_accessories", "character", "cosmetic", "aura", "china" };
	function Preview.Queue(flag)
		if type(flag) ~= "string" then return end;
		for _, prefix in ipairs(LOOKS) do
			if string.sub(flag, 1, #prefix) == prefix then stale(); return end;
		end;
		if Preview.Paint then pcall(Preview.Paint) end;
	end;

	local glowPulse = 0;
	NeverLose:AddSignal(RunService.RenderStepped:Connect(function(dt)
		if not panel.Visible then return end;
		if dirty and os.clock() - dirtyAt > 0.4 and not lib.configApplying then
			dirty = false;
			pcall(Preview.Refresh);
		end;
		aim();
		drawOverlay();
		glowPulse += dt;
		local target = glowOn and (0.35 + math.sin(glowPulse * 2) * 0.06) or 1;
		glow.ImageTransparency += (target - glow.ImageTransparency) * math.min(dt * 6, 1);
		glow.ImageColor3 = glowColor;
	end));

	Preview.Panel = panel;
	Preview.Viewport = view;
	Preview.Model = function() return model end;
	ESP.Preview = Preview;

	Preview.ReadAura();
	Preview.Refresh();
	place();
	task.defer(function() if Preview.Paint then pcall(Preview.Paint) end end);

	onUnload("preview", function()
		dropModel();
		pcall(function() panel:Destroy() end);
		pcall(function() peek:Destroy() end);
	end);
end;
