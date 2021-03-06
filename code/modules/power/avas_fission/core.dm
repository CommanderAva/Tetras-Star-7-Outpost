/obj/machinery/power/fission_reactor/
	name = "nuclear reactor"
	desc = "Core of the nuclear reactor. Contact admin or developer if you see this"
	icon = 'icons/obj/machines/power/fission.dmi'
	icon_state = "core"
	density = 1
	use_power = 1
	idle_power_usage = 50
	active_power_usage = 200

	var/radiation = 15
	var/core_max_temp = 1000
	var/initial_temperature = 200
	var/light_e = 0
	var/rod_quality = 0
	var/control_rod_position = 0
	var/circular_system_quality = 0
	var/shielding_max_temp = 0
	var/turbine_quality = 0
	var/fail_percentage = 0
	var/divide_k = 0
	var/list/fuel_rods = null
	var/reactor_open = 0
	var/output = 0
	var/power_output = 0
	var/temperature = 0
	var/temperature_interchange = 0
	var/max_temperature = 0
	var/power_produced = 0
	var/fission = 0
	var/minwork = 0
	var/maxwork = 100
	var/fission_check = 0
	var/critical_temp = 0
	var/explosion_power = 3
	var/nu_alarm_time = 280
	var/delay_time = 0
	var/delay_time2 = 0
/obj/machinery/power/fission_reactor/habar/New()
	..()

	component_parts = list()
	component_parts += new /obj/item/weapon/stock_parts/fission/control_rod/graphite(src)
	component_parts += new /obj/item/weapon/stock_parts/fission/circular_system/maverick(src)
	component_parts += new /obj/item/weapon/stock_parts/fission/shielding/plumbum(src)
	component_parts += new /obj/item/weapon/stock_parts/fission/turbine/chorus(src)
	component_parts += new /obj/item/weapon/stock_parts/fission/safety_system/nato(src)
	component_parts += new /obj/item/weapon/stock_parts/fission/circular_system/maverick(src)
	fuel_rods = list()
	fuel_rods += new /obj/item/weapon/fuel_rod/uranium238(src)
	fuel_rods += new /obj/item/weapon/fuel_rod/uranium238(src)
	fuel_rods += new /obj/item/weapon/fuel_rod/uranium238(src)
	fuel_rods += new /obj/item/weapon/fuel_rod/uranium238(src)
	fuel_rods += new /obj/item/weapon/fuel_rod/uranium238(src)
	fuel_rods += new /obj/item/weapon/fuel_rod/uranium238(src)
	fuel_rods += new /obj/item/weapon/fuel_rod/uranium238(src)
	fuel_rods += new /obj/item/weapon/fuel_rod/uranium238(src)
	fuel_rods += new /obj/item/weapon/fuel_rod/uranium238(src)
	fuel_rods += new /obj/item/weapon/fuel_rod/uranium238(src)

	RefreshParts()


/*
/obj/machinery/power/fission_reactor/New()
	..()

	fuel_rods = list()
	fuel_rods += new /obj/item/weapon/fuel_rod/uranium238(src)
*/

/obj/machinery/power/fission_reactor/attack_ai(mob/user)
	attack_hand(user)

/obj/machinery/power/fission_reactor/Initialize()
	. = ..()
	connect_to_network()
	check_parts()

/obj/machinery/power/fission_reactor/proc/check_parts()
	for(var/obj/item/weapon/stock_parts/fission/P in component_parts)
		for(var/obj/item/weapon/stock_parts/fission/shielding/I in component_parts)
			src.shielding_max_temp = I.shielding_max_temp
		for(var/obj/item/weapon/stock_parts/fission/turbine/I in component_parts)
			src.turbine_quality = I.turbine_quality
		for(var/obj/item/weapon/stock_parts/fission/circular_system/I in component_parts)
			src.circular_system_quality = I.circular_system_quality
		for(var/obj/item/weapon/stock_parts/fission/control_rod/I in component_parts)
			src.rod_quality = I.rod_quality
		for(var/obj/item/weapon/stock_parts/fission/safety_system/I in component_parts)
			src.fail_percentage = I.fail_percentage

	max_temperature = core_max_temp + shielding_max_temp
	temperature_interchange = circular_system_quality + turbine_quality
	critical_temp = max_temperature * 0.33
	for(var/obj/item/weapon/fuel_rod/I in fuel_rods)
		src.divide_k = I.divide_k

