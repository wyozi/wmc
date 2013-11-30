
-- CHANGE SETTINGS BELOW TO CHANGE PLAYER HUD APPEARANCE

local hud_background_color = Color(50, 50, 50, 50)

local hud_drawoutline = false
local hud_outline_color = Color(196, 136, 252)

local hud_text_color = Color(255, 255, 255, 255)

local hud_progressbar_color = Color(136, 196, 252)

local hud_progressbar_drawoutline = false
local hud_progressbar_outline_color = Color(255, 255, 255, 255)

-- END OF SETTINGS YOU SHOULD CHANGE

local delayalpha = 0

surface.CreateFont("Trebuchet18Bold", {
	font = "Trebuchet18",
	size = 18,
	weight = 500,
})

hook.Add("HUDPaint", "WyoziMCDefaultHUD", function()
	if not wyozimc.ShowPlayingHUD then return end

	local mc = wyozimc.MainContainer

	if mc:has_flag(wyozimc.FLAG_NO_HUD) then return end

	local pd = mc.play_data
	if not pd then return end

	local qd = pd.query_data
	if not qd then return end

	local elapsed = ( CurTime() - pd.started )
	local gonefrac = mc:get_played_fraction()

	local targetalpha = (gonefrac < 1) and 1 or 0
	delayalpha = math.Approach(delayalpha, targetalpha, 0.02)

	if delayalpha <= 0 then
		return
	end

	local w, h = ScrW(), ScrH()
	local hw = 350	

	local flash_found = true -- TODO

	local hh = flash_found and 50 or 70

	local clr = hud_background_color

	surface.SetDrawColor(clr.r, clr.g, clr.b, clr.a*delayalpha)
	surface.DrawRect(w/2 - hw/2, 0, hw, hh)

	if hud_drawoutline then
		clr = hud_outline_color

		surface.SetDrawColor(clr.r, clr.g, clr.b, clr.a*delayalpha)
		surface.DrawOutlinedRect(w/2 - hw/2, 0, hw, hh)
	end

	clr = hud_text_color

	surface.SetTextColor(clr.r, clr.g, clr.b, clr.a*delayalpha)

	surface.SetFont("Trebuchet18Bold")

	local ts = surface.GetTextSize(qd.Title or "-unknown-")

	surface.SetTextPos(w/2 - ts/2, 23)
	surface.DrawText(qd.Title or "-unknown-")

	local progressbary = 5

	clr = hud_progressbar_color

	surface.SetDrawColor(clr.r, clr.g, clr.b, clr.a*delayalpha)
	surface.DrawRect(w/2 - hw/2 + 5, progressbary, (hw - 10) * gonefrac, 15)

	if hud_progressbar_drawoutline then
		clr = hud_progressbar_outline_color

		surface.SetDrawColor(clr.r, clr.g, clr.b, clr.a*delayalpha)
		surface.DrawOutlinedRect(w/2 - hw/2 + 5, progressbary, hw - 10, 15)
	end

	surface.SetFont("Trebuchet18")

	local t = wyozimc.FormatSimpleTime(elapsed, "%02i:%02i")
	if qd.Duration and qd.Duration ~= -1 then
		t = t .. " / " .. wyozimc.FormatSimpleTime(qd.Duration, "%02i:%02i")
	end
	local ts = surface.GetTextSize(t)
	surface.SetTextPos(w/2 - ts/2, progressbary-1)
	surface.DrawText(t)

	surface.SetFont("CenterPrintText")

	if not flash_found and wyozimc.Provider and not wyozimc.Provider.UseGmodPlayer then
		local t = "Warning! No flash player found. Music might not play."
		local ts = surface.GetTextSize(t)
		surface.SetTextPos(w/2 - ts/2, 45)
		surface.SetTextColor(255, 0, 0)
		surface.DrawText(t)
	end
end)