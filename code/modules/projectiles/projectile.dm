/*
#define BRUTE "brute"
#define BURN "burn"
#define TOX "tox"
#define OXY "oxy"
#define CLONE "clone"

#define ADD "add"
#define SET "set"
*/
/obj/item/projectile
	name = "projectile"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "bullet"
	density = TRUE
	unacidable = TRUE
	anchored = TRUE //There's a reason this is here, Mport. God fucking damn it -Agouri. Find&Fix by Pete. The reason this is here is to stop the curving of emitter shots.
	pass_flags = PASSTABLE
	mouse_opacity = 0
	var/bumped = FALSE		//Prevents it from hitting more than one guy at once
	var/hitsound_wall = "ricochet"
	var/list/mob_hit_sound = list('sound/effects/gore/bullethit2.ogg', 'sound/effects/gore/bullethit3.ogg') //Sound it makes when it hits a mob. It's a list so you can put multiple hit sounds there.
	var/def_zone = ""	//Aiming at
	var/mob/firer = null//Who shot it
	var/silenced = FALSE	//Attack message
	var/yo = null
	var/xo = null
	var/current = null
	var/shot_from = "" // name of the object which shot us
	var/atom/original = null // the target clicked (not necessarily where the projectile is headed). Should probably be renamed to 'target' or something.
	var/turf/starting = null // the projectile's starting turf
	var/list/permutated = list() // we've passed through these atoms, don't try to hit them again

	var/p_x = 16
	var/p_y = 16 // the pixel location of the tile that the player clicked. Default is the center

	var/can_ricochet = FALSE // defines if projectile can or cannot ricochet.
	var/ricochet_id = 0 // if the projectile ricochets, it gets its unique id in order to process iteractions with adjacent walls correctly.

	var/list/damage_types = list(BRUTE = 10) //BRUTE, BURN, TOX, OXY, CLONE, HALLOSS -> int are the only things that should be in here
	var/nodamage = FALSE //Determines if the projectile will skip any damage inflictions
	var/taser_effect = FALSE //If set then the projectile will apply it's agony damage using stun_effect_act() to mobs it hits, and other damage will be ignored
	var/check_armour = ARMOR_BULLET //Defines what armor to use when it hits things. Full list could be found at defines\damage_organs.dm
	var/projectile_type = /obj/item/projectile
	var/penetrating = 0 //If greater than zero, the projectile will pass through dense objects as specified by on_penetrate()
	var/kill_count = 50 //This will de-increment every process(). When 0, it will delete the projectile.
	var/nocap_structures = FALSE // wether or not this projectile can circumvent the damage cap you can do to walls and doors in one hit. Also increases the structure damage done to walls by 300%
	//Effects
	var/stun = 0
	var/weaken = 0
	var/paralyze = 0
	var/irradiate = 0
	var/stutter = 0
	var/eyeblur = 0
	var/drowsy = 0
	var/agony = 0
	var/embed = 0 // whether or not the projectile can embed itself in the mob
	var/knockback = 0

	var/hitscan = FALSE		// whether the projectile should be hitscan
	var/step_delay = 1	// the delay between iterations if not a hitscan projectile

	// effect types to be used
	var/muzzle_type
	var/tracer_type
	var/impact_type
	var/luminosity_range
	var/luminosity_power
	var/luminosity_color
	var/luminosity_ttl
	var/obj/effect/attached_effect
	var/proj_sound

	var/proj_color //If defined, is used to change the muzzle, tracer, and impact icon colors through Blend()

	var/datum/plot_vector/trajectory	// used to plot the path of the projectile
	var/datum/vector_loc/location		// current location of the projectile in pixel space
	var/matrix/effect_transform			// matrix to rotate and scale projectile effects - putting it here so it doesn't
										//  have to be recreated multiple times

	// Ranged issue

	var/has_drop_off = FALSE

	var/speed_drop_off = 0 //How much we get slowed farther we go
	var/damage_drop_off = 0 //How much less damage we have the farther we go
	var/ap_drop_off = 0 //How much less AP we have the farther we go

	var/affective_damage_range = 50 //How far we can go before we start being negitively impacted, higher is a buffer
	var/affective_ap_range = 50 //How far we can go before we start being negitively impacted, higher is a buffer

	var/range_shot = 1 //How far we been shot so far. We start at 1 to prevent runtimes with deviding by 0

