#define DOCK_ATTEMPT_TIMEOUT 200	//how long in ticks we wait before assuming the docking controller is broken or blown up.

/datum/shuttle/autodock
	var/in_use = null	//tells the controller whether this shuttle needs processing, also attempts to prevent double-use
	var/last_dock_attempt_time = 0
	var/move_cooldown = 0
	var/next_jump_time = 0
	var/current_dock_target
	//ID of the controller on the shuttle
	var/dock_target = null
	var/datum/computer/file/embedded_program/docking/active_docking_controller


/datum/shuttle/autodock/New(_name, obj/effect/shuttle_landmark/start_waypoint)
	..()

	//Initial dock
	active_docking_controller = current_location.docking_controller
	current_dock_target = get_docking_target(current_location)
	dock()

/datum/shuttle/autodock/Destroy()
	active_docking_controller = null

	return ..()

/datum/shuttle/autodock/pre_move(obj/effect/shuttle_landmark/destination)
	force_undock() //bye!
	..()

/datum/shuttle/autodock/proc/get_docking_target(var/obj/effect/shuttle_landmark/location)
	if(location && location.special_dock_targets)
		if(location.special_dock_targets[name])
			return location.special_dock_targets[name]
	return dock_target

/*
	Docking stuff
*/
/datum/shuttle/autodock/proc/dock()
	if(active_docking_controller)
		active_docking_controller.initiate_docking(current_dock_target)
		last_dock_attempt_time = world.time

/datum/shuttle/autodock/proc/undock()
	if(active_docking_controller)
		active_docking_controller.initiate_undocking()

/datum/shuttle/autodock/proc/force_undock()
	if(active_docking_controller)
		active_docking_controller.force_undock()

/datum/shuttle/autodock/proc/check_docked()
	if(active_docking_controller)
		return active_docking_controller.docked()
	return TRUE

/datum/shuttle/autodock/proc/check_undocked()
	if(active_docking_controller)
		return active_docking_controller.can_launch()
	return TRUE

/*
	Please ensure that jump() are only called from here. This applies to subtypes as well.
	Doing so will ensure that multiple jumps cannot be initiated in parallel.
*/
/datum/shuttle/autodock/process()
	switch(process_state)
		if (WAIT_LAUNCH)
			if(check_undocked())
				//*** ready to go
				process_launch()

		if (FORCE_LAUNCH)
			process_launch()

		if (WAIT_ARRIVE)
			if (moving_status == SHUTTLE_IDLE)
				//*** we made it to the destination, update stuff
				process_arrived()
				process_state = WAIT_FINISH

		if (WAIT_FINISH)
			if (world.time > last_dock_attempt_time + DOCK_ATTEMPT_TIMEOUT || check_docked())
				//*** all done here
				process_state = IDLE_STATE
				arrived()

//not to be confused with the arrived() proc
/datum/shuttle/autodock/proc/process_arrived()
	active_docking_controller = next_location.docking_controller
	current_dock_target = get_docking_target(next_location)
	dock()

	next_location = null
	in_use = null	//release lock


/datum/shuttle/autodock/proc/process_launch()
	if(!next_location.is_valid(src))
		process_state = IDLE_STATE
		in_use = null
		return
	if(move_time && landmark_transition)
		. = jump(SHUTTLE_JUMP_LONG)
	else
		. = jump(SHUTTLE_JUMP_SHORT)
	process_state = WAIT_ARRIVE

/*
	Guards
*/
/datum/shuttle/autodock/proc/can_launch()
	return (next_location && moving_status == SHUTTLE_IDLE && !in_use && world.time > next_jump_time)

/datum/shuttle/autodock/proc/can_force()
	return (next_location && moving_status == SHUTTLE_IDLE && process_state == WAIT_LAUNCH && world.time > next_jump_time)

/datum/shuttle/autodock/proc/can_cancel()
	return (moving_status == SHUTTLE_WARMUP || process_state == WAIT_LAUNCH || process_state == FORCE_LAUNCH)

/*
	"Public" procs
*/
/datum/shuttle/autodock/proc/launch(user)
	if(!can_launch())
		return

	in_use = user	//obtain an exclusive lock on the shuttle

	process_state = WAIT_LAUNCH
	launch_initiated()
	undock()

/datum/shuttle/autodock/proc/force_launch(user)
	if(!can_force())
		return

	in_use = user	//obtain an exclusive lock on the shuttle

	process_state = FORCE_LAUNCH
	launch_initiated()

/datum/shuttle/autodock/proc/launch_initiated()
	return	//Nothing. For use in subclasses

/datum/shuttle/autodock/proc/cancel_launch(user)
	if(!can_cancel())
		return

	moving_status = SHUTTLE_IDLE
	process_state = WAIT_FINISH
	in_use = null

	//whatever we were doing with docking: stop it, then redock
	force_undock()
	addtimer(CALLBACK(src, .proc/dock), 1 SECOND)

//returns 1 if the shuttle is getting ready to move, but is not in transit yet
/datum/shuttle/autodock/proc/is_launching()
	return (moving_status == SHUTTLE_WARMUP || process_state == WAIT_LAUNCH || process_state == FORCE_LAUNCH)

//This gets called when the shuttle finishes arriving at it's destination
//This can be used by subtypes to do things when the shuttle arrives.
//Note that this is called when the shuttle leaves the WAIT_FINISHED state, the proc name is a little misleading
/datum/shuttle/autodock/proc/arrived()
	next_jump_time = world.time + move_cooldown * 10
