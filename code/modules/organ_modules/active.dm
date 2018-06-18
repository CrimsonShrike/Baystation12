//Toggleable embedded module
/obj/item/organ/augment/active
	var/verb_name = "Activate"
	var/verb_desc = "activate embedded module"
	var/obj/item/organ/external/limb


/obj/item/organ/augment/active/proc/activate()
/obj/item/organ/augment/active/proc/deactivate()

//Give verbs on install
/obj/item/organ/augment/active/onInstall()
	limb = loc
	if(istype(limb))
		limb.verbs += /obj/item/organ/augment/active/proc/activate
		//new /obj/item/organ/external/proc/activate_module(limb, verb_name, verb_desc)

/obj/item/organ/augment/active/onRemove()
	limb.verbs -= /obj/item/organ/augment/active/proc/activate


/obj/item/organ/augment/active/proc/can_activate()
	if(owner.incapacitated())
		to_chat(owner, SPAN_WARNING("You can't do that now!"))
		return

	return TRUE

