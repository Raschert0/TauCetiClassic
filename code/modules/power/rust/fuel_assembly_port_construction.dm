#define WORLD_ICON_SIZE 32
//frame assembly

/obj/item/rust_fuel_assembly_port
	name = "Fuel Assembly Port frame"
	icon = 'code/modules/power/rust/rust.dmi'
	icon_state = "port2"
	w_class = 4
	flags = FPRINT | TABLEPASS
	siemens_coefficient = 1

/obj/item/rust_fuel_assembly_port/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if (iswrench(W))
		new /obj/item/stack/sheet/plasteel( get_turf(src.loc), 12 )
		del(src)
		return
	..()

/obj/item/rust_fuel_assembly_port/proc/try_build(turf/on_wall)
	if (get_dist(on_wall,usr)>1)
		return
	var/ndir = get_dir(usr,on_wall)
	if (!(ndir in cardinal))
		return
	var/turf/loc = get_turf(usr)
	var/area/A = loc.loc
	if (!istype(loc, /turf/simulated/floor))
		usr << "\red Fuel Assembly Port cannot be placed on this spot."
		return
	if (A.requires_power == 0 || istype(A, /area/space))
		usr << "\red Fuel Assembly Port cannot be placed in this area."
		return
	for(var/obj/machinery/rust_fuel_assembly_port/T in loc)
		usr << "\red There is another Fuel Assembly Port here."
		return
	new /obj/machinery/rust_fuel_assembly_port(loc, ndir, 1)
	qdel(src)

//construction steps
/obj/machinery/rust_fuel_assembly_port/New(turf/loc, var/ndir, var/building=0)
	..()

	// offset 24 pixels in direction of dir
	// this allows the APC to be embedded in a wall, yet still inside an area
	if (building)
		dir = ndir
	else
		has_electronics = 3
		opened = 0
		icon_state = "port0"

	//20% easier to read than apc code
	pixel_x = (dir & 3)? 0 : (dir == 4 ? WORLD_ICON_SIZE : -WORLD_ICON_SIZE)
	pixel_y = (dir & 3)? (dir ==1 ? WORLD_ICON_SIZE : -WORLD_ICON_SIZE) : 0

/obj/machinery/rust_fuel_assembly_port/attackby(obj/item/W, mob/user)

	if (issilicon(user) && get_dist(src,user)>1)
		return src.attack_hand(user)
	if (iscrowbar(W))
		if(opened)
			if(has_electronics & 1)
				playsound(get_turf(src), 'sound/items/Crowbar.ogg', 50, 1)
				user << "<span class='notice'> You begin removing the circuitboard </span>"//lpeters - fixed grammar issues

				if(do_after(user, 50, target = src))
					user.visible_message(\
						"<span class='warning'>[user.name] has removed the circuitboard from [src.name]!</span>",\
						"<span class='notice'>You remove the circuitboard.</span>")
					has_electronics = 0
					new /obj/item/weapon/module/rust_fuel_port(loc)
					has_electronics &= ~1
			else
				opened = 0
				icon_state = "port0"
				user << "<span class='notice'>You close the maintenance cover.</span>"
		else
			if(cur_assembly)
				user << "<span class='warning'>You cannot open the cover while there is a fuel assembly inside.</span>"
			else
				opened = 1
				user << "<span class='notice'>You open the maintenance cover.</span>"
				icon_state = "port2"
		return

	else if (istype(W, /obj/item/weapon/cable_coil) && opened && !(has_electronics & 2))
		var/obj/item/weapon/cable_coil/C = W
		if(C.amount < 10)
			user << "<span class='warning'>You need more wires.</span>"
			return
		user << "You start adding cables to the frame..."
		playsound(get_turf(src), 'sound/items/Deconstruct.ogg', 50, 1)
		if(do_after(user, 20, target = src) && C.amount >= 10)
			C.use(10)
			user.visible_message(\
				"<span class='warning'>[user.name] has added cables to the port frame!</span>",\
				"You add cables to the port frame.")
			has_electronics &= 2
		return

	else if (iswirecutter(W) && opened && (has_electronics & 2))
		user << "You begin to cut the cables..."
		playsound(get_turf(src), 'sound/items/Deconstruct.ogg', 50, 1)
		if(do_after(user, 50, target = src))
			var/obj/item/weapon/cable_coil/C = new /obj/item/weapon/cable_coil(loc)
			C.amount = 10
			user.visible_message(\
				"<span class='warning'>[user.name] cut the cabling inside the port.</span>",\
				"You cut the cabling inside the port.")
			has_electronics &= ~2
		return

	else if (istype(W, /obj/item/weapon/module/rust_fuel_port) && opened && !(has_electronics & 1))
		user << "You try to insert the port control board into the frame..."
		playsound(get_turf(src), 'sound/items/Deconstruct.ogg', 50, 1)
		if(do_after(user, 10, target = src))
			has_electronics &= 1
			user << "You place the port control board inside the frame."
			del(W)
		return

	else if (istype(W, /obj/item/weapon/weldingtool) && opened && !has_electronics)
		var/obj/item/weapon/weldingtool/WT = W
		if (WT.get_fuel() < 3)
			user << "<span class='notice'>You need more welding fuel to complete this task.</span>"
			return
		user << "You start welding the port frame..."
		playsound(get_turf(src), 'sound/items/Welder.ogg', 50, 1)
		if(do_after(user, 50, target = src))
			if(!src || !WT.remove_fuel(3, user)) return
			new /obj/item/rust_fuel_assembly_port(loc)
			user.visible_message(\
				"<span class='warning'>[src] has been cut away from the wall by [user.name].</span>",\
				"You detached the port frame.",\
				"<span class='warning'>You hear welding.</span>")
			del(src)
		return

	..()

#undef WORLD_ICON_SIZE