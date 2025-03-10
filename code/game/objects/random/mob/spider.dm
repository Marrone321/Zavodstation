/obj/random/mob/spiders
	name = "random spider"
	icon_state = "hostilemob-black"
	alpha = 128

/obj/random/mob/spiders/item_to_spawn()
	return pickweight(list(/mob/living/carbon/superior_animal/giant_spider = 35,\
				/mob/living/carbon/superior_animal/giant_spider/nurse = 30,\
				/mob/living/carbon/superior_animal/giant_spider/nurse/midwife = 15,\
				/mob/living/carbon/superior_animal/giant_spider/nurse/orb_weaver = 14,\
				/mob/living/carbon/superior_animal/giant_spider/nurse/carrier = 12,\
				/mob/living/carbon/superior_animal/giant_spider/nurse/queen = 5,\
				/mob/living/carbon/superior_animal/giant_spider/nurse/recluse = 4,\
				/mob/living/carbon/superior_animal/giant_spider/plasma = 4,\
				/mob/living/carbon/superior_animal/giant_spider/tarantula/emperor = 1,\
				/mob/living/carbon/superior_animal/giant_spider/hunter = 35,\
				/mob/living/carbon/superior_animal/giant_spider/hunter/cloaker = 20,\
				/mob/living/carbon/superior_animal/giant_spider/hunter/viper = 15,\
				/mob/living/carbon/superior_animal/giant_spider/hunter/shocker = 15,\
				/mob/living/carbon/superior_animal/giant_spider/hunter/pepper = 10,\
				/mob/living/carbon/superior_animal/giant_spider/tarantula = 10,\
				/mob/living/carbon/superior_animal/giant_spider/tarantula/ogre = 8,\
				/mob/living/carbon/superior_animal/giant_spider/tarantula/pit = 8,\
				/mob/living/carbon/superior_animal/giant_spider/tarantula/burrowing = 6
				))

/obj/random/mob/spiders/low_chance
	name = "low chance random spider"
	icon_state = "hostilemob-black-low"
	spawn_nothing_percentage = 60

/obj/random/cluster/spiders
	name = "cluster of spiders"
	icon_state = "hostilemob-black-cluster"
	alpha = 128
	min_amount = 1
	max_amount = 5
	spread_range = 0

/obj/random/cluster/spiders/item_to_spawn()
	return /obj/random/mob/spiders

/obj/random/cluster/spiders/low_chance
	name = "low chance cluster of spiders"
	icon_state = "hostilemob-black-cluster-low"
	spawn_nothing_percentage = 60

/obj/random/mob/spiders/spider_ling //just sont have carrer
	name = "random spiderling spider"
	icon_state = "hostilemob-black"
	alpha = 128

/obj/random/mob/spiders/item_to_spawn()
	return pickweight(list(/mob/living/carbon/superior_animal/giant_spider = 35,\
				/mob/living/carbon/superior_animal/giant_spider/nurse = 30,\
				/mob/living/carbon/superior_animal/giant_spider/nurse/midwife = 15,\
				/mob/living/carbon/superior_animal/giant_spider/nurse/orb_weaver = 14,\
				/mob/living/carbon/superior_animal/giant_spider/nurse/queen = 5,\
				/mob/living/carbon/superior_animal/giant_spider/nurse/recluse = 4,\
				/mob/living/carbon/superior_animal/giant_spider/plasma = 4,\
				/mob/living/carbon/superior_animal/giant_spider/tarantula/emperor = 1,\
				/mob/living/carbon/superior_animal/giant_spider/hunter = 35,\
				/mob/living/carbon/superior_animal/giant_spider/hunter/cloaker = 20,\
				/mob/living/carbon/superior_animal/giant_spider/hunter/viper = 15,\
				/mob/living/carbon/superior_animal/giant_spider/hunter/shocker = 15,\
				/mob/living/carbon/superior_animal/giant_spider/hunter/pepper = 10,\
				/mob/living/carbon/superior_animal/giant_spider/tarantula = 10,\
				/mob/living/carbon/superior_animal/giant_spider/tarantula/ogre = 8,\
				/mob/living/carbon/superior_animal/giant_spider/tarantula/pit = 8,\
				/mob/living/carbon/superior_animal/giant_spider/tarantula/burrowing = 6
				))