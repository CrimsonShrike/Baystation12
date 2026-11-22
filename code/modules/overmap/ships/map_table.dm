/*
 * Sensor display tables ("map tables")
 *
 * Adjacent /obj/machinery/map_table segments form a /datum/map_table_group, which projects a
 * scaled-down live picture of the overmap around its ship across the whole tabletop, in-world.
 * Nobody's view is moved; anyone standing nearby sees it.
 *
 * Visibility and detection
 * ------------------------
 * Overmap objects that require sensor contact sit at INVISIBILITY_OVERMAP, and helm viewers only
 * ever see them through per-client marker images cast by the sensors. An onlooker at a table has
 * neither, and lowering the invisibility would hand every undetected contact to everyone. So the
 * table never relies on either:
 *
 *  - The overmap turfs are drawn through vis_contents purely as the background. Undetected objects
 *    on them stay invisible to the onlooker, exactly as they should.
 *  - Every sensor contact is drawn as a world-visible mirror of its marker, created and owned by the
 *    /datum/overmap_contact itself (see /datum/overmap_contact/proc/create_mirror()). Mirrors fade and
 *    ping alongside the marker, and are deleted with the contact.
 *
 * A table therefore shows exactly what the ship's sensors have identified, and nothing else.
 *
 * Zoom
 * ----
 * Clicking the table cycles its zoom. 1x fits the sensor diameter across the table's shorter side,
 * higher levels squeeze in proportionally more overmap, and "full" fits the whole overmap. Zooming out
 * past sensor range only adds background: known sectors and anything else that doesn't need contact.
 *
 * Planes and lighting
 * -------------------
 * Everything shown has to end up on the display's own plane. A vis_contents atom keeps its own plane
 * unless it inherits one, and KEEP_TOGETHER only flattens what shares the holder's plane - anything on
 * another plane renders loose instead, escaping both the scale and the mask. That is why the overmap
 * turfs and objects carry VIS_INHERIT_PLANE (see `/turf/unsimulated/map`), and why the contact mirrors
 * sit at FLOAT_PLANE. Giving one of them a plane of its own is enough to break the display.
 *
 * Layout is explicit. A vis_contents atom is drawn at its holder's position and nowhere else, offset
 * only by its own pixel offsets - there is no relative placement to inherit, least of all between a
 * table on a deck and turfs on the overmap. So every turf gets a cell of its own with the offset
 * worked out here, and no cell is ever asked to arrange more than the one turf it holds.
 *
 * That plane is the ordinary DEFAULT_PLANE, on a layer just above the tabletop sprite, so whatever is
 * resting on the table or standing at it covers the picture like it covers anything else. Being on the
 * normal plane means lighting darkens it, so the lit-screen look comes from an emissive overlay in the
 * shape of the screen: the lighting renderer masks itself against the emissive plane, so the darkness
 * over the screen is cut away and the picture inside it stays bright. Mobs block emissives by default,
 * so someone leaning over the table occludes the glow as well as the picture.
 *
 * Per-segment rendering
 * ---------------------
 * Every layer is KEEP_TOGETHER and alpha-masked to the segment's own tabletop shape, so nothing drawn
 * on the table can spill past its edge. The mask covers the whole tile on sides that join a neighbour,
 * so internal seams don't clip anything.
 *
 *   map_table
 *    |- screen      the hologram; carries the CRT line texture
 *    |   `- view    scaled down; holds one cell per overmap turf
 *    |       `- cell   one turf each, placed by its own pixel offset
 *    |- blip_layer  contact mirrors that fall on this segment; also soaks up clicks for the table
 *    `- scanline    the sweep, on top of everything
 *
 * The tabletop sprite itself gets an emissive overlay and a little light while the display is up, so a
 * working table reads as a lit screen rather than a dark slab with a picture floating over it.
 */

