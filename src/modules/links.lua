--!nonstrict
--[[
	links.lua — extracted feature module (require id "modules.links").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("links") in the driver — byte-frozen original
	code below the marker (re-derived on every `make extract`; do not hand-edit).

	The block originally closed over driver locals; the driver now passes them
	in via the ctx table:

		guard("links", function()
			return require("modules.links")({ NeverLose = NeverLose, Notification = Notification, Remote = Remote });
		end);
]]
return function(ctx)
	local NeverLose = ctx.NeverLose;
	local Notification = ctx.Notification;
	local Remote = ctx.Remote;

-- [ guard("links") callback body — byte-exact from input/message(47).txt ]
	local LINKS = {
		{ file = "images/telegram.png", url = "https://t.me/yanderovisual", name = "Telegram" },
		{ file = "images/tiktok.png", url = "https://www.tiktok.com/@yanderovs", name = "TikTok" },
	};
	task.spawn(function()
		local list = {};
		for _, link in ipairs(LINKS) do
			list[#list + 1] = {
				image = Remote.asset(link.file) or "",
				callback = function()
					local copied = type(setclipboard) == "function" and pcall(setclipboard, link.url);
					Notification.new({
						Title = link.name, Icon = "copy", Duration = 4,
						Content = copied and ("Link copied: " .. link.url) or link.url,
					});
				end,
			};
		end;
		if Remote.current() then NeverLose.Lib:setlinks(list) end;
	end);
end;
