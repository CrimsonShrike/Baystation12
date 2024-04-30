dockingtube// Includes:
// - dockingtube controllers
// - dockingtube computers
// - dockingtube test buttons
// - Dummy turfs

// An dockingtube is a system for large overmap ships that couldnt exist in same zlevel to dock to each other
// dockingtubes will extend and use portals to provide a seamless (from the point of view of player) connection
// For simplicity dockingtubes work in pairs

/* -------------------- Controller -------------------- */

/obj/dockingtube_controller
	name = "dockingtube Controller"
	desc = "This is an invisible thing. Yet you can see it. You notice reality unraveling around you."
	icon = 'icons/misc/mark.dmi'
	icon_state = "dockingtube"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	density = 0

	var/tunnel_width = 1

	var/portal_id = "default"
	var/working = 0
	var/maintaining_bridge = 0
	var/obj/dockingtube_controller/linked = null

	var/list/turf_path = new/list()
	var/list/maintaining_turfs = new/list()

	var/list/obj/machinery/computer/airbr/computers = null

	var/floor_turf = /turf/simulated/floor/tiled/white/monotile
	var/wall_turf = /turf/simulated/shuttle/wall
	var/ceiling_turf = /turf/simulated/floor/ceiling
	var/floor_light_type = /obj/machinery/light/small/floor

	var/list/obj/my_lights = null

	var/slide_delay = 1 SECOND

	var/length = 10 //Length in turfs, tweak this later and use visual tricks to hide it from people observing near the bridge. (we can use an overlay to hide the rest)


/obj/dockingtube_controller/Initialize()
	. = ..()

/obj/dockingtube_controller/proc/get_link()
		// for_by_tcl(C, /obj/dockingtube_controller)
		// 	if(C.z == src.z && C.id == src.id && C != src)
		// 		linked = C
		// 		break

/obj/dockingtube_controller/proc/toggle_bridge()
		// if(linked == null) get_link()
		// if(linked == null) return

		// if(linked.maintaining_bridge)
		// 	return linked.remove_bridge()
		// else if(maintaining_bridge)
		// 	return linked.remove_bridge()
		// else
		// 	return establish_bridge()

	if(maintaining_bridge)
		return remove_bridge()
	return establish_bridge()

/obj/dockingtube_controller/proc/pressurize()
		// if(linked == null) get_link()
		// if(linked == null) return

		// if(linked.working || working) return
		// if(!linked.maintaining_bridge && !maintaining_bridge) return

		// if(!maintaining_turfs.len) return

		//Todo

/obj/dockingtube_controller/proc/get_state_string()
		if(linked == null) get_link()
		if(linked == null) return "ERROR: Connection to secondary dockingtube controller lost."

		if(linked.working || working) return "dockingtube controller working. Please wait."
		if(linked.maintaining_bridge || maintaining_bridge) return "dockingtube established."
		if(!linked.maintaining_bridge && !maintaining_bridge) return "No active dockingtube."

		return "Unknown State."

/obj/dockingtube_controller/proc/is_working()
		// if(linked == null) get_link()
		// if(linked == null) return 0

		if(linked?.working || working) return 1
		else return 0

