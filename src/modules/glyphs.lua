--!nonstrict
--[[
	glyphs.lua — extracted feature module (require id "modules.glyphs").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("glyphs") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("glyphs", function()
			return require("modules.glyphs")({ ESP = ESP, NeverLose = NeverLose, Preview = Preview, Remote = Remote, Render = Render, RunService = RunService, Sections = Sections, onUnload = onUnload, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local NeverLose = ctx.NeverLose;
	local Preview = ctx.Preview;
	local Remote = ctx.Remote;
	local Render = ctx.Render;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local onUnload = ctx.onUnload;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("glyphs") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local G = {
		On = false,
		Count = 55,
		Mode = "Theme",
		Color = Color3.fromRGB(120, 200, 255),
		Speed = 16,
		Length = 34,
		Width = 2,
		Life = 7,
		Glow = true,
	};

	local random = Random.new(93882);
	local lines = {};

	local DIRS = {
		Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
		Vector3.new(0, 1, 0), Vector3.new(0, -1, 0),
		Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
	};

	local FAR = 120;
	local FADE_IN, FADE_OUT = 0.7, 1.4;
	local TURN_TIME = 0.22;

	local BANDS = { 14, 24, 36, 50, 66, 84 };
	local band = 0;

	local GOLDEN = 2.39996323;
	local spiral = 0;

	local strokes = Render.pool("Line", function(item) item.Visible = false end);

	local dotGui = Render.gui("glyphdots", -3);
	local dots, dotted = {}, 0;

	local bloomUrl;

	task.spawn(function()
		local ok, url = pcall(function()
			return Remote.id(Remote.file("particles/p_bloom.png"));
		end);

		if __ALIVE() and ok then bloomUrl = url end;
	end);

	local function glowDot()
		if not bloomUrl or dotted >= 420 then return nil end;

		dotted = dotted + 1;

		local dot = dots[dotted];

		if not dot then
			dot = Instance.new("ImageLabel");
			dot.Name = "Bloom";
			dot.AnchorPoint = Vector2.new(0.5, 0.5);

			dot.BackgroundTransparency = 1;
			dot.BorderSizePixel = 0;
			dot.Image = bloomUrl;
			dot.ResampleMode = Enum.ResamplerMode.Default;
			dot.Visible = false;
			dot.Parent = dotGui;

			dots[dotted] = dot;
		end;

		return dot;
	end;

	local function hideRest()
		strokes.done();

		for i = dotted + 1, #dots do
			if dots[i].Visible then dots[i].Visible = false end;
		end;
	end;

	local connection;

	local function clearPool()

		if connection then
			pcall(function() connection:Disconnect() end);

			connection = nil;
		end;

		strokes.wipe();

		for _, dot in ipairs(dots) do pcall(function() dot:Destroy() end) end;

		table.clear(dots);
		table.clear(lines);

		dotted = 0;
	end;

	local function spawnLine(seeded)
		local cam = Render.camera();

		if not cam then return nil end;

		local cf = cam.CFrame;

		band = band % #BANDS + 1;
		spiral = spiral + GOLDEN;

		local depth = BANDS[band] * random:NextNumber(0.85, 1.15);
		local reach = depth * 0.7;

		local radius = math.sqrt(random:NextNumber(0.05, 1)) * reach;

		local at = cf.Position
			+ cf.LookVector * depth
			+ cf.RightVector * math.cos(spiral) * radius
			+ cf.UpVector * math.sin(spiral) * radius * 0.6;

		local dir = DIRS[random:NextInteger(1, 6)];
		local life = G.Life * random:NextNumber(0.7, 1.35);

		return {
			pts = { at },
			sx = {}, sy = {}, son = {}, sfar = {},
			head = at,
			dir = dir,
			goal = dir,
			turn = 1,
			run = 0,
			leg = random:NextNumber(3, 9),
			life = life,

			age = seeded and random:NextNumber(0, life * 0.8) or 0,
			phase = random:NextNumber(0, 1),
		};
	end;

	local function advance(l, dt)
		l.age = l.age + dt;

		if l.turn < 1 then
			l.turn = math.min(1, l.turn + dt / TURN_TIME);

			local blend = l.turn * l.turn * (3 - 2 * l.turn);
			local mixed = l.dir:Lerp(l.goal, blend);

			if mixed.Magnitude > 0.001 then l.dir = mixed.Unit end;
		end;

		local step = G.Speed * dt;

		l.head = l.head + l.dir * step;
		l.run = l.run + step;

		if l.run >= l.leg then
			l.pts[#l.pts + 1] = l.head;
			l.goal = DIRS[random:NextInteger(1, 6)];
			l.turn = 0;
			l.run = 0;
			l.leg = random:NextNumber(3, 9);
		end;

		local total = (l.head - l.pts[#l.pts]).Magnitude;

		for i = 2, #l.pts do total = total + (l.pts[i] - l.pts[i - 1]).Magnitude end;

		local excess = total - G.Length;

		while excess > 0 and #l.pts >= 2 do
			local leg = l.pts[2] - l.pts[1];
			local len = leg.Magnitude;

			if len <= excess then
				table.remove(l.pts, 1);
				excess = excess - len;
			else
				l.pts[1] = l.pts[1] + leg.Unit * excess;
				excess = 0;
			end;
		end;

		if excess > 0 and #l.pts == 1 then
			local leg = l.head - l.pts[1];

			if leg.Magnitude > excess then l.pts[1] = l.pts[1] + leg.Unit * excess end;
		end;
	end;

	local function envelope(l, eye)
		if l.age >= l.life then return 0 end;

		local fade = math.min(1, l.age / FADE_IN);
		local left = l.life - l.age;

		if left < FADE_OUT then fade = math.min(fade, left / FADE_OUT) end;

		local away = (l.head - eye).Magnitude;

		if away > FAR then return 0 end;
		if away > FAR * 0.75 then fade = fade * (1 - (away - FAR * 0.75) / (FAR * 0.25)) end;

		return fade;
	end;

	local function colourAt(l, index, now)
		if G.Mode == "Rainbow" then
			return Color3.fromHSV(((now * 0.11 + l.phase) % 1), 0.85, 1);
		end;

		if G.Mode == "Single" then return G.Color end;

		local accent = NeverLose.AccentColor or G.Color;
		local h, s, v = accent:ToHSV();
		local drift = math.sin(index * 0.5 + l.phase * 6.283) * 0.09;

		return Color3.fromHSV((h + drift) % 1, math.clamp(s, 0.35, 1), math.max(v, 0.65));
	end;

	local blockAt, blockTo;

	local function cover(frame, padTop)
		if not (frame and frame.Visible and frame.AbsoluteSize.X > 8) then return end;

		local at = frame.AbsolutePosition - Vector2.new(10, padTop);
		local to = frame.AbsolutePosition + frame.AbsoluteSize + Vector2.new(10, 10);

		blockAt = blockAt and Vector2.new(math.min(blockAt.X, at.X), math.min(blockAt.Y, at.Y)) or at;
		blockTo = blockTo and Vector2.new(math.max(blockTo.X, to.X), math.max(blockTo.Y, to.Y)) or to;
	end;

	local function blocked(ax, ay, bx, by)
		if not blockAt then return false end;

		local dx, dy = bx - ax, by - ay;
		local lo, hi = 0, 1;

		for side = 1, 4 do
			local p, q;

			if side == 1 then p, q = -dx, ax - blockAt.X;
			elseif side == 2 then p, q = dx, blockTo.X - ax;
			elseif side == 3 then p, q = -dy, ay - blockAt.Y;
			else p, q = dy, blockTo.Y - ay end;

			if p == 0 then
				if q < 0 then return false end;
			else
				local r = q / p;

				if p < 0 then
					if r > hi then return false end;
					if r > lo then lo = r end;
				else
					if r < lo then return false end;
					if r < hi then hi = r end;
				end;
			end;
		end;

		return true;
	end;

	local function stroke(from, to, colour, width, alpha)
		if G.Glow then
			local glow = strokes.take();

			glow.From, glow.To = from, to;
			glow.Color = colour;
			glow.Thickness = math.max(1, width * 3.2);
			glow.Transparency = alpha * 0.16;
			glow.Visible = true;
		end;

		local piece = strokes.take();

		piece.From, piece.To = from, to;
		piece.Color = colour;
		piece.Thickness = math.max(1, width);
		piece.Transparency = alpha;
		piece.Visible = true;
	end;

	local glyphsShown = true;
	connection = NeverLose:AddSignal(RunService.RenderStepped:Connect(function(dt)
		if not NeverLose.ScreenGui.Parent then return end;

		if not G.On then
			if glyphsShown then
				glyphsShown = false;
				strokes.reset();
				dotted = 0;
				if #lines > 0 then table.clear(lines) end;
				hideRest();
			end;

			return;
		end;

		glyphsShown = true;
		strokes.reset();

		dotted = 0;

		local basis = Render.basis();

		if not basis then hideRest(); return end;

		dt = math.min(dt, 0.1);

		local eye = basis.pos;

		for i = #lines, 1, -1 do
			local l = lines[i];

			advance(l, dt);

			if l.age >= l.life or (l.head - eye).Magnitude > FAR * 1.3 then
				table.remove(lines, i);
			end;
		end;

		local room = 3;

		while #lines < G.Count and room > 0 do
			room = room - 1;

			local born = spawnLine(#lines < G.Count * 0.5);

			if not born then break end;

			lines[#lines + 1] = born;
		end;

		blockAt, blockTo = nil, nil;

		cover(ESP.WindowFrame and ESP.WindowFrame(), 42);
		cover(Preview and Preview.Panel, 10);
		local now = os.clock();

		for index, l in ipairs(lines) do
			local fade = envelope(l, eye);

			if fade > 0.02 then
				local pts = l.pts;
				local count = #pts;
				local colour = colourAt(l, index, now);
				local sx, sy, son, sfar = l.sx, l.sy, l.son, l.sfar;

				for i = 1, count do
					local x, y, depth = Render.project(basis, pts[i]);

					sx[i], sy[i], son[i], sfar[i] = x, y, depth > 0, depth;
				end;

				local hx, hy, hd = Render.project(basis, l.head);
				local last = count + 1;

				sx[last], sy[last], son[last], sfar[last] = hx, hy, hd > 0, hd;

				for i = 2, last do
					if son[i - 1] and son[i] then
						local ax, ay = sx[i - 1], sy[i - 1];
						local bx, by = sx[i], sy[i];

						if not blocked(ax, ay, bx, by) then
							local av = Vector2.new(ax, ay);
							local bv = Vector2.new(bx, by);
							local t = (i - 1) / count;
							local alpha = fade * (0.08 + 0.92 * t);
							local depth = math.clamp(1 - sfar[i] / FAR, 0.12, 1);

							if alpha > 0.02 then
								stroke(av, bv, colour, G.Width * depth * (0.45 + 0.55 * t), alpha);
							end;
						end;
					end;
				end;

				if G.Glow then
					for i = 2, count do
						if son[i] then
							local dot = glowDot();

							if not dot then break end;

							local t = (i - 1) / count;
							local depth = math.clamp(1 - sfar[i] / FAR, 0.12, 1);
							local size = math.max(7, G.Width * depth * 11);

							dot.Position = UDim2.fromOffset(sx[i], sy[i]);
							dot.Size = UDim2.fromOffset(size, size);
							dot.ImageColor3 = colour;
							dot.ImageTransparency = 1 - math.clamp(fade * (0.12 + 0.88 * t) * 0.85, 0, 1);
							dot.Visible = true;
						end;
					end;
				end;
			end;
		end;

		hideRest();
	end));

	ESP.Glyphs = G;
	ESP.ClearGlyphs = onUnload("glyphs", clearPool);

	local row = Sections.Glyphs:AddLabel("Enabled");
	row:AddToggle({
		Default = false, Flag = "glyphs",
		Callback = function(v)
			G.On = v;

			if not v then table.clear(lines) end;
		end,
	});
	row:AddColorPicker({ Default = G.Color, Flag = "glyphs_color", Callback = function(v) G.Color = v end });

	Sections.Glyphs:AddLabel("Color"):AddDropdown({
		Default = "Theme",
		Values = { "Theme", "Rainbow", "Single" },
		Flag = "glyphs_mode",
		Callback = function(v) G.Mode = v end,
	});

	Sections.Glyphs:AddLabel("Count"):AddSlider({
		Min = 8, Max = 160, Default = 55, Rounding = 0, Size = 100,
		Flag = "glyphs_count",
		Callback = function(v) G.Count = v end,
	});

	Sections.Glyphs:AddLabel("Speed"):AddSlider({
		Min = 1, Max = 90, Default = 16, Rounding = 0, Size = 100,
		Flag = "glyphs_speed",
		Callback = function(v) G.Speed = v end,
	});

	Sections.Glyphs:AddLabel("Trail"):AddSlider({
		Min = 6, Max = 120, Default = 34, Rounding = 0, Size = 100,
		Flag = "glyphs_length",
		Callback = function(v) G.Length = v end,
	});

	Sections.Glyphs:AddLabel("Lifetime"):AddSlider({
		Min = 2, Max = 25, Default = 7, Rounding = 0, Size = 100, Type = "s",
		Flag = "glyphs_life",
		Callback = function(v) G.Life = v end,
	});

	Sections.Glyphs:AddLabel("Width"):AddSlider({
		Min = 1, Max = 8, Default = 2, Rounding = 0, Size = 100,
		Flag = "glyphs_width",
		Callback = function(v) G.Width = v end,
	});

	Sections.Glyphs:AddLabel("Glow"):AddToggle({
		Default = true, Flag = "glyphs_glow",
		Callback = function(v) G.Glow = v end,
	});
end;
