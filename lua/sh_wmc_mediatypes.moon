wyozimc.MediaTypes = {}

class BaseMediaType
	create: =>
	destroy: =>

wyozimc.BaseMediaType = BaseMediaType

wyozimc.AddMediaType = (id, cls) ->
	wyozimc.MediaTypes[id] = cls

for _,fil in pairs(file.Find("wmcmediatypes/*.lua", "LUA"))
	if SERVER
		AddCSLuaFile("wmcmediatypes/" .. fil)

	include("wmcmediatypes/" .. fil)
	wyozimc.Debug("Loading mediatype ", fil)