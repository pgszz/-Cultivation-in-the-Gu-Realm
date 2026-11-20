class_name AtlasMap
extends Control

signal destination_selected(pos: Vector2, title: String)
signal destination_cleared
signal view_changed
const MIN_ZOOM := 1.0
const MAX_ZOOM := 8.0
var game: Node
var display_layer := 0
var map_rect:=Rect2()
var markers:Array=[]
var label_rects:Array[Rect2]=[]
var zoom:=1.0
var center:=Vector2(GameData.MAP_W,GameData.MAP_H)*GameData.TILE*0.5
var drag_button:=0
var drag_start:=Vector2.ZERO
var drag_center:=Vector2.ZERO
var dragged:=false
var show_names:=true

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	custom_minimum_size=Vector2(430,260)
	clip_contents=true
	mouse_filter=MOUSE_FILTER_STOP
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	resized.connect(_view_updated)
	visibility_changed.connect(func(): drag_button=0)
	tooltip_text="滚轮缩放 · 按住左键或中键拖动 · 单击标点 · 右键取消"

func extent() -> Vector2:
	return TerrainLayers.extent(display_layer)

func map_scale() -> float:
	return maxf(0.001,minf((size.x-20)/extent().x,(size.y-20)/extent().y))*zoom

func world_to_map(pos: Vector2) -> Vector2:
	return size*0.5+(pos-center)*map_scale()

func map_to_world(pos: Vector2) -> Vector2:
	return center+(pos-size*0.5)/map_scale()

func _view_updated() -> void:
	var half_view:=size*0.5/map_scale()
	var limits:=extent()
	center.x=clampf(center.x,minf(half_view.x,limits.x-half_view.x),maxf(half_view.x,limits.x-half_view.x))
	center.y=clampf(center.y,minf(half_view.y,limits.y-half_view.y),maxf(half_view.y,limits.y-half_view.y))
	map_rect=Rect2(world_to_map(Vector2.ZERO),limits*map_scale())
	queue_redraw()
	view_changed.emit()

func zoom_at(value: float, anchor: Vector2) -> void:
	var before:=map_to_world(anchor)
	zoom=clampf(value,MIN_ZOOM,MAX_ZOOM)
	center+=before-map_to_world(anchor)
	_view_updated()

func fit_world() -> void:
	zoom=MIN_ZOOM
	center=extent()*0.5
	_view_updated()

func focus_position(pos: Vector2) -> void:
	zoom=maxf(zoom,3.0)
	center=pos
	_view_updated()

