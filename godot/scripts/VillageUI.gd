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
var panel: PanelContainer
var gu_buttons: Dictionary = {}
var repair_button: Button
var object_buttons: Dictionary = {}
var shop_filter: OptionButton
var supply_buttons: Dictionary = {}
var caravan_buttons: Dictionary = {}
var direction_buttons: Dictionary = {}
var clinic_button: Button

func _ready()->void:
	UIStyle.fill(self)
	var shade:=ColorRect.new()
	shade.color=Color(0.02,0.05,0.05,0.72)
	UIStyle.fill(shade)
	add_child(shade)
	var center:=CenterContainer.new()
	UIStyle.fill(center)
	add_child(center)
	panel=PanelContainer.new()
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
	shop_filter=OptionButton.new()
	for label in ["全部商品与服务","蛊虫","供养与补给","其他服务"]: shop_filter.add_item(label)
	shop_filter.item_selected.connect(func(_index:int): _filter_shop())
	layout.add_child(shop_filter)
	shop_filter.hide()
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
	panel.custom_minimum_size.y=minf(530,get_viewport_rect().size.y-20)
	action_scroll.custom_minimum_size.y=180 if kind=="conversation" and get_viewport_rect().size.y<620 else 270
	gu_buttons.clear()
	supply_buttons.clear()
	direction_buttons.clear()
	clinic_button=null
	shop_filter.hide()
	shop_filter.select(0)
	order_buttons.clear()
	object_buttons.clear()
	repair_button=null
	camp_claim=null
	camp_treat=null
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	action_scroll.scroll_vertical=0
	message.text=""
	visible=true
	game.paused=true
	if game.residents.has(kind):
		var resident:Npc=game.residents[kind]
		actions.add_child(UIStyle.button("与%s聊聊" % resident.npc_name,func(): show_conversation(resident)))

func show_service(kind:String)->void:
	var building:=SettlementData.building(kind)
	if not building.is_empty():
		_show_settlement(building)
		return
	_prepare(kind)
	match kind:
		"clinic":
			title.text="古月药堂 · 普通医者"
			description.text="目前提供普通伤口包扎。缺失的肢体或眼睛，需要具备相应效用的蛊术；这里不会付钱直接再生。"
			actions.add_child(UIStyle.button("包扎出血伤口 · 2 元石",func():
				game.clinic_heal()
				message.text=game.last_action_message
			))
			actions.add_child(_item_button("绷带 ×1 · 1 元石","bandage",_buy.bind("bandage",1)))
		"shop":
			shop_filter.show()
			title.text="古月商铺 · 补给"
			description.text="蛊虫与专属供养。购得的蛊放进行囊，需 R 炼化、Q 绑定。库存与三寨上架属于游戏设计；原创蛊有明确标记。"
			actions.add_child(_item_button("月兰花瓣 ×10 · 1 元石","moon_petals",func():
				if game.buy_supply("moon_petals",1):
					game.get_node("/root/Inv").add_item("moon_petals",9)
					game.save_game()
				message.text=game.last_action_message
			))
			actions.add_child(_item_button("青竹酒 ×1坛 · 2 元石","bamboo_wine",_buy.bind("bamboo_wine",2)))
			actions.add_child(_item_button("玉石 ×2两 · 4 元石","jade",_buy.bind("jade",4)))
			actions.add_child(_item_button("绷带 ×1 · 1 元石","bandage",_buy.bind("bandage",1)))
			actions.add_child(_item_button("整猪肉 · 一头成年猪份 · 12 元石","pork_ration",_buy.bind("pork_ration",12)))
			actions.add_child(UIStyle.button("小光蛊专用供养 · 一日份 · 1 元石",_buy.bind("light_care",1)))
			for id in ["moon_glow","moon_raiment"]:
				actions.add_child(UIStyle.button(GameData.GU[id].name+"专用供养 · 一日份 · 2 元石",_buy.bind(GameData.GU[id].preferred_food,2)))
			for id in GameData.EXPANSION_GU:
				var food:String=GameData.GU[id].preferred_food
				var supply:=UIStyle.button("%s专用供养 · 一日份 · 1 元石" % GameData.GU[id].name,_buy.bind(food,1))
				supply.tooltip_text="具体食材尚待考据；每只蛊独立使用自己的供养，不能通喂。"
				supply_buttons[food]=supply
				actions.add_child(supply)
			for button in actions.get_children(): button.set_meta("shop_group",2)
			_add_utility_food()
			for id in GameData.shop_gu_ids("shop"):
				var remaining:int=game.gu_shop_remaining(id)
				var sold:bool=remaining<=0
				var button:=UIStyle.button("%s · %d 元石 · %s" % [GuProgression.title(id),GameData.GU_SHOP[id],"售罄" if sold else "余%d只"%remaining],_buy_gu.bind(id))
				button.tooltip_text=GuProgression.power(id)+"\n"+GuProgression.routes(id)
				GuArt.decorate(button,id,36)
				button.disabled=sold
				gu_buttons[id]=button
				button.set_meta("shop_group",1)
				actions.add_child(button)
			actions.add_child(UIStyle.button("山寨委托 · 材料与踏查 →",show_commissions))
			actions.add_child(UIStyle.button("出售猎获与材料 →",func():
				close()
				game.open_journal("inventory")
			))
		"ancestral":
			title.text="古月宗族祠堂"
			description.text="宗族祭祀与家老议事的场所。古月一族以地下灵泉为根基；开窍大典在地下溶洞举行。"
			if not game.player.aperture.is_open(): actions.add_child(UIStyle.button("希望蛊开窍 · 标记地下溶洞",func(): game.guide_awakening()))
		_:
			title.text="古月学堂 · 地理与修行"
			if not game.player.aperture.is_open(): actions.add_child(UIStyle.button("希望蛊开窍 · 标记地下溶洞",func(): game.guide_awakening()))
			description.text="青茅山位于南疆，山上有古月、白家、熊家三寨。黑白两天轮转，五域之间有界壁。"
			actions.add_child(UIStyle.button("山寨委托 · 材料与踏查 →",show_commissions))
			actions.add_child(UIStyle.button("查看地理志",func():
				close()
				game.open_journal("map")
			))

