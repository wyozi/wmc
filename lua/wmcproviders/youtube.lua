
local raw_patterns = {
	"^https?://[A-Za-z0-9%.%-]*%.?youtu%.be/([A-Za-z0-9_%-]+)",
	"^https?://[A-Za-z0-9%.%-]*%.?youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
	"^https?://[A-Za-z0-9%.%-]*%.?youtube%.com/v/([A-Za-z0-9_%-]+)",
}

local all_patterns = {}

-- Appends time modifier patterns to each pattern
for k,p in pairs(raw_patterns) do
	local hash_letter = "#"
	if k == 1 then
		hash_letter = "?"
	end
	table.insert(all_patterns, p .. hash_letter .. "t=(%d+)m(%d+)s")
	table.insert(all_patterns, p .. hash_letter .. "t=(%d+)")
	table.insert(all_patterns, p)
end

wyozimc.AddProvider({
	Name = "Youtube",
	UrlPatterns = all_patterns,
	QueryMeta = function(data, callback, failCallback)
		local uri = data.Matches[1]
		
		local url = Format("http://gdata.youtube.com/feeds/api/videos/%s?alt=json", uri)

		wyozimc.Debug("Fetching query for " .. uri .. " from " .. url)

		http.Fetch(url, function(result, size)
			if size == 0 then
				failCallback("HTTP request failed (size = 0)")
				return
			end

			local data = {}
			data["URL"] = "http://www.youtube.com/watch?v=" .. uri
			
			local jsontbl = util.JSONToTable(result)

			if jsontbl and jsontbl.entry then
				local entry = jsontbl.entry
				data.Title = entry["title"]["$t"]
				data.Duration = tonumber(entry["media$group"]["yt$duration"]["seconds"])
			else
				data.Title = "ERROR"
				data.Duration = 60 -- lol wat
			end

			callback(data)

		end)
	end,
	TranslateUrl = function(data, callback)
		local vqstring = ""
		if cvars.Bool("wyozimc_highquality") then
			vqstring = "hd1080"
		end

		local startat = data.StartAt or 0
		callback(string.format("http://wyozi.github.io/wmc/players/youtube.html?vid=%s&start=%d", wyozimc.JSEscape(data.Matches[1]), startat))
	end,
	ParseUData = function(udata)
		if udata.Matches[2] and udata.Matches[3] then -- Minutes and seconds
			udata.StartAt = math.Round(tonumber(udata.Matches[2])) * 60 + math.Round(tonumber(udata.Matches[3]))
		elseif udata.Matches[2] then -- Seconds
			udata.StartAt = math.Round(tonumber(udata.Matches[2]))
		end
	end,
	FuncSetVolume = function(volume)
		return [[try {
		document.getElementById('player1').setVolume(]] .. (volume*100) .. [[);
		} catch (e) {}
		]]
	end,
	FuncQueryElapsed = function()
		return [[try {
			var player = document.getElementById('player1');
			var state = player.getPlayerState();
			if (state == 0) // ended
				wmc.SetElapsed(player.getDuration() + 2) // Stupid but works?
			else
				wmc.SetElapsed(player.getCurrentTime());
		} catch (e) {
		}
		]]
	end
})