class_name ShangCityTests
extends RefCounted

var game: Node
var city: ShangCity
var test:=CanonTests.new()

func click_action(id: String) -> void:
	await game.get_tree().process_frame
	city.ui.scroll.ensure_control_visible(city.ui.buttons[id])
	await game.get_tree().process_frame
	await test.click(city.ui.buttons[id])

func shot(label: String) -> void:
	print("SHANGTEST render "+label)
	game.logs.clear()
	game._update_camera(0)
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	test.expect(game.get_viewport().get_texture().get_image().save_png("res://shot_shang_"+label+".png")==OK,"rendered "+label)

func approach(id: String) -> void:
	game.player.position=ShangCityData.ORIGIN+Vector2(ShangCityData.building(id).pos)+Vector2(0,65)
	game._update_camera(0)
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()

func run(main: Node) -> void:
	game=main
	city=game.shang_city
	test.game=game
	game.set_process(false)
	await test.start_character()
	game.player.crystals=1000
	game.player.position=Vector2(512,1040)
	var origin:Vector2=game.player.position
	city.ui.open()
	await click_action("EnterCity")
	test.expect(city.active and not city.ui.visible and not game.paused,"actual travel button enters walkable city")
	test.expect(not game.world.on_surface() and game.active_enemies().is_empty() and game.active_npcs().is_empty(),"city isolates Qingmao wildlife and residents")
	test.expect(not game.world.collides(game.player.position.x,game.player.position.y,12),"arrival position is walkable")
	city.seed_value=8189
	var p:Vector2=game.player.position
	game.world.move_body(game.player,50,-30,12)
	test.expect(game.player.position.distance_to(p)>40,"city uses actual world movement")
	await shot("street")
	await test.key(KEY_M)
	test.expect(city.ui.visible and game.paused,"M opens city guide and pauses")
	await shot("guide")
	test.expect(game.get_viewport_rect().encloses(city.ui.panel.get_global_rect()),"city guide fits viewport")
	await test.key(KEY_ESCAPE)
	var cash:int=game.player.crystals
	test.expect(not city.buy_stone(1) and game.player.crystals==cash,"cannot purchase remotely")
	approach("stones")
	await test.key(KEY_E)
	test.expect(city.ui.visible and city.ui.mode=="stones","E opens stone service")
	await shot("stones")
	var id:int=city.offers[0].id
	await click_action("BuyStone_"+str(id))
	test.expect(city.stones.size()==1 and game.player.crystals==cash-12,"purchase consumes real money")
	test.expect(not city.buy_stone(id),"same rock cannot be purchased twice")
	var sealed:Dictionary=city.stone_result(city.stones[0],true)
	var snapshot:Dictionary=game._snapshot()
	city.ui.close()
	test.expect(game._load_save(snapshot),"city snapshot reload accepted")
	test.expect(city.active and city.stones.size()==1 and city.stone_result(city.stones[0],true)==sealed,"unopened stone identity and outcome persist")
	approach("stones")
	var caps:int=game.player.captured.size()
	var inv:Inventory=game.get_node("/root/Inv")
	var rubble:int=inv.get_item_count("rubble")
	var result:=city.open_stone(id,true)
	test.expect(not result.is_empty() and city.stones.is_empty(),"opening consumes exactly one purchased stone")
	test.expect((game.player.captured.size()==caps+1 if result.kind=="live" else inv.get_item_count("rubble")==rubble+1),"opening produces actual unrefined Gu or rubble")
	cash=game.player.crystals
	test.expect(city.open_stone(id,true).is_empty() and cash==game.player.crystals,"cannot claim opening twice")
	# Deterministic outcome boundaries, without consuming or changing production RNG.
	var found:Dictionary={}
	var consistent:=true
	var live_row:Dictionary={}
	for rock_id in range(1,600):
		var row:={"id":rock_id,"tier":2}
		var outcome:=city.stone_result(row,true)
		found[outcome.kind]=true
		if outcome.kind=="live":
			consistent=consistent and city.stone_result(row,false).kind in ["live","broken"]
			if rock_id>city.serial: live_row=row
		if found.size()==4: break
	test.expect(found.has("empty") and found.has("dead") and found.has("live") and found.has("broken"),"all four stone outcomes exist")
	test.expect(consistent,"method changes survival, not sealed content")
	if not live_row.is_empty():
		city.serial=int(live_row.id)
		city.offers=[live_row.duplicate()]
		caps=game.player.captured.size()
		var owned:int=game.get_node("/root/Gus").owned_gus.size()
		test.expect(city.buy_stone(int(live_row.id)),"buy a sealed live-Gu fixture via actual purchase")
		var live:=city.open_stone(int(live_row.id),true)
		test.expect(live.get("kind","")=="live" and game.player.captured.size()==caps+1 and game.get_node("/root/Gus").owned_gus.size()==owned,"live prize enters unrefined list without granting a refined instance")
		result=live
	else: test.expect(false,"live-Gu fixture found")
	cash=game.player.crystals
	# Fail a real write by temporarily selecting a missing profile; resources must roll back.
	id=int(city.offers[0].id)
	var before:Dictionary=city.save_data()
	var character_id:String=game.character_id
	game.character_id="missing_profile"
	test.expect(not city.buy_stone(id) and city.stones==before.stones and city.offers==before.offers and cash==game.player.crystals,"purchase rollback on save failure")
	game.character_id=character_id
	# Extraction must retain both the stone and money if writing the result fails.
	id=int(city.offers[0].id)
	test.expect(city.buy_stone(id),"purchase rollback fixture for extraction")
	before=city.save_data()
	cash=game.player.crystals
	caps=game.player.captured.size()
	rubble=inv.get_item_count("rubble")
	game.character_id="missing_profile"
	test.expect(city.open_stone(id,true).is_empty() and city.stones==before.stones and game.player.crystals==cash and game.player.captured.size()==caps and inv.get_item_count("rubble")==rubble,"extraction rollback preserves stone money and reward")
	game.character_id=character_id
	city.notice=result.text
	city.ui.last_result=result
	city.ui.open("stones")
	city.ui.stone_view.reveal(result)
	await game.get_tree().create_timer(1.6).timeout
	await shot("opened")
	city.ui.close()
	# Actual melee and projectile geometry share the city building collision.
	approach("stones")
	game.player.position=ShangCityData.ORIGIN+Vector2(430,595)
	game.player.atk_cd=0
	game.basic_attack(ShangCityData.ORIGIN+Vector2(430,540))
	test.expect(game.world.destruction.health("shang:stones")<360,"actual attack damages city building")
	var prop:WorldProp=city.props[0]
	game.strike_world(game.player.position,85,1000,"none",Vector2.UP,-1,false,"shang:stones")
	test.expect(prop.broken and prop.collapse_elapsed==0 and not city.available("stones"),"collapse starts and service closes")
	test.expect(not game.world.collides(ShangCityData.ORIGIN.x+430,ShangCityData.ORIGIN.y+540,12),"collapsed building releases collision")
	cash=game.player.crystals
	test.expect(not city.buy_stone(id) and game.player.crystals==cash,"ruined shop cannot transact")
	game.paused=true
	for frame in 24:
		prop.collapse_elapsed=float(frame)/23*CollapseAnimation.DURATION
		prop.queue_redraw()
		await shot("collapse_%02d"%frame)
	print("SHANGTEST restore collapsed city")
	snapshot=game._snapshot()
	game._load_save(snapshot)
	print("SHANGTEST repair and services")
	test.expect(game.world.destruction.broken("shang:stones"),"city damage survives load")
	approach("stones")
	for item in game.world.destruction.repair_cost("shang:stones"): inv.add_item(item,100)
	test.expect(game.repair_world_object("shang:stones"),"actual repair restores city building")
	test.expect(city.available("stones"),"repaired shop resumes service")
	approach("guild")
	inv.add_item("timber",12)
	cash=game.player.crystals
	test.expect(city.deliver("timber") and game.player.crystals==cash+80,"order rewards actual delivery")
	test.expect(not city.deliver("timber"),"order cannot reward twice")
	approach("market")
	test.expect(city.buy_supply("bandage"),"market buys real inventory item")
	var stock_before:int=inv.get_item_count("bandage")
	inv.items.bandage=Inventory.MAX_STACK*10
	cash=game.player.crystals
	test.expect(not city.buy_supply("bandage") and game.player.crystals==cash,"full inventory never consumes payment")
	inv.items.bandage=stock_before
	approach("inn")
	game.player.hp=50
	test.expect(city.rest() and game.player.hp==85,"inn paid recovery")
	approach("arena")
	print("SHANGTEST arena")
	game.player.hp=game.player.max_hp
	city.ui.open("arena")
	await shot("arena_menu")
	cash=game.player.crystals
	await click_action("StartBout")
	test.expect(city.bout and game.player.crystals==cash-20 and is_instance_valid(city.opponent),"real arena button spawns fighting opponent")
	test.expect(not city.finish_bout(true),"cannot claim victory while opponent lives")
	test.expect(not city.leave(),"cannot travel during bout")
	var end:Vector2=game.player.position
	game.world.move_body(game.player,-2000,0,12)
	test.expect(ShangCityData.arena_rect().has_point(game.player.position),"arena confines combatants")
	game.player.position=end
	city.opponent.position=game.player.position+Vector2(40,0)
	city.opponent.tick(0.1,game)
	var health:float=game.player.hp
	city.opponent.tick(0.6,game)
	test.expect(game.player.hp<health,"opponent windup delivers real damage")
	await shot("arena_combat")
	city.opponent.take_damage(1000,game)
	await game.get_tree().process_frame
	test.expect(not city.bout and city.wins==1 and game.player.crystals==cash+30,"defeat settles exactly one victory")
	cash=game.player.crystals
	test.expect(not city.finish_bout(true) and game.player.crystals==cash,"victory cannot pay twice")
	city.ui.close()
	approach("arena")
	game.player.hp=game.player.max_hp
	test.expect(city.start_bout(),"second match starts")
	snapshot=game._snapshot()
	game._load_save(snapshot)
	test.expect(city.active and not city.bout and city.losses==1,"reloading unfinished bout records a single forfeiture")
	snapshot=game._snapshot()
	game._load_save(snapshot)
	test.expect(city.losses==1,"saved forfeiture is not counted twice")
	test.expect(city.leave() and game.player.position.distance_to(origin)<2 and game.world.on_surface(),"return restores exact Qingmao location")
	# Old saves retain all existing behavior and receive an empty city state.
	snapshot=game._snapshot()
	snapshot.erase("shang_city")
	game._load_save(snapshot)
	test.expect(not city.active and city.wins==0 and city.stones.is_empty(),"old saves get safe city defaults")
	var invalid:Dictionary=game._snapshot()
	invalid.shang_city.offers=[{"id":1,"tier":99}]
	test.expect(not game.character_saves._valid_snapshot(invalid),"malformed city data rejected before load")
	invalid=game._snapshot()
	invalid.shang_city.return_pos=["bad",0]
	test.expect(not game.character_saves._valid_snapshot(invalid),"malformed return coordinates rejected")
	game.player.body.reset_full()
	game.player.hp=game.player.max_hp
	await shot("qingmao_ground")
	for sample in [{"name":"forest_ground","pos":Vector2(800,480)},{"name":"moss_ground","pos":Vector2(704,1552)},{"name":"gravel_ground","pos":Vector2(1568,1392)}]:
		game.player.position=game.world.safe_outdoor_position(sample.pos)
		await shot(sample.name)
	# An actual fatal hit inside the arena obeys the character permadeath marker.
	game.paused=false
	game.player.body.reset_full()
	game.player.hp=game.player.max_hp
	game.player.position=Vector2(512,1040)
	test.expect(city.enter(),"revisit city for death boundary")
	approach("arena")
	test.expect(city.start_bout(),"death test begins real match")
	game.player.iframes=0
	game.damage_player(100000)
	test.expect(game.player.dead and game.character_saves.is_dead(game.character_id),"arena lethal damage permanently seals character")
	test.expect(game.character_saves.load_character(game.character_id).is_empty(),"dead arena character cannot be loaded")
	print("SHANGTEST checked=%d failures=%s"%[test.checked,str(test.failures)])
	game.get_tree().quit(0 if test.failures.is_empty() else 1)
