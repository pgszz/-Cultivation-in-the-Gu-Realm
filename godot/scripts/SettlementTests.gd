class_name SettlementTests
extends RefCounted

func run(test: CanonTests) -> void:
	var game:Node=test.game
	var before:=test.checked
	game.village_ui.close()
	game.journal.close()
	game.exit_house(false)
	game.player.body.reset_full()
	game.world.destruction.load_data({})
	for house in SettlementData.HALLS+SettlementData.HOUSES:
		if game.residents.has(house.id): game.residents[house.id].load_data({})
	# 每个商品都要实际买一次；预算随新增供养品计算，另留药堂费用。
	var purchase_budget:=20
	for house in SettlementData.HALLS+SettlementData.HOUSES:
		for price in SettlementData.stock(house.id).values(): purchase_budget+=int(price)
	game.player.crystals=purchase_budget
	game.save_game()
	var baseline:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.SAVE_PATH))
	var inv:Inventory=game.get_node("/root/Inv")
	test.expect(World.HOUSE_DATA.size()==25,"three villages and caves provide 25 usable interiors")
	for district in SettlementData.DISTRICTS:
		var count:=0
		for house in World.HOUSE_DATA:
			if house.get("clan","")==district.id: count+=1
		test.expect(count==9,"district has nine distinct buildings: "+district.id)
	for house in SettlementData.HALLS+SettlementData.HOUSES:
		game.player.position=house.pos+Vector2(0,50)
		test.expect(not game.world.collides(game.player.position.x,game.player.position.y,12) and game.world.zone_at(game.player.position)==house.clan and game.wildlife.is_safe_area(game.player.position),"district doorway is walkable and safe: "+house.id)
		await test.key(KEY_E)
		test.expect(game.world.in_interior and game.current_house_id==house.id,"E enters each district interior: "+house.id)
		game.player.position=HouseInterior.ORIGIN+(Vector2(0,-65) if house.service=="spring" else Vector2(180,-40))
		await test.key(KEY_E)
		test.expect(game.village_ui.visible and game.village_ui.mode==house.id and game.village_ui.title.text==house.name,"E opens the correct local service or information: "+house.id)
		var stock:=SettlementData.stock(house.id)
		for item in stock:
			var amount:=inv.get_item_count(item)
			var money:int=game.player.crystals
			await _click(test,game.village_ui.supply_buttons[item])
			test.expect(inv.get_item_count(item)==amount+1 and game.player.crystals==money-int(stock[item]),"local stock charges once and delivers the correct item: "+house.id+" / "+item)
		if not stock.is_empty():
			var item:String=stock.keys()[0]
			game.residents[house.id].hostile=true
			var money:int=game.player.crystals
			test.expect(not game.buy_supply(item,int(stock[item])) and money==game.player.crystals,"hostility blocks this merchant's purchases: "+house.id)
			game.residents[house.id].hostile=false
			test.expect(not game.buy_supply("moon_petals",0),"local merchants reject unavailable goods and forged prices: "+house.id)
		if house.service=="clinic":
			game.player.body.apply_hit("eye_l",100)
			var money:int=game.player.crystals
			await _click(test,game.village_ui.clinic_button)
			test.expect(game.player.body.total_bleed_rate()==0 and game.player.body.parts.eye_l.destroyed and game.player.crystals==money-2,"local clinic stops bleeding without regrowing an eye: "+house.id)
			test.expect(not game.clinic_heal() and game.player.crystals==money-2,"local clinic does not charge without bleeding: "+house.id)
			game.player.body.reset_full()
		if house.service=="shop":
			var captured:int=game.player.captured.size()
			test.expect(not game.buy_gu("jade_skin") and game.player.captured.size()==captured,"other villages cannot duplicate the ancient village rare Gu stock: "+house.id)
		if SettlementData.can_sell(house.id):
			game.village_ui.close()
			inv.add_item("timber",2)
			var count:=inv.get_item_count("timber")
			var money:int=game.player.crystals
			game.open_journal("inventory")
			game.inventory_ui.selected_id="timber"
			game.inventory_ui.refresh_inventory()
			await test.click(game.inventory_ui.detail_sell)
			test.expect(inv.get_item_count("timber")==count-1 and game.player.crystals==money+1,"inventory sells materials through the current local merchant: "+house.id)
			game.journal.close()
			if house.service=="workshop":
				inv.add_item("rabbit_meat",1)
				test.expect(not game.sell_supply("rabbit_meat"),"workshop only buys building materials: "+house.id)
		game.village_ui.close()
		if house.service in ["home","inn"]:
			var hp:float=game.player.hp
			var yuan:float=game.player.yuan
			game.player.position=HouseInterior.ORIGIN+Vector2(-160,-60)
			await test.key(KEY_E)
			test.expect(game.player.hp==hp and game.player.yuan==yuan and not game.village_ui.visible,"beds offer rest without instant resource restoration: "+house.id)
		if house.service=="spring":
			var money:int=game.player.crystals
			game._try_house_interact()
			test.expect(game.player.crystals==money and game.world.destruction.objects.has("interior:"+house.id+":wall_n") and not game.world.destruction.objects.has("interior:"+house.id+":bed"),"clan spring has cave walls but no free resources or invisible bed: "+house.id)
			await game.get_tree().process_frame
			var furniture_visible:=false
			for child in game.get_children():
				if child is InteriorFixtureVisual and child.is_visible_in_tree(): furniture_visible=true
			test.expect(not furniture_visible,"clan spring renders no ordinary room furniture: "+house.id)
			game.village_ui.close()
		game.player.position=HouseInterior.ORIGIN+Vector2(0,184)
		await test.key(KEY_E)
		test.expect(not game.world.in_interior and game.player.position==house.pos+Vector2(0,50),"E returns to this building's own entrance: "+house.id)
	for data in SettlementData.PEOPLE:
		var person:Npc=game.residents[data.id]
		game.player.position=person.position+Vector2(0,4)
		await game.get_tree().process_frame
		await game.get_tree().process_frame
		test.expect(person in game.active_npcs() and person.visible,"street resident participates in outdoor interaction and combat: "+data.id)
		await test.key(KEY_E)
		test.expect(game.village_ui.visible and game.village_ui.mode=="conversation","street E offers dialogue topics: "+data.id)
		await _click(test,game.village_ui.actions.get_node("Talk_service"))
		test.expect(game.village_ui.visible and game.village_ui.direction_buttons.size()==9,"street resident gives a nine-building directory: "+data.id)
		var destination:=SettlementData.building(data.clan+"_spring")
		await _click(test,game.village_ui.direction_buttons[destination.id])
		test.expect(game.waypoint==destination.pos+Vector2(0,40) and game.waypoint_name==destination.name,"directory marks the selected building's actual door: "+data.id)
		game.village_ui.close()
		person.hostile=true
		await test.key(KEY_E)
		test.expect(not game.village_ui.visible,"hostile street resident refuses directions: "+data.id)
		person.hostile=false
	# New rooms, residents and damage retain separate stable IDs through real reloads.
	game.enter_house(SettlementData.building("bai_inn"))
	game.player.position=HouseInterior.ORIGIN+Vector2(10,50)
	game.strike_world(HouseInterior.ORIGIN+Vector2(-214,-62),1,9999,"none",Vector2.ZERO,-1,false)
	game.residents.bai_clinic.dead=true
	game.residents.bai_clinic.hp=0
	game.residents.xiong_gatekeeper.hostile=true
	game.save_game()
	game._load_save()
	test.expect(game.current_house_id=="bai_inn" and game.player.position==HouseInterior.ORIGIN+Vector2(10,50) and game.outdoor_return==SettlementData.building("bai_inn").pos+Vector2(0,50),"new room save restores its position and doorway")
	test.expect(game.world.destruction.broken("interior:bai_inn:bed") and not game.world.destruction.broken("interior:xiong_inn:bed"),"furniture destruction persists without damaging another clan's room")
	test.expect(not game.service_available("bai_clinic") and game.service_available("xiong_clinic") and game.residents.xiong_gatekeeper.hostile,"resident death and hostility persist independently across clans")
	game.exit_house(false)
	var home:=SettlementData.building("xiong_home_b")
	game.strike_world(home.pos+Vector2(0,-20),1,9999,"none",Vector2.ZERO,-1,false)
	game.player.position=home.pos+Vector2(0,50)
	test.expect(not game._try_house_interact() and game.world.destruction.broken("house:xiong_home_b"),"destroying a new house closes its doorway")
	game.save_game()
	game._load_save()
	test.expect(game.world.destruction.broken("house:xiong_home_b") and not game.world.destruction.broken("house:bai_home_b"),"new building destruction survives reload independently")
	var old:=baseline.duplicate(true)
	old["map_version"]=5
	old["npcs"]={}
	var occupied:Vector2=SettlementData.building("bai_shop").pos+Vector2(0,-20)
	old["position"]=[occupied.x,occupied.y]
	_write_save(game,old)
	game._load_save()
	test.expect(not game.world.collides(game.player.position.x,game.player.position.y,12) and game.player.position.distance_to(occupied)<384,"old outdoor save covered by a new house moves to nearby walkable ground")
	test.expect(game.service_available("bai_clinic") and game.service_available("xiong_clinic") and not game.residents.xiong_gatekeeper.hostile,"old saves without new residents initialize live peaceful residents")
	_write_save(game,baseline)
	game._load_save()
	print("SETTLEMENTTEST checked=%d"%(test.checked-before))

func _click(test: CanonTests, button: Control) -> void:
	var scroll:ScrollContainer=test.game.village_ui.action_scroll
	await test.game.get_tree().process_frame
	await test.game.get_tree().process_frame
	scroll.ensure_control_visible(button)
	await RenderingServer.frame_post_draw
	scroll.ensure_control_visible(button)
	await test.click(button)

func _write_save(game: Node, data: Dictionary) -> void:
	var file:=FileAccess.open(game.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
