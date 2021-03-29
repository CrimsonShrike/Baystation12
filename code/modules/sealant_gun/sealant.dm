/obj/item/clothing/sealant
	name = "glob of sealant"
	desc = "A blob of metal foam sealant."
	icon = 'icons/effects/sealant.dmi'
	icon_state = "world"
	force = 0
	throwforce = 0
	color = "#cccdcc"
	slowdown_general = 3
	tint = TINT_BLIND
	canremove = FALSE
	slot_flags = SLOT_EYES|SLOT_HEAD|SLOT_MASK|SLOT_GLOVES|SLOT_TWOEARS|SLOT_OCLOTHING|SLOT_FEET

	item_icons = list(
		slot_head_str = 'icons/effects/sealant.dmi', 
		slot_l_hand_str = 'icons/effects/sealant.dmi',
		slot_r_hand_str = 'icons/effects/sealant.dmi',
		slot_wear_mask_str = 'icons/effects/sealant.dmi', 
		slot_wear_suit_str = 'icons/effects/sealant.dmi', 
		slot_shoes_str = 'icons/effects/sealant.dmi'
		)

	item_state_slots = list(
		slot_head_str = "humanoid body-slot_head", 
		slot_l_hand_str = "humanoid body-slot_l_hand",
		slot_r_hand_str = "humanoid body-slot_r_hand",
		slot_wear_mask_str = "humanoid body-slot_wear_mask", 
		slot_wear_suit_str = "humanoid body-slot_suit", 
		slot_shoes_str = "humanoid body-slot_shoes"
		)

	var/foam_type = /obj/structure/foamedmetal
	var/splatted = FALSE // Used to prevent doubled effects if throwcode wonks up.
	var/hardened = FALSE // Set manually post-equip so that the blob can't be removed without breaking.
	var/static/list/splat_try_equip_slots = list(
		slot_head, 
		slot_l_hand,
		slot_r_hand, 
		slot_wear_mask, 
		slot_wear_suit, 
		slot_shoes
	)
	
/obj/item/clothing/sealant/equipped(mob/user, slot)
	. = ..()
	if(hardened)
		break_apart(user)
	else
		to_chat(user, SPAN_DANGER("Hardened globs of metal foam stick to you!"))
		hardened = TRUE
		update_icon()

/obj/item/clothing/sealant/on_update_icon()
	. = ..()
	if(hardened)
		icon_state = "inventory"
	else icon_state = "world"

/obj/item/clothing/sealant/attack_hand(mob/user)
	break_apart(user)
	return TRUE

/obj/item/clothing/sealant/attackby(obj/item/W, mob/user)
	break_apart(user)
	return TRUE

/obj/item/clothing/sealant/dropped(mob/user)
	. = ..()
	break_apart()

/obj/item/clothing/sealant/proc/break_apart(var/mob/user)
	canremove = TRUE
	if(user)
		user.unEquip(src, user.loc)
		user.visible_message(SPAN_NOTICE("\The [user] smashes \the [src]!"), SPAN_NOTICE("You smash \the [src]!"), SPAN_NOTICE("You hear a smashing sound."))
		user.setClickCooldown(1 SECOND)
	qdel(src)

/obj/item/clothing/sealant/Bump(atom/A, forced)
	. = ..()
	splat(A)

/obj/item/clothing/sealant/throw_impact(atom/hit_atom)
	. = ..()
	splat(hit_atom)

/obj/item/clothing/sealant/proc/splat(var/atom/target)
	if(splatted)
		return
	splatted = TRUE
	var/turf/T = get_turf(target) || get_turf(src)
	if(T)
		new /obj/effect/sealant(T)
		if(isliving(target))
			var/mob/living/H = target
			for(var/slot in shuffle(splat_try_equip_slots))
				if(!H.get_equipped_item(slot))
					H.equip_to_slot_if_possible(src, slot)
					if(H.get_equipped_item(slot) == src)
						return
		if(!T.density && !(locate(foam_type) in T))
			new foam_type(T)

	if(!QDELETED(src))
		qdel(src)

/obj/effect/sealant
	name = "sealant glob"
	desc = "A blob of metal foam sealant."
	icon = 'icons/effects/sealant.dmi'
	icon_state = "blank"
	layer = PROJECTILE_LAYER
	color = "#cccdcc"

/obj/effect/sealant/Initialize()
	. = ..()
	flick("blobsplat", src)
	QDEL_IN(src, 1 SECOND)