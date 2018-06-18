/obj/item/organ/augment
	name = "embedded organ module"
	desc = "Embedded organ module."
	icon = 'icons/obj/augment.dmi'
	//By default these fit on both flesh and robotic organs and are robotic
	status = ORGAN_ROBOT
	var/augment_flags = AUGMENTATION_MECHANIC | AUGMENTATION_ORGANIC
	var/list/allowed_organs = list(BP_R_ARM, BP_L_ARM)

//General expectation is onInstall and onRemoved are overwritten to add effects to augmentee
/obj/item/organ/augment/replaced(var/mob/living/carbon/human/target)
	..()

	if(istype(owner))
		onInstall()

/obj/item/organ/augment/proc/onInstall()


/obj/item/organ/augment/removed(var/mob/living/user, var/drop_organ=1)
	onRemove()
	..()

/obj/item/organ/augment/proc/onRemove()


/obj/item/organ/augment/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W, /obj/item/weapon/screwdriver) && allowed_organs.len > 1)
		//Here we can adjust location for implants that allow multiple slots
		parent_organ = input(user, "Adjust installation parameters") as null|anything in allowed_organs
		return
	..()

