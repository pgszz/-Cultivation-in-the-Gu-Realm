class_name CanonTests
extends RefCounted

var checked:=0
var failures: Array[String]=[]
var game: Node

func expect(condition: bool, message: String) -> void:
	checked+=1
	if not condition:
		failures.append(message)
		print("CANONTEST FAIL "+message)

func key(code: int) -> void:
	for pressed in [true,false]:
		var e:=InputEventKey.new()
		e.keycode=code
		e.pressed=pressed
		game.get_viewport().push_input(e,true)
	await game.get_tree().process_frame

func click(button: Control) -> void:
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	for pressed in [true,false]:
		var e:=InputEventMouseButton.new()
		e.position=button.get_global_rect().get_center()
		e.button_index=MOUSE_BUTTON_LEFT
		e.pressed=pressed
		game.get_viewport().push_input(e,true)
	await game.get_tree().process_frame

func run(main: Node) -> void:
	game=main
	game.set_process(false)
	await click(game.start_btn)
	expect(game.running,"real GUI start click")
	await key(KEY_Q)
	expect(game.journal.active_page=="aperture" and game.journal.visible,"Q opens independent aperture page")
	await click(game.journal.tabs.inventory)
	expect(game.journal.active_page=="inventory","bag tab remains separate")
	await key(KEY_ESCAPE)
	var p:Player=game.player
	var gus:GuManager=game.get_node("/root/Gus")
	var inv:Inventory=game.get_node("/root/Inv")
	var hunger:HungerSystem=game.get_node("/root/Hunger")
	var a:=p.aperture
	expect(is_equal_approx(a.capacity,44) and a.aptitude()=="丙等","C aptitude sea capacity is 44 percent")
	a.essence=0
	a.recover(60)
	expect(is_equal_approx(a.essence,4),"C natural recovery four percent per game hour")
	a.capacity=84
	a.essence=0
	a.recover(60)
	expect(is_equal_approx(a.essence,8),"A natural recovery eight percent per game hour")
	a.capacity=44
	a.essence=44
	expect(a.refine_essence(),"liquor refinement accepted")
	expect(is_equal_approx(a.essence,24) and is_equal_approx(a.refined_essence,5),"liquor consumes ten activation plus ten refinement for five advanced essence")
	var hp:=p.hp
	a.spend(10)
	expect(is_zero_approx(a.refined_essence) and is_equal_approx(a.essence,24) and p.hp==hp,"advanced essence used at twice potency without healing")
	a.essence=19
	expect(not a.refine_essence() and a.essence==19,"insufficient liquor activation cost consumes nothing")
	a.rank=2
	expect(not a.refine_essence(),"one-rank liquor cannot refine rank-two essence")
	a.rank=1
	a.stage=3
	expect(not a.refine_essence(),"liquor does not cross rank boundary")
	a.stage=0
	a.essence=0
	a.refined_essence=6
	a.cultivate(5)
	expect(is_equal_approx(a.refined_essence,3) and is_equal_approx(a.wall_progress,6),"higher-grade essence nourishes wall twice as fast at equal volume flow")
	a.refined_essence=0
	a.wall_progress=0
	var progress:=a.wall_progress
	a.cultivate(100)
	expect(a.wall_progress==progress,"no free cultivation without essence")
	a.essence=44
	a.cultivate(10)
	expect(a.wall_progress>progress and a.essence<44,"cultivation consumes essence to nourish wall")
	a.wall_progress=100
	p.body.apply_hit("eye_l",100)
	var missing:=p.body.destroyed_count()
	var atk:=p.atk
	a.breakthrough()
	expect(a.stage==1 and a.rank==1 and ApertureState.WALLS[a.stage]=="水膜","first breakthrough advances minor stage")
	expect(p.body.destroyed_count()==missing and p.atk==atk,"breakthrough does not regrow body or increase muscles")
	a.stage=3
	a.wall_progress=100
	a.breakthrough()
	expect(a.rank==1,"unimplemented cross-rank advancement is not silently granted")
	p.body.reset_full()
	a.stage=0
	a.wall_progress=0
	a.essence=44
	# Refinement can create more than three independent instances.
	for i in 5:
		p.captured.append({"id":"moon_blade","rank":1,"quality":"normal","progress":100.0})
		game.refine_target=p.captured.size()-1
		game._finish_refine()
	expect(gus.owned_gus.size()==5,"five refined Gu coexist despite only three hotkeys")
	expect(p.skill_slots.size()==3,"hotkeys are a separate fixed array")
	expect(p.vital_gu_id==gus.owned_gus[0].id,"first refined Gu becomes vital Gu")
	var gu:GuVirtual=gus.owned_gus[0]
	var second:GuVirtual=gus.owned_gus[1]
	expect(gu.id!=second.id,"same species instances have unique identity")
	expect(game.move_gu(gu.id,"bag"),"refined Gu can be carried outside")
	expect(game.equipped_gu(0)==null,"removing Gu unbinds activation")
	game.inventory_ui.refresh_inventory()
	var in_bag:=false
	for item in game.inventory_ui._entries:
		if item.id=="owned:"+gu.id: in_bag=true
	expect(in_bag,"external Gu appears in physical bag")
	game.move_gu(gu.id,"aperture")
	game.inventory_ui.refresh_inventory()
	in_bag=false
	for item in game.inventory_ui._entries:
		if item.id=="owned:"+gu.id: in_bag=true
	expect(not in_bag,"Gu inside aperture is absent from physical bag")
	game.move_gu(gu.id,"body")
	game.equip_gu(gu.id,0)
	expect(game.equipped_gu(0)==gu and gu.location=="body","body-resident moonlight can be activated")
	var liquor:=gus.add_gu("jiu_chong")
	p.owned.append("jiu_chong")
	expect(not game.move_gu(liquor.id,"body"),"unsupported body residence is refused")
	hunger.gu_data[gu.id].current_hunger=10
	inv.add_item("moon_petals",2)
	inv.add_item("bamboo_wine",1)
	var wine:=inv.get_item_count("bamboo_wine")
	expect(not inv.use_item("bamboo_wine",gu.id) and inv.get_item_count("bamboo_wine")==wine,"wrong food is rejected without consuming")
	var petals:=inv.get_item_count("moon_petals")
	expect(inv.use_item("moon_petals",gu.id) and inv.get_item_count("moon_petals")==petals-1,"matching food consumes exactly one item")
	expect(is_equal_approx(hunger.get_hunger(gu.id),35),"one moon petal supplies a quarter-day ration")
	hunger.gu_data[second.id].current_hunger=0
	hunger.gu_data[second.id].starving_seconds=HungerSystem.GAME_DAY_SECONDS-1
	game._update_owned_gu(2)
	expect(second.dead and not inv.use_item("moon_petals",second.id),"starvation death cannot be reversed with food")
	game.enter_house(World.HOUSE_DATA[0])
	p.body.apply_hit("eye_l",100)
	p.crystals=60
	expect(game.clinic_heal(),"clinic treats bleeding")
	expect(p.body.parts.eye_l.destroyed,"clinic does not regrow missing eye")
	var money:=p.crystals
	expect(not game.clinic_heal() and p.crystals==money,"clinic does not charge again for an already bandaged loss")
	p.body.tick(300)
	expect(p.body.parts.eye_l.destroyed,"time does not regenerate destroyed anatomy")
	p.body.reset_full()
	game.exit_house()
	progress=a.wall_progress
	var enemy:Enemy=game.enemies[0]
	game.kill_enemy(enemy)
	expect(a.wall_progress==progress and p.crystals==money,"animal kill grants neither cultivation nor currency")
	# No fabricated elemental reactions.
	var target:Enemy=game.enemies[0]
	target.status.wet=3
	hp=target.hp
	game.apply_status(target,"fire")
	expect(target.hp==hp and game.reaction_events.is_empty(),"element tag does not create unsupported reaction damage")
	# Geography and physical access are checked by full collision-aware flood fill.
	expect(WorldLore.REGIONS.size()==5 and WorldLore.SETTLEMENTS.size()==3,"five domains and three Qing Mao settlements")
	expect(game.boss==null,"fabricated Gu king boss is not spawned")
	_check_routes()
	for h in World.HOUSE_DATA:
		game.player.position=h.pos+Vector2(0,40)
		expect(game._try_house_interact() and game.current_house_id==h.id,"enter destination "+h.id)
		expect(not game.world.collides(p.position.x,p.position.y,12),"destination entry is unobstructed "+h.id)
		game.player.position=HouseInterior.ORIGIN+Vector2(0,184)
		expect(game._try_house_interact() and not game.world.in_interior,"exit destination "+h.id)
	game.open_journal("map")
	game.minimap_ui.show_world()
	expect(game.minimap_ui.world_atlas.visible and not game.minimap_ui.atlas.visible,"world reference is distinct from walkable local map")
	game.minimap_ui.set_mode("dimensions")
	expect(game.minimap_ui.dimensions.visible,"dimension reference is available")
	game.journal.close()
	await _check_live_systems()
	# Round trip keeps locations, instance identity, essence quality and old-save bytes.
	var old:=FileAccess.open("user://save.json",FileAccess.WRITE)
	old.store_string("legacy-save-sentinel")
	old.close()
	a.essence=10
	a.refined_essence=4
	game.move_gu(liquor.id,"bag")
	var gu_id:=gu.id
	var liquor_id:=liquor.id
	game.npc.take_damage(999,game)
	game.save_game()
	a.essence=0
	a.refined_essence=0
	game._load_save()
	expect(p.aperture.essence==10 and p.aperture.refined_essence==4,"both essence grades survive save/load")
	expect(gus.get_gu_by_id(gu_id).location=="body" and gus.get_gu_by_id(liquor_id).location=="bag","Gu residence survives save/load")
	expect(gus.owned_gus.size()==7 and game.equipped_gu(0).id==gu_id,"all Gu and explicit shortcut survive save/load")
	expect(game.cave_gu_claimed and game.jade_gu_purchased,"unique cave event and rare shop stock persist")
	expect(inv.get_item_count("timber")>0 and not game.world.destruction.save_data().is_empty(),"physical destruction loot and damaged world persist")
	expect(game.npc.dead,"NPC death remains persistent")
	expect(FileAccess.get_file_as_string("user://save.json")=="legacy-save-sentinel","legacy save is untouched")
	# Real GUI navigation and scroll isolation after loading.
	await key(KEY_Q)
	expect(game.journal.active_page=="aperture","Q still opens aperture after loading")
	await key(KEY_I)
	expect(game.journal.active_page=="inventory","I switches to external bag")
	await key(KEY_ESCAPE)
	await _check_exploration()
	await _check_commissions_and_camps()
	print("CANONTEST checked=%d failures=%s" % [checked,str(failures)])
	game.get_tree().quit(0 if failures.is_empty() else 1)

