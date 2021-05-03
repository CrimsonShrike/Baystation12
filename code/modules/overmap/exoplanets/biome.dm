///This datum handles the transitioning from a turf to a specific biome, and handles spawning decorative structures and mobs.
/decl/biome
	///Type of turf this biome creates
	var/turf_type

	//Flora chance. Large flora is a subset if flora DOES spawn
	var/flora_prob = 0
	var/large_flora_prob = 0

	var/grass_prob = 0
	
	//Flora chance. Megafauna is a subset if fauna DOES spawn
	var/fauna_prob = 2
	var/megafauna_prob = 0.5

///This proc handles the creation of a turf of a specific biome type
/decl/biome/proc/generate_turf(turf/gen_turf, obj/effect/overmap/visitable/sector/exoplanet/E)
	gen_turf.ChangeTurf(turf_type)
	if(prob(fauna_prob))
		E.spawn_fauna(gen_turf, megafauna_prob)

	if(prob(grass_prob))
		E.spawn_grass(gen_turf)

	if (prob(flora_prob))
		E.spawn_flora(gen_turf, prob(large_flora_prob))

/decl/biome/biome/mudlands
	turf_type = /turf/simulated/floor/exoplanet/sand/dirt
	flora_prob = 3
	grass_prob = 10

/decl/biome/plains
	turf_type = /turf/simulated/floor/exoplanet/grass
	flora_prob = 10
	large_flora_prob = 10
	grass_prob = 40

/decl/biome/jungle
	turf_type = /turf/simulated/floor/exoplanet/grass/dark
	flora_prob = 20
	large_flora_prob = 20

/decl/biome/jungle/deep
	flora_prob = 40
	large_flora_prob = 40

/decl/biome/water
	turf_type =  /turf/simulated/floor/exoplanet/water/shallow
	fauna_prob = 0

// /decl/biome/mountain
// 	turf_type = /turf/closed/mineral/random/jungle
// 	fauna_prob = 0
