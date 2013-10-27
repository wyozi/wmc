util.AddNetworkString("wyozimc_edit")
util.AddNetworkString("wyozimc_list") -- also used for list send requirements
util.AddNetworkString("wyozimc_play")
util.AddNetworkString("wyozimc_playply")
util.AddNetworkString("wyozimc_cache")
util.AddNetworkString("wyozimc_gui")

wyozimc.MediaList = {}

wyozimc.ServerMediaList = wyozimc.CreateManipulator{persist_file = "wyozimedia.txt", unique = "Link", table_reference = wyozimc.MediaList}
wyozimc.ServerMediaList:Load()

function wyozimc.AddMedia(link, by)
	link = link:Trim()
	local media = wyozimc.GetMediaByLink(link)
	if media then
		by:ChatPrint("Media already found in Media List")
		return
	end
	local provider, udata = wyozimc.FindProvider(link)
	if not provider then
		by:ChatPrint("Trying to add link with no valid provider")
		return
	end
	media = {
		Title = "NOT FOUND",
		Link = link,
		AddedBy = by:SteamID() .. "|" .. by:Nick(),
		Date = os.time()
	}
	--table.insert(wyozimc.MediaList, media)

	provider.QueryMeta(udata, function(data)

		media.Title = data.Title
		wyozimc.ServerMediaList:Add(media)
		--wyozimc.ServerMediaList:Save()

		wyozimc.ChatText(by, Color(255, 127, 0), "[MediaPlayer] ", Color(255, 255, 255), "You added ", Color(252, 84, 84), data.Title)

		if wyozimc.ReportModifications then
			wyozimc.ChatText(_, Color(255, 127, 0), "[MediaPlayer] ", by, Color(255, 255, 255), " added ", Color(252, 84, 84), data.Title)
		end
		wyozimc.UpdateGuis()

	end, function(errormsg)
		by:ChatPrint("Failed to query metadata: " .. errormsg)
	end)
end

function wyozimc.GetMediaByLink(link)
	return wyozimc.ServerMediaList:GetByUnique(link)
end

function wyozimc.UpdateGuis(...)
	net.Start("wyozimc_edit")
		net.WriteString("requpd")
		--net.WriteTable({...})
	net.Broadcast()
end

function wyozimc.PlayFor(targ, url, ...)

	local flagtbl = {...}
	local flagint = 0
	for _,v in pairs(flagtbl) do
		flagint = bit.bor(flagint, v)
	end

	net.Start("wyozimc_play")
		net.WriteString(url or "")
		net.WriteUInt(flagint, 32)
	if targ then net.Send(targ) else net.Broadcast() end

	if not targ then
		SetGlobalString("wmc_playurl", url or "")
		SetGlobalInt("wmc_playflags", flagint)
		SetGlobalInt("wmc_playat", CurTime())
	end

	return true
end
function wyozimc.PlayForAll(url, ...)
	return wyozimc.PlayFor(_, url, ...)
end

function wyozimc.CacheFor(targ, url)
	net.Start("wyozimc_cache")
		net.WriteString(url or "")
	if targ then net.Send(targ) else net.Broadcast() end
end

function wyozimc.StopForAll(isSelfRequest) wyozimc.PlayForAll(nil, not isSelfRequest and wyozimc.FLAG_WAS_GLOBAL_REQUEST or 0) end

net.Receive("wyozimc_edit", function(le, cl)

	local ttype = net.ReadString()
	if ttype == "add" then
		local id = net.ReadString()

		if not wyozimc.HasPermission(cl, "Add") then cl:ChatPrint("No permission!") return end

		wyozimc.AddMedia(id, cl)
	elseif ttype == "del" then
		local id = net.ReadString()

		if not wyozimc.HasPermission(cl, "Delete") then cl:ChatPrint("No permission!") return end
		
		local media = wyozimc.GetMediaByLink(id)
		if not media then
			cl:ChatPrint("Not in media list?")
			return
		end

		if wyozimc.ReportModifications then
			wyozimc.ChatText(_, Color(255, 127, 0), "[MediaPlayer] ", cl, Color(255, 255, 255), " removed ", Color(252, 84, 84), media.Title)
		end

		wyozimc.ServerMediaList:Remove(media)
		--wyozimc.SaveMediaList()
		wyozimc.UpdateGuis()
	end
end)

