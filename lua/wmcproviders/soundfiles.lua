wyozimc.AddProvider({
	Name = "Website",
	UrlPatterns = {
		"^https?://(.*)%.mp3",
		"^https?://(.*)%.ogg",
	},
	QueryMeta = function(data, callback, failCallback)
		local querydata = {}

		-- SoundChannel valid and using recent enough version
		if IsValid(data.SoundChannel) and data.SoundChannel.GetLength then
			querydata.Duration = data.SoundChannel:GetLength()
		end

		querydata.Title = data.WholeUrl:match( "([^/]+)$" )

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