/// Smallest a contact blip is allowed to shrink to, relative to a full tile, so contacts stay readable on large windows.
#define MAP_TABLE_MIN_BLIP_SCALE 0.4
/// Groups not refreshed by their ship's sensors for this long refresh themselves, so they never show stale data.
#define MAP_TABLE_STALE_TIME (5 SECONDS)
/// Zoom level that fits as much of the overmap as the table can show.
#define MAP_TABLE_ZOOM_FULL 0
/// How long the scanline takes to cross one segment.
#define MAP_TABLE_SCAN_TIME (2 SECONDS)
/// Dark pause between sweeps.
#define MAP_TABLE_SCAN_PAUSE (1 SECOND)
/// Colour of the sweep and of the glow the screen gives off.
#define MAP_TABLE_SCREEN_COLOR "#a754ce"
/// How strongly a lit tabletop is washed with the screen's own colour.
#define MAP_TABLE_SCREEN_WASH_ALPHA 48
/// Base layer of the display: over the tabletop sprite, under anything on or at the table.
/// The layers stacked on top of it stay below STRUCTURE_LAYER.
#define MAP_TABLE_SCREEN_LAYER BELOW_OBJ_LAYER
/// Rounds up to the nearest odd number. Spans must be odd; see `get_span()`.
#define MAP_TABLE_ODD_UP(value) ((value) % 2 ? (value) : (value) + 1)
/// Rounds down to the nearest odd number, never below one.
#define MAP_TABLE_ODD_DOWN(value) ((value) % 2 ? (value) : max(1, (value) - 1))

GLOBAL_LIST_EMPTY(map_table_mask_cache)


/obj/machinery/map_table
	name = "sensor display table"
	desc = "A holographic tabletop display that projects the ship's sensor picture of the surrounding space. Push several together for a bigger picture."
	icon = 'icons/obj/machines/map_table.dmi'
	icon_state = "maptable_preview"
	density = TRUE
	anchored = TRUE
	layer = TABLE_LAYER
	atom_flags = ATOM_FLAG_NO_TEMP_CHANGE | ATOM_FLAG_CLIMBABLE
	obj_flags = OBJ_FLAG_RECEIVE_TABLE
	idle_power_usage = 300
	health_max = 80
	damage_hitsound = 'sound/weapons/smash.ogg'

	/// Corner connection states, as produced by `dirs_to_corner_states()`.
	var/list/connections = list("0", "0", "0", "0")
	/// The group of connected segments this one belongs to.
	var/datum/map_table_group/group
	/// Position of this segment within its group, from the south-west corner.
	var/grid_x = 0
	var/grid_y = 0

	var/obj/effect/map_table_display/screen/screen
	var/obj/effect/map_table_display/view/view
	var/obj/effect/map_table_display/blips/blip_layer
	var/obj/effect/map_table_display/scanline/scanline

	/// Whether the tabletop is lit up by a working display.
	var/lit = FALSE
	var/light_range_on = 2
	var/light_power_on = 0.4
	var/light_color_on = MAP_TABLE_SCREEN_COLOR


/obj/machinery/map_table/Initialize(mapload)
	. = ..()
	// Built inside the table rather than in nullspace. A holder with no location gives BYOND nothing
	// to lay its vis_contents out from, and the whole block of overmap turfs ends up drawn on the same
	// spot instead of tiled across the segment.
	screen = new(src)
	view = new(src)
	blip_layer = new(src)
	scanline = new(src)
	screen.add_vis_contents(view)
	add_vis_contents(list(screen, blip_layer, scanline))
	if (mapload)
		return INITIALIZE_HINT_LATELOAD // Wait for the rest of the table to exist before grouping.
	rebuild_map_table_groups(list(src))


/obj/machinery/map_table/LateInitialize(mapload)
	..()
	if (!group) // An earlier segment may have already grouped us.
		rebuild_map_table_groups(list(src))


/obj/machinery/map_table/Destroy()
	var/list/adjacent = list()
	for (var/obj/machinery/map_table/other in orange(1, src))
		adjacent += other
	if (group)
		group.segments -= src
		QDEL_NULL(group)
	QDEL_NULL(screen)
	QDEL_NULL(view)
	QDEL_NULL(blip_layer)
	QDEL_NULL(scanline)
	. = ..()
	// We're off the map now, so the neighbours regroup (and possibly split) without us.
	if (length(adjacent))
		rebuild_map_table_groups(adjacent)


/obj/machinery/map_table/Process()
	if (group?.linked && world.time > group.last_refresh + MAP_TABLE_STALE_TIME)
		group.refresh()


