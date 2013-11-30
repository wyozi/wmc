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
		callback("http://player.vimeo.com/video/" .. tostring(data.Matches[1]) .. "?autoplay=1&api=1") -- #t=" .. tostring(math.Round(data.StartAt or 0)) .. "s" Doesnt seem to work properly on awesomium?
	end,
	FuncSetVolume = function(volume)
		-- "window.postMessage(JSON.stringify({method: \"setVolume\", value: \"" .. tostring(volume) .. "\"}));"
		return ""
	end
})