func _show_settlement(building: Dictionary) -> void:
	_prepare(building.id)
	title.text=building.name
	if building.service!="spring" and not game.service_available(building.id):
		description.text="住民已死亡或与你敌对，无法提供服务。"
		return
	match String(building.service):
		"hall":
			description.text=("白家以溪流蛊为家族标志。" if building.clan=="bai" else "熊家以熊力蛊为家族标志，山寨位于青茅山较低的山脚。")+"寨中可补给、包扎、拜访住户和查阅山志。"
		"shop":
			shop_filter.show()
			description.text="本寨蛊虫、专属蛊食与行路补给。购蛊后需 R 炼化、Q 绑定；溪流蛊效用为改编，其余新蛊标为原创。三寨均备有本批全部口粮。"
			_add_gu_stock(building.id)
		"clinic":
			description.text="普通医者可包扎出血伤口；毁损部位需要有相应作用的蛊术，普通包扎不会再生。"
			clinic_button=UIStyle.button("包扎出血伤口 · 2 元石",func():
				game.clinic_heal()
				message.text=game.last_action_message
			)
			actions.add_child(clinic_button)
		"inn":
			description.text="行脚客舍可歇脚、包扎和整理行囊。床榻休息与打坐按原有时间推进，不会瞬间补满气血或真元。"
			actions.add_child(UIStyle.button("就地打坐 · J 收功",func():
				close()
				game.toggle_meditation()
			))
			actions.add_child(UIStyle.button("查看伤势 / 使用绷带",_open_page.bind("body")))
		"archive":
			description.text="学堂记述空窍、用养炼和青茅山地理。温养需要调动真元；猎杀不会直接增长修为。"
			actions.add_child(UIStyle.button("查看空窍与修行",_open_page.bind("aperture")))
		"home":
			description.text=("住户谈起沿溪而建的街巷，商铺在会客楼东侧，药堂在西侧。" if building.clan=="bai" else "住户谈起山脚行旅与竹木生计，商铺在会客楼西侧，药堂在东侧。")+"可到客舍歇脚，沿街往北查看本寨元泉。"
		"workshop":
			description.text="工坊买卖木料与碎石。携带材料靠近受损物件，按 F 检查并修缮；修好房屋不会让已死亡的住民复生。"
		"spring":
			description.text="元泉是家族立寨根基，出产元石。这是受家族管理的资源，观察不会领取元石或瞬间恢复真元。"
	var stock:=SettlementData.stock(building.id)
	for id in stock:
		var button:=_item_button("%s ×1 · %d 元石"%[game.get_node("/root/Inv").get_item_name(id),stock[id]],id,_buy.bind(id,int(stock[id])))
		supply_buttons[id]=button
		button.set_meta("shop_group",2)
		actions.add_child(button)
	if SettlementData.can_sell(building.id):
		actions.add_child(UIStyle.button("出售木石材料 →" if building.service=="workshop" else "出售猎获与材料 →",_open_page.bind("inventory")))
	actions.add_child(UIStyle.button("整理随身行囊",_open_page.bind("inventory")))
	actions.add_child(UIStyle.button("寨内指路 →",show_directions.bind(building.clan,building.name)))
	if building.service=="hall": _add_directions(building.clan)

