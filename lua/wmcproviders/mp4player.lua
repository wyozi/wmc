
wyozimc.AddProvider({
	Name = "MP4 Player",
	UrlPatterns = {
		"^https?://(.*)%.mp4",
	},
	QueryMeta = function(data, callback, failCallback)
		callback({
			Title = data.WholeUrl:match( "([^/]+)$" )
		})
	end,
	SetHTML = function(data, url)
		local startat = (data.StartAt or 0)
		
		return hotomolo
	end,
	MediaType = "web",
	PlayInMediaType = function(mtype, play_data)
		local data = play_data.udata

		local hotomolo = [[<!DOCTYPE html><html><head>
<script src="http://releases.flowplayer.org/js/flowplayer-3.2.12.min.js"></script>
</head><body>
<a style="display:block;width:100%;height:94%;"
    id="player">
</a>
	<script type="text/javascript">
		flowplayer("player", "http://releases.flowplayer.org/swf/flowplayer-3.2.16.swf", {
			plugins: {
				controls: null
			},
			playlist: [
				{
					url: "]] .. data.WholeUrl .. [[",
					start: 0
				}
			],
    		replayLabel: 'Finished'
		});

		function setVideoVolume(vol) {
			flowplayer().setVolume(vol);
		}
		function seekVideo(seconds) {
			flowplayer().seek(seconds);
		}
	</script>
</body></html>]]

		mtype.html:SetHTML(hotomolo)
	end,
	FuncSetVolume = function(mtype, volume)
		mtype.html:RunJavascript("setVideoVolume(" .. tostring(volume) .. ")")
	end
})