/obj/dockingtube_controller/proc/establish_bridge()
	// if(linked == null) get_link()
	// if(linked == null) return
	// if(linked.working || working) return
	// if(linked.maintaining_bridge || maintaining_bridge) return
	// if((linked.x != src.x && linked.y != src.y) || linked.z != src.z) return
	working = TRUE
	maintaining_bridge = TRUE
	//spawn(0)
	turf_path.Cut()
	var/turf/current = src.loc
	turf_path.Add(current)
	var/direction = dir //Bridges always extend in their direction
	turf_path[current] = direction
	while(turf_path.len < length)
		var/previous = current
		current = get_step(current, direction)
		turf_path.Add(current)
		direction = get_dir(previous,current)
		turf_path[current] = direction

	var/turf/curr
	var/j = 1
	var/light_index = 1
	for(var/turf/T in turf_path)
		if(j % 3 == 2 && floor_light_type)
			var/obj/light = null
			if(light_index <= length(my_lights))
				light = my_lights[light_index]
			else
				if(!my_lights)
					my_lights = list()
				light = new floor_light_type(T)
				my_lights += light
			light.forceMove(T)
			light.alpha = 0
			light_index++
		j++

	for(var/turf/T in turf_path)
		to_world("Turf in path [T]")
		var/dir = turf_path[T]
		for(var/i = -tunnel_width, i <= tunnel_width, i++)
			if(abs(i) == tunnel_width) // wall
				curr = get_steps(T, turn(dir, 90),i)
				to_world("Turf in path wall [i] [curr]")
				animate_turf_slideout(curr, src.wall_turf, dir, slide_delay)
			else // floor
				curr = get_steps(T, turn(dir, 90),i)
				to_world("Turf in path floor [i] [curr]")
				animate_turf_slideout(curr, src.floor_turf, dir, slide_delay)
			curr.set_dir(dir)
			maintaining_turfs.Add(curr)
		//playsound(T, 'sound/effects/dockingtube_dpl.ogg', 50, TRUE)
		sleep(slide_delay)
		for(var/i = -tunnel_width, i <= tunnel_width, i++)
			curr = get_steps(T, turn(dir, 90), i)
			animate_turf_slideout_cleanup(curr)
	for(var/obj/light in my_lights)
		//animate_open_from_floor(light, time=1 SECOND, self_contained=0)
		light.alpha = 255
	sleep(1 SECOND)
	for(var/obj/light in my_lights)
		light.filters = null
		// var/obj/machinery/light/l = light
		// if(istype(l))
		// 	l.set_
	working = 0
	//updateComps()
	return

/obj/dockingtube_controller/proc/remove_bridge()
	// if(linked == null) get_link()
	// if(linked == null) return
	// if(linked.working || working) return
	// if(!linked.maintaining_bridge && !maintaining_bridge) return
	// if(!maintaining_bridge && linked.maintaining_bridge)
	// 	linked.remove_bridge()
	// 	return
	working = 1
	maintaining_bridge = 0
	playsound(src.loc, 'sound/machines/warning-buzzer.ogg', 50, 1)

	spawn(2 SECONDS)
		var/list/path_reverse = reverselist(turf_path)
		for(var/obj/light in src.my_lights)
			animate_close_into_floor(light, time=1 SECOND, self_contained=0)
		sleep(1 SECOND)
		for(var/obj/light in my_lights)
			light.forceMove(src)
			// light.remove_filter("alpha white")
			// light.remove_filter("alpha black")
			// light.alpha = 0

		var/turf/curr
		for(var/turf/T in path_reverse)
			var/dir = turf_path[T]
			var/opdir = turn(dir, 180)
			for(var/i = -tunnel_width, i <= tunnel_width, i++)
				curr = get_steps(T, turn(dir, 90), i)
				animate_turf_slidein(curr, get_base_turf_by_area(curr), opdir, slide_delay)
			//playsound(T, 'sound/effects/dockingtube_dpl.ogg', 50, TRUE)
			sleep(slide_delay)
			for(var/i = -tunnel_width, i <= tunnel_width, i++)
				curr = get_steps(T, turn(dir, 90), i)
				animate_turf_slidein_cleanup(curr)

		maintaining_turfs.Cut()
		working = 0
		//updateComps()
	return

	// proc/updateComps()
	// 	for (var/obj/machinery/computer/airbr/C in src.computers)
	// 		C.updateDialog()


/* -------------------- Computer -------------------- */

// /obj/machinery/computer/airbr
// 	name = "dockingtube Computer"
// 	desc = "Used to control the dockingtube."
// 	id = "noodles"
// 	icon = 'icons/obj/airtunnel.dmi'
// 	icon_state = "airbr0"

// 	// set this var to 1 in the map editor if you want the dockingtube to establish and pressurize when the round starts
// 	// only do it to ONE of the computers for the dockingtube ID or they will both try to do it and get confused
// 	var/starts_established = 0

