/obj/machinery/ship_map
	name = "ship holomap"
	desc = "A virtual map of the surrounding craft."
	icon = 'icons/obj/machines/stationmap.dmi'
	icon_state = "station_map"
	anchored = 1
	density = 0
	use_power = 1
	idle_power_usage = 10
	active_power_usage = 500

	light_color = "#64C864"
	//TODO: LIGHT CHANGED; FIX THIS
	//light_power = 1
	//light_range = 2

	construct_state = /decl/machine_construction/default/panel_closed
	maximum_component_parts = list(/obj/item/weapon/stock_parts = 0)         
	base_type = /obj/machinery/ship_map
	stock_part_presets = list(/decl/stock_part_preset/terminal_setup)

	var/light_power_on = 1
	var/light_range_on = 2

	layer = ABOVE_WINDOW_LAYER	// Above windows.

	var/mob/watching_mob = null
	var/image/small_station_map = null
	var/image/floor_markings = null
	var/image/panel = null

	var/original_zLevel = 1	// zLevel on which the station map was initialized.
	var/bogus = TRUE		// set to 0 when you initialize the station map on a zLevel that has its own icon formatted for use by station holomaps.
	var/datum/station_holomap/holomap_datum

/obj/machinery/ship_map/Destroy()
	SSminimap.station_holomaps -= src
	stopWatching()
	QDEL_NULL(holomap_datum)
	return ..()

/obj/machinery/ship_map/Initialize()
	holomap_datum = new()
	original_zLevel = loc.z
	bogus = FALSE
	. = ..()
	
	SSminimap.station_holomaps += src
	if(!SSminimap.holomaps[original_zLevel])
		bogus = TRUE
		holomap_datum.initialize_holomap_bogus()
		update_icon()
		return

	holomap_datum.initialize_holomap(get_turf(src), reinit = TRUE)

	small_station_map = image(icon = SSminimap.holomaps[original_zLevel].holomap_small)
	small_station_map.plane = LIGHTING_PLANE 
	small_station_map.layer = ABOVE_LIGHTING_LAYER

	floor_markings = image('icons/obj/machines/stationmap.dmi', "decal_station_map")
	floor_markings.dir = src.dir
	update_icon()

/obj/machinery/ship_map/attack_hand(var/mob/user)
	if(watching_mob && (watching_mob != user))
		to_chat(user, "<span class='warning'>Someone else is currently watching the holomap.</span>")
		return
	if(user.loc != loc)
		to_chat(user, "<span class='warning'>You need to stand in front of \the [src].</span>")
		return
	startWatching(user)

// Let people bump up against it to watch
/obj/machinery/ship_map/Bumped(var/atom/movable/AM)
	if(!watching_mob && isliving(AM) && AM.loc == loc)
		startWatching(AM)

// In order to actually get Bumped() we need to block movement.  We're (visually) on a wall, so people
// couldn't really walk into us anyway.  But in reality we are on the turf in front of the wall, so bumping
// against where we seem is actually trying to *exit* our real loc
/obj/machinery/ship_map/CheckExit(atom/movable/mover as mob|obj, turf/target as turf)
	// log_debug("[src] (dir=[dir]) CheckExit([mover], [target])  get_dir() = [get_dir(target, loc)]")
	if(get_dir(target, loc) == dir) // Opposite of "normal" since we are visually in the next turf over
		return FALSE
	else
		return TRUE

/obj/machinery/ship_map/proc/startWatching(var/mob/user)
	if(isliving(user) && anchored && !(stat & (NOPOWER|BROKEN)))
		if(user.client)
			holomap_datum.station_map.loc = GLOB.global_hud.holomap  // Put the image on the holomap hud
			holomap_datum.station_map.alpha = 0 // Set to transparent so we can fade in
			animate(holomap_datum.station_map, alpha = 255, time = 5, easing = LINEAR_EASING)
			flick("station_map_activate", src)
			user.client.screen |= GLOB.global_hud.holomap
			user.client.images |= holomap_datum.station_map

			watching_mob = user
			GLOB.moved_event.register(watching_mob, src, /obj/machinery/ship_map/proc/checkPosition)
			GLOB.destroyed_event.register(watching_mob, src, /obj/machinery/ship_map/proc/stopWatching)
			update_use_power(2)


			if(bogus)
				to_chat(user, "<span class='warning'>The holomap failed to initialize. This area of space cannot be mapped.</span>")
			else
				to_chat(user, "<span class='notice'>A hologram of the station appears before your eyes.</span>")

/obj/machinery/ship_map/attack_ai(var/mob/living/silicon/robot/user)
	return // TODO - Implement for AI ~Leshana
	// user.station_holomap.toggleHolomap(user, isAI(user))

/obj/machinery/ship_map/Process()
	..()
	if((stat & (NOPOWER|BROKEN)))
		stopWatching()

/obj/machinery/ship_map/proc/checkPosition()
	if(!watching_mob || (watching_mob.loc != loc) || (dir != watching_mob.dir))
		stopWatching()

