
class Pool
	new: =>
		@items = {}

	new_object: =>

	obtain: =>
		if item = table.remove(@items, 1)
			return item
		return @new_object!


	free: (item) =>
		table.insert(@items, item)

class HTMLCompPool extends Pool
	new_object: =>
		comp = vgui.Create("DHTML")
		--with comp
			--\SetPaintedManually true
		wyozimc.Debug("[HTML-POOL] Created new DHTML comp " .. tostring(comp))
		comp

	free: (item)=>
		item\SetHTML("This browser component was freed at " .. os.time!)
		wyozimc.Debug("[HTML-POOL] Freed DHTML comp " .. tostring(item))
		super\free item

html_pool = HTMLCompPool()

class WebMediaType extends wyozimc.BaseMediaType
	create: =>
		@html = html_pool\obtain!

		with @html
			\SetPos(0, 0)
			\SetSize(512, 512)

			--\SetPaintedManually(true)

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

	destroy: =>
		html_pool\free(@html)

wyozimc.AddMediaType("web", WebMediaType)