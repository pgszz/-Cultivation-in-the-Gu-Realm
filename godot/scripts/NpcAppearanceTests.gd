class_name NpcAppearanceTests
extends RefCounted

var game: Node
var test := CanonTests.new()

func shot(label: String) -> void:
	await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error:=game.get_viewport().get_texture().get_image().save_png("res://shot_people_"+label+".png")
	test.expect(error==OK,"saved people evidence "+label)

func run(main: Node) -> void:
	game=main
	test.game=game
	game.set_process(false)
	await test.start_character()
	game.paused=true
	check_atlases()
	var seen:Dictionary={}
	var people:Array=[game.npc]
	people.append_array(game.residents.values())
	people.append_array(game.population.actors.values())
	for person:Npc in people:
		var appearance:=person.get_appearance()
		seen[appearance]=true
		test.expect(NpcAppearance.STYLES.has(appearance),"registered person has artwork: "+person.resident_id)
		var saved:=person.save_data()
		person.appearance_id=""
		person.load_data(saved)
		test.expect(person.get_appearance()==appearance,"appearance survives person load: "+person.resident_id)
	test.expect(seen.size()==NpcAppearance.STYLES.size(),"all registered appearances are assigned to real people")
	for clan in ["guyue","bai","xiong"]:
		var local:Dictionary={}
		for i in 4: local[game.population.actors[clan+"_civil_"+str(i)].get_appearance()]=true
		test.expect(local.size()==4,"neighboring villagers have four different silhouettes: "+clan)
		test.expect(game.population.actors[clan+"_patrol_0"].get_appearance()!=game.population.actors[clan+"_patrol_1"].get_appearance(),"patrol partners differ: "+clan)
	var party:Dictionary={}
	for id in game.population.caravan_ids: party[game.population.actors[id].get_appearance()]=true
	test.expect(party.size()==4,"merchant, porter and two escorts all differ")
	for id in ["east","south"]:
		test.expect(game.population.actors[id+"_bandit_0"].get_appearance()!=game.population.actors[id+"_bandit_1"].get_appearance(),"bandit partners differ: "+id)
	# Invalid/missing saves must recover deterministically, independent of RNG or other people.
	for person:Npc in [game.residents.bai_shop,game.population.actors.caravan_guard_b]:
		var initial:=NpcAppearance.choose(person.resident_id,person.appearance_role(),person.settlement_id)
		for invalid in [null,"missing_style",42,{"sheet":"invalid"}]:
			var saved:=person.save_data()
			saved["appearance"]=invalid
			person.load_data(saved)
			test.expect(person.get_appearance()==initial,"invalid appearance has stable fallback: "+person.resident_id)
		var legacy:=person.save_data()
		legacy.erase("appearance")
		person.appearance_id="red_bandit"
		person.load_data(legacy)
		test.expect(person.get_appearance()==initial,"legacy save restores the identity default: "+person.resident_id)
	# Verify the main save path, including a saved choice differing from the current default.
	game.residents.bai_shop.appearance_id="wine_merchant"
	game.population.actors.caravan_guard_b.appearance_id="brown_guard"
	game.save_game()
	game.residents.bai_shop.appearance_id="red_tunic"
	game.population.actors.caravan_guard_b.appearance_id="red_tunic"
	game._load_save()
	game.paused=true
	test.expect(game.residents.bai_shop.get_appearance()=="wine_merchant" and game.population.actors.caravan_guard_b.get_appearance()=="brown_guard","main character save restores fixed and moving people's chosen appearance")
	var person:WorldPerson=game.population.actors.caravan_merchant
	game.player.position=person.position+Vector2(0,36)
	person.show()
	game._update_camera(0)
	game.camera.reset_smoothing()
	game.paused=false
	game.inspect_person(person)
	var ui:NpcInspectUI=game.npc_inspect_ui
	test.expect(ui.visible and ui.portrait.texture.atlas==NpcAppearance.texture(person.get_appearance()) and ui.portrait.texture.region==NpcAppearance.region(person.get_appearance(),0),"inspection uses the same full-color appearance as the world actor")
	await shot("inspection")
	ui.close()
	var appearance:=person.get_appearance()
	var radius:=person.radius
	var goods:=person.save_possessions()
	person.receive_hit(9999,null)
	game.save_game()
	game._load_save()
	person=game.population.actors.caravan_merchant
	person.show()
	game.paused=false
	game.inspect_person(person)
	test.expect(person.dead and person.get_appearance()==appearance and person.radius==radius and person.save_possessions()==goods,"death and reload retain appearance, collision and real loot")
	test.expect(ui.visible and ui.portrait.texture.region==NpcAppearance.region(appearance,5),"corpse portrait uses the same person's fallen pose")
	await shot("corpse")
	ui.close()
	await gallery()
	print("APPEARANCETEST checked=%d failures=%s"%[test.checked,str(test.failures)])
	game.get_tree().quit(0 if test.failures.is_empty() else 1)

