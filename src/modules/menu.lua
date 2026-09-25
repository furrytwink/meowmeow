--!nonstrict
--[[
	menu.lua — extracted feature module (require id "modules.menu").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("menu") in the driver — byte-frozen original
	code below the marker (re-derived on every `make extract`; do not hand-edit).

	The block originally closed over driver locals; the driver now passes them
	in via the ctx table:

		guard("menu", function()
			return require("modules.menu")({ ESP = ESP, NeverLose = NeverLose, Notification = Notification, Preview = Preview, Remote = Remote, RunService = RunService, Sections = Sections, Window = Window, ownedSound = ownedSound });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local NeverLose = ctx.NeverLose;
	local Notification = ctx.Notification;
	local Preview = ctx.Preview;
	local Remote = ctx.Remote;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local Window = ctx.Window;
	local ownedSound = ctx.ownedSound;

-- [ guard("menu") callback body — byte-exact from input/message(47).txt ]

	local HttpService = game:GetService("HttpService");
	local ContentProvider = game:GetService("ContentProvider");
	local function fileExists(path)
		return Remote.listedPath(path);
	end;
	local function assetUrl(path)
		return Remote.id(path);
	end;
	local function readManifest(path)
		local body = Remote.body(path);
		if not body then return nil end;
		local ok, records = pcall(function() return HttpService:JSONDecode(body) end);
		return ok and type(records) == "table" and records or nil;
	end;
	local function localPath(relative)
		if type(relative) ~= "string" or relative == "" or relative:find("..", 1, true) or relative:find(":", 1, true) then return nil end;
		return Remote.file(relative);
	end;

	local function listFolder(relative)
		return Remote.under(relative .. "/");
	end;

	local function prettyName(name)
		local text = tostring(name or ""):match("^%s*(.-)%s*$");

		if text == "" then return "Untitled" end;

		return (text:gsub("[_%-]+", " "):gsub("(%a)(%d)", "%1 %2"):gsub("(%a[%w']*)", function(word)
			return word:sub(1, 1):upper() .. word:sub(2);
		end));
	end;

	do
		local hour = 12;
		local ok, clock = pcall(os.date, "*t");
		if ok and type(clock) == "table" and type(clock.hour) == "number" then
			hour = math.clamp(math.floor(clock.hour), 0, 23);
		else
			pcall(function() hour = DateTime.now():ToLocalTime().Hour end);
		end;
		local greeting = "dobry-vecher";
		if hour >= 5 and hour < 11 then
			greeting = "dobroe-utrechko";
		elseif hour >= 11 and hour < 17 then
			greeting = "dobry-denb";
		elseif hour >= 17 and hour < 22 then
			greeting = "dobry-vecher";
		end;
		ESP.Greeting = { Hour = hour, File = "sounds/time/" .. greeting .. ".ogg" };
		local url = assetUrl(Remote.file(ESP.Greeting.File));
		if url then
			local sound = Instance.new("Sound");
			sound:SetAttribute("VisualsOwned", true);
			sound.Name = NeverLose.RandomString();
			sound.SoundId = url;
			sound.Volume = 0.5;
			sound.Parent = NeverLose.ScreenGui;
			NeverLose:AddSignal(sound.Ended:Connect(function() sound:Destroy() end));
			game:GetService("Debris"):AddItem(sound, 30);
			sound:Play();
			ESP.Greeting.Sound = sound;
		end;
	end;

	local presets, order = {}, { "Off" };
	local records = readManifest("menusounds/manifest.json");
	if records then
		for _, entry in ipairs(records) do
			if type(entry) == "table" and type(entry.name) == "string" and entry.name ~= "Off" then
				local on, off = localPath(entry.on), localPath(entry.off);
				if on and fileExists(on) and not presets[entry.name] then
					presets[entry.name] = { on = on, off = off and fileExists(off) and off or nil };
					order[#order + 1] = entry.name;
				end;
			end;
		end;
	else
		local pairsFound, names = {}, {};
		for _, rel in ipairs(listFolder("menusounds")) do
			local file = string.match(rel, "([^/]+)$") or "";
			local name, side, extension = string.match(file:lower(), "^(.+)_(o[nf]f?)%.(%w+)$");
			if name and (extension == "wav" or extension == "ogg" or extension == "mp3") and fileExists(Remote.file(rel)) then
				if not pairsFound[name] then pairsFound[name] = {}; names[#names + 1] = name end;
				pairsFound[name][side] = Remote.file(rel);
			end;
		end;
		table.sort(names);
		for _, name in ipairs(names) do
			local entry = pairsFound[name];
			if entry.on then
				local label = prettyName(name) .. (entry.off and "" or " (ON only)");
				presets[label] = entry; order[#order + 1] = label;
			end;
		end;
	end;

	local M = { Preset = "Off", Volume = 50 };
	local onSound = ownedSound();
	onSound.Name = NeverLose.RandomString();
	onSound.Parent = NeverLose.ScreenGui;
	local offSound = onSound:Clone();
	offSound.Parent = NeverLose.ScreenGui;
	local soundSelection = 0;
	local click;
	local function loadPreset(name, preview)
		soundSelection += 1;
		local selection = soundSelection;
		local playPreview = preview and not NeverLose.Lib.quiet;
		onSound:Stop(); offSound:Stop();
		onSound.SoundId = ""; offSound.SoundId = "";
		local entry = presets[name];
		if not entry then return end;
		local function wanted()
			return Remote.current() and selection == soundSelection and M.Preset == name and onSound.Parent ~= nil and offSound.Parent ~= nil;
		end;
		task.spawn(function()
			local on = assetUrl(entry.on);
			if not wanted() then return end;

			local off = entry.off and assetUrl(entry.off) or "";
			if not wanted() then return end;
			onSound.SoundId = on or ""; offSound.SoundId = off or "";
			if playPreview then click(true) end;
		end);
	end;
	click = function(state)
		if M.Preset == "Off" or M.Volume <= 0 then return end;
		local sound = state and onSound or offSound;
		if not sound.Parent or sound.SoundId == "" then return end;
		sound.Volume = M.Volume / 100;
		sound.TimePosition = 0;
		sound:Play();
	end;
	ESP.MenuClick = click;
	ESP.MenuSounds = M;

	local lib = NeverLose.Lib;
	local OFF_KINDS = { off = true, close = true };

	function lib:chime(kind)
		if M.Preset == "Off" or M.Volume <= 0 then return end;
		if lib.quiet then return end;

		click(not OFF_KINDS[kind]);
	end;

	NeverLose.OnToggleChanged = function(_, flag, _)
		if Preview and Preview.Queue then Preview.Queue(flag) end;
	end;
	Sections.MenuSounds:AddLabel("Preset"):AddDropdown({
		Default = "Off", Values = order, Flag = "menu_sound",
		Callback = function(value) M.Preset = value; loadPreset(value, true) end,
	});
	Sections.MenuSounds:AddLabel("Volume"):AddSlider({
		Min = 0, Max = 100, Default = 50, Type = "%", Size = 100, Flag = "menu_sound_volume",
		Callback = function(value) M.Volume = value end,
	});

	local sheets, stickerOrder = {}, { "Off" };
	local function addSheet(record)
		if type(record) ~= "table" or type(record.name) ~= "string" or record.name == "Off" or sheets[record.name] then return end;
		local cols, rows = tonumber(record.cols), tonumber(record.rows);
		local width, height, frames = tonumber(record.width), tonumber(record.height), tonumber(record.frames);
		if not (cols and rows and width and height and frames) then return end;
		if cols < 1 or rows < 1 or frames < 1 or cols % 1 ~= 0 or rows % 1 ~= 0 or frames % 1 ~= 0 then return end;
		if width % cols ~= 0 or height % rows ~= 0 or width < cols or height < rows then return end;
		local files = {};
		for _, relative in ipairs(record.sheets or { record.file }) do
			local path = localPath(relative);
			if not (path and fileExists(path)) then return end;
			files[#files + 1] = path;
		end;
		if #files == 0 or frames > cols * rows * #files then return end;
		sheets[record.name] = {
			files = files, cols = cols, rows = rows, frames = frames,
			cellWidth = width / cols, cellHeight = height / rows,
			fps = math.clamp(tonumber(record.fps) or 15, 1, 120),
		};
		stickerOrder[#stickerOrder + 1] = record.name;
	end;
	local stickerRecords = readManifest("stickers/manifest.json");
	if stickerRecords then for _, record in ipairs(stickerRecords) do addSheet(record) end end;
	addSheet({ name = "Fury", sheets = {
		"images/furynew_sheet_1.png", "images/furynew_sheet_2.png", "images/furynew_sheet_3.png",
	}, width = 1024, height = 768, cols = 4, rows = 3, frames = 35, fps = 12 });

	local CUSTOM = "Salad Visuals/Stickers";
	local customNames = {};
	local function imageSize(path)
		if not readfile then return nil end;
		local ok, raw = pcall(readfile, path);
		if not ok or type(raw) ~= "string" or #raw < 24 or #raw > 16 * 1024 * 1024 then return nil end;
		local function uint(at, count)
			if at + count - 1 > #raw then return nil end;
			local value = 0;
			for index = at, at + count - 1 do value = value * 256 + raw:byte(index) end;
			return value;
		end;
		local width, height;
		if raw:sub(1, 8) == "\137PNG\13\10\26\10" and raw:sub(13, 16) == "IHDR" then
			width, height = uint(17, 4), uint(21, 4);
		elseif raw:byte(1) == 255 and raw:byte(2) == 216 then
			local at = 3;
			while at < #raw do
				if raw:byte(at) ~= 255 then break end;
				while raw:byte(at) == 255 do at += 1 end;
				local marker = raw:byte(at); at += 1;
				if not marker or marker == 217 or marker == 218 then break end;
				if marker ~= 1 and not (marker >= 208 and marker <= 216) then
					local length = uint(at, 2);
					if not length or length < 2 or at + length - 1 > #raw then break end;
					if marker >= 192 and marker <= 207 and marker ~= 196 and marker ~= 200 and marker ~= 204 then
						if length < 8 then break end;
						height, width = uint(at + 3, 2), uint(at + 5, 2); break;
					end;
					at += length;
				end;
			end;
		end;
		if width and height and width >= 1 and height >= 1 and width <= 8192 and height <= 8192 then return width, height end;
	end;

	local function scanCustom()
		if not (isfolder and listfiles and isfile) then return end;
		if not isfolder(CUSTOM) then
			if makefolder then pcall(makefolder, CUSTOM) end;

			return;
		end;

		local found = {};

		local ok = pcall(function()
			for _, path in ipairs(listfiles(CUSTOM)) do
				local file = string.match(path, "([^/\\]+)$") or "";
				local extension = string.match(string.lower(file), "%.(%w+)$");

				if extension == "png" or extension == "jpg" or extension == "jpeg" then
					found[#found + 1] = { path = path, file = file };
				end;
			end;
		end);

		if not ok then return end;

		table.sort(found, function(a, b) return string.lower(a.file) < string.lower(b.file) end);
		for _, name in ipairs(customNames) do
			sheets[name] = nil;
			local index = table.find(stickerOrder, name);
			if index then table.remove(stickerOrder, index) end;
		end;
		table.clear(customNames);

		for _, entry in ipairs(found) do
			local stem = string.gsub(entry.file, "%.%w+$", "");
			local base, cols, rows, frames = string.match(stem, "^(.+)_(%d+)x(%d+)_(%d+)$");
			local name = prettyName(base or stem);

			if sheets[name] then name = name .. " (mine)" end;
			local baseName, suffix = name, 2;
			while sheets[name] do name = baseName .. " " .. suffix; suffix += 1 end;
			local width, height = imageSize(entry.path);
			cols, rows, frames = tonumber(cols), tonumber(rows), tonumber(frames);
			if cols and (not width or cols < 1 or rows < 1 or cols > 64 or rows > 64
				or frames < 1 or frames > cols * rows or width % cols ~= 0 or height % rows ~= 0) then
				warn("[visuals] invalid sticker sheet: " .. entry.file);
				continue;
			end;

			if not sheets[name] then
				if cols then
					sheets[name] = {
						files = { entry.path }, cols = tonumber(cols), rows = tonumber(rows),
						frames = frames, cellWidth = width / cols, cellHeight = height / rows,
						fps = 15, custom = true, sheet = true,
					};
				else

					sheets[name] = {
						files = { entry.path }, cols = 1, rows = 1, frames = 1,
						fps = 1, custom = true, whole = true,
						cellWidth = width or 1, cellHeight = height or 1,
					};
				end;

				stickerOrder[#stickerOrder + 1] = name;
				customNames[#customNames + 1] = name;
			end;
		end;
	end;

	if #stickerOrder == 1 then
		local legacy = {};
		for _, path in ipairs(listFolder("stickers")) do
			local file = string.match(path, "([^/\\]+)$") or "";
			local name, cols, rows, frames = string.match(file, "^(.+)_(%d+)x(%d+)_(%d+)%.png$");
			if name then
				legacy[#legacy + 1] = { name = prettyName(name), file = "stickers/" .. file, cols = tonumber(cols), rows = tonumber(rows), frames = tonumber(frames), width = 128 * tonumber(cols), height = 128 * tonumber(rows), fps = 15 };
			end;
		end;
		table.sort(legacy, function(a, b) return a.name < b.name end);
		for _, record in ipairs(legacy) do addSheet(record) end;
	end;

	local ST = {
		Name = "Fury", Size = 176, Speed = 100, Opacity = 100, Side = "Header",
		Raise = 0, OffsetX = 0, OffsetY = 0, Layer = 60,
	};
	local holder = Instance.new("ImageLabel");
	holder.Name = "VisualsMenuSticker";
	holder.BackgroundTransparency = 1;
	holder.BorderSizePixel = 0;
	holder.ScaleType = Enum.ScaleType.Fit;
	holder.ImageColor3 = Color3.new(1, 1, 1);
	holder.ImageTransparency = 1;
	holder.Visible = false;
	holder.Active = false;
	holder.ZIndex = 60;
	holder.Parent = NeverLose.ScreenGui;
	local current, frame, elapsed, opacity = nil, 0, 0, 0;
	local pageLayers, activeLayer = {}, nil;
	local stickerSelection = 0;
	local menuOpen = Window.Signal:GetValue();
	local function clearLayers()
		activeLayer = nil;
		for _, layer in ipairs(pageLayers) do layer:Destroy() end;
		table.clear(pageLayers);
	end;
	local function prepareLayers(urls)
		clearLayers();
		for _, url in ipairs(urls) do
			local layer = Instance.new("ImageLabel");
			layer.Name = "VisualsMenuStickerLayer" .. tostring(#pageLayers + 1);
			layer.Size = UDim2.fromScale(1, 1);
			layer.BackgroundTransparency = 1;
			layer.BorderSizePixel = 0;
			layer.Image = url;
			layer.ImageColor3 = Color3.new(1, 1, 1);
			layer.ImageTransparency = 1;
			layer.ScaleType = Enum.ScaleType.Fit;
			layer.Visible = false;
			layer.Active = false;
			layer.ZIndex = ST.Layer;
			layer.Parent = holder;
			pageLayers[#pageLayers + 1] = layer;
		end;
		return table.clone(pageLayers);
	end;
	local function place()
		local window = ESP.WindowFrame and ESP.WindowFrame();
		if not (window and current) then return end;
		local screen = NeverLose.ScreenGui.AbsoluteSize;
		local size = math.min(ST.Size, math.max(16, screen.X - 4), math.max(16, screen.Y - 4));

		if NeverLose.Mobile then size = math.min(size, screen.Y * 0.4) end;
		local ratio = current.cellWidth / current.cellHeight;
		local width, height = size * math.min(1, ratio), size / math.max(1, ratio);
		local at, box = window.AbsolutePosition, window.AbsoluteSize;
		local origin = holder.AbsolutePosition - Vector2.new(holder.Position.X.Offset, holder.Position.Y.Offset);
		local x, y;

		if ST.Side == "Header" then x, y = at.X - width * 0.18, at.Y - height * 0.22;
		elseif ST.Side == "Header Right" then x, y = at.X + box.X - width * 0.82, at.Y - height * 0.22;
		elseif ST.Side == "Right" then x, y = at.X + box.X - width * 0.25, at.Y + box.Y - height;
		else x, y = at.X - width * 0.75, at.Y + box.Y - height end;

		x = math.clamp(x + ST.OffsetX, -width + 8, math.max(8, screen.X - 8));
		y = math.clamp(y + ST.OffsetY - ST.Raise, -height + 8, math.max(8, screen.Y - 8));

		if NeverLose.Mobile then
			local top = NeverLose.ScreenGui.AbsolutePosition.Y + game:GetService("GuiService"):GetGuiInset().Y;
			local bottom = NeverLose.ScreenGui.AbsolutePosition.Y + screen.Y;
			x = math.clamp(x, 0, math.max(0, screen.X - width));
			y = math.clamp(y, top, math.max(top, bottom - height));
		end;
		holder.Size = UDim2.fromOffset(width, height);
		holder.ZIndex = ST.Layer;
		for _, layer in ipairs(pageLayers) do layer.ZIndex = ST.Layer end;
		holder.Position = UDim2.fromOffset(x - origin.X, y - origin.Y);
	end;
	local function drawFrame()
		if not current then return end;
		local layer = pageLayers[1];
		if not layer then return end;

		if current.whole then
			layer.ImageRectSize = Vector2.new();
			layer.ImageRectOffset = Vector2.new();
		else
			local capacity = current.cols * current.rows;
			local page = math.floor(frame / capacity) + 1;
			local localFrame = frame % capacity;
			layer = pageLayers[page];
			if not (layer and current.cellWidth and current.cellHeight) then return end;
			layer.ImageRectSize = Vector2.new(current.cellWidth, current.cellHeight);
			layer.ImageRectOffset = Vector2.new((localFrame % current.cols) * current.cellWidth, math.floor(localFrame / current.cols) * current.cellHeight);
		end;
		if activeLayer ~= layer then
			if activeLayer then activeLayer.Visible = false; activeLayer.ImageTransparency = 1 end;
			activeLayer = layer;
			activeLayer.Visible = true;
		end;
		activeLayer.ImageTransparency = 1 - math.clamp(opacity, 0, 1);
	end;
	local function select(name)
		stickerSelection += 1;
		local selection = stickerSelection;
		current = nil; frame = 0; elapsed = 0; opacity = 0;
		clearLayers();
		holder.Visible = false; holder.ImageTransparency = 1;
		ST.Error = nil;
		local entry = sheets[name];
		if not entry then return end;
		local function wanted()
			return Remote.current() and selection == stickerSelection and ST.Name == name and holder.Parent ~= nil;
		end;
		local function show(urls)
			if not wanted() then return end;
			local layers = prepareLayers(urls);
			if not wanted() then return end;

			Remote.invoke(function() ContentProvider:PreloadAsync(layers) end, 5);
			if not wanted() then return end;
			current = entry;
			drawFrame(); place();
		end;

		task.spawn(function()
			local ok, reason = pcall(function()
				local resolved = entry.urls;
				if not resolved then
					resolved = {};
					for _, path in ipairs(entry.files) do
						if not wanted() then return end;
						local url = assetUrl(path);
						if not wanted() then return end;
						if not url then ST.Error = "Unable to load " .. path; return end;
						resolved[#resolved + 1] = url;
					end;
					entry.urls = resolved;
				end;
				show(resolved);
			end);
			if not ok and wanted() then ST.Error = tostring(reason) end;
		end);
	end;
	NeverLose:AddSignal(RunService.RenderStepped:Connect(function(dt)
		if not (NeverLose.ScreenGui.Parent and holder.Parent) then return end;
		local target = current and menuOpen and ST.Opacity / 100 or 0;
		opacity = opacity + (target - opacity) * (1 - math.exp(-18 * math.max(dt, 0)));
		if math.abs(target - opacity) < 0.001 then opacity = target end;
		holder.Visible = current ~= nil and opacity > 0.001;
		if activeLayer then activeLayer.ImageTransparency = 1 - math.clamp(opacity, 0, 1) end;
		if not current or not holder.Visible then return end;
		place();
		if not menuOpen or current.frames <= 1 then return end;
		local fps = current.fps * ST.Speed / 100;
		elapsed = elapsed + dt;
		local steps = math.floor(elapsed * fps);
		if steps < 1 then return end;
		elapsed = elapsed - steps / fps;
		frame = (frame + steps) % current.frames;
		drawFrame();
	end));
	local stickerDrop = Sections.MenuSticker:AddLabel("Sticker"):AddDropdown({

		Default = NeverLose.Mobile and "Off" or "Fury", Values = stickerOrder, Flag = "menu_sticker",
		Callback = function(value) ST.Name = value; select(value) end,
	});
	task.defer(function()
		if not Remote.current() then return end;
		scanCustom();
		if Remote.current() and stickerDrop and stickerDrop.SetValues then
			stickerDrop:SetValues(stickerOrder);
		end;
	end);

	Sections.MenuSticker:AddButton({
		Icon = "refresh-cw", Name = "Reload Stickers",
		Callback = function()
			local before = #stickerOrder;

			scanCustom();
			if not sheets[ST.Name] then ST.Name = "Off" end;
			select(ST.Name);

			if stickerDrop and stickerDrop.SetValues then
				pcall(stickerDrop.SetValues, stickerDrop, stickerOrder);
			end;

			Notification.new({
				Title = "Stickers",
				Content = (#stickerOrder - before) .. " added, " .. #customNames .. " custom",
				Duration = 4,
			});
		end,
	});
	Sections.MenuSticker:AddLabel("Spot"):AddDropdown({
		Default = "Header", Values = { "Header", "Header Right", "Right", "Left" }, Flag = "menu_sticker_side",
		Callback = function(value) ST.Side = value; place() end,
	});
	Sections.MenuSticker:AddLabel("Size"):AddSlider({
		Min = 40, Max = 700, Default = 176, Rounding = 0, Size = 100, Flag = "menu_sticker_size",
		Callback = function(value) ST.Size = value; place() end,
	});
	Sections.MenuSticker:AddLabel("Playback Speed"):AddSlider({
		Min = 10, Max = 200, Default = 100, Rounding = 0, Type = "%", Size = 100, Flag = "menu_sticker_speed",
		Callback = function(value) ST.Speed = value end,
	});
	Sections.MenuSticker:AddLabel("Opacity"):AddSlider({
		Min = 0, Max = 100, Default = 100, Rounding = 0, Type = "%", Size = 100, Flag = "menu_sticker_opacity",
		Callback = function(value) ST.Opacity = value end,
	});

	Sections.MenuSticker:AddLabel("Offset X"):AddSlider({
		Min = -200, Max = 200, Default = 0, Rounding = 0, Size = 100, Flag = "menu_sticker_x",
		Callback = function(value) ST.OffsetX = value; place() end,
	});
	Sections.MenuSticker:AddLabel("Offset Y"):AddSlider({
		Min = -200, Max = 200, Default = 0, Rounding = 0, Size = 100, Flag = "menu_sticker_y",
		Callback = function(value) ST.OffsetY = value; place() end,
	});

	Sections.MenuSticker:AddLabel("Layer"):AddSlider({
		Min = 1, Max = 120, Default = 60, Rounding = 0, Size = 100, Flag = "menu_sticker_z",
		Callback = function(value) ST.Layer = value; place() end,
	});
	Window.Signal:Connect(function(open) menuOpen = open end);
	ESP.Sticker = ST;
	ESP.ClearMenuExtras = function()
		stickerSelection += 1;
		soundSelection += 1;
		current = nil; menuOpen = false;
		ST.Name = "Off"; M.Preset = "Off";
		NeverLose.OnToggleChanged = function() end;
		onSound:Destroy(); offSound:Destroy(); holder:Destroy();
	end;
end;
