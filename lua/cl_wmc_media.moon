-- For easy access
wdebug = wyozimc.Debug
is_valid = IsValid

-- MediaContainer is a full fledged media player. Used to make it easy to spawn new media players for darkrp entities or whatever.
-- MediaContainer should be extended.
class MediaContainer
	verify_components_exist: =>
		if not is_valid @player_browser_panel
			browser_panel = vgui.Create("DPanel")
			with browser_panel
				\SetPos(0, 0)
				\SetSize(@custom_browser_width or 512, @custom_browser_height or 287)
				\SetVisible(false)
			@player_browser_panel = browser_panel

		if not is_valid @player_browser
			browser = vgui.Create("DHTML", @player_browser_panel)
			with browser
				\SetPos(0, 0)
				\SetSize(@player_browser_panel\GetSize())

				\SetPaintedManually(true)

				\AddFunction "wmc", "SetElapsed", (elapsed) ->
					wyozimc.Debug("Setting elapsed from browser to " .. tostring(elapsed))
					if elapsed < 1
						@browser_zero_elapses += 1
					else
						@browser_zero_elapses = 0

					if @play_data
						@play_data.browser_vid_elapsed = math.Round(elapsed)

				\AddFunction "wmc", "UnableToPlay", (reason) ->
					wyozimc.Debug("Unable to play media because " .. tostring(reason))

				\AddFunction "wmc", "SetFlashStatus", (bool) ->
					@browser_flash_found = bool
					wyozimc.Debug("Setting flash status to " .. tostring(bool))

				@add_browser_funcs(browser)
					
				--\QueueJavascript [[var hasFlash = false;
				--	try {
				--	  var fo = new ActiveXObject('ShockwaveFlash.ShockwaveFlash');
				--	  if(fo) hasFlash = true;
				--	}catch(e){
				--	  if(navigator.mimeTypes ["application/x-shockwave-flash"] != undefined) hasFlash = true;
				--	}
				--	gmod.SetFlashStatus(hasFlash)]]

			@player_browser = browser

	add_browser_funcs: (browser) =>

	-- == HOOK METHODS == These should be overridden for additional functionality

	-- Return true here to prevent starting media
	handle_flags: (url, flags) =>

	-- Return true here to prevent starting media
	pre_play: (url, provider, udata, flags) =>

	post_play: (url, provider, udata, flags) =>

	-- Return true here to prevent stopping media
	pre_stop: (global_request) =>

	post_stop: (global_request) =>

	-- Return a fraction 0 - 1 what volume should we have. Optinally return true as second return value to ignore master volume
	get_volume: =>

	get_debug_id: =>
		"undefined"

	-- If you want to cache BASS handles, this'd be a good place to return them It's assumed that bass handles
	--  are cleared after being return from here
	get_cached_bass_handle: (url) => 

	-- == END HOOK METHODS ==

	-- @param global_request  True if stopping was initiated serverside
	stop: (global_request, dont_destroy_soundchan) =>
		handled_res, reason = @pre_stop(global_request)
		if handled_res == true
			wdebug("Stop prevented in pre_stop: ", reason)
			return
		if wyozimc.CallHook("WyoziMCGlobalPreStop", self, global_request)
			return true, "Terminated by WyoziMCGlobalPreStop hook"

		if pd = @play_data
			pd.mtype\destroy!

		@play_data = nil

		@post_stop(global_request)
		wyozimc.CallHook("WyoziMCGlobalPostStop", self, global_request)

	destroy: =>
		@stop!

	create_future: =>
		tbl = {}
		tbl.done = (callback) ->
			tbl.done_cb = callback
		return tbl

	play_url: (url, startat, flags = 0) =>
		if not cvars.Bool("wyozimc_enabled")
			return wyozimc.Debug("play_url prevented because wmc disabled")
		handled_res, reason  = @handle_flags(url, flags)
		if handled_res == true
			wdebug("Play prevented in handle_flags for ", url, ": ", reason)
			return

		-- Get the provider (e.g. YouTube or Vimeo) and data related to the provider
		provider, udata = wyozimc.FindProvider(url)
		if not provider then
			ErrorNoHalt("Trying to play something with no provider: " .. tostring(url))
			return

		-- Set StartAt
		udata.StartAt = math.Round(startat or udata.StartAt or 0)
		startat = udata.StartAt

		handled_res, reason  = @pre_play(url, provider, udata, flags)
		if handled_res == true
			wdebug("Play prevented in pre_play for ", url, ": ", reason)
			return

		mtype = wyozimc.CreateMediaType(provider.MediaType)
		if not mtype then
			ErrorNoHalt("Trying to create nonexistent mediatype: " .. tostring(provider.MediaType))
			return

		if wyozimc.CallHook("WyoziMCGlobalPrePlay", self, provider, url, udata, flags)
			return true, "Terminated by WyoziMCGlobalPrePlay hook"

		-- Stop old media.
		@stop!

		-- Save old play data in case we need it for something
		@old_play_data = @play_data

		-- To make sure that we set the volume again in volume_think
		@last_volume = nil

		-- Make a new table containing new play data
		@play_data =
			started: CurTime() - startat, 
			real_started: CurTime(),
			url: url,
			startat: startat,
			flags: flags,
			provider: provider,
			udata: udata,
			mtype: mtype

		@browser_zero_elapses = 0

		wdebug("Playing ", url, " with flags ", bit.tohex(flags), " & startat ", startat)

		-- Verify that the browser actually exists
		@verify_components_exist!

		-- To be returned from this function
		future = @create_future!

		-- This is a separate function so each media type can decide when to query
		query_meta = ->
			-- If it's possible to query for data, we should do it here
			wdebug("Querying meta for ", url, ": ", provider.QueryMeta)
			if provider.QueryMeta
				provider.QueryMeta @play_data, (data) ->
					wdebug("QueryData received: (title=" , data.Title, " d=", data.Duration, ")")
					if not @play_data
						return
					if future.done_cb
						future.done_cb(data)
					@play_data.query_data = data,
					(errormsg) ->
			
		-- Create objects etc required to play this media (this could be a HTML comp for a YT video)
		mtype\create(query_meta)

		-- Actually play the media in the media type
		provider.PlayInMediaType mtype, @play_data

		@post_play(url, provider, udata, flags)
		wyozimc.CallHook("WyoziMCGlobalPostPlay", self, provider, url, udata, flags)

		return future

	query_elapsed: =>
		if not is_valid(@player_browser)
			return
			
		if pd = @play_data
			if fqe = pd.provider.FuncQueryElapsed
				@player_browser\Call(fqe!)

	-- A number from 0 to 1, which is the percentage how far we are into the video
	get_played_fraction: =>
		play_data = @play_data
		if not play_data
			return

		if qd = play_data.query_data -- This sets qd to query_data if play_data is valid and has query_data
			elapsed_time = ( CurTime() - play_data.started )
			total_frac = qd.Duration == -1 and 0 or ( elapsed_time / (qd.Duration or 0) )
			return total_frac

	is_playing: =>
		if pf = @get_played_fraction!
			return pf < 1
		return false

	get_url: =>
		if pd = @play_data
			return pd.url

	has_flag: (flag)=>
		if pd = @play_data
			return bit.band(pd.flags or 0, flag) == flag

	draw_vis: (data)=>
		if pd = @play_data
			if mt = pd.mtype
				mt\draw_visualization(data)

	volume_think: =>

		-- FuncSetVol takes two arguments, cur_vol and (optionally) a sound channel
		-- If sound channel arg is present, it is set, otherwise a javascript snippet is returned
		play_data = @play_data
		if play_data and play_data.provider and play_data.provider.FuncSetVolume
			set_vol = play_data.provider.FuncSetVolume

			cur_vol, ignore_master = @get_volume!
			cur_vol = cur_vol or 1

			if not ignore_master
				cur_vol *= wyozimc.GetMasterVolume(@play_data.provider.UseGmodPlayer)

			-- If cur_vol isn't same as the volume in last tick or if media was started less than 2 seconds ago
			if cur_vol ~= @last_volume or @play_data.real_started > CurTime() - 2

				play_data.provider.FuncSetVolume(play_data.mtype, cur_vol)

				@last_volume = cur_vol

		if play_data
			if (not @last_elapsed_query or @last_elapsed_query < CurTime() - 1)
				@query_elapsed! -- Validity of FuncQueryElapsed is checked inside query_elapsed
				@last_elapsed_query = CurTime()

			if elapsed = @play_data.browser_vid_elapsed
				play_data.started = CurTime() - elapsed


wyozimc.MediaContainer = MediaContainer