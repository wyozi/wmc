
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

-- Use 16:9 aspect ratio
vis_pref_width, vis_pref_height = 1280, 720

class WebMediaType extends wyozimc.BaseMediaType
	create: (query_func)=>
		@html = html_pool\obtain!

		with @html
			\SetPos(0, 0)
			\SetSize(vis_pref_width, vis_pref_height)

			\SetPaintedManually(true)
			\SetVisible(false)

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

		query_func!

	draw_visualization: (data)=>
		with @html
			\UpdateHTMLTexture()

			mat = \GetHTMLMaterial()

			-- HTMLMat dimensions are constrained to powers of two, so we use UV
			-- and fraction of wanted dimensions and PoT dimensions to get correct scaling

			w_frac, h_frac = vis_pref_width / mat\Width!, vis_pref_height / mat\Height!

			surface.SetMaterial(mat)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawTexturedRectUV(0, 0, data.w or vis_pref_width, data.h or vis_pref_height, 0, 0, w_frac, h_frac)

	destroy: =>
		html_pool\free(@html)

wyozimc.AddMediaType("web", WebMediaType)
