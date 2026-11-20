class_name AwakeningUI
extends Control

const DURATION := 12.0
const HOPE_TEXT := "希望蛊 · 开窍消耗蛊\n微弱白光从花海升起，汇入体内，开辟空窍。希望蛊随后消散成窍壁光膜，空窍中凝成青铜元海。\n\n转数、食性与稀有程度尚未核实；本版按仪式蛊处理，不进入快捷位，也不成为本命蛊。"
var game: Node
var view: AwakeningView
var title: Label
var description: Label
var progress: ProgressBar
var begin_button: Button
var close_button: Button
var panel: PanelContainer
var elapsed := 0.0
var playing := false
var completed := false
var committed_here := false

func _ready() -> void:
	UIStyle.fill(self)
	mouse_filter=MOUSE_FILTER_STOP
	var shade:=ColorRect.new()
	shade.color=Color(0.015,0.035,0.035,0.96)
	UIStyle.fill(shade)
	add_child(shade)
	panel=PanelContainer.new()
	UIStyle.fill(panel)
	panel.add_theme_stylebox_override("panel",UIStyle.box(Color("102321"),Color("72816a"),12))
	add_child(panel)
	resized.connect(_layout)
	_layout()
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",12)
	panel.add_child(content)
	var header:=HBoxContainer.new()
	content.add_child(header)
	var icon:=GuArt.portrait(56)
	icon.texture=GuArt.texture("hope_gu")
	header.add_child(icon)
	title=UIStyle.label("希望蛊 · 开窍",24,UIStyle.GOLD)
	title.size_flags_horizontal=SIZE_EXPAND_FILL
	title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)
	header.add_child(UIStyle.label("地下溶洞 · 月兰花海",14,UIStyle.DIM))
	view=AwakeningView.new()
	view.game=game
	view.custom_minimum_size.y=200
	view.size_flags_vertical=SIZE_EXPAND_FILL
	content.add_child(view)
	progress=ProgressBar.new()
	progress.max_value=DURATION
	progress.custom_minimum_size.y=6
	progress.show_percentage=false
	content.add_child(progress)
	description=UIStyle.label("",16)
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.y=64
	content.add_child(description)
	var buttons:=HBoxContainer.new()
	content.add_child(buttons)
	begin_button=UIStyle.button("引动希望蛊 · 开始开窍",begin)
	begin_button.size_flags_horizontal=SIZE_EXPAND_FILL
	buttons.add_child(begin_button)
	close_button=UIStyle.button("暂不引动 · 返回",close)
	buttons.add_child(close_button)
	hide()

func _layout() -> void:
	if panel==null: return
	panel.offset_left=maxf(18,(size.x-960)/2)
	panel.offset_right=-panel.offset_left
	panel.offset_top=maxf(18,(size.y-560)/2)
	panel.offset_bottom=-panel.offset_top

func unavailable() -> String:
	if not game.running or game.player.dead: return "此角色不能进行开窍。"
	if game.player.aperture.is_open(): return "空窍已经开辟，不能重复觉醒或重抽资质。"
	if not game.world.in_interior or game.current_house_id!="spring_cave" or game.world.interior.interaction_at(game.player.position)!="spring_cave":
		return "请先走近地下溶洞的月兰花海与灵泉，再按 E。"
	if not game.can_meditate(): return "请先处理出血、中毒或意识异常，并远离威胁。"
	return ""

func open() -> void:
	playing=false
	committed_here=false
	completed=game.player.aperture.is_open()
	elapsed=DURATION if completed else 0.0
	game.stop_meditation("")
	game._world_attack_held=false
	game.paused=true
	show()
	view.sync()
	refresh()

func begin() -> void:
	if playing or completed: return
	var reason:=unavailable()
	if not reason.is_empty():
		description.text=reason
		return
	playing=true
	elapsed=0
	refresh()

func advance(delta: float) -> void:
	if not playing or not visible: return
	var reason:=unavailable()
	if not reason.is_empty():
		playing=false
		elapsed=0
		refresh()
		description.text=reason+" 仪式已停止。"
		return
	elapsed=minf(DURATION,elapsed+maxf(0,delta))
	if elapsed>=DURATION:
		playing=false
		completed=_commit()
		if not completed:
			elapsed=0
			refresh()
			description.text="保存未成功，开窍尚未结算。请检查存档目录后重试；资质结果不会重抽。"
			return
	refresh()

func _commit() -> bool:
	if elapsed<DURATION or not unavailable().is_empty(): return false
	var a:ApertureState=game.player.aperture
	var old:=a.save_data()
	var captured:Array=game.player.captured.duplicate(true)
	var discovered:Array=game.player.discovered.duplicate()
	if not a.awaken(): return false
	# 开窍后的入门蛊为游戏补给安排；希望蛊已化为光膜，不生成可养用实例。
	game.player.captured.append({"id":"moon_blade","rank":1,"quality":"normal","progress":0.0})
	for id in ["hope_gu","moon_blade"]:
		if not game.player.discovered.has(id): game.player.discovered.append(id)
	if not game.save_game():
		a.load_data(old)
		game.player.captured=captured
		game.player.discovered.assign(discovered)
		return false
	game._action_message("开窍成功：%s资质，元海%.0f%%。已获一只未炼化月光蛊，按 R 开始炼化。"%[a.aptitude(),a.capacity])
	committed_here=true
	return true

func refresh() -> void:
	view.elapsed=elapsed
	view.completed=completed
	view.queue_redraw()
	progress.value=elapsed
	begin_button.disabled=playing or completed or not unavailable().is_empty()
	begin_button.text="开窍已成" if completed else "希望汇聚中…" if playing else "引动希望蛊 · 开始开窍"
	close_button.text="进入蛊师之路" if completed else "中止仪式 · Esc" if playing else "暂不引动 · 返回"
	if completed:
		title.text=("开窍成功 · " if committed_here else "空窍已开 · ")+game.player.aperture.aptitude()+"资质"
		description.text="当前境界：%s，元海容量占空窍 %.0f%%。\n"%[game.player.aperture.realm(),game.player.aperture.capacity]
		description.text+="希望蛊已消散为窍壁光膜。月光蛊放入外部行囊，需 R 炼化后再收入空窍。" if committed_here else "希望蛊仅在开窍时消耗，已开辟的空窍不能重复觉醒。按 Q 管理空窍与蛊虫。"
	elif not playing:
		title.text="希望蛊 · 未知的资质"
		description.text="你尚是凡人，空窍与真元都未形成。引动花海中的希望蛊，完成开窍后方能修炼。\n资质于角色创建时固定，仪式中止或读档不会改变结果。" if unavailable().is_empty() else unavailable()
	else:
		title.text="希望初现" if elapsed<3 else "光流入体" if elapsed<6 else "开辟空窍" if elapsed<8 else "凝成元海"
		description.text="微弱白光从花丛升起，回应心中的希望。" if elapsed<3 else "点点希望汇入体内，凝聚成光。" if elapsed<6 else "希望蛊消散，凝为一层白色光膜，撑起空窍。" if elapsed<8 else "光膜内，青铜真元渐渐凝成元海，资质即将显现。"
		description.text+="\n仪式中世界暂停；Esc 可中止，未完成时不会改变角色状态。"

func _process(delta: float) -> void:
	advance(delta)

func close() -> void:
	if not visible: return
	playing=false
	if not completed: elapsed=0
	hide()
	game.paused=false
	game._world_attack_held=false
	game.aperture_ui.refresh()
	if not completed: game._action_message("尚未开窍，可再次到花海引动希望蛊。")