/obj/machinery/ship_map/proc/stopWatching()
	if(watching_mob)
		if(watching_mob.client)
			animate(holomap_datum.station_map, alpha = 0, time = 5, easing = LINEAR_EASING)
			var/mob/M = watching_mob
			addtimer(CALLBACK(src, .proc/clear_image, M, holomap_datum.station_map), 5, TIMER_CLIENT_TIME)//we give it time to fade out
			clear_image(M, holomap_datum.station_map)
		GLOB.moved_event.unregister(watching_mob, src)
		GLOB.destroyed_event.unregister(watching_mob, src)
	watching_mob = null
	update_use_power(1)

/obj/machinery/ship_map/proc/clear_image(mob/M, image/I)
	if (M.client)
		M.client.images -= I

/obj/machinery/ship_map/on_update_icon()
	. = ..()
	overlays.Cut()
	if(stat & BROKEN)
		icon_state = "station_mapb"
	else if((stat & NOPOWER) || !anchored)
		icon_state = "station_map0"
	else
		icon_state = "station_map"

		if(bogus)
			holomap_datum.initialize_holomap_bogus()
		else
			overlays.Add(SSminimap.holomaps[original_zLevel].holomap_small)
			holomap_datum.initialize_holomap(get_turf(src))

	// Put the little "map" overlay downw where it looks nice
	if(floor_markings)
		floor_markings.dir = src.dir
		floor_markings.pixel_x = -src.pixel_x
		floor_markings.pixel_y = -src.pixel_y
		src.overlays.Add(floor_markings)

	if(panel_open)
		overlays.Add("station_map-panel")

/*/obj/machinery/ship_map/attackby(obj/item/weapon/W as obj, mob/user as mob)
	src.add_fingerprint(user)
	if(default_deconstruction_screwdriver(user, W))
		return
	if(default_deconstruction_crowbar(user, W))
		return
	return ..()*/	// Uncomment this if/when this is made constructable.

/obj/machinery/ship_map/ex_act(severity)
	switch(severity)
		if(1)
			qdel(src)
		if(2)
			if (prob(50))
				qdel(src)
			else
				set_broken()
		if(3)
			if (prob(25))
				set_broken()

// TODO: Make these constructable.

#define HOLOMAP_LEGEND_STYLING(X) SPAN_STYLE("font-family: 'Small Fonts'; font-size: 7px;", X)

/obj/screen/legend
	icon = null
	maptext_height = 128
	maptext_width = 128
	layer = HUD_ABOVE_ITEM_LAYER
	pixel_x = HOLOMAP_LEGEND_X
	var/saved_color
	var/datum/station_holomap/owner = null

/obj/screen/legend/cursor
	icon = 'icons/misc/holomap_markers.dmi'
	icon_state = "you"
	maptext_x = 11
	pixel_x = 93

/obj/screen/legend/Initialize(mapload, color, text)
	. = ..()
	src.color = color
	saved_color = color
	maptext = "<A href='?src=\ref[src]' style='color: #ffffff'>[HOLOMAP_LEGEND_STYLING(text)]</A>"
	alpha = 254

/obj/screen/legend/Click(location, control, params)
	if(!usr.incapacitated() && !isghost(usr))
		if(istype(owner))
			owner.legend_select(src)

//What happens when we are clicked on / when another is clicked on
/obj/screen/legend/proc/Select()
	//Start blinking
	animate(src, alpha = 0, time = 2, loop = -1, easing = JUMP_EASING | EASE_IN | EASE_OUT)
	animate(alpha = 254, time = 2, loop = -1, easing = JUMP_EASING | EASE_IN | EASE_OUT)

	for(var/area/A in SSminimap.holomaps[owner.z].holomap_areas)
		if(A.holomap_color == saved_color)
			overlays += SSminimap.holomaps[owner.z].holomap_areas[A]

/obj/screen/legend/proc/Deselect()
	//Stop blinking
	animate(src, flags = ANIMATION_END_NOW)

//Cursor doesnt do anything specific.
/obj/screen/legend/cursor/Select()

/obj/screen/legend/cursor/Deselect()

// Simple datum to keep track of a running holomap. Each machine capable of displaying the holomap will have one.
/datum/station_holomap
	var/image/station_map
	var/image/cursor
	var/list/obj/screen/legend/legend
	var/list/obj/screen/maptexts
	var/z = -1

/datum/station_holomap/Destroy(force)
	QDEL_NULL(station_map)
	QDEL_NULL(cursor)
	QDEL_NULL_LIST(legend)
	. = ..()

