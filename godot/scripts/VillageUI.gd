class_name VillageUI
extends Control

var game: Node
var title: Label
var description: Label
var actions: VBoxContainer
var message: Label
var action_scroll: ScrollContainer
var order_buttons: Dictionary = {}
var camp_claim: Button
var camp_treat: Button
var mode := ""

func _ready()->void:
	UIStyle.fill(self)
	var shade:=ColorRect.new()
	shade.color=Color(0.02,0.05,0.05,0.72)
	UIStyle.fill(shade)
	add_child(shade)
	var center:=CenterContainer.new()
	UIStyle.fill(center)
	add_child(center)
	var panel:=PanelContainer.new()
	panel.custom_minimum_size=Vector2(590,530)
	panel.add_theme_stylebox_override("panel",UIStyle.box())
	center.add_child(panel)
	var layout:=VBoxContainer.new()
	layout.add_theme_constant_override("separation",10)
	panel.add_child(layout)
	title=UIStyle.label("",22,UIStyle.GOLD)
	layout.add_child(title)
	description=UIStyle.label("",16)
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x=510
	layout.add_child(description)
	action_scroll=ScrollContainer.new()
	action_scroll.size_flags_vertical=SIZE_EXPAND_FILL
	action_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	action_scroll.custom_minimum_size.y=270
	layout.add_child(action_scroll)
	actions=VBoxContainer.new()
	actions.size_flags_horizontal=SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation",10)
	action_scroll.add_child(actions)
	message=UIStyle.label("",15,UIStyle.JADE)
	message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(message)
	layout.add_child(UIStyle.button("告辞 · Esc",close))
	visible=false

func _prepare(kind: String) -> void:
	mode=kind
	order_buttons.clear()
	camp_claim=null
	camp_treat=null
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	action_scroll.scroll_vertical=0
	message.text=""
	visible=true
	game.paused=true

func show_service(kind:String)->void:
	_prepare(kind)
	match kind:
		"clinic":
			title.text="古月药堂 · 普通医者"
			description.text="目前提供普通伤口包扎。缺失的肢体或眼睛，需要具备相应效用的蛊术；这里不会付钱直接再生。"
			actions.add_child(UIStyle.button("包扎出血伤口 · 2 元石",func():
				game.clinic_heal()
				message.text=game.last_action_message
			))
			actions.add_child(UIStyle.button("绷带 ×1 · 1 元石",_buy.bind("bandage",1)))
		"shop":
			title.text="古月商铺 · 补给"
			description.text="月兰花瓣供月光蛊食用；青竹酒供酒虫饮用；玉石供玉皮蛊吞食。蛊食不能通用。"
			actions.add_child(UIStyle.button("月兰花瓣 ×10 · 1 元石",func():
				if game.buy_supply("moon_petals",1):
					game.get_node("/root/Inv").add_item("moon_petals",9)
					game.save_game()
				message.text=game.last_action_message
			))
			actions.add_child(UIStyle.button("青竹酒 ×1坛 · 2 元石",_buy.bind("bamboo_wine",2)))
			actions.add_child(UIStyle.button("玉石 ×2两 · 4 元石",_buy.bind("jade",4)))
			actions.add_child(UIStyle.button("绷带 ×1 · 1 元石",_buy.bind("bandage",1)))
			var jade_button:=UIStyle.button("玉皮蛊 · 500 元石 · 仅一只",func():
				game.buy_jade_gu()
				message.text=game.last_action_message
			)
			GuArt.decorate(jade_button,"jade_skin",36)
			actions.add_child(jade_button)
			actions.add_child(UIStyle.button("山寨委托 · 材料与踏查 →",show_commissions))
			actions.add_child(UIStyle.button("出售猎获与材料 →",func():
				close()
				game.open_journal("inventory")
			))
		"bai":
			title.text="白家寨"
			description.text="青茅山三寨之一。家族的标志蛊虫是溪流蛊。此处是缩尺会客场景，白家人物与家族事件尚未开放。"
		"xiong":
			title.text="熊家寨 · 山脚"
			description.text="青茅山三寨中位置最低。家族的标志蛊虫是熊力蛊。这里的会客场景不代表完整山寨。"
		"ancestral":
			title.text="古月宗族祠堂"
			description.text="宗族祭祀与家老议事的场所。古月一族以地下灵泉为根基；开窍大典在地下溶洞举行。"
		_:
			title.text="古月学堂 · 地理与修行"
			description.text="青茅山位于南疆，山上有古月、白家、熊家三寨。黑白两天轮转，五域之间有界壁。"
			actions.add_child(UIStyle.button("山寨委托 · 材料与踏查 →",show_commissions))
			actions.add_child(UIStyle.button("查看地理志",func():
				close()
				game.open_journal("map")
			))

