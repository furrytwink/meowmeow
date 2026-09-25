--!nonstrict
--[[
	config.lua — extracted feature module (require id "modules.config").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("config") in the driver — byte-frozen original
	code below the marker (re-derived on every `make extract`; do not hand-edit).

	The block originally closed over driver locals; the driver now passes them
	in via the ctx table:

		guard("config", function()
			return require("modules.config")({ ESP = ESP, NeverLose = NeverLose, Window = Window, userFile = userFile });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local NeverLose = ctx.NeverLose;
	local Window = ctx.Window;
	local userFile = ctx.userFile;

-- [ guard("config") callback body — byte-exact from input/message(47).txt ]
	local lib = NeverLose.Lib;

	lib.dir = "Salad Visuals/Config";

	userFile("skin favourites.json");

	local SECRET = {
		spotify_code = true,
		spotify_client = true,
		soundcloud_client = true,
		vk_token = true,
	};
	lib.secrets = SECRET;
	lib.beforeConfigApply = function(data)
		local flags = data.flags;
		if ESP.CircleStyles and type(flags) == "table" then
			for _, id in ipairs({ "circle_style", "gun_circle_style" }) do
				local value = flags[id];
				if type(value) == "string" and ESP.CircleStyles.Aliases[value] then flags[id] = ESP.CircleStyles.Aliases[value] end;
			end;
		end;
		if ESP.SoundSettings and type(flags) == "table" and type(flags.killsound) == "string" then
			local selected, allowed = {}, {};
			for _, name in ipairs(ESP.SoundSettings.KillChoices or {}) do allowed[name] = true end;
			local legacy = flags.killsound;
			local function replacePlain(text, old, new)
				local first, last = string.find(text, old, 1, true);
				while first do
					text = string.sub(text, 1, first - 1) .. new .. string.sub(text, last + 1);
					first, last = string.find(text, old, first + #new, true);
				end;
				return text;
			end;
			for old, new in pairs({
				["Туда, бомжа!"] = "Туда бомжа!", ["Ой, а где ты?"] = "Ой а где ты?",
				["На колени, на колени!"] = "На колени! На колени!",
				["Ой, а мне его даже жалко"] = "Ой а мне его даже жалко",
				["Сосать, сосать"] = "Сосать! Сосать!",
			}) do legacy = replacePlain(legacy, old, new) end;
			for name in string.gmatch(legacy, "[^,]+") do
				name = string.match(name, "^%s*(.-)%s*$");
				name = ESP.SoundSettings.KillAliases[name] or name;
				if name ~= "Off" and allowed[name] then selected[#selected + 1] = name end;
			end;
			flags.killsound = table.concat(selected, ", ");
		end;
		if ESP.CharacterAccessories then
			ESP.CharacterAccessories.ImportConfig(data.flags.character_accessory_pick, data.flags.character_accessory_catalog);
		end;
	end;

	local store = lib.store;

	function lib:store(name)
		local saved = {};

		for id in pairs(SECRET) do
			local entry = lib.pool[id];

			if entry then
				saved[id] = entry.get;
				entry.get = function() return nil end;
			end;
		end;

		local ok, result = pcall(store, lib, name);

		for id, get in pairs(saved) do
			local entry = lib.pool[id];

			if entry then entry.get = get end;
		end;

		return ok and result or nil;
	end;

	Window:AddConfigCard();
end;
