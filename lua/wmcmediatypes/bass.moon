map_bass_error = (errid, errname)->
	return switch errid
		when 2
			"Failed to open soundfile at URL"
		when 40
			"Timed out; try again later"
		when 41
			"Invalid format; try another quality/filetype?"
		else
			"#{error_code} #{error_name}"

class BASSMediaType extends wyozimc.BaseMediaType
	create: (query_func, mc)=>
		@qf = query_func
		@mc = mc

	play: (url, opts) =>
		@loading = true

		sound_opts = {}
		-- If we need to go to XX:XX mark in the media file, we need a noblock flag
		if opts.noblock
			table.insert(sound_opts, "noblock")

		sound.PlayURL(url, table.concat(sound_opts, " "), (chan, error_code, error_name)->
			if error_code or error_name
				@loading = false
				wyozimc.Debug("Failed to play sound: #{error_code} #{error_name}!")
				@mc\show_error("ERROR: #{map_bass_error(error_code, error_name)}")
				return

			if not IsValid(chan)
				@loading = false
				wyozimc.Debug("Failed to play sound: invalid soundchan!")
				@mc\show_error("ERROR: SoundChan invalid!")
				return

			if @terminateload
				chan\Stop!
				return

			@chan = chan
			@loading = false
			
			-- BROKEN
			--if opts.noblock and opts.startat
			--	@chan\SetTime(opts.startat)

			@qf!)

	draw_visualization: (data)=>
		@fft_vals = @fft_vals or {}

		if not IsValid(@chan)
			return

		val_count = @chan\FFT(@fft_vals, FFT_1024)

		space_width = data.w or 910
		space_height = data.h or 512

		vals_per_x = if val_count == 0
			1
		else
			space_width / val_count


		for i=1, val_count, math.ceil(vals_per_x) do
			surface.SetDrawColor(HSVToColor(i, 0.95, 0.5))

			h = @fft_vals[i]*space_height
			surface.DrawRect(i, (space_height-h), 1, h)

	destroy: =>
		if IsValid(@chan)
			@chan\Stop!

		if @loading
			@terminateload = true

wyozimc.AddMediaType("bass", BASSMediaType)