func check_atlases() -> void:
	for id:String in NpcAppearance.STYLES:
		var texture:=NpcAppearance.texture(id)
		test.expect(texture!=null,"appearance texture exists: "+id)
		if texture==null: continue
		if NpcAppearance.STYLES[id].sheet!="legacy":
			test.expect(texture.resource_path==NpcAppearance.SHEETS[NpcAppearance.STYLES[id].sheet],"new appearance resolves its own atlas, not a fallback: "+id)
		var source:=texture.get_image()
		var hashes:Dictionary={}
		for frame in 6:
			var region:=Rect2i(NpcAppearance.region(id,frame))
			var cell:=source.get_region(region)
			test.expect(Rect2i(Vector2i.ZERO,source.get_size()).encloses(region) and cell.get_used_rect().get_area()>500,"complete nonempty action cell: %s/%d"%[id,frame])
			hashes[hash(cell.get_data())]=true
			if NpcAppearance.STYLES[id].sheet!="legacy":
				var clear:=true
				for corner in [Vector2i(0,0),Vector2i(cell.get_width()-1,0),Vector2i(0,cell.get_height()-1),cell.get_size()-Vector2i.ONE]:
					clear=clear and cell.get_pixelv(corner).a<0.05
				test.expect(clear,"new sprite has transparent cell corners: %s/%d"%[id,frame])
		test.expect(hashes.size()==6,"six separate action drawings: "+id)

func gallery() -> void:
	# Review fixture renders the same Npc and ActorAnimation used by the world.
	game.paused=true
	var layer:=CanvasLayer.new()
	layer.layer=100
	game.add_child(layer)
	var size:Vector2=game.get_viewport_rect().size
	var background:=ColorRect.new()
	background.color=Color("172923")
	background.size=size
	layer.add_child(background)
	var title:=Label.new()
	title.position=Vector2(28,15)
	title.add_theme_font_size_override("font_size",26)
	title.add_theme_color_override("font_color",Color("e8ce96"))
	layer.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="%d 套人物外观 · 寨民 / 劳作者 / 护卫 / 商旅 / 原著人物" % NpcAppearance.STYLES.size()
	subtitle.position=Vector2(28,50)
	layer.add_child(subtitle)
	var samples:Array[Npc]=[]
	var index:=0
	var columns:=6
	var rows:=ceili(float(NpcAppearance.STYLES.size())/columns)
	var cell:=(size-Vector2(48,100))/Vector2(columns,rows)
	for id:String in NpcAppearance.STYLES:
		var origin:=Vector2(24+(index%columns)*cell.x,86+(index/columns)*cell.y)
		var tile:=ColorRect.new()
		tile.position=origin
		tile.size=cell-Vector2(8,8)
		tile.color=Color("243a31") if index%2==0 else Color("20362f")
		layer.add_child(tile)
		var sample:=Npc.new()
		sample.appearance_id=id
		sample.npc_name=""
		sample.player_pos=Vector2.INF
		sample.position=origin+Vector2((cell.x-8)*0.5,cell.y-49)
		var factor:=minf(1.65,(cell.y-35)/64.0)
		sample.scale=Vector2.ONE*factor
		layer.add_child(sample)
		sample.set_process(false)
		samples.append(sample)
		var label:=Label.new()
		label.text=NpcAppearance.STYLES[id].name
		label.position=origin+Vector2(0,cell.y-31)
		label.size=Vector2(cell.x-8,20)
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		layer.add_child(label)
		index+=1
	for stage in ["idle","walk_left","walk_right","strike","hurt","death"]:
		title.text="人物服装与动作 · "+{"idle":"站立","walk_left":"迈步一","walk_right":"迈步二","strike":"出拳","hurt":"受击","death":"倒地"}[stage]
		for sample in samples:
			sample.animation=ActorAnimation.new()
			if stage.begins_with("walk"):
				sample.animation.advance(0.1,true,0,1.0 if stage=="walk_left" else 33.0)
			elif stage!="idle":
				sample.animation.play(stage,0)
				sample.animation.advance(1.0 if stage=="death" else 0.15,false,0)
			sample.queue_redraw()
		await shot(stage)
	layer.queue_free()
