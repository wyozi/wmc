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
	FuncSetVolume = function(mtype, volume)
		if IsValid(mtype.chan) then
			mtype.chan:SetVolume(volume)
		end
	end,
	PlayInMediaType = function(mtype, play_data)
		local opts = {}
		mtype:play(play_data.url, opts)
	end,
})