--!nonstrict
--[[
	lighting.lua — extracted feature module (require id "modules.lighting").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("lighting") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("lighting", function()
			return require("modules.lighting")({ ESP = ESP, NeverLose = NeverLose, Sections = Sections, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local NeverLose = ctx.NeverLose;
	local Sections = ctx.Sections;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("lighting") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local Lighting = game:GetService("Lighting");

	local FB = { On = false };
	local TM = { On = false, Value = 12 };
	local AM = { On = false, Color = Color3.fromRGB(128,128,128) };
	local EX = { On = false, Value = 0 };
	local snapshots, written = {}, {};
	local function applyAll()
		local wanted = table.clone(ESP.ShaderLighting or {});
		if FB.On then
			wanted.Brightness, wanted.GlobalShadows = 2, false;
			wanted.OutdoorAmbient, wanted.ClockTime = Color3.fromRGB(128,128,128), 14;
		end;
		if AM.On then wanted.Ambient, wanted.OutdoorAmbient = AM.Color, AM.Color end;
		if TM.On then wanted.ClockTime = TM.Value end;
		if EX.On then wanted.ExposureCompensation = EX.Value end;
		for property, previous in pairs(written) do
			if wanted[property] == nil then
				if Lighting[property] == previous then Lighting[property] = snapshots[property] end;
				snapshots[property], written[property] = nil, nil;
			end;
		end;
		for property, value in pairs(wanted) do
			if written[property] == nil then snapshots[property] = Lighting[property]
			elseif Lighting[property] ~= written[property] then snapshots[property] = Lighting[property] end;
			if Lighting[property] ~= value then Lighting[property] = value end;
			written[property] = Lighting[property];
		end;
	end;
	local applyFullbright, applyAmbient, applyTime, applyExposure = applyAll, applyAll, applyAll, applyAll;
	ESP.RestoreLighting = function()
		ESP.ShaderLighting = nil;
		FB.On, TM.On, AM.On, EX.On = false, false, false, false;
		applyAll();
	end;

	ESP.Lighting = { FB = FB, Time = TM, Ambient = AM, Exposure = EX };
	ESP.ApplyLighting = applyAll;

	task.spawn(function()
		while __ALIVE() do
			task.wait(1);
			if not __ALIVE() then break end;

			if NeverLose.ScreenGui.Parent then
				if ESP.ShaderLighting or FB.On or TM.On or AM.On or EX.On then
					pcall(applyAll);
				end;
			end;
		end;
	end);

	local fullbrightRow = Sections.Lighting:AddLabel("Fullbright");
	fullbrightRow:AddToggle({
		Default = false, Flag = "fullbright",
		Callback = function(v) FB.On = v; applyFullbright() end,
	});

	local timeRow = Sections.Lighting:AddLabel("Time Change");
	timeRow:AddToggle({
		Default = false, Flag = "time_change",
		Callback = function(v) TM.On = v; applyTime() end,
	});

	timeRow:AddOption(1):AddLabel("Time"):AddSlider({
		Min = 0, Max = 24, Default = 12, Rounding = 1, Size = 90,
		Flag = "time_value",
		Callback = function(v) TM.Value = v; applyTime() end,
	});

	local ambientRow = Sections.Lighting:AddLabel("Ambient");
	ambientRow:AddToggle({
		Default = false, Flag = "ambient",
		Callback = function(v) AM.On = v; applyAmbient() end,
	});
	ambientRow:AddColorPicker({
		Default = AM.Color, Flag = "ambient_color",
		Callback = function(v) AM.Color = v; applyAmbient() end,
	});

	local exposureRow = Sections.Lighting:AddLabel("Exposure");
	exposureRow:AddToggle({
		Default = false, Flag = "exposure",
		Callback = function(v) EX.On = v; applyExposure() end,
	});

	exposureRow:AddOption(1):AddLabel("Value"):AddSlider({
		Min = -5, Max = 5, Default = 0, Rounding = 2, Size = 90,
		Flag = "exposure_value",
		Callback = function(v) EX.Value = v; applyExposure() end,
	});
end;
