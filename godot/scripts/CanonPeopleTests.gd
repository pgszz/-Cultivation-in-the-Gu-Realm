class_name CanonPeopleTests
extends RefCounted

var game: Node
var test := CanonTests.new()

func shot(label: String) -> void:
	await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error:=game.get_viewport().get_texture().get_image().save_png("res://shot_canon_people_"+label+".png")
	test.expect(error==OK,"named people screenshot "+label)

func approach(person: WorldPerson) -> void:
	person.target=null
	person.flee_left=0
	for offset in [Vector2(0,24),Vector2(24,0),Vector2(-24,0),Vector2(0,-24)]:
		var pos:Vector2=person.position+offset
		if not game.world.collides(pos.x,pos.y,12) and game.world.conversation_clear(pos,person.position):
			game.player.position=pos
			break
	game.fog.reveal(game.player.position,game.fog.radius_world())
	person.show()
	game._update_camera(0)
	game.camera.reset_smoothing()
	game.paused=false

func run(main: Node) -> void:
	game=main
	test.game=main
	game.set_process(false)
	await test.start_character()
	game.paused=true
	var seen:Dictionary={}
	for id in CanonPeople.ORDER:
		var person:WorldPerson=game.population.actors[id]
		test.expect(person in game.active_npcs() and person.get_appearance()==id,"named identity is an actual distinct world person "+id)
		test.expect(not game.population.outdoor_blocked(person.position),"named person spawns on walkable ground "+id)
		test.expect(person.route.size()>1 and person.route_names.size()==person.route.size(),"named person has usable destinations "+id)
		test.expect(NpcAppearance.texture(id).resource_path.ends_with("canon/qing_mao.png"),"named person resolves the independent artwork "+id)
		for frame in 6:
			var region:=NpcAppearance.region(id,frame)
			seen[str(region)]=true
		test.expect(NpcAppearance.restore("red_bandit",id)==id and NpcAppearance.restore("canon_qing_shu",id)==id,"saved unrelated appearance cannot replace a named face "+id)
		var save:=person.save_data()
		save.erase("appearance")
		person.load_data(save)
		test.expect(person.get_appearance()==id,"missing visual fields recover canon identity "+id)
		person.target=null
		game.population.find_target(person)
		test.expect(person.target==null,"named actor is not forced into a generic bandit-hunting escort role "+id)
	test.expect(seen.size()==24,"four identities have separate cells for all six actions")
	# A save written before this feature adds each new actor once without changing old people.
	var legacy:Dictionary=game.population.save_data()
	for id in CanonPeople.ORDER: legacy.people.erase(id)
	legacy.people.caravan_merchant.hp=47.0
	game.population.load_data(legacy)
	test.expect(game.population.actors.size()==34 and game.population.actors.caravan_merchant.hp==47,"legacy population gains four identities without overwriting existing state")
	game.population.load_data(game.population.save_data())
	test.expect(game.population.actors.size()==34,"repeated load does not duplicate named actors")
	var replies:Dictionary={}
	for id in CanonPeople.ORDER:
		var person:WorldPerson=game.population.actors[id]
		approach(person)
		test.expect(game.person_talk_blocker(person)=="","named actor reachable for a real conversation "+id)
		game.talk_to_person(person)
		test.expect(game.village_ui.visible and game.village_ui.title.text.contains(person.npc_name),"named actor opens the main conversation panel "+id)
		var response:=NpcConversation.reply(game,person,"life")
		replies[response]=true
		test.expect(person.conversation.has("life") and not person.social.history.is_empty(),"custom dialogue records social history "+id)
		game.village_ui.show_conversation(person,response)
		if id=="canon_fang_yuan": await shot("talk")
		game.village_ui.close()
		game.inspect_person(person)
		var ui:NpcInspectUI=game.npc_inspect_ui
		test.expect(ui.visible and ui.portrait.texture.region==NpcAppearance.region(id,0),"inspect portrait matches live character "+id)
		await test.click(ui.tabs.canon)
		test.expect(ui.active_tab=="canon" and ui.details.text==CanonPeople.lore(id),"canon tab is reachable through actual GUI input "+id)
		if id in ["canon_fang_yuan","canon_bai_ning_bing"]: await shot(id.trim_prefix("canon_"))
		ui.close()
	test.expect(replies.size()==4,"all four characters speak with separate scripted responses")
	var brother:WorldPerson=game.population.actors.canon_fang_yuan
	var younger:WorldPerson=game.population.actors.canon_fang_zheng
	test.expect(brother.social.relations(brother).any(func(bond:Dictionary): return bond.id==younger.resident_id and bond.kind.contains("孪生弟弟")),"known twin kinship replaces generic same-clan relation")
	approach(brother)
	await test.key(KEY_E)
	test.expect(game.village_ui.visible and game.village_ui.title.text.contains(brother.npc_name),"E interacts with the nearby named person in the actual scene")
	game.village_ui.close()
	game._process(0.016)
	await shot("world")
	await test.key(KEY_M)
	var map:MiniMapUI=game.minimap_ui
	await test.click(map.people_button)
	test.expect(map.mode=="people" and map.people_mark_buttons.size()==4,"map directory exposes all named characters")
	await shot("directory")
	await test.click(map.people_mark_buttons.canon_fang_yuan)
	test.expect(map.mode=="local" and game.waypoint_layer==0 and game.waypoint_name.contains(brother.npc_name),"directory button produces a surface waypoint with a character name")
	game.journal.close()
	# Position, conversation, hostility and death use the existing character save, not a parallel file.
	brother.position=game.population.walkable_position(Vector2(464,1104))
	brother.wait_left=9.0
	var saved_position:=brother.position
	var saved_hp:=younger.hp
	game.save_game()
	game._load_save()
	brother=game.population.actors.canon_fang_yuan
	test.expect(brother.position==saved_position and brother.wait_left==9 and brother.conversation.has("life"),"main save restores named position schedule and dialogue")
	test.expect(game.population.actors.canon_fang_zheng.hp==saved_hp,"one twin's changes do not mutate the other twin")
	approach(brother)
	brother.take_damage(9999,game)
	game._load_save()
	brother=game.population.actors.canon_fang_yuan
	test.expect(brother.dead and brother.hp==0 and brother.hostile and brother.animation.action=="death","named death and hostility survive reload without respawn")
	approach(brother)
	game.inspect_person(brother)
	test.expect(game.npc_inspect_ui.visible and game.npc_inspect_ui.portrait.texture.region==NpcAppearance.region(brother.resident_id,5),"dead named character keeps its own fallen model")
	test.expect(game.person_talk_blocker(brother)!="","dead named person refuses conversation")
	await shot("death")
	game.npc_inspect_ui.close()
	await gallery()
	print("CANONPEOPLETEST checked=%d failures=%s" % [test.checked,str(test.failures)])
	game.get_tree().quit(0 if test.failures.is_empty() else 1)