func _draw() -> void:
	if game==null: return
	map_rect=Rect2(world_to_map(Vector2.ZERO),extent()*map_scale())
	label_rects.clear()
	markers.clear()
	draw_rect(Rect2(Vector2.ZERO,size),Color("0b1d1b"))
	draw_texture_rect(game.world.map_texture(display_layer),map_rect,false)
	if game.fog!=null: draw_texture_rect(game.fog.overlay_on(display_layer),map_rect,false)
	draw_rect(map_rect,Color("8b8d68"),false,2)
	var player_pos:Vector2=game.outdoor_return if game.world.in_interior else game.player.position
	var p:=world_to_map(player_pos)
	if game.waypoint!=Vector2.ZERO and game.waypoint_layer==display_layer:
		var wp:=world_to_map(game.waypoint)
		if display_layer==game.world.layer: draw_dashed_line(p,wp,Color(0.98,0.88,0.6,0.65),2,6,true)
		if _on_map(wp):
			draw_arc(wp,10,0,TAU,28,UIStyle.GOLD,2,true)
			draw_line(wp+Vector2(0,5),wp+Vector2(0,-18),UIStyle.GOLD,2,true)
			draw_colored_polygon(PackedVector2Array([wp+Vector2(0,-18),wp+Vector2(13,-13),wp+Vector2(0,-8)]),UIStyle.GOLD)
			_map_label(wp,game.waypoint_name,UIStyle.GOLD,true)
	if display_layer==game.world.layer and _on_map(p):
		draw_circle(p,7,Color("183c37"))
		draw_circle(p,4,Color.WHITE)
		_map_label(p,"你 · 出口" if game.world.in_interior else "你",Color.WHITE,true)
	if display_layer==0:
		for h in World.HOUSE_DATA:
			if h.has("clan") and h.service!="hall" and zoom<2.5: continue
			if h.id in ["flower_cave","spring_cave"] and not game.fog.discovered_on(h.pos,display_layer): continue
			var hp:=world_to_map(h.pos)
			if not _on_map(hp): continue
			var building:=PaintedArt.prop(String(h.get("kind","house")),"house:"+h.id)
			if game.world.destruction.broken("house:"+h.id): building=PaintedArt.ruin("house")
			draw_texture_rect(building,PaintedArt.fit(building,Rect2(hp-Vector2(12,21),Vector2(24,24))),false)
			markers.append({"screen":hp,"pos":h.pos+Vector2(0,40),"name":h.name})
			if zoom>=2.5 and game.waypoint_name!=h.name: _map_label(hp,h.name,UIStyle.GOLD)
		for settlement in WorldLore.SETTLEMENTS:
			if zoom<2.5: _map_label(world_to_map(settlement.pos),settlement.name,UIStyle.GOLD)
		for lm in World.LANDMARKS:
			var pos:=Vector2(lm.pos)*GameData.TILE
			if not game.fog.discovered_on(pos,display_layer): continue
			var lp:=world_to_map(pos)
			if not _on_map(lp): continue
			draw_circle(lp,5,Color("eddab1"))
			_map_label(lp,lm.name,UIStyle.INK)
			markers.append({"screen":lp,"pos":pos,"name":lm.name})
		for site in World.EXPLORATION_SITES:
			var pos:=Vector2(site.pos)*GameData.TILE+Vector2(16,16)
			if not game.fog.discovered_on(pos,display_layer) and not game.visited_sites.has(site.id): continue
			var sp:=world_to_map(pos)
			if not _on_map(sp): continue
			if site.kind=="camp":
				draw_colored_polygon(PackedVector2Array([sp+Vector2(-5,4),sp+Vector2(0,-6),sp+Vector2(5,4)]),UIStyle.JADE)
			else: draw_circle(sp,4,UIStyle.JADE)
			if game.waypoint_name!=site.name: _map_label(sp,site.name,UIStyle.JADE)
			markers.append({"screen":sp,"pos":pos,"name":site.name})
		for habitat in WildlifeSystem.HABITATS:
			var pos:=WildlifeSystem.center(habitat)
			if not game.fog.discovered_on(pos,display_layer): continue
			var point:=world_to_map(pos)
			if not _on_map(point): continue
			var tint:=UIStyle.RED if MonsterSystem.WILDLIFE.has(habitat.species) else Color("c6b58c")
			draw_arc(point,float(habitat.radius)*map_scale(),0,TAU,24,Color(tint,0.5),1,true)
			draw_circle(point,3,tint)
			if zoom>=2: _map_label(point,habitat.name,tint)
			markers.append({"screen":point,"pos":pos,"name":habitat.name})
	for portal in game.world.blocks.portals(display_layer):
		var point:=world_to_map(portal.pos)
		if not _on_map(point): continue
		draw_rect(Rect2(point-Vector2(4,4),Vector2(8,8)),UIStyle.GOLD)
		markers.append({"screen":point,"pos":portal.pos,"name":portal.name})
		_map_label(point,portal.name,UIStyle.GOLD)
	for site in TerrainLayers.SITES:
		if site.layer!=display_layer or not game.fog.discovered_on(site.pos,display_layer): continue
		var point:=world_to_map(site.pos)
		if not _on_map(point): continue
		draw_circle(point,4,UIStyle.JADE)
		markers.append({"screen":point,"pos":site.pos,"name":site.name})
		_map_label(point,site.name,UIStyle.JADE)
	if display_layer==game.world.layer and game.waypoint!=Vector2.ZERO and game.waypoint_layer!=display_layer:
		var guide:Dictionary=game.waypoint_guidance()
		draw_dashed_line(p,world_to_map(guide.target),Color(UIStyle.GOLD,0.8),2,6,true)
	# Fixed compass and scale remain readable regardless of the viewed region.
	draw_style_box(UIStyle.box(Color(0.04,0.10,0.09,0.9)),Rect2(8,8,58,28))
	draw_string(ThemeDB.fallback_font,Vector2(19,27),"↑ 北",HORIZONTAL_ALIGNMENT_LEFT,-1,13,UIStyle.INK)
	var steps:=maxi(1,int(pow(2,floor(log(95.0/(map_scale()*GameData.TILE))/log(2.0)))))
	var length:=steps*GameData.TILE*map_scale()
	var origin:=Vector2(14,size.y-16)
	draw_line(origin,origin+Vector2(length,0),UIStyle.INK,2)
	draw_line(origin-Vector2(0,4),origin+Vector2(0,4),UIStyle.INK,2)
	draw_line(origin+Vector2(length,-4),origin+Vector2(length,4),UIStyle.INK,2)
	draw_string(ThemeDB.fallback_font,origin+Vector2(0,-7),"%d 步"%steps,HORIZONTAL_ALIGNMENT_LEFT,-1,12,UIStyle.INK)

