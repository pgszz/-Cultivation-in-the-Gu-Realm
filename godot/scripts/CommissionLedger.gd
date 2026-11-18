class_name CommissionLedger
extends RefCounted

# Optional sandbox economy; these are game arrangements, not novel plot events.
const ORDERS := {
	"timber":{"name":"竹楼修缮","desc":"交付木料，帮助寨民修补竹楼。","items":{"timber":6},"stones":10,"reward":{"moon_petals":10},"cooldown":300.0},
	"rubble":{"name":"山路补石","desc":"为寨外山路筹集石料。","items":{"rubble":6},"stones":10,"reward":{"bandage":2},"cooldown":300.0},
	"east_trail":{"name":"东麓踏查","desc":"亲自到三处地点按 E，带回山路见闻。","sites":["bamboo_hollow","river_ford","central_camp"],"stones":45,"reward":{"bamboo_wine":2},"cooldown":0.0},
	"south_trail":{"name":"南麓访踪","desc":"踏查南麓竹坡、歇脚棚与南山石径。","sites":["south_bamboo","old_camp","south_pass"],"stones":50,"reward":{"bandage":3},"cooldown":0.0},
	"mountain_notes":{"name":"青茅山行记","desc":"记录全部九处野外探索点。","sites":["bamboo_hollow","river_ford","high_ridge","stone_gully","south_bamboo","old_camp","cedar_pool","south_pass","central_camp"],"stones":120,"reward":{"jade":2},"cooldown":0.0},
}
var states: Dictionary = {}

func state(id: String) -> Dictionary:
	if not states.has(id): states[id]={"accepted":false,"completed":0,"remaining":0.0}
	return states[id]

func at_counter(game: Node) -> bool:
	return game.world.in_interior and game.current_house_id in ["shop","archive"] and game.service_available(game.current_house_id)

func accept(id: String, game: Node) -> bool:
	if not ORDERS.has(id) or not at_counter(game):
		game._action_message("到古月商铺或学堂的委托处接取。")
		return false
	var s:=state(id)
	if s.accepted or s.remaining>0 or (s.completed>0 and ORDERS[id].cooldown==0): return false
	s.accepted=true
	game._action_message("已接取「"+ORDERS[id].name+"」。可随时游历，完成后回来交付。")
	game.save_game()
	return true

func progress(id: String, game: Node) -> String:
	var d:Dictionary=ORDERS[id]
	var lines:Array[String]=[]
	var inv:Inventory=game.get_node("/root/Inv")
	for item in d.get("items",{}): lines.append("%s %d/%d"%[inv.get_item_name(item),inv.get_item_count(item),d.items[item]])
	if d.has("sites"):
		var count:=0
		for site in d.sites:
			if game.visited_sites.has(site): count+=1
		lines.append("踏查 %d/%d 处"%[count,d.sites.size()])
	return " · ".join(lines)

func ready(id: String, game: Node) -> bool:
	if not ORDERS.has(id) or not state(id).accepted: return false
	var d:Dictionary=ORDERS[id]
	var inv:Inventory=game.get_node("/root/Inv")
	for item in d.get("items",{}):
		if inv.get_item_count(item)<int(d.items[item]): return false
	for site in d.get("sites",[]):
		if not game.visited_sites.has(site): return false
	return true

func submit(id: String, game: Node) -> bool:
	if not at_counter(game) or not ready(id,game):
		game._action_message("需完成委托条件，并回到商铺或学堂交付。")
		return false
	var d:Dictionary=ORDERS[id]
	var s:=state(id)
	# Close the transaction before inventory signals refresh other interfaces.
	s.accepted=false
	s.completed+=1
	s.remaining=d.cooldown
	var inv:Inventory=game.get_node("/root/Inv")
	for item in d.get("items",{}): inv.remove_item(item,int(d.items[item]))
	game.player.crystals+=int(d.stones)
	for item in d.reward: inv.add_item(item,int(d.reward[item]))
	game._action_message("交付「%s」：元石 +%d，补给已放入背包。"%[d.name,d.stones])
	game.save_game()
	return true

func tick(delta: float) -> void:
	for s in states.values(): s.remaining=maxf(0,float(s.remaining)-delta)

func save_data() -> Dictionary:
	return states.duplicate(true)

func load_data(data: Dictionary) -> void:
	states.clear()
	for id in data:
		if not ORDERS.has(id) or not data[id] is Dictionary: continue
		var raw:Dictionary=data[id]
		states[id]={"accepted":bool(raw.get("accepted",false)),"completed":maxi(0,int(raw.get("completed",0))),"remaining":clampf(float(raw.get("remaining",0)),0,float(ORDERS[id].cooldown))}

func next_site(id: String, game: Node) -> Dictionary:
	if not ORDERS.has(id): return {}
	for site_id in ORDERS[id].get("sites",[]):
		if game.visited_sites.has(site_id): continue
		for site in World.EXPLORATION_SITES:
			if site.id==site_id: return site
	return {}
