/datum/event/laser_fire
	startWhen		= 1	// About one minute early warning
	endWhen 		= 60	// Adjusted automatically in tick()
	var/alarmWhen   = 1
	var/next_attack = 1
	var/waves = 1
	var/start_side
	var/next_attack_lower = 1
	var/next_attack_upper = 2


/datum/event/laser_fire/setup()
	waves = 0
	for(var/n in 1 to severity)
		waves += rand(100,200)

	start_side = pick(GLOB.cardinal)
	endWhen = worst_case_end()

/datum/event/laser_fire/announce()
	switch(severity)
		if(EVENT_LEVEL_MAJOR)
			command_announcement.Announce("WARNING: Pulse weaponry lock-on detected. Brace for Impact.", "[station_name()] Sensor Array")
		else
			command_announcement.Announce("ALERT: Pulse beam electromagnetic signatures detected near [station_name()]. Brace for Impact", "[station_name()] Sensor Array")

/datum/event/laser_fire/tick()
	// Same as meteor event, send alarms to shield diffusers, else deactivated parts are going to take full damage
	if(alarmWhen < activeFor)
		for(var/obj/machinery/shield_diffuser/SD in SSmachines.machinery)
			if(isStationLevel(SD.z))
				SD.meteor_alarm(10)

	if(waves && activeFor >= next_attack)
		send_wave()

/datum/event/laser_fire/proc/worst_case_end()
	return activeFor + ((30 / severity) * waves) + 30

/datum/event/laser_fire/proc/send_wave()
	var/pick_side = prob(80) ? start_side : (prob(50) ? turn(start_side, 90) : turn(start_side, -90))
	spawn() spawn_lasers(get_wave_size(), pick_side)
	next_attack += rand(next_attack_lower, next_attack_upper) / severity
	waves--
	endWhen = worst_case_end()

/datum/event/laser_fire/proc/get_wave_size()
	return severity * rand(10,20)

/datum/event/laser_fire/end()
	switch(severity)
		if(EVENT_LEVEL_MAJOR)
			command_announcement.Announce("The [station_name()] is now outside firing range.", "[station_name()] Sensor Array")
		else
			command_announcement.Announce("No more pulse signatures detected near [station_name()]", "[station_name()] Sensor Array")


/datum/event/laser_fire/overmap
	next_attack_lower = 8
	next_attack_upper = 16
	next_attack = 0
	var/obj/effect/overmap/ship/victim

/datum/event/laser_fire/overmap/Destroy()
	victim = null
	. = ..()

/datum/event/laser_fire/overmap/tick()
	if(victim && !victim.is_still()) //Flying towards it, so probably getting shot from front
		start_side = prob(90) ? victim.fore_dir : pick(GLOB.cardinal)
	else //Unless you're standing in the middle of it
		start_side = pick(GLOB.cardinal)
	..()

/datum/event/laser_fire/overmap/get_wave_size()
	. = ..()
	if(!victim)
		return
	if(victim.is_still()) //Standing still means lockon is real easy
		. = round(. * 2)
	if(victim.get_speed() < 0.3) //Slow and steady
		return
	if(victim.get_speed() > 3) //Full speed ahead, bit harder to lock-on
		. *= 0.7

/proc/spawn_lasers(var/number, var/startSide)
	for(var/i = 0; i < number; i++)
		spawn_laser(startSide)

/proc/spawn_laser(var/startSide)
	var/start = pick_meteor_start(startSide)
	var/level = start[1]
	var/turf/location = start[2]
	var/turf/pickedgoal = spaceDebrisFinishLoc(startSide, level) //for now side to side, check how it works

	var/obj/item/projectile/beam/pulse/artillery/P = new /obj/item/projectile/beam/pulse/artillery()
	P.original = pickedgoal
	P.starting = location

	P.loc = location
	P.launch(pickedgoal, null, rand(0,5), rand(0,5), rand(0,10))
