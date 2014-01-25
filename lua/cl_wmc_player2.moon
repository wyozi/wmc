export wyozimc

wyozimc_enabled = CreateConVar("wyozimc_enabled", "1", FCVAR_ARCHIVE)
wyozimc_volume = CreateConVar("wyozimc_volume", wyozimc.DefaultVolume and tostring(wyozimc.DefaultVolume) or "0.5", FCVAR_ARCHIVE)
wyozimc_playwhenalttabbed = CreateConVar("wyozimc_playwhenalttabbed", "0", FCVAR_ARCHIVE)
wyozimc_ignoreglobalplays = CreateConVar("wyozimc_ignoreglobalplays", "0", FCVAR_ARCHIVE)
wyozimc_debugvid = CreateConVar("wyozimc_debugvid", "0", FCVAR_ARCHIVE)

wyozimc_highquality = CreateConVar("wyozimc_highquality", "0", FCVAR_ARCHIVE)

wyozimc_bassvolmapping = CreateConVar("wyozimc_bassvolmapping", "1", FCVAR_ARCHIVE)

wyozimc.GetMasterVolume = (is_bass_module) ->
	curvolume = wyozimc_volume\GetFloat()
	if is_bass_module
		curvolume *= wyozimc_bassvolmapping\GetFloat()
	if not wyozimc_playwhenalttabbed\GetBool() and not system.HasFocus()
		curvolume = 0
	return curvolume

-- Used for cached BASS handles
wyozimc.CachedMedia = {}

class MainMediaContainer extends wyozimc.MediaContainer
	-- Return true here to prevent starting media
	handle_flags: (url, flags) =>

		if flags and bit.band(flags, wyozimc.FLAG_OVERRIDE_NOTHING) == wyozimc.FLAG_OVERRIDE_NOTHING
			return true, "Flags contain FLAG_OVERRIDE_NOTHING"

		if wyozimc_ignoreglobalplays\GetBool() and bit.band(flags, wyozimc.FLAG_DIRECT_REQUEST) == wyozimc.FLAG_DIRECT_REQUEST
			return true, "Direct (serverside) request and we have global plays disabled"

	-- Return true here to prevent starting media
	pre_play: (url, provider, udata, flags) =>
		if wyozimc.CallHook("WyoziMCPrePlay", provider, url, udata, flags)
			return true, "Terminated by WyoziMCPrePlay hook"

	post_play: (url, provider, udata, flags) =>
		wyozimc.CallHook("WyoziMCPostPlay", url, provider, udata, flags)

	-- Return true here to prevent stopping media
	pre_stop: (global_request) =>
		if wyozimc.CallHook("WyoziMCPreStop", global_request)
			return true, "Terminated by hook"

	post_stop: (global_request) =>
		wyozimc.CallHook("WyoziMCPostStop", global_request)

	-- Return a fraction 0 - 1 what volume should we have. Optinally return true as second return value to ignore master volume
	get_volume: =>

	get_debug_id: =>
		"MainContainer"

	-- If you want to cache BASS handles, this'd be a good place to return them It's assumed that bass handles
	--  are cleared after being return from here
	get_cached_bass_handle: (url) => 
		if handle = wyozimc.CachedMedia[url]
			wyozimc.CachedMedia[url] = nil
			return handle

wyozimc.MainContainer = wyozimc.MainContainer or MainMediaContainer!

concommand.Add("wyozimc_refreshmc", ->
	wyozimc.MainContainer\destroy()
	wyozimc.MainContainer = MainMediaContainer!)

hook.Add "Think", "WyoziMCMaintainMainVolume", ->
	--MsgN(wyozimc.MainContainer)
	wyozimc.MainContainer\volume_think!

-- Override some of the old global functions

wyozimc.PlayUrl = (url, startat, flags) ->
	wyozimc.MainContainer\play_url(url, startat, flags)

wyozimc.GetPlayedFraction = ->
	wyozimc.MainContainer\get_played_fraction!

wyozimc.IsPlaying = ->
	wyozimc.MainContainer\is_playing!

wyozimc.Stop = (global_request) ->
	wyozimc.MainContainer\stop(global_request)

net.Receive "wyozimc_play", ->
	url = net.ReadString()
	flags = net.ReadUInt(32)
	if url == ""
		wyozimc.Debug("Got empty url, assuming we need to stop. Flags: " .. bit.tohex(flags))
		wyozimc.Stop(bit.band(flags, wyozimc.FLAG_WAS_GLOBAL_REQUEST) == wyozimc.FLAG_WAS_GLOBAL_REQUEST)
	else
		wyozimc.Debug("Received ", url, " to play on client. Flags: " .. bit.tohex(flags))
		wyozimc.PlayUrl(url, _, flags)

net.Receive "wyozimc_cache", ->
	url = net.ReadString()
	
	provider, udata = wyozimc.FindProvider(url)
	if not provider
		ErrorNoHalt("Trying to cache something with no provider: " .. tostring(url))
		return

	if not provider.UseGmodPlayer
		wyozimc.Debug("Trying to cache invalid provider: only GmodPlayer sounds can be cached!")
		return

	sound.PlayURL url, "noplay", (chan) ->
		if IsValid(chan)
			wyozimc.CachedMedia[url] = chan
			wyozimc.Debug("Cached ", url, " using GmodPlayer")
		else
			wyozimc.Debug("GModplayer Cached channel nonvalid for ", url)

concommand.Add "wyozimc_stop", ->
	wyozimc.Stop()

hook.Add "InitPostEntity", "WyoziMCPlayLate", ->
	url, flags, start = GetGlobalString("wmc_playurl"), GetGlobalInt("wmc_playflags"), GetGlobalInt("wmc_playat")
	if url and url ~= ""
		wyozimc.PlayUrl(url, CurTime() - start, flags)