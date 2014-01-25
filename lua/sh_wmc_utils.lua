
wyozimc.FLAG_OVERRIDE_ALL = 1
wyozimc.FLAG_OVERRIDE_NOTHING = 2
wyozimc.FLAG_WAS_GLOBAL_REQUEST = 4
wyozimc.FLAG_PLAYING_CLIENTSIDE = 8
wyozimc.FLAG_NO_HUD = 16
wyozimc.FLAG_DIRECT_REQUEST = 32 -- Played using "Play for All" in F9 menu

-- Currently known uses of custom flags:
-- TTT: wyozimc.FLAG_IS_ENDROUND = 256
-- Playlists: wyozimc.FLAG_IN_PLAYLIST = 128
-- TTT Themes: wyozimc.FLAG_IS_TTTTHEME = 64

-- There's no space for other custom flags unfortunately. Refer to issue #20 on github

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

function wyozimc.FormatTime(total_seconds)
	if not total_seconds then total_seconds = 0 end

	local ms = (total_seconds - math.floor(total_seconds)) * 100
	total_seconds = math.floor(total_seconds)
	local s = total_seconds % 60
	total_seconds = (total_seconds - s) / 60
	local m = total_seconds % 60
	total_seconds = (total_seconds - m) / 60
	local h = total_seconds % 60

	if h > 0 then
		return string.format("%02i:%02i:%02i", h, m, s)
	end
	return string.format("%02i:%02i", m, s, ms)
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

	concommand.Add("wyozimc_luapatterntester", function()
		local frame = vgui.Create("DFrame")
		frame:SetSize(600, 400)

		local patterninput = frame:Add("DTextEntry")
		local testinput = frame:Add("DTextEntry")
		local resultlabel = frame:Add("DTextEntry")
		resultlabel:SetEnabled(false)
		resultlabel:SetMultiline(true)

		resultlabel:SetPos(10, 265)
		resultlabel:SetSize(580, 125)

		local function UpdatePatternTest()
			local matches = {(testinput:GetText()):match(patterninput:GetText())}
			local str = "Matches:\n"
			for k,v in pairs(matches) do
				str = str .. "#" .. k .. ": " .. v .. "\n"
			end
			resultlabel:SetText(str)
		end

		patterninput:SetPos(10, 30)
		patterninput:SetSize(580, 25)
		patterninput.OnTextChanged = UpdatePatternTest

		testinput:SetMultiline(true)
		testinput:SetPos(10, 60)
		testinput:SetSize(580, 200)
		testinput.OnTextChanged = UpdatePatternTest

		frame:Center()

		frame:MakePopup()
	end)

end