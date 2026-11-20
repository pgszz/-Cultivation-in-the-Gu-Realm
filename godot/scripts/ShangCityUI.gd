class_name ShangCityUI
extends Control

var city: ShangCity
var panel: PanelContainer
var rows: VBoxContainer
var scroll: ScrollContainer
var heading: Label
var note: Label
var banner: TextureRect
var mode := "travel"
var buttons: Dictionary={}
var stone_view: ShangStoneView
var last_result: Dictionary={}

func _ready() -> void:
	UIStyle.fill(self)
	visible=false
	mouse_filter=MOUSE_FILTER_STOP
	var shade:=ColorRect.new()
	UIStyle.fill(shade)
	shade.color=Color(0.015,0.03,0.035,0.9)
	add_child(shade)
	panel=PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left=24
	panel.offset_right=-24
	panel.offset_top=18
	panel.offset_bottom=-18
	panel.add_theme_stylebox_override("panel",UIStyle.box(Color("152a29"),UIStyle.GOLD,9))
	add_child(panel)
	var layout:=VBoxContainer.new()
	layout.add_theme_constant_override("separation",7)
	panel.add_child(layout)
	var top:=HBoxContainer.new()
	layout.add_child(top)
	heading=UIStyle.label("商家城",22,UIStyle.GOLD)
	heading.size_flags_horizontal=SIZE_EXPAND_FILL
	top.add_child(heading)
	var close_button:=UIStyle.button("返回游历  Esc",close)
	close_button.name="CloseCity"
	top.add_child(close_button)
	banner=TextureRect.new()
	banner.texture=city.panorama
	banner.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	banner.custom_minimum_size.y=120
	banner.mouse_filter=MOUSE_FILTER_IGNORE
	layout.add_child(banner)
	var tabs:=HBoxContainer.new()
	layout.add_child(tabs)
	for tab in [ ["travel","城镇指南"],["arena","演武场"],["stones","赌石坊"],["market","百货商楼"],["inn","客栈"],["guild","货栈订单"] ]:
		var b:=UIStyle.button(tab[1],open.bind(tab[0]))
		b.size_flags_horizontal=SIZE_EXPAND_FILL
		tabs.add_child(b)
	note=UIStyle.label("",14,UIStyle.GOLD)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(note)
	scroll=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=SIZE_EXPAND_FILL
	layout.add_child(scroll)
	rows=VBoxContainer.new()
	rows.size_flags_horizontal=SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",9)
	scroll.add_child(rows)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()

func open(page: String = "travel") -> void:
	if city.game.player.dead or not city.game.running: return
	city.game.journal.close()
	city.game.village_ui.close()
	city.game._world_attack_held=false
	mode=page
	visible=true
	city.game.paused=true
	refresh()
	scroll.scroll_vertical=0

func close() -> void:
	visible=false
	if city.game.running and not city.game.player.dead: city.game.paused=false

func paragraph(text: String, color: Color = UIStyle.INK) -> void:
	var l:=UIStyle.label(text,15,color)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(l)

func action(text: String, id: String, callback: Callable, enabled: bool = true) -> Button:
	var b:=UIStyle.button(text,callback)
	b.name=id
	b.disabled=not enabled
	rows.add_child(b)
	buttons[id]=b
	return b

func perform(callback: Callable) -> void:
	callback.call()
	refresh()

