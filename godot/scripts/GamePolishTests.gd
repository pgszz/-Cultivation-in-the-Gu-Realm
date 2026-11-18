class_name GamePolishTests
extends RefCounted

var failures: Array[String]=[]
var checked:=0

func expect(condition:bool, message:String)->void:
	checked+=1
	if not condition:
		failures.append(message)
		print("POLISHTEST FAIL "+message)

func run(game:Node)->void:
	game.start_game()
	game.paused=true
	await game.get_tree().process_frame
	var inv:Inventory=game.get_node("/root/Inv")
	var body:BodyComponent=game.player.body
	expect(game.world.houses.size()==4,"four functional houses")
	for id in game.boss.carried_gu:
		expect(GameData.GU.has(id) and int(GameData.GU[id].rank)==5,"boss carries playable rank-five gu "+id)
	for mountain in World.MOUNTAINS:
		var center: Vector2 = World.mountain_footprint(mountain).get_center()
		expect(game.world.collides(center.x,center.y,12),"mountain base blocks movement")
	_check_routes(game.world)
	for h in World.HOUSE_DATA:
		var entrance:Vector2=h.pos+Vector2(0,40)
		expect(not game.world.collides(entrance.x,entrance.y,12),"door approach clear "+h.id)
		expect(game.world.collides(h.pos.x,h.pos.y-24,12),"house wall blocks movement "+h.id)
		game.player.position=entrance
		expect(game._try_house_interact(),"door interaction "+h.id)
		expect(game.world.in_interior and game.current_house_id==h.id,"entered correct interior "+h.id)
		expect(not game.world.collides(game.player.position.x,game.player.position.y,12),"interior entry is walkable "+h.id)
		expect(game.world.collides(HouseInterior.ORIGIN.x+346,HouseInterior.ORIGIN.y,12),"interior perimeter blocks movement")
		game.player.position=HouseInterior.ORIGIN+Vector2(0,184)
		expect(game._try_house_interact(),"exit interaction "+h.id)
		expect(not game.world.in_interior and game.player.position.distance_to(entrance)<30,"return outside "+h.id)
		game.paused=true
	var house:WorldProp=game.world.houses[0]
	game.world.player_pos=house.position+Vector2(0,-100)
	house._process(1.0)
	expect(house.opacity<0.3,"roof fades behind character")
	game.world.player_pos=house.position+Vector2(0,60)
	house._process(1.0)
	expect(is_equal_approx(house.opacity,1.0),"roof opacity restores")
	for page in ["character","body","inventory","map"]:
		game.open_journal(page)
		await game.get_tree().process_frame
		var visible_pages:=0
		for control in game.journal.pages.values():
			if control.is_visible_in_tree(): visible_pages+=1
		expect(visible_pages==1 and game.journal.active_page==page,"one journal page visible "+page)
		expect(game.paused,"journal pauses combat")
		game.journal.close()
		expect(not game.paused,"journal close resumes")
	game.paused=true
	body.reset_full()
	expect(is_zero_approx(body.part_bleed_rate("leg_l")),"healthy limb has no current bleeding")
	body.apply_hit("leg_l",30)
	expect(body.part_bleed_rate("leg_l")>0 and not body.can_dash(),"leg injury affects movement and bleeding")
	inv.add_item("bandage",2)
	var before:=inv.get_item_count("bandage")
	game.open_journal("body")
	game.body_ui.select_part("leg_l")
	game.inventory_ui._use_item("bandage")
	expect(inv.get_item_count("bandage")==before-1,"one bandage consumed through inventory")
	expect(is_zero_approx(body.part_bleed_rate("leg_l")),"bandaging actually stops bleeding")
	expect(float(body.parts.leg_l.hp)>9,"treatment restores non-destroyed limb")
	body.apply_hit("eye_l",100)
	body.heal_part("eye_l",100)
	expect(bool(body.parts.eye_l.destroyed) and is_zero_approx(float(body.parts.eye_l.hp)),"ordinary treatment does not regrow destroyed eye")
	game.character_ui.refresh()
	expect(game.character_ui.attributes.text.contains("75%"),"character attributes reflect injured eye")
	game.journal.close()
	game.enter_house(World.HOUSE_DATA[0])
	game.paused=true
	game.player.crystals=100
	expect(game.clinic_heal(),"clinic treatment succeeds")
	expect(body.destroyed_count()==0 and is_equal_approx(body.get_accuracy(),1.0),"clinic restores body and accuracy")
	expect(game.player.crystals==80,"clinic charges exactly once")
	expect(not game.clinic_heal() and game.player.crystals==80,"healthy character is not charged")
	game.exit_house()
	game.enter_house(World.HOUSE_DATA[1])
	game.paused=true
	before=inv.get_item_count("bandage")
	expect(game.buy_supply("bandage",6),"shop purchase")
	expect(inv.get_item_count("bandage")==before+1 and game.player.crystals==74,"shop and inventory agree")
	game.player.crystals=0
	expect(not game.buy_supply("bandage",6) and inv.get_item_count("bandage")==before+1,"insufficient funds do not grant item")
	game.exit_house()
	game.paused=true
	game.player.owned.assign(["moon_blade"])
	game._sync_owned_gus()
	var gus:GuManager=game.get_node("/root/Gus")
	var hunger:HungerSystem=game.get_node("/root/Hunger")
	var gu:GuVirtual=gus.owned_gus[0]
	hunger.gu_data[gu.id].current_hunger=30.0
	inv.add_item("grain_normal",2)
	before=inv.get_item_count("grain_normal")
	game.inventory_ui.refresh_inventory()
	game.inventory_ui._use_item("grain_normal")
	expect(inv.get_item_count("grain_normal")==before-1 and hunger.get_hunger(gu.id)>50,"feeding shares real gu hunger")
	hunger.gu_data[gu.id].current_hunger=100
	before=inv.get_item_count("grain_normal")
	game.inventory_ui._use_item("grain_normal")
	expect(inv.get_item_count("grain_normal")==before,"full gu does not waste food")
	game.player.owned.append("green_snake")
	game._sync_owned_gus()
	game.character_ui.select_gu(1)
	game.inventory_ui.refresh_inventory()
	var target: OptionButton = game.inventory_ui.feed_target
	expect(String(target.get_item_metadata(target.selected))==gus.owned_gus[1].id,"character selection becomes inventory feed target")
	game.inventory_ui._select_feed_target(0)
	expect(gus.active_gu==gus.owned_gus[0] and game.character_ui.selected_slot_index==0,"inventory feeding selection updates character")
	game.player.owned.assign(["moon_blade"])
	game._sync_owned_gus()
	body.apply_hit("hand_l",12)
	game.waypoint=World.HOUSE_DATA[0].pos
	game.waypoint_name="回春堂"
	game.player.crystals=42
	game.save_game()
	var saved_hp:float=body.parts.hand_l.hp
	body.reset_full()
	game.player.owned.clear()
	inv.items.clear()
	game.player.crystals=0
	game._load_save()
	expect(is_equal_approx(float(body.parts.hand_l.hp),saved_hp),"injury survives save/load")
	expect(game.player.crystals==42 and inv.get_item_count("grain_normal")==before,"inventory and currency survive save/load")
	expect(gus.owned_gus.size()==game.player.owned.size() and gus.owned_gus[0].template_id=="moon_blade","gu slots survive save/load")
	expect(game.waypoint_name=="回春堂","map marker survives save/load")
	game._load_save()
	expect(game.player.owned.size()==1 and gus.owned_gus.size()==1,"repeated load does not duplicate gu")
	for id in BodyComponent.PARTS:
		expect(not body.part_description(id).is_empty(),"description exists for "+id)
	print("POLISHTEST checked=%d failures=%s" % [checked,str(failures)])
	game.get_tree().quit(0 if failures.is_empty() else 1)

func _check_routes(world: World) -> void:
	var start := Vector2i(16,33)
	var frontier: Array[Vector2i] = [start]
	var visited := {start:true}
	var cursor := 0
	while cursor < frontier.size():
		var cell := frontier[cursor]
		cursor += 1
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = cell+offset
			if visited.has(next) or next.x<1 or next.y<1 or next.x>=GameData.MAP_W-1 or next.y>=GameData.MAP_H-1: continue
			var pos := Vector2(next)*GameData.TILE+Vector2(16,16)
			if world.collides(pos.x,pos.y,12): continue
			visited[next]=true
			frontier.append(next)
	for landmark in World.LANDMARKS:
		expect(visited.has(landmark.pos),"walkable route to "+landmark.name)
	for house in World.HOUSE_DATA:
		var door: Vector2i = Vector2i((house.pos+Vector2(0,40))/GameData.TILE)
		expect(visited.has(door),"walkable route to "+house.name)
