class_name ShangCity
extends Node2D

var game: Node
var active := false
var visited := false
var return_pos := Vector2(512,1040)
var props: Array[WorldProp]=[]
var opponent: ShangOpponent
var ui: ShangCityUI
var seed_value := 0
var serial := 0
var offers: Array=[]
var stones: Array=[]
var ledger: Array=[]
var delivered: Dictionary={}
var wins := 0
var losses := 0
var bout := false
var bout_level := 0
var bout_time := 0.0
var retry_time := 0.0
var notice := ""
var guide := ""
var panorama: Texture2D
var ground: Sprite2D

func setup(main: Node) -> void:
	game=main
	game.add_child(self)
	z_index=-5
	visible=false
	panorama=load("res://assets/shang_city/panorama.png")
	ground=Sprite2D.new()
	# GL Compatibility shares sampling state for the sprite and the pavement uniform.
	ground.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	ground.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ground.texture=load("res://assets/shang_city/paving.png")
	ground.centered=false
	ground.position=ShangCityData.ORIGIN
	ground.scale=ShangCityData.SIZE/ground.texture.get_size()
	ground.show_behind_parent=true
	var surface:=ShaderMaterial.new()
	surface.shader=load("res://assets/shang_city/ground.gdshader")
	for key in ["paving","earth","courtyard","arena_floor"]:
		surface.set_shader_parameter(key,load("res://assets/shang_city/"+key+".png"))
	ground.material=surface
	add_child(ground)
	for b in ShangCityData.BUILDINGS:
		var prop:=WorldProp.new()
		prop.world=game.world
		prop.kind="house"
		prop.title=b.name
		prop.position=ShangCityData.ORIGIN+Vector2(b.pos)
		prop.draw_size=b.size
		prop.art_id="house:"+String(b.art)
		prop.visible=false
		game.add_child(prop)
		game.world.destruction.register("shang:"+b.id,"house",ShangCityData.body_rect(b.id),360,1.4,prop)
		props.append(prop)
	ui=ShangCityUI.new()
	ui.city=self
	game.ui_layer.add_child(ui)

func save_data() -> Dictionary:
	return {"visited":visited,"active":active,"return_pos":[return_pos.x,return_pos.y],"seed":seed_value,"serial":serial,"offers":offers.duplicate(true),"stones":stones.duplicate(true),"ledger":ledger.duplicate(true),"delivered":delivered.duplicate(true),"wins":wins,"losses":losses,"bout":bout,"bout_level":bout_level}

func load_data(data: Dictionary) -> void:
	visited=bool(data.get("visited",false))
	seed_value=maxi(0,int(data.get("seed",0)))
	serial=maxi(0,int(data.get("serial",0)))
	offers=data.get("offers",[]).duplicate(true)
	stones=data.get("stones",[]).duplicate(true)
	ledger=data.get("ledger",[]).duplicate(true)
	delivered=data.get("delivered",{}).duplicate(true)
	wins=maxi(0,int(data.get("wins",0)))
	losses=maxi(0,int(data.get("losses",0)))
	bout=false
	if bool(data.get("bout",false)):
		losses+=1
		notice="上次未完成的演武按弃权记负，不重复收取报名费。"
	var raw:Array=data.get("return_pos",[512,1040])
	return_pos=Vector2(float(raw[0]),float(raw[1])) if raw.size()==2 else Vector2(512,1040)

func _restock() -> void:
	if seed_value==0: seed_value=randi_range(1,2000000000)
	for i in 6:
		serial+=1
		offers.append({"id":serial,"tier":i%3})