func refresh() -> void:
	for child in rows.get_children(): rows.remove_child(child); child.queue_free()
	buttons.clear()
	heading.text="商家城 · %s     元石 %d"%[{"travel":"城镇指南","arena":"演武场","stones":"赌石坊","market":"百货商楼","inn":"行客栈","guild":"商队货栈"}.get(mode,"游历"),city.game.player.crystals]
	note.text=city.notice
	if mode!="travel" and not city.available(mode) and not (mode=="arena" and city.bout):
		paragraph("请走到对应建筑门前办理。建筑损毁后须先按 F 修缮。",UIStyle.DIM)
		if city.active:
			action("在街道标出路线", "Guide",func(): city.guide=mode; close())
	match mode:
		"travel":
			paragraph("商量山 · 商家城\n山外商街与山内五区。当前开放缩尺外城商区和第五内城演武坪；随商队往返青茅山，不要求推进小说剧情。")
			paragraph("WASD / 方向键行走，E 在门前办理服务，左键和蛊术可破坏建筑，F 检查 / 重建。演武场内用同一套战斗与人体规则，死亡仍会永久封存角色。",UIStyle.DIM)
			if not city.active:
				action("随商队前往商家城 · 免费试玩交通", "EnterCity",func():
					if city.enter(): close()
					else: refresh())
			else:
				for b in ShangCityData.BUILDINGS:
					var state:String=city.game.world.destruction.state_text("shang:"+b.id)
					action(b.name+" · "+state+" · 标出路线", "Route_"+b.id,func(): city.guide=b.id; close())
				var near_gate:bool=city.game.player.position.distance_to(ShangCityData.ORIGIN+ShangCityData.GATE)<110
				action("随商队返回青茅山（南门驿站办理）", "LeaveCity",func(): city.leave(),near_gate and not city.bout)
			paragraph("原著参考：分层山城、演武净胜场、购买原石后解石及空石 / 死蛊 / 活蛊。城镇布局、费用、概率、NPC 和订单为游戏改编；未开放内城资格与完整演武排名。",UIStyle.DIM)
		"arena":
			paragraph("战绩 %d 胜 / %d 负 · 净胜 %d 场\n每净胜 10 场提升一档对手，最多三档；当前仍在第五内城试玩演武场。"%[city.wins,city.losses,city.wins-city.losses])
			paragraph("报名 20 元石，胜出获 50 元石；180 秒未决、认输或中途退出游戏记负。暂停不计时。胜利不增加修为。气血不足一半不能报名；一旦死亡，角色存档永久作废。",UIStyle.DIM)
			if city.bout:
				paragraph("本场已进行 %.0f / 180 秒 · 当前对手：%s"%[city.bout_time,ShangCityData.OPPONENTS[city.bout_level].name],UIStyle.RED)
				action("继续战斗", "ResumeBout",close)
				action("认输离场 · 记一负", "Surrender",func(): city.finish_bout(false); refresh())
			else: action("报名上场 · 20 元石", "StartBout",func():
				if not city.start_bout(): refresh(),city.available("arena"))
		"stones":
			paragraph("先买石，再解石。原石编号、封存内容与解石运数随角色保存，重新打开面板或读档不会重抽。",UIStyle.DIM)
			for tier in ShangCityData.STONES:
				paragraph("%s · %d 元石｜空石 %d%% / 死蛊 %d%% / 活蛊 %d%%"%[tier.name,tier.price,tier.empty,tier.dead,tier.live])
			paragraph("粗解免费，活蛊保全率 55%；精解另收 6 元石，保全率 95%。以上概率均为试玩参数。开出活蛊后仍需炼化。",UIStyle.DIM)
			stone_view=ShangStoneView.new()
			stone_view.result=last_result
			rows.add_child(stone_view)
			for row in city.stones:
				paragraph("待解 #%d · %s"%[row.id,ShangCityData.STONES[int(row.tier)].name],UIStyle.GOLD)
				var id:int=row.id
				action("粗解 #%d · 免费"%id,"Rough_"+str(id),func(): reveal(id,false),city.available("stones"))
				action("精解 #%d · 6 元石"%id,"Careful_"+str(id),func(): reveal(id,true),city.available("stones"))
			for row in city.offers:
				var id:int=row.id
				var tier:Dictionary=ShangCityData.STONES[int(row.tier)]
				action("购入 #%d · %s · %d 元石"%[id,tier.name,tier.price],"BuyStone_"+str(id),perform.bind(city.buy_stone.bind(id)),city.available("stones"))
			for entry in city.ledger: paragraph(entry,UIStyle.DIM)
		"market":
			for id in ShangCityData.STOCK:
				action("%s ×1 · %d 元石"%[city.game.get_node("/root/Inv").get_item_name(id),ShangCityData.STOCK[id]],"Buy_"+id,perform.bind(city.buy_supply.bind(id)),city.available("market"))
		"inn":
			paragraph("客栈休息：气血最多恢复 35、体力最多恢复 50。不会修复部位伤势、复活蛊虫或改变境界。")
			action("休息 · 15 元石", "Rest",perform.bind(city.rest),city.available("inn"))
		"guild":
			paragraph("每份订单每个角色仅可完成一次，交付消耗真实背包物品。",UIStyle.DIM)
			for row in ShangCityData.CONTRACTS:
				var owned:int=city.game.get_node("/root/Inv").get_item_count(row.item)
				action("%s · %d / %d · 报酬 %d 元石%s"%[row.name,owned,row.count,row.reward," · 已交付" if city.delivered.has(row.id) else ""],"Deliver_"+row.id,perform.bind(city.deliver.bind(row.id)),city.available("guild") and not city.delivered.has(row.id))

func reveal(id: int, careful: bool) -> void:
	var value:=city.open_stone(id,careful)
	if not value.is_empty(): last_result=value
	refresh()
	if not value.is_empty(): stone_view.reveal(value)
