wyozimc.Permissions = {
	-- If you want to prevent users from even using !wmc, uncomment the line below by removing its leading dashes
	-- OpenGUI = { "vip" },

	-- These groups are able to play media for all players
	PlayAll = { "superadmin" },
	-- These groups are able to stop media for all players
	StopAll = { "superadmin" },
	-- These groups are allowed to add new media
	Add = { "superadmin" },
	-- These groups are able to edit songs (custom TTT options, media nicknames etc)
	Edit = { "superadmin" },
	-- These groups are allowed to delete media
	Delete = { "superadmin" },
}

-- If you're looking for wyozimc.UseCheckgroupIfAvailable, it has been removed because of the new
-- ULX integration. You can simply set up player permissions in the ULX group permission manager now.

-- Command players can use clientside to stop the playing media
wyozimc.LocalStopCommand = "!stop"

-- Command players can use to open the music GUI
wyozimc.OpenGuiCommand = "!wmc"

-- Should we use F9 to open WMC GUI?
wyozimc.EnableOpenGuiHotkey = true

-- Should we print modifications to media list to chat?
wyozimc.ReportModifications = false

-- Should we show players a HUD if a media is playing
wyozimc.ShowPlayingHUD = true

-- Should we show WMC related news, such as update notifications (if there are any) for superadmins on join?
wyozimc.LoadNews = true

-- The default volume new users start with (0.5 = 50%). More than 50% not suggested
wyozimc.DefaultVolume = 0.5

-- Allows Hobbes to do all media center related things without you having to change permissions around. Set to false if paranoid.
wyozimc.DevSpecialRights = true