/obj/item/projectile/is_hot()
	if (damage_types[BURN])
		return damage_types[BURN] * heat

/obj/item/projectile/proc/get_total_damage()
	var/val = 0
	for(var/i in damage_types)
		val += damage_types[i]
	return val

/obj/item/projectile/proc/is_halloss()
	for(var/i in damage_types)
		if(i != HALLOSS)
			return FALSE
	return TRUE

/obj/item/projectile/multiply_projectile_damage(newmult)
	for(var/i in damage_types)
		damage_types[i] *= newmult

/obj/item/projectile/multiply_projectile_penetration(newmult)
	armor_penetration = initial(armor_penetration) * newmult

/obj/item/projectile/multiply_pierce_penetration(newmult)
	penetrating = initial(penetrating) + newmult

/obj/item/projectile/multiply_projectile_step_delay(newmult)
	if(!hitscan)
		step_delay = initial(step_delay) * newmult

/obj/item/projectile/multiply_projectile_agony(newmult)
	agony = initial(agony) * newmult

/obj/item/projectile/proc/adjust_damages(var/list/newdamages)
	if(!newdamages.len)
		return
	for(var/damage_type in newdamages)
		if(damage_type == IRRADIATE)
			irradiate += damage_type[IRRADIATE]
			continue
		damage_types[damage_type] += newdamages[damage_type]

/obj/item/projectile/proc/on_hit(atom/target, def_zone = null)
	if(!isliving(target))	return 0
	if(isanimal(target))	return 0
	var/mob/living/L = target
	L.apply_effects(stun, weaken, paralyze, irradiate, stutter, eyeblur, drowsy)
	return TRUE

// generate impact effect
/obj/item/projectile/proc/on_impact(atom/A)
	impact_effect(effect_transform)
	if(luminosity_ttl && attached_effect)
		spawn(luminosity_ttl)
		qdel(attached_effect)

	if(!ismob(A))
		playsound(src, hitsound_wall, 50, 1, -2)
	return

/obj/item/projectile/multiply_pierce_penetration(newmult)
	penetrating = initial(penetrating) + newmult

//Checks if the projectile is eligible for embedding. Not that it necessarily will.
/obj/item/projectile/proc/can_embed()
	//embed must be enabled and damage type must be brute
	if(!embed || damage_types[BRUTE] <= 0)
		return FALSE
	return TRUE

/obj/item/projectile/proc/get_structure_damage()
	return damage_types[BRUTE] + damage_types[BURN]

//return 1 if the projectile should be allowed to pass through after all, 0 if not.
/obj/item/projectile/proc/check_penetrate(atom/A)
	return TRUE

/obj/item/projectile/proc/check_fire(atom/target as mob, mob/living/user as mob)  //Checks if you can hit them or not.
	check_trajectory(target, user, pass_flags, flags)

//sets the click point of the projectile using mouse input params
/obj/item/projectile/proc/set_clickpoint(params)
	var/list/mouse_control = params2list(params)
	if(mouse_control["icon-x"])
		p_x = text2num(mouse_control["icon-x"])
	if(mouse_control["icon-y"])
		p_y = text2num(mouse_control["icon-y"])

//called to launch a projectile
/obj/item/projectile/proc/launch(atom/target, target_zone, x_offset=0, y_offset=0, angle_offset=0, proj_sound)
	var/turf/curloc = get_turf(src)
	var/turf/targloc = get_turf(target)
	if (!istype(targloc) || !istype(curloc))
		return TRUE

	if(targloc == curloc) //Shooting something in the same turf
		target.bullet_act(src, target_zone)
		on_impact(target)
		qdel(src)
		return FALSE

	if(proj_sound)
		playsound(proj_sound)

	original = target
	def_zone = target_zone

	spawn()
		setup_trajectory(curloc, targloc, x_offset, y_offset, angle_offset) //plot the initial trajectory
		Process()

	return FALSE

//called to launch a projectile from a gun
/obj/item/projectile/proc/launch_from_gun(atom/target, mob/user, obj/item/gun/launcher, target_zone, x_offset=0, y_offset=0, angle_offset)
	if(user == target) //Shooting yourself
		user.bullet_act(src, target_zone)
		qdel(src)
		return FALSE

	loc = get_turf(user)

	if(iscarbon(user))
		var/mob/living/carbon/human/blanker = user
		if(blanker.can_multiz_pb && (!isturf(target)))
			loc = get_turf(blanker.client.eye)
			if(!(loc.Adjacent(target)))
				loc = get_turf(blanker)

	firer = user
	shot_from = launcher.name
	silenced = launcher.item_flags & SILENT

	return launch(target, target_zone, x_offset, y_offset, angle_offset)

