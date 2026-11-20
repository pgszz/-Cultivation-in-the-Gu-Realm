class_name SouthernBorderTests
extends RefCounted

func run(test: CanonTests) -> void:
	var game:Node=test.game
	var before:=test.checked
	var ids:Dictionary={}
	for row in SouthernBorderData.SITES:
		test.expect(not ids.has(row.id) and Rect2(Vector2.ZERO,SouthernBorderData.EXTENT).has_point(row.pos),"south map unique in-bounds site "+row.id)
		ids[row.id]=true
		var valid_sources:bool=not row.sources.is_empty()
		for source in row.sources: valid_sources=valid_sources and SouthernBorderData.SOURCES.has(source)
		for clan_id in row.get("clans",[]): valid_sources=valid_sources and not SouthernBorderData.clan(clan_id).is_empty()
		test.expect(valid_sources and not row.reading.is_empty(),"south site has provenance, interpretation and valid clan links "+row.id)
	var super_count:=0
	ids.clear()
	for row in SouthernBorderData.CLANS:
		test.expect(not ids.has(row.id) and (row.site=="" or not SouthernBorderData.site(row.site).is_empty()),"clan has unique identity and optional valid site "+row.id)
		ids[row.id]=true
		if row.tier=="超级家族": super_count+=1
	test.expect(super_count==13 and SouthernBorderData.clan("bai").site!=SouthernBorderData.clan("bai_hundred").site,"late thirteen-clan registry and distinct white/hundred clans")
	test.expect(SouthernBorderData.clan("yang").name=="羊家" and SouthernBorderData.site("guishou").kind=="家族资源地","Yang spelling and resource site do not invent a headquarters")
	test.expect(SouthernBorderData.site("wanshe").pos.x<SouthernBorderData.site("dapeng").pos.x and SouthernBorderData.site("guishou").pos.y>SouthernBorderData.site("wanshe").pos.y,"western family relative positions preserve text evidence")
	test.expect(SouthernBorderData.site("renyan").pos.y<SouthernBorderData.site("red_blue").pos.y and SouthernBorderData.site("dazhai").pos.y>SouthernBorderData.site("red_blue").pos.y and SouthernBorderData.site("yanshou").pos.x>SouthernBorderData.site("red_blue").pos.x,"Chai Ba Xia retain north south east relations at river junction")
	var intersects:=false
	var blue:Array=SouthernBorderData.RIVERS[1].points
	var yellow:Array=SouthernBorderData.RIVERS[2].points
	for a in range(1,blue.size()):
		for b in range(1,yellow.size()):
			if Geometry2D.segment_intersects_segment(blue[a-1],blue[a],yellow[b-1],yellow[b])!=null: intersects=true
	test.expect(not intersects,"blue and yellow rivers never intersect in schematic")
	game.journal.open_page("map")
	game.minimap_ui.set_mode("local")
	game.set_waypoint(Vector2(640,1040),"保留本地目的地")
	var position:Vector2=game.player.position
	var waypoint:Vector2=game.waypoint
	var layer:int=game.world.layer
	await test.click(game.minimap_ui.south_button)
	var ui:SouthernBorderUI=game.minimap_ui.southern
	var atlas:=ui.map
	atlas.fit_map()
	await game.get_tree().process_frame
	test.expect(ui.is_visible_in_tree() and not game.minimap_ui.main_columns.visible,"actual south button opens its own atlas and catalog")
	test.expect(game.get_viewport_rect().encloses(game.journal.panel.get_global_rect()) and game.journal.panel.get_global_rect().encloses(atlas.get_global_rect()),"southern atlas fits viewport")
	test.expect(atlas.label_for(SouthernBorderData.site("wanshe")).contains("池家") and not atlas.label_for(SouthernBorderData.site("baigu")).contains("百家"),"clan labels include evidenced sites but do not assign future Bai ownership")
	await test.click(ui.clan_toggle)
	test.expect(not atlas.show_clans,"visible clan overlay control toggles labels")
	await test.click(ui.clan_toggle)
	await test.click(ui.route_toggle)
	test.expect(not atlas.show_routes,"visible inferred-route control toggles the schematic trail")
	await test.click(ui.route_toggle)
	await screenshot(test,"overview")
	await test.pointer(atlas.global_position+atlas.to_map(SouthernBorderData.site("shangliang").pos),MOUSE_BUTTON_LEFT)
	test.expect(ui.selected_key=="shangliang" and ui.detail.text.contains("商家城") and not ui.local_button.visible,"real point click shows distant city detail without a travel action")
	var anchor:=atlas.size*0.5
	var coordinate:=atlas.from_map(anchor)
	var camera_zoom:float=game.zoom_level
	await test.pointer(atlas.global_position+anchor,MOUSE_BUTTON_WHEEL_UP)
	test.expect(atlas.zoom>1 and atlas.from_map(anchor).distance_to(coordinate)<0.1 and game.zoom_level==camera_zoom,"south wheel zoom anchors cursor independently of world camera")
	await test.click(ui.zoom_in)
	var old_center:=atlas.center
	await MapTests.new()._drag(game,atlas.global_position+anchor,atlas.global_position+anchor+Vector2(35,25),MOUSE_BUTTON_LEFT)
	test.expect(atlas.center.distance_to(old_center)>5 and ui.selected_key=="shangliang","south dragging pans without selecting a different place")
	atlas.zoom_at(100,atlas.size*0.5)
	test.expect(atlas.zoom==5 and ui.zoom_in.disabled,"south atlas zoom limit is enforced")
	atlas.focus_site("wuyi")
	test.expect(atlas.from_map(Vector2.ZERO).x>=-0.1 and atlas.from_map(atlas.size).y<=SouthernBorderData.EXTENT.y+0.1,"zoomed panning clamps at map edges")
	ui.filter.select(2)
	ui.filter.item_selected.emit(2)
	test.expect(ui.rows.get_child_count()==13,"super-clan filter lists all thirteen families")
	ui.search.text="商家"
	ui.search.text_changed.emit(ui.search.text)
	test.expect(ui.rows.get_child_count()==1,"family search narrows catalog")
	await test.click(ui.rows.get_child(0))
	test.expect(ui.selected_key=="clan:shang" and atlas.selected_site=="shangliang" and ui.detail.text.contains("正文记载") and ui.detail.text.contains("读者理解"),"actual catalog button focuses clan site and separates evidence from inference")
	await screenshot(test,"clan")
	ui.detail.meta_clicked.emit("source:shang")
	test.expect(ui.source_back.visible and ui.detail.text.contains("商家内城") and ui.detail.text.contains("在浏览器查看来源"),"source link displays provenance before optional external browser opening")
	await screenshot(test,"source")
	await test.click(ui.source_back)
	test.expect(ui.selected_key=="clan:shang" and not ui.source_back.visible,"return from provenance restores selected entry")
	ui.search.text=""
	ui.filter.select(4)
	ui.refresh_rows()
	await test.click(ui.rows.get_node("Entry_clan_hou"))
	test.expect(atlas.selected_site=="" and not ui.local_button.visible and ui.detail.text.contains("位置待考"),"unknown headquarters leaves no fabricated map marker or travel action")
	await screenshot(test,"unknown")
	ui.filter.select(0)
	ui.search.text="白家"
	ui.refresh_rows()
	test.expect(ui.rows.has_node("Entry_clan_bai") and not ui.rows.has_node("Entry_clan_bai_hundred"),"white family search never confuses the hundred clan")
	test.expect(game.player.position==position and game.world.layer==layer and game.waypoint==waypoint,"browsing all southern content preserves player layer position and local navigation")
	ui.select_entry("clan:bai")
	await test.click(ui.local_button)
	test.expect(game.minimap_ui.mode=="local" and game.minimap_ui.atlas.display_layer==0 and game.waypoint==waypoint and game.player.position==position,"local button views Bai settlement without teleporting or replacing waypoint")
	game.minimap_ui.set_mode("world")
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	var world_atlas:WorldAtlas=game.minimap_ui.world_atlas
	await test.pointer(world_atlas.global_position+world_atlas.regions.south.get_center(),MOUSE_BUTTON_LEFT)
	test.expect(game.minimap_ui.mode=="south","five-region map south click enters detailed southern atlas")
	ui.search.text=""
	ui.filter.select(0)
	ui.refresh_rows()
	ui.select_entry("qingmao",false)
	atlas.fit_map()
	game.minimap_ui.set_mode("local")
	game.journal.close()
	print("SOUTHBORDER checked=%d"%(test.checked-before))

func screenshot(test: CanonTests, name: String) -> void:
	await test.game.get_tree().process_frame
	await test.game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path:="res://shot_south_"+name+".png"
	test.expect(test.game.get_viewport().get_texture().get_image().save_png(path)==OK,"south atlas screenshot "+name)
