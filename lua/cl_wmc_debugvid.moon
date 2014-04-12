
debug_mat = Material("models/weapons/v_toolgun/screen")
local debug_rt

wyozimc.DebugContainers = {}

hook.Add "HUDPaint", "WyoziMCDebugVid", ->
	if not cvars.Bool("wyozimc_debugvid")
		return

	if not debug_rt
		debug_rt = GetRenderTarget("WMCDebugRT", 512, 512)

	for k,c in pairs(wyozimc.DebugContainers)

		-- Draw visualization to a render target. Expensive but doesn't matter; this is only for debugging and fixes problems with
		--	coordinate system origins etc
		render.PushRenderTarget(debug_rt)

		do
			render.Clear(0, 0, 0, 255)

			cam.Start2D()

			do
				c\draw_vis(w: 512, h: 512)

			cam.End2D()

		render.PopRenderTarget()

		debug_mat\SetTexture("$basetexture", debug_rt)
		surface.SetMaterial(debug_mat)
		surface.DrawTexturedRect((k-1)*256, 0, 256, 256)

		surface.SetDrawColor(255, 255, 255, 200)
		surface.DrawRect((k-1)*256, 256, 256, 20)

		clr = HSVToColor(k*120, 0.95, 0.5)

		surface.SetDrawColor(clr)
		surface.DrawRect((k-1)*256, 256, 5, 20)

		draw.SimpleText(c\get_debug_id!, "DermaDefaultBold", (k-1)*256 + 10, 259, Color(0, 0, 0))