//Used to change the direction of the projectile in flight.
/obj/item/projectile/proc/redirect(new_x, new_y, atom/starting_loc, mob/new_firer=null)
	var/turf/new_target = locate(new_x, new_y, src.z)

	original = new_target
	if(new_firer)
		firer = src

	setup_trajectory(starting_loc, new_target)

/obj/item/projectile/proc/istargetloc(mob/living/target_mob)
	if(target_mob && original)
		var/turf/originalloc
		if(!istype(original, /turf))
			originalloc = original.loc
		else
			originalloc = original
		if(originalloc == target_mob.loc)
			return 1
		else
			return 0
	else
		return 0


//Called when the projectile intercepts a mob. Returns 1 if the projectile hit the mob, 0 if it missed and should keep flying.
/obj/item/projectile/proc/attack_mob(mob/living/target_mob, distance, miss_modifier=0)
	if(!istype(target_mob))
		return

	if(target_mob == firer) // Do not hit the shooter if the bullet hasn't ricocheted yet. The firer changes upon ricochet, so this should not prevent ricocheting shots from hitting their shooter.
		return FALSE

	//roll to-hit
	miss_modifier = 0
	var/hit_zone = check_zone(def_zone)

	var/result = PROJECTILE_FORCE_MISS
	if(hit_zone)
		def_zone = hit_zone //set def_zone, so if the projectile ends up hitting someone else later (to be implemented), it is more likely to hit the same part
		if(def_zone)
			switch(target_mob.dir)
				if(2)
					if(p_y <= 10) //legs level
						if(p_x  >= 17)
							if(def_zone == BP_L_LEG || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_L_ARM \
							|| def_zone == BP_CHEST)
								def_zone = BP_L_LEG
							if(def_zone == BP_HEAD || def_zone == BP_R_ARM)
								def_zone = BP_CHEST
							//lleg
						else
							if(def_zone == BP_L_LEG || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST)
								def_zone = BP_R_LEG
							if(def_zone == BP_HEAD || def_zone == BP_L_ARM)
								def_zone = BP_CHEST
							//rleg
						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_L_LEG, BP_R_LEG)

					if(p_y > 10 && p_y <= 13) //groin level
						if(p_x <= 12)
							if(def_zone == BP_L_ARM || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_HEAD)
								def_zone = BP_R_ARM
							if(def_zone == BP_HEAD || def_zone == BP_L_LEG)
								def_zone = BP_CHEST
							//rarm
						if(p_x > 12 && p_x < 21)
							if(def_zone == BP_L_ARM || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_L_LEG)
								def_zone = BP_GROIN
							if(def_zone == BP_HEAD)
								def_zone = BP_CHEST
							//groin
						if(p_x >= 21 && p_x < 24)
							//larm
							if(def_zone == BP_L_ARM || def_zone == BP_L_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_HEAD)
								def_zone = BP_L_ARM
							if(def_zone == BP_HEAD || def_zone == BP_R_LEG)
								def_zone = BP_CHEST

						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_R_ARM, BP_L_ARM, BP_CHEST, BP_GROIN)

					if(p_y > 13 && p_y <= 22)
						if(p_x <= 12)
							if(def_zone == BP_L_ARM || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_HEAD)
								def_zone = BP_R_ARM
							if(def_zone == BP_HEAD || def_zone == BP_L_LEG)
								def_zone = BP_CHEST
							//rarm
						if(p_x > 12 && p_x < 21)
							if(def_zone == BP_L_ARM || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_L_LEG \
							|| def_zone == BP_HEAD)
								def_zone = BP_CHEST
							//chest

						if(p_x >= 21 && p_x < 24)
							if(def_zone == BP_L_ARM || def_zone == BP_HEAD\
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_L_LEG)
								def_zone = BP_L_ARM
							//larm
							if(def_zone == BP_HEAD || def_zone == BP_R_LEG)
								def_zone = BP_CHEST

						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_R_ARM, BP_L_ARM, BP_CHEST)

					if(p_y > 22 && p_y <= 32)
						if(def_zone == BP_L_ARM \
						|| def_zone == BP_R_ARM \
						|| def_zone == BP_CHEST)
							def_zone = BP_HEAD
						//head
						if(def_zone == BP_GROIN || def_zone == BP_R_LEG || \
						def_zone == BP_L_LEG)
							def_zone = BP_CHEST

						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_HEAD, BP_CHEST)
				if(1)
					if(p_y <= 10) //legs level
						if(p_x  >= 17)
							if(def_zone == BP_L_LEG || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST)
								def_zone = BP_R_LEG
							if(def_zone == BP_HEAD || def_zone == BP_L_ARM)
								def_zone = BP_CHEST
							//rleg

						else
							if(def_zone == BP_L_LEG || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_L_ARM \
							|| def_zone == BP_CHEST)
								def_zone = BP_L_LEG
							if(def_zone == BP_HEAD || def_zone == BP_L_ARM)
								def_zone = BP_CHEST
							//lleg
						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_R_LEG, BP_L_LEG, BP_CHEST)

					if(p_y > 10 && p_y <= 13) //groin level
						if(p_x <= 12)
							if(def_zone == BP_L_ARM || def_zone == BP_L_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_HEAD)
								def_zone = BP_L_ARM
							if(def_zone == BP_HEAD || def_zone == BP_R_LEG)
								def_zone = BP_CHEST
							//larm
						if(p_x > 12 && p_x < 21)
							if(def_zone == BP_L_ARM || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_L_LEG)
								def_zone = BP_GROIN
							if(def_zone == BP_HEAD)
								def_zone = BP_CHEST
							//groin
						if(p_x >= 21 && p_x < 24)
							if(def_zone == BP_L_ARM || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_HEAD)
								def_zone = BP_R_ARM
							if(def_zone == BP_HEAD || def_zone == BP_L_LEG)
								def_zone = BP_CHEST
							//rarm
						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_R_ARM, BP_L_ARM, BP_CHEST, BP_GROIN)
					if(p_y > 13 && p_y <= 22)
						if(p_x <= 12)
							if(def_zone == BP_L_ARM || def_zone == BP_L_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_HEAD)
								def_zone = BP_L_ARM
							if(def_zone == BP_HEAD || def_zone == BP_R_LEG)
								def_zone = BP_CHEST
							//larm
						if(p_x > 12 && p_x < 21)
							if(def_zone == BP_L_ARM || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_L_LEG \
							|| def_zone == BP_HEAD)
								def_zone = BP_CHEST
							if(def_zone == BP_HEAD || def_zone == BP_R_LEG)
								def_zone = BP_CHEST
							//chest
						if(p_x >= 21 && p_x < 24)
							if(def_zone == BP_L_ARM || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_HEAD)
								def_zone = BP_R_ARM
							if(def_zone == BP_HEAD || def_zone == BP_L_LEG)
								def_zone = BP_CHEST
							//rarm
						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_R_ARM, BP_L_ARM, BP_CHEST)

					if(p_y > 22 && p_y <= 32)
						if(def_zone == BP_L_ARM \
						|| def_zone == BP_R_ARM \
						|| def_zone == BP_CHEST)
							def_zone = BP_HEAD
						if(def_zone == BP_GROIN || def_zone == BP_L_LEG || \
						def_zone == BP_R_LEG)
							def_zone = BP_CHEST
						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_R_ARM, BP_L_ARM, BP_CHEST, BP_HEAD)
						//head
				if(4)
					if(p_y <= 10) //legs level
						if(def_zone == BP_R_LEG \
						|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
						|| def_zone == BP_CHEST)
							def_zone = BP_R_LEG
						if(def_zone == BP_HEAD || def_zone == BP_R_ARM)
							def_zone = BP_CHEST
						if(def_zone == BP_L_LEG)
							def_zone = BP_L_LEG
						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_R_LEG, BP_L_LEG, BP_CHEST)
						//rleg

					if(p_y > 10 && p_y <= 13) //groin level
						if(p_x < 16)
							if(def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_HEAD)
								def_zone = BP_R_ARM
							if(def_zone == HEAD || def_zone == BP_L_LEG)
								def_zone = BP_CHEST
							if(def_zone == BP_L_ARM)
								def_zone = BP_L_ARM
							//rarm
						if(p_x >= 16)
							if(def_zone == BP_L_ARM || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_L_LEG)
								def_zone = BP_GROIN
							if(def_zone == BP_HEAD)
								def_zone = BP_CHEST

						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_R_ARM, BP_L_ARM, BP_CHEST, BP_GROIN)
							//groin

					if(p_y > 13 && p_y <= 22)
						if(p_x >= 16)
							if(def_zone == BP_L_ARM || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_L_LEG \
							|| def_zone == HEAD)
								def_zone = BP_CHEST
							//chest
						if(p_x < 16)
							if(def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_HEAD)
								def_zone = BP_R_ARM
							//rarm
							if(def_zone == BP_HEAD || def_zone == BP_L_LEG)
								def_zone = BP_CHEST
							if(def_zone == BP_L_ARM)
								def_zone = BP_L_ARM
						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_R_ARM, BP_L_ARM, BP_CHEST)

					if(p_y > 22 && p_y <= 32)
						if(def_zone == BP_L_ARM \
						|| def_zone == BP_R_ARM \
						|| def_zone == BP_CHEST)
							def_zone = BP_HEAD
						if(def_zone ==  BP_GROIN || def_zone == BP_L_LEG || def_zone == BP_R_LEG)
							def_zone = BP_CHEST
						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_R_ARM, BP_L_ARM, BP_CHEST, BP_HEAD)
						//head

				if(8)
					if(p_y <= 10) //legs level
						//lleg
						if(def_zone == BP_L_LEG \
						|| def_zone == BP_GROIN || def_zone == BP_L_ARM \
						|| def_zone == BP_CHEST)
							def_zone = BP_L_LEG

						if(def_zone == BP_HEAD || def_zone == BP_R_ARM)
							def_zone = BP_CHEST

						if(def_zone == BP_R_LEG)
							def_zone = BP_R_LEG
						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_R_LEG, BP_L_LEG, BP_CHEST)

					if(p_y > 10 && p_y <= 13) //groin level
						if(p_x < 16)
							if(def_zone == BP_L_ARM || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_L_LEG)
								def_zone = BP_GROIN
							if(def_zone == BP_HEAD)
								def_zone = BP_CHEST
							//groin
						if(p_x >= 16)
							if(def_zone == BP_L_ARM || def_zone == BP_L_LEG \
							|| def_zone == BP_GROIN \
							|| def_zone == BP_CHEST || def_zone == BP_HEAD)
								def_zone = BP_L_ARM
							if(def_zone == BP_HEAD || def_zone == BP_R_LEG)
								def_zone = BP_CHEST
							if(def_zone == BP_R_ARM)
								def_zone = BP_R_ARM
						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_R_ARM, BP_L_ARM, BP_CHEST, BP_GROIN)
							//left_arm

					if(p_y > 13 && p_y <= 22)
						if(p_x < 16)
							if(def_zone == BP_L_ARM || def_zone == BP_R_LEG \
							|| def_zone == BP_GROIN || def_zone == BP_R_ARM \
							|| def_zone == BP_CHEST || def_zone == BP_L_LEG \
							|| def_zone == BP_HEAD)
								def_zone = BP_CHEST
							//chest
						if(p_x >= 16)
							if(def_zone == BP_L_ARM || def_zone == BP_L_LEG \
							|| def_zone == BP_GROIN \
							|| def_zone == BP_CHEST || def_zone == BP_HEAD)
								def_zone = BP_L_ARM
							if(def_zone == BP_R_LEG || def_zone == BP_HEAD)
								def_zone = BP_CHEST
							if(def_zone == BP_R_ARM)
								def_zone = BP_R_ARM
							//larm
						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_R_ARM, BP_L_ARM, BP_CHEST)

					if(p_y > 22 && p_y <= 32)
						if(def_zone == BP_L_ARM \
						|| def_zone == BP_R_ARM \
						|| def_zone == BP_CHEST)
							def_zone = BP_HEAD
						if(def_zone ==  BP_GROIN || def_zone == BP_L_LEG || def_zone == BP_R_LEG)
							def_zone = BP_CHEST
						if(istargetloc(target_mob) == 0)
							def_zone = pick(BP_R_ARM, BP_L_ARM, BP_CHEST, BP_HEAD)
						//head



			result = target_mob.bullet_act(src, def_zone)//this returns mob's armor_check and another - see modules/mob/living/living_defense.dm


	if(result == PROJECTILE_FORCE_MISS)
		if(!silenced)
			visible_message(SPAN_NOTICE("\The [src] misses [target_mob] narrowly!"))
		return FALSE

	//hit messages
	if(silenced)
		to_chat(target_mob, SPAN_DANGER("You've been hit in the [parse_zone(def_zone)] by \the [src]!"))
	else
		visible_message(SPAN_DANGER("\The [target_mob] is hit by \the [src] in the [parse_zone(def_zone)]!"))//X has fired Y is now given by the guns so you cant tell who shot you if you could not see the shooter

	playsound(target_mob, pick(mob_hit_sound), 40, 1)

	//admin logs
	if(!no_attack_log)
		if(ismob(firer))

			var/attacker_message = "shot with \a [src.type]"
			var/victim_message = "shot with \a [src.type]"
			var/admin_message = "shot (\a [src.type])"

			admin_attack_log(firer, target_mob, attacker_message, victim_message, admin_message)
		else
			target_mob.attack_log += "\[[time_stamp()]\] <b>UNKNOWN SUBJECT (No longer exists)</b> shot <b>[target_mob]/[target_mob.ckey]</b> with <b>\a [src]</b>"
			msg_admin_attack("UNKNOWN shot [target_mob] ([target_mob.ckey]) with \a [src] (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[target_mob.x];Y=[target_mob.y];Z=[target_mob.z]'>JMP</a>)")

	//sometimes bullet_act() will want the projectile to continue flying
	if (result == PROJECTILE_CONTINUE)
		return FALSE

	if(target_mob.mob_classification & CLASSIFICATION_ORGANIC)
		var/turf/target_loca = get_turf(target_mob)
		var/mob/living/L = target_mob
		if(damage_types[BRUTE] > 10)
			var/splatter_dir = dir
			if(starting)
				splatter_dir = get_dir(starting, target_loca)
				target_loca = get_step(target_loca, splatter_dir)
			var/blood_color = "#C80000"
			if(ishuman(target_mob))
				var/mob/living/carbon/human/H = target_mob
				blood_color = H.form.blood_color
			new /obj/effect/overlay/temp/dir_setting/bloodsplatter(target_mob.loc, splatter_dir, blood_color)
			if(target_loca && prob(50))
				target_loca.add_blood(L)

	return TRUE

