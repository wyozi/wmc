
-- NOTE!
-- Database integration requires FruityDB SQL abstraction plugin (https://github.com/wyozi/fruitydb/)
-- It can be downloaded from https://github.com/wyozi/fruitydb/archive/master.zip and should be unzipped to addons folder

wyozimc.UseDatabaseStorage = false
wyozimc.DatabaseDetails = {
	Host = "localhost",
	User = "root",
	Password = "",
	Database = "wmc",
	TablePrefix = "wmc_"
}