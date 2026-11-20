class_name HUD
extends Control

var game: Node
var quickbar: HBoxContainer
var minimal := false
var player_panel: PlayerHUD

func _ready() -> void:
	UIStyle.fill(self)
	mouse_filter=MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	player_panel=PlayerHUD.new()
	player_panel.game=game
	player_panel.hud=self
	add_child(player_panel)
	quickbar=player_panel.quickbar

func unobstructed() -> bool:
	return game!=null and game.running and not game.paused and not game.journal.visible and not game.village_ui.visible

func _process(_delta: float) -> void:
	# Paused screenshot fixtures keep the same HUD as normal play.
	player_panel.visible=game!=null and game.running and not game.player.dead and not game.journal.visible and not game.village_ui.visible and not game.pause_layer.visible and not game.refine_layer.visible and not game.compendium_ui.visible and not game.settings_ui.visible and not (game.shang_city!=null and game.shang_city.ui.visible)
	queue_redraw()

func _text(pos: Vector2,text: String,font_size: int=13,color: Color=UIStyle.INK,width: float=-1,align: int=HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(ThemeDB.fallback_font,pos,text,align,int(width),font_size,color)

func _panel(rect: Rect2) -> void:
	draw_style_box(UIStyle.box(Color(0.035,0.095,0.09,0.82),Color("465b50"),5),rect)

func _bar(pos: Vector2,width: float,ratio: float,color: Color) -> void:
	draw_rect(Rect2(pos,Vector2(width,5)),Color("0b1c1a"))
	draw_rect(Rect2(pos,Vector2(width*clampf(ratio,0,1),5)),color)

func _draw() -> void:
	if game==null or not game.running or game.player==null: return
	if (game.shang_city!=null and game.shang_city.ui.visible) or game.journal.visible or game.village_ui.visible or game.pause_layer.visible or game.refine_layer.visible or game.compendium_ui.visible or game.settings_ui.visible: return
	var p:Player=game.player
	var vp:=get_viewport_rect().size
	if not minimal:
		var location:String="商家城 · 演武进行中" if game.shang_city.active and game.shang_city.bout else ("商家城 · 商街" if game.shang_city.active else (game.current_house_name if game.world.in_interior else game.world.zone_name(game.world.zone_at(p.position))))
		_text(Vector2(0,30),location,15,UIStyle.GOLD,vp.x,HORIZONTAL_ALIGNMENT_CENTER)
		var map_rect:=Rect2(vp.x-156,12,144,108)
		_panel(map_rect.grow(2))
		if game.shang_city.active:
			game.shang_city.draw_map(self,map_rect)
			_text(Vector2(vp.x-158,136),"M 商家城指南",11,UIStyle.DIM)
		else:
			draw_texture_rect(game.world.map_texture(game.world.layer),map_rect,false)
			draw_texture_rect(game.fog.overlay,map_rect,false)
			var extent:=TerrainLayers.extent(game.world.layer)
			var player_pos:Vector2=game.outdoor_return if game.world.in_interior else p.position
			for house in (World.HOUSE_DATA if game.world.layer==0 else []):
				if house.id in ["flower_cave","spring_cave"] and not game.fog.discovered(house.pos): continue
				draw_circle(map_rect.position+house.pos/extent*map_rect.size,1.8,UIStyle.GOLD)
			for portal in game.world.blocks.portals(game.world.layer):
				draw_rect(Rect2(map_rect.position+portal.pos/extent*map_rect.size-Vector2(2,2),Vector2(4,4)),UIStyle.GOLD)
			draw_circle(map_rect.position+player_pos/extent*map_rect.size,2.5,Color.WHITE)
			_text(Vector2(vp.x-158,136),"M 山志 · 缩放 %.0f%%"%(game.zoom_level*100),11,UIStyle.DIM)
			if game.waypoint!=Vector2.ZERO:
				var point:Vector2=map_rect.position+Vector2(game.waypoint_guidance().target if not game.world.in_interior else game.waypoint)/extent*map_rect.size
				draw_line(map_rect.position+player_pos/extent*map_rect.size,point,Color(UIStyle.GOLD,0.65),1,true)
				draw_arc(point,4,0,TAU,16,UIStyle.GOLD,1.5,true)
		var start:=Vector2(vp.x-174,vp.y-64)
		for i in 3:
			var rect:=Rect2(start+Vector2(i*54,0),Vector2(48,48))
			_panel(rect)
			var gu:GuVirtual=game.equipped_gu(i)
			if gu!=null:
				draw_texture_rect(GuArt.texture(gu.template_id),GuArt.fitted_rect(gu.template_id,Rect2(rect.position+Vector2(5,5),Vector2(38,38))),false)
				if p.cast_cds[i]>0:
					draw_rect(rect,Color(0.02,0.06,0.07,0.7))
					_text(rect.position+Vector2(2,29),"%.1f"%p.cast_cds[i],14,UIStyle.GOLD,44,HORIZONTAL_ALIGNMENT_CENTER)
				_text(rect.position+Vector2(23,43),"%d转"%gu.rank,10,UIStyle.INK)
			else: _text(rect.position+Vector2(3,29),"空",12,UIStyle.DIM,42,HORIZONTAL_ALIGNMENT_CENTER)
			_text(rect.position+Vector2(4,12),str(i+1),11,UIStyle.GOLD)
		_text(Vector2(vp.x-174,vp.y-70),"催蛊 · Q 管理",11,UIStyle.DIM)
		_text(Vector2(vp.x*0.5-180,vp.y-19),"E 交互 · F 检查修缮 · R 炼化 · J 打坐",11,UIStyle.DIM,360,HORIZONTAL_ALIGNMENT_CENTER)
		var line:=0
		for i in mini(2,game.logs.size()):
			var entry:Dictionary=game.logs[game.logs.size()-1-i]
			if Time.get_ticks_msec()-int(entry.get("time",0))>6500: continue
			_text(Vector2(14,vp.y-57-line*17),String(entry.text).left(44),12,UIStyle.INK,540)
			line+=1
	if game.meditating:
		var rect:=Rect2(vp.x*0.5-167,42,334,43)
		_panel(rect)
		var crossing:=p.aperture.crossing
		_text(rect.position+Vector2(10,18),("冲窍 %.1f/30秒 · 真元 %s · J 中断"%[p.aperture.crossing_seconds,p.aperture.amount_text()]) if crossing else "打坐温养 %.1f%% · 真元 %s · J 收功"%[p.xiuwei,p.aperture.amount_text()],13,UIStyle.JADE)
		_bar(rect.position+Vector2(10,28),314,p.aperture.crossing_seconds/30.0 if crossing else p.xiuwei/p.xp_next,UIStyle.GOLD)
	var hint:String=game.world.interaction_prompt(p.position)
	if hint=="" and game.world.on_surface() and not game.npc.dead and not game.npc.hostile and p.position.distance_to(game.npc.position)<80: hint="E  与寨中蛊师交谈"
	if hint!="":
		var rect:=Rect2(vp.x*0.5-196,vp.y-103,392,30)
		_panel(rect)
		_text(rect.position+Vector2(8,20),hint,13,UIStyle.GOLD,376,HORIZONTAL_ALIGNMENT_CENTER)
	elif game.target_hint!=null and not game.world.in_interior and game.fog.can_see(game.target_hint.position):
		var target:Enemy=game.target_hint
		var rect:=Rect2(vp.x*0.5-180,vp.y-130,360,55)
		_panel(rect)
		var title:=target.display_name
		if target.is_creature(): title=("妖兽 · " if target.is_monster else "动物 · ")+title
		_text(rect.position+Vector2(8,17),title,13,UIStyle.RED if target.is_monster else UIStyle.GOLD)
		if not target.wildlife_slot.is_empty(): _text(rect.position+Vector2(8,34),target.life_description(),12,UIStyle.INK)
		_bar(rect.position+Vector2(8,43),344,target.hp/target.max_hp,UIStyle.RED)
	if minimal: _text(Vector2(12,vp.y-16),"F1 显示界面",11,UIStyle.DIM)
	for i in game.reaction_events.size():
		_text(Vector2(vp.x*0.5-140,105+i*18),game.reaction_events[i].title,13,UIStyle.GOLD,280,HORIZONTAL_ALIGNMENT_CENTER)
	_draw_block()
	_draw_waypoint()

func waypoint_indicator() -> Dictionary:
	var guide:Dictionary=game.waypoint_guidance()
	if guide.is_empty(): return {}
	var viewport_size:=get_viewport_rect().size
	var safe:=Rect2(Vector2(40,190),viewport_size-Vector2(80,322))
	var transform:=get_viewport().get_canvas_transform()
	var target:Vector2=transform*Vector2(guide.target)
	var origin:Vector2=(transform*game.player.position).clamp(safe.position+Vector2.ONE,safe.end-Vector2.ONE)
	var delta:=target-origin
	var factor:=1.0
	if delta.x>0: factor=minf(factor,(safe.end.x-origin.x)/delta.x)
	elif delta.x<0: factor=minf(factor,(safe.position.x-origin.x)/delta.x)
	if delta.y>0: factor=minf(factor,(safe.end.y-origin.y)/delta.y)
	elif delta.y<0: factor=minf(factor,(safe.position.y-origin.y)/delta.y)
	guide["screen"]=origin+delta*factor
	guide["offscreen"]=not safe.has_point(target)
	return guide

func _draw_waypoint() -> void:
	var guide:=waypoint_indicator()
	if guide.is_empty(): return
	var vp:=get_viewport_rect().size
	var banner:=Rect2(vp.x*0.5-205,94 if game.meditating else 43,410,56)
	_panel(banner)
	_text(banner.position+Vector2(12,21),"⚑ "+game.waypoint_name,15,UIStyle.GOLD,386,HORIZONTAL_ALIGNMENT_CENTER)
	var detail:="已到达附近 · M 查看 / 取消"
	if guide.indoors: detail="先到出口 · %s · %.0f 步 · E 离开"%[guide.direction,guide.steps]
	elif guide.transition!="": detail="先到%s · %.0f 步 · E"%[guide.transition,guide.steps]
	elif not guide.arrived: detail="%s · %.0f 步 · 沿道路前往 · M 取消"%[guide.direction,guide.steps]
	_text(banner.position+Vector2(12,43),detail,12,UIStyle.INK,386,HORIZONTAL_ALIGNMENT_CENTER)
	var point:Vector2=guide.screen
	var tint:=UIStyle.JADE if guide.arrived else UIStyle.GOLD
	draw_circle(point,19,Color(0.03,0.09,0.08,0.9))
	if guide.offscreen:
		var direction:Vector2=Vector2(guide.delta).normalized()
		var side:=Vector2(-direction.y,direction.x)
		draw_colored_polygon(PackedVector2Array([point+direction*13,point-direction*8+side*8,point-direction*3,point-direction*8-side*8]),tint)
	else:
		draw_arc(point,12,0,TAU,28,tint,2,true)
		draw_line(point+Vector2(0,7),point-Vector2(0,16),tint,2,true)
		draw_colored_polygon(PackedVector2Array([point+Vector2(0,-16),point+Vector2(12,-11),point+Vector2(0,-6)]),tint)
	if guide.offscreen:
		var label_pos:Vector2=Vector2(point.x-62,point.y+34).clamp(Vector2(8,160),vp-Vector2(132,106))
		_text(label_pos,"出口" if guide.indoors else "%.0f 步"%guide.steps,12,tint,124,HORIZONTAL_ALIGNMENT_CENTER)

func _draw_block() -> void:
	if game.world.in_interior: return
	var mouse:Vector2=game.get_global_mouse_position()
	var block:Dictionary=game.world.aimed_block(game.player.position,mouse,640)
	if game.player.position.distance_to(mouse)>640: return
	if block.is_empty(): return
	var transform:=get_viewport().get_canvas_transform()
	var top:Vector2=transform*(Vector2(block.cell)*32)
	var side:Vector2=Vector2.ONE*32*game.camera.zoom.x
	draw_rect(Rect2(top,side),Color(UIStyle.GOLD,0.9),false,2)
	var vp:=get_viewport_rect().size
	var origin:Vector2=(top+Vector2(side.x+8,-16)).clamp(Vector2(12,196),vp-Vector2(224,155))
	_panel(Rect2(origin,Vector2(224,79)))
	_text(origin+Vector2(8,18),"%s · 高 %d"%[block.name,block.height],12,UIStyle.GOLD)
	_text(origin+Vector2(8,36),"血量 %.0f / %.0f · %s"%[block.hp,block.max_hp,"左键 / 蛊术" if game.player.position.distance_to(block.pos)<=80 else "蛊术瞄准"],12,UIStyle.INK)
	_bar(origin+Vector2(8,47),208,block.hp/block.max_hp,UIStyle.JADE)
	var state:String=game.world.environment.label(block.cell,game.world.layer)
	_text(origin+Vector2(8,67),state if state!="" else "瞄准落点开凿 · 近处 F 查看",11,UIStyle.DIM)
