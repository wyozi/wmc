
-- This is the panel shown in the "Gutter" column of media list (the first column with icons etc)
function wyozimc.CreateGutterPanel(v)
	local p = vgui.Create("DPanel")
	p:SetDrawBackground(false)
	p:SetMouseInputEnabled(false)

	local dpl = p:Add("DPanelList")
	dpl:EnableHorizontal(true)
	dpl:SetMouseInputEnabled(false)
	dpl:Dock(FILL)

	dpl.GutterStr = ""

	wyozimc.CallHook("WyoziMCGutter", v, dpl)

	p.IconList = dpl

	return p
end

-- Searches youtube and returns the first link found with given search query.
-- Called by wyozimc.FindURL if a provider was not found.
function wyozimc.SearchYoutube(q, callback)
	local url = "https://gdata.youtube.com/feeds/api/videos?max-results=1&v=2&alt=json&q=" .. wyozimc.URLEscape(q)

	http.Fetch(url, function(result, size)
		if size == 0 then
			failCallback("HTTP request failed (size = 0)")
			return
		end

		local feed = util.JSONToTable(result)
		if not feed or not feed.feed then
			LocalPlayer():ChatPrint("Failed to load youtube data.")
			return
		end

		feed = feed.feed

		if not feed.entry or #feed.entry == 0 then
			LocalPlayer():ChatPrint("Zero results were returned by youtube. Try a more general search term.")
			return
		end

		callback(feed.entry[1].link[1].href)

	end)
end

-- Tried to find a provider for the given string. If no provider was found, tries to search from youtube
function wyozimc.FindURL(text, callback)
	text = text:Trim()
	local provider, udata = wyozimc.FindProvider(text)
	if not provider then
		if text:StartWith("http") then
			return false, "Invalid provider"
		end
		wyozimc.Debug("No provider for ", text, " but doesnt start with http so using youtube search")
		wyozimc.SearchYoutube(text, callback)
		return true
	end
	callback(text)
	return true
end