net.Receive("wyozimc_list", function(le, cl)
	-- TODO throttle send

	local medialist = wyozimc.MediaList

	local mediacount = #medialist

	local iteration_size = 300
	local iterations = math.max(1, math.ceil(mediacount / iteration_size))

	wyozimc.Debug("MediaCount: ", mediacount, " Iterations: ", iterations)

	for i=0, (iterations-1) do
		local from_index = (i * iteration_size) + 1
		local to_index = math.min(from_index + iteration_size, ((i + 1) * iteration_size))
		local tablefragment = {unpack(medialist, from_index, to_index)}

		wyozimc.Debug("Sending iteration #", i, " which is from ", from_index, " to ", to_index, " (realsize ", #tablefragment, ")")

		net.Start("wyozimc_list")
			net.WriteBit(i == 0) -- ShouldEmptyPrevious
			net.WriteTable(tablefragment)
			wyozimc.Debug("Iteration #", i, " bytecount: ", net.BytesWritten())
		net.Send(cl)
	end

	--[[net.Start("wyozimc_list")
		net.WriteBit(1) -- ShouldEmptyPrevious
		net.WriteTable(medialist)
	net.Send(cl)]]

	wyozimc.CallHook("WyoziMCUpdateRequested", cl)
end)

net.Receive("wyozimc_playply", function(le, cl)
	if not wyozimc.HasPermission(cl, "PlayAll") then cl:ChatPrint("No permission!") return end

	local forply = net.ReadEntity()
	if not IsValid(forply) or not forply:IsPlayer() then cl:ChatPrint("Invalid forply!") return end

	local wsp = net.ReadString()

	wyozimc.PlayFor(forply, wsp)
end)

net.Receive("wyozimc_play", function(le, cl)
	if not wyozimc.HasPermission(cl, "PlayAll") then cl:ChatPrint("No permission!") return end

	local wsp = net.ReadString()

	local provider, udata, mediatitle

	if wsp and wsp ~= "" then
		provider, udata = wyozimc.FindProvider(wsp)
		if not provider then
			cl:ChatPrint("Trying to play media with no valid provider")
			return
		end
		
		local media = wyozimc.GetMediaByLink(wsp)
		if media then
			mediatitle = media.Title
		end
	end

	wyozimc.PlayForAll(wsp, wyozimc.FLAG_DIRECT_REQUEST)

	wyozimc.Debug("We should play ", mediatitle, " (", wsp , ")")

	if wsp == "" then
		wyozimc.ChatText(_, Color(255, 127, 0), "[MediaPlayer] ", cl, Color(255, 255, 255), " stopped all playing media.")
	else
		if mediatitle then
			wyozimc.ChatText(_, Color(255, 127, 0), "[MediaPlayer] ", cl, Color(255, 255, 255), " is playing ", Color(252, 84, 84), mediatitle, Color(255, 255, 255), ". " .. (wyozimc.LocalStopCommand and ("Type " .. tostring(wyozimc.LocalStopCommand) .. " to stop.") or ""))
		else
			provider.QueryMeta(udata, function(data)
				wyozimc.ChatText(_, Color(255, 127, 0), "[MediaPlayer] ", cl, Color(255, 255, 255), " is playing ", Color(252, 84, 84), data.Title, Color(255, 255, 255), ". " .. (wyozimc.LocalStopCommand and ("Type " .. tostring(wyozimc.LocalStopCommand) .. " to stop.") or ""))
			end, function(errormsg) end)
		end
	end
end)

hook.Add("PlayerSay", "WyoziMCChatHooks", function( ply, text, public )
	text = text:lower()
	if wyozimc.LocalStopCommand and text:StartWith(wyozimc.LocalStopCommand) then
		net.Start("wyozimc_play")
			net.WriteString("")
			net.WriteUInt(0, 32)
		net.Send(ply)
		timer.Simple(0, function() wyozimc.ChatText(ply, Color(255, 127, 0), "[MediaPlayer] ", Color(255, 255, 255), "Playing media stopped for you.") end)
	end
	if wyozimc.OpenGuiCommand and text:StartWith(wyozimc.OpenGuiCommand) then
		net.Start("wyozimc_gui")
			net.WriteBit(false)
		net.Send(ply)
	end
end)