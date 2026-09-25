--!nonstrict
--[[
	trade.lua — extracted feature module (require id "modules.trade").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("trade") in the driver — byte-frozen original
	code below the marker (re-derived on every `make extract`; do not hand-edit).

	The block originally closed over driver locals; the driver now passes them
	in via the ctx table:

		guard("trade", function()
			return require("modules.trade")({ ESP = ESP, GLOBAL = GLOBAL, Remote = Remote, Sections = Sections, fluxus = fluxus, http = http });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local GLOBAL = ctx.GLOBAL;
	local Remote = ctx.Remote;
	local Sections = ctx.Sections;
	local fluxus = ctx.fluxus;
	local http = ctx.http;

-- [ guard("trade") callback body — byte-exact from input/message(47).txt ]
	local players = game:GetService("Players")
	local rs = game:GetService("ReplicatedStorage")
	local lp = players.LocalPlayer

	local show_on = false
	local conns = {}
	local gen = 0
	local sync = nil

	local env = GLOBAL
	env.__SV_STORE = env.__SV_STORE or { pages = {}, items = {}, fails = {}, busy = {} }
	local store = env.__SV_STORE
	local prefetch_gen = 0
	local id_index = nil

	local BASE = "https://r.jina.ai/https://supremevalues.com/mm2/"
	local PAGES = {
		"godlies", "chromas", "ancients", "uniques", "vintages",
		"legendaries", "rares", "uncommons", "commons", "pets", "misc"
	}
	local RARITY_PAGE = {
		Common = "commons",
		Uncommon = "uncommons",
		Rare = "rares",
		Legendary = "legendaries",
		Godly = "godlies",
		Ancient = "ancients",
		Unique = "uniques",
		Classic = "vintages",
		Vintage = "vintages",
		Christmas = "misc",
		Halloween = "misc",
	}
	local SKIP = {
		"^Class %-", "^Range", "^Stability", "^Demand", "^Rarity", "^Change in Value",
		"^Inv%.", "^Value", "^Tier", "^Filter", "^Sort", "^Title:", "^URL Source",
		"^Published Time", "^Markdown Content", "^%*", "^!%[", "^%[", "^%-", "^Supreme",
		"^Trade your", "^The Supreme", "^Chance of"
	}

	local LOW = "<1"

	local function norm(s)
		return (string.gsub(string.lower(tostring(s)), "[^%w]", ""))
	end

	local function comma(n)
		local s = tostring(math.floor(n + 0.5))
		while true do
			local r
			s, r = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
			if r == 0 then break end
		end
		return s
	end

	local function skip_line(t)
		for _, p in ipairs(SKIP) do
			if string.match(t, p) then return true end
		end
		return string.find(t, "%]%(") ~= nil or #t > 44
	end

	local function unwrap(t)
		return string.match(t, "^!%[.-%]%b()%s*(.+)$") or t
	end

	local function parse_page(txt, slug)
		local out = {}
		local last = nil
		for line in string.gmatch(txt .. "\n", "([^\n]*)\n") do
			local t = unwrap(string.match(line, "^%s*(.-)%s*$"))
			if t ~= "" then
				local raw = string.match(t, "^Value %- %*%*(.-)%*%*")
				if raw then
					if last then
						local clean = string.gsub(raw, "[,%s]", "")
						local num = tonumber(clean)
						if not num and string.match(clean, "^x%d+T%d") then num = LOW end
						if not num and #clean > 0 and #clean <= 12 then num = clean end
						local key = norm(last)
						if num and key ~= "" then
							if out[key] == nil then out[key] = num end
							if slug == "chromas" then
								local cut = string.match(key, "^chroma(.+)") or string.match(key, "^c(.+)")
								if cut and cut ~= "" and out[cut] == nil then out[cut] = num end
							end
						end
					end
					last = nil
				elseif not skip_line(t) then
					last = t
				end
			end
		end
		return out
	end

	local function valid_body(s)
		if type(s) ~= "string" or #s < 512 then return false end
		if not string.find(s, "Markdown Content", 1, true) then return false end
		return true
	end

	local function http_get(url)
		local ok, res = Remote.invoke(function() return game:HttpGet(url, true) end, 12)
		if ok and valid_body(res) then return res end
		local req = rawget(getfenv(), "request")
			or rawget(getfenv(), "http_request")
			or (syn and syn.request)
			or (http and http.request)
			or (fluxus and fluxus.request)
			or env.request
		if type(req) == "function" then
			local ok2, res2 = Remote.invoke(function() return req({
				Url = url,
				Method = "GET",
				Timeout = 12,
				Headers = { ["Accept"] = "text/plain", ["User-Agent"] = "Mozilla/5.0" }
			}) end, 12)
			if ok2 and type(res2) == "table" and valid_body(res2.Body) then return res2.Body end
		end
		return nil
	end

	local BACKOFF = { 2, 4, 6, 9 }
	local FAIL_COOLDOWN = 6

	local function get_page(slug)
		local cached = store.pages[slug]
		if cached then return cached end
		local deadline = os.clock() + 30
		while store.busy[slug] and Remote.current() do
			task.wait(0.2)
			if store.pages[slug] then return store.pages[slug] end
			if os.clock() >= deadline then return nil end
		end
		if not Remote.current() then return nil end
		if store.pages[slug] then return store.pages[slug] end
		local fail = store.fails[slug]
		if fail and os.clock() - fail < FAIL_COOLDOWN then return nil end
		local claim = {}
		store.busy[slug] = claim
		local built = nil
		for attempt = 1, #BACKOFF + 1 do
			if not Remote.current() then break end
			local txt = http_get(BASE .. slug)
			if txt then
				local ok, idx = pcall(parse_page, txt, slug)
				if ok and type(idx) == "table" and next(idx) ~= nil then
					built = idx
					break
				end
			end
			local nap = BACKOFF[attempt]
			if nap then task.wait(nap) end
		end
		if store.busy[slug] == claim then store.busy[slug] = nil end
		if not Remote.current() then return nil end
		if built then
			store.pages[slug] = built
			store.fails[slug] = nil
			return built
		end
		store.fails[slug] = os.clock()
		return nil
	end

	local function item_keys(data)
		local base = norm(data.ItemName or data.Name or "")
		local keys = {}
		if base == "" then return keys end
		local ty = data.ItemType and norm(tostring(data.ItemType)) or nil
		local yr = data.Year and norm(tostring(data.Year)) or nil
		local evo = data.EvoIndex and ("var" .. norm(tostring(data.EvoIndex))) or nil

		local seen = {}
		local function push(k)
			if k == "" or seen[k] then return end
			seen[k] = true
			keys[#keys + 1] = k
		end

		if evo then push(base .. evo) end
		if ty and yr then push(base .. ty .. yr) end
		if ty then push(base .. ty) end
		if yr then push(base .. yr) end
		push(base)
		return keys
	end

	local function page_list(data, dtype)
		if dtype == "Pets" then return { "pets" } end
		if data.Chroma then return { "chromas" } end
		local p = RARITY_PAGE[data.Rarity or ""]
		if p then return { p } end
		return { "misc" }
	end

	local function match_index(idx, keys)
		for _, k in ipairs(keys) do
			local v = idx[k]
			if v ~= nil then return v end
		end
		return nil
	end

	local function resolve(dtype, id, data)
		local ck = tostring(dtype) .. "|" .. tostring(id) .. (data.Chroma and "|c" or "")
		local hit = store.items[ck]
		if hit ~= nil then return hit, true end

		local keys = item_keys(data)
		if #keys == 0 then return false, true end

		local primary = page_list(data, dtype)
		local incomplete = false

		for _, slug in ipairs(primary) do
			local idx = get_page(slug)
			if idx then
				local v = match_index(idx, keys)
				if v ~= nil then
					store.items[ck] = v
					return v, true
				end
			else
				incomplete = true
			end
		end

		if not data.Chroma then
			for _, slug in ipairs(PAGES) do
				local skip = slug == "chromas"
				for _, x in ipairs(primary) do
					if x == slug then skip = true break end
				end
				if not skip then
					local idx = store.pages[slug]
					if idx then
						local v = match_index(idx, keys)
						if v ~= nil then
							store.items[ck] = v
							return v, true
						end
					elseif not store.fails[slug] then
						incomplete = true
					end
				end
			end
		end

		if incomplete then return nil, false end
		store.items[ck] = false
		return false, true
	end

	local function prefetch()
		prefetch_gen = prefetch_gen + 1
		local my = prefetch_gen
		store.fails = {}
		task.spawn(function()
			for sweep = 1, 4 do
				local left = 0
				for _, slug in ipairs(PAGES) do
					if my ~= prefetch_gen or not show_on then return end
					if not store.pages[slug] then
						get_page(slug)
						if not store.pages[slug] then left = left + 1 end
						task.wait(0.4)
					end
				end
				if left == 0 then return end
				if my ~= prefetch_gen or not show_on then return end
				task.wait(sweep * 4)
			end
		end)
	end

	local function trade_root()
		local pg = lp:FindFirstChildOfClass("PlayerGui")
		local gui = pg and pg:FindFirstChild("TradeGUI")
		local cont = gui and gui:FindFirstChild("Container")
		return cont and cont:FindFirstChild("Trade"), gui
	end

	local function make_label(parent, name, size, pos, anchor, maxtext, align)
		local l = parent:FindFirstChild(name)
		if l then
			l.AnchorPoint = anchor
			l.Position = pos
			l.Size = size
			l.TextXAlignment = align
			local c = l:FindFirstChildOfClass("UITextSizeConstraint")
			if c then c.MaxTextSize = maxtext end
			return l
		end
		l = Instance.new("TextLabel")
		l.Name = name
		l.AnchorPoint = anchor
		l.Position = pos
		l.Size = size
		l.BackgroundTransparency = 1
		l.BorderSizePixel = 0
		l.Font = Enum.Font.GothamBold
		l.TextColor3 = Color3.fromRGB(255, 216, 110)
		l.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		l.TextStrokeTransparency = 0.15
		l.TextXAlignment = align
		l.TextScaled = true
		l.RichText = false
		l.ZIndex = 40
		l.Text = ""
		local con = Instance.new("UITextSizeConstraint")
		con.MaxTextSize = maxtext
		con.MinTextSize = 7
		con.Parent = l
		l.Parent = parent
		return l
	end

	local function total_label(offer)
		local l = make_label(offer, "SV_Total",
			UDim2.new(0.4, 0, 0, 22), UDim2.new(0.025, 0, 1, -137),
			Vector2.new(0, 1), 22, Enum.TextXAlignment.Left)

		local width = offer.AbsoluteSize.X
		local left = width * 0.025
		local title = offer:FindFirstChild("Title")
		if title and title.TextBounds.X > 4 then
			left = (title.AbsolutePosition.X - offer.AbsolutePosition.X) + title.TextBounds.X + 10
		end
		local limit = width - left - 8
		local user = offer:FindFirstChild("Username")
		if user and user.TextBounds.X > 4 then
			local edge = (user.AbsolutePosition.X - offer.AbsolutePosition.X) + user.AbsoluteSize.X - user.TextBounds.X
			limit = math.min(limit, edge - left - 8)
		end
		l.Position = UDim2.new(0, math.floor(left), 1, -137)
		l.Size = UDim2.new(0, math.max(60, math.floor(limit)), 0, 22)
		return l
	end

	local function card_label(card)
		local l = make_label(card, "SV_Value",
			UDim2.new(0.7, 0, 0.16, 0), UDim2.new(1, -6, 0, 4),
			Vector2.new(1, 0), 18, Enum.TextXAlignment.Right)

		local inner = card:FindFirstChild("Container")
		local amt = inner and inner:FindFirstChild("Amount")
		local stacked = amt and amt.Visible and string.match(amt.Text or "", "x%s*%d") ~= nil
		l.Position = UDim2.new(1, -6, 0, stacked and 32 or 4)
		return l
	end

	local function clear_side(offer)
		if not offer then return end
		local l = offer:FindFirstChild("SV_Total")
		if l then l.Visible = false end
		local cont = offer:FindFirstChild("Container")
		if not cont then return end
		for _, ch in ipairs(cont:GetChildren()) do
			local v = ch:FindFirstChild("SV_Value")
			if v then v.Visible = false end
		end
	end

	local function wipe_labels()
		local root = trade_root()
		if not root then return end
		for _, side in ipairs({ "YourOffer", "TheirOffer" }) do
			local offer = root:FindFirstChild(side)
			if offer then
				local l = offer:FindFirstChild("SV_Total")
				if l then l:Destroy() end
				local cont = offer:FindFirstChild("Container")
				if cont then
					for _, ch in ipairs(cont:GetChildren()) do
						local v = ch:FindFirstChild("SV_Value")
						if v then v:Destroy() end
					end
				end
			end
		end
	end

	local function ensure_sync()
		if sync then return sync end
		local database = rs:FindFirstChild("Database")
		local module = database and database:FindFirstChild("Sync")
		if not module or not module:IsA("ModuleScript") then return nil end
		local ok, mod = Remote.invoke(function() return require(module) end, 5)
		if ok and type(mod) == "table" then sync = mod end
		return sync
	end

	local function build_index()
		if id_index then return id_index end
		if not ensure_sync() then return nil end
		local byid, byname = {}, {}
		local function add(map, key, rec)
			if not key or key == "" then return end
			local bucket = map[key]
			if bucket then
				bucket[#bucket + 1] = rec
			else
				map[key] = { rec }
			end
		end
		for _, dtype in ipairs({ "Weapons", "Pets" }) do
			local db = sync[dtype]
			if type(db) == "table" then
				for id, d in pairs(db) do
					if type(d) == "table" then
						local rec = { dtype = dtype, id = id, data = d }
						if d.ItemID then add(byid, tostring(d.ItemID), rec) end
						if type(d.Image) == "string" then
							local dig = string.match(d.Image, "assetId=(%d+)")
								or string.match(d.Image, "id=(%d+)")
								or string.match(d.Image, "rbxassetid://(%d+)")
							if dig then add(byid, dig, rec) end
						end
						add(byname, tostring(d.ItemName or d.Name or ""), rec)
					end
				end
			end
		end
		id_index = { byid = byid, byname = byname }
		return id_index
	end

	local function icon_id(card)
		local inner = card:FindFirstChild("Container")
		local icon = inner and inner:FindFirstChild("Icon")
		local img = icon and icon.Image or ""
		if img == "" then return nil end
		return string.match(img, "assetId=(%d+)")
			or string.match(img, "id=(%d+)")
			or string.match(img, "rbxassetid://(%d+)")
	end

	local function card_entry(card, text, chroma)
		local ix = build_index()
		if not ix then return nil end
		local iid = icon_id(card)
		local pool = iid and ix.byid[iid] or nil
		if not pool then pool = ix.byname[text] end
		if not pool then return nil end

		local fallback = nil
		for _, rec in ipairs(pool) do
			local d = rec.data
			if (d.Chroma == true) == chroma then
				if tostring(d.ItemName or d.Name or "") == text then return rec.dtype, rec.id, d end
				if not fallback then fallback = rec end
			end
		end
		if fallback then return fallback.dtype, fallback.id, fallback.data end
		if iid and ix.byid[iid] == pool then
			local rec = pool[1]
			return rec.dtype, rec.id, rec.data
		end
		return nil
	end

	local function gui_items(offer)
		local out = {}
		local cont = offer and offer:FindFirstChild("Container")
		if not cont then return out end
		local i = 1
		while true do
			local card = cont:FindFirstChild("NewItem" .. i)
			if not card or not card.Visible then break end
			local nm = card:FindFirstChild("ItemName")
			local lbl = nm and nm:FindFirstChild("Label")
			local text = lbl and lbl.Text or ""
			if text == "" then break end
			local tags = card:FindFirstChild("Tags")
			local ch = tags and tags:FindFirstChild("Chroma")
			local inner = card:FindFirstChild("Container")
			local amt_l = inner and inner:FindFirstChild("Amount")
			local amt = amt_l and tonumber(string.match(amt_l.Text or "", "x%s*(%d+)")) or 1
			local chroma = ch ~= nil and ch.Visible == true
			local dtype, id, data = card_entry(card, text, chroma)
			out[i] = {
				id = id or norm(text),
				amount = amt,
				dtype = dtype or "Weapons",
				data = data or { ItemName = text, Chroma = chroma }
			}
			i = i + 1
		end
		return out
	end

	local function collect(offer_data)
		local out = {}
		if type(offer_data) ~= "table" then return out end
		ensure_sync()
		for i, v in ipairs(offer_data) do
			local id = v[1] or v.ItemID
			local amount = v[2] or v.Amount or 1
			local dtype = v[3] or v.ItemType
			local db = sync and dtype and sync[dtype]
			local data = db and db[id]
			out[i] = { id = id, amount = amount, dtype = dtype, data = data }
		end
		return out
	end

	local function render(offer, items, my_gen)
		if not offer then return end
		local cont = offer:FindFirstChild("Container")
		if not cont then return end
		clear_side(offer)
		local total = total_label(offer)
		if #items == 0 then
			total.Visible = false
			return
		end
		total.Visible = true
		total.Text = "..."
		for i in ipairs(items) do
			local card = cont:FindFirstChild("NewItem" .. i)
			if card then
				local l = card_label(card)
				l.Visible = true
				l.Text = "..."
			end
		end
		task.spawn(function()
			local done = {}
			local deadline = os.clock() + 150
			while true do
				local pending = false
				local sum = 0
				for i, it in ipairs(items) do
					if my_gen ~= gen or not show_on then return end
					if done[i] == nil then
						if it.data then
							local fine, val, settled = pcall(resolve, it.dtype, it.id, it.data)
							if not fine then
								done[i] = { v = false }
							elseif settled then
								done[i] = { v = val }
							else
								pending = true
							end
						else
							done[i] = { v = false }
						end
					end
					if my_gen ~= gen or not show_on then return end
					local card = cont:FindFirstChild("NewItem" .. i)
					local l = card and card:FindFirstChild("SV_Value")
					local rec = done[i]
					if rec then
						local val = rec.v
						local amt = tonumber(it.amount) or 1
						if type(val) == "number" then
							sum = sum + val * amt
							if l then l.Text = comma(val) end
						elseif type(val) == "string" then
							if l then l.Text = val end
						elseif l then
							l.Text = "?"
						end
					elseif l then
						l.Text = "..."
					end
				end
				if total.Parent then
					total.Text = pending and (comma(sum) .. " ...") or comma(sum)
				end
				if not pending then return end
				if os.clock() > deadline then
					for i in ipairs(items) do
						if done[i] == nil then
							local card = cont:FindFirstChild("NewItem" .. i)
							local l = card and card:FindFirstChild("SV_Value")
							if l then l.Text = "?" end
						end
					end
					if total.Parent then total.Text = comma(sum) end
					return
				end
				task.wait(2)
			end
		end)
	end

	local function update(data)
		if not show_on or type(data) ~= "table" then return end
		local mine, theirs
		if data.Player1 and data.Player1.Player == lp then
			mine, theirs = data.Player1.Offer, data.Player2 and data.Player2.Offer
		elseif data.Player2 and data.Player2.Player == lp then
			mine, theirs = data.Player2.Offer, data.Player1 and data.Player1.Offer
		else
			return
		end
		gen = gen + 1
		local my_gen = gen
		local my_items, their_items = collect(mine), collect(theirs)
		task.delay(0.05, function()
			if my_gen ~= gen or not show_on then return end
			local root = trade_root()
			if not root then return end
			render(root:FindFirstChild("YourOffer"), my_items, my_gen)
			render(root:FindFirstChild("TheirOffer"), their_items, my_gen)
		end)
	end

	local function refresh_gui()
		if not show_on then return end
		local root, gui = trade_root()
		if not root or not gui or not gui.Enabled then return end
		gen = gen + 1
		local my_gen = gen
		local mine = root:FindFirstChild("YourOffer")
		local theirs = root:FindFirstChild("TheirOffer")
		render(mine, gui_items(mine), my_gen)
		render(theirs, gui_items(theirs), my_gen)
	end

	local function hook()
		local trade = rs:FindFirstChild("Trade")
		if not trade then return end
		local upd = trade:FindFirstChild("UpdateTrade")
		local start = trade:FindFirstChild("StartTrade")
		if upd then
			conns[#conns + 1] = upd.OnClientEvent:Connect(update)
		end
		if start then
			conns[#conns + 1] = start.OnClientEvent:Connect(function(data)
				update(data)
			end)
		end
		local _, gui = trade_root()
		if gui then
			conns[#conns + 1] = gui:GetPropertyChangedSignal("Enabled"):Connect(function()
				if not gui.Enabled then
					gen = gen + 1
					local root = trade_root()
					if root then
						clear_side(root:FindFirstChild("YourOffer"))
						clear_side(root:FindFirstChild("TheirOffer"))
					end
				end
			end)
		end
	end

	local function unhook()
		for _, c in ipairs(conns) do
			pcall(function() c:Disconnect() end)
		end
		conns = {}
	end

	Sections.Trade:AddLabel("Show Values"):AddToggle({
		Name = "Show Values",
		Default = false,
		Flag = "trade_show_values",
		ToolTip = "Shows trade values",
		Callback = function(v)
			show_on = v
			gen = gen + 1
			if v then
				unhook()
				hook()
				prefetch()
				refresh_gui()
			else
				prefetch_gen = prefetch_gen + 1
				unhook()
				wipe_labels()
			end
		end,
	});

	Sections.Trade:AddButton({
		Icon = "arrow-rotate-right",
		Name = "Refresh Values",
		Callback = function()
			if not show_on then return end;

			store.pages = {};
			store.items = {};
			store.fails = {};

			prefetch();
			refresh_gui();
		end,
	});

	ESP.ClearTrade = function()
		show_on = false
		gen = gen + 1
		prefetch_gen = prefetch_gen + 1
		unhook()
		wipe_labels()
	end;
end;