func pointer(pos: Vector2, button: int) -> void:
	var motion:=InputEventMouseMotion.new()
	motion.position=pos
	game.get_viewport().push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=pos
		event.button_index=button
		event.pressed=pressed
		game.get_viewport().push_input(event,true)
	await game.get_tree().process_frame

func _check_live_systems() -> void:
	var p:Player=game.player
	var inv:Inventory=game.get_node("/root/Inv")
	var gus:GuManager=game.get_node("/root/Gus")
	var a:=p.aperture
	var zoom:float=game.zoom_level
	await pointer(Vector2(640,360),MOUSE_BUTTON_WHEEL_UP)
	expect(game.zoom_level>zoom,"world wheel input changes camera zoom")
	game.set_camera_zoom(50)
	expect(game.zoom_level==1.75,"zoom upper bound")
	game.set_camera_zoom(-50)
	expect(game.zoom_level==0.65,"zoom lower bound")
	game.set_camera_zoom(1)
	await key(KEY_Q)
	await game.get_tree().process_frame
	expect(game.aperture_ui.summary.size.y>=200,"aperture statistics have visible layout height")
	expect(game.aperture_ui.summary.get_global_rect().intersection(game.get_viewport_rect()).size.y>=200,"aperture statistics lie inside viewport")
	await key(KEY_I)
	await pointer(game.inventory_ui.slots[10].get_global_rect().get_center(),MOUSE_BUTTON_WHEEL_DOWN)
	expect(game.zoom_level==1,"inventory wheel cannot zoom world")
	await key(KEY_B)
	await game.get_tree().process_frame
	var diagram:BodyDiagram=game.body_ui.diagram
	await pointer(diagram.global_position+diagram.hit_regions.leg_l.get_center(),MOUSE_BUTTON_LEFT)
	expect(game.body_ui.selected_part=="leg_l","body diagram click selects character left leg")
	await key(KEY_ESCAPE)
	p.body.reset_full()
	var full_radius:float=game.fog.radius_world()
	p.body.apply_hit("eye_l",2)
	expect(game.fog.radius_world()<full_radius,"partial eye damage reduces sight continuously")
	p.body.apply_hit("eye_l",100)
	expect(is_equal_approx(game.fog.radius_world(),full_radius*0.5),"one missing eye halves sight")
	p.body.apply_hit("eye_r",100)
	expect(is_equal_approx(game.fog.radius_world(),full_radius*0.12),"blind player retains nearby awareness only")
	p.body.stop_bleed()
	p.body.apply_hit("hand_l",10)
	p.body.stop_bleed("hand_l")
	var hand:float=p.body.parts.hand_l.hp
	p.body.tick(4)
	expect(p.body.parts.hand_l.hp==hand,"natural recovery waits after injury")
	p.hp=70
	for i in 20: p.tick_status(1,game)
	expect(p.body.parts.hand_l.hp>hand and p.hp>70,"body and general health recover over time")
	expect(p.body.parts.eye_l.destroyed and p.body.parts.eye_l.hp==0,"recovery never rebuilds destroyed eyes")
	p.body.reset_full()
	game.set_camera_zoom(0.65)
	expect(game.fog.radius_world()==full_radius,"zoom does not increase world sight")
	game.set_camera_zoom(1)
	var bandages:=inv.get_item_count("bandage")
	inv.remove_item("bandage",bandages)
	p.materials=99
	p.body.apply_hit("hand_l",10)
	expect(not game.treat_part("hand_l") and p.materials==99,"generic materials cannot substitute for bandages")
	inv.add_item("bandage",bandages)
	expect(game.treat_part("hand_l") and inv.get_item_count("bandage")==bandages-1,"bandage treatment consumes exactly one physical item")
	p.body.reset_full()
	a.stage=0
	a.essence=44
	a.refined_essence=0
	p.cast_cds[0]=0
	game.cast_skill(0)
	expect(is_equal_approx(a.essence,34) and not game.projectiles.is_empty(),"moonlight produces real projectile for ten initial-stage essence")
	a.stage=1
	a.essence=44
	p.cast_cds[0]=0
	game.cast_skill(0)
	expect(is_equal_approx(a.essence,39),"mid-stage moonlight consumes five percent")
	game.projectiles.clear()
	a.stage=0
	a.essence=0
	a.refined_essence=2
	p.captured.append({"id":"moon_blade","rank":1,"quality":"normal","progress":0.0})
	game.refine_target=p.captured.size()-1
	game.refining=true
	game._update_refine(0.5)
	expect(a.refined_essence<2 and p.captured[-1].progress>0,"advanced essence also supports Gu refinement")
	game.refining=false
	game.refine_target=-1
	p.captured.pop_back()
	game.enter_house(World.HOUSE_DATA[1])
	p.crystals=0
	expect(not game.buy_jade_gu(),"rare Gu cannot be bought without currency")
	p.crystals=500
	expect(game.buy_jade_gu() and p.crystals==0 and p.captured[-1].id=="jade_skin","rare purchase delivers unrefined Gu to physical bag")
	expect(not game.buy_jade_gu(),"rare Gu stock cannot be duplicated")
	p.captured[-1].progress=100
	game.refine_target=p.captured.size()-1
	game._finish_refine()
	var jade:GuVirtual=gus.owned_gus[-1]
	game.equip_gu(jade.id,1)
	a.essence=44
	a.refined_essence=0
	p.cast_cds[1]=0
	game.cast_skill(1)
	game._update_owned_gu(2)
	expect(p.jade_guard and a.essence==42,"jade defense continuously drains essence")
	p.hp=100
	p.iframes=0
	game.damage_player(10)
	expect(p.hp==96 and a.essence<42,"jade reduces actual hit and pays extra essence")
	a.essence=0
	game._update_owned_gu(1)
	expect(not p.jade_guard,"jade defense ends when essence runs out")
	inv.add_item("timber",2)
	var wood:=inv.get_item_count("timber")
	expect(game.sell_supply("timber") and inv.get_item_count("timber")==wood-1 and p.crystals==1,"selling exchanges one bag item for physical currency")
	game.exit_house()
	expect(not game.sell_supply("timber"),"selling requires being at the shop")
	game.enter_house(World.HOUSE_DATA[7])
	inv.add_item("bamboo_wine",1)
	var captures_before:=p.captured.size()
	game._claim_cave_gu()
	expect(game.cave_gu_claimed and p.captured.size()==captures_before+1,"wine obtains the cave liquor worm")
	var wine:=inv.get_item_count("bamboo_wine")
	game._claim_cave_gu()
	expect(p.captured.size()==captures_before+1 and inv.get_item_count("bamboo_wine")==wine,"cave event is not repeatable")
	game.exit_house()
	var destruct:DestructionSystem=game.world.destruction
	var tree:Dictionary={}
	for obj in destruct.objects.values():
		if obj.kind=="tree":
			tree=obj
			break
	game.strike_world(tree.rect.get_center(),1,9999,"none",Vector2.ZERO,-1,false)
	expect(destruct.broken(tree.id) and game.world.tile_at(tree.tile.x,tree.tile.y)==GameData.T_GRASS,"destroying tree clears actual collision")
	wood=inv.get_item_count("timber")
	game.strike_world(tree.rect.get_center(),1,9999,"none",Vector2.ZERO,-1,false)
	expect(inv.get_item_count("timber")==wood,"destroyed objects cannot yield materials twice")
	game.enter_house(World.HOUSE_DATA[2])
	var wall:Rect2=destruct.objects["interior:home:wall_w"].rect
	expect(game.world.collides(wall.get_center().x,wall.get_center().y,12),"intact interior wall blocks movement")
	game.strike_world(wall.get_center(),1,9999,"none",Vector2.ZERO,-1,false)
	expect(not game.world.collides(wall.get_center().x,wall.get_center().y,12),"broken interior wall becomes passable")
	p.body.reset_full()
	p.position=HouseInterior.ORIGIN
	a.essence=44
	a.refined_essence=0
	a.wall_progress=0
	game.paused=false
	await key(KEY_J)
	expect(game.meditating,"J starts meditation without combat")
	game._update_meditation(10)
	expect(a.wall_progress>0 and a.essence<44,"meditation trades essence for wall progress")
	game.paused=true
	var progress:=a.wall_progress
	game._update_meditation(10)
	expect(a.wall_progress==progress,"paused menu does not advance meditation")
	game.paused=false
	p.iframes=0
	game.damage_player(2)
	expect(not game.meditating and not game.can_meditate(),"injury interrupts meditation and prevents immediate restart")
	p.body.reset_full()
	p.hp=100
	p.iframes=0
	game.do_dash()
	expect(p.iframes==0,"ordinary running grants no invulnerability")
	game.exit_house()
	p.position=Vector2(800,1100)
	game.npc.position=Vector2(860,1100)
	var npc_hp:float=game.npc.hp
	game.spawn_projectile(p.position,Vector2(300,0),12,"none","player",{})
	game._update_projectiles(0.2)
	expect(game.npc.hp<npc_hp and game.npc.hostile,"actual projectile can wound and provoke NPC")
	game.fog.reveal(p.position,full_radius)

