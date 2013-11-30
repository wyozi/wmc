wyozimc.AddProvider({
	Name = "Website",
	UrlPatterns = {
		"^https?://(.*)%.mp3",
		"^https?://(.*)%.ogg",
	},
	QueryMeta = function(data, callback, failCallback)
		callback({
			Title = data.WholeUrl:match( "([^/]+)$" )
		})
	end,
	TranslateUrl = function(data, callback)
		callback(data.WholeUrl)
	end,
	FuncSetVolume = function(volume, soundchannel)
		if soundchannel then
			soundchannel:SetVolume(volume)
		end
		return ""
	end,
	UseGmodPlayer = true
})