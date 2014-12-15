--[[
	Table manipulation class.

	In other words it is a wrapper on top of table, which logs changes to a file,
	to a database or to server using net messages.

	Proxy manipulator is a client side tablemanip that sends changes to server.

	In WMC core only used to send media list over network.

	TODO: move CRC checks etc to this file from media list
	TODO: make file data source second class citizen, ie. add a table or member
		  DataSource and set it to file source by default
]]

wyozimc.manip_meta = {
	Init = function(self)
		self.Table = self.Table or {}
	end,
	SetTable = function(self, tbl, no_save)
		table.Empty(self.Table)
		table.Add(self.Table, tbl)

		if not no_save then
			self:Save()
			wyozimc.Debug("Saving to file via SetTable")
		end
	end,
	Load = function(self)
		if not self.persist_file then
			wyozimc.Debug("Not loading table to table manipulator with nil persist file")
			return
		end
		if self.data_source then
			self.data_source:Load(function(tbl)
				self:SetTable(tbl)
			end)
		else
			self:SetTable(util.JSONToTable(file.Read(self.persist_file, "DATA") or "{}"))
		end
	end,
	Save = function(self, action, ...)
		if not self.persist_file then
			wyozimc.Debug("Not saving table manipulator with nil persist file")
			return
		end
		if self.data_source then
			self.data_source:Save(self.Table, action, ...)
		else
			file.Write(self.persist_file, util.TableToJSON(self.Table))
		end
	end,
	Add = function(self, newelement)
		local idx = table.insert(self.Table, newelement)
		self:Save("Add", idx)
		return idx
	end,
	GetByUnique = function(self, uniq)
		local idx = self:UniqueIndex(uniq)
		if idx then return self.Table[idx] end
	end,
	UniqueIndex = function(self, uniq)
		if not self.unique then return nil end
		for k,v in pairs(self.Table) do
			if v[self.unique] == uniq then return k end
		end
		return false
	end,
	ContainsUnique = function(self, uniq)
		return self:UniqueIndex(uniq) ~= nil
	end,
	Remove = function(self, el)
		local idx = table.RemoveByValue(self.Table, el)
		self:Save("Remove", idx, el)
	end,
	RemoveByUnique = function(self, uniq)
		local idx = self:UniqueIndex(uniq)
		if idx then
			local el = self.Table[idx]
			table.remove(self.Table, idx)
			self:Save("Remove", idx, el)
		end
	end,
}

wyozimc.manip_proxy_meta = {
	Init = function(self)
		self.Table = self.Table or {}
		-- Assume there only exists one tablemanip per realm per net message id
		net.Receive(self.net_message_id, function()
			self:SetTable(net.ReadTable(), true)
			wyozimc.Debug("Received table to TableManipulator Proxy ", self.net_message_id, ", #", #self.Table)
			if self.update_callback then
				self.update_callback(self)
			end
		end)
	end,
	Load = function(self)
		-- TODO send table request to server? IDK
	end,
	Save = function(self, action, ...)
		net.Start(self.net_message_id)
			net.WriteTable(self.Table) -- TODO send delta instead of whole thing
		net.SendToServer()
	end,
}

function wyozimc.CreateManipulator(settings)
	local tbl = {}
	setmetatable(tbl, {__index = wyozimc.manip_meta})

	tbl.persist_file = settings.persist_file
	tbl.unique = settings.unique
	tbl.Table = settings.table_reference
	tbl.data_source = settings.data_source

	tbl:Init()
	return tbl
end

function wyozimc.CreateProxyManipulator(settings)
	local tbl = {}
	setmetatable(tbl, {
		-- tbl extends ProxyManipulator extends Manipulator
		__index = function(self, k)
			return wyozimc.manip_proxy_meta[k] or wyozimc.manip_meta[k]
		end
	})

	tbl.net_message_id = settings.net_message_id
	tbl.unique = settings.unique
	tbl.Table = settings.table_reference
	tbl.update_callback = settings.update_callback

	tbl:Init()
	return tbl
end
