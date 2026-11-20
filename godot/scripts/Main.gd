extends Node2D

## 青茅山 · Godot 4.3 可玩版主控。
## 初版包含：世界、玩家、敌人、弹道、元素反应、捕获、炼化、转数、存档。

var character_saves := CharacterSaves.new()
var character_id := ""
var character_name := ""
var awakening_ui: AwakeningUI
var SAVE_PATH: String:
	get: return character_saves.path_for(character_id)
var start_screen: StartScreen
var death_note: Label
var save_error_dialog: AcceptDialog
var death_persisted := false
var death_reason := "气血耗尽"
const TILE := GameData.TILE

var world: World
var shang_city: ShangCity
var player: Player
var fx: Fx
var top: TopLayer
var hud: HUD
var camera: Camera2D
var night_rect: ColorRect
var enemies_root: Node2D

var enemies: Array[Enemy] = []
var wildlife := WildlifeSystem.new()
var population := PopulationSystem.new()
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
var refine_scroll: ScrollContainer
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
var social_time := 0.0
var low_fps_timer := 0.0
var fps_cap_30 := false
var performance_testing := false
var dialogue_layer: CanvasLayer
var dialogue_label: Label
var dialogue_btn: Button
var npc_quest_state := 0

var journal: JournalUI
var village_ui: VillageUI
var npc_inspect_ui: NpcInspectUI
var npc_sight_ui: NpcSightUI
var _world_attack_held := false
var fog: FogOfWar
var residents: Dictionary = {}
var zoom_level := 1.0
var meditating := false
var meditation_seconds := 0.0
var reaction_events: Array = []
var aperture_ui: ApertureUI
var cave_gu_claimed := false
var jade_gu_purchased := false
var gu_shop_purchased := {}
var current_house_id := ""
var current_house_name := ""
var outdoor_return := Vector2.ZERO
var waypoint := Vector2.ZERO
var waypoint_name := ""
var waypoint_notified := false
var waypoint_layer := 0
var last_action_message := ""

var _rng := RandomNumberGenerator.new()
var _tone_cache := {}
var _sfx_pool: Array[AudioStreamPlayer] = []

func _run_shang_tests() -> void:
	await ShangCityTests.new().run(self)


func _ready() -> void:
	get_tree().auto_accept_quit=false
	character_saves.import_legacy()
	_rng.randomize()
	y_sort_enabled = true
	_build_world()
	_build_fx()
	_build_player()
	_build_enemies_root()
	wildlife.setup(self)
	population.setup(self)
	_build_top()
	_build_npc()
	_build_camera()
	_build_hud()
	_build_night()
	_build_fog()
	_build_ui_overlays()
	shang_city=ShangCity.new()
	shang_city.setup(self)
	world.shang=shang_city
	_build_menus()
	_update_camera(0.0)
	player.visible = false
	set_process(true)
	process_mode = Node.PROCESS_MODE_ALWAYS

	var args := OS.get_cmdline_user_args()
	if "--startup-report" in args: _report_startup_ready.call_deferred()
	if "--shangtest" in args: _run_shang_tests.call_deferred()
	if "--guupgradetest" in args: _run_gu_upgrade_tests.call_deferred()
	if "--adventuretest" in args: _run_adventure_tests.call_deferred()
	if "--awakeningtest" in args: _run_awakening_tests.call_deferred()
	if "--terraintest" in args: _run_terrain_tests.call_deferred()
	for scenario in ["blockmountain","underground","deepcave","layermap","blockimpact"]:
		if ("--shot"+scenario) in args: _take_terrain_shot.call_deferred(scenario)
	if "--populationtest" in args: _run_population_tests.call_deferred()
	for scene in ["population","caravan","bandits","caravantrade","populationmotion"]:
		if ("--shot"+scene) in args: _take_population_shot.call_deferred(scene)
	if "--inspecttest" in args: _run_inspection_tests.call_deferred()
	if "--socialtest" in args: _run_social_tests.call_deferred()
	if "--exchangetest" in args: _run_exchange_tests.call_deferred()
	for scenario in ["npcinspect","npcrelations","npcstatus","npcdead","npcitems","npcsell","npcloot"]:
		if ("--shot"+scenario) in args: _take_polish_shot.call_deferred(scenario)
	if "--arttest" in args: _run_art_tests.call_deferred()
	if "--appearancetest" in args: _run_appearance_tests.call_deferred()
	if "--canonpeopletest" in args: _run_canon_people_tests.call_deferred()
	if "--controltest" in args: _run_control_tests.call_deferred()
	if "--charactertest" in args: _run_character_tests.call_deferred()
	if "--customizetest" in args: _run_customization_tests.call_deferred()
	if "--statustest" in args: _run_status_tests.call_deferred()
	if "--guvfxtest" in args: _run_gu_vfx_tests.call_deferred()
	if "--utilitygutest" in args: _run_utility_gu_tests.call_deferred()
	if "--sixtygutest" in args: _run_sixty_gu_tests.call_deferred()
	if "--hundredgutest" in args: _run_hundred_gu_tests.call_deferred()
	if "--bodygutest" in args: _run_body_gu_tests.call_deferred()
	if "--canontest" in args:
		_run_canon_tests.call_deferred()
	if "--maptest" in args:
		_run_map_tests.call_deferred()
	if "--villagetest" in args:
		_run_village_tests.call_deferred()
	if "--wildlifetest" in args:
		_run_wildlife_tests.call_deferred()
	if "--wildlifeanimtest" in args:
		_run_wildlife_animation_tests.call_deferred()
	if "--shotwildlifemotion" in args:
		_take_wildlife_animation_preview.call_deferred()
	for scenario in ["wildlife","wildlifebeasts","wildlifefield","wildlifecultivate"]:
		if ("--shot"+scenario) in args: _take_polish_shot.call_deferred(scenario)
	for scenario in ["mapzoom","mapguide","maparrival","mapexit","mapfrontier","baivillage","xiongvillage","baidistrict","xiongdistrict","baishop","xiongclinic","villagedirections","clanspring","villagemap"]:
		if ("--shot"+scenario) in args: _take_polish_shot.call_deferred(scenario)
	if "--featuretest" in args:
		_run_feature_tests.call_deferred()
	for scenario in ["guwave2","gudefense","gucricket","guwave2shop","guwave2food","gucombat"]:
		if ("--shot"+scenario) in args: _take_polish_shot.call_deferred(scenario)
	if "--polishtest" in args:
		_run_polish_tests.call_deferred()
	for scenario in ["menu","village","interior","shop","journal","character","map","occlusion","elements","aperture","worldmap","waterfall","cave","fog","reaction","meditation","destruction","repair","damageinterior","exploration","atlasfull","minimal","commissions","camp","notes","gujade","guliquor","gulight","guwhite","gublack","gushop","gutraining"]:
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
	for item in ["currency","timber","bandage","rabbit_meat","deer_meat","wolf_meat","bear_meat","boar_meat","pheasant_meat","pork_ration"]:
		if ("--shotitem"+item) in args:
			_take_shot_bag.call_deferred(item)
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
	if "--perfscenes" in args:
		_perfscenes.call_deferred()
	if "--rendertest" in args:
		_run_render_tests.call_deferred()
	if "--bench" in args:
		_bench.call_deferred()
	if "--shot" in args:
		_take_shot.call_deferred()
	if "--shotcomp" in args:
		_take_shot_comp.call_deferred()
	if "--shotbody" in args:
		_take_shot_body.call_deferred()


func _report_startup_ready() -> void:
	await RenderingServer.frame_post_draw
	if not is_instance_valid(start_screen) or not start_screen.is_visible_in_tree():
		push_error("Character selection did not become visible during startup.")
		return
	print("GUDAO_STARTUP_READY")


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
	npc.game=self
	npc.name = "GuMasterAqing"
	npc.position = GameData.BONFIRE + Vector2(186, 104)
	add_child(npc)
	var people:Array=[["clinic","药堂医者"],["shop","商铺伙计"],["archive","学堂执事"]]
	for house in SettlementData.HALLS+SettlementData.HOUSES:
		if house.resident!="": people.append([house.id,house.resident])
	for data in people:
		var person := Npc.new()
		person.game=self
		person.resident_id=data[0]
		person.npc_name=data[1]
		person.position=HouseInterior.ORIGIN+Vector2(180,-160)
		person.visible=false
		add_child(person)
		residents[data[0]]=person
	for data in SettlementData.PEOPLE:
		var person:=Npc.new()
		person.game=self
		person.resident_id=data.id
		person.npc_name=data.name
		person.outdoors=true
		person.settlement_id=data.clan
		person.position=data.pos
		add_child(person)
		residents[data.id]=person


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
	npc_sight_ui=NpcSightUI.new()
	npc_sight_ui.game=self
	ui_layer.add_child(npc_sight_ui)
	journal = JournalUI.new()
	journal.game = self
	ui_layer.add_child(journal)
	settings_ui = _make_settings_ui()
	settings_ui.visible = false
	settings_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var settings_layer:=CanvasLayer.new()
	settings_layer.layer=20
	add_child(settings_layer)
	settings_layer.add_child(settings_ui)
	compendium_ui = CompendiumUI.new()
	compendium_ui.visible = false
	compendium_ui.player = player
	compendium_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(compendium_ui)
	village_ui = VillageUI.new()
	village_ui.game = self
	ui_layer.add_child(village_ui)
	npc_inspect_ui = NpcInspectUI.new()
	npc_inspect_ui.game = self
	ui_layer.add_child(npc_inspect_ui)
	awakening_ui=AwakeningUI.new()
	awakening_ui.game=self
	ui_layer.add_child(awakening_ui)


func open_journal(page: String) -> void:
	if not running or player.dead: return
	if shang_city!=null and shang_city.active and page=="map":
		shang_city.ui.open("travel")
		return
	if shang_city!=null and shang_city.ui.visible: shang_city.ui.close()
	if awakening_ui!=null and awakening_ui.visible: return
	settings_ui.close()
	compendium_ui.visible = false
	journal.open_page(page)


func _toggle_ui(which: Control) -> void:
	if which==settings_ui:
		if settings_ui.visible: settings_ui.close()
		else: open_settings()
		return
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
	ui.game=self
	return ui


func open_settings() -> void:
	settings_ui.open()


