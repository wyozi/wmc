--   ____  ____   _____  ____  _      ______ _______ ______ 
--  / __ \|  _ \ / ____|/ __ \| |    |  ____|__   __|  ____|
-- | |  | | |_) | (___ | |  | | |    | |__     | |  | |__   
-- | |  | |  _ < \___ \| |  | | |    |  __|    | |  |  __|  
-- | |__| | |_) |____) | |__| | |____| |____   | |  | |____ 
--  \____/|____/|_____/ \____/|______|______|  |_|  |______|

-- THIS FILE HAS BEEN REPLACED BY MOONSCRIPT AT cl_wmc_player2.moon
-- IT IS ONLY HERE FOR FUTURE REFERENCE

if true then
	return
end

local wyozimc_enabled = CreateConVar("wyozimc_enabled", "1", FCVAR_ARCHIVE)
local wyozimc_volume = CreateConVar("wyozimc_volume", "0.5", FCVAR_ARCHIVE)
local wyozimc_playwhenalttabbed = CreateConVar("wyozimc_playwhenalttabbed", "0", FCVAR_ARCHIVE)
local wyozimc_ignoreglobalplays = CreateConVar("wyozimc_ignoreglobalplays", "0", FCVAR_ARCHIVE)
local wyozimc_debugvid = CreateConVar("wyozimc_debugvid", "0", FCVAR_ARCHIVE)

local wyozimc_highquality = CreateConVar("wyozimc_highquality", "0", FCVAR_ARCHIVE)
local wyozimc_forcehtml5 = CreateConVar("wyozimc_forcehtml5", "0", FCVAR_ARCHIVE)

function wyozimc.GetMasterVolume()
	local curvolume = wyozimc_volume:GetFloat()
	if not wyozimc_playwhenalttabbed:GetBool() and not system.HasFocus() then
		curvolume = 0
	end
	return curvolume
end

wyozimc.CachedMedia = {}

function wyozimc.SetupPlayer()
	if not IsValid(wyozimc.PlayerFrame) then
		wyozimc.Debug("Recreating wyozimc.PlayerFrame")
		wyozimc.PlayerFrame = vgui.Create("DPanel")
		wyozimc.PlayerFrame:SetPos(0, 0)
		wyozimc.PlayerFrame:SetSize(256, 256)
		wyozimc.PlayerFrame:SetVisible(false)
	end
	if not IsValid(wyozimc.Player) then
		wyozimc.Debug("Recreating wyozimc.Player")
		wyozimc.Player = vgui.Create("DHTML", wyozimc.PlayerFrame)
		wyozimc.Player:Dock(FILL)

		wyozimc.Player:AddFunction("gmod", "SetFlashStatus", function(bool)
			wyozimc.Debug("WMC Player flash found: ", bool)
			wyozimc.FlashFound = bool
		end)
		wyozimc.Player:QueueJavascript([[var hasFlash = false;
try {
  var fo = new ActiveXObject('ShockwaveFlash.ShockwaveFlash');
  if(fo) hasFlash = true;
}catch(e){
  if(navigator.mimeTypes ["application/x-shockwave-flash"] != undefined) hasFlash = true;
}
gmod.SetFlashStatus(hasFlash)]])
	end
end

concommand.Add("wyozimc_refresh", function()
	if IsValid(wyozimc.Player) then
		wyozimc.Player:Remove()
	end
	wyozimc.SetupPlayer()
end)

