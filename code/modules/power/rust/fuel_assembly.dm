
/obj/item/weapon/fuel_assembly
	icon = 'code/modules/power/rust/rust.dmi'
	icon_state = "fuel_assembly"
	name = "fuel rod assembly"
	var/list/rod_quantities
	var/percent_depleted = 1
	layer = 2.9

/obj/item/weapon/fuel_assembly/New()
	. = ..()
	rod_quantities = list()
