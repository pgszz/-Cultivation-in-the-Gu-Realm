class_name TerrainLayers
extends RefCounted

# 三层俯视地形。台阶、洞网、矿脉和耐久都是自由探索游戏参数。
const UNDER_SIZE := Vector2i(128,96)
const NAMES := ["地表 · 青茅山","地下一层 · 岩溪洞网","地下二层 · 深岩洞窟"]
const ENTRANCES := [
	{"id":"bamboo_shaft","name":"竹林地穴","pos":Vector2(1008,1456),"landing":Vector2(528,592)},
	{"id":"bai_shaft","name":"白溪地穴","pos":Vector2(12176,2384),"landing":Vector2(3408,592)},
	{"id":"xiong_shaft","name":"山脚地穴","pos":Vector2(8592,10064),"landing":Vector2(3344,2512)},
]
const STAIRS := [
	{"id":"west_descent","name":"西侧石阶","upper":Vector2(784,1552),"lower":Vector2(592,592)},
	{"id":"east_descent","name":"东侧石阶","upper":Vector2(2896,1552),"lower":Vector2(2832,2064)},
]
const SITES := [
	{"id":"under_camp","name":"岩溪歇脚处","layer":1,"pos":Vector2(1424,528),"text":"旧行旅留下的干燥平台，可在这里整理行囊或按 J 打坐。","loot":{"bandage":2}},
	{"id":"under_river","name":"地下溪桥","layer":1,"pos":Vector2(1776,1424),"text":"流水沿裂隙穿山而过，石梁接通两岸。","loot":{}},
	{"id":"under_vein","name":"浅层玉脉","layer":1,"pos":Vector2(2448,656),"text":"岩缝中留有一份可带走的玉石。周围岩块可逐格击碎。","loot":{"jade":1}},
	{"id":"under_stone","name":"南部碎石厅","layer":1,"pos":Vector2(1936,2448),"text":"倒塌的岩柱留下碎石和可开凿的支路。","loot":{"rubble":3}},
	{"id":"deep_camp","name":"深岩避风台","layer":2,"pos":Vector2(1552,656),"text":"两处石阶通向上层，沿已探明的通路可返回地表。","loot":{"bandage":1,"bamboo_wine":1}},
	{"id":"deep_vein","name":"深层玉脉","layer":2,"pos":Vector2(2704,592),"text":"坚硬岩层中夹着玉脉，开凿会留下永久通道。","loot":{"jade":2}},
	{"id":"deep_pool","name":"暗潭石台","layer":2,"pos":Vector2(1680,1488),"text":"潭边石台潮湿，击碎岩壁可改变绕行路线。","loot":{}},
	{"id":"deep_hall","name":"层岩回廊","layer":2,"pos":Vector2(656,2128),"text":"这里是天然层岩形成的回廊，具体洞网为自由探索布局。","loot":{"rubble":4}},
]
var world: Node
var heights := PackedByteArray()
var caves: Dictionary = {}
var damage: Dictionary = {}
var claimed: Dictionary = {}
var visited: Dictionary = {}
var minimaps: Dictionary = {}
var minimap_images: Dictionary = {}
var mountain_cells: Dictionary = {}

static func size_for(layer: int) -> Vector2i:
	return Vector2i(GameData.MAP_W,GameData.MAP_H) if layer==0 else UNDER_SIZE

static func extent(layer: int) -> Vector2:
	return Vector2(size_for(layer))*GameData.TILE

static func cell_at(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x/32),floori(pos.y/32))

static func center(cell: Vector2i) -> Vector2:
	return Vector2(cell)*32+Vector2(16,16)

