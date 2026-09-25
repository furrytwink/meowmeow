--!nonstrict
--[[
	loading.lua — extracted feature module (require id "modules.loading").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("loading") in the driver — byte-frozen original
	code below the marker (re-derived on every `make extract`; do not hand-edit).

	The block originally closed over driver locals; the driver now passes them
	in via the ctx table:

		guard("loading", function()
			return require("modules.loading")({ NeverLose = NeverLose, Remote = Remote, RunService = RunService, onUnload = onUnload });
		end);
]]
return function(ctx)
	local NeverLose = ctx.NeverLose;
	local Remote = ctx.Remote;
	local RunService = ctx.RunService;
	local onUnload = ctx.onUnload;

-- [ guard("loading") callback body — byte-exact from input/message(47).txt ]
	local lib = NeverLose.Lib;
	local th = lib.theme;
	local L = Remote.Load;
	if not L then return end;

	local pill = Instance.new("CanvasGroup");
	pill.Name = NeverLose.RandomString();
	pill.AnchorPoint = Vector2.new(0.5, 0);
	pill.Position = UDim2.new(0.5, 0, 0, 10);
	pill.Size = UDim2.fromOffset(178, 28);
	pill.BackgroundColor3 = th.panel;
	pill.BorderSizePixel = 0;
	pill.GroupTransparency = 1;
	pill.Visible = false;
	pill.ZIndex = 950;
	pill.Parent = NeverLose.ScreenGui;
	Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0);
	local edge = Instance.new("UIStroke");
	edge.Color, edge.Transparency, edge.Parent = th.line, 0.45, pill;

	local spin = Instance.new("ImageLabel");
	spin.BackgroundTransparency = 1;
	spin.AnchorPoint = Vector2.new(0, 0.5);
	spin.Position = UDim2.new(0, 11, 0.5, 0);
	spin.Size = UDim2.fromOffset(14, 14);
	spin.ImageColor3 = th.accent;
	spin.ZIndex = 951;
	for _, name in ipairs({ "loader-circle", "loader", "refresh-cw" }) do
		if lib.icons[name] then spin.Image = "rbxassetid://" .. lib.icons[name]; break end;
	end;
	spin.Parent = pill;

	local caption = Instance.new("TextLabel");
	caption.BackgroundTransparency = 1;
	caption.Position = UDim2.fromOffset(33, 0);
	caption.Size = UDim2.new(1, -42, 1, -2);
	caption.Font = Enum.Font.GothamBold;
	caption.TextSize = 12;
	caption.TextColor3 = th.text;
	caption.TextXAlignment = Enum.TextXAlignment.Left;
	caption.Text = "Loading assets";
	caption.ZIndex = 951;
	caption.Parent = pill;

	local bar = Instance.new("Frame");
	bar.BorderSizePixel = 0;
	bar.BackgroundColor3 = th.accent;
	bar.AnchorPoint = Vector2.new(0, 1);
	bar.Position = UDim2.new(0, 0, 1, 0);
	bar.Size = UDim2.new(0, 0, 0, 2);
	bar.ZIndex = 951;
	bar.Parent = pill;

	local TweenService = game:GetService("TweenService");
	local base, since, idle, shown = 0, nil, nil, false;
	local function fade(on)
		if shown == on then return end;
		shown = on;
		if on then pill.Visible = true end;
		local tween = TweenService:Create(pill, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { GroupTransparency = on and 0 or 1 });
		tween:Play();
		if not on then tween.Completed:Once(function() if not shown then pill.Visible = false end end) end;
	end;
	local function refresh()
		if L.active > 0 and not since then since, base = os.clock(), L.done end;
		local total, got = math.max(L.total - base, 1), math.max(L.done - base, 0);
		caption.Text = ("Loading assets  %d/%d"):format(math.min(got, total), total);
		TweenService:Create(bar, TweenInfo.new(0.2), { Size = UDim2.new(math.min(got / total, 1), 0, 0, 2) }):Play();
	end;
	L.listeners[#L.listeners + 1] = refresh;

	NeverLose:AddSignal(RunService.Heartbeat:Connect(function(dt)
		if not since then return end;
		if L.active > 0 then
			idle = nil;
			if os.clock() - since > 0.35 then fade(true) end;
			if shown then spin.Rotation = (spin.Rotation + dt * 300) % 360 end;
		else
			idle = idle or os.clock();
			if os.clock() - idle > 0.6 then since = nil; fade(false) end;
		end;
	end));
	onUnload("loading badge", function() pill:Destroy() end);
end;
