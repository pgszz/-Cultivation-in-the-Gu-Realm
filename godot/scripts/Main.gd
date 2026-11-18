extends Node2D

## 青茅山 · Godot 4.3 可玩版主控。
## 初版包含：世界、玩家、敌人、弹道、元素反应、捕获、炼化、转数、存档。

const SAVE_PATH := "user://canon_save.json"
const TILE := GameData.TILE

var world: World
var player: Player
var fx: Fx
var top: TopLayer
var hud: HUD
var camera: Camera2D
var night_rect: ColorRect
var enemies_root: Node2D

var enemies: Array[Enemy] = []
var projectiles: Array = []
var pending_melee: Array = []

var running := false
var paused := false
var started := false
var quest_done := false
var captures := 0
var refined := 0
var kills := 0
var logs: Array = []

var spawn_timer := 0.0
var day_time := 40.0
var save_t := 0.0
var shake := 0.0

var start_layer: CanvasLayer
var refine_layer: CanvasLayer
var death_layer: CanvasLayer
var pause_layer: CanvasLayer
var refine_list: VBoxContainer
var refine_progress_bar: ProgressBar
var refine_progress_label: Label
var refining := false
var refine_target := -1
var refine_elapsed := 0.0
var refine_duration := 0.0
var start_btn: Button

var ui_layer: CanvasLayer
var character_ui: CharacterUI
var inventory_ui: InventoryUI
var settings_ui: SettingsUI
var minimap_ui: MiniMapUI
var compendium_ui: CompendiumUI
var body_ui: BodyUI

var npc: Npc
var boss: Enemy
var target_hint: Enemy
var last_zone := ""
var zone_banner_time := 0.0
var zone_banner_text := ""
var poi_cd := {}
var visited_sites := {}
var claimed_camps := {}
var commissions := CommissionLedger.new()
var low_quality := false
var fps_smooth := 60.0
var play_time := 0.0
var low_fps_timer := 0.0
var fps_cap_30 := false
var dialogue_layer: CanvasLayer
var dialogue_label: Label
var dialogue_btn: Button
var npc_quest_state := 0

var journal: JournalUI
var village_ui: VillageUI
var fog: FogOfWar
var residents: Dictionary = {}
var zoom_level := 1.0
var meditating := false
var meditation_seconds := 0.0
var reaction_events: Array = []
var aperture_ui: ApertureUI
var cave_gu_claimed := false
var jade_gu_purchased := false
var current_house_id := ""
var current_house_name := ""
var outdoor_return := Vector2.ZERO
var waypoint := Vector2.ZERO
var waypoint_name := ""
var last_action_message := ""

var _rng := RandomNumberGenerator.new()
var _tone_cache := {}
var _sfx_pool: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_rng.randomize()
	y_sort_enabled = true
	_build_world()
	_build_fx()
	_build_player()
	_build_enemies_root()
	_build_top()
	_build_npc()
	_build_camera()
	_build_hud()
	_build_night()
	_build_fog()
	_build_ui_overlays()
	_build_menus()
	_update_camera(0.0)
	player.visible = false
	set_process(true)
	process_mode = Node.PROCESS_MODE_ALWAYS

	var args := OS.get_cmdline_user_args()
	if "--canontest" in args:
		_run_canon_tests.call_deferred()
	if "--featuretest" in args:
		_run_feature_tests.call_deferred()
	if "--polishtest" in args:
		_run_polish_tests.call_deferred()
	for scenario in ["menu","village","interior","shop","journal","character","map","occlusion","elements","aperture","worldmap","waterfall","cave","fog","reaction","meditation","destruction","exploration","atlasfull","minimal","commissions","camp","notes","gujade","guliquor"]:
		if ("--shot"+scenario) in args:
			_take_polish_shot.call_deferred(scenario)
	if "--autostart" in args:
		start_game.call_deferred()
	if "--probe" in args:
		_probe.call_deferred()
	if "--skilltest" in args:
		_skilltest.call_deferred()
	if "--npctest" in args:
		_npctest.call_deferred()
	if "--bosstest" in args:
		_bosstest.call_deferred()
	if "--bodytest" in args:
		_bodytest.call_deferred()
	if "--refinetest" in args:
		_refinetest.call_deferred()
	if "--bagtest" in args:
		_bagtest.call_deferred()
	if "--shotbag" in args:
		_take_shot_bag.call_deferred()
	if "--shottarget" in args:
		_take_shot_target.call_deferred()
	if "--shotrefine" in args:
		_take_shot_refine.call_deferred()
	if "--animaltest" in args:
		_animaltest.call_deferred()
	if "--hosttest" in args:
		_hosttest.call_deferred()
	if "--poitest" in args:
		_poitest.call_deferred()
	if "--perftest" in args:
		_perftest.call_deferred()
	if "--bench" in args:
		_bench.call_deferred()
	if "--shot" in args:
		_take_shot.call_deferred()
	if "--shotcomp" in args:
		_take_shot_comp.call_deferred()
	if "--shotbody" in args:
		_take_shot_body.call_deferred()


func _build_world() -> void:
	world = World.new()
	world.name = "World"
	add_child(world)


func _build_fx() -> void:
	fx = Fx.new()
	fx.name = "Fx"
	fx.game=self
	fx.z_index = 10
	add_child(fx)


func _build_player() -> void:
	player = Player.new()
	player.name = "Player"
	player.game = self
	add_child(player)
	player.position = Vector2((GameData.VILLAGE.x + 1) * TILE, (GameData.VILLAGE.y + 2) * TILE)
	player.reset_stats_for_rank(1)


func _build_enemies_root() -> void:
	enemies_root = Node2D.new()
	enemies_root.name = "Enemies"
	enemies_root.y_sort_enabled = true
	add_child(enemies_root)


func _build_top() -> void:
	top = TopLayer.new()
	top.name = "TopLayer"
	top.z_index = 11
	top.game = self
	add_child(top)


func _build_npc() -> void:
	npc = Npc.new()
	npc.name = "GuMasterAqing"
	npc.position = GameData.BONFIRE + Vector2(186, 104)
	add_child(npc)
	for data in [["clinic","药堂医者"],["shop","商铺伙计"],["archive","学堂执事"]]:
		var person := Npc.new()
		person.resident_id=data[0]
		person.npc_name=data[1]
		person.position=HouseInterior.ORIGIN+Vector2(180,-160)
		person.visible=false
		add_child(person)
		residents[data[0]]=person


func _build_camera() -> void:
	camera = Camera2D.new()
	camera.name = "Camera"
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = GameData.MAP_W * TILE
	camera.limit_bottom = GameData.MAP_H * TILE
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	add_child(camera)
	camera.make_current()
	camera.position = player.position


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	hud = HUD.new()
	hud.game = self
	hud.name = "HUD"
	layer.add_child(hud)


func _build_night() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	night_rect = ColorRect.new()
	night_rect.color = Color(0.03, 0.05, 0.11, 0.0)
	night_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	night_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(night_rect)


# ------------------------------------------------------------------ UI

func _build_fog() -> void:
	var layer := CanvasLayer.new()
	layer.layer=1
	add_child(layer)
	fog=FogOfWar.new()
	fog.game=self
	layer.add_child(fog)


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.045, 0.075, 0.052, 0.97)
	sb.border_color = Color(0.85, 0.80, 0.60, 0.30)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(0.0)
	return sb


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _menu_layer(layer_index: int) -> CanvasLayer:
	var cl := CanvasLayer.new()
	cl.layer = layer_index
	add_child(cl)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.035, 0.025, 0.94)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 0)
	panel.add_theme_stylebox_override("panel", UIStyle.box())
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	cl.set_meta("vbox", vbox)
	return cl


func _build_ui_overlays() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 3
	add_child(ui_layer)
	journal = JournalUI.new()
	journal.game = self
	ui_layer.add_child(journal)
	settings_ui = _make_settings_ui()
	settings_ui.visible = false
	settings_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(settings_ui)
	compendium_ui = CompendiumUI.new()
	compendium_ui.visible = false
	compendium_ui.player = player
	compendium_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(compendium_ui)
	village_ui = VillageUI.new()
	village_ui.game = self
	ui_layer.add_child(village_ui)


func open_journal(page: String) -> void:
	if not running or player.dead: return
	settings_ui.visible = false
	compendium_ui.visible = false
	journal.open_page(page)


func _toggle_ui(which: Control) -> void:
	var key := ""
	if which == character_ui: key = "character"
	elif which == inventory_ui: key = "inventory"
	elif which == body_ui: key = "body"
	elif which == minimap_ui: key = "map"
	if key != "":
		if journal.visible and journal.active_page == key:
			journal.close()
		else:
			open_journal(key)
		return
	journal.close()
	for ui in [settings_ui,compendium_ui]:
		if ui != which: ui.visible = false
	which.visible = not which.visible
	paused = which.visible
	if which == compendium_ui: compendium_ui.refresh()


func _make_settings_ui() -> SettingsUI:
	var ui := SettingsUI.new()
	var panel := Panel.new()
	panel.name = "Panel"
	ui.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)

	for group_name in ["MasterVolume", "MusicVolume", "SfxVolume"]:
		var box := VBoxContainer.new()
		box.name = group_name
		vbox.add_child(box)
		var slider := HSlider.new()
		slider.name = "Slider"
		box.add_child(slider)

	var res_box := VBoxContainer.new()
	res_box.name = "Resolution"
	vbox.add_child(res_box)
	var option := OptionButton.new()
	option.name = "Option"
	res_box.add_child(option)

	var fs_box := VBoxContainer.new()
	fs_box.name = "Fullscreen"
	vbox.add_child(fs_box)
	var check := CheckButton.new()
	check.name = "Check"
	fs_box.add_child(check)

	var key_box := VBoxContainer.new()
	key_box.name = "Keybindings"
	vbox.add_child(key_box)
	var key_btn := Button.new()
	key_btn.name = "Button"
	key_box.add_child(key_btn)

	var close_btn := Button.new()
	close_btn.name = "CloseButton"
	panel.add_child(close_btn)
	return ui


func _build_menus() -> void:
	# Start menu uses the actual village as its backdrop.
	start_layer = CanvasLayer.new()
	start_layer.layer = 5
	add_child(start_layer)
	var screen := StartScreen.new()
	screen.game = self
	start_layer.add_child(screen)
	start_btn = screen.start_button

	# 炼化
	refine_layer = _menu_layer(6)
	refine_layer.visible = false
	var rv: VBoxContainer = refine_layer.get_meta("vbox")
	var rt := _label("炼化 · 以真元磨去蛊虫意志", 24, Color("#d9c46a"))
	rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(rt)
	refine_list = VBoxContainer.new()
	refine_list.add_theme_constant_override("separation", 8)
	rv.add_child(refine_list)
	refine_progress_label = _label("", 12, Color("#d8e6d2"))
	refine_progress_label.visible = false
	rv.add_child(refine_progress_label)
	refine_progress_bar = ProgressBar.new()
	refine_progress_bar.custom_minimum_size = Vector2(0, 16)
	refine_progress_bar.visible = false
	rv.add_child(refine_progress_bar)
	var close := Button.new()
	close.text = "关闭（R）"
	close.custom_minimum_size = Vector2(0, 40)
	close.pressed.connect(close_refine)
	rv.add_child(close)

	# 死亡
	death_layer = _menu_layer(7)
	death_layer.visible = false
	var dv: VBoxContainer = death_layer.get_meta("vbox")
	var dt := _label("你死了", 24, Color("#d9534f"))
	dt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dv.add_child(dt)
	dv.add_child(_label("此次生命已结束。读档是游戏操作，不是春秋蝉、轮回或篝火复活。", 13, Color("#d8e6d2")))
	var respawn_btn := Button.new()
	respawn_btn.text = "读取最近的存档"
	respawn_btn.custom_minimum_size = Vector2(0, 40)
	respawn_btn.pressed.connect(respawn)
	dv.add_child(respawn_btn)

	# 暂停
	pause_layer = _menu_layer(8)
	pause_layer.visible = false
	var pv: VBoxContainer = pause_layer.get_meta("vbox")
	var pt := _label("暂停", 24, Color("#d9c46a"))
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(pt)
	var resume := Button.new()
	resume.text = "继续"
	resume.custom_minimum_size = Vector2(0, 40)
	resume.pressed.connect(func(): toggle_pause(false))
	pv.add_child(resume)
	var reset := Button.new()
	reset.text = "重置存档"
	reset.custom_minimum_size = Vector2(0, 40)
	reset.pressed.connect(func():
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		get_tree().reload_current_scene()
	)
	pv.add_child(reset)

	# 蛊师对话
	dialogue_layer = _menu_layer(9)
	dialogue_layer.visible = false
	var dlgv: VBoxContainer = dialogue_layer.get_meta("vbox")
	var dlg_title := _label("寨中蛊师", 22, Color("#d9c46a"))
	dlg_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dlgv.add_child(dlg_title)
	dialogue_label = _label("", 14, Color("#d8e6d2"))
	dialogue_label.custom_minimum_size = Vector2(560, 0)
	dlgv.add_child(dialogue_label)
	dialogue_btn = Button.new()
	dialogue_btn.text = "接受委托"
	dialogue_btn.custom_minimum_size = Vector2(0, 40)
	dialogue_btn.pressed.connect(_on_dialogue_pressed)
	dlgv.add_child(dialogue_btn)