func setup(owner: Node) -> void:
	world=owner
	heights.resize(GameData.MAP_W*GameData.MAP_H)
	heights.fill(0)
	for i in World.MOUNTAINS.size():
		var mountain:Dictionary=World.MOUNTAINS[i]
		var origin:Vector2=mountain.pos-Vector2(0,mountain.size.y*0.28)
		var radius:Vector2=mountain.size*Vector2(0.5,0.4)
		mountain_cells[str(i)]=[]
		for y in range(maxi(1,int((origin.y-radius.y)/32)),mini(GameData.MAP_H-1,ceili((origin.y+radius.y)/32))):
			for x in range(maxi(1,int((origin.x-radius.x)/32)),mini(GameData.MAP_W-1,ceili((origin.x+radius.x)/32))):
				var cell:=Vector2i(x,y)
				var p:=center(cell)
				var d:=((p-origin)/radius).length()
				if d>=1 or world.road_tiles.has(y*GameData.MAP_W+x): continue
				var protected:=false
				for house in World.HOUSE_DATA:
					if p.distance_to(house.pos)<150: protected=true; break
				for gate in ENTRANCES:
					if p.distance_to(gate.pos)<100: protected=true; break
				if protected: continue
				var height:=maxi(1,ceili((1-d)*5))
				heights[y*GameData.MAP_W+x]=maxi(heights[y*GameData.MAP_W+x],height)
				world.map[y*GameData.MAP_W+x]=GameData.T_GRASS
				mountain_cells[str(i)].append(cell)
	for layer in [1,2]:
		var grid:=PackedByteArray()
		grid.resize(UNDER_SIZE.x*UNDER_SIZE.y)
		grid.fill(1 if layer==1 else 4)
		caves[layer]=grid
		var rooms:Array=[Vector2i(16,18),Vector2i(44,16),Vector2i(76,20),Vector2i(106,18),Vector2i(104,78),Vector2i(60,76),Vector2i(22,78),Vector2i(24,48),Vector2i(55,44),Vector2i(90,48)] if layer==1 else [Vector2i(18,18),Vector2i(48,20),Vector2i(84,18),Vector2i(110,36),Vector2i(88,64),Vector2i(52,72),Vector2i(20,66),Vector2i(52,46)]
		# Pools remain beside connected, dry corridors; no swimming is required.
		for y in range(UNDER_SIZE.y):
			for x in range(UNDER_SIZE.x):
				if Vector2(x-65,y-53).length()<9: caves[layer][y*UNDER_SIZE.x+x]=2
		for j in rooms.size():
			carve(layer,rooms[j],5+(j%3))
			corridor(layer,rooms[j],rooms[(j+1)%rooms.size()])
		corridor(layer,rooms[1],rooms[rooms.size()-2])
		corridor(layer,rooms[2],rooms[rooms.size()-1])
		for site in SITES:
			if site.layer==layer: carve(layer,cell_at(site.pos),3)
		for y in range(2,UNDER_SIZE.y-2):
			for x in range(2,UNDER_SIZE.x-2):
				if caves[layer][y*UNDER_SIZE.x+x] in [1,4] and posmod(x*37+y*71+layer*19,47)==0:
					caves[layer][y*UNDER_SIZE.x+x]=3
		for portal in portals(layer):
			var cell:=cell_at(portal.pos)
			carve(layer,cell,3)
			var nearest:Vector2i=rooms[0]
			for room:Vector2i in rooms:
				if Vector2(room-cell).length()<Vector2(nearest-cell).length(): nearest=room
			corridor(layer,cell,nearest)
		bake_minimap(layer)

func carve(layer: int, at: Vector2i, radius: int) -> void:
	for y in range(at.y-radius,at.y+radius+1):
		for x in range(at.x-radius,at.x+radius+1):
			if x>0 and y>0 and x<UNDER_SIZE.x-1 and y<UNDER_SIZE.y-1 and Vector2(x-at.x,y-at.y).length()<=radius:
				caves[layer][y*UNDER_SIZE.x+x]=0

func corridor(layer: int, a: Vector2i, b: Vector2i) -> void:
	var steps:=maxi(absi(a.x-b.x),absi(a.y-b.y))
	for i in steps+1:
		carve(layer,Vector2i(Vector2(a).lerp(Vector2(b),float(i)/maxi(1,steps)).round()),2)

func valid(cell: Vector2i, layer: int) -> bool:
	var size:=size_for(layer)
	return cell.x>=0 and cell.y>=0 and cell.x<size.x and cell.y<size.y

func key(cell: Vector2i, layer: int, height: int = 0) -> String:
	return "%d:%d:%d:%d"%[layer,cell.x,cell.y,height]

