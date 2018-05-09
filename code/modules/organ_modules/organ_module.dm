/obj/item/organ/augment
	name = "embedded organ module"
	desc = "Embedded organ module."
	icon = 'icons/obj/augment.dmi'
	//By default these fit on both flesh and robotic organs and are robotic
	status = ORGAN_ROBOT
	var/augment_flags = AUGMENTATION_MECHANIC | AUGMENTATION_ORGANIC

//General expectation is onInstall and onRemoved are overwritten to add effects to augmentee
/obj/item/organ/augment/replaced(var/mob/living/carbon/human/target)
	..()

	if(istype(owner))
		onInstall()

/obj/item/organ_module/proc/onInstall()


/obj/item/organ/augment/removed(var/mob/living/user, var/drop_organ=1)
	onRemove()
	..()

/obj/item/organ_module/proc/onRemove()

