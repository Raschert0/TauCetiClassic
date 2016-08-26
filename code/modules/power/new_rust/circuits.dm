//////////////////////////////////////
// RUST Core Control computer

/obj/item/weapon/circuitboard/rust_core_control
	name = "Circuit board (R-UST Mk. 7 core controller)"
	build_path = "/obj/machinery/computer/rust_core_control"
	origin_tech = "programming=4;engineering=4"

//////////////////////////////////////
// RUST Core Monitor computer

/obj/item/weapon/circuitboard/rust_core_monitor
	name = "Circuit board (R-UST Mk. 7 core monitor)"
	build_path = "/obj/machinery/computer/rust_core_monitor"
	origin_tech = "programming=4;engineering=4"

//////////////////////////////////////
// RUST Fuel Control computer

/obj/item/weapon/circuitboard/rust_fuel_control
	name = "Circuit board (R-UST Mk. 7 fuel controller)"
	build_path = "/obj/machinery/computer/rust_fuel_control"
	origin_tech = "programming=4;engineering=4"

//////////////////////////////////////
// RUST Fuel Port board

/obj/item/weapon/module/rust_fuel_port
	name = "Internal circuitry (R-UST Mk. 7 fuel port)"
	icon_state = "card_mod"
	origin_tech = "engineering=4;materials=5"

//////////////////////////////////////
// RUST Fuel Compressor board

/obj/item/weapon/module/rust_fuel_compressor
	name = "Internal circuitry (R-UST Mk. 7 fuel compressor)"
	icon_state = "card_mod"
	origin_tech = "materials=6;plasmatech=4"

//////////////////////////////////////
// RUST Tokamak Core board

/obj/item/weapon/circuitboard/rust_core
	name = "Internal circuitry (R-UST Mk. 7 tokamak core)"
	build_path = "/obj/machinery/power/rust_core"
	board_type = "machine"
	origin_tech = "bluespace=3;plasmatech=4;magnets=5;powerstorage=6"
	req_components = list(
							"/obj/item/weapon/stock_parts/manipulator" = 2,
							"/obj/item/weapon/stock_parts/micro_laser" = 1,
							"/obj/item/weapon/stock_parts/subspace/crystal" = 1,
							"/obj/item/weapon/stock_parts/console_screen" = 1,
							"/obj/item/stack/cable_coil" = 5)

//////////////////////////////////////
// RUST Fuel Injector board

/obj/item/weapon/circuitboard/rust_injector
	name = "Internal circuitry (R-UST Mk. 7 fuel injector)"
	build_path = "/obj/machinery/power/rust_fuel_injector"
	board_type = "machine"
	origin_tech = "powerstorage=3;engineering=4;plasmatech=4;materials=6"
	req_components = list(
							"/obj/item/weapon/stock_parts/manipulator" = 2,
							"/obj/item/weapon/stock_parts/scanning_module" = 1,
							"/obj/item/weapon/stock_parts/matter_bin" = 1,
							"/obj/item/weapon/stock_parts/console_screen" = 1,
							"/obj/item/stack/cable_coil" = 5)

/obj/item/weapon/circuitboard/rust_gyrotron
	name = "Internal circuitry (R-UST Mk. 7 gyrotron)"
	build_path = "/obj/machinery/power/gyrotron"
	board_type = "machine"
	origin_tech = "materials=4;engineering=4;magnets=5;powerstorage=5"
	req_components = list(
							"/obj/item/weapon/stock_parts/micro_laser" = 3,
							"/obj/item/stack/cable_coil" = 5)

//Gyrotron controller board.
/obj/item/weapon/circuitboard/rust_gyrotron_control
	name = "Circuit board (R-UST Mk. 7 gyrotron controller)"
	build_path = "/obj/machinery/computer/rust_gyrotron_controller"
	origin_tech = "programming=4;engineering=4"