// 	var/working = 0
// 	var/state_str = ""

// 	req_access = list(access_heads)

// 	var/list/links = list()

// 	var/obj/dockingtube_controller/primary_controller = null

// 	var/emergency = 0 // 1 to automatically extend when the emergency shuttle docks
// 	var/connected_dock = null

// 	New()
// 		..()
// 		START_TRACKING
// 		if (src.emergency && emergency_shuttle) // emergency_shuttle is the controller datum
// 			emergency_shuttle.dockingtubes += src
// 		if (src.connected_dock)
// 			RegisterSignal(GLOBAL_SIGNAL, src.connected_dock, PROC_REF(dock_signal_handler))

// 	initialize()
// 		..()
// 		update_status()
// 		if (starts_established && length(links))
// 			SPAWN(1 SECOND)
// 				do_initial_extend()

// 	disposing()
// 		STOP_TRACKING
// 		..()

// 	proc/dock_signal_handler(datum/holder, var/signal)
// 		switch(signal)
// 			if(DOCK_EVENT_INCOMING)
// 				src.establish_bridge()
// 			if(DOCK_EVENT_ARRIVED)
// 				src.pressurize()
// 			if(DOCK_EVENT_DEPARTED)
// 				src.remove_bridge()

// 	proc/get_links()
// 		for_by_tcl(C, /obj/dockingtube_controller)
// 			if (C.id == src.id)
// 				links.Add(C)
// 				if (C.primary_controller)
// 					src.primary_controller = C
// 				if(isnull(C.computers))
// 					C.computers = list(src)
// 				else
// 					C.computers += src

// 	process()
// 		..()
// 		update_status()
// 		if (starts_established && length(links))
// 			SPAWN(1 SECOND)
// 				do_initial_extend()
// 		return

// 	proc/pick_controller()
// 		if (istype(src.primary_controller))
// 			return src.primary_controller
// 		var/obj/dockingtube_controller/C = pick(links)
// 		if (istype(C))
// 			return C

// 	proc/do_initial_extend()
// 		var/obj/dockingtube_controller/C = src.pick_controller()
// 		if (!istype(C))
// 			return

// 		C.establish_bridge()

// 		var/sanity_counter = 0
// 		while (C.working && sanity_counter < 30)
// 			sanity_counter++
// 			sleep(2 SECONDS)

// 		C.pressurize()
// 		starts_established = 0

// 	proc/update_status()
// 		if (!links.len)
// 			get_links()

// 		if (!links.len)
// 			working = 0
// 			starts_established = 0
// 			state_str = "ERROR: No controllers found."
// 			return

// 		var/obj/dockingtube_controller/C = src.pick_controller()
// 		if (!istype(C))
// 			return

// 		working = C.is_working()
// 		icon_state = "airbr[working]"
// 		state_str = C.get_state_string()

// 	attack_hand(var/mob/user, params)
// 		if (..(user, params))
// 			return

// 		update_status()

// 		var/dat = {"
// 		<b>Controller Status:</b><BR>
// 		[state_str]<BR><BR>
// 		[working ? "Working..." : "Idle..."]<BR><BR>
// 		<b>dockingtube Control:</b><BR>
// 		<A href='?src=\ref[src];create=1'>Establish</A><BR>
// 		<A href='?src=\ref[src];remove=1'>Retract</A><BR>
// 		<A href='?src=\ref[src];air=1'>Pressurize</A><BR>
// 		"}

// 		if (user.client?.tooltipHolder) // BAD MONKEY!
// 			user.client.tooltipHolder.showClickTip(src, list(
// 				"params" = params,
// 				"title" = src.name,
// 				"content" = dat,
// 			))

// 		return

// 	proc/ensure_links()
// 		if (!src.links.len)
// 			src.get_links()
// 		if (!src.links.len)
// 			src.working = 0
// 			src.state_str = "ERROR: No controllers found."
// 			return 0
// 		else
// 			return 1

