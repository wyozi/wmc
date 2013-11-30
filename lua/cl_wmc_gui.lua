
local frame_background = Color(255, 255, 255)
local frame_outline = Color(127, 127, 127)
local frame_title_background = Color(0, 50, 0, 200)

local btn_green = Color(0, 190, 0, 160)
local btn_green_hovered = Color(20, 220, 20, 160)

local clr_black = Color(0, 0, 0)

local function PaintFrame(pself, w, h)

	surface.SetDrawColor(frame_background)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(frame_outline)
	surface.DrawOutlinedRect(0, 0, w, h)

	surface.SetDrawColor(frame_title_background)
	surface.DrawRect(0, 0, w, 25)

	surface.SetTextColor(255, 255, 255, 200)
	surface.SetFont("Trebuchet18")

	local txt = "Wyozi Media Center"

	local ts = surface.GetTextSize(txt)

	surface.SetTextPos(400 - ts/2, 4)
	surface.DrawText(txt)

	if pself.BaseClass then
		pself.BaseClass.Paint(pself, w, h)
	end
end

local function PaintGreenButton(pself, w, h)
	surface.SetDrawColor(pself.Hovered and btn_green_hovered or btn_green)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(clr_black)
	surface.DrawOutlinedRect(0, 0, w, h)

	draw.SimpleText(pself:GetText(), "DermaDefault", w/2, h/2, clr_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	return true
end

local function PaintRedButton(pself, w, h)
	surface.SetDrawColor(Color(190, 90, 0, 160))
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(Color(0, 0, 0))
	surface.DrawOutlinedRect(0, 0, w, h)
end

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

local function CreateGutterPanel(v)
	local p = vgui.Create("DPanel")
	p:SetDrawBackground(false)

	local dpl = p:Add("DPanelList")
	dpl:EnableHorizontal(true)
	dpl:Dock(FILL)

	dpl.GutterStr = ""

	wyozimc.CallHook("WyoziMCGutter", v, dpl)

	p.IconList = dpl

	return p
end

function wyozimc.AddPlayContextOptions(menu, frame, theurl, playnetmsg, passent, playflags)
	playflags = playflags or 0

	if playnetmsg then
		if wyozimc.HasPermission(LocalPlayer(), "PlayAll") then
			menu:AddOption("Play", function()
				net.Start(playnetmsg) net.WriteString(theurl) net.WriteEntity(passent) net.WriteUInt(playflags, 32) net.SendToServer()
				frame:Close()
			end):SetIcon( "icon16/music.png" )
		end
	else

		menu:AddOption("Play", function()
			local nflags = bit.bor(playflags, wyozimc.FLAG_PLAYING_CLIENTSIDE)
			wyozimc.PlayUrl(theurl, _, nflags).done(function(qdata)
				wyozimc.ChatText(Color(255, 127, 0), "[MediaPlayer] ", Color(255, 255, 255), "Playing ", Color(252, 84, 84), qdata.Title or theurl, Color(255, 255, 255), " locally.")
			end)
		end):SetIcon( "icon16/music.png" )

		if wyozimc.HasPermission(LocalPlayer(), "PlayAll") then
			menu:AddOption("Play for All", function()
				net.Start("wyozimc_play") net.WriteString(theurl) net.SendToServer()
			end):SetIcon( "icon16/control_play.png" )

			local csubmenu, csmpnl = menu:AddSubMenu("Play For", function() end)
			csmpnl:SetIcon( "icon16/user_comment.png" )

			for _,ply in pairs(player.GetAll()) do
				local opt = csubmenu:AddOption(ply:Nick(), function()
					net.Start("wyozimc_playply")
						net.WriteEntity(ply)
						net.WriteString(theurl)
					net.SendToServer()
				end)
			end
		end

	end
end

function wyozimc.RequestMediaListUpdate()
	net.Start("wyozimc_list") -- Request list
		if wyozimc.GuiMediaCache then
			net.WriteString(util.CRC(util.TableToJSON(wyozimc.GuiMediaCache)))
		else
			net.WriteString("")
		end
	net.SendToServer()
end

wyozimc.AllLines = {}

function wyozimc.NewOpenGUI(data)

	local playnetmsg = data.CustomNetMessage
	local passent = data.CustomNetEntity

	if IsValid(wyozimc.Gui) then
		--[[if wyozimc.Gui.PlayNetMsg == playnetmsg and wyozimc.Gui.PassEnt == passent then
			wyozimc.Gui:Show()
			return
		end]]
		wyozimc.Gui:Remove()
	end

	if not playnetmsg and not wyozimc.HasPermission(LocalPlayer(), "OpenGUI") then
		wyozimc.ChatText(Color(255, 127, 0), "[MediaPlayer] ", Color(252, 84, 84), "No permission!")
		return
	end
	
	local frame = vgui.Create("DFrame")
	frame.Paint = PaintFrame
	frame:SetTitle("")
	frame:SetSize(800, 600)
	frame:Center()

	frame.PlayNetMsg = playnetmsg
	frame.PassEnt = passent

	wyozimc.Gui = frame

	local tabs = frame:Add("DPropertySheet")
	tabs:Dock(FILL)

	local mediapane = vgui.Create("DPanel")
	mediapane:SetDrawBackground(false)

	local listscrl = mediapane:Add("DScrollPanel")
	listscrl:Dock(FILL)
	listscrl.pnlCanvas:Dock(FILL) -- Hack hack hack, makes content pane fill the scrollpane

	frame.MediaScroll = listscrl

	--[[local oss = listscrl.VBar.SetScroll
	listscrl.VBar.SetScroll = function(pself, offset)
		oss(pself, offset)

		wyozimc.GUI_LastListScroll = offset
		MsgN(offset)
	end]]

	local list = vgui.Create("DListView")
	list:AddColumn(""):SetMaxWidth(40)
	list:AddColumn("Title")
	list:AddColumn("Link")
	list:AddColumn("Added By"):SetMaxWidth(128)
	list:AddColumn("Date"):SetMaxWidth(128)
	list:Dock(FILL)
	list:SetMultiSelect(false)
	list.OnRowRightClick = function(panel, line)

		local theurl = list:GetLine(line):GetValue(3)

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
	if wyozimc.GuiMediaCache and table.Count(wyozimc.GuiMediaCache) > 0 then
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

		local last

		table.foreach(wyozimc.AllLines, function(k, v)
			if filter(v) then
				local gpnl = CreateGutterPanel(v)
				last = list:AddLine(gpnl, v.Title, v.Link, v.AddedBy:Split("|", 2)[2], os.date("%d.%m.%Y %H:%M", tonumber(v.Date)))
				gpnl.Value = gpnl.IconList.GutterStr
			end
		end)

		if last then
			--listscrl:ScrollToChild(last)
		end

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
				surface.SetMaterial(Material(pself.UrlProvider and "icon16/accept.png" or "icon16/cancel.png"))
				surface.DrawTexturedRect(w-20, 4, 16, 16)
			end
			addnewentry.OnTextChanged = function(self)
				self.UrlProvider = wyozimc.FindProvider(self:GetText())
			end

			btnpanels:AddItem(addnewentry)

			if permission_add then
				local addnewbtn = vgui.Create("DButton")
				addnewbtn.Paint = PaintGreenButton
				addnewbtn:SetText("Add New")
				addnewbtn:SetSize(75, 23)
				addnewbtn:DockMargin(4, 10, 0, 0)
				btnpanels:AddItem(addnewbtn)

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

				--[[do
					local luckbtn = vgui.Create("DButton")
					luckbtn.Paint = PaintGreenButton
					luckbtn:SetText("I'm Feeling Lucky")
					luckbtn:SetSize(95, 23)
					luckbtn:DockMargin(4, 10, 0, 0)

					btnpanels:AddItem(luckbtn)

					luckbtn.DoClick = function()
						wyozimc.SearchYoutube(addnewentry:GetText(), function(theurl)
							net.Start("wyozimc_edit")
								net.WriteString("add")
								net.WriteString(theurl)
							net.SendToServer()
						end)

						addnewentry:SetText("")
						addnewentry.OnTextChanged(addnewentry) -- Force call this to update provider to zero
					end
				end]]
			end

			if permission_playall or playnetmsg then
				local playnowbtn = vgui.Create("DButton")
				playnowbtn.Paint = PaintGreenButton
				playnowbtn:SetText("Play Now")
				playnowbtn:SetSize(75, 23)
				playnowbtn:DockMargin(4, 10, 0, 0)
				btnpanels:AddItem(playnowbtn)

				local function PlayNowData()
					local state, err = wyozimc.FindURL(addnewentry:GetText(), function(link)
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
					end)

					if not state then
						LocalPlayer():ChatPrint(tostring(err))
					end

					addnewentry:SetText("")
					addnewentry.OnTextChanged(addnewentry) -- Force call this to update provider to zero
				end

				playnowbtn.DoClick = PlayNowData

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

	tabs:AddSheet( "Media List", mediapane, "icon16/table.png", false, false, "" )

	wyozimc.CallHook("WyoziMCTabs", tabs, playnetmsg, passent)

	do
		local titlex = 4

		local enablebox = frame:Add("DCheckBox")
		enablebox:SetPos(titlex, 4)
		enablebox:SetConVar("wyozimc_enabled")
		titlex = titlex + 18

		local enableboxlabel = frame:Add("DLabel")
		enableboxlabel:SetText("Enable")
		enableboxlabel:SetPos(titlex, 2)
		titlex = titlex + 40
		enableboxlabel.DoClick = function()
			enablebox:DoClick()
		end

		if not playnetmsg then
			local localstopbtn = frame:Add("DImageButton")
			localstopbtn:SetPos(titlex, 4)
			localstopbtn:SetSize(18, 18)
			titlex = titlex + 20

			localstopbtn:SetIcon("icon16/control_stop_blue.png")

			localstopbtn:SetTooltip("Stop media for me")

			localstopbtn.DoClick = function()
				RunConsoleCommand("wyozimc_stop")
			end
		end

		do
			local stopbtn = frame:Add("DImageButton")
			stopbtn:SetPos(titlex, 4)
			stopbtn:SetSize(18, 18)
			titlex = titlex + 25

			stopbtn:SetIcon("icon16/control_stop.png")

			stopbtn:SetTooltip("Stop media for everyone")

			if playnetmsg then
				stopbtn.DoClick = function()
					net.Start(playnetmsg) net.WriteString("") net.WriteEntity(passent) net.SendToServer()
				end
			elseif wyozimc.HasPermission(LocalPlayer(), "StopAll") then
				stopbtn.DoClick = function()
					net.Start("wyozimc_play") net.WriteString("") net.SendToServer()
				end
			else
				stopbtn:SetVisible(false) -- asd
			end
		end

		local volslider = frame:Add("DNumSlider")
		local op = volslider.Paint
		--[[
		volslider.Paint = function(pself, w, h)
			surface.SetDrawColor(50, 50, 50, 100)

			surface.DrawRect(0, h-1, w, 1)
			for i=0,10 do
				local f = w/10*i
				surface.DrawRect(i > 0 and f-1 or f, h-5, 1, 5)
			end
			op(pself, w, h)
		end]]
		volslider:SetPos(titlex, 4)
		volslider:SetSize(150, 18)
		volslider:SetConVar("wyozimc_volume")
		volslider.Label:SetSize(0)

		volslider.TextArea:SetEditable(false)
		volslider.TextArea.Paint = function(pself, w, h)
			surface.SetTextColor(255, 255, 255)
			surface.SetFont("DermaDefault")
			surface.SetTextPos(5, 2)
			surface.DrawText(tostring(tonumber(pself:GetText())*100) .. "%")
		end

		titlex = titlex + 150
	end

	frame:MakePopup()

	wyozimc.RequestMediaListUpdate()
end
function wyozimc.OpenGUI(playnetmsg, passent)
	wyozimc.NewOpenGUI({
		CustomNetMessage = playnetmsg,
		CustomNetEntity = passent
	})
end

concommand.Add("wyozimc_open", function()
	wyozimc.OpenGUI()
end)

concommand.Add("wyozimc_delcache", function()
	wyozimc.GuiMediaCache = nil
end)

net.Receive("wyozimc_list", function()
	if not IsValid(wyozimc.Gui) then return end

	local emptyold = net.ReadBit() == 1

	wyozimc.GuiMediaCache = wyozimc.GuiMediaCache or {}

	if emptyold then
		table.Empty(wyozimc.AllLines)
		table.Empty(wyozimc.GuiMediaCache)
	end

	local addtbl = net.ReadTable()
	table.Add(wyozimc.AllLines, addtbl)
	table.Add(wyozimc.GuiMediaCache, addtbl)

	wyozimc.Gui.UpdateList(function() return true end)

	--[[if wyozimc.DeferredScrollDown then
		wyozimc.DeferredScrollDown = false
		local vbar = wyozimc.Gui.MediaScroll.VBar

		vbar:AddScroll(10000)
	end]]

	wyozimc.Debug("Received new AllLines list #", #wyozimc.AllLines, " emptyold ", emptyold)
end)

net.Receive("wyozimc_edit", function()
	local tt = net.ReadString()

	if tt == "requpd" and IsValid(wyozimc.Gui) then
		wyozimc.RequestMediaListUpdate()
	end
end)

net.Receive("wyozimc_gui", function()
	local bit = net.ReadBit() == 1
	if bit then wyozimc.OpenGUI(net.ReadString(), net.ReadEntity())
	else wyozimc.OpenGUI() end
end)

function wyozimc.HKThink()
	if input.IsKeyDown(KEY_F9) then
		if wyozimc.HKDown then return end

		wyozimc.HKDown = true
		if IsValid(wyozimc.Gui) then
			wyozimc.Gui:SetVisible(not wyozimc.Gui:IsVisible())
		else
			wyozimc.OpenGUI()
		end
	else
		wyozimc.HKDown = false
	end
end

hook.Add("Think", "WyoziMCGUIHotkey", wyozimc.HKThink)