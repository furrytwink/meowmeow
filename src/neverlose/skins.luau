return function(host)
	local Remote, Render, ESP = host.Remote, host.Render, host.ESP;
	local guard, onUnload, recordError = host.guard, host.onUnload, host.recordError;

	guard("skins", function()
		local REL = "data/mm2_weapons.json";

		local HttpService = game:GetService("HttpService");
		local RunService = game:GetService("RunService");
		local CollectionService = game:GetService("CollectionService");
		local ReplicatedStorage = game:GetService("ReplicatedStorage");
		local Players = game:GetService("Players");
		local LocalPlayer = Players.LocalPlayer;

		local REVIVE;

		local function tagged(t)
			local kind = t[1];

			if kind == "$v" then return Vector3.new(t[2], t[3], t[4]) end;
			if kind == "$c" then return Color3.fromRGB(t[2], t[3], t[4]) end;
			if kind == "$f" then return CFrame.new(unpack(t, 2)) end;
			if kind == "$a" then return CFrame.Angles(t[2], t[3], t[4]) end;
			if kind == "$v2" then return Vector2.new(t[2], t[3]) end;
			if kind == "$d" then return UDim.new(t[2], t[3]) end;
			if kind == "$d2" then return UDim2.new(t[2], t[3], t[4], t[5]) end;
			if kind == "$nr" then return NumberRange.new(t[2], t[3]) end;
			if kind == "$rc" then return Rect.new(t[2], t[3], t[4], t[5]) end;
			if kind == "$csk" then return ColorSequenceKeypoint.new(t[2], REVIVE(t[3])) end;
			if kind == "$nsk" then return NumberSequenceKeypoint.new(t[2], t[3], t[4]) end;

			if kind == "$cs" or kind == "$ns" then
				local source = t;
				local from = 2;

				if type(t[2]) == "table" and type(t[2][1]) ~= "string" then
					source, from = t[2], 1;
				end;

				local keys = {};

				for index = from, #source do keys[#keys + 1] = REVIVE(source[index]) end;

				local want = (kind == "$cs") and "ColorSequenceKeypoint" or "NumberSequenceKeypoint";

				if #keys == 1 and typeof(keys[1]) ~= want then
					return kind == "$cs" and ColorSequence.new(keys[1]) or NumberSequence.new(keys[1]);
				end;

				return kind == "$cs" and ColorSequence.new(keys) or NumberSequence.new(keys);
			end;
			if kind == "$e" then
				local category = Enum[t[2]];
				return category and category[t[3]] or nil;
			end;

			return nil;
		end;

		function REVIVE(value)
			if type(value) ~= "table" then return value end;

			local head = value[1];

			if type(head) == "string" and string.sub(head, 1, 1) == "$" then
				local built = tagged(value);

				if built ~= nil then return built end;
			end;

			for key, item in pairs(value) do value[key] = REVIVE(item) end;

			return value;
		end;

		if not Remote.ensure(REL) then
			warn("[visuals] weapon data missing: " .. REL);

			return;
		end;

		local decoded;

		do
			local function readTable()
				local body = Remote.body(REL);

				local ok, result = pcall(function()
					return HttpService:JSONDecode(body);
				end);

				return ok and type(result) == "table" and result or nil;
			end;

			decoded = readTable();

			if not decoded and Remote.repair(REL) then
				decoded = readTable();
			end;

			if not decoded then
				warn("[visuals] weapon data unreadable and could not be refetched");

				return;
			end;
		end;

		local MESHES = REVIVE(decoded);

		local ProfileData, EquipService;

		do
			local services = ReplicatedStorage:FindFirstChild("ClientServices");
			local modules = ReplicatedStorage:FindFirstChild("Modules");

			pcall(function()
				ProfileData = require(modules:WaitForChild("ProfileData", 5));
				EquipService = require(services:WaitForChild("EquipService", 5));
			end);
		end;

		local INGAME = ProfileData ~= nil;

		local function trimAsset(value)
			if type(value) == "string" then
				return (string.gsub(string.gsub(value, "^%s+", ""), "%s+$", ""));
			end;

			return value;
		end;

		local function applyProps(instance, props, skip)
			for key, value in pairs(props or {}) do
				if not (skip and skip[key]) then
					if key == "MeshId" or key == "TextureId" or key == "TextureID" or key == "Texture" then
						value = trimAsset(value);
					end;

					pcall(function() instance[key] = value end);
				end;
			end;
		end;

		local function createMeshPart(props)
			local meshId = trimAsset(props.MeshId or "");
			local size = props.Size or Vector3.new(1, 1, 1);
			local part;

			pcall(function()
				part = game:GetService("InsertService"):CreateMeshPartAsync(
					meshId, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Precise);
			end);

			if part then
				pcall(function() part.Size = size end);

				return part;
			end;

			local fallback = Instance.new("Part");

			fallback.Size = size;

			local mesh = Instance.new("SpecialMesh");

			mesh.MeshType = Enum.MeshType.FileMesh;

			pcall(function() mesh.MeshId = meshId end);
			pcall(function() mesh.TextureId = trimAsset(props.TextureID or props.TextureId or "") end);

			mesh.Parent = fallback;

			return fallback;
		end;

		local CHROMA = {
			Color3.fromRGB(255, 0, 0),
			Color3.fromRGB(255, 255, 0),
			Color3.fromRGB(0, 255, 0),
			Color3.fromRGB(0, 255, 255),
			Color3.fromRGB(0, 0, 255),
			Color3.fromRGB(255, 0, 255),
		};

		local CHROMA_FLASH_RATE = 1.8;
		local CHROMA_LAYER = "rbxassetid://18363392181";

		local function chromaColor(at)
			local count = #CHROMA;
			local phase = at % count;
			local index = math.floor(phase);

			return CHROMA[index + 1]:Lerp(CHROMA[((index + 1) % count) + 1], phase - index);
		end;

		local function isChroma(name, data)
			if data.Meta and data.Meta.Chroma == true then return true end;

			return string.sub(name, -6) == "Chroma";
		end;

		local function startChroma(overlay)
			local flash, decals, others = {}, {}, {};
			local tagged = false;

			for _, item in ipairs(overlay:GetDescendants()) do
				local role = item:GetAttribute("MM2Chroma");

				if role then
					tagged = true;

					if role == "part" then
						flash[#flash + 1] = item;
					elseif role == "decal" and item:IsA("Decal") then
						pcall(function() item.Texture = CHROMA_LAYER end);

						decals[#decals + 1] = item;
					elseif role == "fire" then
						others[#others + 1] = item;
					end;
				end;
			end;

			if not tagged then
				for _, item in ipairs(overlay:GetDescendants()) do
					if item:IsA("BasePart") and (item.Material == Enum.Material.Neon or string.find(string.lower(item.Name), "light")) then
						flash[#flash + 1] = item;
					elseif item:IsA("Decal") and string.find(string.lower(item.Name), "chroma") then
						decals[#decals + 1] = item;
					elseif item:IsA("Fire") then
						others[#others + 1] = item;
					end;
				end;

				if #decals == 0 then others[#others + 1] = overlay end;
			end;

			if #flash == 0 and #decals == 0 and #others == 0 then return nil end;

			return RunService.Heartbeat:Connect(function()
				local now = os.clock();
				local color = chromaColor(now);

				for _, item in ipairs(decals) do item.Color3 = color end;

				for _, item in ipairs(others) do
					if item:IsA("Fire") then
						item.Color = color;
					elseif item:IsA("BasePart") then
						item.Color = color;
					end;
				end;

				local step = math.floor(now * CHROMA_FLASH_RATE);

				for index, part in ipairs(flash) do
					part.Color = CHROMA[((step + index - 1) % #CHROMA) + 1];
				end;
			end);
		end;

		local STRUCTURAL = {
			WeldConstraint = true, Weld = true, Motor6D = true, RigidConstraint = true,
			Bone = true, Snap = true, ManualWeld = true, Rotate = true, RotateP = true, RotateV = true,
		};

		local PARTICLE_CLASSES = {
			ParticleEmitter = true, Fire = true, Smoke = true, Sparkles = true,
			PointLight = true, SpotLight = true, SurfaceLight = true,
		};

		local function chromaTag(instance, node)
			if not (instance and node.Tags) then return end;

			for _, name in ipairs(node.Tags) do
				local role = (name == "ChromaPart" and "part")
					or (name == "ChromaDecal" and "decal")
					or (name == "ChromaFire" and "fire") or nil;

				if role then
					pcall(function() instance:SetAttribute("MM2Chroma", role) end);
				end;
			end;
		end;

		local function instantiateNode(node)
			local class = node.Class;

			if STRUCTURAL[class] then return nil end;

			local instance;

			if class == "MeshPart" then
				instance = createMeshPart(node.Props);

				applyProps(instance, node.Props, { MeshId = true, Size = true, RelCF = true, CanCollide = true });
			else
				local ok, made = pcall(Instance.new, class);

				if not ok or not made then return nil end;

				instance = made;

				applyProps(instance, node.Props, { RelCF = true });
			end;

			chromaTag(instance, node);

			return instance;
		end;

		local function rebuildTree(node, parentInstance, root, idToInstance, parts, deferred)
			for _, child in ipairs(node.Children or {}) do
				local instance = instantiateNode(child);

				if not instance then

					rebuildTree(child, parentInstance, root, idToInstance, parts, deferred);
				else
					idToInstance[child.Id] = instance;

					if instance:IsA("BasePart") then
						instance.Anchored, instance.CanCollide, instance.CanQuery, instance.CanTouch, instance.Massless =
							false, false, false, false, true;

						parts[#parts + 1] = { inst = instance, relcf = child.Props and child.Props.RelCF };
						instance.Parent = root;
					elseif instance:IsA("Attachment") then
						if child.Props and child.Props.RelCF then
							pcall(function() instance.CFrame = child.Props.RelCF end);
						end;

						instance.Parent = root;
					elseif instance:IsA("Beam") or instance:IsA("Trail") then
						instance.Parent = parentInstance;

						deferred[#deferred + 1] = { inst = instance, a0 = child.Att0, a1 = child.Att1 };
					else
						instance.Parent = parentInstance;
					end;

					rebuildTree(child, instance, root, idToInstance, parts, deferred);
				end;
			end;
		end;

		local function buildFullOverlay(data)
			local node = data.Model;

			if not node then return nil end;

			local root;

			if node.Class == "MeshPart" then
				root = createMeshPart(node.Props);

				applyProps(root, node.Props, { MeshId = true, Size = true, RelCF = true, CanCollide = true });
			else
				root = Instance.new("Part");

				applyProps(root, node.Props, { RelCF = true, CanCollide = true });
			end;

			chromaTag(root, node);

			root.Anchored, root.CanCollide, root.CanQuery, root.CanTouch, root.Massless =
				false, false, false, false, true;

			local idToInstance = { [node.Id] = root };
			local parts, deferred = {}, {};

			rebuildTree(node, root, root, idToInstance, parts, deferred);

			for _, item in ipairs(deferred) do
				if item.a0 and idToInstance[item.a0] then
					pcall(function() item.inst.Attachment0 = idToInstance[item.a0] end);
				end;

				if item.a1 and idToInstance[item.a1] then
					pcall(function() item.inst.Attachment1 = idToInstance[item.a1] end);
				end;
			end;

			return { root = root, parts = parts };
		end;

		local function buildFlatOverlay(data)
			local root, meshes, decals, effects = nil, {}, {}, {};

			for _, entry in ipairs(data.Display or {}) do
				if entry.Path == "(root)" then
					root = entry;
				elseif entry.Class == "SpecialMesh" then
					meshes[#meshes + 1] = entry;
				elseif entry.Class == "Decal" or entry.Class == "Texture" then
					decals[#decals + 1] = entry;
				elseif PARTICLE_CLASSES[entry.Class] then
					effects[#effects + 1] = entry;
				end;
			end;

			if not root then return nil end;

			if root.Class ~= "MeshPart" and #meshes == 0 and #decals == 0 then return nil end;

			local part;

			if root.Class == "MeshPart" then
				part = createMeshPart(root.Props);

				applyProps(part, root.Props, { MeshId = true, Size = true, CanCollide = true });
			else
				part = Instance.new("Part");
				part.Size = root.Props.Size or Vector3.new(1, 1, 1);

				applyProps(part, root.Props, { Size = true, CanCollide = true });

				for _, entry in ipairs(meshes) do
					local mesh = Instance.new("SpecialMesh");

					mesh.MeshType = Enum.MeshType.FileMesh;

					applyProps(mesh, entry.Props);

					mesh.Parent = part;
				end;
			end;

			part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.Massless =
				false, false, false, false, true;

			for _, entry in ipairs(decals) do
				local decal = Instance.new("Decal");

				applyProps(decal, entry.Props);

				decal.Parent = part;
			end;

			for _, entry in ipairs(effects) do
				local ok, instance = pcall(Instance.new, entry.Class);

				if ok and instance then
					applyProps(instance, entry.Props);

					instance.Parent = part;
				end;
			end;

			return { root = part, parts = {} };
		end;

		local function buildAnyOverlay(data)
			if data.Model then return buildFullOverlay(data) end;
			if data.Display then return buildFlatOverlay(data) end;

			return nil;
		end;

		local function finalizeOverlay(built, targetCF)
			local root = built.root;
			Render.DepthTree(root, false);

			pcall(function() root.CFrame = targetCF end);

			for _, part in ipairs(built.parts) do
				if part.relcf then
					pcall(function() part.inst.CFrame = targetCF * part.relcf end);
				end;

				local weld = Instance.new("WeldConstraint");

				weld.Part0 = part.inst;
				weld.Part1 = root;
				weld.Parent = part.inst;
			end;

			return root;
		end;

		local function targetMeshId(data)
			if data.Model then
				local node = data.Model;

				if node.Class == "MeshPart" then return trimAsset(node.Props.MeshId or "") end;

				for _, child in ipairs(node.Children or {}) do
					if child.Class == "SpecialMesh" then return trimAsset(child.Props.MeshId or "") end;
				end;

				return "";
			end;

			for _, entry in ipairs(data.Display or {}) do
				if entry.Path == "(root)" and entry.Class == "MeshPart" then
					return trimAsset(entry.Props.MeshId or "");
				end;

				if entry.Class == "SpecialMesh" then return trimAsset(entry.Props.MeshId or "") end;
			end;

			return "";
		end;

		local function baseMeshId(base)
			if not base then return "" end;
			if base:IsA("MeshPart") then return trimAsset(base.MeshId or "") end;

			local mesh = base:FindFirstChildWhichIsA("SpecialMesh", true);

			return mesh and trimAsset(mesh.MeshId or "") or "";
		end;

		local function hideInto(list, instance)
			if instance:IsA("BasePart") or instance:IsA("Decal") then
				list[#list + 1] = { inst = instance, prop = "Transparency", val = instance.Transparency };

				pcall(function() instance.Transparency = 1 end);
			elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam")
				or instance:IsA("Fire") or instance:IsA("Smoke") or instance:IsA("Sparkles") then
				list[#list + 1] = { inst = instance, prop = "Enabled", val = instance.Enabled };

				pcall(function() instance.Enabled = false end);
			end;
		end;

		local function restore(hidden)
			for _, entry in ipairs(hidden or {}) do
				pcall(function() entry.inst[entry.prop] = entry.val end);
			end;
		end;

		local alive = true;
		local conns = {};
		local named = {};

		local function keep(connection)
			if connection then conns[#conns + 1] = connection end;

			return connection;
		end;

		local function keepNamed(name, connection)
			if named[name] then pcall(function() named[name]:Disconnect() end) end;

			named[name] = connection;

			return connection;
		end;

		local function currentChar()
			return LocalPlayer.Character;
		end;

		local function displayValue(slot)
			local character = currentChar();

			if not character then return nil end;

			local ref = character:FindFirstChild("DisplayRef" .. slot);

			return ref and ref:IsA("ObjectValue") and ref.Value or nil;
		end;

		local function waitDisplay(slot, timeout)
			local deadline = os.clock() + (timeout or 1);

			while alive and os.clock() < deadline do
				local value = displayValue(slot);

				if value then return value end;

				task.wait(0.05);
			end;

			return displayValue(slot);
		end;

		local state, lastApplied, token = {}, {}, {};

		local function cleanup(slot)
			local current = state[slot];

			if not current then return end;

			state[slot] = nil;

			if current.chroma then pcall(function() current.chroma:Disconnect() end) end;
			if current.overlay then pcall(function() current.overlay:Destroy() end) end;

			restore(current.hidden);
		end;

		local function apply(slot, name)
			if not alive or not host.Alive() then return end;
			if state[slot] and lastApplied[slot] == name and name ~= nil then return end;
			token[slot] = (token[slot] or 0) + 1;
			local mine = token[slot];
			cleanup(slot);
			local data = name and MESHES[name];
			lastApplied[slot] = name;
			if not data then return end;
			local built, record;
			local ok, err = pcall(function()
				local base = displayValue(slot) or waitDisplay(slot, 1.5);
				if not alive or not host.Alive() or token[slot] ~= mine or not base then return end;
				if baseMeshId(base) ~= "" and baseMeshId(base) == targetMeshId(data) then return end;
				built = buildAnyOverlay(data);
				if not alive or not host.Alive() or not built or not built.root or token[slot] ~= mine or not base.Parent then return end;
				finalizeOverlay(built, base.CFrame);
				local overlay = built.root;
				local weld = Instance.new("WeldConstraint");
				weld.Part0, weld.Part1, weld.Parent = overlay, base, overlay;
				record = {overlay=overlay, hidden={}, chroma=isChroma(name, data) and startChroma(overlay) or nil};
				overlay.Parent = base.Parent;
				state[slot] = record;
				hideInto(record.hidden, base);
				for _, item in ipairs(base:GetDescendants()) do
					if item ~= overlay and not item:IsDescendantOf(overlay) then hideInto(record.hidden, item) end;
				end;
				record.committed = true;
			end);
			if not record or not record.committed then
				if record and state[slot] == record then cleanup(slot) end;
				if record and record.chroma then pcall(function() record.chroma:Disconnect() end) end;
				if built and built.root then pcall(function() built.root:Destroy() end) end;
				if token[slot] == mine then lastApplied[slot] = nil end;
			end;
			if not ok then recordError("skin display: " .. tostring(err)) end;
		end;

		local toolState = {};

		local function isMine(instance)
			if instance:IsDescendantOf(LocalPlayer) then return true end;

			local character = currentChar();

			return character ~= nil and instance:IsDescendantOf(character);
		end;

		local function unoverlayTool(tool)
			local current = toolState[tool];

			if not current then return end;

			toolState[tool] = nil;

			if current.chroma then pcall(function() current.chroma:Disconnect() end) end;
			if current.overlay then pcall(function() current.overlay:Destroy() end) end;

			restore(current.hidden);
		end;

		local function overlayTool(tool, slot)
			if not alive or not host.Alive() or toolState[tool] or not isMine(tool) then return end;
			local record = { hidden = {} };
			toolState[tool] = record;
			local built;
			local skin = lastApplied[slot];
			if not skin and ProfileData then pcall(function() skin = ProfileData.Weapons.Equipped[slot] end) end;
			local ok, err = pcall(function()
				local handle = tool:FindFirstChild("Handle") or tool:WaitForChild("Handle", 5);
				if not alive or not host.Alive() or toolState[tool] ~= record or not handle or not isMine(tool) then return end;
				local data = skin and MESHES[skin];
				if not data then return end;
				built = buildAnyOverlay(data);
				if not built or not built.root then return end;
				if not alive or not host.Alive() or toolState[tool] ~= record or not handle.Parent or not isMine(tool) or (lastApplied[slot] and lastApplied[slot] ~= skin) then return end;
				local overlay = finalizeOverlay(built, handle.CFrame);
				local weld = Instance.new("WeldConstraint");
				weld.Part0, weld.Part1, weld.Parent = overlay, handle, overlay;
				record.overlay = overlay;
				record.chroma = isChroma(skin, data) and startChroma(overlay) or nil;
				hideInto(record.hidden, handle);
				for _, item in ipairs(handle:GetDescendants()) do hideInto(record.hidden, item) end;
				overlay.Parent = handle;
				record.committed = true;
			end);
			if not record.committed then
				if toolState[tool] == record then unoverlayTool(tool) end;
				restore(record.hidden);
				if record.chroma then record.chroma:Disconnect() end;
				if built and built.root then built.root:Destroy() end;
			end;
			if not ok then recordError("skin overlay: " .. tostring(err)) end;
		end;

		local function reapplyTools(slot)

			local tools = {};

			for tool in pairs(toolState) do tools[#tools + 1] = tool end;

			for _, tool in ipairs(tools) do
				local kind = CollectionService:HasTag(tool, "Weapon_Gun") and "Gun" or "Knife";

				if kind == slot then
					unoverlayTool(tool);

					task.spawn(overlayTool, tool, slot);
				end;
			end;
		end;

		local knives, guns = {}, {};

		local function renderable(data)
			if data.Model then return true end;

			for _, entry in ipairs(data.Display or {}) do
				local class = entry.Class;

				if class == "MeshPart" or class == "SpecialMesh"
					or class == "Decal" or class == "Texture" then
					return true;
				end;
			end;

			return false;
		end;
		local function weaponThumbnail(meta)
			local image = meta and meta.Image;
			if type(image) ~= "string" or image == "" then return nil end;
			if string.match(image, "^rbxassetid://%d+$") or string.match(image, "^rbxthumb://") then return image end;
			local id = string.match(image, "[?&]assetId=(%d+)") or string.match(image, "[?&]id=(%d+)");
			if not id then return nil end;
			if string.find(string.lower(image), "/asset/", 1, true) then return "rbxassetid://" .. id end;
			return "rbxthumb://type=Asset&id=" .. id .. "&w=150&h=150";
		end;

		for key, data in pairs(MESHES) do
			local meta = data.Meta;

			if renderable(data) then
				local label = (meta and meta.ItemName) or key;
				local id = meta and tonumber(meta.ItemID) or nil;

				if not id and meta and type(meta.Image) == "string" then
					id = tonumber(string.match(meta.Image, "assetId=(%d+)")
						or string.match(meta.Image, "[?&]id=(%d+)")
						or string.match(meta.Image, "rbxassetid://(%d+)"));
				end;

				local row = { name = key, label = label, base = label, id = id, image = weaponThumbnail(meta) };

				if meta and meta.ItemType == "Gun" then
					guns[#guns + 1] = row;
				else
					knives[#knives + 1] = row;
				end;
			end;
		end;

		local function byName(a, b) return string.lower(a.label) < string.lower(b.label) end;

		table.sort(knives, byName);
		table.sort(guns, byName);

		local worn = {};
		local FAVORITES = "Salad Visuals/.data/skin favourites.json";
		local starred = {};

		do
			local ok, body = pcall(function() return readfile(FAVORITES) end);

			if ok and type(body) == "string" then
				local fine, list = pcall(function()
					return game:GetService("HttpService"):JSONDecode(body);
				end);

				if fine and type(list) == "table" then
					for _, key in ipairs(list) do starred[key] = true end;
				end;
			end;
		end;

		local function saveStarred()
			local list = {};

			for key in pairs(starred) do list[#list + 1] = key end;

			table.sort(list);

			pcall(function()
				writefile(FAVORITES, game:GetService("HttpService"):JSONEncode(list));
			end);
		end;

		local function ordered(rows)
			local out = {};

			for _, row in ipairs(rows) do
				out[#out + 1] = {
					name = row.name,
					label = (starred[row.name] and "• " or "") .. row.base,
					id = row.id,
					image = row.image,
					base = row.base,
				};
			end;

			table.sort(out, function(a, b)
				local sa, sb = starred[a.name] and 1 or 0, starred[b.name] and 1 or 0;

				if sa ~= sb then return sa > sb end;

				return string.lower(a.base) < string.lower(b.base);
			end);

			return out;
		end;

		local grids = {};

		local function wear(slot)
			return function(value)
				local key = (type(value) == "table") and value[1] or value;

				if not INGAME then return end;
				if type(key) ~= "string" or key == "" then
					if worn[slot] then
						worn[slot] = nil;
						pcall(apply, slot, nil);
						for tool in pairs(toolState) do unoverlayTool(tool) end;
					end;
					return;
				end;

				if worn[slot] == key then
					worn[slot] = nil;

					pcall(apply, slot, nil);

					for tool in pairs(toolState) do unoverlayTool(tool) end;

					return;
				end;

				worn[slot] = key;

				if pcall(apply, slot, key) then
					reapplyTools(slot);
				else
					worn[slot] = nil;
				end;
			end;
		end;

		local function star(slot, rows)
			return function(name)
				if type(name) ~= "string" or name == "" then return end;

				starred[name] = (not starred[name]) or nil;

				saveStarred();

				local grid = grids[slot];

				if grid and grid.setdata then pcall(grid.setdata, grid, ordered(rows)) end;
			end;
		end;

		grids.Knife = host.Page:AddGallery({
			Name = "Knives", Icon = "sword", Position = "left",
			Height = 430, Cell = 74, Thumb = "Asset", Blank = "sword", Reset = true, Smooth = true,
			Empty = "No knives", Values = ordered(knives),
			Flag = "skin_knife", Callback = wear("Knife"), Context = star("Knife", knives),
		});

		grids.Gun = host.Page:AddGallery({
			Name = "Guns", Icon = "crosshair", Position = "right",
			Height = 430, Cell = 74, Thumb = "Asset", Blank = "crosshair", Reset = true, Smooth = true,
			Empty = "No guns", Values = ordered(guns),
			Flag = "skin_gun", Callback = wear("Gun"), Context = star("Gun", guns),
		});

		local function watchCharacter(character)

			keepNamed("char", character.ChildAdded:Connect(function(child)
				local slot = (child.Name == "DisplayRefKnife" and "Knife")
					or (child.Name == "DisplayRefGun" and "Gun") or nil;

				if not slot then return end;

				task.delay(0.2, function()
					local skin = lastApplied[slot];

					if alive and skin then
						cleanup(slot);
						apply(slot, skin);
					end;
				end);
			end));
		end;

		if currentChar() then watchCharacter(currentChar()) end;

		keep(LocalPlayer.CharacterAdded:Connect(function(character)

			for slot in pairs(state) do
				local current = state[slot];

				state[slot] = nil;

				if current.chroma then pcall(function() current.chroma:Disconnect() end) end;
				if current.overlay then pcall(function() current.overlay:Destroy() end) end;
			end;

			for tool in pairs(toolState) do unoverlayTool(tool) end;

			watchCharacter(character);

			task.delay(1, function()
				if not alive then return end;

				for _, slot in ipairs({ "Knife", "Gun" }) do
					if lastApplied[slot] then apply(slot, lastApplied[slot]) end;
				end;
			end);
		end));

		for _, tag in ipairs({ "Weapon_Knife", "Weapon_Gun" }) do
			local slot = (tag == "Weapon_Gun") and "Gun" or "Knife";

			for _, tool in ipairs(CollectionService:GetTagged(tag)) do
				if isMine(tool) then task.spawn(overlayTool, tool, slot) end;
			end;

			keep(CollectionService:GetInstanceAddedSignal(tag):Connect(function(tool)
				if isMine(tool) then task.spawn(overlayTool, tool, slot) end;
			end));

			keep(CollectionService:GetInstanceRemovedSignal(tag):Connect(unoverlayTool));
		end;

		if EquipService then
			pcall(function()
				keep(EquipService.EquippedChanged.Event:Connect(function(kind, name)
					if not alive then return end;

					if (kind == "Knife" or kind == "Gun") and not worn[kind] then
						task.spawn(apply, kind, name);
					end;
				end));
			end);
		end;

		ESP.Skins = {
			MESHES = MESHES,
			apply = apply,
			worn = worn,
			count = #knives + #guns,
			ingame = INGAME,
		};

		ESP.ClearSkins = onUnload("skins", function()
			alive = false;

			for _, connection in ipairs(conns) do pcall(function() connection:Disconnect() end) end;
			for _, connection in pairs(named) do pcall(function() connection:Disconnect() end) end;

			table.clear(conns);
			table.clear(named);

			for slot in pairs(state) do pcall(cleanup, slot) end;
			for tool in pairs(toolState) do pcall(unoverlayTool, tool) end;

			ESP.Skins = nil;
		end);
	end);
end;