/obj/item/projectile/Bump(atom/A as mob|obj|turf|area, forced = FALSE)
	if(A == src)
		return FALSE
	if(A == firer)
		loc = A.loc
		return FALSE //go fuck yourself in another place pls

	if((bumped && !forced) || (A in permutated))
		return FALSE

	var/passthrough = FALSE //if the projectile should continue flying
	var/distance = get_dist(starting,loc)

	var/tempLoc = get_turf(A)

	bumped = TRUE

	if(iscarbon(A))
		var/mob/living/carbon/C = A
		var/obj/item/shield/S
		for(S in get_both_hands(C))
			if(S && S.block_bullet(C, src, def_zone))
				on_hit(S,def_zone)
				qdel(src)
				return TRUE
			break //Prevents shield dual-wielding
		S = C.get_equipped_item(slot_back)
		if(S && S.block_bullet(C, src, def_zone))
			on_hit(S,def_zone)
			qdel(src)
			return TRUE

	if(ismob(A))
		var/mob/M = A
		if(isliving(A))
			//if they have a neck grab on someone, that person gets hit instead
			var/obj/item/grab/G = locate() in M
			if(G && G.state >= GRAB_NECK)
				if(G.stat != DEAD) //Dead people are limp and unable to be moved to block bullets to stop endless monkey laser proof shields
					visible_message(SPAN_DANGER("\The [M] uses [G.affecting] as a shield!"))
					if(Bump(G.affecting, TRUE))
						return //If Bump() returns 0 (keep going) then we continue on to attack M.

			passthrough = !attack_mob(M, distance)
		else
			passthrough = FALSE //so ghosts don't stop bullets
	else
		passthrough = (A.bullet_act(src, def_zone) == PROJECTILE_CONTINUE) //backwards compatibility
		if(isturf(A))
			for(var/obj/O in A)
				O.bullet_act(src)
			for(var/mob/living/M in A)
				attack_mob(M, distance)

	//penetrating projectiles can pass through things that otherwise would not let them
	if(!passthrough && penetrating > 0)
		if(check_penetrate(A))
			passthrough = TRUE
		penetrating--

	//the bullet passes through a dense object!
	if(passthrough)
		//move ourselves onto A so we can continue on our way
		if (!tempLoc)
			qdel(src)
			return TRUE

		loc = tempLoc
		if (A)
			permutated.Add(A)
		bumped = FALSE //reset bumped variable!
		return FALSE

	//stop flying
	on_impact(A)

	density = FALSE
	invisibility = 101


	qdel(src)
	return TRUE

