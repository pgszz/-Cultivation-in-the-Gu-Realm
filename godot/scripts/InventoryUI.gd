class_name InventoryUI
extends Control

enum Category {ALL,FOOD,MATERIAL,MEDICINE,GU}
var game: Node
var inventory: Inventory
var food_system: FoodSystem
var current_category := Category.ALL
var slots: Array = []
var status_label: Label
var detail_name: Label
var portrait: TextureRect
var detail_info: RichTextLabel
var detail_use: Button
var detail_drop: Button
var detail_sell: Button
var selected_id := ""
var title_label: Label
var feed_target: OptionButton
var _entries: Array = []
var _elapsed := 0.0

func _ready() -> void:
	inventory = get_node_or_null("/root/Inv")
	food_system = get_node_or_null("/root/Food")
	var columns := HBoxContainer.new()
	UIStyle.fill(columns)
	columns.add_theme_constant_override("separation",16)
	add_child(columns)
	var left := UIStyle.card(columns,470)
	left.get_parent().size_flags_horizontal = SIZE_FILL
	title_label = UIStyle.label("随身行囊",22,UIStyle.GOLD)
	left.add_child(title_label)
	var filters := HBoxContainer.new()
	left.add_child(filters)
	for item in [["全部",Category.ALL],["药物",Category.MEDICINE],["蛊食",Category.FOOD],["材料",Category.MATERIAL],["外部蛊",Category.GU]]:
		var button := UIStyle.button(item[0],_on_category_changed.bind(item[1]))
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		filters.add_child(button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns=7
	grid.add_theme_constant_override("h_separation",5)
	grid.add_theme_constant_override("v_separation",5)
	scroll.add_child(grid)
	for i in 48:
		var slot := UIStyle.button("",_select_index.bind(i))
		slot.custom_minimum_size=Vector2(58,60)
		slot.add_theme_font_size_override("font_size",12)
		slot.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		grid.add_child(slot)
		slots.append(slot)
	status_label=UIStyle.label("选择物品查看用途。",14,UIStyle.DIM)
	status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	left.add_child(status_label)
	var right:=UIStyle.card(columns,290)
	detail_name=UIStyle.label("物品详情",24,UIStyle.GOLD)
	right.add_child(detail_name)
	portrait=GuArt.portrait(78)
	right.add_child(portrait)
	detail_info=UIStyle.rich(16)
	right.add_child(detail_info)
	feed_target=OptionButton.new()
	feed_target.custom_minimum_size.y=38
	feed_target.add_theme_font_size_override("font_size",15)
	feed_target.item_selected.connect(_select_feed_target)
	right.add_child(feed_target)
	detail_use=UIStyle.button("使用",_use_selected)
	right.add_child(detail_use)
	detail_drop=UIStyle.button("丢弃 1 份",_drop_selected)
	right.add_child(detail_drop)
	detail_sell=UIStyle.button("出售 1 份",func():
		if game.sell_supply(selected_id): _set_status(game.last_action_message)
		refresh_inventory()
	)
	right.add_child(detail_sell)
	right.add_child(UIStyle.button("查看治疗目标与伤势 →",func(): game.open_journal("body")))
	if inventory:
		inventory.item_added.connect(func(_id,_amount): refresh_inventory())
		inventory.item_removed.connect(func(_id,_amount): refresh_inventory())
	visibility_changed.connect(refresh_inventory)
	refresh_inventory()

func _on_category_changed(category: int) -> void:
	current_category=category
	refresh_inventory()

func refresh_inventory() -> void:
	if inventory == null or slots.is_empty(): return
	_entries.clear()
	var ids: Array=inventory.items.keys()
	ids.sort_custom(func(a,b): return inventory.get_item_name(a)<inventory.get_item_name(b))
	for id in ids:
		var medicine: bool=id=="bandage"
		if current_category==Category.GU: continue
		if current_category==Category.MEDICINE and not medicine: continue
		if current_category==Category.FOOD and not inventory.is_food(id): continue
		if current_category==Category.MATERIAL and (medicine or inventory.is_food(id)): continue
		_entries.append({"id":id,"name":inventory.get_item_name(id),"count":inventory.get_item_count(id)})
	if current_category in [Category.ALL,Category.GU] and game != null:
		for i in game.player.captured.size():
			var gu: Dictionary=game.player.captured[i]
			_entries.append({"id":"capture:%d"%i,"name":GameData.GU[gu.id].name,"count":1,"gu":gu.id})
	if game!=null and current_category in [Category.ALL,Category.GU]:
		for gu in game.get_node("/root/Gus").owned_gus:
			if gu.location=="bag": _entries.append({"id":"owned:"+gu.id,"name":gu.name+"（外）","count":1,"gu":gu.template_id})
	if game!=null and current_category==Category.ALL:
		_entries.push_front({"id":"currency","name":"元石","count":game.player.crystals})
	for i in slots.size():
		var slot: Button=slots[i]
		slot.icon=null
		if i<_entries.size():
			var item: Dictionary=_entries[i]
			slot.text="%s\n× %d" % [String(item.name).left(4),int(item.count)]
			slot.tooltip_text=item.name
			if item.has("gu"):
				GuArt.decorate(slot,item.gu,36)
				slot.text=""
			slot.disabled=false
			slot.modulate=UIStyle.GOLD if item.id==selected_id else Color.WHITE
		else:
			slot.text="·"
			slot.disabled=true
			slot.modulate=Color(0.6,0.7,0.65,0.45)
	title_label.text="外部行囊 · %d 类携带物" % _entries.size()
	var gus:=get_node_or_null("/root/Gus")
	feed_target.clear()
	if gus:
		for gu in gus.owned_gus:
			feed_target.add_item("喂养 · "+gu.name)
			feed_target.set_item_metadata(feed_target.item_count-1,gu.id)
			if gus.active_gu==gu:
				feed_target.select(feed_target.item_count-1)
	if feed_target.item_count==0:
		feed_target.add_item("尚无已炼化蛊虫")
		feed_target.set_item_metadata(0,"")
	_update_detail()

func _select_feed_target(index: int) -> void:
	var gus := get_node_or_null("/root/Gus")
	if gus == null: return
	var id := String(feed_target.get_item_metadata(index))
	for i in gus.owned_gus.size():
		if gus.owned_gus[i].id == id:
			gus.set_active_gu(gus.owned_gus[i])
			if game: game.aperture_ui.selected_id = id
			return

func _select_index(index: int) -> void:
	if index>=_entries.size(): return
	selected_id=_entries[index].id
	refresh_inventory()

func _update_detail() -> void:
	portrait.texture=null
	portrait.visible=false
	detail_sell.visible=game!=null and game.world.in_interior and game.current_house_id=="shop" and Inventory.SELL_PRICES.has(selected_id)
	detail_sell.text="售出 1 份 · %d 元石" % int(Inventory.SELL_PRICES.get(selected_id,0))
	detail_sell.disabled=not inventory.has_item(selected_id) or not game.service_available("shop")
	if selected_id=="":
		detail_name.text="物品详情"
		detail_info.text="在左侧选择物品。\n\n绷带可直接处理身体页选中的部位。\n蛊食需匹配蛊虫的具体食性。已收入空窍的蛊不在此物品格中。\n\n[color=#93a99f]属性、伤势和背包共享同一份角色数据。[/color]"
		detail_use.disabled=true
		detail_drop.disabled=true
		feed_target.visible=false
		return
	if selected_id=="currency":
		detail_name.text="元石 · 随身钱袋"
		detail_info.text="持有 %d 块。用于交易，也可吸收其中的元气补充真元。元石是外物，不存放在普通空窍中。" % game.player.crystals
		detail_use.text="吸收一块元石"
		detail_use.disabled=false
		detail_drop.disabled=true
		feed_target.visible=false
		return
	if selected_id.begins_with("owned:"):
		var gu: GuVirtual=game.get_node("/root/Gus").get_gu_by_id(selected_id.trim_prefix("owned:"))
		if gu==null or gu.location!="bag":
			selected_id=""
			_update_detail()
			return
		detail_name.text=gu.name
		portrait.texture=GuArt.texture(gu.template_id)
		portrait.visible=true
		detail_info.text="已炼化 · 外部携带\n尚未收入空窍，也未寄居身体。\n收入后在 Q 空窍页管理；不会作为普通材料叠放。"
		detail_use.text="收入空窍"
		detail_use.disabled=gu.dead
		detail_drop.disabled=true
		feed_target.visible=false
		return
	var capture:=selected_id.begins_with("capture:")
	if capture:
		var index:=int(selected_id.get_slice(":",1))
		if game==null or index>=game.player.captured.size():
			selected_id=""
			_update_detail()
			return
		var gu: Dictionary=game.player.captured[index]
		detail_name.text=GameData.GU[gu.id].name
		portrait.texture=GuArt.texture(gu.id)
		portrait.visible=true
		detail_info.text="外部携带 · 未炼化\n\n%d 转 · 意志磨合 %.1f%%\n用真元逐步磨去蛊虫意志。炼化后才能收入空窍；不占普通物品堆叠。" % [gu.rank,float(gu.get("progress",0))]
		detail_use.text="前往炼化"
		detail_use.disabled=false
		detail_drop.disabled=true
		feed_target.visible=false
		return
	detail_name.text=inventory.get_item_name(selected_id)
	detail_info.text=inventory.get_item_desc(selected_id)+"\n\n持有数量：%d" % inventory.get_item_count(selected_id)
	var food:=inventory.is_food(selected_id)
	var medicine: bool=selected_id=="bandage"
	if food: detail_info.text+="\n\n喂养下方选中的蛊虫，成功后消耗 1 份。"
	if selected_id=="bandage" and game!=null:
		detail_info.text+="\n\n当前治疗目标：%s\n止住该处出血，恢复 12 点耐久。普通医者不能恢复毁损部位。" % game.player.body.parts[game.body_ui.selected_part].name
	feed_target.visible=food
	detail_use.text="喂养选定蛊虫" if food else ("使用药物" if medicine else "材料无需直接使用")
	detail_use.disabled=(not food and not medicine) or not inventory.has_item(selected_id)
	detail_drop.disabled=not inventory.has_item(selected_id)

func _use_selected() -> void:
	_use_item(selected_id)

func _use_item(item_id: String) -> void:
	if item_id=="currency":
		game.absorb_primeval_stone()
		_set_status(game.last_action_message)
		refresh_inventory()
		return
	if item_id.begins_with("owned:"):
		game.move_gu(item_id.trim_prefix("owned:"),"aperture")
		selected_id=""
		refresh_inventory()
		return
	if item_id.begins_with("capture:"):
		game.journal.close()
		game.open_refine()
		return
	if game!=null and item_id=="bandage":
		game.treat_part(game.body_ui.selected_part)
		_set_status(game.last_action_message)
	elif inventory.is_food(item_id):
		var target: String=String(feed_target.get_item_metadata(feed_target.selected)) if feed_target.selected>=0 else ""
		if target=="":
			_set_status("尚无已炼化蛊虫，物品未消耗。")
		elif inventory.use_item(item_id,target):
			_set_status("喂养成功，饱腹状态已同步。")
			if game: game.save_game()
		else:
			_set_status("喂养未成功，食性不匹配、已饱腹或已死亡；物品未消耗。")
	refresh_inventory()

func _drop_selected() -> void:
	if inventory.remove_item(selected_id,1):
		_set_status("已丢弃 1 份。")
		if game: game.save_game()
	refresh_inventory()

func _set_status(message: String) -> void:
	status_label.text=message