# ------------------------------------------------------------------ 开始

func start_game() -> void:
	if started:
		return
	started = true
	running = true
	paused = false
	start_layer.visible = false
	player.visible = true
	_load_save()
	_sync_owned_gus()
	_spawn_initial_enemies()
	camera.position = player.position
	last_zone = world.zone_at(player.position)
	zone_banner_text = world.zone_name(last_zone)
	zone_banner_time = 2.4
	add_log("青茅山。风里有瘴气，也有蛊。", Color("#d9c46a"))
	add_log("I 查看外部物品；Q 内视空窍；R 炼化；J 温养窍壁。", Color("#8fa38a"))


func _open_npc_dialogue() -> void:
	if dialogue_layer == null or paused or npc.dead or npc.hostile:
		return
	paused = true
	_update_npc_dialogue()
	dialogue_layer.visible = true


func _update_npc_dialogue() -> void:
	dialogue_label.text="修炼要调动真元温养窍壁。空窍中的元海受资质限制；元石可以补充消耗。\n\n月光蛊喂月兰花瓣，酒虫饮酒。炼化和催动都会耗真元，蛊虫饿死不会自动复活。"
	dialogue_btn.text="知道了"

func _on_dialogue_pressed() -> void:
	_close_npc_dialogue()


func _close_npc_dialogue() -> void:
	dialogue_layer.visible = false
	paused = false


func _spawn_initial_enemies() -> void:
	for row in [["rabbit",18,24],["deer",28,18],["wolf",40,20],["bear",58,38],["wolf",65,48]]:
		_spawn_host(row[0],row[1],row[2])
	# 月光蛊是家族培育，不进入野生掉落池。酒虫由隐蔽遗藏事件取得。


func _spawn_host(id: String, tx: int, ty: int) -> void:
	var x: float = tx * TILE + 16
	var y: float = ty * TILE + 16
	if world.collides(x, y, 14.0):
		return
	var e := _make_host(id, Vector2(x, y))
	if e == null:
		return
	_assign_host_gu(e)
	enemies_root.add_child(e)
	enemies.append(e)


func _make_host(id: String, pos: Vector2) -> Enemy:
	var e := Enemy.new()
	if MonsterSystem.MONSTERS.has(id):
		var md: Dictionary = MonsterSystem.MONSTERS[id].duplicate(true)
		md["id"] = id
		var scale := 0.32 + 0.10 * float(player.rank)
		md["hp"] = float(md["hp"]) * scale
		md["atk"] = float(md["atk"]) * (0.25 + 0.05 * float(player.rank))
		md["rank"] = maxi(1, mini(player.rank, 3))
		e.setup_custom(md)
		e.set_meta("monster_id", id)
	else:
		if not AnimalSystem.ANIMALS.has(id):
			return null
		e.setup_custom(AnimalSystem.ANIMALS[id])
		e.set_meta("animal_id", id)
	e.position = pos
	return e


func _gu_count_for(id: String) -> int:
	match id:
		"rabbit", "deer": return 1
		"wolf", "bear": return 2
		"green_wolf": return 3
	return 1


func _assign_host_gu(e: Enemy) -> void:
	e.carried_gu.clear() # 各物种寄生蛊未核对前，不随机塞入家族蛊或稀有蛊。


func _spawn_boss() -> void:
	boss=null # 删除无原著依据的“万毒蛊王”刷宝首领。


func spawn_enemy(id: String, pos: Vector2) -> Enemy:
	var e := Enemy.new()
	e.setup(id)
	e.position = pos
	enemies_root.add_child(e)
	enemies.append(e)
	return e


func _zone_pool(_zone: String, _max_rank: int) -> Array:
	return []


func random_spawn() -> void:
	for attempt in 40:
		var spot:=player.position+Vector2.from_angle(_rng.randf()*TAU)*_rng.randf_range(500,900)
		var x := clampf(spot.x,64,(GameData.MAP_W-2)*TILE)
		var y := clampf(spot.y,64,(GameData.MAP_H-2)*TILE)
		if world.collides(x, y, 12.0):
			continue
		if Vector2(x, y).distance_to(player.position) < 260.0:
			continue
		if Vector2(x, y).distance_to(GameData.BONFIRE) < 320.0:
			continue
		var zone := world.zone_at(Vector2(x, y))
		var host_id := _animal_for_zone(zone)
		var host := _make_host(host_id, Vector2(x, y))
		if host == null:
			continue
		_assign_host_gu(host)
		enemies_root.add_child(host)
		enemies.append(host)
		return


func _animal_for_zone(zone: String) -> String:
	match zone:
		"forest", "south_forest", "valley":
			return ["rabbit", "deer", "wolf"][_rng.randi_range(0, 2)]
		"marsh":
			return ["rabbit", "deer", "wolf"][_rng.randi_range(0, 2)]
		"rock":
			return ["wolf", "bear"][_rng.randi_range(0, 1)]
		"ruin", "ridge":
			return ["wolf", "bear"][_rng.randi_range(0, 1)]
	return "rabbit"


# ------------------------------------------------------------------ 输入

func _try_poi_interact() -> bool:
	var site:=world.exploration_at(player.position)
	if not site.is_empty():
		visited_sites[site.id]=true
		var message:String=site.text
		if site.kind in ["timber","rubble"]:
			if float(poi_cd.get(site.id,0))>0:
				message="这附近暂时没有散落材料，约 %.0f 秒后再来。" % float(poi_cd[site.id])
			else:
				get_node("/root/Inv").add_item(site.kind,3)
				poi_cd[site.id]=180.0
				message="收集到 %s ×3；可放入行囊，带回商铺出售。" % get_node("/root/Inv").get_item_name(site.kind)
		elif site.kind=="camp":
			save_game()
			village_ui.show_camp(site)
			return true
		_action_message(site.name+" · "+message)
		save_game()
		return true
	var lm := world.poi_at(player.position,110.0)
	if lm.is_empty(): return false
	match String(lm.type):
		"garden": _action_message("月兰花田属于家族。花瓣可在寨中购买，不能无偿反复领取。")
		"pond": _action_message("后山溪瀑。沿水向上，可留意巨石的缝隙；潭水不会恢复真元。")
		"ruin": _action_message("走近巨石缝隙按 E，进入后山密洞。")
		"marsh": _action_message("山腰梯田。这里是寨民耕作的地方。")
		"gate": _action_message("青茅山山道，通往三家山寨。当前地形是地点关系的缩尺表现。")
	return true


func _input(event: InputEvent) -> void:
	# Tab must precede the default GUI focus-navigation handler.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_TAB:
		if running and not player.dead and not village_ui.visible and not pause_layer.visible and not refine_layer.visible and not dialogue_layer.visible:
			if journal.visible: journal.close()
			else: open_journal("character")
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and _can_act():
		set_camera_zoom(zoom_level+(0.1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -0.1))
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if village_ui.visible:
			if event.keycode == KEY_ESCAPE: village_ui.close()
			return
		if running and not player.dead and not refine_layer.visible and not dialogue_layer.visible and not pause_layer.visible:
			var page_keys := {KEY_C:"character",KEY_B:"body",KEY_I:"inventory",KEY_M:"map",KEY_V:"elements",KEY_Q:"aperture",KEY_TAB:"character"}
			if page_keys.has(event.keycode):
				var page: String = page_keys[event.keycode]
				if journal.visible and (journal.active_page == page or event.keycode == KEY_TAB):
					journal.close()
				else:
					open_journal(page)
				get_viewport().set_input_as_handled()
				return
			if journal.visible:
				if event.keycode == KEY_ESCAPE: journal.close()
				elif event.keycode == KEY_H and journal.active_page == "body": treat_part(body_ui.selected_part)
				return
			if settings_ui.visible or compendium_ui.visible:
				if event.keycode in [KEY_ESCAPE,KEY_O,KEY_K]:
					settings_ui.visible = false
					compendium_ui.visible = false
					paused = false
				return
	if event is InputEventKey and event.pressed and not event.echo:
		if refine_layer != null and refine_layer.visible:
			if event.keycode == KEY_R or event.keycode == KEY_ESCAPE:
				close_refine()
			return
		match event.keycode:
			KEY_ESCAPE:
				if running and not player.dead:
					toggle_pause()
			KEY_1:
				if _can_act():
					cast_skill(0)
			KEY_2:
				if _can_act():
					cast_skill(1)
			KEY_3:
				if _can_act():
					cast_skill(2)
			KEY_J:
				if _can_act(): toggle_meditation()
			KEY_SPACE:
				if _can_act():
					do_dash()
			KEY_R:
				if _can_act():
					open_refine()
			KEY_E:
				if _can_act():
					if _try_house_interact():
						pass
					elif npc != null and not npc.dead and not npc.hostile and player.position.distance_to(npc.position) < 80.0:
						_open_npc_dialogue()
					else:
						_try_poi_interact()
			KEY_M:
				if _can_act() and minimap_ui != null:
					_toggle_ui(minimap_ui)
			KEY_C:
				if _can_act() and character_ui != null:
					_toggle_ui(character_ui)
			KEY_I:
				if _can_act() and inventory_ui != null:
					_toggle_ui(inventory_ui)
			KEY_O:
				if _can_act() and settings_ui != null:
					_toggle_ui(settings_ui)
			KEY_K:
				if _can_act() and compendium_ui != null:
					_toggle_ui(compendium_ui)
			KEY_F1:
				if _can_act():
					hud.minimal=not hud.minimal
					save_game()
			KEY_F2:
				_toggle_quality()
			KEY_F3:
				_toggle_vsync()
			KEY_F4:
				_toggle_fps_cap()
			KEY_F11:
				_toggle_fullscreen()
			KEY_B:
				if _can_act() and body_ui != null:
					_toggle_ui(body_ui)
			KEY_H:
				if _can_act():
					_use_bandage()


func _toggle_fps_cap() -> void:
	fps_cap_30 = not fps_cap_30
	Engine.max_fps = 30 if fps_cap_30 else 0
	add_log("帧率上限：%s" % ("30（稳定优先）" if fps_cap_30 else "不限制"), Color("#8fa38a"))


func _toggle_vsync() -> void:
	var mode := DisplayServer.window_get_vsync_mode()
	if mode == DisplayServer.VSYNC_ENABLED:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		add_log("垂直同步：关（更跟手，可能撕裂）。", Color("#8fa38a"))
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		add_log("垂直同步：开。", Color("#8fa38a"))


func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		add_log("窗口模式。", Color("#8fa38a"))
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		add_log("全屏模式。", Color("#8fa38a"))


func _toggle_quality() -> void:
	low_quality = not low_quality
	if fx != null:
		fx.low_quality = low_quality
	Enemy.low_detail = low_quality
	if low_quality:
		DisplayServer.window_set_size(Vector2i(960, 540))
		add_log("低画质：粒子减半，窗口 960×540。", Color("#8fa38a"))
	else:
		DisplayServer.window_set_size(Vector2i(1280, 720))
		add_log("标准画质：1280×720。", Color("#8fa38a"))


func _can_act() -> bool:
	if player.body != null and player.body.unconscious:
		return false
	return running and not paused and not player.dead


# ------------------------------------------------------------------ 主循环

func _process(delta: float) -> void:
	fps_smooth = lerpf(fps_smooth, float(Engine.get_frames_per_second()), 0.06)
	if running and not player.dead:
		play_time += delta
		if play_time > 6.0 and not low_quality and fps_smooth < 45.0:
			low_fps_timer += delta
			if low_fps_timer > 2.5:
				low_fps_timer = 0.0
				_toggle_quality()
				add_log("检测到帧率偏低，已自动切换低画质（F2 可恢复）。", Color("#f0a080"))
		elif fps_smooth >= 45.0:
			low_fps_timer = maxf(0.0, low_fps_timer - delta)
	if refining:
		_update_refine(delta)
	if npc != null and player != null:
		npc.player_pos = player.position
		npc.quest_state = npc_quest_state
	if not running or paused or player.dead:
		return

	commissions.tick(delta)
	if not world.in_interior:
		var zone_now := world.zone_at(player.position)
		if zone_now != last_zone:
			last_zone = zone_now
			zone_banner_text = world.zone_name(zone_now)
			zone_banner_time = 2.4
			if started:
				add_log("进入 %s" % zone_banner_text, world.zone_color(zone_now))
		zone_banner_time = max(0.0, zone_banner_time - delta)
		for k in poi_cd.keys():
			poi_cd[k] = max(0.0, float(poi_cd[k]) - delta)
		_update_target_hint()

	player.atk_cd = max(0.0, player.atk_cd - delta)
	player.dash_cd = max(0.0, player.dash_cd - delta)
	player.iframes = max(0.0, player.iframes - delta)
	player.cast_flash = max(0.0, player.cast_flash - delta)
	for i in 3:
		player.cast_cds[i] = max(0.0, player.cast_cds[i] - delta)

	player.tick_status(delta, self)
	if player.dead: return
	if player.buff_time > 0.0:
		player.buff_time = max(0.0, player.buff_time - delta)
		if player.buff_time <= 0.0:
			player.atk_bonus = 0.0
			player.def_bonus = 0.0
			player.spd_bonus = 0.0

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		basic_attack()

	_update_player(delta)
	_update_pending_melee(delta)
	if not world.in_interior:
		_update_enemies(delta)
		_update_spawn(delta)
	for person in active_npcs():
		person.player_pos=player.position
		person.tick(delta,self)
	_update_projectiles(delta)
	_update_hazards(delta)
	_update_meditation(delta)
	_update_reaction_events(delta)
	if world.in_interior and not HouseInterior.BOUNDS.grow(24).has_point(player.position-HouseInterior.ORIGIN): exit_house()
	_update_camera(delta)
	_update_night(delta)

	if not world.in_interior and Input.is_key_pressed(KEY_E):
		try_capture(delta)
	else:
		player.capture_progress = 0.0
		player.capture_target = null

	# 自动存档
	save_t += delta
	if save_t > 12.0:
		save_t = 0.0
		save_game()


