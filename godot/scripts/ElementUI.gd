class_name ElementUI
extends Control

const REACTIONS := {}
const SHORT_EFFECT := {}
const STATUSES := {"burn":"燃烧","poison":"中毒","wet":"潮湿","shock":"感电","slow":"减速","bleed":"流血","bind":"束缚","frozen":"冻结"}
var game: Node
var descriptions: Dictionary = {}

func _ready() -> void:
	var scroll := ScrollContainer.new()
	UIStyle.fill(scroll)
	add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal=SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation",12)
	scroll.add_child(stack)
	stack.add_child(UIStyle.label("蛊术效用 · 依据具体蛊虫",22,UIStyle.GOLD))
	var intro:=UIStyle.label("查看每只蛊虫的催动方式、真元消耗与食性。组合效果取决于具体蛊术。\n沙盒反应：溪流灭火、湿身；霜针冻结湿身目标 2 秒、结冰水面 6 秒；焰星融冰、蒸发水分、引燃木质物件。结霜岩块受焰星追加 24 点原始伤害，再按硬度结算。",15)
	intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(intro)
	for id in GameData.GU_ORDER:
		var g:Dictionary=GameData.GU[id]
		var card:=UIStyle.card(stack)
		var title:=HBoxContainer.new()
		var icon:=GuArt.portrait(38)
		icon.texture=GuArt.texture(id)
		title.add_child(icon)
		title.add_child(UIStyle.label(GuProgression.title(id)+" · "+g.skill.name,16,UIStyle.JADE))
		card.add_child(title)
		var explanation:=UIStyle.label(GuProgression.power(id)+"\n"+g.flavor+"\n"+GameData.activation_hint(id,game.player.aperture.stage,game.player.aperture.rank),15,UIStyle.INK)
		explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		card.add_child(explanation)
		descriptions[id]=explanation
	stack.add_child(UIStyle.label("辅光需先开启，再催月刃；两蛊同时扣元，多只小光不叠加。豕蛊增长的是肉身力量，不提高月刃伤害或修行境界。",14,UIStyle.DIM))
	visibility_changed.connect(refresh)

func refresh() -> void:
	for id in descriptions:
		descriptions[id].text=GuProgression.power(id)+"\n"+GameData.GU[id].flavor+"\n"+GameData.activation_hint(id,game.player.aperture.stage,game.player.aperture.rank)

static func status_text(status: Dictionary) -> String:
	var text: Array[String]=[]
	for key in STATUSES:
		if float(status.get(key,0))>0:
			text.append("%s %.1fs" % [STATUSES[key],float(status[key])])
	return " / ".join(text)