/obj/machinery/map_table/power_change()
	. = ..()
	if (.)
		group?.refresh(TRUE)


/obj/machinery/map_table/on_death()
	..()
	group?.refresh(TRUE)


/obj/machinery/map_table/on_revive()
	..()
	group?.refresh(TRUE)


/obj/machinery/map_table/interface_interact(mob/user)
	if (!group)
		return FALSE
	group.cycle_zoom()
	user.visible_message(
		SPAN_NOTICE("\The [user] adjusts \the [src]'s zoom."),
		SPAN_NOTICE("You set \the [src] to [group.get_zoom_name()] zoom.")
	)
	return TRUE


/obj/machinery/map_table/examine(mob/user)
	. = ..()
	if (!operable())
		return
	if (!group?.linked)
		to_chat(user, SPAN_WARNING("It shows no signal. It isn't linked to a ship's sensors."))
	else if (!group.span)
		to_chat(user, SPAN_NOTICE("It is linked to \the [group.linked], but there's no sensor data to display."))
	else
		to_chat(user, SPAN_NOTICE("It is showing \the [group.linked]'s sensor picture at [group.get_zoom_name()] zoom, [group.width * group.span] by [group.height * group.span] grid squares across."))
	to_chat(user, SPAN_NOTICE("Use it with an empty hand to change the zoom."))


/obj/machinery/map_table/on_update_icon()
	ClearOverlays()
	icon_state = "blank"
	for (var/i = 1 to 4)
		AddOverlays(image(icon, "maptable_[connections[i]]", dir = SHIFTL(1, i - 1)))
	if (lit)
		// The emissive below only keeps the screen out of the dark; on its own the glass still reads as
		// grey. This washes it with the screen's own colour so it looks powered. Added rather than
		// painted on, so it brightens like something emitting light, and it sits under the picture.
		var/image/wash = image(get_map_table_screen_icon(connections))
		wash.color = MAP_TABLE_SCREEN_COLOR
		wash.alpha = MAP_TABLE_SCREEN_WASH_ALPHA
		wash.blend_mode = BLEND_ADD
		AddOverlays(wash)
		// Cuts the darkness over the screen, which lights the picture drawn on top of it as well as
		// the tabletop. Left blockable, so anything over the table blocks the glow too.
		AddOverlays(emissive_appearance(get_map_table_screen_icon(connections)))


/// Recalculates which corners join up with neighbouring segments, for both the frame and the screen mask.
/obj/machinery/map_table/proc/update_connections()
	var/list/dirs = list()
	for (var/obj/machinery/map_table/other in orange(1, src))
		dirs += get_dir(src, other)
	connections = dirs_to_corner_states(dirs)
	// Everything drawn on the table is clipped to the tabletop, so a contact or the sweep can't hang
	// over the edge into the room.
	screen?.set_mask(connections)
	blip_layer?.set_mask(connections)
	scanline?.set_mask(connections)
	queue_icon_update()


/**
 * Puts this segment's slice of the overmap up and lights the table.
 *
 * **Parameters**:
 * - `turfs` - This segment's block of overmap turfs.
 * - `span` - Overmap tiles along each side of the block.
 * - `rows` - How many segments tall the whole table is, for the sweep.
 * - `origin` - South-west turf of the block, which every turf's place is measured from.
 */
/obj/machinery/map_table/proc/show_turfs(list/turfs, span, rows, turf/origin)
	screen?.alpha = 255
	view?.show_turfs(turfs, span, origin)
	scanline?.start_sweep(grid_y, rows)
	set_lit(TRUE)


/**
 * Lights the tabletop up like a working screen, or lets it go dark again.
 *
 * **Parameters**:
 * - `new_lit` - Whether the display is up.
 */
/obj/machinery/map_table/proc/set_lit(new_lit)
	if (lit == new_lit)
		return
	lit = new_lit
	if (lit)
		set_light(light_range_on, light_power_on, light_color_on)
	else
		set_light(0)
	queue_icon_update()


/obj/machinery/map_table/proc/show_blip(obj/effect/overmap_contact_mirror/blip)
	if (!blip_layer || (blip in blip_layer.vis_contents))
		return
	for (var/atom/other_layer as anything in blip.vis_locs)
		other_layer.remove_vis_contents(blip)
	blip_layer.add_vis_contents(blip)


