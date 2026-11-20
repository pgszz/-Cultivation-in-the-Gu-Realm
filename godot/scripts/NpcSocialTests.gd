class_name NpcSocialTests
extends RefCounted

var game: Node
var test := CanonTests.new()

func frames() -> void:
	await game.get_tree().process_frame
	await game.get_tree().process_frame

func focus(person: Npc, offset: Vector2 = Vector2(-44,16)) -> void:
	game.player.position=person.position+offset
	game._update_camera(0)
	game.camera.reset_smoothing()
	await frames()

func shot(label: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	var err:=game.get_viewport().get_texture().get_image().save_png("res://shot_social_"+label+".png")
	test.expect(err==OK,"saved screenshot "+label)

func reveal_card(id: String) -> bool:
	var sight:NpcSightUI=game.npc_sight_ui
	await frames()
	var people:=sight.visible_people()
	var index:=-1
	for i in people.size():
		if people[i].resident_id==id: index=i
	if index<0: return false
	var destination:=index/sight.page_size
	while sight.page<destination: await test.click(sight.next)
	while sight.page>destination: await test.click(sight.previous)
	await frames()
	return sight.cards.has(id)

func click_card(id: String) -> void:
	var sight:NpcSightUI=game.npc_sight_ui
	if not await reveal_card(id):
		test.expect(false,"visible person has a reachable portrait page "+id)
		return
	await RenderingServer.frame_post_draw
	var motion:=InputEventMouseMotion.new()
	var click_position:Vector2=sight.cards[id].get_global_rect().get_center()
	motion.position=click_position
	motion.global_position=click_position
	game.get_viewport().push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=click_position
		event.global_position=click_position
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed
		event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
		game.get_viewport().push_input(event,true)
	await frames()
	test.expect(game.npc_inspect_ui.visible and game.npc_inspect_ui.person.resident_id==id,"paged card opens exactly "+id)

func run(main: Node) -> void:
	game=main
	test.game=game
	game.set_process(false)
	if Engine.has_meta("social_return_result"):
		var result:Dictionary=Engine.get_meta("social_return_result")
		test.checked=result.checked
		test.failures.assign(result.failures)
		await frames()
		test.expect(not game.running and game.start_screen.visible and not game.npc_sight_ui.visible and game.npc_sight_ui.cards.is_empty(),"returning to actual character selection clears all card references")
		game.start_screen.select_character(result.fresh_id)
		await test.click(game.start_btn)
		test.expect(game.running and game.character_id==result.fresh_id and game.npc.social.history.is_empty() and game.population.actors.caravan_merchant.social.affinity==0,"actual character selection starts an independent social world")
		finish()
		return
	await test.start_character()
	game.hud.minimal=false
	var sight:NpcSightUI=game.npc_sight_ui
	var person:Npc=game.npc
	await focus(person)
	test.expect(sight.visible and sight.cards.has(person.resident_id),"visible outdoor NPC is in the live portrait strip")
	test.expect(game.get_viewport_rect().encloses(sight.get_global_rect()) and not sight.get_global_rect().intersects(game.hud.player_panel.get_global_rect()) and sight.get_global_rect().end.x<=game.get_viewport_rect().size.x-164,"strip fits between actual player HUD and minimap")
	for card:NpcSightCard in sight.cards.values():
		test.expect(game.active_npcs().has(card.person) and game.fog.can_see(card.person.position),"each card belongs to a currently visible scene person")
		var cell:=NpcAppearance.region(card.person.get_appearance(),0)
		test.expect(cell.encloses(card.head.region) and card.head.region.size.y<cell.size.y,"portrait crops the actual actor's head")
	var hp:=person.hp
	await click_card(person.resident_id)
	test.expect(game.npc_inspect_ui.visible and game.npc_inspect_ui.person==person and game.paused,"plain GUI card click opens the matching person and pauses")
	test.expect(person.hp==hp and not person.hostile and not game._world_attack_held,"GUI card click never attacks or arms held attack")
	test.expect(not sight.visible and sight.cards.is_empty(),"strip hides and clears modal targets")
	await test.click(game.npc_inspect_ui.tabs.history)
	test.expect(game.npc_inspect_ui.details.text.contains("尚无经历"),"viewing a person does not fabricate history")
	await test.key(KEY_ESCAPE)
	test.expect(not game.paused and not game._world_attack_held,"closing inspection resumes with no held attack")
	# Real fog radius: exploration alone, zoom and old visible flags cannot expose NPCs.
	await focus(person,Vector2(-500,0))
	game.fog.reveal(person.position,80)
	person.visible=true
	sight.refresh()
	test.expect(not sight.cards.has(person.resident_id),"explored but outside current sight remains absent despite stale visibility")
	game.player.utility_gu.active.vision={"left":30.0,"id":"fixture","template":"night_firefly"}
	await frames()
	test.expect(sight.cards.has(person.resident_id),"scouting expands the actual card visibility radius")
	game.player.utility_gu.active.clear()
	await focus(person,Vector2(-300,0))
	var eyes:Dictionary=game.player.body.parts.duplicate(true)
	game.player.body.parts.eye_l.destroyed=true
	await frames()
	test.expect(not sight.cards.has(person.resident_id),"eye damage contracts card visibility")
	game.player.body.parts=eyes
	await focus(person)
	for zoom in [0.65,1.75]:
		game.set_camera_zoom(zoom)
		await frames()
		test.expect(sight.cards.has(person.resident_id),"zoom does not change logical visibility")
	game.set_camera_zoom(1)
	await test.key(KEY_I)
	test.expect(not sight.visible,"journal hides world cards")
	game.journal.close()
	await test.key(KEY_F1)
	test.expect(not sight.visible,"minimal HUD hides world cards")
	await test.key(KEY_F1)
	game.enter_house(World.HOUSE_DATA[1])
	person=game.residents.shop
	await focus(person)
	test.expect(sight.cards.keys()==["shop"],"indoors lists only the current room occupant")
	game.exit_house(false)
	game.change_layer(1,TerrainLayers.ENTRANCES[0].landing,false)
	await frames()
	test.expect(not sight.visible and sight.cards.is_empty(),"underground never leaks surface people")
	game.change_layer(0,game.npc.position+Vector2(-44,16),false)
	person=game.npc
	await focus(person)
	# First conversation via actual buttons, then repeated action/failed transaction boundaries.
	game.talk_to_person(person)
	var topic:Button=game.village_ui.actions.get_node("Talk_life")
	await test.click(topic)
	test.expect(person.social.met and person.social.affinity==2 and person.social.history.size()>=2,"successful first dialogue updates affection and actual history")
	await test.click(game.village_ui.actions.get_node("Talk_life"))
	test.expect(person.social.affinity==2,"repeating a topic cannot farm affection")
	await test.click(game.village_ui.actions.get_node("Talk_cultivation"))
	test.expect(person.social.label(person)=="熟识" and person.social.affinity==4,"distinct conversation establishes acquaintance")
	var inv:Inventory=game.get_node("/root/Inv")
	inv.items.erase("bandage")
	person.hp=person.max_hp-36
	var before:=person.social.save_data(person)
	NpcConversation.reply(game,person,"care")
	test.expect(before==person.social.save_data(person),"failed care creates no gratitude or event")
	inv.add_item("bandage",3)
	NpcConversation.reply(game,person,"care")
	test.expect(person.hp==person.max_hp-18 and person.social.affinity==12 and inv.get_item_count("bandage")==2,"bandage consumes an item, heals and records gratitude")
	NpcConversation.reply(game,person,"care")
	test.expect(person.hp==person.max_hp and person.social.affinity==12,"repeat treatment can heal but cannot farm immediate gratitude")
	before=person.social.save_data(person)
	NpcConversation.reply(game,person,"care")
	test.expect(before==person.social.save_data(person) and inv.get_item_count("bandage")==1,"uninjured care consumes nothing and records nothing")
	game.village_ui.close()
	person.ensure_possessions()
	game.player.crystals=0
	before=person.social.save_data(person)
	test.expect(not PersonExchange.trade(game,person,"bamboo_wine",1,true) and before==person.social.save_data(person),"failed purchase does not alter social memory")
	game.player.crystals=100
	test.expect(PersonExchange.trade(game,person,"bamboo_wine",1,true) and person.social.affinity==13,"settled trade improves affection")
	test.expect(PersonExchange.trade(game,person,"bamboo_wine",1,false) and person.social.affinity==13,"immediate buy-sell loop has no extra affection")
	var clock_before:float=game.social_time
	game.paused=true
	game._process(500)
	test.expect(game.social_time==clock_before,"paused menus do not advance the social clock")
	game.paused=false
	game.social_time+=301
	test.expect(PersonExchange.trade(game,person,"bamboo_wine",1,true) and person.social.affinity==14,"later genuine trade can improve affection again")
	var saved:=person.social.save_data(person)
	game.save_game()
	person.social.affinity=99
	game._load_save()
	person=game.npc
	test.expect(person.social.save_data(person)==saved,"actual character save restores social history, affection and reward cooldowns")
	await focus(person)
	test.expect(PersonExchange.trade(game,person,"bamboo_wine",1,false) and person.social.affinity==14,"reloading cannot bypass trade reward interval")
	game.inspect_person(person)
	await test.click(game.npc_inspect_ui.tabs.history)
	test.expect(game.npc_inspect_ui.details.text.contains("包扎") and game.npc_inspect_ui.details.text.contains("出售") and game.npc_inspect_ui.details.text.contains("好感 +8"),"history page renders actual help and transactions")
	test.expect(game.npc_inspect_ui.panel.get_global_rect().encloses(game.npc_inspect_ui.talk_button.get_global_rect()) and game.get_viewport_rect().encloses(game.npc_inspect_ui.panel.get_global_rect()),"enlarged inspection fits window and actions remain visible")
	await shot("history")
	game.npc_inspect_ui.close()
	person.take_damage(3,game)
	test.expect(person.hostile and person.social.affinity<=-60 and person.social.history.back().kind=="hostility","player attack causes hostility and records lasting grievance")
	before=person.social.save_data(person)
	NpcConversation.reply(game,person,"life")
	test.expect(before==person.social.save_data(person),"hostile conversation never repairs the relationship")
	person.take_damage(3,game)
	test.expect(before==person.social.save_data(person),"repeated hits do not spam first-grievance events")
	# Real social links and NPC-vs-NPC events, with dead links retained.
	var merchant:WorldPerson=game.population.actors.caravan_merchant
	var escort:WorldPerson=game.population.actors.caravan_guard_a
	var bandit:WorldPerson=game.population.actors.east_bandit_0
	test.expect(merchant.social.relations(merchant).any(func(r:Dictionary): return r.id==escort.resident_id and r.kind=="随行护卫"),"merchant references real escort identity")
	test.expect(escort.social.relations(escort).any(func(r:Dictionary): return r.id==merchant.resident_id and r.kind=="护送对象"),"escort relation has the corresponding direction")
	test.expect(game.npc.social.relations(game.npc).any(func(r:Dictionary): return r.id=="guyue_civil_0" and r.kind=="同寨"),"fixed and roaming people share actual settlement relations")
	merchant.position=game.population.walkable_position(Vector2(816,1008))
	escort.position=merchant.position+Vector2(36,0)
	await focus(merchant)
	merchant.receive_hit(1,bandit)
	test.expect(not merchant.hostile and merchant.social.grudges.has(bandit.resident_id) and bandit.social.grudges.has(merchant.resident_id),"NPC assault creates reciprocal NPC grudges without blaming player")
	var escort_affinity:=escort.social.affinity
	merchant.take_damage(999,game)
	test.expect(merchant.dead and merchant.social.history.any(func(e:Dictionary): return e.kind=="death"),"fatal real damage writes a death record")
	test.expect(escort.social.affinity<escort_affinity and escort.hostile and escort.social.history.any(func(e:Dictionary): return e.kind=="loss"),"nearby escort remembers the killing and turns hostile through existing defense logic")
	test.expect(escort.social.relations(escort).any(func(r:Dictionary): return r.id==merchant.resident_id and r.dead),"relationships retain a deceased partner")
	await frames()
	test.expect(await reveal_card(merchant.resident_id),"visible corpse retains an inspectable card for looting across pages")
	await click_card(merchant.resident_id)
	test.expect(game.npc_inspect_ui.person==merchant,"corpse card opens the matching inventory owner")
	await test.click(game.npc_inspect_ui.tabs.items)
	test.expect(game.npc_inspect_ui.loot_all_button.visible,"corpse card exposes real looting action")
	game.npc_inspect_ui.close()
	var corpse_memory:=merchant.social.save_data(merchant)
	var escort_memory:=escort.social.save_data(escort)
	game._load_save()
	merchant=game.population.actors.caravan_merchant
	escort=game.population.actors.caravan_guard_a
	bandit=game.population.actors.east_bandit_0
	test.expect(merchant.dead and merchant.social.save_data(merchant)==corpse_memory and escort.social.save_data(escort)==escort_memory,"moving people's death, witnesses and grudges persist through the real character reload")
	# Missing fields on old saves and character/world replacement must reset personal memory.
	for target:Npc in [person,merchant]:
		target.load_data({})
		test.expect(target.social.affinity==0 and target.social.history.is_empty() and target.social.grudges.is_empty(),"old save missing social data has safe independent defaults")
	bandit.load_data({})
	test.expect(bandit.social.affinity==-60 and bandit.hostile,"old bandits retain hostile defaults")
	person.load_data({"conversation":{"life":true}})
	await focus(person)
	NpcConversation.reply(game,person,"life")
	test.expect(person.social.affinity==0 and person.social.met,"legacy remembered topics do not become repeatable new affection rewards")
	for i in 60:
		person.social.record(person,"fixture",str(i))
	test.expect(person.social.history.size()==NpcSocial.HISTORY_LIMIT,"history is bounded for long sessions")
	person.load_data({})
	await gallery()
	game.save_game()
	var old:WorldPerson=game.population.actors.caravan_merchant
	game._load_save()
	await focus(game.population.actors.caravan_merchant)
	await reveal_card("caravan_merchant")
	test.expect(sight.cards.has("caravan_merchant") and sight.cards.caravan_merchant.person!=old,"reloading replaces stale card instances with new world actors")
	var fresh_id:String=game.character_saves.create_character("独立社交角色")
	Engine.set_meta("social_return_result",{"checked":test.checked,"failures":test.failures.duplicate(),"fresh_id":fresh_id})
	game.return_to_characters()

func finish() -> void:
	print("SOCIALTEST checked=%d failures=%s" % [test.checked,JSON.stringify(test.failures)])
	game.get_tree().quit(0 if test.failures.is_empty() else 1)

func gallery() -> void:
	# Arrange existing people only for screenshots and overflow input verification.
	game.logs.clear()
	game.zone_banner_time=0
	game.fx.clear_transients()
	var center:Vector2=game.population.walkable_position(Vector2(816,1008))
	var index:=0
	for id in game.population.caravan_ids+["guyue_civil_0","guyue_civil_1","guyue_civil_2","guyue_civil_3","guyue_patrol_0"]:
		var person:WorldPerson=game.population.actors[id]
		person.load_data({})
		person.position=center+Vector2((index%4)*62-95,(index/4)*65)
		person.activity="驻足歇息"
		person.facing=0
		index+=1
	var merchant:WorldPerson=game.population.actors.caravan_merchant
	merchant.social.affinity=34
	merchant.social.met=true
	merchant.social.record(merchant,"journey","抵达古月寨外集市。")
	merchant.social.record(merchant,"trade","向你出售绷带 ×2。","player",1)
	merchant.social.record(merchant,"care","接受你的绷带包扎，伤势得到缓解。","player",8)
	await focus(merchant,Vector2(40,110))
	game.get_viewport().warp_mouse(Vector2(2,2))
	await shot("cards")
	var sight:NpcSightUI=game.npc_sight_ui
	test.expect(not sight.next.disabled,"overflow portraits have a usable next arrow")
	await test.click(sight.next)
	test.expect(sight.page>0 and not game._world_attack_held,"navigation changes the visible card page without attacking")
	var zoom:float=game.zoom_level
	var wheel:=InputEventMouseButton.new()
	wheel.position=sight.get_global_rect().get_center()
	wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed=true
	game.get_viewport().push_input(wheel,true)
	wheel=wheel.duplicate()
	wheel.pressed=false
	game.get_viewport().push_input(wheel,true)
	# Complete the wheel gesture; otherwise Viewport keeps its old mouse target
	# captured and the following synthetic click may hit a different portrait.
	wheel=wheel.duplicate()
	wheel.pressed=false
	game.get_viewport().push_input(wheel,true)
	await frames()
	test.expect(game.zoom_level==zoom and not game._world_attack_held,"scrolling portraits does not zoom or attack the world")
	sight.page=0
	await click_card("caravan_merchant")
	await test.click(game.npc_inspect_ui.tabs.relations)
	test.expect(game.npc_inspect_ui.details.text.contains("随行护卫") and game.npc_inspect_ui.affinity_label.text.contains("友善"),"relations view shows affection and actual party members")
	await shot("relations")
	await test.click(game.npc_inspect_ui.tabs.history)
	await shot("merchant_history")
	game.npc_inspect_ui.close()