func _update_target_hint() -> void:
	target_hint = null
	if player == null or player.dead:
		return
	if player.capture_target is Enemy:
		target_hint = player.capture_target
		return
	var aim := (get_global_mouse_position() - player.position).angle()
	var best := 220.0
	for e in enemies:
		if e.dead:
			continue
		var d := player.position.distance_to(e.position)
		if d > best or not fog.can_see(e.position):
			continue
		var da := wrapf((e.position - player.position).angle() - aim, -PI, PI)
		if abs(da) > 1.0:
			continue
		best = d
		target_hint = e


func _update_player(delta: float) -> void:
	player.aperture.recover(delta)
	_update_owned_gu(delta)
	if player.body != null and player.body.unconscious:
		return
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y += 1.0

	var spd := (player.speed + player.spd_bonus) * (player.body.get_move_multiplier() if player.body != null else 1.0)
	if player.dash_t > 0.0:
		spd *= 3.2
	if v.length() > 0.0:
		stop_meditation("移动打断打坐。")
		v = v.normalized()
		world.move_body(player, v.x * spd * delta, v.y * spd * delta, player.radius)
		if player.dash_t <= 0.0:
			player.dir = v.angle()
	player.dash_t = max(0.0, player.dash_t - delta)

	# 瞄准
	var aim := get_global_mouse_position()
	player.dir = (aim - player.position).angle()


func _update_camera(delta: float) -> void:
	camera.position = HouseInterior.ORIGIN if world.in_interior else player.position.round()
	if shake > 0.2:
		camera.offset = Vector2(_rng.randf_range(-shake, shake), _rng.randf_range(-shake, shake))
		shake *= 0.86
	else:
		camera.offset = Vector2.ZERO

	camera.zoom=Vector2.ONE*zoom_level
	var vp := get_viewport_rect().size/zoom_level
	world.view_size = vp
	world.camera_pos = camera.get_screen_center_position() - vp * 0.5
	world.player_pos = player.position


func _update_night(delta: float) -> void:
	day_time += delta
	var t := fmod(day_time, 180.0) / 180.0
	var alpha := 0.0
	if t > 0.55 and t < 0.95:
		alpha = sin((t - 0.55) / 0.4 * PI) * 0.35
	elif t >= 0.95 or t < 0.10:
		alpha = 0.35 * ((t - 0.95) / 0.05 if t >= 0.95 else 1.0 - t / 0.10)
	night_rect.color = Color(0.03, 0.05, 0.11, alpha)


