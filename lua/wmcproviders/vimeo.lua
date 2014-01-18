wyozimc.AddProvider({
	Name = "Vimeo",
	UrlPatterns = {
		"^https?://www.vimeo.com/(%d*)/?",
		"^https?://vimeo.com/(%d*)/?",
	},
	QueryMeta = function(data, callback, failCallback)
		local uri = data.Matches[1]
		
		local url = Format("http://vimeo.com/api/v2/video/%s.json", uri)

		wyozimc.Debug("Fetching query for " .. uri .. " from " .. url)

		http.Fetch(url, function(result, size)
			if size == 0 then
				failCallback("HTTP request failed (size = 0)")
				return
			end

			local data = {}
			data["URL"] = "http://www.vimeo.com/" .. uri
			
			local entry = util.JSONToTable(result)[1]

			data.Title = entry["title"]
			data.Duration = tonumber(entry["duration"])

			callback(data)

		end)
	end,
	TranslateUrl = function(data, callback)
		callback(string.format("http://wyozi.github.io/wmc/players/vimeo.html?vid=%s", wyozimc.JSEscape(data.Matches[1]), startat))
	end,
	FuncSetVolume = function(volume)
		return "setVimeoVolume(" .. tostring(volume) .. ")"
	end
})