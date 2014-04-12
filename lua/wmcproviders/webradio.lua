wyozimc.AddProvider({
	Name = "Online Radio",
	UrlPatterns = {
		"^https?://(.*)%.pls"
	},
	QueryMeta = function(udata, callback, failCallback)
		callback({
			Title = udata.WholeUrl:match( "([^/]+)$" ),
			Duration = -1 -- streaming
		})
	end,
	MediaType = "bass",
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