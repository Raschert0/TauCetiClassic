//the core [tokamaka generator] big funky solenoid, it generates an EM field

/*
when the core is turned on, it generates [creates] an electromagnetic field
the em field attracts plasma, and suspends it in a controlled torus (doughnut) shape, oscillating around the core

the field strength is directly controllable by the user
field strength = sqrt(energy used by the field generator)

the size of the EM field = field strength / k
(k is an arbitrary constant to make the calculated size into tilewidths)

1 tilewidth = below 5T
3 tilewidth = between 5T and 12T
5 tilewidth = between 10T and 25T
7 tilewidth = between 20T and 50T
(can't go higher than 40T)

energy is added by a gyrotron, and lost when plasma escapes
energy transferred from the gyrotron beams is reduced by how different the frequencies are (closer frequencies = more energy transferred)

frequency = field strength * (stored energy / stored moles of plasma) * x
(where x is an arbitrary constant to make the frequency something realistic)
the gyrotron beams' frequency and energy are hardcapped low enough that they won't heat the plasma much

energy is generated in considerable amounts by fusion reactions from injected particles
fusion reactions only occur when the existing energy is above a certain level, and it's near the max operating level of the gyrotron. higher energy reactions only occur at higher energy levels
a small amount of energy constantly bleeds off in the form of radiation

the field is constantly pulling in plasma from the surrounding [local] atmosphere
at random intervals, the field releases a random percentage of stored plasma in addition to a percentage of energy as intense radiation

the amount of plasma is a percentage of the field strength, increased by frequency
*/

/*
- VALUES -

max volume of plasma storeable by the field = the total volume of a number of tiles equal to the (field tilewidth)^2

*/

#define MAX_FIELD_FREQ 1000
#define MIN_FIELD_FREQ 1
#define MAX_FIELD_STR 1000
#define MIN_FIELD_STR 1
#define RUST_CORE_STR_COST 5

/obj/machinery/power/rust_core
	name = "R-UST Mk 7 Tokamak core"
	desc = "An enormous solenoid for generating extremely high power electromagnetic fields"
	icon = 'code/modules/power/rust/rust.dmi'
	icon_state = "core0"
	density = 1
	var/light_power_on = 2
	var/light_range_on = 3
	light_color = "#6496fa"

	var/obj/effect/effect/rust_em_field/owned_field
	var/field_strength = 1//0.01
	var/field_frequency = 1
	var/id_tag
	var/state = 0

	use_power = 1
	idle_power_usage = 50
	active_power_usage = 500	//multiplied by field strength
	anchored = 0

/obj/machinery/power/rust_core/New()
	. = ..()
	if(ticker)
		initialize()

/obj/machinery/power/rust_core/initialize()
	if(!id_tag)
		assign_uid()
		id_tag = uid

/obj/machinery/power/rust_core/process()
	if(stat & BROKEN || !powernet)
		Shutdown()

/obj/machinery/power/rust_core/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/weapon/wrench))
		if(owned_field)
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
		if(owned_field)
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
	if(istype(W, /obj/item/weapon/card/id) || istype(W, /obj/item/device/pda))
		if(emagged)
			user << "\red The lock seems to be broken"
			return
		if(src.allowed(user))
			if(active)
				src.locked = !src.locked
				user << "The controls are now [src.locked ? "locked." : "unlocked."]"
			else
				src.locked = 0 //just in case it somehow gets locked
				user << "\red The controls can only be locked when the [src] is online"
		else
			user << "\red Access denied."
		return


	if(istype(W, /obj/item/weapon/card/emag) && !emagged)
		locked = 0
		emagged = 1
		user.visible_message("[user.name] emags the [src.name].","\red You short out the lock.")
		return

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

/obj/machinery/power/rust_core/Topic(href, href_list)
	if(..()) return 1
	if(href_list["str"])
		var/dif = text2num(href_list["str"])
		field_strength = min(max(field_strength + dif, MIN_FIELD_STR), MAX_FIELD_STR)
		active_power_usage = 5 * field_strength	//change to 500 later
		if(owned_field)
			owned_field.ChangeFieldStrength(field_strength)

	if(href_list["freq"])
		var/dif = text2num(href_list["freq"])
		field_frequency = min(max(field_frequency + dif, MIN_FIELD_FREQ), MAX_FIELD_FREQ)
		if(owned_field)
			owned_field.ChangeFieldFrequency(field_frequency)

/obj/machinery/power/rust_core/proc/Startup()
	if(owned_field)
		return

	owned_field = new(loc, src)
	owned_field.ChangeFieldStrength(field_strength)
	owned_field.ChangeFieldFrequency(field_frequency)
	set_light(light_range_on, light_power_on, light_color)
	icon_state = "core1"
	use_power = 2
	. = 1

/obj/machinery/power/rust_core/proc/Shutdown()
	//todo: safety checks for field status
	if(owned_field)
		icon_state = "core0"
		qdel(owned_field)
		use_power = 1
		set_light(0)

/obj/machinery/power/rust_core/proc/AddParticles(var/name, var/quantity = 1)
	if(owned_field)
		owned_field.AddParticles(name, quantity)
		. = 1

/obj/machinery/power/rust_core/bullet_act(var/obj/item/projectile/Proj)
	if(owned_field)
		. = owned_field.bullet_act(Proj)

/obj/machinery/power/rust_core/proc/set_strength(var/value)
	value = Clamp(MIN_FIELD_STR, value, MAX_FIELD_STR)
	field_strength = value
	active_power_usage = RUST_CORE_STR_COST * value
	if(owned_field)
		owned_field.ChangeFieldStrength(value)

/obj/machinery/power/rust_core/proc/set_frequency(var/value)
	value = Clamp(MIN_FIELD_FREQ, value, MAX_FIELD_FREQ)
	field_frequency = value
	if(owned_field)
		owned_field.ChangeFieldFrequency(value)
