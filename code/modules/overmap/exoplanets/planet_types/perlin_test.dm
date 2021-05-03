/obj/effect/overmap/visitable/sector/exoplanet/perlin_test
	name = "Perlin test"
	desc = "Perlin test."
	color = "#dcdcdc"
	planetary_area = /area/exoplanet/perlin
	surface_color = "#e8faff"
	habitability_distribution = HABITABILITY_IDEAL
	has_trees = TRUE
	flora_diversity = 7
	fauna_types = list(/mob/living/simple_animal/yithian, /mob/living/simple_animal/tindalos, /mob/living/simple_animal/hostile/retaliate/jelly)
	megafauna_types = list(/mob/living/simple_animal/hostile/retaliate/parrot/space/megafauna, /mob/living/simple_animal/hostile/retaliate/goose/dire)

	//possible_themes = list(/datum/exoplanet_theme = 45, /datum/exoplanet_theme/caves = 65)
	possible_themes = list(/datum/exoplanet_theme/caves = 65)

	map_generators = list(/datum/random_map/noise/ore/rich)

	possible_biomes = list(
	BIOME_LOW_HEAT = list(
		BIOME_LOW_HUMIDITY = /decl/biome/plains,
		BIOME_LOWMEDIUM_HUMIDITY = /decl/biome/biome/mudlands,
		BIOME_HIGHMEDIUM_HUMIDITY = /decl/biome/biome/mudlands,
		BIOME_HIGH_HUMIDITY = /decl/biome/water
		),
	BIOME_LOWMEDIUM_HEAT = list(
		BIOME_LOW_HUMIDITY = /decl/biome/plains,
		BIOME_LOWMEDIUM_HUMIDITY = /decl/biome/jungle,
		BIOME_HIGHMEDIUM_HUMIDITY = /decl/biome/biome/mudlands,
		BIOME_HIGH_HUMIDITY =  /decl/biome/water
		),
	BIOME_HIGHMEDIUM_HEAT = list(
		BIOME_LOW_HUMIDITY = /decl/biome/plains,
		BIOME_LOWMEDIUM_HUMIDITY = /decl/biome/plains,
		BIOME_HIGHMEDIUM_HUMIDITY = /decl/biome/jungle,
		BIOME_HIGH_HUMIDITY = /decl/biome/jungle/deep,
		),
	BIOME_HIGH_HEAT = list(
		BIOME_LOW_HUMIDITY = /decl/biome/plains,
		BIOME_LOWMEDIUM_HUMIDITY = /decl/biome/plains,
		BIOME_HIGHMEDIUM_HUMIDITY = /decl/biome/jungle,
		BIOME_HIGH_HUMIDITY = /decl/biome/jungle/deep,
		)
	)


/obj/structure/stairs/dirt
	name = "dirt"
	icon = 'icons/obj/structures/sloppyslopslap.dmi'
	blend_objects = list(/obj/structure/stairs/dirt)
	icon_state = "S"

/obj/structure/stairs/dirt/Initialize()
	. = ..()
	update_connections(1)
	update_icon()

/obj/structure/stairs/dirt/on_update_icon()
	. = ..()
	icon_state = "S"
	var/turf/TR = get_step(get_turf(src), turn(src.dir, -90))
	var/turf/TL = get_step(get_turf(src), turn(src.dir, 90))
	var/obj/structure/stairs/dirt/R = locate() in TR
	var/obj/structure/stairs/dirt/L = locate() in TL
	if(R)
		R = (R.dir == dir) ? R : null
	if(L)
		L = (L.dir == dir) ? L : null
	if (istype(R) || TR.density)
		if(istype(L) || TL.density)
			icon_state = "M"
		else
			icon_state = "L"
		return
	else if(istype(L) || TL.density)
		icon_state = "R"		
/area/exoplanet/perlin
	ambience = list('sound/effects/wind/tundra0.ogg','sound/effects/wind/tundra1.ogg','sound/effects/wind/tundra2.ogg','sound/effects/wind/spooky0.ogg','sound/effects/wind/spooky1.ogg')
	base_turf = /turf/simulated/floor/exoplanet/snow