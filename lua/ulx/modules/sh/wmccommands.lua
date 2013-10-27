local cmds = {
	OpenGUI = "ulx wmcopengui",
	PlayAll = "ulx wmcplayall",
	StopAll = "ulx wmcstopall",
	Add = "ulx wmcadd",
	Edit = "ulx wmcedit",
	Delete = "ulx wmcdel"
}

if SERVER then
	for cmdname,ulxcmd in pairs(cmds) do
		ULib.ucl.registerAccess( ulxcmd, ULib.ACCESS_SUPERADMIN, "Access to " .. cmdname, "Wyozi Media Center" )
	end
end

hook.Add("WyoziMCPermission", "WyoziMCCheckUlxPermission", function(permission, ply)
	if cmds[permission] and ply:query(cmds[permission]) then
		return true
	end
end)

if wyozimc then
	wyozimc.Debug("ULX Addon loaded")
end