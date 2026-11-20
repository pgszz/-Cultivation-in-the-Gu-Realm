class_name NpcGiftRules
extends RefCounted

## Gift tastes and thresholds are sandbox rules, not claims about canonical NPCs.
const COMMON := ["bandage","bamboo_wine","rabbit_meat","deer_meat","boar_meat","pheasant_meat"]
const MAX_GIFT := 10

static func preference(person: Npc, id: String) -> String:
	var role:String=person.role if person is WorldPerson else SettlementData.service(person.resident_id)
	match role:
		"clinic":
			if id=="bandage": return "药堂需要包扎用品"
		"workshop":
			if id in ["timber","rubble"]: return "工匠需要修缮材料"
		"gatherer":
			if id==("timber" if person.resident_id=="bamboo_gatherer" else "rubble"): return "合乎采集营生"
		"merchant","shop":
			if Inventory.SELL_PRICES.has(id) or id in ["bandage","bamboo_wine","jade"]: return "行商看重可流通的货物"
		"guard","escort","porter","traveler":
			if id=="bandage": return "行路与护卫需要备药"
		"inn":
			if id in COMMON and id!="bandage": return "客舍愿意备些酒肉"
		"aqing","archive":
			if id=="bamboo_wine": return "平日偏爱青竹酒"
	# Stable personal tastes keep ordinary residents distinct across saves.
	if role in ["villager","home","hall"]:
		var favorites:=["bamboo_wine","rabbit_meat","deer_meat","pheasant_meat"]
		if id==favorites[posmod(person.resident_id.hash(),favorites.size())]: return "合乎个人喜好"
	return ""

static func evaluate(person: Npc, id: String) -> Dictionary:
	person.social.ensure(person)
	var result:={"reason":"","gain":0,"note":""}
	if person.social.affinity<0:
		result.reason="对你心存戒备，不愿收你的礼物。"
		return result
	var urgent:=id=="bandage" and person.hp<person.max_hp
	var taste:=preference(person,id)
	if not urgent and taste=="" and not id in COMMON:
		result.reason="用不上这件物品，婉拒收下。"
		return result
	var required:=0 if urgent else (4 if taste!="" and id!="jade" else 30)
	result.note="受伤需要绷带" if urgent else (taste if taste!="" else "愿收朋友的日常用品")
	if person.social.affinity<required:
		result.reason="%s；好感需达到 %d（当前 %+d）。" % [result.note,required,person.social.affinity]
		return result
	result.gain=8 if urgent else (6 if taste!="" else 3)
	return result
