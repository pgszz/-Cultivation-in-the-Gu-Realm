class_name CharacterUI
extends Control

var player: Player
var game: Node
var selected_slot_index := 0
var overview: RichTextLabel
var attributes: RichTextLabel
var portrait: CharacterPreview
var effects: RichTextLabel
var detail_scroll: ScrollContainer
var status_heading: Label
var refresh_time:=0.0
var status_scroll_pending:=false

func _ready() -> void:
	var cols:=HBoxContainer.new()
	UIStyle.fill(cols)
	cols.add_theme_constant_override("separation",12)
	add_child(cols)
	var left:=UIStyle.card(cols,230)
	left.get_parent().size_flags_horizontal=SIZE_FILL
	var identity:=HBoxContainer.new()
	left.add_child(identity)
	portrait=CharacterPreview.new()
	portrait.custom_minimum_size=Vector2(70,90)
	identity.add_child(portrait)
	identity.add_child(UIStyle.label("人物总览\n身份 · 身体 · 修行",17,UIStyle.GOLD))
	overview=UIStyle.rich(15)
	left.add_child(overview)
	left.add_child(UIStyle.button("内视空窍与元海 · Q →",func(): game.open_journal("aperture")))
	left.add_child(UIStyle.button("查看随身物品 · I →",func(): game.open_journal("inventory")))
	left.add_child(UIStyle.button("检查身体伤势 · B →",func(): game.open_journal("body")))
	var right:=UIStyle.card(cols,340)
	var heading:=HBoxContainer.new()
	right.add_child(heading)
	var title:=UIStyle.label("实际属性",21,UIStyle.GOLD)
	title.size_flags_horizontal=SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(UIStyle.button("查看增益 / 减益 ↓",show_status))
	right.add_child(UIStyle.label("基础 → 当前 · 括号为该来源的实际增减",12,UIStyle.DIM))
	detail_scroll=ScrollContainer.new()
	detail_scroll.size_flags_vertical=SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(detail_scroll)
	var detail:=VBoxContainer.new()
	detail.size_flags_horizontal=SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation",14)
	detail_scroll.add_child(detail)
	attributes=UIStyle.rich(15)
	attributes.fit_content=true
	attributes.scroll_active=false
	attributes.size_flags_vertical=SIZE_FILL
	detail.add_child(attributes)
	status_heading=UIStyle.label("状态明细",20,UIStyle.GOLD)
	detail.add_child(status_heading)
	effects=UIStyle.rich(15)
	effects.fit_content=true
	effects.scroll_active=false
	effects.size_flags_vertical=SIZE_FILL
	detail.add_child(effects)
	visibility_changed.connect(func():
		if visible:
			detail_scroll.scroll_vertical=0
			status_scroll_pending=false
		refresh())
	refresh()

func refresh() -> void:
	if overview==null or player==null: return
	# Share the actual world texture: panel refresh never re-imports an image.
	portrait.appearance.texture=player.appearance.texture
	portrait.appearance.data=player.appearance.data
	var b:=player.body
	overview.text="[color=#d8bc7c]%s[/color]\n%s · %s资质\n空窍容量 %.0f%% · 温养 %.1f%%\n\n气血 %.1f / %.0f\n真元 %s\n体力 %.1f / 100\n身体血量 %.1f / 100\n疼痛 %.1f · 意识 %.1f\n\n随身元石 %d\n外部未炼化蛊 %d" % [game.character_name.replace("[","［").replace("]","］"),player.aperture.realm(),player.aperture.aptitude(),player.max_yuan,player.xiuwei,player.hp,player.max_hp,player.aperture.amount_text(),player.gu_effects.stamina,b.blood,b.pain,b.consciousness,player.crystals,player.captured.size()]
	var data:=PlayerStatus.snapshot(game)
	if not player.aperture.is_open():
		overview.text="[color=#d8bc7c]%s[/color]\n凡人 · 资质未觉醒\n尚无空窍、元海和真元\n希望蛊开窍后方可修行\n\n气血 %.1f / %.0f\n体力 %.1f / 100\n身体血量 %.1f / 100\n疼痛 %.1f · 意识 %.1f\n\n随身元石 %d\n外部未炼化蛊 %d"%[game.character_name.replace("[","［").replace("]","］"),player.hp,player.max_hp,player.gu_effects.stamina,b.blood,b.pain,b.consciousness,player.crystals,player.captured.size()]
	var text:=PlayerStatus.attributes_text(data)
	text+="\n\n[color=#93a99f]移动速度按当前位置与朝向计算，包含环境倍率；各乘算来源依次结算。精准度显示最终值，最低 15%%。[/color]\n疾步：%s · 催蛊：%s"%["可用" if b.can_dash() and not player.dead else "伤势或意识受限","可用" if b.can_cast() and not player.dead else "意识或生命状态受限"]
	var training:=player.boar_cultivation
	text+="\n\n体力恢复 +8 / 秒 · 蛮力负担 %.1f / 100（超过 65 继续用力可拉伤）\n真元自然恢复 +%.3f / 秒\n[color=#d8bc7c]豕蛊养力[/color] 永久进度 %.0f%% · 攻击 +%.1f\n本日养力 %.1f / 15 秒 · %s"%[player.gu_effects.strain,player.aperture.recovery_rate(),training.progress*100,training.attack_bonus(),training.daily_used,"正在养力" if training.active_id!="" else "已收功"]
	text+="\n\n[color=#93a99f]升转改变真元品质，不自动增加肉身攻击、防御或修复伤势。攻击数值为基础威力；护体减伤和护盾容量见下方状态。耗元按当前阶普通真元折算，精炼真元优先以双倍效力抵扣。菜单内时间暂停。[/color]"
	if not player.aperture.is_open(): text=text.replace("催蛊：可用","催蛊：尚未开窍")
	if attributes.text!=text: attributes.text=text
	var status_text:=PlayerStatus.effects_text(data)
	if effects.text!=status_text: effects.text=status_text

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	if status_scroll_pending and status_heading.position.y>0 and detail_scroll.get_v_scroll_bar().max_value>detail_scroll.size.y:
		detail_scroll.scroll_vertical=int(status_heading.position.y)
		status_scroll_pending=false
	refresh_time+=delta
	if refresh_time>=0.2:
		refresh_time=0
		refresh()

func show_status() -> void:
	# Rich text reflows after the page becomes visible. Apply on a laid-out frame.
	status_scroll_pending=true

func select_gu(index: int) -> void:
	selected_slot_index=index
	var gu: GuVirtual=game.equipped_gu(index)
	if gu: game.aperture_ui.select_gu(gu.id)

func update_gu_slots() -> void:
	refresh()