/obj/machinery/map_table/proc/blank_display()
	screen?.alpha = 0
	view?.clear_turfs()
	blip_layer?.clear_vis_contents()
	scanline?.stop_sweep()
	set_lit(FALSE)


/**
 * Flood-fills groups of cardinally connected map tables, starting from each of `starts`, replacing
 * whatever groups those tables belonged to. Corner connections are refreshed for everything touched.
 */
/proc/rebuild_map_table_groups(list/starts)
	var/list/done = list()
	var/list/touched = list()
	for (var/obj/machinery/map_table/start as anything in starts)
		if (QDELETED(start) || done[start] || !isturf(start.loc))
			continue
		done[start] = TRUE
		var/list/members = list(start)
		var/i = 1
		while (i <= length(members))
			var/obj/machinery/map_table/current = members[i++]
			for (var/direction in GLOB.cardinal)
				for (var/obj/machinery/map_table/other in get_step(current, direction))
					if (!done[other] && !QDELETED(other))
						done[other] = TRUE
						members += other

		var/list/old_groups = list()
		var/zoom = 1
		for (var/obj/machinery/map_table/member as anything in members)
			if (member.group)
				old_groups |= member.group
			touched |= member
			for (var/obj/machinery/map_table/adjacent in orange(1, member))
				touched |= adjacent
		for (var/datum/map_table_group/old_group as anything in old_groups)
			zoom = old_group.zoom // Keep whatever zoom the table was on when it's extended or shrunk.
			qdel(old_group)
		new /datum/map_table_group(members, zoom)

	for (var/obj/machinery/map_table/table as anything in touched)
		table.update_connections()


/// Re-links every map table group to whatever ship now owns it. Called once ships have finished setting up.
/proc/sync_map_table_groups()
	var/list/groups = list()
	for (var/obj/machinery/map_table/table as anything in MACHINES_OF(/obj/machinery/map_table))
		if (table.group)
			groups |= table.group
	for (var/datum/map_table_group/group as anything in groups)
		group.sync_linked()


/**
 * One contiguous tabletop. Works out which slice of the overmap each segment shows, and keeps a
 * mirror of every sensor contact positioned on the right segment.
 */
/datum/map_table_group
	/// The `/obj/machinery/map_table`s making up this table.
	var/list/segments
	/// Segments by grid position, flat: `grid[grid_x + grid_y * width + 1]`. Gaps in odd shapes are null.
	var/list/grid
	var/width = 0
	var/height = 0

	var/obj/overmap/visitable/ship/linked
	/// Overmap tiles shown along each side of one segment. 0 while nothing is being displayed.
	var/span = 0
	/// Current zoom level, one of `zoom_levels`. Higher shows more of the overmap.
	var/zoom = 1
	var/static/list/zoom_levels = list(1, 2, MAP_TABLE_ZOOM_FULL)
	/// Overmap coordinates of the south-west corner of the displayed window.
	var/window_x = 0
	var/window_y = 0
	var/window_z = 0
	/// `/datum/overmap_contact` -> its `/obj/effect/overmap_contact_mirror` on this table.
	var/list/blips = list()
	var/last_refresh = 0


/datum/map_table_group/New(list/new_segments, new_zoom = 1)
	..()
	segments = new_segments
	zoom = (new_zoom in zoom_levels) ? new_zoom : 1
	var/obj/machinery/map_table/first = segments[1]
	var/min_x = first.x
	var/min_y = first.y
	var/max_x = first.x
	var/max_y = first.y
	for (var/obj/machinery/map_table/segment as anything in segments)
		min_x = min(min_x, segment.x)
		min_y = min(min_y, segment.y)
		max_x = max(max_x, segment.x)
		max_y = max(max_y, segment.y)
	width = max_x - min_x + 1
	height = max_y - min_y + 1
	grid = new /list(width * height)
	for (var/obj/machinery/map_table/segment as anything in segments)
		segment.group = src
		segment.grid_x = segment.x - min_x
		segment.grid_y = segment.y - min_y
		grid[segment.grid_x + segment.grid_y * width + 1] = segment
	sync_linked()


