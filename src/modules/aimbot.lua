--!nonstrict
--[[
	aimbot.lua — extracted feature module (require id "modules.aimbot").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("aimbot") in the driver — byte-frozen original
	code below the marker (re-derived on every `make extract`; do not hand-edit).

	The block originally closed over driver locals; the driver now passes them
	in via the ctx table:

		guard("aimbot", function()
			return require("modules.aimbot")({ ESP = ESP, LocalPlayer = LocalPlayer, NeverLose = NeverLose, Notification = Notification, Players = Players, RunService = RunService, Sections = Sections, onUnload = onUnload });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local Notification = ctx.Notification;
	local Players = ctx.Players;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local onUnload = ctx.onUnload;

-- [ guard("aimbot") callback body — byte-exact from input/message(47).txt ]
	local A = {
		On = false, Key = "E", RightMouse = true, Mode = "Hold", Method = "Camera", TurnCamera = true,
		Fov = 220, Smooth = 3, Part = "Head", Priority = "Crosshair",
		Visible = true, Range = 0,
		TeamCheck = true, IgnoreFriends = false,
		Bots = false, BotsOnly = false,
		Trigger = false, TriggerDelay = 150,
		Circle = true, DynamicCircle = false, CircleColor = Color3.fromRGB(255, 84, 84), CircleFilled = false,
	};

	ESP.Aimbot = A;

	local uis = game:GetService("UserInputService");
	local AIM_STEP = "NeverLoseAimbot";
	local PARTS = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" };

	local circle, stepConn = nil, nil;
	local lastShot = 0;
	local alive = true;

	local function ensureCircle()
		if circle then return circle end;

		local ok, drawn = pcall(function() return Drawing.new("Circle") end);

		if not ok or not drawn then return nil end;

		drawn.Thickness = 1.5;
		drawn.NumSides = 96;
		drawn.Filled = false;
		drawn.Visible = false;
		drawn.Radius = A.Fov;

		circle = drawn;

		return circle;
	end;

	local aimToggled = false;

	local function keyDown()
		if A.Key and A.Key ~= "" then
			local ok, key = pcall(function() return Enum.KeyCode[A.Key] end);

			if ok and key and uis:IsKeyDown(key) then return true end;
		end;

		return A.RightMouse and uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
	end;

	local function active()
		if A.Mode == "Toggle" then
			return aimToggled or (A.RightMouse and uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2));
		end;

		return keyDown();
	end;

	NeverLose:AddSignal(uis.InputBegan:Connect(function(input, processed)
		if processed or A.Mode ~= "Toggle" or not (A.On or A.Trigger) then return end;

		if input.UserInputType ~= Enum.UserInputType.Keyboard or not A.Key or A.Key == "" then return end;

		local ok, key = pcall(function() return Enum.KeyCode[A.Key] end);

		if ok and key and input.KeyCode == key then aimToggled = not aimToggled end;
	end));

	local friendCache = {};

	local function isTeammate(player)
		if player == LocalPlayer then return false end;

		local mine, theirs = LocalPlayer.Team, player.Team;

		if mine and theirs and mine == theirs then return true end;

		if LocalPlayer.TeamColor and player.TeamColor
			and LocalPlayer.TeamColor == player.TeamColor
			and LocalPlayer.Neutral == false and player.Neutral == false then
			return true;
		end;

		return false;
	end;

	local function isFriend(player)
		if player == LocalPlayer then return false end;

		local cached = friendCache[player.UserId];

		if cached ~= nil then return cached end;

		friendCache[player.UserId] = false;

		task.spawn(function()
			local ok, result = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end);

			friendCache[player.UserId] = (ok and result == true) or false;
		end);

		return false;
	end;

	local function botHolder()
		local highlight = workspace:FindFirstChild("Highlight");
		local enemy = highlight and highlight:FindFirstChild("Enemy");

		return enemy and enemy:FindFirstChild("HighlightHolder") or nil;
	end;

	local function botParts(bot)
		local list = {};

		if not (bot and bot.Parent) then return list end;

		local collider = bot:FindFirstChild("Collider");
		local head = collider and collider:FindFirstChild("Head");

		if not (head and head:IsA("BasePart")) then head = bot:FindFirstChild("Head", true) end;
		if not head then head = bot:FindFirstChildWhichIsA("BasePart", true) end;

		if head and head:IsA("BasePart") then list[#list + 1] = head end;

		if A.Part ~= "Head" and #list > 0 then
			local body;

			if collider then
				body = collider:IsA("BasePart") and collider or collider:FindFirstChildWhichIsA("BasePart");
			end;

			if not body then body = bot:FindFirstChildWhichIsA("BasePart", true) end;

			if body and body ~= head and body:IsA("BasePart") then list[#list + 1] = body end;
		end;

		return list;
	end;

	local function botHealth(bot)
		local human = bot:FindFirstChildWhichIsA("Humanoid");

		return human and human.Health or math.huge;
	end;

	local function aimParts(character)
		local list = {};

		if A.Part == "Closest" then
			for _, name in ipairs(PARTS) do
				local part = character:FindFirstChild(name);

				if part then list[#list + 1] = part end;
			end;
		else
			local name = A.Part == "Upper Torso" and "UpperTorso"
				or A.Part == "Lower Torso" and "LowerTorso"
				or A.Part == "HumanoidRootPart" and "HumanoidRootPart"
				or "Head";
			local part = character:FindFirstChild(name) or character:FindFirstChild("Head");

			if part then list[1] = part end;
		end;

		return list;
	end;

	local function pick(camera, center)
		local best, bestPoint, bestScore = nil, nil, nil;
		local origin = camera.CFrame.Position;

		local function scan(part, distance, health)
			if not (part and part.Parent) then return end;

			local at, onScreen = camera:WorldToViewportPoint(part.Position);

			if not onScreen or at.Z <= 0 then return end;

			local span = (Vector2.new(at.X, at.Y) - center).Magnitude;

			if span > A.Fov then return end;

			local score = A.Priority == "Closest" and distance
				or A.Priority == "Health" and health
				or span;

			if not bestScore or score < bestScore then
				best, bestPoint, bestScore = part, part.Position, score;
			end;
		end;

		if not A.BotsOnly then
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer
					and not (A.TeamCheck and isTeammate(player))
					and not (A.IgnoreFriends and isFriend(player)) then

					local character = player.Character;
					local root = character and character:FindFirstChild("HumanoidRootPart");
					local human = character and character:FindFirstChildWhichIsA("Humanoid");

					if root and human and human.Health > 0 then
						local distance = (root.Position - origin).Magnitude;

						if A.Range <= 0 or distance <= A.Range then
							if not A.Visible or ESP.Visibility.Character(camera, character, root) then
								for _, part in ipairs(aimParts(character)) do
									scan(part, distance, human.Health);
								end;
							end;
						end;
					end;
				end;
			end;
		end;

		if A.Bots then
			local holder = botHolder();

			if holder then
				for _, bot in ipairs(holder:GetChildren()) do
					local parts = botParts(bot);

					if #parts > 0 then
						local head = parts[1];
						local distance = (head.Position - origin).Magnitude;

						if (A.Range <= 0 or distance <= A.Range)
							and (not A.Visible or ESP.Visibility.Character(camera, bot, head)) then
							local health = botHealth(bot);

							for _, part in ipairs(parts) do
								scan(part, distance, health);
							end;
						end;
					end;
				end;
			end;
		end;

		return best, bestPoint, bestScore;
	end;

	local mouse = LocalPlayer:GetMouse();

	local mouseRel = nil;
	local vim = nil;

	if type(mousemoverel) == "function" then
		mouseRel = mousemoverel;
	elseif type(getgenv) == "function" then
		local ok, env = pcall(getgenv);

		if ok and type(env) == "table" and type(env.mousemoverel) == "function" then
			mouseRel = env.mousemoverel;
		end;
	end;

	pcall(function() vim = game:GetService("VirtualInputManager") end);

	local vimCursor = nil;

	local function moveMouse(dx, dy)
		if mouseRel then return pcall(mouseRel, dx, dy) end;
		if not vim then return false end;

		local raw = Vector2.new(mouse.X, mouse.Y);

		if not vimCursor or (raw - vimCursor).Magnitude > 60 then vimCursor = raw end;

		vimCursor = vimCursor + Vector2.new(dx, dy);

		pcall(function() vim:SendMouseMoveEvent(vimCursor.X, vimCursor.Y, game) end);

		return true;
	end;

	local function aimMouse(camera, position)
		local at = camera:WorldToViewportPoint(position);

		if not at or at.Z <= 0 then return end;

		local gain = 1 / math.max(1, A.Smooth);

		moveMouse((at.X - mouse.X) * gain, (at.Y - mouse.Y) * gain);
	end;

	local function aim(camera, position)
		local viaMouse = A.Method == "Mouse" and (mouseRel or vim);

		if viaMouse then aimMouse(camera, position) end;

		if viaMouse and not A.TurnCamera then return end;

		local alpha = 1 / math.max(1, A.Smooth);
		local desired = CFrame.lookAt(camera.CFrame.Position, position);

		camera.CFrame = camera.CFrame:Lerp(desired, alpha);
	end;

	local function fire()
		local now = os.clock();

		if now - lastShot < (A.TriggerDelay / 1000) then return end;

		local character = LocalPlayer.Character;
		local tool = character and character:FindFirstChildOfClass("Tool");

		if not tool then return end;

		local name = string.lower(tool.Name);
		local gun = tool:FindFirstChild("GunClient") or tool:FindFirstChild("KnifeClient")
			or string.find(name, "gun", 1, true) or string.find(name, "revolver", 1, true)
			or string.find(name, "knife", 1, true) or string.find(name, "blade", 1, true);

		if not gun then return end;

		lastShot = now;

		pcall(function() tool:Activate() end);
	end;

	local function step()
		local camera = workspace.CurrentCamera;

		if not camera then
			if circle then circle.Visible = false end;

			return;
		end;

		local size = camera.ViewportSize;
		local center = Vector2.new(size.X * 0.5, size.Y * 0.5);
		local enabled = A.On or A.Trigger;
		local position = nil;

		if enabled then
			local character = LocalPlayer.Character;
			local human = character and character:FindFirstChildWhichIsA("Humanoid");

			if human and human.Health > 0 and active() then
				local _, found = pick(camera, center);

				position = found;
			end;
		end;

		if A.Circle and enabled then
			local drawn = ensureCircle();

			if drawn then
				local colour = A.CircleColor;

				if A.DynamicCircle then
					colour = position and A.CircleColor or Color3.new(1, 1, 1);
				end;

				drawn.Position = center;
				drawn.Radius = A.Fov;
				drawn.Color = colour;
				drawn.Filled = A.CircleFilled;
				drawn.Visible = true;
			end;
		elseif circle then
			circle.Visible = false;
		end;

		if not enabled then
			aimToggled = false;

			return;
		end;

		if not position then return end;

		if A.On then aim(camera, position) end;
		if A.Trigger then fire() end;
	end;

	local bound = pcall(function()
		RunService:BindToRenderStep(AIM_STEP, Enum.RenderPriority.Camera.Value + 1, step);
	end);

	if not bound then
		stepConn = RunService.RenderStepped:Connect(step);
	end;

	Sections.Aimbot:AddLabel("Aimbot"):AddToggle({
		Default = false, Flag = "aim_on",
		ToolTip = "Hold the aim key to lock onto targets",
		Callback = function(v) A.On = v end,
	});

	Sections.Aimbot:AddLabel("Aim Key"):AddKeybind({
		Default = "E", Flag = "aim_key",
		Callback = function(v) A.Key = v end,
	});

	Sections.Aimbot:AddLabel("Aim Mode"):AddDropdown({
		Default = "Hold",
		Values = { "Hold", "Toggle" },
		Flag = "aim_mode",
		ToolTip = "Hold: aim while the key is down. Toggle: press once to aim",
		Callback = function(v)
			A.Mode = v == "Toggle" and "Toggle" or "Hold";
			aimToggled = false;
		end,
	});

	Sections.Aimbot:AddLabel("Aim Method"):AddDropdown({
		Default = "Camera",
		Values = { "Camera", "Mouse" },
		Flag = "aim_method",
		ToolTip = "Camera: turns your view onto the target. Mouse: moves the cursor onto the target (works best with right mouse or shift lock)",
		Callback = function(v)
			A.Method = v == "Mouse" and "Mouse" or "Camera";

			if A.Method == "Mouse" and not mouseRel and not vim then
				Notification.new({
					Title = "Aimbot",
					Content = "no mouse control available - using camera",
					Duration = 4,
				});
			end;
		end,
	});

	Sections.Aimbot:AddLabel("Turn Camera"):AddToggle({
		Default = true, Flag = "aim_turn_cam",
		ToolTip = "Mouse method: also rotate the view onto the target while the cursor locks to it",
		Callback = function(v) A.TurnCamera = v end,
	});

	Sections.Aimbot:AddLabel("Right Mouse"):AddToggle({
		Default = true, Flag = "aim_rmb",
		ToolTip = "Also aim while holding right mouse",
		Callback = function(v) A.RightMouse = v end,
	});

	Sections.Aimbot:AddLabel("Smoothness"):AddSlider({
		Min = 1, Max = 20, Default = 3, Rounding = 0, Size = 90,
		Flag = "aim_smooth",
		Callback = function(v) A.Smooth = v end,
	});

	Sections.Aimbot:AddLabel("Target Part"):AddDropdown({
		Default = "Head",
		Values = { "Head", "Upper Torso", "Lower Torso", "HumanoidRootPart", "Closest" },
		Flag = "aim_part",
		Callback = function(v) A.Part = v end,
	});

	Sections.AimTarget:AddLabel("Team Check"):AddToggle({
		Default = true, Flag = "aim_team",
		ToolTip = "Skip players on your team",
		Callback = function(v) A.TeamCheck = v end,
	});

	Sections.AimTarget:AddLabel("Ignore Friends"):AddToggle({
		Default = false, Flag = "aim_friends",
		ToolTip = "Skip players on your Roblox friends list",
		Callback = function(v) A.IgnoreFriends = v end,
	});

	Sections.AimTarget:AddLabel("Priority"):AddDropdown({
		Default = "Crosshair",
		Values = { "Crosshair", "Closest", "Health" },
		Flag = "aim_priority",
		ToolTip = "Crosshair: nearest to your crosshair. Closest: nearest to you. Health: lowest health first",
		Callback = function(v) A.Priority = v end,
	});

	Sections.AimTarget:AddLabel("Visible Only"):AddToggle({
		Default = true, Flag = "aim_visible",
		ToolTip = "Ignore targets behind walls",
		Callback = function(v) A.Visible = v end,
	});

	Sections.AimTarget:AddLabel("FOV Radius"):AddSlider({
		Min = 10, Max = 600, Default = 220, Rounding = 0, Size = 90,
		Flag = "aim_fov",
		Callback = function(v) A.Fov = v end,
	});

	Sections.AimTarget:AddLabel("Max Distance"):AddSlider({
		Min = 0, Max = 1000, Default = 0, Type = "m", Rounding = 0, Size = 90,
		Flag = "aim_range",
		Callback = function(v) A.Range = v end,
	});

	Sections.AimTrigger:AddLabel("Triggerbot"):AddToggle({
		Default = false, Flag = "aim_trigger",
		ToolTip = "Shoots while the aim key is held and you are on a target",
		Callback = function(v) A.Trigger = v end,
	});

	Sections.AimTrigger:AddLabel("Fire Delay"):AddSlider({
		Min = 0, Max = 1000, Default = 150, Type = "ms", Rounding = 0, Size = 90,
		Flag = "aim_fire_delay",
		Callback = function(v) A.TriggerDelay = v end,
	});

	Sections.AimFov:AddLabel("Show Circle"):AddToggle({
		Default = true, Flag = "aim_circle",
		ToolTip = "Draws the aim FOV in the middle of the screen",
		Callback = function(v) A.Circle = v end,
	});

	Sections.AimFov:AddLabel("Dynamic Color"):AddToggle({
		Default = false, Flag = "aim_circle_dynamic",
		ToolTip = "Red while locked onto a target, white when nothing is locked",
		Callback = function(v) A.DynamicCircle = v end,
	});

	Sections.AimFov:AddLabel("Circle Color"):AddColorPicker({
		Default = A.CircleColor, Flag = "aim_circle_color",
		Callback = function(v) A.CircleColor = v end,
	});

	Sections.AimFov:AddLabel("Filled"):AddToggle({
		Default = false, Flag = "aim_circle_filled",
		Callback = function(v) A.CircleFilled = v end,
	});

	local detectedRow = Sections.SniperAim:AddLabel("Bots Found", true);
	local namesRow = Sections.SniperBots:AddLabel("Names", true);

	local botsRow = Sections.SniperAim:AddLabel("Aim at Bots"):AddToggle({
		Default = false, Flag = "aim_bots",
		ToolTip = "Targets the AI under workspace.Highlight.Enemy.HighlightHolder - names are random, they are found each frame",
		Callback = function(v) A.Bots = v end,
	});

	Sections.SniperBots:AddLabel("Bots Only"):AddToggle({
		Default = false, Flag = "aim_bots_only",
		ToolTip = "Ignores real players and only locks onto bots",
		Callback = function(v)
			A.BotsOnly = v;

			if v and not A.Bots then
				A.Bots = true;

				pcall(function() botsRow:Set(true) end);
			end;
		end,
	});

	task.spawn(function()
		while alive do
			local holder = botHolder();
			local names = {};

			if holder then
				for _, bot in ipairs(holder:GetChildren()) do
					if #botParts(bot) > 0 then names[#names + 1] = bot.Name end;
				end;
			end;

			detectedRow:SetText(tostring(#names));
			namesRow:SetText(#names > 0 and string.sub(table.concat(names, ", "), 1, 80) or "none");

			task.wait(1);
		end;
	end);

	onUnload("aimbot", function()
		alive = false;

		A.On, A.Trigger, A.Bots, A.BotsOnly = false, false, false, false;

		pcall(function() RunService:UnbindFromRenderStep(AIM_STEP) end);

		if stepConn then
			pcall(function() stepConn:Disconnect() end);

			stepConn = nil;
		end;

		if circle then
			circle.Visible = false;

			pcall(function() circle:Remove() end);

			circle = nil;
		end;
	end);
end;
