class_name NpcInspectionTests
extends RefCounted

var game: Node
var test := CanonTests.new()

func pointer(person: Npc, pressed: bool, alt: bool = true) -> void:
	var pos:Vector2=person.get_global_transform_with_canvas()*Vector2(0,-18 if not person.dead else 0)
	var motion:=InputEventMouseMotion.new()
	motion.position=pos
	motion.global_position=pos
	motion.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
	game.get_viewport().push_input(motion,true)
	# Basic melee polls the window cursor; dispatched click coordinates alone are insufficient.
	if not alt:
		game.get_viewport().warp_mouse(pos)
		await game.get_tree().process_frame
		game.get_viewport().push_input(motion,true)
	var event:=InputEventMouseButton.new()
	event.position=pos
	event.global_position=pos
	event.button_index=MOUSE_BUTTON_LEFT
	event.pressed=pressed
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.alt_pressed=alt
	game.get_viewport().push_input(event,true)
	await game.get_tree().process_frame
	# Root-window mouse polling reads the OS cursor, not push_input's GUI position.
	# Warp after the awaited frame so desktop motion during that frame cannot change the aim.
	if not alt:
		game.get_viewport().warp_mouse(pos)
		game.get_viewport().push_input(motion,true)

func focus(person: Npc, offset: Vector2 = Vector2(-45,20)) -> void:
	game.player.position=person.position+offset
	game._update_camera(0)
	game.camera.reset_smoothing()
	await game.get_tree().process_frame
	await game.get_tree().process_frame