/datum/map_table_group/Destroy()
	unlink()
	for (var/obj/machinery/map_table/segment as anything in segments)
		if (segment.group == src)
			segment.group = null
	segments = null
	grid = null
	return ..()


/// Links to the ship owning the table, if any, and redraws.
/datum/map_table_group/proc/sync_linked()
	var/obj/overmap/visitable/ship/ship = length(segments) ? get_owning_sector_recursive(segments[1]) : null
	if (!istype(ship))
		ship = null
	if (ship != linked)
		unlink()
		linked = ship
		if (linked)
			LAZYADD(linked.map_table_groups, src)
			GLOB.moved_event.register(linked, src, PROC_REF(on_linked_moved))
			GLOB.destroyed_event.register(linked, src, PROC_REF(unlink))
	refresh(TRUE)
	return linked


/datum/map_table_group/proc/unlink()
	if (linked)
		LAZYREMOVE(linked.map_table_groups, src)
		GLOB.moved_event.unregister(linked, src, PROC_REF(on_linked_moved))
		GLOB.destroyed_event.unregister(linked, src, PROC_REF(unlink))
		linked = null
	blank()


/datum/map_table_group/proc/on_linked_moved()
	refresh(TRUE)


/// Strongest range among the ship's working sensors. 0 if there's nothing to show.
/datum/map_table_group/proc/get_sensor_range()
	. = 0
	for (var/obj/machinery/shipsensors/sensor as anything in linked?.sensors)
		if (sensor.operable())
			. = max(., sensor.get_sensor_range())


/**
 * Redraws the table. Contacts are always repositioned; the overmap window is only re-picked when `full`
 * is set (the ship moved, power changed...) or the sensor range changed enough to need a new scale.
 */
/datum/map_table_group/proc/refresh(full = FALSE)
	last_refresh = world.time
	var/turf/centre = linked && get_turf(linked)
	var/range = get_sensor_range()
	if (!centre || !range)
		blank()
		return

	var/new_span = get_span(range)
	if (full || new_span != span || centre.z != window_z)
		update_window(centre, new_span)
	update_blips()


/**
 * How many overmap tiles each segment shows along a side. At 1x the table's shorter side covers the
 * sensor diameter; zooming multiplies that, up to as much of the overmap as fits on the table.
 *
 * The result is always odd, because a segment's block has to have a middle tile. The scaled-down
 * content is positioned by its own centre (see `view/show_turfs()`), so an even block sits half a tile
 * off; it also leaves the ship half a tile off the middle of the table. Rounding up never shows less
 * than the sensors cover.
 */
/datum/map_table_group/proc/get_span(range)
	var/fits_overmap = max(1, round(get_overmap_size() / max(width, height)))
	var/max_span = MAP_TABLE_ODD_DOWN(fits_overmap)
	if (zoom == MAP_TABLE_ZOOM_FULL)
		return max_span
	var/fit = ceil(((range * 2 + 1) * zoom) / min(width, height))
	return clamp(MAP_TABLE_ODD_UP(fit), 1, max_span)


/// Width of the usable overmap, never larger than the z level holding it.
/datum/map_table_group/proc/get_overmap_size()
	return min(GLOB.using_map.overmap_size || world.maxx, world.maxx, world.maxy)


/datum/map_table_group/proc/cycle_zoom()
	var/index = zoom_levels.Find(zoom)
	zoom = zoom_levels[(index % length(zoom_levels)) + 1]
	refresh(TRUE)


/datum/map_table_group/proc/get_zoom_name()
	return zoom == MAP_TABLE_ZOOM_FULL ? "full system" : "[zoom]x"


/datum/map_table_group/proc/blank()
	for (var/datum/overmap_contact/record as anything in blips.Copy())
		drop_blip(record)
	for (var/obj/machinery/map_table/segment as anything in segments)
		segment.blank_display()
	span = 0