func show_camp(site: Dictionary) -> void:
	_prepare("camp")
	title.text=site.name+" · 歇脚"
	description.text=site.text+"\n包扎优先处理出血；打坐按时间温养窍壁，毁损部位不会再生。"
	camp_claim=UIStyle.button("领取补给 · 绷带 ×2 / 青竹酒 ×1",func():
		game.claim_camp_supplies(site.id)
		var result:String=game.last_action_message
		show_camp(site)
		message.text=result
	)
	camp_claim.disabled=game.claimed_camps.has(site.id)
	if camp_claim.disabled: camp_claim.text="补给已领取 · 此处不再刷新"
	actions.add_child(camp_claim)
	var bandages:int=game.get_node("/root/Inv").get_item_count("bandage")
	camp_treat=UIStyle.button("包扎紧急伤口 · 绷带 %d"%bandages,func():
		game.field_bandage()
		var result:String=game.last_action_message
		show_camp(site)
		message.text=result
	)
	camp_treat.disabled=bandages<=0
	actions.add_child(camp_treat)
	actions.add_child(UIStyle.button("就地打坐 · J 可收功",func():
		close()
		game.toggle_meditation()
	))
	actions.add_child(UIStyle.button("查看身体与伤势",_open_page.bind("body")))
	actions.add_child(UIStyle.button("整理行囊",_open_page.bind("inventory")))
	actions.add_child(UIStyle.button("查看游历记录",func():
		_open_page("map")
		game.minimap_ui.set_mode("notes")
	))

func _open_page(page: String) -> void:
	close()
	game.open_journal(page)

func show_commissions() -> void:
	_prepare("commissions")
	title.text="山寨委托 · 自由接取"
	var available:bool=game.commissions.at_counter(game)
	description.text="材料、踏查均可赚取供养所需。游历记录随时计入，没有完成期限。\n"+("交付处：古月商铺 / 学堂 · 元石 %d"%game.player.crystals if available else "当前仅查看；到古月商铺或学堂接取、交付。")
	var inv:Inventory=game.get_node("/root/Inv")
	for id in CommissionLedger.ORDERS:
		var d:Dictionary=CommissionLedger.ORDERS[id]
		var s:Dictionary=game.commissions.state(id)
		var card:=UIStyle.card(actions)
		card.size_flags_vertical=SIZE_SHRINK_BEGIN
		card.add_child(UIStyle.label(d.name,18,UIStyle.GOLD))
		var summary:=UIStyle.label(d.desc+"\n"+game.commissions.progress(id,game),14)
		summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		card.add_child(summary)
		var rewards:Array[String]=["元石 %d"%d.stones]
		for item in d.reward: rewards.append("%s ×%d"%[inv.get_item_name(item),d.reward[item]])
		card.add_child(UIStyle.label("报酬："+" · ".join(rewards),13,UIStyle.JADE))
		var row:=HBoxContainer.new()
		card.add_child(row)
		var button:=UIStyle.button("接取委托",_commission_action.bind(id))
		button.size_flags_horizontal=SIZE_EXPAND_FILL
		button.disabled=not available
		if s.accepted:
			button.text="交付委托" if game.commissions.ready(id,game) else "进行中 · 条件未满足"
			button.disabled=not available or not game.commissions.ready(id,game)
		elif s.remaining>0:
			button.text="%d 秒游玩后可再接"%ceili(s.remaining)
			button.disabled=true
		elif s.completed>0 and d.cooldown==0:
			button.text="已完成 · 报酬已领取"
			button.disabled=true
		if not available: button.tooltip_text="需到商铺或学堂，且服务人物存活、未敌对。"
		row.add_child(button)
		order_buttons[id]=button
		var next:Dictionary=game.commissions.next_site(id,game)
		if not next.is_empty(): row.add_child(UIStyle.button("标记下一处",_mark_order.bind(next)))

func _commission_action(id: String) -> void:
	if game.commissions.state(id).accepted: game.commissions.submit(id,game)
	else: game.commissions.accept(id,game)
	var result:String=game.last_action_message
	var scroll:int=action_scroll.scroll_vertical
	show_commissions()
	action_scroll.set_deferred("scroll_vertical",scroll)
	message.text=result

func _mark_order(site: Dictionary) -> void:
	game.waypoint=Vector2(site.pos)*World.TILE+Vector2(16,16)
	game.waypoint_name=site.name
	game.save_game()
	message.text="已标记「"+site.name+"」，离开菜单后可跟随方向前往。"

func _buy(id:String,cost:int)->void:
	game.buy_supply(id,cost)
	message.text=game.last_action_message

func close()->void:
	visible=false
	game.paused=false
