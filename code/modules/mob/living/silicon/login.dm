/mob/living/silicon/Login()
	sleeping = 0
	if(mind && ticker && ticker.mode)
		ticker.mode.remove_cultist(mind, 0)
		ticker.mode.remove_revolutionary(mind, 0)
		ticker.mode.remove_gangster(mind, 0)
	..()