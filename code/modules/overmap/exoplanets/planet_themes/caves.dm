/datum/exoplanet_theme/caves
	name = "Caves"
	var/floor_color

/datum/exoplanet_theme/caves/after_map_generation(obj/effect/overmap/visitable/sector/exoplanet/E)
	floor_color = pick(E.rock_colors)
	for(var/zlevel in E.map_z)
		new /datum/random_map/automata/cave_system/exoplanet(null,TRANSITIONEDGE,TRANSITIONEDGE,zlevel,E.maxx-TRANSITIONEDGE,E.maxy-TRANSITIONEDGE,0,1,1, E.planetary_area, floor_color)

//TODO: Probably base this off heigh differences on planet. For now we can just assume caves imply mountains
/datum/exoplanet_theme/caves/get_planet_image_extra()
	var/image/res = image('icons/skybox/planet.dmi', "mountains")
	res.color = floor_color
	return res

/datum/random_map/automata/cave_system/exoplanet
	iterations = 2
	descriptor = "planetary caves"
	wall_type =  null
	cell_threshold = 4
	initial_wall_cell = 55
	target_turf_type = /turf/simulated/mineral
	floor_type = /turf/simulated/floor/exoplanet/cave
	var/rock_color

/datum/random_map/automata/cave_system/exoplanet/New(seed, tx, ty, tz, tlx, tly, do_not_apply, do_not_announce, never_be_priority = 0, area/used_area, _rock_color)
	if (_rock_color)
		rock_color = _rock_color
	if (target_turf_type == null)
		target_turf_type = world.turf
	if (floor_type == null)
		floor_type = used_area.base_turf
	..()

/datum/random_map/automata/cave_system/exoplanet/get_additional_spawns(value, turf/simulated/mineral/T)
	if (istype(T))
		T.queue_icon_update()