func height_at(cell: Vector2i) -> int:
	if not valid(cell,0) or heights.is_empty(): return 0
	var h:int=heights[cell.y*GameData.MAP_W+cell.x]
	while h>=0 and float(damage.get(key(cell,0,h),1))<=0: h-=1
	return h

func kind_at(cell: Vector2i, layer: int) -> int:
	if not valid(cell,layer): return 4
	if layer==0: return 1 if height_at(cell)>0 else 0
	var kind:int=caves[layer][cell.y*UNDER_SIZE.x+cell.x]
	return 0 if float(damage.get(key(cell,layer),1))<=0 else kind

func info(cell: Vector2i, layer: int) -> Dictionary:
	if not valid(cell,layer): return {}
	var h:=height_at(cell) if layer==0 else 0
	if h<0: return {}
	var kind:=kind_at(cell,layer)
	if kind==2 or (layer==0 and world.map[cell.y*GameData.MAP_W+cell.x]==GameData.T_WATER): return {}
	# Removing a cave wall exposes a separate floor block underneath it.
	if layer>0 and caves[layer][cell.y*UNDER_SIZE.x+cell.x] in [1,3,4] and kind==0: h=-1
	var id:=key(cell,layer,h)
	if float(damage.get(id,1))<=0: return {}
	var maximum:=48.0 if kind==0 else (96.0 if kind==3 else (120.0 if kind==4 else 72.0))
	return {"id":id,"cell":cell,"layer":layer,"height":h,"kind":kind,"name":{0:"土石地块",1:"山岩方块" if layer==0 else "洞壁岩块",3:"含玉岩块",4:"深层岩块"}.get(kind,"岩块"),"hp":float(damage.get(id,maximum)),"max_hp":maximum,"hardness":1.0 if kind==0 else (3.0 if kind==4 else 2.0),"pos":center(cell)}

func solid(cell: Vector2i, layer: int) -> bool:
	return not valid(cell,layer) or kind_at(cell,layer) in [1,2,3,4]

func hit(cell: Vector2i, layer: int, amount: float) -> Dictionary:
	var data:=info(cell,layer)
	if data.is_empty() or amount<=0: return {}
	var dealt:=amount/float(data.hardness)
	if dealt<float(data.hardness): dealt=0
	dealt=minf(dealt,float(data.hp))
	data.hp=maxf(0,float(data.hp)-dealt)
	damage[data.id]=data.hp
	data["destroyed"]=data.hp<=0
	data["blocked"]=dealt<=0
	data["damage"]=dealt
	data["loot"]={"jade":1} if data.destroyed and data.kind==3 else ({"rubble":1} if data.destroyed and data.kind!=0 else {})
	if layer==0:
		world.refresh_terrain_tile(cell)
		world.flush_terrain_changes()
	else:
		minimap_images[layer].set_pixel(cell.x,cell.y,color_at(cell,layer))
		minimaps[layer].update(minimap_images[layer])
	world.queue_redraw()
	return data

func speed_multiplier(pos: Vector2, direction: Vector2) -> float:
	if world.layer>0: return 0.82 if kind_at(cell_at(pos),world.layer)==0 else 1.0
	var height:=height_at(cell_at(pos))
	var ahead:=height_at(cell_at(pos+direction.normalized()*24))
	return 0.48 if ahead>height else (0.72 if height>0 else (0.8 if height<0 else 1.0))

func portals(layer: int) -> Array:
	var result:Array=[]
	if layer in [0,1]:
		for gate in ENTRANCES:
			result.append({"id":gate.id,"name":gate.name+(" · 下到岩溪洞网" if layer==0 else " · 返回地表"),"pos":gate.pos if layer==0 else gate.landing,"to_layer":1 if layer==0 else 0,"to_pos":gate.landing if layer==0 else gate.pos})
	if layer in [1,2]:
		for stair in STAIRS:
			result.append({"id":stair.id,"name":stair.name+(" · 下到深岩洞窟" if layer==1 else " · 返回岩溪洞网"),"pos":stair.upper if layer==1 else stair.lower,"to_layer":2 if layer==1 else 1,"to_pos":stair.lower if layer==1 else stair.upper})
	return result