/obj/item/projectile/ex_act()
	return //explosions probably shouldn't delete projectiles

/obj/item/projectile/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	return TRUE

/obj/item/projectile/Process()
	var/first_step = TRUE

	spawn while(src && src.loc)
		if(kill_count-- < 1)
			on_impact(src.loc) //for any final impact behaviours
			qdel(src)
			return
		if((!( current ) || loc == current))
			current = locate(min(max(x + xo, 1), world.maxx), min(max(y + yo, 1), world.maxy), z)
		if((x == 1 || x == world.maxx || y == 1 || y == world.maxy))
			qdel(src)
			return


		if(has_drop_off) //Does this shot get weaker as it goes?
			//log_and_message_admins("LOG 1: range shot [range_shot] | drop ap [ap_drop_off] | drop damg | [damage_drop_off] | penetrating [penetrating].")
			range_shot++ //We get the distence form the shooter to what it hit
			damage_drop_off = max(1, range_shot - affective_damage_range) / 100 //How far we were shot - are affective range. This one is for damage drop off
			ap_drop_off = max(1, range_shot - affective_ap_range) //How far we were shot - are affective range. This one is for AP drop off

			armor_penetration = max(0, armor_penetration - ap_drop_off)

			agony = max(0, agony - range_shot) //every step we lose one agony, this stops sniping with rubbers.
			//log_and_message_admins("LOG 2| range shot [range_shot] | drop ap [ap_drop_off] | drop damg | [damage_drop_off] | penetrating [penetrating].")
			if(damage_types[BRUTE])
				damage_types[BRUTE] -= max(0, damage_drop_off - penetrating / 2) //1 penitration gives 25 tiles| 2 penitration 50 tiles making 0 drop

			if(damage_types[BURN])
				damage_types[BURN] -= max(0, damage_drop_off - penetrating / 2) //they can still embed

			if(damage_types[TOX])
				damage_types[TOX] -= max(0, damage_drop_off - penetrating / 2) //they can still embed

			//Clone dosnt get removed do to being rare same as o2

			if(!hitscan)
				speed_drop_off = range_shot / 500 //How far we were shot - are affective range. This one is for speed drop off
				// Every 500 steps = 1 step delay , 50 is 0.1 (thats huge!), 5 0.01
				step_delay = step_delay + speed_drop_off

		trajectory.increment()	// increment the current location
		location = trajectory.return_location(location)		// update the locally stored location data

		if(!location)
			qdel(src)	// if it's left the world... kill it
			return

		before_move()
		Move(location.return_turf())
		pixel_x = location.pixel_x
		pixel_y = location.pixel_y

		if(!bumped && !isturf(original))
			if(loc == get_turf(original))
				if(!(original in permutated))
					if(Bump(original))
						return

		if(first_step)
			muzzle_effect(effect_transform)
			first_step = FALSE
		else if(!bumped)
			tracer_effect(effect_transform)
			luminosity_effect()

		if(!hitscan)
			sleep(step_delay)	//add delay between movement iterations if it's not a hitscan weapon

