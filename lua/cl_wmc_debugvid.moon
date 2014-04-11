
debug_mat = Material("models/weapons/v_toolgun/screen")
local debug_rt

hook.Add "HUDPaint", "WyoziMCDebugVid", ->
	if not cvars.Bool("wyozimc_debugvid")
		return

	if not debug_rt
		debug_rt = GetRenderTarget("WMCDebugRT", 512, 512)

	containers = {wyozimc.MainContainer}
	for k,c in pairs(containers)

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