func portal_at(pos: Vector2, layer: int) -> Dictionary:
	for portal in portals(layer):
		if pos.distance_to(portal.pos)<55: return portal
	return {}

func site_at(pos: Vector2, layer: int) -> Dictionary:
	for site in SITES:
		if site.layer==layer and pos.distance_to(site.pos)<60: return site
	return {}

func navigation_portal(pos: Vector2, layer: int, target_layer: int, target: Vector2) -> Dictionary:
	var next_layer:=layer+signi(target_layer-layer)
	var chosen:Dictionary={}
	var best:=INF
	for portal in portals(layer):
		if portal.to_layer!=next_layer: continue
		var cost:=pos.distance_to(portal.pos)
		if next_layer==target_layer: cost+=Vector2(portal.to_pos).distance_to(target)
		if cost<best: best=cost; chosen=portal
	return chosen

func color_at(cell: Vector2i, layer: int) -> Color:
	var kind:=kind_at(cell,layer)
	if layer==0:
		return Color("697c52").lerp(Color("b9b7a3"),clampf(height_at(cell)/5.0,0,1))
	return {0:Color("697471") if layer==1 else Color("626679"),1:Color("a4a48c"),2:Color("275564"),3:Color("639c81"),4:Color("818496")}[kind]

func bake_minimap(layer: int) -> void:
	var img:=Image.create(UNDER_SIZE.x,UNDER_SIZE.y,false,Image.FORMAT_RGBA8)
	for y in UNDER_SIZE.y:
		for x in UNDER_SIZE.x: img.set_pixel(x,y,color_at(Vector2i(x,y),layer))
	minimap_images[layer]=img
	if minimaps.has(layer): minimaps[layer].update(img)
	else: minimaps[layer]=ImageTexture.create_from_image(img)

func draw(canvas: Node2D, view: Rect2, layer: int) -> void:
	var size:=size_for(layer)
	for y in range(maxi(0,floori(view.position.y/32)-1),mini(size.y,ceili(view.end.y/32)+1)):
		for x in range(maxi(0,floori(view.position.x/32)-1),mini(size.x,ceili(view.end.x/32)+1)):
			var cell:=Vector2i(x,y)
			var h:=height_at(cell) if layer==0 else 0
			if layer==0 and h==0: continue
			var kind:=kind_at(cell,layer)
			var rect:=Rect2(Vector2(cell)*32,Vector2(32,32))
			var color:=color_at(cell,layer).lightened(float(posmod(x*13+y*7,5))*0.012)
			if h<0: color=Color("695b49")
			var base_kind:int=0 if layer==0 else caves[layer][y*UNDER_SIZE.x+x]
			var floor_key:=key(cell,layer,-1 if base_kind in [1,3,4] else 0)
			if layer>0 and float(damage.get(floor_key,1))<=0: color=color.darkened(0.35)
			_draw_block_model(canvas,rect,cell,layer,h,kind,color)

	for portal in portals(layer):
		if not view.grow(90).has_point(portal.pos): continue
		var p:Vector2=portal.pos
		canvas.draw_rect(Rect2(p-Vector2(30,26),Vector2(60,52)),Color("233637"))
		for i in 5:
			canvas.draw_rect(Rect2(p+Vector2(-24,-20+i*8),Vector2(48-i*5,5)),Color("c4b38a").darkened(i*0.08))
		canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-110,-38),portal.name,HORIZONTAL_ALIGNMENT_CENTER,220,13,UIStyle.GOLD)
	for site in SITES:
		if site.layer!=layer or not view.grow(80).has_point(site.pos): continue
		var p:Vector2=site.pos
		canvas.draw_rect(Rect2(p-Vector2(18,12),Vector2(36,24)),Color("68533b"))
		canvas.draw_rect(Rect2(p-Vector2(18,12),Vector2(36,24)),UIStyle.GOLD,false,2)
		canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-100,-23),site.name+(" · 已取" if claimed.has(site.id) else " · E"),HORIZONTAL_ALIGNMENT_CENTER,200,13,UIStyle.GOLD)