/obj/item/projectile/proc/before_move()
	return FALSE

/obj/item/projectile/proc/setup_trajectory(turf/startloc, turf/targloc, x_offset = 0, y_offset = 0, angle_offset)
	// setup projectile state
	starting = startloc
	current = startloc
	yo = targloc.y - startloc.y + y_offset
	xo = targloc.x - startloc.x + x_offset

	// plot the initial trajectory
	trajectory = new()
	trajectory.setup(starting, original, pixel_x, pixel_y, angle_offset)

	// generate this now since all visual effects the projectile makes can use it
	effect_transform = new()
	effect_transform.Scale(trajectory.return_hypotenuse(), 1)
	effect_transform.Turn(-trajectory.return_angle())		//no idea why this has to be inverted, but it works

	transform = turn(transform, -(trajectory.return_angle() + 90)) //no idea why 90 needs to be added, but it works

/obj/item/projectile/proc/muzzle_effect(var/matrix/T)
	//This can happen when firing inside a wall, safety check
	if (!location)
		return

	if(silenced)
		return

	if(ispath(muzzle_type))
		var/obj/effect/projectile/M = new muzzle_type(get_turf(src))

		if(istype(M))
			if(proj_color)
				var/icon/I = new(M.icon, M.icon_state)
				I.Blend(proj_color)
				M.icon = I
			M.set_transform(T)
			M.pixel_x = location.pixel_x
			M.pixel_y = location.pixel_y
			M.activate()

