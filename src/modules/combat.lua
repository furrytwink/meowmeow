--!nonstrict
--[[
	combat.lua — extracted feature module (require id "modules.combat").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("combat") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("combat", function()
			return require("modules.combat")({ ESP = ESP, GLOBAL = GLOBAL, LocalPlayer = LocalPlayer, NeverLose = NeverLose, Players = Players, Window = Window, getnamecallmethod = getnamecallmethod, onUnload = onUnload, scanDescendantsAsync = scanDescendantsAsync, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local GLOBAL = ctx.GLOBAL;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local Players = ctx.Players;
	local Window = ctx.Window;
	local getnamecallmethod = ctx.getnamecallmethod;
	local onUnload = ctx.onUnload;
	local scanDescendantsAsync = ctx.scanDescendantsAsync;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("combat") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local UserInputService = game:GetService("UserInputService");
	local Combat = {
		Attack = Instance.new("BindableEvent"),
		Hit = Instance.new("BindableEvent"),
		Kill = Instance.new("BindableEvent"),
	};
	for name, event in pairs(Combat) do if typeof(event) == "Instance" then event.Name = "VisualsCombat" .. name end end;
	local recent, humanoids, toolHooks = {}, {}, {};
	local mouse = LocalPlayer:GetMouse();
	local lastInputAt = -math.huge;

	local RANGED = { "gun", "pistol", "rifle", "revolver", "sniper", "shot", "bullet", "blaster", "bow", "crossbow", "cannon", "launcher", "firearm" };
	local MELEE = { "knife", "blade", "sword", "dagger", "katana", "axe", "bat", "hammer", "fist", "punch", "melee" };
	local ATTACK = { "fire", "shoot", "shot", "bullet", "hit", "damage", "attack", "swing", "stab", "slash", "knife", "weapon", "cast" };
	local function containsAny(text, words)
		text = string.lower(text or "");
		for _, word in ipairs(words) do if string.find(text, word, 1, true) then return true end end;
		return false;
	end;
	local function humanoidOf(value)
		if typeof(value) == "Instance" then
			if value:IsA("Humanoid") then return value end;
			if value:IsA("Player") then value = value.Character end;
			local node = value;
			for _ = 1, 5 do
				if not node then break end;
				local human = node:FindFirstChildOfClass("Humanoid");
				if human then return human end;
				node = node.Parent;
			end;
		end;
	end;
	local function rootOf(human)
		local model = human and human.Parent;
		return model and (human.RootPart or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart) or nil;
	end;
	local function localTool()
		local character = LocalPlayer.Character;
		return character and character:FindFirstChildOfClass("Tool") or nil;
	end;
	local function kindOf(tool, hint)
		local text = string.lower((tool and tool.Name or "") .. " " .. (hint or ""));
		if containsAny(text, RANGED) then return "shot" end;
		if containsAny(text, MELEE) then return "melee" end;
		if tool then
			for _, object in ipairs(tool:GetDescendants()) do
				local name = string.lower(object.Name);
				if name == "muzzle" or name == "firepoint" or name == "barrel" or name == "bulletspawn" then return "shot" end;
			end;
		end;
		return containsAny(hint, { "fire", "shoot", "shot", "bullet", "projectile", "ray" }) and "shot" or "attack";
	end;
	local function positionOf(value)
		if typeof(value) == "Vector3" then return value end;
		if typeof(value) == "CFrame" then return value.Position end;
		if typeof(value) == "Ray" then return value.Origin + value.Direction end;
		if typeof(value) == "Instance" then
			if value:IsA("Attachment") then return value.WorldPosition end;
			if value:IsA("BasePart") then return value.Position end;
			local root = value:IsA("Humanoid") and rootOf(value) or nil;
			if root then return root.Position end;
		end;
	end;
	local function originFor(tool)
		if tool then
			for _, name in ipairs({ "Muzzle", "FirePoint", "BulletSpawn", "Barrel", "Handle" }) do
				local object = tool:FindFirstChild(name, true);
				local position = positionOf(object);
				if position then return position end;
			end;
		end;
		local camera = workspace.CurrentCamera;
		local character = LocalPlayer.Character;
		local head = character and character:FindFirstChild("Head");
		return head and head.Position or (camera and camera.CFrame.Position) or Vector3.zero;
	end;
	local function aimFor()
		local okHit, hit = pcall(function() return mouse.Hit end);
		local okTarget, target = pcall(function() return mouse.Target end);
		local to = okHit and hit and hit.Position or nil;
		local human = okTarget and humanoidOf(target) or nil;
		if not to then
			local camera = workspace.CurrentCamera;
			if camera then to = camera.CFrame.Position + camera.CFrame.LookVector * 1000 end;
		end;
		return to, human;
	end;
	local function trim(now)
		while recent[1] and now - recent[1].at > 5 do table.remove(recent, 1) end;
		while #recent > 24 do table.remove(recent, 1) end;
	end;
	local function recordAttack(kind, tool, from, to, target, source)
		local now = os.clock();
		trim(now);
		local info = recent[#recent];
		if not info or now - info.at > 0.12 or (info.tool and tool and info.tool ~= tool) then
			info = { at = now, kind = kind, tool = tool, source = source };
			recent[#recent + 1] = info;
		else
			info.at, info.kind, info.tool, info.source = now, kind ~= "attack" and kind or info.kind, tool or info.tool, source or info.source;
		end;
		info.from, info.to, info.target = from or info.from, to or info.to, target or info.target;
		Combat.Attack:Fire(info);
		return info;
	end;
	Combat.RecordAttack = recordAttack;

	local function distanceToSegment(point, a, b)
		local delta = b - a;
		local length = delta:Dot(delta);
		if length <= 0.0001 then return (point - a).Magnitude end;
		local alpha = math.clamp((point - a):Dot(delta) / length, 0, 1);
		return (point - (a + delta * alpha)).Magnitude;
	end;
	local function creatorCredit(human)
		local creator = human and (human:FindFirstChild("creator") or human:FindFirstChild("Creator"));
		return creator and creator:IsA("ObjectValue") and creator.Value == LocalPlayer;
	end;
	local function creditFor(human)
		if creatorCredit(human) then return { at = os.clock(), kind = "tag", target = human } end;
		local now, root = os.clock(), rootOf(human);
		for index = #recent, 1, -1 do
			local info = recent[index];
			local age = now - info.at;
			if age > 4 then break end;
			if info.target == human then return info end;
			if root and info.from and info.to and age <= 1.75 and distanceToSegment(root.Position, info.from, info.to) <= 8 then return info end;
			if root and info.kind ~= "shot" and age <= 0.8 then
				local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
				if localRoot and (root.Position - localRoot.Position).Magnitude <= 14 then return info end;
			end;
		end;
	end;
	local function watchHumanoid(human)
		if humanoids[human] then return end;
		local character = LocalPlayer.Character;
		if character and human:IsDescendantOf(character) then return end;
		local record = { health = human.Health, killed = false, lastHit = -math.huge, conns = {} };
		humanoids[human] = record;
		local function killed()
			if record.killed then return end;
			local credit = record.credit or creditFor(human);
			if not credit then return end;
			record.killed = true;
			Combat.Kill:Fire({ humanoid = human, attack = credit, at = os.clock() });
		end;
		record.conns[#record.conns + 1] = human.HealthChanged:Connect(function(value)
			local before = record.health;
			record.health = value;
			if value < before then
				local credit = creditFor(human);
				if credit then
					record.credit = credit;
					local now = os.clock();
					if now - record.lastHit >= 0.055 then
						record.lastHit = now;
						Combat.Hit:Fire({ humanoid = human, damage = before - value, attack = credit, at = now });
					end;
				end;
			end;
			if value <= 0 then killed() end;
		end);
		record.conns[#record.conns + 1] = human.Died:Connect(killed);
		record.conns[#record.conns + 1] = human.Destroying:Connect(function()
			humanoids[human] = nil;
			for _, connection in ipairs(record.conns) do connection:Disconnect() end;
		end);
	end;
	local function hookTool(tool)
		if toolHooks[tool] or not tool:IsA("Tool") then return end;
		local record = {};
		toolHooks[tool] = record;
		record.activated = tool.Activated:Connect(function()
			if not __ALIVE() or not tool:IsDescendantOf(LocalPlayer.Character or LocalPlayer) then return end;
		local kind = kindOf(tool);
		local to, target = aimFor();
		recordAttack(kind, tool, originFor(tool), to, target, "tool");
		end);
		record.destroying = tool.Destroying:Connect(function()
			toolHooks[tool] = nil;
			for _, connection in pairs(record) do connection:Disconnect() end;
		end);
	end;
	local function discover(object)
		if object:IsA("Humanoid") then watchHumanoid(object)
		elseif object:IsA("Tool") and (object:IsDescendantOf(LocalPlayer) or (LocalPlayer.Character and object:IsDescendantOf(LocalPlayer.Character))) then hookTool(object) end;
	end;
	NeverLose:AddSignal(workspace.DescendantAdded:Connect(discover));
	NeverLose:AddSignal(LocalPlayer.DescendantAdded:Connect(discover));
	NeverLose:AddSignal(UserInputService.InputBegan:Connect(function(input, processed)
		if processed or UserInputService:GetFocusedTextBox() or Window.Signal:GetValue() then return end;
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end;
		local now = os.clock();
		if now - lastInputAt < 0.035 then return end;
		lastInputAt = now;
		local tool = localTool();
		if tool then return end;
		local to, target = aimFor();
		if not target and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then return end;
		recordAttack("shot", nil, originFor(nil), to, target, "input");
	end));

	local runtime = { Active = true };
	runtime.ObserveRemote = function(remote, args)
		if not runtime.Active or typeof(remote) ~= "Instance" then return end;
		local ok, fullName = pcall(remote.GetFullName, remote);
		local hint = string.lower((ok and fullName or remote.Name) .. " " .. remote.Name);
		if not containsAny(hint, ATTACK) then return end;
		local positions, target, visited = {}, nil, 0;
		local function inspect(value, depth)
			if visited >= 48 or depth > 3 then return end;
			visited += 1;
			local human = humanoidOf(value);
			if human and human.Parent ~= LocalPlayer.Character then target = target or human end;
			local position = positionOf(value);
			if position then positions[#positions + 1] = position end;
			if type(value) == "table" then
				local count = 0;
				for _, nested in pairs(value) do count += 1; if count > 16 then break end; inspect(nested, depth + 1) end;
			end;
		end;
		for index = 1, math.min(args.n or #args, 12) do inspect(args[index], 1) end;
		local tool = localTool();
		local kind = kindOf(tool, hint);
		local from = #positions >= 2 and positions[1] or originFor(tool);
		local to = positions[#positions];
		if not to then to = select(1, aimFor()) end;
		recordAttack(kind, tool, from, to, target, "remote");
	end;
	local hookState = GLOBAL.__VisualsCombatHook;
	if type(hookState) ~= "table" and type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" and type(newcclosure) == "function" then
		hookState = {};
		local old;
		old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
			local method = getnamecallmethod();
			if method == "FireServer" or method == "InvokeServer" then
				local active = GLOBAL.__VisualsCombatRuntime;
				if type(active) == "table" and active.Active and type(active.ObserveRemote) == "function" then
					local args = table.pack(...);
					task.defer(function() pcall(active.ObserveRemote, self, args) end);
				end;
			end;
			return old(self, ...);
		end));
		hookState.Old = old;
		GLOBAL.__VisualsCombatHook = hookState;
	end;
	GLOBAL.__VisualsCombatRuntime = runtime;

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character;
		local human = character and character:FindFirstChildOfClass("Humanoid");
		if human then watchHumanoid(human) end;
	end;
	for _, root in ipairs({ LocalPlayer.Character, LocalPlayer:FindFirstChildOfClass("Backpack") }) do
		if root then
			for _, object in ipairs(root:GetChildren()) do discover(object) end;
		end;
	end;
	runtime.ScanTask = scanDescendantsAsync("combat scan", workspace, discover, function()
		return runtime.Active;
	end, 512);
	ESP.Combat = Combat;
	ESP.ClearCombat = onUnload("combat", function()
		runtime.Active = false;
		if GLOBAL.__VisualsCombatRuntime == runtime then GLOBAL.__VisualsCombatRuntime = nil end;
		for _, record in pairs(humanoids) do for _, connection in ipairs(record.conns) do connection:Disconnect() end end;
		for _, record in pairs(toolHooks) do for _, connection in pairs(record) do connection:Disconnect() end end;
		table.clear(humanoids); table.clear(toolHooks); table.clear(recent);
		for _, event in pairs(Combat) do if typeof(event) == "Instance" then event:Destroy() end end;
	end);
end;
