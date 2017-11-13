/obj/machinery/embedded_controller
	var/datum/computer/file/embedded_program/program

	name = "Embedded Controller"
	anchored = 1

	var/on = 1

/obj/machinery/embedded_controller/Destroy()
	if(program)
		qdel(program)
	return ..()

/obj/machinery/embedded_controller/proc/post_signal(datum/signal/signal, comm_line)
	return 0

/obj/machinery/embedded_controller/receive_signal(datum/signal/signal, receive_method, receive_param)
	if(!signal || signal.encryption) return

	if(program)
		program.receive_signal(signal, receive_method, receive_param)
			//spawn(5) program.process() //no, program.process sends some signals and machines respond and we here again and we lag -rastaf0

/obj/machinery/embedded_controller/process()
	if(program)
		program.process()

	update_icon()
	src.updateDialog()

/obj/machinery/embedded_controller/attack_ai(mob/user)
	src.ui_interact(user)

/obj/machinery/embedded_controller/attack_paw(mob/user)
	to_chat(user, "You do not have the dexterity to use this.")
	return

/obj/machinery/embedded_controller/attack_hand(mob/user)
	src.ui_interact(user)

/obj/machinery/embedded_controller/ui_interact()
	return

/obj/machinery/embedded_controller/radio
	icon = 'icons/obj/airlock_machines.dmi'
	icon_state = "airlock_control_standby"
	power_channel = ENVIRON
	density = 0

	// Setup parameters only
	var/id_tag

	frequency = 1379

	unacidable = 1

/obj/machinery/embedded_controller/radio/atom_init()
	. = ..()
	set_frequency(frequency)

/obj/machinery/embedded_controller/radio/Destroy()
	if(radio_controller)
		radio_controller.remove_object(src,frequency)
	return ..()

/obj/machinery/embedded_controller/radio/update_icon()
	if(on && program)
		if(program.memory["processing"])
			icon_state = "airlock_control_process"
		else
			icon_state = "airlock_control_standby"
	else
		icon_state = "airlock_control_off"

/obj/machinery/embedded_controller/radio/post_signal(datum/signal/signal)
	signal.transmission_method = TRANSMISSION_RADIO
	if(radio_connection)
		return radio_connection.post_signal(src, signal)
	else
		qdel(signal)

/obj/machinery/embedded_controller/radio/set_frequency(new_frequency)
	radio_controller.remove_object(src, frequency)
	frequency = new_frequency
	if(frequency)
		radio_connection = radio_controller.add_object(src, frequency)