func _update_spawn(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer>10.0:
		spawn_timer=0.0
		for enemy in enemies.duplicate():
			if enemy.position.distance_to(player.position)>1800 and enemy.carried_gu.is_empty() and enemy!=player.capture_target:
				enemies.erase(enemy)
				enemy.queue_free()
		if enemies.size()<18: random_spawn()


# ------------------------------------------------------------------ 战斗

func basic_attack() -> void:
	if player.atk_cd > 0.0 or player.dead or paused:
		return
	stop_meditation("攻击打断打坐。")
	player.atk_cd = 0.38 / maxf(0.5, player.body.get_attack_speed_multiplier() if player.body != null else 1.0)
	var acc := player.body.get_accuracy() if player.body != null else 1.0
	var a := (get_global_mouse_position() - player.position).angle()
	var hit := false
	for e in enemies:
		if e.dead:
			continue
		var d := player.position.distance_to(e.position)
		if d > 54.0 + e.radius:
			continue
		var da := wrapf((e.position - player.position).angle() - a, -PI, PI)
		if abs(da) > 0.85:
			continue
		if acc < 1.0 and _rng.randf() > acc:
			continue
		damage_enemy(e, (player.atk + player.atk_bonus) * _rng.randf_range(0.9, 1.1), "none")
		hit = true
	strike_world(player.position,64,player.atk+player.atk_bonus,"none",Vector2.from_angle(a),cos(0.85))
	if hit:
		_play_tone(180.0, 0.08, 0.10)
	fx.ring(player.position.x + cos(a) * 24.0, player.position.y + sin(a) * 24.0,
		Color("#e8e0c8"), 10.0, 54.0, 0.18)
	if not hit:
		fx.burst(player.position.x + cos(a) * 30.0, player.position.y + sin(a) * 30.0,
			Color("#8a8a7a"), 2, 40.0, 0.2)


func damage_enemy(e: Enemy, dmg: float, el: String) -> void:
	if e.dead:
		return
	var final := int(max(1.0, round(dmg * _rng.randf_range(0.92, 1.08))))
	e.hp -= final
	e.flash = 0.12
	e.state = "chase"
	var col := GameData.el_color(el) if el != "none" else Color("#f0e8d0")
	fx.text(e.position.x + _rng.randf_range(-6, 6), e.position.y - 18, str(final), col)
	fx.burst(e.position.x, e.position.y, GameData.el_color(el) if el != "none" else e.color, 5, 90.0, 0.3)
	if e.hp <= 0.0:
		kill_enemy(e)


func kill_enemy(e: Enemy) -> void:
	if e.dead: return
	e.dead=true
	var inv := get_node("/root/Inv")
	var animal_id := String(e.get_meta("animal_id",""))
	if animal_id!="":
		for drop in AnimalSystem.ANIMALS[animal_id].get("drops",[]): inv.add_item(String(drop),1)
	kills+=1
	fx.burst(e.position.x,e.position.y,e.color,12,120,0.4)
	add_log("击倒%s，修行境界不因击杀而增长。" % e.display_name,UIStyle.DIM)
	enemies.erase(e)
	e.queue_free()
	save_game()


func damage_player(dmg: float, element: String = "none") -> void:
	if player.dead or player.iframes > 0.0:
		return
	stop_meditation("受到攻击，打坐中断。")
	if player.jade_guard and player.aperture.spend(dmg*0.35):
		dmg*=0.4
	elif player.jade_guard:
		player.jade_guard=false
	var had_shield := player.shield > 0.0
	if had_shield:
		var absorbed := min(player.shield, dmg)
		player.shield -= absorbed
		dmg -= absorbed
		fx.text(player.position.x, player.position.y - 20, "盾 -%d" % int(absorbed), Color("#b08a4f"))
	if dmg <= 0.0:
		return
	var part_mult := 0.5 if had_shield else 1.0
	var res: Dictionary = player.take_body_hit(dmg * part_mult, element)
	player.hp -= max(1.0, round(dmg))
	player.iframes = 0.35
	player.hurt_flash = 0.2
	shake = min(12.0, shake + 5.0)
	fx.burst(player.position.x, player.position.y, Color("#d9534f"), 8, 100.0, 0.35)
	if not res.is_empty():
		var pname := String(res.get("name", ""))
		var pdmg := int(res.get("part_damage", 0.0))
		fx.text(player.position.x + _rng.randf_range(-8, 8), player.position.y - 34,
			"%s -%d" % [pname, pdmg], Color("#f0a080"), 12)
		if bool(res.get("destroyed", false)):
			shake = 12.0
			_play_tone(140.0, 0.25, 0.18)
			add_log("%s 毁坏！" % pname, Color("#d9534f"))
			if player.body != null and player.body.unconscious:
				add_log("疼痛/意识崩溃，你陷入了昏迷。", Color("#d9534f"))
	if player.hp <= 0.0:
		player_death()


func player_death() -> void:
	if player.dead:
		return
	meditating=false
	player.dead = true
	player.hp = 0.0
	shake = 12.0
	_play_tone(110.0, 0.50, 0.20)
	fx.burst(player.position.x, player.position.y, Color("#d9534f"), 30, 160.0, 0.9)
	death_layer.visible = true
	paused = true


func respawn() -> void:
	# 明确的游戏读档，不是世界内重生；未覆盖最近活着的存档。
	get_tree().reload_current_scene()


func check_rank_up() -> void:
	pass # 击杀、捕获、炼化均不增长修为。温养完成后在空窍页主动冲关。


func cast_skill(slot: int) -> void:
	stop_meditation("催蛊打断打坐。")
	var gu := equipped_gu(slot)
	if gu==null:
		_action_message("此催蛊快捷位未绑定可用蛊虫，请在 Q 空窍页设置。")
		return
	var id: String = gu.template_id
	var data: Dictionary = GameData.GU[id]
	var sk: Dictionary = data.skill
	if player.cast_cds[slot]>0 or not player.body.can_cast(): return
	if sk.kind=="refine_essence":
		var success:=player.aperture.refine_essence()
		_action_message("消耗两成真元，得到半成高一小阶真元。" if success else "需要两成未精炼的一转真元；巅峰或二转真元不适用。")
		if success: player.cast_cds[slot]=0.8
		return
	if sk.kind=="jade_guard":
		if not player.jade_guard and not player.aperture.can_spend(1):
			_action_message("真元不足以维持玉皮。")
			return
		player.jade_guard=not player.jade_guard
		_action_message("正在持续灌注真元，维持玉皮。" if player.jade_guard else "已停止玉皮防御。")
		return
	if not player.aperture.spend(float(sk.cost)):
		_action_message("真元不足。")
		return
	player.cast_cds[slot] = sk["cd"]
	player.cast_flash = 0.25
	_play_tone(520.0, 0.10, 0.10)
	var aim := (get_global_mouse_position() - player.position).angle()
	player.dir = aim
	if sk["kind"] in ["aoe","chain","instant","dash","melee"]:
		var reach := float(sk.get("range",120.0))
		strike_world(player.position,reach,float(sk.dmg),String(sk.element),Vector2.from_angle(aim) if sk["kind"] in ["melee","dash","instant"] else Vector2.ZERO,cos(1.0))

	match sk["kind"]:
		"proj":
			spawn_projectile(player.position, Vector2(cos(aim), sin(aim)) * sk["speed"],
				sk["dmg"], sk["element"], "player", sk)
		"melee3":
			for i in 3:
				pending_melee.append({"time": i * 0.11, "dmg": sk["dmg"], "element": sk["element"], "burn": sk["burn"]})
		"shield":
			player.shield += sk["shield"]
			fx.ring(player.position.x, player.position.y, sk["color"], 8.0, 40.0, 0.5)
			fx.text(player.position.x, player.position.y - 24, "护盾 +%d" % int(sk["shield"]), sk["color"])
		"dash":
			var start := player.position
			var moved := 0.0
			var step := 8.0
			while moved < sk["distance"]:
				var nx := player.position + Vector2(cos(aim), sin(aim)) * step
				if world.collides(nx.x, nx.y, player.radius):
					break
				player.position = nx
				moved += step
			player.iframes = 0.25
			for e in enemies:
				if not e.dead and start.distance_to(e.position) < 70.0 + e.radius:
					damage_enemy(e, sk["dmg"], sk["element"])
			fx.burst(player.position.x, player.position.y, sk["color"], 14, 160.0)
		"chain":
			var cur: Enemy = null
			var best := 160.0 * 160.0
			for e in enemies:
				if e.dead:
					continue
				var d2 := player.position.distance_squared_to(e.position)
				if d2 < best:
					best = d2
					cur = e
			if cur == null:
				add_log("附近没有目标。", Color("#d9534f"))
				return
			var hit_set: Array = []
			var from := player.position
			for j in int(sk["jumps"]):
				if cur == null:
					break
				fx.ring(from.x, from.y, sk["color"], 4.0, 40.0, 0.2)
				damage_enemy(cur, sk["dmg"], sk["element"])
				apply_status(cur, sk["element"])
				hit_set.append(cur)
				from = cur.position
				var next: Enemy = null
				var nd := float(sk["range"]) * float(sk["range"])
				for e in enemies:
					if e.dead or e in hit_set:
						continue
					var d2 := from.distance_squared_to(e.position)
					if d2 < nd:
						nd = d2
						next = e
				cur = next
		"aoe":
			var rng := float(sk.get("range", 120.0))
			for e in enemies:
				if e.dead:
					continue
				if player.position.distance_to(e.position) < rng + e.radius:
					damage_enemy(e, sk["dmg"], sk["element"])
					apply_status(e, sk["element"])
			fx.ring(player.position.x, player.position.y, sk["color"], 8.0, rng, 0.4)
		"multi":
			var count := int(sk.get("count", 3))
			for i in count:
				var angle := aim + (i - count / 2.0) * 0.3
				spawn_projectile(player.position, Vector2(cos(angle), sin(angle)) * sk["speed"],
					sk["dmg"], sk["element"], "player", sk)
		"instant":
			var tgt: Enemy = null
			var best := float(sk.get("range", 200.0)) * float(sk.get("range", 200.0))
			for e in enemies:
				if e.dead:
					continue
				var d2 := player.position.distance_squared_to(e.position)
				if d2 < best:
					best = d2
					tgt = e
			if tgt:
				damage_enemy(tgt, sk["dmg"], sk["element"])
				fx.ring(tgt.position.x, tgt.position.y, sk["color"], 4.0, 30.0, 0.3)
		"buff":
			var dur := float(sk.get("duration", 5.0))
			player.buff_time = max(player.buff_time, dur)
			if sk.has("atk_bonus"):
				player.atk_bonus += float(sk["atk_bonus"])
			if sk.has("def_bonus"):
				player.def_bonus += float(sk["def_bonus"])
			if sk.has("spd_bonus"):
				player.spd_bonus += float(sk["spd_bonus"])
			fx.text(player.position.x, player.position.y - 24, "强化！", sk["color"])
		"bind":
			var rng := float(sk.get("range", 150.0))
			var dur := float(sk.get("duration", 2.0))
			for e in enemies:
				if e.dead:
					continue
				if player.position.distance_to(e.position) < rng + e.radius:
					e.status["bind"] = max(e.status.get("bind", 0.0), dur)
					fx.ring(e.position.x, e.position.y, sk["color"], 4.0, 20.0, 0.3)
		"melee":
			var rng := float(sk.get("range", 64.0))
			for e in enemies:
				if e.dead:
					continue
				if player.position.distance_to(e.position) < rng + e.radius:
					var da := wrapf((e.position - player.position).angle() - aim, -PI, PI)
					if abs(da) < 1.2:
						damage_enemy(e, sk["dmg"], sk["element"])
						apply_status(e, sk["element"])
			fx.burst(player.position.x + cos(aim) * 40.0, player.position.y + sin(aim) * 40.0, sk["color"], 8, 120.0)
		"summon":
			add_log("召唤技能暂未实装", Color("#f0ad4e"))
		"slow":
			var rng := float(sk.get("range", 120.0))
			var dur := float(sk.get("duration", 3.0))
			for e in enemies:
				if e.dead:
					continue
				if player.position.distance_to(e.position) < rng + e.radius:
					e.status["slow"] = max(e.status.get("slow", 0.0), dur)
			fx.ring(player.position.x, player.position.y, sk["color"], 6.0, rng, 0.4)
		"reflect":
			var dur := float(sk.get("duration", 4.0))
			player.status["reflect"] = dur
			fx.ring(player.position.x, player.position.y, sk["color"], 8.0, 50.0, 0.5)
		"heal":
			var amt := float(sk.get("amount", 50.0))
			player.hp = min(player.hp + amt, player.max_hp)
			fx.text(player.position.x, player.position.y - 24, "+%.0f" % amt, Color("#5cb85c"))
		"debuff":
			var rng := float(sk.get("range", 150.0))
			var dur := float(sk.get("duration", 4.0))
			for e in enemies:
				if e.dead:
					continue
				if player.position.distance_to(e.position) < rng + e.radius:
					if sk.has("atk_down"):
						e.status["atk_down"] = dur
					if sk.has("def_down"):
						e.status["def_down"] = dur
			fx.ring(player.position.x, player.position.y, sk["color"], 6.0, rng, 0.4)
	add_log("催动【%s】" % sk["name"], Color("#d9c46a"))

# ------------------------------------------------------------------ 补齐（用户重写 Main 时遗漏的运行函数）

func _update_pending_melee(delta: float) -> void:
	for i in range(pending_melee.size() - 1, -1, -1):
		var m: Dictionary = pending_melee[i]
		m["time"] -= delta
		if m["time"] <= 0.0:
			var aim := (get_global_mouse_position() - player.position).angle()
			for e in enemies:
				if e.dead:
					continue
				if player.position.distance_to(e.position) < 64.0 + e.radius:
					var da := wrapf((e.position - player.position).angle() - aim, -PI, PI)
					if abs(da) < 1.0:
						damage_enemy(e, m["dmg"], m["element"])
						apply_status(e, m["element"])
						if float(m.get("burn", 0.0)) > 0.0:
							e.status["burn"] = max(e.status.get("burn", 0.0), float(m["burn"]))
			strike_world(player.position,68,float(m.dmg),String(m.element),Vector2.from_angle(aim),cos(1.0))
			fx.burst(player.position.x + cos(aim) * 30.0, player.position.y + sin(aim) * 30.0,
				GameData.el_color(m["element"]), 6, 100.0)
			pending_melee.remove_at(i)


func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var e := enemies[i]
		if e.dead:
			enemies.remove_at(i)
			continue
		update_enemy(e, delta)


func update_enemy(e: Enemy, delta: float) -> void:
	e.flash = max(0.0, e.flash - delta)
	e.stun = max(0.0, e.stun - delta)
	e.atk_cd -= delta
	e.gu_cast_cd -= delta

	for k in ["burn", "poison", "wet", "shock", "slow", "bleed","bind"]:
		if float(e.status.get(k, 0.0)) > 0.0:
			e.status[k] = max(0.0, float(e.status[k]) - delta)
			if k == "burn" and _rng.randf() < delta * 3.0:
				damage_enemy(e, 3.0, "fire")
			if k == "poison" and _rng.randf() < delta * 2.2:
				damage_enemy(e, 2.5, "wood")
			if k == "bleed" and _rng.randf() < delta * 2.5:
				damage_enemy(e, 2.0, "metal")
	if e.dead or e.stun > 0.0:
		return

	var d := e.position.distance_to(player.position)
	var safe := player.position.distance_to(GameData.BONFIRE) < 120.0
	var can_see := d < 300.0 and not player.dead and not safe

	if can_see and not e.carried_gu.is_empty() and e.gu_cast_cd <= 0.0:
		e.gu_cast_cd = _rng.randf_range(2.4, 3.8)
		_host_cast_gu(e)

	if e.state == "flee" or (e.ai == "flee" and e.hp < e.max_hp * 0.45):
		if can_see and d < 260.0:
			var a := (e.position - player.position).angle()
			world.move_body(e, cos(a) * e.spd * 1.15 * delta, sin(a) * e.spd * 1.15 * delta, e.radius)
			e.dir = a
		else:
			_wander(e, delta)
		return

	if can_see:
		e.state = "chase"
		var a := (player.position - e.position).angle()
		e.dir = a
		if d > e.radius + player.radius + 14.0:
			var sp := e.spd
			if float(e.status.get("slow", 0.0)) > 0.0 or float(e.status.get("bind", 0.0)) > 0.0:
				sp *= 0.55
			world.move_body(e, cos(a) * sp * delta, sin(a) * sp * delta, e.radius)
		elif e.atk_cd <= 0.0:
			e.atk_cd = _rng.randf_range(1.2, 2.0)
			_enemy_attack(e)
	else:
		_wander(e, delta)


func _wander(e: Enemy, delta: float) -> void:
	e.wander_t -= delta
	if e.wander_t <= 0.0:
		e.wander_t = _rng.randf_range(1.2, 3.0)
		e.dir = _rng.randf() * TAU
		e.moving = _rng.randf() < 0.6
	if e.moving:
		world.move_body(e, cos(e.dir) * e.spd * 0.35 * delta, sin(e.dir) * e.spd * 0.35 * delta, e.radius)


func _host_cast_gu(e: Enemy) -> void:
	if e.carried_gu.is_empty() or player.dead:
		return
	var gid := String(e.carried_gu[_rng.randi_range(0, e.carried_gu.size() - 1)])
	if not GameData.GU.has(gid):
		return
	var sk: Dictionary = GameData.GU[gid]["skill"]
	var el := String(sk["element"])
	var dmg := e.atk * 0.8 + float(sk["dmg"]) * 0.25
	var aim := (player.position - e.position).angle()
	fx.ring(e.position.x, e.position.y, sk["color"], 3.0, 34.0, 0.3)
	fx.text(e.position.x, e.position.y - e.radius - 10, String(sk["name"]), sk["color"], 10)
	match String(sk["kind"]):
		"proj", "chain", "instant":
			spawn_projectile(e.position, Vector2(cos(aim), sin(aim)) * 300.0, dmg, el, "enemy", sk)
		"multi":
			for i in int(sk.get("count", 3)):
				var a := aim + (float(i) - 1.0) * 0.22
				spawn_projectile(e.position, Vector2(cos(a), sin(a)) * 300.0, dmg, el, "enemy", sk)
		"aoe":
			var rng := float(sk.get("range", 120.0))
			if e.position.distance_to(player.position) < rng + player.radius:
				damage_player(dmg, el)
				fx.ring(player.position.x, player.position.y, sk["color"], 4.0, rng, 0.4)
		"heal":
			e.hp = min(e.max_hp, e.hp + float(sk.get("amount", 40.0)))
			fx.text(e.position.x, e.position.y - e.radius, "+%d" % int(sk.get("amount", 40.0)), Color("#5fbf6a"), 11)
		"shield":
			e.shield += float(sk.get("shield", 30.0))
		"dash":
			world.move_body(e, cos(aim) * 46.0, sin(aim) * 46.0, e.radius)
		"buff":
			e.atk *= 1.12
		"reflect":
			e.shield += 25.0
		_:
			damage_player(dmg * 0.6, el)
			apply_status_player(el)


func _enemy_attack(e: Enemy) -> void:
	if e.position.distance_to(player.position) > 90.0:
		return
	if e.kind == "green_snake" or e.kind == "leiwen":
		var a := (player.position - e.position).angle()
		spawn_projectile(e.position, Vector2(cos(a), sin(a)) * 300.0,
			e.atk + 3.0, e.element, "enemy",
			{"color": GameData.el_color(e.element), "pierce": 0})
	else:
		if e.position.distance_to(player.position) < e.radius + player.radius + 18.0:
			damage_player(e.atk + _rng.randf_range(0.0, 3.0), e.element)
			if e.element == "fire" or e.element == "wood":
				apply_status_player(e.element)


func spawn_projectile(pos: Vector2, vel: Vector2, dmg: float, el: String, owner: String, sk: Dictionary) -> void:
	projectiles.append({
		"pos": pos, "vel": vel, "dmg": dmg, "el": el, "owner": owner,
		"life": 1.2, "max_life": 1.2, "r": 7.0 if int(sk.get("pierce", 0)) > 0 else 6.0,
		"color": sk.get("color", GameData.el_color(el)), "pierce": int(sk.get("pierce", 0)),
		"hit_set": [], "poison": float(sk.get("poison", 0.0)), "burn": float(sk.get("burn", 0.0)),
	})


func _update_projectiles(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var pr: Dictionary = projectiles[i]
		pr["life"] -= delta
		var steps := 3
		for s in steps:
			if pr["life"] <= 0.0:
				break
			pr["pos"] = pr["pos"] + pr["vel"] * delta / steps
			var tx := int(floor(pr["pos"].x / TILE))
			var ty := int(floor(pr["pos"].y / TILE))
			if world.collides(pr["pos"].x,pr["pos"].y,0):
				if pr["owner"]=="player": strike_world(pr["pos"],18,float(pr["dmg"]),String(pr["el"]),Vector2.ZERO,-1,false)
				fx.burst(pr["pos"].x, pr["pos"].y, pr["color"], 6, 70.0, 0.25)
				pr["life"] = 0.0
				break
			if pr["owner"] == "player":
				for person in active_npcs():
					if person.dead or person in pr.hit_set: continue
					if pr.pos.distance_to(person.position)<person.radius+float(pr.r):
						person.take_damage(float(pr.dmg),self,String(pr.el))
						pr.hit_set.append(person)
						if int(pr.pierce)>0: pr.pierce-=1
						else: pr.life=0.0
						break
				if pr.life<=0: break
				for e in enemies:
					if e.dead or e in pr["hit_set"]:
						continue
					if pr["pos"].distance_to(e.position) < e.radius + pr["r"]:
						damage_enemy(e, pr["dmg"], pr["el"])
						apply_status(e, pr["el"])
						if pr["poison"] > 0.0:
							e.status["poison"] = max(float(e.status.get("poison", 0.0)), pr["poison"])
						if pr["burn"] > 0.0:
							e.status["burn"] = max(float(e.status.get("burn", 0.0)), pr["burn"])
						pr["hit_set"].append(e)
						fx.burst(pr["pos"].x, pr["pos"].y, pr["color"], 8, 110.0, 0.3)
						if pr["pierce"] > 0:
							pr["pierce"] -= 1
						else:
							pr["life"] = 0.0
						break
			else:
				if not player.dead and pr["pos"].distance_to(player.position) < player.radius + pr["r"]:
					damage_player(pr["dmg"], pr["el"])
					apply_status_player(pr["el"])
					fx.burst(pr["pos"].x, pr["pos"].y, pr["color"], 8, 110.0, 0.3)
					pr["life"] = 0.0
		if pr["life"] <= 0.0:
			projectiles.remove_at(i)


func apply_status(_target: Enemy, _el: String) -> void:
	pass # 道途不等于元素标签；附加状态只由具体蛊术写入。


func apply_status_player(_el: String) -> void:
	pass


func try_capture(delta: float) -> void:
	if player.dead:
		return
	var target: Enemy = null
	var best := 80.0 * 80.0
	for e in enemies:
		if e.dead:
			continue
		if e.is_animal:
			if e.carried_gu.is_empty():
				continue
		elif not GameData.GU.has(e.kind):
			continue
		if e.hp / e.max_hp > 0.35:
			continue
		var d2 := player.position.distance_squared_to(e.position)
		if d2 < best:
			best = d2
			target = e
	if target == null:
		player.capture_target = null
		player.capture_progress = 0.0
		return
	if player.capture_target != target:
		player.capture_target = target
		player.capture_progress = 0.0
	player.capture_progress += delta
	if player.capture_progress >= 1.2:
		var ratio := target.hp / target.max_hp
		var chance := clampf(0.6 + (1.0 - ratio) * 0.35, 0.55, 0.95)
		if _rng.randf() < chance:
			if target.is_animal:
				_capture_host_gu(target)
			else:
				_capture_success(target)
		else:
			add_log("%s 挣脱了！" % target.display_name, Color("#d9534f"))
			target.state = "flee"
			target.stun = 0.8
			fx.burst(target.position.x, target.position.y, Color("#d9534f"), 10, 120.0)
		player.capture_progress = 0.0
		player.capture_target = null


func _capture_host_gu(e: Enemy) -> void:
	if e.carried_gu.is_empty():
		return
	var idx := _rng.randi_range(0, e.carried_gu.size() - 1)
	var gid := String(e.carried_gu[idx])
	e.carried_gu.remove_at(idx)
	var gd: Dictionary = GameData.GU[gid]
	var quality: String = "normal"
	player.captured.append({
		"id": gid, "rank": int(gd["rank"]), "quality": quality,
	})
	captures += 1
	if not player.discovered.has(gid):
		player.discovered.append(gid)

	_play_tone(880.0, 0.20, 0.14)
	fx.burst(e.position.x, e.position.y, gd["color"], 22, 200.0, 0.7)
	fx.ring(e.position.x, e.position.y, gd["color"], 4.0, 60.0, 0.6)
	add_log("从 %s 身上收走 %s！按 R 就地炼化。" % [e.display_name, gd["name"]], Color("#5fbf6a"))
	e.state = "flee"
	e.stun = 0.8
	_update_quest()
	check_rank_up()
	save_game()


func _capture_success(e: Enemy) -> void:
	e.dead = true
	player.captured.append({
		"id": e.kind, "rank": e.rank,
		"quality": "normal",
	})
	captures += 1
	if not player.discovered.has(e.kind):
		player.discovered.append(e.kind)

	_play_tone(880.0, 0.20, 0.14)
	fx.burst(e.position.x, e.position.y, Color("#d9c46a"), 24, 220.0, 0.7)
	fx.ring(e.position.x, e.position.y, Color("#d9c46a"), 4.0, 60.0, 0.6)
	add_log("捕获 %s！按 R 就地炼化。" % GameData.GU[e.kind]["name"], Color("#5fbf6a"))
	enemies.erase(e)
	e.queue_free()
	_update_quest()
	check_rank_up()
	save_game()


func open_refine() -> void:
	if player.dead:
		return
	if paused and not refine_layer.visible:
		return
	paused = true
	_rebuild_refine()
	refine_layer.visible = true


func close_refine() -> void:
	if refining:
		add_log("炼化被打断，蛊虫保住了。", Color("#d9534f"))
		refining = false
		refine_target = -1
		refine_progress_bar.visible = false
		refine_progress_label.visible = false
	paused = false
	refine_layer.visible = false


func _refine_duration(_rank: int) -> float:
	return 100.0 # 进度上限，不是收取固定货币的秒数。


func _update_refine(delta: float) -> void:
	if not refining or refine_target<0 or refine_target>=player.captured.size(): return
	player.aperture.recover(delta)
	var c: Dictionary=player.captured[refine_target]
	var difficulty:=2.0 if c.id=="jiu_chong" else 1.0
	var available:float=(player.aperture.essence+player.aperture.refined_essence*2.0)*pow(2.0,player.aperture.stage)
	var spent:=minf(available,delta)
	player.aperture.spend(spent)
	_update_owned_gu(delta)
	c["progress"]=clampf(float(c.get("progress",0))+spent/difficulty-maxf(0,delta-spent)*0.12,0,100)
	refine_elapsed=float(c.progress)
	refine_progress_bar.value=refine_elapsed
	refine_progress_label.text="磨去意志 %.1f%% · 真元 %.1f%% · 中断后意志会反抗" % [refine_elapsed,player.yuan]
	if refine_elapsed>=100: _finish_refine()


func _quality_key(q: String) -> String:
	match q:
		"粗劣": return "crude"
		"普通": return "normal"
		"精良": return "fine"
		"卓越": return "excellent"
		"完美": return "perfect"
	return "normal"


func _finish_refine() -> void:
	var i:=refine_target
	refining=false
	refine_target=-1
	refine_progress_bar.visible=false
	refine_progress_label.visible=false
	if i<0 or i>=player.captured.size(): return
	var c: Dictionary=player.captured[i]
	if float(c.get("progress",0))<100: return
	var gu: GuVirtual=get_node("/root/Gus").add_gu(String(c.id))
	if gu==null: return
	player.captured.remove_at(i)
	player.owned.append(gu.template_id)
	if player.vital_gu_id=="": player.vital_gu_id=gu.id
	for n in 3:
		if player.skill_slots[n]=="":
			player.skill_slots[n]=gu.id
			break
	refined+=1
	_action_message("炼化成功，%s已收入空窍。快捷位满时仍可继续炼化。"%gu.name)
	_rebuild_refine()
	save_game()


func _rebuild_refine() -> void:
	for c in refine_list.get_children():
		refine_list.remove_child(c)
		c.queue_free()
	if player.captured.is_empty():
		refine_list.add_child(_label("外部行囊中没有待炼化的蛊虫。",14,UIStyle.DIM))
		return
	for i in player.captured.size():
		var c: Dictionary=player.captured[i]
		var row:=HBoxContainer.new()
		var picture:=GuArt.portrait(42)
		picture.texture=GuArt.texture(c.id)
		row.add_child(picture)
		var label:=_label("%s · 未炼化 · 意志磨合 %.1f%%" % [GameData.GU[c.id].name,float(c.get("progress",0))],14,UIStyle.INK)
		label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var b:=UIStyle.button("注入真元",_refine_at.bind(i))
		b.disabled=refining
		row.add_child(b)
		refine_list.add_child(row)
	refine_list.add_child(UIStyle.button("吸收一块元石补充真元",absorb_primeval_stone))


func _refine_at(i: int) -> void:
	if refining or i<0 or i>=player.captured.size(): return
	refining=true
	refine_target=i
	refine_elapsed=float(player.captured[i].get("progress",0))
	refine_duration=100
	refine_progress_bar.max_value=100
	refine_progress_bar.value=refine_elapsed
	refine_progress_bar.visible=true
	refine_progress_label.visible=true
	_rebuild_refine()


func _update_quest() -> void:
	pass


func save_game() -> void:
	if not started or player == null or player.dead:
		return
	var data := {
		"version":6,
		"commissions":commissions.save_data(),
		"map_version":GameData.MAP_VERSION,
		"map_width":GameData.MAP_W,
		"position":[player.position.x,player.position.y],
		"house_id":current_house_id if world.in_interior else "",
		"visited_sites":visited_sites,
		"claimed_camps":claimed_camps,
		"poi_cd":poi_cd,
		"hud_hidden":hud.minimal,
		"aperture":player.aperture.save_data(),
		"skill_slots":player.skill_slots,
		"vital_gu_id":player.vital_gu_id,
		"cave_gu_claimed":cave_gu_claimed,
		"jade_gu_purchased":jade_gu_purchased,
		"world_damage":world.destruction.save_data(),
		"explored":fog.explored.keys(),
		"camera_zoom":zoom_level,
		"npcs":npc_save_data(),
		"body": player.body.save_data(),
		"hp": player.hp,
		"yuan": player.yuan,
		"rank": player.rank,
		"xiuwei": player.xiuwei,
		"crystals": player.crystals,
		"materials": player.materials,
		"owned": player.owned,
		"captured": player.captured,
		"discovered": player.discovered,
		"npc_quest": npc_quest_state,
		"captures": captures,
		"refined": refined,
		"quest_done": quest_done,
		"kills": kills,
	}
	var inv := get_node_or_null("/root/Inv")
	if inv != null:
		data["inventory"] = inv.items
	var gus := get_node_or_null("/root/Gus")
	var hunger := get_node_or_null("/root/Hunger")
	if gus != null: data["gus"] = gus.save_data()
	if hunger != null: data["hunger"] = hunger.save_data()
	data["waypoint"] = [waypoint.x,waypoint.y]
	data["waypoint_name"] = waypoint_name
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))


