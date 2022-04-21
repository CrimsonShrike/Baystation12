//Landmark decorators are a set of items tied to a shuttle landmark
//Their main use is to provide animations and sounds when the shuttle lands on a landmark

/obj/landmark_decorators
	anchored = TRUE

	var/landmark_tag


/obj/landmark_decorators/Initialize()
	. = ..()
	GLOB.shuttle_take_off_event.register_global(src, .proc/shuttle_take_off)
	GLOB.shuttle_pre_take_off_event.register_global(src, .proc/shuttle_pre_take_off)
	GLOB.shuttle_pre_move_event.register_global(src, .proc/shuttle_pre_take_off)

/obj/landmark_decorators/Destroy()
	GLOB.shuttle_pre_move_event.unregister_global(src)
	. = ..()

/obj/landmark_decorators/proc/shuttle_pre_take_off()
	if (GLOB.shuttle_landed_on_landmark == .landmark_tag)
		GLOB.shuttle_landed_on_landmark = ""

/obj/landmark_decorators/proc/shuttle_take_off()
	if (GLOB.shuttle_landed_on_landmark == .landmark_tag)
		GLOB.shuttle_landed_on_landmark = ""
