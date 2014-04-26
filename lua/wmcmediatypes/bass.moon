class BASSMediaType extends wyozimc.BaseMediaType
	create: (query_func)=>
		@qf = query_func

	play: (url, opts) =>
		@loading = true

		sound_opts = {}
		if opts.noblock
			table.insert(sound_opts, "noblock")

		sound.PlayURL(url, table.concat(sound_opts, " "), (chan)->
			if not IsValid(chan)
				wyozimc.Debug("Failed to play sound!")
				@loading = false
				return

			if @terminateload
				chan\Stop!
				return

			@chan = chan
			@loading = false
			
			if opts.noblock and opts.startat
				@chan\SetTime(opts.startat)

			@qf!)

	draw_visualization: (data)=>
		@fft_vals = @fft_vals or {}

		if not IsValid(@chan)
			return

		val_count = @chan\FFT(@fft_vals, FFT_1024 )

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