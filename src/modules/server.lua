--!nonstrict
--[[
	server.lua — extracted feature module (require id "modules.server").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("server") in the driver — byte-frozen original
	code below the marker (re-derived on every `make extract`; do not hand-edit).

	The block originally closed over driver locals; the driver now passes them
	in via the ctx table:

		guard("server", function()
			return require("modules.server")({ LocalPlayer = LocalPlayer, NeverLose = NeverLose, Notification = Notification, Players = Players, RunService = RunService, Sections = Sections, onUnload = onUnload });
		end);
]]
return function(ctx)
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local Notification = ctx.Notification;
	local Players = ctx.Players;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local onUnload = ctx.onUnload;

-- [ guard("server") callback body — byte-exact from input/message(47).txt ]
	local S = {
		Fling = false, Power = 150, Spin = false,
		Target = nil, Follow = false, Spectate = false,
	};

	local alive = true;
	local spinAngle = 0;
	local wasSpinning = false;
	local autoRotFor, autoRot = nil, nil;
	local savedCameraType;
	local startedAt = os.clock();
	local stats = game:GetService("Stats");
	local pingItem;

	local function targetNames()
		local names = {};

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then names[#names + 1] = player.Name end;
		end;

		table.sort(names);

		return names;
	end;

	local function findTarget()
		if type(S.Target) ~= "string" or S.Target == "" then return nil end;

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Name == S.Target then return player end;
		end;

		return nil;
	end;

	local function roots()
		local mine = LocalPlayer.Character;
		local myRoot = mine and mine:FindFirstChild("HumanoidRootPart");
		local victim = findTarget();
		local theirRoot = victim and victim.Character and victim.Character:FindFirstChild("HumanoidRootPart");

		return myRoot, theirRoot;
	end;

	local function copy(value, label)
		local ok = type(setclipboard) == "function" and pcall(setclipboard, tostring(value or ""));

		Notification.new({
			Title = "Server",
			Content = ok and ("copied " .. label) or "no clipboard support",
			Duration = 3,
		});
	end;

	local function pingText()
		if not pingItem then
			local ok, item = pcall(function()
				return stats.Network.ServerStatsItem["Data Ping"];
			end);

			if ok then pingItem = item end;
		end;

		if not pingItem then return nil end;

		local ok, value = pcall(function() return pingItem:GetValueString() end);

		if ok and type(value) == "string" and value ~= "" then return value end;

		return nil;
	end;

	local names = targetNames();

	local targetDrop = Sections.FlingTarget:AddLabel("Target Player"):AddDropdown({
		Default = names[1],
		Values = names,
		Flag = "srv_target",
		Callback = function(v)
			S.Target = (type(v) == "string" and v ~= "") and v or nil;
		end,
	});

	S.Target = names[1];

	local function refreshTargets()
		local list = targetNames();

		if targetDrop.SetValues then targetDrop:SetValues(list) end;

		if not S.Target or not table.find(list, S.Target) then
			S.Target = list[1];

			if S.Target and targetDrop.SetValue then targetDrop:SetValue(S.Target) end;
		end;
	end;

	NeverLose:AddSignal(Players.PlayerAdded:Connect(function() task.defer(refreshTargets) end));
	NeverLose:AddSignal(Players.PlayerRemoving:Connect(function() task.defer(refreshTargets) end));

	NeverLose:AddSignal(RunService.Heartbeat:Connect(function(dt)
		if not alive then return end;

		local myRoot, theirRoot = roots();
		local human = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid");
		local spinning = S.Spin or (S.Fling and theirRoot ~= nil);

		if spinning and myRoot then
			spinAngle = (spinAngle + dt * 6) % (math.pi * 2);
			wasSpinning = true;
		elseif wasSpinning then
			if myRoot then pcall(function() myRoot.AssemblyAngularVelocity = Vector3.zero end) end;

			wasSpinning = false;
		end;

		if myRoot and human then
			if spinning then
				if autoRotFor ~= human then autoRotFor, autoRot = human, human.AutoRotate end;

				human.AutoRotate = false;
			elseif autoRotFor then
				if autoRotFor.Parent and autoRot ~= nil then autoRotFor.AutoRotate = autoRot end;

				autoRotFor, autoRot = nil, nil;
			end;
		end;

		if spinning and myRoot then
			if S.Fling and theirRoot then
				myRoot.CFrame = CFrame.new(theirRoot.Position) * CFrame.Angles(0, spinAngle, 0);
			else
				myRoot.CFrame = CFrame.new(myRoot.Position) * CFrame.Angles(0, spinAngle, 0);
			end;

			myRoot.AssemblyAngularVelocity = Vector3.new(0, S.Power, 0);
		end;

		if S.Follow and not S.Fling and myRoot and theirRoot then
			local delta = theirRoot.Position - myRoot.Position;

			if delta.Magnitude > 8 then
				myRoot.AssemblyLinearVelocity = delta.Unit * math.min(delta.Magnitude * 2, 160);
			end;
		end;

		if S.Spectate and theirRoot then
			local cam = workspace.CurrentCamera;

			if cam then
				if cam.CameraType ~= Enum.CameraType.Scriptable then
					savedCameraType = savedCameraType or cam.CameraType;
					cam.CameraType = Enum.CameraType.Scriptable;
				end;

				local at = theirRoot.Position;
				local back = -theirRoot.CFrame.LookVector;

				cam.CFrame = CFrame.lookAt(at + back * 7 + Vector3.new(0, 3, 0), at);
			end;
		elseif savedCameraType then
			local cam = workspace.CurrentCamera;

			if cam then cam.CameraType = savedCameraType end;

			savedCameraType = nil;
		end;
	end));

	Sections.FlingCtl:AddLabel("Fling"):AddToggle({
		Default = false, Flag = "srv_fling",
		ToolTip = "Sticks to the target and launches them",
		Callback = function(v) S.Fling = v end,
	});

	Sections.FlingCtl:AddLabel("Fling Power"):AddSlider({
		Min = 50, Max = 500, Default = 150, Rounding = 0, Size = 90,
		Flag = "srv_power",
		Callback = function(v) S.Power = v end,
	});

	Sections.FlingCtl:AddLabel("Spin"):AddToggle({
		Default = false, Flag = "srv_spin",
		ToolTip = "Spins your character in place",
		Callback = function(v) S.Spin = v end,
	});

	Sections.PlayerAct:AddButton({
		Icon = "map-pin",
		Name = "Teleport To Target",
		Callback = function()
			local myRoot, theirRoot = roots();

			if not myRoot or not theirRoot then
				Notification.new({ Title = "Server", Content = "Pick a target first", Duration = 3 });
				return;
			end;

			myRoot.CFrame = CFrame.new(theirRoot.Position + Vector3.new(0, 3, 0));
		end,
	});

	Sections.PlayerAct:AddLabel("Follow Target"):AddToggle({
		Default = false, Flag = "srv_follow",
		ToolTip = "Drifts towards the target",
		Callback = function(v) S.Follow = v end,
	});

	Sections.PlayerView:AddLabel("Spectate"):AddToggle({
		Default = false, Flag = "srv_spectate",
		ToolTip = "Camera follows the target",
		Callback = function(v)
			S.Spectate = v;

			if not v and savedCameraType then
				local cam = workspace.CurrentCamera;

				if cam then cam.CameraType = savedCameraType end;

				savedCameraType = nil;
			end;
		end,
	});

	Sections.PlayerView:AddButton({
		Icon = "copy",
		Name = "Copy Target Name",
		Callback = function()
			if not S.Target then
				Notification.new({ Title = "Server", Content = "Pick a target first", Duration = 3 });
				return;
			end;

			copy(S.Target, "name");
		end,
	});

	local playersLabel = Sections.ServerInfo:AddLabel("Players", true);
	local placeLabel = Sections.ServerInfo:AddLabel("Place Id", true);
	local jobLabel = Sections.ServerInfo:AddLabel("Job Id", true);
	local uptimeLabel = Sections.ServerSession:AddLabel("Uptime", true);
	local pingLabel = Sections.ServerSession:AddLabel("Ping", true);

	placeLabel:SetText(tostring(game.PlaceId));

	Sections.ServerInfo:AddButton({
		Icon = "copy",
		Name = "Copy Job Id",
		Callback = function() copy(game.JobId, "job id") end,
	});

	Sections.ServerSession:AddButton({
		Icon = "copy",
		Name = "Copy Join Link",
		Callback = function()
			copy(("roblox://experiences/start?placeId=%d&gameInstanceId=%s"):format(game.PlaceId, game.JobId), "join link");
		end,
	});

	task.spawn(function()
		while alive do
			local count = #Players:GetPlayers();

			playersLabel:SetText(count .. " / " .. Players.MaxPlayers);
			jobLabel:SetText(string.sub(tostring(game.JobId), 1, 8) .. "...");

			local seconds = math.floor(os.clock() - startedAt);

			uptimeLabel:SetText(string.format("%02d:%02d:%02d",
				math.floor(seconds / 3600), math.floor((seconds % 3600) / 60), seconds % 60));
			pingLabel:SetText(pingText() or "...");

			task.wait(1);
		end;
	end);

	onUnload("server", function()
		alive = false;
		S.Fling, S.Spin, S.Follow, S.Spectate = false, false, false, false;

		local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart");

		if root then pcall(function() root.AssemblyAngularVelocity = Vector3.zero end) end;

		if autoRotFor then
			if autoRotFor.Parent and autoRot ~= nil then autoRotFor.AutoRotate = autoRot end;

			autoRotFor, autoRot = nil, nil;
		end;

		if savedCameraType then
			local cam = workspace.CurrentCamera;

			if cam then cam.CameraType = savedCameraType end;

			savedCameraType = nil;
		end;
	end);
end;
