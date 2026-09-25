--!nonstrict
--[[
	assets.lua — extracted feature module (require id "modules.assets").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("assets") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("assets", function()
			return require("modules.assets")({ ESP = ESP, GLOBAL = GLOBAL, LocalPlayer = LocalPlayer, NeverLose = NeverLose, Notification = Notification, Remote = Remote, Sections = Sections, onUnload = onUnload, ownedSound = ownedSound, scanDescendantsAsync = scanDescendantsAsync, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local GLOBAL = ctx.GLOBAL;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local Notification = ctx.Notification;
	local Remote = ctx.Remote;
	local Sections = ctx.Sections;
	local onUnload = ctx.onUnload;
	local ownedSound = ctx.ownedSound;
	local scanDescendantsAsync = ctx.scanDescendantsAsync;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("assets") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local function assetUrl(rel)
		return Remote.asset(rel);
	end;

	local function listNames(folder, extensions, labels)
		local names, map, entries = { "Off" }, {}, {};
		if not isfile then return names, map end;

		local ok, files = pcall(Remote.under, folder .. "/");
		if not ok or type(files) ~= "table" then return names, map end;
		for _, rel in ipairs(files) do
			local file = string.match(rel, "[^/]+$");
			local extension = file and file:match("%.(%w+)$");
			if extension and extensions[extension:lower()] then
				local label = labels and labels[file];
				if not label then
					label = file:gsub("%.%w+$", ""):gsub("[_%-]+", " "):gsub("(%l)(%u)", "%1 %2");
					label = label:gsub("(%a[%w']*)", function(word) return word:sub(1, 1):upper() .. word:sub(2) end);
				end;
				entries[#entries + 1] = { name = label, file = file };
			end;
		end;
		table.sort(entries, function(a, b)
			if a.name:lower() == b.name:lower() then return a.file < b.file end;
			return a.name:lower() < b.name:lower();
		end);
		for _, entry in ipairs(entries) do
			local name = entry.name;
			if map[name] or name == "Off" then name = name .. " (" .. entry.file .. ")" end;
			names[#names + 1] = name;
			map[name] = folder .. "/" .. entry.file;
		end;
		return names, map;
	end;

	local _, cursorFiles = listNames("cursors", { png = true, jpg = true, jpeg = true });
	local soundNames, soundFiles = listNames("sounds", { wav = true, ogg = true, mp3 = true });

	local lib = NeverLose.Lib;

	for name, file in pairs(cursorFiles or {}) do
		if name ~= "Off" and not lib.cursors[name] then
			lib.cursors[name] = "";
			lib.cursorlist[#lib.cursorlist + 1] = name;
		end;
	end;
	local setStyle, setCursor = lib.setstyle, lib.setcursor;
	local function resolveCursor(name)
		if cursorFiles[name] and lib.cursors[name] == "" then
			local url = assetUrl(cursorFiles[name]);
			if not url then return false end;
			lib.cursors[name] = url;
		end;
		return true;
	end;
	function lib:setstyle(name)
		if not self.cursor or resolveCursor(name) then return setStyle(self, name) end;
	end;
	function lib:setcursor(value)
		if value and not resolveCursor(self.style) then return end;
		return setCursor(self, value);
	end;

	table.sort(lib.cursorlist, function(a, b) return string.lower(a) < string.lower(b) end);

	lib.style = lib.style or lib.cursorlist[1];

	if #lib.cursorlist > 0 then
		local cursorRow = Sections.ScreenInfo:AddLabel("Custom Cursor");

		cursorRow:AddToggle({
			Default = false, Flag = "cursor_on",
			Callback = function(v) pcall(function() lib:setcursor(v) end) end,
		});

		Sections.ScreenInfo:AddLabel("Cursor"):AddDropdown({
			Default = lib.style,
			Values = lib.cursorlist,
			Flag = "cursor_skin",
			Callback = function(v) pcall(function() lib:setstyle(v) end) end,
		});

		Sections.ScreenInfo:AddLabel("Cursor Size"):AddSlider({
			Min = 16, Max = 96, Default = 32, Rounding = 0, Size = 90,
			Flag = "cursor_size",
			Callback = function(v)

				for _, child in ipairs(lib.scr:GetChildren()) do
					if child:IsA("ImageLabel") and child.ZIndex == 2147483647 then
						child.Size = UDim2.fromOffset(v, v);
					end;
				end;
			end,
		});
	end;

	onUnload("cursor", function()
		pcall(function() lib:setcursor(false) end);
	end);

	local KILL_LABELS = {
		["kill_anime1.ogg"] = "Туда бомжа!",
		["kill_anime2.ogg"] = "Ой а где ты?",
		["kill_anime3.ogg"] = "На колени! На колени!",
		["kill_anime4.ogg"] = "Ой а мне его даже жалко",
		["kill_anime5.ogg"] = "Он слишком слаб",
		["kill_anime6.ogg"] = "Как же ты хорош?",
		["krasavchik.ogg"] = "Красавчик",
		["molodec.ogg"] = "Молодец",
		["na-koleni.ogg"] = "На колени",
		["sosat-sosat.ogg"] = "Сосать! Сосать!",
	};
	local killNames, killFiles = listNames("killsounds", { ogg = true, wav = true, mp3 = true }, KILL_LABELS);
	local killChoices = {};
	for _, name in ipairs(killNames) do if name ~= "Off" then killChoices[#killChoices + 1] = name end end;
	local killAliases = {
		["Kill Anime1"] = "Туда бомжа!", ["Kill Anime2"] = "Ой а где ты?",
		["Kill Anime3"] = "На колени! На колени!", ["Kill Anime4"] = "Ой а мне его даже жалко",
		["Kill Anime5"] = "Он слишком слаб", ["Kill Anime6"] = "Как же ты хорош?",
		Krasavchik = "Красавчик", Molodec = "Молодец", ["Na Koleni"] = "На колени",
		["Sosat Sosat"] = "Сосать! Сосать!", ["Сосать, сосать"] = "Сосать! Сосать!",
		["Туда, бомжа!"] = "Туда бомжа!", ["Ой, а где ты?"] = "Ой а где ты?",
		["На колени, на колени!"] = "На колени! На колени!",
		["Ой, а мне его даже жалко"] = "Ой а мне его даже жалко",
	};
	local soundService = game:GetService("SoundService");
	local ReplicatedStorage = game:GetService("ReplicatedStorage");
	local H = { Shoot = "Off", ShootVolume = 50, Kill = "Off", Kills = {}, KillVolume = 60, Hush = false,
		MuteShoot = true, MuteReload = true, MuteKill = true, MuteKillEffect = true };
	H.KillAliases, H.KillChoices = killAliases, killChoices;
	ESP.SoundSettings = H;
	local previousAudio = GLOBAL.__VisualsAudioRuntime;
	if type(previousAudio) == "table" and type(previousAudio.Stop) == "function" then pcall(previousAudio.Stop) end;
	local audioRuntime = {};
	local cfg = {
		Sheriff = { on = false, volume = 1.8 },
		Murderer = { on = false, volume = 1.8 },
	};
	local pools, sources, hooked, weaponHooks = {}, {}, {}, {};
	local activeSounds, deathHooks = {}, {};
	local lastAttackAt, lastAttackRole, lastShotAt = 0, nil, 0;
	local lastKillSignalAt, playingKill, lastKillName = -math.huge, nil, nil;
	local random = Random.new();

	local function toolKind(tool)
		if not tool or not tool:IsA("Tool") then return nil end;
		local name = string.lower(tool.Name);
		if tool:FindFirstChild("GunClient") or tool:FindFirstChild("Shoot")
			or name == "gun" or name == "revolver" or name:find("gun", 1, true) then return "Sheriff" end;
		if tool:FindFirstChild("KnifeClient") or tool:FindFirstChild("Events")
			or name == "knife" or name:find("knife", 1, true) or name:find("blade", 1, true) then return "Murderer" end;
	end;

	local function configFor(role)
		return role and cfg[role] or nil;
	end;

	local function resolve(name, pool)
		local rel = (pool or soundFiles)[name];
		if not rel then return nil end;
		local cached = sources[rel];
		if cached then return cached end;
		local id = assetUrl(rel);
		if id then sources[rel] = id end;
		return id;
	end;

	local function template(name)
		if not name or name == "Off" then return nil end;
		local id = resolve(name, killFiles);
		if not id then return nil end;
		local old = pools[name];
		if old and old.Parent and old.SoundId == id then return old end;
		if old then pcall(function() old:Destroy() end) end;
		local s = ownedSound();
		s.Name = "VisualsKillSoundTemplate";
		s.SoundId, s.Volume, s.Looped = id, 1, false;
		s.Parent = soundService;
		pools[name] = s;
		task.spawn(function() pcall(function() game:GetService("ContentProvider"):PreloadAsync({ s }) end) end);
		return s;
	end;
	local function selectedKills()
		local selected = {};
		for _, name in ipairs(killChoices) do if H.Kills[name] then selected[#selected + 1] = name end end;
		return selected;
	end;
	local function chooseKill()
		local selected = selectedKills();
		if #selected == 0 then return nil end;
		local index = random:NextInteger(1, #selected);
		if #selected > 1 and selected[index] == lastKillName then index = index % #selected + 1 end;
		lastKillName = selected[index];
		H.LastKill = lastKillName;
		return lastKillName;
	end;
	local function killGain(value)
		return math.clamp((tonumber(value) or 0) / 100 * 3, 0, 3);
	end;
	local function setKillSelection(value)
		local picked = {};
		if type(value) == "table" then
			for key, entry in pairs(value) do
				local name = type(key) == "string" and entry and key or type(entry) == "string" and entry or nil;
				if name and killFiles[name] then picked[name] = true end;
			end;
		elseif type(value) == "string" and value ~= "Off" and killFiles[value] then picked[value] = true end;
		H.Kills = picked;
		if next(picked) == nil then H.LastKill, lastKillName = nil, nil end;
		local first = selectedKills()[1];
		H.Kill = first or "Off";
		local enabled = first ~= nil;
		cfg.Murderer.on, cfg.Sheriff.on = enabled, enabled;
		for name in pairs(picked) do task.spawn(template, name) end;
	end;

	local function play(role)
		local c = configFor(role) or cfg.Murderer;
		if not (c and c.on) then return false end;

		local now = os.clock();
		local duplicate = now - lastKillSignalAt < 0.12;
		lastKillSignalAt = now;
		if duplicate then return false end;
		local name = chooseKill();
		local base = template(name);
		if not (c and c.on and base) then return false end;
		local ok = pcall(function()
			if playingKill and playingKill.Parent then playingKill:Stop(); activeSounds[playingKill] = nil; playingKill:Destroy() end;
			local s = base:Clone();
			s.Name = "VisualsKillSound";
			playingKill = s;
			activeSounds[s] = true;
			s.Volume, s.TimePosition, s.Parent = c.volume, 0, soundService;
			s:Play();
			task.delay(8, function()
				if playingKill == s then playingKill = nil end;
				activeSounds[s] = nil; s:Destroy();
			end);
		end);
		return ok;
	end;

	local function playNamed(name, pool, volume)
		local id = resolve(name, pool);
		if not id or name == "Off" then return false end;
		local ok = pcall(function()
			local s = ownedSound();
			activeSounds[s] = true;
			s.Name, s.SoundId, s.Volume = "VisualsHitSound", id, volume;
			s.Looped, s.Parent = false, soundService;
			s:Play();
			task.delay(8, function() activeSounds[s] = nil; s:Destroy() end);
		end);
		return ok;
	end;

	local function isKillName(name)
		name = string.lower(name or "");
		return name == "kill" or name == "gunkill" or name == "knife kill"
			or name:find("killeffect", 1, true) or name:find("elimination", 1, true)
			or name:find("death", 1, true) or name:find("murder", 1, true);
	end;

	local function ancestorTool(inst)
		local node = inst.Parent;
		while node and node ~= game do
			if node:IsA("Tool") then return node end;
			node = node.Parent;
		end;
	end;

	local function isLocalTool(tool)
		local character = LocalPlayer.Character;
		return tool and (tool:IsDescendantOf(LocalPlayer) or (character and tool:IsDescendantOf(character)));
	end;
	local function roleForSound(inst)
		local tool = ancestorTool(inst);
		if tool then return isLocalTool(tool) and toolKind(tool) or nil end;
		local character = LocalPlayer.Character;
		local name = string.lower(inst.Name);
		if character and inst:IsDescendantOf(character) and (name == "kill" or name == "gunkill")
			and os.clock() - lastAttackAt <= 1.5 then return lastAttackRole end;
	end;
	local function ownSound(inst)
		return inst:GetAttribute("VisualsOwned") or inst:IsDescendantOf(NeverLose.ScreenGui);
	end;

	local SHOT_NAMES = {
		fire = true, gunshot = true, gun = true, shoot = true, shot = true,
		bang = true, pistol = true, revolver = true,
	};
	local function wantedMute(inst)
		local name = inst.Name:lower();
		local parent = inst.Parent;
		local pName = parent and parent.Name:lower() or "";
		local grand = parent and parent.Parent;
		local gpName = grand and grand.Name:lower() or "";
		local ancestry = name;
		local node = parent;
		for _ = 1, 7 do
			if not node or node == game then break end;
			ancestry ..= " " .. string.lower(node.Name);
			node = node.Parent;
		end;
		local killContext = isKillName(name) or ancestry:find("killeffect", 1, true)
			or ancestry:find("kill effect", 1, true) or ancestry:find("knife kill", 1, true)
			or ancestry:find("murder", 1, true) or ancestry:find("victim", 1, true)
			or ancestry:find("ragdoll", 1, true) or ancestry:find("corpse", 1, true);
		if H.MuteShoot then
			local compound = name:find("gunshot", 1, true) or name:find("gunfire", 1, true)
				or name:find("pistolshot", 1, true) or name:find("revolvershot", 1, true);
			local underGun = pName:find("gun", 1, true) or pName:find("revolver", 1, true) or pName:find("pistol", 1, true)
				or gpName:find("gun", 1, true) or gpName:find("revolver", 1, true) or gpName:find("pistol", 1, true);
			if SHOT_NAMES[name] or compound or (underGun and not name:find("reload", 1, true)) then return true end;
		end;
		if H.MuteReload and (name:find("reload", 1, true) or name:find("cock", 1, true)
			or name:find("cylinder", 1, true) or name:find("spin", 1, true)) then return true end;
		if H.MuteKill and (isKillName(name) or name:find("slash", 1, true) or name:find("stab", 1, true)
			or name:find("knife", 1, true) or name:find("hit", 1, true)
			or pName:find("knife", 1, true) or gpName:find("knife", 1, true)) then return true end;
		if H.MuteKillEffect and (killContext or name:find("killeffect", 1, true) or name:find("effect", 1, true)
			or name:find("death", 1, true) or name:find("dissolve", 1, true) or name:find("freeze", 1, true)
			or name:find("electric", 1, true) or name:find("vapor", 1, true) or name:find("shatter", 1, true)
			or pName:find("effect", 1, true) or pName:find("killeffect", 1, true)
			or pName:find("nl_killfx", 1, true) or gpName:find("nl_killfx", 1, true)) then return true end;
		return false;
	end;
	local function mute(inst)
		local entry = hooked[inst];
		if not entry then return end;
		if H.Hush and not ownSound(inst) and wantedMute(inst) then
			if not entry.muted then entry.volume = inst.Volume end;
			entry.muted = true;
			if inst.Volume ~= 0 then inst.Volume = 0 end;
		elseif entry.muted then
			entry.muted = false;
			if inst.Volume == 0 then inst.Volume = entry.volume end;
		end;
	end;
	local function unhookSound(inst)
		local entry = hooked[inst];
		if not entry then return end;
		hooked[inst] = nil;
		for _, connection in ipairs(entry.conns) do connection:Disconnect() end;
		if entry.muted and inst.Parent and inst.Volume == 0 then inst.Volume = entry.volume end;
	end;
	local function retireLegacyMute(inst)

		local inspect = getupvalues or (debug and debug.getupvalues);
		if type(getconnections) ~= "function" or type(inspect) ~= "function" or not (debug and debug.info) then return end;
		local ok, callbacks = pcall(getconnections, inst:GetPropertyChangedSignal("Volume"));
		if not ok then return end;
		for _, connection in ipairs(callbacks) do
			local fn = connection.Function;
			if type(fn) == "function" then
				local gotSource, source = pcall(debug.info, fn, "s");
				if gotSource and (source == "visuals" or source == "@visuals") then
					local gotValues, values = pcall(inspect, fn);
					local settings, entry;
					if gotValues and type(values) == "table" then
						for _, value in pairs(values) do
							if type(value) == "table" then
								if type(value.Hush) == "boolean" and type(value.Shoot) == "string" and type(value.Kill) == "string"
									and type(value.ShootVolume) == "number" and type(value.KillVolume) == "number" then settings = value end;
								if type(value.volume) == "number" and type(value.conns) == "table" then entry = value end;
							end;
						end;
					end;
					if settings and settings ~= H and entry then
						settings.Hush = false;
						for _, old in ipairs(entry.conns) do pcall(function() old:Disconnect() end) end;
						if entry.muted and inst.Volume == 0 then inst.Volume = entry.volume end;
						entry.muted = false;
					end;
				end;
			end;
		end;
	end;
	local function hookSound(inst)
		if not __ALIVE() or not inst:IsA("Sound") or ownSound(inst) or hooked[inst] then return end;
		retireLegacyMute(inst);
		local entry = { volume = inst.Volume, conns = {}, lastFire = -math.huge };
		hooked[inst] = entry;
		local function keep(connection) entry.conns[#entry.conns + 1] = connection end;
		local function fire()
			if not __ALIVE() then return end;
			mute(inst);
			if not isKillName(inst.Name) or os.clock() - entry.lastFire < 0.08 then return end;
			local role = roleForSound(inst);
			local c = configFor(role);
			if not (role and c and c.on) then return end;
			entry.lastFire = os.clock();
			pcall(function() inst:Stop() end);
			play(role);
		end;
		keep(inst.Played:Connect(fire));
		keep(inst:GetPropertyChangedSignal("Playing"):Connect(function() mute(inst) end));
		keep(inst:GetPropertyChangedSignal("Parent"):Connect(function() mute(inst) end));
		keep(inst:GetPropertyChangedSignal("Name"):Connect(function() mute(inst) end));
		keep(inst:GetAttributeChangedSignal("VisualsOwned"):Connect(function() mute(inst) end));
		keep(inst:GetPropertyChangedSignal("Volume"):Connect(function()
			if not entry.muted then entry.volume = inst.Volume end;
			if __ALIVE() and H.Hush and inst.Volume ~= 0 then mute(inst) end;
		end));
		keep(inst.Destroying:Connect(function() unhookSound(inst) end));
		mute(inst);
	end;
	local function hookWeapon(tool)
		local role = toolKind(tool);
		if not __ALIVE() or not role or not isLocalTool(tool) or weaponHooks[tool] then return end;
		local record = {};
		weaponHooks[tool] = record;
		record.attack = tool.Activated:Connect(function()
			if not __ALIVE() or not isLocalTool(tool) then return end;
			lastAttackAt, lastAttackRole = os.clock(), role;
		end);
		record.destroy = tool.Destroying:Connect(function()
			weaponHooks[tool] = nil;
			record.attack:Disconnect(); record.destroy:Disconnect();
		end);
	end;
	local function hookDeath(human)
		if deathHooks[human] then return end;
		local record = {};
		deathHooks[human] = record;
		record.death = human.Died:Connect(function()
			if not __ALIVE() then return end;
			local creator = human:FindFirstChild("creator") or human:FindFirstChild("Creator");
			if not (creator and creator:IsA("ObjectValue") and creator.Value == LocalPlayer) then return end;
			local role = lastAttackRole;
			if not role then
				for _, tool in ipairs((LocalPlayer.Character or LocalPlayer):GetChildren()) do role = toolKind(tool); if role then break end end;
			end;
			play(role or "Murderer");
		end);
		record.destroy = human.Destroying:Connect(function()
			deathHooks[human] = nil;
			record.death:Disconnect(); record.destroy:Disconnect();
		end);
	end;
	local function discover(inst)
		if not __ALIVE() then return end;
		if inst:IsA("Tool") then hookWeapon(inst)
		elseif inst:IsA("Sound") then hookSound(inst)
		elseif inst:IsA("Humanoid") then hookDeath(inst) end;
	end;
	local function scan()
		for inst in pairs(hooked) do mute(inst) end;
	end;
	NeverLose:AddSignal(workspace.DescendantAdded:Connect(discover));
	NeverLose:AddSignal(soundService.DescendantAdded:Connect(discover));
	NeverLose:AddSignal(LocalPlayer.DescendantAdded:Connect(discover));
	local function watchLocalCharacter(character)
		if not __ALIVE() or LocalPlayer.Character ~= character then return end;
		NeverLose:AddSignal(character.DescendantAdded:Connect(discover));
		for _, inst in ipairs(character:GetDescendants()) do discover(inst) end;
	end;
	NeverLose:AddSignal(LocalPlayer.CharacterAdded:Connect(watchLocalCharacter));
	if LocalPlayer.Character then watchLocalCharacter(LocalPlayer.Character) end;
	local function removed(inst)
		if hooked[inst] then unhookSound(inst) end;
	end;
	NeverLose:AddSignal(workspace.DescendantRemoving:Connect(removed));
	NeverLose:AddSignal(soundService.DescendantRemoving:Connect(removed));
	NeverLose:AddSignal(LocalPlayer.DescendantRemoving:Connect(removed));
	audioRuntime.Active = true;
	audioRuntime.ScanTask = scanDescendantsAsync("sound scan", { workspace, soundService, LocalPlayer }, discover, function()
		return audioRuntime.Active;
	end, 512);

	local shotRemote, shotConn;
	local function playShot()
		local now = os.clock();
		if H.Shoot == "Off" or now - lastShotAt <= 0.045 then return end;
		lastShotAt = now;
		playNamed(H.Shoot, soundFiles, H.ShootVolume / 100);
	end;
	local function bindShots()
		local services = ReplicatedStorage:FindFirstChild("ClientServices");
		local weapons = services and services:FindFirstChild("WeaponService");
		local remote = weapons and weapons:FindFirstChild("GunFired");
		if not (remote and remote:IsA("RemoteEvent")) or remote == shotRemote then return end;
		if shotConn then shotConn:Disconnect() end;
		shotRemote = remote;
		shotConn = remote.OnClientEvent:Connect(function(gun)
			local character = LocalPlayer.Character;
			if __ALIVE() and typeof(gun) == "Instance" and character and gun:IsDescendantOf(character) then playShot() end;
		end);
	end;
	pcall(bindShots);
	task.spawn(function()

		while audioRuntime.Active do
			task.wait(2);
			pcall(bindShots);
		end;
	end);
	local combatConnections = {};
	if ESP.Combat then
		combatConnections[#combatConnections + 1] = ESP.Combat.Attack.Event:Connect(function(info)
			if type(info) ~= "table" then return end;
			lastAttackAt = info.at or os.clock();
			lastAttackRole = toolKind(info.tool) or (info.kind == "shot" and "Sheriff") or (info.kind == "melee" and "Murderer") or lastAttackRole;

			if not shotRemote and info.kind == "shot" and (info.source == "tool" or info.source == "input") then playShot() end;
		end);
		combatConnections[#combatConnections + 1] = ESP.Combat.Kill.Event:Connect(function(info)
			local attack = type(info) == "table" and info.attack or nil;
			local role = attack and (toolKind(attack.tool) or (attack.kind == "shot" and "Sheriff") or (attack.kind == "melee" and "Murderer")) or lastAttackRole;
			play(role or "Murderer");
		end);
	end;

	Sections.WorldMisc:AddLabel("Shoot Sound"):AddDropdown({
		Default = "Off", Values = soundNames, Flag = "hitsound",
		Callback = function(v) H.Shoot = v; end,
	});
	Sections.WorldMisc:AddLabel("Shoot Volume"):AddSlider({
		Min = 0, Max = 100, Default = 50, Type = "%", Size = 90, Flag = "sound_volume",
		Callback = function(v) H.ShootVolume = v; end,
	});
	Sections.WorldMisc:AddLabel("Kill Sound"):AddDropdown({
		Default = {}, Values = killChoices, Multi = true, Flag = "killsound",
		Callback = setKillSelection,
	});
	Sections.WorldMisc:AddLabel("Kill Volume"):AddSlider({
		Min = 0, Max = 100, Default = 60, Type = "%", Size = 90, Flag = "kill_volume",
		Callback = function(v) H.KillVolume = v; cfg.Murderer.volume, cfg.Sheriff.volume = killGain(v), killGain(v); end,
	});

	Sections.WorldMisc:AddButton({
		Name = "Test Shoot Sound", Icon = "play-large",
		Callback = function()
			if H.Shoot == "Off" then
				Notification.new({ Title = "Sounds", Content = "Pick a shoot sound first", Duration = 3 });
				return;
			end;
			playNamed(H.Shoot, soundFiles, H.ShootVolume / 100);
		end,
	});
	Sections.WorldMisc:AddButton({
		Name = "Test Kill Sound", Icon = "play-large",
		Callback = function()
			lastKillSignalAt = 0;
			if not play("Murderer") then
				Notification.new({ Title = "Sounds", Content = "Pick a kill sound first", Duration = 3 });
			end;
		end,
	});

	local muteRow = Sections.WorldMisc:AddLabel("Mute Game Sounds");
	muteRow:AddToggle({
		Name = "Mute Game Sounds", Default = false, Flag = "sound_hush",
		Callback = function(v) H.Hush = v == true; scan() end,
	});
	local muteOptions = muteRow:AddOption(1);
	for _, option in ipairs({
		{ "Shoot", "MuteShoot", "sound_mute_shoot" },
		{ "Reload", "MuteReload", "sound_mute_reload" },
		{ "Kill (Murderer)", "MuteKill", "sound_mute_murder" },
		{ "Kill Effect", "MuteKillEffect", "sound_mute_effect" },
	}) do
		local key = option[2];
		muteOptions:AddLabel(option[1]):AddToggle({
			Default = true, Flag = option[3],
			Callback = function(v) H[key] = v == true; scan() end,
		});
	end;

	ESP.ClearSounds = onUnload("sounds", function()
		audioRuntime.Active = false;
		H.Hush = false;
		playingKill, lastKillSignalAt = nil, -math.huge;
		if GLOBAL.__VisualsAudioRuntime == audioRuntime then GLOBAL.__VisualsAudioRuntime = nil end;
		for inst in pairs(activeSounds) do inst:Destroy() end;
		table.clear(activeSounds);
		for _, record in pairs(weaponHooks) do record.attack:Disconnect(); record.destroy:Disconnect() end;
		for _, record in pairs(deathHooks) do record.death:Disconnect(); record.destroy:Disconnect() end;
		for _, connection in ipairs(combatConnections) do connection:Disconnect() end;
		table.clear(combatConnections);
		if shotConn then shotConn:Disconnect(); shotConn = nil end;
		table.clear(weaponHooks); table.clear(deathHooks);
		for inst in pairs(hooked) do unhookSound(inst) end;
		table.clear(hooked);
		for role, s in pairs(pools) do pcall(function() s:Destroy() end); pools[role] = nil end;
	end);
	audioRuntime.Stop = ESP.ClearSounds;
	GLOBAL.__VisualsAudioRuntime = audioRuntime;

	ESP.Assets = { Url = assetUrl, Cursors = cursorFiles, Sounds = soundFiles };
end;
