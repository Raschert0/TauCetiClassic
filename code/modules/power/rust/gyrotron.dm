/obj/machinery/power/gyrotron
	icon = 'code/modules/power/rust/rust.dmi'
	icon_state = "emitter-off"
	name = "gyrotron"
	anchored = 0
	density = 1
	layer = 2.9

	var/frequency = 1
	var/emitting = 0
	var/rate = 10
	var/mega_energy = 0.001
	var/id_tag
	var/emit_timer_id
	var/state = 0

	req_access = list(access_engine)

	use_power = 1
	idle_power_usage = 10
	active_power_usage = 100000 //Yes that is a shitton. No you're not running this engine on an SE/AME you SE/AME scrubs.

/obj/machinery/power/gyrotron/New()
	. = ..()
	if(!id_tag)
		assign_uid()
		id_tag = num2text(uid)

/obj/machinery/power/gyrotron/Destroy()
	message_admins("Gyrotron deleted at ([x],[y],[z] - <A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[x];Y=[y];Z=[z]'>JMP</a>)",0,1)
	log_game("Gyrotron deleted at ([x],[y],[z])")
	investigate_log("<font color='red'>deleted</font> at ([x],[y],[z])","singulo")
	..()

/obj/machinery/power/gyrotron/initialize()
	..()
	if(state == 2 && anchored)
		connect_to_network()
		src.directwired = 1

/obj/machinery/power/gyrotron/proc/stop_emitting()
	emitting = 0
	use_power = 1
	deltimer(emit_timer_id)
	update_icon()

/obj/machinery/power/gyrotron/proc/start_emitting()
	if(stat & (NOPOWER | BROKEN) || emitting && state == 2) //Sanity.
		return

	emitting = 1
	use_power = 2
	emit()
	emit_timer_id = addtimer(src, "emit", rate, TRUE)

	update_icon()

/obj/machinery/power/gyrotron/proc/emit()
	var/obj/item/projectile/beam/emitter/A = PoolOrNew(/obj/item/projectile/beam/emitter, loc)
	A.frequency = frequency
	A.damage = mega_energy * 1500

	playsound(get_turf(src), 'sound/weapons/emitter.ogg', 25, 1)
	use_power(100 * mega_energy + 500)

	A.dir = dir
	A.starting = get_turf(src)
	switch(dir)
		if(NORTH)
			A.original = locate(x, y+1, z)
		if(EAST)
			A.original = locate(x+1, y, z)
		if(WEST)
			A.original = locate(x-1, y, z)
		else // Any other
			A.original = locate(x, y-1, z)
	A.process()

	flick("emitter-active", src)

/obj/machinery/power/gyrotron/power_change()
	. =..()
	if(stat & (NOPOWER | BROKEN))
		stop_emitting()

	update_icon()

/obj/machinery/power/gyrotron/update_icon()
	if(!(stat & (NOPOWER | BROKEN)) && emitting)
		icon_state = "emitter-on"
	else
		icon_state = "emitter-off"

/obj/machinery/power/gyrotron/attackby(obj/item/W, mob/user)

	if(istype(W, /obj/item/weapon/wrench))
		if(emitting)
			user << "Turn off the [src] first."
			return
		switch(state)
			if(0)
				state = 1
				playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
				user.visible_message("[user.name] secures [src.name] to the floor.", \
					"You secure the external reinforcing bolts to the floor.", \
					"You hear a ratchet")
				src.anchored = 1
			if(1)
				state = 0
				playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
				user.visible_message("[user.name] unsecures [src.name] reinforcing bolts from the floor.", \
					"You undo the external reinforcing bolts.", \
					"You hear a ratchet")
				src.anchored = 0
			if(2)
				user << "\red The [src.name] needs to be unwelded from the floor."
		return

	if(istype(W, /obj/item/weapon/weldingtool))
		var/obj/item/weapon/weldingtool/WT = W
		if(emitting)
			user << "Turn off the [src] first."
			return
		switch(state)
			if(0)
				user << "\red The [src.name] needs to be wrenched to the floor."
			if(1)
				if (WT.remove_fuel(0,user))
					playsound(src.loc, 'sound/items/Welder2.ogg', 50, 1)
					user.visible_message("[user.name] starts to weld the [src.name] to the floor.", \
						"You start to weld the [src] to the floor.", \
						"You hear welding")
					if (do_after(user,20,target = src))
						if(!src || !WT.isOn()) return
						state = 2
						user << "You weld the [src] to the floor."
						connect_to_network()
						src.directwired = 1
				else
					user << "\red You need more welding fuel to complete this task."
			if(2)
				if (WT.remove_fuel(0,user))
					playsound(src.loc, 'sound/items/Welder2.ogg', 50, 1)
					user.visible_message("[user.name] starts to cut the [src.name] free from the floor.", \
						"You start to cut the [src] free from the floor.", \
						"You hear welding")
					if (do_after(user,20,target = src))
						if(!src || !WT.isOn()) return
						state = 1
						user << "You cut the [src] free from the floor."
						disconnect_from_network()
						src.directwired = 0
				else
					user << "\red You need more welding fuel to complete this task."
		return

	if(istype(W, /obj/item/device/multitool))
		var/obj/item/device/multitool/M = W
		M.buffer = src
		user << "<span class='notice'>You save the data in the [M.name]'s buffer.</span>"
		return

/*
	if(default_deconstruction_screwdriver(user, "emitter_open", "emitter", W))
		return

	if(exchange_parts(user, W))
		return

	if(default_pry_open(W))
		return

	default_deconstruction_crowbar(W)
	*/

	..()
	return

/obj/machinery/power/gyrotron/verb/rotate_cw()
	set name = "Rotate (Clockwise)"
	set src in oview(1)
	set category = "Object"

	if(usr.incapacitated() || !Adjacent(usr))
		return

	if(anchored)
		usr << "\blue The [src] is anchored to the floor!"
		return

	dir = turn(dir, -90)

/obj/machinery/power/gyrotron/verb/rotate_ccw()
	set name = "Rotate (Counter-Clockwise)"
	set src in oview(1)
	set category = "Object"

	if(usr.incapacitated() || !Adjacent(usr))
		return

	if(anchored)
		usr << "\blue The [src] is anchored to the floor!"
		return

	dir = turn(dir, 90)