func run(main: Node) -> void:
	game=main
	test.game=game
	game.set_process(false)
	await test.start_character()
	var person:Npc=game.npc
	var ui:NpcInspectUI=game.npc_inspect_ui
	await focus(person)
	var hp:=person.hp
	var player_hp:float=game.player.hp
	await pointer(person,true)
	test.expect(ui.visible and ui.person==person and game.paused,"Alt-left click opens actual outdoor person and pauses")
	test.expect(not game._world_attack_held and person.hp==hp and not person.hostile,"inspection press neither arms melee nor changes relationship")
	game._process(0.5)
	test.expect(game.player.hp==player_hp and person.hp==hp,"inspection blocks combat simulation")
	await pointer(person,false)
	test.expect(game.get_viewport_rect().encloses(ui.panel.get_global_rect()),"person panel fits viewport")
	test.expect(ui.panel.get_global_rect().encloses(ui.talk_button.get_global_rect()),"talk action stays within panel")
	test.expect(ui.details.text.contains("修为    未探明") and ui.details.text.contains("基础攻击    7"),"attributes show known combat values without inventing cultivation")
	await test.click(ui.tabs.relations)
	test.expect(ui.active_tab=="relations" and ui.details.text.contains("中立") and ui.details.text.contains("古月山寨"),"real relations tab reads neutral attitude and faction")
	await test.click(ui.tabs.status)
	test.expect(ui.active_tab=="status" and ui.details.text.contains("健康") and ui.details.text.contains("停留"),"real status tab reads current life and activity")
	await test.key(KEY_TAB)
	test.expect(ui.visible and not game.journal.visible,"Tab does not stack journal on inspection")
	await test.key(KEY_C)
	test.expect(ui.visible and not game.journal.visible,"character shortcut does not switch modal unexpectedly")
	await test.click(ui.talk_button)
	test.expect(not ui.visible and game.village_ui.visible and game.village_ui.mode=="conversation" and game.paused,"inspection opens contextual conversation")
	game.village_ui.close()
	# Zoomed selection uses the actual canvas transform, not fixed screen coordinates.
	for zoom in [0.65,1.75]:
		game.set_camera_zoom(zoom)
		await focus(person)
		await pointer(person,true)
		await pointer(person,false)
		test.expect(ui.visible and ui.person==person,"world click selects person at zoom %.2f" % zoom)
		await test.click(ui.close_button)
		test.expect(not ui.visible and not game.paused and not game._world_attack_held,"close button resumes without arming attack")
	game.set_camera_zoom(1)
	await focus(person,Vector2(-200,0))
	await pointer(person,true)
	await pointer(person,false)
	test.expect(ui.visible and ui.talk_button.disabled and ui.context_label.text.contains("距离"),"visible distant person is inspectable but cannot talk remotely")
	await test.key(KEY_ESCAPE)
	test.expect(not ui.visible and not game.paused and not game.pause_layer.visible,"Escape closes only inspection and resumes")
	game.player.position=person.position+Vector2(700,0)
	person.visible=true
	var screen:Vector2=person.get_global_transform_with_canvas()*Vector2(0,-18)
	test.expect(game.person_at_screen(screen)==null,"out-of-vision person cannot be selected despite stale visible flag")
	game.inspect_person(person)
	test.expect(not ui.visible,"direct inspection also rejects unseen person")
	await focus(person)
	screen=person.get_global_transform_with_canvas()*Vector2(0,-18)
	person.hide()
	test.expect(game.person_at_screen(screen)==null,"hidden person cannot be selected")
	person.show()
	# Deliberate attack remains available, while release reaches Main even over a modal.
	await pointer(person,true,false)
	test.expect(not ui.visible and game._world_attack_held,"plain left press arms melee without opening inspection")
	if game.get_global_mouse_position().distance_to(person.position+Vector2(0,-18))>=3: print("CURSOR DEBUG mouse=%s target=%s offset=%s" % [game.get_global_mouse_position(),person.position+Vector2(0,-18),game.camera.offset])
	test.expect(game.get_global_mouse_position().distance_to(person.position+Vector2(0,-18))<3,"intentional melee cursor matches the clicked person at the actual window size")
	game.player.atk_cd=0
	game.basic_attack()
	test.expect(person.hp<hp and person.hostile,"intentional melee still injures the person and makes them hostile")
	await pointer(person,false,false)
	test.expect(not game._world_attack_held,"release disarms world attack")
	await pointer(person,true)
	await pointer(person,false)
	test.expect(ui.visible and ui.person==person,"hostile person can still be inspected")
	await test.click(ui.tabs.relations)
	test.expect(ui.details.text.contains("敌对") and ui.details.text.contains("遭到你的攻击"),"relations reflect actual attack consequence")
	test.expect(ui.talk_button.disabled,"hostile person's talk is disabled")
	await test.key(KEY_ESCAPE)
	person.load_data({})
	# Every resident resolves affiliation from its actual settlement data.
	for resident: Npc in game.residents.values():
		var profile:=resident.inspection_data()
		test.expect(profile.faction!="未知" and profile.place!="未知","registered resident has identity: "+resident.resident_id)
	# Indoor click must never select other hidden residents at the same local position.
	game.enter_house(World.HOUSE_DATA[1])
	person=game.residents.shop
	await focus(person)
	await pointer(person,true)
	await pointer(person,false)
	test.expect(ui.visible and ui.person==person and ui.name_label.text=="商铺伙计","indoor click resolves the current house occupant")
	game.residents.clinic.show()
	screen=person.get_global_transform_with_canvas()*Vector2(0,-18)
	test.expect(game.person_at_screen(screen)==person,"same-position person from another room cannot steal selection")
	game.residents.clinic.hide()
	test.expect(ui.portrait.texture.atlas==NpcAppearance.texture(person.get_appearance()) and ui.portrait.texture.region==NpcAppearance.region(person.get_appearance(),0),"portrait matches the selected resident's actual appearance")
	await test.click(ui.talk_button)
	test.expect(game.village_ui.visible and game.village_ui.mode=="conversation" and not ui.visible and game.paused,"shop inspection opens resident conversation")
	test.expect(not game._world_attack_held,"service button click cannot leak into melee")
	game.village_ui.close()
	person.take_damage(78,game)
	await pointer(person,true)
	await pointer(person,false)
	await test.click(ui.tabs.status)
	test.expect(ui.health_bar.value==person.hp and ui.details.text.contains("濒危") and ui.talk_button.disabled,"low health and hostility share live model state")
	game.save_game()
	ui.close()
	person.load_data({})
	game._load_save()
	await focus(person)
	game.inspect_person(person)
	ui.select_tab("relations")
	test.expect(person.hostile and is_equal_approx(person.hp,22) and ui.details.text.contains("敌对"),"saved wounds and relationship restore in inspection")
	# External state updates while viewing refresh the panel without reviving anyone.
	person.take_damage(999,game)
	ui.select_tab("status")
	test.expect(ui.health_bar.value==0 and ui.details.text.contains("已死亡") and ui.talk_button.disabled,"death updates displayed life and prevents services")
	ui.close()
	await pointer(person,true)
	await pointer(person,false)
	test.expect(ui.visible and ui.person==person,"corpse remains clickable for inspection")
	await test.click(ui.tabs.relations)
	test.expect(ui.details.text.contains("敌对"),"death preserves prior relationship")
	ui.close()
	game._load_save()
	test.expect(person.dead and person.inspection_data().health=="已死亡","dead person's state survives save reload")
	person.load_data({})
	test.expect(person.hp==person.max_hp and not person.hostile and not person.dead,"legacy missing resident fields retain safe defaults")
	game.exit_house(false)
	# Outdoor residents in the other villages use their own directions service.
	for id in ["bai_gatekeeper","xiong_walker"]:
		if not game.residents.has(id): continue
		person=game.residents[id]
		await focus(person)
		await pointer(person,true)
		await pointer(person,false)
		test.expect(ui.visible and ui.person==person,"outdoor settlement resident can be clicked: "+id)
		await test.click(ui.talk_button)
		test.expect(game.village_ui.visible and not ui.visible,"settlement directions open from selected person: "+id)
		game.village_ui.close()
	# Dynamic people provide their own attributes and portrait row to the same panel.
	for id in ["caravan_merchant","east_bandit_0"]:
		var actor:Npc=game.population.actors.get(id)
		if actor==null: continue
		await focus(actor)
		game.inspect_person(actor)
		await game.get_tree().process_frame
		var info:=actor.inspection_data()
		test.expect(ui.visible and ui.person==actor,"dynamic person shares inspection entry: "+id)
		test.expect(ui.details.text.contains("基础攻击    %.0f" % info.attack),"dynamic person's actual attack overrides fixed resident defaults: "+id)
		test.expect(ui.portrait.texture.atlas==NpcAppearance.texture(actor.get_appearance()) and ui.portrait.texture.region==NpcAppearance.region(actor.get_appearance(),0),"dynamic portrait uses its actual appearance: "+id)
		test.expect(ui.panel.get_global_rect().encloses(ui.summary.get_global_rect()),"long dynamic biography scrolls within panel: "+id)
		ui.select_tab("relations")
		test.expect(ui.details.text.contains(info.relationship_reason),"dynamic relationship reason is preserved: "+id)
		ui.close()
	await exchange_tests()
	print("INSPECTTEST checked=%d failures=%s" % [test.checked,str(test.failures)])
	game.get_tree().quit(0 if test.failures.is_empty() else 1)

