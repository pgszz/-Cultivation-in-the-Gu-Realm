class_name PersonExchange
extends RefCounted

## Personal belongings and prices are sandbox values. Gu instances are not commodities here.
const THEFT_RETALIATION := 0.05
const FRIENDLY_THEFT_RETALIATION := 0.02

static func ordinary_item(id: String) -> bool:
	return Inventory.ITEM_INFO.has(id) or FoodSystem.GRAINS.has(id)

static func initial_possessions(person: Npc) -> Dictionary:
	if person is WorldPerson:
		match person.role:
			"merchant": return {"items":{"bandage":8,"bamboo_wine":6,"timber":10,"rubble":8},"crystals":80}
			"porter": return {"items":{"bandage":1,"timber":3},"crystals":6}
			"guard","escort": return {"items":{"bandage":3,"bamboo_wine":1},"crystals":12}
			"gatherer": return {"items":{"timber":6} if person.resident_id=="bamboo_gatherer" else {"rubble":6},"crystals":5}
			"bandit": return {"items":{"bandage":1,"boar_meat":2},"crystals":8}
			"traveler": return {"items":{"bandage":2,"bamboo_wine":1},"crystals":10}
		return {"items":{"bandage":1},"crystals":4}
	if "clinic" in person.resident_id: return {"items":{"bandage":4},"crystals":12}
	if "shop" in person.resident_id: return {"items":{"bandage":2,"bamboo_wine":2,"rabbit_meat":2},"crystals":24}
	return {"items":{"bandage":1,"bamboo_wine":1},"crystals":8}

static func price(id: String, buying: bool) -> int:
	if not ordinary_item(id): return 0
	var purchase:int={"bandage":2,"bamboo_wine":3,"jade":4,"pork_ration":12}.get(id,maxi(1,int(Inventory.SELL_PRICES.get(id,0))*2))
	return purchase if buying else maxi(1,purchase/2)

static func blocker(game: Node, person: Npc, looting: bool = false, action: String = "交易") -> String:
	if not game.running or game.player.dead: return "当前无法操作人物物品。"
	if not is_instance_valid(person) or not game.active_npcs().has(person): return "人物已不在当前场景。"
	# Fog visibility flags update on the next frame; use the current position here.
	if not game.fog.can_see(person.position): return "人物不在视野内。"
	if game.player.position.distance_to(person.position)>=80: return "距离较远，请靠近后再%s。" % ("搜刮" if looting else action)
	if looting:
		return "此人仍然活着，不能搜刮。" if not person.dead else ""
	if person.dead: return "已死亡，可在物品页搜刮遗留物品。"
	if person.hostile: return "与你敌对，无法靠近盗窃。" if action=="盗窃" else "与你敌对，拒绝%s。" % action
	if person is WorldPerson and (game.population.valid_target(person,person.target) or person.flee_left>0 or person.strike_left>0): return "此人正在交战或避险，暂时无法%s。" % action
	if not game.world.in_interior:
		for other: Npc in game.active_npcs():
			if not other.dead and other.hostile and other.position.distance_to(person.position)<180: return "附近有敌人，暂时无法%s。" % action
	return ""

static func social_blocker(game: Node, person: Npc, action: String) -> String:
	var reason:=blocker(game,person,false,action)
	if reason!="": return reason
	if not game.world.conversation_clear(game.player.position,person.position): return "中间有障碍，请绕到对方面前。"
	var remaining:=person.social.cooldown_left(person,"theft")
	if remaining>0: return "对方刚遭你盗窃，正在戒备；还需 %d 秒游历时间。" % ceili(remaining)
	return ""

static func gift_offer(game: Node, person: Npc, id: String, amount: int) -> Dictionary:
	var offer:={"reason":social_blocker(game,person,"赠礼"),"gain":0,"note":""}
	if offer.reason!="": return offer
	if not ordinary_item(id) or amount<=0 or amount>NpcGiftRules.MAX_GIFT:
		offer.reason="每次赠礼请选择 1–%d 件普通物品。" % NpcGiftRules.MAX_GIFT
		return offer
	person.ensure_possessions()
	var inv:Inventory=game.get_node("/root/Inv")
	if inv.get_item_count(id)<amount: offer.reason="你的物品数量不足。"
	elif int(person.carried_items.get(id,0))+amount>Inventory.MAX_STACK*10: offer.reason="对方此物品已达携带上限。"
	if offer.reason!="": return offer
	offer=NpcGiftRules.evaluate(person,id)
	if offer.reason!="": return offer
	var remaining:=person.social.cooldown_left(person,"gift")
	if remaining>0:
		offer.reason="刚收过你的礼物，暂不再收；还需 %d 秒游历时间。" % ceili(remaining)
		offer.gain=0
	else:
		offer.gain=mini(int(offer.gain),100-person.social.affinity)
	return offer

static func gift(game: Node, person: Npc, id: String, amount: int) -> bool:
	var offer:=gift_offer(game,person,id,amount)
	if offer.reason!="": return reject(game,"赠礼未成："+str(offer.reason))
	var inv:Inventory=game.get_node("/root/Inv")
	inv.remove_item(id,amount)
	person.carried_items[id]=int(person.carried_items.get(id,0))+amount
	var change:=person.social.gift_event(person,inv.get_item_name(id),amount,int(offer.gain))
	game.last_action_message="%s收下%s ×%d（%s），好感 %+d。" % [person.npc_name,inv.get_item_name(id),amount,offer.note,change]
	game.save_game()
	return true

