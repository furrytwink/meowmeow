--!nonstrict
--[[
	fun_hud.lua — extracted feature module (require id "modules.fun_hud").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("fun hud") in the driver — byte-frozen original
	code below the marker (re-derived on every `make extract`; do not hand-edit).

	The block originally closed over driver locals; the driver now passes them
	in via the ctx table:

		guard("fun hud", function()
			return require("modules.fun_hud")({ LocalPlayer = LocalPlayer, NeverLose = NeverLose, RunService = RunService, Sections = Sections, onUnload = onUnload });
		end);
]]
return function(ctx)
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local onUnload = ctx.onUnload;

-- [ guard("fun hud") callback body — byte-exact from input/message(47).txt ]
	local th = NeverLose.Lib.theme;

	local wantFps, wantPing, shotMode = false, false, false;
	local shotPinned = false;
	local pill, label;
	local frames, span = 0, 0;
	local hidden = {};
	local sweepAt = 0;
	local hideUntil = 0;

	local function isMine(gui)
		if typeof(gui) ~= "Instance" then return false end;
		if gui == NeverLose.ScreenGui then return true end;

		local scr = NeverLose.ScreenGui;

		return typeof(scr) == "Instance" and scr:IsDescendantOf(gui);
	end;

	local function screenGuis()
		local list = {};
		local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui");

		if playerGui then
			for _, gui in ipairs(playerGui:GetChildren()) do
				if gui:IsA("ScreenGui") and not isMine(gui) then
					list[#list + 1] = gui;
				end;
			end;
		end;

		local ok, coreGui = pcall(function() return game:GetService("CoreGui") end);

		if ok and typeof(coreGui) == "Instance" then
			for _, gui in ipairs(coreGui:GetChildren()) do
				if gui:IsA("ScreenGui") and not isMine(gui) then
					list[#list + 1] = gui;
				end;
			end;
		end;

		return list;
	end;

	local function ensure()
		if pill and pill.Parent then return end;

		pill = Instance.new("Frame");
		pill.Name = NeverLose.RandomString();
		pill.AnchorPoint = Vector2.new(1, 1);
		pill.Position = UDim2.new(1, -14, 1, -14);
		pill.Size = UDim2.fromOffset(0, 26);
		pill.AutomaticSize = Enum.AutomaticSize.X;
		pill.BackgroundColor3 = th.panel;
		pill.BorderSizePixel = 0;
		pill.Visible = false;
		pill.ZIndex = 905;
		pill.Parent = NeverLose.ScreenGui;

		Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0);

		local edge = Instance.new("UIStroke");
		edge.Color = th.line;
		edge.Transparency = 0.4;
		edge.Parent = pill;

		local pad = Instance.new("UIPadding");
		pad.PaddingLeft = UDim.new(0, 12);
		pad.PaddingRight = UDim.new(0, 12);
		pad.Parent = pill;

		label = Instance.new("TextLabel");
		label.BackgroundTransparency = 1;
		label.Size = UDim2.fromOffset(0, 20);
		label.AutomaticSize = Enum.AutomaticSize.X;
		label.Font = Enum.Font.GothamBold;
		label.TextSize = 12;
		label.TextColor3 = th.text;
		label.Text = "";
		label.ZIndex = 906;
		label.Parent = pill;
	end;

	local stats = game:GetService("Stats");
	local pingItem;

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

	local function sweep()
		for _, gui in ipairs(screenGuis()) do
			if gui.Visible then
				hidden[#hidden + 1] = gui;
				gui.Visible = false;
			end;
		end;
	end;

	local function restoreShot()
		for _, gui in ipairs(hidden) do
			if gui.Parent then pcall(function() gui.Visible = true end) end;
		end;

		table.clear(hidden);
	end;

	local function refresh()
		ensure();
		pill.Visible = wantFps or wantPing;
	end;

	NeverLose:AddSignal(RunService.Heartbeat:Connect(function(dt)
		if not (wantFps or wantPing or shotMode) then return end;

		if hideUntil > 0 and os.clock() >= hideUntil then
			hideUntil = 0;

			if not shotPinned then
				shotMode = false;
				restoreShot();
			end;
		end;

		frames = frames + 1;
		span = span + dt;

		if span >= 0.25 then
			if shotMode and os.clock() >= sweepAt then
				sweepAt = os.clock() + 0.2;
				sweep();
			end;

			if wantFps or wantPing then
				local parts = {};

				if wantFps then parts[#parts + 1] = "FPS " .. math.floor(frames / span + 0.5) end;

				if wantPing then
					local ping = pingText();

					if ping then parts[#parts + 1] = "Ping " .. ping end;
				end;

				ensure();
				label.Text = table.concat(parts, "    ");
				pill.Visible = true;
			end;

			frames, span = 0, 0;
		end;
	end));

	Sections.FunHud:AddLabel("FPS Counter"):AddToggle({
		Default = false, Flag = "fun_fps",
		Callback = function(v)
			wantFps = v;
			refresh();
		end,
	});

	Sections.FunHud:AddLabel("Ping Counter"):AddToggle({
		Default = false, Flag = "fun_ping",
		Callback = function(v)
			wantPing = v;
			refresh();
		end,
	});

	Sections.FunShot:AddLabel("Screenshot Mode"):AddToggle({
		Default = false, Flag = "fun_screenshot",
		ToolTip = "Hides every other GUI for a clean screenshot",
		Callback = function(v)
			shotMode = v and true or false;
			shotPinned = shotMode;
			hideUntil = 0;

			if not shotMode then restoreShot() end;
		end,
	});

	Sections.FunShot:AddButton({
		Name = "Hide UI (5s)",
		Icon = "video",
		Callback = function()
			shotMode = true;
			sweepAt = 0;
			hideUntil = os.clock() + 5;
		end,
	});

	onUnload("fun hud", function()
		shotMode = false;
		shotPinned = false;
		hideUntil = 0;
		restoreShot();

		if pill then
			pill:Destroy();
			pill, label = nil, nil;
		end;
	end);
end;
