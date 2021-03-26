atom/movable/reflection
    appearance_flags = PIXEL_SCALE
    color = list(1,0,0,0,
                 0,1,0,0,
                 0,0,1,0,
                 0,0,0,1,
                 0.3125,0.3125,0.3125,0)
    
atom/movable/reflection/proc/update_appearance(atom/movable/owner)
    filters = null
    appearance = owner.appearance
    filters += filter(type="blur")
    pixel_y = owner.reflection_offset
    pixel_x = 0
    pixel_z = 0
    pixel_w = 0
    // var/matrix/m2 = matrix(1.25,0,0,0,-1,0)
    // var/matrix/m1 = matrix(0.75,0,0,0,-1,0)
    var/matrix/m0 = matrix(1,0,0,0,-1,0)
    transform = m0
    // animate(src,transform=m1,time=2.5,loop=-1)
    // animate(transform=m0,time=2.5)
    // animate(transform=m2,time=2.5)
    // animate(transform=m0,time=2.5)
    alpha = 192
    layer = REFLECTION_LAYER
    vis_flags = VIS_INHERIT_DIR
    mouse_opacity = 0

atom/movable/reflection/Initialize(mapload, atom/movable/owner)
    . = ..()
    //set up a simple passive animation for the reflection to give it a sort of wavering effect.
    update_appearance(owner)
    owner.vis_contents += src
    

atom

    var/has_reflection = FALSE
    var/reflection_offset = -11
    var/tmp/atom/movable/reflection/reflection

/mob/living
    has_reflection = TRUE
    reflection_offset = -31

/obj/item
    has_reflection = TRUE

atom/movable/Initialize(mapload, ...)
    ..()
    if(has_reflection && !reflection)
        reflection = new (null,src)

turf/Initialize(mapload, ...)
    ..()
    if(has_reflection && !reflection)
        reflection = new (null,src)

atom/movable/Destroy()
    if(reflection)
        vis_contents -= reflection
        QDEL_NULL(reflection)
    . = ..()

turf/Destroy()
    if(reflection)
        vis_contents -= reflection
        QDEL_NULL(reflection)
    . = ..()

atom/on_update_icon()
    . = ..()
    if(reflection)
        reflection.update_appearance(src)
