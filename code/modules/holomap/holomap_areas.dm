//Some generic area stuff for holomaps, if you add new areas you probably want to double check colours and flags

/area
    var/holomap_color	// Color of this area on the holomap. Must be a hex color (as string) or null.

/area/shuttle
    area_flags = AREA_FLAG_HIDE_FROM_HOLOMAP

/area/chapel
	holomap_color = HOLOMAP_AREACOLOR_CREW

/area/engineering
	holomap_color = HOLOMAP_AREACOLOR_ENGINEERING

/area/hallway
	holomap_color = HOLOMAP_AREACOLOR_HALLWAYS

/area/medical
	holomap_color = HOLOMAP_AREACOLOR_MEDICAL

/area/security
	holomap_color = HOLOMAP_AREACOLOR_SECURITY

/area/rnd
	holomap_color = HOLOMAP_AREACOLOR_SCIENCE

/area/supply
	area_flags = AREA_FLAG_HIDE_FROM_HOLOMAP

/area/turbolift
	holomap_color = HOLOMAP_AREACOLOR_LIFTS

/area/turret_protected
	area_flags = AREA_FLAG_HIDE_FROM_HOLOMAP