func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		var inv:=get_node("/root/Inv")
		inv.items.clear()
		inv.add_item("moon_petals",10)
		inv.add_item("bandage",3)
		inv.add_item("bamboo_wine",1)
		player.captured=[{"id":"moon_blade","rank":1,"quality":"normal","progress":0.0}]
		player.discovered.assign(["moon_blade"])
		get_node("/root/Gus").owned_gus.clear()
		get_node("/root/Hunger").gu_data.clear()
		return
	var txt := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed = JSON.parse_string(txt)
	if not (parsed is Dictionary):
		return
	var d: Dictionary = parsed
	var r := int(d.get("rank", 1))
	player.reset_stats_for_rank(clamp(r, 1, 5))
	player.aperture.load_data(d.get("aperture",{}))
	cave_gu_claimed=bool(d.get("cave_gu_claimed",false))
	jade_gu_purchased=bool(d.get("jade_gu_purchased",false))
	player.crystals = int(d.get("crystals", 60))
	player.materials = int(d.get("materials", 0))
	player.owned.clear()
	player.captured.clear()
	player.discovered.clear()
	var owned_raw = d.get("owned", [])
	for x in owned_raw:
		if GameData.GU.has(String(x)):
			player.owned.append(String(x))
	var cap_raw = d.get("captured", [])
	for x in cap_raw:
		if x is Dictionary and GameData.GU.has(String(x.get("id",""))):
			player.captured.append({
				"id": String(x.get("id", "moon_blade")),
				"rank": int(x.get("rank", 1)),
				"quality": "normal",
				"progress":float(x.get("progress",0)),
			})
	captures = int(d.get("captures", 0))
	refined = int(d.get("refined", 0))
	quest_done = bool(d.get("quest_done", false))
	kills = int(d.get("kills", 0))
	var inv := get_node_or_null("/root/Inv")
	if inv != null:
		inv.items = d.get("inventory", {})
	var disc_raw = d.get("discovered", [])
	for x in disc_raw:
		player.discovered.append(String(x))
	npc_quest_state = int(d.get("npc_quest", 0))
	if npc != null:
		npc.quest_state = npc_quest_state
	player.hp = clampf(float(d.get("hp",player.max_hp)),1,player.max_hp)
	# 真元由 aperture 字段恢复，不能用旧 yuan 总量覆盖精炼层。
	player.body.load_data(d.get("body",{}))
	var gus := get_node_or_null("/root/Gus")
	var hunger := get_node_or_null("/root/Hunger")
	if gus != null:
		hunger.gu_data.clear()
		gus.load_data(d.get("gus",[]))
	_sync_owned_gus()
	if hunger != null and d.has("hunger"): hunger.load_data(d.hunger)
	player.skill_slots.assign(["","",""])
	var slots: Array=d.get("skill_slots",[])
	for i in mini(3,slots.size()):
		player.skill_slots[i]=String(slots[i])
		if equipped_gu(i)==null: player.skill_slots[i]=""
	player.vital_gu_id=String(d.get("vital_gu_id",""))
	var mark = d.get("waypoint",[0,0])
	if mark is Array and mark.size()==2: waypoint=Vector2(float(mark[0]),float(mark[1]))
	waypoint_name=String(d.get("waypoint_name",""))
	world.destruction.load_data(d.get("world_damage",{}))
	fog.load_data(d.get("explored",[]),int(d.get("map_width",80)))
	visited_sites=d.get("visited_sites",{})
	claimed_camps=d.get("claimed_camps",{})
	commissions.load_data(d.get("commissions",{}))
	poi_cd=d.get("poi_cd",{})
	hud.minimal=bool(d.get("hud_hidden",false))
	set_camera_zoom(float(d.get("camera_zoom",1.0)))
	var npcs: Dictionary=d.get("npcs",{})
	npc.load_data(npcs.get("aqing",{}))
	for id in residents: residents[id].load_data(npcs.get(id,{}))
	if world.in_interior: exit_house(false)
	var saved_pos: Array=d.get("position",[512,1040])
	var resume:=Vector2(float(saved_pos[0]),float(saved_pos[1])) if saved_pos.size()==2 else Vector2(512,1040)
	var house_id:=String(d.get("house_id",""))
	if house_id!="":
		for house in World.HOUSE_DATA:
			if house.id!=house_id: continue
			player.position=world.safe_outdoor_position(house.pos+Vector2(0,50))
			if not world.destruction.broken("house:"+house_id):
				enter_house(house)
				if HouseInterior.BOUNDS.has_point(resume-HouseInterior.ORIGIN) and not world.collides(resume.x,resume.y,12): player.position=resume
			break
	else: player.position=world.safe_outdoor_position(resume)



func add_log(text: String, color: Color) -> void:
	logs.append({"text": text, "color": color, "time":Time.get_ticks_msec()})
	while logs.size() > 8:
		logs.pop_front()


func toggle_pause(force = null) -> void:
	if not running or player.dead:
		return
	if force == null:
		paused = not paused
	else:
		paused = bool(force)
	pause_layer.visible = paused