func show_directions(clan: String, speaker: String) -> void:
	_prepare("directions")
	title.text=speaker+" · 指路"
	description.text="选择要去的地方，在地图上留下标记。沿街走到门前按 E 进入，关图后可跟随方向提示。"
	_add_directions(clan)

func _add_directions(clan: String) -> void:
	for house in SettlementData.HALLS+SettlementData.HOUSES:
		if house.clan!=clan: continue
		var button:=UIStyle.button("标记 · "+house.name,func():
			game.set_waypoint(house.pos+Vector2(0,40),house.name)
			message.text="已标记「"+house.name+"」，沿街前往。"
		)
		direction_buttons[house.id]=button
		actions.add_child(button)

func _buy_gu(id: String) -> void:
	game.buy_gu(id)
	message.text=game.last_action_message
	var remaining:int=game.gu_shop_remaining(id)
	gu_buttons[id].disabled=remaining<=0
	gu_buttons[id].text="%s · %d 元石 · %s" % [GuProgression.title(id),GameData.GU_SHOP[id],"售罄" if remaining<=0 else "余%d只"%remaining]

func _add_gu_stock(shop: String) -> void:
	for id in GameData.shop_gu_ids(shop):
		var remaining:int=game.gu_shop_remaining(id)
		var button:=UIStyle.button("%s · %d 元石 · %s" % [GuProgression.title(id),GameData.GU_SHOP[id],"售罄" if remaining<=0 else "余%d只"%remaining],_buy_gu.bind(id))
		button.tooltip_text=GameData.GU[id].get("origin","")+"\n"+GameData.activation_hint(id)
		GuArt.decorate(button,id,36)
		button.disabled=remaining<=0
		button.set_meta("shop_group",1)
		gu_buttons[id]=button
		actions.add_child(button)

func _add_utility_food() -> void:
	for food in GameData.utility_food_stock():
		var button:=UIStyle.button(FoodSystem.GRAINS[food].name+" · 1 元石",_buy.bind(food,1))
		button.tooltip_text=game.get_node("/root/Food").get_food_description(food)
		button.set_meta("shop_group",2)
		supply_buttons[food]=button
		actions.add_child(button)

