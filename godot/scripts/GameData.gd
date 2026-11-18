class_name GameData
extends RefCounted

## 全局常量、蛊虫数据库、转数表。

const TILE := 32
const MAP_W := 160
const MAP_H := 120
const MAP_VERSION := 2

const VILLAGE := Vector2i(14, 30)
const FURNACE := Vector2(15 * TILE + 16, 28 * TILE + 16)
const BONFIRE := Vector2(12 * TILE + 16, 31 * TILE + 16)

const T_GRASS := 0
const T_DIRT := 1
const T_WATER := 2
const T_ROCK := 3
const T_TREE := 4
const T_FLOWER := 5
const T_RUIN := 6

const EL_COLOR := {
	"metal": Color("#d9c46a"),
	"wood": Color("#5fbf6a"),
	"water": Color("#4aa3df"),
	"fire": Color("#e8663a"),
	"earth": Color("#b08a4f"),
	"thunder": Color("#b07be8"),
	"wind": Color("#7fd6c2"),
	"none": Color("#cfd8cf"),
}

const EL_NAME := {
	"metal": "金", "wood": "木", "water": "水", "fire": "火",
	"earth": "土", "thunder": "雷", "wind": "风", "none": "无",
}

# 正式内容只开放已经逐项校对的蛊；旧表保存在修改前归档中。
const GU := {
	"moon_blade": {
		"name":"月光蛊", "rank":1, "dao":"月道", "element":"none", "color":Color("8cbac5"),
		"hp":24.0, "atk":0.0, "spd":95.0, "radius":8.0, "ai":"flee",
		"preferred_food":"moon_petals", "hunger_rate":1.0, "source":["5374568","5374582"],
		"skill":{"name":"催发月刃","kind":"proj","cd":0.8,"cost":10.0,"dmg":26.0,"speed":460.0,"color":Color("93c7dd"),"element":"none","pierce":0,"poison":0.0,"burn":0.0},
		"flavor":"古月一族秘法培育的镇族蛊。以月兰花瓣为食。月刃是攻击形态，不是另一种蛊。",
	},
	"jiu_chong": {
		"name":"酒虫", "rank":1, "dao":"炼道", "element":"none", "color":Color("8cbac5"),
		"hp":24.0, "atk":0.0, "spd":95.0, "radius":8.0, "ai":"flee",
		"preferred_food":"bamboo_wine", "hunger_rate":1.0, "source":["5374576","5374640"],
		"skill":{"name":"精炼真元","kind":"refine_essence","cd":0.8,"cost":0.0,"dmg":0.0,"speed":460.0,"color":Color("93c7dd"),"element":"none","pierce":0,"poison":0.0,"burn":0.0},
		"flavor":"以酒为食。一次耗一成真元形成酒雾，再将另一成精炼为半成高一小阶真元；一转巅峰及二转真元不适用。",
	},
	"jade_skin": {
		"name":"玉皮蛊", "rank":1, "dao":"防御", "element":"none", "color":Color("8cbac5"),
		"hp":24.0, "atk":0.0, "spd":95.0, "radius":8.0, "ai":"flee",
		"preferred_food":"jade", "hunger_rate":1.0, "source":["5374622","5374659"],
		"skill":{"name":"维持玉皮","kind":"jade_guard","cd":0.8,"cost":0.0,"dmg":0.0,"speed":460.0,"color":Color("93c7dd"),"element":"none","pierce":0,"poison":0.0,"burn":0.0},
		"flavor":"持续灌注真元形成玉皮防御，承受攻击时另耗真元；停止供给即消退。食物为玉石。",
	}
}
const GU_ORDER := ["moon_blade","jiu_chong","jade_skin"]

static func activation_hint(id: String, stage: int = 0) -> String:
	var potency:=pow(2.0,stage)
	match id:
		"moon_blade": return "当前小阶普通真元：每次 %.2f%%。高一小阶真元效力翻倍。" % (10.0/potency)
		"jiu_chong": return "每次共耗两成未精炼真元，得到半成高一小阶真元。只能作用于一转初、中、高阶。"
		"jade_skin": return "维持每秒耗普通真元 %.2f%%；每点来袭伤害另耗 %.3f%%，减伤 60%%。真元不足时防御消退。" % [1.0/potency,0.35/potency]
	return ""

static func rank_name(r: int) -> String:
	return "蛊师" if r <= 5 else "蛊仙"

static func xp_next(_r: int) -> float:
	return 100.0 # 兼容旧显示接口；实际含义为窍壁温养百分比。

static func el_color(el: String) -> Color:
	return EL_COLOR.get(el, Color("cfd8cf"))

static func el_name(_el: String) -> String:
	return "蛊虫具体效用"
