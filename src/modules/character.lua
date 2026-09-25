--!nonstrict
--[[
	character.lua — extracted feature module (require id "modules.character").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("character") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("character", function()
			return require("modules.character")({ ESP = ESP, INIT_GENERATION = INIT_GENERATION, LocalPlayer = LocalPlayer, NeverLose = NeverLose, Notification = Notification, Remote = Remote, Sections = Sections, TAG = TAG, Visuals = Visuals, onUnload = onUnload, recordError = recordError, userFile = userFile, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local INIT_GENERATION = ctx.INIT_GENERATION;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local Notification = ctx.Notification;
	local Remote = ctx.Remote;
	local Sections = ctx.Sections;
	local TAG = ctx.TAG;
	local Visuals = ctx.Visuals;
	local onUnload = ctx.onUnload;
	local recordError = ctx.recordError;
	local userFile = ctx.userFile;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("character") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local STORE = userFile("accessories.json");
	local HttpService = game:GetService("HttpService");
	local A = { On = false, Type = "Auto", Items = {}, Order = {}, Enabled = {}, Error = nil };
	ESP.CharacterAccessories = A;
	local cache, loading, pending, worn, connections = {}, {}, {}, {}, {};
	local accessoryGeometry = {};
	local settingsSaveToken, settingsDirty = 0, false;
	local generation, grid, activeLoads = 0, nil, 0;
	local characterConnections, departing, repairQueued = {}, nil, false;
	local TYPES, VALID_TYPES = { "Auto" }, { Auto = true };
	for _, kind in ipairs(Enum.AccessoryType:GetEnumItems()) do
		if kind ~= Enum.AccessoryType.Unknown and kind.Name ~= "Eyebrow" and kind.Name ~= "Eyelash" then
			TYPES[#TYPES + 1] = kind.Name; VALID_TYPES[kind.Name] = true;
		end;
	end;
	local function notify(message)
		A.Error = message;
		Notification.new({ Title = "Character", Content = message, Duration = 5 });
	end;
	local function parseId(value)
		local text = tostring(value or "");
		local digits = text:match("^%s*(%d+)%s*$") or text:match("/catalog/(%d+)") or text:match("/library/(%d+)") or text:match("rbxassetid://(%d+)");
		local number = digits and tonumber(digits);
		if not number or number < 1 or number >= 2 ^ 53 or number % 1 ~= 0 then return nil end;
		return string.format("%.0f", number);
	end;
	local function keyFor(id, kind) return id .. ":" .. kind end;
	local function transformNumber(value, default, minimum, maximum)
		value = tonumber(value);
		if not value or value ~= value or value == math.huge or value == -math.huge then return default end;
		return math.clamp(value, minimum, maximum);
	end;
	local function accessorySettings(item)
		return {
			Size = transformNumber(item.Size, 1, 0.25, 2.5),
			X = transformNumber(item.X, 0, -5, 5),
			Y = transformNumber(item.Y, 0, -5, 5),
			Z = transformNumber(item.Z, 0, -5, 5),
		};
	end;
	local function destroyWorn(key)
		local copy = worn[key];
		worn[key] = nil;
		accessoryGeometry[key] = nil;
		if copy then pcall(function() copy:Destroy() end) end;
	end;
	local function rows()
		local out = {};
		for _, key in ipairs(A.Order) do
			local item = A.Items[key];
			if item then out[#out + 1] = { name = key, label = item.Name .. " [" .. item.Kind .. "]", id = tonumber(item.Id) } end;
		end;
		return out;
	end;
	local function selected()
		local out = {};
		for _, key in ipairs(A.Order) do if A.Enabled[key] then out[#out + 1] = key end end;
		return out;
	end;
	local function save()
		if not writefile then return end;
		local items = {};
		for _, key in ipairs(A.Order) do
			local item = A.Items[key];
			if item then
				local settings = accessorySettings(item);
				items[#items + 1] = { id = item.Id, kind = item.Kind, name = item.Name,
					size = settings.Size, x = settings.X, y = settings.Y, z = settings.Z };
			end;
		end;
		local ok, json = pcall(HttpService.JSONEncode, HttpService, { version = 2, items = items });
		if ok then pcall(writefile, STORE, json) end;
	end;
	local function flushAccessorySettings()
		if settingsDirty then settingsDirty = false; save() end;
	end;
	local function queueAccessorySave()
		settingsDirty = true;
		settingsSaveToken += 1;
		local token = settingsSaveToken;
		task.delay(0.45, function()
			if __ALIVE() and token == settingsSaveToken then flushAccessorySettings() end;
		end);
	end;
	local function loadTemplate(id)
		if cache[id] then return cache[id] end;
		if loading[id] then
			local deadline = os.clock() + 15;
			repeat task.wait(0.05) until not loading[id] or not __ALIVE() or os.clock() >= deadline;
			return cache[id];
		end;
		loading[id] = true;
		local deadline = os.clock() + 15;
		while Remote.current() and activeLoads >= 4 and os.clock() < deadline do task.wait(0.05) end;
		if not Remote.current() or activeLoads >= 4 then loading[id] = nil; return nil end;
		activeLoads += 1;
		local roots, temporary = {}, nil;
		local completed, result = pcall(function()
		local ok, objects = Remote.objects(function() return game:GetObjects("rbxassetid://" .. id) end);
		if not ok or type(objects) ~= "table" or not objects[1] then
			ok, objects = Remote.objects(function() return { game:GetService("InsertService"):LoadAsset(tonumber(id)) } end);
			objects = ok and type(objects) == "table" and objects or {};
		end;
		roots = objects;
		local found;
		for _, object in ipairs(objects) do
			if object:IsA("Accessory") or object:IsA("Hat") then found = found or object end;
			if not found then
				for _, obj in ipairs(object:GetDescendants()) do
					if obj:IsA("Accessory") or obj:IsA("Hat") then found = obj; break end;
				end;
			end;
		end;
		local template;
		if __ALIVE() and found and #found:GetDescendants() <= 256 then
			found.Archivable = true;
			for _, obj in ipairs(found:GetDescendants()) do obj.Archivable = true end;
			template = found:Clone();
			temporary = template;
		end;
		for _, object in ipairs(objects) do pcall(function() object:Destroy() end) end;
		if template and template:IsA("Hat") then
			local holder = Instance.new("Accessory");
			holder.Name, holder.AttachmentPoint = template.Name, template.AttachmentPoint;
			for _, child in ipairs(template:GetChildren()) do child.Parent = holder end;
			template:Destroy(); template = holder; temporary = holder;
		end;
		local handle = template and template:FindFirstChild("Handle");
		if not (__ALIVE() and handle and handle:IsA("BasePart")) then
			if template then template:Destroy() end;
			loading[id] = nil;
			return nil;
		end;
		for _, obj in ipairs(template:GetDescendants()) do
			if obj:IsA("LuaSourceContainer") or obj:IsA("Sound") or obj:IsA("BodyMover")
				or obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail")
				or (obj:IsA("JointInstance") and obj.Name == "AccessoryWeld") then
				obj:Destroy();
			elseif obj:IsA("BasePart") then
				obj.Anchored, obj.CanCollide, obj.CanTouch, obj.CanQuery = false, false, false, false;
				obj.Massless = true;
			end;
		end;
		if not __ALIVE() then template:Destroy(); loading[id] = nil; return nil end;
		cache[id], loading[id] = template, nil;
		return template;
		end);
		activeLoads -= 1;
		loading[id] = nil;
		if not completed then
			for _, root in ipairs(roots) do pcall(function() root:Destroy() end) end;
			if temporary then pcall(function() temporary:Destroy() end) end;
			return nil;
		end;
		return result;
	end;
	local ATTACHMENTS = {
		Hat = "HatAttachment", Hair = "HairAttachment", Face = "FaceFrontAttachment",
		Neck = "NeckAttachment", Shoulder = "RightShoulderAttachment",
		Front = "BodyFrontAttachment", Back = "BodyBackAttachment", Waist = "WaistCenterAttachment",
	};
	local function targetAttachment(character, name)
		if not name then return nil end;
		for _, part in ipairs(character:GetChildren()) do
			if part:IsA("BasePart") then
				local attachment = part:FindFirstChild(name);
				if attachment and attachment:IsA("Attachment") then return attachment end;
			end;
		end;
	end;
	local function scaledAccessoryFrame(cf, scale)
		return CFrame.new(cf.Position * scale) * (cf - cf.Position);
	end;
	local function captureAccessoryGeometry(copy)
		local handle = copy:FindFirstChild("Handle");
		local weld = handle and handle:FindFirstChild("VisualsAccessoryWeld");
		if not handle or not weld then return nil end;
		local geometry = { Copy = copy, Handle = handle, Weld = weld, C0 = weld.C0, C1 = weld.C1,
			Parts = {}, Meshes = {}, Attachments = {}, Joints = {} };
		for _, object in ipairs(copy:GetDescendants()) do
			if object:IsA("BasePart") then
				geometry.Parts[object] = { Size = object.Size, Relative = handle.CFrame:ToObjectSpace(object.CFrame) };
			elseif object:IsA("DataModelMesh") then

				local fileMesh = object:IsA("FileMesh") and (not object:IsA("SpecialMesh") or object.MeshType == Enum.MeshType.FileMesh);
				geometry.Meshes[object] = { Scale = object.Scale, Offset = object.Offset, File = fileMesh };
			elseif object:IsA("Attachment") then
				geometry.Attachments[object] = object.CFrame;
			elseif object ~= weld and object:IsA("JointInstance") and object.Part0 and object.Part1
				and object.Part0:IsDescendantOf(copy) and object.Part1:IsDescendantOf(copy) then
				geometry.Joints[object] = { C0 = object.C0, C1 = object.C1 };
			end;
		end;
		return geometry;
	end;
	local function applyAccessoryTransform(key)
		local item, geometry = A.Items[key], accessoryGeometry[key];
		if not item or not geometry or worn[key] ~= geometry.Copy or not geometry.Copy.Parent then return end;
		local settings = accessorySettings(item);
		local scale = settings.Size;
		local weld = geometry.Weld;
		if not weld.Parent or not weld.Part0 or not weld.Part0.Parent then return end;
		local c0 = CFrame.new(settings.X, settings.Y, settings.Z) * geometry.C0;
		local c1 = scaledAccessoryFrame(geometry.C1, scale);
		local anchor = weld.Part0;
		local handleFrame = anchor.CFrame * c0 * c1:Inverse();

		weld.Part0 = nil;
		local ok, err = pcall(function()
		for part, base in pairs(geometry.Parts) do
			if part.Parent then
				part.Size = base.Size * scale;
				part.CFrame = handleFrame * scaledAccessoryFrame(base.Relative, scale);
			end;
		end;
		for mesh, base in pairs(geometry.Meshes) do
			if mesh.Parent then mesh.Scale = base.Scale * (base.File and scale or 1); mesh.Offset = base.Offset * scale end;
		end;
		for attachment, base in pairs(geometry.Attachments) do
			if attachment.Parent then attachment.CFrame = scaledAccessoryFrame(base, scale) end;
		end;
		for joint, base in pairs(geometry.Joints) do
			if joint.Parent then joint.C0 = scaledAccessoryFrame(base.C0, scale); joint.C1 = scaledAccessoryFrame(base.C1, scale) end;
		end;
		weld.C0, weld.C1 = c0, c1;
		geometry.Handle.CFrame = handleFrame;
		end);
		weld.Part0 = anchor;
		if not ok then error(err) end;
	end;
	local function setAccessoryTransform(key, field, value)
		local item = A.Items[key];
		if not __ALIVE() or not item or (field ~= "Size" and field ~= "X" and field ~= "Y" and field ~= "Z") then return false end;
		value = tonumber(value);
		if not value or value ~= value or value == math.huge or value == -math.huge then return false end;
		value = math.clamp(value, field == "Size" and 0.25 or -5, field == "Size" and 2.5 or 5);
		if accessorySettings(item)[field] == value then return true end;
		item[field] = value;
		local ok, err = pcall(applyAccessoryTransform, key);
		if not ok then recordError("accessory transform: " .. tostring(err)) end;
		queueAccessorySave();
		return ok;
	end;
	A.SetTransform = setAccessoryTransform;
	local function attachCopy(template, item, character, human, track)
		local copy = template:Clone();
		track(copy);
		copy:SetAttribute("VisualsCharacterAccessory", true);
		copy:SetAttribute("VisualsAccessoryKey", keyFor(item.Id, item.Kind));
		copy:SetAttribute(TAG, INIT_GENERATION);
		local handle = copy:FindFirstChild("Handle");
		if not handle then copy:Destroy(); return nil end;
		if item.Kind ~= "Auto" then pcall(function() copy.AccessoryType = Enum.AccessoryType[item.Kind] end) end;
		local source, target;
		local preferred = ATTACHMENTS[item.Kind];
		if preferred then
			source = handle:FindFirstChild(preferred);
			target = targetAttachment(character, preferred);
		end;
		for _, attachment in ipairs(handle:GetChildren()) do
			if attachment:IsA("Attachment") then
				source = source or attachment;
				if item.Kind == "Auto" then
					local matching = targetAttachment(character, attachment.Name);
					if matching then source, target = attachment, matching; break end;
				end;
			end;
		end;
		local added = pcall(function() human:AddAccessory(copy) end);
		if not added or copy.Parent ~= character then copy.Parent = character end;
		local part, c0;
		if target then part, c0 = target.Parent, target.CFrame
		else
			local head = character:FindFirstChild("Head");
			local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart");
			local kind = item.Kind;
			if kind == "Auto" and source then
				local name = source.Name;
				if name:find("Waist") then kind = "Waist"
				elseif name:find("Back") then kind = "Back"
				elseif name:find("Front") and not name:find("Face") then kind = "Front"
				elseif name:find("Shoulder") then kind = "Shoulder"
				elseif name:find("Neck") then kind = "Neck" end;
			end;
			local body = kind == "Waist" or kind == "Front" or kind == "Back" or kind == "Shoulder" or kind == "Neck";
			part = body and torso or head or torso;
			if not part then copy:Destroy(); return nil end;
			local offset = Vector3.new(0, part.Size.Y * 0.5, 0);
			if kind == "Waist" then offset = Vector3.new(0, -part.Size.Y * 0.4, 0)
			elseif kind == "Front" then offset = Vector3.new(0, 0, -part.Size.Z * 0.5)
			elseif kind == "Back" then offset = Vector3.new(0, 0, part.Size.Z * 0.5)
			elseif kind == "Shoulder" then offset = Vector3.new(part.Size.X * 0.5, part.Size.Y * 0.4, 0)
			elseif kind == "Face" then offset = Vector3.new(0, 0, -part.Size.Z * 0.5) end;
			c0 = CFrame.new(offset);
		end;
		if not part:IsA("BasePart") then copy:Destroy(); return nil end;
		for _, weld in ipairs(handle:GetChildren()) do
			if weld:IsA("JointInstance") and (weld.Name == "AccessoryWeld" or weld.Name == "VisualsAccessoryWeld") then weld:Destroy() end;
		end;
		local c1 = source and source.CFrame or copy.AttachmentPoint;
		handle.CFrame = part.CFrame * c0 * c1:Inverse();
		local weld = Instance.new("Weld");
		weld.Name, weld.Part0, weld.Part1, weld.C0, weld.C1 = "VisualsAccessoryWeld", part, handle, c0, c1;
		weld.Parent = handle;
		return copy;
	end;
	local function reconcile()
		generation += 1;
		A.On = next(A.Enabled) ~= nil;
		local token = generation;
		local character = LocalPlayer.Character;
		local human = character and character:FindFirstChildOfClass("Humanoid");
		for key, copy in pairs(worn) do
			if not A.On or not A.Enabled[key] or not copy.Parent or copy.Parent ~= character then destroyWorn(key) end;
		end;
		if not (__ALIVE() and A.On and character and character ~= departing and character.Parent and human) then return end;
		for _, key in ipairs(A.Order) do
			local item = A.Items[key];
			if item and A.Enabled[key] and not worn[key] then
				task.spawn(function()
					local template = loadTemplate(item.Id);
					if not __ALIVE() or token ~= generation or not A.On or not A.Enabled[key] or not A.Items[key]
						or LocalPlayer.Character ~= character or not character.Parent or not human.Parent or worn[key] then return end;
					if not template then notify("Cannot load accessory " .. item.Id); return end;
					local created;
					local ok, copy = pcall(attachCopy, template, item, character, human, function(c) created = c end);
					if ok and copy then
						worn[key] = copy;
						local transformed, transformError = pcall(function()
							accessoryGeometry[key] = captureAccessoryGeometry(copy);
							applyAccessoryTransform(key);
						end);
						if not transformed then recordError("accessory transform: " .. tostring(transformError)) end;
						A.Error = nil;
					else
						if created then pcall(function() created:Destroy() end) end;
						notify("Cannot attach accessory " .. item.Id .. (ok and "" or ": " .. tostring(copy)));
					end;
				end);
			end;
		end;
	end;
	local function choose(values)
		A.Enabled = {};
		for _, key in ipairs(type(values) == "table" and values or {}) do
			if A.Items[key] then A.Enabled[key] = true end;
		end;
		reconcile();
	end;
	local function refresh()
		if grid then grid:setdata(rows()); grid:set(selected()) end;
	end;
	function A.ImportConfig(selection, catalog)
		local imported, changed = {}, false;
		if type(catalog) == "string" and #catalog <= 65536 then
			local ok, saved = pcall(HttpService.JSONDecode, HttpService, catalog);
			if ok and type(saved) == "table" then
				for index, item in ipairs(saved) do
					if index > 128 then break end;
					if type(item) == "table" then
						local id, kind = parseId(item.Id), item.Kind;
						if id and VALID_TYPES[kind] then imported[keyFor(id, kind)] = item end;
					end;
				end;
			end;
		end;
		if type(selection) == "string" then
			local count = 0;
			for part in selection:gmatch("[^,]+") do
				count += 1; if count > 128 then break end;
				local id, kind = part:match("^%s*(%d+):([%w]+)%s*$");
				id = id and parseId(id);
				if id and VALID_TYPES[kind] then
					local key = keyFor(id, kind);
					imported[key] = imported[key] or { Id = id, Kind = kind };
				end;
			end;
		end;
		for key, item in pairs(imported) do
			local existing = A.Items[key];
			local settings = accessorySettings(item);
			local name = tostring(item.Name or ("Accessory " .. item.Id)):gsub("[%c|]", " "):sub(1, 100);
			if not existing then
				A.Items[key] = { Id = parseId(item.Id), Kind = item.Kind, Name = name,
					Size = settings.Size, X = settings.X, Y = settings.Y, Z = settings.Z };
				A.Order[#A.Order + 1] = key;
				changed = true;
			elseif item.Size ~= nil then
				existing.Size, existing.X, existing.Y, existing.Z = settings.Size, settings.X, settings.Y, settings.Z;
				applyAccessoryTransform(key); changed = true;
			end;
		end;
		if changed then save(); refresh() end;
	end;
	NeverLose.Lib:hook("character_accessory_catalog", "string", function()
		local items = {};
		for _, key in ipairs(A.Order) do
			if #items >= 128 then break end;
			local item = A.Items[key];
			if item then
				local settings = accessorySettings(item);
				items[#items + 1] = { Id = item.Id, Kind = item.Kind, Name = item.Name,
					Size = settings.Size, X = settings.X, Y = settings.Y, Z = settings.Z };
			end;
		end;
		return HttpService:JSONEncode(items);
	end, function() end);
	local function addById(value, kind)
		local id = parseId(value);
		kind = kind or A.Type;
		if not id or not VALID_TYPES[kind] then notify("Enter a valid accessory ID and type"); return false end;
		local key = keyFor(id, kind);
		if A.Items[key] then A.Enabled[key] = true; refresh(); reconcile(); return true end;
		if pending[key] then return false end;
		pending[key] = true;
		task.spawn(function()
			local template = loadTemplate(id);
			pending[key] = nil;
			if not __ALIVE() then return end;
			if not template then notify("ID " .. id .. " is unavailable or is not an accessory"); return end;
			local name = tostring(template.Name):gsub("[%c|]", " "):sub(1, 100);
			if name == "" then name = "Accessory " .. id end;
			if not A.Items[key] then
				A.Items[key] = { Id = id, Kind = kind, Name = name };
				A.Order[#A.Order + 1] = key;
			end;
			A.Enabled[key], A.Error = true, nil;
			save(); refresh(); reconcile();
		end);
		return true;
	end;
	local function removeSelected()
		local any = false;
		for index = #A.Order, 1, -1 do
			local key = A.Order[index];
			if A.Enabled[key] then
				any = true; A.Items[key], A.Enabled[key] = nil, nil;
				destroyWorn(key); table.remove(A.Order, index);
			end;
		end;
		if any then
			save(); refresh(); reconcile();
			for id, template in pairs(cache) do
				local used = false;
				for _, item in pairs(A.Items) do if item.Id == id then used = true; break end end;
				if not used and not loading[id] then template:Destroy(); cache[id] = nil end;
			end;
		end;
		return any;
	end;
	A.Add, A.RemoveSelected, A.Refresh = addById, removeSelected, refresh;
	if isfile and readfile and isfile(STORE) then
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(STORE)) end);
		if ok and type(data) == "table" and type(data.items) == "table" then
			for _, saved in ipairs(data.items) do
				if type(saved) == "table" then
					local id, kind = parseId(saved.id), saved.kind;
					if id and VALID_TYPES[kind] then
						local key = keyFor(id, kind);
						if not A.Items[key] then
							A.Items[key] = { Id = id, Kind = kind, Name = tostring(saved.name or ("Accessory " .. id)):gsub("[%c|]", " "):sub(1, 100),
								Size = transformNumber(saved.size, 1, 0.25, 2.5),
								X = transformNumber(saved.x, 0, -5, 5), Y = transformNumber(saved.y, 0, -5, 5), Z = transformNumber(saved.z, 0, -5, 5) };
							A.Order[#A.Order + 1] = key;
						end;
					end;
				end;
			end;
		end;
	end;
	Sections.Character:AddLabel(""):AddDropdown({
		Default = "Auto", Values = TYPES, FullWidth = true, Flag = "character_accessory_type", Callback = function(v) A.Type = v end,
	});
	Sections.Character:AddButton({ Name = "Add by ID", Icon = "plus", Callback = function()
		local kind = A.Type;
		NeverLose.Lib:ask({
			title = "add accessory — " .. kind, icon = "plus", hint = "accessory ID or catalog link",
			accept = "add", deny = "cancel", callback = function(text) addById(text, kind) end,
		});
	end });
	Sections.Character:AddButton({ Name = "Remove Selected", Icon = "trash-can", Callback = removeSelected });
	Sections.Character:AddButton({ Name = "Unequip All", Icon = "x", Callback = function()
		A.Enabled = {}; refresh(); reconcile();
	end });
	local function showAccessoryMenu(key, _, x, y, cell)
		local item = A.Items[key];
		if not __ALIVE() or not item then return end;
		if typeof(cell) == "Instance" and cell:IsA("GuiObject") then
			local position, size = cell.AbsolutePosition, cell.AbsoluteSize;
			x, y = position.X + size.X - 8, position.Y + 20;
		end;
		local settings = accessorySettings(item);
		local sliders = {{ name = "Size", min = 25, max = 250, value = math.floor(settings.Size * 100 + 0.5), suffix = "%",
			callback = function(value) setAccessoryTransform(key, "Size", value / 100) end }};
		for _, axis in ipairs({ "X", "Y", "Z" }) do
			local field = axis;
			sliders[#sliders + 1] = { name = field, min = -5, max = 5, step = 0.1, precision = 1,
				value = settings[field], suffix = "", callback = function(value) setAccessoryTransform(key, field, value) end };
		end;
		local ok, err = pcall(function()
			NeverLose.Lib:popup({ name = "VisualsAccessoryOptions", title = item.Name, icon = "shirt",
				x = x, y = y, follow = cell, width = 194, sliders = sliders });
		end);
		if not ok then recordError("accessory options: " .. tostring(err)) end;
	end;
	grid = Visuals.Character:AddGallery({
		Name = "Character", Icon = "shirt", Position = "left", Height = 320, Cell = 78,
		Thumb = "Asset", Blank = "shirt", Empty = "Add an accessory by ID", Values = rows(), Reset = true, Smooth = true,
		Multi = true, Flag = "character_accessory_pick", Callback = choose,
		Action = { Icon = "ellipsis", Callback = showAccessoryMenu },
	});
	task.spawn(function()
		task.wait(0.25);
		for index = 1, math.min(#A.Order, 8) do
			if not __ALIVE() then return end;
			local item = A.Items[A.Order[index]];
			if item then pcall(loadTemplate, item.Id) end;
			task.wait();
		end;
	end);
	local function watchCharacter(character)
		for _, conn in ipairs(characterConnections) do conn:Disconnect() end;
		table.clear(characterConnections);
		departing = nil;
		if not character then return end;
		characterConnections[#characterConnections + 1] = character.ChildRemoved:Connect(function(copy)
			local key = copy:GetAttribute("VisualsAccessoryKey");
			if not __ALIVE() or not key or not A.Enabled[key] or departing == character or repairQueued then return end;
			repairQueued = true;
			task.defer(function()
				repairQueued = false;
				if __ALIVE() and LocalPlayer.Character == character and departing ~= character then reconcile() end;
			end);
		end);
		characterConnections[#characterConnections + 1] = character.ChildAdded:Connect(function(obj)
			if obj:IsA("Humanoid") and __ALIVE() and LocalPlayer.Character == character then reconcile() end;
		end);
		task.spawn(function()
			character:WaitForChild("Humanoid", 10);
			if __ALIVE() and LocalPlayer.Character == character then reconcile() end;
		end);
	end;
	watchCharacter(LocalPlayer.Character);
	connections[#connections + 1] = LocalPlayer.CharacterAdded:Connect(watchCharacter);
	connections[#connections + 1] = LocalPlayer.CharacterAppearanceLoaded:Connect(function(character)
		if __ALIVE() and LocalPlayer.Character == character then reconcile() end;
	end);
	connections[#connections + 1] = LocalPlayer.CharacterRemoving:Connect(function(character)
		departing = character;
		generation += 1;
		for key in pairs(worn) do destroyWorn(key) end;
	end);
	ESP.ClearCharacterAccessories = onUnload("character accessories", function()
		flushAccessorySettings(); settingsSaveToken += 1;
		A.On = false; generation += 1;
		for _, conn in ipairs(connections) do conn:Disconnect() end;
		for _, conn in ipairs(characterConnections) do conn:Disconnect() end;
		table.clear(connections);
		table.clear(characterConnections);
		for key in pairs(worn) do destroyWorn(key) end;
		table.clear(accessoryGeometry);
		for id, template in pairs(cache) do template:Destroy(); cache[id] = nil end;
		table.clear(pending);
	end);
end;
