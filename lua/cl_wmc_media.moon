
-- Used for wyozimc_debugvid
wyozimc.DebugVidSlots = wyozimc.DebugVidSlots or {}
get_free_dvs = ->
	i = 0
	while true
		if not wyozimc.DebugVidSlots[i]
			return i
		i += 1

dvs_count = 0

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

		if not is_valid(@browser_debug_comp)
			debug_comp = vgui.Create("DPanel")
			with debug_comp
				\SetPos(0, 0)
				\SetSize(@custom_browser_width or 512, @custom_browser_height or 287)
				\SetVisible(false)
			@browser_debug_comp = debug_comp

			--debug_comp.Think = =>
			--	set_vis_state = cvars.Bool("wyozimc_debugvid")
			--	@SetVisible(set_vis_state)

			id_lbl = vgui.Create("DLabel", debug_comp)
			id_lbl\Dock(BOTTOM)
			id_lbl\SetText(@get_debug_id!)
			id_lbl\SetColor(Color(0, 0, 0))

			browser_painter = vgui.Create("DPanel", debug_comp)
			browser_painter\Dock(FILL)

			browser_painter.Paint = (pself, w, h) ->
				if not is_valid @player_browser
					debug_comp\Remove!
					return
				@player_browser\UpdateHTMLTexture()
				surface.SetMaterial(@player_browser\GetHTMLMaterial!)
				surface.SetDrawColor(255, 255, 255)
				surface.DrawTexturedRect(0, 0, w, h)

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

		if is_valid(@player_browser)
			@player_browser\SetHTML("Hello!") -- Cheaper than to destroy and recreate later
		if is_valid(@sound_channel) and not dont_destroy_soundchan
			@sound_channel\Stop()

		@play_data = nil

		@post_stop(global_request)
		wyozimc.CallHook("WyoziMCGlobalPostStop", self, global_request)

	destroy: =>
		if is_valid(@player_browser)
			@player_browser\Remove!
		if is_valid(@player_browser_panel)
			@player_browser_panel\Remove!

			if @debugvid_slot
				wyozimc.DebugVidSlots[@debugvid_slot] = nil
				dvs_count -= 1

		if is_valid(@sound_channel)
			@sound_channel\Stop()

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

		if wyozimc.CallHook("WyoziMCGlobalPrePlay", self, provider, url, udata, flags)
			return true, "Terminated by WyoziMCGlobalPrePlay hook"

		-- Stop old media. Needed so both soundchannel and html stop
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
			udata: udata

		@browser_zero_elapses = 0

		wdebug("Playing ", url, " with flags ", bit.tohex(flags), " & startat ", startat)

		-- Verify that the browser actually exists
		@verify_components_exist!

		future = @create_future!

		-- If it's possible to query for data, we should do it here
		if provider.QueryMeta
			provider.QueryMeta udata, (data) ->
				wdebug("QueryData received: (title=" , data.Title, " d=", data.Duration, ")")
				if not @play_data
					return
				if future.done_cb
					future.done_cb(data)
				@play_data.query_data = data,
				(errormsg) ->
			
		-- Finally, time to actually play something
		
		if provider.UseGmodPlayer -- We want to use the built-in BASS
			if cached_handle = @get_cached_bass_handle(url) -- See if there's a cached handle
				cached_handle\Play()
				wdebug("Playing ", url, " using a cached BASS handle")
			else
				-- No cache, load manually
				sound.PlayURL url, "noplay", (chan) ->
					if not is_valid(chan)
						return wdebug("Invalid BASS handle received for ", url)

					-- Technically is_valid(sound_channel) shouldnt happen because of @stop(), but if we somehow loaded
					--  a new bass handle while this one was loading, we clear the new one.
					old_chan = @sound_channel
					if is_valid(old_chan)
						old_chan\Stop()

					@sound_channel = chan
					chan\Play()
					wdebug("Playing ", url, " using BASS")

		elseif provider.SetHTML -- if provider.SetHTML exists, the provider wants us to use HTML instead of an url
			html_source = provider.SetHTML(udata, url)
			@player_browser\SetHTML(html_source)
			wdebug("Playing ", url, " using SetHTML")
		else
			wdebug("Translating url ", url)
			provider.TranslateUrl udata, (url, newstartat) ->
				udata.StartAt = udata.StartAt or newstartat -- Providers might parse startat data from the link, so this required
				@player_browser\OpenURL(url)
				wdebug("Playing translated ", url, " normally")

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

				--if cur_vol ~= @last_volume
					--wdebug("[VOLUME] ", cur_vol)

				if is_valid(@player_browser)
					@player_browser\QueueJavascript(set_vol(cur_vol))
				if is_valid(@sound_channel)
					set_vol(cur_vol, @sound_channel)

				@last_volume = cur_vol

		if play_data
			if (not @last_elapsed_query or @last_elapsed_query < CurTime() - 1)
				@query_elapsed! -- Validity of FuncQueryElapsed is checked inside query_elapsed
				@last_elapsed_query = CurTime()

			if elapsed = @play_data.browser_vid_elapsed
				play_data.started = CurTime() - elapsed

		-- This snippet sets the debug html panel visible or hidden based on wyozimc_debugvid.
		-- TODO it shouldn't be here
		if is_valid(@browser_debug_comp) and @browser_debug_comp\IsVisible() ~= cvars.Bool("wyozimc_debugvid")

			set_vis_state = cvars.Bool("wyozimc_debugvid")

			@browser_debug_comp\SetVisible(set_vis_state)

			-- Debugvids use a slot system: each musiccontainer has their own slot and these snippets are responsible
			--  for assigning those slots. This slot system allows debugging multiple videos at once
			--  TODO: add some kind of label to the browser panel indicating which debugvid it is
			if set_vis_state
				@debugvid_slot = get_free_dvs!
				wyozimc.DebugVidSlots[@debugvid_slot] = self
				dvs_count += 1
			else
				if @debugvid_slot
					wyozimc.DebugVidSlots[@debugvid_slot] = nil
					dvs_count -= 1
				@debugvid_slot = nil

		if @last_tracked_dvs ~= dvs_count and is_valid(@browser_debug_comp) and @browser_debug_comp\IsVisible()

			if @debugvid_slot > 0 and not wyozimc.DebugVidSlots[@debugvid_slot - 1]
				old_dvs = @debugvid_slot
				@debugvid_slot -= 1
				wyozimc.DebugVidSlots[old_dvs] = nil
				wyozimc.DebugVidSlots[@debugvid_slot] = self

			xpos = @debugvid_slot % 2
			ypos = math.floor(@debugvid_slot / 2)
			@browser_debug_comp\SetPos(xpos*512, ypos*512)

			@last_tracked_dvs = dvs_count


wyozimc.MediaContainer = MediaContainer