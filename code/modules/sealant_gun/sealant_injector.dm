/obj/item/reagent_containers/chem_disp_cartridge/foaming_agent
	spawn_reagent = /datum/reagent/foaming_agent
/obj/item/reagent_containers/chem_disp_cartridge/polyacid
	spawn_reagent = /datum/reagent/acid/polyacid

/obj/structure/sealant_injector
	name = "sealant tank injector"
	icon = 'icons/obj/structures/sealant_props.dmi'
	icon_state = "injector"

	var/list/cartridges
	var/obj/item/sealant_tank/loaded_tank
	var/max_cartridges = 3

/obj/structure/sealant_injector/Destroy()
	QDEL_NULL_LIST(cartridges)
	QDEL_NULL(loaded_tank)
	. = ..()

/obj/structure/sealant_injector/on_update_icon()
	overlays.Cut()
	if(loaded_tank)
		overlays += image(icon, "tank")
	if(length(cartridges))
		overlays += image(icon, "carts[length(cartridges)]")

/obj/structure/sealant_injector/Initialize(mapload, _mat, _reinf_mat)
	. = ..()
	cartridges = list(
		new /obj/item/reagent_containers/chem_disp_cartridge/aluminium(src) = 3,
		new /obj/item/reagent_containers/chem_disp_cartridge/foaming_agent(src) = 1,
		new /obj/item/reagent_containers/chem_disp_cartridge/polyacid(src) = 1
	)

/obj/structure/sealant_injector/attackby(obj/item/O, mob/user)
	
	if(istype(O, /obj/item/sealant_tank))
		if(loaded_tank)
			to_chat(user, SPAN_WARNING("\The [src] already has a sealant tank inserted."))
			return TRUE
		if(user.unEquip(O, src))
			loaded_tank = O
			update_icon()
			return TRUE

	if(istype(O, /obj/item/reagent_containers/chem_disp_cartridge))
		if(length(cartridges) >= max_cartridges)
			to_chat(user, SPAN_WARNING("\The [src] is loaded to capacity with cartridges."))
			return TRUE
		if(user.unEquip(O, src))
			LAZYSET(cartridges, O, 1)
			update_icon()
			return TRUE

	. = ..()

/obj/structure/sealant_injector/AltClick(mob/user)
	if(Adjacent(user) && CanPhysicallyInteract(user))
		try_inject(user)

/obj/structure/sealant_injector/proc/try_inject(mob/user)

	if(!loaded_tank)
		to_chat(user, SPAN_WARNING("There is no tank loaded."))
		return TRUE

	var/fill_space = Floor(loaded_tank.max_foam_charges - loaded_tank.foam_charges) / 5
	if(fill_space <= 0)
		to_chat(user, SPAN_WARNING("\The [loaded_tank] is full."))
		return TRUE

	var/injected = FALSE
	for(var/obj/item/reagent_containers/chem_disp_cartridge/cart in cartridges)
		if(cart.reagents?.total_volume <= cartridges[cart])
			visible_message("\The [src] flashes a red 'empty' light above \the [cart].")
			continue
		visible_message("Injecting [cartridges[cart] * fill_space]")
		injected = cart.reagents.trans_to_holder(loaded_tank.reagents, min(cart.reagents.total_volume, cartridges[cart] * fill_space))
		//user.set_click_cooldown(5)
	if(injected)
		playsound(loc, 'sound/effects/refill.ogg', 50, 1)
	
/obj/structure/sealant_injector/attack_hand(mob/user)

	if(loaded_tank)
		loaded_tank.dropInto(get_turf(src))
		user.put_in_hands(loaded_tank)
		loaded_tank = null
		update_icon()
		return TRUE

	if(length(cartridges))
		var/obj/cartridge = pick(cartridges)
		cartridges -= cartridge
		cartridge.dropInto(get_turf(user))
		user.put_in_hands(cartridge)
		update_icon()
		return TRUE

	. = ..()