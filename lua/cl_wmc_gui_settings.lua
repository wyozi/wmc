--[[
	Contains the "Settings" tab in WMC GUI. See end of the "WyoziMCTabs" hook for how to add your own setting entries.
]]

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
	--[[
		Example custom setting group:

		hook.Add("WyoziMCAddToSettings", "Example", function(dsettings)
			local dgui = vgui.Create("DForm", dsettings)
			dgui:SetName("Example settings")

			dgui:CheckBox("Checkbox", "example_cvar")

			dsettings:AddItem(dgui)
		end)

		See http://wiki.garrysmod.com/page/Category:DForm
	]]

	dtabs:AddSheet( "Settings", dsettings, "icon16/wrench_orange.png", false, false, "WMC related settings" )
end)
