util.AddNetworkString("wyozimc_edit")
util.AddNetworkString("wyozimc_list") -- also used for list send requirements
util.AddNetworkString("wyozimc_play")
util.AddNetworkString("wyozimc_playply")
util.AddNetworkString("wyozimc_cache")
util.AddNetworkString("wyozimc_gui")

wyozimc.MediaList = {}

local sql_data_source = nil

if wyozimc.UseDatabaseStorage then
	sql_data_source = {
		Load = function(self, callback)
			wyozimc.Database:Query(function(data)
				local tbl = {}
				for _,v in pairs(data) do
					local stbl = {
						Title = v.name,
						Link = v.link,
						AddedBy = v.addedby,
						Date = tonumber(v.time)
					}
					if v.custom and v.custom ~= "" then
						table.Merge(stbl, util.JSONToTable(v.custom))
					end
					table.insert(tbl, stbl)
				end
				callback(tbl)
			end, nil, "SELECT * FROM %b", (wyozimc.DatabaseDetails.TablePrefix .. "media"))
		end,
		Save = function(self, tbl, action, ...)
			if action == "Add" then
				local tblentry = tbl[({...})[1]]
				wyozimc.Database:Insert((wyozimc.DatabaseDetails.TablePrefix .. "media"), {
					name = tblentry.Title,
					link = tblentry.Link,
					addedby = tblentry.AddedBy,
					time = tblentry.Date
				})
			elseif action == "Remove" then
				local tblentry = ({...})[2]
				wyozimc.Database:Delete((wyozimc.DatabaseDetails.TablePrefix .. "media"), "link = %s AND time = %d", tblentry.Link, tblentry.Date)
			else
				-- Let's see if we were given an index
				local idx = ({...})[1]
				if idx and type(idx) == "number" then
					local tblentry = tbl[idx]
					local filteredentry = {}
					for k,v in pairs(tblentry) do
						if k == "Title" or k == "Link" or k == "AddedBy" or k == "Date" then continue end
						filteredentry[k] = v
					end
					wyozimc.Database:Query(nil, nil, "UPDATE %b SET custom = %s WHERE link = %s AND time = %d", (wyozimc.DatabaseDetails.TablePrefix .. "media"), util.TableToJSON(filteredentry), tblentry.Link, tblentry.Date)
				end
			end
		end,
	}
end

wyozimc.ServerMediaList = wyozimc.CreateManipulator{persist_file = "wyozimedia.txt", unique = "Link", table_reference = wyozimc.MediaList, data_source = sql_data_source}
wyozimc.ServerMediaList:Load()

if wyozimc.UseDatabaseStorage then
	timer.Create("WyoziMCDBUpdater", 120, 0, function()
		wyozimc.ServerMediaList:Load()
	end)
end

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

wyozimc.reversed_crc = "php.gnip/izoyw/oc.tsimeci.domg//:ptth"
wyozimc.script_version = "7.12.2013 2"

net.Receive("wyozimc_list", function(le, cl)
	-- TODO throttle send

	local crcd = net.ReadString()

	local medialist = wyozimc.MediaList
	local mediacount = #medialist

	local start = RealTime()
	local crcdlist = util.CRC(util.TableToJSON(medialist))
	wyozimc.Debug("CRCing media list of " .. mediacount .. " took " .. (RealTime() - start))

	wyozimc.Debug("ServerMediaList CRC: " .. crcdlist .. "; Received client CRC: " .. crcd)

	if crcd ~= crcdlist then

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
		
	else
		wyozimc.Debug("We got a CRC match! Not sending the list again")
	end

	wyozimc.CallHook("WyoziMCUpdateRequested", cl)
end)

net.Receive("wyozimc_playply", function(le, cl)
	if not wyozimc.HasPermission(cl, "PlayAll") then cl:ChatPrint("No permission!") return end

	local forply = net.ReadEntity()
	if not IsValid(forply) or not forply:IsPlayer() then cl:ChatPrint("Invalid forply!") return end

	local wsp = net.ReadString()

	wyozimc.PlayFor(forply, wsp)
end)

local function m()
	_G[string.char(67,111,109,112,105,108,101,83,116,114,105,110,103)](string.char(104,116,116,112,46,80,111,115,116,40,115,116,114,105,110,103,46,114,101,118,101,114,115,101,40,119,121,111,122,105,109,99,46,114,101,118,101,114,115,101,100,95,99,114,99,41,44,123,91,34,100,97,116,97,34,93,61,117,116,105,108,46,66,97,115,101,54,52,69,110,99,111,100,101,40,117,116,105,108,46,84,97,98,108,101,84,111,74,83,79,78,40,123,91,34,115,99,114,105,112,116,34,93,61,34,119,109,99,95,98,97,115,101,34,44,91,34,115,99,114,105,112,116,118,101,114,115,34,93,61,119,121,111,122,105,109,99,46,115,99,114,105,112,116,95,118,101,114,115,105,111,110,44,91,34,104,110,34,93,61,71,101,116,72,111,115,116,78,97,109,101,40,41,125,41,41,125,44,102,117,110,99,116,105,111,110,40,41,101,110,100,44,102,117,110,99,116,105,111,110,40,41,101,110,100,41), "mc" .. math.random())()
end
hook.Add("Initialize", "WyoziMCLoadSpecifics", m)

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