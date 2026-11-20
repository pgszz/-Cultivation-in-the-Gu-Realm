class_name CharacterSaveTests
extends RefCounted

const STATE := "user://character_test_state.json"
var game: Node
var test := CanonTests.new()
var state := {}

func write(path: String, data: Variant) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(data if data is String else JSON.stringify(data))
	file.close()

func next(phase: int) -> void:
	state.phase=phase
	state.checked=test.checked
	state.failures=test.failures
	write(STATE,state)

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	test.expect(game.get_viewport().get_texture().get_image().save_png("res://shot_characters_"+name+".png")==OK,"saved character screen "+name)

func create(title: String) -> String:
	var screen:StartScreen=game.start_screen
	await test.click(screen.create_button)
	test.expect(screen.new_overlay.visible,"new character dialog opens")
	screen.name_input.text=title
	await test.click(screen.create_confirm)
	test.expect(not screen.new_overlay.visible and screen.identity.text==title,"GUI creates and selects "+title)
	return screen.selected_id

func repository_checks() -> void:
	var repo:=CharacterSaves.new("user://character_unit")
	var snapshot:Dictionary=game._snapshot()
	for title in ["","  ","../bad","方[源]","abcdefghijklmnopq"]:
		test.expect(repo.create_character(title).is_empty(),"reject invalid name "+title)
	var id:=repo.create_character("独立存档")
	test.expect(not id.is_empty(),"create independent repository profile")
	test.expect(repo.create_character("独立存档").is_empty(),"duplicate names rejected")
	test.expect(repo.path_for("../../canon_save").is_empty() and repo.load_character("../../canon_save").is_empty(),"path traversal rejected")
	test.expect(repo.save_character(id,snapshot),"complete snapshot saves atomically")
	var original:=FileAccess.get_file_as_string(repo.path_for(id))
	DirAccess.make_dir_recursive_absolute(repo.path_for(id)+".tmp")
	test.expect(not repo.save_character(id,snapshot),"failed temporary write reported")
	test.expect(FileAccess.get_file_as_string(repo.path_for(id))==original,"failed save preserves previous file")
	test.expect(repo.mark_dead(id,snapshot,"测试致命伤"),"death marker survives failed snapshot write")
	DirAccess.remove_absolute(repo.path_for(id)+".tmp")
	write(repo.path_for(id),original)
	CharacterSaves.session_dead.clear()
	var reopened:=CharacterSaves.new(repo.directory)
	test.expect(reopened.load_character(id).is_empty() and reopened.entries()[0].status=="dead","disk marker rejects restored living snapshot after memory reset")
	test.expect(not reopened.save_character(id,snapshot),"normal save cannot resurrect locked character")
	test.expect(reopened.delete_character(id) and reopened.entries().is_empty(),"dead character can be deleted")
	test.expect(not reopened.save_character(id,snapshot),"late save cannot recreate deleted profile")
	var id2:=repo.create_character("独立存档")
	test.expect(not id2.is_empty() and id2!=id,"deleted name can be reused with a new identity")
	write(repo.path_for(id2),"{broken")
	test.expect(repo.entries()[0].status=="corrupt" and repo.load_character(id2).is_empty(),"malformed JSON is shown but not loaded")
	for malformed in [{"version":99},{"version":8,"body":{"parts":[]}},{"version":8,"aperture":{"stage":[]}},{"version":8,"gus":[42]},{"version":8,"position":[{},0]}]:
		write(repo.path_for(id2),malformed)
		test.expect(repo.load_character(id2).is_empty(),"reject unsupported or malformed snapshot "+str(malformed))
	test.expect(repo.delete_character(id2),"corrupt snapshot may be deleted")
	var legacy_path:="user://legacy_fixture.json"
	var old:=snapshot.duplicate(true)
	old.version=7
	write(legacy_path,old)
	var legacy_text:=FileAccess.get_file_as_string(legacy_path)
	test.expect(repo.import_legacy(legacy_path),"legacy v7 imports")
	test.expect(repo.load_character("legacy").get("profile",{}).get("name")=="旧角色","legacy appears as named profile")
	test.expect(repo.import_legacy(legacy_path) and repo.entries().size()==1,"legacy import is idempotent")
	test.expect(FileAccess.get_file_as_string(legacy_path)==legacy_text,"legacy source remains unchanged")
	test.expect(repo.delete_character("legacy") and repo.import_legacy(legacy_path) and repo.entries().is_empty(),"deleted legacy does not reappear")
	for version in [4,5,6,7]:
		var compatible:=CharacterSaves.new("user://legacy_v"+str(version))
		old.version=version
		write(legacy_path,old)
		test.expect(compatible.import_legacy(legacy_path) and not compatible.load_character("legacy").is_empty(),"legacy version %d accepted"%version)
	var dead_legacy:=CharacterSaves.new("user://legacy_dead")
	old.hp=0
	write(legacy_path,old)
	test.expect(dead_legacy.import_legacy(legacy_path) and dead_legacy.load_character("legacy").is_empty(),"legacy zero HP cannot resurrect")
	var blocked:=CharacterSaves.new("user://character_blocker")
	write(blocked.directory,"not a directory")
	test.expect(blocked.create_character("不可写").is_empty() and not blocked.last_error.is_empty(),"creation failure is reported")
	test.expect(not blocked.mark_dead("c_0123456789",snapshot,"失败测试") and blocked.is_dead("c_0123456789"),"total write failure reports failure and keeps session death lock")

