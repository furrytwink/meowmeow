--!nonstrict
--[[
	cosmetics.lua — extracted feature module (require id "modules.cosmetics").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("cosmetics") in the driver — byte-frozen original
	code below the marker (re-derived on every `make extract`; do not hand-edit).

	The block originally closed over driver locals; the driver now passes them
	in via the ctx table:

		guard("cosmetics", function()
			return require("modules.cosmetics")({ ESP = ESP, Sections = Sections, Visuals = Visuals, onUnload = onUnload });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local Sections = ctx.Sections;
	local Visuals = ctx.Visuals;
	local onUnload = ctx.onUnload;

-- [ guard("cosmetics") callback body — byte-exact from input/message(47).txt ]
	local FX = ESP.GameFX;
	if not FX then return end;

	local C = {
		On = true, Picked = {}, Color = Color3.fromRGB(255, 255, 255),
		Opacity = 1, Glow = 1, Rate = 1, Size = 1, Speed = 1,
		X = 0, Y = 0, Z = 0, TransformScale = 1,
	};
	ESP.Cosmetics = C;

	local function wear()
		FX.SetGroup("cosmetic", C.On and C.Picked or {});
	end;

	local function tune()
		FX.Tune("cosmetic", {
			opacity = C.Opacity, glow = C.Glow, rate = C.Rate, size = C.Size, speed = C.Speed,
			x = C.X, y = C.Y, z = C.Z, scale = C.TransformScale,
		});
	end;

	local function rows()
		local out = {};
		for _, entry in ipairs(FX.Catalog) do
			if entry.kind == "Cosmetic" then
				out[#out + 1] = FX.Row(entry);
			end;
		end;
		return out;
	end;

	local grid = Visuals.Cosmetics:AddGallery({
		Name = "Cosmetics", Icon = "crown", Position = "left", Height = 440, Cell = 74, Wrap = true, Reset = true, Smooth = true,
		Thumb = "Asset", Blank = "crown", Empty = "No cosmetics", Values = rows(),
		Multi = true, Flag = "cosmetic_pick",
		Callback = function(v)
			local picked = {};
			for key, value in pairs(type(v) == "table" and v or {}) do
				local name = (type(key) == "string" and value) and key or value;
				if type(name) == "string" and FX.ById[name] then picked[#picked + 1] = name end;
			end;
			C.Picked = picked;
			wear();
		end,
	});
	FX.OnThumbs(function() grid:setdata(rows()) end);
	Visuals.Cosmetics.Signal:Connect(function(open) if open then FX.LoadThumbs() end end);

	local row = Sections.Cosmetics:AddLabel("Enabled");
	row:AddToggle({ Default = true, Flag = "cosmetic", Callback = function(v) C.On = v; wear() end });
	row:AddColorPicker({ Default = C.Color, Flag = "cosmetic_color", Callback = function(v) C.Color = v; tune() end });

	for _, setting in ipairs({
		{ "Opacity", "Opacity", "cosmetic_opacity", 0, 100, 100 },
		{ "Glow", "Glow", "cosmetic_glow", 0, 300, 100 },
		{ "Particle Rate", "Rate", "cosmetic_rate", 0, 300, 100 },
		{ "Particle Size", "Size", "cosmetic_size", 25, 300, 100 },
		{ "Speed", "Speed", "cosmetic_speed", 5, 300, 100 },
	}) do
		local key = setting[2];
		Sections.Cosmetics:AddLabel(setting[1]):AddSlider({
			Min = setting[4], Max = setting[5], Default = setting[6], Type = "%", Size = 100, Flag = setting[3],
			Callback = function(v) C[key] = v / 100; tune() end,
		});
	end;

	for _, axis in ipairs({ "X", "Y", "Z" }) do
		Sections.CosmeticsXYZ:AddLabel(axis):AddSlider({
			Min = -5, Max = 5, Default = 0, Rounding = 1, Size = 100,
			Flag = "cosmetic_xyz_" .. string.lower(axis),
			Callback = function(v) C[axis] = v; tune() end,
		});
	end;
	Sections.CosmeticsXYZ:AddLabel("Size"):AddSlider({
		Min = 25, Max = 250, Default = 100, Type = "%", Rounding = 0, Size = 100,
		Flag = "cosmetic_xyz_size",
		Callback = function(v) C.TransformScale = v / 100; tune() end,
	});

	Sections.Cosmetics:AddButton({ Name = "Unequip All", Icon = "x", Callback = function()
		pcall(function() grid:set({}) end);
	end });

	ESP.ClearCosmetics = onUnload("cosmetics", function()
		pcall(FX.SetGroup, "cosmetic", {});
	end);
end;
