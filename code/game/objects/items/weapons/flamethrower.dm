/obj/item/flamethrower
	name = "flamethrower"
	desc = "You are a firestarter!"
	icon = 'icons/obj/flamethrower.dmi'
	icon_state = "flamethrowerbase"
	item_state = "flamethrower_0"
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	force = 3.0
	throwforce = 10.0
	throw_speed = 1
	throw_range = 5
	w_class = ITEM_SIZE_LARGE
	origin_tech = list(TECH_COMBAT = 1)
	matter = list(MATERIAL_STEEL = 500)
	var/status = 0
	var/throw_amount = 100
	var/lit = 0	//on or off
	var/operating = 0//cooldown
	var/turf/previousturf = null
	var/obj/item/weldingtool/weldtool = null
	var/obj/item/device/assembly/igniter/igniter = null
	var/obj/item/tank/tank = null


/obj/item/flamethrower/Destroy()
	QDEL_NULL(weldtool)
	QDEL_NULL(igniter)
	QDEL_NULL(tank)
	. = ..()

/obj/item/flamethrower/Process()
	if(!lit)
		STOP_PROCESSING(SSobj, src)
		return null
	var/turf/location = loc
	if(istype(location, /mob/))
		var/mob/M = location
		if(M.l_hand == src || M.r_hand == src)
			location = M.loc
	if(isturf(location)) //start a fire if possible
		location.hotspot_expose(700, 2)
	return


/obj/item/flamethrower/on_update_icon()
	overlays.Cut()
	if(igniter)
		overlays += "+igniter[status]"
	if(tank)
		if(istype(tank, /obj/item/tank/hydrogen))
			overlays += "+htank"
		else
			overlays += "+ptank"
	if(lit)
		overlays += "+lit"
		item_state = "flamethrower_1"
	else
		item_state = "flamethrower_0"
	return

/obj/item/flamethrower/afterattack(atom/target, mob/user, proximity)
	// Make sure our user is still holding us
	if(user && user.get_active_hand() == src)
		if(user.a_intent == I_HELP) //don't shoot if we're on help intent
			to_chat(user, "<span class='warning'>You refrain from firing \the [src] as your intent is set to help.</span>")
			return
		var/turf/target_turf = get_turf(target)
		if(target_turf)
			var/turflist = getline(user, target_turf)
			flame_turf(turflist)

/obj/item/flamethrower/attackby(obj/item/W as obj, mob/user as mob)
	if(user.stat || user.restrained() || user.lying)	return
	if(isWrench(W) && !status)//Taking this apart
		if(weldtool)
			weldtool.dropInto(loc)
			weldtool = null
		if(igniter)
			igniter.dropInto(loc)
			igniter = null
		if(tank)
			tank.dropInto(loc)
			tank = null
		new /obj/item/stack/material/rods(get_turf(src))
		qdel(src)
		return

	if(isScrewdriver(W) && igniter && !lit)
		status = !status
		to_chat(user, "<span class='notice'>[igniter] is now [status ? "secured" : "unsecured"]!</span>")
		update_icon()
		return

	if(isigniter(W))
		var/obj/item/device/assembly/igniter/I = W
		if(I.secured)	return
		if(igniter)		return
		if(!user.unEquip(I, src))
			return
		igniter = I
		update_icon()
		return

	if(istype(W,/obj/item/tank))
		if(tank)
			to_chat(user, "<span class='notice'>There appears to already be a fuel tank loaded in [src]!</span>")
			return
		if(!user.unEquip(W, src))
			return
		tank = W
		update_icon()
		return

	if(istype(W, /obj/item/device/scanner/gas))
		var/obj/item/device/scanner/gas/A = W
		A.analyze_gases(src, user)
		return
	..()
	return


/obj/item/flamethrower/attack_self(mob/user as mob)
	if(user.stat || user.restrained() || user.lying)	return
	user.set_machine(src)
	if(!tank)
		to_chat(user, "<span class='notice'>Attach a fuel tank first!</span>")
		return
	var/dat = text("<TT><B>Flamethrower (<A HREF='?src=\ref[src];light=1'>[lit ? "<font color='red'>Lit</font>" : "Unlit"]</a>)</B><BR>\n Tank Pressure: [tank.air_contents.return_pressure()]<BR>\nAmount to throw: <A HREF='?src=\ref[src];amount=-100'>-</A> <A HREF='?src=\ref[src];amount=-10'>-</A> <A HREF='?src=\ref[src];amount=-1'>-</A> [throw_amount] <A HREF='?src=\ref[src];amount=1'>+</A> <A HREF='?src=\ref[src];amount=10'>+</A> <A HREF='?src=\ref[src];amount=100'>+</A><BR>\n<A HREF='?src=\ref[src];remove=1'>Remove fuel tank</A> - <A HREF='?src=\ref[src];close=1'>Close</A></TT>")
	show_browser(user, dat, "window=flamethrower;size=600x300")
	onclose(user, "flamethrower")
	return