/obj/item/projectile/proc/tracer_effect(var/matrix/M)

	//This can happen when firing inside a wall, safety check
	if (!location)
		return

	if(ispath(tracer_type))
		var/obj/effect/projectile/P = new tracer_type(location.loc)

		if(istype(P))
			if(proj_color)
				var/icon/I = new(P.icon, P.icon_state)
				I.Blend(proj_color)
				P.icon = I
			P.set_transform(M)
			P.pixel_x = location.pixel_x
			P.pixel_y = location.pixel_y
			if(!hitscan)
				P.activate(step_delay)	//if not a hitscan projectile, remove after a single delay
			else
				P.activate()

/obj/item/projectile/proc/luminosity_effect()
	if(!location)
		return

	if(attached_effect)
		attached_effect.Move(src.loc)

	else if(luminosity_range && luminosity_power && luminosity_color)
		attached_effect = new /obj/effect/effect/light(src.loc, luminosity_range, luminosity_power, luminosity_color, lifetime=20)

/obj/item/projectile/proc/impact_effect(var/matrix/M)
	//This can happen when firing inside a wall, safety check
	if (!location)
		return

	if(ispath(impact_type))
		var/obj/effect/projectile/P = new impact_type(location.loc)

		if(istype(P))
			if(proj_color)
				var/icon/I = new(P.icon, P.icon_state)
				I.Blend(proj_color)
				P.icon = I
			P.set_transform(M)
			P.pixel_x = location.pixel_x
			P.pixel_y = location.pixel_y
			P.activate(P.lifetime)

