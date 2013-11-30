wyozimc.Providers = {}

function wyozimc.AddProvider(tbl)
	table.insert(wyozimc.Providers, tbl)
end

function wyozimc.FindProvider(url)
	url = url:Trim()
	for _, provider in pairs(wyozimc.Providers) do
		local cbres = provider.UrlMatcher and provider.UrlMatcher(url) or nil
		if cbres then
			return provider, {Matches = {cbres}, WholeUrl = url}
		end
		for _, pattern in ipairs(provider.UrlPatterns) do
			local m = {url:match(pattern)}
			if m[1] then
				local udata = {Matches = m, WholeUrl = url}
				if provider.ParseUData then
					provider.ParseUData(udata)
				end
				return provider, udata
			end
		end 
	end

	return nil
end

-- Not sure what this does but some black magic for sure
function wyozimc.JSEscape(str)
	return str:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\'", "\\'")
		:gsub("\r", "\\r"):gsub("\n", "\\n")
end

function wyozimc.URLEscape(s)
	s = tostring(s)
	local new = ""
	
	for i = 1, #s do
		local c = s:sub(i, i)
		local b = c:byte()
		if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or
			(b >= 48 and b <= 57) or
			c == "_" or c == "." or c == "~" then
			new = new .. c
		else
			new = new .. string.format("%%%X", b)
		end
	end
	
	return new
end


function wyozimc.URLUnEscape(str)
	return str:gsub("%%([A-Fa-f0-9][A-Fa-f0-9])", function(m)
		local n = tonumber(m, 16)
		if not n then return "" end -- Not technically required
		return string.char(n)
	end)
end

for _,fil in pairs(file.Find("wmcproviders/*.lua", "LUA")) do
	if SERVER then
		AddCSLuaFile("wmcproviders/" .. fil)
	end
	include("wmcproviders/" .. fil)
	wyozimc.Debug("Loading provider ", fil)
end