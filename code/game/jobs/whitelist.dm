#define WHITELISTFILE "data/whitelist.txt"

var/list/whitelist = list()

/hook/startup/proc/loadWhitelist()
	if(config.usewhitelist)
		load_jobwhitelistSQL()
	return 1

/proc/load_whitelist()
	whitelist = file2list(WHITELISTFILE)
	if(!whitelist.len)	whitelist = null

/proc/check_whitelist(mob/M /*, var/rank*/)
	if(!whitelist)
		return 0
	if(check_rights(R_MOD, 0, M))
		return 1
	return ("[M.ckey]" in whitelist)

/var/list/alien_whitelist = list()

/hook/startup/proc/loadAlienWhitelist()
	if(config.usealienwhitelist)
		if(config.usealienwhitelistSQL)
			if(!load_alienwhitelistSQL())
				world.log << "Could not load alienwhitelist via SQL"
		else
			load_alienwhitelist()
	return 1
/proc/load_alienwhitelist()
	var/text = file2text("config/alienwhitelist.txt")
	if (!text)
		log_misc("Failed to load config/alienwhitelist.txt")
		return 0
	else
		alien_whitelist = splittext(text, "\n")
		return 1

/proc/check_species_whitelist(client/C, var/species)
	if(!C || !species || !istype(species,/datum/species))
		return 0
	var/datum/species/S = species
	if(!config.usealienwhitelist)
		return 1
	if(check_rights(R_ADMIN, 0))
		return 1
	if(!(S.spawn_flags & (SPECIES_IS_WHITELISTED|SPECIES_IS_RESTRICTED)))
		return 1

	var/DBQuery/query = dbcon.NewQuery("SELECT * FROM whitelist WHERE ckey = '[C.ckey]' AND race = '[S.name]' OR  race = 'ALL'")
	if(!query.Execute())
		world.log << dbcon.ErrorMsg()
		return 0
	else
		while(query.NextRow())
			var/list/row = query.GetRowData()
			if(row["ckey"] == C.ckey && findtext(row["race"], S.name))
				alien_whitelist.Add("[C.ckey] - [S.name]")
				return 1
			else
				return 0


/*	else
		while(query.NextRow())
			var/list/row = query.GetRowData()
			if(row["ckey"] == C.ckey && row["race"] == species)
				return 1

			if(alien_whitelist[row["ckey"]])
				var/list/A = alien_whitelist[row["ckey"]]
				A.Add(row["race"])
			else
				alien_whitelist[row["ckey"]] = list(row["race"])*/
//	return 1
/*
/proc/load_alienwhitelistSQL()
	var/DBQuery/query = dbcon.NewQuery("SELECT * FROM whitelist")
	if(!query.Execute())
		world.log << dbcon.ErrorMsg()
		return 0
	else
//		var/list/A
		while(query.NextRow())
			var/list/row = query.GetRowData()
			if(row["ckey"])
				if(findtext(row["race"], "tajaran"))
					alien_whitelist.Add("[C.ckey] - [species]")
				if(findtext(row["race"], "soghun"))
					alien_whitelist.Add("[C.ckey] - [species]")
				if(findtext(row["race"], "unathi"))
					alien_whitelist.Add("[C.ckey] - [species]")
				if(findtext(row["race"], "skrell"))
					alien_whitelist.Add("[C.ckey] - [species]")
		world.log << "Whitelist is now [alien_whitelist.len] Big."
	return 1
*/
/proc/load_alienwhitelistSQL()
	var/DBQuery/query = dbcon.NewQuery("SELECT * FROM whitelist")
	if(!query.Execute())
		world.log << dbcon.ErrorMsg()
		return 0
	else
		while(query.NextRow())
			var/list/row = query.GetRowData()
			if(alien_whitelist[row["ckey"]])
				var/list/A = alien_whitelist[row["ckey"]]
				A.Add(row["race"])
			else
				alien_whitelist[row["ckey"]] = list(row["race"])
	return 1

/proc/load_jobwhitelistSQL()
	var/DBQuery/query = dbcon.NewQuery("SELECT * FROM whitelist WHERE jobwhitelist = 1")
	if(!query.Execute())
		world.log << dbcon.ErrorMsg()
		return 0
	else
		while(query.NextRow())
			var/list/row = query.GetRowData()
			whitelist.Add(row["ckey"])
	return 1

/proc/is_species_whitelisted(mob/M, var/species_name)
	var/datum/species/S = all_species[species_name]
	return is_alien_whitelisted(M, S)

//todo: admin aliens
/proc/is_alien_whitelisted(mob/M, var/species)
	if(!M || !species)
		return 0
	if(!config.usealienwhitelist)
		return 1
	if(check_rights(R_ADMIN, 0, M))
		return 1

	if(istype(species,/datum/language))
		var/datum/language/L = species
		if(!(L.flags & (WHITELISTED|RESTRICTED)))
			return 1
		return whitelist_lookup(L.name, M.ckey)

	if(istype(species,/datum/species))
		var/datum/species/S = species
		if(!(S.spawn_flags & (SPECIES_IS_WHITELISTED|SPECIES_IS_RESTRICTED)))
			return 1
		return whitelist_lookup(S.name, M.ckey)

	return 0

/proc/whitelist_lookup(var/item, var/ckey)
	if(!alien_whitelist)
		return 0

	if(config.usealienwhitelistSQL)
		//SQL Whitelist
		if(!(ckey in alien_whitelist))
			return 0;
		var/list/whitelisted = alien_whitelist[ckey]
		if(findtext(whitelisted, item) in whitelisted)
			return 1
	else
		//Config File Whitelist
		for(var/s in alien_whitelist)
			if(findtext(s,"[ckey] - [item]"))
				return 1
			if(findtext(s,"[ckey] - All"))
				return 1
	return 0

#undef WHITELISTFILE
