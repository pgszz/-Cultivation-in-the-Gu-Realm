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
const FLOOR := preload("res://assets/ninja_adventure/tileset_interior_floor.png")
const POT := preload("res://assets/ninja_adventure/pot.png")
const CRATE := preload("res://assets/ninja_adventure/crate.png")
const PERSON := preload("res://assets/ninja_adventure/samurai_blue.png")
var house_id := ""
var house_name := ""
var game: Node

func _ready() -> void:
	position = ORIGIN
	z_index = -10
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	if house_id in ["flower_cave","spring_cave"]:
		_draw_cave()
		return
	draw_rect(Rect2(-1600,-1000,3200,2000),Color("0d1b20"))
	draw_rect(BOUNDS.grow(12),Color("263330"))
	for y in range(-192,224,32):
		for x in range(-352,352,32):
			draw_texture_rect_region(FLOOR,Rect2(x,y,32,32),Rect2(16,16,16,16),Color("c8b993"))
	for id in FIXTURES:
		if id.begins_with("wall") and not broken(id):
			draw_rect(FIXTURES[id],Color("655943"))
			if id=="wall_n":
				for x in range(-352,352,32):
					draw_line(Vector2(x,-222),Vector2(x,-186),Color("899176"),2)
	draw_rect(Rect2(-40,192,80,32),Color("baa17b"))
	draw_string(ThemeDB.fallback_font,Vector2(-80,187),"出口 · E",HORIZONTAL_ALIGNMENT_CENTER,160,16,Color("fff0c6"))
	if not broken("bed"):
		if house_id in ["home","clinic"]:
			draw_rect(Rect2(-260,-140,88,138),Color("60482f"))
			draw_rect(Rect2(-252,-131,72,120),Color("a5bbb0"))
			draw_rect(Rect2(-248,-128,64,26),Color("dedac1"))
			draw_rect(Rect2(-252,-91,72,75),Color("527b74") if house_id=="home" else Color("b8b999"))
		else:
			for row in 3:
				var y := -140+row*48
				draw_rect(Rect2(-260,y,88,38),Color("60482f"))
				for col in 5:
					if house_id=="archive":
						draw_rect(Rect2(-253+col*15,y+5,10,26),Color("b1b995") if col%2==0 else Color("7b9d90"))
					else:
						draw_texture_rect(POT,Rect2(-252+col*15,y+4,20,24),false)
	draw_rect(Rect2(-100,-80,170,140),Color("5c7470"))
	draw_rect(Rect2(-90,-70,150,120),Color("8c9c85"),false,3)
	if not broken("desk"):
		draw_rect(Rect2(106,-121,164,53),Color("554431"))
		draw_rect(Rect2(102,-132,172,28),Color("9e8157"))
		for i in 4:
			if house_id in ["clinic","shop"]:
				draw_texture_rect(POT,Rect2(114+i*38,-159,32,32),false)
			else:
				draw_rect(Rect2(114+i*38,-137,26,18),Color("ded2a7"))
				draw_line(Vector2(127+i*38,-137),Vector2(127+i*38,-119),Color("89795c"),1)
	if not broken("storage"):
		draw_rect(Rect2(150,76,92,58),Color("5b4833"))
		draw_texture_rect(CRATE,Rect2(165,62,54,54),false)
	for id in FIXTURES:
		if broken(id):
			var p: Vector2=FIXTURES[id].get_center()
			for i in 4:
				draw_rect(Rect2(p+Vector2(-25+i*13,-8+(i%2)*7),Vector2(20,6)),Color("6f6250"))

func interaction_at(pos: Vector2) -> String:
	var local := pos-ORIGIN
	if house_id in ["flower_cave","spring_cave"]:
		if local.distance_to(Vector2(0,184))<65: return "exit"
		if local.distance_to(Vector2(0,-65))<115: return house_id
		return ""
	if local.distance_to(Vector2(0,184))<65: return "exit"
	if not broken("bed") and local.distance_to(Vector2(-214,-62))<92:
		return "rest" if house_id in ["home","clinic"] else house_id
	if not broken("storage") and local.distance_to(Vector2(190,100))<75: return "storage"
	if local.distance_to(Vector2(180,-60))<105:
		return house_id
	return ""

func interaction_prompt(pos: Vector2) -> String:
	var action := interaction_at(pos)
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
		"spring_cave": return "E  观察灵泉与月兰花海"
		"bai","xiong","ancestral": return "E  查看此地说明"
	return "走近人物或家具按 E · J 打坐"

func broken(id: String) -> bool:
	return game!=null and game.world.destruction.broken("interior:"+house_id+":"+id)

func collides_at(pos: Vector2, radius: float) -> bool:
	var local := pos-ORIGIN
	for id in FIXTURES:
		if house_id in ["flower_cave","spring_cave"] and not id.begins_with("wall"): continue
		if not broken(id) and FIXTURES[id].grow(radius).has_point(local): return true
	return false

func _draw_cave() -> void:
	draw_rect(Rect2(-1600,-1000,3200,2000),Color("0a1518"))
	draw_rect(BOUNDS.grow(12),Color("3e4c47"))
	draw_rect(BOUNDS.grow(-26),Color("59665b"))
	for id in FIXTURES:
		if id.begins_with("wall") and not broken(id): draw_rect(FIXTURES[id],Color("283b37"))
	if house_id=="spring_cave":
		draw_circle(Vector2(0,-70),65,Color("4b8997"))
		draw_circle(Vector2(0,-70),43,Color("78b5bb"))
		for i in 38:
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
	draw_string(ThemeDB.fallback_font,Vector2(-180,-155),"灵泉 · 家族资源" if house_id=="spring_cave" else "花酒行者留下的隐蔽密洞",HORIZONTAL_ALIGNMENT_CENTER,360,18,UIStyle.GOLD)
	draw_rect(Rect2(-40,192,80,32),Color("8c9878"))
	draw_string(ThemeDB.fallback_font,Vector2(-80,184),"出口 · E",HORIZONTAL_ALIGNMENT_CENTER,160,16,UIStyle.INK)
