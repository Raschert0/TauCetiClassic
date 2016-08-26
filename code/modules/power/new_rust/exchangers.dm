/obj/machinery/power/rust/exchanger
	name = "R-UST Mk 7 Tokamak exchanger"
	desc = "This is placeholder"
	icon = 'code/modules/power/rust/rust.dmi'
	icon_state = "core0"
	var/obj/machinery/atmospherics/unary/generator_input/connector
	density = 1

/obj/machinery/power/rust/exchanger/inlet
	name = "R-UST Mk 7 Tokamak exchanger inlet"

/obj/machinery/power/rust/exchanger/outlet
	name = "R-UST Mk 7 Tokamak exchanger outlet"

/obj/machinery/power/rust/exchanger/New()
	connector = new(src)
	connector.dir = EAST

/obj/machinery/power/rust/exchanger/Destroy()
	if(connector)
		qdel(connector)
		connector = null
	return ..()
