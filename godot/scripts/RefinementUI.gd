class_name RefinementUI
extends Control

var game: Node
var selected_recipe := "moon_glow"
var picture: TextureRect
var detail: RichTextLabel
var action: Button
var result_note: Label
var recipe_buttons: Dictionary={}

func _ready() -> void:
	var cols:=HBoxContainer.new()
	UIStyle.fill(cols)
	cols.add_theme_constant_override("separation",12)
	add_child(cols)
	var left:=UIStyle.card(cols,245)
	left.get_parent().size_flags_horizontal=SIZE_FILL
	left.add_child(UIStyle.label("合炼 · 一转 → 二转",20,UIStyle.GOLD))
	for id in GuProgression.RECIPES:
		var button:=UIStyle.button(GuProgression.title(id),select_recipe.bind(id))
		button.add_theme_font_size_override("font_size",13)
		GuArt.decorate(button,id,42)
		left.add_child(button)
		recipe_buttons[id]=button
	left.add_child(UIStyle.button("查看空窍与修为 →",func(): game.open_journal("aperture")))
	var explanation:=UIStyle.label("R 炼化：收服单只野生蛊。\n此页合炼：消耗多只已炼化蛊，炼成更高转蛊。\n\n三条蛊方公开供自由探索使用，不要求跟随小说剧情。",13,UIStyle.DIM)
	explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	left.add_child(explanation)
	var right:=UIStyle.card(cols,350)
	var heading:=HBoxContainer.new()
	right.add_child(heading)
	picture=GuArt.portrait(84)
	heading.add_child(picture)
	var note:=UIStyle.label("先检查材料与代价，再进行合炼。\n成功会消耗列出的材料蛊。",14,UIStyle.GOLD)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	note.size_flags_horizontal=SIZE_EXPAND_FILL
	heading.add_child(note)
	detail=UIStyle.rich(14)
	detail.size_flags_vertical=SIZE_EXPAND_FILL
	right.add_child(detail)
	result_note=UIStyle.label("",13,UIStyle.JADE)
	result_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	right.add_child(result_note)
	action=UIStyle.button("合炼",_fuse)
	right.add_child(action)
	refresh()

func select_recipe(id: String) -> void:
	selected_recipe=id
	result_note.text=""
	refresh()

func _fuse() -> void:
	GuRefinement.fuse(game,selected_recipe)
	result_note.text=game.last_action_message
	refresh()

func refresh() -> void:
	if detail==null: return
	var id:=selected_recipe
	var r:Dictionary=GuProgression.RECIPES[id]
	var p:Player=game.player
	picture.texture=GuArt.texture(id)
	for key in recipe_buttons: recipe_buttons[key].modulate=UIStyle.GOLD if key==id else Color.WHITE
	var text:="[font_size=20][color=#d8bc7c]%s[/color][/font_size]\n%s\n\n[color=#76c2aa]威力变化[/color]\n%s\n\n[color=#d8bc7c]需要的已炼化蛊[/color]\n" % [GuProgression.title(id),GuProgression.rarity_note(id),r.change]
	for tid in r.inputs:
		var count:=0
		for gu in game.get_node("/root/Gus").owned_gus:
			if gu.template_id==tid and not gu.dead and gu.location!="bag": count+=1
		text+="%s · 一转：%d / %d\n" % [GameData.GU[tid].name,count,r.inputs[tid]]
	var materials:=GuRefinement.materials(game,id)
	if not materials.is_empty():
		text+="将消耗："
		for gu in materials:
			text+="%s%s（饱腹 %.0f%%） " % [gu.name,"【本命→产物继承】" if gu.id==p.vital_gu_id else "",game.get_node("/root/Hunger").get_hunger(gu.id)]
	text+="\n\n每次花费：%d 元石（持有 %d） · 耗真元 %.2f 点\n成功率 %.0f%%；失败也扣费用，材料保留。\n" % [r.stones,p.crystals,p.aperture.cost_at_stage(r.essence),float(r.chance)*100]
	text+="[color=#93a99f]依据：%s。蛊虫组合与转数来自原著；费用、成功率、即时结算、精确减伤为游戏模拟。本版尚未模拟失败毁蛊或本命反噬。白玉采用常见双蛊方，未加入雪獠牙改良方。[/color]" % r.source
	detail.text=text
	var reason:=GuRefinement.blocker(game,id)
	action.disabled=reason!=""
	action.text=reason if reason!="" else "尝试合炼 · 消耗上述材料与 %d 元石" % r.stones
	action.tooltip_text=reason
