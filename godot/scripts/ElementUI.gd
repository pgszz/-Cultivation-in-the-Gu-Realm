class_name ElementUI
extends Control

const REACTIONS := {}
const SHORT_EFFECT := {}
const STATUSES := {"burn":"燃烧","poison":"中毒","wet":"潮湿","shock":"感电","slow":"减速","bleed":"流血","bind":"束缚"}
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
	var intro:=UIStyle.label("查看每只蛊虫的催动方式、真元消耗与食性。组合效果取决于具体蛊术。",15)
	intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(intro)
	for id in GameData.GU_ORDER:
		var g:Dictionary=GameData.GU[id]
		var card:=UIStyle.card(stack)
		var title:=HBoxContainer.new()
		var icon:=GuArt.portrait(38)
		icon.texture=GuArt.texture(id)
		title.add_child(icon)
		title.add_child(UIStyle.label(g.name+" · "+g.skill.name,18,UIStyle.JADE))
		card.add_child(title)
		var explanation:=UIStyle.label(g.flavor+"\n"+GameData.activation_hint(id,game.player.aperture.stage),15,UIStyle.INK)
		explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		card.add_child(explanation)
		descriptions[id]=explanation
	stack.add_child(UIStyle.label("组合催蛊需有具体机制和依据。小光蛊辅助月光蛊有正文依据，但尚未接入，当前不显示为可用。",14,UIStyle.DIM))
	visibility_changed.connect(refresh)

func refresh() -> void:
	for id in descriptions:
		descriptions[id].text=GameData.GU[id].flavor+"\n"+GameData.activation_hint(id,game.player.aperture.stage)

static func status_text(status: Dictionary) -> String:
	var text: Array[String]=[]
	for key in STATUSES:
		if float(status.get(key,0))>0:
			text.append("%s %.1fs" % [STATUSES[key],float(status[key])])
	return " / ".join(text)
