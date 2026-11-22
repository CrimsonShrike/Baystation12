#define SENSOR_TIME_DELAY 0.2 SECONDS
/datum/overmap_contact

	/// Contact name
	var/name  = "Unknown"
	/// Used to animate overmap effects
	var/pinged = FALSE

	/// Our list of images to cast to users
	var/list/images = list()

	/// Image overlay attached to the contact
	var/image/marker
	/// Radar image for sonar esque effect
	var/image/radar

	/// The sensor console holding this data
	var/obj/machinery/shipsensors/owner

	/// The actual overmap effect associated with this
	var/obj/overmap/effect

	/// World-visible copies of the marker, for in-world displays that can't use client images (e.g. map tables)
	var/list/mirrors
	/// What the marker looked like when the mirrors were last synced, so they're only re-synced on a visible change
	var/mirror_signature

/datum/overmap_contact/New(obj/machinery/shipsensors/creator, obj/overmap/source)
	// Update local tracking information
	owner =  creator
	effect = source
	name =   effect.name
	owner.contact_datums[effect] = src

	marker = new(loc = effect)
	marker.appearance = effect
	marker.alpha = 0 // Marker fades in on detection

	// Needs to be reset to be accurate in position and directions
	marker.pixel_x = 0
	marker.pixel_y = 0
	marker.transform = null

	images += marker

	radar = image(loc = effect.loc, icon = 'icons/obj/overmap.dmi', icon_state = "sensor_range", pixel_x = effect.pixel_x, pixel_y = effect.pixel_y)
	radar.tag = "radar"
	radar.filters = filter(type="blur", size = 1)
	radar.mouse_opacity = MOUSE_OPACITY_UNCLICKABLE


/datum/overmap_contact/proc/update_marker_icon(range = 0)
	marker.icon_state = effect.icon_state
	marker.dir = effect.dir

	marker.ClearOverlays()

	var/shielded = check_effect_shield()
	if (shielded)
		var/image/shield_image = image(icon = 'icons/obj/overmap.dmi', icon_state = "shield")
		shield_image.pixel_x = 8
		marker.AddOverlays(shield_image)

	var/show_heading = effect.is_moving() && !isnull(effect.heading_overlay)
	if (show_heading)
		marker.AddOverlays(effect.heading_overlay)

	// Re-copying the appearance cuts short any running fade on the mirrors, so only do it when the marker actually changed.
	var/signature = "[marker.icon_state]-[marker.dir]-[shielded]-[show_heading]"
	if (signature != mirror_signature)
		mirror_signature = signature
		sync_mirrors()

	if (range > 0)
		radar.transform = null
		radar.alpha = 255
		radar.loc = effect.loc
		radar.pixel_x = effect.pixel_x
		radar.pixel_y = effect.pixel_y

		images |= radar

		var/matrix/M = matrix()
		M.Scale(range*2.6)
		animate(radar, transform = M, alpha = 0, time = (SENSOR_TIME_DELAY*range), 1, SINE_EASING)
		addtimer(new Callback(src, PROC_REF(reset_radar), radar), (0.25 SECONDS *range+0.1))

/datum/overmap_contact/proc/reset_radar(image/radar)
	images -= radar

/datum/overmap_contact/proc/show()
	if (!owner)
		return
	var/list/showing = owner.linked?.navigation_viewers
	if (length(showing))
		for(var/weakref/W in showing)
			var/mob/M = W.resolve()
			if (istype(M) && M.client)
				M.client.images |= images

/datum/overmap_contact/proc/check_effect_shield()
	var/obj/overmap/visitable/visitable_effect = effect
	if (!visitable_effect || !istype(visitable_effect))
		return FALSE
	for (var/obj/machinery/power/shield_generator/S as anything in MACHINES_OF(/obj/machinery/power/shield_generator))
		if (S.z in visitable_effect.map_z)
			if (S.running == SHIELD_RUNNING)
				return TRUE
	return FALSE

/datum/overmap_contact/proc/ping()
	if (pinged)
		return
	pinged = TRUE
	show()
	fade_markers(255, 0.5 SECONDS)
	addtimer(new Callback(src, PROC_REF(unping)), 1 SECOND)

/datum/overmap_contact/proc/unping()
	fade_markers(75, 2 SECONDS)
	pinged = FALSE

