/obj/lighting_plane
	screen_loc = "1,1"
	plane = LIGHTING_PLANE

	blend_mode = BLEND_MULTIPLY
	appearance_flags = PLANE_MASTER | NO_CLIENT_COLOR
	// use 20% ambient lighting; be sure to add full alpha

	color = list(
			-1, 00, 00, 00,
			00, -1, 00, 00,
			00, 00, -1, 00,
			00, 00, 00, 00,
			01, 01, 01, 01
		)

	mouse_opacity = 0    // nothing on this plane is mouse-visible

/*!
 * This system works by exploiting BYONDs color matrix filter to use layers to handle emissive blockers.
 *
 * Emissive overlays are pasted with an atom color that converts them to be entirely some specific color.
 * Emissive blockers are pasted with an atom color that converts them to be entirely some different color.
 * Emissive overlays and emissive blockers are put onto the same plane.
 * The layers for the emissive overlays and emissive blockers cause them to mask eachother similar to normal BYOND objects.
 * A color matrix filter is applied to the emissive plane to mask out anything that isn't whatever the emissive color is.
 * This is then used to alpha mask the lighting plane.
 */

/obj/lighting_plane/Initialize()
	. = ..()
	filters += filter(type = "alpha", render_source = EMISSIVE_RENDER_TARGET, flags = MASK_INVERSE)

/obj/lighting_general
	plane = LIGHTING_PLANE
	screen_loc = "8,8"

	icon = LIGHTING_ICON
	icon_state = LIGHTING_ICON_STATE_DARK

	color = "#ffffff"

	blend_mode = BLEND_MULTIPLY

/obj/lighting_general/Initialize()
	. = ..()
	var/matrix/M = matrix()
	M.Scale(world.view*2.2)

	transform = M

/obj/lighting_general/proc/sync(var/new_colour)
	color = new_colour

/mob
	var/obj/lighting_plane/l_plane
	var/obj/lighting_general/l_general
	var/obj/screen/plane_master/emissive/l_emissive


/mob/proc/change_light_colour(var/new_colour)
	if(l_general)
		l_general.sync(new_colour)

/*
 * Handles emissive overlays and emissive blockers.
 */
/obj/screen/plane_master/emissive
	name = "emissive plane master"
	screen_loc = "CENTER"
	blend_mode = BLEND_OVERLAY
	plane = EMISSIVE_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_target = EMISSIVE_RENDER_TARGET

/obj/screen/plane_master/emissive/Initialize()
	. = ..()
	filters += filter(type = "color", color = GLOB.em_mask_matrix)

/**
 * Internal atom that copies an appearance on to the blocker plane
 *
 * Copies an appearance vis render_target and render_source on to the emissive blocking plane.
 * This means that the atom in question will block any emissive sprites.
 * This should only be used internally. If you are directly creating more of these, you're
 * almost guaranteed to be doing something wrong.
 */
/atom/movable/emissive_blocker
	name = "emissive blocker"
	plane = EMISSIVE_PLANE
	layer = FLOAT_LAYER
	mouse_opacity = 0
	//Why?
	//render_targets copy the transform of the target as well, but vis_contents also applies the transform
	//to what's in it. Applying RESET_TRANSFORM here makes vis_contents not apply the transform.
	//Since only render_target handles transform we don't get any applied transform "stacking"
	appearance_flags = RESET_TRANSFORM

/atom/movable/emissive_blocker/Initialize(mapload, source)
	. = ..()
	verbs.Cut() //Cargo culting from lighting object, this maybe affects memory usage?

	render_source = source
	color = GLOB.em_block_color

/atom/movable/emissive_blocker/ex_act(severity)
	return FALSE

/atom/movable/emissive_blocker/singularity_act()
	return

/atom/movable/emissive_blocker/singularity_pull()
	return

//Prevents people from moving these after creation, because they shouldn't be.
/atom/movable/emissive_blocker/forceMove(atom/destination, no_tp=FALSE, harderforce = FALSE)
	if(harderforce)
		return ..()