// 	proc/establish_bridge()
// 		if (!src.ensure_links())
// 			return 0
// 		var/obj/dockingtube_controller/C = src.pick_controller()
// 		if (istype(C))
// 			C.establish_bridge()
// 			return 1

// 	proc/remove_bridge()
// 		if (!src.ensure_links())
// 			return 0
// 		var/obj/dockingtube_controller/C = src.pick_controller()
// 		if (istype(C))
// 			C.remove_bridge()
// 			return 1

// 	proc/pressurize()
// 		if (!src.ensure_links())
// 			return 0
// 		var/obj/dockingtube_controller/C = src.pick_controller()
// 		if (istype(C))
// 			C.pressurize()
// 			return 1

// 	Topic(href, href_list)
// 		if (..(href, href_list))
// 			return

// 		if (href_list["create"])
// 			if (src.emergency && emergency_shuttle)
// 				if (emergency_shuttle.location != SHUTTLE_LOC_STATION)
// 					boutput(usr, SPAN_ALERT("The dockingtube cannot be deployed while the shuttle is not in position."))
// 					return
// 			if (!(src.allowed(usr)))
// 				boutput(usr, SPAN_ALERT("Access denied."))
// 				return
// 			if (src.establish_bridge())
// 				logTheThing(LOG_STATION, usr, "extended the dockingtube at [usr.loc.loc] ([log_loc(usr)])")

// 		else if (href_list["remove"])
// 			if (!(src.allowed(usr)))
// 				boutput(usr, SPAN_ALERT("Access denied."))
// 				return
// 			if (src.remove_bridge())
// 				logTheThing(LOG_STATION, usr, "retracted the dockingtube at [usr.loc.loc] ([log_loc(usr)])")

// 		else if (href_list["air"])
// 			if (!(src.allowed(usr)))
// 				boutput(usr, SPAN_ALERT("Access denied."))
// 				return
// 			if (src.pressurize())
// 				logTheThing(LOG_STATION, usr, "pressurized the dockingtube at [usr.loc.loc] ([log_loc(usr)])")

// 		update_status()
// 		src.updateDialog()
// 		return

// 	power_change()
// 		if(status & BROKEN)
// 			icon_state = "airbrbr"
// 			light.disable()

// 		else if(powered())
// 			icon_state = "airbr0"
// 			status &= ~NOPOWER
// 			light.enable()
// 		else
// 			SPAWN(rand(0, 15))
// 				icon_state = "airbroff"
// 				status |= NOPOWER
// 				light.disable()
// 	set_broken()
// 		if (status & BROKEN) return
// 		var/datum/effects/system/harmless_smoke_spread/smoke = new /datum/effects/system/harmless_smoke_spread()
// 		smoke.set_up(5, 0, src)
// 		smoke.start()
// 		icon_state = initial(icon_state)
// 		icon_state = "airbrbr"
// 		light.disable()
// 		status |= BROKEN

// /obj/machinery/computer/airbr/emergency_shuttle
// 	emergency = 1

// /obj/machinery/computer/airbr/trader_left // matching mapping area conventions
// 	connected_dock = COMSIG_DOCK_TRADER_WEST

// /obj/machinery/computer/airbr/trader_right
// 	connected_dock = COMSIG_DOCK_TRADER_EAST

/* -------------------- Button -------------------- */
/obj/machinery/airbr_test_button
	name = "dockingtube Button"
	icon = 'icons/obj/structures/buttons.dmi'
	icon_state = "launcherbtt"
	desc = ""
	var/state = 0
	anchored = ANCHORED

/obj/machinery/airbr_test_button/attack_hand(mob/user)
	for(var/obj/dockingtube_controller/C in range(3, src))
		to_chat(user, SPAN_NOTICE("[C.toggle_bridge()]"))
		break
	return

/obj/overlay/tile_effect/fake_fullbright
	icon = 'icons/effects/white.dmi'
	plane = PLANE_LIGHTING
	layer = LIGHTING_LAYER_FULLBRIGHT
	blend_mode = BLEND_OVERLAY

