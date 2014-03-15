class BASSMediaType extends wyozimc.BaseMediaType
	create: =>

	play: (url, opts) =>
		@loading = true
		sound.PlayURL(url, "", (chan)->
			if @terminateload
				chan\Stop!
				return
				
			@chan = chan
			@loading = false)

	destroy: =>
		if IsValid(@chan)
			@chan\Stop!

		if @loading
			@terminateload = true

wyozimc.AddMediaType("bass", BASSMediaType)