function wyozimc.PlayUrl(url, startat, flags)

	flags = flags or 0

	if flags and bit.band(flags, wyozimc.FLAG_OVERRIDE_NOTHING) == wyozimc.FLAG_OVERRIDE_NOTHING then
		wyozimc.Debug("Aborting wyozimc.PlayUrl because we got FLAG_OVERRIDE_NOTHING")
		return
	end

	if wyozimc_ignoreglobalplays:GetBool() and bit.band(flags, wyozimc.FLAG_DIRECT_REQUEST) == wyozimc.FLAG_DIRECT_REQUEST then
		wyozimc.Debug("Not playing because direct request and we got it disabled")
		return 
	end

	local provider, udata = wyozimc.FindProvider(url)
	if not provider then
		ErrorNoHalt("Trying to play something with no provider: " .. tostring(url))
		return
	end

	if wyozimc.CallHook("WyoziMCPrePlay", provider, url, udata, flags) then
		wyozimc.Debug("Hook terminated wyozimc.Play()")
		return
	end

	wyozimc.Stop() -- Make sure old youtube and soundchannel things are stopped

	udata.StartAt = startat or udata.StartAt

	-- Delete old data
	wyozimc.QueryData = nil
	wyozimc.Provider = nil
	wyozimc.StartedAt = nil
	wyozimc.LastSetVolume = nil

	wyozimc.LastPlayedUrl = url
	wyozimc.Debug("Setting LastPlayedUrl to ", wyozimc.LastPlayedUrl)

	wyozimc.ShowHUD = bit.band(flags or 0, wyozimc.FLAG_NO_HUD) == 0 and wyozimc.ShowPlayingHUD

	wyozimc.Debug("WMC Flags: ", bit.tohex(flags or 0))

	if provider.QueryMeta then

		provider.QueryMeta(udata, function(data)
			wyozimc.QueryData = data
			wyozimc.Debug("Setting QueryData to ", data, " (" , data.Title, " d=", data.Duration, ")")
		end, function(errormsg) end)
	end

	if provider.SetHTML then
		wyozimc.Play(provider, provider.SetHTML(udata, url), true, udata.StartAt)
	else
		wyozimc.Debug("Translating url ", url)

		provider.TranslateUrl(udata, function(url, newstartat)
			udata.StartAt = udata.StartAt or newstartat -- Providers might parse startat data from the link, so this required
			wyozimc.Play(provider, url, false, udata.StartAt)
		end)
	end
