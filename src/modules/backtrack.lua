--!nonstrict
--[[
	backtrack.lua — extracted feature module (require id "modules.backtrack").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("backtrack") in the driver — byte-frozen original
	code below the marker (re-derived on every `make extract`; do not hand-edit).

	The block originally closed over driver locals; the driver now passes them
	in via the ctx table:

		guard("backtrack", function()
			return require("modules.backtrack")({ ESP = ESP, Sections = Sections });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local Sections = ctx.Sections;

-- [ guard("backtrack") callback body — byte-exact from input/message(47).txt ]
	local BT = {
		On = false,
		Style = "ForceField",
		Delay = 120,
		Color = Color3.fromRGB(120, 200, 255),
		Transparency = 45,
		Target = "Other",
		Outline = Color3.fromRGB(255, 255, 255),
		OutlineTransparency = 10,
		OutlineOn = true,
	};

	BT.ChamsMaterial = BT.Style;
	BT.ChamsOutline = BT.Outline;
	BT.ChamsOutlineTransparency = BT.OutlineTransparency;

	ESP.Backtrack = BT;

	local order = ESP.MaterialOrder;

	if type(order) ~= "table" or #order == 0 then
		order = {};

		for name in pairs(ESP.MaterialStyles or {}) do order[#order + 1] = name end;

		table.sort(order);
	end;

	local row = Sections.Chams:AddLabel("Backtrack");
	row:AddToggle({
		Default = false, Flag = "backtrack",
		Callback = function(v)
			BT.On = v;

			if not v and ESP.ClearBacktrackChams then ESP.ClearBacktrackChams() end;
		end,
	});
	row:AddColorPicker({ Default = BT.Color, Flag = "backtrack_color", Callback = function(v) BT.Color = v end });

	local options = row:AddOption(1);

	options:AddLabel("Style"):AddDropdown({
		Default = "ForceField",
		Values = order,
		Flag = "backtrack_style",
		Callback = function(v)
			BT.Style, BT.ChamsMaterial = v, v;

			if ESP.ClearBacktrackChams then ESP.ClearBacktrackChams() end;
		end,
	});

	options:AddLabel("Target"):AddDropdown({
		Default = "Other", Values = { "Self", "Other", "All" }, Flag = "backtrack_target",
		Callback = function(v)
			BT.Target = v;

			if ESP.ClearBacktrackChams then ESP.ClearBacktrackChams() end;
		end,
	});

	options:AddLabel("Delay"):AddSlider({
		Min = 20, Max = 800, Default = 120, Type = "ms", Rounding = 0, Size = 90,
		Flag = "backtrack_delay",
		Callback = function(v) BT.Delay = v end,
	});

	options:AddLabel("Fade"):AddSlider({
		Min = 0, Max = 90, Default = 45, Type = "%", Size = 90,
		Flag = "backtrack_fade",
		Callback = function(v) BT.Transparency = v end,
	});

	local outlineRow = options:AddLabel("Outline");
	outlineRow:AddToggle({
		Default = true, Flag = "backtrack_outline_on",
		Callback = function(v) BT.OutlineOn = v end,
	});
	outlineRow:AddColorPicker({
		Default = BT.Outline, Flag = "backtrack_outline",
		Callback = function(v) BT.Outline, BT.ChamsOutline = v, v end,
	});

	options:AddLabel("Outline Opacity"):AddSlider({
		Min = 0, Max = 100, Default = 90, Type = "%", Size = 90,
		Flag = "backtrack_outline_opacity",
		Callback = function(v)
			BT.OutlineTransparency = 100 - v;
			BT.ChamsOutlineTransparency = BT.OutlineTransparency;
		end,
	});
end;
