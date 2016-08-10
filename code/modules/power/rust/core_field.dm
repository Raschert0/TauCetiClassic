//the em field is where the fun happens
/*
Deuterium-deuterium fusion : 40 x 10^7 K
Deuterium-tritium fusion: 4.5 x 10^7 K
*/

#define PIXEL_MULTIPLIER WORLD_ICON_SIZE/32
#define MAGIC_COEF 1.2 //almost transfer circle area in meters to square area in metes
#define MINIMUM_REACTANT_AMOUNT 0.00001
#define SINGULO_COEF 100

//#DEFINE MAX_STORED_ENERGY (held_plasma.toxins * held_plasma.toxins * SPECIFIC_HEAT_TOXIN)

/obj/effect/effect/rust_em_field
	name = "EM Field"
	desc = "A coruscating, barely visible field of energy. It is shaped like a slightly flattened torus."
	icon = 'code/modules/power/rust/rust.dmi'
	icon_state = "emfield_s1"
	alpha = 50

	var/size = 1			//diameter in tiles
	var/turfs_covered = 0	//tiles covered

	var/obj/machinery/power/rust_core/owned_core
	var/list/dormant_reactant_quantities = new

	layer = 2.9

	var/energy = 0
	var/mega_energy = 0
	var/radiation = 0
	var/frequency = 1
	var/field_strength = 0.01						//in teslas, max is 50T

	var/datum/gas_mixture/held_plasma = new
	var/list/particle_catchers = new

	var/emp_overload = 0

/obj/effect/effect/rust_em_field/New(loc, var/obj/machinery/power/rust_core/new_owned_core)
	..()
	owned_core = new_owned_core

	if(!owned_core)
		qdel(src)

	//create the gimmicky things to handle field collisions
	var/obj/effect/effect/rust_particle_catcher/catcher

	catcher = new (locate(src.x-3,src.y-3,src.z))
	catcher.parent = src
	catcher.SetSize(7)
	particle_catchers += catcher
	catcher = new (locate(src.x-2,src.y-2,src.z))
	catcher.parent = src
	catcher.SetSize(5)
	particle_catchers += catcher
	catcher = new (locate(src.x-1,src.y-1,src.z))
	catcher.parent = src
	catcher.SetSize(3)
	particle_catchers += catcher

	catcher = new (locate(src.x,src.y,src.z))	//Center
	catcher.parent = src
	catcher.SetSize(1)
	particle_catchers += catcher

	catcher = new (locate(src.x+1,src.y+1,src.z))
	catcher.parent = src
	catcher.SetSize(3)
	particle_catchers += catcher
	catcher = new (locate(src.x+2,src.y+2,src.z))
	catcher.parent = src
	catcher.SetSize(5)
	particle_catchers += catcher
	catcher = new (locate(src.x+3,src.y+3,src.z))
	catcher.parent = src
	catcher.SetSize(7)
	particle_catchers += catcher

	//init values
	//var/major_radius = field_strength * 0.07// max = 3.5
	//var/minor_radius = field_strength * 0.068// max = 3.4
	turfs_covered = 0.01//approximately precalculated
	SSobj.processing |= src

/obj/effect/effect/rust_em_field/process()
	//make sure the field generator is still intact
	if(!owned_core)
		qdel(src)

	//handle radiation
	if(radiation)
		pulse()

	//update values
	var/transfer_ratio = field_strength * 0.02			//higher field strength will result in faster plasma aggregation
	var/major_radius = field_strength * 0.07			// max = 3.5
	var/minor_radius = field_strength * 0.068			// max = 3.4
	turfs_covered = PI * major_radius * minor_radius * MAGIC_COEF * transfer_ratio	//strange formula...

	//add plasma from the surrounding environment
	var/datum/gas_mixture/environment = loc.return_air()

	//hack in some stuff to remove plasma from the air because SCIENCE
	//the amount of plasma pulled in each update is relative to the field strength, with 50T (max field strength) = 100% of area covered by the field
	//at minimum strength, 0.25% of the field volume is pulled in per update (?)
	//have a max of 1000 moles suspended
	if(held_plasma.phoron < field_strength * 20)		//THIS CAN BE SLOOOOOW (and don't working)
		var/moles_covered = environment.total_moles() * turfs_covered
