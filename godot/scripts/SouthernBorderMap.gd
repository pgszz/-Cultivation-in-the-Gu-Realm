class_name SouthernBorderMap
extends Control

signal selected(key: String)
signal view_changed
var zoom := 1.0
var center := SouthernBorderData.EXTENT*0.5
var selected_site := "qingmao"
var show_routes := true
var show_names := true
var show_clans := true
var markers: Array[Dictionary] = []
var label_boxes: Array[Rect2] = []
var drag_button := 0
var drag_start := Vector2.ZERO
var drag_center := Vector2.ZERO
var dragged := false

func _ready() -> void:
	clip_contents=true
	custom_minimum_size=Vector2(390,250)
	mouse_filter=MOUSE_FILTER_STOP
	resized.connect(_changed)

func scale_factor() -> float:
	return minf(size.x/SouthernBorderData.EXTENT.x,size.y/SouthernBorderData.EXTENT.y)*zoom

func to_map(point: Vector2) -> Vector2:
	return size*0.5+(point-center)*scale_factor()

func from_map(point: Vector2) -> Vector2:
	return center+(point-size*0.5)/maxf(0.001,scale_factor())

func _changed() -> void:
	var half:=size/(2*maxf(0.001,scale_factor()))
	for axis in 2:
		center[axis]=SouthernBorderData.EXTENT[axis]*0.5 if half[axis]*2>=SouthernBorderData.EXTENT[axis] else clampf(center[axis],half[axis],SouthernBorderData.EXTENT[axis]-half[axis])
	queue_redraw()
	view_changed.emit()

func zoom_at(value: float, anchor: Vector2) -> void:
	var before:=from_map(anchor)
	zoom=clampf(value,1,5)
	center+=before-from_map(anchor)
	_changed()

func fit_map() -> void:
	zoom=1
	center=SouthernBorderData.EXTENT*0.5
	_changed()

func focus_site(id: String) -> void:
	var row:=SouthernBorderData.site(id)
	selected_site=id
	if not row.is_empty():
		center=row.pos
		zoom=maxf(zoom,2.2)
	_changed()

