--!nonstrict
--[[
	chinahat.lua — extracted feature module (require id "modules.chinahat").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("chinahat") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("chinahat", function()
			return require("modules.chinahat")({ ESP = ESP, LocalPlayer = LocalPlayer, NeverLose = NeverLose, RunService = RunService, Sections = Sections, destroyAny = destroyAny, onUnload = onUnload, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local destroyAny = ctx.destroyAny;
	local onUnload = ctx.onUnload;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("chinahat") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local lp = LocalPlayer;

	local ch_on = false
	local ch_col = Color3.fromRGB(170, 85, 255)

	local CH_RADIUS, CH_HEIGHT, CH_DROP = 1.55, 0.82, 0.02
	local CH_SEGMENTS = 48
	local CH_TAU = math.pi * 2
	local CH_ALPHA = 0.72
	local CH_MAX_ROWS = 220

	local ch = {
		rows = {},
		px = table.create(CH_SEGMENTS + 1),
		py = table.create(CH_SEGMENTS + 1),
		cos = table.create(CH_SEGMENTS),
		sin = table.create(CH_SEGMENTS),
		ord = table.create(CH_SEGMENTS + 1),
		stack = table.create(CH_SEGMENTS + 2),
		shown = {},
		cpos = {},
		csize = {},
		ccol = {},
		white = Color3.new(1, 1, 1),
		black = Color3.new(0, 0, 0),
		eps = 0.75
	}

	for i = 1, CH_SEGMENTS do
		local angle = (i - 1) / CH_SEGMENTS * CH_TAU
		ch.cos[i] = math.cos(angle) * CH_RADIUS
		ch.sin[i] = math.sin(angle) * CH_RADIUS
	end

	ch.order = function(i, j)
		local px, py = ch.px, ch.py
		local ax, bx = px[i], px[j]
		return ax == bx and py[i] < py[j] or ax < bx
	end

	ch.hull = function(n)
		local px, py, ord, st = ch.px, ch.py, ch.ord, ch.stack
		for i = 1, n do ord[i] = i end
		table.sort(ord, ch.order)
		local m = 0
		for k = 1, n do
			local i = ord[k]
			local x, y = px[i], py[i]
			while m >= 2 do
				local o, a = st[m - 1], st[m]
				local ox, oy = px[o], py[o]
				if (px[a] - ox) * (y - oy) - (py[a] - oy) * (x - ox) > 0 then break end
				m = m - 1
			end
			m = m + 1
			st[m] = i
		end
		local lower = m
		for k = n - 1, 1, -1 do
			local i = ord[k]
			local x, y = px[i], py[i]
			while m > lower do
				local o, a = st[m - 1], st[m]
				local ox, oy = px[o], py[o]
				if (px[a] - ox) * (y - oy) - (py[a] - oy) * (x - ox) > 0 then break end
				m = m - 1
			end
			m = m + 1
			st[m] = i
		end
		return m - 1
	end

	ch.visible = function(state)
		local rows, shown = ch.rows, ch.shown
		for i = 1, #rows do
			if shown[i] ~= state then
				rows[i].Visible = state
				shown[i] = state
			end
		end
	end

	ch.clear = function()
		local rows = ch.rows
		for i = 1, #rows do
			destroyAny(rows[i])
		end
		table.clear(rows)
		table.clear(ch.shown)
		table.clear(ch.cpos)
		table.clear(ch.csize)
		table.clear(ch.ccol)
		ch.head, ch.pos, ch.cf = nil, nil, nil
		ch.fov, ch.vx, ch.vy, ch.col = nil, nil, nil, nil
	end

	ch.build = function()
		ch.clear()
	end

	ch.row = function(index)
		local rows = ch.rows
		local row = rows[index]
		if row then return row end
		row = Drawing.new("Square")
		row.Filled = true
		row.Thickness = 0
		row.Transparency = CH_ALPHA
		row.Visible = false
		row.ZIndex = 1
		rows[index] = row
		ch.shown[index] = false
		return row
	end

	ch.update = function(camera)
		local char = lp.Character
		local head = char and char:FindFirstChild("Head")
		if not head or not head:IsA("BasePart") or not camera then
			ch.visible(false)
			return
		end
		local headPos = head.Position
		local camCF = camera.CFrame
		local fov = camera.FieldOfView
		local view = camera.ViewportSize
		local viewX, viewY = view.X, view.Y
		if ch.head == head and ch.pos == headPos and ch.cf == camCF
			and ch.headSize == head.Size and ch.fov == fov and ch.vx == viewX and ch.vy == viewY and ch.col == ch_col then
			return
		end
		ch.head, ch.pos, ch.cf = head, headPos, camCF
		ch.headSize = head.Size
		ch.fov, ch.vx, ch.vy, ch.col = fov, viewX, viewY, ch_col
		local px, py, cosT, sinT = ch.px, ch.py, ch.cos, ch.sin
		local baseY = headPos.Y + head.Size.Y * 0.5 - CH_DROP
		local center = Vector3.new(headPos.X, baseY, headPos.Z)
		local apex = camera:WorldToViewportPoint(center + Vector3.new(0, CH_HEIGHT, 0))
		if apex.Z <= 0 then
			ch.visible(false)
			return
		end
		local probe = camera:WorldToViewportPoint(center + Vector3.new(cosT[1], 0, sinT[1]))
		if probe.Z <= 0 then
			ch.visible(false)
			return
		end
		px[1], py[1] = apex.X, apex.Y
		px[2], py[2] = probe.X, probe.Y
		local camPos = camCF.Position
		local rv, uv, lv = camCF.RightVector, camCF.UpVector, camCF.LookVector
		local ox, oy, oz = center.X - camPos.X, center.Y - camPos.Y, center.Z - camPos.Z
		local baseR = ox * rv.X + oy * rv.Y + oz * rv.Z
		local baseU = ox * uv.X + oy * uv.Y + oz * uv.Z
		local baseD = ox * lv.X + oy * lv.Y + oz * lv.Z
		local rvx, rvz, uvx, uvz, lvx, lvz = rv.X, rv.Z, uv.X, uv.Z, lv.X, lv.Z
		local scale = viewY * 0.5 / math.tan(math.rad(fov * 0.5))
		local midX, midY = viewX * 0.5, viewY * 0.5
		local eps = ch.eps
		local exact = false
		local dep = baseD + CH_HEIGHT * lv.Y
		if dep > 0 then
			local inv = scale / dep
			if math.abs(midX + (baseR + CH_HEIGHT * rv.Y) * inv - apex.X) <= eps
				and math.abs(midY - (baseU + CH_HEIGHT * uv.Y) * inv - apex.Y) <= eps then
				local c, s = cosT[1], sinT[1]
				dep = baseD + c * lvx + s * lvz
				if dep > 0 then
					inv = scale / dep
					if math.abs(midX + (baseR + c * rvx + s * rvz) * inv - probe.X) <= eps
						and math.abs(midY - (baseU + c * uvx + s * uvz) * inv - probe.Y) <= eps then
						exact = true
					end
				end
			end
		end
		if exact then
			for i = 2, CH_SEGMENTS do
				local c, s = cosT[i], sinT[i]
				local d = baseD + c * lvx + s * lvz
				if d <= 0 then
					ch.visible(false)
					return
				end
				local inv = scale / d
				px[i + 1] = midX + (baseR + c * rvx + s * rvz) * inv
				py[i + 1] = midY - (baseU + c * uvx + s * uvz) * inv
			end
		else
			for i = 2, CH_SEGMENTS do
				local point = camera:WorldToViewportPoint(center + Vector3.new(cosT[i], 0, sinT[i]))
				if point.Z <= 0 then
					ch.visible(false)
					return
				end
				px[i + 1] = point.X
				py[i + 1] = point.Y
			end
		end
		local hn = ch.hull(CH_SEGMENTS + 1)
		if hn < 3 then
			ch.visible(false)
			return
		end
		local st = ch.stack
		local minY, maxY = math.huge, -math.huge
		for i = 1, hn do
			local y = py[st[i]]
			if y < minY then minY = y end
			if y > maxY then maxY = y end
		end
		local firstY = math.max(0, math.floor(minY))
		local lastY = math.min(viewY, math.ceil(maxY))
		if lastY - firstY < 2 then
			ch.visible(false)
			return
		end
		local step = math.max(1, math.ceil((lastY - firstY) / CH_MAX_ROWS))
		local span = math.max(1, maxY - minY)
		local rows, shown = ch.rows, ch.shown
		local cpos, csize, ccol = ch.cpos, ch.csize, ch.ccol
		local white, black = ch.white, ch.black
		local used = 0
		for y0 = firstY, lastY - 1, step do
			local height = math.min(step, lastY - y0)
			local y = y0 + height * 0.5
			local left, right = math.huge, -math.huge
			local ax, ay = px[st[hn]], py[st[hn]]
			for i = 1, hn do
				local ix = st[i]
				local bx, by = px[ix], py[ix]
				if (ay <= y and by > y) or (by <= y and ay > y) then
					local x = ax + (y - ay) * (bx - ax) / (by - ay)
					if x < left then left = x end
					if x > right then right = x end
				end
				ax, ay = bx, by
			end
			local width = right - left
			if width >= 2.5 then
				used = used + 1
				local row = ch.row(used)
				local t = (y - minY) / span
				local light = 1 - t * 1.35
				local dark = (t - 0.58) / 0.42
				if light < 0 then light = 0 end
				if dark < 0 then dark = 0 end
				local color = ch_col:Lerp(white, light * 0.26):Lerp(black, dark * 0.1)
				local pos = Vector2.new(left, y0)
				local size = Vector2.new(width, height)
				if cpos[used] ~= pos then
					row.Position = pos
					cpos[used] = pos
				end
				if csize[used] ~= size then
					row.Size = size
					csize[used] = size
				end
				if ccol[used] ~= color then
					row.Color = color
					ccol[used] = color
				end
				if not shown[used] then
					row.Visible = true
					shown[used] = true
				end
			end
		end
		for i = used + 1, #rows do
			if shown[i] then
				rows[i].Visible = false
				shown[i] = false
			end
		end
	end

	NeverLose:AddSignal(RunService.RenderStepped:Connect(function()
		if not ch_on then return end

		ch.update(workspace.CurrentCamera)
	end));

	NeverLose:AddSignal(LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.4)

		if __ALIVE() and ch_on then ch.build() end
	end));

	local row = Sections.Extras:AddLabel("China Hat");

	row:AddToggle({
		Name = "China Hat",
		Default = false,
		Flag = "china_hat",
		Callback = function(v)
			ch_on = v

			if v then ch.build() else ch.clear() end
		end,
	});

	row:AddColorPicker({
		Default = ch_col,
		Flag = "china_hat_color",
		Callback = function(c) ch_col = c end,
	});

	ESP.ChinaHat = { On = function() return ch_on end };

	ESP.ClearChinaHat = onUnload("chinahat", function()
		ch_on = false

		pcall(ch.clear)
	end);
end;