//		to_chat(world, "<span class='notice'>moles_covered: [moles_covered]</span>")
		//
		var/datum/gas_mixture/gas_covered = environment.remove(moles_covered)
		var/datum/gas_mixture/plasma_captured = new /datum/gas_mixture()
		//
		plasma_captured.phoron = round(gas_covered.phoron * transfer_ratio)
//		to_chat(world, "<span class='warning'>[plasma_captured.toxins] moles of plasma captured</span>")
		plasma_captured.temperature = gas_covered.temperature
		plasma_captured.update_values()
		//
		gas_covered.phoron -= plasma_captured.phoron
		gas_covered.update_values()
		//
		held_plasma.check_then_merge(plasma_captured)
		//
		environment.check_then_merge(gas_covered)

	//let the particles inside the field react
	React()

	//change held plasma temp according to energy levels
	//SPECIFIC_HEAT_TOXIN
	if(mega_energy)
		if(held_plasma.phoron > 0)
			var/heat_capacity = held_plasma.heat_capacity()//200 * number of plasma moles
			if(heat_capacity > 0.0003) //MINIMUM_HEAT_CAPACITY
				held_plasma.temperature = 1 + (mega_energy * 35000)/heat_capacity

			//lose a random amount of plasma back into the air, increased by the field strength (want to switch this over to frequency eventually)
			var/loss_ratio = Clamp(rand(0, 2.5 / field_strength), 0, 0.75)
	//		to_chat(world, "lost [loss_ratio*100]% of held plasma")
			//
			var/datum/gas_mixture/plasma_lost = new
			plasma_lost.temperature = held_plasma.temperature
			//
			plasma_lost.phoron = held_plasma.phoron * loss_ratio
			held_plasma.phoron -= held_plasma.phoron * loss_ratio
			//
			environment.check_then_merge(plasma_lost)
			radiation += loss_ratio * mega_energy * 0.1
			mega_energy -= loss_ratio * mega_energy * 0.1
		else
			held_plasma.phoron = 0

	//handle some reactants formatting
	for(var/reactant in dormant_reactant_quantities)
		var/amount = dormant_reactant_quantities[reactant]
		if(amount < 1)
			dormant_reactant_quantities.Remove(reactant)
		else if(amount >= 1000000)
			var/radiate = rand(amount * 0.25, amount * 0.75)
			dormant_reactant_quantities[reactant] -= radiate
			radiation += radiate

	return 1

/obj/effect/effect/rust_em_field/proc/pulse()
	for(var/obj/machinery/power/rad_collector/R in rad_collectors)
		if(get_dist(R, src) <= 8) // Better than using orange() every process
			R.receive_pulse(radiation * SINGULO_COEF) //this is not singulo - we need increase output

	//and humans... uhm... Maybe, can be slow
	for(var/mob/living/l in range(8, src)) //USE ANOTHER FORMULA (or not...)
		l.apply_effect(radiation, IRRADIATE)

	return

/obj/effect/effect/rust_em_field/proc/ChangeFieldStrength(var/new_strength)
	var/calc_size = 1
	emp_overload = 0
	if(new_strength <= 50)
		calc_size = 1
	else if(new_strength <= 200)
		calc_size = 3
	else if(new_strength <= 500)
		calc_size = 5
	else
		calc_size = 7
		if(new_strength > 900)
			emp_overload = 1
	//
	field_strength = new_strength
	change_size(calc_size)

/obj/effect/effect/rust_em_field/proc/ChangeFieldFrequency(var/new_frequency)
	frequency = new_frequency

/obj/effect/effect/rust_em_field/proc/AddEnergy(var/a_energy, var/a_mega_energy, var/a_frequency)
	var/energy_loss_ratio = 0
	if(a_frequency != src.frequency)
		energy_loss_ratio = Clamp(1 / abs(a_frequency - src.frequency), 0.2, 1)
	energy += a_energy * energy_loss_ratio
	mega_energy += a_mega_energy * energy_loss_ratio

	while(energy > 100000)
		energy -= 100000
		mega_energy += 0.1

/obj/effect/effect/rust_em_field/proc/AddParticles(var/name, var/quantity = 1)
	if(name in dormant_reactant_quantities)
		dormant_reactant_quantities[name] += quantity
	else if(name != "proton" && name != "electron" && name != "neutron")
		dormant_reactant_quantities += name
		dormant_reactant_quantities[name] = quantity