/// Centres the overmap window on `centre` and hands each segment its block of turfs.
/datum/map_table_group/proc/update_window(turf/centre, new_span)
	span = new_span
	var/total_x = width * span
	var/total_y = height * span
	// `span` is odd, so a table with an odd number of segments per side has a middle tile, and the ship
	// sits exactly on it. An even-sided table has its centre on a seam, so the ship lands half a tile
	// off it whatever we do here.
	// Keep the window inside the overmap, so every segment always gets a full block of overmap turfs.
	var/overmap_size = get_overmap_size()
	window_x = clamp(centre.x - round(total_x / 2), 1, max(1, overmap_size - total_x + 1))
	window_y = clamp(centre.y - round(total_y / 2), 1, max(1, overmap_size - total_y + 1))
	window_z = centre.z

	for (var/obj/machinery/map_table/segment as anything in segments)
		if (!segment.operable())
			segment.blank_display()
			continue
		var/start_x = window_x + segment.grid_x * span
		var/start_y = window_y + segment.grid_y * span
		var/turf/south_west = locate(start_x, start_y, window_z)
		var/turf/north_east = locate(min(start_x + span - 1, world.maxx), min(start_y + span - 1, world.maxy), window_z)
		segment.show_turfs(block(south_west, north_east), span, height, south_west)


/// Brings the contact mirrors in line with what the ship's sensors currently know.
/datum/map_table_group/proc/update_blips()
	var/list/current = list()
	var/list/seen_effects = list()
	var/blip_scale = max(1 / span, MAP_TABLE_MIN_BLIP_SCALE)

	for (var/obj/machinery/shipsensors/sensor as anything in linked.sensors)
		for (var/key in sensor.contact_datums)
			var/datum/overmap_contact/record = sensor.contact_datums[key]
			if (QDELETED(record) || !record.effect || seen_effects[record.effect])
				continue
			seen_effects[record.effect] = TRUE
			current[record] = TRUE

			var/obj/effect/overmap_contact_mirror/blip = blips[record]
			if (!blip)
				blip = record.create_mirror()
				blips[record] = blip
				GLOB.destroyed_event.register(blip, src, PROC_REF(on_blip_destroyed))
			place_blip(blip, record.effect, blip_scale)

	for (var/datum/overmap_contact/record as anything in blips - current)
		drop_blip(record)


/// Puts a mirror on whichever segment its contact falls on, or hides it if it's off the table.
/datum/map_table_group/proc/place_blip(obj/effect/overmap_contact_mirror/blip, obj/overmap/effect, blip_scale)
	var/turf/effect_turf = get_turf(effect)
	if (!effect_turf || effect_turf.z != window_z)
		blip.remove_from_displays()
		return
	var/offset_x = effect_turf.x - window_x
	var/offset_y = effect_turf.y - window_y
	var/cell_x = round(offset_x / span)
	var/cell_y = round(offset_y / span)
	if (offset_x < 0 || offset_y < 0 || cell_x >= width || cell_y >= height)
		blip.remove_from_displays()
		return
	var/obj/machinery/map_table/segment = grid[cell_x + cell_y * width + 1]
	if (!segment?.operable())
		blip.remove_from_displays()
		return

	// Centre of the contact within its segment, in overmap tiles, including drift between tiles.
	var/drift_x = isturf(effect.loc) ? effect.pixel_x / world.icon_size : 0
	var/drift_y = isturf(effect.loc) ? effect.pixel_y / world.icon_size : 0
	var/local_x = (offset_x - cell_x * span) + 0.5 + drift_x
	var/local_y = (offset_y - cell_y * span) + 0.5 + drift_y
	blip.set_display(
		round(local_x / span * world.icon_size - world.icon_size / 2),
		round(local_y / span * world.icon_size - world.icon_size / 2),
		blip_scale
	)
	segment.show_blip(blip)


/datum/map_table_group/proc/drop_blip(datum/overmap_contact/record)
	var/obj/effect/overmap_contact_mirror/blip = blips[record]
	blips -= record
	if (blip)
		GLOB.destroyed_event.unregister(blip, src, PROC_REF(on_blip_destroyed))
		qdel(blip)


/// The contact went away and took its mirror with it.
/datum/map_table_group/proc/on_blip_destroyed(obj/effect/overmap_contact_mirror/blip)
	for (var/record in blips)
		if (blips[record] == blip)
			blips -= record
			return


/*
 * Display holders. These live in nullspace and are only ever drawn through a table's vis_contents.
 */
