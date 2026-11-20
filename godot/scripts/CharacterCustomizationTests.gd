class_name CharacterCustomizationTests
extends RefCounted

const STATE := "user://customization_restart.json"
var test:=CanonTests.new()
var game: Node

func write(path: String, value: Variant) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(value if value is String else JSON.stringify(value))
	file.close()

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	test.expect(game.get_viewport().get_texture().get_image().save_png("res://shot_custom_"+name+".png")==OK,"screenshot "+name)

func visible_control(control: Control) -> void:
	var ancestor:=control.get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(control)
			break
		ancestor=ancestor.get_parent()
	await game.get_tree().process_frame
	await game.get_tree().process_frame

func finish() -> void:
	print("CUSTOMIZETEST checked=%d failures=%s"%[test.checked,str(test.failures)])
	game.get_tree().quit(0 if test.failures.is_empty() else 1)

func run(main: Node) -> void:
	game=main
	test.game=game
	game.set_process(false)
	var repo:CharacterSaves=game.character_saves
	var screen:StartScreen=game.start_screen
	var editor:AppearanceEditor=screen.appearance_editor
	if FileAccess.file_exists(STATE):
		var state:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(STATE))
		test.checked=int(state.checked)
		test.failures.assign(state.failures)
		var data:=repo.load_character(state.id)
		test.expect(data.get("appearance",{}).get("base")=="imported","restart retains chosen PNG model")
		test.expect(not FileAccess.file_exists("user://actor.png"),"original PNG is absent after restart")
		screen.select_character(state.id)
		await test.click(screen.start_button)
		test.expect(game.running and game.player.appearance.warning.is_empty(),"restart uses copied assets in actual world")
		test.expect(game.player.appearance.texture.get_image().get_data().hex_encode().sha256_text()==state.digest,"restart restores exact composed pixels")
		test.expect(repo.load_character(state.dead).is_empty(),"customized dead character stays locked after restart")
		test.expect(not repo.update_appearance(state.dead,{"base":"tailored"}),"editing cannot revive dead character after restart")
		await shot("restart")
		game.player_death("自定义角色死亡验证")
		await game.get_tree().create_timer(0.82).timeout
		test.expect(game.player.animation.frame()==5 and game.death_layer.visible,"real customized character reaches death pose and death menu")
		test.expect(repo.is_dead(state.id) and repo.load_character(state.id).is_empty(),"real player death locks customized save")
		test.expect(repo.appearance_for(state.id).actor_asset==data.appearance.actor_asset,"death preserves the fallen character's appearance")
		await shot("death")
		finish()
		return
	var malformed:=CharacterAppearance.normalize({"width":NAN,"height":9,"cloth":"not-a-color","actor_asset":"../other.png","style":-4})
	test.expect(malformed.width==1 and is_equal_approx(malformed.height,1.08) and malformed.cloth==CharacterAppearance.DEFAULTS.cloth and malformed.actor_asset=="" and malformed.style==0,"malformed visual fields are clamped or defaulted")
	test.expect(CharacterAppearance.normalize([])==CharacterAppearance.DEFAULTS,"legacy and wrong-type appearances safely default")
	await test.click(screen.create_button)
	screen.name_input.text="青衣游子"
	await test.click(screen.new_appearance_button)
	test.expect(editor.visible and screen.new_overlay.visible,"new character opens appearance editor without losing creation dialog")
	editor.controls.style.select(1)
	editor.controls.style.item_selected.emit(1)
	editor.controls.hair_style.select(1)
	editor.controls.hair_style.item_selected.emit(1)
	editor.controls.hem.value=0.9
	editor.controls.width.value=1.1
	editor.controls.cloth.color=Color("387e87")
	editor.controls.cloth.color_changed.emit(Color("387e87"))
	test.expect(editor.data.base=="tailored" and editor.data.style==1 and is_equal_approx(editor.data.width,1.1),"clothes and body controls change draft")
	var original_pixels:=editor.preview.appearance.texture.get_image().get_data()
	test.expect(original_pixels!=PaintedArt.HERO.get_image().get_data(),"preview renders the designed character")
	await shot("editor")
	await test.click(editor.confirm_button)
	test.expect(not editor.visible and repo.entries().is_empty(),"confirming new appearance does not create an unnamed save")
	await test.click(screen.create_confirm)
	var id:=screen.selected_id
	test.expect(not id.is_empty() and repo.load_character(id).appearance.style==1,"new role stores clothing design")
	test.expect(screen.portrait.appearance.data.cloth=="387e87","character selection uses saved appearance")
	await test.click(screen.appearance_button)
	editor.controls.width.value=0.8
	await test.click(editor.cancel_button)
	test.expect(is_equal_approx(repo.load_character(id).appearance.width,1.1),"cancel keeps existing appearance intact")
	await test.click(screen.appearance_button)
	editor.controls.pose.select(1)
	editor.controls.pose.item_selected.emit(1)
	await game.get_tree().create_timer(0.3).timeout
	test.expect(editor.preview.figure.animation.moving,"preview plays walking animation")
	for row in 4:
		editor.preview.facing=row
		await game.get_tree().process_frame
		test.expect(editor.preview.figure.animation.facing_row()==row,"preview direction "+str(row))
	test.expect(editor.export_template("user://actor.png",false)==OK,"export editable complete character atlas")
	test.expect(editor.export_template("user://outfit.png",true)==OK,"export transparent clothing layer atlas")
	var full:=CharacterAppearance.read_png("user://actor.png")
	var outfit:=CharacterAppearance.read_png("user://outfit.png")
	test.expect(full.has("image") and outfit.has("image"),"both exported templates pass import validation")
	if not full.has("image") or not outfit.has("image"):
		finish()
		return
	full.image.save_png("res://shot_custom_template.png")
	outfit.image.save_png("res://shot_custom_outfit.png")
	var clothing_only:=CharacterAppearance.new()
	clothing_only.configure(editor.data,"",{"outfit_asset":outfit.image})
	test.expect(clothing_only.texture.get_image().get_data()!=full.image.get_data(),"clothing-only import composites over the body instead of replacing the whole person")
	var fallback:=CharacterAppearance.new()
	fallback.configure({"base":"imported","actor_asset":"a".repeat(64)+".png"},"user://missing_art")
	test.expect(not fallback.warning.is_empty() and fallback.texture!=null,"missing model falls back to a visible built-in model")
	var extreme:=CharacterAppearance.DEFAULTS.duplicate(true)
	extreme.height=1.08
	extreme.width=1.2
	extreme.style=1
	extreme.hem=1
	extreme.sleeve=1
	extreme.base="tailored"
	CharacterAppearance.sheet(extreme).save_png("user://extreme.png")
	test.expect(CharacterAppearance.read_png("user://extreme.png").has("image"),"maximum body and clothing dimensions remain a valid atlas")
	for row in 4:
		var previous:=PackedByteArray()
		for frame in 6:
			var tile:Image=full.image.get_region(Rect2i(frame*256,row*256,256,256))
			test.expect(not tile.is_invisible() and tile.get_data()!=previous,"distinct visible pose row %d frame %d"%[row,frame])
			previous=tile.get_data()
	write("user://bad.png","This is not a PNG file, even though the extension says so.")
	test.expect(not editor.import_png("user://bad.png","actor_asset") and editor.images.is_empty(),"bad PNG leaves current design intact")
	var flat:=Image.create(128,128,false,Image.FORMAT_RGBA8)
	flat.fill(Color.WHITE)
	flat.save_png("user://wrong_size.png")
	test.expect(not editor.import_png("user://wrong_size.png","actor_asset"),"wrong image grid rejected")
	var empty:=Image.create(768,512,false,Image.FORMAT_RGBA8)
	empty.save_png("user://empty.png")
	test.expect(not editor.import_png("user://empty.png","outfit_asset"),"invisible sheet rejected")
	empty.fill(Color.WHITE)
	empty.save_png("user://opaque.png")
	test.expect(not editor.import_png("user://opaque.png","outfit_asset"),"opaque background rejected")
	var missing:Image=full.image.duplicate()
	missing.fill_rect(Rect2i(256,0,256,256),Color.TRANSPARENT)
	missing.save_png("user://missing_frame.png")
	test.expect(not editor.import_png("user://missing_frame.png","actor_asset"),"missing required animation rejected")
	await visible_control(editor.import_actor)
	await test.click(editor.import_actor)
	test.expect(editor.file_dialog.visible and editor.file_dialog.file_mode==FileDialog.FILE_MODE_OPEN_FILE,"import button opens filesystem PNG picker")
	editor.file_dialog.file_selected.emit(ProjectSettings.globalize_path("user://actor.png"))
	editor.file_dialog.hide()
	test.expect(editor.data.base=="imported" and editor.images.has("actor_asset"),"picker selection previews imported actor")
	test.expect(editor.import_png("user://outfit.png","outfit_asset"),"clothing PNG layers onto actor")
	await shot("import")
	await test.click(editor.cancel_button)
	test.expect(not DirAccess.dir_exists_absolute(repo.art_directory(id)),"cancelled PNG import creates no persistent assets")
	await test.click(screen.appearance_button)
	editor.import_png("user://actor.png","actor_asset")
	editor.import_png("user://outfit.png","outfit_asset")
	await test.click(editor.confirm_button)
	var saved:=repo.load_character(id)
	test.expect(saved.appearance.base=="imported" and saved.appearance.actor_asset!="" and saved.appearance.outfit_asset!="","confirm stores both imported layers")
	var art_folder:=repo.art_directory(id)
	test.expect(DirAccess.get_files_at(art_folder).size()==2,"assets are copied into role folder")
	DirAccess.remove_absolute("user://actor.png")
	DirAccess.remove_absolute("user://outfit.png")
	var reloaded:=CharacterAppearance.new()
	reloaded.configure(saved.appearance,art_folder)
	test.expect(reloaded.warning.is_empty(),"moving original imports does not break saved appearance")
	var other:=repo.create_character("独立衣装",{"base":"tailored","cloth":"a54045"})
	test.expect(repo.appearance_for(other).cloth=="a54045" and repo.appearance_for(id).cloth=="387e87","characters retain independent colors")
	var copy:=repo.create_character("副本衣装",saved.appearance,{"actor_asset":full.image,"outfit_asset":outfit.image})
	test.expect(copy!="" and DirAccess.get_files_at(repo.art_directory(copy)).size()==2,"same imported model can be copied to another role")
	test.expect(repo.delete_character(copy) and not DirAccess.dir_exists_absolute(repo.art_directory(copy)),"deletion cleans only that role's imported PNGs")
	test.expect(DirAccess.get_files_at(art_folder).size()==2,"deleting a second role preserves the first role's images")
	var replace:=repo.create_character("更换衣装",saved.appearance,{"actor_asset":full.image,"outfit_asset":outfit.image})
	var copied_path:=repo.art_directory(replace).path_join(saved.appearance.actor_asset)
	write(copied_path,"damaged image contents are deliberately invalid")
	test.expect(repo.update_appearance(replace,saved.appearance,{"actor_asset":full.image}),"reimport repairs an existing corrupted image")
	test.expect(repo.update_appearance(replace,{"base":"tailored"}) and not DirAccess.dir_exists_absolute(repo.art_directory(replace)),"switching away and removing imports clears unused images")
	repo.delete_character(replace)
	var transaction:=repo.create_character("换装事务",{"base":"tailored"})
	var previous:=FileAccess.get_file_as_string(repo.path_for(transaction))
	DirAccess.make_dir_recursive_absolute(repo.path_for(transaction)+".tmp")
	test.expect(not repo.update_appearance(transaction,{"base":"imported"},{"actor_asset":full.image}),"failed appearance save is reported")
	test.expect(FileAccess.get_file_as_string(repo.path_for(transaction))==previous and not DirAccess.dir_exists_absolute(repo.art_directory(transaction)),"failed save keeps old design and discards newly copied assets")
	DirAccess.remove_absolute(repo.path_for(transaction)+".tmp")
	repo.delete_character(transaction)
	var dead:=repo.create_character("故人衣冠",saved.appearance,{"actor_asset":full.image,"outfit_asset":outfit.image})
	test.expect(repo.mark_dead(dead,game._snapshot(),"外观回归测试"),"customized role can be marked permanently dead")
	test.expect(not repo.update_appearance(dead,{"base":"tailored"}) and repo.load_character(dead).is_empty(),"appearance editing cannot revive a dead role")
	screen.select_character(dead)
	test.expect(screen.appearance_button.disabled and screen.start_button.disabled,"fallen role disables both wardrobe and play")
	screen.select_character(id)
	await shot("selection")
	await test.click(screen.start_button)
	test.expect(game.running and game.player.appearance.data.actor_asset==saved.appearance.actor_asset,"actual player loads selected imported model")
	test.expect(game.player.radius==12 and game.player.speed==168,"cosmetics do not change movement and collision")
	var animation:ActorAnimation=game.player.animation
	for row in 4:
		animation.restore_dead(false)
		animation.advance(0.16,true,[PI/2,PI,-PI/2,0][row],20)
		test.expect(animation.facing_row()==row and animation.frame()==0,"world animation retains directional walking")
	for action in ["strike","cast","hurt","death"]:
		animation.restore_dead(false)
		animation.play(action,0)
		animation.advance(0.25,false,0)
		test.expect(animation.action==action,"custom model accepts real action "+action)
	animation.restore_dead(false)
	game.player.queue_redraw()
	game.open_journal("character")
	await game.get_tree().process_frame
	test.expect(game.character_ui.portrait.appearance.texture==game.player.appearance.texture,"character panel shares world model texture")
	await shot("panel")
	await test.key(KEY_ESCAPE)
	game.fog.reveal(game.player.position,500)
	await shot("world")
	test.expect(game.save_game(),"full gameplay save preserves appearance")
	var restored:=repo.load_character(id)
	test.expect(restored.appearance.actor_asset==saved.appearance.actor_asset,"game save does not drop imported references")
	write(STATE,{"id":id,"dead":dead,"digest":game.player.appearance.texture.get_image().get_data().hex_encode().sha256_text(),"checked":test.checked,"failures":test.failures})
	finish()
