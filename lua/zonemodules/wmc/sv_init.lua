	
	hook.Add("zone.PlayerEnteredZone", "zone.wmc.PlyEnteredZone", function(zone, ply)
		if zone:IsZoneType("wmc") then
			local plyurl = zone:GetConfig("wmc", "play_url")
			local nh = zone:GetConfig("wmc", "no_hud")
			local flags = tobool(nh) and wyozimc.FLAG_NO_HUD or 0
			wyozimc.PlayFor(ply, plyurl, flags)
		end
	end)
	
	hook.Add("zone.PlayerLeftZone", "zone.wmc.PlyLeftZone", function(zone, ply)
		if zone:IsZoneType("wmc") then
			wyozimc.PlayFor(ply, "")
		end
	end)