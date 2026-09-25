--!nonstrict
--[[
	models.lua — extracted feature module (require id "modules.models").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("models") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("models", function()
			return require("modules.models")({ ESP = ESP, INIT_GENERATION = INIT_GENERATION, LocalPlayer = LocalPlayer, NeverLose = NeverLose, Notification = Notification, Remote = Remote, Render = Render, RunService = RunService, Sections = Sections, TAG = TAG, Visuals = Visuals, onUnload = onUnload, recordError = recordError, userFile = userFile, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local INIT_GENERATION = ctx.INIT_GENERATION;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local Notification = ctx.Notification;
	local Remote = ctx.Remote;
	local Render = ctx.Render;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local TAG = ctx.TAG;
	local Visuals = ctx.Visuals;
	local onUnload = ctx.onUnload;
	local recordError = ctx.recordError;
	local userFile = ctx.userFile;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("models") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]

	local STORE = userFile("models.txt");
	local SIZES_FILE = userFile("model_sizes.txt");

	local BUILTIN = {
		{ Name = "Tung Tung Sahur", Id = "138151705692565" },
	};

	local M = { On = false, Pick = nil, Sizes = {}, Rotations = {} };

	ESP.Models = M;

	local defs, order = {}, {};
	local cache = {};
	local generation = 0;
	local sizeApplyToken = 0;
	local sizeSaveToken, sizesDirty = 0, false;
	local shell, follow, charConn = nil, nil, nil;
	local hiddenParts, hiddenDecals = {}, {};
	local grid;
	local applyAccessoryVisibility;
	local accessoryHidden, accessoryConn, appearanceConn = {}, nil, nil;
	local accessoryTransparencies = {};
	local hairless, noAccessories, accessoryRefreshQueued = false, false, false;
	local hairAssetIds, hairKind, hairKindLoading = {}, {}, {};
	local MarketplaceService = game:GetService("MarketplaceService");

	local korblox, headless = false, false;
	local legBackup, headBackup = {}, {};
	local r6KorbloxShell = nil;

	local function register(def)
		if defs[def.Name] then return end;

		defs[def.Name] = def;
		order[#order + 1] = def.Name;
	end;

	local function rebuildList()
		table.clear(defs);
		table.clear(order);

		for _, def in ipairs(BUILTIN) do
			register({ Name = def.Name, Id = def.Id, Kind = "asset" });
		end;

		table.sort(order, function(a, b) return string.lower(a) < string.lower(b) end);

		if isfile and readfile and isfile(STORE) then
			local ok, body = pcall(readfile, STORE);

			if ok and type(body) == "string" then
				for line in string.gmatch(body, "[^\r\n]+") do
					local id, name = string.match(line, "^(%d+)|(.*)$");

					if id then
						register({ Name = (name ~= "" and name) or ("Model " .. id), Id = id, Kind = "asset", User = true });
					end;
				end;
			end;
		end;
	end;

	local function saveUsers()
		if not writefile then return end;

		local lines = {};

		for _, name in ipairs(order) do
			local def = defs[name];

			if def and def.User and def.Id then
				lines[#lines + 1] = def.Id .. "|" .. def.Name;
			end;
		end;

		pcall(writefile, STORE, table.concat(lines, "\n"));
	end;

	local function rows()
		local out = {};

		for _, name in ipairs(order) do
			local def = defs[name];

			out[#out + 1] = { name = name, label = name, id = def and def.Id and tonumber(def.Id) or nil };
		end;

		return out;
	end;

	local function refreshGrid()
		if not grid then return end;

		local values = rows();

		if grid.setdata then
			pcall(function() grid:setdata(values) end);
		elseif grid.setlist then
			pcall(function() grid:setlist(values) end);
		end;
	end;

	local function restoreReal()
		for item, value in pairs(hiddenParts) do
			if item.Parent then pcall(function() item.LocalTransparencyModifier = value end) end;
		end;

		for item, value in pairs(hiddenDecals) do
			if item.Parent then pcall(function() item.Transparency = value end) end;
		end;

		table.clear(hiddenParts);
		table.clear(hiddenDecals);
		if applyAccessoryVisibility then applyAccessoryVisibility() end;
	end;

	local function hideReal(character)
		for _, d in ipairs(character:GetDescendants()) do
			local accessory = d:FindFirstAncestorWhichIsA("Accessory");
			local ownedAccessory = accessory and accessory:GetAttribute("VisualsCharacterAccessory");
			if d:IsA("BasePart") and not ownedAccessory then
				if hiddenParts[d] == nil then hiddenParts[d] = accessoryHidden[d] or d.LocalTransparencyModifier end;

				if d.LocalTransparencyModifier < 1 then d.LocalTransparencyModifier = 1 end;
			elseif not ownedAccessory and (d:IsA("Decal") or d:IsA("Texture")) then
				if hiddenDecals[d] == nil then hiddenDecals[d] = d.Transparency end;

				if d.Transparency < 1 then d.Transparency = 1 end;
			end;
		end;
	end;

	local HAIR_WORDS = { "hair", "bang", "ponytail", "pigtail", "braid", "dread", "locks",
		"wig", "afro", "mohawk", "fringe", "twintail", "hairstyle", "bobcut", "hairdo" };
	local function refreshHairIds(character)
		table.clear(hairAssetIds);
		local human = character and character:FindFirstChildOfClass("Humanoid");
		if not human then return end;
		local ok, description = pcall(human.GetAppliedDescription, human);
		if ok and description then
			for id in string.gmatch(description.HairAccessory or "", "%d+") do hairAssetIds[id] = true end;
		end;
	end;
	local function sourceAssetId(object)
		local ok, id = pcall(function() return object.SourceAssetId end);
		return ok and tonumber(id) or nil;
	end;
	local function queueHairKind(object, id)
		local key = id and string.format("%.0f", id) or nil;
		if not key or id <= 0 or hairKind[key] ~= nil or hairKindLoading[key] then return end;
		hairKindLoading[key] = true;
		task.spawn(function()
			local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, Enum.InfoType.Asset);
			hairKindLoading[key] = nil;
			hairKind[key] = ok and type(info) == "table" and tonumber(info.AssetTypeId) == Enum.AssetType.HairAccessory.Value or false;
			if hairKind[key] and __ALIVE() and hairless and object.Parent then applyAccessoryVisibility() end;
		end);
	end;
	local function isHairObject(object)
		if object:IsA("Accessory") and object.AccessoryType == Enum.AccessoryType.Hair then return true end;
		for _, descendant in ipairs(object:GetDescendants()) do
			if descendant:IsA("Attachment") and descendant.Name == "HairAttachment" then return true end;
		end;
		local id = sourceAssetId(object);
		local key = id and string.format("%.0f", id) or nil;
		if key and (hairAssetIds[key] or hairKind[key] == true) then return true end;
		if key and hairKind[key] == nil then queueHairKind(object, id) end;
		local text = string.lower(object.Name);
		local ok, tags = pcall(object.GetTags, object);
		if ok then for _, tag in ipairs(tags) do text ..= " " .. string.lower(tag) end end;
		for _, word in ipairs(HAIR_WORDS) do if string.find(text, word, 1, true) then return true end end;
		return false;
	end;
	applyAccessoryVisibility = function()
		local character = LocalPlayer.Character;
		local wanted, opaqueHidden = {}, {};
		if character and (hairless or noAccessories) then
			for _, object in ipairs(character:GetChildren()) do
				local accessory = object:IsA("Accessory") or object:IsA("Hat");
				local scriptAccessory = object:GetAttribute("VisualsCharacterAccessory") == true;
				local hideAccessory = noAccessories and accessory and not scriptAccessory;
				local hideHair = hairless and isHairObject(object);
				if hideAccessory or hideHair then
					if object:IsA("BasePart") then wanted[object] = true end;
					for _, part in ipairs(object:GetDescendants()) do if part:IsA("BasePart") then wanted[part] = true end end;
					if hideAccessory then for part in pairs(wanted) do if part == object or part:IsDescendantOf(object) then opaqueHidden[part] = true end end end;
				end;
			end;
		end;

		for part, value in pairs(accessoryTransparencies) do
			if not opaqueHidden[part] then
				if part.Parent then part.Transparency = (headless and headBackup[part]) and 1 or value end;
				accessoryTransparencies[part] = nil;
			end;
		end;
		for part in pairs(opaqueHidden) do
			if accessoryTransparencies[part] == nil then
				accessoryTransparencies[part] = headBackup[part] and headBackup[part].Transparency or part.Transparency;
			end;
			part.Transparency = 1;
		end;
		for part, value in pairs(accessoryHidden) do
			if not wanted[part] then
				if part.Parent then part.LocalTransparencyModifier = hiddenParts[part] ~= nil and 1 or value end;
				accessoryHidden[part] = nil;
			end;
		end;
		for part in pairs(wanted) do
			if accessoryHidden[part] == nil then accessoryHidden[part] = hiddenParts[part] or part.LocalTransparencyModifier end;
			part.LocalTransparencyModifier = 1;
		end;
	end;
	local function watchAccessories(character)
		if accessoryConn then accessoryConn:Disconnect(); accessoryConn = nil end;
		if not character then return end;
		refreshHairIds(character);
		accessoryConn = character.DescendantAdded:Connect(function()
			if not (__ALIVE() and (hairless or noAccessories)) or accessoryRefreshQueued then return end;
			accessoryRefreshQueued = true;
			task.defer(function()
				accessoryRefreshQueued = false;
				if __ALIVE() and LocalPlayer.Character == character then applyAccessoryVisibility() end;
			end);
		end);
	end;
	local accessoryVisibilityClock = 0;
	NeverLose:AddSignal(RunService.RenderStepped:Connect(function(dt)
		if not (hairless or noAccessories) then accessoryVisibilityClock = 0; return end;
		accessoryVisibilityClock += dt;
		if accessoryVisibilityClock >= 0.08 then accessoryVisibilityClock = 0; applyAccessoryVisibility() end;
	end));

	local function template(def)
		if cache[def.Name] then return cache[def.Name] end;

		local ok, objects = Remote.objects(function() return game:GetObjects("rbxassetid://" .. tostring(def.Id)) end);

		if not ok or type(objects) ~= "table" or not objects[1] then return nil end;

		local root = objects[1];
		for index = 2, #objects do pcall(function() objects[index]:Destroy() end) end;
		if not __ALIVE() then root:Destroy(); return nil end;

		if not root:IsA("Model") then
			local holder = Instance.new("Model");

			root.Parent = holder;
			root = holder;
		end;

		local descendants = root:GetDescendants();
		if #descendants > 4096 then root:Destroy(); return nil end;
		root.Archivable = true;
		for _, d in ipairs(descendants) do
			d.Archivable = true;
			if d:IsA("LuaSourceContainer") or d:IsA("Humanoid") or d:IsA("JointInstance")
				or d:IsA("Constraint") or d:IsA("BodyMover") or d:IsA("Sound") or d:IsA("ParticleEmitter")
				or d:IsA("Beam") or d:IsA("Trail") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
				pcall(function() d:Destroy() end);
			end;
		end;

		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false;
				d.Massless, d.CastShadow, d.Locked = true, false, true;
			end;
		end;

		cache[def.Name] = root;

		return root;
	end;

	local function clear()
		if follow then
			pcall(function() follow:Disconnect() end);

			follow = nil;
		end;

		if shell then
			pcall(function() shell:Destroy() end);

			shell = nil;
		end;

		restoreReal();
	end;

	local KORBLOX = {
		RightUpperLeg = { MeshId = "rbxassetid://902942096", TextureID = "rbxassetid://902843398" },
		RightLowerLeg = { MeshId = "rbxassetid://902942093", Transparency = 1 },
		RightFoot = { MeshId = "rbxassetid://902942089", Transparency = 1 },
	};

	local HEADLESS_MESH = "rbxassetid://6686307858";

	local function restoreKorblox()
		if r6KorbloxShell then r6KorbloxShell:Destroy(); r6KorbloxShell = nil end;
		for part, saved in pairs(legBackup) do
			if part.Parent then
				for property, value in pairs(saved) do
					pcall(function() part[property] = value end);
				end;
			end;
		end;

		table.clear(legBackup);
	end;

	local function applyKorblox()
		if not korblox then return end;

		local character = LocalPlayer.Character;

		if not character then return end;

		restoreKorblox();
		local r6Leg = character:FindFirstChild("Right Leg");
		if r6Leg and r6Leg:IsA("BasePart") and not character:FindFirstChild("RightUpperLeg") then
			legBackup[r6Leg] = { Transparency = r6Leg.Transparency };
			local shellPart = Instance.new("Part");
			shellPart.Name = "VisualsR6Korblox";
			shellPart:SetAttribute(TAG, INIT_GENERATION);
			shellPart.Size, shellPart.CFrame = r6Leg.Size, r6Leg.CFrame;
			shellPart.Color, shellPart.Material = r6Leg.Color, Enum.Material.SmoothPlastic;
			shellPart.Transparency, shellPart.Reflectance = 0, r6Leg.Reflectance;
			shellPart.CanCollide, shellPart.CanQuery, shellPart.CanTouch = false, false, false;
			shellPart.Massless, shellPart.CastShadow = true, false;
			local mesh = Instance.new("SpecialMesh");
			mesh.MeshType = Enum.MeshType.FileMesh;
			mesh.MeshId, mesh.TextureId = "rbxassetid://902942096", "rbxassetid://902843398";
			mesh.Scale = Vector3.new(1.05, 1, 1.05);
			mesh.Parent = shellPart;
			local weld = Instance.new("WeldConstraint");
			weld.Part0, weld.Part1, weld.Parent = shellPart, r6Leg, shellPart;
			shellPart.Parent = character;
			r6Leg.Transparency = 1;
			r6KorbloxShell = shellPart;
			return;
		end;

		for name, swapTo in pairs(KORBLOX) do
			local part = character:FindFirstChild(name);

			if part then
				local saved = {};

				for property in pairs(swapTo) do
					local ok, value = pcall(function() return part[property] end);

					if ok then saved[property] = value end;
				end;

				legBackup[part] = saved;

				for property, value in pairs(swapTo) do
					pcall(function() part[property] = value end);
				end;
			end;
		end;
	end;

	local function restoreHeadless()
		for object, saved in pairs(headBackup) do
			if object.Parent then
				for property, value in pairs(saved) do
					if property == "Transparency" and accessoryTransparencies[object] ~= nil then value = 1 end;
					pcall(function() object[property] = value end);
				end;
			end;
		end;

		table.clear(headBackup);
	end;

	local function applyHeadless()
		if not headless then return end;

		local character = LocalPlayer.Character;
		local head = character and character:FindFirstChild("Head");

		if not head then return end;

		restoreHeadless();

		headBackup[head] = {
			MeshId = (pcall(function() return head.MeshId end)) and head.MeshId or nil,
			TextureID = (pcall(function() return head.TextureID end)) and head.TextureID or nil,
			Transparency = head.Transparency,
		};

		pcall(function() head.MeshId = HEADLESS_MESH end);
		pcall(function() head.TextureID = HEADLESS_MESH end);
		pcall(function() head.Transparency = 1 end);

		for _, child in ipairs(head:GetDescendants()) do
			local ok, value = pcall(function() return child.Transparency end);

			if ok and type(value) == "number" then
				headBackup[child] = { Transparency = value };

				pcall(function() child.Transparency = 1 end);
			end;
		end;
		for _, accessory in ipairs(character:GetChildren()) do
			if accessory:IsA("Accessory") then
				local handle = accessory:FindFirstChild("Handle");
				local weld = handle and handle:FindFirstChild("AccessoryWeld");
				if handle and weld and weld:IsA("JointInstance") and (weld.Part0 == head or weld.Part1 == head) then
					for _, item in ipairs(accessory:GetDescendants()) do
						if item:IsA("BasePart") or item:IsA("Decal") then
							headBackup[item] = {Transparency=accessoryTransparencies[item] or item.Transparency};
							item.Transparency=1;
						end;
					end;
				end;
			end;
		end;
	end;

	local function build(mine)
		local def = M.Pick and defs[M.Pick];

		if not def then return end;

		local character, root;

		for _ = 1, 40 do
			if mine ~= generation or not (M.On and M.Pick) then return end;

			character = LocalPlayer.Character;
			root = character and character:FindFirstChild("HumanoidRootPart");

			if root then break end;

			task.wait(0.25);
		end;

		if not character or not root then return end;

		local human = character:FindFirstChildOfClass("Humanoid");

		local source = template(def);

		if not __ALIVE() or not M.On or mine ~= generation or LocalPlayer.Character ~= character or not character.Parent or not root.Parent then return end;

		if not source then
			Notification.new({ Title = "Models", Content = "Could not load " .. def.Name, Duration = 4 });

			return;
		end;

		local clone = source:Clone();
		if not clone then return end;

		local body = ESP.BodyExtents(character, root);
		local charSize = body and body.half * 2 or Vector3.new(3, 5, 2);
		local _, rawSize = clone:GetBoundingBox();

		if rawSize.Y > 0.01 then
			local custom = math.clamp(tonumber(M.Sizes[def.Name]) or 1, 0.35, 1.25);
			local scale = (charSize.Y / rawSize.Y) * custom;

			if math.abs(scale - 1) > 0.02 then pcall(function() clone:ScaleTo(clone:GetScale() * scale) end) end;
		end;

		local box, size = clone:GetBoundingBox();
		local pivotFix = (clone:GetPivot():Inverse() * box):Inverse();
		local lift = size.Y * 0.5 - root.Size.Y * 0.5 - (human and human.HipHeight or 0);

		clone.Name = "VisualsModelShell";
		Render.DepthTree(clone, false);
		local shellParts = {};
		for _, part in ipairs(clone:GetDescendants()) do
			if part:IsA("BasePart") then shellParts[#shellParts + 1] = { part, part.LocalTransparencyModifier } end;
		end;
		clone.Parent = workspace;

		shell = clone;

		hideReal(character);

		local last, lastRotation, hideAt, lastVisible = nil, nil, 0, nil;
		local bodyWatch = character.DescendantAdded:Connect(function() if __ALIVE() and M.On and shell then hideAt = 0 end end);
		NeverLose:AddSignal(bodyWatch);
		clone.Destroying:Once(function() bodyWatch:Disconnect() end);

		follow = RunService.RenderStepped:Connect(function()
			if not (__ALIVE() and M.On and shell and shell.Parent) then return end;

			if not root.Parent then return end;
			local visible = ESP.Visibility.Character(Render.camera(), character, root);
			if lastVisible ~= visible then
				lastVisible = visible;
				for _, saved in ipairs(shellParts) do
					if saved[1].Parent then saved[1].LocalTransparencyModifier = visible and saved[2] or 1 end;
				end;
			end;

			local cf = root.CFrame;
			local rotation = M.Rotations[def.Name] or 0;
			if os.clock() >= hideAt then hideAt = os.clock() + 0.2; hideReal(character) end;

			if last == cf and lastRotation == rotation then return end;

			last, lastRotation = cf, rotation;

			local look, pos = cf.LookVector, cf.Position;

			shell:PivotTo(CFrame.new(pos.X, pos.Y + lift, pos.Z)
				* CFrame.fromEulerAnglesYXZ(0, math.atan2(-look.X, -look.Z) + math.rad(rotation), 0)
				* pivotFix);

		end);

	end;

	local function apply()
		generation = generation + 1;

		clear();

		if not (M.On and M.Pick) then
			return;
		end;

		local mine = generation;

		task.spawn(function()
			local ok, err = pcall(build, mine);

			if not ok then warn("[visuals] model: " .. tostring(err)) end;

			if mine == generation and not M.On then clear() end;
		end);
	end;

	local function flushSizes()
		if not sizesDirty or not writefile then return end;
		local lines = {};
		for name in pairs(defs) do
			if M.Sizes[name] or M.Rotations[name] then
				lines[#lines + 1] = name .. "|" .. tostring(M.Sizes[name] or 1) .. "|" .. tostring(M.Rotations[name] or 0);
			end;
		end;
		table.sort(lines);
		if pcall(writefile, SIZES_FILE, table.concat(lines, "\n")) then sizesDirty = false end;
	end;
	local function queueModelSettingsSave()
		sizesDirty = true;

		if writefile then
			sizeSaveToken += 1;
			local saveToken = sizeSaveToken;
			task.delay(0.35, function()
				if saveToken == sizeSaveToken and __ALIVE() then flushSizes() end;
			end);
		end;
	end;
	local function setRotation(name, value)
		if not __ALIVE() or not defs[name] then return end;
		value = tonumber(value);
		if not value or value ~= value or math.abs(value) == math.huge then return end;
		M.Rotations[name] = math.clamp(value, 0, 360);
		queueModelSettingsSave();
	end;
	M.SetRotation = setRotation;
	local function setSize(name, value)
		if not __ALIVE() or not defs[name] then return end;
		value = tonumber(value);
		if not value or value ~= value or math.abs(value) == math.huge then return end;
		M.Sizes[name] = math.clamp(value, 0.35, 1.25);
		queueModelSettingsSave();

		if M.Pick == name and M.On then
			sizeApplyToken += 1;
			local token = sizeApplyToken;

			task.delay(0.12, function()
				if token == sizeApplyToken and __ALIVE() and M.On and M.Pick == name then
					apply();
				end;
			end);
		end;
	end;

	local function loadSizes()
		if not (isfile and readfile and isfile(SIZES_FILE)) then return end;

		local ok, body = pcall(readfile, SIZES_FILE);

		if not ok or type(body) ~= "string" then return end;

		for line in string.gmatch(body, "[^\r\n]+") do
			local name, value, rotation = string.match(line, "^(.-)|([^|]+)|?(.*)$");
			value, rotation = tonumber(value), tonumber(rotation);

			if name and defs[name] then
				if value and value == value and math.abs(value) < math.huge then M.Sizes[name] = math.clamp(value, 0.35, 1.25) end;
				if rotation and rotation == rotation and math.abs(rotation) < math.huge then M.Rotations[name] = math.clamp(rotation, 0, 360) end;
			end;
		end;
	end;

	local function choose(value)
		local name = (type(value) == "table") and value[1] or value;
		name = type(name) == "string" and defs[name] and name or nil;
		local enabled = name ~= nil;
		if M.Pick == name and M.On == enabled then return end;
		M.Pick, M.On = name, enabled;
		apply();
	end;

	local function addById(text)
		local id = string.match(tostring(text or ""), "(%d+)");

		if not id then
			Notification.new({ Title = "Models", Content = "Invalid ID", Duration = 4 });

			return;
		end;

		register({ Name = "Model " .. id, Id = id, Kind = "asset", User = true });
		saveUsers();
		refreshGrid();
	end;

	local function forget(name)
		local def = defs[name];

		if not (def and def.User) then return end;

		defs[name] = nil;

		for index, other in ipairs(order) do
			if other == name then table.remove(order, index); break end;
		end;

		if M.Pick == name then M.Pick, M.On = nil, false; apply(); if grid then grid:set("") end end;

		saveUsers();
		refreshGrid();
	end;

	rebuildList();
	loadSizes();

	local function reapply()
		if not __ALIVE() then return end;

		task.wait(1);

		if not __ALIVE() then return end;

		pcall(applyKorblox);
		pcall(applyHeadless);
		pcall(applyAccessoryVisibility);

		if M.On then pcall(apply) end;
	end;

	local function watchCharacter()
		if charConn then return end;

		charConn = NeverLose:AddSignal(LocalPlayer.CharacterAdded:Connect(function(character)
			watchAccessories(character);
			task.spawn(reapply);
		end));
		watchAccessories(LocalPlayer.Character);
		appearanceConn = LocalPlayer.CharacterAppearanceLoaded:Connect(function(character)
			if __ALIVE() and LocalPlayer.Character == character then task.spawn(reapply) end;
		end);
	end;

	watchCharacter();

	Sections.Character:AddLabel("Korblox Leg"):AddToggle({
		Name = "Korblox Leg",
		Default = false,
		Flag = "korblox_leg",
		ToolTip = "Skeleton right leg",
		Callback = function(v)
			korblox = v;

			if v then
				watchCharacter();
				applyKorblox();
			else
				restoreKorblox();
			end;
		end,
	});

	Sections.Character:AddLabel("Headless"):AddToggle({
		Name = "Headless",
		Default = false,
		Flag = "headless",
		ToolTip = "Hides your head",
		Callback = function(v)
			headless = v;

			if v then
				watchCharacter();
				applyHeadless();
			else
				restoreHeadless();
			end;
		end,
	});

	M.SetHairless = function(value)
		hairless, M.Hairless = value == true, value == true;
		if hairless then refreshHairIds(LocalPlayer.Character) end;
		applyAccessoryVisibility();
	end;
	M.SetNoAccessories = function(value)
		noAccessories, M.NoAccessories = value == true, value == true;
		applyAccessoryVisibility();
	end;
	Sections.Character:AddLabel("Hairless"):AddToggle({ Default = false, Flag = "hairless", Callback = M.SetHairless });
	Sections.Character:AddLabel("No Accessories"):AddToggle({ Default = false, Flag = "no_accessories", Callback = M.SetNoAccessories });

	Sections.Models:AddButton({
		Icon = "plus",
		Name = "Add by ID",
		Callback = function()
			local asked = false;

			pcall(function()
				NeverLose.Lib:ask({
					title = "add model",
					icon = "plus",
					hint = "model id or link",
					accept = "add",
					deny = "cancel",
					callback = function(text) addById(text) end,
				});

				asked = true;
			end);

			if not asked then addById(getgenv and getgenv().VISUALS_MODEL_ID) end;
		end,
	});

	Sections.Models:AddButton({
		Icon = "trash-can",
		Name = "Remove Model",
		Callback = function()
			M.On = false;
			M.Pick = nil;
			local lib = NeverLose.Lib;
			local quiet, applying = lib.quiet, lib.configApplying;
			lib.quiet, lib.configApplying = true, true;
			pcall(function() if grid then grid:set("") end end);
			lib.quiet, lib.configApplying = quiet, applying;

			apply();
		end,
	});

	local function showModelMenu(name, _, x, y, cell)
		local def = defs[name];

		if not __ALIVE() or not def then return end;

		if typeof(cell) == "Instance" and cell:IsA("GuiObject") then
			local position, size = cell.AbsolutePosition, cell.AbsoluteSize;
			x = position.X + size.X - 8;
			y = position.Y + 20;
		end;

		local items = {};

		if def.Id then
			items[#items + 1] = { icon = "copy", name = "Copy ID", callback = function() pcall(setclipboard, def.Id) end };
		end;

		if def.User then
			items[#items + 1] = { icon = "trash-2", name = "Remove", callback = function() forget(name) end };
		end;

		local ok, err = pcall(function()
			NeverLose.Lib:popup({
				name = "VisualsModelOptions",
				title = name, icon = "shirt", x = x, y = y, follow = cell, width = 194,
				items = items,
				sliders = {{
					name = "Size",
					min = 35,
					max = 125,
					value = math.floor((M.Sizes[name] or 1) * 100 + 0.5),
					suffix = "%",
					callback = function(value) setSize(name, value / 100) end,
				}, {
					name = "Rotate",
					min = 0, max = 360,
					value = M.Rotations[name] or 0,
					suffix = "°",
					callback = function(value) setRotation(name, value) end,
				}},
			});
		end);
		if not ok then recordError("model options: " .. tostring(err)); warn("[visuals] model options: " .. tostring(err)) end;
	end;

	grid = Visuals.Models:AddGallery({
		Name = "Models",
		Icon = "shirt",
		Position = "left",
		Height = 320,
		Cell = 78,
		Thumb = "Asset",
		Blank = "person-standing",
		Empty = "No models yet",
		Values = rows(),
		Flag = "model_pick",
		Reset = true,
		Smooth = true,
		Callback = choose,
		Action = { Icon = "ellipsis", Callback = showModelMenu },
	});
	task.spawn(function()
		task.wait(0.2);
		for index = 1, math.min(#order, 6) do
			if not __ALIVE() then return end;
			local def = defs[order[index]];
			if def then pcall(template, def) end;
			task.wait();
		end;
	end);

	ESP.ClearModels = onUnload("models", function()
		flushSizes(); sizeSaveToken += 1;
		M.On = false;
		korblox, headless = false, false;
		hairless, noAccessories = false, false;
		generation = generation + 1;

		if charConn then pcall(function() charConn:Disconnect() end); charConn = nil end;
		if accessoryConn then accessoryConn:Disconnect(); accessoryConn = nil end;
		if appearanceConn then appearanceConn:Disconnect(); appearanceConn = nil end;

		restoreKorblox();
		restoreHeadless();
		clear();
		for _, source in pairs(cache) do pcall(function() source:Destroy() end) end;
		table.clear(cache);
	end);
end;