/obj/effect/map_table_display
	name = "sensor display"
	icon = 'icons/obj/machines/map_table.dmi'
	icon_state = "blank"
	anchored = TRUE
	simulated = FALSE
	mouse_opacity = MOUSE_OPACITY_UNCLICKABLE
	vis_flags = VIS_INHERIT_ID
	plane = DEFAULT_PLANE
	layer = MAP_TABLE_SCREEN_LAYER
	appearance_flags = KEEP_TOGETHER | TILE_BOUND | PIXEL_SCALE


/obj/effect/map_table_display/Destroy()
	clear_vis_contents()
	for (var/atom/holder as anything in vis_locs)
		holder.remove_vis_contents(src)
	return ..()


/**
 * Clips this layer, and anything drawn inside it, to the shape of its segment's tabletop. Relies on
 * KEEP_TOGETHER: the filter applies to the flattened group, not just our own icon.
 *
 * **Parameters**:
 * - `connections` - The segment's corner states, from `dirs_to_corner_states()`.
 */
/obj/effect/map_table_display/proc/set_mask(list/connections)
	filters = filter(type = "alpha", icon = get_map_table_screen_icon(connections))


/**
 * The screen's shape for a set of corner states, baked into a single icon and cached.
 *
 * The corner states are quarter-tile pieces that only land in the right quadrant when drawn with a dir,
 * so they are blended here with an explicit dir rather than left to an overlay to get right. Used for
 * both the display mask and the emissive glow, which keeps the lit area exactly the shape of the screen.
 *
 * **Parameters**:
 * - `connections` - Corner states, from `dirs_to_corner_states()`.
 *
 * Returns instance of `/icon`.
 */
/proc/get_map_table_screen_icon(list/connections)
	RETURN_TYPE(/icon)
	var/key = jointext(connections, "-")
	var/icon/shape = GLOB.map_table_mask_cache[key]
	if (shape)
		return shape
	shape = icon('icons/obj/machines/map_table.dmi', "blank")
	for (var/i = 1 to 4)
		shape.Blend(icon('icons/obj/machines/map_table.dmi', "maptable_screen_[connections[i]]", SHIFTL(1, i - 1)), ICON_OVERLAY)
	GLOB.map_table_mask_cache[key] = shape
	return shape


/// The hologram itself. Also carries the static CRT line texture, over the overmap and under the blips.
/obj/effect/map_table_display/screen
	alpha = 0


/obj/effect/map_table_display/screen/Initialize(mapload)
	. = ..()
	AddOverlays(image('icons/obj/machines/map_table_fx.dmi', icon_state = "crt", layer = MAP_TABLE_SCREEN_LAYER + 0.0005))


/// Draws one segment's block of overmap turfs, shrunk to fit a single tile.
/obj/effect/map_table_display/view
	/// Overmap tiles along each side currently being shown.
	var/span = 0
	/// One `/obj/effect/map_table_display/cell` per turf on show, kept between refreshes and reused.
	var/list/cells


/obj/effect/map_table_display/view/Destroy()
	QDEL_NULL_LIST(cells)
	return ..()


/**
 * Lays this segment's block out, one cell per turf.
 *
 * **Parameters**:
 * - `turfs` - The block's turfs, in any order.
 * - `new_span` - Overmap tiles along each side of the block.
 * - `origin` - South-west turf of the block.
 */
/obj/effect/map_table_display/view/proc/show_turfs(list/turfs, new_span, turf/origin)
	if (new_span != span)
		span = new_span
		var/matrix/scale = matrix()
		scale.Scale(1 / span)
		transform = scale
		// The KEEP_TOGETHER group is scaled about the centre of its content, which spans `span` tiles
		// with the south-west turf on our own tile. Shift that centre back onto our tile. `span` is
		// always odd (see `get_span()`), so this lands on a tile centre, not half a tile out.
		pixel_x = -(world.icon_size / 2) * (span - 1)
		pixel_y = -(world.icon_size / 2) * (span - 1)

	var/count = 0
	for (var/turf/tile as anything in turfs)
		count++
		var/obj/effect/map_table_display/cell/cell
		if (count <= LAZYLEN(cells))
			cell = cells[count]
		else
			cell = new(src)
			LAZYADD(cells, cell)
			add_vis_contents(cell)
		cell.show_turf(tile, tile.x - origin.x, tile.y - origin.y)

	// Spares left over from a larger window we are no longer showing.
	while (LAZYLEN(cells) > count)
		var/obj/effect/map_table_display/cell/spare = cells[length(cells)]
		cells.len--
		qdel(spare)


