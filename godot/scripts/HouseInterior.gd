class_name HouseInterior
extends Node2D

const ORIGIN := Vector2(GameData.MAP_W*GameData.TILE+2048,1024)
const BOUNDS := Rect2(-352,-224,704,448)
const FIXTURES := {
	"bed":Rect2(-260,-140,88,138),
	"desk":Rect2(102,-132,172,64),
	"storage":Rect2(150,76,92,58),
	"wall_n":Rect2(-352,-224,704,40),
	"wall_w":Rect2(-352,-224,12,448),
	"wall_e":Rect2(340,-224,12,448),
	"wall_s_left":Rect2(-352,212,310,12),
	"wall_s_right":Rect2(42,212,310,12),
}
var house_id := ""
var house_name := ""
var game: Node
var fixture_effects: Dictionary = {}
var visual_revision := 0

func _ready() -> void:
	position = ORIGIN
	z_index = -10
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	for id in ["bed","desk","storage"]:
		var visual:=InteriorFixtureVisual.new()
		visual.interior=self
		visual.fixture_id=id
		get_parent().add_child.call_deferred(visual)

func sync_fixture(id: String, health: float, animate: bool) -> void:
	if not id.begins_with("interior:"): return
	visual_revision+=1
	if not animate:
		fixture_effects.erase(id)
	else:
		fixture_effects[id]={"elapsed":0.0,"broken":health<=0.0}
	queue_redraw()

func _process(delta: float) -> void:
	if game==null or game.paused or not visible or fixture_effects.is_empty(): return
	for id in fixture_effects.keys():
		fixture_effects[id].elapsed+=delta
		if fixture_effects[id].elapsed>=CollapseAnimation.DURATION: fixture_effects.erase(id)
	visual_revision+=1
	queue_redraw()

func _draw() -> void:
	if SettlementData.is_cave(house_id):
		_draw_cave()
		return
	draw_rect(Rect2(-1600,-1000,3200,2000),Color("0d1b20"))
	draw_rect(BOUNDS.grow(12),Color("263330"))
	for y in range(-224,224,64):
		for x in range(-352,352,64):
			draw_texture_rect_region(PaintedArt.TERRAIN,Rect2(x,y,64,64),Rect2(512,512,512,512),Color("b3ad96"))
	for id in FIXTURES:
		if id.begins_with("wall"): draw_fixture(id,self)
	draw_rect(Rect2(-40,192,80,32),Color("baa17b"))
	draw_string(ThemeDB.fallback_font,Vector2(-80,187),"出口 · E",HORIZONTAL_ALIGNMENT_CENTER,160,16,Color("fff0c6"))
	draw_rect(Rect2(-100,-80,170,140),Color("5c7470"))
	draw_rect(Rect2(-90,-70,150,120),Color("aab29a"),false,3)
	_draw_wear()

func draw_fixture(id: String, canvas: CanvasItem, origin: Vector2 = Vector2.ZERO) -> void:
	canvas.draw_set_transform(-origin)
	var r: Rect2=FIXTURES[id]
	var texture: AtlasTexture
	if id.begins_with("wall"):
		texture=AtlasTexture.new()
		texture.atlas=PaintedArt.TERRAIN
		texture.region=Rect2(512,512,512,512)
	else:
		var index:int={"bed":4 if SettlementData.service(house_id) in ["home","clinic","inn"] else 7,"desk":5,"storage":6}[id]
		texture=PaintedArt.sprite("scenery",index)
		if id=="desk": r=Rect2(r.position-Vector2(0,55),r.size+Vector2(0,55))
		r=PaintedArt.fit(texture,r)
	var effect: Dictionary=fixture_effects.get("interior:"+house_id+":"+id,{})
	if broken(id):
		var progress:=clampf(float(effect.get("elapsed",CollapseAnimation.DURATION))/CollapseAnimation.DURATION,0,1)
		var debris:=PaintedArt.ruin("furniture")
		var debris_rect:=Rect2(FIXTURES[id].get_center()-Vector2(40,12),Vector2(80,36))
		canvas.draw_texture_rect(debris,PaintedArt.fit(debris,debris_rect),false,Color(1,1,1,smoothstep(0.12,0.72,progress)))
		if progress<1:
			# Collapse coordinates are local to this fixture, so debris lands on its footprint.
			var center: Vector2=FIXTURES[id].get_center()
			CollapseAnimation.draw(canvas,texture,Rect2(r.position-center,r.size),progress,1.0,center-origin)
		canvas.draw_set_transform(Vector2.ZERO)
		return
	var t:=float(effect.get("elapsed",1))
	canvas.draw_set_transform(Vector2(sin(t*90)*maxf(0,0.25-t)*8,0)-origin)
	canvas.draw_texture_rect(texture,r,false)
	canvas.draw_set_transform(Vector2.ZERO)