func enter(resume: bool = false, saved_pos: Vector2 = Vector2.ZERO) -> bool:
	if active or game.player.dead: return false
	if not resume:
		if not game.world.on_surface() or not game.projectiles.is_empty(): return fail("请先回到青茅山地表的安全位置再启程。")
		for e in game.active_enemies():
			if not e.dead and e.position.distance_to(game.player.position)<350: return fail("附近有敌人，暂不能随商队出发。")
		for person in game.active_npcs():
			if person.hostile and not person.dead and person.position.distance_to(game.player.position)<350: return fail("先脱离交战再启程。")
		return_pos=game.player.position
	game.journal.close()
	game.village_ui.close()
	game.stop_meditation("")
	game.stop_gu_training("")
	active=true
	visited=true
	if offers.is_empty(): _restock()
	visible=true
	game.world.visible=false
	game.world.props.visible=false
	game.enemies_root.visible=false
	game.population.set_visible(false)
	game.npc.visible=false
	for p in game.residents.values(): p.visible=false
	game.fog.visible=false
	for prop in props: prop.visible=true
	game.projectiles.clear()
	game.pending_melee.clear()
	game.fx.clear_transients()
	game._world_attack_held=false
	game.player.position=ShangCityData.ORIGIN+ShangCityData.GATE
	if resume and saved_pos.is_finite() and not collides(saved_pos,12): game.player.position=saved_pos
	game.camera.limit_left=int(ShangCityData.ORIGIN.x)
	game.camera.limit_top=int(ShangCityData.ORIGIN.y)
	game.camera.limit_right=int(ShangCityData.ORIGIN.x+ShangCityData.SIZE.x)
	game.camera.limit_bottom=int(ShangCityData.ORIGIN.y+ShangCityData.SIZE.y)
	game._update_camera(0)
	game.camera.reset_smoothing()
	game.zone_banner_text="商家城 · 外城商区"
	game.zone_banner_time=2.5
	game.add_log("抵达商家城。E 交互，M 查看城镇指南；南门可随商队返程。",UIStyle.GOLD)
	if not resume and not game.save_game():
		leave(false)
		return fail("启程存档失败，已返回原地。")
	return true

func leave(persist: bool = true) -> bool:
	if not active: return false
	if bout: return fail("演武中不能离城；按 E 打开演武面板认输。")
	ui.close()
	active=false
	visible=false
	for prop in props: prop.visible=false
	game.change_layer(0,return_pos,false)
	game.fog.visible=true
	if persist: game.save_game()
	return true

func collides(point: Vector2, radius: float) -> bool:
	if not Rect2(ShangCityData.ORIGIN+Vector2(40,340),ShangCityData.SIZE-Vector2(80,380)).grow(-radius).has_point(point): return true
	if bout and not ShangCityData.arena_rect().grow(-radius).has_point(point): return true
	for b in ShangCityData.BUILDINGS:
		if not game.world.destruction.broken("shang:"+b.id) and ShangCityData.body_rect(b.id).grow(radius).has_point(point): return true
	return false

func obstacle(point: Vector2, radius: float = 0) -> Dictionary:
	for b in ShangCityData.BUILDINGS:
		var id:String="shang:"+b.id
		if not game.world.destruction.broken(id) and ShangCityData.body_rect(b.id).grow(radius).has_point(point): return {"id":id,"pos":point,"block":false}
	if not Rect2(ShangCityData.ORIGIN,ShangCityData.SIZE).has_point(point): return {"id":"boundary","pos":point,"block":false}
	return {}

func available(id: String) -> bool:
	var b:=ShangCityData.building(id)
	return active and not bout and not game.player.dead and not b.is_empty() and game.player.position.distance_to(ShangCityData.ORIGIN+Vector2(b.pos))<150 and not game.world.destruction.broken("shang:"+id)

func nearest() -> String:
	for b in ShangCityData.BUILDINGS:
		if game.player.position.distance_to(ShangCityData.ORIGIN+Vector2(b.pos))<150: return b.id
	return ""

func interact() -> bool:
	if bout:
		ui.open("arena")
		return true
	if game.player.position.distance_to(ShangCityData.ORIGIN+ShangCityData.GATE)<100:
		ui.open("travel")
		return true
	var id:=nearest()
	if id!="": ui.open(id)
	return true

