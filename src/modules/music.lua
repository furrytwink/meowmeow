--!nonstrict
--[[
	music.lua — extracted feature module (require id "modules.music").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("music") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("music", function()
			return require("modules.music")({ ESP = ESP, GLOBAL = GLOBAL, NeverLose = NeverLose, Notification = Notification, Remote = Remote, Render = Render, RunService = RunService, Sections = Sections, http = http, onUnload = onUnload, userFile = userFile, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local GLOBAL = ctx.GLOBAL;
	local NeverLose = ctx.NeverLose;
	local Notification = ctx.Notification;
	local Remote = ctx.Remote;
	local Render = ctx.Render;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local http = ctx.http;
	local onUnload = ctx.onUnload;
	local userFile = ctx.userFile;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("music") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local HttpService = game:GetService("HttpService");
	local TweenService = game:GetService("TweenService");
	local UserInputService = game:GetService("UserInputService");

	local TH = NeverLose.Lib.theme;

	local CONFIG = userFile("spotify.json");
	local AUTH = "https://accounts.spotify.com/authorize";
	local TOKEN = "https://accounts.spotify.com/api/token";
	local API = "https://api.spotify.com/v1";
	local REDIRECT = "http://127.0.0.1:8888/callback";
	local SCOPES = "user-read-playback-state user-modify-playback-state user-read-currently-playing";

	local Playback = {
		title = "Nothing playing",
		artist = "",
		artwork = "",
		duration = 0,
		position = 0,
		playing = false,
		volume = 50,
		canSeek = false,
		canSkipNext = false,
		canSkipPrevious = false,
		shuffle = false,
		loop = false,
		status = "",
	};

	local HUD = {
		On = false,
		Layout = "Full",
		Artwork = true,
		Controls = true,
		Progress = true,
		Times = true,
		Visualizer = true,
		Opacity = 100,
		Scale = 100,
		Lyrics = false,
		LyricsSize = 150,
		LyricsSpot = "Bottom Left",
		LyricsX = 0,
		LyricsY = 0,
		LyricsPlaced = false,
		Spot = "Bottom Left",
		OffsetX = 0,
		OffsetY = 0,
		AccentColor = Color3.fromRGB(120, 200, 255),
		CoverSize = 52,
	};

	ESP.Music = { Playback = Playback, Hud = HUD };

	local requestFn = (syn and syn.request) or (http and http.request)
		or rawget(GLOBAL, "http_request") or rawget(GLOBAL, "request");

	local function httpJson(method, url, headers, body)
		if type(requestFn) ~= "function" then return nil, 0 end;

		local ok, res = Remote.invoke(function() return requestFn({
			Url = url,
			Method = method,
			Headers = headers,
			Body = body,
			Timeout = 12,
		}) end, 12);

		if not ok or type(res) ~= "table" then return nil, 0 end;

		local code = tonumber(res.StatusCode or res.Status or 0) or 0;

		if type(res.Body) ~= "string" or res.Body == "" then return nil, code, res end;

		local decoded;

		pcall(function() decoded = HttpService:JSONDecode(res.Body) end);

		return decoded, code, res;
	end;

	local function urlencode(value)
		return (string.gsub(tostring(value), "[^%w%-%._~]", function(c)
			return string.format("%%%02X", string.byte(c));
		end));
	end;

	local function form(pairsTable)
		local parts = {};

		for key, value in pairs(pairsTable) do
			parts[#parts + 1] = key .. "=" .. urlencode(value);
		end;

		return table.concat(parts, "&");
	end;

	local SAFE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~";

	local function verifier()
		local out = {};

		for index = 1, 64 do
			local pick = math.random(1, #SAFE);

			out[index] = string.sub(SAFE, pick, pick);
		end;

		return table.concat(out);
	end;

	local function challengeFor(text)
		local crypt = rawget(GLOBAL, "crypt");

		if not (crypt and crypt.hash and crypt.base64encode) then return nil end;

		local ok, hex = pcall(crypt.hash, text, "sha256");
		if not ok or type(hex) ~= "string" or #hex ~= 64 or hex:find("[^%x]") then return nil end;

		local raw = (string.gsub(hex, "%x%x", function(byte)
			return string.char(tonumber(byte, 16));
		end));

		local fine, encoded = pcall(crypt.base64encode, raw);
		if not fine or type(encoded) ~= "string" then return nil end;

		encoded = string.gsub(encoded, "%+", "-");
		encoded = string.gsub(encoded, "/", "_");
		encoded = string.gsub(encoded, "=", "");

		return encoded;
	end;

	local covers, coverBusy, coverRetryAfter = {}, {}, {};

	local function coverFor(url)
		if type(url) ~= "string" or url == "" then return "" end;
		if not string.find(url, "^https?://") then return url end;

		local hit = covers[url];

		if hit then return hit end;
		if coverBusy[url] or (coverRetryAfter[url] or 0) > os.clock() then return "" end;

		coverBusy[url] = true;

		task.spawn(function()
			local ok, asset = pcall(function()
				local body = Remote.download(url);
				if type(body) ~= "string" or #body < 32 or #body > 8 * 1024 * 1024 then return nil end;
				local image = body:sub(1, 8) == "\137PNG\13\10\26\10" or body:sub(1, 3) == "\255\216\255"
					or body:sub(1, 3) == "GIF" or (body:sub(1, 4) == "RIFF" and body:sub(9, 12) == "WEBP");
				if not image then return nil end;
				return Remote.volatile("external-cover/" .. Remote.slug(url) .. ".png", body);
			end);
			if Remote.current() and ok and type(asset) == "string" and asset ~= "" then covers[url] = asset
			else coverRetryAfter[url] = os.clock() + 15 end;
			coverBusy[url] = nil;
		end);

		return "";
	end;

	local LocalProvider = { name = "Local" };

	do
		local sound = Instance.new("Sound");
		sound:SetAttribute("VisualsOwned", true);
		sound.Name = NeverLose.RandomString();
		sound.Volume = 0.5;
		sound.Looped = false;
		sound.Parent = NeverLose.ScreenGui;

		local queue, cursor = {}, 0;
		local cover = "";

		LocalProvider.sound = sound;

		local function load(index)
			if #queue == 0 then return end;

			cursor = ((index - 1) % #queue) + 1;

			local entry = queue[cursor];

			sound.SoundId = "rbxassetid://" .. tostring(entry.id);
			sound.TimePosition = 0;
			sound:Play();
		end;

		function LocalProvider.add(text)
			local raw = tostring(text or "");
			local id = string.match(raw, "(%d+)");

			if not id then return false end;

			local rest = string.match(raw, "^%s*%d+%s*(.-)%s*$") or "";
			local artist, title = string.match(rest, "^(.-)%s*%-%s*(.+)$");

			queue[#queue + 1] = {
				id = id,
				title = title or (rest ~= "" and rest) or ("Track " .. id),
				artist = title and artist or nil,
			};

			if #queue == 1 then load(1) end;

			return true;
		end;

		function LocalProvider.clear()
			sound:Stop();

			table.clear(queue);

			cursor = 0;
		end;

		function LocalProvider.dump()
			local out = {};

			for _, entry in ipairs(queue) do
				out[#out + 1] = entry.id .. (entry.artist and (" " .. entry.artist .. " - " .. entry.title)
					or (entry.title and (" " .. entry.title) or ""));
			end;

			return out;
		end;

		function LocalProvider.restore(list)
			if type(list) ~= "table" then return end;

			LocalProvider.clear();

			for _, text in ipairs(list) do
				if type(text) == "string" then LocalProvider.add(text) end;
			end;

			sound:Stop();
			sound.TimePosition = 0;
		end;

		function LocalProvider.setCover(url) cover = url or "" end;

		function LocalProvider.play() if sound.SoundId ~= "" then sound:Resume() end end;
		function LocalProvider.pause() sound:Pause() end;
		function LocalProvider.stop() sound:Stop(); sound.TimePosition = 0 end;
		function LocalProvider.replay() sound.TimePosition = 0; sound:Play() end;
		function LocalProvider.next() if #queue > 0 then load(cursor + 1) end end;
		function LocalProvider.previous() if #queue > 0 then load(cursor - 1) end end;
		function LocalProvider.setLoop(v) sound.Looped = v and true or false end;
		function LocalProvider.setVolume(v) sound.Volume = math.clamp(v, 0, 100) / 100 end;
		function LocalProvider.seek(fraction)
			if sound.TimeLength > 0 then sound.TimePosition = sound.TimeLength * math.clamp(fraction, 0, 1) end;
		end;

		function LocalProvider.read(into)
			local entry = queue[cursor];

			into.title = entry and entry.title or "No track queued";
			into.artist = (entry and entry.artist)
				or ((#queue > 0) and (cursor .. " / " .. #queue) or "");
			into.album = "";
			into.artwork = cover;
			into.duration = sound.TimeLength or 0;
			into.position = sound.TimePosition or 0;
			into.playing = sound.IsPlaying;
			into.volume = math.floor(sound.Volume * 100 + 0.5);
			into.canSeek = sound.TimeLength > 0;
			into.canSkipNext = #queue > 1;
			into.canSkipPrevious = #queue > 1;
			into.loop = sound.Looped;
			into.status = "";
		end;

		onUnload("music local", function()
			pcall(function() sound:Stop() end);
			pcall(function() sound:Destroy() end);
		end);
	end;

	local Spotify = { name = "Spotify", connected = false };

	do
		local clientId = "";
		local refreshToken = "";
		local pendingVerifier = nil;
		local access, expires = "", 0;
		local backoffUntil = 0;

		local function save()
			if not writefile then return end;

			pcall(function()
				writefile(CONFIG, HttpService:JSONEncode({
					clientId = clientId,
					refreshToken = refreshToken,
					verifier = pendingVerifier or "",
				}));
			end);
		end;

		local function load()
			if not (isfile and readfile and isfile(CONFIG)) then return end;

			pcall(function()
				local blob = HttpService:JSONDecode(readfile(CONFIG));

				clientId = blob.clientId or "";
				refreshToken = blob.refreshToken or "";
				pendingVerifier = (blob.verifier ~= "" and blob.verifier) or nil;
			end);
		end;

		load();

		function Spotify.setClientId(value)
			clientId = tostring(value or ""):gsub("%s", "");

			save();
		end;

		function Spotify.hasClientId() return clientId ~= "" end;

		local function refresh()
			if clientId == "" or refreshToken == "" then return false end;

			local body, code = httpJson("POST", TOKEN,
				{ ["Content-Type"] = "application/x-www-form-urlencoded" },
				form({
					grant_type = "refresh_token",
					refresh_token = refreshToken,
					client_id = clientId,
				}));

			if code == 200 and body and body.access_token then
				access = body.access_token;
				expires = os.clock() + (tonumber(body.expires_in) or 3600) - 60;

				if body.refresh_token then refreshToken = body.refresh_token; save() end;

				Spotify.connected = true;

				return true;
			end;

			if code == 400 or code == 401 then
				refreshToken = "";
				Spotify.connected = false;

				save();
			end;

			return false;
		end;

		local function token()
			if access ~= "" and os.clock() < expires then return access end;

			return refresh() and access or nil;
		end;

		function Spotify.begin()
			if clientId == "" then
				Notification.new({ Title = "Spotify", Content = "Set a Client ID first", Duration = 6 });

				return;
			end;

			pendingVerifier = verifier();

			save();

			local challenge = challengeFor(pendingVerifier);

			if not challenge then
				Notification.new({ Title = "Spotify", Content = "Executor has no sha256", Duration = 6 });

				return;
			end;

			local url = AUTH .. "?" .. form({
				client_id = clientId,
				response_type = "code",
				redirect_uri = REDIRECT,
				code_challenge_method = "S256",
				code_challenge = challenge,
				scope = SCOPES,
			});

			pcall(setclipboard, url);

			Notification.new({
				Title = "Spotify",
				Content = "Link copied",
				Duration = 10,
			});
		end;

		function Spotify.finish(code)
			local text = tostring(code or "");

			local value = string.match(text, "code=([^&%s]+)") or string.match(text, "^%s*(%S+)%s*$");

			if not value then
				Spotify.lastError = "No code found";

				Notification.new({ Title = "Spotify", Content = Spotify.lastError, Duration = 6 });

				return;
			end;

			if not pendingVerifier then
				Spotify.lastError = "Press Connect first";

				Notification.new({ Title = "Spotify", Content = Spotify.lastError, Duration = 7 });

				return;
			end;

			local body, status = httpJson("POST", TOKEN,
				{ ["Content-Type"] = "application/x-www-form-urlencoded" },
				form({
					grant_type = "authorization_code",
					code = value,
					redirect_uri = REDIRECT,
					client_id = clientId,
					code_verifier = pendingVerifier,
				}));

			pendingVerifier = nil;

			save();

			if status == 200 and body and body.access_token then
				access = body.access_token;
				expires = os.clock() + (tonumber(body.expires_in) or 3600) - 60;
				refreshToken = body.refresh_token or "";
				Spotify.connected = true;

				save();

				Notification.new({ Title = "Spotify", Content = "Connected", Duration = 5 });
			else
				Spotify.connected = false;
				Spotify.lastError = ("http %s: %s"):format(
					tostring(status),
					(body and (body.error_description or body.error)) or "No response"
				);

				Notification.new({
					Title = "Spotify",
					Content = Spotify.lastError,
					Duration = 8,
				});
			end;
		end;

		function Spotify.disconnect()
			access, refreshToken, expires = "", "", 0;
			Spotify.connected = false;

			save();
		end;

		local function call(method, path, body)
			local key = token();

			if not key then return nil, 401 end;

			local headers = { ["Authorization"] = "Bearer " .. key };

			if body then headers["Content-Type"] = "application/json" end;

			return httpJson(method, API .. path, headers, body);
		end;

		Spotify.call = call;

		function Spotify.play() call("PUT", "/me/player/play") end;
		function Spotify.pause() call("PUT", "/me/player/pause") end;
		function Spotify.next() call("POST", "/me/player/next") end;
		function Spotify.previous() call("POST", "/me/player/previous") end;
		function Spotify.setVolume(v) call("PUT", "/me/player/volume?volume_percent=" .. math.floor(math.clamp(v, 0, 100))) end;
		function Spotify.seek(fraction)
			if Playback.duration <= 0 then return end;

			call("PUT", "/me/player/seek?position_ms=" .. math.floor(Playback.duration * math.clamp(fraction, 0, 1) * 1000));
		end;
		function Spotify.stop() Spotify.pause() end;
		function Spotify.replay() Spotify.seek(0) end;
		function Spotify.setLoop(v) call("PUT", "/me/player/repeat?state=" .. (v and "track" or "off")) end;

		function Spotify.refreshState(into)
			if clientId == "" then
				into.status = "No Client ID";
				into.title = "Spotify not set up";
				into.artist = "";
				into.playing = false;

				return;
			end;

			if refreshToken == "" and access == "" then
				into.status = "not connected";
				into.title = "Spotify not connected";
				into.artist = "";
				into.playing = false;

				return;
			end;

			if os.clock() < backoffUntil then return end;

			local body, code, raw = call("GET", "/me/player");

			if code == 204 then
				into.status = "No active device";
				into.title = "Nothing playing";
				into.artist = "open Spotify on any device";
				into.artwork = "";
				into.playing = false;
				into.duration, into.position = 0, 0;

				return;
			end;

			if code == 429 then
				local wait = 5;

				if raw and raw.Headers then
					wait = tonumber(raw.Headers["retry-after"] or raw.Headers["Retry-After"]) or 5;
				end;

				backoffUntil = os.clock() + wait;
				into.status = "rate limited";

				return;
			end;

			if code == 401 then
				if refresh() then return end;

				into.status = "session expired";
				into.playing = false;

				return;
			end;

			if code == 403 then
				local reason = raw and type(raw.Body) == "string" and raw.Body or "";

				if string.find(reason, "premium", 1, true) or string.find(reason, "Premium", 1, true) then
					into.status = "needs Spotify Premium on the app owner";
					into.title = "Spotify unavailable";
				elseif reason ~= "" then
					into.status = string.sub(reason, 1, 90);
					into.title = "Spotify unavailable";
				else
					into.status = "private session";
				end;

				into.artist = "";
				into.artwork = "";
				into.playing = false;
				into.duration, into.position = 0, 0;

				return;
			end;

			if not body or type(body.item) ~= "table" then
				into.title, into.artist, into.album, into.artwork = "Nothing playing", "", "", "";
				into.duration, into.position = 0, 0;
				into.canSeek, into.canSkipNext, into.canSkipPrevious, into.loop, into.shuffle = false, false, false, false, false;
				into.status = (code == 200) and "Nothing playing" or ("http " .. tostring(code));
				into.playing = body and body.is_playing or false;

				return;
			end;

			local item = body.item;
			local artists = {};

			for _, artist in ipairs(item.artists or {}) do artists[#artists + 1] = artist.name end;

			local art = "";

			if item.album and type(item.album.images) == "table" then

				local best;

				for _, image in ipairs(item.album.images) do
					if not best or (image.width and image.width >= 160 and image.width < (best.width or 1e9)) then
						best = image;
					end;
				end;

				art = (best and best.url) or (item.album.images[1] and item.album.images[1].url) or "";
			end;

			into.trackId = item.id;
			into.album = (item.album and item.album.name) or "";
			into.title = item.name or "Unknown";
			into.artist = table.concat(artists, ", ");
			into.artwork = art;
			into.duration = (tonumber(item.duration_ms) or 0) / 1000;
			into.position = (tonumber(body.progress_ms) or 0) / 1000;
			into.playing = body.is_playing and true or false;
			into.shuffle = body.shuffle_state and true or false;
			into.loop = (body.repeat_state or "off") ~= "off";
			into.canSeek = true;
			into.canSkipNext = true;
			into.canSkipPrevious = true;
			into.status = "";

			if body.device and body.device.volume_percent then
				into.volume = body.device.volume_percent;
			end;
		end;
	end;

	local audioCache = {};
	local audioBytes = 0;

	local function cacheAudio(url)
		if type(url) ~= "string" or url == "" then return nil, "no url" end;

		if audioCache[url] then return audioCache[url] end;

		if type(writefile) ~= "function" or type(Remote.custom) ~= "function" then
			return nil, "executor cannot write files";
		end;

		local stamp;

		pcall(function()
			local hasher = rawget(GLOBAL, "crypt");

			stamp = (hasher and hasher.hash) and string.sub(hasher.hash(url, "sha256"), 1, 24) or nil;
		end);

		stamp = stamp or Remote.slug(url);

		local kind = string.match(string.lower(url):match("^[^?#]+") or "", "%.(%a+)$") or "mp3";

		if kind ~= "mp3" and kind ~= "ogg" and kind ~= "wav" then kind = "mp3" end;

		if not url:match("^https?://") then return nil, "unsupported audio URL" end;
		local bytes = Remote.download(url);
		if type(bytes) ~= "string" or #bytes <= 4096 then return nil, "download failed" end;
		local header = bytes:sub(1, 12);
		local first, second = bytes:byte(1, 2);
		local audio = header:sub(1, 4) == "OggS" or (header:sub(1, 4) == "RIFF" and header:sub(9, 12) == "WAVE")
			or header:sub(1, 3) == "ID3" or (first == 255 and second and bit32.band(second, 224) == 224);
		if not Remote.current() or not audio or #bytes > 32 * 1024 * 1024 then return nil, "invalid audio response" end;
		if audioBytes + #bytes > 128 * 1024 * 1024 then return nil, "audio cache limit reached" end;
		local asset = Remote.volatile("external-audio/" .. stamp .. "." .. kind, bytes);
		if type(asset) ~= "string" or asset == "" then return nil, "asset failed" end;
		audioBytes += #bytes;

		audioCache[url] = asset;

		return asset;
	end;

	local function streamProvider(name, resolve)
		local P = { name = name };
		local active, selected, epoch, sequence = true, false, 0, 0;

		local sound = Instance.new("Sound");
		sound:SetAttribute("VisualsOwned", true);
		sound.Name = NeverLose.RandomString();
		sound.Volume = 0.5;
		sound.Looped = false;
		sound.Parent = NeverLose.ScreenGui;

		local queue, cursor, note = {}, 0, "";

		P.sound = sound;

		local function load(index, revision)
			if #queue == 0 or not __ALIVE() or not active or not selected or (revision and revision ~= epoch) then return end;
			sequence += 1;
			local mine, revision = sequence, epoch;

			cursor = ((index - 1) % #queue) + 1;

			local entry = queue[cursor];

			if not entry.asset then
				note = "loading " .. tostring(entry.title);

				local asset, why = cacheAudio(entry.url);
				if not __ALIVE() or not active or not selected or epoch ~= revision or sequence ~= mine or not sound.Parent then return end;

				if not asset then
					note = tostring(why);

					return;
				end;

				entry.asset = asset;
			end;

			note = "";
			sound.SoundId = entry.asset;
			sound.TimePosition = 0;
			sound:Play();
		end;

		function P.add(text)
			local revision = epoch;
			task.spawn(function()
				if not __ALIVE() or not active or revision ~= epoch then return end;
				note = "resolving...";

				local ok, track, why = pcall(resolve, text);
				if not __ALIVE() or not active or revision ~= epoch then return end;

				if not ok then
					note = tostring(track);

					return;
				end;

				if not track then
					note = tostring(why or "Nothing found");

					return;
				end;

				local list = track.tracks or { track };

				for _, one in ipairs(list) do
					if type(one.url) == "string" and one.url ~= "" then
						queue[#queue + 1] = {
							title = one.title or "Unknown",
							artist = one.artist or "",
							artwork = one.artwork or "",
							duration = tonumber(one.duration) or 0,
							url = one.url,
						};
					end;
				end;

				note = "";

				if cursor == 0 and #queue > 0 then load(1) end;
			end);

			return true;
		end;

		function P.clear()
			epoch += 1; sequence += 1;
			sound:Stop();
			sound.SoundId = "";
			table.clear(queue);
			cursor, note = 0, "";
		end;

		function P.activate() selected = true end;
		function P.play() if selected and sound.SoundId ~= "" then sound:Resume() elseif selected and #queue > 0 then task.spawn(load, math.max(1, cursor), epoch) end end;
		function P.pause() sound:Pause() end;
		function P.stop() epoch += 1; sequence += 1; sound:Stop(); sound.TimePosition = 0 end;
		function P.deactivate() selected = false; epoch += 1; sequence += 1; sound:Pause() end;
		function P.replay() if selected then sound.TimePosition = 0; sound:Play() end end;
		function P.next() if selected and #queue > 0 then task.spawn(load, cursor + 1, epoch) end end;
		function P.previous() if selected and #queue > 0 then task.spawn(load, cursor - 1, epoch) end end;
		function P.setLoop(v) sound.Looped = v and true or false end;
		function P.setVolume(v) sound.Volume = math.clamp(v, 0, 100) / 100 end;

		function P.seek(fraction)
			if sound.TimeLength > 0 then
				sound.TimePosition = sound.TimeLength * math.clamp(fraction, 0, 1);
			end;
		end;

		function P.read(into)
			local entry = queue[cursor];

			into.title = entry and entry.title or (name .. ": nothing queued");
			into.artist = entry and entry.artist or "";
			into.album = "";
			into.artwork = entry and coverFor(entry.artwork) or "";
			into.duration = (sound.TimeLength > 0) and sound.TimeLength or (entry and entry.duration or 0);
			into.position = sound.TimePosition or 0;
			into.playing = sound.IsPlaying;
			into.volume = math.floor(sound.Volume * 100 + 0.5);
			into.canSeek = sound.TimeLength > 0;
			into.canSkipNext = #queue > 1;
			into.canSkipPrevious = #queue > 1;
			into.loop = sound.Looped;
			into.status = note;
		end;

		onUnload("music " .. string.lower(name), function()
			active = false; epoch += 1; sequence += 1; table.clear(queue);
			pcall(function() sound:Stop() end);
			pcall(function() sound:Destroy() end);
		end);

		return P;
	end;

	local SC = { Client = "" };

	local function soundcloudResolve(text)
		local raw = string.match(tostring(text or ""), "^%s*(.-)%s*$");

		if raw == "" then return nil, "paste a soundcloud link" end;

		if string.find(string.lower(raw), "%.mp3") or string.find(string.lower(raw), "%.ogg") then
			return { title = string.match(raw, "([^/]+)%.%a+") or "Track", artist = "", url = raw };
		end;

		if SC.Client == "" then return nil, "set a client id first" end;

		local data, code = httpJson("GET", ("https://api-v2.soundcloud.com/resolve?url=%s&client_id=%s")
			:format(urlencode(raw), urlencode(SC.Client)));

		if code == 401 or code == 403 then return nil, "client id rejected" end;
		if type(data) ~= "table" then return nil, "resolve failed (" .. tostring(code) .. ")" end;

		local items = data.tracks or { data };
		local out = {};

		for _, item in ipairs(items) do
			if type(item) == "table" and type(item.media) == "table" then
				local stream;

				for _, t in ipairs(item.media.transcodings or {}) do
					if type(t) == "table" and type(t.format) == "table"
						and t.format.protocol == "progressive" then
						stream = t.url;
					end;
				end;

				if stream then
					local hand, leadCode = httpJson("GET", stream .. "?client_id=" .. urlencode(SC.Client));

					if type(hand) == "table" and type(hand.url) == "string" then
						out[#out + 1] = {
							title = item.title or "Track",
							artist = (type(item.user) == "table" and item.user.username) or "",
							artwork = item.artwork_url or "",
							duration = (tonumber(item.duration) or 0) / 1000,
							url = hand.url,
						};
					elseif leadCode == 401 or leadCode == 403 then
						return nil, "client id rejected";
					end;
				end;
			end;
		end;

		if #out == 0 then return nil, "No playable stream" end;

		return { tracks = out };
	end;

	local VK = { Token = "" };

	local function vkResolve(text)
		local raw = string.match(tostring(text or ""), "^%s*(.-)%s*$");

		if string.find(string.lower(raw), "%.mp3") or string.find(string.lower(raw), "%.m4a") then
			return { title = string.match(raw, "([^/]+)%.%a+") or "Track", artist = "", url = raw };
		end;

		if VK.Token == "" then return nil, "set a vk token first" end;

		local owner, count = string.match(raw, "^(-?%d+)"), 25;
		local url = ("https://api.vk.com/method/audio.get?v=5.131&count=%d&access_token=%s")
			:format(count, urlencode(VK.Token));

		if owner then url = url .. "&owner_id=" .. owner end;

		local data, code = httpJson("GET", url);

		if type(data) ~= "table" then return nil, "vk unreachable (" .. tostring(code) .. ")" end;

		if type(data.error) == "table" then
			return nil, "vk: " .. tostring(data.error.error_msg or data.error.error_code);
		end;

		local items = (type(data.response) == "table" and data.response.items) or {};
		local out = {};

		for _, item in ipairs(items) do

			if type(item) == "table" and type(item.url) == "string" and item.url ~= ""
				and not string.find(item.url, "%.m3u8") then
				out[#out + 1] = {
					title = item.title or "Track",
					artist = item.artist or "",
					duration = tonumber(item.duration) or 0,
					url = item.url,
				};
			end;
		end;

		if #out == 0 then return nil, "No direct file" end;

		return { tracks = out };
	end;

	local SoundCloud = streamProvider("SoundCloud", soundcloudResolve);
	local Vk = streamProvider("VK", vkResolve);

	ESP.Music.SoundCloud = SoundCloud;
	ESP.Music.Vk = Vk;

	local providers = { Local = LocalProvider, Spotify = Spotify, SoundCloud = SoundCloud, VK = Vk };
	local current = "Local";
	local providerEpoch = 0;
	local musicSettings = {volume=50, loop=false};

	ESP.Music.Providers = providers;
	ESP.Music.Local = LocalProvider;
	ESP.Music.Spotify = Spotify;

	local function provider() return providers[current] or LocalProvider end;

	local function command(name, ...)
		local p = provider();
		local fn = p[name];

		if type(fn) == "function" then pcall(fn, ...) end;
	end;

	local gui = Render.gui("music", 40);

	local panel = Instance.new("Frame");
	panel.Name = "NowPlaying";
	panel.BackgroundColor3 = TH.panel;
	panel.BorderSizePixel = 0;
	panel.Size = UDim2.fromOffset(304, 96);
	panel.Visible = false;
	panel.Parent = gui;

	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 7);

	pcall(function()
		local shade = Instance.new("UIShadow");
		shade.Color = TH.bg;
		shade.BlurRadius = UDim.new(0, 9);
		shade.Parent = panel;
	end);

	local edge = Instance.new("UIStroke", panel);
	edge.Color = TH.line;
	edge.Transparency = 0.45;
	edge.Thickness = 1;

	local scale = Instance.new("UIScale", panel);

	local art = Instance.new("ImageLabel");
	art.Name = "Art";
	art.BackgroundColor3 = TH.head;
	art.BorderSizePixel = 0;
	art.Position = UDim2.fromOffset(11, 11);
	art.Size = UDim2.fromOffset(56, 56);
	art.ScaleType = Enum.ScaleType.Crop;
	art.Parent = panel;

	Instance.new("UICorner", art).CornerRadius = UDim.new(0, 6);

	local artEdge = Instance.new("UIStroke", art);
	artEdge.Color = TH.line;
	artEdge.Transparency = 0.6;

	local artMark = Instance.new("ImageLabel");
	artMark.Name = "ArtMark";
	artMark.BackgroundTransparency = 1;
	artMark.AnchorPoint = Vector2.new(0.5, 0.5);
	artMark.Position = UDim2.fromScale(0.5, 0.5);
	artMark.Size = UDim2.fromScale(0.42, 0.42);
	artMark.ScaleType = Enum.ScaleType.Fit;
	artMark.ImageColor3 = TH.dim;
	artMark.ImageTransparency = 0.25;
	artMark.Image = "rbxassetid://" .. tostring(NeverLose.Lib.icons["volume-2"] or 0);
	artMark.Parent = art;

	local artOld = art:Clone();
	artOld.Name = "ArtOld";
	artOld.ImageTransparency = 1;
	artOld.BackgroundTransparency = 1;
	artOld.Parent = panel;

	local staleMark = artOld:FindFirstChild("ArtMark");

	if staleMark then staleMark:Destroy() end;

	local source = Instance.new("TextLabel");
	source.Name = "Source";
	source.BackgroundTransparency = 1;
	source.Position = UDim2.fromOffset(78, 9);
	source.Size = UDim2.new(1, -90, 0, 11);
	source.FontFace = NeverLose.BuiltInBold;
	source.TextSize = 9;
	source.TextColor3 = HUD.AccentColor;
	source.TextXAlignment = Enum.TextXAlignment.Left;
	source.TextTruncate = Enum.TextTruncate.AtEnd;
	source.Text = "LOCAL";
	source.Parent = panel;

	local title = Instance.new("TextLabel");
	title.Name = "Title";
	title.BackgroundTransparency = 1;
	title.Position = UDim2.fromOffset(78, 22);
	title.Size = UDim2.new(1, -88, 0, 17);
	title.FontFace = NeverLose.BuiltInBold;
	title.TextSize = 13;
	title.TextColor3 = TH.text;
	title.TextXAlignment = Enum.TextXAlignment.Left;
	title.TextTruncate = Enum.TextTruncate.AtEnd;
	title.Text = "Nothing playing";
	title.ClipsDescendants = true;
	title.Parent = panel;

	local artist = Instance.new("TextLabel");
	artist.Name = "Artist";
	artist.BackgroundTransparency = 1;
	artist.Position = UDim2.fromOffset(78, 39);
	artist.Size = UDim2.new(1, -88, 0, 14);
	artist.FontFace = NeverLose.BuiltInRegular;
	artist.TextSize = 11;
	artist.TextColor3 = TH.dim;
	artist.TextXAlignment = Enum.TextXAlignment.Left;
	artist.TextTruncate = Enum.TextTruncate.AtEnd;
	artist.Text = "";
	artist.Parent = panel;

	local track = Instance.new("Frame");
	track.Name = "Track";
	track.BackgroundColor3 = TH.head;
	track.BorderSizePixel = 0;
	track.Position = UDim2.fromOffset(78, 61);
	track.Size = UDim2.new(1, -90, 0, 3);
	track.Parent = panel;

	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0);

	local fill = Instance.new("Frame");
	fill.Name = "Fill";
	fill.BackgroundColor3 = HUD.AccentColor;
	fill.BorderSizePixel = 0;
	fill.Size = UDim2.fromScale(0, 1);
	fill.Parent = track;

	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0);

	local knob = Instance.new("Frame");
	knob.Name = "Knob";
	knob.AnchorPoint = Vector2.new(0.5, 0.5);
	knob.Position = UDim2.new(1, 0, 0.5, 0);
	knob.Size = UDim2.fromOffset(8, 8);
	knob.BorderSizePixel = 0;
	knob.ZIndex = 3;
	knob.Parent = fill;

	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0);

	local seekHit = Instance.new("TextButton");
	seekHit.Name = "Seek";
	seekHit.BackgroundTransparency = 1;
	seekHit.Text = "";
	seekHit.Position = UDim2.fromOffset(0, -6);
	seekHit.Size = UDim2.new(1, 0, 0, 15);
	seekHit.Parent = track;

	local clock = Instance.new("TextLabel");
	clock.Name = "Clock";
	clock.BackgroundTransparency = 1;
	clock.Position = UDim2.fromOffset(78, 69);
	clock.Size = UDim2.fromOffset(58, 12);
	clock.FontFace = NeverLose.BuiltInRegular;
	clock.TextSize = 10;
	clock.TextColor3 = TH.dim;
	clock.TextXAlignment = Enum.TextXAlignment.Left;
	clock.Text = "0:00";
	clock.Parent = panel;

	local totalClock = clock:Clone();
	totalClock.Name = "Duration";
	totalClock.AnchorPoint = Vector2.new(1, 0);
	totalClock.Position = UDim2.new(1, -12, 0, 69);
	totalClock.TextXAlignment = Enum.TextXAlignment.Right;
	totalClock.Text = "0:00";
	totalClock.Parent = panel;

	local GLYPH = {};

	for _, name in ipairs({ "play", "pause", "next", "prev", "stop" }) do
		GLYPH[name] = Remote.asset("images/ui_" .. name .. ".png");
	end;

	local controls = Instance.new("Frame");
	controls.Name = "Controls";
	controls.BackgroundTransparency = 1;
	controls.AnchorPoint = Vector2.new(1, 0);
	controls.Position = UDim2.new(1, -10, 0, 68);
	controls.Size = UDim2.fromOffset(84, 24);
	controls.Parent = panel;

	local IDLE, HOVER, DOWN, OFF = 0.28, 0, 0.1, 0.72;

	local function transport(name, x, size)
		local holder = Instance.new("ImageButton");
		holder.Name = name;
		holder.BackgroundColor3 = TH.glow;
		holder.BackgroundTransparency = 1;
		holder.BorderSizePixel = 0;
		holder.AutoButtonColor = false;
		holder.Image = "";
		holder.Position = UDim2.fromOffset(x, 0);
		holder.Size = UDim2.fromOffset(size, 24);
		holder.Parent = controls;

		Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6);

		local glyph = Instance.new("ImageLabel");
		glyph.Name = "Glyph";
		glyph.BackgroundTransparency = 1;
		glyph.AnchorPoint = Vector2.new(0.5, 0.5);
		glyph.Position = UDim2.fromScale(0.5, 0.5);
		glyph.Size = UDim2.fromOffset(size - 10, size - 10);
		glyph.ScaleType = Enum.ScaleType.Fit;
		glyph.ImageColor3 = TH.text;
		glyph.ImageTransparency = IDLE;
		glyph.Parent = holder;

		local pulse = Instance.new("UIScale", holder);

		local item = { button = holder, glyph = glyph, enabled = true, hovered = false };

		local function repaint()
			local target = IDLE;

			if not item.enabled then
				target = OFF;
			elseif item.down then
				target = DOWN;
			elseif item.hovered then
				target = HOVER;
			end;

			TweenService:Create(glyph, TweenInfo.new(0.12), { ImageTransparency = target }):Play();
			TweenService:Create(holder, TweenInfo.new(0.12), {
				BackgroundTransparency = (item.enabled and item.hovered) and 0.9 or 1,
			}):Play();
			TweenService:Create(pulse, TweenInfo.new(0.09), { Scale = item.down and 0.88 or 1 }):Play();
		end;

		holder.MouseEnter:Connect(function() item.hovered = true; repaint() end);
		holder.MouseLeave:Connect(function() item.hovered, item.down = false, false; repaint() end);
		holder.MouseButton1Down:Connect(function() item.down = true; repaint() end);
		holder.MouseButton1Up:Connect(function() item.down = false; repaint() end);

		function item.setEnabled(on)
			if item.enabled == on then return end;

			item.enabled = on;

			repaint();
		end;

		function item.setGlyph(key)
			glyph.Image = GLYPH[key] or "";
		end;

		item.repaint = repaint;

		return item;
	end;

	local prevBtn = transport("Prev", 0, 24);
	local playBtn = transport("Play", 30, 26);
	local nextBtn = transport("Next", 60, 24);

	prevBtn.setGlyph("prev");
	playBtn.setGlyph("play");
	nextBtn.setGlyph("next");

	local bars = {};

	for index = 1, 4 do
		local b = Instance.new("Frame");
		b.Name = "Bar" .. index;
		b.BackgroundColor3 = HUD.AccentColor;
		b.BorderSizePixel = 0;
		b.AnchorPoint = Vector2.new(0, 1);
		b.Position = UDim2.fromOffset(9 + (index - 1) * 5, 61);
		b.Size = UDim2.fromOffset(3, 4);
		b.Visible = false;
		b.Parent = panel;

		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 1);

		bars[index] = b;
	end;

	local SPOTS = {
		["Top Left"] = Vector2.new(0, 0),
		["Top Right"] = Vector2.new(1, 0),
		["Bottom Left"] = Vector2.new(0, 1),
		["Bottom Right"] = Vector2.new(1, 1),
	};

	local PAD = 16;

	local function place()
		local anchor = SPOTS[HUD.Spot] or SPOTS["Bottom Left"];

		local camera = workspace.CurrentCamera;
		if not camera then return end;
		local screen = camera.ViewportSize;
		local size = panel.AbsoluteSize;

		local function limit(side, offset, extent, span)
			if extent <= 1 or span <= extent then return offset end;

			local base = (side == 0) and PAD or (span - PAD - extent);

			return math.clamp(offset, -base, span - extent - base);
		end;

		HUD.OffsetX = limit(anchor.X, HUD.OffsetX, size.X, screen.X);
		HUD.OffsetY = limit(anchor.Y, HUD.OffsetY, size.Y, screen.Y);

		panel.AnchorPoint = anchor;
		panel.Position = UDim2.new(
			anchor.X,
			(anchor.X == 0 and PAD or -PAD) + HUD.OffsetX,
			anchor.Y,
			(anchor.Y == 0 and PAD or -PAD) + HUD.OffsetY
		);
	end;

	local dragging, dragFrom, dragBase = false, nil, nil;

	local placeLyrics;

	local function pushOffsets()
		for flag, value in pairs({ music_x = HUD.OffsetX, music_y = HUD.OffsetY }) do
			local item = NeverLose.Flags[flag];

			if item and item.SetValue then pcall(item.SetValue, item, value) end;
		end;

		local spot = NeverLose.Flags.music_spot;

		if spot and spot.SetValue then pcall(spot.SetValue, spot, HUD.Spot) end;
	end;

	local GuiService = game:GetService("GuiService");

	local function screenAt(object)
		return object.AbsolutePosition + GuiService:GetGuiInset();
	end;

	local function snapCorner()
		local screen = NeverLose.ScreenGui.AbsoluteSize;

		if screen.X < 8 or screen.Y < 8 then return end;

		local center = screenAt(panel) + panel.AbsoluteSize * 0.5;
		local right = center.X > screen.X * 0.5;
		local bottom = center.Y > screen.Y * 0.5;

		HUD.Spot = (bottom and "Bottom " or "Top ") .. (right and "Right" or "Left");

		local anchor = SPOTS[HUD.Spot];
		local at = screenAt(panel) + panel.AbsoluteSize * Vector2.new(anchor.X, anchor.Y);
		local corner = Vector2.new(anchor.X * screen.X, anchor.Y * screen.Y);
		local base = Vector2.new(anchor.X == 0 and PAD or -PAD, anchor.Y == 0 and PAD or -PAD);

		local reachX = math.max(0, screen.X - panel.AbsoluteSize.X);
		local reachY = math.max(0, screen.Y - panel.AbsoluteSize.Y);

		HUD.OffsetX = math.clamp(math.floor(at.X - corner.X - base.X + 0.5), -reachX, reachX);
		HUD.OffsetY = math.clamp(math.floor(at.Y - corner.Y - base.Y + 0.5), -reachY, reachY);
	end;

	panel.Active = true;

	panel.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return;
		end;

		dragging = true;
		dragFrom = input.Position;
		dragBase = Vector2.new(HUD.OffsetX, HUD.OffsetY);
	end);

	NeverLose:AddSignal(UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end;

		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return;
		end;

		local delta = input.Position - dragFrom;

		HUD.OffsetX = dragBase.X + delta.X;
		HUD.OffsetY = dragBase.Y + delta.Y;

		place();

		local screen = NeverLose.ScreenGui.AbsoluteSize;
		local at = screenAt(panel);
		local size = panel.AbsoluteSize;
		local pushX = math.clamp(at.X, 0, math.max(0, screen.X - size.X)) - at.X;
		local pushY = math.clamp(at.Y, 0, math.max(0, screen.Y - size.Y)) - at.Y;

		if pushX ~= 0 or pushY ~= 0 then
			HUD.OffsetX = HUD.OffsetX + pushX;
			HUD.OffsetY = HUD.OffsetY + pushY;

			place();
		end;
	end));

	NeverLose:AddSignal(UserInputService.InputEnded:Connect(function(input)
		if not dragging then return end;

		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return;
		end;

		dragging = false;

		snapCorner();
		place();
		placeLyrics();
		pushOffsets();
	end));

	local function accent()
		return NeverLose.AccentColor or HUD.AccentColor;
	end;

	local function clockText(seconds)
		seconds = math.max(0, math.floor(seconds or 0));

		return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60);
	end;

	local function relayout()
		local compact = HUD.Layout == "Compact";
		local coverOn = HUD.Artwork;
		local size = compact and math.floor(HUD.CoverSize * 0.58) or HUD.CoverSize;
		local pad = compact and 9 or 12;
		local left = coverOn and (size + pad + 12) or 16;

		art.Visible = coverOn;
		artOld.Visible = coverOn;
		art.Position = UDim2.fromOffset(pad, pad);
		artOld.Position = art.Position;
		art.Size = UDim2.fromOffset(size, size);
		artOld.Size = art.Size;

		local height = compact and math.max(62, size + pad * 2) or math.max(96, size + 24);

		panel.Size = UDim2.fromOffset(compact and 268 or 304, height);

		local stacked = HUD.Progress or HUD.Times;
		local top = compact and math.floor((height - 31) / 2) or (stacked and 22 or math.floor((height - 32) / 2));
		source.Visible = not compact;
		source.Position = UDim2.fromOffset(left, 9);
		source.Size = UDim2.new(1, -left - 12, 0, 11);

		local reserve = compact and 38 or 14;

		title.Position = UDim2.fromOffset(left, top);
		title.Size = UDim2.new(1, -left - reserve, 0, 17);

		artist.Position = UDim2.fromOffset(left, top + 17);
		artist.Size = UDim2.new(1, -left - reserve, 0, 14);
		artist.Visible = true;

		track.Position = UDim2.fromOffset(left, height - 35);
		track.Size = UDim2.new(1, -left - 12, 0, 3);
		track.Visible = HUD.Progress and not compact;

		clock.Position = UDim2.fromOffset(left, height - 26);
		clock.Size = UDim2.fromOffset(42, 12);
		clock.Visible = HUD.Times and not compact;
		totalClock.Visible = HUD.Times and not compact;
		if HUD.Controls then
			totalClock.AnchorPoint = Vector2.zero;
			totalClock.Position = UDim2.fromOffset(left + 46, height - 26);
			totalClock.Size = UDim2.fromOffset(42, 12);
		else
			totalClock.AnchorPoint = Vector2.new(1, 0);
			totalClock.Position = UDim2.new(1, -12, 0, height - 26);
			totalClock.Size = UDim2.fromOffset(52, 12);
		end;

		controls.Visible = HUD.Controls;
		controls.Position = compact and UDim2.new(1, -9, 0.5, -12) or UDim2.new(1, -10, 0, height - 31);
		controls.Size = UDim2.fromOffset(compact and 26 or 84, 24);

		prevBtn.button.Visible = not compact;
		nextBtn.button.Visible = not compact;
		playBtn.button.Position = UDim2.fromOffset(compact and 0 or 30, 0);

		local barsOn = HUD.Visualizer and not compact and not HUD.Progress;

		for index, b in ipairs(bars) do
			b.Visible = barsOn;
			b.Position = UDim2.fromOffset(left + (index - 1) * 6, height - 14);
		end;

		scale.Scale = HUD.Scale / 100;

		local clear = 1 - HUD.Opacity / 100;

		panel.BackgroundTransparency = clear * 0.88 + 0.04;
		edge.Transparency = 0.35 + clear * 0.6;

		place();
		placeLyrics();
	end;

	local LYRICS = "https://lrclib.net/api/get";

	local lyricPanel = Instance.new("Frame");
	lyricPanel.Name = "Lyrics";
	lyricPanel.BackgroundColor3 = TH.panel;
	lyricPanel.BorderSizePixel = 0;
	lyricPanel.Size = UDim2.fromOffset(304, 150);
	lyricPanel.Visible = false;
	lyricPanel.ClipsDescendants = true;
	lyricPanel.Parent = gui;

	Instance.new("UICorner", lyricPanel).CornerRadius = UDim.new(0, 7);

	pcall(function()
		local shade = Instance.new("UIShadow");
		shade.Color = TH.bg;
		shade.BlurRadius = UDim.new(0, 9);
		shade.Parent = lyricPanel;
	end);

	local lyricEdge = Instance.new("UIStroke", lyricPanel);
	lyricEdge.Color = TH.line;
	lyricEdge.Transparency = 0.45;

	local lyricScale = Instance.new("UIScale", lyricPanel);

	local lyricHead = Instance.new("TextLabel");
	lyricHead.Name = "Head";
	lyricHead.BackgroundTransparency = 1;
	lyricHead.Position = UDim2.fromOffset(16, 9);
	lyricHead.Size = UDim2.fromOffset(72, 14);
	lyricHead.FontFace = NeverLose.BuiltInBold;
	lyricHead.TextSize = 11;
	lyricHead.TextColor3 = TH.dim;
	lyricHead.TextXAlignment = Enum.TextXAlignment.Left;
	lyricHead.TextTruncate = Enum.TextTruncate.AtEnd;
	lyricHead.Text = "LYRICS";
	lyricHead.Parent = lyricPanel;

	local lyricTrack = Instance.new("TextLabel");
	lyricTrack.Name = "Track";
	lyricTrack.BackgroundTransparency = 1;
	lyricTrack.Position = UDim2.fromOffset(88, 9);
	lyricTrack.Size = UDim2.new(1, -104, 0, 14);
	lyricTrack.FontFace = NeverLose.BuiltInRegular;
	lyricTrack.TextSize = 10;
	lyricTrack.TextColor3 = TH.dim;
	lyricTrack.TextXAlignment = Enum.TextXAlignment.Right;
	lyricTrack.TextTruncate = Enum.TextTruncate.AtEnd;
	lyricTrack.Text = "";
	lyricTrack.Parent = lyricPanel;

	local lyricView = Instance.new("Frame");
	lyricView.Name = "View";
	lyricView.BackgroundTransparency = 1;
	lyricView.ClipsDescendants = true;
	lyricView.Position = UDim2.fromOffset(16, 30);
	lyricView.Size = UDim2.new(1, -32, 1, -41);
	lyricView.Parent = lyricPanel;

	local lyricRoll = Instance.new("Frame");
	lyricRoll.Name = "Roll";
	lyricRoll.BackgroundTransparency = 1;
	lyricRoll.Size = UDim2.new(1, 0, 1, 0);
	lyricRoll.Parent = lyricView;

	local lyricFade = Instance.new("UIGradient", lyricView);
	lyricFade.Rotation = 90;
	lyricFade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.22, 0),
		NumberSequenceKeypoint.new(0.78, 0),
		NumberSequenceKeypoint.new(1, 1),
	});

	local LINE_H = 20;
	local lyricRows = {};
	local lyricShow = 0;

	local function lyricRow(index)
		local row = lyricRows[index];

		if row then return row end;

		row = Instance.new("TextLabel");
		row.Name = "Line" .. index;
		row.BackgroundTransparency = 1;
		row.Size = UDim2.new(1, 0, 0, LINE_H);
		row.FontFace = NeverLose.BuiltInRegular;
		row.TextSize = 12;
		row.TextColor3 = TH.dim;
		row.TextXAlignment = Enum.TextXAlignment.Left;
		row.TextTruncate = Enum.TextTruncate.AtEnd;
		row.Text = "";
		row.Parent = lyricRoll;

		lyricRows[index] = row;

		return row;
	end;

	local lyricState = {
		key = nil,
		lines = {},
		synced = false,
		status = "",
		busy = false,
		offset = 0,
	};
	local function resetLyrics(status)
		lyricState.key = nil;
		lyricState.lines = {};
		lyricState.synced = false;
		lyricState.busy = false;
		lyricState.status = status or "";
		lyricState.offset = 0;
		lyricShow = 0;
		lyricPanel.Visible = false;
		lyricTrack.Text = "";
		for _, row in pairs(lyricRows) do row.Text = "" end;
	end;

	local function parseSynced(text)
		local lines = {};

		for stamp, body in string.gmatch(text, "%[(%d+:%d+%.?%d*)%]([^\n]*)") do
			local m, sec = string.match(stamp, "(%d+):([%d%.]+)");

			if m then
				local at = tonumber(m) * 60 + (tonumber(sec) or 0);
				local clean = string.match(body, "^%s*(.-)%s*$");

				lines[#lines + 1] = { at = at, text = clean };
			end;
		end;

		return lines;
	end;

	local function parsePlain(text)
		local lines = {};

		for body in string.gmatch(text .. "\n", "([^\n]*)\n") do
			lines[#lines + 1] = { at = nil, text = body };
		end;

		return lines;
	end;

	local function lyricName(value)
		local text = string.lower(tostring(value or ""));
		text = string.gsub(text, "%b()", "");
		text = string.gsub(text, "%b[]", "");
		return string.gsub(text, "[%c%p%s]+", "");
	end;

	local function lyricNameMatches(expected, actual)
		local a, b = lyricName(expected), lyricName(actual);
		if a == "" or b == "" then return false end;
		if a == b then return true end;
		local short, long = (#a < #b) and a or b, (#a < #b) and b or a;
		return #short >= 5 and string.find(long, short, 1, true) ~= nil;
	end;

	local function matchingLyrics(results, title, artist)
		if type(results) ~= "table" then return nil end;
		for _, result in ipairs(results) do
			if type(result) == "table" and lyricNameMatches(title, result.trackName)
				and (artist == "" or lyricNameMatches(artist, result.artistName)) then
				return result;
			end;
		end;
	end;

	local function fetchLyrics(title, artist, album, duration)
		local query = LYRICS .. "?" .. form({
			track_name = title,
			artist_name = artist,
			album_name = album or "",
			duration = math.floor(duration or 0),
		});

		local body, code = httpJson("GET", query, { ["Accept"] = "application/json" });

		if code ~= 200 or type(body) ~= "table"
			or (body.trackName and not lyricNameMatches(title, body.trackName))
			or (artist ~= "" and body.artistName and not lyricNameMatches(artist, body.artistName)) then
			local hits = httpJson("GET", "https://lrclib.net/api/search?" .. form({ track_name = title, artist_name = artist }),
				{ ["Accept"] = "application/json" });

			body = matchingLyrics(hits, title, artist);
		end;

		if type(body) ~= "table" then
			return {}, false, "No lyrics";
		end;

		local lines, synced = {}, false;
		if type(body.syncedLyrics) == "string" and body.syncedLyrics ~= "" then
			lines = parseSynced(body.syncedLyrics);
			synced = #lines > 0;
		end;

		if not synced then
			local plain = body.plainLyrics;

			lines = (type(plain) == "string" and plain ~= "") and parsePlain(plain) or {};
		end;

		return lines, synced, (#lines == 0) and "No lyrics" or "";
	end;

	local function wantLyrics()
		if not (HUD.On and HUD.Lyrics) then return end;

		local title = Playback.title or "";
		local artist = Playback.artist or "";

		if title == "" then return end;

		local blocked = {
			["Loading..."] = true,
			["Nothing playing"] = true,
			["No track queued"] = true,
			["Spotify unavailable"] = true,
			["Spotify not connected"] = true,
			["Spotify not set up"] = true,
		};

		if blocked[title] then
			resetLyrics("Nothing playing");

			return;
		end;

		local key = title .. "|" .. artist;

		if lyricState.key == key then return end;

		resetLyrics("searching...");
		lyricState.key = key;
		lyricState.busy = true;

		task.spawn(function()
			local mine = key;
			local ok, lines, synced, status = pcall(fetchLyrics, title, artist, Playback.album, Playback.duration);
			if lyricState.key ~= mine then return end;
			lyricState.busy = false;
			if ok then
				lyricState.lines = lines;
				lyricState.synced = synced;
				lyricState.status = status;
			else
				lyricState.lines = {};
				lyricState.synced = false;
				lyricState.status = "Lyrics unavailable";
			end;
		end);
	end;

	function placeLyrics()

		if not HUD.LyricsPlaced then
			local anchor = SPOTS[HUD.Spot] or SPOTS["Bottom Left"];
			local gapY = (panel.Size.Y.Offset + 8) * (HUD.Scale / 100);

			HUD.LyricsSpot = HUD.Spot;
			HUD.LyricsX = HUD.OffsetX;
			HUD.LyricsY = HUD.OffsetY + (anchor.Y == 1 and -gapY or gapY);
			HUD.LyricsPlaced = true;

			for flag, value in pairs({ music_lyrics_x = HUD.LyricsX, music_lyrics_y = HUD.LyricsY }) do
				local item = NeverLose.Flags[flag];

				if item and item.SetValue then pcall(item.SetValue, item, value) end;
			end;

			local spot = NeverLose.Flags.music_lyrics_spot;

			if spot and spot.SetValue then pcall(spot.SetValue, spot, HUD.LyricsSpot) end;
		end;

		local anchor = SPOTS[HUD.LyricsSpot] or SPOTS["Bottom Left"];

		lyricPanel.AnchorPoint = anchor;
		lyricScale.Scale = HUD.Scale / 100;

		lyricPanel.Size = UDim2.fromOffset(panel.Size.X.Offset, HUD.LyricsSize);

		lyricPanel.Position = UDim2.new(
			anchor.X,
			(anchor.X == 0 and PAD or -PAD) + HUD.LyricsX,
			anchor.Y,
			(anchor.Y == 0 and PAD or -PAD) + HUD.LyricsY
		);
	end;

	local lyricDrag, lyricFrom, lyricBase = false, nil, nil;

	local function snapLyrics()
		local screen = NeverLose.ScreenGui.AbsoluteSize;

		if screen.X < 8 or screen.Y < 8 then return end;

		local center = screenAt(lyricPanel) + lyricPanel.AbsoluteSize * 0.5;
		local right = center.X > screen.X * 0.5;
		local bottom = center.Y > screen.Y * 0.5;

		HUD.LyricsSpot = (bottom and "Bottom " or "Top ") .. (right and "Right" or "Left");

		local anchor = SPOTS[HUD.LyricsSpot];
		local at = screenAt(lyricPanel) + lyricPanel.AbsoluteSize * Vector2.new(anchor.X, anchor.Y);
		local corner = Vector2.new(anchor.X * screen.X, anchor.Y * screen.Y);
		local base = Vector2.new(anchor.X == 0 and PAD or -PAD, anchor.Y == 0 and PAD or -PAD);
		local reachX = math.max(0, screen.X - lyricPanel.AbsoluteSize.X);
		local reachY = math.max(0, screen.Y - lyricPanel.AbsoluteSize.Y);

		HUD.LyricsX = math.clamp(math.floor(at.X - corner.X - base.X + 0.5), -reachX, reachX);
		HUD.LyricsY = math.clamp(math.floor(at.Y - corner.Y - base.Y + 0.5), -reachY, reachY);
	end;

	lyricPanel.Active = true;

	lyricPanel.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return;
		end;

		lyricDrag = true;
		lyricFrom = input.Position;
		lyricBase = Vector2.new(HUD.LyricsX, HUD.LyricsY);
	end);

	NeverLose:AddSignal(UserInputService.InputChanged:Connect(function(input)
		if not lyricDrag then return end;

		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return;
		end;

		local delta = input.Position - lyricFrom;

		HUD.LyricsX = lyricBase.X + delta.X;
		HUD.LyricsY = lyricBase.Y + delta.Y;

		placeLyrics();

		local screen = NeverLose.ScreenGui.AbsoluteSize;
		local at = screenAt(lyricPanel);
		local size = lyricPanel.AbsoluteSize;
		local pushX = math.clamp(at.X, 0, math.max(0, screen.X - size.X)) - at.X;
		local pushY = math.clamp(at.Y, 0, math.max(0, screen.Y - size.Y)) - at.Y;

		if pushX ~= 0 or pushY ~= 0 then
			HUD.LyricsX = HUD.LyricsX + pushX;
			HUD.LyricsY = HUD.LyricsY + pushY;

			placeLyrics();
		end;
	end));

	NeverLose:AddSignal(UserInputService.InputEnded:Connect(function(input)
		if not lyricDrag then return end;

		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return;
		end;

		lyricDrag = false;

		snapLyrics();
		placeLyrics();

		for flag, value in pairs({ music_lyrics_x = HUD.LyricsX, music_lyrics_y = HUD.LyricsY }) do
			local item = NeverLose.Flags[flag];

			if item and item.SetValue then pcall(item.SetValue, item, value) end;
		end;

		local spot = NeverLose.Flags.music_lyrics_spot;

		if spot and spot.SetValue then pcall(spot.SetValue, spot, HUD.LyricsSpot) end;
	end));

	local function drawLyrics(position, dt)

		local lines = lyricState.lines;
		local want = HUD.On and HUD.Lyrics and #lines > 0;

		lyricShow = lyricShow + ((want and 1 or 0) - lyricShow) * math.min(1, dt * 9);

		if lyricShow < 0.01 then
			lyricPanel.Visible = false;

			return;
		end;

		lyricPanel.Visible = true;

		local tone = accent();
		local clear = 1 - HUD.Opacity / 100;

		lyricPanel.BackgroundTransparency = 1 - (1 - (clear * 0.88 + 0.04)) * lyricShow;
		lyricEdge.Transparency = 1 - (1 - (0.4 + clear * 0.55)) * lyricShow;
		lyricHead.TextTransparency = 1 - lyricShow;
		lyricHead.TextColor3 = tone;
		lyricHead.Text = lyricState.synced and "LYRICS" or "LYRICS / PLAIN";
		lyricTrack.Text = Playback.title or "";
		lyricTrack.TextTransparency = 1 - 0.72 * lyricShow;

		local active = 0;

		if lyricState.synced then
			for index = 1, #lines do
				if (lines[index].at or 0) <= position then active = index else break end;
			end;
		end;

		local rows = math.max(1, math.floor(lyricView.AbsoluteSize.Y / LINE_H));
		local center = math.floor(rows / 2);
		local target = lyricState.synced and math.max(0, active - 1 - center) or 0;

		lyricState.offset = lyricState.offset + (target - lyricState.offset) * math.min(1, dt * 7);

		lyricRoll.Position = UDim2.fromOffset(0, -math.floor(lyricState.offset * LINE_H + 0.5));

		for index = 1, math.max(#lines, #lyricRows) do
			local entry = lines[index];

			if entry then
				local row = lyricRow(index);

				if row.Text ~= entry.text then row.Text = entry.text ~= "" and entry.text or " " end;

				row.Position = UDim2.fromOffset(0, (index - 1) * LINE_H);

				local away = lyricState.synced and math.abs(index - active) or 0;
				local near = math.clamp(1 - away / 3.2, 0, 1);
				local isNow = lyricState.synced and index == active;

				local wantAlpha = lyricState.synced and (0.62 - near * 0.62) or 0.1;
				local wantColour = TH.dim:Lerp(tone, isNow and 1 or near * 0.28);

				row.TextTransparency = row.TextTransparency + ((1 - (1 - wantAlpha) * lyricShow) - row.TextTransparency) * math.min(1, dt * 10);
				row.TextColor3 = row.TextColor3:Lerp(wantColour, math.min(1, dt * 10));

				local face = isNow and NeverLose.BuiltInBold or NeverLose.BuiltInRegular;

				if row.FontFace ~= face then row.FontFace = face end;

				local scaleWant = isNow and 1.06 or 1;
				local grow = row:FindFirstChildOfClass("UIScale");

				if not grow then
					grow = Instance.new("UIScale");
					grow.Parent = row;
				end;

				grow.Scale = grow.Scale + (scaleWant - grow.Scale) * math.min(1, dt * 9);
			else
				local row = lyricRows[index];

				if row and row.Text ~= "" then row.Text = "" end;
			end;
		end;
	end;

	local lastSync = os.clock();
	local pollTask, syncBusy, syncQueued;
	local function playbackKey(state)
		return tostring(state.title or "") .. "|" .. tostring(state.artist or "");
	end;
	local function waitForPlayback()
		resetLyrics("Loading");
		Playback.title = "Loading...";
		Playback.artist = "";
		Playback.album = "";
		Playback.artwork = "";
		Playback.duration = 0;
		Playback.position = 0;
		Playback.playing = false;
		Playback.canSeek = false;
		Playback.canSkipNext = false;
		Playback.canSkipPrevious = false;
		Playback.status = "";
		Playback.trackId = nil;
	end;

	local function sync()
		local p = provider();
		local epoch = providerEpoch;
		local previousTrack = playbackKey(Playback);
		local nextState = table.clone(Playback);

		local ok = pcall(function()
			if p.read then
				p.read(nextState);
			elseif p.refreshState then
				p.refreshState(nextState);
			end;
		end);
		if not ok then nextState.status = "Provider unavailable" end;
		if not __ALIVE() or epoch ~= providerEpoch or provider() ~= p then return end;
		for key, value in pairs(nextState) do Playback[key] = value end;
		for _, key in ipairs({ "position", "duration", "volume" }) do
			local value = tonumber(Playback[key]);
			Playback[key] = value and value == value and math.abs(value) < math.huge and math.max(0, value) or 0;
		end;
		Playback.volume = math.min(Playback.volume, 100);
		Playback.position = Playback.duration > 0 and math.min(Playback.position, Playback.duration) or Playback.position;
		for _, key in ipairs({ "title", "artist", "artwork", "status" }) do Playback[key] = tostring(Playback[key] or "") end;
		for _, key in ipairs({ "playing", "canSeek", "canSkipNext", "canSkipPrevious", "shuffle", "loop" }) do Playback[key] = Playback[key] == true end;
		if playbackKey(Playback) ~= previousTrack then resetLyrics("Track changed") end;

		lastSync = os.clock();
	end;
	local function requestSync()
		if not __ALIVE() then return end;
		if syncBusy then syncQueued = true; return end;
		syncBusy = true;
		task.spawn(function()
			repeat
				syncQueued = false;
				pcall(sync);
			until not (__ALIVE() and syncQueued);
			syncBusy = false;
		end);
	end;

	pollTask = task.spawn(function()
		while __ALIVE() do
			if HUD.On then requestSync() end;

			task.wait(current == "Spotify" and 2 or 0.5);
		end;
	end);

	local shownArt = "";
	local shownTitle = "";
	local lastFlagReconcile = -math.huge;
	local frame;
	local function renderHud(dt)
		if not (__ALIVE() and HUD.On) then return end;

		local position = Playback.position;

		if Playback.playing then
			position = position + (os.clock() - lastSync);
		end;

		if Playback.duration > 0 then position = math.min(position, Playback.duration) end;

		local tone = accent();

		fill.BackgroundColor3 = tone;
		knob.BackgroundColor3 = tone;
		knob.Visible = Playback.duration > 0;
		artMark.Visible = (art.Image == "");
		artMark.ImageColor3 = tone;

		if Playback.duration > 0 then
			fill.Size = UDim2.fromScale(math.clamp(position / Playback.duration, 0, 1), 1);
		else
			fill.Size = UDim2.fromScale(0, 1);
		end;

		clock.Text = clockText(position);
		totalClock.Text = clockText(Playback.duration);

		local heading = Playback.title or "";

		if heading ~= shownTitle then
			shownTitle = heading;
			title.Text = heading;
		end;

		local status = Playback.status or "";
		local artistName = Playback.artist or "";
		artist.Text = artistName ~= "" and artistName or status;
		source.Text = string.upper(current) .. ((status ~= "" and artistName ~= "") and (" / " .. status) or "");
		source.TextColor3 = tone;

		local wantArt = coverFor(Playback.artwork);

		if wantArt ~= shownArt then
			artOld.Image = art.Image;
			artOld.ImageTransparency = 0;
			shownArt = wantArt;
			art.Image = wantArt;
			art.ImageTransparency = 1;

			TweenService:Create(art, TweenInfo.new(0.35), { ImageTransparency = 0 }):Play();
			TweenService:Create(artOld, TweenInfo.new(0.35), { ImageTransparency = 1 }):Play();
		end;

		playBtn.setGlyph(Playback.playing and "pause" or "play");
		prevBtn.setEnabled(Playback.canSkipPrevious);
		nextBtn.setEnabled(Playback.canSkipNext);
		seekHit.Active = Playback.canSeek;

		local reconcileFlags = os.clock() - lastFlagReconcile >= 0.25;
		if reconcileFlags then lastFlagReconcile = os.clock() end;
		if reconcileFlags and not dragging then
			local spotFlag = NeverLose.Flags.music_spot;
			local xFlag = NeverLose.Flags.music_x;
			local yFlag = NeverLose.Flags.music_y;
			local moved = false;

			if spotFlag then
				local value = spotFlag:GetValue();

				if type(value) == "table" then value = value[1] end;

				if type(value) == "string" and SPOTS[value] and value ~= HUD.Spot then
					HUD.Spot = value;
					moved = true;
				end;
			end;

			if xFlag then
				local value = tonumber(xFlag:GetValue());

				if value and value ~= HUD.OffsetX then HUD.OffsetX = value; moved = true end;
			end;

			if yFlag then
				local value = tonumber(yFlag:GetValue());

				if value and value ~= HUD.OffsetY then HUD.OffsetY = value; moved = true end;
			end;

			if moved then place(); placeLyrics() end;
		end;

		if reconcileFlags and not lyricDrag then
			local spotFlag = NeverLose.Flags.music_lyrics_spot;
			local xFlag = NeverLose.Flags.music_lyrics_x;
			local yFlag = NeverLose.Flags.music_lyrics_y;
			local moved = false;

			if spotFlag then
				local value = spotFlag:GetValue();

				if type(value) == "table" then value = value[1] end;

				if type(value) == "string" and SPOTS[value] and value ~= HUD.LyricsSpot then
					HUD.LyricsSpot = value;
					HUD.LyricsPlaced = true;
					moved = true;
				end;
			end;

			if xFlag then
				local value = tonumber(xFlag:GetValue());

				if value and value ~= HUD.LyricsX then HUD.LyricsX = value; HUD.LyricsPlaced = true; moved = true end;
			end;

			if yFlag then
				local value = tonumber(yFlag:GetValue());

				if value and value ~= HUD.LyricsY then HUD.LyricsY = value; HUD.LyricsPlaced = true; moved = true end;
			end;

			if moved then placeLyrics() end;
		end;

		wantLyrics();
		drawLyrics(position, math.min(dt, 0.1));

		if HUD.Visualizer then
			local beat = os.clock() * 6;

			for index, b in ipairs(bars) do
				if b.Visible then
					local height = Playback.playing
						and (5 + math.abs(math.sin(beat + index * 0.9)) * 11)
						or 4;

					b.Size = UDim2.fromOffset(3, height);
					b.BackgroundColor3 = tone;
				end;
			end;
		end;
	end;
	local function setHud(value)
		local opening = value == true and not HUD.On;
		HUD.On = value == true;
		panel.Visible = HUD.On;
		if HUD.On then
			if opening then waitForPlayback() end;
			if not frame then frame = RunService.RenderStepped:Connect(renderHud) end;
			requestSync();
			renderHud(0);
		else
			if frame then frame:Disconnect(); frame = nil end;
			lyricShow = 0;
			lyricPanel.Visible = false;
		end;
	end;

	playBtn.button.MouseButton1Click:Connect(function()
		if Playback.playing then command("pause") else command("play") end;

		task.delay(0.35, function() if HUD.On then requestSync() end end);
	end);

	nextBtn.button.MouseButton1Click:Connect(function()
		command("next");

		task.delay(0.5, function() if HUD.On then requestSync() end end);
	end);

	prevBtn.button.MouseButton1Click:Connect(function()
		command("previous");

		task.delay(0.5, function() if HUD.On then requestSync() end end);
	end);

	seekHit.MouseButton1Click:Connect(function()
		if not Playback.canSeek then return end;

		local mouse = UserInputService:GetMouseLocation();
		local at = track.AbsolutePosition.X;
		local width = math.max(1, track.AbsoluteSize.X);

		command("seek", math.clamp((mouse.X - at) / width, 0, 1));

		task.delay(0.4, function() if HUD.On then requestSync() end end);
	end);

	local function showPanels(name)
		local cards = {
			Spotify = Sections.Spotify,
			SoundCloud = Sections.SoundCloud,
			VK = Sections.Vk,
		};

		for key, card in pairs(cards) do
			if card and card.SetVisible then pcall(card.SetVisible, card, key == name) end;
		end;
	end;

	Sections.Music:AddLabel("Provider"):AddDropdown({
		Default = "Local",
		Values = { "Local", "Spotify", "SoundCloud", "VK" },
		Flag = "music_provider",
		Callback = function(v)
			local previous = provider();
			if previous.deactivate then previous.deactivate() elseif previous.pause then pcall(previous.pause) end;
			providerEpoch += 1;
			current = v;
			waitForPlayback();
			command("activate");
			command("setVolume", musicSettings.volume);
			command("setLoop", musicSettings.loop);

			showPanels(v);
			requestSync();
		end,
	});

	showPanels("Local");

	Sections.Music:AddLabel("Now Playing HUD"):AddToggle({
		Name = "Now Playing HUD",
		Default = false,
		Flag = "music_hud",
		Callback = function(v)
			setHud(v);
		end,
	});

	Sections.Music:AddButton({
		Icon = "plus",
		Name = "Add Track by ID",
		Callback = function()
			pcall(function()
				NeverLose.Lib:ask({
					title = "add track",
					icon = "plus",
					hint = "audio id, or: 12345 Artist - Title",
					accept = "add",
					deny = "cancel",
					callback = function(text)
						if LocalProvider.add(text) then requestSync() end;
					end,
				});
			end);
		end,
	});

	Sections.Music:AddButton({ Icon = "trash-can", Name = "Clear Queue", Callback = function()
		LocalProvider.clear(); SoundCloud.clear(); Vk.clear(); requestSync();
	end });

	Sections.Music:AddLabel("Loop"):AddToggle({
		Name = "Loop",
		Default = false, Flag = "music_loop",
		Callback = function(v) musicSettings.loop = v; command("setLoop", v) end,
	});

	Sections.Music:AddLabel("Volume"):AddSlider({
		Min = 0, Max = 100, Default = 50, Type = "%", Size = 100,
		Flag = "music_volume",
		Callback = function(v) musicSettings.volume = v; command("setVolume", v) end,
	});

	Sections.MusicHud:AddLabel("Layout"):AddDropdown({
		Default = "Full", Values = { "Full", "Compact" },
		Flag = "music_layout",
		Callback = function(v) HUD.Layout = v; relayout() end,
	});

	for _, entry in ipairs({
		{ "Show Artwork", "Artwork", "music_show_art", true },
		{ "Show Controls", "Controls", "music_show_controls", true },
		{ "Show Progress", "Progress", "music_show_progress", true },
		{ "Show Time", "Times", "music_show_time", true },
		{ "Show Visualizer", "Visualizer", "music_show_vis", true },
	}) do
		local key = entry[2];

		Sections.MusicHud:AddLabel(entry[1]):AddToggle({
			Name = entry[1], Default = entry[4], Flag = entry[3],
			Callback = function(v) HUD[key] = v; relayout() end,
		});
	end;

	Sections.MusicHud:AddLabel("Lyrics"):AddToggle({
		Name = "Lyrics",
		Default = false,
		Flag = "music_lyrics",
		ToolTip = "Synced lyrics",
		Callback = function(v)
			HUD.Lyrics = v;
			resetLyrics(v and "Loading" or "");

			placeLyrics();
		end,
	});

	Sections.MusicHud:AddLabel("Lyrics Height"):AddSlider({
		Min = 90, Max = 340, Default = 150, Rounding = 0, Size = 100,
		Flag = "music_lyrics_size",
		Callback = function(v) HUD.LyricsSize = v; placeLyrics() end,
	});

	Sections.MusicHud:AddLabel("Lyrics Corner"):AddDropdown({
		Default = "Bottom Left",
		Values = { "Top Left", "Top Right", "Bottom Left", "Bottom Right" },
		Flag = "music_lyrics_spot",
		Callback = function(v) HUD.LyricsSpot = v; HUD.LyricsPlaced = true; placeLyrics() end,
	});

	Sections.MusicHud:AddLabel("Position"):AddDropdown({
		Default = "Bottom Left",
		Values = { "Top Left", "Top Right", "Bottom Left", "Bottom Right" },
		Flag = "music_spot",
		Callback = function(v) HUD.Spot = v; place() end,
	});

	do
		local hidden = {
			{ "music_x", "OffsetX" },
			{ "music_y", "OffsetY" },
			{ "music_lyrics_x", "LyricsX" },
			{ "music_lyrics_y", "LyricsY" },
		};

		for _, entry in ipairs(hidden) do
			local id, key = entry[1], entry[2];

			NeverLose.Lib:hook(id, "number",
				function() return HUD[key] end,
				function(value)
					local number = tonumber(value);

					if number then
						HUD[key] = number;

						if key == "LyricsX" or key == "LyricsY" then HUD.LyricsPlaced = true end;
					end;
				end);

			NeverLose.Flags[id] = {
				GetValue = function() return HUD[key] end,
				SetValue = function(_, value)
					local number = tonumber(value);

					if number then HUD[key] = number end;
				end,
			};
		end;
	end;

	for _, entry in ipairs({
		{ "Opacity", "Opacity", "music_opacity", 10, 100, 100 },
		{ "Scale", "Scale", "music_scale", 60, 180, 100 },
		{ "Cover Size", "CoverSize", "music_cover", 32, 96, 52 },
	}) do
		local key = entry[2];

		Sections.MusicHud:AddLabel(entry[1]):AddSlider({
			Min = entry[4], Max = entry[5], Default = entry[6], Rounding = 0, Size = 100,
			Flag = entry[3],
			Callback = function(v) HUD[key] = v; relayout() end,
		});
	end;

	Sections.Spotify:AddLabel("Client ID"):AddTextInput({
		Default = "",
		Placeholder = "Client ID",
		Flag = "spotify_client",
		Callback = function(v) Spotify.setClientId(v) end,
	});

	Sections.Spotify:AddButton({
		Icon = "link",
		Name = "Connect",
		Callback = function() Spotify.begin() end,
	});

	Sections.Spotify:AddLabel("Paste Code"):AddTextInput({
		Default = "",
		Placeholder = "Paste code",
		Flag = "spotify_code",
		Callback = function(v)
			if #tostring(v or "") > 20 then Spotify.finish(v) end;
		end,
	});

	Sections.Spotify:AddButton({
		Icon = "info",
		Name = "Test Connection",
		Callback = function()
			task.spawn(function()
				if not Spotify.hasClientId() then
					Notification.new({ Title = "Spotify", Content = "No Client ID", Duration = 6 });

					return;
				end;

				local body, code, raw = Spotify.call("GET", "/me");

				if code == 200 and body then
					Notification.new({
						Title = "Spotify",
						Content = ("Connected as %s (%s)"):format(tostring(body.display_name or body.id), tostring(body.product)),
						Duration = 8,
					});

					return;
				end;

				local reason = (raw and type(raw.Body) == "string" and raw.Body ~= "") and raw.Body or "no response body";

				Notification.new({
					Title = "Spotify",
					Content = "Request failed (" .. tostring(code) .. ")",
					Duration = 12,
				});

				warn("[visuals] spotify /me -> " .. tostring(code) .. ": " .. reason);
			end);
		end,
	});

	Sections.Spotify:AddButton({
		Icon = "log-out",
		Name = "Disconnect",
		Callback = function()
			Spotify.disconnect();

			Notification.new({ Title = "Spotify", Content = "Disconnected", Duration = 4 });
		end,
	});

	Sections.Spotify:AddLabel("Redirect URI: " .. REDIRECT, true);

	Sections.SoundCloud:AddLabel("Client ID"):AddTextInput({
		Default = "", Placeholder = "Client ID",
		Flag = "soundcloud_client",
		Callback = function(v) SC.Client = tostring(v or "") end,
	});

	Sections.SoundCloud:AddLabel("Link"):AddTextInput({
		Default = "", Placeholder = "Track or playlist URL",
		Flag = "soundcloud_link",
		Callback = function() end,
	});

	Sections.SoundCloud:AddButton({
		Icon = "plus", Name = "Queue From SoundCloud",
		Callback = function()
			local box = NeverLose.Flags.soundcloud_link;
			local text = box and box:GetValue() or "";

			pcall(function() NeverLose.Lib.pool["music_provider"].set("SoundCloud") end);
			SoundCloud.add(text);
		end,
	});

	Sections.Vk:AddLabel("Token"):AddTextInput({
		Default = "", Placeholder = "Access token",
		Flag = "vk_token",
		Callback = function(v) VK.Token = tostring(v or "") end,
	});

	Sections.Vk:AddLabel("Owner"):AddTextInput({
		Default = "", Placeholder = "Owner ID (optional)",
		Flag = "vk_link",
		Callback = function() end,
	});

	Sections.Vk:AddButton({
		Icon = "plus", Name = "Queue From VK",
		Callback = function()
			local box = NeverLose.Flags.vk_link;
			local text = box and box:GetValue() or "";

			pcall(function() NeverLose.Lib.pool["music_provider"].set("VK") end);
			Vk.add(text);
		end,
	});

	relayout();

	ESP.ClearMusic = onUnload("music", function()
		setHud(false);
		providerEpoch += 1;

		if pollTask then pcall(task.cancel, pollTask) end;

		pcall(function() lyricPanel:Destroy() end);

		pcall(LocalProvider.stop);
		table.clear(audioCache); table.clear(covers); table.clear(coverBusy);
	end);
end;