/obj/item/flamethrower/return_air()
	if(tank)
		return tank.return_air()

/obj/item/flamethrower/Topic(href,href_list[])
	if(href_list["close"])
		usr.unset_machine()
		close_browser(usr, "window=flamethrower")
		return
	if(usr.stat || usr.restrained() || usr.lying)	return
	usr.set_machine(src)
	if(href_list["light"])
		if(!tank)	return
		if(tank.air_contents.get_by_flag(XGM_GAS_FUEL) <  1)	return
		if(!status)	return
		lit = !lit
		if(lit)
			START_PROCESSING(SSobj, src)
	if(href_list["amount"])
		throw_amount = throw_amount + text2num(href_list["amount"])
		throw_amount = max(50, min(5000, throw_amount))
	if(href_list["remove"])
		if(!tank)	return
		usr.put_in_hands(tank)
		tank = null
		lit = 0
		usr.unset_machine()
		close_browser(usr, "window=flamethrower")
	for(var/mob/M in viewers(1, loc))
		if((M.client && M.machine == src))
			attack_self(M)
	update_icon()
	return


//Called from turf.dm turf/dblclick
/obj/item/flamethrower/proc/flame_turf(turflist)
	if(!lit || operating)	return
	operating = 1
	for(var/turf/T in turflist)
		if(T.density || istype(T, /turf/space))
			break
		if(!previousturf && length(turflist)>1)
			previousturf = get_turf(src)
			continue	//so we don't burn the tile we be standin on
		if(previousturf && LinkBlocked(previousturf, T))
			break
		ignite_turf(T)
		sleep(1)
	previousturf = null
	operating = 0
	for(var/mob/M in viewers(1, loc))
		if((M.client && M.machine == src))
			attack_self(M)

/obj/item/flamethrower/proc/ignite_turf(turf/target)
	//TODO: DEFERRED Consider checking to make sure tank pressure is high enough before doing this...
	//Transfer 5% of current tank air contents to turf
	var/datum/gas_mixture/air_transfer = tank.remove_air_ratio(0.02*(throw_amount/100))
	//air_transfer.toxins = air_transfer.toxins * 5 // This is me not comprehending the air system. I realize this is retarded and I could probably make it work without fucking it up like this, but there you have it. -- TLE
	new/obj/effect/decal/cleanable/liquid_fuel/flamethrower_fuel(target,air_transfer.get_by_flag(XGM_GAS_FUEL),get_dir(loc,target))
	air_transfer.remove_by_flag(XGM_GAS_FUEL, 0)
	target.assume_air(air_transfer)
	//Burn it based on transfered gas
	//target.hotspot_expose(part4.air_contents.temperature*2,300)
	target.hotspot_expose((tank.air_contents.temperature*2) + 380,500) // -- More of my "how do I shot fire?" dickery. -- TLE
	//location.hotspot_expose(1000,500,1)

/obj/item/flamethrower/full/New(var/loc)
	..()
	weldtool = new /obj/item/weldingtool(src)
	weldtool.status = 0
	igniter = new /obj/item/device/assembly/igniter(src)
	igniter.secured = 0
	status = 1
	update_icon()


/obj/item/gun/flamethrower
	name = "flammenwerfer"
	desc = "You are a firestarter!"
	icon = 'icons/obj/flamethrower.dmi'
	icon_state = "flamethrowerbase"
	item_state = "flamethrower_0"
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	force = 3.0
	throwforce = 10.0
	throw_speed = 1
	throw_range = 5
	w_class = ITEM_SIZE_LARGE
	origin_tech = list(TECH_COMBAT = 1)
	matter = list(MATERIAL_STEEL = 500)
	//var/throw_amount = 100
	var/turf/previousturf = null
	// var/obj/item/weldingtool/weldtool = null
	// var/obj/item/device/assembly/igniter/igniter = null
	var/obj/item/reagent_containers/glass/beaker/beaker
	fire_sound = ''
	combustion = TRUE
	var/static/list/acceptable_fuels = list(/datum/reagent/fuel = 10,
											/datum/reagent/napalm = 30)

