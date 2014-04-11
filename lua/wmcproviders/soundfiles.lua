wyozimc.AddProvider({
	Name = "Website",
	UrlPatterns = {
		"^https?://(.*)%.mp3",
		"^https?://(.*)%.ogg",
	},
	QueryMeta = function(data, callback, failCallback)
		local querydata = {}

		if IsValid(data.mtype.chan) then
			querydata.Duration = data.mtype.chan:GetLength()
		end

		querydata.Title = data.udata.WholeUrl:match( "([^/]+)$" )

		callback(querydata)
	end,
	MediaType = "bass",
	PlayInMediaType = function(mtype, play_data)
		mtype:play(play_data.url)
	end,
	TranslateUrl = function(data, callback)
		callback(data.WholeUrl)
	end,
	FuncSetVolume = function(mtype, volume)
		if IsValid(mtype.chan) then
			mtype.chan:SetVolume(volume)
		end
	end,
	UseGmodPlayer = true
})