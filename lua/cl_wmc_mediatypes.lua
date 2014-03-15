wyozimc.MediaTypes = { }
local BaseMediaType
do
  local _base_0 = { }
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
for _, fil in pairs(file.Find("wmcproviders/*.lua", "LUA")) do
  if SERVER then
    AddCSLuaFile("wmcproviders/" .. fil)
  end
  _ = end
  include("wmcproviders/" .. fil)
  wyozimc.Debug("Loading provider ", fil)
end
