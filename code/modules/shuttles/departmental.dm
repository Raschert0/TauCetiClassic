/obj/machinery/computer/shuttle_control/multi/mine_sci
	name = "Mine-Sci shuttle console"
	shuttle_tag = "Mine-Sci shuttle"
	req_access = list()

/obj/machinery/computer/shuttle_control/multi/mine_sci/cool_sprite
	icon = 'code/modules/locations/shuttles/computer_shuttle_mining.dmi'
	icon_state = "shuttle"

/datum/shuttle/autodock/multi/mine_sci
	name = "Mine-Sci shuttle"
	warmup_time = 10
	destination_tags = list(
		"nav_mine_sci_station",
		"nav_mine_sci_mining",
		"nav_mine_sci_research"
		)
	shuttle_area = /area/shuttle/mine_sci
	dock_target = "mine_sci_shuttle"
	current_location = "nav_mine_sci_station"


/obj/effect/shuttle_landmark/mine_sci/station
	name = "Station"
	landmark_tag = "nav_mine_sci_station"
	docking_controller = "mine_sci_station"

/obj/effect/shuttle_landmark/mine_sci/mining
	name = "Mining Outpost"
	landmark_tag = "nav_mine_sci_mining"
	docking_controller = "mine_sci_mining"

/obj/effect/shuttle_landmark/mine_sci/research
	name = "Research Outpost"
	landmark_tag = "nav_mine_sci_research"
	docking_controller = "mine_sci_research"
