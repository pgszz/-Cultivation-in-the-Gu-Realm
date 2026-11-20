class_name NpcInspectUI
extends Control

var game: Node
var person: Npc
var panel: PanelContainer
var portrait: TextureRect
var name_label: Label
var role_label: Label
var health_label: Label
var health_bar: ProgressBar
var affinity_label: Label
var affinity_bar: ProgressBar
var summary: RichTextLabel
var details: RichTextLabel
var context_label: Label
var talk_button: Button
var close_button: Button
var tabs: Dictionary = {}
var active_tab := "attributes"
var refresh_timer := 0.0
var _last_snapshot: Dictionary = {}
var items_panel: VBoxContainer
var items_list: VBoxContainer
var item_scroll: ScrollContainer
var funds_label: Label
var quantity: SpinBox
var inventory_button: Button
var loot_all_button: Button
var item_buttons: Dictionary = {}
var owner_button: Button
var player_button: Button
var gift_button: Button
var theft_button: Button
var item_mode := "buy"
var selling := false
var feedback := ""

func _ready() -> void:
	UIStyle.fill(self)
	mouse_filter=MOUSE_FILTER_STOP
	var shade:=ColorRect.new()
	shade.color=Color(0.015,0.04,0.04,0.65)
	UIStyle.fill(shade)
	add_child(shade)
	panel=PanelContainer.new()
	UIStyle.fill(panel)
	panel.add_theme_stylebox_override("panel",UIStyle.box(Color("102321"),Color("72816a"),12))
	add_child(panel)
	resized.connect(_layout_panel)
	_layout_panel()
	var layout:=VBoxContainer.new()
	layout.add_theme_constant_override("separation",14)
	panel.add_child(layout)
	var heading:=HBoxContainer.new()
	layout.add_child(heading)
	var title:=UIStyle.label("人 物 查 看",23,UIStyle.GOLD)
	title.size_flags_horizontal=SIZE_EXPAND_FILL
	heading.add_child(title)
	close_button=UIStyle.button("返回地图 · Esc",close)
	heading.add_child(close_button)
	var columns:=HBoxContainer.new()
	columns.size_flags_vertical=SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",16)
	layout.add_child(columns)
	var left:=UIStyle.card(columns,230)
	left.get_parent().size_flags_horizontal=SIZE_FILL
	name_label=UIStyle.label("",24,UIStyle.GOLD)
	name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(name_label)
	role_label=UIStyle.label("",14,UIStyle.DIM)
	role_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(role_label)
	portrait=TextureRect.new()
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size=Vector2(0,164 if size.y>=650 else 106)
	portrait.size_flags_vertical=SIZE_FILL
	portrait.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.mouse_filter=MOUSE_FILTER_IGNORE
	left.add_child(portrait)
	health_label=UIStyle.label("",15)
	left.add_child(health_label)
	health_bar=UIStyle.meter(100,100,UIStyle.JADE)
	left.add_child(health_bar)
	affinity_label=UIStyle.label("",15,UIStyle.GOLD)
	left.add_child(affinity_label)
	affinity_bar=UIStyle.meter(100,200,UIStyle.GOLD)
	left.add_child(affinity_bar)
	summary=UIStyle.rich(15)
	summary.custom_minimum_size.y=60
	left.add_child(summary)
	var right:=UIStyle.card(columns)
	var navigation:=HBoxContainer.new()
	right.add_child(navigation)
	for entry in [["attributes","属性"],["relations","关系"],["history","经历"],["status","状态"],["canon","原著"],["items","物品"]]:
		var button:=UIStyle.button(entry[1],select_tab.bind(entry[0]))
		button.size_flags_horizontal=SIZE_EXPAND_FILL
		navigation.add_child(button)
		tabs[entry[0]]=button
	details=UIStyle.rich(18)
	details.custom_minimum_size.y=180
	right.add_child(details)
	items_panel=VBoxContainer.new()
	items_panel.size_flags_vertical=SIZE_EXPAND_FILL
	items_panel.add_theme_constant_override("separation",8)
	right.add_child(items_panel)
	funds_label=UIStyle.label("",15,UIStyle.GOLD)
	items_panel.add_child(funds_label)
	var item_controls:=HBoxContainer.new()
	items_panel.add_child(item_controls)
	owner_button=UIStyle.button("买入",_set_selling.bind(false))
	player_button=UIStyle.button("出售",_set_selling.bind(true))
	gift_button=UIStyle.button("赠礼",_set_item_mode.bind("gift"))
	theft_button=UIStyle.button("盗窃",_set_item_mode.bind("theft"))
	item_controls.add_child(owner_button)
	item_controls.add_child(player_button)
	item_controls.add_child(gift_button)
	item_controls.add_child(theft_button)
	for button:Button in [owner_button,player_button,gift_button,theft_button]:
		button.size_flags_horizontal=SIZE_EXPAND_FILL
	var spacer:=Control.new()
	spacer.size_flags_horizontal=SIZE_EXPAND_FILL
	item_controls.add_child(spacer)
	item_controls.add_child(UIStyle.label("数量",13,UIStyle.DIM))
	quantity=SpinBox.new()
	quantity.min_value=1
	quantity.max_value=99
	quantity.value=1
	quantity.custom_minimum_size.x=82
	quantity.value_changed.connect(func(_value): refresh())
	item_controls.add_child(quantity)
	item_scroll=ScrollContainer.new()
	item_scroll.size_flags_vertical=SIZE_EXPAND_FILL
	item_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	items_panel.add_child(item_scroll)
	items_list=VBoxContainer.new()
	items_list.size_flags_horizontal=SIZE_EXPAND_FILL
	items_list.add_theme_constant_override("separation",7)
	item_scroll.add_child(items_list)
	var note:=UIStyle.label("仅含随身普通物品；店铺货架与蛊虫另行管理。",12,UIStyle.DIM)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	items_panel.add_child(note)
	context_label=UIStyle.label("",14,UIStyle.DIM)
	context_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	right.add_child(context_label)
	var action_row:=HBoxContainer.new()
	right.add_child(action_row)
	talk_button=UIStyle.button("交谈",_talk)
	talk_button.custom_minimum_size.y=40
	talk_button.size_flags_horizontal=SIZE_EXPAND_FILL
	action_row.add_child(talk_button)
	inventory_button=UIStyle.button("物品与交易",select_tab.bind("items"))
	action_row.add_child(inventory_button)
	loot_all_button=UIStyle.button("全部搜刮",_loot_all)
	action_row.add_child(loot_all_button)
	layout.add_child(UIStyle.label("查看时暂停 · 顶部头像 / Alt + 左键查看 · 近处可交谈与操作物品",13,UIStyle.DIM))
	hide()

