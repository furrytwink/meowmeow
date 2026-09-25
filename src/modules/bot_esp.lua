--!nonstrict
--[[
	bot_esp.lua — extracted feature module (require id "modules.bot_esp").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("bot esp") in the driver — byte-frozen original
	code below the marker (re-derived on every `make extract`; do not hand-edit).

	The block originally closed over driver locals; the driver now passes them
	in via the ctx table:

		guard("bot esp", function()
			return require("modules.bot_esp")({ NeverLose = NeverLose, RunService = RunService, Sections = Sections, onUnload = onUnload });
		end);
]]
return function(ctx)
	local NeverLose = ctx.NeverLose;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local onUnload = ctx.onUnload;

-- [ guard("bot esp") callback body — byte-exact from input/message(47).txt ]
	local E = {
		On = false, Chams = false, Distance = true,
		Color = Color3.fromRGB(255, 84, 84),
	};

	local alive = true;
	local marks = {};
	local glows = {};

	local CORNERS = {
		Vector3.new(-0.5, -0.5, -0.5), Vector3.new(0.5, -0.5, -0.5),
		Vector3.new(-0.5, 0.5, -0.5), Vector3.new(0.5, 0.5, -0.5),
		Vector3.new(-0.5, -0.5, 0.5), Vector3.new(0.5, -0.5, 0.5),
		Vector3.new(-0.5, 0.5, 0.5), Vector3.new(0.5, 0.5, 0.5),
	};

	local function holder()
		local highlight = workspace:FindFirstChild("Highlight");
		local enemy = highlight and highlight:FindFirstChild("Enemy");

		return enemy and enemy:FindFirstChild("HighlightHolder") or nil;
	end;

	local function anchor(bot)
		local collider = bot:FindFirstChild("Collider");
		local head = collider and collider:FindFirstChild("Head");

		if not (head and head:IsA("BasePart")) then head = bot:FindFirstChild("Head", true) end;
		if not head then head = bot:FindFirstChildWhichIsA("BasePart", true) end;

		return head and head:IsA("BasePart") and head or nil;
	end;

	local function newMark()
		local okBox, box = pcall(function() return Drawing.new("Square") end);
		local okText, text = pcall(function() return Drawing.new("Text") end);

		if not okBox or not box or not okText or not text then
			pcall(function() if box then box:Remove() end end);
			pcall(function() if text then text:Remove() end end);

			return nil;
		end;

		box.Thickness = 1;
		box.Filled = false;
		box.Visible = false;

		text.Size = 14;
		text.Center = true;
		text.Outline = true;
		text.Font = Enum.Font.GothamMedium;
		text.Visible = false;

		return { box = box, name = text };
	end;

	local function drop(mark)
		if not mark then return end;

		pcall(function()
			mark.box.Visible = false;
			mark.name.Visible = false;
		end);

		pcall(function() mark.box:Remove() end);
		pcall(function() mark.name:Remove() end);
	end;

	local function screenBox(bot, camera)
		local ok, cf, size = pcall(function() return bot:GetBoundingBox() end);

		if not ok or not cf then
			local part = anchor(bot);

			if not part then return nil end;

			cf, size = part.CFrame, Vector3.new(2, 5, 2);
		end;

		local x0, y0, x1, y1;

		for _, corner in ipairs(CORNERS) do
			local point, on = camera:WorldToViewportPoint(cf * (corner * size));

			if on and point.Z > 0 then
				x0 = math.min(x0 or point.X, point.X);
				y0 = math.min(y0 or point.Y, point.Y);
				x1 = math.max(x1 or point.X, point.X);
				y1 = math.max(y1 or point.Y, point.Y);
			end;
		end;

		if not x0 then return nil end;

		return x0, y0, math.max(1, x1 - x0), math.max(1, y1 - y0);
	end;

	NeverLose:AddSignal(RunService.RenderStepped:Connect(function()
		if not alive or not NeverLose.ScreenGui.Parent then return end;

		local camera = workspace.CurrentCamera;
		local folder = E.On and camera and holder() or nil;
		local seen = {};

		if folder then
			for _, bot in ipairs(folder:GetChildren()) do
				local part = anchor(bot);

				if part then
					seen[bot] = true;

					local mark = marks[bot];

					if not mark then
						mark = newMark();
						marks[bot] = mark;
					end;

					if mark then
						local x, y, w, h = screenBox(bot, camera);

						if x then
							mark.box.Position = Vector2.new(x, y);
							mark.box.Size = Vector2.new(w, h);
							mark.box.Color = E.Color;
							mark.box.Visible = true;

							local label = bot.Name;

							if E.Distance then
								local away = (part.Position - camera.CFrame.Position).Magnitude;

								label = string.format("%s [%dm]", label, math.floor(away + 0.5));
							end;

							mark.name.Text = label;
							mark.name.Color = E.Color;
							mark.name.Position = Vector2.new(x + w * 0.5, math.max(4, y - 16));
							mark.name.Visible = true;
						else
							mark.box.Visible = false;
							mark.name.Visible = false;
						end;
					end;
				end;
			end;
		end;

		for bot, mark in pairs(marks) do
			if not seen[bot] then
				drop(mark);

				marks[bot] = nil;
			end;
		end;

		for bot in pairs(glows) do
			if not seen[bot] or not E.Chams then
				local glow = glows[bot];

				glows[bot] = nil;

				pcall(function() glow:Destroy() end);
			end;
		end;

		if E.Chams then
			for bot in pairs(seen) do
				local glow = glows[bot];

				if not glow then
					glow = Instance.new("Highlight");
					glow.Name = "BotChams";
					glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop;
					glow.Adornee = bot;
					glow.Parent = bot;
					glows[bot] = glow;
				end;

				glow.FillColor = E.Color;
				glow.OutlineColor = Color3.new(1, 1, 1);
				glow.FillTransparency = 0.35;
				glow.OutlineTransparency = 0.1;
			end;
		end;
	end));

	Sections.SniperEsp:AddLabel("Bot ESP"):AddToggle({
		Default = false, Flag = "bot_esp",
		ToolTip = "Box and name over the AI bots",
		Callback = function(v) E.On = v end,
	});

	Sections.SniperEsp:AddLabel("Distance"):AddToggle({
		Default = true, Flag = "bot_esp_dist",
		ToolTip = "Adds the distance to the name line",
		Callback = function(v) E.Distance = v end,
	});

	Sections.SniperEsp:AddLabel("Color"):AddColorPicker({
		Default = E.Color, Flag = "bot_esp_color",
		Callback = function(v) E.Color = v end,
	});

	Sections.SniperEsp:AddLabel("Bot Chams"):AddToggle({
		Default = false, Flag = "bot_chams",
		ToolTip = "Fills the bots through walls",
		Callback = function(v) E.Chams = v end,
	});

	onUnload("bot esp", function()
		alive = false;
		E.On, E.Chams = false, false;

		for bot, mark in pairs(marks) do
			drop(mark);

			marks[bot] = nil;
		end;

		for bot, glow in pairs(glows) do
			glows[bot] = nil;

			pcall(function() glow:Destroy() end);
		end;
	end);
end;
