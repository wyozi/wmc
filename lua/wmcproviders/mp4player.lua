
wyozimc.AddProvider({
	Name = "MP4/FLV Player",
	UrlPatterns = {
		"^https?://(.*)%.mp4",
		"^https?://(.*)%.flv",
	},
	QueryMeta = function(data, callback, failCallback)
		callback({
			Title = data.WholeUrl:match( "([^/]+)$" )
		})
	end,
	SetHTML = function(data, url)
		local startat = (data.StartAt or 0)
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
					url: "]] .. url .. [[",
					start: ]] .. startat .. [[
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
		return hotomolo
	end,
	FuncSetVolume = function(volume)
		return "setVideoVolume(" .. tostring(volume) .. ")"
	end
})