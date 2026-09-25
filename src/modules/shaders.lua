--!nonstrict
--[[
	shaders.lua — extracted feature module (require id "modules.shaders").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("shaders") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("shaders", function()
			return require("modules.shaders")({ ESP = ESP, NeverLose = NeverLose, Remote = Remote, RunService = RunService, Sections = Sections, onUnload = onUnload, recordError = recordError, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local NeverLose = ctx.NeverLose;
	local Remote = ctx.Remote;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local onUnload = ctx.onUnload;
	local recordError = ctx.recordError;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("shaders") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local Lighting = game:GetService("Lighting");

	local bloom, rays, blur, grade;
	local keepers = {};

	local function effect(class, props, adopt)
		local inst;

		local function make(old)
			local fresh = Instance.new(class);

			fresh.Name = NeverLose.RandomString();
			fresh.Enabled = false;

			for key, value in pairs(props) do fresh[key] = value end;

			if old then
				for key in pairs(props) do
					pcall(function() fresh[key] = old[key] end);
				end;

				pcall(function() fresh.Enabled = old.Enabled end);
			end;

			fresh.Parent = Lighting;

			return fresh;
		end;

		inst = make(nil);

		keepers[#keepers + 1] = function()
			if inst.Parent ~= Lighting then
				inst = make(inst);

				adopt(inst);
			end;
		end;

		return inst;
	end;

	bloom = effect("BloomEffect", { Intensity = 0.6, Size = 24, Threshold = 0.9 },
		function(v) bloom = v end);
	rays = effect("SunRaysEffect", { Intensity = 0.15, Spread = 0.9 },
		function(v) rays = v end);
	blur = effect("BlurEffect", { Size = 8 },
		function(v) blur = v end);
	grade = effect("ColorCorrectionEffect", { Brightness = 0, Contrast = 0.1, Saturation = 0.2, TintColor = Color3.fromRGB(255, 255, 255) },
		function(v) grade = v end);

	task.spawn(function()
		while __ALIVE() do
			task.wait(1);

			if not __ALIVE() then break end;

			for _, keeper in ipairs(keepers) do pcall(keeper) end;
		end;
	end);

	local AIR = {
		On = false, Density = 0.3, Haze = 0, Glare = 0,
		Color = Color3.fromRGB(199, 199, 199), Decay = Color3.fromRGB(106, 112, 125),
	};

	local airMine, airSaved;

	local function airInstance()
		local found = Lighting:FindFirstChildOfClass("Atmosphere");

		if not found then
			found = Instance.new("Atmosphere");
			found.Name = NeverLose.RandomString();
			found.Parent = Lighting;
			airMine = found;
		end;

		if not airSaved or airSaved.instance ~= found or not found.Parent then
			airSaved = {
				instance = found,
				Density = found.Density, Offset = found.Offset, Haze = found.Haze,
				Glare = found.Glare, Color = found.Color, Decay = found.Decay,
			};
		end;

		return found;
	end;

	local function applyAir()
		local fog = ESP.Fog;
		local fogOn = fog and fog.On;

        if not (AIR.On or fogOn) then

			if airSaved and airSaved.instance and airSaved.instance.Parent then
				local a = airSaved.instance;

				pcall(function()
					a.Density = airSaved.Density;
					a.Offset = airSaved.Offset;
					a.Haze = airSaved.Haze;
					a.Glare = airSaved.Glare;
					a.Color = airSaved.Color;
					a.Decay = airSaved.Decay;
				end);
			end;

			if airMine then pcall(function() airMine:Destroy() end); airMine = nil; airSaved = nil end;

			return;
		end;

		local a = airInstance();

		if not a then return end;

		if fogOn then
			a.Density = math.clamp(fog.Density / 100, 0, 1);
			a.Offset = math.clamp(fog.Offset or 0, -1, 1);
			a.Color = fog.Color;
		elseif AIR.On then
			a.Density = math.clamp(AIR.Density, 0, 1);
			a.Offset = airSaved and airSaved.Offset or 0;
			a.Color = AIR.Color;
		end;

		if AIR.On then
			a.Haze = math.clamp(AIR.Haze, 0, 10);
			a.Glare = math.clamp(AIR.Glare, 0, 10);
			a.Decay = AIR.Decay;
		elseif airSaved then
			a.Haze = airSaved.Haze;
			a.Glare = airSaved.Glare;
			a.Decay = airSaved.Decay;
		end;
	end;

	ESP.ApplyAir = applyAir;
	ESP.Air = AIR;

	onUnload("atmosphere", function()
		AIR.On = false;

		if ESP.Fog then ESP.Fog.On = false end;

		pcall(applyAir);
	end);

	ESP.Shaders = setmetatable({}, {__index=function(_, key)
		if key == "bloom" then return bloom elseif key == "rays" then return rays elseif key == "blur" then return blur elseif key == "grade" then return grade end;
	end});

	ESP.ClearShaders = function()
		ESP.ShaderLighting = nil;
		if ESP.RestoreFog then pcall(ESP.RestoreFog) end;
		if ESP.RestoreLighting then pcall(ESP.RestoreLighting) end;

		if ESP.RestoreSky then pcall(ESP.RestoreSky) end;

		bloom:Destroy();
		rays:Destroy();
		blur:Destroy();
		grade:Destroy();

		AIR.On = false;

		if ESP.Fog then ESP.Fog.On = false end;

		pcall(applyAir);
	end;

	local PRESETS = {
		Day = {
			bloom = { on = true, intensity = 0.35, size = 20, threshold = 1.1 },
			rays = { on = true, intensity = 0.08 },
			blur = { on = false, size = 8 },
			grade = { on = true, brightness = 0.02, contrast = 0.12, saturation = 0.15, tint = Color3.fromRGB(255, 252, 245) },
			air = { on = true, density = 0.25, haze = 0.6, color = Color3.fromRGB(205, 216, 226) },
		},
		Night = {
			bloom = { on = true, intensity = 0.75, size = 30, threshold = 0.75 },
			rays = { on = false, intensity = 0 },
			blur = { on = false, size = 8 },
			grade = { on = true, brightness = -0.04, contrast = 0.2, saturation = -0.2, tint = Color3.fromRGB(150, 175, 255) },
			air = { on = true, density = 0.42, haze = 1.2, color = Color3.fromRGB(70, 86, 120) },
		},
		Night2 = {
			bloom = { on = true, intensity = 0.32, size = 22, threshold = 1.15 },
			rays = { on = false, intensity = 0 },
			blur = { on = false, size = 0 },
			grade = { on = true, brightness = 0.025, contrast = 0.14, saturation = -0.06, tint = Color3.fromRGB(226, 237, 255) },
			air = { on = true, density = 0.18, haze = 0.35, color = Color3.fromRGB(166, 185, 211) },
			lighting = { ClockTime = 21.15, Brightness = 2.35, ExposureCompensation = 0.12,
				Ambient = Color3.fromRGB(90, 103, 127), OutdoorAmbient = Color3.fromRGB(105, 119, 145),
				EnvironmentDiffuseScale = 0.6, EnvironmentSpecularScale = 0.8, GlobalShadows = true },
		},
		Sunset = {
			bloom = { on = true, intensity = 0.9, size = 34, threshold = 0.8 },
			rays = { on = true, intensity = 0.3 },
			blur = { on = false, size = 8 },
			grade = { on = true, brightness = 0.03, contrast = 0.18, saturation = 0.35, tint = Color3.fromRGB(255, 196, 150) },
			air = { on = true, density = 0.38, haze = 1.8, color = Color3.fromRGB(255, 180, 140) },
		},
		Noir = {
			bloom = { on = true, intensity = 0.5, size = 26, threshold = 0.85 },
			rays = { on = false, intensity = 0 },
			blur = { on = false, size = 8 },
			grade = { on = true, brightness = -0.02, contrast = 0.45, saturation = -1, tint = Color3.fromRGB(255, 255, 255) },
			air = { on = true, density = 0.3, haze = 1, color = Color3.fromRGB(150, 150, 150) },
		},
		Vibrant = {
			bloom = { on = true, intensity = 0.6, size = 24, threshold = 0.95 },
			rays = { on = true, intensity = 0.15 },
			blur = { on = false, size = 8 },
			grade = { on = true, brightness = 0.05, contrast = 0.25, saturation = 0.6, tint = Color3.fromRGB(255, 255, 255) },
			air = { on = false, density = 0.3, haze = 0, color = Color3.fromRGB(199, 199, 199) },
		},
		Dream = {
			bloom = { on = true, intensity = 1.4, size = 40, threshold = 0.6 },
			rays = { on = true, intensity = 0.22 },
			blur = { on = true, size = 6 },
			grade = { on = true, brightness = 0.06, contrast = -0.05, saturation = 0.3, tint = Color3.fromRGB(255, 220, 245) },
			air = { on = true, density = 0.45, haze = 2.4, color = Color3.fromRGB(255, 215, 240) },
		},
		Horror = {
			bloom = { on = true, intensity = 0.18, size = 18, threshold = 1.25 },
			rays = { on = false, intensity = 0 },
			blur = { on = false, size = 0 },
			grade = { on = true, brightness = 0.005, contrast = 0.2, saturation = -0.32, tint = Color3.fromRGB(225, 239, 228) },
			air = { on = true, density = 0.22, haze = 0.55, color = Color3.fromRGB(128, 145, 136) },
		},
	};

	ESP.ShaderPresets = PRESETS;
	local function syncShaderFlags(flags)
		local lib = NeverLose.Lib;
		local quiet, applying = lib.quiet, lib.configApplying;
		lib.quiet, lib.configApplying = true, true;
		local ok, err = pcall(function()
			for id, value in pairs(flags) do local entry = lib.pool[id]; if entry then entry.set(value) end end;
		end);
		lib.quiet, lib.configApplying = quiet, applying;
		if not ok then recordError("shader preset: " .. tostring(err)) end;
	end;

	local function applyPreset(name)
		local preset = PRESETS[name];
		if not preset then return end;
		ESP.ShaderLighting = preset.lighting;
		if ESP.ApplyLighting then ESP.ApplyLighting() end;

		bloom.Enabled = preset.bloom.on;
		bloom.Intensity = preset.bloom.intensity;
		bloom.Size = preset.bloom.size;
		bloom.Threshold = preset.bloom.threshold;

		rays.Enabled = preset.rays.on;
		rays.Intensity = preset.rays.intensity;

		blur.Enabled = preset.blur.on;
		blur.Size = preset.blur.size;

		grade.Enabled = preset.grade.on;
		grade.Brightness = preset.grade.brightness;
		grade.Contrast = preset.grade.contrast;
		grade.Saturation = preset.grade.saturation;
		grade.TintColor = preset.grade.tint;

		AIR.Density = preset.air.density;
		AIR.Haze = preset.air.haze;
		AIR.Color = preset.air.color;
		AIR.On = preset.air.on;

		applyAir();
		syncShaderFlags({
			shader_bloom=preset.bloom.on, shader_bloom_intensity=preset.bloom.intensity*100, shader_bloom_size=preset.bloom.size, shader_bloom_threshold=preset.bloom.threshold*100,
			shader_rays=preset.rays.on, shader_rays_intensity=preset.rays.intensity*100, shader_blur=preset.blur.on, shader_blur_size=preset.blur.size,
			shader_grade=preset.grade.on, shader_grade_brightness=preset.grade.brightness*100, shader_grade_contrast=preset.grade.contrast*100,
			shader_grade_saturation=preset.grade.saturation*100, shader_grade_tint=preset.grade.tint,
			shader_atmosphere=preset.air.on, shader_atmosphere_density=preset.air.density*100, shader_atmosphere_haze=preset.air.haze*10, shader_atmosphere_color=preset.air.color,
		});
	end;

	ESP.ApplyShaderPreset = applyPreset;

	Sections.Shaders:AddLabel("Preset"):AddDropdown({
		Default = "Off",
		Values = { "Off", "Day", "Night", "Night2", "Sunset", "Noir", "Vibrant", "Dream", "Horror" },
		Flag = "shader_preset",
		Callback = function(v)
			if v == "Off" then
				ESP.ShaderLighting = nil;
				if ESP.ApplyLighting then ESP.ApplyLighting() end;
				syncShaderFlags({shader_bloom=false, shader_rays=false, shader_blur=false, shader_grade=false, shader_atmosphere=false});
				bloom.Enabled = false;
				rays.Enabled = false;
				blur.Enabled = false;
				grade.Enabled = false;
				AIR.On = false;

				applyAir();

				if ESP.ApplyGrade then pcall(ESP.ApplyGrade) end;

				return;
			end;

			applyPreset(v);
		end,
	});

	local SKYBOXES = {
		Jungle = {
			SkyboxBk = "rbxassetid://214399891", SkyboxDn = "rbxassetid://214399887",
			SkyboxFt = "rbxassetid://214399894", SkyboxLf = "rbxassetid://214405668",
			SkyboxRt = "rbxassetid://214399899", SkyboxUp = "rbxassetid://214399889",
		},
		Blossom = {
			SkyboxBk = "rbxassetid://271042516", SkyboxDn = "rbxassetid://271077243",
			SkyboxFt = "rbxassetid://271042556", SkyboxLf = "rbxassetid://271042310",
			SkyboxRt = "rbxassetid://271042467", SkyboxUp = "rbxassetid://271077958",
		},
		["Red Night"] = {
			SkyboxBk = "rbxassetid://401664839", SkyboxDn = "rbxassetid://401664862",
			SkyboxFt = "rbxassetid://401664960", SkyboxLf = "rbxassetid://401664881",
			SkyboxRt = "rbxassetid://401664901", SkyboxUp = "rbxassetid://401664936",
		},
		Purple = {
			SkyboxBk = "rbxassetid://13694952867", SkyboxDn = "rbxassetid://13694968325",
			SkyboxFt = "rbxassetid://13694980654", SkyboxLf = "rbxassetid://13694998113",
			SkyboxRt = "rbxassetid://13695002700", SkyboxUp = "rbxassetid://13695007103",
		},
	};

	local SKY_ASSETS = { Galaxy = 15983996673 };

	local SKY_ORDER = { "Off", "Jungle", "Blossom", "Red Night", "Purple", "Galaxy" };

	local SKY_FACES = { up = "SkyboxUp", dn = "SkyboxDn", lf = "SkyboxLf", rt = "SkyboxRt", ft = "SkyboxFt", bk = "SkyboxBk" };
	local function prettySkyName(value)
		local text = tostring(value or ""):gsub("[_%-]+", " "):gsub("(%l)(%u)", "%1 %2")
		text = text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
		return (text:gsub("(%a)([%w']*)", function(first, rest)
			return first:upper() .. rest:lower()
		end))
	end;

	local function resolveSky(entry)
		if entry.__ready then return entry.__ready end;

		local faces = {};

		for face, property in pairs(SKY_FACES) do
			local rel = entry.files[face];

			if not rel then return nil end;

			local url = Remote.asset(rel);

			if not url then return nil end;

			faces[property] = url;
		end;

		entry.__ready = faces;

		return faces;
	end;

	ESP.ResolveSky = resolveSky;

	if isfile and getcustomasset then
		local groups = {};

		for _, rel in ipairs(Remote.under("skyboxes/")) do
			local file = string.match(rel, "([^/]+)$");
			local name, face = string.match(file or "", "^(.+)_(%a%a)%.[jp][pn]g$");

			if name and SKY_FACES[face] then
				groups[name] = groups[name] or {};
				groups[name][face] = rel;
			end;
		end;

		local manifest = Remote.manifest or (Remote.base ~= "" and Remote.load()) or nil;

		if manifest and type(manifest.skyboxes) == "table" then
			for name, faces in pairs(manifest.skyboxes) do
				groups[name] = groups[name] or {};

				for _, face in ipairs(faces) do
					if SKY_FACES[face] and not groups[name][face] then
						groups[name][face] = "skyboxes/" .. name .. "_" .. face .. ".jpg";
					end;
				end;
			end;
		end;

		for name in pairs(groups) do
			if string.lower(name):match("cloudy") or string.lower(name):match("foggy") then
				groups[name] = nil;
			end;
		end;

		local names = {};
		for name in pairs(groups) do names[#names + 1] = name end;
		table.sort(names);

		for _, name in ipairs(names) do
			local complete = true;

			for face in pairs(SKY_FACES) do
				if not groups[name][face] then complete = false end;
			end;

			if complete then

				local pretty = prettySkyName(name);
				if SKYBOXES[pretty] or SKY_ASSETS[pretty] or pretty == "Off" then pretty = pretty .. " (Local)" end;
				if SKYBOXES[pretty] then pretty = pretty .. " [" .. name .. "]" end;

				SKYBOXES[pretty] = { __sky = name, files = groups[name] };
				SKY_ORDER[#SKY_ORDER + 1] = pretty;
			end;
		end;
	end;

	table.sort(SKY_ORDER, function(a, b)
		if a == "Off" then return b ~= "Off" end;
		if b == "Off" then return false end;
		return a:lower() < b:lower();
	end);

	local SK = { Box = "Off", Body = "Default", Size = 21, Stars = 3000 };

	local mapSky, mapSkyParent, ourSky;
	local skyGeneration=0;

	local originals={};
	local bodyProperties={"StarCount","CelestialBodiesShown","SunAngularSize","MoonAngularSize","SunTextureId","MoonTextureId"};
	local function rememberBody(sky)
		if not sky or originals[sky] then return end;
		local values={}; for _,property in ipairs(bodyProperties) do values[property]=sky[property] end;
		originals[sky]=values;
	end;
	local function restoreBody(sky)
		if sky and originals[sky] then
			for property,value in pairs(originals[sky]) do pcall(function() sky[property]=value end) end;
		end;
	end;
	local function forgetBody(sky)
		if sky then originals[sky]=nil end;
	end;

	local function detachMap()
		if mapSky then return end;

		local existing = Lighting:FindFirstChildOfClass("Sky");

		if existing and existing ~= ourSky then
			mapSky, mapSkyParent = existing, existing.Parent;
			pcall(function() existing.Parent = nil end);
		end;
	end;

	local function dropOurs()
		if ourSky then
			forgetBody(ourSky);
			pcall(function() ourSky:Destroy() end);
			ourSky = nil;
		end;
	end;

	local function restoreSky()
		skyGeneration=skyGeneration+1;
		for sky in pairs(originals) do restoreBody(sky) end;
		table.clear(originals);
		dropOurs();

		if mapSky then
			pcall(function() mapSky.Parent = mapSkyParent or Lighting end);
			mapSky, mapSkyParent = nil, nil;
		end;
	end;

	local bodySky;

	local function applyBody()
		local sky = ourSky or Lighting:FindFirstChildOfClass("Sky");

		if not sky and SK.Body ~= "Default" then
			sky = Instance.new("Sky");
			sky.Name = NeverLose.RandomString();
			sky.Parent = Lighting;
			bodySky = sky;
		end;

		if not sky then return end;

		if bodySky and sky == bodySky and SK.Body == "Default" then
			forgetBody(bodySky);
			pcall(function() bodySky:Destroy() end);

			bodySky = nil;

			return;
		end;

		rememberBody(sky); restoreBody(sky);

		sky.StarCount = SK.Stars;

		if SK.Body == "Default" then
			sky.CelestialBodiesShown = true;
			return;
		end;

		sky.CelestialBodiesShown = SK.Body ~= "None";

		if SK.Body == "Sun" then
			sky.SunAngularSize = SK.Size;
			sky.MoonAngularSize = 0;
		elseif SK.Body == "Moon" then
			sky.SunAngularSize = 0;
			sky.MoonAngularSize = SK.Size;
		elseif SK.Body == "Eclipse" then
			sky.SunTextureId = "rbxasset://sky/moon.jpg";
			sky.SunAngularSize = SK.Size;
			sky.MoonAngularSize = 0;
		else
			sky.SunAngularSize = 0;
			sky.MoonAngularSize = 0;
		end;
	end;

	onUnload("celestial", function()
		if bodySky then forgetBody(bodySky); pcall(function() bodySky:Destroy() end); bodySky = nil end;

		for sky in pairs(originals) do restoreBody(sky) end;

		table.clear(originals);
	end);

	local function applyFaces(faces)
		detachMap();
		dropOurs();

		local sky = Instance.new("Sky");
		sky.Name = NeverLose.RandomString();

		for property, value in pairs(faces) do
			pcall(function() sky[property] = value end);
		end;

		sky.Parent = Lighting;
		ourSky = sky;

		applyBody();
	end;

	local function applyAsset(id)
		local picked, epoch = SK.Box, skyGeneration;

		task.spawn(function()
			local ok, objects = Remote.objects(function() return game:GetObjects("rbxassetid://" .. id) end);
			if not ok or type(objects) ~= "table" then return end;

			local found;

			for _, object in ipairs(objects) do
				if object:IsA("Sky") then
					found = object;
					break;
				end;

				local nested = object:FindFirstChildWhichIsA("Sky", true);

				if nested then
					found = nested;
					break;
				end;
			end;

			if not found or not __ALIVE() or SK.Box ~= picked or skyGeneration ~= epoch then
				for _, object in ipairs(objects) do object:Destroy() end;
				return;
			end;

			detachMap();
			dropOurs();

			found.Name = NeverLose.RandomString();
			found.Parent = Lighting;
			ourSky = found;
			for _, object in ipairs(objects) do if object ~= found then object:Destroy() end end;
			applyBody();
		end);
	end;

	local function applySky()
		skyGeneration=skyGeneration+1;
		if SK.Box == "Off" then
			restoreSky();
			return;
		end;

		if SKYBOXES[SK.Box] then
			local entry = SKYBOXES[SK.Box];

			if entry.files then
				local picked = SK.Box;
				local generation = skyGeneration;

				task.spawn(function()
					local faces = resolveSky(entry);

					if faces and __ALIVE() and generation == skyGeneration and SK.Box == picked then applyFaces(faces) end;
				end);
			else
				applyFaces(entry);
			end;
		elseif SKY_ASSETS[SK.Box] then
			applyAsset(SKY_ASSETS[SK.Box]);
		end;
	end;

	ESP.Sky = SK;
	ESP.RestoreSky = restoreSky;

	Sections.Shaders:AddLabel("Skybox"):AddDropdown({
		Default = "Off",
		Values = SKY_ORDER,
		Flag = "sky_box",
		Callback = function(v) SK.Box = v; applySky() end,
	});

	local bodyRow = Sections.Shaders:AddLabel("Celestial");
	bodyRow:AddDropdown({
		Default = "Default",
		Values = { "Default", "Sun", "Moon", "Eclipse", "None" },
		Flag = "sky_body",
		Callback = function(v) SK.Body = v; applyBody() end,
	});

	local bodyOptions = bodyRow:AddOption(1);

	bodyOptions:AddLabel("Size"):AddSlider({
		Min = 0, Max = 60, Default = 21, Rounding = 0, Size = 90,
		Flag = "sky_size",
		Callback = function(v) SK.Size = v; applyBody() end,
	});

	bodyOptions:AddLabel("Stars"):AddSlider({
		Min = 0, Max = 12000, Default = 3000, Rounding = 0, Size = 90,
		Flag = "sky_stars",
		Callback = function(v) SK.Stars = v; applyBody() end,
	});

	local FOG = { On = false, Color = Color3.fromRGB(192, 192, 192), Density = 35, Offset = 0 };

	ESP.Fog = FOG;

	local function applyFog() applyAir() end;

	ESP.ApplyFog = applyFog;
	ESP.RestoreFog = function() FOG.On = false; applyAir() end;

	local elapsed = 0;

	NeverLose:AddSignal(RunService.Heartbeat:Connect(function(dt)
		elapsed = elapsed + dt;

		if elapsed < 1 or not __ALIVE() then return end;

		elapsed = 0;

		if not (FOG.On or AIR.On) then return end;

		local live = Lighting:FindFirstChildOfClass("Atmosphere");

		if not live then applyAir(); return end;

		local wantDensity = FOG.On and math.clamp(FOG.Density / 100, 0, 1) or AIR.Density;

		if math.abs(live.Density - wantDensity) > 0.01 then applyAir() end;
	end));

	local fogRow = Sections.Shaders:AddLabel("Fog");

	fogRow:AddToggle({
		Default = false, Flag = "fog",
		Callback = function(v) FOG.On = v; applyAir() end,
	});

	fogRow:AddColorPicker({
		Default = FOG.Color, Flag = "fog_color",
		Callback = function(v) FOG.Color = v; applyAir() end,
	});

	local fogOptions = fogRow:AddOption(1);

	fogOptions:AddLabel("Density"):AddSlider({
		Min = 0, Max = 100, Default = 35, Rounding = 0, Size = 90,
		Flag = "fog_density",
		Callback = function(v) FOG.Density = v; applyAir() end,
	});

	fogOptions:AddLabel("Height"):AddSlider({
		Min = -100, Max = 100, Default = 0, Rounding = 0, Size = 90,
		Flag = "fog_offset",
		Callback = function(v) FOG.Offset = v / 100; applyAir() end,
	});

	local bloomRow = Sections.Shaders:AddLabel("Bloom");
	bloomRow:AddToggle({ Default = false, Flag = "shader_bloom", Callback = function(v) bloom.Enabled = v end });

	local bloomOptions = bloomRow:AddOption(1);

	bloomOptions:AddLabel("Intensity"):AddSlider({
		Min = 0, Max = 200, Default = 60, Rounding = 0, Size = 90,
		Flag = "shader_bloom_intensity",
		Callback = function(v) bloom.Intensity = v / 100 end,
	});

	bloomOptions:AddLabel("Size"):AddSlider({
		Min = 1, Max = 56, Default = 24, Rounding = 0, Size = 90,
		Flag = "shader_bloom_size",
		Callback = function(v) bloom.Size = v end,
	});

	bloomOptions:AddLabel("Threshold"):AddSlider({
		Min = 0, Max = 200, Default = 90, Rounding = 0, Size = 90,
		Flag = "shader_bloom_threshold",
		Callback = function(v) bloom.Threshold = v / 100 end,
	});

	local raysRow = Sections.Shaders:AddLabel("Sun Rays");
	raysRow:AddToggle({ Default = false, Flag = "shader_rays", Callback = function(v) rays.Enabled = v end });
	raysRow:AddOption(1):AddLabel("Intensity"):AddSlider({
		Min = 0, Max = 100, Default = 15, Rounding = 0, Size = 90,
		Flag = "shader_rays_intensity",
		Callback = function(v) rays.Intensity = v / 100 end,
	});

	local blurRow = Sections.Shaders:AddLabel("Blur");
	blurRow:AddToggle({ Default = false, Flag = "shader_blur", Callback = function(v) blur.Enabled = v end });
	blurRow:AddSlider({
		Min = 1, Max = 40, Default = 8, Rounding = 0, Size = 90,
		Flag = "shader_blur_size",
		Callback = function(v) blur.Size = v end,
	});

	local GRADE = {
		On = false,
		Tint = Color3.fromRGB(255, 255, 255),
		Saturation = 0.2,
		Contrast = 0.1,
		Brightness = 0,
	};

	local function paintGrade()
		grade.Enabled = GRADE.On;
		grade.TintColor = GRADE.Tint;
		grade.Saturation = GRADE.Saturation;
		grade.Contrast = GRADE.Contrast;
		grade.Brightness = GRADE.Brightness;
	end;

	ESP.ApplyGrade = paintGrade;

	local gradeRow = Sections.Shaders:AddLabel("Color Grade");
	gradeRow:AddToggle({ Default = false, Flag = "shader_grade", Callback = function(v) GRADE.On = v; paintGrade() end });
	gradeRow:AddColorPicker({
		Default = Color3.fromRGB(255, 255, 255), Flag = "shader_grade_tint",
		Callback = function(v) GRADE.Tint = v; paintGrade() end,
	});

	local gradeOptions = gradeRow:AddOption(1);

	gradeOptions:AddLabel("Saturation"):AddSlider({
		Min = -100, Max = 200, Default = 20, Rounding = 0, Size = 90,
		Flag = "shader_grade_saturation",
		Callback = function(v) GRADE.Saturation = v / 100; paintGrade() end,
	});

	gradeOptions:AddLabel("Contrast"):AddSlider({
		Min = -100, Max = 200, Default = 10, Rounding = 0, Size = 90,
		Flag = "shader_grade_contrast",
		Callback = function(v) GRADE.Contrast = v / 100; paintGrade() end,
	});

	gradeOptions:AddLabel("Brightness"):AddSlider({
		Min = -100, Max = 100, Default = 0, Rounding = 0, Size = 90,
		Flag = "shader_grade_brightness",
		Callback = function(v) GRADE.Brightness = v / 100; paintGrade() end,
	});

	local airRow = Sections.Shaders:AddLabel("Atmosphere");
	airRow:AddToggle({
		Default = false, Flag = "shader_atmosphere",
		Callback = function(v)
			AIR.On = v;

			applyAir();
		end,
	});
	airRow:AddColorPicker({
		Default = Color3.fromRGB(199, 199, 199), Flag = "shader_atmosphere_color",
		Callback = function(v) AIR.Color = v; applyAir() end,
	});

	local airOptions = airRow:AddOption(1);

	airOptions:AddLabel("Density"):AddSlider({
		Min = 0, Max = 100, Default = 30, Rounding = 0, Size = 90,
		Flag = "shader_atmosphere_density",
		Callback = function(v) AIR.Density = v / 100; applyAir() end,
	});

	airOptions:AddLabel("Haze"):AddSlider({
		Min = 0, Max = 100, Default = 0, Rounding = 0, Size = 90,
		Flag = "shader_atmosphere_haze",
		Callback = function(v) AIR.Haze = v / 10; applyAir() end,
	});
end;