/**
 * Animates the alpha of the marker and all of its mirrors together. Use this instead of animating
 * `marker` directly, or mirrors won't follow.
 *
 * **Parameters**:
 * - `target_alpha` - Alpha to fade to.
 * - `time` - Duration of the fade.
 * - `start_alpha` (optional) - Alpha to jump to before fading.
 */
/datum/overmap_contact/proc/fade_markers(target_alpha, time, start_alpha)
	if (!marker)
		return
	if (!isnull(start_alpha))
		marker.alpha = start_alpha
	animate(marker, alpha = target_alpha, time = time, loop = 1, easing = LINEAR_EASING)
	for (var/obj/effect/overmap_contact_mirror/mirror as anything in mirrors)
		if (!isnull(start_alpha))
			mirror.alpha = start_alpha
		animate(mirror, alpha = target_alpha, time = time, loop = 1, easing = LINEAR_EASING)

/// Creates a new world-visible mirror of the marker. It's owned by this contact and deleted along with it.
/datum/overmap_contact/proc/create_mirror()
	RETURN_TYPE(/obj/effect/overmap_contact_mirror)
	var/obj/effect/overmap_contact_mirror/mirror = new(null, src)
	LAZYADD(mirrors, mirror)
	return mirror

/datum/overmap_contact/proc/sync_mirrors()
	for (var/obj/effect/overmap_contact_mirror/mirror as anything in mirrors)
		mirror.sync()

/datum/overmap_contact/Destroy()
	if (owner)
		var/list/showing = owner.linked?.navigation_viewers
		if (length(showing))
			for (var/weakref/W in showing)
				var/mob/M = W.resolve()
				if (istype(M) && M.client)
					M.client.images -= images
		if (effect)
			owner.contact_datums -= effect
		owner = null
	effect = null
	QDEL_NULL_LIST(images)
	if (mirrors)
		var/list/old_mirrors = mirrors
		mirrors = null
		for (var/obj/effect/overmap_contact_mirror/mirror as anything in old_mirrors)
			mirror.contact = null
			qdel(mirror)
	. = ..()


/**
 * A world-visible copy of an overmap contact's marker.
 *
 * Markers are client images and their source objects sit at INVISIBILITY_OVERMAP, so neither can be shown
 * to an arbitrary onlooker without leaking contacts the sensors haven't found. Mirrors only exist for
 * contacts that have been identified, so displays built from them only show what the sensors know.
 * The display that requested the mirror positions and scales it with `set_display()`.
 */
/obj/effect/overmap_contact_mirror
	name = "sensor contact"
	anchored = TRUE
	simulated = FALSE
	mouse_opacity = MOUSE_OPACITY_UNCLICKABLE
	var/datum/overmap_contact/contact
	var/display_x = 0
	var/display_y = 0
	var/display_scale = 1

/obj/effect/overmap_contact_mirror/Initialize(mapload, datum/overmap_contact/source)
	. = ..()
	contact = source
	sync()

/obj/effect/overmap_contact_mirror/Destroy()
	remove_from_displays()
	if (contact)
		LAZYREMOVE(contact.mirrors, src)
		contact = null
	return ..()

/// Copies the contact's current marker appearance, keeping our own display placement.
/obj/effect/overmap_contact_mirror/proc/sync()
	if (!contact?.marker)
		return
	appearance = contact.marker
	invisibility = INVISIBILITY_NONE // The marker inherits the source's INVISIBILITY_OVERMAP
	mouse_opacity = MOUSE_OPACITY_UNCLICKABLE
	plane = FLOAT_PLANE
	layer = FLOAT_LAYER
	appearance_flags |= PIXEL_SCALE
	apply_display()

/obj/effect/overmap_contact_mirror/proc/set_display(new_x, new_y, new_scale)
	if (new_x == display_x && new_y == display_y && new_scale == display_scale)
		return
	display_x = new_x
	display_y = new_y
	display_scale = new_scale
	apply_display()

/obj/effect/overmap_contact_mirror/proc/apply_display()
	pixel_x = display_x
	pixel_y = display_y
	var/matrix/scale = matrix()
	scale.Scale(display_scale)
	transform = scale

/// Removes the mirror from every display currently drawing it.
/obj/effect/overmap_contact_mirror/proc/remove_from_displays()
	for (var/atom/holder as anything in vis_locs)
		holder.remove_vis_contents(src)