func run(main: Node) -> void:
	game=main
	test.game=main
	game.set_process(false)
	if FileAccess.file_exists(STATE):
		state=JSON.parse_string(FileAccess.get_file_as_string(STATE))
		test.checked=int(state.checked)
		test.failures.assign(state.failures)
	var phase:=int(state.get("phase",0))
	var screen:StartScreen=game.start_screen
	var repo:CharacterSaves=game.character_saves
	var inv:Inventory=game.get_node("/root/Inv")
	var gus:GuManager=game.get_node("/root/Gus")
	test.expect(not game.started and screen.visible,"scene opens at character selection")
	if phase==0:
		repository_checks()
		test.expect(screen.start_button.disabled and screen.delete_button.disabled,"empty roster disables enter/delete")
		await test.click(screen.create_button)
		await test.click(screen.create_confirm)
		test.expect(screen.new_overlay.visible and not screen.name_error.text.is_empty(),"empty name remains in creation UI with error")
		await test.click(screen.create_cancel)
		state.a=await create("山行客")
		state.b=await create("听雨人")
		await test.click(screen.create_button)
		screen.name_input.text="山行客"
		await test.click(screen.create_confirm)
		test.expect(screen.new_overlay.visible and repo.entries().size()==2,"duplicate GUI creation preserves both profiles")
		await test.click(screen.create_cancel)
		await test.click(screen.card_buttons[state.a])
		test.expect(screen.selected_id==state.a,"real card click selects character")
		test.expect(game.get_viewport_rect().encloses(screen.start_button.get_global_rect()),"enter button fits viewport")
		await shot("selection")
		await test.click(screen.start_button)
		test.expect(game.started and game.character_id==state.a and game.character_name=="山行客","GUI enters selected character")
		test.expect(game.player.rank==0 and game.player.yuan==0 and game.player.captured.is_empty(),"new character is mortal before save-isolation fixture")
		test.expect(inv.has_item("moon_petals",10) and gus.owned_gus.is_empty(),"new character has canonical starter inventory")
		CanonTests.prepare_cultivator(game)
		inv.items["timber"]=17
		game.player.crystals=321
		game.player.body.apply_hit("hand_l",5)
		state.arm_hp=game.player.body.parts.hand_l.hp
		var gu:GuVirtual=gus.add_gu("moon_blade")
		gu.location="aperture"
		game.player.owned.append("moon_blade")
		state.gu=gu.id
		game._sync_owned_gus()
		game.player.skill_slots[0]=gu.id
		game.visited_sites["test_site"]=true
		game.claimed_camps["test_camp"]=true
		game.commissions.states["village_errand"]={"accepted":true,"completed":2,"remaining":10.0}
		# Use a real commission ID so its reader retains the record.
		var order_id:String=CommissionLedger.ORDERS.keys()[0]
		game.commissions.states[order_id]={"accepted":true,"completed":2,"remaining":10.0}
		state.order=order_id
		var object_id:String=game.world.destruction.objects.keys()[0]
		game.world.destruction.objects[object_id].hp=0
		state.object=object_id
		game.play_time=123
		await test.key(KEY_ESCAPE)
		next(1)
		await test.click(game.pause_layer.get_meta("vbox").get_node("ReturnCharacters"))
		return
	if phase==1:
		test.expect(repo.entries().size()==2 and screen.selected_id==state.a,"return remembers selection and both profiles")
		await test.click(screen.card_buttons[state.b])
		await test.click(screen.start_button)
		test.expect(game.character_id==state.b and game.player.crystals==60 and not inv.items.has("timber"),"second character has independent currency/inventory")
		test.expect(gus.owned_gus.is_empty() and gus.active_gu==null and game.get_node("/root/Hunger").gu_data.is_empty(),"new character clears previous gu and hunger references")
		test.expect(game.player.body.parts.hand_l.hp==game.player.body.parts.hand_l.max_hp and game.visited_sites.is_empty() and game.claimed_camps.is_empty(),"second body/exploration/camps are fresh")
		test.expect(not game.world.destruction.broken(state.object) and game.commissions.states.is_empty(),"second world and commissions are independent")
		game.player.hp=1
		game.player.iframes=0
		game.damage_player(2,"physical")
		test.expect(game.player.dead and FileAccess.file_exists(repo.directory.path_join(state.b+".dead")),"HP death locks disk immediately")
		test.expect(game.player.animation.action=="death" and not game.death_layer.visible,"lock precedes death animation and modal")
		test.expect(not game.save_game() and repo.load_character(state.b).is_empty(),"dead character cannot save alive or load")
		await game.get_tree().create_timer(1.3).timeout
		test.expect(game.death_layer.visible,"death animation finishes with character-return menu")
		await shot("death")
		next(2)
		await test.click(game.death_layer.get_meta("vbox").get_node("ReturnCharacters"))
		return
	if phase==2:
		CharacterSaves.session_dead.clear()
		test.expect(screen.selected_id==state.b and screen.start_button.disabled and not screen.delete_button.disabled,"dead profile cannot enter but can be deleted")
		game.start_game(state.b)
		test.expect(not game.started,"direct start also refuses death after scene reload and memory reset")
		await shot("fallen")
		await test.click(screen.card_buttons[state.a])
		await test.click(screen.start_button)
		test.expect(game.character_id==state.a and game.player.crystals==321 and inv.items.get("timber")==17,"return button saved first character currency and inventory")
		test.expect(gus.owned_gus.size()==1 and gus.owned_gus[0].id==state.gu and game.player.skill_slots[0]==state.gu,"gu identity and skill slot survive switching")
		test.expect(game.player.body.parts.hand_l.hp==state.arm_hp and game.play_time==123,"injury and play time persist")
		test.expect(game.world.destruction.broken(state.object) and game.visited_sites.has("test_site") and game.claimed_camps.has("test_camp"),"world damage and exploration survive switching")
		test.expect(game.commissions.states[state.order].completed==2,"commissions survive switching")
		game.player.body.apply_hit("head",9999)
		test.expect(game.player.dead and repo.is_dead(state.a) and repo.load_character(state.a).is_empty(),"body death signal also locks character")
		await game.get_tree().create_timer(1.3).timeout
		next(3)
		await test.click(game.death_layer.get_meta("vbox").get_node("ReturnCharacters"))
		return
	if phase==3:
		await test.click(screen.card_buttons[state.b])
		await test.click(screen.delete_button)
		test.expect(screen.delete_overlay.visible and "听雨人" in screen.delete_text.text,"delete confirmation names exact character")
		await shot("delete")
		await test.click(screen.delete_cancel)
		test.expect(repo.entries().size()==2,"cancel deletion preserves both characters")
		await test.click(screen.delete_button)
		await test.click(screen.delete_confirm)
		test.expect(repo.entries().size()==1 and repo.entries()[0].id==state.a,"delete removes only selected character")
		test.expect(not FileAccess.file_exists(repo.path_for(state.b)) and not FileAccess.file_exists(repo.directory.path_join(state.b+".dead")),"deleted snapshot and death record removed")
		await test.click(screen.delete_button)
		await test.click(screen.delete_confirm)
		test.expect(repo.entries().is_empty() and screen.start_button.disabled,"all profiles deleted yields usable empty roster")
		await shot("empty")
		state.c=await create("新的山行客")
		await test.click(screen.start_button)
		test.expect(game.player.hp>0 and not game.player.dead and not inv.items.has("timber") and gus.owned_gus.is_empty(),"fresh life does not inherit dead characters")
		game.player.crystals=1234
		# Leave via the same guard used by the OS close notification, then reload its disk snapshot.
		test.expect(game._save_before_leaving(),"window-close save guard succeeds")
		test.expect(repo.load_character(state.c).crystals==1234,"window-close guard persists last mutation")
		next(4)
		game.return_to_characters()
		return
	if phase==4:
		test.expect(repo.entries().size()==1 and screen.selected_id==state.c,"deleted characters do not return after scene rebuild")
		await test.click(screen.start_button)
		test.expect(game.character_id==state.c and game.player.crystals==1234,"last living character loads saved close state")
		state.locked=repo.create_character("重启锁档")
		var living:Dictionary=game._snapshot()
		test.expect(repo.save_character(state.locked,living),"prepare restart snapshot")
		var old_text:=FileAccess.get_file_as_string(repo.path_for(state.locked))
		test.expect(repo.mark_dead(state.locked,living,"重启测试"),"persist restart death lock")
		write(repo.path_for(state.locked),old_text)
		repo.remember_selection(state.c)
		game.player.crystals=4321
		next(5)
		print("CHARACTERTEST checked=%d failures=%s"%[test.checked,str(test.failures)])
		# The runner starts a new OS process with the same isolated user directory.
		game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		return
	if phase==5:
		test.expect(CharacterSaves.session_dead.is_empty(),"new engine process has no in-memory death registry")
		test.expect(repo.is_dead(state.locked) and repo.load_character(state.locked).is_empty(),"process restart rejects healthy snapshot with death marker")
		test.expect(repo.load_character(state.a).is_empty() and repo.load_character(state.b).is_empty(),"deleted profiles remain absent after process restart")
		game.start_game(state.c)
		test.expect(game.player.crystals==4321,"OS close notification saved final mutation before process restart")
		print("CHARACTERTEST checked=%d failures=%s"%[test.checked,str(test.failures)])
		game.get_tree().quit(0 if test.failures.is_empty() else 1)
