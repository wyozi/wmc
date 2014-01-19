
local wyozimc_dontshownews = CreateConVar("wyozimc_dontshownews", "0", FCVAR_ARCHIVE) 

hook.Add("WyoziMCTabs", "WyoziMCAddSettingsTab", function(dtabs)

	local padding = dtabs:GetPadding()

	padding = padding * 2

	local dsettings = vgui.Create("DPanelList", dtabs)
	dsettings:StretchToParent(0,0,padding,0)
	dsettings:EnableVerticalScrollbar(true)
	dsettings:SetPadding(10)
	dsettings:SetSpacing(10)

	do
		local dgui = vgui.Create("DForm", dsettings)
		dgui:SetName("General settings")

		local cb = nil

		dgui:CheckBox("Enable WMC", "wyozimc_enabled")

		dgui:CheckBox("Play music even if game is unfocused", "wyozimc_playwhenalttabbed")

		dgui:CheckBox("Don't play globally started (using Play for All) media", "wyozimc_ignoreglobalplays")

		dgui:CheckBox("Prefer high quality videos. Might slow down video loading time!", "wyozimc_highquality")

		dgui:CheckBox("Enable debug mode", "wyozimc_debug")

		dgui:CheckBox("Enable video debug mode", "wyozimc_debugvid")

		dsettings:AddItem(dgui)

	end

	wyozimc.CallHook("WyoziMCAddToSettings", dsettings)

	dtabs:AddSheet( "Settings", dsettings, "icon16/wrench_orange.png", false, false, "WMC related settings" )
end)

local function LoadWmcNews()
	if not LocalPlayer():IsSuperAdmin() then return end
	if cvars.Bool("wyozimc_dontshownews") then return end

	http.Fetch("http://gmod.icemist.co/wmcnews.php", function(data)
		local tbl = util.JSONToTable(data)
		if not tbl then return end
		
		local curtime = os.time()
		for _,new in pairs(tbl) do
			if tonumber(new.time) > curtime-3600 then
				chat.AddText(Color(255, 127, 0), "[WyoziMediaPlayer News] ", Color(255, 127, 255), os.date("%x %X", tonumber(new.time)), Color(255, 255, 255),  ": ", new.title)
			end
		end
		if cvars.Bool("wyozimc_debug") then
			PrintTable(tbl)
		end
	end, function() end)
end
concommand.Add("wyozimc_d_shownews", LoadWmcNews)

-- Load WMC news
hook.Add("InitPostEntity", "WyoziMCGetNews", LoadWmcNews)