/obj/item/gun/flamethrower/toggle_safety(mob/user)
	if (user?.is_physically_disabled())
		return

	safety_state = !safety_state
	update_icon()
	if(user)
		user.visible_message(SPAN_WARNING("[user] [safety_state ? "extinguishes" : "ignites"] the pilot flame of \the [src] ."), SPAN_NOTICE("You [safety_state ? "extinguish" : "ignite"] the pilot flame of \the [src] ."), range = 3)
		last_safety_check = world.time
		playsound(src, 'sound/weapons/flipblade.ogg', 15, 1)

/obj/item/gun/flamethrower/consume_next_projectile()
	if(beaker)
		return beaker
	return null

/obj/item/gun/flamethrower/process_projectile(obj/projectile, mob/user, atom/target, target_zone, params)
	if(!projectile)
		return 0
	if(projectile.reagents) //You can get fuels even with impurities, as long as impurities arent main content
		var/datum/reagent/F = projectile.reagents.get_master_reagent()
		if(F.type in acceptable_fuels)
			
			//BURN BABY BURN! BURN BABY BURN!
			//Disco inferno

				set waitfor = 0
				var/turf/curloc = get_turf(user) //In case the target or we are expired.
				var/turf/targloc = get_turf(target)
				if (!targloc || !curloc) return //Something has gone wrong...

				var/amount_to_burn = min(10, F.volume)
				var/potency = acceptable_fuels[F.type]
				reagents.remove_reagent(F.type, amount_to_burn)

				unleash_flame(target, user, potency, amount_to_burn)



	play_fire_sound(user, null)
	return 1

/obj/item/gun/flamethrower/proc/unleash_flame(atom/target, mob/living/user, potency, amount_to_burn)
	set waitfor = 0
	if(!potency || !amount_to_burn)
		return

	// var/datum/reagent/R = current_mag.reagents.reagent_list[1]

	// var/flameshape = R.flameshape

	// R.intensityfire = Clamp(R.intensityfire, current_mag.reagents.min_fire_int, current_mag.reagents.max_fire_int)
	// R.durationfire = Clamp(R.durationfire, current_mag.reagents.min_fire_dur, current_mag.reagents.max_fire_dur)
	// R.rangefire = Clamp(R.rangefire, current_mag.reagents.min_fire_rad, current_mag.reagents.max_fire_rad)
	// var/max_range = R.rangefire

	var/max_range = amount_to_burn / 2

	for(var/turf/target_turf in )

	var/list/turf/turfs = getline(get_turf(user), get_turf(target))

	var/turf/to_fire = turfs[2]

	var/obj/flamer_fire/fire = locate() in to_fire
	if(fire)
		qdel(fire)

	//playsound(to_fire, src.get_fire_sound(), 50, TRUE)

	new /obj/flamer_fire(to_fire, user, potency, max_range, target)


/obj/flamer_fire
	name = "fire"
	desc = "Ouch!"
	anchored = 1
	mouse_opacity = 0
	icon = 'icons/effects/fire.dmi'
	icon_state = "dynamic_2"
	layer = BELOW_OBJ_LAYER

	var/firelevel = 12 //Tracks how much "fire" there is. Basically the timer of how long the fire burns
	var/burnlevel = 10 //Tracks how HOT the fire is. This is basically the heat level of the fire and determines the temperature.

	var/flame_icon = "dynamic"
	//var/flameshape = FLAMESHAPE_DEFAULT // diagonal square shape
	//var/weapon_source
	//var/weapon_source_mob
	var/turf/target_clicked

	//var/datum/reagent/tied_reagent
	//var/datum/reagents/tied_reagents
	//var/datum/callback/to_call

/obj/flamer_fire/Initialize(mapload, var/user, potency, fire_spread_amount = 0, atom/target = null)
	. = ..()

	color = COLOR_MUZZLE_FLASH
	//tied_reagent = new R.type() // Can't get deleted this way
	//tied_reagent.make_alike(R)

	//tied_reagents = obj_reagents

	target_clicked = target
	//weapon_source_mob = user

	icon_state = "[flame_icon]_2"

	firelevel = potency / 2
	burnlevel = potency

	START_PROCESSING(SSobj, src)

	var/burn_dam = burnlevel

	if(fire_spread_amount > 0)
		handle_fire_spread(fire_spread_amount, burn_dam)
	//Apply fire effects onto everyone in the fire


	for(var/mob/living/M in loc) //Deal bonus damage if someone's caught directly in initial stream


		M.fire_act(null, burnlevel * 70)
			
		//Dont deal extra damage if mob is not on fire
		if(M.fire_stacks)
			M.apply_damage(burn_dam, BURN)

		to_chat(M, SPAN_DANGER("You are being burned!"))

		if(weapon_source)
			M.last_damage_source = weapon_source
		else
			M.last_damage_source = initial(name)
		if(weapon_source_mob)
			var/mob/SM = weapon_source_mob
			SM.track_shot_hit(weapon_source)