static func theft_offer(game: Node, person: Npc, id: String, amount: int) -> Dictionary:
	var offer:={"reason":social_blocker(game,person,"盗窃"),"loss":0,"risk":0.0}
	if offer.reason!="": return offer
	offer.risk=theft_retaliation_chance(person)
	if (id!="currency" and not ordinary_item(id)) or amount<=0 or amount>Inventory.MAX_STACK*10:
		offer.reason="请选择有效的普通物品或元石数量。"
		return offer
	person.ensure_possessions()
	var inv:Inventory=game.get_node("/root/Inv")
	var count:int=person.carried_crystals if id=="currency" else int(person.carried_items.get(id,0))
	if count<amount: offer.reason="对方物品数量不足。"
	elif id!="currency" and inv.get_item_count(id)+amount>Inventory.MAX_STACK*10: offer.reason="你的此物品已达携带上限。"
	if offer.reason!="": return offer
	var value:int=amount if id=="currency" else price(id,false)*amount
	offer.loss=mini(person.social.affinity+100,mini(40,10+value))
	return offer

static func theft_retaliation_chance(person: Npc) -> float:
	person.social.ensure(person)
	return FRIENDLY_THEFT_RETALIATION if person.social.affinity>=30 else THEFT_RETALIATION

static func steal(game: Node, person: Npc, id: String, amount: int) -> bool:
	var offer:=theft_offer(game,person,id,amount)
	if offer.reason!="": return reject(game,"盗窃未成："+str(offer.reason))
	var inv:Inventory=game.get_node("/root/Inv")
	if id=="currency":
		person.carried_crystals-=amount
		game.player.crystals+=amount
	else:
		person.carried_items[id]=int(person.carried_items[id])-amount
		if person.carried_items[id]==0: person.carried_items.erase(id)
		inv.add_item(id,amount)
	var item_name:String="元石" if id=="currency" else inv.get_item_name(id)
	var change:=person.social.theft_event(person,item_name,amount,int(offer.loss))
	# One roll only after successful transfer; previews and invalid attempts never roll.
	var retaliates:bool=game._rng.randf()<float(offer.risk)
	if retaliates: person.social.retaliate(person)
	game.last_action_message="盗得%s ×%d；%s察觉失窃，好感 %+d。%s" % [item_name,amount,person.npc_name,change,"对方愤而反击，返回地图后将攻击你！" if retaliates else "对方暂未动手，戒备 300 秒。"]
	if retaliates: game.add_log(person.npc_name+"发现你盗窃，愤而向你动手！",UIStyle.RED)
	game.save_game()
	return true

static func reject(game: Node, message: String) -> bool:
	game.last_action_message=message
	return false

static func trade(game: Node, person: Npc, id: String, amount: int, buying: bool) -> bool:
	var reason:=blocker(game,person)
	if reason!="": return reject(game,reason)
	var unit:=price(id,buying)
	if amount<=0 or amount>Inventory.MAX_STACK*10 or unit<=0: return reject(game,"请选择有效的普通物品与数量。")
	person.ensure_possessions()
	var inv:Inventory=game.get_node("/root/Inv")
	var seller_count:int=int(person.carried_items.get(id,0)) if buying else inv.get_item_count(id)
	var buyer_count:int=inv.get_item_count(id) if buying else int(person.carried_items.get(id,0))
	var money:int=game.player.crystals if buying else person.carried_crystals
	var total:=unit*amount
	if seller_count<amount: return reject(game,"物品数量不足。")
	if buyer_count+amount>Inventory.MAX_STACK*10: return reject(game,"接收方此物品已达携带上限。")
	if money<total: return reject(game,"你的元石不足。" if buying else "对方元石不足，无法收购。")
	# Validate all legs before mutating either participant; persist once after settlement.
	if buying:
		person.carried_items[id]=seller_count-amount
		if person.carried_items[id]==0: person.carried_items.erase(id)
		game.player.crystals-=total
		person.carried_crystals+=total
		inv.add_item(id,amount)
	else:
		inv.remove_item(id,amount)
		person.carried_items[id]=buyer_count+amount
		person.carried_crystals-=total
		game.player.crystals+=total
	game.last_action_message="%s%s ×%d，%s %d 元石。" % ["买入" if buying else "卖出",inv.get_item_name(id),amount,"花费" if buying else "获得",total]
	person.social.trade_event(person,inv.get_item_name(id),amount,buying)
	game.save_game()
	return true

static func loot(game: Node, person: Npc, id: String = "", amount: int = 1, all_items: bool = false) -> bool:
	var reason:=blocker(game,person,true)
	if reason!="": return reject(game,reason)
	person.ensure_possessions()
	var inv:Inventory=game.get_node("/root/Inv")
	if not all_items and id!="currency" and (not ordinary_item(id) or amount<=0): return reject(game,"请选择有效物品与数量。")
	var moved:=0
	if all_items or id=="currency":
		moved+=person.carried_crystals
		game.player.crystals+=person.carried_crystals
		person.carried_crystals=0
	var ids:Array=person.carried_items.keys() if all_items else [id]
	for item in ids:
		if not ordinary_item(item): continue
		var count:int=int(person.carried_items.get(item,0))
		var transfer:=mini(count,Inventory.MAX_STACK*10-inv.get_item_count(item))
		if not all_items: transfer=mini(transfer,amount)
		if transfer<=0: continue
		person.carried_items[item]=count-transfer
		if person.carried_items[item]==0: person.carried_items.erase(item)
		inv.add_item(item,transfer)
		moved+=transfer
	if moved==0: return reject(game,"没有可收取的物品，或你的背包已达携带上限。")
	game.last_action_message="已搜刮，物品与元石已放入行囊。" if person.carried_items.is_empty() and person.carried_crystals==0 else "已收取物品；遗体仍有余物，可继续搜刮。"
	person.social.record(person,"loot","遗物被你收取。","player")
	game.save_game()
	return true