func _layout_panel() -> void:
	if panel==null: return
	if portrait!=null: portrait.custom_minimum_size.y=164 if size.y>=650 else 106
	var margin_x:=maxf(18,(size.x-920)*0.5)
	var margin_y:=maxf(18,(size.y-570)*0.5)
	panel.offset_left=margin_x
	panel.offset_right=-margin_x
	panel.offset_top=margin_y
	panel.offset_bottom=-margin_y

func show_person(target: Npc) -> void:
	person=target
	_last_snapshot.clear()
	active_tab="attributes"
	selling=false
	item_mode="buy"
	feedback=""
	quantity.value=1
	person.ensure_possessions()
	game._world_attack_held=false
	game.paused=true
	show()
	refresh()

func close() -> void:
	hide()
	person=null
	game._world_attack_held=false
	if game.running and not game.player.dead: game.paused=false

func select_tab(key: String) -> void:
	active_tab=key
	feedback=""
	refresh()
	details.scroll_to_line(0)

func refresh() -> void:
	if not is_instance_valid(person): return
	tabs.canon.visible=CanonPeople.has(person.resident_id)
	if active_tab=="canon" and not tabs.canon.visible: active_tab="attributes"
	var info:=person.inspection_data()
	info["social"]=person.social.save_data(person)
	if active_tab=="relations": info["bonds"]=person.social.relations(person)
	info["tab"]=active_tab
	info["talk_blocker"]=game.person_talk_blocker(person)
	info["exchange_blocker"]=PersonExchange.blocker(game,person,person.dead)
	if active_tab=="items":
		if person.dead:
			item_mode="buy"
			selling=false
		info["possessions"]=person.save_possessions()
		info["player_items"]=game.get_node("/root/Inv").items.duplicate()
		info["player_crystals"]=game.player.crystals
		info["selling"]=selling
		info["item_mode"]=item_mode
		info["gift_wait"]=ceili(person.social.cooldown_left(person,"gift"))
		info["theft_wait"]=ceili(person.social.cooldown_left(person,"theft"))
		info["social_blocker"]=PersonExchange.social_blocker(game,person,"赠礼" if item_mode=="gift" else "盗窃") if item_mode in ["gift","theft"] else ""
		info["quantity"]=quantity.value
		info["feedback"]=feedback
	if info==_last_snapshot: return
	_last_snapshot=info
	name_label.text=info.name
	role_label.text=info.faction+" · "+info.role
	portrait.texture=NpcAppearance.portrait(person.get_appearance(),person.dead)
	health_label.text="气血 %.0f / %.0f · %s" % [info.hp,info.max_hp,info.health]
	health_bar.max_value=info.max_hp
	health_bar.value=info.hp
	health_bar.modulate=UIStyle.RED if person.dead or person.hp<=person.max_hp*0.25 else Color.WHITE
	affinity_label.text="好感 %+d · %s" % [person.social.affinity,person.social.label(person)]
	affinity_label.add_theme_color_override("font_color",person.social.tint(person))
	affinity_bar.value=person.social.affinity+100
	affinity_bar.modulate=person.social.tint(person)
	summary.text="%s\n%s · %s\n衣着 · %s\n\n%s" % [info.place,info.relationship,info.activity,NpcAppearance.STYLES[person.get_appearance()].name,info.description]
	for key in tabs: tabs[key].modulate=UIStyle.GOLD if key==active_tab else Color.WHITE
	details.visible=active_tab!="items"
	items_panel.visible=active_tab=="items"
	loot_all_button.visible=active_tab=="items" and person.dead
	inventory_button.visible=active_tab!="items"
	inventory_button.text="搜刮遗物" if person.dead else "物品与交易"
	match active_tab:
		"canon": details.text=CanonPeople.lore(person.resident_id)
		"attributes":
			details.text="[color=#d8bc7c]身份与能力[/color]\n\n身份    %s\n职责    %s\n修为    未探明\n持有蛊虫    未探明\n\n[color=#d8bc7c]徒手行动[/color]\n\n基础攻击    %.0f\n出手间隔    %.1f 秒\n追击速度    %.0f 像素/秒\n\n[color=#93a99f]能力数值为存活时的基础值；当前能否行动见「状态」。[/color]" % [info.role,info.duty,info.get("attack",Npc.ATTACK_DAMAGE),info.get("interval",Npc.ATTACK_INTERVAL),info.get("speed",Npc.PURSUIT_SPEED)]
		"relations":
			details.text="[color=#d8bc7c]与你的关系[/color]\n\n%s · %s    好感 %+d / 100\n%s\n\n[color=#d8bc7c]人物往来 · %d 人[/color]\n所属势力    %s\n\n" % [info.relationship,person.social.label(person),person.social.affinity,info.relationship_reason,info.bonds.size(),info.faction]
			for bond in info.bonds:
				details.text+="[color=#d8bc7c]%s[/color]    %s%s\n" % [bond.name,bond.kind," · 已故" if bond.dead else ""]
			if info.bonds.is_empty(): details.text+="尚无已记录的人物往来。\n"
			details.text+="\n[color=#93a99f]标注「原著」的亲缘来自正文，其余关系来自同寨生活、同行护送与实际交战。[/color]"
		"history":
			details.text="[color=#d8bc7c]人物经历[/color]\n[color=#93a99f]记录实际发生的交往、行程与伤亡，最近 %d 条。\n游历时间只在正常游玩中推进。[/color]\n\n" % NpcSocial.HISTORY_LIMIT
			if person.social.history.is_empty(): details.text+="尚无经历记录。与此人交谈或交易后会留下记载。"
			for i in range(person.social.history.size()-1,-1,-1):
				var entry:Dictionary=person.social.history[i]
				var change:="  好感 %+d" % int(entry.change) if int(entry.change)!=0 else ""
				details.text+="[color=#d8bc7c]%s%s[/color]\n%s%s\n\n" % [NpcSocial.stamp(entry.time),change,str(entry.text).replace("[","[lb]"),"（共 %d 次）" % int(entry.count) if int(entry.count)>1 else ""]
		"status":
			details.text="[color=#d8bc7c]身体与行动[/color]\n\n生命    %s\n气血    %.0f / %.0f\n伤势    %s\n行动    %s\n\n[color=#d8bc7c]交谈与服务[/color]\n\n%s\n\n[color=#93a99f]交谈不会自动消除敌对，死亡后不能继续提供服务。[/color]" % ["已死亡" if person.dead else "存活",info.hp,info.max_hp,info.health,info.activity,game.person_talk_blocker(person) if game.person_talk_blocker(person)!="" else "可以交谈"]
	var reason:String=game.person_talk_blocker(person)
	talk_button.disabled=reason!=""
	talk_button.text="交谈 · "+String(info.duty)
	context_label.add_theme_color_override("font_color",UIStyle.DIM)
	context_label.text=reason if reason!="" else "在交谈距离内，可继续办理相关事务。"
	if active_tab=="items": _refresh_items()

