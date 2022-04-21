//	Observer Pattern Implementation: Shuttle Moved
//		Registration type: /datum/shuttle/autodock
//
//		Raised when: A shuttle has moved to a new landmark.
//
//		Arguments that the called proc should expect:
//			/datum/shuttle/shuttle: the shuttle moving
//			/obj/shuttle_landmark/old_location: the old location's shuttle landmark
//			/obj/shuttle_landmark/new_location: the new location's shuttle landmark

//	Observer Pattern Implementation: Shuttle Pre Move
//		Registration type: /datum/shuttle/autodock
//
//		Raised when: A shuttle is about to move to a new landmark.
//
//		Arguments that the called proc should expect:
//			/datum/shuttle/shuttle: the shuttle moving
//			/obj/shuttle_landmark/old_location: the old location's shuttle landmark
//			/obj/shuttle_landmark/new_location: the new location's shuttle landmark

GLOBAL_DATUM_INIT(shuttle_moved_event, /singleton/observ/shuttle_moved, new)

/singleton/observ/shuttle_moved
	name = "Shuttle Moved"
	expected_type = /datum/shuttle

GLOBAL_DATUM_INIT(shuttle_pre_move_event, /singleton/observ/shuttle_pre_move, new)

/singleton/observ/shuttle_pre_move
	name = "Shuttle Pre Move"
	expected_type = /datum/shuttle

/*****************
* Shuttle Moved/Pre Move Handling *
*****************/

// Located in modules/shuttle/shuttle.dm
// Proc: /datum/shuttle/proc/attempt_move()


//	Observer Pattern Implementation: Shuttle Pre Take off
//		Registration type: /datum/shuttle
//
//		Raised when: A shuttle starts process to leave a landmark and head to another (either short or long jump)
//
//		Arguments that the called proc should expect:
//			/datum/shuttle/shuttle: the shuttle moving
//			/obj/effect/shuttle_landmark/old_location: the old location's shuttle landmark
//			/obj/effect/shuttle_landmark/new_location: the new location's shuttle landmark

//	Observer Pattern Implementation: Shuttle End Take off
//		Registration type: /datum/shuttle
//
//		Raised when: A shuttle ends process to leave a landmark (either short or long jump). Either they managed to take off or the process was aborted
//
//		Arguments that the called proc should expect:
//			/datum/shuttle/shuttle: the shuttle moving
//			/obj/effect/shuttle_landmark/old_location: the old location's shuttle landmark
//			/obj/effect/shuttle_landmark/new_location: the new location's shuttle landmark
//			/success: true if the shuttle managed to take off, false if the process was aborted

//	Observer Pattern Implementation: Shuttle Pre Land
//		Registration type: /datum/shuttle
//
//		Raised when: A shuttle starts process to move to another landmark (either short or long jump)
//
//		Arguments that the called proc should expect:
//			/datum/shuttle/shuttle: the shuttle moving
//			/obj/effect/shuttle_landmark/old_location: the old location's shuttle landmark
//			/obj/effect/shuttle_landmark/new_location: the new location's shuttle landmark

//	Observer Pattern Implementation: Shuttle End Land
//		Registration type: /datum/shuttle
//
//		Raised when: A shuttle ends process to move to landmark (either short or long jump). It considers the initial and final landmarks, and not any transition/interim ones
//
//		Arguments that the called proc should expect:
//			/datum/shuttle/shuttle: the shuttle moving
//			/obj/effect/shuttle_landmark/old_location: the old location's shuttle landmark
//			/obj/effect/shuttle_landmark/new_location: the new location's shuttle landmark

GLOBAL_DATUM_INIT(shuttle_take_off_event, /singleton/observ/shuttle_take_off, new)

/singleton/observ/shuttle_take_off
	name = "Shuttle take off"
	expected_type = /datum/shuttle

GLOBAL_DATUM_INIT(shuttle_pre_take_off_event, /singleton/observ/shuttle_pre_take_off, new)

/singleton/observ/shuttle_pre_take_off
	name = "Shuttle Pre take off"
	expected_type = /datum/shuttle
