class_name NpcSightCard
extends Button

var person: Npc
var game: Node
var head: AtlasTexture
var look := ""

func _ready() -> void:
	custom_minimum_size=Vector2(108,88)
	focus_mode=Control.FOCUS_NONE
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","pressed"]:
		add_theme_stylebox_override(state,UIStyle.box(Color("203b35") if state=="normal" else Color("36594a"),Color("577466") if state=="normal" else UIStyle.GOLD,6))
	pressed.connect(func():
		game._world_attack_held=false
		game.inspect_person(person))

func refresh() -> void:
	if not is_instance_valid(person): return
	var id:=person.get_appearance()
	if id!=look:
		look=id
		head=NpcAppearance.headshot(id)
	var info:=person.inspection_data()
	tooltip_text="%s · %s\n%s · %s\n好感 %+d · %s\n点击查看人物" % [person.npc_name,info.role,info.health,info.activity,person.social.affinity,person.social.label(person)]
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(person) or head==null: return
	var color:=person.social.tint(person)
	draw_texture_rect(head,Rect2(size.x*0.5-24,3,48,46),false,Color(0.65,0.65,0.65) if person.dead else Color.WHITE)
	draw_line(Vector2(8,50),Vector2(size.x-8,50),Color(color,0.45),1)
	draw_string(ThemeDB.fallback_font,Vector2(4,66),person.npc_name,HORIZONTAL_ALIGNMENT_CENTER,int(size.x-8),12,UIStyle.INK)
	var status:="已死亡" if person.dead else ("敌对" if person.hostile else ("受伤" if person.hp<person.max_hp else person.social.label(person)))
	draw_string(ThemeDB.fallback_font,Vector2(4,81),"%s · %+d" % [status,person.social.affinity],HORIZONTAL_ALIGNMENT_CENTER,int(size.x-8),11,color)