/obj/effect/map_table_display/view/proc/clear_turfs()
	QDEL_NULL_LIST(cells)


/**
 * Holds a single overmap turf at its place in the segment's block.
 *
 * One turf per cell is the point: with nothing to arrange there is nothing for the layout to get
 * wrong, and the cell's own pixel offset is what puts it where it belongs. The scale lives on the
 * view above, so the whole block shrinks together.
 */
/obj/effect/map_table_display/cell
	/// The turf on show, so an unchanged one isn't re-set on every refresh.
	var/turf/shown


/obj/effect/map_table_display/cell/proc/show_turf(turf/tile, dx, dy)
	pixel_x = dx * world.icon_size
	pixel_y = dy * world.icon_size
	if (shown == tile)
		return
	shown = tile
	set_vis_contents(tile)


/// Holds the contact mirrors on top of the hologram.
/obj/effect/map_table_display/blips
	layer = MAP_TABLE_SCREEN_LAYER + 0.001
	// Catches clicks across the whole tile for the table, so the overmap turfs underneath can't be
	// clicked, hovered or examined through the hologram. The mask doesn't affect this.
	mouse_opacity = MOUSE_OPACITY_PRIORITY


/**
 * The sweep travelling up the table.
 *
 * Each segment's line crosses its own tile and waits its turn, so on a multi-segment table one line
 * appears to travel the whole height. Every segment's cycle is the same length whatever row it is on,
 * so the segments can't drift out of step with each other.
 */
/obj/effect/map_table_display/scanline
	icon = 'icons/obj/machines/map_table_fx.dmi'
	icon_state = "scanline"
	layer = MAP_TABLE_SCREEN_LAYER + 0.002
	color = MAP_TABLE_SCREEN_COLOR
	alpha = 0
	blend_mode = BLEND_ADD
	/// Row and table height the running sweep was built for, so it isn't restarted on every refresh.
	var/scan_row = -1
	var/scan_rows = 0


/**
 * Starts the sweep, unless one is already running for this position.
 *
 * **Parameters**:
 * - `row` - This segment's row within the table, from the bottom.
 * - `rows` - How many segments tall the whole table is.
 */
/obj/effect/map_table_display/scanline/proc/start_sweep(row, rows)
	if (row == scan_row && rows == scan_rows)
		return
	scan_row = row
	scan_rows = rows
	var/half = world.icon_size / 2
	var/before = row * MAP_TABLE_SCAN_TIME
	var/after = (rows - row - 1) * MAP_TABLE_SCAN_TIME
	// Omitted when zero, which leaves the cycle the same length for every row: 3 + rows * SCAN_TIME.
	// The jump back to the bottom happens on the loop's first step, while still faded out.
	animate(src, pixel_y = -half, alpha = 0, time = 1, loop = -1, flags = ANIMATION_END_NOW)
	if (before)
		animate(time = before)
	animate(alpha = 255, time = 1)
	animate(pixel_y = half, time = MAP_TABLE_SCAN_TIME, easing = LINEAR_EASING)
	animate(alpha = 0, time = 1)
	if (after)
		animate(time = after)
	animate(time = MAP_TABLE_SCAN_PAUSE)


/obj/effect/map_table_display/scanline/proc/stop_sweep()
	if (scan_rows == 0)
		return
	scan_row = -1
	scan_rows = 0
	animate(src)
	alpha = 0


#undef MAP_TABLE_MIN_BLIP_SCALE
#undef MAP_TABLE_STALE_TIME
#undef MAP_TABLE_ZOOM_FULL
#undef MAP_TABLE_SCAN_TIME
#undef MAP_TABLE_SCAN_PAUSE
#undef MAP_TABLE_SCREEN_COLOR
#undef MAP_TABLE_SCREEN_WASH_ALPHA
#undef MAP_TABLE_SCREEN_LAYER
#undef MAP_TABLE_ODD_UP
#undef MAP_TABLE_ODD_DOWN
