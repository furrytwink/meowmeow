--!nonstrict
--[[
	camera.lua — extracted feature module (require id "modules.camera").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("camera") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("camera", function()
			return require("modules.camera")({ ESP = ESP, Render = Render, RunService = RunService, Sections = Sections, onUnload = onUnload, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local Render = ctx.Render;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local onUnload = ctx.onUnload;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("camera") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local lockedFov, holding = 70, false;
	local original = nil;
	local originalCamera;
	local function restoreFov()
		if originalCamera and original then pcall(function() originalCamera.FieldOfView = original end) end;
		original, originalCamera = nil, nil;
	end;
	local loop;
	local function updateFov()
		if not (__ALIVE() and holding and lockedFov) then return end;

		local camera = Render.camera();
		if camera and originalCamera ~= camera then restoreFov(); originalCamera, original = camera, camera.FieldOfView end;

		if camera and math.abs(camera.FieldOfView - lockedFov) > 0.01 then
			camera.FieldOfView = lockedFov;
		end;
	end;
	local function stopLoop()
		if loop then loop:Disconnect(); loop = nil end;
	end;

	local row = Sections.Camera:AddLabel("Field of View");

	row:AddToggle({
		Name = "Field of View",
		Default = false,
		Flag = "camera_fov",
		ToolTip = "Locks FOV",
		Callback = function(v)
			holding = v;

			local camera = Render.camera();

			if v then
				if camera and originalCamera ~= camera then restoreFov(); originalCamera, original = camera, camera.FieldOfView end;
				if not loop then loop = RunService.RenderStepped:Connect(updateFov) end;
				updateFov();
			else
				stopLoop();
				restoreFov();
			end;
		end,
	});

	row:AddSlider({
		Name = "Amount",
		Min = 40, Max = 120, Default = 70, Rounding = 0, Size = 110,
		Flag = "camera_fov_value",
		Callback = function(v) lockedFov = v end,
	});

	ESP.ClearCamera = onUnload("camera", function()
		holding = false;
		stopLoop();
		restoreFov();
	end);
end;
