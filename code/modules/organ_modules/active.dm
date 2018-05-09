//Toggleable embedded module
/obj/item/organ/augment/active
	var/verb_name = "Activate"
	var/verb_desc = "activate embedded module"
	var/obj/item/organ/external/limb

//Give verbs on install
/obj/item/organ_module/active/onInstall()
	limb = loc
	if(istype(limb))
		new /obj/item/organ/external/proc/activate_module(limb, verb_name, verb_desc)

/obj/item/organ_module/active/onRemove()
	limb.verbs -= /obj/item/organ/external/proc/activate_module


/obj/item/organ_module/active/proc/can_activate()
	if(owner.incapacitated())
		to_chat(H, SPAN_WARNING("You can't do that now!"))
		return

	return TRUE

/obj/item/organ_module/active/proc/activate()
/obj/item/organ_module/active/proc/deactivate()