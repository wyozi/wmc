
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

local hud_cache

local function DrawPlayerHUD(data)
	-- Positions and dimensions
	local x, y, w, h = data.x, data.y, data.w, data.h
	-- Random variables
	local title = data.title
	local info_msg, error_msg = data.info_msg, data.error_msg
	-- Progress bar stuff
	local progress = data.progress
	local progress_label = data.progress_label

	-- If info_msg or error_msg exists, the box needs to have some height added
	if info_msg or error_msg then
		h = h + 20
	end

	local bg_clr = hud_background_color
	local outline_clr = hud_outline_color
	local text_clr = hud_text_color
	local progbar_clr = hud_progressbar_color
	local progbar_outline_clr = hud_progressbar_outline_color

	-- Draw the background rectangle
	do
		surface.SetDrawColor(bg_clr.r, bg_clr.g, bg_clr.b, bg_clr.a*delayalpha)
		surface.DrawRect(x, y, w, h)
	end

	-- Draw outline
	if hud_drawoutline then
		surface.SetDrawColor(outline_clr.r, outline_clr.g, outline_clr.b, outline_clr.a*delayalpha)
		surface.DrawOutlinedRect(x, y, w, h)
	end

	-- Draw the title string
	do
		surface.SetTextColor(text_clr.r, text_clr.g, text_clr.b, text_clr.a*delayalpha)
		surface.SetFont("Trebuchet18Bold")

		local ts = surface.GetTextSize(title)

		surface.SetTextPos((x+w/2) - ts/2, y + 23)
		surface.DrawText(title)
	end

	-- Draw the elapsed progressbar
	do
		local progressbary = 5

		surface.SetDrawColor(progbar_clr.r, progbar_clr.g, progbar_clr.b, progbar_clr.a*delayalpha)
		surface.DrawRect(x + 5, y + progressbary, (w - 10) * progress, 15)

		if hud_progressbar_drawoutline then
			surface.SetDrawColor(progbar_outline_clr.r, progbar_outline_clr.g, progbar_outline_clr.b, progbar_outline_clr.a*delayalpha)
			surface.DrawOutlinedRect(x + 5, y + progressbary, w - 10, 15)
		end

		surface.SetFont("Trebuchet18")

		local t = progress_label

		local ts = surface.GetTextSize(t)
		surface.SetTextPos((x+w/2) - ts/2, progressbary-1)
		surface.DrawText(t)
	end

	if error_msg then
		surface.SetFont("CenterPrintText")
		local ts = surface.GetTextSize(error_msg)
		surface.SetTextPos((x+w/2) - ts/2, 45)
		surface.SetTextColor(255, 0, 0)
		surface.DrawText(error_msg)
	end

	-- Store data table to hud_cache local var. This is used to fade out HUD even after mediacontainer is dead
	hud_cache = data
end

hook.Add("HUDPaint", "WyoziMCDefaultHUD", function()
	if not wyozimc.ShowPlayingHUD then return end

	local mc = wyozimc.MainContainer
	if not mc then return end

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

	local error_msg, title

	-- Possibly get an error message we should show
	do
		-- TODO This doesn't work due to backend changes
		if mc then
			if mc.browser_flash_found == false then
				error_msg = "Warning! No flash player found. Music might not play."
			elseif mc.browser_zero_elapses and mc.browser_zero_elapses > 5 then
				error_msg = "Video might be blocked in your country."
			end
		end

		if pd.error_msg then
			error_msg = pd.error_msg
		end
	end

	title = qd.Title or "-unknown-"
	if mc.extras and mc.extras.Title then
		title = mc.extras.Title
	end

	local w, h = ScrW(), ScrH()
	local hw = 350	

	local prog_lbl = wyozimc.FormatTime(elapsed)
	if qd.Duration and qd.Duration ~= -1 then
		prog_lbl = prog_lbl .. " / " .. wyozimc.FormatTime(qd.Duration)
	end

	DrawPlayerHUD {
		x = w/2 - (350/2),
		y = 0,
		w = 350,
		h = 50,

		error_msg = error_msg,
		title = title,

		progress = gonefrac,
		progress_label = prog_lbl
	}
	
end)