/obj/overlay/tile_effect/sliding_turf
	mouse_opacity = 0

/obj/overlay/tile_effect/sliding_turf/New(turf/T)
	. = ..()
	appearance = T.appearance

/proc/animate_turf_slideout(turf/T, new_turf_type, dir, time)
	var/image/orig = new
	orig.loc = T
	orig.appearance = T.appearance
	orig.layer -= 1
	//var/was_fullbright = T.fullbright
	orig.appearance_flags |= RESET_TRANSFORM
	T.ChangeTurf(new_turf_type)
	orig.layer = T.layer + 0.1
	switch(dir)
		if(WEST)
			T.transform = list(1, 0, WORLD_ICON_SIZE, 0, 1, 0)
		if(EAST)
			T.transform = list(1, 0, -WORLD_ICON_SIZE, 0, 1, 0)
		if(SOUTH)
			T.transform = list(1, 0, 0, 0, 1, WORLD_ICON_SIZE)
		if(NORTH)
			T.transform = list(1, 0, 0, 0, 1, -WORLD_ICON_SIZE)
	animate(T, transform=list(1, 0, 0, 0, 1, 0), time=time)

/proc/animate_turf_slideout_cleanup(turf/T)
	T.layer++
	T.underlays.Cut()

/proc/animate_turf_slidein(turf/T, new_turf_type, dir, time)
	var/obj/overlay/tile_effect/sliding_turf/slide = new(T)
	T.ChangeTurf(new_turf_type)
	var/list/tr
	slide.layer += 1
	switch(dir)
		if(WEST)
			tr = list(1, 0, -WORLD_ICON_SIZE, 0, 1, 0)
		if(EAST)
			tr = list(1, 0, WORLD_ICON_SIZE, 0, 1, 0)
		if(SOUTH)
			tr = list(1, 0, 0, 0, 1, -WORLD_ICON_SIZE)
		if(NORTH)
			tr = list(1, 0, 0, 0, 1, WORLD_ICON_SIZE)
	animate(slide, transform=tr, time=time)

/proc/animate_turf_slidein_cleanup(turf/T)
	var/obj/overlay/tile_effect/sliding_turf/slide = locate() in T
	if(slide)
		qdel(slide)

/proc/animate_open_from_floor(atom/A, time=1 SECOND, self_contained=1)
	// A.add_filter("alpha white", 200, alpha_mask_filter(icon='icons/effects/white.dmi', x=16))
	// A.add_filter("alpha black", 201, alpha_mask_filter(icon='icons/effects/black.dmi', x=-16)) // has to be a different dmi because byond
	// animate(A.get_filter("alpha black"), x=0, time=time, easing=CUBIC_EASING | EASE_IN)
	// animate(A.get_filter("alpha white"), x=0, time=time, easing=CUBIC_EASING | EASE_IN, flags=ANIMATION_PARALLEL)
	// if(self_contained) // assume we're starting from being invisible
	// 	A.alpha = 255
	// if(self_contained)
	// 	SPAWN(time)
	// 		A.remove_filter(list("alpha white", "alpha black"))

/proc/animate_close_into_floor(atom/A, time=1 SECOND, self_contained=1)
	// A.add_filter("alpha white", 200, alpha_mask_filter(icon='icons/effects/white.dmi', x=0))
	// A.add_filter("alpha black", 201, alpha_mask_filter(icon='icons/effects/black.dmi', x=0)) // has to be a different dmi because byond
	// animate(A.get_filter("alpha black"), x=-16, time=time, easing=CUBIC_EASING | EASE_IN)
	// animate(A.get_filter("alpha white"), x=16, time=time, easing=CUBIC_EASING | EASE_IN, flags=ANIMATION_PARALLEL)
	// if(self_contained)
	// 	SPAWN(time)
	// 		A.remove_filter(list("alpha white", "alpha black"))
	// 		A.alpha = 0