func _draw_wear() -> void:
	if game==null: return
	for id in FIXTURES:
		var full_id:String="interior:"+house_id+":"+id
		if not game.world.destruction.objects.has(full_id): continue
		var obj:Dictionary=game.world.destruction.objects[full_id]
		if float(obj.hp)<=0 or float(obj.hp)>=float(obj.max_hp): continue
		var r:Rect2=FIXTURES[id]
		var ratio:=float(obj.hp)/float(obj.max_hp)
		var center:=r.get_center()
		var extent:=Vector2(minf(r.size.x*0.4,35),minf(r.size.y*0.4,30))
		draw_polyline(PackedVector2Array([center-extent,center+Vector2(4,-4),center+Vector2(-4,5),center+extent]),Color("302b25"),3 if ratio<=0.3 else 2,true)
		var bar:=center+Vector2(-22,10)
		draw_rect(Rect2(bar,Vector2(44,4)),Color("263330"))
		draw_rect(Rect2(bar,Vector2(44*ratio,4)),UIStyle.RED if ratio<=0.3 else UIStyle.GOLD)

func interaction_at(pos: Vector2) -> String:
	var local := pos-ORIGIN
	if SettlementData.is_cave(house_id):
		if local.distance_to(Vector2(0,184))<65: return "exit"
		if local.distance_to(Vector2(0,-65))<115: return house_id
		return ""
	if local.distance_to(Vector2(0,184))<65: return "exit"
	if not broken("bed") and local.distance_to(Vector2(-214,-62))<92:
		return "rest" if SettlementData.service(house_id) in ["home","clinic","inn"] else house_id
	if not broken("storage") and local.distance_to(Vector2(190,100))<75: return "storage"
	if local.distance_to(Vector2(180,-60))<105:
		return house_id
	return ""

func interaction_prompt(pos: Vector2) -> String:
	var action := interaction_at(pos)
	var building:=SettlementData.building(action)
	if not building.is_empty():
		if building.service!="spring" and not game.service_available(action): return "住民已死亡或敌对，无法交谈"
		return "E  "+building.hint
	if action in ["clinic","shop","archive"] and not game.service_available(action): return "住民已死亡或敌对，无法交谈"
	match action:
		"exit": return "E  离开房屋"
		"rest": return "E  在床榻休息"
		"storage": return "E  整理随身行囊"
		"clinic": return "E  与药师交谈 · 治疗伤势"
		"shop": return "E  与掌柜交易 · 购买物资"
		"archive": return "E  查阅寨中山志"
		"home": return "E  查看修行札记"
		"flower_cave": return "E  查看枯藤与酒香"
		"spring_cave": return "E  引动希望蛊 · 开窍" if game!=null and not game.player.aperture.is_open() else "E  查看开窍后的空窍"
		"bai","xiong","ancestral": return "E  查看此地说明"
	return "走近人物或家具按 E · J 打坐"

func broken(id: String) -> bool:
	return game!=null and game.world.destruction.broken("interior:"+house_id+":"+id)

func collides_at(pos: Vector2, radius: float) -> bool:
	var local := pos-ORIGIN
	for id in FIXTURES:
		if SettlementData.is_cave(house_id) and not id.begins_with("wall"): continue
		if not broken(id) and FIXTURES[id].grow(radius).has_point(local): return true
	return false

func _draw_cave() -> void:
	draw_rect(Rect2(-1600,-1000,3200,2000),Color("0a1518"))
	draw_rect(BOUNDS.grow(12),Color("3e4c47"))
	draw_rect(BOUNDS.grow(-26),Color("59665b"))
	for id in FIXTURES:
		if id.begins_with("wall") and not broken(id): draw_rect(FIXTURES[id],Color("283b37"))
	if house_id=="spring_cave" or SettlementData.service(house_id)=="spring":
		draw_circle(Vector2(0,-70),65,Color("4b8997"))
		draw_circle(Vector2(0,-70),43,Color("78b5bb"))
		for i in (38 if house_id=="spring_cave" else 0):
			var x:float=-270+(i%13)*42
			var y:float=40+int(i/13)*38
			draw_line(Vector2(x,y),Vector2(x,y-20),Color("70a17d"),3)
			draw_circle(Vector2(x,y-20),6,Color("acc6ef"))
	else:
		for i in 14:
			draw_line(Vector2(-240+i*35,-150),Vector2(-220+i*29,-40),Color("84734c"),3)
		draw_circle(Vector2(0,-65),34,Color("756b52"))
		if game!=null and not game.cave_gu_claimed:
			draw_texture_rect(GuArt.texture("jiu_chong"),Rect2(-22,-88,44,44),false)
	draw_string(ThemeDB.fallback_font,Vector2(-180,-155),house_name+" · 家族资源" if house_id!="flower_cave" else "花酒行者留下的隐蔽密洞",HORIZONTAL_ALIGNMENT_CENTER,360,18,UIStyle.GOLD)
	draw_rect(Rect2(-40,192,80,32),Color("8c9878"))
	draw_string(ThemeDB.fallback_font,Vector2(-80,184),"出口 · E",HORIZONTAL_ALIGNMENT_CENTER,160,16,UIStyle.INK)
	_draw_wear()