/obj/machinery/power/fission_reactor/attackby(var/obj/item/weapon/fuel_rod/A, mob/user as mob)
	if (src.reactor_open == 0)
		to_chat(user, "<span class='notice'>You'll have to open the \"[src]\" first.</span>")
		return
	else if(!typesof(A, /obj/item/weapon/fuel_rod) && src.reactor_open == 1)
		to_chat(user, "<span class='notice'>You can't put that into reactor fuel slot!.</span>")
		return
	else
		if(A.fuel_life != 0)
			user.drop_item()
			A.forceMove(src)
			src.fuel_rods += A
			to_chat(user, "<span class='notice'>You add \"[A]\" into \the [src].</span>")

			return
		else if (fuel_rods.len == 10)
			to_chat(user, "<span class='notice'>All slots for fuel rods are full.</span>")
			return
		else if (A.fuel_life != 0)
			to_chat(user, "<span class='notice'>This \"[A]\" is depleted.</span>")
			return

/obj/machinery/power/fission_reactor/proc/check_reaction()
	if(!fission)
		fission_check = "Dead"
		update_icon()
	if(fission)
		fission_check = "Active"
		update_icon()

/obj/machinery/power/fission_reactor/proc/check_integrity()
	if(temperature - max_temperature > 0 && delay_time == 0)
		GLOB.global_announcer.autosay("WARNING: [src] MELTDOWN IMMENENT!", "Nuclear Reactor Monitor")
		delay_time += 10
	else if (temperature - max_temperature > 0 && delay_time > 0)
		delay_time -= 1
	else if(temperature - max_temperature + critical_temp > 0 && delay_time2 == 0)
		command_announcement.Announce("[src] meltdown . All personell evacuate to nearest bunker", "Nuclear Supervision Monitor")
		to_world(sound('sound/ambience/nuclear_warning.ogg', repeat = 0, wait = 0, volume = 50, channel = 3))
		spawn(nu_alarm_time)
			explosion(get_turf(src), 10, 8, 22)
			radiation_repository.flat_radiate(get_turf(src), 50, 150, TRUE)
			qdel(src)

	else if (temperature - max_temperature + critical_temp > 0 && delay_time2 > 0)
		delay_time2 -= 1
	else
		return

/obj/machinery/power/fission_reactor/proc/radiate()
	var/radiation = 0
	if (src.temperature > max_temperature)
		radiation = radiation * ((src.temperature - max_temperature)*0.5)
	else if (src.temperature > shielding_max_temp)
		radiation = round(((src.temperature - shielding_max_temp)/50))
	radiation_repository.radiate(src, radiation) //Always radiate at max, so a decent dose of radiation is applied
	return


/obj/machinery/power/fission_reactor/Process(mob/user as mob)
	check_parts()
	radiate()
	check_reaction()
	update_icon()
	check_integrity()
	if(temperature > 0)
		temperature -= 10
	if(temperature < 0)
		temperature = 0
	if(reactor_open == 1)
		to_chat(user, "<span class='notice'>Reactor chamber opened. Close it before start.</span>")
		return
	if(control_rod_position == 0)
		fission = 0
		update_icon()
		return
	for(var/obj/item/weapon/fuel_rod/I in src.fuel_rods)
		I.divide_k = src.divide_k
		if(I.fuel_life == 0)
			fission = 0
			return
	if(fission && fuel_rods.len > 0)
		temperature = temperature * (divide_k * (control_rod_position * 0.01))
		power_produced = temperature * temperature_interchange
		add_avail(power_produced * 3) //Don't ask me why the fuck i did it. BALANCE!

		for(var/obj/item/weapon/fuel_rod/I in src.fuel_rods)
			I.fuel_life -= 1



