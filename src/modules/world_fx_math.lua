--!nonstrict
--[[
	world_fx_math.lua — extracted feature module (require id "modules.world_fx_math").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("world_fx_math") in the driver — byte-frozen original
	code below the marker (re-derived on every `make extract`; do not hand-edit).

	The block originally closed over driver locals; the driver now passes them
	in via the ctx table:

		guard("world_fx_math", function()
			return require("modules.world_fx_math")({ ESP = ESP });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;

-- [ guard("world_fx_math") callback body — byte-exact from input/message(47).txt ]
	local F = {};
	function F.Number(v, fallback, lo, hi)
		v = tonumber(v);
		if not v or v ~= v or v == math.huge or v == -math.huge then v = fallback end;
		return math.clamp(v, lo, hi);
	end;
	function F.Smooth(t)
		t = math.clamp(t, 0, 1);
		return t * t * (3 - 2 * t);
	end;
	function F.Envelope(age, life, fadeIn, fadeOut)
		return F.Smooth(age / (life * fadeIn)) * F.Smooth((life - age) / (life * fadeOut));
	end;
	function F.Frame(position, tangent)
		local right = tangent.Magnitude > 0.0001 and tangent.Unit or Vector3.xAxis;
		local side = right:Cross(Vector3.yAxis);
		if side.Magnitude < 0.0001 then side = right:Cross(Vector3.xAxis) end;
		return CFrame.fromMatrix(position, right, side.Unit:Cross(right));
	end;
	function F.GlyphPath(style, distance, phase, bend)
		local q = distance / bend;
		if style == "Straight" then return Vector3.new(distance, 0, 0) end;
		if style == "Circuit" then
			local cell = bend / 8;
			local n = math.floor(distance / cell);
			local t, k = distance / cell - n, n % 6;
			local x, y, z = math.floor(n / 6) * 2, 0, 0;
			if k == 0 then x += t;
			elseif k == 1 then x += 1; y = t;
			elseif k == 2 then x += 1; y = 1; z = t;
			elseif k == 3 then x += 1 + t; y = 1; z = 1;
			elseif k == 4 then x += 2; y = 1 - t; z = 1;
			else x += 2; z = 1 - t end;
			return Vector3.new(x, y, phase > math.pi and -z or z) * cell;
		elseif style == "Zigzag" then
			local function triangle(v) return 1 - 4 * math.abs((v % 1) - 0.5) end;
			return Vector3.new(distance * 0.8, bend * 0.14 * (triangle(q * 0.8) - triangle(0)),
				bend * 0.2 * (triangle(q * 1.2 + phase) - triangle(phase)));
		elseif style == "Curve" then
			return Vector3.new(bend * math.sin(q), bend * 0.16 * math.sin(q * 0.6), bend * (1 - math.cos(q)));
		elseif style == "Helix" then
			return Vector3.new(distance * 0.72, bend * 0.24 * (math.cos(q * 1.8 + phase) - math.cos(phase)),
				bend * 0.24 * (math.sin(q * 1.8 + phase) - math.sin(phase)));
		elseif style == "Wave" then
			return Vector3.new(distance, bend * 0.3 * (math.sin(q * 1.8 + phase) - math.sin(phase)),
				bend * 0.15 * (math.sin(q * 0.9 + phase) - math.sin(phase)));
		elseif style == "Orbit" then
			return Vector3.new(bend * (math.sin(q + phase) - math.sin(phase)), bend * 0.12 * math.sin(q * 0.7),
				bend * (math.cos(q + phase) - math.cos(phase)));
		elseif style == "Ribbon" then
			return Vector3.new(distance * 0.7, bend * 0.24 * (math.sin(q * 1.4 + phase) - math.sin(phase)),
				bend * 0.3 * (math.sin(q * 2.8 + phase) - math.sin(phase)));
		end;
		return Vector3.new(distance * 0.85, bend * 0.13 * (math.sin(q * 0.7 + phase) - math.sin(phase)),
			bend * 0.22 * (math.sin(q * 1.1 + phase) - math.sin(phase)));
	end;
	function F.MeteorPoint(origin, velocity, travel)
		return origin + velocity * travel + Vector3.new(0, -1.8 * travel * travel, 0);
	end;
	function F.PixelWidth(camera, distance, pixels)
		local height = camera.ViewportSize and camera.ViewportSize.Y or 600;
		local fov = F.Number(camera.FieldOfView, 70, 1, 120);
		return 2 * math.max(0.1, distance) * math.tan(math.rad(fov) * 0.5)
			* math.max(0.1, pixels) / math.max(1, height);
	end;
	ESP.WorldFX = F;
end;
