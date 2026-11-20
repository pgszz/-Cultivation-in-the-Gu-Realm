class_name CultivationGu
extends RefCounted

## 舍利消耗与升阶作为一次存档事务；资质增长由 UtilityGuEffects 按时钟结算。
static func use_relic(game: Node, gu: GuVirtual) -> void:
	var p:Player=game.player
	var a:=p.aperture
	if a.rank!=gu.rank or a.stage>=3:
		game._action_message("%s仅适用于%d转未达巅峰的蛊师；不能跨转或提高资质。"%[gu.name,gu.rank])
		return
	if not game.can_meditate():
		game._action_message("需要远离威胁、止血后的静处使用舍利蛊。")
		return
	if gu.id==p.vital_gu_id:
		game._action_message("本作不允许主动消耗本命舍利蛊，请选用非本命实例。")
		return
	var gus:GuManager=game.get_node("/root/Gus")
	var hunger:HungerSystem=game.get_node("/root/Hunger")
	var before:=a.save_data()
	var slots:=p.skill_slots.duplicate()
	var owned:=p.owned.duplicate()
	var old_instances:=gus.owned_gus.duplicate()
	var old_active:=gus.active_gu
	var food_state:=hunger.save_data()
	a.wall_progress=100
	a.breakthrough()
	p.owned.erase(gu.template_id)
	for i in p.skill_slots.size():
		if p.skill_slots[i]==gu.id: p.skill_slots[i]=""
	gus.remove_gu(gu.id)
	if not game.save_game():
		a.load_data(before)
		p.skill_slots.assign(slots)
		p.owned.assign(owned)
		gus.owned_gus.assign(old_instances)
		gus.active_gu=old_active
		hunger.register_gu(gu.id,gu.rank,gu.quality,gu.preferred_food)
		hunger.load_data(food_state)
		game._action_message("保存失败，舍利消耗与升阶已撤回。")
		return
	p.utility_gu.cancel(gu.id)
	p.animation.play("cast",p.dir,0.6)
	game.fx.ring(p.position.x,p.position.y-18,GameData.GU[gu.template_id].color,8,70,0.8)
	game._action_message("%s已消耗，达到%s；资质不变。"%[gu.name,a.realm()])