/obj/flamer_fire/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/flamer_fire/Crossed(mob/living/M) //Only way to get it to reliable do it when you walk into it.
	if(!istype(M))
		return

	var/burn_damage = round(burnlevel*0.5)


	
	M.fire_act(null, burnlevel * 70)

	M.apply_damage(burn_damage, BURN) //This makes fire stronk.
	to_chat(M, SPAN_DANGER("You are burned!"))

/obj/flamer_fire/proc/on_update_icon()
	. = ..()
	if(burnlevel < 15 && flame_icon != "dynamic")
		color = "#c1c1c1" //make it darker to make show its weaker.
	switch(firelevel)	
		if(1 to 9)
			icon_state = "[flame_icon]_1"
			set_light(0.5, 1, 3, color)
		if(10 to 25)
			icon_state = "[flame_icon]_2"
			set_light(0.7, 2, 5, color)
		if(25 to INFINITY) //Change the icons and luminosity based on the fire's intensity
			icon_state = "[flame_icon]_3"
			set_light(1, 2, 7, color)

/obj/flamer_fire/process()
	var/turf/T = loc
	firelevel = max(0, firelevel)
	if(!istype(T)) //Is it a valid turf? Has to be on a floor
		qdel(src)
		return

	update_icon()

	if(!firelevel)
		qdel(src)
		return

	var/j = 0
	for(var/i in loc)
		if(++j >= 11) break
		if(isliving(i))
			var/mob/living/I = i
			// If I stand in the fire I deserve all of this. Also Napalm stacks quickly.
			M.fire_act(null, burnlevel * 70)
			I.show_message(text(SPAN_WARNING("You are burned!")), 1)
		if(isobj(i))
			var/obj/O = i
			O.fire_act(null, burnlevel * 70)

	//This has been made a simple loop, for the most part flamer_fire_act() just does return, but for specific items it'll cause other effects.
	firelevel -= 2 //reduce the intensity by 2 per tick
	return

/proc/fire_spread_recur(var/turf/target, var/source, var/source_mob, remaining_distance, direction, fire_lvl, burn_lvl, f_color)
	var/direction_angle = dir2angle(direction)
	var/obj/flamer_fire/foundflame = locate() in target
	if(!foundflame)
		var/datum/reagent/R = new()
		R.intensityfire = burn_lvl
		R.durationfire = fire_lvl

		R.burncolor = f_color
		new/obj/flamer_fire(target, source, source_mob, R)

	for(var/spread_direction in alldirs)

		var/spread_power = remaining_distance

		var/spread_direction_angle = dir2angle(spread_direction)

		var/angle = 180 - abs( abs( direction_angle - spread_direction_angle ) - 180 ) // the angle difference between the spread direction and initial direction

		switch(angle) //this reduces power when the explosion is going around corners
			if (0)
				//no change
			if (45)
				spread_power *= 0.75
			else //turns out angles greater than 90 degrees almost never happen. This bit also prevents trying to spread backwards
				continue

		switch(spread_direction)
			if(NORTH,SOUTH,EAST,WEST)
				spread_power -= 1
			else
				spread_power -= 1.414 //diagonal spreading

		if (spread_power < 1)
			continue

		var/turf/T = get_step(target, spread_direction)

		if(!T) //prevents trying to spread into "null" (edge of the map?)
			continue

		if(T.density)
			continue

		spawn(0)
			fire_spread_recur(T, source, source_mob, spread_power, spread_direction, fire_lvl, burn_lvl, f_color)

/proc/fire_spread(var/turf/target, var/source, var/source_mob, range, fire_lvl, burn_lvl, f_color)
	var/datum/reagent/R = new()
	R.intensityfire = burn_lvl
	R.durationfire = fire_lvl

	R.burncolor = f_color

	new/obj/flamer_fire(target, source, source_mob, R)
	for(var/direction in alldirs)
		var/spread_power = range
		switch(direction)
			if(NORTH,SOUTH,EAST,WEST)
				spread_power -= 1
			else
				spread_power -= 1.414 //diagonal spreading
		var/turf/T = get_step(target, direction)
		fire_spread_recur(T, source, source_mob, spread_power, direction, fire_lvl, burn_lvl, f_color)


	