
function wyozimc.ToolSettingsMenu(panel)
	panel:AddControl("CheckBox", {Label = "Enable WMC", Command = "wyozimc_enabled"})
	panel:AddControl("Slider", {Label = "Volume", Type = "Float", Min = "0", Max = "1", Command = "wyozimc_volume"})
	panel:AddControl("CheckBox", {Label = "Play media while game is unfocused", Command = "wyozimc_playwhenalttabbed"})
end

hook.Add("PopulateToolMenu", "WyoziMCToolMenuSettings", function()
	spawnmenu.AddToolMenuOption( "Utilities", "Wyozi Media Center", "WMC settings", "Settings", "", "", wyozimc.ToolSettingsMenu)
end)