func prompt() -> String:
	if bout: return "演武进行中 · E 查看战况 / 认输 · 伤亡真实结算"
	if game.player.position.distance_to(ShangCityData.ORIGIN+ShangCityData.GATE)<100: return "E  商队驿站 · 返回青茅山"
	var id:=nearest()
	if id!="": return "E  "+String(ShangCityData.building(id).name)+( " · 已毁损，F 修缮" if game.world.destruction.broken("shang:"+id) else "")
	if guide!="": return "前往 "+String(ShangCityData.building(guide).name)+" · 跟随金色路标"
	return "M  城镇指南 · 沿街寻找商楼与演武场"

func fail(message: String) -> bool:
	notice=message
	game._action_message(message)
	return false

func _transaction(mutation: Callable, message: String) -> bool:
	var before:=save_data()
	var cash:int=game.player.crystals
	var inv:Inventory=game.get_node("/root/Inv")
	var items:=inv.items.duplicate(true)
	var captured:Array=game.player.captured.duplicate(true)
	var discoveries:Array=game.player.discovered.duplicate()
	mutation.call()
	if not game.save_game():
		load_data(before)
		# Rollback must preserve a running bout, not count a reload forfeiture.
		losses=int(before.losses)
		bout=bool(before.bout)
		bout_level=int(before.bout_level)
		game.player.crystals=cash
		inv.items=items
		game.player.captured=captured
		game.player.discovered.assign(discoveries)
		return fail("存档失败，本次元石、物品和结果已回滚。")
	notice=message
	game._action_message(message)
	return true

func buy_stone(id: int) -> bool:
	if not available("stones"): return fail("请到完好的赌石坊门前交易。")
	if stones.size()>=12: return fail("待解原石已达 12 块，请先解石。")
	var selected:Dictionary={}
	for row in offers:
		if int(row.id)==id: selected=row
	if selected.is_empty(): return fail("这块原石已经售出。")
	var price:int=ShangCityData.STONES[int(selected.tier)].price
	if game.player.crystals<price: return fail("元石不足。")
	return _transaction(func():
		game.player.crystals-=price
		stones.append(selected.duplicate(true))
		offers.erase(selected)
		if offers.is_empty(): _restock()
	,"原石 #%d 已买下；解石结果随编号固定，保存后可继续解石。"%id)

func stone_result(row: Dictionary, careful: bool) -> Dictionary:
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value+int(row.id)*7919
	var kind:Dictionary=ShangCityData.STONES[clampi(int(row.tier),0,2)]
	var roll:=rng.randi_range(0,99)
	var gu:String=ShangCityData.GU_POOL[rng.randi_range(0,ShangCityData.GU_POOL.size()-1)]
	var survival:=rng.randi_range(0,99)
	if roll<int(kind.empty): return {"kind":"empty","text":"空石 · 获得碎石 ×1"}
	if roll<int(kind.empty)+int(kind.dead): return {"kind":"dead","text":"死蛊 · 石中只剩蛊虫残躯，获得碎石 ×1"}
	if survival>=(95 if careful else 55): return {"kind":"broken","text":"解石失手 · 活蛊在剥石中损毁，获得碎石 ×1"}
	return {"kind":"live","gu":gu,"text":"活蛊 · "+String(GameData.GU[gu].name)+"（未炼化，按 R 炼化）"}

func open_stone(id: int, careful: bool) -> Dictionary:
	if not available("stones"): fail("请在完好的赌石坊解石。"); return {}
	var selected:Dictionary={}
	for row in stones:
		if int(row.id)==id: selected=row
	if selected.is_empty(): fail("原石不存在或已经解开。"); return {}
	var fee:=6 if careful else 0
	if game.player.crystals<fee: fail("精解需要 6 元石。"); return {}
	var result:=stone_result(selected,careful)
	if result.kind!="live" and game.get_node("/root/Inv").get_item_count("rubble")>=Inventory.MAX_STACK*10:
		fail("碎石堆叠已满，请先腾出容量再解石。")
		return {}
	var success:=_transaction(func():
		game.player.crystals-=fee
		stones.erase(selected)
		if result.kind=="live":
			game.player.captured.append({"id":result.gu,"rank":int(GameData.GU[result.gu].rank),"quality":"normal","progress":0.0})
			if not game.player.discovered.has(result.gu): game.player.discovered.append(result.gu)
		else: game.get_node("/root/Inv").add_item("rubble",1)
		ledger.push_front("#%d · %s · %s"%[id,"精解" if careful else "粗解",result.text])
		while ledger.size()>12: ledger.pop_back()
	,result.text)
	return result if success else {}

