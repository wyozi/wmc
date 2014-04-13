wyozimc.MediaTypes = {}

class BaseMediaType
	create: =>
	destroy: =>

wyozimc.BaseMediaType = BaseMediaType

wyozimc.AddMediaType = (id, cls) ->
	wyozimc.MediaTypes[id] = cls

wyozimc.CreateMediaType = (id) ->
	if cls = wyozimc.MediaTypes[id]
		return cls()

wyozimc.RefreshMediaTypes = ->
	for _,fil in pairs(file.Find("wmcmediatypes/*.lua", "LUA"))
		if SERVER
			AddCSLuaFile("wmcmediatypes/" .. fil)

		include("wmcmediatypes/" .. fil)
		wyozimc.Debug("Loading mediatype ", fil)

wyozimc.RefreshMediaTypes!