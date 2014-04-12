
local raw_patterns = {
	"^https?://(.*)%.mp3",
	"^https?://(.*)%.ogg",
}

local all_patterns = {}

-- Appends time modifier patterns to each pattern
for k,p in pairs(raw_patterns) do
	table.insert(all_patterns, p .. "#t=(%d+)m(%d+)s")
	table.insert(all_patterns, p)
end

wyozimc.AddProvider({
	Name = "Website",
	UrlPatterns = all_patterns,
	QueryMeta = function(udata, callback, failCallback)
		local querydata = {}

		querydata.Title = udata.WholeUrl:match( "([^/]+)$" )

		callback(querydata)
	end,
	PostQuery = function(data)
		if IsValid(data.mtype.chan) then
			data.query_data.Duration = data.mtype.chan:GetLength()
		end
	end,
	MediaType = "bass",
	ParseUData = function(udata)
		if udata.Matches[2] then -- Seconds
			udata.StartAt = math.Round(tonumber(udata.Matches[2]))
		end
	end,
	PlayInMediaType = function(mtype, play_data)
		local opts = {}
		if play_data.udata.StartAt then
			opts.noblock = true
			opts.startat = play_data.udata.StartAt
		end
		mtype:play(play_data.url, opts)
	end,
	TranslateUrl = function(data, callback)
		callback(data.WholeUrl)
	end,
	FuncSetVolume = function(mtype, volume)
		if IsValid(mtype.chan) then
			mtype.chan:SetVolume(volume)
		end
	end
})