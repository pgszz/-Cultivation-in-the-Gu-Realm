class_name GuRefinement
extends RefCounted

static func materials(game: Node, recipe: String) -> Array[GuVirtual]:
	var chosen:Array[GuVirtual]=[]
	if not GuProgression.RECIPES.has(recipe): return chosen
	var gus:GuManager=game.get_node("/root/Gus")
	var hunger:HungerSystem=game.get_node("/root/Hunger")
	for tid in GuProgression.RECIPES[recipe].inputs:
		var need:int=GuProgression.RECIPES[recipe].inputs[tid]
		for gu in gus.owned_gus:
			if gu.template_id!=tid or gu.dead or gu.location=="bag": continue
			if not hunger.gu_data.has(gu.id) or hunger.gu_data[gu.id].dead: continue
			chosen.append(gu)
			need-=1
			if need==0: break
		if need>0: return []
	return chosen

static func blocker(game: Node, recipe: String) -> String:
	if not GuProgression.RECIPES.has(recipe): return "尚未核实这条蛊方。"
	if not game.running or game.player.dead: return "需要存活的修行角色。"
	if game.refining: return "请先结束单蛊炼化。"
	if not game.can_meditate(): return "需在安全处合炼，先处理伤势并远离敌人。"
	if game.player.aperture.rank<2: return "需先在 Q 空窍页温养、冲窍，达到二转修为。"
	if materials(game,recipe).is_empty(): return "缺少已炼化且存活的材料蛊；外部携带蛊需先收入空窍。"
	var r:Dictionary=GuProgression.RECIPES[recipe]
	if game.player.crystals<int(r.stones): return "元石不足，需要 %d 块。" % int(r.stones)
	if not game.player.aperture.can_spend(float(r.essence)): return "真元不足，先打坐恢复或吸收元石。"
	return ""

static func fuse(game: Node, recipe: String) -> bool:
	var reason:=blocker(game,recipe)
	if reason!="":
		game._action_message(reason)
		return false
	var inputs:=materials(game,recipe)
	var r:Dictionary=GuProgression.RECIPES[recipe]
	var p:Player=game.player
	var gus:GuManager=game.get_node("/root/Gus")
	var hunger:HungerSystem=game.get_node("/root/Hunger")
	# Validate all requirements before mutating money, essence, slots or instances.
	if not p.aperture.spend(float(r.essence)): return false
	p.crystals-=int(r.stones)
	game.stop_meditation("")
	game.stop_gu_training("")
	if game._rng.randf()>=float(r.chance):
		game._action_message("合炼失败：元石和真元已消耗，材料蛊保留。本版未模拟失败毁蛊与本命反噬。")
		game.save_game()
		return false
	var inherited_vital:=false
	var slots:Array[int]=[]
	var fullness:=100.0
	var starving:=0.0
	for gu in inputs:
		inherited_vital=inherited_vital or p.vital_gu_id==gu.id
		fullness=minf(fullness,hunger.get_hunger(gu.id))
		starving=maxf(starving,hunger.gu_data[gu.id].starving_seconds)
		for i in 3:
			if p.skill_slots[i]==gu.id:
				slots.append(i)
				p.skill_slots[i]=""
		p.gu_effects.cancel(gu.id)
		if gu.template_id=="jade_skin": p.jade_guard=false
		if p.light_support_id==gu.id: p.light_support_id=""
		p.owned.erase(gu.template_id)
		gus.remove_gu(gu.id)
	var result:=gus.add_gu(recipe)
	p.owned.append(recipe)
	if not p.discovered.has(recipe): p.discovered.append(recipe)
	if inherited_vital: p.vital_gu_id=result.id
	if not slots.is_empty():
		p.skill_slots[slots[0]]=result.id
		p.cast_cds[slots[0]]=0.8
	result.hunger=fullness
	hunger.gu_data[result.id].current_hunger=fullness
	hunger.gu_data[result.id].starving_seconds=starving
	gus.set_active_gu(result)
	game.aperture_ui.selected_id=result.id
	game.fx.gu.emit("awaken",p.position,recipe,0.8)
	game._action_message("合炼成功：%s已收入空窍。材料蛊已合为一只，快捷位、本命和饥饿状态已衔接。" % GuProgression.title(recipe))
	game.save_game()
	return true
