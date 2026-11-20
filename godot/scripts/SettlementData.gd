class_name SettlementData
extends RefCounted

# 街区、普通住民与商户安排属于自由探索设计，不是原著人物或精确测绘。
const DISTRICTS := [
	{"id":"bai","name":"白家寨","pos":GameData.BAI_VILLAGE,"color":Color("91c4ce"),"bounds":Rect2(GameData.BAI_VILLAGE+Vector2(-576,-640),Vector2(1152,1472))},
	{"id":"xiong","name":"熊家寨","pos":GameData.XIONG_VILLAGE,"color":Color("c29b69"),"bounds":Rect2(GameData.XIONG_VILLAGE+Vector2(-576,-640),Vector2(1152,1472))},
]
const HALLS := [
	{"id":"bai","name":"白家寨会客楼","pos":GameData.BAI_VILLAGE,"hint":"寨中指路 / 家族见闻","clan":"bai","service":"hall","resident":"白家接待执事","art":5},
	{"id":"xiong","name":"熊家寨会客楼","pos":GameData.XIONG_VILLAGE,"hint":"寨中指路 / 家族见闻","clan":"xiong","service":"hall","resident":"熊家接待执事","art":6},
]
const HOUSES := [
	{"id":"bai_clinic","name":"白家药堂","pos":GameData.BAI_VILLAGE+Vector2(-320,0),"hint":"普通包扎 / 绷带","clan":"bai","service":"clinic","resident":"白家医者","art":1},
	{"id":"bai_shop","name":"白家商铺","pos":GameData.BAI_VILLAGE+Vector2(320,0),"hint":"行路补给 / 猎获交易","clan":"bai","service":"shop","resident":"白家掌柜","art":2},
	{"id":"bai_inn","name":"白家客舍","pos":GameData.BAI_VILLAGE+Vector2(-320,320),"hint":"歇脚 / 行囊 / 补给","clan":"bai","service":"inn","resident":"白家客舍主人","art":0},
	{"id":"bai_school","name":"白家学堂","pos":GameData.BAI_VILLAGE+Vector2(320,-320),"hint":"修行常识 / 寨中指路","clan":"bai","service":"archive","resident":"白家学堂执事","art":3},
	{"id":"bai_home_a","name":"白家民居一","pos":GameData.BAI_VILLAGE+Vector2(-320,-320),"hint":"拜访住户 / 听闻山路","clan":"bai","service":"home","resident":"白家住户","art":0},
	{"id":"bai_home_b","name":"白家民居二","pos":GameData.BAI_VILLAGE+Vector2(0,608),"hint":"拜访住户 / 听闻生活","clan":"bai","service":"home","resident":"白家族人","art":0},
	{"id":"bai_workshop","name":"白家工坊","pos":GameData.BAI_VILLAGE+Vector2(320,320),"hint":"木石材料 / 修缮说明","clan":"bai","service":"workshop","resident":"白家工匠","art":2},
	{"id":"bai_spring","name":"白家元泉洞","pos":GameData.BAI_VILLAGE+Vector2(0,-480),"hint":"家族元泉 / 观察","clan":"bai","service":"spring","resident":"","art":8,"kind":"cave"},
	{"id":"xiong_clinic","name":"熊家药堂","pos":GameData.XIONG_VILLAGE+Vector2(320,0),"hint":"普通包扎 / 绷带","clan":"xiong","service":"clinic","resident":"熊家医者","art":1},
	{"id":"xiong_shop","name":"熊家商铺","pos":GameData.XIONG_VILLAGE+Vector2(-320,0),"hint":"行路补给 / 猎获交易","clan":"xiong","service":"shop","resident":"熊家掌柜","art":2},
	{"id":"xiong_inn","name":"熊家客舍","pos":GameData.XIONG_VILLAGE+Vector2(320,320),"hint":"歇脚 / 行囊 / 补给","clan":"xiong","service":"inn","resident":"熊家客舍主人","art":0},
	{"id":"xiong_school","name":"熊家学堂","pos":GameData.XIONG_VILLAGE+Vector2(-320,-320),"hint":"修行常识 / 寨中指路","clan":"xiong","service":"archive","resident":"熊家学堂执事","art":3},
	{"id":"xiong_home_a","name":"熊家民居一","pos":GameData.XIONG_VILLAGE+Vector2(320,-320),"hint":"拜访住户 / 听闻山路","clan":"xiong","service":"home","resident":"熊家住户","art":0},
	{"id":"xiong_home_b","name":"熊家民居二","pos":GameData.XIONG_VILLAGE+Vector2(-320,608),"hint":"拜访住户 / 听闻生活","clan":"xiong","service":"home","resident":"熊家族人","art":0},
	{"id":"xiong_workshop","name":"熊家工坊","pos":GameData.XIONG_VILLAGE+Vector2(-320,320),"hint":"木石材料 / 修缮说明","clan":"xiong","service":"workshop","resident":"熊家工匠","art":2},
	{"id":"xiong_spring","name":"熊家元泉洞","pos":GameData.XIONG_VILLAGE+Vector2(0,-480),"hint":"家族元泉 / 观察","clan":"xiong","service":"spring","resident":"","art":8,"kind":"cave"},
]
const PEOPLE := [
	{"id":"bai_gatekeeper","name":"白家守寨人","clan":"bai","pos":GameData.BAI_VILLAGE+Vector2(96,736)},
	{"id":"bai_walker","name":"白家行路人","clan":"bai","pos":GameData.BAI_VILLAGE+Vector2(-80,192)},
	{"id":"xiong_gatekeeper","name":"熊家守寨人","clan":"xiong","pos":GameData.XIONG_VILLAGE+Vector2(96,736)},
	{"id":"xiong_walker","name":"熊家行路人","clan":"xiong","pos":GameData.XIONG_VILLAGE+Vector2(-80,192)},
]

static func building(id: String) -> Dictionary:
	for data in HALLS+HOUSES:
		if data.id==id: return data
	return {}

static func service(id: String) -> String:
	var data:=building(id)
	return String(data.service) if not data.is_empty() else id

static func is_cave(id: String) -> bool:
	return id in ["flower_cave","spring_cave"] or service(id)=="spring"

static func can_sell(id: String, item: String = "") -> bool:
	var role:=service(id)
	return role=="shop" or (role=="workshop" and item in ["","timber","rubble"])

static func stock(id: String) -> Dictionary:
	match service(id):
		"clinic": return {"bandage":1}
		"shop":
			var result:Dictionary={"bandage":1,"bamboo_wine":2,"jade":4,"pork_ration":12}
			result.merge(GameData.utility_food_stock())
			return result
		"inn": return {"bandage":1,"bamboo_wine":2}
		"workshop": return {"timber":2,"rubble":2}
	return {}
