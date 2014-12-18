-- Now this is the good stuff.
-- MediaContainer class below is an abstract container, which can be used to create your own media players of all sorts.


-- For fast n' easy access
wdebug = wyozimc.Debug
is_valid = IsValid

-- MediaContainer is a full fledged media player. Used to make it easy to spawn new media players for darkrp entities or whatever.
-- MediaContainer should be extended by your own class. See cl_wmc_player2.moon for an example
class MediaContainer
	add_browser_funcs: (browser) =>

	-- == HOOK METHODS == These should be overridden for additional functionality

	--- Verifies that url can be played (name is misleading, yeah)
	-- @return prevent_play Should the media be prevented from playing
	-- @return reason If media player was prevented, why. Optional
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

		table.RemoveByValue(wyozimc.DebugContainers, self)

	destroy: =>
		@stop!

	create_future: =>
		tbl = {}
		tbl.done = (callback) ->
			tbl.done_cb = callback
		return tbl

	--- Can a media be played
	can_play: (url, flags)=>
		if not cvars.Bool("wyozimc_enabled")
			return false, "wmc is disabled"

		play_prevented, reason  = @handle_flags(url, flags)
		if play_prevented == true
			return false, reason

		return true

	--- Actually play a media file
	-- @param url Url to play
	-- @param startat The time to start the media at in seconds. Not guaranteed
	-- to work with all providers
	-- @param flags Optional flags. See sh_wmc_utils.lua
	play_url: (url, startat, flags = 0) =>
		can_play, reason = @can_play(url, flags)
		if not can_play
			return wyozimc.Debug("Prevented playing #{url} because #{reason}")

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

		-- To be returned from this function
		future = @create_future!

		-- This is a separate function so each media type can decide when to query
		query_meta = ->
			-- If it's possible to query for data, we should do it here
			wdebug("Querying meta for ", url, ": ", provider.QueryMeta)
			-- QueryMeta is used to query for metadata
			if provider.QueryMeta
				provider.QueryMeta udata, (data) ->
					wdebug("QueryData received: (title=" , data.Title, " d=", data.Duration, ")")
					if not @play_data
						return
					if future.done_cb
						future.done_cb(data)
					@play_data.query_data = data

					-- PostQuery used for queries after mtype has been created
					if provider.PostQuery
						provider.PostQuery @play_data, (errormsg) ->
							wdebug("QueryData failed: ", errormsg)


		-- Create objects etc required to play this media (this could be a HTML comp for a YT video)
		mtype\create(query_meta, self)

		-- Actually play the media in the media type
		provider.PlayInMediaType mtype, @play_data

		@post_play(url, provider, udata, flags)
		wyozimc.CallHook("WyoziMCGlobalPostPlay", self, provider, url, udata, flags)

		table.insert(wyozimc.DebugContainers, self)

		return future

	--- Returns a number from 0 to 1, which is the percentage how much of the
	-- media file is played. Returns -1, if it cannot be determined.
	get_played_fraction: =>
		if pd = @play_data
			if qd = pd.query_data
				if not qd.Duration or qd.Duration == -1
					return -1

				elapsed_time = (CurTime() - pd.started)
				return (elapsed_time / qd.Duration)
		return -1

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

	--- Draws visualization of media. Visualization is a rectangle with
	-- x: 0, y: 0, width: (data.w or internal value), height: (data.h or internal value)
	-- @param data Visualization parameters. Common keys: 'w' for width, 'h' for height
	draw_vis: (data)=>
		if pd = @play_data
			if mt = pd.mtype
				mt\draw_visualization(data)

	--- Displays an error message and stops the media after ´timeout´ seconds
	-- @param msg Error message to show on HUD
	show_error: (msg, timeout=5)=>
		if pd = @play_data
			pd.error_msg = msg
			timer.Simple(timeout, ()->
				@stop!)
			wdebug("Stopping media because of error message: #{msg}")

	--- The function that updates the media container's volume from local volume
	-- Just call this function in a Think hook or equivalent.
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
