/*
Multitile RUST? OKAY!
*/

#define MAX_FIELD_FREQ 1000
#define MIN_FIELD_FREQ 1
#define MAX_FIELD_STR 1000
#define MIN_FIELD_STR 1
#define RUST_CORE_STR_COST 5

/obj/machinery/power/rust
	name = "R-UST Mk 7 Tokamak"
	desc = "This is placeholder"
	icon = 'code/modules/power/rust/rust.dmi'
	icon_state = "core0"
	var/obj/machinery/power/rust/rust_core/core
	density = 1

/obj/machinery/power/rust/rust_core
	name = "R-UST Mk 7 Tokamak core"
	desc = "An enormous solenoid for generating extremely high power electromagnetic fields"
	icon = 'code/modules/power/rust/rust.dmi'
	icon_state = "core0"
	var/light_power_on = 2
	var/light_range_on = 3
	light_color = "#6496fa"

	var/list/obj/machinery/power/rust/connected_parts
	var/field_strength = 1//0.01
	var/field_frequency = 1
	var/id_tag
	var/state = 0
	use_power = 1
	idle_power_usage = 50
	active_power_usage = 500	//multiplied by field strength
	anchored = 0
	var/injectors = 0
	var/exchangers = 0
	var/datum/gas_mixture/int_gas

/obj/machinery/power/rust/rust_core/New()
	. = ..()
	int_gas = new()
	if(ticker)
		initialize()

/obj/machinery/power/rust/rust_core/part_scan()
	connected_parts = list()
	var/tally = 0
	var/ldir = turn(dir,-90)
	var/rdir = turn(dir,90)
	var/odir = turn(dir,180)
	var/turf/T = src.loc
	T = get_step(T,rdir)
	if(!check_part(T,/obj/machinery/power/rust/magnetic_coil))
		return
	T = get_step(T,rdir)
	T = get_step(T,dir)
	if(!check_part(T,/obj/machinery/power/rust/en_injector && !check_part(T,/obj/machinery/power/rust/f_injector))
		return
	T = get_step(T,rdir)
	T = get_step(T,dir)
	if(!check_part(T,/obj/machinery/power/rust/exchanger))
		return
	T = get_step(T,dir)
	if(!check_part(T,/obj/machinery/power/rust/magnetic_coil))
		return
	T = get_step(T,dir)
	if(!check_part(T,/obj/machinery/power/rust/exchanger))
		return
	T = get_step(T,dir)
	T = get_step(T,ldir)
	if(!check_part(T,/obj/machinery/power/rust/en_injector && !check_part(T,/obj/machinery/power/rust/f_injector))
		return
	T = get_step(T,dir)
	T = get_step(T,ldir)
	if(!check_part(T,/obj/machinery/power/rust/magnetic_coil))
		return
T = get_step(T,ldir)

/obj/machinery/rust/rust_core/proc/check_part(var/turf/T, var/type)
	if(!T || !type)
		return 0
	var/obj/machinery/rust/R = locate(/obj/machinery/rust) in T
	if(istype(R, type))
		src.connected_parts += R
		R.core = src
		return 1
	return 0

/obj/machinery/power/rust/rust_core/initialize()
	if(!id_tag)
		assign_uid()
		id_tag = uid

/obj/machinery/power/rust/rust_core/process()
	if(stat & BROKEN || !powernet)
		//Shutdown()
