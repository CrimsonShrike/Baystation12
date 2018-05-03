//////////////////////////////////////////////////////////////////
//	organ module installation
//////////////////////////////////////////////////////////////////
/datum/surgery_step/robotics/install_organ_module
	allowed_tools = list(
	/obj/item/organ_module = 100,
	)

	min_duration = 60
	max_duration = 80

/datum/surgery_step/robotics/install_organ_module/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)



	var/obj/item/organ_module/OM = tool
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(!(affected && affected.hatch_state == HATCH_OPENED))
		return 0

	if(!istype(OM))
		return 0

	if(!(affected.organ_tag in OM.allowed_organs))
		return

	if(!(affected.robotic >= ORGAN_ROBOT))
		to_chat(user, "<span class='danger'>You cannot install augmentations into a meat body.</span>")
		return -1

	if(affected.module)
		to_chat(user, "<span class='danger'>There's already something installed in here.</span>")
		return -1

	return 1

/datum/surgery_step/robotics/install_organ_module/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message("[user] starts installing \the [tool] into [target]'s [affected.name].", \
	"You start installing \the [tool] into [target]'s [affected.name].")
	..()

/datum/surgery_step/robotics/install_organ_module/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message("<span class='notice'>[user] has installed \the [tool] into [target]'s [affected.name].</span>", \
	"<span class='notice'>You have installed \the [tool] into [target]'s [affected.name].</span>")

	var/obj/item/organ_module/OM = tool

	//Check again
	if(!affected.module)
		user.unEquip(OM)//Remove from surgeon
		affected.module = OM
		OM.install(affected)

/datum/surgery_step/robotics/install_organ_module/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message("<span class='warning'>[user]'s hand slips, failing to install \the [tool] inside [target]'s [affected.name].</span>", \
	"<span class='warning'>Your hand slips, failing to install \the [tool] inside [target]'s [affected.name].</span>")




//////////////////////////////////////////////////////////////////
//	organ module removal
//////////////////////////////////////////////////////////////////
/datum/surgery_step/robotics/uninstall_organ_module
	allowed_tools = list(
		/obj/item/weapon/hemostat = 100,
		/obj/item/weapon/wirecutters = 75
	)

	priority = 3
	min_duration = 60
	max_duration = 80

/datum/surgery_step/robotics/uninstall_organ_module/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)



	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(!(affected && affected.hatch_state == HATCH_OPENED && affected.module))
		return 0

	return 1

/datum/surgery_step/robotics/uninstall_organ_module/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message("[user] starts removing [affected.module], from [target]'s [affected] with \the [tool].",
		                 "You start removing [affected.module] from [target]'s [affected] with \the [tool].")
	..()

/datum/surgery_step/robotics/uninstall_organ_module/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message("<span class='notice'>[user] has removed \the [affected.module] from [target]'s [affected.name].</span>", \
	"<span class='notice'>You have removed \the [affected.module] from [target]'s [affected.name].</span>")

	var/obj/item/organ_module/OM = affected.module
	OM.remove(affected)
	affected.module = null

/datum/surgery_step/robotics/uninstall_organ_module/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message("<span class='warning'>[user]'s hand slips, failing to remove the module inside [target]'s [affected.name].</span>", \
	"<span class='warning'>Your hand slips, failing to remove the module inside [target]'s [affected.name].</span>")