func buy_supply(id: String) -> bool:
	if not available("market") or not ShangCityData.STOCK.has(id): return fail("请到完好的百货商楼交易。")
	var cost:int=ShangCityData.STOCK[id]
	if game.player.crystals<cost: return fail("元石不足。")
	if game.get_node("/root/Inv").get_item_count(id)>=Inventory.MAX_STACK*10: return fail("这类物品堆叠已满，请先腾出容量。")
	return _transaction(func(): game.player.crystals-=cost; game.get_node("/root/Inv").add_item(id,1),"购入 "+game.get_node("/root/Inv").get_item_name(id))

func deliver(id: String) -> bool:
	if not available("guild") or delivered.has(id): return fail("请到货栈交付尚未完成的订单。")
	for row in ShangCityData.CONTRACTS:
		if row.id!=id: continue
		var inv:Inventory=game.get_node("/root/Inv")
		if not inv.has_item(row.item,int(row.count)): return fail("交付物资不足。")
		return _transaction(func():
			inv.remove_item(row.item,int(row.count))
			game.player.crystals+=int(row.reward)
			delivered[id]=true
		,"订单完成 · +%d 元石。每个角色仅可领取一次。"%int(row.reward))
	return false

func rest() -> bool:
	if not available("inn") or game.player.crystals<15: return fail("到完好的客栈门前，花费 15 元石休息。")
	if game.player.hp>=game.player.max_hp and game.player.gu_effects.stamina>=99: return fail("气血和体力充足，无需休息。")
	var hp:float=game.player.hp
	var stamina:float=game.player.gu_effects.stamina
	var result:=_transaction(func():
		game.player.crystals-=15
		game.player.hp=minf(game.player.max_hp,game.player.hp+35)
		game.player.gu_effects.stamina=minf(100,game.player.gu_effects.stamina+50)
	,"休息完成 · 气血 +%.0f，体力 +%.0f；部位伤势仍需包扎。"%[minf(35,game.player.max_hp-hp),minf(50,100-stamina)])
	if not result: game.player.hp=hp; game.player.gu_effects.stamina=stamina
	return result

func start_bout() -> bool:
	if not available("arena"): return fail("请到完好的演武场门前报名。")
	if game.player.rank<1: return fail("凡人不能报名蛊师演武，请先开窍。")
	if game.player.crystals<20: return fail("报名需 20 元石。")
	if game.player.hp<game.player.max_hp*0.5 or game.player.body.unconscious: return fail("气血不足一半或失去意识，不能报名。")
	bout_level=clampi((wins-losses)/10,0,2)
	if not _transaction(func(): game.player.crystals-=20; bout=true,"报名成功。胜方获 50 元石；伤害真实，死亡将永久封存角色。"): return false
	ui.close()
	game.player.position=ShangCityData.ORIGIN+ShangCityData.ARENA.position+Vector2(150,230)
	game.projectiles.clear()
	game.pending_melee.clear()
	game._world_attack_held=false
	opponent=ShangOpponent.new()
	opponent.city=self
	opponent.game=game
	opponent.resident_id="shang_opponent"
	opponent.profile=ShangCityData.OPPONENTS[bout_level].duplicate()
	opponent.npc_name=opponent.profile.name
	opponent.max_hp=opponent.profile.hp
	opponent.hp=opponent.max_hp
	opponent.hostile=true
	opponent.position=ShangCityData.ORIGIN+ShangCityData.ARENA.position+Vector2(560,230)
	game.add_child(opponent)
	bout_time=0
	return true

