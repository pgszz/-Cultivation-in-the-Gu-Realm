class_name GuExpansionTests
extends RefCounted

func cast(game: Node, gu: GuVirtual, slot: int = 0) -> void:
	game.equip_gu(gu.id,slot)
	game.player.cast_cds[slot]=0
	game.cast_skill(slot)

func aim_at(game: Node, position: Vector2) -> void:
	game.shake=0.0
	game.set_camera_zoom(1.0)
	game._update_camera(0)
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	await game.get_tree().process_frame
	var event:=InputEventMouseMotion.new()
	event.position=game.get_viewport().get_canvas_transform()*position
	event.global_position=event.position
	# get_global_mouse_position polls the window cursor, not only dispatched events.
	game.get_viewport().warp_mouse(event.position)
	await RenderingServer.frame_post_draw
	game.get_viewport().push_input(event,true)

func run(suite: RefCounted) -> void:
	var start:int=suite.checked
	var failures:int=suite.failures.size()
	var game:Node=suite.game
	var p:Player=game.player
	var gus:GuManager=game.get_node("/root/Gus")
	var hunger:HungerSystem=game.get_node("/root/Hunger")
	var inv:Inventory=game.get_node("/root/Inv")
	var ui:VillageUI=game.village_ui
	game.close_refine()
	game.journal.close()
	game.compendium_ui.hide()
	p.body.reset_full()
	p.hp=p.max_hp
	p.dead=false
	p.jade_guard=false
	p.gu_effects.load_data({})
	p.boar_cultivation.load_data({})
	p.aperture.stage=0
	p.aperture.essence=44
	p.aperture.refined_essence=0
	game.world.destruction.load_data({})
	game.residents.shop.dead=false
	game.residents.shop.hostile=false
	game.enter_house(World.HOUSE_DATA[1])
	var instances:Dictionary={}
	for id in GameData.EXPANSION_GU:
		game.gu_shop_purchased.erase(id)
		p.crystals=int(GameData.GU_SHOP[id])-1
		var count:int=p.captured.size()
		suite.expect(not game.buy_gu(id) and p.captured.size()==count,"insufficient coins leave new Gu stock intact: "+id)
		p.crystals=int(GameData.GU_SHOP[id])+1
		ui.show_service("shop")
		ui.shop_filter.select(1)
		ui._filter_shop()
		await game.get_tree().process_frame
		await game.get_tree().process_frame
		ui.action_scroll.ensure_control_visible(ui.gu_buttons[id])
		await suite.click(ui.gu_buttons[id])
		suite.expect(p.captured.size()==count+1 and p.captured[-1].id==id and p.crystals==1,"filtered real shop purchase reaches "+id)
		suite.expect(ui.gu_buttons[id].disabled and not game.buy_gu(id),"new Gu has persisted single-stock identity: "+id)
		var food:String=GameData.GU[id].preferred_food
		ui.shop_filter.grab_focus()
		ui.shop_filter.select(2)
		ui._filter_shop()
		await game.get_tree().process_frame
		await game.get_tree().process_frame
		# Filtering resizes the scroll viewport; settle layout before clicking its last rows.
		await RenderingServer.frame_post_draw
		ui.action_scroll.ensure_control_visible(ui.supply_buttons[food])
		await RenderingServer.frame_post_draw
		ui.action_scroll.ensure_control_visible(ui.supply_buttons[food])
		await RenderingServer.frame_post_draw
		suite.expect(ui.action_scroll.get_global_rect().encloses(ui.supply_buttons[food].get_global_rect()),"filtered supply is fully reachable: "+id)
		var previous:int=inv.get_item_count(food)
		await suite.click(ui.supply_buttons[food])
		suite.expect(inv.get_item_count(food)==previous+1 and p.crystals==0,"actual supply button delivers dedicated ration: "+id)
		ui.close()
		p.captured[-1].progress=100
		game.refine_target=p.captured.size()-1
		game._finish_refine()
		var gu:GuVirtual=gus.owned_gus[-1]
		instances[id]=gu
		suite.expect(gu.template_id==id and gu.location=="aperture" and hunger.gu_data.has(gu.id),"new Gu refinement creates independent aperture resident: "+id)
		hunger.gu_data[gu.id].current_hunger=20
		inv.add_item("moon_petals",1)
		var petals:int=inv.get_item_count("moon_petals")
		suite.expect(not inv.use_item("moon_petals",gu.id) and inv.get_item_count("moon_petals")==petals,"unmatched food cannot feed "+id)
		suite.expect(inv.use_item(food,gu.id) and hunger.get_hunger(gu.id)==100 and inv.get_item_count(food)==previous,"matching ration consumed exactly once for "+id)
	for id in ["beast_skin","stone_skin","copper_skin","iron_skin"]:
		p.aperture.essence=44
		p.body.reset_full()
		p.hp=100
		cast(game,instances[id])
		p.iframes=0
		game.damage_player(10)
		var sk:Dictionary=GameData.GU[id].skill
		suite.expect(is_equal_approx(p.hp,100-maxf(1,round(10*(1-float(sk.reduction))))) and is_equal_approx(p.aperture.essence,44-10*float(sk.hit_cost)),"actual hit uses "+id+" mitigation and impact essence")
		var energy:float=p.aperture.essence
		game._update_owned_gu(1)
		suite.expect(is_equal_approx(p.aperture.essence,energy-float(sk.upkeep)),"continuous upkeep for "+id)
		p.aperture.essence=0
		p.iframes=0
		var health:float=p.hp
		game.damage_player(10)
		suite.expect(p.gu_effects.guard_id=="" and p.hp==health-10,"unfunded "+id+" collapses before mitigation")
	p.body.reset_full()
	p.hp=100
	p.aperture.essence=44
	var jade:=gus.add_gu("jade_skin")
	cast(game,jade)
	cast(game,instances.copper_skin,1)
	suite.expect(not p.jade_guard and p.gu_effects.guard_id==instances.copper_skin.id,"copper replaces jade instead of stacking")
	cast(game,jade)
	suite.expect(p.jade_guard and p.gu_effects.guard_id=="","jade replaces active new skin")
	cast(game,instances.iron_skin,1)
	game.move_gu(instances.iron_skin.id,"bag")
	suite.expect(p.gu_effects.guard_id=="","taking active skin outside ends protection immediately")
	game.move_gu(instances.iron_skin.id,"aperture")
	cast(game,instances.stone_skin)
	var dead_id:String=instances.stone_skin.id
	hunger.gu_data[dead_id].current_hunger=0
	hunger.gu_data[dead_id].starving_seconds=1439
	game._update_owned_gu(2)
	suite.expect(instances.stone_skin.dead and p.gu_effects.guard_id=="","starving active skin removes real defense")
	p.aperture.essence=19
	var power:float=p.melee_attack()
	cast(game,instances.brute_longhorn)
	suite.expect(p.gu_effects.brute_left==0 and p.aperture.essence==19,"brute requires full two-tenths initial essence")
	p.aperture.essence=44
	cast(game,instances.brute_longhorn)
	suite.expect(p.melee_attack()==power+22 and p.aperture.essence==24,"brute temporarily increases actual melee with canonical activation cost")
	var strain:float=p.gu_effects.strain
	cast(game,instances.brute_longhorn)
	suite.expect(p.aperture.essence==24 and p.gu_effects.strain==strain,"brute cannot stack or charge twice while active")
	var moon:=gus.add_gu("moon_blade")
	p.light_support_id=""
	game.projectiles.clear()
	cast(game,moon,1)
	suite.expect(game.projectiles[-1].dmg==26,"brute never boosts moon projectile")
	game._update_owned_gu(5)
	suite.expect(p.melee_attack()==power and p.gu_effects.brute_left==0,"brute expiry restores physical attack without changing permanent progress")
	p.aperture.essence=44
	p.aperture.stage=1
	cast(game,instances.brute_longhorn)
	suite.expect(p.aperture.essence==34,"brute middle-stage activation is one-tenth")
	game.move_gu(instances.brute_longhorn.id,"bag")
	suite.expect(p.melee_attack()==power,"moving active brute Gu outside cancels temporary force")
	game.move_gu(instances.brute_longhorn.id,"aperture")
	p.aperture.stage=0
	p.aperture.essence=44
	p.gu_effects.strain=70
	var arm:float=p.body.parts.hand_l.hp
	cast(game,instances.brute_longhorn)
	suite.expect(p.body.parts.hand_l.hp<arm and p.body.pain>0,"excessive brute use actually injures body parts")
	p.gu_effects.cancel(instances.brute_longhorn.id)
	p.body.reset_full()
	p.gu_effects.stamina=100
	p.dash_cd=0
	game.do_dash()
	suite.expect(p.gu_effects.stamina==75 and p.dash_t>0,"ordinary dash spends real stamina")
	p.aperture.essence=44
	cast(game,instances.yellow_camel)
	p.dash_cd=0
	game.do_dash()
	suite.expect(p.gu_effects.stamina==65 and p.gu_effects.endurance_left==15 and p.aperture.essence==36,"yellow camel reduces actual dash consumption")
	cast(game,instances.yellow_camel)
	suite.expect(p.aperture.essence==36,"endurance cannot stack or waste essence while active")
	game._update_owned_gu(15)
	suite.expect(p.gu_effects.endurance_left==0 and p.gu_effects.stamina==100,"endurance expires and resting restores capped stamina")
	p.gu_effects.stamina=5
	p.dash_cd=0
	p.dash_t=0
	game.do_dash()
	suite.expect(p.dash_t==0 and p.gu_effects.stamina==5,"exhausted dash is rejected without partial spending")
	p.gu_effects.stamina=100
	p.aperture.essence=44
	p.iframes=0
	p.position=HouseInterior.ORIGIN+Vector2(0,60)
	await aim_at(game,p.position+Vector2(180,0))
	var from:Vector2=p.position
	cast(game,instances.dragon_cricket)
	var moved:float=from.distance_to(p.position)
	suite.expect(moved>=8 and moved<=112.01 and not game.world.collides(p.position.x,p.position.y,p.radius),"cricket actual leap moves within collision-limited range")
	suite.expect(p.aperture.essence==38 and p.gu_effects.stamina==80 and p.iframes==0,"cricket charges actual essence and stamina without invincibility")
	from=p.position
	cast(game,instances.dragon_cricket,1)
	suite.expect(p.position==from and p.aperture.essence==38,"switching hotkeys cannot bypass leap cooldown")
	p.gu_effects.leap_cd=0
	p.body.parts.leg_l.hp=1
	cast(game,instances.dragon_cricket)
	suite.expect(p.position==from and p.aperture.essence==38,"cricket cannot bypass seriously injured legs")
	p.body.reset_full()
	p.gu_effects.stamina=0
	cast(game,instances.dragon_cricket)
	suite.expect(p.position==from and p.aperture.essence==38,"cricket needs stamina before charging essence")
	p.gu_effects.stamina=100
	p.aperture.essence=0
	await aim_at(game,p.position+Vector2(-180,0))
	cast(game,instances.dragon_cricket)
	suite.expect(p.position==from and p.gu_effects.stamina==100,"cricket cannot spend stamina when essence is insufficient")
	p.aperture.essence=44
	p.gu_effects.stamina=37
	# Stand flush against the east wall; a blocked leap must not consume either resource.
	p.position=HouseInterior.ORIGIN+Vector2(326,0)
	p.gu_effects.leap_cd=0
	await aim_at(game,p.position+Vector2(16,0))
	var blocked:Vector2=p.position
	suite.expect(game.world.collides(blocked.x+4,blocked.y,p.radius,true),"blocked leap fixture faces intact wall")
	cast(game,instances.dragon_cricket)
	if p.position!=blocked: print("LEAP_DIAGNOSTIC from=%s to=%s mouse=%s"%[blocked,p.position,game.get_global_mouse_position()])
	suite.expect(p.position==blocked and p.aperture.essence==44 and p.gu_effects.stamina==37,"cricket rejects blocked wall leap before charging resources")
	p.gu_effects.strain=72
	cast(game,instances.yellow_camel)
	game.open_journal("character")
	var seconds:float=p.gu_effects.endurance_left
	game._process(20)
	suite.expect(p.gu_effects.endurance_left==seconds,"menu pauses new Gu durations and physical recovery")
	suite.expect(game.character_ui.attributes.text.contains("体力") and game.character_ui.attributes.text.contains("蛮力负担"),"character page exposes stamina and muscle strain")
	game.journal.close()
	game.save_game()
	game._load_save()
	suite.expect(p.gu_effects.stamina==37 and p.gu_effects.strain==72 and p.gu_effects.endurance_left==0,"save restores physical resources but not active Gu effects")
	for id in GameData.EXPANSION_GU:
		suite.expect(game.gu_shop_purchased.has(id) and gus.get_gu_by_id(instances[id].id)!=null,"new stock and independent Gu survive reload: "+id)
	var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.SAVE_PATH))
	saved.erase("gu_physical")
	var file:=FileAccess.open(game.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(saved))
	file.close()
	game._load_save()
	suite.expect(p.gu_effects.stamina==100 and p.gu_effects.strain==0,"old version-seven saves get safe physical defaults")
	p.discovered.assign(GameData.GU_ORDER)
	game.compendium_ui.refresh()
	game.compendium_ui.show()
	game.compendium_ui.search.text="蛐蛐"
	game.compendium_ui._apply_filter()
	await game.get_tree().process_frame
	suite.expect(game.compendium_ui._buttons.dragon_cricket.visible and not game.compendium_ui._buttons.copper_skin.visible,"compendium search filters all thirteen entries")
	await suite.click(game.compendium_ui._buttons.dragon_cricket)
	suite.expect(game.compendium_ui.portrait.texture==GuArt.texture("dragon_cricket"),"filtered cricket selection displays its actual generated portrait")
	game.compendium_ui.search.text="不存在的蛊"
	game.compendium_ui._apply_filter()
	suite.expect(game.compendium_ui.portrait.texture==null and game.compendium_ui.detail.text.contains("没有匹配"),"empty search does not retain unrelated portrait")
	game.compendium_ui.search.clear()
	game.compendium_ui.category.select(2)
	game.compendium_ui._apply_filter()
	suite.expect(game.compendium_ui._buttons.iron_skin.visible and not game.compendium_ui._buttons.brute_longhorn.visible,"defense category excludes force Gu")
	game.compendium_ui.category.select(0)
	game.compendium_ui._apply_filter()
	game.compendium_ui.hide()
	print("GUEXPANSIONTEST checked=%d failures=%d" % [suite.checked-start,suite.failures.size()-failures])