func _on_map(point: Vector2) -> bool:
	return Rect2(Vector2(4,4),size-Vector2(8,8)).has_point(point)

func _nearest_marker(point: Vector2) -> Dictionary:
	var best:Dictionary={}
	var distance:=13.0
	for marker in markers:
		var current:=point.distance_to(marker.screen)
		if current<distance:
			best=marker
			distance=current
	return best

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseMotion:
		if drag_button!=0:
			if event.position.distance_to(drag_start)>5: dragged=true
			if dragged:
				center=drag_center-(event.position-drag_start)/map_scale()
				_view_updated()
			accept_event()
		else:
			var marker:=_nearest_marker(event.position)
			var tile:=Vector2i(map_to_world(event.position)/GameData.TILE)
			tooltip_text=(String(marker.name)+" · " if not marker.is_empty() else "(%d, %d) · "%[tile.x,tile.y])+"单击标点 / 再点取消 · 滚轮缩放 · 拖动查看 · 右键取消"
	if not event is InputEventMouseButton: return
	if event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				zoom_at(zoom*pow(1.25,maxf(0.1,event.factor)*(1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -1)),event.position)
			MOUSE_BUTTON_RIGHT:
				drag_button=0
				destination_cleared.emit()
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE:
				drag_button=event.button_index
				drag_start=event.position
				drag_center=center
				dragged=false
	elif event.button_index==drag_button:
		var click:bool=drag_button==MOUSE_BUTTON_LEFT and not dragged and event.position.distance_to(drag_start)<=5
		drag_button=0
		if click and Rect2(Vector2.ZERO,size).has_point(event.position): _select_point(event.position)
	accept_event()

func _select_point(point: Vector2) -> void:
	var pos:=map_to_world(point)
	if not Rect2(Vector2.ZERO,extent()).has_point(pos): return
	if game.waypoint_layer==display_layer and game.waypoint!=Vector2.ZERO and point.distance_to(world_to_map(game.waypoint))<10:
		destination_cleared.emit()
		return
	var marker:=_nearest_marker(point)
	if not marker.is_empty():
		if game.waypoint_layer==display_layer and game.waypoint.is_equal_approx(marker.pos): destination_cleared.emit()
		else: destination_selected.emit(marker.pos,marker.name)
	else:
		destination_selected.emit(pos,"自定标记 (%d, %d)"%[int(pos.x/GameData.TILE),int(pos.y/GameData.TILE)])

func _map_label(point:Vector2,title:String,color:Color,always:bool=false) -> void:
	if not _on_map(point) or (not show_names and not always): return
	var label_size:=ThemeDB.fallback_font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,12)+Vector2(6,3)
	for offset in [Vector2(9,-21),Vector2(9,4),Vector2(-label_size.x-9,-21),Vector2(-label_size.x-9,4),Vector2(9,21)]:
		var origin:Vector2=(point+offset).clamp(Vector2(4,4),size-label_size-Vector2(4,4))
		var rect:=Rect2(origin,label_size)
		var overlaps:=false
		for previous in label_rects:
			if rect.intersects(previous): overlaps=true; break
		if overlaps: continue
		label_rects.append(rect)
		draw_rect(rect,Color(0.03,0.09,0.08,0.88))
		draw_string(ThemeDB.fallback_font,origin+Vector2(3,13),title,HORIZONTAL_ALIGNMENT_LEFT,int(label_size.x),12,color)
		return