/obj/effect/effect/rust_em_field/proc/RadiateAll(var/ratio_lost = 1)
	for(var/particle in dormant_reactant_quantities)
		radiation += dormant_reactant_quantities[particle]
		dormant_reactant_quantities.Remove(particle)
	radiation += mega_energy
	mega_energy = 0

	//lose all held plasma back into the air
	var/datum/gas_mixture/environment = loc.return_air()
	environment.merge(held_plasma)

/obj/effect/effect/rust_em_field/proc/change_size(var/newsize = 1)
	//
	var/changed = 0
	switch(newsize)
		if(1)
			size = 1
			icon = 'code/modules/power/rust/rust.dmi'
			icon_state = "emfield_s1"
			pixel_x = 0
			pixel_y = 0
			//
			changed = 1
		if(3)
			size = 3
			icon = 'icons/effects/96x96.dmi'
			icon_state = "emfield_s3"
			pixel_x = -32 * PIXEL_MULTIPLIER
			pixel_y = -32 * PIXEL_MULTIPLIER
			//
			changed = 3
		if(5)
			size = 5
			icon = 'icons/effects/160x160.dmi'
			icon_state = "emfield_s5"
			pixel_x = -64 * PIXEL_MULTIPLIER
			pixel_y = -64 * PIXEL_MULTIPLIER
			//
			changed = 5
		if(7)
			size = 7
			icon = 'icons/effects/224x224.dmi'
			icon_state = "emfield_s7"
			pixel_x = -96 * PIXEL_MULTIPLIER
			pixel_y = -96 * PIXEL_MULTIPLIER
			//
			changed = 7

	for(var/obj/effect/effect/rust_particle_catcher/catcher in particle_catchers)
		catcher.UpdateSize()
	return changed

//the !!fun!! part
/obj/effect/effect/rust_em_field/proc/React()
	//loop through the reactions
	if(!fusion_reactions.len)
		return
	if(dormant_reactant_quantities.len)
		var/p_reactant
		var/s_reactant
		for(var/datum/fusion_reaction/cur_reaction in fusion_reactions)
			p_reactant = cur_reaction.primary_reactant
			s_reactant = cur_reaction.secondary_reactant
			if(!dormant_reactant_quantities.Find(p_reactant) || !dormant_reactant_quantities.Find(s_reactant))
				continue
			var/react_amount  = 0
			if(p_reactant != s_reactant)
				react_amount = min(dormant_reactant_quantities[p_reactant], dormant_reactant_quantities[s_reactant], 1)
			else
				react_amount = min(dormant_reactant_quantities[p_reactant] * 0.5, 1)
			if(!react_amount || ((cur_reaction.energy_consumption * react_amount) > mega_energy))
				continue
			mega_energy += (cur_reaction.energy_production - cur_reaction.energy_consumption) * react_amount
			radiation += cur_reaction.radiation * react_amount
			dormant_reactant_quantities[p_reactant] -= react_amount
			if(dormant_reactant_quantities[p_reactant] < MINIMUM_REACTANT_AMOUNT)
				dormant_reactant_quantities -= p_reactant
			dormant_reactant_quantities[s_reactant] -= react_amount
			if(dormant_reactant_quantities[s_reactant] < MINIMUM_REACTANT_AMOUNT)
				dormant_reactant_quantities -= s_reactant
			if(cur_reaction.products.len)
				for(var/o_reactant in cur_reaction.products)
					if(!dormant_reactant_quantities.Find(o_reactant))
						dormant_reactant_quantities += o_reactant
						dormant_reactant_quantities[o_reactant] = react_amount * cur_reaction.products[o_reactant]
					else
						dormant_reactant_quantities[o_reactant] += react_amount * cur_reaction.products[o_reactant]
	return

/obj/effect/effect/rust_em_field/Destroy()
	//radiate everything in one giant burst
	for(var/obj/effect/effect/rust_particle_catcher/catcher in particle_catchers)
		qdel(catcher)

	owned_core.owned_field = null
	owned_core = null

	RadiateAll()

	SSobj.processing.Remove(src)
	. = ..()

/obj/effect/effect/rust_em_field/bullet_act(var/obj/item/projectile/Proj)
	if(Proj.flag == "laser")
		AddEnergy(Proj.damage * 20, 0, 1)
		update_icon()
	return 0

#undef SINGULO_COEF
#undef MINIMUM_REACTANT_AMOUNT
#undef MAGIC_COEF
#undef PIXEL_MULTIPLIER