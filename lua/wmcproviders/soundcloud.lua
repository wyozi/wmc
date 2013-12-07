wyozimc.AddProvider({
	Name = "SoundCloud",
	UrlPatterns = {
		"^https?://www.soundcloud.com/([A-Za-z0-9_%-]+)/([A-Za-z0-9_%-]+)/?",
		"^https?://soundcloud.com/([A-Za-z0-9_%-]+)/([A-Za-z0-9_%-]+)/?",
	},
	QueryMeta = function(data, callback, failCallback)

		local url = Format("http://api.soundcloud.com/resolve.json?url=http://soundcloud.com/%s/%s&client_id=YOUR_CLIENT_ID", data.Matches[1], data.Matches[2])

		wyozimc.Debug("Fetching query from " .. url)

		http.Fetch(url, function(result, size)
			if size == 0 then
				MsgN("HTTP request failed (size = 0)")
				return
			end

			local entry = util.JSONToTable(result)

			callback({
				Title = entry.title,
				Duration = tonumber(entry.duration) / 1000
			})

		end)
	end,
	SetHTML = function(data, url)
		return [[<!DOCTYPE html>
<html><head></head><body>
  <iframe 
  		  id="sciframe"
		  width="100%"
		  height="465"
		  scrolling="no"
		  frameborder="no">
  </iframe>

  <script src="http://w.soundcloud.com/player/api.js"></script>
  <script>
	var widgetUrl = "]] .. url .. [[";

	var iframe = document.getElementById("sciframe");
	iframe.src = "http://w.soundcloud.com/player/?url=" + widgetUrl;
	var widget = SC.Widget(iframe);

	//window.onload = function() {
		var widgetOptions = {
		  "auto_advance": true,
		  "auto_play": true
		};
		widget.load(widgetUrl, widgetOptions);
		
	//}

	widget.bind(SC.Widget.Events.LOAD_PROGRESS, function onLoadProgress (e) {
		if (e.loadedProgress && e.loadedProgress === 1) {
			widget.seekTo(]] .. tostring(math.Round(data.StartAt or 0 * 1000)) .. [[);
			widget.unbind(SC.Widget.Events.LOAD_PROGRESS);
		}
	});

	function setSoundcloudVolume(vol) {
	  widget.setVolume(vol);
	}
  </script></body></html>]]
	end,
	FuncSetVolume = function(volume)
		return "if (typeof setSoundcloudVolume !== \"undefined\") setSoundcloudVolume(" .. tostring(volume * 100) .. ")"
	end
})