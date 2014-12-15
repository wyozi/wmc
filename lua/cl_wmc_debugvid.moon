-- Handles drawing debug video output to the screen, if a convar is set

debug_mat = Material("models/weapons/v_toolgun/screen")
local debug_rt

wyozimc.DebugContainers = wyozimc.DebugContainers or {}

debug_vid_width = 1280 * (2/5)
debug_vid_height = 720 * (2/5)

hook.Add "HUDPaint", "WyoziMCDebugVid", ->
	if not cvars.Bool("wyozimc_debugvid")
		return

	if not debug_rt
		debug_rt = GetRenderTarget("WMCDebugRT", 1280, 720)

	for k,c in pairs(wyozimc.DebugContainers)

		-- Draw visualization to a render target. Expensive, but doesn't matter; this is only for debugging and using RT fixes problems with
		-- coordinate system origins etc
		render.PushRenderTarget(debug_rt)

		do
			render.Clear(0, 0, 0, 255)

			cam.Start2D()

			do
				render.PushFilterMin(TEXFILTER.LINEAR)
				render.PushFilterMag(TEXFILTER.LINEAR)

				c\draw_vis{}

				render.PopFilterMin()
				render.PopFilterMag()

			cam.End2D()

		render.PopRenderTarget()

		dvw, dvh = debug_vid_width, debug_vid_height

		debug_mat\SetTexture("$basetexture", debug_rt)
		surface.SetMaterial(debug_mat)
		surface.DrawTexturedRect((k-1)*dvw, 0, dvw, dvh)

		surface.SetDrawColor(255, 255, 255, 200)
		surface.DrawRect((k-1)*dvw, dvh, dvw, 20)

		clr = HSVToColor(k*120, 0.95, 0.5)

		surface.SetDrawColor(clr)
		surface.DrawRect((k-1)*dvw, dvh, 5, 20)

		draw.SimpleText(c\get_debug_id!, "DermaDefaultBold", (k-1)*dvw + 10, dvh+10, Color(0, 0, 0), _, TEXT_ALIGN_CENTER)