func _check_routes() -> void:
	var start:=Vector2i(16,32)
	var queue: Array[Vector2i]=[start]
	var visited:Dictionary={start:true}
	var index:=0
	while index<queue.size():
		var point:=queue[index]
		index+=1
		for step in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next:Vector2i=point+step
			if next.x<1 or next.y<1 or next.x>=GameData.MAP_W-1 or next.y>=GameData.MAP_H-1 or visited.has(next): continue
			var pos:=Vector2(next)*32+Vector2(16,16)
			if game.world.collides(pos.x,pos.y,12): continue
			visited[next]=true
			queue.append(next)
	for h in World.HOUSE_DATA:
		var door:=Vector2i((h.pos+Vector2(0,50))/32)
		expect(visited.has(door),"walkable route to "+h.id)
	for site in World.EXPLORATION_SITES:
		expect(visited.has(site.pos),"walkable route to wilderness "+site.id)
	expect(visited.size()>9000,"expanded world has substantial traversable area")

func _check_exploration() -> void:
	var p:Player=game.player
	var inv:Inventory=game.get_node("/root/Inv")
	expect(GameData.MAP_W*GameData.MAP_H==19200,"world area expanded to four times 80x60")
	expect(HouseInterior.ORIGIN.x-HouseInterior.BOUNDS.size.x>GameData.MAP_W*32,"interiors stay outside enlarged outdoor world")
	for chunk in game.world.terrain_chunks.values():
		expect(chunk.texture.get_width()<=1024 and chunk.texture.get_height()<=1024,"terrain textures fit 1024 pixel chunks")
	game.fog.load_data([30*80+14,59*80+78],80)
	expect(game.fog.discovered(Vector2(14*32+16,30*32+16)) and game.fog.discovered(Vector2(78*32+16,59*32+16)),"old fog indices migrate with legacy width")
	expect(not game.fog.discovered(Vector2(94*32+16,14*32+16)),"migration does not reveal wrong columns")
	expect(not game.fog.discovered(Vector2(-1,32)),"fog rejects positions outside map")
	for id in GameData.GU_ORDER:
		expect(GuArt.texture(id)!=null and GuArt.texture(id).get_width()>=512 and GuArt.texture(id).resource_path.ends_with(".png"),"painted portrait for "+id)
	await key(KEY_F1)
	expect(game.hud.minimal and not game.hud.quickbar.visible,"F1 hides HUD navigation")
	await key(KEY_F1)
	expect(not game.hud.minimal and game.hud.quickbar.visible,"F1 restores HUD")
	var site:Dictionary=World.EXPLORATION_SITES[0]
	p.position=Vector2(site.pos)*32+Vector2(16,16)
	var wood:=inv.get_item_count("timber")
	expect(game._try_poi_interact() and inv.get_item_count("timber")==wood+3,"free exploration yields materials without story progression")
	game._try_poi_interact()
	expect(inv.get_item_count("timber")==wood+3,"gathering cooldown prevents repeated key farming")
	var camp:Dictionary=World.EXPLORATION_SITES[5]
	p.position=Vector2(camp.pos)*32+Vector2(16,16)
	var wine:=inv.get_item_count("bamboo_wine")
	game._try_poi_interact()
	expect(game.village_ui.visible and game.village_ui.mode=="camp" and inv.get_item_count("bamboo_wine")==wine,"camp opens choices before giving supplies")
	await click(game.village_ui.camp_claim)
	expect(inv.get_item_count("bamboo_wine")==wine+1,"remote camp delivers one physical supply pack")
	await key(KEY_ESCAPE)
	var saved_pos:=p.position
	game.save_game()
	p.position=Vector2(512,1040)
	game._load_save()
	expect(p.position==saved_pos and not game.world.collides(p.position.x,p.position.y,12),"resume exact safe wilderness position")
	game._try_poi_interact()
	expect(game.village_ui.camp_claim.disabled,"claimed camp disables its supply button after reload")
	expect(inv.get_item_count("bamboo_wine")==wine+1,"camp does not duplicate supplies after reload")
	await key(KEY_ESCAPE)
	expect(game.poi_cd.has(site.id) and game.visited_sites.has(site.id),"resource cooldown and discovered site survive reload")
	game.enter_house(World.HOUSE_DATA[2])
	p.position=HouseInterior.ORIGIN+Vector2(10,50)
	game.save_game()
	game.exit_house(false)
	game._load_save()
	expect(game.world.in_interior and game.current_house_id=="home" and p.position==HouseInterior.ORIGIN+Vector2(10,50),"indoor position and house restore")
	game.exit_house(false)
	# Open real UI and inspect picture/detail wiring and panel bounds.
	await key(KEY_I)
	var capture_index:=-1
	for i in game.inventory_ui._entries.size():
		if String(game.inventory_ui._entries[i].id).begins_with("capture:"):
			capture_index=i
			break
	if capture_index>=0:
		await click(game.inventory_ui.slots[capture_index])
		expect(game.inventory_ui.portrait.visible and game.inventory_ui.portrait.texture!=null,"bag selection shows Gu portrait")
	var viewport:Rect2=game.get_viewport_rect()
	expect(viewport.encloses(game.journal.panel.get_global_rect()),"compact journal remains inside viewport")
	expect(game.journal.panel.size.x<=1080 and game.journal.panel.size.y<=580,"journal has bounded readable size")
	await key(KEY_ESCAPE)
	await key(KEY_K)
	expect(game.compendium_ui.visible and game.compendium_ui.portrait.texture!=null,"K opens illustrated compendium")
	for id in GameData.GU_ORDER:
		if not p.discovered.has(id): p.discovered.append(id)
	game.compendium_ui.refresh()
	for id in GameData.GU_ORDER:
		await click(game.compendium_ui._buttons[id])
		expect(game.compendium_ui.portrait.texture==GuArt.texture(id) and game.compendium_ui.detail.text.contains("供养与取得"),"compendium button shows portrait and care for "+id)
	await key(KEY_ESCAPE)

