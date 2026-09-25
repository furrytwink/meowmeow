--!nonstrict
--[[
	misc.lua — extracted feature module (require id "modules.misc").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("misc") in the driver — byte-frozen original
	code below the marker (re-derived on every `make extract`; do not hand-edit).

	The block originally closed over driver locals; the driver now passes them
	in via the ctx table:

		guard("misc", function()
			return require("modules.misc")({ ESP = ESP, GLOBAL = GLOBAL, LocalPlayer = LocalPlayer, NeverLose = NeverLose, Players = Players, RunService = RunService, Sections = Sections, onUnload = onUnload });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local GLOBAL = ctx.GLOBAL;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local Players = ctx.Players;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local onUnload = ctx.onUnload;

-- [ guard("misc") callback body — byte-exact from input/message(47).txt ]
	local players = Players;
	local run = RunService;
	local lp = LocalPlayer;
	local ws = workspace;
	local uis = game:GetService("UserInputService");
	local cs = game:GetService("CollectionService");
	local rs = game:GetService("ReplicatedStorage");
	local vu = game:GetService("VirtualUser");

	local function get_hrp()
		local c = lp.Character
		return c and c:FindFirstChild("HumanoidRootPart")
	end

	local function get_hum()
		local c = lp.Character
		return c and c:FindFirstChildOfClass("Humanoid")
	end

	local anti_afk, anti_fling, anti_void, anti_trap = true, false, false, false
	local coin_on = false
	local fade_on = false
	local void_original = ws.FallenPartsDestroyHeight
	local noclip_on, fly_on = false, false
	local inf_jump_on, wallhop_on = false, false
	local noclip_cache = {}
	local fling_cache = {}
	local last_coin_backup = nil

	local ws_on, ws_value = false, 40
	local jp_on, jp_value = false, 80

	local function kill_container(d)
		pcall(function()
			d.Archivable = true
			last_coin_backup = { clone = d:Clone(), parent = d.Parent }
			d:Destroy()
		end)
	end

	local function wipe_coins()
		for _, v in ipairs(cs:GetTagged("CoinVisual")) do
			pcall(function() v:Destroy() end)
		end
		for _, d in ipairs(ws:GetDescendants()) do
			if d.Name == "CoinContainer" then
				kill_container(d)
			end
		end
	end

	local function restore_coins()
		if last_coin_backup and last_coin_backup.clone then
			pcall(function()
				last_coin_backup.clone.Parent = last_coin_backup.parent or ws
			end)
			last_coin_backup = nil
		end
	end
	local player_gui = lp:FindFirstChildOfClass("PlayerGui")
	local fade_cache = {}
	local fade_conns = {}

	local FADE_GUI_NAMES = { CameraFade = true, SpawnFade = true, Fade = true, DeathFade = true }
	local fade_desc_conn = nil

	local function fade_gui()
		if player_gui and player_gui.Parent then return player_gui end
		player_gui = lp:FindFirstChildOfClass("PlayerGui")
		return player_gui
	end

	local function fade_hide(frame)
		if not frame or not frame.Parent or not frame:IsA("GuiObject") then return end
		if fade_cache[frame] == nil then fade_cache[frame] = frame.Visible end
		if frame.Visible then pcall(function() frame.Visible = false end) end
		if not fade_conns[frame] then
			fade_conns[frame] = frame:GetPropertyChangedSignal("Visible"):Connect(function()
				if fade_on and frame.Visible then
					pcall(function() frame.Visible = false end)
				end
			end)
		end
	end

	local function fade_match(inst)
		if not inst:IsA("GuiObject") then return false end
		local parent = inst.Parent
		if not parent then return false end
		if (inst.Name == "Fade" or inst.Name == "Frame") and parent:IsA("ScreenGui") and FADE_GUI_NAMES[parent.Name] then
			return true
		end
		if inst.Name == "Fade" and parent.Name == "Game" then
			return true
		end
		return false
	end

	local function fade_targets()
		local list = {}
		local gui = fade_gui()
		if not gui then return list end
		for _, child in ipairs(gui:GetChildren()) do
			if child:IsA("ScreenGui") and FADE_GUI_NAMES[child.Name] then
				for _, sub in ipairs(child:GetChildren()) do
					if sub:IsA("GuiObject") and (sub.Name == "Fade" or sub.Name == "Frame") then
						list[#list + 1] = sub
					end
				end
			end
		end
		local main = gui:FindFirstChild("MainGUI")
		local gg = main and main:FindFirstChild("Game")
		local gf = gg and gg:FindFirstChild("Fade")
		if gf and gf:IsA("GuiObject") then list[#list + 1] = gf end
		return list
	end

	local function fade_watch()
		if fade_desc_conn then return end
		local gui = fade_gui()
		if not gui then return end
		fade_desc_conn = gui.DescendantAdded:Connect(function(d)
			if not fade_on then return end
			if not fade_match(d) then return end
			task.defer(function()
				if fade_on and d.Parent then pcall(fade_hide, d) end
			end)
		end)
	end

	local function fade_apply()
		fade_watch()
		for _, frame in ipairs(fade_targets()) do
			pcall(fade_hide, frame)
		end
	end

	local function fade_restore()
		for _, conn in pairs(fade_conns) do
			pcall(function() conn:Disconnect() end)
		end
		fade_conns = {}
		for frame, v in pairs(fade_cache) do
			if frame and frame.Parent then
				pcall(function()
					frame.Visible = v
				end)
			end
		end
		fade_cache = {}
	end
	local FLING_MAX_VEL = 700
	local FLING_MAX_ANG = 90
	local FLING_SNAP_DIST = 60
	local FLING_HOLD = 0.25
	local FLING_SAFE_VEL = 250

	local fling_reg = {}
	local fling_conns = {}
	local fling_attached = false
	local fling_safe_cf = nil
	local fling_hold_until = 0

	local fling_active_since = 0

	local function fling_busy()
		if fly_on then return true end
		if os.clock() < (tonumber(GLOBAL.VELOCITY_DESYNC_UNTIL) or 0) then return true end
		if (tonumber(GLOBAL.FLING_ACTIVE) or 0) > 0 then
			local now = os.clock()
			if fling_active_since == 0 then fling_active_since = now end
			if now - fling_active_since < 20 then return true end
			GLOBAL.FLING_ACTIVE = 0
			fling_active_since = 0
			return false
		end
		fling_active_since = 0
		return false
	end

	local function fling_kill_part(p)
		if fling_cache[p] == nil then fling_cache[p] = p.CanCollide end
		if p.CanCollide then p.CanCollide = false end
	end

	local function fling_unregister(model)
		local entry = fling_reg[model]
		if not entry then return end
		fling_reg[model] = nil
		for i = 1, #entry.conns do
			pcall(function() entry.conns[i]:Disconnect() end)
		end
		for p in pairs(entry.parts) do
			local v = fling_cache[p]
			fling_cache[p] = nil
			if v ~= nil and p.Parent then
				pcall(function() p.CanCollide = v end)
			end
		end
		table.clear(entry.parts)
	end

	local function fling_register(model)
		if not anti_fling or not model then return end
		if fling_reg[model] or model == lp.Character then return end
		local entry = { parts = {}, conns = {} }
		fling_reg[model] = entry
		local function add(d)
			if d:IsA("BasePart") and not entry.parts[d] then
				entry.parts[d] = true
				if anti_fling then pcall(fling_kill_part, d) end
			end
		end
		for _, d in model:GetDescendants() do
			pcall(add, d)
		end
		local function push(c) entry.conns[#entry.conns + 1] = c end
		push(model.DescendantAdded:Connect(function(d)
			if anti_fling then pcall(add, d) end
		end))
		push(model.DescendantRemoving:Connect(function(d)
			if entry.parts[d] then
				entry.parts[d] = nil
				fling_cache[d] = nil
			end
		end))
		push(model.AncestryChanged:Connect(function(_, parent)
			if not parent then fling_unregister(model) end
		end))
	end

	local function fling_is_body(m)
		return m ~= lp.Character
			and m:IsA("Model")
			and m:FindFirstChildOfClass("Humanoid") ~= nil
	end

	local function fling_scan()
		for _, pl in players:GetPlayers() do
			if pl ~= lp and pl.Character then fling_register(pl.Character) end
		end
		for _, m in ws:GetChildren() do
			if fling_is_body(m) then fling_register(m) end
		end
	end

	local function fling_sweep()
		for model, entry in pairs(fling_reg) do
			if not model.Parent or model == lp.Character then
				fling_unregister(model)
			else
				for p in pairs(entry.parts) do
					if p.Parent then
						if p.CanCollide then
							if fling_cache[p] == nil then fling_cache[p] = true end
							p.CanCollide = false
						end
					else
						entry.parts[p] = nil
						fling_cache[p] = nil
					end
				end
			end
		end
	end

	local function fling_guard(full)
		local hrp = get_hrp()
		if not hrp or not hrp.Parent then
			fling_safe_cf = nil
			return
		end
		if fling_busy() then
			fling_safe_cf = nil
			return
		end
		local lin = hrp.AssemblyLinearVelocity
		local ang = hrp.AssemblyAngularVelocity
		local spike = lin.Magnitude > FLING_MAX_VEL or ang.Magnitude > FLING_MAX_ANG
		local now = os.clock()
		if spike then fling_hold_until = now + FLING_HOLD end
		if spike or now < fling_hold_until then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			if full and fling_safe_cf then
				if (hrp.Position - fling_safe_cf.Position).Magnitude > FLING_SNAP_DIST then
					hrp.CFrame = fling_safe_cf
				end
			end
		elseif full and lin.Magnitude < FLING_SAFE_VEL then
			fling_safe_cf = hrp.CFrame
		end
	end

	local function fling_detach()
		fling_attached = false
		for i = 1, #fling_conns do
			pcall(function() fling_conns[i]:Disconnect() end)
		end
		table.clear(fling_conns)
	end

	local function fling_attach()
		if fling_attached then return end
		fling_attached = true
		local function push(c) fling_conns[#fling_conns + 1] = c end
		local function watch(pl)
			if pl == lp then return end
			push(pl.CharacterAdded:Connect(function(c)
				if anti_fling then fling_register(c) end
			end))
			push(pl.CharacterRemoving:Connect(function(c)
				fling_unregister(c)
			end))
		end
		for _, pl in players:GetPlayers() do watch(pl) end
		push(players.PlayerAdded:Connect(function(pl)
			watch(pl)
			if anti_fling and pl.Character then fling_register(pl.Character) end
		end))
		push(players.PlayerRemoving:Connect(function(pl)
			if pl.Character then fling_unregister(pl.Character) end
		end))
		push(ws.ChildAdded:Connect(function(m)
			if not anti_fling then return end
			task.defer(function()
				if anti_fling and m.Parent == ws and fling_is_body(m) then
					fling_register(m)
				end
			end)
		end))
		push(lp.CharacterAdded:Connect(function(c)
			fling_unregister(c)
			fling_safe_cf = nil
			fling_hold_until = 0
			if anti_fling then task.defer(fling_scan) end
		end))
		fling_scan()
	end

	local function fling_restore()
		fling_detach()
		for model in pairs(fling_reg) do
			fling_unregister(model)
		end
		table.clear(fling_reg)
		for p, v in pairs(fling_cache) do
			if p and p.Parent then pcall(function() p.CanCollide = v end) end
		end
		table.clear(fling_cache)
		fling_safe_cf = nil
		fling_hold_until = 0
	end
	local TRAP_LOCK = 1
	local TRAP_HOLD = 5
	local trap_window = 0
	local trap_busy = false
	local trap_speed_cache = 16
	local trap_jump_cache = 50
	local trap_hit_conn = nil

	local function trap_hum()
		local c = lp.Character
		return c and c:FindFirstChildOfClass("Humanoid")
	end

	local function trap_kill_gui()
		local gui = fade_gui()
		if not gui then return end
		for _, child in ipairs(gui:GetChildren()) do
			if child.Name == "TrapGUI" then
				pcall(function() child:Destroy() end)
			end
		end
	end

	local function trap_unlock(hum)
		if not hum or not hum.Parent then return end
		pcall(function()
			if hum.WalkSpeed <= TRAP_LOCK then hum.WalkSpeed = trap_speed_cache end
			if hum.JumpPower <= TRAP_LOCK then hum.JumpPower = trap_jump_cache end
		end)
	end

	local function trap_engage()
		if not anti_trap then return end
		trap_window = os.clock() + TRAP_HOLD
		local hum = trap_hum()
		if hum then
			if hum.WalkSpeed > TRAP_LOCK then trap_speed_cache = hum.WalkSpeed end
			if hum.JumpPower > TRAP_LOCK then trap_jump_cache = hum.JumpPower end
		end
		trap_kill_gui()
		if trap_busy then return end
		trap_busy = true
		task.spawn(function()
			while anti_trap and os.clock() < trap_window do
				trap_unlock(trap_hum())
				trap_kill_gui()
				run.Heartbeat:Wait()
			end
			trap_busy = false
		end)
	end

	local function trap_attach()
		if trap_hit_conn then return end
		local ok, remote = pcall(function()
			local sys = rs:FindFirstChild("TrapSystem")
			return sys and sys:FindFirstChild("TrapHitLocal")
		end)
		if not ok or not remote then return end
		trap_hit_conn = remote.OnClientEvent:Connect(function()
			task.spawn(trap_engage)
		end)
	end

	local function trap_detach()
		if trap_hit_conn then
			pcall(function() trap_hit_conn:Disconnect() end)
			trap_hit_conn = nil
		end
		trap_window = 0
		trap_unlock(trap_hum())
	end
	local function noclip_restore()
		for p, v in pairs(noclip_cache) do
			if p and p.Parent then p.CanCollide = v end
		end
		noclip_cache = {}
	end

	local part_index = setmetatable({}, { __mode = "k" })

	local function char_parts(char)
		local entry = part_index[char]
		if not entry then
			entry = { list = {}, valid = false }
			part_index[char] = entry
			local function dirty(d)
				if d:IsA("BasePart") then entry.valid = false end
			end
			entry.added = char.DescendantAdded:Connect(dirty)
			entry.removing = char.DescendantRemoving:Connect(dirty)
		end
		if not entry.valid then
			local list = entry.list
			table.clear(list)
			local n = 0
			for _, p in char:GetDescendants() do
				if p:IsA("BasePart") then
					n = n + 1
					list[n] = p
				end
			end
			entry.valid = true
		end
		return entry.list
	end

	local function release_part_index()
		for _, entry in pairs(part_index) do
			if entry.added then pcall(function() entry.added:Disconnect() end) end
			if entry.removing then pcall(function() entry.removing:Disconnect() end) end
		end
		part_index = setmetatable({}, { __mode = "k" })
	end

	local step_conn = run.Stepped:Connect(function()
		if anti_fling then
			if not fling_attached then pcall(fling_attach) end
			pcall(fling_sweep)
			pcall(fling_guard, true)
		end
		if noclip_on then
			if (tonumber(GLOBAL.FLING_ACTIVE) or 0) == 0 then
				local c = lp.Character
				if c then
					local list = char_parts(c)
					for i = 1, #list do
						local p = list[i]
						if p.Parent and p.CanCollide then
							if noclip_cache[p] == nil then noclip_cache[p] = p.CanCollide end
							p.CanCollide = false
						end
					end
				end
			elseif next(noclip_cache) then
				noclip_restore()
			end
		end
	end)

	local fling_beat_conn = run.Heartbeat:Connect(function()
		if anti_fling then
			pcall(fling_guard, false)
		end
	end)
	local controls_ref = nil
	local function get_controls()
		if controls_ref then return controls_ref end
		local ok, res = pcall(function()
			local ps = lp:FindFirstChild("PlayerScripts")
			local pm = ps and ps:FindFirstChild("PlayerModule")
			if not pm then return nil end
			return require(pm):GetControls()
		end)
		if ok and res then controls_ref = res end
		return controls_ref
	end

	local function flat_unit(v)
		local f = Vector3.new(v.X, 0, v.Z)
		if f.Magnitude > 0 then return f.Unit end
		return Vector3.zero
	end

	local function get_move_vector(cam)
		local c = get_controls()
		if c then
			local ok, v = pcall(function() return c:GetMoveVector() end)
			if ok and typeof(v) == "Vector3" and v.Magnitude > 0.05 then
				return v
			end
		end
		local ch = lp.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hum and cam then
			local md = hum.MoveDirection
			if md.Magnitude > 0.05 then
				local ff, fr = flat_unit(cam.CFrame.LookVector), flat_unit(cam.CFrame.RightVector)
				return Vector3.new(md:Dot(fr), 0, -md:Dot(ff))
			end
		end
		return Vector3.zero
	end

	local hop_params = RaycastParams.new()
	hop_params.FilterType = Enum.RaycastFilterType.Exclude
	hop_params.IgnoreWater = true
	local hop_ang = { 0, 0.45, -0.45, 0.9, -0.9, 1.4, -1.4, 2, -2, 2.6, -2.6, 3.14 }

	local function hop_wall(hrp, hum)
		local cam = ws.CurrentCamera
		local base = flat_unit(hum.MoveDirection)
		if base == Vector3.zero then
			base = cam and flat_unit(cam.CFrame.LookVector) or Vector3.zero
		end
		if base == Vector3.zero then return nil end
		hop_params.FilterDescendantsInstances = { lp.Character }
		local pos = hrp.Position
		for i = 1, #hop_ang do
			local c, s = math.cos(hop_ang[i]), math.sin(hop_ang[i])
			local dir = Vector3.new(base.X * c + base.Z * s, 0, base.Z * c - base.X * s) * 3
			local hit = ws:Raycast(pos, dir, hop_params)
			if not hit then
				hit = ws:Raycast(pos - Vector3.new(0, 2, 0), dir, hop_params)
			end
			if hit and math.abs(hit.Normal.Y) < 0.5 then return hit end
		end
		return nil
	end

	local hop_scan_t = 0
	local jump_conn = uis.JumpRequest:Connect(function()
		if fly_on or (not inf_jump_on and not wallhop_on) then return end
		local hrp = get_hrp()
		local ch = lp.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then return end
		if inf_jump_on then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			return
		end
		if hum.FloorMaterial ~= Enum.Material.Air then return end
		local now = os.clock()
		if now - hop_scan_t < 0.1 then return end
		hop_scan_t = now
		local wall = hop_wall(hrp, hum)
		if not wall then return end
		local n = flat_unit(wall.Normal)
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
		local v = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = Vector3.new(v.X + n.X * 3, v.Y, v.Z + n.Z * 3)
	end)

	local vim = nil
	pcall(function() vim = game:GetService("VirtualInputManager") end)

	local function keep_awake()
		local ok = pcall(function()
			vu:CaptureController()
			vu:ClickButton2(Vector2.new())
		end)
		if ok or not vim then return end
		pcall(function()
			local at = uis:GetMouseLocation()
			vim:SendMouseMoveEvent(at.X, at.Y, game)
		end)
	end

	local idle_conn = lp.Idled:Connect(function()
		if anti_afk then keep_awake() end
	end)

	local coin_conn = cs:GetInstanceAddedSignal("CoinVisual"):Connect(function(v)
		if coin_on then
			task.wait()
			if coin_on then pcall(function() v:Destroy() end) end
		end
	end)

	local coin_desc_conn = ws.DescendantAdded:Connect(function(d)
		if coin_on and d.Name == "CoinContainer" then
			task.wait()
			if coin_on then kill_container(d) end
		end
	end)

	local sprint_on, sprint_held, sprint_prev = false, false, nil
	local sprint_speed = 60
	local bhop_on = false
	local fly_mode = "Velocity"
	local walk_mode = "WalkSpeed"

	local speed_conn = run.Stepped:Connect(function()

		if not (ws_on or jp_on or sprint_held) then return end

		local hum = get_hum()
		if not hum then return end
		if sprint_held and sprint_speed > 0 then
			if hum.WalkSpeed ~= sprint_speed then
				hum.WalkSpeed = sprint_speed
			end
		elseif ws_on then
			local target = walk_mode == "CFrame" and 0 or ws_value

			if hum.WalkSpeed ~= target then hum.WalkSpeed = target end
		end
		if jp_on then
			if not hum.UseJumpPower then hum.UseJumpPower = true end
			if hum.JumpPower ~= jp_value then hum.JumpPower = jp_value end
		end
	end)

	local ws_original, jp_original, use_jp_original = nil, nil, nil

	Sections.Anti:AddLabel("Anti Fling"):AddToggle({
		Name = "Anti Fling",
		Default = false,
		Flag = "anti_fling",
		ToolTip = "Blocks fling",
		Callback = function(v)
			if v == anti_fling then return end;

			anti_fling = v;

			if v then fling_attach() else fling_restore() end;
		end,
	});

	Sections.Anti:AddLabel("Anti Blackout"):AddToggle({
		Name = "Anti Blackout",
		Default = false,
		Flag = "anti_blackout",
		ToolTip = "Blocks screen fades",
		Callback = function(v)
			if v == fade_on then return end;

			fade_on = v;

			if v then fade_apply() else fade_restore() end;
		end,
	});

	Sections.Anti:AddLabel("Anti AFK"):AddToggle({
		Name = "Anti AFK",
		Default = true,
		Flag = "anti_afk",
		ToolTip = "Prevents AFK kick",
		Callback = function(v) anti_afk = v end,
	});

	local fly_speed = 60

	local function capture_move()
		local hum = get_hum()
		if not hum then return end
		if ws_original == nil then ws_original = hum.WalkSpeed end
		if jp_original == nil then jp_original = hum.JumpPower end
		if use_jp_original == nil then use_jp_original = hum.UseJumpPower end
	end

	local function release_move()
		local hum = get_hum()

		if hum and ws_original then
			pcall(function() hum.WalkSpeed = ws_original end)
		end

		ws_original = nil
	end

	local function release_jump()
		local hum = get_hum()

		if hum and jp_original then
			pcall(function()
				hum.JumpPower = jp_original

				if use_jp_original ~= nil then hum.UseJumpPower = use_jp_original end
			end)
		end

		jp_original, use_jp_original = nil, nil
	end

	NeverLose:AddSignal(lp.CharacterAdded:Connect(function()
		ws_original, jp_original, use_jp_original = nil, nil, nil

		task.wait(0.6)

		if ws_on or jp_on then capture_move() end
	end))

	local function cframe_walk(dt)
		if fly_on then return end

		local hrp = get_hrp()
		local hum = get_hum()
		local cam = ws.CurrentCamera

		if not hrp or not hum or hum.Health <= 0 or not cam then return end

		local cf = cam.CFrame
		local flat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
		local side = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)

		flat = flat.Magnitude > 0.001 and flat.Unit or Vector3.new(0, 0, -1)
		side = side.Magnitude > 0.001 and side.Unit or Vector3.new(1, 0, 0)

		local wish = Vector3.zero

		if uis:IsKeyDown(Enum.KeyCode.W) then wish = wish + flat end
		if uis:IsKeyDown(Enum.KeyCode.S) then wish = wish - flat end
		if uis:IsKeyDown(Enum.KeyCode.D) then wish = wish + side end
		if uis:IsKeyDown(Enum.KeyCode.A) then wish = wish - side end

		if wish.Magnitude < 0.01 then return end

		wish = wish.Unit

		local pos = hrp.Position + wish * ws_value * dt

		hrp.CFrame = CFrame.lookAt(pos, pos + wish)
	end

	local fly_conn = run.Heartbeat:Connect(function(dt)
		if not fly_on then return end

		local hrp = get_hrp()
		local hum = get_hum()
		local cam = ws.CurrentCamera

		if not hrp or not hum or hum.Health <= 0 or not cam then return end

		local cf = cam.CFrame
		local wish = Vector3.zero

		if uis:IsKeyDown(Enum.KeyCode.W) then wish = wish + cf.LookVector end
		if uis:IsKeyDown(Enum.KeyCode.S) then wish = wish - cf.LookVector end
		if uis:IsKeyDown(Enum.KeyCode.D) then wish = wish + cf.RightVector end
		if uis:IsKeyDown(Enum.KeyCode.A) then wish = wish - cf.RightVector end
		if uis:IsKeyDown(Enum.KeyCode.Space) then wish = wish + Vector3.yAxis end

		if uis:IsKeyDown(Enum.KeyCode.LeftControl) or uis:IsKeyDown(Enum.KeyCode.C) then
			wish = wish - Vector3.yAxis
		end

		if wish.Magnitude > 1 then wish = wish.Unit end

		if fly_mode == "CFrame" then
			hrp.CFrame = hrp.CFrame + wish * fly_speed * dt
			hrp.AssemblyLinearVelocity = Vector3.zero
		else
			hrp.AssemblyLinearVelocity = wish * fly_speed
		end

		hrp.AssemblyAngularVelocity = Vector3.zero
	end)

	local move_conn = run.Heartbeat:Connect(function(dt)
		if ws_on and walk_mode == "CFrame" then cframe_walk(dt) end

		local hum = get_hum()

		if sprint_on and hum and hum.Health > 0 then
			local held = uis:IsKeyDown(Enum.KeyCode.LeftShift)

			if held and not sprint_held then
				sprint_prev = hum.WalkSpeed
			end

			if not held and sprint_held and not ws_on and sprint_prev ~= nil then
				hum.WalkSpeed = sprint_prev
			end

			sprint_held = held

			if not held then sprint_prev = nil end
		elseif sprint_held then
			sprint_held = false

			if hum and not ws_on and sprint_prev ~= nil then
				hum.WalkSpeed = sprint_prev
			end

			sprint_prev = nil
		end

		if bhop_on and hum and hum.Health > 0 and hum.FloorMaterial ~= Enum.Material.Air then
			hum:ChangeState(Enum.HumanoidStateType.Jump)
		end
	end)

	Sections.FunMove:AddLabel("Noclip"):AddToggle({
		Name = "Noclip",
		Default = false,
		Flag = "fun_noclip",
		ToolTip = "Walk through walls",
		Callback = function(v)
			noclip_on = v

			if not v then pcall(noclip_restore) end
		end,
	});

	Sections.FunMove:AddLabel("Fly"):AddToggle({
		Name = "Fly",
		Default = false,
		Flag = "fun_fly",
		ToolTip = "WASD, Space up, Ctrl down",
		Callback = function(v)
			fly_on = v

			if not v then pcall(function()
				local hrp = get_hrp()
				if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
			end) end
		end,
	});

	Sections.FunMove:AddLabel("Fly Speed"):AddSlider({
		Name = "Fly Speed",
		Min = 10, Max = 400, Default = 60, Rounding = 0, Size = 110,
		Flag = "fun_fly_speed",
		Callback = function(v) fly_speed = v end,
	});

	Sections.FunMove:AddLabel("Fly Mode"):AddDropdown({
		Name = "Fly Mode",
		Default = "Velocity",
		Values = { "Velocity", "CFrame" },
		Flag = "fun_fly_mode",
		ToolTip = "Velocity: pushes the body. CFrame: places it every frame - pair with Noclip",
		Callback = function(v) fly_mode = v == "CFrame" and "CFrame" or "Velocity" end,
	});

	Sections.FunMove:AddLabel("Infinite Jump"):AddToggle({
		Name = "Infinite Jump",
		Default = false,
		Flag = "fun_inf_jump",
		ToolTip = "Jump while airborne",
		Callback = function(v) inf_jump_on = v end,
	});

	Sections.FunMove:AddLabel("Wall Jump"):AddToggle({
		Name = "Wall Jump",
		Default = false,
		Flag = "fun_wall_jump",
		ToolTip = "Hop off walls",
		Callback = function(v) wallhop_on = v end,
	});

	Sections.FunJump:AddLabel("Walk Speed"):AddToggle({
		Name = "Walk Speed",
		Default = false,
		Flag = "fun_speed_on",
		Callback = function(v)
			ws_on = v

			if v then capture_move() else release_move() end
		end,
	});

	Sections.FunJump:AddLabel("Speed"):AddSlider({
		Name = "Speed",
		Min = 16, Max = 250, Default = 40, Rounding = 0, Size = 110,
		Flag = "fun_speed_value",
		Callback = function(v) ws_value = v end,
	});

	Sections.FunJump:AddLabel("Walk Mode"):AddDropdown({
		Name = "Walk Mode",
		Default = "WalkSpeed",
		Values = { "WalkSpeed", "CFrame" },
		Flag = "fun_walk_mode",
		ToolTip = "WalkSpeed: edits the humanoid. CFrame: moves you each frame, past game speed locks",
		Callback = function(v) walk_mode = v == "CFrame" and "CFrame" or "WalkSpeed" end,
	});

	Sections.FunJump:AddLabel("Jump Power"):AddToggle({
		Name = "Jump Power",
		Default = false,
		Flag = "fun_jump_on",
		Callback = function(v)
			jp_on = v

			if v then capture_move() else release_jump() end
		end,
	});

	Sections.FunJump:AddLabel("Jump Height"):AddSlider({
		Name = "Jump Height",
		Min = 50, Max = 200, Default = 80, Rounding = 0, Size = 110,
		Flag = "fun_jump_value",
		Callback = function(v) jp_value = v end,
	});

	Sections.FunJump:AddLabel("Bunny Hop"):AddToggle({
		Name = "Bunny Hop",
		Default = false,
		Flag = "fun_bhop",
		ToolTip = "Jumps the moment you land",
		Callback = function(v) bhop_on = v end,
	});

	Sections.FunJump:AddLabel("Sprint"):AddToggle({
		Name = "Sprint",
		Default = false,
		Flag = "fun_sprint",
		ToolTip = "Hold Left Shift to dash",
		Callback = function(v)
			sprint_on = v

			if not v and sprint_held then
				sprint_held = false

				local hum = get_hum()

				if hum and not ws_on and sprint_prev ~= nil then hum.WalkSpeed = sprint_prev end

				sprint_prev = nil
			end
		end,
	});

	Sections.FunJump:AddLabel("Sprint Speed"):AddSlider({
		Name = "Sprint Speed",
		Min = 20, Max = 300, Default = 60, Rounding = 0, Size = 110,
		Flag = "fun_sprint_speed",
		Callback = function(v) sprint_speed = v end,
	});

	ESP.ClearMisc = onUnload("misc", function()
		anti_afk, anti_fling, anti_void, anti_trap = false, false, false, false
		coin_on, fade_on = false, false
		noclip_on, fly_on = false, false
		inf_jump_on, wallhop_on = false, false
		ws_on, jp_on = false, false
		bhop_on, sprint_on, sprint_held = false, false, false
		sprint_prev = nil

		pcall(function() ws.FallenPartsDestroyHeight = void_original end)

		for _, conn in ipairs({ idle_conn, coin_conn, coin_desc_conn, step_conn, fling_beat_conn, speed_conn, jump_conn, fly_conn, move_conn }) do
			pcall(function() conn:Disconnect() end)
		end

		if fade_desc_conn then pcall(function() fade_desc_conn:Disconnect() end) fade_desc_conn = nil end

		pcall(trap_detach)
		pcall(restore_coins)
		pcall(fade_restore)
		pcall(fling_restore)
		pcall(noclip_restore)
		pcall(release_part_index)

		local hum = get_hum()

		if hum then
			pcall(function()
				if ws_original then hum.WalkSpeed = ws_original end
				if jp_original then hum.JumpPower = jp_original end
				if use_jp_original ~= nil then hum.UseJumpPower = use_jp_original end
			end)
		end
	end);
end;