func _use_bandage() -> void:
	var id := body_ui.selected_part if body_ui != null and body_ui.visible else ""
	if id == "":
		id = "neck" if player.body.neck_timer >= 0.0 else "torso"
		for part in player.body.parts:
			if player.body.part_bleed_rate(part)>player.body.part_bleed_rate(id): id=part
	treat_part(id)


func treat_part(id: String) -> bool:
	if not player.body.parts.has(id): return false
	var b := player.body
	var p: Dictionary = b.parts[id]
	if (float(p.hp)>=float(p.max_hp) or bool(p.destroyed)) and b.part_bleed_rate(id)<=0 and not (id=="neck" and b.neck_timer>=0):
		_action_message("此部位无需包扎。毁损部位需要有明确再生能力的蛊术。")
		return false
	var inv := get_node_or_null("/root/Inv")
	if inv.has_item("bandage"):
		inv.remove_item("bandage",1)
	else:
		_action_message("需要一份绷带，可在古月药堂或商铺购买。")
		return false
	b.stop_bleed(id)
	b.heal_part(id,12)
	_action_message("已处理%s：止血，恢复可修复的部位耐久。" % p.name)
	save_game()
	return true


func _action_message(message: String) -> void:
	last_action_message=message
	add_log(message,UIStyle.JADE)


func _sync_owned_gus() -> void:
	var gus := get_node_or_null("/root/Gus")
	if gus == null: return
	var ordered: Array[GuVirtual] = []
	for id in player.owned:
		var found: GuVirtual = null
		for gu in gus.owned_gus:
			if gu.template_id==id and not ordered.has(gu):
				found=gu
				break
		if found == null:
			found=gus.add_gu(id)
		if found != null: ordered.append(found)
	for gu in gus.owned_gus:
		if not ordered.has(gu): get_node("/root/Hunger").unregister_gu(gu.id)
	gus.owned_gus=ordered
	if not ordered.is_empty():
		gus.set_active_gu(ordered[0])
		for i in mini(3,ordered.size()):
			if player.skill_slots[i]=="" and ordered[i].location!="bag" and not ordered[i].dead: player.skill_slots[i]=ordered[i].id
	else: gus.active_gu=null


func _try_house_interact() -> bool:
	if world.in_interior:
		var action := world.interior.interaction_at(player.position)
		match action:
			"exit": exit_house()
			"rest": rest_at_bed()
			"storage": open_journal("inventory")
			"flower_cave": _claim_cave_gu()
			"spring_cave": _action_message("地下灵泉提供家族元石资源，月兰花田供蛊虫食材。这里不是免费恢复站。")
			"bai","xiong","ancestral": village_ui.show_service(action)
			"clinic","shop","archive","home":
				if service_available(action): village_ui.show_service(action)
				else: _action_message("这里的住民已死亡或与你敌对，无法提供服务。")
		return action!=""
	var h := world.house_at(player.position)
	if h.is_empty(): return false
	enter_house(h)
	return true


func enter_house(h: Dictionary) -> void:
	if world.in_interior or world.destruction.broken("house:"+String(h.id)): return
	stop_meditation("")
	outdoor_return=h.pos+Vector2(0,50)
	current_house_id=h.id
	current_house_name=h.name
	world.in_interior=true
	world.visible=false
	world.props.visible=false
	enemies_root.visible=false
	npc.visible=false
	for id in residents: residents[id].visible=id==current_house_id
	projectiles.clear()
	pending_melee.clear()
	target_hint=null
	player.capture_target=null
	player.capture_progress=0
	if world.interior == null:
		world.interior=HouseInterior.new()
		world.interior.game=self
		add_child(world.interior)
	world.interior.house_id=h.id
	world.interior.house_name=h.name
	world.interior.visible=true
	world.interior.queue_redraw()
	player.position=HouseInterior.ORIGIN+Vector2(0,135)
	camera.limit_left=int(HouseInterior.ORIGIN.x)-1100
	camera.limit_right=int(HouseInterior.ORIGIN.x)+1100
	camera.limit_top=int(HouseInterior.ORIGIN.y)-1000
	camera.limit_bottom=int(HouseInterior.ORIGIN.y)+1000
	_update_camera(0)
	camera.reset_smoothing()
	zone_banner_text=h.name
	zone_banner_time=2.0
	_action_message("进入%s。走近人物或家具按 E 交互。" % h.name)


func exit_house(should_save: bool = true) -> void:
	if not world.in_interior: return
	world.in_interior=false
	world.visible=true
	world.props.visible=true
	enemies_root.visible=true
	npc.visible=true
	for person in residents.values(): person.visible=false
	world.interior.visible=false
	projectiles.clear()
	pending_melee.clear()
	fx.hazards.clear()
	stop_meditation("")
	player.position=outdoor_return
	current_house_id=""
	current_house_name=""
	camera.limit_left=0
	camera.limit_top=0
	camera.limit_right=GameData.MAP_W*TILE
	camera.limit_bottom=GameData.MAP_H*TILE
	_update_camera(0)
	camera.reset_smoothing()
	if should_save: save_game()
	_action_message("回到青茅山。")


func buy_supply(id: String, cost: int) -> bool:
	if not world.in_interior or current_house_id not in ["shop","clinic"] or not service_available(current_house_id): return false
	if player.crystals<cost:
		_action_message("元石不足，还需要 %d 元石。" % (cost-player.crystals))
		return false
	player.crystals-=cost
	var inv := get_node_or_null("/root/Inv")
	inv.add_item(id,1)
	_action_message("购得%s ×1，花费 %d 元石。" % [inv.get_item_name(id),cost])
	save_game()
	return true


func buy_jade_gu() -> bool:
	if current_house_id!="shop" or not service_available("shop") or not world.in_interior: return false
	if jade_gu_purchased:
		_action_message("玉皮蛊已经售出。")
		return false
	if player.crystals<500:
		_action_message("这只玉皮蛊售价五百元石，钱袋不足。")
		return false
	player.crystals-=500
	jade_gu_purchased=true
	player.captured.append({"id":"jade_skin","rank":1,"quality":"normal","progress":0.0})
	if not player.discovered.has("jade_skin"): player.discovered.append("jade_skin")
	_action_message("玉皮蛊已放入外部行囊，尚未炼化。")
	save_game()
	return true


func sell_supply(id: String) -> bool:
	if current_house_id!="shop" or not world.in_interior or not service_available("shop"): return false
	var price:int=Inventory.SELL_PRICES.get(id,0)
	var inv:Inventory=get_node("/root/Inv")
	if price<=0 or not inv.remove_item(id,1): return false
	player.crystals+=price
	_action_message("售出%s ×1，得到 %d 元石。" % [inv.get_item_name(id),price])
	save_game()
	return true


func clinic_heal() -> bool:
	if current_house_id!="clinic" or not service_available("clinic"): return false
	var b:=player.body
	if b.total_bleed_rate()<=0:
		_action_message("普通医者只能包扎止血。没有已接入的再生蛊术，不能修复断肢、毁眼。")
		return false
	if player.crystals<2:
		_action_message("包扎需要两块元石。")
		return false
	player.crystals-=2
	b.stop_bleed()
	_action_message("伤口已经包扎止血；缺失部位没有再生。")
	save_game()
	return true


func rest_at_bed() -> void:
	_action_message("床榻供休息。真元按资质自然恢复；J 可温养窍壁，休息不会瞬间治愈。")


func do_dash() -> void:
	stop_meditation("疾步打断打坐。")
	if player.dash_cd > 0.0 or player.dead:
		return
	if player.body != null and not player.body.can_dash():
		add_log("腿部伤势太重，无法疾步。", Color("#d9534f"))
		return
	player.dash_cd = 2.4
	player.dash_t = 0.13
	# 普通疾跑不提供无敌。
	fx.burst(player.position.x, player.position.y, Color("#cfd8cf"), 8, 100.0, 0.3)


# ------------------------------------------------------------------ 自测钩子

func _probe() -> void:
	start_game()
	await get_tree().create_timer(1.0).timeout
	print("PROBE running=%s enemies=%d hp=%.0f crystals=%d owned=%s" % [
		str(running), enemies.size(), player.hp, player.crystals, str(player.owned)
	])

	var zone_info := []
	for z in ["forest", "marsh", "ruin", "rock"]:
		zone_info.append("%s=%d" % [z, _zone_pool(z, 5).size()])
	print("PROBE zones %s" % str(zone_info))
	for ui in [character_ui, inventory_ui, settings_ui, minimap_ui, compendium_ui, body_ui]:
		ui.visible = true
	await get_tree().create_timer(0.2).timeout
	print("PROBE ui_visible=%s" % str([character_ui.visible, inventory_ui.visible, settings_ui.visible, minimap_ui.visible]))
	for ui in [character_ui, inventory_ui, settings_ui, minimap_ui, compendium_ui]:
		ui.visible = false

	var e := spawn_enemy("green_snake", player.position + Vector2(60, 0))
	e.hp = e.max_hp * 0.1
	_capture_success(e)
	print("PROBE capture captured=%d captures=%d" % [player.captured.size(), captures])

	player.crystals = 500
	var need := _refine_duration(1)
	_refine_at(0)
	await get_tree().create_timer(need + 0.3).timeout
	close_refine()
	print("PROBE refine owned=%s refined=%d crystals=%d" % [str(player.owned), refined, player.crystals])

	player.cast_cds = [0.0, 0.0, 0.0]
	player.yuan = 200.0
	cast_skill(0)
	print("PROBE cast cd=%.1f projectiles=%d" % [player.cast_cds[0], projectiles.size()])

	player.owned = ["ding_chen"]
	player.cast_cds = [0.0, 0.0, 0.0]
	player.yuan = 200.0
	cast_skill(0)
	print("PROBE buff time=%.1f atk_bonus=%.1f" % [player.buff_time, player.atk_bonus])

	damage_player(9999.0)
	print("PROBE death dead=%s panel=%s" % [str(player.dead), str(death_layer.visible)])
	respawn()
	print("PROBE respawn dead=%s hp=%.0f" % [str(player.dead), player.hp])
	get_tree().quit()


func _bagtest() -> void:
	start_game()
	await get_tree().process_frame
	var inv := get_node_or_null("/root/Inv")
	inv.add_item("poison_sac", 2)
	inv.add_item("demon_bone", 1)
	print("BAGTEST items=%s" % str(inv.items))
	print("BAGTEST names=%s" % str([
		inv.get_item_name("grain_normal"),
		inv.get_item_name("poison_sac"),
		inv.get_item_name("demon_bone"),
	]))
	open_journal("inventory")
	inventory_ui.refresh_inventory()
	await get_tree().process_frame
	print("BAGTEST slots=%d visible=%s" % [inventory_ui.slots.size(), str(inventory_ui.visible)])
	inventory_ui._use_item("grain_normal")
	print("BAGTEST use_no_gu status=%s count=%d" % [
		inventory_ui.status_label.text, inv.get_item_count("grain_normal")
	])
	save_game()
	inv.items.clear()
	_load_save()
	print("BAGTEST reload items=%s" % str(inv.items))
	inventory_ui.visible = false
	get_tree().quit()


func _bench() -> void:
	start_game()
	await get_tree().create_timer(1.0).timeout
	player.hp = 99999.0
	player.max_hp = 99999.0
	player.yuan = 9999.0
	player.owned = ["leiwen", "moon_blade", "green_snake"]
	for i in 10:
		var a := TAU * float(i) / 10.0
		var pos := player.position + Vector2(cos(a), sin(a)) * float(120 + i * 14)
		var host := _make_host("rabbit" if i % 2 == 0 else "wolf", pos)
		if host != null:
			_assign_host_gu(host)
			enemies_root.add_child(host)
			enemies.append(host)
	var samples: Array = []
	var frame_ms: Array = []
	var start_ms := Time.get_ticks_msec()
	var frame := 0
	var last_us := Time.get_ticks_usec()
	while Time.get_ticks_msec() - start_ms < 8000:
		await get_tree().process_frame
		var now_us := Time.get_ticks_usec()
		frame_ms.append((now_us - last_us) / 1000.0)
		last_us = now_us
		frame += 1
		samples.append(Engine.get_frames_per_second())
		if frame % 12 == 0:
			basic_attack()
		if frame % 45 == 0:
			player.cast_cds = [0.0, 0.0, 0.0]
			player.yuan = 9999.0
			cast_skill(frame % 3)
		if frame % 10 == 0:
			fx.burst(player.position.x + randf_range(-200, 200), player.position.y + randf_range(-150, 150), Color("#d9c46a"), 8, 120.0, 0.4)
			fx.ring(player.position.x, player.position.y, Color("#4aa3df"), 4.0, 80.0, 0.3)
	var mn := 999
	var total := 0
	for s in samples:
		mn = mini(mn, int(s))
		total += int(s)
	var avg := int(total / maxi(1, samples.size()))
	var worst := frame_ms.duplicate()
	worst.sort()
	var p95: float = worst[int(worst.size() * 0.95)] if worst.size() > 0 else 0.0
	print("BENCH frames=%d fps_min=%d fps_avg=%d p95_frame_ms=%.1f max_frame_ms=%.1f enemies=%d draws=%d" % [
		samples.size(), mn, avg, p95, worst[worst.size() - 1] if worst.size() > 0 else 0.0,
		enemies.size(), int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
	])
	get_tree().quit()


