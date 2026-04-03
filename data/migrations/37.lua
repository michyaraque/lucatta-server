function onUpdateDatabase()
	print("> Updating database to version 38 (argon2 password hashes)")

	db.query("ALTER TABLE `accounts` CHANGE `password` `password` VARCHAR(255) NOT NULL")
	return true
end