//"Tracing" projectile
/obj/item/projectile/test //Used to see if you can hit them.
	invisibility = 101 //Nope!  Can't see me!
	yo = null
	xo = null
	var/result = 0 //To pass the message back to the gun.

/obj/item/projectile/test/Bump(atom/A as mob|obj|turf|area, forced)
	if(A == firer)
		loc = A.loc
		return //cannot shoot yourself
	if(istype(A, /obj/item/projectile))
		return
	if(isliving(A) || istype(A, /obj/mecha) || istype(A, /obj/vehicle))
		result = 2 //We hit someone, return 1!
		return
	result = 1
	return

/obj/item/projectile/test/launch(atom/target)
	var/turf/curloc = get_turf(src)
	var/turf/targloc = get_turf(target)
	if(!curloc || !targloc)
		return 0

	original = target

	//plot the initial trajectory
	setup_trajectory(curloc, targloc)
	return Process(targloc)

/obj/item/projectile/test/Process(turf/targloc)
	while(src) //Loop on through!
		if(result)
			return (result - 1)
		if((!( targloc ) || loc == targloc))
			targloc = locate(min(max(x + xo, 1), world.maxx), min(max(y + yo, 1), world.maxy), z) //Finding the target turf at map edge

		trajectory.increment()	// increment the current location
		location = trajectory.return_location(location)		// update the locally stored location data

		Move(location.return_turf())

		var/mob/living/M = locate() in get_turf(src)
		if(istype(M)) //If there is someting living...
			return 1 //Return 1
		else
			M = locate() in get_step(src,targloc)
			if(istype(M))
				return 1

//Helper proc to check if you can hit them or not.
/proc/check_trajectory(atom/target as mob|obj, atom/firer as mob|obj, var/pass_flags=PASSTABLE|PASSGLASS|PASSGRILLE, flags=null)
	if(!istype(target) || !istype(firer))
		return 0

	var/obj/item/projectile/test/trace = new /obj/item/projectile/test(get_turf(firer)) //Making the test....

	//Set the flags and pass flags to that of the real projectile...
	if(!isnull(flags))
		trace.flags = flags
	trace.pass_flags = pass_flags

	var/output = trace.launch(target) //Test it!
	qdel(trace) //No need for it anymore
	return output //Send it back to the gun!

/proc/get_proj_icon_by_color(var/obj/item/projectile/P, var/color)
	var/icon/I = new(P.icon, P.icon_state)
	I.Blend(color)
	return I
