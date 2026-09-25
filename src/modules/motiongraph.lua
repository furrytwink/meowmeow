--!nonstrict
--[[
	motiongraph.lua — extracted feature module (require id "modules.motiongraph").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("motiongraph") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("motiongraph", function()
			return require("modules.motiongraph")({ ESP = ESP, LocalPlayer = LocalPlayer, NeverLose = NeverLose, RunService = RunService, Sections = Sections, destroyAny = destroyAny, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local destroyAny = ctx.destroyAny;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("motiongraph") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local MG = { On = false };

	ESP.MotionGraph = MG;

		local run = RunService
		local ws  = workspace
		local lp  = LocalPlayer

		local mg_on = false
		local mg_color = Color3.fromRGB(242, 242, 242)
		local mg_width = 280
		local mg_height = 72
		local mg_offset = 105
		local mg_thickness = 1
		local mg_span = 2.8
		local mg_step = 1 / 30
		local mg_accum = 0
		local mg_render_accum = 0
		local mg_smooth = 0
		local mg_history = {}
		local mg_lines = {}
		local mg_shadows = {}
		local mg_labels = {}
		local mg_current = nil
		local mg_conn = nil

		local function mg_remove(obj)
			destroyAny(obj)
		end

		local function mg_speed()
			local char = lp.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root then return 0 end
			local velocity = root.AssemblyLinearVelocity
			return Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		end

		local function mg_reference()
			local char = lp.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			return math.max(1, hum and hum.WalkSpeed or 16)
		end

		local function mg_new_line(color, thickness, zindex, transparency)
			local line = Drawing.new("Line")
			line.Color = color
			line.Thickness = thickness
			line.Transparency = transparency
			line.ZIndex = zindex
			line.Visible = false
			return line
		end

		local function mg_new_text()
			local text = Drawing.new("Text")
			text.Center = true
			text.Outline = true
			text.Color = mg_color
			text.Size = 12
			text.ZIndex = 904
			text.Visible = false
			return text
		end

		local function mg_sync_pool(needed)
			while #mg_lines < needed do
				mg_shadows[#mg_shadows + 1] = mg_new_line(Color3.new(0, 0, 0), mg_thickness + 2, 901, 0.45)
				mg_lines[#mg_lines + 1] = mg_new_line(mg_color, mg_thickness, 902, 1)
			end
			while #mg_lines > needed do
				mg_remove(table.remove(mg_lines))
				mg_remove(table.remove(mg_shadows))
			end
		end

		local function mg_create()
			if mg_current then return end
			mg_current = mg_new_text()
			mg_current.Center = false
			for i = 1, 6 do
				mg_labels[i] = mg_new_text()
			end
		end

		local function mg_hide()
			if mg_current then mg_current.Visible = false end
			for i = 1, #mg_lines do
				mg_lines[i].Visible = false
				mg_shadows[i].Visible = false
			end
			for i = 1, #mg_labels do
				mg_labels[i].Visible = false
			end
		end

		local function mg_clear()
			if mg_conn then
				pcall(function() mg_conn:Disconnect() end)
				mg_conn = nil
			end
			mg_remove(mg_current)
			mg_current = nil
			for i = 1, #mg_lines do
				mg_remove(mg_lines[i])
				mg_remove(mg_shadows[i])
			end
			for i = 1, #mg_labels do
				mg_remove(mg_labels[i])
			end
			table.clear(mg_lines)
			table.clear(mg_shadows)
			table.clear(mg_labels)
			table.clear(mg_history)
			mg_accum = 0
			mg_render_accum = 0
		end

		local function mg_reset_history()
			table.clear(mg_history)
			local now = os.clock()
			local speed = mg_speed()
			mg_smooth = speed
			local count = math.ceil(mg_span / mg_step)
			for i = 0, count do
				mg_history[#mg_history + 1] = {
					t = now - mg_span + i * mg_step,
					v = speed
				}
			end
			mg_sync_pool(#mg_history)
		end

		local function mg_apply_style()
			if mg_current then mg_current.Color = mg_color end
			for i = 1, #mg_lines do
				mg_lines[i].Color = mg_color
				mg_lines[i].Thickness = mg_thickness
				mg_shadows[i].Thickness = mg_thickness + 2
			end
			for i = 1, #mg_labels do
				mg_labels[i].Color = mg_color
			end
		end

		local function mg_y(value, center, height, reference)
			local normalized = math.clamp(value / reference - 1, -1, 1)
			return center - normalized * height * 0.44
		end

		local function mg_render(now)
			local camera = ws.CurrentCamera
			if not mg_on or not camera or #mg_history < 2 then
				mg_hide()
				return
			end
			local viewport = camera.ViewportSize
			local width = math.min(mg_width, math.max(120, viewport.X - 48))
			local height = math.min(mg_height, math.max(36, viewport.Y - 32))
			local left = math.floor(viewport.X * 0.5 - width * 0.5)
			local center = math.clamp(math.floor(viewport.Y * 0.5 + mg_offset), height * 0.5 + 8, viewport.Y - height * 0.5 - 8)
			local reference = mg_reference()
			local start_time = now - mg_span
			local count = #mg_history
			mg_sync_pool(count)
			for i = 1, count - 1 do
				local a = mg_history[i]
				local b = mg_history[i + 1]
				local ap = math.clamp((a.t - start_time) / mg_span, 0, 1)
				local bp = math.clamp((b.t - start_time) / mg_span, 0, 1)
				local fade = math.clamp(math.min((ap + bp) * 6, (2 - ap - bp) * 5), 0, 1)
				local from = Vector2.new(left + ap * width, mg_y(a.v, center, height, reference))
				local to = Vector2.new(left + bp * width, mg_y(b.v, center, height, reference))
				local line = mg_lines[i]
				local shadow = mg_shadows[i]
				line.From, line.To = from, to
				line.Transparency = fade
				line.Visible = fade > 0.02
				shadow.From, shadow.To = from, to
				shadow.Transparency = fade * 0.42
				shadow.Visible = fade > 0.02
			end
			local last = mg_history[count]
			local lpct = math.clamp((last.t - start_time) / mg_span, 0, 1)
			local from = Vector2.new(left + lpct * width, mg_y(last.v, center, height, reference))
			local to = Vector2.new(left + width, mg_y(mg_smooth, center, height, reference))
			local tail = mg_lines[count]
			local tail_shadow = mg_shadows[count]
			tail.From, tail.To = from, to
			tail.Transparency = 0.72
			tail.Visible = true
			tail_shadow.From, tail_shadow.To = from, to
			tail_shadow.Transparency = 0.3
			tail_shadow.Visible = true
			for i = count + 1, #mg_lines do
				mg_lines[i].Visible = false
				mg_shadows[i].Visible = false
			end
			mg_current.Text = tostring(math.floor(mg_smooth + 0.5))
			mg_current.Position = Vector2.new(left + width + 5, to.Y - 7)
			mg_current.Color = mg_color
			mg_current.Visible = true
			while #mg_labels < 12 do
				mg_labels[#mg_labels + 1] = mg_new_text()
			end
			local threshold = math.max(0.8, reference * 0.08)
			local min_label_gap = 0.42
			for i = 5, count - 4 do
				local point = mg_history[i]
				if not point.checked then
					point.checked = true
					local before = point.v - mg_history[i - 4].v
					local after = mg_history[i + 4].v - point.v
					if math.abs(before) >= threshold and (before * after <= 0 or math.abs(after) < threshold * 0.35) then
						local nearby = nil
						for j = i - 1, 1, -1 do
							local previous = mg_history[j]
							if point.t - previous.t > min_label_gap then break end
							if previous.label ~= nil then
								nearby = previous
								break
							end
						end
						local score = math.abs(before) - math.abs(after)
						if not nearby then
							point.label = math.floor(point.v + 0.5)
							point.label_score = score
						elseif score > (nearby.label_score or -math.huge) then
							nearby.label = nil
							nearby.label_score = nil
							point.label = math.floor(point.v + 0.5)
							point.label_score = score
						end
					end
				end
			end
			for i = 1, #mg_labels do
				mg_labels[i].Visible = false
			end
			local placed = {}
			local label_count = 0
			for i = count, 1, -1 do
				local point = mg_history[i]
				if point.label ~= nil and label_count < #mg_labels then
					local pct = (point.t - start_time) / mg_span
					if pct > 0.04 and pct < 0.82 then
						local value = tostring(point.label)
						local x = left + pct * width
						local y = mg_y(point.v, center, height, reference) - 15
						local half_width = math.max(8, #value * 3.5 + 2)
						local blocked = false
						for j = 1, #placed do
							local other = placed[j]
							if x + half_width + 5 > other.x1 and x - half_width - 5 < other.x2 and y + 13 > other.y1 and y - 3 < other.y2 then
								blocked = true
								break
							end
						end
						if not blocked then
							label_count = label_count + 1
							local text = mg_labels[label_count]
							text.Text = value
							text.Position = Vector2.new(x, y)
							text.Color = mg_color
							text.Visible = true
							placed[#placed + 1] = {
								x1 = x - half_width,
								x2 = x + half_width,
								y1 = y - 3,
								y2 = y + 13
							}
						end
					end
				end
			end
		end

		mg_offset = 180

		local function mg_start()
			mg_clear()
			mg_create()
			mg_reset_history()
			mg_apply_style()
			mg_conn = run.RenderStepped:Connect(function(dt)
				if not __ALIVE() or not mg_on then
					mg_hide()
					return
				end
				local raw = mg_speed()
				mg_smooth = mg_smooth + (raw - mg_smooth) * (1 - math.exp(-dt * 18))
				mg_accum = mg_accum + dt
				local now = os.clock()
				if mg_accum >= mg_step then
					mg_accum = mg_accum % mg_step
					mg_history[#mg_history + 1] = { t = now, v = mg_smooth }
					local cutoff = now - mg_span
					while #mg_history > 2 and mg_history[2].t < cutoff do
						table.remove(mg_history, 1)
					end
				end
				mg_render_accum += dt
				if mg_render_accum >= 1 / 60 then
					mg_render_accum %= 1 / 60
					mg_render(now)
				end
			end)
		end

		MG.On = false
		MG.Color     = mg_color
		MG.Width     = mg_width
		MG.Height    = mg_height
		MG.Thickness = mg_thickness
		MG.OffsetY   = mg_offset

		ESP.MotionGraphSet = { set = function(k, v)
			if k == "color" then
				mg_color = v
				mg_apply_style()
			elseif k == "width" then
				mg_width = v
			elseif k == "height" then
				mg_height = v
			elseif k == "y" then
				mg_offset = v
			elseif k == "thickness" then
				mg_thickness = v
				mg_apply_style()
			end
			MG.Color, MG.Width, MG.Height, MG.OffsetY, MG.Thickness = mg_color, mg_width, mg_height, mg_offset, mg_thickness
		end }

		ESP.StartMotionGraph = function()
			mg_on = true
			MG.On = true
			mg_start()
		end

		ESP.ClearMotionGraph = function()
			mg_on = false
			MG.On = false
			mg_clear()
		end

		ESP.MotionGraphStyle = mg_apply_style

		NeverLose:AddSignal(lp.CharacterAdded:Connect(function()
			task.wait(0.4)
			if __ALIVE() and mg_on then mg_reset_history() end
		end))

	local row = Sections.Screen:AddLabel("Motion Graph");
	row:AddToggle({
		Default = false, Flag = "motion_graph",
		Callback = function(v)
			if v then ESP.StartMotionGraph() else ESP.ClearMotionGraph() end;
		end,
	});
	row:AddColorPicker({
		Default = MG.Color, Flag = "motion_graph_color",
		Callback = function(v) ESP.MotionGraphSet.set("color", v) end,
	});

	local options = row:AddOption(1);

	options:AddLabel("Width"):AddSlider({
		Min = 120, Max = 600, Default = 280, Rounding = 0, Size = 90,
		Flag = "motion_graph_width",
		Callback = function(v) ESP.MotionGraphSet.set("width", v) end,
	});

	options:AddLabel("Height"):AddSlider({
		Min = 30, Max = 200, Default = 72, Rounding = 0, Size = 90,
		Flag = "motion_graph_height",
		Callback = function(v) ESP.MotionGraphSet.set("height", v) end,
	});

	options:AddLabel("Offset"):AddSlider({
		Min = 40, Max = 400, Default = 180, Rounding = 0, Size = 90,
		Flag = "motion_graph_offset",
		Callback = function(v) ESP.MotionGraphSet.set("y", v) end,
	});

	options:AddLabel("Thickness"):AddSlider({
		Min = 1, Max = 5, Default = 1, Rounding = 0, Size = 90,
		Flag = "motion_graph_thickness",
		Callback = function(v) ESP.MotionGraphSet.set("thickness", v) end,
	});
end;
