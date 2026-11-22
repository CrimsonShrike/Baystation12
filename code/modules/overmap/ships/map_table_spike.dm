/*
 * Throwaway spike: settles how a one-piece holomap could be drawn across a multi-segment table.
 * Delete this file, its line in the .dme, and `icons/obj/machines/map_table_test.dmi` when done.
 *
 * Three verbs on any map table, under Debug, each clearing the last. Every cell drawn is a different
 * colour with a dark block in its lower left and a diagonal running to its top right, so a flip, a
 * mirror or a wrong cell is obvious at a glance.
 *
 *
 * 1. "Spike: Clipping (masked)" and 2. "Spike: Clipping (unmasked)"
 *
 * One oversized icon, two tiles square, on the segment you used the verb on. No offsets, no render
 * source: this asks one question only, which is whether anything trims an appearance to its own tile.
 * Run both. The unmasked one is the control, and the pair is what makes the answer mean anything:
 *
 *   masked trims to one tile, unmasked sprawls  - the mask does the clipping, as the design assumes
 *   both trim to one tile                       - something else trims it (TILE_BOUND, most likely)
 *                                                 and the mask is not load-bearing after all
 *   neither trims                               - nothing clips. The blips have been spilling over
 *                                                 the table edge all along and the holomap must be
 *                                                 sliced per segment instead of windowed
 *
 * A pass shows the lower left cell, red, and nothing else. If a different cell survives, or it sits
 * somewhere other than the lower left, the mask is anchored to the appearance's bounding box rather
 * than to the tile, which matters just as much.
 *
 *
 * 3. "Spike: Render Windows"
 *
 * One table-sized canvas on a single object, with every segment drawing its own window onto that one
 * canvas through `render_source`. This is the holomap arrangement in miniature.
 *
 * A pass is one unbroken grid over the whole table: every segment showing a different cell, borders
 * meeting on the seams, cut off square at the table edge. Bottom row red, yellow, green; middle row
 * blue, purple, pink; top row light green, orange, grey. Anything less than the full set means only
 * some windows resolve, which is worth knowing before the holomap depends on it.
 */

/// Layer for the spike's own visuals, just above the ordinary ones. MAP_TABLE_SCREEN_LAYER is
/// undef'd at the end of map_table.dm and so can't be used here.
#define MAP_TABLE_SPIKE_LAYER (BELOW_OBJ_LAYER + 0.003)
/// Size of the oversized icon used by the clipping tests, in tiles each way.
#define MAP_TABLE_SPIKE_CLIP_TILES 2


/datum/map_table_group
	/// Spike only. Everything this file has put on the table, cleared as a set.
	var/list/spike_visuals
	/// Spike only. The one-piece canvas the windows draw from.
	var/obj/effect/map_table_canvas/spike_canvas


/obj/machinery/map_table/verb/spike_clipping_masked()
	set name = "Spike: Clipping (masked)"
	set category = "Debug"
	set src in view(1)
	run_clip_spike(usr, TRUE)


/obj/machinery/map_table/verb/spike_clipping_unmasked()
	set name = "Spike: Clipping (unmasked)"
	set category = "Debug"
	set src in view(1)
	run_clip_spike(usr, FALSE)


/obj/machinery/map_table/verb/spike_render_windows()
	set name = "Spike: Render Windows"
	set category = "Debug"
	set src in view(1)

	if (!group)
		to_chat(usr, SPAN_WARNING("\The [src] isn't part of a table group."))
		return
	group.clear_spike()
	group.spike_canvas = new(get_turf(src))
	group.spike_canvas.build(group.width, group.height)
	for (var/obj/machinery/map_table/segment as anything in group.segments)
		var/obj/effect/map_table_display/spike/window = new(segment)
		window.set_mask(segment.connections)
		window.render_source = group.spike_canvas.render_target
		// Slide the whole canvas so this segment's share of it lands on this segment's tile. Whatever
		// trims an appearance to its tile is what keeps the rest off the neighbours and out of the room.
		window.pixel_x = -segment.grid_x * world.icon_size
		window.pixel_y = -segment.grid_y * world.icon_size
		segment.add_vis_contents(window)
		LAZYADD(group.spike_visuals, window)
	to_chat(usr, SPAN_NOTICE("Render windows up. Expect every segment showing a different cell, meeting on the seams: bottom row red, yellow, green; middle blue, purple, pink; top light green, orange, grey. Use a clipping verb to clear."))


