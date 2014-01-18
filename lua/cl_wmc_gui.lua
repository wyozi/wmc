
local frame_background = Color(255, 255, 255)
local frame_outline = Color(127, 127, 127)
local frame_title_background = Color(0, 50, 0, 200)

local btn_green = Color(0, 190, 0, 160)
local btn_green_hovered = Color(20, 220, 20, 160)
local btn_green_disabled = Color(100, 160, 100, 160)
local btn_green_disabled_hovered = Color(120, 180, 120, 160)

local clr_black = Color(0, 0, 0)

function wyozimc.PaintFrame(pself, w, h)

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

function wyozimc.CreateButtonPainter(datatbl)
	datatbl = datatbl or {}
	return function(pself, w, h)
		if pself:GetDisabled() then
			surface.SetDrawColor(datatbl.disabled_clr or btn_green_disabled)
		elseif pself.Hovered then
			surface.SetDrawColor(datatbl.hovered_clr or btn_green_hovered)
		else
			surface.SetDrawColor(datatbl.clr or btn_green)
		end
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(datatbl.outline_clr or clr_black)
		surface.DrawOutlinedRect(0, 0, w, h)

		draw.SimpleText(pself:GetText(), "DermaDefault", w/2, h/2,
			(pself:GetDisabled()) and (Color(200, 200, 200, 100)) or (datatbl.text_clr or clr_black)
			, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		return true
	end
end

-- DEPRECATED!
wyozimc.PaintGreenButton = wyozimc.CreateButtonPainter()

function wyozimc.AddSimplePlayContextOptions(menu, theurl, playflags)
	playflags = playflags or 0
	menu:AddOption("Play", function()
		local nflags = bit.bor(playflags, wyozimc.FLAG_PLAYING_CLIENTSIDE)
		local fut = wyozimc.PlayUrl(theurl, _, nflags)
		if fut then
			fut.done(function(qdata)
				wyozimc.ChatText(Color(255, 127, 0), "[MediaPlayer] ", Color(255, 255, 255), "Playing ", Color(252, 84, 84), qdata.Title or theurl, Color(255, 255, 255), " locally.")
			end)
		end
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
		wyozimc.AddSimplePlayContextOptions(menu, theurl, playflags)
	end
end

-- Sends server a request to update the media list shown in the GUI
-- Most commonly used after opening the GUI (so server doesn't have to send updates every time the list updates, but only
--  when player actually has an use for the media list)
function wyozimc.RequestMediaListUpdate()
	net.Start("wyozimc_list") -- Request list
		if wyozimc.GuiMediaCache then
			net.WriteString(util.CRC(util.TableToJSON(wyozimc.GuiMediaCache)))
		else
			net.WriteString("")
		end
	net.SendToServer()
end

-- Media received from the server is stored in this table. 
wyozimc.AllLines = {}

function wyozimc.NewOpenGUI(data)

	data = data or {}

	local playnetmsg = data.CustomNetMessage
	local passent = data.CustomNetEntity

	if IsValid(wyozimc.Gui) then
		wyozimc.Gui:Remove()
	end

	if not playnetmsg and not wyozimc.HasPermission(LocalPlayer(), "OpenGUI") then
		wyozimc.ChatText(Color(255, 127, 0), "[MediaPlayer] ", Color(252, 84, 84), "No permission!")
		return
	end
	
	local frame = vgui.Create("DFrame")
	frame.Paint = wyozimc.PaintFrame
	frame:SetTitle("")
	frame:SetSize(800, 600)
	frame:Center()

	frame.PlayNetMsg = playnetmsg
	frame.PassEnt = passent

	wyozimc.Gui = frame

	local tabs = frame:Add("DPropertySheet")
	tabs:Dock(FILL)

	tabs.MainFrame = frame

	wyozimc.CallHook("WyoziMCTabs", tabs, playnetmsg, passent)

	-- === TITLEBAR CONTROLS ===
	-- This includes "Enable" checkbox, volume slider and the stop buttons
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

		-- "Stop for myself" button should only be visible if this is the default WMC medialist
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

-- Deprecated! Use wyozimc.NewOpenGUI
function wyozimc.OpenGUI(playnetmsg, passent)
	wyozimc.Debug("Note: Deprecated wyozimc.OpenGUI called from somewhere. Use wyozimc.NewOpenGUI!")
	wyozimc.NewOpenGUI({
		CustomNetMessage = playnetmsg,
		CustomNetEntity = passent
	})
end

concommand.Add("wyozimc_open", function()
	wyozimc.NewOpenGUI({})
end)

concommand.Add("wyozimc_delcache", function()
	wyozimc.GuiMediaCache = nil
end)

net.Receive("wyozimc_list", function()

	local emptyold = net.ReadBit() == 1

	wyozimc.GuiMediaCache = wyozimc.GuiMediaCache or {}

	if emptyold then
		table.Empty(wyozimc.AllLines)
		table.Empty(wyozimc.GuiMediaCache)
	end

	local addtbl = net.ReadTable()
	table.Add(wyozimc.AllLines, addtbl)
	table.Add(wyozimc.GuiMediaCache, addtbl)

	if IsValid(wyozimc.Gui) then
		wyozimc.Gui.UpdateList(function() return true end)
	end

	wyozimc.Debug("Received new AllLines list #", #wyozimc.AllLines, " emptyold ", emptyold)
end)

net.Receive("wyozimc_edit", function()
	local tt = net.ReadString()

	-- When something is edited in the media list on server, the server sends "wyozimc_edit" net message with "requpd"
	--  payload to everyone. Then each of the clients check if they have the wyozimc media list open, and if it's open 
	--  we send server back a net message where we request for update to the media list. This prevents unnecessary (big)
	--  payloads with the full media list, if the clients don't actually need it.
	if tt == "requpd" and IsValid(wyozimc.Gui) then
		wyozimc.RequestMediaListUpdate()
	end
end)

net.Receive("wyozimc_gui", function()
	local for_custom_player = net.ReadBit() == 1 -- If we're not the list for the default F9 openable player
	if for_custom_player then
		wyozimc.NewOpenGUI({
			CustomNetMessage = net.ReadString(),
			CustomNetEntity = net.ReadEntity()
		})
	else
		wyozimc.NewOpenGUI({})
	end
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