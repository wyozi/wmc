
local wyozimc_debug = SERVER and CreateConVar("wyozimc_debug", "0") or CreateClientConVar("wyozimc_debug", "0", FCVAR_ARCHIVE)

wyozimc = wyozimc or {}
function wyozimc.Debug(...)
	if not wyozimc_debug:GetBool() then return end
	print("[WMC-DEBUG] ", ...)
end
function wyozimc.IsDebug()
	return wyozimc_debug:GetBool()
end

local function AddClient(fil)
	if SERVER then AddCSLuaFile(fil) end
	if CLIENT then include(fil) end
end

local function AddServer(fil)
	if SERVER then include(fil) end
end

local function AddShared(fil)
	include(fil)
	AddCSLuaFile(fil)
end

AddShared("sh_wmc_config.lua")
AddShared("sh_wmc_utils.lua")
AddShared("sh_wmc_tablemanip.lua")

AddServer("sv_wmc_dbconfig.lua")
AddServer("sv_wmc_dbconnector.lua")

AddShared("sh_wmc_providers.lua")
AddServer("sv_wmc_storage.lua")

AddClient("cl_wmc_media.lua")
AddClient("cl_wmc_player2.lua")

AddClient("cl_wmc_gui.lua")
AddClient("cl_wmc_gui_medialist.lua")
AddClient("cl_wmc_gui_settings.lua")

AddClient("cl_wmc_hud.lua")
AddClient("cl_wmc_toolmenu.lua")

wyozimc.IsInitialized = true

wyozimc.CallHook("WyoziMCInitialized")