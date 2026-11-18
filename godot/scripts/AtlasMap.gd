class_name AtlasMap
extends Control

signal destination_selected(pos: Vector2, title: String)
var game: Node
var map_rect:=Rect2()
var markers:Array=[]
var label_rects:Array[Rect2]=[]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size=Vector2(430,280)
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND

func _draw() -> void:
	if game==null: return
	label_rects.clear()
	var extent:=Vector2(GameData.MAP_W*GameData.TILE,GameData.MAP_H*GameData.TILE)
	var ratio:=minf((size.x-20)/extent.x,(size.y-20)/extent.y)
	map_rect=Rect2((size-extent*ratio)*0.5,extent*ratio)
	draw_rect(map_rect.grow(5),Color("8b8d68"),false,2)
	draw_texture_rect(game.world.minimap_texture,map_rect,false)
	if game.fog!=null: draw_texture_rect(game.fog.overlay,map_rect,false)
	for mountain in World.MOUNTAINS:
		if not game.fog.discovered(mountain.pos): continue
		var mp: Vector2 = map_rect.position+mountain.pos*ratio
		draw_colored_polygon(PackedVector2Array([mp+Vector2(-8,2),mp+Vector2(0,-10),mp+Vector2(8,2)]),Color("c4c5a0"))
	var player_pos:Vector2=game.outdoor_return if game.world.in_interior else game.player.position
	var p:=map_rect.position+player_pos*ratio
	draw_circle(p,8,Color("183c37"))
	draw_circle(p,4,UIStyle.INK)
	draw_string(ThemeDB.fallback_font,p+Vector2(9,4),"你",HORIZONTAL_ALIGNMENT_LEFT,50,14,Color.WHITE)
	markers.clear()
	for h in World.HOUSE_DATA:
		if h.id in ["flower_cave","spring_cave"] and not game.fog.discovered(h.pos): continue
		var hp:Vector2=map_rect.position+h.pos*ratio
		draw_rect(Rect2(hp-Vector2(4,4),Vector2(8,8)),UIStyle.GOLD)
		markers.append({"screen":hp,"pos":h.pos,"name":h.name})
	for settlement in WorldLore.SETTLEMENTS:
		_map_label(map_rect.position+settlement.pos*ratio,settlement.name,UIStyle.GOLD)
	for lm in World.LANDMARKS:
		if not game.fog.discovered(Vector2(lm.pos)*GameData.TILE): continue
		var lp:Vector2=map_rect.position+Vector2(lm.pos)*GameData.TILE*ratio
		draw_circle(lp,5,Color("eddab1"))
		_map_label(lp,lm.name,UIStyle.INK)
		markers.append({"screen":lp,"pos":Vector2(lm.pos)*GameData.TILE,"name":lm.name})
	for site in World.EXPLORATION_SITES:
		var pos:=Vector2(site.pos)*GameData.TILE+Vector2(16,16)
		if not game.fog.discovered(pos): continue
		var sp:Vector2=map_rect.position+pos*ratio
		draw_circle(sp,4,UIStyle.JADE)
		_map_label(sp,site.name,UIStyle.JADE)
		markers.append({"screen":sp,"pos":pos,"name":site.name})
	if game.waypoint!=Vector2.ZERO:
		var wp:Vector2=map_rect.position+game.waypoint*ratio
		draw_line(p,wp,Color(0.98,0.88,0.6,0.6),2,true)
		draw_arc(wp,9,0,TAU,28,UIStyle.GOLD,2,true)

func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseMotion:
		tooltip_text="点击地面设置步行目的地"
		for marker in markers:
			if event.position.distance_to(marker.screen)<12:
				tooltip_text=marker.name+" · 点击标记"
				break
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		if not map_rect.has_point(event.position): return
		for marker in markers:
			if event.position.distance_to(marker.screen)<15:
				destination_selected.emit(marker.pos,marker.name)
				return
		var extent:=Vector2(GameData.MAP_W*GameData.TILE,GameData.MAP_H*GameData.TILE)
		var pos:Vector2=(event.position-map_rect.position)/map_rect.size*extent
		destination_selected.emit(pos,"自定标记")

func _map_label(point:Vector2,title:String,color:Color) -> void:
	var extent:=ThemeDB.fallback_font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,11)+Vector2(6,2)
	for offset in [Vector2(7,-18),Vector2(7,3),Vector2(-extent.x-7,-18),Vector2(-extent.x-7,3),Vector2(7,18)]:
		var origin:Vector2=(point+offset).clamp(map_rect.position+Vector2(3,3),map_rect.end-extent-Vector2(3,3))
		var rect:=Rect2(origin,extent)
		var overlaps:=false
		for previous in label_rects:
			if rect.intersects(previous): overlaps=true; break
		if overlaps: continue
		label_rects.append(rect)
		draw_rect(rect,Color(0.05,0.12,0.10,0.72))
		draw_string(ThemeDB.fallback_font,origin+Vector2(3,12),title,HORIZONTAL_ALIGNMENT_LEFT,int(extent.x),11,color)
		return