/datum/station_holomap/proc/initialize_holomap(turf/T, isAI = null, mob/user = null, reinit = FALSE)
	z = T.z
	if(!station_map || reinit)
		station_map = image(SSminimap.holomaps[z].holomap_combined)
	if(!cursor || reinit)
		cursor = image('icons/misc/holomap_markers.dmi', "you")
	if(!LAZYLEN(legend) || reinit)
		if(LAZYLEN(legend))
			QDEL_NULL_LIST(legend)
		LAZYINITLIST(legend)
		LAZYADD(legend, new /obj/screen/legend(null ,HOLOMAP_AREACOLOR_SECURITY, "■ Security"))
		LAZYADD(legend, new /obj/screen/legend(null ,HOLOMAP_AREACOLOR_MEDICAL, "■ Medical"))
		LAZYADD(legend, new /obj/screen/legend(null ,HOLOMAP_AREACOLOR_SCIENCE, "■ Research"))
		LAZYADD(legend, new /obj/screen/legend(null ,HOLOMAP_AREACOLOR_ENGINEERING, "■ Engineering"))
		LAZYADD(legend, new /obj/screen/legend(null ,HOLOMAP_AREACOLOR_CARGO, "■ Supply"))
		LAZYADD(legend, new /obj/screen/legend(null ,HOLOMAP_AREACOLOR_AIRLOCK, "■ Airlock"))
		LAZYADD(legend, new /obj/screen/legend(null ,HOLOMAP_AREACOLOR_ESCAPE, "■ Escape"))
		LAZYADD(legend, new /obj/screen/legend(null ,HOLOMAP_AREACOLOR_CREW, "■ Crew"))
		LAZYADD(legend, new /obj/screen/legend/cursor(null ,HOLOMAP_AREACOLOR_BASE, "You are here"))
	QDEL_NULL(maptexts)

	//This is where the fun begins
	if(GLOB.using_map.use_overmap)
		var/obj/effect/overmap/visitable/O = map_sectors["[z]"]

		var/current_z_offset_x = 0
		var/current_z_offset_y = 0

		if(istype(O))
			var/z_count = length(O.map_z)

			//Lets do some math. Shall we?
			// Given a number of levels space them in an even grid (example, if you have 4 2x2, if you have 8 2x4)
			//This assumes a square.
			station_map = image(icon(HOLOMAP_ICON, "stationmap"))

			var/x_cells = z_count
			var/y_cells = round(sqrt(z_count))

			while(x_cells%y_cells)
				y_cells--
				CHECK_TICK

			x_cells = y_cells
			y_cells = z_count / y_cells

			//Step 1. Determine how we will fit this stuff
			//First determine how many elements fit in a row
			var/effective_space = (HOLOMAP_ICON_SIZE - (HOLOMAP_MARGIN * 2))
			var/space_axis_x = effective_space / x_cells
			var/space_axis_y = effective_space / y_cells

			for(var/y = 0; y < y_cells; y++)
				for(var/x = 0; x < x_cells; x++)
					var/image/map_icon = image(SSminimap.holomaps[O.map_z[1 + x + x_cells*y]].holomap_base)
					map_icon.color = HOLOMAP_HOLOFIER
					var/image/areas = image(SSminimap.holomaps[O.map_z[1 + x + x_cells*y]].holomap_areas_combined)
					areas.appearance_flags = RESET_COLOR
					map_icon.overlays += areas

					map_icon.pixel_x = (space_axis_x / 2) + space_axis_x * x + HOLOMAP_MARGIN - world.maxx / 2
					map_icon.pixel_y = (space_axis_y / 2) + space_axis_y * y + HOLOMAP_MARGIN - world.maxy / 2
					if(O.map_z[1 + x + x_cells*y] == z)
						current_z_offset_x = (space_axis_x / 2) + space_axis_x * x + HOLOMAP_MARGIN - world.maxx / 2
						current_z_offset_y = (space_axis_y / 2) + space_axis_y * y + HOLOMAP_MARGIN - world.maxy / 2
					
					//var/obj/screen/maptext_overlay = image(icon())s
					var/obj/screen/maptext_overlay = new(null)
					maptext_overlay.icon = null
					maptext_overlay.layer = HUD_ABOVE_ITEM_LAYER + 1
					maptext_overlay.maptext = "LEVEL [1 + x + x_cells*y]"
					maptext_overlay.pixel_x = current_z_offset_x
					maptext_overlay.pixel_y = current_z_offset_y
					maptext_overlay.maptext_width = 96
					LAZYADD(maptexts, maptext_overlay)

					station_map.overlays += map_icon
					station_map.vis_contents += maptext_overlay

		var/pixel_y = HOLOMAP_LEGEND_Y
		for(var/obj/screen/legend/element in legend)
			element.owner = src
			element.pixel_y = pixel_y
			pixel_y -= 10
			station_map.vis_contents += element

		if(isAI)
			T = get_turf(user.client.eye)
		cursor.pixel_x = (T.x - 6 + current_z_offset_x) * PIXEL_MULTIPLIER
		cursor.pixel_y = (T.y - 6 + current_z_offset_y) * PIXEL_MULTIPLIER

		station_map.vis_contents += cursor

/datum/station_holomap/proc/legend_select(obj/screen/legend/L)
	for(var/obj/screen/legend/entry in legend)
		entry.Deselect()
	L.Select()

/datum/station_holomap/proc/initialize_holomap_bogus()
	station_map = image('icons/480x480.dmi', "stationmap")
	station_map.overlays |= image('icons/effects/64x64.dmi', "notfound", pixel_x = 7 * WORLD_ICON_SIZE, pixel_y = 7 * WORLD_ICON_SIZE)

#undef HOLOMAP_LEGEND_STYLING