func finish_bout(won: bool) -> bool:
	if not bout or game.player.dead: return false
	# A victory can only be issued by actual depletion of the opponent's HP.
	if won and (not is_instance_valid(opponent) or not opponent.defeated): return false
	if not _transaction(func():
		bout=false
		if won: wins+=1; game.player.crystals+=50
		else: losses+=1
	,"演武胜出 · +50 元石，净胜 %d 场。"%(wins+1-losses) if won else "本场记负，报名费不退；保留当前伤势。"): return false
	if is_instance_valid(opponent): opponent.queue_free()
	opponent=null
	game.projectiles.clear()
	game.pending_melee.clear()
	game.player.utility_gu.person_status.erase("shang_opponent")
	game._world_attack_held=false
	game.player.position=ShangCityData.ORIGIN+Vector2(1440,475)
	ui.open("arena")
	return true

func tick(delta: float) -> void:
	if not active: return
	if bout:
		bout_time+=delta
		retry_time+=delta
		if retry_time>1:
			retry_time=0
			if is_instance_valid(opponent) and opponent.defeated: finish_bout(true)
			elif bout_time>=180: finish_bout(false)
	queue_redraw()

func draw_map(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect,Color("243d3b"))
	for b in ShangCityData.BUILDINGS:
		canvas.draw_circle(rect.position+Vector2(b.pos)/ShangCityData.SIZE*rect.size,4,UIStyle.RED if game.world.destruction.broken("shang:"+b.id) else UIStyle.GOLD)
	canvas.draw_circle(rect.position+(game.player.position-ShangCityData.ORIGIN)/ShangCityData.SIZE*rect.size,3,Color.WHITE)

func _draw() -> void:
	if not active: return
	var origin:=ShangCityData.ORIGIN
	var horizon_height:=panorama.get_width()*360.0/2000.0
	draw_texture_rect_region(panorama,Rect2(origin,Vector2(2000,360)),Rect2(0,panorama.get_height()*0.3,panorama.get_width(),horizon_height))
	# Raised street edging and stone gutters separate each neighborhood surface.
	for y in [600,720,1050,1170]:
		for x in range(96,1880,48):
			if x in range(360,500) or x in range(730,870) or x in range(920,1070): continue
			if y==600 or y==720:
				if x>1060: continue
			draw_rect(Rect2(origin+Vector2(x,y-3),Vector2(45,6)),Color("a3a394"))
	for y in range(744,1340,48):
		if y in range(1030,1190): continue
		for x in [930,1060]: draw_rect(Rect2(origin+Vector2(x-3,y),Vector2(6,44)),Color("b8b09a"))
	draw_rect(ShangCityData.arena_rect(),Color("b6a17d"),false,9)
	draw_rect(ShangCityData.arena_rect().grow(-13),Color("595c54"),false,2)
	var center:=ShangCityData.arena_rect().get_center()
	draw_arc(center,145,0,TAU,80,Color("c2b58b"),4,true)
	draw_arc(center,154,0,TAU,80,Color("414f48"),2,true)
	for i in 8:
		var angle:=TAU*i/8.0
		draw_line(center+Vector2.from_angle(angle)*158,center+Vector2.from_angle(angle)*178,Color("776b54"),3,true)
	draw_string(ThemeDB.fallback_font,center+Vector2(-130,-170),"第五内城 · 演武坪",HORIZONTAL_ALIGNMENT_CENTER,260,19,Color("efe0b2"))
	var gate:=origin+ShangCityData.GATE
	draw_style_box(UIStyle.box(Color("203d37"),UIStyle.GOLD,10),Rect2(gate-Vector2(130,22),Vector2(260,56)))
	draw_string(ThemeDB.fallback_font,gate+Vector2(-120,12),"南门驿站 · E 返程",HORIZONTAL_ALIGNMENT_CENTER,240,20,UIStyle.GOLD)
	if guide!="":
		var target:Vector2=origin+Vector2(ShangCityData.building(guide).pos)+Vector2(0,60)
		draw_line(game.player.position,target,Color(UIStyle.GOLD,0.65),3,true)
		draw_arc(target,22,0,TAU,24,UIStyle.GOLD,3,true)
