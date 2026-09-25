--!nonstrict
--[[
	backtrack_chams.lua — extracted feature module (require id "modules.backtrack_chams").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("backtrack_chams") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("backtrack_chams", function()
			return require("modules.backtrack_chams")({ ESP = ESP, INIT_GENERATION = INIT_GENERATION, LocalPlayer = LocalPlayer, NeverLose = NeverLose, Players = Players, RunService = RunService, TAG = TAG, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local INIT_GENERATION = ctx.INIT_GENERATION;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local Players = ctx.Players;
	local RunService = ctx.RunService;
	local TAG = ctx.TAG;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("backtrack_chams") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local BT = ESP.Backtrack;
	local states, timer = {}, 0;
	local SAMPLE_STEP = 1 / 30;

	local present = {};

	local function clear(player)
		local state = states[player];
		if not state then return end;
		if state.model then state.model:Destroy() end;
		states[player] = nil;
	end;

	local function clearAll()
		while next(states) do clear(next(states)) end;
	end;

	local function selected(player)
		return BT.On and (BT.Target == "All" or (BT.Target == "Self" and player == LocalPlayer) or (BT.Target == "Other" and player ~= LocalPlayer));
	end;

	local function groupParts(model)
		local groups = {};
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				groups[descendant.Name] = groups[descendant.Name] or {};
				table.insert(groups[descendant.Name], descendant);
			end;
		end;
		return groups;
	end;

	local function buildModel(state)
		if state.model and state.model.Parent then return true end;
		local character = state.character;
		local archivable = character.Archivable;
		pcall(function() character.Archivable = true end);
		local ok, model = pcall(character.Clone, character);
		pcall(function() character.Archivable = archivable end);
		if not ok or not model then return false end;

		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true;
				descendant.CanCollide = false;
				descendant.CanTouch = false;
				descendant.CanQuery = false;
				descendant.CastShadow = false;
				descendant.Transparency = 1;
			elseif descendant:IsA("Humanoid") or descendant:IsA("BaseScript") or descendant:IsA("Sound")
				or descendant:IsA("Decal") or descendant:IsA("Texture") or descendant:IsA("ParticleEmitter")
				or descendant:IsA("Trail") or descendant:IsA("Beam") or descendant:IsA("Light")
				or descendant:IsA("Highlight") or descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
				descendant:Destroy();
			end;
		end;

		local sourceGroups = groupParts(character);
		local cloneGroups = groupParts(model);
		local links = {};
		for name, sources in pairs(sourceGroups) do
			local clones = cloneGroups[name] or {};
			for index, source in ipairs(sources) do
				local clone = clones[index];
				if clone and source.Name ~= "HumanoidRootPart" and source.Transparency < 1 then
					links[#links + 1] = { source = source, clone = clone, baseTransparency = source.Transparency };
				end;
			end;
		end;

		local highlight = Instance.new("Highlight");
		highlight.Name = "BacktrackPlayerChams";
		highlight.Adornee = model;
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop;
		highlight.Parent = model;

		model.Name = NeverLose.RandomString();
		model:SetAttribute(TAG, INIT_GENERATION);
		model.Parent = workspace;
		state.model, state.links, state.highlight = model, links, highlight;
		return true;
	end;

	local function ensure(player, character)
		local state = states[player];
		if state and state.character == character then return state end;
		clear(player);
		state = { character = character, history = {} };
		states[player] = state;
		return state;
	end;

	local function snapshot(state, root, now)
		local pose = {};
		for index, link in ipairs(state.links or {}) do
			if link.source.Parent then pose[index] = link.source.CFrame end;
		end;
		state.history[#state.history + 1] = { t = now, root = root.CFrame, pose = pose };
		local keep = math.max(1.05, BT.Delay / 1000 + 0.2);
		while #state.history > 2 and state.history[2].t < now - keep do table.remove(state.history, 1) end;
	end;

	local function delayedPose(history, target)
		if #history == 0 then return nil end;
		local before, after = history[1], history[1];
		for index = 2, #history do
			local sample = history[index];
			if sample.t >= target then
				before, after = history[index - 1], sample;
				break;
			end;
			before, after = sample, sample;
		end;
		local alpha = before == after and 0 or math.clamp((target - before.t) / math.max(after.t - before.t, 0.00001), 0, 1);
		return before, after, alpha;
	end;

	local function renderChams(state, before, after, alpha)
		if not buildModel(state) then return end;
		local style = ESP.MaterialStyles[BT.ChamsMaterial] or ESP.MaterialStyles.ForceField;
		local userFade = math.clamp(BT.Transparency / 100, 0, 1);
		local styleFade = math.clamp(style.transparency or 0, 0, 1);
		for index, link in ipairs(state.links) do
			local first = before.pose[index];
			local second = after.pose[index] or first;
			if first and link.clone.Parent then
				link.clone.CFrame = first:Lerp(second, alpha);
				link.clone.Material = style.material or Enum.Material.ForceField;
				link.clone.Reflectance = style.reflectance or 0;
				link.clone.Color = BT.Color;
				link.clone.Transparency = 1 - (1 - link.baseTransparency) * (1 - userFade) * (1 - styleFade);
			end;
		end;
		local highlight = state.highlight;
		if highlight then
			highlight.Enabled = true;
			highlight.FillColor = BT.Color;
			highlight.FillTransparency = userFade;
			highlight.OutlineColor = BT.ChamsOutline;
			highlight.OutlineTransparency = BT.OutlineOn and math.clamp(BT.ChamsOutlineTransparency / 100, 0, 1) or 1;
		end;
	end;

	local function hideChams(state)
		if state.highlight then state.highlight.Enabled = false end;
		for _, link in ipairs(state.links or {}) do link.clone.Transparency = 1 end;
	end;

	NeverLose:AddSignal(Players.PlayerRemoving:Connect(clear));
	NeverLose:AddSignal(RunService.RenderStepped:Connect(function(dt)
		if not __ALIVE() then return end;
		if not BT.On then
			timer = 0;
			if next(states) then clearAll() end;
			return;
		end;
		timer = timer + dt;
		local sampleNow = timer >= SAMPLE_STEP;
		if sampleNow then timer = timer % SAMPLE_STEP end;
		local now = os.clock();

		table.clear(present);

		for _, player in ipairs(Players:GetPlayers()) do
			present[player] = true;
			local character = player.Character;
			local root = character and character:FindFirstChild("HumanoidRootPart");
			if selected(player) and character and root then
				local state = ensure(player, character);
				if not state.model or not state.model.Parent then buildModel(state) end;
				if sampleNow or #state.history == 0 then snapshot(state, root, now) end;
				local before, after, alpha = delayedPose(state.history, now - BT.Delay / 1000);
				if before then renderChams(state, before, after, alpha) end;
			elseif states[player] then
				clear(player);
			end;
		end;
		for player in pairs(states) do if not present[player] then clear(player) end end;
	end));
	ESP.ClearBacktrackChams = clearAll;
end;
