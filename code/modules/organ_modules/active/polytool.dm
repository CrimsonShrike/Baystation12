/obj/item/organ_module/active/polytool
	name = "Polytool embedded module"
	verb_name = "Deploy tool"
	icon_state = "multitool"
	allowed_organs = list(BP_R_ARM, BP_L_ARM)
	var/list/items = list()
	var/list/paths = list() //We may lose them

/obj/item/organ_module/active/polytool/New()
	..()
	for(var/path in paths)
		var/obj/item/I = new path (src)
		I.canremove = FALSE
		items += I

/obj/item/organ_module/active/polytool/proc/holding_dropped(var/obj/item/I)

	//Stop caring
	GLOB.item_unequipped_event.unregister(I, src)

	if(I.loc != src) //something went wrong and is no longer attached/ it broke
		I.canremove = 1

/obj/item/organ_module/active/polytool/activate(mob/living/carbon/human/H, obj/item/organ/external/E)
	var/target_hand = E.organ_tag == BP_L_ARM ? slot_l_hand : slot_r_hand
	var/obj/I = H.get_active_hand()
	if(I)
		if(I.type in paths && !(I.type in items)) //We don't want several of same but you can replace parts whenever
			H.drop_from_inventory(I, src)
			items += I
			H.visible_message(
				SPAN_WARNING("[H] retracts \his [I] into [E]."),
				SPAN_NOTICE("You retract your [I] into [E].")
			)
		else
			to_chat(H, SPAN_WARNING("You must drop [I] before tool can be extend."))
	else
		var/obj/item = input(H, "Select item for deploy") as null|anything in src
		if(!item || !src.loc in H.organs || H.incapacitated())
			return
		if(H.equip_to_slot_if_possible(item, target_hand))
			items -= item
			//Keep track of it, make sure it returns
			GLOB.item_unequipped_event.register(item, src, /obj/item/organ_module/active/simple/proc/holding_dropped )
			H.visible_message(
				SPAN_WARNING("[H] extend \his [item] from [E]."),
				SPAN_NOTICE("You extend your [item] from [E].")
			)