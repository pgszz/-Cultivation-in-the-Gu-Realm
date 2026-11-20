class_name NpcExchangeTests
extends RefCounted

var game: Node
var test := CanonTests.new()
var inv: Inventory

func frames() -> void:
	await game.get_tree().process_frame
	await game.get_tree().process_frame

func focus(person: Npc) -> void:
	game.player.position=person.position+Vector2(-32,0)
	game._update_camera(0)
	game.camera.reset_smoothing()
	await frames()

func click(button: Control) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	var point:=button.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new()
	motion.position=point
	motion.global_position=point
	game.get_viewport().push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=point
		event.global_position=point
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed
		event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
		game.get_viewport().push_input(event,true)
	await frames()

func state(person: Npc) -> Dictionary:
	return {"npc":person.save_data().duplicate(true),"items":inv.items.duplicate(),"money":game.player.crystals}

func restored_state(person: Npc, expected: Dictionary) -> bool:
	# JSON restores inventory counts as floats; compare numeric content, not Variant types.
	var actual:=state(person)
	if JSON.stringify(actual)==JSON.stringify(expected): return true
	print("EXCHANGETEST SAVE expected="+JSON.stringify(expected)+" actual="+JSON.stringify(actual))
	return false

func reject_unchanged(person: Npc, item: String, count: int, theft: bool, label: String) -> void:
	var before:=state(person)
	var random_state:int=game._rng.state
	var accepted:=PersonExchange.steal(game,person,item,count) if theft else PersonExchange.gift(game,person,item,count)
	test.expect(not accepted and state(person)==before and random_state==game._rng.state,label+": no transfer, social change or retaliation roll")

func next_roll(retaliation: bool) -> void:
	# Exercise both rare and common outcomes without exposing a gameplay bypass.
	var probe:=RandomNumberGenerator.new()
	for seed_value in range(10000):
		probe.seed=seed_value
		var roll:=probe.randf()
		if (retaliation and roll<0.02) or (not retaliation and roll>=0.05):
			game._rng.seed=seed_value
			return
	test.expect(false,"could find a deterministic random seed")