func exchange_tests() -> void:
	var ui:NpcInspectUI=game.npc_inspect_ui
	var inv:Inventory=game.get_node("/root/Inv")
	game.enter_house(World.HOUSE_DATA[1])
	var person:Npc=game.residents.shop
	person.load_data({})
	await focus(person)
	inv.items={"timber":6,"bandage":1}
	game.player.crystals=100
	game.inspect_person(person)
	await test.click(ui.tabs.items)
	test.expect(ui.items_panel.visible and not ui.details.visible and ui.item_buttons.has("bandage"),"items tab displays real personal supplies")
	test.expect(ui.panel.get_global_rect().encloses(ui.items_panel.get_global_rect()),"inventory controls fit within the panel")
	var coins:=person.carried_crystals
	var stock:=int(person.carried_items.bandage)
	await test.click(ui.item_buttons.bandage)
	test.expect(game.player.crystals==98 and person.carried_crystals==coins+2 and person.carried_items.bandage==stock-1 and inv.get_item_count("bandage")==2,"real buy button transfers both goods and currency")
	await test.click(ui.player_button)
	ui.quantity.value=2
	await game.get_tree().process_frame
	await test.click(ui.item_buttons.timber)
	test.expect(inv.get_item_count("timber")==4 and person.carried_items.timber==2 and game.player.crystals==100 and person.carried_crystals==coins,"real sell button respects selected quantity and pays from recipient wallet")
	var before:=person.save_possessions()
	var inventory_before:=inv.items.duplicate()
	for amount in [0,-1,991]:
		test.expect(not PersonExchange.trade(game,person,"bandage",amount,true),"invalid quantity is rejected: "+str(amount))
	test.expect(not PersonExchange.trade(game,person,"moonlight",1,true),"Gu template cannot be traded as ordinary inventory")
	test.expect(not PersonExchange.trade(game,person,"bandage",stock+1,true),"insufficient item quantity rejects the entire transaction")
	test.expect(before==person.save_possessions() and inventory_before==inv.items and game.player.crystals==100,"rejected requests leave both inventories and money unchanged")
	game.player.crystals=0
	test.expect(not PersonExchange.trade(game,person,"bamboo_wine",1,true) and person.save_possessions()==before,"insufficient player funds preserve seller goods")
	game.player.crystals=100
	person.carried_crystals=0
	test.expect(not PersonExchange.trade(game,person,"timber",1,false) and inv.items==inventory_before,"seller cannot receive invented money from an empty NPC wallet")
	person.carried_crystals=coins
	inv.items.bandage=990
	test.expect(not PersonExchange.trade(game,person,"bandage",1,true) and person.save_possessions()==before,"full player stack rejects purchase without losing stock or currency")
	inv.items.bandage=2
	person.carried_items.timber=990
	test.expect(not PersonExchange.trade(game,person,"timber",1,false) and inv.get_item_count("timber")==4,"full NPC stack rejects sale without removing player goods")
	person.carried_items.timber=2
	person.hostile=true
	test.expect(not PersonExchange.trade(game,person,"bandage",1,true),"hostile living person refuses trade")
	person.hostile=false
	test.expect(not PersonExchange.loot(game,person,"bandage") and person.save_possessions()==before,"living person cannot be looted")
	await focus(person,Vector2(-200,0))
	test.expect(not PersonExchange.trade(game,person,"bandage",1,true),"distant transaction is rejected even with the panel open")
	await focus(person)
	game.save_game()
	ui.close()
	game._load_save()
	test.expect(person.save_possessions()==before and inv.get_item_count("timber")==4 and game.player.crystals==100,"real save reload preserves both sides of completed transactions")
	await focus(person)
	person.take_damage(999,game)
	test.expect(person.dead and person.save_possessions()==before,"death preserves exact existing belongings rather than rolling rewards")
	test.expect(not PersonExchange.trade(game,person,"bandage",1,true),"corpse cannot trade")
	await focus(person,Vector2(-200,0))
	test.expect(not PersonExchange.loot(game,person,"",1,true) and person.save_possessions()==before,"distant corpse cannot be looted")
	await focus(person)
	await pointer(person,true)
	await pointer(person,false)
	await test.click(ui.inventory_button)
	test.expect(ui.active_tab=="items" and ui.loot_all_button.visible and not ui.player_button.visible,"corpse exposes loot controls through actual inspection action")
	var bandages:=inv.get_item_count("bandage")
	await test.click(ui.item_buttons.bandage)
	test.expect(inv.get_item_count("bandage")==bandages+1 and not person.carried_items.has("bandage"),"individual corpse item transfers once")
	inv.items.bamboo_wine=990
	await test.click(ui.loot_all_button)
	test.expect(person.carried_crystals==0 and game.player.crystals==100+coins and person.carried_items=={"bamboo_wine":2},"loot-all collects money and fitting items while leaving full-stack remainder")
	test.expect(not PersonExchange.loot(game,person,"",1,true) and person.carried_items.bamboo_wine==2,"repeated loot with full inventory does not delete leftovers")
	inv.items.bamboo_wine=989
	test.expect(PersonExchange.loot(game,person,"bamboo_wine",2) and inv.get_item_count("bamboo_wine")==990 and person.carried_items.bamboo_wine==1,"partial capacity transfers only available room")
	inv.items.bamboo_wine=988
	PersonExchange.loot(game,person,"",1,true)
	ui.refresh()
	test.expect(ui.loot_all_button.disabled and ui.item_buttons.is_empty(),"empty corpse stays inspectable and shows an exhausted inventory")
	ui.close()
	game._load_save()
	test.expect(person.dead and person.carried_items.is_empty() and person.carried_crystals==0,"looted corpse remains empty after save reload")
	var total:int=game.player.crystals
	game._load_save()
	test.expect(not PersonExchange.loot(game,person,"",1,true) and game.player.crystals==total,"repeated load and loot cannot duplicate money")
	person.load_data({"dead":true,"hp":0})
	test.expect(person.carried_items.is_empty() and person.carried_crystals==0,"legacy corpse without possessions does not generate rewards")
	person.load_data({})
	test.expect(person.carried_items.bandage==2 and person.carried_crystals==24,"legacy living resident receives identity-specific defaults")
	game.exit_house(false)
	game.population.load_data({"stock":{"bandage":2,"bamboo_wine":0,"timber":3,"rubble":1},"people":{}})
	var merchant:WorldPerson=game.population.actors.caravan_merchant
	test.expect(merchant.carried_items.bandage==2 and int(merchant.carried_items.get("bamboo_wine",0))==0,"legacy shared stock migrates into merchant belongings")
	merchant.carried_items.bandage=1
	var saved:Dictionary=game.population.save_data()
	saved.stock={"bandage":8}
	game.population.load_data(saved)
	merchant=game.population.actors.caravan_merchant
	test.expect(merchant.carried_items.bandage==1 and game.population.stock.bandage==1,"personal inventory takes precedence over stale shared stock")
	await focus(merchant)
	merchant.flee_left=2
	test.expect(not PersonExchange.trade(game,merchant,"bandage",1,true),"fleeing person refuses trade")
	merchant.flee_left=0
	var health:=merchant.hp
	var merchant_goods:=merchant.save_possessions()
	merchant.receive_hit(health+1,game.player)
	test.expect(merchant.save_possessions()==merchant_goods,"dynamic person's death preserves personal inventory")
	PersonExchange.loot(game,merchant,"",1,true)
	var remaining:=merchant.save_possessions()
	game.save_game()
	game._load_save()
	merchant=game.population.actors.caravan_merchant
	test.expect(merchant.dead and merchant.save_possessions()==remaining,"dynamic person's loot state survives actual population recreation")
	var porter:WorldPerson=game.population.actors.caravan_porter
	porter.route_index=3
	porter.position=porter.route[3]
	porter.wait_left=0
	game.population.restock_left=0
	game.population.update_person(porter,0.1)
	test.expect(merchant.save_possessions()==remaining,"surviving caravan arriving at market cannot restock its dead merchant")
	# Alt clicks on empty world space never start an attack.
	var empty:=InputEventMouseButton.new()
	empty.position=Vector2(120,120)
	empty.button_index=MOUSE_BUTTON_LEFT
	empty.pressed=true
	empty.alt_pressed=true
	game._unhandled_input(empty)
	test.expect(not game._world_attack_held and not ui.visible,"Alt click on empty space never arms an attack")