func _build_menus() -> void:
	# Start menu uses the actual village as its backdrop.
	start_layer = CanvasLayer.new()
	start_layer.layer = 5
	add_child(start_layer)
	start_screen = StartScreen.new()
	start_screen.game = self
	start_layer.add_child(start_screen)
	start_btn = start_screen.start_button
	save_error_dialog=AcceptDialog.new()
	save_error_dialog.title="存档未能写入"
	save_error_dialog.dialog_autowrap=true
	add_child(save_error_dialog)

	# 炼化
	refine_layer = _menu_layer(6)
	refine_layer.visible = false
	var rv: VBoxContainer = refine_layer.get_meta("vbox")
	var rt := _label("炼化 · 以真元磨去蛊虫意志", 24, Color("#d9c46a"))
	rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(rt)
	refine_list = VBoxContainer.new()
	refine_list.add_theme_constant_override("separation", 8)
	refine_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	refine_scroll=ScrollContainer.new()
	refine_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	refine_scroll.custom_minimum_size.y=60
	rv.add_child(refine_scroll)
	refine_scroll.add_child(refine_list)
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
	death_note=_label("角色已永久陨落，不能继续读取。\n可返回角色列表查看记录、删除或新建角色。", 15, Color("#d8e6d2"))
	dv.add_child(death_note)
	var respawn_btn := Button.new()
	respawn_btn.text = "返回角色选择"
	respawn_btn.name = "ReturnCharacters"
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
	var settings_button:=UIStyle.button("设置",open_settings)
	settings_button.name="SettingsButton"
	settings_button.custom_minimum_size.y=40
	pv.add_child(settings_button)
	var reset := Button.new()
	reset.text = "保存并返回角色选择"
	reset.name = "ReturnCharacters"
	reset.custom_minimum_size = Vector2(0, 40)
	reset.pressed.connect(return_to_characters)
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

func start_game(id: String = "") -> void:
	if started:
		return
	if id.is_empty():
		id=start_screen.selected_id
		# No-argument starts are used by isolated development/test entries.
		if id.is_empty() and character_saves.entries().is_empty(): id=character_saves.create_character("青茅游子")
	var data:=character_saves.load_character(id)
	if data.is_empty():
		start_screen.note.text=character_saves.last_error
		start_screen.refresh()
		return
	character_id=id
	character_name=str(data.get("profile",{}).get("name","旧角色"))
	character_saves.remember_selection(id)
	if not _load_save(data): return
	started = true
	running = true
	paused = false
	start_layer.visible = false
	player.visible = true
	_sync_owned_gus()
	_spawn_initial_enemies()
	population.initialize()
	if shang_city.active: population.set_visible(false)
	camera.position = player.position
	last_zone = world.zone_at(player.position)
	zone_banner_text = world.zone_name(last_zone)
	zone_banner_time = 2.4
	add_log("青茅山。风里有瘴气，也有蛊。", Color("#d9c46a"))
	add_log("I 查看外部物品；Q 内视空窍；R 炼化；J 温养窍壁。" if player.aperture.is_open() else "你尚是凡人。按 Q 查看开窍指引，前往地下溶洞花海寻找希望蛊。", Color("#8fa38a"))
	save_game()


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


func _run_wildlife_tests() -> void:
	var suite:=WildlifeTests.new()
	await suite.run(self)

func _run_wildlife_animation_tests() -> void:
	var suite:=WildlifeAnimationTests.new()
	await suite.run(self)

func _run_population_tests() -> void:
	await PopulationTests.new().run(self)

func _run_appearance_tests() -> void:
	await NpcAppearanceTests.new().run(self)

func _run_canon_people_tests() -> void:
	await CanonPeopleTests.new().run(self)

func _take_population_shot(scenario: String) -> void:
	await PopulationTests.capture(self,scenario)

func _take_wildlife_animation_preview() -> void:
	var preview:=WildlifeAnimationPreview.new()
	await preview.capture(self)


func _spawn_initial_enemies() -> void:
	wildlife.initialize()
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
	if WildlifeSystem.SPECIES.has(id):
		e.setup_custom(WildlifeSystem.species_data(id))
		e.set_meta("monster_id" if e.is_monster else "animal_id",id)
	elif MonsterSystem.MONSTERS.has(id):
		var md: Dictionary = MonsterSystem.MONSTERS[id].duplicate(true)
		md["id"] = id
		md["is_monster"] = true
		var scale := 0.32 + 0.10 * float(player.rank)
		md["hp"] = float(md["hp"]) * scale
		md["atk"] = float(md["atk"]) * (0.25 + 0.05 * float(player.rank))
		md["rank"] = maxi(1, mini(player.rank, 3))
		e.setup_custom(md)
		e.set_meta("monster_id", id)
	else:
		if not AnimalSystem.ANIMALS.has(id):
			e.free()
			return null
		var ad:Dictionary=AnimalSystem.ANIMALS[id].duplicate(true)
		ad["id"]=id
		e.setup_custom(ad)
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
	wildlife.try_spawns()


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
	if world.layer>0: return false
	var site:=world.exploration_at(player.position)
	if not site.is_empty():
		visited_sites[site.id]=true
		var message:String=site.text
		if site.kind in ["timber","rubble"]:
			if float(poi_cd.get(site.id,0))>0:
				message="这附近暂时没有散落材料，约 %.0f 秒后再来。" % float(poi_cd[site.id])
			else:
				var amount:=3+player.utility_gu.harvest_bonus(String(site.kind))
				get_node("/root/Inv").add_item(site.kind,amount)
				poi_cd[site.id]=180.0
				message="收集到 %s ×%d；可放入行囊，带回商铺出售。" % [get_node("/root/Inv").get_item_name(site.kind),amount]
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
	if awakening_ui!=null and awakening_ui.visible:
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
			awakening_ui.close()
			get_viewport().set_input_as_handled()
		return
	# Explicit world inspection takes priority over compact HUD cards covering
	# that pixel in a small window. Ordinary card clicks still use the GUI.
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and event.alt_pressed and _can_act():
		_world_attack_held=false
		var selected:=person_at_screen(event.position)
		if selected!=null: inspect_person(selected)
		get_viewport().set_input_as_handled()
		return
	# Release is observed even when a GUI control consumes the mouse event.
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		_world_attack_held=false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_F11:
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()
			return
		if settings_ui.visible:
			if event.keycode in [KEY_ESCAPE,KEY_O]:
				settings_ui.close()
				get_viewport().set_input_as_handled()
			return
	# Tab must precede the default GUI focus-navigation handler.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_TAB:
		if running and not player.dead and not npc_inspect_ui.visible and not village_ui.visible and not pause_layer.visible and not refine_layer.visible and not dialogue_layer.visible:
			if journal.visible: journal.close()
			else: open_journal("character")
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if shang_city!=null and shang_city.ui.visible:
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE: shang_city.ui.close()
		get_viewport().set_input_as_handled()
		return
	if awakening_ui!=null and awakening_ui.visible:
		get_viewport().set_input_as_handled()
		return
	if settings_ui.visible:
		get_viewport().set_input_as_handled()
		return
	if npc_inspect_ui.visible:
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
			npc_inspect_ui.close()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and _can_act():
		var person:=person_at_screen(event.position)
		if event.alt_pressed:
			_world_attack_held=false
			if person!=null: inspect_person(person)
		else:
			_world_attack_held=true
			basic_attack(get_viewport().get_canvas_transform().affine_inverse()*event.position)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and _can_act():
		set_camera_zoom(zoom_level+(0.1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -0.1))
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if village_ui.visible:
			if event.keycode == KEY_ESCAPE or (event.keycode==KEY_F and village_ui.mode in ["destruction","block"]): village_ui.close()
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
			KEY_F:
				if _can_act():
					stop_meditation("")
					var block:=world.aimed_block(player.position,get_global_mouse_position(),64)
					var nearby:=world.destruction.nearby(player.position,current_house_id if world.in_interior else "")
					if not block.is_empty() and (world.layer>0 or block.height>0 or nearby.is_empty()): village_ui.show_block(block)
					else: village_ui.show_destruction()
			KEY_E:
				if _can_act():
					if _try_layer_interact():
						pass
					elif _try_house_interact():
						pass
					elif _try_settlement_talk():
						pass
					elif world.on_surface() and npc != null and not npc.dead and not npc.hostile and player.position.distance_to(npc.position) < 80.0:
						talk_to_person(npc)
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
				if _can_act() or not running or pause_layer.visible:
					open_settings()
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
	await settings_ui.toggle_fullscreen()


func _toggle_quality() -> void:
	low_quality = not low_quality
	if fx != null:
		fx.low_quality = low_quality
	Enemy.low_detail = low_quality
	if low_quality:
		add_log("低画质：减少粒子与细节。", Color("#8fa38a"))
	else:
		add_log("标准画质。", Color("#8fa38a"))


func _can_act() -> bool:
	if player.body != null and player.body.unconscious:
		return false
	return running and not paused and not player.dead


# ------------------------------------------------------------------ 主循环

func _process(delta: float) -> void:
	fps_smooth = lerpf(fps_smooth, float(Engine.get_frames_per_second()), 0.06)
	if running and not player.dead:
		play_time += delta
		if not performance_testing and play_time > 6.0 and not low_quality and fps_smooth < 45.0:
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

	social_time+=delta
	commissions.tick(delta)
	if not world.in_interior and not shang_city.active:
		var zone_now := world.zone_at(player.position)
		if zone_now != last_zone:
			last_zone = zone_now
			zone_banner_text = world.zone_name(zone_now)
			zone_banner_time = 2.4
			if started:
				add_log("进入 %s" % zone_banner_text, world.zone_color(zone_now))
		zone_banner_time = max(0.0, zone_banner_time - delta)
		if world.on_surface():
			for k in poi_cd.keys(): poi_cd[k] = max(0.0, float(poi_cd[k]) - delta)
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

	if _world_attack_held and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		basic_attack()

	world.environment.tick(delta,self)
	_update_player(delta)
	_update_waypoint()
	_update_pending_melee(delta)
	if world.on_surface():
		_update_enemies(delta)
		_update_spawn(delta)
	population.tick(delta)
	shang_city.tick(delta)
	for person in active_npcs():
		person.player_pos=player.position
		person.tick(delta,self)
		person.social_tick(delta)
	_update_projectiles(delta)
	_update_hazards(delta)
	_update_meditation(delta)
	_update_reaction_events(delta)
	if world.in_interior and not HouseInterior.BOUNDS.grow(24).has_point(player.position-HouseInterior.ORIGIN): exit_house()
	_update_camera(delta)
	_update_night(delta)

	if world.on_surface() and Input.is_key_pressed(KEY_E):
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
	for e in active_enemies():
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

	var spd:float=PlayerStatus.movement(self,v).value
	if v.length() > 0.0:
		stop_meditation("移动打断打坐。")
		v = v.normalized()
		var before := player.position
		world.move_body(player, v.x * spd * delta, v.y * spd * delta, player.radius)
		var moved := player.position - before
		player.dir = moved.angle() if moved.length_squared() > 0.0001 else v.angle()
	update_water_state()
	player.dash_t = max(0.0, player.dash_t - delta)


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
	if shang_city.active:
		night_rect.color=Color(0,0,0,0)
		return
	if world.layer>0:
		night_rect.color=Color(0.025,0.035,0.07,0.12)
		return
	day_time += delta
	var t := fmod(day_time, 180.0) / 180.0
	var alpha := 0.0
	if t > 0.55 and t < 0.95:
		alpha = sin((t - 0.55) / 0.4 * PI) * 0.35
	elif t >= 0.95 or t < 0.10:
		alpha = 0.35 * ((t - 0.95) / 0.05 if t >= 0.95 else 1.0 - t / 0.10)
	night_rect.color = Color(0.03, 0.05, 0.11, alpha)


func _update_spawn(delta: float) -> void:
	wildlife.tick(delta)


