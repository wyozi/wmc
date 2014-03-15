wyozimc.MediaTypes = { }
local BaseMediaType
do
  local _base_0 = {
    allocate = function() end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "BaseMediaType"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  BaseMediaType = _class_0
end
wyozimc.BaseMediaType = BaseMediaType
wyozimc.AddMediaType = function(id, cls)
  wyozimc.MediaTypes[id] = cls
end
for _, fil in pairs(file.Find("wmcmediatypes/*.lua", "LUA")) do
  if SERVER then
    AddCSLuaFile("wmcmediatypes/" .. fil)
  end
  include("wmcmediatypes/" .. fil)
  wyozimc.Debug("Loading mediatype ", fil)
end