func label_for(row: Dictionary) -> String:
	if row.id=="shangliang": return "商家城"
	if show_clans:
		var names:Array[String]=[]
		for family in SouthernBorderData.CLANS:
			if family.site==row.id: names.append(family.name)
		if names.size()==1: return names[0]+"·"+row.name
		if row.id=="qingmao": return "青茅山·三寨"
		if row.id=="huangjin": return "黄金山·金/黄"
	return row.name

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("152c2b"))
	var outline:=PackedVector2Array()
	for p in [Vector2(50,90),Vector2(190,25),Vector2(430,60),Vector2(650,35),Vector2(870,55),Vector2(1160,100),Vector2(1190,330),Vector2(1150,540),Vector2(1180,790),Vector2(970,870),Vector2(650,850),Vector2(420,890),Vector2(180,865),Vector2(30,710),Vector2(60,430),Vector2(15,260)]: outline.append(to_map(p))
	draw_colored_polygon(outline,Color("2b4438"))
	outline.append(outline[0])
	draw_polyline(outline,Color("7c8966"),1.5,true)
	# 固定种子式几何山纹；不把装饰山峰当成原著地名。
	for y in range(110,850,78):
		for x in range(80,1150,88):
			var p:=Vector2(x+sin(y*0.11+x)*26,y+cos(x*0.07+y)*23)
			var r:=14.0+fposmod(x+y,20)
			var a:=to_map(p+Vector2(-r,12))
			var b:=to_map(p+Vector2(0,-r))
			var c:=to_map(p+Vector2(r,12))
			draw_colored_polygon(PackedVector2Array([a,b,c]),Color("354e3d"))
			draw_line(a,b,Color("5b6c50"),1,true)
			draw_line(b,c,Color("203b34"),2,true)
	for river in SouthernBorderData.RIVERS:
		var points:=PackedVector2Array()
		for p in river.points: points.append(to_map(p))
		draw_polyline(points,Color("122d30"),maxf(5,8*scale_factor()),true)
		draw_polyline(points,river.color,maxf(2,4.5*scale_factor()),true)
	if show_routes:
		for trail in SouthernBorderData.TRAILS:
			for i in range(1,trail.size()): draw_dashed_line(to_map(trail[i-1]),to_map(trail[i]),Color("c2ad80"),1.2,5,true)
	markers.clear()
	label_boxes.clear()
	for row in SouthernBorderData.SITES:
		var point:=to_map(row.pos)
		if not Rect2(Vector2(10,28),size-Vector2(20,50)).has_point(point): continue
		var tint:=UIStyle.GOLD if row.id==selected_site else (Color("92c8b7") if row.placement=="relative" else Color("d0c0a0"))
		if row.placement=="relative": draw_circle(point,4.5,tint)
		else:
			var diamond:=PackedVector2Array([point+Vector2(-5,0),point+Vector2(0,-5),point+Vector2(5,0),point+Vector2(0,5),point+Vector2(-5,0)])
			draw_polyline(diamond,tint,1.5,true)
		if row.id==selected_site: draw_arc(point,9,0,TAU,24,UIStyle.GOLD,1.8,true)
		markers.append({"id":row.id,"point":point})
	# 优先选中项和主要地名，碰撞标签可在放大后显示。
	for pass_index in 3:
		for row in SouthernBorderData.SITES:
			var priority:=0 if row.id==selected_site else (1 if row.get("major",false) or (show_clans and row.id in ["wanshe","dapeng"]) else 2)
			if priority!=pass_index or (priority>0 and not show_names) or (priority==2 and zoom<1.7): continue
			var p:=to_map(row.pos)
			if not Rect2(Vector2(10,28),size-Vector2(20,50)).has_point(p): continue
			var title:=label_for(row)
			var font_size:=15 if priority==0 else 13
			var width:=ThemeDB.fallback_font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x+10
			for offset in [Vector2(9,-11),Vector2(-width-9,-11),Vector2(-width*0.5,12),Vector2(-width*0.5,-33)]:
				var rect:=Rect2(p+offset,Vector2(width,22))
				if not Rect2(Vector2(5,29),size-Vector2(10,53)).encloses(rect): continue
				var overlaps:=false
				for used in label_boxes:
					if rect.grow(2).intersects(used): overlaps=true; break
				if overlaps: continue
				label_boxes.append(rect)
				draw_style_box(UIStyle.box(Color(0.06,0.12,0.11,0.88),Color("70806a") if priority==0 else Color(0,0,0,0),3),rect)
				draw_string(ThemeDB.fallback_font,rect.position+Vector2(5,16),title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,UIStyle.GOLD if priority==0 else UIStyle.INK)
				break
	draw_rect(Rect2(0,0,size.x,27),Color(0.04,0.10,0.09,0.95))
	draw_string(ThemeDB.fallback_font,Vector2(10,19),"↑ 北    南疆山川 · 方位示意",HORIZONTAL_ALIGNMENT_LEFT,-1,13,UIStyle.INK)
	draw_rect(Rect2(0,size.y-23,size.x,23),Color(0.04,0.10,0.09,0.95))
	draw_string(ThemeDB.fallback_font,Vector2(10,size.y-7),"山形 / 间距 / 商路为推演 · 非测绘疆界",HORIZONTAL_ALIGNMENT_LEFT,-1,12,UIStyle.DIM)

func nearest(point: Vector2) -> String:
	var distance:=13.0
	var id:=""
	for marker in markers:
		var current:=point.distance_to(marker.point)
		if current<distance: distance=current; id=marker.id
	return id

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if drag_button!=0:
			if event.position.distance_to(drag_start)>5: dragged=true
			if dragged:
				center=drag_center-(event.position-drag_start)/maxf(0.001,scale_factor())
				_changed()
			accept_event()
		else:
			var id:=nearest(event.position)
			tooltip_text=SouthernBorderData.site(id).get("name","")+" · 单击查看 · 滚轮缩放 · 左/中键拖动"
	if not event is InputEventMouseButton: return
	if event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_at(zoom*(1.25 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 0.8),event.position)
		elif event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE]:
			drag_button=event.button_index
			drag_start=event.position
			drag_center=center
			dragged=false
	elif event.button_index==drag_button:
		if not dragged and drag_button==MOUSE_BUTTON_LEFT:
			var id:=nearest(event.position)
			if id!="":
				selected_site=id
				selected.emit(id)
				queue_redraw()
		drag_button=0
	accept_event()