func _set_selling(value: bool) -> void:
	_set_item_mode("sell" if value else "buy")

func _set_item_mode(value: String) -> void:
	item_mode=value
	selling=value in ["sell","gift"]
	feedback=""
	refresh()
	item_scroll.scroll_vertical=0

func _refresh_items() -> void:
	for child in items_list.get_children():
		items_list.remove_child(child)
		child.queue_free()
	item_buttons.clear()
	player_button.visible=not person.dead
	gift_button.visible=not person.dead
	theft_button.visible=not person.dead
	owner_button.text="遗留物品" if person.dead else "买入"
	owner_button.modulate=UIStyle.GOLD if item_mode=="buy" else Color.WHITE
	player_button.modulate=UIStyle.GOLD if item_mode=="sell" else Color.WHITE
	gift_button.modulate=UIStyle.GOLD if item_mode=="gift" else Color.WHITE
	theft_button.modulate=UIStyle.RED if item_mode=="theft" else Color.WHITE
	funds_label.text="你的元石  %d    |    对方元石  %d" % [game.player.crystals,person.carried_crystals]
	var reason:=PersonExchange.blocker(game,person,person.dead)
	var hint:="收取实际遗物；装不下的物品仍留在遗体上。" if person.dead else "按所选数量结算，买卖后双方物品与元石立即保存。"
	if item_mode in ["gift","theft"]:
		reason=PersonExchange.social_blocker(game,person,"赠礼" if item_mode=="gift" else "盗窃")
		hint="赠送你的物品 · 每次 1–10 件；是否收礼取决于关系和用途，收礼后间隔 300 秒。" if item_mode=="gift" else "盗窃必定降低好感，反击概率 %d%%；未反击时戒备 300 秒。" % roundi(PersonExchange.theft_retaliation_chance(person)*100)
	context_label.text=feedback if feedback!="" else (reason if reason!="" else hint)
	context_label.add_theme_color_override("font_color",UIStyle.RED if item_mode=="theft" else UIStyle.DIM)
	loot_all_button.disabled=reason!="" or (person.carried_items.is_empty() and person.carried_crystals==0)
	var inv:Inventory=game.get_node("/root/Inv")
	var contents:Dictionary=inv.items if selling else person.carried_items
	if (person.dead or item_mode=="theft") and person.carried_crystals>0:
		var coin_text:="元石 ×%d    收取全部元石" % person.carried_crystals
		var coin_reason:=reason
		if item_mode=="theft":
			var offer:=PersonExchange.theft_offer(game,person,"currency",int(quantity.value))
			coin_reason=offer.reason
			coin_text="元石 ×%d    无法盗取" % person.carried_crystals if coin_reason!="" else "元石 ×%d    盗取 ×%d · 好感 -%d" % [person.carried_crystals,int(quantity.value),offer.loss]
		var coins:=UIStyle.button(coin_text,_item_action.bind("currency"))
		ItemArt.decorate(coins,"currency",36)
		coins.disabled=coin_reason!=""
		coins.tooltip_text=coin_reason
		if item_mode=="theft": coins.modulate=UIStyle.RED
		items_list.add_child(coins)
		item_buttons.currency=coins
	var ids:=contents.keys()
	ids.sort()
	for id in ids:
		if not PersonExchange.ordinary_item(id) or int(contents[id])<=0: continue
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",8)
		row.custom_minimum_size.y=50
		var entry:=VBoxContainer.new()
		items_list.add_child(entry)
		entry.add_child(row)
		var icon:=TextureRect.new()
		icon.texture=ItemArt.texture(id)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size=Vector2(46,46)
		row.add_child(icon)
		var label:=UIStyle.label("%s ×%d" % [inv.get_item_name(id),contents[id]],15)
		label.size_flags_horizontal=SIZE_EXPAND_FILL
		label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		label.tooltip_text=inv.get_item_desc(id)
		row.add_child(label)
		var count:=int(quantity.value)
		var unit:=PersonExchange.price(id,not selling)
		var button:=UIStyle.button("收取 ×%d" % mini(count,int(contents[id])) if person.dead else "%s ×%d · %d 元石" % ["卖出" if selling else "买入",count,unit*count],_item_action.bind(id))
		button.disabled=reason!=""
		if not person.dead and item_mode in ["gift","theft"]:
			var offer:Dictionary=PersonExchange.gift_offer(game,person,id,count) if item_mode=="gift" else PersonExchange.theft_offer(game,person,id,count)
			button.disabled=offer.reason!=""
			button.text=("不收" if item_mode=="gift" else "无法盗取") if button.disabled else ("赠送 ×%d · 好感 +%d" % [count,offer.gain] if item_mode=="gift" else "盗取 ×%d · 好感 -%d" % [count,offer.loss])
			button.tooltip_text=offer.reason
			button.modulate=UIStyle.JADE if item_mode=="gift" else UIStyle.RED
			var explanation:String=offer.reason if offer.reason!="" else (offer.note if item_mode=="gift" else "取走后会被察觉；反击概率 %d%%，可能与你敌对。" % roundi(float(offer.risk)*100))
			var note:=UIStyle.label(explanation,12,UIStyle.DIM if button.disabled else (UIStyle.JADE if item_mode=="gift" else UIStyle.RED))
			note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			entry.add_child(note)
		elif not person.dead:
			var funds:int=person.carried_crystals if selling else game.player.crystals
			var recipient:int=int(person.carried_items.get(id,0)) if selling else inv.get_item_count(id)
			button.disabled=button.disabled or count>int(contents[id]) or funds<unit*count or recipient+count>Inventory.MAX_STACK*10
		else:
			button.disabled=button.disabled or inv.get_item_count(id)>=Inventory.MAX_STACK*10
		row.add_child(button)
		item_buttons[id]=button
	if item_buttons.is_empty(): items_list.add_child(UIStyle.label("遗物已搜空。" if person.dead else "没有可操作的普通物品。",16,UIStyle.DIM))

func _item_action(id: String) -> void:
	if not is_instance_valid(person): return
	if person.dead: PersonExchange.loot(game,person,id,int(quantity.value))
	elif item_mode=="gift": PersonExchange.gift(game,person,id,int(quantity.value))
	elif item_mode=="theft": PersonExchange.steal(game,person,id,int(quantity.value))
	else: PersonExchange.trade(game,person,id,int(quantity.value),not selling)
	feedback=game.last_action_message
	refresh()

func _loot_all() -> void:
	if not is_instance_valid(person): return
	PersonExchange.loot(game,person,"",1,true)
	feedback=game.last_action_message
	refresh()

func _talk() -> void:
	if not is_instance_valid(person): return
	if game.person_talk_blocker(person)!="":
		refresh()
		return
	var target:=person
	close()
	game.talk_to_person(target)

func _process(delta: float) -> void:
	if not visible: return
	if not is_instance_valid(person) or not game.active_npcs().has(person) or not game.running or game.player.dead:
		close()
		return
	refresh_timer+=delta
	if refresh_timer>=0.2:
		refresh_timer=0
		refresh()