func _click_order(id: String) -> void:
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	var button:Button=game.village_ui.order_buttons[id]
	game.village_ui.action_scroll.ensure_control_visible(button)
	await click(button)

func _check_commissions_and_camps() -> void:
	var p:Player=game.player
	var inv:Inventory=game.get_node("/root/Inv")
	var ledger:CommissionLedger=game.commissions
	var ui:VillageUI=game.village_ui
	# The map exposes progress, but all transactions still require a living service NPC.
	game.open_journal("map")
	game.minimap_ui.set_mode("notes")
	expect(game.minimap_ui.notes.visible and game.minimap_ui.notes.text.contains("东麓竹坳") and game.minimap_ui.notes.text.contains("补给已领取"),"travel notes reflect real visits and claimed camp supplies")
	game.journal.close()
	ui.show_commissions()
	expect(ui.order_buttons.timber.disabled and not ledger.accept("timber",game),"remote ledger cannot accept commissions")
	ui.close()
	game.enter_house(World.HOUSE_DATA[1])
	inv.remove_item("timber",inv.get_item_count("timber"))
	ui.show_commissions()
	await _click_order("timber")
	expect(ledger.state("timber").accepted and ui.order_buttons.timber.disabled,"real accept button records order and waits for materials")
	var money:int=p.crystals
	var petals:int=inv.get_item_count("moon_petals")
	expect(not ledger.submit("timber",game) and p.crystals==money and inv.get_item_count("moon_petals")==petals,"insufficient materials cannot grant or consume anything")
	inv.add_item("timber",8)
	ui.show_commissions()
	await _click_order("timber")
	expect(inv.get_item_count("timber")==2 and p.crystals==money+10 and inv.get_item_count("moon_petals")==petals+10,"real submit button exchanges exactly six wood for promised rewards")
	expect(not ledger.submit("timber",game) and not ledger.accept("timber",game) and p.crystals==money+10,"repeat click and cooldown cannot duplicate rewards")
	var cooldown:float=ledger.state("timber").remaining
	game._process(1)
	expect(ledger.state("timber").remaining==cooldown,"commission menu pauses cooldown")
	ui.close()
	p.body.reset_full()
	p.hp=p.max_hp
	game._process(1)
	expect(ledger.state("timber").remaining<cooldown,"ordinary gameplay advances commission cooldown")
	game.save_game()
	cooldown=ledger.state("timber").remaining
	ledger.states.clear()
	game._load_save()
	expect(ledger.state("timber").completed==1 and is_equal_approx(ledger.state("timber").remaining,cooldown),"commission completion and remaining cooldown survive reload")
	ledger.tick(301)
	expect(ledger.accept("timber",game),"repeatable commission becomes available after gameplay cooldown")
	game.residents.shop.hostile=true
	expect(not ledger.accept("rubble",game) and not ledger.submit("timber",game),"hostile service NPC cannot take commission transactions")
	game.residents.shop.hostile=false
	game.residents.shop.dead=true
	expect(not ledger.accept("rubble",game),"dead service NPC cannot give commissions")
	game.residents.shop.dead=false
	game.exit_house(false)
	game.enter_house(World.HOUSE_DATA[3])
	expect(ledger.accept("rubble",game),"academy also accepts commissions")
	inv.add_item("timber",6)
	game.exit_house(false)
	var wood:int=inv.get_item_count("timber")
	money=p.crystals
	expect(not ledger.submit("timber",game) and inv.get_item_count("timber")==wood and p.crystals==money,"completed material order cannot transact from wilderness")
	# Prior real exploration counts, while one missing stop prevents completion.
	game.enter_house(World.HOUSE_DATA[1])
	ledger.accept("east_trail",game)
	game.visited_sites.bamboo_hollow=true
	game.visited_sites.river_ford=true
	game.visited_sites.erase("central_camp")
	expect(not ledger.ready("east_trail",game) and not ledger.submit("east_trail",game),"survey requires every named stop")
	var next:Dictionary=ledger.next_site("east_trail",game)
	ui.show_commissions()
	ui._mark_order(next)
	expect(game.waypoint==Vector2(next.pos)*32+Vector2(16,16) and next.id=="central_camp","survey points to the next unvisited stop")
	ui.close()
	game.exit_house(false)
	p.position=Vector2(next.pos)*32+Vector2(16,16)
	game._try_poi_interact()
	expect(ledger.ready("east_trail",game),"actual camp interaction completes survey without combat")
	ui.close()
	game.enter_house(World.HOUSE_DATA[1])
	ui.show_commissions()
	money=p.crystals
	var wine:int=inv.get_item_count("bamboo_wine")
	await _click_order("east_trail")
	expect(p.crystals==money+45 and inv.get_item_count("bamboo_wine")==wine+2,"survey GUI grants exact one-time rewards")
	ui.close()
	game.save_game()
	game._load_save()
	expect(not ledger.accept("east_trail",game) and not ledger.submit("east_trail",game) and p.crystals==money+45,"completed survey cannot reward again after reload")
	game.exit_house(false)
	# Camp treatment consumes real bandages and never regrows a destroyed eye.
	var camp:Dictionary=World.EXPLORATION_SITES[8]
	var bandages:int=inv.get_item_count("bandage")
	expect(not game.claim_camp_supplies(camp.id) and inv.get_item_count("bandage")==bandages,"camp supplies cannot be claimed from far away")
	p.position=Vector2(camp.pos)*32+Vector2(16,16)
	game._try_poi_interact()
	await click(ui.camp_claim)
	expect(inv.get_item_count("bandage")==bandages+2 and not game.claim_camp_supplies(camp.id),"second camp has its own one-time supply pack")
	p.body.reset_full()
	p.body.apply_hit("eye_l",100)
	p.body.apply_hit("hand_r",5)
	bandages=inv.get_item_count("bandage")
	await click(ui.camp_treat)
	expect(inv.get_item_count("bandage")==bandages-1 and p.body.part_bleed_rate("eye_l")==0,"camp button prioritizes the bleeding wound and consumes one bandage")
	expect(p.body.parts.eye_l.destroyed and p.body.parts.eye_l.hp==0,"camp bandaging cannot regenerate destroyed anatomy")
	p.body.reset_full()
	bandages=inv.get_item_count("bandage")
	expect(not game.field_bandage() and inv.get_item_count("bandage")==bandages,"healthy camp visitor does not waste a bandage")
	p.body.apply_hit("hand_l",10)
	inv.remove_item("bandage",bandages)
	expect(not game.field_bandage(),"camp treatment still needs physical bandages")
	ui.close()
	p.body.reset_full()
	var legacy:=CommissionLedger.new()
	legacy.load_data({})
	expect(not legacy.state("timber").accepted and legacy.state("timber").completed==0,"older saves initialize an empty optional ledger")