func show_conversation(person: Npc, response: String = "") -> void:
	var blocker:String=game.person_talk_blocker(person)
	if blocker!="":
		message.text=blocker
		return
	_prepare("conversation")
	person.facing=(game.player.position-person.position).angle()
	if person.social.meet(person): game.save_game()
	title.text="%s · %s · 好感 %+d" % [person.npc_name,person.social.label(person),person.social.affinity]
	var profile:Dictionary=person.inspection_data()
	description.text="%s · %s\n\n「%s」" % [profile.role,profile.activity,NpcConversation.greeting(game,person) if response=="" else response]
	for topic in NpcConversation.TOPICS:
		var button:=UIStyle.button(NpcConversation.TOPICS[topic],_conversation_reply.bind(person,topic))
		button.name="Talk_"+topic
		actions.add_child(button)
	if person.hp<person.max_hp:
		actions.add_child(UIStyle.button("帮忙包扎 · 绷带 ×1 · 恢复 18 气血",_conversation_reply.bind(person,"care")))
	var service_button:Button
	if person is WorldPerson:
		service_button=UIStyle.button("看看随身物品与行程",func(): show_traveler(person))
	elif person.outdoors:
		service_button=UIStyle.button("询问寨内建筑位置",func(): show_directions(person.settlement_id,person.npc_name))
	elif person.resident_id!="aqing":
		service_button=UIStyle.button("办理事务 · 商铺 / 药堂 / 服务",func(): show_service(person.resident_id))
	if service_button!=null:
		service_button.name="Talk_service"
		actions.add_child(service_button)

func _conversation_reply(person: Npc, topic: String) -> void:
	var response:=NpcConversation.reply(game,person,topic)
	show_conversation(person,response)

func show_traveler(person: WorldPerson) -> void:
	_prepare("traveler")
	caravan_buttons.clear()
	title.text=person.npc_name+" · "+PopulationSystem.ROLE_NAMES[person.role]
	description.text=game.population.description(person)
	actions.add_child(UIStyle.button("坐下聊一聊",func(): show_conversation(person)))
	actions.add_child(UIStyle.button("查看随身物品 · 买卖",func():
		close()
		game.inspect_person(person)
		game.npc_inspect_ui.select_tab("items")
	))
	if person.role=="merchant":
		for item in PopulationSystem.GOODS:
			var goods:Dictionary=PopulationSystem.GOODS[item]
			var amount:int=game.population.stock.get(item,0)
			var button:=_item_button("%s ×1 · %d 元石 · 余 %d"%[goods.name,goods.price,amount],item,_caravan_buy.bind(person,item))
			button.disabled=amount<=0 or not game.population.can_trade(person)
			caravan_buttons[item]=button
			actions.add_child(button)
	if not person.route_names.is_empty():
		var target:Vector2=person.route[person.route_index]
		var destination:String=person.route_names[person.route_index]
		actions.add_child(UIStyle.button("标记下一站 · "+destination,func():
			game.set_waypoint(target,destination)
			message.text="已在地图标记目的地，需自行沿山路前往。"
		))

func _caravan_buy(person: WorldPerson, item: String) -> void:
	game.population.buy(person,item)
	var result:String=game.last_action_message
	show_traveler(person)
	message.text=result

func _filter_shop() -> void:
	if SettlementData.service(mode)!="shop": return
	for action in actions.get_children():
		action.visible=shop_filter.selected==0 or int(action.get_meta("shop_group",3))==shop_filter.selected
	action_scroll.scroll_vertical=0

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
	ItemArt.decorate(camp_treat,"bandage",28)
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

func show_block(block: Dictionary) -> void:
	_prepare("block")
	title.text="方块 · 独立耐久"
	var amount:float=game.player.melee_attack()/float(block.hardness)
	if amount<float(block.hardness): amount=0
	description.text="%s · 格 (%d, %d) · 高度 %d\n%s\n血量 %.1f / %.0f · 硬度 %.0f\n当前普攻每次伤害 %.1f"%[block.name,block.cell.x,block.cell.y,block.height,TerrainLayers.NAMES[block.layer],block.hp,block.max_hp,block.hardness,amount]
	actions.add_child(UIStyle.meter(block.hp,block.max_hp,UIStyle.JADE))
	var note:=UIStyle.label("朝方块按住左键，或瞄准后催动攻击蛊开凿。每一格、每一高度分别承受伤害；山岩逐层剥落，地下岩壁击碎后可通行。山坡可直接走上去，上坡时会减速。",15,UIStyle.INK)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	actions.add_child(note)