# ------------------------------------------------------------------ 战斗

func basic_attack(aim_position: Vector2 = Vector2.INF) -> void:
	if player.atk_cd > 0.0 or player.dead or paused:
		return
	stop_meditation("攻击打断打坐。")
	player.body_gu.interrupt()
	player.utility_gu.break_veil()
	stop_gu_training("")
	player.atk_cd = 0.38 / maxf(0.5, player.body.get_attack_speed_multiplier() if player.body != null else 1.0)
	var acc := player.body.get_accuracy() if player.body != null else 1.0
	var aim:Vector2=get_global_mouse_position() if not aim_position.is_finite() else aim_position
	var a := (aim - player.position).angle()
	player.dir = a
	player.animation.play("strike",a,minf(player.atk_cd,0.5))
	var hit := false
	for e in active_enemies():
		if e.dead:
			continue
		var d := player.position.distance_to(e.position)
		if d > 54.0 + e.radius:
			continue
		var da := wrapf((e.position - player.position).angle() - a, -PI, PI)
		if abs(da) > 0.85:
			continue
		if not world.attack_clear(player.position,e.position): continue
		if acc < 1.0 and _rng.randf() > acc:
			continue
		damage_enemy(e, player.melee_attack() * _rng.randf_range(0.9, 1.1), "none")
		hit = true
	for person in active_npcs():
		var offset:Vector2=person.position-player.position
		if not person.dead and offset.length()<=64+person.radius and offset.normalized().dot(Vector2.from_angle(a))>=cos(0.85) and world.attack_clear(player.position,person.position): hit=true
	var block:=world.aimed_block(player.position,aim,64)
	var hits:=strike_world(player.position,64,player.melee_attack(),"none",Vector2.from_angle(a),cos(0.85))
	if not hit and hits.is_empty() and not block.is_empty(): hit_terrain(block.cell,player.melee_attack(),Vector2.from_angle(a))
	if hit:
		_play_tone(180.0, 0.08, 0.10)
	fx.gu.emit("melee",player.position,"brute_longhorn" if player.gu_effects.brute_left>0 else "white_boar",0.2,{"angle":a,"strong":player.gu_effects.brute_left>0})
	if not hit:
		fx.burst(player.position.x + cos(a) * 30.0, player.position.y + sin(a) * 30.0,
			Color("#8a8a7a"), 2, 40.0, 0.2)


func damage_enemy(e: Enemy, dmg: float, el: String, varied: bool = true) -> void:
	if e.dead:
		return
	var final:float=maxf(0,dmg) if not varied else maxf(1.0,round(dmg*_rng.randf_range(0.92,1.08)))
	e.hp -= final
	e.flash = 0.12
	e.state = "chase"
	e.threat_time=12.0
	e.calm_seconds=0.0
	e.cultivating=false
	if e.wildlife_animation!=null:
		e.wildlife_animation.play_hurt(e.position-player.position)
		e.wildlife_animation.sync_pose(e.radius)
	var col := GameData.el_color(el) if el != "none" else Color("#f0e8d0")
	fx.text(e.position.x + _rng.randf_range(-6, 6), e.position.y - 18, str(final), col)
	fx.burst(e.position.x, e.position.y, GameData.el_color(el) if el != "none" else e.color, 5, 90.0, 0.3)
	if e.hp <= 0.0:
		kill_enemy(e)


func kill_enemy(e: Enemy) -> void:
	if e.dead: return
	e.dead=true
	wildlife.died(e)
	var inv := get_node("/root/Inv")
	if e.is_creature():
		for drop in e.data.get("drops",[]): inv.add_item(String(drop),1)
	kills+=1
	fx.burst(e.position.x,e.position.y,e.color,12,120,0.4)
	add_log("击倒%s，修行境界不因击杀而增长。" % e.display_name,UIStyle.DIM)
	enemies.erase(e)
	if target_hint==e: target_hint=null
	if player.capture_target==e: player.capture_target=null
	if e.wildlife_animation!=null: wildlife.retire(e)
	else: e.queue_free()
	save_game()


func damage_player(dmg: float, element: String = "none") -> void:
	if player.dead or player.iframes > 0.0:
		return
	stop_meditation("受到攻击，打坐中断。")
	stop_gu_training("受到攻击，养力中断。")
	player.body_gu.interrupt(true)
	dmg=player.utility_gu.absorb(dmg,self,element)
	var before_guard:float=dmg
	var guard_template:String=String(fx.gu.snapshot(self).get("guard",""))
	dmg=player.gu_effects.absorb_damage(dmg,player,get_node("/root/Gus"))
	if player.jade_guard and player.aperture.spend(dmg*0.35):
		dmg*=0.4
	elif player.jade_guard:
		player.jade_guard=false
	if guard_template!="":
		var blocked:=maxf(0,before_guard-dmg)
		fx.gu.guard_hit(player.position,guard_template,blocked,blocked<=0)
		fx.text(player.position.x-28,player.position.y-58,"护体 -%.1f"%blocked if blocked>0 else "真元不足 · 护体消退",GuVfx.tint(guard_template),11)
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
	player.animation.play("hurt",player.dir,0.28)
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


func player_death(reason: String = "气血耗尽") -> void:
	if player.dead:
		return
	meditating=false
	player.dead = true
	player.utility_gu.clear_active()
	player.body_gu.clear_active()
	fx.gu.clear(player.position)
	player.animation.play("death",player.dir)
	player.hp = 0.0
	death_reason=reason
	# Persist before animation, menus, or another close event can run.
	_persist_death()
	shake = 12.0
	_play_tone(110.0, 0.50, 0.20)
	fx.burst(player.position.x, player.position.y, Color("#d9534f"), 30, 160.0, 0.9)
	# Freeze gameplay immediately; show the modal after the short visual fall.
	death_layer.visible = false
	paused = true


func respawn() -> void:
	return_to_characters()

func _persist_death() -> bool:
	death_persisted=character_saves.mark_dead(character_id,_snapshot(),death_reason)
	death_note.text=("「%s」已永久陨落，不能继续读取。\n返回角色列表后可查看记录、删除或新建角色。" % character_name) if death_persisted else "死亡记录写入失败。请检查磁盘空间和权限，\n再点返回重试；当前角色仍已陨落。"
	return death_persisted

func _save_before_leaving() -> bool:
	if not started: return true
	if player.dead:
		if death_persisted or _persist_death(): return true
	else:
		if save_game(): return true
	save_error_dialog.dialog_text=character_saves.last_error+"\n当前进度仍保留在窗口中，请排除写入问题后重试。"
	save_error_dialog.popup_centered(Vector2i(500,180))
	return false

func return_to_characters() -> void:
	if not _save_before_leaving(): return
	get_tree().reload_current_scene()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST and _save_before_leaving(): get_tree().quit()


func check_rank_up() -> void:
	pass # 击杀、捕获、炼化均不增长修为。温养完成后在空窍页主动冲关。


func cast_skill(slot: int) -> void:
	if not player.aperture.is_open():
		_action_message("凡人尚无真元；需先借希望蛊开窍。")
		return
	stop_meditation("催蛊打断打坐。")
	var gu := equipped_gu(slot)
	if gu==null:
		_action_message("此催蛊快捷位未绑定可用蛊虫，请在 Q 空窍页设置。")
		return
	var id: String = gu.template_id
	if gu.rank>player.aperture.rank:
		_action_message("%s为%d转蛊，本版需达到对应修为再催动；可在 Q 空窍页打坐冲窍。" % [gu.name,gu.rank])
		return
	var data: Dictionary = GameData.GU[id]
	var sk: Dictionary = data.skill.duplicate(true)
	sk["gu_id"]=id
	sk["target"]=get_global_mouse_position()
	if player.cast_cds[slot]>0 or not player.body.can_cast(): return
	if float(sk.get("dmg",0))>0: player.body_gu.interrupt()
	if sk.kind=="boar_training":
		if player.boar_cultivation.active_id==gu.id:
			stop_gu_training("已收功，增长的力量保留在身体中。")
		elif not player.boar_cultivation.available():
			_action_message("已达到一猪之力。" if player.boar_cultivation.progress>=1 else "今日身体已达安全承受量，请明日再练。")
		elif not can_meditate() or not player.aperture.can_spend(1):
			_action_message("养力需要真元，并在远离威胁、止血后的静处进行。")
		else:
			player.boar_cultivation.active_id=gu.id
			player.animation.play("cast",player.dir,0.38)
			_action_message("开始以%s改造身体；移动、攻击或受伤会停止。" % gu.name)
		player.cast_cds[slot]=0.3
		return
	stop_gu_training("")
	if sk.kind=="light_support":
		player.light_support_id="" if player.light_support_id==gu.id else gu.id
		if player.light_support_id!="": player.animation.play("cast",player.dir,0.32)
		player.cast_cds[slot]=0.3
		_action_message("辅光已开启：催月刃时同时耗元，伤害与大小翻倍。" if player.light_support_id!="" else "已关闭辅光。")
		return
	if player.gu_effects.cast(self,gu,slot): return
	if player.body_gu.cast(self,gu,slot): return
	if player.utility_gu.cast(self,gu,slot): return
	if sk.kind=="refine_essence":
		var success:=player.aperture.refine_essence()
		_action_message("消耗两成真元，得到半成高一小阶真元。" if success else "需要两成未精炼的一转真元；巅峰或二转真元不适用。")
		if success:
			player.cast_cds[slot]=0.8
			player.animation.play("cast",player.dir,0.38)
			fx.gu.emit("refine",player.position,id,1.0)
		return
	if sk.kind=="jade_guard":
		if not player.jade_guard and not player.aperture.can_spend(1):
			_action_message("真元不足以维持玉皮。")
			return
		player.jade_guard=not player.jade_guard
		if player.jade_guard: player.animation.play("cast",player.dir,0.32)
		if player.jade_guard: player.gu_effects.guard_id=""
		if player.jade_guard: player.utility_gu.active.erase("shell")
		if player.jade_guard: player.gu_effects.cancel(player.gu_effects.ward_id)
		_action_message("正在持续灌注真元，维持玉皮。" if player.jade_guard else "已停止玉皮防御。")
		return
	if id=="moon_blade" and active_light_gu()!=null:
		sk.cost=float(sk.cost)+float(GameData.GU.little_light.skill.cost)
		sk.dmg=float(sk.dmg)*2.0
		sk["projectile_radius"]=12.0
		sk["name"]="辅光月刃"
		sk["color"]=Color("d4e9ef")
	if not player.aperture.spend(float(sk.cost)):
		_action_message("真元不足。")
		return
	player.cast_cds[slot] = sk["cd"]
	if float(sk.get("dmg",0))>0: player.utility_gu.break_veil()
	player.cast_flash = 0.25
	_play_tone(520.0, 0.10, 0.10)
	var aim := (get_global_mouse_position() - player.position).angle()
	player.dir = aim
	player.animation.play("cast",aim,0.38)
	if id in ["moon_blade","moon_glow"]: fx.gu.emit("moon_cast",player.position,id,0.2,{"angle":aim})
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
				if world.collides(nx.x, nx.y, player.radius, true):
					break
				player.position = nx
				moved += step
			player.iframes = 0.25
			for e in active_enemies():
				if not e.dead and start.distance_to(e.position) < 70.0 + e.radius:
					damage_enemy(e, sk["dmg"], sk["element"])
			fx.burst(player.position.x, player.position.y, sk["color"], 14, 160.0)
		"chain":
			var cur: Enemy = null
			var best := 160.0 * 160.0
			for e in active_enemies():
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
				for e in active_enemies():
					if e.dead or e in hit_set:
						continue
					var d2 := from.distance_squared_to(e.position)
					if d2 < nd:
						nd = d2
						next = e
				cur = next
		"aoe":
			var rng := float(sk.get("range", 120.0))
			for e in active_enemies():
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
			for e in active_enemies():
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
			for e in active_enemies():
				if e.dead:
					continue
				if player.position.distance_to(e.position) < rng + e.radius:
					e.status["bind"] = max(e.status.get("bind", 0.0), dur)
					fx.ring(e.position.x, e.position.y, sk["color"], 4.0, 20.0, 0.3)
		"melee":
			var rng := float(sk.get("range", 64.0))
			for e in active_enemies():
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
			for e in active_enemies():
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
			for e in active_enemies():
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
			for e in active_enemies():
				if e.dead:
					continue
				if player.position.distance_to(e.position) < 64.0 + e.radius:
					var da := wrapf((e.position - player.position).angle() - aim, -PI, PI)
					if abs(da) < 1.0 and world.attack_clear(player.position,e.position):
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
	e.player_pos=player.position
	if not e.wildlife_slot.is_empty(): wildlife.tick_life(e,delta)
	e.flash = max(0.0, e.flash - delta)
	if e.stun>0 and e.wildlife_animation!=null and e.wildlife_animation.action=="attack":
		e.wildlife_animation.play_hurt(-e.wildlife_animation.attack_direction)
	e.stun = max(0.0, e.stun - delta)
	e.atk_cd -= delta
	e.gu_cast_cd -= delta

	for k in ["burn", "poison", "wet", "shock", "slow", "bleed","bind","frozen"]:
		if float(e.status.get(k, 0.0)) > 0.0:
			if k=="poison":
				e.status["poison_tick"]=float(e.status.get("poison_tick",0))+minf(delta,float(e.status[k]))
			e.status[k] = max(0.0, float(e.status[k]) - delta)
			if k == "burn" and _rng.randf() < delta * 3.0:
				damage_enemy(e, 3.0, "fire")
			if k=="poison" and (float(e.status.poison_tick)>=1 or e.status[k]<=0):
				var poison_damage:float=e.status.poison_tick*4.0
				e.status.poison_tick=0.0
				damage_enemy(e,poison_damage,"wood",false)
			if k == "bleed" and _rng.randf() < delta * 2.5:
				damage_enemy(e, 2.0, "metal")
	if e.dead:
		return
	if float(e.status.get("frozen",0))>0: return
	if not e.wildlife_slot.is_empty():
		wildlife.animate_actor(e,delta)
		return
	if e.stun > 0.0: return

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
			if e.position.distance_to(player.position) < rng + player.radius and world.attack_clear(e.position,player.position):
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
	if e.wildlife_animation!=null:
		wildlife.begin_attack(e)
		return
	if e.position.distance_to(player.position) > 90.0:
		return
	if e.kind == "green_snake" or e.kind == "leiwen":
		var a := (player.position - e.position).angle()
		spawn_projectile(e.position, Vector2(cos(a), sin(a)) * 300.0,
			e.atk + 3.0, e.element, "enemy",
			{"color": GameData.el_color(e.element), "pierce": 0})
	else:
		if e.position.distance_to(player.position) < e.radius + player.radius + 18.0 and world.attack_clear(e.position,player.position):
			damage_player(e.atk + _rng.randf_range(0.0, 3.0), e.element)
			if e.element == "fire" or e.element == "wood":
				apply_status_player(e.element)