/**
 * Drops an oversized icon on this one segment and leaves it there to be looked at.
 *
 * **Parameters**:
 * - `user` - Who to report to.
 * - `masked` - Whether to apply the segment's tabletop mask. Run it both ways; the unmasked pass is
 * the control, and only the difference between them says what is doing the trimming.
 */
/obj/machinery/map_table/proc/run_clip_spike(mob/user, masked)
	if (!group)
		to_chat(user, SPAN_WARNING("\The [src] isn't part of a table group."))
		return
	group.clear_spike()
	var/obj/effect/map_table_display/spike/patch = new(src)
	patch.icon = build_map_table_spike_grid(MAP_TABLE_SPIKE_CLIP_TILES, MAP_TABLE_SPIKE_CLIP_TILES)
	if (masked)
		patch.set_mask(connections)
	add_vis_contents(patch)
	LAZYADD(group.spike_visuals, patch)
	to_chat(user, SPAN_NOTICE("[MAP_TABLE_SPIKE_CLIP_TILES] by [MAP_TABLE_SPIKE_CLIP_TILES] tiles of icon on one segment, [masked ? "masked" : "unmasked"]. Trimmed to the lower left red cell means something clips it; the whole grid sprawling means nothing does. Run it the other way to see which."))


/datum/map_table_group/proc/clear_spike()
	QDEL_NULL_LIST(spike_visuals)
	QDEL_NULL(spike_canvas)


/**
 * Paints a grid of tinted cells, one per tile, for the spike to show.
 *
 * **Parameters**:
 * - `cols` - Cells across.
 * - `rows` - Cells up.
 *
 * Returns instance of `/icon`, `cols * 32` by `rows * 32`.
 */
/proc/build_map_table_spike_grid(cols, rows)
	RETURN_TYPE(/icon)
	var/static/list/tints = list(
		"#ff6b6b", "#ffd166", "#06d6a0",
		"#4cc9f0", "#b388ff", "#f72585",
		"#80ed99", "#ffa552", "#e0e0e0"
	)
	var/icon/canvas = icon('icons/obj/machines/map_table_test.dmi', "cell")
	canvas.Scale(cols * world.icon_size, rows * world.icon_size)
	var/index = 0
	for (var/row = 0 to rows - 1)
		for (var/col = 0 to cols - 1)
			index++
			var/icon/cell = icon('icons/obj/machines/map_table_test.dmi', "cell")
			cell.Blend(tints[((index - 1) % length(tints)) + 1], ICON_MULTIPLY)
			// Blend positions are 1-based.
			canvas.Blend(cell, ICON_OVERLAY, col * world.icon_size + 1, row * world.icon_size + 1)
	return canvas


/**
 * The whole table's picture in one piece. Never drawn where it stands: the `*` on its render_target
 * marks it as a source only, and the segments pull from it.
 */
/obj/effect/map_table_canvas
	name = "map table canvas"
	icon = 'icons/obj/machines/map_table_test.dmi'
	icon_state = "cell"
	anchored = TRUE
	simulated = FALSE
	mouse_opacity = MOUSE_OPACITY_UNCLICKABLE
	appearance_flags = KEEP_TOGETHER | PIXEL_SCALE


/obj/effect/map_table_canvas/proc/build(cols, rows)
	icon = build_map_table_spike_grid(cols, rows)
	render_target = "*maptable-spike-\ref[src]"


/// One segment's spike visual, whatever the test is.
/obj/effect/map_table_display/spike
	layer = MAP_TABLE_SPIKE_LAYER


#undef MAP_TABLE_SPIKE_LAYER
#undef MAP_TABLE_SPIKE_CLIP_TILES