func show_destruction(selected: String = "") -> void:
	_prepare("destruction")
	title.text="地物 · 检查与修缮"
	var destruct:DestructionSystem=game.world.destruction
	var nearby:=destruct.nearby(game.player.position,game.current_house_id if game.world.in_interior else "")
	if nearby.is_empty():
		description.text="附近没有可检查的物件。靠近树木、岩石、建筑或室内陈设，再按 F。"
		return
	if not destruct.within_reach(selected,game.player.position,game.current_house_id if game.world.in_interior else ""):
		selected=nearby[0].id
	var obj:Dictionary=destruct.objects[selected]
	var physical:=destruct.damage_amount(selected,game.player.melee_attack(),game.destruction_power())
	var supported:bool=game.active_light_gu()!=null
	var moon:=destruct.damage_amount(selected,float(GameData.GU.moon_blade.skill.dmg)*(2.0 if supported else 1.0),game.destruction_power())
	description.text="%s · %s\n耐久 %.1f / %.0f · 硬度 %.1f\n每次命中：普攻 %.1f / %s %.1f"%[destruct.object_name(selected),destruct.state_text(selected),obj.hp,obj.max_hp,obj.hardness,physical,"辅光月刃" if supported else "月刃",moon]
	actions.add_child(UIStyle.meter(float(obj.hp),float(obj.max_hp),UIStyle.RED if float(obj.hp)<float(obj.max_hp)*0.3 else UIStyle.JADE))
	var loot:=destruct.salvage_yield(selected)
	var salvage_note:=UIStyle.label("首次拆解："+game.materials_text(loot) if not loot.is_empty() else "回收材料已取尽，修好再拆也不会重复产出。",14,UIStyle.DIM)
	salvage_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	actions.add_child(salvage_note)
	if physical<=0:
		actions.add_child(UIStyle.label("普攻不足以破坏此物；升小阶不会增强肉身攻击。",14,UIStyle.GOLD))
	var cost:=destruct.repair_cost(selected)
	if destruct.repairable(selected):
		var inv:Inventory=game.get_node("/root/Inv")
		actions.add_child(UIStyle.label("行囊：木料 %d / 碎石 %d"%[inv.get_item_count("timber"),inv.get_item_count("rubble")],14,UIStyle.DIM))
		repair_button=UIStyle.button(("重建" if destruct.broken(selected) else "修缮")+" · "+game.materials_text(cost) if not cost.is_empty() else "完好 · 无需修缮",func():
			game.repair_world_object(selected)
			var result:String=game.last_action_message
			show_destruction(selected)
			message.text=result
		)
		var reason:String=game.repair_unavailable_reason(selected)
		repair_button.disabled=reason!=""
		repair_button.tooltip_text=reason
		actions.add_child(repair_button)
		if not cost.is_empty() and reason!="":
			var note:=UIStyle.label(reason,14,UIStyle.GOLD)
			note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			actions.add_child(note)
	else:
		actions.add_child(UIStyle.label("自然地物暂不支持修复或再生。",14,UIStyle.DIM))
	if obj.kind=="house":
		var note:=UIStyle.label("重建恢复入口；屋内陈设单独修复，住民的死亡与敌对状态保留。",14,UIStyle.DIM)
		note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		actions.add_child(note)
	actions.add_child(UIStyle.label("附近物件 · 选择查看 · F / Esc 返回",15,UIStyle.GOLD))
	for entry in nearby:
		var button:=UIStyle.button("%s%s · %s · %.1f 步"%["● " if entry.id==selected else "",destruct.object_name(entry.id),destruct.state_text(entry.id),float(entry.distance)/GameData.TILE],show_destruction.bind(entry.id))
		button.disabled=entry.id==selected
		object_buttons[entry.id]=button
		actions.add_child(button)

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
	game.set_waypoint(Vector2(site.pos)*World.TILE+Vector2(16,16),site.name)
	message.text="已标记「"+site.name+"」，离开菜单后可跟随方向前往。"

func _item_button(text: String, id: String, callback: Callable) -> Button:
	var button:=UIStyle.button(text,callback)
	button.custom_minimum_size.y=48
	ItemArt.decorate(button,id)
	return button

func _buy(id:String,cost:int)->void:
	game.buy_supply(id,cost)
	message.text=game.last_action_message

func close()->void:
	visible=false
	game.paused=false