func _perftest() -> void:
	start_game()
	for i in 5:
		await get_tree().create_timer(1.0).timeout
		print("PERF fps=%d draws=%d objects=%d nodes=%d" % [
			Engine.get_frames_per_second(),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			int(Performance.get_monitor(Performance.OBJECT_COUNT)),
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		])
	get_tree().quit()


func _poitest() -> void:
	start_game()
	await get_tree().process_frame
	var garden: Vector2i = Vector2i(58, 44)
	player.position = Vector2(garden.x, garden.y) * TILE
	_try_poi_interact()
	var inv := get_node_or_null("/root/Inv")
	print("POITEST garden items=%s" % str(inv.items))
	_try_poi_interact()
	print("POITEST cooldown=%s" % str(poi_cd))
	var pond: Vector2i = Vector2i(31, 15)
	player.position = Vector2(pond.x, pond.y) * TILE
	_try_poi_interact()
	print("POITEST pond yuan=%.0f" % player.yuan)
	var ruin: Vector2i = Vector2i(67, 13)
	player.position = Vector2(ruin.x, ruin.y) * TILE
	_try_poi_interact()
	print("POITEST ruin items=%s" % str(inv.items))
	get_tree().quit()


func _hosttest() -> void:
	start_game()
	await get_tree().process_frame
	var host: Enemy = null
	for e in enemies:
		if e.is_animal and not e.carried_gu.is_empty():
			host = e
			break
	if host == null:
		print("HOSTTEST none")
		get_tree().quit()
		return
	print("HOSTTEST host=%s hp=%.0f atk=%.0f gu=%s" % [
		host.display_name, host.max_hp, host.atk, str(host.carried_gu)
	])
	player.position = host.position + Vector2(34, 0)
	host.carried_gu = ["moon_blade"]
	var sk: Dictionary = GameData.GU["moon_blade"]["skill"]
	var proj_before: int = projectiles.size()
	_host_cast_gu(host)
	print("HOSTTEST cast kind=%s projectiles=%d" % [
		sk["kind"], projectiles.size() - proj_before
	])
	host.hp = host.max_hp * 0.2
	var captured_before := player.captured.size()
	for i in 12:
		try_capture(1.3)
	print("HOSTTEST captured=%d host_gu_left=%d" % [
		player.captured.size() - captured_before, host.carried_gu.size()
	])
	host.hp = 1.0
	var enemies_before := enemies.size()
	kill_enemy(host)
	print("HOSTTEST released enemies=%d" % (enemies.size() - enemies_before + 1))

	var h2 := _make_host("bear", player.position + Vector2(120, 0))
	if h2 != null:
		_assign_host_gu(h2)
		enemies_root.add_child(h2)
		enemies.append(h2)
		var carried := h2.carried_gu.size()
		h2.hp = 1.0
		var before2 := enemies.size()
		kill_enemy(h2)
		print("HOSTTEST release carried=%d new_enemies=%d" % [
			carried, enemies.size() - before2 + 1
		])
	get_tree().quit()


func _animaltest() -> void:
	start_game()
	await get_tree().process_frame
	var animal: Enemy = null
	for e in enemies:
		if e.is_animal:
			animal = e
			break
	if animal == null:
		print("ANIMALTEST none")
		get_tree().quit()
		return
	print("ANIMALTEST name=%s hp=%.0f atk=%.0f kind=%s" % [
		animal.display_name, animal.max_hp, animal.atk, animal.kind
	])
	var inv := get_node_or_null("/root/Inv")
	kill_enemy(animal)
	print("ANIMALTEST killed items=%s" % str(inv.items))
	get_tree().quit()


func _take_shot_refine() -> void:
	start_game()
	player.captured.append({"id":"jiu_chong","rank":1,"quality":"normal","progress":0.0})
	player.captured.append({"id":"jade_skin","rank":1,"quality":"normal","progress":0.0})
	player.crystals = 500
	open_refine()
	_refine_at(0)
	await get_tree().create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://shot_refine.png")
	var err := img.save_png(path)
	print("SHOTREFINE path=%s err=%d refining=%s" % [path, err, str(refining)])
	get_tree().quit()


func _take_shot_target() -> void:
	start_game()
	await get_tree().process_frame
	var host: Enemy = null
	for e in enemies:
		if e.is_animal and not e.carried_gu.is_empty():
			host = e
			break
	if host == null:
		get_tree().quit()
		return
	player.position = host.position + Vector2(-70, 10)
	camera.position = player.position
	target_hint = host
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://shot_target.png")
	var err := img.save_png(path)
	print("SHOTTARGET path=%s err=%d" % [path, err])
	get_tree().quit()


func _take_shot_bag() -> void:
	start_game()
	await get_tree().process_frame
	var inv := get_node_or_null("/root/Inv")
	inv.add_item("rabbit_meat", 2)
	inv.add_item("timber", 3)
	inv.add_item("jade", 1)
	open_journal("inventory")
	inventory_ui.selected_id="capture:0"
	inventory_ui.refresh_inventory()
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://shot_bag.png")
	var err := img.save_png(path)
	print("SHOTBAG path=%s err=%d" % [path, err])
	get_tree().quit()


func _refinetest() -> void:
	start_game()
	await get_tree().process_frame
	player.captured.append({"id": "green_snake", "rank": 1, "quality": "普通"})
	player.crystals = 500
	open_refine()
	_refine_at(0)
	print("REFINETEST start refining=%s duration=%.1f owned=%d" % [
		str(refining), refine_duration, player.owned.size()
	])
	await get_tree().create_timer(refine_duration + 0.4).timeout
	var gus := get_node_or_null("/root/Gus")
	print("REFINETEST done refining=%s refined=%d owned=%s crystals=%d gus=%d" % [
		str(refining), refined, str(player.owned), player.crystals, gus.owned_gus.size()
	])
	close_refine()
	var inv := get_node_or_null("/root/Inv")
	inv.add_item("grain_normal", 2)
	var gu = gus.active_gu
	inventory_ui._use_item("grain_normal")
	print("REFINETEST feed gu=%s food_left=%d status=%s" % [
		gu.name, inv.get_item_count("grain_normal"), inventory_ui.status_label.text
	])
	print("REFINETEST close paused=%s panel=%s" % [str(paused), str(refine_layer.visible)])
	get_tree().quit()


func _bodytest() -> void:
	start_game()
	await get_tree().process_frame
	var b := BodyComponent.new()
	add_child(b)
	b.setup(1)
	print("BODYTEST parts=%d blood=%.0f pain=%.0f" % [b.parts.size(), b.blood, b.pain])

	b.reset_full()
	var r := b.apply_hit("eye_l", 20.0, "none")
	print("BODYTEST eye damage=%.1f destroyed=%s acc=%.2f" % [
		float(r["part_damage"]), str(r["destroyed"]), b.get_accuracy()
	])

	b.reset_full()
	b.apply_hit("head", 100.0, "none")
	print("BODYTEST head dead=%s" % str(b.dead))

	b.reset_full()
	b.apply_hit("leg_l", 100.0, "none")
	print("BODYTEST leg move=%.2f dash=%s" % [b.get_move_multiplier(), str(b.can_dash())])

	b.reset_full()
	b.apply_hit("neck", 100.0, "none")
	print("BODYTEST neck timer=%.1f dead=%s" % [b.neck_timer, str(b.dead)])
	b.tick(3.2)
	print("BODYTEST neck_after dead=%s" % str(b.dead))

	b.reset_full()
	b.apply_hit("hand_l", 100.0, "none")
	b.apply_hit("hand_r", 100.0, "none")
	print("BODYTEST hands can_cast=%s atkspd=%.2f" % [str(b.can_cast()), b.get_attack_speed_multiplier()])

	b.reset_full()
	b.apply_hit("mouth", 100.0, "none")
	print("BODYTEST mouth can_cast=%s" % str(b.can_cast()))

	b.reset_full()
	b.apply_hit("torso", 100.0, "none")
	print("BODYTEST torso dead=%s" % str(b.dead))

	player.body.apply_hit("neck", 100.0, "none")
	player.materials = 2
	print("BODYTEST bandage_before neck=%.1f materials=%d" % [player.body.neck_timer, player.materials])
	_use_bandage()
	print("BODYTEST bandage_after neck=%.1f materials=%d" % [player.body.neck_timer, player.materials])
	player.body.reset_full()
	player.body.apply_hit("leg_l", 100.0, "none")
	var leg_hp: float = float(player.body.parts["leg_l"]["hp"])
	player.materials = 1
	body_ui.visible = true
	body_ui.selected_part = "leg_l"
	_use_bandage()
	print("BODYTEST heal leg %.0f->%.0f materials=%d" % [
		leg_hp, float(player.body.parts["leg_l"]["hp"]), player.materials
	])
	body_ui.visible = false
	print("BODYTEST player_body parts=%d move=%.2f" % [
		player.body.parts.size(), player.body.get_move_multiplier()
	])
	b.queue_free()
	get_tree().quit()


func _bosstest() -> void:
	start_game()
	await get_tree().process_frame
	print("BOSSTEST spawn name=%s hp=%.0f rank=%d boss_null=%s" % [
		boss.name, boss.max_hp, boss.rank, str(boss == null)
	])
	kill_enemy(boss)
	print("BOSSTEST kill boss_null=%s crystals=%d materials=%d" % [
		str(boss == null), player.crystals, player.materials
	])
	get_tree().quit()


func _npctest() -> void:
	start_game()
	await get_tree().process_frame
	player.position = npc.position + Vector2(12, 0)
	_open_npc_dialogue()
	print("NPCTEST open state=%d paused=%s text=%s" % [npc_quest_state, str(paused), dialogue_label.text])
	_on_dialogue_pressed()
	print("NPCTEST accept state=%d btn=%s" % [npc_quest_state, dialogue_btn.text])
	player.discovered = ["moon_blade", "green_snake", "leiwen"]
	_on_dialogue_pressed()
	print("NPCTEST claim state=%d crystals=%d text=%s" % [npc_quest_state, player.crystals, dialogue_label.text])
	_on_dialogue_pressed()
	print("NPCTEST close paused=%s visible=%s" % [str(paused), str(dialogue_layer.visible)])
	get_tree().quit()


func _skilltest() -> void:
	start_game()
	await get_tree().process_frame
	var fails := []
	for id in GameData.GU_ORDER:
		player.owned = [id]
		player.cast_cds = [0.0, 0.0, 0.0]
		player.yuan = 10000.0
		cast_skill(0)
		if player.cast_cds[0] <= 0.0:
			fails.append(id)
	print("SKILLTEST tested=%d fails=%s" % [GameData.GU_ORDER.size(), str(fails)])
	get_tree().quit()


func _take_shot_body() -> void:
	start_game()
	await get_tree().process_frame
	player.body.apply_hit("eye_l", 20.0, "fire")
	player.body.apply_hit("leg_l", 80.0, "none")
	player.body.apply_hit("hand_r", 20.0, "none")
	open_journal("body")
	body_ui.selected_part = "leg_l"
	body_ui.queue_redraw()
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://shot_body.png")
	var err := img.save_png(path)
	print("SHOTBODY path=%s err=%d" % [path, err])
	get_tree().quit()


func _take_shot_comp() -> void:
	start_game()
	player.discovered.clear()
	for id in GameData.GU_ORDER:
		player.discovered.append(id)
	compendium_ui.refresh()
	compendium_ui.visible = true
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://shot_comp.png")
	var err := img.save_png(path)
	print("SHOTCOMP path=%s err=%d" % [path, err])
	get_tree().quit()


func _take_shot() -> void:
	start_game()
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://shot_godot.png")
	var err := img.save_png(path)
	print("SHOT path=%s err=%d size=%dx%d" % [path, err, img.get_width(), img.get_height()])
	get_tree().quit()


# ------------------------------------------------------------------ 音效（程序生成，无需素材）

func _play_tone(freq: float, duration: float, volume: float = 0.18) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var key := "%d_%.3f_%.3f" % [int(freq), duration, volume]
	var stream: AudioStreamWAV = _tone_cache.get(key)
	if stream == null:
		var rate := 16000
		var count := int(rate * duration)
		var data := PackedByteArray()
		data.resize(count * 2)
		for i in count:
			var env := 1.0 - float(i) / float(count)
			var sample := sin(TAU * freq * float(i) / float(rate)) * volume * env
			data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
		stream = AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = rate
		stream.stereo = false
		stream.data = data
		_tone_cache[key] = stream
	var player: AudioStreamPlayer = null
	for p in _sfx_pool:
		if not p.playing:
			player = p
			break
	if player == null:
		if _sfx_pool.size() >= 10:
			return
		player = AudioStreamPlayer.new()
		add_child(player)
		_sfx_pool.append(player)
	player.stream = stream
	player.play()


func _run_polish_tests() -> void:
	var suite := GamePolishTests.new()
	await suite.run(self)