func _draw_block_model(canvas: Node2D, rect: Rect2, cell: Vector2i, layer: int, height: int, kind: int, color: Color) -> void:
	var origin:=rect.position
	var raised:=height>0 if layer==0 else kind in [1,3,4]
	var south:=height_at(cell+Vector2i.DOWN) if layer==0 else (1 if kind_at(cell+Vector2i.DOWN,layer) in [1,3,4] else 0)
	var east:=height_at(cell+Vector2i.RIGHT) if layer==0 else (1 if kind_at(cell+Vector2i.RIGHT,layer) in [1,3,4] else 0)
	var level:=height if layer==0 else (1 if raised else 0)
	var depth:=clampf((level-south)*11.0,0,22) if raised else 0.0
	var side:=clampf((level-east)*5.0,0,9) if raised else 0.0
	var grain:=posmod(cell.x*127+cell.y*311+layer*41,97)
	# A continuous top surface with exposed layered south/east walls, inside each
	# collision footprint. No art-only displacement of the playable cells.
	var relief:=sin(cell.x*0.42+cell.y*0.26)*0.035+cos(cell.y*0.53)*0.025
	color=color.lightened(relief)
	if layer==0 and height>0:
		color=Color("82925c").lerp(Color("acafa0"),clampf((height-1)/4.0,0,1)).lightened(relief)
	canvas.draw_rect(rect,color.darkened(0.42))
	var top:=Rect2(origin,Vector2(32-side,32-depth))
	canvas.draw_rect(top,color)
	if kind!=2 and height>=0:
		# Reuse small stone/turf material regions, while all height, sides and
		# damage remain code-built blocks rather than a whole mountain sprite.
		var turf:=layer==0 and height==1
		var source:=Rect2(Vector2(posmod(cell.x,4)*128,posmod(cell.y,4)*128+(0 if turf else 512)),Vector2(128,128))
		var tint:=Color("bdc59c") if turf else Color("c4c8b7").lightened(relief)
		if layer>0: tint=Color("737e7b") if kind==0 else (Color("9ea6b7") if kind==4 else Color("c4c8b7"))
		canvas.draw_texture_rect_region(PaintedArt.TERRAIN,top,source,tint)
	canvas.draw_rect(top,Color(color.darkened(0.35),0.24),false,0.8)
	if depth>0:
		var face:=PackedVector2Array([origin+Vector2(0,32-depth),origin+Vector2(32-side,32-depth),origin+Vector2(32,32),origin+Vector2(0,32)])
		canvas.draw_colored_polygon(face,color.darkened(0.32))
		canvas.draw_texture_rect_region(PaintedArt.TERRAIN,Rect2(origin+Vector2(0,32-depth),Vector2(32-side,depth)),Rect2(Vector2(posmod(cell.x,4)*128,512+posmod(cell.y,4)*128),Vector2(128,128)),Color("848771"))
		for band in range(1,ceili(depth/5.0)):
			var yy:=32-depth+band*5
			canvas.draw_line(origin+Vector2(1,yy),origin+Vector2(31,yy),color.darkened(0.46),1,true)
		canvas.draw_line(origin+Vector2(1,32-depth),origin+Vector2(31-side,32-depth),color.lightened(0.3),1.5,true)
		canvas.draw_line(origin+Vector2(2,31),origin+Vector2(31,31),Color("38463b"),1.5)
	if side>0:
		canvas.draw_colored_polygon(PackedVector2Array([origin+Vector2(32-side,0),origin+Vector2(32,3),origin+Vector2(32,32),origin+Vector2(32-side,32-depth)]),color.darkened(0.48))
		canvas.draw_line(origin+Vector2(31-side,1),origin+Vector2(31-side,30-depth),color.lightened(0.15),1)
	if kind!=2:
		for fleck in 5:
			var at:=origin+Vector2(3+posmod(grain+fleck*11,maxi(4,int(top.size.x)-7)),3+posmod(grain*3+fleck*7,maxi(4,int(top.size.y)-6)))
			canvas.draw_line(at,at+Vector2(2+fleck%3,1),Color(color.lightened(0.2) if fleck%2==0 else color.darkened(0.22),0.65),1)
		if layer==0 and height in [1,2,3] and grain%3==0:
			canvas.draw_colored_polygon(PackedVector2Array([origin+Vector2(2,2),origin+Vector2(18,3),origin+Vector2(12,8),origin+Vector2(3,6)]),Color("6a804d"))
		if layer==0 and height_at(cell+Vector2i.UP)>height:
			canvas.draw_rect(Rect2(origin,Vector2(32,5)),Color(0.12,0.18,0.12,0.3))
	else:
		canvas.draw_texture_rect_region(PaintedArt.TERRAIN,rect,Rect2(Vector2(1024+posmod(cell.x,4)*128,posmod(cell.y,4)*128),Vector2(128,128)),Color("6491a2"))
		canvas.draw_line(origin+Vector2(4,12),origin+Vector2(24,12),Color("518d9a"),1.2,true)
		canvas.draw_line(origin+Vector2(12,24),origin+Vector2(29,24),Color("3d7a8a"),1.2,true)
	if height<0:
		canvas.draw_rect(Rect2(origin,Vector2(32,6)),color.darkened(0.5))
		canvas.draw_rect(Rect2(origin,Vector2(5,32)),color.darkened(0.3))
	if kind==3 and layer>0:
		canvas.draw_polyline(PackedVector2Array([origin+Vector2(5,5),origin+Vector2(15,13),origin+Vector2(23,8)]),Color("b5e3c6"),2.6,true)
	var block:=info(cell,layer)
	if not block.is_empty() and float(block.hp)<float(block.max_hp):
		var fraction:=1.0-float(block.hp)/float(block.max_hp)
		canvas.draw_polyline(PackedVector2Array([origin+Vector2(10,2),origin+Vector2(17,10),origin+Vector2(11,19),origin+Vector2(22,28)]),color.darkened(0.65),1+fraction*1.5,true)
		if fraction>0.4:
			canvas.draw_polyline(PackedVector2Array([origin+Vector2(17,10),origin+Vector2(25,13),origin+Vector2(31,8)]),color.darkened(0.6),1.4,true)
		if fraction>0.7:
			canvas.draw_polyline(PackedVector2Array([origin+Vector2(11,19),origin+Vector2(4,23),origin+Vector2(0,20)]),color.darkened(0.65),1.7,true)

