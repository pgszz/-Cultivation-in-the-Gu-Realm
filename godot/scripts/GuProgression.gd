class_name GuProgression
extends RefCounted

## 原著的转数、路线与稀有叙述；费用、概率和精确数值均为游戏模拟。
const RECIPES := {
	"moon_glow":{"inputs":{"moon_blade":1,"little_light":2},"stones":80,"essence":100.0,"chance":0.8,"change":"月刃 26 → 78，攻击力为月光蛊的 3 倍；比辅光月刃 52 再提高 50%。","source":"第一卷 98、106、108"},
	"white_jade":{"inputs":{"white_boar":1,"jade_skin":1},"stones":100,"essence":100.0,"chance":0.8,"change":"护体减伤 60% → 80%；同样 100 点来袭伤害，承伤 40 → 20。已练成的永久力量保留。","source":"第一卷 98—100"},
	"moon_raiment":{"inputs":{"moon_blade":1,"jade_skin":1},"stones":90,"essence":100.0,"chance":0.8,"change":"护体减伤 60% → 70%；增加近处行人庇护，保护范围 180 像素。只能维持一层护体。","source":"第一卷 98、104、106"},
}
const SHOP_LIMITS := {"moon_blade":4,"little_light":6,"jade_skin":3,"white_boar":2}
const RARITY := {
	"moon_blade":["家族限定","古月一族秘法培育；家族限定不等于全天下的统一稀有评级。"],
	"jiu_chong":["稀有","前期正文将酒虫与玉皮等珍贵蛊相比较；不是随机品质加成。"],
	"jade_skin":["稀有","第一卷 62 明确描述其稀有，价格接近酒虫。"],
	"white_boar":["稀有","第一卷 62—63 将黑白豕列为珍贵增力蛊，市价六百。"],
	"black_boar":["稀有","第一卷 62 黑白豕增力永久，价值远高于普通暂时增力蛊。"],
	"beast_skin":["常见","第一卷 62 介绍常见且价格低的兽皮蛊。"],
	"moon_raiment":["少见路线","第一卷 106 称其为较少见的合炼路线；不表示所有二转蛊都稀有。"],
}

static func rarity(id: String) -> String:
	if GameData.GU[id].has("rarity"): return String(GameData.GU[id].rarity)
	if GameData.GU[id].get("origin","")=="原创蛊虫": return "沙盒无评级"
	return String(RARITY.get(id,["稀有度未定",""])[0])

static func rarity_note(id: String) -> String:
	if GameData.GU[id].has("rarity"): return "此稀有标签按本作投放与价格标示，不是原著统一品质，也不增加随机属性。"
	if GameData.GU[id].get("origin","")=="原创蛊虫": return "本作原创蛊虫，没有原著稀有评级。"
	return String(RARITY.get(id,["","原著尚未核实其统一稀有评级；商铺库存属于游戏安排，不能据此判定稀有。"])[1])

static func title(id: String) -> String:
	if GameData.is_utility_gu(id): return "%s · %d转 · %s" % [GameData.GU[id].name,GameData.GU[id].rank,GameData.GU[id].origin]
	return "%s · %d转 · %s" % [GameData.GU[id].name,GameData.GU[id].rank,rarity(id)]

static func ingredients(recipe: String) -> String:
	var out:Array[String]=[]
	for id in RECIPES[recipe].inputs:
		out.append("%s（一转）×%d" % [GameData.GU[id].name,RECIPES[recipe].inputs[id]])
	return " + ".join(out)

static func routes(id: String) -> String:
	if GameData.BODY_GU.has(id): return "获取："+GameData.shop_name(id)+"购买未炼化蛊，用 R 炼化后寄居空窍或身体、绑定快捷键使用。本批未开放合炼方，催动与杀敌不会自动升转；详情见肉身状态蛊专题。"
	if GameData.HUNDRED_GU.has(id): return "获取："+GameData.shop_name(id)+"购买未炼化蛊，再用 R 炼化；本批尚未开放合炼方。舍利五种分别取得，不能靠使用或杀敌把青铜舍利升成赤铁舍利。" if GameData.GU[id].skill.kind=="relic" else "获取："+GameData.shop_name(id)+"购买，再用 R 炼化；本批尚未开放合炼方，催动和杀敌不会让蛊自动升转。"
	var lines:Array[String]=[]
	if RECIPES.has(id):
		lines.append("炼成办法："+ingredients(id)+" → "+GameData.GU[id].name+"（二转）。")
	for result in RECIPES:
		if RECIPES[result].inputs.has(id):
			lines.append(ingredients(result)+" → "+GameData.GU[result].name+"（二转）\n"+RECIPES[result].change)
	if lines.is_empty(): return "升炼：尚未开放已核对的后续蛊方；催动和杀敌不会让蛊自动升转。"
	return "\n".join(lines)+"\n在修行录「炼蛊」查看材料与条件；与 R 单蛊炼化不同。"

static func power(id: String) -> String:
	if GameData.GU[id].has("hint"): return String(GameData.GU[id].hint)
	var sk:Dictionary=GameData.GU[id].skill
	match String(sk.kind):
		"proj": return "基础伤害 %.0f · 冷却 %.1f 秒" % [sk.dmg,sk.cd]
		"jade_guard": return "护体减伤 60%；100 点来袭伤害承受 40。"
		"skin_guard": return "护体减伤 %.0f%%；100 点来袭伤害承受 %.0f。" % [float(sk.reduction)*100,(1-float(sk.reduction))*100]
		"boar_training": return "逐渐练成永久一猪之力；当前肉身攻击最多 +11，不提高月刃威力。"
		"brute_force": return "肉身攻击 +22，持续 5 秒；有肌肉负担。"
		"endurance": return "体力消耗减少 60%，持续 15 秒。"
		"cricket_leap": return "腾跃距离最多 112 像素；无伤害、无无敌。"
		"light_support": return "辅光月刃 26 → 52；多只小光不叠加。"
		"refine_essence": return "两成一转真元 → 半成高一小阶真元；一转巅峰停用。"
	return "详见催动说明。"

static func detail(id: String, stage: int = 0, rank: int = 1) -> String:
	if GameData.is_utility_gu(id):
		return "[color=#d8bc7c]%s[/color]\n%s · %s\n\n[color=#76c2aa]当前效用[/color]\n%s\n\n%s" % [title(id),rarity(id),rarity_note(id),GameData.activation_hint(id,stage,rank),routes(id)]
	return "[color=#d8bc7c]%s[/color]\n%s\n\n[color=#76c2aa]当前效用（数值为模拟）[/color]\n%s\n%s\n\n[color=#d8bc7c]升炼路线[/color]\n%s" % [title(id),rarity_note(id),power(id),GameData.activation_hint(id,stage,rank),routes(id)]