func gallery() -> void:
	game.paused=true
	var layer:=CanvasLayer.new()
	layer.layer=100
	game.add_child(layer)
	var size:Vector2=game.get_viewport_rect().size
	var background:=ColorRect.new()
	background.color=Color("102321")
	background.size=size
	layer.add_child(background)
	var title:=UIStyle.label("青 茅 人 物  /  前期原著形象",28,UIStyle.GOLD)
	title.position=Vector2(28,18)
	layer.add_child(title)
	var subtitle:=UIStyle.label("独立动作与头像 · 双胞胎相貌相似 · 白凝冰为早期男性 · 青书保留青色长发",14,UIStyle.DIM)
	subtitle.position=Vector2(28,58)
	layer.add_child(subtitle)
	var width:=(size.x-56)/4.0
	for i in CanonPeople.ORDER.size():
		var id:String=CanonPeople.ORDER[i]
		var data:Dictionary=CanonPeople.PEOPLE[id]
		var origin:=Vector2(20+i*width,98)
		var tile:=ColorRect.new()
		tile.position=origin
		tile.size=Vector2(width-8,size.y-126)
		tile.color=Color("1d3530")
		layer.add_child(tile)
		var name:=UIStyle.label(data.name,23,UIStyle.GOLD)
		name.position=origin+Vector2(16,12)
		layer.add_child(name)
		var caption:=UIStyle.label(data.title,13,UIStyle.DIM)
		caption.position=origin+Vector2(16,46)
		layer.add_child(caption)
		var factor:=minf((size.y-255)/100.0,3.8)
		var baseline:=origin.y+70+64*factor
		var sample:=Npc.new()
		sample.resident_id=id
		sample.appearance_id=id
		sample.npc_name=""
		sample.player_pos=Vector2.INF
		sample.position=Vector2(origin.x+width*0.48,baseline)
		sample.scale=Vector2.ONE*factor
		layer.add_child(sample)
		sample.set_process(false)
		for action in 3:
			var actor:=Npc.new()
			actor.resident_id=id
			actor.appearance_id=id
			actor.npc_name=""
			actor.player_pos=Vector2.INF
			actor.position=Vector2(origin.x+(action+0.5)*(width-8)/3,size.y-82)
			actor.scale=Vector2.ONE*1.12
			layer.add_child(actor)
			actor.set_process(false)
			if action==0: actor.animation.advance(0.1,true,0,1.0)
			else:
				actor.animation.play("strike" if action==1 else "death",0)
				actor.animation.advance(0.15 if action==1 else 1.0,false,0)
			actor.queue_redraw()
			var label:=UIStyle.label(["行走","出手","倒地"][action],12,UIStyle.DIM)
			label.position=Vector2(origin.x+action*(width-8)/3,size.y-54)
			label.size=Vector2((width-8)/3,20)
			label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			layer.add_child(label)
	await shot("gallery")
	layer.queue_free()
