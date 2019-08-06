/obj/item/weapon/gun/hook
	name = "grappling gun"
	icon_state = "riotgun"
	item_state = "riotgun"
	w_class = ITEM_SIZE_HUGE
	force = 10

	fire_sound = 'sound/weapons/empty.ogg'
	fire_sound_text = "a metallic thunk"
	screen_shake = 0



	var/loaded = TRUE
	var/obj/item/anchor/an = null

//revolves the magazine, allowing players to choose between multiple grenade types

/obj/item/weapon/gun/hook/examine(mob/user)
	if(..(user, 2))
		if(loaded)
			to_chat(user, "The hook is loaded")

/obj/item/weapon/gun/hook/proc/load()
	an = null
	loaded = TRUE


/obj/item/weapon/gun/hook/attack_self(mob/user)
	if(an)
		QDEL_NULL(an)


/obj/item/weapon/gun/hook/handle_post_fire(mob/user)
	log_and_message_admins("hook activated.")

	loaded = FALSE
	..()

/obj/item/weapon/gun/hook/consume_next_projectile()
	if(loaded)
		return new /obj/item/projectile/hook(src, src)


/obj/item/projectile/hook
	name = "hook"
	icon_state = "bullet"
	fire_sound = 'sound/weapons/gunshot/gunshot_strong.ogg'
	damage = 10
	damage_type = BRUTE
	damage_flags = DAM_SHARP
	nodamage = 0
	embed = 0

	var/obj/item/weapon/gun/hook/g = null

/obj/item/projectile/hook/Initialize(mapload, var/obj/item/weapon/gun/hook/h )
	. = ..()
	g = h
	log_world("Created projectie for gun [h] ")

/obj/item/projectile/hook/on_hit(var/atom/target, var/blocked = 0)
	if(target.density)
		new /obj/item/anchor(src, g)
	else return ..()

/obj/item/anchor
	var/obj/item/weapon/gun/hook/g = null

/obj/item/anchor/Initialize(mapload, var/obj/item/weapon/gun/hook/h)
	. = ..()
	g = h
	g.an = src
	START_PROCESSING(SSprocessing, src)
	log_world("Created anchor at [loc] with [h] ")

/obj/item/anchor/Process()
	Beam(g,icon_state="cable",icon='icons/effects/beam.dmi',time=3, maxdistance=15)