func _take_polish_shot(scenario: String) -> void:
	if scenario != "menu":
		start_game()
		player.position=Vector2(510,1060)
		player.owned.assign(["moon_blade","jiu_chong","jade_skin"])
		_sync_owned_gus()
		fog.reveal(player.position,fog.radius_world())
		_update_camera(0)
		camera.reset_smoothing()
		if scenario=="interior": enter_house(World.HOUSE_DATA[0])
		if scenario=="shop":
			enter_house(World.HOUSE_DATA[1])
			village_ui.show_service("shop")
		if scenario=="commissions":
			enter_house(World.HOUSE_DATA[1])
			get_node("/root/Inv").add_item("timber",6)
			commissions.accept("timber",self)
			village_ui.show_commissions()
		if scenario in ["camp","notes"]:
			var site:Dictionary=World.EXPLORATION_SITES[5]
			player.position=Vector2(site.pos)*32+Vector2(16,16)
			fog.reveal(player.position,fog.radius_world())
			_update_camera(0)
			camera.reset_smoothing()
			if scenario=="camp":
				player.body.apply_hit("hand_l",10)
				_try_poi_interact()
			else:
				for i in [0,1,5,8]: visited_sites[World.EXPLORATION_SITES[i].id]=true
				claimed_camps[site.id]=true
				open_journal("map")
				minimap_ui.set_mode("notes")
		if scenario in ["gujade","guliquor"]:
			player.discovered.assign(GameData.GU_ORDER)
			compendium_ui.refresh()
			compendium_ui._show_detail("jade_skin" if scenario=="gujade" else "jiu_chong")
			compendium_ui.show()
			paused=true
		if scenario=="journal":
			player.body.apply_hit("leg_l",30)
			player.body.apply_hit("eye_l",20)
			open_journal("body")
			body_ui.select_part("leg_l")
		if scenario=="map": open_journal("map")
		if scenario=="atlasfull":
			fog.reveal(Vector2(GameData.MAP_W,GameData.MAP_H)*16,10000)
			open_journal("map")
		if scenario=="exploration":
			player.position=Vector2(World.EXPLORATION_SITES[5].pos)*32+Vector2(16,70)
			_update_camera(0)
			camera.reset_smoothing()
			fog.reveal(player.position,fog.radius_world())
			paused=true
		if scenario=="minimal":
			hud.minimal=true
			paused=true
		if scenario=="character": open_journal("character")
		if scenario=="elements": open_journal("elements")
		if scenario=="aperture":
			player.aperture.essence=24
			player.aperture.refined_essence=5
			player.aperture.wall_progress=36
			open_journal("aperture")
		if scenario=="worldmap":
			open_journal("map")
			minimap_ui.show_world()
		if scenario=="fog":
			player.body.apply_hit("eye_l",100)
			paused=true
		if scenario=="meditation":
			enter_house(World.HOUSE_DATA[2])
			toggle_meditation()
			_update_meditation(15)
			paused=true
		if scenario=="destruction":
			strike_world(World.HOUSE_DATA[2].pos+Vector2(0,-20),2,9999,"earth",Vector2.ZERO,-1,false)
			paused=true
		if scenario=="reaction": open_journal("elements")
		if scenario=="waterfall":
			player.position=Vector2(1094,390)
			_update_camera(0)
			camera.reset_smoothing()
			fog.reveal(player.position,fog.radius_world())
			paused=true
		if scenario=="cave":
			enter_house(World.HOUSE_DATA[7])
			paused=true
		if scenario=="occlusion":
			player.position=World.HOUSE_DATA[2].pos+Vector2(0,-100)
			_update_camera(0)
			camera.reset_smoothing()
		if scenario in ["village","interior","occlusion"]: paused=true
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://shot_%s.png" % scenario)
	var err := img.save_png(path)
	print("POLISHSHOT scenario=%s err=%d path=%s" % [scenario,err,path])
	get_tree().quit(0 if err==OK else 1)

func set_camera_zoom(value: float) -> void:
	zoom_level=clampf(value,0.65,1.75)
	camera.zoom=Vector2.ONE*zoom_level

func destruction_power() -> float:
	return 1.0 # 破坏由实际攻击与材料硬度结算；升转不会凭空强化肉身。


func active_npcs() -> Array:
	if world.in_interior:
		return [residents[current_house_id]] if residents.has(current_house_id) else []
	return [npc]

func service_available(id: String) -> bool:
	if id=="home": return not world.destruction.broken("house:home")
	return residents.has(id) and not residents[id].dead and not residents[id].hostile and not world.destruction.broken("house:"+id)

func npc_save_data() -> Dictionary:
	var data := {"aqing":npc.save_data()}
	for id in residents: data[id]=residents[id].save_data()
	return data

func strike_world(center: Vector2, radius: float, damage: float, element: String, direction: Vector2 = Vector2.ZERO, cone: float = -1.0, include_people: bool = true) -> Array:
	var hits := world.destruction.hit_area(center,radius,damage,destruction_power(),current_house_id if world.in_interior else "",direction,cone)
	for hit in hits:
		fx.burst(hit.pos.x,hit.pos.y,Color("b4a27a"),5,70,0.3)
		fx.text(hit.pos.x,hit.pos.y-25,"破坏 -%.0f / 耐久 %.0f"%[hit.damage,hit.hp],UIStyle.GOLD,11)
		if hit.destroyed:
			var item := "timber" if hit.kind in ["tree","bamboo","house","furniture","bonfire"] else "rubble"
			var inv:Inventory=get_node("/root/Inv")
			inv.add_item(item,1)
			_action_message("物体已破坏，%s ×1 已放入背包。" % inv.get_item_name(item))
	if include_people:
		for person in active_npcs():
			if person.dead: continue
			var offset: Vector2=person.position-center
			if offset.length()<=radius+person.radius and (direction==Vector2.ZERO or offset.normalized().dot(direction)>=cone):
				person.take_damage(damage,self,element)
	if not hits.is_empty(): save_game()
	return hits

func toggle_meditation() -> void:
	if meditating:
		stop_meditation("收功，窍壁温养进度已保存。")
		save_game()
		return
	if not can_meditate():
		_action_message("需远离敌人、停止受击并处理出血或中毒后才能打坐。")
		return
	meditating=true
	meditation_seconds=0.0
	player.capture_target=null
	player.capture_progress=0.0
	_action_message("开始打坐。J 收功；移动、攻击或受伤会中断。")

func can_meditate() -> bool:
	if player.dead or player.body.unconscious or player.body.total_bleed_rate()>0 or player.body.recovery_delay>0:
		return false
	if float(player.status.get("burn",0))>0 or float(player.status.get("poison",0))>0: return false
	if not world.in_interior:
		for enemy in enemies:
			if not enemy.dead and enemy.position.distance_to(player.position)<260: return false
	for person in active_npcs():
		if person.hostile and not person.dead and person.position.distance_to(player.position)<260: return false
	return true

func meditation_rate() -> float:
	return 0.6 if player.yuan>0 else 0.0


func _update_meditation(delta: float) -> void:
	if not meditating or paused: return
	if not can_meditate():
		stop_meditation("无法继续集中精神，打坐中断。")
		return
	meditation_seconds+=delta
	player.aperture.cultivate(delta)
	if player.aperture.wall_progress>=100:
		stop_meditation("窍壁温养完成，请在 Q 空窍页冲关。")


func stop_meditation(message: String) -> void:
	if not meditating: return
	meditating=false
	if message!="": _action_message(message)

func record_reaction(_title: String) -> void:
	pass # 旧公式已退役，不能向 HUD 注入虚构反应。


func _update_reaction_events(delta: float) -> void:
	for i in range(reaction_events.size()-1,-1,-1):
		reaction_events[i].time-=delta
		if reaction_events[i].time<=0: reaction_events.remove_at(i)

func _update_hazards(delta: float) -> void:
	for hazard in fx.hazards:
		hazard["tick"]=float(hazard.get("tick",0))+delta
		if hazard.tick<0.5: continue
		hazard.tick-=0.5
		for enemy in enemies.duplicate():
			if not enemy.dead and enemy.position.distance_to(hazard.pos)<float(hazard.r):
				damage_enemy(enemy,float(hazard.dps)*0.5,String(hazard.element))
		for person in active_npcs():
			if not person.dead and person.position.distance_to(hazard.pos)<float(hazard.r):
				person.take_damage(float(hazard.dps)*0.5,self,String(hazard.element))

func _run_feature_tests() -> void:
	var suite := GameFeatureTests.new()
	await suite.run(self)

func equipped_gu(slot: int) -> GuVirtual:
	if slot<0 or slot>=3: return null
	var gu: GuVirtual=get_node("/root/Gus").get_gu_by_id(player.skill_slots[slot])
	if gu==null or gu.dead or gu.location=="bag": return null
	return gu

func equip_gu(id: String, slot: int) -> void:
	var gu: GuVirtual=get_node("/root/Gus").get_gu_by_id(id)
	if gu==null or gu.dead or gu.location=="bag" or slot<0 or slot>=3:
		_action_message("请选择空窍或身体内的一只存活蛊虫，再绑定快捷位。")
		return
	for i in 3:
		if player.skill_slots[i]==id: player.skill_slots[i]=""
	player.skill_slots[slot]=id
	player.cast_cds[slot]=maxf(player.cast_cds[slot],0.8)
	save_game()

func move_gu(id: String, location: String) -> bool:
	var gu: GuVirtual=get_node("/root/Gus").get_gu_by_id(id)
	if gu==null or gu.dead or location not in ["bag","aperture","body"]: return false
	if location=="body" and gu.template_id!="moon_blade":
		_action_message("这只蛊虫暂不支持寄居掌心，可收入空窍或外部携带。")
		return false
	gu.location=location
	if location=="bag":
		for i in 3:
			if player.skill_slots[i]==id: player.skill_slots[i]=""
		if gu.template_id=="jade_skin": player.jade_guard=false
	save_game()
	return true

func absorb_primeval_stone() -> void:
	var a:=player.aperture
	if player.crystals<=0 or a.stone_reserve>0 or a.total()>=a.capacity:
		_action_message("无需吸收，或元石不足；已有元石余量时先继续吸收。")
		return
	player.crystals-=1
	a.stone_reserve=100.0 # 每块储量为模拟参数，不作为原文固定数值。
	_action_message("开始吸收元石，逐步补充真元。")
	save_game()

func attempt_breakthrough() -> void:
	_action_message(player.aperture.breakthrough())
	save_game()
	aperture_ui.refresh()

func _update_owned_gu(delta: float) -> void:
	var hunger:=get_node("/root/Hunger")
	hunger.update(delta)
	for gu in get_node("/root/Gus").owned_gus:
		if not gu.dead and hunger.gu_data.has(gu.id) and hunger.gu_data[gu.id].dead:
			gu.dead=true
			for i in 3:
				if player.skill_slots[i]==gu.id: player.skill_slots[i]=""
			if gu.id==player.vital_gu_id:
				player.hp=maxf(1,player.hp-player.max_hp*0.5)
				player.body.consciousness=maxf(1,player.body.consciousness-40)
				_action_message("本命蛊饿死，你遭受重创。")
	if player.jade_guard:
		var valid:=false
		for gu in get_node("/root/Gus").owned_gus:
			if gu.template_id=="jade_skin" and not gu.dead and gu.location!="bag": valid=true
		if not valid or not player.aperture.spend(1.0*delta): player.jade_guard=false
	for c in player.captured:
		if refining and refine_target>=0 and refine_target<player.captured.size() and is_same(c,player.captured[refine_target]): continue
		c["progress"]=maxf(0,float(c.get("progress",0))-delta*0.12)

func _run_canon_tests() -> void:
	var test:=CanonTests.new()
	await test.run(self)

func _claim_cave_gu() -> void:
	if current_house_id!="flower_cave": return
	if cave_gu_claimed:
		_action_message("遗藏中的酒虫已经取走，不会再次出现。")
	elif get_node("/root/Inv").remove_item("bamboo_wine",1):
		cave_gu_claimed=true
		player.captured.append({"id":"jiu_chong","rank":1,"quality":"normal","progress":0.0})
		if not player.discovered.has("jiu_chong"): player.discovered.append("jiu_chong")
		_action_message("以青竹酒诱来酒虫，趁其醉后收起。它仍在外部行囊中，尚未炼化。")
		save_game()
	else: _action_message("先准备一坛青竹酒，才能引出酒虫。")

func claim_camp_supplies(id: String) -> bool:
	var site:=world.exploration_at(player.position)
	if world.in_interior or site.is_empty() or site.id!=id or site.kind!="camp":
		_action_message("需在营地附近领取补给。")
		return false
	if claimed_camps.has(id):
		_action_message("这里的补给已经取空。")
		return false
	claimed_camps[id]=true
	get_node("/root/Inv").add_item("bandage",2)
	get_node("/root/Inv").add_item("bamboo_wine",1)
	_action_message("获得绷带 ×2、青竹酒 ×1，已放入背包。")
	world.queue_redraw()
	save_game()
	return true

func field_bandage() -> bool:
	var site:=world.exploration_at(player.position)
	if world.in_interior or site.is_empty() or site.kind!="camp": return false
	var chosen:=""
	var urgency:=-1.0
	for id in player.body.parts:
		var part:Dictionary=player.body.parts[id]
		var bleed:float=player.body.part_bleed_rate(id)
		if (part.destroyed or part.hp>=part.max_hp) and bleed<=0: continue
		var score:float=bleed*100.0+(1.0-float(part.hp)/float(part.max_hp))
		if score>urgency:
			urgency=score
			chosen=id
	if chosen=="":
		_action_message("当前没有需要包扎的伤口。")
		return false
	return treat_part(chosen)
