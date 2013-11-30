
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
		return [[<!DOCTYPE html><html><body>
	<video width="100%" height="100%" id="thevideo" autoplay>
		<source src="]] .. url .. [[" type="video/mp4">
	</video> 
	<script type="text/javascript">
		function setVideoVolume(vol) {
			document.getElementById("thevideo").volume = vol;
		}
		function seekVideo(seconds) {
			document.getElementById("thevideo").currentTime = seconds;
		}
		document.getElementById("thevideo").addEventListener("loadedmetadata", function() {
			 this.currentTime = ]] .. tostring(math.Round(data.StartAt or 0 * 1000)) .. [[;
		}, false);
	</script>
</body></html>]]
	end,
	FuncSetVolume = function(volume)
		return "setVideoVolume(" .. tostring(volume) .. ")"
	end
})