/obj/machinery/power/fission_reactor/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	// this is the data which will be sent to the ui

	var/data[0]
	data["totalOutput"] = power_produced
	data["totalTemperature"] = temperature
	data["maxTotalTemperature"] = max_temperature
	data["controlRodPosition"] = control_rod_position
	data["fuelRods"] = fuel_rods
	data["divideCoefficient"] = divide_k
	data["interchangeCoefficient"] = temperature_interchange
	data["fission"] = fission_check
	data["minwork"] = minwork
	data["maxwork"] = maxwork
	data["setControlRod"] = round(control_rod_position)




	// update the ui if it exists, returns null if no ui is passed/found
	ui = GLOB.nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		// the ui does not exist, so we'll create a new() one
		// for a list of parameters and their descriptions see the code docs in \code\modules\nano\nanoui.dm
		ui = new(user, src, ui_key, "fission_reactor.tmpl", "Fission Reactor", 700, 700)
		// when the ui is first opened this is the data it will use
		ui.set_initial_data(data)
		// open the new ui window
		ui.open()
		// auto update every Master Controller tick
		ui.set_auto_update(1)


/obj/machinery/power/fission_reactor/Topic(href, href_list)
	if(..())
		return 1

	if(href_list["startFission"])
		fission = 1
		update_icon()
		temperature += initial_temperature


	if(href_list["stopFission"])
		control_rod_position = 0
		update_icon()

	if (href_list["rod_adj"])
		var/diff = text2num(href_list["rod_adj"])
		control_rod_position += diff


/obj/machinery/power/fission_reactor/attack_hand(mob/user)
	if(fuel_rods && reactor_open && (!issilicon(user)))
		if(temperature > 100)
			to_chat(user, "You think about removing the fuel rod, but then reconsider since it's too hot and you don't want to burn your hand to ashes.")
			return
		else
			for(var/obj/item/weapon/fuel_rod/I in src.fuel_rods)
				user.put_in_hands(I)
				check_parts()
				I.add_fingerprint(user)
				I.update_icon()
				src.fuel_rods -= I
				user.visible_message("<span class='warning'>[user.name] removes the fuel rod from [src.name]!</span>",\
								 "<span class='notice'>You remove the fuel rod.</span>")

				return
	if(!reactor_open)
		check_parts()
		ui_interact(user)

/obj/machinery/power/fission_reactor/verb/reactor_chamber(mob/user as mob)
	set category = "Object"
	set name = "Open/Close reactor chamber"
	set src in view(1)

	if(reactor_open)
		to_chat(user, "<span class='notice'>You've closed the [src] chamber</span>")
		reactor_open = 0
		flick("habar_close_anim", src)
		check_parts()
		connect_to_network()
		update_icon()
		return
	if(!reactor_open && fission)
		to_chat(user, "<span class='notice'>You are no idiot to open the [src] chamber while it works</span>")
		return
	if(!reactor_open)
		to_chat(user, "<span class='notice'>You've opened the [src] chamber</span>")
		reactor_open = 1
		flick("habar_open_anim", src)
		check_parts()
		disconnect_from_network()
		update_icon()
		return

/obj/machinery/power/fission_reactor/habar
	name = "Habar X-1 Nuclear Reactor"
	desc = "Habar X-1 Nuclear Reactor, old but trustworhy, don't expect a lot from it though."
	icon = 'icons/obj/machines/power/fission.dmi'
	icon_state = "habar"
	core_max_temp = 1500

/obj/machinery/power/fission_reactor/habar/update_icon()
	if(!fission && !reactor_open)
		icon_state = "habar"
	else if(!fission && reactor_open)
		icon_state = "habar_open"
	else if(fission)
		icon_state = "habar_work"


