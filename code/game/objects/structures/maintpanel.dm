/obj/structure/maintpanel
    name = "maintenance panel"
    desc = "Something to maintain awaits inside."
    icon = 'icons/obj/maintpanel.dmi'
    icon_state = "base"
    appearance_flags = KEEP_TOGETHER
    density = 0
    anchored = 1
    var/open = FALSE
    var/list/obj/objects = list()
    var/obj/effect/maskpart/mask
    var/obj/effect/maskpart/background

/obj/effect/maskpart
    mouse_opacity = 0
    layer = FLOAT_LAYER
    plane = FLOAT_PLANE

/obj/effect/maskpart/mask
    icon = 'icons/obj/maintpanel.dmi'
    icon_state = "mask"

/obj/effect/maskpart/bg
    icon = 'icons/obj/maintpanel.dmi'
    icon_state = "background"
    appearance_flags = KEEP_TOGETHER
    blend_mode = BLEND_MULTIPLY

/obj/effect/maskpart/pipe
    var/weakref/pipe
    mouse_opacity = 1

/obj/effect/maskpart/pipe/attackby(obj/item/I, mob/user)
    var/obj/item/WR = pipe.resolve()
    if(istype(WR))
        return WR.attackby(I, user)
    
/obj/structure/maintpanel/Initialize()
    . = ..()
    mask = new/obj/effect/maskpart/mask(null)
    background = new/obj/effect/maskpart/bg(null)

    mask.vis_contents += background



/obj/structure/maintpanel/proc/open()
    visible_message("<span class='notice'>Panel open</span>")
    open = TRUE
    vis_contents += mask

    for(var/obj/machinery/atmospherics/pipe/p in loc)
        var/obj/effect/maskpart/pipe/P = new(null)
        P.appearance = p
        P.invisibility = 0
        P.layer = FLOAT_LAYER
        P.plane = FLOAT_PLANE
        P.dir = p.dir
        P.pipe = weakref(p)
        objects += P
        background.vis_contents += P

/obj/structure/maintpanel/proc/close()
    visible_message("<span class='notice'>Panel closed</span>")
    open = FALSE
    vis_contents -= mask
    background.vis_contents.Cut()
    objects.Cut()
    

/obj/structure/maintpanel/attack_hand(mob/user)
    . = ..()
    if(open)
        close()
    else open()