func shot(label: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	test.expect(game.get_viewport().get_texture().get_image().save_png("res://shot_exchange_"+label+".png")==OK,"saved "+label)

func layout() -> void:
	var ui:NpcInspectUI=game.npc_inspect_ui
	test.expect(game.get_viewport_rect().encloses(ui.panel.get_global_rect()),"inspection panel fits viewport")
	for control:Control in [ui.gift_button,ui.theft_button,ui.quantity,ui.talk_button,ui.context_label,ui.item_scroll]:
		test.expect(ui.panel.get_global_rect().encloses(control.get_global_rect()),"gift/theft control remains inside panel: "+control.name)
	test.expect(ui.item_scroll.size.y>=90,"item list retains a usable scrolling area")

func run(main: Node) -> void:
	game=main
	test.game=game
	game.set_process(false)
	await test.start_character()
	inv=game.get_node("/root/Inv")
	var person:Npc=game.npc
	var ui:NpcInspectUI=game.npc_inspect_ui
	await focus(person)
	inv.items={"bandage":6,"bamboo_wine":4,"rubble":3,"jade":2,"moon_petals":5,"rabbit_meat":4}
	game.inspect_person(person)
	await click(ui.tabs.items)
	await click(ui.gift_button)
	test.expect(ui.item_mode=="gift" and ui.selling and game.paused,"real gift tab selects player inventory and keeps game paused")
	test.expect(ui.item_buttons.bamboo_wine.disabled and ui.item_buttons.bamboo_wine.tooltip_text.contains("好感需达到 4"),"healthy stranger refuses favored wine and explains relationship threshold")
	reject_unchanged(person,"bamboo_wine",1,false,"stranger gift refusal")
	person.social.affinity=100
	reject_unchanged(person,"moon_petals",1,false,"trusted person refuses unused Gu food")
	reject_unchanged(person,"rubble",1,false,"trusted non-craftsman refuses rubble")
	person.hp-=10
	person.social.affinity=-1
	reject_unchanged(person,"bandage",1,false,"wary wounded person refuses gift")
	person.social.affinity=0
	ui.refresh()
	await frames()
	layout()
	await shot("gift_choices")
	var money:int=game.player.crystals
	var npc_money:=person.carried_crystals
	var old_count:int=int(person.carried_items.get("bandage",0))
	var hp:=person.hp
	await click(ui.item_buttons.bandage)
	test.expect(inv.get_item_count("bandage")==5 and int(person.carried_items.bandage)==old_count+1,"gift button transfers exact quantity into real NPC inventory")
	test.expect(person.social.affinity==8 and person.social.history.back().kind=="gift" and person.social.history.back().change==8,"urgent accepted gift records actual gratitude")
	test.expect(person.hp==hp and game.player.crystals==money and person.carried_crystals==npc_money,"gift neither heals nor transfers currency implicitly")
	test.expect(ui.affinity_label.text.contains("+8") and ui.context_label.text.contains("收下") and not game._world_attack_held,"gift updates feedback and affinity without leaking attack")
	reject_unchanged(person,"bamboo_wine",1,false,"switching item cannot bypass gift interval")
	var saved:=state(person)
	ui.close()
	game._load_save()
	person=game.npc
	await focus(person)
	test.expect(restored_state(person,saved),"actual character reload restores fixed NPC gift, inventory and social cooldown")
	reject_unchanged(person,"bandage",1,false,"reload cannot repeat gift")
	var start_time:float=game.social_time
	game.paused=true
	game._process(400)
	test.expect(game.social_time==start_time,"paused time cannot expire gift or theft interval")
	game.paused=false
	game.social_time+=299.5
	reject_unchanged(person,"bandage",1,false,"gift still blocked before 300 seconds")
	game.social_time+=0.5
	test.expect(PersonExchange.gift(game,person,"bamboo_wine",2) and person.social.affinity==14,"favored gift accepted exactly at interval with quantity-independent reward")
	person.social.rewards.erase("gift")
	person.hp=person.max_hp
	for quantity in [0,-1,11,991]: reject_unchanged(person,"bandage",quantity,false,"invalid gift quantity "+str(quantity))
	for item in ["moon_blade","missing","currency"]: reject_unchanged(person,item,1,false,"invalid gift type "+item)
	reject_unchanged(person,"bamboo_wine",10,false,"gift stock shortage")
	person.carried_items.bandage=Inventory.MAX_STACK*10
	reject_unchanged(person,"bandage",1,false,"full recipient inventory")
	person.carried_items.bandage=3
	reject_unchanged(person,"rabbit_meat",1,false,"ordinary gift below friendship threshold")
	person.social.affinity=30
	test.expect(PersonExchange.gift(game,person,"rabbit_meat",3) and person.social.affinity==33,"friend accepts practical gift with ordinary gratitude")
	# Distinct roles use actual resident identities; no fabricated NPC Gu inventory.
	for entry in [[game.residents.clinic,"bandage"],[game.residents.bai_workshop,"timber"],[game.population.actors.caravan_guard_a,"bandage"],[game.population.actors.bamboo_gatherer,"timber"]]:
		var target:Npc=entry[0]
		target.social.ensure(target)
		target.social.affinity=4
		test.expect(NpcGiftRules.evaluate(target,entry[1]).reason=="","profession accepts useful gift: "+target.resident_id)
		test.expect(NpcGiftRules.evaluate(target,"moon_petals").reason!="","profession refuses unused specialty: "+target.resident_id)
	# Invalid locations and target states are checked again at settlement time.
	person.social.rewards.clear()
	await focus(person)
	game.player.position+=Vector2(200,0)
	for theft in [false,true]: reject_unchanged(person,"bandage",1,theft,"distant operation")
	await focus(person)
	person.hostile=true
	for theft in [false,true]: reject_unchanged(person,"bandage",1,theft,"hostile operation")
	person.hostile=false
	game.player.dead=true
	for theft in [false,true]: reject_unchanged(person,"bandage",1,theft,"dead player operation")
	game.player.dead=false
	game.enter_house(World.HOUSE_DATA[1])
	for theft in [false,true]: reject_unchanged(person,"bandage",1,theft,"different scene operation")
	game.exit_house()
	# Moving actors share the same gift and theft settlement and persistence.
	var merchant:WorldPerson=game.population.actors.caravan_merchant
	merchant.position=game.population.walkable_position(Vector2(816,1008))
	merchant.load_data({})
	merchant.social.affinity=34
	await focus(merchant)
	test.expect(NpcGiftRules.evaluate(merchant,"jade").reason=="","friendly merchant accepts valuable jade")
	merchant.social.affinity=4
	test.expect(NpcGiftRules.evaluate(merchant,"jade").reason!="","valuable jade requires friendship even for merchant")
	merchant.social.affinity=34
	for quantity in [0,-1,991]: reject_unchanged(merchant,"bandage",quantity,true,"invalid theft quantity "+str(quantity))
	for item in ["moon_blade","missing"]: reject_unchanged(merchant,item,1,true,"invalid theft type "+item)
	reject_unchanged(merchant,"bandage",100,true,"theft shortage")
	reject_unchanged(merchant,"currency",999,true,"currency theft shortage")
	inv.items.bandage=Inventory.MAX_STACK*10
	reject_unchanged(merchant,"bandage",1,true,"full player inventory")
	inv.items.bandage=5
	merchant.flee_left=1
	for theft in [false,true]: reject_unchanged(merchant,"bandage",1,theft,"fleeing target")
	merchant.flee_left=0
	game.inspect_person(merchant)
	await click(ui.tabs.items)
	await click(ui.theft_button)
	ui.quantity.value=2
	await frames()
	layout()
	test.expect(ui.item_mode=="theft" and ui.item_buttons.bandage.text.contains("好感 -12"),"theft page previews actual loss and target inventory")
	await shot("theft_choices")
	money=game.player.crystals
	npc_money=merchant.carried_crystals
	next_roll(false)
	await click(ui.item_buttons.bandage)
	test.expect(inv.get_item_count("bandage")==7 and int(merchant.carried_items.bandage)==6,"real theft button moves exact items")
	test.expect(merchant.social.affinity==22 and merchant.social.history.back().kind=="theft" and merchant.social.history.back().change==-12,"successful theft reduces affinity and records stolen quantity")
	test.expect(game.player.crystals==money and merchant.carried_crystals==npc_money and not game._world_attack_held,"item theft neither spends money nor attacks")
	test.expect(ui.context_label.text.contains("察觉") and ui.affinity_label.text.contains("+22"),"theft feedback immediately reflects consequences")
	test.expect(not merchant.hostile and not merchant.social.theft_retaliation,"ordinary theft outcome does not start combat")
	reject_unchanged(merchant,"currency",1,true,"raised alert prevents immediate repeat theft")
	reject_unchanged(merchant,"bandage",1,false,"raised alert prevents immediate gift appeasement")
	await click(ui.tabs.history)
	test.expect(ui.details.text.contains("盗走绷带 ×2") and ui.details.text.contains("好感 -12"),"history renders actual theft loss")
	await shot("theft_history")
	saved=state(merchant)
	ui.close()
	game._load_save()
	merchant=game.population.actors.caravan_merchant
	await focus(merchant)
	test.expect(restored_state(merchant,saved),"actual reload restores moving NPC theft, inventory and alert")
	reject_unchanged(merchant,"bandage",1,true,"reload cannot bypass theft alert")
	game.social_time+=300
	test.expect(PersonExchange.gift(game,merchant,"bandage",1) and merchant.social.affinity==28,"useful gift works after alert expires if relationship permits")
	money=game.player.crystals
	npc_money=merchant.carried_crystals
	next_roll(false)
	test.expect(PersonExchange.steal(game,merchant,"currency",3),"currency theft settles")
	test.expect(game.player.crystals==money+3 and merchant.carried_crystals==npc_money-3 and merchant.social.affinity==15,"currency theft transfers both balances and applies value-based loss")
	merchant.social.rewards.erase("theft")
	merchant.social.affinity=-95
	next_roll(false)
	test.expect(PersonExchange.steal(game,merchant,"bandage",1) and merchant.social.affinity==-100 and merchant.social.history.back().change==-5,"theft clamps affinity and records only actual loss")
	merchant.social.rewards.clear()
	reject_unchanged(merchant,"bandage",1,false,"theft-damaged relationship refuses gifts")
	merchant.social.affinity=100
	inv.items.bandage=30
	test.expect(PersonExchange.gift(game,merchant,"bandage",10) and merchant.social.affinity==100,"maximum gift quantity transfers with clamped gratitude")
	# Full real save path preserves both gift and theft keys on both NPC subclasses.
	game.save_game()
	saved=state(merchant)
	game._load_save()
	merchant=game.population.actors.caravan_merchant
	await focus(merchant)
	test.expect(restored_state(merchant,saved) and merchant.social.rewards.has("gift"),"moving NPC gift state survives character reload")
	# A low-probability retaliation really attacks through the existing combat systems.
	merchant.social.rewards.clear()
	merchant.social.affinity=34
	test.expect(is_equal_approx(PersonExchange.theft_retaliation_chance(merchant),0.02),"friendly retaliation chance is only two percent")
	game.inspect_person(merchant)
	await click(ui.tabs.items)
	await click(ui.theft_button)
	test.expect(ui.context_label.text.contains("2%"),"UI communicates rare retaliation before stealing")
	next_roll(true)
	await click(ui.item_buttons.currency)
	test.expect(merchant.hostile and merchant.social.theft_retaliation and merchant.target==game.player,"rare theft roll makes moving civilian hostile with a real player target")
	test.expect(game.population.can_fight(merchant) and merchant.social.history.back().kind=="retaliation","civilian retaliation enables actual fighting and leaves a cause record")
	test.expect(ui.context_label.text.contains("反击") and ui.talk_button.disabled,"retaliation is visible and prevents peaceful interactions")
	await shot("retaliation")
	var player_hp:float=game.player.hp
	game._process(1)
	test.expect(game.player.hp==player_hp,"inspection remains paused when retaliation triggers")
	ui.close()
	game.population.update_person(merchant,0.01)
	game.population.update_person(merchant,0.30)
	test.expect(game.player.hp<player_hp,"moving victim's real strike damages player after returning to map")
	game._load_save()
	merchant=game.population.actors.caravan_merchant
	await focus(merchant)
	game.population.find_target(merchant)
	test.expect(merchant.hostile and merchant.social.theft_retaliation and game.population.can_fight(merchant) and merchant.target==game.player,"reload retains civilian retaliation and reacquires player")
	reject_unchanged(merchant,"bandage",1,false,"retaliating victim cannot be appeased by forced gift")
	merchant.load_data({})
	person=game.npc
	person.load_data({})
	await focus(person)
	test.expect(is_equal_approx(PersonExchange.theft_retaliation_chance(person),0.05),"neutral or wary retaliation remains capped at five percent")
	next_roll(true)
	test.expect(PersonExchange.steal(game,person,"bandage",1) and person.hostile,"rare theft roll also activates fixed resident hostility")
	player_hp=game.player.hp
	game.player.iframes=0
	person.tick(0.01,game)
	test.expect(game.player.hp<player_hp,"fixed victim actually attacks through ordinary NPC combat")
	game._load_save()
	person=game.npc
	test.expect(person.hostile and person.social.theft_retaliation and person.inspection_data().relationship_reason.contains("盗窃"),"fixed retaliation and correct relationship cause persist")
	person.load_data({})
	merchant=game.population.actors.caravan_merchant
	await focus(merchant)
	merchant.dead=true
	merchant.hp=0
	for theft in [false,true]: reject_unchanged(merchant,"bandage",1,theft,"corpse cannot receive gifts or be pickpocketed")
	game.inspect_person(merchant)
	await click(ui.tabs.items)
	test.expect(not ui.gift_button.visible and not ui.theft_button.visible and ui.loot_all_button.visible,"corpse keeps distinct looting UI")
	var affinity:=merchant.social.affinity
	test.expect(PersonExchange.loot(game,merchant,"bandage",1) and merchant.social.affinity==affinity,"corpse looting remains available without theft penalty")
	ui.close()
	for target:Npc in [game.npc,merchant]:
		target.load_data({})
		test.expect(target.social.affinity==0 and not target.social.theft_retaliation and target.social.cooldown_left(target,"gift")==0 and target.social.cooldown_left(target,"theft")==0,"legacy save defaults have no gift or theft memory")
	print("EXCHANGETEST checked=%d failures=%s" % [test.checked,JSON.stringify(test.failures)])
	game.get_tree().quit(0 if test.failures.is_empty() else 1)
