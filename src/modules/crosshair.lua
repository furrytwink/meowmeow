--!nonstrict
--[[
	crosshair.lua — extracted feature module (require id "modules.crosshair").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("crosshair") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("crosshair", function()
			return require("modules.crosshair")({ ESP = ESP, GLOBAL = GLOBAL, LocalPlayer = LocalPlayer, NeverLose = NeverLose, RunService = RunService, Sections = Sections, destroyAny = destroyAny, onUnload = onUnload, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local GLOBAL = ctx.GLOBAL;
	local LocalPlayer = ctx.LocalPlayer;
	local NeverLose = ctx.NeverLose;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local destroyAny = ctx.destroyAny;
	local onUnload = ctx.onUnload;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("crosshair") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local UserInputService = game:GetService("UserInputService");
	local LP = LocalPlayer;

	local crosshair_lines = {};
	local crosshair_enabled = false;
	local crosshair_hidden_game_cursor = false;
	local original_cursor_icon = nil;
	local gun_equipped = false;
	local game_crosshair_gui = nil;
	local game_crosshair_hook_conn = nil;
	local mouse_icon_hook_active = false;

	local gap_size = 4;
	local line_length = 8;
	local line_thickness = 2;
	local line_color = Color3.fromRGB(255, 255, 255);
	local outline_color = Color3.fromRGB(0, 0, 0);
	local rotation_speed = 0;

	local current_rotation = 0;
	local crosshair_connection = nil;
	local gun_watch_connections = {};
	local containerConnections = {};
	local crosshair_angles = { 0, 0, 0, 0 };

	local function has_gun_equipped()
		local char = LP.Character;

		if char and char:FindFirstChild("Gun") then
			return true;
		end;

		return false;
	end;

	local function create_crosshair_lines()
		for i = 1, 8 do
			local line = Drawing.new("Line");

			line.Visible = false;
			line.Color = (i % 2 == 0) and outline_color or line_color;
			line.Thickness = (i % 2 == 0) and line_thickness + 2 or line_thickness;
			line.Transparency = 1;
			line.ZIndex = (i % 2 == 0) and 999 or 1000;

			crosshair_lines[i] = line;
		end;
	end;

	local function destroy_crosshair_lines()
		for i = 1, #crosshair_lines do
			if crosshair_lines[i] then
				destroyAny(crosshair_lines[i]);

				crosshair_lines[i] = nil;
			end;
		end;
	end;

	local function update_crosshair_visibility(show, equipped)
		if equipped == nil then
			equipped = has_gun_equipped();
		end;

		gun_equipped = equipped;

		local should_show = show and crosshair_enabled and gun_equipped;

		for i = 1, #crosshair_lines do
			if crosshair_lines[i] then
				crosshair_lines[i].Visible = should_show;
			end;
		end;
	end;

	local originalGui = setmetatable({}, {__mode="k"});
	local watchGeneration = 0;
	local function hide_game_crosshair_gui()
		if not (__ALIVE() and crosshair_enabled and crosshair_hidden_game_cursor and has_gun_equipped()) then return end;
		local pg=LP:FindFirstChild("PlayerGui");
		local topbar=pg and pg:FindFirstChild("GameTopbar");
		local gui=topbar and topbar:FindFirstChild("Crosshair");
		if gui and gui:IsA("GuiObject") then
			if originalGui[gui] == nil then originalGui[gui]=gui.Visible end;
			game_crosshair_gui=gui;
			gui.Visible=false;
		end;
	end;
	local function show_game_crosshair_gui()
		for gui,visible in pairs(originalGui) do
			if gui.Parent then gui.Visible=visible end;
			originalGui[gui]=nil;
		end;
		game_crosshair_gui=nil;
	end;
	local mouseRuntime = { Active = true, Block = false };
	GLOBAL.__VisualsCrosshairMouseRuntime = mouseRuntime;
	local function setup_mouse_icon_hook()
		mouse_icon_hook_active = true;
		mouseRuntime.Block = true;
		if type(GLOBAL.__VisualsCrosshairMouseHook) == "table" then return end;
		if type(hookmetamethod) ~= "function" or type(newcclosure) ~= "function" then return end;
		local old;
		old = hookmetamethod(game, "__newindex", newcclosure(function(self, property, value)
			local active = GLOBAL.__VisualsCrosshairMouseRuntime;
			if property == "Icon" and type(active) == "table" and active.Active and active.Block
				and (type(checkcaller) ~= "function" or checkcaller() == false)
				and typeof(self) == "Instance" and self:IsA("Mouse")
				and (value == "rbxassetid://79658449" or value == "") then return end;
			return old(self, property, value);
		end));
		GLOBAL.__VisualsCrosshairMouseHook = { Old = old };
	end;
	local function remove_mouse_icon_hook()
		mouse_icon_hook_active = false;
		mouseRuntime.Block = false;
	end;
	local function hide_game_cursor(hide)
		local mouse=LP:GetMouse();
		if __ALIVE() and crosshair_enabled and crosshair_hidden_game_cursor and hide and has_gun_equipped() then
			setup_mouse_icon_hook();
			if original_cursor_icon == nil then original_cursor_icon = mouse.Icon end;
			if mouse.Icon ~= "" then mouse.Icon="" end;
			hide_game_crosshair_gui();
		else
			remove_mouse_icon_hook();
			if original_cursor_icon ~= nil and not NeverLose.Lib.cursor then mouse.Icon = original_cursor_icon end;
			original_cursor_icon = nil;
			show_game_crosshair_gui();
		end;
	end;

	local function update_crosshair(dt)
		if not crosshair_enabled or #crosshair_lines == 0 then return end;

		local equipped = has_gun_equipped();

		gun_equipped = equipped;
		hide_game_cursor(equipped);

		if not equipped then
			update_crosshair_visibility(false, equipped);

			return;
		end;

		local mouse_pos = UserInputService:GetMouseLocation();
		local center_x = mouse_pos.X;
		local center_y = mouse_pos.Y;

		if rotation_speed > 0 then
			current_rotation = (current_rotation + dt * rotation_speed * 100) % 360;
		else
			current_rotation = 0;
		end;

		local rad = math.rad(current_rotation);
		local cos = math.cos;
		local sin = math.sin;
		local pi = math.pi;

		crosshair_angles[1] = rad;
		crosshair_angles[2] = pi / 2 + rad;
		crosshair_angles[3] = pi + rad;
		crosshair_angles[4] = 3 * pi / 2 + rad;

		for i = 1, 4 do
			local angle = crosshair_angles[i];
			local line_idx = (i - 1) * 2 + 1;
			local outline_idx = line_idx + 1;

			local start_x = center_x + gap_size * cos(angle);
			local start_y = center_y + gap_size * sin(angle);
			local end_x = center_x + (gap_size + line_length) * cos(angle);
			local end_y = center_y + (gap_size + line_length) * sin(angle);

			local outline_start_x = center_x + (gap_size - 1) * cos(angle);
			local outline_start_y = center_y + (gap_size - 1) * sin(angle);
			local outline_end_x = center_x + (gap_size + line_length + 1) * cos(angle);
			local outline_end_y = center_y + (gap_size + line_length + 1) * sin(angle);

			if crosshair_lines[line_idx] then
				crosshair_lines[line_idx].From = Vector2.new(start_x, start_y);
				crosshair_lines[line_idx].To = Vector2.new(end_x, end_y);
			end;

			if crosshair_lines[outline_idx] then
				crosshair_lines[outline_idx].From = Vector2.new(outline_start_x, outline_start_y);
				crosshair_lines[outline_idx].To = Vector2.new(outline_end_x, outline_end_y);
			end;
		end;

		update_crosshair_visibility(true, equipped);
	end;

	local function start_crosshair()
		if crosshair_connection then return end;
		watchGeneration += 1;
		local generation = watchGeneration;

		if #crosshair_lines == 0 then
			create_crosshair_lines();
		end;

		crosshair_connection = RunService.RenderStepped:Connect(update_crosshair);

		local function watch_gun(container, kind)
			if not __ALIVE() or not crosshair_enabled or generation ~= watchGeneration or not container then return end;
			local old = containerConnections[kind];
			if old and old.container == container then return end;
			if old then old.add:Disconnect(); old.remove:Disconnect() end;
			local function changed(child)
				if child.Name ~= "Gun" or not __ALIVE() or generation ~= watchGeneration then return end;
				local equipped = has_gun_equipped();
				update_crosshair_visibility(true, equipped);
				hide_game_cursor(equipped);
			end;
			containerConnections[kind] = { container = container,
				add = container.ChildAdded:Connect(changed), remove = container.ChildRemoved:Connect(changed) };
		end;

		if not game_crosshair_hook_conn then
			local pg = LP:FindFirstChild("PlayerGui");

			if pg then
				game_crosshair_hook_conn = pg.DescendantAdded:Connect(function(descendant)
					if descendant.Name == "Crosshair" and descendant.Parent and descendant.Parent.Name == "GameTopbar" then
						if __ALIVE() and crosshair_enabled and crosshair_hidden_game_cursor and descendant:IsA("GuiObject") then
							hide_game_crosshair_gui();
						end;
					end;
				end);
			end;
		end;

		local char = LP.Character;

		if char then
			watch_gun(char, "character");
		end;

		local backpack = LP:FindFirstChildOfClass("Backpack");

		if backpack then
			watch_gun(backpack, "backpack");
		end;

		local char_conn = LP.CharacterAdded:Connect(function(new_char)
			task.wait(0.3);
			if not __ALIVE() or not crosshair_enabled or generation ~= watchGeneration or LP.Character ~= new_char then return end;

			watch_gun(new_char, "character");
			watch_gun(LP:FindFirstChildOfClass("Backpack"), "backpack");

			gun_equipped = has_gun_equipped();

			update_crosshair_visibility(true, gun_equipped);
			hide_game_cursor(gun_equipped and crosshair_hidden_game_cursor);
		end);

		table.insert(gun_watch_connections, char_conn);
		table.insert(gun_watch_connections, LP.ChildAdded:Connect(function(child)
			if child:IsA("Backpack") then watch_gun(child, "backpack") end;
		end));

		gun_equipped = has_gun_equipped();

		update_crosshair_visibility(true, gun_equipped);
		hide_game_cursor(gun_equipped and crosshair_hidden_game_cursor);
	end;

	local function stop_crosshair()
		watchGeneration += 1;
		if crosshair_connection then
			pcall(function() crosshair_connection:Disconnect() end);

			crosshair_connection = nil;
		end;

		if game_crosshair_hook_conn then
			pcall(function() game_crosshair_hook_conn:Disconnect() end);

			game_crosshair_hook_conn = nil;
		end;

		for _, conn in ipairs(gun_watch_connections) do
			pcall(function() conn:Disconnect() end);
		end;

		gun_watch_connections = {};
		for kind, entry in pairs(containerConnections) do
			entry.add:Disconnect(); entry.remove:Disconnect(); containerConnections[kind] = nil;
		end;

		update_crosshair_visibility(false);
		hide_game_cursor(false);
		show_game_crosshair_gui();
		destroy_crosshair_lines();
	end;

	local row = Sections.Screen:AddLabel("Crosshair");
	local crosshair_toggle = row:AddToggle({
		Name = "crosshair",
		Default = false,
		Flag = "crosshair",
		Callback = function(v)
			crosshair_enabled = v;

			if v then
				start_crosshair();
			else
				stop_crosshair();
			end;
		end,
	});
	local options = row:AddOption(1);
	options:AddLabel("hide original"):AddToggle({
		Name = "hide original",
		Default = false,
		Flag = "crosshair_hide_original",
		Callback = function(v)
			crosshair_hidden_game_cursor = v;

			hide_game_cursor(v);
		end,
	});
	options:AddLabel("gap"):AddSlider({
		Min = 0, Max = 20, Default = 4, Rounding = 0, Size = 100,
		Flag = "crosshair_gap",
		Callback = function(v) gap_size = v end,
	});
	options:AddLabel("Line"):AddSlider({
		Min = 2, Max = 30, Default = 8, Rounding = 0, Size = 100,
		Flag = "crosshair_length",
		Callback = function(v) line_length = v end,
	});
	options:AddLabel("thickness"):AddSlider({
		Min = 1, Max = 5, Default = 2, Rounding = 0, Size = 100,
		Flag = "crosshair_thickness",
		Callback = function(v)
			line_thickness = v;

			for i = 1, #crosshair_lines do
				if crosshair_lines[i] then
					crosshair_lines[i].Thickness = (i % 2 == 0) and v + 2 or v;
				end;
			end;
		end,
	});
	options:AddLabel("rotation"):AddSlider({
		Min = 0, Max = 10, Default = 0, Rounding = 0, Size = 100,
		Flag = "crosshair_rotation",
		Callback = function(v) rotation_speed = v end,
	});
	options:AddLabel("Line"):AddColorPicker({
		Default = line_color,
		Flag = "crosshair_color",
		Callback = function(c)
			line_color = c;
			for i = 1, #crosshair_lines do
				if crosshair_lines[i] and i % 2 == 1 then crosshair_lines[i].Color = c end;
			end;
		end,
	});
	options:AddLabel("Outline"):AddColorPicker({
		Default = outline_color,
		Flag = "crosshair_outline_color",
		Callback = function(c)
			outline_color = c;

			for i = 1, #crosshair_lines do
				if crosshair_lines[i] and i % 2 == 0 then
					crosshair_lines[i].Color = c;
				end;
			end;
		end,
	});

	ESP.ClearCrosshair = onUnload("crosshair", function()
		crosshair_enabled = false;
		stop_crosshair();
		mouseRuntime.Active = false;
		if GLOBAL.__VisualsCrosshairMouseRuntime == mouseRuntime then GLOBAL.__VisualsCrosshairMouseRuntime = nil end;
	end);
end;
