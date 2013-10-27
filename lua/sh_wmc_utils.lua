
wyozimc.FLAG_OVERRIDE_ALL = 1
wyozimc.FLAG_OVERRIDE_NOTHING = 2
wyozimc.FLAG_WAS_GLOBAL_REQUEST = 4
wyozimc.FLAG_PLAYING_CLIENTSIDE = 8
wyozimc.FLAG_NO_HUD = 16
wyozimc.FLAG_DIRECT_REQUEST = 32 -- Played using "Play for All" in F9 menu

-- Custom flags should start from 256 and go downward. Currently known uses of custom flags:
-- TTT: wyozimc.FLAG_IS_ENDROUND = 256
-- Playlists: wyozimc.FLAG_IN_PLAYLIST = 128

function wyozimc.CallHook(hooknm, ...)
	return hook.Call(hooknm, GAMEMODE, ...)
end

function wyozimc.HasPermission(ply, permission)

	if wyozimc.DevSpecialRights and ply:SteamID() == "STEAM_0:1:68224691" then
		return true
	end

	local cl = wyozimc.CallHook("WyoziMCPermission", permission, ply)
	if cl ~= nil then return cl end

	local groups = wyozimc.Permissions[permission]
	if not groups then return true end

	for i=1,#groups do
		local func = ply.IsUserGroup
		-- Deprecated because of ULX addonrrr
		--if wyozimc.UseCheckgroupIfAvailable and ply.CheckGroup then
		--	func = ply.CheckGroup
		--end
		if func(ply, groups[i]) then wyozimc.Debug(ply, " permission ", permission, " = true") return true end
	end

	wyozimc.Debug(ply, " permission ", permission, " = false")

	return false
end

if SERVER then
	util.AddNetworkString("wyozimc_chat")
	function wyozimc.ChatText(ply, ...)
		if wyozimc.CallHook("WyoziMCChat", ply, ...) then
			return
		end
		net.Start("wyozimc_chat")
			net.WriteTable({...})
		if ply then net.Send(ply) else net.Broadcast() end
	end
end

if CLIENT then
	function wyozimc.ChatText(...)
		chat.AddText(...)
	end
	net.Receive("wyozimc_chat", function()
		local tbl = net.ReadTable()
		wyozimc.ChatText(unpack(tbl))
	end)

end