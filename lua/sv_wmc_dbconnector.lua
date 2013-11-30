function wyozimc.ConnectToDatabase(reconnect)
	if not wyozimc.UseDatabaseStorage then return end
	if not reconnect and wyozimc.Database then return end

	local dbdetails = wyozimc.DatabaseDetails
	local db, err = FDB.NewConnect("mysqloo", {
		host = dbdetails.Host,
		name = dbdetails.User,
		password = dbdetails.Password,
		database = dbdetails.Database
	})
	if not db then
		ErrorNoHalt("[WMC-ERROR] Failed to connect to database\n")
		return
	end

	db:Query(nil, nil, "CREATE TABLE IF NOT EXISTS  " .. dbdetails.TablePrefix .. "media (name TEXT, link TEXT, addedby TEXT, time INT, custom TEXT)")

	wyozimc.Database = db
	wyozimc.Debug("Succesfully connected to database")
end

wyozimc.ConnectToDatabase()
concommand.Add("wyozimc_reconndb", function(ply)
	if ply:IsValid() and not ply:IsSuperAdmin() then return end
	wyozimc.ConnectToDatabase(true)
end)
concommand.Add("wyozimc_media_filetodb", function(ply)
	if ply:IsValid() and not ply:IsSuperAdmin() then return end
	if not wyozimc.Database then return end

	local tbl = util.JSONToTable(file.Read("wyozimedia.txt", "DATA") or "{}")
	for _,v in ipairs(tbl) do
		wyozimc.ServerMediaList:Add(v)
	end
end)