end
function wyozimc.Play(provider, url_or_html, isHtml, startat)

	if not wyozimc_enabled:GetBool() then
		wyozimc.Debug("Not playing because wyozimc_enabled is 0")
		return
	end

	wyozimc.Provider = provider

	if provider.UseGmodPlayer then
		if isHtml then
			ErrorNoHalt("Attempting to play GmodPlayer provider with SetHTML!!")
			return
		end

		local url = url_or_html

		wyozimc.Debug("Attempting to play ", url, " using GmodPlayer")
		if wyozimc.CachedMedia[url] and wyozimc.CachedMedia[url]:IsValid() then
			wyozimc.CachedMedia[url]:Play()
			wyozimc.SoundChannel = wyozimc.CachedMedia[url]
			wyozimc.CachedMedia[url] = nil

			wyozimc.Debug("Playing ", url , " using cached sound channel")
		else
			sound.PlayURL(url, "noplay", function(chan)
				if IsValid(chan) then
					if IsValid(wyozimc.SoundChannel) then
						wyozimc.SoundChannel:Stop()
					end
					wyozimc.SoundChannel = chan
					chan:Play()
					wyozimc.Debug("playing ", url, " using GmodPlayer")
				else
					wyozimc.Debug("GModplayer Channel nonvalid for ", url)
				end
			end)
		end
	else
		wyozimc.SetupPlayer()
		if isHtml then
			wyozimc.Debug("Playing using SetHTML #" .. tostring(#url_or_html))
			wyozimc.Player:SetHTML(url_or_html)
			MsgN(url_or_html)
		else
			local url = url_or_html
			wyozimc.Debug("Playing ", url)
			wyozimc.Player:OpenURL(url)
		end
	end

	wyozimc.StartedAt = CurTime() - (startat or 0)
	wyozimc.Debug("PostPlay: CurTime: " .. CurTime() .. " startat: " .. tostring(startat) .. " StartedAt " .. wyozimc.StartedAt)

	wyozimc.RealStartedAt = CurTime()
	wyozimc.CallHook("WyoziMCPostPlay", provider, url_or_html, isHtml)
end

function wyozimc.GetPlayedFraction()
	local qd = wyozimc.QueryData
	if not qd then return nil end

	local goneseconds = ( CurTime() - (wyozimc.StartedAt or CurTime()) )
	local gonefrac = qd.Duration == -1 and 0 or ( goneseconds / (qd.Duration or 0) )

	return gonefrac
end

function wyozimc.IsPlaying()
	local frac = wyozimc.GetPlayedFraction()
	if frac and frac < 1 then
		return true
	end
	return false
end

hook.Add("Think", "WyoziMCMaintainVolume", function()
	if wyozimc.Provider and wyozimc.Provider.FuncSetVolume then
		local curvolume = wyozimc.GetMasterVolume()
		if curvolume ~= wyozimc.LastSetVolume or (wyozimc.RealStartedAt and wyozimc.RealStartedAt > CurTime() - 2) then

			if curvolume ~= wyozimc.LastSetVolume then wyozimc.Debug("Setting volume to ", curvolume) end

			if IsValid(wyozimc.Player) then
				wyozimc.Player:QueueJavascript(wyozimc.Provider.FuncSetVolume(curvolume))
			end
			if IsValid(wyozimc.SoundChannel) then
				wyozimc.Provider.FuncSetVolume(curvolume, wyozimc.SoundChannel)
			end

			wyozimc.LastSetVolume = curvolume
		end
	end
	if IsValid(wyozimc.PlayerFrame) and wyozimc.PlayerFrame:IsVisible() ~= wyozimc_debugvid:GetBool() then
		wyozimc.PlayerFrame:SetVisible(wyozimc_debugvid:GetBool())
	end
end)

function wyozimc.Stop(globalrequest)
	if wyozimc.CallHook("WyoziMCPreStop", globalrequest) then
		wyozimc.Debug("Hook terminated wyozimc.Stop()")
		return 
	end

	if IsValid(wyozimc.Player) then
		wyozimc.Player:SetHTML("Hello!") -- Cheaper than to destroy and recreate later
	end
	if IsValid(wyozimc.SoundChannel) then
		wyozimc.SoundChannel:Stop()
	end
	
	-- Delete old data
	wyozimc.QueryData = nil
	wyozimc.Provider = nil
	wyozimc.StartedAt = nil

	wyozimc.Debug("All wyozimc data reset")

	wyozimc.CallHook("WyoziMCPostStop", globalrequest)
end

net.Receive("wyozimc_play", function()
	local url = net.ReadString()
	local flags = net.ReadUInt(32)
	if url == "" then
		wyozimc.Debug("Got empty url, assuming we need to stop. Flags: " .. bit.tohex(flags))
		wyozimc.Stop(bit.band(flags, wyozimc.FLAG_WAS_GLOBAL_REQUEST) == wyozimc.FLAG_WAS_GLOBAL_REQUEST)
	else
		wyozimc.Debug("Received ", url, " to play on client. Flags: " .. bit.tohex(flags))
		wyozimc.PlayUrl(url, _, flags)
	end
end)

net.Receive("wyozimc_cache", function()
	local url = net.ReadString()
	
	local provider, udata = wyozimc.FindProvider(url)
	if not provider then
		ErrorNoHalt("Trying to cache something with no provider: " .. tostring(url))
		return
	end

	if not provider.UseGmodPlayer then
		wyozimc.Debug("Trying to cache invalid provider: only GmodPlayer sounds can be cached!")
		return
	end

	sound.PlayURL(url, "noplay", function(chan)
		if IsValid(chan) then
			wyozimc.CachedMedia[url] = chan
			wyozimc.Debug("Cached ", url, " using GmodPlayer")
		else
			wyozimc.Debug("GModplayer Cached channel nonvalid for ", url)
		end
	end)

end)

concommand.Add("wyozimc_stop", function()
	wyozimc.Stop()
end)

hook.Add("InitPostEntity", "WyoziMCPlayLate", function()
	local url, flags, start = GetGlobalString("wmc_playurl"), GetGlobalInt("wmc_playflags"), GetGlobalInt("wmc_playat")
	if url and url ~= "" then
		wyozimc.PlayUrl(url, CurTime() - start, flags)
	end
end)