func save_data() -> Dictionary:
	return {"damage":damage,"claimed":claimed,"visited":visited}

func load_data(data: Dictionary, legacy_damage: Dictionary = {}) -> void:
	damage.clear()
	for id in data.get("damage",{}):
		var parts:=String(id).split(":")
		if parts.size()!=4: continue
		var layer:=int(parts[0])
		var cell:=Vector2i(int(parts[1]),int(parts[2]))
		if layer not in [0,1,2] or not valid(cell,layer): continue
		var height:=int(parts[3])
		if String(id)!=key(cell,layer,height): continue
		var kind:=0
		if layer==0:
			if height<0 or height>heights[cell.y*GameData.MAP_W+cell.x]: continue
			kind=1 if height>0 else 0
		else:
			kind=caves[layer][cell.y*UNDER_SIZE.x+cell.x]
			if kind==2 or height not in [0,-1] or (height==-1 and kind not in [1,3,4]): continue
			if height==-1: kind=0
		var maximum:=48.0 if kind==0 else (96.0 if kind==3 else (120.0 if kind==4 else 72.0))
		var hp:float=float(data.damage[id])
		if is_finite(hp): damage[id]=clampf(hp,0,maximum)
	if data.is_empty():
		for index in mountain_cells:
			var old_id:String="mountain:"+index
			if not legacy_damage.has(old_id): continue
			var ratio:=clampf(float(legacy_damage[old_id])/900.0,0,1)
			for cell:Vector2i in mountain_cells[index]:
				for h in range(1,heights[cell.y*GameData.MAP_W+cell.x]+1): damage[key(cell,0,h)]=72.0*ratio
	claimed=data.get("claimed",{}).duplicate()
	visited=data.get("visited",{}).duplicate()
	for layer in [1,2]: bake_minimap(layer)
