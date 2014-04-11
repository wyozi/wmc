class BASSMediaType extends wyozimc.BaseMediaType
	create: (query_func)=>
		@qf = query_func

	play: (url, opts) =>
		@loading = true
		sound.PlayURL(url, "", (chan)->
			if @terminateload
				chan\Stop!
				return

			@chan = chan
			@loading = false

			@qf!)

	draw_visualization: (data)=>
		-- TODO visualize BASS handle using FFT
		surface.SetDrawColor(255, 127, 0)
		surface.DrawRect(0, 0, data.w or 512, data.h or 512)

	destroy: =>
		if IsValid(@chan)
			@chan\Stop!

		if @loading
			@terminateload = true

wyozimc.AddMediaType("bass", BASSMediaType)