hook.Add("WyoziMCTabs", "WyoziMCAddMediaList", function(tabs, playnetmsg, passent)

	local frame = tabs.MainFrame

	local mediapane = vgui.Create("DPanel")
	mediapane:SetDrawBackground(false)

	local listscrl = mediapane:Add("DScrollPanel")
	listscrl:Dock(FILL)
	listscrl.pnlCanvas:Dock(FILL) -- Hack hack hack, makes content pane fill the scrollpane

	frame.MediaScroll = listscrl

	local list = vgui.Create("DListView")
	list:AddColumn(""):SetMaxWidth(40)
	list:AddColumn("Title")
	list:AddColumn("Information"):SetMaxWidth(180)
	list:AddColumn("Added By"):SetMaxWidth(128)
	list:AddColumn("Date"):SetMaxWidth(100)
	list:Dock(FILL)
	list:SetMultiSelect(false)
	list.OnRowRightClick = function(panel, line)

		local theline = list:GetLine(line)

		local theurl = theline.OrigLink

		local menu = DermaMenu()
		menu:AddOption("Copy Link", function() SetClipboardText(theurl) end):SetIcon( "icon16/page_white_copy.png" )

		menu:AddSpacer()

		wyozimc.AddPlayContextOptions(menu, frame, theurl, playnetmsg, passent)

		menu:AddSpacer()
		
		if wyozimc.HasPermission(LocalPlayer(), "Delete") then
			menu:AddOption("Delete", function()
				net.Start("wyozimc_edit") net.WriteString("del") net.WriteString(theurl) net.SendToServer() 
			end):SetIcon( "icon16/delete.png" )
		end
		if wyozimc.HasPermission(LocalPlayer(), "Edit") then
			menu:AddOption("Rename", function()
				Derma_StringRequest("Rename WMC Media",
					"What would you like to rename this media to?",
					theline:GetColumnText(2),
					function(text)
						net.Start("wyozimc_edit") net.WriteString("rename") net.WriteString(theurl) net.WriteString(text) net.SendToServer()
					end
				) 
			end):SetIcon( "icon16/book_edit.png" )
		end

		local tmedia
		for _,media in pairs(wyozimc.AllLines) do
			if media.Link == theurl then
				tmedia = media
				break
			end
		end

		wyozimc.CallHook("WyoziMCMenu", menu, theurl, tmedia, playnetmsg)

		menu:Open()
	end

	table.Empty(wyozimc.AllLines)

	-- See if media list exists in cache
	if wyozimc.GuiMediaCache then
		table.Add(wyozimc.AllLines, wyozimc.GuiMediaCache)
	else
		table.insert(wyozimc.AllLines, {
			Title = "UPDATING",
			Link = "LIST",
			AddedBy = "PLEASE",
			Date = "WAIT"
		})
	end

	function frame.UpdateList(filter)

		for i=1,#list.Lines do list:RemoveLine(i) end

		table.foreach(wyozimc.AllLines, function(k, v)
			if filter(v) then
				local gpnl = wyozimc.CreateGutterPanel(v)

				local info = ""
				local provider, udata = wyozimc.FindProvider(v.Link)
				if provider then
					info = info .. provider.Name
					if udata and udata.StartAt then
						info = info .. "; Starts at " .. udata.StartAt .. " seconds"
					end
				end

				local line = list:AddLine(gpnl, v.Title, info, v.AddedBy:Split("|", 2)[2], os.date("%c", tonumber(v.Date)))
				line.OrigLink = v.Link

				gpnl.Value = gpnl.IconList.GutterStr
			end
		end)

		wyozimc.CallHook("WyoziMCListUpdated", wyozimc.AllLines)
	end

	frame.UpdateList(function() return true end)

	listscrl:AddItem(list)

	local searchbar = mediapane:Add("DTextEntry")
	searchbar:Dock(TOP)
	local op = searchbar.Paint
	searchbar.Paint = function(pself, w, h)
		op(pself, w, h)

		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(Material("icon16/magnifier.png"))
		surface.DrawTexturedRect(w-18, 2, 16, 16)
	end
	searchbar:DockMargin(0, 0, 0, 5)
	searchbar.OnTextChanged = function()
		frame.UpdateList(function(v) return v.Title:lower():find(searchbar:GetText(), _, true) end)
	end
	searchbar:RequestFocus()

	local btnbar = mediapane:Add("DPanel")
	btnbar:Dock(BOTTOM)
	btnbar:SetDrawBackground(false)
	btnbar:DockMargin(0, 5, 0, 0)

	local btnpanels = btnbar:Add("DPanelList")
	btnpanels:EnableHorizontal(true)
	btnpanels:Dock(FILL)
	btnpanels:SetSpacing(5)

	-- === "NEW MEDIA" INPUTS ===
	-- This includes the textbox at bottom of the WMC GUI and buttons accompanied
	do

		local permission_add = wyozimc.HasPermission(LocalPlayer(), "Add")
		local permission_playall = wyozimc.HasPermission(LocalPlayer(), "PlayAll")

		if permission_add or permission_playall or playnetmsg then

			local addnewentry = vgui.Create("DTextEntry")
			addnewentry:SetSize(590, 23)
			local op = addnewentry.Paint
			addnewentry.Paint = function(pself, w, h)
				op(pself, w, h)

				if pself:GetText() == "" then
					surface.SetTextColor(127, 127, 127, 200)
					surface.SetFont("DermaDefault")
					surface.SetTextPos(3, 6)
					surface.DrawText("http://www.youtube.com/watch?v=")
				end
				surface.SetDrawColor(255, 255, 255, 255)

				local is_empty = pself:GetText():Trim() == ""

				surface.SetMaterial(Material(is_empty and "icon16/cancel.png" or "icon16/accept.png"))
				surface.DrawTexturedRect(w-(is_empty and 20 or 25), 4, 16, 16)

				if pself.UrlProvider or not is_empty then
					surface.SetMaterial(Material(pself.UrlProvider and "icon16/webcam.png" or "icon16/magnifier.png"))
					surface.DrawTexturedRect(w-11, 13, 8, 8)
				end

			end
			addnewentry.OnTextChanged = function(self)
				self.UrlProvider = wyozimc.FindProvider(self:GetText())
			end

			btnpanels:AddItem(addnewentry)

			if permission_add then
				local addnewbtn = vgui.Create("DButton")
				addnewbtn.Paint = wyozimc.PaintGreenButton
				addnewbtn:SetText("Add New")
				addnewbtn:SetSize(75, 23)
				addnewbtn:DockMargin(4, 10, 0, 0)
				btnpanels:AddItem(addnewbtn)
				addnewbtn.Think = function(pself)
					pself:SetDisabled(addnewentry:GetText():Trim() == "")
				end

				local function SendAddData()
					local state, err = wyozimc.FindURL(addnewentry:GetText(), function(link)
						net.Start("wyozimc_edit")
							net.WriteString("add")
							net.WriteString(link)
						net.SendToServer()

						wyozimc.DeferredScrollDown = true
					end)

					if not state then
						LocalPlayer():ChatPrint(tostring(err))
					end

					addnewentry:SetText("")
					addnewentry.OnTextChanged(addnewentry) -- Force call this to update provider to zero
				end

				addnewbtn.DoClick = SendAddData

				addnewentry.OnEnter = SendAddData
			end

			if permission_playall or playnetmsg then
				local playnowbtn = vgui.Create("DButton")
				playnowbtn.Paint = wyozimc.PaintGreenButton
				playnowbtn:SetText("Play Now")
				playnowbtn:SetSize(75, 23)
				playnowbtn:DockMargin(4, 10, 0, 0)
				btnpanels:AddItem(playnowbtn)

				playnowbtn.Think = function(pself)
					pself:SetDisabled(addnewentry:GetText():Trim() == "")
				end

				local function PlayNowData(rightclick)
					local state, err = wyozimc.FindURL(addnewentry:GetText(), function(link)
						if rightclick then
							local menu = DermaMenu()
							wyozimc.AddPlayContextOptions(menu, frame, link, playnetmsg, passent, playflags)
							menu:Open()
						else
							if playnetmsg then
								net.Start(playnetmsg)
									net.WriteString(link)
									net.WriteEntity(passent)
								net.SendToServer()
							else
								net.Start("wyozimc_play")
									net.WriteString(link)
								net.SendToServer()
							end
						end

						addnewentry:SetText("")
						addnewentry.OnTextChanged(addnewentry) -- Force call this to update provider to zero
					end)

					if not state then
						LocalPlayer():ChatPrint(tostring(err))

						addnewentry:SetText("")
						addnewentry.OnTextChanged(addnewentry) -- Force call this to update provider to zero
					end
				end

				playnowbtn.DoClick = function() PlayNowData(false) end
				playnowbtn.DoRightClick = function() PlayNowData(true) end

				if not permission_add then
					addnewentry.OnEnter = PlayNowData
				end
			end


			local addnewinfo = vgui.Create("DButton")
			local helpicon = Material("icon16/help.png")
			addnewinfo.Paint = function()
				surface.SetDrawColor(255, 255, 255)
				surface.SetMaterial(helpicon)
				surface.DrawTexturedRect(2, 2, 16, 16)
				return true
			end
			addnewinfo:SetSize(16, 23)
			addnewinfo:DockMargin(4, 19, 0, 0)
			addnewinfo:SetTooltip([[Both links and search queries work in this field. If the entered string is not identified as a link, it will be automatically searched from YouTube.]])
			btnpanels:AddItem(addnewinfo)
		end

	end

	tabs:AddSheet( "Media List", mediapane, "icon16/table.png", false, false, "A list of media added to WMC" )

end)