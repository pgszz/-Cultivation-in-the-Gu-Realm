class_name StartScreen
extends Control

var game: Node
var start_button: Button
var note: Label

func _ready()->void:
	UIStyle.fill(self)
	var shade:=ColorRect.new()
	shade.color=Color(0.02,0.06,0.06,0.56)
	UIStyle.fill(shade)
	add_child(shade)
	var margin:=MarginContainer.new()
	UIStyle.fill(margin)
	for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,80)
	for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,64)
	add_child(margin)
	var columns:=HBoxContainer.new()
	columns.add_theme_constant_override("separation",100)
	margin.add_child(columns)
	var left:=VBoxContainer.new()
	left.custom_minimum_size.x=480
	left.size_flags_horizontal=SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",18)
	columns.add_child(left)
	left.add_child(UIStyle.label("南 疆  /  青 茅 山",18,UIStyle.GOLD))
	var spacer:=Control.new()
	spacer.custom_minimum_size.y=20
	left.add_child(spacer)
	left.add_child(UIStyle.label("蛊 道 修 仙",58,Color("f0e6c7")))
	left.add_child(UIStyle.label("山林有灵，万物藏蛊。",22,UIStyle.INK))
	var story:=UIStyle.label("从一座山寨出发。\n温养空窍、炼化用蛊，在青茅三寨之间行走。",17,Color("c3d2bf"))
	story.custom_minimum_size.y=85
	left.add_child(story)
	start_button=UIStyle.button("继续游历  →" if FileAccess.file_exists(game.SAVE_PATH) else "踏入青茅山  →",game.start_game)
	start_button.custom_minimum_size=Vector2(380,56)
	start_button.add_theme_font_size_override("font_size",21)
	left.add_child(start_button)
	left.add_child(UIStyle.button("行走与交互说明",func():
		note.text="WASD 移动 · 左键攻击 · 滚轮缩放 · J 打坐\nE 进屋 / 交谈 / 长按收蛊 · R 炼化\nTab 修行录 · C 人物 · B 身体 · I 背包 · M 地图 · Q 空窍 · V 蛊术"
	))
	note=UIStyle.label("青茅山前期 · 原著规则校正版\n单独存档，保留旧版 save.json；尚非全书剧情复刻。",13,UIStyle.DIM)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size=Vector2(450,86)
	left.add_child(note)
	var right:=VBoxContainer.new()
	right.custom_minimum_size.x=350
	right.size_flags_vertical=SIZE_SHRINK_CENTER
	right.add_theme_constant_override("separation",16)
	columns.add_child(right)
	for item in [["壹  山林行旅","沿山路探索林间、水潭与岩岭。\n地图可标记目的地。"],["贰  寨中烟火","走近屋门按 E 进入。\n药堂包扎，商铺备好蛊食。"],["叁  识己养蛊","修行录汇集属性、伤势与行囊。\n伤在哪里、影响什么，一眼可查。"]]:
		var card:=UIStyle.card(right,350)
		card.get_parent().size_flags_vertical=SIZE_FILL
		card.add_child(UIStyle.label(item[0],20,UIStyle.GOLD))
		card.add_child(UIStyle.label(item[1],15,UIStyle.INK))
