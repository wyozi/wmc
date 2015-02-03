wyozimc.AddProvider({
	Name = "Twitch Stream",
	UrlPatterns = {
		"^https?://www.twitch.tv/([%a%d]*)",
		"^https?://twitch.tv/([%a%d]*)",
	},
	QueryMeta = function(udata, callback, failCallback)
		local channel = udata.Matches[1]
		local url = string.format("https://api.twitch.tv/kraken/channels/%s", channel)

		wyozimc.Debug("Fetching Twitch meta for channel " .. channel)

		http.Fetch(url, function(result, size)
			if size == 0 then
				failCallback("HTTP request failed (size = 0)")
				return
			end

			local data = {}
			data["URL"] = "http://www.twitch.tv/" .. channel

			local jsontbl = util.JSONToTable(result)

			if jsontbl then
				data.Title = jsontbl.display_name .. ": " .. jsontbl.status
				data.Duration = -1
			else
				data.Title = "ERROR"
				data.Duration = -1
			end

			callback(data)

		end)
	end,
	PlayInMediaType = function(mtype, play_data)
		local data = play_data.udata
		mtype.html:OpenURL(string.format("http://wyozi.github.io/wmc/players/twitch.html?channel=%s", wyozimc.JSEscape(data.Matches[1])))
	end,
	ParseUData = function(udata)
	end,
	MediaType = "web",
})