func spawn_projectile(pos: Vector2, vel: Vector2, dmg: float, el: String, owner: String, sk: Dictionary) -> void:
	projectiles.append({
		"pos": pos, "vel": vel, "dmg": dmg, "el": el, "owner": owner,
		"life": 1.2, "max_life": 1.2, "r": float(sk.get("projectile_radius",7.0 if int(sk.get("pierce", 0)) > 0 else 6.0)),
		"color": sk.get("color", GameData.el_color(el)), "pierce": int(sk.get("pierce", 0)),
		"hit_set": [], "poison": float(sk.get("poison", 0.0)), "burn": float(sk.get("burn", 0.0)),
		"slow":float(sk.get("slow",0)), "bind":float(sk.get("bind",0)),
		"reaction":String(sk.get("reaction","")), "terrain_damage":float(sk.get("terrain_damage",dmg)),
		"gu_id":String(sk.get("gu_id","")), "trail":[pos],
		"travel":0.0, "ground_range":minf(pos.distance_to(Vector2(sk.target)),vel.length()*1.2) if sk.has("target") and owner=="player" else -1.0,
		"height":world.blocks.height_at(TerrainLayers.cell_at(pos)) if world.on_surface() else 0,
	})


func _update_projectiles(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var pr: Dictionary = projectiles[i]
		var frame_time:=minf(delta,float(pr.life))
		# Keep fast projectiles from stepping over thin interior walls.
		var steps := maxi(3,ceili(Vector2(pr.vel).length()*frame_time/4.0))
		for s in steps:
			if pr["life"] <= 0.0:
				break
			var step_distance:=Vector2(pr.vel).length()*frame_time/steps
			if float(pr.ground_range)>=0: step_distance=minf(step_distance,maxf(0,pr.ground_range-pr.travel))
			pr["pos"]+=Vector2(pr.vel).normalized()*step_distance
			pr.travel+=step_distance
			if Vector2(pr.pos).distance_to(pr.trail[-1])>=6:
				pr.trail.append(pr.pos)
				while pr.trail.size()>(8 if low_quality else 16): pr.trail.pop_front()
			var tx := int(floor(pr["pos"].x / TILE))
			var ty := int(floor(pr["pos"].y / TILE))
			var obstacle:=world.attack_obstacle(pr.pos,int(pr.get("height",0)),float(pr.r))
			if not obstacle.is_empty():
				if pr["owner"]=="player":
					projectile_terrain_hit(pr,obstacle)
				fx.burst(pr["pos"].x, pr["pos"].y, pr["color"], 6, 70.0, 0.25)
				fx.gu.impact(pr,true)
				pr["life"] = 0.0
				break
			if pr["owner"] == "player":
				for person in active_npcs():
					if person.dead or person in pr.hit_set: continue
					if pr.pos.distance_to(person.position)<person.radius+float(pr.r):
						person.take_damage(float(pr.dmg),self,String(pr.el))
						world.environment.react_actor(self,person,pr)
						fx.gu.impact(pr)
						pr.hit_set.append(person)
						if int(pr.pierce)>0: pr.pierce-=1
						else: pr.life=0.0
						break
				if pr.life<=0: break
				for e in active_enemies():
					if e.dead or e in pr["hit_set"]:
						continue
					if pr["pos"].distance_to(e.position) < e.radius + pr["r"]:
						damage_enemy(e, pr["dmg"], pr["el"])
						fx.gu.impact(pr)
						apply_status(e, pr["el"])
						world.environment.react_actor(self,e,pr)
						if pr["poison"] > 0.0:
							e.status["poison"] = max(float(e.status.get("poison", 0.0)), pr["poison"])
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
			if pr.life>0 and float(pr.ground_range)>=0 and pr.travel>=pr.ground_range-0.01:
				projectile_terrain_hit(pr)
				fx.gu.impact(pr,true)
				pr.life=0.0
		pr.life-=frame_time
		if pr["life"] <= 0.0:
			projectiles.remove_at(i)


func projectile_terrain_hit(pr: Dictionary, obstacle: Dictionary = {}) -> void:
	var cell:Vector2i=obstacle.get("cell",TerrainLayers.cell_at(pr.pos))
	if not obstacle.is_empty() and not bool(obstacle.get("block",false)) and world.destruction.objects.has(String(obstacle.id)):
		cell=TerrainLayers.cell_at(Rect2(world.destruction.objects[String(obstacle.id)].rect).get_center())
	var bonus:=world.environment.react_cell(self,cell,pr,obstacle)
	if not obstacle.is_empty() and not bool(obstacle.get("block",false)):
		strike_world(pr.pos,18,float(pr.get("terrain_damage",pr.dmg))+bonus,String(pr.el),Vector2.ZERO,-1,false,String(obstacle.id))
	else:
		hit_terrain(cell,float(pr.get("terrain_damage",pr.dmg))+bonus,Vector2(pr.vel).normalized())
	if world.water_at(pr.pos):
		fx.ring(pr.pos.x,pr.pos.y,Color("a5e0e5"),4,30,0.5)
		fx.burst(pr.pos.x,pr.pos.y,Color("b4e6ec"),8,75,0.4)
	# Reactions can change water without damaging a solid block.
	save_game()

func update_water_state(feedback: bool = true) -> void:
	var was_swimming:=player.swimming
	player.swimming=world.swimming_at(player.position)
	if player.swimming:
		if player.status.burn>0 and feedback: world.environment.reaction(self,player.position,"入水灭火",Color("afdfe6"))
		player.status.burn=0.0
		player.status.wet=5.0
		stop_meditation("")
	if feedback and player.swimming!=was_swimming:
		fx.ring(player.position.x,player.position.y,Color("b9e8ed"),8,38,0.6)
		fx.burst(player.position.x,player.position.y,Color("8ac8d3"),12,60,0.45)
		_action_message("进入水中 · 浅水涉行，深水游动减速；可沿岸直接上岸。" if player.swimming else "已离开水面。")

func apply_status(_target: Enemy, _el: String) -> void:
	pass # 道途不等于元素标签；附加状态只由具体蛊术写入。


func apply_status_player(_el: String) -> void:
	pass


func try_capture(delta: float) -> void:
	if player.dead:
		return
	var target: Enemy = null
	var best := 80.0 * 80.0
	for e in active_enemies():
		if e.dead:
			continue
		if e.is_creature():
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
			if target.is_creature():
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
	if not player.aperture.is_open():
		_action_message("凡人无法注入真元炼化。按 Q 查看希望蛊开窍指引。")
		return
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
	if not player.aperture.is_open(): return
	if not refining or refine_target<0 or refine_target>=player.captured.size(): return
	player.aperture.recover(delta)
	var c: Dictionary=player.captured[refine_target]
	var difficulty:=2.0 if c.id=="jiu_chong" else 1.0
	var available:float=(player.aperture.essence+player.aperture.refined_essence*2.0)/player.aperture.cost_at_stage(1.0)
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
	if not player.aperture.is_open(): return
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
	refine_scroll.custom_minimum_size.y=clampf(player.captured.size()*50+44,60,300)
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
		var label:=_label("%s · 未炼化 · 意志磨合 %.1f%%" % [GuProgression.title(c.id),float(c.get("progress",0))],13,UIStyle.INK)
		label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var b:=UIStyle.button("注入真元",_refine_at.bind(i))
		b.disabled=refining
		row.add_child(b)
		refine_list.add_child(row)
	refine_list.add_child(UIStyle.button("吸收一块元石补充真元",absorb_primeval_stone))


func _refine_at(i: int) -> void:
	if not player.aperture.is_open(): return
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


func save_game() -> bool:
	if not started or player == null or player.dead:
		return false
	var saved:=character_saves.save_character(character_id,_snapshot())
	if not saved: _action_message(character_saves.last_error)
	return saved

func _snapshot() -> Dictionary:
	var data := {
		"shang_city":shang_city.save_data(),
		"version":8,
		"appearance":player.appearance.data.duplicate(true),
		"play_time":play_time,
		"day_time":day_time,
		"social_time":social_time,
		"gu_physical":player.gu_effects.save_data(),
		"utility_gu":player.utility_gu.save_data(),
		"body_gu":player.body_gu.save_data(),
		"boar_cultivation":player.boar_cultivation.save_data(),
		"gu_shop_purchased":gu_shop_purchased,
		"wildlife":wildlife.save_data(),
		"population":population.save_data(),
		"commissions":commissions.save_data(),
		"map_version":GameData.MAP_VERSION,
		"map_width":GameData.MAP_W,
		"world_layer":world.layer,
		"terrain_layers":world.blocks.save_data(),
		"environment":world.environment.save_data(),
		"layer_explored":fog.save_layers(),
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
		"world_salvaged":world.destruction.salvaged.keys(),
		"explored":fog.explored_on(0).keys(),
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
	data["waypoint_layer"] = waypoint_layer
	return data


func _load_save(snapshot: Dictionary = {}) -> bool:
	var d:Dictionary=snapshot if not snapshot.is_empty() else character_saves.load_character(character_id)
	if d.is_empty() or character_saves.is_dead(character_id): return false
	if shang_city.active:
		shang_city.bout=false
		if is_instance_valid(shang_city.opponent): shang_city.opponent.queue_free()
		shang_city.opponent=null
		shang_city.leave(false)
	shang_city.load_data(d.get("shang_city",{}))
	player.appearance.configure(d.get("appearance",{}),character_saves.art_directory(character_id))
	if not player.appearance.warning.is_empty(): _action_message(player.appearance.warning)
	fx.clear_transients()
	get_node("/root/Gus").active_gu=null
	if bool(d.get("fresh",false)):
		player.reset_stats_for_rank(0)
		player.aperture.load_data(d.get("aperture",{"rank":0,"potential":44}))
		var inv:=get_node("/root/Inv")
		inv.items.clear()
		inv.add_item("moon_petals",10)
		inv.add_item("bandage",3)
		inv.add_item("bamboo_wine",1)
		player.captured.clear()
		player.owned.clear()
		player.skill_slots.assign(["","",""])
		player.vital_gu_id=""
		player.discovered.assign(["hope_gu"])
		get_node("/root/Gus").owned_gus.clear()
		get_node("/root/Hunger").gu_data.clear()
		return true
	play_time=maxf(0,float(d.get("play_time",0)))
	day_time=float(d.get("day_time",40))
	social_time=maxf(0,float(d.get("social_time",maxf(0,day_time-40))))
	var source_map_version:=int(d.get("map_version",1))
	var r := int(d.get("rank", 1))
	player.reset_stats_for_rank(clamp(r, 0, 5))
	player.aperture.load_data(d.get("aperture",{}))
	cave_gu_claimed=bool(d.get("cave_gu_claimed",false))
	jade_gu_purchased=bool(d.get("jade_gu_purchased",false))
	gu_shop_purchased=d.get("gu_shop_purchased",{})
	if jade_gu_purchased and int(gu_shop_purchased.get("jade_skin",0))<1: gu_shop_purchased["jade_skin"]=1
	player.boar_cultivation.load_data(d.get("boar_cultivation",{}))
	player.gu_effects.load_data(d.get("gu_physical",{}))
	player.utility_gu.load_data(d.get("utility_gu",{}))
	player.body_gu.load_data(d.get("body_gu",{}))
	player.jade_guard=false
	player.light_support_id=""
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
	clear_waypoint(false)
	if mark is Array and mark.size()==2:
		var destination:=Vector2(float(mark[0]),float(mark[1]))
		if int(d.get("waypoint_layer",0))==0: destination=World.migrate_outdoor_position(destination,source_map_version)
		set_waypoint(destination,String(d.get("waypoint_name","自定标记")),false,clampi(int(d.get("waypoint_layer",0)),0,2))
	world.layer=0
	fog.set_layer(0)
	world.destruction.load_data(d.get("world_damage",{}),d.get("world_salvaged",[]))
	world.blocks.load_data(d.get("terrain_layers",{}),d.get("world_damage",{}))
	world.environment.load_data(d.get("environment",{}))
	world._bake_textures()
	fog.load_data(d.get("explored",[]),int(d.get("map_width",80)),source_map_version)
	fog.load_layers(d.get("layer_explored",{}))
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
		# Indoor coordinates live beyond the map; retain room-local positions after expansion.
		var source_width:=int(d.get("map_width",80))
		if source_width in [80,160,240,320] and source_width!=GameData.MAP_W:
			resume.x+=(GameData.MAP_W-source_width)*GameData.TILE
		for house in World.HOUSE_DATA:
			if house.id!=house_id: continue
			player.position=world.safe_outdoor_position(house.pos+Vector2(0,50))
			if not world.destruction.broken("house:"+house_id):
				enter_house(house)
				if HouseInterior.BOUNDS.has_point(resume-HouseInterior.ORIGIN) and not world.collides(resume.x,resume.y,12): player.position=resume
			break
	else: player.position=world.safe_position(World.migrate_outdoor_position(resume,source_map_version),true)
	wildlife.load_data(d.get("wildlife"))
	population.load_data(d.get("population"))
	var saved_layer:=clampi(int(d.get("world_layer",0)),0,2)
	if house_id=="": change_layer(saved_layer,resume if saved_layer>0 else player.position,false)
	if bool(d.get("shang_city",{}).get("active",false)):
		world.layer=0
		shang_city.enter(true,resume)
	return true



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
	if shang_city.active: return shang_city.interact()
	if world.in_interior:
		var action := world.interior.interaction_at(player.position)
		match action:
			"exit": exit_house()
			"rest": rest_at_bed()
			"storage": open_journal("inventory")
			"flower_cave": _claim_cave_gu()
			"spring_cave": open_awakening()
			"ancestral": village_ui.show_service(action)
			"clinic","shop","archive","home":
				if service_available(action): village_ui.show_service(action)
				else: _action_message("这里的住民已死亡或与你敌对，无法提供服务。")
			_:
				var building:=SettlementData.building(action)
				if not building.is_empty():
					if building.service=="spring" or service_available(action): village_ui.show_service(action)
					else: _action_message("这里的住民已死亡或与你敌对，无法提供服务。")
		return action!=""
	var h := world.house_at(player.position)
	if h.is_empty(): return false
	enter_house(h)
	return true


func enter_house(h: Dictionary) -> void:
	if world.layer>0 or world.in_interior or world.destruction.broken("house:"+String(h.id)): return
	stop_meditation("")
	outdoor_return=h.pos+Vector2(0,50)
	current_house_id=h.id
	player.utility_gu.clear_active()
	player.body_gu.clear_active()
	current_house_name=h.name
	world.in_interior=true
	world.visible=false
	world.props.visible=false
	enemies_root.visible=false
	population.set_visible(false)
	npc.visible=false
	for id in residents: residents[id].visible=not residents[id].outdoors and id==current_house_id
	projectiles.clear()
	pending_melee.clear()
	fx.clear_transients()
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
	player.utility_gu.clear_active()
	player.body_gu.clear_active()
	world.in_interior=false
	world.visible=true
	world.props.visible=true
	enemies_root.visible=true
	population.set_visible(true)
	npc.visible=true
	for person in residents.values(): person.visible=person.outdoors
	world.interior.visible=false
	projectiles.clear()
	pending_melee.clear()
	fx.clear_transients()
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
	if not world.in_interior or not service_available(current_house_id): return false
	if GameData.utility_food_stock().has(id) and (SettlementData.service(current_house_id)!="shop" or cost!=1): return false
	if not SettlementData.building(current_house_id).is_empty():
		var stock:=SettlementData.stock(current_house_id)
		if not stock.has(id) or cost!=int(stock[id]): return false
	elif current_house_id not in ["shop","clinic"]: return false
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
	return buy_gu("jade_skin")

func gu_shop_remaining(id: String) -> int:
	var bought:=int(gu_shop_purchased.get(id,0))
	if id=="jade_skin" and jade_gu_purchased: bought=maxi(1,bought)
	return maxi(0,int(GuProgression.SHOP_LIMITS.get(id,1))-bought)

func buy_gu(id: String) -> bool:
	if not world.in_interior or not service_available(current_house_id): return false
	if not GameData.shop_gu_ids(current_house_id).has(id): return false
	var data:Dictionary=GameData.GU[id]
	if gu_shop_remaining(id)<=0:
		_action_message("%s已经售出。" % data.name)
		return false
	var price:int=GameData.GU_SHOP[id]
	if player.crystals<price:
		_action_message("%s售价 %d 元石，钱袋不足。" % [data.name,price])
		return false
	player.crystals-=price
	gu_shop_purchased[id]=int(GuProgression.SHOP_LIMITS.get(id,1))-gu_shop_remaining(id)+1
	if id=="jade_skin": jade_gu_purchased=true
	player.captured.append({"id":id,"rank":int(data.rank),"quality":"normal","progress":0.0})
	if not player.discovered.has(id): player.discovered.append(id)
	_action_message("%s已放入外部行囊，尚未炼化。" % data.name)
	save_game()
	return true


func sell_supply(id: String) -> bool:
	if not world.in_interior or not SettlementData.can_sell(current_house_id,id) or not service_available(current_house_id): return false
	var price:int=Inventory.SELL_PRICES.get(id,0)
	var inv:Inventory=get_node("/root/Inv")
	if price<=0 or not inv.remove_item(id,1): return false
	player.crystals+=price
	_action_message("售出%s ×1，得到 %d 元石。" % [inv.get_item_name(id),price])
	save_game()
	return true


func clinic_heal() -> bool:
	if not world.in_interior or SettlementData.service(current_house_id)!="clinic" or not service_available(current_house_id): return false
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
	stop_gu_training("")
	if player.dash_cd > 0.0 or player.dead:
		return
	if player.body != null and not player.body.can_dash():
		add_log("腿部伤势太重，无法疾步。", Color("#d9534f"))
		return
	player.dash_cd = 2.4
	if not player.gu_effects.spend_stamina(25):
		player.dash_cd=0
		_action_message("体力不足以疾步，稍作休息；黄骆天牛蛊可减少消耗。")
		return
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
	await PerformanceTests.new().run(self)

func _perfscenes() -> void:
	await PerformanceTests.new().run(self,true)

func _run_render_tests() -> void:
	await RenderTests.new().run(self)


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
	for e in active_enemies():
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
	for e in active_enemies():
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
	player.captured.clear()
	for id in GameData.GU_ORDER:
		player.captured.append({"id":id,"rank":1,"quality":"normal","progress":0.0})
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
	for e in active_enemies():
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


func _take_shot_bag(item_id: String = "capture:0") -> void:
	start_game()
	await get_tree().process_frame
	var inv := get_node_or_null("/root/Inv")
	inv.add_item("rabbit_meat", 2)
	inv.add_item("timber", 3)
	inv.add_item("rubble", 4)
	inv.add_item("jade", 1)
	if item_id.ends_with("_meat") or item_id=="pork_ration":
		for meat in ["deer_meat","wolf_meat","bear_meat","boar_meat","pheasant_meat"]:
			inv.add_item(meat,3)
		inv.add_item("pork_ration",1)
	open_journal("inventory")
	inventory_ui.selected_id=item_id
	inventory_ui.refresh_inventory()
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://shot_bag.png" if item_id=="capture:0" else "res://shot_item%s.png"%item_id)
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
	player.bus = "SFX"
	player.play()


func _run_polish_tests() -> void:
	var suite := GamePolishTests.new()
	await suite.run(self)


func _take_polish_shot(scenario: String) -> void:
	if scenario != "menu":
		start_game()
		player.position=Vector2(510,1060)
		player.owned.assign(GameData.GU_ORDER)
		_sync_owned_gus()
		fog.reveal(player.position,fog.radius_world())
		_update_camera(0)
		camera.reset_smoothing()
		if scenario in ["npcinspect","npcrelations","npcstatus","npcdead","npcitems","npcsell","npcloot"]:
			enter_house(World.HOUSE_DATA[1])
			var person:Npc=residents.shop
			player.position=person.position+Vector2(-55,20)
			_update_camera(0)
			camera.reset_smoothing()
			person.visible=true
			if scenario in ["npcrelations","npcstatus"]:
				person.load_data({"hp":34,"hostile":true})
			if scenario=="npcdead": person.load_data({"hp":0,"hostile":true,"dead":true})
			if scenario in ["npcitems","npcsell","npcloot"]:
				person.load_data({"hp":0 if scenario=="npcloot" else 100,"dead":scenario=="npcloot","possessions":{"items":{"bandage":3,"bamboo_wine":2,"rabbit_meat":2,"timber":6,"rubble":4},"crystals":24}})
				player.crystals=48
				get_node("/root/Inv").items={"timber":6,"rabbit_meat":3,"bandage":2,"rubble":4}
			inspect_person(person)
			if scenario=="npcrelations": npc_inspect_ui.select_tab("relations")
			if scenario in ["npcstatus","npcdead"]: npc_inspect_ui.select_tab("status")
			if scenario in ["npcitems","npcsell","npcloot"]: npc_inspect_ui.select_tab("items")
			if scenario=="npcsell": npc_inspect_ui._set_selling(true)
		if scenario=="interior": enter_house(World.HOUSE_DATA[0])
		if scenario in ["wildlife","wildlifebeasts"]:
			open_journal("map")
			minimap_ui.set_mode("beasts" if scenario=="wildlifebeasts" else "wildlife")
			if scenario=="wildlifebeasts":
				await get_tree().process_frame
				await get_tree().process_frame
				minimap_ui.wildlife_view.scroll_vertical=0
		if scenario in ["wildlifefield","wildlifecultivate"]:
			var habitat:Dictionary=WildlifeSystem.HABITATS[0 if scenario=="wildlifefield" else 7]
			var actor:Enemy=wildlife.actors.get(habitat.id+":0")
			if actor!=null:
				if actor.is_monster:
					actor.position=WildlifeSystem.center(habitat)
					actor.age_seconds=float(actor.data.mature)
					actor.cultivation_seconds=220.0
				actor.refresh_growth()
				var observer_offset:=Vector2(-340,0) if actor.is_monster else Vector2(-120,85)
				player.position=world.safe_outdoor_position(actor.position+observer_offset)
				if actor.is_monster:
					actor.calm_seconds=9.0
					wildlife.tick_life(actor,0.0)
				for resident in enemies: resident.player_pos=player.position
				target_hint=actor
				fog.reveal(player.position,fog.radius_world())
				_update_camera(0)
				camera.reset_smoothing()
			paused=true
		if scenario=="shop":
			enter_house(World.HOUSE_DATA[1])
			village_ui.show_service("shop")
		if scenario=="gushop":
			enter_house(World.HOUSE_DATA[1])
			village_ui.show_service("shop")
			await get_tree().process_frame
			await get_tree().process_frame
			village_ui.action_scroll.ensure_control_visible(village_ui.gu_buttons.black_boar)
		if scenario=="gutraining":
			player.boar_cultivation.progress=0.3
			player.boar_cultivation.daily_used=15
			open_journal("character")
		if scenario=="guwave2shop":
			enter_house(World.HOUSE_DATA[1])
			village_ui.show_service("shop")
			village_ui.shop_filter.select(1)
			village_ui._filter_shop()
			await get_tree().process_frame
			await get_tree().process_frame
			village_ui.action_scroll.ensure_control_visible(village_ui.gu_buttons.dragon_cricket)
		if scenario=="guwave2food":
			enter_house(World.HOUSE_DATA[1])
			village_ui.show_service("shop")
			village_ui.shop_filter.select(2)
			village_ui._filter_shop()
			await get_tree().process_frame
			await get_tree().process_frame
			village_ui.action_scroll.ensure_control_visible(village_ui.supply_buttons.dragon_cricket_care)
		if scenario in ["guwave2","gudefense","gucricket"]:
			player.discovered.assign(GameData.GU_ORDER)
			compendium_ui.refresh()
			if scenario=="gudefense":
				compendium_ui.category.select(2)
				compendium_ui._apply_filter()
			var chosen:String={"guwave2":"brute_longhorn","gudefense":"copper_skin","gucricket":"dragon_cricket"}[scenario]
			compendium_ui._show_detail(chosen)
			compendium_ui.show()
			await get_tree().process_frame
			await get_tree().process_frame
			compendium_ui.list_scroll.ensure_control_visible(compendium_ui._buttons[chosen])
			paused=true
		if scenario=="gucombat":
			for gu in get_node("/root/Gus").owned_gus:
				if gu.template_id in ["iron_skin","brute_longhorn","yellow_camel"]:
					var slot:int=["iron_skin","brute_longhorn","yellow_camel"].find(gu.template_id)
					equip_gu(gu.id,slot)
					player.cast_cds[slot]=0
					cast_skill(slot)
			paused=true
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
		if scenario in ["gujade","guliquor","gulight","guwhite","gublack"]:
			player.discovered.assign(GameData.GU_ORDER)
			compendium_ui.refresh()
			compendium_ui._show_detail({"gujade":"jade_skin","guliquor":"jiu_chong","gulight":"little_light","guwhite":"white_boar","gublack":"black_boar"}[scenario])
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
		if scenario=="mapzoom":
			fog.reveal(Vector2(GameData.MAP_W,GameData.MAP_H)*16,20000)
			set_waypoint(Vector2(274,104)*32+Vector2(16,16),"云溪长桥",false)
			open_journal("map")
			minimap_ui.atlas.focus_position(waypoint)
		if scenario in ["baivillage","xiongvillage","baidistrict","xiongdistrict","villagedirections","villagemap"]:
			var house:Dictionary=World.HOUSE_DATA[6 if scenario in ["xiongvillage","xiongdistrict"] else 5]
			player.position=house.pos+Vector2(0,160)
			set_waypoint(house.pos+Vector2(0,40),house.name,false)
			if scenario in ["baidistrict","xiongdistrict"]:
				zoom_level=minf(0.46,(get_viewport_rect().size.y-96)/1536.0) # Whole-district review fixture.
				fog.reveal(player.position,1400)
				fog.set_process(false)
				fog.hide() # Overview fixture only; gameplay retains normal sight.
				hud.hide()
			_update_camera(0)
			camera.reset_smoothing()
			fog.reveal(player.position,fog.radius_world())
			if scenario=="villagedirections": village_ui.show_directions("bai","白家守寨人")
			if scenario=="villagemap":
				fog.reveal(player.position,1800)
				open_journal("map")
				minimap_ui.atlas.zoom=8
				minimap_ui.atlas.focus_position(player.position)
			paused=true
		if scenario in ["baishop","xiongclinic","clanspring"]:
			var house_id:String={"baishop":"bai_shop","xiongclinic":"xiong_clinic","clanspring":"bai_spring"}[scenario]
			enter_house(SettlementData.building(house_id))
			if scenario!="clanspring": village_ui.show_service(house_id)
			paused=true
		if scenario in ["mapguide","maparrival","mapexit","mapfrontier"]:
			set_waypoint(Vector2(302,142)*32+Vector2(16,16),"远岭驿棚",false)
			if scenario=="maparrival": player.position=waypoint+Vector2(0,35)
			elif scenario=="mapexit": enter_house(World.HOUSE_DATA[2])
			elif scenario=="mapfrontier": player.position=Vector2(274,104)*32+Vector2(16,45)
			_update_camera(0)
			camera.reset_smoothing()
			fog.reveal(player.position,fog.radius_world())
			paused=true
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
		if scenario in ["destruction","repair"]:
			var home_pos:Vector2=World.HOUSE_DATA[2].pos
			strike_world(home_pos+Vector2(0,-20),2,9999,"none",Vector2.ZERO,-1,false)
			player.position=home_pos+Vector2(0,54)
			_update_camera(0)
			camera.reset_smoothing()
			fog.reveal(player.position,fog.radius_world())
			if scenario=="repair":
				get_node("/root/Inv").add_item("timber",20)
				get_node("/root/Inv").add_item("rubble",20)
				village_ui.show_destruction("house:home")
			paused=true
		if scenario=="damageinterior":
			enter_house(World.HOUSE_DATA[2])
			strike_world(HouseInterior.ORIGIN+Vector2(190,100),1,9999,"none",Vector2.ZERO,-1,false)
			strike_world(HouseInterior.ORIGIN+Vector2(180,-100),1,45,"none",Vector2.ZERO,-1,false)
			strike_world(HouseInterior.ORIGIN+Vector2(-346,0),1,310,"none",Vector2.ZERO,-1,false)
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
	if shang_city!=null and shang_city.active:
		return [shang_city.opponent] if is_instance_valid(shang_city.opponent) and shang_city.bout else []
	if world.layer>0: return []
	if world.in_interior:
		return [residents[current_house_id]] if residents.has(current_house_id) else []
	var people:Array=[npc]
	for person in residents.values():
		if person.outdoors: people.append(person)
	people.append_array(population.actors.values())
	return people

func active_enemies() -> Array:
	if shang_city!=null and shang_city.active: return []
	return enemies if world.layer==0 else []

func change_layer(value: int, arrival: Vector2, persist: bool = true) -> void:
	if value not in [0,1,2]: return
	if world.in_interior: exit_house(false)
	stop_meditation("")
	stop_gu_training("")
	world.layer=value
	player.utility_gu.clear_active()
	player.body_gu.clear_active()
	world.visible=true
	world.props.visible=value==0
	enemies_root.visible=value==0
	population.set_visible(value==0)
	npc.visible=value==0
	for person in residents.values(): person.visible=value==0 and person.outdoors
	projectiles.clear()
	pending_melee.clear()
	fx.clear_transients()
	_world_attack_held=false
	target_hint=null
	player.capture_target=null
	player.capture_progress=0
	player.position=world.safe_position(arrival,true)
	update_water_state(false)
	fog.set_layer(value)
	fog.reveal(player.position,fog.radius_world())
	camera.limit_left=0
	camera.limit_top=0
	camera.limit_right=int(TerrainLayers.extent(value).x)
	camera.limit_bottom=int(TerrainLayers.extent(value).y)
	_update_camera(0)
	camera.reset_smoothing()
	world.queue_redraw()
	minimap_ui.view_layer(value)
	last_zone=""
	if persist:
		_action_message("来到"+TerrainLayers.NAMES[value]+"。E 使用石阶，M 查看分层地图。")
		save_game()

func _try_layer_interact() -> bool:
	if shang_city.active: return false
	if world.in_interior: return false
	var portal:=world.blocks.portal_at(player.position,world.layer)
	if not portal.is_empty() and world.attack_clear(player.position,portal.pos):
		change_layer(int(portal.to_layer),portal.to_pos)
		return true
	var site:=world.blocks.site_at(player.position,world.layer)
	if site.is_empty() or not world.attack_clear(player.position,site.pos): return false
	world.blocks.visited[site.id]=true
	var detail:String=site.text
	if not world.blocks.claimed.has(site.id):
		world.blocks.claimed[site.id]=true
		for item in site.loot: get_node("/root/Inv").add_item(item,int(site.loot[item]))
		if not site.loot.is_empty(): detail+=" 获得"+materials_text(site.loot)+"。"
	elif not site.loot.is_empty(): detail+=" 此处补给已取走。"
	_action_message(detail)
	world.queue_redraw()
	save_game()
	return true

func hit_terrain(cell: Vector2i, amount: float, direction: Vector2) -> Dictionary:
	if shang_city.active: return {}
	if world.in_interior: return {}
	var result:=world.blocks.hit(cell,world.layer,amount)
	if result.is_empty(): return result
	fx.text(result.pos.x,result.pos.y-26,"%s · %.0f / %.0f"%[result.name,result.hp,result.max_hp],UIStyle.GOLD,12)
	if result.destroyed:
		fx.eject_blocks(result.pos,direction,amount,world.blocks.color_at(cell,world.layer))
		for item in result.loot: get_node("/root/Inv").add_item(item,int(result.loot[item]))
	else:
		fx.burst(result.pos.x,result.pos.y,Color("aba58e"),4,55,0.25)
	if result.damage>0:
		fx.impact_mark(result.pos,direction,result.destroyed)
		shake=maxf(shake,2.0 if result.destroyed else 0.6)
		save_game()
	return result

func _try_settlement_talk() -> bool:
	if not world.on_surface(): return false
	var nearest:Npc=null
	var distance:=80.0
	for person:Npc in active_npcs():
		if not person.outdoors: continue
		var current:=player.position.distance_to(person.position)
		if current<distance:
			nearest=person
			distance=current
	if nearest==null: return false
	var blocker:=person_talk_blocker(nearest)
	if blocker!="": _action_message(blocker)
	else: talk_to_person(nearest)
	return true

func person_at_screen(screen_position: Vector2) -> Npc:
	var selected: Npc=null
	for person: Npc in active_npcs():
		if not is_instance_valid(person) or not person.is_visible_in_tree() or not fog.can_see(person.position): continue
		var local:Vector2=person.get_global_transform_with_canvas().affine_inverse()*screen_position
		if person.inspection_rect().has_point(local):
			if selected==null or person.position.y>selected.position.y: selected=person
	return selected

func inspect_person(person: Npc) -> void:
	if not _can_act() or not is_instance_valid(person) or not active_npcs().has(person): return
	if not person.is_visible_in_tree() or not fog.can_see(person.position): return
	npc_inspect_ui.show_person(person)

func person_talk_blocker(person: Npc) -> String:
	if not is_instance_valid(person) or not active_npcs().has(person): return "人物已不在当前场景。"
	if person.dead: return "已死亡，无法交谈或提供服务。"
	if person.hostile: return "与你敌对，拒绝交谈与服务。"
	if person is WorldPerson and (population.valid_target(person,person.target) or person.flee_left>0): return "此人正在交战或避险，暂时无法交谈。"
	if person.resident_id!="aqing" and not person.outdoors and not service_available(person.resident_id): return "所在建筑已毁损，暂时无法提供服务。"
	if player.position.distance_to(person.position)>=80: return "距离较远，请靠近人物后再交谈。"
	if not world.conversation_clear(player.position,person.position): return "中间有遮挡，请绕到人物身边再交谈。"
	return ""

func talk_to_person(person: Npc) -> void:
	if not _can_act() or person_talk_blocker(person)!="": return
	village_ui.show_conversation(person)

func service_available(id: String) -> bool:
	if id=="home": return not world.destruction.broken("house:home")
	return residents.has(id) and not residents[id].dead and not residents[id].hostile and not world.destruction.broken("house:"+id)

func npc_save_data() -> Dictionary:
	var data := {"aqing":npc.save_data()}
	for id in residents: data[id]=residents[id].save_data()
	return data

func strike_world(center: Vector2, radius: float, damage: float, element: String, direction: Vector2 = Vector2.ZERO, cone: float = -1.0, include_people: bool = true, only_id: String = "", persist: bool = true) -> Array:
	# Snapshot visibility before destruction: a single swing cannot break through a wall and hit behind it.
	var people:Array=[]
	if include_people:
		for person in active_npcs():
			if person.dead: continue
			var offset:Vector2=person.position-center
			if offset.length()<=radius+person.radius and (direction==Vector2.ZERO or offset.normalized().dot(direction)>=cone) and world.attack_clear(center,person.position):
				people.append(person)
	var hits := world.destruction.hit_area(center,radius,damage,destruction_power(),current_house_id if world.in_interior else "",direction,cone,only_id)
	var damaged:=false
	for hit in hits:
		if hit.blocked:
			fx.burst(hit.pos.x,hit.pos.y,Color("aeb9bd"),3,45,0.2)
			fx.text(hit.pos.x,hit.pos.y-25,"过于坚硬 · 未造成破坏",UIStyle.DIM,12)
			continue
		damaged=true
		var wood:bool=hit.kind in ["tree","bamboo","house","furniture","bonfire"]
		fx.burst(hit.pos.x,hit.pos.y,Color("ba9765") if wood else Color("a6b2b3"),18 if hit.destroyed else 5,110 if hit.destroyed else 70,0.5 if hit.destroyed else 0.3)
		fx.text(hit.pos.x,hit.pos.y-25,"%s -%.1f / 耐久 %.0f"%[world.destruction.object_name(hit.id),hit.damage,hit.hp],UIStyle.GOLD,11)
		if hit.destroyed:
			fx.eject_blocks(hit.pos,(hit.pos-player.position).normalized(),damage,Color("b48b58") if wood else Color("a6b2b3"))
			fx.impact_mark(hit.pos,(hit.pos-player.position).normalized(),true)
			var inv:Inventory=get_node("/root/Inv")
			for item in hit.loot: inv.add_item(item,int(hit.loot[item]))
			_action_message("%s已毁损。%s"%[world.destruction.object_name(hit.id),materials_text(hit.loot)+"已放入背包。" if not hit.loot.is_empty() else "可回收材料已取尽。"])
			_play_tone(130 if wood else 85,0.16,0.15)
	for person in people: person.take_damage(damage,self,element)
	if damaged and persist: save_game()
	return hits


func materials_text(items: Dictionary) -> String:
	var parts:=PackedStringArray()
	var inv:Inventory=get_node("/root/Inv")
	for item in items: parts.append("%s ×%d"%[inv.get_item_name(item),int(items[item])])
	return " / ".join(parts)


func repair_unavailable_reason(id: String) -> String:
	var destruct:DestructionSystem=world.destruction
	if not running or player.dead or player.body.unconscious: return "当前无法修缮。"
	if not destruct.within_reach(id,player.position,current_house_id if world.in_interior else ""):
		return "请靠近该物件，在同一地点修缮。"
	if not destruct.repairable(id): return "自然地物暂不能修复或再生。"
	var cost:=destruct.repair_cost(id)
	if cost.is_empty(): return "物件完好，无需修缮。"
	if destruct.broken(id):
		var rect:Rect2=destruct.objects[id].rect
		var people:Array=[player]
		people.append_array(active_npcs())
		if not world.in_interior: people.append_array(enemies)
		for person in people:
			if not is_instance_valid(person) or person.dead: continue
			if rect.grow(float(person.radius)+2).has_point(person.position):
				return "原址有人占据，请先离开原址再重建。"
	var inv:Inventory=get_node("/root/Inv")
	for item in cost:
		if not inv.has_item(item,int(cost[item])): return "材料不足，需要："+materials_text(cost)+"。"
	return ""


func repair_world_object(id: String) -> bool:
	var reason:=repair_unavailable_reason(id)
	if reason!="":
		_action_message(reason)
		return false
	var destruct:DestructionSystem=world.destruction
	var cost:=destruct.repair_cost(id)
	if not destruct.repair(id,get_node("/root/Inv")): return false
	var pos:Vector2=destruct.objects[id].rect.get_center()
	fx.ring(pos.x,pos.y,UIStyle.JADE,12,48,0.5)
	_action_message("%s已修复，消耗%s。"%[destruct.object_name(id),materials_text(cost)])
	save_game()
	return true

func toggle_meditation() -> void:
	if not player.aperture.is_open():
		_action_message("尚未开窍，没有可温养的窍壁；按 Q 查看希望蛊指引。")
		return
	if meditating:
		stop_meditation("收功，窍壁温养进度已保存。")
		save_game()
		return
	if not can_meditate():
		_action_message("需远离敌人、停止受击并处理出血或中毒后才能打坐。")
		return
	meditating=true
	stop_gu_training("")
	meditation_seconds=0.0
	player.capture_target=null
	player.capture_progress=0.0
	_action_message("开始打坐。J 收功；移动、攻击或受伤会中断。")

func can_meditate() -> bool:
	if world.swimming_at(player.position): return false
	if player.dead or player.body.unconscious or player.body.total_bleed_rate()>0 or player.body.recovery_delay>0:
		return false
	if float(player.status.get("burn",0))>0 or float(player.status.get("poison",0))>0: return false
	if not world.in_interior:
		for enemy in active_enemies():
			if not enemy.dead and enemy.position.distance_to(player.position)<260: return false
	for person in active_npcs():
		if person.hostile and not person.dead and person.position.distance_to(player.position)<260: return false
	return true

func meditation_rate() -> float:
	return 0.6*player.utility_gu.cultivation_multiplier() if player.yuan>0 else 0.0


func _update_meditation(delta: float) -> void:
	if not meditating or paused: return
	if not can_meditate():
		stop_meditation("无法继续集中精神，打坐中断。")
		return
	meditation_seconds+=delta
	if player.aperture.crossing:
		if player.aperture.advance_crossing(delta):
			stop_meditation("冲窍成功，进入%d转初阶；已解锁对应转数蛊的催动。"%player.aperture.rank)
			save_game()
		elif not player.aperture.crossing:
			stop_meditation("真元中断，冲窍停止；已消耗的真元不返还。")
		return
	player.aperture.cultivate(delta*player.utility_gu.cultivation_multiplier())
	if player.aperture.wall_progress>=100:
		stop_meditation("窍壁温养完成，请在 Q 空窍页冲关。")


func stop_meditation(message: String) -> void:
	player.aperture.cancel_crossing()
	if not meditating: return
	meditating=false
	if message!="": _action_message(message)

func record_reaction(title: String) -> void:
	reaction_events.append({"title":title,"time":2.5})
	while reaction_events.size()>3: reaction_events.pop_front()


func _update_reaction_events(delta: float) -> void:
	for i in range(reaction_events.size()-1,-1,-1):
		reaction_events[i].time-=delta
		if reaction_events[i].time<=0: reaction_events.remove_at(i)

func _update_hazards(delta: float) -> void:
	for hazard in fx.hazards:
		hazard["tick"]=float(hazard.get("tick",0))+delta
		if hazard.tick<0.5: continue
		hazard.tick-=0.5
		for enemy in active_enemies().duplicate():
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
	if not player.aperture.is_open():
		_action_message("尚未开窍，无法绑定催蛊快捷位。")
		return
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
	if not player.aperture.is_open() and location!="bag":
		_action_message("凡人尚无空窍，蛊虫只能在外部携带。")
		return false
	var gu: GuVirtual=get_node("/root/Gus").get_gu_by_id(id)
	if gu==null or gu.dead or location not in ["bag","aperture","body"]: return false
	if location=="body" and gu.template_id not in ["moon_blade","little_light"]:
		_action_message("这只蛊虫暂不支持寄居掌心，可收入空窍或外部携带。")
		return false
	gu.location=location
	if location=="bag":
		player.gu_effects.cancel(id)
		player.utility_gu.cancel(id)
		player.body_gu.cancel(id)
		for i in 3:
			if player.skill_slots[i]==id: player.skill_slots[i]=""
		if gu.template_id=="jade_skin": player.jade_guard=false
		if player.light_support_id==id: player.light_support_id=""
		if player.boar_cultivation.active_id==id: stop_gu_training("")
	save_game()
	return true

func absorb_primeval_stone() -> void:
	var a:=player.aperture
	if not a.is_open():
		_action_message("尚未开窍，不能吸收元石形成真元。")
		return
	if player.crystals<=0 or a.stone_reserve>0 or a.total()>=a.capacity:
		_action_message("无需吸收，或元石不足；已有元石余量时先继续吸收。")
		return
	player.crystals-=1
	a.stone_reserve=100.0 # 每块储量为模拟参数，不作为原文固定数值。
	_action_message("开始吸收元石，逐步补充真元。")
	save_game()

func attempt_breakthrough() -> void:
	var a:=player.aperture
	if not a.is_open():
		_action_message("需先借希望蛊开窍，之后才能温养与冲关。")
		return
	if a.stage==3 and a.wall_progress>=100:
		if not can_meditate() or not a.begin_crossing():
			_action_message("五转为当前上限。跨转需安全静处、当前转数巅峰、窍壁温养 100%%、普通真元至少 %.0f 点。"%minf(30,a.capacity))
			return
		journal.close()
		stop_gu_training("")
		meditating=true
		meditation_seconds=0
		_action_message("开始冲窍：持续 30 秒，共耗当前普通真元 %.0f 点；移动、攻击、受伤或 J 收功会中断。"%minf(30,a.capacity))
		return
	_action_message(player.aperture.breakthrough())
	save_game()
	aperture_ui.refresh()

func _update_owned_gu(delta: float) -> void:
	var previous_guard:String=String(fx.gu.snapshot(self).get("guard",""))
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
	if active_light_gu()==null: player.light_support_id=""
	player.gu_effects.tick(delta,player,get_node("/root/Gus"))
	player.utility_gu.tick(delta,self)
	player.body_gu.tick(delta,self)
	if previous_guard!="" and not fx.gu.snapshot(self).has("guard"):
		fx.gu.guard_hit(player.position,previous_guard,0,true)
	var training:=player.boar_cultivation
	var training_gu:GuVirtual=get_node("/root/Gus").get_gu_by_id(training.active_id)
	var usable:bool=training_gu!=null and not training_gu.dead and training_gu.location!="bag"
	var moving:=false
	for key in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]:
		if Input.is_key_pressed(key): moving=true
	var was_training:bool=training.active_id!=""
	training.tick(delta,player.aperture,usable and not moving and not refining and not meditating and can_meditate())
	if was_training and training.active_id=="":
		_action_message("养力已停止，永久力量 %.0f%%；本游戏日已练 %.1f / 15 秒。" % [training.progress*100,training.daily_used])
	for c in player.captured:
		if refining and refine_target>=0 and refine_target<player.captured.size() and is_same(c,player.captured[refine_target]): continue
		c["progress"]=maxf(0,float(c.get("progress",0))-delta*0.12)

func active_light_gu() -> GuVirtual:
	var gu:GuVirtual=get_node("/root/Gus").get_gu_by_id(player.light_support_id)
	if gu==null or gu.dead or gu.location=="bag" or gu.template_id!="little_light": return null
	return gu

func stop_gu_training(message: String) -> void:
	if player.boar_cultivation.active_id=="": return
	player.boar_cultivation.active_id=""
	if message!="": _action_message(message)

func _run_canon_tests() -> void:
	var test:=CanonTests.new()
	await test.run(self)

func _run_inspection_tests() -> void:
	await NpcInspectionTests.new().run(self)

func _run_social_tests() -> void:
	await NpcSocialTests.new().run(self)

func _run_exchange_tests() -> void:
	await NpcExchangeTests.new().run(self)

func _run_art_tests() -> void:
	var test:=ArtAnimationTests.new()
	await test.run(self)

func _run_character_tests() -> void:
	var test:=CharacterSaveTests.new()
	await test.run(self)

func _run_customization_tests() -> void:
	await CharacterCustomizationTests.new().run(self)

func _run_status_tests() -> void:
	await PlayerStatusTests.new().run(self)

func _run_control_tests() -> void:
	await ControlsSettingsTests.new().run(self)

func _run_gu_vfx_tests() -> void:
	await GuVfxTests.new().run(self)

func _run_utility_gu_tests() -> void:
	await UtilityGuTests.new().run(self)

func _run_sixty_gu_tests() -> void:
	await SixtyGuTests.new().run(self)

func _run_body_gu_tests() -> void:
	await BodyGuTests.new().run(self)

func _run_hundred_gu_tests() -> void:
	await HundredGuTests.new().run(self)

func _run_gu_upgrade_tests() -> void:
	await GuUpgradeTests.new().run(self)

func _run_map_tests() -> void:
	set_process(false)
	start_game()
	var test:=CanonTests.new()
	test.game=self
	test._check_routes()
	await MapTests.new().run(test)
	print("MAPTEST checked=%d failures=%s"%[test.checked,str(test.failures)])
	get_tree().quit(0 if test.failures.is_empty() else 1)

func _run_village_tests() -> void:
	set_process(false)
	start_game()
	var test:=CanonTests.new()
	test.game=self
	test._check_routes()
	await SettlementTests.new().run(test)
	print("VILLAGETEST checked=%d failures=%s"%[test.checked,str(test.failures)])
	get_tree().quit(0 if test.failures.is_empty() else 1)

func set_waypoint(pos: Vector2, title: String, persist: bool = true, target_layer: int = 0) -> bool:
	if target_layer not in [0,1,2]: return false
	var bounds:=Rect2(Vector2.ZERO,TerrainLayers.extent(target_layer))
	if not pos.is_finite() or pos==Vector2.ZERO or not bounds.has_point(pos): return false
	waypoint=pos
	waypoint_name=title if not title.is_empty() else "自定标记"
	waypoint_notified=false
	waypoint_layer=target_layer
	if persist: save_game()
	return true

func clear_waypoint(persist: bool = true) -> void:
	waypoint=Vector2.ZERO
	waypoint_layer=0
	waypoint_name=""
	waypoint_notified=false
	if persist: save_game()

func waypoint_guidance() -> Dictionary:
	if shang_city.active: return {}
	if waypoint==Vector2.ZERO: return {}
	var target:=HouseInterior.ORIGIN+Vector2(0,184) if world.in_interior else waypoint
	var transition:=""
	if not world.in_interior and world.layer!=waypoint_layer:
		var portal:=world.blocks.navigation_portal(player.position,world.layer,waypoint_layer,waypoint)
		if not portal.is_empty(): target=portal.pos; transition=portal.name
	var delta:Vector2=target-player.position
	var directions:=["东","东南","南","西南","西","西北","北","东北"]
	var direction:String=directions[posmod(roundi(delta.angle()/(PI/4)),8)]
	var arrived:=not world.in_interior and world.layer==waypoint_layer and delta.length()<=48
	return {"target":target,"delta":delta,"steps":delta.length()/TILE,"direction":direction,"arrived":arrived,"indoors":world.in_interior,"transition":transition}

func _update_waypoint() -> void:
	if waypoint==Vector2.ZERO or world.in_interior or world.layer!=waypoint_layer or waypoint_notified: return
	if player.position.distance_to(waypoint)<=48:
		waypoint_notified=true
		add_log("已到达「%s」附近 · M 查看或取消标点"%waypoint_name,UIStyle.GOLD)

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
	if not world.on_surface() or site.is_empty() or site.id!=id or site.kind!="camp":
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
	if not world.on_surface() or site.is_empty() or site.kind!="camp": return false
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

func _run_terrain_tests() -> void:
	await TerrainTests.new().run(self)

func _take_terrain_shot(scenario: String) -> void:
	await TerrainTests.new().shot(self,scenario)

func _run_adventure_tests() -> void:
	await AdventureTests.new().run(self)


func guide_awakening() -> void:
	if world.in_interior and current_house_id=="spring_cave" and world.interior.interaction_at(player.position)=="spring_cave":
		open_awakening()
		return
	journal.close()
	village_ui.close()
	for house in World.HOUSE_DATA:
		if house.id=="spring_cave":
			set_waypoint(house.pos,"希望蛊 · 地下溶洞",true,0)
			_action_message("已标记地下溶洞；到洞口按 E 进入，走近花海与灵泉再按 E。")
			return

func open_awakening() -> void:
	if not running or player.dead: return
	journal.close()
	village_ui.close()
	awakening_ui.open()

func _run_awakening_tests() -> void:
	await AwakeningTests.new().run(self)
